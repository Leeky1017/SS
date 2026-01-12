export type Step1MethodCategoryId =
  | 'panel'
  | 'causal_inference'
  | 'time_series'
  | 'medical'
  | 'finance'
  | 'spatial'
  | 'free_description'

export type Step1MethodId =
  | 'panel_regression'
  | 'causal_did'
  | 'time_series_arima'
  | 'medical_logit'
  | 'finance_event_study'
  | 'spatial_sdm'

export type Step1Method = {
  id: Step1MethodId
  label: string
  description: string
  template: string
}

export type Step1MethodCategory = {
  id: Step1MethodCategoryId
  label: string
  description: string
  methods: Step1Method[]
}

const PANEL_REGRESSION: Step1Method = {
  id: 'panel_regression',
  label: '面板回归（OLS/FE/RE）',
  description: '适用于企业/个人等面板数据',
  template:
    '【分析类型】面板回归（OLS/FE/RE）\n【研究目标】___\n【被解释变量（Y）】___\n【核心解释变量（X）】___\n【控制变量（Controls，可选）】___\n【固定效应】个体 FE + 时间 FE（可调整）\n【标准误】建议按个体聚类稳健（可调整）',
}

const CAUSAL_DID: Step1Method = {
  id: 'causal_did',
  label: 'DID（双重差分）',
  description: '政策/冲击前后对照',
  template:
    '【分析类型】因果推断 - DID（双重差分）\n【研究目标】___\n【处理变量（Treatment）】___\n【结果变量（Outcome）】___\n【控制变量（Controls，可选）】___\n【关键设定】个体固定效应 + 时间固定效应；并行趋势检验（事件研究/安慰剂）',
}

const TIME_SERIES_ARIMA: Step1Method = {
  id: 'time_series_arima',
  label: 'ARIMA/预测',
  description: '单变量序列建模与预测',
  template:
    '【分析类型】时间序列 - ARIMA/预测\n【研究目标】___\n【被解释变量（Y）】___\n【频率】日/周/月/季度（___）\n【是否差分/对数】___\n【预测期】___',
}

const MEDICAL_LOGIT: Step1Method = {
  id: 'medical_logit',
  label: 'Logistic 回归',
  description: '二分类结局/风险因素分析',
  template:
    '【分析类型】医学/生统 - Logistic 回归\n【研究目标】___\n【结局变量（Y，二分类）】___\n【暴露/核心变量（X）】___\n【协变量（Covariates）】___\n【分组/交互（可选）】___',
}

const FINANCE_EVENT_STUDY: Step1Method = {
  id: 'finance_event_study',
  label: '事件研究（Event Study）',
  description: '事件冲击与超额收益',
  template:
    '【分析类型】金融 - 事件研究\n【研究目标】___\n【事件定义】___\n【事件日】___\n【估计窗口/事件窗口】___\n【收益指标】日收益/超额收益（___）\n【控制模型】市场模型/CAPM/FF3（___）',
}

const SPATIAL_SDM: Step1Method = {
  id: 'spatial_sdm',
  label: '空间杜宾模型（SDM）',
  description: '空间溢出效应/邻近相关',
  template:
    '【分析类型】空间计量 - SDM\n【研究目标】___\n【被解释变量（Y）】___\n【核心解释变量（X）】___\n【空间权重矩阵 W】相邻/距离/经济距离（___）\n【空间效应】滞后项/误差项（___）',
}

export const STEP1_METHOD_CATEGORIES: Step1MethodCategory[] = [
  { id: 'panel', label: '面板回归', description: 'OLS / FE / RE', methods: [PANEL_REGRESSION] },
  { id: 'causal_inference', label: '因果推断', description: 'DID 等准实验方法', methods: [CAUSAL_DID] },
  { id: 'time_series', label: '时间序列', description: '预测 / 冲击分析', methods: [TIME_SERIES_ARIMA] },
  { id: 'medical', label: '医学/生统', description: 'Logit / Cox 等', methods: [MEDICAL_LOGIT] },
  { id: 'finance', label: '金融', description: '事件研究 / 资产定价', methods: [FINANCE_EVENT_STUDY] },
  { id: 'spatial', label: '空间计量', description: 'SAR / SEM / SDM', methods: [SPATIAL_SDM] },
  { id: 'free_description', label: '自由描述', description: '我想直接输入需求', methods: [] },
]

export const STEP1_QUICK_FILLS = [
  { label: '面板回归', categoryId: 'panel', methodId: 'panel_regression' },
  { label: 'DID 模型', categoryId: 'causal_inference', methodId: 'causal_did' },
] as const satisfies ReadonlyArray<{
  label: string
  categoryId: Step1MethodCategoryId
  methodId: Step1MethodId
}>

type Step1MethodIndexEntry = { categoryId: Step1MethodCategoryId; method: Step1Method }

export const STEP1_METHOD_INDEX = {
  panel_regression: { categoryId: 'panel', method: PANEL_REGRESSION },
  causal_did: { categoryId: 'causal_inference', method: CAUSAL_DID },
  time_series_arima: { categoryId: 'time_series', method: TIME_SERIES_ARIMA },
  medical_logit: { categoryId: 'medical', method: MEDICAL_LOGIT },
  finance_event_study: { categoryId: 'finance', method: FINANCE_EVENT_STUDY },
  spatial_sdm: { categoryId: 'spatial', method: SPATIAL_SDM },
} as const satisfies Record<Step1MethodId, Step1MethodIndexEntry>

export function getStep1Category(categoryId: Step1MethodCategoryId): Step1MethodCategory | null {
  return STEP1_METHOD_CATEGORIES.find((c) => c.id === categoryId) ?? null
}

export function getStep1MethodTemplate(methodId: Step1MethodId): string {
  return STEP1_METHOD_INDEX[methodId].method.template
}

