# TB08_kdensity_compare — 密度对比图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB08 |
| **Slug** | kdensity_compare |
| **名称(中文)** | 密度对比图 |
| **Name(EN)** | Kdensity Compare |
| **家族** | descriptive_statistics |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Draw grouped kernel density comparison plot

## 使用场景

- 关键词：kdensity, distribution, comparison

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable |
| `__BY_VAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TB08_kdensity.png | figure | Kdensity comparison plot |
| data_TB08_kd.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | kdensity command |

## 示例

```stata
* Template: TB08_kdensity_compare
* Script: tasks/do/TB08_kdensity_compare.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

