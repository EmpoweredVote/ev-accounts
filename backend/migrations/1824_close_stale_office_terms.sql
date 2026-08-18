-- 1824_close_stale_office_terms.sql
--
-- Close the six open-ended essentials.office_terms rows whose holder has demonstrably left
-- the office. Idempotent (guarded on term_end IS NULL; a re-run touches 0 rows).
--
-- WHY: essentials.office_current_holder is a VIEW over current_office_holders, which is a VIEW
--   over office_terms filtered on
--       (term_start IS NULL OR term_start <= CURRENT_DATE)
--   AND (term_end   IS NULL OR term_end   >= CURRENT_DATE)
--   A term row with term_end NULL therefore reports its holder as the CURRENT occupant forever.
--   These six people left office between 2021 and 2026, so every consumer that asks "who holds
--   this office" gets a stale answer. You cannot fix this by deleting from the views.
--
-- ROOT CAUSE: all six rows carry
--   source = 'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'
--   and created_at 2026-07-26. Migration 1459 moved occupancy off offices.politician_id onto
--   office_terms, but the old column held only a pointer — no dates — so the backfill could only
--   write term_start NULL / term_end NULL. Every row it produced is open-ended by construction.
--   This migration closes the six that are provably wrong; it does NOT audit the rest of 1459's
--   output, which is a larger sweep worth doing separately.
--
-- RELATIONSHIP TO 1802: 1802_reactivate_current_officeholders.sql re-activated the only two rows
--   that were is_active = false while genuinely still in office (Daniel Webster, Patrice
--   Lattimore). It deliberately did NOT touch these six, because for them is_active = false is
--   CORRECT and the stale thing is the term row — exactly what this migration fixes. The two
--   changes are complementary: 1802 fixed the flag, 1824 fixes the dates.
--
-- WHY THIS IS SAFE / NOT USER-VISIBLE: the public "who represents me" feed
--   (backend/src/lib/essentialsService.ts :774 and :840) gates on
--       AND (p.is_active = true OR o.is_vacant = true)
--   All six politicians are already is_active = false, so the seat is ALREADY excluded from the
--   feed today. Closing the term changes how the row is excluded (no current holder, rather than
--   an inactive one), not whether. Verified before authoring: each of the six offices holds
--   EXACTLY ONE office_terms row — the stale one — so no successor term exists that this could
--   collide with, and the office_terms_no_overlap EXCLUDE constraint cannot fire.
--
--   Deliberately NOT setting offices.is_vacant = true. These seats are not vacant — each has a
--   real successor (below) who is simply not modelled yet. Flipping is_vacant would publish them
--   on the live feed as vacant seats, which is a different and wrong claim.
--
-- TERM_END IS INCLUSIVE in this schema: the view tests term_end >= CURRENT_DATE, and
--   office_terms_no_overlap uses daterange(term_start, term_end, '[]'). So term_end is the last
--   day the person held the office, and the dates below are last-day-in-office, not day-after.
--
-- THE SIX, each verified individually against an authoritative source (2026-08-17):
--
--   Shruti Rana        450800  Bloomington Common Council D5   2024-02-07  resigned
--     Resignation effective Feb. 7 2024 (announced 2024-01-13) to take posts at the University
--     of Missouri. Courtney Daily won the 2024-03-02 Democratic caucus for the seat.
--     (essentials.politicians.valid_to already reads 2024-03-01 — the caucus date, not her last
--     day; the term row is the authoritative field and gets the resignation date.)
--     Source: bsquarebulletin.com/rana-to-step-down-from-bloomington-city-council-academic-
--     couple-to-move-to-university-of-missouri/
--
--   James Kirsch       206174  Indiana Court of Appeals D2     2021-09-23  retired
--     Retired 2021-09-23, three months short of the mandatory retirement age of 75; succeeded by
--     Derek R. Molter. (Kirsch has since died — but the term ended at retirement, not at death,
--     so how_ended is 'retired'.)
--     Source: theindianalawyer.com/articles/judge-james-kirsch-announces-retirement-from-indiana-
--     court-of-appeals
--
--   Patricia A Riley   206176  Indiana Court of Appeals D4     2024-08-30  retired
--     "Judge Patricia A. Riley will retire from the Court of Appeals of Indiana on August 30,
--     2024" — the court's own release. Continued as a senior judge, which is a different role
--     and NOT this office.
--     Source: in.gov/courts/appeals/news/2024-0618/
--
--   Dan Combs          393382  Perry Township Trustee (Monroe) 2026-01-06  died
--     Died in office 2026-01-06, aged 73, after 40 years as trustee. Monroe County Democrats
--     caucused 2026-01-31 and seated Leon Gordon to serve through the end of 2026.
--     Source: ipm.org/2026-01-06/dan-combs-perry-township-trustee-since-1986-dies
--
--   Kristi Noem        642537  Secretary of Homeland Security  2026-03-31  removed
--     Sworn in 2025-01-25; removal announced 2026-03-05; last day at the department 2026-03-31.
--     DATE CHOICE (deliberate, Chris's call 2026-08-17): there are two defensible dates here.
--     Markwayne Mullin was confirmed and sworn in as her successor on 2026-03-24, so the OFFICE
--     arguably transferred on the 24th; but her formal departure — and the date essentially all
--     press coverage reports as her last day — is 2026-03-31. We use 2026-03-31 so the record
--     reconciles against news coverage. Practical impact is nil: both dates are long past, so
--     the view excludes her either way, and no successor term exists to overlap with. If Mullin
--     is ever seated on this office with a term_start of 2026-03-24, the office_terms_no_overlap
--     EXCLUDE constraint WILL reject it against this row's daterange — close this term to
--     2026-03-23 at that point, or start his at 2026-04-01.
--     She subsequently became Special Envoy for the Shield of the Americas, a different office
--     not modelled here.
--     Sources: 19thnews.org/2026/03/trump-replaces-kristi-noem-homeland-security/ (last day
--     March 31); npr.org/2026/03/24/nx-s1-5757989/markwayne-mullin-confirmed-as-the-next-
--     secretary-of-homeland-security (Mullin sworn in March 24)
--
--   Pamela Bondi       642364  Attorney General                2026-04-02  removed
--     87th Attorney General, sworn in 2025-02-05, fired 2026-04-02; Deputy AG Todd Blanche
--     became acting Attorney General.
--     Source: en.wikipedia.org/wiki/Pam_Bondi ; npr.org/2026/04/02/g-s1-115077/trump-bondi-
--     attorney-general-departure
--
-- how_ended uses the office_terms_how_ended_check vocabulary
--   {term_expired, resigned, defeated, retired, died, recalled, removed, redistricted, unknown}.
--   Noem and Bondi are 'removed' (both dismissed by the President), not 'resigned'.
--
-- term_start is deliberately left NULL. It is unknown for four of the six, and this migration is
--   scoped to closing the terms; back-filling starts is a separate, better-sourced pass.
--
-- SUCCESSORS ARE NOT SEATED HERE. After this runs each of the six offices has zero current
--   holders. Seating Mullin, Blanche, Molter, Gordon, Daily and Riley's successor means creating
--   or linking politician rows and is a larger, separate piece of work.

BEGIN;

-- ---------------------------------------------------------------------------
-- Target table, resolved by external_id (stable; UUIDs are environment-specific)
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE close_terms ON COMMIT DROP AS
SELECT v.person, v.term_end::date AS term_end, v.how_ended, t.id AS term_id, t.office_id
FROM (VALUES
  ('Shruti Rana',      450800::bigint, '2024-02-07', 'resigned'),
  ('James Kirsch',     206174,         '2021-09-23', 'retired'),
  ('Patricia A Riley', 206176,         '2024-08-30', 'retired'),
  ('Dan Combs',        393382,         '2026-01-06', 'died'),
  ('Kristi Noem',      642537,         '2026-03-31', 'removed'),
  ('Pamela Bondi',     642364,         '2026-04-02', 'removed')
) AS v(person, ext, term_end, how_ended)
JOIN essentials.politicians p ON p.external_id = v.ext
JOIN essentials.office_terms t ON t.politician_id = p.id;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM close_terms;
  IF n <> 6 THEN
    RAISE EXCEPTION 'expected 6 term rows to close, resolved % — external_ids or term rows changed', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT 1: each target office must hold exactly ONE term row. If a successor term has
-- appeared since this was authored, the no-overlap picture has changed and a blind close could
-- be wrong (or the successor already supersedes this row) — fail loudly instead.
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record; n int;
BEGIN
  FOR r IN SELECT * FROM close_terms LOOP
    SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = r.office_id;
    IF n <> 1 THEN
      RAISE EXCEPTION '% : office % holds % term rows, expected exactly 1 — a successor term '
                      'may already exist; review before closing', r.person, r.office_id, n;
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT 2: every term_end being written must be in the PAST. A future date would leave the
-- row still reporting as current and silently achieve nothing.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM close_terms WHERE term_end >= CURRENT_DATE;
  IF n <> 0 THEN
    RAISE EXCEPTION '% target term_end value(s) are not in the past', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- THE WRITE. Enumerated by external_id, never predicate-driven. Guarded on term_end IS NULL so a
-- re-run is a no-op and cannot overwrite a date someone has since corrected by hand.
-- ---------------------------------------------------------------------------
UPDATE essentials.office_terms t
   SET term_end   = c.term_end,
       how_ended  = c.how_ended,
       source     = t.source || ' | term closed by migration 1824 on 2026-08-17 (holder left '
                    || 'office ' || c.term_end::text || ', ' || c.how_ended || '); 1459''s '
                    || 'backfill could not supply dates'
  FROM close_terms c
 WHERE t.id = c.term_id
   AND t.term_end IS NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r record;
  n int;
BEGIN
  -- Every target term is closed, with the exact date and reason intended.
  FOR r IN SELECT * FROM close_terms LOOP
    IF NOT EXISTS (
      SELECT 1 FROM essentials.office_terms
       WHERE id = r.term_id AND term_end = r.term_end AND how_ended = r.how_ended
    ) THEN
      RAISE EXCEPTION '% : term row % did not close to % / %', r.person, r.term_id, r.term_end, r.how_ended;
    END IF;
  END LOOP;

  -- THE POINT: none of the six may still resolve as a current office holder.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och
    JOIN close_terms c ON c.office_id = och.office_id
   WHERE och.politician_id IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '% of the six still report as current holders', n;
  END IF;

  -- The diagnostic that started this work — inactive politicians still holding a titled office —
  -- must drop to exactly 2: Gary Crockett and John Fleming, who hold fake
  -- "Candidate for U.S. Senate — Louisiana" offices and are tracked as separate follow-ups.
  SELECT count(*) INTO n
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE p.is_active = false AND COALESCE(o.title, '') <> '';
  IF n <> 2 THEN
    RAISE EXCEPTION 'expected 2 inactive-officeholder rows to remain, found %', n;
  END IF;

  -- 1802 must not be disturbed: Webster and Lattimore stay active current officeholders.
  SELECT count(*) INTO n
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
   WHERE p.external_id IN (-12011, -700002) AND p.is_active;
  IF n <> 2 THEN
    RAISE EXCEPTION 'migration 1802''s two reactivated officeholders no longer resolve (found %)', n;
  END IF;

  -- No politician row's is_active was touched by this migration.
  SELECT count(*) INTO n
    FROM essentials.politicians p
   WHERE p.external_id IN (450800, 206174, 206176, 393382, 642537, 642364) AND p.is_active;
  IF n <> 0 THEN
    RAISE EXCEPTION '% of the six politicians are unexpectedly active', n;
  END IF;

  RAISE NOTICE 'Stale term close PASSED: 6 open-ended office_terms rows closed with sourced '
               'dates + how_ended; 0 still report as current holders; inactive-officeholder '
               'diagnostic now 2 (Crockett, Fleming); 1802 intact.';
END $$;

COMMIT;
