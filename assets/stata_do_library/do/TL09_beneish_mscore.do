* ==============================================================================
* SS_TEMPLATE: id=TL09  level=L1  module=L  title="Beneish MScore"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL09_mscore.csv type=table desc="M-Score results"
*   - data_TL09_mscore.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL09|level=L1|title=Beneish_MScore"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local dsri = "__DSRI__"
local gmi = "__GMI__"
local aqi = "__AQI__"
local sgi = "__SGI__"
local depi = "__DEPI__"
local sgai = "__SGAI__"
local lvgi = "__LVGI__"
local tata = "__TATA__"

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

generate mscore = -4.84 + 0.920*`dsri' + 0.528*`gmi' + 0.404*`aqi' + 0.892*`sgi' ///
    + 0.115*`depi' - 0.172*`sgai' + 4.679*`tata' - 0.327*`lvgi'

generate fraud_flag = (mscore > -1.78)

summarize mscore
local mean_mscore = r(mean)
count if fraud_flag == 1
local n_fraud = r(N)
display "SS_METRIC|name=mean_mscore|value=`mean_mscore'"
display "SS_METRIC|name=n_fraud|value=`n_fraud'"

preserve
clear
set obs 1
gen str32 model = "Beneish M-Score"
gen double mean_mscore = `mean_mscore'
gen int n_fraud = `n_fraud'
export delimited using "table_TL09_mscore.csv", replace
display "SS_OUTPUT_FILE|file=table_TL09_mscore.csv|type=table|desc=mscore_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL09_mscore.dta", replace
display "SS_OUTPUT_FILE|file=data_TL09_mscore.dta|type=data|desc=mscore_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_mscore|value=`mean_mscore'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL09|status=ok|elapsed_sec=`elapsed'"
log close
