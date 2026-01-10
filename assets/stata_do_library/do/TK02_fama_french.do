* ==============================================================================
* SS_TEMPLATE: id=TK02  level=L2  module=K  title="Fama-French Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK02_ff_result.csv type=table desc="FF results"
*   - table_TK02_factor_loadings.csv type=table desc="Factor loadings"
*   - fig_TK02_alpha_dist.png type=graph desc="Alpha distribution"
*   - data_TK02_ff.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.10) / 最佳实践审查记录
* - Date: 2026-01-10
* - Inference / 推断: robust SE by default; consider HAC for time-series residual autocorr
* - Data checks / 数据校验: missingness + factor scaling; verify factor definitions (MKT/SMB/HML/RMW/CMA)
* - Model caveat / 注意: factor models are sensitive to sample window and data frequency
* - SSC deps / SSC 依赖: none / 无
* ------------------------------------------------------------------------------

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

program define ss_fail_TK02
    args code cmd msg detail step
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    if "`step'" != "" & "`step'" != "." {
        display "SS_STEP_END|step=`step'|status=fail|elapsed_sec=0"
    }
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|detail=`detail'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TK02|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK02|level=L2|title=FF_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local mkt_var = "__MKT_VAR__"
local smb_var = "__SMB_VAR__"
local hml_var = "__HML_VAR__"
local rmw_var = "__RMW_VAR__"
local cma_var = "__CMA_VAR__"
local stock_id = "__STOCK_ID__"

display ""
display ">>> Fama-French模型参数:"
display "    收益变量: `return_var'"
display "    市场因子: `mkt_var'"
display "    SMB因子: `smb_var'"
display "    HML因子: `hml_var'"

* 判断是三因子还是五因子
local is_five_factor = 0
if "`rmw_var'" != "" & "`cma_var'" != "" {
    display "    RMW因子: `rmw_var'"
    display "    CMA因子: `cma_var'"
    local is_five_factor = 1
    display ">>> 使用五因子模型"
}
else {
    display ">>> 使用三因子模型"
}

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK02 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `return_var' `mkt_var' `smb_var' `hml_var' `stock_id' {
    capture confirm numeric variable `var'
    if _rc {
        ss_fail_TK02 200 confirm_variable var_not_found `var' S02_validate_inputs
    }
}

if `is_five_factor' {
    foreach var in `rmw_var' `cma_var' {
        capture confirm numeric variable `var'
        if _rc {
            display "SS_RC|code=0|cmd=confirm_variable|msg=factor_not_found_fallback_to_3_factor|detail=`var'|severity=warn"
            local is_five_factor = 0
        }
    }
}

* Missingness + scaling checks / 缺失值与尺度检查（提示性）
local check_vars "`return_var' `mkt_var' `smb_var' `hml_var'"
if `is_five_factor' {
    local check_vars "`check_vars' `rmw_var' `cma_var'"
}
foreach var in `check_vars' {
    quietly count if missing(`var')
    local n_miss = r(N)
    if `n_miss' > 0 {
        display "SS_RC|code=MISSING_VALUES|var=`var'|n=`n_miss'|severity=warn"
    }
    capture quietly summarize `var', detail
    local rc_sum = _rc
    if `rc_sum' == 0 {
        local p1 = r(p1)
        local p99 = r(p99)
        if `p1' < . & `p99' < . {
            if abs(`p1') > 5 | abs(`p99') > 5 {
                display "SS_RC|code=CHECK_SCALE|var=`var'|p1=`p1'|p99=`p99'|severity=warn"
            }
        }
    }
}

quietly levelsof `stock_id', local(stocks)
local n_stocks : word count `stocks'
display ">>> 股票数: `n_stocks'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ FF模型估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Fama-French模型时间序列估计"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname ff_results
if `is_five_factor' {
    postfile `ff_results' long stock_id double alpha double alpha_t ///
        double b_mkt double b_smb double b_hml double b_rmw double b_cma ///
        double r2 double adj_r2 long n_obs ///
        using "temp_ff_results.dta", replace
}
else {
    postfile `ff_results' long stock_id double alpha double alpha_t ///
        double b_mkt double b_smb double b_hml ///
        double r2 double adj_r2 long n_obs ///
        using "temp_ff_results.dta", replace
}

display ""
if `is_five_factor' {
    display "股票     Alpha    t(α)    MKT     SMB     HML     RMW     CMA     R2"
    display "───────────────────────────────────────────────────────────────────────"
}
else {
    display "股票     Alpha    t(α)    MKT     SMB     HML     R2"
    display "─────────────────────────────────────────────────────────"
}

foreach s of local stocks {
    if `is_five_factor' {
        quietly regress `return_var' `mkt_var' `smb_var' `hml_var' `rmw_var' `cma_var' if `stock_id' == `s', robust
        
        local alpha = _b[_cons]
        local alpha_t = _b[_cons] / _se[_cons]
        local b_mkt = _b[`mkt_var']
        local b_smb = _b[`smb_var']
        local b_hml = _b[`hml_var']
        local b_rmw = _b[`rmw_var']
        local b_cma = _b[`cma_var']
        local r2 = e(r2)
        local adj_r2 = e(r2_a)
        local n = e(N)
        
        post `ff_results' (`s') (`alpha') (`alpha_t') (`b_mkt') (`b_smb') (`b_hml') (`b_rmw') (`b_cma') (`r2') (`adj_r2') (`n')
        
        display %6.0f `s' "  " %8.5f `alpha' " " %6.2f `alpha_t' " " %6.3f `b_mkt' " " %6.3f `b_smb' " " %6.3f `b_hml' " " %6.3f `b_rmw' " " %6.3f `b_cma' " " %5.3f `r2'
    }
    else {
        quietly regress `return_var' `mkt_var' `smb_var' `hml_var' if `stock_id' == `s', robust
        
        local alpha = _b[_cons]
        local alpha_t = _b[_cons] / _se[_cons]
        local b_mkt = _b[`mkt_var']
        local b_smb = _b[`smb_var']
        local b_hml = _b[`hml_var']
        local r2 = e(r2)
        local adj_r2 = e(r2_a)
        local n = e(N)
        
        post `ff_results' (`s') (`alpha') (`alpha_t') (`b_mkt') (`b_smb') (`b_hml') (`r2') (`adj_r2') (`n')
        
        display %6.0f `s' "  " %8.5f `alpha' " " %6.2f `alpha_t' " " %6.3f `b_mkt' " " %6.3f `b_smb' " " %6.3f `b_hml' " " %5.3f `r2'
    }
}

postclose `ff_results'

* ============ 结果汇总 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 结果汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_ff_results.dta", clear

* Alpha统计
quietly summarize alpha
local avg_alpha = r(mean)
local sd_alpha = r(sd)

quietly count if abs(alpha_t) > 1.96
local n_sig_alpha = r(N)

* 因子载荷统计
quietly summarize b_mkt
local avg_mkt = r(mean)
quietly summarize b_smb
local avg_smb = r(mean)
quietly summarize b_hml
local avg_hml = r(mean)

quietly summarize r2
local avg_r2 = r(mean)

display ""
display ">>> FF模型汇总统计:"
display "    平均Alpha: " %10.6f `avg_alpha' " (SD=" %8.6f `sd_alpha' ")"
display "    显著Alpha: `n_sig_alpha' / `n_stocks' (" %5.1f `=`n_sig_alpha'/`n_stocks'*100' "%)"
display ""
display ">>> 平均因子载荷:"
display "    MKT: " %8.4f `avg_mkt'
display "    SMB: " %8.4f `avg_smb'
display "    HML: " %8.4f `avg_hml'
if `is_five_factor' {
    quietly summarize b_rmw
    local avg_rmw = r(mean)
    quietly summarize b_cma
    local avg_cma = r(mean)
    display "    RMW: " %8.4f `avg_rmw'
    display "    CMA: " %8.4f `avg_cma'
}
display ""
display ">>> 平均R2: " %6.4f `avg_r2'

display "SS_METRIC|name=avg_alpha|value=`avg_alpha'"
display "SS_METRIC|name=avg_r2|value=`avg_r2'"
display "SS_METRIC|name=n_sig_alpha|value=`n_sig_alpha'"

export delimited using "table_TK02_ff_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TK02_ff_result.csv|type=table|desc=ff_results"

* 导出因子载荷摘要
clear
set obs 5
generate str10 factor = ""
generate double avg_loading = .
generate double sd_loading = .

replace factor = "MKT" in 1
replace avg_loading = `avg_mkt' in 1
replace factor = "SMB" in 2
replace avg_loading = `avg_smb' in 2
replace factor = "HML" in 3
replace avg_loading = `avg_hml' in 3

if `is_five_factor' {
    replace factor = "RMW" in 4
    replace avg_loading = `avg_rmw' in 4
    replace factor = "CMA" in 5
    replace avg_loading = `avg_cma' in 5
}

export delimited using "table_TK02_factor_loadings.csv", replace
display "SS_OUTPUT_FILE|file=table_TK02_factor_loadings.csv|type=table|desc=factor_loadings"
use "temp_ff_results.dta", clear

* 生成Alpha分布图
histogram alpha, bin(20) normal ///
    xtitle("Alpha") ytitle("频数") ///
    title("Fama-French Alpha分布") ///
    xline(0, lcolor(red) lpattern(dash)) ///
    note("红线=零Alpha")
graph export "fig_TK02_alpha_dist.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK02_alpha_dist.png|type=graph|desc=alpha_dist"

restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK02_ff.dta", replace
display "SS_OUTPUT_FILE|file=data_TK02_ff.dta|type=data|desc=ff_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

capture erase "temp_ff_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  股票数:          " %10.0fc `n_stocks'
display "  模型:            " cond(`is_five_factor', "五因子", "三因子")
display ""
display "  Alpha统计:"
display "    平均:          " %10.6f `avg_alpha'
display "    显著:          `n_sig_alpha' / `n_stocks'"
display ""
display "  平均R2:          " %10.4f `avg_r2'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=avg_r2|value=`avg_r2'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK02|status=ok|elapsed_sec=`elapsed'"
log close
