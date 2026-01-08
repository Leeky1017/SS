import { CheckCircle2 } from "lucide-react";

export interface Step {
  label: string;
  description?: string;
}

interface StepProgressProps {
  steps: Step[];
  currentStep: number;
}

export function StepProgress({ steps, currentStep }: StepProgressProps) {
  return (
    <div className="glass-card rounded-2xl p-4 shadow-lg sticky top-24 bg-white/80 backdrop-blur-xl border border-slate-200/50 max-w-[200px]">
      <h4 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">步骤进度</h4>
      <div className="space-y-4 relative">
        {/* Vertical line */}
        <div className="absolute left-3.5 top-2 bottom-2 w-px bg-slate-100"></div>

        {steps.map((step, index) => {
          const isCompleted = index < currentStep;
          const isCurrent = index === currentStep;
          const isFuture = index > currentStep;

          return (
            <div
              key={index}
              className={`flex items-center gap-4 relative z-10 ${isFuture ? 'opacity-60' : ''}`}
            >
              <div
                className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold transition-all
                                    ${isCompleted
                    ? 'bg-emerald-500 text-white shadow-lg shadow-emerald-500/30'
                    : isCurrent
                      ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30'
                      : 'bg-white border border-slate-200 text-slate-300'
                  }`}
              >
                {isCompleted ? (
                  <CheckCircle2 className="h-4 w-4" />
                ) : (
                  index + 1
                )}
              </div>
              <div>
                <div className={`text-sm font-bold ${isFuture ? 'text-slate-400' : 'text-slate-800'}`}>
                  {step.label}
                </div>
                {step.description && (
                  <div className={`text-xs ${isFuture ? 'text-slate-400/80' : 'text-slate-500'}`}>
                    {step.description}
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// Compact mobile version
export function StepProgressMobile({ steps, currentStep }: StepProgressProps) {
  return (
    <div className="md:hidden mb-6">
      <div className="flex items-center justify-between text-sm mb-2">
        <span className="font-medium text-slate-700">{steps[currentStep]?.label}</span>
        <span className="text-slate-400">
          步骤 {currentStep + 1} / {steps.length}
        </span>
      </div>
      <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
        <div
          className="h-full bg-blue-600 rounded-full transition-all duration-500"
          style={{ width: `${((currentStep + 1) / steps.length) * 100}%` }}
        />
      </div>
    </div>
  );
}
