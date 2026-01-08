import { useState, useEffect } from "react";
import { AlertTriangle, FileCheck, Clock, Info } from "lucide-react";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogFooter,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogAction,
} from "@/components/ui/alert-dialog";

const STORAGE_KEY = "ss_tips_acknowledged";

interface TipsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function TipsDialog({ open, onOpenChange }: TipsDialogProps) {
  const [dontShowAgain, setDontShowAgain] = useState(false);

  const handleConfirm = () => {
    if (dontShowAgain) {
      localStorage.setItem(STORAGE_KEY, "true");
    }
    onOpenChange(false);
  };

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent className="max-w-md">
        <AlertDialogHeader>
          <AlertDialogTitle className="flex items-center gap-2">
            <Info className="h-5 w-5 text-primary" />
            使用须知
          </AlertDialogTitle>
          <AlertDialogDescription asChild>
            <div className="space-y-4 pt-2">
              <div className="flex gap-3 text-left">
                <AlertTriangle className="h-5 w-5 text-amber-500 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="font-medium text-foreground">确认任务需求</p>
                  <p className="text-sm text-muted-foreground">
                    请确保您的分析需求符合统计学逻辑，系统将根据您的描述生成分析代码。
                  </p>
                </div>
              </div>

              <div className="flex gap-3 text-left">
                <FileCheck className="h-5 w-5 text-blue-500 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="font-medium text-foreground">数据质量要求</p>
                  <p className="text-sm text-muted-foreground">
                    如果分析结果不符合预期，建议重新检查数据质量并确保数据收集过程的严谨性。
                  </p>
                </div>
              </div>

              <div className="flex gap-3 text-left">
                <Clock className="h-5 w-5 text-orange-500 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="font-medium text-foreground">及时下载结果</p>
                  <p className="text-sm text-muted-foreground">
                    任务完成后 48 小时内请及时下载分析结果，到期后系统将自动清理。
                  </p>
                </div>
              </div>

              <label className="flex items-center gap-2 pt-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={dontShowAgain}
                  onChange={(e) => setDontShowAgain(e.target.checked)}
                  className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
                />
                <span className="text-sm text-muted-foreground">
                  我已阅读并理解以上内容，不再显示
                </span>
              </label>
            </div>
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogAction onClick={handleConfirm}>
            我知道了
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}

/**
 * Hook: 管理小贴士弹窗的显示状态
 */
export function useTipsDialog() {
  const [open, setOpen] = useState(false);

  useEffect(() => {
    // 检查是否已经确认过
    const acknowledged = localStorage.getItem(STORAGE_KEY);
    if (!acknowledged) {
      // 首次访问，延迟显示弹窗
      const timer = setTimeout(() => setOpen(true), 500);
      return () => clearTimeout(timer);
    }
  }, []);

  const showTips = () => setOpen(true);

  return { open, setOpen, showTips };
}
