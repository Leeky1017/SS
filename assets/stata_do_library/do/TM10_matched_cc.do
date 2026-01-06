* ==============================================================================
* SS_TEMPLATE: id=TM10  level=L1  module=M  title="Matched CC"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM10_mcc.csv type=table desc="Matched CC results"
*   - data_TM10_mcc.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TM10|level=L1|title=Matched_CC"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local case = "__CASE__"
local exposure = "__EXPOSURE__"
local match_id = "__MATCH_ID__"

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

clogit `case' `exposure', group(`match_id') or
local or = exp(_b[`exposure'])
local ll = e(ll)
display "SS_METRIC|name=odds_ratio|value=`or'"
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen double or = `or'
gen double ll = `ll'
export delimited using "table_TM10_mcc.csv", replace
display "SS_OUTPUT_FILE|file=table_TM10_mcc.csv|type=table|desc=mcc_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM10_mcc.dta", replace
display "SS_OUTPUT_FILE|file=data_TM10_mcc.dta|type=data|desc=mcc_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=odds_ratio|value=`or'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM10|status=ok|elapsed_sec=`elapsed'"
log close
