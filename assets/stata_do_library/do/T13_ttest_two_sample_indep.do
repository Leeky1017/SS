* ==============================================================================
* SS_TEMPLATE: id=T13  level=L0  module=C  title="Two Sample Independent T-Test"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T13_ttest_result.csv type=table desc="T-test results summary"
*   - fig_T13_boxplot.png type=graph desc="Group boxplot comparison"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core statistical commands"
* ==============================================================================
* Task ID:      T13_ttest_two_sample_indep
* Task Name:    独立样本t检验（两组均值比较）
* Family:       C - 假设检验
* Description:  比较两组独立样本的均值是否存在显著差异
* 
* Placeholders: __TEST_VAR__   - 要检验的连续变量
*               __GROUP_VAR__  - 分组变量（0/1或两类别）
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
display "SS_TASK_BEGIN|id=T13|level=L0|title=Two_Sample_Independent_T_Test"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: two-sample t-test result table (CSV) / 输出：双样本 t 检验结果表（CSV）
* - Error policy: fail on missing group var; warn on unequal variances / 错误策略：分组变量缺失→fail；方差不齐提示→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T13|ssc=none|output=csv|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T13_ttest_two_sample_indep                                       ║"
display "║  TASK_NAME: 独立样本t检验（两组均值比较）                                  ║"
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
        display "SS_TASK_END|id=T13|status=fail|elapsed_sec=`elapsed'"
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
* [ZH] S02 校验检验变量与分组变量（组别/样本量）
* [EN] S02 Validate test var and group var (groups/sample sizes)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与准备"
display "═══════════════════════════════════════════════════════════════════════════════"

local test_var "__TEST_VAR__"
local group_var "__GROUP_VAR__"

capture confirm variable `test_var'
if _rc {
    display as error "ERROR: Test variable `test_var' not found"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable|msg=test_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T13|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

capture confirm numeric variable `test_var'
if _rc {
    display as error "ERROR: Test variable `test_var' is not numeric"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric|msg=test_var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T13|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=T13|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

* 检查分组变量取值
quietly levelsof `group_var', local(groups)
local n_groups: word count `groups'

if `n_groups' != 2 {
    display as error "ERROR: Group variable must have exactly 2 levels, found `n_groups'"
    display "SS_RC|code=198|cmd=levelsof|msg=group_var_not_two_levels|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T13|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 198
}

local group1: word 1 of `groups'
local group2: word 2 of `groups'

display ""
display ">>> 检验变量:   `test_var'"
display ">>> 分组变量:   `group_var'"
display ">>> 组别取值:   `group1' vs `group2'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 分组描述统计
* ==============================================================================
* [ZH] S03 进行双样本 t 检验并导出结果
* [EN] S03 Run two-sample t-test and export results
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 分组描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
tabstat `test_var', by(`group_var') statistics(n mean sd min p25 p50 p75 max) columns(statistics)

* 保存各组统计量
quietly summarize `test_var' if `group_var' == `group1'
local n1 = r(N)
local mean1 = r(mean)
local sd1 = r(sd)

quietly summarize `test_var' if `group_var' == `group2'
local n2 = r(N)
local mean2 = r(mean)
local sd2 = r(sd)

local diff = `mean1' - `mean2'

* ==============================================================================
* SECTION 3: 方差齐性检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 方差齐性检验（Levene检验）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> H0: 两组方差相等"
display ">>> H1: 两组方差不等"
display "-------------------------------------------------------------------------------"

robvar `test_var', by(`group_var')

local levene_p = r(p_2)

display ""
if `levene_p' < 0.05 {
    display as error ">>> Levene检验 p = `: display %6.4f `levene_p'' < 0.05"
    display as error ">>> 拒绝方差齐性假设，应使用 Welch t 检验"
    local use_welch = 1
}
else {
    display as result ">>> Levene检验 p = `: display %6.4f `levene_p'' ≥ 0.05"
    display as result ">>> 不能拒绝方差齐性假设，可使用普通 t 检验 ✓"
    local use_welch = 0
}

* ==============================================================================
* SECTION 4: 独立样本 t 检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 独立样本 t 检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 4.1 普通t检验（假设方差相等）
display ""
display ">>> 4.1 Student's t 检验（假设方差相等）"
display "-------------------------------------------------------------------------------"

ttest `test_var', by(`group_var')

local t_equal = r(t)
local p_equal = r(p)
local df_equal = r(df_t)
local se_equal = r(se)

* 4.2 Welch t检验（不假设方差相等）
display ""
display ">>> 4.2 Welch t 检验（不假设方差相等，推荐）"
display "-------------------------------------------------------------------------------"

ttest `test_var', by(`group_var') unequal

local t_welch = r(t)
local p_welch = r(p)
local df_welch = r(df_t)
local se_welch = r(se)

* 选择主要报告的结果
if `use_welch' {
    local t_main = `t_welch'
    local p_main = `p_welch'
    local df_main = `df_welch'
    local test_type "Welch t检验"
}
else {
    local t_main = `t_equal'
    local p_main = `p_equal'
    local df_main = `df_equal'
    local test_type "Student's t检验"
}

* ==============================================================================
* SECTION 5: 效应量（Cohen's d）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 效应量（Cohen's d）"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算合并标准差
local pooled_sd = sqrt(((`n1'-1)*`sd1'^2 + (`n2'-1)*`sd2'^2) / (`n1' + `n2' - 2))
local cohens_d = `diff' / `pooled_sd'
local abs_d = abs(`cohens_d')

display ""
display "Cohen's d = (M1 - M2) / SD_pooled"
display "          = (`: display %9.4f `mean1'' - `: display %9.4f `mean2'') / `: display %9.4f `pooled_sd''"
display "          = " %9.4f `cohens_d'
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
* SECTION 6: 检验结论汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 检验结论汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "检验类型:       独立样本 t 检验"
display "检验变量:       `test_var'"
display "分组变量:       `group_var'"
display "{hline 70}"
display "组1 (`group1'):  N=" %6.0fc `n1' "  Mean=" %9.4f `mean1' "  SD=" %9.4f `sd1'
display "组2 (`group2'):  N=" %6.0fc `n2' "  Mean=" %9.4f `mean2' "  SD=" %9.4f `sd2'
display "均值差异:       " %10.4f `diff' "  (组1 - 组2)"
display "{hline 70}"
display "Levene方差齐性检验 p值:  " %10.4f `levene_p'
display "{hline 70}"
display "Student's t检验: t=" %8.4f `t_equal' ", df=" %6.1f `df_equal' ", p=" %8.4f `p_equal'
display "Welch t检验:     t=" %8.4f `t_welch' ", df=" %6.1f `df_welch' ", p=" %8.4f `p_welch'
display "{hline 70}"
display "推荐使用:       `test_type'"
display "Cohen's d:      " %10.4f `cohens_d' "  (`effect_size')"
display "{hline 70}"

display ""
display ">>> 统计结论（双侧检验）:"
if `p_main' < 0.01 {
    display as error "    在 1% 显著性水平下拒绝原假设 (p < 0.01) ***"
    display as error "    两组均值存在极显著差异"
    local sig_level "***"
}
else if `p_main' < 0.05 {
    display as error "    在 5% 显著性水平下拒绝原假设 (p < 0.05) **"
    display as error "    两组均值存在显著差异"
    local sig_level "**"
}
else if `p_main' < 0.10 {
    display "    在 10% 显著性水平下拒绝原假设 (p < 0.10) *"
    display "    两组均值存在边际显著差异"
    local sig_level "*"
}
else {
    display as result "    不能拒绝原假设 (p ≥ 0.10)"
    display as result "    没有足够证据表明两组均值存在显著差异"
    local sig_level ""
}

* ==============================================================================
* SECTION 7: 可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成分组箱线图"

quietly graph box `test_var', ///
    over(`group_var') ///
    title("`test_var' 按 `group_var' 分组比较", size(medium)) ///
    subtitle("均值差异 = `: display %9.3f `diff'' (p = `: display %6.4f `p_main'')", size(small)) ///
    ytitle("`test_var'") ///
    note("箱体: 四分位距; 中线: 中位数; 圆点: 异常值") ///
    scheme(s2color)

quietly graph export "fig_T13_boxplot.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T13_boxplot.png|type=graph|desc=group_boxplot_comparison"
display ">>> 已导出: fig_T13_boxplot.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出检验结果: table_T13_ttest_result.csv"

preserve
clear
set obs 1

generate str32 test_type = "two_sample_ttest"
generate str32 test_var = "`test_var'"
generate str32 group_var = "`group_var'"
generate long n1 = `n1'
generate long n2 = `n2'
generate double mean1 = `mean1'
generate double mean2 = `mean2'
generate double sd1 = `sd1'
generate double sd2 = `sd2'
generate double mean_diff = `diff'
generate double levene_p = `levene_p'
generate double t_equal = `t_equal'
generate double p_equal = `p_equal'
generate double t_welch = `t_welch'
generate double p_welch = `p_welch'
generate double cohens_d = `cohens_d'
generate str16 significance = "`sig_level'"

export delimited using "table_T13_ttest_result.csv", replace
display "SS_OUTPUT_FILE|file=table_T13_ttest_result.csv|type=table|desc=ttest_results"
display ">>> 检验结果已导出"
restore

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T13 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "检验概况:"
display "  - 检验变量:        `test_var'"
display "  - 分组变量:        `group_var'"
display "  - 组1均值:         " %10.4f `mean1'
display "  - 组2均值:         " %10.4f `mean2'
display "  - 均值差异:        " %10.4f `diff'
display "  - t 统计量:        " %10.4f `t_main'
display "  - p 值:            " %10.4f `p_main'
display "  - Cohen's d:       " %10.4f `cohens_d' " (`effect_size')"
display ""
display "输出文件:"
display "  - table_T13_ttest_result.csv    检验结果汇总表"
display "  - fig_T13_boxplot.png           分组箱线图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_total|value=`=`n1'+`n2''"
display "SS_SUMMARY|key=mean_diff|value=`diff'"
display "SS_SUMMARY|key=p_value|value=`p_main'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`=`n1'+`n2''"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T13|status=ok|elapsed_sec=`elapsed'"

log close
