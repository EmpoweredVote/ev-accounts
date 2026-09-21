#!/usr/bin/env node
/**
 * gen-mn-cities-migrations.mjs
 *
 * Emits the two MN-3 migrations from data/mn-cities-roster.json:
 *
 *   migrations/CC_0109_mn_cities_structure.sql    2 governments, 4 chambers, 14 districts, 18 offices
 *   migrations/CC_0110_mn_cities_officials.sql    18 people + 18 dated terms
 *
 * Both slots were RESERVED from the allocator (`steward slot CC`), never counted.
 * Reads nothing from the database and writes nothing to it.
 *
 *   node scripts/gen-mn-cities-migrations.mjs
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'mn-cities-roster.json');
const MIG = path.join(HERE, '..', 'migrations');

/** Free band, measured 2026-09-14: 0 rows between -2734001 and -2734999. */
const BAND_HI = -2734001;
const BAND_LO = -2734100;

const CITIES = {
  Duluth: {
    government: 'City of Duluth, Minnesota, US',
    place_geo_id: '2717000',
    mtfcc: 'X0052',
    districts: 5,
    council: { name: 'Duluth City Council', official_count: 9 },
    mayor: { name: 'Office of the Mayor', official_count: 1 },
    districtSlug: (n) => `duluth-mn-council-district-${n}`,
    districtLabel: (n) => `Duluth City Council District ${n}`,
    citywideLabel: 'Duluth Citywide',
    districtTitle: (n) => `Councilor, District ${n}`,
    atLargeTitle: 'Councilor, At Large',
    atLarge: 4,
  },
  'Saint Paul': {
    government: 'City of Saint Paul, Minnesota, US',
    place_geo_id: '2758000',
    mtfcc: 'X0053',
    districts: 7,
    council: { name: 'Saint Paul City Council', official_count: 7 },
    mayor: { name: 'Office of the Mayor', official_count: 1 },
    districtSlug: (n) => `saint-paul-mn-ward-${n}`,
    districtLabel: (n) => `Saint Paul City Council Ward ${n}`,
    citywideLabel: 'Saint Paul Citywide',
    districtTitle: (n) => `Councilmember, Ward ${n}`,
    atLargeTitle: null,
    atLarge: 0,
  },
};

const sql = (v) => (v === null || v === undefined ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`);
const arr = (a) => (a && a.length ? `ARRAY[${a.map(sql).join(', ')}]::text[]` : `'{}'::text[]`);

const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8')).roster;
const byCity = (c) => roster.filter((r) => r.city === c);

/**
 * Duluth's four at-large seats carry the IDENTICAL voter-facing title, so a person cannot be
 * joined to one by title alone. The discriminator lives in `description`, is labelled INTERNAL,
 * and is ordered by the seat's term start then the member's surname so it is STABLE across
 * regenerations. This is Fort Wayne's pattern.
 */
const atLargeOrder = byCity('Duluth')
  .filter((r) => r.district_number === null && r.title.includes('At Large'))
  .sort((a, b) => (a.term_start === b.term_start ? a.last_name.localeCompare(b.last_name) : a.term_start.localeCompare(b.term_start)));

const atLargeDesc = (i, n) =>
  `Internal ordinal ${i + 1} of ${n}. Duluth does not number its at-large seats; all four are ` +
  `elected in one citywide race. Not a ballot designation.`;

// ── every office this wave creates, in a stable order ────────────────────────
const offices = [];
for (const [city, cfg] of Object.entries(CITIES)) {
  for (let n = 1; n <= cfg.districts; n++) {
    const r = byCity(city).find((x) => x.district_number === n);
    offices.push({ city, cfg, geo_id: cfg.districtSlug(n), chamber: cfg.council.name, title: cfg.districtTitle(n), description: null, holder: r });
  }
  const al = city === 'Duluth' ? atLargeOrder : [];
  al.forEach((r, i) => {
    offices.push({ city, cfg, geo_id: cfg.place_geo_id, chamber: cfg.council.name, title: cfg.atLargeTitle, description: atLargeDesc(i, al.length), holder: r });
  });
  const mayor = byCity(city).find((x) => x.seat === 'Mayor');
  offices.push({ city, cfg, geo_id: cfg.place_geo_id, chamber: cfg.mayor.name, title: 'Mayor', description: null, holder: mayor });
}

if (offices.length !== roster.length) throw new Error(`built ${offices.length} offices for ${roster.length} roster rows`);
for (const o of offices) if (!o.holder) throw new Error(`office ${o.city} ${o.title} has no holder`);

let next = BAND_HI;
const people = offices.map((o) => ({ ...o.holder, external_id: next-- }));
if (next < BAND_LO - 1) throw new Error('external_id band exhausted');

const SOURCE = (city) =>
  city === 'Duluth'
    ? 'City of Duluth council and mayor pages, https://duluthmn.gov/city-council/ ; Duluth City Charter ch. II; VotingDistricts/MapServer/16; change-checked against each member’s own page, read 2026-09-14 (MN-3)'
    : 'City of Saint Paul council and mayor pages, https://www.stpaul.gov/department/city-council ; Saint Paul City Charter; Council_Ward_/FeatureServer/0; change-checked against each member’s own page, read 2026-09-14 (MN-3)';

// ═══════════════════════════════════════════════════════════════════════════════
// CC_0109 -- structure
// ═══════════════════════════════════════════════════════════════════════════════
const districtRows = [];
for (const [city, cfg] of Object.entries(CITIES)) {
  for (let n = 1; n <= cfg.districts; n++) districtRows.push({ city, geo_id: cfg.districtSlug(n), label: cfg.districtLabel(n), mtfcc: cfg.mtfcc });
  districtRows.push({ city, geo_id: cfg.place_geo_id, label: cfg.citywideLabel, mtfcc: 'G4110' });
}

const structure = `-- CC_0109_mn_cities_structure.sql
-- Knight Foundation program, wave MN-3 (structure half). Slot RESERVED from the allocator.
--
-- Creates BOTH Knight jurisdictions in slice 5, which have nothing in production today -- no
-- government row, no district, no office, no official:
--
--   City of Duluth            2 chambers   6 districts   10 offices  (Mayor + 5 district + 4 at large)
--   City of Saint Paul        2 chambers   8 districts    8 offices  (Mayor + 7 ward)
--
-- Creates NO people and NO terms -- CC_0110 does that, and the two are applied back to back.
--
-- 🔴🔴 THE ONLY "SAINT PAUL" IN PRODUCTION IS IN TEXAS. essentials.governments holds exactly one
-- row matching '%Saint Paul%': 'City of Saint Paul, Texas, US', geo_id 4864220, state TX. Any
-- wave that finds this city by NAME seats the whole council under a Texas city. Every lookup
-- here is by TIGER place geo_id '2758000'. TIGER also calls the Minnesota city 'St. Paul', and
-- '%St. Paul%' matches FIVE Minnesota cities including 'St. Paul Park' (2758018), which shares
-- the capital's first five characters.
--
-- 🔴 TEN OFFICES AND EIGHT ARE WHAT THE CHARTERS SAY, NOT WHAT CITIES "USUALLY" HAVE.
-- Duluth City Charter ch. II is titled ELECTIVE OFFICERS and contains only ss 2-5. s 2 reads
-- "The council shall have nine members, four elected from the city at large and five from
-- geographical districts", and the chapter ENDS without naming another elected officer: the
-- clerk appears only as "secretary of the council" and the chief administrative officer is
-- appointed by the mayor. ch. VI s 38 names the elective titles once more and only twice,
-- "offices of mayor and councilor". Saint Paul's charter gives a mayor at large and seven
-- councilmembers, one per ward, and no at-large council seat.
--
-- 🔴 DULUTH'S FOUR AT-LARGE SEATS ARE NOT NUMBERED AND THIS MIGRATION REFUSES TO NUMBER THEM.
-- All four are elected in ONE citywide race. Numbering them would describe a power Duluth does
-- not have. All four offices therefore carry the IDENTICAL voter-facing title, and the join key
-- lives in \`description\`, spelled out as an internal ordinal that is not a ballot designation.
-- ⚠ Saint Paul has NO at-large council seat, so this does not apply there -- the two cities are
-- deliberately NOT made uniform.
--
-- 🟢 A DULUTH COUNCIL DISTRICT MEANS LESS THAN IT LOOKS, AND THE CHARTER SAYS SO: "The council
-- districts are established herein solely for the purposes of electing district councilors. The
-- administration of the city shall never be divided, nor any facility ever provided, nor any
-- appropriation ever made upon a council district basis." (ch. II s 2)
--
-- 🔴 GEOMETRY COMES FROM scripts/load-mn-city-council-boundaries.ts (X0052, X0053), NOT from
-- here, and the pre-flight below FAILS HARD if those twelve boundaries are absent -- an office on
-- a district with no polygon is unreachable by address and nothing errors.
--
-- 🔴🔴 DULUTH PUBLISHES TWO COUNCIL-DISTRICT MAPS AND A COUNT CANNOT TELL THEM APART: both return
-- five features numbered 1-5. The superseded 2012 map leaves 8.68 SQ MI OF DULUTH IN NO DISTRICT
-- -- 89.18% coverage against the current map's 99.98%. The loader asserts coverage; this
-- migration asserts the loader ran and left the right \`source\` behind.
--
-- ⚠ THE TWO CITIES HAVE OPPOSITE SHAPES AGAINST THEIR PLACE POLYGON AND BOTH ARE CORRECT.
-- Saint Paul's seven wards tile the city exactly (100.000%). Duluth's five districts OVERHANG it
-- by 11.16 sq mi of Lake Superior and unincorporated township, of which only 0.045 touches
-- another incorporated place. Full coverage is the gate; an exact tiling is not.
--
-- ⚠ districts.state is written LOWERCASE 'mn', matching every other LOCAL district in production.
-- Always lower(d.state).
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight: the twelve council boundaries and both place polygons ───────

DO $$
DECLARE v_d int; v_s int;
BEGIN
  SELECT count(*) INTO v_d FROM essentials.geofence_boundaries WHERE mtfcc = 'X0052';
  IF v_d <> ${CITIES.Duluth.districts} THEN
    RAISE EXCEPTION 'MN-3 pre-flight: X0052 holds % Duluth council boundaries, expected ${CITIES.Duluth.districts}. Run scripts/load-mn-city-council-boundaries.ts first.', v_d;
  END IF;
  SELECT count(*) INTO v_s FROM essentials.geofence_boundaries WHERE mtfcc = 'X0053';
  IF v_s <> ${CITIES['Saint Paul'].districts} THEN
    RAISE EXCEPTION 'MN-3 pre-flight: X0053 holds % Saint Paul ward boundaries, expected ${CITIES['Saint Paul'].districts}. Run scripts/load-mn-city-council-boundaries.ts first.', v_s;
  END IF;
  -- The citywide seats -- both mayors and Duluth's four at-large councilors -- hang on the TIGER
  -- place polygons, which MN-1 loaded.
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '2717000' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'MN-3 pre-flight: TIGER place 2717000/G4110 (Duluth) is missing.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '2758000' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'MN-3 pre-flight: TIGER place 2758000/G4110 (St. Paul) is missing.';
  END IF;
  -- 🔴 The Duluth boundaries must have come from the CURRENT service. The loader stamps which.
  IF EXISTS (SELECT 1 FROM essentials.geofence_boundaries
              WHERE mtfcc = 'X0052' AND source NOT LIKE '%VotingDistricts/MapServer/16%') THEN
    RAISE EXCEPTION 'MN-3 pre-flight: an X0052 boundary did not come from VotingDistricts/MapServer/16 -- it may be the superseded 2012 map, which leaves 8.68 sq mi of Duluth in no district.';
  END IF;
END $$;

-- ─── 1. Two governments ──────────────────────────────────────────────────────
-- ⚠ Matched and guarded on geo_id, never on name. See the Texas note above.

${Object.entries(CITIES).map(([city, cfg]) => `INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT ${sql(cfg.government)}, 'City', 'MN', ${sql(city)}, ${sql(cfg.place_geo_id)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = ${sql(cfg.place_geo_id)});`).join('\n\n')}

-- ─── 2. Four chambers ────────────────────────────────────────────────────────

${Object.entries(CITIES).map(([city, cfg]) => [cfg.council, cfg.mayor].map((ch) => `INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, ${sql(ch.name)}, ${sql(ch.name === 'Office of the Mayor' ? `Office of the Mayor of ${city}` : ch.name)}, ${ch.official_count}
FROM essentials.governments g
WHERE g.geo_id = ${sql(cfg.place_geo_id)}
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = ${sql(ch.name)});`).join('\n\n')).join('\n\n')}

-- ─── 3. Fourteen districts ───────────────────────────────────────────────────
-- Twelve council districts on X0052/X0053, plus one citywide row per city on the TIGER place
-- polygon carrying the Mayor and, in Duluth, the four at-large councilors.

CREATE TEMP TABLE mn3_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO mn3_districts(geo_id, label, mtfcc) VALUES
${districtRows.map((d) => `  (${sql(d.geo_id)}, ${sql(d.label)}, ${sql(d.mtfcc)})`).join(',\n')};

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'mn', n.mtfcc
FROM mn3_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = n.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Eighteen offices ─────────────────────────────────────────────────────

CREATE TEMP TABLE mn3_offices(place_geo_id text, district_geo_id text, chamber_name text, title text, description text, city text) ON COMMIT DROP;
INSERT INTO mn3_offices(place_geo_id, district_geo_id, chamber_name, title, description, city) VALUES
${offices.map((o) => `  (${sql(o.cfg.place_geo_id)}, ${sql(o.geo_id)}, ${sql(o.chamber)}, ${sql(o.title)}, ${sql(o.description)}, ${sql(o.city)})`).join(',\n')};

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'MN', n.city, 1, false, 'full'
FROM mn3_offices n
JOIN essentials.districts d ON d.geo_id = n.district_geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'mn'
JOIN essentials.governments g ON g.geo_id = n.place_geo_id
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int; v_atlarge int; v_atlarge_desc int; v_tx int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE geo_id IN ('2717000','2758000');
  IF v_gov <> 2 THEN RAISE EXCEPTION 'MN-3 structure: expected 2 governments, got %', v_gov; END IF;

  -- 🔴 The Texas Saint Paul must be untouched and must still be the ONLY TX one.
  SELECT count(*) INTO v_tx FROM essentials.governments WHERE geo_id = '4864220' AND state = 'TX';
  IF v_tx <> 1 THEN RAISE EXCEPTION 'MN-3 structure: the Texas Saint Paul row (4864220) is not intact; got %', v_tx; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id IN ('2717000','2758000');
  IF v_ch <> 4 THEN RAISE EXCEPTION 'MN-3 structure: expected 4 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type::text = 'LOCAL' AND lower(state) = 'mn' AND mtfcc IN ('X0052','X0053');
  IF v_dist <> ${districtRows.filter((d) => d.mtfcc !== 'G4110').length} THEN
    RAISE EXCEPTION 'MN-3 structure: expected ${districtRows.filter((d) => d.mtfcc !== 'G4110').length} council districts, got %', v_dist;
  END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('2717000','2758000');
  IF v_off <> ${offices.length} THEN RAISE EXCEPTION 'MN-3 structure: expected ${offices.length} offices, got %', v_off; END IF;

  -- Duluth's four at-large offices must exist, share one title, and carry FOUR DISTINCT internal
  -- ordinals -- without which CC_0110 cannot attach a person to a seat deterministically.
  SELECT count(*), count(DISTINCT o.description) INTO v_atlarge, v_atlarge_desc
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '2717000' AND o.title = ${sql(CITIES.Duluth.atLargeTitle)};
  IF v_atlarge <> ${CITIES.Duluth.atLarge} OR v_atlarge_desc <> ${CITIES.Duluth.atLarge} THEN
    RAISE EXCEPTION 'MN-3 structure: Duluth at-large is % office(s) with % distinct description(s), expected ${CITIES.Duluth.atLarge} and ${CITIES.Duluth.atLarge}', v_atlarge, v_atlarge_desc;
  END IF;

  -- Saint Paul must have NO at-large council seat. The two cities are not made uniform.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.geo_id = '2758000' AND o.title ILIKE '%at large%'
  ) THEN
    RAISE EXCEPTION 'MN-3 structure: Saint Paul has an at-large council office; its charter creates none';
  END IF;

  -- Every council district must carry exactly one office.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE d.mtfcc IN ('X0052','X0053') AND lower(d.state) = 'mn'
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'MN-3 structure: a council district does not carry exactly one office';
  END IF;

  RAISE NOTICE 'MN-3 structure OK: % governments, % chambers, % council districts, % offices (Duluth at-large % distinct)',
    v_gov, v_ch, v_dist, v_off, v_atlarge_desc;
END $$;

COMMIT;
`;

// ═══════════════════════════════════════════════════════════════════════════════
// CC_0110 -- occupancy
// ═══════════════════════════════════════════════════════════════════════════════
const dated = people.filter((p) => p.term_start).length;
const precisions = [...new Set(people.map((p) => p.start_precision))];

const occupancy = `-- CC_0110_mn_cities_officials.sql
-- Knight Foundation program, wave MN-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0109, which creates the governments, chambers, districts and the
-- ${offices.length} offices.
--
-- Seats all ${offices.length} Duluth and Saint Paul city offices: **${people.length} people created**, external_id band
-- ${BAND_LO} .. ${BAND_HI}. **0 vacancies.**
--
-- 🟢 EVERY TERM IS DATED, AND THAT IS UNUSUAL FOR THIS PROGRAM. MN-2 wrote all 200 legislative
-- terms open-ended at 'unknown' because neither chamber publishes a date. Both cities do, so all
-- ${dated} of these carry a real term_start at ${precisions.map((p) => `'${p}'`).join(' / ')} precision:
--
--   2024-01-01  6  Duluth, elected November 2023 -- first Monday in January
--   2026-01-05  4  Duluth, elected November 2025 -- first Monday in January
--   2024-01-09  6  Saint Paul council, sworn in at the Ordway Center
--   2025-08-27  1  Saint Paul Ward 4, sworn in after the 2025-08-12 special election
--   2026-01-02  1  Saint Paul Mayor, sworn in as the city's 56th mayor
--
-- Duluth's boundary is the charter's own: ch. II s 4 has an appointee serve "until the first
-- Monday in January after the next municipal election", and every term-expiry date the city
-- publishes -- 2028-01-03, 2030-01-07 -- is a first Monday. The start is therefore derived from
-- the city's OWN published dates plus the charter's four-year term, not invented.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate. The stated
-- expiries are recorded in data/mn-cities-roster.json for the audit trail and are not loaded.
--
-- 🔴🔴 THE CHANGE-CHECK SIGNAL FOR A CITY COUNCIL IS AN EXPIRED DATE, NOT A BANNER. A word
-- scanner over all 18 member pages -- resigned, vacant, appointed, sworn in, stepping down,
-- interim -- returned ONE benign biographical hit, and all six of its positive controls fired.
-- It was still blind: Terese Tomanek's page says "Term Expires: January 5, 2026", read on
-- 2026-09-14. Nothing on the page is worded as a problem. ⚠ A control proves a detector is not
-- broken; it cannot prove the detector is looking at the right thing.
--
-- 🔴 ALL FOUR DULUTH AT-LARGE PAGES STATE THE SAME EXPIRED DATE, and the roster is right while
-- the pages are wrong. The DISTRIBUTION gave it away -- Duluth staggers its council, so its
-- expiries must not be uniform. November 2023 elected Forsman and Nephew at large; November 2025
-- elected Tomanek (re-elected) and Johnson (a newcomer, whose page states an expiry that predates
-- his own term). Settled against the election record, not against the page.
--
-- 🔴 THREE SEATS HAD TURNED OVER MID-TERM AND EACH WAS READ:
--   Duluth District 2  -- Mike Mayou resigned on moving out of the district; Deborah DeLuca was
--                         appointed INTERIM by unanimous council vote and served until the first
--                         Monday in January, as the charter requires; Diane Desotelle won the
--                         November general with 80%. The interim holder is NOT modelled: this
--                         wave seats who holds the seat today.
--   Duluth District 4  -- appeared in BOTH the 2023 and 2025 election listings, which read as a
--                         contradiction until the special election to the unexpired PARTIAL term
--                         explained it. Clanaugh beat Swenson in November 2025, 53% to 46%.
--   Saint Paul Ward 4  -- Council President Mitra Jalali resigned effective 2025-03-08; Molly
--                         Coleman won the 2025-08-12 special and was sworn in 2025-08-27. ⚠ Saint
--                         Paul's own council index says flatly that "Councilmembers were elected
--                         to a 4-year term in 2023", which is WRONG FOR THIS SEAT.
--
-- 🟢 NONE OF THE ${people.length} NAMES COLLIDES WITH AN ACTIVE POLITICIAN ROW. Zero exact
-- (first_name, last_name) matches, so essentials.politician_name_duplicate_guard blocks nothing
-- and there is nobody to reuse. ⚠ Kaohly Her exists in production under NO spelling -- checked
-- '%kaohly%' -- even though she is the same person the Minnesota House's Leadership tab still
-- lists for HD-64A. She left that seat by defeating the incumbent mayor on 2025-11-04, which is
-- what MN-2 found and could not explain from House sources alone.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party, never on a person or an office.
-- Duluth's municipal elections are non-partisan by charter (ch. VI s 38) in any case.
--
-- 🔴 DULUTH'S FOUR AT-LARGE OFFICES SHARE ONE TITLE, so a person is joined to a seat through the
-- INTERNAL ordinal CC_0109 wrote into \`description\`. Nothing reads that as a seat name.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── ${people.length} people ──────────────────────────────────────────────────────────────────

CREATE TEMP TABLE mn3_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[], source text)
  ON COMMIT DROP;
INSERT INTO mn3_people(external_id, full_name, first_name, last_name, alternate_names, source) VALUES
${people.map((p) => `  (${p.external_id}, ${sql(p.full_name)}, ${sql(p.first_name)}, ${sql(p.last_name)}, ${arr(p.alternate_names)}, ${sql(SOURCE(p.city))})`).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.source, n.alternate_names
FROM mn3_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── ${people.length} dated terms, one per office ─────────────────────────────────────────────

CREATE TEMP TABLE mn3_terms(place_geo_id text, district_geo_id text, title text, description text, external_id bigint, term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO mn3_terms(place_geo_id, district_geo_id, title, description, external_id, term_start, start_precision, how_started) VALUES
${people.map((p, i) => {
  const o = offices[i];
  return `  (${sql(o.cfg.place_geo_id)}, ${sql(o.geo_id)}, ${sql(o.title)}, ${sql(o.description)}, ${p.external_id}, ${sql(p.term_start)}::date, ${sql(p.start_precision)}, ${sql(p.how_started)})`;
}).join(',\n')};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       n.source || ' (CC_0110, MN-3)'
FROM mn3_terms t
JOIN essentials.districts d ON d.geo_id = t.district_geo_id AND d.district_type::text = 'LOCAL' AND lower(d.state) = 'mn'
JOIN essentials.governments g ON g.geo_id = t.place_geo_id
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.district_id = d.id AND o.chamber_id = c.id AND o.title = t.title
  AND o.description IS NOT DISTINCT FROM t.description
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN mn3_people n ON n.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_offices int; v_seated int; v_terms int; v_undated int; v_ended int;
  v_duluth int; v_stpaul int; v_distinct_al int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN ${BAND_LO} AND ${BAND_HI};
  IF v_people <> ${people.length} THEN RAISE EXCEPTION 'MN-3 occupancy: expected ${people.length} people in the reserved band, got %', v_people; END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id IN ('2717000','2758000');
  IF v_offices <> ${offices.length} THEN RAISE EXCEPTION 'MN-3 occupancy: expected ${offices.length} offices, got %', v_offices; END IF;

  -- och.politician_id, never count(*): office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id),
         count(och.politician_id) FILTER (WHERE g.geo_id = '2717000'),
         count(och.politician_id) FILTER (WHERE g.geo_id = '2758000')
    INTO v_seated, v_duluth, v_stpaul
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.geo_id IN ('2717000','2758000');
  IF v_seated <> ${offices.length} THEN RAISE EXCEPTION 'MN-3 occupancy: expected ${offices.length} seated, got %', v_seated; END IF;
  IF v_duluth <> ${byCity('Duluth').length} OR v_stpaul <> ${byCity('Saint Paul').length} THEN
    RAISE EXCEPTION 'MN-3 occupancy: expected ${byCity('Duluth').length} Duluth + ${byCity('Saint Paul').length} Saint Paul, got % + %', v_duluth, v_stpaul;
  END IF;

  SELECT count(*), count(*) FILTER (WHERE t.term_start IS NULL), count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_terms, v_undated, v_ended
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('2717000','2758000');
  IF v_terms <> ${people.length} THEN RAISE EXCEPTION 'MN-3 occupancy: expected ${people.length} term rows, got %', v_terms; END IF;
  -- 🟢 Unlike MN-2, EVERY term here is dated. An undated one means a source was lost.
  IF v_undated <> 0 THEN RAISE EXCEPTION 'MN-3 occupancy: % term(s) carry no term_start; both cities publish one', v_undated; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'MN-3 occupancy: % term(s) carry a term_end; a future term_end self-vacates the seat', v_ended; END IF;

  -- Duluth's four at-large offices must hold FOUR DIFFERENT people.
  SELECT count(DISTINCT och.politician_id) INTO v_distinct_al
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.geo_id = '2717000' AND o.title = ${sql(CITIES.Duluth.atLargeTitle)};
  IF v_distinct_al <> ${CITIES.Duluth.atLarge} THEN
    RAISE EXCEPTION 'MN-3 occupancy: Duluth at-large seats hold % distinct people, expected ${CITIES.Duluth.atLarge}', v_distinct_al;
  END IF;

  RAISE NOTICE 'MN-3 occupancy OK: % people, % offices, % seated (% Duluth + % Saint Paul), % terms, 0 undated, 0 ended, % distinct at-large',
    v_people, v_offices, v_seated, v_duluth, v_stpaul, v_terms, v_distinct_al;
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIG, 'CC_0109_mn_cities_structure.sql'), structure);
fs.writeFileSync(path.join(MIG, 'CC_0110_mn_cities_officials.sql'), occupancy);

console.log(`CC_0109_mn_cities_structure.sql  2 governments, 4 chambers, ${districtRows.length} districts, ${offices.length} offices`);
console.log(`CC_0110_mn_cities_officials.sql  ${people.length} people, ${people.length} dated terms, 0 vacancies`);
console.log(`external_id band used: ${people[people.length - 1].external_id} .. ${people[0].external_id}`);
console.log(`Duluth at-large ordinals: ${atLargeOrder.map((r, i) => `${i + 1}=${r.full_name}`).join(', ')}`);
