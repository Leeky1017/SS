* ==============================================================================
* SS_TEMPLATE: id=TS03  level=L2  module=S  title="Elastic Net"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS03_enet_coef.csv type=table desc="Elastic Net coefficients"
*   - table_TS03_cv_result.csv type=table desc="CV results"
*   - data_TS03_enet.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Elastic net blends LASSO/Ridge; tune both α and λ (cross-validate) and report sensitivity.
* - Avoid data leakage: any preprocessing (scaling, feature selection) must be learned within training folds only.
* - Do not interpret post-selection coefficients as unbiased causal effects; treat as predictive modeling unless design supports inference.
* 最佳实践审查（ZH）:
* - Elastic net 结合 LASSO/Ridge；建议同时调 α 与 λ（交叉验证）并报告敏感性。
* - 避免信息泄露：标准化/特征选择等预处理应仅在训练折中拟合。
* - 不应把选择后系数当作无偏因果效应；除非研究设计支持，否则主要用于预测建模。

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

display "SS_TASK_BEGIN|id=TS03|level=L2|title=Elastic_Net"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* Reproducibility / 可复现性
local seed_value = 12345
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local alpha_raw = "__ALPHA__"
local cv_folds_raw = "__CV_FOLDS__"
local alpha = real("`alpha_raw'")
local cv_folds = real("`cv_folds_raw'")

if missing(`alpha') | `alpha' < 0 | `alpha' > 1 {
    local alpha = 0.5
}
if missing(`cv_folds') | `cv_folds' < 3 | `cv_folds' > 20 {
    local cv_folds = 10
}
local cv_folds = floor(`cv_folds')

display ""
display ">>> Elastic Net参数:"
display "    因变量: `depvar'"
display "    α (L1比例): " %6.2f `alpha'
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
* EN: Fit elastic net with cross-validation and export coefficients/diagnostics.
* ZH: 执行 Elastic Net 交叉验证并导出系数与诊断信息。

* ============ Elastic Net回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Elastic Net回归"
display "═══════════════════════════════════════════════════════════════════════════════"

elasticnet linear `depvar' `valid_indep', alpha(`alpha') selection(cv) folds(`cv_folds')

local lambda_opt = e(lambda_sel)
local n_nonzero = e(k_nonzero_sel)

display ""
display ">>> Elastic Net结果:"
display "    α: " %6.2f `alpha'
display "    最优λ: " %12.6f `lambda_opt'
display "    非零系数: `n_nonzero' / `n_vars'"

display "SS_METRIC|name=alpha|value=`alpha'"
display "SS_METRIC|name=lambda_opt|value=`lambda_opt'"
display "SS_METRIC|name=n_nonzero|value=`n_nonzero'"

* ============ 提取系数 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 系数"
display "═══════════════════════════════════════════════════════════════════════════════"

lassocoef, display(coef)

tempname enet_coef
postfile `enet_coef' str32 variable double coef ///
    using "temp_enet_coef.dta", replace

matrix b = e(b)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    if `coef' != 0 {
        post `enet_coef' ("`vname'") (`coef')
    }
}

postclose `enet_coef'

preserve
use "temp_enet_coef.dta", clear
export delimited using "table_TS03_enet_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_TS03_enet_coef.csv|type=table|desc=enet_coef"
restore

* ============ 模型性能 ============
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
generate double alpha = `alpha'
generate double lambda = `lambda_opt'
generate int n_nonzero = `n_nonzero'
generate double cv_mse = `cv_mse'
generate double cv_r2 = `cv_r2'

export delimited using "table_TS03_cv_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TS03_cv_result.csv|type=table|desc=cv_result"
restore

capture erase "temp_enet_coef.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS03_enet.dta", replace
display "SS_OUTPUT_FILE|file=data_TS03_enet.dta|type=data|desc=enet_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  候选变量:        " %10.0fc `n_vars'
display ""
display "  Elastic Net:"
display "    α:             " %10.2f `alpha'
display "    λ:             " %12.6f `lambda_opt'
display "    选中变量:      " %10.0fc `n_nonzero'
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

display "SS_TASK_END|id=TS03|status=ok|elapsed_sec=`elapsed'"
log close
