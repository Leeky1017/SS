* ==============================================================================
* SS_TEMPLATE: id=TB05  level=L0  module=B  title="Group Mean Trend"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TB05_group_trend.png type=graph desc="Group mean trend plot"
*   - data_TB05_trend.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="collapse and twoway"
* ==============================================================================
* Task ID:      TB05_group_mean_trend
* Placeholders: __YVAR__, __TIME_VAR__, __GROUP_VAR__
* Stata:        18.0+
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.4) ============
* - [x] Validate vars and avoid hard-coded group values (避免把分组变量硬编码为 0/1)
* - [x] Missingness summary (缺失值摘要)
* - [x] No SSC dependencies (无需 SSC)
* - [x] Bilingual notes for key steps (关键步骤中英文注释)
* - 2026-01-08: Use `by()` faceting for arbitrary groups (支持任意分组水平)

capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TB05|level=L0|title=Group_Mean_Trend"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local yvar = "__YVAR__"
local timevar = "__TIME_VAR__"
local group_var = "__GROUP_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Validate variables / 校验变量
capture confirm variable `yvar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `yvar'|msg=var_not_found:yvar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `timevar'|msg=var_not_found:time_var|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `group_var'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `group_var'|msg=var_not_found:group_var|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `yvar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `yvar'|msg=not_numeric:yvar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `timevar'|msg=not_numeric:time_var|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly count if missing(`yvar') | missing(`timevar') | missing(`group_var')
local n_missing_total = r(N)
display "SS_METRIC|name=n_missing|value=`n_missing_total'"

* Collapse to group-time means / 按时间与分组求均值
capture noisily collapse (mean) `yvar', by(`timevar' `group_var')
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=collapse|msg=collapse_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
sort `group_var' `timevar'

* Plot by group (faceted) / 分组分面趋势图
capture noisily twoway (line `yvar' `timevar', sort lcolor(navy) lwidth(medium)), ///
    by(`group_var', title("分组均值趋势图 / Group Mean Trend") note("")) ///
    xtitle("`timevar'") ytitle("Mean `yvar'")
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=twoway line by(group)|msg=plot_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
graph export "fig_TB05_group_trend.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TB05_group_trend.png|type=graph|desc=group_trend"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TB05_trend.dta", replace
display "SS_OUTPUT_FILE|file=data_TB05_trend.dta|type=data|desc=trend_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=yvar|value=`yvar'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TB05|status=ok|elapsed_sec=`elapsed'"
log close
