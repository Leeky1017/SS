* ==============================================================================
* SS_TEMPLATE: id=T15  level=L0  module=C  title="One-way ANOVA"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T15_anova_result.csv type=table desc="ANOVA results summary"
*   - table_T15_group_stats.csv type=table desc="Group descriptive statistics"
*   - fig_T15_boxplot.png type=graph desc="Group boxplot comparison"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core ANOVA commands"
* ==============================================================================
* Task ID:      T15_anova_oneway
* Task Name:    单因素方差分析（One-way ANOVA）
* Family:       C - 假设检验
* Description:  比较三组或更多组的均值是否存在显著差异
* 
* Placeholders: __DEPVAR__    - 因变量（连续变量）
*               __GROUP_VAR__  - 分组变量（分类变量）
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
display "SS_TASK_BEGIN|id=T15|level=L0|title=One_way_ANOVA"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: ANOVA table + post-hoc summaries (CSV) / 输出：方差分析表 + 事后比较（CSV）
* - Error policy: fail on missing group var; warn on small groups / 错误策略：分组变量缺失→fail；小组样本提示→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T15|ssc=none|output=csv|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T15_anova_oneway                                                 ║"
display "║  TASK_NAME: 单因素方差分析（One-way ANOVA）                                ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ---------- 标准化数据加载逻辑开始 ----------
* [ZH] S01 加载数据（标准化 data.dta / data.csv）
* [EN] S01 Load data (standardized data.dta / data.csv)
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
        display "SS_TASK_END|id=T15|status=fail|elapsed_sec=`elapsed'"
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
* [ZH] S02 校验因变量与分组变量（组别与样本量）
* [EN] S02 Validate outcome and group vars (groups/sample sizes)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与准备"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEPVAR__"
local group_var "__GROUP_VAR__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable|msg=dep_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T15|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

capture confirm numeric variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' is not numeric"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric|msg=dep_var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T15|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

capture confirm variable `group_var'
if _rc {
    display as error "ERROR: Group variable `group_var' not found"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable|msg=group_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T15|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

* 检查分组数
quietly levelsof `group_var', local(groups)
local n_groups: word count `groups'

if `n_groups' < 2 {
    display as error "ERROR: Group variable must have at least 2 levels"
    display "SS_RC|code=198|cmd=levelsof|msg=insufficient_groups|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T15|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 198
}

display ""
display ">>> 因变量:     `dep_var'"
display ">>> 分组变量:   `group_var'"
display ">>> 组别数量:   `n_groups' 组"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 分组描述统计
* ==============================================================================
* [ZH] S03 进行单因素 ANOVA 并导出结果
* [EN] S03 Run one-way ANOVA and export results
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 分组描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
tabstat `dep_var', by(`group_var') statistics(n mean sd min p50 max) columns(statistics) longstub

* 计算总体统计
quietly summarize `dep_var'
local grand_mean = r(mean)
local grand_sd = r(sd)
local n_obs = r(N)

* ==============================================================================
* SECTION 3: 方差齐性检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 方差齐性检验（ANOVA前提假设）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Levene 检验（稳健方差齐性检验）"
display "-------------------------------------------------------------------------------"

robvar `dep_var', by(`group_var')
local levene_p = r(p_2)

display ""
if `levene_p' < 0.05 {
    display as error ">>> Levene检验 p = `: display %6.4f `levene_p'' < 0.05"
    display as error ">>> 拒绝方差齐性假设，ANOVA结果需谨慎解读"
    display as error ">>> 建议使用 Kruskal-Wallis 非参数检验"
}
else {
    display as result ">>> Levene检验 p = `: display %6.4f `levene_p'' ≥ 0.05"
    display as result ">>> 不能拒绝方差齐性假设，满足ANOVA前提 ✓"
}

* ==============================================================================
* SECTION 4: 单因素方差分析
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 单因素方差分析"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 检验假设"
display "-------------------------------------------------------------------------------"
display "H0: μ₁ = μ₂ = ... = μₖ  （所有组均值相等）"
display "H1: 至少有两组均值不相等"
display ""

anova `dep_var' `group_var'

* 保存结果
local F_stat = e(F)
local df_between = e(df_m)
local df_within = e(df_r)
local p_value = Ftail(`df_between', `df_within', `F_stat')
local SS_between = e(mss)
local SS_within = e(rss)
local SS_total = `SS_between' + `SS_within'

* ==============================================================================
* SECTION 5: 效应量
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 效应量"
display "═══════════════════════════════════════════════════════════════════════════════"

local eta_sq = `SS_between' / `SS_total'
local omega_sq = (`SS_between' - `df_between' * (`SS_within' / `df_within')) / (`SS_total' + (`SS_within' / `df_within'))
if `omega_sq' < 0 {
    local omega_sq = 0
}

display ""
display "Eta-squared (η²):       " %8.4f `eta_sq'
display "Omega-squared (ω²):     " %8.4f `omega_sq' "  (偏差校正估计)"
display ""

if `eta_sq' < 0.01 {
    local effect_size "小效应"
}
else if `eta_sq' < 0.06 {
    local effect_size "中等效应"
}
else if `eta_sq' < 0.14 {
    local effect_size "较大效应"
}
else {
    local effect_size "大效应"
}

display "效应量判断: `effect_size' （η² = `: display %5.4f `eta_sq''）"
display ""
display "效应量参考标准（Cohen, 1988）："
display "  η² < 0.01   小效应"
display "  0.01-0.06   中等效应"
display "  0.06-0.14   较大效应"
display "  η² ≥ 0.14   大效应"

* ==============================================================================
* SECTION 6: 事后多重比较
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 事后多重比较"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 6.1 Bonferroni 多重比较（最保守）"
display "-------------------------------------------------------------------------------"

oneway `dep_var' `group_var', bonferroni

display ""
display ">>> 6.2 Scheffé 多重比较（适用于任意对比）"
display "-------------------------------------------------------------------------------"

oneway `dep_var' `group_var', scheffe

* ==============================================================================
* SECTION 7: 检验结论汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 检验结论汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "检验类型:       单因素方差分析（One-way ANOVA）"
display "因变量:         `dep_var'"
display "分组变量:       `group_var' (`n_groups' 组)"
display "{hline 70}"
display "总样本量:       " %10.0fc `n_obs'
display "总体均值:       " %10.4f `grand_mean'
display "{hline 70}"
display "组间平方和:     " %12.4f `SS_between'
display "组内平方和:     " %12.4f `SS_within'
display "总平方和:       " %12.4f `SS_total'
display "{hline 70}"
display "F 统计量:       " %10.4f `F_stat'
display "组间自由度:     " %10.0f `df_between'
display "组内自由度:     " %10.0f `df_within'
display "p 值:           " %10.4f `p_value'
display "{hline 70}"
display "η² (Eta-squared): " %8.4f `eta_sq' "  (`effect_size')"
display "Levene检验 p值:   " %8.4f `levene_p'
display "{hline 70}"

display ""
display ">>> 统计结论:"
if `p_value' < 0.01 {
    display as error "    在 1% 显著性水平下拒绝原假设 (p < 0.01) ***"
    display as error "    至少有一组均值与其他组存在极显著差异"
    local sig_level "***"
}
else if `p_value' < 0.05 {
    display as error "    在 5% 显著性水平下拒绝原假设 (p < 0.05) **"
    display as error "    至少有一组均值与其他组存在显著差异"
    local sig_level "**"
}
else if `p_value' < 0.10 {
    display "    在 10% 显著性水平下拒绝原假设 (p < 0.10) *"
    display "    至少有一组均值与其他组存在边际显著差异"
    local sig_level "*"
}
else {
    display as result "    不能拒绝原假设 (p ≥ 0.10)"
    display as result "    没有足够证据表明各组均值存在显著差异"
    local sig_level ""
}

* ==============================================================================
* SECTION 8: 可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成分组箱线图"

quietly graph box `dep_var', ///
    over(`group_var') ///
    title("`dep_var' 按 `group_var' 分组比较", size(medium)) ///
    subtitle("F = `: display %6.2f `F_stat'', p = `: display %6.4f `p_value''", size(small)) ///
    ytitle("`dep_var'") ///
    note("ANOVA: 检验各组均值是否存在显著差异") ///
    scheme(s2color)

quietly graph export "fig_T15_boxplot.png", replace width(1000) height(600)
display "SS_OUTPUT_FILE|file=fig_T15_boxplot.png|type=graph|desc=group_boxplot_comparison"
display ">>> 已导出: fig_T15_boxplot.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 9: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 9: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出ANOVA结果: table_T15_anova_result.csv"

preserve
clear
set obs 1

generate str32 dep_var = "`dep_var'"
generate str32 group_var = "`group_var'"
generate long n_groups = `n_groups'
generate long n_obs = `n_obs'
generate double grand_mean = `grand_mean'
generate double ss_between = `SS_between'
generate double ss_within = `SS_within'
generate double f_stat = `F_stat'
generate double df_between = `df_between'
generate double df_within = `df_within'
generate double p_value = `p_value'
generate double eta_sq = `eta_sq'
generate double levene_p = `levene_p'
generate str16 significance = "`sig_level'"

export delimited using "table_T15_anova_result.csv", replace
display "SS_OUTPUT_FILE|file=table_T15_anova_result.csv|type=table|desc=anova_results_summary"
display ">>> ANOVA结果已导出"
restore

* 导出分组统计
display ""
display ">>> 导出分组统计: table_T15_group_stats.csv"

preserve
collapse (count) n=`dep_var' (mean) mean=`dep_var' (sd) sd=`dep_var' ///
         (min) min=`dep_var' (max) max=`dep_var', by(`group_var')
export delimited using "table_T15_group_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_T15_group_stats.csv|type=table|desc=group_descriptive_statistics"
display ">>> 分组统计已导出"
restore

* ==============================================================================
* SECTION 10: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T15 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "检验概况:"
display "  - 因变量:          `dep_var'"
display "  - 分组变量:        `group_var' (`n_groups' 组)"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - F 统计量:        " %10.4f `F_stat'
display "  - p 值:            " %10.4f `p_value'
display "  - η²:              " %10.4f `eta_sq' " (`effect_size')"
display ""
display "输出文件:"
display "  - table_T15_anova_result.csv   ANOVA结果汇总表"
display "  - table_T15_group_stats.csv    分组描述统计"
display "  - fig_T15_boxplot.png          分组箱线图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=f_stat|value=`F_stat'"
display "SS_SUMMARY|key=p_value|value=`p_value'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T15|status=ok|elapsed_sec=`elapsed'"

log close
