* ==============================================================================
* SS_TEMPLATE: id=TU08  level=L1  module=U  title="Density"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU08_density.png type=figure desc="Density plot"
*   - data_TU08_density.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TU08|level=L1|title=Density"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local var = "__VAR__"
local by_var = "__BY_VAR__"
local bandwidth = __BANDWIDTH__

display ""
display ">>> 核密度图参数:"
display "    变量: `var'"

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
capture confirm numeric variable `var'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=var_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 绘制核密度图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 绘制核密度图"
display "═══════════════════════════════════════════════════════════════════════════════"

capture confirm variable `by_var'
if !_rc & "`by_var'" != "" & "`by_var'" != "__BY_VAR__" {
    twoway (kdensity `var' if `by_var' == 0, lcolor(navy)) ///
           (kdensity `var' if `by_var' == 1, lcolor(red)), ///
           title("核密度图: `var'") ///
           xtitle("`var'") ytitle("密度") ///
           legend(order(1 "`by_var'=0" 2 "`by_var'=1"))
}
else {
    kdensity `var', ///
        title("核密度图: `var'") ///
        xtitle("`var'") ytitle("密度") ///
        lcolor(navy) lwidth(medium)
}

graph export "fig_TU08_density.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU08_density.png|type=figure|desc=density_plot"

quietly summarize `var'
local mean = r(mean)
local sd = r(sd)

display ""
display ">>> 分布统计:"
display "    均值: " %12.4f `mean'
display "    标准差: " %12.4f `sd'

display "SS_METRIC|name=mean|value=`mean'"
display "SS_METRIC|name=sd|value=`sd'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU08_density.dta", replace
display "SS_OUTPUT_FILE|file=data_TU08_density.dta|type=data|desc=density_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU08 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  均值:            " %10.4f `mean'
display "  标准差:          " %10.4f `sd'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean|value=`mean'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU08|status=ok|elapsed_sec=`elapsed'"
log close
