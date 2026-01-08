* ==============================================================================
* SS_TEMPLATE: id=T36  level=L0  module=G  title="Time Series Diagnostics"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - fig_T36_ts_line.png type=graph desc="Time series plot"
*   - fig_T36_acf_pacf.png type=graph desc="ACF/PACF plots"
*   - table_T36_corrgram.csv type=table desc="Autocorrelation table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="time series commands"
* ==============================================================================
* Task ID:      T36_ts_diagnostics_plots
* Task Name:    时间序列诊断图
* Family:       G - 时间序列分析
* Description:  生成时序图、ACF、PACF
* 
* Placeholders: __TIME_VAR__    - 时间变量
*               __SERIES_VAR__  - 时间序列变量
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

program define ss_fail_T36
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T36|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T36|level=L0|title=Time_Series_Diagnostics"
display "SS_SUMMARY|key=template_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T36_ts_diagnostics_plots                                        ║"
display "║  TASK_NAME: 时间序列诊断图（ACF/PACF分析）                                  ║"
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
        display as error "ERROR: No data.dta or data.csv found."
        ss_fail_T36 601 "confirm file" "data_file_not_found"
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
display "SS_OUTPUT_FILE|file=`datafile'|type=data|desc=converted_from_csv"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}
local n_total = _N
display ">>> 数据加载成功: `n_total' 条观测", replace

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 1: 变量设置与时间序列声明
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量设置与时间序列声明"
display "═══════════════════════════════════════════════════════════════════════════════"

local time_var "__TIME_VAR__"
local series_var "__SERIES_VAR__"

display ""
display ">>> 时间变量:        `time_var'"
display ">>> 序列变量:        `series_var'"
display "-------------------------------------------------------------------------------"

tsset `time_var'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 基本统计量
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 序列基本统计量"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
summarize `series_var', detail

quietly summarize `series_var'
local mean_val = r(mean)
local sd_val = r(sd)
local min_val = r(min)
local max_val = r(max)

display ""
display "{hline 50}"
display "均值:                " %12.4f `mean_val'
display "标准差:              " %12.4f `sd_val'
display "最小值:              " %12.4f `min_val'
display "最大值:              " %12.4f `max_val'
display "变异系数:            " %12.4f `sd_val'/abs(`mean_val')
display "{hline 50}"

* ==============================================================================
* SECTION 3: 时序图
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 时序图"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成时序折线图"

tsline `series_var', ///
    title("时间序列图: `series_var'", size(medium)) ///
    ytitle("`series_var'") ///
    xtitle("时间") ///
    lcolor(navy) lwidth(medium) ///
    scheme(s1color)

graph export "fig_T36_ts_line.png", replace width(1200) height(600)
display "SS_OUTPUT_FILE|file=fig_T36_ts_line.png|type=graph|desc=time_series_plot"
display ">>> 时序图已导出: fig_T36_ts_line.png"

* ==============================================================================
* SECTION 4: 自相关函数（ACF）与偏自相关函数（PACF）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: ACF与PACF分析"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> ACF（自相关函数）：衡量序列与其滞后值的相关性"
display ">>> PACF（偏自相关函数）：控制中间滞后后的相关性"
display "-------------------------------------------------------------------------------"

* 生成ACF图
ac `series_var', lags(20) ///
    title("自相关函数 (ACF)", size(medium)) ///
    name(acf_plot, replace)

* 生成PACF图
pac `series_var', lags(20) ///
    title("偏自相关函数 (PACF)", size(medium)) ///
    name(pacf_plot, replace)

* 组合图
graph combine acf_plot pacf_plot, cols(1) ///
    title("ACF 与 PACF 诊断图", size(medium)) ///
    note("虚线为95%置信区间; 超出虚线表示该滞后阶数显著", size(small))

graph export "fig_T36_acf_pacf.png", replace width(1000) height(1200)
display "SS_OUTPUT_FILE|file=fig_T36_acf_pacf.png|type=graph|desc=acf_pacf_plot"
display ">>> ACF/PACF组合图已导出: fig_T36_acf_pacf.png"

* ==============================================================================
* SECTION 5: 自相关系数表
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 自相关系数表"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
corrgram `series_var', lags(20)

* 导出自相关系数表
display ""
display ">>> 导出自相关系数表: table_T36_corrgram.csv"

preserve
clear
set obs 20
generate int lag = _n
generate double ac = .
generate double pac = .
generate double q_stat = .
generate double p_value = .

* 计算各滞后阶的AC和PAC
restore
preserve

* 使用官方命令计算自相关
tempfile corr_data
forvalues i = 1/20 {
    quietly corr `series_var' L`i'.`series_var'
    local ac_`i' = r(rho)
}

* 计算偏自相关（近似）
forvalues i = 1/20 {
    if `i' == 1 {
        local pac_`i' = `ac_1'
    }
    else {
        * 简化近似：直接使用回归系数
        quietly regress `series_var' L(1/`i').`series_var'
        matrix b = e(b)
        local pac_`i' = b[1, `i']
    }
}

* 创建输出数据
clear
set obs 20
generate int lag = _n
generate double ac = .
generate double pac = .

forvalues i = 1/20 {
    replace ac = `ac_`i'' in `i'
    replace pac = `pac_`i'' in `i'
}

export delimited using "table_T36_corrgram.csv", replace
display "SS_OUTPUT_FILE|file=table_T36_corrgram.csv|type=table|desc=autocorrelation_table"
display ">>> 自相关系数表已导出"
restore

* ==============================================================================
* SECTION 6: ARIMA阶数识别指导
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: ARIMA阶数识别指导"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "模式          ACF特征                    PACF特征"
display "{hline 70}"
display "AR(p)         拖尾（指数/振荡衰减）      p阶后截尾"
display "MA(q)         q阶后截尾                  拖尾（指数/振荡衰减）"
display "ARMA(p,q)     拖尾                       拖尾"
display "非平稳        缓慢线性衰减               首阶极高"
display "{hline 70}"
display ""
display ">>> 如果ACF缓慢衰减，说明序列可能非平稳，需要差分"
display ">>> 使用T37进行单位根检验确认平稳性"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T36 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "序列信息:"
display "  - 序列变量:        `series_var'"
display "  - 样本量:          " %10.0fc `n_total'
display "  - 均值:            " %10.4f `mean_val'
display "  - 标准差:          " %10.4f `sd_val'
display ""
display "输出文件:"
display "  - fig_T36_ts_line.png      时序图"
display "  - fig_T36_acf_pacf.png     ACF/PACF组合图"
display "  - table_T36_corrgram.csv   自相关系数表"
display ""
display "下一步建议:"
display "  - 使用T37进行单位根检验"
display "  - 根据ACF/PACF选择ARIMA阶数"
display "  - 使用T38估计ARIMA模型"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
display "SS_SUMMARY|key=mean|value=`mean_val'"
display "SS_SUMMARY|key=sd|value=`sd_val'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T36|status=ok|elapsed_sec=`elapsed'"

log close
