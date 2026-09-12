#!/usr/bin/env node
/**
 * gen-in-legislature-migrations.mjs
 *
 * Emits the two IN-2 migrations from data/in-legislature-roster.json plus two measured
 * production dumps. Reads nothing from the database and writes nothing to it.
 *
 *   migrations/CC_0088_in_legislature_structure.sql
 *   migrations/CC_0089_in_legislature_incumbents.sql
 *
 * Slots CC_0088 and CC_0089 were RESERVED FROM THE ALLOCATOR, not counted:
 *   npm run steward --prefix backend -- slot CC --purpose "..."
 *
 * INPUTS
 *   data/in-legislature-roster.json              150 seats, both sources agreeing
 *   data/seed-in-legislature-2026/_existing18.psv        the 18 offices already in production
 *   data/seed-in-legislature-2026/_discovery_matches.psv the 92 indiana_discovery people to reuse
 *
 * 🔴 IN-2 IS A REPAIR AND A SEED IN ONE WAVE. Indiana's 18 existing seats hang on 18
 * pseudo-chambers, one per district, official_count 0, spread over 18 SEPARATE
 * `State of Indiana` government rows. Every other state has exactly one government row and
 * exactly two legislative chambers.
 *
 * 🔴 THE 132 NEW DISTRICTS ARE WRITTEN IN THE CURRENT LOADER'S SHAPE, NOT THE LEGACY ONE.
 * scripts/load-state-tiger-boundaries.ts writes state as a LOWERCASE abbreviation (line 719,
 * `FIPS_TO_STATE[fips]`) and labels sldl/sldu as `State House District N` / `State Senate
 * District N` -- which is why GA, FL, CO and NC are all lowercase. Indiana's legacy 18 are
 * uppercase 'IN' from an older loader. Matching the CURRENT loader keeps a future
 * loader run on Indiana a no-op instead of a duplicate-maker.
 *
 * 🔴 THE LEGACY 18 ARE NOT CASE-NORMALISED, DELIBERATELY. Live read paths compare
 * `d.state = $1` case-sensitively against an UPPER-CASED argument
 * (essentialsBrowseService.ts:100,996 -> districtQueries.ts:218). Those queries filter to
 * statewide district_types and so cannot see a STATE_LOWER row -- but proving that for every
 * caller is a bigger claim than a seeding wave needs to make. The split is recorded instead.
 *
 * 🔴 NO term_end IS EVER WRITTEN, and no term_start is invented. Indiana publishes no
 * service-start of any kind, so every term is open-ended at start_precision 'unknown' --
 * the GA-2 pattern, and what the 18 existing rows already carry.
 *
 * 🔴 PARTY IS NOT WRITTEN. It lives on races.primary_party, never on a person or an office.
 *
 *   node scripts/gen-in-legislature-migrations.mjs
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SEED = path.join(HERE, '..', 'data', 'seed-in-legislature-2026');
const ROSTER = path.join(HERE, '..', 'data', 'in-legislature-roster.json');
const MIGRATIONS = path.join(HERE, '..', 'migrations');

/** The one 'State of Indiana' government row carrying correctly modelled statewide chambers
 *  (Comptroller, Secretary of State, Treasurer, Utility Regulatory Commission -- real
 *  official_counts). The other 21 rows are import duplicates and are left alone. */
const GOVERNMENT_ID = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c';

const CHAMBERS = {
  STATE_LOWER: {
    name: 'Indiana House of Representatives',
    seats: 100,
    title: 'Representative',
    mtfcc: 'G5220',
    ocdKey: 'sldl',
    label: (n) => `State House District ${n}`,
    idBase: -1332000,
  },
  STATE_UPPER: {
    name: 'Indiana State Senate',
    seats: 50,
    title: 'Senator',
    mtfcc: 'G5210',
    ocdKey: 'sldu',
    label: (n) => `State Senate District ${n}`,
    idBase: -1332100,
  },
};

const SOURCE_A = 'Indiana General Assembly member list, https://iga.in.gov/api/getLegislators?session_lpid=session_2026';
const SOURCE_B = 'Open States, https://data.openstates.org/people/current/in.csv';
const TERM_SOURCE = `${SOURCE_A}, reconciled against ${SOURCE_B}, read 2026-09-10 (CC_0089, IN-2)`;

const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

function readPsv(file) {
  return fs.readFileSync(file, 'utf8').trim().split('\n').filter(Boolean).map((l) => l.split('|'));
}

function main() {
  const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8')).roster;
  if (roster.length !== 150) throw new Error(`roster has ${roster.length} seats, expected 150`);

  // -- the 18 offices already in production ---------------------------------
  const existing = new Map();
  for (const [dtype, dist, officeId, chamberId, politicianId, title] of readPsv(path.join(SEED, '_existing18.psv'))) {
    existing.set(`${dtype}-${Number(dist)}`, { officeId, chamberId, politicianId, title });
  }
  if (existing.size !== 18) throw new Error(`_existing18.psv has ${existing.size} rows, expected 18`);

  // -- the indiana_discovery people to reuse ---------------------------------
  const discovery = new Map();
  for (const [dtype, dist, id, fullName] of readPsv(path.join(SEED, '_discovery_matches.psv'))) {
    discovery.set(`${dtype}-${Number(dist)}`, { id, fullName });
  }

  // -- resolve every seat ----------------------------------------------------
  const seats = roster.map((r) => {
    const k = `${r.chamber}-${r.district}`;
    const ex = existing.get(k);
    if (ex) return { ...r, kind: 'existing', ...ex };
    const dis = discovery.get(k);
    if (dis) return { ...r, kind: 'reuse', politicianId: dis.id, discoveryName: dis.fullName };
    return { ...r, kind: 'new', externalId: CHAMBERS[r.chamber].idBase - r.district };
  });

  const byKind = (k) => seats.filter((s) => s.kind === k);
  const counts = { existing: byKind('existing').length, reuse: byKind('reuse').length, new: byKind('new').length };
  console.log(`resolution: ${counts.existing} existing offices repaired, ` +
    `${counts.reuse} people reused from indiana_discovery, ${counts.new} people created`);
  if (counts.existing + counts.reuse + counts.new !== 150) throw new Error('resolution does not total 150');

  const newOffices = seats.filter((s) => s.kind !== 'existing');
  if (newOffices.length !== 132) throw new Error(`${newOffices.length} new offices, expected 132`);

  // Every external_id assigned must be unique and inside the reserved band.
  const ids = byKind('new').map((s) => s.externalId);
  if (new Set(ids).size !== ids.length) throw new Error('duplicate external_id assigned');
  for (const id of ids) if (id > -1332001 || id < -1332150) throw new Error(`external_id ${id} outside the reserved band`);

  // Seats where an indiana_discovery row matched but a 'ballotready' row already holds the
  // office: two person rows for one human. Named in the migration so 92 vs 84 is explained.
  const seatsWithBoth = seats
    .filter((s) => s.kind === 'existing' && discovery.has(`${s.chamber}-${s.district}`))
    .map((s) => {
      const c = CHAMBERS[s.chamber];
      const tag = s.chamber === 'STATE_LOWER' ? 'HD' : 'SD';
      // The seat is held by the ballotready row, whose full_name can differ in FORM from the
      // roster's -- HD-100 is 'Robert B Johnson' in production and 'Blake Johnson' at the IGA,
      // confirmed the same person via Ballotpedia's Robert_Blake_Johnson. Name the roster form
      // and the discovery form, and do not assert the production form here.
      return `${tag}-${String(s.district).padEnd(3)} roster ${JSON.stringify(s.full_name)}; ` +
             `already seated by a ballotready row; duplicate indiana_discovery row ` +
             `${JSON.stringify(discovery.get(`${s.chamber}-${s.district}`).fullName)}`;
    });
  console.log(`seats holding BOTH a ballotready and an indiana_discovery row: ${seatsWithBoth.length}`);

  writeStructure(seats, newOffices, counts);
  writeIncumbents(seats, newOffices, counts, seatsWithBoth);
}

// ─── CC_0088 structure ───────────────────────────────────────────────────────
function writeStructure(seats, newOffices, counts) {
  const districtValues = newOffices.map((s) => {
    const c = CHAMBERS[s.chamber];
    return `  (${q(s.geo_id)}, ${q(`ocd-division/country:us/state:in/${c.ocdKey}:${s.district}`)}, ` +
           `${q(c.label(s.district))}, ${q(s.chamber)}, ${q(c.mtfcc)})`;
  }).join(',\n');

  const sql = `-- CC_0088_in_legislature_structure.sql
-- Knight Foundation program, wave IN-2 (structure half). Slot RESERVED from the allocator.
--
-- Indiana is the program's first PARTIALLY seated legislature, and IN-2 is therefore a REPAIR
-- and a seed in one wave. This migration:
--
--   1. creates the two real chambers -- Indiana has NEITHER today;
--   2. creates the 132 missing districts (88 House + 44 Senate);
--   3. REPOINTS the 18 existing offices onto the real chambers and normalises their titles;
--   4. creates the 132 missing offices;
--   5. DELETES the 18 emptied pseudo-chambers.
--
-- Creates NO people and NO terms -- CC_0089 does that, and the two are applied back to back.
--
-- 🔴 THE DEFECT BEING REPAIRED. Indiana's 18 seated legislators hang on 18 chambers named for a
-- single district each, every one with official_count 0, spread across 18 SEPARATE
-- 'State of Indiana' government rows. Measured 2026-09-10: count(DISTINCT chamber_id) over
-- Indiana's STATE_LOWER offices is 12 across 12 offices, and over STATE_UPPER is 6 across 6.
-- Swept across every state, INDIANA IS THE ONLY ONE where a legislative chamber count exceeds 2.
--
-- 🟢 NOTHING ELSE REFERENCES THE 18. The three tables carrying a chambers FK --
-- meetings.meetings, essentials.discovered_sources, essentials.source_outlets -- hold ZERO rows
-- against any of the 18 chamber ids. Their only referents are their own 18 offices, which step 3
-- moves first. The DELETE in step 5 is still guarded on emptiness rather than trusting that.
--
-- 🔴 THE HOST GOVERNMENT IS CHOSEN, NOT ASSUMED. There are TWENTY-TWO government rows named
-- 'State of Indiana', all type STATE, state IN, geo_id NULL -- indistinguishable by attribute.
-- Every other state in production has exactly ONE. ${GOVERNMENT_ID}
-- is the only one carrying correctly modelled statewide chambers (Comptroller, Secretary of
-- State, Treasurer, Utility Regulatory Commission, with real official_counts), so it hosts the
-- legislature. ⚠ The other 21 rows are an import artefact and are DELIBERATELY LEFT ALONE:
-- consolidating governments is a larger repair than this wave, and half-doing it is worse than
-- scheduling it. After this migration, 17 of them hold no chamber at all.
--
-- 🔴 THE 132 NEW DISTRICTS MATCH THE CURRENT LOADER, NOT THE LEGACY 18. state is the LOWERCASE
-- abbreviation and the label is 'State House/Senate District N', which is what
-- scripts/load-state-tiger-boundaries.ts writes (line 719) and why GA, FL, CO and NC are all
-- lowercase. Indiana's legacy 18 are uppercase 'IN' from an older loader. Matching the CURRENT
-- loader keeps a future loader run on Indiana a NO-OP rather than a duplicate-maker.
-- ⚠ The legacy 18 are NOT case-normalised here. Live read paths compare d.state = $1
-- case-sensitively against an upper-cased argument; those queries filter to statewide
-- district_types and cannot see a STATE_LOWER row, but proving that for every caller is a bigger
-- claim than this wave needs. The split is recorded in .planning/knight-foundation/in.md.
--
-- 🔴 GEOMETRY IS NOT TOUCHED. All 150 polygons were already loaded (census_tiger_2024,
-- 2026-02-11/12) and were VINTAGE-PROVED 150/150 against the General Assembly's own
-- house_2021.kmz / senate_2021.kmz by scripts/verify-in-legislative-vintage.mjs, every district
-- tested at its own interior point, with SD-17/SD-18 swapped as a planted control.
--
-- 🔴 EVERY JOIN PAIRS geo_id WITH district_type. Indiana's sldl range runs 18001..18100 and its
-- sldu range 18001..18050, so '18046' is House District 46 AND Senate District 46. A LEFT JOIN
-- on geo_id alone reported 25 House and 18 Senate district rows when the true counts are 12 and 6.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded, every UPDATE is guarded on the current value,
-- and the DELETE is guarded on emptiness. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers Indiana does not have ───────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT ${q(GOVERNMENT_ID)}, ${q(CHAMBERS.STATE_LOWER.name)}, ${q(CHAMBERS.STATE_LOWER.name)}, ${CHAMBERS.STATE_LOWER.seats}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = ${q(GOVERNMENT_ID)} AND name = ${q(CHAMBERS.STATE_LOWER.name)});

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT ${q(GOVERNMENT_ID)}, ${q(CHAMBERS.STATE_UPPER.name)}, ${q(CHAMBERS.STATE_UPPER.name)}, ${CHAMBERS.STATE_UPPER.seats}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = ${q(GOVERNMENT_ID)} AND name = ${q(CHAMBERS.STATE_UPPER.name)});

-- ─── 2. The 132 missing districts ────────────────────────────────────────────

CREATE TEMP TABLE in_new_districts(geo_id text, ocd_id text, label text, district_type text, mtfcc text)
  ON COMMIT DROP;
INSERT INTO in_new_districts(geo_id, ocd_id, label, district_type, mtfcc) VALUES
${districtValues};

INSERT INTO essentials.districts (geo_id, ocd_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.ocd_id, n.label, n.district_type, 'in', n.mtfcc
FROM in_new_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.district_type = n.district_type);

-- ─── 3. Repoint and retitle the 18 existing offices ──────────────────────────
-- Guarded on the current value, so a re-run is a no-op.

UPDATE essentials.offices o
SET chamber_id = c.id,
    title      = ch.title
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', ${q(CHAMBERS.STATE_LOWER.name)}, ${q(CHAMBERS.STATE_LOWER.title)}),
  ('STATE_UPPER', ${q(CHAMBERS.STATE_UPPER.name)}, ${q(CHAMBERS.STATE_UPPER.title)})
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type
JOIN essentials.chambers c
  ON c.government_id = ${q(GOVERNMENT_ID)} AND c.name = ch.chamber_name
WHERE d.id = o.district_id
  AND lower(d.state) = 'in'
  AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND (o.chamber_id IS DISTINCT FROM c.id OR o.title IS DISTINCT FROM ch.title);

-- ─── 4. The 132 missing offices ──────────────────────────────────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'IN', 1, false, 'full'
FROM in_new_districts n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.district_type = n.district_type AND lower(d.state) = 'in'
JOIN (VALUES
  ('STATE_LOWER', ${q(CHAMBERS.STATE_LOWER.name)}, ${q(CHAMBERS.STATE_LOWER.title)}),
  ('STATE_UPPER', ${q(CHAMBERS.STATE_UPPER.name)}, ${q(CHAMBERS.STATE_UPPER.title)})
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type
JOIN essentials.chambers c
  ON c.government_id = ${q(GOVERNMENT_ID)} AND c.name = ch.chamber_name
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── 5. Delete the 18 emptied pseudo-chambers ────────────────────────────────
-- Guarded on holding no office. Step 3 moved all 18; if any still holds one, this deletes
-- nothing and the post-verify gate below fails loudly rather than silently orphaning an office.

DELETE FROM essentials.chambers c
WHERE (c.name LIKE 'Indiana House of Representatives - District%'
    OR c.name LIKE 'Indiana State Senate - District%')
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_house_chamber   int;
  v_senate_chamber  int;
  v_lower_districts int;
  v_upper_districts int;
  v_lower_offices   int;
  v_upper_offices   int;
  v_pseudo          int;
  v_distinct_ch     int;
  v_mistitled       int;
BEGIN
  SELECT count(*) INTO v_house_chamber FROM essentials.chambers
   WHERE government_id = ${q(GOVERNMENT_ID)} AND name = ${q(CHAMBERS.STATE_LOWER.name)} AND official_count = 100;
  SELECT count(*) INTO v_senate_chamber FROM essentials.chambers
   WHERE government_id = ${q(GOVERNMENT_ID)} AND name = ${q(CHAMBERS.STATE_UPPER.name)} AND official_count = 50;
  IF v_house_chamber <> 1 OR v_senate_chamber <> 1 THEN
    RAISE EXCEPTION 'IN-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_chamber, v_senate_chamber;
  END IF;

  SELECT count(*) FILTER (WHERE district_type = 'STATE_LOWER'),
         count(*) FILTER (WHERE district_type = 'STATE_UPPER')
    INTO v_lower_districts, v_upper_districts
  FROM essentials.districts WHERE lower(state) = 'in' AND district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_lower_districts <> 100 OR v_upper_districts <> 50 THEN
    RAISE EXCEPTION 'IN-2 structure: expected 100 House / 50 Senate districts, got % / %',
      v_lower_districts, v_upper_districts;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type = 'STATE_UPPER')
    INTO v_lower_offices, v_upper_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_lower_offices <> 100 OR v_upper_offices <> 50 THEN
    RAISE EXCEPTION 'IN-2 structure: expected 100 House / 50 Senate offices, got % / %',
      v_lower_offices, v_upper_offices;
  END IF;

  -- The whole point of the repair: two chambers, not 150.
  SELECT count(DISTINCT o.chamber_id) INTO v_distinct_ch
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_distinct_ch <> 2 THEN
    RAISE EXCEPTION 'IN-2 structure: Indiana legislative offices span % chambers, expected exactly 2', v_distinct_ch;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
    AND o.title <> CASE d.district_type WHEN 'STATE_LOWER' THEN ${q(CHAMBERS.STATE_LOWER.title)} ELSE ${q(CHAMBERS.STATE_UPPER.title)} END;
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'IN-2 structure: % Indiana legislative offices carry a non-standard title', v_mistitled;
  END IF;

  SELECT count(*) INTO v_pseudo FROM essentials.chambers
   WHERE name LIKE 'Indiana House of Representatives - District%'
      OR name LIKE 'Indiana State Senate - District%';
  IF v_pseudo <> 0 THEN
    RAISE EXCEPTION 'IN-2 structure: % pseudo-chambers survive -- one still holds an office', v_pseudo;
  END IF;

  RAISE NOTICE 'IN-2 structure OK: 2 chambers, 100+50 districts, 100+50 offices, 0 pseudo-chambers';
END $$;

COMMIT;
`;
  const out = path.join(MIGRATIONS, 'CC_0088_in_legislature_structure.sql');
  fs.writeFileSync(out, sql);
  console.log(`wrote ${path.basename(out)} (${counts.existing} repointed, ${newOffices.length} offices created)`);
}

// ─── CC_0089 occupancy ───────────────────────────────────────────────────────
function writeIncumbents(seats, newOffices, counts, seatsWithBoth) {
  const created = seats.filter((s) => s.kind === 'new');
  const SEATS_WITH_BOTH = seatsWithBoth;

  const peopleValues = created.map((s) =>
    `  (${s.externalId}, ${q(s.full_name)}, ${q(s.first_name)}, ${q(s.last_name)})`).join(',\n');

  // Every new office gets a term. The politician is resolved by external_id (created here) or
  // by the uuid of the indiana_discovery row being reused.
  const termValues = newOffices.map((s) => {
    const c = CHAMBERS[s.chamber];
    const person = s.kind === 'new' ? `${s.externalId}::bigint, NULL::uuid` : `NULL::bigint, ${q(s.politicianId)}::uuid`;
    return `  (${q(s.geo_id)}, ${q(s.chamber)}, ${person})`;
  }).join(',\n');

  const sql = `-- CC_0089_in_legislature_incumbents.sql
-- Knight Foundation program, wave IN-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0088, which creates the chambers, districts and offices.
--
-- Seats the ${newOffices.length} Indiana legislative offices CC_0088 created:
--   ${String(counts.new).padStart(3)} people created here, external_id band -1332001 .. -1332150
--   ${String(counts.reuse).padStart(3)} people REUSED from the existing indiana_discovery cohort
--   ${String(counts.existing).padStart(3)} seats already held a person and are NOT touched by this migration
--
-- 🔴🔴 THE 92 REUSED ROWS ARE THE WHOLE POINT, AND THEY ARE NOT DUPLICATES BEING CREATED --
-- THEY ARE DUPLICATES BEING AVOIDED. Production holds 672 politicians sourced
-- 'indiana_discovery', 671 of whom hold an office with NO district_id, NO chamber_id and no
-- government: 305 'Indiana Elected Official', 231 'State Representative', 102 'State Senator'.
-- No address can reach any of them and nothing errors. 92 of the 150 sitting legislators are in
-- that cohort. Creating fresh rows for them would add 92 duplicates to Indiana's existing
-- duplicate problem, so this migration seats the people who are already there.
--
-- ⚠ 92 MATCHED, ${counts.reuse} ARE REUSED HERE, AND THE DIFFERENCE IS NOT A ROUNDING ERROR. The other
-- ${92 - counts.reuse} sit on seats that were ALREADY held by a 'ballotready' row, so their office needs no
-- term and this migration does not touch them:
${SEATS_WITH_BOTH.map((s) => `--     ${s}`).join('\n')}
-- Each of those is TWO person rows for ONE human -- a genuine duplicate PERSON, not merely a
-- duplicate office. The ballotready row keeps the seat; the discovery row is left alone and is
-- part of the same recorded debt. Merging them is a dedupe decision about identity, and it is
-- deliberately not made inside a seeding wave.
--
-- 🟢 THE MATCH WAS TESTED, NOT ASSUMED. Not one of the 150 roster names matches more than one
-- indiana_discovery row -- checked explicitly, because 2 of 4 name hits in the GA wave were a
-- Colorado senator and a Utah treasurer. Corroborated a second way: of the 92, 57 hold an orphan
-- office whose title agrees with the chamber ('State Representative' for a House member), 35 hold
-- the generic 'Indiana Elected Official', and ZERO hold one that contradicts it.
--
-- ⚠ CONSEQUENCE, STATED RATHER THAN DISCOVERED LATER: after this migration each of those 92
-- people holds TWO offices -- the real, reachable one created by CC_0088, and the orphan one
-- they already had. That is expected and recorded. Retiring the 671 orphan offices is its own
-- wave: closing a term without flagging the office vacant pushes essentials.offices_missing_terms
-- unflagged drift up, and that is the count CI watches. Cleaning a seventh of the cohort would
-- make it harder to reason about, not easier.
--
-- 🔴 NO term_start EXISTS TO BE HAD, AND NONE IS INVENTED. getLegislatorDetails -- the richest
-- per-member endpoint iga.in.gov has -- returns lpid, honorific, firstname, lastname, statephone,
-- district_id, party, busemail, contact_form_url, caucus_page_url, bills[] and committees[].
-- No service-start of any kind. So every term is written OPEN-ENDED with start_precision
-- 'unknown', which is the GA-2 pattern (all 235 Georgia terms are 'unknown') and is what the 18
-- Indiana rows already in production carry. The seat_officeholder() helper is NOT used: it
-- refuses a NULL term_start, exactly as GA-4 found for its nine undated seats.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. Both sources carry it; party lives on races.primary_party.
--
-- 🔴 alternate_names IS NOT NULL DEFAULT '{}' -- an empty array is emitted, never NULL.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── ${counts.new} new people ────────────────────────────────────────────────────────────

CREATE TEMP TABLE in_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;
INSERT INTO in_new_people(external_id, full_name, first_name, last_name) VALUES
${peopleValues};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, ${q(SOURCE_A)}, '{}'
FROM in_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── ${newOffices.length} terms, one per office CC_0088 created ───────────────────────────

CREATE TEMP TABLE in_terms(geo_id text, district_type text, external_id bigint, politician_id uuid)
  ON COMMIT DROP;
INSERT INTO in_terms(geo_id, district_type, external_id, politician_id) VALUES
${termValues};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown', ${q(TERM_SOURCE)}
FROM in_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type = t.district_type AND lower(d.state) = 'in'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p
  ON (t.politician_id IS NOT NULL AND p.id = t.politician_id)
  OR (t.external_id  IS NOT NULL AND p.external_id = t.external_id)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_seated   int;
  v_offices  int;
  v_dated    int;
  v_ended    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -1332150 AND -1332001;
  IF v_people <> ${counts.new} THEN
    RAISE EXCEPTION 'IN-2 occupancy: expected ${counts.new} people in the reserved band, got %', v_people;
  END IF;

  -- count(och.politician_id), never count(*): office_current_holder LEFT JOINs from offices.
  SELECT count(o.id), count(och.politician_id) INTO v_offices, v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> 150 OR v_seated <> 150 THEN
    RAISE EXCEPTION 'IN-2 occupancy: expected 150 offices all seated, got % offices / % seated',
      v_offices, v_seated;
  END IF;

  -- Nothing may carry an invented date, and nothing may carry an end date.
  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_dated <> 0 OR v_ended <> 0 THEN
    RAISE EXCEPTION 'IN-2 occupancy: % terms carry a term_start and % carry a term_end; Indiana publishes neither',
      v_dated, v_ended;
  END IF;

  RAISE NOTICE 'IN-2 occupancy OK: 150 offices, 150 seated, 0 dated, 0 ended';
END $$;

COMMIT;
`;
  const out = path.join(MIGRATIONS, 'CC_0089_in_legislature_incumbents.sql');
  fs.writeFileSync(out, sql);
  console.log(`wrote ${path.basename(out)} (${counts.new} created, ${counts.reuse} reused, ${newOffices.length} terms)`);
}

main();
