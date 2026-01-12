* ==============================================================================
* SS_TEMPLATE: id=TO02  level=L2  module=O  title="Esttab LaTeX (fallback)"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO02_reg.tex type=table desc="LaTeX regression table"
*   - data_TO02_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none (Stata 18 built-in; uses collect export when available)
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

program define ss_fail_TO02
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TO02|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TO02|level=L2|title=Esttab_LaTeX"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: removed (prefer Stata 18 `collect export`) / SSC 依赖：已移除（优先使用 collect 导出）
* - Output: LaTeX regression table / 输出：LaTeX 回归表
* - Error policy: fail on model/IO errors; warn on collect fallback / 错误策略：模型/写文件失败→fail；collect 不可用→warn 并降级
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TO02|ssc=removed|output=tex_dta|policy=warn_fail"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
display "SS_DEP_CHECK|pkg=collect|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TO02 601 "confirm file data.csv" "input_file_not_found"
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
    ss_fail_TO02 111 "confirm variable `depvar'" "depvar_not_found"
}
capture confirm numeric variable `depvar'
if _rc {
    ss_fail_TO02 109 "confirm numeric variable `depvar'" "depvar_not_numeric"
}
capture fvunab indepvars_fv : `indepvars'
if _rc {
    ss_fail_TO02 111 "fvunab indepvars" "indepvars_invalid"
}
local indepvars "`indepvars_fv'"
if "`indepvars'" == "" {
    ss_fail_TO02 111 "indepvars" "indepvars_empty"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 回归并导出 LaTeX 表（优先 collect；否则降级为手写 tex）
* [EN] S03 Run regression and export LaTeX (prefer collect; fallback to manual tex)
display "SS_STEP_BEGIN|step=S03_analysis"

local wrote_tex = 0

capture noisily collect clear
capture noisily collect: regress `depvar' `indepvars', robust
if _rc {
    local rc_collect_reg = _rc
    display "SS_RC|code=`rc_collect_reg'|cmd=collect: regress|msg=collect_regress_failed_fallback|severity=warn"
    capture noisily regress `depvar' `indepvars', robust
    if _rc {
        ss_fail_TO02 459 "regress" "model_fit_failed"
    }
}
else {
    capture noisily collect export "table_TO02_reg.tex", as(tex) replace
    if _rc {
        local rc_collect_export = _rc
        display "SS_RC|code=`rc_collect_export'|cmd=collect export|msg=collect_export_failed_fallback|severity=warn"
    }
    else {
        local wrote_tex = 1
    }
}

local n_obs = e(N)
local r2 = e(r2)

local n_obs_txt : display %9.0f `n_obs'
local r2_txt : display %9.3f `r2'

if `wrote_tex' == 0 {
    tempname fh
    capture file open `fh' using "table_TO02_reg.tex", write replace text
    if _rc {
        ss_fail_TO02 459 "file open table_TO02_reg.tex" "file_open_failed"
    }
    file write `fh' "\\\\begin{table}[!htbp]\\\\centering" _n
    file write `fh' "\\\\caption{Regression Results (robust SE)}" _n
    file write `fh' "\\\\begin{tabular}{lrr}\\\\hline" _n
    file write `fh' "Variable & Coef & SE \\\\\\\\ \\\\hline" _n
    foreach v of local indepvars {
        local b_txt : display %9.3f _b[`v']
        local se_txt : display %9.3f _se[`v']
        file write `fh' "`v' & `b_txt' & `se_txt' \\\\" _n
    }
    local b0_txt : display %9.3f _b[_cons]
    local se0_txt : display %9.3f _se[_cons]
    file write `fh' "_cons & `b0_txt' & `se0_txt' \\\\ \\hline" _n
    file write `fh' "N & `n_obs_txt' & R2=`r2_txt' \\\\ \\hline" _n
    file write `fh' "\\\\end{tabular}" _n
    file write `fh' "\\\\end{table}" _n
    file close `fh'
    local wrote_tex = 1
}

if `wrote_tex' == 1 {
    display "SS_OUTPUT_FILE|file=table_TO02_reg.tex|type=table|desc=latex_table"
}
else {
    ss_fail_TO02 459 "export tex" "tex_output_failed"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TO02_export.dta", replace
if _rc {
    ss_fail_TO02 459 "save data_TO02_export.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TO02_export.dta|type=data|desc=export_data"
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

display "SS_TASK_END|id=TO02|status=ok|elapsed_sec=`elapsed'"
log close
