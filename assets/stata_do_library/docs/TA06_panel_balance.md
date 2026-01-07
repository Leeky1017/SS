# TA06_panel_balance — 面板数据平衡化

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA06 |
| **Slug** | panel_balance |
| **名称(中文)** | 面板数据平衡化 |
| **Name(EN)** | Panel Balance |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Convert unbalanced panel to balanced panel by filling or dropping

## 使用场景

- 关键词：panel, balance, fill, tsfill

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__ID_VAR__` | string | 是 | ID variable |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__METHOD__` | string | 否 | Method: fill/drop |
| `__FILL_VALUE__` | string | 否 | Fill value type |
| `__MIN_PERIODS__` | integer | 否 | Minimum periods |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA06_balance_summary.csv | table | Balance summary |
| data_TA06_balanced.dta | data | Balanced panel data |
| data_TA06_balanced.csv | data | Balanced panel CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | Panel commands |

## 示例

```stata
* Template: TA06_panel_balance
* Script: assets/stata_do_library/do/TA06_panel_balance.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

