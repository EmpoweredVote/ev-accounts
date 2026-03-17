import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';
import { WelcomeStep } from './steps/WelcomeStep';
import { LocationStep, type LocationResult } from './steps/LocationStep';
import { LocationCelebrationStep } from './steps/LocationCelebrationStep';
import { PseudonymStep } from './steps/PseudonymStep';

type Step = 'welcome' | 'location' | 'location-celebration' | 'pseudonym';

function initialStep(locationConsent: boolean): Step {
  // Resumption: if they already set location, skip straight to pseudonym
  if (locationConsent) return 'pseudonym';
  return 'welcome';
}

export default function OnboardingPage() {
  const { user, updateUser } = useAuthStore();
  const navigate = useNavigate();

  const [step, setStep] = useState<Step>(
    initialStep(user?.locationConsent ?? false)
  );
  const [locationResult, setLocationResult] = useState<LocationResult | null>(null);

  function handleLocationSuccess(result: LocationResult) {
    updateUser({ locationConsent: true });
    setLocationResult(result);
    if (result.first_location) {
      setStep('location-celebration');
    } else {
      // Shouldn't happen in onboarding (first_location always true here),
      // but handle gracefully
      setStep('pseudonym');
    }
  }

  function handleOnboardingComplete() {
    navigate('/', { replace: true });
  }

  return (
    <div className="bg-white dark:bg-ev-black min-h-screen">
      {step === 'welcome' && (
        <WelcomeStep onContinue={() => setStep('location')} />
      )}

      {step === 'location' && (
        <LocationStep onSuccess={handleLocationSuccess} />
      )}

      {step === 'location-celebration' && locationResult && (
        <LocationCelebrationStep
          result={locationResult}
          onContinue={() => setStep('pseudonym')}
        />
      )}

      {step === 'pseudonym' && (
        <PseudonymStep
          currentDisplayName={user?.displayName ?? null}
          onComplete={handleOnboardingComplete}
        />
      )}
    </div>
  );
}
