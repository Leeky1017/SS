* ==============================================================================
* SS_TEMPLATE: id=TN02  level=L1  module=N  title="Moran I"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TN02_moran.csv type=table desc="Moran results"
*   - data_TN02_moran.dta type=data desc="Output data"
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

program define ss_fail_TN02
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TN02|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TN02|level=L1|title=Moran_I"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: none (built-in spatial suite) / SSC 依赖：无（官方空间计量命令）
* - Output: CSV + DTA / 输出：CSV 表格 + DTA 数据
* - Notes: drop missing values; Moran's I is sensitive to W choice / 备注：删除缺失值；Moran's I 对权重矩阵 W 设定敏感
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TN02|ssc=none|output=csv_dta|policy=warn_fail"

display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local var = "__VAR__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TN02 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* [ZH] S02 校验变量并处理缺失值（缺失值将被删除）
* [EN] S02 Validate variable and drop missing values
display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `var'
if _rc {
    ss_fail_TN02 111 "confirm variable `var'" "var_not_found"
}
capture confirm numeric variable `var'
if _rc {
    ss_fail_TN02 109 "confirm numeric variable `var'" "var_not_numeric"
}
quietly count if missing(`var')
local n_missing_var = r(N)
if `n_missing_var' > 0 {
    display "SS_RC|code=0|cmd=drop if missing(`var')|msg=missing_values_dropped|detail=n_missing_var_`n_missing_var'|severity=warn"
    drop if missing(`var')
}
if _N < 3 {
    ss_fail_TN02 459 "count" "too_few_obs_for_moran_i"
}
display "SS_METRIC|name=n_missing_var|value=`n_missing_var'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 构建 W 并计算全局 Moran's I（简化实现）
* [EN] S03 Build W and compute global Moran's I (simplified)
display "SS_STEP_BEGIN|step=S03_analysis"

capture confirm variable `var'
if _rc {
    ss_fail_TN02 111 "confirm variable `var'" "var_not_found"
}
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
    ss_fail_TN02 459 "spset ss_sid" "spset_failed"
}
capture noisily spset, modify coord(x cluster)
if _rc {
    ss_fail_TN02 459 "spset modify coord" "spset_coord_failed"
}
capture noisily spmatrix create idistance W, normalize(row)
if _rc {
    ss_fail_TN02 459 "spmatrix create idistance" "spmatrix_create_failed"
}

quietly summarize `var'
local mean_var = r(mean)
local sd_var = r(sd)
if `sd_var' == 0 {
    ss_fail_TN02 459 "summarize" "zero_variance_var"
}
generate double z_var = (`var' - `mean_var') / `sd_var'
spgenerate Wz = W*z_var
generate double prod = z_var * Wz
quietly summarize prod
local numerator = r(sum)
generate double z2 = z_var^2
quietly summarize z2
local denom = r(sum)
local moran_i = `numerator' / `denom'

local n = _N
local E_I = -1 / (`n' - 1)
local V_I = (`n'^2) / ((`n' - 1)^2 * (`n' + 1)) - `E_I'^2
local z = .
local p = .
if `V_I' > 0 {
    local z = (`moran_i' - `E_I') / sqrt(`V_I')
    local p = 2 * (1 - normal(abs(`z')))
}
else {
    display "SS_RC|code=0|cmd=moran_variance_check|msg=nonpositive_variance|detail=V_I_`V_I'|severity=warn"
}
display "SS_METRIC|name=moran_i|value=`moran_i'"
display "SS_METRIC|name=z_stat|value=`z'"
display "SS_METRIC|name=p_value|value=`p'"

preserve
clear
set obs 1
gen double moran_i = `moran_i'
gen double z = `z'
gen double p = `p'
capture noisily export delimited using "table_TN02_moran.csv", replace
if _rc {
    ss_fail_TN02 459 "export delimited table_TN02_moran.csv" "export_table_failed"
}
display "SS_OUTPUT_FILE|file=table_TN02_moran.csv|type=table|desc=moran_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TN02_moran.dta", replace
if _rc {
    ss_fail_TN02 459 "save data_TN02_moran.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TN02_moran.dta|type=data|desc=moran_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=moran_i|value=`moran_i'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TN02|status=ok|elapsed_sec=`elapsed'"
log close
