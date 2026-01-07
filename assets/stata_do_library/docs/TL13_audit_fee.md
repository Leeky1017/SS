# TL13_audit_fee — 审计费用模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL13 |
| **Slug** | audit_fee |
| **名称(中文)** | 审计费用模型 |
| **Name(EN)** | Audit Fee Model |
| **家族** | audit |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Audit fee determinants model

## 使用场景

- 关键词：audit, fee, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__FEE_VAR__` | string | 是 | Audit fee |
| `__SIZE_VAR__` | string | 是 | Size |
| `__INDEPVARS__` | list[string] | 否 | Controls |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL13_auditfee.csv | table | Audit fee results |
| data_TL13_auditfee.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL13_audit_fee
* Script: assets/stata_do_library/do/TL13_audit_fee.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

