* ==============================================================================
* SS_TEMPLATE: id=TP10  level=L2  module=P  title="Panel Cointegration"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP10_cointegration.csv type=table desc="Cointegration tests"
*   - data_TP10_coint.dta type=data desc="Output data"
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

program define ss_fail_TP10
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP10|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP10|level=L2|title=Panel_Cointegration"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: cointegration tests require non-stationary series in levels; run panel unit-root checks first and interpret residual tests cautiously. /
*   最佳实践：协整检验通常要求水平序列非平稳；建议先做单位根检验，并谨慎解读残差检验。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/xtset/estimation/tests; warn on singleton panels /
*   错误策略：缺少输入/xtset/估计与检验失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP10|ssc=none|output=csv_dta|policy=warn_fail"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"

display ""
display ">>> 面板协整检验参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP10 601 "confirm file data.csv" "input_file_not_found"
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
        ss_fail_TP10 200 "confirm variable `var'" "var_not_found"
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
    ss_fail_TP10 200 "confirm numeric indepvars" "no_valid_indepvars"
}

capture xtset `id_var' `time_var'
if _rc {
    ss_fail_TP10 `=_rc' "xtset `id_var' `time_var'" "xtset_failed"
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

* ============ 估计协整回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 面板协整回归"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily xtreg `depvar' `valid_indep', fe
if _rc {
    ss_fail_TP10 `=_rc' "xtreg fe" "estimation_failed"
}
capture predict double resid_coint, e
if _rc {
    ss_fail_TP10 `=_rc' "predict resid_coint, e" "predict_failed"
}

local r2 = e(r2_w)
display ""
display ">>> 协整回归R2(within): " %8.4f `r2'

* ============ 残差单位根检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 残差单位根检验（协整检验）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ">>> 如果残差平稳，则存在协整关系..."

* LLC检验残差
capture noisily xtunitroot llc resid_coint, lags(1)
if _rc {
    ss_fail_TP10 `=_rc' "xtunitroot llc resid" "cointegration_test_failed"
}
local llc_stat = r(z_adj)
local llc_p = r(p_adj)

display ""
display ">>> LLC检验残差 (H0: 无协整):"
display "    z统计量: " %10.4f `llc_stat'
display "    p值: " %10.4f `llc_p'

* IPS检验残差
capture noisily xtunitroot ips resid_coint, lags(1)
if _rc {
    ss_fail_TP10 `=_rc' "xtunitroot ips resid" "cointegration_test_failed"
}
local ips_stat = r(Wtbar)
local ips_p = r(p_Wtbar)

display ""
display ">>> IPS检验残差 (H0: 无协整):"
display "    W-t-bar: " %10.4f `ips_stat'
display "    p值: " %10.4f `ips_p'

display "SS_METRIC|name=llc_p|value=`llc_p'"
display "SS_METRIC|name=ips_p|value=`ips_p'"

* ============ 结论 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 协整检验结论"
display "═══════════════════════════════════════════════════════════════════════════════"

if `llc_p' < 0.05 | `ips_p' < 0.05 {
    display ""
    display ">>> 结论: 存在协整关系（残差平稳）"
    local coint_conclusion = "存在协整"
}
else {
    display ""
    display ">>> 结论: 不存在协整关系（残差非平稳）"
    local coint_conclusion = "无协整"
}

* 导出结果
preserve
clear
set obs 2
generate str20 test = ""
generate double statistic = .
generate double p_value = .
generate str20 conclusion = ""

replace test = "LLC (residual)" in 1
replace statistic = `llc_stat' in 1
replace p_value = `llc_p' in 1
replace conclusion = "`coint_conclusion'" in 1

replace test = "IPS (residual)" in 2
replace statistic = `ips_stat' in 2
replace p_value = `ips_p' in 2
replace conclusion = "`coint_conclusion'" in 2

capture export delimited using "table_TP10_cointegration.csv", replace
if _rc {
    ss_fail_TP10 `=_rc' "export delimited table_TP10_cointegration.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP10_cointegration.csv|type=table|desc=coint_tests"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TP10_coint.dta", replace
if _rc {
    ss_fail_TP10 `=_rc' "save data_TP10_coint.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TP10_coint.dta|type=data|desc=coint_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP10 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  协整检验:"
display "    LLC p值:       " %10.4f `llc_p'
display "    IPS p值:       " %10.4f `ips_p'
display "    结论:          `coint_conclusion'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=llc_p|value=`llc_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP10|status=ok|elapsed_sec=`elapsed'"
log close
