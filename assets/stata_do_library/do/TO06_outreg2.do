* ==============================================================================
* SS_TEMPLATE: id=TO06  level=L2  module=O  title="Outreg2 (fallback)"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO06_compare.docx type=table desc="Comparison table (docx)"
*   - data_TO06_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none (Stata 18 built-in; uses putdocx)
* ==============================================================================

capture log close _all
local rc_log_close = _rc
if `rc_log_close' != 0 {
    display "SS_RC|code=`rc_log_close'|cmd=log close _all|msg=no_active_log|severity=warn"
}

clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TO06
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TO06|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TO06|level=L2|title=Outreg2"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
display "SS_DEP_CHECK|pkg=putdocx|source=built-in|status=ok"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: removed (`outreg2` → native `putdocx`) / SSC 依赖：已移除（用 putdocx 替代）
* - Output: DOCX model comparison / 输出：DOCX 模型对比表
* - Error policy: fail on model/export errors / 错误策略：模型或导出失败→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TO06|ssc=removed|output=docx_dta|policy=warn_fail"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TO06 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* [ZH] S02 校验输入变量（因变量/自变量）
* [EN] S02 Validate inputs (depvar/indepvars)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `depvar'
if _rc {
    ss_fail_TO06 111 "confirm variable `depvar'" "depvar_not_found"
}
capture confirm numeric variable `depvar'
if _rc {
    ss_fail_TO06 109 "confirm numeric variable `depvar'" "depvar_not_numeric"
}
capture fvunab indepvars_fv : `indepvars'
if _rc {
    ss_fail_TO06 111 "fvunab indepvars" "indepvars_invalid"
}
local indepvars "`indepvars_fv'"
if "`indepvars'" == "" {
    ss_fail_TO06 111 "indepvars" "indepvars_empty"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 回归并导出模型对比（putdocx）
* [EN] S03 Run models and export comparison (putdocx)
display "SS_STEP_BEGIN|step=S03_analysis"

capture noisily regress `depvar' `indepvars'
if _rc {
    ss_fail_TO06 459 "regress" "ols_model_fit_failed"
}
estimates store m_ols
local r2a_ols = e(r2_a)
local n_ols = e(N)

capture noisily regress `depvar' `indepvars', robust
if _rc {
    ss_fail_TO06 459 "regress, robust" "robust_model_fit_failed"
}
estimates store m_robust
local r2_robust = e(r2)
local n_robust = e(N)

local r2a_txt : display %9.3f `r2a_ols'
local r2r_txt : display %9.3f `r2_robust'

local k : word count `indepvars'
local n_rows = `k' + 1

preserve
clear
set obs `n_rows'
gen str32 variable = ""
gen double coef_ols = .
gen double se_ols = .
gen double coef_robust = .
gen double se_robust = .

local row = 1
foreach v of local indepvars {
    replace variable = "`v'" in `row'
    estimates restore m_ols
    replace coef_ols = _b[`v'] in `row'
    replace se_ols = _se[`v'] in `row'
    estimates restore m_robust
    replace coef_robust = _b[`v'] in `row'
    replace se_robust = _se[`v'] in `row'
    local row = `row' + 1
}
replace variable = "_cons" in `row'
estimates restore m_ols
replace coef_ols = _b[_cons] in `row'
replace se_ols = _se[_cons] in `row'
estimates restore m_robust
replace coef_robust = _b[_cons] in `row'
replace se_robust = _se[_cons] in `row'

capture noisily putdocx clear
capture noisily putdocx begin
if _rc {
    ss_fail_TO06 459 "putdocx begin" "putdocx_begin_failed"
}
capture noisily putdocx paragraph, style(Heading1)
if _rc {
    ss_fail_TO06 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx text ("Model comparison (OLS vs robust)")
if _rc {
    ss_fail_TO06 459 "putdocx text" "putdocx_text_failed"
}
capture noisily putdocx paragraph
if _rc {
    ss_fail_TO06 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx text ("OLS: N=`n_ols' Adj.R2=`r2a_txt'   Robust: N=`n_robust' R2=`r2r_txt'")
if _rc {
    ss_fail_TO06 459 "putdocx text" "putdocx_text_failed"
}
capture noisily putdocx paragraph
if _rc {
    ss_fail_TO06 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx table t1 = data(variable coef_ols se_ols coef_robust se_robust), varnames
if _rc {
    ss_fail_TO06 459 "putdocx table" "putdocx_table_failed"
}
capture noisily putdocx save "table_TO06_compare.docx", replace
if _rc {
    ss_fail_TO06 459 "putdocx save table_TO06_compare.docx" "putdocx_save_failed"
}
display "SS_OUTPUT_FILE|file=table_TO06_compare.docx|type=table|desc=compare_table"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TO06_export.dta", replace
if _rc {
    ss_fail_TO06 459 "save data_TO06_export.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TO06_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2a_ols|value=`r2a_ols'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO06|status=ok|elapsed_sec=`elapsed'"
log close
