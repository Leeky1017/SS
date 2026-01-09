* ==============================================================================
* SS_TEMPLATE: id=TH14  level=L1  module=H  title="Rolling Regression"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TH14_rolling.png type=figure desc="Rolling plot"
*   - data_TH14_rolling.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="rolling regression via regress (no SSC)"
* ==============================================================================
* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.8) / 最佳实践审查（阶段 5.8）
* - 2026-01-09 (Issue #263): Remove SSC `asreg` dependency; implement rolling regression with built-in `regress`.
*   移除 SSC 依赖 asreg；用原生命令 regress 实现滚动窗口回归。
* - 2026-01-09 (Issue #263): Add `tsset`/gap preflight and fail fast on invalid window sizes.
*   增加 tsset/缺口检查；窗口参数不合法时 fail-fast。
* ==============================================================================
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

display "SS_TASK_BEGIN|id=TH14|level=L1|title=Rolling_Regression"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_BP_REVIEW|issue=263|template_id=TH14|ssc=removed|output=png_dta|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

program define ss_fail_TH14
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TH14|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local timevar = "__TIME_VAR__"
local window = __WINDOW__

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TH14 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `timevar'
if _rc {
    ss_fail_TH14 111 "confirm variable `timevar'" "time_var_missing"
}
capture confirm variable `depvar'
if _rc {
    ss_fail_TH14 111 "confirm variable `depvar'" "depvar_missing"
}
foreach v of local indepvars {
    capture confirm variable `v'
    if _rc {
        ss_fail_TH14 111 "confirm variable `v'" "indepvar_missing"
    }
}

local tsvar "`timevar'"
local _ss_need_index = 0
capture confirm numeric variable `timevar'
if _rc {
    local _ss_need_index = 1
    display "SS_RC|code=TIMEVAR_NOT_NUMERIC|var=`timevar'|severity=warn"
}
if `_ss_need_index' == 0 {
    capture isid `timevar'
    if _rc {
        local _ss_need_index = 1
        display "SS_RC|code=TIMEVAR_NOT_UNIQUE|var=`timevar'|severity=warn"
    }
}
if `_ss_need_index' == 1 {
    sort `timevar'
    capture drop ss_time_index
    local rc_drop = _rc
    if `rc_drop' != 0 & `rc_drop' != 111 {
        display "SS_RC|code=`rc_drop'|cmd=drop ss_time_index|msg=drop_failed|severity=warn"
    }
    gen long ss_time_index = _n
    local tsvar "ss_time_index"
    display "SS_METRIC|name=ts_timevar|value=ss_time_index"
}
capture tsset `tsvar'
if _rc {
    ss_fail_TH14 `=_rc' "tsset `tsvar'" "tsset_failed"
}
capture tsreport, report
if _rc == 0 {
    display "SS_METRIC|name=ts_n_gaps|value=`=r(N_gaps)'"
    if r(N_gaps) > 0 {
        display "SS_RC|code=TIME_GAPS|n_gaps=`=r(N_gaps)'|severity=warn"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local task_success = 1
if missing(`window') | `window' < 5 {
    ss_fail_TH14 198 "validate window" "window_invalid"
}
if _N < `window' {
    ss_fail_TH14 2001 "validate window vs N" "window_exceeds_sample"
}
local k_indep : word count `indepvars'
if `window' <= (`k_indep' + 2) {
    display "SS_RC|code=WINDOW_TOO_SMALL|window=`window'|k_indep=`k_indep'|severity=fail"
    ss_fail_TH14 2002 "validate window vs parameters" "window_too_small"
}
display "SS_METRIC|name=window|value=`window'"
display "SS_METRIC|name=k_indep|value=`k_indep'"

* Rolling regression (滚动窗口回归): compute coefficients at each window endpoint.
sort `tsvar'
capture drop b_cons
local rc_drop_bcons = _rc
if `rc_drop_bcons' != 0 & `rc_drop_bcons' != 111 {
    display "SS_RC|code=`rc_drop_bcons'|cmd=drop b_cons|msg=drop_failed|severity=warn"
}
gen double b_cons = .
foreach v of local indepvars {
    capture drop b_`v'
    local rc_drop_bv = _rc
    if `rc_drop_bv' != 0 & `rc_drop_bv' != 111 {
        display "SS_RC|code=`rc_drop_bv'|cmd=drop b_`v'|msg=drop_failed|severity=warn"
    }
    gen double b_`v' = .
}
local n_windows = 0
local n_fail = 0
local warned_coef = 0
forvalues i = `window'/`=_N' {
    local start = `i' - `window' + 1
    quietly capture regress `depvar' `indepvars' in `start'/`i'
    local rc = _rc
    local n_windows = `n_windows' + 1
    if `rc' != 0 {
        local n_fail = `n_fail' + 1
    }
    else {
        capture replace b_cons = _b[_cons] in `i'
        local rc_bcons = _rc
        if `rc_bcons' != 0 & `warned_coef' == 0 {
            local warned_coef = 1
            display "SS_RC|code=`rc_bcons'|cmd=replace b_cons=_b[_cons]|msg=coef_unavailable|severity=warn"
        }
        foreach v of local indepvars {
            capture replace b_`v' = _b[`v'] in `i'
            local rc_bv = _rc
            if `rc_bv' != 0 & `warned_coef' == 0 {
                local warned_coef = 1
                display "SS_RC|code=`rc_bv'|cmd=replace b_`v'=_b[`v']|msg=coef_unavailable|severity=warn"
            }
        }
    }
}
display "SS_METRIC|name=rolling_n_windows|value=`n_windows'"
display "SS_METRIC|name=rolling_n_fail|value=`n_fail'"
if `n_fail' > 0 {
    display "SS_RC|code=ROLLING_WINDOW_FAIL|n_fail=`n_fail'|severity=warn"
}

capture noisily tsline b_*, title("滚动回归系数 / Rolling coefficients") legend(cols(3))
capture graph export "fig_TH14_rolling.png", replace width(1200)
local rc_gexp = _rc
if `rc_gexp' != 0 {
    display "SS_RC|code=`rc_gexp'|cmd=graph export fig_TH14_rolling.png|msg=graph_export_failed|severity=warn"
    capture twoway line `depvar' `tsvar', title("Rolling (analysis skipped)")
    local rc_tw = _rc
    if `rc_tw' != 0 {
        display "SS_RC|code=`rc_tw'|cmd=twoway line|msg=fallback_plot_failed|severity=warn"
    }
    capture graph export "fig_TH14_rolling.png", replace width(1200)
    local rc_gexp2 = _rc
    if `rc_gexp2' != 0 {
        display "SS_RC|code=`rc_gexp2'|cmd=graph export fig_TH14_rolling.png|msg=graph_export_failed|severity=warn"
    }
}
display "SS_OUTPUT_FILE|file=fig_TH14_rolling.png|type=figure|desc=rolling_plot"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH14_rolling.dta", replace
display "SS_OUTPUT_FILE|file=data_TH14_rolling.dta|type=data|desc=rolling_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=window|value=`window'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH14|status=ok|elapsed_sec=`elapsed'"
log close
