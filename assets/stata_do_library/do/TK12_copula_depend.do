* ==============================================================================
* SS_TEMPLATE: id=TK12  level=L2  module=K  title="Copula Depend"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK12_correlation.csv type=table desc="Correlation matrix"
*   - table_TK12_tail_depend.csv type=table desc="Tail dependence"
*   - fig_TK12_scatter.png type=graph desc="Scatter plot"
*   - data_TK12_copula.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.10) / 最佳实践审查记录
* - Date: 2026-01-10
* - Interpretation / 解释: dependence measures depend on marginals and tail behavior / 依赖度量依赖边际分布与尾部行为
* - Data checks / 数据校验: missingness across series; ensure aligned time index
* - Diagnostics / 诊断: compare Pearson/Spearman/Kendall; tail dependence is sample-sensitive
* - SSC deps / SSC 依赖: none / 无
* ------------------------------------------------------------------------------

* ============ 初始化 ============
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TK12
    args code cmd msg detail step
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    if "`step'" != "" & "`step'" != "." {
        display "SS_STEP_END|step=`step'|status=fail|elapsed_sec=0"
    }
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|detail=`detail'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TK12|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK12|level=L2|title=Copula_Depend"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_vars = "__RETURN_VARS__"
local copula_type = "__COPULA_TYPE__"

if "`copula_type'" == "" {
    display "SS_RC|code=PARAM_DEFAULTED|param=copula_type|default=gaussian|severity=warn"
    local copula_type = "gaussian"
}

display ""
display ">>> Copula依赖分析参数:"
display "    收益变量: `return_vars'"
display "    Copula类型: `copula_type'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK12 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
local valid_vars ""
local n_vars = 0
foreach var of local return_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_vars "`valid_vars' `var'"
        local n_vars = `n_vars' + 1
    }
}

if `n_vars' < 2 {
    ss_fail_TK12 198 validate_variables too_few_variables n_vars_lt_2 S02_validate_inputs
}

* Missingness checks / 缺失值检查（提示性）
foreach var of local valid_vars {
    quietly count if missing(`var')
    local n_miss = r(N)
    if `n_miss' > 0 {
        display "SS_RC|code=MISSING_VALUES|var=`var'|n=`n_miss'|severity=warn"
    }
}

display ">>> 有效变量数: `n_vars'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 相关性分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 相关性分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* Pearson相关
correlate `valid_vars'
matrix corr_pearson = r(C)

display ""
display ">>> Pearson相关矩阵:"
matrix list corr_pearson, format(%8.4f)

* Spearman秩相关
spearman `valid_vars', stats(rho)
matrix corr_spearman = r(Rho)

display ""
display ">>> Spearman相关矩阵:"
matrix list corr_spearman, format(%8.4f)

* Kendall's tau
ktau `valid_vars'

* 导出相关矩阵
preserve
clear
svmat corr_pearson, names(col)
generate str20 variable = ""
local i = 1
foreach var of local valid_vars {
    replace variable = "`var'" in `i'
    local i = `i' + 1
}
order variable
export delimited using "table_TK12_correlation.csv", replace
display "SS_OUTPUT_FILE|file=table_TK12_correlation.csv|type=table|desc=correlation"
restore

* ============ 尾部依赖分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 尾部依赖分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算经验尾部依赖系数
local var1 : word 1 of `valid_vars'
local var2 : word 2 of `valid_vars'

* 转换为均匀分布（经验CDF）
foreach var of local valid_vars {
    egen rank_`var' = rank(`var')
    generate double u_`var' = rank_`var' / (_N + 1)
}

* 下尾依赖（联合低于某阈值的概率）
tempname tail_results
postfile `tail_results' double threshold double lower_tail double upper_tail ///
    using "temp_tail.dta", replace

display ""
display ">>> 经验尾部依赖系数:"
display "阈值q    下尾依赖    上尾依赖"
display "─────────────────────────────"

foreach q in 0.05 0.10 0.15 0.20 0.25 {
    * 下尾
    quietly count if u_`var1' <= `q' & u_`var2' <= `q'
    local joint_lower = r(N)
    quietly count if u_`var1' <= `q'
    local marginal = r(N)
    local lambda_l = `joint_lower' / `marginal'
    
    * 上尾
    quietly count if u_`var1' >= 1-`q' & u_`var2' >= 1-`q'
    local joint_upper = r(N)
    quietly count if u_`var1' >= 1-`q'
    local marginal_u = r(N)
    local lambda_u = `joint_upper' / `marginal_u'
    
    post `tail_results' (`q') (`lambda_l') (`lambda_u')
    
    display %6.2f `q' "     " %8.4f `lambda_l' "      " %8.4f `lambda_u'
}

postclose `tail_results'

preserve
use "temp_tail.dta", clear
export delimited using "table_TK12_tail_depend.csv", replace
display "SS_OUTPUT_FILE|file=table_TK12_tail_depend.csv|type=table|desc=tail_depend"
restore

display "SS_METRIC|name=lower_tail_5pct|value=`lambda_l'"

* ============ 生成散点图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成散点图"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway (scatter `var2' `var1', mcolor(navy%30) msize(tiny)), ///
    xtitle("`var1'") ytitle("`var2'") ///
    title("收益散点图") ///
    note("Pearson ρ=" %5.3f corr_pearson[1,2])
graph export "fig_TK12_scatter.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK12_scatter.png|type=graph|desc=scatter_plot"

* 清理
capture erase "temp_tail.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK12_copula.dta", replace
display "SS_OUTPUT_FILE|file=data_TK12_copula.dta|type=data|desc=copula_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK12 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display ""
display "  相关性 (`var1' vs `var2'):"
display "    Pearson:       " %10.4f corr_pearson[1,2]
display "    Spearman:      " %10.4f corr_spearman[1,2]
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_vars|value=`n_vars'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK12|status=ok|elapsed_sec=`elapsed'"
log close
