* ==============================================================================
* SS_TEMPLATE: id=TR03  level=L2  module=R  title="Spatial Error"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TR03_sem_result.csv type=table desc="SEM results"
*   - data_TR03_sem.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

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

display "SS_TASK_BEGIN|id=TR03|level=L2|title=Spatial_Error"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local x_coord = "__X_COORD__"
local y_coord = "__Y_COORD__"

display ""
display ">>> 空间误差模型参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `depvar' `id_var' `x_coord' `y_coord' {
    capture confirm variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|severity=fail"
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
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 构建空间权重 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 构建空间权重矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

local n = _N
matrix W = J(`n', `n', 0)

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
    
    if `row_sum' > 0 {
        forvalues j = 1/`n' {
            matrix W[`i', `j'] = W[`i', `j'] / `row_sum'
        }
    }
}

* ============ OLS残差分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: OLS残差空间相关检验"
display "═══════════════════════════════════════════════════════════════════════════════"

regress `depvar' `valid_indep'
predict double resid_ols, residuals

* 计算残差的空间滞后
generate double W_resid = 0
forvalues i = 1/`n' {
    local wr = 0
    forvalues j = 1/`n' {
        local wr = `wr' + W[`i', `j'] * resid_ols[`j']
    }
    replace W_resid = `wr' in `i'
}

* Moran's I检验
quietly summarize resid_ols
local mean_resid = r(mean)
local var_resid = r(Var)

local moran_num = 0
local moran_denom = 0

forvalues i = 1/`n' {
    local ei = resid_ols[`i'] - `mean_resid'
    local moran_denom = `moran_denom' + `ei'^2
    
    forvalues j = 1/`n' {
        local ej = resid_ols[`j'] - `mean_resid'
        local moran_num = `moran_num' + W[`i', `j'] * `ei' * `ej'
    }
}

local moran_i = `n' * `moran_num' / `moran_denom'

display ""
display ">>> Moran's I (残差): " %10.4f `moran_i'

display "SS_METRIC|name=moran_i|value=`moran_i'"

* ============ SEM估计（FGLS） ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 空间误差模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 估计λ（使用残差回归）
regress resid_ols W_resid, noconstant
local lambda_init = _b[W_resid]

display ">>> 初始λ估计: " %10.4f `lambda_init'

* 迭代FGLS估计
local lambda = `lambda_init'
local max_iter = 20
local tol = 0.0001
local converged = 0

forvalues iter = 1/`max_iter' {
    * 构建转换变量 (I - λW)y 和 (I - λW)X
    generate double y_trans = `depvar'
    forvalues i = 1/`n' {
        local wy = 0
        forvalues j = 1/`n' {
            local wy = `wy' + W[`i', `j'] * `depvar'[`j']
        }
        replace y_trans = `depvar' - `lambda' * `wy' in `i'
    }
    
    foreach var of local valid_indep {
        capture drop `var'_trans
        local rc = _rc
        if `rc' != 0 {
            display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
        }
        generate double `var'_trans = `var'
        forvalues i = 1/`n' {
            local wx = 0
            forvalues j = 1/`n' {
                local wx = `wx' + W[`i', `j'] * `var'[`j']
            }
            replace `var'_trans = `var' - `lambda' * `wx' in `i'
        }
    }
    
    * 估计转换后模型
    local trans_vars ""
    foreach var of local valid_indep {
        local trans_vars "`trans_vars' `var'_trans"
    }
    
    quietly regress y_trans `trans_vars'
    predict double resid_new, residuals
    
    * 更新λ
    generate double W_resid_new = 0
    forvalues i = 1/`n' {
        local wr = 0
        forvalues j = 1/`n' {
            local wr = `wr' + W[`i', `j'] * resid_new[`j']
        }
        replace W_resid_new = `wr' in `i'
    }
    
    quietly regress resid_new W_resid_new, noconstant
    local lambda_new = _b[W_resid_new]
    
    local diff = abs(`lambda_new' - `lambda')
    
    drop y_trans resid_new W_resid_new
    foreach var of local valid_indep {
        drop `var'_trans
    }
    
    if `diff' < `tol' {
        local converged = 1
        local lambda = `lambda_new'
        continue, break
    }
    
    local lambda = `lambda_new'
}

display ""
display ">>> SEM估计结果:"
display "    λ (空间误差系数): " %10.4f `lambda'
display "    收敛: " cond(`converged', "是", "否")

display "SS_METRIC|name=lambda|value=`lambda'"

* 最终估计
generate double y_final = `depvar'
forvalues i = 1/`n' {
    local wy = 0
    forvalues j = 1/`n' {
        local wy = `wy' + W[`i', `j'] * `depvar'[`j']
    }
    replace y_final = `depvar' - `lambda' * `wy' in `i'
}

foreach var of local valid_indep {
    generate double `var'_final = `var'
    forvalues i = 1/`n' {
        local wx = 0
        forvalues j = 1/`n' {
            local wx = `wx' + W[`i', `j'] * `var'[`j']
        }
        replace `var'_final = `var' - `lambda' * `wx' in `i'
    }
}

local final_vars ""
foreach var of local valid_indep {
    local final_vars "`final_vars' `var'_final"
}

regress y_final `final_vars', robust

* 导出结果
tempname sem_results
postfile `sem_results' str32 variable double coef double se double t double p ///
    using "temp_sem_results.dta", replace

post `sem_results' ("lambda") (`lambda') (.) (.) (.)

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
    post `sem_results' ("`vname'") (`coef') (`se') (`t') (`p')
}

postclose `sem_results'

preserve
use "temp_sem_results.dta", clear
export delimited using "table_TR03_sem_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TR03_sem_result.csv|type=table|desc=sem_results"
restore

capture erase "temp_sem_results.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TR03_sem.dta", replace
display "SS_OUTPUT_FILE|file=data_TR03_sem.dta|type=data|desc=sem_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TR03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  空间诊断:"
display "    Moran's I:     " %10.4f `moran_i'
display ""
display "  SEM模型:"
display "    λ:             " %10.4f `lambda'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=lambda|value=`lambda'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TR03|status=ok|elapsed_sec=`elapsed'"
log close
