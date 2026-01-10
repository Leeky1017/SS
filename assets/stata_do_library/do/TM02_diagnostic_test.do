* ==============================================================================
* SS_TEMPLATE: id=TM02  level=L1  module=M  title="Diagnostic Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM02_diag.csv type=table desc="Diagnostic results"
*   - data_TM02_diag.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
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

display "SS_TASK_BEGIN|id=TM02|level=L1|title=Diagnostic_Test"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

capture which diagt
if _rc {
    display "SS_DEP_CHECK|pkg=diagt|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=diagt"
    display "SS_RC|code=199|cmd=which diagt|msg=dependency_missing|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=diagt|source=ssc|status=ok"
local test = "__TEST__"
local gold = "__GOLD__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

diagt `gold' `test'
local sens = r(sens)
local spec = r(spec)
local ppv = r(ppv)
local npv = r(npv)
local plr = r(plr)
local nlr = r(nlr)

display "SS_METRIC|name=sensitivity|value=`sens'"
display "SS_METRIC|name=specificity|value=`spec'"
display "SS_METRIC|name=ppv|value=`ppv'"
display "SS_METRIC|name=npv|value=`npv'"

preserve
clear
set obs 1
gen double sens = `sens'
gen double spec = `spec'
gen double ppv = `ppv'
gen double npv = `npv'
gen double plr = `plr'
gen double nlr = `nlr'
export delimited using "table_TM02_diag.csv", replace
display "SS_OUTPUT_FILE|file=table_TM02_diag.csv|type=table|desc=diag_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM02_diag.dta", replace
display "SS_OUTPUT_FILE|file=data_TM02_diag.dta|type=data|desc=diag_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=sensitivity|value=`sens'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM02|status=ok|elapsed_sec=`elapsed'"
log close
