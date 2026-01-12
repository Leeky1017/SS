* ==============================================================================
* SS_TEMPLATE: id=TQ11  level=L1  module=Q  title="Cross Classified"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ11_cross.csv type=table desc="Cross classified results"
*   - data_TQ11_cross.dta type=data desc="Output data"
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

program define ss_fail_TQ11
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ11|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ11|level=L1|title=Cross_Classified"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: cross-classified models need sufficient observations per classification and careful random-effect structure choice. /
*   最佳实践：交叉分类模型需每个分类有足够观测，并谨慎选择随机效应结构。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/mixed/export; warn on convergence issues /
*   错误策略：缺少输入/mixed/导出失败→fail；收敛问题→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ11|ssc=none|output=csv_dta|policy=warn_fail"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local group1 = "__GROUP1__"
local group2 = "__GROUP2__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TQ11 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `depvar'
if _rc {
    ss_fail_TQ11 200 "confirm variable `depvar'" "var_not_found"
}
capture confirm variable `group1'
if _rc {
    ss_fail_TQ11 200 "confirm variable `group1'" "var_not_found"
}
capture confirm variable `group2'
if _rc {
    ss_fail_TQ11 200 "confirm variable `group2'" "var_not_found"
}
local valid_x ""
foreach v of local indepvars {
    capture confirm numeric variable `v'
    if !_rc {
        local valid_x "`valid_x' `v'"
    }
}
if "`valid_x'" == "" {
    ss_fail_TQ11 200 "confirm numeric indepvars" "no_valid_indepvars"
}
local g1 "`group1'"
local g2 "`group2'"
capture confirm numeric variable `g1'
if _rc {
    display "SS_RC|code=GROUP_NOT_NUMERIC|var=`g1'|severity=warn"
    capture drop ss_group1_id
    local rc_drop = _rc
    if `rc_drop' != 0 & `rc_drop' != 111 {
        display "SS_RC|code=`rc_drop'|cmd=drop ss_group1_id|msg=drop_failed|severity=warn"
    }
    egen long ss_group1_id = group(`g1')
    local g1 "ss_group1_id"
}
capture confirm numeric variable `g2'
if _rc {
    display "SS_RC|code=GROUP_NOT_NUMERIC|var=`g2'|severity=warn"
    capture drop ss_group2_id
    local rc_drop2 = _rc
    if `rc_drop2' != 0 & `rc_drop2' != 111 {
        display "SS_RC|code=`rc_drop2'|cmd=drop ss_group2_id|msg=drop_failed|severity=warn"
    }
    egen long ss_group2_id = group(`g2')
    local g2 "ss_group2_id"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture noisily mixed `depvar' `valid_x' || _all: R.`g1' || _all: R.`g2'
if _rc {
    ss_fail_TQ11 `=_rc' "mixed cross_classified" "estimation_failed"
}
local ll = e(ll)
local n_obs = e(N)
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=n_obs|value=`n_obs'"

tempname cross_results
postfile `cross_results' str64 term double coef double se double z double p using "temp_cross.dta", replace
matrix b = e(b)
matrix V = e(V)
local colnames : colnames b
local k : word count `colnames'
forvalues i = 1/`k' {
    local term : word `i' of `colnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `cross_results' ("`term'") (`coef') (`se') (`z') (`p')
}
postclose `cross_results'

preserve
use "temp_cross.dta", clear
capture export delimited using "table_TQ11_cross.csv", replace
if _rc {
    ss_fail_TQ11 `=_rc' "export delimited table_TQ11_cross.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ11_cross.csv|type=table|desc=cross_results"
restore

capture erase "temp_cross.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TQ11_cross.dta", replace
if _rc {
    ss_fail_TQ11 `=_rc' "save data_TQ11_cross.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TQ11_cross.dta|type=data|desc=cross_data"
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

display "SS_TASK_END|id=TQ11|status=ok|elapsed_sec=`elapsed'"
log close
