# TJ04_canon — 典型相关分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TJ04 |
| **Slug** | canon |
| **名称(中文)** | 典型相关分析 |
| **Name(EN)** | Canonical Correlation |
| **家族** | multivariate |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Canonical Correlation Analysis

## 使用场景

- 关键词：canonical, correlation, multivariate

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS1__` | list[string] | 是 | First variable set |
| `__VARS2__` | list[string] | 是 | Second variable set |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TJ04_canon.csv | table | CCA results |
| data_TJ04_canon.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | canon command |

## 示例

```stata
* Template: TJ04_canon
* Script: assets/stata_do_library/do/TJ04_canon.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

