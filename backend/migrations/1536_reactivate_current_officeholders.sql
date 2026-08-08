-- 1536_reactivate_current_officeholders.sql
-- Re-activate the TWO politician rows that are is_active = false while genuinely holding
-- the office essentials says they hold. Idempotent (guarded on is_active; a re-run no-ops).
--
-- WHY: gui/politicians.py (on-the-record, PR #146) filters the speaker-link picker on
--   p.is_active, rescuing inactive rows only when they carry a NON-WITHDRAWN candidacy via an
--   uncorrelated IN. An inactive officeholder with no live candidacy is therefore invisible in
--   the picker, and the search returns zero results — indistinguishable from "no such person".
--   The picker's WHERE is correct as shipped (relaxing it costs 5x: 165ms -> 850-1068ms per
--   keystroke, because the OR defeats the planner's pruning). The data is what is wrong.
--
--   The same flag also gates the PUBLIC "who represents me" feed:
--   backend/src/lib/essentialsService.ts:774 and :840 —
--       LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
--       LEFT JOIN essentials.politicians p ON p.id = och.politician_id
--       ... AND (p.is_active = true OR o.is_vacant = true)
--   Both offices below are is_vacant = false with these people as the office_terms holder, so
--   today the seat resolves to a deactivated person and drops out of the feed entirely:
--   FL-11 constituents currently see NO U.S. Representative, and Los Angeles shows no City
--   Clerk. This migration fixes a live public gap, not just the internal picker.
--
-- THE TWO ROWS (verified individually against authoritative sources on 2026-08-03):
--
--   Daniel Webster (external_id -12011) — U.S. Representative, FL-11 (district geo_id 1211).
--     Sitting member. He announced on 2026-04-28 that he will not seek re-election, and
--     finishes his term in January 2027. Migration 1381_fl11_webster_untangle.sql deactivated
--     him at that announcement, conflating "not a 2026 candidate" with "not a current
--     officeholder": it set BOTH rc.candidate_status = 'withdrawn' AND is_active = false.
--     The withdrawn candidacy is CORRECT and stays — it is also precisely why the picker's
--     candidacy rescue does not reach him. Carries 15 inform.politician_answers + a portrait.
--     Sources: rollcall.com/2026/04/28/florida-rep-daniel-webster-is-latest-republican-to-
--     announce-retirement/ ; news.ballotpedia.org/2026/05/05/rep-daniel-webster-becomes-the-
--     56th-u-s-representative-to-announce-he-wont-seek-re-election-in-2026/
--
--   Patrice Lattimore (external_id -700002) — City Clerk, Los Angeles (district geo_id 0644000).
--     Appointed by Mayor Bass, confirmed by City Council 2025-09-16, started 2025-09-24,
--     succeeding Holly Wolcott (Petty Santos had been interim). Unambiguously the current
--     clerk; she oversees the 2026 LA elections. No provenance for the deactivation exists in
--     any migration in this repo — it was written directly to prod.
--     Source: mayor.lacity.gov/news/mayor-bass-announces-appointment-los-angeles-city-clerk-0
--
-- THE ELEVEN ROWS DELIBERATELY NOT TOUCHED. The starting list was 13 rows returned by
--   "is_active = false AND holds an office with a non-empty title". Each was checked
--   individually; only the two above survived. Recording the other eleven here so the next
--   person does not have to re-derive them:
--
--   (a) LEFT THE OFFICE — is_active = false is CORRECT; the stale thing is their open-ended
--       essentials.office_terms row, which is what still reports them as current holder.
--       Activating them would push a factually wrong officeholder back onto the public feed.
--         Kristi Noem       642537  Sec. of Homeland Security — out 2026-03-31 (now Special
--                                   Envoy); Markwayne Mullin nominated 2026-03-09.
--         Pamela Bondi      642364  Attorney General — out 2026-04-02; Todd Blanche acting.
--         Patricia A Riley  206176  Indiana COA District 4 — retired 2024-08-30 (senior judge).
--         James Kirsch      206174  Indiana COA District 2 — retired 2021-09; since deceased.
--         Dan Combs         393382  Perry Twp Trustee — died 2026-01; Leon Gordon succeeded.
--         Shruti Rana       450800  Bloomington Common Council D5 — resigned 2024-02-07;
--                                   Courtney Daily won the 2024-03-02 caucus. (politicians
--                                   .valid_to already reads 2024-03-01.)
--
--   (b) DUPLICATE STUBS whose real row is already ACTIVE and already findable in the picker.
--       Activating these would trade one problem for another by surfacing a duplicate pair.
--       All four inactive stubs hold ZERO quotes/speakers/images/answers.
--         Raul Ruiz     05349fa0-...  stub with a spurious "U.S. Representative" office_terms
--                       row; deliberately retired by 1091_seed_ca_2026_house_candidates.sql in
--                       favour of 5238b298-... (-6000325, CA-25 incumbent, 15 answers).
--         Arthur Dixon  b8e3727a-...  source federal_2026_bulk_seed; real row is
--                       76d1140a-... (ballotpedia, CA-34 candidate, portrait + race edge).
--         Calvin Lee    1d7ca756-...  source federal_2026_bulk_seed; real row is
--                       361c6a80-... (ballotpedia, CA-34 candidate, portrait + race edge).
--       Confirmed Dixon and Lee are genuine CA-34 2026 primary candidates, so the ACTIVE rows
--       are the correct ones; the inactive ones are bulk-seed junk carrying a fake office.
--
--   (c) NEEDS A REAL MERGE, NOT A FLAG FLIP — deliberately out of scope for this migration.
--         John Fleming  8be7e981-... (-400119, inactive, 18 answers + portrait, fake office
--                       "Candidate for U.S. Senate — Louisiana")
--                   vs  a750bce8-... (-2200005, ACTIVE, Louisiana Treasurer, 14 answers +
--                       portrait). BOTH rows carry Compass answers, so a merge must reconcile
--                       inform.politician_answers on its (politician_id, topic_id) PK — exactly
--                       the collision class 1534 excluded. The active row is already findable
--                       in the picker, so nothing is blocked by waiting.
--
--   (d) JUDGMENT CALL, DELIBERATELY DEFERRED
--         Gary Crockett 1c6f7914-... — real 2026 Louisiana U.S. Senate Democratic candidate;
--           LOST the 2026-06-27 runoff to Jamie Davis, so he is neither an officeholder nor a
--           live candidate, and his "office" is a fake "Candidate for U.S. Senate — Louisiana"
--           row. But he holds 2 readrank_selected quotes + 2 answers + a portrait, and no twin
--           exists, so the picker cannot find him at all. Note his quotes are ALREADY
--           unreachable in Read & Rank for an unrelated reason: he has no
--           essentials.race_candidates edge, and readrankService reaches quotes only through
--           that join. Flipping is_active would NOT fix that; the race edge would.
--
-- WHY THIS IS SAFE: is_active is READ-ONLY in the ev-accounts backend — every occurrence in
--   backend/src is a SELECT filter, never an UPDATE. No ballotready/cicero sync code exists in
--   backend/src or scripts, and render.yaml defines no cron. Every deactivation in this DB
--   traces to a hand-written migration (1091 for Ruiz, 1381 for Webster, 1092, 1411, ...).
--   There is therefore NO roster-sync job that will undo this on its next run. The standing
--   risk is a future hand-written migration repeating 1381's conflation of "retiring" with
--   "no longer in office" — which is why the notes column below records the reason inline.

BEGIN;

-- ---------------------------------------------------------------------------
-- Target table, resolved by external_id (stable; UUIDs are environment-specific)
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE reactivate_targets ON COMMIT DROP AS
SELECT v.person, v.reason, p.id
FROM (VALUES
  ('Daniel Webster',
   'sitting U.S. Representative FL-11 through January 2027; migration 1381 deactivated him '
   'on his 2026-04-28 retirement announcement, conflating "not a 2026 candidate" with "not a '
   'current officeholder". His withdrawn FL-11 candidacy is correct and is left in place.',
   -12011::bigint),
  ('Patrice Lattimore',
   'current Los Angeles City Clerk, confirmed by City Council 2025-09-16 and serving since '
   '2025-09-24; no migration in this repo ever deactivated her.',
   -700002)
) AS v(person, reason, ext)
JOIN essentials.politicians p ON p.external_id = v.ext;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM reactivate_targets;
  IF n <> 2 THEN
    RAISE EXCEPTION 'expected 2 reactivation targets, resolved % — external_ids missing or changed', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT 1: each target must STILL be the current holder of a real, titled office.
-- If a term has closed since this migration was authored, the premise is gone — fail loudly
-- rather than re-activate someone who has since left office.
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM reactivate_targets LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      WHERE och.politician_id = r.id AND COALESCE(o.title, '') <> ''
    ) THEN
      RAISE EXCEPTION '% (%) no longer holds a current titled office — do not re-activate', r.person, r.id;
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT 2: no ACTIVE same-name twin. The whole point is to make these people findable
-- in the picker; activating a row whose twin is already active would surface a duplicate
-- pair instead — trading one problem for another. Measured 2026-08-03: neither has a twin
-- (the four rows that DO have active twins are excluded from this migration by design).
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record; n int;
BEGIN
  FOR r IN SELECT t.person, t.id, p.full_name FROM reactivate_targets t
             JOIN essentials.politicians p ON p.id = t.id LOOP
    SELECT count(*) INTO n
      FROM essentials.politicians q
     WHERE q.id <> r.id
       AND q.is_active
       AND lower(trim(q.full_name)) = lower(trim(r.full_name));
    IF n <> 0 THEN
      RAISE EXCEPTION '% : % active same-name row(s) already exist — resolve the duplicate '
                      'before re-activating, or the picker gains a duplicate pair', r.person, n;
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- THE WRITE. Enumerated by external_id, never predicate-driven. Guarded on is_active so a
-- re-run neither rewrites the row nor appends the provenance note twice.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET is_active = true,
       notes = COALESCE(p.notes, '{}'::text[])
               || ('re-activated by migration 1536 on 2026-08-03: ' || t.reason)
  FROM reactivate_targets t
 WHERE p.id = t.id
   AND p.is_active = false;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r record;
  n int;
BEGIN
  FOR r IN SELECT t.person, t.id FROM reactivate_targets t LOOP
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.id AND is_active) THEN
      RAISE EXCEPTION '% : row % is still inactive after the update', r.person, r.id;
    END IF;
  END LOOP;

  -- No duplicate pair created: exactly one active row per target name.
  SELECT count(*) INTO n FROM (
    SELECT lower(trim(p.full_name)) AS nm
      FROM essentials.politicians p
      JOIN reactivate_targets t ON t.id = p.id
  ) tgt
  JOIN LATERAL (
    SELECT count(*) AS c FROM essentials.politicians q
     WHERE q.is_active AND lower(trim(q.full_name)) = tgt.nm
  ) x ON x.c > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'reactivation produced % duplicate active name group(s)', n;
  END IF;

  -- THE POINT OF THE MIGRATION, checked through the exact shape both consumers use:
  -- an active politician reachable from a titled office via office_current_holder.
  SELECT count(*) INTO n
    FROM essentials.politicians p
    JOIN reactivate_targets t ON t.id = p.id
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
   WHERE p.is_active AND COALESCE(o.title, '') <> '';
  IF n <> 2 THEN
    RAISE EXCEPTION 'expected 2 active officeholders after reactivation, found %', n;
  END IF;

  -- Webster's retirement must NOT have been undone: his FL-11 candidacy stays withdrawn.
  IF EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
     WHERE rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -12011)
       AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
  ) THEN
    RAISE EXCEPTION 'Daniel Webster has a non-withdrawn candidacy — 1381''s retirement was undone';
  END IF;

  RAISE NOTICE 'Reactivation PASSED: Daniel Webster (FL-11) and Patrice Lattimore (LA City Clerk) '
               'are active current officeholders; no duplicate name groups; Webster still withdrawn.';
END $$;

COMMIT;
