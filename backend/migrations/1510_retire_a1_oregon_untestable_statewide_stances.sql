-- 1510_retire_a1_oregon_untestable_statewide_stances.sql
--
-- Retire 7 untestable stance answers across 4 Oregon officeholders who are NOT sitting legislators.
-- Act 2 of 2; migration 1509 took the 20 held by sitting OR House and Senate members.
--   Evidence:        data/stance-retirement/2026-07-31-a1-oregon-articlebody-audit.json (verdict UNTESTABLE)
--   Rollback record: data/stance-retirement/2026-07-29-suspect-stance-backlog.csv carries
--                    politician_id, topic_id, value, write_in_text, reasoning and sources for every
--                    row deleted here, so this is fully reversible from the repo.
--
-- WHY THESE ARE SEPARATE. 1509's rows can be re-derived immediately from OLIS per-member roll calls.
-- These four cannot, and the reason is the same in every case: each row describes service in a
-- PREVIOUS office while citing the bio page of the CURRENT one. Steiner's three rows argue from her
-- Senate career and she is Treasurer; Stephenson's from her House service and she is Labor
-- Commissioner; Read's from his time as Treasurer and he is Secretary of State; Bynum's from her OR
-- House service and she now sits in the US House.
--
-- 🔴 DO NOT PUSH THESE FOUR THROUGH OLIS 2025R1. They hold no legislative seat in that session, and
-- mapping session votes onto them is exactly how a statewide executive ends up credited with
-- legislative votes. Steiner, Stephenson and Read need earlier OLIS sessions matched to the years
-- they actually served; Bynum needs a congressional source. That is separate, unscheduled work.
--
-- Retired anyway, and deliberately: an unevidenced claim about a statewide officeholder is not
-- improved by being left published while it waits for a source that is not scheduled. This is the
-- higher-profile half of the set, which is a reason to hold it to the standard, not to exempt it.
--
-- WHY THESE ARE RETIRED RATHER THAN RE-TESTED. Migrations 1507 and 1508 retired 188 A1 rows by
-- fetching the cited Ballotpedia page and testing whether the row's own claim terms appear in the
-- article body. The 27 rows in this class could not be put to that test at all -- this migration takes
-- 7 of them. 26 of the 27 yielded ZERO
-- extractable distinctive terms, because there is nothing specific in them to extract. Every one
-- asserts CONDUCT -- "voted for", "voted YES on climate bills", "Voted in favor of measures
-- restricting transgender athletes" -- while naming no bill, no vote, no date and no quote.
--
-- The bar this project holds is a chair the evidence NAMES and a source that SUPPORTS it. A citation
-- that cannot be tested does not meet it, and leaving these live would make them a permanent
-- exception to the standard every other row is held to. Retiring is the honest outcome: the row
-- becomes merely ABSENT. Some of these claims are probably TRUE -- but an unevidenced true claim is
-- indistinguishable to a voter from an unevidenced false one, and sorting them requires exactly the
-- roll-call research that produces a better row than the one being preserved.
--
-- CORROBORATION, not the basis for deletion. Independent template clustering
-- (scripts/cluster-stance-reasoning.mjs) finds 4 of the 27 to be byte-identical pairs after proper
-- nouns are removed: Thatcher/McLane share a trans-athletes sentence, Prozanski/Gelser Blouin share a
-- campaign-finance sentence. Wrong-office attribution is visible on the face of others -- Skarlatos's
-- row argues from two US HOUSE campaigns (2020, 2022 CD-4) while he holds OR House District 4.
--
-- Idempotent: the target set is an explicit (politician_id, topic_id) list, so a re-run deletes
-- nothing. Structure follows migrations 1494, 1507 and 1508.

BEGIN;

CREATE TEMP TABLE _retire_1510 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1510 (politician_id, topic_id) VALUES
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),  -- Elizabeth Steiner · Affordable Housing · State Treasurer (statewide) · no testable term · "Steiner voted for housing production and affordability bills as state senator; supported increas"
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Elizabeth Steiner · Climate Change and Environmental Protection · State Treasurer (statewide) · no testable term · "Steiner voted for multiple climate bills as state senator including clean electricity standards;"
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Elizabeth Steiner · Taxation and Public Spending · State Treasurer (statewide) · no testable term · "Steiner as state senator voted for corporate tax increases and progressive revenue measures; as "
  ('8548989d-ff40-4b25-bb42-e1a7cbb03c88'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),  -- Christina Stephenson · Affordable Housing · Labor Commissioner (statewide) · no testable term · "Stephenson as state representative voted for affordable housing bills and zoning reform; support"
  ('8548989d-ff40-4b25-bb42-e1a7cbb03c88'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Christina Stephenson · Taxation and Public Spending · Labor Commissioner (statewide) · no testable term · "Stephenson as state representative supported progressive tax policies including corporate tax re"
  ('7aad2a83-2f05-4570-aa7a-eb7a8c602ebd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Janelle Bynum · Taxation and Public Spending · US House OR-5 · no testable term · "Bynum as OR state rep voted for progressive tax measures targeting higher incomes; supported cor"
  ('94105ea6-e6f7-4629-b30c-a8fe713e1cad'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid);  -- Tobias Read · Affordable Housing · Secretary of State (statewide) · no testable term · "Read as Treasurer championed Oregon's affordable housing bond program; supported financing mecha"

-- Politicians who will be left with no answers at all, computed BEFORE the delete.
CREATE TEMP TABLE _emptied_1510 ON COMMIT DROP AS
SELECT a.politician_id FROM inform.politician_answers a
 GROUP BY a.politician_id
HAVING count(*) = count(*) FILTER (WHERE EXISTS (
         SELECT 1 FROM _retire_1510 r
          WHERE r.politician_id = a.politician_id AND r.topic_id = a.topic_id));

DELETE FROM inform.politician_context c USING _retire_1510 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1510 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- A timestamp with zero answers asserts research that no longer exists, and would keep these people
-- out of the re-research queue. All 4 were verified NULL against prod before this ran, so this
-- is expected to affect 0 rows -- it is here so the invariant holds if that ever changes.
UPDATE essentials.politicians p SET last_stances_researched_at = NULL
  FROM _emptied_1510 e
 WHERE p.id = e.politician_id AND p.last_stances_researched_at IS NOT NULL;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
  v_ts   int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1510 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left;
  END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1510 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN
    RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx;
  END IF;

  -- Nobody may be left carrying a research timestamp with no answers behind it.
  SELECT count(*) INTO v_ts
    FROM essentials.politicians p
    JOIN _emptied_1510 e ON e.politician_id = p.id
   WHERE p.last_stances_researched_at IS NOT NULL;
  IF v_ts <> 0 THEN
    RAISE EXCEPTION '% emptied politicians still carry a research timestamp', v_ts;
  END IF;
END $$;

COMMIT;
