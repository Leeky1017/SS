* ==============================================================================
* SS_TEMPLATE: id=TN08  level=L2  module=N  title="Spatial Panel"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TN08_sppanel.csv type=table desc="Panel results"
*   - data_TN08_sppanel.dta type=data desc="Output data"
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

program define ss_fail_TN08
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TN08|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TN08|level=L2|title=Spatial_Panel"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.13 REVIEW (Issue #362) / 最佳实践审查（阶段 5.13）
* - SSC deps: none (built-in panel suite) / SSC 依赖：无（官方面板命令）
* - Output: CSV + DTA / 输出：CSV 表格 + DTA 数据
* - Notes: baseline xtreg FE; spatial panel needs extra assumptions / 备注：当前为面板FE基线；真正空间面板需额外设定（W/模型形式）
* ==============================================================================
display "SS_BP_REVIEW|issue=362|template_id=TN08|ssc=none|output=csv_dta|policy=warn_fail"

display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"

* [ZH] S01 加载数据（data.csv）
* [EN] S01 Load data (data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TN08 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* [ZH] S02 校验输入变量（因变量/自变量/面板结构变量）
* [EN] S02 Validate inputs (depvar/indepvars/panel+time)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
foreach v in `depvar' `panelvar' `timevar' {
    capture confirm variable `v'
    if _rc {
        ss_fail_TN08 111 "confirm variable `v'" "required_var_not_found"
    }
}
capture confirm numeric variable `depvar'
if _rc {
    ss_fail_TN08 109 "confirm numeric variable `depvar'" "depvar_not_numeric"
}
capture fvunab indepvars_fv : `indepvars'
if _rc {
    ss_fail_TN08 111 "fvunab indepvars" "indepvars_invalid"
}
local indepvars "`indepvars_fv'"
if "`indepvars'" == "" {
    ss_fail_TN08 111 "indepvars" "indepvars_empty"
}
quietly count if missing(`panelvar') | missing(`timevar')
if r(N) > 0 {
    ss_fail_TN08 459 "count missing panel/time" "panel_time_has_missing"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* [ZH] S03 面板回归估计（FE 基线）
* [EN] S03 Estimate panel model (FE baseline)
display "SS_STEP_BEGIN|step=S03_analysis"

capture ss_smart_xtset `panelvar' `timevar'
if _rc {
    capture xtset `panelvar' `timevar'
    if _rc {
        ss_fail_TN08 459 "xtset" "panel_setup_failed"
    }
}

capture xtreg `depvar' `indepvars', fe
if _rc {
    ss_fail_TN08 459 "xtreg" "model_fit_failed"
}
local r2_within = e(r2_within)
local n_obs = e(N)

display "SS_METRIC|name=r2_within|value=`r2_within'"
display "SS_METRIC|name=n_obs_model|value=`n_obs'"

preserve
clear
set obs 1
gen str32 model = "Panel FE (baseline)"
gen double r2_within = `r2_within'
gen double n_obs = `n_obs'
capture noisily export delimited using "table_TN08_sppanel.csv", replace
if _rc {
    ss_fail_TN08 459 "export delimited table_TN08_sppanel.csv" "export_table_failed"
}
display "SS_OUTPUT_FILE|file=table_TN08_sppanel.csv|type=table|desc=sppanel_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture noisily save "data_TN08_sppanel.dta", replace
if _rc {
    ss_fail_TN08 459 "save data_TN08_sppanel.dta" "save_output_data_failed"
}
display "SS_OUTPUT_FILE|file=data_TN08_sppanel.dta|type=data|desc=sppanel_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2_within|value=`r2_within'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TN08|status=ok|elapsed_sec=`elapsed'"
log close
