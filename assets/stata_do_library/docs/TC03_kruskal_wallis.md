# TC03_kruskal_wallis — Kruskal-Wallis非参数检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC03 |
| **Slug** | kruskal_wallis |
| **名称(中文)** | Kruskal-Wallis非参数检验 |
| **Name(EN)** | Kruskal Wallis |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Kruskal-Wallis H test for multiple groups

## 使用场景

- 关键词：nonparametric, kruskal-wallis, multiple-groups

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
| table_TC03_kw.csv | table | KW test results |
| data_TC03_kw.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | kwallis command |

## 示例

```stata
* Template: TC03_kruskal_wallis
* Script: tasks/do/TC03_kruskal_wallis.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

