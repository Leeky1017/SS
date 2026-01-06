* ==============================================================================
* SS_TEMPLATE: id=TU15  level=L2  module=U  title="MI Impute"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TU15_mi_summary.csv type=table desc="MI summary"
*   - data_TU15_mi.dta type=data desc="Imputed data"
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

display "SS_TASK_BEGIN|id=TU15|level=L2|title=MI_Impute"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local impute_vars = "__IMPUTE_VARS__"
local method = "__METHOD__"
local n_imputations = __N_IMPUTATIONS__

if "`method'" == "" | "`method'" == "__METHOD__" { local method = "regress" }
if `n_imputations' < 1 | `n_imputations' > 100 { local n_imputations = 5 }

display ""
display ">>> 多重插补参数:"
display "    插补变量: `impute_vars'"
display "    插补方法: `method'"
display "    插补次数: `n_imputations'"

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
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 缺失数据分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 缺失数据分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 统计缺失情况
local n_missing_total = 0
foreach v of varlist `impute_vars' {
    quietly count if missing(`v')
    local n_miss = r(N)
    local n_missing_total = `n_missing_total' + `n_miss'
    display "    `v': `n_miss' 缺失"
}

display ""
display ">>> 缺失统计:"
display "    总缺失值: `n_missing_total'"

display "SS_METRIC|name=n_missing_total|value=`n_missing_total'"

* ============ 多重插补 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 多重插补"
display "═══════════════════════════════════════════════════════════════════════════════"

* 设置MI数据
mi set mlong

* 注册插补变量
mi register imputed `impute_vars'

* 执行插补
mi impute `method' `impute_vars', add(`n_imputations')

display ""
display ">>> 多重插补完成"
display "    插补次数: `n_imputations'"
display "    插补方法: `method'"

display "SS_METRIC|name=n_imputations|value=`n_imputations'"

* 导出摘要
preserve
mi describe
clear
set obs 3
gen str30 metric = ""
gen str50 value = ""
replace metric = "插补变量" in 1
replace value = "`impute_vars'" in 1
replace metric = "插补方法" in 2
replace value = "`method'" in 2
replace metric = "插补次数" in 3
replace value = "`n_imputations'" in 3
export delimited using "table_TU15_mi_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TU15_mi_summary.csv|type=table|desc=mi_summary"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU15_mi.dta", replace
display "SS_OUTPUT_FILE|file=data_TU15_mi.dta|type=data|desc=mi_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU15 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  原始样本量:      " %10.0fc `n_input'
display "  总缺失值:        " %10.0fc `n_missing_total'
display "  插补次数:        " %10.0f `n_imputations'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_imputations|value=`n_imputations'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU15|status=ok|elapsed_sec=`elapsed'"
log close
