# TM02_diagnostic_test — 诊断试验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM02 |
| **Slug** | diagnostic_test |
| **名称(中文)** | 诊断试验 |
| **Name(EN)** | Diagnostic Test |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Sensitivity, specificity, PPV, NPV calculation

## 使用场景

- 关键词：sensitivity, specificity, ppv, npv, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME__` | string | 是 | True condition |
| `__TEST_VAR__` | string | 是 | Test result |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM02_diag.csv | table | Diagnostic results |
| data_TM02_diag.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | diagt command |

## 示例

```stata
* Template: TM02_diagnostic_test
* Script: tasks/do/TM02_diagnostic_test.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

