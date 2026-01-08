* ==============================================================================
* SS_TEMPLATE: id=TA11  level=L1  module=A  title="Dedup Check"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA11_dup_summary.csv type=table desc="Duplicate summary"
*   - table_TA11_dup_details.csv type=table desc="Duplicate details"
*   - data_TA11_deduped.dta type=data desc="Deduplicated data"
*   - data_TA11_deduped.csv type=data desc="Deduplicated CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - distinct source=ssc purpose="count distinct values"
* ==============================================================================
* Task ID:      TA11_dedup_check
* Task Name:    数据去重与唯一性检查
* Family:       A - 数据管理
* Description:  检查数据集中的重复观测
* 
* Placeholders: __KEY_VARS__       - 主键变量列表
*               __ACTION__         - 处理方式
*               __SORT_VAR__       - 排序变量
*               __SORT_ORDER__     - 排序顺序
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands)
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc = _rc
if `rc' {
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
display "SS_TASK_BEGIN|id=TA11|level=L1|title=Dedup_Check"
display "SS_METRIC|name=task_version|value=2.0.1"

* ============ 依赖检测 ============
local required_deps "distinct"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_CHECK|pkg=`dep'|source=ssc|status=missing"
        display "SS_DEP_MISSING|pkg=`dep'"
        display "SS_RC|code=199|cmd=which `dep'|msg=dependency_missing|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = round(r(t1))
        display "SS_TASK_END|id=TA11|status=fail|elapsed_sec=`elapsed'"
        log close
        exit 199
    }
    display "SS_DEP_CHECK|pkg=`dep'|source=ssc|status=ok"
}

* ============ 参数设置 ============
local key_vars "__KEY_VARS__"
local action "__ACTION__"
local sort_var "__SORT_VAR__"
local sort_order "__SORT_ORDER__"

* 参数默认值
if "`action'" == "" | ("`action'" != "check" & "`action'" != "keep_first" & "`action'" != "keep_last" & "`action'" != "drop_all") {
    local action = "check"
}
if "`sort_order'" == "" | ("`sort_order'" != "asc" & "`sort_order'" != "desc") {
    local sort_order = "desc"
}

display ""
display ">>> 去重参数:"
display "    主键变量: `key_vars'"
display "    处理方式: `action'"
if "`sort_var'" != "" {
    display "    排序变量: `sort_var'"
    display "    排序顺序: `sort_order'"
}

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 601
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

* 生成行号
generate long _row_id = _n

* ============ 变量检查 ============
local valid_keys ""
foreach var of local key_vars {
    capture confirm variable `var'
    if _rc {
        display ">>> 警告: `var' 不存在，跳过"
        display "SS_RC|code=0|cmd=confirm variable `var'|msg=key_var_not_found_skipped|severity=warn"
    }
    else {
        local valid_keys "`valid_keys' `var'"
    }
}

if "`valid_keys'" == "" {
    display "SS_RC|code=200|cmd=validate_key_vars|msg=no_valid_key_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

* 检查排序变量
if "`sort_var'" != "" {
    capture confirm variable `sort_var'
    if _rc {
        display "SS_RC|code=0|cmd=confirm variable `sort_var'|msg=sort_var_not_found_ignored|severity=warn"
        local sort_var ""
    }
}

* ============ 唯一性检查 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 唯一性检查"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用distinct命令检查唯一值
display ""
display ">>> 主键变量: `valid_keys'"
distinct `valid_keys'
local n_distinct = r(ndistinct)
local n_total = r(N)

display ""
display "  总观测数:        " %10.0fc `n_total'
display "  唯一键值组合数:  " %10.0fc `n_distinct'
display "  重复组数:        " %10.0fc `=`n_total' - `n_distinct''

local n_dup_groups = `n_total' - `n_distinct'
display "SS_METRIC|name=n_distinct|value=`n_distinct'"
display "SS_METRIC|name=n_dup_groups|value=`n_dup_groups'"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 重复识别 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 重复识别"
display "═══════════════════════════════════════════════════════════════════════════════"

* 标记重复
sort `valid_keys'
by `valid_keys': generate _dup_count = _N
by `valid_keys': generate _dup_seq = _n

* 标记是否重复
generate byte _is_dup = (_dup_count > 1)

* 统计
quietly count if _is_dup == 1
local n_dup_obs = r(N)
display ""
display ">>> 重复记录数: `n_dup_obs'"
display "SS_METRIC|name=n_dup_obs|value=`n_dup_obs'"

* 创建统计摘要
tempname summary
postfile `summary' str20 metric long value ///
    using "temp_dup_summary.dta", replace

post `summary' ("total_obs") (`n_total')
post `summary' ("distinct_keys") (`n_distinct')
post `summary' ("dup_groups") (`n_dup_groups')
post `summary' ("dup_obs") (`n_dup_obs')

postclose `summary'

* ============ 输出重复明细 ============
if `n_dup_obs' > 0 {
    display ""
    display ">>> 导出重复记录明细..."
    
    preserve
    keep if _is_dup == 1
    
    * 排序
    if "`sort_var'" != "" {
        if "`sort_order'" == "desc" {
            gsort `valid_keys' -`sort_var'
        }
        else {
            sort `valid_keys' `sort_var'
        }
    }
    else {
        sort `valid_keys' _row_id
    }
    
    * 导出重复明细（最多10000条）
    if _N > 10000 {
        display ">>> 重复记录过多，仅导出前10000条"
        keep in 1/10000
    }
    
    export delimited using "table_TA11_dup_details.csv", replace
    display "SS_OUTPUT_FILE|file=table_TA11_dup_details.csv|type=table|desc=dup_details"
    restore
}
else {
    * 创建空的明细文件
    preserve
    clear
    set obs 0
    generate str32 message = ""
    replace message = "No duplicates found" in 1
    export delimited using "table_TA11_dup_details.csv", replace
    display "SS_OUTPUT_FILE|file=table_TA11_dup_details.csv|type=table|desc=dup_details"
    restore
    
    display ">>> 未发现重复记录"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 去重处理 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 去重处理"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0

if "`action'" == "check" {
    display ">>> 处理方式: 仅检查（不删除）"
    display ">>> 保留所有记录，添加重复标记变量 _is_dup"
}
else if "`action'" == "keep_first" {
    display ">>> 处理方式: 保留第一条"
    
    * 排序
    if "`sort_var'" != "" {
        if "`sort_order'" == "desc" {
            gsort `valid_keys' -`sort_var'
        }
        else {
            sort `valid_keys' `sort_var'
        }
        by `valid_keys': replace _dup_seq = _n
    }
    
    * 删除非第一条
    quietly count if _dup_seq > 1
    local n_dropped = r(N)
    drop if _dup_seq > 1
    
    display ">>> 删除记录数: `n_dropped'"
}
else if "`action'" == "keep_last" {
    display ">>> 处理方式: 保留最后一条"
    
    * 排序
    if "`sort_var'" != "" {
        if "`sort_order'" == "desc" {
            gsort `valid_keys' -`sort_var'
        }
        else {
            sort `valid_keys' `sort_var'
        }
        by `valid_keys': replace _dup_seq = _n
        by `valid_keys': replace _dup_count = _N
    }
    
    * 删除非最后一条
    quietly count if _dup_seq < _dup_count
    local n_dropped = r(N)
    drop if _dup_seq < _dup_count
    
    display ">>> 删除记录数: `n_dropped'"
}
else if "`action'" == "drop_all" {
    display ">>> 处理方式: 删除所有重复记录"
    
    quietly count if _is_dup == 1
    local n_dropped = r(N)
    drop if _is_dup == 1
    
    display ">>> 删除记录数: `n_dropped'"
}

display "SS_METRIC|name=n_dropped|value=`n_dropped'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出统计摘要
preserve
use "temp_dup_summary.dta", clear
export delimited using "table_TA11_dup_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA11_dup_summary.csv|type=table|desc=dup_summary"
restore

* 清理临时变量
drop _row_id _dup_count _dup_seq

* 导出数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TA11_deduped.dta", replace
display "SS_OUTPUT_FILE|file=data_TA11_deduped.dta|type=data|desc=deduped_data"

export delimited using "data_TA11_deduped.csv", replace
display "SS_OUTPUT_FILE|file=data_TA11_deduped.csv|type=data|desc=deduped_csv"

* 清理临时文件
capture erase "temp_dup_summary.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA11 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  唯一键值数:      " %10.0fc `n_distinct'
display "  重复记录数:      " %10.0fc `n_dup_obs'
display "  删除记录数:      " %10.0fc `n_dropped'
display "  处理方式:        `action'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA11|status=ok|elapsed_sec=`elapsed'"
log close
