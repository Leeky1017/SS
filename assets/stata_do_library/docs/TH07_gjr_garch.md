# TH07_gjr_garch — GJR-GARCH模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH07 |
| **Slug** | gjr_garch |
| **名称(中文)** | GJR-GARCH模型 |
| **Name(EN)** | GJR-GARCH Model |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

GJR-GARCH leverage effect model

## 使用场景

- 关键词：gjr, garch, leverage, volatility

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable |
| `__TIME_VAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH07_gjr.csv | table | GJR results |
| data_TH07_gjr.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH07_gjr_garch
* Script: assets/stata_do_library/do/TH07_gjr_garch.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

