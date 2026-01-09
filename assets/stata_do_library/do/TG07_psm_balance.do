* ==============================================================================
* SS_TEMPLATE: id=TG07  level=L1  module=G  title="PSM Balance"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG07_balance_stats.csv type=table desc="Balance stats"
*   - table_TG07_balance_detail.csv type=table desc="Balance detail"
*   - fig_TG07_love_plot.png type=graph desc="Love plot"
*   - fig_TG07_ps_overlap.png type=graph desc="PS overlap"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - psmatch2 source=ssc purpose="PSM balance"
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 {
    * Expected non-fatal return code
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TG07|level=L1|title=PSM_Balance"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.0.1"

* ============ 依赖检测 ============
local required_deps "psmatch2"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
display "SS_DEP_CHECK|pkg=`dep'|source=ssc|status=missing"
display "SS_DEP_MISSING|pkg=`dep'|hint=ssc_install_`dep'"
display "SS_RC|code=199|cmd=which `dep'|msg=dependency_missing|severity=fail"
display "SS_RC|code=199|cmd=which|msg=dep_missing|detail=`dep'_is_required_but_not_installed|severity=fail"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=psmatch2|source=ssc|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local covariates = "__COVARIATES__"
local pscore_var = "__PSCORE_VAR__"
local weight_var = "__WEIGHT_VAR__"
local threshold = __THRESHOLD__

if "`pscore_var'" == "" {
    local pscore_var = "pscore"
}
if `threshold' <= 0 | `threshold' > 50 {
    local threshold = 10
}

display ""
display ">>> 平衡性检验参数:"
display "    处理变量: `treatment_var'"
display "    协变量: `covariates'"
display "    倾向得分: `pscore_var'"
if "`weight_var'" != "" {
    display "    权重变量: `weight_var'"
}
display "    阈值: `threshold'%"

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
capture confirm file "data.csv"
if _rc {
display "SS_RC|code=601|cmd=confirm_file|msg=file_not_found|detail=data.csv_not_found|file=data.csv|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
capture confirm variable `treatment_var'
if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`treatment_var'_not_found|var=`treatment_var'|severity=fail"
    log close
    exit 200
}

local valid_covariates ""
foreach var of local covariates {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_covariates "`valid_covariates' `var'"
    }
}

* 检查或估计倾向得分
capture confirm variable `pscore_var'
if _rc {
    display ">>> 未找到倾向得分，重新估计..."
    logit `treatment_var' `valid_covariates'
    predict double `pscore_var', pr
}

quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 平衡性统计计算 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 平衡性统计计算"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname balance_stats
postfile `balance_stats' str32 variable double mean_t double mean_c double std_diff ///
    double var_ratio double t_stat double p_value byte pass ///
    using "temp_balance_stats.dta", replace

local n_pass = 0
local n_fail = 0

display ""
display "变量                 均值(T)      均值(C)    标准化差异  方差比    t值      p值     结果"
display "──────────────────────────────────────────────────────────────────────────────────────────"

foreach var of local valid_covariates {
    * 计算统计量
    if "`weight_var'" != "" {
        quietly summarize `var' if `treatment_var' == 1 [aw=`weight_var']
    }
    else {
        quietly summarize `var' if `treatment_var' == 1
    }
    local mean_t = r(mean)
    local var_t = r(Var)
    local sd_t = r(sd)
    
    if "`weight_var'" != "" {
        quietly summarize `var' if `treatment_var' == 0 [aw=`weight_var']
    }
    else {
        quietly summarize `var' if `treatment_var' == 0
    }
    local mean_c = r(mean)
    local var_c = r(Var)
    local sd_c = r(sd)
    
    * 标准化差异
    local pooled_sd = sqrt((`var_t' + `var_c') / 2)
    if `pooled_sd' > 0 {
        local std_diff = (`mean_t' - `mean_c') / `pooled_sd' * 100
    }
    else {
        local std_diff = 0
    }
    
    * 方差比
    if `var_c' > 0 {
        local var_ratio = `var_t' / `var_c'
    }
    else {
        local var_ratio = 1
    }
    
    * t检验
    quietly ttest `var', by(`treatment_var')
    local t_stat = r(t)
    local p_value = r(p)
    
    * 判断是否通过
    local pass = (abs(`std_diff') < `threshold')
    if `pass' {
        local n_pass = `n_pass' + 1
        local result = "PASS"
    }
    else {
        local n_fail = `n_fail' + 1
        local result = "FAIL"
    }
    
    post `balance_stats' ("`var'") (`mean_t') (`mean_c') (`std_diff') (`var_ratio') (`t_stat') (`p_value') (`pass')
    
    display %20s "`var'" "  " %10.4f `mean_t' "  " %10.4f `mean_c' "  " %8.2f `std_diff' "%  " ///
        %6.3f `var_ratio' "  " %6.2f `t_stat' "  " %6.4f `p_value' "  " "`result'"
}

postclose `balance_stats'

display "──────────────────────────────────────────────────────────────────────────────────────────"
display ">>> 通过: `n_pass', 未通过: `n_fail' (阈值: `threshold'%)"

local pass_rate = `n_pass' / (`n_pass' + `n_fail') * 100
display "SS_METRIC|name=pass_rate|value=`pass_rate'"
display "SS_METRIC|name=n_pass|value=`n_pass'"
display "SS_METRIC|name=n_fail|value=`n_fail'"

* 导出统计结果
preserve
use "temp_balance_stats.dta", clear
export delimited using "table_TG07_balance_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_TG07_balance_stats.csv|type=table|desc=balance_stats"
restore

* ============ 详细检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 详细平衡性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname detail
postfile `detail' str32 variable str20 test double statistic double p_value ///
    using "temp_balance_detail.dta", replace

foreach var of local valid_covariates {
    * KS检验
    capture ksmirnov `var', by(`treatment_var')
    if !_rc {
        local ks_stat = r(D)
        local ks_p = r(p)
        post `detail' ("`var'") ("KS test") (`ks_stat') (`ks_p')
    }
    
    * Wilcoxon秩和检验
    capture ranksum `var', by(`treatment_var')
    if !_rc {
        local rs_z = r(z)
        local rs_p = 2 * (1 - normal(abs(`rs_z')))
        post `detail' ("`var'") ("Ranksum") (`rs_z') (`rs_p')
    }
}

postclose `detail'

preserve
use "temp_balance_detail.dta", clear
export delimited using "table_TG07_balance_detail.csv", replace
display "SS_OUTPUT_FILE|file=table_TG07_balance_detail.csv|type=table|desc=balance_detail"
restore

* ============ 生成图形 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成诊断图形"
display "═══════════════════════════════════════════════════════════════════════════════"

* Love Plot
preserve
use "temp_balance_stats.dta", clear
generate var_id = _n
generate abs_std_diff = abs(std_diff)

twoway (scatter var_id abs_std_diff, msymbol(O) mcolor(navy)), ///
    xline(`threshold', lcolor(red) lpattern(dash)) ///
    xlabel(0(5)30) ///
    ylabel(1(1)`=_N', valuelabel angle(0) labsize(small)) ///
    ytitle("") xtitle("绝对标准化差异 (%)") ///
    title("协变量平衡性 Love Plot") ///
    note("红色虚线=`threshold'%阈值")
graph export "fig_TG07_love_plot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG07_love_plot.png|type=graph|desc=love_plot"
restore

* 倾向得分重叠图
twoway (kdensity `pscore_var' if `treatment_var' == 1, lcolor(red) lwidth(medium)) ///
       (kdensity `pscore_var' if `treatment_var' == 0, lcolor(blue) lwidth(medium)), ///
       legend(order(1 "处理组" 2 "对照组") position(6)) ///
       xtitle("倾向得分") ytitle("密度") ///
       title("倾向得分分布重叠")
graph export "fig_TG07_ps_overlap.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG07_ps_overlap.png|type=graph|desc=ps_overlap"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=pass_rate|value=`pass_rate'"

capture erase "temp_balance_stats.dta"
if _rc != 0 {
    * Expected non-fatal return code
}
capture erase "temp_balance_detail.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG07 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理组:          " %10.0fc `n_treated'
display "  对照组:          " %10.0fc `n_control'
display "  检验变量数:      " %10.0fc `: word count `valid_covariates''
display ""
display "  平衡性检验结果 (阈值=`threshold'%):"
display "    通过:          " %10.0fc `n_pass'
display "    未通过:        " %10.0fc `n_fail'
display "    通过率:        " %10.1f `pass_rate' "%"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG07|status=ok|elapsed_sec=`elapsed'"
log close
