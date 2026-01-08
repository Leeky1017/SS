* ==============================================================================
* SS_TEMPLATE: id=T14  level=L0  module=C  title="Paired Sample T-Test"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T14_paired_ttest.csv type=table desc="Paired t-test results"
*   - fig_T14_boxplot.png type=graph desc="Before-after boxplot comparison"
*   - fig_T14_diff_histogram.png type=graph desc="Difference distribution histogram"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core statistical commands"
* ==============================================================================
* Task ID:      T14_ttest_paired
* Task Name:    配对样本t检验
* Family:       C - 假设检验
* Description:  检验配对样本的均值差异
* 
* Placeholders: __VAR_BEFORE__  - 前测/基线变量
*               __VAR_AFTER__   - 后测/干预后变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 {
    * No log to close - expected
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T14|level=L0|title=Paired_Sample_T_Test"
display "SS_TASK_VERSION|version=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T14_ttest_paired                                                 ║"
display "║  TASK_NAME: 配对样本t检验                                                  ║"
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
        display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_METRIC|name=task_success|value=0"
        display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
        display "SS_TASK_END|id=T14|status=fail|elapsed_sec=`elapsed'"
        log close
        exit 601
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
    display "SS_OUTPUT_FILE|file=`datafile'|type=data|desc=converted_from_csv"
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

local var_before "__VAR_BEFORE__"
local var_after "__VAR_AFTER__"

capture confirm variable `var_before'
if _rc {
    display as error "ERROR: Before variable `var_before' not found"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable|msg=var_before_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

capture confirm numeric variable `var_before'
if _rc {
    display as error "ERROR: Before variable `var_before' is not numeric"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric|msg=var_before_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

capture confirm variable `var_after'
if _rc {
    display as error "ERROR: After variable `var_after' not found"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable|msg=var_after_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

capture confirm numeric variable `var_after'
if _rc {
    display as error "ERROR: After variable `var_after' is not numeric"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric|msg=var_after_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

display ""
display ">>> 前测变量: `var_before'"
display ">>> 后测变量: `var_after'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 配对数据描述统计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 配对数据描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 2.1 前测与后测各自的描述统计"
display "-------------------------------------------------------------------------------"
summarize `var_before' `var_after'

quietly summarize `var_before'
local n_before = r(N)
local mean_before = r(mean)
local sd_before = r(sd)

quietly summarize `var_after'
local n_after = r(N)
local mean_after = r(mean)
local sd_after = r(sd)

* ==============================================================================
* SECTION 3: 计算配对差异
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 配对差异分析"
display "═══════════════════════════════════════════════════════════════════════════════"

generate _diff_temp = `var_after' - `var_before'
label variable _diff_temp "差异（后测 - 前测）"

display ""
display ">>> 差异变量: 后测 - 前测"
display "-------------------------------------------------------------------------------"
summarize _diff_temp, detail

quietly summarize _diff_temp, detail
local n_pairs = r(N)
local mean_diff = r(mean)
local sd_diff = r(sd)
local se_diff = `sd_diff' / sqrt(`n_pairs')
local skew_diff = r(skewness)
local kurt_diff = r(kurtosis)

* 正态性检验
display ""
display ">>> 差异的正态性检验"
display "-------------------------------------------------------------------------------"

local sw_p = .
if `n_pairs' <= 2000 {
    quietly swilk _diff_temp
    local sw_p = r(p)
    display "Shapiro-Wilk W:  " %10.6f r(W)
    display "p 值:            " %10.6f `sw_p'
    
    if `sw_p' < 0.05 {
        display ""
        display as error "WARNING: 差异分布偏离正态（p < 0.05），考虑使用非参数检验"
    }
    else {
        display ""
        display as result ">>> 差异分布不拒绝正态性假设 ✓"
    }
}
else {
    display ">>> 样本量 > 2000，根据中心极限定理，t检验稳健"
}

* ==============================================================================
* SECTION 4: 配对 t 检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 配对 t 检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 检验假设"
display "-------------------------------------------------------------------------------"
display "H0: μ_diff = 0  （前后测均值无差异）"
display "H1: μ_diff ≠ 0  （前后测均值有差异，双侧）"
display ""

ttest `var_before' == `var_after'

* 保存检验结果
local t_stat = r(t)
local p_two = r(p)
local df = r(df_t)

* ==============================================================================
* SECTION 5: 置信区间
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 差异的置信区间"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
ci means _diff_temp, level(95)

quietly ci means _diff_temp, level(95)
local ci_lb = r(lb)
local ci_ub = r(ub)

display ""
display ">>> 95% 置信区间: [`: display %9.4f `ci_lb'', `: display %9.4f `ci_ub'']"

if `ci_lb' > 0 {
    display as error ">>> 置信区间完全在0以上 → 后测显著高于前测"
}
else if `ci_ub' < 0 {
    display as error ">>> 置信区间完全在0以下 → 后测显著低于前测"
}
else {
    display ">>> 置信区间包含0 → 差异不显著"
}

* ==============================================================================
* SECTION 6: 效应量（Cohen's d for paired samples）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 效应量（Cohen's d）"
display "═══════════════════════════════════════════════════════════════════════════════"

local cohens_d = `mean_diff' / `sd_diff'
local abs_d = abs(`cohens_d')

display ""
display "Cohen's d（配对）= 平均差异 / 差异标准差"
display "                 = `: display %9.4f `mean_diff'' / `: display %9.4f `sd_diff''"
display "                 = " %9.4f `cohens_d'
display ""

if `abs_d' < 0.2 {
    local effect_size "小效应"
}
else if `abs_d' < 0.5 {
    local effect_size "小到中效应"
}
else if `abs_d' < 0.8 {
    local effect_size "中效应"
}
else {
    local effect_size "大效应"
}

display "效应量判断: `effect_size' （|d| = `: display %5.3f `abs_d''）"

* ==============================================================================
* SECTION 7: 检验结论汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 检验结论汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "检验类型:       配对样本 t 检验"
display "前测变量:       `var_before'"
display "后测变量:       `var_after'"
display "{hline 70}"
display "配对数:         " %10.0fc `n_pairs'
display "前测均值:       " %10.4f `mean_before' "  (SD=" %8.4f `sd_before' ")"
display "后测均值:       " %10.4f `mean_after' "  (SD=" %8.4f `sd_after' ")"
display "平均差异:       " %10.4f `mean_diff' "  (后测 - 前测)"
display "差异标准差:     " %10.4f `sd_diff'
display "{hline 70}"
display "t 统计量:       " %10.4f `t_stat'
display "自由度 (df):    " %10.0f `df'
display "p 值（双侧）:   " %10.4f `p_two'
display "{hline 70}"
display "Cohen's d:      " %10.4f `cohens_d' "  (`effect_size')"
display "95% CI:         [`: display %9.4f `ci_lb'', `: display %9.4f `ci_ub'']"
display "{hline 70}"

display ""
display ">>> 统计结论:"
if `p_two' < 0.01 {
    display as error "    在 1% 显著性水平下拒绝原假设 (p < 0.01) ***"
    local sig_level "***"
}
else if `p_two' < 0.05 {
    display as error "    在 5% 显著性水平下拒绝原假设 (p < 0.05) **"
    local sig_level "**"
}
else if `p_two' < 0.10 {
    display "    在 10% 显著性水平下拒绝原假设 (p < 0.10) *"
    local sig_level "*"
}
else {
    display as result "    不能拒绝原假设 (p ≥ 0.10)"
    local sig_level ""
}

if `mean_diff' > 0 & `p_two' < 0.05 {
    display as error "    后测显著高于前测，平均增加 `: display %9.4f `mean_diff''"
}
else if `mean_diff' < 0 & `p_two' < 0.05 {
    display as error "    后测显著低于前测，平均减少 `: display %9.4f abs(`mean_diff')'"
}

* ==============================================================================
* SECTION 8: 可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 8.1 前后对比箱线图"

quietly graph box `var_before' `var_after', ///
    title("前后测对比", size(medium)) ///
    subtitle("差异 = `: display %9.3f `mean_diff'' (p = `: display %6.4f `p_two'')", size(small)) ///
    legend(label(1 "前测") label(2 "后测")) ///
    scheme(s2color)

quietly graph export "fig_T14_boxplot.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T14_boxplot.png|type=graph|desc=before_after_boxplot_comparison"
display ">>> 已导出: fig_T14_boxplot.png"

display ""
display ">>> 8.2 差异分布直方图"

quietly histogram _diff_temp, ///
    frequency normal ///
    title("配对差异分布", size(medium)) ///
    xtitle("差异（后测 - 前测）") ///
    ytitle("频数") ///
    note("红线: 参考正态分布") ///
    xline(0, lcolor(red) lpattern(dash)) ///
    scheme(s2color)

quietly graph export "fig_T14_diff_histogram.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T14_diff_histogram.png|type=graph|desc=difference_distribution_histogram"
display ">>> 已导出: fig_T14_diff_histogram.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 9: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 9: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出检验结果: table_T14_paired_ttest.csv"

preserve
clear
set obs 1

generate str32 test_type = "paired_ttest"
generate str32 var_before = "`var_before'"
generate str32 var_after = "`var_after'"
generate long n_pairs = `n_pairs'
generate double mean_before = `mean_before'
generate double mean_after = `mean_after'
generate double mean_diff = `mean_diff'
generate double sd_diff = `sd_diff'
generate double t_stat = `t_stat'
generate double df = `df'
generate double p_value = `p_two'
generate double ci_lower = `ci_lb'
generate double ci_upper = `ci_ub'
generate double cohens_d = `cohens_d'
generate str16 significance = "`sig_level'"

export delimited using "table_T14_paired_ttest.csv", replace
display "SS_OUTPUT_FILE|file=table_T14_paired_ttest.csv|type=table|desc=paired_ttest_results"
display ">>> 检验结果已导出"
restore

* 清理临时变量
drop _diff_temp

* ==============================================================================
* SECTION 10: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T14 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "检验概况:"
display "  - 前测变量:        `var_before'"
display "  - 后测变量:        `var_after'"
display "  - 配对数:          " %10.0fc `n_pairs'
display "  - 平均差异:        " %10.4f `mean_diff'
display "  - t 统计量:        " %10.4f `t_stat'
display "  - p 值:            " %10.4f `p_two'
display "  - Cohen's d:       " %10.4f `cohens_d' " (`effect_size')"
display ""
display "输出文件:"
display "  - table_T14_paired_ttest.csv     检验结果汇总表"
display "  - fig_T14_boxplot.png            前后对比箱线图"
display "  - fig_T14_diff_histogram.png     差异分布直方图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_pairs|value=`n_pairs'"
display "SS_SUMMARY|key=mean_diff|value=`mean_diff'"
display "SS_SUMMARY|key=p_value|value=`p_two'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_pairs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T14|status=ok|elapsed_sec=`elapsed'"

log close
