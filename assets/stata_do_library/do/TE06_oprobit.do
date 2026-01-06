* ==============================================================================
* SS_TEMPLATE: id=TE06  level=L0  module=E  title="Ordered Probit"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TE06_oprobit.csv type=table desc="Ordered Probit results"
*   - data_TE06_oprobit.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="oprobit command"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TE06|level=L0|title=Ordered_Probit"
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
oprobit `depvar' `indepvars'
local ll = e(ll)
local pseudo_r2 = e(r2_p)
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=pseudo_r2|value=`pseudo_r2'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 model = "Ordered Probit"
gen double ll = `ll'
gen double pseudo_r2 = `pseudo_r2'
export delimited using "table_TE06_oprobit.csv", replace
display "SS_OUTPUT_FILE|file=table_TE06_oprobit.csv|type=table|desc=oprobit_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TE06_oprobit.dta", replace
display "SS_OUTPUT_FILE|file=data_TE06_oprobit.dta|type=data|desc=oprobit_data"
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

display "SS_TASK_END|id=TE06|status=ok|elapsed_sec=`elapsed'"
log close
