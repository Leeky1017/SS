* ==============================================================================
* SS_TEMPLATE: id=T31  level=L0  module=F  title="Panel Fixed Effects"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T31_fe_coef.csv type=table desc="FE regression coefficients"
*   - table_T31_fe_gof.csv type=table desc="Goodness of fit"
*   - table_T31_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
*   - estout source=ssc purpose="publication-quality tables (optional)" purpose="panel regression commands"
* ==============================================================================
* Task ID:      T31_panel_fe_basic
* Task Name:    面板固定效应回归
* Family:       F - 面板数据与政策评估
* Description:  估计面板固定效应回归模型
* 
* Placeholders: __DEP_VAR__     - 因变量
*               __INDEP_VARS__  - 自变量列表
*               __ID_VAR__      - 个体标识变量
*               __TIME_VAR__    - 时间变量
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
display "SS_TASK_BEGIN|id=T31|level=L0|title=Panel_Fixed_Effects"
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
display "║  TASK_ID: T31_panel_fe_basic                                               ║"
display "║  TASK_NAME: 面板固定效应回归（Panel Fixed Effects）                            ║"
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
* SECTION 1: 变量检查与面板设置
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与面板设置"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEP_VAR__"
local indep_vars "__INDEP_VARS__"
local id_var "__ID_VAR__"
local time_var "__TIME_VAR__"

* 聚类变量：如果未指定则默认使用个体变量
local cluster_var "__CLUSTER_VAR__"
if "`cluster_var'" == "" | "`cluster_var'" == "__CLUSTER_VAR__" {
    local cluster_var "`id_var'"
}

display ""
display ">>> 因变量:          `dep_var'"
display ">>> 自变量:          `indep_vars'"
display ">>> 个体变量:        `id_var'"
display ">>> 时间变量:        `time_var'"
display ">>> 聚类变量:        `cluster_var'"
display "-------------------------------------------------------------------------------"

* ---------- Panel pre-checks (T31–T33 通用) ----------
capture confirm variable `id_var'
if _rc {
    display as error "ERROR: ID variable `id_var' not found（个体标识变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `time_var'
if _rc {
    display as error "ERROR: Time variable `time_var' not found（时间变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `cluster_var'
if _rc {
    display as error "ERROR: Cluster variable `cluster_var' not found（聚类变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture ss_smart_xtset `id_var' `time_var'
if _rc {
    display as error "ERROR: Failed to xtset panel structure with `id_var' and `time_var'（面板结构设置失败）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

tempvar __panel_first
quietly bysort `id_var': gen byte `__panel_first' = (_n == 1) if !missing(`id_var')
quietly count if `__panel_first' == 1
local n_groups = r(N)
drop `__panel_first'

if `n_groups' <= 1 {
    display as error "ERROR: Panel models require at least 2 groups in `id_var'（面板个体数必须大于 1）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}
display ">>> 面板设置成功: `n_groups' 个个体"
* ---------- Panel pre-checks end ----------

* 使用官方命令统计唯一值数量（替代 distinct）
tempvar __tag_id __tag_time
quietly bysort `id_var': gen `__tag_id' = _n == 1
quietly count if `__tag_id'
local n_ids = r(N)
quietly bysort `time_var': gen `__tag_time' = _n == 1
quietly count if `__tag_time'
local n_times = r(N)
drop `__tag_id' `__tag_time'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 混合OLS（基准模型）
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 混合OLS（基准模型）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 混合OLS忽略面板结构，假设所有观测独立"
display ">>> 可能存在遗漏变量偏误（个体异质性）"
display "-------------------------------------------------------------------------------"

regress `dep_var' `indep_vars'
estimates store pooled

local r2_pooled = e(r2)
local n_obs = e(N)

* ==============================================================================
* SECTION 3: 固定效应回归
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 固定效应回归（FE）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 固定效应模型: Y_it = α_i + X_it'β + ε_it"
display ">>> 通过组内变换消除个体效应 α_i"
display ">>> 估计的是组内变异（within variation）"
display "-------------------------------------------------------------------------------"

xtreg `dep_var' `indep_vars', fe
estimates store fe_model

local r2_w = e(r2_w)
local r2_b = e(r2_b)
local r2_o = e(r2_o)
local sigma_u = e(sigma_u)
local sigma_e = e(sigma_e)
local rho = e(rho)
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
display "{hline 60}"

* ==============================================================================
* SECTION 4: 固定效应 + 聚类标准误
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 固定效应 + 聚类标准误"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 聚类标准误处理组内自相关和异方差"
display ">>> 论文中推荐使用此规格"
display "-------------------------------------------------------------------------------"

xtreg `dep_var' `indep_vars', fe vce(cluster `cluster_var')
estimates store fe_cluster

* ==============================================================================
* SECTION 5: 固定效应显著性检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 固定效应显著性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> F检验: H0: 所有个体效应 α_i = 0（即OLS适用）"
display "-------------------------------------------------------------------------------"

quietly xtreg `dep_var' `indep_vars', fe
local f_stat = e(F_f)
local df_a = e(df_a)
local df_r = e(df_r)
local f_p = Ftail(`df_a', `df_r', `f_stat')

display ""
display "{hline 60}"
display "F(" %5.0f `df_a' ", " %5.0f `df_r' ") = " %12.4f `f_stat'
display "Prob > F:              " %12.4f `f_p'
display "{hline 60}"

if `f_p' < 0.05 {
    display ""
    display as result ">>> 拒绝H0: 个体效应联合显著，应使用固定效应模型"
}
else {
    display ""
    display as error ">>> 不拒绝H0: 个体效应不显著，混合OLS可能适用"
}

* ==============================================================================
* SECTION 6: 模型比较
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 模型比较"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
estimates table pooled fe_model fe_cluster, star stats(N r2 r2_w r2_o) b(%9.4f) se(%9.4f)

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出FE系数
display ""
display ">>> 导出FE系数: table_T31_fe_coef.csv"

quietly xtreg `dep_var' `indep_vars', fe vce(cluster `id_var')

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

local varlist "`indep_vars' _cons"
local i = 1
foreach var of local varlist {
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

export delimited using "table_T31_fe_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T31_fe_coef.csv|type=table|desc=fe_regression_coefficients"
display ">>> FE系数已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T31_paper.rtf"
    
    esttab using "table_T31_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T31_paper.rtf|type=table|desc=publication_table"
    display ">>> 论文级表格已导出 ✓"
}
else {
    display ""
    display ">>> 跳过论文级表格 (estout 未安装)"
}


* 导出拟合优度
display ""
display ">>> 导出拟合优度: table_T31_fe_gof.csv"

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
generate double f_stat = `f_stat'
generate double f_p = `f_p'

export delimited using "table_T31_fe_gof.csv", replace
display "SS_OUTPUT_FILE|file=table_T31_fe_gof.csv|type=table|desc=goodness_of_fit"
display ">>> 拟合优度已导出"
restore

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T31 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 个体数:          " %10.0fc `n_groups'
display ""
display "拟合优度:"
display "  - Within R²:       " %10.4f `r2_w'
display "  - Overall R²:      " %10.4f `r2_o'
display "  - ρ (rho):         " %10.4f `rho'
display ""
display "固定效应检验:"
display "  - F统计量:         " %10.4f `f_stat'
display "  - p值:             " %10.4f `f_p'
display ""
display "输出文件:"
display "  - table_T31_fe_coef.csv    FE回归系数"
display "  - table_T31_fe_gof.csv     拟合优度指标"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_groups|value=`n_groups'"
display "SS_SUMMARY|key=r2_within|value=`r2_w'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T31|status=ok|elapsed_sec=`elapsed'"

log close
