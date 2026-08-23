#!/usr/bin/env node
/**
 * gen-nc-legislature-migrations.mjs
 *
 * Emits the two North Carolina General Assembly seeding migrations from
 * data/nc-legislature-roster.json (170 seats: 120 House + 50 Senate).
 *
 *   migrations/_wip_nc_legislature_structure.sql   2 chambers + 170 offices
 *   migrations/_wip_nc_legislature_incumbents.sql  170 politicians + 170 terms
 *
 * Split in two to match the WA (1742/1743) and CO (1843/1844) precedent:
 * structure is stable, occupancy churns with every vacancy, and keeping them
 * apart means a re-seat never has to re-run office creation.
 *
 * Files are emitted as `_wip_` on purpose. MIGRATION NUMBERS ARE TAKEN LAST,
 * immediately before applying, in Chris's CA_ namespace (CA_0004 / CA_0005) --
 * this script does NOT apply anything and does NOT touch the database.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/gen-nc-legislature-migrations.mjs
 */

import fs from 'node:fs';

const ROSTER = JSON.parse(fs.readFileSync('data/nc-legislature-roster.json', 'utf8'));
const SEATS = ROSTER.seats;

if (SEATS.length !== 170) {
  console.error(`FATAL: expected 170 seats, roster has ${SEATS.length}. Re-run build-nc-legislature-roster.mjs.`);
  process.exit(1);
}

const GOV_ID = '3a09655d-0d33-45c5-a33a-7a863bd653a1'; // State of North Carolina — ALREADY EXISTS

// SQL string literal. Escapes single quotes only -- the sole SQL-meaningful
// character inside a single-quoted literal. Double quotes (Jerry "Alan"
// Branson) and non-ASCII (Erin Paré, Renée A. Price) pass through untouched:
// this is a byte-for-byte pass of the name into the literal, never a
// normalization. NFD-stripping helpers used elsewhere in this repo for
// cross-source MATCHING must never run on a value headed into full_name.
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

/**
 * external_id band. NC FIPS is 37, so Senate -> -(3710000+n), House ->
 * -(3720000+n), mirroring WA's -(5310000+n)/-(5320000+n) and CO's
 * -(810000+n)/-(820000+n) schemes. Verified free against prod 2026-08-22:
 * zero rows in -3729999..-3710001 (see generator output below).
 */
const extId = (s) => (s.chamber === 'upper' ? -(3710000 + s.district) : -(3720000 + s.district));

/**
 * Split a roster "name" string into the shape essentials.politicians wants.
 *
 * Handles three shapes actually present in this roster (verified against all
 * 170 names before writing this):
 *   - "First Last"                        -> first / last
 *   - "First M. Last"                     -> first / middle_initial / last
 *   - "First Last, SUFFIX"                -> suffix stripped to name_suffix
 *       e.g. "Ted Davis, Jr.", "Timothy Reeder, MD", "Robert T. Reives, II"
 *   - a quoted nickname token mid-name    -> stripped to preferred_name
 *       e.g. Jerry "Alan" Branson -> first Jerry, last Branson, preferred
 *       name Alan. This is the ONLY name in the roster with quote characters.
 *
 * Not asserted by any post-verify gate (full_name is what's rendered; this is
 * best-effort structure on top of it), so no name shape in this roster is
 * dropped or corrupted if the split is imperfect -- full_name always carries
 * the roster's exact string.
 */
// Surname particles that begin a multi-word surname (a preposition/article
// fused onto the family name, not a middle name). Matched case-INSENSITIVELY
// for detection only -- the token's original casing is always preserved in
// the output, since some people capitalise theirs (Van Buren) and some don't
// (van Buren); normalizing either to a house style would misstate the name.
const SURNAME_PARTICLES = new Set([
  'von', 'van', 'de', 'del', 'della', 'di', 'da', 'du',
  'la', 'le', 'den', 'ter', 'ten', 'dos', 'das',
]);

const splitName = (full) => {
  let namePart = full;
  let suffix = null;
  const commaIdx = full.indexOf(',');
  if (commaIdx !== -1) {
    namePart = full.slice(0, commaIdx).trim();
    suffix = full.slice(commaIdx + 1).trim();
  }

  const tokens = namePart.split(/\s+/);
  let preferred = null;
  const quotedIdx = tokens.findIndex((t) => /^"[^"]+"$/.test(t));
  if (quotedIdx !== -1) {
    preferred = tokens[quotedIdx].slice(1, -1);
    tokens.splice(quotedIdx, 1);
  }

  // A particle counts only when it is strictly interior -- not the first
  // token (which would just be a one-word first name) and not the last
  // (already the whole surname on its own). This is what keeps the rule from
  // firing on "A. Reece Pyrtle" or any suffix/credential row: none of their
  // interior tokens are in SURNAME_PARTICLES.
  let particleIdx = -1;
  for (let i = 1; i < tokens.length - 1; i++) {
    if (SURNAME_PARTICLES.has(tokens[i].toLowerCase())) {
      particleIdx = i;
      break;
    }
  }

  const first = tokens[0];
  let last;
  let middle;
  if (particleIdx !== -1) {
    // Everything from the particle onward is the surname, e.g.
    // ["Julie", "von", "Haefen"] -> first "Julie", last "von Haefen".
    last = tokens.slice(particleIdx).join(' ');
    middle = tokens.slice(1, particleIdx).join(' ') || null;
  } else {
    last = tokens[tokens.length - 1];
    middle = tokens.slice(1, -1).join(' ') || null;
  }

  return { first, last, middle, suffix, preferred };
};

const RETRIEVED = ROSTER.retrievedAt ? ROSTER.retrievedAt.slice(0, 10) : '2026-08-22';

// Per-seat source: the member's own ncleg.gov biography page (identity, district,
// chamber) plus the roster-level note that the assumed-office date was cross-
// checked against Ballotpedia. This is more precise than a single blanket
// citation because the roster already carries a per-member biography URL.
const sourceFor = (s) =>
  `${s.source} (ncleg.gov Member Biography — identity, district, chamber); assumed-office date ` +
  `cross-checked against Ballotpedia (matched by ${s.ballotpediaConfirmedBy}). Retrieved ${RETRIEVED}.`;

// ── structure ────────────────────────────────────────────────────────────────
const structure = `-- nc_legislature_structure.sql
-- North Carolina General Assembly: 2 chambers + 170 offices.
--
-- NC General Assembly wave 1. Depends on the NC TIGER/redistricting load, which
-- ALREADY created all 170 essentials.districts rows (120 STATE_LOWER + 50
-- STATE_UPPER, geo_id = '37' || lpad(district,3,'0'), state 'nc'). This
-- migration therefore creates CHAMBERS and OFFICES ONLY -- it must not insert
-- districts.
--
-- 🔴 geo_id is NOT unique across chambers in NC: '37001' is BOTH House District 1
-- and Senate District 1 (exactly 50 colliding geo_ids, one per Senate seat,
-- since NC runs 120 House / 50 Senate districts numbered independently from 1).
-- Every office join below keys on (geo_id, district_type) together, which IS
-- unique (verified zero duplicate groups) -- a bare geo_id join would either
-- attach a House office to a Senate district or fan out to two rows per seat,
-- while still producing a plausible-looking 170 count.
--
-- essentials.offices.politician_id was DROPPED (ADR 0002 phase 5, migration
-- 1463). This migration writes NO occupant -- occupancy is
-- migrations/_wip_nc_legislature_incumbents.sql, entirely through
-- essentials.office_terms.
--
-- Idempotency: essentials.offices has no unique index beyond the pkey, so
-- inserts use NOT EXISTS, never ON CONFLICT. Chamber idempotency keys on
-- (government_id, name).

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────
-- One chamber per CHAMBER, not one per district (Indiana's 100+
-- "... - District 45" rows with government_id-per-row and official_count=0 is
-- the bug this avoids, not the pattern to follow).

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'North Carolina House of Representatives', 'North Carolina House of Representatives', 120, 2, false, 'full'
FROM essentials.governments g
WHERE g.id = ${q(GOV_ID)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'North Carolina House of Representatives'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'North Carolina Senate', 'North Carolina Senate', 50, 2, false, 'full'
FROM essentials.governments g
WHERE g.id = ${q(GOV_ID)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'North Carolina Senate'
  );

-- ─── House offices: 120, one per STATE_LOWER district ────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Representative', 'NC', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = ${q(GOV_ID)} AND ch.name = 'North Carolina House of Representatives'
) c
WHERE d.district_type = 'STATE_LOWER'
  AND lower(d.state) = 'nc'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Representative'
  );

-- ─── Senate offices: 50, one per STATE_UPPER district ────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Senator', 'NC', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = ${q(GOV_ID)} AND ch.name = 'North Carolina Senate'
) c
WHERE d.district_type = 'STATE_UPPER'
  AND lower(d.state) = 'nc'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Senator'
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE n_ch int; n_off int; n_orphan int;
BEGIN
  SELECT count(*) INTO n_ch FROM essentials.chambers c
   WHERE c.government_id = ${q(GOV_ID)}
     AND c.name IN ('North Carolina House of Representatives', 'North Carolina Senate');
  IF n_ch <> 2 THEN RAISE EXCEPTION 'CA_0004: expected 2 NC legislative chambers, found %', n_ch; END IF;

  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 170 THEN RAISE EXCEPTION 'CA_0004: expected 170 NC legislative offices, found %', n_off; END IF;

  -- Every office must hang off a district that actually has geometry, or the
  -- seat is unreachable by address and nothing will error.
  SELECT count(*) INTO n_orphan FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND (d.geo_id IS NULL
          OR NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id));
  IF n_orphan <> 0 THEN RAISE EXCEPTION 'CA_0004: % NC legislative offices lack district geometry', n_orphan; END IF;
END $$;

-- Fourth assertion, same gate: per-chamber shape + no cross-wiring. Catches
-- exactly the failure mode where a bare geo_id join fans a House office onto a
-- Senate district (or vice versa) while still producing a plausible 170 total.
DO $$
DECLARE n_lower int; n_upper int; n_dupe int;
BEGIN
  SELECT count(*) INTO n_lower FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='nc' AND d.district_type='STATE_LOWER';
  IF n_lower <> 120 THEN RAISE EXCEPTION 'CA_0004: expected 120 NC House offices, found %', n_lower; END IF;

  SELECT count(*) INTO n_upper FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='nc' AND d.district_type='STATE_UPPER';
  IF n_upper <> 50 THEN RAISE EXCEPTION 'CA_0004: expected 50 NC Senate offices, found %', n_upper; END IF;

  -- Two offices on one district means the geo_id join fanned across chambers.
  SELECT count(*) INTO n_dupe FROM (
    SELECT o.district_id FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state)='nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     GROUP BY o.district_id HAVING count(*) > 1
  ) x;
  IF n_dupe <> 0 THEN RAISE EXCEPTION 'CA_0004: % NC districts carry more than one office — geo_id join fanned across chambers', n_dupe; END IF;
END $$;

COMMIT;
`;

// ── incumbents ───────────────────────────────────────────────────────────────
const rows = SEATS
  .slice()
  .sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? 1 : -1))
  .map((s) => {
    const { first, last, middle, suffix, preferred } = splitName(s.name);
    const districtType = s.chamber === 'upper' ? 'STATE_UPPER' : 'STATE_LOWER';
    const title = s.chamber === 'upper' ? 'Senator' : 'Representative';
    const geoId = '37' + String(s.district).padStart(3, '0');
    const aliases = preferred ? `ARRAY[${q(preferred)}]::text[]` : `'{}'::text[]`;
    const termStartSql = s.assumedOffice === null ? 'NULL' : `DATE ${q(s.assumedOffice)}`;
    return (
      `    (${q(geoId)}, ${q(districtType)}, ${q(title)}, ${extId(s)}, ${q(s.name)}, ` +
      `${q(first)}, ${q(last)}, ${q(middle)}, ${q(suffix)}, ${aliases}, ${q(s.portraitUrl ?? null)}, ` +
      `${termStartSql}, ${q(s.assumedPrecision)}, ${q(s.howStarted)}, ${q(sourceFor(s))})`
    );
  })
  .join(',\n');

const nDay = SEATS.filter((s) => s.assumedPrecision === 'day').length;
const nYear = SEATS.filter((s) => s.assumedPrecision === 'year').length;
const nUnknown = SEATS.filter((s) => s.assumedPrecision === 'unknown').length;
const nAppointed = SEATS.filter((s) => s.howStarted === 'appointed').length;
const nElected = SEATS.filter((s) => s.howStarted === 'elected').length;
const nullDateSeats = SEATS.filter((s) => s.assumedOffice === null);

const incumbents = `-- nc_legislature_incumbents.sql
-- Seats all 170 North Carolina General Assembly members (120 Representatives +
-- 50 Senators).
--
-- SOURCE: ncleg.gov/Members/Biography/<chamber>/<memberId> per seat (identity,
-- district, chamber, portrait), cross-checked against Ballotpedia for the
-- assumed-office date (data/nc-legislature-roster.json, built by
-- build-nc-legislature-roster.mjs). Retrieved ${RETRIEVED}.
--
-- DATE PRECISION is recorded, never fabricated: ${nDay} seats carry a full
-- assumed-office date (start_precision='day'); ${nYear} carry only a year
-- (stored as YYYY-01-01 with start_precision='year' so month/day are explicitly
-- NOT being claimed); ${nUnknown} seat's start date is genuinely unknown.
--
-- ⚠ THE ONE UNKNOWN-START SEAT: Jake Johnson, NC House District 113. The
-- roster carries assumedOffice: null / assumedPrecision: 'unknown'. Per
-- CLAUDE.md ("don't invent dates") and repo precedent (migration 1459's phase-2
-- backfill, and every later fix that touched an unknown-start row -- 1465,
-- 1546, 1635, 1798, 1814 -- all use this identical shape), this is recorded as
-- term_start NULL / start_precision 'unknown' via a DIRECT INSERT into
-- essentials.office_terms, NOT through essentials.seat_officeholder(): that
-- helper RAISE EXCEPTIONs on a NULL p_term_start by design (confirmed against
-- prod 2026-08-22 -- "seat_officeholder requires a real term_start"). He is
-- still seated: essentials.current_office_holders treats term_start IS NULL /
-- term_end IS NULL as "currently holds", so he counts in the 170-seated gate
-- below exactly like every dated seat.
--
-- how_started: NC's own roster distinguishes this per member --
-- ${nElected} 'elected', ${nAppointed} 'appointed' (vacancy replacements). Passed through to
-- p_how_started explicitly; NOT left to seat_officeholder's 'elected' default,
-- which would misclassify the 8 appointees.
--
-- NAME HANDLING: full_name is the roster's exact string, byte-for-byte -- never
-- run through NFD/diacritic-stripping (those helpers exist elsewhere in this
-- repo only for cross-source MATCHING, never for what gets stored). Two names
-- carry non-ASCII characters (Erin Paré, HD 37; Renée A. Price, HD 50) and one
-- carries embedded double quotes around a nickname (Jerry "Alan" Branson, HD
-- 59, stored with preferred_name='Alan'). This file is written as UTF-8
-- without a BOM; the generator verifies the emitted bytes decode correctly for
-- both accented names before reporting success.
--
-- EXTERNAL IDS: House HD n -> -(3720000+n); Senate SD n -> -(3710000+n),
-- mirroring WA's/CO's scheme off the state FIPS (NC = 37). Verified
-- collision-free against prod 2026-08-22: zero existing rows in
-- -3729999..-3710001.
--
-- IDEMPOTENCY: politicians uses ON CONFLICT (external_id) DO NOTHING (real
-- unique index). Dated seats go through essentials.seat_officeholder(), which
-- is idempotent and closes any predecessor's term rather than silently
-- overlapping it. The one unknown-start seat uses a guarded direct INSERT
-- (NOT EXISTS on office_id) for the same idempotency, since seat_officeholder()
-- cannot accept it.
--
-- Joins key on (geo_id, district_type) together -- geo_id alone is NOT unique
-- across NC's two chambers (50 colliding geo_ids, e.g. '37001' is both HD-1 and
-- SD-1).

BEGIN;

CREATE TEMP TABLE nc_leg_seed (
  geo_id          text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_name     text,
  name_suffix     text,
  aliases         text[],
  photo_url       text,
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO nc_leg_seed VALUES
${rows};

-- Guard the payload itself before it touches anything.
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM nc_leg_seed;
  IF v_n <> 170 THEN RAISE EXCEPTION 'seed payload: expected 170 rows, got %', v_n; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM nc_leg_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT geo_id, district_type FROM nc_leg_seed GROUP BY geo_id, district_type HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate (geo_id, district_type) key(s)', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, photo_origin_url, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_name, s.name_suffix,
       s.aliases, s.photo_url, true, true, s.source
FROM nc_leg_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy: dated seats, via the helper ──────────────────────────────────
-- seat_officeholder() closes any predecessor's open-ended term before
-- inserting, which is the whole reason it exists.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
    FROM nc_leg_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id
     AND d.district_type = s.district_type
     AND lower(d.state) = 'nc'
    JOIN essentials.offices o
      ON o.district_id = d.id AND o.title = s.office_title
    WHERE s.term_start IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM essentials.office_terms t
        WHERE t.office_id = o.id AND t.politician_id = p.id
      )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      r.source,
      r.how_started,
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % NC legislator(s) with a known start date', v_seated;
END $$;

-- ─── Occupancy: the one unknown-start seat, direct insert ────────────────────
-- Jake Johnson, HD 113. seat_officeholder() refuses a NULL p_term_start by
-- design -- this is the identical shape the 1459 phase-2 backfill and its
-- later corrections (1465, 1546, 1635, 1798, 1814) all use for a genuinely
-- unknown start: term_start NULL, term_end NULL, start_precision 'unknown'.
-- The office_terms_no_overlap exclusion constraint permits this because it is
-- the only term ever written for this office.

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, s.start_precision, s.how_started, s.source
FROM nc_leg_seed s
JOIN essentials.politicians p ON p.external_id = s.ext_id
JOIN essentials.districts d
  ON d.geo_id = s.geo_id
 AND d.district_type = s.district_type
 AND lower(d.state) = 'nc'
JOIN essentials.offices o
  ON o.district_id = d.id AND o.title = s.office_title
WHERE s.term_start IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  v_pol int; v_seated int; v_appointed int;
BEGIN
  SELECT count(*) INTO v_pol
  FROM essentials.politicians WHERE external_id BETWEEN -3729999 AND -3710001;
  IF v_pol <> 170 THEN RAISE EXCEPTION 'CA_0005: NC legislators inserted: expected 170, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id, never an absent row.
  -- count(*) would pass vacuously with every seat empty.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> 170 THEN RAISE EXCEPTION 'CA_0005: expected 170 seated NC legislators, found %', v_seated; END IF;

  SELECT count(*) INTO v_appointed
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND t.how_started = 'appointed';
  IF v_appointed <> 8 THEN RAISE EXCEPTION 'CA_0005: expected 8 NC legislative terms with how_started=appointed, found %', v_appointed; END IF;
END $$;

COMMIT;
`;

fs.writeFileSync('migrations/_wip_nc_legislature_structure.sql', structure, { encoding: 'utf8' });
fs.writeFileSync('migrations/_wip_nc_legislature_incumbents.sql', incumbents, { encoding: 'utf8' });

// Verify the emitted bytes round-trip the two non-ASCII names correctly and
// carry no BOM (node's utf8 writer never adds one, but check anyway).
const emitted = fs.readFileSync('migrations/_wip_nc_legislature_incumbents.sql', 'utf8');
const hasBOM = fs.readFileSync('migrations/_wip_nc_legislature_incumbents.sql').slice(0, 3).equals(Buffer.from([0xef, 0xbb, 0xbf]));
const pareOk = emitted.includes('Erin Paré');
const reneeOk = emitted.includes('Renée A. Price');
const bransonOk = emitted.includes('Jerry "Alan" Branson');
if (hasBOM) {
  console.error('FATAL: emitted incumbents file carries a UTF-8 BOM.');
  process.exit(1);
}
if (!pareOk || !reneeOk) {
  console.error(`FATAL: accented name round-trip failed (Paré: ${pareOk}, Renée: ${reneeOk}).`);
  process.exit(1);
}
if (!bransonOk) {
  console.error('FATAL: Jerry "Alan" Branson round-trip failed (quote characters mangled).');
  process.exit(1);
}

console.log('wrote migrations/_wip_nc_legislature_structure.sql');
console.log('wrote migrations/_wip_nc_legislature_incumbents.sql');
console.log(`  ${SEATS.length} seats | House ${SEATS.filter((s) => s.chamber === 'lower').length}, Senate ${SEATS.filter((s) => s.chamber === 'upper').length}`);
console.log(`  precision: day ${nDay}, year ${nYear}, unknown ${nUnknown}`);
console.log(`  how_started: elected ${nElected}, appointed ${nAppointed}`);
console.log(`  unknown-start seat(s): ${nullDateSeats.map((s) => `${s.name} (HD ${s.district})`).join(', ')}`);
console.log('  BOM check: none found');
console.log(`  accented-name round-trip: Erin Paré ok=${pareOk}, Renée A. Price ok=${reneeOk}`);
console.log(`  quoted-nickname round-trip: Jerry "Alan" Branson ok=${bransonOk}`);
