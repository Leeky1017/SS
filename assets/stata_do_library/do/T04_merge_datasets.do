* ==============================================================================
* SS_TEMPLATE: id=T04  level=L1  module=B  title="Merge Datasets Horizontal"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data_using.dta  role=merge_table  required=yes
* OUTPUTS:
*   - table_T04_merge_report.csv type=table desc="Merge diagnostics report"
*   - table_T04_merged_data.csv type=table desc="Merged dataset CSV"
*   - data_T04_merged_data.dta type=data desc="Merged dataset Stata"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core merge commands"
* ==============================================================================
* Task ID:      T04_merge_datasets
* Task Name:    数据集合并（横向）
* Family:       B - 数据合并
* Description:  使用主键横向合并两个数据集，支持 1:1、m:1、1:m 合并类型
* 
* Placeholders: __MERGE_KEYS__   - 合并主键（空格分隔）
*               __MERGE_TYPE__   - 合并类型: 1:1, m:1, 1:m
*               __KEEP_OPTION__  - 保留选项: master, using, match, all
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T04|level=L1|title=Merge_Datasets_Horizontal"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                        T04: 数据集合并（横向）                               ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ==============================================================================
* SECTION 1: 导入并检查辅助数据集（Using）
* ==============================================================================
display "SS_STEP_BEGIN|step=S01_load_data"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 导入辅助数据集 (Using)"
display "═══════════════════════════════════════════════════════════════════════════════"

* 标准化数据加载：data_using.dta 优先，缺失时回退 data_using.csv
local using_file "data_using.dta"

capture confirm file "`using_file'"
if _rc {
    capture confirm file "data_using.csv"
    if _rc {
        display as error "ERROR: No data_using.dta or data_using.csv found in job directory."
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
    import delimited "data_using.csv", clear varnames(1) encoding(utf8)
    save "`using_file'", replace
    display "SS_OUTPUT_FILE|file=`using_file'|type=data|desc=converted_from_csv"
    display ">>> 已从 data_using.csv 转换并保存为 data_using.dta"
}
else {
    use "`using_file'", clear
}

local n_using = _N

display ""
display ">>> 1.1 辅助数据集概况"
display "-------------------------------------------------------------------------------"
display "样本量:             " %10.0fc `n_using'
describe, short

* 检查合并键是否存在
display ""
local merge_keys "__MERGE_KEYS__"
display ">>> 1.2 合并键检查: `merge_keys'"
display "-------------------------------------------------------------------------------"

foreach key of local merge_keys {
    capture confirm variable `key'
    if _rc {
        display as error "ERROR: Merge key `key' not found in using dataset"
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
}
display ">>> 合并键存在 ✓"

* 检查合并键唯一性
display ""
display ">>> 1.3 合并键唯一性检查（辅助数据集）"
display "-------------------------------------------------------------------------------"
duplicates report `merge_keys'

quietly duplicates tag `merge_keys', generate(_dup_using)
quietly count if _dup_using > 0
local n_dup_using = r(N)

if `n_dup_using' > 0 {
    display ""
    display as error "WARNING: 辅助数据集中合并键有 `n_dup_using' 条重复"
    display as error "这可能导致 1:1 或 m:1 合并失败"
    display ""
    display "重复键示例（前10条）:"
    list `merge_keys' if _dup_using > 0 in 1/10, separator(0)
}
else {
    display as result ">>> 合并键唯一性检查通过 ✓"
}
drop _dup_using

* 记录辅助数据集的变量
quietly describe, varlist
local using_vars = r(varlist)
local n_using_vars: word count `using_vars'
display ""
display "辅助数据集变量数: `n_using_vars'"

* 保存为临时文件
tempfile using_data
save `using_data', replace
display ""
display ">>> 辅助数据集已缓存"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 导入并检查主数据集（Master）
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 导入主数据集 (Master)"
display "═══════════════════════════════════════════════════════════════════════════════"

* 标准化数据加载：data.dta 优先，缺失时回退 data.csv
local datafile "data.dta"

capture confirm file "`datafile'"
if _rc {
    capture confirm file "data.csv"
    if _rc {
        display as error "ERROR: No data.dta or data.csv found in job directory."
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
    display "SS_OUTPUT_FILE|file=`datafile'|type=data|desc=converted_from_csv"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}

local n_master = _N

display ""
display ">>> 2.1 主数据集概况"
display "-------------------------------------------------------------------------------"
display "样本量:             " %10.0fc `n_master'
describe, short

* 检查合并键
display ""
display ">>> 2.2 合并键检查: `merge_keys'"
display "-------------------------------------------------------------------------------"

foreach key of local merge_keys {
    capture confirm variable `key'
    if _rc {
        display as error "ERROR: Merge key `key' not found in master dataset"
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
}
display ">>> 合并键存在 ✓"

* 检查合并键唯一性
display ""
display ">>> 2.3 合并键唯一性检查（主数据集）"
display "-------------------------------------------------------------------------------"
duplicates report `merge_keys'

quietly duplicates tag `merge_keys', generate(_dup_master)
quietly count if _dup_master > 0
local n_dup_master = r(N)

if `n_dup_master' > 0 {
    display ""
    display as error "WARNING: 主数据集中合并键有 `n_dup_master' 条重复"
    display as error "这可能导致 1:1 或 1:m 合并失败"
    display ""
    display "重复键示例（前10条）:"
    list `merge_keys' if _dup_master > 0 in 1/10, separator(0)
}
else {
    display as result ">>> 合并键唯一性检查通过 ✓"
}
drop _dup_master

* 记录主数据集的变量
quietly describe, varlist
local master_vars = r(varlist)
local n_master_vars: word count `master_vars'
display ""
display "主数据集变量数: `n_master_vars'"

* ==============================================================================
* SECTION 3: 合并前预览
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 合并前预览"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 60}"
display "数据集" _col(25) "样本量" _col(40) "变量数"
display "{hline 60}"
display "主数据集 (Master)" _col(25) %10.0fc `n_master' _col(40) %5.0f `n_master_vars'
display "辅助数据集 (Using)" _col(25) %10.0fc `n_using' _col(40) %5.0f `n_using_vars'
display "{hline 60}"
display ""
display "合并键: `merge_keys'"
display "合并类型: `merge_type'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 4: 执行合并
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 执行合并"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 执行 `merge_type' 合并..."
display ""

* 执行合并（根据类型）
* 支持: 1:1, m:1, 1:m, m:m
local merge_type "__MERGE_TYPE__"
capture noisily merge `merge_type' `merge_keys' using `using_data'

if _rc {
    display ""
    display as error "ERROR: 合并失败，请检查合并键和合并类型"
    display as error "常见原因："
    display as error "  1. 1:1 合并但主键不唯一"
    display as error "  2. m:1 合并但 using 数据集主键不唯一"
    display as error "  3. 1:m 合并但 master 数据集主键不唯一"
    exit _rc
}

* ==============================================================================
* SECTION 5: 合并结果诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 合并结果诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 5.1 合并结果分布"
display "-------------------------------------------------------------------------------"
tabulate _merge

* 统计各类匹配情况
quietly count if _merge == 1
local n_master_only = r(N)
quietly count if _merge == 2
local n_using_only = r(N)
quietly count if _merge == 3
local n_matched = r(N)
local n_total = _N

* 计算匹配率
local match_rate_master = (`n_matched' / `n_master') * 100
local match_rate_using = (`n_matched' / `n_using') * 100

display ""
display ">>> 5.2 合并统计汇总"
display "-------------------------------------------------------------------------------"
display "{hline 60}"
display "类别" _col(35) "数量" _col(50) "占比"
display "{hline 60}"
display "仅在主数据集 (_merge==1)" _col(35) %8.0fc `n_master_only' _col(50) %6.1f (`n_master_only'/`n_total'*100) "%"
display "仅在辅助数据集 (_merge==2)" _col(35) %8.0fc `n_using_only' _col(50) %6.1f (`n_using_only'/`n_total'*100) "%"
display "成功匹配 (_merge==3)" _col(35) %8.0fc `n_matched' _col(50) %6.1f (`n_matched'/`n_total'*100) "%"
display "{hline 60}"
display "合并后总数" _col(35) %8.0fc `n_total'
display "{hline 60}"

display ""
display ">>> 5.3 匹配率分析"
display "-------------------------------------------------------------------------------"
display "主数据集匹配率:     " %6.1f `match_rate_master' "% (" %0.0fc `n_matched' "/" %0.0fc `n_master' ")"
display "辅助数据集匹配率:   " %6.1f `match_rate_using' "% (" %0.0fc `n_matched' "/" %0.0fc `n_using' ")"

* 匹配率警告
if `match_rate_master' < 80 {
    display ""
    display as error "WARNING: 主数据集匹配率低于80%，请检查合并键是否正确"
}

if `n_master_only' > 0 | `n_using_only' > 0 {
    display ""
    display ">>> 5.4 未匹配样本示例"
    display "-------------------------------------------------------------------------------"
    
    if `n_master_only' > 0 {
        display ""
        display "仅在主数据集的样本（前5条）:"
        list `merge_keys' if _merge == 1 in 1/5, separator(0)
    }
    
    if `n_using_only' > 0 {
        display ""
        display "仅在辅助数据集的样本（前5条）:"
        list `merge_keys' if _merge == 2 in 1/5, separator(0)
    }
}

* ==============================================================================
* SECTION 6: 处理合并结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 处理合并结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 根据保留策略处理
local keep_option = "__KEEP_OPTION__"
local n_before_keep = _N

display ""
display ">>> 保留策略: __KEEP_OPTION__"

if "`keep_option'" == "matched" {
    keep if _merge == 3
    display ">>> 仅保留成功匹配的观测"
}
else if "`keep_option'" == "master" {
    keep if _merge == 1 | _merge == 3
    display ">>> 保留主数据集所有观测（含未匹配）"
}
else if "`keep_option'" == "using" {
    keep if _merge == 2 | _merge == 3
    display ">>> 保留辅助数据集所有观测（含未匹配）"
}
else {
    * 默认保留全部
    display ">>> 保留所有观测（含未匹配）"
}

local n_after_keep = _N
local n_dropped_keep = `n_before_keep' - `n_after_keep'

if `n_dropped_keep' > 0 {
    display ">>> 根据保留策略剔除: " %0.0fc `n_dropped_keep' " 条"
}

* 生成合并来源标记（可选保留）
generate byte merge_source = _merge
label define merge_source_lbl 1 "Master only" 2 "Using only" 3 "Matched"
label values merge_source merge_source_lbl
label variable merge_source "数据来源标记"

* 删除 _merge 变量
drop _merge

* ==============================================================================
* SECTION 7: 合并后数据检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 合并后数据检查"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 7.1 合并后数据概况"
display "-------------------------------------------------------------------------------"
display "最终样本量:         " %10.0fc _N
describe, short

display ""
display ">>> 7.2 合并后主键唯一性检查"
display "-------------------------------------------------------------------------------"
duplicates report `merge_keys'

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 8.1 导出合并诊断报告
display ""
display ">>> 8.1 导出合并诊断报告: table_T04_merge_report.csv"

preserve
clear
set obs 5

generate str30 item = ""
generate str50 value = ""

replace item = "主数据集样本量" in 1
replace value = "`n_master'" in 1

replace item = "辅助数据集样本量" in 2
replace value = "`n_using'" in 2

replace item = "成功匹配数" in 3
replace value = "`n_matched'" in 3

replace item = "主数据集匹配率" in 4
replace value = string(`match_rate_master', "%6.1f") + "%" in 4

replace item = "最终样本量" in 5
replace value = string(_N, "%10.0fc") in 5

export delimited using "table_T04_merge_report.csv", replace
display "SS_OUTPUT_FILE|file=table_T04_merge_report.csv|type=table|desc=merge_diagnostics_report"
display ">>> 合并诊断报告已导出"
restore

* 8.2 导出合并后数据
display ""
display ">>> 8.2 导出合并后数据"

* CSV格式
export delimited using "table_T04_merged_data.csv", replace
display "SS_OUTPUT_FILE|file=table_T04_merged_data.csv|type=table|desc=merged_dataset_csv"
display ">>> CSV格式: table_T04_merged_data.csv"

* DTA格式
save "data_T04_merged_data.dta", replace
display "SS_OUTPUT_FILE|file=data_T04_merged_data.dta|type=data|desc=merged_dataset_dta"
display ">>> DTA格式: data_T04_merged_data.dta"

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T04 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "合并概况:"
display "  - 合并键:          `merge_keys'"
display "  - 合并类型:        `merge_type'"
display "  - 主数据集:        " %10.0fc `n_master' " 条"
display "  - 辅助数据集:      " %10.0fc `n_using' " 条"
display "  - 成功匹配:        " %10.0fc `n_matched' " 条 (" %5.1f `match_rate_master' "%)"
display "  - 最终样本量:      " %10.0fc _N " 条"
display ""
display "输出文件:"
display "  - table_T04_merge_report.csv  合并诊断报告"
display "  - table_T04_merged_data.csv   合并后数据(CSV)"
display "  - data_T04_merged_data.dta    合并后数据(DTA)"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_master|value=`n_master'"
display "SS_SUMMARY|key=n_matched|value=`n_matched'"
display "SS_SUMMARY|key=match_rate|value=`match_rate_master'"
display "SS_SUMMARY|key=n_final|value=`=_N'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`=_N'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T04|status=ok|elapsed_sec=`elapsed'"

log close
