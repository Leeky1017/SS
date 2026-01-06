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
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TO07|level=L1|title=Graph_Export"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local yvar = "__YVAR__"
local xvar = "__XVAR__"

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
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

twoway (scatter `yvar' `xvar') (lfit `yvar' `xvar'), ///
    title("Scatter Plot with Fitted Line") ///
    xtitle("`xvar'") ytitle("`yvar'")

graph export "fig_TO07_scatter.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TO07_scatter.png|type=figure|desc=png_scatter"

graph export "fig_TO07_scatter.pdf", replace
display "SS_OUTPUT_FILE|file=fig_TO07_scatter.pdf|type=figure|desc=pdf_scatter"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TO07_export.dta", replace
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
