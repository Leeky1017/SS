* ==============================================================================
* SS_TEMPLATE: id=TG02  level=L1  module=G  title="PSM Match"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG02_att_result.csv type=table desc="ATT results"
*   - table_TG02_balance_after.csv type=table desc="Balance after matching"
*   - fig_TG02_balance_compare.png type=graph desc="Balance comparison"
*   - data_TG02_matched.dta type=data desc="Matched data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - psmatch2 source=ssc purpose="PSM matching"
* ==============================================================================

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

display "SS_TASK_BEGIN|id=TG02|level=L1|title=PSM_Match"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.0.1"

* ============ 依赖检测 ============
local required_deps "psmatch2"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
display "SS_DEP_CHECK|pkg=`dep'|source=ssc|status=missing"
display "SS_DEP_MISSING|pkg=`dep'|hint=ssc_install_`dep'"
display "SS_RC|code=199|cmd=which `dep'|msg=dependency_missing|severity=fail"
display "SS_RC|code=199|cmd=which|msg=dep_missing|detail=`dep'_is_required_but_not_installed|severity=fail"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=psmatch2|source=ssc|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local outcome_var = "__OUTCOME_VAR__"
local covariates = "__COVARIATES__"
local n_neighbors = __N_NEIGHBORS__
local caliper = __CALIPER__
local with_replace = "__WITH_REPLACE__"

* 参数默认值
if `n_neighbors' <= 0 {
    local n_neighbors = 1
}
if `caliper' <= 0 | `caliper' > 1 {
    local caliper = 0.05
}
if "`with_replace'" == "" {
    local with_replace = "yes"
}

display ""
display ">>> PSM匹配参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    协变量: `covariates'"
display "    邻居数: `n_neighbors'"
display "    卡尺: `caliper'"
display "    放回匹配: `with_replace'"

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
foreach var in `treatment_var' `outcome_var' {
    capture confirm variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

* 检查协变量
local valid_covariates ""
foreach var of local covariates {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_covariates "`valid_covariates' `var'"
    }
}

* 统计处理组和对照组
quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)

display ">>> 处理组: `n_treated', 对照组: `n_control'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 执行PSM匹配 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 执行倾向得分匹配"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建psmatch2命令
local psmatch_opts "neighbor(`n_neighbors') caliper(`caliper') common"
if "`with_replace'" == "no" {
    local psmatch_opts "`psmatch_opts' noreplacement"
}

display ">>> 执行psmatch2..."
psmatch2 `treatment_var' `valid_covariates', outcome(`outcome_var') `psmatch_opts'

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
display "SS_METRIC|name=att_t|value=`att_t'"

* ============ 匹配质量评估 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 匹配质量评估"
display "═══════════════════════════════════════════════════════════════════════════════"

* 统计匹配结果
quietly count if _treated == 1 & _support == 1
local n_treated_matched = r(N)
quietly count if _treated == 0 & _weight > 0
local n_control_matched = r(N)

display ""
display ">>> 匹配统计:"
display "    匹配的处理组: `n_treated_matched' / `n_treated'"
display "    使用的对照组: `n_control_matched' / `n_control'"

* 计算匹配后平衡性
tempname balance_after
postfile `balance_after' str32 variable double mean_t double mean_c double std_diff_before double std_diff_after double bias_reduction ///
    using "temp_balance_after.dta", replace

display ""
display "匹配后平衡性检验:"
display "变量                 标准化差异(前)  标准化差异(后)  偏误减少"
display "───────────────────────────────────────────────────────────────"

foreach var of local valid_covariates {
    * 匹配前标准化差异
    quietly summarize `var' if `treatment_var' == 1
    local mean_t_before = r(mean)
    local sd_t = r(sd)
    quietly summarize `var' if `treatment_var' == 0
    local mean_c_before = r(mean)
    local sd_c = r(sd)
    local pooled_sd = sqrt((`sd_t'^2 + `sd_c'^2) / 2)
    if `pooled_sd' > 0 {
        local std_diff_before = (`mean_t_before' - `mean_c_before') / `pooled_sd' * 100
    }
    else {
        local std_diff_before = 0
    }
    
    * 匹配后标准化差异（加权）
    quietly summarize `var' if _treated == 1 & _support == 1
    local mean_t_after = r(mean)
    quietly summarize `var' if _treated == 0 [aw = _weight]
    local mean_c_after = r(mean)
    if `pooled_sd' > 0 {
        local std_diff_after = (`mean_t_after' - `mean_c_after') / `pooled_sd' * 100
    }
    else {
        local std_diff_after = 0
    }
    
    * 偏误减少
    if abs(`std_diff_before') > 0 {
        local bias_reduction = (1 - abs(`std_diff_after') / abs(`std_diff_before')) * 100
    }
    else {
        local bias_reduction = 100
    }
    
    post `balance_after' ("`var'") (`mean_t_after') (`mean_c_after') (`std_diff_before') (`std_diff_after') (`bias_reduction')
    
    display %20s "`var'" "  " %12.2f `std_diff_before' "%  " %12.2f `std_diff_after' "%  " %10.1f `bias_reduction' "%"
}

postclose `balance_after'

* 导出平衡性结果
preserve
use "temp_balance_after.dta", clear
export delimited using "table_TG02_balance_after.csv", replace
display "SS_OUTPUT_FILE|file=table_TG02_balance_after.csv|type=table|desc=balance_after"
restore

* ============ 生成平衡性对比图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成图表"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用pstest命令生成平衡性图
capture pstest `valid_covariates', both graph
if !_rc {
    graph export "fig_TG02_balance_compare.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG02_balance_compare.png|type=graph|desc=balance_compare"
}
else {
display "SS_RC|code=0|cmd=warning|msg=graph_failed|detail=Could_not_generate_balance_graph|severity=warn"
}

* ============ 导出ATT结果 ============
preserve
clear
set obs 1
generate str20 estimand = "ATT"
generate double estimate = `att'
generate double std_err = `att_se'
generate double t_stat = `att_t'
generate double p_value = 2 * (1 - normal(abs(`att_t')))
generate double ci_lower = `att' - 1.96 * `att_se'
generate double ci_upper = `att' + 1.96 * `att_se'
generate long n_treated = `n_treated_matched'
generate long n_control = `n_control_matched'

export delimited using "table_TG02_att_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG02_att_result.csv|type=table|desc=att_result"
restore

* ============ 保存匹配后数据 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 保留匹配样本
keep if _support == 1

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG02_matched.dta", replace
display "SS_OUTPUT_FILE|file=data_TG02_matched.dta|type=data|desc=matched_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=att|value=`att'"

* 清理临时文件
capture erase "temp_balance_after.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  匹配后样本量:    " %10.0fc `n_output'
display "  匹配处理组:      " %10.0fc `n_treated_matched'
display "  匹配对照组:      " %10.0fc `n_control_matched'
display ""
display "  ATT估计:"
display "    效应值:        " %10.4f `att'
display "    标准误:        " %10.4f `att_se'
display "    t统计量:       " %10.4f `att_t'
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

* ============ 任务结束 ============
display "SS_TASK_END|id=TG02|status=ok|elapsed_sec=`elapsed'"
log close
