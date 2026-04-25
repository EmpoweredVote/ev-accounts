import { useState } from 'react';
import type { LocationResult } from './LocationStep';
import { apiFetch } from '../../../lib/api';
import { useAuthStore } from '../../../store/authStore';
import { AppNav } from '../../../components/AppNav';
import { StepProgress } from '../../../components/StepProgress';
import { AuthCard } from '../../../components/AuthCard';
import { PrimaryButton } from '../../../components/PrimaryButton';

interface Props {
  result: LocationResult;
  onComplete: () => void;
}

export function LocationCelebrationStep({ onComplete }: Props) {
  const { updateUser } = useAuthStore();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleGoToDashboard() {
    setError('');
    setLoading(true);
    try {
      await apiFetch('/auth/complete-onboarding', { method: 'POST' });
      updateUser({ completedOnboarding: true });
      onComplete();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-ev-navy flex flex-col">
      <AppNav />
      <div className="flex-1 px-4 py-8">
        <div className="max-w-sm mx-auto space-y-6">
          <StepProgress currentStep={3} totalSteps={3} />
          <AuthCard>
            {/* Green checkmark badge */}
            <div className="flex justify-center">
              <div className="w-16 h-16 rounded-full bg-green-500/15 flex items-center justify-center">
                <svg className="w-9 h-9 text-green-400" fill="none" stroke="currentColor" strokeWidth={3} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                </svg>
              </div>
            </div>

            {/* Heading + subhead */}
            <div className="space-y-2 text-center">
              <h2 className="text-2xl font-bold text-white">You're connected</h2>
              <p className="text-sm text-gray-400 leading-relaxed">Your Connected Account is ready.</p>
            </div>

            {/* Three milestone rows */}
            <ul className="space-y-3">
              {[
                "Your Connected Account is live",
                "Your civic community is located",
                "You're ready to participate",
              ].map((label) => (
                <li key={label} className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-green-500/15 flex items-center justify-center flex-shrink-0">
                    <svg className="w-5 h-5 text-green-400" fill="none" stroke="currentColor" strokeWidth={3} viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                  <span className="text-sm text-white leading-snug">{label}</span>
                </li>
              ))}
            </ul>

            {/* Inline error */}
            {error && (
              <div className="bg-red-950/40 border border-red-800/60 rounded-xl px-4 py-3">
                <p className="text-sm text-ev-red">{error}</p>
              </div>
            )}

            {/* CTA */}
            <PrimaryButton onClick={handleGoToDashboard} disabled={loading}>
              {loading ? 'Finalizing…' : 'Go to dashboard'}
            </PrimaryButton>
          </AuthCard>
        </div>
      </div>
    </div>
  );
}
