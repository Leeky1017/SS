* ==============================================================================
* SS_TEMPLATE: id=TD02  level=L1  module=D  title="High Dim FE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD02_hdfe.csv type=table desc="HDFE regression results"
*   - data_TD02_hdfe.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - reghdfe source=ssc purpose="high-dimensional fixed effects"
*   - estout source=ssc purpose="table export"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TD02|level=L1|title=High_Dim_FE"
display "SS_TASK_VERSION|version=2.0.1"

capture which reghdfe
if _rc {
    display "SS_DEP_CHECK|pkg=reghdfe|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=reghdfe"
    display "SS_RC|code=199|cmd=which reghdfe|msg=dependency_missing|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 199
}

display "SS_DEP_CHECK|pkg=reghdfe|source=ssc|status=ok"
capture which esttab
if _rc {
    display "SS_DEP_CHECK|pkg=estout|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=estout"
    display "SS_RC|code=199|cmd=which esttab|msg=dependency_missing|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=estout|source=ssc|status=ok"
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local absorb_vars = "__ABSORB_VARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture noisily reghdfe `depvar' `indepvars', absorb(`absorb_vars') vce(robust)
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=reghdfe|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

local r2 = e(r2)
display "SS_METRIC|name=r2|value=`r2'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
estimates store hdfe_model
capture noisily esttab hdfe_model using "table_TD02_hdfe.csv", replace cells(b se) csv
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=esttab|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
display "SS_OUTPUT_FILE|file=table_TD02_hdfe.csv|type=table|desc=hdfe_results"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD02_hdfe.dta", replace
display "SS_OUTPUT_FILE|file=data_TD02_hdfe.dta|type=data|desc=hdfe_data"
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

display "SS_TASK_END|id=TD02|status=ok|elapsed_sec=`elapsed'"
log close
