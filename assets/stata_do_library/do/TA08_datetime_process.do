* ==============================================================================
* SS_TEMPLATE: id=TA08  level=L0  module=A  title="Datetime Process"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA08_datetime_summary.csv type=table desc="Datetime summary"
*   - data_TA08_processed.dta type=data desc="Processed data"
*   - data_TA08_processed.csv type=data desc="Processed CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="date functions"
* ==============================================================================
* Task ID:      TA08_datetime_process
* Task Name:    日期时间变量处理
* Family:       A - 数据管理
* Description:  解析和转换日期时间变量
* 
* Placeholders: __DATE_VARS__      - 日期变量列表
*               __INPUT_FORMAT__   - 输入格式
*               __OPERATIONS__     - 操作类型
*               __REFERENCE_DATE__ - 参考日期
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
display "SS_TASK_BEGIN|id=TA08|level=L0|title=Datetime_Process"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local date_vars = "__DATE_VARS__"
local input_format = "__INPUT_FORMAT__"
local operations = "__OPERATIONS__"
local reference_date = "__REFERENCE_DATE__"

* 参数默认值
if "`input_format'" == "" {
    local input_format = "YMD"
}
if "`operations'" == "" {
    local operations = "extract"
}

display ""
display ">>> 日期处理参数:"
display "    日期变量: `date_vars'"
display "    输入格式: `input_format'"
display "    操作: `operations'"
if "`reference_date'" != "" {
    display "    参考日期: `reference_date'"
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
foreach var of local date_vars {
    capture confirm variable `var'
    if _rc {
        display ">>> 警告: `var' 不存在，跳过"
        display "SS_WARNING:VAR_NOT_FOUND:`var'"
    }
    else {
        local valid_vars "`valid_vars' `var'"
    }
}

if "`valid_vars'" == "" {
    display "SS_ERROR:NO_VALID_VARS:No valid date variables"
    display "SS_ERR:NO_VALID_VARS:No valid date variables"
    log close
    exit 200
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 日期解析 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 日期变量解析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建统计存储
tempname stats
postfile `stats' str32 variable str20 type long n_valid long n_missing ///
    double min_date double max_date ///
    using "temp_datetime_stats.dta", replace

local n_converted = 0
local new_var_list ""

foreach var of local valid_vars {
    display ""
    display ">>> 处理变量: `var'"
    
    * 检查是否已是Stata日期格式
    capture confirm numeric variable `var'
    if !_rc {
        * 已经是数值型，检查是否是日期
        local fmt : format `var'
        if strpos("`fmt'", "%t") > 0 | strpos("`fmt'", "%d") > 0 {
            display "    已是Stata日期格式"
            local `var'_stata = "`var'"
        }
        else {
            * 数值但非日期格式，尝试解析
            local `var'_stata = "`var'_date"
            generate double ``var'_stata' = `var'
            format ``var'_stata' %td
            display "    转换为日期格式"
        }
    }
    else {
        * 字符串型，需要解析
        local `var'_stata = "`var'_date"
        
        if "`input_format'" == "YMD" {
            generate double ``var'_stata' = date(`var', "YMD")
        }
        else if "`input_format'" == "DMY" {
            generate double ``var'_stata' = date(`var', "DMY")
        }
        else if "`input_format'" == "MDY" {
            generate double ``var'_stata' = date(`var', "MDY")
        }
        else if "`input_format'" == "YM" {
            generate double ``var'_stata' = monthly(`var', "YM")
            format ``var'_stata' %tm
        }
        else {
            * 尝试多种格式
            generate double ``var'_stata' = date(`var', "YMD")
            replace ``var'_stata' = date(`var', "DMY") if missing(``var'_stata')
            replace ``var'_stata' = date(`var', "MDY") if missing(``var'_stata')
        }
        
        format ``var'_stata' %td
        display "    从字符串解析为日期"
    }
    
    * 统计
    quietly count if !missing(``var'_stata')
    local n_valid = r(N)
    quietly count if missing(``var'_stata')
    local n_missing = r(N)
    quietly summarize ``var'_stata'
    local min_date = r(min)
    local max_date = r(max)
    
    post `stats' ("`var'") ("date") (`n_valid') (`n_missing') (`min_date') (`max_date')
    
    display "    有效: `n_valid', 缺失: `n_missing'"
    display "    范围: " %td `min_date' " - " %td `max_date'
    
    local n_converted = `n_converted' + 1
    if "``var'_stata'" != "`var'" {
        local new_var_list "`new_var_list' ``var'_stata'"
    }
}

* ============ 执行日期操作 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 执行日期操作"
display "═══════════════════════════════════════════════════════════════════════════════"

* 解析操作列表
local operations = subinstr("`operations'", ",", " ", .)
local n_newvars = 0

foreach var of local valid_vars {
    local datevar = "``var'_stata'"
    if "`datevar'" == "" {
        local datevar = "`var'"
    }
    
    foreach op of local operations {
        display ""
        display ">>> `var': 执行操作 `op'"
        
        if "`op'" == "extract" {
            * 提取年/月/日/季度/星期
            
            * 年
            capture drop `var'_year
            if _rc != 0 { }
            generate int `var'_year = year(`datevar')
            local new_var_list "`new_var_list' `var'_year"
            local n_newvars = `n_newvars' + 1
            display "    生成: `var'_year"
            
            * 月
            capture drop `var'_month
            if _rc != 0 { }
            generate byte `var'_month = month(`datevar')
            local new_var_list "`new_var_list' `var'_month"
            local n_newvars = `n_newvars' + 1
            display "    生成: `var'_month"
            
            * 日
            capture drop `var'_day
            if _rc != 0 { }
            generate byte `var'_day = day(`datevar')
            local new_var_list "`new_var_list' `var'_day"
            local n_newvars = `n_newvars' + 1
            display "    生成: `var'_day"
            
            * 季度
            capture drop `var'_quarter
            if _rc != 0 { }
            generate byte `var'_quarter = quarter(`datevar')
            local new_var_list "`new_var_list' `var'_quarter"
            local n_newvars = `n_newvars' + 1
            display "    生成: `var'_quarter"
            
            * 星期
            capture drop `var'_dow
            if _rc != 0 { }
            generate byte `var'_dow = dow(`datevar')
            label define dow_lbl 0 "Sun" 1 "Mon" 2 "Tue" 3 "Wed" 4 "Thu" 5 "Fri" 6 "Sat", replace
            label values `var'_dow dow_lbl
            local new_var_list "`new_var_list' `var'_dow"
            local n_newvars = `n_newvars' + 1
            display "    生成: `var'_dow"
        }
        else if "`op'" == "diff" {
            * 计算与参考日期的差值
            if "`reference_date'" != "" {
                local ref_stata = date("`reference_date'", "YMD")
                capture drop `var'_diff
                if _rc != 0 { }
                generate long `var'_diff = `datevar' - `ref_stata'
                local new_var_list "`new_var_list' `var'_diff"
                local n_newvars = `n_newvars' + 1
                display "    生成: `var'_diff (距`reference_date'的天数)"
            }
            else {
                display "SS_WARNING:NO_REF_DATE:No reference date for diff operation"
            }
        }
        else if "`op'" == "dummy" {
            * 生成年份哑变量
            quietly levelsof `var'_year if !missing(`var'_year), local(years)
            local base_year : word 1 of `years'
            
            foreach y of local years {
                if `y' != `base_year' {
                    capture drop `var'_y`y'
                    if _rc != 0 { }
                    generate byte `var'_y`y' = (`var'_year == `y') if !missing(`var'_year)
                    local new_var_list "`new_var_list' `var'_y`y'"
                    local n_newvars = `n_newvars' + 1
                }
            }
            display "    生成年份哑变量 (基准年: `base_year')"
            
            * 生成季度哑变量
            forvalues q = 2/4 {
                capture drop `var'_q`q'
                if _rc != 0 { }
                generate byte `var'_q`q' = (`var'_quarter == `q') if !missing(`var'_quarter)
                local new_var_list "`new_var_list' `var'_q`q'"
                local n_newvars = `n_newvars' + 1
            }
            display "    生成季度哑变量 (基准: Q1)"
        }
    }
}

postclose `stats'

display ""
display ">>> 新增变量数: `n_newvars'"
display "SS_METRIC|name=n_newvars|value=`n_newvars'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 输出结果 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出统计摘要
preserve
use "temp_datetime_stats.dta", clear
format min_date max_date %td
export delimited using "table_TA08_datetime_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA08_datetime_summary.csv|type=table|desc=datetime_summary"
restore

* 导出数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

save "data_TA08_processed.dta", replace
display "SS_OUTPUT_FILE|file=data_TA08_processed.dta|type=data|desc=processed_data"

export delimited using "data_TA08_processed.csv", replace
display "SS_OUTPUT_FILE|file=data_TA08_processed.csv|type=data|desc=processed_csv"

* 清理临时文件
capture erase "temp_datetime_stats.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA08 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  处理日期变量:    " %10.0fc `n_converted'
display "  新增变量数:      " %10.0fc `n_newvars'
display "  输入格式:        `input_format'"
display "  执行操作:        `operations'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_newvars|value=`n_newvars'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA08|status=ok|elapsed_sec=`elapsed'"
log close
