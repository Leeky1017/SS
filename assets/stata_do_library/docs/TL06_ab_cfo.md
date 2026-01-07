# TL06_ab_cfo — 异常经营现金流

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL06 |
| **Slug** | ab_cfo |
| **名称(中文)** | 异常经营现金流 |
| **Name(EN)** | Abnormal CFO |
| **家族** | accounting |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Abnormal cash flow from operations

## 使用场景

- 关键词：abnormal_cfo, rem, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__CFO_VAR__` | string | 是 | CFO |
| `__SALES_VAR__` | string | 是 | Sales |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL06_abcfo.csv | table | Ab CFO results |
| data_TL06_abcfo.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL06_ab_cfo
* Script: assets/stata_do_library/do/TL06_ab_cfo.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

