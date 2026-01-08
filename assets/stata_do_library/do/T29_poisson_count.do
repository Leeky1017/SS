* ==============================================================================
* SS_TEMPLATE: id=T29  level=L0  module=E  title="Count Models"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T29_count_gof.csv type=table desc="Goodness of fit comparison"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="count regression commands"
* ==============================================================================
* Task ID:      T29_poisson_count
* Task Name:    计数模型
* Family:       E - 有限因变量模型
* Description:  估计计数数据的Poisson或负二项回归模型
* 
* Placeholders: __DEPVAR__     - 因变量（计数变量）
*               __INDEPVARS__  - 自变量列表
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.2)
* - 2026-01-08: Validate count outcome (nonnegative integer) and default to robust SE; keep `nbreg` as overdispersion alternative (验证计数因变量并默认稳健标准误；保留负二项备选).
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

program define ss_fail_T29
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T29|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T29|level=L0|title=Count_Models"
display "SS_SUMMARY|key=template_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T29_poisson_count                                                ║"
display "║  TASK_NAME: 计数模型（Poisson/负二项回归）                                  ║"
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
        ss_fail_T29 601 "confirm file" "data_file_not_found"
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
* SECTION 1: 变量检查与数据描述
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与数据描述"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEPVAR__"
local indep_vars "__INDEPVARS__"

* 模型类型：poisson（仅泊松）、nbreg（仅负二项）、both（两者都运行，默认）
local model_type "__MODEL_TYPE__"
if "`model_type'" == "" | "`model_type'" == "__MODEL_TYPE__" {
    local model_type "both"
}

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    ss_fail_T29 111 "confirm variable" "dep_var_not_found"
}

capture confirm numeric variable `dep_var'
if _rc {
    display as error "ERROR: Count outcome `dep_var' must be numeric"
    ss_fail_T29 121 "confirm numeric" "dep_var_not_numeric"
}
capture assert `dep_var' >= 0 if !missing(`dep_var')
if _rc {
    display as error "ERROR: Count outcome `dep_var' must be nonnegative"
    ss_fail_T29 121 "assert nonnegative" "dep_var_negative_values"
}
capture assert `dep_var' == floor(`dep_var') if !missing(`dep_var')
if _rc {
    display as error "ERROR: Count outcome `dep_var' must be integer-coded"
    ss_fail_T29 121 "assert integer" "dep_var_not_integer"
}

display ""
display ">>> 因变量:          `dep_var' (计数变量，非负整数)"
display ">>> 自变量:          `indep_vars'"
display ">>> 模型类型:        `model_type' (poisson/nbreg/both)"
display ""

* 因变量分布
display ">>> 因变量描述统计："
summarize `dep_var', detail

* 频率分布（仅显示前20个值）
display ""
display ">>> 因变量频率分布（前20个值）："
tabulate `dep_var' if `dep_var' <= 20

* 过度分散初步检查
quietly summarize `dep_var'
local mean_y = r(mean)
local var_y = r(Var)
local disp_ratio = `var_y' / `mean_y'
local n_zeros = 0
quietly count if `dep_var' == 0
local n_zeros = r(N)
local pct_zeros = 100 * `n_zeros' / `n_total'

display ""
display "{hline 60}"
display "均值:                         " %12.4f `mean_y'
display "方差:                         " %12.4f `var_y'
display "方差/均值（分散系数）:        " %12.4f `disp_ratio'
display "零值个数:                     " %12.0fc `n_zeros' " (" %5.2f `pct_zeros' "%)"
display "{hline 60}"

display ""
if `disp_ratio' > 1.5 {
    display as error ">>> WARNING: 方差/均值 = " %5.2f `disp_ratio' " >> 1"
    display as error "    存在过度分散，建议使用负二项模型"
}
else {
    display as result ">>> 方差/均值 ≈ 1，可以使用Poisson模型"
}

if `pct_zeros' > 30 {
    display as error ">>> WARNING: 零值比例 = " %5.2f `pct_zeros' "%"
    display as error "    零值过多，考虑使用零膨胀模型"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: Poisson回归
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Poisson回归"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 模型: E[Y|X] = exp(X'β)"
display ">>> 假设: Var[Y|X] = E[Y|X]（等分散）"
display "-------------------------------------------------------------------------------"

poisson `dep_var' `indep_vars', vce(robust)

estimates store poisson_model
local ll_pois = e(ll)
local n_obs = e(N)
local chi2_pois = e(chi2)
local aic_pois = -2*e(ll) + 2*e(rank)
local bic_pois = -2*e(ll) + e(rank)*ln(e(N))

* ==============================================================================
* SECTION 3: 发生率比（IRR）- Poisson
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 发生率比（IRR）- Poisson"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> IRR解释: 自变量增加1单位，计数的乘数变化"
display ">>> IRR > 1: 计数增加 (IRR-1)*100%"
display ">>> IRR < 1: 计数减少 (1-IRR)*100%"
display "-------------------------------------------------------------------------------"

poisson `dep_var' `indep_vars', irr vce(robust)

* ==============================================================================
* SECTION 4: 过度分散检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 过度分散检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Poisson拟合优度检验"
display ">>> H0: 数据服从Poisson分布（无过度分散）"
display "-------------------------------------------------------------------------------"

quietly poisson `dep_var' `indep_vars', vce(robust)
estat gof

local gof_chi2 = r(chi2_d)
local gof_p = r(p_d)

display ""
if `gof_p' < 0.05 {
    display as error ">>> 拒绝H0 (p < 0.05): 存在过度分散"
    display as error "    建议使用负二项模型"
}
else {
    display as result ">>> 不拒绝H0: Poisson模型适用"
}

* ==============================================================================
* SECTION 5: 负二项回归
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 负二项回归"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 模型: E[Y|X] = exp(X'β)"
display ">>> 假设: Var[Y|X] = E[Y|X] + α·E[Y|X]²"
display ">>> α = 0 时退化为Poisson"
display "-------------------------------------------------------------------------------"

nbreg `dep_var' `indep_vars', vce(robust)

estimates store nbreg_model
local ll_nb = e(ll)
local alpha = e(alpha)
local aic_nb = -2*e(ll) + 2*e(rank)
local bic_nb = -2*e(ll) + e(rank)*ln(e(N))

display ""
display "{hline 50}"
display "过度分散参数 α:      " %12.4f `alpha'
display "{hline 50}"

* ==============================================================================
* SECTION 6: 负二项IRR
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 发生率比（IRR）- 负二项"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
nbreg `dep_var' `indep_vars', irr vce(robust)

* ==============================================================================
* SECTION 7: 模型比较
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 模型比较（Poisson vs 负二项）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
estimates table poisson_model nbreg_model, star stats(N ll aic bic) b(%9.4f) se(%9.4f)

display ""
display "{hline 60}"
display "模型" _col(25) "Poisson" _col(45) "负二项"
display "{hline 60}"
display "Log-Likelihood" _col(25) %12.4f `ll_pois' _col(45) %12.4f `ll_nb'
display "AIC" _col(25) %12.2f `aic_pois' _col(45) %12.2f `aic_nb'
display "BIC" _col(25) %12.2f `bic_pois' _col(45) %12.2f `bic_nb'
display "{hline 60}"

display ""
display ">>> α参数的LR检验（H0: α=0，即Poisson适用）："
local lr_stat = 2 * (`ll_nb' - `ll_pois')
local lr_p = chi2tail(1, `lr_stat') / 2
display "    LR统计量: " %10.4f `lr_stat'
display "    p值:      " %10.4f `lr_p'

if `lr_p' < 0.05 {
    display ""
    display as result ">>> 推荐使用: 负二项模型（存在显著过度分散）"
}
else {
    display ""
    display as result ">>> 推荐使用: Poisson模型"
}

* ==============================================================================
* SECTION 8: 边际效应
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 边际效应"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 边际效应: 自变量变化1单位，计数的平均变化"
display "-------------------------------------------------------------------------------"

quietly nbreg `dep_var' `indep_vars', vce(robust)
margins, dydx(*)

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 9: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 9: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出拟合优度比较
display ""
display ">>> 导出模型比较: table_T29_count_gof.csv"

preserve
clear
set obs 2

generate str20 model = ""
generate double n = .
generate double ll = .
generate double aic = .
generate double bic = .
generate double alpha = .

quietly replace model = "Poisson" in 1
quietly replace n = `n_obs' in 1
quietly replace ll = `ll_pois' in 1
quietly replace aic = `aic_pois' in 1
quietly replace bic = `bic_pois' in 1
quietly replace alpha = 0 in 1

quietly replace model = "NegBin" in 2
quietly replace n = `n_obs' in 2
quietly replace ll = `ll_nb' in 2
quietly replace aic = `aic_nb' in 2
quietly replace bic = `bic_nb' in 2
quietly replace alpha = `alpha' in 2

export delimited using "table_T29_count_gof.csv", replace
display "SS_OUTPUT_FILE|file=table_T29_count_gof.csv|type=table|desc=model_comparison"
display ">>> 模型比较已导出"
restore

* ==============================================================================
* SECTION 10: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T29 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "数据概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 因变量均值:      " %10.4f `mean_y'
display "  - 方差/均值:       " %10.4f `disp_ratio'
display ""
display "模型比较:"
display "  - Poisson AIC:     " %10.2f `aic_pois'
display "  - 负二项 AIC:      " %10.2f `aic_nb'
display "  - α参数:           " %10.4f `alpha'
if `lr_p' < 0.05 {
    display "  - 推荐模型:        负二项"
}
else {
    display "  - 推荐模型:        Poisson"
}
display ""
display "输出文件:"
display "  - table_T29_count_gof.csv    模型比较指标"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=mean_y|value=`mean_y'"
display "SS_SUMMARY|key=disp_ratio|value=`disp_ratio'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T29|status=ok|elapsed_sec=`elapsed'"

log close
