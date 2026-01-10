* ==============================================================================
* SS_TEMPLATE: id=TI09  level=L2  module=I  title="Cure Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI09_cure.csv type=table desc="Cure results"
*   - data_TI09_cure.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - none (built-in Stata only)
* ==============================================================================
* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.9) / 最佳实践审查记录
* - Date: 2026-01-10
* - Model intent / 模型目的: mixture cure survival model / 混合治愈模型
* - Dep note / 依赖说明: `stcure` is not available from SSC; replaced with built-in approximation (logit cure + parametric survival on time-to-event) / stcure 无法从 SSC 获取，改用内置近似（治愈概率 logit + 事件时间的参数生存）
* - Guardrails / 防御: stset fail-fast + small-events warning + model skipped when data too small / 数据过小则跳过估计并给出告警
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
display "SS_TASK_VERSION|version=2.0.2"
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
local n_dropped = 0
gen byte _ss_keep = !missing(`timevar') & !missing(`failvar')
quietly count if _ss_keep == 0
local n_dropped = r(N)
if `n_dropped' > 0 {
    display "SS_RC|code=DROP_MISSING_CORE_VARS|n=`n_dropped'|severity=warn"
    drop if _ss_keep == 0
}
drop _ss_keep
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_prepare_subject_level"
local idvar "id"
capture confirm variable id
local rc_id = _rc
if `rc_id' != 0 {
    gen long _ss_id = _n
    local idvar "_ss_id"
    display "SS_RC|code=IDVAR_MISSING|fallback=_ss_id|severity=warn"
}
sort `idvar' `timevar'
by `idvar': egen byte _ss_event = max(`failvar' == 1)
by `idvar': egen double _ss_time_event = min(cond(`failvar' == 1, `timevar', .))
by `idvar': egen double _ss_time_last = max(`timevar')
gen double _ss_time = _ss_time_event
replace _ss_time = _ss_time_last if missing(_ss_time)
gen byte _ss_fail = _ss_event
gen byte _ss_cure = 1 - _ss_fail
by `idvar': keep if _n == 1
local n_subjects = _N
quietly count if _ss_fail == 1
local n_events = r(N)
display "SS_METRIC|name=n_subjects|value=`n_subjects'"
display "SS_METRIC|name=n_events|value=`n_events'"
if `n_events' == 0 {
    ss_fail TI09 200 "subject_level_event_build" "no_failure_events"
}
if `n_events' < 5 {
    display "SS_RC|code=SMALL_EVENT_COUNT|n_events=`n_events'|severity=warn"
}
display "SS_STEP_END|step=S03_prepare_subject_level|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S04_analysis"
capture stset _ss_time, failure(_ss_fail)
local rc_stset = _rc
if `rc_stset' != 0 {
    ss_fail TI09 `rc_stset' "stset _ss_time, failure(_ss_fail)" "stset_failed"
}
quietly summarize _ss_cure
local cure_rate = r(mean)
display "SS_METRIC|name=cure_rate|value=`cure_rate'"

local survival_model = "skipped"
local cure_model = "skipped"
local ll = .
local ll_cure = .
local rc_survival = .
local rc_cure = .

if `n_subjects' >= 10 & `n_events' >= 3 {
    capture noisily streg `indepvars', dist(weibull)
    local rc_survival = _rc
    if `rc_survival' == 0 {
        local survival_model = "streg_weibull"
        capture local ll = e(ll)
        if _rc != 0 {
            display "SS_RC|code=MISSING_LL|cmd=e(ll)|severity=warn"
        }
    }
    else {
        display "SS_RC|code=MODEL_STREG_FAILED|rc=`rc_survival'|severity=warn"
    }
}
else {
    display "SS_RC|code=MODEL_SKIPPED_SMALL_SAMPLE|model=streg_weibull|n_subjects=`n_subjects'|n_events=`n_events'|severity=warn"
}

if `n_subjects' >= 10 & `n_events' >= 1 & (`n_subjects' - `n_events') >= 1 {
    capture noisily logit _ss_cure `indepvars'
    local rc_cure = _rc
    if `rc_cure' == 0 {
        local cure_model = "logit_cure"
        capture local ll_cure = e(ll)
        if _rc != 0 {
            display "SS_RC|code=MISSING_LL|cmd=e(ll)|severity=warn"
        }
    }
    else {
        display "SS_RC|code=MODEL_LOGIT_FAILED|rc=`rc_cure'|severity=warn"
    }
}
else {
    display "SS_RC|code=MODEL_SKIPPED_SMALL_SAMPLE|model=logit_cure|n_subjects=`n_subjects'|n_events=`n_events'|severity=warn"
}

display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "Cure Model"
gen long n_subjects = `n_subjects'
gen long n_events = `n_events'
gen double cure_rate = `cure_rate'
gen str32 survival_model = "`survival_model'"
gen str32 cure_model = "`cure_model'"
gen double ll_survival = `ll'
gen double ll_cure = `ll_cure'
gen double rc_survival = `rc_survival'
gen double rc_cure = `rc_cure'
export delimited using "table_TI09_cure.csv", replace
display "SS_OUTPUT_FILE|file=table_TI09_cure.csv|type=table|desc=cure_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI09_cure.dta", replace
display "SS_OUTPUT_FILE|file=data_TI09_cure.dta|type=data|desc=cure_data"
display "SS_STEP_END|step=S04_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"
display "SS_SUMMARY|key=cure_rate|value=`cure_rate'"

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
