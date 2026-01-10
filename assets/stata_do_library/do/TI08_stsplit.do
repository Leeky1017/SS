* ==============================================================================
* SS_TEMPLATE: id=TI08  level=L1  module=I  title="Piecewise Exponential"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI08_piecewise.csv type=table desc="Piecewise results"
*   - data_TI08_piecewise.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TI08|level=L1|title=Piecewise_Exp"
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

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TI08 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
local idvar "id"
capture confirm variable `idvar'
local rc_id = _rc
if `rc_id' != 0 {
    gen long ss_id = _n
    local idvar "ss_id"
    display "SS_RC|code=111|cmd=confirm variable id|msg=id_var_missing_created|severity=warn"
}
capture stset `timevar', failure(`failvar') id(`idvar')
local rc_stset = _rc
if `rc_stset' != 0 {
    ss_fail TI08 `rc_stset' "stset" "stset_failed"
}
quietly count if _d == 1
local n_events = r(N)
display "SS_METRIC|name=n_events|value=`n_events'"
if `n_events' == 0 {
    ss_fail TI08 200 "stset" "no_failure_events"
}
if `n_events' < 5 {
    display "SS_RC|code=SMALL_EVENT_COUNT|n_events=`n_events'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily stsplit period, at(0 30 60 90)
local rc_stsplit = _rc
if `rc_stsplit' != 0 {
    ss_fail TI08 `rc_stsplit' "stsplit" "stsplit_failed"
}
capture noisily streg `indepvars' i.period, dist(exponential)
local rc_streg = _rc
if `rc_streg' != 0 {
    if `rc_streg' == 430 {
        display "SS_RC|code=430|cmd=streg|msg=convergence_not_achieved|severity=warn"
    }
    else {
        ss_fail TI08 `rc_streg' "streg" "streg_failed"
    }
}
local ll = .
capture local ll = e(ll)
local rc_ll = _rc
if `rc_ll' != 0 {
    display "SS_RC|code=`rc_ll'|cmd=e(ll)|msg=missing_log_likelihood|severity=warn"
}
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "Piecewise Exponential"
gen double ll = `ll'
export delimited using "table_TI08_piecewise.csv", replace
display "SS_OUTPUT_FILE|file=table_TI08_piecewise.csv|type=table|desc=piecewise_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI08_piecewise.dta", replace
display "SS_OUTPUT_FILE|file=data_TI08_piecewise.dta|type=data|desc=piecewise_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI08|status=ok|elapsed_sec=`elapsed'"
log close
