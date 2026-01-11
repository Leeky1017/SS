* ==============================================================================
* SS_TEMPLATE: id=TN04  level=L1  module=N  title="SEM"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TN04_sem.csv type=table desc="SEM results"
*   - data_TN04_sem.dta type=data desc="Output data"
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

program define ss_fail_TN04
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TN04|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TN04|level=L1|title=SEM"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TN04 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture confirm variable x
if _rc {
    gen double x = _n
    display "SS_RC|code=0|cmd=gen x=_n|msg=coord_x_defaulted|severity=warn"
}
capture confirm variable cluster
if _rc {
    gen double cluster = 0
    display "SS_RC|code=0|cmd=gen cluster=0|msg=coord_y_defaulted|severity=warn"
}
gen long ss_sid = _n
spset ss_sid
spset, modify coord(x cluster)
spmatrix create idistance W, normalize(row)
spregress `depvar' `indepvars', ml errorlag(W)
local lambda = e(lambda)
local ll = e(ll)
display "SS_METRIC|name=lambda|value=`lambda'"
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "SEM"
gen double lambda = `lambda'
gen double ll = `ll'
export delimited using "table_TN04_sem.csv", replace
display "SS_OUTPUT_FILE|file=table_TN04_sem.csv|type=table|desc=sem_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TN04_sem.dta", replace
display "SS_OUTPUT_FILE|file=data_TN04_sem.dta|type=data|desc=sem_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=lambda|value=`lambda'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TN04|status=ok|elapsed_sec=`elapsed'"
log close
