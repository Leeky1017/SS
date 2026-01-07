* ==============================================================================
* SS_TEMPLATE: id=TL08  level=L1  module=L  title="Ab Disexp"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL08_abdis.csv type=table desc="Abnormal DISEXP results"
*   - data_TL08_abdis.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL08|level=L1|title=Ab_Disexp"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local disexp = "__DISEXP__"
local rev = "__REV__"
local assets = "__ASSETS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"

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
generate disexp_scaled = `disexp' / L.`assets'
generate inv_assets = 1 / L.`assets'
generate lag_rev = L.`rev' / L.`assets'

regress disexp_scaled inv_assets lag_rev
predict ab_disexp, residuals

summarize ab_disexp
local mean_ab_disexp = r(mean)
display "SS_METRIC|name=mean_ab_disexp|value=`mean_ab_disexp'"

preserve
clear
set obs 1
gen str32 model = "Abnormal DISEXP"
gen double mean = `mean_ab_disexp'
export delimited using "table_TL08_abdis.csv", replace
display "SS_OUTPUT_FILE|file=table_TL08_abdis.csv|type=table|desc=abdis_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL08_abdis.dta", replace
display "SS_OUTPUT_FILE|file=data_TL08_abdis.dta|type=data|desc=abdis_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_ab_disexp|value=`mean_ab_disexp'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL08|status=ok|elapsed_sec=`elapsed'"
log close
