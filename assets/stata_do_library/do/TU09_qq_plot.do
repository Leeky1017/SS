* ==============================================================================
* SS_TEMPLATE: id=TU09  level=L1  module=U  title="QQ Plot"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU09_qq.png type=figure desc="QQ plot"
*   - table_TU09_normality.csv type=table desc="Normality test"
*   - data_TU09_qq.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TU09|level=L1|title=QQ_Plot"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local var = "__VAR__"

display ""
display ">>> Q-Q图参数:"
display "    变量: `var'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
capture confirm numeric variable `var'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=var_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 正态性检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 正态性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

swilk `var'
local sw_stat = r(W)
local sw_p = r(p)

display ""
display ">>> Shapiro-Wilk检验:"
display "    W统计量: " %10.6f `sw_stat'
display "    p值: " %10.4f `sw_p'

if `sw_p' >= 0.05 {
    display "    结论: 不能拒绝正态性假设"
    local conclusion = "近似正态"
}
else {
    display "    结论: 拒绝正态性假设"
    local conclusion = "非正态"
}

display "SS_METRIC|name=sw_stat|value=`sw_stat'"
display "SS_METRIC|name=sw_p|value=`sw_p'"

* 偏度和峰度
summarize `var', detail
local skewness = r(skewness)
local kurtosis = r(kurtosis)

display ""
display ">>> 偏度: " %10.4f `skewness'
display ">>> 峰度: " %10.4f `kurtosis'

* 导出正态性检验结果
preserve
clear
set obs 4
generate str30 test = ""
generate double value = .

replace test = "Shapiro-Wilk W" in 1
replace value = `sw_stat' in 1
replace test = "Shapiro-Wilk p" in 2
replace value = `sw_p' in 2
replace test = "偏度" in 3
replace value = `skewness' in 3
replace test = "峰度" in 4
replace value = `kurtosis' in 4

export delimited using "table_TU09_normality.csv", replace
display "SS_OUTPUT_FILE|file=table_TU09_normality.csv|type=table|desc=normality_test"
restore

* ============ 绘制Q-Q图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 绘制Q-Q图"
display "═══════════════════════════════════════════════════════════════════════════════"

qnorm `var', ///
    title("Q-Q图: `var'") ///
    xtitle("理论分位数") ytitle("样本分位数") ///
    note("Shapiro-Wilk p=`=round(`sw_p', 0.001)', `conclusion'")

graph export "fig_TU09_qq.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU09_qq.png|type=figure|desc=qq_plot"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU09_qq.dta", replace
display "SS_OUTPUT_FILE|file=data_TU09_qq.dta|type=data|desc=qq_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU09 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  正态性检验:"
display "    SW W:          " %10.6f `sw_stat'
display "    p值:           " %10.4f `sw_p'
display "    结论:          `conclusion'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=sw_p|value=`sw_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU09|status=ok|elapsed_sec=`elapsed'"
log close
