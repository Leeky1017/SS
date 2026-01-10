* ==============================================================================
* SS_TEMPLATE: id=TL10  level=L1  module=L  title="FScore"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL10_fscore.csv type=table desc="F-Score results"
*   - data_TL10_fscore.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Dechow F-Score is a misstatement risk screening model; confirm inputs are constructed consistently with the intended definition.
* - Probabilities depend on calibration; use as relative ranking or screening, not an absolute claim.
* - Outliers/missingness in inputs can dominate the score; consider winsorization and missingness checks.
* 最佳实践审查（ZH）:
* - Dechow F-Score 是舞弊/错报风险筛查模型；请确认输入变量的构造与定义一致。
* - 概率受校准影响；更适合作为相对排序或筛查信号，而非绝对判断。
* - 输入变量的极端值/缺失会显著影响结果；建议截尾并检查缺失比例。
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

display "SS_TASK_BEGIN|id=TL10|level=L1|title=FScore"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local rsst = "__RSST__"
local chg_rec = "__CHG_REC__"
local chg_inv = "__CHG_INV__"
local soft = "__SOFT__"
local chg_cash = "__CHG_CASH__"
local chg_roa = "__CHG_ROA__"
local issue = "__ISSUE__"

display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL10|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and numeric types.
* ZH: 校验关键变量存在且为数值型。
local required_vars "`rsst' `chg_rec' `chg_inv' `soft' `chg_cash' `chg_roa' `issue'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL10|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
    capture confirm numeric variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm numeric variable `v'|msg=var_not_numeric|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL10|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Compute F-Score and implied probability via logistic transform.
* ZH: 计算 F-Score 并通过 logistic 变换得到风险概率。

generate fscore = -7.893 + 0.790*`rsst' + 2.518*`chg_rec' + 1.191*`chg_inv' ///
    + 1.979*`soft' + 0.171*`chg_cash' - 0.932*`chg_roa' + 1.029*`issue'

generate prob_misstate = exp(fscore) / (1 + exp(fscore))

summarize fscore prob_misstate
local mean_fscore = r(mean)
count if missing(fscore)
local n_missing_fscore = r(N)
display "SS_METRIC|name=mean_fscore|value=`mean_fscore'"
display "SS_METRIC|name=n_missing_fscore|value=`n_missing_fscore'"

preserve
clear
set obs 1
gen str32 model = "Dechow F-Score"
gen double mean_fscore = `mean_fscore'
export delimited using "table_TL10_fscore.csv", replace
display "SS_OUTPUT_FILE|file=table_TL10_fscore.csv|type=table|desc=fscore_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL10_fscore.dta", replace
display "SS_OUTPUT_FILE|file=data_TL10_fscore.dta|type=data|desc=fscore_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_fscore|value=`mean_fscore'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL10|status=ok|elapsed_sec=`elapsed'"
log close
