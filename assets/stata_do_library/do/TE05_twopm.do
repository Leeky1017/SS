* ==============================================================================
* SS_TEMPLATE: id=TE05  level=L1  module=E  title="Two-Part"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TE05_twopm.csv type=table desc="Two-Part results"
*   - data_TE05_twopm.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="logit + glm (two-part model)"
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.5) ============
* - [x] Remove SSC dependency where feasible (用内置 `logit` + `glm` 替换 `twopm`)
* - [x] Handle edge cases (全为 0 / 全为正 / 收敛失败)
* - [x] Export machine-readable coefficient table (导出可解析系数表)
* - 2026-01-08: Two-part = Pr(y>0) + E(y|y>0) (两部分模型：发生概率 + 正值强度)

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

display "SS_TASK_BEGIN|id=TE05|level=L1|title=Two_Part"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `depvar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `depvar'|msg=var_not_found:depvar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

local n_missing_total = 0
quietly count if missing(`depvar')
local n_missing_total = `n_missing_total' + r(N)
foreach v of local indepvars {
    if regexm("`v'", "^[A-Za-z_][A-Za-z0-9_]*$") {
        capture confirm variable `v'
        if _rc {
            local rc = _rc
            display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found:indepvar|severity=fail"
            timer off 1
            quietly timer list 1
            local elapsed = r(t1)
            display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
            log close
            exit `rc'
        }
        quietly count if missing(`v')
        local n_missing_total = `n_missing_total' + r(N)
    }
}
display "SS_METRIC|name=n_missing|value=`n_missing_total'"

tempvar positive
gen byte `positive' = (`depvar' > 0) if !missing(`depvar')
quietly count if `positive' == 1
local n_pos = r(N)
quietly count if `positive' == 0
local n_zero = r(N)
display "SS_METRIC|name=n_pos|value=`n_pos'"
display "SS_METRIC|name=n_zero|value=`n_zero'"

if `n_pos' <= 0 {
    display "SS_RC|code=2001|cmd=gen positive|msg=no_positive_outcomes|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2001
}

* Part 1: occurrence / 第一部分：发生概率
local ran_logit = 0
if `n_zero' > 0 {
    capture noisily logit `positive' `indepvars', vce(robust)
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=logit|msg=fit_failed|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
    capture confirm scalar e(converged)
    if !_rc {
        if e(converged) == 0 {
            display "SS_RC|code=430|cmd=logit|msg=not_converged|severity=fail"
            timer off 1
            quietly timer list 1
            local elapsed = r(t1)
            display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
            log close
            exit 430
        }
    }
    estimates store te05_part1
    local ran_logit = 1
}
else {
    display "SS_RC|code=0|cmd=logit|msg=all_positive_skip_part1|severity=warn"
}

* Part 2: intensity on positive outcomes / 第二部分：正值强度（仅正值样本）
capture noisily glm `depvar' `indepvars' if `positive' == 1, family(gamma) link(log) vce(robust)
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=glm gamma log|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm scalar e(converged)
if !_rc {
    if e(converged) == 0 {
        display "SS_RC|code=431|cmd=glm|msg=not_converged|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TE05|status=fail|elapsed_sec=`elapsed'"
        log close
        exit 431
    }
}
estimates store te05_part2

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
tempname results
postfile `results' str16 model str64 variable double coef double se using "temp_TE05_coefs.dta", replace

local vars_to_export "_cons `indepvars'"

if `ran_logit' == 1 {
    estimates restore te05_part1
    foreach v of local vars_to_export {
        if ("`v'" == "_cons") | regexm("`v'", "^[A-Za-z_][A-Za-z0-9_]*$") {
            capture scalar coef = _b[`v']
            if _rc {
                continue
            }
            scalar se = _se[`v']
            post `results' ("part1_logit") ("`v'") (coef) (se)
        }
    }
}

estimates restore te05_part2
foreach v of local vars_to_export {
    if ("`v'" == "_cons") | regexm("`v'", "^[A-Za-z_][A-Za-z0-9_]*$") {
        capture scalar coef = _b[`v']
        if _rc {
            continue
        }
        scalar se = _se[`v']
        post `results' ("part2_glm") ("`v'") (coef) (se)
    }
}
postclose `results'

preserve
use "temp_TE05_coefs.dta", clear
export delimited using "table_TE05_twopm.csv", replace
display "SS_OUTPUT_FILE|file=table_TE05_twopm.csv|type=table|desc=twopm_results"
restore
capture erase "temp_TE05_coefs.dta"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TE05_twopm.dta", replace
display "SS_OUTPUT_FILE|file=data_TE05_twopm.dta|type=data|desc=twopm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=model|value=two_part"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TE05|status=ok|elapsed_sec=`elapsed'"
log close

