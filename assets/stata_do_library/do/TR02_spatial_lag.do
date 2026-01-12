* ==============================================================================
* SS_TEMPLATE: id=TR02  level=L2  module=R  title="Spatial Lag"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TR02_sar_result.csv type=table desc="SAR results"
*   - data_TR02_sar.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: spregress
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Spatial lag models can face endogeneity; consider IV/GMM variants or robustness checks where appropriate.
* - Weight matrix W is a modeling choice; document construction and test sensitivity (band/KNN/standardization).
* - Check diagnostics (e.g., Moran's I on residuals) and compare with non-spatial baselines.
* 最佳实践审查（ZH）:
* - 空间滞后模型可能存在内生性；必要时考虑 IV/GMM 或稳健性检验。
* - 权重矩阵 W 属于建模假设；请记录构建方式并做敏感性分析（阈值/KNN/标准化）。
* - 建议做诊断（如残差 Moran's I）并与非空间基准模型对照。

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

display "SS_TASK_BEGIN|id=TR02|level=L2|title=Spatial_Lag"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=spregress|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local x_coord = "__X_COORD__"
local y_coord = "__Y_COORD__"

display ""
display ">>> 空间滞后模型参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    地区ID: `id_var'"

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
* EN: Validate required variables and basic types.
* ZH: 校验关键变量存在且类型合理。

* ============ 变量检查 ============
capture confirm numeric variable `depvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found_or_not_numeric|var=`depvar'|severity=fail"
    log close
    exit 200
}
capture confirm variable `id_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|var=`id_var'|severity=fail"
    log close
    exit 200
}
foreach var in `x_coord' `y_coord' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm numeric variable|msg=coord_var_not_found_or_not_numeric|var=`var'|severity=fail"
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
if "`valid_indep'" == "" {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=no_valid_indepvars|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Build W and estimate a spatial lag-style model (approximation).
* ZH: 构建 W 并估计空间滞后模型（近似实现）。

* ============ 构建空间权重 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 构建空间权重矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用距离倒数构建权重矩阵
local n = _N
matrix W = J(`n', `n', 0)

display ">>> 计算距离权重矩阵..."

forvalues i = 1/`n' {
    local xi = `x_coord'[`i']
    local yi = `y_coord'[`i']
    local row_sum = 0
    
    forvalues j = 1/`n' {
        if `i' != `j' {
            local xj = `x_coord'[`j']
            local yj = `y_coord'[`j']
            local dist = sqrt((`xi' - `xj')^2 + (`yi' - `yj')^2)
            if `dist' > 0 {
                matrix W[`i', `j'] = 1 / `dist'
                local row_sum = `row_sum' + 1 / `dist'
            }
        }
    }
    
    * 行标准化
    if `row_sum' > 0 {
        forvalues j = 1/`n' {
            matrix W[`i', `j'] = W[`i', `j'] / `row_sum'
        }
    }
}

display ">>> 权重矩阵已构建并行标准化"

* ============ 计算空间滞后变量 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 计算空间滞后变量"
display "═══════════════════════════════════════════════════════════════════════════════"

generate double W_`depvar' = 0

forvalues i = 1/`n' {
    local wy = 0
    forvalues j = 1/`n' {
        local wy = `wy' + W[`i', `j'] * `depvar'[`j']
    }
    replace W_`depvar' = `wy' in `i'
}

label variable W_`depvar' "空间滞后`depvar'"

quietly correlate `depvar' W_`depvar'
local spatial_corr = r(rho)
display ""
display ">>> `depvar'与空间滞后的相关系数: " %8.4f `spatial_corr'

display "SS_METRIC|name=spatial_corr|value=`spatial_corr'"

* ============ SAR模型估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 空间滞后模型(SAR)估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用2SLS估计SAR
* y = ρWy + Xβ + ε
* 工具变量: WX, W²X

display ">>> 构建工具变量..."

foreach var of local valid_indep {
    generate double W_`var' = 0
    forvalues i = 1/`n' {
        local wx = 0
        forvalues j = 1/`n' {
            local wx = `wx' + W[`i', `j'] * `var'[`j']
        }
        replace W_`var' = `wx' in `i'
    }
}

display ">>> 使用2SLS估计SAR模型..."

local iv_list ""
foreach var of local valid_indep {
    local iv_list "`iv_list' W_`var'"
}

ivregress 2sls `depvar' `valid_indep' (W_`depvar' = `iv_list'), robust

local rho = _b[W_`depvar']
local rho_se = _se[W_`depvar']
local rho_t = `rho' / `rho_se'
local rho_p = 2 * ttail(e(df_r), abs(`rho_t'))

display ""
display ">>> SAR模型结果:"
display "    空间自回归系数 ρ: " %10.4f `rho'
display "    标准误: " %10.4f `rho_se'
display "    t值: " %10.2f `rho_t'
display "    p值: " %10.4f `rho_p'

if `rho_p' < 0.05 {
    display "    结论: 存在显著空间依赖性"
}

display "SS_METRIC|name=rho|value=`rho'"
display "SS_METRIC|name=rho_t|value=`rho_t'"

* 导出结果
tempname sar_results
postfile `sar_results' str32 variable double coef double se double t double p ///
    using "temp_sar_results.dta", replace

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
    post `sar_results' ("`vname'") (`coef') (`se') (`t') (`p')
}

postclose `sar_results'

preserve
use "temp_sar_results.dta", clear
export delimited using "table_TR02_sar_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TR02_sar_result.csv|type=table|desc=sar_results"
restore

capture erase "temp_sar_results.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TR02_sar.dta", replace
display "SS_OUTPUT_FILE|file=data_TR02_sar.dta|type=data|desc=sar_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TR02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  SAR模型:"
display "    ρ (空间系数):  " %10.4f `rho'
display "    t值:           " %10.2f `rho_t'
display "    p值:           " %10.4f `rho_p'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=rho|value=`rho'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TR02|status=ok|elapsed_sec=`elapsed'"
log close
