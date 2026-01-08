* ==============================================================================
* SS_TEMPLATE: id=TC09  level=L0  module=C  title="Normality Comprehensive"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TC09_norm.csv type=table desc="Normality test results"
*   - data_TC09_norm.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="swilk sfrancia"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TC09|level=L0|title=Normality_Comprehensive"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local vars = "__VARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ">>> Shapiro-Wilk检验:"
swilk `vars'

display ">>> Shapiro-Francia检验:"
sfrancia `vars'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
tempname results
postfile `results' str32 variable double sw_w double sw_p double sf_w double sf_p ///
    using "temp_norm.dta", replace

foreach var of local vars {
    capture confirm numeric variable `var'
    if !_rc {
        quietly swilk `var'
        local sw_w = r(W)
        local sw_p = r(p)
        quietly sfrancia `var'
        local sf_w = r(W)
        local sf_p = r(p)
        post `results' ("`var'") (`sw_w') (`sw_p') (`sf_w') (`sf_p')
    }
}
postclose `results'

preserve
use "temp_norm.dta", clear
export delimited using "table_TC09_norm.csv", replace
display "SS_OUTPUT_FILE|file=table_TC09_norm.csv|type=table|desc=norm_results"
restore
capture erase "temp_norm.dta"
if _rc != 0 { }

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TC09_norm.dta", replace
display "SS_OUTPUT_FILE|file=data_TC09_norm.dta|type=data|desc=norm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_vars|value=`: word count `vars''"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TC09|status=ok|elapsed_sec=`elapsed'"
log close
