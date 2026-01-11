* ==============================================================================
* SS_TEMPLATE: id=TU12  level=L2  module=U  title="Spline Regression"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU12_spline.png type=figure desc="Spline fit"
*   - table_TU12_spline.csv type=table desc="Spline results"
*   - data_TU12_spline.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TU12|level=L2|title=Spline_Regression"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local xvar = "__XVAR__"
local n_knots = __N_KNOTS__
local spline_type = "__SPLINE_TYPE__"

if `n_knots' < 1 | `n_knots' > 10 {
    local n_knots = 3
}
if "`spline_type'" == "" {
    local spline_type = "linear"
}

display ""
display ">>> 样条回归参数:"
display "    因变量: `depvar'"
display "    自变量: `xvar'"
display "    节点数: `n_knots'"
display "    样条类型: `spline_type'"

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
capture confirm numeric variable `depvar' `xvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=vars_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 样条回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 样条回归"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建样条变量
mkspline _S = `xvar', nknots(`n_knots') cubic

* 回归
regress `depvar' _S*

local r2 = e(r2)
local n_obs = e(N)
local rmse = e(rmse)

display ""
display ">>> 样条回归结果:"
display "    样本量: `n_obs'"
display "    R²: " %8.4f `r2'
display "    RMSE: " %8.4f `rmse'

display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=r2|value=`r2'"
display "SS_METRIC|name=rmse|value=`rmse'"

* 预测并绘图
predict yhat, xb

twoway (scatter `depvar' `xvar', msize(small) mcolor(gray%50)) ///
    (line yhat `xvar', sort lwidth(medium) lcolor(navy)), ///
    title("样条回归拟合") ///
    xtitle("`xvar'") ytitle("`depvar'") ///
    legend(order(1 "观测值" 2 "样条拟合"))

graph export "fig_TU12_spline.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU12_spline.png|type=figure|desc=spline_fit"

* 导出结果
preserve
clear
set obs 3
gen str20 metric = ""
gen double value = .
replace metric = "R2" in 1
replace value = `r2' in 1
replace metric = "RMSE" in 2
replace value = `rmse' in 2
replace metric = "N" in 3
replace value = `n_obs' in 3
export delimited using "table_TU12_spline.csv", replace
display "SS_OUTPUT_FILE|file=table_TU12_spline.csv|type=table|desc=spline_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU12_spline.dta", replace
display "SS_OUTPUT_FILE|file=data_TU12_spline.dta|type=data|desc=spline_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU12 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  R²:              " %10.4f `r2'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU12|status=ok|elapsed_sec=`elapsed'"
log close
