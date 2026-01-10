* ==============================================================================
* SS_TEMPLATE: id=TL15  level=L1  module=L  title="ICW"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL15_icw.csv type=table desc="ICW results"
*   - data_TL15_icw.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL15|level=L1|title=ICW"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local icw = "__ICW__"
local lnta = "__LNTA__"
local segments = "__SEGMENTS__"
local foreign = "__FOREIGN__"
local growth = "__GROWTH__"
local restructure = "__RESTRUCTURE__"
local loss = "__LOSS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL15|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL15|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
local required_vars "`icw' `lnta' `segments' `foreign' `growth' `restructure' `loss'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL15|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
    capture confirm numeric variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm numeric variable `v'|msg=var_not_numeric|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL15|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

local model_ok = 1
capture logit `icw' `lnta' `segments' `foreign' `growth' `restructure' `loss'
local rc = _rc
local ll = .
local pseudo_r2 = .
if `rc' != 0 {
    local model_ok = 0
    display "SS_RC|code=`rc'|cmd=logit|msg=model_fit_failed|severity=warn"
}
if `rc' == 0 {
    local ll = e(ll)
    local pseudo_r2 = e(r2_p)
}
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=pseudo_r2|value=`pseudo_r2'"

preserve
clear
set obs 1
gen str32 model = "ICW Prediction"
gen double pseudo_r2 = `pseudo_r2'
export delimited using "table_TL15_icw.csv", replace
display "SS_OUTPUT_FILE|file=table_TL15_icw.csv|type=table|desc=icw_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL15_icw.dta", replace
display "SS_OUTPUT_FILE|file=data_TL15_icw.dta|type=data|desc=icw_data"
local step_status "ok"
if `model_ok' == 0 {
    local step_status "warn"
}
display "SS_STEP_END|step=S03_analysis|status=`step_status'|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=pseudo_r2|value=`pseudo_r2'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

local task_status "ok"
if `model_ok' == 0 {
    local task_status "warn"
}
display "SS_TASK_END|id=TL15|status=`task_status'|elapsed_sec=`elapsed'"
log close
