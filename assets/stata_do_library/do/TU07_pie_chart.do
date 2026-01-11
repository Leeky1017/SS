* ==============================================================================
* SS_TEMPLATE: id=TU07  level=L1  module=U  title="Pie Chart"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU07_pie.png type=figure desc="Pie chart"
*   - table_TU07_pie_data.csv type=table desc="Pie data"
*   - data_TU07_pie.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TU07|level=L1|title=Pie_Chart"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local cat_var = "__CAT_VAR__"
local value_var = "__VALUE_VAR__"

display ""
display ">>> 饼图参数:"
display "    分类变量: `cat_var'"

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
capture confirm variable `cat_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable|msg=cat_var_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 计算占比 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 计算占比"
display "═══════════════════════════════════════════════════════════════════════════════"

contract `cat_var', freq(_count)
generate double _pct = _count / `n_input' * 100

gsort -_count

display ""
display ">>> 各类占比:"
list `cat_var' _count _pct, noobs

local n_cats = _N
display ""
display ">>> 类别数: `n_cats'"

display "SS_METRIC|name=n_categories|value=`n_cats'"

* 导出占比数据
rename _count count
rename _pct percentage
export delimited using "table_TU07_pie_data.csv", replace
display "SS_OUTPUT_FILE|file=table_TU07_pie_data.csv|type=table|desc=pie_data"

* ============ 绘制饼图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 绘制饼图"
display "═══════════════════════════════════════════════════════════════════════════════"

graph pie count, over(`cat_var') ///
    plabel(_all percent, format(%4.1f)) ///
    title("饼图: `cat_var' 分布") ///
    legend(position(3))

graph export "fig_TU07_pie.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU07_pie.png|type=figure|desc=pie_chart"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU07_pie.dta", replace
display "SS_OUTPUT_FILE|file=data_TU07_pie.dta|type=data|desc=pie_output"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU07 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  类别数:          " %10.0fc `n_cats'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_categories|value=`n_cats'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU07|status=ok|elapsed_sec=`elapsed'"
log close
