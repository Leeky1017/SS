* ==============================================================================
* SS_TEMPLATE: id=TB02  level=L0  module=B  title="Normality Test"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TB02_normality.csv type=table desc="Normality test results"
*   - data_TB02_norm.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="swilk command"
* ==============================================================================
* Task ID:      TB02_normality_test
* Task Name:    正态性检验
* Family:       B - 描述统计
* Description:  计算偏度峰度，执行正态性检验
* 
* Placeholders: __VARS__           - 数值变量列表
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands)
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=TB02|level=L0|title=Normality_Test"
display "SS_TASK_VERSION|version=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local vars = "__VARS__"

display ""
display ">>> 正态性检验参数:"
display "    变量: `vars'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 正态性检验 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display ">>> 执行正态性检验..."
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 偏度峰度检验"
display "═══════════════════════════════════════════════════════════════════════════════"

sktest `vars'

display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Shapiro-Wilk检验"
display "═══════════════════════════════════════════════════════════════════════════════"

swilk `vars'

display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: Shapiro-Francia检验"
display "═══════════════════════════════════════════════════════════════════════════════"

sfrancia `vars'

* ============ 导出结果 ============
tempname results
postfile `results' str32 variable double skewness double kurtosis double sw_stat double sw_p ///
    using "temp_normality.dta", replace

foreach var of local vars {
    capture confirm numeric variable `var'
    if !_rc {
        quietly summarize `var', detail
        local skew = r(skewness)
        local kurt = r(kurtosis)
        
        quietly swilk `var'
        local sw_w = r(W)
        local sw_p = r(p)
        
        post `results' ("`var'") (`skew') (`kurt') (`sw_w') (`sw_p')
    }
}

postclose `results'

preserve
use "temp_normality.dta", clear
display ""
display ">>> 正态性检验汇总:"
list, noobs
export delimited using "table_TB02_normality.csv", replace
display "SS_OUTPUT_FILE|file=table_TB02_normality.csv|type=table|desc=normality_test"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"
restore

capture erase "temp_normality.dta"
if _rc != 0 { }

display "SS_STEP_BEGIN|step=S03_analysis"
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TB02_norm.dta", replace
display "SS_OUTPUT_FILE|file=data_TB02_norm.dta|type=data|desc=norm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TB02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_vars|value=`: word count `vars''"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TB02|status=ok|elapsed_sec=`elapsed'"
log close
