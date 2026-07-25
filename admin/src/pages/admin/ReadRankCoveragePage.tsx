import { useState } from 'react';
import { apiFetch } from '../../lib/api';
import { cellClass, rowStatus, type CellState } from './coverageGridCell';

interface RaceOption { raceId: string; positionName: string; }
interface Question {
  questionId: string; topicKey: string; questionText: string;
  origin: string; status: string; answeringCandidates: number;
  rankable: boolean; surfaced: boolean;
}
interface Candidate { politicianId: string; fullName: string; }
interface Cell { questionId: string; politicianId: string; state: CellState; }
interface Grid { questions: Question[]; candidates: Candidate[]; cells: Cell[]; }

const ROW_BADGE: Record<string, string> = {
  rankable: 'bg-green-600 text-white',
  'near-rankable': 'bg-amber-500 text-white',
  solo: 'bg-gray-400 text-white',
  none: 'bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
};

export function ReadRankCoveragePage() {
  const [query, setQuery] = useState('');
  const [races, setRaces] = useState<RaceOption[]>([]);
  const [grid, setGrid] = useState<Grid | null>(null);
  const [raceName, setRaceName] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function search(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    try {
      const d = await apiFetch<{ races: RaceOption[] }>(
        `/admin/readrank-coverage/races?q=${encodeURIComponent(query)}`);
      setRaces(d.races);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Search failed');
    }
  }

  async function loadRace(r: RaceOption) {
    setLoading(true); setError(''); setRaceName(r.positionName);
    try {
      setGrid(await apiFetch<Grid>(`/admin/readrank-coverage?race_id=${encodeURIComponent(r.raceId)}`));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load grid');
      setGrid(null);
    } finally {
      setLoading(false);
    }
  }

  const stateOf = (g: Grid, qId: string, pId: string): CellState =>
    g.cells.find((c) => c.questionId === qId && c.politicianId === pId)?.state ?? 'none';

  return (
    <div className="p-6">
      <h1 className="text-2xl font-semibold mb-4">Read &amp; Rank — Coverage Grid</h1>

      <form onSubmit={search} className="flex gap-2 mb-6">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search races (e.g. Senate Texas)"
          className="border rounded px-3 py-2 flex-1 dark:bg-gray-800 dark:border-gray-600"
        />
        <button type="submit" className="px-4 py-2 rounded bg-ev-blue text-white">Search</button>
      </form>

      {races.length > 0 && !grid && (
        <ul className="mb-6 space-y-1">
          {races.map((r) => (
            <li key={r.raceId}>
              <button onClick={() => loadRace(r)} className="text-ev-blue hover:underline">
                {r.positionName}
              </button>
            </li>
          ))}
        </ul>
      )}

      {error && <p className="text-ev-red mb-4">{error}</p>}
      {loading && <p>Loading…</p>}

      {grid && (
        <>
          <div className="flex items-center gap-4 mb-3">
            <h2 className="text-lg font-medium">{raceName}</h2>
            <button onClick={() => { setGrid(null); }} className="text-sm text-ev-blue hover:underline">
              ← pick another race
            </button>
          </div>
          <div className="flex gap-4 mb-3 text-sm">
            <span><span className="inline-block w-3 h-3 rounded-sm bg-green-500 mr-1" />live</span>
            <span><span className="inline-block w-3 h-3 rounded-sm bg-amber-400 mr-1" />draft</span>
            <span><span className="inline-block w-3 h-3 rounded-sm bg-gray-200 dark:bg-gray-700 mr-1" />none</span>
          </div>

          {grid.questions.length === 0 ? (
            <p className="text-gray-500">No confirmed questions for this race yet.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="border-collapse text-sm">
                <thead>
                  <tr>
                    <th className="text-left p-2 sticky left-0 bg-white dark:bg-gray-900">Question</th>
                    <th className="p-2">Status</th>
                    {grid.candidates.map((c) => (
                      <th key={c.politicianId} className="p-2 whitespace-nowrap">{c.fullName}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {grid.questions.map((q) => {
                    const states = grid.candidates.map((c) => stateOf(grid, q.questionId, c.politicianId));
                    const rs = rowStatus(states);
                    return (
                      <tr key={q.questionId} className="border-t dark:border-gray-700">
                        <td className="p-2 max-w-md sticky left-0 bg-white dark:bg-gray-900">
                          <span className="text-xs text-gray-500 mr-1">[{q.topicKey}]</span>{q.questionText}
                        </td>
                        <td className="p-2">
                          <span className={`px-2 py-0.5 rounded text-xs ${ROW_BADGE[rs]}`}>{rs}</span>
                        </td>
                        {grid.candidates.map((c, i) => (
                          <td key={c.politicianId} className="p-2 text-center">
                            <span
                              title={states[i]}
                              className={`inline-block w-5 h-5 rounded-sm ${cellClass(states[i])}`}
                            />
                          </td>
                        ))}
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  );
}
