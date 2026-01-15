// GENERATED FILE - DO NOT EDIT.
// Source: FastAPI OpenAPI → openapi-typescript@7.9.1.
// Run: scripts/contract_sync.sh generate

export interface components {
    schemas: {
        ArtifactIndexItem: {
            created_at?: string | null;
            kind: string;
            meta?: {
                [key: string]: string | number | boolean | null;
            };
            rel_path: string;
        };
        ArtifactsIndexResponse: {
            artifacts?: components["schemas"]["ArtifactIndexItem"][];
            job_id: string;
        };
        ArtifactsSummary: {
            by_kind?: {
                [key: string]: number;
            };
            total: number;
        };
        ConfirmJobRequest: {
            answers: {
                [key: string]: components["schemas"]["JsonValue-Input"];
            };
            confirmed: boolean;
            default_overrides: {
                [key: string]: components["schemas"]["JsonValue-Input"];
            };
            expert_suggestions_feedback: {
                [key: string]: components["schemas"]["JsonValue-Input"];
            };
            notes?: string | null;
            output_formats?: string[] | null;
            variable_corrections: {
                [key: string]: string;
            };
        };
        ConfirmJobResponse: {
            job_id: string;
            message: string;
            scheduled_at?: string | null;
            status: string;
        };
        DraftDataQualityWarning: {
            message: string;
            severity: string;
            suggestion?: string | null;
            type: string;
        };
        DraftOpenUnknown: {
            blocking?: boolean | null;
            candidates?: string[];
            description: string;
            field: string;
            impact: string;
        };
        DraftPatchRequest: {
            field_updates?: {
                [key: string]: components["schemas"]["JsonValue-Input"];
            };
        };
        DraftPatchResponse: {
            draft_preview?: {
                [key: string]: components["schemas"]["JsonValue-Output"];
            };
            open_unknowns?: components["schemas"]["DraftOpenUnknown"][];
            patched_fields?: string[];
            remaining_unknowns_count: number;
            status: "patched";
        };
        DraftPreviewDataSource: {
            dataset_key: string;
            format: string;
            original_name: string;
            role: string;
        };
        DraftPreviewPendingResponse: {
            message: string;
            retry_after_seconds: number;
            retry_until: string;
            status: "pending";
        };
        DraftPreviewResponse: {
            column_candidates?: string[];
            controls?: string[];
            data_quality_warnings?: components["schemas"]["DraftDataQualityWarning"][];
            data_sources?: components["schemas"]["DraftPreviewDataSource"][];
            decision: "auto_freeze" | "require_confirm" | "require_confirm_with_downgrade";
            default_overrides?: {
                [key: string]: components["schemas"]["JsonValue-Output"];
            };
            draft_id: string;
            draft_text: string;
            job_id: string;
            open_unknowns?: components["schemas"]["DraftOpenUnknown"][];
            outcome_var?: string | null;
            risk_score: number;
            stage1_questions?: components["schemas"]["DraftStage1Question"][];
            status: "ready";
            treatment_var?: string | null;
            variable_types?: components["schemas"]["InputsPreviewColumn"][];
        };
        DraftStage1Option: {
            label: string;
            option_id: string;
            value: components["schemas"]["JsonScalar"];
        };
        DraftStage1Question: {
            options?: components["schemas"]["DraftStage1Option"][];
            priority: number;
            question_id: string;
            question_text: string;
            question_type: string;
        };
        DraftSummary: {
            created_at: string;
            text_chars: number;
        };
        FreezePlanRequest: {
            answers?: {
                [key: string]: components["schemas"]["JsonValue-Input"];
            };
            notes?: string | null;
        };
        FreezePlanResponse: {
            job_id: string;
            plan: components["schemas"]["LLMPlanResponse"];
        };
        GetJobResponse: {
            artifacts: components["schemas"]["ArtifactsSummary"];
            draft?: components["schemas"]["DraftSummary"] | null;
            job_id: string;
            latest_run?: components["schemas"]["RunAttemptSummary"] | null;
            selected_template_id?: string | null;
            status: string;
            timestamps: components["schemas"]["JobTimestamps"];
            trace_id?: string | null;
        };
        GetPlanResponse: {
            job_id: string;
            plan: components["schemas"]["LLMPlanResponse"];
        };
        InputsPreviewColumn: {
            inferred_type: string;
            name: string;
        };
        InputsPreviewResponse: {
            column_count?: number | null;
            columns?: components["schemas"]["InputsPreviewColumn"][];
            header_row?: boolean | null;
            job_id: string;
            row_count?: number | null;
            sample_rows?: {
                [key: string]: string | number | boolean | null;
            }[];
            selected_sheet?: string | null;
            sheet_names?: string[];
        };
        InputsUploadResponse: {
            fingerprint: string;
            job_id: string;
            manifest_rel_path: string;
        };
        JobTimestamps: {
            created_at: string;
            scheduled_at?: string | null;
        };
        JsonScalar: string | number | boolean | null;
        "JsonValue-Input": components["schemas"]["JsonScalar"] | components["schemas"]["JsonValue-Input"][] | {
            [key: string]: components["schemas"]["JsonValue-Input"];
        };
        "JsonValue-Output": components["schemas"]["JsonScalar"] | components["schemas"]["JsonValue-Output"][] | {
            [key: string]: components["schemas"]["JsonValue-Output"];
        };
        LLMPlanResponse: {
            plan_id: string;
            plan_version: number;
            rel_path: string;
            steps?: components["schemas"]["PlanStepResponse"][];
        };
        PlanStepResponse: {
            depends_on?: string[];
            params?: {
                [key: string]: components["schemas"]["JsonValue-Output"];
            };
            produces?: string[];
            step_id: string;
            type: string;
        };
        RunAttemptSummary: {
            artifacts_count: number;
            attempt: number;
            ended_at?: string | null;
            run_id: string;
            started_at?: string | null;
            status: string;
        };
        RunJobResponse: {
            job_id: string;
            scheduled_at?: string | null;
            status: string;
        };
        TaskCodeRedeemRequest: {
            requirement: string;
            task_code: string;
        };
        TaskCodeRedeemResponse: {
            expires_at: string;
            is_idempotent: boolean;
            job_id: string;
            token: string;
        };
    };
    responses: never;
    parameters: never;
    requestBodies: never;
    headers: never;
    pathItems: never;
}
export type $defs = Record<string, never>;
export type operations = Record<string, never>;

export type JsonScalar = components['schemas']['JsonScalar'];
type JsonValueInput = components['schemas']['JsonValue-Input'];
type JsonValueOutput = components['schemas']['JsonValue-Output'];
export type JsonValue = JsonValueInput | JsonValueOutput;
export type RedeemTaskCodeRequest = components['schemas']['TaskCodeRedeemRequest'];
export type RedeemTaskCodeResponse = components['schemas']['TaskCodeRedeemResponse'];
export type ConfirmJobRequest = components['schemas']['ConfirmJobRequest'];
export type ConfirmJobResponse = components['schemas']['ConfirmJobResponse'];
export type PlanStepResponse = components['schemas']['PlanStepResponse'];
export type LLMPlanResponse = components['schemas']['LLMPlanResponse'];
export type FreezePlanRequest = components['schemas']['FreezePlanRequest'];
export type FreezePlanResponse = components['schemas']['FreezePlanResponse'];
export type GetPlanResponse = components['schemas']['GetPlanResponse'];
export type JobTimestamps = components['schemas']['JobTimestamps'];
export type DraftSummary = components['schemas']['DraftSummary'];
export type ArtifactsSummary = components['schemas']['ArtifactsSummary'];
export type RunAttemptSummary = components['schemas']['RunAttemptSummary'];
export type GetJobResponse = components['schemas']['GetJobResponse'];
export type ArtifactIndexItem = components['schemas']['ArtifactIndexItem'];
export type ArtifactsIndexResponse = components['schemas']['ArtifactsIndexResponse'];
export type InputsUploadResponse = components['schemas']['InputsUploadResponse'];
export type InputsPreviewColumn = components['schemas']['InputsPreviewColumn'];
export type InputsPreviewResponse = components['schemas']['InputsPreviewResponse'];
export type DraftPreviewDataSource = components['schemas']['DraftPreviewDataSource'];
export type DraftPreviewPendingResponse = components['schemas']['DraftPreviewPendingResponse'];
export type DraftQualityWarning = components['schemas']['DraftDataQualityWarning'];
export type DraftStage1Option = components['schemas']['DraftStage1Option'];
export type DraftStage1Question = components['schemas']['DraftStage1Question'];
export type DraftOpenUnknown = components['schemas']['DraftOpenUnknown'];
export type DraftPreviewReadyResponse = components['schemas']['DraftPreviewResponse'];
export type DraftPreviewDecision = DraftPreviewReadyResponse['decision'];
export type DraftPreviewResponse = DraftPreviewPendingResponse | DraftPreviewReadyResponse;
export type DraftPatchRequest = components['schemas']['DraftPatchRequest'];
export type DraftPatchResponse = components['schemas']['DraftPatchResponse'];
export type RunJobResponse = components['schemas']['RunJobResponse'];
export type SSJobStatus = GetJobResponse['status'];
