# TL14_gc_opinion — 持续经营意见

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL14 |
| **Slug** | gc_opinion |
| **名称(中文)** | 持续经营意见 |
| **Name(EN)** | Going Concern Opinion |
| **家族** | audit |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Going concern opinion prediction model

## 使用场景

- 关键词：going_concern, audit, opinion

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__GC_VAR__` | string | 是 | GC opinion indicator |
| `__INDEPVARS__` | list[string] | 是 | Predictors |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL14_gc.csv | table | GC opinion results |
| data_TL14_gc.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | logit command |

## 示例

```stata
* Template: TL14_gc_opinion
* Script: assets/stata_do_library/do/TL14_gc_opinion.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

