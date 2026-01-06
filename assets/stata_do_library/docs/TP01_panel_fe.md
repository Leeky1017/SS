# TP01_panel_fe — 面板固定效应

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP01 |
| **Slug** | panel_fe |
| **名称(中文)** | 面板固定效应 |
| **Name(EN)** | Panel FE |
| **家族** | panel |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Panel data fixed effects estimation

## 使用场景

- 关键词：panel, fixed_effects, fe

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP01_fe.dta | data | Output data |
| result.log | log | Execution log |
| table_TP01_fe_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TP01_fe_test.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtreg fe command |

## 示例

```stata
* Template: TP01_panel_fe
* Script: tasks/do/TP01_panel_fe.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

