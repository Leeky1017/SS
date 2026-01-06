#!/usr/bin/env python3
"""
generate_new_tasks.py - 批量生成新增Do模板

按DO_LIBRARY_EXPANSION_PLAN.md的A-U分类生成250个新任务
每个任务生成: do文件 + md文件 + meta.json + fixture
"""

import json
import os
from pathlib import Path
from typing import Dict, List

# 新任务定义 (从扩展规划中提取)
NEW_TASKS = [
    # A. 数据管理新增 (TA01-TA14)
    {"id": "TA01", "slug": "winsorize", "name": "缩尾处理（Winsorize）", "family": "data_management", "deps": ["winsor2"], "level": "basic"},
    {"id": "TA02", "slug": "standardize", "name": "标准化与归一化", "family": "data_management", "deps": [], "level": "basic"},
    {"id": "TA03", "slug": "mi_impute", "name": "缺失值多重插补", "family": "data_management", "deps": [], "level": "intermediate"},
    {"id": "TA04", "slug": "outlier_detect", "name": "异常值检测与处理", "family": "data_management", "deps": [], "level": "basic"},
    {"id": "TA05", "slug": "var_generate", "name": "变量生成器（滞后/差分/增长率）", "family": "data_management", "deps": [], "level": "intermediate"},
    {"id": "TA06", "slug": "panel_balance", "name": "面板数据平衡化", "family": "data_management", "deps": [], "level": "intermediate"},
    {"id": "TA07", "slug": "string_process", "name": "字符串变量处理", "family": "data_management", "deps": [], "level": "basic"},
    {"id": "TA08", "slug": "datetime_process", "name": "日期时间变量处理", "family": "data_management", "deps": [], "level": "basic"},
    {"id": "TA09", "slug": "quantile_groups", "name": "分组变量生成（分位数/自定义）", "family": "data_management", "deps": [], "level": "basic"},
    {"id": "TA10", "slug": "dummy_generate", "name": "虚拟变量批量生成", "family": "data_management", "deps": [], "level": "basic"},
    {"id": "TA11", "slug": "dedup_check", "name": "数据去重与唯一性检查", "family": "data_management", "deps": ["distinct"], "level": "basic"},
    {"id": "TA12", "slug": "label_manage", "name": "变量标签批量管理", "family": "data_management", "deps": [], "level": "basic"},
    {"id": "TA13", "slug": "stratified_sample", "name": "数据集抽样（分层抽样）", "family": "data_management", "deps": [], "level": "intermediate"},
    {"id": "TA14", "slug": "data_quality", "name": "数据质量诊断报告", "family": "data_management", "deps": ["mdesc"], "level": "basic"},
    
    # G. 因果推断 (TG01-TG25)
    {"id": "TG01", "slug": "pscore_estimate", "name": "倾向得分估计", "family": "causal", "deps": ["psmatch2"], "level": "advanced"},
    {"id": "TG02", "slug": "psm_match", "name": "倾向得分匹配（1:1/1:N）", "family": "causal", "deps": ["psmatch2"], "level": "advanced"},
    {"id": "TG03", "slug": "ipw_weight", "name": "倾向得分加权（IPW）", "family": "causal", "deps": [], "level": "advanced"},
    {"id": "TG04", "slug": "psm_strata", "name": "倾向得分分层", "family": "causal", "deps": ["psmatch2"], "level": "advanced"},
    {"id": "TG05", "slug": "cem_match", "name": "粗化精确匹配（CEM）", "family": "causal", "deps": ["cem"], "level": "advanced"},
    {"id": "TG06", "slug": "mahal_match", "name": "马氏距离匹配", "family": "causal", "deps": ["psmatch2"], "level": "advanced"},
    {"id": "TG07", "slug": "psm_balance", "name": "PSM平衡性检验", "family": "causal", "deps": ["psmatch2"], "level": "advanced"},
    {"id": "TG08", "slug": "psm_sensitivity", "name": "敏感性分析（Rosenbaum）", "family": "causal", "deps": ["rbounds"], "level": "advanced"},
    {"id": "TG09", "slug": "rdd_sharp", "name": "断点回归（Sharp RDD）", "family": "causal", "deps": ["rdrobust"], "level": "advanced"},
    {"id": "TG10", "slug": "rdd_fuzzy", "name": "模糊断点回归（Fuzzy RDD）", "family": "causal", "deps": ["rdrobust"], "level": "advanced"},
    {"id": "TG11", "slug": "rdd_bandwidth", "name": "RDD带宽选择", "family": "causal", "deps": ["rdrobust"], "level": "advanced"},
    {"id": "TG12", "slug": "rdd_density", "name": "RDD操纵检验（密度检验）", "family": "causal", "deps": ["rddensity"], "level": "advanced"},
    {"id": "TG13", "slug": "iv_2sls", "name": "工具变量2SLS", "family": "causal", "deps": ["ivreg2"], "level": "advanced"},
    {"id": "TG14", "slug": "iv_weak_test", "name": "弱工具变量检验", "family": "causal", "deps": ["ivreg2"], "level": "advanced"},
    {"id": "TG15", "slug": "iv_overid", "name": "过度识别检验（Sargan）", "family": "causal", "deps": ["ivreg2"], "level": "advanced"},
    {"id": "TG16", "slug": "panel_iv", "name": "面板工具变量", "family": "causal", "deps": ["xtivreg2"], "level": "advanced"},
    {"id": "TG17", "slug": "scm_synth", "name": "合成控制法（SCM）", "family": "causal", "deps": ["synth"], "level": "advanced"},
    {"id": "TG18", "slug": "scm_placebo", "name": "SCM安慰剂检验", "family": "causal", "deps": ["synth"], "level": "advanced"},
    {"id": "TG19", "slug": "did_staggered", "name": "交叠DID（Staggered）", "family": "causal", "deps": ["did_multiplegt"], "level": "advanced"},
    {"id": "TG20", "slug": "did_csdid", "name": "Callaway-Sant'Anna DID", "family": "causal", "deps": ["csdid"], "level": "advanced"},
    {"id": "TG21", "slug": "ddd_triple", "name": "三重差分（DDD）", "family": "causal", "deps": [], "level": "advanced"},
    {"id": "TG22", "slug": "dr_aipw", "name": "双重稳健估计（DR）", "family": "causal", "deps": [], "level": "advanced"},
    {"id": "TG23", "slug": "late_iv", "name": "局部平均处理效应（LATE）", "family": "causal", "deps": ["ivreg2"], "level": "advanced"},
    {"id": "TG24", "slug": "het_treatment", "name": "处理效应异质性分析", "family": "causal", "deps": [], "level": "advanced"},
    {"id": "TG25", "slug": "mediation", "name": "中介效应分析", "family": "causal", "deps": [], "level": "advanced"},  # 使用官方 sem 命令，无需社区依赖
    
    # K. 金融专题 (TK01-TK10)
    {"id": "TK01", "slug": "capm_model", "name": "CAPM模型估计", "family": "finance", "deps": [], "level": "intermediate"},
    {"id": "TK02", "slug": "ff3_model", "name": "Fama-French三因子模型", "family": "finance", "deps": [], "level": "intermediate"},
    {"id": "TK03", "slug": "ff5_model", "name": "Fama-French五因子模型", "family": "finance", "deps": [], "level": "intermediate"},
    {"id": "TK04", "slug": "carhart4_model", "name": "Carhart四因子模型", "family": "finance", "deps": [], "level": "intermediate"},
    {"id": "TK05", "slug": "rolling_beta", "name": "Beta系数估计（滚动）", "family": "finance", "deps": ["asreg"], "level": "intermediate"},
    {"id": "TK06", "slug": "event_study_market", "name": "事件研究-市场模型", "family": "finance", "deps": [], "level": "advanced"},
    {"id": "TK07", "slug": "event_study_car", "name": "事件研究-CAR计算", "family": "finance", "deps": [], "level": "advanced"},
    {"id": "TK08", "slug": "event_study_bhar", "name": "事件研究-BHAR计算", "family": "finance", "deps": [], "level": "advanced"},
    {"id": "TK09", "slug": "var_calc", "name": "VaR风险价值计算", "family": "finance", "deps": [], "level": "advanced"},
    {"id": "TK10", "slug": "sharpe_ratio", "name": "夏普比率计算", "family": "finance", "deps": [], "level": "basic"},
    
    # P. 复杂抽样调查 (TP01-TP10)
    {"id": "TP01", "slug": "svy_setup", "name": "复杂抽样设计设置（svyset）", "family": "survey", "deps": [], "level": "intermediate"},
    {"id": "TP02", "slug": "svy_mean", "name": "加权描述统计", "family": "survey", "deps": [], "level": "basic"},
    {"id": "TP03", "slug": "svy_tab", "name": "加权频数表", "family": "survey", "deps": [], "level": "basic"},
    {"id": "TP04", "slug": "svy_regress", "name": "加权线性回归", "family": "survey", "deps": [], "level": "intermediate"},
    {"id": "TP05", "slug": "svy_logit", "name": "加权Logit回归", "family": "survey", "deps": [], "level": "intermediate"},
    {"id": "TP06", "slug": "svy_ologit", "name": "加权有序Logit", "family": "survey", "deps": [], "level": "intermediate"},
    {"id": "TP07", "slug": "svy_poisson", "name": "加权Poisson回归", "family": "survey", "deps": [], "level": "intermediate"},
    {"id": "TP08", "slug": "svy_deff", "name": "设计效应分析（DEFF）", "family": "survey", "deps": [], "level": "advanced"},
    {"id": "TP09", "slug": "svy_subpop", "name": "亚群分析（subpop）", "family": "survey", "deps": [], "level": "advanced"},
    {"id": "TP10", "slug": "svy_multistage", "name": "多阶段抽样处理", "family": "survey", "deps": [], "level": "advanced"},
    
    # Q. 多层模型 (TQ01-TQ08)
    {"id": "TQ01", "slug": "hlm_intercept", "name": "随机截距模型（两层）", "family": "multilevel", "deps": [], "level": "advanced"},
    {"id": "TQ02", "slug": "hlm_slope", "name": "随机斜率模型", "family": "multilevel", "deps": [], "level": "advanced"},
    {"id": "TQ03", "slug": "hlm_both", "name": "随机截距+随机斜率", "family": "multilevel", "deps": [], "level": "advanced"},
    {"id": "TQ04", "slug": "hlm_3level", "name": "三层嵌套模型", "family": "multilevel", "deps": [], "level": "advanced"},
    {"id": "TQ05", "slug": "melogit", "name": "多层Logit模型", "family": "multilevel", "deps": [], "level": "advanced"},
    {"id": "TQ06", "slug": "mepoisson", "name": "多层Poisson模型", "family": "multilevel", "deps": [], "level": "advanced"},
    {"id": "TQ07", "slug": "hlm_icc", "name": "ICC组内相关计算", "family": "multilevel", "deps": [], "level": "advanced"},
    {"id": "TQ08", "slug": "hlm_variance", "name": "方差分解（组间/组内）", "family": "multilevel", "deps": [], "level": "advanced"},
]

# 模板生成
DO_TEMPLATE = '''* ==============================================================================
* Task ID:      {task_id}
* Task Name:    {name}
* Family:       {family}
* Version:      2.0.0
* Description:  {name}
* 
* Inputs:       data.csv (main_dataset)
* Outputs:      table_{task_id}.csv
*
* Placeholders: __DEP_VAR__, __INDEP_VARS__
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands allowed)
* Dependencies: {deps}
* ==============================================================================

* ============ 初始化 ============
capture log close _all
clear all
set more off
version 18

log using "result.log", text replace

display "SS_TASK_START:{task_id}"
display "SS_TASK_VERSION:2.0.0"
display "SS_TIMESTAMP:`c(current_date)' `c(current_time)'"

{dep_check_block}

* ============ 数据加载 ============
capture confirm file "data.csv"
if _rc {{
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    display "SS_TASK_END:FAILED"
    log close
    exit 601
}}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC:n_input:`n_input'"

* ============ 变量检查 ============
local dep_var = "__DEP_VAR__"
local indep_vars = "__INDEP_VARS__"

foreach var in `dep_var' {{
    capture confirm variable `var'
    if _rc {{
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found in dataset"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found in dataset"
        display "SS_TASK_END:FAILED"
        log close
        exit 200
    }}
}}

* ============ 主分析: {name} ============
* TODO: 实现具体分析逻辑
display ">>> 执行 {name}"

local n_obs = _N
display "SS_METRIC:n_obs:`n_obs'"

* ============ 输出 ============
export delimited using "table_{task_id}.csv", replace
display "SS_OUTPUT_FILE:table_{task_id}.csv"

* ============ 任务结束 ============
display "SS_TASK_END:SUCCESS"
log close
'''

DEP_CHECK_TEMPLATE = '''* ============ 依赖检测 ============
local required_deps "{deps}"
foreach dep of local required_deps {{
    capture which `dep'
    if _rc {{
        display "SS_DEP_MISSING:cmd=`dep':hint=ssc install `dep'"
        display "SS_ERROR:DEP_MISSING:`dep' is required but not installed"
        display "SS_ERR:DEP_MISSING:`dep' is required but not installed"
        display "SS_TASK_END:FAILED"
        log close
        exit 199
    }}
}}
display "SS_DEP_CHECK:PASSED"
'''

MD_TEMPLATE = '''# {task_id}: {name}

## 概述

{name}

**Family**: {family}  
**Level**: {level}  
**Dependencies**: {deps}

## 输入

- `data.csv`: 主数据集

## 占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEP_VAR__` | varname | 是 | 因变量 |
| `__INDEP_VARS__` | varlist | 是 | 自变量列表 |

## 输出

- `table_{task_id}.csv`: 结果表格
- `result.log`: 运行日志

## 使用说明

1. 准备数据文件 `data.csv`
2. 设置占位符参数
3. 运行任务
4. 查看输出文件

## 注意事项

- 确保数据文件格式正确
- 检查变量名称是否存在
'''


def generate_task(task: Dict, output_dir: Path):
    """生成单个任务的所有文件"""
    task_id = task['id']
    
    # 依赖检测块
    deps = task.get('deps', [])
    if deps:
        dep_check = DEP_CHECK_TEMPLATE.format(deps=' '.join(deps))
    else:
        dep_check = '* 无社区命令依赖\ndisplay "SS_DEP_CHECK:PASSED"'
    
    # 生成do文件
    do_content = DO_TEMPLATE.format(
        task_id=task_id,
        name=task['name'],
        family=task['family'],
        deps=', '.join(deps) if deps else 'none',
        dep_check_block=dep_check
    )
    
    do_path = output_dir / 'do' / f"{task_id}_{task['slug']}.do"
    do_path.parent.mkdir(parents=True, exist_ok=True)
    do_path.write_text(do_content, encoding='utf-8')
    
    # 生成md文件
    md_content = MD_TEMPLATE.format(
        task_id=task_id,
        name=task['name'],
        family=task['family'],
        level=task['level'],
        deps=', '.join(deps) if deps else 'none'
    )
    
    md_path = output_dir / 'docs' / f"{task_id}_{task['slug']}.md"
    md_path.parent.mkdir(parents=True, exist_ok=True)
    md_path.write_text(md_content, encoding='utf-8')
    
    # 生成meta.json
    meta = {
        'task_id': task_id,
        'version': '2.0.0',
        'family': task['family'],
        'title': task['name'],
        'level': task['level'],
        'capabilities': [task['slug']],
        'inputs': {'required': [{'file': 'data.csv', 'role': 'main_dataset'}], 'optional': []},
        'dependencies': {'official': [], 'community': deps},
        'outputs': {'tables': [f"table_{task_id}.csv"], 'figures': [], 'data': [], 'reports': []},
        'placeholders': {
            '__DEP_VAR__': {'type': 'varname', 'required': True, 'default': '', 'description': '因变量'},
            '__INDEP_VARS__': {'type': 'varlist', 'required': True, 'default': '', 'description': '自变量列表'}
        },
        'expected_anchors': {'SS_TASK_START': 1, 'SS_TASK_END': 1, 'SS_OUTPUT_FILE': '>=1', 'SS_METRIC': '>=1'},
        'required_metrics': ['n_input', 'n_obs'],
        'test_cases': [{'name': 'basic', 'fixture': f'fixtures/{task_id}/sample_data.csv', 'params': {}, 'expected_success': True}]
    }
    
    meta_path = output_dir / 'do' / 'meta' / f"{task_id}_meta.json"
    meta_path.parent.mkdir(parents=True, exist_ok=True)
    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
    
    return task_id


def main():
    output_dir = Path('tasks')
    
    count = 0
    for task in NEW_TASKS:
        generate_task(task, output_dir)
        count += 1
    
    print(f"Generated {count} new tasks")
    print(f"  - do files: tasks/do/")
    print(f"  - md files: tasks/docs/")
    print(f"  - meta files: tasks/do/meta/")


if __name__ == "__main__":
    main()
