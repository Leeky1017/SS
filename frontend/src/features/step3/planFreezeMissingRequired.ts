export type MissingParamDetail = {
  param: string
  description: string
  candidates: string[]
}

export type PlanFreezeMissingRequiredDetails = {
  action: string | null
  missingParams: string[]
  missingParamsDetail: MissingParamDetail[]
}

export const VARIABLE_SELECTION_PARAMS = new Set(['__ID_VAR__', '__TIME_VAR__', '__PANELVAR__', '__CLUSTER_VAR__'])

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value === null || value === undefined) return null
  if (typeof value !== 'object') return null
  return value as Record<string, unknown>
}

function readNonEmptyString(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed === '' ? null : trimmed
}

function readStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  const out: string[] = []
  for (const item of value) {
    const s = readNonEmptyString(item)
    if (s === null) continue
    out.push(s)
  }
  return out
}

function parseMissingParamDetail(value: unknown): MissingParamDetail | null {
  const rec = asRecord(value)
  if (rec === null) return null
  const param = readNonEmptyString(rec.param)
  if (param === null) return null
  return {
    param,
    description: readNonEmptyString(rec.description) ?? '',
    candidates: readStringList(rec.candidates),
  }
}

export function parsePlanFreezeMissingRequiredDetails(details: unknown): PlanFreezeMissingRequiredDetails | null {
  const rec = asRecord(details)
  if (rec === null) return null
  const missingParams = readStringList(rec.missing_params)
  const rawDetail = rec.missing_params_detail
  const missingParamsDetail: MissingParamDetail[] = []
  if (Array.isArray(rawDetail)) {
    for (const item of rawDetail) {
      const parsed = parseMissingParamDetail(item)
      if (parsed === null) continue
      missingParamsDetail.push(parsed)
    }
  }
  return {
    action: readNonEmptyString(rec.action),
    missingParams,
    missingParamsDetail,
  }
}

