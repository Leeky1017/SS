# TJ05_mds — 多维尺度分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TJ05 |
| **Slug** | mds |
| **名称(中文)** | 多维尺度分析 |
| **Name(EN)** | MDS Analysis |
| **家族** | multivariate |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Multidimensional Scaling

## 使用场景

- 关键词：mds, scaling, multivariate

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TJ05_mds.dta | data | Output data |
| fig_TJ05_mds.png | graph | MDS plot |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mds command |

## 示例

```stata
* Template: TJ05_mds
* Script: assets/stata_do_library/do/TJ05_mds.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

