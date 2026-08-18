/**
 * StatewideRacesPanel — net-new panel (ELEC-02) shown alongside the county
 * choropleth when a state is selected in elections mode. Lists the state's
 * statewide/legislative races (the D-01 number that colors the map fill),
 * so a click surfaces both the race list AND the existing county drill-down
 * together (D-02). Data arrives pre-fetched on `StateElection` — no new fetch.
 */
import type { StateElection } from './coverageTypes';
import { TIER_INFO } from './ElectionsTierLegend';

interface Props {
  stateElection: StateElection | null;
  /** True while the elections dataset is still lazy-fetching, so the panel shows a
   *  loading affordance instead of flashing blank (a state can be selected before
   *  `elecStates` resolves, e.g. flipping to elections mode with a state already picked). */
  loading?: boolean;
}

export function StatewideRacesPanel({ stateElection, loading = false }: Props) {
  if (!stateElection) {
    if (!loading) return null;
    return (
      <div className="flex items-center gap-3 rounded-lg bg-white px-4 py-3 shadow dark:bg-gray-900">
        <div className="h-4 w-4 animate-spin rounded-full border-2 border-gray-300 border-t-ev-teal dark:border-gray-600 dark:border-t-ev-teal-light" />
        <p className="text-sm text-gray-500 dark:text-gray-400">Loading statewide races…</p>
      </div>
    );
  }

  const { statewideRaces, countyCoverage, tierCounts } = stateElection;
  const total = statewideRaces.length;

  return (
    <div className="overflow-hidden rounded-lg bg-white shadow dark:bg-gray-900">
      <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-gray-800">
        <h2 className="text-sm font-semibold text-gray-900 dark:text-white">
          Statewide &amp; legislative races <span className="font-normal text-gray-400">({statewideRaces.length})</span>
        </h2>
        <span className="text-xs text-gray-400">
          <span title={TIER_INFO[3].desc}>{TIER_INFO[3].label}: <span className="tabular-nums text-gray-600 dark:text-gray-300">{tierCounts.t3}/{total}</span></span>
          {' · '}<span title={TIER_INFO[2].desc}>{TIER_INFO[2].label.toLowerCase()}: <span className="tabular-nums text-gray-600 dark:text-gray-300">{tierCounts.t2}/{total}</span></span>
          {' · '}<span title={TIER_INFO[1].desc}>{TIER_INFO[1].label.toLowerCase()}: <span className="tabular-nums text-gray-600 dark:text-gray-300">{tierCounts.t1}/{total}</span></span>
          <span className="mx-2 text-gray-300 dark:text-gray-600">|</span>
          County-pinnable:{' '}
          {countyCoverage.status === 'unknown' ? (
            <span className="text-gray-400">N/A — no county-level races</span>
          ) : (
            <span className="tabular-nums text-gray-600 dark:text-gray-300">{countyCoverage.coverage}%</span>
          )}
        </span>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
            <tr>
              <th className="px-3 py-2 text-left font-medium text-gray-500 dark:text-gray-400">Race</th>
              <th className="px-3 py-2 text-right font-medium text-gray-500 dark:text-gray-400">Tier</th>
              <th className="px-3 py-2 text-right font-medium text-gray-500 dark:text-gray-400">Candidates</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {statewideRaces.length === 0 ? (
              <tr>
                <td colSpan={3} className="px-3 py-6 text-center text-gray-400">
                  No statewide/legislative races for this election.
                </td>
              </tr>
            ) : (
              statewideRaces.map((r) => (
                <tr key={r.race_id} className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
                  <td className="px-3 py-2 font-medium text-gray-900 dark:text-white">{r.position_name}</td>
                  <td className="px-3 py-2 text-right">
                    <span
                      className={`inline-block whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium ${TIER_INFO[r.tier].chip}`}
                      title={TIER_INFO[r.tier].desc}
                    >
                      {TIER_INFO[r.tier].label}
                    </span>
                  </td>
                  <td className="px-3 py-2 text-right tabular-nums text-gray-600 dark:text-gray-400">
                    {r.candidate_count}/{r.seats} candidates
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
