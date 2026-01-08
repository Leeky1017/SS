* ==============================================================================
* SS_TEMPLATE: id=T18  level=L0  module=D  title="Multiple OLS Regression"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T18_reg_result.csv type=table desc="Regression results summary"
*   - table_T18_vif.csv type=table desc="VIF multicollinearity test"
*   - fig_T18_residuals.png type=graph desc="Residual diagnostics plot"
*   - table_T18_paper.rtf type=report desc="Publication-ready regression table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core regression commands"
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
display "SS_TASK_BEGIN|id=T18|level=L0|title=Multiple_OLS_Regression"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: regression results + diagnostics (CSV/PNG) / 输出：回归结果与诊断（CSV/PNG）
* - Error policy: fail on missing vars; warn on multicollinearity / 错误策略：变量缺失→fail；多重共线性提示→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T18|ssc=none|output=csv_png|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T18_ols_multiple                                                 ║"
display "║  TASK_NAME: 多元线性回归（Multiple OLS）                                    ║"
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
	        display "SS_TASK_END|id=T18|status=fail|elapsed_sec=`elapsed'"
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
* [ZH] S02 校验因变量与自变量列表（变量存在性/样本量）
* [EN] S02 Validate dep var and indep varlist (existence/sample size)
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
    display "SS_RC|code=111|cmd=confirm variable|msg=dep_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T18|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}

foreach var of varlist `indep_vars' {
    capture confirm variable `var'
	    if _rc {
	        display as error "ERROR: Independent variable `var' not found"
	        display "SS_RC|code=111|cmd=confirm variable|msg=indep_var_not_found|severity=fail"
	        timer off 1
	        quietly timer list 1
	        local elapsed = r(t1)
	        display "SS_METRIC|name=task_success|value=0"
	        display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
	        display "SS_TASK_END|id=T18|status=fail|elapsed_sec=`elapsed'"
	        log close
	        exit 111
	    }
	}

display ""
display ">>> 因变量 (Y):  `dep_var'"
display ">>> 自变量 (X):  `indep_vars'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 变量描述统计
* ==============================================================================
* [ZH] S03 估计多元 OLS 并输出诊断与结果表
* [EN] S03 Estimate multiple OLS and export diagnostics/results
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
local mean_vif = .
local max_vif = .
capture noisily estat vif
if _rc {
    display as error "WARNING: estat vif 失败 (rc=`_rc')"
    display "SS_RC|code=`=_rc'|cmd=estat vif|msg=vif_failed|severity=warn"
}
else {
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
}

display ""
display ">>> VIF 汇总"
display "    平均 VIF:   `: display %6.2f `mean_vif''"
display "    最大 VIF:   `: display %6.2f `max_vif''"
display ""
display "VIF 判断标准："
display "  VIF < 5:    无严重共线性 ✓"
display "  5 ≤ VIF < 10: 中度共线性，需关注"
display "  VIF ≥ 10:   严重共线性，需处理"

if !missing(`max_vif') {
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
}
else {
    display ""
    display as error "WARNING: VIF 结果不可用，跳过共线性阈值判断"
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
local bp_chi2 = .
local bp_p = .
local white_chi2 = .
local white_p = .
local reset_f = .
local reset_p = .

if missing(`rmse') | `rmse' == 0 {
    display as error "WARNING: 残差方差为0，跳过回归诊断检验（完全拟合/无残差波动）"
    display "SS_RC|code=0|cmd=estat hettest|msg=skipped_zero_residual_variance|severity=warn"
    display "SS_RC|code=0|cmd=estat imtest,white|msg=skipped_zero_residual_variance|severity=warn"
    display "SS_RC|code=0|cmd=estat ovtest|msg=skipped_zero_residual_variance|severity=warn"
}
else {
    quietly regress `dep_var' `indep_vars'
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

* 异方差检验（White）
display ""
display ">>> 7.3 异方差检验（White）"
display "-------------------------------------------------------------------------------"
if missing(`rmse') | `rmse' == 0 {
    * already handled above
}
else {
    quietly regress `dep_var' `indep_vars'
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

* 模型设定检验（Ramsey RESET）
display ""
display ">>> 7.4 模型设定检验（Ramsey RESET）"
display "-------------------------------------------------------------------------------"
if missing(`rmse') | `rmse' == 0 {
    * already handled above
}
else {
    quietly regress `dep_var' `indep_vars'
    capture noisily estat ovtest
    if _rc {
        display as error "WARNING: estat ovtest 失败 (rc=`_rc')"
        display "SS_RC|code=`=_rc'|cmd=estat ovtest|msg=reset_failed|severity=warn"
    }
    else {
        local reset_f = r(F)
        local reset_p = r(p)
    }
}

display ""
if !missing(`reset_p') & `reset_p' < 0.05 {
    display as error "WARNING: RESET检验显著（p < 0.05），可能存在遗漏变量或函数形式错误"
}
else if !missing(`reset_p') {
    display as result ">>> RESET检验不显著，模型设定较为合理 ✓"
}
else {
    display as error "WARNING: RESET检验不可用，跳过模型设定判断"
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

display ""
display ">>> 导出论文表格: table_T18_paper.rtf"

file open _rtf using "table_T18_paper.rtf", write replace
file write _rtf "{\\rtf1\\ansi\\deff0" _n
file write _rtf "{\\b Regression Results}\\par" _n
file write _rtf "Dependent variable: `dep_var'\\par" _n
file write _rtf "Independent variables: `indep_vars'\\par" _n
file write _rtf "Observations: `n_obs'\\par" _n
file write _rtf "R-squared: `: display %9.4f `r2''\\par" _n
file write _rtf "Adj. R-squared: `: display %9.4f `r2_adj''\\par" _n
file write _rtf "F-statistic: `: display %9.4f `F_stat''\\par" _n
file write _rtf "Prob > F: `: display %9.4f `F_p''\\par" _n
file write _rtf "\\par" _n
file write _rtf "Mean VIF: `: display %9.2f `mean_vif''\\par" _n
file write _rtf "BP p-value: `: display %9.4f `bp_p''\\par" _n
file write _rtf "White p-value: `: display %9.4f `white_p''\\par" _n
file write _rtf "RESET p-value: `: display %9.4f `reset_p''\\par" _n
file write _rtf "}" _n
file close _rtf

display "SS_OUTPUT_FILE|file=table_T18_paper.rtf|type=report|desc=publication_table"
display ">>> 论文表格已导出 ✓"


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
