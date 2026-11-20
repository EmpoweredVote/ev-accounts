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
 * 🔴 AND `swept` IS ONLY HONEST IF PARTIAL FAILURES REACH IT. `sweepCategories` keeps
 * going past a category that errors, which is right -- one bad category must not cost
 * the county -- but a caller that discards those errors publishes "I looked and there
 * was nothing" after a WAF challenge ate half the sweep. So errors are collected and a
 * county that had any is NOT marked swept.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import fs from 'node:fs';
import path from 'node:path';
import type { CandidateFile, CountyCandidates } from './types.js';
import { listCounties, attachCoordinates, assignToCounties, type QueryFn, type AssignResult } from './locate.js';
import { sweepCategories, countyCategoryRoots, type SweepOptions } from './sweep.js';
import { filterCandidates } from './filter.js';
import { rankCandidates, PAGE_SIZE } from './rank.js';
import { renderSourceFrame } from './render.js';
import { USER_AGENT } from './commonsClient.js';

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
  sweep?: (roots: string[], opts?: SweepOptions) => Promise<CandidateFile[]>;
  attach?: (files: CandidateFile[]) => Promise<CandidateFile[]>;
  assign?: (files: CandidateFile[], stateFips: string, query: QueryFn) => Promise<AssignResult>;
  /** Download and write the review frame. Injected in tests; defaults to a real fetch. */
  render?: (file: CandidateFile, outPath: string) => Promise<unknown>;
}

/** What is written to disk: the operator's page plus the accounting behind it. */
export interface CountyFile extends CountyCandidates {
  allCandidates: CandidateFile[];
  /** Files the sweep returned at all -- the denominator every other count sums to. */
  filesSwept: number;
  /** Zero categories is a DIFFERENT finding from zero files: the title probably missed. */
  categoriesFound: number;
  /** Categories that errored. Any at all means `swept` stays false. */
  categoryErrors: number;
  /** Located inside this state but in another county. Not ours, but not lost either. */
  otherCounty: number;
  unlocated: number;
  outside: number;
}

/** Fetch the file and write its full, uncropped review frame. */
async function defaultRender(file: CandidateFile, outPath: string): Promise<unknown> {
  const res = await fetch(file.url, { headers: { 'User-Agent': USER_AGENT } });
  if (!res.ok) throw new Error(`fetch ${file.title}: HTTP ${res.status}`);
  return renderSourceFrame(Buffer.from(await res.arrayBuffer()), outPath);
}

/** Read a county's previous row, treating an unreadable file as never swept. */
function readPrevious(file: string): CountyFile | null {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8')) as CountyFile;
  } catch {
    // A crash mid-write leaves truncated JSON. Dying here would wedge the whole state
    // behind a file nobody can find without reading a stack trace.
    return null;
  }
}

/** Write via a temp file and rename, so a crash cannot leave half a row behind. */
function writeAtomic(file: string, row: CountyFile): void {
  const tmp = `${file}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(row, null, 1));
  fs.renameSync(tmp, file);
}

export async function buildStateCandidates(stateUsps: string, outDir: string, deps: BuildDeps): Promise<CountyFile[]> {
  const usps = stateUsps.toUpperCase();
  const stateFips = STATE_FIPS[usps];
  if (!stateFips) throw new Error(`Unknown state code '${stateUsps}'. Known: ${Object.keys(STATE_FIPS).join(', ')}`);
  const stateName = STATE_NAME[usps];

  const sweep = deps.sweep ?? sweepCategories;
  const attach = deps.attach ?? ((f: CandidateFile[]) => attachCoordinates(f));
  const assign = deps.assign ?? assignToCounties;
  const render = deps.render ?? defaultRender;

  const imgDir = path.join(outDir, 'img');
  fs.mkdirSync(imgDir, { recursive: true });
  const counties = await listCounties(stateFips, deps.query);
  const rows: CountyFile[] = [];

  for (const county of counties) {
    const file = path.join(outDir, `${county.geoid}.json`);
    // Resume: a county already swept is left alone. One left swept:false by a crashed
    // run is NOT -- that is the whole reason the flag exists.
    if (fs.existsSync(file)) {
      const prev = readPrevious(file);
      if (prev?.swept) { rows.push(prev); continue; }
    }

    const row: CountyFile = {
      geoid: county.geoid, name: county.name, swept: false, candidates: [], rejected: {},
      allCandidates: [], filesSwept: 0, categoriesFound: 0, categoryErrors: 0,
      otherCounty: 0, unlocated: 0, outside: 0,
    };

    try {
      const errored: string[] = [];
      // No county-seat source exists yet, so the seat is null and the seat's photographs
      // are reached through the county category's subcategories instead.
      const swept = await sweep(countyCategoryRoots(county.name, stateName, null), {
        onError: (cat, e) => {
          errored.push(cat);
          process.stderr.write(`  ! ${county.geoid} ${cat}: ${(e as Error).message}\n`);
        },
        onStats: (s) => { row.categoriesFound = s.categories; },
      });
      row.filesSwept = swept.length;
      row.categoryErrors = errored.length;

      const withCoords = await attach(swept);
      const placed = await assign(withCoords, stateFips, deps.query);
      const mine = placed.located.get(county.geoid) ?? [];
      // Located in the state but in some other county. Counted, so the accounting
      // closes and so a run can tell "not here" from "lost".
      let elsewhere = 0;
      for (const [geoid, list] of placed.located) if (geoid !== county.geoid) elsewhere += list.length;
      row.otherCounty = elsewhere;

      const { kept, rejected } = filterCandidates(mine);
      const ranked = rankCandidates(kept);
      row.allCandidates = ranked;
      row.candidates = ranked.slice(0, PAGE_SIZE);
      row.rejected = rejected;
      row.unlocated = placed.unlocated.length;
      row.outside = placed.outside.length;

      // Render only what the operator will actually see.
      for (let i = 0; i < row.candidates.length; i++) {
        const out = path.join(imgDir, `${county.geoid}-${i}.jpg`);
        try {
          await render(row.candidates[i], out);
        } catch (e) {
          process.stderr.write(`  ! ${county.geoid} render ${row.candidates[i].title}: ${(e as Error).message}\n`);
        }
      }

      // 🔴 A county whose sweep lost a category has NOT been swept. Saying otherwise
      // publishes "nothing here" over a hole in the search.
      row.swept = errored.length === 0;
    } catch (e) {
      // swept stays false. The row is still written, so the next run finds it and
      // retries exactly this county rather than the whole state.
      row.categoryErrors = Math.max(1, row.categoryErrors);
      process.stderr.write(`  ! ${county.geoid} ${county.name}: ${(e as Error).message}\n`);
    }

    writeAtomic(file, row);
    rows.push(row);
  }
  return rows;
}
