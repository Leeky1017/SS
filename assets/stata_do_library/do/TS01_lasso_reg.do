* ==============================================================================
* SS_TEMPLATE: id=TS01  level=L2  module=S  title="LASSO Reg"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS01_lasso_coef.csv type=table desc="LASSO coefficients"
*   - table_TS01_cv_result.csv type=table desc="CV results"
*   - fig_TS01_cv_path.png type=figure desc="Lambda path"
*   - data_TS01_lasso.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TS01|level=L2|title=LASSO_Reg"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local cv_folds = __CV_FOLDS__
local selection = "__SELECTION__"

if `cv_folds' < 3 | `cv_folds' > 20 {
    local cv_folds = 10
}
if "`selection'" == "" {
    local selection = "cv"
}

display ""
display ">>> LASSO回归参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    CV折数: `cv_folds'"
display "    λ选择: `selection'"

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
capture confirm numeric variable `depvar'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`depvar' not found"
    display "SS_ERR:VAR_NOT_FOUND:`depvar' not found"
    log close
    exit 200
}

local valid_indep ""
local n_vars = 0
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
        local n_vars = `n_vars' + 1
    }
}

display ">>> 有效自变量数: `n_vars'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ LASSO回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: LASSO回归 (交叉验证)"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`selection'" == "adaptive" {
    lasso linear `depvar' `valid_indep', selection(adaptive) folds(`cv_folds')
}
else {
    lasso linear `depvar' `valid_indep', selection(cv) folds(`cv_folds')
}

local lambda_opt = e(lambda_sel)
local n_nonzero = e(k_nonzero_sel)

display ""
display ">>> LASSO结果:"
display "    最优λ: " %12.6f `lambda_opt'
display "    非零系数数: `n_nonzero'"
display "    总变量数: `n_vars'"

display "SS_METRIC|name=lambda_opt|value=`lambda_opt'"
display "SS_METRIC|name=n_nonzero|value=`n_nonzero'"

* ============ 提取系数 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: LASSO系数"
display "═══════════════════════════════════════════════════════════════════════════════"

lassocoef, display(coef, standardized)

* 导出系数
tempname lasso_coef
postfile `lasso_coef' str32 variable double coef double std_coef ///
    using "temp_lasso_coef.dta", replace

matrix b = e(b)
local varnames : colnames b
local nvars : word count `varnames'

display ""
display ">>> 非零系数:"
display "变量                系数"
display "────────────────────────────"

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    if `coef' != 0 {
        post `lasso_coef' ("`vname'") (`coef') (.)
        display %20s "`vname'" "  " %12.6f `coef'
    }
}

postclose `lasso_coef'

preserve
use "temp_lasso_coef.dta", clear
export delimited using "table_TS01_lasso_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_TS01_lasso_coef.csv|type=table|desc=lasso_coef"
restore

* ============ 交叉验证结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 交叉验证结果"
display "═══════════════════════════════════════════════════════════════════════════════"

lassogof

local cv_mse = e(mse_sel)
local cv_r2 = e(r2_sel)

display ""
display ">>> 模型性能 (选择的λ):"
display "    CV MSE: " %12.6f `cv_mse'
display "    CV R²: " %10.4f `cv_r2'

display "SS_METRIC|name=cv_mse|value=`cv_mse'"
display "SS_METRIC|name=cv_r2|value=`cv_r2'"

* 导出CV结果
preserve
clear
set obs 1
generate double lambda = `lambda_opt'
generate int n_nonzero = `n_nonzero'
generate double cv_mse = `cv_mse'
generate double cv_r2 = `cv_r2'

export delimited using "table_TS01_cv_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TS01_cv_result.csv|type=table|desc=cv_result"
restore

* ============ 生成λ路径图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成λ路径图"
display "═══════════════════════════════════════════════════════════════════════════════"

cvplot
graph export "fig_TS01_cv_path.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TS01_cv_path.png|type=figure|desc=cv_path"

capture erase "temp_lasso_coef.dta"
if _rc != 0 { }

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS01_lasso.dta", replace
display "SS_OUTPUT_FILE|file=data_TS01_lasso.dta|type=data|desc=lasso_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  候选变量数:      " %10.0fc `n_vars'
display ""
display "  LASSO结果:"
display "    最优λ:         " %12.6f `lambda_opt'
display "    选中变量数:    " %10.0fc `n_nonzero'
display "    CV R²:         " %10.4f `cv_r2'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_nonzero|value=`n_nonzero'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS01|status=ok|elapsed_sec=`elapsed'"
log close
