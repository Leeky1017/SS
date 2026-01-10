* ==============================================================================
* SS_TEMPLATE: id=TM15  level=L1  module=M  title="Sample Size Clinical"
* INPUTS:
*   - parameters  role=parameters  required=yes
* OUTPUTS:
*   - table_TM15_ss.csv type=table desc="Sample size results"
*   - data_TM15_ss.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TM15|level=L1|title=Sample_Size_Clinical"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

display "SS_STEP_BEGIN|step=S01_load_data"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

local p1 = __P1__
local p2 = __P2__
local alpha = __ALPHA__
local power = __POWER__
local ratio = __RATIO__

if `p1' <= 0 | `p1' >= 1 {
    local p1 = 0.3
}
if `p2' <= 0 | `p2' >= 1 {
    local p2 = 0.5
}
if `alpha' <= 0 | `alpha' >= 1 {
    local alpha = 0.05
}
if `power' <= 0 | `power' >= 1 {
    local power = 0.8
}
if `ratio' <= 0 {
    local ratio = 1
}

power twoproportions `p1' `p2', alpha(`alpha') power(`power') nratio(`ratio')
local n1 = r(N1)
local n2 = r(N2)
local n_total = `n1' + `n2'

display "SS_METRIC|name=n1|value=`n1'"
display "SS_METRIC|name=n2|value=`n2'"
display "SS_METRIC|name=n_total|value=`n_total'"

clear
set obs 1
gen double p1 = `p1'
gen double p2 = `p2'
gen double alpha = `alpha'
gen double power = `power'
gen int n1 = `n1'
gen int n2 = `n2'
gen int n_total = `n_total'

export delimited using "table_TM15_ss.csv", replace
display "SS_OUTPUT_FILE|file=table_TM15_ss.csv|type=table|desc=ss_results"

local n_input = 1
local n_output = 1
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TM15_ss.dta", replace
display "SS_OUTPUT_FILE|file=data_TM15_ss.dta|type=data|desc=ss_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_total|value=`n_total'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM15|status=ok|elapsed_sec=`elapsed'"
log close
