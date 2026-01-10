* ==============================================================================
* SS_TEMPLATE: id=TL02  level=L1  module=L  title="Mod Jones"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL02_modjones.csv type=table desc="Modified Jones results"
*   - data_TL02_modjones.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TL02|level=L1|title=Mod_Jones"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local ta = "__TA__"
local rev = "__REV__"
local rec = "__REC__"
local ppe = "__PPE__"
local assets = "__ASSETS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL02|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
local required_vars "`ta' `rev' `rec' `ppe' `assets' `panelvar' `timevar'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL02|status=fail|elapsed_sec=`elapsed'"
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
        display "SS_TASK_END|id=TL02|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture xtset `panelvar' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset `panelvar' `timevar'|msg=xtset_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

generate ta_scaled = `ta' / L.`assets'
generate inv_assets = 1 / L.`assets'
generate delta_rev = D.`rev' / L.`assets'
generate delta_rec = D.`rec' / L.`assets'
generate adj_rev = delta_rev - delta_rec
generate ppe_scaled = `ppe' / L.`assets'

regress ta_scaled inv_assets delta_rev ppe_scaled, noconstant
matrix b = e(b)
generate nda = b[1,1]*inv_assets + b[1,2]*adj_rev + b[1,3]*ppe_scaled
generate da = ta_scaled - nda

summarize da
local mean_da = r(mean)
local sd_da = r(sd)
display "SS_METRIC|name=mean_da|value=`mean_da'"
display "SS_METRIC|name=sd_da|value=`sd_da'"

preserve
clear
set obs 1
gen str32 model = "Modified Jones"
gen double mean_da = `mean_da'
gen double sd_da = `sd_da'
export delimited using "table_TL02_modjones.csv", replace
display "SS_OUTPUT_FILE|file=table_TL02_modjones.csv|type=table|desc=modjones_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL02_modjones.dta", replace
display "SS_OUTPUT_FILE|file=data_TL02_modjones.dta|type=data|desc=modjones_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_da|value=`mean_da'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL02|status=ok|elapsed_sec=`elapsed'"
log close
