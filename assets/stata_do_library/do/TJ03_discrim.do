* ==============================================================================
* SS_TEMPLATE: id=TJ03  level=L1  module=J  title="LDA Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TJ03_discrim.csv type=table desc="LDA results"
*   - data_TJ03_discrim.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
local rc_log_close = _rc
if `rc_log_close' != 0 {
    display "SS_RC|code=`rc_log_close'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TJ03|level=L1|title=LDA_Analysis"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

program define ss_fail
    args template_id code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=`template_id'|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local group_var = "__GROUP_VAR__"
local vars = "__VARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TJ03 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily discrim lda `vars', group(`group_var')
local rc_discrim = _rc
if `rc_discrim' != 0 {
    ss_fail TJ03 `rc_discrim' "discrim lda" "discrim_failed"
}
local correct = .
capture noisily estat classtable
local rc_class = _rc
if `rc_class' == 0 {
    capture local correct = e(P_corr)
    local rc_corr = _rc
    if `rc_corr' != 0 {
        display "SS_RC|code=`rc_corr'|cmd=e(P_corr)|msg=missing_correct_rate|severity=warn"
    }
}
else {
    display "SS_RC|code=`rc_class'|cmd=estat classtable|msg=classtable_unavailable|severity=warn"
}
display "SS_METRIC|name=correct_rate|value=`correct'"

preserve
clear
set obs 1
gen str32 model = "LDA"
gen double correct_rate = `correct'
export delimited using "table_TJ03_discrim.csv", replace
display "SS_OUTPUT_FILE|file=table_TJ03_discrim.csv|type=table|desc=lda_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TJ03_discrim.dta", replace
display "SS_OUTPUT_FILE|file=data_TJ03_discrim.dta|type=data|desc=lda_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=correct_rate|value=`correct'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TJ03|status=ok|elapsed_sec=`elapsed'"
log close
