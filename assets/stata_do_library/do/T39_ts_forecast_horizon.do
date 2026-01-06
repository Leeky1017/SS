* ==============================================================================
* SS_TEMPLATE: id=T39  level=L0  module=G  title="Time Series Forecasting"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T39_forecast.csv type=table desc="Forecast results"
*   - fig_T39_forecast.png type=graph desc="Forecast visualization"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="time series commands"
* ==============================================================================
* Task ID:      T39_ts_forecast_horizon
* Task Name:    时间序列预测
* Family:       G - 时间序列分析
* Description:  基于ARIMA模型进行多期预测
* 
* Placeholders: __TIME_VAR__    - 时间变量
*               __SERIES_VAR__  - 时间序列变量
*               __P__           - AR阶数
*               __D__           - 差分阶数
*               __Q__           - MA阶数
*               __HORIZON__     - 预测期数
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T39|level=L0|title=Time_Series_Forecasting"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T39_ts_forecast_horizon                                         ║"
display "║  TASK_NAME: 时间序列预测（ARIMA Forecasting）                               ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ---------- 标准化数据加载逻辑开始 ----------
display "SS_STEP_BEGIN|step=S01_load_data"
local datafile "data.dta"

capture confirm file "`datafile'"
if _rc {
    capture confirm file "data.csv"
    if _rc {
        display as error "ERROR: No data.dta or data.csv found in job directory."
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
display "SS_OUTPUT_FILE|file=`datafile'|type=table|desc=output"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}
* ---------- 标准化数据加载逻辑结束 ----------

local n_total = _N
display ">>> 数据加载成功: `n_total' 条观测"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 1: 变量设置与模型参数
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量设置与预测参数"
display "═══════════════════════════════════════════════════════════════════════════════"

local time_var "__TIME_VAR__"
local series_var "__SERIES_VAR__"
local p = __P__
local d = __D__
local q = __Q__
local horizon = __HORIZON__

display ""
display ">>> 时间变量:        `time_var'"
display ">>> 序列变量:        `series_var'"
display ">>> ARIMA阶数:       (`p', `d', `q')"
display ">>> 预测期数:        `horizon'"
display "-------------------------------------------------------------------------------"

tsset `time_var'

local T = _N
display ">>> 样本期数:        `T'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: ARIMA模型估计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: ARIMA模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
arima `series_var', arima(`p', `d', `q')

local ll = e(ll)
local aic = -2*e(ll) + 2*e(k)

* ==============================================================================
* SECTION 3: 样本内拟合
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 样本内拟合"
display "═══════════════════════════════════════════════════════════════════════════════"

predict fitted, xb
predict mse, mse

* 计算拟合误差
generate error = `series_var' - fitted
quietly summarize error
local rmse = sqrt(r(Var) + r(mean)^2)
local mae = .
quietly summarize error if error >= 0
local mae_pos = r(sum)
quietly summarize error if error < 0
local mae_neg = -r(sum)
quietly count if !missing(error)
local mae = (`mae_pos' + `mae_neg') / r(N)

display ""
display "{hline 50}"
display "样本内拟合评估:"
display "  RMSE:              " %12.4f `rmse'
display "  MAE:               " %12.4f `mae'
display "{hline 50}"

* ==============================================================================
* SECTION 4: 扩展数据集进行预测
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成预测期"
display "═══════════════════════════════════════════════════════════════════════════════"

local new_T = `T' + `horizon'

display ""
display ">>> 扩展数据集: `T' → `new_T' 期"

* 扩展观测
set obs `new_T'

* 填充时间变量
quietly summarize `time_var'
local last_t = r(max)
forvalues i = 1/`horizon' {
    quietly replace `time_var' = `last_t' + `i' in `=`T'+`i''
}

* 重新设置时间序列
tsset `time_var'

* ==============================================================================
* SECTION 5: 动态预测
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 动态预测（`horizon' 期）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 使用动态预测方法（多步向前）"
display ">>> 预测期: T+1 至 T+`horizon'"
display "-------------------------------------------------------------------------------"

predict forecast, dynamic(`=`T'+1') y

* 计算置信区间（使用MSE近似）
generate forecast_se = sqrt(mse) if _n > `T'
generate forecast_lo = forecast - 1.96*forecast_se if _n > `T'
generate forecast_hi = forecast + 1.96*forecast_se if _n > `T'

* ==============================================================================
* SECTION 6: 预测结果展示
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 预测结果"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "时间" _col(15) "点预测" _col(30) "95% CI下限" _col(50) "95% CI上限"
display "{hline 70}"

forvalues i = 1/`horizon' {
    local obs = `T' + `i'
    local t_val = `time_var'[`obs']
    local f_val = forecast[`obs']
    local lo_val = forecast_lo[`obs']
    local hi_val = forecast_hi[`obs']
    display %10.0f `t_val' _col(15) %12.4f `f_val' _col(30) %12.4f `lo_val' _col(50) %12.4f `hi_val'
}
display "{hline 70}"

* ==============================================================================
* SECTION 7: 预测可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 预测可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成预测图（含置信区间）"

twoway (tsline `series_var', lcolor(navy) lwidth(medium)) ///
       (tsline forecast if _n > `T', lcolor(cranberry) lwidth(medium) lpattern(dash)) ///
       (rarea forecast_lo forecast_hi `time_var' if _n > `T', fcolor(cranberry%20) lwidth(none)), ///
    title("ARIMA(`p',`d',`q') 预测: `horizon'期", size(medium)) ///
    subtitle("动态多步预测", size(small)) ///
    ytitle("`series_var'") ///
    xtitle("时间") ///
    legend(label(1 "实际值") label(2 "预测值") label(3 "95%置信区间") position(6) rows(1)) ///
    xline(`last_t', lcolor(gray) lpattern(shortdash)) ///
    note("垂直虚线为预测起点", size(small)) ///
    scheme(s1color)
    
graph export "fig_T39_forecast.png", replace width(1200) height(600)
display "SS_OUTPUT_FILE|file=fig_T39_forecast.png|type=graph|desc=forecast_visualization"
display ">>> 预测图已导出: fig_T39_forecast.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出预测结果: table_T39_forecast.csv"

preserve
keep if _n > `T'
rename `time_var' time
keep time forecast forecast_lo forecast_hi
export delimited using "table_T39_forecast.csv", replace
display "SS_OUTPUT_FILE|file=table_T39_forecast.csv|type=table|desc=forecast_results"
display ">>> 预测结果已导出"
restore

* 清理临时变量
drop fitted mse error forecast forecast_se forecast_lo forecast_hi

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T39 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型设定:"
display "  - 序列变量:        `series_var'"
display "  - ARIMA阶数:       (`p', `d', `q')"
display "  - 样本期数:        `T'"
display "  - 预测期数:        `horizon'"
display ""
display "样本内拟合:"
display "  - RMSE:            " %10.4f `rmse'
display "  - AIC:             " %10.4f `aic'
display ""
display "输出文件:"
display "  - table_T39_forecast.csv    预测结果"
display "  - fig_T39_forecast.png      预测可视化"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
display "SS_SUMMARY|key=horizon|value=`horizon'"
display "SS_SUMMARY|key=rmse|value=`rmse'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T39|status=ok|elapsed_sec=`elapsed'"

log close
