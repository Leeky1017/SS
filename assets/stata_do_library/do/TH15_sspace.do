* ==============================================================================
* SS_TEMPLATE: id=TH15  level=L2  module=H  title="State Space Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH15_sspace.csv type=table desc="State space results"
*   - data_TH15_sspace.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.8) / 最佳实践审查（阶段 5.8）
* - 2026-01-09 (Issue #263): Add `tsset`/gap diagnostics and fail fast on `sspace` estimation errors.
*   增加 tsset/缺口诊断；sspace 估计失败则 fail-fast。
* - 2026-01-09 (Issue #263): Interpretation note: specify a meaningful state/measurement equation for your context.
*   解读提示：状态方程/观测方程需结合研究背景设定；示例仅为最小可运行链路。
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

display "SS_TASK_BEGIN|id=TH15|level=L2|title=State_Space"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_BP_REVIEW|issue=263|template_id=TH15|ssc=none|output=csv_dta|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

program define ss_fail_TH15
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TH15|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local depvar = "__DEPVAR__"
local timevar = "__TIME_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TH15 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `timevar'
if _rc {
    ss_fail_TH15 111 "confirm variable `timevar'" "time_var_missing"
}
capture confirm variable `depvar'
if _rc {
    ss_fail_TH15 111 "confirm variable `depvar'" "depvar_missing"
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
    ss_fail_TH15 `=_rc' "tsset `tsvar'" "tsset_failed"
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
local ll = .
capture noisily sspace (u L.u, state noconstant) (`depvar' u, noconstant)
if _rc {
    ss_fail_TH15 `=_rc' "sspace (u L.u, state noconstant) (`depvar' u, noconstant)" "sspace_failed"
}
else {
    local ll = e(ll)
}
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "State Space"
gen double ll = `ll'
export delimited using "table_TH15_sspace.csv", replace
display "SS_OUTPUT_FILE|file=table_TH15_sspace.csv|type=table|desc=sspace_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH15_sspace.dta", replace
display "SS_OUTPUT_FILE|file=data_TH15_sspace.dta|type=data|desc=sspace_data"
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
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH15|status=ok|elapsed_sec=`elapsed'"
log close
