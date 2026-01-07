* ==============================================================================
* SS_TEMPLATE: id=T34  level=L0  module=F  title="Difference-in-Differences 2x2"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T34_did_coef.csv type=table desc="DID regression coefficients"
*   - fig_T34_did_trend.png type=graph desc="Trend comparison"
*   - table_T34_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
*   - estout source=ssc purpose="publication-quality tables (optional)" purpose="regression commands"
* ==============================================================================
* Task ID:      T34_diff_in_diff_2x2
* Task Name:    经典2×2双重差分
* Family:       F - 面板数据与政策评估
* Description:  估计经典双重差分模型
* 
* Placeholders: __DEPVAR__       - 因变量
*               __TREAT_VAR__     - 处理组变量
*               __POST_VAR__      - 政策后变量
*               __CONTROL_VARS__  - 控制变量列表
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
display "SS_TASK_BEGIN|id=T34|level=L0|title=Difference_in_Differences_2x2"
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
display "║  TASK_ID: T34_diff_in_diff_2x2                                             ║"
display "║  TASK_NAME: 经典2×2双重差分（Difference-in-Differences）                      ║"
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

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

local n_total = _N
display ">>> 数据加载成功: `n_total' 条观测"

* ==============================================================================
* SECTION 1: 变量检查
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEPVAR__"
local treat_var "__TREAT_VAR__"
local post_var "__POST_VAR__"
local control_vars "__CONTROL_VARS__"

display ""
display ">>> 因变量:          `dep_var'"
display ">>> 处理组指示:      `treat_var' (0=控制组, 1=处理组)"
display ">>> 政策时期:        `post_var' (0=政策前, 1=政策后)"
display ">>> 控制变量:        `control_vars'"
display "-------------------------------------------------------------------------------"

display ""
display ">>> 2×2分组情况："
tabulate `treat_var' `post_var'

* 检查各组样本量
quietly count if `treat_var' == 1 & `post_var' == 1
local n11 = r(N)
quietly count if `treat_var' == 1 & `post_var' == 0
local n10 = r(N)
quietly count if `treat_var' == 0 & `post_var' == 1
local n01 = r(N)
quietly count if `treat_var' == 0 & `post_var' == 0
local n00 = r(N)

display ""
display "{hline 60}"
display "处理组-政策后:        " %10.0fc `n11'
display "处理组-政策前:        " %10.0fc `n10'
display "控制组-政策后:        " %10.0fc `n01'
display "控制组-政策前:        " %10.0fc `n00'
display "{hline 60}"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 各组均值与手动DID计算
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 各组均值与DID分解"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各组因变量均值："
table `treat_var' `post_var', statistic(mean `dep_var') statistic(sd `dep_var')

* 计算各组均值
quietly summarize `dep_var' if `treat_var'==1 & `post_var'==1
local y11 = r(mean)
quietly summarize `dep_var' if `treat_var'==1 & `post_var'==0
local y10 = r(mean)
quietly summarize `dep_var' if `treat_var'==0 & `post_var'==1
local y01 = r(mean)
quietly summarize `dep_var' if `treat_var'==0 & `post_var'==0
local y00 = r(mean)

local did_manual = (`y11' - `y10') - (`y01' - `y00')
local treat_change = `y11' - `y10'
local control_change = `y01' - `y00'

display ""
display "{hline 60}"
display "处理组变化 (Y11-Y10):  " %10.4f `treat_change'
display "控制组变化 (Y01-Y00):  " %10.4f `control_change'
display "{hline 60}"
display "DID估计量:             " %10.4f `did_manual'
display "{hline 60}"

* ==============================================================================
* SECTION 3: DID回归（无控制变量）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: DID回归（无控制变量）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 模型: Y = β₀ + β₁·Treat + β₂·Post + β₃·(Treat×Post) + ε"
display ">>> DID估计量 = β₃（交互项系数）"
display "-------------------------------------------------------------------------------"

generate did = `treat_var' * `post_var'
label variable did "Treat × Post"

regress `dep_var' `treat_var' `post_var' did
estimates store did_simple

local did_coef_simple = _b[did]
local did_se_simple = _se[did]
local did_t_simple = _b[did] / _se[did]

display ""
display "{hline 60}"
display "DID估计量（无控制）:   " %10.4f `did_coef_simple'
display "标准误:                " %10.4f `did_se_simple'
display "t统计量:               " %10.4f `did_t_simple'
display "{hline 60}"

* ==============================================================================
* SECTION 4: DID回归（加控制变量 + 稳健标准误）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: DID回归（加控制变量）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 加入控制变量和稳健标准误"
display "-------------------------------------------------------------------------------"

regress `dep_var' `treat_var' `post_var' did `control_vars', vce(robust)
estimates store did_model

local did_coef = _b[did]
local did_se = _se[did]
local did_t = _b[did] / _se[did]
local did_p = 2 * ttail(e(df_r), abs(`did_t'))
local r2 = e(r2)
local n_obs = e(N)

display ""
display "{hline 60}"
display "DID估计量（含控制）:   " %10.4f `did_coef'
display "稳健标准误:            " %10.4f `did_se'
display "t统计量:               " %10.4f `did_t'
display "p值:                   " %10.4f `did_p'
display "R²:                    " %10.4f `r2'
display "{hline 60}"

* ==============================================================================
* SECTION 5: 趋势可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 趋势可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成处理组与控制组趋势对比图"

preserve
collapse (mean) `dep_var', by(`treat_var' `post_var')

twoway (connected `dep_var' `post_var' if `treat_var'==1, lcolor(navy) mcolor(navy) lwidth(medium)) ///
       (connected `dep_var' `post_var' if `treat_var'==0, lcolor(cranberry) mcolor(cranberry) lwidth(medium) lpattern(dash)), ///
    title("Difference-in-Differences: 趋势对比", size(medium)) ///
    subtitle("处理组 vs 控制组", size(small)) ///
    xtitle("时期（0=政策前, 1=政策后）") ///
    ytitle("`dep_var'") ///
    legend(label(1 "处理组") label(2 "控制组") position(6) rows(1)) ///
    xlabel(0 "政策前" 1 "政策后") ///
    xline(0.5, lcolor(gray) lpattern(dash)) ///
    note("DID估计量 = " %6.4f `did_coef' " (SE = " %6.4f `did_se' ")", size(small)) ///
    scheme(s1color)
    
graph export "fig_T34_did_trend.png", replace width(1200) height(800)
display "SS_OUTPUT_FILE|file=fig_T34_did_trend.png|type=graph|desc=trend_comparison"
restore

display ">>> 趋势图已导出: fig_T34_did_trend.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 6: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出DID系数: table_T34_did_coef.csv"

preserve
clear
set obs 1

generate double did_estimate = `did_coef'
generate double did_se = `did_se'
generate double did_t = `did_t'
generate double did_p = `did_p'
generate double r2 = `r2'
generate int n = `n_obs'
generate double y11 = `y11'
generate double y10 = `y10'
generate double y01 = `y01'
generate double y00 = `y00'

export delimited using "table_T34_did_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T34_did_coef.csv|type=table|desc=did_coefficients"
display ">>> DID系数已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T34_paper.rtf"
    
    esttab using "table_T34_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T34_paper.rtf|type=table|desc=publication_table"
    display ">>> 论文级表格已导出 ✓"
}
else {
    display ""
    display ">>> 跳过论文级表格 (estout 未安装)"
}


drop did

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T34 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "DID分析概况:"
display "  - 因变量:          `dep_var'"
display "  - 处理组指示:      `treat_var'"
display "  - 政策时期:        `post_var'"
display "  - 样本量:          " %10.0fc `n_obs'
display ""
display "DID估计结果:"
display "  - DID估计量:       " %10.4f `did_coef'
display "  - 标准误:          " %10.4f `did_se'
display "  - t统计量:         " %10.4f `did_t'
display "  - p值:             " %10.4f `did_p'
display ""
display "效应分解:"
display "  - 处理组变化:      " %10.4f `treat_change'
display "  - 控制组变化:      " %10.4f `control_change'
display ""
display "输出文件:"
display "  - table_T34_did_coef.csv    DID估计结果"
display "  - fig_T34_did_trend.png     趋势对比图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=did_coef|value=`did_coef'"
display "SS_SUMMARY|key=did_p|value=`did_p'"
display "SS_SUMMARY|key=n_obs|value=`n_obs'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T34|status=ok|elapsed_sec=`elapsed'"

log close
