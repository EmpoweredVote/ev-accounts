/**
 * Human-readable legend + labels for the elections-mode race tiers (D-01/D-04).
 * A race's tier is set by its WEAKEST candidate, so "fully researched" means
 * every candidate in the race clears the bar — one blank candidate drags the
 * whole race down a tier. TIER_INFO is shared with StatewideRacesPanel so the
 * map legend and the race table can never describe the same tier differently.
 */

export const TIER_INFO: Record<0 | 1 | 2 | 3, { label: string; desc: string; chip: string }> = {
  3: {
    label: 'Fully researched',
    desc: 'every candidate has stances + donor data',
    chip: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-400',
  },
  2: {
    label: 'Partly researched',
    desc: 'every candidate has stances or donor data',
    chip: 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400',
  },
  1: {
    label: 'Candidates only',
    desc: 'candidates loaded, research incomplete',
    chip: 'bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-400',
  },
  0: {
    label: 'No candidates',
    desc: 'race exists, nobody loaded yet',
    chip: 'bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-600',
  },
};

/** Rendered BELOW the map (never as an overlay — it covered the map). */
export function ElectionsTierLegend() {
  return (
    <div className="rounded-md border border-gray-200 bg-gray-50 px-4 py-3 text-sm leading-relaxed text-gray-500 dark:border-gray-700 dark:bg-gray-800/60 dark:text-gray-400">
      <div className="mb-1.5 font-medium text-gray-700 dark:text-gray-200">
        Race research depth — a race is only as done as its least-researched candidate
      </div>
      <div className="flex flex-wrap items-baseline gap-x-6 gap-y-1.5">
        {([3, 2, 1, 0] as const).map((t) => (
          <span key={t} className="inline-flex items-baseline gap-2" title={TIER_INFO[t].desc}>
            <span className={`inline-block w-9 shrink-0 rounded px-1.5 py-0.5 text-center text-xs font-semibold ${TIER_INFO[t].chip}`}>T{t}</span>
            <span className="whitespace-nowrap font-medium text-gray-700 dark:text-gray-200">{TIER_INFO[t].label}</span>
            <span className="hidden whitespace-nowrap lg:inline">— {TIER_INFO[t].desc}</span>
          </span>
        ))}
      </div>
    </div>
  );
}
