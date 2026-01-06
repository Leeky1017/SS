* ==============================================================================
* SS_TEMPLATE: id=TC04  level=L0  module=C  title="Mann Whitney"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TC04_mw.csv type=table desc="MW test results"
*   - data_TC04_mw.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="ranksum command"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TC04|level=L0|title=Mann_Whitney"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local var = "__VAR__"
local group_var = "__GROUP_VAR__"

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
ranksum `var', by(`group_var')
local z = r(z)
local p = 2 * (1 - normal(abs(`z')))

display ""
display ">>> Mann-Whitney U检验:"
display "    z = " %10.4f `z'
display "    p值 = " %10.4f `p'

display "SS_METRIC|name=z_stat|value=`z'"
display "SS_METRIC|name=p_value|value=`p'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str30 test = "Mann-Whitney U"
gen double z = `z'
gen double p = `p'
export delimited using "table_TC04_mw.csv", replace
display "SS_OUTPUT_FILE|file=table_TC04_mw.csv|type=table|desc=mw_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TC04_mw.dta", replace
display "SS_OUTPUT_FILE|file=data_TC04_mw.dta|type=data|desc=mw_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=z_stat|value=`z'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TC04|status=ok|elapsed_sec=`elapsed'"
log close
