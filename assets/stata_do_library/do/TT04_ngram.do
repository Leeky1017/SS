* ==============================================================================
* SS_TEMPLATE: id=TT04  level=L2  module=T  title="N-gram"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TT04_ngram.csv type=table desc="N-gram frequency"
*   - data_TT04_ngram.dta type=data desc="N-gram data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TT04|level=L2|title=N_gram"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local text_var = "__TEXT_VAR__"
local n_gram = __N__
local top_n = __TOP_N__

if `n_gram' < 2 | `n_gram' > 5 {
    local n_gram = 2
}
if `top_n' < 10 | `top_n' > 200 {
    local top_n = 30
}

display ""
display ">>> N-gram分析参数:"
display "    文本变量: `text_var'"
display "    N: `n_gram'"
display "    Top N: `top_n'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
capture confirm string variable `text_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`text_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`text_var' not found"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 生成N-gram ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 生成`n_gram'-gram"
display "═══════════════════════════════════════════════════════════════════════════════"

generate long _doc_id = _n
local total_docs = _N

* 分词
replace `text_var' = lower(`text_var')
split `text_var', parse(" ") generate(_w)

quietly describe _w*, varlist
local word_vars = r(varlist)
local n_word_vars : word count `word_vars'

display ">>> 最大单词数/文档: `n_word_vars'"

* 生成N-gram
local max_ngram = `n_word_vars' - `n_gram' + 1
if `max_ngram' < 1 {
    local max_ngram = 1
}

tempname ngram_data
postfile `ngram_data' long doc_id str200 ngram using "temp_ngram.dta", replace

forvalues d = 1/`total_docs' {
    forvalues i = 1/`max_ngram' {
        local ngram_str ""
        forvalues j = 0/`=`n_gram'-1' {
            local word_idx = `i' + `j'
            local w = _w`word_idx'[`d']
            if "`w'" != "" {
                if "`ngram_str'" == "" {
                    local ngram_str "`w'"
                }
                else {
                    local ngram_str "`ngram_str' `w'"
                }
            }
        }
        
        * 检查是否完整N-gram
        local n_words : word count `ngram_str'
        if `n_words' == `n_gram' {
            post `ngram_data' (`d') ("`ngram_str'")
        }
    }
    
    if mod(`d', 100) == 0 {
        display "    处理文档 `d' / `total_docs'..."
    }
}

postclose `ngram_data'

* ============ N-gram频率统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: N-gram频率统计"
display "═══════════════════════════════════════════════════════════════════════════════"

use "temp_ngram.dta", clear

local total_ngrams = _N
display ">>> 总`n_gram'-gram数: `total_ngrams'"

contract ngram, freq(frequency)
gsort -frequency

local n_unique = _N
display ">>> 唯一`n_gram'-gram数: `n_unique'"

generate double proportion = frequency / `total_ngrams'

if _N > `top_n' {
    keep in 1/`top_n'
}

display ""
display ">>> Top 15 `n_gram'-gram:"
list ngram frequency proportion in 1/15, noobs

local top_ngram = ngram[1]
local top_freq = frequency[1]

display "SS_METRIC|name=total_ngrams|value=`total_ngrams'"
display "SS_METRIC|name=unique_ngrams|value=`n_unique'"
display "SS_METRIC|name=top_freq|value=`top_freq'"

export delimited using "table_TT04_ngram.csv", replace
display "SS_OUTPUT_FILE|file=table_TT04_ngram.csv|type=table|desc=ngram_freq"

save "data_TT04_ngram.dta", replace
display "SS_OUTPUT_FILE|file=data_TT04_ngram.dta|type=data|desc=ngram_data"

capture erase "temp_ngram.dta"
if _rc != 0 { }
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  文档数:          " %10.0fc `total_docs'
display "  N-gram (N=`n_gram'):"
display "    总数:          " %10.0fc `total_ngrams'
display "    唯一数:        " %10.0fc `n_unique'
display "    最高频:        `top_ngram' (`top_freq')"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=total_ngrams|value=`total_ngrams'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TT04|status=ok|elapsed_sec=`elapsed'"
log close
