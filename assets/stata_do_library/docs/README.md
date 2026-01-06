# Stata 任务模板库

本目录包含 50 个标准化的 Stata 分析任务模板，覆盖数据管理、描述统计、假设检验、回归分析、面板数据、时间序列、生存分析等常见统计分析场景。

## 使用方式

### 1. 任务选择
上层服务根据用户需求，从 `tasks_index.json` 中匹配合适的任务模板。

### 2. 占位符渲染
每个 `.do` 模板使用双下划线大写占位符（如 `__DEP_VAR__`、`__INDEP_VARS__`），上层服务根据用户提供的 JSON 配置进行字符串替换，生成最终的 `user.do` 文件。

### 3. 与 `/run_stata` API 集成
1. 选择任务模板 → 2. 渲染占位符生成 `user.do` → 3. 调用 `POST /run_stata` 提交 `user.do` + `data.csv` → 4. 获取 `result.log` 及输出文件

## 占位符规范

| 占位符 | 说明 | 示例值 |
|--------|------|--------|
| `__DEP_VAR__` | 因变量名 | `income` |
| `__INDEP_VARS__` | 自变量列表（空格分隔） | `age edu gender` |
| `__NUMERIC_VARS__` | 数值变量列表 | `x1 x2 x3` |
| `__CATEGORICAL_VAR__` | 分类变量名 | `region` |
| `__GROUP_VAR__` | 分组变量名 | `gender` |
| `__TIME_VAR__` | 时间变量名 | `year` |
| `__ID_VAR__` | 个体/面板标识变量 | `id` |
| `__CLUSTER_VAR__` | 聚类变量名 | `firm_id` |
| `__FILTER_CONDITION__` | 筛选条件表达式 | `year >= 2015` |
| `__TREAT_VAR__` | 处理组指示变量 | `treated` |
| `__POST_VAR__` | 政策后时期指示变量 | `post` |

## 任务家族分类

| 家族 | 代码 | 任务数 | 说明 |
|------|------|--------|------|
| A | `data_management` | 6 | 数据管理与预处理 |
| B | `descriptive` | 5 | 描述统计与相关性 |
| C | `hypothesis_testing` | 5 | 假设检验 |
| D | `linear_regression` | 8 | 线性回归家族 |
| E | `limited_dependent` | 5 | 限定因变量模型 |
| F | `panel_policy` | 6 | 面板数据与政策评估 |
| G | `time_series` | 5 | 时间序列分析 |
| H | `survival` | 4 | 生存分析 |
| I | `multivariate` | 4 | 多变量与无监督学习 |
| J | `reporting` | 2 | 报告与打包 |

## 任务总表

| ID | Slug | 家族 | 简要说明 | 主要输入 | 主要输出 |
|----|------|------|----------|----------|----------|
| T01 | desc_overview | A | 整体描述统计与缺失概况 | data.csv | 日志输出 |
| T02 | desc_by_group | A | 按分组变量做分组描述统计 | data.csv | 日志输出 |
| T03 | filter_and_sample | A | 条件筛选与抽样 | data.csv | filtered_data.csv |
| T04 | merge_datasets | A | 主键合并两个数据集 | data_main.csv, data_aux.csv | merged_data.csv |
| T05 | append_datasets | A | 纵向合并多期数据 | data_1.csv, data_2.csv | appended_data.csv |
| T06 | reshape_wide_long | A | 宽表与长表转换 | data.csv | reshaped_data.csv |
| T07 | summary_numeric | B | 数值变量描述统计 | data.csv | desc_summary.csv |
| T08 | freq_categorical | B | 分类变量频数分布 | data.csv | freq_table.csv |
| T09 | corr_matrix | B | 相关系数矩阵 | data.csv | corr_matrix.csv |
| T10 | distribution_plots | B | 分布图（直方图/箱线图/核密度） | data.csv | figure_*.png |
| T11 | scatter_matrix | B | 散点图矩阵 | data.csv | figure_scatter.png |
| T12 | ttest_one_sample | C | 单样本t检验 | data.csv | 日志输出 |
| T13 | ttest_two_sample_indep | C | 两独立样本t检验 | data.csv | 日志输出 |
| T14 | ttest_paired | C | 配对t检验 | data.csv | 日志输出 |
| T15 | anova_oneway | C | 单因素方差分析 | data.csv | 日志输出 |
| T16 | chi_square_independence | C | 卡方独立性检验 | data.csv | 日志输出 |
| T17 | ols_simple | D | 简单线性回归 | data.csv | 日志输出 |
| T18 | ols_multiple | D | 多元线性回归 | data.csv | 日志输出 |
| T19 | ols_robust_se | D | 稳健标准误OLS | data.csv | 日志输出 |
| T20 | ols_cluster_se | D | 聚类稳健标准误OLS | data.csv | 日志输出 |
| T21 | ols_with_interaction | D | 含交互项的回归 | data.csv | 日志输出 |
| T22 | ols_fe_entity_dummies | D | 实体固定效应（虚拟变量法） | data.csv | 日志输出 |
| T23 | ols_time_dummies | D | 时间虚拟变量回归 | data.csv | 日志输出 |
| T24 | ols_model_comparison | D | 多模型对比 | data.csv | model_comparison.csv |
| T25 | logit_binary | E | 二元Logit模型 | data.csv | 日志输出 |
| T26 | probit_binary | E | 二元Probit模型 | data.csv | 日志输出 |
| T27 | ologit_ordered | E | 有序Logit模型 | data.csv | 日志输出 |
| T28 | mlogit_multinomial | E | 多项Logit模型 | data.csv | 日志输出 |
| T29 | poisson_count | E | Poisson/负二项回归 | data.csv | 日志输出 |
| T30 | panel_setup_check | F | 面板数据设置与检查 | data.csv | panel_summary.csv |
| T31 | panel_fe_basic | F | 面板固定效应回归 | data.csv | 日志输出 |
| T32 | panel_re_basic | F | 面板随机效应回归 | data.csv | 日志输出 |
| T33 | panel_fe_re_hausman | F | FE/RE比较与Hausman检验 | data.csv | 日志输出 |
| T34 | diff_in_diff_2x2 | F | 经典2×2 DID | data.csv | figure_did.png |
| T35 | diff_in_diff_event_study | F | 事件研究法DID | data.csv | figure_event_study.png |
| T36 | ts_diagnostics_plots | G | 时间序列诊断图 | data.csv | figure_ts_*.png |
| T37 | ts_unit_root_adf | G | ADF单位根检验 | data.csv | 日志输出 |
| T38 | ts_arima_estimation | G | ARIMA模型估计 | data.csv | 日志输出 |
| T39 | ts_forecast_horizon | G | ARIMA预测 | data.csv | forecast.csv, figure_forecast.png |
| T40 | var_two_series_basic | G | 双变量VAR模型 | data.csv | figure_irf.png |
| T41 | survival_km_curve | H | Kaplan-Meier生存曲线 | data.csv | figure_km.png |
| T42 | survival_logrank_test | H | Log-rank检验 | data.csv | 日志输出 |
| T43 | survival_cox_basic | H | 基本Cox回归 | data.csv | 日志输出 |
| T44 | survival_cox_time_varying | H | 时变协变量Cox模型 | data.csv | 日志输出 |
| T45 | pca_principal_components | I | 主成分分析 | data.csv | pca_scores.csv |
| T46 | factor_analysis | I | 因子分析 | data.csv | factor_loadings.csv |
| T47 | kmeans_clustering | I | K-means聚类 | data.csv | cluster_results.csv |
| T48 | hierarchical_clustering | I | 层次聚类 | data.csv | figure_dendrogram.png |
| T49 | auto_analysis_report | J | 自动化分析报告 | data.csv | report_*.csv, figure_*.png |
| T50 | export_outputs_bundle | J | 输出文件打包 | 当前目录文件 | outputs/ 目录 |

## 文件结构

```
stata_tasks/
├── README.md                      # 本文件
├── tasks_index.json               # 任务元信息索引
├── T01_desc_overview.do          # 任务模板
├── T01_desc_overview.md          # 任务说明
├── T02_desc_by_group.do
├── T02_desc_by_group.md
├── ...
├── T50_export_outputs_bundle.do
└── T50_export_outputs_bundle.md
```

## 注意事项

1. **不依赖外部包**：所有模板仅使用 Stata 18 官方内置命令，无需安装任何SSC包
2. **日志管理**：模板不包含 `log using/close`，由上层 runner 管理
3. **输出文件**：图形导出为 PNG，表格导出为 CSV 或 DTA

## 数据文件约定

### 内部统一规范
- **主数据文件**：`data.dta`（Stata格式）
- **Fallback数据文件**：`data.csv`（如果不存在dta，自动从csv转换）

### 标准化数据加载逻辑
每个任务模板使用统一的数据加载代码块：
```stata
local datafile "data.dta"
capture confirm file "`datafile'"
if _rc {
    capture confirm file "data.csv"
    if _rc {
        display as error "ERROR: No data.dta or data.csv found"
        exit 601
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
}
else {
    use "`datafile'", clear
}
```

### 上层服务支持格式
上层Python服务支持 `csv / xlsx / xls / dta` 格式，在进入job目录前自动转换为标准格式。

## 端到端使用示例

```mermaid
graph LR
    A[准备数据 csv/xlsx/dta] --> B[选择任务模板 T17_ols_simple]
    B --> C[填充占位符 JSON配置]
    C --> D[生成 user.do]
    D --> E[执行 Stata]
    E --> F[获取 result.log + 输出文件]
```

**示例：执行简单OLS回归**

1. **准备数据**：将数据文件命名为 `data.csv` 或 `data.dta`
2. **选择任务**：`T17_ols_simple`
3. **配置占位符**：
   ```json
   {
     "__DEP_VAR__": "wage",
     "__INDEP_VAR__": "education"
   }
   ```
4. **生成并执行**：字符串替换后得到可执行的 `user.do`
5. **获取结果**：`result.log` 包含回归输出

## 占位符扩展说明

| 占位符 | 说明 | 类型 | 必填 | 默认值 |
|--------|------|------|------|--------|
| `__MODEL_TYPE__` | T29模型类型 | poisson/nbreg/both | 否 | both |
| `__CLUSTER_VAR__` | T31聚类变量 | 变量名 | 否 | 使用ID变量 |
| `__N_COMPONENTS__` | T45主成分数 | 正整数 | 否 | 3 |
| `__MERGE_TYPE__` | T04合并类型 | 1:1/m:1/1:m | 是 | - |
| `__KEEP_OPTION__` | T04保留策略 | matched/master/using/all | 否 | all |

