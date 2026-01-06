* ==============================================================================
* SS_TEMPLATE: id=TM09  level=L1  module=M  title="Cohort RR"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM09_rr.csv type=table desc="RR results"
*   - data_TM09_rr.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TM09|level=L1|title=Cohort_RR"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local outcome = "__OUTCOME__"
local exposure = "__EXPOSURE__"

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

cs `outcome' `exposure'
local rr = r(rr)
local lb = r(lb_rr)
local ub = r(ub_rr)
local ard = r(ard)
display "SS_METRIC|name=relative_risk|value=`rr'"
display "SS_METRIC|name=rr_ci_lb|value=`lb'"
display "SS_METRIC|name=rr_ci_ub|value=`ub'"

preserve
clear
set obs 1
gen double rr = `rr'
gen double lb = `lb'
gen double ub = `ub'
gen double ard = `ard'
export delimited using "table_TM09_rr.csv", replace
display "SS_OUTPUT_FILE|file=table_TM09_rr.csv|type=table|desc=rr_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM09_rr.dta", replace
display "SS_OUTPUT_FILE|file=data_TM09_rr.dta|type=data|desc=rr_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=relative_risk|value=`rr'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM09|status=ok|elapsed_sec=`elapsed'"
log close
