* ==============================================================================
* SS_TEMPLATE: id=TU13  level=L2  module=U  title="Local Polynomial"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU13_lpoly.png type=figure desc="Local polynomial fit"
*   - table_TU13_lpoly.csv type=table desc="Lpoly results"
*   - data_TU13_lpoly.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TU13|level=L2|title=Local_Polynomial"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local yvar = "__YVAR__"
local xvar = "__XVAR__"
local degree = __DEGREE__
local bandwidth = __BANDWIDTH__

if `degree' < 0 | `degree' > 6 {
    local degree = 1
}
if `bandwidth' <= 0 {
    local bandwidth = 0
}

display ""
display ">>> 局部多项式回归参数:"
display "    因变量: `yvar'"
display "    自变量: `xvar'"
display "    多项式阶数: `degree'"
display "    带宽: " cond(`bandwidth' == 0, "auto", "`bandwidth'")

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm numeric variable `yvar' `xvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=vars_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 局部多项式回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 局部多项式回归"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建lpoly命令
local bw_opt ""
if `bandwidth' > 0 {
    local bw_opt "bwidth(`bandwidth')"
}

lpoly `yvar' `xvar', degree(`degree') `bw_opt' generate(xgrid yhat) nograph

* 绘图
twoway (scatter `yvar' `xvar', msize(small) mcolor(gray%50)) ///
    (line yhat xgrid, sort lwidth(medium) lcolor(navy)), ///
    title("局部多项式回归") ///
    subtitle("阶数=`degree'") ///
    xtitle("`xvar'") ytitle("`yvar'") ///
    legend(order(1 "观测值" 2 "局部多项式拟合"))

graph export "fig_TU13_lpoly.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU13_lpoly.png|type=figure|desc=lpoly_fit"

display ""
display ">>> 局部多项式回归完成"
display "    样本量: `n_input'"
display "    多项式阶数: `degree'"

display "SS_METRIC|name=n_obs|value=`n_input'"
display "SS_METRIC|name=degree|value=`degree'"

* 导出结果
preserve
keep xgrid yhat
drop if missing(xgrid)
export delimited using "table_TU13_lpoly.csv", replace
display "SS_OUTPUT_FILE|file=table_TU13_lpoly.csv|type=table|desc=lpoly_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU13_lpoly.dta", replace
display "SS_OUTPUT_FILE|file=data_TU13_lpoly.dta|type=data|desc=lpoly_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU13 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  多项式阶数:      " %10.0f `degree'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=degree|value=`degree'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU13|status=ok|elapsed_sec=`elapsed'"
log close
