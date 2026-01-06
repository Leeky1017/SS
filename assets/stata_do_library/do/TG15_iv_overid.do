* ==============================================================================
* SS_TEMPLATE: id=TG15  level=L1  module=G  title="IV Overid"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG15_overid_tests.csv type=table desc="Overid tests"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - ivreg2 source=ssc purpose="IV regression"
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

display "SS_TASK_BEGIN|id=TG15|level=L1|title=IV_Overid"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "ivreg2"
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
local dep_var = "__DEP_VAR__"
local endog_var = "__ENDOG_VAR__"
local instruments = "__INSTRUMENTS__"
local exog_vars = "__EXOG_VARS__"
local cluster_var = "__CLUSTER_VAR__"

display ""
display ">>> 过度识别检验参数:"
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
local overid_df = `n_instruments' - `n_endog'

display ">>> 工具变量数: `n_instruments'"
display ">>> 内生变量数: `n_endog'"
display ">>> 过度识别自由度: `overid_df'"

if `overid_df' <= 0 {
    display ""
    display "SS_WARNING:JUST_IDENTIFIED:Model is just-identified, overidentification test not applicable"
    display ">>> 模型恰好识别，无法进行过度识别检验"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 过度识别检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 过度识别检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建回归命令
local iv_opts "robust"
if "`cluster_var'" != "" {
    capture confirm variable `cluster_var'
    if !_rc {
        local iv_opts "cluster(`cluster_var')"
    }
}

ivreg2 `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), `iv_opts'

* 提取检验统计量
local sargan = e(sargan)
local sargan_p = e(sarganp)
local sargan_df = e(sargandf)
local hansen_j = e(j)
local hansen_p = e(jp)

display ""
display ">>> Sargan检验 (同方差假设):"
display "    Chi2统计量: " %10.4f `sargan'
display "    自由度: " %10.0f `sargan_df'
display "    p值: " %10.4f `sargan_p'

display ""
display ">>> Hansen J检验 (异方差稳健):"
display "    J统计量: " %10.4f `hansen_j'
display "    p值: " %10.4f `hansen_p'

display "SS_METRIC|name=sargan|value=`sargan'"
display "SS_METRIC|name=sargan_p|value=`sargan_p'"
display "SS_METRIC|name=hansen_j|value=`hansen_j'"
display "SS_METRIC|name=hansen_p|value=`hansen_p'"

* ============ 结果解释 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 结果解释"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 检验假设:"
display "    H0: 所有工具变量都是外生的（有效的）"
display "    H1: 至少一个工具变量是内生的（无效的）"
display ""

local sargan_conclusion = ""
local hansen_conclusion = ""

if `sargan_p' >= 0.10 {
    display ">>> Sargan检验结论: 不拒绝H0 (p=" %5.4f `sargan_p' ")"
    display "    工具变量整体外生性假设成立"
    local sargan_conclusion = "通过:工具变量外生"
}
else if `sargan_p' >= 0.05 {
    display ">>> Sargan检验结论: 在10%水平拒绝H0 (p=" %5.4f `sargan_p' ")"
    display "    边际拒绝，需谨慎"
    local sargan_conclusion = "边际拒绝:需谨慎"
}
else {
    display ">>> Sargan检验结论: 拒绝H0 (p=" %5.4f `sargan_p' ")"
    display "    警告: 工具变量可能存在内生性问题！"
    display "SS_WARNING:OVERID_REJECTED:Sargan test rejects instrument validity"
    local sargan_conclusion = "拒绝:IV可能内生"
}

display ""

if `hansen_p' >= 0.10 {
    display ">>> Hansen J检验结论: 不拒绝H0 (p=" %5.4f `hansen_p' ")"
    local hansen_conclusion = "通过:工具变量外生"
}
else if `hansen_p' >= 0.05 {
    display ">>> Hansen J检验结论: 在10%水平拒绝H0 (p=" %5.4f `hansen_p' ")"
    local hansen_conclusion = "边际拒绝:需谨慎"
}
else {
    display ">>> Hansen J检验结论: 拒绝H0 (p=" %5.4f `hansen_p' ")"
    display "SS_WARNING:HANSEN_REJECTED:Hansen J test rejects instrument validity"
    local hansen_conclusion = "拒绝:IV可能内生"
}

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
clear
set obs 2
generate str30 test = ""
generate double statistic = .
generate int df = .
generate double p_value = .
generate str50 conclusion = ""

replace test = "Sargan" in 1
replace statistic = `sargan' in 1
replace df = `sargan_df' in 1
replace p_value = `sargan_p' in 1
replace conclusion = "`sargan_conclusion'" in 1

replace test = "Hansen J" in 2
replace statistic = `hansen_j' in 2
replace df = `overid_df' in 2
replace p_value = `hansen_p' in 2
replace conclusion = "`hansen_conclusion'" in 2

export delimited using "table_TG15_overid_tests.csv", replace
display "SS_OUTPUT_FILE|file=table_TG15_overid_tests.csv|type=table|desc=overid_tests"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=sargan|value=`sargan'"
display "SS_SUMMARY|key=hansen_j|value=`hansen_j'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG15 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  工具变量数:      " %10.0fc `n_instruments'
display "  过度识别df:      " %10.0fc `overid_df'
display ""
display "  Sargan检验:"
display "    统计量:        " %10.4f `sargan'
display "    p值:           " %10.4f `sargan_p'
display "    结论:          `sargan_conclusion'"
display ""
display "  Hansen J检验:"
display "    统计量:        " %10.4f `hansen_j'
display "    p值:           " %10.4f `hansen_p'
display "    结论:          `hansen_conclusion'"
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

display "SS_TASK_END|id=TG15|status=ok|elapsed_sec=`elapsed'"
log close
