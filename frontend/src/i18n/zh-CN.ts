export const zhCN = {
  common: {
    placeholderDash: '—',
    selectPlaceholder: '请选择…',
  },
  actions: {
    retry: '重试',
    redeemAgain: '重新兑换',
    refreshPreview: '刷新预览',
    cancel: '取消',
    confirmAndStart: '确认并启动',
    continueConfirm: '继续确认',
    recheck: '重新检查',
  },
  steps: {
    step1: '第一步',
    step2: '第二步',
  },
  step2: {
    continueToStep3: '继续：预览确认',
  },
  step3: {
    title: '预览确认',
    lead: '确认变量映射、查看风险提示并完成必要澄清；确认后将锁定并进入执行阶段。',
    missingJobIdTitle: '缺少任务信息',
    missingJobIdHint: '请先完成第一步 / 第二步。',
    backToStep1: '返回第一步',
    lockedTitle: '已锁定（已确认）',
    confirmedAtLabel: '确认时间',
    pendingTitle: '预处理中…',
    pendingDefaultMessage: '系统正在准备预览，请稍后自动重试。',
    retryAfterSecondsLabel: '预计等待',
    retryLoadDraft: '重试加载预览',
    refreshDraft: '刷新预览',
    retryPatchDraft: '重试应用澄清',
    retryConfirm: '重试确认',
  },
  variables: {
    heading: '变量概览',
    headers: {
      role: '角色',
      variable: '变量',
    },
    roles: {
      outcome: '因变量 (Outcome)',
      treatment: '处理变量 (Treatment)',
      controls: '控制变量 (Controls)',
    },
  },
  warnings: {
    heading: '数据质量警告',
    headers: {
      severity: '严重程度',
      message: '提示',
      suggestion: '建议',
    },
  },
  draft: {
    heading: '预览内容',
  },
  mapping: {
    heading: '修正变量映射',
    clearAll: '清除修正',
    headers: {
      role: '角色',
      original: '原始',
      corrected: '修正',
    },
    optionNoCorrection: '（不修正）',
    hint: '显示变量时只应用修正映射，不会修改原始内容。',
  },
  stage1: {
    heading: '确认问题（第一阶段）',
    mustAnswerAllBeforeConfirm: '请完成所有第一阶段问题后再确认。',
  },
  unknowns: {
    heading: '待澄清项',
    blocking: '阻断项',
    nonBlocking: '非阻断项',
    hasBlockingHint: '包含阻断项，确认前必须补全',
    placeholderValue: '填写澄清值',
    applyAndRefresh: '应用澄清并刷新预览',
    patchUnsupported: '当前版本暂不支持提交澄清，本面板仅作为提示，不阻断确认。',
    patchNotProvided404501: '当前版本暂不支持提交澄清，本面板不阻断确认。',
    mustFillBlockingBeforeConfirm: '请补全所有阻断项后再确认。',
  },
  downgrade: {
    title: '需要额外确认',
    message: '当前预览存在风险提示，确认后将按保守策略继续执行。是否继续？',
  },
  errors: {
    unauthorizedTitle: '验证失效',
    requestFailedTitle: '操作失败',
    requestIdLabel: '参考编号',
  },
} as const

export function controlRoleLabel(index: number): string {
  return `${zhCN.variables.roles.controls} ${index}`
}
