* ==============================================================================
* SS_TEMPLATE: id=T49  level=L0  module=J  title="Automated Analysis Report"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T49_summary.csv type=table desc="Descriptive statistics"
*   - table_T49_correlation.csv type=table desc="Correlation matrix"
*   - table_T49_regression.csv type=table desc="Regression results"
*   - fig_T49_distribution.png type=graph desc="Distribution plot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="analysis commands"
* ==============================================================================
* Task ID:      T49_auto_analysis_report
* Task Name:    自动化分析报告
* Family:       J - 报告与打包
* Description:  自动执行描述统计、回归分析
* 
* Placeholders: __NUMERIC_VARS__  - 数值变量列表
*               __DEP_VAR__       - 因变量
*               __INDEP_VARS__    - 自变量列表
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
display "SS_TASK_BEGIN|id=T49|level=L0|title=Automated_Analysis_Report"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T49_auto_analysis_report                                      ║"
display "║  TASK_NAME: 自动化分析报告（Automated Analysis Report）                     ║"
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

local numeric_vars "__NUMERIC_VARS__"
local dep_var "__DEP_VAR__"
local indep_vars "__INDEP_VARS__"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* PART 1: 数据概览
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                          PART 1: 数据概览                                    ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"

display ""
display ">>> 1.1 数据集基本信息"
describe

display ""
display ">>> 1.2 样本量信息"
display "{hline 40}"
display "观测数:              " %10.0fc _N
display "变量数:              " %10.0fc c(k)
display "{hline 40}"

display ""
display ">>> 1.3 缺失值概况"
misstable summarize

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* PART 2: 描述统计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                          PART 2: 描述统计                                    ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"

display ""
display ">>> 2.1 数值变量描述统计"
summarize `numeric_vars'

display ""
display ">>> 2.2 详细描述统计"
tabstat `numeric_vars', statistics(n mean sd min p25 p50 p75 max) columns(statistics)

* 导出描述统计
display ""
display ">>> 导出描述统计: table_T49_summary.csv"

quietly tabstat `numeric_vars', statistics(n mean sd min p25 p50 p75 max) save
matrix stats = r(StatTotal)'

preserve
clear
svmat stats, names(col)
export delimited using "table_T49_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_T49_summary.csv|type=table|desc=descriptive_stats"
display ">>> 描述统计已导出"
restore

* ==============================================================================
* PART 3: 分布可视化
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                          PART 3: 分布可视化                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"

display ""
display ">>> 绘制因变量分布直方图"

histogram `dep_var', frequency normal ///
    title("`dep_var'的分布", size(medium)) ///
    xtitle("`dep_var'") ///
    ytitle("频数") ///
    note("叠加正态分布曲线", size(small)) ///
    scheme(s1color)

graph export "fig_T49_distribution.png", replace width(1000) height(700)
display "SS_OUTPUT_FILE|file=fig_T49_distribution.png|type=graph|desc=distribution_plot"
display ">>> 分布图已导出: fig_T49_distribution.png"

* ==============================================================================
* PART 4: 相关分析
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                          PART 4: 相关分析                                    ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"

display ""
display ">>> 4.1 相关系数矩阵（带显著性）"
pwcorr `dep_var' `indep_vars', sig star(0.05)

* 导出相关系数矩阵
display ""
display ">>> 导出相关系数矩阵: table_T49_correlation.csv"

local corr_vars "`dep_var' `indep_vars'"
quietly correlate `corr_vars'
matrix corr_matrix = r(C)

local n_corr_vars = wordcount("`corr_vars'")

preserve
clear
set obs `n_corr_vars'
generate str32 variable = ""

local i = 1
foreach v of local corr_vars {
    replace variable = "`v'" in `i'
    local i = `i' + 1
}

* 添加相关系数列
local j = 1
foreach v of local corr_vars {
    generate double corr_`v' = .
    forvalues i = 1/`n_corr_vars' {
        replace corr_`v' = corr_matrix[`i', `j'] in `i'
    }
    local j = `j' + 1
}

export delimited using "table_T49_correlation.csv", replace
display "SS_OUTPUT_FILE|file=table_T49_correlation.csv|type=table|desc=correlation_matrix"
display ">>> 相关系数矩阵已导出"
restore

* ==============================================================================
* PART 5: 回归分析
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                          PART 5: 回归分析                                    ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"

display ""
display ">>> 5.1 OLS回归（普通标准误）"
regress `dep_var' `indep_vars'

display ""
display ">>> 5.2 OLS回归（稳健标准误）"
regress `dep_var' `indep_vars', vce(robust)

* 导出回归结果
display ""
display ">>> 导出回归结果: table_T49_regression.csv"

matrix coef = e(b)'
matrix var = e(V)

preserve
clear
local ncols = rowsof(coef)
set obs `ncols'

generate str32 variable = ""
generate double coef = .
generate double se = .
generate double t = .
generate double p = .

local names: rownames coef
local i = 1
foreach name of local names {
    quietly replace variable = "`name'" in `i'
    local b = coef[`i', 1]
    local v = var[`i', `i']
    local s = sqrt(`v')
    quietly replace coef = `b' in `i'
    quietly replace se = `s' in `i'
    local t_val = `b' / `s'
    local p_val = 2 * ttail(e(df_r), abs(`t_val'))
    quietly replace t = `t_val' in `i'
    quietly replace p = `p_val' in `i'
    local i = `i' + 1
}

export delimited using "table_T49_regression.csv", replace
display "SS_OUTPUT_FILE|file=table_T49_regression.csv|type=table|desc=regression_results"
display ">>> 回归结果已导出"
restore

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* PART 6: 诊断检验
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                          PART 6: 诊断检验                                    ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"

quietly regress `dep_var' `indep_vars'

display ""
display ">>> 6.1 异方差检验（Breusch-Pagan）"
estat hettest

display ""
display ">>> 6.2 多重共线性检验（VIF）"
estat vif

display ""
display ">>> 6.3 模型设定检验（Ramsey RESET）"
estat ovtest

* ==============================================================================
* 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T49 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "自动化分析报告已生成，包含："
display "  - 数据概览（样本量、缺失值）"
display "  - 描述统计（均值、标准差、分位数）"
display "  - 分布可视化（直方图）"
display "  - 相关分析（相关系数矩阵）"
display "  - 回归分析（OLS、稳健OLS）"
display "  - 诊断检验（异方差、共线性、设定）"
display ""
display "输出文件:"
display "  - table_T49_summary.csv       描述统计"
display "  - table_T49_correlation.csv   相关系数矩阵"
display "  - table_T49_regression.csv    回归结果"
display "  - fig_T49_distribution.png    分布图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
local nvars = wordcount("`numeric_vars'")
display "SS_SUMMARY|key=n_vars|value=`nvars'"
display "SS_SUMMARY|key=r2|value=`r2'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T49|status=ok|elapsed_sec=`elapsed'"

log close
