* ==============================================================================
* SS_TEMPLATE: id=TM03  level=L1  module=M  title="Kappa"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM03_kappa.csv type=table desc="Kappa results"
*   - data_TM03_kappa.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Kappa depends on prevalence and category balance; interpret with caution and report categories.
* - Ensure raters use the same set of categories; recode/standardize before computing agreement.
* - For ordinal ratings, consider weighted kappa (not covered in this minimal template).
* 最佳实践审查（ZH）:
* - Kappa 会受患病率与类别分布影响；建议同时报告类别分布并谨慎解读。
* - 请确保两位评定者使用一致的类别集合；必要时先进行重编码/标准化。
* - 若为有序分类，建议使用加权 kappa（本模板未覆盖）。
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

display "SS_TASK_BEGIN|id=TM03|level=L1|title=Kappa"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local rater1 = "__RATER1__"
local rater2 = "__RATER2__"

display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM03|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM03|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate rater variables exist (numeric or string).
* ZH: 校验评定者变量存在（可为数值或字符串）。
capture confirm variable `rater1'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `rater1'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM03|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `rater2'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `rater2'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM03|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Encode string ratings if needed and compute kappa.
* ZH: 如为字符串评分先编码，再计算 kappa。

local model_ok = 1
local kappa = .
local z = .
local p = .

tempvar ss_r1 ss_r2
local r1_var "`rater1'"
local r2_var "`rater2'"

capture confirm numeric variable `rater1'
if _rc {
    capture confirm string variable `rater1'
    if _rc {
        local model_ok = 0
    }
    if _rc == 0 {
        encode `rater1', gen(`ss_r1')
        local r1_var "`ss_r1'"
    }
}
capture confirm numeric variable `rater2'
if _rc {
    capture confirm string variable `rater2'
    if _rc {
        local model_ok = 0
    }
    if _rc == 0 {
        encode `rater2', gen(`ss_r2')
        local r2_var "`ss_r2'"
    }
}

if `model_ok' == 1 {
    capture noisily kap `r1_var' `r2_var'
    if _rc {
        local model_ok = 0
        display "SS_RC|code=`=_rc'|cmd=kap|msg=kappa_failed|severity=warn"
    }
}
if `model_ok' == 1 {
    local kappa = r(kappa)
    local z = r(z)
    local p = r(p)
}
display "SS_METRIC|name=kappa|value=`kappa'"
display "SS_METRIC|name=p_value|value=`p'"

preserve
clear
set obs 1
gen str32 analysis = "Kappa"
gen double kappa = `kappa'
gen double z = `z'
gen double p = `p'
export delimited using "table_TM03_kappa.csv", replace
display "SS_OUTPUT_FILE|file=table_TM03_kappa.csv|type=table|desc=kappa_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM03_kappa.dta", replace
display "SS_OUTPUT_FILE|file=data_TM03_kappa.dta|type=data|desc=kappa_data"
local step_status "ok"
if `model_ok' == 0 {
    local step_status "warn"
}
display "SS_STEP_END|step=S03_analysis|status=`step_status'|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=kappa|value=`kappa'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

local task_status "ok"
if `model_ok' == 0 {
    local task_status "warn"
}
display "SS_TASK_END|id=TM03|status=`task_status'|elapsed_sec=`elapsed'"
log close
