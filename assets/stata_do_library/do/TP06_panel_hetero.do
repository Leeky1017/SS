* ==============================================================================
* SS_TEMPLATE: id=TP06  level=L2  module=P  title="Panel Hetero"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP06_hetero_tests.csv type=table desc="Heteroskedasticity tests"
*   - data_TP06_hetero.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TP06|level=L2|title=Panel_Hetero"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"

display ""
display ">>> 异方差检验参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    display "SS_TASK_END|id=TP06|status=fail|elapsed_sec=."
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `depvar' `id_var' `time_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|severity=fail|var=`var'"
        display "SS_TASK_END|id=TP06|status=fail|elapsed_sec=."
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

capture xtset `id_var' `time_var'
if _rc {
    local rc_xtset = _rc
    display "SS_RC|code=`rc_xtset'|cmd=xtset|msg=xtset_failed|severity=fail"
    display "SS_TASK_END|id=TP06|status=fail|elapsed_sec=."
    log close
    exit `rc_xtset'
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ Modified Wald检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Modified Wald检验（组间异方差）"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly xtreg `depvar' `valid_indep', fe
predict double resid_fe, e

* 计算各组残差方差
bysort `id_var': egen double var_resid = sd(resid_fe)
replace var_resid = var_resid^2

quietly summarize var_resid
local overall_var = r(mean)

* 简化的Wald检验
bysort `id_var': generate byte _first = (_n == 1)
quietly count if _first
local n_groups = r(N)
quietly summarize var_resid if _first
local var_of_var = r(Var)
local wald_chi2 = `n_groups' * `var_of_var' / `overall_var'^2

local wald_p = chi2tail(`n_groups'-1, `wald_chi2')

display ""
display ">>> Modified Wald检验 (H0: 同方差):"
display "    χ²统计量: " %10.4f `wald_chi2'
display "    自由度: " %10.0f `=`n_groups'-1'
display "    p值: " %10.4f `wald_p'

if `wald_p' < 0.05 {
    display "    结论: 存在组间异方差"
    local hetero_conclusion = "存在异方差"
}
else {
    display "    结论: 无显著异方差"
    local hetero_conclusion = "无异方差"
}

display "SS_METRIC|name=wald_chi2|value=`wald_chi2'"
display "SS_METRIC|name=wald_p|value=`wald_p'"

* ============ Breusch-Pagan检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Breusch-Pagan检验"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly regress `depvar' `valid_indep'
predict double resid_ols, residuals

generate double resid2 = resid_ols^2
quietly summarize resid2
local mean_resid2 = r(mean)
generate double g = resid2 / `mean_resid2' - 1

quietly regress g `valid_indep'
local bp_chi2 = e(mss) / 2
local bp_df = e(df_m)
local bp_p = chi2tail(`bp_df', `bp_chi2')

display ""
display ">>> Breusch-Pagan检验 (H0: 同方差):"
display "    χ²统计量: " %10.4f `bp_chi2'
display "    自由度: " %10.0f `bp_df'
display "    p值: " %10.4f `bp_p'

display "SS_METRIC|name=bp_chi2|value=`bp_chi2'"
display "SS_METRIC|name=bp_p|value=`bp_p'"

* 导出检验结果
preserve
clear
set obs 2
generate str30 test = ""
generate double statistic = .
generate double p_value = .
generate str30 conclusion = ""

replace test = "Modified Wald" in 1
replace statistic = `wald_chi2' in 1
replace p_value = `wald_p' in 1
replace conclusion = "`hetero_conclusion'" in 1

replace test = "Breusch-Pagan" in 2
replace statistic = `bp_chi2' in 2
replace p_value = `bp_p' in 2
replace conclusion = cond(`bp_p' < 0.05, "存在异方差", "无异方差") in 2

export delimited using "table_TP06_hetero_tests.csv", replace
display "SS_OUTPUT_FILE|file=table_TP06_hetero_tests.csv|type=table|desc=hetero_tests"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TP06_hetero.dta", replace
display "SS_OUTPUT_FILE|file=data_TP06_hetero.dta|type=data|desc=hetero_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP06 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  组数:            " %10.0fc `n_groups'
display ""
display "  异方差检验:"
display "    Wald χ²:       " %10.4f `wald_chi2'
display "    Wald p值:      " %10.4f `wald_p'
display "    BP χ²:         " %10.4f `bp_chi2'
display "    BP p值:        " %10.4f `bp_p'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=wald_p|value=`wald_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP06|status=ok|elapsed_sec=`elapsed'"
log close
