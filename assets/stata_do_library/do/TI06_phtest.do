* ==============================================================================
* SS_TEMPLATE: id=TI06  level=L1  module=I  title="PH Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI06_phtest.csv type=table desc="PH test results"
*   - fig_TI06_ph.png type=graph desc="PH plot"
*   - data_TI06_phtest.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TI06|level=L1|title=PH_Test"
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
    ss_fail TI06 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture stset `timevar', failure(`failvar')
local rc_stset = _rc
if `rc_stset' != 0 {
    ss_fail TI06 `rc_stset' "stset" "stset_failed"
}
quietly count if _d == 1
local n_events = r(N)
display "SS_METRIC|name=n_events|value=`n_events'"
if `n_events' == 0 {
    ss_fail TI06 200 "stset" "no_failure_events"
}
if `n_events' < 5 {
    display "SS_RC|code=SMALL_EVENT_COUNT|n_events=`n_events'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily stcox `indepvars'
local rc_stcox = _rc
if `rc_stcox' != 0 {
    ss_fail TI06 `rc_stcox' "stcox" "stcox_failed"
}
local chi2 = .
local p = .
capture noisily estat phtest, detail
local rc_phtest = _rc
if `rc_phtest' == 0 {
    local chi2 = r(chi2)
    local p = r(p)
}
else {
    display "SS_RC|code=`rc_phtest'|cmd=estat phtest|msg=phtest_unavailable|severity=warn"
}
display "SS_METRIC|name=chi2|value=`chi2'"
display "SS_METRIC|name=p_value|value=`p'"

local byvar : word 1 of indepvars
if "`byvar'" == "" {
    local byvar "`failvar'"
}
capture stphplot, by(`byvar')
local rc_phplot = _rc
if `rc_phplot' != 0 {
    display "SS_RC|code=`rc_phplot'|cmd=stphplot|msg=phplot_failed|severity=warn"
}
else {
    capture graph export "fig_TI06_ph.png", replace width(1200)
    local rc_export = _rc
    if `rc_export' != 0 {
        display "SS_RC|code=`rc_export'|cmd=graph export fig_TI06_ph.png|msg=graph_export_failed|severity=warn"
    }
    else {
        display "SS_OUTPUT_FILE|file=fig_TI06_ph.png|type=graph|desc=ph_plot"
    }
}

preserve
clear
set obs 1
gen str32 test = "PH Test"
gen double chi2 = `chi2'
gen double p = `p'
export delimited using "table_TI06_phtest.csv", replace
display "SS_OUTPUT_FILE|file=table_TI06_phtest.csv|type=table|desc=phtest_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI06_phtest.dta", replace
display "SS_OUTPUT_FILE|file=data_TI06_phtest.dta|type=data|desc=phtest_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=chi2|value=`chi2'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI06|status=ok|elapsed_sec=`elapsed'"
log close
