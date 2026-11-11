-- CC_0390 — Reno Municipal Court: date the bench from the record, and refuse the two dates
--           that look like answers and are not.
--
-- CC_0389 seated Departments 2, 3 and 4 three hours ago with term_start NULL and
-- start_precision 'unknown', because the COURT publishes no dates anywhere on its site. That was
-- correct for what it had. The State of Nevada Judicial Directory (AOC, rev. 2026-03-17) does
-- publish dates, in a column headed TOOK OFFICE, and this migration was opened to copy all three
-- of them in. 🔴 TWO OF THE THREE ARE WRONG, and the directory's own rows are what prove it.
--
--   https://nvcourts.gov/__data/assets/pdf_file/0014/11282/Judicial_Directory_03.23.26.pdf
--   22 pages, footer "Rev. March 17, 2026". ⚠ nvcourts.gov answers HTTP 403 to curl even with a
--   browser User-Agent; it was fetched inside Playwright and parsed with pdf.js, with the footer
--   line asserted present as a control before anything was read off it.
--
--   FIRST NAME · LAST NAME · COURT · APPOINTED/ELECTED · TOOK OFFICE · TERM EXPIRES
--     Shelly O’Neill               Reno Municipal Court (Dept. 2)   11/08/2016  11/08/2016  01/02/2029
--     Justin Champagne             Reno Municipal Court (Dept. 3)   11/08/2022  01/03/2023  01/02/2029
--     Christopher Hazlett-Stevens  Reno Municipal Court (Dept. 4)   11/09/2021  11/13/2021  01/02/2029
--     Gene S. Drakulich            Reno Municipal Court (Dept. 1)   11/04/2014  01/05/2015  01/03/2027
--
-- ▶ THE DEPARTMENT 1 ROW IS THE CONTROL ON THE OTHER THREE. Drakulich was elected on 11/04/2014
--   and took office on 01/05/2015 — a Reno municipal judge elected in November takes office the
--   FOLLOWING JANUARY — and his term expires 01/03/2027, twelve years later, so the seat runs on
--   SIX-YEAR terms. Both facts come from the directory itself, and both are needed below.
--
-- ═══ DEPARTMENT 2 — Shelly T. O'Neill — NOT DATED, and the directory is why ═══════════════════
--    Her two date columns are IDENTICAL: 11/08/2016 in both. 11/08/2016 was the 2016 general
--    election day. Read against the Drakulich control, an elected judge does not take office on
--    election night — she would have taken office in JANUARY 2017. The arithmetic agrees: her
--    term expires 01/02/2029, and 2029 − 12 = 2017, two six-year terms (2017–2023, 2023–2029).
--    Ballotpedia independently has her winning Department 2 again, unopposed, on 2026-11-08 —
--    that is the second of those terms.
-- 🔴 SO THE "TOOK OFFICE" CELL IS THE ELECTION DATE COPIED FORWARD, and the row mixes her FIRST
--    election with her CURRENT term's expiry. Writing 2016-11-08 would assert she held the seat
--    through roughly eight weeks of her predecessor's tenure.
--    The real answer is "January 2017", derived rather than published — no source states it — so
--    this term stays NULL / 'unknown'. ▶ The 2016 Washoe canvass or the City Clerk would settle
--    it; her own biography on the court's page is purely personal and gives no date.
--
-- ═══ DEPARTMENT 3 — Justin Champagne — 2023-01-03, the one clean row ══════════════════════════
--    Elected 11/08/2022, took office 01/03/2023, expires 01/02/2029. The two columns DIFFER, the
--    gap is the Drakulich November→January shape, and the span is exactly six years. Nothing
--    contradicts it. Our Nevada Judges, read 2026-11-10, records one arrival and only one:
--    "Elected Municipal Court Judge to Dept. 3 of the Reno Municipal Court on Jan 2, 2023."
--    ⚠ ONE DAY APART, and deliberately not reconciled: the AOC's 01/03/2023 is written because
--    the AOC is the state's own directory and the source CC_0387 and CC_0388 already cite. The
--    disagreement is recorded here so nobody "corrects" it later without re-sourcing it.
--    ⚠ He sat as a JUDGE PRO TEMPORE from 2020 — a substitute, not the holder of Department 3.
--    Pro tem service is not tenure in the seat and is not a term_start.
--
-- ═══ DEPARTMENT 4 — Christopher Hazlett-Stevens — 2021-01-14, TEN MONTHS BEFORE THE AOC'S DATE ═
-- 🔴 THE DIRECTORY SAYS 11/13/2021 AND HE WAS ALREADY ON THE BENCH. Reno City Council Minutes for
--    14 January 2021, read in full from the city's own PrimeGov portal:
--      "B  Reno Municipal Court, Department 4 Judge Selection and Appointment
--       B.1 Staff Report (For Possible Action): Interviews with finalists Christopher
--           Hazlett-Stevens, Steven Silva, Henry Sotelo, and Charles Woodman seeking appointment
--           as Judge for Reno Municipal Court, Department 4, review of competence and
--           qualifications, possible selection of appointee, possible swearing in of appointed
--           judge, and other possible direction to staff."
--      "Mr. Shaver reported the results with three Council Members selecting Mr. Hazlett-Stevens,
--       two selecting Mr. Sotelo, and two selecting Mr. Woodman. Christopher Hazlett-Stevens was
--       selected for appointment to Reno Municipal Court Judge in Department 4.
--       RESULT: APPROVED [UNANIMOUS]"
--    Corroborated independently: KUNR, published 2021-04-08, captions a photograph "Judge
--    Christopher Hazlett-Stevens (center, facing the camera) presiding over a case at Reno
--    Community Court ... on April 7, 2021", and quotes him on "my previous experience as a
--    prosecutor, and now as a judge". He was sitting SEVEN MONTHS before the directory's date.
--
-- 🔴 THE TWO AGGREGATORS AGREE WITH EACH OTHER AND BOTH ARE WRONG, WHICH IS WHY AGREEMENT IS NOT
--    CORROBORATION. Our Nevada Judges also gives "Appointed ... to Dept. 4 ... on Nov 9, 2021",
--    the same month as the AOC. Two sources that agree may share one upstream. The Reno City
--    Council's own minutes are the primary record of an act the COUNCIL performs, and they name
--    the man, the department and the vote. ▶ ASK WHO PERFORMS THE ACT, THEN READ THAT BODY.
--    The council's complete 2021 record was scanned — 36 meetings, 69 Agenda and Minutes PDFs,
--    positive control "public comment" matching 69 of 69 — and "Hazlett" appears on 14 January
--    and NOWHERE ELSE. There was no November 2021 council action on Department 4 to point at.
--    (The only other Department 4 hit all year is a judges' salary resolution on 26 May.)
--    ⚠ His own campaign statement says "In January of 2021, Chris was appointed to the bench by
--    the Reno City Council" — loose prose that names no department, and it agrees with the
--    minutes, not with the directories.
--    ⚠ The minutes record the SELECTION and the vote; they do not separately record a swearing-in,
--    although the agenda item put one in the same item on the same day. So 2021-01-14 is the day
--    the council seated him, written at 'day' precision. If a swearing-in days later is ever
--    found, this is the row to refine — the evidence for the claim is written out above so that
--    the claim stays testable.
--    how_started becomes 'appointed': he arrived by appointment and was elected to the seat
--    afterwards, in November 2022. The tenure is continuous and this repo models a tenure as ONE
--    row — measured, 11,212 office_terms rows and NOT ONE office/person pair holds two; Chuck
--    Grassley is a single open-ended row from 1981-01-05 across seven re-elections. So the row's
--    how_started describes how the TENURE began, which here is the appointment.
--
-- ═══ WHAT THIS OVERWRITES ═════════════════════════════════════════════════════════════════════
-- There is no history table for office_terms, so the prior values are recorded here verbatim.
-- All three rows currently read: term_start NULL · start_precision 'unknown' · how_started
-- 'elected', and all three carry this source, differing only in the quoted heading:
--
--   "CC_0389 S1: Reno Municipal Court's own judges page,
--    https://www.renomunicipalcourt.com/general-information/judges.php, read 2026-11-10. Heading
--    read verbatim: "Department N - Judge <name>". The court publishes its roster on its own
--    domain, not on reno.gov, whose court paths all return 404. The page renders client-side, so
--    it was read in a browser. No term dates are published anywhere on the site, so this
--    occupancy has no start date."
--
-- Term ids as at 2026-11-10: Dept 2 26d02dce-14c0-4408-b1e5-75737ba17b34 ·
-- Dept 3 554a95e0-3e44-45c3-9978-90057784b7ef · Dept 4 23183e44-a8f8-43ac-a809-d6b17414f54a.
--
-- ═══ WHAT THIS DELIBERATELY DOES NOT TOUCH ════════════════════════════════════════════════════
-- Department 1 is vacant and stays vacant: no term, flag kept, no vacant_since, description
-- unchanged. Nothing here seats anybody or changes who holds a seat — only when three tenures
-- that are already recorded began. The drift metric therefore must not move at all, and the gate
-- asserts that as a delta captured inside this transaction rather than against a total another
-- session can shift while this is being written.
--
-- Applied to production 2026-11-10.

BEGIN;

-- ── Resolve the bench, and capture the before-state for the delta gate ────────────────────────
CREATE TEMP TABLE rt_bench ON COMMIT DROP AS
SELECT o.id          AS office_id,
       o.title       AS office_title,
       o.is_vacant   AS was_vacant,
       t.id          AS term_id,
       t.politician_id,
       p.full_name,
       t.term_start      AS was_term_start,
       t.start_precision AS was_precision,
       t.how_started     AS was_how_started
  FROM essentials.offices o
  JOIN essentials.chambers c   ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_terms t ON t.office_id = o.id
  LEFT JOIN essentials.politicians p  ON p.id = t.politician_id
 WHERE g.geo_id = '3260600'
   AND c.name = 'Reno Municipal Court';

CREATE TEMP TABLE rt_baseline ON COMMIT DROP AS
SELECT count(*)                                AS total,
       count(*) FILTER (WHERE o.is_vacant)     AS flagged,
       count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

-- ── Pre-check: refuse unless the bench is exactly as CC_0389 left it ──────────────────────────
DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM rt_bench;
  IF v <> 4 THEN
    RAISE EXCEPTION 'CC_0390 pre-check: expected 4 Reno Municipal Court offices, found %', v;
  END IF;

  SELECT count(*) INTO v FROM rt_bench WHERE term_id IS NOT NULL;
  IF v <> 3 THEN
    RAISE EXCEPTION 'CC_0390 pre-check: expected 3 seated departments, found %. CC_0389 is the '
                    'migration that seats this bench; re-read the roster before running this.', v;
  END IF;

  -- Every row must still be undated, or another session has already dated them and the evidence
  -- written in this header was gathered against a state that no longer exists.
  SELECT count(*) INTO v
    FROM rt_bench
   WHERE term_id IS NOT NULL
     AND (was_term_start IS NOT NULL OR was_precision <> 'unknown' OR was_how_started <> 'elected');
  IF v <> 0 THEN
    RAISE EXCEPTION 'CC_0390 pre-check: % bench term(s) are no longer NULL/unknown/elected. '
                    'Somebody has already edited them.', v;
  END IF;

  SELECT count(*) INTO v FROM rt_bench
   WHERE office_title = 'Municipal Court Judge, Department 1' AND was_vacant AND term_id IS NULL;
  IF v <> 1 THEN
    RAISE EXCEPTION 'CC_0390 pre-check: Department 1 is not an unseated, flagged vacancy';
  END IF;

  -- The three names this migration reasons about must be the three people actually seated.
  SELECT count(*) INTO v FROM rt_bench
   WHERE full_name IN ('Shelly T. O''Neill', 'Justin Champagne', 'Christopher Hazlett-Stevens');
  IF v <> 3 THEN
    RAISE EXCEPTION 'CC_0390 pre-check: the seated judges are not the three this migration '
                    'researched; found % of 3 expected names', v;
  END IF;
END $$;

-- ── Department 3 — Justin Champagne — the AOC's TOOK OFFICE, which survives every cross-check ──
UPDATE essentials.office_terms t
   SET term_start      = DATE '2023-01-03',
       start_precision = 'day',
       how_started     = 'elected',
       source =
         'CC_0390 S1: State of Nevada Judicial Directory (AOC, rev. 2026-03-17), '
      || 'https://nvcourts.gov/__data/assets/pdf_file/0014/11282/Judicial_Directory_03.23.26.pdf, '
      || 'read 2026-11-10 in a browser (the host answers 403 to curl). Its MUNICIPAL COURT JUDGES '
      || 'table gives Justin Champagne, Reno Municipal Court (Dept. 3): elected 11/08/2022, TOOK '
      || 'OFFICE 01/03/2023, term expires 01/02/2029 — a six-year span, and the same '
      || 'November-to-January gap the directory shows for this court''s Department 1. '
      || 'Our Nevada Judges, read the same day, records exactly one arrival for him and says '
      || '"Elected Municipal Court Judge to Dept. 3 of the Reno Municipal Court on Jan 2, 2023"; '
      || 'that one-day disagreement is recorded and not reconciled. He sat as a judge pro tempore '
      || 'from 2020, which is substitute service and not tenure in this seat. '
      || 'Supersedes CC_0389''s undated row, which was written before this directory was read.'
  FROM rt_bench b
 WHERE t.id = b.term_id
   AND b.office_title = 'Municipal Court Judge, Department 3'
   AND t.term_start IS NULL;

-- ── Department 4 — Christopher Hazlett-Stevens — the council's own minutes, not the directory ──
UPDATE essentials.office_terms t
   SET term_start      = DATE '2021-01-14',
       start_precision = 'day',
       how_started     = 'appointed',
       source =
         'CC_0390 S1: Reno City Council Minutes, 14 January 2021, read in full 2026-11-10 from '
      || 'the city''s PrimeGov portal (https://reno.primegov.com/Public/CompiledDocument/2915). '
      || 'Agenda item B, "Reno Municipal Court, Department 4 Judge Selection and Appointment", '
      || 'interviewed four finalists and provided for "possible swearing in of appointed judge"; '
      || 'the minutes record "Christopher Hazlett-Stevens was selected for appointment to Reno '
      || 'Municipal Court Judge in Department 4. RESULT: APPROVED [UNANIMOUS]". '
      || 'Corroborated by KUNR, 2021-04-08, whose photo caption reads "Judge Christopher '
      || 'Hazlett-Stevens ... presiding over a case at Reno Community Court ... on April 7, 2021". '
      || 'He arrived by appointment and was elected to the seat afterwards, in November 2022; the '
      || 'tenure is continuous and is one row, so how_started describes the appointment. '
      || '🔴 The State of Nevada Judicial Directory (AOC, rev. 2026-03-17) gives TOOK OFFICE '
      || '11/13/2021 and Our Nevada Judges gives an appointment of 2021-11-09; BOTH ARE REJECTED, '
      || 'because he was demonstrably on the bench in April 2021 and the council — the body that '
      || 'performs the appointment — took no Department 4 action in November 2021 at all. Its '
      || 'complete 2021 record was scanned, 69 of 69 documents matching a positive control, and '
      || 'his name appears on 14 January only. The minutes do not separately record a '
      || 'swearing-in, so a later date, if one is ever found, would refine this row. '
      || 'Supersedes CC_0389''s undated row.'
  FROM rt_bench b
 WHERE t.id = b.term_id
   AND b.office_title = 'Municipal Court Judge, Department 4'
   AND t.term_start IS NULL;

-- ── Department 2 — Shelly T. O'Neill — STAYS UNDATED. Only the reasoning is written down. ──────
-- 🔴 This is the point of the migration as much as the two dates are. The directory offers a date
--    for her and it is the election date wearing a "took office" label; recording WHY it was
--    refused is what stops the next session copying it in.
UPDATE essentials.office_terms t
   SET source =
         'CC_0390 S1: still undated, deliberately. The court publishes no dates '
      || '(https://www.renomunicipalcourt.com/general-information/judges.php, read 2026-11-10; '
      || 'her biography there is personal and gives no arrival date). The State of Nevada '
      || 'Judicial Directory (AOC, rev. 2026-03-17) gives Shelly O''Neill, Reno Municipal Court '
      || '(Dept. 2): elected 11/08/2016, TOOK OFFICE 11/08/2016, term expires 01/02/2029 — the '
      || 'two date columns are IDENTICAL and 11/08/2016 was the 2016 general election day. '
      || '🔴 THAT IS THE ELECTION DATE COPIED FORWARD, NOT A DATE OF TAKING OFFICE. The same '
      || 'directory shows this court''s Department 1 judge elected 11/04/2014 and taking office '
      || '01/05/2015, so a Reno municipal judge elected in November takes office the following '
      || 'January; and her expiry of 01/02/2029 is twelve years — two six-year terms — after a '
      || 'January 2017 start. Ballotpedia has her re-elected to Department 2 unopposed on '
      || '2026-11-08, which is that second term. So the real answer is January 2017, DERIVED and '
      || 'not published by anyone, and it is therefore not written. The 2016 Washoe County '
      || 'canvass or the Reno City Clerk would settle the day. '
      || 'Prior value, from CC_0389: term_start NULL, start_precision unknown, source recording '
      || 'that the court publishes no dates.'
  FROM rt_bench b
 WHERE t.id = b.term_id
   AND b.office_title = 'Municipal Court Judge, Department 2'
   AND t.term_start IS NULL;

-- ── Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_dated int; v_terms int; v_held int; v_flagged int; v_bad int; v_sourced int;
  v_d2_start date; v_d2_prec text; v_d3_start date; v_d4_start date; v_d4_how text;
  b_total int; b_flagged int; b_unflagged int;
  a_total int; a_flagged int; a_unflagged int;
BEGIN
  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t JOIN rt_bench b ON b.term_id = t.id;
  IF v_terms <> 3 THEN
    RAISE EXCEPTION 'CC_0390 gate: expected the same 3 bench terms, found %', v_terms;
  END IF;

  -- Exactly two of the three carry a date, and they are the two that were researched to a record.
  SELECT count(*) INTO v_dated
    FROM essentials.office_terms t JOIN rt_bench b ON b.term_id = t.id
   WHERE t.term_start IS NOT NULL;
  IF v_dated <> 2 THEN
    RAISE EXCEPTION 'CC_0390 gate: expected exactly 2 dated bench terms, found %', v_dated;
  END IF;

  -- 🔴 The dates that look like answers and are not. Checked FIRST, so that this guard is the one
  --    a refused date trips, rather than the per-department equality checks below shadowing it.
  SELECT count(*) INTO v_bad
    FROM essentials.office_terms t JOIN rt_bench b ON b.term_id = t.id
   WHERE t.term_start IN (DATE '2021-11-13',   -- AOC's TOOK OFFICE for Dept 4; ten months late
                          DATE '2021-11-09',   -- Our Nevada Judges' appointment date for Dept 4
                          DATE '2016-11-08',   -- AOC's TOOK OFFICE for Dept 2; the election day
                          DATE '2022-11-18');  -- Ballotpedia's "assumed office" for all three
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0390 gate: % bench term(s) took a refused date. Each of 2021-11-13, '
                    '2021-11-09, 2016-11-08 and 2022-11-18 is contradicted by a primary record; '
                    'read this migration''s header before overriding.', v_bad;
  END IF;

  SELECT t.term_start, t.start_precision INTO v_d2_start, v_d2_prec
    FROM essentials.office_terms t JOIN rt_bench b ON b.term_id = t.id
   WHERE b.office_title = 'Municipal Court Judge, Department 2';
  IF v_d2_start IS NOT NULL OR v_d2_prec <> 'unknown' THEN
    RAISE EXCEPTION 'CC_0390 gate: Department 2 acquired a start date (% / %). The directory''s '
                    '11/08/2016 is the election date, not the day she took office.',
                    v_d2_start, v_d2_prec;
  END IF;

  SELECT t.term_start INTO v_d3_start
    FROM essentials.office_terms t JOIN rt_bench b ON b.term_id = t.id
   WHERE b.office_title = 'Municipal Court Judge, Department 3';
  IF v_d3_start IS DISTINCT FROM DATE '2023-01-03' THEN
    RAISE EXCEPTION 'CC_0390 gate: Department 3 start is % , expected 2023-01-03', v_d3_start;
  END IF;

  SELECT t.term_start, t.how_started INTO v_d4_start, v_d4_how
    FROM essentials.office_terms t JOIN rt_bench b ON b.term_id = t.id
   WHERE b.office_title = 'Municipal Court Judge, Department 4';
  IF v_d4_start IS DISTINCT FROM DATE '2021-01-14' THEN
    RAISE EXCEPTION 'CC_0390 gate: Department 4 start is % , expected 2021-01-14 — the day the '
                    'Reno City Council appointed him', v_d4_start;
  END IF;
  IF v_d4_how <> 'appointed' THEN
    RAISE EXCEPTION 'CC_0390 gate: Department 4 how_started is %, expected appointed. He was '
                    'appointed by the council and elected only afterwards.', v_d4_how;
  END IF;

  -- Every row this migration touched must say so, or its reasoning exists nowhere.
  SELECT count(*) INTO v_sourced
    FROM essentials.office_terms t JOIN rt_bench b ON b.term_id = t.id
   WHERE t.source LIKE 'CC_0390 %';
  IF v_sourced <> 3 THEN
    RAISE EXCEPTION 'CC_0390 gate: expected 3 bench terms to carry a CC_0390 source, found %',
                    v_sourced;
  END IF;

  -- Nobody was seated or unseated. Count och.politician_id, never count(*).
  SELECT count(*) INTO v_held
    FROM essentials.office_current_holder och JOIN rt_bench b ON b.office_id = och.office_id
   WHERE och.politician_id IS NOT NULL;
  IF v_held <> 3 THEN
    RAISE EXCEPTION 'CC_0390 gate: expected 3 departments to resolve to a holder, found %', v_held;
  END IF;

  -- Department 1 is untouched: still vacant, still flagged, still undated, still described.
  SELECT count(*) INTO v_flagged
    FROM essentials.offices o JOIN rt_bench b ON b.office_id = o.id WHERE o.is_vacant;
  IF v_flagged <> 1 THEN
    RAISE EXCEPTION 'CC_0390 gate: expected exactly 1 flagged department, found %', v_flagged;
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.offices o JOIN rt_bench b ON b.office_id = o.id
              WHERE b.office_title = 'Municipal Court Judge, Department 1'
                AND (NOT o.is_vacant OR o.vacant_since IS NOT NULL OR o.description IS NULL)) THEN
    RAISE EXCEPTION 'CC_0390 gate: Department 1 changed. This migration dates tenures; it has no '
                    'business touching the vacancy, whose date is still unestablished.';
  END IF;

  -- 🔴 The drift metric must not move AT ALL — captured as a delta inside this transaction.
  SELECT total, flagged, unflagged INTO b_total, b_flagged, b_unflagged FROM rt_baseline;
  SELECT count(*),
         count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE NOT o.is_vacant)
    INTO a_total, a_flagged, a_unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF (a_total, a_flagged, a_unflagged) IS DISTINCT FROM (b_total, b_flagged, b_unflagged) THEN
    RAISE EXCEPTION 'CC_0390 gate: offices_missing_terms moved % / % / % -> % / % / %. Dating an '
                    'existing term cannot change it; something else was edited.',
                    b_total, b_flagged, b_unflagged, a_total, a_flagged, a_unflagged;
  END IF;

  RAISE NOTICE 'CC_0390 OK: Dept 3 -> 2023-01-03 (elected) · Dept 4 -> 2021-01-14 (appointed) · '
               'Dept 2 left undated on purpose · 3 sources rewritten · drift unchanged at % / % / %',
               a_total, a_flagged, a_unflagged;
END $$;

COMMIT;
