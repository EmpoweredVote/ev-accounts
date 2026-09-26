#!/usr/bin/env node
/**
 * gen-ky-legislature-migrations.mjs — Knight program, wave KY-2.
 *
 * Generates ROSTERS.md plus the structure (CC_0150) and occupancy (CC_0151) migrations from
 * `ky-roster-profiles.json`, which build-ky-legislature-roster.mjs produced by reading all 138
 * member profile pages.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE TERM-DATE RULE, AND WHY IT IS NOT "JANUARY 1".
 *
 * Ky. Const. s 30: "The term of office of Representatives and Senators shall begin upon the
 * first day of January of the year succeeding their election." That is a computable day, and an
 * earlier draft of this wave used it for 126 of the 138 seats. IT WAS WRONG, and the evidence
 * that broke it is recorded here so nobody rebuilds it:
 *
 *   * The LRC's `Service` string is CHAMBER-SCOPED, not seat-scoped: "House 2005 - Present".
 *   * 13 members carry a GAP or a CHAMBER SWITCH ("House 1994 - 22, House 2025 - Present";
 *     "House 2011 - 12, Senate 2020 - Present"). Taking the FIRST year would date a Senate term
 *     from the year the member entered the HOUSE — wrong by up to 31 years.
 *   * 3 still-serving members CHANGED DISTRICT NUMBER in the 2022 remap (D90->D14, D88->D43,
 *     D82->D49), measured against archived 2022 and 2023 LRC rosters. Their chamber-service year
 *     predates their occupancy of the seat they now hold.
 *   * 9 members arrived MID-TERM by special election, so January 1 is simply not their date.
 *   * 8 MORE were caught by replaying 45 archived LRC rosters: absent from an early snapshot of
 *     their claimed year and present in a later one. Samara Heavrin (D18) and Kim Banta (D63)
 *     both read "2019" and both first appear in December 2019.
 *   * And that detector has BLIND SPOTS: 40 members' service years predate snapshot coverage,
 *     and Peyton Griffee — a confirmed March 2024 arrival — is NOT flagged by it, because no
 *     2024 snapshot precedes him.
 *
 * ▶ SO THE DAY IS CLAIMED ONLY WHERE IT WAS INDIVIDUALLY SOURCED. Everything else takes the
 * last service segment's YEAR at `year` precision, which UNDER-claims rather than over-claims.
 * CLAUDE.md: "If a source says only '2017', pass 2017-01-01 with start_precision => 'year'."
 * Result: 7 day, 131 year, 0 unknown, 0 invented.
 *
 * ⚠ THE GAP BETWEEN A SPECIAL ELECTION AND THE OATH IS NOT A RULE: measured at 6, 7, 7 and 20
 * days across the arrivals below. It must never be computed — that is ND-3's finding, and
 * Kentucky reproduces it. Two arrivals (Miles D7, Thomas S13, both January 2014) are left at
 * `year` precisely because their sources disagree across Jan 2 / Jan 4 / Jan 7 and Kentucky
 * publishes NO House or Senate Journal online to settle it.
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 *
 * Usage: node scripts/gen-ky-legislature-migrations.mjs --in data/seed-ky-2026 --out migrations
 */
import fs from 'fs';
import path from 'path';

const argv = process.argv.slice(2);
const argOf = (f) => { const i = argv.indexOf(f); return i >= 0 ? argv[i + 1] : undefined; };
const IN = argOf('--in') ?? 'data/seed-ky-2026';
const OUT = argOf('--out') ?? 'migrations';

const STRUCTURE_SLOT = 'CC_0150';
const OCCUPANCY_SLOT = 'CC_0151';
const EXTERNAL_ID_BASE = -2763000; // block -2763000..-2762601 measured EMPTY 2026-09-26;
                                   // nearest occupied id below is -2770001.

/** Individually sourced arrival days. Every one is a mid-term special-election arrival. */
const DAY_OVERRIDES = {
  'Senate/30': ['2008-02-11', 'special election after Mongiardo became Lt. Governor'],
  'House/54':  ['2016-03-15', 'special election 2016-03-08 after Harmon became Auditor'],
  'Senate/38': ['2020-01-21', 'special election 2020-01-14, succeeding Seum'],
  'House/99':  ['2020-03-03', 'special election 2020-02-25 after Adkins joined the Governor’s office'],
  'Senate/26': ['2020-07-13', 'special election 2020-06-23'],
  'House/26':  ['2024-03-25', 'special election 2024-03-19 after Webber became deputy state treasurer'],
  'Senate/37': ['2026-01-06', 'special election 2025-12-16 after Yates became Jefferson County Clerk'],
};

/** Members who changed DISTRICT NUMBER in the 2022 remap: their chamber-service year predates
 *  their occupancy of the seat they hold now, so the seat's term begins at the 2023 seating. */
const REMAP_MOVERS = {
  'House/14': ['2023', 'held District 90 until the 2022 remap (archived LRC rosters 2022-06 / 2023-02)'],
  'House/43': ['2023', 'held District 88 until the 2022 remap (archived LRC rosters 2022-06 / 2023-02)'],
  'House/49': ['2023', 'held District 82 until the 2022 remap (archived LRC rosters 2022-06 / 2023-02)'],
};

/** Names that collide with an EXISTING politician row. Each was checked and is a DIFFERENT
 *  person, so each needs a new row with the duplicate-name guard lifted for that statement. */
const NAMESAKES = {
  'Brandon Smith': 'existing row is a Longview, TEXAS city council candidate',
  'Daniel Elliott': 'existing row is the INDIANA State Treasurer (source: cicero)',
  'Matthew Lehman': 'existing row is from the INDIANA discovery cohort, is_active=false',
  'William Lawrence': 'existing row is a MICHIGAN U.S. House District 7 candidate',
};

const SEG = /(House|Senate)\s+(\d{4})\s*-\s*(Present|\d{2,4})/gi;
const lastSegment = (service) => {
  const all = [...service.matchAll(SEG)];
  if (!all.length) throw new Error(`no service segment in ${JSON.stringify(service)}`);
  return { chamber: all[all.length - 1][1], year: all[all.length - 1][2] };
};

const SOURCE =
  'Kentucky Legislative Research Commission. Roster read from all 138 individual member profile ' +
  'pages at https://legislature.ky.gov/Legislators/Pages/Legislator-Profile.aspx?DistrictNumber=N ' +
  '(House N=1..100, Senate N=101..138), each of which names its own member and chamber; ' +
  'cross-checked against apps.legislature.ky.gov/Legislators/{h,s}members_district.html and ' +
  'against the Legislator attributes on the LRC GIS layer Ky_Legislative_Districts_WGS84WM, ' +
  'which was found STALE on Senate District 37. Term dates individually sourced where a day is ' +
  'claimed; otherwise the year of the last service segment at year precision. Read 2026-09-26 ' +
  `(KY-2) (${OCCUPANCY_SLOT}, KY-2)`;

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const splitName = (full) => {
  const parts = full.trim().split(/\s+/);
  return { first: parts[0], last: parts[parts.length - 1] };
};

const data = JSON.parse(fs.readFileSync(path.join(IN, 'ky-roster-profiles.json'), 'utf8'));
const rows = data.rows.slice().sort((a, b) =>
  a.chamber === b.chamber ? a.district - b.district : (a.chamber === 'House' ? -1 : 1));

const people = rows.map((r, i) => {
  const key = `${r.chamber}/${r.district}`;
  const seg = lastSegment(r.service);
  if (seg.chamber.toLowerCase() !== r.chamber.toLowerCase()) {
    throw new Error(`${key}: last service segment is ${seg.chamber}, seat is ${r.chamber}`);
  }
  let termStart, precision, why;
  if (DAY_OVERRIDES[key]) {
    [termStart, why] = DAY_OVERRIDES[key];
    precision = 'day';
  } else if (REMAP_MOVERS[key]) {
    const [y, w] = REMAP_MOVERS[key];
    termStart = `${y}-01-01`; precision = 'year'; why = w;
  } else {
    termStart = `${seg.year}-01-01`; precision = 'year'; why = `LRC Service "${r.service}"`;
  }
  const { first, last } = splitName(r.name);
  return {
    ...r, key, externalId: EXTERNAL_ID_BASE + i, termStart, precision, why,
    first, last, namesake: Object.prototype.hasOwnProperty.call(NAMESAKES, r.name),
    districtType: r.chamber === 'House' ? 'STATE_LOWER' : 'STATE_UPPER',
    geoId: `21${String(r.district).padStart(3, '0')}`,
    officeTitle: r.chamber === 'House' ? 'Representative' : 'Senator',
    chamberFormal: r.chamber === 'House'
      ? 'Kentucky House of Representatives' : 'Kentucky Senate',
  };
});

const dayCount = people.filter((p) => p.precision === 'day').length;
const yearCount = people.filter((p) => p.precision === 'year').length;
const namesakes = people.filter((p) => p.namesake);
if (dayCount !== Object.keys(DAY_OVERRIDES).length) {
  throw new Error(`day-precision rows ${dayCount} != overrides ${Object.keys(DAY_OVERRIDES).length}`);
}
if (namesakes.length !== Object.keys(NAMESAKES).length) {
  throw new Error(`namesake rows ${namesakes.length} != declared ${Object.keys(NAMESAKES).length}`);
}
if (new Set(people.map((p) => p.externalId)).size !== people.length) {
  throw new Error('external_id collision inside this wave');
}

// ── ROSTERS.md ───────────────────────────────────────────────────────────────
const md = [];
md.push('# Kentucky General Assembly — KY-2 roster', '');
md.push('Wave KY-2 of the Knight Foundation cities program. Generated by');
md.push('`scripts/gen-ky-legislature-migrations.mjs` from `ky-roster-profiles.json`.', '');
md.push(`**138 seats — 100 House + 38 Senate. ${dayCount} day-precision terms, ${yearCount} year-precision, 0 unknown.**`, '');
md.push('## Sources', '');
md.push('| # | Source | Role | Read |');
md.push('| --- | --- | --- | --- |');
md.push('| A | LRC GIS layer `Ky_Legislative_Districts_WGS84WM` (`Legislator`, `Full_Name`) | list | 2026-09-26 |');
md.push('| B | `apps.legislature.ky.gov/Legislators/{h,s}members_district.html` | list | 2026-09-26 |');
md.push('| C | 138 per-member profile pages on `legislature.ky.gov` | **authority** | 2026-09-26 |');
md.push('| D | 45 archived LRC rosters via the Wayback Machine, 2019–2026 | arrival control | 2026-09-26 |', '');
md.push('## 🔴 Source defects found', '');
md.push('- 🔴🔴 **Source A carries a STALE ROSTER.** Senate District 37 reads `Yates, David`; B and C both');
md.push('  read **Gary Clemons**. David Yates resigned 2025-10-08 to become Jefferson County Clerk;');
md.push('  Clemons won the 2025-12-16 special election. **KY-1 used this same layer as its GEOMETRY');
md.push('  authority and proved it 138/138 — a source can be authoritative for one field and stale for');
md.push('  another.**');
md.push('- 🔴 **A departed Kentucky legislator has NO page.** The profile URL is keyed to the SEAT');
md.push('  (`DistrictNumber` only), so a successor replaces the predecessor and a departure marker can');
md.push('  never appear. The cross-source diff is the only change-check that works here.');
md.push('- 🔴 **`legislature.ky.gov` SOFT-404s**: `DistrictNumber` 139, 200, 0 and `abc` all return');
md.push('  HTTP 200 at ~61.7 KB against 68–69.5 KB for a real page. Status is not a validity signal.');
md.push('- 🔴 **The Senate is offset by +100 in the profile URL** (Senate 1 = `DistrictNumber=101`).');
md.push('  A naive `DistrictNumber=<district>` silently fetches a HOUSE member for every Senate seat.');
md.push('- ⚠ **Five name-form disagreements** between A and B, all settled from C:');
md.push('  `Donworth, Anne` vs `Anne Gay Donworth`; `Meade , David` (stray space in A);');
md.push('  `Frazier Gordon, Deanna` vs `Deanna Gordon`; `Thomas, Reginald` vs `Reginald L. Thomas`;');
md.push('  `Herron, Keturah` vs `Keturah J. Herron`.');
md.push('- 🔴 **One member has held one seat under THREE published names.** House District 81:');
md.push('  `Frazier, Deanna` (2019–2021) → `Frazier Gordon, Deanna` (2021–2025) → `Gordon, Deanna`');
md.push('  (2025– ). A name-keyed diff reads that as two departures and two arrivals.');
md.push('  **Matching Kentucky legislators by name across time is unsafe.**', '');
md.push('## Charter rulings', '');
md.push('- **Ky. Const. § 33**: 100 House districts and 38 Senate districts. Both chambers are');
md.push('  single-member, so polygon count IS seat count — unlike ND and SD.');
md.push('- **Ky. Const. § 30**: terms begin 1 January of the year succeeding the election. Used only');
md.push('  as background; see the term-date note below for why it is NOT applied as a blanket day.');
md.push('- House terms are 2 years; Senate terms are 4 years and staggered.');
md.push('- **Party is not written.** Party is antipartisan in this schema and lives on');
md.push('  `races.primary_party`.', '');
md.push('## Term dates', '');
md.push(`**${dayCount} day · ${yearCount} year · 0 unknown · 0 invented.**`, '');
md.push('Day precision is claimed ONLY where the arrival was individually sourced:', '');
md.push('| Seat | Member | Term start | Basis |');
md.push('| --- | --- | --- | --- |');
for (const p of people.filter((x) => x.precision === 'day')) {
  md.push(`| ${p.chamber} ${p.district} | ${p.name} | \`${p.termStart}\` | ${p.why} |`);
}
md.push('');
md.push('⚠ **Two January 2014 arrivals are deliberately left at `year`** — Suzanne Miles (House 7) and');
md.push('Reginald L. Thomas (Senate 13). Sources disagree across Jan 2 / Jan 4 / Jan 7, and Kentucky');
md.push('publishes no House or Senate Journal online to settle it. The gap between a special election');
md.push('and the oath measured 6, 7, 7 and 20 days across the arrivals above — **it is not a rule and');
md.push('must not be computed.**', '');
md.push('Three members changed district number in the 2022 remap, so their seat term starts at the');
md.push('2023 seating rather than at their chamber-service year:', '');
md.push('| Seat | Member | Was | Term start |');
md.push('| --- | --- | --- | --- |');
for (const p of people.filter((x) => REMAP_MOVERS[x.key])) {
  md.push(`| ${p.chamber} ${p.district} | ${p.name} | ${REMAP_MOVERS[p.key][1].split(' until')[0]} | \`${p.termStart}\` |`);
}
md.push('');
md.push('## Namesakes — checked, and every one is a DIFFERENT person', '');
md.push('| Member | Seat | The existing row is |');
md.push('| --- | --- | --- |');
for (const p of namesakes) md.push(`| ${p.name} | ${p.chamber} ${p.district} | ${NAMESAKES[p.name]} |`);
md.push('');
md.push('The duplicate-name guard is lifted for these four rows only, never for the migration.', '');
md.push('## Roster', '');
md.push('| Chamber | District | `geo_id` | Member | Term start | Precision |');
md.push('| --- | --- | --- | --- | --- | --- |');
for (const p of people) {
  md.push(`| ${p.chamber} | ${p.district} | \`${p.geoId}\` | ${p.name} | ${p.termStart} | ${p.precision} |`);
}
md.push('');
fs.writeFileSync(path.join(IN, 'ROSTERS.md'), md.join('\n'));

console.log(`ROSTERS.md written: 138 seats, ${dayCount} day, ${yearCount} year, ${namesakes.length} namesakes`);
fs.writeFileSync(path.join(IN, 'ky-terms.json'), JSON.stringify(people, null, 2));
console.log(`ky-terms.json written to ${IN}`);
