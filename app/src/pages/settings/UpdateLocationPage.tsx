import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useAuthStore } from '../../store/authStore';
import { LocationStep, type LocationResult } from '../onboarding/steps/LocationStep';

export default function UpdateLocationPage() {
  const navigate = useNavigate();
  const { updateUser } = useAuthStore();
  const [confirmed, setConfirmed] = useState<LocationResult | null>(null);

  function handleSuccess(result: LocationResult) {
    updateUser({ locationConsent: true });
    setConfirmed(result);
  }

  if (confirmed) {
    const { jurisdiction } = confirmed;
    return (
      <div className="flex flex-col items-center justify-center min-h-screen px-6 text-center bg-white dark:bg-ev-black">
        <div className="max-w-md w-full space-y-6">
          <div className="flex justify-center">
            <div className="w-16 h-16 rounded-full bg-ev-teal/10 flex items-center justify-center">
              <svg className="w-8 h-8 text-ev-teal" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
            </div>
          </div>

          <div className="space-y-2">
            <h2 className="text-2xl font-bold text-ev-black dark:text-white">Location updated.</h2>
            <p className="text-gray-500 dark:text-gray-400 text-sm">
              Your community connections have been refreshed.
            </p>
          </div>

          {jurisdiction.congressional_district_name && (
            <p className="text-ev-teal font-medium">{jurisdiction.congressional_district_name}</p>
          )}

          <button
            onClick={() => navigate(-1)}
            className="w-full bg-ev-teal text-white rounded-xl py-3 font-semibold hover:bg-ev-teal/90 transition-colors"
          >
            Done
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white dark:bg-ev-black min-h-screen">
      <div className="max-w-md mx-auto px-6 pt-6">
        <button
          onClick={() => navigate(-1)}
          className="text-sm text-gray-500 hover:text-ev-teal transition-colors mb-2"
        >
          ← Back
        </button>
      </div>
      <LocationStep isUpdate onSuccess={handleSuccess} />
    </div>
  );
}
