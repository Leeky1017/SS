# TE01_zip — 零膨胀Poisson

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TE01 |
| **Slug** | zip |
| **名称(中文)** | 零膨胀Poisson |
| **Name(EN)** | ZIP |
| **家族** | limited_dependent |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Zero-inflated Poisson regression for excess zeros

## 使用场景

- 关键词：zip, zero-inflated, poisson, count

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
| table_TE01_zip.csv | table | ZIP results |
| data_TE01_zip.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | zip command |

## 示例

```stata
* Template: TE01_zip
* Script: assets/stata_do_library/do/TE01_zip.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

