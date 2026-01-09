* ==============================================================================
* SS_TEMPLATE: id=TG15  level=L1  module=G  title="IV Overid"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG15_overid_tests.csv type=table desc="Overid tests"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="ivregress + estat overid"
* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* 方法 / Method: `ivregress 2sls` + `estat overid` (Hansen/Sargan depending on VCE)
* 识别假设 / ID assumptions: overid tests require more instruments than endogenous vars
* 诊断输出 / Diagnostics: `estat overid` p-value + explicit just-identified warning
* SSC依赖 / SSC deps: removed (replace `ivreg2`)
* 解读要点 / Interpretation: failing to reject overid ≠ proof of validity; rejection is a warning

* ============ 初始化 ============
capture log close _all
if _rc != 0 {
    * Expected non-fatal return code
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TG15|level=L1|title=IV_Overid"
display "SS_TASK_VERSION|version=2.1.0"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local dep_var = "__DEPVAR__"
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
display "SS_RC|code=601|cmd=confirm_file|msg=file_not_found|detail=data.csv_not_found|file=data.csv|severity=fail"
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
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
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
display "SS_RC|code=0|cmd=warning|msg=just_identified|detail=Model_is_just-identified_overidentification_test_not_applicable|severity=warn"
    display ">>> 模型恰好识别，无法进行过度识别检验"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 过度识别检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 过度识别检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建回归命令 / Build VCE option
local vce_opt "vce(robust)"
if "`cluster_var'" != "" {
    capture confirm variable `cluster_var'
    if !_rc {
        local vce_opt "vce(cluster `cluster_var')"
    }
}

capture noisily ivregress 2sls `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), `vce_opt'
if _rc {
display "SS_RC|code=430|cmd=ivregress_2sls|msg=ivregress_failed|detail=ivregress_failed_rc_`_rc'|severity=fail"
    log close
    exit 430
}

local overid_chi2 = .
local overid_p = .
local overid_df_r = .
if `overid_df' > 0 {
    capture noisily estat overid
    if _rc == 0 {
        capture local overid_chi2 = r(chi2)
        capture local overid_p = r(p)
        capture local overid_df_r = r(df)
        if `overid_p' < . & `overid_p' < 0.05 {
display "SS_RC|code=0|cmd=warning|msg=overid_rejected|detail=estat_overid_rejects_instrument_validity|severity=warn"
        }
    }
    else {
display "SS_RC|code=0|cmd=warning|msg=overid_failed|detail=estat_overid_failed_rc_`_rc'|severity=warn"
    }
}

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

local overid_conclusion = ""
if `overid_df' <= 0 {
    local overid_conclusion = "不适用:恰好识别"
}
else if `overid_p' >= 0.10 {
    local overid_conclusion = "通过:不拒绝H0"
}
else if `overid_p' >= 0.05 {
    local overid_conclusion = "边际拒绝:需谨慎"
}
else if `overid_p' < . {
    local overid_conclusion = "拒绝:IV可能无效"
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

replace test = "estat overid" in 1
replace statistic = `overid_chi2' in 1
replace df = cond(`overid_df_r' < ., `overid_df_r', `overid_df') in 1
replace p_value = `overid_p' in 1
replace conclusion = "`overid_conclusion'" in 1

replace test = "Overid df (n_iv - n_endog)" in 2
replace statistic = `overid_df' in 2
replace df = . in 2
replace p_value = . in 2
replace conclusion = "" in 2

export delimited using "table_TG15_overid_tests.csv", replace
display "SS_OUTPUT_FILE|file=table_TG15_overid_tests.csv|type=table|desc=overid_tests"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=overid_chi2|value=`overid_chi2'"
display "SS_SUMMARY|key=overid_p|value=`overid_p'"

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
display "  estat overid:"
display "    统计量(chi2):  " %10.4f `overid_chi2'
display "    p值:           " %10.4f `overid_p'
display "    结论:          `overid_conclusion'"
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
