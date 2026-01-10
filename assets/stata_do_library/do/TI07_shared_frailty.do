* ==============================================================================
* SS_TEMPLATE: id=TI07  level=L2  module=I  title="Shared Frailty"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI07_frailty.csv type=table desc="Frailty results"
*   - data_TI07_frailty.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
local rc_log_close = _rc
if `rc_log_close' != 0 {
    display "SS_RC|code=`rc_log_close'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TI07|level=L2|title=Shared_Frailty"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

program define ss_fail
    args template_id code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=`template_id'|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local timevar = "__TIME_VAR__"
local failvar = "__FAILVAR__"
local indepvars = "__INDEPVARS__"
local group_var = "__GROUP_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TI07 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture stset `timevar', failure(`failvar')
local rc_stset = _rc
if `rc_stset' != 0 {
    ss_fail TI07 `rc_stset' "stset" "stset_failed"
}
quietly count if _d == 1
local n_events = r(N)
display "SS_METRIC|name=n_events|value=`n_events'"
if `n_events' == 0 {
    ss_fail TI07 200 "stset" "no_failure_events"
}
if `n_events' < 5 {
    display "SS_RC|code=SMALL_EVENT_COUNT|n_events=`n_events'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily stcox `indepvars', shared(`group_var')
local rc_stcox = _rc
if `rc_stcox' != 0 {
    ss_fail TI07 `rc_stcox' "stcox" "stcox_failed"
}
local ll = .
local theta = .
capture local ll = e(ll)
local rc_ll = _rc
if `rc_ll' != 0 {
    display "SS_RC|code=`rc_ll'|cmd=e(ll)|msg=missing_log_likelihood|severity=warn"
}
capture local theta = e(theta)
local rc_theta = _rc
if `rc_theta' != 0 {
    display "SS_RC|code=`rc_theta'|cmd=e(theta)|msg=missing_theta|severity=warn"
}
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=theta|value=`theta'"

preserve
clear
set obs 1
gen str32 model = "Shared Frailty"
gen double ll = `ll'
gen double theta = `theta'
export delimited using "table_TI07_frailty.csv", replace
display "SS_OUTPUT_FILE|file=table_TI07_frailty.csv|type=table|desc=frailty_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI07_frailty.dta", replace
display "SS_OUTPUT_FILE|file=data_TI07_frailty.dta|type=data|desc=frailty_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=theta|value=`theta'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI07|status=ok|elapsed_sec=`elapsed'"
log close
