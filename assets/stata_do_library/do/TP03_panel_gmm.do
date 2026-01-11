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

display "SS_TASK_BEGIN|id=TP03|level=L2|title=Panel_GMM"
display "SS_TASK_VERSION|version=2.0.1"

* ============ 依赖检测 ============
local required_deps "xtabond2"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_MISSING|pkg=`dep'|hint=ssc_install_`dep'"
        display "SS_RC|code=199|cmd=which `dep'|msg=dependency_missing|severity=fail|pkg=`dep'"
        display "SS_TASK_END|id=TP03|status=fail|elapsed_sec=."
        log close
        exit 199
    }
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

display ""
display ">>> 动态面板GMM参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    GMM类型: `gmm_type'"
display "    滞后阶数: `lags'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    display "SS_TASK_END|id=TP03|status=fail|elapsed_sec=."
    log close
    exit 601
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
        display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|severity=fail|var=`var'"
        display "SS_TASK_END|id=TP03|status=fail|elapsed_sec=."
        log close
        exit 200
    }
}

local valid_indep ""
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
    }
}

capture xtset `id_var' `time_var'
if _rc {
    local rc_xtset = _rc
    display "SS_RC|code=`rc_xtset'|cmd=xtset|msg=xtset_failed|severity=fail"
    display "SS_TASK_END|id=TP03|status=fail|elapsed_sec=."
    log close
    exit `rc_xtset'
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ GMM估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: `=upper("`gmm_type'")'GMM估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建滞后因变量
local lag_depvars ""
forvalues i = 1/`lags' {
    local lag_depvars "`lag_depvars' L`i'.`depvar'"
}

if "`gmm_type'" == "difference" {
    xtabond2 `depvar' `lag_depvars' `valid_indep', gmm(L.`depvar') iv(`valid_indep') ///
        noleveleq robust small
}
else {
    xtabond2 `depvar' `lag_depvars' `valid_indep', gmm(L.`depvar') iv(`valid_indep') ///
        robust small
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
export delimited using "table_TP03_gmm_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TP03_gmm_result.csv|type=table|desc=gmm_results"
restore

* ============ 诊断检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 诊断检验"
display "═══════════════════════════════════════════════════════════════════════════════"

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

export delimited using "table_TP03_diagnostics.csv", replace
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

save "data_TP03_gmm.dta", replace
display "SS_OUTPUT_FILE|file=data_TP03_gmm.dta|type=data|desc=gmm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_obs'
display "  组数:            " %10.0fc `n_groups'
display "  工具变量数:      " %10.0fc `n_inst'
display ""
display "  诊断检验:"
display "    AR(2) p值:     " %10.4f `ar2_p'
display "    Hansen p值:    " %10.4f `hansen_p'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=hansen_p|value=`hansen_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP03|status=ok|elapsed_sec=`elapsed'"
log close
