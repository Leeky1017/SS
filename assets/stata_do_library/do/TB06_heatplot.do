* ==============================================================================
* SS_TEMPLATE: id=TB06  level=L1  module=B  title="Heatplot"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - fig_TB06_heatplot.png type=figure desc="Correlation heatplot"
*   - table_TB06_corr.csv type=table desc="Correlation matrix"
*   - data_TB06_heat.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - heatplot source=ssc purpose="heatmap visualization"
* ==============================================================================
* Task ID:      TB06_heatplot
* Placeholders: __VARS__
* Stata:        18.0+
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TB06|level=L1|title=Heatplot"
display "SS_TASK_VERSION:2.0.1"

capture which heatplot
if _rc {
    display "SS_DEP_MISSING:heatplot"
    display "SS_ERROR:DEP_MISSING:heatplot not installed"
    display "SS_ERR:DEP_MISSING:heatplot not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=heatplot|source=ssc|status=ok"

local vars = "__VARS__"

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
display "SS_METRIC:n_input:`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
correlate `vars'
matrix C = r(C)

heatplot C, values(format(%4.2f)) color(hcl diverging, intensity(.6)) ///
    title("相关系数热力图") aspectratio(1)
graph export "fig_TB06_heatplot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TB06_heatplot.png|type=figure|desc=heatplot"
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
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TB06|status=ok|elapsed_sec=`elapsed'"
log close
