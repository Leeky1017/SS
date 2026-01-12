* ==============================================================================
* SS_TEMPLATE: id=TN04  level=L1  module=N  title="SEM"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TN04_sem.csv type=table desc="SEM results"
*   - data_TN04_sem.dta type=data desc="Output data"
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

program define ss_fail_TN04
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TN04|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TN04|level=L1|title=SEM"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: none (built-in spatial suite) / SSC 依赖：无（官方空间计量命令）
* - Output: CSV + DTA / 输出：CSV 表格 + DTA 数据
* - Notes: errorlag(W) models spatially correlated errors / 备注：errorlag(W) 用于建模空间相关误差项
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TN04|ssc=none|output=csv_dta|policy=warn_fail"

display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TN04 601 "confirm file data.csv" "input_file_not_found"
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
    ss_fail_TN04 111 "confirm variable `depvar'" "depvar_not_found"
}
capture confirm numeric variable `depvar'
if _rc {
    ss_fail_TN04 109 "confirm numeric variable `depvar'" "depvar_not_numeric"
}
capture fvunab indepvars_fv : `indepvars'
if _rc {
    ss_fail_TN04 111 "fvunab indepvars" "indepvars_invalid"
}
local indepvars "`indepvars_fv'"
if "`indepvars'" == "" {
    ss_fail_TN04 111 "indepvars" "indepvars_empty"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 构建 W 并估计 SEM（空间误差模型）
* [EN] S03 Build W and estimate SEM (spatial error model)
display "SS_STEP_BEGIN|step=S03_analysis"

capture confirm variable x
if _rc {
    gen double x = _n
    display "SS_RC|code=0|cmd=gen x=_n|msg=coord_x_defaulted|severity=warn"
}
capture confirm variable cluster
if _rc {
    gen double cluster = 0
    display "SS_RC|code=0|cmd=gen cluster=0|msg=coord_y_defaulted|severity=warn"
}
gen long ss_sid = _n
capture noisily spset ss_sid
if _rc {
    ss_fail_TN04 459 "spset ss_sid" "spset_failed"
}
capture noisily spset, modify coord(x cluster)
if _rc {
    ss_fail_TN04 459 "spset modify coord" "spset_coord_failed"
}
capture noisily spmatrix create idistance W, normalize(row)
if _rc {
    ss_fail_TN04 459 "spmatrix create idistance" "spmatrix_create_failed"
}
capture noisily spregress `depvar' `indepvars', ml errorlag(W)
if _rc {
    ss_fail_TN04 459 "spregress" "sem_model_fit_failed"
}
local lambda = e(lambda)
local ll = e(ll)
display "SS_METRIC|name=lambda|value=`lambda'"
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "SEM"
gen double lambda = `lambda'
gen double ll = `ll'
capture noisily export delimited using "table_TN04_sem.csv", replace
if _rc {
    ss_fail_TN04 459 "export delimited table_TN04_sem.csv" "export_table_failed"
}
display "SS_OUTPUT_FILE|file=table_TN04_sem.csv|type=table|desc=sem_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TN04_sem.dta", replace
if _rc {
    ss_fail_TN04 459 "save data_TN04_sem.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TN04_sem.dta|type=data|desc=sem_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=lambda|value=`lambda'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TN04|status=ok|elapsed_sec=`elapsed'"
log close
