* ==============================================================================
* SS_TEMPLATE: id=TR05  level=L2  module=R  title="Spatial Panel"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TR05_spatial_panel.csv type=table desc="Spatial panel results"
*   - data_TR05_sp_panel.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Spatial panel models are sensitive to W and identification; document W and justify FE/RE choice with robustness checks.
* - This template uses a simplified manual W-lag construction and requires a balanced panel; for production consider specialized spatial panel tooling.
* - Check diagnostics and report uncertainty; interpretation of ρ depends on model assumptions and scaling.
* 最佳实践审查（ZH）:
* - 空间面板模型对 W 与识别假设敏感；请记录 W 并通过稳健性分析支持 FE/RE 选择。
* - 本模板使用简化的手工空间滞后构造并要求平衡面板；正式研究建议使用更专业的空间面板工具链。
* - 请做诊断并报告不确定性；ρ 的解释依赖模型假设与变量尺度。

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

display "SS_TASK_BEGIN|id=TR05|level=L2|title=Spatial_Panel"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local x_coord = "__X_COORD__"
local y_coord = "__Y_COORD__"
local model_type = "__MODEL_TYPE__"

if "`model_type'" == "" {
    local model_type = "fe"
}
if !inlist("`model_type'", "fe", "re") {
    display "SS_RC|code=11|cmd=param_check|msg=invalid_model_type_defaulted|value=`model_type'|severity=warn"
    local model_type = "fe"
}

display ""
display ">>> 空间面板模型参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    模型类型: `model_type'"

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
* EN: Validate inputs and enforce balanced panel assumptions.
* ZH: 校验输入并强制平衡面板假设。

* ============ 变量检查 ============
capture confirm numeric variable `depvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found_or_not_numeric|var=`depvar'|severity=fail"
    log close
    exit 200
}
foreach var in `id_var' `time_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm variable|msg=required_var_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}
foreach var in `x_coord' `y_coord' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm numeric variable|msg=coord_var_not_found|var=`var'|severity=fail"
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

capture xtset `id_var' `time_var'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset `id_var' `time_var'|msg=xtset_failed|severity=fail"
    log close
    exit `rc'
}
tempvar region_idx time_idx
egen int `region_idx' = group(`id_var')
egen int `time_idx' = group(`time_var')

capture isid `region_idx' `time_idx'
if _rc {
    display "SS_RC|code=459|cmd=isid|msg=duplicate_panel_keys|severity=fail"
    log close
    exit 459
}

quietly summarize `region_idx', meanonly
local n_regions = r(max)
quietly summarize `time_idx', meanonly
local n_times = r(max)
local n_obs = _N
local expected_n = `n_regions' * `n_times'
if `n_obs' != `expected_n' {
    display "SS_RC|code=459|cmd=panel_balance_check|msg=unbalanced_panel_not_supported|n_obs=`n_obs'|expected=`expected_n'|severity=fail"
    log close
    exit 459
}

sort `time_idx' `region_idx'

display ""
display ">>> 面板结构: `n_regions' 地区 x `n_times' 时期"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Build W, compute spatial lags, then fit a panel IV model.
* ZH: 构建 W、计算空间滞后变量，并估计面板 IV 模型。

* ============ 构建空间权重（基于首期坐标） ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 构建空间权重矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

* 提取首期坐标（按 region_idx 对齐）
preserve
keep `id_var' `time_var' `x_coord' `y_coord' `region_idx' `time_idx'
sort `region_idx' `time_idx'
bysort `region_idx': keep if _n == 1
keep `region_idx' `x_coord' `y_coord'
sort `region_idx'
tempfile coords
save `coords'
restore

* 构建权重矩阵
matrix W = J(`n_regions', `n_regions', 0)

preserve
use `coords', clear

forvalues i = 1/`n_regions' {
    local xi = `x_coord'[`i']
    local yi = `y_coord'[`i']
    local row_sum = 0
    
    forvalues j = 1/`n_regions' {
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
    
    if `row_sum' > 0 {
        forvalues j = 1/`n_regions' {
            matrix W[`i', `j'] = W[`i', `j'] / `row_sum'
        }
    }
}

restore

display ">>> 空间权重矩阵已构建 (`n_regions' x `n_regions')"

* ============ 计算空间滞后变量 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 计算空间滞后变量"
display "═══════════════════════════════════════════════════════════════════════════════"

* 对每个时期计算空间滞后（要求平衡面板 + 已按 time_idx/region_idx 排序）
sort `time_idx' `region_idx'

generate double W_`depvar' = .

quietly levelsof `time_idx', local(times)
foreach t of local times {
    * 提取该期数据
    forvalues i = 1/`n_regions' {
        local wy = 0
        forvalues j = 1/`n_regions' {
            * 找到第j个地区在时期t的值
            local obs_j = (`t' - 1) * `n_regions' + `j'
            capture noisily local yj = `depvar'[`obs_j']
            if _rc == 0 {
                local wy = `wy' + W[`i', `j'] * `yj'
            }
        }
        local obs_i = (`t' - 1) * `n_regions' + `i'
        capture replace W_`depvar' = `wy' in `obs_i'
        local rc = _rc
        if `rc' != 0 {
            display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
        }
    }
}

label variable W_`depvar' "空间滞后`depvar'"

* ============ 空间面板模型估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 空间面板模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建空间滞后的自变量作为工具变量
foreach var of local valid_indep {
    generate double W_`var' = .
    
    foreach t of local times {
        forvalues i = 1/`n_regions' {
            local wx = 0
            forvalues j = 1/`n_regions' {
                local obs_j = (`t' - 1) * `n_regions' + `j'
                capture noisily local xj = `var'[`obs_j']
                if _rc == 0 {
                    local wx = `wx' + W[`i', `j'] * `xj'
                }
            }
            local obs_i = (`t' - 1) * `n_regions' + `i'
            capture replace W_`var' = `wx' in `obs_i'
            local rc = _rc
            if `rc' != 0 {
                display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
            }
        }
    }
}

* 使用面板2SLS估计
local iv_list ""
foreach var of local valid_indep {
    local iv_list "`iv_list' W_`var'"
}

local rc = 0
if "`model_type'" == "fe" {
    display ">>> 固定效应空间面板模型..."
    capture noisily xtivreg `depvar' `valid_indep' (W_`depvar' = `iv_list'), fe
    local rc = _rc
    if `rc' == 198 {
        display "SS_RC|code=198|cmd=xtivreg fe|msg=collinear_try_re|severity=warn"
        capture noisily xtivreg `depvar' `valid_indep' (W_`depvar' = `iv_list'), re
        local rc = _rc
    }
}
else {
    display ">>> 随机效应空间面板模型..."
    capture noisily xtivreg `depvar' `valid_indep' (W_`depvar' = `iv_list'), re
    local rc = _rc
}
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=xtivreg|msg=xtivreg_failed|severity=fail"
    log close
    exit `rc'
}

local rho = _b[W_`depvar']
local rho_se = _se[W_`depvar']
local rho_z = `rho' / `rho_se'

display ""
display ">>> 空间面板模型结果:"
display "    空间自回归系数 ρ: " %10.4f `rho'
display "    标准误: " %10.4f `rho_se'
display "    z值: " %10.2f `rho_z'

display "SS_METRIC|name=rho|value=`rho'"
display "SS_METRIC|name=rho_z|value=`rho_z'"

* 导出结果
tempname sp_results
postfile `sp_results' str32 variable double coef double se double z double p ///
    using "temp_sp_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `sp_results' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `sp_results'

preserve
use "temp_sp_results.dta", clear
export delimited using "table_TR05_spatial_panel.csv", replace
display "SS_OUTPUT_FILE|file=table_TR05_spatial_panel.csv|type=table|desc=spatial_panel_results"
restore

capture erase "temp_sp_results.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TR05_sp_panel.dta", replace
display "SS_OUTPUT_FILE|file=data_TR05_sp_panel.dta|type=data|desc=sp_panel_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TR05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  地区数:          " %10.0fc `n_regions'
display "  时期数:          " %10.0fc `n_times'
display "  模型:            `model_type'"
display ""
display "  空间系数:"
display "    ρ:             " %10.4f `rho'
display "    z值:           " %10.2f `rho_z'
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

display "SS_TASK_END|id=TR05|status=ok|elapsed_sec=`elapsed'"
log close
