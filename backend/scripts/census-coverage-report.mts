/**
 * census-coverage-report.mts — measure our officeholder coverage against the real universe of
 * local governments, weighted by population.
 *
 *   npx tsx scripts/census-coverage-report.mts --states=ca,or --out=data/census-coverage
 *
 * Source: Census Bureau Government Units Listing (Annual Organization public use file).
 *   https://www.census.gov/programs-surveys/gus/data/publicusefiles.html
 *   https://www2.census.gov/programs-surveys/gus/datasets/2025/gov_units_2025.zip
 * Unzip Govt_Units_2025_Final.xlsx into backend/data/census-gov-units/ (not committed, ~10MB).
 *
 * Read-only against our database. Writes CSVs and a summary; never mutates anything.
 *
 * Why this exists: our own coverage report can only say how many rows we hold. It cannot say what
 * fraction of the universe that is, so it cannot distinguish "we cover this state" from "we cover
 * the four cities somebody happened to seed." Joining to the Census universe converts row counts
 * into the only unit that means anything to a reader: how many people live somewhere we know who
 * represents them.
 */
import { writeFileSync, mkdirSync, existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import * as XLSX from 'xlsx';
import { pool } from '../src/lib/db.js';

// ---------------------------------------------------------------- args

const arg = (name: string, fallback: string) =>
  process.argv.find((a) => a.startsWith(`--${name}=`))?.split('=').slice(1).join('=') ?? fallback;

const STATES = arg('states', 'ca,or').split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);
const CENSUS_XLSX = arg('census', 'data/census-gov-units/Govt_Units_2025_Final.xlsx');
const OUT_DIR = arg('out', 'data/census-coverage');
const SLUG = STATES.join('_');

const STATE_FIPS: Record<string, string> = {
  al: '01', ak: '02', az: '04', ar: '05', ca: '06', co: '08', ct: '09', de: '10', dc: '11',
  fl: '12', ga: '13', hi: '15', id: '16', il: '17', in: '18', ia: '19', ks: '20', ky: '21',
  la: '22', me: '23', md: '24', ma: '25', mi: '26', mn: '27', ms: '28', mo: '29', mt: '30',
  ne: '31', nv: '32', nh: '33', nj: '34', nm: '35', ny: '36', nc: '37', nd: '38', oh: '39',
  ok: '40', or: '41', pa: '42', ri: '44', sc: '45', sd: '46', tn: '47', tx: '48', ut: '49',
  vt: '50', va: '51', wa: '53', wv: '54', wi: '55', wy: '56',
};
const FIPS_STATE = Object.fromEntries(Object.entries(STATE_FIPS).map(([k, v]) => [v, k]));

// ---------------------------------------------------------------- csv

function csvCell(v: unknown): string {
  if (v === null || v === undefined) return '';
  const s = String(v);
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}
const toCsv = (rows: Record<string, unknown>[], cols: string[]) =>
  [cols.join(','), ...rows.map((r) => cols.map((c) => csvCell(r[c])).join(','))].join('\r\n') + '\r\n';

// ---------------------------------------------------------------- census

type CensusUnit = {
  censusId: string; name: string; unitType: string; population: number | null;
  popYear: string | null; fipsState: string; fipsCounty: string; fipsPlace: string;
  county: string; web: string | null; state: string; key: string; kind: 'county' | 'place';
};

/**
 * IMPORTANT: STATE / CITY / ZIP in this file are the MAILING ADDRESS of the unit's contact, not
 * the jurisdiction. Auburn Township PA has a PO box in Vale, Oregon and reads STATE='OR'.
 * Always filter on FIPS_STATE.
 *
 * Counties carry a synthetic FIPS_PLACE of '99' + county code, so they key on
 * FIPS_STATE||FIPS_COUNTY. Municipalities and townships key on FIPS_STATE||FIPS_PLACE.
 */
function loadCensus(path: string, states: string[]): CensusUnit[] {
  if (!existsSync(path)) {
    throw new Error(
      `Census file not found at ${path}\n` +
      `Download https://www2.census.gov/programs-surveys/gus/datasets/2025/gov_units_2025.zip\n` +
      `and unzip Govt_Units_2025_Final.xlsx into the directory above (not committed, ~10MB).`,
    );
  }
  const wanted = new Set(states.map((s) => STATE_FIPS[s]).filter(Boolean));
  // XLSX.readFile is unavailable in the ESM build (it needs fs wired in), so read the buffer here.
  const wb = XLSX.read(readFileSync(path), { type: 'buffer' });
  const ws = wb.Sheets['General Purpose'];
  if (!ws) throw new Error(`sheet "General Purpose" missing; found: ${wb.SheetNames.join(', ')}`);
  const raw = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { raw: true, defval: null });

  const out: CensusUnit[] = [];
  for (const r of raw) {
    if (String(r.ACTIVE ?? '').trim() !== 'Y') continue;
    const fipsState = String(r.FIPS_STATE ?? '').padStart(2, '0');
    if (!wanted.has(fipsState)) continue;
    const unitType = String(r.UNIT_TYPE ?? '');
    const kind: 'county' | 'place' = unitType.startsWith('1') ? 'county' : 'place';
    const fipsCounty = String(r.FIPS_COUNTY ?? '').padStart(3, '0');
    const fipsPlace = String(r.FIPS_PLACE ?? '').padStart(5, '0');
    const popRaw = r.POPULATION;
    const population = popRaw === null || popRaw === '' ? null : Number(String(popRaw).replace(/,/g, ''));
    out.push({
      censusId: String(r.CENSUS_ID_PID6 ?? ''),
      name: String(r.UNIT_NAME ?? '').trim(),
      unitType,
      population: Number.isFinite(population as number) ? (population as number) : null,
      popYear: r.POPULATION_SOURCE_YEAR ? String(r.POPULATION_SOURCE_YEAR) : null,
      fipsState, fipsCounty, fipsPlace,
      county: String(r.COUNTY_AREA_NAME ?? '').trim(),
      web: (String(r.WEB_ADDRESS ?? '').trim() || null),
      state: FIPS_STATE[fipsState] ?? fipsState,
      kind,
      key: kind === 'county' ? fipsState + fipsCounty : fipsState + fipsPlace,
    });
  }
  return out;
}

// ---------------------------------------------------------------- our side

const Q_DISTRICTS = `
  SELECT d.id::text                         AS district_id,
         coalesce(btrim(d.geo_id), '')      AS geo_id,
         coalesce(btrim(d.ocd_id), '')      AS ocd_id,
         lower(d.state)                     AS state,
         d.district_type,
         coalesce(d.label, '')              AS label,
         count(o.id)                        AS offices,
         count(och.politician_id)           AS seated
  FROM essentials.districts d
  LEFT JOIN essentials.offices o                 ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = ANY($1::text[])
    AND d.district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY')
  GROUP BY d.id, d.geo_id, d.state, d.district_type, d.label
`;

type Ours = {
  district_id: string; geo_id: string; ocd_id: string; state: string; district_type: string;
  label: string; offices: number; seated: number;
};

/**
 * Parent place or county for a sub-jurisdictional district, read out of its OCD id.
 *
 * A council ward has NO FIPS place code -- FIPS identifies places, not wards inside them -- so a
 * ward district legitimately carries a synthesized geo_id like `boston-ma-council-district-5`.
 * Those slugs are the join key to geofence_boundaries and must never be rewritten; 361 of the 381
 * non-FIPS rows have live geometry keyed on the exact string.
 *
 * The parent is nonetheless recoverable, because ocd_id already encodes it:
 *   ocd-division/country:us/state:ma/place:boston/ward:5   -> place boston
 *   ocd-division/country:us/state:ca/county:los_angeles/... -> county los_angeles
 * Reading it turns a ward into evidence that its city is covered, which is what the coverage
 * question actually asks.
 */
function ocdParent(ocdId: string): { kind: 'place' | 'county'; name: string } | null {
  const m = ocdId.match(/\/(place|county):([a-z0-9_~.-]+)/i);
  if (!m) return null;
  return { kind: m[1].toLowerCase() as 'place' | 'county', name: m[2].replace(/_/g, ' ') };
}

/** Only a numeric geo_id of the right width is a FIPS key. Everything else needs human review. */
function fipsKeyOf(r: Ours): { key: string; kind: 'county' | 'place' } | null {
  const g = r.geo_id;
  if (!/^\d+$/.test(g)) return null;
  if (r.district_type === 'COUNTY' && g.length === 5) return { key: g, kind: 'county' };
  if (g.length === 7) return { key: g, kind: 'place' };
  return null;
}

/** Normalized name, used ONLY to propose a review candidate — never to write anything. */
function normName(s: string): string {
  return s.toUpperCase()
    .replace(/^(CITY AND COUNTY OF|CITY OF|TOWN OF|VILLAGE OF|BOROUGH OF|TOWNSHIP OF|COUNTY OF)\s+/, '')
    .replace(/[^A-Z0-9]/g, '');
}

/** Best-effort place name out of the many incompatible slug schemes found in geo_id. */
function guessNameFromGeoId(geoId: string): string {
  let s = geoId;
  const ocdPlace = s.match(/(?:place|county):([a-z_]+)/i);
  if (ocdPlace) s = ocdPlace[1];
  s = s.replace(/[_-]?(council|supervisor|ward|commission|board|school|park|metro|city)[_-]?district.*$/i, '');
  s = s.replace(/[_-](ca|or|[a-z]{2})$/i, '');
  return s.replace(/[_-]+/g, ' ').trim();
}

// ---------------------------------------------------------------- main

async function main() {
  console.log(`[census] states=${STATES.join(',')} source=${CENSUS_XLSX}`);
  const census = loadCensus(CENSUS_XLSX, STATES);
  const ours: Ours[] = (await pool.query(Q_DISTRICTS, [STATES])).rows.map((r) => ({
    ...r, offices: Number(r.offices), seated: Number(r.seated),
  }));
  console.log(`[census] census units=${census.length} our districts=${ours.length}`);

  // Fold our districts onto FIPS keys. geo_id is not unique, so several rows can share a key —
  // that is expected (a city's mayor row and its at-large council row both carry the place FIPS).
  const byKey = new Map<string, { offices: number; seated: number; rows: Ours[] }>();
  const unjoinable: Ours[] = [];
  for (const r of ours) {
    const k = fipsKeyOf(r);
    if (!k) { unjoinable.push(r); continue; }
    const e = byKey.get(k.key) ?? { offices: 0, seated: 0, rows: [] };
    e.offices += r.offices; e.seated += r.seated; e.rows.push(r);
    byKey.set(k.key, e);
  }

  // Roll wards up to their parent via ocd_id. This resolves by NAME, which is why it is kept in
  // its own bucket and reported separately -- a name match is evidence, not proof, and the strict
  // FIPS number stays visible next to it so neither can hide the other.
  const censusByName = new Map<string, CensusUnit[]>();
  for (const c of census) {
    censusByName.set(`${c.fipsState}|${c.kind}|${normName(c.name)}`, [
      ...(censusByName.get(`${c.fipsState}|${c.kind}|${normName(c.name)}`) ?? []), c,
    ]);
  }
  const rollup = new Map<string, { offices: number; seated: number; rows: Ours[] }>();
  const unresolved: Ours[] = [];
  for (const r of unjoinable) {
    const p = ocdParent(r.ocd_id);
    const fs = STATE_FIPS[r.state];
    const cands = p && fs ? censusByName.get(`${fs}|${p.kind}|${normName(p.name)}`) ?? [] : [];
    if (cands.length !== 1) { unresolved.push(r); continue; }
    const e = rollup.get(cands[0].key) ?? { offices: 0, seated: 0, rows: [] };
    e.offices += r.offices; e.seated += r.seated; e.rows.push(r);
    rollup.set(cands[0].key, e);
  }
  console.log(`[census] ward rollup: ${unjoinable.length - unresolved.length} of ${unjoinable.length} ` +
    `non-FIPS districts resolved to a parent via ocd_id`);

  // ---- coverage_vs_census.csv : one row per Census unit
  const coverage = census.map((c) => {
    const m = byKey.get(c.key);
    const ru = rollup.get(c.key);
    return {
      state: c.state,
      unit_name: c.name,
      unit_type: c.unitType.split(' - ')[1] ?? c.unitType,
      census_id: c.censusId,
      fips_key: c.key,
      county_area: c.county,
      population: c.population,
      population_year: c.popYear,
      census_web_address: c.web,
      we_have_district: m ? 'yes' : ru ? 'via_ward_only' : 'no',
      our_offices: (m?.offices ?? 0) + (ru?.offices ?? 0),
      our_seated_officeholders: (m?.seated ?? 0) + (ru?.seated ?? 0),
      // Strict = FIPS-joined only. The rolled-up view additionally credits wards matched to this
      // place by name through ocd_id. Both are emitted; the summary shows them side by side.
      coverage_status_strict: !m ? 'absent' : m.seated > 0 ? 'seated' : 'district_only',
      coverage_status: (m?.seated ?? 0) + (ru?.seated ?? 0) > 0 ? 'seated'
        : m || ru ? 'district_only' : 'absent',
      ward_rollup_applied: ru ? 'yes' : '',
    };
  }).sort((a, b) => a.state.localeCompare(b.state) || (b.population ?? 0) - (a.population ?? 0));

  // ---- uncovered_by_population.csv : the gap list = seeding priority + seed source
  const uncovered = coverage
    .filter((r) => r.coverage_status !== 'seated')
    .sort((a, b) => (b.population ?? 0) - (a.population ?? 0));

  // ---- geo_id_review.csv : only what neither the FIPS join nor the ocd rollup could settle.
  // A slug geo_id is NOT reportable on its own -- a ward has no FIPS code, so a synthesized key
  // is the correct design there, and the slug is the join key to geofence_boundaries. Rewriting
  // one would detach the district from its polygon. Only unresolvable PARENTAGE is a finding.
  const censusKeys = new Set(census.map((c) => c.key));

  const review = [
    ...unresolved.map((r) => {
      // ocd_id first; fall back to picking a name out of the slug only when there is no ocd_id.
      const p = ocdParent(r.ocd_id);
      const guess = p ? p.name : guessNameFromGeoId(r.geo_id);
      const fs = STATE_FIPS[r.state];
      const cands = [
        ...(censusByName.get(`${fs}|place|${normName(guess)}`) ?? []),
        ...(censusByName.get(`${fs}|county|${normName(guess)}`) ?? []),
      ];
      const one = cands.length === 1 ? cands[0] : null;
      return {
        reason: p ? 'ocd_parent_unmatched' : 'no_parent_recoverable',
        state: r.state,
        district_id: r.district_id,
        district_type: r.district_type,
        label: r.label,
        geo_id: r.geo_id,
        our_offices: r.offices,
        our_seated_officeholders: r.seated,
        guessed_name: guess,
        proposed_census_name: one?.name ?? '',
        proposed_fips_key: one?.key ?? '',
        proposed_population: one?.population ?? '',
        match_confidence: cands.length === 1 ? 'single_name_match' : cands.length > 1 ? 'ambiguous' : 'no_match',
        proposal_adds_coverage: one ? (byKey.has(one.key) ? 'no_already_covered' : 'yes') : '',
      };
    }),
    // Exact duplicate district rows: same FIPS key, same type, same label. A place FIPS carrying
    // several rows is normal (a mayor row and an at-large council row share it), so only an
    // identical triple is evidence of duplication rather than structure.
    ...[...byKey.values()].flatMap((e) => {
      const seen = new Map<string, Ours[]>();
      for (const r of e.rows) {
        const k = `${r.geo_id}|${r.district_type}|${r.label}`;
        seen.set(k, [...(seen.get(k) ?? []), r]);
      }
      return [...seen.values()].filter((g) => g.length > 1).flatMap((g) => g.map((r) => ({
        reason: 'duplicate_district_rows',
        state: r.state,
        district_id: r.district_id,
        district_type: r.district_type,
        label: r.label,
        geo_id: r.geo_id,
        our_offices: r.offices,
        our_seated_officeholders: r.seated,
        guessed_name: '',
        proposed_census_name: '',
        proposed_fips_key: r.geo_id,
        proposed_population: '',
        match_confidence: `${g.length}_rows_share_geo_id_type_and_label`,
        proposal_adds_coverage: '',
      })));
    }),
    // Our FIPS keys that do not exist in the Census universe at all — surplus or misfiled rows.
    // Note SF legitimately lands here: Census classifies it as MUNICIPAL, not a county.
    ...[...byKey.entries()]
      .filter(([k]) => !censusKeys.has(k))
      .flatMap(([k, e]) => e.rows.map((r) => ({
        reason: 'fips_not_in_census',
        state: r.state,
        district_id: r.district_id,
        district_type: r.district_type,
        label: r.label,
        geo_id: r.geo_id,
        our_offices: r.offices,
        our_seated_officeholders: r.seated,
        guessed_name: '',
        proposed_census_name: '',
        proposed_fips_key: k,
        proposed_population: '',
        match_confidence: 'not_in_census_universe',
        proposal_adds_coverage: '',
      }))),
  ];

  mkdirSync(OUT_DIR, { recursive: true });
  const files = {
    coverage: `coverage_vs_census_${SLUG}.csv`,
    uncovered: `uncovered_by_population_${SLUG}.csv`,
    review: `geo_id_review_${SLUG}.csv`,
  };
  writeFileSync(join(OUT_DIR, files.coverage), toCsv(coverage, Object.keys(coverage[0] ?? {})), 'utf8');
  writeFileSync(join(OUT_DIR, files.uncovered), toCsv(uncovered, Object.keys(coverage[0] ?? {})), 'utf8');
  writeFileSync(join(OUT_DIR, files.review), toCsv(review, Object.keys(review[0] ?? {})), 'utf8');

  const summary = renderSummary(coverage, review, files);
  writeFileSync(join(OUT_DIR, `SUMMARY_${SLUG}.md`), summary, 'utf8');

  verify(coverage, review, census, ours, byKey, unjoinable, rollup, unresolved);
  console.log(`[census] wrote 4 files to ${OUT_DIR}`);
  console.log(summary.split('\n').slice(0, 40).join('\n'));
}

type Cov = { state: string; unit_type: string; population: number | null; coverage_status: string };

function renderSummary(coverage: Cov[], review: any[], files: Record<string, string>): string {
  const L: string[] = ['# Coverage vs the Census universe', ''];
  L.push('Denominator: Census Bureau Government Units Listing 2025, active general-purpose');
  L.push('governments only. Joined on FIPS — counties on state+county, places on state+place.', '');
  L.push('| State | Unit type | Units | We have a district | Someone is seated | Population covered |');
  L.push('|---|---|---:|---:|---:|---:|');

  const groups = new Map<string, Cov[]>();
  for (const r of coverage) {
    const k = `${r.state}|${r.unit_type}`;
    groups.set(k, [...(groups.get(k) ?? []), r]);
  }
  for (const [k, rows] of [...groups.entries()].sort()) {
    const [st, ut] = k.split('|');
    const pop = (rs: Cov[]) => rs.reduce((a, r) => a + (r.population ?? 0), 0);
    const seated = rows.filter((r) => r.coverage_status === 'seated');
    const present = rows.filter((r) => r.coverage_status !== 'absent');
    const tp = pop(rows);
    L.push(`| ${st.toUpperCase()} | ${ut} | ${rows.length} | ${present.length} | ${seated.length} | ` +
      `${pop(seated).toLocaleString()} / ${tp.toLocaleString()} (${tp ? Math.round((pop(seated) / tp) * 100) : 0}%) |`);
  }
  L.push('');
  L.push('`district_only` in the CSV means the seat geography exists but nobody is recorded in it —');
  L.push('the failure mode that produces silently invisible offices. It is counted separately from');
  L.push('`absent` on purpose.', '');

  const nonFips = review.filter((r) => r.reason === 'ocd_parent_unmatched' || r.reason === 'no_parent_recoverable');
  const orphan = review.filter((r) => r.reason === 'fips_not_in_census');
  L.push('## How wards are counted', '');
  L.push('A council ward has no FIPS place code, so a ward district carries a synthesized geo_id such');
  L.push('as `boston-ma-council-district-5`. That string is the join key to geofence_boundaries and is');
  L.push('correct by design -- it is not a defect and must never be rewritten. Its parent is read from');
  L.push('`ocd_id` (`.../place:boston/ward:5`) so the ward counts toward its city.');
  L.push('');
  L.push('That rollup resolves by NAME, so the CSV carries both readings: `coverage_status_strict` is');
  L.push('the FIPS-join-only view, `coverage_status` includes the rollup, and `ward_rollup_applied`');
  L.push('marks which rows differ. Neither number is hidden behind the other.');
  L.push('');
  L.push(`${nonFips.length} district rows could not be attributed to any parent and remain unmeasured.`);
  const adds = nonFips.filter((r) => r.proposal_adds_coverage === 'yes');
  const already = nonFips.filter((r) => r.proposal_adds_coverage === 'no_already_covered').length;
  const noParent = nonFips.filter((r) => r.reason === 'no_parent_recoverable').length;
  const addPlaces = new Set(adds.map((r) => r.proposed_fips_key));
  L.push('');
  L.push(`- ${already} propose a place already counted (would add nothing)`);
  L.push(`- ${adds.length} propose a place NOT currently counted — ${addPlaces.size} distinct place(s), so coverage rises by that much`);
  L.push(`- ${noParent} carry no ocd_id at all, so their parent cannot be recovered without research`);
  L.push('');
  L.push('The fix for the last group is to populate `ocd_id`, NOT to touch `geo_id`.');

  const dupes = review.filter((r) => r.reason === 'duplicate_district_rows');
  if (dupes.length) {
    L.push('');
    L.push('## Districts sharing an identical key', '');
    L.push(`${dupes.length} district rows share an identical (geo_id, district_type, label) with`);
    L.push('another row.');
    L.push('');
    L.push('**This is a review list, not a defect list.** An at-large body legitimately models each');
    L.push('seat as its own district row — a six-member at-large council produces six rows carrying');
    L.push('the same place FIPS and the same "At-Large" label, and that is correct. Genuine');
    L.push('duplication looks identical from here, so the two can only be told apart by checking');
    L.push('whether the office count matches the real size of the body.');
    L.push('');
    L.push('Nothing is auto-resolved, and deleting a district silently orphans every office attached');
    L.push('to it, so treat a row here as a question rather than a finding.');
  }
  if (orphan.length) {
    L.push('');
    L.push(`${orphan.length} district row${orphan.length === 1 ? '' : 's'} carr${orphan.length === 1 ? 'ies' : 'y'} a FIPS key absent from the Census universe.`);
    L.push('Not necessarily an error — Census classifies consolidated city-counties such as San');
    L.push('Francisco as municipal, so a legitimate county row can land here. Check before acting.');
  }
  L.push('', '## Files', '');
  L.push(`- \`${files.coverage}\` — one row per Census government unit`);
  L.push(`- \`${files.uncovered}\` — the gap, ranked by population (seeding priority + seed source)`);
  L.push(`- \`${files.review}\` — everything the deterministic join could not settle`);
  L.push('');
  return L.join('\n');
}

// ---------------------------------------------------------------- verify

function verify(coverage: any[], review: any[], census: CensusUnit[], ours: Ours[],
                byKey: Map<string, any>, unjoinable: Ours[], rollup: Map<string, any>,
                unresolved: Ours[]) {
  const fail = (m: string) => { throw new Error(`[verify] ${m}`); };

  if (coverage.length !== census.length) fail(`coverage rows ${coverage.length} != census units ${census.length}`);

  // Every one of our districts is either joined or explicitly surfaced for review — nothing is
  // silently dropped, which is the only way a coverage number can quietly overstate itself.
  const joined = [...byKey.values()].reduce((a, e) => a + e.rows.length, 0);
  if (joined + unjoinable.length !== ours.length) {
    fail(`${joined} joined + ${unjoinable.length} unjoinable != ${ours.length} districts`);
  }
  // Every non-FIPS district is either rolled up to a parent or surfaced for review. Nothing may
  // fall between the two, which is the only way a coverage number could quietly overstate itself.
  const rolled = [...rollup.values()].reduce((a, e) => a + e.rows.length, 0);
  if (rolled + unresolved.length !== unjoinable.length) {
    fail(`${rolled} rolled up + ${unresolved.length} unresolved != ${unjoinable.length} non-FIPS districts`);
  }
  const reviewedNonFips = review.filter(
    (r) => r.reason === 'ocd_parent_unmatched' || r.reason === 'no_parent_recoverable').length;
  if (reviewedNonFips !== unresolved.length) {
    fail(`${unresolved.length} unresolved districts but ${reviewedNonFips} in the review file`);
  }

  // The rolled-up view can only ever be equal or better than the strict one, never worse.
  const regressed = coverage.filter((r) => r.coverage_status_strict === 'seated' && r.coverage_status !== 'seated');
  if (regressed.length) fail(`${regressed.length} units lost 'seated' status under the ward rollup`);

  const statuses = new Set(coverage.map((r) => r.coverage_status));
  const known = ['absent', 'district_only', 'seated'];
  const bad = [...statuses].filter((s) => !known.includes(s));
  if (bad.length) fail(`unexpected coverage_status: ${bad.join(', ')}`);

  // A unit cannot be "seated" without offices, nor "absent" while holding any.
  for (const r of coverage) {
    if (r.coverage_status === 'seated' && r.our_seated_officeholders === 0) fail(`seated with 0 holders: ${r.unit_name}`);
    if (r.coverage_status === 'absent' && (r.our_offices > 0 || r.our_seated_officeholders > 0)) {
      fail(`absent but holds offices: ${r.unit_name}`);
    }
  }

  const dupes = coverage.length - new Set(coverage.map((r) => `${r.state}|${r.fips_key}`)).size;
  if (dupes) fail(`${dupes} duplicate fips_key rows in coverage output`);

  console.log(`[verify] ${coverage.length} census units, ${ours.length} districts ` +
    `(${joined} FIPS-joined, ${rolled} rolled up via ocd_id, ${unresolved.length} to review), ` +
    'all assertions passed');
}

main()
  .catch((e) => { console.error(e); process.exitCode = 1; })
  .finally(() => pool.end());
