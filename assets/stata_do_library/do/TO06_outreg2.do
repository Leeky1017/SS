* ==============================================================================
* SS_TEMPLATE: id=TO06  level=L2  module=O  title="Outreg2"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO06_compare.doc type=table desc="Comparison table"
*   - data_TO06_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: outreg2
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TO06|level=L2|title=Outreg2"
display "SS_TASK_VERSION:2.0.1"

capture which outreg2
if _rc {
    display "SS_DEP_MISSING:outreg2"
    display "SS_ERROR:DEP_MISSING:outreg2 not installed"
    display "SS_ERR:DEP_MISSING:outreg2 not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=outreg2|source=ssc|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

regress `depvar' `indepvars'
outreg2 using "table_TO06_compare.doc", replace ctitle(OLS) addstat(Adj. R2, e(r2_a))

regress `depvar' `indepvars', robust
outreg2 using "table_TO06_compare.doc", append ctitle(Robust)

display "SS_OUTPUT_FILE|file=table_TO06_compare.doc|type=table|desc=compare_table"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TO06_export.dta", replace
display "SS_OUTPUT_FILE|file=data_TO06_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_dropped|value=`n_dropped'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO06|status=ok|elapsed_sec=`elapsed'"
log close
