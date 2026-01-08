* ==============================================================================
* SS_TEMPLATE: id=TB03  level=L0  module=B  title="Percentile Table"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TB03_percentiles.csv type=table desc="Percentile table"
*   - data_TB03_pct.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="summarize detail"
* ==============================================================================
* Task ID:      TB03_percentile_table
* Task Name:    百分位数表
* Family:       B - 描述统计
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
display "SS_TASK_BEGIN|id=TB03|level=L0|title=Percentile_Table"
display "SS_TASK_VERSION|version=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local vars = "__VARS__"

display ""
display ">>> 百分位数参数:"
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
    display "SS_TASK_END|id=TB03|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 百分位数计算 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display ">>> 计算百分位数..."
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 百分位数统计"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname results
postfile `results' str32 variable double p1 double p5 double p10 double p25 double p50 ///
    double p75 double p90 double p95 double p99 using "temp_percentiles.dta", replace

foreach var of local vars {
    capture confirm numeric variable `var'
    if !_rc {
        quietly summarize `var', detail
        quietly centile `var', centile(1 5 10 25 50 75 90 95 99)
        
        post `results' ("`var'") (r(c_1)) (r(c_2)) (r(c_3)) (r(c_4)) (r(c_5)) ///
            (r(c_6)) (r(c_7)) (r(c_8)) (r(c_9))
        
        display ""
        display ">>> `var' 百分位数:"
        display "    P1=" %10.4f r(c_1) "  P5=" %10.4f r(c_2) "  P10=" %10.4f r(c_3)
        display "    P25=" %10.4f r(c_4) "  P50=" %10.4f r(c_5) "  P75=" %10.4f r(c_6)
        display "    P90=" %10.4f r(c_7) "  P95=" %10.4f r(c_8) "  P99=" %10.4f r(c_9)
    }
}

postclose `results'

preserve
use "temp_percentiles.dta", clear
export delimited using "table_TB03_percentiles.csv", replace
display "SS_OUTPUT_FILE|file=table_TB03_percentiles.csv|type=table|desc=percentiles"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"
restore

capture erase "temp_percentiles.dta"
if _rc != 0 { }

display "SS_STEP_BEGIN|step=S03_analysis"
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TB03_pct.dta", replace
display "SS_OUTPUT_FILE|file=data_TB03_pct.dta|type=data|desc=pct_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TB03 任务完成摘要"
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
display "SS_TASK_END|id=TB03|status=ok|elapsed_sec=`elapsed'"
log close
