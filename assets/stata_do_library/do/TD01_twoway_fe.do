* ==============================================================================
* SS_TEMPLATE: id=TD01  level=L1  module=D  title="Twoway FE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD01_twfe.csv type=table desc="TWFE regression results"
*   - data_TD01_twfe.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="xtreg fixed effects"
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.5) ============
* - [x] Remove SSC dependency where feasible (用 `xtreg, fe` 替换 `reghdfe`；适用于双向固定效应的常见场景)
* - [x] Validate key variables (校验关键变量：dep/panel/time)
* - [x] Cluster-robust SE by panel (按个体聚类稳健标准误)
* - [x] Export machine-readable coefficient table (导出可解析系数表)
* - 2026-01-08: Time FE implemented via `i.__TIME_VAR__` (时间固定效应通过因子变量实现)

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

display "SS_TASK_BEGIN|id=TD01|level=L1|title=Twoway_FE"
display "SS_TASK_VERSION|version=2.0.1"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
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
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Validate key variables / 校验关键变量
capture confirm variable `depvar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `depvar'|msg=var_not_found:depvar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `depvar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `depvar'|msg=not_numeric:depvar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `panelvar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `panelvar'|msg=var_not_found:panelvar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `timevar'|msg=var_not_found:timevar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `timevar'|msg=not_numeric:timevar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly count if missing(`depvar') | missing(`panelvar') | missing(`timevar')
local n_missing_total = r(N)
display "SS_METRIC|name=n_missing|value=`n_missing_total'"

capture noisily xtset `panelvar' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset|msg=xtset_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

* TWFE: unit FE via xtreg, time FE via i.timevar / 个体固定效应 + 时间固定效应
capture noisily xtreg `depvar' `indepvars' i.`timevar', fe vce(cluster `panelvar')
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtreg|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

local r2 = e(r2_within)
local n_obs = e(N)
display "SS_METRIC|name=r2|value=`r2'"
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
tempname results
postfile `results' str64 variable double coef double se using "temp_TD01_coefs.dta", replace

local n_written = 0
foreach var of local indepvars {
    capture confirm variable `var'
    if _rc {
        continue
    }
    capture scalar coef = _b[`var']
    if _rc {
        display "SS_RC|code=0|cmd=_b[`var']|msg=coef_not_available_skipped|severity=warn"
        continue
    }
    scalar se = _se[`var']
    post `results' ("`var'") (coef) (se)
    local n_written = `n_written' + 1
}
postclose `results'

preserve
use "temp_TD01_coefs.dta", clear
if `n_written' <= 0 {
    display "SS_RC|code=198|cmd=_b/_se|msg=no_coefficients_exported|severity=fail"
    restore
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 198
}
export delimited using "table_TD01_twfe.csv", replace
display "SS_OUTPUT_FILE|file=table_TD01_twfe.csv|type=table|desc=twfe_results"
restore

capture erase "temp_TD01_coefs.dta"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD01_twfe.dta", replace
display "SS_OUTPUT_FILE|file=data_TD01_twfe.dta|type=data|desc=twfe_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TD01|status=ok|elapsed_sec=`elapsed'"
log close
