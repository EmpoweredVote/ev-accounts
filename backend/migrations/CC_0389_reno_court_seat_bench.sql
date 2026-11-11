-- CC_0389 — Reno Municipal Court: seat the bench from the court's own roster.
--
-- CC_0388 wrote four descriptions saying "this one is filled … we will name the judge once the
-- court's own roster settles it", because every reno.gov URL for the court returned 404 and the
-- roster could not be reached. 🔴 THE COURT IS NOT ON reno.gov. It publishes on its own domain:
--
--     https://www.renomunicipalcourt.com/general-information/judges.php      (read 2026-11-10)
--
-- The four reno.gov 404s in CC_0388's header are real path 404s, not a WAF and not an outage:
-- reno.gov/government and /government/departments answer 200 while /residents and every court
-- path return the same 186,842-byte styled error page. reno.gov's live paths now end in ".php".
-- ⚠ The roster is NOT in the HTML — curl returns a shell with no names; the CMS renders the list
-- client-side, so it has to be read in a browser. It was.
--
-- The court's own roster, which outranks every aggregator:
--
--     Department 1   Vacant
--     Department 2   Judge Shelly T. O'Neill
--     Department 3   Judge Justin Champagne
--     Department 4   Judge Christopher Hazlett-Stevens
--
-- Each sitting judge has a long, specific biography behind an "About" tab, all three read in full.
-- Department 1's detail pane is EMPTY: the court gives no reason and no date for the vacancy.
--
-- 🔴 SO CC_0388 WAS WRONG ABOUT DEPARTMENT 1, IN THE DIRECTION IT EXISTED TO PREVENT. It told a
-- voter the seat is filled. The court says it is vacant. That department does not want a seating;
-- it wants its sentence corrected.
--
-- 🔴 NO TERM DATES ARE PUBLISHED ANYWHERE ON THE COURT'S SITE. The roster is authoritative for the
-- names and silent on the starts, so all three terms are written term_start NULL with
-- start_precision 'unknown' — the same encoding CC_0387 used for Reno's six sitting councillors,
-- and for the same reason. That is also why these go in through a direct INSERT: essentials.
-- seat_officeholder RAISES on a NULL term_start, by design. There is no predecessor term on any of
-- these four offices, so the helper's real work — closing the previous term — does not arise.
-- ⚠ Ballotpedia gives 2022-11-18 for all three. It is an aggregator, the court does not corroborate
-- it, and CLAUDE.md is explicit that "first elected" is not a term start. Not used. If someone later
-- sources a start from the City Clerk's 2022 canvass or the judges' oaths, that is a real improvement.
--
-- 🔴 DEPARTMENT 1 GETS NO vacant_since. The court does not publish one. A local Substack reports
-- Gene Drakulich retired effective 2026-06-10 with no interim appointment; that is a lead, not
-- evidence, and a date copied off it would be a false claim wearing a citation-shaped field. The
-- seat stays in the undated-flagged sub-bucket with its reason written down, which is CC_0298's
-- "real vacancy, date not published" shape. Dating it is a follow-up, not a blocker.
--
-- 🔴 NO DESCRIPTION NAMES THE 2026 WINNER. The Nevada Secretary of State's Washoe page, marked
-- Unofficial and prepared 2026-11-04, gives Dept 1 as GIANOLI, ANGELA "ANGIE" 64.84% / 46,785
-- against HUBACH, JENNY DIANE 35.16% / 25,372. ⚠ That page's own header reads "Precincts
-- reporting: 0" beside 72,157 votes, so it is stale on its face. A call is not a canvass and a
-- certified result is not a fact about who holds a seat. Certification is 2026-12-01. A gate below
-- fails if either candidate's name reaches a voter-facing column.
--
-- ── VALUES THIS MIGRATION OVERWRITES ─────────────────────────────────────────────────────────────
-- There is no history for essentials.offices.description, so the previous text exists nowhere else
-- the moment this commits. All four CC_0388 values, verbatim:
--
--   Dept 1: "Reno Municipal Court has four elected departments, and this one is filled. Empowered
--            Vote has not recorded who holds it. The department was on the ballot on 3 November
--            2026 and the result was not settled when this record was written. We will name the
--            judge once the City declares the result."
--   Dept 2: "Reno Municipal Court has four elected departments, and this one is filled. Empowered
--            Vote has not recorded who holds it. Published sources disagree: the State of Nevada
--            Judicial Directory and Ballotpedia name different judges for this department. We will
--            name the judge once the court's own roster settles it."
--   Dept 3: "Reno Municipal Court has four elected departments, and this one is filled. Empowered
--            Vote has not recorded who holds it, because we have not yet confirmed the judge
--            against the court's own roster. We will name the judge once we have."
--   Dept 4: identical to Dept 3.
--
-- Dept 2's sentence recorded a source conflict. The court's roster resolves it: Shelly T. O'Neill.
-- Depts 2, 3 and 4 said "we will name the judge once the court's own roster settles it" — this is
-- that. Their descriptions are cleared, because they describe an absence that no longer exists.
--
-- ── NAMESAKES ────────────────────────────────────────────────────────────────────────────────────
-- None of the three judges existed in the database. Five namesakes do, and one is a Nevadan:
-- P. K. O'Neill, Richard W. O'Neill, David O'Neill (KY), Brian J. O'Neill (PA) and Dawn Champagne.
-- A full-name match is not an identity; these people are created fresh and scoped on
-- source LIKE 'CC_0389 %'. A gate below fails if any pre-existing person acquires a bench seat.
--
-- Baseline: measured 297 / 59 / 238 (total / flagged / unflagged) immediately before writing this.
-- Three flagged-and-unseated offices become seated, so total and flagged each fall by 3 and 🔴 the
-- 238 UNFLAGGED BASELINE MUST NOT MOVE. The gate asserts the delta inside this transaction rather
-- than a total another session can move while this is being written.
--
-- Offices observed 2026-11-10, all four on chamber "Reno Municipal Court" (official_count 4),
-- all sharing district d3c8c850-e8e4-48ee-a91c-a19210d52efa (LOCAL, geo_id 3260600) — a shared
-- district holding several offices, which is a legitimate variant, not a defect:
--   Dept 1 c5ef0097-14dc-4bef-b4f8-2367b163f752   Dept 2 69420fe3-092a-4b96-9b1d-4c7680fc663d
--   Dept 3 0c4afaf8-7ea3-4828-b44c-4afe083c60c9   Dept 4 eaa93d4f-7176-46cd-aa67-d5a05701d608
-- Resolved by chamber and title below rather than by those ids, so a rebuilt row does not silently
-- miss; the count is asserted at 4.

BEGIN;

-- ── Resolve the four departments, and record where the metric stood on entry ──────────────────
CREATE TEMP TABLE rc_bench ON COMMIT DROP AS
SELECT o.id          AS office_id,
       o.title       AS office_title,
       o.is_vacant   AS was_vacant,
       o.description AS was_description,
       NULL::uuid    AS politician_id,
       NULL::text    AS full_name,
       NULL::text    AS first_name,
       NULL::text    AS last_name,
       NULL::text    AS preferred_name
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.geo_id = '3260600'
   AND c.name = 'Reno Municipal Court';

CREATE TEMP TABLE rc_baseline ON COMMIT DROP AS
SELECT count(*)                                  AS total,
       count(*) FILTER (WHERE o.is_vacant)       AS flagged,
       count(*) FILTER (WHERE NOT o.is_vacant)   AS unflagged
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

-- ── Pre-check: refuse if the bench is not in the state this migration was written against ─────
DO $$
DECLARE v_offices int; v_seated int; v_flagged int; v_described int;
BEGIN
  SELECT count(*) INTO v_offices FROM rc_bench;
  IF v_offices <> 4 THEN
    RAISE EXCEPTION 'CC_0389 pre-check: expected 4 Reno Municipal Court offices, found %', v_offices;
  END IF;

  IF EXISTS (SELECT 1 FROM rc_bench GROUP BY office_title HAVING count(*) > 1) THEN
    RAISE EXCEPTION 'CC_0389 pre-check: a department title resolves to more than one office';
  END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.office_terms t JOIN rc_bench b ON b.office_id = t.office_id;
  IF v_seated <> 0 THEN
    RAISE EXCEPTION 'CC_0389 pre-check: % bench term(s) already exist. Another session has seated '
                    'this court; re-read the roster before running this.', v_seated;
  END IF;

  SELECT count(*) INTO v_flagged FROM rc_bench WHERE was_vacant;
  IF v_flagged <> 4 THEN
    RAISE EXCEPTION 'CC_0389 pre-check: expected 4 flagged departments, found %', v_flagged;
  END IF;

  SELECT count(*) INTO v_described FROM rc_bench WHERE was_description IS NOT NULL;
  IF v_described <> 4 THEN
    RAISE EXCEPTION 'CC_0389 pre-check: expected CC_0388 descriptions on all 4, found %', v_described;
  END IF;
END $$;

-- ── The three sitting judges, read off the court's own roster ─────────────────────────────────
-- ⚠ The straight ASCII apostrophe in O'Neill is the form the roster heading uses. An existing
-- Brian J. O’Neill in this table carries the curly U+2019; they are different people and the
-- difference in punctuation is not what distinguishes them.
UPDATE rc_bench SET full_name = 'Shelly T. O''Neill',
                    first_name = 'Shelly', last_name = 'O''Neill'
 WHERE office_title = 'Municipal Court Judge, Department 2';
UPDATE rc_bench SET full_name = 'Justin Champagne',
                    first_name = 'Justin', last_name = 'Champagne'
 WHERE office_title = 'Municipal Court Judge, Department 3';
UPDATE rc_bench SET full_name = 'Christopher Hazlett-Stevens',
                    first_name = 'Christopher', last_name = 'Hazlett-Stevens',
                    preferred_name = 'Chris'     -- his own biography calls him Chris throughout
 WHERE office_title = 'Municipal Court Judge, Department 4';

INSERT INTO essentials.politicians
  (full_name, first_name, last_name, preferred_name, is_active, is_incumbent, source)
SELECT b.full_name, b.first_name, b.last_name, b.preferred_name,
       true,
       true,    -- sitting judges, not candidates; the column defaults FALSE and hides them
       'CC_0389 S1: Reno Municipal Court''s own judges page, '
       || 'https://www.renomunicipalcourt.com/general-information/judges.php, read 2026-11-10. '
       || 'Heading read verbatim: "' || b.office_title_heading || '". The court publishes its '
       || 'roster on its own domain, not on reno.gov, whose court paths all return 404. The page '
       || 'renders client-side, so it was read in a browser. No term dates are published anywhere '
       || 'on the site, so this occupancy has no start date.'
  FROM (SELECT b.*,
               replace(b.office_title, 'Municipal Court Judge, ', '') || ' - Judge ' || b.full_name
                 AS office_title_heading
          FROM rc_bench b WHERE b.full_name IS NOT NULL) b
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(b.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(b.last_name))
      AND p.source LIKE 'CC_0389 %');

UPDATE rc_bench b SET politician_id = p.id
  FROM essentials.politicians p
 WHERE lower(btrim(p.first_name)) = lower(btrim(b.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(b.last_name))
   AND p.source LIKE 'CC_0389 %';

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM rc_bench WHERE full_name IS NOT NULL AND politician_id IS NULL;
  IF v <> 0 THEN RAISE EXCEPTION 'CC_0389: % judge(s) did not resolve to a person', v; END IF;
END $$;

-- ── Seat the three ────────────────────────────────────────────────────────────────────────────
-- Direct, not via seat_officeholder: that helper RAISEs on a NULL term_start, and NULL +
-- 'unknown' is the honest encoding when the body publishes no start. No predecessor to close.
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT b.office_id, b.politician_id, NULL, 'unknown', 'elected', p.source
  FROM rc_bench b
  JOIN essentials.politicians p ON p.id = b.politician_id
 WHERE b.politician_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = b.office_id);

-- ── The three held departments are no longer vacant ───────────────────────────────────────────
-- 🔴 seat_officeholder would not have done this and neither does an INSERT: clearing the flag is
-- a separate act, and a seat left held AND flagged emits a spurious all-NULL row beside its holder.
UPDATE essentials.offices o
   SET is_vacant = false,
       vacant_since = NULL
  FROM rc_bench b
 WHERE o.id = b.office_id AND b.politician_id IS NOT NULL;

-- ── Their CC_0388 descriptions go: they describe an absence that no longer exists ─────────────
UPDATE essentials.offices o
   SET description = NULL
  FROM rc_bench b
 WHERE o.id = b.office_id
   AND b.politician_id IS NOT NULL
   AND o.description IS NOT NULL;

-- ── Department 1 is genuinely vacant. Correct its sentence; keep its flag; write no date ──────
UPDATE essentials.offices o
   SET description =
         'Reno Municipal Court has four elected departments, and this one has no judge. '
      || 'The court''s own roster lists Department 1 as vacant. Empowered Vote has not '
      || 'established the date the seat became empty, so none is shown. The department was '
      || 'on the ballot on 3 November 2026 and the count was not certified when this record '
      || 'was written.'
  FROM rc_bench b
 WHERE o.id = b.office_id
   AND b.politician_id IS NULL
   AND o.description LIKE '%this one is filled%';

-- ── Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_people int; v_terms int; v_dated int; v_held int; v_flagged int;
  v_desc_cleared int; v_d1_flag bool; v_d1_since date; v_d1_desc text;
  v_filled int; v_names int; v_outsider int;
  b_total int; b_flagged int; b_unflagged int;
  a_total int; a_flagged int; a_unflagged int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE source LIKE 'CC_0389 %';
  IF v_people <> 3 THEN
    RAISE EXCEPTION 'CC_0389 gate: expected 3 new people, found %', v_people;
  END IF;

  IF EXISTS (SELECT 1 FROM essentials.politicians
              WHERE source LIKE 'CC_0389 %' AND (is_incumbent = false OR is_active = false)) THEN
    RAISE EXCEPTION 'CC_0389 gate: a seated judge is not marked active and incumbent, so address '
                    'search would not return them';
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t JOIN rc_bench b ON b.office_id = t.office_id;
  IF v_terms <> 3 THEN
    RAISE EXCEPTION 'CC_0389 gate: expected 3 bench terms, found %', v_terms;
  END IF;

  -- 🔴 Department 1 must NOT have been seated. The court says the seat is empty.
  IF EXISTS (SELECT 1 FROM essentials.office_terms t JOIN rc_bench b ON b.office_id = t.office_id
              WHERE b.office_title = 'Municipal Court Judge, Department 1') THEN
    RAISE EXCEPTION 'CC_0389 gate: Department 1 was seated. The court''s own roster says vacant.';
  END IF;

  -- 🔴 No invented start dates.
  SELECT count(*) INTO v_dated
    FROM essentials.office_terms t JOIN rc_bench b ON b.office_id = t.office_id
   WHERE t.term_start IS NOT NULL OR t.start_precision <> 'unknown';
  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'CC_0389 gate: % bench term(s) carry a start date. The court publishes none; '
                    'an aggregator''s "assumed office" is not the court''s record.', v_dated;
  END IF;

  SELECT count(*) INTO v_held
    FROM essentials.office_current_holder och JOIN rc_bench b ON b.office_id = och.office_id
   WHERE och.politician_id IS NOT NULL;      -- counting och.politician_id, never count(*)
  IF v_held <> 3 THEN
    RAISE EXCEPTION 'CC_0389 gate: expected 3 departments to resolve to a holder, found %', v_held;
  END IF;

  SELECT count(*) INTO v_flagged
    FROM essentials.offices o JOIN rc_bench b ON b.office_id = o.id WHERE o.is_vacant;
  IF v_flagged <> 1 THEN
    RAISE EXCEPTION 'CC_0389 gate: expected exactly 1 department still flagged vacant '
                    '(Department 1), found %', v_flagged;
  END IF;

  SELECT count(*) INTO v_desc_cleared
    FROM essentials.offices o JOIN rc_bench b ON b.office_id = o.id
   WHERE b.politician_id IS NOT NULL AND o.description IS NULL;
  IF v_desc_cleared <> 3 THEN
    RAISE EXCEPTION 'CC_0389 gate: expected 3 cleared descriptions, found %', v_desc_cleared;
  END IF;

  -- 🔴 No seat anywhere in this court may still tell a voter it is filled.
  SELECT count(*) INTO v_filled
    FROM essentials.offices o JOIN rc_bench b ON b.office_id = o.id
   WHERE o.description LIKE '%this one is filled%';
  IF v_filled <> 0 THEN
    RAISE EXCEPTION 'CC_0389 gate: % description(s) still say the seat is filled', v_filled;
  END IF;

  SELECT o.is_vacant, o.vacant_since, o.description
    INTO v_d1_flag, v_d1_since, v_d1_desc
    FROM essentials.offices o JOIN rc_bench b ON b.office_id = o.id
   WHERE b.office_title = 'Municipal Court Judge, Department 1';
  IF v_d1_flag IS NOT TRUE THEN
    RAISE EXCEPTION 'CC_0389 gate: Department 1 lost its flag. Unseated and unflagged is invisible '
                    'from every Reno address and turns the reachability gate red on the next merge.';
  END IF;
  IF v_d1_since IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0389 gate: Department 1 acquired a vacant_since of %. No source publishes '
                    'one; a Substack report is a lead, not a citation.', v_d1_since;
  END IF;
  IF v_d1_desc IS NULL OR v_d1_desc NOT LIKE '%has no judge%' THEN
    RAISE EXCEPTION 'CC_0389 gate: Department 1 does not say it is empty';
  END IF;

  -- 🔴 An unofficial count is not an officeholder. Neither candidate may be named to a voter.
  SELECT count(*) INTO v_names
    FROM essentials.offices o JOIN rc_bench b ON b.office_id = o.id
   WHERE o.description ILIKE ANY (ARRAY['%Gianoli%','%Hubach%','%Drakulich%']);
  IF v_names <> 0 THEN
    RAISE EXCEPTION 'CC_0389 gate: % description(s) name a candidate or the former judge', v_names;
  END IF;

  -- 🔴 Namesakes: no pre-existing person may have been seated on this bench.
  SELECT count(*) INTO v_outsider
    FROM essentials.office_terms t
    JOIN rc_bench b ON b.office_id = t.office_id
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.source IS NULL OR p.source NOT LIKE 'CC_0389 %';
  IF v_outsider <> 0 THEN
    RAISE EXCEPTION 'CC_0389 gate: % pre-existing person(s) were seated on the Reno bench. '
                    'P. K. O''Neill, Richard W. O''Neill, David O''Neill, Brian J. O''Neill and '
                    'Dawn Champagne are namesakes, not these judges.', v_outsider;
  END IF;

  -- 🔴 The drift metric, as a DELTA captured inside this transaction.
  SELECT total, flagged, unflagged INTO b_total, b_flagged, b_unflagged FROM rc_baseline;
  SELECT count(*),
         count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE NOT o.is_vacant)
    INTO a_total, a_flagged, a_unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;

  IF a_unflagged <> b_unflagged THEN
    RAISE EXCEPTION 'CC_0389 gate: the UNFLAGGED baseline moved % -> %. Seating flagged seats must '
                    'leave it alone; it falls only by seating a seat that was unflagged.',
                    b_unflagged, a_unflagged;
  END IF;
  IF a_flagged <> b_flagged - 3 THEN
    RAISE EXCEPTION 'CC_0389 gate: expected the flagged bucket to fall by 3 (% -> %), found %',
                    b_flagged, b_flagged - 3, a_flagged;
  END IF;
  IF a_total <> b_total - 3 THEN
    RAISE EXCEPTION 'CC_0389 gate: expected the view total to fall by 3 (% -> %), found %',
                    b_total, b_total - 3, a_total;
  END IF;

  RAISE NOTICE 'CC_0389 OK: 3 judges seated undated · 3 flags cleared · 3 descriptions removed · '
               'Dept 1 vacant, flagged, undated and corrected · unflagged baseline % held · '
               'flagged % -> % · total % -> %',
               a_unflagged, b_flagged, a_flagged, b_total, a_total;
END $$;

COMMIT;
