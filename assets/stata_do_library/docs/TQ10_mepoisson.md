# TQ10_mepoisson — 多层Poisson

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ10 |
| **Slug** | mepoisson |
| **名称(中文)** | 多层Poisson |
| **Name(EN)** | Multilevel Poisson |
| **家族** | multilevel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Multilevel Poisson regression

## 使用场景

- 关键词：mepoisson, multilevel, count

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Count dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__GROUPVAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TQ10_mepois.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TQ10_mepois.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mepoisson command |

## 示例

```stata
* Template: TQ10_mepoisson
* Script: assets/stata_do_library/do/TQ10_mepoisson.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

