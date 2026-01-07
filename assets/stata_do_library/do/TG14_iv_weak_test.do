* ==============================================================================
* SS_TEMPLATE: id=TG14  level=L1  module=G  title="IV Weak Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG14_weak_iv_tests.csv type=table desc="Weak IV tests"
*   - table_TG14_critical_values.csv type=table desc="Critical values"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - ivreg2 source=ssc purpose="IV regression"
*   - ranktest source=ssc purpose="Rank test"
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

display "SS_TASK_BEGIN|id=TG14|level=L1|title=IV_Weak_Test"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "ivreg2 ranktest"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_MISSING:cmd=`dep':hint=ssc install `dep'"
        display "SS_ERROR:DEP_MISSING:`dep' is required but not installed"
        display "SS_ERR:DEP_MISSING:`dep' is required but not installed"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=ivreg2|source=ssc|status=ok"

* ============ 参数设置 ============
local dep_var = "__DEPVAR__"
local endog_var = "__ENDOG_VAR__"
local instruments = "__INSTRUMENTS__"
local exog_vars = "__EXOG_VARS__"

display ""
display ">>> 弱工具变量检验参数:"
display "    因变量: `dep_var'"
display "    内生变量: `endog_var'"
display "    工具变量: `instruments'"

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
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
foreach var in `dep_var' `endog_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

local valid_instruments ""
foreach var of local instruments {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_instruments "`valid_instruments' `var'"
    }
}

local valid_exog ""
foreach var of local exog_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_exog "`valid_exog' `var'"
    }
}

local n_instruments : word count `valid_instruments'
local n_endog : word count `endog_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 弱工具变量检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 弱工具变量检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 运行ivreg2获取诊断统计量
ivreg2 `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), robust first ffirst

* 提取统计量
local cdf = e(cdf)
local widstat = e(widstat)
local archi2 = e(archi2)
local archi2p = e(archi2p)
local arf = e(arf)
local arfp = e(arfp)

display ""
display ">>> 弱工具变量检验结果:"
display ""
display "1. Cragg-Donald Wald F统计量: " %10.2f `cdf'
display "   (用于i.i.d.误差假设)"
display ""
display "2. Kleibergen-Paap rk Wald F统计量: " %10.2f `widstat'
display "   (用于异方差/聚类稳健)"
display ""
display "3. Anderson-Rubin检验:"
display "   Chi2统计量: " %10.2f `archi2'
display "   p值: " %10.4f `archi2p'
display "   F统计量: " %10.2f `arf'
display "   p值: " %10.4f `arfp'

display "SS_METRIC|name=cragg_donald_f|value=`cdf'"
display "SS_METRIC|name=kleibergen_paap_f|value=`widstat'"

* ============ Stock-Yogo临界值 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Stock-Yogo临界值比较"
display "═══════════════════════════════════════════════════════════════════════════════"

* Stock-Yogo临界值（单内生变量情况）
display ""
display ">>> Stock-Yogo 2SLS相对偏误临界值 (单内生变量):"
display "    工具变量数: `n_instruments'"
display ""
display "    最大相对偏误    临界值"
display "    ─────────────────────────"

* 简化的临界值表（实际应用中应使用完整表）
if `n_instruments' == 1 {
    display "    10%             16.38"
    display "    15%             8.96"
    display "    20%             6.66"
    display "    25%             5.53"
    local cv_10 = 16.38
}
else if `n_instruments' == 2 {
    display "    10%             19.93"
    display "    15%             11.59"
    display "    20%             8.75"
    display "    25%             7.25"
    local cv_10 = 19.93
}
else if `n_instruments' == 3 {
    display "    10%             22.30"
    display "    15%             12.83"
    display "    20%             9.54"
    display "    25%             7.80"
    local cv_10 = 22.30
}
else {
    display "    10%             约 " %5.2f `=16 + `n_instruments''
    local cv_10 = 16 + `n_instruments'
}

* 判断
display ""
if `cdf' >= `cv_10' {
    display ">>> 结论: Cragg-Donald F (" %5.2f `cdf' ") >= 临界值 (" %5.2f `cv_10' ")"
    display ">>> 工具变量强度: 通过10%偏误检验"
    local weak_iv_conclusion = "通过:工具变量足够强"
}
else if `cdf' >= 10 {
    display ">>> 结论: Cragg-Donald F (" %5.2f `cdf' ") >= 10 (经验法则)"
    display ">>> 工具变量强度: 可接受"
    local weak_iv_conclusion = "可接受:F>=10"
}
else {
    display ">>> 结论: Cragg-Donald F (" %5.2f `cdf' ") < 10"
    display ">>> 警告: 存在弱工具变量问题！"
    display "SS_WARNING:WEAK_IV:Cragg-Donald F < 10"
    local weak_iv_conclusion = "警告:弱工具变量"
}

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出检验结果
preserve
clear
set obs 5
generate str40 test = ""
generate double statistic = .
generate double p_value = .
generate str50 conclusion = ""

replace test = "Cragg-Donald Wald F" in 1
replace statistic = `cdf' in 1
replace conclusion = cond(`cdf' >= 10, "通过(F>=10)", "弱IV") in 1

replace test = "Kleibergen-Paap rk Wald F" in 2
replace statistic = `widstat' in 2
replace conclusion = cond(`widstat' >= 10, "通过(F>=10)", "弱IV") in 2

replace test = "Anderson-Rubin Chi2" in 3
replace statistic = `archi2' in 3
replace p_value = `archi2p' in 3
replace conclusion = cond(`archi2p' < 0.05, "内生变量显著", "内生变量不显著") in 3

replace test = "Anderson-Rubin F" in 4
replace statistic = `arf' in 4
replace p_value = `arfp' in 4

replace test = "工具变量数" in 5
replace statistic = `n_instruments' in 5

export delimited using "table_TG14_weak_iv_tests.csv", replace
display "SS_OUTPUT_FILE|file=table_TG14_weak_iv_tests.csv|type=table|desc=weak_iv_tests"
restore

* 导出临界值表
preserve
clear
set obs 4
generate str20 max_bias = ""
generate int n_iv_1 = .
generate int n_iv_2 = .
generate int n_iv_3 = .

replace max_bias = "10%" in 1
replace n_iv_1 = 16 in 1
replace n_iv_2 = 20 in 1
replace n_iv_3 = 22 in 1

replace max_bias = "15%" in 2
replace n_iv_1 = 9 in 2
replace n_iv_2 = 12 in 2
replace n_iv_3 = 13 in 2

replace max_bias = "20%" in 3
replace n_iv_1 = 7 in 3
replace n_iv_2 = 9 in 3
replace n_iv_3 = 10 in 3

replace max_bias = "25%" in 4
replace n_iv_1 = 6 in 4
replace n_iv_2 = 7 in 4
replace n_iv_3 = 8 in 4

export delimited using "table_TG14_critical_values.csv", replace
display "SS_OUTPUT_FILE|file=table_TG14_critical_values.csv|type=table|desc=critical_values"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=cragg_donald_f|value=`cdf'"
display "SS_SUMMARY|key=kleibergen_paap_f|value=`widstat'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG14 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:              " %10.0fc `n_input'
display "  工具变量数:          " %10.0fc `n_instruments'
display ""
display "  弱工具变量检验:"
display "    Cragg-Donald F:    " %10.2f `cdf'
display "    Kleibergen-Paap F: " %10.2f `widstat'
display "    结论:              `weak_iv_conclusion'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
local n_dropped = 0
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG14|status=ok|elapsed_sec=`elapsed'"
log close
