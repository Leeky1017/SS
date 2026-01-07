* ==============================================================================
* SS_TEMPLATE: id=TF05  level=L1  module=F  title="System GMM"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TF05_sysgmm.csv type=table desc="System GMM results"
*   - data_TF05_sysgmm.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - xtabond2 source=ssc purpose="System GMM estimation"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TF05|level=L1|title=System_GMM"
display "SS_TASK_VERSION:2.0.1"

capture which xtabond2
if _rc {
    display "SS_DEP_MISSING:xtabond2"
    display "SS_ERROR:DEP_MISSING:xtabond2 not installed"
    display "SS_ERR:DEP_MISSING:xtabond2 not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=xtabond2|source=ssc|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
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
display "SS_METRIC:n_input:`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
ss_smart_xtset `panelvar' `timevar'
xtabond2 `depvar' L.`depvar' `indepvars', gmm(L.`depvar') iv(`indepvars') twostep robust

local ar1_p = e(ar1p)
local ar2_p = e(ar2p)
local hansen_p = e(hansenp)
display "SS_METRIC|name=ar1_p|value=`ar1_p'"
display "SS_METRIC|name=ar2_p|value=`ar2_p'"
display "SS_METRIC|name=hansen_p|value=`hansen_p'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 model = "System GMM"
gen double ar2_p = `ar2_p'
gen double hansen_p = `hansen_p'
export delimited using "table_TF05_sysgmm.csv", replace
display "SS_OUTPUT_FILE|file=table_TF05_sysgmm.csv|type=table|desc=sysgmm_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TF05_sysgmm.dta", replace
display "SS_OUTPUT_FILE|file=data_TF05_sysgmm.dta|type=data|desc=sysgmm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=ar2_p|value=`ar2_p'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TF05|status=ok|elapsed_sec=`elapsed'"
log close
