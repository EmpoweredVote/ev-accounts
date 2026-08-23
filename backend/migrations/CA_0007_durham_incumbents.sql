-- CA_0007_durham_incumbents.sql
-- Seats all 15 Durham, NC elected officials (7 City of Durham + 8 Durham
-- County), keyed to the offices CA_0006_durham_structure.sql creates.
--
-- SOURCE: backend/data/seed-durham-2026/ROSTERS.md (committed, reviewed,
-- fact-checked; sources S1-S19 cited there), transcribed machine-readably in
-- data/seed-durham-2026/durham-roster.json. Retrieved 2026-08-22. No new
-- research was performed by this generator.
--
-- DATE PRECISION is recorded, never fabricated: 14 seats carry a full
-- assumed-office date (start_precision='day'); Wendy Jacobs' original 2012
-- seating could not be pinned to a day despite a primary-source search
-- (ROSTERS.md 'source defects' section) and is stored as 2012-01-01 with
-- start_precision='year' rather than guessed from N.C.G.S. Sec. 153A-26 alone.
--
-- how_started: 12 'elected', 3 'appointed' (vacancy fills who
-- continued in the same seat rather than restarting occupancy at their later
-- election win): Chelsea Cook, Javiera Caballero, Sharon A. Davis. Passed through to p_how_started
-- explicitly -- NOT left to seat_officeholder()'s 'elected' default, which
-- would misclassify all three.
--
-- 🔴 FIX ROUND 1 (coordinator, 2026-08-22): the structure migration now
-- creates 3 IDENTICALLY-TITLED 'Council Member, At-Large' offices and 5
-- IDENTICALLY-TITLED 'Commissioner' offices (no numbered seat exists on
-- Durham's ballot -- see CA_0006_durham_structure.sql header). A bare
-- office_id/title join can no longer resolve one person to one office row
-- within either group. This file resolves the ambiguity DETERMINISTICALLY
-- by pairing row_number() over each side's natural key, partitioned by
-- (geo_id, district_type, office_title):
--   * office side:  ORDER BY o.id (each office row's UUID is fixed for good
--                   the moment CA_0006 creates it -- an arbitrary but STABLE
--                   ordering key, never reshuffled by a RE-RUN of these two
--                   migrations). 🔴 This is silent about OUT-OF-BAND
--                   deletion: if an office row is deleted outside CA_0006/
--                   CA_0007 and the top-up in CA_0006 regenerates a
--                   replacement, the replacement gets a NEW UUID, which can
--                   sort into a different rank and shift the rank→person
--                   mapping. For the three at-large seats and the five
--                   Commissioner seats this would NOT produce a wrong
--                   voter-facing roster -- those seats are genuinely
--                   interchangeable, so the wrong PERSON never lands on the
--                   wrong SEAT LABEL. It WOULD, however, fabricate term_end
--                   values on real people's tenure records: re-running the
--                   seating loop with a shifted mapping makes
--                   seat_officeholder() close and reopen terms against the
--                   wrong predecessor, writing an incorrect term_end onto
--                   whoever it now (wrongly) believes vacated the seat.
--   * roster side:  ORDER BY s.ext_id (fixed per person by ROSTERS.md's own
--                   external_id mapping table).
-- Because the structure migration is asserted (by its own post-verify gate)
-- to create EXACTLY 3 At-Large offices and EXACTLY 5 Commissioner offices,
-- and this file's payload guard (below) asserts EXACTLY 3 and 5 roster rows
-- per group, row_number() on each side produces the SAME set of integers
-- 1..N with no gaps and no repeats -- so the join is a bijection: every
-- office gets exactly one politician, every politician gets exactly one
-- office, and re-running is idempotent (the same office UUID always sorts to
-- the same rank, so the same person is matched to the same row every time).
-- If the two counts ever drifted apart, the payload guard below fails loudly
-- instead of silently double-seating one office or leaving another vacant.
-- Every other seat (Mayor, wards, Sheriff, Register of Deeds, Clerk of
-- Superior Court) is a group of size 1, where rank 1 trivially matches rank
-- 1 -- the identical mechanism, just with N=1.
--
-- 🔴 THE MIKE LEE COLLISION: Durham County's Board Chair is stored as
-- full_name = 'Dr. Michael "Mike" Lee' (external_id -3730008), first_name
-- 'Dr. Michael', last_name 'Lee', alternate_names {'Mike'} -- matching this
-- corpus's existing convention of folding a courtesy title into first_name
-- (see 'Dr. Kathleen Lang', 'Dr. Monica Sanchez'). Prod ALREADY contains two
-- distinct, unrelated people: 'Mike Lee' (external_id -400077, US Senator,
-- Utah) and 'Michael V. Lee' (external_id -3710007, NC State Senate District
-- 7, New Hanover County, Republican). Durham's Lee is a third, distinct
-- person (Avalara customer-success manager, former Durham Public Schools
-- Board of Education member, elected countywide 2024, Democrat). Never write
-- 'Michael Lee' or 'Mike Lee' bare for this row -- either string collides
-- with an existing prod row under a lower(full_name) match.
--
-- NAME HANDLING: full_name is ROSTERS.md's exact string, byte-for-byte --
-- never run through NFD/diacritic-stripping. Two names carry embedded double
-- quotes around a nickname (Leonardo "Leo" Williams, Dr. Michael "Mike" Lee).
-- This file is written as UTF-8 without a BOM; the generator verifies the
-- emitted bytes decode correctly for both quoted names before reporting
-- success.
--
-- EXTERNAL IDS: -(3730000+n), n=1..15, per ROSTERS.md's external_id mapping
-- table. Verified collision-free against prod 2026-08-22: zero existing rows
-- in -3730015..-3730001.
--
-- IDEMPOTENCY: politicians uses ON CONFLICT (external_id) DO NOTHING (real
-- unique index, migration 191). All 15 terms go through
-- essentials.seat_officeholder(), which is idempotent and closes any
-- predecessor's term rather than silently overlapping it -- none of these 15
-- seats has an unknown term_start, so no direct office_terms insert is
-- needed (unlike the NC legislature's one unknown-start seat).
--
-- Joins key on (geo_id, district_type) together -- '37063' is NOT unique
-- across Durham County (COUNTY) and NC House District 63 (STATE_LOWER).

BEGIN;

CREATE TEMP TABLE durham_seed (
  geo_id          text,
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

INSERT INTO durham_seed VALUES
    ('3719000', 'LOCAL', 'Mayor', -3730001, 'Leonardo "Leo" Williams', 'Leonardo', 'Williams', NULL, NULL, ARRAY['Leo']::text[], DATE '2023-12-04', 'day', 'elected', 'durhamnc.gov/1329/About-the-Mayor (official mayor bio page, sworn-in date); corroborated by IndyWeek swearing-in coverage (2023-12-04 cohort). Retrieved 2026-08-22.'),
    ('3719000', 'LOCAL', 'Council Member, Ward 1', -3730002, 'Matt Kopac', 'Matt', 'Kopac', NULL, NULL, '{}'::text[], DATE '2025-12-01', 'day', 'elected', 'durhamnc.gov/1396/City-Council-Members (City Clerk''s roster) + durhamnc.gov/5483/Matt-Kopac (member bio); corroborated by IndyWeek ''new-durham-city-council-members-sworn-in'' (2025-12-01 cohort). Retrieved 2026-08-22.'),
    ('3719000', 'LOCAL', 'Council Member, Ward 2', -3730003, 'Shanetta Burris', 'Shanetta', 'Burris', NULL, NULL, '{}'::text[], DATE '2025-12-01', 'day', 'elected', 'durhamnc.gov/1396/City-Council-Members (City Clerk''s roster) + durhamnc.gov/5484/Shanetta-Burris (member bio); corroborated by IndyWeek ''new-durham-city-council-members-sworn-in'' (2025-12-01 cohort). Retrieved 2026-08-22.'),
    ('3719000', 'LOCAL', 'Council Member, Ward 3', -3730004, 'Chelsea Cook', 'Chelsea', 'Cook', NULL, NULL, '{}'::text[], DATE '2024-01-16', 'day', 'appointed', 'WRAL ''chelsea-cook-to-be-appointed-as-newest-durham-city-council-member'' (appointed and sworn in 2024-01-16, same evening) + durhamnc.gov/4664/Chelsea-Cook (member bio); corroborated by IndyWeek ''durham-council-selects-legal-aid-attorney-chelsea-cook-to-fill-vacant-seat''. NOTE: Ballotpedia''s Chelsea_Cook page gives 2024-01-17 (one-day discrepancy) -- WRAL''s contemporaneous, dated, same-evening account is preferred; see ROSTERS.md source-defects section. term_start is her appointment date, not her later 2025 election win. Retrieved 2026-08-22.'),
    ('3719000', 'LOCAL', 'Council Member, At-Large', -3730005, 'Javiera Caballero', 'Javiera', 'Caballero', NULL, NULL, '{}'::text[], DATE '2018-01-16', 'day', 'appointed', 'IndyWeek archives ''javiera-caballero-named-durham-city-council'' (appointed and sworn in 2018-01-16, ~1 hour after the council vote) + durhamnc.gov/3286/Javiera-Caballero (member bio). term_start is her appointment date, not her subsequent 2019+ election wins. Retrieved 2026-08-22.'),
    ('3719000', 'LOCAL', 'Council Member, At-Large', -3730006, 'Nate Baker', 'Nate', 'Baker', NULL, NULL, '{}'::text[], DATE '2023-12-04', 'day', 'elected', 'durhamnc.gov/1396/City-Council-Members (City Clerk''s roster) + durhamnc.gov/4797/Nate-Baker (member bio); corroborated by IndyWeek ''durhams-new-city-council-sworn-in-monday'' (2023-12-04 cohort). Retrieved 2026-08-22.'),
    ('3719000', 'LOCAL', 'Council Member, At-Large', -3730007, 'Carl Rist', 'Carl', 'Rist', NULL, NULL, '{}'::text[], DATE '2023-12-04', 'day', 'elected', 'durhamnc.gov/1396/City-Council-Members (City Clerk''s roster) + durhamnc.gov/1661/Carl-Rist (member bio); corroborated by IndyWeek ''durhams-new-city-council-sworn-in-monday'' (2023-12-04 cohort). Retrieved 2026-08-22.'),
    ('37063', 'COUNTY', 'Commissioner', -3730008, 'Dr. Michael "Mike" Lee', 'Dr. Michael', 'Lee', NULL, NULL, ARRAY['Mike']::text[], DATE '2024-12-02', 'day', 'elected', 'dconc.gov/county-departments/departments-a-e/board-of-commissioners/commissioners (current roster) + dconc.gov .../Mike-Lee (member bio); corroborated by IndyWeek ''new-durham-county-board-of-commissioners-officially-sworn-into-office'' and Spectacular Magazine (2024-12) for the 2024-12-02 swearing-in cohort. NOT the US Senator (external_id -400077, Utah) or NC State Senate District 7''s Michael V. Lee (external_id -3710007, Republican, New Hanover County) -- see ROSTERS.md ''Mike Lee collision'' section. Retrieved 2026-08-22.'),
    ('37063', 'COUNTY', 'Commissioner', -3730009, 'Nida Allam', 'Nida', 'Allam', NULL, NULL, '{}'::text[], DATE '2020-12-07', 'day', 'elected', 'dconc.gov .../Nida-Allam (member bio); corroborated by IndyWeek ''new-durham-county-board-of-commissioners-officially-sworn-into-office'' (confirms Allam retained in the 2024 election). Retrieved 2026-08-22.'),
    ('37063', 'COUNTY', 'Commissioner', -3730010, 'Michelle Burton', 'Michelle', 'Burton', NULL, NULL, '{}'::text[], DATE '2024-12-02', 'day', 'elected', 'dconc.gov/county-departments/departments-a-e/board-of-commissioners/commissioners (current roster); corroborated by IndyWeek ''new-durham-county-board-of-commissioners-officially-sworn-into-office'' (2024-12-02 cohort, newly elected). Retrieved 2026-08-22.'),
    ('37063', 'COUNTY', 'Commissioner', -3730011, 'Stephen J. Valentine', 'Stephen', 'Valentine', 'J.', NULL, '{}'::text[], DATE '2024-12-02', 'day', 'elected', 'dconc.gov .../Stephen-Valentine (member bio); corroborated by IndyWeek ''new-durham-county-board-of-commissioners-officially-sworn-into-office'' (2024-12-02 cohort, newly elected). Retrieved 2026-08-22.'),
    ('37063', 'COUNTY', 'Commissioner', -3730012, 'Wendy Jacobs', 'Wendy', 'Jacobs', NULL, NULL, '{}'::text[], DATE '2012-01-01', 'year', 'elected', 'dconc.gov current commissioners roster + IndyWeek/Spectacular Magazine (confirms Jacobs retained through 2024). Original 2012 seating day is genuinely unrecoverable: primary-source minutes bracket it between 2012-11-29 (still Commissioner-Elect) and 2012-12-10 (seated), and N.C.G.S. Sec. 153A-26 suggests but does not attest 2012-12-03 -- per coordinator instruction this stays at year precision rather than upgrading on the statute alone. See ROSTERS.md ''source defects'' section for the full account. Retrieved 2026-08-22.'),
    ('37063', 'COUNTY', 'Sheriff', -3730013, 'Clarence F. Birkhead', 'Clarence', 'Birkhead', 'F.', NULL, '{}'::text[], DATE '2018-12-03', 'day', 'elected', 'durhamsheriff.com/about-us/welcome/sheriff-s-bio + Spectrum News ''new-durham-county-sheriff-takes-oath-of-office'' (sworn in 2018-12-03, first African-American sheriff of Durham County). Retrieved 2026-08-22.'),
    ('37063', 'COUNTY', 'Register of Deeds', -3730014, 'Sharon A. Davis', 'Sharon', 'Davis', 'A.', NULL, '{}'::text[], DATE '2016-06-01', 'day', 'appointed', 'rodweb.dconc.gov/web/ (Register of Deeds'' own office site) + ncard.us/find-your-register-of-deeds/durham-county/ (NC Association of Registers of Deeds); independently confirmed by branch.vote''s 2024 candidate page and Ballotpedia Sharon_Davis (appointed 2016-06-01 to fill a vacancy, elected Nov 2016, re-elected 2024 unopposed). term_start is her appointment date, not any of her three subsequent election wins. Retrieved 2026-08-22.'),
    ('37063', 'COUNTY', 'Clerk of Superior Court', -3730015, 'Aminah M. Thompson', 'Aminah', 'Thompson', 'M.', NULL, '{}'::text[], DATE '2022-12-05', 'day', 'elected', 'dconc.gov/Clerk-of-the-Superior-Court (county''s own site); independently confirmed by Ballotpedia Aminah_Thompson (aggregating NCSBE results) and IndyWeek ''durham-county-clerk-of-superior-court-aminah-thompson-2026'' (elected 2022-11-08 defeating 20-year incumbent Archie Smith III, assumed office 2022-12-05). Retrieved 2026-08-22.');

-- Guard the payload itself before it touches anything. Duplicate office_title
-- within (geo_id, district_type) is now EXPECTED for the two multi-seat
-- groups (3x 'Council Member, At-Large', 5x 'Commissioner'), so the guard
-- checks per-group COUNTS against the exact expectation instead of rejecting
-- any duplicate -- a plain duplicate-key check would wrongly fail on these
-- two legitimate groups.
DO $$
DECLARE v_n int; v_dup int; v_grp int;
BEGIN
  SELECT count(*) INTO v_n FROM durham_seed;
  IF v_n <> 15 THEN RAISE EXCEPTION 'seed payload: expected 15 rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM durham_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;

  SELECT count(*) INTO v_grp FROM durham_seed
   WHERE geo_id = '3719000' AND district_type = 'LOCAL' AND office_title = 'Council Member, At-Large';
  IF v_grp <> 3 THEN RAISE EXCEPTION 'seed payload: expected 3 ''Council Member, At-Large'' rows, got %', v_grp; END IF;

  SELECT count(*) INTO v_grp FROM durham_seed
   WHERE geo_id = '37063' AND district_type = 'COUNTY' AND office_title = 'Commissioner';
  IF v_grp <> 5 THEN RAISE EXCEPTION 'seed payload: expected 5 ''Commissioner'' rows, got %', v_grp; END IF;

  -- Every OTHER (geo_id, district_type, office_title) combination must be
  -- unique -- these are the genuinely single-seat titles (Mayor, wards,
  -- Sheriff, Register of Deeds, Clerk of Superior Court).
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, district_type, office_title FROM durham_seed
    WHERE office_title NOT IN ('Council Member, At-Large', 'Commissioner')
    GROUP BY geo_id, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % unexpected duplicate single-seat (geo_id, district_type, office_title) key(s)', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_initial, s.name_suffix,
       s.aliases, true, true, s.source
FROM durham_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy, via the helper ───────────────────────────────────────────────
-- seat_officeholder() closes any predecessor's open-ended term before
-- inserting, which is the whole reason it exists. All 15 rows carry a real
-- term_start (Jacobs' is year-precision, not NULL), so every row goes through
-- this loop -- no direct office_terms insert is needed for this file.
--
-- office_rank/seed_rank: deterministic row_number() pairing within each
-- (geo_id, district_type, office_title) group -- see file header for the
-- bijection argument. For every size-1 group this degenerates to "the one
-- office matches the one roster row", identical in effect to a plain title
-- join.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    WITH office_rank AS (
      SELECT o.id AS office_id, d.geo_id, d.district_type, o.title,
             row_number() OVER (
               PARTITION BY d.geo_id, d.district_type, o.title ORDER BY o.id
             ) AS rn
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      WHERE (d.geo_id = '3719000' AND d.district_type = 'LOCAL')
         OR (d.geo_id = '37063' AND d.district_type = 'COUNTY')
    ),
    seed_rank AS (
      SELECT s.*,
             row_number() OVER (
               PARTITION BY s.geo_id, s.district_type, s.office_title ORDER BY s.ext_id
             ) AS rn
      FROM durham_seed s
    )
    SELECT sr.term_start, sr.start_precision, sr.how_started, sr.source,
           orr.office_id, p.id AS politician_id
    FROM seed_rank sr
    JOIN office_rank orr
      ON orr.geo_id = sr.geo_id
     AND orr.district_type = sr.district_type
     AND orr.title = sr.office_title
     AND orr.rn = sr.rn
    JOIN essentials.politicians p ON p.external_id = sr.ext_id
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = orr.office_id AND t.politician_id = p.id
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
  RAISE NOTICE 'seated % Durham official(s)', v_seated;
END $$;

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  v_pol int; v_seated int; v_appointed int; v_homonym int;
BEGIN
  SELECT count(*) INTO v_pol
  FROM essentials.politicians WHERE external_id BETWEEN -3730015 AND -3730001;
  IF v_pol <> 15 THEN RAISE EXCEPTION 'CA_0007: Durham officials inserted: expected 15, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id, never an absent row.
  -- count(*) would pass vacuously with every seat empty.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE (d.geo_id = '3719000' AND d.district_type = 'LOCAL')
      OR (d.geo_id = '37063' AND d.district_type = 'COUNTY');
  IF v_seated <> 15 THEN RAISE EXCEPTION 'CA_0007: expected 15 seated Durham officials, found %', v_seated; END IF;

  SELECT count(*) INTO v_appointed
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE ((d.geo_id = '3719000' AND d.district_type = 'LOCAL')
          OR (d.geo_id = '37063' AND d.district_type = 'COUNTY'))
     AND t.how_started = 'appointed';
  IF v_appointed <> 3 THEN RAISE EXCEPTION 'CA_0007: expected 3 Durham terms with how_started=appointed, found %', v_appointed; END IF;

  -- 🔴 Cross-state homonym assertion: no politician seated on a Durham office
  -- may simultaneously hold an office whose district state is not 'nc'. This
  -- is the check that would catch a Utah senator or a New Hanover state
  -- senator landing on the Durham County Commission via a bad name match.
  SELECT count(*) INTO v_homonym
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och1 ON och1.politician_id = p.id
    JOIN essentials.offices o1 ON o1.id = och1.office_id
    JOIN essentials.districts d1 ON d1.id = o1.district_id
    JOIN essentials.office_current_holder och2 ON och2.politician_id = p.id AND och2.office_id <> och1.office_id
    JOIN essentials.offices o2 ON o2.id = och2.office_id
    JOIN essentials.districts d2 ON d2.id = o2.district_id
   WHERE ((d1.geo_id = '3719000' AND d1.district_type = 'LOCAL')
          OR (d1.geo_id = '37063' AND d1.district_type = 'COUNTY'))
     AND lower(d2.state) <> 'nc';
  IF v_homonym <> 0 THEN
    RAISE EXCEPTION 'CA_0007: % politician(s) seated on a Durham office also hold an office outside NC — cross-state homonym collision', v_homonym;
  END IF;
END $$;

COMMIT;
