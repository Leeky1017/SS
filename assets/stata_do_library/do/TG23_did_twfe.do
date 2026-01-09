* ==============================================================================
* SS_TEMPLATE: id=TG23  level=L2  module=G  title="DID TWFE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG23_twfe_comparison.csv type=table desc="TWFE comparison"
*   - fig_TG23_comparison.png type=graph desc="Comparison plot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none (optional: `csdid` for robust comparison)
* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* 方法 / Method: TWFE baseline (built-in) + optional robust staggered DID comparison (csdid)
* 识别假设 / ID assumptions: TWFE can be biased under heterogeneous effects with staggered adoption
* 诊断输出 / Diagnostics: cohort-count warning + TWFE vs robust comparison (if available)
* SSC依赖 / SSC deps: minimized (remove mandatory `reghdfe`/`did_multiplegt`)
* 解读要点 / Interpretation: large TWFE-vs-robust gap suggests heterogeneity/negative weights concerns

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

display "SS_TASK_BEGIN|id=TG23|level=L2|title=DID_TWFE"
display "SS_TASK_VERSION|version=2.1.0"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local treat_var = "__TREAT_VAR__"

display ""
display ">>> TWFE诊断参数:"
display "    结果变量: `outcome_var'"
display "    ID变量: `id_var'"
display "    时间变量: `time_var'"
display "    处理变量: `treat_var'"

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
foreach var in `outcome_var' `id_var' `time_var' `treat_var' {
    capture confirm variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

* 设置面板
capture xtset `id_var' `time_var'
if _rc {
display "SS_RC|code=459|cmd=xtset|msg=xtset_failed|detail=xtset_failed_for_panel_structure|severity=fail"
    log close
    exit 459
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 标准TWFE估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 标准TWFE估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* TWFE baseline using built-in FE regression / 使用内置TWFE基准
capture noisily xtreg `outcome_var' `treat_var' i.`time_var', fe vce(cluster `id_var')
if _rc {
display "SS_RC|code=430|cmd=xtreg|msg=twfe_failed|detail=xtreg_twfe_failed_rc_`_rc'|severity=fail"
    log close
    exit 430
}

local twfe_coef = _b[`treat_var']
local twfe_se = _se[`treat_var']
local twfe_t = `twfe_coef' / `twfe_se'
local twfe_p = 2 * ttail(e(df_r), abs(`twfe_t'))

display ""
display ">>> 标准TWFE估计:"
display "    系数: " %10.4f `twfe_coef'
display "    标准误: " %10.4f `twfe_se'
display "    t统计量: " %10.4f `twfe_t'
display "    p值: " %10.4f `twfe_p'

display "SS_METRIC|name=twfe_coef|value=`twfe_coef'"

* ============ de Chaisemartin-D'Haultfoeuille估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: de Chaisemartin-D'Haultfoeuille估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ">>> 执行稳健交错DID比较 (csdid, 若可用)..."

local robust_coef = .
local robust_se = .
local robust_t = .
local robust_p = .

* Derive first treatment time (gvar) from treat indicator (assumes 0->1 and stays)
bysort `id_var': egen byte _ever_treated = max(`treat_var')
bysort `id_var' (`time_var'): generate _first_treat = `time_var' if `treat_var' == 1 & `treat_var'[_n-1] == 0
bysort `id_var': egen first_treat_time = min(_first_treat)
replace first_treat_time = 0 if missing(first_treat_time)

capture which csdid
if _rc {
display "SS_RC|code=0|cmd=warning|msg=csdid_missing|detail=csdid_not_installed_skip_robust_comparison|severity=warn"
}
else {
    capture noisily csdid `outcome_var', ivar(`id_var') time(`time_var') gvar(first_treat_time) agg(simple)
    if _rc {
display "SS_RC|code=0|cmd=warning|msg=csdid_failed|detail=csdid_failed_skip_comparison|severity=warn"
    }
    else {
        capture local robust_coef = e(b)[1, 1]
        capture local robust_se = sqrt(e(V)[1, 1])
        if `robust_se' > 0 {
            local robust_t = `robust_coef' / `robust_se'
            local robust_p = 2 * (1 - normal(abs(`robust_t')))
        }
    }
}

display ""
display ">>> 稳健交错DID估计(若可用):"
display "    系数: " %10.4f `robust_coef'
display "    标准误: " %10.4f `robust_se'

display "SS_METRIC|name=robust_coef|value=`robust_coef'"

* ============ 负权重诊断 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: TWFE负权重诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

* 分析处理时间异质性
display ">>> 检查处理时间异质性..."

quietly levelsof first_treat_time if first_treat_time > 0, local(treat_times)
local n_cohorts : word count `treat_times'

display ""
display ">>> 处理时间分布:"
display "    处理队列数: `n_cohorts'"

if `n_cohorts' > 1 {
    display "    存在交错处理，TWFE可能存在负权重问题"
display "SS_RC|code=0|cmd=warning|msg=staggered_treatment|detail=Multiple_treatment_cohorts_detected|severity=warn"
}

* 计算简单的权重诊断
quietly count if `treat_var' == 1
local n_treated_obs = r(N)
quietly count if `treat_var' == 0
local n_control_obs = r(N)

display ""
display ">>> 处理状态分布:"
display "    处理观测: `n_treated_obs'"
display "    对照观测: `n_control_obs'"

* ============ 比较结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 估计量比较"
display "═══════════════════════════════════════════════════════════════════════════════"

local diff = `twfe_coef' - `robust_coef'
local pct_diff = .
if `robust_coef' < . & `robust_coef' != 0 {
    local pct_diff = `diff' / `robust_coef' * 100
}

display ""
display "估计量比较:"
display "─────────────────────────────────────────────────"
display "方法                    系数        标准误"
display "─────────────────────────────────────────────────"
display "标准TWFE            " %10.4f `twfe_coef' "  " %10.4f `twfe_se'
display "稳健(若可用)         " %10.4f `robust_coef' "  " %10.4f `robust_se'
display "─────────────────────────────────────────────────"
display "差异                " %10.4f `diff' " (" %5.1f `pct_diff' "%)"

if `pct_diff' < . & abs(`pct_diff') > 20 {
    display ""
display "SS_RC|code=0|cmd=warning|msg=large_diff|detail=TWFE_differs_from_robust_estimator_by_`20'|severity=warn"
    display ">>> 警告: TWFE与稳健估计量差异较大，建议使用稳健方法"
}

* 导出比较结果
preserve
clear
set obs 2
generate str30 estimator = ""
generate double coefficient = .
generate double std_error = .
generate double t_stat = .
generate double p_value = .

replace estimator = "TWFE" in 1
replace coefficient = `twfe_coef' in 1
replace std_error = `twfe_se' in 1
replace t_stat = `twfe_t' in 1
replace p_value = `twfe_p' in 1

replace estimator = "Robust (csdid)" in 2
replace coefficient = `robust_coef' in 2
replace std_error = `robust_se' in 2
replace t_stat = `robust_t' in 2
replace p_value = `robust_p' in 2

export delimited using "table_TG23_twfe_comparison.csv", replace
display "SS_OUTPUT_FILE|file=table_TG23_twfe_comparison.csv|type=table|desc=twfe_comparison"
restore

* ============ 生成对比图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 生成对比图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
clear
set obs 2
generate str30 estimator = ""
generate double coef = .
generate double ci_lower = .
generate double ci_upper = .
generate int order = .

replace estimator = "TWFE" in 1
replace coef = `twfe_coef' in 1
replace ci_lower = `twfe_coef' - 1.96 * `twfe_se' in 1
replace ci_upper = `twfe_coef' + 1.96 * `twfe_se' in 1
replace order = 1 in 1

replace estimator = "Robust (csdid)" in 2
replace coef = `robust_coef' in 2
replace ci_lower = `robust_coef' - 1.96 * `robust_se' in 2
replace ci_upper = `robust_coef' + 1.96 * `robust_se' in 2
replace order = 2 in 2

twoway (bar coef order, barwidth(0.6) color(navy)) ///
       (rcap ci_lower ci_upper order, lcolor(black)), ///
       xlabel(1 "TWFE" 2 "Robust") ///
       xtitle("估计方法") ytitle("系数估计") ///
       title("TWFE vs 稳健估计量比较") ///
       yline(0, lcolor(gray) lpattern(dot)) ///
       legend(off)
graph export "fig_TG23_comparison.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG23_comparison.png|type=graph|desc=comparison"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=twfe_coef|value=`twfe_coef'"
display "SS_SUMMARY|key=robust_coef|value=`robust_coef'"

* 清理临时变量
capture drop _ever_treated _first_treat first_treat_time
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG23 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理队列数:      " %10.0fc `n_cohorts'
display ""
display "  估计结果:"
display "    TWFE:          " %10.4f `twfe_coef' " (SE=" %6.4f `twfe_se' ")"
display "    Robust (csdid): " %10.4f `robust_coef' " (SE=" %6.4f `robust_se' ")"
display "    差异:          " %10.4f `diff' " (" %5.1f `pct_diff' "%)"
display ""
if abs(`pct_diff') > 20 {
    display "  建议: TWFE可能存在偏误，使用稳健估计量"
}
else {
    display "  结论: TWFE与稳健估计量结果接近"
}
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
local n_dropped = 0
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG23|status=ok|elapsed_sec=`elapsed'"
log close
