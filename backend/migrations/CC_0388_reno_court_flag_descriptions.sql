-- CC_0388_reno_court_flag_descriptions.sql
-- Reno Municipal Court — the four departments are flagged vacant and are NOT vacant. This
-- migration writes the explanation the flag cannot carry. NO FLAG IS CLEARED AND NO PERSON
-- IS SEATED.
--
-- ═══ 🔴🔴 AN UNDATED FLAG ASSERTS A VACANCY TO VOTERS, AND THESE FOUR SEATS ARE FILLED ═══
--
-- CC_0387 seated 13 people across Reno and Washoe County and deliberately left the four
-- Municipal Court departments empty, because the sources name different judges. Its own gate
-- enforces that ("% municipal judge(s) seated; the bench is unresolved"), and that judgement
-- was right: an aggregator contradicting the state's own directory is not a basis for seating
-- a judge.
--
-- But an unseated office has to be flagged `is_vacant` or it disappears — `buildStatewideQuery`
-- ends with `AND (p.is_active = true OR o.is_vacant = true)`, so unseated AND unflagged is
-- invisible from every Reno address, and it would also raise the 238 unflagged drift baseline,
-- which CLAUDE.md forbids. So the flag is correct and load-bearing. What it says to a voter is
-- not: the Reno Municipal Court bench is sitting, and the profile reads "vacant, date unknown".
--
-- `essentials.offices.description` is the only field that can hold the difference, and it IS
-- rendered — `districtQueries.ts` selects `o.description AS office_description` on the address
-- path, and `essentialsService.ts` shows it on the ?q= list and detail paths. This is the
-- CC_0299 shape: explain the flag, do not date it.
--
-- ═══ 🔴 WHY NO `vacant_since` IS WRITTEN ═══
--
-- `vacant_since` is the first day the seat was EMPTY. These seats are not empty, so any date
-- here would be a false claim with a citation-shaped field around it. The four stay in the
-- UNDATED flagged sub-bucket on purpose, and the description says which of the four kinds they
-- are, which is the thing CC_0298 had to re-derive one row at a time for 41 older flags because
-- nobody wrote it down at the time. These are three days old and the reason is still known.
--
-- ═══ 🔴 WHY NO FLAG IS CLEARED ═══
--
-- Clearing `is_vacant` on an unseated office hides it from address search and turns the
-- master-only reachability gate red on whoever merges next (DEAD_GEOGRAPHY for a district with
-- `active_holders = 0 AND vacant_offices = 0`). It would also take the unflagged baseline from
-- 238 to 242. The honest fix for the flag is to SEAT the judges; this migration does not
-- pretend to be that fix, and the ▶ below says what that work needs.
--
-- ═══ THE VALUES THIS MIGRATION OVERWRITES ═══
--
-- Measured against production 2026-11-10, immediately before writing this file:
--
--   office                                 description   is_vacant  vacant_since
--   Municipal Court Judge, Department 1     NULL          true       NULL
--   Municipal Court Judge, Department 2     NULL          true       NULL
--   Municipal Court Judge, Department 3     NULL          true       NULL
--   Municipal Court Judge, Department 4     NULL          true       NULL
--
-- All four descriptions are NULL, so this migration destroys no prior text. `is_vacant` and
-- `vacant_since` are not touched by any statement below; they are listed because they are the
-- companions of the column being written and a reader three months from now cannot otherwise
-- tell whether this pass moved them.
--
-- ═══ WHAT EACH DEPARTMENT'S REASON ACTUALLY IS, AND WHERE IT IS NOT KNOWN ═══
--
--   Dept 1  on the ballot 2026-11-03, result unsettled when CC_0387 was written
--           (Gianoli v Hubach). Recorded in CC_0387's header.
--   Dept 2  sources disagree: the State of Nevada Judicial Directory (AOC, rev. 2026-03-17)
--           gives it to Randall Soderquist and places Shelly O'Neill at FALLON Municipal
--           Court; Ballotpedia puts O'Neill in Reno Dept 2. Recorded in CC_0387's header.
--   Dept 3  ⚠ NO REASON IS ON RECORD. CC_0387 says only "the bench is unresolved".
--   Dept 4  ⚠ NO REASON IS ON RECORD, same.
--
-- 🔴 SO DEPTS 3 AND 4 GET THE WEAKER, TRUER SENTENCE. It would be easy to give all four the
--    Dept 2 wording and read evenly; that would invent a source conflict for two seats where
--    none was ever recorded. A description is a voter-facing claim like any other.
--
-- ⚠ NO JUDGE IS NAMED IN ANY DESCRIPTION, including the names above. Naming the disputed
--   candidate in prose is seating them without the audit trail of seating them.
--
-- ═══ ▶ THE REAL FIX, AND WHAT IT NEEDS ═══
--
-- The chamber's own roster outranks every aggregator and would settle all four at once. It
-- could not be reached on 2026-11-10. Recorded so the next reader does not repeat it:
--
--   https://reno.gov/government/municipal-court/judges                      HTTP 404
--   https://www.reno.gov/government/municipal-court                         HTTP 404
--   https://www.reno.gov/government/departments/municipal-court             HTTP 404
--   https://www.reno.gov/government/departments/municipal-court/about-the-court/judges  HTTP 404
--
-- ⚠ These are REAL 404s, not a WAF: the same 404 comes back in a full Playwright browser, and
--   the three ~186 KB bodies are the city's own styled error page. A search engine still
--   indexes the /government/municipal-court/judges path, so the site was restructured and the
--   index is stale. Find the current path, or ask the City Clerk.
--
-- ▶ Once the roster is in hand: seat the four judges, clear `is_vacant` in the SAME migration
--   (seat_officeholder does NOT clear it), and DELETE these four descriptions — they describe
--   an absence that will no longer exist. Same obligation CC_0299's descriptions carry.
--
-- ═══ IDEMPOTENT ═══
-- Every UPDATE is guarded on the office still having no description, so a re-run writes nothing
-- and the post-verify still passes.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- Guard: the four offices must exist, in exactly one chamber, before anything is written.
-- Keyed on chamber name + title rather than UUID so the file reads and reviews, and so a
-- wrong-environment run fails loudly instead of updating nothing in silence.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_chambers int;
  v_offices  int;
  v_seated   int;
BEGIN
  SELECT count(*) INTO v_chambers
    FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE c.name = 'Reno Municipal Court' AND g.geo_id = '3260600' AND g.mtfcc = 'G4110';
  IF v_chambers <> 1 THEN
    RAISE EXCEPTION 'CC_0388 pre-check: expected 1 Reno Municipal Court chamber, found %', v_chambers;
  END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Reno Municipal Court'
     AND o.title LIKE 'Municipal Court Judge, Department %';
  IF v_offices <> 4 THEN
    RAISE EXCEPTION 'CC_0388 pre-check: expected 4 departments, found %', v_offices;
  END IF;

  -- If somebody has seated the bench since 2026-11-10, this migration is the wrong act:
  -- the descriptions would tell a voter nobody is recorded while a name renders beside them.
  SELECT count(t.politician_id) INTO v_seated
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Reno Municipal Court';
  IF v_seated <> 0 THEN
    RAISE EXCEPTION 'CC_0388 pre-check: % judge(s) now seated — seat the bench and DELETE these descriptions instead', v_seated;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Department 1 — the seat was on the ballot and the count was not settled.
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices o
   SET description = 'Reno Municipal Court has four elected departments, and this one is filled. '
                  || 'Empowered Vote has not recorded who holds it. The department was on the ballot '
                  || 'on 3 November 2026 and the result was not settled when this record was written. '
                  || 'We will name the judge once the City declares the result.'
  FROM essentials.chambers c
 WHERE c.id = o.chamber_id
   AND c.name = 'Reno Municipal Court'
   AND o.title = 'Municipal Court Judge, Department 1'
   AND coalesce(o.description, '') = '';

-- ─────────────────────────────────────────────────────────────────────────────
-- Department 2 — two published sources name different judges.
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices o
   SET description = 'Reno Municipal Court has four elected departments, and this one is filled. '
                  || 'Empowered Vote has not recorded who holds it. Published sources disagree: the '
                  || 'State of Nevada Judicial Directory and Ballotpedia name different judges for '
                  || 'this department. We will name the judge once the court''s own roster settles it.'
  FROM essentials.chambers c
 WHERE c.id = o.chamber_id
   AND c.name = 'Reno Municipal Court'
   AND o.title = 'Municipal Court Judge, Department 2'
   AND coalesce(o.description, '') = '';

-- ─────────────────────────────────────────────────────────────────────────────
-- Departments 3 and 4 — no reason is on record beyond "not yet confirmed". Say that.
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices o
   SET description = 'Reno Municipal Court has four elected departments, and this one is filled. '
                  || 'Empowered Vote has not recorded who holds it, because we have not yet '
                  || 'confirmed the judge against the court''s own roster. We will name the judge '
                  || 'once we have.'
  FROM essentials.chambers c
 WHERE c.id = o.chamber_id
   AND c.name = 'Reno Municipal Court'
   AND o.title IN ('Municipal Court Judge, Department 3', 'Municipal Court Judge, Department 4')
   AND coalesce(o.description, '') = '';

-- ─────────────────────────────────────────────────────────────────────────────
-- Post-verify. Gates on the END STATE and on the DELTA this file is responsible for:
-- four described departments, four still flagged, zero dated, zero seated, and the
-- unflagged drift baseline untouched at 238.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_described int;
  v_distinct  int;
  v_flagged   int;
  v_dated     int;
  v_seated    int;
  v_named     int;
  v_unflagged int;
BEGIN
  SELECT count(*) FILTER (WHERE coalesce(o.description, '') <> ''),
         count(DISTINCT o.description),
         count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE o.vacant_since IS NOT NULL)
    INTO v_described, v_distinct, v_flagged, v_dated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Reno Municipal Court';

  IF v_described <> 4 THEN
    RAISE EXCEPTION 'CC_0388 gate: expected 4 described departments, found %', v_described;
  END IF;

  -- 🔴 Three distinct sentences, not one. If this reads 1 the file has given Depts 3 and 4 a
  -- source conflict that was never recorded for them, which is the specific error this
  -- migration exists to avoid making.
  IF v_distinct <> 3 THEN
    RAISE EXCEPTION 'CC_0388 gate: expected 3 distinct descriptions (Dept 1, Dept 2, Depts 3+4), found %', v_distinct;
  END IF;

  IF v_flagged <> 4 THEN
    RAISE EXCEPTION 'CC_0388 gate: expected 4 departments still flagged is_vacant, found % — this file must not clear a flag', v_flagged;
  END IF;

  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'CC_0388 gate: expected 0 vacant_since dates, found % — these seats are not empty', v_dated;
  END IF;

  SELECT count(t.politician_id) INTO v_seated
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Reno Municipal Court';
  IF v_seated <> 0 THEN
    RAISE EXCEPTION 'CC_0388 gate: expected 0 seated judges, found % — this file seats nobody', v_seated;
  END IF;

  -- 🔴 No description may name a person. The disputed names are in this file's header, where
  -- they are a note to the next editor; in the voter-facing column they would be a claim.
  SELECT count(*) INTO v_named
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Reno Municipal Court'
     AND (o.description ILIKE '%Soderquist%' OR o.description ILIKE '%O''Neill%'
       OR o.description ILIKE '%Gianoli%'    OR o.description ILIKE '%Hubach%');
  IF v_named <> 0 THEN
    RAISE EXCEPTION 'CC_0388 gate: % description(s) name a judge', v_named;
  END IF;

  -- The drift baseline must not move. This file writes prose, nothing else.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN
    RAISE EXCEPTION 'CC_0388 gate: unflagged drift baseline is %, expected 238', v_unflagged;
  END IF;

  RAISE NOTICE 'CC_0388 OK: 4 departments described (3 distinct), 4 still flagged, 0 dated, 0 seated, baseline 238';
END $$;

COMMIT;
