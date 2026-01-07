# TP08_panel_pcse — 面板校正标准误

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP08 |
| **Slug** | panel_pcse |
| **名称(中文)** | 面板校正标准误 |
| **Name(EN)** | Panel PCSE |
| **家族** | panel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Panel-corrected standard errors

## 使用场景

- 关键词：panel, pcse, beck_katz

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
| data_TP08_pcse.dta | data | Output data |
| result.log | log | Execution log |
| table_TP08_pcse_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtpcse command |

## 示例

```stata
* Template: TP08_panel_pcse
* Script: assets/stata_do_library/do/TP08_panel_pcse.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

