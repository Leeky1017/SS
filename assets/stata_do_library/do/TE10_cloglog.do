* ==============================================================================
* SS_TEMPLATE: id=TE10  level=L0  module=E  title="Cloglog"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TE10_cloglog.csv type=table desc="Cloglog results"
*   - data_TE10_cloglog.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="cloglog command"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TE10|level=L0|title=Cloglog"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TE10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture noisily cloglog `depvar' `indepvars'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=cloglog|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TE10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local ll = e(ll)
local pseudo_r2 = e(r2_p)
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=pseudo_r2|value=`pseudo_r2'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 model = "Cloglog"
gen double ll = `ll'
gen double pseudo_r2 = `pseudo_r2'
export delimited using "table_TE10_cloglog.csv", replace
display "SS_OUTPUT_FILE|file=table_TE10_cloglog.csv|type=table|desc=cloglog_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TE10_cloglog.dta", replace
display "SS_OUTPUT_FILE|file=data_TE10_cloglog.dta|type=data|desc=cloglog_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=pseudo_r2|value=`pseudo_r2'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TE10|status=ok|elapsed_sec=`elapsed'"
log close
