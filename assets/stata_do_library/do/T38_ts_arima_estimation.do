* ==============================================================================
* SS_TEMPLATE: id=T38  level=L0  module=G  title="ARIMA Model Estimation"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T38_arima_coef.csv type=table desc="ARIMA coefficients"
*   - table_T38_arima_gof.csv type=table desc="Model fit statistics"
*   - fig_T38_arima_fit.png type=graph desc="Fit visualization"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="time series commands"
* ==============================================================================
* Task ID:      T38_ts_arima_estimation
* Task Name:    ARIMA模型估计
* Family:       G - 时间序列分析
* Description:  估计ARIMA(p,d,q)模型
* 
* Placeholders: __TIME_VAR__    - 时间变量
*               __SERIES_VAR__  - 时间序列变量
*               __P__           - AR阶数
*               __D__           - 差分阶数
*               __Q__           - MA阶数
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
display "SS_TASK_BEGIN|id=T38|level=L0|title=ARIMA_Model_Estimation"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T38_ts_arima_estimation                                         ║"
display "║  TASK_NAME: ARIMA模型估计（ARIMA Model Estimation）                         ║"
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
* SECTION 1: 变量设置与时间序列声明
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量设置与ARIMA阶数"
display "═══════════════════════════════════════════════════════════════════════════════"

local time_var "__TIME_VAR__"
local series_var "__SERIES_VAR__"
local p = __P__
local d = __D__
local q = __Q__

display ""
display ">>> 时间变量:        `time_var'"
display ">>> 序列变量:        `series_var'"
display ">>> ARIMA阶数:       (`p', `d', `q')"
display "-------------------------------------------------------------------------------"

tsset `time_var'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: ARIMA模型估计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: ARIMA(`p', `d', `q') 模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> ARIMA模型设定："
display "    AR(p): 自回归阶数 = `p'"
display "    I(d):  差分阶数 = `d'"
display "    MA(q): 移动平均阶数 = `q'"
display "-------------------------------------------------------------------------------"

arima `series_var', arima(`p', `d', `q')
estimates store arima_model

local ll = e(ll)
local k = e(k)
local n_used = e(N)
local aic = -2*`ll' + 2*`k'
local bic = -2*`ll' + `k'*ln(`n_used')

* ==============================================================================
* SECTION 3: 模型摘要
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 模型拟合指标"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 50}"
display "样本量:              " %12.0fc `n_used'
display "参数个数:            " %12.0f `k'
display "对数似然:            " %12.4f `ll'
display "AIC:                 " %12.4f `aic'
display "BIC:                 " %12.4f `bic'
display "{hline 50}"

* ==============================================================================
* SECTION 4: 残差诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 残差诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

predict resid, residuals

display ""
display ">>> 残差统计量："
summarize resid, detail

* Ljung-Box Q检验
display ""
display ">>> Ljung-Box Q检验（残差白噪声检验）："
display "    H0: 残差为白噪声（无自相关）"
display "    H1: 残差存在自相关"
display "-------------------------------------------------------------------------------"

wntestq resid, lags(12)

local q_stat = r(stat)
local q_p = r(p)

display ""
display "{hline 50}"
display "Q统计量:             " %12.4f `q_stat'
display "p值:                 " %12.4f `q_p'
display "{hline 50}"

if `q_p' > 0.05 {
    display ""
    display as result ">>> 不拒绝H0 (p > 0.05): 残差为白噪声，模型拟合良好"
}
else {
    display ""
    display as error ">>> 拒绝H0 (p <= 0.05): 残差存在自相关"
    display as error "    建议调整ARIMA阶数或检查模型设定"
}

* 残差ACF
display ""
display ">>> 残差自相关图："
corrgram resid, lags(12)

* ==============================================================================
* SECTION 5: 拟合效果可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 拟合效果可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

predict fitted, xb

display ""
display ">>> 生成实际值与拟合值对比图"

twoway (tsline `series_var', lcolor(navy) lwidth(medium)) ///
       (tsline fitted, lcolor(cranberry) lwidth(medium) lpattern(dash)), ///
    title("ARIMA(`p',`d',`q'): 实际值 vs 拟合值", size(medium)) ///
    ytitle("`series_var'") ///
    xtitle("时间") ///
    legend(label(1 "实际值") label(2 "拟合值") position(6) rows(1)) ///
    scheme(s1color)

graph export "fig_T38_arima_fit.png", replace width(1200) height(600)
display "SS_OUTPUT_FILE|file=fig_T38_arima_fit.png|type=graph|desc=fit_visualization"
display ">>> 拟合效果图已导出: fig_T38_arima_fit.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 6: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出ARIMA系数
display ""
display ">>> 导出ARIMA系数: table_T38_arima_coef.csv"

matrix coef = e(b)
matrix var = e(V)

preserve
clear
local ncols = colsof(coef)
set obs `ncols'

generate str32 parameter = ""
generate double coef = .
generate double se = .
generate double z = .
generate double p = .

local names: colnames coef
local i = 1
foreach name of local names {
    quietly replace parameter = "`name'" in `i'
    quietly replace coef = coef[1, `i'] in `i'
    quietly replace se = sqrt(var[`i', `i']) in `i'
    local z_val = coef[1, `i'] / sqrt(var[`i', `i'])
    local p_val = 2 * (1 - normal(abs(`z_val')))
    quietly replace z = `z_val' in `i'
    quietly replace p = `p_val' in `i'
    local i = `i' + 1
}

export delimited using "table_T38_arima_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T38_arima_coef.csv|type=table|desc=arima_coefficients"
display ">>> ARIMA系数已导出"
restore

* 导出模型拟合指标
display ""
display ">>> 导出模型拟合指标: table_T38_arima_gof.csv"

preserve
clear
set obs 1

generate int p = `p'
generate int d = `d'
generate int q = `q'
generate int n = `n_used'
generate double ll = `ll'
generate double aic = `aic'
generate double bic = `bic'
generate double ljung_box_q = `q_stat'
generate double ljung_box_p = `q_p'

export delimited using "table_T38_arima_gof.csv", replace
display "SS_OUTPUT_FILE|file=table_T38_arima_gof.csv|type=table|desc=model_fit_statistics"
display ">>> 模型拟合指标已导出"
restore

drop resid fitted

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T38 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型设定:"
display "  - 序列变量:        `series_var'"
display "  - ARIMA阶数:       (`p', `d', `q')"
display "  - 样本量:          " %10.0fc `n_used'
display ""
display "模型拟合:"
display "  - 对数似然:        " %10.4f `ll'
display "  - AIC:             " %10.4f `aic'
display "  - BIC:             " %10.4f `bic'
display ""
display "残差诊断:"
display "  - Ljung-Box Q:     " %10.4f `q_stat'
display "  - p值:             " %10.4f `q_p'
if `q_p' > 0.05 {
    display "  - 结论:            残差为白噪声 ✓"
}
else {
    display "  - 结论:            残差存在自相关 ✗"
}
display ""
display "输出文件:"
display "  - table_T38_arima_coef.csv    ARIMA系数"
display "  - table_T38_arima_gof.csv     模型拟合指标"
display "  - fig_T38_arima_fit.png       拟合效果图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_used'"
display "SS_SUMMARY|key=aic|value=`aic'"
display "SS_SUMMARY|key=bic|value=`bic'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_used'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T38|status=ok|elapsed_sec=`elapsed'"

log close
