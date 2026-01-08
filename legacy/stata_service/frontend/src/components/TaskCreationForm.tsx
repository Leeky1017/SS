import { useState, useEffect, useCallback } from "react";
import { Upload, FileText, X, Loader2, CheckCircle } from "lucide-react";
import { useFormPersistence, type FileMeta } from "@/hooks/useFormPersistence";
import { submitTask, type UploadProgress } from "@/api/stataService";

interface TaskCreationFormProps {
  onSubmit: (data: TaskSubmitResult) => void;
}

export interface TaskSubmitResult {
  taskCode: string;
  jobId: string;
  status: string;
  estimatedTime: number;
  submittedAt: string;
}

export function TaskCreationForm({ onSubmit }: TaskCreationFormProps) {
  const [taskCode, setTaskCode] = useState("");
  const [description, setDescription] = useState("");
  const [files, setFiles] = useState<File[]>([]);
  const [mainDataFileIndex, setMainDataFileIndex] = useState<number | null>(null);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<UploadProgress[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [rateLimitCountdown, setRateLimitCountdown] = useState<number | null>(null);

  const dataExtensions = ['.dta', '.xlsx', '.xls', '.csv'];
  const isDataFile = (filename: string) => {
    const ext = filename.toLowerCase().slice(filename.lastIndexOf('.'));
    return dataExtensions.includes(ext);
  };
  const hasDataFiles = files.some((f) => isDataFile(f.name));
  const needsMainDataSelection = hasDataFiles && mainDataFileIndex === null;

  const [previousFiles, setPreviousFiles] = useState<FileMeta[]>([]);
  const [showFileRecoveryHint, setShowFileRecoveryHint] = useState(false);
  const [lastSaveTime, setLastSaveTime] = useState<number | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const { loadDraft, saveDraft, clearDraft } = useFormPersistence();

  // 需求模板
  const requirementTemplates: { label: string; text: string }[] = [
    {
      label: "回归：验证 X 对 Y 的影响，控制 Z",
      text:
        "研究问题：验证 X 对 Y 的影响，并控制 Z。\n" +
        "模型设定：请进行多元回归（必要时加入固定效应），并报告系数、标准误、p 值与样本量。\n" +
        "稳健性：如可行，请补充至少 1-2 项稳健性检验（如替换变量测度/子样本/安慰剂等）。",
    },
    {
      label: "组间差异：比较 A 组与 B 组",
      text:
        "研究问题：比较 A 组和 B 组在指标 C 上的差异。\n" +
        "方法：请输出描述统计，并进行差异检验（t 检验或非参数检验，视分布与样本量而定）。\n" +
        "补充：如可行，请控制关键协变量并报告回归结果。",
    },
    {
      label: "描述统计：变量分布与缺失情况",
      text:
        "研究问题：描述 D 变量的分布特征与缺失情况。\n" +
        "输出：请给出样本量、均值/标准差、分位数、缺失值比例，以及必要的图表或分组汇总。",
    },
  ];

  const applyTemplate = (text: string) => {
    setDescription((prev) => {
      const p = (prev || "").trim();
      if (!p) return text;
      return `${p}\n\n${text}`;
    });
  };

  useEffect(() => {
    if (rateLimitCountdown === null) return;
    if (rateLimitCountdown <= 0) {
      setRateLimitCountdown(null);
      return;
    }
    const timer = setTimeout(() => {
      setRateLimitCountdown(rateLimitCountdown - 1);
    }, 1000);
    return () => clearTimeout(timer);
  }, [rateLimitCountdown]);

  useEffect(() => {
    const draft = loadDraft();
    if (draft) {
      setTaskCode(draft.taskCode);
      setDescription(draft.description);
      if (draft.filesMeta.length > 0) {
        setPreviousFiles(draft.filesMeta);
        setShowFileRecoveryHint(true);
      }
      setLastSaveTime(draft.savedAt);
    }
  }, [loadDraft]);

  const debouncedSave = useCallback(() => {
    setIsSaving(true);
    const timer = setTimeout(() => {
      saveDraft({
        taskCode,
        description,
        filesMeta: files.map((f) => ({ name: f.name, size: f.size, type: f.type })),
        pendingJobId: null,
        currentStep: 'form',
      });
      setLastSaveTime(Date.now());
      setIsSaving(false);
    }, 500);
    return () => clearTimeout(timer);
  }, [taskCode, description, files, saveDraft]);

  useEffect(() => {
    if (taskCode || description || files.length > 0) {
      return debouncedSave();
    }
  }, [taskCode, description, files, debouncedSave]);

  // 用户必须手动选择主数据文件（不自动选择）

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(e.target.files || []);
    setFiles((prev) => [...prev, ...selectedFiles]);
  };

  const removeFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index));
    if (mainDataFileIndex === index) {
      setMainDataFileIndex(null);
    } else if (mainDataFileIndex !== null && mainDataFileIndex > index) {
      setMainDataFileIndex(mainDataFileIndex - 1);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!taskCode.trim()) {
      setError("请填写任务验证码");
      return;
    }
    if (!description.trim()) {
      setError("请填写研究设计描述");
      return;
    }
    if (files.length === 0) {
      setError("请至少上传一个数据文件");
      return;
    }
    if (needsMainDataSelection) {
      setError("请选择主数据文件后再提交");
      return;
    }

    setShowConfirmDialog(true);
  };

  const handleConfirm = async () => {
    setShowConfirmDialog(false);
    setIsSubmitting(true);
    setError(null);
    setUploadProgress([]);
    setRateLimitCountdown(null);

    try {
      const result = await submitTask(
        taskCode.trim(),
        files,
        mainDataFileIndex ?? 0,
        description.trim(),
        (progress) => {
          setUploadProgress([...progress]);
        }
      );

      const now = new Date();
      const estimatedCompletion = new Date(now.getTime() + 80 * 60000);

      onSubmit({
        taskCode: taskCode.trim(),
        jobId: result.jobId,
        status: "queued",
        estimatedTime: 80,
        submittedAt: estimatedCompletion.toLocaleString("zh-CN", {
          year: "numeric",
          month: "2-digit",
          day: "2-digit",
          hour: "2-digit",
          minute: "2-digit",
          hour12: false,
        }).replace(/\//g, "-"),
      });

      clearDraft();
    } catch (err) {
      const rateLimitError = err as { type?: string; retryAfter?: number; message?: string };
      if (rateLimitError && rateLimitError.type === "RATE_LIMITED") {
        const retryAfter = Math.max(1, Number(rateLimitError.retryAfter || 60));
        setRateLimitCountdown(retryAfter);
        setError(rateLimitError.message || `请求过于频繁，请在 ${retryAfter} 秒后重试`);
      } else if (err instanceof Error && err.message.includes("文件校验失败")) {
        setError("文件校验失败，系统已自动重试仍失败，请重新选择文件后再提交");
      } else {
        setError(err instanceof Error ? err.message : "提交失败，请重试");
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const totalProgress = uploadProgress.length > 0
    ? uploadProgress.reduce((sum, p) => sum + p.progress, 0) / uploadProgress.length
    : 0;

  return (
    <>
      <form onSubmit={handleSubmit} className="space-y-8">
        {/* Error Display */}
        {error && (
          <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
            <span>{error}</span>
            {rateLimitCountdown !== null && rateLimitCountdown > 0 && (
              <span className="text-red-500 font-medium">({rateLimitCountdown}s)</span>
            )}
          </div>
        )}

        {/* File Recovery Hint */}
        {showFileRecoveryHint && previousFiles.length > 0 && (
          <div className="flex items-start gap-3 p-4 bg-amber-50 border border-amber-200 rounded-xl">
            <div className="flex-1">
              <p className="text-sm text-amber-800 font-medium">检测到上次未完成的任务</p>
              <p className="text-xs text-amber-700 mt-1">
                请重新选择以下文件：{previousFiles.map(f => f.name).join(", ")}
              </p>
            </div>
            <button
              type="button"
              onClick={() => setShowFileRecoveryHint(false)}
              className="text-amber-600 hover:text-amber-800"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        )}

        {/* G3: 任务验证码 - 简洁设计 */}
        <div className="space-y-2">
          <div className="flex items-baseline justify-between">
            <label htmlFor="taskCode" className="text-sm font-semibold text-slate-900">
              任务验证码 <span className="text-red-500">*</span>
            </label>
          </div>
          <input
            id="taskCode"
            type="text"
            value={taskCode}
            onChange={(e) => setTaskCode(e.target.value)}
            placeholder="2025-TASK-XXXX"
            required
            disabled={isSubmitting}
            className="w-full h-12 px-4 text-base font-mono bg-white border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all disabled:opacity-50"
          />
        </div>

        {/* G3: 研究设计描述 */}
        <div className="space-y-2">
          <div className="flex items-baseline justify-between">
            <label htmlFor="description" className="text-sm font-semibold text-slate-900">
              研究设计描述 <span className="text-red-500">*</span>
            </label>
            <button
              type="button"
              className="text-xs text-blue-600 hover:text-blue-700 flex items-center gap-1"
              onClick={() => {
                const template = requirementTemplates[0];
                applyTemplate(template.text);
              }}
	            >
	              <FileText className="h-3 w-3" />
	              插入标准示例
	            </button>
          </div>
          <textarea
            id="description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="请描述您的回归模型（如 OLS, Fixed Effects）以及相关变量 ..."
            required
            disabled={isSubmitting}
            rows={6}
            className="w-full px-4 py-3 text-sm bg-white border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all resize-none disabled:opacity-50"
          />

          {/* 快速模板按钮 */}
          <div className="flex flex-wrap gap-2">
            {requirementTemplates.map((tpl) => (
              <button
                key={tpl.label}
                type="button"
                disabled={isSubmitting}
                onClick={() => applyTemplate(tpl.text)}
                className="px-3 py-1.5 text-xs bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors border border-slate-200 disabled:opacity-50"
              >
                {tpl.label}
              </button>
            ))}
          </div>
        </div>

        {/* G3: 上传数据文件 - 简洁卡片 */}
        <div className="bg-slate-50/50 rounded-2xl p-6 border border-slate-200/50">
          <div className="text-center mb-4">
            <Upload className="h-8 w-8 text-slate-400 mx-auto mb-3" />
            <h3 className="text-base font-semibold text-slate-900 mb-1">
              上传数据文件 <span className="text-red-500">*</span>
            </h3>
            <p className="text-sm text-slate-500">
              支持 .dta, .xlsx, .csv 格式 (必须上传)
            </p>
            <p className="mt-2 text-xs text-slate-500">
              选择您分析的核心数据文件
              <span
                className="ml-2 inline-block cursor-help text-slate-400"
                title="主数据文件是您分析的核心数据。系统会以这个文件为基础识别变量、生成分析计划。其他文件将作为辅助数据（如需要合并的表、查找表等）。"
              >
                （什么是主数据？）
              </span>
            </p>
          </div>

          {/* Upload Area */}
          <div className="relative">
            <input
              type="file"
              id="dataFile"
              onChange={handleFileChange}
              className="hidden"
              multiple
              disabled={isSubmitting}
              accept=".dta,.xlsx,.xls,.csv,.docx,.doc,.txt"
            />
            <label
              htmlFor="dataFile"
              className={`
                flex items-center justify-center gap-2 p-8 border-2 border-dashed rounded-xl transition-all cursor-pointer
                ${isSubmitting
                  ? "border-slate-200 bg-slate-100 cursor-not-allowed"
                  : "border-slate-300 hover:border-blue-400 hover:bg-blue-50/50"
                }
              `}
            >
              <Upload className="h-5 w-5 text-slate-400" />
              <span className="text-slate-600">点击或拖拽文件至此处</span>
            </label>
          </div>

          {/* File List */}
          {files.length > 0 && (
            <div className="mt-4 space-y-2">
              {files.map((file, index) => {
                const isData = isDataFile(file.name);
                const isMain = mainDataFileIndex === index;

                return (
                  <div
                    key={`${file.name}-${index}`}
                    className={`flex items-center gap-3 p-3 rounded-xl transition-all ${isMain
                      ? 'bg-blue-100 border border-blue-300'
                      : 'bg-white border border-slate-200'
                      }`}
                  >
                    <FileText className={`h-5 w-5 flex-shrink-0 ${isMain ? 'text-blue-600' : 'text-slate-400'}`} />
                    <div className="flex-1 min-w-0">
                      <span className={`block truncate text-sm ${isMain ? 'text-blue-700 font-medium' : 'text-slate-700'}`}>
                        {file.name}
                      </span>
                      {isMain && (
                        <span className="text-xs text-blue-600">✓ 主数据文件</span>
                      )}
                    </div>
                    <span className="text-xs text-slate-400 whitespace-nowrap">
                      {(file.size / 1024).toFixed(1)} KB
                    </span>
                    {!isSubmitting && isData && !isMain && (
                      <button
                        type="button"
                        onClick={() => setMainDataFileIndex(index)}
                        className="px-2 py-1 text-xs text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded"
                      >
                        设为主数据
                      </button>
                    )}
                    {!isSubmitting && (
                      <button
                        type="button"
                        onClick={() => removeFile(index)}
                        className="p-1 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          )}

          {/* Upload Progress */}
          {isSubmitting && uploadProgress.length > 0 && (
            <div className="mt-4 p-4 bg-blue-50 rounded-xl">
              <div className="flex items-center justify-between text-sm mb-2">
                <span className="text-blue-700">上传进度</span>
                <span className="text-blue-700 font-medium">{Math.round(totalProgress)}%</span>
              </div>
              <div className="h-2 bg-blue-200 rounded-full overflow-hidden">
                <div
                  className="h-full bg-blue-600 transition-all duration-300"
                  style={{ width: `${totalProgress}%` }}
                />
              </div>
            </div>
          )}

          {/* Main Data Selection Hint */}
          {needsMainDataSelection && files.length > 0 && (
            <div className="mt-4 p-3 bg-amber-50 border border-amber-200 rounded-xl text-sm text-amber-700">
              请选择主数据文件后再提交
            </div>
          )}
        </div>

        {/* Auto-save Status */}
        <div className="flex items-center justify-center gap-2 text-xs text-slate-400">
          {isSaving ? (
            <>
              <Loader2 className="h-3 w-3 animate-spin" />
              正在保存...
            </>
          ) : lastSaveTime ? (
            <>
              <CheckCircle className="h-3 w-3 text-green-500" />
              已自动保存
            </>
          ) : null}
        </div>

        {/* Submit Button */}
        <div className="flex justify-center pt-2">
          <button
            type="submit"
            disabled={isSubmitting || needsMainDataSelection || (rateLimitCountdown ?? 0) > 0}
            className={`
              px-10 py-3.5 text-base font-medium text-white rounded-xl transition-all
              ${isSubmitting || needsMainDataSelection || (rateLimitCountdown ?? 0) > 0
                ? 'bg-slate-300 cursor-not-allowed'
                : 'bg-blue-600 hover:bg-blue-700 shadow-lg shadow-blue-600/25 hover:shadow-xl hover:shadow-blue-600/30'
              }
            `}
          >
            {isSubmitting ? (
              <span className="flex items-center gap-2">
                <Loader2 className="h-4 w-4 animate-spin" />
                正在提交...
              </span>
            ) : files.length === 0 ? (
              "请先上传数据文件"
            ) : (
              "下一步：确认需求"
            )}
          </button>
        </div>
      </form>

      {/* Confirmation Dialog */}
      {showConfirmDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full mx-4 shadow-2xl">
            <h3 className="text-lg font-semibold text-slate-900 mb-4">确认提交任务</h3>
            <div className="space-y-3 mb-6">
              <div className="p-4 bg-slate-50 rounded-xl">
                <div className="space-y-2 text-sm">
                  <div className="flex gap-2">
                    <span className="text-slate-500">任务验证码：</span>
                    <span className="font-mono text-slate-900">{taskCode}</span>
                  </div>
                  <div className="flex gap-2">
                    <span className="text-slate-500">上传文件：</span>
                    <span className="text-slate-900">{files.length} 个文件</span>
                  </div>
                </div>
              </div>
              <p className="text-sm text-slate-500">
                提交后，系统将开始处理您的分析任务。
              </p>
            </div>
            <div className="flex gap-3 justify-end">
              <button
                type="button"
                onClick={() => setShowConfirmDialog(false)}
                className="px-4 py-2 text-sm text-slate-600 hover:text-slate-800 hover:bg-slate-100 rounded-lg transition-colors"
              >
                取消
              </button>
              <button
                type="button"
                onClick={handleConfirm}
                disabled={isSubmitting}
                className="px-4 py-2 text-sm text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors"
              >
                确认提交
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
