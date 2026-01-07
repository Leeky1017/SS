# TC04_mann_whitney — Mann-Whitney U检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC04 |
| **Slug** | mann_whitney |
| **名称(中文)** | Mann-Whitney U检验 |
| **Name(EN)** | Mann Whitney |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Mann-Whitney U test for two groups

## 使用场景

- 关键词：nonparametric, mann-whitney, two-groups

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
| table_TC04_mw.csv | table | MW test results |
| data_TC04_mw.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | ranksum command |

## 示例

```stata
* Template: TC04_mann_whitney
* Script: assets/stata_do_library/do/TC04_mann_whitney.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

