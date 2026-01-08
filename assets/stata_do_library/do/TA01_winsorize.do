* ==============================================================================
* SS_TEMPLATE: id=TA01  level=L1  module=A  title="Winsorize"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA01_winsor_summary.csv type=table desc="Winsorize summary"
*   - data_TA01_winsorized.dta type=data desc="Winsorized data"
*   - table_TA01_winsorized.csv type=table desc="Winsorized data CSV"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="percentile-based winsor/trim (egen pctile)"
* ==============================================================================
* Task ID:      TA01_winsorize
* Task Name:    缩尾处理
* Family:       A - 数据管理
* Description:  对指定数值变量进行缩尾处理
* 
* Placeholders: __WINSOR_VARS__     - 需要缩尾的变量列表
*               __LOWER_PCTL__      - 下分位数（默认1）
*               __UPPER_PCTL__      - 上分位数（默认99）
*               __TRIM_OR_WINSOR__  - trim或winsor（默认winsor）
*               __BY_VAR__          - 分组变量（可选）
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.3)
* - 2026-01-08: Replace SSC `winsor2` with built-in percentile cutpoints (egen pctile) for winsor/trim (用原生命令替代 winsor2).
* - 2026-01-08: Use deterministic cutpoints and record modified counts (使用确定性分位点并记录处理数量).
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
display "SS_TASK_BEGIN|id=TA01|level=L1|title=Winsorize"
display "SS_METRIC|name=task_version|value=2.1.0"

* ============ 依赖检测 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local winsor_vars = "__WINSOR_VARS__"
local lower_pctl = __LOWER_PCTL__
local upper_pctl = __UPPER_PCTL__
local method = "__TRIM_OR_WINSOR__"
local by_var = "__BY_VAR__"

* 参数默认值处理
if `lower_pctl' <= 0 | `lower_pctl' >= 50 {
    local lower_pctl = 1
}
if `upper_pctl' <= 50 | `upper_pctl' >= 100 {
    local upper_pctl = 99
}
if "`method'" == "" | ("`method'" != "trim" & "`method'" != "winsor") {
    local method = "winsor"
}

display ""
display ">>> 缩尾参数设置:"
display "    变量: `winsor_vars'"
display "    下分位: `lower_pctl'%"
display "    上分位: `upper_pctl'%"
display "    方法: `method'"
if "`by_var'" != "" {
    display "    分组变量: `by_var'"
}

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
local datafile "data.dta"

capture confirm file "`datafile'"
if _rc {
    capture confirm file "data.csv"
    if _rc {
        display "SS_RC|code=601|cmd=confirm file data.dta/data.csv|msg=input_file_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = round(r(t1))
        display "SS_TASK_END|id=TA01|status=fail|elapsed_sec=`elapsed'"
        log close
        exit 601
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
    display "SS_OUTPUT_FILE|file=`datafile'|type=data|desc=converted_from_csv"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}

local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

* ============ 变量检查 ============
local valid_vars ""
local invalid_vars ""

foreach var of local winsor_vars {
    capture confirm variable `var'
    if _rc {
        local invalid_vars "`invalid_vars' `var'"
    }
    else {
        capture confirm numeric variable `var'
        if _rc {
            display ">>> 警告: `var' 不是数值变量，跳过"
            display "SS_RC|code=0|cmd=confirm numeric variable `var'|msg=not_numeric_skipped|severity=warn"
        }
        else {
            local valid_vars "`valid_vars' `var'"
        }
    }
}

if "`invalid_vars'" != "" {
    display ">>> 警告: 以下变量不存在: `invalid_vars'"
    display "SS_RC|code=0|cmd=confirm variable <list>|msg=var_not_found|severity=warn"
}

if "`valid_vars'" == "" {
    display "SS_RC|code=200|cmd=validate_vars|msg=no_valid_numeric_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

* 检查分组变量
if "`by_var'" != "" {
    capture confirm variable `by_var'
    if _rc {
        display "SS_RC|code=0|cmd=confirm variable `by_var'|msg=by_var_not_found_ignored|severity=warn"
        local by_var ""
    }
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 缩尾前统计 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 缩尾前描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建结果存储
tempname results
postfile `results' str32 variable str10 stage n mean sd min p1 p5 p25 p50 p75 p95 p99 max ///
    using "temp_winsor_stats.dta", replace

foreach var of local valid_vars {
    quietly summarize `var', detail
    local n = r(N)
    local mean = r(mean)
    local sd = r(sd)
    local min = r(min)
    local p1 = r(p1)
    local p5 = r(p5)
    local p25 = r(p25)
    local p50 = r(p50)
    local p75 = r(p75)
    local p95 = r(p95)
    local p99 = r(p99)
    local max = r(max)
    
    post `results' ("`var'") ("before") (`n') (`mean') (`sd') (`min') (`p1') (`p5') ///
        (`p25') (`p50') (`p75') (`p95') (`p99') (`max')
    
    display ""
    display "变量: `var'"
    display "  N = `n', Mean = " %9.3f `mean' ", SD = " %9.3f `sd'
    display "  Min = " %9.3f `min' ", P1 = " %9.3f `p1' ", P99 = " %9.3f `p99' ", Max = " %9.3f `max'
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 执行缩尾处理 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 执行缩尾处理"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_winsorized = 0

foreach var of local valid_vars {
    display ""
    display ">>> 处理变量: `var'"

    * Compute percentile cutpoints (supports arbitrary percentiles; summarize, detail does not)
    if "`by_var'" != "" {
        tempvar __lo __hi
        bysort `by_var': egen double `__lo' = pctile(`var'), p(`lower_pctl')
        bysort `by_var': egen double `__hi' = pctile(`var'), p(`upper_pctl')

        quietly count if !missing(`var') & (`var' < `__lo' | `var' > `__hi')
        local n_extreme_before = r(N)

        if "`method'" == "trim" {
            replace `var' = . if !missing(`var') & (`var' < `__lo' | `var' > `__hi')
        }
        else {
            replace `var' = `__lo' if !missing(`var') & `var' < `__lo'
            replace `var' = `__hi' if !missing(`var') & `var' > `__hi'
        }
        drop `__lo' `__hi'
    }
    else {
        quietly _pctile `var' if !missing(`var'), p(`lower_pctl' `upper_pctl')
        local p_lower = r(r1)
        local p_upper = r(r2)

        quietly count if !missing(`var') & (`var' < `p_lower' | `var' > `p_upper')
        local n_extreme_before = r(N)

        if "`method'" == "trim" {
            replace `var' = . if !missing(`var') & (`var' < `p_lower' | `var' > `p_upper')
        }
        else {
            replace `var' = `p_lower' if !missing(`var') & `var' < `p_lower'
            replace `var' = `p_upper' if !missing(`var') & `var' > `p_upper'
        }
    }
    
    * 统计缩尾后
    quietly summarize `var', detail
    local n_after = r(N)
    local mean_after = r(mean)
    local sd_after = r(sd)
    
    display "  缩尾前极端值: `n_extreme_before' 个"
    display "  缩尾后 N = `n_after', Mean = " %9.3f `mean_after' ", SD = " %9.3f `sd_after'
    
    local n_winsorized = `n_winsorized' + `n_extreme_before'
    
    * 记录缩尾后统计
    post `results' ("`var'") ("after") (r(N)) (r(mean)) (r(sd)) (r(min)) (r(p1)) (r(p5)) ///
        (r(p25)) (r(p50)) (r(p75)) (r(p95)) (r(p99)) (r(max))
}

postclose `results'

display ""
display ">>> 总共处理极端值: `n_winsorized' 个"
display "SS_METRIC|name=n_winsorized|value=`n_winsorized'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 输出统计摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 加载统计结果并导出
preserve
use "temp_winsor_stats.dta", clear
export delimited using "table_TA01_winsor_summary.csv", replace
display ">>> 缩尾统计摘要已导出"
display "SS_OUTPUT_FILE|file=table_TA01_winsor_summary.csv|type=table|desc=winsor_summary"
restore

* 导出缩尾后数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TA01_winsorized.dta", replace
display "SS_OUTPUT_FILE|file=data_TA01_winsorized.dta|type=data|desc=winsorized_data"

export delimited using "table_TA01_winsorized.csv", replace
display "SS_OUTPUT_FILE|file=table_TA01_winsorized.csv|type=table|desc=winsorized_csv"

* 清理临时文件
capture erase "temp_winsor_stats.dta"
local rc = _rc
if `rc' != 0 & `rc' != 601 {
    display "SS_RC|code=`rc'|cmd=erase temp_winsor_stats.dta|msg=cleanup_failed|severity=warn"
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  处理变量数:      " %10.0fc `: word count `valid_vars''
display "  缩尾极端值数:    " %10.0fc `n_winsorized'
display "  缩尾方法:        `method'"
display "  分位数范围:      `lower_pctl'% - `upper_pctl'%"
display ""
display "  输出文件:"
display "    - table_TA01_winsor_summary.csv"
display "    - data_TA01_winsorized.dta"
display "    - table_TA01_winsorized.csv"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = `n_input' - `n_output'
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_winsorized|value=`n_winsorized'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA01|status=ok|elapsed_sec=`elapsed'"
log close
