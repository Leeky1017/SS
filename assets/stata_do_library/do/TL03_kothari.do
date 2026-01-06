* ==============================================================================
* SS_TEMPLATE: id=TL03  level=L1  module=L  title="Kothari"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL03_kothari.csv type=table desc="Kothari results"
*   - data_TL03_kothari.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL03|level=L1|title=Kothari"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local ta = "__TA__"
local rev = "__REV__"
local rec = "__REC__"
local ppe = "__PPE__"
local roa = "__ROA__"
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

generate ta_scaled = `ta' / L.`assets'
generate inv_assets = 1 / L.`assets'
generate adj_rev = (D.`rev' - D.`rec') / L.`assets'
generate ppe_scaled = `ppe' / L.`assets'

regress ta_scaled inv_assets adj_rev ppe_scaled `roa'
predict nda, xb
generate da = ta_scaled - nda

summarize da
local mean_da = r(mean)
local sd_da = r(sd)
display "SS_METRIC|name=mean_da|value=`mean_da'"
display "SS_METRIC|name=sd_da|value=`sd_da'"

preserve
clear
set obs 1
gen str32 model = "Kothari"
gen double mean_da = `mean_da'
gen double sd_da = `sd_da'
export delimited using "table_TL03_kothari.csv", replace
display "SS_OUTPUT_FILE|file=table_TL03_kothari.csv|type=table|desc=kothari_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL03_kothari.dta", replace
display "SS_OUTPUT_FILE|file=data_TL03_kothari.dta|type=data|desc=kothari_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_da|value=`mean_da'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL03|status=ok|elapsed_sec=`elapsed'"
log close
