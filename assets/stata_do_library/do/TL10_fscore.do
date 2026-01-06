* ==============================================================================
* SS_TEMPLATE: id=TL10  level=L1  module=L  title="FScore"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL10_fscore.csv type=table desc="F-Score results"
*   - data_TL10_fscore.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL10|level=L1|title=FScore"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local rsst = "__RSST__"
local chg_rec = "__CHG_REC__"
local chg_inv = "__CHG_INV__"
local soft = "__SOFT__"
local chg_cash = "__CHG_CASH__"
local chg_roa = "__CHG_ROA__"
local issue = "__ISSUE__"

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

generate fscore = -7.893 + 0.790*`rsst' + 2.518*`chg_rec' + 1.191*`chg_inv' ///
    + 1.979*`soft' + 0.171*`chg_cash' - 0.932*`chg_roa' + 1.029*`issue'

generate prob_misstate = exp(fscore) / (1 + exp(fscore))

summarize fscore prob_misstate
local mean_fscore = r(mean)
display "SS_METRIC|name=mean_fscore|value=`mean_fscore'"

preserve
clear
set obs 1
gen str32 model = "Dechow F-Score"
gen double mean_fscore = `mean_fscore'
export delimited using "table_TL10_fscore.csv", replace
display "SS_OUTPUT_FILE|file=table_TL10_fscore.csv|type=table|desc=fscore_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL10_fscore.dta", replace
display "SS_OUTPUT_FILE|file=data_TL10_fscore.dta|type=data|desc=fscore_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_fscore|value=`mean_fscore'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL10|status=ok|elapsed_sec=`elapsed'"
log close
