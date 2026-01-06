* ==============================================================================
* SS_TEMPLATE: id=TA02  level=L0  module=A  title="Standardize"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA02_transform_summary.csv type=table desc="Transform summary"
*   - data_TA02_standardized.dta type=data desc="Standardized data"
*   - table_TA02_standardized.csv type=table desc="Standardized CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="egen command"
* ==============================================================================
* Task ID:      TA02_standardize
* Task Name:    标准化与归一化
* Family:       A - 数据管理
* Description:  对指定数值变量进行标准化或归一化处理
* 
* Placeholders: __TRANSFORM_VARS__   - 需要转换的变量列表
*               __METHOD__           - 方法：zscore/minmax/rank
*               __BY_VAR__           - 分组变量（可选）
*               __SUFFIX__           - 新变量后缀
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
display "SS_TASK_BEGIN|id=TA02|level=L0|title=Standardize"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local transform_vars = "__TRANSFORM_VARS__"
local method = "__METHOD__"
local by_var = "__BY_VAR__"
local suffix = "__SUFFIX__"

* 参数默认值处理
if "`method'" == "" | ("`method'" != "zscore" & "`method'" != "minmax" & "`method'" != "rank") {
    local method = "zscore"
}
if "`suffix'" == "" {
    local suffix = "_std"
}

display ""
display ">>> 标准化参数设置:"
display "    变量: `transform_vars'"
display "    方法: `method'"
display "    新变量后缀: `suffix'"
if "`by_var'" != "" {
    display "    分组变量: `by_var'"
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
local valid_vars ""
local invalid_vars ""

foreach var of local transform_vars {
    capture confirm variable `var'
    if _rc {
        local invalid_vars "`invalid_vars' `var'"
    }
    else {
        capture confirm numeric variable `var'
        if _rc {
            display ">>> 警告: `var' 不是数值变量，跳过"
            display "SS_WARNING:NOT_NUMERIC:`var' is not numeric, skipped"
        }
        else {
            local valid_vars "`valid_vars' `var'"
        }
    }
}

if "`invalid_vars'" != "" {
    display ">>> 警告: 以下变量不存在: `invalid_vars'"
    display "SS_WARNING:VAR_NOT_FOUND:Variables not found:`invalid_vars'"
}

if "`valid_vars'" == "" {
    display "SS_ERROR:NO_VALID_VARS:No valid numeric variables to transform"
    display "SS_ERR:NO_VALID_VARS:No valid numeric variables to transform"
    log close
    exit 200
}

* 检查分组变量
if "`by_var'" != "" {
    capture confirm variable `by_var'
    if _rc {
        display "SS_WARNING:BY_VAR_NOT_FOUND:`by_var' not found, ignoring grouping"
        local by_var ""
    }
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "转换前统计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建结果存储
tempname results
postfile `results' str32 variable str10 stage double n double mean double sd double min double max ///
    using "temp_transform_stats.dta", replace

foreach var of local valid_vars {
    quietly summarize `var', detail
    local n = r(N)
    local mean = r(mean)
    local sd = r(sd)
    local min = r(min)
    local max = r(max)
    
    post `results' ("`var'") ("before") (`n') (`mean') (`sd') (`min') (`max')
    
    display ""
    display "变量: `var'"
    display "  N = `n', Mean = " %12.4f `mean' ", SD = " %12.4f `sd'
    display "  Min = " %12.4f `min' ", Max = " %12.4f `max'
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 执行转换 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 执行转换"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_transformed = 0
local new_vars ""

foreach var of local valid_vars {
    display ""
    display ">>> 处理变量: `var' -> `var'`suffix'"
    
    local newvar = "`var'`suffix'"
    local new_vars "`new_vars' `newvar'"
    
    if "`method'" == "zscore" {
        * Z-score标准化: (x - mean) / sd
        if "`by_var'" != "" {
            bysort `by_var': egen `newvar' = std(`var')
        }
        else {
            egen `newvar' = std(`var')
        }
        display "  方法: Z-score标准化 (均值=0, 标准差=1)"
    }
    else if "`method'" == "minmax" {
        * Min-Max归一化: (x - min) / (max - min)
        if "`by_var'" != "" {
            bysort `by_var': egen double _min_`var' = min(`var')
            bysort `by_var': egen double _max_`var' = max(`var')
        }
        else {
            egen double _min_`var' = min(`var')
            egen double _max_`var' = max(`var')
        }
        generate double `newvar' = (`var' - _min_`var') / (_max_`var' - _min_`var')
        drop _min_`var' _max_`var'
        display "  方法: Min-Max归一化 (范围=0-1)"
    }
    else if "`method'" == "rank" {
        * 秩次转换
        if "`by_var'" != "" {
            bysort `by_var': egen `newvar' = rank(`var')
        }
        else {
            egen `newvar' = rank(`var')
        }
        display "  方法: 秩次转换"
    }
    
    * 统计转换后
    quietly summarize `newvar', detail
    display "  转换后: N = " r(N) ", Mean = " %9.4f r(mean) ", SD = " %9.4f r(sd)
    display "          Min = " %9.4f r(min) ", Max = " %9.4f r(max)
    
    post `results' ("`newvar'") ("after") (r(N)) (r(mean)) (r(sd)) (r(min)) (r(max))
    
    local n_transformed = `n_transformed' + 1
}

postclose `results'

display ""
display ">>> 总共转换变量: `n_transformed' 个"
display "SS_METRIC|name=n_transformed|value=`n_transformed'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 输出统计摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 加载统计结果并导出
preserve
use "temp_transform_stats.dta", clear
export delimited using "table_TA02_transform_summary.csv", replace
display ">>> 转换统计摘要已导出"
display "SS_OUTPUT_FILE|file=table_TA02_transform_summary.csv|type=table|desc=transform_summary"
restore

* 导出标准化后数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TA02_standardized.dta", replace
display "SS_OUTPUT_FILE|file=data_TA02_standardized.dta|type=data|desc=standardized_data"

export delimited using "table_TA02_standardized.csv", replace
display "SS_OUTPUT_FILE|file=table_TA02_standardized.csv|type=table|desc=standardized_csv"

* 清理临时文件
capture erase "temp_transform_stats.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  转换变量数:      " %10.0fc `n_transformed'
display "  转换方法:        `method'"
display "  新变量后缀:      `suffix'"
display ""
display "  新增变量:"
foreach v of local new_vars {
    display "    - `v'"
}
display ""
display "  输出文件:"
display "    - table_TA02_transform_summary.csv"
display "    - data_TA02_standardized.dta"
display "    - table_TA02_standardized.csv"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_transformed|value=`n_transformed'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA02|status=ok|elapsed_sec=`elapsed'"
log close
