* ==============================================================================
* SS_TEMPLATE: id=TN01  level=L1  module=N  title="SP Matrix"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - spmat_TN01.dta type=data desc="Spatial matrix"
*   - data_TN01_spmat.dta type=data desc="Output data"
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

program define ss_fail_TN01
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TN01|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TN01|level=L1|title=SP_Matrix"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: none (built-in spatial suite) / SSC 依赖：无（官方空间计量命令）
* - Output: saved spmatrix + dataset / 输出：保存空间权重矩阵与结果数据
* - Notes: prefer unique numeric ID + non-missing numeric coords / 备注：优先唯一数值ID与无缺失数值坐标
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TN01|ssc=none|output=spmat_dta|policy=warn_fail"

display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local id = "__ID__"
local x = "__X__"
local y = "__Y__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TN01 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* [ZH] S02 校验关键输入（坐标与可选ID）
* [EN] S02 Validate key inputs (coords + optional ID)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `x'
if _rc {
    ss_fail_TN01 111 "confirm variable `x'" "coord_x_not_found"
}
capture confirm variable `y'
if _rc {
    ss_fail_TN01 111 "confirm variable `y'" "coord_y_not_found"
}
capture confirm numeric variable `x'
if _rc {
    ss_fail_TN01 109 "confirm numeric variable `x'" "coord_x_not_numeric"
}
capture confirm numeric variable `y'
if _rc {
    ss_fail_TN01 109 "confirm numeric variable `y'" "coord_y_not_numeric"
}
quietly count if missing(`x') | missing(`y')
local n_missing_coord = r(N)
if `n_missing_coord' > 0 {
    ss_fail_TN01 459 "count missing coords" "coords_have_missing_values"
}

local id_for_spset "ss_sid"
capture confirm variable `id'
if _rc {
    display "SS_RC|code=0|cmd=confirm variable `id'|msg=id_var_not_found_fallback_seq|severity=warn"
}
else {
    capture confirm numeric variable `id'
    if _rc {
        display "SS_RC|code=0|cmd=confirm numeric variable `id'|msg=id_var_not_numeric_fallback_seq|severity=warn"
    }
    else {
        capture isid `id'
        if _rc {
            display "SS_RC|code=0|cmd=isid `id'|msg=id_var_not_unique_fallback_seq|severity=warn"
        }
        else {
            local id_for_spset "`id'"
        }
    }
}
display "SS_METRIC|name=n_missing_coord|value=`n_missing_coord'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 构建空间权重矩阵并导出
* [EN] S03 Build spatial weights matrix and export
display "SS_STEP_BEGIN|step=S03_analysis"
if "`id_for_spset'" == "ss_sid" {
    gen long ss_sid = _n
}
capture noisily spset `id_for_spset'
if _rc {
    ss_fail_TN01 459 "spset `id_for_spset'" "spset_failed"
}
capture noisily spset, modify coord(`x' `y')
if _rc {
    ss_fail_TN01 459 "spset modify coord" "spset_coord_failed"
}
capture noisily spmatrix create idistance W, normalize(row)
if _rc {
    ss_fail_TN01 459 "spmatrix create idistance" "spmatrix_create_failed"
}
capture noisily spmatrix summarize W
if _rc {
    ss_fail_TN01 459 "spmatrix summarize" "spmatrix_summarize_failed"
}
local mean_w = r(mean)
display "SS_METRIC|name=mean_weight|value=`mean_w'"

capture noisily spmatrix save W using "spmat_TN01.dta", replace
if _rc {
    ss_fail_TN01 459 "spmatrix save" "spmatrix_save_failed"
}
display "SS_OUTPUT_FILE|file=spmat_TN01.dta|type=data|desc=spatial_matrix"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TN01_spmat.dta", replace
if _rc {
    ss_fail_TN01 459 "save data_TN01_spmat.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TN01_spmat.dta|type=data|desc=spmat_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_weight|value=`mean_w'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TN01|status=ok|elapsed_sec=`elapsed'"
log close
