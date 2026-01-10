* ==============================================================================
* SS_TEMPLATE: id=TI09  level=L2  module=I  title="Cure Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI09_cure.csv type=table desc="Cure results"
*   - data_TI09_cure.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stcure source=ssc purpose="Cure model"
* ==============================================================================
* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.9) / 最佳实践审查记录
* - Date: 2026-01-10
* - Model intent / 模型目的: mixture cure survival model via `stcure` / 混合治愈模型（stcure）
* - SSC deps / SSC 依赖: `stcure` is SSC-only; keep as explicit dep (no Stata 18 built-in replacement) / stcure 为 SSC 命令，暂无内置替代，保留并显式声明
* - Guardrails / 防御: fail-fast on missing dep + stset fail-fast + small-events warning
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

display "SS_TASK_BEGIN|id=TI09|level=L2|title=Cure_Model"
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

capture which stcure
local rc_dep = _rc
if `rc_dep' != 0 {
    display "SS_DEP_CHECK|pkg=stcure|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=stcure"
    display "SS_RC|code=DEP_INSTALL_HINT|cmd=ssc install stcure|msg=install_stcure_then_rerun|severity=warn"
    ss_fail TI09 199 "which stcure" "dependency_missing"
}
display "SS_DEP_CHECK|pkg=stcure|source=ssc|status=ok"

local timevar = "__TIME_VAR__"
local failvar = "__FAILVAR__"
local indepvars = "__INDEPVARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TI09 601 "confirm file data.csv" "input_file_not_found"
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
    ss_fail TI09 200 "confirm numeric variable `timevar'" "timevar_missing_or_not_numeric"
}
capture confirm numeric variable `failvar'
local rc_fail = _rc
if `rc_fail' != 0 {
    ss_fail TI09 200 "confirm numeric variable `failvar'" "failvar_missing_or_not_numeric"
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
    ss_fail TI09 `rc_stset' "stset" "stset_failed"
}
quietly count if _d == 1
local n_events = r(N)
display "SS_METRIC|name=n_events|value=`n_events'"
if `n_events' == 0 {
    ss_fail TI09 200 "stset" "no_failure_events"
}
if `n_events' < 5 {
    display "SS_RC|code=SMALL_EVENT_COUNT|n_events=`n_events'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily stcure `indepvars', dist(weibull) link(logit)
local rc_stcure = _rc
if `rc_stcure' != 0 {
    ss_fail TI09 `rc_stcure' "stcure" "stcure_failed"
}
local ll = .
capture local ll = e(ll)
local rc_ll = _rc
if `rc_ll' != 0 {
    display "SS_RC|code=`rc_ll'|cmd=e(ll)|msg=missing_log_likelihood|severity=warn"
}
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "Cure Model"
gen double ll = `ll'
export delimited using "table_TI09_cure.csv", replace
display "SS_OUTPUT_FILE|file=table_TI09_cure.csv|type=table|desc=cure_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI09_cure.dta", replace
display "SS_OUTPUT_FILE|file=data_TI09_cure.dta|type=data|desc=cure_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI09|status=ok|elapsed_sec=`elapsed'"
log close
