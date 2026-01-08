import { useEffect, useMemo, useState } from "react";
import { ArrowLeft, Loader2, AlertTriangle, CheckCircle } from "lucide-react";
import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";
import {
  getBundleSheets,
  patchBundleSheets,
  type BundleSheetFileInfo,
} from "@/api/stataService";

interface SheetSelectionStepProps {
  jobId: string;
  onDone: () => void;
  onBack: () => void;
}

function roleLabel(role: string): string {
  switch ((role || "").toLowerCase()) {
    case "main_dataset":
      return "主数据文件";
    case "merge_table":
      return "合并用辅表";
    case "lookup":
      return "查表/映射表";
    case "appendix":
      return "附录/说明";
    default:
      return role || "其他";
  }
}

export function SheetSelectionStep({ jobId, onDone, onBack }: SheetSelectionStepProps) {
  const [loading, setLoading] = useState(true);
  const [files, setFiles] = useState<BundleSheetFileInfo[]>([]);
  const [selections, setSelections] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      setError(null);
      try {
        const resp = await getBundleSheets(jobId);
        if (cancelled) return;

        const nextFiles = Array.isArray(resp.files) ? resp.files : [];
        setFiles(nextFiles);

        const init: Record<string, string> = {};
        for (const f of nextFiles) {
          const sheetOptions = Array.isArray(f.sheets) ? f.sheets : [];
          const hasMultiple = sheetOptions.filter((s) => !!s.sheet_name).length > 1;
          if (!hasMultiple) continue;
          const recommended =
            f.selected_sheet_name ||
            f.recommended_sheet_name ||
            sheetOptions.find((s) => !!s.sheet_name)?.sheet_name ||
            "";
          if (recommended && f.file_id) {
            init[f.file_id] = recommended;
          }
        }
        setSelections(init);
      } catch (err) {
        if (cancelled) return;
        setError(err instanceof Error ? err.message : "加载失败");
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void load();
    return () => {
      cancelled = true;
    };
  }, [jobId]);

  const requiredFiles = useMemo(() => {
    const out: BundleSheetFileInfo[] = [];
    for (const f of files) {
      const sheetOptions = Array.isArray(f.sheets) ? f.sheets : [];
      const valid = sheetOptions.filter((s) => typeof s.sheet_name === "string" && s.sheet_name);
      if (valid.length > 1) out.push(f);
    }
    return out;
  }, [files]);

  useEffect(() => {
    if (!loading && !error && requiredFiles.length === 0) {
      onDone();
    }
  }, [loading, error, requiredFiles.length, onDone]);

  const handleSubmit = async () => {
    setError(null);
    if (requiredFiles.length === 0) {
      onDone();
      return;
    }

    const missing = requiredFiles.filter((f) => !(selections[f.file_id] || "").trim());
    if (missing.length > 0) {
      setError("请先为每个多工作表 Excel 选择一个 sheet 后继续。");
      return;
    }

    try {
      setSubmitting(true);
      await patchBundleSheets(jobId, selections);
      onDone();
    } catch (err) {
      setError(err instanceof Error ? err.message : "提交失败");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <Card className="border border-slate-200 shadow-sm">
        <CardContent className="p-6">
          <div className="flex items-center gap-3 text-slate-700">
            <Loader2 className="h-5 w-5 animate-spin" />
            <span>正在解析 Excel 工作表…</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (requiredFiles.length === 0) {
    return (
      <Card className="border border-slate-200 shadow-sm">
        <CardContent className="p-6">
          <div className="flex items-center gap-3 text-emerald-700">
            <CheckCircle className="h-5 w-5" />
            <span>未检测到需要选择的多工作表 Excel，正在进入系统确认…</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-3">
        <Button variant="outline" onClick={onBack} className="gap-2">
          <ArrowLeft className="h-4 w-4" />
          返回修改
        </Button>
      </div>

      {error && (
        <div className="flex items-center gap-3 p-4 bg-amber-50 border border-amber-200 rounded-xl text-amber-800 text-sm">
          <AlertTriangle className="h-4 w-4" />
          <span>{error}</span>
        </div>
      )}

      <Card className="border border-slate-200 shadow-sm">
        <CardContent className="p-6 space-y-4">
          <div className="space-y-1">
            <h2 className="text-lg font-semibold text-slate-900">请选择 Excel 工作表</h2>
            <p className="text-sm text-slate-500">
              检测到上传文件包含多个 sheet。请选择每个文件后续要使用的 sheet（影响变量识别、合并与执行）。
            </p>
          </div>

          <div className="space-y-4">
            {requiredFiles.map((f) => {
              const sheetOptions = (Array.isArray(f.sheets) ? f.sheets : []).filter(
                (s) => typeof s.sheet_name === "string" && s.sheet_name
              );
              const current = selections[f.file_id] || "";
              return (
                <div
                  key={f.file_id}
                  className="rounded-xl border border-slate-200 bg-white p-4 space-y-3"
                >
                  <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-2">
                    <div className="space-y-0.5">
                      <div className="text-sm font-semibold text-slate-900 break-all">{f.filename}</div>
                      <div className="text-xs text-slate-500">
                        角色：{roleLabel(f.role)}{" "}
                        {f.recommended_sheet_name ? `· 推荐：${f.recommended_sheet_name}` : ""}
                      </div>
                    </div>
                    <div className="md:w-80">
                      <select
                        className="w-full border border-slate-200 rounded-md px-3 py-2 text-sm bg-white"
                        value={current}
                        onChange={(e) =>
                          setSelections((prev) => ({ ...prev, [f.file_id]: e.target.value }))
                        }
                      >
                        {sheetOptions.map((s) => (
                          <option key={`${f.file_id}:${s.sheet_name}`} value={s.sheet_name || ""}>
                            {s.sheet_name}
                            {typeof s.score === "number" ? `（score ${s.score.toFixed(1)}）` : ""}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  {current && (
                    <div className="text-xs text-slate-500">
                      已选择：<span className="font-mono">{current}</span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          <div className="flex justify-end">
            <Button onClick={handleSubmit} disabled={submitting} className="gap-2">
              {submitting ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              继续进入系统确认
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export default SheetSelectionStep;

