* ==============================================================================
* SS_TEMPLATE: id=TB06  level=L1  module=B  title="Heatplot"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TB06_heatplot.png type=graph desc="Correlation heatplot"
*   - table_TB06_corr.csv type=table desc="Correlation matrix"
*   - data_TB06_heat.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="correlate + graph export (heatplot optional)"
* ==============================================================================
* Task ID:      TB06_heatplot
* Placeholders: __VARS__
* Stata:        18.0+
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.4) ============
* - [x] Validate numeric vars (校验数值变量)
* - [x] Missingness summary (缺失值摘要)
* - [x] Remove hard SSC dep (移除对 heatplot 的硬依赖；缺失时降级输出)
* - [x] Bilingual notes for key steps (关键步骤中英文注释)
* - 2026-01-08: If `heatplot` is unavailable, fall back to `graph matrix` (无 heatplot 时使用 graph matrix 作为替代图形)

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

display "SS_TASK_BEGIN|id=TB06|level=L1|title=Heatplot"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
local vars = "__VARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Validate numeric vars / 校验数值变量
local numeric_vars ""
local n_missing_total = 0
foreach var of local vars {
    capture confirm variable `var'
    if _rc {
        display "SS_RC|code=0|cmd=confirm variable `var'|msg=var_not_found_skipped|severity=warn"
        continue
    }
    capture confirm numeric variable `var'
    if _rc {
        display "SS_RC|code=0|cmd=confirm numeric variable `var'|msg=not_numeric_skipped|severity=warn"
        continue
    }
    local numeric_vars "`numeric_vars' `var'"
    quietly count if missing(`var')
    local n_missing_total = `n_missing_total' + r(N)
}
local n_vars_used : word count `numeric_vars'
if `n_vars_used' <= 1 {
    display "SS_RC|code=198|cmd=confirm numeric variable <vars>|msg=need_at_least_two_numeric_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 198
}
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=n_vars_valid|value=`n_vars_used'"

capture noisily correlate `numeric_vars'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=correlate|msg=corr_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
matrix C = r(C)

* Prefer heatplot if available; otherwise fall back / 优先 heatplot；否则降级
capture which heatplot
if _rc == 0 {
    display "SS_DEP_CHECK|pkg=heatplot|source=ssc|status=ok"
    heatplot C, values(format(%4.2f)) ///
        title("相关系数热力图 / Correlation Heatmap") aspectratio(1)
}
else {
    local rc = _rc
    display "SS_DEP_CHECK|pkg=heatplot|source=ssc|status=missing"
    display "SS_RC|code=`rc'|cmd=which heatplot|msg=dependency_missing_fallback_graph_matrix|severity=warn"
    graph matrix `numeric_vars', half title("相关性矩阵（替代） / Correlation Matrix (fallback)")
}
graph export "fig_TB06_heatplot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TB06_heatplot.png|type=graph|desc=heatplot"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
svmat C, names(col)
export delimited using "table_TB06_corr.csv", replace
display "SS_OUTPUT_FILE|file=table_TB06_corr.csv|type=table|desc=corr_matrix"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TB06_heat.dta", replace
display "SS_OUTPUT_FILE|file=data_TB06_heat.dta|type=data|desc=heat_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_vars|value=`: word count `vars''"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TB06|status=ok|elapsed_sec=`elapsed'"
log close
