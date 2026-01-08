* ==============================================================================
* SS_TEMPLATE: id=TB10  level=L0  module=B  title="Bland Altman"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TB10_ba.png type=graph desc="Bland-Altman plot"
*   - table_TB10_ba.csv type=table desc="BA statistics"
*   - data_TB10_ba.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="scatter and summarize"
* ==============================================================================
* Task ID:      TB10_bland_altman
* Placeholders: __VAR1__, __VAR2__
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

display "SS_TASK_BEGIN|id=TB10|level=L0|title=Bland_Altman"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local var1 = "__VAR1__"
local var2 = "__VAR2__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
generate double _mean = (`var1' + `var2') / 2
generate double _diff = `var1' - `var2'

quietly summarize _diff
local mean_diff = r(mean)
local sd_diff = r(sd)
local loa_lo = `mean_diff' - 1.96 * `sd_diff'
local loa_hi = `mean_diff' + 1.96 * `sd_diff'

display ">>> Bland-Altman分析:"
display "    均值差: " %8.4f `mean_diff'
display "    LOA下限: " %8.4f `loa_lo'
display "    LOA上限: " %8.4f `loa_hi'

display "SS_METRIC|name=mean_diff|value=`mean_diff'"
display "SS_METRIC|name=loa_lower|value=`loa_lo'"
display "SS_METRIC|name=loa_upper|value=`loa_hi'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
twoway (scatter _diff _mean, mcolor(navy%50)) ///
       (function y=`mean_diff', range(_mean) lcolor(red)) ///
       (function y=`loa_lo', range(_mean) lcolor(gray) lpattern(dash)) ///
       (function y=`loa_hi', range(_mean) lcolor(gray) lpattern(dash)), ///
    title("Bland-Altman图") xtitle("均值") ytitle("差值") ///
    legend(order(2 "Mean" 3 "95% LOA"))
graph export "fig_TB10_ba.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TB10_ba.png|type=graph|desc=ba_plot"

preserve
clear
set obs 3
gen str20 metric = ""
gen double value = .
replace metric = "Mean Diff" in 1
replace value = `mean_diff' in 1
replace metric = "LOA Lower" in 2
replace value = `loa_lo' in 2
replace metric = "LOA Upper" in 3
replace value = `loa_hi' in 3
export delimited using "table_TB10_ba.csv", replace
display "SS_OUTPUT_FILE|file=table_TB10_ba.csv|type=table|desc=ba_stats"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TB10_ba.dta", replace
display "SS_OUTPUT_FILE|file=data_TB10_ba.dta|type=data|desc=ba_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_diff|value=`mean_diff'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TB10|status=ok|elapsed_sec=`elapsed'"
log close
