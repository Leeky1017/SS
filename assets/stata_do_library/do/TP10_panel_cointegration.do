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
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TP10|level=L2|title=Panel_Cointegration"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

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
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
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
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
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

ss_smart_xtset `id_var' `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 估计协整回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 面板协整回归"
display "═══════════════════════════════════════════════════════════════════════════════"

xtreg `depvar' `valid_indep', fe
predict double resid_coint, e

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
xtunitroot llc resid_coint, lags(1)
local llc_stat = r(z_adj)
local llc_p = r(p_adj)

display ""
display ">>> LLC检验残差 (H0: 无协整):"
display "    z统计量: " %10.4f `llc_stat'
display "    p值: " %10.4f `llc_p'

* IPS检验残差
xtunitroot ips resid_coint, lags(1)
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

export delimited using "table_TP10_cointegration.csv", replace
display "SS_OUTPUT_FILE|file=table_TP10_cointegration.csv|type=table|desc=coint_tests"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TP10_coint.dta", replace
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
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP10|status=ok|elapsed_sec=`elapsed'"
log close
