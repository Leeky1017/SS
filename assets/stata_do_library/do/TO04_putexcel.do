* ==============================================================================
* SS_TEMPLATE: id=TO04  level=L1  module=O  title="Putexcel"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO04_results.xlsx type=table desc="Excel results"
*   - data_TO04_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
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

program define ss_fail_TO04
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TO04|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TO04|level=L1|title=Putexcel"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: none (native `putexcel`) / SSC 依赖：无（使用 putexcel 原生导出）
* - Output: XLSX regression table / 输出：XLSX 回归表
* - Error policy: fail on model/export errors / 错误策略：模型或导出失败→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TO04|ssc=none|output=xlsx_dta|policy=warn_fail"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
display "SS_DEP_CHECK|pkg=putexcel|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TO04 601 "confirm file data.csv" "input_file_not_found"
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
    ss_fail_TO04 111 "confirm variable `depvar'" "depvar_not_found"
}
capture confirm numeric variable `depvar'
if _rc {
    ss_fail_TO04 109 "confirm numeric variable `depvar'" "depvar_not_numeric"
}
capture fvunab indepvars_fv : `indepvars'
if _rc {
    ss_fail_TO04 111 "fvunab indepvars" "indepvars_invalid"
}
local indepvars "`indepvars_fv'"
if "`indepvars'" == "" {
    ss_fail_TO04 111 "indepvars" "indepvars_empty"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 回归并导出 Excel 表（putexcel）
* [EN] S03 Run regression and export Excel (putexcel)
display "SS_STEP_BEGIN|step=S03_analysis"

capture noisily regress `depvar' `indepvars', robust
if _rc {
    ss_fail_TO04 459 "regress" "model_fit_failed"
}
local r2 = e(r2)
local df_r = e(df_r)
local n_obs = e(N)

capture noisily putexcel set "table_TO04_results.xlsx", replace
if _rc {
    ss_fail_TO04 459 "putexcel set" "putexcel_set_failed"
}
capture noisily putexcel A1 = ("Regression Results (robust SE)")
if _rc {
    ss_fail_TO04 459 "putexcel write" "putexcel_write_failed"
}
capture noisily putexcel A2 = ("Variable") B2 = ("Coefficient") C2 = ("Std. Error") D2 = ("t") E2 = ("p")
if _rc {
    ss_fail_TO04 459 "putexcel write" "putexcel_write_failed"
}

local row = 3
foreach v of local indepvars {
    local b = _b[`v']
    local s = _se[`v']
    local tt = .
    local pp = .
    if `s' < . & `s' > 0 {
        local tt = `b' / `s'
        local pp = 2 * ttail(`df_r', abs(`tt'))
    }
    capture noisily putexcel A`row' = ("`v'") B`row' = (`b') C`row' = (`s') D`row' = (`tt') E`row' = (`pp')
    if _rc {
        ss_fail_TO04 459 "putexcel write row" "putexcel_write_failed"
    }
    local row = `row' + 1
}
local b0 = _b[_cons]
local s0 = _se[_cons]
local t0 = .
local p0 = .
if `s0' < . & `s0' > 0 {
    local t0 = `b0' / `s0'
    local p0 = 2 * ttail(`df_r', abs(`t0'))
}
capture noisily putexcel A`row' = ("_cons") B`row' = (`b0') C`row' = (`s0') D`row' = (`t0') E`row' = (`p0')
if _rc {
    ss_fail_TO04 459 "putexcel write row" "putexcel_write_failed"
}
local row = `row' + 2
capture noisily putexcel A`row' = ("N") B`row' = (`n_obs')
if _rc {
    ss_fail_TO04 459 "putexcel write" "putexcel_write_failed"
}
local row2 = `row' + 1
capture noisily putexcel A`row2' = ("R-squared") B`row2' = (`r2')
if _rc {
    ss_fail_TO04 459 "putexcel write" "putexcel_write_failed"
}
display "SS_OUTPUT_FILE|file=table_TO04_results.xlsx|type=table|desc=excel_results"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TO04_export.dta", replace
if _rc {
    ss_fail_TO04 459 "save data_TO04_export.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TO04_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_dropped|value=`n_dropped'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO04|status=ok|elapsed_sec=`elapsed'"
log close
