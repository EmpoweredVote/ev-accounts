/**
 * gen-ga3-milledgeville-migrations.mjs
 *
 * Generates the three GA-3 migrations from backend/data/ga3-milledgeville-roster.json:
 *
 *   CC_wip_milledgeville_structure.sql   1 government, 2 chambers, 7 districts, 7 offices
 *   CC_wip_milledgeville_people.sql      7 politicians, 7 open-ended terms
 *   CC_wip_baldwin_county.sql            1 government, 2 chambers, 6 districts,
 *                                        11 offices, 11 politicians, 11 terms
 *
 * Wave GA-3 Task 3 of the Knight Foundation cities program.
 * Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md
 * Roster: backend/data/seed-milledgeville-2026/ROSTERS.md
 *
 * Usage:  node scripts/gen-ga3-milledgeville-migrations.mjs
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE NUMBER IS TAKEN LAST. These emit as CC_wip_*.sql. Rename, apply and
 *    commit in one go, after re-counting against EVERY remote ref — not against
 *    PROGRAM.md, which records what the last wave took, a different question.
 *    Verified 2026-09-01: CC_0026 is the highest slot across all 81 remote refs,
 *    so these become CC_0027, CC_0028 and CC_0029.
 *
 * 🔴 STRUCTURE AND OCCUPANCY ARE SPLIT FOR THE CITY, JOINED FOR THE COUNTY.
 *    Spec §3: a county wave emits ONE migration, because an office with no
 *    office_terms row is invisible — no holder, so the official appears nowhere,
 *    and NOTHING ERRORS. Shipping county offices and county people separately
 *    would push offices_missing_terms above its 655-unflagged baseline for the
 *    days between the two applies.
 *
 * ⚠ THE CITY OCCUPANCY HALF CANNOT BE DRY-RUN ALONE — its offices do not exist
 *   yet. Run both city halves as ONE transaction ending in ROLLBACK, and assert
 *   the stream holds exactly one BEGIN, one ROLLBACK and ZERO COMMIT before
 *   sending it. That is the FL-6 method.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 ALL 18 TERMS ARE OPEN-ENDED AT start_precision 'unknown' (ruling R4).
 *
 * essentials.seat_officeholder() REFUSES a NULL term_start. Every person in this
 * wave has one, so every row takes the direct-insert path that CC_0009
 * established — and that path is only safe into an office with ZERO existing
 * term rows, because the helper's two-step exists to close a predecessor before
 * an open-ended range overlaps it. With no predecessor there is nothing to close
 * and the exclusion constraint cannot fire. The generated guard REFUSES rather
 * than guesses if that stops being true.
 *
 * Georgia publishes no service-start for either body, and term_start is the start
 * of CONTINUOUS occupancy, which re-election does not end. Four of the seven city
 * members are incumbents whose occupancy predates the 2025 election. The certified
 * election dates ARE known and are written into the headers as prose — they are
 * not term_starts.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const BACKEND = join(HERE, '..');
const ROSTER = join(BACKEND, 'data', 'ga3-milledgeville-roster.json');
const OUT_DIR = join(BACKEND, 'migrations');

const r = JSON.parse(readFileSync(ROSTER, 'utf8'));

/** SQL single-quoted literal. */
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
/** SQL text[] literal from a JS array of strings. */
const arr = (a) => (!a || a.length === 0 ? `'{}'::text[]` : `ARRAY[${a.map(q).join(', ')}]::text[]`);

// ── sanity on the roster itself, before a line of SQL is written ─────────────
function assertRoster() {
  const all = [...r.city.offices, ...r.county.offices];
  if (all.length !== 18) throw new Error(`expected 18 offices in the roster, got ${all.length}`);

  const ids = all.map((o) => o.person.external_id);
  if (new Set(ids).size !== ids.length) throw new Error('duplicate external_id in the roster');
  const { min, max } = r.id_band;
  for (const id of ids) {
    if (id < min || id > max) throw new Error(`external_id ${id} is outside the declared band ${min}..${max}`);
  }
  if (Math.min(...ids) !== min || Math.max(...ids) !== max) {
    throw new Error(`the declared band ${min}..${max} does not match the ids actually used`);
  }

  for (const side of ['city', 'county']) {
    const names = new Set(r[side].chambers.map((c) => c.name));
    for (const o of r[side].offices) {
      if (!names.has(o.chamber)) throw new Error(`${side}: office '${o.title}' names unknown chamber '${o.chamber}'`);
    }
    const seats = r[side].offices.map((o) => `${o.district_geo_id}|${o.district_mtfcc}|${o.title}`);
    if (new Set(seats).size !== seats.length) throw new Error(`${side}: duplicate seat key`);
  }

  // 🔴 Party must not have leaked into a person or an office. It lives on
  //    races.primary_party. A generator is exactly where this leaks back in.
  const json = JSON.stringify(r).toLowerCase();
  for (const w of ['"party"', '"republican"', '"democrat"', '"(dem)"', '"(rep)"']) {
    if (json.includes(w)) throw new Error(`the roster carries ${w} — party belongs on races.primary_party only`);
  }
  console.log(`roster OK: 18 offices, 18 unique ids, band ${min}..${max}, no party fields`);
}

/** The wide (citywide / countywide) district for a tier. */
const wideOf = (side) => (side === 'city' ? r[side].citywide_district : r[side].countywide_district);

/**
 * 🔴 DISTRICT TYPE DIFFERS BY TIER, AND THE FIRST DRAFT OF THIS GENERATOR HAD IT
 *    WRONG FOR THE COUNTY.
 *
 *   CITY   districts are district_type 'LOCAL'   (Bradenton, CC_0008)
 *   COUNTY districts are district_type 'COUNTY'  (Manatee,   CC_0010)
 *
 * 🔴 AND THE WIDE DISTRICT IS CREATED FOR THE CITY BUT ONLY ASSERTED FOR THE
 *    COUNTY. GA-1 loaded the TIGER place BOUNDARY 1351492/G4110 and created no
 *    place DISTRICT, so the citywide district has to be inserted here. But the
 *    TIGER county load already created 13009/G4020 as a COUNTY district —
 *    verified in production 2026-09-01 — so inserting it again would put a
 *    second district row over the same ground. CC_0010 asserts it in the
 *    pre-flight and inserts nothing, and that is what this generator now does.
 */
function districtRows(side) {
  const s = r[side];
  const rows = [];
  const wide = wideOf(side);
  if (wide.create) {
    rows.push({ label: wide.label, geo_id: wide.geo_id, mtfcc: wide.mtfcc, num: 'NULL' });
  }
  for (let i = 1; i <= s.district_count; i++) {
    rows.push({
      label: `${s.district_label_prefix}${i}`,
      geo_id: `${s.district_geo_id_prefix}${i}`,
      mtfcc: s.district_mtfcc,
      num: '1',
    });
  }
  return rows;
}

function districtsSql(side) {
  const dt = r[side].district_type;
  const wide = wideOf(side);
  const preamble = wide.create
    ? ''
    : `-- ⚠ ${wide.geo_id}/${wide.mtfcc} IS NOT CREATED HERE. It already exists as a\n` +
      `-- ${dt} district from the TIGER county load, verified in production\n` +
      `-- 2026-09-01. The pre-flight above asserts it. Inserting it again would put a\n` +
      `-- second district row over the same ground.\n\n`;
  return (
    preamble +
    districtRows(side)
      .map(
        (d) => `INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT ${q(dt)}, ${q(d.label)}, 'ga', ${q(d.geo_id)}, ${q(d.mtfcc)}, ${d.num}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = ${q(d.geo_id)} AND mtfcc = ${q(d.mtfcc)} AND district_type = ${q(dt)}
);`,
      )
      .join('\n')
  );
}

function governmentSql(side) {
  const g = r[side].government;
  return `INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT ${q(g.name)}, ${q(g.type)}, ${q(g.state)}, ${q(g.city)}, ${q(g.geo_id)}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = ${q(g.geo_id)} AND type = ${q(g.type)}
);`;
}

function chambersSql(side) {
  const g = r[side].government;
  return r[side].chambers
    .map(
      (c) => `INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, ${q(c.name)}, ${q(c.name_formal)}, ${c.official_count}, 'full'
FROM essentials.governments g
WHERE g.geo_id = ${q(g.geo_id)} AND g.type = ${q(g.type)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = ${q(c.name)}
  );`,
    )
    .join('\n\n');
}

function officesSql(side) {
  const g = r[side].government;
  const dt = r[side].district_type;
  return r[side].offices
    .map((o) => {
      const cols = ['chamber_id', 'district_id', 'title', 'representing_state', 'representing_city', 'voting_powers'];
      const vals = ['c.id', 'd.id', q(o.title), q(g.state), q(g.city), q(o.voting_powers)];
      if (o.description) {
        cols.push('description');
        vals.push(q(o.description));
      }
      return `INSERT INTO essentials.offices
  (${cols.join(', ')})
SELECT ${vals.join(', ')}
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
   WHERE dd.geo_id = ${q(o.district_geo_id)} AND dd.mtfcc = ${q(o.district_mtfcc)}
     AND dd.district_type = ${q(dt)} AND lower(dd.state) = 'ga'
) d
WHERE g.geo_id = ${q(g.geo_id)} AND g.type = ${q(g.type)} AND c.name = ${q(o.chamber)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = ${q(o.title)}
  );`;
    })
    .join('\n');
}

function preflightSql(side, tag) {
  const s = r[side];
  const wide = side === 'city' ? s.citywide_district : s.countywide_district;
  return `-- --- 0. Pre-flight: refuse to create offices whose district has no polygon ---
-- 🔴 An office on a district with no boundary is an office NOBODY CAN REACH BY
-- ADDRESS, and nothing else in the system errors. This is the only failure mode
-- CI cannot catch after the fact.
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = ${q(s.district_mtfcc)};
  IF v_n <> ${s.district_count} THEN
    RAISE EXCEPTION '${tag}: expected ${s.district_count} ${s.district_mtfcc} boundaries, found % -- run the GA-3 boundary loader first', v_n;
  END IF;

  -- ⚠ ALWAYS PAIR geo_id WITH mtfcc. Georgia's collision is THREE-WAY: bare
  -- '13009' is Baldwin County AND State House District 9 AND State Senate
  -- District 9, and all three rows are in production.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries
     WHERE geo_id = ${q(wide.geo_id)} AND mtfcc = ${q(wide.mtfcc)}
  ) THEN
    RAISE EXCEPTION '${tag}: boundary ${wide.geo_id}/${wide.mtfcc} is missing -- GA-1 must be applied first';
  END IF;
${wide.create ? '' : `
  -- 🔴 THIS DISTRICT IS NOT CREATED BY THIS MIGRATION. It already exists from the
  -- TIGER county load, so its ABSENCE is a hard stop rather than something to
  -- insert around: the county officers have nowhere to sit without it.
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = ${q(wide.geo_id)} AND mtfcc = ${q(wide.mtfcc)}
     AND district_type = ${q(s.district_type)} AND lower(state) = 'ga';
  IF v_n <> 1 THEN
    RAISE EXCEPTION '${tag}: expected exactly 1 existing ${wide.mtfcc} ${s.district_type} district ${wide.geo_id}, found % -- this migration does not create it', v_n;
  END IF;`}
END $$;`;
}

function structureVerifySql(side, tag) {
  const s = r[side];
  const g = s.government;
  const wide = wideOf(side);
  const dt = s.district_type;
  const nOffices = s.offices.length;
  const chamberChecks = s.chambers
    .map((c) => `(name = ${q(c.name)} AND official_count = ${c.official_count})`)
    .join('\n                                 OR ');
  const described = s.offices.filter((o) => o.description);
  const descCheck = described.length
    ? `
  -- 🔴 Ruling R2 must have SURVIVED generation. The Chair and Vice Chair are
  -- roles the Board elects from among its members, recorded as a note on the
  -- SEAT and not as offices of their own. A generator that dropped the
  -- description would pass every count above.
  SELECT count(*) INTO v_desc FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.description IS NOT NULL AND o.description <> '';
  IF v_desc <> ${described.length} THEN RAISE EXCEPTION '${tag}: expected ${described.length} office(s) carrying a role note, got %', v_desc; END IF;

  -- And no role leaked out as its own office.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov
     AND (o.title ILIKE '%chair%' OR o.title ILIKE '%vice%' OR o.title ILIKE '%pro-tem%' OR o.title ILIKE '%pro tem%');
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag}: % role(s) were created as offices -- ruling R2 says they are parentheticals', v_n; END IF;
`
    : `
  -- No role leaked out as its own office. Mayor Pro-Tem is a role the council
  -- elects from among its members (ruling R2), not an office.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov
     AND (o.title ILIKE '%pro-tem%' OR o.title ILIKE '%pro tem%' OR o.title ILIKE '%chair%');
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag}: % role(s) were created as offices -- ruling R2 says they are parentheticals', v_n; END IF;
`;

  return `-- --- 5. Post-verify gate ----------------------------------------------------
DO $$
DECLARE v_n int; v_gov uuid; v_d text; v_desc int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE mtfcc = ${q(s.district_mtfcc)} AND district_type = ${q(dt)} AND lower(state) = 'ga';
  IF v_n <> ${s.district_count} THEN RAISE EXCEPTION '${tag}: expected ${s.district_count} ${s.district_mtfcc} districts, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = ${q(wide.geo_id)} AND mtfcc = ${q(wide.mtfcc)} AND district_type = ${q(dt)};
  IF v_n <> 1 THEN RAISE EXCEPTION '${tag}: expected exactly 1 ${wide.label} district, got %', v_n; END IF;

  SELECT id INTO v_gov FROM essentials.governments
   WHERE geo_id = ${q(g.geo_id)} AND type = ${q(g.type)};
  IF v_gov IS NULL THEN RAISE EXCEPTION '${tag}: the government row is missing'; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers WHERE government_id = v_gov;
  IF v_n <> ${s.chambers.length} THEN RAISE EXCEPTION '${tag}: expected ${s.chambers.length} chambers, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers
   WHERE government_id = v_gov AND (${chamberChecks});
  IF v_n <> ${s.chambers.length} THEN RAISE EXCEPTION '${tag}: chamber names or official_counts are wrong'; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${nOffices} THEN RAISE EXCEPTION '${tag}: expected ${nOffices} offices, got %', v_n; END IF;

  -- Exactly one office per numbered district, counted PER DISTRICT. A single
  -- total can hide two offices on one district and none on another.
  FOR v_d IN SELECT ${q(s.district_geo_id_prefix)} || gs FROM generate_series(1,${s.district_count}) gs LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = v_d AND d.mtfcc = ${q(s.district_mtfcc)} AND d.district_type = ${q(dt)};
    IF v_n <> 1 THEN RAISE EXCEPTION '${tag}: district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- The at-large offices sit on the wide district.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = ${q(wide.geo_id)} AND d.mtfcc = ${q(wide.mtfcc)}
     AND d.district_type = ${q(dt)};
  IF v_n <> ${nOffices - s.district_count} THEN RAISE EXCEPTION '${tag}: expected ${nOffices - s.district_count} office(s) on ${wide.label}, got %', v_n; END IF;
${descCheck}
  -- 🔴 No office may sit on a district with no matching boundary: that is an
  -- office nobody can reach by address, and nothing else errors.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag}: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE '${tag} OK: ${s.district_count + (wide.create ? 1 : 0)} district(s) created, 1 government, ${s.chambers.length} chambers, ${nOffices} offices';
END $$;`;
}

function peopleSql(side, tag, seedTable) {
  const s = r[side];
  const dt = s.district_type;
  const offices = s.offices;
  const ids = offices.map((o) => o.person.external_id).sort((a, b) => a - b);
  const bandMin = Math.min(...ids);
  const bandMax = Math.max(...ids);
  const idList = ids.join(', ');

  const seedRows = offices
    .map((o) => {
      const p = o.person;
      return `  (${q(o.district_geo_id)}, ${q(o.district_mtfcc)}, ${q(dt)}, ${q(o.title)}, ${p.external_id}, ${q(p.full_name)}, ${q(p.first_name)}, ${q(p.last_name)}, ${q(p.middle_initial)}, ${q(p.name_suffix)}, ${arr(p.aliases)}, NULL::date, 'unknown', ${q(p.how_started)}, ${q(p.source)})`;
    })
    .join(',\n');

  return `-- --- Politician identity band ----------------------------------------------
-- 🔴 NOBODY ELSE MAY ALREADY OWN THE IDS THIS WAVE IS ABOUT TO INSERT. That is
-- the FL-2 failure exactly: a band collided with 166 existing rows and
-- ON CONFLICT DO NOTHING would have absorbed it in silence, leaving seats held
-- by whoever already owned those ids.
--
-- ⚠ SCOPED TO THIS WAVE'S OWN SUB-RANGE, per the FL-4 correction. A guard over
-- the whole shared band makes a neighbouring wave's legitimate rows look foreign
-- and breaks this migration's OWN re-run. Excluding our own ids keeps it
-- idempotent.
DO $$
DECLARE v_n int; v_foreign text;
BEGIN
  SELECT count(*), string_agg(external_id::text, ', ' ORDER BY external_id)
    INTO v_n, v_foreign
    FROM essentials.politicians
   WHERE external_id BETWEEN ${bandMin} AND ${bandMax}
     AND external_id NOT IN (${idList});
  IF v_n <> 0 THEN
    RAISE EXCEPTION '${tag}: % row(s) inside this wave''s id range ${bandMin}..${bandMax} are owned by something else (%). Pick another sub-range rather than colliding.', v_n, v_foreign;
  END IF;
END $$;

-- 🔴 IDENTITY IS KEYED ON external_id, NEVER ON NAME. All ${offices.length} names in this half
-- were checked against production 2026-09-01 with a POSITIVE CONTROL (Floyd
-- Griffin, seated by GA-2, returns exactly 1) and none matched, so all are fresh
-- inserts and nothing is reused. A name-based guard is what seated a Wisconsin
-- village trustee on the Nashville council and a Colorado senator in Georgia.

CREATE TEMP TABLE ${seedTable} (
  geo_id          text,
  mtfcc           text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_initial  text,
  name_suffix     text,
  aliases         text[],
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO ${seedTable} VALUES
${seedRows};

-- --- Payload guard ----------------------------------------------------------
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM ${seedTable};
  IF v_n <> ${offices.length} THEN RAISE EXCEPTION '${tag} payload: expected ${offices.length} rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM ${seedTable} GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${tag} payload: % duplicate external_id(s)', v_dup; END IF;

  SELECT count(*) INTO v_n FROM ${seedTable} WHERE ext_id NOT BETWEEN ${r.id_band.min} AND ${r.id_band.max};
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag} payload: % out-of-band external_id(s)', v_n; END IF;

  -- Every (geo_id, mtfcc, district_type, title) is a single seat in this wave.
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, mtfcc, district_type, office_title FROM ${seedTable}
    GROUP BY geo_id, mtfcc, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${tag} payload: % duplicate seat key(s)', v_dup; END IF;

  -- 🔴 RULING R4: every row in this wave has NO term_start and MUST declare
  -- 'unknown'. Georgia publishes no service-start for either body.
  SELECT count(*) INTO v_n FROM ${seedTable} WHERE term_start IS NULL AND start_precision <> 'unknown';
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag} payload: % row(s) have no term_start but claim a precision', v_n; END IF;
  SELECT count(*) INTO v_n FROM ${seedTable} WHERE term_start IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag} payload: % row(s) carry a term_start, which ruling R4 says is not sourced for this wave', v_n; END IF;

  -- ⚠ alternate_names is NOT NULL DEFAULT '{}'. Emit an empty array, never NULL.
  SELECT count(*) INTO v_n FROM ${seedTable} WHERE aliases IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag} payload: % row(s) carry a NULL aliases array', v_n; END IF;

  -- And every seat named must resolve to exactly one office in prod.
  SELECT count(*) INTO v_n FROM ${seedTable} s
   WHERE (SELECT count(*) FROM essentials.offices o
            JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
             AND d.district_type = s.district_type AND lower(d.state) = 'ga'
             AND o.title = s.office_title) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag} payload: % seat(s) do not resolve to exactly one office -- run the structure half first', v_n; END IF;
END $$;

-- --- Politicians ------------------------------------------------------------
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name,
       nullif(s.middle_initial, ''), nullif(s.name_suffix, ''),
       s.aliases, true, true, s.source
FROM ${seedTable} s
ON CONFLICT (external_id) DO NOTHING;

-- --- Occupancy --------------------------------------------------------------
-- 🔴 EVERY ROW IN THIS WAVE TAKES THE DIRECT-INSERT PATH, because
-- essentials.seat_officeholder() REFUSES a NULL term_start ("pass Jan 1 with
-- p_start_precision => 'year' rather than NULL") and ruling R4 has no date to
-- pass. Inventing Jan 1 of a guessed year is a false statement about history
-- that no end_precision exists to soften.
--
-- The schema allows the honest record and prod is full of it: the ADR 0002
-- phase-2 backfill wrote 81,676 'unknown'-precision rows with term_start NULL.
-- Only the HELPER refuses it.
--
-- Direct insert is safe ONLY into an office with zero existing term rows: the
-- helper's two-step exists to close a predecessor before an open-ended range
-- overlaps it, and with no predecessor there is nothing to close and the
-- exclusion constraint cannot fire. The guard REFUSES rather than guesses if
-- that stops being true.
DO $$
DECLARE r record; v_blank int := 0; v_prior int;
BEGIN
  FOR r IN
    SELECT s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
      FROM ${seedTable} s
      JOIN essentials.districts d
        ON d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
       AND d.district_type = s.district_type AND lower(d.state) = 'ga'
      JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
      JOIN essentials.politicians p ON p.external_id = s.ext_id
     WHERE NOT EXISTS (
       SELECT 1 FROM essentials.office_terms t
        WHERE t.office_id = o.id AND t.politician_id = p.id
     )
  LOOP
    IF r.start_precision <> 'unknown' THEN
      RAISE EXCEPTION '${tag}: office % has no term_start but claims precision % -- refusing', r.office_id, r.start_precision;
    END IF;
    SELECT count(*) INTO v_prior FROM essentials.office_terms t WHERE t.office_id = r.office_id;
    IF v_prior <> 0 THEN
      RAISE EXCEPTION '${tag}: office % already carries % term row(s), so an undated open term cannot be inserted directly -- close the predecessor and give this person a real date', r.office_id, v_prior;
    END IF;
    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
    VALUES (r.office_id, r.politician_id, NULL, NULL, 'unknown', r.how_started, r.source);
    v_blank := v_blank + 1;
  END LOOP;
  RAISE NOTICE '${tag}: seated % official(s), every one with an honest unknown start', v_blank;
END $$;

-- --- Post-verify gate ------------------------------------------------------
DO $$
DECLARE v_gov uuid; v_pol int; v_seated int; v_n int; v_d text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments
   WHERE geo_id = ${q(s.government.geo_id)} AND type = ${q(s.government.type)};
  IF v_gov IS NULL THEN RAISE EXCEPTION '${tag}: the government row is missing'; END IF;

  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id BETWEEN ${bandMin} AND ${bandMax};
  IF v_pol <> ${offices.length} THEN RAISE EXCEPTION '${tag}: expected ${offices.length} politicians in ${bandMin}..${bandMax}, got %', v_pol; END IF;

  -- 🔴 office_current_holder LEFT JOINs from offices, so a vacancy is a NULL
  -- politician_id, NEVER an absent row. count(*) would pass VACUOUSLY.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov;
  IF v_seated <> ${offices.length} THEN RAISE EXCEPTION '${tag}: expected ${offices.length} seated officials, got %', v_seated; END IF;

  -- Exactly one holder per numbered district.
  FOR v_d IN SELECT ${q(s.district_geo_id_prefix)} || gs FROM generate_series(1,${s.district_count}) gs LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = ${q(s.district_mtfcc)} AND d.district_type = ${q(dt)};
    IF v_n <> 1 THEN RAISE EXCEPTION '${tag}: district % has % holder(s), expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- Every term is open-ended at 'unknown' (ruling R4), and NO term_end was
  -- written: a future term_end makes a seat silently self-vacate.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id BETWEEN ${bandMin} AND ${bandMax}
     AND (t.start_precision <> 'unknown' OR t.term_start IS NOT NULL OR t.term_end IS NOT NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag}: % term row(s) are not an open-ended unknown-precision term', v_n; END IF;

  -- No office in this government may be left with no term row at all: that is
  -- the invisible-office failure, and nothing else errors.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '${tag}: % office(s) carry no office_terms row and are invisible', v_n; END IF;

  RAISE NOTICE '${tag} OK: ${offices.length} politicians, ${offices.length} seated across ${offices.length} offices, 0 vacancies';
END $$;`;
}

// ── file bodies ──────────────────────────────────────────────────────────────
const CITY_HEADER = `-- CC_wip_milledgeville_structure.sql
--
-- Knight Foundation cities program, wave GA-3, CITY STRUCTURE half.
--   * 1 government, 2 chambers
--   * 7 districts -- 1 citywide (TIGER place 1351492/G4110) + 6 council (X0042)
--   * 7 offices   -- 1 Mayor + 6 single-member council members
--
-- Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md
-- Roster: backend/data/seed-milledgeville-2026/ROSTERS.md
-- Generated by scripts/gen-ga3-milledgeville-migrations.mjs -- edit the roster
-- JSON and regenerate, do not hand-edit this file.
--
-- 🔴 TAKE THE MIGRATION NUMBER LAST. Re-count against EVERY remote ref, not
--    against PROGRAM.md. Verified 2026-09-01: CC_0026 was the highest slot
--    across all 81 remote refs.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING R1: THE MAYOR IS voting_powers 'full', IN A CHAMBER OF ONE.
--
-- Follows Bradenton's ruling R2 (CC_0008): voting_powers describes the powers of
-- the OFFICE, not a council procedure. Milledgeville's Mayor is elected citywide
-- on a separate certified ballot line ("Mayor - Milledgeville", Georgia SOS) for
-- a four-year term, and is not a seat that exists only to preside -- which is
-- what made Nashville's Vice Mayor non_voting.
--
-- ⚠ THE MAYOR'S VOTE ON THE COUNCIL IS NOT ESTABLISHED. The only published
--   charter is codified through JANUARY 2014 and is titled "ARTICLE II. -- MAYOR
--   AND ALDERMEN"; it describes no six-district council at all. Milledgeville is
--   council-MANAGER, so unlike Bradenton the Mayor is not the chief executive.
--   'full' requires no representation_note, so this ruling writes NO unsourced
--   prose into a voter-facing field. Re-check when a current charter is found.
--
-- 🔴 RULING R2: MAYOR PRO-TEM IS A ROLE, NOT AN OFFICE. The council elects it
--    from among its own members (currently Denese Shinholster, District 3). The
--    post-verify gate refuses any office whose title contains "pro-tem".
--
-- ⚠ THE COUNCIL IS NOT STAGGERED. All six districts and the mayoralty were on
--   the SAME November 2025 ballot, confirmed against the Georgia Secretary of
--   State's certified municipal results.`;

const CITY_PEOPLE_HEADER = `-- CC_wip_milledgeville_people.sql
--
-- Knight Foundation cities program, wave GA-3, CITY OCCUPANCY half.
--   * 7 politicians, 7 open-ended terms, 0 vacancies
--
-- Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md
-- Roster: backend/data/seed-milledgeville-2026/ROSTERS.md
-- Generated by scripts/gen-ga3-milledgeville-migrations.mjs.
--
-- ⚠ THIS HALF CANNOT BE DRY-RUN ALONE -- its offices do not exist until the
--   structure half runs. Run both as ONE transaction ending in ROLLBACK and
--   assert the stream holds exactly one BEGIN, one ROLLBACK and ZERO COMMIT.
--
-- ---------------------------------------------------------------------------
-- THE ROSTER, CERTIFIED BY THE GEORGIA SECRETARY OF STATE
--
-- November 4 2025 municipal general, certified as of 2025-11-21, 6 of 6 units
-- reporting. 🟢 The SOS publishes certified MUNICIPAL results -- nothing in the
-- Florida slice used that route, and it settled every seat here.
--
--   Mayor      Mary Parham-Copelan    1,235 / 2,330 (53.0%) def. Walter Reynolds
--   District 1 Collinda J. Lee          377, unopposed
--   District 2 Arlene Simmons           108 / 216 -- see the note below
--   District 3 Denese Ray Shinholster   248, unopposed
--   District 4 Morgan Pendergast         79, unopposed
--   District 5 Shonya A. Mapp           498, unopposed
--   District 6 Jeffery C. Wells         456 / 730 (62.5%) def. Kayla Brownlow
--
-- 🔴 THREE SEATS CHANGED HANDS, AND ONE PERSON'S MOVE EXPLAINS ONE OF THEM.
--    Walter Reynolds vacated District 4 to run for Mayor, and lost. Walden (D2)
--    and Chambers (D6) do not appear on the 2025 ballot at all. Baldwin County's
--    ArcGIS layer still names all three predecessors, and the Georgia Municipal
--    Association directory lists NINE members for a six-seat council because it
--    accumulates and has no dateVacated field.
--
-- ⚠ DISTRICT 2's ARITHMETIC DOES NOT CLOSE, AND IT IS RECORDED, NOT EXPLAINED.
--   108 of 216 is exactly 50.0%, not a majority. The Union-Recorder reported
--   five write-ins pending a panel review; the certified sheet carries no
--   write-in option and sums to 216. Baldwin held NO runoff -- it is absent from
--   the December 2 2025 runoff results, which return HTTP 204 for this county.
--   Plurality election is the likely explanation and is NOT confirmed, because
--   the only published charter is the 2014 one. Simmons holds the seat by the
--   certified count, by the city's own roster, and by the absence of any
--   successor contest.
--
-- 🔴 RULING R4: ALL SEVEN TERMS ARE OPEN-ENDED AT 'unknown'. The certified
--    election date above is NOT a term_start: term_start is the start of
--    CONTINUOUS occupancy, which re-election does not end, and four of these
--    seven are incumbents whose occupancy predates 2025. Milledgeville publishes
--    no service-start and no swearing-in date. No date is invented.`;

const COUNTY_HEADER = `-- CC_wip_baldwin_county.sql
--
-- Knight Foundation cities program, wave GA-3, BALDWIN COUNTY -- offices AND
-- people in ONE migration, per spec §3.
--   * 1 government, 2 chambers
--   * 6 districts -- 1 countywide (TIGER county 13009/G4020) + 5 commission (X0043)
--   * 11 offices, 11 politicians, 11 open-ended terms, 0 vacancies
--
-- Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md
-- Roster: backend/data/seed-milledgeville-2026/ROSTERS.md
-- Generated by scripts/gen-ga3-milledgeville-migrations.mjs.
--
-- 🔴 OFFICES AND PEOPLE SHIP TOGETHER, DELIBERATELY. An office with no
--    office_terms row is INVISIBLE -- no holder, so the official appears nowhere
--    in Essentials, and NOTHING ERRORS. Splitting this would push
--    offices_missing_terms above its 655-unflagged baseline in between.
--
-- ---------------------------------------------------------------------------
-- 🔴 FIVE SINGLE-MEMBER SEATS, NO AT-LARGE MEMBER -- A FOURTH CONVENTION IN
--    FIVE COUNTIES.
--
--   Manatee     5 districts + 2 at-large
--   Leon        5 districts + 2 at-large
--   Palm Beach  7 districts, no at-large
--   Miami-Dade  13 districts + a separately elected countywide Mayor
--   Baldwin     5 districts, no at-large, CHAIR ELECTED BY THE BOARD
--
-- 🔴 RULING R2: THE CHAIR AND VICE CHAIR ARE PARENTHETICALS, NOT OFFICES. The
--    Board elects both from among its five district commissioners. They are
--    recorded as a note on the SEAT (District 2 Chairman, District 5 Vice
--    Chairman) and the post-verify gate refuses any office titled with them.
--    Follows the Lawrence County ruling.
--
-- 🔴 RULING R3, DECIDED 2026-09-01 (Cantrell): ELEVEN OFFICES. Baldwin elects
--    thirteen countywide offices besides the commission. Seated are the four
--    county officers named in Ga. Const. Art. IX, Sec. I, Par. III -- Sheriff,
--    Clerk of Superior Court, Probate Judge, Tax Commissioner -- plus Coroner
--    and Surveyor, statutory county officers Baldwin genuinely elected in 2024.
--
--    EXCLUDED, each for a stated reason:
--      Solicitor General            a prosecutor -- the FL-5 rule against Palm
--                                   Beach's State Attorney
--      Chief Magistrate             judicial branch, Ga. Const. Art. VI, as
--                                   Florida excluded its county judges
--      Ocmulgee Circuit DA and its  MULTI-COUNTY circuit -- the FL-5 ruling
--        five Superior Court judges exactly
--      School board                 spec §11
--      Piedmont Soil and Water      spec §11
--      GMC Board of Trustees        a STATE junior college's board, on the same
--                                   2025 municipal ballot but not a city office
--
--    ⚠ Georgia's PROBATE JUDGE is a county officer, not a judicial-branch
--      officer. That is why it is in and the magistrate is out. The line is the
--      constitution's, not ours.
--
-- ---------------------------------------------------------------------------
-- THE ROSTER, CERTIFIED BY THE GEORGIA SECRETARY OF STATE
--
-- November 5 2024 general, certified as of 2025-01-02. ALL TEN on the ballot ran
-- UNOPPOSED at 100%.
--
--   Commission D1  Emily C. Davis            2,650
--   Commission D2  Kendrick B. Butts         2,128   (Chairman)
--   Commission D3  Sammy Hall                2,239
--   Commission D4  Andrew Strickland         4,084
--   Commission D5  Scott Little              4,312   (Vice Chairman)
--   Sheriff        W.C. "Bill" Massee, Jr.  16,400
--   Clerk of Sup.  Wanda T. Paul            14,815
--   Tax Comm.      Cathy Freeman Settle     16,026
--   Coroner        John Gonzalez            15,444
--   Surveyor       James E. Smith, Jr.      14,121
--
-- ⚠ THE PROBATE JUDGE IS ON NO 2024 BALLOT. Georgia omits unopposed nonpartisan
--   candidates, so Todd A. Blackwell rests on the county's own staff directory,
--   the county ArcGIS layer and Ballotpedia's candidate list -- three publishers
--   agreeing on the person, none of them a certified count.
--
-- 🔴 THE COUNTY'S OWN LAYER MISSPELLS THE SHERIFF as "Bill Masse", one 'e'. His
--    office and the county directory both give MASSEE. Two suffixed names and
--    one embedded nickname in this half, so splitName() is NOT used: first and
--    last come from the source, as GA-2 did.
--
-- 🔴 RULING R4: ALL ELEVEN TERMS ARE OPEN-ENDED AT 'unknown'. The certified
--    election date is not a term_start. Baldwin publishes no service-start.`;

function build() {
  assertRoster();

  const cityStructure = [
    CITY_HEADER,
    '',
    'BEGIN;',
    '',
    preflightSql('city', 'milledgeville structure'),
    '',
    '-- --- 1. Districts -----------------------------------------------------------',
    '-- ⚠ Synthetic districts carry no ocd_id and no government_id, matching X0036',
    "-- and X0041. district state is LOWER case here and UPPER on governments and",
    '-- offices; both conventions are live in prod.',
    '',
    districtsSql('city'),
    '',
    '-- --- 2. Government ----------------------------------------------------------',
    '',
    governmentSql('city'),
    '',
    '-- --- 3. Chambers ------------------------------------------------------------',
    '-- ⚠ chambers.slug is GENERATED from name_formal and cannot be inserted.',
    '-- Getting name_formal wrong silently yields a different slug.',
    '',
    chambersSql('city'),
    '',
    '-- --- 4. Offices -------------------------------------------------------------',
    '-- Every title is distinct, so a NOT EXISTS-on-title guard cannot collapse rows.',
    '',
    officesSql('city'),
    '',
    structureVerifySql('city', 'milledgeville structure'),
    '',
    'COMMIT;',
    '',
  ].join('\n');

  const cityPeople = [
    CITY_PEOPLE_HEADER,
    '',
    'BEGIN;',
    '',
    peopleSql('city', 'milledgeville people', 'mv_seed'),
    '',
    'COMMIT;',
    '',
  ].join('\n');

  const county = [
    COUNTY_HEADER,
    '',
    'BEGIN;',
    '',
    preflightSql('county', 'baldwin county'),
    '',
    '-- --- 1. Districts -----------------------------------------------------------',
    '',
    districtsSql('county'),
    '',
    '-- --- 2. Government ----------------------------------------------------------',
    '',
    governmentSql('county'),
    '',
    '-- --- 3. Chambers ------------------------------------------------------------',
    '',
    chambersSql('county'),
    '',
    '-- --- 4. Offices -------------------------------------------------------------',
    '',
    officesSql('county'),
    '',
    structureVerifySql('county', 'baldwin county structure'),
    '',
    '-- --- 6. People and occupancy, in the SAME migration (spec §3) ---------------',
    '',
    peopleSql('county', 'baldwin county people', 'bc_seed'),
    '',
    'COMMIT;',
    '',
  ].join('\n');

  const files = [
    ['CC_wip_milledgeville_structure.sql', cityStructure],
    ['CC_wip_milledgeville_people.sql', cityPeople],
    ['CC_wip_baldwin_county.sql', county],
  ];
  for (const [name, body] of files) {
    writeFileSync(join(OUT_DIR, name), body, 'utf8');
    console.log(`wrote migrations/${name}  (${body.split('\n').length} lines)`);
  }
  console.log('\n🔴 Take the migration numbers LAST: re-count against every remote ref, then rename,');
  console.log('   apply and commit in one go. CC_0027 / CC_0028 / CC_0029 as of 2026-09-01.');
}

build();
