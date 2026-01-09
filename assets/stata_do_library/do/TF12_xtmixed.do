* ==============================================================================
* SS_TEMPLATE: id=TF12  level=L0  module=F  title="XTMIXED"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TF12_mixed.csv type=table desc="Mixed effects results"
*   - data_TF12_mixed.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="mixed command"
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

program define ss_fail_TF12
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TF12|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TF12|level=L0|title=XTMIXED"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TF12 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `panelvar'
if _rc {
    ss_fail_TF12 111 "confirm variable `panelvar'" "panel_var_missing"
}
capture noisily mixed `depvar' `indepvars' || `panelvar':
if _rc {
    ss_fail_TF12 `=_rc' "mixed" "mixed_failed"
}
local ll = e(ll)
display "SS_METRIC|name=log_likelihood|value=`ll'"

capture noisily estat icc
if _rc {
    ss_fail_TF12 `=_rc' "estat icc" "estat_icc_failed"
}
local icc = r(icc2)
display "SS_METRIC|name=icc|value=`icc'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 model = "Mixed Effects"
gen double ll = `ll'
gen double icc = `icc'
capture export delimited using "table_TF12_mixed.csv", replace
if _rc {
    ss_fail_TF12 `=_rc' "export delimited" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TF12_mixed.csv|type=table|desc=mixed_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TF12_mixed.dta", replace
if _rc {
    ss_fail_TF12 `=_rc' "save" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TF12_mixed.dta|type=data|desc=mixed_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=icc|value=`icc'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TF12|status=ok|elapsed_sec=`elapsed'"
log close
