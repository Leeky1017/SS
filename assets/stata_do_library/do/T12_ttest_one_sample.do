* ==============================================================================
* SS_TEMPLATE: id=T12  level=L0  module=C  title="One Sample T-Test"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T12_ttest_result.csv type=table desc="T-test results summary"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core statistical commands"
* ==============================================================================
* Task ID:      T12_ttest_one_sample
* Task Name:    单样本t检验
* Family:       C - 假设检验
* Description:  检验单个变量的均值是否等于指定的理论值
* 
* Placeholders: __TEST_VAR__    - 要检验的变量
*               __NULL_VALUE__  - 理论值/基准值
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
display "SS_TASK_BEGIN|id=T12|level=L0|title=One_Sample_T_Test"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T12_ttest_one_sample                                             ║"
display "║  TASK_NAME: 单样本t检验                                                    ║"
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

local test_var "__TEST_VAR__"
local null_value = __NULL_VALUE__

capture confirm variable `test_var'
if _rc {
    display as error "ERROR: Variable `test_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm numeric variable `test_var'
if _rc {
    display as error "ERROR: Variable `test_var' is not numeric"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

display ""
display ">>> 检验变量:   `test_var'"
display ">>> 原假设值:   `null_value'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 描述性统计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 描述性统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
summarize `test_var', detail

quietly summarize `test_var', detail
local n_obs = r(N)
local mean_val = r(mean)
local sd_val = r(sd)
local se_val = `sd_val' / sqrt(`n_obs')
local min_val = r(min)
local max_val = r(max)
local skew_val = r(skewness)
local kurt_val = r(kurtosis)

* ==============================================================================
* SECTION 3: 正态性检验（t检验前提假设）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 正态性检验（t检验前提假设）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
local sw_p = .

if `n_obs' <= 2000 {
    display ">>> Shapiro-Wilk 正态性检验"
    display "-------------------------------------------------------------------------------"
    quietly swilk `test_var'
    local sw_p = r(p)
    display "W 统计量:       " %10.6f r(W)
    display "p 值:           " %10.6f `sw_p'
    
    if `sw_p' < 0.05 {
        display ""
        display as error "WARNING: 拒绝正态性假设（p < 0.05）"
        display as error "建议: 大样本时t检验仍稳健，或考虑非参数检验（符号检验）"
    }
    else {
        display ""
        display as result ">>> 不能拒绝正态性假设（p ≥ 0.05）✓"
    }
}
else {
    display ">>> 样本量 > 2000，根据中心极限定理，t检验稳健"
}

* ==============================================================================
* SECTION 4: 单样本 t 检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 单样本 t 检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 检验假设"
display "-------------------------------------------------------------------------------"
display "H0: μ = `null_value'  （原假设：总体均值等于 `null_value'）"
display "H1: μ ≠ `null_value'  （备择假设：总体均值不等于 `null_value'，双侧）"
display ""

ttest `test_var' == `null_value'

* 保存检验结果
local t_stat = r(t)
local p_two = r(p)
local p_left = r(p_l)
local p_right = r(p_u)
local df = r(df_t)

* ==============================================================================
* SECTION 5: 置信区间
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 均值置信区间"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
ci means `test_var', level(95)

quietly ci means `test_var', level(95)
local ci_lb = r(lb)
local ci_ub = r(ub)

display ""
display ">>> 95% 置信区间: [`: display %9.4f `ci_lb'', `: display %9.4f `ci_ub'']"

if `null_value' >= `ci_lb' & `null_value' <= `ci_ub' {
    display ">>> 原假设值 `null_value' 落在置信区间内 → 不能拒绝 H0"
}
else {
    display as error ">>> 原假设值 `null_value' 落在置信区间外 → 拒绝 H0"
}

* ==============================================================================
* SECTION 6: 效应量计算
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 效应量（Cohen's d）"
display "═══════════════════════════════════════════════════════════════════════════════"

local effect_d = (`mean_val' - `null_value') / `sd_val'
local abs_d = abs(`effect_d')

display ""
display "Cohen's d = (样本均值 - 原假设值) / 标准差"
display "          = (`: display %9.4f `mean_val'' - `null_value') / `: display %9.4f `sd_val''"
display "          = " %9.4f `effect_d'
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
display ""
display "效应量参考标准（Cohen, 1988）："
display "  |d| < 0.2    小效应"
display "  0.2 ≤ |d| < 0.5  小到中效应"
display "  0.5 ≤ |d| < 0.8  中效应"
display "  |d| ≥ 0.8    大效应"

* ==============================================================================
* SECTION 7: 检验结论汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 检验结论汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "检验类型:       单样本 t 检验"
display "检验变量:       `test_var'"
display "原假设值:       `null_value'"
display "{hline 70}"
display "样本量 (N):     " %10.0fc `n_obs'
display "样本均值:       " %10.4f `mean_val'
display "标准差:         " %10.4f `sd_val'
display "标准误:         " %10.4f `se_val'
display "{hline 70}"
display "t 统计量:       " %10.4f `t_stat'
display "自由度 (df):    " %10.0f `df'
display "p 值（双侧）:   " %10.4f `p_two'
display "p 值（左侧）:   " %10.4f `p_left' "  (H1: μ < `null_value')"
display "p 值（右侧）:   " %10.4f `p_right' "  (H1: μ > `null_value')"
display "{hline 70}"
display "Cohen's d:      " %10.4f `effect_d' "  (`effect_size')"
display "95% CI:         [`: display %9.4f `ci_lb'', `: display %9.4f `ci_ub'']"
display "{hline 70}"

display ""
display ">>> 统计结论（双侧检验）:"
if `p_two' < 0.01 {
    display as error "    在 1% 显著性水平下拒绝原假设 (p < 0.01) ***"
    display as error "    样本均值与 `null_value' 存在极显著差异"
    local sig_level "***"
}
else if `p_two' < 0.05 {
    display as error "    在 5% 显著性水平下拒绝原假设 (p < 0.05) **"
    display as error "    样本均值与 `null_value' 存在显著差异"
    local sig_level "**"
}
else if `p_two' < 0.10 {
    display "    在 10% 显著性水平下拒绝原假设 (p < 0.10) *"
    display "    样本均值与 `null_value' 存在边际显著差异"
    local sig_level "*"
}
else {
    display as result "    不能拒绝原假设 (p ≥ 0.10)"
    display as result "    没有足够证据表明样本均值与 `null_value' 存在显著差异"
    local sig_level ""
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出检验结果: table_T12_ttest_result.csv"

preserve
clear
set obs 1

generate str32 test_type = "one_sample_ttest"
generate str32 variable = "`test_var'"
generate double null_value = `null_value'
generate long n = `n_obs'
generate double mean = `mean_val'
generate double sd = `sd_val'
generate double se = `se_val'
generate double t_stat = `t_stat'
generate double df = `df'
generate double p_two_sided = `p_two'
generate double p_left = `p_left'
generate double p_right = `p_right'
generate double ci_lower = `ci_lb'
generate double ci_upper = `ci_ub'
generate double cohens_d = `effect_d'
generate str16 significance = "`sig_level'"

export delimited using "table_T12_ttest_result.csv", replace
display "SS_OUTPUT_FILE|file=table_T12_ttest_result.csv|type=table|desc=ttest_results"
display ">>> 检验结果已导出"
restore

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T12 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "检验概况:"
display "  - 检验变量:        `test_var'"
display "  - 原假设值:        `null_value'"
display "  - 样本均值:        " %10.4f `mean_val'
display "  - t 统计量:        " %10.4f `t_stat'
display "  - p 值（双侧）:    " %10.4f `p_two'
display "  - 效应量:          " %10.4f `effect_d' " (`effect_size')"
display ""
display "输出文件:"
display "  - table_T12_ttest_result.csv    检验结果汇总表"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=t_stat|value=`t_stat'"
display "SS_SUMMARY|key=p_value|value=`p_two'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T12|status=ok|elapsed_sec=`elapsed'"

log close
