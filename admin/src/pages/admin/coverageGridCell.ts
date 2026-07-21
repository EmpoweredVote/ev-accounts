export type CellState = 'live' | 'draft' | 'none';
export type RowStatus = 'rankable' | 'near-rankable' | 'solo' | 'none';

const CELL_CLASS: Record<CellState, string> = {
  live: 'bg-green-500',
  draft: 'bg-amber-400',
  none: 'bg-gray-200 dark:bg-gray-700',
};

export function cellClass(state: CellState): string {
  return CELL_CLASS[state];
}

// A question's row status, derived from its candidates' cell states.
// rankable = >=2 live (a real head-to-head); near-rankable = 1 live + >=1 draft (one confirm away);
// solo = at least one live/draft but not rankable/near; none = nothing.
export function rowStatus(states: CellState[]): RowStatus {
  const live = states.filter((s) => s === 'live').length;
  const draft = states.filter((s) => s === 'draft').length;
  if (live >= 2) return 'rankable';
  if (live === 1 && draft >= 1) return 'near-rankable';
  if (live + draft >= 1) return 'solo';
  return 'none';
}
