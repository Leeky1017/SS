* ==============================================================================
* SS_TEMPLATE: id=TU01  level=L1  module=U  title="Histogram"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU01_histogram.png type=figure desc="Histogram"
*   - table_TU01_hist_stats.csv type=table desc="Stats"
*   - data_TU01_hist.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TU01|level=L1|title=Histogram"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local var = "__VAR__"
local bins = __BINS__
local normal = "__NORMAL__"
local title = "__TITLE__"

if `bins' < 5 | `bins' > 100 {
    local bins = 0
}
if "`normal'" == "" {
    local normal = "yes"
}
if "`title'" == "" | "`title'" == "__TITLE__" {
    local title = "直方图: `var'"
}

display ""
display ">>> 直方图参数:"
display "    变量: `var'"
display "    分箱: " cond(`bins' == 0, "auto", "`bins'")
display "    正态曲线: `normal'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
capture confirm numeric variable `var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`var' not found"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 统计计算 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 描述性统计"
display "═══════════════════════════════════════════════════════════════════════════════"

summarize `var', detail

local mean = r(mean)
local sd = r(sd)
local median = r(p50)
local skewness = r(skewness)
local kurtosis = r(kurtosis)
local min = r(min)
local max = r(max)

display ""
display ">>> 分布统计:"
display "    均值: " %12.4f `mean'
display "    标准差: " %12.4f `sd'
display "    中位数: " %12.4f `median'
display "    偏度: " %12.4f `skewness'
display "    峰度: " %12.4f `kurtosis'

display "SS_METRIC|name=mean|value=`mean'"
display "SS_METRIC|name=sd|value=`sd'"
display "SS_METRIC|name=skewness|value=`skewness'"

* 导出统计
preserve
clear
set obs 7
generate str20 statistic = ""
generate double value = .

replace statistic = "均值" in 1
replace value = `mean' in 1
replace statistic = "标准差" in 2
replace value = `sd' in 2
replace statistic = "中位数" in 3
replace value = `median' in 3
replace statistic = "偏度" in 4
replace value = `skewness' in 4
replace statistic = "峰度" in 5
replace value = `kurtosis' in 5
replace statistic = "最小值" in 6
replace value = `min' in 6
replace statistic = "最大值" in 7
replace value = `max' in 7

export delimited using "table_TU01_hist_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_TU01_hist_stats.csv|type=table|desc=hist_stats"
restore

* ============ 绘制直方图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 绘制直方图"
display "═══════════════════════════════════════════════════════════════════════════════"

local bin_opt ""
if `bins' > 0 {
    local bin_opt "bin(`bins')"
}

if "`normal'" == "yes" {
    histogram `var', `bin_opt' normal ///
        title("`title'") ///
        xtitle("`var'") ytitle("密度") ///
        note("N=`n_input', 均值=`=round(`mean', 0.01)', SD=`=round(`sd', 0.01)'")
}
else {
    histogram `var', `bin_opt' ///
        title("`title'") ///
        xtitle("`var'") ytitle("频率")
}

graph export "fig_TU01_histogram.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU01_histogram.png|type=figure|desc=histogram"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU01_hist.dta", replace
display "SS_OUTPUT_FILE|file=data_TU01_hist.dta|type=data|desc=hist_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量:            `var'"
display "  均值:            " %10.4f `mean'
display "  标准差:          " %10.4f `sd'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean|value=`mean'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU01|status=ok|elapsed_sec=`elapsed'"
log close
