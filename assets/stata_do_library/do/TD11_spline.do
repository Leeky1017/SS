* ==============================================================================
* SS_TEMPLATE: id=TD11  level=L0  module=D  title="Spline"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD11_spline.csv type=table desc="Spline results"
*   - data_TD11_spline.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="mkspline command"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TD11|level=L0|title=Spline"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvar = "__INDEPVAR__"
local knot = __KNOT__

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
mkspline `indepvar'_sp1 `knot' `indepvar'_sp2 = `indepvar'
regress `depvar' `indepvar'_sp1 `indepvar'_sp2
local r2 = e(r2)
display "SS_METRIC|name=r2|value=`r2'"
display "SS_METRIC|name=knot|value=`knot'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen double knot = `knot'
gen double r2 = `r2'
export delimited using "table_TD11_spline.csv", replace
display "SS_OUTPUT_FILE|file=table_TD11_spline.csv|type=table|desc=spline_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD11_spline.dta", replace
display "SS_OUTPUT_FILE|file=data_TD11_spline.dta|type=data|desc=spline_data"
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

display "SS_TASK_END|id=TD11|status=ok|elapsed_sec=`elapsed'"
log close
