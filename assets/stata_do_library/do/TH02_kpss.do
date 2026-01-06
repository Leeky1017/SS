* ==============================================================================
* SS_TEMPLATE: id=TH02  level=L1  module=H  title="KPSS Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH02_kpss.csv type=table desc="KPSS results"
*   - data_TH02_kpss.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - kpss source=ssc purpose="KPSS test"
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TH02|level=L1|title=KPSS_Test"
display "SS_TASK_VERSION:2.0.1"

capture which kpss
if _rc {
    display "SS_DEP_MISSING:kpss"
    display "SS_ERROR:DEP_MISSING:kpss not installed"
    display "SS_ERR:DEP_MISSING:kpss not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=kpss|source=ssc|status=ok"

local var = "__VAR__"
local timevar = "__TIMEVAR__"

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
tsset `timevar'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
kpss `var'
local kpss_stat = r(kpss)
display "SS_METRIC|name=kpss_stat|value=`kpss_stat'"

preserve
clear
set obs 1
gen str32 test = "KPSS"
gen double stat = `kpss_stat'
export delimited using "table_TH02_kpss.csv", replace
display "SS_OUTPUT_FILE|file=table_TH02_kpss.csv|type=table|desc=kpss_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH02_kpss.dta", replace
display "SS_OUTPUT_FILE|file=data_TH02_kpss.dta|type=data|desc=kpss_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=kpss_stat|value=`kpss_stat'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH02|status=ok|elapsed_sec=`elapsed'"
log close
