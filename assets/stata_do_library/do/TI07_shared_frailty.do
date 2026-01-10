* ==============================================================================
* SS_TEMPLATE: id=TI07  level=L2  module=I  title="Shared Frailty"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI07_frailty.csv type=table desc="Frailty results"
*   - data_TI07_frailty.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.9) / 最佳实践审查记录
* - Date: 2026-01-10
* - Model intent / 模型目的: shared frailty Cox to model within-group dependence / 共享脆弱性 Cox 处理组内相关
* - PH assumption / 比例风险: still relevant; attempt `estat phtest` best-effort / 仍有关联，尽量输出 phtest 诊断
* - Competing risks / 竞争风险: N/A / 不适用
* - SSC deps / SSC 依赖: none / 无
* - Guardrails / 防御: validate time/fail/group vars + small-events warning
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

display "SS_TASK_BEGIN|id=TI07|level=L2|title=Shared_Frailty"
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
local group_var = "__GROUP_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TI07 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Core validation / 核心校验: time/failure/group vars must exist.
capture confirm numeric variable `timevar'
local rc_time = _rc
if `rc_time' != 0 {
    ss_fail TI07 200 "confirm numeric variable `timevar'" "timevar_missing_or_not_numeric"
}
capture confirm numeric variable `failvar'
local rc_fail = _rc
if `rc_fail' != 0 {
    ss_fail TI07 200 "confirm numeric variable `failvar'" "failvar_missing_or_not_numeric"
}
capture confirm variable `group_var'
local rc_group = _rc
if `rc_group' != 0 {
    ss_fail TI07 200 "confirm variable `group_var'" "group_var_missing"
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
    ss_fail TI07 `rc_stset' "stset" "stset_failed"
}
quietly count if _d == 1
local n_events = r(N)
display "SS_METRIC|name=n_events|value=`n_events'"
if `n_events' == 0 {
    ss_fail TI07 200 "stset" "no_failure_events"
}
if `n_events' < 5 {
    display "SS_RC|code=SMALL_EVENT_COUNT|n_events=`n_events'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* Cox frailty model / 共享脆弱性 Cox 模型
capture noisily stcox `indepvars', shared(`group_var')
local rc_stcox = _rc
if `rc_stcox' != 0 {
    ss_fail TI07 `rc_stcox' "stcox" "stcox_failed"
}
* PH test / 比例风险假定检验（若可用）
local ph_chi2 = .
local ph_p = .
capture noisily estat phtest
local rc_phtest = _rc
if `rc_phtest' == 0 {
    capture local ph_chi2 = r(chi2)
    capture local ph_p = r(p)
}
else {
    display "SS_RC|code=`rc_phtest'|cmd=estat phtest|msg=phtest_unavailable|severity=warn"
}
display "SS_METRIC|name=ph_test_chi2|value=`ph_chi2'"
display "SS_METRIC|name=ph_test_p|value=`ph_p'"
local ll = .
local theta = .
capture local ll = e(ll)
local rc_ll = _rc
if `rc_ll' != 0 {
    display "SS_RC|code=`rc_ll'|cmd=e(ll)|msg=missing_log_likelihood|severity=warn"
}
capture local theta = e(theta)
local rc_theta = _rc
if `rc_theta' != 0 {
    display "SS_RC|code=`rc_theta'|cmd=e(theta)|msg=missing_theta|severity=warn"
}
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=theta|value=`theta'"

preserve
clear
set obs 1
gen str32 model = "Shared Frailty"
gen double ll = `ll'
gen double theta = `theta'
gen double ph_p = `ph_p'
export delimited using "table_TI07_frailty.csv", replace
display "SS_OUTPUT_FILE|file=table_TI07_frailty.csv|type=table|desc=frailty_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI07_frailty.dta", replace
display "SS_OUTPUT_FILE|file=data_TI07_frailty.dta|type=data|desc=frailty_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=theta|value=`theta'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI07|status=ok|elapsed_sec=`elapsed'"
log close
