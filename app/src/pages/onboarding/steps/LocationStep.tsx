import { useState } from 'react';
import { useNavigate } from 'react-router';
import { apiFetch } from '../../../lib/api';
import { useAuthStore } from '../../../store/authStore';
import { AuthPageLayout } from '../../../components/AuthPageLayout';
import { AuthCard } from '../../../components/AuthCard';
import { AuthInput } from '../../../components/AuthInput';
import { PrimaryButton } from '../../../components/PrimaryButton';
import { SecondaryButton } from '../../../components/SecondaryButton';

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
  // 403s from requireConnected (backend/src/middleware/tierGuards.ts). Retrying
  // never changes these, so they must not fall through to INTERNAL_ERROR.
  //
  // CONNECTED_REQUIRED is NOT "basic accounts cannot add an address" — they can,
  // through /account/set-location (CA_0368). It only reaches this page when the
  // app sent a basic account down the Connected route, i.e. the tier it holds is
  // out of date (for example, an account changed tier in another tab). A reload
  // re-reads the account and picks the right route.
  CONNECTED_REQUIRED:
    "We couldn't match this page to your account type. Reload the page and try again.",
  CONNECTED_UNVERIFIED:
    'Your Connected account has not been verified yet. You can add an address once it is.',
};

// The same two refusals as sent before the guard carried a `code`. Kept so the
// message is right whichever of the app and the API deploys first.
ERROR_MESSAGES['Connected account required'] = ERROR_MESSAGES.CONNECTED_REQUIRED;
ERROR_MESSAGES['Verified Connected account required'] = ERROR_MESSAGES.CONNECTED_UNVERIFIED;

interface Props {
  isUpdate?: boolean;
  onSuccess: (result: LocationResult) => void;
}

export function LocationStep({ isUpdate = false, onSuccess }: Props) {
  const navigate = useNavigate();
  const tier = useAuthStore((st) => st.user?.tier);
  const isConnectedTier = tier === 'connected' || tier === 'empowered';
  const [street, setStreet] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [zip, setZip] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const isComplete = street.trim() && city.trim() && state.trim() && zip.trim();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!isComplete) {
      setError('Please fill in all address fields.');
      return;
    }
    setError('');
    setLoading(true);
    const address = `${street.trim()}, ${city.trim()}, ${state.trim()} ${zip.trim()}`;
    try {
      // Two routes, one per tier. A basic account keeps only its districts (CA_0368); a
      // Connected account also keeps an encrypted point and seals the address in the identity
      // vault. Both answer the same LocationResult shape and the same error codes.
      const result = isConnectedTier
        ? await apiFetch<LocationResult>('/connect/set-location', {
            method: 'POST',
            body: JSON.stringify({ address, ...(isUpdate && { force: true }) }),
          })
        : await apiFetch<LocationResult>('/account/set-location', {
            method: 'POST',
            body: JSON.stringify({ address }),
          });
      onSuccess(result);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'INTERNAL_ERROR';
      setError(ERROR_MESSAGES[msg] ?? ERROR_MESSAGES.INTERNAL_ERROR);
    } finally {
      setLoading(false);
    }
  }

  const cardContent = (
    <AuthCard>
      {!isUpdate && (
        <div className="flex justify-center">
          <div className="w-16 h-16 rounded-full bg-ev-blue/10 flex items-center justify-center">
            <svg
              className="w-8 h-8 text-ev-blue"
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
              viewBox="0 0 24 24"
              aria-hidden="true"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25s-7.5-4.108-7.5-11.25a7.5 7.5 0 1115 0z"
              />
            </svg>
          </div>
        </div>
      )}

      <div className={isUpdate ? 'space-y-1' : 'space-y-2 text-center'}>
        <h2 className="text-2xl font-bold text-white">
          {isUpdate ? 'Update your location' : 'Find your civic community'}
        </h2>
        <p className="text-sm text-gray-400 leading-relaxed">
          {isUpdate
            ? "Moved? We'll refresh your district connections."
            : 'We use your location to connect you with your local civic space.'}
        </p>
      </div>

      {error && (
        <div className="bg-red-950/40 border border-red-800/60 rounded-xl px-4 py-3">
          <p className="text-sm text-ev-red">{error}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <AuthInput
          label="Street address"
          value={street}
          onChange={setStreet}
          placeholder="123 Main St"
          autoComplete="address-line1"
          autoFocus
          required
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <AuthInput
            label="City"
            value={city}
            onChange={setCity}
            placeholder="Indianapolis"
            autoComplete="address-level2"
            required
          />

          <AuthInput
            label="State"
            value={state}
            onChange={(value) => setState(value.toUpperCase().slice(0, 2))}
            placeholder="IN"
            autoComplete="address-level1"
            required
          />
        </div>

        <AuthInput
          label="ZIP code"
          value={zip}
          onChange={(value) => setZip(value.replace(/\D/g, '').slice(0, 5))}
          placeholder="46201"
          autoComplete="postal-code"
          required
          inputProps={{ inputMode: 'numeric' }}
        />

        <PrimaryButton type="submit" disabled={loading || !isComplete}>
          {loading
            ? 'Finding your community…'
            : isUpdate
            ? 'Update location'
            : 'Find my representatives'}
        </PrimaryButton>

        {!isUpdate && (
          <SecondaryButton onClick={() => navigate('/welcome')}>
            Back
          </SecondaryButton>
        )}
      </form>
    </AuthCard>
  );

  if (isUpdate) {
    return cardContent;
  }

  return (
    <AuthPageLayout step={{ current: 2, total: 3 }}>
      {cardContent}
    </AuthPageLayout>
  );
}
