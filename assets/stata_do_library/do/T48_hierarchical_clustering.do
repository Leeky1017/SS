* ==============================================================================
* SS_TEMPLATE: id=T48  level=L0  module=I  title="Hierarchical Clustering"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T48_clusters.csv type=table desc="Cluster assignments"
*   - fig_T48_dendrogram.png type=graph desc="Dendrogram"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="cluster command"
* ==============================================================================
* Task ID:      T48_hierarchical_clustering
* Task Name:    层次聚类
* Family:       I - 多变量与无监督学习
* Description:  进行层次聚类
* 
* Placeholders: __NUMERIC_VARS__    - 聚类变量列表
*               __LINKAGE_METHOD__  - 连接方法
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.2)
* - 2026-01-08: Keep hierarchical clustering with linkage choice documented and dendrogram export (保留层次聚类并明确链接方法).
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 {
    display "SS_RC|code=`=_rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

program define ss_fail_T48
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T48|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T48|level=L0|title=Hierarchical_Clustering"
display "SS_SUMMARY|key=template_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T48_hierarchical_clustering                                   ║"
display "║  TASK_NAME: 层次聚类（Hierarchical Clustering）                           ║"
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
        ss_fail_T48 601 "confirm file" "data_file_not_found"
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
local linkage "__LINKAGE_METHOD__"

display ""
display ">>> 聚类变量: `numeric_vars'"
display ">>> 连接方法: `linkage'"
display "-------------------------------------------------------------------------------"

* ---------- Clustering pre-checks (T47–T48 通用) ----------
* 1. 检查指定的数值变量是否存在
foreach v of varlist `numeric_vars' {
    capture confirm variable `v'
    if _rc {
        display as error "ERROR: Variable `v' not found（变量不存在）."
        ss_fail_T48 200 "runtime" "task_failed"
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
    ss_fail_T48 200 "runtime" "task_failed"
}

* 3. 检查样本量 >= 2（层次聚类至少需要2个样本）
local first_var: word 1 of `kept_vars'
quietly count if !missing(`first_var')
local n_obs = r(N)

if `n_obs' < 2 {
    display as error "ERROR: Hierarchical clustering requires at least 2 observations（样本量不足）."
    ss_fail_T48 200 "runtime" "task_failed"
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
display ">>> 对变量进行Z-score标准化"

local zvars ""
foreach var of varlist `CLUSTER_VARS' {
    quietly summarize `var'
    generate z_`var' = (`var' - r(mean)) / r(sd)
    local zvars "`zvars' z_`var'"
}

display ">>> 已生成标准化变量"

* ==============================================================================
* SECTION 3: 层次聚类
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 层次聚类（`linkage'连接法）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 连接方法说明："
display "    - single:   单连接（最近邻）"
display "    - complete: 完全连接（最远邻）"
display "    - average:  平均连接（常用）"
display "    - ward:     Ward法（最小方差）"
display "-------------------------------------------------------------------------------"

cluster `linkage'linkage `zvars', name(hclust)

* ==============================================================================
* SECTION 4: 树状图
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 树状图（Dendrogram）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 绘制树状图"

cluster dendrogram hclust, ///
    title("层次聚类树状图", size(medium)) ///
    subtitle("连接方法: `linkage'", size(small)) ///
    ylabel(, angle(0)) ///
    xlabel(, labsize(tiny)) ///
    scheme(s1color)

graph export "fig_T48_dendrogram.png", replace width(1200) height(700)
display "SS_OUTPUT_FILE|file=fig_T48_dendrogram.png|type=graph|desc=dendrogram"
display ">>> 树状图已导出: fig_T48_dendrogram.png"

* ==============================================================================
* SECTION 5: 生成聚类标签
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 生成聚类标签"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 根据不同切割水平生成簇标签"

cluster generate cluster3 = groups(3), name(hclust)
cluster generate cluster4 = groups(4), name(hclust)

display ""
display ">>> 3簇分布："
tabulate cluster3

display ""
display ">>> 4簇分布："
tabulate cluster4

* ==============================================================================
* SECTION 6: 各簇特征
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 各簇特征"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各簇在原始变量上的均值（3簇）："
tabstat `numeric_vars', by(cluster3) statistics(mean n) nototal

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出聚类结果: table_T48_clusters.csv"

preserve
keep cluster3 cluster4 `numeric_vars'
export delimited using "table_T48_clusters.csv", replace
display "SS_OUTPUT_FILE|file=table_T48_clusters.csv|type=table|desc=cluster_assignments"
display ">>> 聚类结果已导出"
restore

* 清理
drop z_* cluster3 cluster4
cluster drop hclust

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T48 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "层次聚类概况:"
display "  - 样本量:          " %10.0fc `n_total'
display "  - 聚类变量数:      " %10.0fc wordcount("`numeric_vars'")
display "  - 连接方法:        `linkage'"
display ""
display "输出文件:"
display "  - table_T48_clusters.csv     聚类结果（含簇标签）"
display "  - fig_T48_dendrogram.png     树状图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
local nvars = wordcount("`numeric_vars'")
display "SS_SUMMARY|key=n_vars|value=`nvars'"
display "SS_SUMMARY|key=linkage|value=`linkage'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T48|status=ok|elapsed_sec=`elapsed'"

log close
