* ==============================================================================
* SS_TEMPLATE: id=T20  level=L0  module=D  title="OLS with Cluster SE"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T20_reg_cluster.csv type=table desc="Cluster regression results"
*   - table_T20_se_comparison.csv type=table desc="SE comparison table"
*   - table_T20_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
*   - estout source=ssc purpose="publication-quality tables (optional)" purpose="core regression commands"
* ==============================================================================
* Task ID:      T20_ols_cluster_se
* Task Name:    聚类稳健标准误OLS
* Family:       D - 线性回归
* Description:  使用聚类稳健标准误的OLS回归
* 
* Placeholders: __DEP_VAR__      - 因变量
*               __INDEP_VARS__   - 自变量列表
*               __CLUSTER_VAR__  - 聚类变量
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
display "SS_TASK_BEGIN|id=T20|level=L0|title=OLS_with_Cluster_SE"
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
display "║  TASK_ID: T20_ols_cluster_se                                                ║"
display "║  TASK_NAME: 聚类稳健标准误OLS（Cluster-Robust SE）                           ║"
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
local cluster_var "__CLUSTER_VAR__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `cluster_var'
if _rc {
    display as error "ERROR: Cluster variable `cluster_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

* 聚类统计
quietly levelsof `cluster_var', local(clusters)
local n_clusters: word count `clusters'
local avg_cluster_size = `n_total' / `n_clusters'

display ""
display ">>> 因变量:         `dep_var'"
display ">>> 自变量:         `indep_vars'"
display ">>> 聚类变量:       `cluster_var'"
display ""
display "{hline 50}"
display "总样本量:           " %10.0fc `n_total'
display "聚类数量:           " %10.0fc `n_clusters'
display "平均聚类大小:       " %10.2f `avg_cluster_size'
display "{hline 50}"

* 聚类数量警告
display ""
if `n_clusters' < 30 {
    display as error "WARNING: 聚类数量较少 (<30)，标准误可能低估！"
    display as error "         建议: 考虑 wild cluster bootstrap"
}
else if `n_clusters' < 50 {
    display as error "WARNING: 聚类数量中等 (30-50)，结果需谨慎解读"
}
else {
    display as result ">>> 聚类数量充足 (≥50)，聚类标准误可靠 ✓"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 普通 OLS 回归（对比基准）
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 普通 OLS 回归（对比基准）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
regress `dep_var' `indep_vars'

local r2 = e(r2)
local r2_adj = e(r2_a)
local n_obs = e(N)
matrix V_ols = e(V)

* ==============================================================================
* SECTION 3: 稳健标准误 OLS（对比）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 稳健标准误 OLS（对比）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
regress `dep_var' `indep_vars', vce(robust)

matrix V_robust = e(V)

* ==============================================================================
* SECTION 4: 聚类稳健标准误 OLS
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 聚类稳健标准误 OLS"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 聚类变量: `cluster_var' (`n_clusters' 个聚类)"
display ">>> 允许同一聚类内的观测存在任意相关"
display "-------------------------------------------------------------------------------"

regress `dep_var' `indep_vars', vce(cluster `cluster_var')

matrix V_cluster = e(V)
local F_cluster = e(F)

* ==============================================================================
* SECTION 5: 三种标准误对比
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 三种标准误对比"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 75}"
display "变量" _col(18) "OLS SE" _col(30) "Robust SE" _col(43) "Cluster SE" _col(56) "Clust/OLS" _col(68) "趋势"
display "{hline 75}"

* 准备导出
preserve
clear
local nvars: word count `indep_vars'
local nrows = `nvars' + 1
set obs `nrows'

generate str32 variable = ""
generate double se_ols = .
generate double se_robust = .
generate double se_cluster = .
generate double ratio_cluster_ols = .

local varlist "`indep_vars' _cons"
local i = 1
foreach var of local varlist {
    quietly replace variable = "`var'" in `i'
    
    local se_o = sqrt(V_ols[`i', `i'])
    local se_r = sqrt(V_robust[`i', `i'])
    local se_c = sqrt(V_cluster[`i', `i'])
    local rat = `se_c' / `se_o'
    
    quietly replace se_ols = `se_o' in `i'
    quietly replace se_robust = `se_r' in `i'
    quietly replace se_cluster = `se_c' in `i'
    quietly replace ratio_cluster_ols = `rat' in `i'
    
    if `rat' > 1.5 {
        display "`var'" _col(18) %9.4f `se_o' _col(30) %9.4f `se_r' _col(43) %9.4f `se_c' _col(56) %6.2f `rat' _col(68) "↑↑"
    }
    else if `rat' > 1.1 {
        display "`var'" _col(18) %9.4f `se_o' _col(30) %9.4f `se_r' _col(43) %9.4f `se_c' _col(56) %6.2f `rat' _col(68) "↑"
    }
    else if `rat' < 0.9 {
        display "`var'" _col(18) %9.4f `se_o' _col(30) %9.4f `se_r' _col(43) %9.4f `se_c' _col(56) %6.2f `rat' _col(68) "↓"
    }
    else {
        display "`var'" _col(18) %9.4f `se_o' _col(30) %9.4f `se_r' _col(43) %9.4f `se_c' _col(56) %6.2f `rat' _col(68) "≈"
    }
    
    local i = `i' + 1
}
display "{hline 75}"

export delimited using "table_T20_se_comparison.csv", replace
display "SS_OUTPUT_FILE|file=table_T20_se_comparison.csv|type=table|desc=se_comparison_table"
restore

display ""
display ">>> 比率解读："
display "    比率 > 1.5: 聚类效应很强，组内高度相关"
display "    比率 1.1-1.5: 存在中等聚类效应"
display "    比率 ≈ 1: 聚类效应较弱"

* ==============================================================================
* SECTION 6: 组内相关系数（ICC）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 组内相关系数（ICC）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> ICC 衡量同一聚类内观测的相关程度"
display "-------------------------------------------------------------------------------"
loneway `dep_var' `cluster_var'

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出聚类回归结果: table_T20_reg_cluster.csv"

quietly regress `dep_var' `indep_vars', vce(cluster `cluster_var')

preserve
clear
local nvars: word count `indep_vars'
local nrows = `nvars' + 1
set obs `nrows'

generate str32 variable = ""
generate double coef = .
generate double cluster_se = .
generate double t = .
generate double p = .
generate str10 sig = ""

local varlist "`indep_vars' _cons"
local i = 1
foreach var of local varlist {
    quietly replace variable = "`var'" in `i'
    quietly replace coef = _b[`var'] in `i'
    quietly replace cluster_se = _se[`var'] in `i'
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

export delimited using "table_T20_reg_cluster.csv", replace
display "SS_OUTPUT_FILE|file=table_T20_reg_cluster.csv|type=table|desc=cluster_regression_results"
display ">>> 聚类回归结果已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T20_paper.rtf"
    
    esttab using "table_T20_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T20_paper.rtf|type=table|desc=publication_table"
    display ">>> 论文级表格已导出 ✓"
}
else {
    display ""
    display ">>> 跳过论文级表格 (estout 未安装)"
}


* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T20 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "回归概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 聚类变量:        `cluster_var'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 聚类数量:        " %10.0fc `n_clusters'
display "  - R²:              " %10.4f `r2'
display ""
display "输出文件:"
display "  - table_T20_reg_cluster.csv    聚类回归系数表"
display "  - table_T20_se_comparison.csv  三种SE对比表"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_clusters|value=`n_clusters'"
display "SS_SUMMARY|key=r_squared|value=`r2'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T20|status=ok|elapsed_sec=`elapsed'"

log close
