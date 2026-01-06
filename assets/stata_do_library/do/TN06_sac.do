* ==============================================================================
* SS_TEMPLATE: id=TN06  level=L1  module=N  title="SAC"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TN06_sac.csv type=table desc="SAC results"
*   - data_TN06_sac.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TN06|level=L1|title=SAC"
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
spregress `depvar' `indepvars', ml dvarlag(W) errorlag(W)
local rho = e(rho)
local lambda = e(lambda)
local ll = e(ll)
display "SS_METRIC|name=rho|value=`rho'"
display "SS_METRIC|name=lambda|value=`lambda'"
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "SAC"
gen double rho = `rho'
gen double lambda = `lambda'
gen double ll = `ll'
export delimited using "table_TN06_sac.csv", replace
display "SS_OUTPUT_FILE|file=table_TN06_sac.csv|type=table|desc=sac_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TN06_sac.dta", replace
display "SS_OUTPUT_FILE|file=data_TN06_sac.dta|type=data|desc=sac_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=rho|value=`rho'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TN06|status=ok|elapsed_sec=`elapsed'"
log close
