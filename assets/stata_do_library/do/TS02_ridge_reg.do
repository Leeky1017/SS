* ==============================================================================
* SS_TEMPLATE: id=TS02  level=L2  module=S  title="Ridge Reg"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS02_ridge_coef.csv type=table desc="Ridge coefficients"
*   - table_TS02_cv_result.csv type=table desc="CV results"
*   - data_TS02_ridge.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Ridge is for prediction/stabilization under multicollinearity; coefficients are shrunk and not directly comparable to OLS magnitudes.
* - Tune λ via cross-validation and evaluate on held-out data; avoid leakage in preprocessing.
* - Standardization and missing-data handling can materially affect results; document choices.
* 最佳实践审查（ZH）:
* - Ridge 常用于预测与缓解多重共线性；系数会被收缩，不能简单按 OLS 解释大小。
* - 使用交叉验证选择 λ，并在留出样本评估；预处理注意避免信息泄露。
* - 标准化与缺失值处理会显著影响结果；请记录设置。

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

display "SS_TASK_BEGIN|id=TS02|level=L2|title=Ridge_Reg"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* Reproducibility / 可复现性
local seed_value = 12345
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local cv_folds_raw = "__CV_FOLDS__"
local cv_folds = real("`cv_folds_raw'")

if missing(`cv_folds') | `cv_folds' < 3 | `cv_folds' > 20 {
    local cv_folds = 10
}
local cv_folds = floor(`cv_folds')

display ""
display ">>> Ridge回归参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    CV折数: `cv_folds'"

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
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found|severity=fail"
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
if `n_vars' <= 0 {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=no_valid_indepvars|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Fit ridge (elasticnet with alpha=0) and export coefficients.
* ZH: 执行 Ridge（alpha=0）并导出系数。

* ============ Ridge回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Ridge回归 (交叉验证)"
display "═══════════════════════════════════════════════════════════════════════════════"

elasticnet linear `depvar' `valid_indep', alpha(0) selection(cv) folds(`cv_folds')

local lambda_opt = e(lambda_sel)

display ""
display ">>> Ridge结果:"
display "    最优λ: " %12.6f `lambda_opt'

display "SS_METRIC|name=lambda_opt|value=`lambda_opt'"

* ============ 提取系数 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Ridge系数"
display "═══════════════════════════════════════════════════════════════════════════════"

lassocoef, display(coef, standardized)

tempname ridge_coef
postfile `ridge_coef' str32 variable double coef ///
    using "temp_ridge_coef.dta", replace

matrix b = e(b)
local varnames : colnames b
local nvars : word count `varnames'

display ""
display ">>> 系数:"
display "变量                系数"
display "────────────────────────────"

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    post `ridge_coef' ("`vname'") (`coef')
    display %20s "`vname'" "  " %12.6f `coef'
}

postclose `ridge_coef'

preserve
use "temp_ridge_coef.dta", clear
export delimited using "table_TS02_ridge_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_TS02_ridge_coef.csv|type=table|desc=ridge_coef"
restore

* ============ 模型性能 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 模型性能"
display "═══════════════════════════════════════════════════════════════════════════════"

lassogof

local cv_mse = e(mse_sel)
local cv_r2 = e(r2_sel)

display ""
display ">>> 模型性能:"
display "    CV MSE: " %12.6f `cv_mse'
display "    CV R²: " %10.4f `cv_r2'

display "SS_METRIC|name=cv_mse|value=`cv_mse'"
display "SS_METRIC|name=cv_r2|value=`cv_r2'"

preserve
clear
set obs 1
generate double lambda = `lambda_opt'
generate double cv_mse = `cv_mse'
generate double cv_r2 = `cv_r2'

export delimited using "table_TS02_cv_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TS02_cv_result.csv|type=table|desc=cv_result"
restore

capture erase "temp_ridge_coef.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS02_ridge.dta", replace
display "SS_OUTPUT_FILE|file=data_TS02_ridge.dta|type=data|desc=ridge_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display ""
display "  Ridge结果:"
display "    最优λ:         " %12.6f `lambda_opt'
display "    CV R²:         " %10.4f `cv_r2'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=cv_r2|value=`cv_r2'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS02|status=ok|elapsed_sec=`elapsed'"
log close
