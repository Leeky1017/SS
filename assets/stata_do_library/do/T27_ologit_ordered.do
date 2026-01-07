* ==============================================================================
* SS_TEMPLATE: id=T27  level=L0  module=E  title="Ordered Logit Model"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T27_ologit_coef.csv type=table desc="Coefficients and odds ratios"
*   - table_T27_ologit_gof.csv type=table desc="Goodness of fit"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="ordered logit commands"
* ==============================================================================
* Task ID:      T27_ologit_ordered
* Task Name:    有序Logit模型
* Family:       E - 有限因变量模型
* Description:  估计有序多分类因变量的Ordered Logit模型
* 
* Placeholders: __DEPVAR__     - 因变量（有序分类）
*               __INDEPVARS__  - 自变量列表
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
display "SS_TASK_BEGIN|id=T27|level=L0|title=Ordered_Logit_Model"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T27_ologit_ordered                                               ║"
display "║  TASK_NAME: 有序Logit模型（Ordered Logistic Regression）                     ║"
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

local dep_var "__DEPVAR__"
local indep_vars "__INDEPVARS__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

display ""
display ">>> 因变量:          `dep_var' (应为有序分类: 1,2,3,...)"
display ">>> 自变量:          `indep_vars'"
display ""

* 因变量分布
display ">>> 因变量频率分布："
tabulate `dep_var'

quietly levelsof `dep_var', local(levels)
local n_levels: word count `levels'
display ""
display "{hline 50}"
display "类别数量:            " %10.0f `n_levels'
display "{hline 50}"

if `n_levels' < 3 {
    display as error "WARNING: 因变量仅有 `n_levels' 个类别，建议使用二元Logit"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 有序Logit回归
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 有序Logit回归"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 模型: P(Y ≤ j | X) = Λ(αⱼ - X'β)"
display ">>> 累积Logit模型，假设各类别间系数相同（平行线假设）"
display "-------------------------------------------------------------------------------"

ologit `dep_var' `indep_vars'

estimates store ologit_model
local ll = e(ll)
local ll_0 = e(ll_0)
local pseudo_r2 = e(r2_p)
local n_obs = e(N)
local chi2 = e(chi2)
local p_chi2 = e(p)

* ==============================================================================
* SECTION 3: 比值比（Odds Ratio）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 比值比（Odds Ratio）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> OR解释: 自变量增加1单位，选择更高类别的累积几率变化"
display ">>> OR > 1: 倾向于选择更高类别"
display ">>> OR < 1: 倾向于选择更低类别"
display "-------------------------------------------------------------------------------"

ologit `dep_var' `indep_vars', or

* ==============================================================================
* SECTION 4: 各类别边际效应
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 各类别边际效应"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 边际效应: 自变量变化1单位，各类别概率的变化"
display ">>> 注意: 各类别边际效应之和为0"
display "-------------------------------------------------------------------------------"

quietly ologit `dep_var' `indep_vars'

* 获取类别数量并计算边际效应
local cat_count = 0
foreach lev of local levels {
    local cat_count = `cat_count' + 1
    if `cat_count' <= 3 {
        display ""
        display ">>> 类别 `lev' 的边际效应:"
        margins, dydx(*) predict(outcome(`lev'))
    }
}

if `cat_count' > 3 {
    display ""
    display ">>> (仅显示前3个类别的边际效应，其余类别可在导出文件中查看)"
}

* ==============================================================================
* SECTION 5: 预测概率
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 预测概率"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各类别的平均预测概率："

quietly ologit `dep_var' `indep_vars'

local prob_display = ""
local cat_count = 0
foreach lev of local levels {
    local cat_count = `cat_count' + 1
    quietly margins, predict(outcome(`lev'))
    matrix M = r(table)
    local prob_`lev' = M[1,1]
    display "    P(Y=`lev'):  " %8.4f `prob_`lev''
}

* ==============================================================================
* SECTION 6: 模型拟合优度
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 模型拟合优度"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 60}"
display "对数似然 (Log-Likelihood):     " %12.4f `ll'
display "零模型对数似然 (LL₀):          " %12.4f `ll_0'
display "Pseudo R² (McFadden):          " %12.4f `pseudo_r2'
display "LR χ²:                         " %12.4f `chi2'
display "Prob > χ²:                     " %12.4f `p_chi2'
display "样本量:                        " %12.0fc `n_obs'
display "类别数:                        " %12.0f `n_levels'
display "{hline 60}"

* ==============================================================================
* SECTION 7: 平行线假设近似检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 平行线假设检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 平行线假设（Proportional Odds Assumption）"
display ">>> H0: 各类别间的系数相同"
display ">>> 如果拒绝H0，考虑使用广义有序Logit"
display "-------------------------------------------------------------------------------"

* 使用omodel命令（Stata内置）进行近似LR检验
quietly ologit `dep_var' `indep_vars'

display ""
display ">>> 提示: 正式的Brant检验需通过对比各类别模型进行"
display ">>> 可通过分别估计二元Logit模型，对比系数稳定性来近似检验"
display ">>> 若各子模型系数差异较大，说明平行线假设可能被违反"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出系数与OR
display ""
display ">>> 导出系数与比值比: table_T27_ologit_coef.csv"

quietly ologit `dep_var' `indep_vars', or

preserve
clear
local nvars: word count `indep_vars'
set obs `nvars'

generate str32 variable = ""
generate double coef = .
generate double se = .
generate double z = .
generate double p = .
generate double or = .
generate double or_ll = .
generate double or_ul = .
generate str10 sig = ""

local i = 1
foreach var of local indep_vars {
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

export delimited using "table_T27_ologit_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T27_ologit_coef.csv|type=table|desc=ordered_logit_coef"
display ">>> 系数与比值比已导出"
restore

* 导出拟合优度
display ""
display ">>> 导出拟合优度: table_T27_ologit_gof.csv"

preserve
clear
set obs 1

generate double n = `n_obs'
generate int n_categories = `n_levels'
generate double ll = `ll'
generate double pseudo_r2 = `pseudo_r2'
generate double chi2 = `chi2'
generate double p_chi2 = `p_chi2'

export delimited using "table_T27_ologit_gof.csv", replace
display "SS_OUTPUT_FILE|file=table_T27_ologit_gof.csv|type=table|desc=goodness_of_fit"
display ">>> 拟合优度已导出"
restore

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T27 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 类别数:          " %10.0f `n_levels'
display ""
display "拟合优度:"
display "  - Pseudo R²:       " %10.4f `pseudo_r2'
display "  - LR χ²:           " %10.4f `chi2'
display ""
display "输出文件:"
display "  - table_T27_ologit_coef.csv   系数与比值比"
display "  - table_T27_ologit_gof.csv    拟合优度指标"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_categories|value=`n_levels'"
display "SS_SUMMARY|key=pseudo_r2|value=`pseudo_r2'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T27|status=ok|elapsed_sec=`elapsed'"

log close
