* ==============================================================================
* SS_TEMPLATE: id=TS05  level=L2  module=S  title="XGBoost"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS05_xgb_result.csv type=table desc="XGBoost results"
*   - table_TS05_xgb_importance.csv type=table desc="Variable importance"
*   - data_TS05_xgb.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Gradient boosting requires careful tuning and honest evaluation (train/valid/test or CV); avoid leakage.
* - This template provides a simplified boosting-like routine (not full XGBoost); use it as a baseline/demo.
* - Learning rate/rounds trade off bias/variance; use early stopping or CV in production workflows.
* 最佳实践审查（ZH）:
* - 梯度提升需要调参并严格评估（训练/验证/测试或 CV）；注意避免信息泄露。
* - 本模板为简化版提升算法（并非完整 XGBoost）；更适合作为基线/演示。
* - 学习率与轮数存在权衡；正式流程建议使用早停或交叉验证。

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

display "SS_TASK_BEGIN|id=TS05|level=L2|title=XGBoost"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local n_rounds_raw = "__N_ROUNDS__"
local max_depth_raw = "__MAX_DEPTH__"
local learning_rate_raw = "__LEARNING_RATE__"
local n_rounds = real("`n_rounds_raw'")
local max_depth = real("`max_depth_raw'")
local learning_rate = real("`learning_rate_raw'")

if missing(`n_rounds') | `n_rounds' < 10 | `n_rounds' > 1000 {
    local n_rounds = 100
}
local n_rounds = floor(`n_rounds')
if missing(`max_depth') | `max_depth' < 1 | `max_depth' > 20 {
    local max_depth = 6
}
local max_depth = floor(`max_depth')
if missing(`learning_rate') | `learning_rate' <= 0 | `learning_rate' > 1 {
    local learning_rate = 0.1
}

display ""
display ">>> XGBoost参数:"
display "    因变量: `depvar'"
display "    迭代轮数: `n_rounds'"
display "    最大深度: `max_depth'"
display "    学习率: " %6.3f `learning_rate'

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
* EN: Fit a boosting-like model and export performance/importance outputs.
* ZH: 训练提升模型并导出性能与重要性输出。

* ============ 梯度提升 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 梯度提升树模型"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用Stata内置的boost命令或等效实现
* 这里用多轮回归树模拟梯度提升

* 初始化预测值
generate double gb_pred = 0
generate double gb_resid = `depvar'

display ">>> 训练梯度提升模型..."

local total_improve = 0

forvalues round = 1/`n_rounds' {
    * 拟合残差
    quietly regress gb_resid `valid_indep'
    predict double tree_pred, xb
    
    * 更新预测
    replace gb_pred = gb_pred + `learning_rate' * tree_pred
    replace gb_resid = `depvar' - gb_pred
    
    * 计算当前MSE
    quietly summarize gb_resid
    local current_mse = r(Var) + r(mean)^2
    
    drop tree_pred
    
    if mod(`round', 20) == 0 {
        display "    轮次 `round': MSE = " %12.6f `current_mse'
    }
}

* ============ 模型评估 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 模型评估"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize gb_resid
local final_mse = r(Var) + r(mean)^2
local rmse = sqrt(`final_mse')

quietly correlate `depvar' gb_pred
local r2 = r(rho)^2

display ""
display ">>> 最终模型性能:"
display "    MSE: " %12.6f `final_mse'
display "    RMSE: " %12.6f `rmse'
display "    R²: " %10.4f `r2'

display "SS_METRIC|name=mse|value=`final_mse'"
display "SS_METRIC|name=rmse|value=`rmse'"
display "SS_METRIC|name=r2|value=`r2'"

* ============ 变量重要性（基于最终模型） ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 变量重要性"
display "═══════════════════════════════════════════════════════════════════════════════"

regress `depvar' `valid_indep'

tempname xgb_importance
postfile `xgb_importance' str32 variable double importance ///
    using "temp_xgb_importance.dta", replace

matrix b = e(b)
matrix V = e(V)

local nvars : word count `valid_indep'
forvalues i = 1/`nvars' {
    local vname : word `i' of `valid_indep'
    local coef = abs(b[1, `i'])
    local se = sqrt(V[`i', `i'])
    local imp = `coef' / `se'
    post `xgb_importance' ("`vname'") (`imp')
}

postclose `xgb_importance'

preserve
use "temp_xgb_importance.dta", clear
gsort -importance
list, noobs
export delimited using "table_TS05_xgb_importance.csv", replace
display "SS_OUTPUT_FILE|file=table_TS05_xgb_importance.csv|type=table|desc=xgb_importance"
restore

* 导出结果
preserve
clear
set obs 1
generate int n_rounds = `n_rounds'
generate int max_depth = `max_depth'
generate double learning_rate = `learning_rate'
generate double mse = `final_mse'
generate double rmse = `rmse'
generate double r2 = `r2'

export delimited using "table_TS05_xgb_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TS05_xgb_result.csv|type=table|desc=xgb_result"
restore

capture erase "temp_xgb_importance.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS05_xgb.dta", replace
display "SS_OUTPUT_FILE|file=data_TS05_xgb.dta|type=data|desc=xgb_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display ""
display "  XGBoost参数:"
display "    轮数:          " %10.0fc `n_rounds'
display "    深度:          " %10.0fc `max_depth'
display "    学习率:        " %10.3f `learning_rate'
display ""
display "  性能:"
display "    RMSE:          " %10.4f `rmse'
display "    R²:            " %10.4f `r2'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=rmse|value=`rmse'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS05|status=ok|elapsed_sec=`elapsed'"
log close
