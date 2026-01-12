* ==============================================================================
* SS_TEMPLATE: id=TT01  level=L2  module=T  title="Text Clean"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TT01_clean_stats.csv type=table desc="Clean stats"
*   - data_TT01_clean.dta type=data desc="Cleaned data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Text cleaning is language-dependent; define rules (punctuation/stopwords/numbers) aligned with your downstream task.
* - Preserve raw text and audit cleaning impact (length, missingness); overly aggressive regex can remove informative tokens.
* - Ensure encoding/Unicode handling is consistent (ustr* functions) and document decisions.
* 最佳实践审查（ZH）:
* - 文本清洗与语言相关；请根据下游任务明确规则（标点/停用词/数字等）。
* - 保留原始文本并审计清洗影响（长度、缺失）；过强的正则可能误删有效信息。
* - 注意编码/Unicode 一致性（使用 ustr* 函数）并记录关键决策。

* ============ 初始化 ============
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

display "SS_TASK_BEGIN|id=TT01|level=L2|title=Text_Clean"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local text_var = "__TEXT_VAR__"
local lowercase = "__LOWERCASE__"
local remove_punct = "__REMOVE_PUNCT__"
local remove_num = "__REMOVE_NUM__"

if "`lowercase'" == "" | "`lowercase'" == "__LOWERCASE__" {
    local lowercase = "yes"
}
if "`remove_punct'" == "" | "`remove_punct'" == "__REMOVE_PUNCT__" {
    local remove_punct = "yes"
}
if "`remove_num'" == "" | "`remove_num'" == "__REMOVE_NUM__" {
    local remove_num = "no"
}

display ""
display ">>> 文本清洗参数:"
display "    文本变量: `text_var'"
display "    转小写: `lowercase'"
display "    去标点: `remove_punct'"
display "    去数字: `remove_num'"

* ============ 数据加载 ============
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
* EN: Validate text variable existence/type.
* ZH: 校验文本变量存在且为字符串。

* ============ 变量检查 ============
capture confirm string variable `text_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm string variable|msg=text_var_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Clean text and export cleaned dataset + summary stats.
* ZH: 清洗文本并导出清洗后数据与统计摘要。

* ============ 原始文本统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 原始文本统计"
display "═══════════════════════════════════════════════════════════════════════════════"

generate int orig_len = strlen(`text_var')

quietly summarize orig_len
local orig_avg_len = r(mean)
local orig_max_len = r(max)

quietly count if missing(`text_var') | `text_var' == ""
local n_missing = r(N)

display ""
display ">>> 原始文本统计:"
display "    总记录数: `n_input'"
display "    缺失/空白: `n_missing'"
display "    平均长度: " %8.1f `orig_avg_len'
display "    最大长度: " %8.0f `orig_max_len'

* ============ 文本清洗 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 文本清洗"
display "═══════════════════════════════════════════════════════════════════════════════"

generate str2000 text_clean = `text_var'

* 转小写
if "`lowercase'" == "yes" {
    display ">>> 转换为小写..."
    replace text_clean = lower(text_clean)
}

* 去除标点符号
if "`remove_punct'" == "yes" {
    display ">>> 去除标点符号..."
    replace text_clean = ustrregexra(text_clean, "[^\w\s]", " ")
}

* 去除数字
if "`remove_num'" == "yes" {
    display ">>> 去除数字..."
    replace text_clean = ustrregexra(text_clean, "[0-9]+", " ")
}

* 去除多余空格
display ">>> 去除多余空格..."
replace text_clean = stritrim(text_clean)
replace text_clean = strtrim(text_clean)

* ============ 清洗后统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 清洗后统计"
display "═══════════════════════════════════════════════════════════════════════════════"

generate int clean_len = strlen(text_clean)
generate int len_change = orig_len - clean_len

quietly summarize clean_len
local clean_avg_len = r(mean)

quietly summarize len_change
local avg_removed = r(mean)
local pct_removed = 0
if `orig_avg_len' > 0 {
    local pct_removed = (`orig_avg_len' - `clean_avg_len') / `orig_avg_len' * 100
}
else {
    display "SS_RC|code=10|cmd=length_check|msg=orig_avg_len_zero|severity=warn"
}

display ""
display ">>> 清洗后统计:"
display "    清洗后平均长度: " %8.1f `clean_avg_len'
display "    平均减少字符: " %8.1f `avg_removed'
display "    长度变化比: " %8.1f `pct_removed' "%"

display "SS_METRIC|name=orig_avg_len|value=`orig_avg_len'"
display "SS_METRIC|name=clean_avg_len|value=`clean_avg_len'"
display "SS_METRIC|name=pct_len_reduction|value=`pct_removed'"

* 导出统计
preserve
clear
set obs 4
generate str30 metric = ""
generate double value = .

replace metric = "原始平均长度" in 1
replace value = `orig_avg_len' in 1
replace metric = "清洗后平均长度" in 2
replace value = `clean_avg_len' in 2
replace metric = "缺失记录数" in 3
replace value = `n_missing' in 3
replace metric = "总记录数" in 4
replace value = `n_input' in 4

export delimited using "table_TT01_clean_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_TT01_clean_stats.csv|type=table|desc=clean_stats"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT01_clean.dta", replace
display "SS_OUTPUT_FILE|file=data_TT01_clean.dta|type=data|desc=clean_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  文本统计:"
display "    原始平均长度:  " %10.1f `orig_avg_len'
display "    清洗后长度:    " %10.1f `clean_avg_len'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=clean_avg_len|value=`clean_avg_len'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=`n_missing'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TT01|status=ok|elapsed_sec=`elapsed'"
log close
