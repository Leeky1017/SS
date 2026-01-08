import { Check, ArrowRight } from "lucide-react";

interface Step {
  number: number;
  title: string;
  description: string;
}

interface StepIndicatorProps {
  currentStep: number;
  steps: Step[];
}

export function StepIndicator({ currentStep, steps }: StepIndicatorProps) {
  return (
    <div className="w-full">
      <div className="flex items-start justify-between gap-4">
        {steps.map((step, index) => {
          const isCompleted = currentStep > step.number;
          const isCurrent = currentStep === step.number;

          return (
            <div key={step.number} className="flex items-start flex-1">
              <div className="flex flex-col items-center flex-1">
                <div className="flex flex-col items-center w-full">
                  <div
                    className={`
                      flex items-center justify-center w-10 h-10 rounded-full transition-all mb-3
                      ${
                        isCompleted
                          ? "bg-primary text-primary-foreground"
                          : isCurrent
                          ? "bg-primary text-primary-foreground ring-4 ring-blue-100"
                          : "bg-secondary text-muted-foreground"
                      }
                    `}
                  >
                    {isCompleted ? (
                      <Check className="w-5 h-5" />
                    ) : (
                      <span className="font-semibold">{step.number}</span>
                    )}
                  </div>

                  <div className="text-center">
                    <div
                      className={`
                        font-medium transition-colors
                        ${isCurrent ? "text-foreground" : "text-muted-foreground"}
                      `}
                    >
                      {step.title}
                    </div>
                    <div className="text-xs text-muted-foreground mt-1">
                      {step.description}
                    </div>
                  </div>
                </div>
              </div>

              {index < steps.length - 1 && (
                <div className="flex items-center pt-3 px-4">
                  <ArrowRight
                    className={`
                      w-6 h-6 transition-colors
                      ${isCompleted ? "text-primary" : "text-border"}
                    `}
                  />
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
