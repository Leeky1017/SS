* ==============================================================================
* SS_TEMPLATE: id=TD12  level=L0  module=D  title="Bootstrap SE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD12_boot.csv type=table desc="Bootstrap results"
*   - data_TD12_boot.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="bootstrap vce"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TD12|level=L0|title=Bootstrap_SE"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local reps = __REPS__
if `reps' < 50 | `reps' > 1000 { local reps = 200 }

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD12|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture noisily regress `depvar' `indepvars', vce(bootstrap, reps(`reps'))
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD12|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local r2 = e(r2)
display "SS_METRIC|name=r2|value=`r2'"
display "SS_METRIC|name=bootstrap_reps|value=`reps'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen int reps = `reps'
gen double r2 = `r2'
export delimited using "table_TD12_boot.csv", replace
display "SS_OUTPUT_FILE|file=table_TD12_boot.csv|type=table|desc=boot_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD12_boot.dta", replace
display "SS_OUTPUT_FILE|file=data_TD12_boot.dta|type=data|desc=boot_data"
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

display "SS_TASK_END|id=TD12|status=ok|elapsed_sec=`elapsed'"
log close
