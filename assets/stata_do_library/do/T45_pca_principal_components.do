* ==============================================================================
* SS_TEMPLATE: id=T45  level=L0  module=I  title="Principal Component Analysis"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T45_eigenvalues.csv type=table desc="Eigenvalue table"
*   - table_T45_loadings.csv type=table desc="Loading matrix"
*   - table_T45_scores.csv type=table desc="Component scores"
*   - fig_T45_scree.png type=graph desc="Scree plot"
*   - fig_T45_pca_scatter.png type=graph desc="PC1-PC2 scatter"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="pca command"
* ==============================================================================
* Task ID:      T45_pca_principal_components
* Task Name:    主成分分析
* Family:       I - 多变量与无监督学习
* Description:  进行主成分分析
* 
* Placeholders: __NUMERIC_VARS__   - 分析变量列表
*               __N_COMPONENTS__   - 提取主成分数量
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

program define ss_fail_T45
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T45|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T45|level=L0|title=Principal_Component_Analysis"
display "SS_SUMMARY|key=template_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T45_pca_principal_components                                   ║"
display "║  TASK_NAME: 主成分分析（Principal Component Analysis）                      ║"
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
        ss_fail_T45 601 "confirm file" "data_file_not_found"
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

* 主成分数量：如果未指定或无效则默认3个
local n_components = __N_COMPONENTS__
local n_input_vars: word count `numeric_vars'
if `n_components' <= 0 | `n_components' > `n_input_vars' {
    local n_components = min(3, `n_input_vars')
}

display ""
display ">>> 用于PCA的变量: `numeric_vars'"
display ">>> 提取主成分数: `n_components'"
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
display ">>> PCA基于相关系数矩阵（标准化变量）"
correlate `numeric_vars'

* ==============================================================================
* SECTION 3: 主成分分析
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 主成分分析"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
pca `numeric_vars'

* ==============================================================================
* SECTION 4: 特征值与方差解释
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 特征值与方差解释"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 特征值、方差比例及累积方差："
estat eigenvalues

* ==============================================================================
* SECTION 5: 碎石图
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 碎石图（Scree Plot）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 绘制碎石图（用于确定主成分数量）"

screeplot, ///
    title("碎石图（Scree Plot）", size(medium)) ///
    ytitle("特征值") ///
    xtitle("主成分") ///
    yline(1, lcolor(gray) lpattern(dash)) ///
    note("水平虚线为Kaiser准则（特征值=1）", size(small)) ///
    scheme(s1color)

graph export "fig_T45_scree.png", replace width(1000) height(700)
display "SS_OUTPUT_FILE|file=fig_T45_scree.png|type=graph|desc=scree_plot"
display ">>> 碎石图已导出: fig_T45_scree.png"

* ==============================================================================
* SECTION 6: 主成分载荷
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 主成分载荷（Factor Loadings）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 载荷矩阵（原变量与主成分的相关）："
estat loadings

* ==============================================================================
* SECTION 7: 提取主成分得分
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 提取主成分得分"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 提取前 `n_components' 个主成分得分"

* 动态提取主成分
local pc_list ""
forvalues i = 1/`n_components' {
    local pc_list "`pc_list' pc`i'"
}
predict `pc_list', score

display ""
summarize `pc_list'

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出特征值表
display ""
display ">>> 导出特征值表: table_T45_eigenvalues.csv"

* 获取特征值矩阵
matrix eigenvalues = e(Ev)
local n_eigenvalues = colsof(eigenvalues)

preserve
clear
set obs `n_eigenvalues'
generate int component = _n
generate double eigenvalue = .
generate double proportion = .
generate double cumulative = .

local total_var = 0
forvalues i = 1/`n_eigenvalues' {
    local total_var = `total_var' + eigenvalues[1, `i']
}

local cum_prop = 0
forvalues i = 1/`n_eigenvalues' {
    local ev = eigenvalues[1, `i']
    local prop = `ev' / `total_var'
    local cum_prop = `cum_prop' + `prop'
    replace eigenvalue = `ev' in `i'
    replace proportion = `prop' in `i'
    replace cumulative = `cum_prop' in `i'
}

export delimited using "table_T45_eigenvalues.csv", replace
display "SS_OUTPUT_FILE|file=table_T45_eigenvalues.csv|type=table|desc=eigenvalues"
display ">>> 特征值表已导出"
restore

* 导出载荷矩阵
display ""
display ">>> 导出载荷矩阵: table_T45_loadings.csv"

matrix loadings = e(L)
local n_vars = rowsof(loadings)
local n_pcs = colsof(loadings)

preserve
clear
set obs `n_vars'
generate str32 variable = ""

* 获取变量名
local varnames : rownames loadings
local i = 1
foreach v of local varnames {
    replace variable = "`v'" in `i'
    local i = `i' + 1
}

* 添加各主成分载荷列
forvalues j = 1/`n_pcs' {
    generate double pc`j'_loading = .
    forvalues i = 1/`n_vars' {
        replace pc`j'_loading = loadings[`i', `j'] in `i'
    }
}

export delimited using "table_T45_loadings.csv", replace
display "SS_OUTPUT_FILE|file=table_T45_loadings.csv|type=table|desc=loadings"
display ">>> 载荷矩阵已导出"
restore

* 导出主成分得分
display ""
display ">>> 导出主成分得分: table_T45_scores.csv"

preserve
keep `pc_list'
export delimited using "table_T45_scores.csv", replace
display "SS_OUTPUT_FILE|file=table_T45_scores.csv|type=table|desc=pc_scores"
display ">>> 主成分得分已导出"
restore

* ==============================================================================
* SECTION 9: 主成分散点图
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 9: 主成分散点图"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> PC1 vs PC2 散点图"

twoway scatter pc2 pc1, ///
    title("主成分得分散点图", size(medium)) ///
    xtitle("PC1") ///
    ytitle("PC2") ///
    msize(small) ///
    scheme(s1color)

graph export "fig_T45_pca_scatter.png", replace width(1000) height(700)
display "SS_OUTPUT_FILE|file=fig_T45_pca_scatter.png|type=graph|desc=pc_scatter"
display ">>> 散点图已导出: fig_T45_pca_scatter.png"

* 清理
drop pc1 pc2 pc3

* ==============================================================================
* SECTION 10: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T45 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "PCA分析概况:"
display "  - 样本量:          " %10.0fc `n_total'
display "  - 输入变量数:      " %10.0fc wordcount("`numeric_vars'")
display ""
display "输出文件:"
display "  - table_T45_eigenvalues.csv   特征值表"
display "  - table_T45_loadings.csv      载荷矩阵"
display "  - table_T45_scores.csv        主成分得分"
display "  - fig_T45_scree.png           碎石图"
display "  - fig_T45_pca_scatter.png     PC1-PC2散点图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
local nvars = wordcount("`numeric_vars'")
display "SS_SUMMARY|key=n_vars|value=`nvars'"
display "SS_SUMMARY|key=n_components|value=`n_components'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T45|status=ok|elapsed_sec=`elapsed'"

log close
