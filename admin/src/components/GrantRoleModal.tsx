import { useEffect, useRef, useState } from 'react';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import { apiFetch } from '../lib/api';

// ── Types ─────────────────────────────────────────────────────────────────────

interface AvailableRole {
  id: string;
  slug: string;
  name: string;
  required_tier: string;
  description: string | null;
  is_active?: boolean;
}

interface AvailableRolesResponse {
  roles: AvailableRole[];
}

interface Politician {
  id: string;
  first_name: string;
  last_name: string;
  preferred_name: string | null;
  full_name: string | null;
  office_title: string | null;
}

interface PoliticiansResponse {
  politicians: Politician[];
}

interface JurisdictionHints {
  county_geo_id: string | null;
  county_name: string | null;
  congressional_geo_id: string | null;
  congressional_district_name: string | null;
  state_senate_geo_id: string | null;
  state_senate_district_name: string | null;
  state_house_geo_id: string | null;
  state_house_district_name: string | null;
}

function politicianLabel(p: Politician): string {
  const name = p.full_name ?? [p.preferred_name ?? p.first_name, p.last_name].filter(Boolean).join(' ');
  return p.office_title ? `${name} — ${p.office_title}` : name;
}

// ── PoliticianSearch ───────────────────────────────────────────────────────────

interface PoliticianSearchProps {
  politicians: Politician[];
  loading: boolean;
  value: Politician | null;
  onChange: (p: Politician | null) => void;
}

function PoliticianSearch({ politicians, loading, value, onChange }: PoliticianSearchProps) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  // Close on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const matches = query.trim().length < 2
    ? []
    : politicians
        .filter(p => {
          const q = query.toLowerCase();
          const label = politicianLabel(p).toLowerCase();
          const last = (p.last_name ?? '').toLowerCase();
          const first = (p.first_name ?? '').toLowerCase();
          return label.includes(q) || last.startsWith(q) || first.startsWith(q);
        })
        .slice(0, 10);

  function select(p: Politician) {
    onChange(p);
    setQuery('');
    setOpen(false);
  }

  function clear() {
    onChange(null);
    setQuery('');
    setOpen(false);
  }

  if (loading) {
    return <div className="h-9 bg-gray-100 dark:bg-gray-800 rounded animate-pulse" />;
  }

  if (value) {
    return (
      <div className="flex items-center gap-2 px-3 py-2 border border-blue-400 dark:border-blue-600 rounded bg-blue-50 dark:bg-blue-950/30">
        <span className="flex-1 text-sm text-gray-900 dark:text-white truncate">
          {politicianLabel(value)}
        </span>
        <button
          type="button"
          onClick={clear}
          className="flex-shrink-0 text-gray-400 hover:text-red-500 transition-colors"
          title="Clear selection"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    );
  }

  return (
    <div ref={containerRef} className="relative">
      <input
        type="text"
        value={query}
        onChange={(e) => { setQuery(e.target.value); setOpen(true); }}
        onFocus={() => { if (query.trim().length >= 2) setOpen(true); }}
        placeholder="Type a name to search…"
        className="w-full border border-gray-300 dark:border-gray-600 rounded px-3 py-2 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
        autoComplete="off"
      />
      {open && matches.length > 0 && (
        <ul className="absolute z-50 mt-1 w-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded shadow-lg max-h-60 overflow-y-auto">
          {matches.map(p => (
            <li key={p.id}>
              <button
                type="button"
                onMouseDown={() => select(p)}
                className="w-full text-left px-3 py-2 text-sm hover:bg-blue-50 dark:hover:bg-blue-950/30 text-gray-900 dark:text-white"
              >
                <span className="font-medium">
                  {p.full_name ?? `${p.preferred_name ?? p.first_name} ${p.last_name}`}
                </span>
                {p.office_title && (
                  <span className="ml-1 text-gray-400 text-xs">— {p.office_title}</span>
                )}
              </button>
            </li>
          ))}
        </ul>
      )}
      {open && query.trim().length >= 2 && matches.length === 0 && (
        <div className="absolute z-50 mt-1 w-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded shadow-lg px-3 py-2 text-sm text-gray-400">
          No politicians found
        </div>
      )}
      {query.trim().length < 2 && query.length > 0 && (
        <p className="mt-1 text-xs text-gray-400">Type at least 2 characters to search</p>
      )}
    </div>
  );
}

// ── GrantRoleModal ─────────────────────────────────────────────────────────────

interface GrantRoleModalProps {
  open: boolean;
  onClose: () => void;
  userId: string;
  onGranted: () => void;
}

export function GrantRoleModal({ open, onClose, userId, onGranted }: GrantRoleModalProps) {
  const [availableRoles, setAvailableRoles] = useState<AvailableRole[]>([]);
  const [politicians, setPoliticians] = useState<Politician[]>([]);
  const [jurisdictions, setJurisdictions] = useState<JurisdictionHints | null>(null);
  const [rolesLoading, setRolesLoading] = useState(false);
  const [politiciansLoading, setPoliticiansLoading] = useState(false);

  const [selectedSlug, setSelectedSlug] = useState('');
  const [jurisdictionGeoid, setJurisdictionGeoid] = useState('');
  const [selectedPolitician, setSelectedPolitician] = useState<Politician | null>(null);

  const [granting, setGranting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isCampaignManager = selectedSlug === 'campaign_manager';
  const resourceId = selectedPolitician?.id ?? '';

  // Derived feature_scope
  function deriveFeatureScope(): string {
    if (isCampaignManager && resourceId) return 'resource';
    if (!isCampaignManager && jurisdictionGeoid.trim()) return 'jurisdiction';
    return 'platform';
  }

  // Build jurisdiction hint chips from the user's stored geoids
  const jurisdictionChips: { label: string; geoid: string }[] = [];
  if (jurisdictions) {
    if (jurisdictions.county_geo_id) {
      jurisdictionChips.push({
        label: jurisdictions.county_name ? `County: ${jurisdictions.county_name}` : 'County',
        geoid: jurisdictions.county_geo_id,
      });
    }
    if (jurisdictions.congressional_geo_id) {
      jurisdictionChips.push({
        label: jurisdictions.congressional_district_name
          ? `Congress: ${jurisdictions.congressional_district_name}`
          : 'Congressional',
        geoid: jurisdictions.congressional_geo_id,
      });
    }
    if (jurisdictions.state_senate_geo_id) {
      jurisdictionChips.push({
        label: jurisdictions.state_senate_district_name
          ? `State Senate: ${jurisdictions.state_senate_district_name}`
          : 'State Senate',
        geoid: jurisdictions.state_senate_geo_id,
      });
    }
    if (jurisdictions.state_house_geo_id) {
      jurisdictionChips.push({
        label: jurisdictions.state_house_district_name
          ? `State House: ${jurisdictions.state_house_district_name}`
          : 'State House',
        geoid: jurisdictions.state_house_geo_id,
      });
    }
  }

  // Load available roles and jurisdiction hints when modal opens
  useEffect(() => {
    if (!open) return;
    setSelectedSlug('');
    setJurisdictionGeoid('');
    setSelectedPolitician(null);
    setError(null);
    setJurisdictions(null);

    setRolesLoading(true);
    apiFetch<AvailableRolesResponse>('/admin/roles')
      .then((data) => {
        const active = data.roles.filter((r) => r.is_active !== false);
        setAvailableRoles(active);
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load roles'))
      .finally(() => setRolesLoading(false));

    // Fetch jurisdiction hints — non-fatal if user has no connected profile
    apiFetch<JurisdictionHints>(`/admin/accounts/${userId}/jurisdictions`)
      .then((data) => setJurisdictions(data))
      .catch(() => { /* non-fatal */ });
  }, [open, userId]);

  // Load politicians when campaign_manager is selected (once per modal open)
  useEffect(() => {
    if (!open || !isCampaignManager) return;
    if (politicians.length > 0) return;

    setPoliticiansLoading(true);
    apiFetch<PoliticiansResponse>('/admin/compass/politicians')
      .then((data) => setPoliticians(data.politicians))
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load politicians'))
      .finally(() => setPoliticiansLoading(false));
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, isCampaignManager]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedSlug) return;

    const feature_scope = deriveFeatureScope();

    setGranting(true);
    setError(null);
    try {
      await apiFetch('/admin/roles/grant', {
        method: 'POST',
        body: JSON.stringify({
          user_id: userId,
          role_slug: selectedSlug,
          feature_scope,
          jurisdiction_geoid: (!isCampaignManager && jurisdictionGeoid.trim()) ? jurisdictionGeoid.trim() : null,
          resource_id: (isCampaignManager && resourceId) ? resourceId : null,
        }),
      });
      setTimeout(() => {
        onGranted();
      }, 1500);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Grant failed');
      setGranting(false);
    }
  }

  return (
    <Dialog open={open} onClose={() => { if (!granting) onClose(); }} className="relative z-50">
      <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="w-full max-w-md bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6 overflow-y-auto max-h-[90vh]">
          <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Grant Role
          </DialogTitle>

          {error && (
            <div className="mb-4 px-3 py-2 bg-red-50 border border-red-200 text-red-700 text-sm rounded dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Role selector */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Role
              </label>
              {rolesLoading ? (
                <div className="h-9 bg-gray-100 dark:bg-gray-800 rounded animate-pulse" />
              ) : (
                <select
                  value={selectedSlug}
                  onChange={(e) => {
                    setSelectedSlug(e.target.value);
                    setJurisdictionGeoid('');
                    setSelectedPolitician(null);
                    setError(null);
                  }}
                  className="w-full border border-gray-300 dark:border-gray-600 rounded px-3 py-2 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Select a role...</option>
                  {availableRoles.map((role) => (
                    <option key={role.slug} value={role.slug}>
                      {role.name}
                    </option>
                  ))}
                </select>
              )}
            </div>

            {/* Conditional: Politician search (campaign_manager) */}
            {selectedSlug && isCampaignManager && (
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Politician
                </label>
                <PoliticianSearch
                  politicians={politicians}
                  loading={politiciansLoading}
                  value={selectedPolitician}
                  onChange={setSelectedPolitician}
                />
              </div>
            )}

            {/* Conditional: Jurisdiction input (all other roles) */}
            {selectedSlug && !isCampaignManager && (
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Jurisdiction <span className="text-gray-400 font-normal">(optional)</span>
                </label>
                <input
                  type="text"
                  value={jurisdictionGeoid}
                  onChange={(e) => setJurisdictionGeoid(e.target.value)}
                  placeholder="e.g., 06037 — leave blank for platform-wide"
                  className="w-full border border-gray-300 dark:border-gray-600 rounded px-3 py-2 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                {/* Jurisdiction hint chips from user's stored geoids */}
                {jurisdictionChips.length > 0 && (
                  <div className="mt-2">
                    <p className="text-xs text-gray-400 dark:text-gray-500 mb-1.5">User's jurisdictions — click to fill:</p>
                    <div className="flex flex-wrap gap-1.5">
                      {jurisdictionChips.map((chip) => (
                        <button
                          key={chip.geoid}
                          type="button"
                          onClick={() => setJurisdictionGeoid(chip.geoid)}
                          className={`px-2 py-1 rounded text-xs border transition-colors ${
                            jurisdictionGeoid === chip.geoid
                              ? 'bg-blue-600 border-blue-600 text-white'
                              : 'bg-gray-50 border-gray-300 text-gray-700 hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700'
                          }`}
                        >
                          {chip.label}
                          <span className="ml-1 font-mono opacity-60">{chip.geoid}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}
                <p className="mt-1.5 text-xs text-gray-400 dark:text-gray-500">
                  Leave blank for platform-wide access.
                </p>
              </div>
            )}

            {/* Scope preview */}
            {selectedSlug && (
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Scope: <span className="font-medium">{deriveFeatureScope()}</span>
              </p>
            )}

            {/* Actions */}
            <div className="flex gap-3 justify-end pt-2">
              <button
                type="button"
                onClick={onClose}
                disabled={granting}
                className="px-3 py-1.5 text-sm border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-50 dark:hover:bg-gray-800 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={granting || !selectedSlug}
                className="px-4 py-1.5 text-sm bg-blue-600 hover:bg-blue-700 text-white rounded disabled:opacity-50"
              >
                {granting ? 'Granting...' : 'Grant Role'}
              </button>
            </div>
          </form>
        </DialogPanel>
      </div>
    </Dialog>
  );
}
