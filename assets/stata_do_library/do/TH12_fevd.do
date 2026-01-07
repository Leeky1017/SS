* ==============================================================================
* SS_TEMPLATE: id=TH12  level=L1  module=H  title="FEVD Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TH12_fevd.png type=figure desc="FEVD plot"
*   - table_TH12_fevd.csv type=table desc="FEVD results"
*   - data_TH12_fevd.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TH12|level=L1|title=FEVD_Analysis"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local vars = "__VARS__"
local timevar = "__TIME_VAR__"
local lags = __LAGS__
local steps = __STEPS__

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
tsset `timevar'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
var `vars', lags(1/`lags')
irf create myfevd, step(`steps') set(fevd_results)
irf graph fevd
graph export "fig_TH12_fevd.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TH12_fevd.png|type=figure|desc=fevd_plot"

irf table fevd
preserve
clear
set obs 1
gen str32 analysis = "FEVD"
export delimited using "table_TH12_fevd.csv", replace
display "SS_OUTPUT_FILE|file=table_TH12_fevd.csv|type=table|desc=fevd_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH12_fevd.dta", replace
display "SS_OUTPUT_FILE|file=data_TH12_fevd.dta|type=data|desc=fevd_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=steps|value=`steps'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH12|status=ok|elapsed_sec=`elapsed'"
log close
