* ==============================================================================
* SS_TEMPLATE: id=TS07  level=L2  module=S  title="PCA Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS07_eigenvalues.csv type=table desc="Eigenvalues"
*   - table_TS07_loadings.csv type=table desc="Loadings"
*   - fig_TS07_scree.png type=figure desc="Scree plot"
*   - data_TS07_pca.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TS07|level=L2|title=PCA_Analysis"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local vars = "__VARS__"
local n_components = __N_COMPONENTS__

display ""
display ">>> PCA参数:"
display "    分析变量: `vars'"

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

if `n_vars' < 2 {
    display "SS_ERROR:FEW_VARS:Need at least 2 variables"
    display "SS_ERR:FEW_VARS:Need at least 2 variables"
    log close
    exit 198
}

display ">>> 有效变量数: `n_vars'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ PCA分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 主成分分析"
display "═══════════════════════════════════════════════════════════════════════════════"

pca `valid_vars'

* 提取特征值
matrix eigenvalues = e(Ev)
local n_pc = colsof(eigenvalues)

display ""
display ">>> 特征值和解释方差:"
display "PC    特征值      方差占比    累计占比"
display "─────────────────────────────────────────"

local total_var = 0
forvalues i = 1/`n_pc' {
    local total_var = `total_var' + eigenvalues[1, `i']
}

tempname eigen_results
postfile `eigen_results' int pc double eigenvalue double var_prop double cum_prop ///
    using "temp_eigenvalues.dta", replace

local cum_prop = 0
local n_retain = 0

forvalues i = 1/`n_pc' {
    local ev = eigenvalues[1, `i']
    local prop = `ev' / `total_var'
    local cum_prop = `cum_prop' + `prop'
    
    post `eigen_results' (`i') (`ev') (`prop') (`cum_prop')
    
    display %4.0f `i' "   " %10.4f `ev' "    " %8.4f `prop' "      " %8.4f `cum_prop'
    
    * Kaiser准则：特征值>1
    if `ev' > 1 & `n_retain' == `i' - 1 {
        local n_retain = `i'
    }
}

postclose `eigen_results'

if `n_components' > 0 & `n_components' <= `n_pc' {
    local n_retain = `n_components'
}

display ""
display ">>> 建议保留主成分数 (Kaiser准则): `n_retain'"

display "SS_METRIC|name=n_components|value=`n_retain'"

preserve
use "temp_eigenvalues.dta", clear
export delimited using "table_TS07_eigenvalues.csv", replace
display "SS_OUTPUT_FILE|file=table_TS07_eigenvalues.csv|type=table|desc=eigenvalues"
restore

* ============ 载荷矩阵 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 成分载荷"
display "═══════════════════════════════════════════════════════════════════════════════"

matrix loadings = e(L)

tempname load_results
postfile `load_results' str32 variable double pc1 double pc2 double pc3 ///
    using "temp_loadings.dta", replace

forvalues i = 1/`n_vars' {
    local vname : word `i' of `valid_vars'
    local l1 = loadings[`i', 1]
    local l2 = cond(`n_pc' >= 2, loadings[`i', 2], .)
    local l3 = cond(`n_pc' >= 3, loadings[`i', 3], .)
    post `load_results' ("`vname'") (`l1') (`l2') (`l3')
}

postclose `load_results'

preserve
use "temp_loadings.dta", clear
display ""
display ">>> 前3个主成分载荷:"
list, noobs
export delimited using "table_TS07_loadings.csv", replace
display "SS_OUTPUT_FILE|file=table_TS07_loadings.csv|type=table|desc=loadings"
restore

* ============ 生成主成分得分 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成主成分得分"
display "═══════════════════════════════════════════════════════════════════════════════"

predict pc1 pc2 pc3, score

display ">>> 已生成PC1-PC3得分"

quietly summarize pc1
display "    PC1: 均值=" %8.4f r(mean) ", SD=" %8.4f r(sd)

* ============ 生成碎石图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成碎石图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_eigenvalues.dta", clear

twoway (connected eigenvalue pc, mcolor(navy) lcolor(navy)) ///
       (scatter eigenvalue pc if eigenvalue > 1, mcolor(red) msize(large)), ///
       yline(1, lcolor(gray) lpattern(dash)) ///
       xtitle("主成分") ytitle("特征值") ///
       title("PCA碎石图") ///
       note("红点=特征值>1 (Kaiser准则)") ///
       legend(off)
graph export "fig_TS07_scree.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TS07_scree.png|type=figure|desc=scree_plot"
restore

capture erase "temp_eigenvalues.dta"
if _rc != 0 { }
capture erase "temp_loadings.dta"
if _rc != 0 { }

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS07_pca.dta", replace
display "SS_OUTPUT_FILE|file=data_TS07_pca.dta|type=data|desc=pca_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS07 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  原始变量数:      " %10.0fc `n_vars'
display "  建议保留PC:      " %10.0fc `n_retain'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_components|value=`n_retain'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS07|status=ok|elapsed_sec=`elapsed'"
log close
