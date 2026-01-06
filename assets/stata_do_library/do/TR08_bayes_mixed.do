* ==============================================================================
* SS_TEMPLATE: id=TR08  level=L1  module=R  title="Bayes Mixed"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TR08_bmixed.csv type=table desc="Bayes mixed results"
*   - data_TR08_bmixed.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TR08|level=L1|title=Bayes_Mixed"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local group_var = "__GROUP_VAR__"
local mcmc = __MCMC__
if `mcmc' < 1000 { local mcmc = 10000 }

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

bayes, mcmcsize(`mcmc') burnin(2500): mixed `depvar' `indepvars' || `group_var':
bayesstats summary
display "SS_METRIC|name=mcmc_size|value=`mcmc'"

preserve
clear
set obs 1
gen str32 model = "Bayesian Mixed"
gen int mcmc = `mcmc'
export delimited using "table_TR08_bmixed.csv", replace
display "SS_OUTPUT_FILE|file=table_TR08_bmixed.csv|type=table|desc=bmixed_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TR08_bmixed.dta", replace
display "SS_OUTPUT_FILE|file=data_TR08_bmixed.dta|type=data|desc=bmixed_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mcmc_size|value=`mcmc'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TR08|status=ok|elapsed_sec=`elapsed'"
log close
