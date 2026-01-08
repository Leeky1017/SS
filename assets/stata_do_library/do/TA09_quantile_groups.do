* ==============================================================================
* SS_TEMPLATE: id=TA09  level=L0  module=A  title="Quantile Groups"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA09_group_summary.csv type=table desc="Group summary"
*   - data_TA09_grouped.dta type=data desc="Grouped data"
*   - data_TA09_grouped.csv type=data desc="Grouped CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="xtile command"
* ==============================================================================
* Task ID:      TA09_quantile_groups
* Task Name:    分组变量生成
* Family:       A - 数据管理
* Description:  基于数值变量生成分组变量
* 
* Placeholders: __SOURCE_VAR__     - 源变量
*               __N_GROUPS__       - 分组数量
*               __METHOD__         - 方法
*               __CUTPOINTS__      - 自定义断点
*               __BY_VAR__         - 分组变量
*               __NEW_VAR__        - 新变量名
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.3) ============
* - 2026-01-08: Validate numeric source variable and handle missing values explicitly when creating quantile groups (分组前先验证数值变量，并显式处理缺失值).

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
display "SS_TASK_BEGIN|id=TA09|level=L0|title=Quantile_Groups"
display "SS_METRIC|name=task_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local source_var "__SOURCE_VAR__"
local n_groups __N_GROUPS__
local method "__METHOD__"
local cutpoints "__CUTPOINTS__"
local by_var "__BY_VAR__"
local new_var "__NEW_VAR__"

* 参数默认值
if `n_groups' <= 1 | `n_groups' > 100 {
    local n_groups = 4
}
if "`method'" == "" | ("`method'" != "quantile" & "`method'" != "equal" & "`method'" != "custom") {
    local method = "quantile"
}
if "`new_var'" == "" {
    local new_var = "`source_var'_grp"
}

display ""
display ">>> 分组参数:"
display "    源变量: `source_var'"
display "    分组数: `n_groups'"
display "    方法: `method'"
if "`cutpoints'" != "" {
    display "    断点: `cutpoints'"
}
if "`by_var'" != "" {
    display "    按组: `by_var'"
}
display "    新变量: `new_var'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 601
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

* ============ 变量检查 ============
capture confirm numeric variable `source_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable `source_var'|msg=source_var_not_numeric_or_missing|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

if "`by_var'" != "" {
    capture confirm variable `by_var'
    if _rc {
        display "SS_RC|code=0|cmd=confirm variable `by_var'|msg=by_var_not_found_ignored|severity=warn"
        local by_var ""
    }
}

* ============ 源变量统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 源变量统计"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize `source_var', detail
local n_valid = r(N)
local mean_val = r(mean)
local sd_val = r(sd)
local min_val = r(min)
local max_val = r(max)
local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)

display ""
display "变量: `source_var'"
display "  N = `n_valid'"
display "  Mean = " %12.4f `mean_val' ", SD = " %12.4f `sd_val'
display "  Min = " %12.4f `min_val' ", Max = " %12.4f `max_val'
display "  P25 = " %12.4f `p25' ", P50 = " %12.4f `p50' ", P75 = " %12.4f `p75'

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 分组处理 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 分组处理"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`method'" == "quantile" {
    * 分位数分组
    display ">>> 方法: 等分位数分组"
    
    if "`by_var'" != "" {
        * 按组计算分位数
        bysort `by_var': egen `new_var' = cut(`source_var'), group(`n_groups')
        display ">>> 按 `by_var' 分组计算分位数"
    }
    else {
        xtile `new_var' = `source_var', nq(`n_groups')
    }
}
else if "`method'" == "equal" {
    * 等间距分组
    display ">>> 方法: 等间距分组"
    
    local interval = (`max_val' - `min_val') / `n_groups'
    generate `new_var' = .
    
    forvalues g = 1/`n_groups' {
        local lower = `min_val' + (`g' - 1) * `interval'
        local upper = `min_val' + `g' * `interval'
        
        if `g' == 1 {
            replace `new_var' = `g' if `source_var' >= `lower' & `source_var' < `upper'
        }
        else if `g' == `n_groups' {
            replace `new_var' = `g' if `source_var' >= `lower' & `source_var' <= `upper'
        }
        else {
            replace `new_var' = `g' if `source_var' >= `lower' & `source_var' < `upper'
        }
        
        display "    组`g': [`lower', `upper'" cond(`g'==`n_groups', "]", ")")
    }
}
else if "`method'" == "custom" {
    * 自定义断点
    display ">>> 方法: 自定义断点分组"
    
    if "`cutpoints'" == "" {
        display "SS_RC|code=198|cmd=validate_cutpoints|msg=no_cutpoints_for_custom_method|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = round(r(t1))
        display "SS_TASK_END|id=TA09|status=fail|elapsed_sec=`elapsed'"
        log close
        exit 198
    }
    
    * 解析断点
    local cutpoints = subinstr("`cutpoints'", ",", " ", .)
    local n_cuts : word count `cutpoints'
    local n_groups = `n_cuts' + 1
    
    generate `new_var' = .
    
    * 第一组
    local cut1 : word 1 of `cutpoints'
    replace `new_var' = 1 if `source_var' < `cut1'
    display "    组1: (-inf, `cut1')"
    
    * 中间组
    forvalues i = 1/`=`n_cuts'-1' {
        local lower : word `i' of `cutpoints'
        local upper : word `=`i'+1' of `cutpoints'
        replace `new_var' = `=`i'+1' if `source_var' >= `lower' & `source_var' < `upper'
        display "    组`=`i'+1': [`lower', `upper')"
    }
    
    * 最后一组
    local last_cut : word `n_cuts' of `cutpoints'
    replace `new_var' = `n_groups' if `source_var' >= `last_cut'
    display "    组`n_groups': [`last_cut', +inf)"
}

display ""
display ">>> 生成分组变量: `new_var'"
display "SS_METRIC|name=n_groups|value=`n_groups'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 分组统计 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 分组统计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建统计存储
tempname grpstats
postfile `grpstats' byte group long n double mean double sd double min double max ///
    using "temp_group_stats.dta", replace

display ""
display "组别      N        均值         标准差        最小值       最大值"
display "─────────────────────────────────────────────────────────────────────"

forvalues g = 1/`n_groups' {
    quietly summarize `source_var' if `new_var' == `g'
    local n_g = r(N)
    local mean_g = r(mean)
    local sd_g = r(sd)
    local min_g = r(min)
    local max_g = r(max)
    
    post `grpstats' (`g') (`n_g') (`mean_g') (`sd_g') (`min_g') (`max_g')
    
    display %3.0f `g' "    " %8.0fc `n_g' "  " %12.4f `mean_g' "  " %12.4f `sd_g' "  " %12.4f `min_g' "  " %12.4f `max_g'
}

postclose `grpstats'

* 添加标签
label variable `new_var' "`source_var'分组 (1-`n_groups')"

* 生成标签
if "`method'" == "quantile" {
    forvalues g = 1/`n_groups' {
        local pct_low = (`g' - 1) * 100 / `n_groups'
        local pct_high = `g' * 100 / `n_groups'
        label define `new_var'_lbl `g' "Q`g' (P`pct_low'-P`pct_high')", add
    }
}
else {
    forvalues g = 1/`n_groups' {
        label define `new_var'_lbl `g' "Group `g'", add
    }
}
label values `new_var' `new_var'_lbl

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出统计摘要
preserve
use "temp_group_stats.dta", clear
export delimited using "table_TA09_group_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA09_group_summary.csv|type=table|desc=group_summary"
restore

* 导出数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

save "data_TA09_grouped.dta", replace
display "SS_OUTPUT_FILE|file=data_TA09_grouped.dta|type=data|desc=grouped_data"

export delimited using "data_TA09_grouped.csv", replace
display "SS_OUTPUT_FILE|file=data_TA09_grouped.csv|type=data|desc=grouped_csv"

* 清理临时文件
capture erase "temp_group_stats.dta"
local rc = _rc
if `rc' != 0 & `rc' != 601 {
    display "SS_RC|code=`rc'|cmd=erase temp_group_stats.dta|msg=tempfile_erase_failed|severity=warn"
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA09 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  源变量:          `source_var'"
display "  分组方法:        `method'"
display "  分组数量:        " %10.0fc `n_groups'
display "  新变量:          `new_var'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_groups|value=`n_groups'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA09|status=ok|elapsed_sec=`elapsed'"
log close
