# TM15_sample_size_clinical — 临床样本量

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM15 |
| **Slug** | sample_size_clinical |
| **名称(中文)** | 临床样本量 |
| **Name(EN)** | Clinical Sample Size |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Sample size calculation for clinical trials

## 使用场景

- 关键词：sample_size, power, clinical_trial, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__ALPHA__` | number | 否 | Significance level |
| `__POWER__` | number | 否 | Power |
| `__EFFECT_SIZE__` | number | 是 | Effect size |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM15_ss.csv | table | Sample size results |
| data_TM15_ss.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | power command |

## 示例

```stata
* Template: TM15_sample_size_clinical
* Script: tasks/do/TM15_sample_size_clinical.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

