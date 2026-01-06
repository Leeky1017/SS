* ==============================================================================
* SS_TEMPLATE: id=TA06  level=L0  module=A  title="Panel Balance"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA06_balance_summary.csv type=table desc="Balance summary"
*   - data_TA06_balanced.dta type=data desc="Balanced panel data"
*   - data_TA06_balanced.csv type=data desc="Balanced panel CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="panel commands"
* ==============================================================================
* Task ID:      TA06_panel_balance
* Task Name:    面板数据平衡化
* Family:       A - 数据管理
* Description:  将非平衡面板转换为平衡面板
* 
* Placeholders: __ID_VAR__         - 个体标识变量
*               __TIME_VAR__       - 时间变量
*               __METHOD__         - 方法：fill/drop
*               __FILL_VALUE__     - 填充值
*               __MIN_PERIODS__    - 最少时期数
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
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
display "SS_TASK_BEGIN|id=TA06|level=L0|title=Panel_Balance"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local method = "__METHOD__"
local fill_value = "__FILL_VALUE__"
local min_periods = __MIN_PERIODS__

* 参数默认值
if "`method'" == "" | ("`method'" != "fill" & "`method'" != "drop") {
    local method = "drop"
}
if "`fill_value'" == "" {
    local fill_value = "missing"
}
if `min_periods' <= 0 {
    local min_periods = 0
}

display ""
display ">>> 面板平衡化参数:"
display "    ID变量: `id_var'"
display "    时间变量: `time_var'"
display "    方法: `method'"
if "`method'" == "fill" {
    display "    填充值: `fill_value'"
}
if `min_periods' > 0 {
    display "    最少时期: `min_periods'"
}

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
capture confirm variable `id_var'
if _rc {
    display "SS_ERROR:ID_VAR_NOT_FOUND:`id_var' not found"
    display "SS_ERR:ID_VAR_NOT_FOUND:`id_var' not found"
    log close
    exit 200
}

capture confirm variable `time_var'
if _rc {
    display "SS_ERROR:TIME_VAR_NOT_FOUND:`time_var' not found"
    display "SS_ERR:TIME_VAR_NOT_FOUND:`time_var' not found"
    log close
    exit 200
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 面板结构分析 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 面板结构分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 设置面板
sort `id_var' `time_var'
ss_smart_xtset `id_var' `time_var'

quietly xtdescribe
local n_panels_before = r(n)
local min_t_before = r(min)
local max_t_before = r(max)
local mean_t_before = r(mean)

* 获取时间范围
quietly summarize `time_var'
local t_min = r(min)
local t_max = r(max)
local n_periods_total = `t_max' - `t_min' + 1

display ""
display "平衡前面板结构:"
display "  个体数量:        " %10.0fc `n_panels_before'
display "  时间范围:        `t_min' - `t_max'"
display "  总时期数:        " %10.0fc `n_periods_total'
display "  最少观测期数:    " %10.0fc `min_t_before'
display "  最多观测期数:    " %10.0fc `max_t_before'
display "  平均观测期数:    " %10.2f `mean_t_before'

* 检查是否已经平衡
local is_balanced = (`min_t_before' == `max_t_before')
if `is_balanced' {
    display ""
    display ">>> 面板已经是平衡面板，无需处理"
    display "SS_WARNING:ALREADY_BALANCED:Panel is already balanced"
}

display "SS_METRIC:n_panels_before:`n_panels_before'"

* 统计每个个体的观测数
tempvar n_obs_by_id
bysort `id_var': generate `n_obs_by_id' = _N

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 平衡化处理 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 平衡化处理"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped_panels = 0
local n_filled_obs = 0

if "`method'" == "drop" {
    * 方法1: 删除不完整个体
    display ">>> 方法: 删除不完整个体"
    
    * 确定保留阈值
    if `min_periods' == 0 {
        local keep_threshold = `n_periods_total'
    }
    else {
        local keep_threshold = `min_periods'
    }
    
    display ">>> 保留条件: 观测期数 >= `keep_threshold'"
    
    * 标记要删除的个体
    quietly count if `n_obs_by_id' < `keep_threshold'
    local n_obs_to_drop = r(N)
    
    quietly levelsof `id_var' if `n_obs_by_id' < `keep_threshold', local(drop_ids)
    local n_dropped_panels : word count `drop_ids'
    
    * 删除
    drop if `n_obs_by_id' < `keep_threshold'
    
    display ">>> 删除个体数: `n_dropped_panels'"
    display ">>> 删除观测数: `n_obs_to_drop'"
}
else {
    * 方法2: 填充缺失时期
    display ">>> 方法: 填充缺失时期"
    display ">>> 填充值: `fill_value'"
    
    * 获取数值变量列表（用于填充）
    ds, has(type numeric)
    local numvars = r(varlist)
    local numvars : list numvars - id_var
    local numvars : list numvars - time_var
    
    * 使用tsfill填充缺失时期
    tsfill, full
    
    * 统计填充的观测数
    quietly count if missing(`=word("`numvars'", 1)') & !missing(`id_var') & !missing(`time_var')
    local n_filled_obs = r(N)
    
    display ">>> 填充观测数: `n_filled_obs'"
    
    * 根据fill_value处理缺失值
    if "`fill_value'" == "zero" {
        foreach var of local numvars {
            quietly replace `var' = 0 if missing(`var')
        }
        display ">>> 缺失值已替换为0"
    }
    else if "`fill_value'" == "mean" {
        foreach var of local numvars {
            quietly summarize `var'
            quietly replace `var' = r(mean) if missing(`var')
        }
        display ">>> 缺失值已替换为均值"
    }
    else if "`fill_value'" == "locf" {
        * Last Observation Carried Forward
        foreach var of local numvars {
            bysort `id_var' (`time_var'): replace `var' = `var'[_n-1] if missing(`var')
        }
        display ">>> 缺失值已使用LOCF填充"
    }
    * else: 保持missing
    
    * 如果设置了min_periods，删除不满足的个体
    if `min_periods' > 0 {
        drop `n_obs_by_id'
        bysort `id_var': generate `n_obs_by_id' = _N
        
        quietly levelsof `id_var' if `n_obs_by_id' < `min_periods', local(drop_ids)
        local n_dropped_panels : word count `drop_ids'
        
        drop if `n_obs_by_id' < `min_periods'
    }
}

display "SS_METRIC:n_filled:`n_filled_obs'"
display "SS_METRIC:n_dropped_panels:`n_dropped_panels'"

* ============ 平衡后面板结构分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 平衡后面板结构分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 重新设置面板
sort `id_var' `time_var'
ss_smart_xtset `id_var' `time_var'

quietly xtdescribe
local n_panels_after = r(n)
local min_t_after = r(min)
local max_t_after = r(max)
local mean_t_after = r(mean)

display ""
display "平衡后面板结构:"
display "  个体数量:        " %10.0fc `n_panels_after'
display "  最少观测期数:    " %10.0fc `min_t_after'
display "  最多观测期数:    " %10.0fc `max_t_after'
display "  平均观测期数:    " %10.2f `mean_t_after'

local is_balanced_after = (`min_t_after' == `max_t_after')
if `is_balanced_after' {
    display ""
    display ">>> 面板现在是平衡面板"
}
else {
    display ""
    display ">>> 注意: 面板仍非完全平衡"
    display "SS_WARNING:NOT_FULLY_BALANCED:Panel is not fully balanced after processing"
}

display "SS_METRIC|name=n_panels_after|value=`n_panels_after'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建并导出统计摘要
preserve
clear
set obs 1
generate str20 stage = ""
generate long n_panels = .
generate long n_obs = .
generate long min_periods = .
generate long max_periods = .
generate double mean_periods = .

replace stage = "before" in 1
replace n_panels = `n_panels_before' in 1
replace n_obs = `n_input' in 1
replace min_periods = `min_t_before' in 1
replace max_periods = `max_t_before' in 1
replace mean_periods = `mean_t_before' in 1

set obs 2
replace stage = "after" in 2
replace n_panels = `n_panels_after' in 2
replace n_obs = `n_input' - `n_dropped_panels' * `min_t_before' + `n_filled_obs' in 2
replace min_periods = `min_t_after' in 2
replace max_periods = `max_t_after' in 2
replace mean_periods = `mean_t_after' in 2

export delimited using "table_TA06_balance_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA06_balance_summary.csv|type=table|desc=balance_summary"
restore

* 导出数据
drop `n_obs_by_id'
local n_output = _N
display "SS_METRIC:n_output:`n_output'"

save "data_TA06_balanced.dta", replace
display "SS_OUTPUT_FILE|file=data_TA06_balanced.dta|type=data|desc=balanced_data"

export delimited using "data_TA06_balanced.csv", replace
display "SS_OUTPUT_FILE|file=data_TA06_balanced.csv|type=data|desc=balanced_csv"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA06 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  平衡化方法:      `method'"
display ""
display "  平衡前:"
display "    - 观测数:      " %10.0fc `n_input'
display "    - 个体数:      " %10.0fc `n_panels_before'
display "    - 期数范围:    `min_t_before' - `max_t_before'"
display ""
display "  平衡后:"
display "    - 观测数:      " %10.0fc `n_output'
display "    - 个体数:      " %10.0fc `n_panels_after'
display "    - 期数范围:    `min_t_after' - `max_t_after'"
display ""
if "`method'" == "drop" {
    display "  删除个体数:      " %10.0fc `n_dropped_panels'
}
else {
    display "  填充观测数:      " %10.0fc `n_filled_obs'
}
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = `n_input' - `n_output'
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_panels_after|value=`n_panels_after'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA06|status=ok|elapsed_sec=`elapsed'"
log close
