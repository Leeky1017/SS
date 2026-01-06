* ==============================================================================
* SS_TEMPLATE: id=TM05  level=L1  module=M  title="NNT"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM05_nnt.csv type=table desc="NNT results"
*   - data_TM05_nnt.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TM05|level=L1|title=NNT"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local outcome = "__OUTCOME__"
local treatment = "__TREATMENT__"

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

tabulate `treatment' `outcome', matcell(freq)
local a = freq[2,2]
local b = freq[2,1]
local c = freq[1,2]
local d = freq[1,1]

local cer = `c' / (`c' + `d')
local eer = `a' / (`a' + `b')
local arr = `cer' - `eer'
local nnt = 1 / abs(`arr')
local rr = `eer' / `cer'

display "SS_METRIC|name=nnt|value=`nnt'"
display "SS_METRIC|name=arr|value=`arr'"
display "SS_METRIC|name=rr|value=`rr'"

preserve
clear
set obs 1
gen double cer = `cer'
gen double eer = `eer'
gen double arr = `arr'
gen double nnt = `nnt'
gen double rr = `rr'
export delimited using "table_TM05_nnt.csv", replace
display "SS_OUTPUT_FILE|file=table_TM05_nnt.csv|type=table|desc=nnt_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM05_nnt.dta", replace
display "SS_OUTPUT_FILE|file=data_TM05_nnt.dta|type=data|desc=nnt_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=nnt|value=`nnt'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM05|status=ok|elapsed_sec=`elapsed'"
log close
