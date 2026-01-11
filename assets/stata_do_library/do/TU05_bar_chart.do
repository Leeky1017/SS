* ==============================================================================
* SS_TEMPLATE: id=TU05  level=L1  module=U  title="Bar Chart"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU05_bar.png type=figure desc="Bar chart"
*   - data_TU05_bar.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TU05|level=L1|title=Bar_Chart"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local var = "__VAR__"
local cat_var = "__CAT_VAR__"
local stat = "__STAT__"

if "`stat'" == "" {
    local stat = "mean"
}

display ""
display ">>> 柱状图参数:"
display "    数值变量: `var'"
display "    分类变量: `cat_var'"
display "    统计量: `stat'"

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

capture confirm variable `cat_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable|msg=cat_var_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 绘制柱状图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 绘制柱状图"
display "═══════════════════════════════════════════════════════════════════════════════"

graph bar (`stat') `var', over(`cat_var') ///
    title("柱状图: `var' by `cat_var'") ///
    ytitle("`=upper("`stat'")' of `var'") ///
    blabel(bar, format(%9.2f))

graph export "fig_TU05_bar.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU05_bar.png|type=figure|desc=bar_chart"

quietly summarize `var'
local overall = r(mean)
display "SS_METRIC|name=overall_mean|value=`overall'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU05_bar.dta", replace
display "SS_OUTPUT_FILE|file=data_TU05_bar.dta|type=data|desc=bar_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  统计量:          `stat'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=overall_mean|value=`overall'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU05|status=ok|elapsed_sec=`elapsed'"
log close
