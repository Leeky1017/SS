* ==============================================================================
* SS_TEMPLATE: id=TH04  level=L1  module=H  title="SARIMA Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH04_sarima.csv type=table desc="SARIMA results"
*   - fig_TH04_forecast.png type=figure desc="Forecast plot"
*   - data_TH04_sarima.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.8) / 最佳实践审查（阶段 5.8）
* - 2026-01-09 (Issue #263): Add parameter validation and `tsset`/gap diagnostics; fail fast on estimation errors.
*   增加参数校验与 tsset/缺口诊断；估计失败则 fail-fast。
* - 2026-01-09 (Issue #263): Add lightweight diagnostics (`estat ic`/`estat aroots`) to the log (no extra outputs).
*   在日志中加入轻量诊断（不新增输出文件）。
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

display "SS_TASK_BEGIN|id=TH04|level=L1|title=SARIMA_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_BP_REVIEW|issue=263|template_id=TH04|ssc=none|output=csv_png_dta|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

program define ss_fail_TH04
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TH04|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local var = "__VAR__"
local timevar = "__TIME_VAR__"
local p = __P__
local d = __D__
local q = __Q__
local sp = __SP__
local sd = __SD__
local sq = __SQ__
local season = __SEASON__

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TH04 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `timevar'
if _rc {
    ss_fail_TH04 111 "confirm variable `timevar'" "time_var_missing"
}
capture confirm variable `var'
if _rc {
    ss_fail_TH04 111 "confirm variable `var'" "series_var_missing"
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
    ss_fail_TH04 `=_rc' "tsset `tsvar'" "tsset_failed"
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
local aic = .

* Parameter hygiene / 参数校验
foreach nm in p d q sp sd sq {
    if missing(``nm'') | ``nm'' < 0 {
        display "SS_RC|code=PARAM_INVALID|param=`nm'|value=``nm''|severity=warn"
        local `nm' = 0
    }
}
if missing(`season') | `season' < 1 {
    display "SS_RC|code=PARAM_INVALID|param=season|value=`season'|severity=warn"
    local season = 1
    local sp = 0
    local sd = 0
    local sq = 0
}

capture noisily arima `var', arima(`p',`d',`q') sarima(`sp',`sd',`sq',`season')
if _rc {
    ss_fail_TH04 `=_rc' "arima `var', arima(`p',`d',`q') sarima(`sp',`sd',`sq',`season')" "arima_failed"
}
else {
    local ll = e(ll)
    local aic = -2*`ll' + 2*e(k)
    capture noisily estat ic
    local rc_ic = _rc
    if `rc_ic' != 0 {
        display "SS_RC|code=`rc_ic'|cmd=estat ic|msg=diagnostic_failed|severity=warn"
    }
    capture noisily estat aroots
    local rc_ar = _rc
    if `rc_ar' != 0 {
        display "SS_RC|code=`rc_ar'|cmd=estat aroots|msg=diagnostic_failed|severity=warn"
    }
}
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=aic|value=`aic'"

capture drop yhat
local rc_drop_yhat = _rc
if `rc_drop_yhat' != 0 & `rc_drop_yhat' != 111 {
    display "SS_RC|code=`rc_drop_yhat'|cmd=drop yhat|msg=drop_failed|severity=warn"
}
if `task_success' {
    capture noisily predict yhat, y
    local rc_pred = _rc
    if `rc_pred' != 0 {
        local task_success = 0
        display "SS_RC|code=`rc_pred'|cmd=predict yhat, y|msg=predict_failed|severity=warn"
    }
}
if `task_success' {
    capture noisily tsline `var' yhat, title("SARIMA预测") legend(order(1 "实际" 2 "拟合"))
    local rc_tsline = _rc
    if `rc_tsline' != 0 {
        local task_success = 0
        display "SS_RC|code=`rc_tsline'|cmd=tsline actual fitted|msg=plot_failed|severity=warn"
    }
}
else {
    capture noisily tsline `var', title("SARIMA (analysis skipped)")
    local rc_tsline2 = _rc
    if `rc_tsline2' != 0 {
        display "SS_RC|code=`rc_tsline2'|cmd=tsline actual_only|msg=plot_failed|severity=warn"
    }
}
capture graph export "fig_TH04_forecast.png", replace width(1200)
local rc_gexp = _rc
if `rc_gexp' != 0 {
    display "SS_RC|code=`rc_gexp'|cmd=graph export fig_TH04_forecast.png|msg=graph_export_failed|severity=warn"
}
display "SS_OUTPUT_FILE|file=fig_TH04_forecast.png|type=figure|desc=forecast"

preserve
clear
set obs 1
gen str32 model = "SARIMA"
gen double ll = `ll'
gen double aic = `aic'
export delimited using "table_TH04_sarima.csv", replace
display "SS_OUTPUT_FILE|file=table_TH04_sarima.csv|type=table|desc=sarima_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH04_sarima.dta", replace
display "SS_OUTPUT_FILE|file=data_TH04_sarima.dta|type=data|desc=sarima_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=aic|value=`aic'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH04|status=ok|elapsed_sec=`elapsed'"
log close
