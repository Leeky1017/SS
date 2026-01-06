# TN08_spatial_panel — 空间面板模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TN08 |
| **Slug** | spatial_panel |
| **名称(中文)** | 空间面板模型 |
| **Name(EN)** | Spatial Panel |
| **家族** | spatial |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Spatial panel data models

## 使用场景

- 关键词：spatial_panel, panel, spatial

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
| table_TN08_sppanel.csv | table | Spatial panel results |
| data_TN08_sppanel.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xsmle | ssc | Spatial panel |

## 示例

```stata
* Template: TN08_spatial_panel
* Script: tasks/do/TN08_spatial_panel.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

