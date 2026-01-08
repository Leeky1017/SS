* ==============================================================================
* SS_TEMPLATE: id=TD02  level=L1  module=D  title="High Dim FE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD02_hdfe.csv type=table desc="HDFE regression results"
*   - data_TD02_hdfe.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - reghdfe source=ssc purpose="high-dimensional fixed effects"
*   - stata source=built-in purpose="matrix-based CSV export (estout removed)"
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

display "SS_TASK_BEGIN|id=TD02|level=L1|title=High_Dim_FE"
display "SS_TASK_VERSION|version=2.0.1"

* ============ BEST_PRACTICE_REVIEW (Phase 5.5) ============
* - [x] Keep SSC model only where needed (保留 `reghdfe`；无等价内置替代)
* - [x] Remove SSC table export (移除 `estout/esttab`；改为内置矩阵导出)
* - [x] Validate key variables (校验 depvar 与吸收变量)
* - [x] Fail fast with structured diagnostics (结构化错误信息；无 silent failure)

capture which reghdfe
if _rc {
    display "SS_DEP_CHECK|pkg=reghdfe|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=reghdfe"
    display "SS_RC|code=199|cmd=which reghdfe|msg=dependency_missing|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 199
}

display "SS_DEP_CHECK|pkg=reghdfe|source=ssc|status=ok"
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local absorb_vars = "__ABSORB_VARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

local n_missing_total = 0
quietly count if missing(`depvar')
local n_missing_total = `n_missing_total' + r(N)
foreach v of local absorb_vars {
    if regexm("`v'", "^[A-Za-z_][A-Za-z0-9_]*$") {
        capture confirm variable `v'
        if _rc {
            local rc = _rc
            display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found:absorb_var|severity=fail"
            timer off 1
            quietly timer list 1
            local elapsed = r(t1)
            display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
            log close
            exit `rc'
        }
        quietly count if missing(`v')
        local n_missing_total = `n_missing_total' + r(N)
    }
}
display "SS_METRIC|name=n_missing|value=`n_missing_total'"

capture noisily reghdfe `depvar' `indepvars', absorb(`absorb_vars') vce(robust)
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=reghdfe|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

local r2 = e(r2)
display "SS_METRIC|name=r2|value=`r2'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
tempname results
postfile `results' str64 variable double coef double se using "temp_TD02_coefs.dta", replace

local n_written = 0
foreach var of local indepvars {
    if !regexm("`var'", "^[A-Za-z_][A-Za-z0-9_]*$") {
        continue
    }
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
use "temp_TD02_coefs.dta", clear
if `n_written' <= 0 {
    display "SS_RC|code=198|cmd=_b/_se|msg=no_coefficients_exported|severity=fail"
    restore
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 198
}
export delimited using "table_TD02_hdfe.csv", replace
restore
capture erase "temp_TD02_coefs.dta"

display "SS_OUTPUT_FILE|file=table_TD02_hdfe.csv|type=table|desc=hdfe_results"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD02_hdfe.dta", replace
display "SS_OUTPUT_FILE|file=data_TD02_hdfe.dta|type=data|desc=hdfe_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TD02|status=ok|elapsed_sec=`elapsed'"
log close
