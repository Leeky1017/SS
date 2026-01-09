* ==============================================================================
* SS_TEMPLATE: id=TH01  level=L1  module=H  title="DF-GLS Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH01_dfgls.csv type=table desc="DF-GLS results"
*   - data_TH01_dfgls.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.8) / 最佳实践审查（阶段 5.8）
* - 2026-01-09 (Issue #263): Add `tsset` preflight + gap diagnostics; fail fast on core command errors.
*   增加 tsset 前置检查与缺口诊断；核心命令失败即 fail-fast，避免“静默成功”。
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

display "SS_TASK_BEGIN|id=TH01|level=L1|title=DFGLS_Test"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_BP_REVIEW|issue=263|template_id=TH01|ssc=none|output=csv_dta|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

program define ss_fail_TH01
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TH01|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local var = "__VAR__"
local timevar = "__TIME_VAR__"
local maxlag = __MAXLAG__

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TH01 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `timevar'
if _rc {
    ss_fail_TH01 111 "confirm variable `timevar'" "time_var_missing"
}
capture confirm variable `var'
if _rc {
    ss_fail_TH01 111 "confirm variable `var'" "series_var_missing"
}

local tsvar "`timevar'"
local _ss_need_index = 0
capture confirm numeric variable `timevar'
if _rc {
    local _ss_need_index = 1
    display "SS_RC|code=TIMEVAR_NOT_NUMERIC|var=`timevar'|severity=warn"
}
if `_ss_need_index' == 0 {
    capture isid `timevar'
    if _rc {
        local _ss_need_index = 1
        display "SS_RC|code=TIMEVAR_NOT_UNIQUE|var=`timevar'|severity=warn"
    }
}
if `_ss_need_index' == 1 {
    sort `timevar'
    capture drop ss_time_index
    local rc_drop = _rc
    if `rc_drop' != 0 & `rc_drop' != 111 {
        display "SS_RC|code=`rc_drop'|cmd=drop ss_time_index|msg=drop_failed|severity=warn"
    }
    gen long ss_time_index = _n
    local tsvar "ss_time_index"
    display "SS_METRIC|name=ts_timevar|value=ss_time_index"
}
capture tsset `tsvar'
if _rc {
    ss_fail_TH01 `=_rc' "tsset `tsvar'" "tsset_failed"
}
capture tsreport, report
if _rc == 0 {
    display "SS_METRIC|name=ts_n_gaps|value=`=r(N_gaps)'"
    if r(N_gaps) > 0 {
        display "SS_RC|code=TIME_GAPS|n_gaps=`=r(N_gaps)'|severity=warn"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local task_success = 1
if missing(`maxlag') | `maxlag' < 0 {
    display "SS_RC|code=PARAM_INVALID|param=maxlag|value=`maxlag'|severity=warn"
    local maxlag = 0
}
capture noisily dfgls `var', maxlag(`maxlag')
local opt_lag = .
local t_stat = .
if _rc {
    ss_fail_TH01 `=_rc' "dfgls `var', maxlag(`maxlag')" "dfgls_failed"
}
else {
    local opt_lag = r(optlag)
    local t_stat = r(t)
}
display "SS_METRIC|name=optimal_lag|value=`opt_lag'"
display "SS_METRIC|name=t_stat|value=`t_stat'"

preserve
clear
set obs 1
gen str32 test = "DF-GLS"
gen int opt_lag = `opt_lag'
gen double t_stat = `t_stat'
export delimited using "table_TH01_dfgls.csv", replace
display "SS_OUTPUT_FILE|file=table_TH01_dfgls.csv|type=table|desc=dfgls_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH01_dfgls.dta", replace
display "SS_OUTPUT_FILE|file=data_TH01_dfgls.dta|type=data|desc=dfgls_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=optimal_lag|value=`opt_lag'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH01|status=ok|elapsed_sec=`elapsed'"
log close
