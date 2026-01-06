# TB07_vioplot — 小提琴图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB07 |
| **Slug** | vioplot |
| **名称(中文)** | 小提琴图 |
| **Name(EN)** | Vioplot |
| **家族** | descriptive_statistics |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Draw violin plot to show data distribution

## 使用场景

- 关键词：violin, distribution, visualization

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
| fig_TB07_violin.png | figure | Violin plot |
| data_TB07_vio.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| vioplot | ssc | violin plot visualization |

## 示例

```stata
* Template: TB07_vioplot
* Script: tasks/do/TB07_vioplot.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

