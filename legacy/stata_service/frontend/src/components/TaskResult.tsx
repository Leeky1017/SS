import { useEffect, useRef, useState } from "react";
import { CheckCircle2, Clock, Loader2, RefreshCw } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { getJobStatus, type JobStatusResponse } from "@/api/stataService";

interface TaskResultProps {
  taskCode: string;
  jobId: string;
  status: string;
  estimatedTime: number;
  submittedAt: string;
}

export function TaskResult({ taskCode, jobId, status, estimatedTime, submittedAt }: TaskResultProps) {
  const [liveStatus, setLiveStatus] = useState<JobStatusResponse | null>(null);
  const [liveError, setLiveError] = useState<string | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const pollTimerRef = useRef<number | null>(null);

  const formatRetryUntil = (iso: string): string | null => {
    try {
      const d = new Date(iso);
      if (Number.isNaN(d.getTime())) return null;
      return d.toLocaleString("zh-CN", { hour12: false });
    } catch {
      return null;
    }
  };

  const storedRetryUntil = (() => {
    try {
      return localStorage.getItem(`stata_service_retry_until:${jobId}`);
    } catch {
      return null;
    }
  })();

  const retryUntilIso = liveStatus?.retry_until || storedRetryUntil || null;
  const retryUntilText = retryUntilIso ? formatRetryUntil(retryUntilIso) : null;

  const refresh = async (): Promise<JobStatusResponse | null> => {
    setIsRefreshing(true);
    try {
      const data = await getJobStatus(jobId);
      setLiveStatus(data);
      setLiveError(null);
      return data;
    } catch (err) {
      setLiveError(err instanceof Error ? err.message : "获取任务状态失败");
      return null;
    } finally {
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    let cancelled = false;

    const pollOnce = async () => {
      if (cancelled) return;
      const data = await refresh();
      if (cancelled) return;

      const s = String(data?.status || "").toLowerCase();
      const terminal = ["done", "failed"].includes(s);
      if (terminal) return;

      if (pollTimerRef.current) {
        window.clearTimeout(pollTimerRef.current);
      }
      pollTimerRef.current = window.setTimeout(() => {
        void pollOnce();
      }, 5000);
    };

    void pollOnce();

    return () => {
      cancelled = true;
      if (pollTimerRef.current) {
        window.clearTimeout(pollTimerRef.current);
      }
    };
  }, [jobId]);

  const rawStatus = String(liveStatus?.status || status || "").toLowerCase();
  const displayStatus = ["processing", "done", "failed"].includes(rawStatus) ? rawStatus : "processing";

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "processing":
        return <Badge variant="default">处理中</Badge>;
      case "done":
        return <Badge variant="success">已完成</Badge>;
      case "failed":
        return <Badge variant="destructive">失败</Badge>;
      default:
        return <Badge variant="secondary">{status}</Badge>;
    }
  };

  return (
    <Card className="border-green-500/30 bg-green-50/20 backdrop-blur-sm">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-lg">
          <CheckCircle2 className="h-5 w-5 text-green-600" />
          提交成功
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Live Status */}
        <div className="flex items-center justify-between gap-3 p-3 bg-card/60 border border-border rounded-lg">
          <div className="space-y-1">
            <div className="text-xs text-muted-foreground uppercase tracking-wide">实时状态</div>
            <div className="flex items-center gap-2">
              {getStatusBadge(displayStatus || "unknown")}
              {displayStatus === "processing" && (
                <span className="text-sm text-muted-foreground flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  系统处理中（自动刷新）
                </span>
              )}
            </div>
            {displayStatus === "processing" && retryUntilText ? (
              <div className="text-sm text-muted-foreground">预计完成时间：{retryUntilText}</div>
            ) : null}
            {displayStatus === "failed" && liveStatus?.message ? (
              <div className="text-sm text-muted-foreground">{liveStatus.message}</div>
            ) : null}
            {liveError && <div className="text-xs text-red-600">{liveError}</div>}
          </div>

          <Button variant="outline" size="sm" onClick={refresh} disabled={isRefreshing}>
            <RefreshCw className={`h-4 w-4 mr-2 ${isRefreshing ? "animate-spin" : ""}`} />
            刷新
          </Button>
        </div>

        {/* Task Info Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="space-y-1">
            <div className="text-xs text-muted-foreground uppercase tracking-wide">任务验证码</div>
            <div className="text-foreground font-mono">{taskCode}</div>
          </div>
          <div className="space-y-1">
            <div className="text-xs text-muted-foreground uppercase tracking-wide">当前状态</div>
            {getStatusBadge(displayStatus || "unknown")}
          </div>
          <div className="space-y-1">
            <div className="text-xs text-muted-foreground uppercase tracking-wide">预计耗时</div>
            <div className="text-foreground flex items-center gap-1 text-sm">
              <Clock className="h-3 w-3" />
              约 {estimatedTime} 分钟
            </div>
          </div>
          <div className="space-y-1">
            <div className="text-xs text-muted-foreground uppercase tracking-wide">预计完成时间</div>
            <div className="text-foreground flex items-center gap-1 text-sm">
              <Clock className="h-3 w-3" />
              {retryUntilText || submittedAt}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
