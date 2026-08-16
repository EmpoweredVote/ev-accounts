-- 1789_cal_access_bucket_a_wrong_token.sql
-- cal_access bucket A: the 6 politicians whose committees were matched on a NON-SURNAME token.
-- Purges 518 links carrying $792,923.81. Keeps the 14 that genuinely name them.
--
-- ── THE DEFECT ────────────────────────────────────────────────────────────────────────────────────
-- `backend/scripts/confirm-cal-access.ts` links a Cal-Access committee to a politician when
-- `extractLastName(full_name)` -- **the LAST SPACE-DELIMITED TOKEN** -- appears as a whole word in the
-- committee name. `essentials.politicians.last_name` is stored on the same row and was ignored. For
-- anyone with a multi-word surname or a generational suffix the matched token is not their name at all:
--   Gracey Van Der Mark -> "mark" -> 381 committees containing the GIVEN NAME Mark
--   Jesse Avila Jr      -> "jr"   -> 115 committees containing the SUFFIX
--   Walter Allen III    -> "iii"  ->  25
-- Full audit, including the much larger bucket B, in memory `cal_access_lasttoken_mislinks`.
-- Surfaced by migration 1788 (the Robert Garcia / Antonio Vazquez conflation).
--
-- ── WHY THIS IS BUCKET A AND NOT THE WHOLE FIX ────────────────────────────────────────────────────
-- The audit split cal_access by comparing the last token of `full_name` against the stored
-- `last_name`:
--   A  last token <> stored surname .....    6 politicians,   532 links   (this migration)
--   B  last token  = stored surname .....  572 politicians, 7,321 links   (NOT touched here)
-- Bucket B is the larger problem and needs an operator decision -- a surname is not a person, so
-- Traci Park's correctly-matched "park" still picked up Buena Park, Menlo Park and East Bay Regional
-- Park District, and Ashley Johnson's "johnson" picked up Ray, Ben, Jimmie, Stephanie, Nancy and
-- Michael V. Johnson. **Do not extend this migration's logic to bucket B**: the test used here is
-- "the committee does not name this person at all", which is only decisive because the matched token
-- was never their name to begin with.
--
-- ⚠ AND DO NOT BUCKET BY COMMITTEE COUNT. Money and fan-out are only weakly correlated: Gavin Newsom
-- holds 24 cal_access committees and $10.7M, Rob Bonta 20 and $5.8M -- plausible real records for a
-- governor and an attorney general. Van Der Mark holds 381 and only $837K. A "purge everyone with
-- 10+ committees" rule would destroy correct data and recover little.
--
-- ── THE REFINEMENT THAT EARNED ITS PLACE ──────────────────────────────────────────────────────────
-- A blanket purge of all 532 would have been wrong. Strip the generational suffix from the stored
-- surname to a CORE surname (`avila jr` -> `avila`, `allen iii` -> `allen`, `van der mark` unchanged),
-- then keep any link whose committee name contains that core surname as a whole word:
--
--   Gracey Van Der Mark   381 links     3 keep   378 purge
--   Jesse Avila Jr        115 links     0 keep   115 purge
--   Walter Allen III       25 links     0 keep    25 purge
--   Jose Luis Solache Jr.   7 links     7 keep     0 purge
--   Eloy Morales Jr.        3 links     3 keep     0 purge
--   James T. Butts Jr.      1 link      1 keep     0 purge
--                                     ------     -----
--                                        14        518
--
-- The keeps are unmistakably theirs -- "VAN DER MARK FOR ASSEMBLY 2026; GRACEY", "MORALES JR.,
-- FRIENDS OF ELOY", "BUTTS FOR MAYOR 2026; JAMES", "SOLACHE FOR ASSEMBLY 2024; FRIENDS OF" -- and
-- carry $165,082.15 that is correctly attributed. The purges are unmistakably other people:
-- "ABRAMOWITZ FOR CITY COUNCIL, MARK", "ADAMS FOR SHERIFF 2010, FRIENDS OF MARK", "ALVAREZ FOR WATER
-- BOARD, MARK". 🔑 Without the suffix-stripping step all 14 keeps would have been purged, because
-- "avila jr" and "butts jr." appear in no committee name.
--
-- ── WHAT IS REMOVED ───────────────────────────────────────────────────────────────────────────────
-- 518 links demoted to `not_applicable` with a WRONG PERSON note -- NOT deleted, because the notes are
-- the only provenance of how the tangle arose (the person-merge recipe in migration 1661).
-- 180 contributions / 23 `contribution_summary_agg` rows / **$792,923.81** deleted outright.
-- ⚠ `contribution_summary_agg` is a real TABLE, not a view. Deleting contributions alone leaves the
-- UI displaying money whose contributions are gone, so both are deleted here.
-- ⚠ Money is deleted by LITERAL source ids. A DELETE joined to a fresh temp table seq-scans
-- `contributions` and times out -- the planner has no statistics for the temp table and ignores
-- `idx_transparent_motivations_contributions_politician_source_id`. The literal list is asserted below
-- to be exactly the money-bearing subset of the purge set, so the two cannot drift apart silently.
BEGIN;

-- ⚠ No global `count(*)` snapshot of `transparent_motivations.contributions`. That table is large
-- enough that a full count seq-scans and blows the statement timeout — the first attempt at this
-- migration died on exactly that, before reaching any of the work. Every before/after assertion
-- below is scoped to the affected ids instead, which is the meaningful claim anyway: a global delta
-- would also be satisfied by deleting 180 unrelated rows.

-- The classification, expressed once and reused by every step and guard below.
CREATE TEMP TABLE ca_bucket_a ON COMMIT DROP AS
SELECT ps.id AS sid,
       ps.essentials_politician_id AS pid,
       p.full_name,
       lower(coalesce(substring(ps.notes from '"committee_name"\s*:\s*"([^"]{0,120})'),'')) AS cmt,
       btrim(regexp_replace(lower(coalesce(p.last_name,'')), '\s+(jr\.?|sr\.?|ii|iii|iv)$', '')) AS core_surname
  FROM transparent_motivations.politician_sources ps
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
 WHERE ps.source_system = 'cal_access'
   AND p.is_active
   -- the defect: the token the script matched on is not the stored surname
   AND lower(regexp_replace(p.full_name, '^.*\s', '')) <> lower(coalesce(p.last_name,''));

CREATE TEMP TABLE ca_purge ON COMMIT DROP AS
SELECT * FROM ca_bucket_a WHERE NOT (cmt ~ ('\m' || core_surname || '\M'));

CREATE TEMP TABLE ca_keep ON COMMIT DROP AS
SELECT * FROM ca_bucket_a WHERE cmt ~ ('\m' || core_surname || '\M');

-- The money-bearing subset, as literal ids so the delete can use the index.
CREATE TEMP TABLE ca_money (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO ca_money (sid) VALUES
 ('001329f7-a3e0-4b6e-b347-f17c02723e41'),('133b45d3-8eed-44f9-ba02-f3c5f501025e'),
 ('1bff4c83-09a9-4a92-9e35-904f55b88245'),('3fe7885e-9e6b-45d0-af4e-a7efef936bca'),
 ('53634d8e-ef39-4892-8d70-019ccdc38b76'),('6a0cd3a4-21ff-45a5-bb0d-4627cdd3dcaf'),
 ('793ca9ad-5941-496d-ac7b-4dee44e6ad3e'),('97e924b1-3d42-4c54-8033-fd1992ba3d35'),
 ('99944204-0423-4c76-8856-ea7cd3305f73'),('9dc57ffd-9338-43b5-92bd-095c1e2b2abc'),
 ('c4cb810a-e2fe-4456-afba-9e4e02ee1440'),('d4afb477-2d15-4b73-bd6b-2af572945894'),
 ('dbe0004e-8cd6-4203-9045-5e70a802a630'),('e20ce9b9-be6e-4245-8165-86ffc548eba0');

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM ca_bucket_a;
  IF n <> 532 THEN RAISE EXCEPTION 'pre-check: bucket A holds % links, expected 532', n; END IF;
  SELECT count(DISTINCT pid) INTO n FROM ca_bucket_a;
  IF n <> 6 THEN RAISE EXCEPTION 'pre-check: bucket A covers % politicians, expected 6', n; END IF;
  SELECT count(*) INTO n FROM ca_purge;
  IF n <> 518 THEN RAISE EXCEPTION 'pre-check: purge set is %, expected 518', n; END IF;
  SELECT count(*) INTO n FROM ca_keep;
  IF n <> 14 THEN RAISE EXCEPTION 'pre-check: keep set is %, expected 14', n; END IF;

  -- The literal money list must be exactly the money-bearing subset of the purge set. If the two
  -- ever disagree, the hard-coded ids are stale and would delete the wrong rows or miss some.
  SELECT count(*) INTO n FROM ca_money m WHERE NOT EXISTS (SELECT 1 FROM ca_purge p WHERE p.sid = m.sid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % literal money id(s) are not in the purge set', n; END IF;
  SELECT count(DISTINCT g.politician_source_id) INTO n
    FROM transparent_motivations.contribution_summary_agg g JOIN ca_purge p ON p.sid = g.politician_source_id;
  IF n <> 14 THEN RAISE EXCEPTION 'pre-check: % purge link(s) carry money, but the literal list has 14', n; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ca_purge p ON p.sid = g.politician_source_id;
  IF d <> 792923.81 THEN RAISE EXCEPTION 'pre-check: purge set displays %, expected 792923.81', d; END IF;

  -- The keeps must be worth what the audit said, so a mistake that swaps the two sets is caught.
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ca_keep k ON k.sid = g.politician_source_id;
  IF d <> 165082.15 THEN RAISE EXCEPTION 'pre-check: keep set displays %, expected 165082.15', d; END IF;
END $$;

-- 1. The misattributed money.
-- ⚠ The id list is written out INLINE and not as `IN (SELECT sid FROM ca_money)`. The temp-table
-- form was tried first and timed out: a fresh temp table carries no statistics, so the planner
-- ignores idx_transparent_motivations_contributions_politician_source_id and sequentially scans a
-- very large table. `ca_money` above still holds the same ids and the pre-check asserts the two
-- agree, so the duplication cannot drift silently.
DELETE FROM transparent_motivations.contributions
 WHERE politician_source_id IN (
   '001329f7-a3e0-4b6e-b347-f17c02723e41','133b45d3-8eed-44f9-ba02-f3c5f501025e',
   '1bff4c83-09a9-4a92-9e35-904f55b88245','3fe7885e-9e6b-45d0-af4e-a7efef936bca',
   '53634d8e-ef39-4892-8d70-019ccdc38b76','6a0cd3a4-21ff-45a5-bb0d-4627cdd3dcaf',
   '793ca9ad-5941-496d-ac7b-4dee44e6ad3e','97e924b1-3d42-4c54-8033-fd1992ba3d35',
   '99944204-0423-4c76-8856-ea7cd3305f73','9dc57ffd-9338-43b5-92bd-095c1e2b2abc',
   'c4cb810a-e2fe-4456-afba-9e4e02ee1440','d4afb477-2d15-4b73-bd6b-2af572945894',
   'dbe0004e-8cd6-4203-9045-5e70a802a630','e20ce9b9-be6e-4245-8165-86ffc548eba0');

DELETE FROM transparent_motivations.contribution_summary_agg
 WHERE politician_source_id IN (
   '001329f7-a3e0-4b6e-b347-f17c02723e41','133b45d3-8eed-44f9-ba02-f3c5f501025e',
   '1bff4c83-09a9-4a92-9e35-904f55b88245','3fe7885e-9e6b-45d0-af4e-a7efef936bca',
   '53634d8e-ef39-4892-8d70-019ccdc38b76','6a0cd3a4-21ff-45a5-bb0d-4627cdd3dcaf',
   '793ca9ad-5941-496d-ac7b-4dee44e6ad3e','97e924b1-3d42-4c54-8033-fd1992ba3d35',
   '99944204-0423-4c76-8856-ea7cd3305f73','9dc57ffd-9338-43b5-92bd-095c1e2b2abc',
   'c4cb810a-e2fe-4456-afba-9e4e02ee1440','d4afb477-2d15-4b73-bd6b-2af572945894',
   'dbe0004e-8cd6-4203-9045-5e70a802a630','e20ce9b9-be6e-4245-8165-86ffc548eba0');

-- 2. The links: demoted, not deleted.
UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'not_applicable',
       notes = coalesce(ps.notes,'') || ' | WRONG PERSON (migration 1789, 2026-08-16): confirm-cal-'
               || 'access.ts matched this committee on the LAST TOKEN of the politician''s full_name,'
               || ' which is not their surname. The committee does not name them at all.',
       updated_at = now()
  FROM ca_purge p
 WHERE ps.id = p.sid;

DO $$
DECLARE n int; d numeric;
BEGIN
  -- No money may remain anywhere on the purged links, in either table.
  SELECT count(*) INTO n FROM transparent_motivations.contribution_summary_agg g
    JOIN ca_purge p ON p.sid = g.politician_source_id;
  IF n <> 0 THEN RAISE EXCEPTION 'guard 2: % agg row(s) still on purged links', n; END IF;
  -- Literal ids again, for the same planner reason as the DELETE above.
  SELECT count(*) INTO n FROM transparent_motivations.contributions c
   WHERE c.politician_source_id IN (
     '001329f7-a3e0-4b6e-b347-f17c02723e41','133b45d3-8eed-44f9-ba02-f3c5f501025e',
     '1bff4c83-09a9-4a92-9e35-904f55b88245','3fe7885e-9e6b-45d0-af4e-a7efef936bca',
     '53634d8e-ef39-4892-8d70-019ccdc38b76','6a0cd3a4-21ff-45a5-bb0d-4627cdd3dcaf',
     '793ca9ad-5941-496d-ac7b-4dee44e6ad3e','97e924b1-3d42-4c54-8033-fd1992ba3d35',
     '99944204-0423-4c76-8856-ea7cd3305f73','9dc57ffd-9338-43b5-92bd-095c1e2b2abc',
     'c4cb810a-e2fe-4456-afba-9e4e02ee1440','d4afb477-2d15-4b73-bd6b-2af572945894',
     'dbe0004e-8cd6-4203-9045-5e70a802a630','e20ce9b9-be6e-4245-8165-86ffc548eba0');
  IF n <> 0 THEN RAISE EXCEPTION 'guard 2: % contribution(s) still on purged links', n; END IF;

  -- All 518 demoted and carrying the provenance note.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ca_purge p ON p.sid = ps.id
   WHERE ps.research_status = 'not_applicable' AND ps.notes LIKE '%WRONG PERSON (migration 1789%';
  IF n <> 518 THEN RAISE EXCEPTION 'guard 2: % of 518 purged links demoted with a note, expected 518', n; END IF;

  -- 🔑 THE KEEPS ARE THE POINT OF THE REFINEMENT — assert they survived UNCHANGED. A bug that widened
  -- the purge would still satisfy every check above.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ca_keep k ON k.sid = ps.id
   WHERE ps.research_status = 'confirmed';
  IF n <> 14 THEN RAISE EXCEPTION 'guard 2: % of 14 kept links still confirmed, expected 14', n; END IF;
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ca_keep k ON k.sid = g.politician_source_id;
  IF d <> 165082.15 THEN RAISE EXCEPTION 'guard 2: kept money is now %, expected 165082.15 untouched', d; END IF;

  -- Van Der Mark keeps exactly her 3 real committees; Avila and Allen keep none, because none of
  -- their links named them. Assert the split per person, not just in aggregate.
  SELECT count(*) INTO n FROM ca_keep WHERE full_name = 'Gracey Van Der Mark';
  IF n <> 3 THEN RAISE EXCEPTION 'guard 2: Van Der Mark kept % links, expected 3', n; END IF;
  SELECT count(*) INTO n FROM ca_purge WHERE full_name = 'Gracey Van Der Mark';
  IF n <> 378 THEN RAISE EXCEPTION 'guard 2: Van Der Mark purged % links, expected 378', n; END IF;

  RAISE NOTICE 'cal_access bucket A: 518 links demoted, 180 contributions / $792,923.81 removed, 14 correct links kept';
END $$;

COMMIT;
