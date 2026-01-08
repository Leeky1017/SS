import { useState } from "react";
import { FileText, Loader2 } from "lucide-react";
import { Button } from "./ui/button";
import { downloadReport, type DocumentReport } from "@/api/stataService";

interface ReportDownloadProps {
  jobId: string;
  documentReport?: DocumentReport;
}

const FORMAT_CONFIG: Record<string, { icon: string; label: string; extension: string }> = {
  html: { icon: "HTML", label: "HTML 报告", extension: "html" },
  word: { icon: "Word", label: "Word 文档", extension: "docx" },
  pdf: { icon: "PDF", label: "PDF 报告", extension: "pdf" },
};

export function ReportDownload({ jobId, documentReport }: ReportDownloadProps) {
  const [downloading, setDownloading] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  if (!documentReport?.success) {
    return null;
  }

  const availableFormats = Object.entries(documentReport.files || {})
    .filter(([_, path]) => path)
    .map(([format]) => format);

  if (availableFormats.length === 0) {
    return null;
  }

  const handleDownload = async (format: "html" | "word" | "pdf") => {
    setDownloading(format);
    setError(null);
    try {
      await downloadReport(jobId, format);
    } catch (err) {
      console.error("Download failed:", err);
      setError(err instanceof Error ? err.message : "下载失败，请稍后重试");
    } finally {
      setDownloading(null);
    }
  };

  return (
    <div className="mt-4 p-4 bg-muted/30 rounded-lg border">
      <div className="flex items-center gap-2 mb-3">
        <FileText className="h-5 w-5 text-primary" />
        <h4 className="font-medium">分析报告下载</h4>
      </div>

      {error && (
        <div className="mb-3 p-2 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
          {error}
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        {availableFormats.map((format) => {
          const config = FORMAT_CONFIG[format] || { icon: format.toUpperCase(), label: format, extension: format };
          const isDownloading = downloading === format;

          return (
            <Button
              key={format}
              variant="outline"
              size="sm"
              onClick={() => handleDownload(format as "html" | "word" | "pdf")}
              disabled={isDownloading}
              className="gap-2"
            >
              {isDownloading ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <span className="text-xs font-mono bg-primary/10 px-1.5 py-0.5 rounded">
                  {config.icon}
                </span>
              )}
              {config.label}
            </Button>
          );
        })}
      </div>

      {documentReport.errors && documentReport.errors.length > 0 && (
        <div className="mt-3 text-xs text-muted-foreground">
          <span className="text-amber-600">部分格式生成失败：</span>
          {documentReport.errors.join(", ")}
        </div>
      )}
    </div>
  );
}
