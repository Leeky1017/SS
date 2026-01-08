import { AlertCircle, CheckCircle, CheckCircle2, Target, Variable, AlertTriangle, Database, HelpCircle } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogHeader,
    AlertDialogTitle,
} from "./ui/alert-dialog";
import type { DraftPreviewResponse, ClarificationQuestion } from "@/api/stataService";
import { useState } from "react";
import { DataSourceSelector } from "./DataSourceSelector";
import { InlineClarificationInput } from "./InlineClarificationInput";
import { WideTableConfirmDialog, shouldShowWideTableWarning } from "./WideTableConfirmDialog";

interface DraftPreviewProps {
    draft: DraftPreviewResponse;
    onEditDefaults?: () => void;
    variableCorrections?: Record<string, string>;
    onVariableCorrectionsChange?: (next: Record<string, string>) => void;
    onSelectDataSource?: (sourceId: string) => void;
    isChangingSource?: boolean;
    /** 用户澄清值（字段路径 -> 值） */
    clarifications?: Record<string, string>;
    /** 澄清值变化回调 */
    onClarificationChange?: (field: string, value: string) => void;
    /** 阻断性选择题列表（需在待确认顶部优先显示） */
    stage1Questions?: ClarificationQuestion[];
    /** 选择题答案 */
    stage1Answers?: Record<string, string[]>;
    /** 选择题答案变化回调 */
    onStage1AnswerChange?: (questionId: string, optionIds: string[]) => void;
}

const goalTypeLabels: Record<string, string> = {
    descriptive: "描述性分析",
    predictive: "预测建模",
    causal: "因果推断",
};

export function DraftPreview({
    draft,
    onEditDefaults,
    variableCorrections,
    onVariableCorrectionsChange,
    onSelectDataSource,
    isChangingSource = false,
    clarifications,
    onClarificationChange,
    stage1Questions = [],
    stage1Answers = {},
    onStage1AnswerChange,
}: DraftPreviewProps) {
    const [defaultsExpanded, setDefaultsExpanded] = useState(false);
    const [showMainDataHelp, setShowMainDataHelp] = useState(false);
    const [varTypesExpanded, setVarTypesExpanded] = useState(false);
    const [varMappingEditing, setVarMappingEditing] = useState(false);
    const [wideTableDialogSource, setWideTableDialogSource] = useState<typeof dataSources[0] | null>(null);

    const debugEnabled = (() => {
        if (typeof window === "undefined") return false;
        const params = new URLSearchParams(window.location.search);
        const v = (params.get("debug") || "").toLowerCase();
        return v === "1" || v === "true" || v === "yes" || v === "y";
    })();

    const getRiskColor = (score: number) => {
        if (score <= 25) return "text-green-600";
        if (score <= 60) return "text-yellow-600";
        return "text-red-600";
    };

    const getRiskLabel = (score: number) => {
        if (score <= 25) return "低风险";
        if (score <= 60) return "中等风险";
        return "高风险";
    };

    const getDecisionBadge = (decision: string) => {
        switch (decision) {
            case "auto_freeze":
                return (
                    <span className="inline-flex items-center gap-1 px-2 py-1 bg-green-100 text-green-700 rounded-full text-xs font-medium">
                        <CheckCircle className="h-3 w-3" />
                        可自动执行
                    </span>
                );
            case "require_confirm":
                return (
                    <span className="inline-flex items-center gap-1 px-2 py-1 bg-yellow-100 text-yellow-700 rounded-full text-xs font-medium">
                        <AlertCircle className="h-3 w-3" />
                        需要确认
                    </span>
                );
            case "require_confirm_with_downgrade":
                return (
                    <span className="inline-flex items-center gap-1 px-2 py-1 bg-red-100 text-red-700 rounded-full text-xs font-medium">
                        <AlertTriangle className="h-3 w-3" />
                        高风险需确认
                    </span>
                );
            default:
                return null;
        }
    };

    const defaults = draft.stage2_defaults ?? [];
    const analysisTypes = draft.analysis_types ?? [];
    const dataQualityWarnings = draft.data_quality_warnings ?? [];
    const variableTypes = draft.variable_types ?? [];
    const columnCandidates = draft.column_candidates ?? [];
    const corrections = variableCorrections ?? {};
    const variableCandidates = Array.from(new Set(
        ((Array.isArray(columnCandidates) && columnCandidates.length > 0)
            ? columnCandidates
            : variableTypes.map((v) => v.name)
        ).filter((x) => typeof x === "string" && x.trim())
    ));
    const dataSources = draft.data_sources ?? [];
    const mainSourceId = draft.main_data_source_id ?? null;
    const mainSource =
        (mainSourceId && dataSources.find((s) => s.source_id === mainSourceId)) ||
        dataSources[0] ||
        null;
    const mainSourceLabel = mainSource
        ? `${mainSource.file_name}${mainSource.sheet_name ? ` / ${mainSource.sheet_name}` : ""}`
        : null;
    const mainSourceName = draft.main_data_source_name || mainSourceLabel;
    const mainCols = mainSource?.cols_preview ?? [];
    const mainRowsSample = mainSource?.shape?.n_rows_sample ?? 0;
    const mainColsCount = mainSource?.shape?.n_cols ?? mainCols.length;

    // Handler for data source selection with wide table confirmation
    const handleSourceSelect = (sourceId: string) => {
        const source = dataSources.find((s) => s.source_id === sourceId);
        if (source && shouldShowWideTableWarning(source)) {
            setWideTableDialogSource(source);
        } else {
            onSelectDataSource?.(sourceId);
        }
    };

    const confirmWideTableSource = () => {
        if (wideTableDialogSource) {
            onSelectDataSource?.(wideTableDialogSource.source_id);
        }
        setWideTableDialogSource(null);
    };



    const varTypeLabel: Record<string, string> = {
        continuous: "连续",
        categorical: "类别",
        datetime: "时间",
        id: "ID",
        text: "文本",
    };

    const getVarSourceLabel = (v: (typeof variableTypes)[number]) => {
        const s = v?.source;
        if (!s) return null;
        const fileName = (s.file_name || "").trim();
        const sheetName = (s.sheet_name || "").trim();
        const fileId = (s.file_id || "").trim();
        if (fileName && sheetName) return `${fileName} / ${sheetName}`;
        if (fileName) return fileName;
        return fileId || null;
    };

    const renderSeverity = (severity: string) => {
        if (severity === "error") return <AlertCircle className="h-4 w-4 text-red-600 mt-0.5" />;
        if (severity === "warning") return <AlertTriangle className="h-4 w-4 text-amber-600 mt-0.5" />;
        return <HelpCircle className="h-4 w-4 text-blue-600 mt-0.5" />;
    };

    const getCorrectedVar = (name: string | null) => {
        if (!name) return null;
        return corrections[name] || name;
    };

    const updateCorrection = (from: string, to: string) => {
        if (!onVariableCorrectionsChange) return;

        const f = (from || "").trim();
        const t = (to || "").trim();
        const next = { ...corrections };

        if (!f || !t || f === t) {
            delete next[f];
        } else {
            next[f] = t;
        }
        onVariableCorrectionsChange(next);
    };

    const clearCorrections = () => {
        if (!onVariableCorrectionsChange) return;
        onVariableCorrectionsChange({});
    };

    return (
        <Card className="border-blue-200 bg-gradient-to-br from-blue-50 to-white">
            <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                    <CardTitle className="text-lg flex items-center gap-2">
                        <Target className="h-5 w-5 text-blue-600" />
                        需求理解预览
                    </CardTitle>
                    {getDecisionBadge(draft.decision)}
                </div>
            </CardHeader>
            <CardContent className="space-y-4">
                {/* 研究目标 */}
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <label className="text-sm text-muted-foreground">研究目标类型</label>
                        <div className="text-base font-medium">
                            {goalTypeLabels[draft.goal_type] || draft.goal_type}
                        </div>
                    </div>
                    <div>
                        <label className="text-sm text-muted-foreground">风险评分</label>
                        <div className={`text-base font-medium ${getRiskColor(draft.risk_score)}`}>
                            {draft.risk_score} 分 ({getRiskLabel(draft.risk_score)})
                        </div>
                    </div>
                </div>

                {/* 分析范围预览（T3.2） */}
                {analysisTypes.length > 0 && (
                    <div className="bg-white/50 rounded-lg p-4 space-y-2">
                        <h4 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                            <CheckCircle className="h-4 w-4" />
                            将要执行的分析类型
                        </h4>
                        <div className="flex flex-wrap gap-2">
                            {analysisTypes.map((t) => (
                                <span
                                    key={t}
                                    className="px-2 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 text-xs"
                                >
                                    {t}
                                </span>
                            ))}
                        </div>
                    </div>
                )}

                {/* 数据源选择器 (P4) */}
                {dataSources.length > 1 && onSelectDataSource && (
                    <DataSourceSelector
                        dataSources={dataSources}
                        selectedSourceId={mainSourceId}
                        isAutoSelected={draft.main_data_auto_selected}
                        onSelectSource={handleSourceSelect}
                        isLoading={isChangingSource}
                    />
                )}

                {/* 数据概览（UX-005） */}
                {mainSource && (
                    <div className="bg-white/50 rounded-lg p-4 space-y-3">
                        <h4 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                            <Database className="h-4 w-4" />
                            数据概览
                        </h4>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                            <div className="md:col-span-2">
                                <span className="text-muted-foreground inline-flex items-center gap-1">
                                    主数据源
                                    <button
                                        type="button"
                                        className="inline-flex items-center text-muted-foreground hover:text-foreground"
                                        onClick={() => setShowMainDataHelp(true)}
                                        aria-label="什么是主数据文件？"
                                    >
                                        <HelpCircle className="h-4 w-4" />
                                    </button>
                                    ：
                                </span>
                                <span className="font-mono ml-1 break-all">{mainSourceName}</span>
                                {draft.main_data_auto_selected && (
                                    <div className="mt-2 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-md p-2">
                                        系统暂时自动选择了主数据文件，请确认是否正确；如不正确，请返回上一步重新选择。
                                    </div>
                                )}
                            </div>
                            <div>
                                <span className="text-muted-foreground">行数：</span>
                                <span className="font-mono ml-1">{mainRowsSample.toLocaleString()}</span>
                                <span className="text-xs text-muted-foreground ml-2">（采样）</span>
                            </div>
                            <div>
                                <span className="text-muted-foreground">列数：</span>
                                <span className="font-mono ml-1">{mainColsCount}</span>
                            </div>
                        </div>

                        {/* 按数据源分组显示列名 */}
                        {dataSources.length > 0 && (
                            <div className="space-y-3">
                                {dataSources.map((source) => {
                                    const cols = source.cols_preview ?? [];
                                    if (cols.length === 0) return null;
                                    const isMain = source.source_id === mainSourceId;
                                    const sourceLabel = isMain
                                        ? "主数据文件"
                                        : source.file_name || source.sheet_name || "辅助数据";
                                    return (
                                        <div key={source.source_id}>
                                            <div className="text-sm text-muted-foreground mb-1">
                                                识别的列名（{sourceLabel}）：
                                            </div>
                                            <div className="flex flex-wrap gap-1">
                                                {cols.slice(0, 8).map((col) => (
                                                    <span
                                                        key={`${source.source_id}-${col}`}
                                                        className={`px-2 py-0.5 rounded text-xs font-mono ${isMain
                                                            ? "bg-blue-100 text-blue-800"
                                                            : "bg-gray-200 text-gray-700"
                                                            }`}
                                                    >
                                                        {col}
                                                    </span>
                                                ))}
                                                {cols.length > 8 && (
                                                    <span className="text-xs text-muted-foreground px-2 py-0.5">
                                                        +{cols.length - 8} 更多
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        )}
                    </div>
                )}

                {/* 数据质量预警（T5.4） */}
                {dataQualityWarnings.length > 0 && (
                    <div className="bg-white/50 rounded-lg p-4">
                        <h4 className="text-sm font-semibold text-gray-700 flex items-center gap-2 mb-2">
                            <AlertTriangle className="h-4 w-4" />
                            数据质量预警
                        </h4>
                        <ul className="space-y-2">
                            {dataQualityWarnings.map((w, idx) => (
                                <li key={`${w.type}-${idx}`} className="text-sm flex gap-2">
                                    {renderSeverity(w.severity)}
                                    <div className="flex-1">
                                        <div className="text-gray-800">{w.message}</div>
                                        {w.suggestion && (
                                            <div className="text-xs text-muted-foreground mt-0.5">
                                                建议：{w.suggestion}
                                            </div>
                                        )}
                                    </div>
                                </li>
                            ))}
                        </ul>
                    </div>
                )}

                {/* 变量设定 */}
                <div className="bg-white/50 rounded-lg p-4 space-y-3">
                    <div className="flex items-center justify-between gap-3">
                        <h4 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                            <Variable className="h-4 w-4" />
                            变量设定
                        </h4>
                        {onVariableCorrectionsChange && variableCandidates.length > 0 && (
                            <div className="flex items-center gap-2">
                                {Object.keys(corrections).length > 0 && (
                                    <Button
                                        type="button"
                                        variant="outline"
                                        size="sm"
                                        onClick={clearCorrections}
                                    >
                                        清除修正
                                    </Button>
                                )}
                                <Button
                                    type="button"
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setVarMappingEditing((v) => !v)}
                                >
                                    {varMappingEditing ? "收起" : "修正变量映射"}
                                </Button>
                            </div>
                        )}
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                        <div>
                            <span className="text-muted-foreground">因变量：</span>
                            <span className="font-mono ml-1">
                                {getCorrectedVar(draft.outcome_var) || <span className="text-yellow-600">未确定</span>}
                            </span>
                            {draft.outcome_var && getCorrectedVar(draft.outcome_var) !== draft.outcome_var && (
                                <span className="text-xs text-muted-foreground ml-2">(原：{draft.outcome_var})</span>
                            )}
                        </div>
                        <div>
                            <span className="text-muted-foreground">自变量：</span>
                            <span className="font-mono ml-1">
                                {getCorrectedVar(draft.treatment_var) || <span className="text-yellow-600">未确定</span>}
                            </span>
                            {draft.treatment_var && getCorrectedVar(draft.treatment_var) !== draft.treatment_var && (
                                <span className="text-xs text-muted-foreground ml-2">(原：{draft.treatment_var})</span>
                            )}
                        </div>
                        {draft.controls && draft.controls.length > 0 && (
                            <div className="col-span-2">
                                <span className="text-muted-foreground">控制变量：</span>
                                <span className="font-mono ml-1">
                                    {draft.controls.map((c) => getCorrectedVar(c) || c).join(", ")}
                                </span>
                            </div>
                        )}
                    </div>

                    {varMappingEditing && onVariableCorrectionsChange && variableCandidates.length > 0 && (
                        <div className="pt-2 space-y-3 border-t border-gray-200">
                            <div className="text-xs text-muted-foreground">
                                仅用于修正变量名映射（例如系统识别的变量名与实际列名不一致）。若当前变量未确定，请在下方“待确认问题”中选择。
                            </div>

                            {draft.outcome_var && (
                                <div className="space-y-1">
                                    <div className="text-xs text-muted-foreground">因变量修正</div>
                                    <select
                                        className="w-full border border-gray-200 rounded-md px-3 py-2 text-sm bg-white font-mono"
                                        value={getCorrectedVar(draft.outcome_var) || ""}
                                        onChange={(e) => updateCorrection(draft.outcome_var as string, e.target.value)}
                                    >
                                        {getCorrectedVar(draft.outcome_var) &&
                                            !variableCandidates.includes(getCorrectedVar(draft.outcome_var) as string) && (
                                                <option value={getCorrectedVar(draft.outcome_var) as string}>
                                                    {getCorrectedVar(draft.outcome_var)}
                                                </option>
                                            )}
                                        {variableCandidates.map((name) => (
                                            <option key={`outcome-${name}`} value={name}>
                                                {name}
                                            </option>
                                        ))}
                                    </select>
                                </div>
                            )}

                            {draft.treatment_var && (
                                <div className="space-y-1">
                                    <div className="text-xs text-muted-foreground">自变量修正</div>
                                    <select
                                        className="w-full border border-gray-200 rounded-md px-3 py-2 text-sm bg-white font-mono"
                                        value={getCorrectedVar(draft.treatment_var) || ""}
                                        onChange={(e) => updateCorrection(draft.treatment_var as string, e.target.value)}
                                    >
                                        {getCorrectedVar(draft.treatment_var) &&
                                            !variableCandidates.includes(getCorrectedVar(draft.treatment_var) as string) && (
                                                <option value={getCorrectedVar(draft.treatment_var) as string}>
                                                    {getCorrectedVar(draft.treatment_var)}
                                                </option>
                                            )}
                                        {variableCandidates.map((name) => (
                                            <option key={`treatment-${name}`} value={name}>
                                                {name}
                                            </option>
                                        ))}
                                    </select>
                                </div>
                            )}

                            {draft.controls && draft.controls.length > 0 && (
                                <div className="space-y-2">
                                    <div className="text-xs text-muted-foreground">控制变量逐项修正</div>
                                    <div className="space-y-2">
                                        {draft.controls.map((orig) => (
                                            <div key={`ctrl-${orig}`} className="grid grid-cols-1 md:grid-cols-3 gap-2 items-center">
                                                <div className="text-xs text-muted-foreground md:col-span-1 break-all">
                                                    原：<span className="font-mono">{orig}</span>
                                                </div>
                                                <div className="md:col-span-2">
                                                    <select
                                                        className="w-full border border-gray-200 rounded-md px-3 py-2 text-sm bg-white font-mono"
                                                        value={getCorrectedVar(orig) || ""}
                                                        onChange={(e) => updateCorrection(orig, e.target.value)}
                                                    >
                                                        {getCorrectedVar(orig) && !variableCandidates.includes(getCorrectedVar(orig) as string) && (
                                                            <option value={getCorrectedVar(orig) as string}>
                                                                {getCorrectedVar(orig)}
                                                            </option>
                                                        )}
                                                        {variableCandidates.map((name) => (
                                                            <option key={`ctrl-${orig}-${name}`} value={name}>
                                                                {name}
                                                            </option>
                                                        ))}
                                                    </select>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>
                    )}
                </div>

                {/* 变量类型识别（T5.2） */}
                {variableTypes.length > 0 && (
                    <div className="bg-white/50 rounded-lg p-4 space-y-2">
                        <div className="flex items-center justify-between gap-3">
                            <h4 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                                <Database className="h-4 w-4" />
                                变量类型识别（所有文件）
                            </h4>
                            <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={() => setVarTypesExpanded((v) => !v)}
                            >
                                {varTypesExpanded ? "收起" : "展开"}
                            </Button>
                        </div>

                        {varTypesExpanded && (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                                {variableTypes.slice(0, 40).map((v) => (
                                    <div
                                        key={v.name}
                                        className="flex items-center justify-between gap-3 rounded-md border border-gray-200 bg-white px-3 py-2 text-xs"
                                    >
                                        <span className="font-mono break-all">{v.name}</span>
                                        <span className="text-muted-foreground">
                                            {varTypeLabel[v.type] || v.type}
                                            {typeof v.missing_rate === "number"
                                                ? ` · 缺失${Math.round(v.missing_rate * 100)}%`
                                                : ""}
                                            {getVarSourceLabel(v) ? ` · 来源：${getVarSourceLabel(v)}` : ""}
                                        </span>
                                    </div>
                                ))}
                                {variableTypes.length > 40 && (
                                    <div className="text-xs text-muted-foreground md:col-span-2">
                                        仅展示前 40 个变量；其余变量可在后续问题中继续确认。
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                )}

                {/* 统一的待确认事项区域：选择题 + 信息补充 */}
                {(() => {
                    // 过滤逻辑：只显示阻断性项，隐藏内部占位符
                    const visibleUnknowns = (draft.open_unknowns || []).filter((u) => {
                        // 只显示阻断性项（blocking=true 或 impact 为 high/critical）
                        const isBlocking = u.blocking === true || 
                            (u.blocking !== false && ["high", "critical"].includes(String(u.impact || "").toLowerCase()));
                        if (!isBlocking) return false;
                        // 隐藏内部占位符
                        const field = String(u.field || "");
                        if (field.startsWith("placeholders.")) return false;
                        if (field.includes("BASE_VARS") || field.includes("FULL_VARS")) return false;
                        if (field.includes("__") && field.includes("VARS")) return false; // 其他内部变量
                        return true;
                    });
                    const totalItems = stage1Questions.length + visibleUnknowns.length;
                    if (totalItems === 0) return null;
                    return (
                    <div className="space-y-3">
                        <h4 className="text-sm font-semibold text-yellow-800 flex items-center gap-2">
                            <AlertTriangle className="h-4 w-4" />
                            待确认事项（{totalItems}项）
                        </h4>
                        <div className="space-y-2">
                            {/* 阻断性选择题优先显示 */}
                            {stage1Questions.map((question, qIdx) => {
                                const isAnswered = (stage1Answers[question.question_id] || []).length > 0;
                                const selectedOption = question.options.find((opt) =>
                                    (stage1Answers[question.question_id] || []).includes(opt.option_id)
                                );
                                return (
                                    <div
                                        key={question.question_id}
                                        className="bg-white border border-yellow-200 rounded-lg p-4 shadow-sm"
                                    >
                                        <div className="flex items-start gap-3">
                                            <span
                                                className={`flex-shrink-0 w-6 h-6 rounded-full text-xs font-bold flex items-center justify-center ${isAnswered
                                                        ? "bg-green-100 text-green-700"
                                                        : "bg-yellow-100 text-yellow-700"
                                                    }`}
                                            >
                                                {isAnswered ? (
                                                    <CheckCircle2 className="h-4 w-4" />
                                                ) : (
                                                    qIdx + 1
                                                )}
                                            </span>
                                            <div className="flex-1 min-w-0">
                                                <div className="font-semibold text-gray-900 mb-1">
                                                    {question.question_text}
                                                    {question.question_type === "single_choice" && (
                                                        <span className="ml-2 text-xs font-normal text-muted-foreground">
                                                            （单选）
                                                        </span>
                                                    )}
                                                </div>
                                                {isAnswered && selectedOption && (
                                                    <div className="text-sm text-green-600 mb-2">
                                                        已选择：{selectedOption.label}
                                                    </div>
                                                )}
                                                {/* 选项按钮 */}
                                                {onStage1AnswerChange && (
                                                    <div className="mt-3 grid gap-2">
                                                        {question.options.map((option) => {
                                                            const isSelected = (stage1Answers[question.question_id] || []).includes(option.option_id);
                                                            return (
                                                                <Button
                                                                    key={option.option_id}
                                                                    type="button"
                                                                    variant={isSelected ? "default" : "outline"}
                                                                    className={`justify-start h-auto py-3 px-4 text-left whitespace-normal ${isSelected ? "" : "hover:bg-accent/50"
                                                                        }`}
                                                                    onClick={() => {
                                                                        if (question.question_type === "single_choice") {
                                                                            onStage1AnswerChange(question.question_id, [option.option_id]);
                                                                        } else {
                                                                            const current = stage1Answers[question.question_id] || [];
                                                                            if (current.includes(option.option_id)) {
                                                                                onStage1AnswerChange(
                                                                                    question.question_id,
                                                                                    current.filter((id) => id !== option.option_id)
                                                                                );
                                                                            } else {
                                                                                onStage1AnswerChange(question.question_id, [...current, option.option_id]);
                                                                            }
                                                                        }
                                                                    }}
                                                                >
                                                                    <span
                                                                        className={`w-4 h-4 rounded-full border-2 mr-3 flex-shrink-0 flex items-center justify-center ${isSelected
                                                                                ? "border-primary-foreground bg-primary-foreground"
                                                                                : "border-current"
                                                                            }`}
                                                                    >
                                                                        {isSelected && <span className="w-2 h-2 rounded-full bg-primary" />}
                                                                    </span>
                                                                    <span className="text-sm">{option.label}</span>
                                                                </Button>
                                                            );
                                                        })}
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}

                            {/* 信息补充类待确认项（仅显示阻断性项） */}
                            {visibleUnknowns.map((unknown, idx) => (
                                <div
                                    key={`unknown-${idx}`}
                                    className="bg-white border border-yellow-200 rounded-lg p-4 shadow-sm"
                                >
                                    <div className="flex items-start gap-3">
                                        <span className="flex-shrink-0 w-6 h-6 rounded-full bg-yellow-100 text-yellow-700 text-xs font-bold flex items-center justify-center">
                                            {stage1Questions.length + idx + 1}
                                        </span>
                                        <div className="flex-1 min-w-0">
                                            <div className="font-semibold text-gray-900 mb-1">
                                                {unknown.display_name || unknown.field}
                                            </div>
                                            <div className="text-sm text-gray-600 whitespace-pre-line">
                                                {unknown.description}
                                            </div>
                                            {debugEnabled && (
                                                <div className="text-xs text-muted-foreground mt-1">
                                                    字段：{unknown.field}
                                                </div>
                                            )}

                                            {/* 内联澄清输入框 */}
                                            {onClarificationChange && (
                                                <div className="mt-3">
                                                    <InlineClarificationInput
                                                        field={unknown.field}
                                                        candidates={unknown.candidates}
                                                        suggestedDefault={typeof unknown.suggested_default === 'string' ? unknown.suggested_default : undefined}
                                                        value={clarifications?.[unknown.field]}
                                                        onChange={(value) => onClarificationChange(unknown.field, value)}
                                                    />
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                    );
                })()}

                {/* 默认值透明展示 */}
                {defaults.length > 0 && (
                    <div className="bg-white/50 rounded-lg p-4 space-y-3">
                        <div className="flex items-center justify-between gap-3">
                            <h4 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                                <CheckCircle className="h-4 w-4" />
                                已使用默认值（{defaults.length}项）
                            </h4>
                            <div className="flex items-center gap-2">
                                {onEditDefaults && (
                                    <Button
                                        type="button"
                                        size="sm"
                                        onClick={onEditDefaults}
                                    >
                                        修改默认值
                                    </Button>
                                )}
                                <Button
                                    type="button"
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setDefaultsExpanded((v) => !v)}
                                >
                                    {defaultsExpanded ? "收起" : "展开"}
                                </Button>
                            </div>
                        </div>

                        {defaultsExpanded && (
                            <div className="space-y-2">
                                {defaults.map((d) => (
                                    <div
                                        key={d.field}
                                        className="rounded-md border border-gray-200 bg-white p-3"
                                    >
                                        <div className="text-sm font-medium">
                                            {d.display_name}：{d.reason}
                                        </div>
                                        <div className="text-xs text-muted-foreground mt-1">
                                            {d.default_label}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                )}
            </CardContent>

            <AlertDialog open={showMainDataHelp} onOpenChange={setShowMainDataHelp}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>什么是主数据文件？</AlertDialogTitle>
                        <AlertDialogDescription>
                            主数据文件是您分析的核心数据。系统会以这个文件为基础识别变量、生成分析计划。其他文件将作为辅助数据（如需要合并的表、查找表等）。
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <div className="mt-4 flex justify-end">
                        <AlertDialogAction>我知道了</AlertDialogAction>
                    </div>
                </AlertDialogContent>
            </AlertDialog>

            {/* 宽表确认弹窗 (P5) */}
            <WideTableConfirmDialog
                source={wideTableDialogSource}
                open={wideTableDialogSource !== null}
                onConfirm={confirmWideTableSource}
                onCancel={() => setWideTableDialogSource(null)}
            />
        </Card>
    );
}
