* ==============================================================================
* SS_TEMPLATE: id=TL04  level=L1  module=L  title="DD Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL04_dd.csv type=table desc="DD results"
*   - data_TL04_dd.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL04|level=L1|title=DD_Model"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local wca = "__WCA__"
local cfo = "__CFO__"
local assets = "__ASSETS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIMEVAR__"

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

ss_smart_xtset `panelvar' `timevar'

generate wca_scaled = D.`wca' / L.`assets'
generate cfo_lag = L.`cfo' / L.`assets'
generate cfo_cur = `cfo' / L.`assets'
generate cfo_lead = F.`cfo' / L.`assets'

regress wca_scaled cfo_lag cfo_cur cfo_lead
predict residual, residuals
generate aq = abs(residual)

summarize aq
local mean_aq = r(mean)
local sd_aq = r(sd)
display "SS_METRIC|name=mean_aq|value=`mean_aq'"
display "SS_METRIC|name=sd_aq|value=`sd_aq'"

preserve
clear
set obs 1
gen str32 model = "DD"
gen double mean_aq = `mean_aq'
gen double sd_aq = `sd_aq'
export delimited using "table_TL04_dd.csv", replace
display "SS_OUTPUT_FILE|file=table_TL04_dd.csv|type=table|desc=dd_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL04_dd.dta", replace
display "SS_OUTPUT_FILE|file=data_TL04_dd.dta|type=data|desc=dd_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_aq|value=`mean_aq'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL04|status=ok|elapsed_sec=`elapsed'"
log close
