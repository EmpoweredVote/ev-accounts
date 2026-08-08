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
  district_id: string; geo_id: string; state: string; district_type: string;
  label: string; offices: number; seated: number;
};

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

  // ---- coverage_vs_census.csv : one row per Census unit
  const coverage = census.map((c) => {
    const m = byKey.get(c.key);
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
      we_have_district: m ? 'yes' : 'no',
      our_offices: m?.offices ?? 0,
      our_seated_officeholders: m?.seated ?? 0,
      coverage_status: !m ? 'absent' : m.seated > 0 ? 'seated' : 'district_only',
    };
  }).sort((a, b) => a.state.localeCompare(b.state) || (b.population ?? 0) - (a.population ?? 0));

  // ---- uncovered_by_population.csv : the gap list = seeding priority + seed source
  const uncovered = coverage
    .filter((r) => r.coverage_status !== 'seated')
    .sort((a, b) => (b.population ?? 0) - (a.population ?? 0));

  // ---- geo_id_review.csv : everything the deterministic join could not settle
  const censusByName = new Map<string, CensusUnit[]>();
  for (const c of census) {
    const nk = `${c.fipsState}|${normName(c.name)}`;
    censusByName.set(nk, [...(censusByName.get(nk) ?? []), c]);
  }
  const censusKeys = new Set(census.map((c) => c.key));

  const review = [
    ...unjoinable.map((r) => {
      const guess = guessNameFromGeoId(r.geo_id);
      const nk = `${STATE_FIPS[r.state]}|${normName(guess)}`;
      const cands = censusByName.get(nk) ?? [];
      const one = cands.length === 1 ? cands[0] : null;
      return {
        reason: 'non_fips_geo_id',
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

  verify(coverage, review, census, ours, byKey, unjoinable);
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

  const nonFips = review.filter((r) => r.reason === 'non_fips_geo_id');
  const orphan = review.filter((r) => r.reason === 'fips_not_in_census');
  L.push('## Why these numbers are a lower bound', '');
  L.push(`${nonFips.length} of our district rows carry a geo_id that is not a FIPS code and could not`);
  L.push('be joined deterministically. They are listed in the review file with a *proposed* match and');
  L.push('a confidence flag; nothing was auto-resolved. Any that turn out to be places missing from');
  L.push('the covered set will raise the coverage figures above.');
  const adds = nonFips.filter((r) => r.proposal_adds_coverage === 'yes');
  const already = nonFips.filter((r) => r.proposal_adds_coverage === 'no_already_covered').length;
  const nomatch = nonFips.filter((r) => r.match_confidence === 'no_match').length;
  const addPlaces = new Set(adds.map((r) => r.proposed_fips_key));
  L.push('');
  L.push(`- ${already} propose a place already counted (would add nothing)`);
  L.push(`- ${adds.length} propose a place NOT currently counted — ${addPlaces.size} distinct place(s), so coverage rises by that much`);
  L.push(`- ${nomatch} could not be matched to any Census name and need a human`);

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
                byKey: Map<string, any>, unjoinable: Ours[]) {
  const fail = (m: string) => { throw new Error(`[verify] ${m}`); };

  if (coverage.length !== census.length) fail(`coverage rows ${coverage.length} != census units ${census.length}`);

  // Every one of our districts is either joined or explicitly surfaced for review — nothing is
  // silently dropped, which is the only way a coverage number can quietly overstate itself.
  const joined = [...byKey.values()].reduce((a, e) => a + e.rows.length, 0);
  if (joined + unjoinable.length !== ours.length) {
    fail(`${joined} joined + ${unjoinable.length} unjoinable != ${ours.length} districts`);
  }
  const reviewedNonFips = review.filter((r) => r.reason === 'non_fips_geo_id').length;
  if (reviewedNonFips !== unjoinable.length) {
    fail(`${unjoinable.length} unjoinable districts but ${reviewedNonFips} in the review file`);
  }

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
    `(${joined} joined, ${unjoinable.length} to review), all assertions passed`);
}

main()
  .catch((e) => { console.error(e); process.exitCode = 1; })
  .finally(() => pool.end());
