* ==============================================================================
* SS_TEMPLATE: id=TU03  level=L1  module=U  title="Boxplot"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU03_boxplot.png type=figure desc="Box plot"
*   - table_TU03_box_stats.csv type=table desc="Box stats"
*   - data_TU03_box.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TU03|level=L1|title=Boxplot"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local var = "__VAR__"
local by_var = "__BY_VAR__"

display ""
display ">>> 箱线图参数:"
display "    变量: `var'"
display "    分组: `by_var'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
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
capture confirm numeric variable `var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`var' not found"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 统计计算 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 箱线统计"
display "═══════════════════════════════════════════════════════════════════════════════"

summarize `var', detail

local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)
local iqr = `p75' - `p25'
local lower_fence = `p25' - 1.5 * `iqr'
local upper_fence = `p75' + 1.5 * `iqr'

display ""
display ">>> 箱线统计:"
display "    Q1 (25%): " %12.4f `p25'
display "    中位数: " %12.4f `p50'
display "    Q3 (75%): " %12.4f `p75'
display "    IQR: " %12.4f `iqr'
display "    下围栏: " %12.4f `lower_fence'
display "    上围栏: " %12.4f `upper_fence'

* 异常值计数
quietly count if `var' < `lower_fence' | `var' > `upper_fence'
local n_outliers = r(N)
local pct_outliers = `n_outliers' / `n_input' * 100

display ""
display ">>> 异常值: `n_outliers' (" %4.1f `pct_outliers' "%)"

display "SS_METRIC|name=median|value=`p50'"
display "SS_METRIC|name=iqr|value=`iqr'"
display "SS_METRIC|name=n_outliers|value=`n_outliers'"

* 导出统计
preserve
clear
set obs 7
generate str20 statistic = ""
generate double value = .

replace statistic = "Q1" in 1
replace value = `p25' in 1
replace statistic = "中位数" in 2
replace value = `p50' in 2
replace statistic = "Q3" in 3
replace value = `p75' in 3
replace statistic = "IQR" in 4
replace value = `iqr' in 4
replace statistic = "下围栏" in 5
replace value = `lower_fence' in 5
replace statistic = "上围栏" in 6
replace value = `upper_fence' in 6
replace statistic = "异常值数" in 7
replace value = `n_outliers' in 7

export delimited using "table_TU03_box_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_TU03_box_stats.csv|type=table|desc=box_stats"
restore

* ============ 绘制箱线图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 绘制箱线图"
display "═══════════════════════════════════════════════════════════════════════════════"

capture confirm variable `by_var'
if !_rc & "`by_var'" != "" & "`by_var'" != "__BY_VAR__" {
    graph box `var', over(`by_var') ///
        title("箱线图: `var' by `by_var'") ///
        ytitle("`var'") ///
        note("N=`n_input', 异常值=`n_outliers'")
}
else {
    graph box `var', ///
        title("箱线图: `var'") ///
        ytitle("`var'") ///
        note("N=`n_input', 异常值=`n_outliers', 中位数=`=round(`p50', 0.01)'")
}

graph export "fig_TU03_boxplot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU03_boxplot.png|type=figure|desc=boxplot"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU03_box.dta", replace
display "SS_OUTPUT_FILE|file=data_TU03_box.dta|type=data|desc=box_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  中位数:          " %10.4f `p50'
display "  IQR:             " %10.4f `iqr'
display "  异常值:          " %10.0fc `n_outliers'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=median|value=`p50'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU03|status=ok|elapsed_sec=`elapsed'"
log close
