* ==============================================================================
* SS_TEMPLATE: id=T46  level=L0  module=I  title="Exploratory Factor Analysis"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T46_loadings.csv type=table desc="Factor loadings"
*   - table_T46_scores.csv type=table desc="Factor scores"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="factor command"
* ==============================================================================
* Task ID:      T46_factor_analysis
* Task Name:    因子分析
* Family:       I - 多变量与无监督学习
* Description:  进行探索性因子分析
* 
* Placeholders: __NUMERIC_VARS__  - 分析变量列表
*               __N_FACTORS__     - 提取因子数量
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
display "SS_TASK_BEGIN|id=T46|level=L0|title=Exploratory_Factor_Analysis"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T46_factor_analysis                                           ║"
display "║  TASK_NAME: 因子分析（Exploratory Factor Analysis）                        ║"
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
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
display "SS_OUTPUT_FILE|file=`datafile'|type=table|desc=output"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}
* ---------- 标准化数据加载逻辑结束 ----------

local n_total = _N
display ">>> 数据加载成功: `n_total' 条观测"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 1: 变量设置
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量设置"
display "═══════════════════════════════════════════════════════════════════════════════"

local numeric_vars "__NUMERIC_VARS__"
local n_factors = __N_FACTORS__

display ""
display ">>> 分析变量: `numeric_vars'"
display ">>> 提取因子数: `n_factors'"
display "-------------------------------------------------------------------------------"

summarize `numeric_vars'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 相关系数矩阵
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 相关系数矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
correlate `numeric_vars'

* ==============================================================================
* SECTION 3: KMO检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: KMO检验（因子分析适用性）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> KMO检验标准："
display "    > 0.9:  非常适合"
display "    0.8-0.9: 适合"
display "    0.7-0.8: 一般"
display "    0.6-0.7: 勉强可以"
display "    < 0.6:  不适合因子分析"
display "-------------------------------------------------------------------------------"

factor `numeric_vars', pcf
estat kmo

* ==============================================================================
* SECTION 4: 因子分析
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 因子分析（提取`n_factors'个因子）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
factor `numeric_vars', pcf factors(`n_factors')

* ==============================================================================
* SECTION 5: 因子载荷（旋转前）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 因子载荷（旋转前）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
estat loadings

* ==============================================================================
* SECTION 6: 因子旋转（Varimax）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 因子旋转（Varimax正交旋转）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Varimax旋转使载荷更易解释"
rotate, varimax

display ""
display ">>> 旋转后因子载荷："
estat loadings

* ==============================================================================
* SECTION 7: 因子得分
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 因子得分"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 使用回归法计算因子得分"

if `n_factors' == 1 {
    predict f1, regression
    summarize f1
}
else if `n_factors' == 2 {
    predict f1 f2, regression
    summarize f1 f2
}
else {
    predict f1 f2 f3, regression
    summarize f1 f2 f3
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出因子载荷
display ""
display ">>> 导出因子载荷: table_T46_loadings.csv"

matrix L = e(L)
matrix list L

preserve
clear
svmat L, names(Factor)
generate str32 variable = ""
local varlist `numeric_vars'
local i = 1
foreach var of local varlist {
    quietly replace variable = "`var'" in `i'
    local i = `i' + 1
}
order variable
export delimited using "table_T46_loadings.csv", replace
display "SS_OUTPUT_FILE|file=table_T46_loadings.csv|type=table|desc=factor_loadings"
display ">>> 因子载荷已导出"
restore

* 导出因子得分
display ""
display ">>> 导出因子得分: table_T46_scores.csv"

preserve
if `n_factors' == 1 {
    keep f1
}
else if `n_factors' == 2 {
    keep f1 f2
}
else {
    keep f1 f2 f3
}
export delimited using "table_T46_scores.csv", replace
display "SS_OUTPUT_FILE|file=table_T46_scores.csv|type=table|desc=factor_scores"
display ">>> 因子得分已导出"
restore

* 清理
capture drop f1 f2 f3
if _rc != 0 { }

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T46 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "因子分析概况:"
display "  - 样本量:          " %10.0fc `n_total'
display "  - 输入变量数:      " %10.0fc wordcount("`numeric_vars'")
display "  - 提取因子数:      " %10.0fc `n_factors'
display ""
display "输出文件:"
display "  - table_T46_loadings.csv     因子载荷（旋转后）"
display "  - table_T46_scores.csv       因子得分"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
local nvars = wordcount("`numeric_vars'")
display "SS_SUMMARY|key=n_vars|value=`nvars'"
display "SS_SUMMARY|key=n_factors|value=`n_factors'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T46|status=ok|elapsed_sec=`elapsed'"

log close
