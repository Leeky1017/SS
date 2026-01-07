# TM12_stratified_analysis — 分层分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM12 |
| **Slug** | stratified_analysis |
| **名称(中文)** | 分层分析 |
| **Name(EN)** | Stratified Analysis |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Mantel-Haenszel stratified analysis

## 使用场景

- 关键词：stratified, mantel_haenszel, confounding, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME__` | string | 是 | Outcome |
| `__EXPOSURE__` | string | 是 | Exposure |
| `__STRATA__` | string | 是 | Stratification var |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TM12_mh.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TM12_mh.csv | table | MH results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mhodds command |

## 示例

```stata
* Template: TM12_stratified_analysis
* Script: assets/stata_do_library/do/TM12_stratified_analysis.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

