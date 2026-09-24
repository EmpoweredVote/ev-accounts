-- CA_0198_ca_ad3_gallagher_vacancy.sql
--
-- Close James Gallagher's tenure in California Assembly District 3, and date its start.
--
-- He resigned the Assembly to take CA-01 in the U.S. House, where he was sworn in on 2026-06-10
-- (seated here by migration 1536). Prod still carried him on the open-ended AD-3 `office_terms`
-- row written by the ADR 0002 phase-2 backfill (migration 1459, start_precision 'unknown'), so he
-- resolved through `essentials.office_current_holder` as the sitting AD-3 Assembly Member as well as
-- the CA-01 Representative -- and, with term_start NULL, `office_holders_as_of` answered "Gallagher"
-- for AD-3 on every past date, including the years before he held it.
--
-- Sources (all checked 2026-09-23, the day this was written):
--   * Assembly Journal, 2025-26 Regular Session, June 9, 2026, p. 5632 (Communications), his letter
--     to Speaker Rivas: "I hereby resign from my current office as Assemblymember for California's
--     Third Assembly District, effective at close of business on June 9th, 2026."
--     https://clerk.assembly.ca.gov/sites/clerk.assembly.ca.gov/files/adj060926.pdf
--   * assembly.ca.gov/assemblymembers lists District 03 as "Vacant" -- the roster's only vacancy
--     ("80 Members | democrat: 60 | republican: 19 | vacant: 1"). No successor has been seated, so
--     `vacate_office` -- not `seat_officeholder` -- is the correct call. The seat goes to the
--     November 2026 general election; this migration seats nobody.
--   * Start: the Wikipedia infobox gives his Assembly tenure as "December 1, 2014 - June 9, 2026"
--     (3rd district). Cal. Const. art. IV, sec. 2(a) starts an Assembly term on the first Monday in
--     December after the election, which in 2014 was December 1. One unbroken tenure (re-elected
--     2016-2024), so a single term row is right. how_started 'elected' (November 2014).
--
-- 2026-06-09 is his LAST DAY: "close of business" means he held the seat through that day (he
-- addressed the floor as its member that afternoon). vacate_office takes the FIRST VACANT day, so it
-- gets 2026-06-10 and writes term_end = 2026-06-09 itself -- the day before his House term starts,
-- so the two tenures neither overlap nor leave a gap. (Wikipedia's district article says "vacant
-- since June 9"; the letter's "close of business" is the primary text and wins.)
--
-- This closes and dates a tenure. It does not touch the `politicians` row, his CA-01 seat, his
-- is_incumbent flag (he is still an incumbent -- of CA-01) or his 16 compass answers, all asserted
-- intact below. Found while linking him to FEC (PR #663): he was the only politician in that run
-- holding a state-legislative seat and a U.S. House seat at once.
--
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews, in chat). Dry run first as BEGIN ... ROLLBACK:
--   every gate passed and the rollback left the AD-3 term open with no start. A double run in one transaction was a
--   no-op (one "vacated" suffix). Apply: every gate passed. Verified after: AD-3 term 2014-12-01..2026-06-09 resigned,
--   no current holder, 79 Assembly members seated; GET /api/essentials/politicians?q=James Gallagher returns one row,
--   U.S. Representative CA-01. PR #671.

DO $$
DECLARE
  v_office_id   uuid;
  v_ad3_office  uuid := '1f799cc8-3663-40e6-9ee1-fcca6412884a';  -- AD-3, pinned for the cross-check
  v_ca01_office uuid := '095d8394-1b09-4009-8221-1fa5916405ac';  -- CA-01 (migration 1536)
  v_pol_id      uuid := '0a283c28-344c-40c9-ae48-bb2dcf1c7c4d';  -- James Gallagher
  v_n           int;
  v_t           record;
  v_is_vacant   boolean;
BEGIN
  -- Resolve the seat on (state, district_type, geo_id) and assert 1:1; never LIMIT 1.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.state = 'CA' AND d.district_type = 'STATE_LOWER' AND d.geo_id = '06003';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 office for CA STATE_LOWER geo_id 06003, found %', v_n;
  END IF;

  SELECT o.id INTO v_office_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.state = 'CA' AND d.district_type = 'STATE_LOWER' AND d.geo_id = '06003';
  IF v_office_id IS DISTINCT FROM v_ad3_office THEN
    RAISE EXCEPTION 'CA AD-3 resolved to office %, expected %', v_office_id, v_ad3_office;
  END IF;

  -- 1. Date the start. Guarded on term_start IS NULL, so a re-run is a no-op and a row someone has
  --    since dated is left alone.
  UPDATE essentials.office_terms t
     SET term_start      = DATE '2014-12-01',
         start_precision = 'day',
         how_started     = 'elected',
         source          = t.source || ' | CA_0198 (2026-09-23): start sourced -- Assembly tenure '
                           || '"December 1, 2014 - June 9, 2026" (en.wikipedia.org/wiki/'
                           || 'James_Gallagher_(California_politician)); Cal. Const. art. IV sec. 2(a) '
                           || 'first Monday in December 2014 = 2014-12-01'
   WHERE t.office_id = v_office_id
     AND t.politician_id = v_pol_id
     AND t.term_start IS NULL;

  -- 2. Close it. Idempotent: act only while Gallagher is still the resolved current holder. A re-run
  --    after the fix, or a run after a successor has been seated, is a no-op.
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder och
              WHERE och.office_id = v_office_id AND och.politician_id = v_pol_id) THEN
    PERFORM essentials.vacate_office(
      v_office_id,
      DATE '2026-06-10',
      'CA_0198: resigned "effective at close of business on June 9th, 2026" (Assembly Journal '
        || '2026-06-09 p. 5632, clerk.assembly.ca.gov adj060926.pdf) on election to CA-01; '
        || 'assembly.ca.gov/assemblymembers lists District 03 Vacant, checked 2026-09-23');
  END IF;

  -- ---- post-verify -------------------------------------------------------------------------

  -- The seat resolves to nobody now. office_current_holder LEFT JOINs from offices, so a vacancy is
  -- a NULL politician_id, not an absent row -- counting rows would assert nothing.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.office_id = v_office_id AND och.politician_id IS NULL) THEN
    RAISE EXCEPTION 'CA AD-3 still resolves to a current holder after vacate';
  END IF;

  -- His AD-3 term is exactly [2014-12-01, 2026-06-09], resigned, and the only term on the seat.
  SELECT count(*) INTO v_n FROM essentials.office_terms t WHERE t.office_id = v_office_id;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'expected 1 office_terms row on CA AD-3, found %', v_n;
  END IF;
  SELECT t.term_start, t.term_end, t.start_precision, t.how_started, t.how_ended INTO v_t
    FROM essentials.office_terms t
   WHERE t.office_id = v_office_id AND t.politician_id = v_pol_id;
  IF v_t.term_start IS DISTINCT FROM DATE '2014-12-01' OR v_t.start_precision IS DISTINCT FROM 'day'
     OR v_t.term_end IS DISTINCT FROM DATE '2026-06-09' OR v_t.how_ended IS DISTINCT FROM 'resigned'
     OR v_t.how_started IS DISTINCT FROM 'elected' THEN
    RAISE EXCEPTION 'unexpected Gallagher AD-3 term: %', v_t;
  END IF;

  -- History answers correctly on both sides of each boundary.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_holders_as_of(DATE '2026-06-09') h
                  WHERE h.office_id = v_office_id AND h.politician_id = v_pol_id) THEN
    RAISE EXCEPTION 'office_holders_as_of(2026-06-09) should return Gallagher for AD-3';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_holders_as_of(DATE '2026-06-10') h
              WHERE h.office_id = v_office_id AND h.politician_id IS NOT NULL) THEN
    RAISE EXCEPTION 'office_holders_as_of(2026-06-10) should return nobody for AD-3';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_holders_as_of(DATE '2014-11-30') h
              WHERE h.office_id = v_office_id AND h.politician_id = v_pol_id) THEN
    RAISE EXCEPTION 'office_holders_as_of(2014-11-30) should not return Gallagher for AD-3';
  END IF;

  -- The office carries the vacancy flag and the first vacant day.
  SELECT o.is_vacant INTO v_is_vacant FROM essentials.offices o WHERE o.id = v_office_id;
  IF v_is_vacant IS NOT TRUE THEN
    RAISE EXCEPTION 'CA AD-3 is_vacant did not get set';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.offices o
                  WHERE o.id = v_office_id AND o.vacant_since::date = DATE '2026-06-10') THEN
    RAISE EXCEPTION 'CA AD-3 vacant_since is not 2026-06-10';
  END IF;

  -- The person, his House seat, his incumbency and his research survive.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.office_id = v_ca01_office AND och.politician_id = v_pol_id) THEN
    RAISE EXCEPTION 'Gallagher no longer resolves as the CA-01 holder';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE p.id = v_pol_id AND p.is_active AND p.is_incumbent) THEN
    RAISE EXCEPTION 'Gallagher politicians row is missing, inactive, or no longer an incumbent';
  END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers a WHERE a.politician_id = v_pol_id;
  IF v_n <> 16 THEN
    RAISE EXCEPTION 'expected Gallagher to keep 16 compass answers, found %', v_n;
  END IF;

  -- The other 79 Assembly seats are untouched; this matches the official roster's 79 members.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.name = 'California State Assembly'
     AND och.politician_id IS NOT NULL;      -- same trap: the join alone would count all 80
  IF v_n <> 79 THEN
    RAISE EXCEPTION 'expected 79 seated CA Assembly members after vacating AD-3, found %', v_n;
  END IF;

  RAISE NOTICE 'CA AD-3 vacated: Gallagher term 2014-12-01..2026-06-09, 79 Assembly members remain seated';
END $$;
