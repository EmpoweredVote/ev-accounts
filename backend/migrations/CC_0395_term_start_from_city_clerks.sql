-- CC_0395 — replace CC_0394's under-claimed term starts with what the city clerks actually record.
--
-- CC_0394 carried 290 term starts off the deprecated politicians.valid_from snapshot. Where the
-- record's STATED precision and the value's SHAPE disagreed, it took the coarser of the two and
-- truncated the date, because over-claiming tells a voter something false while under-claiming
-- only tells them less. 18 rows paid that price: a real day sat in the data and shipped as a month.
-- This migration goes to each city's own clerk and settles all 18.
--
-- ⚠ Every one of the 18 is reached through its own body's MINUTES, not a roster, a press report or
--   a bio page. Two of those near-misses are worth naming, because each would have been wrong:
--     · Frisco's own "Mayor Mark Hill" bio gives "Elected: 2026" and no oath date at all.
--     · Cambridge's city-news item announced the inauguration in advance. An announcement says a
--       ceremony was SCHEDULED, not that anyone took an oath.
--
-- ============================================================================================
-- WHAT IT OVERWRITES  (no history table, no schema_migrations — the header is the only record)
-- ============================================================================================
--   17 rows: term_start <truncated 1st-of-month> -> the clerk's date; start_precision month -> day
--    1 row : term_start 2026-06-01 -> NULL;        start_precision month -> unknown
--   source is APPENDED to on every row, never replaced.
--
-- ============================================================================================
-- 🔴 ALLEN TX WAS NOT UNDER-CLAIMED. IT WAS WRONG.
-- ============================================================================================
-- The snapshot gave Mayor Chris Schulmeister 2026-05-03 — the day after the 2 May general
-- election, and a SUNDAY. He was sworn in on 2026-05-26, after the 13 May canvass.
-- ▶ CC_0394 stored that as 2026-05-01 with month precision, which rendered "May 2026" — TRUE BY
--   ACCIDENT, because the wrong day and the right day fall in the same month. Had CC_0394 trusted
--   the day the way the shape alone suggested, it would have published a Sunday as the date this
--   mayor took office. That is the asymmetry rule earning its keep, and it is the reason this
--   file exists rather than a one-line "upgrade month to day" pass.
--
-- ============================================================================================
-- 🔴 PRINCETON TX GOES BACK TO UNDATED. A CANVASS IS NOT A SEATING.
-- ============================================================================================
-- The snapshot gave Jaisen Rutledge (Place 4) 2026-06-23. The City of Princeton's minutes for
-- 23 June 2026 (attested by City Secretary Amber Anderson) show that date is the CANVASS:
-- Ordinance No. 2026-06-23 canvassed the 13 June runoff for Council Member Seat 4. The same
-- minutes carry NO oath of office, never name Rutledge, and record every motion that night as
-- 5-0 — the council sitting one member short with Place 4 still empty.
-- He appears as "Councilmember Jaisen Rutledge", present, in the 13 July 2026 work session and
-- regular meeting, with no oath item in either. So he was sworn in privately somewhere between
-- 24 June and 13 July, and NO city record published the day.
-- ▶ That straddles two months, so neither "June 2026" nor "July 2026" is safely true, and the
--   stored June value could be false. The honest state is the one he was in before CC_0394:
--   undated, which the read path already emits as an empty string. This row is not a failure of
--   the backfill; it is the backfill's premise failing for one row, and being put back.
-- 🔴 It is NOT tagged '| unverified' — that tag makes office_holders_as_of skip the term and would
--    delete a sitting councilmember from every historical query. He holds the seat. Only the date
--    is unknown, which is exactly what term_start NULL means.
--
-- ============================================================================================
-- SOURCES, one per city, each the body's own minutes
-- ============================================================================================
-- CAMBRIDGE MA — 14 rows, all 2026-01-05 (a Monday; the Plan E charter sets the first Monday in
--   January of even years). TWO separate bodies, each with its own attested minutes:
--   · City Council Inaugural Meeting, 5 Jan 2026, 10:00 AM, Sullivan Chamber. Interim City Clerk
--     Paula M. Crane presiding: "it is her duty and honor to administer the Oath to those elected
--     in the November 2025 election"; "Councillors-elect will be called to the Rostrum in
--     alphabetical order to take their Oath. A copy of the Oath of Office administered to each
--     Councillor is attached"; then "the requirements of Section 97 having been met". All nine
--     councillors-elect are recorded present, so the charter's "member-elect not present" clause
--     reached nobody. (Sumbul Siddiqui is among the nine but is NOT in this migration — CC_0394
--     excluded her as a two-seat holder, Mayor and City Councillor.)
--     cambridgema.iqm2.com/Citizens/FileOpen.aspx?Type=12&ID=3119
--   · School Committee Special (Organizational) Meeting, 5 Jan 2026, 6:00 PM, Dr. Carolyn Turk
--     Auditorium. Minutes attested by Katherine Christo, Executive Secretary: "student members
--     Asraf and Jama introduced Interim City Clerk Paula Crane and Clerk of Committees, Nicole
--     Irwin to administer the oath of office to the Members-Elect:" followed by exactly the six
--     names below.  portal.cpsd.us/school_committee./admin/minutes/570_2026-01-05.pdf
--
-- FRISCO TX — Mark Hill, Mayor, 2026-07-07. City Council Regular Meeting minutes, item 10,
--   "Issuance of the Statement of Elected Officer, Oath of Office, and Certificate of Election to
--   Mark Hill, Mayor": "Mayor Jeff Cheney ceremoniously administered the Oath of Office and
--   Statement of Elected Officer to Mark Hill, Mayor-elect, and presented Mr. Hill with his
--   Certificate of Election." The 5:12 PM roll call that same evening still lists him as
--   "Mayor-Elect" and Cheney as "Mayor", so the seat changed hands inside this meeting.
--   agenda.friscotexas.gov OnBase meetingId=5629, Minutes 7/7/2026.
--
-- PLANO TX — Shun Thomas, Council Place 7, 2026-02-09. The clearest record of the 18, because the
--   city's own minutes catch her on both sides of it in one day:
--   · Preliminary Open Meeting, 4:00 PM, 9 Feb 2026 lists her under "COUNCIL MEMBER ELECT",
--     adopts Resolution No. 2026-2-1(R) canvassing the 31 Jan 2026 special election and
--     "declaring Shun Thomas was elected to Place 7", then takes "Oath of Office for
--     Councilmember Elect Thomas".  plano.novusagenda.com MinutesMeetingID=892
--   · Regular Minutes, 7:00 PM the same evening, list her under "COUNCIL MEMBERS PRESENT".
--     plano.novusagenda.com MinutesMeetingID=893
--   City Secretary Lisa C. Henderson on both.
--
-- ALLEN TX — Chris Schulmeister, Mayor, 2026-05-26. The city's own calendar entry for the 26 May
--   2026 Regular Meeting: the council "will honor outgoing Mayor Baine L. Brooks and conduct the
--   Swearing-In and Oath ceremony for newly elected Mayor Chris Schulmeister". The city's own
--   news item afterwards: "The City of Allen officially welcomed a new mayor during the May 26
--   Allen City Council meeting as Chris Schulmeister was sworn in". Notice and report agree.
--   events.allentx.gov/allentx/260146500 · cityofallen.org/news_detail_T11_R465.php
--
-- Idempotent and gated on the END STATE rather than on rows changed, so a second run writes
-- nothing and still passes every assertion.
--
-- Applied to production 2026-11-11: 17 dated to the day, 1 returned to undated, all 14 Cambridge
-- rows on one date, 0 real days left hidden, unflagged offices_missing_terms still 238. Re-running
-- updates 0 rows and still passes every gate.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- 1. The plan: 18 tenures, keyed on the office and the person, with the value each must end at.
--    NULL target_start means "put this row back to undated".
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE cc0395_plan (
  office_id      uuid    NOT NULL,
  politician_id  uuid    NOT NULL,
  who            text    NOT NULL,
  city           text    NOT NULL,
  target_start   date,
  target_prec    text    NOT NULL,
  citation       text    NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0395_plan (office_id, politician_id, who, city, target_start, target_prec, citation) VALUES
 -- Cambridge MA City Council — Inaugural Meeting minutes, 5 January 2026 (Interim City Clerk Paula M. Crane)
 ('876bdc52-c876-48b4-b578-4f384f639350','236fb3c1-b473-407f-b8a0-d76039b28087','Ayah A. Al-Zubi','Cambridge MA','2026-01-05','day','Cambridge City Council Inaugural Meeting minutes, 5 Jan 2026: Interim City Clerk Paula M. Crane administered the Oath to the Councillors-Elect, all nine recorded present'),
 ('670fe3bd-7c55-4102-b573-3015393965c6','d2358e54-6860-4382-8c8d-95a3dabea874','Burhan Azeem','Cambridge MA','2026-01-05','day','Cambridge City Council Inaugural Meeting minutes, 5 Jan 2026: Interim City Clerk Paula M. Crane administered the Oath to the Councillors-Elect, all nine recorded present'),
 ('667780f2-1d99-4a35-a59e-6a33bddb5967','e44fdba7-5fd0-43c2-a125-c999b0a0bb97','Catherine Zusy','Cambridge MA','2026-01-05','day','Cambridge City Council Inaugural Meeting minutes, 5 Jan 2026: Interim City Clerk Paula M. Crane administered the Oath to the Councillors-Elect, all nine recorded present'),
 ('10772452-d228-4e57-9527-93c48bc2ecde','00565708-5520-418d-afec-58a295d0d8ec','E. Denise Simmons','Cambridge MA','2026-01-05','day','Cambridge City Council Inaugural Meeting minutes, 5 Jan 2026: Interim City Clerk Paula M. Crane administered the Oath to the Councillors-Elect, all nine recorded present'),
 ('05d01dd6-7fe5-42b8-a317-030fc463e478','ad060f52-145c-41e3-8bd1-c454ac1ed46c','Jivan Sobrinho-Wheeler','Cambridge MA','2026-01-05','day','Cambridge City Council Inaugural Meeting minutes, 5 Jan 2026: Interim City Clerk Paula M. Crane administered the Oath to the Councillors-Elect, all nine recorded present'),
 ('2ed4e3df-3551-4c0e-90bf-48733dc38548','a8f48816-2ebc-4ae4-9667-a12d4c18f5ec','Marc C. McGovern','Cambridge MA','2026-01-05','day','Cambridge City Council Inaugural Meeting minutes, 5 Jan 2026: Interim City Clerk Paula M. Crane administered the Oath to the Councillors-Elect, all nine recorded present'),
 ('6aaf22a0-fa2e-4402-8fc9-5c9a6554ae35','eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585','Patricia M. Nolan','Cambridge MA','2026-01-05','day','Cambridge City Council Inaugural Meeting minutes, 5 Jan 2026: Interim City Clerk Paula M. Crane administered the Oath to the Councillors-Elect, all nine recorded present'),
 ('f19a30b2-529c-4e17-8322-40db08baf3aa','34da113e-e5dc-4637-9be1-9d42a6feea93','Tim Flaherty','Cambridge MA','2026-01-05','day','Cambridge City Council Inaugural Meeting minutes, 5 Jan 2026: Interim City Clerk Paula M. Crane administered the Oath to Councillor-Elect Timothy R. Flaherty, recorded present'),
 -- Cambridge MA School Committee — Organizational Meeting minutes, 5 January 2026 (attested Katherine Christo)
 ('2074d5ac-4470-4766-bc77-124c05e8bd97','0342bc7c-a470-4013-897e-237d77265c06','Arjun Jaikumar','Cambridge MA','2026-01-05','day','Cambridge School Committee organizational meeting minutes, 5 Jan 2026: Interim City Clerk Paula Crane and Clerk of Committees Nicole Irwin administered the oath of office to the six Members-Elect, named individually'),
 ('2b2cfbde-9c06-49e3-abe7-6b1c121819d5','c2a5bfd4-a756-4da5-8902-11ee3846cb3a','Caitlin Dube','Cambridge MA','2026-01-05','day','Cambridge School Committee organizational meeting minutes, 5 Jan 2026: Interim City Clerk Paula Crane and Clerk of Committees Nicole Irwin administered the oath of office to the six Members-Elect, named individually'),
 ('528ed78d-0247-4f11-a3aa-c4c283e429db','7dafe688-b8ef-4b49-b6ab-fce66e443fa0','David Weinstein','Cambridge MA','2026-01-05','day','Cambridge School Committee organizational meeting minutes, 5 Jan 2026: Interim City Clerk Paula Crane and Clerk of Committees Nicole Irwin administered the oath of office to the six Members-Elect, named individually (David J. Weinstein)'),
 ('0837f7bd-0055-4a70-a5f6-1e41c4c81b24','1567f33d-dfad-4680-b516-905ff3abdced','Elizabeth Hudson','Cambridge MA','2026-01-05','day','Cambridge School Committee organizational meeting minutes, 5 Jan 2026: Interim City Clerk Paula Crane and Clerk of Committees Nicole Irwin administered the oath of office to the six Members-Elect, named individually'),
 ('b512166f-b5c8-44bf-a70f-07b6f7878b3c','ca2ff1d9-8ebe-4cf2-a804-27d73c58340b','Luisa de Paula Santos','Cambridge MA','2026-01-05','day','Cambridge School Committee organizational meeting minutes, 5 Jan 2026: Interim City Clerk Paula Crane and Clerk of Committees Nicole Irwin administered the oath of office to the six Members-Elect, named individually'),
 ('2494e524-d9ba-493f-a8eb-49f203d3f75c','03e962a0-559e-4ec3-9e41-9a8a933467b2','Richard Harding, Jr.','Cambridge MA','2026-01-05','day','Cambridge School Committee organizational meeting minutes, 5 Jan 2026: Interim City Clerk Paula Crane and Clerk of Committees Nicole Irwin administered the oath of office to the six Members-Elect, named individually'),
 -- Texas
 ('2087a453-d1c4-47ab-904d-13ca58118fd1','3579e02c-d480-48ba-8d95-3eb7f002a5b0','Mark Hill','Frisco TX','2026-07-07','day','Frisco City Council Regular Meeting minutes, 7 Jul 2026, item 10: Mayor Jeff Cheney administered the Oath of Office and Statement of Elected Officer to Mark Hill, Mayor-elect, and presented his Certificate of Election; the 5:12 PM roll call still listed Hill as Mayor-Elect'),
 ('b0121186-a0d8-4dca-8603-8389b66b394e','4272e5cb-40cf-42d9-a493-ae5ca04301bb','Shun Thomas','Plano TX','2026-02-09','day','Plano City Council Preliminary Open Meeting minutes, 9 Feb 2026: Resolution 2026-2-1(R) canvassed the 31 Jan 2026 special election declaring Shun Thomas elected to Place 7, followed by Oath of Office for Councilmember Elect Thomas; the 7:00 PM Regular Minutes the same evening list her under Council Members Present'),
 ('684ffdb3-4073-4164-86f6-c151334fccb1','698da6ca-eadd-46a0-8e27-94ae48d23279','Chris Schulmeister','Allen TX','2026-05-26','day','City of Allen meeting notice and the city news report for the 26 May 2026 Regular Meeting: the council conducted the Swearing-In and Oath ceremony for newly elected Mayor Chris Schulmeister. CORRECTS the snapshot value 2026-05-03, which was the day after the 2 May election and a Sunday'),
 -- 🔴 Back to undated: the snapshot date was the canvass, and no record publishes the oath.
 ('327a50dd-e40f-4892-a3c2-208b1cc0d9b9','53f97990-822e-46de-8e18-f09e5a160c2b','Jaisen Rutledge','Princeton TX',NULL,'unknown','Princeton City Council minutes, 23 Jun 2026 (attested City Secretary Amber Anderson): Ordinance 2026-06-23 CANVASSED the 13 Jun runoff for Seat 4; the meeting records no oath, never names Rutledge, and every motion carried 5-0 with Place 4 empty. He is present as Councilmember in the 13 Jul 2026 work session and regular meeting, neither of which records an oath. The day is between 24 Jun and 13 Jul and is published nowhere, so this term goes back to undated');

-- ---------------------------------------------------------------------------------------------
-- 2. Refuse a plan that does not match the rows CC_0394 actually left behind.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_match int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0395_plan;
  IF v_n <> 18 THEN
    RAISE EXCEPTION 'CC_0395 pre-gate: plan holds % row(s), expected 18', v_n;
  END IF;

  -- Each plan row must name exactly one live tenure, held by that person, on that office.
  SELECT count(*) INTO v_match
    FROM cc0395_plan pl
    JOIN essentials.office_terms ot
      ON ot.office_id = pl.office_id AND ot.politician_id = pl.politician_id
     AND daterange(ot.term_start, ot.term_end, '[]') @> CURRENT_DATE;
  IF v_match <> 18 THEN
    RAISE EXCEPTION 'CC_0395 pre-gate: the 18 plan rows resolve to % current tenure(s)', v_match;
  END IF;

  -- 🔴 Every one must be a row CC_0394 wrote, or this file is editing something else.
  SELECT count(*) INTO v_bad
    FROM cc0395_plan pl
    JOIN essentials.office_terms ot
      ON ot.office_id = pl.office_id AND ot.politician_id = pl.politician_id
     AND daterange(ot.term_start, ot.term_end, '[]') @> CURRENT_DATE
   WHERE ot.source NOT LIKE '%CC_0394: term_start%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0395 pre-gate: % tenure(s) were not written by CC_0394', v_bad;
  END IF;

  -- The person's recorded name must match the plan, so a mis-copied UUID cannot seat a stranger.
  SELECT count(*) INTO v_bad
    FROM cc0395_plan pl
    JOIN essentials.politicians p ON p.id = pl.politician_id
   WHERE p.full_name IS DISTINCT FROM pl.who;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0395 pre-gate: % plan row(s) name a different person than the id does', v_bad;
  END IF;

  -- A dated row must carry a real day; the undated one must carry none.
  SELECT count(*) INTO v_bad FROM cc0395_plan
   WHERE (target_start IS NOT NULL AND target_prec <> 'day')
      OR (target_start IS NULL     AND target_prec <> 'unknown')
      OR (target_start > CURRENT_DATE);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0395 pre-gate: % plan row(s) are internally inconsistent', v_bad;
  END IF;

  RAISE NOTICE 'CC_0395 plan: % dated to the day, % returned to undated',
               (SELECT count(*) FROM cc0395_plan WHERE target_start IS NOT NULL),
               (SELECT count(*) FROM cc0395_plan WHERE target_start IS NULL);
END $$;

-- ---------------------------------------------------------------------------------------------
-- 3. Write. Only rows that differ are touched, so a re-run is a no-op.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.office_terms ot
   SET term_start      = pl.target_start,
       start_precision = pl.target_prec,
       source          = ot.source || ' | CC_0395: '
                         || CASE WHEN pl.target_start IS NULL
                                 THEN 'term start RETURNED TO UNDATED. '
                                 ELSE 'term start set to ' || to_char(pl.target_start,'YYYY-MM-DD')
                                      || ' (day precision) from the city''s own record. ' END
                         || pl.citation || '.'
  FROM cc0395_plan pl
 WHERE ot.office_id = pl.office_id
   AND ot.politician_id = pl.politician_id
   AND daterange(ot.term_start, ot.term_end, '[]') @> CURRENT_DATE
   AND (ot.term_start IS DISTINCT FROM pl.target_start
     OR ot.start_precision IS DISTINCT FROM pl.target_prec);

-- ---------------------------------------------------------------------------------------------
-- 4. Post-verify, on the END STATE.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad int; v_cambridge int; v_drift int; v_left int;
BEGIN
  -- Every planned tenure now reads exactly what the clerk's record says.
  SELECT count(*) INTO v_bad
    FROM cc0395_plan pl
    JOIN essentials.office_terms ot
      ON ot.office_id = pl.office_id AND ot.politician_id = pl.politician_id
     AND daterange(ot.term_start, ot.term_end, '[]') @> CURRENT_DATE
   WHERE ot.term_start IS DISTINCT FROM pl.target_start
      OR ot.start_precision IS DISTINCT FROM pl.target_prec;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0395 gate: % tenure(s) do not carry the planned value', v_bad;
  END IF;

  -- The provenance must be ADDED, not swapped for: CC_0394's account has to survive underneath.
  SELECT count(*) INTO v_bad
    FROM cc0395_plan pl
    JOIN essentials.office_terms ot
      ON ot.office_id = pl.office_id AND ot.politician_id = pl.politician_id
     AND daterange(ot.term_start, ot.term_end, '[]') @> CURRENT_DATE
   WHERE ot.source NOT LIKE '%CC_0394: term_start%'
      OR ot.source NOT LIKE '%CC_0395:%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0395 gate: % row(s) lost a provenance line', v_bad;
  END IF;

  -- 🔴 All 14 Cambridge rows must share one date. They were sworn at two meetings of two
  --    different bodies on the same day; a split here means a UUID went to the wrong city.
  SELECT count(DISTINCT ot.term_start) INTO v_cambridge
    FROM cc0395_plan pl
    JOIN essentials.office_terms ot
      ON ot.office_id = pl.office_id AND ot.politician_id = pl.politician_id
     AND daterange(ot.term_start, ot.term_end, '[]') @> CURRENT_DATE
   WHERE pl.city = 'Cambridge MA';
  IF v_cambridge <> 1 THEN
    RAISE EXCEPTION 'CC_0395 gate: Cambridge rows carry % distinct start dates, expected 1',
                    v_cambridge;
  END IF;
  IF (SELECT count(*) FROM cc0395_plan WHERE city = 'Cambridge MA') <> 14 THEN
    RAISE EXCEPTION 'CC_0395 gate: Cambridge is not 14 rows';
  END IF;

  -- 🔴 The read path must agree. A write a voter cannot see is not a fix.
  SELECT count(*) INTO v_bad
    FROM cc0395_plan pl
    JOIN essentials.office_current_holder och ON och.office_id = pl.office_id
   WHERE och.politician_id IS DISTINCT FROM pl.politician_id
      OR och.term_start      IS DISTINCT FROM pl.target_start
      OR och.start_precision IS DISTINCT FROM pl.target_prec;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0395 gate: % seat(s) do not read back through office_current_holder', v_bad;
  END IF;

  -- Rebuilt independently of the plan: no CC_0394 row may still be sitting at month precision
  -- over a snapshot value whose day component was real. That is the whole population this file
  -- exists to clear.
  SELECT count(*) INTO v_left
    FROM essentials.office_terms ot
   WHERE ot.source LIKE '%CC_0394: term_start%'
     AND ot.start_precision = 'month'
     AND substring(ot.source from 'snapshot, which read "([^"]*)"') ~ '^[0-9]{4}-[0-9]{2}-(0[2-9]|[12][0-9]|3[01])';
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'CC_0395 gate: % month-precision row(s) still hide a real day', v_left;
  END IF;

  -- Nothing here creates or closes a tenure, so the occupancy drift baseline cannot move.
  SELECT count(*) INTO v_drift
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id
   WHERE NOT o.is_vacant;
  IF v_drift <> 238 THEN
    RAISE EXCEPTION 'CC_0395 gate: unflagged offices_missing_terms is %, baseline 238', v_drift;
  END IF;

  RAISE NOTICE 'CC_0395 OK: % dated to the day from clerk minutes, % returned to undated, '
               'Cambridge all on one date, 0 real days left hidden, drift baseline 238 intact',
               (SELECT count(*) FROM cc0395_plan WHERE target_start IS NOT NULL),
               (SELECT count(*) FROM cc0395_plan WHERE target_start IS NULL);
END $$;

COMMIT;
