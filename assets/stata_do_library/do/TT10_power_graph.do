* ==============================================================================
* SS_TEMPLATE: id=TT10  level=L1  module=T  title="Power Graph"
* INPUTS:
*   - (parameters only)
* OUTPUTS:
*   - fig_TT10_power_curve.png type=figure desc="Power curve"
*   - table_TT10_power.csv type=table desc="Power results"
*   - data_TT10_power.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
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

display "SS_TASK_BEGIN|id=TT10|level=L1|title=Power_Graph"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local test_type = "__TEST_TYPE__"
local effect_min = __EFFECT_MIN__
local effect_max = __EFFECT_MAX__
local alpha = __ALPHA__
local n_sample = __N_SAMPLE__

if "`test_type'" == "" | "`test_type'" == "__TEST_TYPE__" { local test_type = "twomeans" }
if `effect_min' <= 0 { local effect_min = 0.1 }
if `effect_max' <= `effect_min' { local effect_max = 1.0 }
if `alpha' <= 0 | `alpha' >= 1 { local alpha = 0.05 }
if `n_sample' < 10 { local n_sample = 100 }

display ""
display ">>> 功效曲线参数:"
display "    检验类型: `test_type'"
display "    效应量范围: `effect_min' - `effect_max'"
display "    显著性水平: `alpha'"
display "    样本量: `n_sample'"

display "SS_STEP_BEGIN|step=S01_load_data"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 功效曲线计算 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 功效曲线计算与可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

* 生成效应量序列
local n_points = 20
local step = (`effect_max' - `effect_min') / (`n_points' - 1)

clear
set obs `n_points'
gen double effect_size = `effect_min' + (_n - 1) * `step'
gen double power = .
gen double alpha = `alpha'
gen int n = `n_sample'

* 计算每个效应量对应的功效
forvalues i = 1/`n_points' {
    local eff = effect_size[`i']
    
    if "`test_type'" == "twomeans" {
        quietly power twomeans 0 `eff', n(`n_sample') alpha(`alpha')
        replace power = r(power) in `i'
    }
    else if "`test_type'" == "oneproportion" {
        local p1 = 0.5 + `eff'/2
        if `p1' > 0.99 { local p1 = 0.99 }
        quietly power oneproportion 0.5 `p1', n(`n_sample') alpha(`alpha')
        replace power = r(power) in `i'
    }
    else {
        * 默认使用 twomeans
        quietly power twomeans 0 `eff', n(`n_sample') alpha(`alpha')
        replace power = r(power) in `i'
    }
}

* ============ 绘制功效曲线 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 绘制功效曲线"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway (line power effect_size, lwidth(medium) lcolor(navy)) ///
    (scatter power effect_size, msize(small) mcolor(navy)), ///
    title("功效曲线") ///
    subtitle("样本量=`n_sample', α=`alpha'") ///
    xtitle("效应量") ytitle("检验功效") ///
    ylabel(0(0.2)1, format(%3.1f)) ///
    yline(0.8, lpattern(dash) lcolor(red)) ///
    legend(off) ///
    note("红色虚线表示80%功效水平")

graph export "fig_TT10_power_curve.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TT10_power_curve.png|type=figure|desc=power_curve"

* 导出数据
export delimited using "table_TT10_power.csv", replace
display "SS_OUTPUT_FILE|file=table_TT10_power.csv|type=table|desc=power_results"

local n_input = 1
local n_output = `n_points'
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT10_power.dta", replace
display "SS_OUTPUT_FILE|file=data_TT10_power.dta|type=data|desc=power_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT10 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  检验类型:        `test_type'"
display "  效应量范围:      `effect_min' - `effect_max'"
display "  样本量:          " %10.0f `n_sample'
display "  计算点数:        " %10.0f `n_points'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_points|value=`n_points'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TT10|status=ok|elapsed_sec=`elapsed'"
log close
