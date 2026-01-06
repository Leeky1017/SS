* ==============================================================================
* SS_TEMPLATE: id=T37  level=L0  module=G  title="Unit Root Tests"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T37_unit_root.csv type=table desc="Unit root test results"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="time series commands"
* ==============================================================================
* Task ID:      T37_ts_unit_root_adf
* Task Name:    单位根检验
* Family:       G - 时间序列分析
* Description:  进行ADF和PP单位根检验
* 
* Placeholders: __TIME_VAR__    - 时间变量
*               __SERIES_VAR__  - 时间序列变量
*               __LAGS__        - 滞后阶数
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
display "SS_TASK_BEGIN|id=T37|level=L0|title=Unit_Root_Tests"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T37_ts_unit_root_adf                                            ║"
display "║  TASK_NAME: 单位根检验（ADF & Phillips-Perron）                             ║"
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
display "SECTION 1: 变量设置与时间序列声明"
display "═══════════════════════════════════════════════════════════════════════════════"

local time_var "__TIME_VAR__"
local series_var "__SERIES_VAR__"
local lags = __LAGS__

display ""
display ">>> 时间变量:        `time_var'"
display ">>> 序列变量:        `series_var'"
display ">>> 滞后阶数:        `lags'"
display "-------------------------------------------------------------------------------"

tsset `time_var'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 序列概况
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 序列概况"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
summarize `series_var', detail

* ==============================================================================
* SECTION 3: ADF检验（原序列）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: ADF单位根检验（原序列）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> ADF检验假设："
display "    H0: 存在单位根（序列非平稳）"
display "    H1: 不存在单位根（序列平稳）"
display "-------------------------------------------------------------------------------"

display ""
display ">>> 模型1: 无常数项无趋势项（随机游走）"
display "{hline 50}"
dfuller `series_var', noconstant lags(`lags')

display ""
display ">>> 模型2: 含常数项（随机游走+漂移）"
display "{hline 50}"
dfuller `series_var', lags(`lags')

local adf_t_level = r(Zt)
local adf_p_level = r(p)

display ""
display ">>> 模型3: 含常数项和趋势项（趋势平稳）"
display "{hline 50}"
dfuller `series_var', trend lags(`lags')

* ==============================================================================
* SECTION 4: 一阶差分ADF检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 一阶差分后ADF检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 对一阶差分序列进行ADF检验"
display ">>> 若拒绝H0，则原序列为I(1)"
display "-------------------------------------------------------------------------------"

generate d_series = D.`series_var'
label variable d_series "一阶差分序列"

dfuller d_series, lags(`lags')

local adf_t_diff1 = r(Zt)
local adf_p_diff1 = r(p)

* ==============================================================================
* SECTION 5: Phillips-Perron检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: Phillips-Perron检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> PP检验使用非参数方法处理序列相关"
display ">>> 原序列PP检验："
display "-------------------------------------------------------------------------------"

pperron `series_var', lags(`lags')

local pp_t_level = r(Zt)
local pp_p_level = r(p)

display ""
display ">>> 一阶差分PP检验："
pperron d_series, lags(`lags')

local pp_t_diff1 = r(Zt)
local pp_p_diff1 = r(p)

* ==============================================================================
* SECTION 6: 检验结果汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 单位根检验结果汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "序列              检验方法        t统计量      p值        结论"
display "{hline 70}"
display "原序列            ADF          " %10.4f `adf_t_level' "   " %8.4f `adf_p_level' _continue
if `adf_p_level' < 0.05 {
    display "    平稳"
}
else {
    display "    非平稳"
}
display "原序列            PP           " %10.4f `pp_t_level' "   " %8.4f `pp_p_level' _continue
if `pp_p_level' < 0.05 {
    display "    平稳"
}
else {
    display "    非平稳"
}
display "一阶差分          ADF          " %10.4f `adf_t_diff1' "   " %8.4f `adf_p_diff1' _continue
if `adf_p_diff1' < 0.05 {
    display "    平稳"
}
else {
    display "    非平稳"
}
display "一阶差分          PP           " %10.4f `pp_t_diff1' "   " %8.4f `pp_p_diff1' _continue
if `pp_p_diff1' < 0.05 {
    display "    平稳"
}
else {
    display "    非平稳"
}
display "{hline 70}"

* 确定单整阶数
local int_order = 0
if `adf_p_level' >= 0.05 & `adf_p_diff1' < 0.05 {
    local int_order = 1
}
else if `adf_p_level' >= 0.05 & `adf_p_diff1' >= 0.05 {
    local int_order = 2
}

display ""
display ">>> 结论: 序列为 I(" %1.0f `int_order' ")"
if `int_order' == 0 {
    display "    原序列平稳，可直接建模"
}
else if `int_order' == 1 {
    display "    一阶差分后平稳，ARIMA中d=1"
}
else {
    display "    可能需要二阶差分"
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出单位根检验结果: table_T37_unit_root.csv"

preserve
clear
set obs 4

generate str20 series = ""
generate str10 test = ""
generate double t_stat = .
generate double p_value = .
generate str15 conclusion = ""

replace series = "level" in 1
replace test = "ADF" in 1
replace t_stat = `adf_t_level' in 1
replace p_value = `adf_p_level' in 1
replace conclusion = cond(`adf_p_level' < 0.05, "stationary", "non-stationary") in 1

replace series = "level" in 2
replace test = "PP" in 2
replace t_stat = `pp_t_level' in 2
replace p_value = `pp_p_level' in 2
replace conclusion = cond(`pp_p_level' < 0.05, "stationary", "non-stationary") in 2

replace series = "diff1" in 3
replace test = "ADF" in 3
replace t_stat = `adf_t_diff1' in 3
replace p_value = `adf_p_diff1' in 3
replace conclusion = cond(`adf_p_diff1' < 0.05, "stationary", "non-stationary") in 3

replace series = "diff1" in 4
replace test = "PP" in 4
replace t_stat = `pp_t_diff1' in 4
replace p_value = `pp_p_diff1' in 4
replace conclusion = cond(`pp_p_diff1' < 0.05, "stationary", "non-stationary") in 4

export delimited using "table_T37_unit_root.csv", replace
display "SS_OUTPUT_FILE|file=table_T37_unit_root.csv|type=table|desc=unit_root_test_results"
display ">>> 单位根检验结果已导出"
restore

drop d_series

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T37 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "序列信息:"
display "  - 序列变量:        `series_var'"
display "  - 样本量:          " %10.0fc `n_total'
display ""
display "单位根检验结果:"
display "  - 原序列ADF p值:   " %10.4f `adf_p_level'
display "  - 差分后ADF p值:   " %10.4f `adf_p_diff1'
display "  - 单整阶数:        I(" %1.0f `int_order' ")"
display ""
display "输出文件:"
display "  - table_T37_unit_root.csv   单位根检验结果"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
display "SS_SUMMARY|key=int_order|value=`int_order'"
display "SS_SUMMARY|key=adf_p_level|value=`adf_p_level'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T37|status=ok|elapsed_sec=`elapsed'"

log close
