/**
 * Generate the PROGRAM.md baseline tables, and the arithmetic line under the
 * first one, from production.
 *
 * USAGE (from C:/EV-Accounts/backend -- it reads ./.env, so the cwd matters):
 *   node scripts/measure-program-tables.mjs
 *
 * Paste the output over the two tables in
 * .planning/knight-foundation/PROGRAM.md. It is read-only.
 *
 * 🔴 THE TOTAL LINE IS WRITTEN BY THIS SCRIPT, NOT BY HAND. PROGRAM.md's own
 * warning on that line is that it "stood at 545 for four days after MN-2 seated
 * 200 of these seats -- it is arithmetic over the applied waves, not a fresh
 * query". Hand arithmetic over sixteen rows is how it went stale.
 *
 * "have" is SEATED, not offices: the MN row reads `133/134 *(21A vacant)*` and
 * 21A is an office that exists with nobody in it.
 *
 * `expect` for a state with no legislature loaded is the STATUTORY seat count,
 * which cannot be measured from a database that holds none of those seats. Those
 * six are carried over from the 2026-08-28 baseline unchanged and are marked.
 */
import { config } from 'dotenv';
config({ quiet: true });
import pg from 'pg';

const FIPS = {
  CA: '06', CO: '08', NC: '37', IN: '18', FL: '12', GA: '13', KS: '20', KY: '21',
  MI: '26', MN: '27', MS: '28', ND: '38', OH: '39', PA: '42', SC: '45', SD: '46',
};
const ORDER = ['CA', 'CO', 'NC', 'IN', 'FL', 'GA', 'KS', 'KY', 'MI', 'MN', 'MS', 'ND', 'OH', 'PA', 'SC', 'SD'];
// Statutory seat counts for the states whose legislature is not loaded, carried
// over unchanged from the 2026-08-28 baseline.
const STATUTORY = {
  KS: [125, 40], KY: [100, 38], MI: [110, 38], MS: [122, 52], ND: [94, 47], SD: [70, 35],
};
// Vacancy notes, read off is_vacant/vacant_since rather than inferred from the gap.
const NOTE = {
  CA: ['*(AD-3 vacant)*', ''],
  FL: ['*(4 vacant)*', '*(SD-39 vacant)*'],
  MN: ['*(21A vacant)*', ''],
  GA: ['', '*(SD-12 vacant)*'],
  OH: ['*(HD-66 vacant)*', '*(SD-13 vacant)*'],
};

const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();

const seats = await c.query(`
  SELECT lower(d.state) AS st,
         CASE WHEN d.ocd_id LIKE '%/sldl:%' THEN 'house' ELSE 'senate' END AS chamber,
         count(*) AS offices, count(och.politician_id) AS seated
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE d.ocd_id LIKE '%/sldl:%' OR d.ocd_id LIKE '%/sldu:%'
  GROUP BY 1, 2`);
const geo = await c.query(`
  SELECT state AS fips, mtfcc, count(*) AS n
  FROM essentials.geofence_boundaries
  WHERE mtfcc IN ('G5220','G5210','G4110','G4020')
  GROUP BY 1, 2`);

const S = {}, G = {};
for (const r of seats.rows) (S[r.st.toUpperCase()] ??= {})[r.chamber] = r;
for (const r of geo.rows) (G[r.fips] ??= {})[r.mtfcc] = Number(r.n);

const bold = (s) => `**${s}**`;
let seated = 0, expect = 0, loadedStates = 0;
const rows1 = [];
for (const st of ORDER) {
  const h = S[st]?.house, s = S[st]?.senate;
  const [nh, ns] = NOTE[st] ?? ['', ''];
  if (h || s) {
    loadedStates++;
    const hs = Number(h?.seated ?? 0), ho = Number(h?.offices ?? 0);
    const ss = Number(s?.seated ?? 0), so = Number(s?.offices ?? 0);
    seated += hs + ss; expect += ho + so;
    rows1.push(`| ${st} | ${bold(`${hs}/${ho}`)}${nh ? ' ' + nh : ''} | ${bold(`${ss}/${so}`)}${ns ? ' ' + ns : ''} |`);
  } else {
    const [eh, es] = STATUTORY[st];
    expect += eh + es;
    rows1.push(`| ${st} | 0/${eh} | 0/${es} |`);
  }
}

const rows2 = [], needLeg = [], needPlace = [];
for (const st of ORDER) {
  const g = G[FIPS[st]] ?? {};
  const sldl = g.G5220 ?? 0, sldu = g.G5210 ?? 0, place = g.G4110 ?? 0, county = g.G4020 ?? 0;
  if (!sldl || !sldu) needLeg.push(st);
  if (!place) needPlace.push(st);
  const b = (n) => (n ? bold(n) : String(n));
  rows2.push(`| ${st} | ${b(sldl)} | ${b(sldu)} | ${b(place)} | ${county} |`);
}

console.log('### Legislature seats owed\n');
console.log('| State | House have/expect | Senate have/expect |');
console.log('| --- | --- | --- |');
console.log(rows1.join('\n'));
console.log(`\nTOTALS: seated ${seated} of ${expect} expected; remaining ${expect - seated}; legislatures loaded ${loadedStates} of 16`);

console.log('\n### Geofence polygons present\n');
console.log('| State | sldl | sldu | place | county |');
console.log('| --- | --- | --- | --- | --- |');
console.log(rows2.join('\n'));
console.log(`\nSTILL NEED sldu+sldl: ${needLeg.join(' ') || 'none'}  (${needLeg.length})`);
console.log(`STILL NEED place:     ${needPlace.join(' ') || 'NONE — every state in this table has a place layer'}`);

await c.end();
