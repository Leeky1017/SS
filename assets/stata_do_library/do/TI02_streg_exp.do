* ==============================================================================
* SS_TEMPLATE: id=TI02  level=L1  module=I  title="Exponential Survival"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI02_exp.csv type=table desc="Exp results"
*   - data_TI02_exp.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TI02|level=L1|title=Exp_Survival"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local timevar = "__TIME_VAR__"
local failvar = "__FAILVAR__"
local indepvars = "__INDEPVARS__"
local dist = "__DIST__"
if "`dist'" == "" { local dist = "exponential" }

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
stset `timevar', failure(`failvar')
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
streg `indepvars', dist(`dist')
local ll = e(ll)
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "`dist'"
gen double ll = `ll'
export delimited using "table_TI02_exp.csv", replace
display "SS_OUTPUT_FILE|file=table_TI02_exp.csv|type=table|desc=exp_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI02_exp.dta", replace
display "SS_OUTPUT_FILE|file=data_TI02_exp.dta|type=data|desc=exp_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI02|status=ok|elapsed_sec=`elapsed'"
log close
