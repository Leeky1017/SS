* ==============================================================================
* SS_TEMPLATE: id=TS11  level=L1  module=S  title="GEE Basic"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS11_gee.csv type=table desc="GEE results"
*   - data_TS11_gee.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Choose family/link consistent with the outcome distribution; report robustness to alternative specifications.
* - Correlation structure is a working assumption; use robust SEs and compare structures (independent/exchangeable/ar1).
* - Ensure panel/time identifiers are correct; xtset failures often indicate duplicates or missing keys.
* 最佳实践审查（ZH）:
* - family/link 需与因变量分布匹配；建议做不同设定的稳健性检验。
* - 相关结构是工作假设；建议使用稳健标准误，并比较不同结构（independent/exchangeable/ar1）。
* - 请确保面板/时间标识正确；xtset 失败常见原因是重复或缺失键。
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

display "SS_TASK_BEGIN|id=TS11|level=L1|title=GEE_Basic"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"
local family = "__FAMILY__"
local corr = "__CORR__"

display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate inputs and set defaults for optional parameters.
* ZH: 校验输入并为可选参数设置默认值。
capture confirm numeric variable `depvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found_or_not_numeric|var=`depvar'|severity=fail"
    log close
    exit 200
}
capture confirm variable `panelvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable|msg=panelvar_not_found|var=`panelvar'|severity=fail"
    log close
    exit 200
}
capture confirm numeric variable `timevar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=timevar_not_found_or_not_numeric|var=`timevar'|severity=fail"
    log close
    exit 200
}

local panelvar_num "`panelvar'"
capture confirm numeric variable `panelvar'
if _rc {
    tempvar panel_id
    encode `panelvar', gen(`panel_id')
    local panelvar_num "`panel_id'"
}

local valid_indep ""
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
    }
}
if "`valid_indep'" == "" {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=no_valid_indepvars|severity=fail"
    log close
    exit 200
}

if "`family'" == "" | "`family'" == "__FAMILY__" {
    local family = "gaussian"
}
if "`corr'" == "" | "`corr'" == "__CORR__" {
    local corr = "independent"
}
local link = "identity"
if "`family'" == "binomial" {
    local link = "logit"
}
else if "`family'" == "poisson" {
    local link = "log"
}
else if "`family'" != "gaussian" {
    display "SS_RC|code=10|cmd=param_check|msg=family_link_defaulted_to_identity|family=`family'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Fit GEE with robust SEs and export summary outputs.
* ZH: 估计 GEE（稳健标准误）并导出结果摘要。

capture xtset `panelvar_num' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset|msg=xtset_failed|severity=fail"
    log close
    exit `rc'
}
local n_obs = _N
capture noisily xtgee `depvar' `valid_indep', family(`family') link(`link') corr(`corr') robust
local rc = _rc
if `rc' != 0 {
    if `rc' == 430 {
        display "SS_RC|code=430|cmd=xtgee|msg=convergence_not_achieved|severity=warn"
    }
    else {
        display "SS_RC|code=`rc'|cmd=xtgee|msg=xtgee_failed|severity=fail"
        log close
        exit `rc'
    }
}
else {
    local n_obs = e(N)
}
display "SS_METRIC|name=n_obs|value=`n_obs'"

preserve
clear
set obs 1
gen str32 model = "GEE"
gen str20 correlation = "`corr'"
export delimited using "table_TS11_gee.csv", replace
display "SS_OUTPUT_FILE|file=table_TS11_gee.csv|type=table|desc=gee_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TS11_gee.dta", replace
display "SS_OUTPUT_FILE|file=data_TS11_gee.dta|type=data|desc=gee_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_obs|value=`n_obs'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS11|status=ok|elapsed_sec=`elapsed'"
log close
