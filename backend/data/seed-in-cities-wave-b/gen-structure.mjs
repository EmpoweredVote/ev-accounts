#!/usr/bin/env node
// gen-structure.mjs — writes ONE structure migration for a set of Indiana cities from structure.json.
//
// Each city gets: a government, three chambers (council, mayor, clerk), N council districts on X0091 plus
// one citywide district on its TIGER place polygon, and N + at-large + 2 offices. NO people, NO terms.
// The shape is CC_0090 (Fort Wayne) generalised; read that file's header for the reasoning behind every
// choice (unnumbered at-large seats with an INTERNAL ordinal in description, lowercase 'in' on LOCAL
// districts, pre-flight on the boundaries, post-verify per city).
//
// Usage: node gen-structure.mjs <migration-name-without-.sql> <slug,slug,...|all>
//   e.g. node gen-structure.mjs CA_0400_indiana_cities_wave_b_structure all
import fs from 'node:fs';
import path from 'node:path';

const DIR = path.dirname(new URL(import.meta.url).pathname);
const [name, which] = process.argv.slice(2);
if (!name || !which) { console.error('usage: gen-structure.mjs <migration-name> <slugs|all>'); process.exit(2); }
const all = JSON.parse(fs.readFileSync(path.join(DIR, 'structure.json'), 'utf8'));
const cities = which === 'all' ? all : all.filter((c) => which.split(',').includes(c.slug));
if (!cities.length) { console.error('no cities selected'); process.exit(2); }

const lit = (s) => (s == null ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
const gov = (c) => `City of ${c.name}, Indiana, US`;
const clerkChamber = (c) => (c.clerk_title === 'City Clerk' ? 'Office of the City Clerk' : 'Office of the Clerk-Treasurer');
for (const c of cities) {
  if (!['City Clerk', 'Clerk-Treasurer'].includes(c.clerk_title)) throw new Error(`${c.slug}: clerk_title ${c.clerk_title}`);
  if (c.district_seats + c.at_large_seats !== c.council_size) throw new Error(`${c.slug}: seat arithmetic`);
  if (!/^18\d{5}$/.test(c.geoid)) throw new Error(`${c.slug}: geoid ${c.geoid}`);
}

const govRows = [], chamberRows = [], distRows = [], officeRows = [], expect = [];
for (const c of cities) {
  govRows.push(`  (${lit(gov(c))}, ${lit(c.name)}, ${lit(c.geoid)})`);
  chamberRows.push(`  (${lit(gov(c))}, ${lit(c.council_name)}, ${c.council_size})`,
                   `  (${lit(gov(c))}, 'Office of the Mayor', 1)`,
                   `  (${lit(gov(c))}, ${lit(clerkChamber(c))}, 1)`);
  // district_numbers: a city whose districts are not numbered 1..N (Jasper: 2-6) lists its own numbers.
  const nums = c.district_numbers ?? Array.from({ length: c.district_seats }, (_, i) => i + 1);
  if (nums.length !== c.district_seats) throw new Error(`${c.slug}: district_numbers length`);
  for (const d of nums) {
    const g = `${c.slug}-council-district-${d}`;
    distRows.push(`  (${lit(g)}, ${lit(`${c.name} City Council District ${d}`)}, 'X0091')`);
    officeRows.push(`  (${lit(gov(c))}, ${lit(g)}, ${lit(c.council_name)}, ${lit(`Council Member, District ${d}`)}, NULL)`);
  }
  distRows.push(`  (${lit(c.geoid)}, ${lit(`${c.name} Citywide`)}, 'G4110')`);
  for (let i = 1; i <= c.at_large_seats; i++) {
    officeRows.push(`  (${lit(gov(c))}, ${lit(c.geoid)}, ${lit(c.council_name)}, 'Council Member, At Large', ` +
      lit(`Internal ordinal ${i} of ${c.at_large_seats}. ${c.name} does not number its at-large seats; not a ballot designation.`) + ')');
  }
  officeRows.push(`  (${lit(gov(c))}, ${lit(c.geoid)}, 'Office of the Mayor', 'Mayor', NULL)`,
                  `  (${lit(gov(c))}, ${lit(c.geoid)}, ${lit(clerkChamber(c))}, ${lit(c.clerk_title)}, NULL)`);
  expect.push(`  (${lit(gov(c))}, ${lit(c.slug)}, ${lit(c.geoid)}, ${c.district_seats}, ${c.at_large_seats}, ${lit(c.council_name)})`);
}
const totalOffices = cities.reduce((s, c) => s + c.council_size + 2, 0);
const totalDistricts = cities.reduce((s, c) => s + c.district_seats + 1, 0);

const header = cities.map((c) =>
  `--   ${c.name.padEnd(16)} ${String(c.district_seats).padStart(1)} district + ${c.at_large_seats} at-large · ${c.clerk_title.padEnd(15)} · ${c.structure_source}`).join('\n');

const sql = `-- ${name}.sql
-- Indiana cities Wave B, structure half. Slot RESERVED from the allocator.
-- Scope note: .planning/todos/2026-11-24-indiana-cities-2027-scope.md
--
-- Creates ${cities.length} city governments, ${cities.length * 3} chambers, ${totalDistricts} districts and ${totalOffices} offices.
-- Creates NO people and NO terms -- the people migration does that.
-- 🔴 APPLY THE PEOPLE MIGRATION THE SAME DAY. Until it runs, every new district is an office with a polygon,
-- no holder and no vacancy flag, which check:reachability counts as DEAD_GEOGRAPHY (CA_0416 alone took
-- in|LOCAL from 12 to 101 and held the gate red until CA_0417 landed).
--
-- Structure per city, from IC 36-4-6-3 / 36-4-6-4 / 36-4-10-2 and confirmed on each city's own site
-- (data/seed-in-cities-wave-b/cities/<slug>.json, checked by verify-collect.mjs):
${header}
--
-- 🔴 THE AT-LARGE SEATS ARE NOT NUMBERED. Indiana elects them in one citywide race (top N win), so every
-- at-large office carries the identical title 'Council Member, At Large'. The ordinal in description is
-- INTERNAL, exists only so the people migration can attach a person deterministically, and is labelled so.
-- (CC_0090 header, the DESCRIBE-REAL-POWERS rule.)
--
-- 🔴 GEOMETRY COMES FROM scripts/load-indiana-city-council-boundaries.ts (X0091), NOT from here. The
-- pre-flight FAILS HARD unless every city has exactly its district count of X0091 boundaries and its TIGER
-- place polygon -- an office on a district with no polygon is unreachable by address and nothing errors.
--
-- ⚠ City court judges are NOT modelled in this wave (scope decision pending).
-- ⚠ districts.state is lowercase 'in' on LOCAL districts (CC_0090). Always lower(d.state).
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate per city.

BEGIN;

CREATE TEMP TABLE w_city(gov text, slug text, geoid text, n_dist int, n_al int, council text) ON COMMIT DROP;
INSERT INTO w_city VALUES
${expect.join(',\n')};

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE r record; v_b int;
BEGIN
  FOR r IN SELECT * FROM w_city LOOP
    SELECT count(*) INTO v_b FROM essentials.geofence_boundaries
     WHERE mtfcc = 'X0091' AND geo_id LIKE r.slug || '-council-district-%';
    IF v_b <> r.n_dist THEN
      RAISE EXCEPTION 'pre-flight: X0091 holds % council boundaries for %, expected %. Run scripts/load-indiana-city-council-boundaries.ts first.', v_b, r.slug, r.n_dist;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = r.geoid AND mtfcc = 'G4110') THEN
      RAISE EXCEPTION 'pre-flight: TIGER place %/G4110 (%) is missing', r.geoid, r.slug;
    END IF;
    -- A government already on this place under ANOTHER name would be duplicated silently by the name guard.
    IF EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id = r.geoid AND g.name <> r.gov) THEN
      RAISE EXCEPTION 'pre-flight: place % already has a government under a different name', r.geoid;
    END IF;
  END LOOP;
END $$;

-- ─── 1. Governments ──────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT v.name, 'City', 'IN', v.city, v.geo_id, 'G4110'
FROM (VALUES
${govRows.join(',\n')}
) AS v(name, city, geo_id)
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.name = v.name);

-- ─── 2. Chambers ─────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM (VALUES
${chamberRows.join(',\n')}
) AS v(gov, name, official_count)
JOIN essentials.governments g ON g.name = v.gov
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Districts ────────────────────────────────────────────────────────────
-- Council districts on X0091; one citywide row per city on its TIGER place polygon, which carries the
-- Mayor, the clerk and the at-large seats.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT v.geo_id, v.label, 'LOCAL', 'in', v.mtfcc
FROM (VALUES
${distRows.join(',\n')}
) AS v(geo_id, label, mtfcc)
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Offices ──────────────────────────────────────────────────────────────

CREATE TEMP TABLE w_off(gov text, geo_id text, chamber text, title text, description text) ON COMMIT DROP;
INSERT INTO w_off VALUES
${officeRows.join(',\n')};

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'IN', g.city, 1, false, 'full'
FROM w_off n
JOIN essentials.governments g ON g.name = n.gov
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify, per city ───────────────────────────────────────────────────

DO $$
DECLARE r record; v_gov int; v_ch int; v_off int; v_council int; v_al int; v_dist int; v_unreach int;
        v_total int := 0;
BEGIN
  FOR r IN SELECT * FROM w_city LOOP
    SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = r.gov;
    SELECT count(*) INTO v_ch FROM essentials.chambers c JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = r.gov;
    SELECT count(*), count(*) FILTER (WHERE c.name = r.council), count(*) FILTER (WHERE o.title = 'Council Member, At Large')
      INTO v_off, v_council, v_al
      FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = r.gov;
    SELECT count(*) INTO v_dist FROM essentials.districts
     WHERE district_type = 'LOCAL' AND lower(state) = 'in'
       AND (geo_id LIKE r.slug || '-council-district-%' OR geo_id = r.geoid);
    -- 🔴 Every district must meet a boundary on (geo_id, mtfcc), or its officeholder is invisible at an address.
    SELECT count(*) INTO v_unreach FROM essentials.districts d
     WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'in'
       AND (d.geo_id LIKE r.slug || '-council-district-%' OR d.geo_id = r.geoid)
       AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
    IF v_gov <> 1 OR v_ch <> 3 OR v_off <> r.n_dist + r.n_al + 2 OR v_council <> r.n_dist + r.n_al
       OR v_al <> r.n_al OR v_dist <> r.n_dist + 1 OR v_unreach <> 0 THEN
      RAISE EXCEPTION 'post-verify %: gov % ch % offices % (want %) council % al % districts % (want %) unreachable %',
        r.slug, v_gov, v_ch, v_off, r.n_dist + r.n_al + 2, v_council, v_al, v_dist, r.n_dist + 1, v_unreach;
    END IF;
    RAISE NOTICE 'ok %: % offices (% district + % at-large + mayor + clerk), % districts, all reachable',
      r.slug, v_off, r.n_dist, r.n_al, v_dist;
    v_total := v_total + v_off;
  END LOOP;
  IF v_total <> ${totalOffices} THEN RAISE EXCEPTION 'post-verify: % offices in total, expected ${totalOffices}', v_total; END IF;
  RAISE NOTICE 'structure OK: ${cities.length} cities, ${totalOffices} offices, ${totalDistricts} districts';
END $$;

COMMIT;
`;
const out = path.resolve(DIR, '../../migrations', `${name}.sql`);
fs.writeFileSync(out, sql);
console.log(`wrote ${out}: ${cities.length} cities, ${totalOffices} offices, ${totalDistricts} districts`);
