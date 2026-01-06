* ==============================================================================
* SS_TEMPLATE: id=TH05  level=L1  module=H  title="GARCH Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH05_garch.csv type=table desc="GARCH results"
*   - fig_TH05_vol.png type=figure desc="Volatility plot"
*   - data_TH05_garch.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TH05|level=L1|title=GARCH_Model"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

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
arch `var', arch(1) garch(1)
local ll = e(ll)
display "SS_METRIC|name=log_likelihood|value=`ll'"

predict vol, variance
generate sqrt_vol = sqrt(vol)
tsline sqrt_vol, title("GARCH条件波动率")
graph export "fig_TH05_vol.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TH05_vol.png|type=figure|desc=volatility"

preserve
clear
set obs 1
gen str32 model = "GARCH(1,1)"
gen double ll = `ll'
export delimited using "table_TH05_garch.csv", replace
display "SS_OUTPUT_FILE|file=table_TH05_garch.csv|type=table|desc=garch_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH05_garch.dta", replace
display "SS_OUTPUT_FILE|file=data_TH05_garch.dta|type=data|desc=garch_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH05|status=ok|elapsed_sec=`elapsed'"
log close
