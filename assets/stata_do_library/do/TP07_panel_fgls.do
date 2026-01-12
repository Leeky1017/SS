* ==============================================================================
* SS_TEMPLATE: id=TP07  level=L2  module=P  title="Panel FGLS"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP07_fgls_result.csv type=table desc="FGLS results"
*   - data_TP07_fgls.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
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

program define ss_fail_TP07
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP07|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP07|level=L2|title=Panel_FGLS"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: FGLS relies on error-structure assumptions; use with diagnostics and compare against cluster-robust FE/RE where possible. /
*   最佳实践：FGLS 依赖误差结构假设；建议配合诊断，并与聚类稳健 FE/RE 对照。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/xtset/estimation; warn on singleton groups /
*   错误策略：缺少输入/xtset/估计失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP07|ssc=none|output=csv_dta|policy=warn_fail"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local corr_type = "__CORR_TYPE__"

if "`corr_type'" == "" {
    local corr_type = "ar1"
}

display ""
display ">>> FGLS参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    相关结构: `corr_type'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP07 601 "confirm file data.csv" "input_file_not_found"
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
        ss_fail_TP07 200 "confirm variable `var'" "var_not_found"
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
    ss_fail_TP07 200 "confirm numeric indepvars" "no_valid_indepvars"
}

capture xtset `id_var' `time_var'
if _rc {
    ss_fail_TP07 `=_rc' "xtset `id_var' `time_var'" "xtset_failed"
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

* ============ FGLS估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: FGLS估计"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`corr_type'" == "independent" {
    capture noisily xtgls `depvar' `valid_indep', panels(heteroskedastic)
    if _rc {
        ss_fail_TP07 `=_rc' "xtgls" "estimation_failed"
    }
}
else if "`corr_type'" == "ar1" {
    capture noisily xtgls `depvar' `valid_indep', panels(heteroskedastic) corr(ar1)
    if _rc {
        ss_fail_TP07 `=_rc' "xtgls" "estimation_failed"
    }
}
else {
    capture noisily xtgls `depvar' `valid_indep', panels(heteroskedastic) corr(psar1)
    if _rc {
        ss_fail_TP07 `=_rc' "xtgls" "estimation_failed"
    }
}

local n_obs = e(N)
local n_groups = e(N_g)
local ll = e(ll)

display ""
display ">>> FGLS拟合:"
display "    观测数: `n_obs'"
display "    组数: `n_groups'"
display "    对数似然: " %12.4f `ll'

display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=ll|value=`ll'"

* 导出结果
tempname fgls_results
postfile `fgls_results' str32 variable double coef double se double z double p ///
    using "temp_fgls_results.dta", replace

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
    post `fgls_results' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `fgls_results'

preserve
use "temp_fgls_results.dta", clear
capture export delimited using "table_TP07_fgls_result.csv", replace
if _rc {
    ss_fail_TP07 `=_rc' "export delimited table_TP07_fgls_result.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP07_fgls_result.csv|type=table|desc=fgls_results"
restore

capture erase "temp_fgls_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TP07_fgls.dta", replace
if _rc {
    ss_fail_TP07 `=_rc' "save data_TP07_fgls.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TP07_fgls.dta|type=data|desc=fgls_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP07 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_obs'
display "  组数:            " %10.0fc `n_groups'
display "  相关结构:        `corr_type'"
display "  对数似然:        " %10.4f `ll'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=ll|value=`ll'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP07|status=ok|elapsed_sec=`elapsed'"
log close
