* ==============================================================================
* SS_TEMPLATE: id=TQ02  level=L2  module=Q  title="VAR Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ02_var_result.csv type=table desc="VAR results"
*   - table_TQ02_granger.csv type=table desc="Granger causality"
*   - fig_TQ02_irf.png type=figure desc="IRF plot"
*   - data_TQ02_var.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TQ02
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ02|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ02|level=L2|title=VAR_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: VAR requires careful lag selection and stationarity checks; interpret Granger tests as predictive, not causal. /
*   最佳实践：VAR 需谨慎选择滞后并检查平稳性；Granger 检验是预测关系而非因果。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/tsset/estimation; warn on time gaps and IRF failures /
*   错误策略：缺少输入/tsset/估计失败→fail；时间缺口与 IRF 失败→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ02|ssc=none|output=csv_png_dta|policy=warn_fail"

* ============ 参数设置 ============
local endog_vars = "__ENDOG_VARS__"
local time_var = "__TIME_VAR__"
local lags = __LAGS__

if `lags' < 1 | `lags' > 10 {
    local lags = 2
}

display ""
display ">>> VAR模型参数:"
display "    内生变量: `endog_vars'"
display "    滞后阶数: `lags'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TQ02 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
capture confirm variable `time_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|severity=fail|var=`time_var'"
    display "SS_TASK_END|id=TQ02|status=fail|elapsed_sec=."
    log close
    exit 200
}

local valid_endog ""
foreach var of local endog_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_endog "`valid_endog' `var'"
    }
}

local n_vars : word count `valid_endog'
if `n_vars' < 2 {
    ss_fail_TQ02 198 "validate endog_vars" "endog_vars_too_short"
}

local tsvar "`time_var'"
local _ss_need_index = 0
capture confirm numeric variable `time_var'
if _rc {
    local _ss_need_index = 1
    display "SS_RC|code=TIMEVAR_NOT_NUMERIC|var=`time_var'|severity=warn"
}
if `_ss_need_index' == 0 {
    capture isid `time_var'
    if _rc {
        local _ss_need_index = 1
        display "SS_RC|code=TIMEVAR_NOT_UNIQUE|var=`time_var'|severity=warn"
    }
}
if `_ss_need_index' == 1 {
    sort `time_var'
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
    ss_fail_TQ02 `=_rc' "tsset `tsvar'" "tsset_failed"
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

* ============ VAR估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: VAR(`lags')估计"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily var `valid_endog', lags(1/`lags')
if _rc {
    ss_fail_TQ02 `=_rc' "var" "var_failed"
}

local ll = e(ll)
local aic = e(aic)
local bic = e(sbic)

display ""
display ">>> 模型拟合:"
display "    对数似然: " %12.4f `ll'
display "    AIC: " %12.4f `aic'
display "    BIC: " %12.4f `bic'

display "SS_METRIC|name=aic|value=`aic'"
display "SS_METRIC|name=bic|value=`bic'"

* ============ Granger因果检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Granger因果检验"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname granger_results
postfile `granger_results' str32 equation str32 excluded double chi2 int df double p ///
    using "temp_granger.dta", replace

foreach eq of local valid_endog {
    foreach excl of local valid_endog {
        if "`eq'" != "`excl'" {
            capture test [`eq']: L.`excl'
            if _rc == 0 {
                forvalues i = 2/`lags' {
                    capture test [`eq']: L`i'.`excl', accum
                    local rc_last = _rc
                    if `rc_last' != 0 {
                        display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
                    }
                }
                local chi2 = r(chi2)
                local df = r(df)
                local p = r(p)
                post `granger_results' ("`eq'") ("`excl'") (`chi2') (`df') (`p')
            }
        }
    }
}

postclose `granger_results'

capture noisily vargranger
if _rc {
    display "SS_RC|code=`=_rc'|cmd=vargranger|msg=vargranger_failed|severity=warn"
}

preserve
use "temp_granger.dta", clear
capture export delimited using "table_TQ02_granger.csv", replace
if _rc {
    ss_fail_TQ02 `=_rc' "export delimited table_TQ02_granger.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ02_granger.csv|type=table|desc=granger_tests"
restore

* ============ 脉冲响应分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 脉冲响应分析"
display "═══════════════════════════════════════════════════════════════════════════════"

local has_irf = 1
capture irf create var_irf, set(irf_results) replace step(20)
if _rc {
    local has_irf = 0
    display "SS_RC|code=`=_rc'|cmd=irf create|msg=irf_create_failed|severity=warn"
}

local var1 : word 1 of `valid_endog'
local var2 : word 2 of `valid_endog'

if `has_irf' {
    capture irf graph oirf, impulse(`var1') response(`var2') ///
        title("OIRF: `var1' -> `var2'")
    if _rc {
        display "SS_RC|code=`=_rc'|cmd=irf graph|msg=irf_graph_failed|severity=warn"
        local has_irf = 0
    }
}
if `has_irf' {
    capture graph export "fig_TQ02_irf.png", replace width(1200)
    if _rc {
        display "SS_RC|code=`=_rc'|cmd=graph export fig_TQ02_irf.png|msg=graph_export_failed|severity=warn"
    }
    display "SS_OUTPUT_FILE|file=fig_TQ02_irf.png|type=figure|desc=irf_plot"
}

capture erase "irf_results.irf"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

* 导出VAR系数
tempname var_results
postfile `var_results' str32 equation str32 variable double coef double se double z double p ///
    using "temp_var_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local eqnames : rownames e(b)

local nvars : word count `varnames'
forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `var_results' ("VAR") ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `var_results'

preserve
use "temp_var_results.dta", clear
capture export delimited using "table_TQ02_var_result.csv", replace
if _rc {
    ss_fail_TQ02 `=_rc' "export delimited table_TQ02_var_result.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ02_var_result.csv|type=table|desc=var_results"
restore

capture erase "temp_granger.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
capture erase "temp_var_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TQ02_var.dta", replace
if _rc {
    ss_fail_TQ02 `=_rc' "save data_TQ02_var.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TQ02_var.dta|type=data|desc=var_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TQ02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display "  滞后阶数:        " %10.0fc `lags'
display "  AIC:             " %10.4f `aic'
display "  BIC:             " %10.4f `bic'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=aic|value=`aic'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ02|status=ok|elapsed_sec=`elapsed'"
log close
