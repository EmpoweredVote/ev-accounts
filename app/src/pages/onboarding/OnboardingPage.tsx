import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router';
import { apiFetch } from '../../lib/api';
import { useAuthStore } from '../../store/authStore';
import { LocationStep, type LocationResult } from './steps/LocationStep';
import { LocationCelebrationStep } from './steps/LocationCelebrationStep';

type Step = 'location' | 'location-celebration';

export default function OnboardingPage() {
  const { user, updateUser } = useAuthStore();
  const navigate = useNavigate();

  const initialLocationConsent = user?.locationConsent ?? false;
  const [step, setStep] = useState<Step>('location');
  const [locationResult, setLocationResult] = useState<LocationResult | null>(null);
  const [resuming, setResuming] = useState(initialLocationConsent);

  // Resumption: user already has locationConsent=true but no completedOnboarding —
  // finish onboarding silently and bounce to dashboard. We can't show the celebration
  // step because we don't have a fresh LocationResult on remount.
  useEffect(() => {
    if (!initialLocationConsent) return;
    let cancelled = false;
    (async () => {
      try {
        await apiFetch('/auth/complete-onboarding', { method: 'POST' });
        if (cancelled) return;
        updateUser({ completedOnboarding: true });
        navigate('/', { replace: true });
      } catch {
        // If complete-onboarding fails, fall back to showing the location step
        // so the user has SOMETHING to do; they can re-submit and try again.
        if (!cancelled) setResuming(false);
      }
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function handleLocationSuccess(result: LocationResult) {
    updateUser({ locationConsent: true });
    setLocationResult(result);
    setStep('location-celebration');
  }

  function handleOnboardingComplete() {
    navigate('/', { replace: true });
  }

  if (resuming) {
    return (
      <div className="min-h-screen bg-ev-navy flex items-center justify-center">
        <p className="text-gray-400 text-sm">Finalizing your account…</p>
      </div>
    );
  }

  return (
    <>
      {step === 'location' && (
        <LocationStep onSuccess={handleLocationSuccess} />
      )}

      {step === 'location-celebration' && locationResult && (
        <LocationCelebrationStep
          result={locationResult}
          onComplete={handleOnboardingComplete}
        />
      )}
    </>
  );
}
