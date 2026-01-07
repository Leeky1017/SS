# TI04_stcrreg — 竞争风险模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TI04 |
| **Slug** | stcrreg |
| **名称(中文)** | 竞争风险模型 |
| **Name(EN)** | Competing Risks |
| **家族** | survival |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Competing risks regression (Fine-Gray model)

## 使用场景

- 关键词：survival, competing_risks, fine_gray

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TIMEVAR__` | string | 是 | Time variable |
| `__FAILVAR__` | string | 是 | Failure indicator |
| `__INDEPVARS__` | list[string] | 否 | Covariates |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TI04_cr.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TI04_cr.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | stcrreg command |

## 示例

```stata
* Template: TI04_stcrreg
* Script: assets/stata_do_library/do/TI04_stcrreg.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

