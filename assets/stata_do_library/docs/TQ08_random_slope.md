# TQ08_random_slope — 随机斜率模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ08 |
| **Slug** | random_slope |
| **名称(中文)** | 随机斜率模型 |
| **Name(EN)** | Random Slope |
| **家族** | multilevel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Random slope multilevel model

## 使用场景

- 关键词：random_slope, multilevel, mixed

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__GROUPVAR__` | string | 是 | Group variable |
| `__SLOPEVAR__` | string | 是 | Random slope variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TQ08_rslope.csv | table | Random slope results |
| data_TQ08_rslope.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mixed command |

## 示例

```stata
* Template: TQ08_random_slope
* Script: tasks/do/TQ08_random_slope.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

