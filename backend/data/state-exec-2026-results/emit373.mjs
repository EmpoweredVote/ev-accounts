// Emit CC_0373, CC_0374 and CC_0375 from the committed data file, the committed canvass parse
// and the committed enacted-plan population table.
//
// 🟢 FIFTH USE OF THE emit369 TEMPLATE, and the first that emits three migrations from one run.
//    What is new here:
//    1. THERE IS NO STATUTE TO GATE ON. Nebraska redistricts its boards by adopting maps by
//       reference, so the composition arm is built from the Secretary of State's certified
//       canvass books — which counties actually voted in which district's race.
//    2. TWO BODIES SHARE ONE MTFCC IN ONE STATE. The Public Service Commission and the Board of
//       Regents are both (X-ST-BOARD, STATE_BOARD) in Nebraska, so every pre-gate that used to
//       count "the rows of this mtfcc in this state" has to count "the rows of this mtfcc in
//       this state WITH THIS GEO_ID PREFIX" instead. CC_0374 and CC_0375 would otherwise each
//       refuse to run after the other had.
//    3. NO AGGREGATOR IS IN THE CHAIN. Holders come from each body's own roster page and
//       results from the Secretary of State's own results service.
//
// 🔴 Carried over and still load-bearing: the anchor table states the member's name as a
//    literal (CC_0369 control C); the point-to-member chain is what catches a wrong
//    office-to-district join (CC_0370 control D); and there is no ::geography cast anywhere in
//    the SQL (ev-cto decision 0006) — every area test is a ratio of planar areas.
import fs from 'node:fs';

const WT = 'C:/ev-accounts-stateexec/backend/data/state-exec-2026-results';
const MIG = 'C:/ev-accounts-stateexec/backend/migrations';
const J = JSON.parse(fs.readFileSync(`${WT}/ne-boards-2026-11-07.json`, 'utf8'));
const PLAN = JSON.parse(fs.readFileSync(`${WT}/ne-plan-populations-2026-11-07.json`, 'utf8'));

const STATE_FIPS = '31';
const SHARE_FLOOR = 0.001;   // 0.1% — measured; the smallest real split is Burt's 1.8769%
const LEAK_CEILING = 0.0001; // 0.01% — measured; the largest spurious share is 0.006454%
const WHOLE_FLOOR = 0.999;   // 99.9% — measured; the worst real containment is 99.9932%
const TERM_START = '2027-01-07';

const q = s => "'" + String(s).replace(/'/g, "''") + "'";
const split = n => {
  const i = n.lastIndexOf(' ');
  if (i < 1) throw new Error(`cannot split "${n}"`);
  return [n.slice(0, i), n.slice(i + 1)];
};

const FILES = [];

for (const B of J.bodies) {
  const CO = JSON.parse(fs.readFileSync(`${WT}/${B.countiesFile}`, 'utf8'));
  const POP = PLAN.populations[B.key];
  const PREFIX = B.prefix;
  const MTFCC = B.mtfcc;
  const DTYPE = B.districtType;
  const N = B.seats.length;

  if (N !== B.officialCount) throw new Error(`${B.key}: ${N} seats for official_count ${B.officialCount}`);
  if (CO.whole.length + CO.split.length !== 93) throw new Error(`${B.key}: the county table is not 93 counties`);
  if (Object.keys(POP).length !== N) throw new Error(`${B.key}: the plan population table is not ${N} districts`);

  // ─── people ───
  const people = new Map();
  const calls = [];
  const add = (n, source) => { if (!people.has(n)) { const [f, l] = split(n); people.set(n, { first: f, last: l, source }); } };
  const holderSource = `${B.rosterUrl} (the body's own roster, read 2026-11-07) — ${B.slot}`;
  const resultSource = `Nebraska Secretary of State, 2026 General Election results, ${B.resultsUrl}, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — ${B.slot}`;

  for (const s of B.seats) add(s.holder, holderSource);
  for (const r of B.races) {
    const seat = B.seats.find(s => s.district === r.district);
    if (!seat) throw new Error(`${B.key}: a race for district ${r.district} with no seat`);
    if (!seat.raceRecorded) throw new Error(`${B.key}: a race is recorded for D${r.district}, whose seat says otherwise`);
    const wins = r.candidates.filter(c => c.won).length;
    if (wins !== 1) throw new Error(`${B.key} D${r.district}: ${wins} winners`);
    for (const c of r.candidates) {
      add(c.name, resultSource);
      calls.push({ d: r.district, who: c.name, result: c.won ? 'won' : 'lost', votes: c.votes, party: c.party, incumbent: c.name === seat.holder });
    }
  }
  for (const s of B.seats) {
    if (s.raceRecorded && !s.onBallot2026) throw new Error(`${B.key} D${s.district}: a race on a seat not on the ballot`);
    if (s.onBallot2026 && !s.raceRecorded) throw new Error(`${B.key} D${s.district}: on the ballot with no race — say so deliberately if that is right`);
  }

  const nRaces = B.races.length;
  const nBallot = B.seats.filter(s => s.onBallot2026).length;
  const nAnchors = B.anchors.length;
  const winners = calls.filter(c => c.result === 'won');
  const newcomers = winners.filter(c => !B.seats.some(s => s.district === c.d && s.holder === c.who));

  // every anchor must be a whole county of its district, and the two rosters must agree
  for (const a of B.anchors) {
    const w = CO.whole.find(x => x.county === a.county);
    if (!w) throw new Error(`${B.key}: anchor ${a.county} is not a whole county in the canvass parse`);
    if (w.district !== a.district) throw new Error(`${B.key}: anchor ${a.county} is whole in D${w.district}, not D${a.district}`);
    const seat = B.seats.find(s => s.district === a.district);
    if (seat.holder !== a.member) throw new Error(`${B.key}: anchor D${a.district} says ${a.member}, the seat says ${seat.holder}`);
  }
  const anchorable = new Set(CO.whole.map(w => w.district));
  const un = B.seats.map(s => s.district).filter(d => !anchorable.has(d));
  if (un.join(',') !== B.unanchored.join(',')) throw new Error(`${B.key}: unanchored is ${B.unanchored} but the county table says ${un}`);
  if (nAnchors !== N - un.length) throw new Error(`${B.key}: ${nAnchors} anchors for ${N - un.length} anchorable districts`);

  console.error(`${B.key}: seats ${N} · on ballot ${nBallot} · races ${nRaces} · anchors ${nAnchors} · ` +
    `people ${people.size} · candidacies ${calls.length} · winners ${winners.length} · newcomers ${newcomers.length}`);

  const L = [];
  const p = s => L.push(s);

  p(`-- ${B.slot} — ${B.chamberFormal}: all ${N} seats created and seated on the 2021 district map,`);
  p(`--           and the ${nRaces} ${nRaces === 1 ? 'result' : 'results'} of the 2026 general election.`);
  p(`--`);
  p(`-- 🔴🔴 THE POLYGONS ARE NOT IN THIS FILE. They are loaded by`);
  p(`--   scripts/CC_0373-ne-boards-geofences.mjs --body ${B.key}, WHICH MUST RUN FIRST. This file`);
  p(`--   asserts the rows are there, are the right shape, are the map the enacted plan describes,`);
  p(`--   and reach the right member.`);
  p(`--`);
  p(`-- 🔴🔴 NEBRASKA REDISTRICTS BY MAP REFERENCE, SO THERE IS NO STATUTORY COUNTY TEXT TO GATE ON.`);
  p(`--   ${B.remarks.split('🔴')[1] ? '' : ''}${B.act || ''}`);
  for (const line of wrap(B.remarks, 76)) p(`--   ${line}`);
  p(`--`);
  p(`-- 🟢🟢 SO THE COMPOSITION GATE COMES FROM THE SECRETARY OF STATE'S CERTIFIED CANVASS BOOKS.`);
  p(`--   A county that cast votes in a district's race is in that district, and a county split`);
  p(`--   between two districts casts votes in both. Three canvasses — the 2022 general, the 2024`);
  p(`--   general and the 2026 primary — cover all ${N} districts, and the districts that appear in`);
  p(`--   two of them must read the same in both. ${CO.whole.length} counties are assigned whole and ${CO.split.length} are split.`);
  p(`--   data/state-exec-2026-results/parse-ne-canvass-counties.mjs does the reading, bounded by`);
  p(`--   each book's own table of contents so that no other office's districts can leak in.`);
  p(`--   🔴 The split floor is 0.1%, measured: the smallest real split share in Nebraska is Burt`);
  p(`--     County's 1.876912% in State Board of Education District 6, and the largest spurious`);
  p(`--     one — a county merely grazing a district it is not in — is 0.006454%.`);
  p(`--`);
  p(`-- 🟢 AND A SECOND ANCHOR: THE ENACTED PLAN'S OWN POPULATION TABLE. The Legislative Research`);
  p(`--   Office prints a population and deviation on each district's map sheet. The loader checks`);
  p(`--   the GIS attribute against it before a row is written. It is the only thing that can`);
  p(`--   separate two districts whose county sets are identical.`);
  if (B.key === 'regents') {
    p(`--   🔴🔴 AND IT CAUGHT A REAL ONE. The file the Legislature publishes as reg_lb8_final.pdf`);
    p(`--     carries sheets drawn on 2021-09-25 — three days before AM41 was filed and adopted on`);
    p(`--     the 28th, and five before the bill passed 46-2-1 on the 30th. Four of its eight`);
    p(`--     districts are pre-amendment: it gives District 1 as 242,357 against the enacted`);
    p(`--     248,649 and District 4 as 234,292 against 237,525, with the differences traded to 5`);
    p(`--     and 8. reg_lb8_am41.pdf has the enacted figures and the State of Nebraska's own GIS`);
    p(`--     agrees with it on all eight. ▶ A sheet titled "Final Reading" can predate the`);
    p(`--     amendment that passed — and because LB 8 adopts the plan by the map NAME, which AM41`);
    p(`--     did not change, the statute cannot tell the two versions apart either.`);
  }
  p(`--`);
  p(`-- WHAT IT WRITES:`);
  p(`--   1 chamber · ${N} districts · ${N} offices · ${N} office_terms · ${nRaces} races · ${people.size} politicians · ${calls.length} candidacies`);
  p(`--`);
  for (const s of B.seats) {
    const w = calls.filter(c => c.d === s.district && c.result === 'won').map(c => c.who)[0];
    const a = B.anchors.find(x => x.district === s.district);
    p(`--   District ${String(s.district).padStart(2)}  holder ${s.holder.padEnd(22)} anchor ${(a ? a.county : '— none possible').padEnd(18)}` +
      `${s.onBallot2026 ? (w === s.holder ? '🏆 re-elected' : '🏆 ' + w + ' won the seat') : ''}`);
  }
  p(`--`);
  p(`-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so all ${N} are created WITH`);
  p(`--   their current member seated, and the post-verify asserts the unflagged baseline is still`);
  p(`--   exactly 238.`);
  p(`--   ▶ ${TERM_START} — the winners take office. Neb. Const. Art. XVII-5: terms begin on the first`);
  p(`--     Thursday after the first Tuesday in January next succeeding the election, which in`);
  p(`--     2027 is Thursday 7 January. On that date, seat:`);
  for (const c of newcomers) {
    const s = B.seats.find(x => x.district === c.d);
    p(`--       District ${c.d}: ${c.who} replaces ${s.holder}`);
  }
  if (!newcomers.length) p(`--       nobody — every winner here already holds the seat.`);
  const reelected = winners.filter(c => !newcomers.includes(c));
  if (reelected.length) p(`--     ${reelected.map(c => `${c.who} (D${c.d})`).join(', ')} ${reelected.length === 1 ? 'was' : 'were'} re-elected and stay${reelected.length === 1 ? 's' : ''}.`);
  p(`--`);
  p(`-- 🔴 ${un.length ? `${un.length} OF THE ${N} DISTRICTS CANNOT BE ANCHORED ON A WHOLE COUNTY.` : 'EVERY DISTRICT HAS A WHOLE-COUNTY ANCHOR.'}`);
  if (un.length) for (const line of wrap(B.unanchoredWhy, 74)) p(`--   ${line}`);
  p(`--`);
  p(`-- IDENTITY. All ${people.size} people are new. A sweep of all 91,770 politicians on both full name`);
  p(`--   and (first, last) returned nothing for any of the 34 names across the three Nebraska`);
  p(`--   boards. 🟢 The sweep is not blind: its positive control found Pete Ricketts, and its`);
  p(`--   (first, last) arm was shown to work by returning four politicians surnamed Jones whose`);
  p(`--   first name begins with S — just not a Sherry. Production holds only 12 Nebraska`);
  p(`--   officeholders, all statewide executives or members of Congress.`);
  p(`--`);
  p(`-- 🔴 NO TERM START IS INVENTED FOR A SITTING MEMBER. The rosters publish when a member was`);
  p(`--   FIRST elected, which is a different fact, so every term written here is open-ended with`);
  p(`--   start_precision 'unknown'.`);
  p(`--`);
  p(`-- Applied to production 2026-11-07 by Chris Cantrell. Slot reserved via steward.`);
  p(``);
  p(`BEGIN;`);
  p(``);
  p(`CREATE TEMP TABLE seat (`);
  p(`  d int PRIMARY KEY, who text NOT NULL,`);
  p(`  on_ballot_2026 boolean NOT NULL, race_recorded boolean NOT NULL`);
  p(`) ON COMMIT DROP;`);
  p(`INSERT INTO seat VALUES`);
  p(B.seats.map(s => `  (${s.district}, ${q(s.holder)}, ${!!s.onBallot2026}, ${!!s.raceRecorded})`).join(',\n') + ';');
  p(``);
  p(`-- One county per district that the canvass assigns WHOLE to it.`);
  p(`-- 🔴 THE MEMBER'S NAME IS WRITTEN OUT HERE ON PURPOSE, not read from the seat table.`);
  p(`CREATE TEMP TABLE anchor (d int PRIMARY KEY, county text NOT NULL, member text NOT NULL) ON COMMIT DROP;`);
  p(`INSERT INTO anchor VALUES`);
  p(B.anchors.map(a => `  (${a.district}, ${q(a.county)}, ${q(a.member)})`).join(',\n') + ';');
  p(``);
  p(`-- The county composition, read from the Secretary of State's canvass books.`);
  p(`CREATE TEMP TABLE plan_whole (county text PRIMARY KEY, d int NOT NULL) ON COMMIT DROP;`);
  p(`INSERT INTO plan_whole VALUES`);
  p(CO.whole.map(w => `  (${q(w.county)}, ${w.district})`).join(',\n') + ';');
  p(``);
  p(`CREATE TEMP TABLE plan_split (county text PRIMARY KEY, ds text NOT NULL) ON COMMIT DROP;`);
  p(`INSERT INTO plan_split VALUES`);
  p(CO.split.map(s => `  (${q(s.county)}, ${q(s.districts.slice().sort((a, b) => a - b).join(','))})`).join(',\n') + ';');
  p(``);
  p(`-- ─── Pre-gates ───`);
  p(`DO $$ DECLARE txt text; n int; v numeric; BEGIN`);
  p(`  SELECT count(*) INTO n FROM seat; IF n <> ${N} THEN RAISE EXCEPTION 'expected ${N} seats, found %', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM seat WHERE race_recorded; IF n <> ${nRaces} THEN RAISE EXCEPTION 'expected ${nRaces} races, found %', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM seat WHERE on_ballot_2026; IF n <> ${nBallot} THEN RAISE EXCEPTION 'expected ${nBallot} seats on the ballot, found %', n; END IF;`);
  p(`  SELECT string_agg('D' || d, ', ') INTO txt FROM seat WHERE race_recorded <> on_ballot_2026;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seat disagrees with itself about the ballot and the race: %', txt; END IF;`);
  p(`  SELECT count(*) INTO n FROM plan_whole; IF n <> ${CO.whole.length} THEN RAISE EXCEPTION 'the plan table holds % whole counties, expected ${CO.whole.length}', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM plan_split; IF n <> ${CO.split.length} THEN RAISE EXCEPTION 'the plan table holds % split counties, expected ${CO.split.length}', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM (SELECT county FROM plan_whole UNION SELECT county FROM plan_split) z;`);
  p(`  IF n <> 93 THEN RAISE EXCEPTION 'the plan table names % counties, and Nebraska has 93', n; END IF;`);
  p(`  SELECT string_agg(z.county, ', ') INTO txt FROM (SELECT county FROM plan_whole UNION SELECT county FROM plan_split) z`);
  p(`   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries co`);
  p(`                      WHERE co.state = '${STATE_FIPS}' AND co.mtfcc = 'G4020' AND co.name = z.county);`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the plan table names counties we hold no polygon for: %', txt; END IF;`);
  p(``);
  p(`  SELECT count(*) INTO n FROM anchor; IF n <> ${nAnchors} THEN RAISE EXCEPTION 'expected ${nAnchors} anchors, found %', n; END IF;`);
  p(`  SELECT string_agg('D' || a.d || ' ' || a.county, '; ') INTO txt FROM anchor a`);
  p(`   WHERE NOT EXISTS (SELECT 1 FROM plan_whole w WHERE w.county = a.county AND w.d = a.d);`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county is not assigned whole to its district by the canvass: %', txt; END IF;`);
  p(`  -- ⚠ and every district that COULD be anchored must be`);
  p(`  SELECT string_agg('D' || s.d, ', ' ORDER BY s.d) INTO txt FROM seat s`);
  p(`   WHERE NOT EXISTS (SELECT 1 FROM anchor a WHERE a.d = s.d)`);
  p(`     AND EXISTS (SELECT 1 FROM plan_whole w WHERE w.d = s.d);`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'these districts have a whole county and no anchor: %', txt; END IF;`);
  p(``);
  p(`  -- 🔴 the two independent statements of the roster must agree before either is used`);
  p(`  SELECT string_agg('D' || a.d || ': anchor says ' || a.member || ', seat says ' || s.who, '; ') INTO txt`);
  p(`    FROM anchor a JOIN seat s ON s.d = a.d WHERE a.member <> s.who;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the anchor table and the seat table name different members: %', txt; END IF;`);
  p(``);
  p(`  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = '${J.governmentId}'::uuid)`);
  p(`    THEN RAISE EXCEPTION 'the Nebraska government row does not exist'; END IF;`);
  p(`  IF NOT EXISTS (SELECT 1 FROM essentials.elections`);
  p(`                  WHERE id = '${J.election.id}'::uuid AND election_date = DATE '${J.election.date}' AND state = 'NE')`);
  p(`    THEN RAISE EXCEPTION 'the election row is not the ${J.election.date} Nebraska general'; END IF;`);
  p(``);
  p(`  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE name_formal = ${q(B.chamberFormal)})`);
  p(`    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;`);
  p(`  SELECT string_agg(o.title || ' (' || coalesce(d.district_type, 'no district') || ' ' || o.id || ')', '; ') INTO txt`);
  p(`    FROM essentials.offices o LEFT JOIN essentials.districts d ON d.id = o.district_id`);
  p(`   WHERE o.representing_state = 'NE' AND o.title ILIKE ${q('%' + B.officeTitle.replace(', District', '') + '%')};`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;`);
  p(``);
  p(`  -- 🔴🔴 SCOPED BY THE GEO_ID PREFIX, NOT JUST BY (district_type, state). The Public Service`);
  p(`  --   Commission and the Board of Regents are BOTH ${DTYPE} in Nebraska, so a count of all`);
  p(`  --   Nebraska ${DTYPE} districts is not a count of this body's.`);
  p(`  SELECT count(*) INTO n FROM essentials.districts`);
  p(`   WHERE district_type = '${DTYPE}' AND lower(state) = 'ne' AND geo_id LIKE ${q(PREFIX + '%')};`);
  p(`  IF n <> 0 THEN RAISE EXCEPTION '% Nebraska district(s) with this body''s geo_id prefix already exist', n; END IF;`);
  p(``);
  p(`  -- 🔴🔴 THE POLYGONS MUST ALREADY BE LOADED, AND BE THE RIGHT ONES.`);
  p(`  SELECT count(*) INTO n FROM essentials.geofence_boundaries`);
  p(`   WHERE mtfcc = '${MTFCC}' AND state = '${STATE_FIPS}'`);
  p(`     AND geo_id = ANY (SELECT ${q(PREFIX)} || s.d FROM seat s);`);
  p(`  IF n <> ${N} THEN RAISE EXCEPTION 'only % of the ${N} ${B.chamberFormal} polygons are loaded — run scripts/CC_0373-ne-boards-geofences.mjs --body ${B.key} first', n; END IF;`);
  p(``);
  p(`  SELECT string_agg(gb.geo_id || ' srid=' || public.ST_SRID(gb.geometry) || ' valid=' || public.ST_IsValid(gb.geometry), '; ') INTO txt`);
  p(`    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc = '${MTFCC}' AND gb.state = '${STATE_FIPS}'`);
  p(`     AND gb.geo_id LIKE ${q(PREFIX + '%')}`);
  p(`     AND (public.ST_SRID(gb.geometry) <> 4326 OR NOT public.ST_IsValid(gb.geometry) OR public.ST_IsEmpty(gb.geometry)`);
  p(`          OR public.ST_XMin(gb.geometry) < -105 OR public.ST_XMax(gb.geometry) > -94.5`);
  p(`          OR public.ST_YMin(gb.geometry) < 39 OR public.ST_YMax(gb.geometry) > 43.5);`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loaded polygon is not a valid 4326 Nebraska polygon: %', txt; END IF;`);
  p(``);
  p(`  -- The union must reproduce our own TIGER Nebraska outline. ⚠ NO ::geography CAST HERE or`);
  p(`  -- below — ev-cto decision 0006. This is a ratio of planar areas, and the loader's`);
  p(`  -- geodesic measurement of the same thing came out at 99.9019%.`);
  p(`  SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g))`);
  p(`                     / public.ST_Area(s.g) * 100)::numeric, 3) INTO v`);
  p(`    FROM (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries`);
  p(`           WHERE mtfcc='${MTFCC}' AND state='${STATE_FIPS}' AND geo_id LIKE ${q(PREFIX + '%')}) u,`);
  p(`         (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='${STATE_FIPS}') s;`);
  p(`  IF v < 99.5 THEN RAISE EXCEPTION 'the ${N} districts cover only %%% of the Nebraska outline', v; END IF;`);
  p(``);
  p(`  -- 🟢🟢 THE CANVASS GATE.`);
  p(`  SELECT string_agg(z.msg, '; ') INTO txt FROM (`);
  p(`    SELECT w.county || ' is only ' ||`);
  p(`           round((public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))`);
  p(`                  / public.ST_Area(co.geometry) * 100)::numeric, 4) || '% in D' || w.d AS msg`);
  p(`      FROM plan_whole w`);
  p(`      JOIN essentials.geofence_boundaries co ON co.state='${STATE_FIPS}' AND co.mtfcc='G4020' AND co.name=w.county`);
  p(`      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='${MTFCC}' AND gb.state='${STATE_FIPS}'`);
  p(`       AND gb.geo_id = ${q(PREFIX)} || w.d::text`);
  p(`     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))`);
  p(`           < public.ST_Area(co.geometry) * ${WHOLE_FLOOR}) z;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the canvass puts these counties wholly in one district and the map does not: %', txt; END IF;`);
  p(``);
  p(`  SELECT string_agg(z.msg, '; ') INTO txt FROM (`);
  p(`    SELECT w.county || ' (canvass D' || w.d || ') also reaches D' || replace(gb.geo_id, ${q(PREFIX)}, '') AS msg`);
  p(`      FROM plan_whole w`);
  p(`      JOIN essentials.geofence_boundaries co ON co.state='${STATE_FIPS}' AND co.mtfcc='G4020' AND co.name=w.county`);
  p(`      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='${MTFCC}' AND gb.state='${STATE_FIPS}'`);
  p(`       AND gb.geo_id LIKE ${q(PREFIX + '%')} AND gb.geo_id <> ${q(PREFIX)} || w.d::text`);
  p(`     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))`);
  p(`           > public.ST_Area(co.geometry) * ${LEAK_CEILING}) z;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county the canvass assigns whole reaches into another district: %', txt; END IF;`);
  p(``);
  p(`  -- ⚠ the split floor is 0.1%, measured against Nebraska: the smallest real share is 1.8769%`);
  p(`  SELECT string_agg(z.county || ' -> ' || coalesce(z.got, 'nothing') || ', the canvass says ' || z.ds, '; ') INTO txt FROM (`);
  p(`    SELECT sp.county, sp.ds,`);
  p(`           (SELECT string_agg(replace(gb.geo_id, ${q(PREFIX)}, ''), ',' ORDER BY (replace(gb.geo_id, ${q(PREFIX)}, ''))::int)`);
  p(`              FROM essentials.geofence_boundaries gb`);
  p(`             WHERE gb.mtfcc='${MTFCC}' AND gb.state='${STATE_FIPS}' AND gb.geo_id LIKE ${q(PREFIX + '%')}`);
  p(`               AND public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))`);
  p(`                   > public.ST_Area(co.geometry) * ${SHARE_FLOOR}) AS got`);
  p(`      FROM plan_split sp`);
  p(`      JOIN essentials.geofence_boundaries co ON co.state='${STATE_FIPS}' AND co.mtfcc='G4020' AND co.name=sp.county) z`);
  p(`   WHERE z.got IS DISTINCT FROM z.ds;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county the canvass splits is shared with the wrong districts: %', txt; END IF;`);
  p(``);
  p(`  -- ⚠ each ZCTA is tested at a point inside Nebraska, not at its own centroid: three of the`);
  p(`  --   586 straddle a state line and ST_PointOnSurface lands outside the state.`);
  p(`  SELECT count(*) INTO n FROM (`);
  p(`    SELECT (SELECT count(*) FROM essentials.geofence_boundaries s`);
  p(`             WHERE s.mtfcc='${MTFCC}' AND s.state='${STATE_FIPS}' AND s.geo_id LIKE ${q(PREFIX + '%')}`);
  p(`               AND public.ST_Covers(s.geometry, pt)) k`);
  p(`      FROM (SELECT public.ST_PointOnSurface(public.ST_CollectionExtract(`);
  p(`                     public.ST_Intersection(z.geometry, st.geometry), 3)) pt`);
  p(`              FROM essentials.geofence_boundaries z,`);
  p(`                   essentials.geofence_boundaries st`);
  p(`             WHERE z.state='${STATE_FIPS}' AND z.mtfcc='G6350'`);
  p(`               AND st.mtfcc='G4000' AND st.geo_id='${STATE_FIPS}'`);
  p(`               AND NOT public.ST_IsEmpty(public.ST_CollectionExtract(public.ST_Intersection(z.geometry, st.geometry), 3))) w) y`);
  p(`   WHERE y.k <> 1;`);
  p(`  IF n <> 0 THEN RAISE EXCEPTION '% Nebraska ZCTA(s) do not resolve to exactly one district', n; END IF;`);
  p(`END $$;`);
  p(``);
  p(`-- ─── Chamber, districts, offices ───`);
  p(`CREATE TEMP TABLE made_chamber (chamber_id uuid NOT NULL) ON COMMIT DROP;`);
  p(`WITH ins AS (`);
  p(`  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,`);
  p(`                                   official_count, term_length, staggered_term, website_url,`);
  p(`                                   inauguration_rules, election_rules, remarks)`);
  p(`  VALUES (${q(B.chamberName)}, ${q(B.chamberFormal)}, '${J.governmentId}'::uuid, 'full', ${B.officialCount}, ${q(B.termLength)}, true, ${q(B.rosterUrl)},`);
  p(`          ${q(B.inaugurationRules)},`);
  p(`          ${q(B.electionRules)},`);
  p(`          ${q(B.remarks)})`);
  p(`  RETURNING id)`);
  p(`INSERT INTO made_chamber SELECT id FROM ins;`);
  p(``);
  p(`CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;`);
  p(`WITH ins AS (`);
  p(`  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)`);
  p(`  SELECT '${DTYPE}', 'ne',`);
  p(`         ${q(PREFIX)} || s.d, ${q(PREFIX)} || s.d,`);
  p(`         ${q(B.chamberFormal)} || ' District ' || s.d, '${MTFCC}', s.d::text, 'residency'`);
  p(`    FROM seat s RETURNING id, geo_id)`);
  p(`INSERT INTO made_district`);
  p(`SELECT replace(ins.geo_id, ${q(PREFIX)}, '')::int, ins.id FROM ins;`);
  p(``);
  p(`CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;`);
  p(`WITH ins AS (`);
  p(`  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,`);
  p(`                                  is_vacant, faces_retention_vote, is_appointed_position, description)`);
  p(`  SELECT ${q(B.officeTitle + ' ')} || s.d, mc.chamber_id, md.district_id, 'NE', 'full',`);
  p(`         false, false, false, 'seat:' || s.d`);
  p(`    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc`);
  p(`  RETURNING id, description)`);
  p(`INSERT INTO made_office SELECT replace(ins.description, 'seat:', '')::int, ins.id FROM ins;`);
  p(`UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;`);
  p(``);
  p(`DO $$ DECLARE n int; BEGIN`);
  p(`  SELECT count(*) INTO n FROM made_district; IF n <> ${N} THEN RAISE EXCEPTION 'only % districts were created', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM made_office;   IF n <> ${N} THEN RAISE EXCEPTION 'only % offices were created', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;`);
  p(`  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id`);
  p(`    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;`);
  p(`  IF n <> ${N} THEN RAISE EXCEPTION 'only % of the ${N} districts meet a geofence row on (geo_id, mtfcc)', n; END IF;`);
  p(`END $$;`);
  p(``);
  p(`-- ─── The people ───`);
  p(`CREATE TEMP TABLE seed_people (`);
  p(`  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL`);
  p(`) ON COMMIT DROP;`);
  p(`INSERT INTO seed_people VALUES`);
  p([...people.entries()].map(([n, v]) => `  (${q(n)}, ${q(v.first)}, ${q(v.last)},\n   ${q(v.source)})`).join(',\n') + ';');
  p(``);
  p(`CREATE TEMP TABLE allowed_name_collisions (full_name text PRIMARY KEY) ON COMMIT DROP;`);
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
  p(`  -- 🔴 a positive control on BOTH arms, so a sweep that finds nothing is a clean sweep`);
  p(`  --   rather than a blind one.`);
  p(`  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Pete Ricketts');`);
  p(`  IF n < 1 THEN RAISE EXCEPTION 'the full-name index cannot see a politician known to exist'; END IF;`);
  p(`  SELECT count(*) INTO n FROM pol_keys WHERE k_first = pg_temp.namekey('Shevrin') AND k_last = pg_temp.namekey('Jones');`);
  p(`  IF n < 1 THEN RAISE EXCEPTION 'the (first, last) index cannot see a politician known to exist'; END IF;`);
  p(`  SELECT count(*) INTO n FROM pol_keys; IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows', n; END IF;`);
  p(``);
  p(`  SELECT string_agg(z.msg, '; ') INTO txt FROM (`);
  p(`    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ')' AS msg`);
  p(`      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)`);
  p(`     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)`);
  p(`    UNION`);
  p(`    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'`);
  p(`      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name)`);
  p(`     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)) z;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;`);
  p(``);
  p(`  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt`);
  p(`    FROM seed_people s WHERE s.full_name <> s.first_name || ' ' || s.last_name;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;`);
  p(`  SELECT string_agg(s.full_name || ' -> ' || s.source, '; ') INTO txt FROM seed_people s`);
  p(`   WHERE s.source NOT LIKE 'https://%' AND s.source NOT LIKE 'Nebraska Secretary of State%';`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is neither a roster URL nor the Secretary of State: %', txt; END IF;`);
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
  p(`  IF n <> ${people.size} THEN RAISE EXCEPTION 'only % of the ${people.size} people resolved to exactly one row', n; END IF; END $$;`);
  p(``);
  p(`-- ─── Seat every current member ───`);
  p(`INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)`);
  p(`SELECT mo.office_id, pe.pid, NULL, NULL, 'unknown', 'unknown',`);
  if (B.holderNotes) {
    p(`       CASE s.d`);
    for (const [d, note] of Object.entries(B.holderNotes)) {
      p(`         WHEN ${d} THEN ${q(`${B.rosterUrl} (the body's own roster, read 2026-11-07). ${note} — ${B.slot}`)}`);
    }
    p(`         ELSE ${q(holderSource)} END`);
  } else {
    p(`       ${q(holderSource)}`);
  }
  p(`  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;`);
  p(``);
  p(`-- ─── The races and their results ───`);
  p(`INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)`);
  p(`SELECT '${J.election.id}'::uuid, mo.office_id, ${q(B.chamberFormal)} || ' District ' || s.d, NULL, 1,`);
  p(`       CASE s.d`);
  for (const r of B.races) {
    const s = B.seats.find(x => x.district === r.district);
    const desc = `The seat held by ${s.holder}. ${r.termNote === 'unexpired term, to 2031' ? 'A special election for an unexpired term. ' : ''}` +
      r.candidates.map(c => `${c.name} (${c.party}) ${c.votes.toLocaleString('en-US')}`).join(', ') +
      `; ${r.precincts}.${r.note ? ' ' + r.note : ''}`;
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
  p(`  -- 🔴 the winner must be the candidate with the most votes. A "won" flag and a vote count`);
  p(`  --   are two separate facts, and this is where they are made to agree.`);
  p(`  SELECT string_agg('D' || z.d, ', ') INTO txt FROM (`);
  p(`    SELECT c.d FROM calls c`);
  p(`     GROUP BY c.d`);
  p(`    HAVING max(c.votes) FILTER (WHERE c.result = 'won') < max(c.votes)) z;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the winner is not the leading candidate in: %', txt; END IF;`);
  p(`  SELECT string_agg(c.who, '; ') INTO txt FROM calls c LEFT JOIN person pe ON pe.who = c.who WHERE pe.pid IS NULL;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy resolves to no person: %', txt; END IF;`);
  p(`  SELECT string_agg(c.who || ' in D' || c.d, '; ') INTO txt FROM calls c JOIN seat s ON s.d = c.d`);
  p(`   WHERE c.is_incumbent <> (s.who = c.who);`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an incumbent flag disagrees with the seat''s holder: %', txt; END IF;`);
  p(`  SELECT count(*) INTO n FROM calls WHERE NOT EXISTS (SELECT 1 FROM seat s WHERE s.d = calls.d AND s.race_recorded);`);
  p(`  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) sit on a district with no race', n; END IF;`);
  p(`END $$;`);
  p(``);
  p(`INSERT INTO essentials.race_candidates`);
  p(`  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,`);
  p(`   is_write_in, source, result, result_certainty, result_source, result_recorded_at)`);
  p(`SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, c.is_incumbent, 'active', false,`);
  p(`       ${q(resultSource)},`);
  p(`       c.result, 'called',`);
  p(`       ${q(resultSource)}, now()`);
  p(`  FROM calls c JOIN made_office mo ON mo.d = c.d`);
  p(`  JOIN essentials.races r ON r.office_id = mo.office_id`);
  p(`  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '${J.election.date}'`);
  p(`  JOIN person pe ON pe.who = c.who JOIN essentials.politicians pl ON pl.id = pe.pid;`);
  p(``);
  p(`-- ─── Post-verify ───`);
  p(`DO $$ DECLARE n int; txt text; BEGIN`);
  p(`  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.d = s.d`);
  p(`    JOIN essentials.races r ON r.office_id = mo.office_id WHERE s.race_recorded;`);
  p(`  IF n <> ${nRaces} THEN RAISE EXCEPTION 'expected ${nRaces} new races, found %', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM calls c JOIN made_office mo ON mo.d = c.d`);
  p(`    JOIN essentials.races r ON r.office_id = mo.office_id`);
  p(`    JOIN person pe ON pe.who = c.who`);
  p(`    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid`);
  p(`   WHERE rc.result = c.result AND rc.result_certainty = 'called';`);
  p(`  IF n <> ${calls.length} THEN RAISE EXCEPTION 'only % of the ${calls.length} candidacies hold their stated result', n; END IF;`);
  p(``);
  p(`  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED`);
  p(`  SELECT count(*) INTO n FROM made_office mo`);
  p(`   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);`);
  p(`  IF n <> 0 THEN RAISE EXCEPTION '% of the ${N} offices have no term and would raise the drift metric', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM essentials.offices_missing_terms m`);
  p(`    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;`);
  p(`  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;`);
  p(``);
  p(`  SELECT count(*) INTO n FROM made_chamber mc JOIN essentials.offices o ON o.chamber_id = mc.chamber_id;`);
  p(`  IF n <> ${N} THEN RAISE EXCEPTION 'the chamber holds % offices, not ${N}', n; END IF;`);
  p(`  SELECT official_count INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id;`);
  p(`  IF n <> ${B.officialCount} THEN RAISE EXCEPTION 'official_count is %, not ${B.officialCount}', n; END IF;`);
  p(`  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id`);
  p(`   WHERE ch.inauguration_rules ILIKE '%2027-01-07%';`);
  p(`  IF n <> 1 THEN RAISE EXCEPTION 'the chamber does not record the ${TERM_START} handover'; END IF;`);
  p(``);
  p(`  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED MEMBER, for the ${nAnchors} districts`);
  p(`  --   the canvass gives a whole county.${un.length ? ` Districts ${un.join(', ')} have none; see the header.` : ''}`);
  p(`  SELECT string_agg(a.county || ' -> ' || coalesce(x.who, 'nobody') || ' (expected ' || a.member || ')', '; ') INTO txt`);
  p(`    FROM anchor a`);
  p(`    LEFT JOIN LATERAL (`);
  p(`      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who`);
  p(`        FROM essentials.geofence_boundaries co`);
  p(`        JOIN essentials.geofence_boundaries gb`);
  p(`          ON gb.mtfcc = '${MTFCC}' AND gb.state = '${STATE_FIPS}' AND gb.geo_id LIKE ${q(PREFIX + '%')}`);
  p(`         AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(co.geometry))`);
  p(`        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc`);
  p(`         AND dd.district_type = '${DTYPE}'`);
  p(`        JOIN essentials.offices o ON o.district_id = dd.id`);
  p(`        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL`);
  p(`        JOIN essentials.politicians pl ON pl.id = och.politician_id`);
  p(`       WHERE co.state = '${STATE_FIPS}' AND co.mtfcc = 'G4020' AND co.name = a.county) x ON true`);
  p(`   WHERE x.who IS DISTINCT FROM a.member;`);
  p(`  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county does not reach its member: %', txt; END IF;`);
  p(``);
  p(`  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id`);
  p(`   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';`);
  p(`  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;`);
  p(``);
  p(`  RAISE NOTICE '${B.slot} OK — ${N} ${B.chamberFormal} seats created and seated, ${nRaces} races, ${calls.length} candidacies, ${people.size} people seeded.';`);
  p(`END $$;`);
  p(``);
  p(`COMMIT;`);

  const name = { psc: 'CC_0373_ne_public_service_commission.sql', sboe: 'CC_0374_ne_state_board_of_education.sql', regents: 'CC_0375_ne_board_of_regents.sql' }[B.key];
  const out = `${MIG}/${name}`;
  fs.writeFileSync(out, L.join('\n') + '\n');
  FILES.push(`${out} (${fs.statSync(out).size} bytes)`);
}

function wrap(s, w) {
  const out = [];
  let line = '';
  for (const word of String(s).split(/\s+/)) {
    if (line && (line + ' ' + word).length > w) { out.push(line); line = word; } else line = line ? line + ' ' + word : word;
  }
  if (line) out.push(line);
  return out;
}

console.error(FILES.join('\n'));
