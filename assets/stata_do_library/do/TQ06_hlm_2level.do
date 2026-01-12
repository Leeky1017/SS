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

program define ss_fail_TQ06
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ06|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ06|level=L1|title=HLM_2Level"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: center predictors as needed and report ICC; check group counts and convergence. /
*   最佳实践：按需要中心化解释变量并报告 ICC；检查组数并关注收敛。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/mixed; warn when ICC is unavailable /
*   错误策略：缺少输入/mixed 失败→fail；ICC 不可得→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ06|ssc=none|output=csv_dta|policy=warn_fail"

local depvar = "__DEPVAR__"
local level1_vars = "__LEVEL1_VARS__"
local level2_vars = "__LEVEL2_VARS__"
local group_var = "__GROUP_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TQ06 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `depvar'
if _rc {
    ss_fail_TQ06 200 "confirm variable `depvar'" "var_not_found"
}
capture confirm variable `group_var'
if _rc {
    ss_fail_TQ06 200 "confirm variable `group_var'" "var_not_found"
}
local valid_x ""
foreach v of local level1_vars {
    capture confirm numeric variable `v'
    if !_rc {
        local valid_x "`valid_x' `v'"
    }
}
foreach v of local level2_vars {
    capture confirm numeric variable `v'
    if !_rc {
        local valid_x "`valid_x' `v'"
    }
}
if "`valid_x'" == "" {
    ss_fail_TQ06 200 "confirm numeric predictors" "no_valid_predictors"
}
local grp "`group_var'"
capture confirm numeric variable `grp'
if _rc {
    display "SS_RC|code=GROUP_NOT_NUMERIC|var=`grp'|severity=warn"
    capture drop ss_group_id
    local rc_drop = _rc
    if `rc_drop' != 0 & `rc_drop' != 111 {
        display "SS_RC|code=`rc_drop'|cmd=drop ss_group_id|msg=drop_failed|severity=warn"
    }
    egen long ss_group_id = group(`grp')
    local grp "ss_group_id"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture noisily mixed `depvar' `valid_x' || `grp':
if _rc {
    ss_fail_TQ06 `=_rc' "mixed" "estimation_failed"
}
local ll = e(ll)
display "SS_METRIC|name=log_likelihood|value=`ll'"

local icc = .
capture noisily estat icc
if _rc {
    display "SS_RC|code=`=_rc'|cmd=estat icc|msg=icc_failed|severity=warn"
}
else {
    local icc = r(icc2)
}
display "SS_METRIC|name=icc|value=`icc'"

preserve
clear
set obs 1
gen str32 model = "HLM 2-Level"
gen double ll = `ll'
gen double icc = `icc'
capture export delimited using "table_TQ06_hlm2.csv", replace
if _rc {
    ss_fail_TQ06 `=_rc' "export delimited table_TQ06_hlm2.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ06_hlm2.csv|type=table|desc=hlm_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TQ06_hlm.dta", replace
if _rc {
    ss_fail_TQ06 `=_rc' "save data_TQ06_hlm.dta" "save_failed"
}
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
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ06|status=ok|elapsed_sec=`elapsed'"
log close
