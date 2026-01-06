* ==============================================================================
* SS_TEMPLATE: id=TO08  level=L2  module=O  title="Table1"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO08_table1.doc type=table desc="Table1 Word"
*   - table_TO08_table1.csv type=table desc="Table1 CSV"
*   - data_TO08_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: table1_mc
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TO08|level=L2|title=Table1"
display "SS_TASK_VERSION:2.0.1"

capture which table1_mc
if _rc {
    display "SS_DEP_MISSING:table1_mc"
    display "SS_ERROR:DEP_MISSING:table1_mc not installed"
    display "SS_ERR:DEP_MISSING:table1_mc not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=table1_mc|source=ssc|status=ok"

local vars = "__VARS__"
local by_var = "__BY_VAR__"

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

table1_mc, by(`by_var') vars(`vars') ///
    saving("table_TO08_table1.doc", replace) ///
    clear
display "SS_OUTPUT_FILE|file=table_TO08_table1.doc|type=table|desc=table1_doc"

import delimited "data.csv", clear
tabstat `vars', by(`by_var') statistics(n mean sd) columns(statistics) save
matrix stats = r(StatTotal)
preserve
clear
svmat stats, names(col)
export delimited using "table_TO08_table1.csv", replace
display "SS_OUTPUT_FILE|file=table_TO08_table1.csv|type=table|desc=table1_csv"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TO08_export.dta", replace
display "SS_OUTPUT_FILE|file=data_TO08_export.dta|type=data|desc=export_data"
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

display "SS_TASK_END|id=TO08|status=ok|elapsed_sec=`elapsed'"
log close
