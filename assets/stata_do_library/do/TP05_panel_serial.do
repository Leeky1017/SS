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
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TP05|level=L2|title=Panel_Serial"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
capture which xtserial
if _rc {
    display "SS_DEP_MISSING:cmd=xtserial:hint=ssc install xtserial"
    display "SS_ERROR:DEP_MISSING:xtserial is required but not installed"
    display "SS_ERR:DEP_MISSING:xtserial is required but not installed"
    log close
    exit 199
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

* ============ Wooldridge检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Wooldridge序列相关检验"
display "═══════════════════════════════════════════════════════════════════════════════"

xtserial `depvar' `valid_indep'

local wooldridge_f = r(F)
local wooldridge_p = r(p)

display ""
display ">>> Wooldridge检验 (H0: 无一阶序列相关):"
display "    F统计量: " %10.4f `wooldridge_f'
display "    p值: " %10.4f `wooldridge_p'

if `wooldridge_p' < 0.05 {
    display "    结论: 存在一阶序列相关"
    local serial_conclusion = "存在序列相关"
}
else {
    display "    结论: 无显著序列相关"
    local serial_conclusion = "无序列相关"
}

display "SS_METRIC|name=wooldridge_f|value=`wooldridge_f'"
display "SS_METRIC|name=wooldridge_p|value=`wooldridge_p'"

* ============ 残差分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 残差序列相关分析"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly xtreg `depvar' `valid_indep', fe
predict double resid, e

* 残差滞后相关
bysort `id_var' (`time_var'): generate double L_resid = resid[_n-1]
quietly correlate resid L_resid
local rho1 = r(rho)

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

replace test = "Wooldridge" in 1
replace statistic = `wooldridge_f' in 1
replace p_value = `wooldridge_p' in 1
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
display "    Wooldridge F:  " %10.4f `wooldridge_f'
display "    p值:           " %10.4f `wooldridge_p'
display "    结论:          `serial_conclusion'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=wooldridge_p|value=`wooldridge_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP05|status=ok|elapsed_sec=`elapsed'"
log close
