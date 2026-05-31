import { useEffect, useState, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { apiFetch } from '../../lib/api';
import { Bool, Chip, Stances, Roster, type Tristate } from './coverageCells';

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

const LEVEL_LABEL: Record<Level, string> = {
  federal: 'Federal Delegation',
  state: 'State Government',
  county: 'Counties',
  local: 'Cities & Municipalities',
  school: 'School Districts',
};
const LEVEL_ORDER: Level[] = ['federal', 'state', 'county', 'local', 'school'];

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

const STATUS_STYLE: Record<CoverageLocation['status'], string> = {
  active: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
  in_progress: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  deferred: 'bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-500',
};

export function CoverageTrackerPage() {
  const [data, setData] = useState<CoverageResponse | null>(null);
  const [state, setState] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchCoverage = useCallback(() => {
    setLoading(true);
    setError(null);
    const qs = state ? `?state=${state}` : '';
    apiFetch<CoverageResponse>(`/admin/coverage${qs}`)
      .then((res) => {
        setData(res);
        if (!state && res.coverage) setState(res.coverage.state.toLowerCase());
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [state]);

  useEffect(() => {
    fetchCoverage();
  }, [fetchCoverage]);

  const cov = data?.coverage ?? null;
  const syncedStale =
    cov?.synced_at != null &&
    Date.now() - Date.parse(cov.synced_at) > (cov.freshness_days ?? 180) * 86_400_000;

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Data Coverage</h1>
          <Link
            to="/admin/coverage/map"
            className="rounded-md border border-gray-300 px-2.5 py-1 text-xs font-medium text-gray-600 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
          >
            Map view →
          </Link>
        </div>
        {data && data.states.length > 0 && (
          <select
            value={state ?? ''}
            onChange={(e) => setState(e.target.value)}
            className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm dark:border-gray-600 dark:bg-gray-900 dark:text-gray-200"
          >
            {data.states.map((s) => (
              <option key={s} value={s}>
                {s.toUpperCase()}
              </option>
            ))}
          </select>
        )}
      </div>

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
