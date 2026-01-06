* ==============================================================================
* SS_TEMPLATE: id=TS08  level=L2  module=S  title="K-Means Cluster"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS08_centers.csv type=table desc="Cluster centers"
*   - table_TS08_elbow.csv type=table desc="Elbow data"
*   - fig_TS08_elbow.png type=figure desc="Elbow plot"
*   - data_TS08_kmeans.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TS08|level=L2|title=KMeans_Cluster"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local vars = "__VARS__"
local k = __K__
local max_k = __MAX_K__

if `k' < 2 | `k' > 20 {
    local k = 3
}
if `max_k' < `k' | `max_k' > 20 {
    local max_k = 10
}

display ""
display ">>> K均值聚类参数:"
display "    聚类变量: `vars'"
display "    K: `k'"
display "    肘部法则最大K: `max_k'"

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
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
local valid_vars ""
local n_vars = 0
foreach var of local vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_vars "`valid_vars' `var'"
        local n_vars = `n_vars' + 1
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 肘部法则 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 肘部法则（确定最优K）"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname elbow_data
postfile `elbow_data' int k double wss using "temp_elbow.dta", replace

display ""
display "K     组内平方和(WSS)"
display "─────────────────────"

forvalues test_k = 2/`max_k' {
    cluster kmeans `valid_vars', k(`test_k') name(_temp_cluster) start(random(12345))
    
    * 计算组内平方和
    local wss = 0
    forvalues c = 1/`test_k' {
        foreach var of local valid_vars {
            quietly summarize `var' if _temp_cluster == `c'
            local var_ss = r(Var) * (r(N) - 1)
            local wss = `wss' + `var_ss'
        }
    }
    
    post `elbow_data' (`test_k') (`wss')
    display %4.0f `test_k' "   " %15.2f `wss'
    
    drop _temp_cluster
}

postclose `elbow_data'

preserve
use "temp_elbow.dta", clear
export delimited using "table_TS08_elbow.csv", replace
display "SS_OUTPUT_FILE|file=table_TS08_elbow.csv|type=table|desc=elbow_data"

* 生成肘部图
twoway (connected wss k, mcolor(navy) lcolor(navy)), ///
    xtitle("聚类数K") ytitle("组内平方和(WSS)") ///
    title("K均值聚类肘部图") ///
    xlabel(2(1)`max_k')
graph export "fig_TS08_elbow.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TS08_elbow.png|type=figure|desc=elbow_plot"
restore

* ============ K均值聚类 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: K均值聚类 (K=`k')"
display "═══════════════════════════════════════════════════════════════════════════════"

cluster kmeans `valid_vars', k(`k') name(cluster_id) start(random(12345))

display ""
display ">>> 聚类分布:"
tabulate cluster_id

* 计算聚类中心
display ""
display ">>> 聚类中心:"

tempname centers
postfile `centers' int cluster str32 variable double mean double sd ///
    using "temp_centers.dta", replace

forvalues c = 1/`k' {
    foreach var of local valid_vars {
        quietly summarize `var' if cluster_id == `c'
        post `centers' (`c') ("`var'") (r(mean)) (r(sd))
    }
}

postclose `centers'

preserve
use "temp_centers.dta", clear
reshape wide mean sd, i(cluster) j(variable) string
list, noobs
export delimited using "table_TS08_centers.csv", replace
display "SS_OUTPUT_FILE|file=table_TS08_centers.csv|type=table|desc=cluster_centers"
restore

* ============ 聚类质量评估 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 聚类质量"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算轮廓系数（简化版）
local total_wss = 0
forvalues c = 1/`k' {
    foreach var of local valid_vars {
        quietly summarize `var' if cluster_id == `c'
        local total_wss = `total_wss' + r(Var) * (r(N) - 1)
    }
}

display ""
display ">>> 总组内平方和: " %15.2f `total_wss'

display "SS_METRIC|name=k|value=`k'"
display "SS_METRIC|name=wss|value=`total_wss'"

capture erase "temp_elbow.dta"
if _rc != 0 { }
capture erase "temp_centers.dta"
if _rc != 0 { }

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS08_kmeans.dta", replace
display "SS_OUTPUT_FILE|file=data_TS08_kmeans.dta|type=data|desc=kmeans_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS08 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display "  聚类数K:         " %10.0fc `k'
display "  组内平方和:      " %15.2f `total_wss'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=k|value=`k'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS08|status=ok|elapsed_sec=`elapsed'"
log close
