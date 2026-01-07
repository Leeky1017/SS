* ==============================================================================
* SS_TEMPLATE: id=T44  level=L0  module=H  title="Time-Varying Cox Model"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T44_cox_tv_coef.csv type=table desc="Time-varying Cox coefficients"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="survival analysis commands"
* ==============================================================================
* Task ID:      T44_survival_cox_time_varying
* Task Name:    时变协变量Cox模型
* Family:       H - 生存分析
* Description:  估计时变协变量Cox模型
* 
* Placeholders: __ID_VAR__      - 个体标识变量
*               __START_VAR__   - 区间起点变量
*               __STOP_VAR__    - 区间终点变量
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
display "SS_TASK_BEGIN|id=T44|level=L0|title=Time_Varying_Cox_Model"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T44_survival_cox_time_varying                                  ║"
display "║  TASK_NAME: 时变协变量Cox模型（Time-Varying Cox）                           ║"
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
display ">>> 数据加载成功: `n_total' 条记录"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 1: 变量设置与计数过程数据声明
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量设置与计数过程数据声明"
display "═══════════════════════════════════════════════════════════════════════════════"

local id_var "__ID_VAR__"
local start_var "__START_VAR__"
local stop_var "__STOP_VAR__"
local event_var "__EVENT_VAR__"
local indep_vars "__INDEPVARS__"

display ""
display ">>> 数据格式: 计数过程（每个风险区间一行）"
display ">>> ID变量:           `id_var'"
display ">>> 区间起点:         `start_var'"
display ">>> 区间终点:         `stop_var'"
display ">>> 事件变量:         `event_var'"
display ">>> 协变量:           `indep_vars'"
display "-------------------------------------------------------------------------------"

* ---------- Survival pre-checks (T44 时变协变量) ----------
capture confirm variable `id_var'
if _rc {
    display as error "ERROR: ID variable `id_var' not found（个体标识变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `start_var'
if _rc {
    display as error "ERROR: Start variable `start_var' not found（区间起点变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `stop_var'
if _rc {
    display as error "ERROR: Stop variable `stop_var' not found（区间终点变量不存在）."
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

quietly count if `stop_var' < 0 & !missing(`stop_var')
if r(N) > 0 {
    display as error "ERROR: Stop time `stop_var' contains negative values（终点时间存在负值）."
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

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 设置生存数据
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 设置生存数据（计数过程格式）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
stset `stop_var', failure(`event_var') enter(`start_var') id(`id_var')
stdescribe

quietly stsum
local n_subjects = r(N_sub)
local n_fail = r(N_fail)
local time_total = r(tr)

* ==============================================================================
* SECTION 3: 数据结构检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 数据结构检查"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 每个个体的记录数分布："
bysort `id_var': gen n_records = _N if _n == 1
tabulate n_records

display ""
display "{hline 50}"
display "个体数:              " %12.0fc `n_subjects'
display "总记录数:            " %12.0fc `n_total'
display "事件数:              " %12.0fc `n_fail'
display "平均记录数/人:       " %12.2f `n_total'/`n_subjects'
display "{hline 50}"

drop n_records

* ==============================================================================
* SECTION 4: 时变协变量Cox模型
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 时变协变量Cox模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 时变Cox模型："
display "    h(t|X(t)) = h₀(t) × exp(β'X(t))"
display "    协变量值可随时间变化"
display "-------------------------------------------------------------------------------"

stcox `indep_vars'
estimates store cox_tv

local ll = e(ll)
local chi2 = e(chi2)

* ==============================================================================
* SECTION 5: 危险比
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 危险比（Hazard Ratio）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
stcox `indep_vars', nohr
display ""
stcox `indep_vars'

* ==============================================================================
* SECTION 6: 比例风险假设检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 比例风险假设检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Schoenfeld残差检验："
estat phtest, detail

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出Cox系数: table_T44_cox_tv_coef.csv"

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

export delimited using "table_T44_cox_tv_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T44_cox_tv_coef.csv|type=table|desc=tv_cox_coefficients"
display ">>> Cox系数已导出"
restore

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T44 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "数据概况:"
display "  - 个体数:          " %10.0fc `n_subjects'
display "  - 总记录数:        " %10.0fc `n_total'
display "  - 事件数:          " %10.0fc `n_fail'
display ""
display "模型信息:"
display "  - 对数似然:        " %10.4f `ll'
display "  - Wald χ²:         " %10.4f `chi2'
display ""
display "输出文件:"
display "  - table_T44_cox_tv_coef.csv    Cox系数（含HR）"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_subjects|value=`n_subjects'"
display "SS_SUMMARY|key=n_fail|value=`n_fail'"
display "SS_SUMMARY|key=chi2|value=`chi2'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T44|status=ok|elapsed_sec=`elapsed'"

log close
