import { useCallback, useEffect, useState } from "react";
import { Header } from "./components/Header";
import { Hero } from "./components/Hero";
import { TabNavigation, type TabType } from "./components/TabNavigation";
import { TaskCreationForm, type TaskSubmitResult } from "./components/TaskCreationForm";
import { TaskResult } from "./components/TaskResult";
import { TaskQuery } from "./components/TaskQuery";
import { ConfirmationStep } from "./components/ConfirmationStep";
import { SheetSelectionStep } from "./components/SheetSelectionStep";
import { StepProgress, StepProgressMobile, type Step } from "./components/StepProgress";
import { TipsDialog, useTipsDialog } from "./components/TipsDialog";

const SUBMIT_STEPS: Step[] = [
  { label: '填写需求', description: '验证任务并上传数据' },
  { label: '系统确认', description: '智能化变量映射校验' },
  { label: '执行分析', description: '获取分析结果' },
];

// Workflow states for submit tab
type SubmitFlowState = "form" | "sheet_select" | "confirming" | "completed";

const RESUME_STORAGE_KEY = "ss_task_resume_state";
const RESUME_EXPIRY_HOURS = 24;

type ResumeState = {
  taskCode: string;
  jobId: string;
  resumablePhase: string;
  savedAt: number;
};

function loadResumeState(): ResumeState | null {
  try {
    const raw = localStorage.getItem(RESUME_STORAGE_KEY);
    if (!raw) return null;
    const data = JSON.parse(raw) as Partial<ResumeState>;
    const savedAt = Number(data.savedAt || 0);
    const hoursSinceSave = (Date.now() - savedAt) / (1000 * 60 * 60);
    if (!data.taskCode || !data.jobId || !data.resumablePhase || !savedAt || hoursSinceSave > RESUME_EXPIRY_HOURS) {
      localStorage.removeItem(RESUME_STORAGE_KEY);
      return null;
    }
    return data as ResumeState;
  } catch {
    return null;
  }
}

function saveResumeState(state: Omit<ResumeState, "savedAt">) {
  try {
    localStorage.setItem(
      RESUME_STORAGE_KEY,
      JSON.stringify({
        ...state,
        savedAt: Date.now(),
      })
    );
  } catch {
    // ignore
  }
}

function clearResumeState() {
  try {
    localStorage.removeItem(RESUME_STORAGE_KEY);
  } catch {
    // ignore
  }
}

export default function App() {
  const [activeTab, setActiveTab] = useState<TabType>('submit');
  const [submitFlowState, setSubmitFlowState] = useState<SubmitFlowState>("form");
  const [pendingJobId, setPendingJobId] = useState<string | null>(null);
  const [submittedTask, setSubmittedTask] = useState<TaskSubmitResult | null>(null);
  const { open: tipsOpen, setOpen: setTipsOpen, showTips } = useTipsDialog();

  // Called when files are uploaded (before confirmation)
  const handleFilesUploaded = (data: TaskSubmitResult) => {
    setPendingJobId(data.jobId);
    setSubmittedTask(data);
    setSubmitFlowState("sheet_select");
  };

  // Called when user confirms the draft
  const handleConfirmed = () => {
    setSubmitFlowState("completed");
  };

  // Called when user wants to go back from confirmation (UX-001: preserve data)
  const handleBackFromConfirmation = () => {
    setSubmitFlowState("form");
    // Do NOT clear pendingJobId - form data is preserved in localStorage
  };

  const handleSheetSelectionDone = () => {
    setSubmitFlowState("confirming");
  };

  const handleViewTaskStatus = () => {
    setActiveTab('query');
  };

  const resumeToPhase = useCallback(
    (jobId: string, phase: string, taskCode: string, opts?: { persist?: boolean }) => {
      const persist = opts?.persist !== false;

      setPendingJobId(jobId);
      setSubmittedTask((prev) => {
        if (prev && prev.jobId === jobId && prev.taskCode === taskCode) return prev;
        const now = new Date();
        return {
          taskCode,
          jobId,
          status: "queued",
          estimatedTime: 80,
          submittedAt: now
            .toLocaleString("zh-CN", {
              year: "numeric",
              month: "2-digit",
              day: "2-digit",
              hour: "2-digit",
              minute: "2-digit",
              hour12: false,
            })
            .replace(/\//g, "-"),
        };
      });

      setActiveTab("submit");

      if (phase === "bundle_uploaded") {
        setSubmitFlowState("sheet_select");
      } else if (phase === "previewing" || phase === "draft_ready") {
        setSubmitFlowState("confirming");
      } else if (phase === "confirmed" || phase === "completed") {
        setSubmitFlowState("completed");
      }

      if (persist) {
        saveResumeState({ taskCode, jobId, resumablePhase: phase });
      }
    },
    []
  );

  const handleResumeTask = useCallback(
    (jobId: string, phase: string, taskCode: string) => {
      if (!jobId || !phase || !taskCode) return;
      resumeToPhase(jobId, phase, taskCode);
    },
    [resumeToPhase]
  );

  // Auto-resume after refresh / accidental close (localStorage)
  useEffect(() => {
    const saved = loadResumeState();
    if (!saved) return;
    resumeToPhase(saved.jobId, saved.resumablePhase, saved.taskCode, { persist: false });
  }, [resumeToPhase]);

  // Persist resume state while in submit flow (non-form states only)
  useEffect(() => {
    if (!pendingJobId || !submittedTask?.taskCode) return;
    if (submitFlowState === "form") {
      clearResumeState();
      return;
    }

    const phase =
      submitFlowState === "sheet_select"
        ? "bundle_uploaded"
        : submitFlowState === "confirming"
          ? "draft_ready"
          : "confirmed";
    saveResumeState({ taskCode: submittedTask.taskCode, jobId: pendingJobId, resumablePhase: phase });
  }, [pendingJobId, submitFlowState, submittedTask?.taskCode]);

  // Reset flow when switching tabs
  const handleTabChange = (tab: TabType) => {
    setActiveTab(tab);
    if (tab === 'submit' && submitFlowState !== 'completed') {
      // Keep state if completed, reset if not
    }
  };

  const currentStep = submitFlowState === 'form' ? 0 : submitFlowState === 'completed' ? 2 : 1;

  return (
    <div className="min-h-screen flex flex-col bg-gradient-to-b from-slate-50 via-white to-slate-50">
      <Header onShowTips={showTips} />
      <TipsDialog open={tipsOpen} onOpenChange={setTipsOpen} />
      <Hero />

      <main className="flex-1">
        {/* Tab Navigation */}
        <TabNavigation activeTab={activeTab} onTabChange={handleTabChange} />

        {/* Tab Content */}
        <div className="py-12">
          <div className="container mx-auto px-6">
            {/* Submit Tab - Centered Layout with Fixed Right Sidebar */}
            {activeTab === 'submit' && (
              <div className="animate-fadeIn relative">
                {/* Mobile Step Progress */}
                <StepProgressMobile steps={SUBMIT_STEPS} currentStep={currentStep} />

                {/* Fixed Right Sidebar - Step Progress (Desktop) */}
                <div className="hidden lg:block fixed right-6 xl:right-12 top-1/2 -translate-y-1/2 z-20">
                  <StepProgress steps={SUBMIT_STEPS} currentStep={currentStep} />
                </div>

                {/* Main Content - Centered */}
                <div className="max-w-3xl mx-auto space-y-8">
                  {/* Form State - Initial form */}
                  {submitFlowState === "form" && (
                    <TaskCreationForm onSubmit={handleFilesUploaded} />
                  )}

                  {/* Confirming State - Show draft preview and questions */}
                  {submitFlowState === "sheet_select" && pendingJobId && (
                    <SheetSelectionStep
                      jobId={pendingJobId}
                      onDone={handleSheetSelectionDone}
                      onBack={handleBackFromConfirmation}
                    />
                  )}

                  {submitFlowState === "confirming" && pendingJobId && (
                    <ConfirmationStep
                      jobId={pendingJobId}
                      onConfirmed={handleConfirmed}
                      onBack={handleBackFromConfirmation}
                    />
                  )}

                  {/* Completed State - Show result */}
                  {submitFlowState === "completed" && submittedTask && (
                    <div id="task-result" className="space-y-6">
                      <TaskResult
                        taskCode={submittedTask.taskCode}
                        jobId={submittedTask.jobId}
                        status="queued"
                        estimatedTime={submittedTask.estimatedTime}
                        submittedAt={submittedTask.submittedAt}
                      />

	                      <div className="flex justify-center gap-4">
	                        <button
	                          onClick={() => {
	                            clearResumeState();
	                            setSubmitFlowState("form");
	                            setPendingJobId(null);
	                            setSubmittedTask(null);
	                          }}
	                          className="px-6 py-3 bg-slate-100 text-slate-700 rounded-xl hover:bg-slate-200 transition-colors font-medium"
	                        >
	                          提交新任务
	                        </button>
                        <button
                          onClick={handleViewTaskStatus}
                          className="px-8 py-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors font-medium shadow-lg shadow-blue-600/20"
                        >
                          查看任务状态 →
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Query Tab */}
            {activeTab === 'query' && (
              <div className="max-w-4xl mx-auto animate-fadeIn">
                <div className="mb-8">
                  <div className="flex items-center justify-between mb-2">
                    <h2 className="text-2xl font-bold text-slate-900">任务状态与结果查询</h2>
                    <span className="px-3 py-1 bg-emerald-50 text-emerald-600 rounded-full text-sm font-bold border border-emerald-200">
                      查询
                    </span>
                  </div>
                  <p className="text-slate-500">
                    使用任务验证码查询任务状态并下载结果
                  </p>
                </div>

                <TaskQuery initialTaskCode={submittedTask?.taskCode || ""} onResumeTask={handleResumeTask} />
              </div>
            )}
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-white/80 backdrop-blur-sm border-t border-slate-200/50 py-8">
        <div className="container mx-auto px-6">
          <div className="text-center space-y-2">
            <p className="text-slate-500">
              © 2025 Stata Analysis Service. All Rights Reserved.
            </p>
            <p className="text-xs text-slate-400">
              Powered by FastAPI & Stata 18 MP
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
