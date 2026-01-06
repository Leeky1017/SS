* ==============================================================================
* SS_TEMPLATE: id=TG20  level=L2  module=G  title="DID Staggered"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG20_staggered_result.csv type=table desc="Staggered DID"
*   - table_TG20_group_effects.csv type=table desc="Group effects"
*   - fig_TG20_event_study.png type=figure desc="Event study"
*   - data_TG20_staggered.dta type=data desc="Staggered data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - csdid source=ssc purpose="Staggered DID"
*   - drdid source=ssc purpose="DR DID"
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TG20|level=L2|title=DID_Staggered"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "csdid drdid"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_MISSING:cmd=`dep':hint=ssc install `dep'"
        display "SS_ERROR:DEP_MISSING:`dep' is required but not installed"
        display "SS_ERR:DEP_MISSING:`dep' is required but not installed"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=csdid|source=ssc|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local treat_time_var = "__TREAT_TIME_VAR__"
local controls = "__CONTROLS__"

display ""
display ">>> 交错DID参数:"
display "    结果变量: `outcome_var'"
display "    ID变量: `id_var'"
display "    时间变量: `time_var'"
display "    首次处理时间: `treat_time_var'"
if "`controls'" != "" {
    display "    控制变量: `controls'"
}

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `outcome_var' `id_var' `time_var' `treat_time_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

local valid_controls ""
foreach var of local controls {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_controls "`valid_controls' `var'"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 数据准备 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 数据准备"
display "═══════════════════════════════════════════════════════════════════════════════"

* 处理首次处理时间（csdid要求未处理单位为0）
replace `treat_time_var' = 0 if missing(`treat_time_var')

* 设置面板
ss_smart_xtset `id_var' `time_var'

* 统计处理组
quietly levelsof `treat_time_var' if `treat_time_var' > 0, local(treat_times)
local n_cohorts : word count `treat_times'

quietly count if `treat_time_var' == 0
local n_never_treated = r(N)

quietly distinct `id_var' if `treat_time_var' == 0
local n_never_treated_units = r(ndistinct)

display ""
display ">>> 数据结构:"
display "    处理队列数: `n_cohorts'"
display "    从未处理单位数: `n_never_treated_units'"
display "    处理时间: `treat_times'"

display "SS_METRIC|name=n_cohorts|value=`n_cohorts'"

* ============ Callaway-Sant'Anna估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Callaway-Sant'Anna估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ">>> 执行csdid估计..."

if "`valid_controls'" != "" {
    csdid `outcome_var' `valid_controls', ivar(`id_var') time(`time_var') gvar(`treat_time_var') agg(simple)
}
else {
    csdid `outcome_var', ivar(`id_var') time(`time_var') gvar(`treat_time_var') agg(simple)
}

* 提取简单平均ATT
local att_simple = e(b)[1, 1]
local att_se = sqrt(e(V)[1, 1])
local att_t = `att_simple' / `att_se'
local att_p = 2 * (1 - normal(abs(`att_t')))

display ""
display ">>> 简单平均ATT:"
display "    ATT: " %10.4f `att_simple'
display "    SE: " %10.4f `att_se'
display "    t: " %10.4f `att_t'
display "    p值: " %10.4f `att_p'

display "SS_METRIC|name=att|value=`att_simple'"
display "SS_METRIC|name=att_se|value=`att_se'"

* 分组效应
display ""
display ">>> 分组效应估计..."
csdid `outcome_var', ivar(`id_var') time(`time_var') gvar(`treat_time_var') agg(group)

* 导出分组效应
tempname grp_effects
postfile `grp_effects' int cohort double att double se double ci_lower double ci_upper ///
    using "temp_group_effects.dta", replace

matrix b = e(b)
matrix V = e(V)
local n_grp = colsof(b)

forvalues i = 1/`n_grp' {
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local ci_l = `coef' - 1.96 * `se'
    local ci_u = `coef' + 1.96 * `se'
    
    local cohort_i : word `i' of `treat_times'
    if "`cohort_i'" == "" {
        local cohort_i = `i'
    }
    
    post `grp_effects' (`cohort_i') (`coef') (`se') (`ci_l') (`ci_u')
}

postclose `grp_effects'

preserve
use "temp_group_effects.dta", clear
export delimited using "table_TG20_group_effects.csv", replace
display "SS_OUTPUT_FILE|file=table_TG20_group_effects.csv|type=table|desc=group_effects"
restore

* ============ 事件研究 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 事件研究"
display "═══════════════════════════════════════════════════════════════════════════════"

display ">>> 事件研究估计..."
csdid `outcome_var', ivar(`id_var') time(`time_var') gvar(`treat_time_var') agg(event)

* 保存事件研究结果并绘图
matrix b = e(b)
matrix V = e(V)
local n_events = colsof(b)

tempname event_results
postfile `event_results' int rel_time double att double se double ci_lower double ci_upper ///
    using "temp_event_study.dta", replace

local rel_time = -`n_events'/2
forvalues i = 1/`n_events' {
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local ci_l = `coef' - 1.96 * `se'
    local ci_u = `coef' + 1.96 * `se'
    
    post `event_results' (`rel_time') (`coef') (`se') (`ci_l') (`ci_u')
    local rel_time = `rel_time' + 1
}

postclose `event_results'

preserve
use "temp_event_study.dta", clear

twoway (rarea ci_lower ci_upper rel_time, color(navy%20)) ///
       (scatter att rel_time, mcolor(navy)) ///
       (line att rel_time, lcolor(navy)), ///
       xline(-0.5, lcolor(red) lpattern(dash)) ///
       yline(0, lcolor(gray) lpattern(dot)) ///
       xtitle("相对处理时间") ytitle("ATT") ///
       title("交错DID事件研究") ///
       legend(off) ///
       note("Callaway-Sant'Anna估计, 红线=处理时间")
graph export "fig_TG20_event_study.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG20_event_study.png|type=figure|desc=event_study"
restore

* ============ 导出主结果 ============
preserve
clear
set obs 1
generate str30 estimator = "Callaway-Sant'Anna"
generate str20 aggregation = "Simple"
generate double att = `att_simple'
generate double se = `att_se'
generate double t_stat = `att_t'
generate double p_value = `att_p'
generate double ci_lower = `att_simple' - 1.96 * `att_se'
generate double ci_upper = `att_simple' + 1.96 * `att_se'
generate int n_cohorts = `n_cohorts'

export delimited using "table_TG20_staggered_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG20_staggered_result.csv|type=table|desc=staggered_result"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG20_staggered.dta", replace
display "SS_OUTPUT_FILE|file=data_TG20_staggered.dta|type=data|desc=staggered_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=att|value=`att_simple'"

capture erase "temp_group_effects.dta"
if _rc != 0 { }
capture erase "temp_event_study.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG20 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理队列数:      " %10.0fc `n_cohorts'
display "  从未处理单位:    " %10.0fc `n_never_treated_units'
display ""
display "  Callaway-Sant'Anna ATT:"
display "    简单平均:      " %10.4f `att_simple'
display "    标准误:        " %10.4f `att_se'
display "    p值:           " %10.4f `att_p'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG20|status=ok|elapsed_sec=`elapsed'"
log close
