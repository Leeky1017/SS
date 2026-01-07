# TA13_stratified_sample — 数据集抽样

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA13 |
| **Slug** | stratified_sample |
| **名称(中文)** | 数据集抽样 |
| **Name(EN)** | Stratified Sample |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Perform stratified random sampling with proportional/equal/fixed methods

## 使用场景

- 关键词：sample, stratified, random, subset

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__STRATA_VAR__` | string | 是 | Strata variable |
| `__SAMPLE_SIZE__` | number | 是 | Sample size or proportion |
| `__METHOD__` | string | 否 | Sampling method |
| `__RANDOM_SEED__` | integer | 否 | Random seed |
| `__WITH_REPLACE__` | string | 否 | With replacement |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA13_sample_summary.csv | table | Sample summary |
| data_TA13_sampled.dta | data | Sampled data |
| data_TA13_sampled.csv | data | Sampled CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | Sample command |

## 示例

```stata
* Template: TA13_stratified_sample
* Script: assets/stata_do_library/do/TA13_stratified_sample.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

