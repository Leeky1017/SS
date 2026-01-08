* ==============================================================================
* SS_TEMPLATE: id=T21  level=L0  module=D  title="OLS with Interaction Terms"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T21_reg_interaction.csv type=table desc="Interaction regression results"
*   - fig_T21_margins.png type=graph desc="Marginal effects plot"
*   - table_T21_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
*   - estout source=ssc purpose="publication-quality tables (optional)" purpose="core regression commands"
* ==============================================================================
* Task ID:      T21_ols_with_interaction
* Task Name:    含交互项的回归（调节效应分析）
* Family:       D - 线性回归
* Description:  估计包含变量交互项的回归模型
* 
* Placeholders: __DEPVAR__        - 因变量
*               __INDEPVARS__     - 自变量列表
*               __INTERACT_VAR1__  - 交互项变量1
*               __INTERACT_VAR2__  - 交互项变量2
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

program define ss_fail_T21
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T21|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T21|level=L0|title=OLS_with_Interaction_Terms"
display "SS_SUMMARY|key=template_version|value=2.0.1"

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
display "║  TASK_ID: T21_ols_with_interaction                                         ║"
display "║  TASK_NAME: 含交互项的回归（调节效应分析）                                   ║"
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
        ss_fail_T21 601 "confirm file" "data_file_not_found"
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
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与准备"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEPVAR__"
local indep_vars "__INDEPVARS__"
local var1 "__INTERACT_VAR1__"
local var2 "__INTERACT_VAR2__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    ss_fail_T21 111 "confirm variable" "dep_var_not_found"
}

capture confirm variable `var1'
if _rc {
    display as error "ERROR: Interaction variable 1 `var1' not found"
    ss_fail_T21 111 "confirm variable" "interact_var1_not_found"
}

capture confirm variable `var2'
if _rc {
    display as error "ERROR: Interaction variable 2 `var2' not found"
    ss_fail_T21 111 "confirm variable" "interact_var2_not_found"
}

display ""
display ">>> 因变量 (Y):      `dep_var'"
display ">>> 控制变量:        `indep_vars'"
display ">>> 核心自变量:      `var1'"
display ">>> 调节变量:        `var2'"
display ">>> 交互项:          `var1' × `var2'"

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
summarize `dep_var' `var1' `var2' `indep_vars'

* 获取调节变量的分位数
quietly summarize `var2', detail
local m_p10 = r(p10)
local m_p25 = r(p25)
local m_p50 = r(p50)
local m_p75 = r(p75)
local m_p90 = r(p90)
local m_mean = r(mean)
local m_sd = r(sd)

* ==============================================================================
* SECTION 3: 基准模型（无交互项）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 基准模型（无交互项）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
regress `dep_var' `indep_vars' `var1' `var2'

estimates store base_model
local r2_base = e(r2)
local n_obs = e(N)

* ==============================================================================
* SECTION 4: 交互项模型
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 交互项模型"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 回归模型"
display "-------------------------------------------------------------------------------"
display "`dep_var' = β₀ + β₁`var1' + β₂`var2' + β₃(`var1' × `var2') + Controls + ε"
display ""

* 创建交互项
quietly generate _interact = `var1' * `var2'
label variable _interact "`var1' × `var2'"

regress `dep_var' `indep_vars' `var1' `var2' _interact

estimates store inter_model
local r2_inter = e(r2)
local r2_adj = e(r2_a)

* 保存交互项结果
local b_int = _b[_interact]
local se_int = _se[_interact]
local t_int = `b_int' / `se_int'
local p_int = 2 * ttail(e(df_r), abs(`t_int'))

local b_var1 = _b[`var1']
local b_var2 = _b[`var2']

* ==============================================================================
* SECTION 5: 交互效应解读
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 交互效应解读"
display "═══════════════════════════════════════════════════════════════════════════════"

* 显著性标记
if `p_int' < 0.01 {
    local sig_int "***"
}
else if `p_int' < 0.05 {
    local sig_int "**"
}
else if `p_int' < 0.10 {
    local sig_int "*"
}
else {
    local sig_int ""
}

display ""
display "{hline 70}"
display "交互项系数:         " %10.4f `b_int' " `sig_int'"
display "标准误:             " %10.4f `se_int'
display "t 统计量:           " %10.2f `t_int'
display "p 值:               " %10.4f `p_int'
display "{hline 70}"

display ""
display ">>> 边际效应解释："
display "    `var1' 对 `dep_var' 的边际效应 = β₁ + β₃ × `var2'"
display "    = `: display %6.4f `b_var1'' + `: display %6.4f `b_int'' × `var2'"
display ""

if `p_int' < 0.10 {
    display as result ">>> 交互效应显著 (`sig_int')"
    display "    `var1' 对 `dep_var' 的影响随 `var2' 的变化而变化"
    if `b_int' > 0 {
        display "    正向调节：`var2' 越高，`var1' 的效应越强"
    }
    else {
        display "    负向调节：`var2' 越高，`var1' 的效应越弱"
    }
}
else {
    display as error ">>> 交互效应不显著 (p = `: display %6.4f `p_int'')"
    display "    可能不存在显著的调节效应"
}

* ==============================================================================
* SECTION 6: 边际效应分析
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 边际效应分析（简单斜率）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> `var1' 的边际效应（在 `var2' 不同水平下）"
display "-------------------------------------------------------------------------------"

* 使用因子变量语法重新估计
quietly regress `dep_var' `indep_vars' c.`var1'##c.`var2'

* 在调节变量的关键水平计算边际效应
margins, dydx(`var1') at(`var2'=(`m_p10' `m_p25' `m_p50' `m_p75' `m_p90'))

* ==============================================================================
* SECTION 7: 模型比较
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 模型比较"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 50}"
display "基准模型 R²:        " %10.4f `r2_base'
display "交互模型 R²:        " %10.4f `r2_inter'
display "R² 增量:            " %10.4f (`r2_inter' - `r2_base')
display "{hline 50}"

* ==============================================================================
* SECTION 8: 可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成边际效应图"

quietly regress `dep_var' `indep_vars' c.`var1'##c.`var2'
quietly margins, dydx(`var1') at(`var2'=(`m_p10' `m_p25' `m_p50' `m_p75' `m_p90'))

quietly marginsplot, ///
    title("`var1' 的边际效应", size(medium)) ///
    subtitle("调节变量: `var2'", size(small)) ///
    xtitle("`var2'") ///
    ytitle("`var1' 的边际效应") ///
    note("交互项系数 = `: display %6.4f `b_int'' `sig_int'") ///
    scheme(s2color)

quietly graph export "fig_T21_margins.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T21_margins.png|type=graph|desc=marginal_effects_plot"
display ">>> 已导出: fig_T21_margins.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 9: 导出结果文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 9: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出回归结果: table_T21_reg_interaction.csv"

preserve
clear
set obs 4

generate str32 variable = ""
generate double coef = .
generate double se = .
generate double t = .
generate double p = .
generate str10 sig = ""

quietly replace variable = "`var1'" in 1
quietly replace coef = `b_var1' in 1

quietly replace variable = "`var2'" in 2
quietly replace coef = `b_var2' in 2

quietly replace variable = "`var1'_x_`var2'" in 3
quietly replace coef = `b_int' in 3
quietly replace se = `se_int' in 3
quietly replace t = `t_int' in 3
quietly replace p = `p_int' in 3
quietly replace sig = "`sig_int'" in 3

export delimited using "table_T21_reg_interaction.csv", replace
display "SS_OUTPUT_FILE|file=table_T21_reg_interaction.csv|type=table|desc=interaction_regression"
display ">>> 回归结果已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T21_paper.rtf"
    
    esttab using "table_T21_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T21_paper.rtf|type=table|desc=publication_table"
    display ">>> 论文级表格已导出 ✓"
}
else {
    display ""
    display ">>> 跳过论文级表格 (estout 未安装)"
}


* 清理
drop _interact

* ==============================================================================
* SECTION 10: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T21 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "回归概况:"
display "  - 因变量:          `dep_var'"
display "  - 核心自变量:      `var1'"
display "  - 调节变量:        `var2'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - R²:              " %10.4f `r2_inter'
display ""
display "交互效应:"
display "  - 交互项系数:      " %10.4f `b_int' " `sig_int'"
display "  - p 值:            " %10.4f `p_int'
display ""
display "输出文件:"
display "  - table_T21_reg_interaction.csv  回归结果"
display "  - fig_T21_margins.png            边际效应图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=r_squared|value=`r2_inter'"
display "SS_SUMMARY|key=interaction_p|value=`p_int'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T21|status=ok|elapsed_sec=`elapsed'"

log close
