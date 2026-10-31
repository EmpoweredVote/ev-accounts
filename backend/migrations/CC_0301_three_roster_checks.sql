-- CC_0301: the last three rows of the CC_0298 triage, checked against each body's own roster.
-- They came out three different ways, which is the point of checking one at a time.
--
-- `CC_0298` ended with three offices it classified as "unseeded, emptiness unproven — a roster
-- check, not a date". All three are now checked, and no two needed the same thing:
--
--   1. Three Valleys MWD, Division 3     REAL vacancy, and the district PUBLISHES THE DATE
--                                        -> write vacant_since = 2026-06-03
--   2. Torrance Unified, Trustee Area D  REAL vacancy, date NOT published
--                                        -> explain it, leave vacant_since NULL
--   3. Caledonia WI, Village Trustee 2   NOT VACANT — Paula Pintar holds it
--                                        -> seat her, clear the flag
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- 1. THREE VALLEYS MUNICIPAL WATER DISTRICT, DIVISION 3  —  a vacancy with a published date
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- https://www.threevalleys.com/board-of-directors/ , read 2026-10-27. The district lists its
-- seven divisions and division III reads, in full: **"Vacant Effective June 3, 2026"**.
-- The other six match this database exactly, name for name and term for term:
--   I Carlos Goytia (Dec 2022) · II David De Jesus (Dec 2024) · IV Bob Kuhn (Dec 2024) ·
--   V Jody Roberto (Dec 2022) · VI Jorge Marquez (Dec 2024) · VII Mike Ti (Dec 2024)
--
-- 🔴 THIS DATE IS NOT ADJUSTED BY ONE, AND `CC_0298`'s DATES WERE. That is not an inconsistency,
-- it is the difference between two kinds of source. `vacant_since` is the FIRST DAY THE SEAT WAS
-- EMPTY. Ballotpedia's column gives the DEPARTURE date — the member's last day — so `CC_0298`
-- wrote departure + 1. This source gives the date the vacancy TAKES EFFECT, which is already the
-- first empty day. ▶ Read what the source's date is a date OF before adjusting it.
--
-- ⚠ A false negative worth recording: the first scan of that page asked for "Division 3" and
-- reported the division absent. The page uses ROMAN NUMERALS. The seat was there all along under
-- "Division III". A narrow pattern is how a present fact reads as a missing one.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- 2. TORRANCE UNIFIED, TRUSTEE AREA D  —  a vacancy whose date nobody publishes
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- https://www.tusd.org/boe , read 2026-10-27. The district's own board contact list reads
-- "Position Vacant / Trustee Area D", alongside James Han (C), Dave Zygielbaum (E),
-- Dr. Anil Muhammed (A) and Catherine "Cat" Bones (B) — exactly the four this database seats.
-- Its per-member page for the seat (/boe/people/657136/betty-lieu) is titled "Position Vacant"
-- and carries no date; the district publishes the vacancy and not the day it began.
--
-- So this one gets the Richland County SC treatment: flagged, undated, and SAYING WHY in its
-- description, which is the shape CLAUDE.md asks for when a date is genuinely unpublished.
-- ⚠ The description deliberately does NOT name the former holder or a cause. Secondary sources
-- say the seat opened when Betty Lieu was elected to the Torrance City Council, and the
-- district's own pages disagree with each other about her — one still lists her in the seat. An
-- unsourced cause written into a voter-facing field is the thing this repo keeps paying for.
--
-- ⚠ This office's only term row is Terry Ragins 2003-01-01..2020-12-14, closed by CA_0150 as
-- STALE with the end date set to a successor's start, not researched. It is not evidence about
-- the current vacancy and is left exactly as it is.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- 3. VILLAGE OF CALEDONIA WI, TRUSTEE SEAT 2  —  not vacant at all
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- The village's published roster (https://www.caledonia-wi.gov/board) lists seven people for its
-- seven positions — six trustees and the president — and every record maps one-to-one:
--   President Prescott Balch · 1 Nancy Pierce · **2 PAULA PINTAR** · 3 Michael Lambrecht ·
--   4 Fran Martin · 5 Holly McManus · 6 Lee Wishau
-- Six of those seven are already seated here. Seat 2 is the one this database called vacant.
--
-- WHEN: The Journal Times, 2026-08-05, "Caledonia Village Board fills vacant trustee seat":
--   "Village Clerk Jennifer Bass ... swore in Paula Pintar as Caledonia Trustee No. 2 on Tuesday
--    following Pintar's selection by the Village Board."
--   "Pintar took the oath of office and will assume her role on the board at the next meeting,
--    which is scheduled for 6 p.m. Aug. 18."
--   "She will serve the remainder of the term, which expires in April 2028."
-- The article is dated Wednesday 2026-08-05, so "Tuesday" is 2026-08-04 (checked: 2026-08-04 is
-- a Tuesday, and the board meets the first and third Tuesday of each month).
-- 🟢 `term_start` is the OATH (2026-08-04), not her first sitting (2026-08-18). Taking the oath
-- is holding the office; attending is not. Both dates are in the term's source text so a later
-- reader can see the choice rather than guess at it.
--
-- 🟢 The same article explains the vacancy this database was carrying: the seat "was left vacant
-- following Prescott Balch's appointment as village president" — and Balch is exactly who this
-- database already has as Caledonia's Village President. The flag was correct when it was set and
-- went stale when the board filled the seat.
--
-- ⚠ No predecessor term is written for Balch on Seat 2. Every Caledonia term row here has a NULL
-- `term_start` already; inventing one to close would be a guess, and seat_officeholder has
-- nothing to close because the seat has no term at all.
--
-- ⚠ Reaching that roster took a redirect and a third-party module: caledonia-wi.gov 301s to the
-- www host (Playwright reported it as a navigation failure, which reads like a block and is not
-- one), and the people list is injected from app.membershipware.com rather than being in the
-- page HTML.
--
-- EXPECTED MOVEMENT, measured 2026-10-27 before running:
--   offices is_vacant            64 -> 63   (Caledonia was never vacant)
--           flagged and undated  24 -> 22   (Caledonia leaves; Three Valleys gains a date)
--           flagged and dated    40 -> 41
--   offices_missing_terms  294 / 56 / 238 -> 293 / 55 / 238
--   🟢 The 238 unflagged DRIFT BASELINE does not move: Caledonia's seat was in the FLAGGED bucket.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Pre-flight.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad text;
BEGIN
  -- All three must still be flagged, undated, and the shape each was researched as.
  SELECT string_agg(format('%s: vac=%s since=%s terms=%s descr=%L',
                           d.label, o.is_vacant, o.vacant_since,
                           (SELECT count(*) FROM essentials.office_terms t WHERE t.office_id = o.id),
                           left(coalesce(o.description, ''), 30)), E'\n  ')
    INTO bad
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.id IN ('424d30d7-914c-5d77-9ad4-e40b74b140be',   -- Three Valleys MWD Division 3
                  'cf414a7e-6c18-4697-8c9d-67f18f8bfb39',   -- Torrance Unified Trustee Area D
                  '85f8dbe0-aa70-4104-83c1-955cb6663dd4')   -- Caledonia WI Village Trustee Seat 2
     AND (o.is_vacant IS DISTINCT FROM true
          OR o.vacant_since IS NOT NULL
          OR coalesce(o.description, '') <> '');
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: a target is not flagged-undated-undescribed:%s  %s', E'\n  ', bad;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices
   WHERE id IN ('424d30d7-914c-5d77-9ad4-e40b74b140be','cf414a7e-6c18-4697-8c9d-67f18f8bfb39',
                '85f8dbe0-aa70-4104-83c1-955cb6663dd4');
  IF n <> 3 THEN RAISE EXCEPTION 'PRE-FLIGHT: expected 3 target offices, found %', n; END IF;

  -- Caledonia: the seat must be unheld and term-less, and the other six positions seated. That
  -- is what makes "Pintar is the missing seventh" a measurement rather than a guess.
  IF EXISTS (SELECT 1 FROM essentials.office_terms
              WHERE office_id = '85f8dbe0-aa70-4104-83c1-955cb6663dd4') THEN
    RAISE EXCEPTION 'PRE-FLIGHT: the Caledonia seat already has a term row';
  END IF;
  SELECT count(*) INTO n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Village of Caledonia, Wisconsin, US' AND och.politician_id IS NOT NULL;
  IF n <> 6 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: expected 6 seated Caledonia positions, found % — re-read '
                    'https://www.caledonia-wi.gov/board', n;
  END IF;

  -- 🔴 The duplicate-person sweep the repo's guard cannot do: it keys on (first_name, last_name),
  -- so an identical full_name split differently is invisible, as are archived rows.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE full_name ILIKE '%pintar%'
      OR (first_name ILIKE 'paula%' AND last_name ILIKE '%pintar%');
  IF n <> 0 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: % existing row(s) may already be Paula Pintar — read them first', n;
  END IF;

  -- external_id is UNIQUE and a collision seats the wrong person silently. Caledonia occupies
  -- -5526001..-5526006 (six seated), so -5526007 is next in that block.
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -5526007) THEN
    RAISE EXCEPTION 'PRE-FLIGHT: external_id -5526007 is taken';
  END IF;
END $$;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices WHERE is_vacant)                            AS vac_total,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL)   AS undated,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NOT NULL) AS dated,
       (SELECT count(*) FROM essentials.office_terms)                                       AS terms_total,
       (SELECT count(*) FROM essentials.politicians)                                        AS people_total,
       (SELECT count(*) FROM essentials.offices WHERE coalesce(description,'') <> '')       AS with_descr,
       (SELECT count(*) FROM essentials.offices_missing_terms)                              AS omt_total,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE o.is_vacant)                AS omt_flagged,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)            AS omt_unflagged,
       NOT EXISTS (SELECT 1 FROM essentials.office_terms
                    WHERE office_id = '85f8dbe0-aa70-4104-83c1-955cb6663dd4')               AS did_run;

-- ── 1. Three Valleys MWD Division 3: the date the district publishes. ────────────────────────
UPDATE essentials.offices
   SET vacant_since = DATE '2026-06-03'
 WHERE id = '424d30d7-914c-5d77-9ad4-e40b74b140be'
   AND is_vacant AND vacant_since IS NULL;

-- ── 2. Torrance Unified Trustee Area D: say why there is no date. ────────────────────────────
UPDATE essentials.offices
   SET description = 'This seat is vacant. The district lists it as "Position Vacant" on its '
                  || 'Board of Education page, and does not publish the date it became vacant, '
                  || 'so no start date is recorded here. The seat is on the ballot at the '
                  || 'election on 3 November 2026.'
 WHERE id = 'cf414a7e-6c18-4697-8c9d-67f18f8bfb39'
   AND coalesce(description, '') = '';

-- ── 3. Caledonia WI Trustee Seat 2: not vacant. Seat her. ────────────────────────────────────
-- 🔴 is_incumbent is named explicitly: it defaults to false since CA_0188 and a seated person
-- without it is HIDDEN from address search. check:occupancy fails an INSERT that omits it.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, source)
VALUES
  (-5526007, 'Paula Pintar', 'Paula', 'Pintar', true, true,
   'CC_0301: Village of Caledonia WI board roster (caledonia-wi.gov/board) + The Journal Times, '
   || '2026-08-05, "Caledonia Village Board fills vacant trustee seat"')
ON CONFLICT (external_id) DO NOTHING;

SELECT essentials.seat_officeholder(
         '85f8dbe0-aa70-4104-83c1-955cb6663dd4',
         (SELECT id FROM essentials.politicians WHERE external_id = -5526007),
         DATE '2026-08-04',
         'Sworn in as Caledonia Trustee No. 2 by Village Clerk Jennifer Bass on Tuesday '
         || '2026-08-04, after selection by the Village Board from 12 applicants; she first sat '
         || 'at the 2026-08-18 meeting. Appointed to the remainder of a term expiring April 2028 '
         || '(not written as term_end — see CC_0301). The seat was open because Prescott Balch, '
         || 'its previous holder, was appointed Village President. Source: The Journal Times, '
         || '2026-08-05.',
         'appointed',
         'day');

-- 🔴 seat_officeholder DOES NOT CLEAR is_vacant — only its mirror vacate_office syncs the flag.
-- Leaving it set would publish a seat that is both held and vacant (the is_vacant trap).
UPDATE essentials.offices
   SET is_vacant = false, vacant_since = NULL
 WHERE id = '85f8dbe0-aa70-4104-83c1-955cb6663dd4';

-- Keep the deprecated point-in-time snapshot consistent with her six colleagues, who all carry it.
UPDATE essentials.politicians
   SET office_id = '85f8dbe0-aa70-4104-83c1-955cb6663dd4'
 WHERE external_id = -5526007;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Post-verify.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE b record; n int; v record; d date; one int;
BEGIN
  SELECT * INTO b FROM _before;
  one := CASE WHEN b.did_run THEN 1 ELSE 0 END;

  -- (a) Three Valleys carries exactly the published date, and is still flagged.
  SELECT vacant_since INTO d
    FROM essentials.offices WHERE id = '424d30d7-914c-5d77-9ad4-e40b74b140be';
  IF d IS DISTINCT FROM DATE '2026-06-03' THEN
    RAISE EXCEPTION 'POST-VERIFY: Three Valleys Division 3 vacant_since is %, expected 2026-06-03', d;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.offices
                  WHERE id = '424d30d7-914c-5d77-9ad4-e40b74b140be' AND is_vacant) THEN
    RAISE EXCEPTION 'POST-VERIFY: Three Valleys Division 3 lost its vacancy flag — it IS vacant';
  END IF;

  -- (b) Torrance is described, and still flagged AND still undated. Describing a vacancy whose
  --     date is unpublished must not quietly invent one.
  IF NOT EXISTS (SELECT 1 FROM essentials.offices
                  WHERE id = 'cf414a7e-6c18-4697-8c9d-67f18f8bfb39'
                    AND is_vacant AND vacant_since IS NULL
                    AND description LIKE '%does not publish the date%') THEN
    RAISE EXCEPTION 'POST-VERIFY: Torrance Area D is not flagged-undated-and-described';
  END IF;

  -- (c) Caledonia is held by her, with the oath date, and is NOT flagged.
  SELECT p.full_name, p.is_active, p.is_incumbent, t.term_start, t.start_precision, t.how_started
    INTO v
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    JOIN essentials.office_terms t ON t.office_id = och.office_id AND t.politician_id = p.id
   WHERE och.office_id = '85f8dbe0-aa70-4104-83c1-955cb6663dd4';
  IF v IS NULL THEN
    RAISE EXCEPTION 'POST-VERIFY: nobody holds the Caledonia seat';
  END IF;
  IF (v.full_name, v.is_active, v.is_incumbent, v.term_start, v.start_precision, v.how_started)
       IS DISTINCT FROM ('Paula Pintar', true, true, DATE '2026-08-04', 'day', 'appointed') THEN
    RAISE EXCEPTION 'POST-VERIFY: Caledonia holder is % / active=% / incumbent=% / start=% / '
                    'precision=% / how_started=%',
                    v.full_name, v.is_active, v.is_incumbent, v.term_start, v.start_precision,
                    v.how_started;
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.offices
              WHERE id = '85f8dbe0-aa70-4104-83c1-955cb6663dd4'
                AND (is_vacant OR vacant_since IS NOT NULL)) THEN
    RAISE EXCEPTION 'POST-VERIFY: the Caledonia seat is held and still flagged vacant — the '
                    'is_vacant trap. seat_officeholder does not clear the flag.';
  END IF;

  SELECT count(*) INTO n FROM essentials.politicians
   WHERE full_name ILIKE '%pintar%' OR (first_name ILIKE 'paula%' AND last_name ILIKE '%pintar%');
  IF n <> 1 THEN
    RAISE EXCEPTION 'POST-VERIFY: % rows match Paula Pintar, expected 1 (ONE ROW PER PERSON)', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Village of Caledonia, Wisconsin, US' AND och.politician_id IS NOT NULL;
  IF n <> 7 THEN
    RAISE EXCEPTION 'POST-VERIFY: % seated Caledonia positions, expected 7', n;
  END IF;

  -- (d) The deltas. One vacancy withdrawn, one dated, one described, one term, one person.
  IF (b.vac_total - (SELECT count(*) FROM essentials.offices WHERE is_vacant)) IS DISTINCT FROM one THEN
    RAISE EXCEPTION 'POST-VERIFY: flagged total fell by %, expected %',
      b.vac_total - (SELECT count(*) FROM essentials.offices WHERE is_vacant), one;
  END IF;
  IF (b.undated - (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL))
       IS DISTINCT FROM 2 * one THEN
    RAISE EXCEPTION 'POST-VERIFY: undated fell by %, expected % (Caledonia leaves, Three Valleys dated)',
      b.undated - (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL),
      2 * one;
  END IF;
  IF ((SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NOT NULL) - b.dated)
       IS DISTINCT FROM one THEN
    RAISE EXCEPTION 'POST-VERIFY: dated rose by %, expected %',
      (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NOT NULL) - b.dated, one;
  END IF;
  IF ((SELECT count(*) FROM essentials.offices WHERE coalesce(description,'') <> '') - b.with_descr)
       IS DISTINCT FROM one THEN
    RAISE EXCEPTION 'POST-VERIFY: described offices rose by %, expected % — this writes ONE description',
      (SELECT count(*) FROM essentials.offices WHERE coalesce(description,'') <> '') - b.with_descr, one;
  END IF;
  IF ((SELECT count(*) FROM essentials.office_terms) - b.terms_total) IS DISTINCT FROM one
     OR ((SELECT count(*) FROM essentials.politicians) - b.people_total) IS DISTINCT FROM one THEN
    RAISE EXCEPTION 'POST-VERIFY: terms rose by % and people by %, expected % each',
      (SELECT count(*) FROM essentials.office_terms) - b.terms_total,
      (SELECT count(*) FROM essentials.politicians) - b.people_total, one;
  END IF;

  -- (e) 🔴 The occupancy metric moves the one honest way. Caledonia's seat was in the FLAGGED
  --     bucket, so total and flagged each fall by one and the 238 drift BASELINE does not move.
  IF ((b.omt_total - (SELECT count(*) FROM essentials.offices_missing_terms)),
      (b.omt_flagged - (SELECT count(*) FROM essentials.offices_missing_terms m
                          JOIN essentials.offices o ON o.id = m.office_id WHERE o.is_vacant)),
      ((SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant) - b.omt_unflagged))
     IS DISTINCT FROM (one, one, 0) THEN
    RAISE EXCEPTION 'POST-VERIFY: offices_missing_terms moved wrongly from % / % / %',
      b.omt_total, b.omt_flagged, b.omt_unflagged;
  END IF;

  RAISE NOTICE 'CC_0301 OK: flagged % -> %; undated % -> %; dated % -> %; '
               'offices_missing_terms % / % / % -> % / % / %',
    b.vac_total, (SELECT count(*) FROM essentials.offices WHERE is_vacant),
    b.undated, (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL),
    b.dated, (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NOT NULL),
    b.omt_total, b.omt_flagged, b.omt_unflagged,
    (SELECT count(*) FROM essentials.offices_missing_terms),
    (SELECT count(*) FROM essentials.offices_missing_terms m
       JOIN essentials.offices o ON o.id = m.office_id WHERE o.is_vacant),
    (SELECT count(*) FROM essentials.offices_missing_terms m
       JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant);
END $$;

COMMIT;
