/**
 * Hover cards for the completeness map. They convey WHAT is covered, not just a
 * %: breadth bars (how many child units started) + a one-line per-axis summary
 * (state and county both show Rosters/Stances/Photos[/Donors] percentages).
 * The federal lens gets its own card; untracked states hovering in local mode
 * show the federal summary too — grey no longer means "we have nothing".
 */
import { Chip, type Tristate } from './coverageCells';
import type { FederalStats } from './coverageTypes';

export interface StateHover {
  name: string;
  tracked: boolean;
  federal: FederalStats;
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

/** One-line federal delegation summary — shared by both state cards. */
function FederalSummaryLine({ f }: { f: FederalStats }) {
  const parts = [
    f.senate.expected > 0 ? `Senate ${f.senate.filled}/${f.senate.expected}` : null,
    f.house.expected > 0 ? `House ${f.house.districtsCovered}/${f.house.expected}` : null,
    f.governor.expected > 0 ? `Gov ${f.governor.filled > 0 ? '✓' : '—'}` : null,
  ].filter(Boolean);
  return <>{parts.join(' · ')}</>;
}

export function StateHoverCard({ s }: { s: StateHover }) {
  // Untracked locally — say what IS covered (the federal tier) instead of
  // presenting grey as "nothing".
  if (!s.tracked) {
    return (
      <div className="w-64 rounded-lg border border-gray-200 bg-white p-3 shadow-lg dark:border-gray-700 dark:bg-gray-900">
        <div className="mb-1 text-sm font-semibold text-gray-900 dark:text-white">{s.name}</div>
        <div className="mb-2 text-xs text-gray-500 dark:text-gray-400">No local coverage file yet</div>
        <div className="text-[11px] text-gray-600 dark:text-gray-300">
          <FederalSummaryLine f={s.federal} />
        </div>
        <div className="mt-2 border-t border-gray-100 pt-1.5 text-[11px] text-gray-500 dark:border-gray-800 dark:text-gray-400">
          Federal &amp; state coverage {s.federal.score}% — switch to the Federal lens
        </div>
      </div>
    );
  }
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
      <div className="mt-1 text-[11px] text-gray-500 dark:text-gray-400">
        Federal: <FederalSummaryLine f={s.federal} />
      </div>
    </div>
  );
}

/** Federal-lens hover card — the delegation + state offices at a glance. */
export function FederalHoverCard({ name, f }: { name: string; f: FederalStats }) {
  const delegationTotal = f.senate.filled + f.house.filled;
  const pct = (part: number) => (delegationTotal > 0 ? Math.round((part / delegationTotal) * 100) : 0);
  const stancesPct = pct(f.senate.researched + f.house.researched);
  const photosPct = pct(f.senate.withPhoto + f.house.withPhoto);
  const legKnown = f.stateLeg.districtsTotal > 0;
  return (
    <div className="w-64 rounded-lg border border-gray-200 bg-white p-3 shadow-lg dark:border-gray-700 dark:bg-gray-900">
      <div className="mb-1 flex items-baseline justify-between">
        <span className="text-sm font-semibold text-gray-900 dark:text-white">{name}</span>
        <span className="tabular-nums text-xs text-gray-500 dark:text-gray-400">{f.score}%</span>
      </div>
      <ul className="space-y-0.5 text-[11px] text-gray-600 dark:text-gray-300">
        {f.senate.expected > 0 && <li>U.S. Senate {f.senate.filled}/{f.senate.expected}</li>}
        <li>U.S. House {f.house.districtsCovered}/{f.house.expected} districts</li>
        {f.governor.expected > 0 && <li>Governor {f.governor.filled > 0 ? '✓' : 'not loaded'}</li>}
        {f.statewideExecs > 0 && <li>Statewide officials {f.statewideExecs}</li>}
        <li>
          Legislature{' '}
          {legKnown
            ? `${f.stateLeg.districtsCovered}/${f.stateLeg.districtsTotal} districts`
            : f.stateLeg.members > 0
              ? `${f.stateLeg.members} members`
              : 'not loaded'}
        </li>
        {f.candidatesTracked > 0 && <li>Candidates tracked {f.candidatesTracked}</li>}
      </ul>
      <div className="mt-2 border-t border-gray-100 pt-1.5 text-[11px] text-gray-500 dark:border-gray-800 dark:text-gray-400">
        Delegation stances {stancesPct}% · Photos {photosPct}%
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
