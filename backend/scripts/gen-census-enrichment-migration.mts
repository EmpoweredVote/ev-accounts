/**
 * Generates a districts-enrichment migration from the Census Government Units Listing.
 *
 *   npx tsx scripts/gen-census-enrichment-migration.mts \
 *     --states=ca,or --out=migrations/1619_districts_census_population_and_web.sql
 *
 * Emits only rows that matched one of our districts on FIPS. Name matching is never used here —
 * a wrong match would attribute a whole city's population to the wrong geography.
 *
 * Take the next free migration number per CLAUDE.md and verify with `npm run check:migrations`.
 * The migration adds its columns with IF NOT EXISTS, so a second state batch re-runs safely.
 */
import { writeFileSync, readFileSync } from 'node:fs';
import * as XLSX from 'xlsx';
import { pool } from '../src/lib/db.js';

const arg = (n: string, d: string) =>
  process.argv.find((a) => a.startsWith(`--${n}=`))?.split('=').slice(1).join('=') ?? d;
const STATES = arg('states', 'ca,or').split(',').map((s) => s.trim().toLowerCase());
const XLSX_PATH = arg('census', 'data/census-gov-units/Govt_Units_2025_Final.xlsx');
const OUT = arg('out', 'migrations/1619_districts_census_population_and_web.sql');

const STATE_FIPS: Record<string, string> = {
  al: '01', ak: '02', az: '04', ar: '05', ca: '06', co: '08', ct: '09', de: '10', dc: '11',
  fl: '12', ga: '13', hi: '15', id: '16', il: '17', in: '18', ia: '19', ks: '20', ky: '21',
  la: '22', me: '23', md: '24', ma: '25', mi: '26', mn: '27', ms: '28', mo: '29', mt: '30',
  ne: '31', nv: '32', nh: '33', nj: '34', nm: '35', ny: '36', nc: '37', nd: '38', oh: '39',
  ok: '40', or: '41', pa: '42', ri: '44', sc: '45', sd: '46', tn: '47', tx: '48', ut: '49',
  vt: '50', va: '51', wa: '53', wv: '54', wi: '55', wy: '56',
};
const q = (s: string | null) => (s === null ? 'NULL' : `'${s.replace(/'/g, "''")}'`);

async function main() {
  const wanted = new Set(STATES.map((s) => STATE_FIPS[s]));
  const wb = XLSX.read(readFileSync(XLSX_PATH), { type: 'buffer' });
  const raw = XLSX.utils.sheet_to_json<Record<string, unknown>>(wb.Sheets['General Purpose'], { raw: true, defval: null });

  const units = new Map<string, { name: string; pop: number | null; year: string | null; web: string | null; id: string }>();
  for (const r of raw) {
    if (String(r.ACTIVE ?? '').trim() !== 'Y') continue;
    const fs = String(r.FIPS_STATE ?? '').padStart(2, '0');
    if (!wanted.has(fs)) continue;
    const isCounty = String(r.UNIT_TYPE ?? '').startsWith('1');
    const key = isCounty
      ? fs + String(r.FIPS_COUNTY ?? '').padStart(3, '0')
      : fs + String(r.FIPS_PLACE ?? '').padStart(5, '0');
    const popN = Number(String(r.POPULATION ?? '').replace(/,/g, ''));
    const web = String(r.WEB_ADDRESS ?? '').trim();
    units.set(key, {
      name: String(r.UNIT_NAME ?? '').trim(),
      pop: Number.isFinite(popN) && String(r.POPULATION ?? '') !== '' ? popN : null,
      year: r.POPULATION_SOURCE_YEAR ? String(r.POPULATION_SOURCE_YEAR) : null,
      // Only accept a real absolute URL. Census leaves partial junk in this column.
      web: /^https?:\/\//i.test(web) ? web : null,
      id: String(r.CENSUS_ID_PID6 ?? ''),
    });
  }

  // Only emit units that actually match a district we hold, on FIPS alone.
  const { rows } = await pool.query<{ geo_id: string }>(`
    SELECT DISTINCT btrim(geo_id) AS geo_id
    FROM essentials.districts
    WHERE lower(state) = ANY($1::text[])
      AND district_type IN ('LOCAL','LOCAL_EXEC','COUNTY')
      AND btrim(geo_id) ~ '^[0-9]+$'
      AND length(btrim(geo_id)) IN (5, 7)`, [STATES]);

  const matched = rows.map((r) => r.geo_id).filter((g) => units.has(g)).sort();
  const values = matched.map((g) => {
    const u = units.get(g)!;
    // The name goes ABOVE the tuple, never after it: a trailing `-- comment` swallows the row
    // delimiter that join() appends, silently truncating the INSERT.
    return `    -- ${u.name}\n    (${q(g)}, ${u.pop ?? 'NULL'}, ${u.year ?? 'NULL'}, ${q(u.web)}, ${q(u.id)})`;
  });

  const withPop = matched.filter((g) => units.get(g)!.pop !== null).length;
  const withWeb = matched.filter((g) => units.get(g)!.web !== null).length;

  const sql = `-- 1619_districts_census_population_and_web.sql
--
-- Adds population and official web address to essentials.districts, backfilled from the
-- Census Bureau Government Units Listing 2025 (Annual Organization public use file):
--   https://www.census.gov/programs-surveys/gus/data/publicusefiles.html
--   https://www2.census.gov/programs-surveys/gus/datasets/2025/gov_units_2025.zip
--
-- Scope: ${STATES.map((s) => s.toUpperCase()).join(' + ')}. ${matched.length} government units matched one or more of our
-- districts. ${withPop} carry a population, ${withWeb} carry a usable official URL.
--
-- MATCHED ON FIPS ONLY -- never on name. Counties key on FIPS_STATE||FIPS_COUNTY (the file's
-- FIPS_PLACE for a county is a synthetic '99'+county code), places on FIPS_STATE||FIPS_PLACE.
-- A name match here would attribute a whole city's population to the wrong geography.
--
-- geo_id is deliberately NOT unique: an at-large body models each seat as its own district row,
-- so several rows share a place FIPS. Updating every row carrying that FIPS is correct -- they
-- describe the same place.
--
-- Idempotent. Re-running overwrites with the same source values and re-passes the gate.
-- Generated by scripts/gen-census-enrichment-migration.mts.

BEGIN;

ALTER TABLE essentials.districts
  ADD COLUMN IF NOT EXISTS population             integer,
  ADD COLUMN IF NOT EXISTS population_source_year smallint,
  ADD COLUMN IF NOT EXISTS official_web_url       text,
  ADD COLUMN IF NOT EXISTS census_unit_id         text;

COMMENT ON COLUMN essentials.districts.population IS
  'Resident population from the Census Government Units Listing 2025. See population_source_year for the vintage. Backfilled by migration 1619; NULL means not sourced, never zero.';
COMMENT ON COLUMN essentials.districts.population_source_year IS
  'Vintage of the population estimate, as published by the Census (migration 1619).';
COMMENT ON COLUMN essentials.districts.official_web_url IS
  'Official government URL as published in the Census Government Units Listing 2025 (migration 1619). Absolute http(s) only.';
COMMENT ON COLUMN essentials.districts.census_unit_id IS
  'CENSUS_ID_PID6 of the matching Government Units Listing record (migration 1619). Provenance and re-join key for future refreshes.';

CREATE TEMP TABLE _census_units (
  geo_id         text PRIMARY KEY,
  population     integer,
  pop_year       smallint,
  web_url        text,
  census_unit_id text
) ON COMMIT DROP;

INSERT INTO _census_units (geo_id, population, pop_year, web_url, census_unit_id) VALUES
${values.join(',\n')}
;

UPDATE essentials.districts d
   SET population             = c.population,
       population_source_year = c.pop_year,
       official_web_url       = c.web_url,
       census_unit_id         = c.census_unit_id
  FROM _census_units c
 WHERE btrim(d.geo_id) = c.geo_id
   AND lower(d.state) = ANY (ARRAY[${STATES.map((s) => `'${s}'`).join(', ')}])
   AND d.district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY')
   AND (d.population             IS DISTINCT FROM c.population
     OR d.population_source_year IS DISTINCT FROM c.pop_year
     OR d.official_web_url       IS DISTINCT FROM c.web_url
     OR d.census_unit_id         IS DISTINCT FROM c.census_unit_id);

DO $$
DECLARE
  v_staged   integer;
  v_enriched integer;
  v_bad_pop  integer;
  v_bad_url  integer;
  v_orphan   integer;
BEGIN
  SELECT count(*) INTO v_staged FROM _census_units;
  IF v_staged <> ${matched.length} THEN
    RAISE EXCEPTION '1619: staged % units, expected ${matched.length}', v_staged;
  END IF;

  -- Every district carrying a matched FIPS must now be enriched. If this count drops, the join
  -- silently missed rows and the coverage figures built on it would be wrong.
  SELECT count(*) INTO v_enriched
    FROM essentials.districts d
    JOIN _census_units c ON btrim(d.geo_id) = c.geo_id
   WHERE lower(d.state) = ANY (ARRAY[${STATES.map((s) => `'${s}'`).join(', ')}])
     AND d.district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY')
     AND d.census_unit_id IS NOT DISTINCT FROM c.census_unit_id;
  IF v_enriched = 0 THEN
    RAISE EXCEPTION '1619: no districts were enriched';
  END IF;

  -- Population is a count of people: zero or negative is a parse failure, not a small town.
  SELECT count(*) INTO v_bad_pop
    FROM essentials.districts
   WHERE population IS NOT NULL AND population <= 0;
  IF v_bad_pop > 0 THEN
    RAISE EXCEPTION '1619: % districts have a non-positive population', v_bad_pop;
  END IF;

  SELECT count(*) INTO v_bad_url
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL AND official_web_url !~* '^https?://';
  IF v_bad_url > 0 THEN
    RAISE EXCEPTION '1619: % districts have a non-absolute official_web_url', v_bad_url;
  END IF;

  -- Nothing outside the intended scope may have been touched.
  SELECT count(*) INTO v_orphan
    FROM essentials.districts
   WHERE census_unit_id IS NOT NULL
     AND (lower(state) <> ALL (ARRAY[${STATES.map((s) => `'${s}'`).join(', ')}])
       OR district_type NOT IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY'));
  IF v_orphan > 0 THEN
    RAISE EXCEPTION '1619: % districts enriched outside the intended scope', v_orphan;
  END IF;

  RAISE NOTICE '1619 OK: % units staged, % district rows enriched', v_staged, v_enriched;
END $$;

COMMIT;
`;

  writeFileSync(OUT, sql, 'utf8');
  console.log(`[gen] ${matched.length} units matched (${withPop} with population, ${withWeb} with URL)`);
  console.log(`[gen] wrote ${OUT}`);
}

main().catch((e) => { console.error(e); process.exitCode = 1; }).finally(() => pool.end());
