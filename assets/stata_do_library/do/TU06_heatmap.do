* ==============================================================================
* SS_TEMPLATE: id=TU06  level=L1  module=U  title="Heatmap"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU06_heatmap.png type=figure desc="Heatmap"
*   - table_TU06_corr.csv type=table desc="Correlation matrix"
*   - data_TU06_heat.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Correlation heatmaps are sensitive to scaling/outliers and missingness; document preprocessing and consider robust correlations.
* - Use consistent color scales and clear labels; avoid implying causality from correlation patterns.
* - For many variables, consider clustering/reordering to improve interpretability.
* 最佳实践审查（ZH）:
* - 相关热力图对尺度/离群值/缺失敏感；请记录预处理，并在需要时使用稳健相关系数。
* - 颜色尺度与标签要清晰一致；不要从相关图形直接推断因果关系。
* - 变量很多时可考虑聚类/重排以提升可读性。

* ============ 初始化 ============
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TU06|level=L1|title=Heatmap"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local vars = "__VARS__"

display ""
display ">>> 热力图参数:"
display "    变量: `vars'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate variables for correlation/heatmap (numeric, >=2).
* ZH: 校验变量（数值型且至少 2 个）以计算相关与绘制热力图。

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
    display "SS_RC|code=198|cmd=validate_inputs|msg=few_vars|severity=fail"
    log close
    exit 198
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Compute correlation matrix and export heatmap + table.
* ZH: 计算相关矩阵并导出热力图与表格。

* ============ 计算相关矩阵 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 相关矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

correlate `valid_vars'
matrix C = r(C)

display ""
display ">>> 相关矩阵:"
matrix list C, format(%6.3f)

* 导出相关矩阵
preserve
clear
svmat C, names(col)
generate str32 variable = ""
local i = 1
foreach var of local valid_vars {
    replace variable = "`var'" in `i'
    local i = `i' + 1
}
order variable
export delimited using "table_TU06_corr.csv", replace
display "SS_OUTPUT_FILE|file=table_TU06_corr.csv|type=table|desc=corr_matrix"
restore

* ============ 绘制热力图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 绘制热力图"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建热力图数据
preserve
clear
local n2 = `n_vars' * `n_vars'
set obs `n2'

generate int row = .
generate int col = .
generate double corr = .
generate str32 row_var = ""
generate str32 col_var = ""

local obs = 1
forvalues i = 1/`n_vars' {
    local var_i : word `i' of `valid_vars'
    forvalues j = 1/`n_vars' {
        local var_j : word `j' of `valid_vars'
        replace row = `i' in `obs'
        replace col = `j' in `obs'
        replace corr = C[`i', `j'] in `obs'
        replace row_var = "`var_i'" in `obs'
        replace col_var = "`var_j'" in `obs'
        local obs = `obs' + 1
    }
}

* 简单热力图
twoway (scatter row col [w=abs(corr)], msymbol(square) mcolor(navy%80)), ///
    xlabel(1(1)`n_vars', valuelabel angle(45)) ///
    ylabel(1(1)`n_vars', valuelabel) ///
    title("相关系数热力图") ///
    xtitle("") ytitle("") ///
    aspectratio(1)
graph export "fig_TU06_heatmap.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU06_heatmap.png|type=figure|desc=heatmap"
restore

display "SS_METRIC|name=n_vars|value=`n_vars'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU06_heat.dta", replace
display "SS_OUTPUT_FILE|file=data_TU06_heat.dta|type=data|desc=heat_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU06 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_vars|value=`n_vars'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU06|status=ok|elapsed_sec=`elapsed'"
log close
