import { useState, useEffect, useRef, useCallback } from "react";
import { Loader2, Send, ArrowLeft, CheckCircle, Upload, AlertTriangle, FileText, Plus, X, RefreshCw } from "lucide-react";
import { Button } from "./ui/button";
import { DraftPreview } from "./DraftPreview";
import { ClarificationQuestions } from "./ClarificationQuestions";
import { DefaultsEditor } from "./DefaultsEditor";
import {
    getDraftPreview,
    patchDraft,
    confirmDraft,
    appendFiles,
    getBundle,
    PreviewTimeoutError,
    type DraftPreviewResponse,
    type UploadProgress,
} from "@/api/stataService";
import { Card, CardContent } from "./ui/card";
import { Progress } from "./ui/progress";

interface ConfirmationStepProps {
    jobId: string;
    onConfirmed: () => void;
    onBack: () => void;
}

type ConfirmationState =
    | "loading"
    | "preview"
    | "confirming"
    | "confirmed"
    | "error";

function isBlockingUnknown(u: any): boolean {
    if (u && typeof u.blocking === "boolean") {
        return u.blocking;
    }
    const impact = String((u && u.impact) || "").toLowerCase();
    return impact === "high" || impact === "critical";
}

export function ConfirmationStep({
    jobId,
    onConfirmed,
    onBack,
}: ConfirmationStepProps) {
    const [state, setState] = useState<ConfirmationState>("loading");
    const [draft, setDraft] = useState<DraftPreviewResponse | null>(null);
    const [answers, setAnswers] = useState<Record<string, string[]>>({});
    const [defaultOverrides, setDefaultOverrides] = useState<Record<string, unknown>>({});
    const [variableCorrections, setVariableCorrections] = useState<Record<string, string>>({});
    const [inlineClarifications, setInlineClarifications] = useState<Record<string, string>>({});
    const [expertSuggestionsFeedback, setExpertSuggestionsFeedback] = useState<Record<string, boolean>>({});
    const [currentStage, setCurrentStage] = useState<1 | 2>(1);
    const [error, setError] = useState<string | null>(null);
    const [loadingHint, setLoadingHint] = useState<string | null>(null);
    const [timeoutRetryAfter, setTimeoutRetryAfter] = useState<number | null>(null);
    const [timeoutCountdown, setTimeoutCountdown] = useState<number | null>(null);
    const timeoutRetryTimerRef = useRef<number | null>(null);
    const timeoutRetryCountRef = useRef(0);
    const [confirmRetryUntil, setConfirmRetryUntil] = useState<string | null>(null);
    const [confirmMessage, setConfirmMessage] = useState<string | null>(null);

    // UX-002: append files on confirmation page (last chance)
    const [bundleFilenames, setBundleFilenames] = useState<string[]>([]);
    const [appendExpanded, setAppendExpanded] = useState(false);
    const [additionalFiles, setAdditionalFiles] = useState<File[]>([]);
    const [appendProgress, setAppendProgress] = useState<UploadProgress[]>([]);
    const [isAppending, setIsAppending] = useState(false);
    const [appendError, setAppendError] = useState<string | null>(null);
    const [appendSuccess, setAppendSuccess] = useState<string | null>(null);
    const [appendUsed, setAppendUsed] = useState(false);

    const loadDraft = useCallback(async () => {
        try {
            setState("loading");
            setError(null);
            setLoadingHint(null);
            setTimeoutRetryAfter(null);
            setTimeoutCountdown(null);

            const draftData = await getDraftPreview(jobId);
            timeoutRetryCountRef.current = 0;
            setDraft(draftData);
            setAnswers({});
            setDefaultOverrides({});
            setVariableCorrections({});
            setInlineClarifications({});

            const suggestions = Array.isArray(draftData.expert_suggestions) ? draftData.expert_suggestions : [];
            const initialFeedback: Record<string, boolean> = {};
            for (const s of suggestions) {
                const key =
                    (s && typeof s.key === "string" && s.key) ||
                    (s && typeof s.title === "string" && s.title) ||
                    "";
                if (key) initialFeedback[key] = true;
            }
            setExpertSuggestionsFeedback(initialFeedback);
            setState("preview");
            setCurrentStage(1);

            // Load bundle filenames for duplicate-name protection
            try {
                const manifest = await getBundle(jobId);
                setBundleFilenames((manifest.files || []).map((f) => f.filename));
            } catch {
                // Non-blocking
            }

            // If auto_freeze, skip confirmation
            const stage1Count = (draftData.stage1_questions || []).length;
            const hasBlockingUnknowns = (draftData.open_unknowns || []).some(isBlockingUnknown);
            if (draftData.decision === "auto_freeze" && stage1Count === 0 && !hasBlockingUnknowns) {
                // Auto confirm for low-risk tasks
                const suggestions = Array.isArray(draftData.expert_suggestions) ? draftData.expert_suggestions : [];
                const initialFeedback: Record<string, boolean> = {};
                for (const s of suggestions) {
                    const key =
                        (s && typeof s.key === "string" && s.key) ||
                        (s && typeof s.title === "string" && s.title) ||
                        "";
                    if (key) initialFeedback[key] = true;
                }
                await confirmDraft(jobId, {}, {}, {}, initialFeedback);
                setState("confirmed");
                setTimeout(() => onConfirmed(), 1500);
            }
        } catch (err) {
            if (err instanceof PreviewTimeoutError) {
                timeoutRetryCountRef.current += 1;
                const retryAfter = Math.max(1, Number(err.retryAfter || 5));
                setLoadingHint(err.message);
                setTimeoutRetryAfter(retryAfter);
                setTimeoutCountdown(retryAfter);
                setState("loading");

                if (timeoutRetryCountRef.current <= 6) {
                    if (timeoutRetryTimerRef.current) {
                        window.clearTimeout(timeoutRetryTimerRef.current);
                    }
                    timeoutRetryTimerRef.current = window.setTimeout(() => {
                        void loadDraft();
                    }, retryAfter * 1000);
                    return;
                }

                // 停止自动重试，但保持“处理中”语义（窗口内不失败）
                setLoadingHint("预处理中，等待时间较长，你可以稍后手动刷新。");
                setTimeoutRetryAfter(null);
                setTimeoutCountdown(null);
                setState("loading");
                return;
            }

            const msg =
                (typeof err === "object" &&
                    err &&
                    "message" in err &&
                    typeof (err as { message?: unknown }).message === "string" &&
                    (err as { message: string }).message) ||
                (err instanceof Error ? err.message : null) ||
                "加载未完成";
            setError(msg);
            setState("error");
        }
    }, [jobId, onConfirmed]);

    // Load draft preview
    useEffect(() => {
        void loadDraft();
        return () => {
            if (timeoutRetryTimerRef.current) {
                window.clearTimeout(timeoutRetryTimerRef.current);
                timeoutRetryTimerRef.current = null;
            }
        };
    }, [loadDraft]);

    // Countdown display for auto-retry (best-effort)
    useEffect(() => {
        if (state !== "loading") return;
        if (!timeoutCountdown || timeoutCountdown <= 0) return;

        const id = window.setTimeout(() => {
            setTimeoutCountdown((v) => (v ? Math.max(0, v - 1) : v));
        }, 1000);
        return () => window.clearTimeout(id);
    }, [state, timeoutCountdown]);

    useEffect(() => {
        const key = `stata_service_append_used:${jobId}`;
        setAppendUsed(localStorage.getItem(key) === "1");
    }, [jobId]);

    const handleAnswerChange = (questionId: string, optionIds: string[]) => {
        setAnswers((prev) => ({
            ...prev,
            [questionId]: optionIds,
        }));
    };

    const handleConfirm = async () => {
        if (draft?.decision === "require_confirm_with_downgrade") {
            const confirmed = window.confirm(
                "该任务存在降级风险，确认继续将以降级方案执行。是否仍要确认？"
            );
            if (!confirmed) return;
        }

        const requiredUnknowns = (draft?.open_unknowns || []).filter(isBlockingUnknown);
        const missingRequired = requiredUnknowns.filter((u) => !(inlineClarifications[u.field] || "").trim());
        if (missingRequired.length > 0) {
            const names = missingRequired
                .slice(0, 3)
                .map((u) => u.display_name || u.field)
                .join("、");
            window.alert(`请先完成待确认事项（必填）：${names}`);
            return;
        }

        try {
            setState("confirming");

            const updates: Record<string, string> = {};
            for (const u of draft?.open_unknowns || []) {
                const v = (inlineClarifications[u.field] || "").trim();
                if (v) updates[u.field] = v;
            }

            if (Object.keys(updates).length > 0) {
                const resp = await patchDraft(jobId, updates);

                setDraft((prev) => {
                    if (!prev) return prev;
                    const controls = Array.isArray(resp.draft_preview?.controls)
                        ? (resp.draft_preview.controls as string[])
                        : prev.controls;
                    return {
                        ...prev,
                        goal_type: (resp.draft_preview?.goal_type as DraftPreviewResponse["goal_type"]) || prev.goal_type,
                        outcome_var: resp.draft_preview?.outcome_var ?? prev.outcome_var,
                        treatment_var: resp.draft_preview?.treatment_var ?? prev.treatment_var,
                        controls,
                        open_unknowns: resp.open_unknowns ?? prev.open_unknowns,
                    };
                });

                setInlineClarifications((prev) => {
                    const next = { ...prev };
                    for (const k of Object.keys(updates)) delete next[k];
                    return next;
                });

                const remainingBlocking = (resp.open_unknowns || []).filter(isBlockingUnknown);
                if (remainingBlocking.length > 0) {
                    window.alert("仍有未澄清的必填项，请继续填写后再确认执行。");
                    setState("preview");
                    return;
                }
            }

            const resp = await confirmDraft(jobId, answers, defaultOverrides, variableCorrections, expertSuggestionsFeedback);
            const retryUntil = typeof resp.retry_until === "string" ? resp.retry_until : null;
            setConfirmRetryUntil(retryUntil);
            setConfirmMessage(typeof resp.message === "string" ? resp.message : null);
            if (retryUntil) {
                try {
                    localStorage.setItem(`stata_service_retry_until:${jobId}`, retryUntil);
                } catch {
                    // ignore
                }
            }
            setState("confirmed");
            setTimeout(() => onConfirmed(), 1500);
        } catch (err) {
            setError(err instanceof Error ? err.message : "暂时无法提交，请稍后再试");
            setState("error");
        }
    };

    const handleAdditionalFiles = (e: React.ChangeEvent<HTMLInputElement>) => {
        setAppendError(null);
        const selected = Array.from(e.target.files || []);
        if (selected.length === 0) return;

        const existing = new Set<string>([...bundleFilenames, ...additionalFiles.map((f) => f.name)]);
        const accepted: File[] = [];
        const rejected: string[] = [];

        for (const file of selected) {
            if (existing.has(file.name)) {
                rejected.push(file.name);
                continue;
            }
            existing.add(file.name);
            accepted.push(file);
        }

        if (rejected.length > 0) {
            setAppendError(`以下文件名已存在，无法重复上传：${rejected.join("、")}`);
        }

        if (accepted.length > 0) {
            setAdditionalFiles((prev) => [...prev, ...accepted]);
        }

        // Allow selecting the same file again after removal
        e.target.value = "";
    };

    const removeAdditionalFile = (index: number) => {
        setAdditionalFiles((prev) => prev.filter((_, i) => i !== index));
    };

    const clearAdditionalFiles = () => {
        setAdditionalFiles([]);
        setAppendProgress([]);
        setAppendError(null);
    };

    const appendTotalProgress =
        appendProgress.length > 0
            ? appendProgress.reduce((sum, p) => sum + p.progress, 0) / appendProgress.length
            : 0;

    const handleAppendUpload = async () => {
        if (additionalFiles.length === 0) return;

        setIsAppending(true);
        setAppendError(null);
        setAppendSuccess(null);
        setAppendProgress([]);

        try {
            const resp = await appendFiles(jobId, additionalFiles, (p) => {
                setAppendProgress([...p]);
            });

            const key = `stata_service_append_used:${jobId}`;
            localStorage.setItem(key, "1");
            setAppendUsed(true);

            setBundleFilenames((prev) => [...prev, ...resp.appended_files]);
            setAdditionalFiles([]);
            setAppendExpanded(false);
            setAppendSuccess(`已追加上传 ${resp.appended_files.length} 个文件，将重新解析需求`);

            // Refresh draft/questions after file changes (backend caching handled separately)
            const refreshed = await getDraftPreview(jobId, { force: true });
            setDraft(refreshed);
            setAnswers({});
            setDefaultOverrides({});
            setVariableCorrections({});
            setInlineClarifications({});
            const suggestions = Array.isArray(refreshed.expert_suggestions) ? refreshed.expert_suggestions : [];
            const initialFeedback: Record<string, boolean> = {};
            for (const s of suggestions) {
                const key =
                    (s && typeof s.key === "string" && s.key) ||
                    (s && typeof s.title === "string" && s.title) ||
                    "";
                if (key) initialFeedback[key] = true;
            }
            setExpertSuggestionsFeedback(initialFeedback);
            setCurrentStage(1);
        } catch (err) {
            setAppendError(err instanceof Error ? err.message : "追加上传未完成");
        } finally {
            setIsAppending(false);
        }
    };

    const getStage1Questions = () => {
        if (!draft) return [];
        return draft.stage1_questions ?? [];
    };

    const getStage2Defaults = () => {
        if (!draft) return [];
        return draft.stage2_defaults ?? [];
    };

    const getStage2Optional = () => {
        if (!draft) return [];
        return draft.stage2_optional ?? [];
    };

    const hasStage2 = () => {
        return getStage2Defaults().length > 0 || getStage2Optional().length > 0;
    };

    const isStage1Answered = () => {
        const stage1 = getStage1Questions();
        if (stage1.length === 0) return true;
        return stage1.every((q) => (answers[q.question_id] || []).length > 0);
    };

    // Loading state
    if (state === "loading") {
        return (
            <Card className="border-primary/20">
                <CardContent className="py-12">
                    <div className="flex flex-col items-center justify-center gap-4">
                        <Loader2 className="h-8 w-8 animate-spin text-primary" />
                        <div className="text-center">
                            <div className="font-medium">正在分析您的需求...</div>
                            <div className="text-sm text-muted-foreground mt-1">
                                {loadingHint || "Stata Service Team 正在解析您的研究需求，请勿关闭页面"}
                            </div>
                            {timeoutRetryAfter !== null && (
                                <div className="mt-3 flex flex-col items-center gap-2">
                                    <div className="text-xs text-muted-foreground">
                                        {timeoutCountdown !== null && timeoutCountdown > 0
                                            ? `${timeoutCountdown} 秒后自动重试`
                                            : "即将自动重试"}
                                    </div>
                                    <Button
                                        type="button"
                                        variant="outline"
                                        size="sm"
                                        onClick={() => void loadDraft()}
                                    >
                                        <RefreshCw className="h-4 w-4 mr-2" />
                                        立即重试
                                    </Button>
                                </div>
                            )}
                        </div>
                    </div>
                </CardContent>
            </Card>
        );
    }

    // Error state
    if (state === "error") {
        return (
            <Card className="border-red-200">
                <CardContent className="py-8">
                    <div className="text-center">
                        <div className="text-red-600 font-medium mb-2">预处理未完成</div>
                        <div className="text-sm text-muted-foreground mb-4">{error}</div>
                        <Button variant="outline" onClick={onBack}>
                            <ArrowLeft className="h-4 w-4 mr-2" />
                            返回修改
                        </Button>
                    </div>
                </CardContent>
            </Card>
        );
    }

    // Confirmed state
    if (state === "confirmed") {
        const retryUntilText = (() => {
            if (!confirmRetryUntil) return null;
            try {
                const d = new Date(confirmRetryUntil);
                if (Number.isNaN(d.getTime())) return null;
                return d.toLocaleString("zh-CN", { hour12: false });
            } catch {
                return null;
            }
        })();
        return (
            <Card className="border-green-200 bg-green-50">
                <CardContent className="py-12">
                    <div className="flex flex-col items-center justify-center gap-4">
                        <CheckCircle className="h-12 w-12 text-green-600" />
                        <div className="text-center">
                            <div className="font-medium text-green-800">需求已确认</div>
                            <div className="text-sm text-green-600 mt-1">
                                任务已提交，系统开始处理，正在跳转...
                            </div>
                            {retryUntilText ? (
                                <div className="text-sm text-green-700 mt-2">预计完成时间：{retryUntilText}</div>
                            ) : null}
                            {confirmMessage ? (
                                <div className="text-xs text-green-700 mt-2">{confirmMessage}</div>
                            ) : null}
                        </div>
                    </div>
                </CardContent>
            </Card>
        );
    }

    // Preview state
    if (!draft) return null;

    const stage1Questions = getStage1Questions();
    const stage2Defaults = getStage2Defaults();
    const stage2Optional = getStage2Optional();
    const totalStages = hasStage2() ? 2 : 1;

    const requiredUnknowns = (draft.open_unknowns || []).filter(isBlockingUnknown);
    const allRequiredUnknownsClarified = requiredUnknowns.every((u) => (inlineClarifications[u.field] || "").trim());

    const StageIndicator = () => (
        <div className="space-y-2">
            <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>步骤 {currentStage}/{totalStages}</span>
                {currentStage === 1 ? (
                    <span>核心问题（必答）</span>
                ) : (
                    <span>默认值与可选细化</span>
                )}
            </div>
            <Progress value={(currentStage / totalStages) * 100} className="h-2" />
        </div>
    );

    return (
        <div className="space-y-6 animate-fadeIn max-w-4xl mx-auto">
            {/* G3: Contract Header */}
            <div className="mb-6 text-center">
                <h2 className="text-2xl font-bold text-foreground">分析契约单</h2>
                <p className="text-muted-foreground text-sm mt-1">系统根据您提交的数据与描述生成的实证方案</p>
            </div>

            {/* G3: Alert Banner */}
            <div className="mb-8 p-6 rounded-2xl bg-gradient-to-r from-primary/5 to-primary/10 border border-primary/20 flex items-start gap-4 shadow-sm">
                <div className="p-2 bg-primary/10 rounded-lg text-primary shrink-0">
                    <AlertTriangle className="w-5 h-5" />
                </div>
                <div>
                    <h3 className="text-primary font-bold mb-1">请确认变量映射关系</h3>
                    <p className="text-primary/70 text-sm leading-relaxed">
                        智能化引擎已识别出以下核心变量。这是后续回归分析的基础，请务必核对。如识别有误，请点击右侧"手动修正"。
                    </p>
                </div>
            </div>

            {/* Draft Preview */}
            <DraftPreview
                draft={draft}
                variableCorrections={variableCorrections}
                onVariableCorrectionsChange={setVariableCorrections}
                clarifications={inlineClarifications}
                onClarificationChange={(field, value) =>
                    setInlineClarifications((prev) => ({ ...prev, [field]: value }))
                }
                onEditDefaults={() => {
                    if (totalStages === 2) setCurrentStage(2);
                }}
                stage1Questions={stage1Questions}
                stage1Answers={answers}
                onStage1AnswerChange={handleAnswerChange}
            />

            {/* AAU-MUST-004: expert_suggestions（非阻断建议） */}
            {Array.isArray(draft.expert_suggestions) && draft.expert_suggestions.length > 0 && (
                <Card className="border-primary/20">
                    <CardContent className="py-5 space-y-3">
                        <div className="flex items-center justify-between gap-3">
                            <h4 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                                <FileText className="h-4 w-4" />
                                专家建议（可选，默认采纳）
                            </h4>
                            <div className="text-xs text-muted-foreground">采纳/忽略仅影响执行参数记录，不会阻断执行</div>
                        </div>
                        <div className="space-y-3">
                            {draft.expert_suggestions.map((s, idx) => {
                                const key =
                                    (s && typeof s.key === "string" && s.key) ||
                                    (s && typeof s.title === "string" && s.title) ||
                                    `expert_${idx}`;
                                const accepted = expertSuggestionsFeedback[key] !== false;
                                return (
                                    <div
                                        key={key}
                                        className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm space-y-2"
                                    >
                                        <div className="flex items-start justify-between gap-4">
                                            <div className="min-w-0">
                                                <div className="font-semibold text-gray-900">
                                                    {s?.title || `建议 ${idx + 1}`}
                                                </div>
                                                {s?.recommendation && (
                                                    <div className="text-sm text-gray-700 mt-1 whitespace-pre-line">
                                                        {s.recommendation}
                                                    </div>
                                                )}
                                                {s?.rationale && (
                                                    <div className="text-xs text-muted-foreground mt-2">
                                                        理由：{s.rationale}
                                                    </div>
                                                )}
                                                {s?.risk && (
                                                    <div className="text-xs text-muted-foreground mt-1">
                                                        风险：{s.risk}
                                                    </div>
                                                )}
                                            </div>
                                            <div className="flex shrink-0 items-center gap-2">
                                                <Button
                                                    type="button"
                                                    size="sm"
                                                    variant={accepted ? "default" : "outline"}
                                                    onClick={() =>
                                                        setExpertSuggestionsFeedback((prev) => ({ ...prev, [key]: true }))
                                                    }
                                                >
                                                    采纳
                                                </Button>
                                                <Button
                                                    type="button"
                                                    size="sm"
                                                    variant={!accepted ? "default" : "outline"}
                                                    onClick={() =>
                                                        setExpertSuggestionsFeedback((prev) => ({ ...prev, [key]: false }))
                                                    }
                                                >
                                                    忽略
                                                </Button>
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </CardContent>
                </Card>
            )}


            {/* G3: Append files feature disabled - single upload only */}
            {false && (
                <Card className="border-amber-200 bg-amber-50/50">
                    <CardContent className="py-4 space-y-3">
                        <div className="flex items-start justify-between gap-3">
                            <div className="flex items-start gap-3">
                                {appendUsed ? (
                                    <CheckCircle className="h-5 w-5 text-green-600 mt-0.5 flex-shrink-0" />
                                ) : (
                                    <AlertTriangle className="h-5 w-5 text-amber-600 mt-0.5 flex-shrink-0" />
                                )}
                                <div>
                                    <p className="text-sm font-medium text-amber-900">
                                        遗漏文件？可追加上传（最后一次机会）
                                    </p>
                                    <p className="text-xs text-amber-700 mt-1">
                                        追加上传完成后将重新解析需求，并可能更新澄清问题与默认值建议
                                    </p>
                                    {appendUsed && (
                                        <p className="text-xs text-green-700 mt-1">
                                            已使用补充上传机会，如仍有遗漏请联系服务团队
                                        </p>
                                    )}
                                </div>
                            </div>
                            {!appendUsed && (
                                <Button
                                    type="button"
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setAppendExpanded((v) => !v)}
                                    disabled={state === "confirming" || isAppending}
                                >
                                    {appendExpanded ? "收起" : "展开"}
                                </Button>
                            )}
                        </div>

                        {!appendUsed && appendExpanded && (
                            <div className="space-y-3">
                                <input
                                    type="file"
                                    id="additionalFiles"
                                    onChange={handleAdditionalFiles}
                                    className="hidden"
                                    multiple
                                    disabled={state === "confirming" || isAppending}
                                    accept=".dta,.xlsx,.xls,.csv,.docx,.doc,.pdf,.txt"
                                />
                                <label
                                    htmlFor="additionalFiles"
                                    className={`flex items-center justify-center gap-2 p-4 border-2 border-dashed rounded-lg transition-colors cursor-pointer
                                  ${state === "confirming" || isAppending
                                            ? "border-gray-200 bg-gray-50 cursor-not-allowed"
                                            : "border-amber-200 hover:border-amber-400 hover:bg-amber-50"
                                        }`}
                                >
                                    <Plus className="h-4 w-4 text-amber-700" />
                                    <span className="text-sm text-amber-800">点击选择要追加的文件</span>
                                </label>

                                {additionalFiles.length > 0 && (
                                    <div className="space-y-2">
                                        {additionalFiles.map((file, idx) => (
                                            <div
                                                key={`${file.name}-${idx}`}
                                                className="flex items-center gap-2 p-3 bg-white rounded-lg border border-amber-100"
                                            >
                                                <FileText className="h-4 w-4 text-amber-700 flex-shrink-0" />
                                                <span className="flex-1 truncate text-sm">{file.name}</span>
                                                <span className="text-xs text-muted-foreground">
                                                    {(file.size / 1024).toFixed(1)} KB
                                                </span>
                                                {!isAppending && (
                                                    <button
                                                        type="button"
                                                        onClick={() => removeAdditionalFile(idx)}
                                                        className="p-1 hover:bg-amber-50 rounded"
                                                    >
                                                        <X className="h-4 w-4 text-muted-foreground" />
                                                    </button>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                )}

                                {isAppending && appendProgress.length > 0 && (
                                    <div className="space-y-2 p-4 bg-white rounded-lg border border-amber-100">
                                        <div className="flex items-center justify-between text-sm">
                                            <span className="text-amber-800">追加上传进度</span>
                                            <span className="text-amber-800">{Math.round(appendTotalProgress)}%</span>
                                        </div>
                                        <Progress value={appendTotalProgress} className="h-2" />
                                        <div className="text-xs text-amber-700">
                                            {appendProgress.filter((p) => p.status === "done").length} /{" "}
                                            {appendProgress.length} 文件已完成
                                        </div>
                                    </div>
                                )}

                                {appendError && (
                                    <p className="text-xs text-red-600">{appendError}</p>
                                )}
                                {appendSuccess && (
                                    <p className="text-xs text-green-700">{appendSuccess}</p>
                                )}

                                <div className="flex items-center justify-end gap-2 pt-1">
                                    <Button
                                        type="button"
                                        variant="outline"
                                        onClick={clearAdditionalFiles}
                                        disabled={state === "confirming" || isAppending || additionalFiles.length === 0}
                                    >
                                        清空
                                    </Button>
                                    <Button
                                        type="button"
                                        onClick={handleAppendUpload}
                                        disabled={
                                            state === "confirming" ||
                                            isAppending ||
                                            additionalFiles.length === 0
                                        }
                                        className="bg-amber-600 hover:bg-amber-700"
                                    >
                                        <Upload className="h-4 w-4 mr-2" />
                                        {isAppending ? "上传中..." : "上传追加文件"}
                                    </Button>
                                </div>
                            </div>
                        )}
                    </CardContent>
                </Card>
            )}

            {/* Two-stage flow: stage2 defaults/optional only (stage1 now in DraftPreview) */}
            {totalStages === 2 && currentStage === 2 && (
                <>
                    <StageIndicator />

                    <DefaultsEditor
                        defaults={stage2Defaults}
                        overrides={defaultOverrides}
                        onChange={setDefaultOverrides}
                    />

                    {stage2Optional.length > 0 && (
                        <ClarificationQuestions
                            questions={stage2Optional}
                            answers={answers}
                            onAnswerChange={handleAnswerChange}
                        />
                    )}
                </>
            )}

            {/* Actions */}
            <div className="flex items-center justify-between pt-4">
                {totalStages === 2 && currentStage === 2 ? (
                    <Button
                        variant="outline"
                        onClick={() => setCurrentStage(1)}
                        disabled={state === "confirming" || isAppending}
                    >
                        <ArrowLeft className="h-4 w-4 mr-2" />
                        上一步
                    </Button>
                ) : (
                    <Button variant="outline" onClick={onBack} disabled={state === "confirming" || isAppending}>
                        <ArrowLeft className="h-4 w-4 mr-2" />
                        返回修改
                    </Button>
                )}

                <Button
                    onClick={totalStages === 2 && currentStage === 1 ? () => setCurrentStage(2) : handleConfirm}
                    disabled={
                        state === "confirming" ||
                        isAppending ||
                        !isStage1Answered() ||
                        ((totalStages !== 2 || currentStage !== 1) && !allRequiredUnknownsClarified)
                    }
                    size="lg"
                    className="px-8"
                >
                    {state === "confirming" ? (
                        <>
                            <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                            确认中...
                        </>
                    ) : (
                        <>
                            <Send className="h-4 w-4 mr-2" />
                            {totalStages === 2 && currentStage === 1 ? "下一步" : "确认并开始执行"}
                        </>
                    )}
                </Button>
            </div>

            {/* Helper text */}
            {totalStages === 2 && currentStage === 1 && stage1Questions.length > 0 && !isStage1Answered() && (
                <p className="text-center text-sm text-muted-foreground">
                    请先完成阶段1必答问题后进入下一步
                </p>
            )}
            {(totalStages !== 2 || currentStage !== 1) && requiredUnknowns.length > 0 && !allRequiredUnknownsClarified && (
                <p className="text-center text-sm text-muted-foreground">
                    请先完成待确认事项中的必填项后再确认执行
                </p>
            )}
        </div>
    );
}
