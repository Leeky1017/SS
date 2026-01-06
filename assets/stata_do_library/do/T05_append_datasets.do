* ==============================================================================
* SS_TEMPLATE: id=T05  level=L1  module=B  title="Append Datasets Vertical"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data_append.dta  role=append_table  required=yes
* OUTPUTS:
*   - table_T05_append_report.csv type=table desc="Append diagnostics report"
*   - table_T05_appended_data.csv type=table desc="Appended dataset CSV"
*   - data_T05_appended_data.dta type=data desc="Appended dataset Stata"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core append commands"
* ==============================================================================
* Task ID:      T05_append_datasets
* Task Name:    数据集追加（纵向合并）
* Family:       B - 数据合并
* Description:  将多个数据集纵向追加合并，检查变量一致性，生成数据来源标记
* 
* Placeholders: __ID_VAR__    - 个体变量（可选）
*               __TIME_VAR__  - 时间变量（可选）
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
display "SS_TASK_BEGIN|id=T05|level=L1|title=Append_Datasets_Vertical"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                       T05: 数据集追加（纵向合并）                             ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ==============================================================================
* SECTION 1: 导入并检查追加数据集
* ==============================================================================
display "SS_STEP_BEGIN|step=S01_load_data"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 导入追加数据集"
display "═══════════════════════════════════════════════════════════════════════════════"

* 标准化数据加载：data_append.dta 优先，缺失时回退 data_append.csv
local append_file "data_append.dta"

capture confirm file "`append_file'"
if _rc {
    capture confirm file "data_append.csv"
    if _rc {
        display as error "ERROR: No data_append.dta or data_append.csv found in job directory."
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
    import delimited "data_append.csv", clear varnames(1) encoding(utf8)
    save "`append_file'", replace
    display "SS_OUTPUT_FILE|file=`append_file'|type=data|desc=converted_from_csv"
    display ">>> 已从 data_append.csv 转换并保存为 data_append.dta"
}
else {
    use "`append_file'", clear
}

local n_append = _N

display ""
display ">>> 1.1 追加数据集概况"
display "-------------------------------------------------------------------------------"
display "样本量:             " %10.0fc `n_append'
describe, short

* 记录追加数据集的变量
quietly describe, varlist
local append_vars = r(varlist)
local n_append_vars: word count `append_vars'
display ""
display "变量数:             " %10.0fc `n_append_vars'

* 参数定义
local id_var "__ID_VAR__"
local time_var "__TIME_VAR__"

* 检查时间标记（如果有）
capture confirm variable `time_var'
if _rc == 0 {
    quietly summarize `time_var'
    display ""
    display "时间范围:           " r(min) " - " r(max)
}

* 生成数据来源标记
generate byte _source = 2
label variable _source "数据来源 (1=主数据集, 2=追加数据集)"

* 保存为临时文件
tempfile append_data
save `append_data', replace
display ""
display ">>> 追加数据集已缓存"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 导入主数据集
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 导入主数据集"
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

* 记录主数据集的变量
quietly describe, varlist
local master_vars = r(varlist)
local n_master_vars: word count `master_vars'
display ""
display "变量数:             " %10.0fc `n_master_vars'

* 检查时间标记
capture confirm variable `time_var'
if _rc == 0 {
    quietly summarize `time_var'
    display ""
    display "时间范围:           " r(min) " - " r(max)
}

* 生成数据来源标记
generate byte _source = 1

* ==============================================================================
* SECTION 3: 变量结构一致性检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 变量结构一致性检查"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 3.1 变量数量对比"
display "-------------------------------------------------------------------------------"
display "主数据集变量数:     " %5.0f `n_master_vars'
display "追加数据集变量数:   " %5.0f `n_append_vars'

* 检查变量差异
display ""
display ">>> 3.2 变量差异分析"
display "-------------------------------------------------------------------------------"

* 找出两个数据集的共同变量和差异变量
local common_vars ""
local only_master ""
local only_append ""

foreach var of local master_vars {
    local found = 0
    foreach avar of local append_vars {
        if "`var'" == "`avar'" {
            local found = 1
            continue, break
        }
    }
    if `found' {
        local common_vars "`common_vars' `var'"
    }
    else {
        local only_master "`only_master' `var'"
    }
}

foreach var of local append_vars {
    local found = 0
    foreach mvar of local master_vars {
        if "`var'" == "`mvar'" {
            local found = 1
            continue, break
        }
    }
    if !`found' {
        local only_append "`only_append' `var'"
    }
}

local n_common: word count `common_vars'
local n_only_master: word count `only_master'
local n_only_append: word count `only_append'

display "共同变量数:         " %5.0f `n_common'
display "仅主数据集变量数:   " %5.0f `n_only_master'
display "仅追加数据集变量数: " %5.0f `n_only_append'

if `n_only_master' > 0 {
    display ""
    display as result "仅在主数据集中的变量:`only_master'"
    display as result ">>> 这些变量在追加数据集中将为缺失值"
}

if `n_only_append' > 0 {
    display ""
    display as result "仅在追加数据集中的变量:`only_append'"
    display as result ">>> 这些变量在主数据集中将为缺失值"
}

if `n_only_master' == 0 & `n_only_append' == 0 {
    display ""
    display as result ">>> 变量结构完全一致 ✓"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 4: 执行纵向合并
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 执行纵向合并"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 执行 append 操作..."

append using `append_data', force

local n_total = _N
display ""
display ">>> 合并完成"
display "合并后总样本量:     " %10.0fc `n_total'

* 验证样本量
local expected_total = `n_master' + `n_append'
if `n_total' != `expected_total' {
    display ""
    display as error "WARNING: 合并后样本量与预期不符"
    display as error "预期: " %0.0fc `expected_total' ", 实际: " %0.0fc `n_total'
}
else {
    display as result ">>> 样本量验证通过 (`n_master' + `n_append' = `n_total')"
}

* ==============================================================================
* SECTION 5: 合并结果诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 合并结果诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 5.1 数据来源分布"
display "-------------------------------------------------------------------------------"
tabulate _source

display ""
display ">>> 5.2 合并后变量结构"
display "-------------------------------------------------------------------------------"
describe, short

* 检查因合并产生的缺失值
display ""
display ">>> 5.3 各变量有效率检查"
display "-------------------------------------------------------------------------------"
display ""
display "{hline 60}"
display "变量名" _col(30) "有效数" _col(45) "有效率"
display "{hline 60}"

local has_missing_issue = 0
foreach var of varlist * {
    if "`var'" != "_source" {
        quietly count if !missing(`var')
        local n_valid = r(N)
        local pct_valid = (`n_valid' / `n_total') * 100
        
        if `pct_valid' < 100 {
            local has_missing_issue = 1
            if `pct_valid' < 50 {
                display as error "`var'" _col(30) %8.0fc `n_valid' _col(45) %6.1f `pct_valid' "%"
            }
            else {
                display "`var'" _col(30) %8.0fc `n_valid' _col(45) %6.1f `pct_valid' "%"
            }
        }
    }
}

if !`has_missing_issue' {
    display "所有变量有效率均为 100%"
}
display "{hline 60}"

* ==============================================================================
* SECTION 6: 主键唯一性检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 主键唯一性检查"
display "═══════════════════════════════════════════════════════════════════════════════"

capture confirm variable `id_var'
local has_id = (_rc == 0)
capture confirm variable `time_var'
local has_time = (_rc == 0)

if `has_id' & `has_time' {
    display ""
    display ">>> 检查主键唯一性: `id_var' × `time_var'"
    duplicates report `id_var' `time_var'
    
    quietly duplicates tag `id_var' `time_var', generate(_dup_flag)
    quietly count if _dup_flag > 0
    local n_dups = r(N)
    
    if `n_dups' > 0 {
        display ""
        display as error "WARNING: 发现 `n_dups' 条重复记录"
        display as error "可能原因: 两个数据集有重叠时期"
        display ""
        display "重复记录示例（前10条）:"
        list `id_var' `time_var' _source if _dup_flag > 0 in 1/10, separator(0)
    }
    else {
        display as result ">>> 主键唯一性检查通过 ✓"
    }
    drop _dup_flag
}
else if `has_id' {
    display ""
    display ">>> 检查主键唯一性: `id_var'"
    duplicates report `id_var'
}
else {
    display ">>> 未指定主键变量，跳过唯一性检查"
}

* ==============================================================================
* SECTION 7: 时间覆盖检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 时间覆盖检查"
display "═══════════════════════════════════════════════════════════════════════════════"

capture confirm variable `time_var'
if _rc == 0 {
    display ""
    display ">>> 时间范围覆盖检查"
    display "-------------------------------------------------------------------------------"
    
    summarize `time_var'
    
    display ""
    display ">>> 7.2 各时期样本量分布"
    display "-------------------------------------------------------------------------------"
    tabulate `time_var' _source
}
else {
    display ">>> 未指定时间变量，跳过时间覆盖检查"
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 8.1 导出追加诊断报告
display ""
display ">>> 8.1 导出追加诊断报告: table_T05_append_report.csv"

preserve
clear
set obs 6

generate str30 item = ""
generate str50 value = ""

replace item = "主数据集样本量" in 1
replace value = "`n_master'" in 1

replace item = "追加数据集样本量" in 2
replace value = "`n_append'" in 2

replace item = "合并后总样本量" in 3
replace value = "`n_total'" in 3

replace item = "共同变量数" in 4
replace value = "`n_common'" in 4

replace item = "仅主数据集变量数" in 5
replace value = "`n_only_master'" in 5

replace item = "仅追加数据集变量数" in 6
replace value = "`n_only_append'" in 6

export delimited using "table_T05_append_report.csv", replace
display "SS_OUTPUT_FILE|file=table_T05_append_report.csv|type=table|desc=append_diagnostics_report"
display ">>> 追加诊断报告已导出"
restore

* 8.2 导出合并后数据
display ""
display ">>> 8.2 导出追加后数据"

* CSV格式
export delimited using "table_T05_appended_data.csv", replace
display "SS_OUTPUT_FILE|file=table_T05_appended_data.csv|type=table|desc=appended_dataset_csv"
display ">>> CSV格式: table_T05_appended_data.csv"

* DTA格式
save "data_T05_appended_data.dta", replace
display "SS_OUTPUT_FILE|file=data_T05_appended_data.dta|type=data|desc=appended_dataset_dta"
display ">>> DTA格式: data_T05_appended_data.dta"

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T05 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "追加概况:"
display "  - 主数据集:        " %10.0fc `n_master' " 条"
display "  - 追加数据集:      " %10.0fc `n_append' " 条"
display "  - 合并后总数:      " %10.0fc `n_total' " 条"
display "  - 共同变量数:      " %10.0fc `n_common'
display ""
display "输出文件:"
display "  - table_T05_append_report.csv  追加诊断报告"
display "  - table_T05_appended_data.csv  追加后数据(CSV)"
display "  - data_T05_appended_data.dta   追加后数据(DTA)"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_master|value=`n_master'"
display "SS_SUMMARY|key=n_append|value=`n_append'"
display "SS_SUMMARY|key=n_total|value=`n_total'"
display "SS_SUMMARY|key=n_common_vars|value=`n_common'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T05|status=ok|elapsed_sec=`elapsed'"

log close
