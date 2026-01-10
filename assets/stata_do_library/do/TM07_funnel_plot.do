* ==============================================================================
* SS_TEMPLATE: id=TM07  level=L2  module=M  title="Funnel Plot"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TM07_funnel.png type=graph desc="Funnel plot"
*   - table_TM07_bias.csv type=table desc="Bias results"
*   - data_TM07_bias.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Funnel plots and Egger tests are exploratory and can be misleading with few studies; interpret alongside heterogeneity and design factors.
* - Ensure effect sizes and SEs are on compatible scales (e.g., log OR with its SE).
* - Consider alternative bias diagnostics (trim-and-fill, selection models) when appropriate; this template provides a minimal baseline.
* 最佳实践审查（ZH）:
* - 漏斗图与 Egger 检验属于探索性工具；研究数量少时容易误判，需结合异质性与研究设计解读。
* - 请确保效应量与标准误在同一尺度（如 log OR 及其 SE）。
* - 可视情境考虑其他偏倚诊断方法；本模板提供最小可复用基线实现。
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TM07|level=L2|title=Funnel_Plot"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local effect = "__EFFECT__"
local se = "__SE__"

display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate effect/SE variables exist and SE > 0 for complete cases.
* ZH: 校验效应量/标准误变量存在，且完整观测中标准误应大于 0。
capture confirm variable `effect'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `effect'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `se'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `se'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `effect'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `effect'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `se'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `se'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
count if !missing(`effect', `se') & (`se' > 0)
local k = r(N)
display "SS_METRIC|name=k_studies|value=`k'"
if `k' < 3 {
    display "SS_RC|code=2005|cmd=validate_study_count|msg=too_few_studies_for_bias_test|severity=warn"
}
count if !missing(`effect', `se') & (`se' <= 0)
local n_bad_se = r(N)
display "SS_METRIC|name=n_bad_se|value=`n_bad_se'"
if `n_bad_se' > 0 {
    display "SS_RC|code=2006|cmd=validate_se_positive|msg=nonpositive_se_detected|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Produce funnel plot (effect vs precision) and Egger regression intercept p-value (no SSC dependency).
* ZH: 生成漏斗图（效应量 vs 精度）并计算 Egger 回归截距的 p 值（不依赖 SSC）。

tempvar ss_precision ss_snd ss_w ss_wx
gen double `ss_precision' = .
replace `ss_precision' = 1 / `se' if !missing(`effect', `se') & (`se' > 0)
gen double `ss_snd' = `effect' / `se' if !missing(`effect', `se') & (`se' > 0)

gen double `ss_w' = .
replace `ss_w' = 1 / (`se'^2) if !missing(`effect', `se') & (`se' > 0)
gen double `ss_wx' = `ss_w' * `effect'
quietly summarize `ss_w', meanonly
local sum_w = r(sum)
quietly summarize `ss_wx', meanonly
local sum_wx = r(sum)
local pooled_fe = `sum_wx' / `sum_w'
display "SS_METRIC|name=pooled_effect_fe|value=`pooled_fe'"

quietly summarize `ss_precision' if !missing(`ss_precision'), meanonly
local pmin = r(min)
local pmax = r(max)

twoway ///
    (scatter `effect' `ss_precision' if !missing(`ss_precision'), mcolor(navy) msymbol(O) msize(vsmall)) ///
    (function `pooled_fe' + 1.96/x, range(`pmin' `pmax') lcolor(gs10) lpattern(dash)) ///
    (function `pooled_fe' - 1.96/x, range(`pmin' `pmax') lcolor(gs10) lpattern(dash)) ///
    (function `pooled_fe', range(`pmin' `pmax') lcolor(maroon)), ///
    xtitle("Precision (1/SE)") ytitle("Effect") title("Funnel Plot")
graph export "fig_TM07_funnel.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TM07_funnel.png|type=graph|desc=funnel_plot"

local bias = .
local p_bias = .
capture noisily regress `ss_snd' `ss_precision' if !missing(`ss_snd', `ss_precision')
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress_egger|msg=egger_regression_failed|severity=warn"
}
if _rc == 0 {
    local bias = _b[_cons]
    quietly test _cons = 0
    local p_bias = r(p)
}
display "SS_METRIC|name=egger_bias|value=`bias'"
display "SS_METRIC|name=egger_p|value=`p_bias'"

preserve
clear
set obs 1
gen double egger_bias = `bias'
gen double egger_p = `p_bias'
export delimited using "table_TM07_bias.csv", replace
display "SS_OUTPUT_FILE|file=table_TM07_bias.csv|type=table|desc=bias_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM07_bias.dta", replace
display "SS_OUTPUT_FILE|file=data_TM07_bias.dta|type=data|desc=bias_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=egger_bias|value=`bias'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM07|status=ok|elapsed_sec=`elapsed'"
log close
