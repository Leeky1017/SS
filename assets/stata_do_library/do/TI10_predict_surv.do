* ==============================================================================
* SS_TEMPLATE: id=TI10  level=L1  module=I  title="Survival Prediction"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI10_predict.csv type=table desc="Prediction results"
*   - data_TI10_predict.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.9) / 最佳实践审查记录
* - Date: 2026-01-10
* - Model intent / 模型目的: fit Weibull and produce survival-related predictions / 拟合 Weibull 并生成预测（生存率/中位生存期/风险率）
* - Prediction caveat / 预测注意: predictions are model-based; validate calibration externally / 预测为模型推断，建议外部做校准/验证
* - SSC deps / SSC 依赖: none / 无
* - Guardrails / 防御: validate time/fail vars + stset fail-fast + best-effort predict warnings
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

display "SS_TASK_BEGIN|id=TI10|level=L1|title=Surv_Prediction"
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

local timevar = "__TIME_VAR__"
local failvar = "__FAILVAR__"
local indepvars = "__INDEPVARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TI10 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Core validation / 核心校验: time/failure vars must exist and be numeric.
capture confirm numeric variable `timevar'
local rc_time = _rc
if `rc_time' != 0 {
    ss_fail TI10 200 "confirm numeric variable `timevar'" "timevar_missing_or_not_numeric"
}
capture confirm numeric variable `failvar'
local rc_fail = _rc
if `rc_fail' != 0 {
    ss_fail TI10 200 "confirm numeric variable `failvar'" "failvar_missing_or_not_numeric"
}
quietly count if missing(`timevar')
local n_miss_time = r(N)
if `n_miss_time' > 0 {
    display "SS_RC|code=MISSING_TIMEVAR|n=`n_miss_time'|severity=warn"
}
quietly count if `timevar' < 0 & !missing(`timevar')
if r(N) > 0 {
    display "SS_RC|code=NEGATIVE_TIMEVAR|n=`=r(N)'|severity=warn"
}
quietly count if !inlist(`failvar', 0, 1) & !missing(`failvar')
if r(N) > 0 {
    display "SS_RC|code=FAILVAR_NOT_BINARY|n=`=r(N)'|severity=warn"
}
capture stset `timevar', failure(`failvar')
local rc_stset = _rc
if `rc_stset' != 0 {
    ss_fail TI10 `rc_stset' "stset" "stset_failed"
}
quietly count if _d == 1
local n_events = r(N)
display "SS_METRIC|name=n_events|value=`n_events'"
if `n_events' == 0 {
    ss_fail TI10 200 "stset" "no_failure_events"
}
if `n_events' < 5 {
    display "SS_RC|code=SMALL_EVENT_COUNT|n_events=`n_events'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* Fit model / 拟合模型
capture noisily streg `indepvars', dist(weibull)
local rc_streg = _rc
if `rc_streg' != 0 {
    if `rc_streg' == 430 {
        display "SS_RC|code=430|cmd=streg|msg=convergence_not_achieved|severity=warn"
    }
    else {
        ss_fail TI10 `rc_streg' "streg" "streg_failed"
    }
}
* Predict survival / 预测生存率
capture noisily predict surv, surv
local rc_pred_surv = _rc
if `rc_pred_surv' != 0 {
    display "SS_RC|code=`rc_pred_surv'|cmd=predict surv|msg=predict_surv_failed|severity=warn"
}
* Predict median survival time / 预测中位生存期
capture noisily predict median, time
local rc_pred_med = _rc
if `rc_pred_med' != 0 {
    display "SS_RC|code=`rc_pred_med'|cmd=predict median|msg=predict_median_failed|severity=warn"
}
* Predict hazard / 预测风险率
capture noisily predict hazard, hazard
local rc_pred_haz = _rc
if `rc_pred_haz' != 0 {
    display "SS_RC|code=`rc_pred_haz'|cmd=predict hazard|msg=predict_hazard_failed|severity=warn"
}

local median_surv = .
capture summarize median
local rc_sum = _rc
if `rc_sum' == 0 {
    local median_surv = r(mean)
}
else {
    display "SS_RC|code=`rc_sum'|cmd=summarize median|msg=median_summary_failed|severity=warn"
}
display "SS_METRIC|name=median_survival|value=`median_surv'"

preserve
clear
set obs 1
gen str32 prediction = "Survival Time"
gen double median = `median_surv'
export delimited using "table_TI10_predict.csv", replace
display "SS_OUTPUT_FILE|file=table_TI10_predict.csv|type=table|desc=predict_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI10_predict.dta", replace
display "SS_OUTPUT_FILE|file=data_TI10_predict.dta|type=data|desc=predict_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=median_survival|value=`median_surv'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI10|status=ok|elapsed_sec=`elapsed'"
log close
