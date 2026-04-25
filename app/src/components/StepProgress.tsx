interface StepProgressProps {
  currentStep: number;
  totalSteps: number;
}

export function StepProgress({ currentStep, totalSteps }: StepProgressProps) {
  const safeTotal = Math.max(totalSteps, 1);
  const safeCurrent = Math.max(0, Math.min(currentStep, safeTotal));
  const percent = Math.round((safeCurrent / safeTotal) * 100);

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between text-sm text-gray-400">
        <span>Step {safeCurrent} of {safeTotal}</span>
        <span>{percent}%</span>
      </div>
      <div className="h-1.5 rounded-full bg-gray-800 overflow-hidden" aria-hidden="true">
        <div
          className="h-full rounded-full bg-ev-blue transition-all duration-500"
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
}
