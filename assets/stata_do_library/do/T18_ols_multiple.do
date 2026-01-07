* ==============================================================================
* SS_TEMPLATE: id=T18  level=L0  module=D  title="Multiple OLS Regression"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T18_reg_result.csv type=table desc="Regression results summary"
*   - table_T18_vif.csv type=table desc="VIF multicollinearity test"
*   - fig_T18_residuals.png type=graph desc="Residual diagnostics plot"
*   - table_T18_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core regression commands"
*   - estout source=ssc purpose="publication-quality tables (optional)"
* ==============================================================================
* Task ID:      T18_ols_multiple
* Task Name:    多元线性回归（Multiple OLS）
* Family:       D - 线性回归
* Description:  估计多个自变量对因变量的线性关系
* 
* Placeholders: __DEPVAR__     - 因变量
*               __INDEPVARS__  - 自变量列表（空格分隔）
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands)
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
display "SS_TASK_BEGIN|id=T18|level=L0|title=Multiple_OLS_Regression"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* 检查 esttab (可选依赖，用于论文级表格)
local has_esttab = 0
capture which esttab
if _rc {
    display "SS_DEP_CHECK|pkg=estout|source=ssc|status=missing"
    display ">>> estout 未安装，将使用基础 CSV 导出"
} 
else {
    display "SS_DEP_CHECK|pkg=estout|source=ssc|status=ok"
    local has_esttab = 1
}


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T18_ols_multiple                                                 ║"
display "║  TASK_NAME: 多元线性回归（Multiple OLS）                                    ║"
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

foreach var of varlist `indep_vars' {
    capture confirm variable `var'
    if _rc {
        display as error "ERROR: Independent variable `var' not found"
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
}

display ""
display ">>> 因变量 (Y):  `dep_var'"
display ">>> 自变量 (X):  `indep_vars'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 变量描述统计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 变量描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
summarize `dep_var' `indep_vars'

* ==============================================================================
* SECTION 3: 相关性矩阵
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 相关性矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
pwcorr `dep_var' `indep_vars', sig star(0.05)

* ==============================================================================
* SECTION 4: 多元线性回归
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 多元线性回归"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 回归模型"
display "-------------------------------------------------------------------------------"
display "`dep_var' = β₀ + β₁X₁ + β₂X₂ + ... + βₖXₖ + ε"
display ""

regress `dep_var' `indep_vars'

* 保存回归结果
local r2 = e(r2)
local r2_adj = e(r2_a)
local F_stat = e(F)
local F_p = Ftail(e(df_m), e(df_r), e(F))
local n_obs = e(N)
local k = e(df_m)
local rmse = e(rmse)

* ==============================================================================
* SECTION 5: 标准化系数（Beta）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 标准化系数 (Beta)"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 用于比较各变量的相对重要性"
display "-------------------------------------------------------------------------------"

regress `dep_var' `indep_vars', beta

* ==============================================================================
* SECTION 6: 多重共线性检验（VIF）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 多重共线性检验 (VIF)"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
quietly regress `dep_var' `indep_vars'
estat vif

* 保存VIF结果
matrix vif_mat = r(vif)
local mean_vif = 0
local max_vif = 0
local n_vars = rowsof(vif_mat)
forvalues i = 1/`n_vars' {
    local v = vif_mat[`i', 1]
    local mean_vif = `mean_vif' + `v'
    if `v' > `max_vif' {
        local max_vif = `v'
    }
}
local mean_vif = `mean_vif' / `n_vars'

display ""
display ">>> VIF 汇总"
display "    平均 VIF:   `: display %6.2f `mean_vif''"
display "    最大 VIF:   `: display %6.2f `max_vif''"
display ""
display "VIF 判断标准："
display "  VIF < 5:    无严重共线性 ✓"
display "  5 ≤ VIF < 10: 中度共线性，需关注"
display "  VIF ≥ 10:   严重共线性，需处理"

if `max_vif' >= 10 {
    display ""
    display as error "WARNING: 存在严重多重共线性（VIF ≥ 10）"
}
else if `max_vif' >= 5 {
    display ""
    display as error "WARNING: 存在中度多重共线性（5 ≤ VIF < 10）"
}
else {
    display ""
    display as result ">>> 无严重多重共线性 ✓"
}

* ==============================================================================
* SECTION 7: 回归诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 回归诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly regress `dep_var' `indep_vars'

* 生成预测值和残差
quietly predict _yhat, xb
quietly predict _resid, residuals
quietly predict _rstd, rstandard

display ""
display ">>> 7.1 残差统计"
display "-------------------------------------------------------------------------------"
summarize _resid, detail

* 异方差检验（Breusch-Pagan）
display ""
display ">>> 7.2 异方差检验（Breusch-Pagan）"
display "-------------------------------------------------------------------------------"
quietly regress `dep_var' `indep_vars'
estat hettest

quietly estat hettest
local bp_chi2 = r(chi2)
local bp_p = r(p)

* 异方差检验（White）
display ""
display ">>> 7.3 异方差检验（White）"
display "-------------------------------------------------------------------------------"
quietly regress `dep_var' `indep_vars'
estat imtest, white

quietly estat imtest, white
local white_chi2 = r(chi2)
local white_p = r(p)

* 模型设定检验（Ramsey RESET）
display ""
display ">>> 7.4 模型设定检验（Ramsey RESET）"
display "-------------------------------------------------------------------------------"
quietly regress `dep_var' `indep_vars'
estat ovtest

quietly estat ovtest
local reset_f = r(F)
local reset_p = r(p)

display ""
if `reset_p' < 0.05 {
    display as error "WARNING: RESET检验显著（p < 0.05），可能存在遗漏变量或函数形式错误"
}
else {
    display as result ">>> RESET检验不显著，模型设定较为合理 ✓"
}

* ==============================================================================
* SECTION 8: 回归结果汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 回归结果汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "因变量:         `dep_var'"
display "自变量:         `indep_vars'"
display "{hline 70}"
display "样本量:                    " %10.0fc `n_obs'
display "自变量个数:                " %10.0f `k'
display "R²:                        " %10.4f `r2'
display "调整 R²:                   " %10.4f `r2_adj'
display "RMSE:                      " %10.4f `rmse'
display "{hline 70}"
display "F 统计量:                  " %10.4f `F_stat'
display "Prob > F:                  " %10.4f `F_p'
display "{hline 70}"
display "Breusch-Pagan χ²:          " %10.4f `bp_chi2' "  (p = " %6.4f `bp_p' ")"
display "White χ²:                  " %10.4f `white_chi2' "  (p = " %6.4f `white_p' ")"
display "RESET F:                   " %10.4f `reset_f' "  (p = " %6.4f `reset_p' ")"
display "Mean VIF:                  " %10.2f `mean_vif'
display "{hline 70}"

if `bp_p' < 0.05 | `white_p' < 0.05 {
    display ""
    display as error ">>> 存在异方差，建议使用稳健标准误 (T19_ols_robust_se)"
}

* ==============================================================================
* SECTION 9: 可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 9: 可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成残差诊断图"

quietly twoway (scatter _rstd _yhat, msize(small) mcolor(navy%50)) ///
       (function y=0, range(_yhat) lcolor(red) lpattern(dash)) ///
       (function y=2, range(_yhat) lcolor(gray) lpattern(dot)) ///
       (function y=-2, range(_yhat) lcolor(gray) lpattern(dot)), ///
    title("标准化残差 vs 拟合值", size(medium)) ///
    subtitle("R² = `: display %5.3f `r2''", size(small)) ///
    xtitle("拟合值") ///
    ytitle("标准化残差") ///
    legend(off) ///
    note("虚线: ±2标准差参考线") ///
    scheme(s2color)

quietly graph export "fig_T18_residuals.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T18_residuals.png|type=graph|desc=residual_diagnostics_plot"
display ">>> 已导出: fig_T18_residuals.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 10: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 10: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出回归结果: table_T18_reg_result.csv"

* 导出系数表
quietly regress `dep_var' `indep_vars'

preserve
clear
local nvars: word count `indep_vars'
local nrows = `nvars' + 1
set obs `nrows'

generate str32 variable = ""
generate double coef = .
generate double se = .
generate double t = .
generate double p = .
generate str10 sig = ""

local i = 1
foreach var in `indep_vars' {
    quietly replace variable = "`var'" in `i'
    quietly replace coef = _b[`var'] in `i'
    quietly replace se = _se[`var'] in `i'
    local t_val = _b[`var'] / _se[`var']
    local p_val = 2 * ttail(e(df_r), abs(`t_val'))
    quietly replace t = `t_val' in `i'
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
quietly replace variable = "_cons" in `i'
quietly replace coef = _b[_cons] in `i'
quietly replace se = _se[_cons] in `i'

export delimited using "table_T18_reg_result.csv", replace
display "SS_OUTPUT_FILE|file=table_T18_reg_result.csv|type=table|desc=regression_results_summary"
display ">>> 回归结果已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T18_paper.rtf"
    
    esttab using "table_T18_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T18_paper.rtf|type=table|desc=publication_table"
    display ">>> 论文级表格已导出 ✓"
}
else {
    display ""
    display ">>> 跳过论文级表格 (estout 未安装)"
}


* 导出VIF结果
display ""
display ">>> 导出VIF结果: table_T18_vif.csv"

quietly regress `dep_var' `indep_vars'
quietly estat vif
matrix vif_mat = r(vif)

preserve
clear
local nvars = rowsof(vif_mat)
set obs `nvars'

generate str32 variable = ""
generate double vif = .
generate double tolerance = .

local varnames: rownames vif_mat
local i = 1
foreach var of local varnames {
    quietly replace variable = "`var'" in `i'
    quietly replace vif = vif_mat[`i', 1] in `i'
    quietly replace tolerance = 1 / vif_mat[`i', 1] in `i'
    local i = `i' + 1
}

export delimited using "table_T18_vif.csv", replace
display "SS_OUTPUT_FILE|file=table_T18_vif.csv|type=table|desc=vif_results"
display ">>> VIF结果已导出"
restore

* 清理临时变量
drop _yhat _resid _rstd

* ==============================================================================
* SECTION 11: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T18 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "回归概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - R²:              " %10.4f `r2'
display "  - 调整 R²:         " %10.4f `r2_adj'
display "  - F 统计量:        " %10.4f `F_stat'
display ""
display "诊断结果:"
display "  - 平均 VIF:        " %10.2f `mean_vif'
display "  - BP异方差 p:      " %10.4f `bp_p'
display "  - RESET p:         " %10.4f `reset_p'
display ""
display "输出文件:"
display "  - table_T18_reg_result.csv   回归系数表"
display "  - table_T18_vif.csv          VIF共线性检验"
display "  - fig_T18_residuals.png      残差诊断图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=r_squared|value=`r2'"
display "SS_SUMMARY|key=f_stat|value=`F_stat'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T18|status=ok|elapsed_sec=`elapsed'"

log close
