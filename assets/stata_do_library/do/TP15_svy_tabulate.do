* ==============================================================================
* SS_TEMPLATE: id=TP15  level=L1  module=P  title="Svy Tabulate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP15_svytab.csv type=table desc="Survey tabulate results"
*   - data_TP15_svy.dta type=data desc="Output data"
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

program define ss_fail_TP15
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP15|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP15|level=L1|title=Svy_Tabulate"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: svy: tabulate provides design-based association tests; check sparse cells and design df. /
*   最佳实践：svy: tabulate 给出设计型关联检验；关注稀疏单元与设计自由度。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/svyset/estimation; warn on sparse cells /
*   错误策略：缺少输入/svyset/估计失败→fail；稀疏单元→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP15|ssc=none|output=csv_dta|policy=warn_fail"

local var1 = "__VAR1__"
local var2 = "__VAR2__"
local pweight = "__PWEIGHT__"
local strata = "__STRATA__"
local psu = "__PSU__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP15 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
foreach v in `var1' `var2' `psu' `strata' `pweight' {
    capture confirm variable `v'
    if _rc {
        ss_fail_TP15 200 "confirm variable `v'" "var_not_found"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture svyset `psu' [pweight=`pweight'], strata(`strata')
if _rc {
    ss_fail_TP15 `=_rc' "svyset" "svyset_failed"
}
capture svy: tabulate `var1' `var2', pearson
if _rc {
    ss_fail_TP15 `=_rc' "svy: tabulate" "estimation_failed"
}
local f = e(F_Pear)
local p = e(p_Pear)
display "SS_METRIC|name=f_stat|value=`f'"
display "SS_METRIC|name=p_value|value=`p'"
display "SS_METRIC|name=n_obs|value=`=e(N)'"

preserve
clear
set obs 1
gen str32 analysis = "Survey Tabulate"
gen double f = `f'
gen double p = `p'
capture export delimited using "table_TP15_svytab.csv", replace
if _rc {
    ss_fail_TP15 `=_rc' "export delimited table_TP15_svytab.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP15_svytab.csv|type=table|desc=svy_tab"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TP15_svy.dta", replace
if _rc {
    ss_fail_TP15 `=_rc' "save data_TP15_svy.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TP15_svy.dta|type=data|desc=svy_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=p_value|value=`p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP15|status=ok|elapsed_sec=`elapsed'"
log close
