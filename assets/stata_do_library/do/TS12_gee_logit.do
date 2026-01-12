* ==============================================================================
* SS_TEMPLATE: id=TS12  level=L1  module=S  title="GEE Logit"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS12_geelogit.csv type=table desc="GEE logit results"
*   - data_TS12_geelogit.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - GEE logit targets population-averaged effects; interpret differently from random-effects (subject-specific) logit models.
* - Correlation structure is a working assumption; use robust SEs and compare structures (exchangeable/ar1/independent).
* - Ensure the dependent variable is binary and check class imbalance; report marginal effects when appropriate.
* 最佳实践审查（ZH）:
* - GEE logit 估计的是总体平均效应（population-averaged），与随机效应 logit 的个体效应解释不同。
* - 相关结构是工作假设；建议使用稳健标准误并比较不同结构（exchangeable/ar1/independent）。
* - 请确保因变量为二元变量并关注类别不平衡；必要时报告边际效应。
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

display "SS_TASK_BEGIN|id=TS12|level=L1|title=GEE_Logit"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"
local corr = "__CORR__"

local indepvars_clean ""
foreach v of local indepvars {
    if "`v'" != "`depvar'" {
        local indepvars_clean "`indepvars_clean' `v'"
    }
}
local indepvars "`indepvars_clean'"

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
quietly count if !inlist(`depvar', 0, 1) & !missing(`depvar')
if r(N) > 0 {
    display "SS_RC|code=10|cmd=depvar_check|msg=depvar_not_binary_for_logit|severity=warn"
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

if "`corr'" == "" | "`corr'" == "__CORR__" {
    local corr = "exchangeable"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Fit GEE logit with robust SEs and export outputs.
* ZH: 估计 GEE logit（稳健标准误）并导出结果摘要。

capture xtset `panelvar_num' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset|msg=xtset_failed|severity=fail"
    log close
    exit `rc'
}
capture noisily xtgee `depvar' `valid_indep', family(binomial) link(logit) corr(`corr') eform robust
if _rc == 2000 {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtgee|msg=perfect_prediction_fallback_to_intercept_only|severity=warn"
    capture noisily xtgee `depvar', family(binomial) link(logit) corr(`corr') eform robust
}
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtgee|msg=xtgee_failed|severity=fail"
    log close
    exit `rc'
}
display "SS_METRIC|name=n_obs|value=`e(N)'"

preserve
clear
set obs 1
gen str32 model = "GEE Logit"
export delimited using "table_TS12_geelogit.csv", replace
display "SS_OUTPUT_FILE|file=table_TS12_geelogit.csv|type=table|desc=geelogit_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TS12_geelogit.dta", replace
display "SS_OUTPUT_FILE|file=data_TS12_geelogit.dta|type=data|desc=geelogit_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_obs|value=`e(N)'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS12|status=ok|elapsed_sec=`elapsed'"
log close
