* ==============================================================================
* SS_TEMPLATE: id=T06  level=L1  module=A  title="Reshape Wide Long"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T06_reshape_report.csv type=table desc="Reshape diagnostics report"
*   - table_T06_reshaped_data.csv type=table desc="Reshaped dataset CSV"
*   - data_T06_reshaped_data.dta type=data desc="Reshaped dataset Stata"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core reshape commands"
* ==============================================================================
* Task ID:      T06_reshape_wide_long
* Task Name:    数据表形态转换（宽表/长表）
* Family:       A - 数据管理与预处理
* Description:  在宽表和长表之间进行 reshape 转换
* 
* Placeholders: __RESHAPE_DIRECTION__ - 转换方向: wide 或 long
*               __STUB_VARS__         - 变量前缀/桩
*               __ID_VAR__            - 个体标识变量
*               __TIME_VAR__          - 时间变量名
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only, no SSC packages)
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 {
    * No log to close - expected
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T06|level=L1|title=Reshape_Wide_Long"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: reshaped dataset + reshape summary / 输出：reshape 后数据集 + 汇总表
* - Error policy: fail on invalid reshape identifiers/j variables / 错误策略：reshape 关键变量不合法→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T06|ssc=none|output=dta_csv|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T06_reshape_wide_long                                              ║"
display "║  TASK_NAME: 数据表形态转换（宽表/长表）                                      ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ---------- 标准化数据加载逻辑开始 ----------
* [ZH] S01 加载数据并准备 reshape 所需结构
* [EN] S01 Load data and prepare reshape structure
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
	        display "SS_TASK_END|id=T06|status=fail|elapsed_sec=`elapsed'"
	        log close
	        exit 601
	    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
    display "SS_OUTPUT_FILE|file=`datafile'|type=data|desc=converted_from_csv"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}
* ---------- 标准化数据加载逻辑结束 ----------

local n_original = _N
display ">>> 数据加载成功: `n_original' 条观测"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 1: 原始数据概况
* ==============================================================================
* [ZH] S02 校验 reshape 参数与变量（i/j/varlist）
* [EN] S02 Validate reshape parameters and variables (i/j/varlist)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 原始数据概况"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 1.1 数据集概况"
display "-------------------------------------------------------------------------------"
display "样本量:             " %10.0fc _N
describe, short

* 记录原始变量数
quietly describe
local n_vars_original = r(k)
display ""
display "变量数:             " %10.0fc `n_vars_original'

display ""
display ">>> 1.2 原始数据预览（前5行）"
display "-------------------------------------------------------------------------------"
list in 1/5, separator(5) abbreviate(12)

* 检查ID变量
display ""
local id_var_check "__ID_VAR__"
display ">>> 1.3 ID变量检查: `id_var_check'"
display "-------------------------------------------------------------------------------"

capture confirm variable `id_var_check'
if _rc {
    display as error "ERROR: ID variable `id_var_check' not found"
    display "SS_RC|code=111|cmd=confirm variable|msg=id_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}

* 参数定义
local id_var "__ID_VAR__"
local time_var "__TIME_VAR__"

* 使用官方命令统计唯一值数量（替代 distinct）
tempvar _tag_id
quietly bysort `id_var': gen `_tag_id' = _n == 1
quietly count if `_tag_id'
local n_ids_orig = r(N)
drop `_tag_id'
display "唯一ID数:           " %10.0fc `n_ids_orig'

* 计算每个ID的记录数（用于判断当前是宽表还是长表）
quietly bysort `id_var': gen _n_per_id = _N
quietly summarize _n_per_id
local avg_per_id = r(mean)
local max_per_id = r(max)
local min_per_id = r(min)
drop _n_per_id

display "每ID平均记录数:     " %10.1f `avg_per_id'
display "每ID最大记录数:     " %10.0fc `max_per_id'
display "每ID最小记录数:     " %10.0fc `min_per_id'

if `max_per_id' == 1 {
    display ""
    display as result ">>> 当前为宽表结构（每ID仅1条记录）"
    local current_format = "wide"
}
else {
    display ""
    display as result ">>> 当前为长表结构（每ID多条记录）"
    local current_format = "long"
}

* ==============================================================================
* SECTION 2: 转换参数显示
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 转换参数"
display "═══════════════════════════════════════════════════════════════════════════════"

local direction "__RESHAPE_DIRECTION__"
local stub_vars "__STUB_VARS__"

display ""
display "转换方向:           `direction'"
display "ID变量 (i):         `id_var'"
display "时间变量 (j):       `time_var'"
display "转换变量 (stub):    `stub_vars'"
display ""

* 验证转换方向与当前格式的一致性

if "`direction'" == "long" & "`current_format'" == "long" {
    display as error "WARNING: 数据已是长表格式，reshape long 可能非预期操作"
}
else if "`direction'" == "wide" & "`current_format'" == "wide" {
    display as error "WARNING: 数据已是宽表格式，reshape wide 可能非预期操作"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 3: 执行 reshape
* ==============================================================================
* [ZH] S03 执行 reshape 并输出结果摘要
* [EN] S03 Run reshape and emit summary
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 执行 reshape 转换"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 执行 reshape `direction' ..."
display ""

* 执行 reshape 命令
capture noisily reshape `direction' `stub_vars', i(`id_var') j(`time_var')

if _rc {
    display ""
    display as error "ERROR: reshape 失败"
    display as error "常见原因："
    display as error "  1. ID变量不唯一（对于 wide->long）"
    display as error "  2. ID+时间变量组合不唯一（对于 long->wide）"
    display as error "  3. stub 变量名不正确"
    display as error "  4. 时间变量j取值有问题"
    display "SS_RC|code=`=_rc'|cmd=reshape|msg=reshape_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

local n_reshaped = _N
display ""
display ">>> reshape 成功完成"
display "转换后样本量:       " %10.0fc `n_reshaped'

* ==============================================================================
* SECTION 4: 转换结果诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 转换结果诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 4.1 转换后数据结构"
display "-------------------------------------------------------------------------------"
describe, short

quietly describe
local n_vars_reshaped = r(k)

display ""
display ">>> 4.2 转换前后对比"
display "-------------------------------------------------------------------------------"
display "{hline 50}"
display "指标" _col(25) "转换前" _col(40) "转换后"
display "{hline 50}"
display "样本量" _col(25) %10.0fc `n_original' _col(40) %10.0fc `n_reshaped'
display "变量数" _col(25) %10.0fc `n_vars_original' _col(40) %10.0fc `n_vars_reshaped'
display "唯一ID数" _col(25) %10.0fc `n_ids_orig' _col(40) %10.0fc `n_ids_orig'
display "{hline 50}"

* 计算转换比率
if "`direction'" == "long" {
    local expand_ratio = `n_reshaped' / `n_original'
    display ""
    display "扩展比率: " %5.1f `expand_ratio' " (每行扩展为 " %9.0f `expand_ratio' " 行)"
}
else {
    local compress_ratio = `n_original' / `n_reshaped'
    display ""
    display "压缩比率: " %5.1f `compress_ratio' " (每 " %9.0f `compress_ratio' " 行压缩为 1 行)"
}

display ""
display ">>> 4.3 转换后数据预览（前10行）"
display "-------------------------------------------------------------------------------"
list in 1/10, separator(5) abbreviate(12)

* ==============================================================================
* SECTION 5: 转换后ID和时间变量检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 转换后数据验证"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 5.1 ID变量唯一性检查"
display "-------------------------------------------------------------------------------"

if "`direction'" == "wide" {
    * 转换为宽表后，ID应唯一
    duplicates report `id_var'
    
    quietly duplicates tag `id_var', generate(_dup_check)
    quietly count if _dup_check > 0
    if r(N) > 0 {
        display as error "WARNING: 转换后ID变量不唯一"
    }
    else {
        display as result ">>> ID变量唯一性检查通过 ✓"
    }
    drop _dup_check
}
else {
    * 转换为长表后，ID+时间应唯一
    duplicates report `id_var' `time_var'
    
    quietly duplicates tag `id_var' `time_var', generate(_dup_check)
    quietly count if _dup_check > 0
    if r(N) > 0 {
        display as error "WARNING: 转换后ID+时间组合不唯一"
    }
    else {
        display as result ">>> ID+时间组合唯一性检查通过 ✓"
    }
    drop _dup_check
}

* 检查时间变量（仅 long 格式）
if "`direction'" == "long" {
    display ""
    display ">>> 5.2 时间变量分布"
    display "-------------------------------------------------------------------------------"
    tabulate `time_var'
}

* ==============================================================================
* SECTION 6: 数据质量检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 数据质量检查"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 6.1 转换后描述统计"
display "-------------------------------------------------------------------------------"
summarize

display ""
display ">>> 6.2 缺失值检查"
display "-------------------------------------------------------------------------------"

local has_missing = 0
foreach var of varlist * {
    quietly count if missing(`var')
    if r(N) > 0 {
        local pct_miss = (r(N) / `n_reshaped') * 100
        if `pct_miss' > 10 {
            display as error "`var': " %8.0fc r(N) " 条缺失 (" %5.1f `pct_miss' "%)"
            local has_missing = 1
        }
    }
}

if !`has_missing' {
    display ">>> 所有变量缺失率均低于10%"
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 7.1 导出转换诊断报告
display ""
display ">>> 7.1 导出转换诊断报告: table_T06_reshape_report.csv"

preserve
clear
set obs 6

generate str30 item = ""
generate str50 value = ""

replace item = "转换方向" in 1
replace value = "`direction'" in 1

replace item = "转换前样本量" in 2
replace value = "`n_original'" in 2

replace item = "转换后样本量" in 3
replace value = "`n_reshaped'" in 3

replace item = "转换前变量数" in 4
replace value = "`n_vars_original'" in 4

replace item = "转换后变量数" in 5
replace value = "`n_vars_reshaped'" in 5

replace item = "唯一ID数" in 6
replace value = "`n_ids_orig'" in 6

export delimited using "table_T06_reshape_report.csv", replace
display "SS_OUTPUT_FILE|file=table_T06_reshape_report.csv|type=table|desc=reshape_diagnostics_report"
display ">>> 转换诊断报告已导出"
restore

* 7.2 导出转换后数据
display ""
display ">>> 7.2 导出转换后数据"

* CSV格式
export delimited using "table_T06_reshaped_data.csv", replace
display "SS_OUTPUT_FILE|file=table_T06_reshaped_data.csv|type=table|desc=reshaped_dataset_csv"
display ">>> CSV格式: table_T06_reshaped_data.csv"

* DTA格式
save "data_T06_reshaped_data.dta", replace
display "SS_OUTPUT_FILE|file=data_T06_reshaped_data.dta|type=data|desc=reshaped_dataset_dta"
display ">>> DTA格式: data_T06_reshaped_data.dta"

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T06 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "转换概况:"
display "  - 转换方向:        __RESHAPE_DIRECTION__"
display "  - ID变量:          __ID_VAR__"
display "  - 时间变量:        __TIME_VAR__"
display "  - 转换前样本量:    " %10.0fc `n_original'
display "  - 转换后样本量:    " %10.0fc `n_reshaped'
display "  - 唯一ID数:        " %10.0fc `n_ids_orig'
display ""
display "输出文件:"
display "  - table_T06_reshape_report.csv  转换诊断报告"
display "  - table_T06_reshaped_data.csv   转换后数据(CSV)"
display "  - data_T06_reshaped_data.dta    转换后数据(DTA)"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=direction|value=__RESHAPE_DIRECTION__"
display "SS_SUMMARY|key=n_original|value=`n_original'"
display "SS_SUMMARY|key=n_reshaped|value=`n_reshaped'"
display "SS_SUMMARY|key=n_ids|value=`n_ids_orig'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_reshaped'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T06|status=ok|elapsed_sec=`elapsed'"

log close
