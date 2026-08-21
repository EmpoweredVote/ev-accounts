#!/usr/bin/env node
/**
 * gen-co-legislature-migrations.mjs
 *
 * Emits the two Colorado General Assembly seeding migrations from
 * data/co-legislature-roster.json (written by build-co-legislature-roster.mjs).
 *
 *   migrations/1843_co_legislature_structure.sql   chambers + 100 offices
 *   migrations/1844_co_legislature_incumbents.sql  100 politicians + 100 terms
 *
 * Split in two to match the WA precedent (1742 / 1743): structure is stable,
 * occupancy churns with every vacancy, and keeping them apart means a re-seat
 * never has to re-run the office creation.
 *
 * Files are emitted as `_wip_` on purpose. MIGRATION NUMBERS ARE TAKEN LAST,
 * from origin/master, immediately before applying — numbers collide constantly
 * because branches are long-lived.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/gen-co-legislature-migrations.mjs
 */

import fs from 'node:fs';

const ROSTER = JSON.parse(fs.readFileSync('data/co-legislature-roster.json', 'utf8'));
const SEATS = ROSTER.seats;

if (SEATS.length !== 100) {
  console.error(`FATAL: expected 100 seats, roster has ${SEATS.length}. Re-run build-co-legislature-roster.mjs.`);
  process.exit(1);
}

const SOURCE =
  'leg.colorado.gov/legislators for identity/district/party/email; data.openstates.org for ' +
  'cross-check and the official portrait URL; ballotpedia.org chamber rosters for the ' +
  'assumed-office date. All 100 seats reconciled across all three. Retrieved 2026-08-21.';

const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

/**
 * external_id band. CO FIPS is 08, so Senate -> -(810000+n), House -> -(820000+n),
 * mirroring WA's -(5310000+n)/-(5320000+...) scheme. Verified free against prod
 * 2026-08-21: zero rows in -810001..-829999.
 */
const extId = (s) => (s.chamber === 'upper' ? -(810000 + s.district) : -(820000 + s.district));

const splitName = (full) => {
  const parts = full.trim().split(/\s+/);
  const SUFFIX = /^(jr\.?|sr\.?|ii|iii|iv|v)$/i;
  let suffix = null;
  if (parts.length > 2 && SUFFIX.test(parts[parts.length - 1])) suffix = parts.pop();
  const first = parts.shift();
  const last = parts.pop();
  return { first, last: suffix ? `${last} ${suffix}` : last, middle: parts.join(' ') || null };
};

// ── structure ────────────────────────────────────────────────────────────────
const structure = `-- co_legislature_structure.sql
-- Colorado General Assembly: 2 chambers + 100 offices.
--
-- Colorado Springs deep seed. Depends on the CO TIGER load, which ALREADY created
-- all 100 essentials.districts rows (writeDistrictRow=true for sldu/sldl). This
-- migration therefore creates CHAMBERS and OFFICES ONLY -- it must not insert
-- districts.
--
-- Confirmed against the database 2026-08-21:
--   * MTFCC orientation matches the other states in this loader:
--       STATE_UPPER (Senate) = G5210,  STATE_LOWER (House) = G5220.
--   * districts.state = 'co' (LOWERCASE) for these rows -- the TIGER loader
--     writes the abbreviation lowercased, unlike CO's older federal/exec rows
--     which carry 'CO'. Joins below use ILIKE so they are insensitive to it.
--   * geo_id is NOT unique across MTFCCs ('08011' is both SD 11 and, in other
--     states' shape, a county). Every join keys on (district_type, mtfcc, state).
--
-- COLORADO IS SINGLE-MEMBER IN BOTH CHAMBERS: 35 Senate + 65 House = 100 offices,
-- one per district. This is NOT the WA/AZ multi-member shape, so there is no
-- Position 1 / Position 2 split and the office title carries no position number.
--
-- Senate terms are 4 years and STAGGERED; House terms are 2 years, all up every
-- even year.
--
-- Idempotency: essentials.offices has NO unique index beyond the pkey, so inserts
-- use NOT EXISTS, never ON CONFLICT. Chamber idempotency keys on
-- (government_id, name), matching the five existing CO executive chambers which
-- all carry NULL external_id.

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────
-- Short-form names matching this government's existing convention ('Governor',
-- not 'Colorado Governor').

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'State Senate', 'Colorado State Senate', 35, 4, true, 'full'
FROM essentials.governments g
WHERE g.state = 'CO' AND g.geo_id = '08'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'State Senate'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'House of Representatives', 'Colorado House of Representatives', 65, 2, false, 'full'
FROM essentials.governments g
WHERE g.state = 'CO' AND g.geo_id = '08'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'House of Representatives'
  );

-- ─── Senate offices: 35, one per STATE_UPPER district ────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'State Senator', 'CO', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  JOIN essentials.governments g ON ch.government_id = g.id
  WHERE g.state = 'CO' AND g.geo_id = '08' AND ch.name = 'State Senate'
) c
WHERE d.district_type = 'STATE_UPPER'
  AND d.state ILIKE 'co'
  AND d.mtfcc = 'G5210'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'State Senator'
  );

-- ─── House offices: 65, one per STATE_LOWER district ─────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'State Representative', 'CO', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  JOIN essentials.governments g ON ch.government_id = g.id
  WHERE g.state = 'CO' AND g.geo_id = '08' AND ch.name = 'House of Representatives'
) c
WHERE d.district_type = 'STATE_LOWER'
  AND d.state ILIKE 'co'
  AND d.mtfcc = 'G5220'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'State Representative'
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  v_sen int;
  v_rep int;
  v_dup int;
BEGIN
  SELECT count(*) INTO v_sen
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'STATE_UPPER' AND d.state ILIKE 'co' AND d.mtfcc = 'G5210'
    AND o.title = 'State Senator';

  SELECT count(*) INTO v_rep
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'STATE_LOWER' AND d.state ILIKE 'co' AND d.mtfcc = 'G5220'
    AND o.title = 'State Representative';

  -- More than one office per district would fan out every downstream join.
  SELECT count(*) INTO v_dup
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER') AND d.state ILIKE 'co'
    GROUP BY o.district_id
    HAVING count(*) > 1
  ) x;

  IF v_sen <> 35 THEN
    RAISE EXCEPTION 'CO Senate offices: expected 35, got %', v_sen;
  END IF;
  IF v_rep <> 65 THEN
    RAISE EXCEPTION 'CO House offices: expected 65, got %', v_rep;
  END IF;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'CO state-leg districts carrying more than one office: %', v_dup;
  END IF;
END $$;

COMMIT;
`;

// ── incumbents ───────────────────────────────────────────────────────────────
const rows = SEATS
  .slice()
  .sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? 1 : -1))
  .map((s) => {
    const { first, last } = splitName(s.full_name);
    // alternate_names is NOT NULL with default '{}' — an explicit NULL violates the
    // constraint, so a member with no variant spelling gets an EMPTY array, not NULL.
    const aliases = s.preferred_name ? `ARRAY[${q(s.preferred_name)}]::text[]` : `'{}'::text[]`;
    const partyShort = s.party === 'Democratic' ? 'D' : s.party === 'Republican' ? 'R' : null;
    return `    (${q(s.seat)}, ${q(s.chamber === 'upper' ? 'STATE_UPPER' : 'STATE_LOWER')}, ` +
      `${q(s.chamber === 'upper' ? 'G5210' : 'G5220')}, ${q(String(s.district).padStart(3, '0'))}, ` +
      `${q(s.chamber === 'upper' ? 'State Senator' : 'State Representative')}, ` +
      `${extId(s)}, ${q(s.full_name)}, ${q(first)}, ${q(last)}, ${q(s.party)}, ${q(partyShort)}, ` +
      `${q(s.email)}, ${aliases}, DATE ${q(s.term_start)}, ${q(s.start_precision)}, ${q(s.photo_origin_url)})`;
  })
  .join(',\n');

const nDay = SEATS.filter((s) => s.start_precision === 'day').length;
const nYear = SEATS.filter((s) => s.start_precision === 'year').length;
const nPhoto = SEATS.filter((s) => s.photo_origin_url).length;
const variants = SEATS.filter((s) => s.preferred_name);

const incumbents = `-- co_legislature_incumbents.sql
-- Seats all 100 Colorado state legislators (35 senators + 65 representatives).
--
-- SOURCES -- three, reconciled seat by seat; a seat was only accepted when all
-- three named the same person (scripts/build-co-legislature-roster.mjs):
--   Identity, district, party, email, name spelling : leg.colorado.gov/legislators
--   Independent cross-check + official portrait URL : data.openstates.org
--   Assumed-office date                             : ballotpedia.org
--
-- WHY THREE. Open States is a detector, not an oracle -- it lagged our TX SD-22
-- fix and dropped a sitting TX HD-93 member. Ballotpedia is the ONLY one of the
-- three carrying an assumed-office date. The chamber's own table is the
-- tiebreaker on identity.
--
-- ⚠ THE CHAMBER'S TABLE CARRIES 101 ROWS. Senate District 21 appears twice: once
-- for Dafna Michaelson Jenet annotated "resigned as of 2/13/26" and once for her
-- successor. The resigned row is dropped by the builder, and the drop is
-- asserted rather than assumed. SD 21 is seated here to ADRIENNE BENAVIDEZ from
-- 2026-03-02, which post-dates the 2026-02-13 resignation as it must.
--
-- ⚠ term_start IS THE ASSUMED-OFFICE DATE, not the start of the current two-year
-- term. office_terms models how long THIS PERSON has held THIS SEAT, so a member
-- returned at three elections carries one continuous term from their first, not
-- three. Amy Paschal's HD 18 term begins 2025-01-08 -- the day Marc Snyder
-- vacated it for SD 12 -- which is exactly the sort of thing a "current term"
-- reading would erase.
--
-- ⚠ DO NOT SOURCE THIS FROM WIKIPEDIA'S "Start" COLUMN. Measured 2026-08-21: it
-- holds the ELECTION year for elected members and the APPOINTMENT year for
-- appointees, in the same column. Marc Snyder shows 2024 there but took the seat
-- 2025-01-08. start_precision='year' does not excuse a wrong year.
--
-- DATE PRECISION is recorded, never fabricated: ${nDay} seats carry a full
-- assumed-office date (start_precision='day'); ${nYear} carries only a year
-- (SD 26, Jeff Bridges -- Ballotpedia has "2019" and nothing finer), stored as
-- 2019-01-01 with start_precision='year' so month and day are explicitly NOT
-- being claimed.
--
-- how_started is NULL throughout. Several members arrived by vacancy-committee
-- appointment rather than election -- the non-January assumed-office dates make
-- that visible -- but which is which was not verified per member, and
-- seat_officeholder's default of 'elected' would assert it for all 100.
--
-- term_end is NULL for all (currently serving) but term_start is ALWAYS
-- populated: a NULL/NULL pair reads downstream as "currently serving" and would
-- mask a later departure.
--
-- NAME FORM: the chamber's own spelling wins; the short form other sources use is
-- kept in alternate_names so the person stays findable either way.
${variants.map((v) => `--   ${v.seat.padEnd(4)} ${v.full_name.padEnd(20)} also listed as "${v.preferred_name}"`).join('\n')}
--
-- PORTRAITS: ${nPhoto} of 100 carry an official leg.colorado.gov portrait URL,
-- recorded in photo_origin_url for the headshot pass. The remaining ${100 - nPhoto} are a
-- known backlog, not an error.
--
-- EXTERNAL IDS: Senate SD n -> -(810000+n); House HD n -> -(820000+n), mirroring
-- WA's scheme off the state FIPS (CO = 08). Verified collision-free 2026-08-21:
-- zero existing rows in -810001..-829999.
--
-- IDEMPOTENCY: politicians uses ON CONFLICT (external_id) DO NOTHING (real unique
-- index). Occupancy goes through essentials.seat_officeholder(), which is
-- idempotent and which closes any predecessor's term rather than silently
-- overlapping it -- the two-step CLAUDE.md requires. It is called only where no
-- term already exists for the pair, so a re-run is a no-op.
--
-- Joins key on (geo_id, district_type, mtfcc) because geo_id is NOT unique across
-- MTFCCs. STATE_UPPER=G5210, STATE_LOWER=G5220.

BEGIN;

CREATE TEMP TABLE co_leg_seed (
  seat            text,
  district_type   text,
  mtfcc           text,
  district_suffix text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  party           text,
  party_short     text,
  email           text,
  aliases         text[],
  term_start      date,
  start_precision text,
  photo_url       text
) ON COMMIT DROP;

INSERT INTO co_leg_seed VALUES
${rows};

-- Guard the payload itself before it touches anything.
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM co_leg_seed;
  IF v_n <> 100 THEN RAISE EXCEPTION 'seed payload: expected 100 rows, got %', v_n; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM co_leg_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT seat FROM co_leg_seed GROUP BY seat HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate seat key(s)', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party, party_short_name,
   email_addresses, alternate_names, photo_origin_url, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.party, s.party_short,
       CASE WHEN s.email IS NULL THEN NULL ELSE ARRAY[s.email]::text[] END,
       s.aliases, s.photo_url, true, true,
       ${q(SOURCE)}
FROM co_leg_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy, via the helper ───────────────────────────────────────────────
-- seat_officeholder() closes any predecessor's open-ended term before inserting,
-- which is the whole reason it exists. how_started is passed NULL explicitly:
-- the default is 'elected' and that is not known to be true for every member.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, o.id AS office_id, p.id AS politician_id, s.seat
    FROM co_leg_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.district_type = s.district_type
     AND d.mtfcc = s.mtfcc
     AND d.state ILIKE 'co'
     AND right(d.geo_id, 3) = s.district_suffix
    JOIN essentials.offices o
      ON o.district_id = d.id AND o.title = s.office_title
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = o.id AND t.politician_id = p.id
    )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      ${q(SOURCE)},
      NULL,                 -- how_started: election vs vacancy appointment not verified per member
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % legislator(s)', v_seated;
END $$;

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  v_pol int; v_held int; v_null int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_pol
  FROM essentials.politicians WHERE external_id BETWEEN -829999 AND -810001;

  -- office_current_holder LEFT JOINs from offices, so a vacancy is a NULL
  -- politician_id and NOT an absent row. Counting seated occupancy REQUIRES the
  -- IS NOT NULL, or this passes vacuously.
  SELECT count(*) INTO v_held
  FROM essentials.office_current_holder och
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER')
    AND d.state ILIKE 'co'
    AND och.politician_id IS NOT NULL;

  SELECT count(*) INTO v_null
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER') AND d.state ILIKE 'co'
    AND t.term_start IS NULL;

  -- A CO state-leg office with no term row is invisible: no holder, and nothing
  -- errors. This is the failure mode CI cannot catch, so it is asserted here.
  SELECT count(*) INTO v_orphan
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER') AND d.state ILIKE 'co'
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

  IF v_pol <> 100 THEN RAISE EXCEPTION 'CO legislators inserted: expected 100, got %', v_pol; END IF;
  IF v_held <> 100 THEN RAISE EXCEPTION 'CO state-leg seats with a current holder: expected 100, got %', v_held; END IF;
  IF v_null <> 0 THEN RAISE EXCEPTION 'CO state-leg terms with NULL term_start: %', v_null; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION 'CO state-leg offices with NO term row (invisible seats): %', v_orphan; END IF;
END $$;

COMMIT;
`;

fs.writeFileSync('migrations/1843_co_legislature_structure.sql', structure);
fs.writeFileSync('migrations/1844_co_legislature_incumbents.sql', incumbents);
console.log('wrote migrations/1843_co_legislature_structure.sql');
console.log('wrote migrations/1844_co_legislature_incumbents.sql');
console.log(`  ${SEATS.length} seats | day-precision ${nDay}, year-precision ${nYear} | portraits ${nPhoto}`);
