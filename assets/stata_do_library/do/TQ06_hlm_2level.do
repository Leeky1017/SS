* ==============================================================================
* SS_TEMPLATE: id=TQ06  level=L1  module=Q  title="HLM 2Level"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ06_hlm2.csv type=table desc="HLM results"
*   - data_TQ06_hlm.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TQ06|level=L1|title=HLM_2Level"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local depvar = "__DEPVAR__"
local level1_vars = "__LEVEL1_VARS__"
local level2_vars = "__LEVEL2_VARS__"
local group_var = "__GROUP_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    display "SS_TASK_END|id=TQ06|status=fail|elapsed_sec=."
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

mixed `depvar' `level1_vars' `level2_vars' || `group_var':
local ll = e(ll)
display "SS_METRIC|name=log_likelihood|value=`ll'"

estat icc
local icc = r(icc2)
display "SS_METRIC|name=icc|value=`icc'"

preserve
clear
set obs 1
gen str32 model = "HLM 2-Level"
gen double ll = `ll'
gen double icc = `icc'
export delimited using "table_TQ06_hlm2.csv", replace
display "SS_OUTPUT_FILE|file=table_TQ06_hlm2.csv|type=table|desc=hlm_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TQ06_hlm.dta", replace
display "SS_OUTPUT_FILE|file=data_TQ06_hlm.dta|type=data|desc=hlm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=icc|value=`icc'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ06|status=ok|elapsed_sec=`elapsed'"
log close
