* ==============================================================================
* SS_TEMPLATE: id=TL12  level=L1  module=L  title="Ohlson OScore"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL12_oscore.csv type=table desc="O-Score results"
*   - data_TL12_oscore.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
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

display "SS_TASK_BEGIN|id=TL12|level=L1|title=Ohlson_OScore"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL12|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL12|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* 参数定义
local size_var "__SIZE__"
local tlta_var "__TLTA__"
local wcta_var "__WCTA__"
local clca_var "__CLCA__"
local oeneg_var "__OENEG__"
local nita_var "__NITA__"
local futl_var "__FUTL__"
local intwo_var "__INTWO__"
local chin_var "__CHIN__"
local required_vars "`size_var' `tlta_var' `wcta_var' `clca_var' `oeneg_var' `nita_var' `futl_var' `intwo_var' `chin_var'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL12|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
    capture confirm numeric variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm numeric variable `v'|msg=var_not_numeric|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL12|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* Ohlson O-Score: O = -1.32 - 0.407*SIZE + 6.03*TLTA - 1.43*WCTA + 0.0757*CLCA
*                    - 1.72*OENEG - 2.37*NITA - 1.83*FUTL + 0.285*INTWO - 0.521*CHIN
generate oscore = -1.32 - 0.407*`size_var' + 6.03*`tlta_var' - 1.43*`wcta_var' ///
    + 0.0757*`clca_var' - 1.72*`oeneg_var' - 2.37*`nita_var' - 1.83*`futl_var' ///
    + 0.285*`intwo_var' - 0.521*`chin_var'

generate prob_bankrupt = exp(oscore) / (1 + exp(oscore))

summarize oscore prob_bankrupt
local mean_oscore = r(mean)
display "SS_METRIC|name=mean_oscore|value=`mean_oscore'"

preserve
clear
set obs 1
gen str32 model = "Ohlson O-Score"
gen double mean_oscore = `mean_oscore'
export delimited using "table_TL12_oscore.csv", replace
display "SS_OUTPUT_FILE|file=table_TL12_oscore.csv|type=table|desc=oscore_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL12_oscore.dta", replace
display "SS_OUTPUT_FILE|file=data_TL12_oscore.dta|type=data|desc=oscore_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_oscore|value=`mean_oscore'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL12|status=ok|elapsed_sec=`elapsed'"
log close
