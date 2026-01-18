type StepperStep = {
  label: string
  state: 'done' | 'active' | 'upcoming'
  onClick?: () => void
}

export function Stepper(props: { steps: StepperStep[] }) {
  const cols = Math.max(1, props.steps.length)
  return (
    <div className="ss-stepper" aria-label="步骤">
      <div className="ss-stepper-track" aria-hidden="true">
        {props.steps.map((step, idx) => (
          <div key={`${step.state}_${idx}`} className={`ss-stepper-tick ${step.state}`} />
        ))}
      </div>
      <div className="ss-stepper-labels" style={{ gridTemplateColumns: `repeat(${cols}, 1fr)` }}>
        {props.steps.map((step, idx) => {
          const className = `ss-stepper-label ${step.state}${step.onClick ? ' clickable' : ''}`
          if (step.onClick) {
            return (
              <button key={`${step.label}_${idx}`} type="button" className={className} onClick={step.onClick}>
                {step.label}
              </button>
            )
          }
          return (
            <div key={`${step.label}_${idx}`} className={className}>
              {step.label}
            </div>
          )
        })}
      </div>
    </div>
  )
}
