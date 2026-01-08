* ==============================================================================
* SS_TEMPLATE: id=T25  level=L0  module=E  title="Binary Logit Model"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T25_logit_coef.csv type=table desc="Coefficients and odds ratios"
*   - table_T25_logit_gof.csv type=table desc="Goodness of fit metrics"
*   - fig_T25_roc.png type=graph desc="ROC curve"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="logit regression commands"
* ==============================================================================
* Task ID:      T25_logit_binary
* Task Name:    二元Logit模型
* Family:       E - 有限因变量模型
* Description:  估计二分类因变量的Logit模型
* 
* Placeholders: __DEPVAR__     - 因变量（0/1二元）
*               __INDEPVARS__  - 自变量列表（空格分隔）
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.2)
* - 2026-01-08: Confirm dependent variable is binary (0/1) before estimation (确认因变量为二元 0/1).
* - 2026-01-08: Prefer robust variance estimator for model diagnostics stability (优先使用稳健方差估计以增强稳健性).
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 {
    display "SS_RC|code=`=_rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

program define ss_fail_T25
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T25|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T25|level=L0|title=Binary_Logit_Model"
display "SS_SUMMARY|key=template_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T25_logit_binary                                                 ║"
display "║  TASK_NAME: 二元Logit模型（Binary Logistic Regression）                      ║"
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
        ss_fail_T25 601 "confirm file" "data_file_not_found"
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

local dep_var "__DEPVAR__"
local indep_vars "__INDEPVARS__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    ss_fail_T25 111 "confirm variable" "dep_var_not_found"
}

* Best practice: enforce binary 0/1 coding for logit
capture assert inlist(`dep_var', 0, 1) if !missing(`dep_var')
if _rc {
    display as error "ERROR: Dependent variable `dep_var' must be coded as 0/1 for binary logit"
    ss_fail_T25 121 "assert inlist" "dep_var_not_binary_01"
}

display ""
display ">>> 因变量:          `dep_var' (应为0/1)"
display ">>> 自变量:          `indep_vars'"
display ""

* 因变量分布
display ">>> 因变量频率分布："
tabulate `dep_var'

quietly summarize `dep_var'
local mean_y = r(mean)
local n_1 = r(sum)
local n_0 = `n_total' - `n_1'

display ""
display "{hline 50}"
display "Y = 0 (基准类):      " %10.0fc `n_0' " (" %5.2f 100*(1-`mean_y') "%)"
display "Y = 1 (事件类):      " %10.0fc `n_1' " (" %5.2f 100*`mean_y' "%)"
display "事件发生率:          " %10.4f `mean_y'
display "{hline 50}"

* 检查是否为二元变量
quietly levelsof `dep_var', local(levels)
local n_levels: word count `levels'
if `n_levels' != 2 {
    display as error "WARNING: 因变量不是二元变量，有 `n_levels' 个取值"
}

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
summarize `dep_var' `indep_vars'

* ==============================================================================
* SECTION 3: Logit回归（系数）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: Logit回归（系数）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 模型: logit(`dep_var') = β₀ + β'X"
display ">>> 系数解释: 对数几率 ln(p/(1-p)) 的变化"
display "-------------------------------------------------------------------------------"

logit `dep_var' `indep_vars', vce(robust)

estimates store logit_model
local ll = e(ll)
local ll_0 = e(ll_0)
local pseudo_r2 = e(r2_p)
local n_obs = e(N)
local chi2 = e(chi2)
local p_chi2 = e(p)

* ==============================================================================
* SECTION 4: 比值比（Odds Ratio）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 比值比（Odds Ratio）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> OR 解释："
display "    OR > 1: 该变量增加1单位，事件发生几率增加 (OR-1)*100%"
display "    OR < 1: 该变量增加1单位，事件发生几率减少 (1-OR)*100%"
display "    OR = 1: 无影响"
display "-------------------------------------------------------------------------------"

logit `dep_var' `indep_vars', or vce(robust)

* ==============================================================================
* SECTION 5: 边际效应（Average Marginal Effects）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 边际效应（Average Marginal Effects）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 边际效应解释: 自变量变化1单位，概率P(Y=1)的平均变化"
display ">>> 这是最直观的效应解释方式"
display "-------------------------------------------------------------------------------"

quietly logit `dep_var' `indep_vars', vce(robust)
margins, dydx(*) post

* 保存边际效应
matrix ME = r(table)

* ==============================================================================
* SECTION 6: 模型拟合优度
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 模型拟合优度"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly logit `dep_var' `indep_vars', vce(robust)

display ""
display "{hline 60}"
display "对数似然 (Log-Likelihood):     " %12.4f `ll'
display "零模型对数似然 (LL₀):          " %12.4f `ll_0'
display "Pseudo R² (McFadden):          " %12.4f `pseudo_r2'
display "LR χ²:                         " %12.4f `chi2'
display "Prob > χ²:                     " %12.4f `p_chi2'
display "样本量:                        " %12.0fc `n_obs'
display "{hline 60}"

display ""
display ">>> 分类准确率："
estat classification

* 获取分类统计
local sensitivity = r(P_p1)
local specificity = r(P_n0)
local correctly = r(P_corr)

* ==============================================================================
* SECTION 7: ROC曲线与AUC
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: ROC曲线与AUC"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> ROC曲线衡量模型的区分能力"
display ">>> AUC = 0.5: 无区分能力；AUC = 1.0: 完美区分"
display "-------------------------------------------------------------------------------"

quietly logit `dep_var' `indep_vars', vce(robust)
lroc, title("ROC Curve - Logit Model") note("T25: Binary Logit")
local auc = r(area)

quietly graph export "fig_T25_roc.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T25_roc.png|type=graph|desc=roc_curve"
display ""
display ">>> AUC (Area Under ROC): " %6.4f `auc'
display ">>> ROC曲线已导出: fig_T25_roc.png"

* AUC 解释
display ""
if `auc' >= 0.9 {
    display as result ">>> 模型区分能力: 优秀 (AUC ≥ 0.9)"
}
else if `auc' >= 0.8 {
    display as result ">>> 模型区分能力: 良好 (0.8 ≤ AUC < 0.9)"
}
else if `auc' >= 0.7 {
    display as result ">>> 模型区分能力: 可接受 (0.7 ≤ AUC < 0.8)"
}
else if `auc' >= 0.6 {
    display as error ">>> 模型区分能力: 较弱 (0.6 ≤ AUC < 0.7)"
}
else {
    display as error ">>> 模型区分能力: 差 (AUC < 0.6)"
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出系数和OR
display ""
display ">>> 导出系数与比值比: table_T25_logit_coef.csv"

quietly logit `dep_var' `indep_vars', or vce(robust)

preserve
clear
local nvars: word count `indep_vars'
local nrows = `nvars' + 1
set obs `nrows'

generate str32 variable = ""
generate double coef = .
generate double se = .
generate double z = .
generate double p = .
generate double or = .
generate double or_ll = .
generate double or_ul = .
generate str10 sig = ""

local varlist "`indep_vars' _cons"
local i = 1
foreach var of local varlist {
    quietly replace variable = "`var'" in `i'
    quietly replace coef = _b[`var'] in `i'
    quietly replace se = _se[`var'] in `i'
    local z_val = _b[`var'] / _se[`var']
    local p_val = 2 * (1 - normal(abs(`z_val')))
    quietly replace z = `z_val' in `i'
    quietly replace p = `p_val' in `i'
    quietly replace or = exp(_b[`var']) in `i'
    quietly replace or_ll = exp(_b[`var'] - 1.96*_se[`var']) in `i'
    quietly replace or_ul = exp(_b[`var'] + 1.96*_se[`var']) in `i'
    if `p_val' < 0.01 {
        quietly replace sig = "***" in `i'
    }
    else if `p_val' < 0.05 {
        quietly replace sig = "**" in `i'
    }
    else if `p_val' < 0.10 {
        quietly replace sig = "*" in `i'
    }
    local i = `i' + 1
}

export delimited using "table_T25_logit_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T25_logit_coef.csv|type=table|desc=coefficients_and_odds_ratios"
display ">>> 系数与比值比已导出"
restore

* 导出拟合优度
display ""
display ">>> 导出拟合优度指标: table_T25_logit_gof.csv"

preserve
clear
set obs 1

generate double n = `n_obs'
generate double ll = `ll'
generate double ll_0 = `ll_0'
generate double pseudo_r2 = `pseudo_r2'
generate double chi2 = `chi2'
generate double p_chi2 = `p_chi2'
generate double auc = `auc'
generate double correctly_classified = `correctly'

export delimited using "table_T25_logit_gof.csv", replace
display "SS_OUTPUT_FILE|file=table_T25_logit_gof.csv|type=table|desc=goodness_of_fit"
display ">>> 拟合优度指标已导出"
restore

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T25 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 事件发生率:      " %10.4f `mean_y'
display ""
display "拟合优度:"
display "  - Pseudo R²:       " %10.4f `pseudo_r2'
display "  - AUC:             " %10.4f `auc'
display "  - 正确分类率:      " %10.4f `correctly' "%"
display ""
display "输出文件:"
display "  - table_T25_logit_coef.csv    系数与比值比"
display "  - table_T25_logit_gof.csv     拟合优度指标"
display "  - fig_T25_roc.png             ROC曲线"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=pseudo_r2|value=`pseudo_r2'"
display "SS_SUMMARY|key=auc|value=`auc'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T25|status=ok|elapsed_sec=`elapsed'"

log close
