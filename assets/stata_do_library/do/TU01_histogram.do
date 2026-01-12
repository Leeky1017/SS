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

* BEST_PRACTICE_REVIEW (EN):
* - Choose binning intentionally (rules-of-thumb vs domain-driven) and report sensitivity; bins can change perceived distribution.
* - Use density vs frequency consistently and label axes; consider adding reference lines (mean/median) for interpretation.
* - For heavy tails/outliers, consider log scale or robust summaries alongside histograms.
* 最佳实践审查（ZH）:
* - 分箱应有依据（经验法则/领域知识）并做敏感性分析；分箱会影响分布观感。
* - 统一使用密度或频数并标注坐标轴；可加入均值/中位数参考线便于解释。
* - 对厚尾/离群值可考虑对数尺度或搭配稳健统计量。

* ============ 初始化 ============
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

display "SS_TASK_BEGIN|id=TU01|level=L1|title=Histogram"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local var = "__VAR__"
local bins_raw = "__BINS__"
local bins = real("`bins_raw'")
local normal = "__NORMAL__"
local title = "__TITLE__"

if missing(`bins') | `bins' < 5 | `bins' > 100 {
    local bins = 0
}
local bins = floor(`bins')
if "`normal'" == "" | "`normal'" == "__NORMAL__" {
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
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate plotting variable existence/type.
* ZH: 校验绘图变量存在且为数值型。

* ============ 变量检查 ============
capture confirm numeric variable `var'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=var_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Compute summary stats and export histogram figure/table outputs.
* ZH: 计算统计量并导出直方图与表格输出。

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
