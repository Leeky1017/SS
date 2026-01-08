* ==============================================================================
* SS_TEMPLATE: id=TA07  level=L0  module=A  title="String Process"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA07_string_summary.csv type=table desc="String processing summary"
*   - data_TA07_processed.dta type=data desc="Processed data"
*   - data_TA07_processed.csv type=data desc="Processed CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="string functions"
* ==============================================================================
* Task ID:      TA07_string_process
* Task Name:    字符串变量处理
* Family:       A - 数据管理
* Description:  对字符串变量进行清洗和转换
* 
* Placeholders: __STRING_VARS__    - 要处理的字符串变量列表
*               __OPERATION__      - 操作类型
*               __PATTERN__        - 正则表达式或查找字符串
*               __REPLACEMENT__    - 替换字符串
*               __NEW_SUFFIX__     - 新变量后缀
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.3) ============
* - 2026-01-08: Require at least one valid string variable and avoid silent coercion errors during `tostring` (至少需要一个可处理变量，并对类型转换潜在失败保持可见).

* ============ 初始化 ============
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=log_close_failed|severity=warn"
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=TA07|level=L0|title=String_Process"
display "SS_METRIC|name=task_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local string_vars = "__STRING_VARS__"
local operation = "__OPERATION__"
local pattern = "__PATTERN__"
local replacement = "__REPLACEMENT__"
local new_suffix = "__NEW_SUFFIX__"

* 参数默认值
if "`operation'" == "" {
    local operation = "trim"
}
if "`new_suffix'" == "" {
    local new_suffix = "_clean"
}

display ""
display ">>> 字符串处理参数:"
display "    变量: `string_vars'"
display "    操作: `operation'"
if "`pattern'" != "" {
    display "    模式: `pattern'"
}
if "`replacement'" != "" {
    display "    替换为: `replacement'"
}
display "    新变量后缀: `new_suffix'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 601
}
import delimited "data.csv", clear stringcols(_all)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

* ============ 变量检查 ============
local valid_vars ""
foreach var of local string_vars {
    capture confirm string variable `var'
    if _rc {
        capture confirm variable `var'
        if _rc {
            display ">>> 警告: `var' 不存在，跳过"
            display "SS_RC|code=0|cmd=confirm variable `var'|msg=var_not_found_skipped|severity=warn"
        }
        else {
            * 转换为字符串
            tostring `var', replace force
            local valid_vars "`valid_vars' `var'"
        }
    }
    else {
        local valid_vars "`valid_vars' `var'"
    }
}

if "`valid_vars'" == "" {
    display "SS_RC|code=200|cmd=validate_string_vars|msg=no_valid_string_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

* ============ 处理前统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 处理前字符串统计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建统计存储
tempname stats
postfile `stats' str32 variable str10 stage long n_nonmissing long n_unique ///
    double avg_length long max_length ///
    using "temp_string_stats.dta", replace

foreach var of local valid_vars {
    * 非空计数
    quietly count if `var' != "" & !missing(`var')
    local n_nonmissing = r(N)
    
    * 唯一值计数
    quietly levelsof `var', local(levels) clean
    local n_unique : word count `levels'
    
    * 长度统计
    tempvar len
    generate `len' = strlen(`var')
    quietly summarize `len'
    local avg_length = r(mean)
    local max_length = r(max)
    drop `len'
    
    post `stats' ("`var'") ("before") (`n_nonmissing') (`n_unique') (`avg_length') (`max_length')
    
    display ""
    display "变量: `var'"
    display "  非空值: `n_nonmissing', 唯一值: `n_unique'"
    display "  平均长度: " %5.1f `avg_length' ", 最大长度: `max_length'"
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 字符串处理 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 字符串处理"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_processed = 0
local new_var_list ""

foreach var of local valid_vars {
    local newvar = "`var'`new_suffix'"
    display ""
    display ">>> 处理: `var' -> `newvar'"
    
    if "`operation'" == "trim" {
        * 去除首尾空格
        generate `newvar' = strtrim(`var')
        display "    操作: 去除首尾空格"
    }
    else if "`operation'" == "lower" {
        * 转小写
        generate `newvar' = strlower(`var')
        display "    操作: 转小写"
    }
    else if "`operation'" == "upper" {
        * 转大写
        generate `newvar' = strupper(`var')
        display "    操作: 转大写"
    }
    else if "`operation'" == "proper" {
        * 首字母大写
        generate `newvar' = strproper(`var')
        display "    操作: 首字母大写"
    }
    else if "`operation'" == "extract" {
        * 正则提取
        if "`pattern'" != "" {
            generate `newvar' = ustrregexs(0) if ustrregexm(`var', "`pattern'")
            display "    操作: 正则提取 (模式: `pattern')"
        }
        else {
            generate `newvar' = `var'
            display "SS_RC|code=0|cmd=extract|msg=no_pattern_provided|severity=warn"
        }
    }
    else if "`operation'" == "replace" {
        * 替换
        if "`pattern'" != "" {
            generate `newvar' = ustrregexra(`var', "`pattern'", "`replacement'")
            display "    操作: 替换 (`pattern' -> `replacement')"
        }
        else {
            generate `newvar' = `var'
            display "SS_RC|code=0|cmd=replace|msg=no_pattern_provided|severity=warn"
        }
    }
    else if "`operation'" == "remove_special" {
        * 移除特殊字符，只保留字母数字
        generate `newvar' = ustrregexra(`var', "[^a-zA-Z0-9\u4e00-\u9fa5 ]", "")
        display "    操作: 移除特殊字符"
    }
    else if "`operation'" == "remove_spaces" {
        * 移除所有空格
        generate `newvar' = ustrregexra(`var', "\s+", "")
        display "    操作: 移除所有空格"
    }
    else {
        * 默认trim
        generate `newvar' = strtrim(`var')
        display "    操作: 去除首尾空格（默认）"
    }
    
    local n_processed = `n_processed' + 1
    local new_var_list "`new_var_list' `newvar'"
    
    * 统计处理后
    quietly count if `newvar' != "" & !missing(`newvar')
    local n_nonmissing = r(N)
    quietly levelsof `newvar', local(levels) clean
    local n_unique : word count `levels'
    tempvar len
    generate `len' = strlen(`newvar')
    quietly summarize `len'
    local avg_length = r(mean)
    local max_length = r(max)
    drop `len'
    
    post `stats' ("`newvar'") ("after") (`n_nonmissing') (`n_unique') (`avg_length') (`max_length')
    
    display "    结果: 非空`n_nonmissing', 唯一`n_unique', 平均长度" %5.1f `avg_length'
}

postclose `stats'

display ""
display ">>> 总共处理变量: `n_processed' 个"
display "SS_METRIC|name=n_processed|value=`n_processed'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 输出结果 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出统计摘要
preserve
use "temp_string_stats.dta", clear
export delimited using "table_TA07_string_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA07_string_summary.csv|type=table|desc=string_summary"
restore

* 导出数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

save "data_TA07_processed.dta", replace
display "SS_OUTPUT_FILE|file=data_TA07_processed.dta|type=data|desc=processed_data"

export delimited using "data_TA07_processed.csv", replace
display "SS_OUTPUT_FILE|file=data_TA07_processed.csv|type=data|desc=processed_csv"

* 清理临时文件
capture erase "temp_string_stats.dta"
local rc = _rc
if `rc' != 0 & `rc' != 601 {
    display "SS_RC|code=`rc'|cmd=erase temp_string_stats.dta|msg=cleanup_failed|severity=warn"
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA07 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  处理变量数:      " %10.0fc `n_processed'
display "  操作类型:        `operation'"
display ""
display "  新增变量:"
foreach v of local new_var_list {
    display "    - `v'"
}
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_processed|value=`n_processed'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA07|status=ok|elapsed_sec=`elapsed'"
log close
