* ==============================================================================
* SS_TEMPLATE: id=TJ04  level=L1  module=J  title="Canonical Correlation"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TJ04_canon.csv type=table desc="Canon results"
*   - data_TJ04_canon.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.9) / 最佳实践审查记录
* - Date: 2026-01-10
* - Model intent / 模型目的: canonical correlation between two variable sets / 两组变量的典型相关分析
* - Data caveats / 数据注意: requires enough observations vs dimensionality / 样本量需足够（避免维度过高导致不稳定）
* - Diagnostics / 诊断: record first canonical correlation / 记录第一典型相关系数
* - SSC deps / SSC 依赖: none / 无
* - Guardrails / 防御: validate var lists + warn if N is small relative to dimensions
* ------------------------------------------------------------------------------
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

display "SS_TASK_BEGIN|id=TJ04|level=L1|title=Canon_Corr"
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

local vars1 = "__VARS1__"
local vars2 = "__VARS2__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TJ04 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Validate variable sets / 校验两组变量列表
local k1 : word count `vars1'
local k2 : word count `vars2'
display "SS_METRIC|name=k1|value=`k1'"
display "SS_METRIC|name=k2|value=`k2'"
if `k1' < 1 | `k2' < 1 {
    ss_fail TJ04 200 "vars1/vars2" "vars_empty"
}
foreach v of local vars1 {
    capture confirm variable `v'
    if _rc {
        ss_fail TJ04 200 "confirm variable `v'" "var_not_found"
    }
}
foreach v of local vars2 {
    capture confirm variable `v'
    if _rc {
        ss_fail TJ04 200 "confirm variable `v'" "var_not_found"
    }
}
local k_total = `k1' + `k2'
if _N < (`k_total' + 10) {
    display "SS_RC|code=SMALL_SAMPLE_FOR_DIMENSION|n=`=_N'|k_total=`k_total'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily canon (`vars1') (`vars2')
local rc_canon = _rc
if `rc_canon' != 0 {
    ss_fail TJ04 `rc_canon' "canon" "canon_failed"
}
local corr1 = .
capture local corr1 = e(ccorr1)
local rc_corr = _rc
if `rc_corr' != 0 {
    display "SS_RC|code=`rc_corr'|cmd=e(ccorr1)|msg=missing_canonical_corr|severity=warn"
}
display "SS_METRIC|name=canonical_corr1|value=`corr1'"

preserve
clear
set obs 1
gen str32 analysis = "Canonical Correlation"
gen double corr1 = `corr1'
export delimited using "table_TJ04_canon.csv", replace
display "SS_OUTPUT_FILE|file=table_TJ04_canon.csv|type=table|desc=canon_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TJ04_canon.dta", replace
display "SS_OUTPUT_FILE|file=data_TJ04_canon.dta|type=data|desc=canon_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=canonical_corr1|value=`corr1'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TJ04|status=ok|elapsed_sec=`elapsed'"
log close
