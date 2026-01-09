* ==============================================================================
* SS_TEMPLATE: id=TF04  level=L1  module=F  title="XTSCC"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TF04_xtscc.csv type=table desc="XTSCC results"
*   - data_TF04_xtscc.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="xtreg (FE) with clustered SE (fallback); optional xtscc for Driscoll-Kraay"
* ==============================================================================

capture log close _all
if _rc != 0 {
    display "SS_RC|code=`=_rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TF04
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TF04|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TF04|level=L1|title=XTSCC"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.6 REVIEW (Issue #246) / 最佳实践审查（阶段 5.6）
* - Best practice: prefer robust inference; if `xtscc` is available use Driscoll-Kraay; otherwise fall back to FE with clustered SE. /
*   最佳实践：优先稳健推断；若可用则用 Driscoll-Kraay（xtscc）；否则回退到 FE + 聚类稳健标准误。
* - SSC deps: xtscc optional (fallback exists) / SSC 依赖：xtscc 可选（存在回退实现）
* - Error policy: fail on missing panel/time vars or xtset failure; warn on singleton groups /
*   错误策略：缺少面板/时间变量或 xtset 失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=246|template_id=TF04|ssc=optional:xtscc|output=csv|policy=warn_fail"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local has_xtscc = 0
capture which xtscc
if _rc {
    display "SS_DEP_CHECK|pkg=xtscc|source=ssc|status=missing"
    display "SS_RC|code=199|cmd=which xtscc|msg=dependency_missing_fallback_xtreg_cluster|severity=warn"
}
else {
    display "SS_DEP_CHECK|pkg=xtscc|source=ssc|status=ok"
    local has_xtscc = 1
}

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TF04 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `panelvar'
if _rc {
    ss_fail_TF04 111 "confirm variable `panelvar'" "panel_var_missing"
}
capture confirm variable `timevar'
if _rc {
    ss_fail_TF04 111 "confirm variable `timevar'" "time_var_missing"
}
capture xtset `panelvar' `timevar'
if _rc {
    ss_fail_TF04 `=_rc' "xtset `panelvar' `timevar'" "xtset_failed"
}

tempvar _ss_n_i
bysort `panelvar': gen long `_ss_n_i' = _N
quietly count if `_ss_n_i' == 1
local n_singletons = r(N)
drop `_ss_n_i'
display "SS_METRIC|name=n_singletons|value=`n_singletons'"
if `n_singletons' > 0 {
    display "SS_RC|code=312|cmd=xtset|msg=singleton_groups_present|severity=warn"
}

if `has_xtscc' == 1 {
    capture noisily xtscc `depvar' `indepvars', fe
    if _rc {
        ss_fail_TF04 `=_rc' "xtscc" "xtscc_failed"
    }
    local model_label = "Driscoll-Kraay (xtscc)"
    local r2 = e(r2)
}
else {
    * [ZH] 回退：FE + 聚类稳健标准误（按个体聚类）；不等价于 Driscoll-Kraay。/ [EN] Fallback: FE + cluster-robust SE (by panel id); not equivalent to Driscoll-Kraay.
    capture noisily xtreg `depvar' `indepvars', fe vce(cluster `panelvar')
    if _rc {
        ss_fail_TF04 `=_rc' "xtreg fe vce(cluster)" "xtreg_failed"
    }
    local model_label = "FE + cluster SE (fallback)"
    local r2 = e(r2_w)
}
display "SS_METRIC|name=r2|value=`r2'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 model = "Driscoll-Kraay"
replace model = "`model_label'"
gen double r2 = `r2'
capture export delimited using "table_TF04_xtscc.csv", replace
if _rc {
    ss_fail_TF04 `=_rc' "export delimited" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TF04_xtscc.csv|type=table|desc=xtscc_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TF04_xtscc.dta", replace
if _rc {
    ss_fail_TF04 `=_rc' "save" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TF04_xtscc.dta|type=data|desc=xtscc_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TF04|status=ok|elapsed_sec=`elapsed'"
log close
