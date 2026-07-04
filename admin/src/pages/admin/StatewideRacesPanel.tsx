/**
 * StatewideRacesPanel — net-new panel (ELEC-02) shown alongside the county
 * choropleth when a state is selected in elections mode. Lists the state's
 * statewide/legislative races (the D-01 number that colors the map fill),
 * so a click surfaces both the race list AND the existing county drill-down
 * together (D-02). Data arrives pre-fetched on `StateElection` — no new fetch.
 */
import type { StateElection } from './coverageTypes';

interface Props {
  stateElection: StateElection | null;
}

export function StatewideRacesPanel({ stateElection }: Props) {
  if (!stateElection) return null;

  const { statewideRaces, countyCoverage } = stateElection;

  return (
    <div className="overflow-hidden rounded-lg bg-white shadow dark:bg-gray-900">
      <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-gray-800">
        <h2 className="text-sm font-semibold text-gray-900 dark:text-white">
          Statewide &amp; legislative races <span className="font-normal text-gray-400">({statewideRaces.length})</span>
        </h2>
        <span className="text-xs text-gray-400">
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
              <th className="px-3 py-2 text-right font-medium text-gray-500 dark:text-gray-400">Candidates</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {statewideRaces.length === 0 ? (
              <tr>
                <td colSpan={2} className="px-3 py-6 text-center text-gray-400">
                  No statewide/legislative races for this election.
                </td>
              </tr>
            ) : (
              statewideRaces.map((r) => (
                <tr key={r.race_id} className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
                  <td className="px-3 py-2 font-medium text-gray-900 dark:text-white">{r.position_name}</td>
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
