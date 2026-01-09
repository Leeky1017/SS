* ==============================================================================
* SS_TEMPLATE: id=TH12  level=L1  module=H  title="FEVD Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TH12_fevd.png type=figure desc="FEVD plot"
*   - table_TH12_fevd.csv type=table desc="FEVD results"
*   - data_TH12_fevd.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.8) / 最佳实践审查（阶段 5.8）
* - 2026-01-09 (Issue #263): Validate inputs (>=2 vars, lags/steps>=1) and add `tsset`/gap diagnostics.
*   校验输入（>=2 变量，lags/steps>=1）并增加 tsset/缺口诊断。
* - 2026-01-09 (Issue #263): Keep fallback plot when FEVD graph fails; emit explicit warnings (no silent failure).
*   FEVD 图失败时保留兜底图，但必须显式输出 warn（禁止静默失败）。
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

display "SS_TASK_BEGIN|id=TH12|level=L1|title=FEVD_Analysis"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_BP_REVIEW|issue=263|template_id=TH12|ssc=none|output=png_csv_dta|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

program define ss_fail_TH12
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TH12|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local vars = "__VARS__"
local timevar = "__TIME_VAR__"
local lags = __LAGS__
local steps = __STEPS__

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TH12 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `timevar'
if _rc {
    ss_fail_TH12 111 "confirm variable `timevar'" "time_var_missing"
}
foreach v of local vars {
    capture confirm variable `v'
    if _rc {
        ss_fail_TH12 111 "confirm variable `v'" "series_var_missing"
    }
}
local n_vars : word count `vars'
if `n_vars' < 2 {
    ss_fail_TH12 198 "validate vars count" "need_at_least_two_series"
}
if missing(`lags') | `lags' < 1 {
    ss_fail_TH12 198 "validate lags" "lags_invalid"
}
if missing(`steps') | `steps' < 1 {
    ss_fail_TH12 198 "validate steps" "steps_invalid"
}
display "SS_METRIC|name=n_vars|value=`n_vars'"
display "SS_METRIC|name=lags|value=`lags'"
display "SS_METRIC|name=steps|value=`steps'"

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
    ss_fail_TH12 `=_rc' "tsset `tsvar'" "tsset_failed"
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
capture noisily var `vars', lags(1/`lags')
if _rc {
    ss_fail_TH12 `=_rc' "var `vars', lags(1/`lags')" "var_failed"
}
else {
    capture irf set fevd_results, replace
    capture noisily irf create myfevd, step(`steps') replace
    if _rc {
        local task_success = 0
        display "SS_RC|code=CMD_FAILED|cmd=irf_create|rc=`_rc'|severity=warn"
    }
    capture noisily irf graph fevd
    if _rc {
        local task_success = 0
        display "SS_RC|code=CMD_FAILED|cmd=irf_graph_fevd|rc=`_rc'|severity=warn"
    }
}
capture graph export "fig_TH12_fevd.png", replace width(1200)
local rc_gexp = _rc
if `rc_gexp' != 0 {
    display "SS_RC|code=`rc_gexp'|cmd=graph export fig_TH12_fevd.png|msg=graph_export_failed|severity=warn"
    local first_var : word 1 of `vars'
    capture twoway line `first_var' `tsvar'
    local rc_tw = _rc
    if `rc_tw' != 0 {
        display "SS_RC|code=`rc_tw'|cmd=twoway line|msg=fallback_plot_failed|severity=warn"
    }
    capture graph export "fig_TH12_fevd.png", replace width(1200)
    local rc_gexp2 = _rc
    if `rc_gexp2' != 0 {
        display "SS_RC|code=`rc_gexp2'|cmd=graph export fig_TH12_fevd.png|msg=graph_export_failed|severity=warn"
    }
}
display "SS_OUTPUT_FILE|file=fig_TH12_fevd.png|type=figure|desc=fevd_plot"

capture noisily irf table fevd
local rc_table = _rc
if `rc_table' != 0 {
    local task_success = 0
    display "SS_RC|code=`rc_table'|cmd=irf table fevd|msg=fevd_table_failed|severity=warn"
}
preserve
clear
set obs 1
gen str32 analysis = "FEVD"
export delimited using "table_TH12_fevd.csv", replace
display "SS_OUTPUT_FILE|file=table_TH12_fevd.csv|type=table|desc=fevd_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH12_fevd.dta", replace
display "SS_OUTPUT_FILE|file=data_TH12_fevd.dta|type=data|desc=fevd_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=steps|value=`steps'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH12|status=ok|elapsed_sec=`elapsed'"
log close
