* ==============================================================================
* SS_TEMPLATE: id=T10  level=L0  module=B  title="Distribution Plots"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - fig_T10_histogram.png type=graph desc="Histogram with normal curve"
*   - fig_T10_kdensity.png type=graph desc="Kernel density plot"
*   - fig_T10_boxplot.png type=graph desc="Box plot"
*   - fig_T10_qqplot.png type=graph desc="Normal QQ plot"
*   - table_T10_normality_test.csv type=table desc="Normality test results"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core graphics commands"
* ==============================================================================
* Task ID:      T10_distribution_plots
* Task Name:    变量分布可视化（直方图/箱线图/核密度/QQ图）
* Family:       B - 描述性统计
* Description:  生成数值变量的多种分布图
* 
* Placeholders: __NUMERIC_VAR__  - 要分析的数值变量
*               __GROUP_VAR__    - 分组变量（可选）
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
display "SS_TASK_BEGIN|id=T10|level=L0|title=Distribution_Plots"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T10_distribution_plots                                        ║"
display "║  TASK_NAME: 变量分布可视化（直方图/箱线图/核密度/QQ图）                   ║"
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
* SECTION 1: 变量检查与准备
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与准备"
display "═══════════════════════════════════════════════════════════════════════════════"

* 检查分析变量
local analysis_var "__NUMERIC_VAR__"

capture confirm variable `analysis_var'
if _rc {
    display as error "ERROR: Variable `analysis_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm numeric variable `analysis_var'
if _rc {
    display as error "ERROR: Variable `analysis_var' is not numeric"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

display ">>> 分析变量: `analysis_var'"

* 检查分组变量（可选）
local group_var "__GROUP_VAR__"
local has_group = 0

capture confirm variable `group_var'
if _rc == 0 {
    local has_group = 1
    display ">>> 分组变量: `group_var'"
}
else {
    display ">>> 分组变量: 未指定"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 分布统计摘要
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 分布统计摘要"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 2.1 详细描述统计"
display "-------------------------------------------------------------------------------"
summarize `analysis_var', detail

* 保存统计量
quietly summarize `analysis_var', detail
local n_obs = r(N)
local mean_val = r(mean)
local sd_val = r(sd)
local min_val = r(min)
local max_val = r(max)
local p50_val = r(p50)
local skew_val = r(skewness)
local kurt_val = r(kurtosis)

* 判断分布特征
display ""
display ">>> 2.2 分布特征诊断"
display "-------------------------------------------------------------------------------"
display "偏度 (Skewness):    " %8.3f `skew_val'
display "峰度 (Kurtosis):    " %8.3f `kurt_val'
display ""

if abs(`skew_val') > 1 {
    display as error ">>> 分布严重偏斜（|Skewness| > 1）"
}
else if abs(`skew_val') > 0.5 {
    display ">>> 分布中等偏斜（0.5 < |Skewness| ≤ 1）"
}
else {
    display as result ">>> 分布基本对称（|Skewness| ≤ 0.5）✓"
}

if `kurt_val' > 4 {
    display as error ">>> 尖峰厚尾分布（Kurtosis > 4）- 金融数据常见"
}
else if `kurt_val' < 2 {
    display ">>> 平峰薄尾分布（Kurtosis < 2）"
}
else {
    display as result ">>> 峰度接近正态（2 ≤ Kurtosis ≤ 4）✓"
}

* ==============================================================================
* SECTION 3: 正态性检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 正态性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
local sw_stat = .
local sw_p = .
local sk_chi2 = .
local sk_p = .

if `n_obs' <= 2000 {
    display ">>> 3.1 Shapiro-Wilk 检验（N ≤ 2000）"
    display "-------------------------------------------------------------------------------"
    quietly swilk `analysis_var'
    local sw_stat = r(W)
    local sw_p = r(p)
    display "W 统计量:           " %10.6f `sw_stat'
    display "p 值:               " %10.6f `sw_p'
    
    if `sw_p' < 0.05 {
        display as error ">>> 拒绝正态性假设（p < 0.05）"
    }
    else {
        display as result ">>> 不能拒绝正态性假设（p ≥ 0.05）✓"
    }
}
else {
    display ">>> Shapiro-Wilk 检验要求 N ≤ 2000，样本量过大跳过"
}

display ""
display ">>> 3.2 Skewness/Kurtosis 检验"
display "-------------------------------------------------------------------------------"
quietly sktest `analysis_var'
local sk_chi2 = r(chi2)
local sk_p = r(p_chi2)
display "Chi2 统计量:        " %10.4f `sk_chi2'
display "联合检验 p 值:      " %10.6f `sk_p'

if `sk_p' < 0.05 {
    display as error ">>> 拒绝正态性假设（p < 0.05）"
}
else {
    display as result ">>> 不能拒绝正态性假设（p ≥ 0.05）✓"
}

* ==============================================================================
* SECTION 4: 生成直方图
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成分布图"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 4.1 直方图（含正态曲线）"

quietly histogram `analysis_var', ///
    frequency ///
    normal ///
    title("`analysis_var' 分布直方图", size(medium)) ///
    subtitle("N=`n_obs', Mean=`: display %9.3f `mean_val'', SD=`: display %9.3f `sd_val''", size(small)) ///
    xtitle("`analysis_var'") ///
    ytitle("频数") ///
    note("红色曲线为正态分布参考") ///
    scheme(s2color)

quietly graph export "fig_T10_histogram.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_T10_histogram.png|type=graph|desc=histogram_with_normal_curve"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"
display ">>> 已导出: fig_T10_histogram.png"

* ==============================================================================
* SECTION 5: 生成核密度图
* ==============================================================================
display ""
display ">>> 4.2 核密度图"

quietly kdensity `analysis_var', ///
    normal ///
    title("`analysis_var' 核密度估计", size(medium)) ///
    xtitle("`analysis_var'") ///
    ytitle("密度") ///
    note("虚线为正态分布参考") ///
    scheme(s2color)

quietly graph export "fig_T10_kdensity.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_T10_kdensity.png|type=graph|desc=kernel_density_plot"
display ">>> 已导出: fig_T10_kdensity.png"

* ==============================================================================
* SECTION 6: 生成箱线图
* ==============================================================================
display ""
display ">>> 4.3 箱线图"

quietly graph box `analysis_var', ///
    title("`analysis_var' 箱线图", size(medium)) ///
    ytitle("`analysis_var'") ///
    note("显示中位数、四分位数和异常值（圆点）") ///
    scheme(s2color)

quietly graph export "fig_T10_boxplot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_T10_boxplot.png|type=graph|desc=box_plot"
display ">>> 已导出: fig_T10_boxplot.png"

* ==============================================================================
* SECTION 7: 生成QQ图
* ==============================================================================
display ""
display ">>> 4.4 正态QQ图"

quietly qnorm `analysis_var', ///
    title("`analysis_var' 正态Q-Q图", size(medium)) ///
    note("点越接近对角线，分布越接近正态") ///
    scheme(s2color)

quietly graph export "fig_T10_qqplot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_T10_qqplot.png|type=graph|desc=normal_qq_plot"
display ">>> 已导出: fig_T10_qqplot.png"

* ==============================================================================
* SECTION 8: 分组图（如有分组变量）
* ==============================================================================
if `has_group' {
    display ""
    display "═══════════════════════════════════════════════════════════════════════════════"
    display "SECTION 5: 分组分布图"
    display "═══════════════════════════════════════════════════════════════════════════════"
    
    display ""
    display ">>> 5.1 分组箱线图"
    
    quietly graph box `analysis_var', ///
        over(`group_var') ///
        title("`analysis_var' 按 `group_var' 分组", size(medium)) ///
        ytitle("`analysis_var'") ///
        note("按分组变量展示分布差异") ///
        scheme(s2color)
    
    quietly graph export "fig_T10_boxplot_grouped.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_T10_boxplot_grouped.png|type=graph|desc=grouped_box_plot"
    display ">>> 已导出: fig_T10_boxplot_grouped.png"
    
    display ""
    display ">>> 5.2 分组核密度图"
    
    * 获取分组数
    quietly levelsof `group_var', local(groups)
    local n_groups: word count `groups'
    
    if `n_groups' <= 6 {
        quietly twoway ///
            (kdensity `analysis_var' if `group_var' == `:word 1 of `groups'') ///
            (kdensity `analysis_var' if `group_var' == `:word 2 of `groups'', lpattern(dash)) ///
            , ///
            title("`analysis_var' 分组核密度对比", size(medium)) ///
            xtitle("`analysis_var'") ///
            ytitle("密度") ///
            legend(order(1 "`group_var'=`:word 1 of `groups''" 2 "`group_var'=`:word 2 of `groups''")) ///
            scheme(s2color)
        
        quietly graph export "fig_T10_kdensity_grouped.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_T10_kdensity_grouped.png|type=graph|desc=grouped_kernel_density_plot"
        display ">>> 已导出: fig_T10_kdensity_grouped.png"
    }
    else {
        display ">>> 分组数过多（>6），跳过分组核密度图"
    }
}

* ==============================================================================
* SECTION 9: 导出正态性检验结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出正态性检验结果: table_T10_normality_test.csv"

preserve
clear
set obs 1

generate str32 variable = "`analysis_var'"
generate long n = `n_obs'
generate double mean = `mean_val'
generate double sd = `sd_val'
generate double skewness = `skew_val'
generate double kurtosis = `kurt_val'
generate double sw_W = `sw_stat'
generate double sw_p = `sw_p'
generate double sk_chi2 = `sk_chi2'
generate double sk_p = `sk_p'

export delimited using "table_T10_normality_test.csv", replace
display "SS_OUTPUT_FILE|file=table_T10_normality_test.csv|type=table|desc=normality_test_results"
display ">>> 正态性检验结果已导出"
restore

* ==============================================================================
* SECTION 10: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T10 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "分析概况:"
display "  - 分析变量:        `analysis_var'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 偏度:            " %10.3f `skew_val'
display "  - 峰度:            " %10.3f `kurt_val'
display ""
display "输出文件:"
display "  - fig_T10_histogram.png         直方图（含正态曲线）"
display "  - fig_T10_kdensity.png          核密度图"
display "  - fig_T10_boxplot.png           箱线图"
display "  - fig_T10_qqplot.png            正态Q-Q图"
if `has_group' {
    display "  - fig_T10_boxplot_grouped.png   分组箱线图"
}
display "  - table_T10_normality_test.csv  正态性检验结果"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=variable|value=`analysis_var'"
display "SS_SUMMARY|key=skewness|value=`skew_val'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T10|status=ok|elapsed_sec=`elapsed'"

log close
