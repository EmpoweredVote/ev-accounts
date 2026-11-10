// emit376.mjs — writes backend/migrations/CC_0376_nh_executive_council.sql
//
// New Hampshire's Executive Council: one chamber, five districts, five offices, the five sitting
// councilors seated from the date the House Journal records their oath, and the five 2026-11-03
// races with all ten candidacies.
//
// Inputs, both produced earlier on this branch and committed beside this file:
//   nh-exec-composition.json — RSA 662:2 joined to the Census gazetteer: every town in the state,
//                              its council district and an internal point. The anchor.
//   nh-exec-returns.json     — the Secretary of State's own per-district return workbooks.
//
// 🔴 THE POLYGONS ARE NOT IN THIS FILE. scripts/CC_0376-nh-exec-geofences.mjs loads them; this
//   migration refuses to run until it has, and gates the whole chain from a point on the ground
//   to a named councilor for ALL 259 towns the statute names.
import fs from 'node:fs';

const WT = 'C:/ev-accounts-nh/backend/data/state-exec-2026-results';
const MIG = 'C:/ev-accounts-nh/backend/migrations';
const COMP = JSON.parse(fs.readFileSync(`${WT}/nh-exec-composition.json`, 'utf8'));
const RET = JSON.parse(fs.readFileSync(`${WT}/nh-exec-returns.json`, 'utf8'));

const SLOT = 'CC_0376';
const N = 5;
const STATE_FIPS = '33';
const MTFCC = 'X-ST-BOARD';
const DTYPE = 'STATE_BOARD';
const PREFIX = 'ocd-division/country:us/state:nh/council:';
const GOVERNMENT_ID = '6541c097-c589-45e2-bcd1-f187c7bf65a1';   // State of New Hampshire
const ELECTION_ID = 'c6fcba79-6b3d-4617-b227-5a745c27f849';     // NH 2026 Statewide General
const ELECTION_DATE = '2026-11-03';
const OATH_2025 = '2025-01-09';
const BASELINE = 238;

const q = s => "'" + String(s).replace(/'/g, "''") + "'";

const HJ = 'https://gc.nh.gov/house/calendars_journals/Journals/2025/HJ%2003%20January%209,%202025.PDF';
const SOS = 'https://www.sos.nh.gov/2026-general-election-results';
const ROSTER = d => `https://www.council.nh.gov/district-${d}`;

// ── The sitting councilors. Names as the body's OWN pages head them, which is also how the House
//    Journal lists them, except that the Journal drops the middle initials.
//    🔴 D5's BALLOT NAME IS NOT HIS ROSTER NAME. The Secretary of State's return sheet carries
//    "Dave Wheeler"; council.nh.gov heads his page "Councilor David K. Wheeler". One person, two
//    forms, and the roster form is the one this file stores — with the ballot form written into
//    the race description so the return can still be traced to the row. Nothing else diverges.
const HOLDERS = [
  { d: 1, who: 'Joseph D. Kenney',  first: 'Joseph', last: 'Kenney',          middle: 'D.',  party: 'r', ballot: 'Joseph D. Kenney' },
  { d: 2, who: 'Karen Liot Hill',   first: 'Karen',  last: 'Liot Hill',       middle: null,  party: 'd', ballot: 'Karen Liot Hill' },
  { d: 3, who: 'Janet Stevens',     first: 'Janet',  last: 'Stevens',         middle: null,  party: 'r', ballot: 'Janet Stevens' },
  { d: 4, who: 'John Stephen',      first: 'John',   last: 'Stephen',         middle: null,  party: 'r', ballot: 'John Stephen' },
  { d: 5, who: 'David K. Wheeler',  first: 'David',  last: 'Wheeler',         middle: 'K.',  party: 'r', ballot: 'Dave Wheeler' },
];
// The challengers, taken from the return sheets. Splits are declared, never derived — two of
// these surnames are two words ("Liot Hill" above, "Kennedy Sheldon" here) and a last-token
// split would get both wrong.
const CHALLENGERS = [
  { d: 1, who: 'Luz Bay',             first: 'Luz',     last: 'Bay',             middle: null },
  { d: 2, who: 'Tobin Menard',        first: 'Tobin',   last: 'Menard',          middle: null },
  { d: 3, who: 'Lisa Kennedy Sheldon',first: 'Lisa',    last: 'Kennedy Sheldon', middle: null },
  { d: 4, who: "Jim O'Connell",       first: 'Jim',     last: "O'Connell",       middle: null },
  { d: 5, who: 'Melanie Levesque',    first: 'Melanie', last: 'Levesque',        middle: null },
];

// ── Resolve every candidacy on the return sheets to one of the ten people above.
const byBallot = new Map();
for (const h of HOLDERS) byBallot.set(h.ballot, h.who);
for (const c of CHALLENGERS) byBallot.set(c.who, c.who);

const calls = [];
for (const r of RET.districts) {
  for (const c of r.candidates) {
    const who = byBallot.get(c.name);
    if (!who) throw new Error(`D${r.district}: the return names "${c.name}", who is in neither roster list`);
    const holder = HOLDERS.find(h => h.d === r.district);
    calls.push({
      d: r.district, who, ballot: c.name, result: c.status, votes: c.votes, party: c.party, partyLetter: c.partyLetter,
      incumbent: who === holder.who,
    });
  }
}
if (calls.length !== 10) throw new Error(`expected 10 candidacies, built ${calls.length}`);
// Every sitting councilor stood again — assert it rather than assume it, because a seat whose
// holder retired would need a different incumbent flag and a different race description.
for (const h of HOLDERS) {
  if (!calls.some(c => c.d === h.d && c.who === h.who)) {
    throw new Error(`D${h.d}: the sitting councilor ${h.who} is not on the 2026 ballot — re-read the race`);
  }
}
// And the party letter the ballot gave each incumbent must match the roster's.
for (const h of HOLDERS) {
  const c = calls.find(x => x.d === h.d && x.who === h.who);
  if (c.partyLetter !== h.party) throw new Error(`D${h.d}: ${h.who} is ${h.party} here and ${c.partyLetter} on the ballot`);
}

const people = new Map();
for (const h of HOLDERS) {
  people.set(h.who, {
    first: h.first, last: h.last, incumbent: true,
    source: `${ROSTER(h.d)} — the body's own roster, whose page is headed "Councilor ${h.who}", read 2026-11-08. ` +
      `Took office ${OATH_2025}: New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE" — ` +
      `"Governor Ayotte administered the oath of office to the Honorable Executive Councilors, Joseph Kenney, ` +
      `Karen Liot Hill, Janet Stevens, John Stephen and David Wheeler", ${HJ} (${SLOT})`,
  });
}
for (const c of CHALLENGERS) {
  const r = RET.districts.find(x => x.district === c.d);
  const row = r.candidates.find(x => x.name === c.who);
  people.set(c.who, {
    first: c.first, last: c.last, incumbent: false,
    source: `New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District ${c.d}" ` +
      `return workbook (${SOS}), read 2026-11-08: ${c.who} (${row.partyLetter}) ${row.votes.toLocaleString('en-US')} ` +
      `votes, ${row.status} (${SLOT})`,
  });
}
if (people.size !== 10) throw new Error(`expected 10 people, built ${people.size}`);

// Middle initials are declared so the name-split gate can allow exactly them and nothing else.
const MIDDLE = [...HOLDERS, ...CHALLENGERS].filter(p => p.middle).map(p => p.who);

const towns = COMP.towns;
const whole = COMP.counties.filter(c => c.whole);

const L = [];
const p = s => L.push(s);
const wrap = (s, w = 96) => {
  const out = []; let line = '';
  for (const word of String(s).split(/\s+/)) {
    if (line && (line + ' ' + word).length > w) { out.push(line); line = word; } else line = line ? line + ' ' + word : word;
  }
  if (line) out.push(line);
  return out;
};
const comment = s => wrap(s).forEach(l => p(`-- ${l}`));

p(`-- ${SLOT}_nh_executive_council.sql`);
p(`--`);
comment(`New Hampshire's Executive Council — the last body in state-executive tier 3. One chamber, five ` +
  `districts, five offices, the five sitting councilors seated, and the five 2026-11-03 races with all ` +
  `ten candidacies recorded.`);
p(`--`);
comment(`WHAT THIS FILE CREATES: 1 chamber - ${N} districts - ${N} offices - ${N} office_terms - ` +
  `${RET.districts.length} races - ${people.size} politicians - ${calls.length} candidacies.`);
p(`--`);
comment(`THE DISTRICTS. RSA 662:2 "Councilor Districts", as amended by 2022 N.H. Laws ch. 46 (SB 241), ` +
  `effective 6 May 2022. New Hampshire states the whole composition in words: every town, city and ` +
  `unincorporated place is named, in exactly one of the five districts. The polygons come from ` +
  `NHGRANIT (nhgeodata.unh.edu), service APB_ElectoralDistricts, layer 7 "NHExecDists2022".`);
p(`--`);
comment(`[RED] LAYER 1 OF THAT SERVICE IS "NHExecCo2012", THE SUPERSEDED MAP, AND ONLY THE YEAR IN THE ` +
  `LAYER NAME TELLS THEM APART. Both are five valid, disjoint polygons covering the whole state; both ` +
  `report the same extent; and measured, the 2012 map covers the TIGER state outline to 99.6836%, the ` +
  `SAME FIGURE AS THE CURRENT MAP TO FOUR DECIMAL PLACES, because both are complete partitions. No ` +
  `structural gate can separate them. The statute can, on 66 of 259 towns, and that is what the anchor ` +
  `table below exists for. The loader's control B is the superseded map itself, not a synthetic tamper.`);
p(`--`);
comment(`[RED] THE CRS TRAP. The NHGRANIT layer is native wkid 3437 — NAD83 New Hampshire State Plane in ` +
  `US SURVEY FEET. Loaded as 4326 it is valid, correctly shaped and matches no address on Earth. The ` +
  `fetcher asks the server for outSR=4326 and bounds-checks every coordinate; the loader checks the ` +
  `bounding boxes again after INSERT; and this file checks them a third time before creating anything.`);
p(`--`);
comment(`[GREEN] THE ANCHOR IS COMPLETE, SO NO DISTRICT IS UNPINNED. Nebraska had to record two pairs of ` +
  `districts that no available evidence could separate, and New Mexico four. New Hampshire has none: ` +
  `the post-verify below walks the full chain — a Census internal point, the geofence polygon that ` +
  `covers it, the district row, the office, the current holder — for ALL ${towns.length} towns the ` +
  `statute names, and every one must reach the councilor RSA 662:2 implies. No permutation of five ` +
  `districts survives that.`);
p(`--`);
comment(`[WARN] ONLY ONE OF THE TEN COUNTIES LIES WHOLLY IN ONE DISTRICT — Carroll, in district 1. The ` +
  `tier-3 inventory predicted several would, and nine of ten are split, Hillsborough four ways. The ` +
  `whole-county gate that carried Alabama and Louisiana would have had a single usable row here and ` +
  `would have LOOKED anchored. It is kept below as corroboration, not as the anchor.`);
p(`--`);
comment(`THE PEOPLE. All five sitting councilors took office on ${OATH_2025}, from the primary record: ` +
  `New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE" — "Governor Ayotte administered ` +
  `the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet ` +
  `Stevens, John Stephen and David Wheeler". The same Journal seats the councilors-elect by district, ` +
  `which is a second source for the district assignments beside council.nh.gov's own pages.`);
p(`--`);
comment(`[RED] A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT, AND NONE OF THESE WINNERS HOLDS ` +
  `ONE YET. Four of the five sitting councilors were defeated on ${ELECTION_DATE}; they remain in office ` +
  `until the oath is administered in January 2027. This file seats the CURRENT holders and records the ` +
  `winners as race results only.`);
p(`--`);
comment(`[RED] AND THE HANDOVER DATE IS NOT KNOWN YET, SO IT IS NOT WRITTEN DOWN. N.H. Const. pt. 2, art. ` +
  `60 fixes when the votes are LAID BEFORE the General Court — "the first Wednesday following the first ` +
  `Tuesday of January", which is 2027-01-06 — and that is a date for the COUNT, not for the oath. In ` +
  `2025 the votes went before them on Wednesday 8 January and the Joint Convention administered the ` +
  `oath on Thursday 9 January. Read the date a source gives before reusing it: the constitutional date ` +
  `is one day early at best and is a date of a different event. The follow-up below says to read the ` +
  `House Journal, not to assume a day.`);
p(`--`);
comment(`[WARN] THE RESULTS ARE RETURNS, NOT A CANVASS. The Secretary of State's page states: "Tallies ` +
  `accurately reflect the returns of votes reported by clerks but are subject to change if clerks ` +
  `submit amendments." Every candidacy is recorded with result_certainty 'called'.`);
p(`--`);
comment(`NO READ-PATH CHANGE IS NEEDED. These seats file under (${MTFCC}, ${DTYPE}), which CC_0366 ` +
  `registered in districtQueries.ts and geoIdGuard.ts and which is on master.`);
p(`--`);
comment(`FOLLOW-UP, January 2027: seat Luz Bay (D1), Karen Liot Hill (D2, re-elected), Lisa Kennedy ` +
  `Sheldon (D3), Jim O'Connell (D4) and Melanie Levesque (D5), on the date the House Journal records ` +
  `the oath. Close the four defeated councilors' terms the day before.`);
p(`--`);
comment(`PREREQUISITE: node scripts/CC_0376-nh-exec-geofences.mjs --geojson ... --composition ... must ` +
  `have run and committed. This file refuses otherwise.`);
p(``);
p(`BEGIN;`);
p(``);

// ── reference tables
p(`-- The seats, their sitting holders, and whether a 2026 race is recorded for each.`);
p(`CREATE TEMP TABLE seat (`);
p(`  d int PRIMARY KEY, who text NOT NULL, party text NOT NULL, race_recorded boolean NOT NULL`);
p(`) ON COMMIT DROP;`);
p(`INSERT INTO seat VALUES`);
p(HOLDERS.map(h => `  (${h.d}, ${q(h.who)}, ${q(h.party)}, true)`).join(',\n') + ';');
p(``);
p(`-- 🟢 THE ANCHOR: every town, city and unincorporated place RSA 662:2 names, with the Census`);
p(`--    Bureau's internal point for it. Neither column comes from the NHGRANIT map.`);
p(`CREATE TEMP TABLE anchor (`);
p(`  town text PRIMARY KEY, county text NOT NULL, d int NOT NULL, lon float8 NOT NULL, lat float8 NOT NULL`);
p(`) ON COMMIT DROP;`);
p(`INSERT INTO anchor VALUES`);
p(towns.map(t => `  (${q(t.statuteName)}, ${q(t.countyName)}, ${t.district}, ${t.lon}, ${t.lat})`).join(',\n') + ';');
p(``);
p(`-- The county composition, derived from the same statute. One whole, nine split.`);
p(`CREATE TEMP TABLE plan_county (county text PRIMARY KEY, districts text NOT NULL, whole boolean NOT NULL) ON COMMIT DROP;`);
p(`INSERT INTO plan_county VALUES`);
p(COMP.counties.map(c => `  (${q(c.name + ' County')}, ${q(c.districts.join(','))}, ${c.whole})`).join(',\n') + ';');
p(``);

p(`DO $$ DECLARE n int; txt text; BEGIN`);
p(`  SELECT count(*) INTO n FROM seat;   IF n <> ${N} THEN RAISE EXCEPTION 'expected ${N} seats, found %', n; END IF;`);
p(`  SELECT count(*) INTO n FROM anchor; IF n <> ${towns.length} THEN RAISE EXCEPTION 'expected ${towns.length} anchors, found %', n; END IF;`);
p(`  SELECT count(*) INTO n FROM plan_county; IF n <> 10 THEN RAISE EXCEPTION 'expected New Hampshire''s 10 counties, found %', n; END IF;`);
p(`  SELECT count(*) INTO n FROM plan_county WHERE whole;`);
p(`  IF n <> ${whole.length} THEN RAISE EXCEPTION 'expected ${whole.length} whole county, found %', n; END IF;`);
p(`  -- every district must carry enough anchors that a label swap cannot hide`);
p(`  SELECT string_agg('D' || z.d || '=' || z.n, ', ') INTO txt FROM (SELECT d, count(*) n FROM anchor GROUP BY d) z WHERE z.n < 15;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a district has too few anchors to pin it: %', txt; END IF;`);
p(`  SELECT count(DISTINCT d) INTO n FROM anchor; IF n <> ${N} THEN RAISE EXCEPTION 'the anchors cover % districts', n; END IF;`);
p(`  -- the counties the anchors fall in must be the ten we hold polygons for`);
p(`  SELECT string_agg(pc.county, ', ') INTO txt FROM plan_county pc`);
p(`   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g`);
p(`                      WHERE g.mtfcc = 'G4020' AND g.state = '${STATE_FIPS}' AND g.name = pc.county);`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'we hold no county polygon for: %', txt; END IF;`);
p(``);
p(`  -- preconditions on rows this file does not create`);
p(`  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = '${GOVERNMENT_ID}'::uuid AND name = 'State of New Hampshire')`);
p(`    THEN RAISE EXCEPTION 'the New Hampshire government row does not exist'; END IF;`);
p(`  IF NOT EXISTS (SELECT 1 FROM essentials.elections WHERE id = '${ELECTION_ID}'::uuid AND election_date = DATE '${ELECTION_DATE}')`);
p(`    THEN RAISE EXCEPTION 'the election row is not the ${ELECTION_DATE} New Hampshire general'; END IF;`);
p(``);
p(`  -- idempotence: this file creates, so nothing it creates may already be there`);
p(`  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE government_id = '${GOVERNMENT_ID}'::uuid AND name = 'Executive Council')`);
p(`    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;`);
p(`  SELECT count(*) INTO n FROM essentials.districts WHERE geo_id LIKE ${q(PREFIX + '%')};`);
p(`  IF n <> 0 THEN RAISE EXCEPTION '% district(s) with this body''s geo_id prefix already exist', n; END IF;`);
p(``);
p(`  -- 🔴 THE POLYGONS MUST BE LOADED, AND THEY MUST BE NEW HAMPSHIRE IN 4326.`);
p(`  SELECT count(*) INTO n FROM essentials.geofence_boundaries`);
p(`   WHERE mtfcc = '${MTFCC}' AND state = '${STATE_FIPS}' AND geo_id LIKE ${q(PREFIX + '%')};`);
p(`  IF n <> ${N} THEN RAISE EXCEPTION 'only % of the ${N} councilor polygons are loaded — run scripts/CC_0376-nh-exec-geofences.mjs first', n; END IF;`);
p(`  SELECT string_agg(g.geo_id || ' srid=' || public.ST_SRID(g.geometry) || ' bbox=' ||`);
p(`           round(public.ST_XMin(g.geometry)::numeric,3) || ',' || round(public.ST_YMin(g.geometry)::numeric,3) || '..' ||`);
p(`           round(public.ST_XMax(g.geometry)::numeric,3) || ',' || round(public.ST_YMax(g.geometry)::numeric,3), '; ') INTO txt`);
p(`    FROM essentials.geofence_boundaries g`);
p(`   WHERE g.mtfcc = '${MTFCC}' AND g.state = '${STATE_FIPS}' AND g.geo_id LIKE ${q(PREFIX + '%')}`);
p(`     AND (public.ST_SRID(g.geometry) <> 4326 OR NOT public.ST_IsValid(g.geometry) OR public.ST_IsEmpty(g.geometry)`);
p(`          OR public.ST_XMin(g.geometry) < -72.8 OR public.ST_XMax(g.geometry) > -70.4`);
p(`          OR public.ST_YMin(g.geometry) < 42.5  OR public.ST_YMax(g.geometry) > 45.5);`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loaded polygon is not a valid 4326 New Hampshire polygon (wrong CRS?): %', txt; END IF;`);
p(``);
p(`  -- 🟢 and the map agrees with the statute, for every town, BEFORE anything is created`);
p(`  SELECT string_agg(z.town || ': statute D' || z.d || ', map ' || coalesce(z.got, 'NOWHERE'), '; ') INTO txt`);
p(`    FROM (SELECT a.town, a.d,`);
p(`                 (SELECT string_agg(replace(g.geo_id, ${q(PREFIX)}, ''), ',')`);
p(`                    FROM essentials.geofence_boundaries g`);
p(`                   WHERE g.mtfcc = '${MTFCC}' AND g.state = '${STATE_FIPS}' AND g.geo_id LIKE ${q(PREFIX + '%')}`);
p(`                     AND public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(a.lon, a.lat), 4326))) AS got`);
p(`            FROM anchor a) z`);
p(`   WHERE z.got IS DISTINCT FROM z.d::text;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the map and RSA 662:2 disagree about which district a town is in: %', left(txt, 900); END IF;`);
p(``);
p(`  -- the coarse county view, as corroboration`);
p(`  SELECT string_agg(pc.county || ' -> ' || coalesce(z.got, 'nothing') || ' (statute ' || pc.districts || ')', '; ') INTO txt`);
p(`    FROM plan_county pc`);
p(`    LEFT JOIN LATERAL (`);
p(`      SELECT string_agg(replace(g.geo_id, ${q(PREFIX)}, ''), ',' ORDER BY (replace(g.geo_id, ${q(PREFIX)}, ''))::int) AS got`);
p(`        FROM essentials.geofence_boundaries co, essentials.geofence_boundaries g`);
p(`       WHERE co.mtfcc = 'G4020' AND co.state = '${STATE_FIPS}' AND co.name = pc.county`);
p(`         AND g.mtfcc = '${MTFCC}' AND g.state = '${STATE_FIPS}' AND g.geo_id LIKE ${q(PREFIX + '%')}`);
p(`         AND public.ST_Area(public.ST_Intersection(g.geometry, co.geometry)) > public.ST_Area(co.geometry) * 0.0005) z ON true`);
p(`   WHERE z.got IS DISTINCT FROM pc.districts;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county is shared by districts RSA 662:2 does not name: %', txt; END IF;`);
p(`END $$;`);
p(``);

// ── chamber, districts, offices
p(`-- ─── Chamber, districts, offices ───`);
p(`CREATE TEMP TABLE made_chamber (chamber_id uuid NOT NULL) ON COMMIT DROP;`);
p(`WITH ins AS (`);
p(`  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,`);
p(`                                   official_count, term_length, staggered_term, website_url,`);
p(`                                   inauguration_rules, election_rules, remarks)`);
p(`  VALUES ('Executive Council', 'New Hampshire Executive Council', '${GOVERNMENT_ID}'::uuid, 'full', ${N},`);
p(`          '2 years', false, 'https://www.council.nh.gov/',`);
p(`          ${q(`All five councilors are elected together at every biennial general election; the council is NOT staggered. ` +
  `N.H. Const. pt. 2, art. 60 requires the returns to be laid before the Senate and House "on the first Wednesday ` +
  `following the first Tuesday of January" — that is the date of the COUNT, not of the oath. The oath is ` +
  `administered afterwards at a Joint Convention: in 2025 the votes went before the General Court on Wednesday ` +
  `8 January and Governor Ayotte swore the councilors in on Thursday 9 January (House Journal No. 3). For the ` +
  `2027 handover read the House Journal for the Joint Convention; do not assume 2027-01-06.`)},`);
p(`          ${q(`Five single-member districts, one councilor each, elected by plurality (N.H. Const. pt. 2, art. 61, ` +
  `amended 1912 substituting plurality for majority). Districts are set by RSA 662:2, as amended by 2022 N.H. ` +
  `Laws ch. 46 (SB 241), eff. 6 May 2022, which names every town, city and unincorporated place in the state.`)},`);
p(`          ${q(`Advises and consents to the Governor on appointments, contracts and pardons. Created by ${SLOT}; ` +
  `polygons from NHGRANIT layer 7 NHExecDists2022, anchored on RSA 662:2 via all ${towns.length} New Hampshire ` +
  `county subdivisions.`)})`);
p(`  RETURNING id)`);
p(`INSERT INTO made_chamber SELECT id FROM ins;`);
p(``);
p(`CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;`);
p(`WITH ins AS (`);
p(`  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)`);
p(`  SELECT '${DTYPE}', 'nh', ${q(PREFIX)} || s.d, ${q(PREFIX)} || s.d,`);
p(`         'New Hampshire Executive Council District ' || s.d, '${MTFCC}', s.d::text, 'residency'`);
p(`    FROM seat s RETURNING id, geo_id)`);
p(`INSERT INTO made_district SELECT replace(ins.geo_id, ${q(PREFIX)}, '')::int, ins.id FROM ins;`);
p(``);
p(`CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;`);
p(`WITH ins AS (`);
p(`  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,`);
p(`                                  is_vacant, faces_retention_vote, is_appointed_position, description)`);
p(`  SELECT 'Executive Councilor, District ' || s.d, mc.chamber_id, md.district_id, 'NH', 'full',`);
p(`         false, false, false, 'seat:' || s.d`);
p(`    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc`);
p(`  RETURNING id, description)`);
p(`INSERT INTO made_office SELECT replace(ins.description, 'seat:', '')::int, ins.id FROM ins;`);
p(`UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;`);
p(``);
p(`DO $$ DECLARE n int; txt text; BEGIN`);
p(`  SELECT count(*) INTO n FROM made_district; IF n <> ${N} THEN RAISE EXCEPTION 'only % districts were created', n; END IF;`);
p(`  SELECT count(*) INTO n FROM made_office;   IF n <> ${N} THEN RAISE EXCEPTION 'only % offices were created', n; END IF;`);
p(`  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;`);
p(`  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;`);
p(`  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id`);
p(`    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;`);
p(`  IF n <> ${N} THEN RAISE EXCEPTION 'only % of the ${N} districts meet a geofence row on (geo_id, mtfcc)', n; END IF;`);
p(``);
p(`  -- 🔴🔴 EVERY NUMBER ON A ROW MUST BE THE SAME NUMBER. A control that swapped which polygon`);
p(`  --    districts 1 and 3 point at reported DRY RUN OK and the chain gate never fired: the`);
p(`  --    district->office join keys on a number DERIVED FROM the geo_id, so the swap cancelled`);
p(`  --    itself and left only a district whose LABEL disagreed with its geo_id. Nothing checked`);
p(`  --    that, and a voter would have been shown "District 1" for the District 3 map. These two`);
p(`  --    gates exist because that control passed.`);
p(`  SELECT string_agg(d.label || ' carries geo_id ' || d.geo_id || ' and district_id ' || d.district_id, '; ') INTO txt`);
p(`    FROM made_district md JOIN essentials.districts d ON d.id = md.district_id`);
p(`   WHERE d.label <> 'New Hampshire Executive Council District ' || replace(d.geo_id, ${q(PREFIX)}, '')`);
p(`      OR d.district_id <> replace(d.geo_id, ${q(PREFIX)}, '');`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a district''s label or district_id disagrees with its geo_id: %', txt; END IF;`);
p(``);
p(`  SELECT string_agg(o.title || ' sits on ' || d.geo_id, '; ') INTO txt`);
p(`    FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id`);
p(`    JOIN essentials.districts d ON d.id = o.district_id`);
p(`   WHERE o.title <> 'Executive Councilor, District ' || replace(d.geo_id, ${q(PREFIX)}, '');`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an office sits on a district with a different number: %', txt; END IF;`);
p(`END $$;`);
p(``);

// ── people
p(`-- ─── The people ───`);
p(`CREATE TEMP TABLE seed_people (`);
p(`  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL`);
p(`) ON COMMIT DROP;`);
p(`INSERT INTO seed_people VALUES`);
p([...people.entries()].map(([n, v]) => `  (${q(n)}, ${q(v.first)}, ${q(v.last)},\n   ${q(v.source)})`).join(',\n') + ';');
p(``);
p(`-- Names carrying a middle initial, so the split gate can allow exactly these and nothing else.`);
p(`CREATE TEMP TABLE middle_initial (full_name text PRIMARY KEY) ON COMMIT DROP;`);
p(`INSERT INTO middle_initial VALUES ${MIDDLE.map(m => `(${q(m)})`).join(', ')};`);
p(``);
p(`CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$`);
p(`  SELECT lower(translate(coalesce(t, ''), 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',`);
p(`                                          'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc'))`);
p(`$f$;`);
p(``);
p(`CREATE TEMP TABLE pol_keys ON COMMIT DROP AS`);
p(`SELECT id, full_name, first_name, last_name, is_active, source,`);
p(`       pg_temp.namekey(full_name) AS k_full, pg_temp.namekey(first_name) AS k_first, pg_temp.namekey(last_name) AS k_last`);
p(`  FROM essentials.politicians;`);
p(`CREATE INDEX ON pol_keys (k_full);`);
p(`CREATE INDEX ON pol_keys (k_first, k_last);`);
p(`ANALYZE pol_keys;`);
p(``);
p(`DO $$ DECLARE txt text; n int; BEGIN`);
p(`  -- 🔴 A POSITIVE CONTROL ON BOTH ARMS, so a sweep that finds nothing is a clean sweep and not a`);
p(`  --   blind one. Both probes name people this repo is known to hold.`);
p(`  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Kelly Ayotte');`);
p(`  IF n < 1 THEN RAISE EXCEPTION 'the full-name index cannot see a politician known to exist'; END IF;`);
p(`  SELECT count(*) INTO n FROM pol_keys WHERE k_first = pg_temp.namekey('Paul') AND k_last = pg_temp.namekey('Kenney');`);
p(`  IF n < 1 THEN RAISE EXCEPTION 'the (first, last) index cannot see a politician known to exist'; END IF;`);
p(`  SELECT count(*) INTO n FROM pol_keys; IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows', n; END IF;`);
p(``);
p(`  -- 🔴🔴 A NAMESAKE REACHES PRODUCTION AND NOTHING ERRORS. Both arms, because the duplicate-name`);
p(`  --   guard keys on (first, last) and a differently-split identical full_name is invisible to it.`);
p(`  SELECT string_agg(z.msg, '; ') INTO txt FROM (`);
p(`    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ')' AS msg`);
p(`      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)`);
p(`     WHERE p.source IS DISTINCT FROM s.source`);
p(`    UNION`);
p(`    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'`);
p(`      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name)`);
p(`     WHERE p.source IS DISTINCT FROM s.source) z;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;`);
p(``);
p(`  -- the split must reproduce the name, allowing exactly the declared middle initials`);
p(`  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt`);
p(`    FROM seed_people s`);
p(`   WHERE s.full_name <> s.first_name || ' ' || s.last_name`);
p(`     AND NOT (s.full_name IN (SELECT full_name FROM middle_initial)`);
p(`              AND s.full_name ~ ('^' || s.first_name || ' [A-Z]\\. ' || replace(s.last_name, '''', '''''') || '$'));`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;`);
p(``);
p(`  SELECT string_agg(s.full_name, '; ') INTO txt FROM seed_people s`);
p(`   WHERE s.source NOT LIKE 'https://www.council.nh.gov/%' AND s.source NOT LIKE 'New Hampshire Secretary of State%';`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is neither the council''s own roster nor the Secretary of State: %', txt; END IF;`);
p(`END $$;`);
p(``);
p(`SET LOCAL essentials.allow_duplicate_name = 'on';`);
p(`INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)`);
p(`SELECT s.full_name, s.first_name, s.last_name, s.source, true,`);
p(`       EXISTS (SELECT 1 FROM seat st WHERE st.who = s.full_name)`);
p(`  FROM seed_people s`);
p(` WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source);`);
p(`SET LOCAL essentials.allow_duplicate_name = 'off';`);
p(``);
p(`CREATE TEMP TABLE person (who text PRIMARY KEY, pid uuid NOT NULL) ON COMMIT DROP;`);
p(`INSERT INTO person SELECT s.full_name, p.id FROM seed_people s`);
p(`  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;`);
p(`DO $$ DECLARE n int; BEGIN SELECT count(*) INTO n FROM person;`);
p(`  IF n <> ${people.size} THEN RAISE EXCEPTION 'only % of the ${people.size} people resolved to exactly one row', n; END IF;`);
p(`  -- 🔴 is_incumbent is a cached flag the incumbents-only reads filter on, and it defaults to`);
p(`  --   false. The five sitting councilors must carry true and the five challengers false.`);
p(`  SELECT count(*) INTO n FROM person pe JOIN essentials.politicians p ON p.id = pe.pid`);
p(`   WHERE p.is_incumbent <> EXISTS (SELECT 1 FROM seat s WHERE s.who = pe.who);`);
p(`  IF n <> 0 THEN RAISE EXCEPTION '% seeded person(s) carry the wrong is_incumbent', n; END IF;`);
p(`END $$;`);
p(``);

// ── seating
p(`-- ─── Seat the five sitting councilors ───`);
p(`-- 🔴 THE DATE IS THE DAY OF THE OATH, FROM THE HOUSE JOURNAL, not the day of the election and`);
p(`--    not the constitutional counting day. All five were sworn together on ${OATH_2025}.`);
p(`INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)`);
p(`SELECT mo.office_id, pe.pid, DATE '${OATH_2025}', NULL, 'day', 'elected',`);
p(`       ${q(`New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE": "Governor Ayotte administered ` +
  `the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet Stevens, John ` +
  `Stephen and David Wheeler." ${HJ}. District assignments from the same Journal (the councilors-elect are seated ` +
  `by district) and from council.nh.gov's own district pages, both read 2026-11-08 (${SLOT})`)}`);
p(`  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;`);
p(``);

// ── races
p(`-- ─── The ${RET.districts.length} races and their results ───`);
p(`INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)`);
p(`SELECT '${ELECTION_ID}'::uuid, mo.office_id, 'New Hampshire Executive Council District ' || s.d, NULL, 1,`);
p(`       CASE s.d`);
for (const r of RET.districts) {
  const h = HOLDERS.find(x => x.d === r.district);
  const desc = `The seat held by ${h.who}. ` +
    r.candidates.map(c => `${c.name} (${c.party}) ${c.votes.toLocaleString('en-US')}`).join(', ') +
    `; ${r.writeIns} write-in${r.writeIns === 1 ? '' : 's'}; ${r.ballotsCounted.toLocaleString('en-US')} ballots counted across ` +
    `${r.distinctPlaces} towns and cities. Returns reported by town clerks to the Secretary of State and ` +
    `subject to amendment; not a certified canvass.` +
    (h.ballot !== h.who ? ` The return sheet gives the incumbent's ballot name as "${h.ballot}"; council.nh.gov heads his page "${h.who}".` : '');
  p(`         WHEN ${r.district} THEN ${q(desc)}`);
}
p(`         ELSE NULL END`);
p(`  FROM seat s JOIN made_office mo ON mo.d = s.d WHERE s.race_recorded;`);
p(``);
p(`CREATE TEMP TABLE calls (`);
p(`  d int NOT NULL, who text NOT NULL, result text NOT NULL, votes int NOT NULL,`);
p(`  is_incumbent boolean NOT NULL, PRIMARY KEY (d, who)`);
p(`) ON COMMIT DROP;`);
p(`INSERT INTO calls VALUES`);
p(calls.map(c => `  (${c.d}, ${q(c.who)}, ${q(c.result)}, ${c.votes}, ${c.incumbent})`).join(',\n') + ';');
p(``);
p(`DO $$ DECLARE n int; txt text; BEGIN`);
p(`  SELECT count(*) INTO n FROM calls; IF n <> ${calls.length} THEN RAISE EXCEPTION 'expected ${calls.length} candidacies, found %', n; END IF;`);
p(`  SELECT string_agg('D' || z.d || ': ' || z.w || ' winner(s)', '; ') INTO txt FROM (`);
p(`    SELECT c.d, count(*) FILTER (WHERE c.result = 'won') w FROM calls c GROUP BY c.d) z WHERE z.w <> 1;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a single-seat race does not hold exactly one winner: %', txt; END IF;`);
p(`  -- 🔴 A "won" FLAG AND A VOTE COUNT ARE TWO SEPARATE FACTS. This is where they are made to agree,`);
p(`  --   and it is why no loser is inferred from "not the winner" — each carries its own status.`);
p(`  SELECT string_agg('D' || z.d, ', ') INTO txt FROM (`);
p(`    SELECT c.d FROM calls c GROUP BY c.d`);
p(`    HAVING max(c.votes) FILTER (WHERE c.result = 'won') < max(c.votes)) z;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the winner is not the leading candidate in: %', txt; END IF;`);
p(`  SELECT string_agg(c.who, '; ') INTO txt FROM calls c LEFT JOIN person pe ON pe.who = c.who WHERE pe.pid IS NULL;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy resolves to no person: %', txt; END IF;`);
p(`  SELECT string_agg(c.who || ' in D' || c.d, '; ') INTO txt FROM calls c JOIN seat s ON s.d = c.d`);
p(`   WHERE c.is_incumbent <> (s.who = c.who);`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an incumbent flag disagrees with the seat''s holder: %', txt; END IF;`);
p(`  -- every seat's sitting holder stood again, so each race carries exactly one incumbent`);
p(`  SELECT string_agg('D' || z.d || '=' || z.k, ', ') INTO txt FROM (`);
p(`    SELECT c.d, count(*) FILTER (WHERE c.is_incumbent) k FROM calls c GROUP BY c.d) z WHERE z.k <> 1;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race does not carry exactly one incumbent: %', txt; END IF;`);
p(`END $$;`);
p(``);
p(`INSERT INTO essentials.race_candidates`);
p(`  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,`);
p(`   is_write_in, source, result, result_certainty, result_source, result_recorded_at)`);
p(`SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, c.is_incumbent, 'active', false,`);
p(`       ${q(`New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District N" return workbooks (${SOS}), read 2026-11-08 (${SLOT})`)},`);
p(`       c.result, 'called',`);
p(`       ${q(`New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District N" return workbooks (${SOS}), read 2026-11-08. Returns as reported by town clerks, subject to amendment; not a certified canvass (${SLOT})`)}, now()`);
p(`  FROM calls c JOIN made_office mo ON mo.d = c.d`);
p(`  JOIN essentials.races r ON r.office_id = mo.office_id`);
p(`  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '${ELECTION_DATE}'`);
p(`  JOIN person pe ON pe.who = c.who JOIN essentials.politicians pl ON pl.id = pe.pid;`);
p(``);

// ── post-verify
p(`-- ─── Post-verify ───`);
p(`DO $$ DECLARE n int; txt text; BEGIN`);
p(`  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.d = s.d`);
p(`    JOIN essentials.races r ON r.office_id = mo.office_id WHERE s.race_recorded;`);
p(`  IF n <> ${RET.districts.length} THEN RAISE EXCEPTION 'expected ${RET.districts.length} new races, found %', n; END IF;`);
p(`  SELECT count(*) INTO n FROM calls c JOIN made_office mo ON mo.d = c.d`);
p(`    JOIN essentials.races r ON r.office_id = mo.office_id`);
p(`    JOIN person pe ON pe.who = c.who`);
p(`    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid`);
p(`   WHERE rc.result = c.result AND rc.result_certainty = 'called';`);
p(`  IF n <> ${calls.length} THEN RAISE EXCEPTION 'only % of the ${calls.length} candidacies hold their stated result', n; END IF;`);
p(``);
p(`  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED. Creating an office is an`);
p(`  --    occupancy act: an unseated one RAISES the baseline, and the baseline must never be raised.`);
p(`  SELECT count(*) INTO n FROM made_office mo`);
p(`   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);`);
p(`  IF n <> 0 THEN RAISE EXCEPTION '% of the ${N} offices have no term and would raise the drift metric', n; END IF;`);
p(`  SELECT count(*) INTO n FROM essentials.offices_missing_terms m`);
p(`    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;`);
p(`  IF n <> ${BASELINE} THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was ${BASELINE} and must never be raised', n; END IF;`);
p(``);
p(`  SELECT count(*) INTO n FROM made_chamber mc JOIN essentials.offices o ON o.chamber_id = mc.chamber_id;`);
p(`  IF n <> ${N} THEN RAISE EXCEPTION 'the chamber holds % offices, not ${N}', n; END IF;`);
p(`  SELECT official_count INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id;`);
p(`  IF n <> ${N} THEN RAISE EXCEPTION 'official_count is %, not ${N}', n; END IF;`);
p(`  -- 🔴 the chamber must record that art. 60's January date is the COUNT, not the oath, or a`);
p(`  --   December pass will read 2027-01-06 as a handover date and seat five people a day early.`);
p(`  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id`);
p(`   WHERE ch.inauguration_rules ILIKE '%not of the oath%' AND ch.inauguration_rules ILIKE '%2027-01-06%';`);
p(`  IF n <> 1 THEN RAISE EXCEPTION 'the chamber does not warn that the constitutional January date is the count, not the oath'; END IF;`);
p(`  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id WHERE ch.staggered_term;`);
p(`  IF n <> 0 THEN RAISE EXCEPTION 'the council is recorded as staggered; all five seats are elected together'; END IF;`);
p(``);
p(`  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id`);
p(`   WHERE t.term_start <> DATE '${OATH_2025}' OR t.term_end IS NOT NULL OR t.start_precision <> 'day';`);
p(`  IF n <> 0 THEN RAISE EXCEPTION '% term(s) do not carry the ${OATH_2025} oath date', n; END IF;`);
p(``);
p(`  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED COUNCILOR, FOR ALL ${towns.length} TOWNS.`);
p(`  --    This is the gate the superseded 2012 map fails and every structural gate passes.`);
p(`  SELECT string_agg(a.town || ' -> ' || coalesce(x.who, 'nobody'), '; ') INTO txt`);
p(`    FROM anchor a`);
p(`    JOIN seat s ON s.d = a.d`);
p(`    LEFT JOIN LATERAL (`);
p(`      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who`);
p(`        FROM essentials.geofence_boundaries gb`);
p(`        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc AND dd.district_type = '${DTYPE}'`);
p(`        JOIN essentials.offices o ON o.district_id = dd.id`);
p(`        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL`);
p(`        JOIN essentials.politicians pl ON pl.id = och.politician_id`);
p(`       WHERE gb.mtfcc = '${MTFCC}' AND gb.state = '${STATE_FIPS}' AND gb.geo_id LIKE ${q(PREFIX + '%')}`);
p(`         AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(a.lon, a.lat), 4326))) x ON true`);
p(`   WHERE x.who IS DISTINCT FROM s.who;`);
p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a town does not reach the councilor RSA 662:2 gives it: %', left(txt, 900); END IF;`);
p(`  SELECT count(*) INTO n FROM anchor; IF n <> ${towns.length} THEN RAISE EXCEPTION 'the chain gate examined % towns', n; END IF;`);
p(``);
p(`  RAISE NOTICE '${SLOT} OK — ${N} New Hampshire Executive Council seats created and seated, ${RET.districts.length} races, ${calls.length} candidacies, ${people.size} people, ${towns.length} towns reach their councilor.';`);
p(`END $$;`);
p(``);
p(`COMMIT;`);

const out = `${MIG}/${SLOT}_nh_executive_council.sql`;
fs.writeFileSync(out, L.join('\n') + '\n');
console.error(`${out} (${fs.statSync(out).size} bytes, ${L.length} lines)`);
console.error(`  ${N} seats · ${RET.districts.length} races · ${calls.length} candidacies · ${people.size} people · ${towns.length} anchors · ${whole.length} whole county`);
