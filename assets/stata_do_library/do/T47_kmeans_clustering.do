* ==============================================================================
* SS_TEMPLATE: id=T47  level=L0  module=I  title="K-means Clustering"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T47_clusters.csv type=table desc="Cluster assignments"
*   - table_T47_centers.csv type=table desc="Cluster centers"
*   - fig_T47_kmeans.png type=graph desc="Cluster scatter plot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="cluster command"
* ==============================================================================
* Task ID:      T47_kmeans_clustering
* Task Name:    K-means聚类
* Family:       I - 多变量与无监督学习
* Description:  进行K-means聚类
* 
* Placeholders: __NUMERIC_VARS__  - 聚类变量列表
*               __N_CLUSTERS__    - 聚类数量K
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
set seed 12345

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

program define ss_fail_T47
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T47|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T47|level=L0|title=Kmeans_Clustering"
display "SS_SUMMARY|key=template_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T47_kmeans_clustering                                         ║"
display "║  TASK_NAME: K-means聚类（K-means Clustering）                             ║"
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
        ss_fail_T47 601 "confirm file" "data_file_not_found"
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
local n_clusters = __N_CLUSTERS__

display ""
display ">>> 聚类变量: `numeric_vars'"
display ">>> 聚类数量: `n_clusters'"
display "-------------------------------------------------------------------------------"

* ---------- Clustering pre-checks (T47–T48 通用) ----------
* 1. 检查指定的数值变量是否存在
foreach v of varlist `numeric_vars' {
    capture confirm variable `v'
    if _rc {
        display as error "ERROR: Variable `v' not found（变量不存在）."
        ss_fail_T47 200 "runtime" "task_failed"
    }
}

* 2. 删除全缺失或常数列变量
local kept_vars ""
foreach v of varlist `numeric_vars' {
    quietly summarize `v' if !missing(`v'), meanonly
    if r(N) == 0 {
        display as error "WARNING: Variable `v' is all missing and will be dropped from clustering（变量全缺失已排除）."
        continue
    }
    if r(min) == r(max) {
        display as error "WARNING: Variable `v' is constant and will be dropped from clustering（变量为常数已排除）."
        continue
    }
    local kept_vars "`kept_vars' `v'"
}

if "`kept_vars'" == "" {
    display as error "ERROR: No usable variables left after dropping all-missing/constant ones（无有效变量可用于聚类）."
    ss_fail_T47 200 "runtime" "task_failed"
}

* 3. 检查样本量 >= 聚类数
local first_var: word 1 of `kept_vars'
quietly count if !missing(`first_var')
local n_obs = r(N)

if `n_obs' < `n_clusters' {
    display as error "ERROR: Number of observations (`n_obs') is smaller than number of clusters (`n_clusters')（样本量小于聚类数）."
    ss_fail_T47 200 "runtime" "task_failed"
}

* 4. 把 kept_vars 缓存到一个局部宏，后续聚类代码统一用它
local CLUSTER_VARS "`kept_vars'"
display ">>> 聚类检查通过: `n_obs' 个有效样本, 使用变量: `CLUSTER_VARS'"
* ---------- Clustering pre-checks end ----------

summarize `CLUSTER_VARS'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 变量标准化
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 变量标准化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 对变量进行Z-score标准化（消除量纲影响）"

local zvars ""
foreach var of varlist `CLUSTER_VARS' {
    quietly summarize `var'
    generate z_`var' = (`var' - r(mean)) / r(sd)
    local zvars "`zvars' z_`var'"
}

display ">>> 已生成标准化变量: `zvars'"

* ==============================================================================
* SECTION 3: K-means聚类
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: K-means聚类（K=`n_clusters'）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 执行K-means聚类"
display "    目标：最小化组内平方和（Within-cluster SS）"
display "-------------------------------------------------------------------------------"

cluster kmeans `zvars', k(`n_clusters') name(cluster_id) start(krandom)

* ==============================================================================
* SECTION 4: 聚类结果分布
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 聚类结果分布"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各簇样本分布："
tabulate cluster_id

* ==============================================================================
* SECTION 5: 各簇特征
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 各簇特征（原始变量）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各簇在原始变量上的均值和标准差："
tabstat `CLUSTER_VARS', by(cluster_id) statistics(mean sd n) nototal

* ==============================================================================
* SECTION 6: 簇中心
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 簇中心（标准化变量）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各簇中心（标准化尺度）："
tabstat `zvars', by(cluster_id) statistics(mean) nototal

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出聚类结果
display ""
display ">>> 导出聚类结果: table_T47_clusters.csv"

preserve
keep cluster_id `CLUSTER_VARS'
export delimited using "table_T47_clusters.csv", replace
display "SS_OUTPUT_FILE|file=table_T47_clusters.csv|type=table|desc=cluster_assignments"
display ">>> 聚类结果已导出"
restore

* 导出簇中心
display ""
display ">>> 导出簇中心: table_T47_centers.csv"

preserve
collapse (mean) `zvars', by(cluster_id)
export delimited using "table_T47_centers.csv", replace
display "SS_OUTPUT_FILE|file=table_T47_centers.csv|type=table|desc=cluster_centers"
display ">>> 簇中心已导出"
restore

* ==============================================================================
* SECTION 8: 聚类可视化
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 聚类可视化"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 绘制聚类散点图（前两个变量）"

local var1: word 1 of `CLUSTER_VARS'
local var2: word 2 of `CLUSTER_VARS'

if `n_clusters' == 2 {
    twoway (scatter `var2' `var1' if cluster_id==1, mcolor(cranberry) msize(small)) ///
           (scatter `var2' `var1' if cluster_id==2, mcolor(navy) msize(small)), ///
        title("K-means聚类结果 (K=`n_clusters')", size(medium)) ///
        xtitle("`var1'") ytitle("`var2'") ///
        legend(label(1 "簇1") label(2 "簇2") position(6) rows(1)) ///
        scheme(s1color)
}
else {
    twoway (scatter `var2' `var1' if cluster_id==1, mcolor(cranberry) msize(small)) ///
           (scatter `var2' `var1' if cluster_id==2, mcolor(navy) msize(small)) ///
           (scatter `var2' `var1' if cluster_id==3, mcolor(forest_green) msize(small)), ///
        title("K-means聚类结果 (K=`n_clusters')", size(medium)) ///
        xtitle("`var1'") ytitle("`var2'") ///
        legend(label(1 "簇1") label(2 "簇2") label(3 "簇3") position(6) rows(1)) ///
        scheme(s1color)
}

graph export "fig_T47_kmeans.png", replace width(1000) height(700)
display "SS_OUTPUT_FILE|file=fig_T47_kmeans.png|type=graph|desc=cluster_scatter"
display ">>> 聚类散点图已导出: fig_T47_kmeans.png"

* 清理
drop z_*

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T47 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "聚类分析概况:"
display "  - 样本量:          " %10.0fc `n_total'
display "  - 聚类变量数:      " %10.0fc wordcount("`numeric_vars'")
display "  - 聚类数K:         " %10.0fc `n_clusters'
display ""
display "输出文件:"
display "  - table_T47_clusters.csv    聚类结果（含簇标签）"
display "  - table_T47_centers.csv     簇中心（标准化尺度）"
display "  - fig_T47_kmeans.png        聚类散点图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
local nvars = wordcount("`numeric_vars'")
display "SS_SUMMARY|key=n_vars|value=`nvars'"
display "SS_SUMMARY|key=n_clusters|value=`n_clusters'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=seed|value=12345"
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T47|status=ok|elapsed_sec=`elapsed'"

log close
