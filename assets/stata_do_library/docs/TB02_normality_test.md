# TB02_normality_test — 正态性检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB02 |
| **Slug** | normality_test |
| **名称(中文)** | 正态性检验 |
| **Name(EN)** | Normality Test |
| **家族** | descriptive_statistics |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Calculate skewness/kurtosis and perform Shapiro-Wilk normality tests

## 使用场景

- 关键词：normality, skewness, kurtosis, shapiro-wilk

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | string | 是 | Numeric variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TB02_normality.csv | table | Normality test results |
| data_TB02_norm.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | swilk command |

## 示例

```stata
* Template: TB02_normality_test
* Script: tasks/do/TB02_normality_test.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

