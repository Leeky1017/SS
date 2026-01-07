* ==============================================================================
* SS_TEMPLATE: id=T19  level=L0  module=D  title="OLS with Robust SE"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T19_reg_robust.csv type=table desc="Robust regression results"
*   - table_T19_se_comparison.csv type=table desc="SE comparison table"
*   - fig_T19_residuals.png type=graph desc="Residual diagnostics plot"
*   - table_T19_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
*   - estout source=ssc purpose="publication-quality tables (optional)" purpose="core regression commands"
* ==============================================================================
* Task ID:      T19_ols_robust_se
* Task Name:    稳健标准误OLS
* Family:       D - 线性回归
* Description:  使用异方差稳健标准误的OLS回归
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
display "SS_TASK_BEGIN|id=T19|level=L0|title=OLS_with_Robust_SE"
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
display "║  TASK_ID: T19_ols_robust_se                                                ║"
display "║  TASK_NAME: 稳健标准误OLS（Huber-White Robust SE）                         ║"
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
display ">>> 因变量 (Y):  `dep_var'"
display ">>> 自变量 (X):  `indep_vars'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 异方差检验
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 异方差检验"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly regress `dep_var' `indep_vars'

display ""
display ">>> 2.1 Breusch-Pagan 检验"
display "-------------------------------------------------------------------------------"
estat hettest

quietly estat hettest
local bp_chi2 = r(chi2)
local bp_p = r(p)

display ""
display ">>> 2.2 White 检验"
display "-------------------------------------------------------------------------------"
quietly regress `dep_var' `indep_vars'
estat imtest, white

quietly estat imtest, white
local white_chi2 = r(chi2)
local white_p = r(p)

display ""
if `bp_p' < 0.05 | `white_p' < 0.05 {
    display as error ">>> 存在异方差（至少一个检验 p < 0.05）"
    display as error ">>> 建议使用稳健标准误"
}
else {
    display as result ">>> 未检测到显著异方差，但稳健SE仍是安全选择 ✓"
}

* ==============================================================================
* SECTION 3: 普通 OLS 回归（基准）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 普通 OLS 回归（对比基准）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
regress `dep_var' `indep_vars'

* 保存结果
local r2 = e(r2)
local r2_adj = e(r2_a)
local F_stat = e(F)
local n_obs = e(N)
matrix V_ols = e(V)

* ==============================================================================
* SECTION 4: 稳健标准误 OLS（HC1）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 稳健标准误 OLS（HC1 - Huber-White）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> vce(robust) 使用 Huber-White 稳健标准误"
display "-------------------------------------------------------------------------------"

regress `dep_var' `indep_vars', vce(robust)

matrix V_robust = e(V)
local F_robust = e(F)

* ==============================================================================
* SECTION 5: 标准误对比
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 标准误对比（OLS vs Robust）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "变量" _col(20) "OLS SE" _col(35) "Robust SE" _col(50) "比率" _col(60) "变化"
display "{hline 70}"

* 准备导出数据
tempfile se_compare
preserve
clear

local nvars: word count `indep_vars'
local nrows = `nvars' + 1
set obs `nrows'

generate str32 variable = ""
generate double se_ols = .
generate double se_robust = .
generate double ratio = .
generate str10 direction = ""

local varlist "`indep_vars' _cons"
local i = 1
foreach var of local varlist {
    quietly replace variable = "`var'" in `i'
    
    local se_o = sqrt(V_ols[`i', `i'])
    local se_r = sqrt(V_robust[`i', `i'])
    local rat = `se_r' / `se_o'
    
    quietly replace se_ols = `se_o' in `i'
    quietly replace se_robust = `se_r' in `i'
    quietly replace ratio = `rat' in `i'
    
    if `rat' > 1.05 {
        quietly replace direction = "↑" in `i'
        display "`var'" _col(20) %9.4f `se_o' _col(35) %9.4f `se_r' _col(50) %6.3f `rat' _col(60) "↑ 更保守"
    }
    else if `rat' < 0.95 {
        quietly replace direction = "↓" in `i'
        display "`var'" _col(20) %9.4f `se_o' _col(35) %9.4f `se_r' _col(50) %6.3f `rat' _col(60) "↓ 更精确"
    }
    else {
        quietly replace direction = "≈" in `i'
        display "`var'" _col(20) %9.4f `se_o' _col(35) %9.4f `se_r' _col(50) %6.3f `rat' _col(60) "≈ 相近"
    }
    
    local i = `i' + 1
}
display "{hline 70}"

export delimited using "table_T19_se_comparison.csv", replace
display "SS_OUTPUT_FILE|file=table_T19_se_comparison.csv|type=table|desc=se_comparison_table"
restore

display ""
display ">>> 比率 > 1: 稳健标准误更大（更保守的推断）"
display ">>> 比率 < 1: 稳健标准误更小（更高效的估计）"

* ==============================================================================
* SECTION 6: 回归诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 回归诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly regress `dep_var' `indep_vars'
quietly predict _yhat, xb
quietly predict _resid, residuals
quietly predict _rstd, rstandard

display ""
display ">>> 残差统计"
display "-------------------------------------------------------------------------------"
summarize _resid, detail

* ==============================================================================
* SECTION 7: 可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成残差诊断图（检查异方差模式）"

quietly twoway (scatter _rstd _yhat, msize(small) mcolor(navy%50)) ///
       (function y=0, range(_yhat) lcolor(red) lpattern(dash)) ///
       (function y=2, range(_yhat) lcolor(gray) lpattern(dot)) ///
       (function y=-2, range(_yhat) lcolor(gray) lpattern(dot)), ///
    title("标准化残差 vs 拟合值", size(medium)) ///
    subtitle("BP p = `: display %6.4f `bp_p'', White p = `: display %6.4f `white_p''", size(small)) ///
    xtitle("拟合值") ///
    ytitle("标准化残差") ///
    legend(off) ///
    note("若残差呈喇叭形（发散/收敛），表明存在异方差") ///
    scheme(s2color)

quietly graph export "fig_T19_residuals.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T19_residuals.png|type=graph|desc=residual_diagnostics_plot"
display ">>> 已导出: fig_T19_residuals.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出稳健回归结果: table_T19_reg_robust.csv"

quietly regress `dep_var' `indep_vars', vce(robust)

preserve
clear
local nvars: word count `indep_vars'
local nrows = `nvars' + 1
set obs `nrows'

generate str32 variable = ""
generate double coef = .
generate double robust_se = .
generate double t = .
generate double p = .
generate str10 sig = ""

local varlist "`indep_vars' _cons"
local i = 1
foreach var of local varlist {
    quietly replace variable = "`var'" in `i'
    quietly replace coef = _b[`var'] in `i'
    quietly replace robust_se = _se[`var'] in `i'
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

export delimited using "table_T19_reg_robust.csv", replace
display "SS_OUTPUT_FILE|file=table_T19_reg_robust.csv|type=table|desc=robust_regression_results"
display ">>> 稳健回归结果已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T19_paper.rtf"
    
    esttab using "table_T19_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T19_paper.rtf|type=table|desc=publication_table"
    display ">>> 论文级表格已导出 ✓"
}
else {
    display ""
    display ">>> 跳过论文级表格 (estout 未安装)"
}


* 清理临时变量
drop _yhat _resid _rstd

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T19 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "回归概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - R²:              " %10.4f `r2'
display ""
display "异方差检验:"
display "  - BP检验 p:        " %10.4f `bp_p'
display "  - White检验 p:     " %10.4f `white_p'
display ""
display "输出文件:"
display "  - table_T19_reg_robust.csv     稳健回归系数表"
display "  - table_T19_se_comparison.csv  标准误对比表"
display "  - fig_T19_residuals.png        残差诊断图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=r_squared|value=`r2'"
display "SS_SUMMARY|key=bp_p|value=`bp_p'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T19|status=ok|elapsed_sec=`elapsed'"

log close
