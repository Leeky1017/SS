* ==============================================================================
* SS_TEMPLATE: id=TG06  level=L1  module=G  title="Mahal Match"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG06_mahal_result.csv type=table desc="Mahal match results"
*   - table_TG06_balance.csv type=table desc="Balance after matching"
*   - data_TG06_mahal_matched.dta type=data desc="Matched data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - psmatch2 source=ssc purpose="Mahalanobis matching"
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

display "SS_TASK_BEGIN|id=TG06|level=L1|title=Mahal_Match"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "psmatch2"
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
display "SS_DEP_CHECK|pkg=psmatch2|source=ssc|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local outcome_var = "__OUTCOME_VAR__"
local match_vars = "__MATCH_VARS__"
local exact_vars = "__EXACT_VARS__"
local n_neighbors = __N_NEIGHBORS__

if `n_neighbors' <= 0 {
    local n_neighbors = 1
}

display ""
display ">>> 马氏距离匹配参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    匹配变量: `match_vars'"
if "`exact_vars'" != "" {
    display "    精确匹配: `exact_vars'"
}
display "    邻居数: `n_neighbors'"

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
foreach var in `treatment_var' `outcome_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

local valid_match_vars ""
foreach var of local match_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_match_vars "`valid_match_vars' `var'"
    }
}

quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)

display ">>> 处理组: `n_treated', 对照组: `n_control'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 执行马氏距离匹配 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 执行马氏距离匹配"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建psmatch2命令选项
local match_opts "mahal(`valid_match_vars') neighbor(`n_neighbors') common"
if "`exact_vars'" != "" {
    local match_opts "`match_opts' exact(`exact_vars')"
}

display ">>> 执行马氏距离匹配..."
psmatch2 `treatment_var', outcome(`outcome_var') `match_opts'

* 获取ATT结果
local att = r(att)
local att_se = r(seatt)
local att_t = r(tatt)

display ""
display ">>> ATT估计结果:"
display "    ATT = " %10.4f `att'
display "    SE  = " %10.4f `att_se'
display "    t   = " %10.4f `att_t'

display "SS_METRIC|name=att|value=`att'"
display "SS_METRIC|name=att_se|value=`att_se'"

* ============ 匹配质量评估 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 匹配质量评估"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly count if _treated == 1 & _support == 1
local n_treated_matched = r(N)
quietly count if _treated == 0 & _weight > 0
local n_control_used = r(N)

display ""
display ">>> 匹配统计:"
display "    匹配处理组: `n_treated_matched' / `n_treated'"
display "    使用对照组: `n_control_used'"

* 平衡性检验
tempname balance
postfile `balance' str32 variable double std_diff_before double std_diff_after double reduction ///
    using "temp_mahal_balance.dta", replace

display ""
display "变量                 标准化差异(前)  标准化差异(后)  改善"
display "───────────────────────────────────────────────────────────────"

foreach var of local valid_match_vars {
    quietly summarize `var' if `treatment_var' == 1
    local mean_t_before = r(mean)
    local sd_t = r(sd)
    quietly summarize `var' if `treatment_var' == 0
    local mean_c_before = r(mean)
    local sd_c = r(sd)
    local pooled_sd = sqrt((`sd_t'^2 + `sd_c'^2) / 2)
    local std_diff_before = (`mean_t_before' - `mean_c_before') / `pooled_sd' * 100
    
    quietly summarize `var' if _treated == 1 & _support == 1
    local mean_t_after = r(mean)
    quietly summarize `var' if _treated == 0 [aw = _weight]
    local mean_c_after = r(mean)
    local std_diff_after = (`mean_t_after' - `mean_c_after') / `pooled_sd' * 100
    
    if abs(`std_diff_before') > 0.001 {
        local reduction = (1 - abs(`std_diff_after') / abs(`std_diff_before')) * 100
    }
    else {
        local reduction = 100
    }
    
    post `balance' ("`var'") (`std_diff_before') (`std_diff_after') (`reduction')
    display %20s "`var'" "  " %12.2f `std_diff_before' "%  " %12.2f `std_diff_after' "%  " %10.1f `reduction' "%"
}

postclose `balance'

preserve
use "temp_mahal_balance.dta", clear
export delimited using "table_TG06_balance.csv", replace
display "SS_OUTPUT_FILE|file=table_TG06_balance.csv|type=table|desc=balance"
restore

* ============ 导出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

local ci_lower = `att' - 1.96 * `att_se'
local ci_upper = `att' + 1.96 * `att_se'
local p_value = 2 * (1 - normal(abs(`att_t')))

preserve
clear
set obs 1
generate str20 method = "Mahalanobis"
generate str10 estimand = "ATT"
generate double effect = `att'
generate double se = `att_se'
generate double t_stat = `att_t'
generate double p_value = `p_value'
generate double ci_lower = `ci_lower'
generate double ci_upper = `ci_upper'
generate long n_treated = `n_treated_matched'
generate long n_control = `n_control_used'
export delimited using "table_TG06_mahal_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG06_mahal_result.csv|type=table|desc=mahal_result"
restore

keep if _support == 1
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG06_mahal_matched.dta", replace
display "SS_OUTPUT_FILE|file=data_TG06_mahal_matched.dta|type=data|desc=matched_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=att|value=`att'"

capture erase "temp_mahal_balance.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG06 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  匹配后样本量:    " %10.0fc `n_output'
display ""
display "  ATT估计:"
display "    效应值:        " %10.4f `att'
display "    标准误:        " %10.4f `att_se'
display "    95% CI:        [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = `n_input' - `n_output'
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG06|status=ok|elapsed_sec=`elapsed'"
log close
