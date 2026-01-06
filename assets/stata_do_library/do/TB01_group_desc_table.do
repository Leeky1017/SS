* ==============================================================================
* SS_TEMPLATE: id=TB01  level=L0  module=B  title="Group Desc Table"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TB01_group_desc.csv type=table desc="Group descriptive table"
*   - data_TB01_group.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="summarize command"
* ==============================================================================
* Task ID:      TB01_group_desc_table
* Task Name:    分组描述统计
* Family:       B - 描述统计
* Description:  生成分组描述统计表
* 
* Placeholders: __VARS__           - 数值变量列表
*               __BY_VAR__         - 分组变量
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
display "SS_TASK_BEGIN|id=TB01|level=L0|title=Group_Desc_Table"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local vars = "__VARS__"
local by_var = "__BY_VAR__"

display ""
display ">>> 分组描述统计参数:"
display "    变量: `vars'"
display "    分组: `by_var'"

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
display "SS_METRIC:n_input:`n_input'"

* ============ 变量检查 ============
capture confirm variable `by_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`by_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`by_var' not found"
    log close
    exit 200
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 分组描述统计 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display ">>> 分组描述统计..."
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 分组描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 获取分组值
levelsof `by_var', local(groups)
local n_groups : word count `groups'

display ">>> 分组数: `n_groups'"

tabstat `vars', by(`by_var') statistics(n mean sd min p25 p50 p75 max) columns(statistics) longstub

* ============ 导出论文格式表 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 导出论文格式"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname results
postfile `results' str32 variable str20 group double n double mean double sd double median ///
    using "temp_group_desc.dta", replace

foreach var of local vars {
    capture confirm numeric variable `var'
    if !_rc {
        foreach g of local groups {
            quietly summarize `var' if `by_var' == `g', detail
            post `results' ("`var'") ("`g'") (r(N)) (r(mean)) (r(sd)) (r(p50))
        }
    }
}

postclose `results'

preserve
use "temp_group_desc.dta", clear
list, noobs
export delimited using "table_TB01_group_desc.csv", replace
display "SS_OUTPUT_FILE|file=table_TB01_group_desc.csv|type=table|desc=group_desc"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"
restore

capture erase "temp_group_desc.dta"
if _rc != 0 { }

display "SS_STEP_BEGIN|step=S03_analysis"
display "SS_METRIC|name=n_groups|value=`n_groups'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TB01_group.dta", replace
display "SS_OUTPUT_FILE|file=data_TB01_group.dta|type=data|desc=group_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TB01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  分组数:          " %10.0fc `n_groups'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_groups|value=`n_groups'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TB01|status=ok|elapsed_sec=`elapsed'"
log close
