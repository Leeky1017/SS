# TU06_heatmap — 热力图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU06 |
| **Slug** | heatmap |
| **名称(中文)** | 热力图 |
| **Name(EN)** | Heatmap |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot correlation matrix heatmap

## 使用场景

- 关键词：visualization, heatmap, correlation

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Variables for correlation |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU06_heatmap.png | graph | Heatmap |
| table_TU06_corr.csv | table | Correlation matrix |
| data_TU06_heat.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | correlate command |

## 示例

```stata
* Template: TU06_heatmap
* Script: assets/stata_do_library/do/TU06_heatmap.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

