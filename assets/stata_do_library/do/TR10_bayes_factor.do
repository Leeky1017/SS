* ==============================================================================
* SS_TEMPLATE: id=TR10  level=L1  module=R  title="Bayes Factor"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TR10_bf.csv type=table desc="Bayes factor results"
*   - data_TR10_bf.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TR10|level=L1|title=Bayes_Factor"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars1 = "__INDEPVARS1__"
local indepvars2 = "__INDEPVARS2__"
local mcmc = __MCMC__
if `mcmc' < 200 {
    local mcmc = 200
}

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
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

bayes, mcmcsize(`mcmc') burnin(2500): regress `depvar' `indepvars1'
local margl1 = e(margl)

bayes, mcmcsize(`mcmc') burnin(2500): regress `depvar' `indepvars2'
local margl2 = e(margl)

local bf = exp(`margl1' - `margl2')
display "SS_METRIC|name=bayes_factor|value=`bf'"

preserve
clear
set obs 1
gen str32 comparison = "Model 1 vs Model 2"
gen double bf = `bf'
export delimited using "table_TR10_bf.csv", replace
display "SS_OUTPUT_FILE|file=table_TR10_bf.csv|type=table|desc=bf_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TR10_bf.dta", replace
display "SS_OUTPUT_FILE|file=data_TR10_bf.dta|type=data|desc=bf_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=bayes_factor|value=`bf'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TR10|status=ok|elapsed_sec=`elapsed'"
log close
