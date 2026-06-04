import { useEffect, useState, useCallback } from 'react';
import { apiFetch } from '../../lib/api';
import { Bool, Chip, Stances, Roster, ratioToTristate, type Tristate } from './coverageCells';
import { type CountyScore } from './coverageTypes';

// ---------------------------------------------------------------------------
// Types — extracted from the previous CoverageTrackerPage (removed in coverage-bivariate-redesign)
// ---------------------------------------------------------------------------

type Level = 'federal' | 'state' | 'county' | 'local' | 'school';

interface SkipTopicRule {
  topic_key: string;
  reason: string;
  source?: string;
  applies_to: Level[];
}

interface CoverageLocation {
  ocd_id: string;
  name: string;
  level: Level;
  status: 'active' | 'in_progress' | 'deferred';
  expected_seats: number | null;
  geofenced: boolean;
  donors: Tristate;
  candidates: Tristate;
  treasury: Tristate;
  populated: boolean;
  headshots: Tristate;
  stances: { researched: number; total: number };
  last_researched: string | null;
  stale: boolean;
  roster_actual: number;
  roster_complete: boolean;
}

interface UniverseCategory {
  level: 'county' | 'local' | 'school' | 'tribe';
  label: string;
  total: number;
  complete: number;
  started: number;
  remaining: string[];
  reliable: boolean;
}

interface Coverage {
  state: string;
  state_name: string;
  synced_at: string | null;
  freshness_days: number;
  universe: UniverseCategory[];
  rules: { skip_topics: SkipTopicRule[]; notes: string[] };
  locations: CoverageLocation[];
  treasury_orphans: { name: string; level: Level }[];
}

interface CoverageResponse {
  states: string[];
  coverage: Coverage | null;
}

// ---------------------------------------------------------------------------
// Constants — extracted from the previous CoverageTrackerPage (removed in coverage-bivariate-redesign)
// ---------------------------------------------------------------------------

const LEVEL_LABEL: Record<Level, string> = {
  federal: 'Federal Delegation',
  state: 'State Government',
  county: 'Counties',
  local: 'Cities & Municipalities',
  school: 'School Districts',
};
const LEVEL_ORDER: Level[] = ['federal', 'state', 'county', 'local', 'school'];

// ---------------------------------------------------------------------------
// UniverseCard — extracted from the previous CoverageTrackerPage (removed in coverage-bivariate-redesign)
// ---------------------------------------------------------------------------

function UniverseCard({ cat }: { cat: UniverseCategory }) {
  const [open, setOpen] = useState(false);
  const completePct = cat.total > 0 ? (cat.complete / cat.total) * 100 : 0;
  const inProgress = Math.max(0, cat.started - cat.complete);
  const inProgressPct = cat.total > 0 ? (inProgress / cat.total) * 100 : 0;
  const notStarted = cat.total - cat.started;

  // Geofence universe incomplete (more populated than the denominator says exist):
  // show the populated count without a misleading fraction.
  if (!cat.reliable) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
        <div className="flex items-baseline justify-between">
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">{cat.label}</span>
          <span className="tabular-nums text-sm font-semibold text-gray-900 dark:text-white">{cat.started}</span>
        </div>
        <div className="mt-2 text-xs text-amber-600 dark:text-amber-400">
          {cat.complete} complete · universe size unknown (geofences incomplete)
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
      <div className="flex items-baseline justify-between">
        <span className="text-sm font-medium text-gray-700 dark:text-gray-300">{cat.label}</span>
        <span className="tabular-nums text-sm font-semibold text-gray-900 dark:text-white">
          {cat.complete}
          <span className="text-gray-400">/{cat.total}</span>
        </span>
      </div>
      {/* Stacked bar: green = full roster, amber = started-but-incomplete */}
      <div className="mt-2 flex h-2 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
        <div className="h-full bg-emerald-500" style={{ width: `${completePct}%` }} />
        <div className="h-full bg-amber-400" style={{ width: `${inProgressPct}%` }} />
      </div>
      <div className="mt-1.5 flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
        <span>
          {cat.complete} complete
          {inProgress > 0 && <span className="text-amber-600 dark:text-amber-400"> · {inProgress} in progress</span>}
          {' · '}
          {notStarted} not started
        </span>
        {cat.remaining.length > 0 && (
          <button onClick={() => setOpen((o) => !o)} className="hover:text-ev-teal dark:hover:text-ev-teal-light">
            {open ? 'hide' : 'list'}
          </button>
        )}
      </div>
      {open && (
        <div className="mt-2 max-h-44 overflow-auto rounded border border-gray-100 bg-gray-50 p-2 text-xs leading-relaxed text-gray-600 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-400">
          {cat.remaining.join(' · ')}
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// STATUS_STYLE — extracted from the previous CoverageTrackerPage (removed in coverage-bivariate-redesign)
// ---------------------------------------------------------------------------

const STATUS_STYLE: Record<CoverageLocation['status'], string> = {
  active: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  in_progress: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  deferred: 'bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-500',
};

// ---------------------------------------------------------------------------
// County-focus level label map
// ---------------------------------------------------------------------------

const COUNTY_LEVEL_LABEL = { county: 'County govt', local: 'City / Town', school: 'School District' } as const;

// ---------------------------------------------------------------------------
// CoverageTable
// ---------------------------------------------------------------------------

interface Props {
  state: string | null;              // lowercase state code from the map selection; null = none chosen
  focusCounty: CountyScore | null;   // when set, show this county's jurisdiction breakdown instead of the state tracker
  onClearCounty: () => void;
}

export function CoverageTable({ state, focusCounty, onClearCounty }: Props) {
  const [data, setData] = useState<CoverageResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchCoverage = useCallback(() => {
    if (!state) { setData(null); return; }
    setLoading(true); setError(null);
    apiFetch<CoverageResponse>(`/admin/coverage?state=${state}`)
      .then(setData)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [state]);

  useEffect(() => { fetchCoverage(); }, [fetchCoverage]);

  // County focus branch — replaces the state tracker while a county is selected
  if (focusCounty) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
        <div className="flex items-center justify-between border-b border-gray-100 p-4 dark:border-gray-800">
          <div>
            <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{focusCounty.name}</h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {focusCounty.populated_count}/{focusCounty.jurisdiction_count} jurisdictions populated · depth {focusCounty.depth}%
            </p>
          </div>
          <button onClick={onClearCounty} className="text-xs text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">← back to state</button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
              <tr>
                {['Jurisdiction', 'Geofenced', 'Roster', 'Headshots', 'Stances', 'Treasury', 'Donors', 'Score'].map((h) => (
                  <th key={h} className="whitespace-nowrap px-3 py-2 text-left font-medium text-gray-500 dark:text-gray-400">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {focusCounty.jurisdictions.map((j) => (
                <tr key={j.ocd_id} className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
                  <td className="px-3 py-2">
                    <div className="font-medium text-gray-900 dark:text-white">{j.name}</div>
                    <div className="text-[10px] uppercase tracking-wide text-gray-400">{COUNTY_LEVEL_LABEL[j.level]}</div>
                  </td>
                  <td className="px-3 py-2"><Bool value={j.geofenced} /></td>
                  <td className="px-3 py-2"><Roster actual={j.roster_actual} expected={j.expected_seats} complete={j.expected_seats != null && j.roster_actual >= j.expected_seats} /></td>
                  <td className="px-3 py-2"><Chip value={ratioToTristate(j.headshots.withPhoto, j.headshots.total)} /></td>
                  <td className="px-3 py-2"><Stances s={j.stances} /></td>
                  <td className="px-3 py-2"><Chip value={j.treasury} /></td>
                  <td className="px-3 py-2"><Chip value={j.donors} /></td>
                  <td className="px-3 py-2 tabular-nums text-gray-600 dark:text-gray-400">{j.score}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    );
  }

  // No state selected
  if (!state) return <p className="text-sm text-gray-400">Select a state on the map to see its coverage breakdown.</p>;

  const cov = data?.coverage ?? null;
  const syncedStale =
    cov?.synced_at != null &&
    Date.now() - Date.parse(cov.synced_at) > (cov.freshness_days ?? 180) * 86_400_000;

  return (
    <div>
      {error && (
        <div className="mb-4 rounded border border-red-200 bg-red-50 p-4 text-sm text-red-700 dark:border-red-800/60 dark:bg-red-950/40 dark:text-red-400">
          {error}
        </div>
      )}

      {!loading && data && data.states.length === 0 && (
        <div className="rounded-lg border border-gray-200 bg-white p-8 text-center text-gray-400 dark:border-gray-700 dark:bg-gray-900">
          No coverage files found. Add <code>data/coverage/&lt;state&gt;.yaml</code> to the backend.
        </div>
      )}

      {cov && (
        <>
          <div className="mb-4 flex items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
            <span>
              {cov.state_name} — {cov.locations.length} tracked jurisdictions
            </span>
            {cov.synced_at && (
              <span className="inline-flex items-center gap-1.5">
                Synced {cov.synced_at}
                {syncedStale && (
                  <span className="rounded bg-amber-100 px-1.5 py-0.5 text-[10px] font-medium text-amber-700 dark:bg-amber-900/40 dark:text-amber-400">
                    stale — re-run coverage-sync
                  </span>
                )}
              </span>
            )}
          </div>

          {/* State completion progress */}
          {cov.universe.length > 0 && (
            <div className="mb-6">
              <h2 className="mb-2 text-sm font-semibold text-gray-700 dark:text-gray-300">
                Statewide progress — how much of {cov.state_name} is populated
              </h2>
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
                {cov.universe.map((u) => (
                  <UniverseCard key={u.level} cat={u} />
                ))}
              </div>
            </div>
          )}

          {/* Treasury data with no coverage row (money data, no people data) */}
          {cov.treasury_orphans.length > 0 && (
            <div className="mb-6 rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
              <h2 className="mb-1 text-sm font-semibold text-gray-700 dark:text-gray-300">
                Budget data without a coverage row{' '}
                <span className="font-normal text-gray-400">({cov.treasury_orphans.length})</span>
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                These jurisdictions have treasury budgets loaded but no officials tracked yet —{' '}
                {cov.treasury_orphans.map((o) => o.name).join(' · ')}
              </p>
            </div>
          )}

          {/* Jurisdiction rules */}
          {(cov.rules.skip_topics.length > 0 || cov.rules.notes.length > 0) && (
            <div className="mb-6 rounded-lg border border-amber-200 bg-amber-50 p-4 dark:border-amber-900/50 dark:bg-amber-950/20">
              <h2 className="mb-2 text-sm font-semibold text-amber-800 dark:text-amber-300">
                Jurisdiction rules — research-stances auto-skips these topics
              </h2>
              <ul className="space-y-1.5 text-sm">
                {cov.rules.skip_topics.map((r) => (
                  <li key={r.topic_key} className="text-amber-900 dark:text-amber-200">
                    <code className="rounded bg-amber-100 px-1 font-medium dark:bg-amber-900/40">
                      {r.topic_key}
                    </code>{' '}
                    — {r.reason}{' '}
                    <span className="text-amber-700 dark:text-amber-400">
                      ({r.applies_to.join(', ')})
                    </span>
                    {r.source && (
                      <>
                        {' '}
                        <a
                          href={r.source}
                          target="_blank"
                          rel="noreferrer"
                          className="underline hover:text-amber-700"
                        >
                          source
                        </a>
                      </>
                    )}
                  </li>
                ))}
              </ul>
              {cov.rules.notes.length > 0 && (
                <ul className="mt-2 space-y-1 border-t border-amber-200 pt-2 text-xs text-amber-700 dark:border-amber-900/50 dark:text-amber-400">
                  {cov.rules.notes.map((n, i) => (
                    <li key={i}>• {n}</li>
                  ))}
                </ul>
              )}
            </div>
          )}

          {/* Coverage table */}
          <div className="overflow-hidden rounded-lg bg-white shadow dark:bg-gray-900">
            <table className="w-full text-sm">
              <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
                <tr>
                  {['Jurisdiction', 'Geofenced', 'Roster', 'Headshots', 'Stances', 'Donors', 'Candidates', 'Treasury', 'Last Researched'].map(
                    (h, i) => (
                      <th
                        key={h}
                        className={`px-4 py-3 font-medium text-gray-500 dark:text-gray-400 ${i === 0 ? 'text-left' : 'text-left'}`}
                      >
                        {h}
                      </th>
                    ),
                  )}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {loading ? (
                  Array.from({ length: 8 }).map((_, i) => (
                    <tr key={i} className="animate-pulse">
                      <td colSpan={9} className="px-4 py-3">
                        <div className="h-4 w-full rounded bg-gray-200 dark:bg-gray-700" />
                      </td>
                    </tr>
                  ))
                ) : (
                  LEVEL_ORDER.flatMap((level) => {
                    const rows = cov.locations.filter((l) => l.level === level);
                    if (rows.length === 0) return [];
                    return [
                      <tr key={`h-${level}`} className="bg-gray-50/70 dark:bg-gray-800/40">
                        <td
                          colSpan={9}
                          className="px-4 py-1.5 text-xs font-semibold uppercase tracking-wide text-gray-400 dark:text-gray-500"
                        >
                          {LEVEL_LABEL[level]}
                        </td>
                      </tr>,
                      ...rows.map((l, i) => (
                        // ocd_id is NOT unique — a state's federal/state rows (US House,
                        // State Senate, State House, Statewide) all share `.../state:<code>`.
                        // Key on level+name+index so switching states reconciles cleanly
                        // (duplicate keys left stale rows from the previous state on screen).
                        <tr key={`${level}-${l.ocd_id}-${l.name}-${i}`} className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
                          <td className="px-4 py-2.5">
                            <div className="flex items-center gap-2">
                              <span className="font-medium text-gray-900 dark:text-white">{l.name}</span>
                              {l.status !== 'active' && (
                                <span className={`rounded px-1.5 py-0.5 text-[10px] font-medium ${STATUS_STYLE[l.status]}`}>
                                  {l.status.replace('_', ' ')}
                                </span>
                              )}
                            </div>
                          </td>
                          <td className="px-4 py-2.5"><Bool value={l.geofenced} /></td>
                          <td className="px-4 py-2.5"><Roster actual={l.roster_actual} expected={l.expected_seats} complete={l.roster_complete} /></td>
                          <td className="px-4 py-2.5"><Chip value={l.headshots} /></td>
                          <td className="px-4 py-2.5"><Stances s={l.stances} stale={l.stale} /></td>
                          <td className="px-4 py-2.5"><Chip value={l.donors} /></td>
                          <td className="px-4 py-2.5"><Chip value={l.candidates} /></td>
                          <td className="px-4 py-2.5"><Chip value={l.treasury} /></td>
                          <td className="px-4 py-2.5 tabular-nums text-gray-600 dark:text-gray-400">
                            {l.last_researched ?? <span className="text-gray-300 dark:text-gray-600">—</span>}
                          </td>
                        </tr>
                      )),
                    ];
                  })
                )}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
}
