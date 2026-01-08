* ==============================================================================
* SS_TEMPLATE: id=T50  level=L0  module=J  title="Export Outputs Bundle"
* INPUTS:
*   - *.csv  role=output_files  required=no
*   - *.png  role=output_files  required=no
*   - *.dta  role=output_files  required=no
* OUTPUTS:
*   - outputs/manifest.txt type=manifest desc="File manifest"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="file operations"
* ==============================================================================
* Task ID:      T50_export_outputs_bundle
* Task Name:    输出文件打包
* Family:       J - 报告与打包
* Description:  整理输出文件到outputs子目录
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

program define ss_fail_T50
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T50|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T50|level=L0|title=Export_Outputs_Bundle"
display "SS_SUMMARY|key=template_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T50_export_outputs_bundle                                     ║"
display "║  TASK_NAME: 输出文件打包（Export Outputs Bundle）                          ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ==============================================================================
* SECTION 1: 创建输出目录
* ==============================================================================
display "SS_STEP_BEGIN|step=S01_prepare"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 创建输出目录"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 创建 outputs/ 目录"
capture mkdir "outputs"
if _rc != 0 { }
display ">>> outputs/ 目录已准备就绪"
display "SS_STEP_END|step=S01_prepare|status=ok|elapsed_sec=0"

* 初始化计数器
local n_csv = 0
local n_dta = 0
local n_png = 0
local n_other = 0

* ==============================================================================
* SECTION 2: 复制CSV文件
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_copy_files"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 复制CSV文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
local csv_files : dir "." files "*.csv"
foreach file of local csv_files {
    if "`file'" != "data.csv" {
        capture copy "`file'" "outputs/`file'", replace
        if !_rc {
            display "  ✓ `file'"
            local n_csv = `n_csv' + 1
        }
    }
}
display ">>> CSV文件: `n_csv' 个"

* ==============================================================================
* SECTION 3: 复制DTA文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 复制DTA文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
local dta_files : dir "." files "*.dta"
foreach file of local dta_files {
    capture copy "`file'" "outputs/`file'", replace
    if !_rc {
        display "  ✓ `file'"
        local n_dta = `n_dta' + 1
    }
}
display ">>> DTA文件: `n_dta' 个"

* ==============================================================================
* SECTION 4: 复制PNG图形文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 复制PNG图形文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
local png_files : dir "." files "*.png"
foreach file of local png_files {
    capture copy "`file'" "outputs/`file'", replace
    if !_rc {
        display "  ✓ `file'"
        local n_png = `n_png' + 1
    }
}
display ">>> PNG文件: `n_png' 个"

* ==============================================================================
* SECTION 5: 复制其他图形文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 复制其他图形文件（PDF/EPS）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
* PDF
local pdf_files : dir "." files "*.pdf"
foreach file of local pdf_files {
    capture copy "`file'" "outputs/`file'", replace
    if !_rc {
        display "  ✓ `file'"
        local n_other = `n_other' + 1
    }
}

* EPS
local eps_files : dir "." files "*.eps"
foreach file of local eps_files {
    capture copy "`file'" "outputs/`file'", replace
    if !_rc {
        display "  ✓ `file'"
        local n_other = `n_other' + 1
    }
}
display ">>> 其他图形文件: `n_other' 个"

display "SS_STEP_END|step=S02_copy_files|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 6: 生成文件清单
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_manifest"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 生成文件清单"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成 manifest.txt"

file open manifest using "outputs/manifest.txt", write replace
file write manifest "╔══════════════════════════════════════════════════════════════════╗" _n
file write manifest "║                       输出文件清单                               ║" _n
file write manifest "╚══════════════════════════════════════════════════════════════════╝" _n
file write manifest _n
file write manifest "生成时间: `c(current_date)' `c(current_time)'" _n
file write manifest "Stata版本: `c(stata_version)'" _n
file write manifest _n
file write manifest "════════════════════════════════════════════════════════════════════" _n
file write manifest _n

* CSV文件
file write manifest "CSV 表格文件 (`n_csv' 个):" _n
foreach file of local csv_files {
    if "`file'" != "data.csv" {
        file write manifest "  - `file'" _n
    }
}

* DTA文件
file write manifest _n "DTA 数据文件 (`n_dta' 个):" _n
foreach file of local dta_files {
    file write manifest "  - `file'" _n
}

* PNG文件
file write manifest _n "PNG 图形文件 (`n_png' 个):" _n
foreach file of local png_files {
    file write manifest "  - `file'" _n
}

* 其他图形
if `n_other' > 0 {
    file write manifest _n "其他图形文件 (`n_other' 个):" _n
    foreach file of local pdf_files {
        file write manifest "  - `file'" _n
    }
    foreach file of local eps_files {
        file write manifest "  - `file'" _n
    }
}

file write manifest _n "════════════════════════════════════════════════════════════════════" _n
local n_total = `n_csv' + `n_dta' + `n_png' + `n_other'
file write manifest "总计: `n_total' 个文件" _n

file close manifest
display ">>> 文件清单已生成: outputs/manifest.txt"
display "SS_OUTPUT_FILE|file=outputs/manifest.txt|type=manifest|desc=file_manifest"
display "SS_STEP_END|step=S03_manifest|status=ok|elapsed_sec=0"

* ==============================================================================
* 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T50 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "打包统计:"
display "  - CSV表格:         " %10.0fc `n_csv' " 个"
display "  - DTA数据:         " %10.0fc `n_dta' " 个"
display "  - PNG图形:         " %10.0fc `n_png' " 个"
display "  - 其他图形:        " %10.0fc `n_other' " 个"
display "  ─────────────────────────"
display "  - 总计:            " %10.0fc `n_total' " 个"
display ""
display "输出目录: outputs/"
display "文件清单: outputs/manifest.txt"
display ""
display ">>> Python层可使用以下代码打包:"
display "    import shutil"
display "    shutil.make_archive('results', 'zip', 'outputs')"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
local n_total = `n_csv' + `n_dta' + `n_png' + `n_other'
display "SS_SUMMARY|key=n_csv|value=`n_csv'"
display "SS_SUMMARY|key=n_png|value=`n_png'"
display "SS_SUMMARY|key=n_total|value=`n_total'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T50|status=ok|elapsed_sec=`elapsed'"

log close
