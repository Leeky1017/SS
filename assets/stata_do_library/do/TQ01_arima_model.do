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

display "SS_TASK_BEGIN|id=TQ01|level=L2|title=ARIMA_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

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
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    display "SS_TASK_END|id=TQ01|status=fail|elapsed_sec=."
    log close
    exit 601
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
        display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|severity=fail|var=`var'"
        display "SS_TASK_END|id=TQ01|status=fail|elapsed_sec=."
        log close
        exit 200
    }
}

tsset `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ ARIMA估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: ARIMA(`ar_order',`diff_order',`ma_order')估计"
display "═══════════════════════════════════════════════════════════════════════════════"

arima `series_var', arima(`ar_order',`diff_order',`ma_order')

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
export delimited using "table_TQ01_arima_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TQ01_arima_result.csv|type=table|desc=arima_results"
restore

* ============ 预测 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 预测"
display "═══════════════════════════════════════════════════════════════════════════════"

* 扩展数据
local last_t = `time_var'[_N]
local new_obs = _N + `forecast_h'
set obs `new_obs'
forvalues i = 1/`forecast_h' {
    replace `time_var' = `last_t' + `i' in `=_N - `forecast_h' + `i''
}

tsset `time_var'

predict double forecast, y dynamic(`=`last_t'+1')
predict double forecast_se, mse dynamic(`=`last_t'+1')
replace forecast_se = sqrt(forecast_se)

generate double ci_lower = forecast - 1.96 * forecast_se
generate double ci_upper = forecast + 1.96 * forecast_se

display ""
display ">>> 预测结果:"
list `time_var' forecast ci_lower ci_upper if `time_var' > `last_t', noobs

* 导出预测
preserve
keep if `time_var' > `last_t'
keep `time_var' forecast forecast_se ci_lower ci_upper
export delimited using "table_TQ01_forecast.csv", replace
display "SS_OUTPUT_FILE|file=table_TQ01_forecast.csv|type=table|desc=forecast"
restore

* ============ 生成预测图 ============
twoway (line `series_var' `time_var' if `time_var' <= `last_t', lcolor(navy)) ///
       (line forecast `time_var' if `time_var' > `last_t', lcolor(red)) ///
       (rarea ci_lower ci_upper `time_var' if `time_var' > `last_t', color(red%20)), ///
       xline(`last_t', lcolor(gray) lpattern(dash)) ///
       legend(order(1 "历史" 2 "预测" 3 "95%CI") position(6)) ///
       xtitle("时间") ytitle("`series_var'") ///
       title("ARIMA(`ar_order',`diff_order',`ma_order')预测")
graph export "fig_TQ01_forecast.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TQ01_forecast.png|type=figure|desc=forecast_plot"

capture erase "temp_arima_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TQ01_arima.dta", replace
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
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ01|status=ok|elapsed_sec=`elapsed'"
log close
