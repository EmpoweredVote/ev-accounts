-- CC_0280_jefferson_fremont_county_co_officials.sql
--
-- Seeds the elected officials of JEFFERSON and FREMONT counties, Colorado.
--
--   governments 2 · chambers 4 · offices 18 · people created 15 · people SEATED from an
--   existing row 3 · office_terms 18
--
-- These two counties were found by the candidate->person programme, not by an occupancy audit:
-- `CC_0276` had to create fresh person rows for the Jefferson County Clerk and Recorder, a
-- Jefferson County Commissioner and a Fremont County Commissioner, because we held no row for
-- any of them. That migration's header predicted this one: *"if those counties are seeded later,
-- THESE are the people to seat, not rows to duplicate."* This is that migration, and it seats
-- exactly those three rows.
--
-- ⚠ THE COUNTY DISTRICTS AND THEIR POLYGONS ALREADY EXISTED. All 64 Colorado counties are in
-- `districts` with boundaries. What was missing was OFFICES and HOLDERS — `Jefferson County`
-- (`08059`) and `Fremont County` (`08043`) each carried **zero** offices, so every address in
-- either county returned no county government at all. The earlier note that we "seed no Jefferson
-- County" was imprecise; nothing had to be created geographically.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ 🔴🔴 THE COMMISSIONERS ARE ELECTED AT LARGE, SO THEY HANG OFF THE COUNTY DISTRICT ═══
--
-- Both counties publish it plainly. Jefferson County's Leadership page: *"three commissioners
-- elected **at-large** to four-year staggered terms"*, and its Meet the Commissioners page:
-- *"They are elected at large to four year terms."* Fremont's three seats are the same shape.
-- District 1 / 2 / 3 are **RESIDENCY** districts: a commissioner must live in theirs, and every
-- voter in the county votes in all three contests.
--
-- ▶ So all three Commissioner offices are attached to the **county-wide district**, and an
-- address anywhere in the county returns **all three** commissioners — which is the truth about
-- who represents that voter and whom they elect.
--
-- 🔴 THIS DELIBERATELY DIFFERS FROM EL PASO COUNTY, THE ONLY OTHER CO COUNTY WE HOLD.
-- El Paso's five commissioners each sit on their own sub-district (`mtfcc X0033`) with its own
-- polygon, so an El Paso address returns ONE commissioner. El Paso has five commissioners rather
-- than three — a different statutory class — and may genuinely use district-only voting.
-- ⚠ **THIS MIGRATION DOES NOT TOUCH EL PASO.** Operator decision 2026-10-20: model these two
-- counties on what their own charters and websites say, and raise El Paso as a question rather
-- than unifying the two shapes by fiat. That is the standing ruling on classification
-- (Cantrell 2026-09-05): *understand and describe the distinction, do not make them uniform.*
-- ▶ OPEN QUESTION recorded in `backend/data/seed-co-counties-2026/ROSTERS.md`: is El Paso County
-- district-elected, or is its sub-district model wrong? One sentence from the El Paso Clerk
-- settles it. **Do not "fix" either county until that is answered.**
--
-- ═══ 🔴 TWO FREMONT SEATS ARE DELIBERATELY NOT CREATED ═══
-- Fremont County lists both in its elected-officials menu and neither can be sourced:
--   * **Surveyor** — the county's Surveyor page describes the duties and **names nobody**, and
--     its contact page 404s.
--   * **District Attorney, 11th Judicial District** — the recent history is unsettled (Linda
--     Stanley was disbarred; Jeff Lindsey was appointed Acting DA in November 2024) and the
--     district's own site is unreachable.
-- ▶ Operator decision 2026-10-20: **create neither.** An office with no holder is invisible to
-- voters anyway, and it would raise `offices_missing_terms` above its watched 239 baseline for
-- no gain. Both are named in ROSTERS.md with the document that would settle them.
-- 🔴 Jefferson's Surveyor and District Attorney ARE created — the county's own Leadership page
-- names Robert Hennessy and Alexis King.
--
-- ═══ DATES: WHAT THE COUNTIES THEMSELVES STATE, AND NOTHING MORE ═══
-- 🔴 `term_start` is the start of CONTINUOUS OCCUPANCY of the seat, never the start of the
-- current term — a re-election does not open a new row. So a published "Current Term: 2025-2029"
-- is only the answer when it is the person's FIRST term.
--   * **Andy Kerr** — county: "Current Term: 2025-2029" **and** "elected to his SECOND four-year
--     term in November of 2024" ⇒ first term began 2021. Dating him 2025 would have been wrong.
--   * **Lesley Dahlkemper** — county: "Current Term: 2023 - 2027", "elected to her second,
--     four-year term in November 2022" ⇒ 2019. 🟢 Independently corroborated: KUNC, 2026-07-23,
--     describes "her seven-year career as county commissioner" (2026 − 7 = 2019).
--   * **Rachel Zenzinger** — "Term: 2025-2029" with no second-term language ⇒ 2025.
--   * **Kevin Grantham** — Colorado Politics 2026-10-02: "in his second term as a Fremont County
--     commissioner"; he was Senate President through 2018 ⇒ first commissioner term began 2019.
--   * **Debbie Bell** — county: "took office in January 2011" ⇒ month precision, the only one.
--   * **Dwayne McFall** — county: "elected ... in 2016 and 2020" ⇒ took office January 2017.
--     ⚠ That bio is STALE about his elections — it lists only two, yet he is sitting in 2026, so
--     there is a third win it does not mention. It is still good evidence of when he STARTED.
--     Authoritative for one field, stale for another.
--   * **Amanda Gonzalez** 2023 (won the seat in 2022) · **Jerry DiTullio** 2019 ("has served as
--     Jefferson County Treasurer since 2019") · **Justin D Grantham** 2019 ("since 2019").
-- 🔴 THE OTHER NINE GET `start_precision => 'unknown'` WITH A NULL `term_start`. No county page
-- states when they took office, and CLAUDE.md is explicit: write an open-ended term with
-- 'unknown' rather than a guess. ⚠ Ballotpedia was NOT used to fill them: its "Amanda Gonzalez"
-- page is a disambiguation, and a third-party page reached by name match is exactly how the
-- wrong person gets dated.
--
-- ═══ 🟢 THE ROSTER WAS PROVED CURRENT, NOT ASSUMED ═══
-- A county bio page says who held a seat when it was written. Fremont's commissioner bios looked
-- stale — McFall's claims elections only through 2020, which would have ended in January 2025 —
-- so the board was checked against a DATED PRIMARY DOCUMENT instead: the Fremont County BOCC
-- minutes of **22 September 2026** ("TWENTIETH MEETING"), whose roll call reads
-- *Debbie Bell — Commissioner; Dwayne McFall — Commissioner; Kevin Grantham — Commissioner;
-- Justin Grantham — Clerk and Recorder.* All three commissioners and the clerk are sitting now.
--
-- ═══ SEATING THREE EXISTING PEOPLE, NOT CREATING THEM ═══
--   Amanda Gonzalez  `7b61bc5e` -> Jefferson County Clerk and Recorder
--   Lesley Dahlkemper `0a783864` -> Jefferson County Commissioner, District 3
--   Kevin Grantham   `bc6296a0` -> Fremont County Commissioner, District 1
-- All three were created by `CC_0276` as 2026 statewide candidates with no office. Each identity
-- is confirmed by a document tying the statewide candidacy to the county seat: Weiser's running-
-- mate announcement names "Jeffco Commissioner Lesley Dahlkemper"; CPR and Colorado Politics name
-- the Secretary of State nominee as the Jefferson County Clerk; Colorado Politics names the
-- Treasurer nominee as a sitting Fremont County commissioner.
-- 🔴 **`seat_officeholder` DOES NOT TOUCH `is_incumbent`** — checked, it is not in the function
-- body. All three carry `is_incumbent = false` from CC_0276, and a seated person left false is
-- HIDDEN from the incumbents-only reads. This migration flips them explicitly.
--
-- 🔴 NO SEAT HERE IS ALREADY OCCUPIED. Every office in this migration is created by this
-- migration, so `seat_officeholder` cannot close a predecessor's term — the CC_0271 trap needs an
-- occupied seat and there are none. A post-verify gate asserts one term per office.
--
-- ⚠ SAFE TO RE-RUN: every insert is guarded by NOT EXISTS on a natural key and
-- `seat_officeholder` is idempotent for the same (office, person). Unlike this programme's
-- creation migrations, this one really is a no-op on a second run rather than an abort.

BEGIN;

-- ─── 1. Governments ──────────────────────────────────────────────────────────────────────
-- 🔴 geo_id + mtfcc must MATCH the county district's pair. The essentials landing page keys a
-- place chip on `governments.geo_id`, which address search never touches, so a mismatched pair
-- leaves a fully seeded county unreachable from the main page.
INSERT INTO essentials.governments (name, type, state, geo_id, mtfcc)
SELECT v.name, 'County', 'CO', v.geo_id, 'G4020'
FROM (VALUES ('Jefferson County, Colorado, US','08059'),
             ('Fremont County, Colorado, US','08043')) AS v(name, geo_id)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments g
   WHERE g.geo_id = v.geo_id AND g.mtfcc = 'G4020' AND g.state = 'CO');

-- ─── 2. Chambers: the countywide officials, and the board ────────────────────────────────
INSERT INTO essentials.chambers (government_id, name, name_formal, term_length, policy_engagement_level)
SELECT g.id, v.ch, v.formal, '4', 'full'
FROM (VALUES
  ('08059','Countywide Elected Officials','Jefferson County Elected Officials'),
  ('08059','Board of County Commissioners','Jefferson County Board of County Commissioners'),
  ('08043','Countywide Elected Officials','Fremont County Elected Officials'),
  ('08043','Board of County Commissioners','Fremont County Board of County Commissioners')
) AS v(geo_id, ch, formal)
JOIN essentials.governments g ON g.geo_id = v.geo_id AND g.mtfcc = 'G4020' AND g.state = 'CO'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.ch);

-- ─── 3. The roster ───────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _roster (
  county_geo   text NOT NULL,
  chamber      text NOT NULL,
  title        text NOT NULL,
  descr        text,
  full_name    text NOT NULL,
  first_name   text NOT NULL,
  last_name    text NOT NULL,
  term_start   date,
  precision    text NOT NULL,
  src          text NOT NULL,
  office_id    uuid,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO _roster (county_geo, chamber, title, descr, full_name, first_name, last_name, term_start, precision, src) VALUES
-- ── Jefferson County ──
('08059','Board of County Commissioners','Commissioner, District 1',
 'One of three Jefferson County commissioners. Elected AT LARGE by every voter in the county to a four-year term; District 1 is a residency district, not a separate electorate.',
 'Rachel Zenzinger','Rachel','Zenzinger','2025-01-01','year',
 'jeffco.us/2078/Leadership and jeffco.us/4876 ("Term: 2025-2029"), read 2026-10-20 (CC_0280)'),
('08059','Board of County Commissioners','Commissioner, District 2',
 'One of three Jefferson County commissioners. Elected AT LARGE by every voter in the county to a four-year term; District 2 is a residency district, not a separate electorate.',
 'Andy Kerr','Andy','Kerr','2021-01-01','year',
 'jeffco.us/4228 — "Current Term: 2025-2029" and "elected to his second four-year term in November of 2024", so continuous occupancy began 2021, read 2026-10-20 (CC_0280)'),
('08059','Board of County Commissioners','Commissioner, District 3',
 'One of three Jefferson County commissioners. Elected AT LARGE by every voter in the county to a four-year term; District 3 is a residency district, not a separate electorate.',
 'Lesley Dahlkemper','Lesley','Dahlkemper','2019-01-01','year',
 'jeffco.us/2099 — "Current Term: 2023 - 2027", "elected to her second, four-year term in November 2022"; corroborated by KUNC 2026-07-23 "her seven-year career as county commissioner", read 2026-10-20 (CC_0280)'),
('08059','Countywide Elected Officials','Assessor', NULL,
 'Scot Kersgaard','Scot','Kersgaard',NULL,'unknown',
 'jeffco.us/2078/Leadership, read 2026-10-20; no start date published (CC_0280)'),
('08059','Countywide Elected Officials','Clerk and Recorder',
 'Chief election official of the county; also records land records and acts as clerk to the Board of County Commissioners.',
 'Amanda Gonzalez','Amanda','Gonzalez','2023-01-01','year',
 'jeffco.us/2078/Leadership, read 2026-10-20; won the seat in 2022 per CPR 2025-01-06 (CC_0280)'),
('08059','Countywide Elected Officials','Coroner', NULL,
 'Annette Cannon','Annette','Cannon',NULL,'unknown',
 'jeffco.us/2078/Leadership, read 2026-10-20; no start date published (CC_0280)'),
('08059','Countywide Elected Officials','Sheriff', NULL,
 'Regina "Reggie" Marinelli','Regina','Marinelli',NULL,'unknown',
 'jeffco.us/2078/Leadership, read 2026-10-20; no start date published (CC_0280)'),
('08059','Countywide Elected Officials','Surveyor',
 'Represents the county in boundary disputes and notifies the county attorney of unsettled boundary discrepancies.',
 'Robert Hennessy','Robert','Hennessy',NULL,'unknown',
 'jeffco.us/2078/Leadership, read 2026-10-20; no start date published (CC_0280)'),
('08059','Countywide Elected Officials','Treasurer and Public Trustee',
 'Collects property taxes and holds county funds. As of 1 July 2020 the Treasurer also serves as the county Public Trustee, so this is one elected seat and not two.',
 'Jerry DiTullio','Jerry','DiTullio','2019-01-01','year',
 'jeffco.us/809/Treasurer — "Jerry DiTullio has served as Jefferson County Treasurer since 2019", read 2026-10-20 (CC_0280)'),
('08059','Countywide Elected Officials','District Attorney',
 'District Attorney for Colorado''s First Judicial District, which covers Jefferson County AND Gilpin County. The seat is elected by the whole judicial district, so Gilpin voters elect this office too.',
 'Alexis King','Alexis','King',NULL,'unknown',
 'jeffco.us/2078/Leadership, read 2026-10-20; no start date published (CC_0280)'),
-- ── Fremont County ──
('08043','Board of County Commissioners','Commissioner, District 1',
 'One of three Fremont County commissioners. Elected AT LARGE by every voter in the county to a four-year term; District 1 is a residency district, not a separate electorate.',
 'Kevin Grantham','Kevin','Grantham','2019-01-01','year',
 'fremontcountyco.gov/commissioners/meet-commissioners and the BOCC minutes of 2026-09-22; Colorado Politics 2026-10-02 "in his second term as a Fremont County commissioner" and he was Senate President through 2018, so occupancy began 2019 (CC_0280)'),
('08043','Board of County Commissioners','Commissioner, District 2',
 'One of three Fremont County commissioners. Elected AT LARGE by every voter in the county to a four-year term; District 2 is a residency district, not a separate electorate.',
 'Debbie Bell','Debbie','Bell','2011-01-01','month',
 'fremontcountyco.gov/commissioners/meet-commissioners — "Debbie Bell took office in January 2011"; sitting per the BOCC minutes of 2026-09-22 (CC_0280)'),
('08043','Board of County Commissioners','Commissioner, District 3',
 'One of three Fremont County commissioners. Elected AT LARGE by every voter in the county to a four-year term; District 3 is a residency district, not a separate electorate.',
 'Dwayne McFall','Dwayne','McFall','2017-01-01','year',
 'fremontcountyco.gov/commissioners/meet-commissioners — "elected to be the Commissioner for District 3 in 2016 and 2020", so he took office January 2017; that bio is stale about his later elections but he is sitting per the BOCC minutes of 2026-09-22 (CC_0280)'),
('08043','Countywide Elected Officials','Assessor', NULL,
 'Stacey Seifert','Stacey','Seifert',NULL,'unknown',
 'fremontcountyco.gov/assessor/assessor, read 2026-10-20; no start date published (CC_0280)'),
('08043','Countywide Elected Officials','Clerk and Recorder',
 'Chief election official of the county; also records land records and acts as an agent of the state for motor vehicle transactions.',
 'Justin D Grantham','Justin D','Grantham','2019-01-01','year',
 'fremontcountyclerkco.gov — "has proudly served Fremont County as Clerk and Recorder since 2019"; present in the BOCC minutes of 2026-09-22 (CC_0280)'),
('08043','Countywide Elected Officials','Coroner', NULL,
 'Randy Keller','Randy','Keller',NULL,'unknown',
 'fremontcountyco.gov/coroner/coroner, read 2026-10-20; no start date published (CC_0280)'),
('08043','Countywide Elected Officials','Sheriff', NULL,
 'Allen Cooper','Allen','Cooper',NULL,'unknown',
 'fremontsheriff.org, read 2026-10-20; no start date published (CC_0280)'),
('08043','Countywide Elected Officials','Treasurer and Public Trustee',
 'Collects property taxes and holds county funds. The county''s Public Trustee page names the Treasurer in that role, so this is one elected seat and not two.',
 'Kathy Elliott','Kathy','Elliott',NULL,'unknown',
 'fremontcountyco.gov/treasurer/fremont-county-treasurer and /treasurer/public-trustee, read 2026-10-20; no start date published (CC_0280)');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM _roster;
  IF n <> 18 THEN RAISE EXCEPTION 'CC_0280: expected 18 roster rows, found %', n; END IF;
  SELECT count(*) INTO n FROM _roster WHERE precision = 'unknown' AND term_start IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0280: % row(s) claim an unknown start AND a date', n; END IF;
  SELECT count(*) INTO n FROM _roster WHERE precision <> 'unknown' AND term_start IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0280: % row(s) have a precision but no date', n; END IF;
END $$;

-- ─── 4. Offices, on the county-wide district ─────────────────────────────────────────────
INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state,
                                seats, is_appointed_position, is_vacant, voting_powers)
SELECT c.id, d.id, r.title, r.descr, 'CO', 1, false, false, 'full'
FROM _roster r
JOIN essentials.districts d
  ON d.geo_id = r.county_geo AND d.mtfcc = 'G4020' AND lower(d.state) = 'co'
JOIN essentials.governments g
  ON g.geo_id = r.county_geo AND g.mtfcc = 'G4020' AND g.state = 'CO'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = r.chamber
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = r.title);

UPDATE _roster r SET office_id = o.id
FROM essentials.districts d, essentials.offices o
WHERE d.geo_id = r.county_geo AND d.mtfcc = 'G4020' AND lower(d.state) = 'co'
  AND o.district_id = d.id AND o.title = r.title;

-- ─── 5. People ───────────────────────────────────────────────────────────────────────────
-- Three already exist, created by CC_0276 as 2026 statewide candidates. Match them by the
-- (first_name, last_name) key the duplicate guard itself uses, so anything this misses is
-- something the guard would have refused anyway.
UPDATE _roster r SET politician_id = p.id
FROM essentials.politicians p
WHERE p.is_active
  AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
  AND lower(btrim(p.last_name))  = lower(btrim(r.last_name));

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM _roster WHERE politician_id IS NOT NULL;
  IF n <> 3 THEN
    RAISE EXCEPTION 'CC_0280: expected exactly 3 existing people (Gonzalez, Dahlkemper, '
                    'Grantham from CC_0276), matched % - read every extra before inserting', n;
  END IF;
  SELECT count(*) INTO n FROM _roster r
   WHERE r.politician_id IS NOT NULL
     AND r.full_name NOT IN ('Amanda Gonzalez','Lesley Dahlkemper','Kevin Grantham');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0280: an unexpected name matched an existing person'; END IF;
END $$;

-- 🔴 is_incumbent TRUE: these people hold the seat. It is a cached flag the incumbents-only
-- reads filter on, and it defaults to false since CA_0188, so a seated person left false is
-- hidden from address search.
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.src
FROM _roster r WHERE r.politician_id IS NULL;

UPDATE _roster r SET politician_id = p.id
FROM essentials.politicians p
WHERE r.politician_id IS NULL AND p.is_active
  AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
  AND lower(btrim(p.last_name))  = lower(btrim(r.last_name));

-- 🔴 the three CC_0276 rows were created is_incumbent=false (correctly, as candidates holding
-- nothing). They hold a seat as of this migration. seat_officeholder will NOT do this.
UPDATE essentials.politicians p SET is_incumbent = true
FROM _roster r WHERE p.id = r.politician_id AND p.is_incumbent IS DISTINCT FROM true;

-- ─── 6. Seat everyone ────────────────────────────────────────────────────────────────────
-- 🔴 `seat_officeholder` REFUSES A NULL `term_start` — it raises "requires a real term_start",
-- by design, so that a year-only source is written as Jan 1 + 'year' rather than discarded. It
-- therefore cannot write the open-ended 'unknown' term CLAUDE.md prescribes for a start that is
-- genuinely unrecorded. The nine undated seats take the helper's own INSERT, verbatim:
-- (office_id, politician_id, term_start, start_precision, how_started, source) is the complete
-- column list in its body, and it syncs nothing else. That is safe here only because every one
-- of these offices is created by this migration and has no predecessor to close.
-- ⚠ Those nine also get `how_started = 'unknown'`. We know they are elected officials; we do
-- NOT know whether this particular tenure began by election or by appointment to a vacancy, and
-- 'elected' would assert the thing we could not check.
DO $$
DECLARE r record; n_helper int := 0; n_direct int := 0;
BEGIN
  FOR r IN SELECT * FROM _roster ORDER BY county_geo, title LOOP
    IF r.office_id IS NULL OR r.politician_id IS NULL THEN
      RAISE EXCEPTION 'CC_0280: % / % did not resolve to an office and a person', r.county_geo, r.title;
    END IF;

    IF r.term_start IS NOT NULL THEN
      PERFORM essentials.seat_officeholder(
        r.office_id, r.politician_id, r.term_start, r.src, 'elected'::text, r.precision::text);
      n_helper := n_helper + 1;
    ELSE
      IF NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = r.office_id
                        AND t.politician_id IS NOT DISTINCT FROM r.politician_id) THEN
        INSERT INTO essentials.office_terms
          (office_id, politician_id, term_start, start_precision, how_started, source)
        VALUES (r.office_id, r.politician_id, NULL, 'unknown', 'unknown', r.src);
      END IF;
      n_direct := n_direct + 1;
    END IF;
  END LOOP;

  IF n_helper <> 9 OR n_direct <> 9 THEN
    RAISE EXCEPTION 'CC_0280: expected 9 dated seats and 9 undated, got % and %', n_helper, n_direct;
  END IF;
END $$;

-- ─── 7. Post-verify ──────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; n_jeff int; n_frem int; bad int;
BEGIN
  -- one term per office, and every office seated
  SELECT count(*) INTO n FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id AND t.politician_id = r.politician_id;
  IF n <> 18 THEN RAISE EXCEPTION 'CC_0280: expected 18 terms, found %', n; END IF;

  SELECT count(*) INTO bad FROM (
    SELECT r.office_id FROM _roster r
      JOIN essentials.office_terms t ON t.office_id = r.office_id
     GROUP BY r.office_id HAVING count(*) > 1) q;
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0280: % office(s) carry more than one term - seat_officeholder closed a '
                    'predecessor, which means a seat was already occupied', bad;
  END IF;

  -- every seated person is flagged incumbent, or address search hides them
  SELECT count(*) INTO bad FROM _roster r JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0280: % seated person(s) are not active incumbents', bad; END IF;

  -- the view resolves, office-rooted, for both counties
  SELECT count(*) INTO n_jeff FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '08059' AND d.mtfcc = 'G4020' AND och.politician_id IS NOT NULL;
  IF n_jeff <> 10 THEN RAISE EXCEPTION 'CC_0280: Jefferson should resolve 10 holders, found %', n_jeff; END IF;

  SELECT count(*) INTO n_frem FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '08043' AND d.mtfcc = 'G4020' AND och.politician_id IS NOT NULL;
  IF n_frem <> 8 THEN RAISE EXCEPTION 'CC_0280: Fremont should resolve 8 holders, found %', n_frem; END IF;

  -- 🔴 the whole point of the at-large model: THREE commissioners on the county district
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id IN ('08059','08043') AND d.mtfcc = 'G4020' AND o.title LIKE 'Commissioner,%';
  IF bad <> 6 THEN
    RAISE EXCEPTION 'CC_0280: expected 6 commissioner offices on the two COUNTY districts, found '
                    '% - commissioners here are elected at large and must not sit on sub-districts', bad;
  END IF;

  -- the two deliberately-skipped Fremont seats must not have been created
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '08043' AND d.mtfcc = 'G4020' AND o.title IN ('Surveyor','District Attorney');
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0280: Fremont Surveyor/District Attorney were created, but neither holder '
                    'could be sourced - see ROSTERS.md';
  END IF;

  RAISE NOTICE 'CC_0280 OK - Jefferson 10 seats, Fremont 8 seats, 18 terms, 3 CC_0276 people seated';
END $$;

DROP TABLE _roster;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: THE ELECTORATE IS PART OF THE OFFICE, AND IT IS NOT INFERABLE FROM A PEER.
-- The only Colorado county we already held put each commissioner on their own polygon, which
-- would have been the obvious thing to copy. Both of these counties say in their own words that
-- their commissioners are elected AT LARGE, with the numbered districts serving only as residency
-- requirements. Copying the peer would have told a Jefferson County voter they have one
-- commissioner when they elect, and are represented by, all three.
-- ▶ Read the jurisdiction's own description of HOW the seat is filled before choosing the shape.
-- 🟢 AND THE LOOP CLOSED: three of these officeholders already existed as person rows, created
-- six migrations ago as statewide candidates with no office. Seating them rather than creating
-- them is the whole reason CC_0276 wrote down who they were.
-- ───────────────────────────────────────────────────────────────────────────────────────────
