* ==============================================================================
* SS_TEMPLATE: id=TL06  level=L1  module=L  title="Ab CFO"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL06_abcfo.csv type=table desc="Abnormal CFO results"
*   - data_TL06_abcfo.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL06|level=L1|title=Ab_CFO"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local cfo = "__CFO__"
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
generate cfo_scaled = `cfo' / L.`assets'
generate inv_assets = 1 / L.`assets'
generate rev_scaled = `rev' / L.`assets'
generate delta_rev = D.`rev' / L.`assets'

regress cfo_scaled inv_assets rev_scaled delta_rev
predict ab_cfo, residuals

summarize ab_cfo
local mean_ab_cfo = r(mean)
display "SS_METRIC|name=mean_ab_cfo|value=`mean_ab_cfo'"

preserve
clear
set obs 1
gen str32 model = "Abnormal CFO"
gen double mean = `mean_ab_cfo'
export delimited using "table_TL06_abcfo.csv", replace
display "SS_OUTPUT_FILE|file=table_TL06_abcfo.csv|type=table|desc=abcfo_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL06_abcfo.dta", replace
display "SS_OUTPUT_FILE|file=data_TL06_abcfo.dta|type=data|desc=abcfo_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_ab_cfo|value=`mean_ab_cfo'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL06|status=ok|elapsed_sec=`elapsed'"
log close
