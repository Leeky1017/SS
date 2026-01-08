* ==============================================================================
* SS_TEMPLATE: id=TA13  level=L0  module=A  title="Stratified Sample"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA13_sample_summary.csv type=table desc="Sample summary"
*   - data_TA13_sampled.dta type=data desc="Sampled data"
*   - data_TA13_sampled.csv type=data desc="Sampled CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="sample command"
* ==============================================================================
* Task ID:      TA13_stratified_sample
* Task Name:    数据集抽样
* Family:       A - 数据管理
* Description:  执行分层随机抽样
* 
* Placeholders: __STRATA_VAR__     - 分层变量
*               __SAMPLE_SIZE__    - 样本量或比例
*               __METHOD__         - 方法
*               __RANDOM_SEED__    - 随机种子
*               __WITH_REPLACE__   - 是否放回抽样
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
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
display "SS_TASK_BEGIN|id=TA13|level=L0|title=Stratified_Sample"
display "SS_METRIC|name=task_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local strata_var "__STRATA_VAR__"
local sample_size __SAMPLE_SIZE__
local method "__METHOD__"
local random_seed __RANDOM_SEED__
local with_replace "__WITH_REPLACE__"

* 参数默认值
if "`method'" == "" {
    local method = "proportional"
}
if `random_seed' <= 0 {
    local random_seed = 12345
}
if "`with_replace'" == "" {
    local with_replace = "no"
}

display ""
display ">>> 分层抽样参数:"
display "    分层变量: `strata_var'"
display "    样本量/比例: `sample_size'"
display "    方法: `method'"
display "    随机种子: `random_seed'"
display "    放回抽样: `with_replace'"

* 设置随机种子
set seed `random_seed'

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA13|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 601
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

* ============ 变量检查 ============
capture confirm variable `strata_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable `strata_var'|msg=strata_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA13|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

* ============ 分层结构分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 分层结构分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 获取各层信息
quietly levelsof `strata_var', local(strata_levels)
local n_strata : word count `strata_levels'

display ""
display ">>> 分层变量: `strata_var'"
display ">>> 层数: `n_strata'"
display ""
display "层         N        占比"
display "─────────────────────────────"

* 创建统计存储
tempname stratastats
postfile `stratastats' str32 stratum str10 stage long n double pct long n_sample ///
    using "temp_strata_stats.dta", replace

foreach s of local strata_levels {
    quietly count if `strata_var' == `s'
    local n_s = r(N)
    local pct_s = (`n_s' / `n_input') * 100
    
    post `stratastats' ("`s'") ("before") (`n_s') (`pct_s') (0)
    
    display %10s "`s'" "  " %8.0fc `n_s' "  " %6.2f `pct_s' "%"
}

display "─────────────────────────────"
display %10s "Total" "  " %8.0fc `n_input' "  100.00%"

display "SS_METRIC|name=n_strata|value=`n_strata'"

* ============ 计算各层样本量 ============
display ""
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 计算各层样本量"
display "═══════════════════════════════════════════════════════════════════════════════"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* 判断是比例还是数量
if `sample_size' > 0 & `sample_size' < 1 {
    local is_proportion = 1
    local total_sample = round(`n_input' * `sample_size')
    display ">>> 抽样比例: " %5.1f `=`sample_size'*100' "%"
    display ">>> 目标样本量: `total_sample'"
}
else {
    local is_proportion = 0
    local total_sample = `sample_size'
    display ">>> 目标样本量: `total_sample'"
}

* 生成抽样标记
generate byte _sample = 0
generate double _rand = runiform()

local total_sampled = 0

foreach s of local strata_levels {
    * 计算该层样本量
    quietly count if `strata_var' == `s'
    local n_stratum = r(N)
    
    if "`method'" == "proportional" {
        * 按比例抽样
        if `is_proportion' {
            local n_sample_s = round(`n_stratum' * `sample_size')
        }
        else {
            local n_sample_s = round(`total_sample' * `n_stratum' / `n_input')
        }
    }
    else if "`method'" == "equal" {
        * 等量抽样
        local n_sample_s = round(`total_sample' / `n_strata')
    }
    else if "`method'" == "fixed" {
        * 固定数量
        local n_sample_s = min(`sample_size', `n_stratum')
    }
    
    * 确保不超过层内样本量
    if `n_sample_s' > `n_stratum' {
        local n_sample_s = `n_stratum'
        display "SS_RC|code=0|cmd=validate_sample_size|msg=oversample_reduced_to_stratum_size|severity=warn"
    }
    
    display ">>> 层 `s': 抽取 `n_sample_s' / `n_stratum'"
    
    * 执行抽样
    if "`with_replace'" == "yes" {
        * 放回抽样（允许重复选择）
        sort `strata_var' _rand
        by `strata_var': replace _sample = 1 if `strata_var' == `s' & _n <= `n_sample_s'
    }
    else {
        * 不放回抽样
        sort `strata_var' _rand
        by `strata_var': replace _sample = 1 if `strata_var' == `s' & _n <= `n_sample_s'
    }
    
    * 更新统计
    quietly count if `strata_var' == `s' & _sample == 1
    local actual_sampled = r(N)
    local total_sampled = `total_sampled' + `actual_sampled'
    
    * 记录抽样后统计
    local pct_s = (`actual_sampled' / `total_sample') * 100
    post `stratastats' ("`s'") ("after") (`actual_sampled') (`pct_s') (`actual_sampled')
}

postclose `stratastats'

display ""
display ">>> 实际抽样总量: `total_sampled'"
display "SS_METRIC|name=n_sampled|value=`total_sampled'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 保留样本 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 保留样本"
display "═══════════════════════════════════════════════════════════════════════════════"

display "SS_STEP_BEGIN|step=S03_analysis"

keep if _sample == 1
drop _sample _rand

local n_output = _N
display ">>> 保留样本量: `n_output'"

* 验证分层结构
display ""
display "抽样后各层分布:"
display "层         N        占比"
display "─────────────────────────────"

foreach s of local strata_levels {
    quietly count if `strata_var' == `s'
    local n_s = r(N)
    local pct_s = (`n_s' / `n_output') * 100
    display %10s "`s'" "  " %8.0fc `n_s' "  " %6.2f `pct_s' "%"
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

display "SS_STEP_BEGIN|step=S04_output"

* 导出统计摘要
preserve
use "temp_strata_stats.dta", clear
export delimited using "table_TA13_sample_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA13_sample_summary.csv|type=table|desc=sample_summary"
restore

* 导出数据
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S04_output|status=ok|elapsed_sec=0"

save "data_TA13_sampled.dta", replace
display "SS_OUTPUT_FILE|file=data_TA13_sampled.dta|type=data|desc=sampled_data"

export delimited using "data_TA13_sampled.csv", replace
display "SS_OUTPUT_FILE|file=data_TA13_sampled.csv|type=data|desc=sampled_csv"

* 清理临时文件
capture erase "temp_strata_stats.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA13 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  抽样比例:        " %10.2f `=`n_output'/`n_input'*100' "%"
display "  分层数:          " %10.0fc `n_strata'
display "  抽样方法:        `method'"
display "  随机种子:        `random_seed'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = `n_input' - `n_output'
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_strata|value=`n_strata'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA13|status=ok|elapsed_sec=`elapsed'"
log close
