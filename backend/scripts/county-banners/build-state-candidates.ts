/**
 * The pipeline, end to end, for one state.
 *
 * Writes one JSON file per county as that county completes, so a crash costs one county
 * rather than a state, and a second run resumes rather than re-sweeping.
 *
 * 🔴 `swept` IS THE FIELD THAT KEEPS THIS HONEST. A county that was never looked at and
 * a county with no photographs are different findings, and they produce an identical
 * empty candidate list. Only `swept` separates them. A run that crashes leaves
 * `swept: false` behind, and the next run picks exactly those up again -- which is why
 * 20 empty Nebraska counties could be trusted as genuinely empty rather than skipped.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import fs from 'node:fs';
import path from 'node:path';
import type { CandidateFile, CountyCandidates } from './types.js';
import { listCounties, attachCoordinates, assignToCounties, type QueryFn, type AssignResult } from './locate.js';
import { sweepCategories, countyCategoryRoots } from './sweep.js';
import { filterCandidates } from './filter.js';
import { rankCandidates, PAGE_SIZE } from './rank.js';

/** USPS -> the 2-digit FIPS `geofence_boundaries.state` actually holds. */
export const STATE_FIPS: Record<string, string> = {
  AL: '01', AK: '02', AZ: '04', AR: '05', CA: '06', CO: '08', CT: '09', DE: '10', DC: '11',
  FL: '12', GA: '13', HI: '15', ID: '16', IL: '17', IN: '18', IA: '19', KS: '20', KY: '21',
  LA: '22', ME: '23', MD: '24', MA: '25', MI: '26', MN: '27', MS: '28', MO: '29', MT: '30',
  NE: '31', NV: '32', NH: '33', NJ: '34', NM: '35', NY: '36', NC: '37', ND: '38', OH: '39',
  OK: '40', OR: '41', PA: '42', RI: '44', SC: '45', SD: '46', TN: '47', TX: '48', UT: '49',
  VT: '50', VA: '51', WA: '53', WV: '54', WI: '55', WY: '56', PR: '72',
};

/** The state's full name, for Commons category titles. */
const STATE_NAME: Record<string, string> = {
  AL: 'Alabama', AK: 'Alaska', AZ: 'Arizona', AR: 'Arkansas', CA: 'California', CO: 'Colorado',
  CT: 'Connecticut', DE: 'Delaware', DC: 'Washington, D.C.', FL: 'Florida', GA: 'Georgia',
  HI: 'Hawaii', ID: 'Idaho', IL: 'Illinois', IN: 'Indiana', IA: 'Iowa', KS: 'Kansas',
  KY: 'Kentucky', LA: 'Louisiana', ME: 'Maine', MD: 'Maryland', MA: 'Massachusetts',
  MI: 'Michigan', MN: 'Minnesota', MS: 'Mississippi', MO: 'Missouri', MT: 'Montana',
  NE: 'Nebraska', NV: 'Nevada', NH: 'New Hampshire', NJ: 'New Jersey', NM: 'New Mexico',
  NY: 'New York', NC: 'North Carolina', ND: 'North Dakota', OH: 'Ohio', OK: 'Oklahoma',
  OR: 'Oregon', PA: 'Pennsylvania', RI: 'Rhode Island', SC: 'South Carolina',
  SD: 'South Dakota', TN: 'Tennessee', TX: 'Texas', UT: 'Utah', VT: 'Vermont',
  VA: 'Virginia', WA: 'Washington', WV: 'West Virginia', WI: 'Wisconsin', WY: 'Wyoming',
  PR: 'Puerto Rico',
};

export interface BuildDeps {
  query: QueryFn;
  sweep?: (roots: string[]) => Promise<CandidateFile[]>;
  attach?: (files: CandidateFile[]) => Promise<CandidateFile[]>;
  assign?: (files: CandidateFile[], stateFips: string, query: QueryFn) => Promise<AssignResult>;
}

/** What is written to disk: the operator's page plus everything behind it. */
interface CountyFile extends CountyCandidates {
  allCandidates: CandidateFile[];
  unlocated: number;
  outside: number;
}

export async function buildStateCandidates(stateUsps: string, outDir: string, deps: BuildDeps): Promise<CountyCandidates[]> {
  const usps = stateUsps.toUpperCase();
  const stateFips = STATE_FIPS[usps];
  if (!stateFips) throw new Error(`Unknown state code '${stateUsps}'. Known: ${Object.keys(STATE_FIPS).join(', ')}`);
  const stateName = STATE_NAME[usps];

  const sweep = deps.sweep ?? ((roots: string[]) => sweepCategories(roots));
  const attach = deps.attach ?? ((f: CandidateFile[]) => attachCoordinates(f));
  const assign = deps.assign ?? assignToCounties;

  fs.mkdirSync(outDir, { recursive: true });
  const counties = await listCounties(stateFips, deps.query);
  const rows: CountyCandidates[] = [];

  for (const county of counties) {
    const file = path.join(outDir, `${county.geoid}.json`);
    // Resume: a county already swept is left alone. One left swept:false by a crashed
    // run is NOT -- that is the whole reason the flag exists.
    if (fs.existsSync(file)) {
      const prev = JSON.parse(fs.readFileSync(file, 'utf8')) as CountyFile;
      if (prev.swept) { rows.push(prev); continue; }
    }

    const row: CountyFile = {
      geoid: county.geoid, name: county.name, swept: false, candidates: [],
      rejected: {}, allCandidates: [], unlocated: 0, outside: 0,
    };

    try {
      // No county-seat source exists yet, so the seat is null and the seat's photographs
      // are reached through the county category's subcategories instead.
      const swept = await sweep(countyCategoryRoots(county.name, stateName, null));
      const withCoords = await attach(swept);
      const placed = await assign(withCoords, stateFips, deps.query);
      const mine = placed.located.get(county.geoid) ?? [];
      const { kept, rejected } = filterCandidates(mine);
      const ranked = rankCandidates(kept);

      row.allCandidates = ranked;
      row.candidates = ranked.slice(0, PAGE_SIZE);
      row.rejected = rejected;
      row.unlocated = placed.unlocated.length;
      row.outside = placed.outside.length;
      row.swept = true;
    } catch (e) {
      // swept stays false. The row is still written, so the next run finds it and
      // retries exactly this county rather than the whole state.
      row.rejected = { error: 1 };
      process.stderr.write(`  ! ${county.geoid} ${county.name}: ${(e as Error).message}\n`);
    }

    fs.writeFileSync(file, JSON.stringify(row, null, 1));
    rows.push(row);
  }
  return rows;
}
