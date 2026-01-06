# TC06_fisher_exact — Fisher精确检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC06 |
| **Slug** | fisher_exact |
| **名称(中文)** | Fisher精确检验 |
| **Name(EN)** | Fisher Exact |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Fisher exact test for small sample contingency tables

## 使用场景

- 关键词：fisher, exact, contingency, categorical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR1__` | string | 是 | Variable 1 |
| `__VAR2__` | string | 是 | Variable 2 |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TC06_fisher.csv | table | Fisher test results |
| data_TC06_fisher.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | tabulate exact |

## 示例

```stata
* Template: TC06_fisher_exact
* Script: tasks/do/TC06_fisher_exact.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

