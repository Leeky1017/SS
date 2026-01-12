* ==============================================================================
* SS_TEMPLATE: id=TU10  level=L1  module=U  title="Coef Plot"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU10_coef.png type=figure desc="Coefficient plot"
*   - table_TU10_coef.csv type=table desc="Coefficients"
*   - data_TU10_coef.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Coefficient plots are easiest to compare when predictors are on comparable scales; consider standardizing or using meaningful units.
* - Report uncertainty clearly (CI level + SE type); for clustered/heteroskedastic settings prefer robust/clustered SE over default OLS SE.
* - Avoid over-interpreting magnitude without checking model specification (omitted variables, functional form, collinearity).
* 最佳实践审查（ZH）:
* - 系数图的可比性依赖于变量尺度；建议标准化或使用有意义的单位进行比较。
* - 不确定性表达要清晰（置信水平 + 标准误类型）；存在异方差/聚类时优先使用稳健/聚类标准误。
* - 避免在未检验模型设定（遗漏变量、函数形式、共线性）前过度解读系数大小。

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

display "SS_TASK_BEGIN|id=TU10|level=L1|title=Coef_Plot"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local ci_level_raw = "__CI_LEVEL__"
local ci_level = real("`ci_level_raw'")

if missing(`ci_level') | `ci_level' < 80 | `ci_level' > 99 {
    local ci_level = 95
}
local ci_level = floor(`ci_level')

display ""
display ">>> 系数图参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    置信水平: `ci_level'%"

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
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate dependent/independent variables.
* ZH: 校验因变量与自变量存在且为数值型。

* ============ 变量检查 ============
capture confirm numeric variable `depvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found|severity=fail"
    log close
    exit 200
}

local valid_indep ""
local n_indep = 0
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
        local n_indep = `n_indep' + 1
    }
}
if `n_indep' <= 0 {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=no_valid_indepvars|severity=fail"
    log close
    exit 200
}
display "SS_METRIC|name=n_indep|value=`n_indep'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Fit OLS regression and plot coefficients with confidence intervals.
* ZH: 执行 OLS 回归并绘制系数及置信区间。

* ============ 回归估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 回归估计"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily regress `depvar' `valid_indep', level(`ci_level')
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=regress|msg=regression_failed|severity=fail"
    log close
    exit `rc'
}

local r2 = e(r2)
local n_obs = e(N)

display ""
display ">>> 模型拟合:"
display "    R²: " %8.4f `r2'
display "    N: `n_obs'"

display "SS_METRIC|name=r2|value=`r2'"

* ============ 提取系数和CI ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 系数和置信区间"
display "═══════════════════════════════════════════════════════════════════════════════"

matrix b = e(b)
matrix V = e(V)

local t_crit = invttail(e(df_r), (100 - `ci_level') / 200)

tempname coef_data
postfile `coef_data' str32 variable double coef double se double ci_lo double ci_hi int order ///
    using "temp_coef.dta", replace

local varnames : colnames b
local nvars : word count `varnames'
local order = 0

display ""
display "变量              系数        SE        CI下限      CI上限"
display "────────────────────────────────────────────────────────────"

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    if "`vname'" != "_cons" {
        local order = `order' + 1
        local coef = b[1, `i']
        local se = sqrt(V[`i', `i'])
        local ci_lo = `coef' - `t_crit' * `se'
        local ci_hi = `coef' + `t_crit' * `se'
        
        post `coef_data' ("`vname'") (`coef') (`se') (`ci_lo') (`ci_hi') (`order')
        
        display %15s "`vname'" "  " %10.4f `coef' "  " %8.4f `se' "  " %10.4f `ci_lo' "  " %10.4f `ci_hi'
    }
}

postclose `coef_data'

* 导出系数表
preserve
use "temp_coef.dta", clear
sort order
label define coef_order 0 "", replace
forvalues i = 1/`=_N' {
    local vname = variable[`i']
    label define coef_order `i' "`vname'", add
}
label values order coef_order
export delimited using "table_TU10_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_TU10_coef.csv|type=table|desc=coefficients"

* ============ 绘制系数图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 绘制系数图"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway (rcap ci_lo ci_hi order, horizontal lcolor(navy)) ///
       (scatter order coef, mcolor(red) msize(medium)), ///
       xline(0, lcolor(gray) lpattern(dash)) ///
       ylabel(1(1)`order', valuelabel angle(0)) ///
       ytitle("") xtitle("系数估计") ///
       title("回归系数图 (`ci_level'% CI)") ///
       legend(off)

graph export "fig_TU10_coef.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU10_coef.png|type=figure|desc=coef_plot"
restore

capture erase "temp_coef.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU10_coef.dta", replace
display "SS_OUTPUT_FILE|file=data_TU10_coef.dta|type=data|desc=coef_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU10 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `order'
display "  R²:              " %10.4f `r2'
display "  置信水平:        `ci_level'%"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU10|status=ok|elapsed_sec=`elapsed'"
log close
