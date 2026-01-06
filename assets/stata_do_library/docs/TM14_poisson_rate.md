# TM14_poisson_rate — 泊松率回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM14 |
| **Slug** | poisson_rate |
| **名称(中文)** | 泊松率回归 |
| **Name(EN)** | Poisson Rate |
| **家族** | medical |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Poisson regression for rate data

## 使用场景

- 关键词：poisson, rate, incidence, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__EVENTS__` | string | 是 | Event count |
| `__EXPOSURE__` | string | 是 | Exposure time |
| `__INDEPVARS__` | list[string] | 是 | Predictors |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TM14_irr.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TM14_irr.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | poisson command |

## 示例

```stata
* Template: TM14_poisson_rate
* Script: tasks/do/TM14_poisson_rate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

