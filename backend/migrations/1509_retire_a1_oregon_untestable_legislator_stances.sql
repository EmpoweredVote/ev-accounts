-- 1509_retire_a1_oregon_untestable_legislator_stances.sql
--
-- Retire 20 untestable stance answers across 14 SITTING OREGON LEGISLATORS. Act 1 of 2; migration
-- 1510 takes the 7 held by statewide-executive and congressional officeholders, which are split out
-- because they have no replacement source in the built tooling and these do.
--   Evidence:        data/stance-retirement/2026-07-31-a1-oregon-articlebody-audit.json (verdict UNTESTABLE)
--   Rollback record: data/stance-retirement/2026-07-29-suspect-stance-backlog.csv carries
--                    politician_id, topic_id, value, write_in_text, reasoning and sources for every
--                    row deleted here, so this is fully reversible from the repo.
--
-- WHY THIS SPLIT IS THE POINT. Every politician here holds a current OR House or Senate seat, so
-- their record is already reachable: scripts/olis-fetch-votes.mjs pulls per-member roll calls for
-- session 2025R1 and is built and verified. Retiring these rows is therefore not "delete and lose",
-- it is delete and RE-DERIVE from the legislature's own record. That is what makes it cheap.
--
-- OCCUPANCY VERIFIED, because two of these looked wrong and were not. Mike McLane (Senate District 30)
-- and Alek Skarlatos (House District 4) both carry office_terms rows with term_start NULL and
-- start_precision 'unknown' -- the migration-1459 backfill, i.e. unverified occupancy. Both were
-- checked against the authoritative OLIS 2025R1 roster, which confirms McLane in S-30 and Skarlatos
-- in H-4. Tawna Sanchez did not match an earlier name probe for 'Tawna D. Sanchez'; she is stored as
-- 'Tawna Sanchez' (House District 43). A name form, not a missing person -- resolved, not guessed.
--
-- WHY THESE ARE RETIRED RATHER THAN RE-TESTED. Migrations 1507 and 1508 retired 188 A1 rows by
-- fetching the cited Ballotpedia page and testing whether the row's own claim terms appear in the
-- article body. The 27 rows in this class could not be put to that test at all -- this migration takes
-- 20 of them. 26 of the 27 yielded ZERO
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

CREATE TEMP TABLE _retire_1509 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1509 (politician_id, topic_id) VALUES
  ('35d2729c-b754-4fad-b124-10ee437a116f'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Alek Skarlatos · Immigration and Treatment of Immigrants · OR House District 4 · no testable term · "Supported enhanced border security and stricter immigration enforcement during 2020 and 2022 CD-"
  ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- Lew Frederick · Campaign Finance Reform · OR Senate District 22 · no testable term · "Supported campaign finance reform and disclosure requirements; backed measures reducing dark mon"
  ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),  -- Lew Frederick · Voting Rights and Electoral Integrity · OR Senate District 22 · no testable term · "Champion of voting rights; supported automatic voter registration, vote-by-mail expansion, and o"
  ('1ca1abf1-9523-499c-b644-0b32c61257c6'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- Sara Gelser Blouin · Campaign Finance Reform · OR Senate District 8 · no testable term · "Supported campaign finance transparency measures; backed donor disclosure requirements as part o"
  ('b548a0f7-5086-4124-a510-49ef8f60f515'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),  -- Kim Thatcher · Transgender Athletes · OR Senate District 11 · no testable term · "Voted in favor of measures restricting transgender athletes in school sports; consistent conserv"
  ('b548a0f7-5086-4124-a510-49ef8f60f515'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),  -- Kim Thatcher · Voting Rights and Electoral Integrity · OR Senate District 11 · no testable term · "Opposed automatic voter registration; supported voter ID measures and questioned election integr"
  ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- Kate Lieber · Campaign Finance Reform · OR Senate District 14 · no testable term · "Supported campaign finance reform including disclosure requirements; backed measures reducing da"
  ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Kate Lieber · Immigration and Treatment of Immigrants · OR Senate District 14 · no testable term · "Supported immigrant protection policies; opposed state collaboration with federal ICE enforcemen"
  ('252a2adf-68a5-4b5a-9024-d5635e2fbd88'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),  -- Mike McLane · Transgender Athletes · OR Senate District 30 · no testable term · "Voted in favor of measures restricting transgender athletes in school sports; consistent conserv"
  ('b6f5cd9e-a9d2-44ff-9027-0d931765f378'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- Floyd Prozanski · Campaign Finance Reform · OR Senate District 4 · no testable term · "Supported campaign finance transparency; backed measures expanding donor disclosure requirements"
  ('c5c49832-aa2d-477e-b44e-d6059a98d426'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Rob Nosse · Civil Rights and Social Justice · OR House District 42 · no testable term · "LGBTQ+ rights champion; consistent civil rights voting record; one of Portland's most outspoken "
  ('c5c49832-aa2d-477e-b44e-d6059a98d426'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid),  -- Rob Nosse · Rent Regulation · OR House District 42 · no testable term · "Supported tenant protections and rent stabilization measures; Portland SE district with diverse "
  ('c5c49832-aa2d-477e-b44e-d6059a98d426'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),  -- Rob Nosse · Transgender Athletes · OR House District 42 · no testable term · "Strong transgender rights advocate; voted for protections for transgender youth and athletes in "
  ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Wlnsvey Campos · Climate Change and Environmental Protection · OR Senate District 18 · no testable term · "Supported clean energy legislation; voted YES on climate bills protecting frontline communities "
  ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Wlnsvey Campos · Taxation and Public Spending · OR Senate District 18 · no testable term · "Supports progressive taxation and public investment in education and social services; backed rev"
  ('a5a3918c-3e24-44fa-9573-440436a05b04'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Andrea Valderrama · Civil Rights and Social Justice · OR House District 47 · no testable term · "Supported civil rights and racial equity measures; environmental justice framework connects envi"
  ('631cc414-8793-42ec-b883-594ed7f0b249'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Deb Patterson · Immigration and Treatment of Immigrants · OR Senate District 10 · no testable term · "Supported immigrant health access; backed measures ensuring immigrant communities can access hea"
  ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),  -- Khanh Pham · Voting Rights and Electoral Integrity · OR Senate District 23 · no testable term · "Supported automatic voter registration and multilingual ballot access; voted for voting rights e"
  ('051b4e9a-6966-45b3-9b65-e23ad4672364'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Tawna D. Sanchez · Immigration and Treatment of Immigrants · OR House District 43 · no testable term · "Supported immigration policies benefiting tribal and Indigenous communities; supported DACA prot"
  ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid);  -- Tom Andersen · Healthcare Access · OR House District 19 · no testable term · "Supported healthcare access expansion measures; Corvallis area with Oregon State University comm"

-- Politicians who will be left with no answers at all, computed BEFORE the delete.
CREATE TEMP TABLE _emptied_1509 ON COMMIT DROP AS
SELECT a.politician_id FROM inform.politician_answers a
 GROUP BY a.politician_id
HAVING count(*) = count(*) FILTER (WHERE EXISTS (
         SELECT 1 FROM _retire_1509 r
          WHERE r.politician_id = a.politician_id AND r.topic_id = a.topic_id));

DELETE FROM inform.politician_context c USING _retire_1509 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1509 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- A timestamp with zero answers asserts research that no longer exists, and would keep these people
-- out of the re-research queue. All 14 were verified NULL against prod before this ran, so this
-- is expected to affect 0 rows -- it is here so the invariant holds if that ever changes.
UPDATE essentials.politicians p SET last_stances_researched_at = NULL
  FROM _emptied_1509 e
 WHERE p.id = e.politician_id AND p.last_stances_researched_at IS NOT NULL;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
  v_ts   int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1509 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left;
  END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1509 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN
    RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx;
  END IF;

  -- Nobody may be left carrying a research timestamp with no answers behind it.
  SELECT count(*) INTO v_ts
    FROM essentials.politicians p
    JOIN _emptied_1509 e ON e.politician_id = p.id
   WHERE p.last_stances_researched_at IS NOT NULL;
  IF v_ts <> 0 THEN
    RAISE EXCEPTION '% emptied politicians still carry a research timestamp', v_ts;
  END IF;
END $$;

COMMIT;
