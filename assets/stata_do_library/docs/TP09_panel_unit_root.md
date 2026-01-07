# TP09_panel_unit_root — 面板单位根检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP09 |
| **Slug** | panel_unit_root |
| **名称(中文)** | 面板单位根检验 |
| **Name(EN)** | Panel Unit Root |
| **家族** | panel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Panel unit root tests (LLC, IPS, Fisher)

## 使用场景

- 关键词：panel, unit_root, stationarity

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to test |
| `__LAGS__` | integer | 否 | Number of lags |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP09_unit_root.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TP09_unit_root.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtunitroot command |

## 示例

```stata
* Template: TP09_panel_unit_root
* Script: assets/stata_do_library/do/TP09_panel_unit_root.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

