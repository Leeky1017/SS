* ==============================================================================
* SS_TEMPLATE: id=T32  level=L0  module=F  title="Panel Random Effects"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T32_re_coef.csv type=table desc="RE regression coefficients"
*   - table_T32_re_gof.csv type=table desc="Goodness of fit"
*   - table_T32_paper.docx type=report desc="Publication-style table (docx)"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
* ==============================================================================
* Task ID:      T32_panel_re_basic
* Task Name:    面板随机效应回归
* Family:       F - 面板数据与政策评估
* Description:  估计面板随机效应回归模型
* 
* Placeholders: __DEPVAR__     - 因变量
*               __INDEPVARS__  - 自变量列表
*               __ID_VAR__      - 个体标识变量
*               __TIME_VAR__    - 时间变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands)
* ==============================================================================

* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.2)
* - 2026-01-08: Keep RE estimation via `xtreg, re`; use `T33` Hausman test to justify FE vs RE choice (保留随机效应，FE/RE 选择用 Hausman 检验).
* - 2026-01-08: Replace optional SSC `estout/esttab` with Stata 18 native `putdocx` report (移除 SSC 依赖，使用原生 docx 输出).
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

program define ss_fail_T32
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T32|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T32|level=L0|title=Panel_Random_Effects"
display "SS_SUMMARY|key=template_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T32_panel_re_basic                                               ║"
display "║  TASK_NAME: 面板随机效应回归（Panel Random Effects）                          ║"
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
        ss_fail_T32 601 "confirm file" "data_file_not_found"
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
* SECTION 1: 变量检查与面板设置
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与面板设置"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEPVAR__"
local indep_vars "__INDEPVARS__"
local id_var "__ID_VAR__"
local time_var "__TIME_VAR__"

display ""
display ">>> 因变量:          `dep_var'"
display ">>> 自变量:          `indep_vars'"
display ">>> 个体变量:        `id_var'"
display ">>> 时间变量:        `time_var'"
display "-------------------------------------------------------------------------------"

* ---------- Panel pre-checks (T31–T33 通用) ----------
capture confirm variable `id_var'
if _rc {
    display as error "ERROR: ID variable `id_var' not found（个体标识变量不存在）."
    ss_fail_T32 111 "confirm variable" "id_var_not_found"
}

capture confirm variable `time_var'
if _rc {
    display as error "ERROR: Time variable `time_var' not found（时间变量不存在）."
    ss_fail_T32 111 "confirm variable" "time_var_not_found"
}

capture ss_smart_xtset `id_var' `time_var'
if _rc {
    display as error "ERROR: Failed to xtset panel structure with `id_var' and `time_var'（面板结构设置失败）."
    ss_fail_T32 200 "runtime" "task_failed"
}

tempvar __panel_first
quietly bysort `id_var': gen byte `__panel_first' = (_n == 1) if !missing(`id_var')
quietly count if `__panel_first' == 1
local n_groups_check = r(N)
drop `__panel_first'

if `n_groups_check' <= 1 {
    display as error "ERROR: Panel models require at least 2 groups in `id_var'（面板个体数必须大于 1）."
    ss_fail_T32 200 "runtime" "task_failed"
}
display ">>> 面板设置成功: `n_groups_check' 个个体"
* ---------- Panel pre-checks end ----------

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 随机效应回归
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 随机效应回归（RE）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 随机效应模型: Y_it = α + X_it'β + u_i + ε_it"
display ">>> 假设: u_i 与 X_it 不相关（外生性假设）"
display ">>> 使用GLS估计，加权组内和组间变异"
display "-------------------------------------------------------------------------------"

xtreg `dep_var' `indep_vars', re
estimates store re_model

local r2_w = e(r2_w)
local r2_b = e(r2_b)
local r2_o = e(r2_o)
local sigma_u = e(sigma_u)
local sigma_e = e(sigma_e)
local rho = e(rho)
local theta = e(theta)
local n_obs = e(N)
local n_groups = e(N_g)

display ""
display "{hline 60}"
display "Within R²:             " %12.4f `r2_w'
display "Between R²:            " %12.4f `r2_b'
display "Overall R²:            " %12.4f `r2_o'
display "{hline 60}"
display "σ_u (个体效应SD):      " %12.4f `sigma_u'
display "σ_e (特质误差SD):      " %12.4f `sigma_e'
display "ρ (个体效应占比):      " %12.4f `rho'
display "θ (GLS权重):           " %12.4f `theta'
display "{hline 60}"

* ==============================================================================
* SECTION 3: 随机效应 + 稳健标准误
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 随机效应 + 稳健标准误"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 稳健标准误处理异方差"
display "-------------------------------------------------------------------------------"

xtreg `dep_var' `indep_vars', re vce(robust)
estimates store re_robust

* ==============================================================================
* SECTION 4: BP-LM检验（RE vs Pooled OLS）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: Breusch-Pagan LM检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> H0: Var(u_i) = 0（即混合OLS适用）"
display ">>> H1: Var(u_i) > 0（即存在个体效应）"
display "-------------------------------------------------------------------------------"

quietly xtreg `dep_var' `indep_vars', re
xttest0

local lm_chi2 = r(chi2)
local lm_p = r(p)

display ""
if `lm_p' < 0.05 {
    display as result ">>> 拒绝H0 (p < 0.05): 存在显著个体效应"
    display "    应使用随机效应模型而非混合OLS"
}
else {
    display as error ">>> 不拒绝H0: 个体效应不显著"
    display "    混合OLS可能适用"
}

* ==============================================================================
* SECTION 5: 模型比较
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 模型比较"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly regress `dep_var' `indep_vars'
estimates store pooled

display ""
estimates table pooled re_model re_robust, star stats(N r2 r2_o) b(%9.4f) se(%9.4f)

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 6: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出RE系数
display ""
display ">>> 导出RE系数: table_T32_re_coef.csv"

quietly xtreg `dep_var' `indep_vars', re vce(robust)

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

export delimited using "table_T32_re_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T32_re_coef.csv|type=table|desc=re_regression_coefficients"
display ">>> RE系数已导出"

display ""
display ">>> 导出论文级表格: table_T32_paper.docx"
putdocx clear
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("T32: Panel Random Effects / 面板随机效应回归")
putdocx paragraph
putdocx text ("Estimation: xtreg, re.")
putdocx table t1 = data(variable coef se z p sig), varnames
putdocx save "table_T32_paper.docx", replace
display "SS_OUTPUT_FILE|file=table_T32_paper.docx|type=report|desc=publication_table_docx"
display ">>> 论文级表格已导出 ✓"
restore
* 导出拟合优度
display ""
display ">>> 导出拟合优度: table_T32_re_gof.csv"

preserve
clear
set obs 1

generate double n_obs = `n_obs'
generate int n_groups = `n_groups'
generate double r2_within = `r2_w'
generate double r2_between = `r2_b'
generate double r2_overall = `r2_o'
generate double sigma_u = `sigma_u'
generate double sigma_e = `sigma_e'
generate double rho = `rho'
generate double lm_chi2 = `lm_chi2'
generate double lm_p = `lm_p'

export delimited using "table_T32_re_gof.csv", replace
display "SS_OUTPUT_FILE|file=table_T32_re_gof.csv|type=table|desc=goodness_of_fit"
display ">>> 拟合优度已导出"
restore

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T32 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 个体数:          " %10.0fc `n_groups'
display ""
display "拟合优度:"
display "  - Overall R²:      " %10.4f `r2_o'
display "  - ρ (rho):         " %10.4f `rho'
display ""
display "BP-LM检验:"
display "  - χ²统计量:        " %10.4f `lm_chi2'
display "  - p值:             " %10.4f `lm_p'
display ""
display "输出文件:"
display "  - table_T32_re_coef.csv    RE回归系数"
display "  - table_T32_re_gof.csv     拟合优度指标"
display "  - table_T32_paper.docx      论文级表格（docx）"
display ""
display ">>> 提示: 使用T33进行Hausman检验以选择FE或RE"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_groups|value=`n_groups'"
display "SS_SUMMARY|key=r2_overall|value=`r2_o'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T32|status=ok|elapsed_sec=`elapsed'"

log close
