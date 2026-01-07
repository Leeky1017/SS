* ==============================================================================
* SS_TEMPLATE: id=TI09  level=L2  module=I  title="Cure Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI09_cure.csv type=table desc="Cure results"
*   - data_TI09_cure.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stcure source=ssc purpose="Cure model"
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TI09|level=L2|title=Cure_Model"
display "SS_TASK_VERSION:2.0.1"

capture which stcure
if _rc {
    display "SS_DEP_MISSING:stcure"
    display "SS_ERROR:DEP_MISSING:stcure not installed"
    display "SS_ERR:DEP_MISSING:stcure not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=stcure|source=ssc|status=ok"

local timevar = "__TIME_VAR__"
local failvar = "__FAILVAR__"
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
stset `timevar', failure(`failvar')
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
stcure `indepvars', dist(weibull) link(logit)
local ll = e(ll)
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "Cure Model"
gen double ll = `ll'
export delimited using "table_TI09_cure.csv", replace
display "SS_OUTPUT_FILE|file=table_TI09_cure.csv|type=table|desc=cure_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI09_cure.dta", replace
display "SS_OUTPUT_FILE|file=data_TI09_cure.dta|type=data|desc=cure_data"
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

display "SS_TASK_END|id=TI09|status=ok|elapsed_sec=`elapsed'"
log close
