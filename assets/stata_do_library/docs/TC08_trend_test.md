# TC08_trend_test — 趋势检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC08 |
| **Slug** | trend_test |
| **名称(中文)** | 趋势检验 |
| **Name(EN)** | Trend Test |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Cochran-Armitage trend test for ordinal data

## 使用场景

- 关键词：trend, ordinal, cochran-armitage

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Test variable |
| `__GROUP_VAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TC08_trend.csv | table | Trend test results |
| data_TC08_trend.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | nptrend command |

## 示例

```stata
* Template: TC08_trend_test
* Script: assets/stata_do_library/do/TC08_trend_test.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

