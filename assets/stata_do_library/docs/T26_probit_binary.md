# T26_probit_binary — 二元Probit模型（Binary Probit Regression）

## 任务元信息

| 属性 | 值 |
|------|-----|
| **Task ID** | T26_probit_binary |
| **任务名称** | 二元Probit模型 |
| **任务族** | E - 有限因变量模型 |
| **难度级别** | intermediate |
| **数据结构** | cross_section / panel |
| **金融场景适用** | ✓ 是 |

## 任务摘要

估计二分类因变量（0/1）的Probit模型，输出系数、边际效应和拟合优度。包含与Logit模型的对比。**Probit与Logit在实践中差异很小，但某些领域（如劳动经济学）更偏好Probit**。

## 适用场景

### 场景 1：参与决策
- **因变量**：是否参与（0/1）
- **自变量**：个人特征、成本收益
- **应用**：劳动参与、项目参与

### 场景 2：样本选择模型第一阶段
- **因变量**：是否进入样本（0/1）
- **自变量**：选择变量
- **应用**：Heckman两阶段模型的选择方程

### 场景 3：处理效应倾向得分
- **因变量**：是否接受处理（0/1）
- **自变量**：协变量
- **应用**：PSM的倾向得分估计

## 理论背景

### Probit模型

**潜变量模型**：
$$Y_i^* = X_i'\beta + \varepsilon_i, \quad \varepsilon_i \sim N(0,1)$$

**概率模型**：
$$P(Y_i = 1 | X_i) = \Phi(X_i'\beta)$$

其中 $\Phi(\cdot)$ 是标准正态累积分布函数。

### Logit vs Probit 对比

| 方面 | Logit | Probit |
|------|-------|--------|
| **链接函数** | Logistic CDF | Normal CDF |
| **误差分布** | Logistic | Normal |
| **系数解释** | 有OR解释 | 无直观解释 |
| **边际效应** | 几乎相同 | 几乎相同 |
| **计算** | 更快 | 稍慢 |
| **应用惯例** | 医学、流行病学 | 劳动经济学 |

### 系数转换规则

$$\beta_{Logit} \approx 1.6 \times \beta_{Probit}$$

或更精确地：$\beta_{Logit} \approx \frac{\pi}{\sqrt{3}} \times \beta_{Probit}$

## 数据文件要求

### 数据文件
- **首选**：`data.dta`（Stata 格式）
- **备选**：`data.csv`（自动转换为 data.dta）
- **编码**：UTF-8（推荐）

### 变量要求
- 因变量必须为 0/1 二元变量
- 自变量必须为数值型
- 不允许完全缺失

## 输入与占位符说明

### 占位符列表

| 占位符 | 含义 | 类型 | 必填 | 合法取值示例 |
|--------|------|------|------|-------------|
| `__DEP_VAR__` | 因变量（0/1） | 单变量名 | ✓ 是 | `participate` |
| `__INDEP_VARS__` | 自变量列表 | 空格分隔变量 | ✓ 是 | `age edu income` |

### 渲染规则

```python
config = {
    "dep_var": "participate",
    "indep_vars": ["age", "edu", "income", "married"]
}

placeholders = {
    "__DEP_VAR__": config["dep_var"],
    "__INDEP_VARS__": " ".join(config["indep_vars"])
}
```

## 输出文件清单与 Schema

### 0. result.log

任务执行日志，包含Probit回归、边际效应、拟合优度、ROC分析、Logit对比和结果摘要。

### 1. table_T26_probit_coef.csv

Probit系数表。

| 列名 | 类型 | 说明 |
|------|------|------|
| `variable` | string | 变量名 |
| `coef` | float | Probit系数 |
| `se` | float | 标准误 |
| `z` | float | z统计量 |
| `p` | float | p值 |
| `sig` | string | 显著性标记 |

### 2. fig_T26_roc.png

ROC曲线图（PNG格式）。

## 上层 JSON 配置示例

```json
{
  "task_id": "T26_probit_binary",
  "description": "劳动参与决策的Probit分析",
  "dep_var": "lfp",
  "indep_vars": ["age", "age_sq", "edu", "kids", "huswage"]
}
```

## 报告写作骨架

```markdown
## X.X Probit回归分析

由于因变量[Y]为二元变量，本文采用Probit模型进行估计：

$$ P(Y_i = 1 | X_i) = \Phi(X_i'\beta) $$

其中 $\Phi(\cdot)$ 为标准正态累积分布函数。

表X报告了Probit回归结果。[核心变量]的系数为[β]（z=[z]），
在[1%/5%/10%]水平下显著[为正/为负]。

由于Probit系数本身不易解释，表X同时报告了平均边际效应。
[核心变量]的边际效应为[ME]，即该变量每增加1单位，
[因变量=1]的概率平均[增加/减少] [ME*100] 个百分点。

作为稳健性检验，本文同时估计了Logit模型（见附录表X），
两种模型的边际效应几乎完全一致，表明结论不受模型选择影响。
```

## 常见坑与建议

### 1. 系数不能直接解释
- **问题**：Probit系数没有直观解释
- **建议**：必须报告边际效应

### 2. 与Logit选择
- **问题**：不知道用哪个模型
- **建议**：边际效应几乎相同，可按领域惯例选择

### 3. 没有OR
- **问题**：Probit没有比值比
- **建议**：如需OR，用Logit

## 与其他任务的关系

| 相关任务 | 关系说明 |
|----------|----------|
| T25_logit_binary | Logit是替代方法 |
| T27_ologit_ordered | 有序因变量 |

## 技术说明

- **Stata 版本**：18.0+
- **外部依赖**：无，仅使用 Stata 官方命令
- **关键命令**：`probit`, `margins`, `lroc`, `estat classification`
- **退出码**：错误时统一返回 200
