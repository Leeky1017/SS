# TL07_ab_prod — 异常生产成本

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL07 |
| **Slug** | ab_prod |
| **名称(中文)** | 异常生产成本 |
| **Name(EN)** | Abnormal Production |
| **家族** | accounting |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Abnormal production costs

## 使用场景

- 关键词：abnormal_production, rem, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__PROD_VAR__` | string | 是 | Production costs |
| `__SALES_VAR__` | string | 是 | Sales |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL07_abprod.csv | table | Ab Prod results |
| data_TL07_abprod.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL07_ab_prod
* Script: assets/stata_do_library/do/TL07_ab_prod.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

