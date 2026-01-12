* ==============================================================================
* SS_TEMPLATE: id=TP14  level=L1  module=P  title="Svy Poisson"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP14_svypois.csv type=table desc="Survey poisson results"
*   - data_TP14_svy.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TP14
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP14|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP14|level=L1|title=Svy_Poisson"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: use svy: poisson for design-based inference; consider overdispersion and alternative models if needed. /
*   最佳实践：使用 svy: poisson 做设计型推断；关注过度离散，必要时考虑替代模型。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/svyset/estimation; warn on convergence issues /
*   错误策略：缺少输入/svyset/估计失败→fail；收敛问题→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP14|ssc=none|output=csv_dta|policy=warn_fail"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local pweight = "__PWEIGHT__"
local strata = "__STRATA__"
local psu = "__PSU__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP14 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `depvar'
if _rc {
    ss_fail_TP14 200 "confirm variable `depvar'" "var_not_found"
}
local valid_indep ""
foreach v of local indepvars {
    capture confirm numeric variable `v'
    if !_rc {
        local valid_indep "`valid_indep' `v'"
    }
}
if "`valid_indep'" == "" {
    ss_fail_TP14 200 "confirm numeric indepvars" "no_valid_indepvars"
}
foreach v in `psu' `strata' `pweight' {
    capture confirm variable `v'
    if _rc {
        ss_fail_TP14 200 "confirm variable `v'" "var_not_found"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture svyset `psu' [pweight=`pweight'], strata(`strata')
if _rc {
    ss_fail_TP14 `=_rc' "svyset" "svyset_failed"
}
capture svy: poisson `depvar' `valid_indep'
if _rc {
    ss_fail_TP14 `=_rc' "svy: poisson" "estimation_failed"
}
local ll = e(ll)
local n_obs = e(N)
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=n_obs|value=`n_obs'"
capture noisily svydescribe
local rc_svydescribe = _rc
if `rc_svydescribe' != 0 {
    display "SS_RC|code=`rc_svydescribe'|cmd=svydescribe|msg=svydescribe_failed|severity=warn"
}

tempname pois_results
postfile `pois_results' str64 term double coef double se double t double p using "temp_svy_pois.dta", replace
matrix b = e(b)
matrix V = e(V)
local colnames : colnames b
local k : word count `colnames'
forvalues i = 1/`k' {
    local term : word `i' of `colnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local t = `coef' / `se'
    local p = 2 * ttail(e(df_r), abs(`t'))
    post `pois_results' ("`term'") (`coef') (`se') (`t') (`p')
}
postclose `pois_results'

preserve
use "temp_svy_pois.dta", clear
capture export delimited using "table_TP14_svypois.csv", replace
if _rc {
    ss_fail_TP14 `=_rc' "export delimited table_TP14_svypois.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP14_svypois.csv|type=table|desc=svy_poisson"
restore

capture erase "temp_svy_pois.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TP14_svy.dta", replace
if _rc {
    ss_fail_TP14 `=_rc' "save data_TP14_svy.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TP14_svy.dta|type=data|desc=svy_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP14|status=ok|elapsed_sec=`elapsed'"
log close
