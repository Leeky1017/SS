* ==============================================================================
* SS_TEMPLATE: id=TU02  level=L1  module=U  title="Scatter"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU02_scatter.png type=figure desc="Scatter plot"
*   - data_TU02_scatter.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TU02|level=L1|title=Scatter"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local xvar = "__XVAR__"
local yvar = "__YVAR__"
local fitline = "__FITLINE__"
local group_var = "__GROUP_VAR__"

if "`fitline'" == "" {
    local fitline = "linear"
}

display ""
display ">>> 散点图参数:"
display "    X变量: `xvar'"
display "    Y变量: `yvar'"
display "    拟合线: `fitline'"

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

* ============ 变量检查 ============
foreach var in `xvar' `yvar' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm numeric variable|msg=var_not_found|severity=fail"
        log close
        exit 200
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 相关性分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 相关性分析"
display "═══════════════════════════════════════════════════════════════════════════════"

correlate `xvar' `yvar'
local corr = r(rho)

display ""
display ">>> 相关系数: " %8.4f `corr'

display "SS_METRIC|name=correlation|value=`corr'"

* ============ 绘制散点图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 绘制散点图"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`fitline'" == "linear" {
    twoway (scatter `yvar' `xvar', mcolor(navy%50) msize(small)) ///
           (lfit `yvar' `xvar', lcolor(red) lwidth(medium)), ///
           title("散点图: `yvar' vs `xvar'") ///
           xtitle("`xvar'") ytitle("`yvar'") ///
           note("N=`n_input', r=`=round(`corr', 0.001)'") ///
           legend(order(1 "观测值" 2 "线性拟合"))
}
else if "`fitline'" == "lowess" {
    twoway (scatter `yvar' `xvar', mcolor(navy%50) msize(small)) ///
           (lowess `yvar' `xvar', lcolor(red) lwidth(medium)), ///
           title("散点图: `yvar' vs `xvar'") ///
           xtitle("`xvar'") ytitle("`yvar'") ///
           note("N=`n_input', r=`=round(`corr', 0.001)'") ///
           legend(order(1 "观测值" 2 "Lowess拟合"))
}
else {
    twoway (scatter `yvar' `xvar', mcolor(navy%50) msize(small)), ///
           title("散点图: `yvar' vs `xvar'") ///
           xtitle("`xvar'") ytitle("`yvar'") ///
           note("N=`n_input', r=`=round(`corr', 0.001)'")
}

graph export "fig_TU02_scatter.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU02_scatter.png|type=figure|desc=scatter_plot"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU02_scatter.dta", replace
display "SS_OUTPUT_FILE|file=data_TU02_scatter.dta|type=data|desc=scatter_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  相关系数:        " %10.4f `corr'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=correlation|value=`corr'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU02|status=ok|elapsed_sec=`elapsed'"
log close
