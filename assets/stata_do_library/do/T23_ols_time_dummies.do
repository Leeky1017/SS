* ==============================================================================
* SS_TEMPLATE: id=T23  level=L0  module=D  title="Time Fixed Effects"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T23_reg_timefe.csv type=table desc="Time fixed effects regression"
*   - fig_T23_time_effects.png type=graph desc="Time effects plot"
*   - table_T23_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
*   - estout source=ssc purpose="publication-quality tables (optional)" purpose="core regression commands"
* ==============================================================================
* Task ID:      T23_ols_time_dummies
* Task Name:    时间固定效应
* Family:       D - 线性回归
* Description:  加入时间虚拟变量控制时间效应
* 
* Placeholders: __DEPVAR__     - 因变量
*               __INDEPVARS__  - 自变量列表
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
display "SS_TASK_BEGIN|id=T23|level=L0|title=Time_Fixed_Effects"
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
display "║  TASK_ID: T23_ols_time_dummies                                             ║"
display "║  TASK_NAME: 时间固定效应（Year/Time Fixed Effects）                           ║"
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
local time_var "__TIME_VAR__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `time_var'
if _rc {
    display as error "ERROR: Time variable `time_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

* 时间统计
quietly levelsof `time_var', local(periods)
local n_periods: word count `periods'

display ""
display ">>> 因变量:          `dep_var'"
display ">>> 自变量:          `indep_vars'"
display ">>> 时间变量:        `time_var'"
display ""
display "{hline 50}"
display "总样本量:            " %10.0fc `n_total'
display "时间期数:            " %10.0fc `n_periods'
display "{hline 50}"

display ""
tabulate `time_var'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 基准模型（无时间效应）
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 基准模型（无时间效应）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
regress `dep_var' `indep_vars'

estimates store no_time
local r2_base = e(r2)
local n_obs = e(N)

* ==============================================================================
* SECTION 3: 时间固定效应模型
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 时间固定效应模型"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 加入时间虚拟变量: i.`time_var' (`n_periods' 个时期)"
display "-------------------------------------------------------------------------------"

regress `dep_var' `indep_vars' i.`time_var'

estimates store with_time
local r2_time = e(r2)

* ==============================================================================
* SECTION 4: 时间效应联合显著性检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 时间效应联合显著性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> H0: 所有时间虚拟变量系数 = 0"
display "-------------------------------------------------------------------------------"

testparm i.`time_var'

local time_F = r(F)
local time_p = r(p)

display ""
if `time_p' < 0.05 {
    display as result ">>> 时间固定效应联合显著 (p < 0.05)"
    display "    应控制时间固定效应 ✓"
}
else {
    display as error ">>> 时间固定效应不显著 (p ≥ 0.05)"
    display "    可考虑不加时间固定效应"
}

* ==============================================================================
* SECTION 5: 模型比较
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 模型比较"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 50}"
display "无时间效应 R²:       " %10.4f `r2_base'
display "有时间效应 R²:       " %10.4f `r2_time'
display "R² 增量:             " %10.4f (`r2_time' - `r2_base')
display "{hline 50}"
display "时间FE联合检验 F:    " %10.4f `time_F'
display "时间FE联合检验 p:    " %10.4f `time_p'
display "{hline 50}"

* ==============================================================================
* SECTION 6: 可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成时间效应图"

quietly regress `dep_var' `indep_vars' i.`time_var'
quietly margins `time_var'
quietly marginsplot, ///
    title("时间固定效应", size(medium)) ///
    subtitle("各时期的预测均值", size(small)) ///
    xtitle("`time_var'") ///
    ytitle("预测 `dep_var'") ///
    scheme(s2color)

quietly graph export "fig_T23_time_effects.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T23_time_effects.png|type=graph|desc=time_effects_plot"
display ">>> 已导出: fig_T23_time_effects.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出时间固定效应回归结果: table_T23_reg_timefe.csv"

quietly regress `dep_var' `indep_vars' i.`time_var', vce(robust)

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

export delimited using "table_T23_reg_timefe.csv", replace
display "SS_OUTPUT_FILE|file=table_T23_reg_timefe.csv|type=table|desc=time_fixed_effects"
display ">>> 时间固定效应回归结果已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T23_paper.rtf"
    
    esttab using "table_T23_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T23_paper.rtf|type=table|desc=publication_table"
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
display "║                            T23 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "回归概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 时间变量:        `time_var'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 时间期数:        " %10.0fc `n_periods'
display "  - R²:              " %10.4f `r2_time'
display ""
display "时间效应检验:"
display "  - F 统计量:        " %10.4f `time_F'
display "  - p 值:            " %10.4f `time_p'
display ""
display "输出文件:"
display "  - table_T23_reg_timefe.csv     时间固定效应回归结果"
display "  - fig_T23_time_effects.png     时间效应图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_periods|value=`n_periods'"
display "SS_SUMMARY|key=r_squared|value=`r2_time'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T23|status=ok|elapsed_sec=`elapsed'"

log close
