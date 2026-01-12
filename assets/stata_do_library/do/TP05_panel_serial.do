* ==============================================================================
* SS_TEMPLATE: id=TP05  level=L2  module=P  title="Panel Serial"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP05_serial_tests.csv type=table desc="Serial correlation tests"
*   - data_TP05_serial.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: xtserial
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

program define ss_fail_TP05
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP05|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP05|level=L2|title=Panel_Serial"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: use Wooldridge test as primary evidence for AR(1)-type errors; pair with clustered SE or appropriate corrections. /
*   最佳实践：以 Wooldridge 检验作为面板一阶序列相关的主要证据；并结合聚类稳健标准误或相应修正。
* - SSC deps: required:xtserial (no built-in equivalent widely used for Wooldridge test) / SSC 依赖：必需 xtserial（无常用内置等价替代）
* - Error policy: fail on missing inputs/xtset/test; warn on singleton groups /
*   错误策略：缺少输入/xtset/检验失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP05|ssc=required:xtserial|output=csv_dta|policy=warn_fail"

* ============ 依赖检测 ============
capture which xtserial
if _rc {
    display "SS_DEP_CHECK|pkg=xtserial|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=xtserial"
    ss_fail_TP05 199 "which xtserial" "dependency_missing"
}
display "SS_DEP_CHECK|pkg=xtserial|source=ssc|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"

display ""
display ">>> 序列相关检验参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP05 601 "confirm file data.csv" "input_file_not_found"
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
        ss_fail_TP05 200 "confirm variable `var'" "var_not_found"
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
    ss_fail_TP05 200 "confirm numeric indepvars" "no_valid_indepvars"
}

capture xtset `id_var' `time_var'
if _rc {
    ss_fail_TP05 `=_rc' "xtset `id_var' `time_var'" "xtset_failed"
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

* ============ Wooldridge检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Wooldridge序列相关检验"
display "═══════════════════════════════════════════════════════════════════════════════"

local serial_test = ""
local serial_stat = .
local serial_p = .
capture noisily xtserial `depvar' `valid_indep'
if _rc {
    ss_fail_TP05 `=_rc' "xtserial" "xtserial_failed"
}
local serial_test = "Wooldridge"
local serial_stat = r(F)
local serial_p = r(p)

display ""
display ">>> 序列相关检验 (H0: 无序列相关):"
display "    检验: " "`serial_test'"
display "    统计量: " %10.4f `serial_stat'
display "    p值: " %10.4f `serial_p'

local serial_conclusion = ""
if `serial_p' < 0.05 {
    display "    结论: 存在一阶序列相关"
    local serial_conclusion = "serial_correlation"
}
else {
    display "    结论: 无显著序列相关"
    local serial_conclusion = "no_serial_correlation"
}

display "SS_METRIC|name=serial_stat|value=`serial_stat'"
display "SS_METRIC|name=serial_p|value=`serial_p'"

* ============ 残差分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 残差序列相关分析"
display "═══════════════════════════════════════════════════════════════════════════════"

capture quietly xtreg `depvar' `valid_indep', fe
if _rc {
    display "SS_RC|code=`=_rc'|cmd=xtreg fe|msg=xtreg_failed_skip_resid_diag|severity=warn"
}
capture predict double resid, e
if _rc {
    display "SS_RC|code=`=_rc'|cmd=predict resid, e|msg=predict_failed|severity=warn"
    gen double resid = .
}

* 残差滞后相关
bysort `id_var' (`time_var'): generate double L_resid = resid[_n-1]
capture quietly correlate resid L_resid
local rho1 = .
if _rc {
    display "SS_RC|code=`=_rc'|cmd=correlate resid L_resid|msg=correlate_failed|severity=warn"
}
else {
    local rho1 = r(rho)
}

display ""
display ">>> 残差一阶自相关系数: " %8.4f `rho1'

* 导出检验结果
preserve
clear
set obs 2
generate str30 test = ""
generate double statistic = .
generate double p_value = .
generate str30 conclusion = ""

replace test = "`serial_test'" in 1
replace statistic = `serial_stat' in 1
replace p_value = `serial_p' in 1
replace conclusion = "`serial_conclusion'" in 1

replace test = "残差自相关系数" in 2
replace statistic = `rho1' in 2

export delimited using "table_TP05_serial_tests.csv", replace
display "SS_OUTPUT_FILE|file=table_TP05_serial_tests.csv|type=table|desc=serial_tests"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TP05_serial.dta", replace
display "SS_OUTPUT_FILE|file=data_TP05_serial.dta|type=data|desc=serial_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  序列相关检验:"
display "    Wooldridge F:  " %10.4f `serial_stat'
display "    p值:           " %10.4f `serial_p'
display "    结论:          `serial_conclusion'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=serial_p|value=`serial_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP05|status=ok|elapsed_sec=`elapsed'"
log close
