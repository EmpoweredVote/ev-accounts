/**
 * CoveragePage — unified coverage view. The map (top) is the selector for the
 * table (below); the WHOLE PAGE scrolls (no inner scroll box). Three lenses:
 *   Local    — the YAML-tracked local-government composite (map + tracker table)
 *   Federal  — federal + state offices, live for ALL 56 states (map + roster)
 *   Elections— race coverage for each state's nearest upcoming election
 * Every state is clickable in every lens; untracked states drill into their
 * federal/state roster instead of a local tracker they don't have.
 */
import { useEffect, useMemo, useState, useCallback } from 'react';
import { apiFetch } from '../../lib/api';
import { CoverageMap } from './CoverageMap';
import { CoverageTable } from './CoverageTable';
import { StatewideRacesPanel } from './StatewideRacesPanel';
import { FederalDelegationPanel } from './FederalDelegationPanel';
import type { StateScore, CountyScore, StateElection, CountyElection, Metric } from './coverageTypes';

const METRIC_LABEL: Record<Metric, string> = {
  completeness: 'Local',
  federal: 'Federal & state',
  elections: 'Elections',
};

export function CoveragePage() {
  const [metric, setMetric] = useState<Metric>('completeness');
  // completeness data
  const [states, setStates] = useState<StateScore[]>([]);
  const [counties, setCounties] = useState<CountyScore[]>([]);
  // elections data
  const [elecStates, setElecStates] = useState<StateElection[]>([]);
  const [elecCounties, setElecCounties] = useState<CountyElection[]>([]);
  const [elecDate, setElecDate] = useState<{ date: string; type: string } | null>(null);
  // selection
  const [selected, setSelected] = useState<{ fips: string; name: string; code?: string } | null>(null);
  const [selectedCounty, setSelectedCounty] = useState<CountyScore | null>(null);
  // misc
  const [error, setError] = useState<string | null>(null);
  const [statesLoading, setStatesLoading] = useState(true);
  const [loading, setLoading] = useState(false);

  // US completeness scores (uncached — can take a few seconds on first load)
  useEffect(() => {
    setStatesLoading(true);
    apiFetch<{ states: StateScore[] }>(`/admin/coverage/map?level=state`)
      .then((res) => setStates(res.states))
      .catch((err) => setError(err.message))
      .finally(() => setStatesLoading(false));
  }, []);

  // US elections scores — lazy, first time elections mode is toggled on
  useEffect(() => {
    if (metric !== 'elections' || elecStates.length > 0) return;
    setStatesLoading(true);
    apiFetch<{ states: StateElection[] }>(`/admin/coverage/map?metric=elections&level=state`)
      .then((res) => setElecStates(res.states))
      .catch((err) => setError(err.message))
      .finally(() => setStatesLoading(false));
  }, [metric, elecStates.length]);

  const stateByFips = useMemo(() => new Map(states.map((s) => [s.fips, s])), [states]);
  const countyByFips = useMemo(() => new Map(counties.map((c) => [c.fips, c])), [counties]);
  const elecStatesByFips = useMemo(() => new Map(elecStates.map((s) => [s.fips, s])), [elecStates]);
  const elecCountiesByFips = useMemo(() => new Map(elecCounties.map((c) => [c.fips, c])), [elecCounties]);

  const loadCounties = useCallback((code: string) => {
    setLoading(true);
    if (metric === 'completeness') {
      apiFetch<{ counties: CountyScore[] }>(`/admin/coverage/map?level=county&state=${code}`)
        .then((res) => setCounties(res.counties))
        .catch((err) => setError(err.message))
        .finally(() => setLoading(false));
    } else {
      apiFetch<{ election_date: string | null; election_type: string | null; counties: CountyElection[] }>(
        `/admin/coverage/map?metric=elections&level=county&state=${code}`,
      )
        .then((res) => {
          setElecCounties(res.counties);
          setElecDate(res.election_date ? { date: res.election_date, type: res.election_type ?? '' } : null);
        })
        .catch((err) => setError(err.message))
        .finally(() => setLoading(false));
    }
  }, [metric]);

  const onSelectState = useCallback((fips: string, name: string) => {
    const code = metric === 'completeness' || metric === 'federal'
      ? stateByFips.get(fips)?.code
      : elecStatesByFips.get(fips)?.code ?? stateByFips.get(fips)?.code;
    setSelected({ fips, name, code });
    setSelectedCounty(null);
    if (!code) { setCounties([]); setElecCounties([]); return; }
    // Federal lens has no county drill-down; untracked states have no county
    // scores to fetch (no YAML) — their drill-down is the federal roster.
    if (metric === 'federal') return;
    if (metric === 'completeness' && stateByFips.get(fips)?.tracked === false) { setCounties([]); return; }
    loadCounties(code);
  }, [metric, stateByFips, elecStatesByFips, loadCounties]);

  // Re-fetch the selected state's counties when the metric flips. Keyed on
  // [metric] only and intentionally omitting loadCounties/selected: loadCounties
  // already closes over the current metric, and onSelectState handles the click
  // path — adding them would double-fetch on every state click.
  useEffect(() => {
    if (metric === 'federal') return; // no county layer in the federal lens
    if (metric === 'completeness' && selected && stateByFips.get(selected.fips)?.tracked === false) return;
    if (selected?.code) loadCounties(selected.code);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [metric]);

  const onSelectCounty = useCallback((fips: string) => {
    if (metric === 'completeness') setSelectedCounty(countyByFips.get(fips) ?? null);
  }, [metric, countyByFips]);

  const selectedUntracked = selected != null && stateByFips.get(selected.fips)?.tracked === false;

  const backToUS = useCallback(() => {
    setSelected(null);
    setCounties([]);
    setSelectedCounty(null);
    setElecCounties([]);
    setElecDate(null);
  }, []);

  return (
    <div>
      {/* Header + metric toggle + breadcrumb */}
      <div className="mb-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Coverage</h1>
          <div className="inline-flex overflow-hidden rounded-md border border-gray-300 text-xs dark:border-gray-600">
            {(['completeness', 'federal', 'elections'] as Metric[]).map((m) => (
              <button
                key={m}
                onClick={() => { setMetric(m); setSelectedCounty(null); }}
                className={`px-2.5 py-1 font-medium ${metric === m ? 'bg-ev-teal text-white dark:bg-ev-teal-light dark:text-gray-900' : 'text-gray-600 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'}`}
              >
                {METRIC_LABEL[m]}
              </button>
            ))}
          </div>
        </div>
        <nav className="text-sm text-gray-500 dark:text-gray-400">
          <button onClick={backToUS} className="hover:text-ev-teal dark:hover:text-ev-teal-light">United States</button>
          {selected && (
            <>
              <span className="px-1.5">›</span>
              <button onClick={() => setSelectedCounty(null)} className="font-medium text-gray-900 hover:text-ev-teal dark:text-white dark:hover:text-ev-teal-light">{selected.name}</button>
            </>
          )}
          {selectedCounty && (
            <>
              <span className="px-1.5">›</span>
              <span className="font-medium text-gray-900 dark:text-white">{selectedCounty.name}</span>
            </>
          )}
        </nav>
      </div>

      {error && (
        <div className="mb-4 rounded border border-red-200 bg-red-50 p-4 text-sm text-red-700 dark:border-red-800/60 dark:bg-red-950/40 dark:text-red-400">
          {error}
        </div>
      )}

      {/* MAP (top) */}
      <div className="relative mb-6">
        {(statesLoading || loading) && (
          <div className="absolute inset-0 z-10 flex flex-col items-center justify-center gap-3 bg-white/70 backdrop-blur-sm dark:bg-gray-900/70">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-gray-300 border-t-ev-teal dark:border-gray-600 dark:border-t-ev-teal-light" />
            <p className="text-sm font-medium text-gray-600 dark:text-gray-300">{statesLoading ? 'Loading coverage data…' : 'Loading counties…'}</p>
            {statesLoading && <p className="text-xs text-gray-400">First load aggregates every tracked state — this can take a few seconds.</p>}
          </div>
        )}
        <CoverageMap
          metric={metric}
          stateByFips={stateByFips}
          countyByFips={countyByFips}
          elecStatesByFips={elecStatesByFips}
          elecCountiesByFips={elecCountiesByFips}
          elecDate={elecDate}
          selected={selected}
          selectedCountyFips={selectedCounty?.fips ?? null}
          onSelectState={onSelectState}
          onSelectCounty={onSelectCounty}
        />
      </div>

      {/* STATEWIDE RACES PANEL (below map) — elections mode, only once a state is selected;
          renders alongside the county view (map's own drill-down), never in place of it (D-02) */}
      {metric === 'elections' && selected && (
        <StatewideRacesPanel stateElection={elecStatesByFips.get(selected.fips) ?? null} loading={statesLoading} />
      )}

      {/* FEDERAL ROSTER (below map) — the federal lens drill-down for ANY state */}
      {metric === 'federal' && selected?.code && (
        <FederalDelegationPanel stateCode={selected.code} stateName={selected.name} />
      )}
      {metric === 'federal' && !selected && (
        <CoverageTable
          states={states}
          statesLoading={statesLoading}
          state={null}
          focusCounty={null}
          onClearCounty={() => setSelectedCounty(null)}
          onPickState={onSelectState}
        />
      )}

      {/* TABLE (below) — local (completeness) mode; whole page scrolls (no inner scroll box).
          Untracked states have no YAML tracker — show their federal/state roster instead of
          silently falling back to the first tracked state's file (the old behavior). */}
      {metric === 'completeness' && (
        selected?.code && selectedUntracked ? (
          <div className="space-y-4">
            <div className="rounded-lg border border-gray-200 bg-white p-4 text-sm text-gray-500 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-400">
              <span className="font-medium text-gray-700 dark:text-gray-200">{selected.name}</span> has no local
              coverage file yet — local government isn't tracked. Add{' '}
              <code className="rounded bg-gray-100 px-1 dark:bg-gray-800">data/coverage/{selected.code}.yaml</code> to
              start. Its federal &amp; state officials are covered below.
            </div>
            <FederalDelegationPanel stateCode={selected.code} stateName={selected.name} />
          </div>
        ) : (
          <CoverageTable
            states={states}
            statesLoading={statesLoading}
            state={selected?.code ?? null}
            focusCounty={selectedCounty}
            onClearCounty={() => setSelectedCounty(null)}
            onPickState={onSelectState}
          />
        )
      )}
    </div>
  );
}
