* ==============================================================================
* SS_TEMPLATE: id=TG22  level=L2  module=G  title="DID Placebo"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG22_placebo_results.csv type=table desc="Placebo results"
*   - fig_TG22_placebo_dist.png type=figure desc="Placebo distribution"
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

display "SS_TASK_BEGIN|id=TG22|level=L2|title=DID_Placebo"
display "SS_TASK_VERSION:2.0.1"

display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local treat_var = "__TREAT_VAR__"
local post_var = "__POST_VAR__"
local time_var = "__TIME_VAR__"
local placebo_type = "__PLACEBO_TYPE__"
local n_permutations = __N_PERMUTATIONS__

if "`placebo_type'" == "" {
    local placebo_type = "permutation"
}
if `n_permutations' <= 0 | `n_permutations' > 2000 {
    local n_permutations = 500
}

display ""
display ">>> DID安慰剂检验参数:"
display "    结果变量: `outcome_var'"
display "    处理组: `treat_var'"
display "    处理后: `post_var'"
display "    安慰剂类型: `placebo_type'"
if "`placebo_type'" == "permutation" {
    display "    置换次数: `n_permutations'"
}

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
tempfile original_data
save `original_data'

* ============ 变量检查 ============
foreach var in `outcome_var' `treat_var' `post_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 真实DID估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 真实DID估计"
display "═══════════════════════════════════════════════════════════════════════════════"

generate byte did = `treat_var' * `post_var'
regress `outcome_var' did `treat_var' `post_var', robust

local true_effect = _b[did]
local true_se = _se[did]
local true_t = `true_effect' / `true_se'

display ""
display ">>> 真实DID效应: " %10.4f `true_effect'
display ">>> 标准误: " %10.4f `true_se'
display ">>> t统计量: " %10.4f `true_t'

display "SS_METRIC|name=true_effect|value=`true_effect'"

* ============ 执行安慰剂检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 执行安慰剂检验 (`placebo_type')"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname placebo_results
postfile `placebo_results' int iteration double effect double t_stat ///
    using "temp_placebo.dta", replace

if "`placebo_type'" == "time" {
    * 假处理时间检验：在处理前的不同时间点假装处理发生
    display ">>> 执行假处理时间检验..."
    
    quietly levelsof `time_var' if `post_var' == 0, local(pre_times)
    local n_pre : word count `pre_times'
    
    if `n_pre' < 2 {
        display "SS_WARNING:FEW_PERIODS:Too few pre-treatment periods"
    }
    
    local iter = 0
    foreach t of local pre_times {
        use `original_data', clear
        
        * 创建假处理后变量
        generate byte fake_post = (`time_var' >= `t')
        generate byte fake_did = `treat_var' * fake_post
        
        quietly regress `outcome_var' fake_did `treat_var' fake_post, robust
        local fake_effect = _b[fake_did]
        local fake_t = `fake_effect' / _se[fake_did]
        
        local iter = `iter' + 1
        post `placebo_results' (`iter') (`fake_effect') (`fake_t')
        
        display "    时间`t': 效应=" %8.4f `fake_effect' ", t=" %6.2f `fake_t'
    }
}
else if "`placebo_type'" == "group" {
    * 假处理组检验：在对照组内随机分配假处理
    display ">>> 执行假处理组检验..."
    
    set seed 12345
    
    forvalues i = 1/`n_permutations' {
        use `original_data', clear
        
        * 只保留对照组
        keep if `treat_var' == 0
        
        * 随机分配假处理
        generate double _rand = runiform()
        sort _rand
        generate byte fake_treat = (_n <= _N/2)
        
        generate byte fake_did = fake_treat * `post_var'
        
        quietly regress `outcome_var' fake_did fake_treat `post_var', robust
        local fake_effect = _b[fake_did]
        local fake_t = `fake_effect' / _se[fake_did]
        
        post `placebo_results' (`i') (`fake_effect') (`fake_t')
        
        if mod(`i', 100) == 0 {
            display "    完成 `i' / `n_permutations' 次迭代"
        }
    }
}
else {
    * 置换检验：随机打乱处理组分配
    display ">>> 执行置换检验..."
    
    set seed 12345
    
    forvalues i = 1/`n_permutations' {
        use `original_data', clear
        
        * 随机打乱处理组
        generate double _rand = runiform()
        sort _rand
        
        * 保持处理组比例
        quietly count if `treat_var' == 1
        local n_treat = r(N)
        
        generate byte fake_treat = (_n <= `n_treat')
        generate byte fake_did = fake_treat * `post_var'
        
        quietly regress `outcome_var' fake_did fake_treat `post_var', robust
        local fake_effect = _b[fake_did]
        local fake_t = `fake_effect' / _se[fake_did]
        
        post `placebo_results' (`i') (`fake_effect') (`fake_t')
        
        if mod(`i', 100) == 0 {
            display "    完成 `i' / `n_permutations' 次迭代"
        }
    }
}

postclose `placebo_results'

* ============ 计算p值 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 计算推断p值"
display "═══════════════════════════════════════════════════════════════════════════════"

use "temp_placebo.dta", clear

* 计算置换p值
quietly count if abs(effect) >= abs(`true_effect')
local n_extreme = r(N)
quietly count
local n_total = r(N)

local perm_p = `n_extreme' / `n_total'

display ""
display ">>> 置换p值:"
display "    |安慰剂效应| >= |真实效应| 的比例: `n_extreme' / `n_total'"
display "    p值: " %6.4f `perm_p'

display "SS_METRIC|name=perm_p|value=`perm_p'"

* 安慰剂效应分布统计
quietly summarize effect
local placebo_mean = r(mean)
local placebo_sd = r(sd)

display ""
display ">>> 安慰剂效应分布:"
display "    均值: " %10.4f `placebo_mean'
display "    标准差: " %10.4f `placebo_sd'
display "    真实效应: " %10.4f `true_effect'
display "    标准化(z): " %10.4f `=(`true_effect' - `placebo_mean') / `placebo_sd''

* 导出结果
export delimited using "table_TG22_placebo_results.csv", replace
display "SS_OUTPUT_FILE|file=table_TG22_placebo_results.csv|type=table|desc=placebo_results"

* ============ 生成分布图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成安慰剂分布图"
display "═══════════════════════════════════════════════════════════════════════════════"

histogram effect, bin(30) ///
    xline(`true_effect', lcolor(red) lwidth(thick)) ///
    xtitle("安慰剂DID效应") ytitle("频数") ///
    title("DID安慰剂检验: 效应分布") ///
    note("红线=真实效应(" %6.4f `true_effect' "), 置换p值=" %5.3f `perm_p')
graph export "fig_TG22_placebo_dist.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG22_placebo_dist.png|type=figure|desc=placebo_dist"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=true_effect|value=`true_effect'"
display "SS_SUMMARY|key=perm_p|value=`perm_p'"

* 清理
capture erase "temp_placebo.dta"
if _rc != 0 { }

* 恢复原始数据
use `original_data', clear

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG22 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  安慰剂类型:      `placebo_type'"
display "  迭代次数:        " %10.0fc `n_total'
display ""
display "  真实DID效应:     " %10.4f `true_effect'
display "  安慰剂均值:      " %10.4f `placebo_mean'
display "  安慰剂标准差:    " %10.4f `placebo_sd'
display ""
display "  置换p值:         " %10.4f `perm_p'
if `perm_p' < 0.05 {
    display "  结论:            真实效应在5%水平显著"
}
else if `perm_p' < 0.10 {
    display "  结论:            真实效应在10%水平显著"
}
else {
    display "  结论:            真实效应不显著"
}
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

display "SS_TASK_END|id=TG22|status=ok|elapsed_sec=`elapsed'"
log close
