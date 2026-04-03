import { useEffect, useState } from 'react';
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
  const [rolesLoading, setRolesLoading] = useState(false);
  const [politiciansLoading, setPoliticiansLoading] = useState(false);

  const [selectedSlug, setSelectedSlug] = useState('');
  const [jurisdictionGeoid, setJurisdictionGeoid] = useState('');
  const [resourceId, setResourceId] = useState('');

  const [granting, setGranting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isCampaignManager = selectedSlug === 'campaign_manager';

  // Derived feature_scope
  function deriveFeatureScope(): string {
    if (isCampaignManager && resourceId) return 'resource';
    if (!isCampaignManager && jurisdictionGeoid.trim()) return 'jurisdiction';
    return 'platform';
  }

  // Load available roles when modal opens
  useEffect(() => {
    if (!open) return;
    setSelectedSlug('');
    setJurisdictionGeoid('');
    setResourceId('');
    setError(null);

    setRolesLoading(true);
    apiFetch<AvailableRolesResponse>('/admin/roles')
      .then((data) => {
        // Filter to active roles only (if is_active field present)
        const active = data.roles.filter((r) => r.is_active !== false);
        setAvailableRoles(active);
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load roles'))
      .finally(() => setRolesLoading(false));
  }, [open]);

  // Load politicians when campaign_manager is selected
  useEffect(() => {
    if (!open || !isCampaignManager) return;
    if (politicians.length > 0) return; // already loaded

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
      // Brief success indication then close
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
        <DialogPanel className="w-full max-w-md bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6">
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
                    setResourceId('');
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

            {/* Conditional: Politician picker (campaign_manager) */}
            {selectedSlug && isCampaignManager && (
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Politician
                </label>
                {politiciansLoading ? (
                  <div className="h-9 bg-gray-100 dark:bg-gray-800 rounded animate-pulse" />
                ) : (
                  <select
                    value={resourceId}
                    onChange={(e) => setResourceId(e.target.value)}
                    className="w-full border border-gray-300 dark:border-gray-600 rounded px-3 py-2 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Platform-wide (no specific politician)</option>
                    {politicians.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.full_name ?? `${p.preferred_name ?? p.first_name} ${p.last_name}`}
                        {p.office_title ? ` — ${p.office_title}` : ''}
                      </option>
                    ))}
                  </select>
                )}
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
                  placeholder="e.g., 06037 (optional)"
                  className="w-full border border-gray-300 dark:border-gray-600 rounded px-3 py-2 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <p className="mt-1 text-xs text-gray-400 dark:text-gray-500">
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
