* ==============================================================================
* SS_TEMPLATE: id=TA05  level=L0  module=A  title="Var Generate"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA05_newvar_summary.csv type=table desc="New variable summary"
*   - data_TA05_generated.dta type=data desc="Data with new variables"
*   - data_TA05_generated.csv type=data desc="Data CSV with new variables"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="panel commands"
* ==============================================================================
* Task ID:      TA05_var_generate
* Task Name:    变量生成器
* Family:       A - 数据管理
* Description:  生成滞后变量、差分变量、增长率变量
* 
* Placeholders: __SOURCE_VARS__    - 源变量列表
*               __ID_VAR__         - 个体标识变量
*               __TIME_VAR__       - 时间变量
*               __LAG_PERIODS__    - 滞后期数
*               __DIFF_ORDER__     - 差分阶数
*               __GROWTH_TYPE__    - 增长率类型
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=log_close_failed|severity=warn"
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=TA05|level=L0|title=Var_Generate"
display "SS_METRIC|name=task_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local source_vars = "__SOURCE_VARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local lag_periods = "__LAG_PERIODS__"
local diff_order = __DIFF_ORDER__
local growth_type = "__GROWTH_TYPE__"

* 参数默认值处理
if `diff_order' <= 0 | `diff_order' > 2 {
    local diff_order = 1
}
if "`growth_type'" == "" | ("`growth_type'" != "pct" & "`growth_type'" != "log") {
    local growth_type = "pct"
}

display ""
display ">>> 变量生成参数:"
display "    源变量: `source_vars'"
display "    ID变量: `id_var'"
display "    时间变量: `time_var'"
display "    滞后期数: `lag_periods'"
display "    差分阶数: `diff_order'"
display "    增长率类型: `growth_type'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 变量检查 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
* 检查ID变量
capture confirm variable `id_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable `id_var'|msg=id_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

* 检查时间变量
capture confirm variable `time_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable `time_var'|msg=time_var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

* 检查源变量
local valid_vars ""
foreach var of local source_vars {
    capture confirm numeric variable `var'
    if _rc {
        display ">>> 警告: `var' 不存在或非数值，跳过"
        display "SS_RC|code=0|cmd=confirm numeric variable `var'|msg=source_var_invalid_skipped|severity=warn"
    }
    else {
        local valid_vars "`valid_vars' `var'"
    }
}

if "`valid_vars'" == "" {
    display "SS_RC|code=200|cmd=validate_source_vars|msg=no_valid_source_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 设置面板结构 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成变量"
display "═══════════════════════════════════════════════════════════════════════════════"

* 排序并设置面板
sort `id_var' `time_var'
capture confirm string variable `id_var'
if !_rc {
    capture drop _ss_panel_id
    capture encode `id_var', generate(_ss_panel_id)
    local rc = _rc
    if `rc' != 0 {
        display "SS_RC|code=`rc'|cmd=encode `id_var'|msg=id_encode_failed|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = round(r(t1))
        display "SS_TASK_END|id=TA05|status=fail|elapsed_sec=`elapsed'"
        log close
        exit 200
    }
    local id_var "_ss_panel_id"
}
capture confirm string variable `time_var'
if !_rc {
    capture drop _ss_time_id
    capture destring `time_var', generate(_ss_time_id) force
    local rc = _rc
    if `rc' != 0 {
        display "SS_RC|code=`rc'|cmd=destring `time_var'|msg=time_destring_failed|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = round(r(t1))
        display "SS_TASK_END|id=TA05|status=fail|elapsed_sec=`elapsed'"
        log close
        exit 200
    }
    local time_var "_ss_time_id"
}
capture duplicates drop `id_var' `time_var', force
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=duplicates drop `id_var' `time_var'|msg=dedup_failed|severity=warn"
}
capture xtset `id_var' `time_var'
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=xtset `id_var' `time_var'|msg=xtset_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

quietly xtdescribe
local n_panels = r(n)
local n_periods = r(max)
display ">>> 面板结构: `n_panels' 个个体, 最大 `n_periods' 个时期"
display "SS_METRIC|name=n_panels|value=`n_panels'"

* ============ 生成滞后变量 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成滞后变量"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建新变量统计存储
tempname newvars
postfile `newvars' str32 newvar str32 source str20 type long n_valid double mean double sd ///
    using "temp_newvar_summary.dta", replace

local n_newvars = 0
local new_var_list ""

* 解析滞后期数
local lag_list ""
if "`lag_periods'" != "" {
    local lag_periods = subinstr("`lag_periods'", ",", " ", .)
    foreach l of local lag_periods {
        capture confirm integer number `l'
        if !_rc & `l' > 0 {
            local lag_list "`lag_list' `l'"
        }
    }
}

if "`lag_list'" == "" {
    local lag_list "1"
}

foreach var of local valid_vars {
    foreach lag of local lag_list {
        local newvar = "`var'_L`lag'"
        display ">>> 生成: `newvar' = L`lag'.`var'"
        
        generate double `newvar' = L`lag'.`var'
        
        quietly summarize `newvar'
        local n_valid = r(N)
        local mean_val = r(mean)
        local sd_val = r(sd)
        
        post `newvars' ("`newvar'") ("`var'") ("lag`lag'") (`n_valid') (`mean_val') (`sd_val')
        
        local n_newvars = `n_newvars' + 1
        local new_var_list "`new_var_list' `newvar'"
        
        display "    N = `n_valid', Mean = " %9.4f `mean_val'
    }
}

* ============ 生成差分变量 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 生成差分变量"
display "═══════════════════════════════════════════════════════════════════════════════"

foreach var of local valid_vars {
    * 一阶差分
    local newvar = "`var'_D1"
    display ">>> 生成: `newvar' = D.`var'"
    
    generate double `newvar' = D.`var'
    
    quietly summarize `newvar'
    post `newvars' ("`newvar'") ("`var'") ("diff1") (r(N)) (r(mean)) (r(sd))
    
    local n_newvars = `n_newvars' + 1
    local new_var_list "`new_var_list' `newvar'"
    display "    N = " r(N) ", Mean = " %9.4f r(mean)
    
    * 二阶差分（如果需要）
    if `diff_order' >= 2 {
        local newvar = "`var'_D2"
        display ">>> 生成: `newvar' = D2.`var'"
        
        generate double `newvar' = D2.`var'
        
        quietly summarize `newvar'
        post `newvars' ("`newvar'") ("`var'") ("diff2") (r(N)) (r(mean)) (r(sd))
        
        local n_newvars = `n_newvars' + 1
        local new_var_list "`new_var_list' `newvar'"
        display "    N = " r(N) ", Mean = " %9.4f r(mean)
    }
}

* ============ 生成增长率变量 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成增长率变量"
display "═══════════════════════════════════════════════════════════════════════════════"

foreach var of local valid_vars {
    if "`growth_type'" == "pct" {
        * 百分比增长率: (x_t - x_{t-1}) / x_{t-1} * 100
        local newvar = "`var'_growth"
        display ">>> 生成: `newvar' = (`var' - L.`var') / L.`var' * 100"
        
        generate double `newvar' = (`var' - L.`var') / L.`var' * 100 if L.`var' != 0
        
        quietly summarize `newvar'
        post `newvars' ("`newvar'") ("`var'") ("growth_pct") (r(N)) (r(mean)) (r(sd))
    }
    else {
        * 对数增长率: ln(x_t) - ln(x_{t-1}) * 100
        local newvar = "`var'_lngrowth"
        display ">>> 生成: `newvar' = (ln(`var') - ln(L.`var')) * 100"
        
        generate double `newvar' = (ln(`var') - ln(L.`var')) * 100 if `var' > 0 & L.`var' > 0
        
        quietly summarize `newvar'
        post `newvars' ("`newvar'") ("`var'") ("growth_log") (r(N)) (r(mean)) (r(sd))
    }
    
    local n_newvars = `n_newvars' + 1
    local new_var_list "`new_var_list' `newvar'"
    display "    N = " r(N) ", Mean = " %9.4f r(mean)
}

postclose `newvars'

display ""
display ">>> 总共生成新变量: `n_newvars' 个"
display "SS_METRIC|name=n_newvars|value=`n_newvars'"

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出新变量统计摘要
preserve
use "temp_newvar_summary.dta", clear
export delimited using "table_TA05_newvar_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TA05_newvar_summary.csv|type=table|desc=newvar_summary"
restore

* 导出数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

save "data_TA05_generated.dta", replace
display "SS_OUTPUT_FILE|file=data_TA05_generated.dta|type=data|desc=generated_data"

export delimited using "data_TA05_generated.csv", replace
display "SS_OUTPUT_FILE|file=data_TA05_generated.csv|type=data|desc=generated_csv"

* 清理临时文件
capture erase "temp_newvar_summary.dta"
local rc = _rc
if `rc' != 0 & `rc' != 601 {
    display "SS_RC|code=`rc'|cmd=erase temp_newvar_summary.dta|msg=cleanup_failed|severity=warn"
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  源变量数:        " %10.0fc `: word count `valid_vars''
display "  新增变量数:      " %10.0fc `n_newvars'
display "  面板个体数:      " %10.0fc `n_panels'
display ""
display "  新增变量类型:"
display "    - 滞后变量 (L1, L2, ...)"
display "    - 差分变量 (D1" cond(`diff_order'>=2, ", D2", "") ")"
display "    - 增长率变量 (`growth_type')"
display ""
display "  新增变量列表:"
local i = 0
foreach v of local new_var_list {
    local i = `i' + 1
    if `i' <= 10 {
        display "    - `v'"
    }
}
if `i' > 10 {
    display "    ... 共 `i' 个变量"
}
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_newvars|value=`n_newvars'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA05|status=ok|elapsed_sec=`elapsed'"
log close
