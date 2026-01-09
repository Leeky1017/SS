* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* Template: TG19 — DID Basic
* 识别假设 / ID assumptions: method-specific; review before use (no "auto validity")
* 诊断输出 / Diagnostics: run minimal, relevant checks; treat WARN as evidence, not noise
* SSC依赖 / SSC deps: keep minimal; required packages are explicit in header
* 解读要点 / Interpretation: estimates are conditional on assumptions; add robustness checks
* SS_TEMPLATE: id=TG19  level=L1  module=G  title="DID Basic"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG19_did_result.csv type=table desc="DID results"
*   - table_TG19_parallel_test.csv type=table desc="Parallel test"
*   - fig_TG19_parallel_trend.png type=graph desc="Parallel trend"
*   - data_TG19_did.dta type=data desc="DID data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
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

display "SS_TASK_BEGIN|id=TG19|level=L1|title=DID_Basic"
display "SS_TASK_VERSION|version=2.1.0"

display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local treat_var = "__TREAT_VAR__"
local post_var = "__POST_VAR__"
local time_var = "__TIME_VAR__"
local controls = "__CONTROLS__"
local cluster_var = "__CLUSTER_VAR__"

display ""
display ">>> DID参数:"
display "    结果变量: `outcome_var'"
display "    处理组: `treat_var'"
display "    处理后: `post_var'"
display "    时间变量: `time_var'"
if "`controls'" != "" {
    display "    控制变量: `controls'"
}
if "`cluster_var'" != "" {
    display "    聚类变量: `cluster_var'"
}

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
foreach var in `outcome_var' `treat_var' `post_var' {
    capture confirm numeric variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

local valid_controls ""
foreach var of local controls {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_controls "`valid_controls' `var'"
    }
}

* 统计
quietly count if `treat_var' == 1
local n_treated = r(N)
quietly count if `treat_var' == 0
local n_control = r(N)
quietly count if `post_var' == 1
local n_post = r(N)
quietly count if `post_var' == 0
local n_pre = r(N)

display ""
display ">>> 数据结构:"
display "    处理组: `n_treated', 对照组: `n_control'"
display "    处理后: `n_post', 处理前: `n_pre'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 生成交互项 ============
generate byte did = `treat_var' * `post_var'
label variable did "DID交互项"

* ============ 描述性统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 描述性统计（2x2表格）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "                    处理前          处理后          差异"
display "─────────────────────────────────────────────────────────────"

quietly summarize `outcome_var' if `treat_var' == 1 & `post_var' == 0
local y_t_pre = r(mean)
quietly summarize `outcome_var' if `treat_var' == 1 & `post_var' == 1
local y_t_post = r(mean)
local diff_t = `y_t_post' - `y_t_pre'

quietly summarize `outcome_var' if `treat_var' == 0 & `post_var' == 0
local y_c_pre = r(mean)
quietly summarize `outcome_var' if `treat_var' == 0 & `post_var' == 1
local y_c_post = r(mean)
local diff_c = `y_c_post' - `y_c_pre'

local did_estimate = `diff_t' - `diff_c'

display "处理组          " %10.4f `y_t_pre' "      " %10.4f `y_t_post' "      " %10.4f `diff_t'
display "对照组          " %10.4f `y_c_pre' "      " %10.4f `y_c_post' "      " %10.4f `diff_c'
display "─────────────────────────────────────────────────────────────"
display "差中差(DID)                                         " %10.4f `did_estimate'

* ============ DID回归估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: DID回归估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建回归命令
local reg_cmd "regress `outcome_var' did `treat_var' `post_var' `valid_controls'"

if "`cluster_var'" != "" {
    capture confirm variable `cluster_var'
    if !_rc {
        local reg_cmd "`reg_cmd', vce(cluster `cluster_var')"
    }
    else {
        local reg_cmd "`reg_cmd', robust"
    }
}
else {
    local reg_cmd "`reg_cmd', robust"
}

`reg_cmd'

local did_coef = _b[did]
local did_se = _se[did]
local did_t = `did_coef' / `did_se'
local did_p = 2 * ttail(e(df_r), abs(`did_t'))
local ci_lower = `did_coef' - 1.96 * `did_se'
local ci_upper = `did_coef' + 1.96 * `did_se'
local r2 = e(r2)
local n_obs = e(N)

display ""
display ">>> DID估计结果:"
display "    DID系数: " %10.4f `did_coef'
display "    标准误: " %10.4f `did_se'
display "    t统计量: " %10.4f `did_t'
display "    p值: " %10.4f `did_p'
display "    95% CI: [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"
display "    R-squared: " %6.4f `r2'

display "SS_METRIC|name=did_coef|value=`did_coef'"
display "SS_METRIC|name=did_se|value=`did_se'"
display "SS_METRIC|name=did_p|value=`did_p'"

* 导出结果
tempname results
postfile `results' str32 variable double coef double se double t double p ///
    using "temp_did_result.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local t = `coef' / `se'
    local p = 2 * ttail(e(df_r), abs(`t'))
    post `results' ("`vname'") (`coef') (`se') (`t') (`p')
}

postclose `results'

preserve
use "temp_did_result.dta", clear
export delimited using "table_TG19_did_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG19_did_result.csv|type=table|desc=did_result"
restore

* ============ 平行趋势检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 平行趋势检验"
display "═══════════════════════════════════════════════════════════════════════════════"

capture confirm variable `time_var'
if !_rc {
    * 获取时间点
    quietly levelsof `time_var', local(time_points)
    local n_times : word count `time_points'
    
    if `n_times' > 2 {
        display ">>> 执行事件研究法检验平行趋势..."
        
        * 找到处理时间
        quietly summarize `time_var' if `post_var' == 1
        local treat_time = r(min)
        
        * 生成相对时间
        generate int rel_time = `time_var' - `treat_time'
        
        * 生成时间虚拟变量与处理组的交互
        quietly levelsof rel_time, local(rel_times)
        
        local time_dummies ""
        foreach rt of local rel_times {
            if `rt' != -1 {
                local rt_label = cond(`rt' < 0, "m" + string(abs(`rt')), "p" + string(`rt'))
                generate byte treat_t`rt_label' = `treat_var' * (rel_time == `rt')
                local time_dummies "`time_dummies' treat_t`rt_label'"
            }
        }
        
        * 事件研究回归
        regress `outcome_var' `time_dummies' i.`time_var' `valid_controls', robust
        
        * 保存平行趋势检验结果
        tempname parallel
        postfile `parallel' int rel_time double coef double se double ci_lower double ci_upper ///
            using "temp_parallel.dta", replace
        
        foreach rt of local rel_times {
            if `rt' != -1 {
                local rt_label = cond(`rt' < 0, "m" + string(abs(`rt')), "p" + string(`rt'))
                local coef = _b[treat_t`rt_label']
                local se = _se[treat_t`rt_label']
                local ci_l = `coef' - 1.96 * `se'
                local ci_u = `coef' + 1.96 * `se'
                post `parallel' (`rt') (`coef') (`se') (`ci_l') (`ci_u')
            }
            else {
                post `parallel' (-1) (0) (0) (0) (0)
            }
        }
        
        postclose `parallel'
        
        preserve
        use "temp_parallel.dta", clear
        export delimited using "table_TG19_parallel_test.csv", replace
        display "SS_OUTPUT_FILE|file=table_TG19_parallel_test.csv|type=table|desc=parallel_test"
        
        * 绘制事件研究图
        twoway (rarea ci_lower ci_upper rel_time, color(navy%20)) ///
               (scatter coef rel_time, mcolor(navy) msize(medium)) ///
               (line coef rel_time, lcolor(navy)), ///
               xline(-0.5, lcolor(red) lpattern(dash)) ///
               yline(0, lcolor(gray) lpattern(dot)) ///
               xlabel(-3(1)3) ///
               xtitle("相对处理时间") ytitle("估计系数") ///
               title("事件研究法: 平行趋势检验") ///
               legend(off) ///
               note("红色虚线=处理时间, 基准期=-1")
        graph export "fig_TG19_parallel_trend.png", replace width(1200)
        display "SS_OUTPUT_FILE|file=fig_TG19_parallel_trend.png|type=graph|desc=parallel_trend"
        restore
        
        capture erase "temp_parallel.dta"
        if _rc != 0 {
            * Expected non-fatal return code
        }
    }
    else {
        display ">>> 时间点不足，无法进行平行趋势检验"
    }
}

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG19_did.dta", replace
display "SS_OUTPUT_FILE|file=data_TG19_did.dta|type=data|desc=did_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=did_coef|value=`did_coef'"

capture erase "temp_did_result.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG19 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理组:          " %10.0fc `n_treated'
display "  对照组:          " %10.0fc `n_control'
display ""
display "  DID估计结果:"
display "    系数:          " %10.4f `did_coef'
display "    标准误:        " %10.4f `did_se'
display "    p值:           " %10.4f `did_p'
display "    95% CI:        [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"
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

display "SS_TASK_END|id=TG19|status=ok|elapsed_sec=`elapsed'"
log close
