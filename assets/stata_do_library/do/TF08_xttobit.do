* ==============================================================================
* SS_TEMPLATE: id=TF08  level=L0  module=F  title="XTTOBIT"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TF08_xttobit.csv type=table desc="Panel Tobit results"
*   - data_TF08_xttobit.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="xttobit command"
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

program define ss_fail_TF08
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TF08|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TF08|level=L0|title=XTTOBIT"
display "SS_TASK_VERSION|version=2.0.1"
* ==============================================================================
* PHASE 5.6 REVIEW (Issue #246) / 最佳实践审查（阶段 5.6）
* - Best practice: Tobit assumptions are strong; treat as sensitivity and consider alternatives if censoring is limited. /
*   最佳实践：Tobit 假设较强；建议作为稳健性分析，并视删失程度考虑替代模型。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/xtset/estimation; warn on singleton groups /
*   错误策略：缺少输入/xtset/估计失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=246|template_id=TF08|ssc=none|output=csv|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"
local ll = __LL__

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TF08 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `panelvar'
if _rc {
    ss_fail_TF08 111 "confirm variable `panelvar'" "panel_var_missing"
}
capture confirm variable `timevar'
if _rc {
    ss_fail_TF08 111 "confirm variable `timevar'" "time_var_missing"
}
capture xtset `panelvar' `timevar'
if _rc {
    ss_fail_TF08 `=_rc' "xtset `panelvar' `timevar'" "xtset_failed"
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
capture noisily xttobit `depvar' `indepvars', ll(`ll')
if _rc {
    ss_fail_TF08 `=_rc' "xttobit" "xttobit_failed"
}
local ll_val = e(ll)
display "SS_METRIC|name=log_likelihood|value=`ll_val'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 model = "Panel Tobit"
gen double ll = `ll_val'
capture export delimited using "table_TF08_xttobit.csv", replace
if _rc {
    ss_fail_TF08 `=_rc' "export delimited" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TF08_xttobit.csv|type=table|desc=xttobit_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TF08_xttobit.dta", replace
if _rc {
    ss_fail_TF08 `=_rc' "save" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TF08_xttobit.dta|type=data|desc=xttobit_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll_val'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TF08|status=ok|elapsed_sec=`elapsed'"
log close
