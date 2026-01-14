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
    continueToStep3: '继续：执行草案预检',
  },
  step3: {
    title: '执行草案预检',
    lead: '确认变量映射、查看风险提示并完成必要澄清；确认后将锁定并进入执行阶段。',
    missingJobIdTitle: '缺少 job_id',
    missingJobIdHint: '请先完成第一步 / 第二步。',
    backToStep1: '返回第一步',
    lockedTitle: '已锁定（已确认）',
    confirmedAtLabel: 'confirmed_at',
    pendingTitle: '预处理中…',
    pendingDefaultMessage: '后端正在生成执行草案预览，请稍后自动重试。',
    retryAfterSecondsLabel: 'retry_after_seconds',
    retryLoadDraft: '重试加载执行草案',
    refreshDraft: '刷新执行草案',
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
    heading: '草案内容',
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
    hint: '显示变量时只应用修正映射，不会修改原始草案内容。',
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
    patchUnsupported: '后端暂不支持 draft/patch，本面板仅作为提示，不阻断确认。',
    patchNotProvided404501: '后端未提供 draft/patch（404/501），本面板不阻断确认。',
    mustFillBlockingBeforeConfirm: '请补全所有阻断项后再确认。',
  },
  downgrade: {
    title: '需要降级确认',
    message: '当前执行草案存在风险项，确认后将以降级策略继续执行。是否继续？',
  },
  errors: {
    unauthorizedTitle: '未授权',
    requestFailedTitle: '请求失败',
    requestIdLabel: 'request_id',
  },
} as const

export function controlRoleLabel(index: number): string {
  return `${zhCN.variables.roles.controls} ${index}`
}
