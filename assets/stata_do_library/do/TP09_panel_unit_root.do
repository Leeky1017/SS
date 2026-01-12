* ==============================================================================
* SS_TEMPLATE: id=TP09  level=L2  module=P  title="Panel Unit Root"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP09_unit_root.csv type=table desc="Unit root tests"
*   - data_TP09_unit_root.dta type=data desc="Output data"
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

program define ss_fail_TP09
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP09|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP09|level=L2|title=Panel_Unit_Root"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: panel unit-root results depend on lag choice and cross-sectional dependence; treat as input to downstream cointegration/levels vs differences. /
*   最佳实践：面板单位根结果受滞后与截面相关影响；用于指导后续协整检验/差分处理。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/xtset/tests; warn on singleton panels /
*   错误策略：缺少输入/xtset/检验失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP09|ssc=none|output=csv_dta|policy=warn_fail"

* ============ 参数设置 ============
local var = "__VAR__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local lags = __LAGS__

if `lags' < 0 | `lags' > 10 {
    local lags = 1
}

display ""
display ">>> 面板单位根检验参数:"
display "    检验变量: `var'"
display "    滞后阶数: `lags'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP09 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach v in `var' `id_var' `time_var' {
    capture confirm variable `v'
    if _rc {
        ss_fail_TP09 200 "confirm variable `v'" "var_not_found"
    }
}
capture confirm numeric variable `var'
if _rc {
    ss_fail_TP09 200 "confirm numeric variable `var'" "series_var_not_numeric"
}

capture xtset `id_var' `time_var'
if _rc {
    ss_fail_TP09 `=_rc' "xtset `id_var' `time_var'" "xtset_failed"
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

* ============ LLC检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Levin-Lin-Chu检验"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily xtunitroot llc `var', lags(`lags')
if _rc {
    ss_fail_TP09 `=_rc' "xtunitroot llc" "unit_root_test_failed"
}

local llc_stat = r(z_adj)
local llc_p = r(p_adj)

display ""
display ">>> LLC检验 (H0: 所有面板有单位根):"
display "    调整后z统计量: " %10.4f `llc_stat'
display "    p值: " %10.4f `llc_p'

display "SS_METRIC|name=llc_stat|value=`llc_stat'"
display "SS_METRIC|name=llc_p|value=`llc_p'"

* ============ IPS检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Im-Pesaran-Shin检验"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily xtunitroot ips `var', lags(`lags')
if _rc {
    ss_fail_TP09 `=_rc' "xtunitroot ips" "unit_root_test_failed"
}

local ips_stat = r(Wtbar)
local ips_p = r(p_Wtbar)

display ""
display ">>> IPS检验 (H0: 所有面板有单位根):"
display "    W-t-bar统计量: " %10.4f `ips_stat'
display "    p值: " %10.4f `ips_p'

display "SS_METRIC|name=ips_stat|value=`ips_stat'"
display "SS_METRIC|name=ips_p|value=`ips_p'"

* ============ Fisher-ADF检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: Fisher-ADF检验"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily xtunitroot fisher `var', dfuller lags(`lags')
if _rc {
    ss_fail_TP09 `=_rc' "xtunitroot fisher" "unit_root_test_failed"
}

local fisher_chi2 = r(chi2_p)
local fisher_p = r(P_chi2_p)
display "SS_METRIC|name=fisher_chi2|value=`fisher_chi2'"
display "SS_METRIC|name=fisher_p|value=`fisher_p'"

display ""
display ">>> Fisher-ADF检验 (H0: 所有面板有单位根):"
display "    χ²统计量: " %10.4f `fisher_chi2'
display "    p值: " %10.4f `fisher_p'

* ============ 结论 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 综合结论"
display "═══════════════════════════════════════════════════════════════════════════════"

local conclusion = "平稳"
if `llc_p' >= 0.05 & `ips_p' >= 0.05 {
    local conclusion = "非平稳(有单位根)"
}

display ""
display ">>> 综合结论: `conclusion'"

* 导出结果
preserve
clear
set obs 3
generate str20 test = ""
generate double statistic = .
generate double p_value = .

replace test = "LLC" in 1
replace statistic = `llc_stat' in 1
replace p_value = `llc_p' in 1

replace test = "IPS" in 2
replace statistic = `ips_stat' in 2
replace p_value = `ips_p' in 2

replace test = "Fisher-ADF" in 3
replace statistic = `fisher_chi2' in 3
replace p_value = `fisher_p' in 3

capture export delimited using "table_TP09_unit_root.csv", replace
if _rc {
    ss_fail_TP09 `=_rc' "export delimited table_TP09_unit_root.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP09_unit_root.csv|type=table|desc=unit_root_tests"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TP09_unit_root.dta", replace
if _rc {
    ss_fail_TP09 `=_rc' "save data_TP09_unit_root.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TP09_unit_root.dta|type=data|desc=unit_root_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP09 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  单位根检验:"
display "    LLC p值:       " %10.4f `llc_p'
display "    IPS p值:       " %10.4f `ips_p'
display "    Fisher p值:    " %10.4f `fisher_p'
display "    结论:          `conclusion'"
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

display "SS_TASK_END|id=TP09|status=ok|elapsed_sec=`elapsed'"
log close
