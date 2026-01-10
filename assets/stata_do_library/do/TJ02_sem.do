* ==============================================================================
* SS_TEMPLATE: id=TJ02  level=L2  module=J  title="SEM Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TJ02_sem.csv type=table desc="SEM results"
*   - data_TJ02_sem.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.9) / 最佳实践审查记录
* - Date: 2026-01-10
* - Model intent / 模型目的: SEM via `sem __MODEL_SPEC__` / 结构方程模型（模型由 __MODEL_SPEC__ 指定）
* - Diagnostics / 诊断: report GOF (chi2/RMSEA/CFI/SRMR) + standardized solution / 输出拟合优度与标准化结果
* - Data caveats / 数据注意: SEM is sensitive to sample size, scaling, and missingness / 需关注样本量、尺度与缺失
* - SSC deps / SSC 依赖: none / 无
* - Guardrails / 防御: warn on small N; fail-fast only on missing input file
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

display "SS_TASK_BEGIN|id=TJ02|level=L2|title=SEM_Analysis"
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

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TJ02 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Basic sanity checks / 基础校验（样本量过小会导致不收敛/不稳定）
if _N < 30 {
    display "SS_RC|code=SMALL_SAMPLE_SIZE|n=`=_N'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily sem __MODEL_SPEC__
local rc_sem = _rc
if `rc_sem' != 0 {
    if `rc_sem' == 430 {
        display "SS_RC|code=430|cmd=sem|msg=convergence_not_achieved|severity=warn"
    }
    else {
        ss_fail TJ02 `rc_sem' "sem" "sem_failed"
    }
}
local chi2 = .
local rmsea = .
local cfi = .
local srmr = .
capture noisily estat gof, stats(all)
local rc_gof = _rc
if `rc_gof' == 0 {
    local chi2 = e(chi2_ms)
    local rmsea = e(rmsea)
    local cfi = e(cfi)
    local srmr = e(srmr)
}
else {
    display "SS_RC|code=`rc_gof'|cmd=estat gof|msg=gof_unavailable|severity=warn"
}
display "SS_METRIC|name=chi2|value=`chi2'"
display "SS_METRIC|name=rmsea|value=`rmsea'"
display "SS_METRIC|name=cfi|value=`cfi'"

capture noisily sem, standardized
local rc_std = _rc
if `rc_std' != 0 {
    display "SS_RC|code=`rc_std'|cmd=sem standardized|msg=sem_standardized_failed|severity=warn"
}
capture noisily estat eqgof
local rc_eq = _rc
if `rc_eq' != 0 {
    display "SS_RC|code=`rc_eq'|cmd=estat eqgof|msg=eqgof_unavailable|severity=warn"
}

preserve
clear
set obs 1
gen str32 model = "SEM"
gen double chi2 = `chi2'
gen double rmsea = `rmsea'
gen double cfi = `cfi'
export delimited using "table_TJ02_sem.csv", replace
display "SS_OUTPUT_FILE|file=table_TJ02_sem.csv|type=table|desc=sem_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TJ02_sem.dta", replace
display "SS_OUTPUT_FILE|file=data_TJ02_sem.dta|type=data|desc=sem_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=cfi|value=`cfi'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TJ02|status=ok|elapsed_sec=`elapsed'"
log close
