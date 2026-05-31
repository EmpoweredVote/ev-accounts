/**
 * Shared coverage cell components — used by both the tabular CoverageTrackerPage
 * and the CoverageMapPage drill-down panel so the two stay visually in sync.
 */

export type Tristate = 'none' | 'partial' | 'full';

export function Bool({ value }: { value: boolean }) {
  return value ? (
    <span className="inline-flex h-5 w-5 items-center justify-center rounded-full bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-400">
      ✓
    </span>
  ) : (
    <span className="inline-flex h-5 w-5 items-center justify-center rounded-full bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-600">
      ✕
    </span>
  );
}

export function Chip({ value }: { value: Tristate }) {
  const map: Record<Tristate, string> = {
    full: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-400',
    partial: 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400',
    none: 'bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-600',
  };
  return (
    <span className={`inline-block rounded-full px-2 py-0.5 text-xs font-medium capitalize ${map[value]}`}>
      {value}
    </span>
  );
}

export function Stances({ s, stale }: { s: { researched: number; total: number }; stale?: boolean }) {
  const pct = s.total > 0 ? Math.round((s.researched / s.total) * 100) : 0;
  const done = s.total > 0 && s.researched >= s.total;
  const bar = done ? 'bg-emerald-500' : s.researched > 0 ? 'bg-amber-500' : 'bg-gray-300 dark:bg-gray-700';
  return (
    <div className="flex items-center gap-2">
      <div className="h-1.5 w-20 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
        <div className={`h-full ${bar}`} style={{ width: `${pct}%` }} />
      </div>
      <span className="tabular-nums text-xs text-gray-600 dark:text-gray-400">
        {s.researched}/{s.total}
      </span>
      {stale && (
        <span className="rounded bg-amber-100 px-1 text-[10px] font-medium text-amber-700 dark:bg-amber-900/40 dark:text-amber-400">
          stale
        </span>
      )}
    </div>
  );
}

export function Roster({ actual, expected, complete }: { actual: number; expected: number | null; complete: boolean }) {
  const cls = complete
    ? 'text-emerald-700 dark:text-emerald-400'
    : actual > 0
      ? 'text-amber-700 dark:text-amber-400'
      : 'text-gray-400 dark:text-gray-600';
  return (
    <span className={`tabular-nums text-xs font-medium ${cls}`}>
      {actual}
      <span className="text-gray-400">/{expected ?? '—'}</span>
      {complete && ' ✓'}
    </span>
  );
}

/** Ratio (0..1) → tristate, for headshot fractions coming from the map API. */
export function ratioToTristate(part: number, total: number): Tristate {
  if (total === 0 || part === 0) return 'none';
  return part >= total ? 'full' : 'partial';
}
