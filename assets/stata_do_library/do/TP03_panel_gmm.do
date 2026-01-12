* ==============================================================================
* SS_TEMPLATE: id=TP03  level=L2  module=P  title="Panel GMM"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP03_gmm_result.csv type=table desc="GMM results"
*   - table_TP03_diagnostics.csv type=table desc="Diagnostics"
*   - data_TP03_gmm.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: xtabond2
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TP03
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP03|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP03|level=L2|title=Panel_GMM"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: report AR(2) + Hansen p-values; avoid instrument proliferation; interpret with care. /
*   最佳实践：关注 AR(2) 与 Hansen 的 p 值；避免工具变量过多；谨慎解读。
* - SSC deps: required:xtabond2 (widely used system/diff GMM implementation; built-in alternatives differ) /
*   SSC 依赖：必需 xtabond2（常用系统/差分 GMM 实现；内置替代在语法/输出上不等价）
* - Error policy: fail on missing inputs/xtset/estimation; warn on singleton groups /
*   错误策略：缺少输入/xtset/估计失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP03|ssc=required:xtabond2|output=csv_dta|policy=warn_fail"

* ============ 依赖检测 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
capture which xtabond2
if _rc {
    display "SS_DEP_CHECK|pkg=xtabond2|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=xtabond2"
    ss_fail_TP03 199 "which xtabond2" "dependency_missing"
}
display "SS_DEP_CHECK|pkg=xtabond2|source=ssc|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local gmm_type = "__GMM_TYPE__"
local lags = __LAGS__

if "`gmm_type'" == "" {
    local gmm_type = "system"
}
if `lags' < 1 | `lags' > 5 {
    local lags = 1
}

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP03 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `depvar' `id_var' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TP03 200 "confirm variable `var'" "var_not_found"
    }
}

local valid_indep ""
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
    }
}
if "`valid_indep'" == "" {
    ss_fail_TP03 200 "confirm numeric indepvars" "no_valid_indepvars"
}

capture xtset `id_var' `time_var'
if _rc {
    ss_fail_TP03 `=_rc' "xtset `id_var' `time_var'" "xtset_failed"
}
tempvar _ss_n_i
bysort `id_var': gen long `_ss_n_i' = _N
quietly count if `_ss_n_i' == 1
local n_singletons = r(N)
drop `_ss_n_i'
display "SS_METRIC|name=n_singletons|value=`n_singletons'"
if `n_singletons' > 0 {
    display "SS_RC|code=312|cmd=xtset|msg=singleton_groups_present|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ GMM估计 ============
display "SECTION 1: GMM"

* 构建滞后因变量
local lag_depvars ""
forvalues i = 1/`lags' {
    local lag_depvars "`lag_depvars' L`i'.`depvar'"
}

if "`gmm_type'" == "difference" {
    capture noisily xtabond2 `depvar' `lag_depvars' `valid_indep', gmm(L.`depvar') iv(`valid_indep') ///
        noleveleq robust small
    if _rc {
        ss_fail_TP03 `=_rc' "xtabond2" "xtabond2_failed"
    }
}
else {
    capture noisily xtabond2 `depvar' `lag_depvars' `valid_indep', gmm(L.`depvar') iv(`valid_indep') ///
        robust small
    if _rc {
        ss_fail_TP03 `=_rc' "xtabond2" "xtabond2_failed"
    }
}

local n_obs = e(N)
local n_groups = e(N_g)
local n_inst = e(j)

display ""
display ">>> 样本信息:"
display "    观测数: `n_obs'"
display "    组数: `n_groups'"
display "    工具变量数: `n_inst'"

* 导出结果
tempname gmm_results
postfile `gmm_results' str32 variable double coef double se double z double p ///
    using "temp_gmm_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `gmm_results' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `gmm_results'

preserve
use "temp_gmm_results.dta", clear
capture export delimited using "table_TP03_gmm_result.csv", replace
if _rc {
    ss_fail_TP03 `=_rc' "export delimited table_TP03_gmm_result.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP03_gmm_result.csv|type=table|desc=gmm_results"
restore

* ============ 诊断检验 ============
display "SECTION 2: Diagnostics"

* AR(1)和AR(2)检验
local ar1 = e(ar1)
local ar1_p = e(ar1p)
local ar2 = e(ar2)
local ar2_p = e(ar2p)

display ""
display ">>> Arellano-Bond序列相关检验:"
display "    AR(1): z=" %8.4f `ar1' ", p=" %6.4f `ar1_p'
display "    AR(2): z=" %8.4f `ar2' ", p=" %6.4f `ar2_p'

if `ar2_p' >= 0.10 {
    display "    结论: AR(2)不显著，模型设定正确"
}
else {
    display "SS_RC|code=0|cmd=estat abond|msg=ar2_significant|severity=warn"
}

* Hansen/Sargan过度识别检验
local hansen = e(hansen)
local hansen_p = e(hansenp)

display ""
display ">>> Hansen过度识别检验:"
display "    χ²=" %10.4f `hansen' ", p=" %6.4f `hansen_p'

if `hansen_p' >= 0.10 {
    display "    结论: 工具变量有效"
}
else {
    display "SS_RC|code=0|cmd=estat sargan|msg=overid_rejected|severity=warn"
}

display "SS_METRIC|name=ar2_p|value=`ar2_p'"
display "SS_METRIC|name=hansen_p|value=`hansen_p'"

* 导出诊断结果
preserve
clear
set obs 3
generate str30 test = ""
generate double statistic = .
generate double p_value = .

replace test = "AR(1)" in 1
replace statistic = `ar1' in 1
replace p_value = `ar1_p' in 1

replace test = "AR(2)" in 2
replace statistic = `ar2' in 2
replace p_value = `ar2_p' in 2

replace test = "Hansen J" in 3
replace statistic = `hansen' in 3
replace p_value = `hansen_p' in 3

capture export delimited using "table_TP03_diagnostics.csv", replace
if _rc {
    ss_fail_TP03 `=_rc' "export delimited table_TP03_diagnostics.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP03_diagnostics.csv|type=table|desc=diagnostics"
restore

capture erase "temp_gmm_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TP03_gmm.dta", replace
if _rc {
    ss_fail_TP03 `=_rc' "save data_TP03_gmm.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TP03_gmm.dta|type=data|desc=gmm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=hansen_p|value=`hansen_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP03|status=ok|elapsed_sec=`elapsed'"
log close
