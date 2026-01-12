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

* BEST_PRACTICE_REVIEW (EN):
* - Pie charts are hard to compare across categories; prefer bar charts when there are many slices or small differences.
* - Ensure the measure is non-negative and meaningful for shares; document whether wedges represent counts or summed values.
* - Sort categories and label clearly; consider aggregating tiny slices into "Other".
* 最佳实践审查（ZH）:
* - 饼图不利于跨类别比较；类别多或差异小更建议用柱状图。
* - 扇区度量需非负且有意义；请明确扇区代表计数还是数值求和占比。
* - 建议排序并清晰标注；可将极小类别合并为“其他”。

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
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate category variable and optional weight/value variable.
* ZH: 校验分类变量与可选权重/数值变量。

* ============ 变量检查 ============
capture confirm variable `cat_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable|msg=cat_var_not_found|severity=fail"
    log close
    exit 200
}
local use_weighted = 0
if "`value_var'" != "" & "`value_var'" != "__VALUE_VAR__" {
    capture confirm numeric variable `value_var'
    if _rc {
        display "SS_RC|code=10|cmd=confirm numeric variable|msg=value_var_not_numeric_ignored|var=`value_var'|severity=warn"
    }
    else {
        quietly count if `value_var' < 0 & !missing(`value_var')
        if r(N) > 0 {
            display "SS_RC|code=10|cmd=value_check|msg=value_var_negative_ignored|var=`value_var'|severity=warn"
        }
        else {
            local use_weighted = 1
        }
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Compute shares and export pie chart figure/table.
* ZH: 计算占比并导出饼图与表格。

* ============ 计算占比 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 计算占比"
display "═══════════════════════════════════════════════════════════════════════════════"

if `use_weighted' == 1 {
    collapse (sum) count = `value_var', by(`cat_var')
    quietly summarize count
    local total = r(sum)
    if `total' <= 0 {
        display "SS_RC|code=112|cmd=collapse|msg=nonpositive_total_fallback_to_counts|severity=warn"
        contract `cat_var', freq(count)
        generate double percentage = count / `n_input' * 100
    }
    else {
        generate double percentage = count / `total' * 100
    }
}
else {
    contract `cat_var', freq(count)
    generate double percentage = count / `n_input' * 100
}

gsort -count

display ""
display ">>> 各类占比:"
list `cat_var' count percentage, noobs

local n_cats = _N
display ""
display ">>> 类别数: `n_cats'"

display "SS_METRIC|name=n_categories|value=`n_cats'"

* 导出占比数据
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
