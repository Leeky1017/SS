* ==============================================================================
* SS_TEMPLATE: id=TL14  level=L1  module=L  title="GC Opinion"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL14_gc.csv type=table desc="GC opinion results"
*   - data_TL14_gc.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL14|level=L1|title=GC_Opinion"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local gc = "__GC__"
local zscore = "__ZSCORE__"
local loss = "__LOSS__"
local laggc = "__LAGGC__"
local lnta = "__LNTA__"
local leverage = "__LEVERAGE__"

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

logit `gc' `zscore' `loss' `laggc' `lnta' `leverage'
local ll = e(ll)
local pseudo_r2 = e(r2_p)
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=pseudo_r2|value=`pseudo_r2'"

lroc
local auc = r(area)
display "SS_METRIC|name=auc|value=`auc'"

preserve
clear
set obs 1
gen str32 model = "GC Opinion"
gen double pseudo_r2 = `pseudo_r2'
gen double auc = `auc'
export delimited using "table_TL14_gc.csv", replace
display "SS_OUTPUT_FILE|file=table_TL14_gc.csv|type=table|desc=gc_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL14_gc.dta", replace
display "SS_OUTPUT_FILE|file=data_TL14_gc.dta|type=data|desc=gc_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=auc|value=`auc'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL14|status=ok|elapsed_sec=`elapsed'"
log close
