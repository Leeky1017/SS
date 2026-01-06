* ==============================================================================
* SS_TEMPLATE: id=T03  level=L0  module=A  title="Data Filtering and Sampling"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T03_filter_summary.csv type=table desc="Filter process summary"
*   - table_T03_filtered_data.csv type=table desc="Filtered dataset CSV"
*   - data_T03_filtered_data.dta type=data desc="Filtered dataset Stata"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core data management commands"
* ==============================================================================
* Task ID:      T03_filter_and_sample
* Task Name:    数据筛选与抽样
* Family:       A - 数据管理与预处理
* Description:  根据条件筛选样本（如剔除金融业、ST股票、缺失值等），
*               可选进行随机抽样，输出筛选后的清洁数据集
* 
* Placeholders: __FILTER_CONDITION__ - 筛选条件表达式
*               __SAMPLE_FRACTION__  - 抽样比例(0-1)或数量(>=1)
*               __KEY_VARS__         - 关键变量列表
*               __RANDOM_SEED__      - 随机种子（默认12345）
*               __ID_VAR__           - 个体变量（可选）
*               __TIME_VAR__         - 时间变量（可选）
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only, no SSC packages)
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
display "SS_TASK_BEGIN|id=T03|level=L0|title=Data_Filtering_and_Sampling"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T03_filter_and_sample                                              ║"
display "║  TASK_NAME: 数据筛选与抽样                                                   ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ---------- 标准化数据加载逻辑开始 ----------
display "SS_STEP_BEGIN|step=S01_load_data"
local datafile "data.dta"

capture confirm file "`datafile'"
if _rc {
    capture confirm file "data.csv"
    if _rc {
        display as error "ERROR: No data.dta or data.csv found in job directory."
        display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_METRIC|name=task_success|value=0"
        display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
        display "SS_TASK_END|id=T03|status=fail|elapsed_sec=`elapsed'"
        log close
        exit 601
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
display "SS_OUTPUT_FILE|file=`datafile'|type=table|desc=output"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"
* ---------- 标准化数据加载逻辑结束 ----------

local original_n = _N
display ">>> 数据加载成功: `original_n' 条观测"

* 参数定义
local id_var "__ID_VAR__"
local time_var "__TIME_VAR__"
local filter_cond "__FILTER_CONDITION__"

* ==============================================================================
* SECTION 1: 原始数据概况
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 原始数据概况"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 1.1 数据集结构"
display "-------------------------------------------------------------------------------"
describe, short

display ""
display ">>> 1.2 原始样本量统计"
display "-------------------------------------------------------------------------------"
display "原始观测数:         " %10.0fc _N

* 记录原始样本量用于后续比较
local n_original = _N

* 如果有ID和时间变量，输出面板维度
capture confirm variable `id_var'
if _rc == 0 {
    * 使用官方命令统计唯一值数量（替代 distinct）
    tempvar _tag_id
    quietly bysort `id_var': gen `_tag_id' = _n == 1
    quietly count if `_tag_id'
    local n_ids_orig = r(N)
    drop `_tag_id'
    display "原始个体数:         " %10.0fc `n_ids_orig'
}

capture confirm variable `time_var'
if _rc == 0 {
    * 使用官方命令统计唯一值数量（替代 distinct）
    tempvar _tag_time
    quietly bysort `time_var': gen `_tag_time' = _n == 1
    quietly count if `_tag_time'
    local n_times_orig = r(N)
    drop `_tag_time'
    display "原始时期数:         " %10.0fc `n_times_orig'
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 条件筛选
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 条件筛选"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 筛选条件: `filter_cond'"
display ""

* 检查筛选条件涉及的变量是否存在
* 注意：这里用 capture 测试条件是否有效
capture count if `filter_cond'
if _rc {
    display as error "ERROR: 筛选条件无效或涉及不存在的变量"
    display as error "条件: `filter_cond'"
    display as error "请检查变量名和条件语法"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

local n_match = r(N)
local n_not_match = _N - `n_match'
local pct_match = (`n_match' / _N) * 100
local pct_drop = (`n_not_match' / _N) * 100

display ">>> 筛选预览"
display "-------------------------------------------------------------------------------"
display "满足条件的观测:     " %10.0fc `n_match' " (" %5.1f `pct_match' "%)"
display "将被剔除的观测:     " %10.0fc `n_not_match' " (" %5.1f `pct_drop' "%)"

* 警告：如果剔除比例过高
if `pct_drop' > 50 {
    display ""
    display as error "WARNING: 筛选将剔除超过50%的样本，请确认条件是否正确"
}

* 警告：如果保留样本过少
if `n_match' < 100 {
    display ""
    display as error "WARNING: 筛选后样本量将少于100，可能影响统计推断"
}

if `n_match' == 0 {
    display ""
    display as error "ERROR: 筛选后样本量为0，请检查筛选条件"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

* ==============================================================================
* SECTION 3: 分步筛选记录（金融研究常见筛选）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 分步筛选过程"
display "═══════════════════════════════════════════════════════════════════════════════"

* 初始化筛选记录
tempname filter_log
tempfile filter_file

* 记录每步筛选
local step = 0
local n_current = _N

* 创建筛选记录矩阵
matrix filter_summary = J(10, 3, .)
matrix colnames filter_summary = step_n dropped remaining

* Step 0: 原始样本
local step = `step' + 1
matrix filter_summary[`step', 1] = 0
matrix filter_summary[`step', 2] = 0
matrix filter_summary[`step', 3] = _N
display ""
display "Step 0: 原始样本"
display "        样本量: " %10.0fc _N

* ==============================================================================
* SECTION 4: 应用主筛选条件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 应用筛选条件"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_before = _N

* 应用筛选条件
keep if __FILTER_CONDITION__

local n_after = _N
local n_dropped = `n_before' - `n_after'

* 记录筛选
local step = `step' + 1
matrix filter_summary[`step', 1] = `step' - 1
matrix filter_summary[`step', 2] = `n_dropped'
matrix filter_summary[`step', 3] = `n_after'

display ""
display "Step 1: 应用筛选条件 [__FILTER_CONDITION__]"
display "        剔除: " %10.0fc `n_dropped' " 条"
display "        剩余: " %10.0fc `n_after' " 条"

* ==============================================================================
* SECTION 5: 缺失值处理（可选）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 关键变量缺失值检查"
display "═══════════════════════════════════════════════════════════════════════════════"

* 检查是否指定了关键变量
local key_vars "__KEY_VARS__"
local has_key_vars = 0

foreach var of local key_vars {
    capture confirm variable `var'
    if _rc == 0 {
        local has_key_vars = 1
    }
}

if `has_key_vars' {
    display ""
    display ">>> 关键变量缺失情况"
    display "-------------------------------------------------------------------------------"
    
    local n_before_miss = _N
    
    foreach var of local key_vars {
        capture confirm variable `var'
        if _rc == 0 {
            quietly count if missing(`var')
            local n_miss = r(N)
            local pct_miss = (`n_miss' / _N) * 100
            display "`var': " %8.0fc `n_miss' " 条缺失 (" %5.1f `pct_miss' "%)"
        }
    }
    
    * 剔除关键变量缺失的观测
    display ""
    display ">>> 剔除关键变量缺失的观测"
    
    foreach var of local key_vars {
        capture confirm variable `var'
        if _rc == 0 {
            drop if missing(`var')
        }
    }
    
    local n_after_miss = _N
    local n_dropped_miss = `n_before_miss' - `n_after_miss'
    
    if `n_dropped_miss' > 0 {
        local step = `step' + 1
        matrix filter_summary[`step', 1] = `step' - 1
        matrix filter_summary[`step', 2] = `n_dropped_miss'
        matrix filter_summary[`step', 3] = `n_after_miss'
        
        display "Step 2: 剔除关键变量缺失"
        display "        剔除: " %10.0fc `n_dropped_miss' " 条"
        display "        剩余: " %10.0fc `n_after_miss' " 条"
    }
    else {
        display ">>> 无关键变量缺失，无需剔除"
    }
}
else {
    display ">>> 未指定关键变量，跳过缺失值剔除"
}

* ==============================================================================
* SECTION 6: 随机抽样（可选）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 随机抽样"
display "═══════════════════════════════════════════════════════════════════════════════"

* 设置随机种子以保证可重复性
local seed_val = __RANDOM_SEED__
if `seed_val' > 0 {
    set seed `seed_val'
    display ">>> 随机种子: `seed_val'"
}
else {
    set seed 12345
    display ">>> 使用默认随机种子: 12345"
}

* 抽样参数
local sample_param = __SAMPLE_FRACTION__
local n_before_sample = _N

if `sample_param' > 0 & `sample_param' < 1 {
    * 按比例抽样
    local pct_sample = `sample_param' * 100
    display ""
    display ">>> 按比例抽样: `pct_sample'%"
    sample `pct_sample'
    
    local n_after_sample = _N
    local n_dropped_sample = `n_before_sample' - `n_after_sample'
    
    local step = `step' + 1
    matrix filter_summary[`step', 1] = `step' - 1
    matrix filter_summary[`step', 2] = `n_dropped_sample'
    matrix filter_summary[`step', 3] = `n_after_sample'
    
    display "        抽取: " %10.0fc `n_after_sample' " 条"
}
else if `sample_param' >= 1 {
    * 按固定数量抽样
    display ""
    display ">>> 按数量抽样: " %10.0fc `sample_param' " 条"
    
    if _N > `sample_param' {
        sample `sample_param', count
        
        local n_after_sample = _N
        local n_dropped_sample = `n_before_sample' - `n_after_sample'
        
        local step = `step' + 1
        matrix filter_summary[`step', 1] = `step' - 1
        matrix filter_summary[`step', 2] = `n_dropped_sample'
        matrix filter_summary[`step', 3] = `n_after_sample'
        
        display "        抽取: " %10.0fc `n_after_sample' " 条"
    }
    else {
        display ">>> 当前样本量(" _N ")不大于目标数量，保留全部样本"
    }
}
else {
    display ">>> 不进行抽样，保留全部筛选后样本"
}

* ==============================================================================
* SECTION 7: 筛选后数据概况
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 筛选后数据概况"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_final = _N
local pct_retained = (`n_final' / `n_original') * 100

display ""
display ">>> 7.1 最终样本量"
display "-------------------------------------------------------------------------------"
display "原始样本量:         " %10.0fc `n_original'
display "最终样本量:         " %10.0fc `n_final'
display "保留比例:           " %10.1f `pct_retained' "%"
display "剔除总数:           " %10.0fc `n_original' - `n_final'

* 如果有ID和时间变量，输出面板维度
capture confirm variable `id_var'
if _rc == 0 {
    * 使用官方命令统计唯一值数量（替代 distinct）
    tempvar _tag_id_f
    quietly bysort `id_var': gen `_tag_id_f' = _n == 1
    quietly count if `_tag_id_f'
    local n_ids_final = r(N)
    drop `_tag_id_f'
    display ""
    display "最终个体数:         " %10.0fc `n_ids_final'
}

capture confirm variable `time_var'
if _rc == 0 {
    * 使用官方命令统计唯一值数量（替代 distinct）
    tempvar _tag_time_f
    quietly bysort `time_var': gen `_tag_time_f' = _n == 1
    quietly count if `_tag_time_f'
    local n_times_final = r(N)
    drop `_tag_time_f'
    display "最终时期数:         " %10.0fc `n_times_final'
}

display ""
display ">>> 7.2 筛选后描述统计"
display "-------------------------------------------------------------------------------"
summarize

* 样本量警告
if `n_final' < 30 {
    display ""
    display as error "WARNING: 最终样本量少于30，统计推断可能不可靠"
}
else if `n_final' < 100 {
    display ""
    display as result "NOTICE: 最终样本量在30-100之间，部分分析可能需要更大样本"
}
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 8.1 导出筛选汇总表
display ""
display ">>> 8.1 导出筛选过程汇总表: table_T03_filter_summary.csv"

preserve
clear
set obs `step'

generate int step = _n - 1
generate str50 description = ""
generate long n_dropped = .
generate long n_remaining = .

* 填充数据
replace description = "原始样本" in 1
replace n_dropped = 0 in 1
replace n_remaining = `n_original' in 1

forvalues i = 2/`step' {
    replace description = "筛选步骤 `=`i'-1'" in `i'
    replace n_dropped = filter_summary[`i', 2] in `i'
    replace n_remaining = filter_summary[`i', 3] in `i'
}

export delimited using "table_T03_filter_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_T03_filter_summary.csv|type=table|desc=filter_process_summary"
display ">>> 筛选汇总表已导出"
restore

* 8.2 导出筛选后数据
display ""
display ">>> 8.2 导出筛选后数据"

* CSV格式
export delimited using "table_T03_filtered_data.csv", replace
display "SS_OUTPUT_FILE|file=table_T03_filtered_data.csv|type=table|desc=filtered_dataset_csv"
display ">>> CSV格式: table_T03_filtered_data.csv"

* DTA格式
save "data_T03_filtered_data.dta", replace
display "SS_OUTPUT_FILE|file=data_T03_filtered_data.dta|type=data|desc=filtered_dataset_dta"
display ">>> DTA格式: data_T03_filtered_data.dta"

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T03 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "筛选概况:"
display "  - 原始样本量:    " %10.0fc `n_original'
display "  - 最终样本量:    " %10.0fc `n_final'
display "  - 保留比例:      " %10.1f `pct_retained' "%"
display "  - 筛选条件:      __FILTER_CONDITION__"
display ""
display "输出文件:"
display "  - table_T03_filter_summary.csv  筛选过程汇总表"
display "  - table_T03_filtered_data.csv   筛选后数据(CSV)"
display "  - data_T03_filtered_data.dta    筛选后数据(DTA)"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_original|value=`n_original'"
display "SS_SUMMARY|key=n_final|value=`n_final'"
display "SS_SUMMARY|key=pct_retained|value=`pct_retained'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_final'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T03|status=ok|elapsed_sec=`elapsed'"

log close
