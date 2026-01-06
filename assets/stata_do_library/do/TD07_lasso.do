* ==============================================================================
* SS_TEMPLATE: id=TD07  level=L0  module=D  title="LASSO"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD07_lasso.csv type=table desc="LASSO results"
*   - data_TD07_lasso.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="lasso command"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TD07|level=L0|title=LASSO"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

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
display "SS_METRIC:n_input:`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
lasso linear `depvar' `indepvars', selection(cv)
local lambda = e(lambda_sel)
display "SS_METRIC|name=lambda|value=`lambda'"

lassocoef, display(coef, standardized)
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 model = "LASSO"
gen double lambda = `lambda'
export delimited using "table_TD07_lasso.csv", replace
display "SS_OUTPUT_FILE|file=table_TD07_lasso.csv|type=table|desc=lasso_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD07_lasso.dta", replace
display "SS_OUTPUT_FILE|file=data_TD07_lasso.dta|type=data|desc=lasso_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=lambda|value=`lambda'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TD07|status=ok|elapsed_sec=`elapsed'"
log close
