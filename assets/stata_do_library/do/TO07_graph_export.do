* ==============================================================================
* SS_TEMPLATE: id=TO07  level=L1  module=O  title="Graph Export"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TO07_scatter.png type=figure desc="PNG scatter plot"
*   - fig_TO07_scatter.pdf type=figure desc="PDF scatter plot"
*   - data_TO07_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
local rc_log_close = _rc
if `rc_log_close' != 0 {
    display "SS_RC|code=`rc_log_close'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TO07
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TO07|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TO07|level=L1|title=Graph_Export"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: none (built-in graphs) / SSC 依赖：无（官方作图命令）
* - Output: PNG+PDF graphs / 输出：PNG+PDF 图形文件
* - Error policy: fail on graph/export errors / 错误策略：作图或导出失败→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TO07|ssc=none|output=png_pdf_dta|policy=warn_fail"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local yvar = "__YVAR__"
local xvar = "__XVAR__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TO07 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* [ZH] S02 校验输入变量（X/Y 必须为数值变量）
* [EN] S02 Validate inputs (X/Y must be numeric)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `xvar'
if _rc {
    ss_fail_TO07 111 "confirm variable `xvar'" "xvar_not_found"
}
capture confirm variable `yvar'
if _rc {
    ss_fail_TO07 111 "confirm variable `yvar'" "yvar_not_found"
}
capture confirm numeric variable `xvar'
if _rc {
    ss_fail_TO07 109 "confirm numeric variable `xvar'" "xvar_not_numeric"
}
capture confirm numeric variable `yvar'
if _rc {
    ss_fail_TO07 109 "confirm numeric variable `yvar'" "yvar_not_numeric"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 作图并导出（PNG/PDF）
* [EN] S03 Plot and export (PNG/PDF)
display "SS_STEP_BEGIN|step=S03_analysis"

capture noisily twoway (scatter `yvar' `xvar') (lfit `yvar' `xvar'), ///
    title("Scatter Plot with Fitted Line") ///
    xtitle("`xvar'") ytitle("`yvar'")
if _rc {
    ss_fail_TO07 459 "twoway" "graph_failed"
}

capture noisily graph export "fig_TO07_scatter.png", replace width(1200)
if _rc {
    ss_fail_TO07 459 "graph export png" "graph_export_png_failed"
}
display "SS_OUTPUT_FILE|file=fig_TO07_scatter.png|type=figure|desc=png_scatter"

capture noisily graph export "fig_TO07_scatter.pdf", replace
if _rc {
    ss_fail_TO07 459 "graph export pdf" "graph_export_pdf_failed"
}
display "SS_OUTPUT_FILE|file=fig_TO07_scatter.pdf|type=figure|desc=pdf_scatter"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TO07_export.dta", replace
if _rc {
    ss_fail_TO07 459 "save data_TO07_export.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TO07_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_dropped|value=`n_dropped'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO07|status=ok|elapsed_sec=`elapsed'"
log close
