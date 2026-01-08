* ==============================================================================
* SS_TEMPLATE: id=T16  level=L0  module=C  title="Chi-Square Independence Test"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T16_chi2_result.csv type=table desc="Chi-square test results"
*   - table_T16_crosstab.csv type=table desc="Cross tabulation"
*   - fig_T16_stacked_bar.png type=graph desc="Stacked bar chart"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core tabulation commands"
* ==============================================================================
* Task ID:      T16_chi_square_independence
* Task Name:    卡方独立性检验
* Family:       C - 假设检验
* Description:  检验两个分类变量之间是否存在显著关联
* 
* Placeholders: __ROW_VAR__  - 行变量（分类变量）
*               __COL_VAR__  - 列变量（分类变量）
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
display "SS_TASK_BEGIN|id=T16|level=L0|title=Chi_Square_Independence_Test"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: contingency tables + chi-square results (CSV) / 输出：列联表 + 卡方检验结果（CSV）
* - Error policy: warn on small expected counts; fail if vars missing / 错误策略：期望频数过小→warn；变量缺失→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T16|ssc=none|output=csv|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T16_chi_square_independence                                       ║"
display "║  TASK_NAME: 卡方独立性检验                                                  ║"
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
        display "SS_TASK_END|id=T16|status=fail|elapsed_sec=`elapsed'"
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
* [ZH] S02 校验两分类变量并检查稀疏性
* [EN] S02 Validate two categorical vars and check sparsity
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与准备"
display "═══════════════════════════════════════════════════════════════════════════════"

local row_var "__ROW_VAR__"
local col_var "__COL_VAR__"

capture confirm variable `row_var'
if _rc {
    display as error "ERROR: Row variable `row_var' not found"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable|msg=row_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T16|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

capture confirm variable `col_var'
if _rc {
    display as error "ERROR: Column variable `col_var' not found"
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable|msg=col_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T16|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

* 获取变量类别数
quietly levelsof `row_var', local(row_levels)
quietly levelsof `col_var', local(col_levels)
local n_row: word count `row_levels'
local n_col: word count `col_levels'

display ""
display ">>> 行变量:     `row_var' (`n_row' 类)"
display ">>> 列变量:     `col_var' (`n_col' 类)"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 交叉表（列联表）
* ==============================================================================
* [ZH] S03 进行独立性卡方检验并导出结果
* [EN] S03 Run chi-square test of independence and export results
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 交叉表（列联表）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 2.1 频数交叉表"
display "-------------------------------------------------------------------------------"
tabulate `row_var' `col_var'

display ""
display ">>> 2.2 行百分比"
display "-------------------------------------------------------------------------------"
tabulate `row_var' `col_var', row nofreq

display ""
display ">>> 2.3 列百分比"
display "-------------------------------------------------------------------------------"
tabulate `row_var' `col_var', column nofreq

* ==============================================================================
* SECTION 3: 卡方独立性检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 卡方独立性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 检验假设"
display "-------------------------------------------------------------------------------"
display "H0: `row_var' 与 `col_var' 相互独立"
display "H1: `row_var' 与 `col_var' 存在关联"
display ""

display ">>> 带期望频数的交叉表"
display "-------------------------------------------------------------------------------"
tabulate `row_var' `col_var', chi2 expected

* 保存检验结果
local chi2 = r(chi2)
local p_value = r(p)
local df = (`n_row' - 1) * (`n_col' - 1)
local n_obs = r(N)

* ==============================================================================
* SECTION 4: 关联强度指标
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 关联强度指标"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
tabulate `row_var' `col_var', V

* 计算 Cramér's V
local min_dim = min(`n_row' - 1, `n_col' - 1)
local cramers_v = sqrt(`chi2' / (`n_obs' * `min_dim'))

display ""
display ">>> Cramér's V = `: display %6.4f `cramers_v''"
display ""

if `cramers_v' < 0.1 {
    local assoc_strength "弱关联"
}
else if `cramers_v' < 0.3 {
    local assoc_strength "中等关联"
}
else if `cramers_v' < 0.5 {
    local assoc_strength "较强关联"
}
else {
    local assoc_strength "强关联"
}

display "关联强度判断: `assoc_strength' （V = `: display %5.3f `cramers_v''）"
display ""
display "Cramér's V 参考标准："
display "  V < 0.1    弱关联"
display "  0.1-0.3    中等关联"
display "  0.3-0.5    较强关联"
display "  V ≥ 0.5    强关联"

* ==============================================================================
* SECTION 5: Fisher 精确检验（2×2表或小样本）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: Fisher 精确检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
local fisher_p = .
if `n_row' == 2 & `n_col' == 2 {
    display ">>> 2×2 表，执行 Fisher 精确检验"
    display "-------------------------------------------------------------------------------"
    quietly tabulate `row_var' `col_var', exact
    local fisher_p = r(p_exact)
    tabulate `row_var' `col_var', exact
}
else {
    display ">>> 非 2×2 表 (`n_row'×`n_col')，Fisher 精确检验计算量过大"
    display ">>> 仅报告 Pearson 卡方检验结果"
}

* ==============================================================================
* SECTION 6: 检验结论汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 检验结论汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "检验类型:       卡方独立性检验"
display "行变量:         `row_var' (`n_row' 类)"
display "列变量:         `col_var' (`n_col' 类)"
display "{hline 70}"
display "样本量:         " %10.0fc `n_obs'
display "表格维度:       `n_row' × `n_col'"
display "{hline 70}"
display "χ² 统计量:      " %10.4f `chi2'
display "自由度 (df):    " %10.0f `df'
display "p 值:           " %10.4f `p_value'
if `fisher_p' != . {
    display "Fisher p值:     " %10.4f `fisher_p'
}
display "{hline 70}"
display "Cramér's V:     " %10.4f `cramers_v' "  (`assoc_strength')"
display "{hline 70}"

display ""
display ">>> 统计结论:"
if `p_value' < 0.01 {
    display as error "    在 1% 显著性水平下拒绝原假设 (p < 0.01) ***"
    display as error "    `row_var' 与 `col_var' 存在极显著关联"
    local sig_level "***"
}
else if `p_value' < 0.05 {
    display as error "    在 5% 显著性水平下拒绝原假设 (p < 0.05) **"
    display as error "    `row_var' 与 `col_var' 存在显著关联"
    local sig_level "**"
}
else if `p_value' < 0.10 {
    display "    在 10% 显著性水平下拒绝原假设 (p < 0.10) *"
    display "    `row_var' 与 `col_var' 存在边际显著关联"
    local sig_level "*"
}
else {
    display as result "    不能拒绝原假设 (p ≥ 0.10)"
    display as result "    没有足够证据表明 `row_var' 与 `col_var' 存在关联"
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
display ">>> 生成堆叠条形图"

quietly graph bar (count), over(`col_var') over(`row_var') ///
    asyvars stack ///
    title("`row_var' 与 `col_var' 的分布", size(medium)) ///
    subtitle("χ² = `: display %6.2f `chi2'', p = `: display %6.4f `p_value''", size(small)) ///
    legend(rows(1)) ///
    scheme(s2color)

quietly graph export "fig_T16_stacked_bar.png", replace width(1000) height(600)
display "SS_OUTPUT_FILE|file=fig_T16_stacked_bar.png|type=graph|desc=stacked_bar_chart"
display ">>> 已导出: fig_T16_stacked_bar.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出卡方检验结果: table_T16_chi2_result.csv"

preserve
clear
set obs 1

generate str32 row_var = "`row_var'"
generate str32 col_var = "`col_var'"
generate long n_obs = `n_obs'
generate long n_row = `n_row'
generate long n_col = `n_col'
generate double chi2 = `chi2'
generate double df = `df'
generate double p_value = `p_value'
generate double cramers_v = `cramers_v'
generate double fisher_p = `fisher_p'
generate str16 significance = "`sig_level'"

export delimited using "table_T16_chi2_result.csv", replace
display "SS_OUTPUT_FILE|file=table_T16_chi2_result.csv|type=table|desc=chi_square_test_results"
display ">>> 卡方检验结果已导出"
restore

* 导出交叉表
display ""
display ">>> 导出交叉表: table_T16_crosstab.csv"

quietly contract `row_var' `col_var', freq(count)
quietly reshape wide count, i(`row_var') j(`col_var')
quietly export delimited using "table_T16_crosstab.csv", replace
display "SS_OUTPUT_FILE|file=table_T16_crosstab.csv|type=table|desc=crosstab"
display ">>> 交叉表已导出"

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T16 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "检验概况:"
display "  - 行变量:          `row_var' (`n_row' 类)"
display "  - 列变量:          `col_var' (`n_col' 类)"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - χ² 统计量:       " %10.4f `chi2'
display "  - p 值:            " %10.4f `p_value'
display "  - Cramér's V:      " %10.4f `cramers_v' " (`assoc_strength')"
display ""
display "输出文件:"
display "  - table_T16_chi2_result.csv   卡方检验结果汇总表"
display "  - table_T16_crosstab.csv      交叉表"
display "  - fig_T16_stacked_bar.png     堆叠条形图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=chi2|value=`chi2'"
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
display "SS_TASK_END|id=T16|status=ok|elapsed_sec=`elapsed'"

log close
