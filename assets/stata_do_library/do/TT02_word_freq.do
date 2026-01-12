* ==============================================================================
* SS_TEMPLATE: id=TT02  level=L2  module=T  title="Word Freq"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TT02_word_freq.csv type=table desc="Word frequency"
*   - data_TT02_freq.dta type=data desc="Freq data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Tokenization is language-dependent; whitespace splitting is a simplification and may be inappropriate for Chinese or noisy text.
* - Consider stopwords, stemming/lemmatization, and normalization (case, punctuation) aligned with your research question.
* - Report sensitivity to preprocessing choices (min frequency, top-N cutoff).
* 最佳实践审查（ZH）:
* - 分词与语言相关；按空格切分是简化做法，对中文/噪声文本可能不适用。
* - 建议结合研究问题处理停用词、词干化/词形还原与规范化（大小写、标点）。
* - 建议报告不同预处理设置（最小词频、Top-N）的敏感性。

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

display "SS_TASK_BEGIN|id=TT02|level=L2|title=Word_Freq"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local text_var = "__TEXT_VAR__"
local top_n_raw = "__TOP_N__"
local min_freq_raw = "__MIN_FREQ__"
local top_n = real("`top_n_raw'")
local min_freq = real("`min_freq_raw'")

if missing(`top_n') | `top_n' < 10 | `top_n' > 500 {
    local top_n = 50
}
local top_n = floor(`top_n')
if missing(`min_freq') | `min_freq' < 1 | `min_freq' > 100 {
    local min_freq = 2
}
local min_freq = floor(`min_freq')

display ""
display ">>> 词频统计参数:"
display "    文本变量: `text_var'"
display "    Top N: `top_n'"
display "    最小词频: `min_freq'"

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
    display "SS_RC|code=200|cmd=confirm string variable|msg=text_var_not_found|var=`text_var'|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Tokenize text and compute word frequency table.
* ZH: 对文本分词并统计词频表。

* ============ 分词和词频统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 分词处理"
display "═══════════════════════════════════════════════════════════════════════════════"

* 合并所有文本
generate long _doc_id = _n
local total_docs = _N

* 展开单词
split `text_var', parse(" ") generate(_word)

* 获取生成的单词变量
quietly describe _word*, varlist
local word_vars = r(varlist)
local n_word_vars : word count `word_vars'

display ">>> 最大单词数/文档: `n_word_vars'"

* 重塑为长格式
reshape long _word, i(_doc_id) j(_word_pos)
drop if missing(_word) | _word == ""

* 标准化
replace _word = lower(_word)
replace _word = strtrim(_word)

local total_words = _N
display ">>> 总词数: `total_words'"

* ============ 计算词频 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 词频统计"
display "═══════════════════════════════════════════════════════════════════════════════"

if `total_words' <= 0 {
    display "SS_RC|code=112|cmd=tokenize|msg=no_tokens_found|severity=warn"
    gen str32 word = ""
    gen long frequency = .
    gen double proportion = .
    keep word frequency proportion
    keep in 1/0

    local n_unique = 0
    local top_word = ""
    local max_freq = 0
}
else {
contract _word, freq(_freq)
gsort -_freq

local n_unique = _N
display ">>> 唯一词数: `n_unique'"

* 过滤低频词
drop if _freq < `min_freq'
local n_filtered = _N

display ">>> 过滤后词数 (freq>=`min_freq'): `n_filtered'"

if _N == 0 {
    display "SS_RC|code=112|cmd=contract|msg=no_tokens_after_filter|severity=warn"
    gen str32 word = ""
    gen long frequency = .
    gen double proportion = .
    keep word frequency proportion
    keep in 1/0

    local top_word = ""
    local max_freq = 0
}
else {
    * 计算词频占比
    generate double _prop = _freq / `total_words'

    * 取Top N
    if _N > `top_n' {
        keep in 1/`top_n'
    }

    rename _word word
    rename _freq frequency
    rename _prop proportion
    keep word frequency proportion

    display ""
    display ">>> Top 20 高频词:"
    local show_n = min(20, _N)
    list word frequency proportion in 1/`show_n', noobs

    * 统计
    quietly summarize frequency
    local max_freq = r(max)
    local top_word = word[1]
}
}

display ""
display ">>> 最高频词: `top_word' (频率=`max_freq')"

display "SS_METRIC|name=total_words|value=`total_words'"
display "SS_METRIC|name=unique_words|value=`n_unique'"
display "SS_METRIC|name=max_freq|value=`max_freq'"

* 导出词频表
export delimited using "table_TT02_word_freq.csv", replace
display "SS_OUTPUT_FILE|file=table_TT02_word_freq.csv|type=table|desc=word_freq"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT02_freq.dta", replace
display "SS_OUTPUT_FILE|file=data_TT02_freq.dta|type=data|desc=freq_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  文档数:          " %10.0fc `total_docs'
display "  总词数:          " %10.0fc `total_words'
display "  唯一词数:        " %10.0fc `n_unique'
display "  最高频词:        `top_word' (`max_freq'次)"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=total_words|value=`total_words'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TT02|status=ok|elapsed_sec=`elapsed'"
log close
