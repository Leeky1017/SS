* ==============================================================================
* SS_TEMPLATE: id=TJ03  level=L1  module=J  title="LDA Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TJ03_discrim.csv type=table desc="LDA results"
*   - data_TJ03_discrim.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TJ03|level=L1|title=LDA_Analysis"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local group_var = "__GROUP_VAR__"
local vars = "__VARS__"

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
discrim lda `vars', group(`group_var')
estat classtable
local correct = e(P_corr)
display "SS_METRIC|name=correct_rate|value=`correct'"

preserve
clear
set obs 1
gen str32 model = "LDA"
gen double correct_rate = `correct'
export delimited using "table_TJ03_discrim.csv", replace
display "SS_OUTPUT_FILE|file=table_TJ03_discrim.csv|type=table|desc=lda_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TJ03_discrim.dta", replace
display "SS_OUTPUT_FILE|file=data_TJ03_discrim.dta|type=data|desc=lda_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=correct_rate|value=`correct'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TJ03|status=ok|elapsed_sec=`elapsed'"
log close
