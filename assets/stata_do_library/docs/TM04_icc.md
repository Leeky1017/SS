# TM04_icc — 组内相关系数

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM04 |
| **Slug** | icc |
| **名称(中文)** | 组内相关系数 |
| **Name(EN)** | ICC |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Intraclass Correlation Coefficient

## 使用场景

- 关键词：icc, reliability, agreement, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Measurement variable |
| `__GROUP__` | string | 是 | Group/subject ID |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM04_icc.csv | table | ICC results |
| data_TM04_icc.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | icc command |

## 示例

```stata
* Template: TM04_icc
* Script: assets/stata_do_library/do/TM04_icc.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

