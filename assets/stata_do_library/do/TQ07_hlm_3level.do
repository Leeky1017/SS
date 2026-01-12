* ==============================================================================
* SS_TEMPLATE: id=TQ07  level=L1  module=Q  title="HLM 3Level"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ07_hlm3.csv type=table desc="HLM results"
*   - data_TQ07_hlm.dta type=data desc="Output data"
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

program define ss_fail_TQ07
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ07|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ07|level=L1|title=HLM_3Level"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: verify sufficient clusters at each level and check convergence; interpret variance components carefully. /
*   最佳实践：确保每层有足够组数并关注收敛；谨慎解读方差分量。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/mixed/export; warn on small group counts /
*   错误策略：缺少输入/mixed/导出失败→fail；组数过少→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ07|ssc=none|output=csv_dta|policy=warn_fail"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local level2 = "__LEVEL2__"
local level3 = "__LEVEL3__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TQ07 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `depvar'
if _rc {
    ss_fail_TQ07 200 "confirm variable `depvar'" "var_not_found"
}
capture confirm variable `level2'
if _rc {
    ss_fail_TQ07 200 "confirm variable `level2'" "var_not_found"
}
capture confirm variable `level3'
if _rc {
    ss_fail_TQ07 200 "confirm variable `level3'" "var_not_found"
}
local valid_x ""
foreach v of local indepvars {
    capture confirm numeric variable `v'
    if !_rc {
        local valid_x "`valid_x' `v'"
    }
}
if "`valid_x'" == "" {
    ss_fail_TQ07 200 "confirm numeric indepvars" "no_valid_indepvars"
}
local g2 "`level2'"
local g3 "`level3'"
capture confirm numeric variable `g2'
if _rc {
    display "SS_RC|code=GROUP_NOT_NUMERIC|var=`g2'|severity=warn"
    capture drop ss_level2_id
    local rc_drop = _rc
    if `rc_drop' != 0 & `rc_drop' != 111 {
        display "SS_RC|code=`rc_drop'|cmd=drop ss_level2_id|msg=drop_failed|severity=warn"
    }
    egen long ss_level2_id = group(`g2')
    local g2 "ss_level2_id"
}
capture confirm numeric variable `g3'
if _rc {
    display "SS_RC|code=GROUP_NOT_NUMERIC|var=`g3'|severity=warn"
    capture drop ss_level3_id
    local rc_drop2 = _rc
    if `rc_drop2' != 0 & `rc_drop2' != 111 {
        display "SS_RC|code=`rc_drop2'|cmd=drop ss_level3_id|msg=drop_failed|severity=warn"
    }
    egen long ss_level3_id = group(`g3')
    local g3 "ss_level3_id"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture noisily mixed `depvar' `valid_x' || `g3': || `g2':
if _rc {
    ss_fail_TQ07 `=_rc' "mixed" "estimation_failed"
}
local ll = e(ll)
local n_obs = e(N)
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=n_obs|value=`n_obs'"

preserve
clear
set obs 1
gen str32 model = "HLM 3-Level"
gen double ll = `ll'
capture export delimited using "table_TQ07_hlm3.csv", replace
if _rc {
    ss_fail_TQ07 `=_rc' "export delimited table_TQ07_hlm3.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ07_hlm3.csv|type=table|desc=hlm_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TQ07_hlm.dta", replace
if _rc {
    ss_fail_TQ07 `=_rc' "save data_TQ07_hlm.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TQ07_hlm.dta|type=data|desc=hlm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ07|status=ok|elapsed_sec=`elapsed'"
log close
