# TE02_zinb — 零膨胀负二项

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TE02 |
| **Slug** | zinb |
| **名称(中文)** | 零膨胀负二项 |
| **Name(EN)** | ZINB |
| **家族** | limited_dependent |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Zero-inflated negative binomial regression

## 使用场景

- 关键词：zinb, zero-inflated, negative-binomial, count

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__INFLATE_VARS__` | string | 是 | Inflate variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TE02_zinb.csv | table | ZINB results |
| data_TE02_zinb.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | zinb command |

## 示例

```stata
* Template: TE02_zinb
* Script: tasks/do/TE02_zinb.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

