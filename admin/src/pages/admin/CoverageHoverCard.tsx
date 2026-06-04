/**
 * Hover cards for the bivariate completeness map. They convey WHAT is covered,
 * not just a %: breadth bars (how many child units started) + a one-line depth
 * summary (state) or axis chips (county).
 */
import { Chip, type Tristate } from './coverageCells';

export interface StateHover {
  name: string;
  counties_started: number; counties_total: number;
  cities_started: number; cities_total: number;
  schools_started: number; schools_total: number;
  roster_pct: number; stances_pct: number; photo_pct: number;
}

export interface CountyHover {
  name: string;
  populated_count: number; jurisdiction_count: number;
  county_govt_started: boolean;
  cities_started: number; cities_total: number;
  schools_started: number; schools_total: number;
  roster_pct: number; stances_pct: number; photo_pct: number; donors_pct: number; treasury: Tristate;
}

function Bar({ label, started, total }: { label: string; started: number; total: number }) {
  const pct = total > 0 ? (started / total) * 100 : 0;
  return (
    <div className="flex items-center gap-2">
      <span className="w-14 shrink-0 text-[10px] uppercase tracking-wide text-gray-400">{label}</span>
      <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
        <div className="h-full bg-ev-teal dark:bg-ev-teal-light" style={{ width: `${pct}%` }} />
      </div>
      <span className="tabular-nums text-[11px] text-gray-500 dark:text-gray-400">{started}/{total}</span>
    </div>
  );
}

export function StateHoverCard({ s }: { s: StateHover }) {
  return (
    <div className="w-64 rounded-lg border border-gray-200 bg-white p-3 shadow-lg dark:border-gray-700 dark:bg-gray-900">
      <div className="mb-1 text-sm font-semibold text-gray-900 dark:text-white">{s.name}</div>
      <div className="mb-2 text-xs text-gray-500 dark:text-gray-400">
        {s.counties_started}/{s.counties_total} counties started
      </div>
      <div className="space-y-1">
        <Bar label="Counties" started={s.counties_started} total={s.counties_total} />
        <Bar label="Cities" started={s.cities_started} total={s.cities_total} />
        <Bar label="Schools" started={s.schools_started} total={s.schools_total} />
      </div>
      <div className="mt-2 border-t border-gray-100 pt-1.5 text-[11px] text-gray-500 dark:border-gray-800 dark:text-gray-400">
        Rosters {s.roster_pct}% · Stances {s.stances_pct}% · Photos {s.photo_pct}%
      </div>
    </div>
  );
}

export function CountyHoverCard({ c }: { c: CountyHover }) {
  return (
    <div className="w-64 rounded-lg border border-gray-200 bg-white p-3 shadow-lg dark:border-gray-700 dark:bg-gray-900">
      <div className="mb-1 text-sm font-semibold text-gray-900 dark:text-white">{c.name}</div>
      <div className="mb-2 text-xs text-gray-500 dark:text-gray-400">
        {c.populated_count}/{c.jurisdiction_count} populated
      </div>
      <ul className="space-y-0.5 text-[11px] text-gray-600 dark:text-gray-300">
        <li>County govt {c.county_govt_started ? '✓' : 'not started'}</li>
        <li>Cities {c.cities_started}/{c.cities_total}</li>
        <li>School districts {c.schools_started}/{c.schools_total}</li>
      </ul>
      <div className="mt-2 border-t border-gray-100 pt-1.5 text-[11px] text-gray-500 dark:border-gray-800 dark:text-gray-400">
        Rosters {c.roster_pct}% · Stances {c.stances_pct}% · Photos {c.photo_pct}% · Donors {c.donors_pct}%
      </div>
      <div className="mt-1 flex items-center gap-1 text-[10px] text-gray-500 dark:text-gray-400">
        Treasury<Chip value={c.treasury} />
      </div>
    </div>
  );
}
