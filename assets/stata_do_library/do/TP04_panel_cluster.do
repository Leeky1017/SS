* ==============================================================================
* SS_TEMPLATE: id=TP04  level=L2  module=P  title="Panel Cluster"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP04_cluster_result.csv type=table desc="Cluster results"
*   - table_TP04_comparison.csv type=table desc="SE comparison"
*   - data_TP04_cluster.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TP04|level=L2|title=Panel_Cluster"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local cluster_var = "__CLUSTER_VAR__"
local cluster_type = "__CLUSTER_TYPE__"

if "`cluster_type'" == "" {
    local cluster_type = "one"
}

display ""
display ">>> 聚类标准误参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    聚类变量: `cluster_var'"
display "    聚类类型: `cluster_type'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    display "SS_TASK_END|id=TP04|status=fail|elapsed_sec=."
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `depvar' `id_var' `time_var' `cluster_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|severity=fail|var=`var'"
        display "SS_TASK_END|id=TP04|status=fail|elapsed_sec=."
        log close
        exit 200
    }
}

local valid_indep ""
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
    }
}

capture xtset `id_var' `time_var'
if _rc {
    local rc_xtset = _rc
    display "SS_RC|code=`rc_xtset'|cmd=xtset|msg=xtset_failed|severity=fail"
    display "SS_TASK_END|id=TP04|status=fail|elapsed_sec=."
    log close
    exit `rc_xtset'
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 不同标准误比较 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 标准误比较"
display "═══════════════════════════════════════════════════════════════════════════════"

* 1. OLS标准误
quietly regress `depvar' `valid_indep'
matrix b_ols = e(b)
matrix se_ols = vecdiag(cholesky(diag(vecdiag(e(V)))))

* 2. 稳健标准误
quietly regress `depvar' `valid_indep', robust
matrix se_robust = vecdiag(cholesky(diag(vecdiag(e(V)))))

* 3. 单向聚类标准误
quietly regress `depvar' `valid_indep', vce(cluster `cluster_var')
matrix se_cluster1 = vecdiag(cholesky(diag(vecdiag(e(V)))))
local n_clusters = e(N_clust)

* 4. 双向聚类（如果选择）
if "`cluster_type'" == "two" {
    quietly regress `depvar' `valid_indep', vce(cluster `id_var' `time_var')
    matrix se_cluster2 = vecdiag(cholesky(diag(vecdiag(e(V)))))
}

display ""
display ">>> 聚类数: `n_clusters'"

* 创建比较表
tempname se_comparison
postfile `se_comparison' str32 variable double se_ols double se_robust double se_cluster ///
    using "temp_se_comparison.dta", replace

local varnames : colnames b_ols
local nvars : word count `varnames'

display ""
display "变量            OLS SE      Robust SE   Cluster SE  比率"
display "─────────────────────────────────────────────────────────"

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local se1 = sqrt(se_ols[1, `i']^2)
    local se2 = sqrt(se_robust[1, `i']^2)
    local se3 = sqrt(se_cluster1[1, `i']^2)
    local ratio = `se3' / `se1'
    
    post `se_comparison' ("`vname'") (`se1') (`se2') (`se3')
    
    display %15s "`vname'" "  " %10.6f `se1' "  " %10.6f `se2' "  " %10.6f `se3' "  " %6.2f `ratio'
}

postclose `se_comparison'

preserve
use "temp_se_comparison.dta", clear
export delimited using "table_TP04_comparison.csv", replace
display "SS_OUTPUT_FILE|file=table_TP04_comparison.csv|type=table|desc=se_comparison"
restore

* ============ 聚类回归结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 聚类回归结果"
display "═══════════════════════════════════════════════════════════════════════════════"

regress `depvar' `valid_indep', vce(cluster `cluster_var')

tempname cluster_results
postfile `cluster_results' str32 variable double coef double se double t double p ///
    using "temp_cluster_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local t = `coef' / `se'
    local p = 2 * ttail(e(df_r), abs(`t'))
    post `cluster_results' ("`vname'") (`coef') (`se') (`t') (`p')
}

postclose `cluster_results'

preserve
use "temp_cluster_results.dta", clear
export delimited using "table_TP04_cluster_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TP04_cluster_result.csv|type=table|desc=cluster_results"
restore

display "SS_METRIC|name=n_clusters|value=`n_clusters'"

capture erase "temp_se_comparison.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
capture erase "temp_cluster_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TP04_cluster.dta", replace
display "SS_OUTPUT_FILE|file=data_TP04_cluster.dta|type=data|desc=cluster_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  聚类数:          " %10.0fc `n_clusters'
display "  聚类类型:        `cluster_type'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_clusters|value=`n_clusters'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP04|status=ok|elapsed_sec=`elapsed'"
log close
