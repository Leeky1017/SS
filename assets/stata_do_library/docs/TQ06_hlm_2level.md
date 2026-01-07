# TQ06_hlm_2level — 两层HLM

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ06 |
| **Slug** | hlm_2level |
| **名称(中文)** | 两层HLM |
| **Name(EN)** | HLM 2-Level |
| **家族** | multilevel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Two-level hierarchical linear model

## 使用场景

- 关键词：hlm, multilevel, mixed

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__GROUPVAR__` | string | 是 | Level-2 group |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TQ06_hlm.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TQ06_hlm2.csv | table | HLM results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mixed command |

## 示例

```stata
* Template: TQ06_hlm_2level
* Script: assets/stata_do_library/do/TQ06_hlm_2level.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

