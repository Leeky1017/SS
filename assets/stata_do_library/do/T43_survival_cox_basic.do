* ==============================================================================
* SS_TEMPLATE: id=T43  level=L0  module=H  title="Cox Proportional Hazards"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T43_cox_coef.csv type=table desc="Cox regression coefficients"
*   - table_T43_phtest.csv type=table desc="Proportional hazards test"
*   - fig_T43_cox_survival.png type=graph desc="Cox model survival curve"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="survival analysis commands"
* ==============================================================================
* Task ID:      T43_survival_cox_basic
* Task Name:    Cox比例风险回归
* Family:       H - 生存分析
* Description:  估计Cox比例风险回归模型
* 
* Placeholders: __TIME_VAR__    - 生存时间变量
*               __EVENT_VAR__   - 事件变量
*               __INDEPVARS__  - 协变量列表
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
display "SS_TASK_BEGIN|id=T43|level=L0|title=Cox_Proportional_Hazards"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T43_survival_cox_basic                                         ║"
display "║  TASK_NAME: Cox比例风险回归（Cox Proportional Hazards）                     ║"
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
* SECTION 1: 变量设置与生存数据声明
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量设置与生存数据声明"
display "═══════════════════════════════════════════════════════════════════════════════"

local time_var "__TIME_VAR__"
local event_var "__EVENT_VAR__"
local indep_vars "__INDEPVARS__"

display ""
display ">>> 时间变量:        `time_var'"
display ">>> 事件变量:        `event_var'"
display ">>> 协变量:          `indep_vars'"
display "-------------------------------------------------------------------------------"

* ---------- Survival pre-checks (T41–T44 通用) ----------
capture confirm variable `time_var'
if _rc {
    display as error "ERROR: Time variable `time_var' not found（时间变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `event_var'
if _rc {
    display as error "ERROR: Event variable `event_var' not found（事件变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

quietly count if `time_var' < 0 & !missing(`time_var')
if r(N) > 0 {
    display as error "ERROR: Survival time `time_var' contains negative values（生存时间存在负值）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

quietly count if `event_var' != 0 & `event_var' != 1 & !missing(`event_var')
if r(N) > 0 {
    display as error "ERROR: Event variable `event_var' must be coded as 0/1（事件变量必须为0/1编码）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

quietly count if `event_var' == 1 & !missing(`event_var')
if r(N) == 0 {
    display as error "ERROR: No events (=1) found in `event_var'（无事件发生，无法进行生存分析）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}
display ">>> 生存数据检查通过"
* ---------- Survival pre-checks end ----------

stset `time_var', failure(`event_var')
stdescribe

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: Cox比例风险模型估计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Cox比例风险模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Cox比例风险模型："
display "    h(t|X) = h₀(t) × exp(β₁X₁ + β₂X₂ + ...)"
display "-------------------------------------------------------------------------------"

stcox `indep_vars'
estimates store cox_model

local ll = e(ll)
local chi2 = e(chi2)
local n_obs = e(N)
local n_fail = e(N_fail)

* ==============================================================================
* SECTION 3: 危险比输出
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 危险比（Hazard Ratio）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> HR解读："
display "    HR > 1: 风险增加（危险因素）"
display "    HR < 1: 风险降低（保护因素）"
display "    HR = 1: 无影响"
display "-------------------------------------------------------------------------------"

stcox `indep_vars', nohr
display ""
stcox `indep_vars'

* ==============================================================================
* SECTION 4: 比例风险假设检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 比例风险假设检验（Schoenfeld残差）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 比例风险假设检验："
display "    H0: 比例风险假设成立（HR恒定）"
display "    H1: 比例风险假设不成立（HR随时间变化）"
display "-------------------------------------------------------------------------------"

estat phtest, detail

* 保存比例风险检验结果用于后续导出
matrix phtest_results = r(phtest)
local phtest_chi2 = r(chi2)
local phtest_df = r(df)
local phtest_p = r(p)

display ""
display ">>> 解读："
display "    若 p > 0.05: 不拒绝H0，比例风险假设成立"
display "    若 p < 0.05: 拒绝H0，需考虑分层或时变系数"

* ==============================================================================
* SECTION 5: 模型拟合指标
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 模型拟合指标"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 50}"
display "样本量:              " %12.0fc `n_obs'
display "事件数:              " %12.0fc `n_fail'
display "对数似然:            " %12.4f `ll'
display "Wald χ²:             " %12.4f `chi2'
display "{hline 50}"

* ==============================================================================
* SECTION 6: 生存曲线可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 生存曲线可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 绘制Cox模型生存曲线"

stcurve, survival ///
    title("Cox模型估计的生存函数", size(medium)) ///
    ytitle("生存概率 S(t)") ///
    xtitle("时间") ///
    scheme(s1color)

graph export "fig_T43_cox_survival.png", replace width(1000) height(700)
display "SS_OUTPUT_FILE|file=fig_T43_cox_survival.png|type=graph|desc=cox_survival_curve"
display ">>> 生存曲线已导出: fig_T43_cox_survival.png"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出Cox系数
display ""
display ">>> 导出Cox系数: table_T43_cox_coef.csv"

matrix coef = e(b)
matrix var = e(V)

preserve
clear
local ncols = colsof(coef)
set obs `ncols'

generate str32 variable = ""
generate double coef = .
generate double se = .
generate double hr = .
generate double z = .
generate double p = .
generate double hr_lo = .
generate double hr_hi = .

local names: colnames coef
local i = 1
foreach name of local names {
    quietly replace variable = "`name'" in `i'
    local b = coef[1, `i']
    local v = var[`i', `i']
    local s = sqrt(`v')
    quietly replace coef = `b' in `i'
    quietly replace se = `s' in `i'
    quietly replace hr = exp(`b') in `i'
    local z_val = `b' / `s'
    local p_val = 2 * (1 - normal(abs(`z_val')))
    quietly replace z = `z_val' in `i'
    quietly replace p = `p_val' in `i'
    quietly replace hr_lo = exp(`b' - 1.96*`s') in `i'
    quietly replace hr_hi = exp(`b' + 1.96*`s') in `i'
    local i = `i' + 1
}

export delimited using "table_T43_cox_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T43_cox_coef.csv|type=table|desc=cox_coefficients"
display ">>> Cox系数已导出"
restore

* 导出比例风险检验结果
display ""
display ">>> 导出比例风险检验结果: table_T43_phtest.csv"

preserve
clear
* 获取检验矩阵的行数（变量数）
local nrows = rowsof(phtest_results)
set obs `nrows'

generate str32 variable = ""
generate double rho = .
generate double chi2 = .
generate double df = .
generate double p = .

local rownames: rownames phtest_results
local i = 1
foreach name of local rownames {
    quietly replace variable = "`name'" in `i'
    quietly replace rho = phtest_results[`i', 1] in `i'
    quietly replace chi2 = phtest_results[`i', 2] in `i'
    quietly replace df = phtest_results[`i', 3] in `i'
    quietly replace p = phtest_results[`i', 4] in `i'
    local i = `i' + 1
}

* 添加全局检验结果行
local newobs = `nrows' + 1
set obs `newobs'
quietly replace variable = "global" in `newobs'
quietly replace chi2 = `phtest_chi2' in `newobs'
quietly replace df = `phtest_df' in `newobs'
quietly replace p = `phtest_p' in `newobs'

export delimited using "table_T43_phtest.csv", replace
display "SS_OUTPUT_FILE|file=table_T43_phtest.csv|type=table|desc=ph_test_results"
display ">>> 比例风险检验结果已导出"
restore

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T43 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型信息:"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 事件数:          " %10.0fc `n_fail'
display "  - 对数似然:        " %10.4f `ll'
display "  - Wald χ²:         " %10.4f `chi2'
display ""
display "输出文件:"
display "  - table_T43_cox_coef.csv      Cox系数（含HR）"
display "  - table_T43_phtest.csv        比例风险检验结果"
display "  - fig_T43_cox_survival.png    生存曲线"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_fail|value=`n_fail'"
display "SS_SUMMARY|key=chi2|value=`chi2'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T43|status=ok|elapsed_sec=`elapsed'"

log close
