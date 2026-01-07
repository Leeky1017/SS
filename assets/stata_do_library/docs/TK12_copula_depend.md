# TK12_copula_depend — Copula相依性

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK12 |
| **Slug** | copula_depend |
| **名称(中文)** | Copula相依性 |
| **Name(EN)** | Copula Dependence |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Copula-based dependence modeling

## 使用场景

- 关键词：copula, dependence, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR1__` | string | 是 | First variable |
| `__VAR2__` | string | 是 | Second variable |
| `__COPULA_TYPE__` | string | 否 | Copula family |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK12_copula.dta | data | Output data |
| fig_TK12_scatter.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK12_correlation.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK12_tail_depend.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | copula calculations |

## 示例

```stata
* Template: TK12_copula_depend
* Script: assets/stata_do_library/do/TK12_copula_depend.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

