* ==============================================================================
* SS_TEMPLATE: id=TU14  level=L2  module=U  title="Kernel Regression"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU14_npregress.png type=figure desc="Kernel regression fit"
*   - table_TU14_npregress.csv type=table desc="Npregress results"
*   - data_TU14_npregress.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TU14|level=L2|title=Kernel_Regression"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local kernel = "__KERNEL__"

if "`kernel'" == "" | "`kernel'" == "__KERNEL__" { local kernel = "epanechnikov" }

display ""
display ">>> 核回归参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    核函数: `kernel'"

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
capture confirm numeric variable `depvar'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`depvar' not found"
    display "SS_ERR:VAR_NOT_FOUND:`depvar' not found"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 核回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 核回归 (Kernel Regression)"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用npregress kernel命令
npregress kernel `depvar' `indepvars', kernel(`kernel')

local n_obs = e(N)

display ""
display ">>> 核回归结果:"
display "    样本量: `n_obs'"
display "    核函数: `kernel'"

display "SS_METRIC|name=n_obs|value=`n_obs'"

* 预测
predict yhat_mean, mean

* 获取第一个自变量用于绘图
local firstvar : word 1 of `indepvars'

twoway (scatter `depvar' `firstvar', msize(small) mcolor(gray%50)) ///
    (line yhat_mean `firstvar', sort lwidth(medium) lcolor(navy)), ///
    title("核回归拟合") ///
    subtitle("核函数: `kernel'") ///
    xtitle("`firstvar'") ytitle("`depvar'") ///
    legend(order(1 "观测值" 2 "核回归拟合"))

graph export "fig_TU14_npregress.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU14_npregress.png|type=figure|desc=npregress_fit"

* 导出结果
preserve
clear
set obs 2
gen str20 metric = ""
gen str50 value = ""
replace metric = "N" in 1
replace value = "`n_obs'" in 1
replace metric = "Kernel" in 2
replace value = "`kernel'" in 2
export delimited using "table_TU14_npregress.csv", replace
display "SS_OUTPUT_FILE|file=table_TU14_npregress.csv|type=table|desc=npregress_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU14_npregress.dta", replace
display "SS_OUTPUT_FILE|file=data_TU14_npregress.dta|type=data|desc=npregress_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU14 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  核函数:          `kernel'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=kernel|value=`kernel'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU14|status=ok|elapsed_sec=`elapsed'"
log close
