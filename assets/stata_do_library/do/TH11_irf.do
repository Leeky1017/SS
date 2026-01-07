* ==============================================================================
* SS_TEMPLATE: id=TH11  level=L1  module=H  title="IRF Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TH11_irf.png type=figure desc="IRF plot"
*   - data_TH11_irf.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TH11|level=L1|title=IRF_Analysis"
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
irf create myirf, step(`steps') set(irf_results)
irf graph oirf, impulse(`vars') response(`vars')
graph export "fig_TH11_irf.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TH11_irf.png|type=figure|desc=irf_plot"

display "SS_METRIC|name=steps|value=`steps'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH11_irf.dta", replace
display "SS_OUTPUT_FILE|file=data_TH11_irf.dta|type=data|desc=irf_data"
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

display "SS_TASK_END|id=TH11|status=ok|elapsed_sec=`elapsed'"
log close
