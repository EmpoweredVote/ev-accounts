import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { apiFetch } from '../../lib/api';

interface ContributorGrant {
  role_slug: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
  resource_display_name: string | null;
  granted_at: string;
  granted_by_display_name: string | null;
}

const ROLE_DISPLAY_NAMES: Record<string, string> = {
  compass_stance_editor: 'Compass Editor',
  campaign_manager: 'Candidate Coordinator',
  essentials_data_editor: 'Essentials Editor',
};

const ROLE_ROUTES: Record<string, string> = {
  compass_stance_editor: '/contributor/compass-editor',
  campaign_manager: '/contributor/campaign-manager',
  essentials_data_editor: '/contributor/essentials-editor',
};

const ROLE_DESCRIPTIONS: Record<string, string> = {
  compass_stance_editor: 'Record and maintain politician stances on compass topics.',
  campaign_manager: 'Manage campaign data for your assigned candidate.',
  essentials_data_editor: 'Keep candidate profiles and biographical info up to date.',
};

const ROLE_ACCENT: Record<string, string> = {
  compass_stance_editor: 'border-ev-yellow/40 bg-ev-yellow/5',
  campaign_manager: 'border-ev-red/30 bg-ev-red/5',
  essentials_data_editor: 'border-ev-teal/30 bg-ev-teal/5',
};

const ROLE_BADGE: Record<string, string> = {
  compass_stance_editor: 'bg-ev-yellow/20 text-ev-black dark:text-ev-yellow',
  campaign_manager: 'bg-ev-red/15 text-ev-red',
  essentials_data_editor: 'bg-ev-teal/15 text-ev-teal',
};

const ROLE_CTA_STYLE: Record<string, string> = {
  compass_stance_editor: 'bg-ev-yellow text-ev-black hover:bg-ev-yellow/90',
  campaign_manager: 'bg-ev-red text-white hover:bg-ev-red/90',
  essentials_data_editor: 'bg-ev-teal text-white hover:bg-ev-teal/90',
};

function getScopeLabel(grant: ContributorGrant): string {
  if (grant.resource_id) return grant.resource_display_name ?? 'Single Politician';
  if (grant.jurisdiction_geoid) return grant.jurisdiction_geoid;
  if (grant.feature_scope === 'platform') return 'Unrestricted';
  return grant.feature_scope;
}

export default function ContributorDashboard() {
  const navigate = useNavigate();
  const [grants, setGrants] = useState<ContributorGrant[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiFetch<ContributorGrant[]>('/contributor/me')
      .then(setGrants)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="max-w-lg mx-auto px-4 py-6 space-y-4">

      {/* Tab bar */}
      <nav className="flex gap-6 border-b border-gray-200 dark:border-gray-800 mb-6">
        <Link
          to="/"
          className="pb-2 border-b-2 border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 font-medium text-sm"
        >
          Profile
        </Link>
        <span className="pb-2 border-b-2 border-ev-teal text-ev-teal font-medium text-sm">
          Contributor
        </span>
      </nav>

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
        </div>
      ) : grants.length === 0 ? (
        /* Locked / empty state */
        <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-6 space-y-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-ev-teal/10 flex items-center justify-center flex-shrink-0">
              <svg className="w-5 h-5 text-ev-teal" fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10" />
              </svg>
            </div>
            <div>
              <h2 className="text-lg font-bold text-ev-black dark:text-white">Become a Contributor</h2>
              <p className="text-xs text-gray-400 mt-0.5">Help power civic transparency</p>
            </div>
          </div>

          <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
            Contributors are trusted members who help keep Empowered Vote's civic data accurate and current. There are three ways to contribute:
          </p>

          <div className="space-y-3">
            <div className="flex items-start gap-3 p-3 rounded-xl bg-ev-yellow/5 border border-ev-yellow/20">
              <div className="w-1.5 h-1.5 rounded-full bg-ev-yellow mt-2 flex-shrink-0" />
              <div>
                <p className="text-sm font-semibold text-ev-black dark:text-white">Essentials Editors</p>
                <p className="text-xs text-gray-500 mt-0.5">Maintain accurate candidate profiles and biographical information.</p>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 rounded-xl bg-ev-teal/5 border border-ev-teal/20">
              <div className="w-1.5 h-1.5 rounded-full bg-ev-teal mt-2 flex-shrink-0" />
              <div>
                <p className="text-sm font-semibold text-ev-black dark:text-white">Compass Editors</p>
                <p className="text-xs text-gray-500 mt-0.5">Record and verify politician stances on compass topics.</p>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 rounded-xl bg-ev-red/5 border border-ev-red/20">
              <div className="w-1.5 h-1.5 rounded-full bg-ev-red mt-2 flex-shrink-0" />
              <div>
                <p className="text-sm font-semibold text-ev-black dark:text-white">Candidate Coordinators</p>
                <p className="text-xs text-gray-500 mt-0.5">Manage campaign data for specific candidates and races.</p>
              </div>
            </div>
          </div>

        </div>
      ) : (
        /* Active grants */
        <div className="space-y-4">
          <div>
            <h2 className="text-lg font-bold text-ev-black dark:text-white">Your Contributor Roles</h2>
            <p className="text-xs text-gray-400 mt-0.5">
              {grants.length === 1 ? '1 active role' : `${grants.length} active roles`}
            </p>
          </div>

          {grants.map((grant, i) => {
            const displayName = ROLE_DISPLAY_NAMES[grant.role_slug] ?? grant.role_slug;
            const route = ROLE_ROUTES[grant.role_slug];
            const description = ROLE_DESCRIPTIONS[grant.role_slug] ?? '';
            const accentClass = ROLE_ACCENT[grant.role_slug] ?? 'border-gray-200 bg-white';
            const badgeClass = ROLE_BADGE[grant.role_slug] ?? 'bg-gray-100 text-gray-600';
            const ctaClass = ROLE_CTA_STYLE[grant.role_slug] ?? 'bg-ev-teal text-white hover:bg-ev-teal/90';
            const scopeLabel = getScopeLabel(grant);
            const grantDate = new Date(grant.granted_at).toLocaleDateString('en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            });

            return (
              <div
                key={`${grant.role_slug}-${i}`}
                className={`rounded-2xl border p-5 space-y-4 ${accentClass} dark:bg-gray-950 dark:border-gray-800`}
              >
                {/* Header row */}
                <div className="flex items-start justify-between gap-3">
                  <div className="space-y-1">
                    <h3 className="text-base font-bold text-ev-black dark:text-white leading-tight">
                      {displayName}
                    </h3>
                    {description && (
                      <p className="text-xs text-gray-500 leading-snug">{description}</p>
                    )}
                  </div>
                  <span className={`text-xs font-semibold px-2.5 py-1 rounded-full whitespace-nowrap flex-shrink-0 ${badgeClass}`}>
                    {displayName}
                  </span>
                </div>

                {/* Metadata */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-0.5">
                    <p className="text-xs text-gray-400 uppercase tracking-wider font-medium">Scope</p>
                    <p className="text-sm font-semibold text-ev-black dark:text-white font-mono">{scopeLabel}</p>
                  </div>
                  <div className="space-y-0.5">
                    <p className="text-xs text-gray-400 uppercase tracking-wider font-medium">Granted</p>
                    <p className="text-sm font-semibold text-ev-black dark:text-white">{grantDate}</p>
                  </div>
                  <div className="col-span-2 space-y-0.5">
                    <p className="text-xs text-gray-400 uppercase tracking-wider font-medium">Granted by</p>
                    <p className="text-sm font-semibold text-ev-black dark:text-white">{grant.granted_by_display_name ?? 'Empowered Vote'}</p>
                  </div>
                </div>

                {/* CTA */}
                {route && (
                  <button
                    onClick={() => navigate(route)}
                    className={`w-full py-2.5 rounded-xl text-sm font-semibold transition-colors ${ctaClass}`}
                  >
                    Open {displayName}
                  </button>
                )}
              </div>
            );
          })}
        </div>
      )}
    </main>
  );
}
