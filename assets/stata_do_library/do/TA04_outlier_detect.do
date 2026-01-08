* ==============================================================================
* SS_TEMPLATE: id=TA04  level=L0  module=A  title="Outlier Detect"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA04_outlier_summary.csv type=table desc="Outlier summary"
*   - table_TA04_outlier_details.csv type=table desc="Outlier details"
*   - data_TA04_cleaned.dta type=data desc="Cleaned data"
*   - data_TA04_cleaned.csv type=data desc="Cleaned CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="analysis commands"
* ==============================================================================
* Task ID:      TA04_outlier_detect
* Task Name:    异常值检测与处理
* Family:       A - 数据管理
* Description:  检测数值变量中的异常值
* 
* Placeholders: __CHECK_VARS__     - 需要检测的变量列表
*               __METHOD__         - 检测方法：iqr/zscore/mad
*               __THRESHOLD__      - 阈值
*               __ACTION__         - 处理方式：flag/drop/replace
*               __ID_VAR__         - 个体标识变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

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
display "SS_TASK_BEGIN|id=TA04|level=L0|title=Outlier_Detect"
display "SS_METRIC|name=task_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local check_vars = "__CHECK_VARS__"
local method = "__METHOD__"
local threshold = __THRESHOLD__
local action = "__ACTION__"
local id_var = "__ID_VAR__"

* 参数默认值处理
if "`method'" == "" | ("`method'" != "iqr" & "`method'" != "zscore" & "`method'" != "mad") {
    local method = "iqr"
}
if `threshold' <= 0 {
    if "`method'" == "iqr" {
        local threshold = 1.5
    }
    else if "`method'" == "zscore" {
        local threshold = 3
    }
    else {
        local threshold = 3
    }
}
if "`action'" == "" | ("`action'" != "flag" & "`action'" != "drop" & "`action'" != "replace") {
    local action = "flag"
}

display ""
display ">>> 异常值检测参数:"
display "    检测变量: `check_vars'"
display "    检测方法: `method'"
display "    阈值: `threshold'"
display "    处理方式: `action'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

* 生成行号用于追踪
generate long _row_id = _n

* ============ 变量检查 ============
local valid_vars ""

foreach var of local check_vars {
    capture confirm numeric variable `var'
    if _rc {
        display ">>> 警告: `var' 不存在或非数值，跳过"
        display "SS_RC|code=0|cmd=confirm numeric variable `var'|msg=check_var_invalid_skipped|severity=warn"
    }
    else {
        local valid_vars "`valid_vars' `var'"
    }
}

if "`valid_vars'" == "" {
    display "SS_RC|code=200|cmd=validate_check_vars|msg=no_valid_numeric_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

* 检查ID变量
if "`id_var'" != "" {
    capture confirm variable `id_var'
    if _rc {
        display "SS_RC|code=0|cmd=confirm variable `id_var'|msg=id_var_not_found_using_row_id|severity=warn"
        local id_var "_row_id"
    }
}
else {
    local id_var "_row_id"
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 异常值检测 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 异常值检测"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建统计结果存储
tempname summary
postfile `summary' str32 variable long n_total long n_outliers double pct_outliers ///
    double lower_bound double upper_bound str10 method double threshold ///
    using "temp_outlier_summary.dta", replace

* 创建异常值明细存储
tempname details
postfile `details' str32 id str32 variable double value str10 direction ///
    using "temp_outlier_details.dta", replace

* 创建综合异常标记
generate byte _any_outlier = 0

local total_outliers = 0

foreach var of local valid_vars {
    display ""
    display ">>> 检测变量: `var'"
    
    * 生成该变量的异常标记
    generate byte _outlier_`var' = 0
    
    quietly summarize `var', detail
    local n_valid = r(N)
    local mean_val = r(mean)
    local sd_val = r(sd)
    local p25 = r(p25)
    local p50 = r(p50)
    local p75 = r(p75)
    
    * 根据方法计算边界
    if "`method'" == "iqr" {
        local iqr = `p75' - `p25'
        local lower_bound = `p25' - `threshold' * `iqr'
        local upper_bound = `p75' + `threshold' * `iqr'
        display "  IQR方法: IQR = " %9.4f `iqr'
    }
    else if "`method'" == "zscore" {
        local lower_bound = `mean_val' - `threshold' * `sd_val'
        local upper_bound = `mean_val' + `threshold' * `sd_val'
        display "  Z-score方法: Mean = " %9.4f `mean_val' ", SD = " %9.4f `sd_val'
    }
    else if "`method'" == "mad" {
        * MAD (Median Absolute Deviation)
        tempvar abs_dev
        generate double `abs_dev' = abs(`var' - `p50')
        quietly summarize `abs_dev', detail
        local mad = r(p50)
        local lower_bound = `p50' - `threshold' * 1.4826 * `mad'
        local upper_bound = `p50' + `threshold' * 1.4826 * `mad'
        drop `abs_dev'
        display "  MAD方法: Median = " %9.4f `p50' ", MAD = " %9.4f `mad'
    }
    
    display "  下界: " %12.4f `lower_bound'
    display "  上界: " %12.4f `upper_bound'
    
    * 标记异常值
    replace _outlier_`var' = 1 if `var' < `lower_bound' & !missing(`var')
    replace _outlier_`var' = 1 if `var' > `upper_bound' & !missing(`var')
    replace _any_outlier = 1 if _outlier_`var' == 1
    
    * 统计异常值
    quietly count if _outlier_`var' == 1
    local n_outliers = r(N)
    local pct_outliers = (`n_outliers' / `n_valid') * 100
    
    display "  异常值数量: `n_outliers' (" %5.2f `pct_outliers' "%)"
    
    local total_outliers = `total_outliers' + `n_outliers'
    
    * 记录统计结果
    post `summary' ("`var'") (`n_valid') (`n_outliers') (`pct_outliers') ///
        (`lower_bound') (`upper_bound') ("`method'") (`threshold')
    
    * 记录异常值明细
    quietly count if _outlier_`var' == 1
    if r(N) > 0 {
        preserve
        keep if _outlier_`var' == 1
        local n_detail = _N
        forvalues i = 1/`n_detail' {
            local id_val = `id_var'[`i']
            local val = `var'[`i']
            if `val' < `lower_bound' {
                post `details' ("`id_val'") ("`var'") (`val') ("low")
            }
            else {
                post `details' ("`id_val'") ("`var'") (`val') ("high")
            }
        }
        restore
    }
}

postclose `summary'
postclose `details'

display ""
display ">>> 总异常值数量: `total_outliers'"
display "SS_METRIC|name=n_outliers|value=`total_outliers'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 处理异常值 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 异常值处理"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
local n_replaced = 0

if "`action'" == "flag" {
    display ">>> 处理方式: 仅标记（保留数据）"
    display ">>> 已生成变量: _outlier_* 和 _any_outlier"
}
else if "`action'" == "drop" {
    quietly count if _any_outlier == 1
    local n_dropped = r(N)
    drop if _any_outlier == 1
    display ">>> 处理方式: 删除异常观测"
    display ">>> 删除观测数: `n_dropped'"
}
else if "`action'" == "replace" {
    display ">>> 处理方式: 替换为边界值"
    foreach var of local valid_vars {
        * 重新计算边界
        quietly summarize `var', detail
        local p25 = r(p25)
        local p75 = r(p75)
        local mean_val = r(mean)
        local sd_val = r(sd)
        local p50 = r(p50)
        
        if "`method'" == "iqr" {
            local iqr = `p75' - `p25'
            local lower_bound = `p25' - `threshold' * `iqr'
            local upper_bound = `p75' + `threshold' * `iqr'
        }
        else if "`method'" == "zscore" {
            local lower_bound = `mean_val' - `threshold' * `sd_val'
            local upper_bound = `mean_val' + `threshold' * `sd_val'
        }
        else {
            tempvar abs_dev
            generate double `abs_dev' = abs(`var' - `p50')
            quietly summarize `abs_dev', detail
            local mad = r(p50)
            local lower_bound = `p50' - `threshold' * 1.4826 * `mad'
            local upper_bound = `p50' + `threshold' * 1.4826 * `mad'
            drop `abs_dev'
        }
        
        quietly count if `var' < `lower_bound' & !missing(`var')
        local n_low = r(N)
        quietly count if `var' > `upper_bound' & !missing(`var')
        local n_high = r(N)
        
        replace `var' = `lower_bound' if `var' < `lower_bound' & !missing(`var')
        replace `var' = `upper_bound' if `var' > `upper_bound' & !missing(`var')
        
        local n_replaced = `n_replaced' + `n_low' + `n_high'
        display "  `var': 替换 `n_low' 个低值, `n_high' 个高值"
    }
    display ">>> 总替换数: `n_replaced'"
}

display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出统计摘要
preserve
use "temp_outlier_summary.dta", clear
export delimited using "table_TA04_outlier_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA04_outlier_summary.csv|type=table|desc=outlier_summary"
restore

* 导出异常值明细
preserve
use "temp_outlier_details.dta", clear
export delimited using "table_TA04_outlier_details.csv", replace
display "SS_OUTPUT_FILE|file=table_TA04_outlier_details.csv|type=table|desc=outlier_details"
restore

* 导出处理后数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

drop _row_id
save "data_TA04_cleaned.dta", replace
display "SS_OUTPUT_FILE|file=data_TA04_cleaned.dta|type=data|desc=cleaned_data"

export delimited using "data_TA04_cleaned.csv", replace
display "SS_OUTPUT_FILE|file=data_TA04_cleaned.csv|type=data|desc=cleaned_csv"

* 清理临时文件
capture erase "temp_outlier_summary.dta"
local rc = _rc
if `rc' != 0 & `rc' != 601 {
    display "SS_RC|code=`rc'|cmd=erase temp_outlier_summary.dta|msg=cleanup_failed|severity=warn"
}
capture erase "temp_outlier_details.dta"
local rc = _rc
if `rc' != 0 & `rc' != 601 {
    display "SS_RC|code=`rc'|cmd=erase temp_outlier_details.dta|msg=cleanup_failed|severity=warn"
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  检测变量数:      " %10.0fc `: word count `valid_vars''
display "  总异常值数:      " %10.0fc `total_outliers'
display "  检测方法:        `method'"
display "  阈值:            `threshold'"
display "  处理方式:        `action'"
if "`action'" == "drop" {
    display "  删除观测数:      " %10.0fc `n_dropped'
}
if "`action'" == "replace" {
    display "  替换值数:        " %10.0fc `n_replaced'
}
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=total_outliers|value=`total_outliers'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA04|status=ok|elapsed_sec=`elapsed'"
log close
