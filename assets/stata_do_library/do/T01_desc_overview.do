* ==============================================================================
* SS_TEMPLATE: id=T01  level=L0  module=A  title="Dataset Overview and Descriptive Statistics"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T01_desc_stats.csv type=table desc="Descriptive statistics table"
*   - table_T01_missing_pattern.csv type=table desc="Missing value pattern table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core statistical commands"
* ==============================================================================
* Task ID:      T01_desc_overview
* Task Name:    数据集整体概况与描述统计
* Family:       A - 数据管理与预处理
* Description:  对数据集进行全面的概况分析，包括变量结构、描述统计、缺失值模式、
*               主键唯一性检查，为后续回归/面板/时间序列分析做准备
* 
* Placeholders: __NUMERIC_VARS__ - 要分析的数值变量列表（空格分隔）
*               __ID_VAR__       - 个体/主键变量（可选，用于面板检测）
*               __TIME_VAR__     - 时间变量（可选，用于面板检测）
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only, no SSC packages)
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 {
    * No log to close - this is expected
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
display "SS_TASK_BEGIN|id=T01|level=L0|title=Dataset_Overview_Descriptive_Statistics"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: CSV tables via `export delimited` / 输出：CSV 表格（export delimited）
* - Error policy: warn on partial missing vars; fail on no valid vars / 错误策略：部分缺失→warn；无有效变量→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T01|ssc=none|output=csv|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T01_desc_overview                                                  ║"
display "║  TASK_NAME: 数据集整体概况与描述统计                                         ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ---------- 标准化数据加载逻辑开始 ----------
* [ZH] S01 加载数据（标准化 data.dta / data.csv）
* [EN] S01 Load data (standardized data.dta / data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
local datafile "data.dta"

capture confirm file "`datafile'"
if _rc {
    * 若没有 data.dta，则尝试 data.csv 并立刻转换为 data.dta
    capture confirm file "data.csv"
    if _rc {
        display as error "ERROR: No data.dta or data.csv found in job directory."
        display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_METRIC|name=task_success|value=0"
        display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
        display "SS_TASK_END|id=T01|status=fail|elapsed_sec=`elapsed'"
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
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"
* ---------- 标准化数据加载逻辑结束 ----------

local import_obs = _N
display ">>> 数据加载成功: `import_obs' 条观测"

* ==============================================================================
* SECTION 1: 变量存在性检查
* ==============================================================================
* [ZH] S02 校验输入变量（缺失变量 warn；无可用变量 fail）
* [EN] S02 Validate input variables (warn on missing; fail if none usable)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量存在性检查"
display "═══════════════════════════════════════════════════════════════════════════════"

local numeric_vars "__NUMERIC_VARS__"
local id_var "__ID_VAR__"
local time_var "__TIME_VAR__"

local required_vars "`numeric_vars'"
local missing_vars ""
local valid_vars ""

foreach var of local required_vars {
    capture confirm variable `var'
    if _rc {
        local missing_vars "`missing_vars' `var'"
        display as error "WARNING: Required variable `var' not found in data.csv"
    }
    else {
        local valid_vars "`valid_vars' `var'"
    }
}

if "`missing_vars'" != "" {
    display ""
    display as error "Missing variables:`missing_vars'"
    display as error "Continuing with available variables only..."
    display "SS_RC|code=111|cmd=confirm variable|msg=some_variables_missing|severity=warn"
}

* 检查是否有有效变量可分析
if "`valid_vars'" == "" {
    display as error "ERROR: No valid numeric variables found for analysis"
    display "SS_RC|code=111|cmd=confirm variable|msg=no_valid_variables|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}

local analysis_vars "`valid_vars'"
display ""
display ">>> 将分析的变量: `analysis_vars'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 数据集基本信息
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 数据集基本信息"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 2.1 数据集结构 (describe)"
display "-------------------------------------------------------------------------------"
describe

display ""
display ">>> 2.2 基本维度"
display "-------------------------------------------------------------------------------"
display "总观测数 (N):         " _N
display "总变量数 (K):         " c(k)
display "数据集大小:           " %12.0fc c(memory) " bytes"

* 检查是否为面板/时间序列结构
capture confirm variable `id_var'
local has_id = (_rc == 0)
capture confirm variable `time_var'
local has_time = (_rc == 0)

if `has_id' & `has_time' {
    display ""
    display ">>> 检测到面板数据结构 (ID: `id_var', Time: `time_var')"
    * 使用官方命令统计唯一值数量（替代 distinct）
    tempvar _tag_id _tag_time
    quietly bysort `id_var': gen `_tag_id' = _n == 1
    quietly count if `_tag_id'
    local n_ids = r(N)
    quietly bysort `time_var': gen `_tag_time' = _n == 1
    quietly count if `_tag_time'
    local n_times = r(N)
    drop `_tag_id' `_tag_time'
    display "    个体数 (N):       `n_ids'"
    display "    时期数 (T):       `n_times'"
    display "    理论总观测数:     " `n_ids' * `n_times'
    display "    实际观测数:       " _N
    if _N < `n_ids' * `n_times' {
        display as result "    >>> 不平衡面板 (Unbalanced Panel)"
    }
    else {
        display as result "    >>> 平衡面板 (Balanced Panel)"
    }
}
else if `has_time' {
    display ""
    display ">>> 检测到时间序列数据结构 (Time: `time_var')"
}
else if `has_id' {
    display ""
    display ">>> 检测到截面数据结构 (ID: `id_var')"
}

* ==============================================================================
* SECTION 3: 主键唯一性检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 主键唯一性检查"
display "═══════════════════════════════════════════════════════════════════════════════"

capture confirm variable `id_var'
if _rc == 0 {
    capture confirm variable `time_var'
    if _rc == 0 {
        * 面板数据：检查 id + time 唯一性
        display ""
        display ">>> 检查主键唯一性: `id_var' × `time_var'"
        duplicates report `id_var' `time_var'
        quietly duplicates tag `id_var' `time_var', generate(_dup_flag)
        quietly count if _dup_flag > 0
        local n_dups = r(N)
        if `n_dups' > 0 {
            display ""
            display as error "WARNING: 发现 `n_dups' 条重复记录 (基于 `id_var' + `time_var')"
            display as error "建议: 检查数据或使用 duplicates drop 删除重复行"
            display ""
            display "重复记录示例（前10条）:"
            list `id_var' `time_var' if _dup_flag > 0 in 1/10, separator(0)
        }
        else {
            display as result ">>> 主键唯一性检查通过: 无重复记录"
        }
        drop _dup_flag
    }
    else {
        * 截面数据：检查 id 唯一性
        display ""
        display ">>> 检查主键唯一性: `id_var'"
        duplicates report `id_var'
        quietly duplicates tag `id_var', generate(_dup_flag)
        quietly count if _dup_flag > 0
        local n_dups = r(N)
        if `n_dups' > 0 {
            display ""
            display as error "WARNING: 发现 `n_dups' 条重复记录 (基于 `id_var')"
        }
        else {
            display as result ">>> 主键唯一性检查通过: 无重复记录"
        }
        drop _dup_flag
    }
}
else {
    display ">>> 未指定 ID 变量，跳过主键唯一性检查"
}

* ==============================================================================
* SECTION 4: 数值变量描述统计
* ==============================================================================
* [ZH] S03 统计分析（描述统计 + 分位数 + 缺失模式）
* [EN] S03 Analysis (descriptive stats + quantiles + missingness)
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 数值变量描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 4.1 基础描述统计 (summarize)"
display "-------------------------------------------------------------------------------"
summarize `analysis_vars'

display ""
display ">>> 4.2 详细描述统计 (含分位数)"
display "-------------------------------------------------------------------------------"
summarize `analysis_vars', detail

display ""
display ">>> 4.3 扩展分位数统计"
display "-------------------------------------------------------------------------------"
tabstat `analysis_vars', statistics(n mean sd min p1 p5 p10 p25 p50 p75 p90 p95 p99 max) columns(statistics) format(%12.4f)

* ==============================================================================
* SECTION 5: 缺失值分析
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 缺失值分析"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 5.1 各变量缺失情况"
display "-------------------------------------------------------------------------------"
display ""
display "{hline 60}"
display "变量名" _col(25) "缺失数" _col(40) "缺失比例" _col(55) "状态"
display "{hline 60}"

local total_obs = _N
local any_missing = 0

foreach var of local analysis_vars {
    quietly count if missing(`var')
    local miss_n = r(N)
    local miss_pct = (`miss_n' / `total_obs') * 100
    
    if `miss_pct' == 0 {
        local status "✓ 完整"
    }
    else if `miss_pct' < 5 {
        local status "轻微"
        local any_missing = 1
    }
    else if `miss_pct' < 20 {
        local status "中等"
        local any_missing = 1
    }
    else {
        local status "严重!"
        local any_missing = 1
    }
    
    display "`var'" _col(25) %8.0f `miss_n' _col(40) %6.2f `miss_pct' "%" _col(55) "`status'"
}
display "{hline 60}"

if `any_missing' {
    display ""
    display as result ">>> 建议: 存在缺失值，后续分析前请考虑处理方式（删除/插补）"
}

display ""
display ">>> 5.2 缺失值模式汇总 (misstable summarize)"
display "-------------------------------------------------------------------------------"
misstable summarize `analysis_vars'

display ""
display ">>> 5.3 缺失值模式分析 (misstable patterns)"
display "-------------------------------------------------------------------------------"
misstable patterns `analysis_vars'

* ==============================================================================
* SECTION 6: 有效样本量检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 有效样本量检查"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算完整案例数
quietly count
local total_n = r(N)

tempvar complete_case
generate `complete_case' = 1
foreach var of local analysis_vars {
    quietly replace `complete_case' = 0 if missing(`var')
}
quietly count if `complete_case' == 1
local complete_n = r(N)
local complete_pct = (`complete_n' / `total_n') * 100

display ""
display "总观测数:           " %10.0fc `total_n'
display "完整案例数:         " %10.0fc `complete_n' " (" %5.1f `complete_pct' "%)"
display "含缺失案例数:       " %10.0fc `total_n' - `complete_n'

if `complete_n' < 30 {
    display ""
    display as error "WARNING: 完整案例数少于30，样本量可能不足以进行可靠的统计推断"
    display as error "建议: 检查数据质量或考虑缺失值插补方法"
}
else if `complete_n' < 100 {
    display ""
    display as result "NOTICE: 完整案例数在30-100之间，部分高级分析可能需要更大样本"
}
else {
    display ""
    display as result ">>> 样本量检查通过: 完整案例数充足"
}

* ==============================================================================
* SECTION 7: 变量类型检测
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 变量类型检测与异常值初筛"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 7.1 变量类型与唯一值数量"
display "-------------------------------------------------------------------------------"
display ""
display "{hline 70}"
display "变量名" _col(25) "存储类型" _col(40) "唯一值数" _col(55) "建议类型"
display "{hline 70}"

foreach var of local analysis_vars {
    local vtype: type `var'
    * 使用官方命令统计唯一值数量（替代 distinct）
    tempvar __tag_distinct
    quietly bysort `var': gen `__tag_distinct' = _n == 1
    quietly count if `__tag_distinct'
    local n_distinct = r(N)
    drop `__tag_distinct'
    
    * 判断建议类型
    if strpos("`vtype'", "str") > 0 {
        local suggest "字符串(考虑encode)"
    }
    else if `n_distinct' <= 2 {
        local suggest "二元变量"
    }
    else if `n_distinct' <= 10 {
        local suggest "分类变量"
    }
    else {
        local suggest "连续变量"
    }
    
    display "`var'" _col(25) "`vtype'" _col(40) %8.0f `n_distinct' _col(55) "`suggest'"
}
display "{hline 70}"

display ""
display ">>> 7.2 极端值初筛 (1%/99%分位数外的观测)"
display "-------------------------------------------------------------------------------"

foreach var of local analysis_vars {
    * 检查是否为数值型
    capture confirm numeric variable `var'
    if _rc == 0 {
        quietly summarize `var', detail
        local p1 = r(p1)
        local p99 = r(p99)
        quietly count if `var' < `p1' | `var' > `p99'
        local n_extreme = r(N)
        if `n_extreme' > 0 {
            local pct_extreme = (`n_extreme' / _N) * 100
            display "`var': `n_extreme' 个极端值 (" %4.1f `pct_extreme' "% 在1%-99%分位数外)"
        }
    }
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果文件
* ==============================================================================
* [ZH] S04 导出输出文件（与 OUTPUTS/SS_OUTPUT_FILE 对齐）
* [EN] S04 Export declared outputs (OUTPUTS + SS_OUTPUT_FILE anchors)
display "SS_STEP_BEGIN|step=S04_export"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 8.1 导出描述统计表
display ""
display ">>> 8.1 导出描述统计表: table_T01_desc_stats.csv"

preserve
quietly {
    * 计算统计量
    local n_vars: word count `analysis_vars'
    
    clear
    set obs `n_vars'
    
    generate str32 variable = ""
    generate double n = .
    generate double mean = .
    generate double sd = .
    generate double min = .
    generate double p1 = .
    generate double p5 = .
    generate double p10 = .
    generate double p25 = .
    generate double p50 = .
    generate double p75 = .
    generate double p90 = .
    generate double p95 = .
    generate double p99 = .
    generate double max = .
    generate double n_missing = .
    generate double pct_missing = .
}

restore
preserve

* 构建统计表
quietly tabstat `analysis_vars', statistics(n mean sd min p1 p5 p10 p25 p50 p75 p90 p95 p99 max) save
matrix S = r(StatTotal)

clear
local n_vars: word count `analysis_vars'
set obs `n_vars'

generate str32 variable = ""
generate double n = .
generate double mean = .
generate double sd = .
generate double min = .
generate double p1 = .
generate double p5 = .
generate double p10 = .
generate double p25 = .
generate double p50 = .
generate double p75 = .
generate double p90 = .
generate double p95 = .
generate double p99 = .
generate double max = .

local i = 1
foreach var of local analysis_vars {
    quietly replace variable = "`var'" in `i'
    quietly replace n = S[1, `i'] in `i'
    quietly replace mean = S[2, `i'] in `i'
    quietly replace sd = S[3, `i'] in `i'
    quietly replace min = S[4, `i'] in `i'
    quietly replace p1 = S[5, `i'] in `i'
    quietly replace p5 = S[6, `i'] in `i'
    quietly replace p10 = S[7, `i'] in `i'
    quietly replace p25 = S[8, `i'] in `i'
    quietly replace p50 = S[9, `i'] in `i'
    quietly replace p75 = S[10, `i'] in `i'
    quietly replace p90 = S[11, `i'] in `i'
    quietly replace p95 = S[12, `i'] in `i'
    quietly replace p99 = S[13, `i'] in `i'
    quietly replace max = S[14, `i'] in `i'
    local i = `i' + 1
}

export delimited using "table_T01_desc_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_T01_desc_stats.csv|type=table|desc=descriptive_statistics"
display ">>> 描述统计表已导出: table_T01_desc_stats.csv"

restore

* 8.2 导出缺失值模式表
display ""
display ">>> 8.2 导出缺失值分析表: table_T01_missing_pattern.csv"

preserve
clear
local n_vars: word count `analysis_vars'
set obs `n_vars'

generate str32 variable = ""
generate long n_total = `total_obs'
generate long n_missing = .
generate double pct_missing = .

local i = 1
foreach var of local analysis_vars {
    quietly replace variable = "`var'" in `i'
    local i = `i' + 1
}

restore
preserve

* 计算缺失数
local i = 1
foreach var of local analysis_vars {
    quietly count if missing(`var')
    local miss_`i' = r(N)
    local i = `i' + 1
}

clear
local n_vars: word count `analysis_vars'
set obs `n_vars'

generate str32 variable = ""
generate long n_total = `total_obs'
generate long n_missing = .
generate double pct_missing = .

local i = 1
foreach var of local analysis_vars {
    quietly replace variable = "`var'" in `i'
    quietly replace n_missing = `miss_`i'' in `i'
    quietly replace pct_missing = (`miss_`i'' / `total_obs') * 100 in `i'
    local i = `i' + 1
}

export delimited using "table_T01_missing_pattern.csv", replace
display "SS_OUTPUT_FILE|file=table_T01_missing_pattern.csv|type=table|desc=missing_value_pattern"
display ">>> 缺失值分析表已导出: table_T01_missing_pattern.csv"

restore

display "SS_STEP_END|step=S04_export|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T01 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "数据集概况:"
display "  - 总观测数:      " %10.0fc _N
display "  - 分析变量数:    " %10.0fc `: word count `analysis_vars''
display "  - 完整案例数:    " %10.0fc `complete_n' " (" %5.1f `complete_pct' "%)"
display ""
display "输出文件:"
display "  - table_T01_desc_stats.csv      描述统计表（含分位数）"
display "  - table_T01_missing_pattern.csv 缺失值模式表"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
local n_vars: word count `analysis_vars'
local n_missing_total = `total_n' - `complete_n'
display "SS_SUMMARY|key=n_obs|value=`total_n'"
display "SS_SUMMARY|key=n_vars_analyzed|value=`n_vars'"
display "SS_SUMMARY|key=complete_cases|value=`complete_n'"
display "SS_SUMMARY|key=complete_rate_pct|value=`complete_pct'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`total_n'"
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T01|status=ok|elapsed_sec=`elapsed'"

log close
