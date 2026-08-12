-- 1715_seat_md42a_me29_successors.sql
--
-- Seat two successors who were never seated: MD House of Delegates 42A and ME House District 29.
--
-- Both are the MIRROR IMAGE of TX SD-22 (migration 1712). There we carried a member who had left;
-- here we recorded the vacancy correctly and then never seated the person who filled it. Same
-- silence either way — essentials.office_current_holder just returns a NULL holder, so a seat with a
-- sitting representative renders as vacant to every voter in it. Found by
-- backend/scripts/roster-diff.mjs sweeping all 11 states where we hold a full chamber (22 chambers,
-- 1,338 seated rows); these two were the entire actionable result.
--
-- MD 42A — Alexander M. Harlan (R), APPOINTED, sworn 2026-08-03.
--   Nino Mangione resigned in June 2026 to run for Baltimore County Council. Harlan was nominated by
--   the Baltimore County Republican Central Committee and appointed by Gov. Moore.
--   Oracle: mgaleg.maryland.gov/mgawebsite/Members/Details/harlan01 — "Delegate Alexander M.
--   Harlan", district "42A", Republican, "Member of the Maryland House of Delegates since
--   August 3, 2026."
--
-- ME 29 — Nancy J. Theriault (R, Millinocket), ELECTED, sworn 2026-07-14.
--   Rep. Kathy Javner (R-Chester) died early 2026; Theriault won the June 2026 special election
--   (61.3%, 1,102-695 over Nancy McDowell) and was sworn in by Gov. Mills.
--   Oracle: legislature.maine.gov/house/MemberProfiles/Details/3142 — "Nancy J. Theriault", House
--   District 29, Republican, Millinocket. That profile carries NO swearing-in date; 2026-07-14 comes
--   from the Maine House Republicans release published that day, reading "sworn in today".
--
-- 🔴 NO VACANCY SPAN IS WRITTEN for either seat, deliberately. Both offices carry 0 office_terms
-- rows, so there is no predecessor term to close, and neither predecessor exists as a politician at
-- all. MD 42A's offices.vacant_since is 2026-06-01, but that date's provenance is unknown to us and
-- the sources say only "June 2026" — so per ADR 0002 we do NOT invent a span start. The honest
-- record is "Harlan from 2026-08-03, nothing asserted before".
--
-- 🔴 seat_officeholder DOES NOT CLEAR offices.is_vacant — only vacate_office syncs that flag. Seating
-- without clearing it produces a seat that holds a current term while still flagged vacant, which is
-- exactly the is_vacant trap in CLAUDE.md: any query filtering `is_vacant = false` then emits a
-- spurious all-NULL office row for the new holder. Both flags are cleared and post-verified below.
--
-- external_id: uniquely indexed (three redundant unique indexes), so a collision fails the insert
-- rather than mis-seating anyone. ME's synthetic band is district-keyed (-232000 - district), so
-- ME 29 takes the -232029 slot its own seed left empty. MD's band is sequential and its
-- district-ordered slot for 42A (-2420124) is ALREADY TAKEN — by an inactive placeholder politician
-- literally named "Vacant" that the MD seed parked there. That row is inert (inactive, no office,
-- holds no seat; 4 like it exist repo-wide) and is left untouched rather than mutated into a real
-- person, so Harlan extends the band to -2420142 instead.

DO $$
DECLARE
  v_md_office  uuid;
  v_me_office  uuid;
  v_harlan     uuid;
  v_theriault  uuid;
  v_n          int;
BEGIN
  -- ---- resolve both seats 1:1 -------------------------------------------------------------
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     AND d.label = 'State Legislative Subdistrict 42A';
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected 1 office for MD 42A, found %', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_LOWER'
     AND d.label = 'State House District 29';
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected 1 office for ME 29, found %', v_n; END IF;

  SELECT o.id INTO v_md_office
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     AND d.label = 'State Legislative Subdistrict 42A';
  SELECT o.id INTO v_me_office
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_LOWER'
     AND d.label = 'State House District 29';

  -- ---- create the two people (idempotent on the synthetic external_id) ---------------------
  -- Neither exists: searching %harlan% / %theriault% returns 16 rows, every one FEC ALLCAPS
  -- committee junk from California ("HARLAN FOR CAPITOLA CITY COUNCIL 2010"). Guarding on
  -- external_id rather than on name keeps a re-run from matching that junk.
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -2420142) THEN
    INSERT INTO essentials.politicians
      (external_id, full_name, first_name, last_name, party,
       is_active, is_incumbent, is_appointed, appointment_date, office_id, source)
    VALUES
      (-2420142, 'Alexander M. Harlan', 'Alexander', 'Harlan', 'Republican',
       true, true, true, DATE '2026-08-03', v_md_office,
       'mgaleg.maryland.gov Members/Details/harlan01, checked 2026-08-12 (migration 1715)');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -232029) THEN
    INSERT INTO essentials.politicians
      (external_id, full_name, first_name, last_name, party,
       is_active, is_incumbent, is_appointed, office_id, source)
    VALUES
      (-232029, 'Nancy J. Theriault', 'Nancy', 'Theriault', 'Republican',
       true, true, false, v_me_office,
       'legislature.maine.gov house/MemberProfiles/Details/3142, checked 2026-08-12 (migration 1715)');
  END IF;

  SELECT id INTO v_harlan    FROM essentials.politicians WHERE external_id = -2420142;
  SELECT id INTO v_theriault FROM essentials.politicians WHERE external_id = -232029;
  IF v_harlan IS NULL OR v_theriault IS NULL THEN
    RAISE EXCEPTION 'politician rows did not materialize (harlan=%, theriault=%)',
                    v_harlan, v_theriault;
  END IF;

  -- ---- seat them --------------------------------------------------------------------------
  PERFORM essentials.seat_officeholder(
    v_md_office, v_harlan, DATE '2026-08-03',
    'mgaleg.maryland.gov Members/Details/harlan01 ("since August 3, 2026"), checked 2026-08-12; '
      || 'appointed by Gov. Moore after Mangione resigned (migration 1715)',
    'appointed', 'day');

  PERFORM essentials.seat_officeholder(
    v_me_office, v_theriault, DATE '2026-07-14',
    'legislature.maine.gov MemberProfiles/Details/3142 + Maine House Republicans release '
      || '2026-07-14 ("sworn in today"), checked 2026-08-12; June 2026 special election after '
      || 'Rep. Javner died (migration 1715)',
    'elected', 'day');

  -- ---- clear the vacancy flags (seat_officeholder does not) --------------------------------
  UPDATE essentials.offices
     SET is_vacant = false, vacant_since = NULL
   WHERE id IN (v_md_office, v_me_office)
     AND (is_vacant IS DISTINCT FROM false OR vacant_since IS NOT NULL);

  -- ---- post-verify ------------------------------------------------------------------------
  -- Both seats resolve to the right person. office_current_holder LEFT JOINs from offices, so the
  -- test is on politician_id, never on row count.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder
                  WHERE office_id = v_md_office AND politician_id = v_harlan) THEN
    RAISE EXCEPTION 'MD 42A does not resolve to Harlan';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder
                  WHERE office_id = v_me_office AND politician_id = v_theriault) THEN
    RAISE EXCEPTION 'ME 29 does not resolve to Theriault';
  END IF;

  -- Terms start on the sworn dates, open-ended, at day precision.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE office_id = v_md_office AND politician_id = v_harlan
                    AND term_start = DATE '2026-08-03' AND term_end IS NULL
                    AND start_precision = 'day' AND how_started = 'appointed') THEN
    RAISE EXCEPTION 'MD 42A term row is not as specified';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE office_id = v_me_office AND politician_id = v_theriault
                    AND term_start = DATE '2026-07-14' AND term_end IS NULL
                    AND start_precision = 'day' AND how_started = 'elected') THEN
    RAISE EXCEPTION 'ME 29 term row is not as specified';
  END IF;

  -- Exactly one term row each: we asserted no vacancy span, so there must be no second row.
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE office_id = v_md_office;
  IF v_n <> 1 THEN RAISE EXCEPTION 'MD 42A should have exactly 1 term row, has %', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE office_id = v_me_office;
  IF v_n <> 1 THEN RAISE EXCEPTION 'ME 29 should have exactly 1 term row, has %', v_n; END IF;

  -- The is_vacant trap: a seat holding a current term must not still be flagged vacant.
  IF EXISTS (SELECT 1 FROM essentials.offices
              WHERE id IN (v_md_office, v_me_office)
                AND (is_vacant IS NOT false OR vacant_since IS NOT NULL)) THEN
    RAISE EXCEPTION 'a newly seated office is still flagged vacant';
  END IF;

  -- Chamber totals now match the rosters: MD 141 delegates, ME 151 representatives.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     AND och.politician_id IS NOT NULL;
  IF v_n <> 141 THEN RAISE EXCEPTION 'expected 141 seated MD delegates, found %', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_LOWER'
     AND och.politician_id IS NOT NULL;
  IF v_n <> 151 THEN RAISE EXCEPTION 'expected 151 seated ME representatives, found %', v_n; END IF;

  -- The "Vacant" placeholder at -2420124 stays inert: not seated, not activated.
  IF EXISTS (SELECT 1 FROM essentials.politicians p
              WHERE p.external_id = -2420124
                AND (p.is_active OR EXISTS (SELECT 1 FROM essentials.office_current_holder och
                                             WHERE och.politician_id = p.id))) THEN
    RAISE EXCEPTION 'the -2420124 "Vacant" placeholder was disturbed';
  END IF;

  RAISE NOTICE 'seated Harlan (MD 42A, 2026-08-03) and Theriault (ME 29, 2026-07-14)';
END $$;
