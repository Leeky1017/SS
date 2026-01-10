export type SSJobStatus = string

export type RedeemTaskCodeRequest = {
  task_code: string
  requirement: string
}

export type RedeemTaskCodeResponse = {
  job_id: string
  token: string
}

export type ConfirmJobRequest = {
  confirmed: boolean
  notes: string | null
  variable_corrections: Record<string, string>
  default_overrides: Record<string, unknown>
  answers?: Record<string, string[]>
  expert_suggestions_feedback?: Record<string, unknown>
}

export type ConfirmJobResponse = {
  job_id: string
  status: SSJobStatus
  scheduled_at: string | null
}

export type PlanStepResponse = {
  step_id: string
  type: string
  params: Record<string, unknown>
  depends_on: string[]
  produces: string[]
}

export type LLMPlanResponse = {
  plan_version: number
  plan_id: string
  rel_path: string
  steps: PlanStepResponse[]
}

export type FreezePlanRequest = { notes: string | null }
export type FreezePlanResponse = { job_id: string; plan: LLMPlanResponse }
export type GetPlanResponse = { job_id: string; plan: LLMPlanResponse }

export type JobTimestamps = { created_at: string; scheduled_at: string | null }

export type DraftSummary = { created_at: string; text_chars: number }

export type ArtifactsSummary = { total: number; by_kind: Record<string, number> }

export type RunAttemptSummary = {
  run_id: string
  attempt: number
  status: string
  started_at: string | null
  ended_at: string | null
  artifacts_count: number
}

export type GetJobResponse = {
  job_id: string
  trace_id: string | null
  status: SSJobStatus
  timestamps: JobTimestamps
  draft: DraftSummary | null
  artifacts: ArtifactsSummary
  latest_run: RunAttemptSummary | null
}

export type ArtifactIndexItem = {
  kind: string
  rel_path: string
  created_at: string | null
  meta: Record<string, string | number | boolean | null>
}

export type ArtifactsIndexResponse = { job_id: string; artifacts: ArtifactIndexItem[] }

export type InputsUploadResponse = {
  job_id: string
  manifest_rel_path: string
  fingerprint: string
}

export type InputsPreviewColumn = { name: string; inferred_type: string }

export type InputsPreviewResponse = {
  job_id: string
  row_count: number | null
  columns: InputsPreviewColumn[]
  sample_rows: Array<Record<string, string | number | boolean | null>>
}

export type DraftPreviewDataSource = {
  dataset_key: string
  role: string
  original_name: string
  format: string
}

export type DraftPreviewDecision = 'auto_freeze' | 'require_confirm' | 'require_confirm_with_downgrade'

export type DraftPreviewPendingResponse = {
  status: 'pending'
  message?: string
  retry_after_seconds: number
  retry_until?: string
}

export type DraftQualityWarning = {
  type: string
  severity: string
  message: string
  suggestion?: string
}

export type DraftStage1Option = {
  option_id: string
  label: string
  value: string | number | boolean | null
}

export type DraftStage1Question = {
  question_id: string
  question_text: string
  question_type: string
  options: DraftStage1Option[]
  priority?: number
}

export type DraftOpenUnknown = {
  field: string
  description: string
  impact?: string
  blocking?: boolean
  candidates?: string[]
}

export type DraftPreviewReadyResponse = {
  job_id: string
  draft_text: string
  draft_id?: string
  status?: string
  decision?: DraftPreviewDecision
  risk_score?: number
  outcome_var: string | null
  treatment_var: string | null
  controls: string[]
  column_candidates?: string[]
  variable_types?: InputsPreviewColumn[]
  data_sources?: DraftPreviewDataSource[]
  data_quality_warnings?: DraftQualityWarning[]
  stage1_questions?: DraftStage1Question[]
  open_unknowns?: DraftOpenUnknown[]
  default_overrides?: Record<string, unknown>
}

export type DraftPreviewResponse = DraftPreviewPendingResponse | DraftPreviewReadyResponse

export type DraftPatchRequest = { field_updates: Record<string, string> }

export type DraftPatchResponse = {
  status: string
  patched_fields?: string[]
  remaining_unknowns_count?: number
  open_unknowns?: DraftOpenUnknown[]
  draft_preview?: Partial<DraftPreviewReadyResponse>
}

export type RunJobResponse = { job_id: string; status: SSJobStatus; scheduled_at: string | null }
