* ==============================================================================
* SS_TEMPLATE: id=TA14  level=L1  module=A  title="Data Quality"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA14_quality_summary.csv type=table desc="Quality summary"
*   - table_TA14_var_diagnostics.csv type=table desc="Variable diagnostics"
*   - table_TA14_issues.csv type=table desc="Issues list"
*   - fig_TA14_quality_heatmap.png type=figure desc="Quality heatmap"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - mdesc source=ssc purpose="missing data description"
* ==============================================================================
* Task ID:      TA14_data_quality
* Task Name:    数据质量诊断报告
* Family:       A - 数据管理
* Description:  全面评估数据集质量
* 
* Placeholders: __CHECK_VARS__     - 要检查的变量
*               __ID_VAR__         - 主键变量
*               __QUALITY_THRESHOLD__ - 质量阈值
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands)
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=TA14|level=L1|title=Data_Quality"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "mdesc"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_MISSING:cmd=`dep':hint=ssc install `dep'"
        display "SS_ERROR:DEP_MISSING:`dep' is required but not installed"
        display "SS_ERR:DEP_MISSING:`dep' is required but not installed"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=mdesc|source=ssc|status=ok"

* ============ 参数设置 ============
local check_vars = "__CHECK_VARS__"
local id_var = "__ID_VAR__"
local quality_threshold = __QUALITY_THRESHOLD__

* 参数默认值
if `quality_threshold' <= 0 | `quality_threshold' > 1 {
    local quality_threshold = 0.8
}

display ""
display ">>> 数据质量诊断参数:"
if "`check_vars'" != "" {
    display "    检查变量: `check_vars'"
}
else {
    display "    检查变量: 全部"
}
if "`id_var'" != "" {
    display "    主键变量: `id_var'"
}
display "    质量阈值: `quality_threshold'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC:n_input:`n_input'"

* 获取变量列表
if "`check_vars'" == "" {
    ds
    local check_vars = r(varlist)
}
local n_vars : word count `check_vars'

display ">>> 检查变量数: `n_vars'"
display ">>> 观测数: `n_input'"

* ============ 缺失值分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 缺失值分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用mdesc进行缺失值分析
mdesc `check_vars'

* 创建变量诊断存储
tempname vardiag
postfile `vardiag' str32 variable str10 type long n_total long n_missing double pct_missing ///
    long n_unique double completeness_score byte has_issue str50 issue_desc ///
    using "temp_var_diagnostics.dta", replace

* 创建问题清单存储
tempname issues
postfile `issues' str32 variable str20 issue_type str100 description double severity ///
    using "temp_issues.dta", replace

local total_issues = 0
local total_missing = 0

display ""
display "变量                 类型      N       缺失    缺失率   唯一值  完整度"
display "───────────────────────────────────────────────────────────────────────────"

foreach var of local check_vars {
    * 获取变量类型
    local vartype : type `var'
    local is_string = (substr("`vartype'", 1, 3) == "str")
    
    * 缺失值统计
    quietly count if missing(`var')
    local n_missing = r(N)
    local pct_missing = (`n_missing' / `n_input') * 100
    local total_missing = `total_missing' + `n_missing'
    
    * 唯一值统计
    quietly levelsof `var', local(levels)
    local n_unique : word count `levels'
    
    * 计算完整度得分
    local completeness = 1 - (`n_missing' / `n_input')
    
    * 检测问题
    local has_issue = 0
    local issue_desc = ""
    
    * 问题1: 高缺失率
    if `pct_missing' > 50 {
        local has_issue = 1
        local issue_desc = "高缺失率(>`=50'%)"
        post `issues' ("`var'") ("high_missing") ("缺失率`pct_missing'%超过50%") (0.8)
        local total_issues = `total_issues' + 1
    }
    else if `pct_missing' > 20 {
        local has_issue = 1
        local issue_desc = "中等缺失率(>20%)"
        post `issues' ("`var'") ("medium_missing") ("缺失率`pct_missing'%超过20%") (0.5)
        local total_issues = `total_issues' + 1
    }
    
    * 问题2: 零方差（常数）
    if !`is_string' & `n_unique' == 1 {
        local has_issue = 1
        local issue_desc = "`issue_desc' 常数变量"
        post `issues' ("`var'") ("zero_variance") ("变量只有一个唯一值") (0.6)
        local total_issues = `total_issues' + 1
    }
    
    * 问题3: 疑似ID变量（唯一值=样本量）
    if `n_unique' == `n_input' & !`is_string' {
        post `issues' ("`var'") ("possible_id") ("每个值都唯一，可能是ID变量") (0.2)
    }
    
    post `vardiag' ("`var'") ("`vartype'") (`n_input') (`n_missing') (`pct_missing') ///
        (`n_unique') (`completeness') (`has_issue') ("`issue_desc'")
    
    * 显示
    local type_short = substr("`vartype'", 1, 6)
    display %20s "`var'" "  " %6s "`type_short'" "  " %6.0fc `n_input' "  " ///
        %6.0fc `n_missing' "  " %6.2f `pct_missing' "%  " %6.0fc `n_unique' "  " %5.2f `completeness'
}

postclose `vardiag'
postclose `issues'

display "───────────────────────────────────────────────────────────────────────────"
display ">>> 总缺失值数: `total_missing'"
display ">>> 检测到问题数: `total_issues'"

display "SS_METRIC:n_missing_total:`total_missing'"
display "SS_METRIC:n_issues:`total_issues'"

* ============ 主键唯一性检查 ============
if "`id_var'" != "" {
    display ""
    display "═══════════════════════════════════════════════════════════════════════════════"
    display "SECTION 2: 主键唯一性检查"
    display "═══════════════════════════════════════════════════════════════════════════════"
    
    capture confirm variable `id_var'
    if !_rc {
        quietly duplicates report `id_var'
        local n_dup = r(unique_value)
        local is_unique = (`n_dup' == `n_input')
        
        if `is_unique' {
            display ">>> 主键 `id_var' 唯一性检查: 通过"
            display "SS_METRIC:id_unique:1"
        }
        else {
            display ">>> 主键 `id_var' 唯一性检查: 失败"
            display ">>> 唯一值: `n_dup', 总观测: `n_input'"
            display "SS_WARNING:ID_NOT_UNIQUE:Primary key has duplicates"
            display "SS_METRIC:id_unique:0"
        }
    }
}

* ============ 计算整体质量得分 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 整体质量评估"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算各维度得分
local completeness_score = 1 - (`total_missing' / (`n_input' * `n_vars'))

* 加载变量诊断计算更多指标
preserve
use "temp_var_diagnostics.dta", clear
quietly summarize completeness_score
local avg_completeness = r(mean)
quietly count if has_issue == 1
local n_problem_vars = r(N)
restore

local problem_var_ratio = 1 - (`n_problem_vars' / `n_vars')
local overall_score = (`completeness_score' * 0.4) + (`problem_var_ratio' * 0.4) + 0.2

display ""
display "质量维度评分:"
display "  完整性得分:      " %5.2f `completeness_score' " (权重40%)"
display "  问题变量比例:    " %5.2f `problem_var_ratio' " (权重40%)"
display "  基础得分:        0.20 (权重20%)"
display "  ─────────────────────────────"
display "  综合质量得分:    " %5.2f `overall_score'

if `overall_score' >= `quality_threshold' {
    display ""
    display ">>> 质量评估: 通过 (>= `quality_threshold')"
}
else {
    display ""
    display ">>> 质量评估: 未通过 (< `quality_threshold')"
    display "SS_WARNING:LOW_QUALITY:Overall quality score below threshold"
}

display "SS_METRIC:quality_score:`overall_score'"

* ============ 生成质量摘要 ============
preserve
clear
set obs 1
generate str30 metric = ""
generate double value = .

local metrics "n_observations n_variables total_missing n_problem_vars completeness_score problem_var_ratio overall_score quality_threshold"
local values "`n_input' `n_vars' `total_missing' `n_problem_vars' `completeness_score' `problem_var_ratio' `overall_score' `quality_threshold'"

local n_metrics : word count `metrics'
set obs `n_metrics'

forvalues i = 1/`n_metrics' {
    local m : word `i' of `metrics'
    local v : word `i' of `values'
    replace metric = "`m'" in `i'
    replace value = `v' in `i'
}

export delimited using "table_TA14_quality_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA14_quality_summary.csv|type=table|desc=quality_summary"
restore

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 变量诊断 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 变量诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出变量诊断
preserve
use "temp_var_diagnostics.dta", clear
export delimited using "table_TA14_var_diagnostics.csv", replace
display "SS_OUTPUT_FILE|file=table_TA14_var_diagnostics.csv|type=table|desc=var_diagnostics"
restore

* 导出问题清单
preserve
use "temp_issues.dta", clear
export delimited using "table_TA14_issues.csv", replace
display "SS_OUTPUT_FILE|file=table_TA14_issues.csv|type=table|desc=issues_list"
restore

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 生成质量热图 ============
display "SS_STEP_BEGIN|step=S03_analysis"

* 生成质量热图（简化版-条形图）
preserve
use "temp_var_diagnostics.dta", clear
graph bar completeness_score, over(variable, sort(completeness_score) label(angle(45) labsize(tiny))) ///
    ytitle("完整度得分") title("变量完整度评分") ///
    yline(`quality_threshold', lcolor(red) lpattern(dash)) ///
    note("红色虚线=质量阈值`quality_threshold'") ///
    bar(1, color(navy))
graph export "fig_TA14_quality_heatmap.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TA14_quality_heatmap.png|type=figure|desc=quality_heatmap"
restore

* 清理临时文件
capture erase "temp_var_diagnostics.dta"
if _rc != 0 { }
capture erase "temp_issues.dta"
if _rc != 0 { }

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA14 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  观测数:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display "  总缺失值:        " %10.0fc `total_missing'
display "  问题变量数:      " %10.0fc `n_problem_vars'
display "  综合质量得分:    " %10.2f `overall_score'
display "  质量阈值:        " %10.2f `quality_threshold'
display "  评估结果:        " cond(`overall_score' >= `quality_threshold', "通过", "未通过")
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_input'"
display "SS_SUMMARY|key=n_vars|value=`n_vars'"
display "SS_SUMMARY|key=overall_score|value=`overall_score'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_input'"
display "SS_METRIC|name=n_missing|value=`total_missing'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA14|status=ok|elapsed_sec=`elapsed'"
log close
