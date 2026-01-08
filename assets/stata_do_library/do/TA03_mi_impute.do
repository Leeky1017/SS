* ==============================================================================
* SS_TEMPLATE: id=TA03  level=L1  module=A  title="MI Impute"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA03_missing_pattern.csv type=table desc="Missing pattern"
*   - table_TA03_impute_diag.csv type=table desc="Imputation diagnostics"
*   - data_TA03_imputed.dta type=data desc="Imputed data (MI format)"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="mi module"
* ==============================================================================
* Task ID:      TA03_mi_impute
* Task Name:    缺失值多重插补
* Family:       A - 数据管理
* Description:  使用多重插补方法处理缺失数据
* 
* Placeholders: __IMPUTE_VARS__    - 需要插补的变量列表
*               __PREDICTOR_VARS__ - 预测变量列表
*               __N_IMPUTATIONS__  - 插补次数
*               __METHOD__         - 插补方法
*               __ID_VAR__         - 个体标识变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands - mi module)
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.3) ============
* - 2026-01-08: Emphasize MI assumptions and reproducibility (seed, m) (强调多重插补假设与可复现性).

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
display "SS_TASK_BEGIN|id=TA03|level=L1|title=MI_Impute"
display "SS_METRIC|name=task_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local impute_vars = "__IMPUTE_VARS__"
local predictor_vars = "__PREDICTOR_VARS__"
local n_imputations = __N_IMPUTATIONS__
local method = "__METHOD__"
local id_var = "__ID_VAR__"

* 参数默认值处理
if `n_imputations' <= 0 | `n_imputations' > 100 {
    local n_imputations = 5
}
if "`method'" == "" | ("`method'" != "regress" & "`method'" != "pmm" & "`method'" != "logit" & "`method'" != "ologit" & "`method'" != "mlogit") {
    local method = "pmm"
}

display ""
display ">>> 多重插补参数设置:"
display "    待插补变量: `impute_vars'"
display "    预测变量: `predictor_vars'"
display "    插补次数: `n_imputations'"
display "    插补方法: `method'"
if "`id_var'" != "" {
    display "    ID变量: `id_var'"
}

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA03|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

* ============ 变量检查 ============
local valid_impute_vars ""
local valid_predictor_vars ""

* 检查待插补变量
foreach var of local impute_vars {
    capture confirm numeric variable `var'
    if _rc {
        display ">>> 警告: `var' 不存在或非数值，跳过"
        display "SS_RC|code=0|cmd=confirm numeric variable `var'|msg=impute_var_invalid_skipped|severity=warn"
    }
    else {
        local valid_impute_vars "`valid_impute_vars' `var'"
    }
}

if "`valid_impute_vars'" == "" {
    display "SS_RC|code=200|cmd=validate_impute_vars|msg=no_valid_impute_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA03|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

* 检查预测变量
foreach var of local predictor_vars {
    capture confirm variable `var'
    if !_rc {
        local valid_predictor_vars "`valid_predictor_vars' `var'"
    }
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 缺失模式分析 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 缺失模式分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建缺失模式统计
tempname misspattern
postfile `misspattern' str32 variable long n_total long n_missing double pct_missing ///
    using "temp_missing_pattern.dta", replace

local total_missing = 0
foreach var of local valid_impute_vars {
    quietly count
    local n_total = r(N)
    quietly count if missing(`var')
    local n_missing = r(N)
    local pct_missing = (`n_missing' / `n_total') * 100
    
    post `misspattern' ("`var'") (`n_total') (`n_missing') (`pct_missing')
    
    display ""
    display "变量: `var'"
    display "  总观测数: `n_total'"
    display "  缺失数: `n_missing' (" %5.2f `pct_missing' "%)"
    
    local total_missing = `total_missing' + `n_missing'
}
postclose `misspattern'

display ""
display ">>> 总缺失值数量: `total_missing'"
display "SS_METRIC|name=n_missing_total|value=`total_missing'"

* 导出缺失模式
preserve
use "temp_missing_pattern.dta", clear
export delimited using "table_TA03_missing_pattern.csv", replace
display "SS_OUTPUT_FILE|file=table_TA03_missing_pattern.csv|type=table|desc=missing_pattern"
restore

* ============ 设置MI数据结构 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 设置多重插补数据结构"
display "═══════════════════════════════════════════════════════════════════════════════"

* 设置mi数据
mi set wide
display ">>> MI数据结构已设置为wide格式"

* 注册待插补变量
mi register imputed `valid_impute_vars'
display ">>> 已注册待插补变量: `valid_impute_vars'"

* 注册完整变量（预测变量）
if "`valid_predictor_vars'" != "" {
    mi register regular `valid_predictor_vars'
    display ">>> 已注册预测变量: `valid_predictor_vars'"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 执行多重插补 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 执行多重插补"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 开始插补，共 `n_imputations' 次..."
display ">>> 插补方法: `method'"

* 构建插补命令
local impute_cmd ""
foreach var of local valid_impute_vars {
    if "`valid_predictor_vars'" != "" {
        local impute_cmd "`impute_cmd' (`method') `var' = `valid_predictor_vars'"
    }
    else {
        local impute_cmd "`impute_cmd' (`method') `var'"
    }
}

* 执行链式方程插补
capture noisily mi impute chained `impute_cmd', add(`n_imputations') rseed(12345)

if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=mi impute chained|msg=mi_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA03|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

display ""
display ">>> 多重插补完成"

* ============ 插补诊断 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 插补诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建诊断统计
tempname diagresults
postfile `diagresults' str32 variable long m double mean_obs double mean_imp double sd_obs double sd_imp ///
    using "temp_impute_diag.dta", replace

foreach var of local valid_impute_vars {
    * 原始数据统计
    quietly summarize `var' if _mi_m == 0 & !missing(`var')
    local mean_obs = r(mean)
    local sd_obs = r(sd)
    
    * 各插补数据集统计
    forvalues m = 1/`n_imputations' {
        quietly summarize `var' if _mi_m == `m'
        local mean_imp = r(mean)
        local sd_imp = r(sd)
        
        post `diagresults' ("`var'") (`m') (`mean_obs') (`mean_imp') (`sd_obs') (`sd_imp')
    }
    
    display ""
    display "变量: `var'"
    display "  观测值均值: " %9.4f `mean_obs' " (SD = " %9.4f `sd_obs' ")"
    display "  插补后均值: " %9.4f `mean_imp' " (SD = " %9.4f `sd_imp' ")"
}
postclose `diagresults'

* 导出诊断结果
preserve
use "temp_impute_diag.dta", clear
export delimited using "table_TA03_impute_diag.csv", replace
display "SS_OUTPUT_FILE|file=table_TA03_impute_diag.csv|type=table|desc=impute_diagnostics"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"
restore

* ============ 保存插补数据 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 保存结果"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_METRIC|name=n_imputations|value=`n_imputations'"

save "data_TA03_imputed.dta", replace
display "SS_OUTPUT_FILE|file=data_TA03_imputed.dta|type=data|desc=imputed_data"

* 清理临时文件
capture erase "temp_missing_pattern.dta"
local rc = _rc
if `rc' != 0 & `rc' != 601 {
    display "SS_RC|code=`rc'|cmd=erase temp_missing_pattern.dta|msg=cleanup_failed|severity=warn"
}
capture erase "temp_impute_diag.dta"
local rc = _rc
if `rc' != 0 & `rc' != 601 {
    display "SS_RC|code=`rc'|cmd=erase temp_impute_diag.dta|msg=cleanup_failed|severity=warn"
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  插补变量数:      " %10.0fc `: word count `valid_impute_vars''
display "  总缺失值数:      " %10.0fc `total_missing'
display "  插补次数:        " %10.0fc `n_imputations'
display "  插补方法:        `method'"
display ""
display "  输出文件:"
display "    - table_TA03_missing_pattern.csv  (缺失模式)"
display "    - table_TA03_impute_diag.csv      (插补诊断)"
display "    - data_TA03_imputed.dta           (MI数据)"
display ""
display "  使用提示:"
display "    后续分析使用 mi estimate: 前缀运行回归"
display "    例如: mi estimate: regress y x1 x2"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=total_missing|value=`total_missing'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=`total_missing'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA03|status=ok|elapsed_sec=`elapsed'"
log close
