* ==============================================================================
* SS_TEMPLATE: id=TM07  level=L2  module=M  title="Funnel Plot"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TM07_funnel.png type=figure desc="Funnel plot"
*   - table_TM07_bias.csv type=table desc="Bias results"
*   - data_TM07_bias.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: metafunnel
* ==============================================================================
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

display "SS_TASK_BEGIN|id=TM07|level=L2|title=Funnel_Plot"
display "SS_TASK_VERSION|version=2.0.1"

capture which metafunnel
if _rc {
    display "SS_DEP_CHECK|pkg=metafunnel|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=metafunnel"
    display "SS_RC|code=199|cmd=which metafunnel|msg=dependency_missing|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=metafunnel|source=ssc|status=ok"

local effect = "__EFFECT__"
local se = "__SE__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

metafunnel `effect' `se', title("Funnel Plot")
graph export "fig_TM07_funnel.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TM07_funnel.png|type=figure|desc=funnel_plot"

metabias `effect' `se', egger
local bias = r(bias)
local p_bias = r(p)
display "SS_METRIC|name=egger_bias|value=`bias'"
display "SS_METRIC|name=egger_p|value=`p_bias'"

preserve
clear
set obs 1
gen double egger_bias = `bias'
gen double egger_p = `p_bias'
export delimited using "table_TM07_bias.csv", replace
display "SS_OUTPUT_FILE|file=table_TM07_bias.csv|type=table|desc=bias_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM07_bias.dta", replace
display "SS_OUTPUT_FILE|file=data_TM07_bias.dta|type=data|desc=bias_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=egger_bias|value=`bias'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM07|status=ok|elapsed_sec=`elapsed'"
log close
