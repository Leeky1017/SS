# TJ01_cfa — 验证性因子分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TJ01 |
| **Slug** | cfa |
| **名称(中文)** | 验证性因子分析 |
| **Name(EN)** | CFA Analysis |
| **家族** | latent_variable |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Confirmatory Factor Analysis using SEM

## 使用场景

- 关键词：cfa, sem, factor_analysis

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Indicator variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TJ01_cfa.csv | table | CFA results |
| data_TJ01_cfa.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | sem command |

## 示例

```stata
* Template: TJ01_cfa
* Script: assets/stata_do_library/do/TJ01_cfa.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

