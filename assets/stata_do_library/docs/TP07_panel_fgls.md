# TP07_panel_fgls — 面板FGLS

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP07 |
| **Slug** | panel_fgls |
| **名称(中文)** | 面板FGLS |
| **Name(EN)** | Panel FGLS |
| **家族** | panel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Feasible GLS for panel data

## 使用场景

- 关键词：panel, fgls, gls

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP07_fgls.dta | data | Output data |
| result.log | log | Execution log |
| table_TP07_fgls_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtgls command |

## 示例

```stata
* Template: TP07_panel_fgls
* Script: assets/stata_do_library/do/TP07_panel_fgls.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

