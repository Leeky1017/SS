* ==============================================================================
* SS_TEMPLATE: id=T02  level=L0  module=A  title="Descriptive Statistics by Group"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T02_group_stats.csv type=table desc="Grouped descriptive statistics"
*   - table_T02_group_means.csv type=table desc="Group means summary"
*   - fig_T02_group_boxplot.png type=graph desc="Grouped boxplot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core statistical commands"
* ==============================================================================
* Task ID:      T02_desc_by_group
* Task Name:    分组描述统计
* Family:       A - 数据管理与预处理
* Description:  按指定分组变量（如行业、年份、地区）对数值变量进行分组描述统计，
*               输出各组的样本量、均值、标准差、分位数等，支持组间差异初步比较
* 
* Placeholders: __NUMERIC_VARS__ - 要分析的数值变量列表（空格分隔）
*               __GROUP_VAR__    - 分组变量
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
display "SS_TASK_BEGIN|id=T02|level=L0|title=Descriptive_Statistics_by_Group"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T02_desc_by_group                                                  ║"
display "║  TASK_NAME: 分组描述统计                                                     ║"
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
        display "SS_TASK_END|id=T02|status=fail|elapsed_sec=`elapsed'"
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
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量存在性检查"
display "═══════════════════════════════════════════════════════════════════════════════"

* 参数定义
local group_var "__GROUP_VAR__"
local numeric_vars "__NUMERIC_VARS__"

* 检查分组变量
capture confirm variable `group_var'
if _rc {
    display as error "ERROR: Required grouping variable `group_var' not found"
    display "SS_RC|code=111|cmd=confirm variable|msg=group_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}
display ">>> 分组变量: `group_var' ✓"

* 检查数值变量
local required_vars "`numeric_vars'"
local valid_vars ""
local missing_vars ""

foreach var of local required_vars {
    capture confirm variable `var'
    if _rc {
        local missing_vars "`missing_vars' `var'"
        display as error "WARNING: Variable `var' not found"
    }
    else {
        local valid_vars "`valid_vars' `var'"
    }
}

if "`valid_vars'" == "" {
    display as error "ERROR: No valid numeric variables found for analysis"
    display "SS_RC|code=111|cmd=confirm variable|msg=no_valid_variables|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}

local analysis_vars "`valid_vars'"
display ">>> 分析变量: `analysis_vars'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 分组变量概况
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 分组变量概况"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 2.1 分组变量频数分布"
display "-------------------------------------------------------------------------------"
tabulate `group_var', missing

* 获取组数和各组样本量
quietly tab `group_var'
local n_groups = r(r)
display ""
display ">>> 组数: `n_groups'"

* 检查组数是否合理
if `n_groups' > 50 {
    display ""
    display as error "WARNING: 分组数量(`n_groups')过多，可能不适合分组描述统计"
    display as error "建议: 考虑重新编码分组变量或使用连续变量处理方法"
}
else if `n_groups' < 2 {
    display ""
    display as error "ERROR: 分组数量少于2，无法进行分组比较"
    display "SS_RC|code=198|cmd=tabulate|msg=insufficient_groups|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 198
}

* 检查各组样本量
display ""
display ">>> 2.2 各组样本量检查"
display "-------------------------------------------------------------------------------"

quietly levelsof `group_var', local(groups)
local small_groups = 0
foreach g of local groups {
    quietly count if `group_var' == `g'
    local n_g = r(N)
    if `n_g' < 30 {
        display as error "WARNING: 组 `g' 样本量仅 `n_g'，统计量可能不稳定"
        local small_groups = `small_groups' + 1
    }
}

if `small_groups' == 0 {
    display as result ">>> 各组样本量均 ≥ 30，统计量较为可靠"
}

* ==============================================================================
* SECTION 3: 分组描述统计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 分组描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 3.1 分组描述统计 (tabstat)"
display "-------------------------------------------------------------------------------"
tabstat `analysis_vars', by(`group_var') statistics(n mean sd min p25 p50 p75 max) columns(statistics) longstub format(%12.4f)

display ""
display ">>> 3.2 扩展分位数分组统计"
display "-------------------------------------------------------------------------------"
tabstat `analysis_vars', by(`group_var') statistics(n mean sd p1 p5 p10 p25 p50 p75 p90 p95 p99) columns(statistics) longstub format(%12.4f)

* ==============================================================================
* SECTION 4: 组间差异初步检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 组间差异初步检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 4.1 各变量组间均值比较与方差分析"
display "-------------------------------------------------------------------------------"

foreach var of local analysis_vars {
    display ""
    display "{hline 60}"
    display "变量: `var'"
    display "{hline 60}"
    
    * 分组均值
    tabulate `group_var', summarize(`var') means standard
    
    * 单因素方差分析（若组数>=2）
    quietly tab `group_var'
    if r(r) >= 2 {
        display ""
        display ">>> 单因素方差分析 (One-way ANOVA)"
        oneway `var' `group_var'
        
        * 如果组数=2，额外做t检验
        if r(r) == 2 {
            display ""
            display ">>> 两组均值t检验"
            ttest `var', by(`group_var')
        }
    }
}

* ==============================================================================
* SECTION 5: 分组箱线图
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 分组箱线图"
display "═══════════════════════════════════════════════════════════════════════════════"

* 对第一个变量画分组箱线图
local first_var: word 1 of `analysis_vars'
display ""
display ">>> 生成 `first_var' 的分组箱线图"

graph box `first_var', over(`group_var') ///
    title("`first_var' 分组箱线图") ///
    ytitle("`first_var'") ///
    note("分组变量: `group_var'")
graph export "fig_T02_group_boxplot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_T02_group_boxplot.png|type=graph|desc=grouped_boxplot"
display ">>> 箱线图已导出: fig_T02_group_boxplot.png"

* ==============================================================================
* SECTION 6: 导出分组统计表
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 6.1 导出分组均值表
display ""
display ">>> 6.1 导出分组均值表: table_T02_group_means.csv"

preserve
collapse (count) n=`first_var' (mean) `analysis_vars', by(`group_var')
export delimited using "table_T02_group_means.csv", replace
display "SS_OUTPUT_FILE|file=table_T02_group_means.csv|type=table|desc=group_means_summary"
display ">>> 分组均值表已导出"
restore

* 6.2 导出详细分组统计表
display ""
display ">>> 6.2 导出详细分组统计表: table_T02_group_stats.csv"

preserve
collapse (count) n=`first_var' ///
         (mean) mean_=`analysis_vars' ///
         (sd) sd_=`analysis_vars' ///
         (p50) median_=`analysis_vars', by(`group_var')
export delimited using "table_T02_group_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_T02_group_stats.csv|type=table|desc=grouped_descriptive_statistics"
display ">>> 详细分组统计表已导出"
restore

* ==============================================================================
* SECTION 7: 组间差异汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 组间差异汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各变量组间差异汇总（ANOVA F检验）"
display "{hline 70}"
display "变量" _col(30) "F统计量" _col(45) "P值" _col(60) "结论"
display "{hline 70}"

foreach var of local analysis_vars {
    quietly oneway `var' `group_var'
    local f_stat = r(F)
    local p_val = Ftail(r(df_m), r(df_r), r(F))
    
    if `p_val' < 0.01 {
        local conclusion "***显著"
    }
    else if `p_val' < 0.05 {
        local conclusion "** 显著"
    }
    else if `p_val' < 0.1 {
        local conclusion "*  边缘"
    }
    else {
        local conclusion "   不显著"
    }
    
    display "`var'" _col(30) %8.3f `f_stat' _col(45) %8.4f `p_val' _col(60) "`conclusion'"
}
display "{hline 70}"
display "注: *** p<0.01, ** p<0.05, * p<0.1"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T02 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "分析概况:"
display "  - 总观测数:      " %10.0fc _N
display "  - 分组变量:      `group_var'"
display "  - 组数:          " %10.0fc `n_groups'
display "  - 分析变量数:    " %10.0fc `: word count `analysis_vars''
display ""
display "输出文件:"
display "  - table_T02_group_means.csv    分组均值表"
display "  - table_T02_group_stats.csv    详细分组统计表"
display "  - fig_T02_group_boxplot.png    分组箱线图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
local n_vars: word count `analysis_vars'
display "SS_SUMMARY|key=n_obs|value=`=_N'"
display "SS_SUMMARY|key=n_groups|value=`n_groups'"
display "SS_SUMMARY|key=n_vars_analyzed|value=`n_vars'"
display "SS_SUMMARY|key=group_var|value=`group_var'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`=_N'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T02|status=ok|elapsed_sec=`elapsed'"

log close
