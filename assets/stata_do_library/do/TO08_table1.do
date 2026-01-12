* ==============================================================================
* SS_TEMPLATE: id=TO08  level=L2  module=O  title="Table1 (fallback)"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO08_table1.docx type=table desc="Table1 Word (docx)"
*   - table_TO08_table1.csv type=table desc="Table1 CSV"
*   - data_TO08_export.dta type=data desc="Output data"
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

program define ss_fail_TO08
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TO08|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TO08|level=L2|title=Table1"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
display "SS_DEP_CHECK|pkg=putdocx|source=built-in|status=ok"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: removed (`table1_mc` optional → native summary + putdocx) / SSC 依赖：已移除（用原生汇总 + putdocx）
* - Output: DOCX + CSV / 输出：DOCX 表1 + CSV 数据
* - Error policy: fail on invalid vars/export errors / 错误策略：变量无效或导出失败→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TO08|ssc=removed|output=docx_csv_dta|policy=warn_fail"

local vars = "__VARS__"
local by_var = "__BY_VAR__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TO08 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* [ZH] S02 校验输入变量（分组变量 + 数值变量列表）
* [EN] S02 Validate inputs (by var + numeric vars)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `by_var'
if _rc {
    ss_fail_TO08 111 "confirm variable `by_var'" "by_var_not_found"
}
foreach v of local vars {
    capture confirm variable `v'
    if _rc {
        ss_fail_TO08 111 "confirm variable `v'" "var_not_found"
    }
    capture confirm numeric variable `v'
    if _rc {
        ss_fail_TO08 109 "confirm numeric variable `v'" "var_not_numeric"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 生成 Table 1 并导出（CSV + DOCX）
* [EN] S03 Generate Table 1 and export (CSV + DOCX)
display "SS_STEP_BEGIN|step=S03_analysis"

capture noisily tabstat `vars', by(`by_var') statistics(n mean sd) columns(statistics) save
if _rc {
    ss_fail_TO08 459 "tabstat" "tabstat_failed"
}
matrix stats = r(StatTotal)
preserve
clear
svmat stats, names(col)
capture noisily export delimited using "table_TO08_table1.csv", replace
if _rc {
    ss_fail_TO08 459 "export delimited table_TO08_table1.csv" "export_csv_failed"
}
display "SS_OUTPUT_FILE|file=table_TO08_table1.csv|type=table|desc=table1_csv"

capture noisily putdocx clear
capture noisily putdocx begin
if _rc {
    ss_fail_TO08 459 "putdocx begin" "putdocx_begin_failed"
}
capture noisily putdocx paragraph, style(Heading1)
if _rc {
    ss_fail_TO08 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx text ("Table 1 (summary via tabstat)")
if _rc {
    ss_fail_TO08 459 "putdocx text" "putdocx_text_failed"
}
capture noisily putdocx paragraph
if _rc {
    ss_fail_TO08 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx text ("by: `by_var'    vars: `vars'")
if _rc {
    ss_fail_TO08 459 "putdocx text" "putdocx_text_failed"
}
capture noisily putdocx paragraph
if _rc {
    ss_fail_TO08 459 "putdocx paragraph" "putdocx_paragraph_failed"
}
capture noisily putdocx table t1 = data(*), varnames
if _rc {
    ss_fail_TO08 459 "putdocx table" "putdocx_table_failed"
}
capture noisily putdocx save "table_TO08_table1.docx", replace
if _rc {
    ss_fail_TO08 459 "putdocx save table_TO08_table1.docx" "putdocx_save_failed"
}
display "SS_OUTPUT_FILE|file=table_TO08_table1.docx|type=table|desc=table1_docx"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TO08_export.dta", replace
if _rc {
    ss_fail_TO08 459 "save data_TO08_export.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TO08_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO08|status=ok|elapsed_sec=`elapsed'"
log close
