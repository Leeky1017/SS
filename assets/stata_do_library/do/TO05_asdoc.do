* ==============================================================================
* SS_TEMPLATE: id=TO05  level=L2  module=O  title="Asdoc (fallback)"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO05_asdoc.docx type=table desc="Word document (docx)"
*   - data_TO05_export.dta type=data desc="Output data"
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

program define ss_fail_TO05
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TO05|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TO05|level=L2|title=Asdoc"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
display "SS_DEP_CHECK|pkg=putdocx|source=built-in|status=ok"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: removed (`asdoc` → native `putdocx`) / SSC 依赖：已移除（用 putdocx 替代）
* - Output: DOCX regression table / 输出：DOCX 回归表
* - Error policy: fail on model/export errors / 错误策略：模型或导出失败→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TO05|ssc=removed|output=docx_dta|policy=warn_fail"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TO05 601 "confirm file data.csv" "input_file_not_found"
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
    ss_fail_TO05 111 "confirm variable `depvar'" "depvar_not_found"
}
capture confirm numeric variable `depvar'
if _rc {
    ss_fail_TO05 109 "confirm numeric variable `depvar'" "depvar_not_numeric"
}
capture fvunab indepvars_fv : `indepvars'
if _rc {
    ss_fail_TO05 111 "fvunab indepvars" "indepvars_invalid"
}
local indepvars "`indepvars_fv'"
if "`indepvars'" == "" {
    ss_fail_TO05 111 "indepvars" "indepvars_empty"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 回归并导出 DOCX 表（putdocx）
* [EN] S03 Run regression and export DOCX (putdocx)
display "SS_STEP_BEGIN|step=S03_analysis"

capture noisily regress `depvar' `indepvars', robust
if _rc {
    ss_fail_TO05 459 "regress" "model_fit_failed"
}
local n_obs = e(N)
local r2 = e(r2)
local df_r = e(df_r)

local n_obs_txt : display %9.0f `n_obs'
local r2_txt : display %9.3f `r2'

local k : word count `indepvars'
local n_rows = `k' + 1

preserve
clear
set obs `n_rows'
gen str32 variable = ""
gen double coef = .
gen double se = .
gen double t = .
gen double p = .

local row = 1
foreach v of local indepvars {
    replace variable = "`v'" in `row'
    local b = _b[`v']
    local s = _se[`v']
    replace coef = `b' in `row'
    replace se = `s' in `row'
    local tt = .
    local pp = .
    if `s' < . & `s' > 0 {
        local tt = `b' / `s'
        local pp = 2 * ttail(`df_r', abs(`tt'))
    }
    replace t = `tt' in `row'
    replace p = `pp' in `row'
    local row = `row' + 1
}
replace variable = "_cons" in `row'
local b0 = _b[_cons]
local s0 = _se[_cons]
replace coef = `b0' in `row'
replace se = `s0' in `row'
local t0 = .
local p0 = .
if `s0' < . & `s0' > 0 {
    local t0 = `b0' / `s0'
    local p0 = 2 * ttail(`df_r', abs(`t0'))
}
replace t = `t0' in `row'
replace p = `p0' in `row'

capture noisily putdocx clear
capture noisily putdocx begin
if _rc {
    ss_fail_TO05 459 "putdocx begin" "putdocx_begin_failed"
}
capture noisily putdocx paragraph, style(Heading1)
if _rc {
    ss_fail_TO05 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx text ("Regression Results (robust SE)")
if _rc {
    ss_fail_TO05 459 "putdocx text" "putdocx_text_failed"
}
capture noisily putdocx paragraph
if _rc {
    ss_fail_TO05 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx text ("N=`n_obs_txt'  R2=`r2_txt'")
if _rc {
    ss_fail_TO05 459 "putdocx text" "putdocx_text_failed"
}
capture noisily putdocx paragraph
if _rc {
    ss_fail_TO05 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx table t1 = data(variable coef se t p), varnames
if _rc {
    ss_fail_TO05 459 "putdocx table" "putdocx_table_failed"
}
capture noisily putdocx save "table_TO05_asdoc.docx", replace
if _rc {
    ss_fail_TO05 459 "putdocx save table_TO05_asdoc.docx" "putdocx_save_failed"
}
display "SS_OUTPUT_FILE|file=table_TO05_asdoc.docx|type=table|desc=docx_table"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TO05_export.dta", replace
if _rc {
    ss_fail_TO05 459 "save data_TO05_export.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TO05_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO05|status=ok|elapsed_sec=`elapsed'"
log close
