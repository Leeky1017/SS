* ==============================================================================
* SS_TEMPLATE: id=T22  level=L0  module=D  title="Entity Fixed Effects"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T22_reg_fe.csv type=table desc="Fixed effects regression results"
*   - table_T22_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
*   - estout source=ssc purpose="publication-quality tables (optional)" purpose="core regression commands"
* ==============================================================================
* Task ID:      T22_ols_fe_entity_dummies
* Task Name:    实体固定效应
* Family:       D - 线性回归
* Description:  通过areg实现实体固定效应
* 
* Placeholders: __DEP_VAR__     - 因变量
*               __INDEP_VARS__  - 自变量列表
*               __ENTITY_VAR__  - 实体变量（固定效应）
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
display "SS_TASK_BEGIN|id=T22|level=L0|title=Entity_Fixed_Effects"
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
display "║  TASK_ID: T22_ols_fe_entity_dummies                                        ║"
display "║  TASK_NAME: 实体固定效应（Entity Fixed Effects）                              ║"
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
local entity_var "__ENTITY_VAR__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `entity_var'
if _rc {
    display as error "ERROR: Entity variable `entity_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

* 实体统计
quietly levelsof `entity_var', local(entities)
local n_entities: word count `entities'
local avg_obs = `n_total' / `n_entities'

display ""
display ">>> 因变量:          `dep_var'"
display ">>> 自变量:          `indep_vars'"
display ">>> 实体变量:        `entity_var'"
display ""
display "{hline 50}"
display "总样本量:            " %10.0fc `n_total'
display "实体数量:            " %10.0fc `n_entities'
display "平均每实体观测:      " %10.2f `avg_obs'
display "{hline 50}"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 混合OLS（Pooled OLS）
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 混合OLS（不控制实体效应）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
regress `dep_var' `indep_vars'

estimates store pooled_ols
local r2_pooled = e(r2)
local n_obs = e(N)

* ==============================================================================
* SECTION 3: 实体固定效应（areg）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 实体固定效应（areg）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 使用 areg 吸收实体固定效应"
display ">>> 实体变量: `entity_var' (`n_entities' 个实体)"
display "-------------------------------------------------------------------------------"

areg `dep_var' `indep_vars', absorb(`entity_var')

estimates store fe_model
local r2_fe = e(r2)
local r2_within = e(r2_a)

* ==============================================================================
* SECTION 4: 固定效应联合显著性检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 固定效应联合显著性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> H0: 所有实体固定效应 = 0"
display "-------------------------------------------------------------------------------"

quietly regress `dep_var' `indep_vars' i.`entity_var'
testparm i.`entity_var'

local fe_F = r(F)
local fe_p = r(p)

display ""
if `fe_p' < 0.05 {
    display as result ">>> 固定效应联合显著 (p < 0.05)"
    display "    应控制实体固定效应 ✓"
}
else {
    display as error ">>> 固定效应联合不显著 (p ≥ 0.05)"
    display "    可考虑使用混合OLS"
}

* ==============================================================================
* SECTION 5: 最终模型（聚类标准误）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 最终模型（实体固定效应 + 聚类标准误）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 控制实体固定效应，按实体聚类标准误"
display "-------------------------------------------------------------------------------"

areg `dep_var' `indep_vars', absorb(`entity_var') vce(cluster `entity_var')

estimates store fe_cluster
local F_stat = e(F)

* ==============================================================================
* SECTION 6: 模型比较
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 模型比较"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 60}"
display "模型" _col(25) "R²" _col(40) "Within R²"
display "{hline 60}"
display "混合OLS" _col(25) %8.4f `r2_pooled' _col(40) "N/A"
display "实体固定效应" _col(25) %8.4f `r2_fe' _col(40) %8.4f `r2_within'
display "{hline 60}"
display "R² 增量:             " %10.4f (`r2_fe' - `r2_pooled')
display "FE联合检验 F:        " %10.4f `fe_F'
display "FE联合检验 p:        " %10.4f `fe_p'
display "{hline 60}"

display ""
display ">>> 说明："
display "    - 固定效应 R² 包含实体虚拟变量的解释力"
display "    - Within R² 仅基于组内变异，通常更低"
display "    - 实体间变异被固定效应吸收"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出固定效应回归结果: table_T22_reg_fe.csv"

quietly areg `dep_var' `indep_vars', absorb(`entity_var') vce(cluster `entity_var')

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

export delimited using "table_T22_reg_fe.csv", replace
display "SS_OUTPUT_FILE|file=table_T22_reg_fe.csv|type=table|desc=fixed_effects_regression"
display ">>> 固定效应回归结果已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T22_paper.rtf"
    
    esttab using "table_T22_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T22_paper.rtf|type=table|desc=publication_table"
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
display "║                            T22 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "回归概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 实体变量:        `entity_var'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 实体数量:        " %10.0fc `n_entities'
display "  - R²:              " %10.4f `r2_fe'
display "  - Within R²:       " %10.4f `r2_within'
display ""
display "固定效应检验:"
display "  - F 统计量:        " %10.4f `fe_F'
display "  - p 值:            " %10.4f `fe_p'
display ""
display "输出文件:"
display "  - table_T22_reg_fe.csv    固定效应回归结果"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_entities|value=`n_entities'"
display "SS_SUMMARY|key=r_squared|value=`r2_fe'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T22|status=ok|elapsed_sec=`elapsed'"

log close
