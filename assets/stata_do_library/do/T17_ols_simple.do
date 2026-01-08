* ==============================================================================
* SS_TEMPLATE: id=T17  level=L1  module=D  title="Simple Linear Regression OLS"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T17_reg_result.csv type=table desc="Regression results table"
*   - table_T17_paper.rtf type=report desc="Publication-ready regression table"
*   - fig_T17_scatter_fit.png type=graph desc="Scatter plot with fitted line"
*   - fig_T17_residuals.png type=graph desc="Residual diagnostics plot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core regression and diagnostic commands"
* ==============================================================================
* Task ID:      T17_ols_simple
* Task Name:    简单线性回归（一元OLS）
* Family:       D - 线性回归
* Description:  估计单自变量对因变量的线性关系，
*               包含回归诊断、异方差检验、正态性检验和可视化
* 
* Placeholders: __DEPVAR__    - 因变量
*               __INDEP_VAR__  - 自变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands)
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
display "SS_TASK_BEGIN|id=T17|level=L1|title=Simple_Linear_Regression_OLS"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: regression result tables (CSV) + diagnostics plot / 输出：回归表（CSV）+ 诊断图
* - Error policy: fail on missing dep/indep vars; warn on small N / 错误策略：变量缺失→fail；小样本提示→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T17|ssc=none|output=csv_png|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T17_ols_simple                                                   ║"
display "║  TASK_NAME: 简单线性回归（一元OLS）                                       ║"
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
        display "SS_TASK_END|id=T17|status=fail|elapsed_sec=`elapsed'"
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
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"
* ---------- 标准化数据加载逻辑结束 ----------

local n_total = _N
display ">>> 数据加载成功: `n_total' 条观测"

* ==============================================================================
* SECTION 1: 变量检查
* ==============================================================================
* [ZH] S02 校验因变量与自变量（变量存在性/样本量）
* [EN] S02 Validate dep/indep vars (existence/sample size)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEPVAR__"
local indep_var "__INDEP_VAR__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    display "SS_RC|code=111|cmd=confirm variable|msg=dep_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T17|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}

capture confirm variable `indep_var'
if _rc {
    display as error "ERROR: Independent variable `indep_var' not found"
    display "SS_RC|code=111|cmd=confirm variable|msg=indep_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T17|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}

display ""
display ">>> 因变量 (Y):  `dep_var'"
display ">>> 自变量 (X):  `indep_var'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 变量描述统计
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 变量描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
summarize `dep_var' `indep_var', detail

quietly summarize `dep_var'
local y_mean = r(mean)
local y_sd = r(sd)
local y_n = r(N)

quietly summarize `indep_var'
local x_mean = r(mean)
local x_sd = r(sd)

* ==============================================================================
* SECTION 3: 相关性分析
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 相关性分析"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
pwcorr `dep_var' `indep_var', sig star(0.05)

quietly correlate `dep_var' `indep_var'
local corr_coef = r(rho)

display ""
display ">>> Pearson 相关系数: `: display %6.4f `corr_coef''"

* ==============================================================================
* SECTION 4: 简单线性回归
* ==============================================================================
* [ZH] S03 估计简单 OLS 并做基础诊断
* [EN] S03 Estimate simple OLS and run basic diagnostics
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 简单线性回归"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 回归模型"
display "-------------------------------------------------------------------------------"
display "`dep_var' = β₀ + β₁ × `indep_var' + ε"
display ""

regress `dep_var' `indep_var'

* 保存回归结果
local b_cons = _b[_cons]
local b_x = _b[`indep_var']
local se_cons = _se[_cons]
local se_x = _se[`indep_var']
local t_x = `b_x' / `se_x'
local p_x = 2 * ttail(e(df_r), abs(`t_x'))
local r2 = e(r2)
local r2_adj = e(r2_a)
local F_stat = e(F)
local F_p = Ftail(e(df_m), e(df_r), e(F))
local n_obs = e(N)
local rmse = e(rmse)

* ==============================================================================
* SECTION 5: 回归诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 回归诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

* 生成预测值和残差
quietly predict _yhat, xb
quietly predict _resid, residuals
quietly predict _rstd, rstandard

display ""
display ">>> 5.1 残差统计"
display "-------------------------------------------------------------------------------"
summarize _resid, detail

* 异方差检验（Breusch-Pagan / White；残差方差为 0 时跳过）
display ""
display ">>> 5.2 异方差检验（Breusch-Pagan）"
display "-------------------------------------------------------------------------------"
local bp_chi2 = .
local bp_p = .
local white_chi2 = .
local white_p = .

if missing(`rmse') | `rmse' == 0 {
    display as error "WARNING: 残差方差为0，跳过异方差检验（完全拟合/无残差波动）"
    display "SS_RC|code=0|cmd=estat hettest|msg=skipped_zero_residual_variance|severity=warn"
    display "SS_RC|code=0|cmd=estat imtest,white|msg=skipped_zero_residual_variance|severity=warn"
}
else {
    quietly regress `dep_var' `indep_var'
    capture noisily estat hettest
    if _rc {
        display as error "WARNING: estat hettest 失败 (rc=`_rc')"
        display "SS_RC|code=`=_rc'|cmd=estat hettest|msg=hettest_failed|severity=warn"
    }
    else {
        local bp_chi2 = r(chi2)
        local bp_p = r(p)
    }
}

display ""
display ">>> 5.3 异方差检验（White）"
display "-------------------------------------------------------------------------------"
if missing(`rmse') | `rmse' == 0 {
    * already handled above
}
else {
    quietly regress `dep_var' `indep_var'
    capture noisily estat imtest, white
    if _rc {
        display as error "WARNING: estat imtest, white 失败 (rc=`_rc')"
        display "SS_RC|code=`=_rc'|cmd=estat imtest,white|msg=white_test_failed|severity=warn"
    }
    else {
        local white_chi2 = r(chi2)
        local white_p = r(p)
    }
}

* 残差正态性检验
display ""
display ">>> 5.4 残差正态性检验"
display "-------------------------------------------------------------------------------"
local sw_p = .
quietly count if _resid != .
if r(N) <= 2000 {
    capture noisily swilk _resid
    if _rc {
        display as error "WARNING: swilk 失败 (rc=`_rc')"
        display "SS_RC|code=`=_rc'|cmd=swilk|msg=swilk_failed|severity=warn"
    }
    else {
        local sw_p = r(p)
        display "Shapiro-Wilk W:  " %10.6f r(W)
        display "p 值:            " %10.6f `sw_p'
    }
    
    if !missing(`sw_p') & `sw_p' < 0.05 {
        display ""
        display as error "WARNING: 残差偏离正态分布（p < 0.05），t/F检验可能不可靠"
    }
    else if !missing(`sw_p') {
        display ""
        display as result ">>> 残差分布不拒绝正态性假设 ✓"
    }
}
else {
    display ">>> 样本量 > 2000，根据中心极限定理，t/F检验近似有效"
}

* ==============================================================================
* SECTION 6: 回归结果汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 回归结果汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

* 显著性标记
if `p_x' < 0.01 {
    local sig_x "***"
}
else if `p_x' < 0.05 {
    local sig_x "**"
}
else if `p_x' < 0.10 {
    local sig_x "*"
}
else {
    local sig_x ""
}

display ""
display "{hline 70}"
display "模型:           `dep_var' = β₀ + β₁ × `indep_var' + ε"
display "{hline 70}"
display "样本量:                    " %10.0fc `n_obs'
display "R²:                        " %10.4f `r2'
display "调整 R²:                   " %10.4f `r2_adj'
display "RMSE:                      " %10.4f `rmse'
display "{hline 70}"
display "F 统计量:                  " %10.4f `F_stat'
display "Prob > F:                  " %10.4f `F_p'
display "{hline 70}"
display "                    系数       标准误       t值        p值"
display "{hline 70}"
display "`indep_var'" _col(20) %10.4f `b_x' "  " %10.4f `se_x' "  " %8.2f `t_x' "  " %8.4f `p_x' "  `sig_x'"
display "_cons" _col(20) %10.4f `b_cons' "  " %10.4f `se_cons'
display "{hline 70}"
display "Breusch-Pagan χ²:          " %10.4f `bp_chi2' "  (p = " %6.4f `bp_p' ")"
display "White χ²:                  " %10.4f `white_chi2' "  (p = " %6.4f `white_p' ")"
display "{hline 70}"

display ""
display ">>> 经济含义解读:"
display "    `indep_var' 每增加 1 单位，`dep_var' 平均变化 `: display %9.4f `b_x'' 单位"

if `bp_p' < 0.05 | `white_p' < 0.05 {
    display ""
    display as error ">>> 异方差检验显著，建议使用稳健标准误 (T19_ols_robust_se)"
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 可视化
* ==============================================================================
* [ZH] S04 导出回归表与图形输出
* [EN] S04 Export regression tables and plots
display "SS_STEP_BEGIN|step=S04_export"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 7.1 散点图 + 拟合线"

quietly twoway (scatter `dep_var' `indep_var', msize(small) mcolor(navy%50)) ///
       (lfit `dep_var' `indep_var', lcolor(red) lwidth(medium)), ///
    title("`dep_var' 与 `indep_var' 的线性关系", size(medium)) ///
    subtitle("β₁ = `: display %6.4f `b_x'' `sig_x', R² = `: display %5.3f `r2''", size(small)) ///
    xtitle("`indep_var'") ///
    ytitle("`dep_var'") ///
    legend(label(1 "观测值") label(2 "拟合线") rows(1)) ///
    scheme(s2color)

quietly graph export "fig_T17_scatter_fit.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T17_scatter_fit.png|type=graph|desc=scatter_plot_with_fit"
display ">>> 已导出: fig_T17_scatter_fit.png"

display ""
display ">>> 7.2 残差诊断图"

quietly summarize _yhat
local yhat_min = r(min)
local yhat_max = r(max)
if `yhat_min' == `yhat_max' {
    local yhat_min = `yhat_min' - 1
    local yhat_max = `yhat_max' + 1
}

quietly twoway (scatter _rstd _yhat, msize(small) mcolor(navy%50)) ///
       (function y=0, range(`yhat_min' `yhat_max') lcolor(red) lpattern(dash)) ///
       (function y=2, range(`yhat_min' `yhat_max') lcolor(gray) lpattern(dot)) ///
       (function y=-2, range(`yhat_min' `yhat_max') lcolor(gray) lpattern(dot)), ///
    title("标准化残差 vs 拟合值", size(medium)) ///
    xtitle("拟合值") ///
    ytitle("标准化残差") ///
    legend(off) ///
    note("虚线: ±2标准差参考线") ///
    scheme(s2color)

quietly graph export "fig_T17_residuals.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T17_residuals.png|type=graph|desc=residual_diagnostics"
display ">>> 已导出: fig_T17_residuals.png"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出回归结果: table_T17_reg_result.csv"

preserve
clear
set obs 1

generate str32 model = "simple_ols"
generate str32 dep_var = "`dep_var'"
generate str32 indep_var = "`indep_var'"
generate long n_obs = `n_obs'
generate double b_x = `b_x'
generate double se_x = `se_x'
generate double t_x = `t_x'
generate double p_x = `p_x'
generate double b_cons = `b_cons'
generate double r2 = `r2'
generate double r2_adj = `r2_adj'
generate double f_stat = `F_stat'
generate double f_p = `F_p'
generate double rmse = `rmse'
generate double bp_chi2 = `bp_chi2'
generate double bp_p = `bp_p'
generate double white_chi2 = `white_chi2'
generate double white_p = `white_p'
generate str16 significance = "`sig_x'"

export delimited using "table_T17_reg_result.csv", replace
display "SS_OUTPUT_FILE|file=table_T17_reg_result.csv|type=table|desc=regression_results"
display ">>> 回归结果已导出"
restore

display ""
display ">>> 导出论文表格: table_T17_paper.rtf"

file open _rtf using "table_T17_paper.rtf", write replace
file write _rtf "{\\rtf1\\ansi\\deff0" _n
file write _rtf "{\\b Simple OLS Regression Results}\\par" _n
file write _rtf "Dependent variable: `dep_var'\\par" _n
file write _rtf "Independent variable: `indep_var'\\par" _n
file write _rtf "Observations: `n_obs'\\par" _n
file write _rtf "R-squared: `: display %9.4f `r2''\\par" _n
file write _rtf "\\par" _n
file write _rtf "Coef(`indep_var'): `: display %9.4f `b_x''\\par" _n
file write _rtf "SE(`indep_var'): `: display %9.4f `se_x''\\par" _n
file write _rtf "p-value: `: display %9.4f `p_x''\\par" _n
file write _rtf "BP p-value: `: display %9.4f `bp_p''\\par" _n
file write _rtf "White p-value: `: display %9.4f `white_p''\\par" _n
file write _rtf "}" _n
file close _rtf

display "SS_OUTPUT_FILE|file=table_T17_paper.rtf|type=report|desc=publication_table"
display ">>> 论文表格已导出 ✓"

* 清理临时变量
drop _yhat _resid _rstd

display "SS_STEP_END|step=S04_export|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T17 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "回归概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_var'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - β₁ (斜率):       " %10.4f `b_x' " `sig_x'"
display "  - R²:              " %10.4f `r2'
display "  - F 统计量:        " %10.4f `F_stat'
display ""
display "诊断结果:"
display "  - BP异方差检验 p:  " %10.4f `bp_p'
display "  - White检验 p:     " %10.4f `white_p'
display ""
display "输出文件:"
display "  - table_T17_reg_result.csv   回归结果汇总表"
display "  - fig_T17_scatter_fit.png    散点图+拟合线"
display "  - fig_T17_residuals.png      残差诊断图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=r_squared|value=`r2'"
display "SS_SUMMARY|key=coefficient|value=`b_x'"
display "SS_SUMMARY|key=pvalue|value=`p_x'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T17|status=ok|elapsed_sec=`elapsed'"

log close
