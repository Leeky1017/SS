# TC02_repeated_anova — 重复测量方差分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC02 |
| **Slug** | repeated_anova |
| **名称(中文)** | 重复测量方差分析 |
| **Name(EN)** | Repeated ANOVA |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Repeated measures ANOVA

## 使用场景

- 关键词：anova, repeated, longitudinal, within-subject

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__ID_VAR__` | string | 是 | Subject ID |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TC02_repeated.csv | table | Repeated ANOVA results |
| data_TC02_rep.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | anova repeated |

## 示例

```stata
* Template: TC02_repeated_anova
* Script: tasks/do/TC02_repeated_anova.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

