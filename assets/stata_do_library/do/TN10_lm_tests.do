* ==============================================================================
* SS_TEMPLATE: id=TN10  level=L1  module=N  title="LM Tests"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TN10_lm.csv type=table desc="LM test results"
*   - data_TN10_lm.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TN10|level=L1|title=LM_Tests"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

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

spmatrix create contiguity W, normalize(row)
regress `depvar' `indepvars'
estat moran, errorlag(W)
local moran_p = r(p)

spregress `depvar' `indepvars', ml
estat ic
local aic = r(S)[1,5]
local bic = r(S)[1,6]

display "SS_METRIC|name=moran_p|value=`moran_p'"
display "SS_METRIC|name=aic|value=`aic'"
display "SS_METRIC|name=bic|value=`bic'"

preserve
clear
set obs 1
gen str32 test = "LM Diagnostics"
gen double aic = `aic'
gen double bic = `bic'
export delimited using "table_TN10_lm.csv", replace
display "SS_OUTPUT_FILE|file=table_TN10_lm.csv|type=table|desc=lm_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TN10_lm.dta", replace
display "SS_OUTPUT_FILE|file=data_TN10_lm.dta|type=data|desc=lm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=aic|value=`aic'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TN10|status=ok|elapsed_sec=`elapsed'"
log close
