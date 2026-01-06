* ==============================================================================
* SS_TEMPLATE: id=TU11  level=L2  module=U  title="RIF-HDReg"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TU11_rifhdreg.csv type=table desc="RIF regression results"
*   - data_TU11_rifhdreg.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: rifreg
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

display "SS_TASK_BEGIN|id=TU11|level=L2|title=RIF_HDReg"
display "SS_TASK_VERSION:2.0.1"

* 检查依赖
capture which rifreg
if _rc {
    display "SS_DEP_CHECK|pkg=rifreg|source=ssc|status=missing"
    display "SS_ERROR:DEP_MISSING:rifreg not installed"
    display "SS_ERR:DEP_MISSING:rifreg not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=rifreg|source=ssc|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local quantile = __QUANTILE__

if `quantile' <= 0 | `quantile' >= 1 { local quantile = 0.5 }

display ""
display ">>> 无条件分位数回归参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    分位数: `quantile'"

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

* ============ RIF回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 无条件分位数回归 (RIF)"
display "═══════════════════════════════════════════════════════════════════════════════"

rifreg `depvar' `indepvars', quantile(`quantile')

matrix b = e(b)
matrix V = e(V)
local n_obs = e(N)

display ""
display ">>> RIF回归结果:"
display "    样本量: `n_obs'"
display "    分位数: `quantile'"

display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=quantile|value=`quantile'"

* 导出结果
preserve
clear
local nvars : word count `indepvars'
local nvars = `nvars' + 1
set obs `nvars'
gen str30 variable = ""
gen double coef = .
gen double se = .

local i = 1
foreach v in `indepvars' _cons {
    replace variable = "`v'" in `i'
    replace coef = b[1, `i'] in `i'
    replace se = sqrt(V[`i', `i']) in `i'
    local i = `i' + 1
}

export delimited using "table_TU11_rifhdreg.csv", replace
display "SS_OUTPUT_FILE|file=table_TU11_rifhdreg.csv|type=table|desc=rif_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU11_rifhdreg.dta", replace
display "SS_OUTPUT_FILE|file=data_TU11_rifhdreg.dta|type=data|desc=rif_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU11 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  分位数:          " %10.2f `quantile'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=quantile|value=`quantile'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU11|status=ok|elapsed_sec=`elapsed'"
log close
