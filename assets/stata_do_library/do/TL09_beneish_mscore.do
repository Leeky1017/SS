* ==============================================================================
* SS_TEMPLATE: id=TL09  level=L1  module=L  title="Beneish MScore"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL09_mscore.csv type=table desc="M-Score results"
*   - data_TL09_mscore.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Beneish M-Score inputs are ratios/indexes; confirm definitions match the original paper and your dataset construction.
* - Thresholds (e.g., -1.78) vary by context and calibration; interpret flags as screening, not proof of manipulation.
* - Outliers in component ratios can dominate the score; consider winsorization and missingness checks.
* 最佳实践审查（ZH）:
* - Beneish M-Score 的输入多为比率/指数；请确认变量口径与论文/样本构造一致。
* - 阈值（如 -1.78）存在情境差异；应将识别结果视为筛查信号而非确定结论。
* - 组成比率的极端值会主导得分；建议截尾并关注缺失值比例。
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

display "SS_TASK_BEGIN|id=TL09|level=L1|title=Beneish_MScore"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local dsri = "__DSRI__"
local gmi = "__GMI__"
local aqi = "__AQI__"
local sgi = "__SGI__"
local depi = "__DEPI__"
local sgai = "__SGAI__"
local lvgi = "__LVGI__"
local tata = "__TATA__"

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
    display "SS_TASK_END|id=TL09|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and numeric types.
* ZH: 校验关键变量存在且为数值型。
local required_vars "`dsri' `gmi' `aqi' `sgi' `depi' `sgai' `lvgi' `tata'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL09|status=fail|elapsed_sec=`elapsed'"
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
        display "SS_TASK_END|id=TL09|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Compute Beneish M-Score and a simple screening flag (mscore > -1.78).
* ZH: 计算 Beneish M-Score 并给出简单筛查标记（mscore > -1.78）。

generate mscore = -4.84 + 0.920*`dsri' + 0.528*`gmi' + 0.404*`aqi' + 0.892*`sgi' ///
    + 0.115*`depi' - 0.172*`sgai' + 4.679*`tata' - 0.327*`lvgi'

generate fraud_flag = (mscore > -1.78)

summarize mscore
local mean_mscore = r(mean)
count if fraud_flag == 1
local n_fraud = r(N)
count if missing(mscore)
local n_missing_mscore = r(N)
display "SS_METRIC|name=mean_mscore|value=`mean_mscore'"
display "SS_METRIC|name=n_fraud|value=`n_fraud'"
display "SS_METRIC|name=n_missing_mscore|value=`n_missing_mscore'"

preserve
clear
set obs 1
gen str32 model = "Beneish M-Score"
gen double mean_mscore = `mean_mscore'
gen int n_fraud = `n_fraud'
export delimited using "table_TL09_mscore.csv", replace
display "SS_OUTPUT_FILE|file=table_TL09_mscore.csv|type=table|desc=mscore_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL09_mscore.dta", replace
display "SS_OUTPUT_FILE|file=data_TL09_mscore.dta|type=data|desc=mscore_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_mscore|value=`mean_mscore'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL09|status=ok|elapsed_sec=`elapsed'"
log close
