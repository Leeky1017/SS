# TH01_dfgls — DF-GLS单位根检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH01 |
| **Slug** | dfgls |
| **名称(中文)** | DF-GLS单位根检验 |
| **Name(EN)** | DF-GLS Test |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Elliott-Rothenberg-Stock DF-GLS unit root test

## 使用场景

- 关键词：unit_root, dfgls, stationarity, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to test |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__MAXLAG__` | number | 是 | Maximum lag |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH01_dfgls.csv | table | DF-GLS results |
| data_TH01_dfgls.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH01_dfgls
* Script: assets/stata_do_library/do/TH01_dfgls.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

