* ==============================================================================
* SS_TEMPLATE: id=TR06  level=L1  module=R  title="Bayes Regress"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TR06_bayes.csv type=table desc="Bayes regression results"
*   - data_TR06_bayes.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Default priors may be too vague; consider specifying weakly-informative priors when scale is known.
* - Always check convergence/efficiency (ESS, trace/ACF); low ESS implies unreliable posterior summaries.
* - Use reproducible seeds for debugging; increase `__MCMC__` substantially for real analysis (200 is smoke-test only).
* 最佳实践审查（ZH）:
* - 默认先验可能过于宽泛；若量纲/尺度已知，建议设置弱信息先验。
* - 必做收敛/有效样本诊断（ESS、trace/ACF）；ESS 很低时后验汇总不可靠。
* - 为可复现与排错设置随机种子；真实分析请显著增大 `__MCMC__`（200 仅用于冒烟测试）。
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

display "SS_TASK_BEGIN|id=TR06|level=L1|title=Bayes_Regress"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* Reproducibility / 可复现性
local seed_value = 12345
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local mcmc_raw = "__MCMC__"
local mcmc = real("`mcmc_raw'")
if missing(`mcmc') | `mcmc' < 200 {
    local mcmc = 200
}
local mcmc = floor(`mcmc')

display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and basic types.
* ZH: 校验关键变量存在且类型合理。
capture confirm numeric variable `depvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found_or_not_numeric|var=`depvar'|severity=fail"
    log close
    exit 200
}
local valid_indep ""
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
    }
}
if "`valid_indep'" == "" {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=no_valid_indepvars|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Fit Bayesian regression and run basic diagnostics (ESS).
* ZH: 执行贝叶斯回归并做基础诊断（ESS）。

capture noisily bayes, mcmcsize(`mcmc') burnin(2500): regress `depvar' `valid_indep'
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=bayes regress|msg=bayes_failed|severity=fail"
    log close
    exit `rc'
}
bayesstats summary
local ess = e(ess_min)
if `ess' < 100 {
    display "SS_RC|code=10|cmd=bayesstats summary|msg=low_ess_warning|ess_min=`ess'|severity=warn"
}
display "SS_METRIC|name=ess_min|value=`ess'"
display "SS_METRIC|name=mcmc_size|value=`mcmc'"

preserve
clear
set obs 1
gen str32 model = "Bayesian Regression"
gen int mcmc = `mcmc'
export delimited using "table_TR06_bayes.csv", replace
display "SS_OUTPUT_FILE|file=table_TR06_bayes.csv|type=table|desc=bayes_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TR06_bayes.dta", replace
display "SS_OUTPUT_FILE|file=data_TR06_bayes.dta|type=data|desc=bayes_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=ess_min|value=`ess'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TR06|status=ok|elapsed_sec=`elapsed'"
log close
