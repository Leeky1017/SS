import { useEffect, useRef, useState } from "react";
import { Search, Download, FileText, Loader2, AlertCircle } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Input } from "./ui/input";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import {
  redeemTaskCode,
  getTaskCodeStatus,
  listArtifacts,
  getJobStatus,
  getArtifactDownloadUrl,
  requestArtifactsZip,
  saveAuth,
  type ArtifactListResponse,
  type Artifact,
  type TaskStatusResponse,
  type JobStatusResponse,
} from "@/api/stataService";

interface TaskQueryProps {
  initialTaskCode?: string;
  onResumeTask?: (jobId: string, phase: string, taskCode: string) => void;
}

export function TaskQuery({ initialTaskCode = "", onResumeTask }: TaskQueryProps) {
  const [queryCode, setQueryCode] = useState(initialTaskCode);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [jobId, setJobId] = useState<string | null>(null);
  const [artifacts, setArtifacts] = useState<ArtifactListResponse | null>(null);
  const [downloadingId, setDownloadingId] = useState<string | null>(null);
  const [jobStatus, setJobStatus] = useState<JobStatusResponse | null>(null);
  const [taskCodeStatus, setTaskCodeStatus] = useState<TaskStatusResponse | null>(null);
  const [queriedTaskCode, setQueriedTaskCode] = useState<string | null>(null);
  const statusTimerRef = useRef<number | null>(null);

  const handleQuery = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!queryCode.trim()) {
      setError("请输入任务验证码");
      return;
    }

    setIsLoading(true);
    setError(null);
    setNotice(null);
    setArtifacts(null);
    setJobStatus(null);
    setTaskCodeStatus(null);
    setQueriedTaskCode(null);

    try {
      // Step 1: Redeem (idempotent) to get job_id and token
      const inputCode = queryCode.trim();
      const redeemResult = await redeemTaskCode(inputCode);
      setJobId(redeemResult.job_id);
      saveAuth(redeemResult.token, redeemResult.job_id);
      setQueriedTaskCode(inputCode);

      // Step 1.2: Read task-code status (resume phase)
      try {
        const tcStatus = await getTaskCodeStatus();
        setTaskCodeStatus(tcStatus);
      } catch {
        // Non-blocking: still allow status/artifact query
      }

      // Step 1.5: Read job status (R7 blackbox)
      try {
        const statusResp = await getJobStatus(redeemResult.job_id);
        setJobStatus(statusResp);
      } catch {
        // Non-blocking: still allow artifact query
      }

      // Step 2: List artifacts
      const artifactList = await listArtifacts(redeemResult.job_id);
      setArtifacts(artifactList);
    } catch (err) {
      setError(err instanceof Error ? err.message : "查询失败，请重试");
    } finally {
      setIsLoading(false);
    }
  };

  // Auto-poll job status while it's not terminal, so users can "see it's working"
  useEffect(() => {
    if (!jobId) return;

    let cancelled = false;

    const poll = async () => {
      if (cancelled) return;
      try {
        const statusResp = await getJobStatus(jobId);
        if (cancelled) return;
        setJobStatus(statusResp);

        const s = String(statusResp.status || "").toLowerCase();
        const terminal = ["done", "failed"].includes(s);
        if (terminal) {
          // Refresh artifacts once when job becomes terminal
          try {
            const artifactList = await listArtifacts(jobId);
            if (!cancelled) setArtifacts(artifactList);
          } catch {
            // ignore
          }
          return;
        }
      } catch {
        // ignore transient polling errors
      }

      if (statusTimerRef.current) {
        window.clearTimeout(statusTimerRef.current);
      }
      statusTimerRef.current = window.setTimeout(() => {
        void poll();
      }, 5000);
    };

    void poll();

    return () => {
      cancelled = true;
      if (statusTimerRef.current) {
        window.clearTimeout(statusTimerRef.current);
      }
    };
  }, [jobId]);

  const handleDownloadArtifact = async (artifact: Artifact) => {
    if (!jobId) return;
    
    setDownloadingId(artifact.artifact_id);
    try {
      const downloadInfo = await getArtifactDownloadUrl(jobId, artifact.artifact_id);
      // Open download URL in new tab
      window.open(downloadInfo.presigned_url, "_blank");
    } catch (err) {
      setError(err instanceof Error ? err.message : "获取下载链接失败");
    } finally {
      setDownloadingId(null);
    }
  };

  const handleDownloadAll = async () => {
    if (!jobId) return;
    
    setDownloadingId("zip");
    try {
      setError(null);
      setNotice(null);
      const zipResult = await requestArtifactsZip(jobId);
      if (zipResult.presigned_url) {
        window.open(zipResult.presigned_url, "_blank");
      } else {
        setNotice(zipResult.message || "打包处理中，请稍后重试");
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "请求 ZIP 失败");
    } finally {
      setDownloadingId(null);
    }
  };

  const deriveBlackboxStatus = (): string => {
    const s = String(jobStatus?.status || "").toLowerCase();
    if (s === "processing" || s === "done" || s === "failed") return s;

    const as = String(artifacts?.status || "").toLowerCase();
    if (as === "processing" || as === "done" || as === "failed") return as;
    return "unknown";
  };

  const formatRetryUntil = (iso: string): string | null => {
    try {
      const d = new Date(iso);
      if (Number.isNaN(d.getTime())) return null;
      return d.toLocaleString("zh-CN", { hour12: false });
    } catch {
      return null;
    }
  };

  const retryUntilText = jobStatus?.retry_until ? formatRetryUntil(jobStatus.retry_until) : null;

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "done":
        return <Badge variant="success">已完成</Badge>;
      case "processing":
        return <Badge variant="warning">处理中</Badge>;
      case "failed":
        return <Badge variant="destructive">失败</Badge>;
      default:
        return <Badge variant="secondary">{status}</Badge>;
    }
  };

  const getArtifactStatusBadge = (status: string) => {
    switch (status) {
      case "READY":
        return <Badge variant="success" className="text-xs">可下载</Badge>;
      case "PENDING":
        return <Badge variant="warning" className="text-xs">生成中</Badge>;
      case "FAILED":
        return <Badge variant="destructive" className="text-xs">失败</Badge>;
      default:
        return <Badge variant="secondary" className="text-xs">{status}</Badge>;
    }
  };

  const resumablePhase = taskCodeStatus?.resumable_phase || null;
  const canResume =
    Boolean(onResumeTask) && Boolean(jobId) && Boolean(resumablePhase) && resumablePhase !== "failed";
  const resumeLabel = resumablePhase === "completed" ? "查看结果" : "返回任务";

  const handleResume = () => {
    if (!onResumeTask || !jobId || !resumablePhase) return;
    onResumeTask(jobId, resumablePhase, queriedTaskCode || queryCode.trim());
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>任务状态与结果查询</CardTitle>
        <CardDescription>
          使用任务验证码查询任务状态并下载结果文件
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <form onSubmit={handleQuery} className="flex gap-3">
          <div className="flex-1">
            <Input
              value={queryCode}
              onChange={(e) => setQueryCode(e.target.value)}
              placeholder="请输入任务验证码，例如：2025-TASK-ABC012"
              className="font-mono"
              disabled={isLoading}
            />
          </div>
          <Button type="submit" className="px-8" disabled={isLoading}>
            {isLoading ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <>
                <Search className="h-4 w-4 mr-2" />
                查询状态
              </>
            )}
          </Button>
        </form>

        {/* Error Display */}
        {error && (
          <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700">
            <AlertCircle className="h-4 w-4 flex-shrink-0" />
            <span className="text-sm">{error}</span>
          </div>
        )}

        {notice && (
          <div className="flex items-center gap-2 p-3 bg-blue-50 border border-blue-200 rounded-lg text-blue-700">
            <AlertCircle className="h-4 w-4 flex-shrink-0" />
            <span className="text-sm">{notice}</span>
          </div>
        )}

        {/* Results */}
        {artifacts ? (
          <div className="space-y-4">
            {/* Status Header */}
            <div className="flex items-center justify-between p-4 bg-muted/50 rounded-lg">
              <div className="space-y-1">
                <div className="text-sm text-muted-foreground">任务状态</div>
                <div className="flex items-center gap-2">
                  {getStatusBadge(deriveBlackboxStatus())}
                </div>
                {deriveBlackboxStatus() === "processing" && (
                  <div className="text-sm text-muted-foreground">
                    系统处理中，请耐心等待（页面会自动刷新）
                  </div>
                )}
                {deriveBlackboxStatus() === "processing" && retryUntilText ? (
                  <div className="text-sm text-muted-foreground">预计完成时间：{retryUntilText}</div>
                ) : null}
	                {jobStatus?.message && (
	                  <div className="text-sm text-muted-foreground">{jobStatus.message}</div>
	                )}
	              </div>
	              <div className="flex items-center gap-2">
	                {canResume && (
	                  <Button variant="default" onClick={handleResume}>
	                    {resumeLabel}
	                  </Button>
	                )}
	                {(deriveBlackboxStatus() === "done") && (artifacts.artifacts || []).length > 0 && (
	                  <Button
	                    variant="outline"
	                    onClick={handleDownloadAll}
	                    disabled={downloadingId === "zip"}
	                  >
	                    {downloadingId === "zip" ? (
	                      <Loader2 className="h-4 w-4 animate-spin mr-2" />
	                    ) : (
	                      <Download className="h-4 w-4 mr-2" />
	                    )}
	                    下载全部 (ZIP)
	                  </Button>
	                )}
	              </div>
	            </div>

            {/* Artifacts List */}
            {(artifacts.artifacts || []).length > 0 ? (
              <div className="space-y-2">
                <div className="text-sm font-medium">可下载文件 ({(artifacts.artifacts || []).length})</div>
                <div className="divide-y divide-border rounded-lg border">
                  {(artifacts.artifacts || []).map((artifact) => (
                    <div
                      key={artifact.artifact_id}
                      className="flex items-center justify-between p-3 hover:bg-muted/30"
                    >
                      <div className="flex items-center gap-3">
                        <FileText className="h-5 w-5 text-muted-foreground" />
                        <div>
                          <div className="text-sm font-medium">{artifact.filename}</div>
                          <div className="text-xs text-muted-foreground">
                            {(artifact.size_bytes / 1024).toFixed(1)} KB
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        {getArtifactStatusBadge(artifact.status)}
                        {artifact.status === "READY" && (
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleDownloadArtifact(artifact)}
                            disabled={downloadingId === artifact.artifact_id}
                          >
                            {downloadingId === artifact.artifact_id ? (
                              <Loader2 className="h-4 w-4 animate-spin" />
                            ) : (
                              <Download className="h-4 w-4" />
                            )}
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                <FileText className="h-12 w-12 mx-auto mb-3 opacity-50" />
                <p>暂无可下载的文件</p>
                <p className="text-sm mt-1">任务仍在处理中，请稍后刷新查询</p>
              </div>
            )}
          </div>
        ) : !isLoading && (
          <div className="p-8 bg-muted/30 rounded-lg border-2 border-dashed border-border text-center">
            <Search className="h-12 w-12 mx-auto mb-3 text-muted-foreground opacity-50" />
            <div className="text-muted-foreground">
              输入任务验证码后，查询结果将在此处显示
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
