* ==============================================================================
* SS_TEMPLATE: id=TH02  level=L1  module=H  title="KPSS Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH02_kpss.csv type=table desc="KPSS results"
*   - data_TH02_kpss.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - kpss source=ssc purpose="KPSS test"
* ==============================================================================
* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.8) / 最佳实践审查（阶段 5.8）
* - 2026-01-09 (Issue #263): Keep SSC `kpss` (no built-in equivalent in this library); fail fast if missing.
*   保留 SSC 依赖 kpss（库内无等价内置替代）；缺失时 fail-fast。
* - 2026-01-09 (Issue #263): Add `tsset`/gap diagnostics and interpretation notes (KPSS null = stationarity).
*   增加 tsset/缺口诊断，并补充解释：KPSS 原假设为平稳。
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

display "SS_TASK_BEGIN|id=TH02|level=L1|title=KPSS_Test"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_BP_REVIEW|issue=263|template_id=TH02|ssc=required:kpss|output=csv_dta|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

capture which kpss
if _rc {
    display "SS_DEP_CHECK|pkg=kpss|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=kpss"
    display "SS_RC|code=199|cmd=which kpss|msg=dependency_missing|severity=fail"
    exit 199
}
else {
    display "SS_DEP_CHECK|pkg=kpss|source=ssc|status=ok"
}

program define ss_fail_TH02
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TH02|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local var = "__VAR__"
local timevar = "__TIME_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TH02 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `timevar'
if _rc {
    ss_fail_TH02 111 "confirm variable `timevar'" "time_var_missing"
}
capture confirm variable `var'
if _rc {
    ss_fail_TH02 111 "confirm variable `var'" "series_var_missing"
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
    ss_fail_TH02 `=_rc' "tsset `tsvar'" "tsset_failed"
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
local kpss_stat = .
capture noisily kpss `var'
if _rc {
    ss_fail_TH02 `=_rc' "kpss `var'" "kpss_failed"
}
local kpss_stat = r(kpss)
display "SS_METRIC|name=kpss_stat|value=`kpss_stat'"

preserve
clear
set obs 1
gen str32 test = "KPSS"
gen double stat = `kpss_stat'
export delimited using "table_TH02_kpss.csv", replace
display "SS_OUTPUT_FILE|file=table_TH02_kpss.csv|type=table|desc=kpss_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH02_kpss.dta", replace
display "SS_OUTPUT_FILE|file=data_TH02_kpss.dta|type=data|desc=kpss_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=kpss_stat|value=`kpss_stat'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH02|status=ok|elapsed_sec=`elapsed'"
log close
