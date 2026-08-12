#!/usr/bin/env node
/**
 * Emit the migration that seeds Puerto Rico's government: the Governor and both chambers of the
 * Legislative Assembly. Generated rather than hand-written because it is 82 people.
 *
 * Roster source is Open States' current-legislator CSV (a DETECTOR elsewhere in this repo, used here
 * as the seed roster because no machine-readable official roster exists for the Asamblea Legislativa);
 * the composition it reports is checked against PR's constitutional structure before anything is
 * emitted — 8 senatorial districts × 2 senators + at-large, 40 representative districts × 1 + at-large.
 * If those invariants ever stop holding, this refuses to generate rather than seeding a wrong shape.
 *
 * 🔴 PR'S CHAMBERS ARE NOT 27/51. The Constitution sets 27 senators and 51 representatives, but the
 * minority-representation guarantee ("por adición") adds seats when one party sweeps. The 2025-2028
 * Assembly has 28 and 53. Do not "correct" these counts to the constitutional minimums.
 *
 *   node scripts/generate-pr-government-migration.mjs <openstates-pr.csv> <out.sql>
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';

const [, , CSV, OUT] = process.argv;
if (!CSV || !OUT) { console.error('usage: <openstates-pr.csv> <out.sql>'); process.exit(2); }

function parseCsv(t) {
  const rows = []; let row = []; let f = ''; let q = false;
  for (let i = 0; i < t.length; i++) {
    const c = t[i];
    if (q) {
      if (c === '"') { if (t[i + 1] === '"') { f += '"'; i++; } else q = false; } else f += c;
    } else if (c === '"') q = true;
    else if (c === ',') { row.push(f); f = ''; }
    else if (c === '\n') { row.push(f); rows.push(row); row = []; f = ''; }
    else if (c !== '\r') f += c;
  }
  if (f.length || row.length) { row.push(f); rows.push(row); }
  const h = rows.shift();
  return rows.filter((r) => r.length > 1).map((r) => Object.fromEntries(h.map((x, i) => [x, r[i] ?? ''])));
}

const people = parseCsv(readFileSync(CSV, 'utf8'));
const upper = people.filter((p) => p.current_chamber === 'upper');
const lower = people.filter((p) => p.current_chamber === 'lower');

// ---- structural invariants, checked before emitting -------------------------------------------
const bad = [];
const senDistricts = [...new Set(upper.filter((p) => p.current_district !== 'At-Large')
  .map((p) => p.current_district))].sort((a, b) => +a - +b);
const repDistricts = [...new Set(lower.filter((p) => p.current_district !== 'At-Large')
  .map((p) => p.current_district))].sort((a, b) => +a - +b);
if (senDistricts.length !== 8) bad.push(`expected 8 senatorial districts, got ${senDistricts.length}`);
if (repDistricts.length !== 40) bad.push(`expected 40 representative districts, got ${repDistricts.length}`);
for (const d of senDistricts) {
  const n = upper.filter((p) => p.current_district === d).length;
  if (n !== 2) bad.push(`senatorial district ${d} has ${n} senators, expected 2`);
}
for (const d of repDistricts) {
  const n = lower.filter((p) => p.current_district === d).length;
  if (n !== 1) bad.push(`representative district ${d} has ${n} members, expected 1`);
}
if (bad.length) { console.error('REFUSING TO GENERATE:\n  ' + bad.join('\n  ')); process.exit(1); }

const sq = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
const pad3 = (n) => String(n).padStart(3, '0');

// ---- assemble seats ---------------------------------------------------------------------------
// Deterministic seat assignment inside a multi-member district: members sorted by family name, then
// given name, take Seat 1..N. Arbitrary but STABLE, so a re-run maps the same person to the same seat.
const byName = (a, b) =>
  (a.family_name || '').localeCompare(b.family_name || '', 'es')
  || (a.given_name || '').localeCompare(b.given_name || '', 'es');

const seats = [];   // {chamber, geo_id, districtLabel, seatNo, person}
for (const d of senDistricts) {
  upper.filter((p) => p.current_district === d).sort(byName).forEach((p, i) => {
    seats.push({ dt: 'STATE_UPPER', geo: `72${pad3(d)}`, label: `Senatorial District ${d}`, seat: i + 1, p });
  });
}
upper.filter((p) => p.current_district === 'At-Large').sort(byName).forEach((p, i) => {
  seats.push({ dt: 'STATE_UPPER', geo: '72000', label: 'Senate At-Large', seat: i + 1, p });
});
for (const d of repDistricts) {
  lower.filter((p) => p.current_district === d).sort(byName).forEach((p, i) => {
    seats.push({ dt: 'STATE_LOWER', geo: `72${pad3(d)}`, label: `Representative District ${d}`, seat: i + 1, p });
  });
}
lower.filter((p) => p.current_district === 'At-Large').sort(byName).forEach((p, i) => {
  seats.push({ dt: 'STATE_LOWER', geo: '72000', label: 'House At-Large', seat: i + 1, p });
});

let extSen = -7210000;
let extRep = -7220000;
for (const s of seats) {
  s.uuid = randomUUID();
  s.ext = s.dt === 'STATE_UPPER' ? --extSen : --extRep;
  s.title = s.dt === 'STATE_UPPER' ? 'Senator' : 'Representative';
}

const districts = [];
const seen = new Set();
for (const s of seats) {
  const k = `${s.dt}|${s.geo}`;
  if (seen.has(k)) continue;
  seen.add(k);
  districts.push({ dt: s.dt, geo: s.geo, label: s.label,
    mtfcc: s.dt === 'STATE_UPPER' ? 'G5210' : 'G5220' });
}

const GOV = { uuid: randomUUID(), ext: -7200001, name: 'Jenniffer González-Colón',
  first: 'Jenniffer', last: 'González-Colón', party: 'Partido Nuevo Progresista' };

const SRC = 'Open States current roster + Census TIGERweb boundaries, checked 2026-08-12 '
  + '(migration NNNN)';

// ---- emit -------------------------------------------------------------------------------------
const L = [];
L.push(`-- NNNN_puerto_rico_government.sql
--
-- Puerto Rico's government: the Governor and both chambers of the Legislative Assembly.
-- Generated by scripts/generate-pr-government-migration.mjs — do not hand-edit; regenerate.
--
-- Follows migration 1719, which gave PR its Resident Commissioner. This is the territory's OWN
-- government, which is the part that actually governs day to day: PR has a governor and a bicameral
-- legislature with full domestic lawmaking power, and none of it was in this database.
--
-- 🔴 THE CHAMBERS ARE 28 AND 53, NOT 27 AND 51. The Constitution of Puerto Rico sets 27 senators and
-- 51 representatives, but its minority-representation guarantee adds seats ("por adición") when one
-- party wins too large a share. The 2025-2028 Assembly seats 28 and 53. Anyone "fixing" these counts
-- to the constitutional minimums will delete two real legislators.
--
-- Composition, verified structurally before generation:
--   Senate  28 = 8 senatorial districts × 2 senators  + 12 at-large
--   House   53 = 40 representative districts × 1      + 13 at-large
--
-- 🔴 AT-LARGE SEATS COVER THE WHOLE TERRITORY, on synthesized geo_id 72000 (TIGER numbers PR
-- districts from 001, and MTFCC keeps the Senate and House at-large rows apart). 12 senators and 13
-- representatives are elected island-wide and genuinely represent every resident, so an address in
-- PR correctly returns its district senators AND the at-large members. That is real: a San Juan voter
-- has 2 district senators plus 12 at-large senators. It is not duplication.
--
-- 🔴 SLDU AND SLDL SHARE GEO_IDS (72001 is both Senate District 1 and House District 1). This is the
-- documented collision MTFCC_DISTRICT_TYPE_GUARD exists for. Never join districts to boundaries on
-- geo_id alone for PR.
--
-- Parties are Puerto Rico's own and are stored verbatim — Partido Nuevo Progresista, Partido Popular
-- Democrático, Partido Independentista Puertorriqueño, Proyecto Dignidad, Independent. They do NOT
-- map onto the U.S. two-party split (PNP and PPD both contain Democrats and Republicans nationally),
-- and translating them would be a false statement about every member.
--
-- Terms begin 2025-01-02 for all 82: the Constitution of Puerto Rico fixes the start of legislative
-- and gubernatorial terms at January 2 following the general election (2024-11-05).
--
-- Boundaries were loaded first by scripts/load-pr-boundaries.mjs, which verifies San Juan falls in
-- exactly one senatorial and one representative district before writing.

DO $$
DECLARE
  c_src text := ${sq(SRC)};
  v_n   int;
  r     record;
BEGIN
  -- ---- districts ---------------------------------------------------------------------------`);

L.push(`  INSERT INTO essentials.districts (label, district_type, state, geo_id, mtfcc, representation_basis)
  SELECT v.label, v.dt, 'pr', v.geo, v.mtfcc, 'residency'
    FROM (VALUES`);
L.push(`      ('Puerto Rico Governor', 'STATE_EXEC', '72', NULL::text),`.replace(/,$/, ','));
L.pop();
const dvals = [`      ('Puerto Rico Governor','STATE_EXEC','72',NULL)`]
  .concat(districts.map((d) => `      (${sq(d.label)},${sq(d.dt)},${sq(d.geo)},${sq(d.mtfcc)})`));
L.push(dvals.join(',\n'));
L.push(`    ) AS v(label, dt, geo, mtfcc)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d
                      WHERE d.geo_id = v.geo AND d.district_type = v.dt AND lower(d.state) = 'pr');
`);

// offices: governor + one per seat, distinguished by description so assignment is deterministic
L.push(`  -- ---- offices (multi-member districts get one office per seat) ------------------------`);
L.push(`  INSERT INTO essentials.offices (district_id, title, representing_state, description, voting_powers)
  SELECT d.id, v.title, 'PR', v.descr, 'full'
    FROM (VALUES`);
const ovals = [`      ('STATE_EXEC','72','Governor',NULL)`]
  .concat(seats.map((s) => `      (${sq(s.dt)},${sq(s.geo)},${sq(s.title)},${sq('Seat ' + s.seat)})`));
L.push(ovals.join(',\n'));
L.push(`    ) AS v(dt, geo, title, descr)
    JOIN essentials.districts d
      ON d.geo_id = v.geo AND d.district_type = v.dt AND lower(d.state) = 'pr'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                      WHERE o.district_id = d.id
                        AND o.description IS NOT DISTINCT FROM v.descr);
`);

L.push(`  -- ---- people ------------------------------------------------------------------------`);
L.push(`  INSERT INTO essentials.politicians
    (id, external_id, full_name, first_name, last_name, party,
     is_active, is_incumbent, is_vacant, is_appointed, source)
  SELECT v.id, v.ext, v.fullname, v.firstname, v.lastname, v.party, true, true, false, false, c_src
    FROM (VALUES`);
const pvals = [
  `      (${sq(GOV.uuid)}::uuid,${GOV.ext},${sq(GOV.name)},${sq(GOV.first)},${sq(GOV.last)},${sq(GOV.party)})`,
].concat(seats.map((s) => `      (${sq(s.uuid)}::uuid,${s.ext},${sq(s.p.name)},`
  + `${sq(s.p.given_name)},${sq(s.p.family_name)},${sq(s.p.current_party)})`));
L.push(pvals.join(',\n'));
L.push(`    ) AS v(id, ext, fullname, firstname, lastname, party)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);
`);

L.push(`  -- ---- seat everyone -----------------------------------------------------------------`);
L.push(`  FOR r IN
    SELECT o.id AS office_id, p.id AS politician_id
      FROM (VALUES`);
const svals = [`        (${GOV.ext},'STATE_EXEC','72',NULL)`]
  .concat(seats.map((s) => `        (${s.ext},${sq(s.dt)},${sq(s.geo)},${sq('Seat ' + s.seat)})`));
L.push(svals.join(',\n'));
L.push(`      ) AS m(ext, dt, geo, descr)
      JOIN essentials.politicians p ON p.external_id = m.ext
      JOIN essentials.districts d
        ON d.geo_id = m.geo AND d.district_type = m.dt AND lower(d.state) = 'pr'
      JOIN essentials.offices o
        ON o.district_id = d.id AND o.description IS NOT DISTINCT FROM m.descr
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, DATE '2025-01-02', c_src, 'elected', 'day');
  END LOOP;
`);

L.push(`  -- ---- post-verify -------------------------------------------------------------------
  SELECT count(*) INTO v_n FROM essentials.districts WHERE lower(state) = 'pr'
     AND district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC');
  IF v_n <> ${districts.length + 1} THEN
    RAISE EXCEPTION 'expected ${districts.length + 1} PR districts, found %', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'pr' AND d.district_type = 'STATE_UPPER'
     AND och.politician_id IS NOT NULL;
  IF v_n <> ${upper.length} THEN RAISE EXCEPTION 'expected ${upper.length} PR senators, found %', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'pr' AND d.district_type = 'STATE_LOWER'
     AND och.politician_id IS NOT NULL;
  IF v_n <> ${lower.length} THEN RAISE EXCEPTION 'expected ${lower.length} PR representatives, found %', v_n; END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.offices o
                   JOIN essentials.districts d ON d.id = o.district_id
                   JOIN essentials.office_current_holder och ON och.office_id = o.id
                   JOIN essentials.politicians p ON p.id = och.politician_id
                  WHERE lower(d.state) = 'pr' AND d.district_type = 'STATE_EXEC'
                    AND o.title = 'Governor' AND p.external_id = ${GOV.ext}) THEN
    RAISE EXCEPTION 'the Governor of Puerto Rico is not seated';
  END IF;

  -- Every seat filled: no office left holderless, which would render as a phantom vacancy.
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'pr' AND d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC')
     AND och.politician_id IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '% PR seats have no holder', v_n; END IF;

  -- Parties preserved verbatim: nothing was translated into the U.S. two-party split.
  IF EXISTS (SELECT 1 FROM essentials.politicians
              WHERE external_id BETWEEN -7299999 AND -7200000
                AND party IN ('Democrat','Democratic','Republican')) THEN
    RAISE EXCEPTION 'a Puerto Rico party was mapped onto a U.S. party';
  END IF;

  -- Every district-based seat has usable geometry, so residents can actually reach it.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE lower(d.state) = 'pr' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gp
                      WHERE gp.geo_id = d.geo_id AND gp.mtfcc = d.mtfcc
                        AND public.ST_IsValid(gp.geometry) AND NOT public.ST_IsEmpty(gp.geometry));
  IF v_n <> 0 THEN RAISE EXCEPTION '% PR legislative districts lack valid geometry', v_n; END IF;

  RAISE NOTICE 'Puerto Rico: governor + ${upper.length} senators + ${lower.length} representatives seated';
END $$;`);

writeFileSync(OUT, L.join('\n') + '\n');
console.log(`wrote ${OUT}`);
console.log(`  districts: ${districts.length + 1} (incl. STATE_EXEC)`);
console.log(`  seats:     ${seats.length + 1} (incl. Governor)`);
console.log(`  senate:    ${upper.length} (${senDistricts.length} districts × 2 + `
  + `${upper.filter((p) => p.current_district === 'At-Large').length} at-large)`);
console.log(`  house:     ${lower.length} (${repDistricts.length} districts × 1 + `
  + `${lower.filter((p) => p.current_district === 'At-Large').length} at-large)`);
