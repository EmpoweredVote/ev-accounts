/**
 * Legend for the honest completeness gradient: a sage → purple → yellow bar
 * (less complete → 100%) plus the separate grey "not started" chip. Rendered as
 * an overlay inside the map area.
 */
import { completenessColor, NOT_STARTED } from './completenessColor';

// Sample the same gamma'd ramp at a few scores so the bar matches the map exactly.
const STOPS = [0, 10, 25, 45, 70, 100].map((s) => completenessColor(s));

export function CompletenessLegend() {
  return (
    <div className="flex items-center gap-3 text-[11px] leading-none text-gray-500 dark:text-gray-400">
      <div className="flex flex-col gap-1">
        <div className="flex items-center gap-2">
          <span>less complete</span>
          <div className="h-3 w-40 rounded-full" style={{ background: `linear-gradient(to right, ${STOPS.join(', ')})` }} />
          <span className="font-medium text-gray-600 dark:text-gray-300">100%</span>
        </div>
      </div>
      <span className="inline-flex items-center gap-1.5">
        <span className="inline-block h-3 w-3 rounded-sm" style={{ background: NOT_STARTED }} />
        not started
      </span>
    </div>
  );
}
