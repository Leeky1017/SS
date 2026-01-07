# TB09_spineplot — 脊柱图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB09 |
| **Slug** | spineplot |
| **名称(中文)** | 脊柱图 |
| **Name(EN)** | Spineplot |
| **家族** | descriptive_statistics |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Draw spine plot for categorical variable relationships

## 使用场景

- 关键词：spineplot, categorical, mosaic

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
| fig_TB09_spine.png | figure | Spine plot |
| data_TB09_spine.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| spineplot | ssc | spine plot visualization |

## 示例

```stata
* Template: TB09_spineplot
* Script: assets/stata_do_library/do/TB09_spineplot.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

