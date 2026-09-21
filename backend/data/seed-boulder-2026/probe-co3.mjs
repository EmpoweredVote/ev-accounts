/**
 * CO-3 address probe.
 *
 * The only reliable detector is end-to-end: does a real point return the officials who represent it?
 * This runs point -> geofence_boundaries -> districts -> offices -> office_terms -> politicians,
 * exactly as address search does.
 *
 * 🟢 THE WAVES MUST STACK. Colorado's legislature was already seated, so a Boulder address has to
 * return FOUR KINDS of answer at once: a city council member, a county commissioner, a state
 * representative and a state senator. A city wave run before the legislature can only ever score 2
 * of 4 — which is why the programme orders them this way.
 *
 * 🔴 BOULDER IS ALL AT-LARGE, SO "EXACTLY ONE COUNCILLOR" IS THE WRONG ASSERTION. Every Boulder
 * address is represented by all nine seats and all three commissioners, because both bodies are
 * elected by the whole electorate. The assertion is therefore 9 and 3, not 1 and 1 — the opposite
 * of MN-4, where exactly one commissioner was correct.
 *
 * ⚠ NEGATIVE CONTROLS MUST SIT OUTSIDE THE THING BEING TESTED, not outside the last thing tested.
 * Longmont is inside Boulder COUNTY and outside Boulder CITY, so it separates the two halves of
 * this wave. Denver is outside both and must return neither.
 *
 *   node probe-co3.mjs
 */
import pg from 'pg';

const POINTS = [
  { name: 'Boulder City Hall, 1777 Broadway', lon: -105.2797, lat: 40.0175,
    wantCity: 9, wantCounty: 10, wantState: 2 },
  { name: 'Longmont City Hall (in the county, outside the city)', lon: -105.1019, lat: 40.1672,
    wantCity: 0, wantCounty: 10, wantState: 2 },
  { name: 'Denver City Hall (outside both) — negative control', lon: -104.9903, lat: 39.7392,
    wantCity: 0, wantCounty: 0, wantState: 2 },
];

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
await client.query("SET statement_timeout = '180s'");

const AT_POINT = `
  SELECT d.district_type::text AS layer, d.label, d.mtfcc, d.geo_id, o.title,
         g.name AS government, pol.full_name AS holder
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians pol ON pol.id = och.politician_id
  WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
    AND lower(COALESCE(d.state, '')) IN ('co', '08')
  ORDER BY d.district_type::text, o.title`;

let bad = 0;
for (const p of POINTS) {
  const { rows } = await client.query(AT_POINT, [p.lon, p.lat]);
  const city = rows.filter((r) => r.government === 'City of Boulder, Colorado, US');
  const county = rows.filter((r) => r.government === 'Boulder County, Colorado, US');
  const state = rows.filter((r) => r.government === 'State of Colorado'
    && /^State (House|Senate)/.test(String(r.label)));
  console.log(`\n${p.name}`);
  console.log(`   ${rows.length} answer(s): ${city.length} Boulder city, ${county.length} Boulder county, ${state.length} state legislative`);
  for (const r of [...city, ...county, ...state]) {
    console.log(`     ${String(r.title).padEnd(26)} ${r.holder ?? '(VACANT)'}`);
  }
  for (const [label, got, want] of [['city', city.length, p.wantCity],
                                    ['county', county.length, p.wantCounty],
                                    ['state', state.length, p.wantState]]) {
    if (got !== want) { console.log(`   ✗ ${label}: got ${got}, expected ${want}`); bad++; }
  }
  const unseated = [...city, ...county].filter((r) => !r.holder);
  if (unseated.length) { console.log(`   ✗ ${unseated.length} Boulder office(s) with no holder`); bad++; }
  // The four-answer test the programme defines "done" by.
  if (p.wantCity > 0) {
    const kinds = {
      councillor: city.some((r) => /Council Member|Mayor/.test(r.title)),
      commissioner: county.some((r) => /^Commissioner/.test(r.title)),
      representative: state.some((r) => /^State House/.test(String(r.label))),
      senator: state.some((r) => /^State Senate/.test(String(r.label))),
    };
    const missing = Object.entries(kinds).filter(([, v]) => !v).map(([k]) => k);
    console.log(`   four-answer test: ${missing.length ? `✗ missing ${missing.join(', ')}` : '✅ all four kinds returned'}`);
    if (missing.length) bad++;
  }
}

await client.end();
console.log(bad ? `\n✗ ${bad} failure(s)` : '\n✅ every probe and control as expected');
process.exit(bad ? 1 : 0);
