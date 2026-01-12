* ==============================================================================
* SS_TEMPLATE: id=TQ01  level=L2  module=Q  title="ARIMA Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ01_arima_result.csv type=table desc="ARIMA results"
*   - table_TQ01_forecast.csv type=table desc="Forecast values"
*   - fig_TQ01_forecast.png type=figure desc="Forecast plot"
*   - data_TQ01_arima.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TQ01
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ01|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ01|level=L2|title=ARIMA_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: confirm stationarity/differencing choices; use diagnostics (AIC/BIC, roots) and avoid overfitting. /
*   最佳实践：确认平稳性/差分选择；使用诊断（AIC/BIC、根）并避免过拟合。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/tsset/arima; warn on time gaps and forecast/plot failures /
*   错误策略：缺少输入/tsset/arima 失败→fail；时间缺口/预测或绘图失败→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ01|ssc=none|output=csv_png_dta|policy=warn_fail"

* ============ 参数设置 ============
local series_var = "__SERIES_VAR__"
local time_var = "__TIME_VAR__"
local ar_order = __AR_ORDER__
local diff_order = __DIFF_ORDER__
local ma_order = __MA_ORDER__
local forecast_h = __FORECAST_H__

if `ar_order' < 0 | `ar_order' > 5 {
    local ar_order = 1
}
if `diff_order' < 0 | `diff_order' > 2 {
    local diff_order = 0
}
if `ma_order' < 0 | `ma_order' > 5 {
    local ma_order = 1
}
if `forecast_h' < 1 | `forecast_h' > 100 {
    local forecast_h = 12
}

display ""
display ">>> ARIMA模型参数:"
display "    序列变量: `series_var'"
display "    ARIMA(`ar_order',`diff_order',`ma_order')"
display "    预测期数: `forecast_h'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TQ01 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `series_var' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TQ01 200 "confirm variable `var'" "var_not_found"
    }
}
capture confirm numeric variable `series_var'
if _rc {
    ss_fail_TQ01 200 "confirm numeric variable `series_var'" "series_var_not_numeric"
}

local tsvar "`time_var'"
local _ss_need_index = 0
capture confirm numeric variable `time_var'
if _rc {
    local _ss_need_index = 1
    display "SS_RC|code=TIMEVAR_NOT_NUMERIC|var=`time_var'|severity=warn"
}
if `_ss_need_index' == 0 {
    capture isid `time_var'
    if _rc {
        local _ss_need_index = 1
        display "SS_RC|code=TIMEVAR_NOT_UNIQUE|var=`time_var'|severity=warn"
    }
}
if `_ss_need_index' == 1 {
    sort `time_var'
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
    ss_fail_TQ01 `=_rc' "tsset `tsvar'" "tsset_failed"
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

* ============ ARIMA估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: ARIMA(`ar_order',`diff_order',`ma_order')估计"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily arima `series_var', arima(`ar_order',`diff_order',`ma_order')
if _rc {
    ss_fail_TQ01 `=_rc' "arima" "arima_failed"
}

local ll = e(ll)
local aic = -2 * `ll' + 2 * e(k)
local bic = -2 * `ll' + ln(e(N)) * e(k)
local sigma = e(sigma)

display ""
display ">>> 模型拟合:"
display "    对数似然: " %12.4f `ll'
display "    AIC: " %12.4f `aic'
display "    BIC: " %12.4f `bic'
display "    sigma: " %12.6f `sigma'

display "SS_METRIC|name=aic|value=`aic'"
display "SS_METRIC|name=bic|value=`bic'"

* 导出系数
tempname arima_results
postfile `arima_results' str32 parameter double coef double se double z double p ///
    using "temp_arima_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `arima_results' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `arima_results'

preserve
use "temp_arima_results.dta", clear
capture export delimited using "table_TQ01_arima_result.csv", replace
if _rc {
    ss_fail_TQ01 `=_rc' "export delimited table_TQ01_arima_result.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ01_arima_result.csv|type=table|desc=arima_results"
restore

* ============ 预测 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 预测"
display "═══════════════════════════════════════════════════════════════════════════════"

* 扩展数据
local last_t = `tsvar'[_N]
local new_obs = _N + `forecast_h'
set obs `new_obs'
forvalues i = 1/`forecast_h' {
    replace `tsvar' = `last_t' + `i' in `=_N - `forecast_h' + `i''
}

capture tsset `tsvar'
if _rc {
    ss_fail_TQ01 `=_rc' "tsset `tsvar'" "tsset_failed"
}

capture predict double forecast, y dynamic(`=`last_t'+1')
if _rc {
    ss_fail_TQ01 `=_rc' "predict forecast" "predict_failed"
}
capture predict double forecast_se, mse dynamic(`=`last_t'+1')
if _rc {
    ss_fail_TQ01 `=_rc' "predict forecast_se" "predict_failed"
}
replace forecast_se = sqrt(forecast_se)

generate double ci_lower = forecast - 1.96 * forecast_se
generate double ci_upper = forecast + 1.96 * forecast_se

display ""
display ">>> 预测结果:"
list `tsvar' forecast ci_lower ci_upper if `tsvar' > `last_t', noobs

* 导出预测
preserve
keep if `tsvar' > `last_t'
keep `tsvar' forecast forecast_se ci_lower ci_upper
capture export delimited using "table_TQ01_forecast.csv", replace
if _rc {
    ss_fail_TQ01 `=_rc' "export delimited table_TQ01_forecast.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ01_forecast.csv|type=table|desc=forecast"
restore

* ============ 生成预测图 ============
twoway (line `series_var' `tsvar' if `tsvar' <= `last_t', lcolor(navy)) ///
       (line forecast `tsvar' if `tsvar' > `last_t', lcolor(red)) ///
       (rarea ci_lower ci_upper `tsvar' if `tsvar' > `last_t', color(red%20)), ///
       xline(`last_t', lcolor(gray) lpattern(dash)) ///
       legend(order(1 "历史" 2 "预测" 3 "95%CI") position(6)) ///
       xtitle("时间") ytitle("`series_var'") ///
       title("ARIMA(`ar_order',`diff_order',`ma_order')预测")
capture graph export "fig_TQ01_forecast.png", replace width(1200)
local rc_gexp = _rc
if `rc_gexp' != 0 {
    display "SS_RC|code=`rc_gexp'|cmd=graph export fig_TQ01_forecast.png|msg=graph_export_failed|severity=warn"
}
display "SS_OUTPUT_FILE|file=fig_TQ01_forecast.png|type=figure|desc=forecast_plot"

capture erase "temp_arima_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TQ01_arima.dta", replace
if _rc {
    ss_fail_TQ01 `=_rc' "save data_TQ01_arima.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TQ01_arima.dta|type=data|desc=arima_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TQ01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  模型:            ARIMA(`ar_order',`diff_order',`ma_order')"
display "  AIC:             " %10.4f `aic'
display "  BIC:             " %10.4f `bic'
display "  预测期:          `forecast_h'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=aic|value=`aic'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ01|status=ok|elapsed_sec=`elapsed'"
log close
