import type { ReactNode } from 'react';
import { StepProgress } from './StepProgress';

interface AuthPageLayoutProps {
  children: ReactNode;
  step?: { current: number; total: number };
}

export function AuthPageLayout({ children, step }: AuthPageLayoutProps) {
  return (
    <div className="min-h-screen bg-ev-navy flex flex-col">
      <header className="md:hidden bg-ev-navy border-b border-white/10 sticky top-0 z-10">
        <div className="px-4 h-14 flex items-center">
          <img src="/logo.png" alt="Empowered Vote" className="h-6 w-auto" />
        </div>
      </header>

      <div className="flex-1 flex flex-col px-4 py-8 md:justify-center md:py-12">
        <div className="hidden md:block mb-10">
          <img src="/logo.png" alt="Empowered Vote" className="h-8 w-auto mx-auto" />
        </div>

        {step && (
          <div className="w-full max-w-sm md:max-w-lg mx-auto mb-6">
            <StepProgress currentStep={step.current} totalSteps={step.total} />
          </div>
        )}

        <div className="w-full max-w-sm md:max-w-md mx-auto">
          {children}
        </div>
      </div>
    </div>
  );
}
