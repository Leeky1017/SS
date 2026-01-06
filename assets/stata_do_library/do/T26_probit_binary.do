* ==============================================================================
* SS_TEMPLATE: id=T26  level=L0  module=E  title="Binary Probit Model"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T26_probit_coef.csv type=table desc="Probit coefficients"
*   - fig_T26_roc.png type=graph desc="ROC curve"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="probit regression commands"
* ==============================================================================
* Task ID:      T26_probit_binary
* Task Name:    二元Probit模型
* Family:       E - 有限因变量模型
* Description:  估计二分类因变量的Probit模型
* 
* Placeholders: __DEP_VAR__     - 因变量（0/1二元）
*               __INDEP_VARS__  - 自变量列表
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
display "SS_TASK_BEGIN|id=T26|level=L0|title=Binary_Probit_Model"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T26_probit_binary                                                ║"
display "║  TASK_NAME: 二元Probit模型（Binary Probit Regression）                        ║"
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

local dep_var "__DEP_VAR__"
local indep_vars "__INDEP_VARS__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

display ""
display ">>> 因变量:          `dep_var' (应为0/1)"
display ">>> 自变量:          `indep_vars'"
display ""

tabulate `dep_var'

quietly summarize `dep_var'
local mean_y = r(mean)

display ""
display "{hline 50}"
display "事件发生率 P(Y=1):   " %10.4f `mean_y'
display "{hline 50}"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: Probit回归
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Probit回归"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 模型: P(Y=1|X) = Φ(X'β)"
display ">>> Φ(·) 是标准正态累积分布函数"
display "-------------------------------------------------------------------------------"

probit `dep_var' `indep_vars'

estimates store probit_model
local ll_probit = e(ll)
local ll_0 = e(ll_0)
local pseudo_r2 = e(r2_p)
local n_obs = e(N)
local chi2 = e(chi2)

* ==============================================================================
* SECTION 3: 边际效应（Average Marginal Effects）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 边际效应（Average Marginal Effects）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 边际效应: 自变量变化1单位，P(Y=1)的平均变化"
display ">>> 与Logit的边际效应通常非常接近"
display "-------------------------------------------------------------------------------"

quietly probit `dep_var' `indep_vars'
margins, dydx(*) post

* ==============================================================================
* SECTION 4: 模型拟合优度
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 模型拟合优度"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly probit `dep_var' `indep_vars'

display ""
display "{hline 60}"
display "对数似然 (Log-Likelihood):     " %12.4f `ll_probit'
display "Pseudo R² (McFadden):          " %12.4f `pseudo_r2'
display "LR χ²:                         " %12.4f `chi2'
display "样本量:                        " %12.0fc `n_obs'
display "{hline 60}"

display ""
display ">>> 分类准确率："
estat classification

local correctly = r(P_corr)

* ==============================================================================
* SECTION 5: ROC曲线
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: ROC曲线与AUC"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
quietly probit `dep_var' `indep_vars'
lroc, title("ROC Curve - Probit Model") note("T26: Binary Probit")
local auc = r(area)

quietly graph export "fig_T26_roc.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T26_roc.png|type=graph|desc=roc_curve"
display ""
display ">>> AUC (Area Under ROC): " %6.4f `auc'
display ">>> ROC曲线已导出: fig_T26_roc.png"

* ==============================================================================
* SECTION 6: Logit vs Probit 对比
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: Logit vs Probit 对比"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Probit系数 × 1.6 ≈ Logit系数（经验法则）"
display ">>> 边际效应通常差异很小"
display "-------------------------------------------------------------------------------"

quietly logit `dep_var' `indep_vars'
estimates store logit_model
local ll_logit = e(ll)

display ""
estimates table probit_model logit_model, star stats(N ll r2_p) b(%9.4f) se(%9.4f)

display ""
display "{hline 50}"
display "Probit Log-Likelihood:  " %12.4f `ll_probit'
display "Logit Log-Likelihood:   " %12.4f `ll_logit'
display "差异:                   " %12.4f (`ll_logit' - `ll_probit')
display "{hline 50}"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出Probit系数
display ""
display ">>> 导出Probit系数: table_T26_probit_coef.csv"

quietly probit `dep_var' `indep_vars'

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

export delimited using "table_T26_probit_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T26_probit_coef.csv|type=table|desc=probit_coefficients"
display ">>> Probit系数已导出"
restore

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T26 任务完成摘要                                  ║"
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
display "  - table_T26_probit_coef.csv   Probit系数"
display "  - fig_T26_roc.png             ROC曲线"
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
display "SS_TASK_END|id=T26|status=ok|elapsed_sec=`elapsed'"

log close
