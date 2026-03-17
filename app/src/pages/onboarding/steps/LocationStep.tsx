import { useState } from 'react';
import { apiFetch } from '../../../lib/api';

export interface LocationResult {
  location_consent: boolean;
  first_location: boolean;
  jurisdiction: {
    congressional_district: string | null;
    congressional_district_name: string | null;
    state_senate_district: string | null;
    state_senate_district_name: string | null;
    state_house_district: string | null;
    state_house_district_name: string | null;
    county: string | null;
    county_name: string | null;
    school_district: string | null;
    school_district_name: string | null;
  };
}

const ERROR_MESSAGES: Record<string, string> = {
  ADDRESS_NOT_FOUND:
    "We couldn't find that address. Try including your city and state, or use a more specific street address.",
  PO_BOX_REJECTED:
    "We need a residential street address to find your representatives. PO Boxes can't be mapped to districts.",
  OUT_OF_COVERAGE:
    "We're not in your area yet, but we're expanding. We'll let you know when we arrive.",
  VALIDATION_ERROR: 'Please enter a complete address.',
  INTERNAL_ERROR: 'Something went wrong on our end. Please try again in a moment.',
};

interface Props {
  isUpdate?: boolean;
  onSuccess: (result: LocationResult) => void;
}

export function LocationStep({ isUpdate = false, onSuccess }: Props) {
  const [revealed, setRevealed] = useState(isUpdate); // skip reveal animation for update flow
  const [address, setAddress] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!address.trim()) {
      setError('Please enter your address.');
      return;
    }
    setError('');
    setLoading(true);
    try {
      const result = await apiFetch<LocationResult>('/connect/set-location', {
        method: 'POST',
        body: JSON.stringify({ address: address.trim() }),
      });
      onSuccess(result);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'INTERNAL_ERROR';
      setError(ERROR_MESSAGES[msg] ?? ERROR_MESSAGES.INTERNAL_ERROR);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-screen px-6">
      <div className="max-w-md w-full space-y-8">

        {!isUpdate && (
          <div className="space-y-2 text-center">
            <h2 className="text-2xl font-bold text-ev-black dark:text-white">
              One more thing.
            </h2>
            <p className="text-gray-500 dark:text-gray-400 text-sm">Step 2 of 3</p>
          </div>
        )}

        {isUpdate && (
          <div className="space-y-2">
            <h2 className="text-2xl font-bold text-ev-black dark:text-white">
              Update your location
            </h2>
            <p className="text-gray-500 dark:text-gray-400 text-sm">
              Moved? We'll refresh your district connections.
            </p>
          </div>
        )}

        {/* Context-first — shown before the input is revealed */}
        <div className="bg-ev-teal/5 border border-ev-teal/20 rounded-2xl p-5 space-y-3">
          <p className="text-ev-black dark:text-white font-medium leading-snug">
            To connect you to your representatives, we need to know where you live.
          </p>
          <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
            Your address is encrypted and never shared. We use it only to identify
            your voting districts and the civic communities closest to you.
          </p>
          {!revealed && (
            <button
              onClick={() => setRevealed(true)}
              className="text-ev-teal text-sm font-semibold hover:underline"
            >
              I understand — show the input →
            </button>
          )}
        </div>

        {/* Address input — revealed after context */}
        {revealed && (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-ev-black dark:text-white mb-1.5">
                Home address
              </label>
              <input
                type="text"
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="123 Main St, Indianapolis, IN 46201"
                autoFocus
                className="w-full border border-gray-300 dark:border-gray-600 rounded-xl px-4 py-3 bg-white dark:bg-gray-900 text-ev-black dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-ev-teal text-base"
              />
              {error && (
                <p className="mt-2 text-sm text-ev-red leading-snug">{error}</p>
              )}
            </div>

            <p className="text-xs text-gray-400 leading-relaxed">
              Your congressional representative votes on federal legislation that affects your
              life. Knowing who they are is step one.
            </p>

            <button
              type="submit"
              disabled={loading || !address.trim()}
              className="w-full bg-ev-teal text-white rounded-xl py-3.5 font-semibold text-base hover:bg-ev-teal/90 disabled:opacity-40 transition-colors"
            >
              {loading ? 'Finding your community…' : isUpdate ? 'Update location' : 'Find my representatives'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
