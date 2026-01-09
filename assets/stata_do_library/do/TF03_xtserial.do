* ==============================================================================
* SS_TEMPLATE: id=TF03  level=L1  module=F  title="XTSERIAL"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TF03_serial.csv type=table desc="Serial correlation test results"
*   - data_TF03_serial.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - xtserial source=ssc purpose="Wooldridge test"
* ==============================================================================

capture log close _all
if _rc != 0 {
    display "SS_RC|code=`=_rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TF03
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TF03|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TF03|level=L1|title=XTSERIAL"
display "SS_TASK_VERSION|version=2.0.1"

capture which xtserial
if _rc {
    display "SS_DEP_CHECK|pkg=xtserial|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=xtserial"
    ss_fail_TF03 199 "which xtserial" "dependency_missing"
}
display "SS_DEP_CHECK|pkg=xtserial|source=ssc|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TF03 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `panelvar'
if _rc {
    ss_fail_TF03 111 "confirm variable `panelvar'" "panel_var_missing"
}
capture confirm variable `timevar'
if _rc {
    ss_fail_TF03 111 "confirm variable `timevar'" "time_var_missing"
}
capture xtset `panelvar' `timevar'
if _rc {
    ss_fail_TF03 `=_rc' "xtset `panelvar' `timevar'" "xtset_failed"
}
capture noisily xtserial `depvar' `indepvars'
if _rc {
    ss_fail_TF03 `=_rc' "xtserial" "xtserial_failed"
}

local f = r(F)
local p = r(p)
display "SS_METRIC|name=f_stat|value=`f'"
display "SS_METRIC|name=p_value|value=`p'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 test = "Wooldridge"
gen double f = `f'
gen double p = `p'
capture export delimited using "table_TF03_serial.csv", replace
if _rc {
    ss_fail_TF03 `=_rc' "export delimited" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TF03_serial.csv|type=table|desc=serial_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TF03_serial.dta", replace
if _rc {
    ss_fail_TF03 `=_rc' "save" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TF03_serial.dta|type=data|desc=serial_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=f_stat|value=`f'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TF03|status=ok|elapsed_sec=`elapsed'"
log close
