# TC01_twoway_anova — 双因素方差分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC01 |
| **Slug** | twoway_anova |
| **名称(中文)** | 双因素方差分析 |
| **Name(EN)** | Twoway ANOVA |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Two-way ANOVA testing main effects and interaction

## 使用场景

- 关键词：anova, twoway, interaction, factorial

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__FACTOR1__` | string | 是 | Factor 1 |
| `__FACTOR2__` | string | 是 | Factor 2 |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TC01_anova.csv | table | ANOVA results |
| data_TC01_anova.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | anova command |

## 示例

```stata
* Template: TC01_twoway_anova
* Script: tasks/do/TC01_twoway_anova.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

