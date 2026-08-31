BEGIN;

-- =============================================================================
-- CA_0056: Social Security — re-audit chair 4 against v2 wording (Season 1, open)
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2, candrews@empowered.vote).
--
-- WHY: CA_0054 approved the v2 de-barrel of chair 4 ("reduce future benefits rather
--   than raise taxes"). Re-reading all 98 chair-4 seatings showed the chair was built
--   largely on interest-group ratings (ARA/ARS percentages) and party inference —
--   evidence that establishes only direction, not a specific chair. A 36-row web-research
--   rescue pass (WebSearch, a Social Security-specific record required) confirmed this.
--
-- DISPOSITION (all 98): 26 carry at 4, 12 move 4->5 (private accounts), 2 move 4->3
--   (adjust both / open to a tax rise), 58 blank (no SS-specific position on record).
--   Chair 4: 98 -> 26. Distribution 107/208/178/98/66 -> 107/208/180/26/78 (58 removed).
--   Applied to Season 1 (open): a rating/inference seat is wrong under the v1 wording too,
--   so the fix belongs live now (mirrors rent-regulation CA_0045, transportation CA_0050/0052).
--   Robert Chew is the one v2-wording-driven move: he backs raise-age + means-test (fits v1
--   chair 4) but floats a payroll-tax rise, so under v2 "rather than raise taxes" he is chair 3.
--
-- 🔴 The CI answer-delete guard (check:answer-delete-guards) matches only ^(\d+)_ names, so it
--   SKIPS CA_ files. The ORPHAN_CONTEXT guard below is pasted from
--   backend/migrations/_templates/answer_delete_context_guard.sql; check-stance-sources.mjs and
--   audit-chair-evidence.mjs are run by hand after apply.
-- @context-decision: rewritten-as-blank — every blanked pair keeps a documented-blank context
--   ("Researched 2026-08-30 …") naming what was checked; the Social Security topic applies to each
--   and each record was read in the re-audit. No answer row remains for them.
-- Idempotent: DELETE no-ops on re-run; value UPDATEs are stable; context UPDATEs are stable.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id='87d20824-a6e9-407b-983c-65440084a0ab' AND topic_key='social-security') THEN
    RAISE EXCEPTION 'CA_0056: social-security topic id mismatch';
  END IF;
END $$;

CREATE TEMP TABLE ss_blank(pid uuid) ON COMMIT DROP;
INSERT INTO ss_blank(pid) VALUES
  ('abbe5ec0-94fb-4230-bc7c-4b890e4e6387'),  -- Alan Armstrong
  ('8118811a-aadd-4eb9-9208-de0f5d3b29ad'),  -- Andy Biggs
  ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'),  -- Angie Nixon
  ('f6c97c43-41e3-45ae-bdaa-c339f2e6ed4d'),  -- Ashley Moody
  ('7f0bb866-57f4-45de-88ae-5c9977f086bd'),  -- Barry Loudermilk
  ('7de0d70b-81ba-484c-aa82-43dfb4dadd0a'),  -- Brian Birdwell
  ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c'),  -- Brian W. Jones
  ('7e85ff40-5ad8-4374-81a9-c18e60fad8b0'),  -- Bryan Hughes
  ('99198363-2ac9-4b56-9d80-7abfe7b2a01a'),  -- Candice B. Pierucci
  ('eb7ef2a7-d0bb-475e-b2de-d96e6931932c'),  -- Charles Perry
  ('a97678bc-8844-4560-87b1-5ef4f8013d96'),  -- Dan Sullivan
  ('ae7e8d67-e8a4-49a7-bb5c-715c99168374'),  -- David Brock Smith
  ('8ef374f4-e74a-4f51-9733-c9c208856c8d'),  -- David Pan
  ('1fd041d0-473c-45f5-bbfb-54b42aaabc8d'),  -- David Rouzer
  ('b841a475-41b4-4f19-9ad1-13769b1f4eef'),  -- Derek Dooley
  ('02e74087-5a81-474b-9771-62451239007a'),  -- Donna Campbell
  ('4bf58192-5208-4c5f-93f1-ac0a7e6b162d'),  -- Earl L. "Buddy" Carter
  ('274c286d-a292-4e3f-b570-6c2d7ae9c209'),  -- Eric Schmitt
  ('1021e185-125e-4004-91bb-436a9727e4a9'),  -- Greg Gianforte
  ('2ccd34d7-ca08-45d1-bfe0-f64c63349e18'),  -- Gus M. Bilirakis
  ('8f1c9df6-5649-4b49-a18c-09864a2e9763'),  -- Harold Rogers
  ('3bc348ae-0363-4dca-b235-30bc5c073fad'),  -- Heather Smiley
  ('2b8d4b89-2d7c-4b67-a5a1-72bd7c766e1e'),  -- James Lankford
  ('9a41971c-1e38-41b8-a6ec-bec6055a00b3'),  -- James Risch
  ('e4b27d5e-59de-4e71-a8a7-28e7b9a80807'),  -- John Barrasso
  ('e6596b34-8d9f-4593-bf0c-4fe7fc17cd26'),  -- John Hoeven
  ('ffe3816f-4923-4e10-b71c-8b2590a8f377'),  -- John Kennedy
  ('ed095ae9-1864-47e1-9d5d-36b65f0314fe'),  -- John W. Rose
  ('b1282990-8cfc-4919-9955-bdbbbb1b8155'),  -- Joshua McKee
  ('b0ef94c3-d047-4af3-907d-3d1da2b09e50'),  -- Julia Letlow
  ('e1e4e88b-bfd0-4c16-8e95-72c51b59c1f4'),  -- Katy Hall
  ('183d6ca3-be06-4d4f-a727-103687f80e69'),  -- Kevin Sparks
  ('cc873a93-cb47-405a-93b0-bb2848fdd57e'),  -- Lisa Murkowski
  ('2db78ab9-242e-46cd-ba95-5c504a2c8892'),  -- Lois Kolkhorst
  ('030b5074-8335-48b3-8d6b-0ea7c09814a5'),  -- Mark E. Amodei
  ('929346a2-8037-4b14-af33-4820eb365323'),  -- Micah Beckwith
  ('610a5a07-5633-428d-9c88-f0157414e902'),  -- Michael K. Simpson
  ('b6542655-fc71-4b18-a022-6528522cdcae'),  -- Mike Collins
  ('787b2a74-de35-4dbe-b58a-c9bd345120a0'),  -- Mike Johnson
  ('9e3164d5-ce71-4c50-9220-b969265ce551'),  -- Mike Kennedy
  ('f8d6555b-faea-4746-b8d8-27c41e08f4c4'),  -- Mitch McConnell
  ('096ba968-82d5-46ce-86ab-4b387973978d'),  -- Nancy Mace
  ('af0e81ec-b2dd-42eb-80b9-aa73c62c2741'),  -- Patrick Morrisey
  ('efd863c6-df64-4b40-9b49-73ddd003dc5d'),  -- Paul A. Gosar
  ('e3c5cef5-08ff-4066-9fee-344733cb4137'),  -- Robert E. Latta
  ('9df12eb2-bc9a-4083-8004-1af4167342ea'),  -- Roger Marshall
  ('d53cbad2-d166-4f8d-87a2-f7e5ddc7a237'),  -- Roger Wicker
  ('4112b70d-e961-4313-987e-8673e9f39f22'),  -- Russ Fulcher
  ('fe96da99-4c28-42b7-841f-1d25b2c47406'),  -- Sam Graves
  ('6ca6aabe-6a7f-46b7-b51d-620a7f5c9913'),  -- Shelley Moore Capito
  ('066f7bc5-6e3d-4d17-9878-73d896a2369e'),  -- Stacy Garrity
  ('fcdd3836-bb89-44ec-920a-75a21c9d726f'),  -- Stan Ellis
  ('24109768-01ad-4bab-b833-b7bc1d8f437d'),  -- Steve Daines
  ('970c20ca-d938-4e90-b7d6-ecfbc6f517a3'),  -- Steve Scalise
  ('540628fb-afea-4803-ab8e-abea3d4e603c'),  -- Tan Parker
  ('e8228875-8fed-4f62-8184-22c5bb0093e1'),  -- Thomas A. Garrett, Jr.
  ('d2d9d65d-138a-4b40-a4de-88642f35ec15'),  -- Tracy Miller
  ('8ee77a4f-4653-45d4-ab9c-15061ff4ecbb');  -- Vern Buchanan

-- Remove the 58 unevidenced seatings (no value=0 sentinel; blank = absence of row).
DELETE FROM inform.politician_answers a USING ss_blank b
 WHERE a.politician_id=b.pid AND a.topic_id='87d20824-a6e9-407b-983c-65440084a0ab';

-- Documented-blank contexts for the 58 blanked pairs.
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Alan Armstrong. PROMISE Act procedural trigger only. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='abbe5ec0-94fb-4230-bc7c-4b890e4e6387' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Andy Biggs. general insolvency + "no tax on SS"; no mechanism. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='8118811a-aadd-4eb9-9208-de0f5d3b29ad' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Angie Nixon. MIS-ATTRIBUTION: Democrat described as "Conservative Republican". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='0ac89151-2b8d-4430-b9bd-3a80bef3413b' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Ashley Moody. only "No Tax on Social Security" income-tax exemption. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='f6c97c43-41e3-45ae-bdaa-c339f2e6ed4d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Barry Loudermilk. SSA service complaints + "no cuts"; no reform. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='7f0bb866-57f4-45de-88ae-5c9977f086bd' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Brian Birdwell. "Texas Republicans consistently opposed..." party inference. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='7de0d70b-81ba-484c-aa82-43dfb4dadd0a' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Brian W. Jones. "no direct SS votes... platform most consistent with". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='ee130fd3-649d-49e1-bda4-13d9bbed2f6c' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Bryan Hughes. AFP award; "consistent with" inference. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='7e85ff40-5ad8-4374-81a9-c18e60fad8b0' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Candice B. Pierucci. "no state-level SS legislation... aligns with Republican caucus". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='99198363-2ac9-4b56-9d80-7abfe7b2a01a' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Charles Perry. "no SS expansion legislation... consistent with". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='eb7ef2a7-d0bb-475e-b2de-d96e6931932c' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Dan Sullivan. TRUST/Fairness Act; raise-age is opponent claim. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='a97678bc-8844-4560-87b1-5ef4f8013d96' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — David Brock Smith. OR state senator; no SS plank. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='ae7e8d67-e8a4-49a7-bb5c-715c99168374' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — David Pan. "new system for younger" two-tier restructure — ambiguous chair. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='8ef374f4-e74a-4f51-9733-c9c208856c8d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — David Rouzer. OnTheIssues "no stance recorded". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='1fd041d0-473c-45f5-bbfb-54b42aaabc8d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Derek Dooley. balanced-budget platform; raise-age inferred. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='b841a475-41b4-4f19-9ad1-13769b1f4eef' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Donna Campbell. "No evidence of specific statements found, but... suggests". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='02e74087-5a81-474b-9771-62451239007a' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Earl L. "Buddy" Carter. opposes privatization; raise-age inferred, no stated cut. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='4bf58192-5208-4c5f-93f1-ac0a7e6b162d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Eric Schmitt. own quote May 2025 opposes ANY SS cuts — contradicts 4. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='274c286d-a292-4e3f-b570-6c2d7ae9c209' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Greg Gianforte. contradictory; recent "won't cut benefits" contradicts chair 4. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='1021e185-125e-4004-91bb-436a9727e4a9' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Gus M. Bilirakis. commission bill + income-tax deduction; no ladder mechanism. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='2ccd34d7-ca08-45d1-bfe0-f64c63349e18' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Harold Rogers. "protect and preserve" + Fairness Act; no mechanism. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='8f1c9df6-5649-4b49-a18c-09864a2e9763' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Heather Smiley. wants benefits tax-free; priv is govt pensions — no SS cut. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='3bc348ae-0363-4dca-b235-30bc5c073fad' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — James Lankford. SSDI anti-fraud only. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='2b8d4b89-2d7c-4b67-a5a1-72bd7c766e1e' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — James Risch. "not going to cut" reassurance; no mechanism. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='9a41971c-1e38-41b8-a6ec-bec6055a00b3' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — John Barrasso. "sacred trust" 2012; no lever. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='e4b27d5e-59de-4e71-a8a7-28e7b9a80807' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — John Hoeven. generic solvency + excluded rating. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='e6596b34-8d9f-4593-bf0c-4fe7fc17cd26' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — John Kennedy. deflection; admin bills only. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='ffe3816f-4923-4e10-b71c-8b2590a8f377' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — John W. Rose. "everything on the table" = openness, not a committed chair. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='ed095ae9-1864-47e1-9d5d-36b65f0314fe' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Joshua McKee. "exploring innovative privatization options" — vague/hybrid. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='b1282990-8cfc-4919-9955-bdbbbb1b8155' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Julia Letlow. "does not record a specific SS stance... likely favors". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='b0ef94c3-d047-4af3-907d-3d1da2b09e50' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Katy Hall. "no state-level SS legislation... consistent with". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='e1e4e88b-bfd0-4c16-8e95-72c51b59c1f4' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Kevin Sparks. "No specific SS legislation found... suggests preference". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='183d6ca3-be06-4d4f-a727-103687f80e69' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Lisa Murkowski. prefunding vote + tax pledge; no benefit-cut/private-account statement. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='cc873a93-cb47-405a-93b0-bb2848fdd57e' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Lois Kolkhorst. "No specific SS legislation... Medicaid stance suggests". No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='2db78ab9-242e-46cd-ba95-5c504a2c8892' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Mark E. Amodei. "lockbox"/off-budget accounting only. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='030b5074-8335-48b3-8d6b-0ea7c09814a5' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Micah Beckwith. IN Lt Gov; no federal lever; no personal SS statement. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='929346a2-8037-4b14-af33-4820eb365323' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Michael K. Simpson. 20+yr lockbox/tax/401k votes; no mechanism. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='610a5a07-5633-428d-9c88-f0157414e902' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Mike Collins. "opposing outright cuts" contradicts chair 4; vague. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='b6542655-fc71-4b18-a022-6528522cdcae' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Mike Johnson. contradictory; early-2025 affirmed SS not cut. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='787b2a74-de35-4dbe-b58a-c9bd345120a0' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Mike Kennedy. own record anti-cut (OBBB no cuts); chair-4 = RSC-membership inference. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='9e3164d5-ce71-4c50-9220-b969265ce551' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Mitch McConnell. 2018 "structure of SS" no mechanism; distanced from Scott sunset. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='f8d6555b-faea-4746-b8d8-27c41e08f4c4' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Nancy Mace. concrete SS act is eliminating taxes on benefits; rest general. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='096ba968-82d5-46ce-86ab-4b387973978d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Patrick Morrisey. WV Gov; "solemn promise" no mechanism; OTI Unclear. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='af0e81ec-b2dd-42eb-80b9-aa73c62c2741' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Paul A. Gosar. rating + subissue bills; no mechanism. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='efd863c6-df64-4b40-9b49-73ddd003dc5d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Robert E. Latta. WEP/GPO+ALS+identity-theft bills only. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='e3c5cef5-08ff-4066-9fee-344733cb4137' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Roger Marshall. benefits-taxation bill + reassurance. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='9df12eb2-bc9a-4083-8004-1af4167342ea' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Roger Wicker. old 401k/lockbox; vague unsourced accounts note. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='d53cbad2-d166-4f8d-87a2-f7e5ddc7a237' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Russ Fulcher. op-ed was a columnist not Fulcher; town-hall topic only. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='4112b70d-e961-4313-987e-8673e9f39f22' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Sam Graves. disability-fraud/coverage bills; generic pledge. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='fe96da99-4c28-42b7-841f-1d25b2c47406' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Shelley Moore Capito. voted FOR Fairness Act expansion; mixed/contradictory. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='6ca6aabe-6a7f-46b7-b51d-620a7f5c9913' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Stacy Garrity. "state-run retirement savings program" alternative — ambiguous. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='066f7bc5-6e3d-4d17-9878-73d896a2369e' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Stan Ellis. CA Assembly; AJR8 NO vote under-determines. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='fcdd3836-bb89-44ec-920a-75a21c9d726f' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Steve Daines. no SS-specific mechanism. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='24109768-01ad-4bab-b833-b7bc1d8f437d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Steve Scalise. "strengthening" messaging; RSC plans postdate chairmanship. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='970c20ca-d938-4e90-b7d6-ecfbc6f517a3' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Tan Parker. "consistent with Republican preference" party inference. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='540628fb-afea-4803-ab8e-abea3d4e603c' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Thomas A. Garrett, Jr.. idiosyncratic "Student Security" restructure; ambiguous chair. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='e8228875-8fed-4f62-8184-22c5bb0093e1' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Tracy Miller. "no state-level SS legislation... caucus preference" inference. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='d2d9d65d-138a-4b40-a4de-88642f35ec15' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-08-30 — Vern Buchanan. transparency + SECURE 2.0; no mechanism. No Social Security-specific statement, bill, or vote placing a chair on this ladder (benefit level, payroll-tax cap, retirement age, or private accounts) was found; the prior chair-4 seat was not evidenced. Left blank.$r$
 WHERE politician_id='8ee77a4f-4653-45d4-ab9c-15061ff4ecbb' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';

-- Move 4->5 (private individual accounts).
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='e365a1d4-2de3-4fb6-b416-d78227836553' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Blake Moore
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.deseret.com/opinion/2023/2/8/23581997/blake-moore-conservative-optimist-recession/']::text[],
  reasoning=$r$Researched 2026-08-30 — Blake Moore: Deseret News Feb 2023: personal accounts / private capital-market investment. This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='e365a1d4-2de3-4fb6-b416-d78227836553' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='dd5d3f6d-fc82-4774-b510-287ec47cbd84' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Chuck Grassley
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.ontheissues.org/Senate/Chuck_Grassley.htm','https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=119&session=1&vote=00180']::text[],
  reasoning=$r$Researched 2026-08-30 — Chuck Grassley: "voted YES on allowing personal Social Security retirement accounts". This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='dd5d3f6d-fc82-4774-b510-287ec47cbd84' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='3621bbef-a821-45fe-991c-e1744ad05203' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- John Boozman
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.ontheissues.org/Senate/John_Boozman.htm','https://en.wikipedia.org/wiki/John_Boozman']::text[],
  reasoning=$r$Researched 2026-08-30 — John Boozman: "invest a portion of payroll taxes in privately managed accounts". This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='3621bbef-a821-45fe-991c-e1744ad05203' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='ffb0dcac-385a-4df3-a441-cdbd0e713c1d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- John Sununu
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[],
  reasoning=$r$Researched 2026-08-30 — John Sununu: "Proposed creating personal retirement accounts within Social Security". This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='ffb0dcac-385a-4df3-a441-cdbd0e713c1d' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='130591ca-bfd1-4691-916b-3570341b04fb' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Joni Ernst
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://en.wikipedia.org/wiki/Joni_Ernst','https://www.ontheissues.org/Senate/Joni_Ernst.htm']::text[],
  reasoning=$r$Researched 2026-08-30 — Joni Ernst: "partial privatization of accounts for young workers". This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='130591ca-bfd1-4691-916b-3570341b04fb' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='e04094d1-247c-40c8-8829-c7cb8654d0ed' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Lisa C. McClain
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.ontheissues.org/MI/Lisa_McClain_Social_Security.htm']::text[],
  reasoning=$r$Researched 2026-08-30 — Lisa C. McClain: "partial private investment accounts... investment options like HSAs". This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='e04094d1-247c-40c8-8829-c7cb8654d0ed' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='2971d4f9-1433-4dcd-aaa7-193241ef3c95' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Mike Crapo
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.ontheissues.org/Senate/Mike_Crapo.htm','https://crapo.senate.gov/issues/social-security/']::text[],
  reasoning=$r$Researched 2026-08-30 — Mike Crapo: stated: "privatized government-managed accounts are acceptable". This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='2971d4f9-1433-4dcd-aaa7-193241ef3c95' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='ace0b96d-8ef8-4aca-8928-6848ae430da6' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Mike Rogers
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://michiganindependent.com/politics/2024-senate-election-mike-rogers-elissa-slotkin-social-security-investments-stock-market-bush/']::text[],
  reasoning=$r$Researched 2026-08-30 — Mike Rogers: MI Senate candidate (is_incumbent=false, verified): 2005 op-ed backing Bush personal accounts. This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='ace0b96d-8ef8-4aca-8928-6848ae430da6' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='a947157e-cf67-4181-a554-4ff56b2846f7' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Sarah Bella Spinosa
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.citizenscount.org/candidate/sarah-bella-spinosa/running/2026-primary-us-house','https://freecongressnh.com/vision']::text[],
  reasoning=$r$Researched 2026-08-30 — Sarah Bella Spinosa: survey: partial privatization + downsize to minimal public option. This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='a947157e-cf67-4181-a554-4ff56b2846f7' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='2392d04a-fdb9-45be-8a02-3bb60a1517aa' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Steve Womack
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.ontheissues.org/House/Steve_Womack.htm']::text[],
  reasoning=$r$Researched 2026-08-30 — Steve Womack: OnTheIssues documents supporting SS privatization initiatives. This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='2392d04a-fdb9-45be-8a02-3bb60a1517aa' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='a8bda21a-a5ca-4c15-9612-10fad5d5c9d6' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Ted Cruz
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.ontheissues.org/Ted_Cruz.htm','https://www.ontheissues.org/senate/Ted_Cruz.htm']::text[],
  reasoning=$r$Researched 2026-08-30 — Ted Cruz: Nov 2015: "No changes for seniors; personal accounts for young". This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='a8bda21a-a5ca-4c15-9612-10fad5d5c9d6' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='7affca4e-db2b-4f7e-b009-9acc6b493139' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Tommy Tuberville
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.ontheissues.org/Tommy_Tuberville.htm','https://en.wikipedia.org/wiki/Tommy_Tuberville']::text[],
  reasoning=$r$Researched 2026-08-30 — Tommy Tuberville: Financial Freedom Act + "private retirement account options" as SS alternative. This is the private individual investment accounts stance (chair 5), not a benefit-reduction stance; re-seated from chair 4 to chair 5.$r$
 WHERE politician_id='7affca4e-db2b-4f7e-b009-9acc6b493139' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';

-- Move 4->3 (adjust both / open to a tax rise).
UPDATE inform.politician_answers SET value=3, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='64783a11-a7ae-4ab7-a6d2-593ae06796f8' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Al Lemmo
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://ivoterguide.com/candidate/51843/race/845/election/688?culture=en-us']::text[],
  reasoning=$r$Researched 2026-08-30 — Al Lemmo: iVoterGuide MI-08 2026: open to raising cap + means-testing "unjust" = adjust both. Adjusts both benefits and taxes rather than cutting benefits instead of raising taxes; re-seated from chair 4 to chair 3.$r$
 WHERE politician_id='64783a11-a7ae-4ab7-a6d2-593ae06796f8' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
UPDATE inform.politician_answers SET value=3, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='2096c3f0-12bd-449c-9892-ebe7d8bc8c80' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Robert Chew
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://bobchew2026.com/issues/']::text[],
  reasoning=$r$Researched 2026-08-30 — Robert Chew: raise-age + means-test BUT also floats payroll-tax increase = adjust both. Adjusts both benefits and taxes rather than cutting benefits instead of raising taxes; re-seated from chair 4 to chair 3.$r$
 WHERE politician_id='2096c3f0-12bd-449c-9892-ebe7d8bc8c80' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab';

-- Re-source the 3 rescued carry-at-4 rows (keep value=4, replace rating/inference context).
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://news.bgov.com/bloomberg-government-news/republican-plan-to-raise-retirement-age-draws-election-year-heat']::text[],
  reasoning=$r$Researched 2026-08-30 — John Thune: Bloomberg Mar 2024: raise retirement age, phased in for younger, no tax. Reduces future benefits (raise retirement age / means-test) with no tax increase = chair 4. Re-sourced from a rating/inference basis to a Social Security-specific record.$r$
 WHERE politician_id='661c0499-af4c-4cf9-a34b-eb0c20d5cd4b' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- John Thune
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.wral.com/fact-check-did-budd-vote-to-cut-social-security-and-medicare/20560981/']::text[],
  reasoning=$r$Researched 2026-08-30 — Ted Budd: Oct 2017 RSC substitute (Sam Johnson Act): raise age to 69 + means-test COLAs, no tax. Reduces future benefits (raise retirement age / means-test) with no tax increase = chair 4. Re-sourced from a rating/inference basis to a Social Security-specific record.$r$
 WHERE politician_id='401f1fab-c996-4b1a-92f7-2817c5dd4619' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Ted Budd
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources=ARRAY['https://www.americanprogress.org/article/the-house-republican-study-committee-budget-proposes-harsh-changes-to-social-security/']::text[],
  reasoning=$r$Researched 2026-08-30 — Tom Cotton: Mar 2013 House Vote 86 RSC FY2014 substitute: phase retirement age to 70, no tax. Reduces future benefits (raise retirement age / means-test) with no tax increase = chair 4. Re-sourced from a rating/inference basis to a Social Security-specific record.$r$
 WHERE politician_id='0942f325-1180-4e1a-b1df-06438f1792a3' AND topic_id='87d20824-a6e9-407b-983c-65440084a0ab'; -- Tom Cotton

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate on blanked pairs (regex identical to gate).
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM ss_blank t
    JOIN inform.politician_context pc ON pc.politician_id=t.pid AND pc.topic_id='87d20824-a6e9-407b-983c-65440084a0ab'
   WHERE coalesce(cardinality(pc.sources),0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'CA_0056 context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE v_c1 int; v_c2 int; v_c3 int; v_c4 int; v_c5 int; v_blank_ans int; v_blank_ctx int;
BEGIN
  SELECT count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2), count(*) FILTER (WHERE value=3),
         count(*) FILTER (WHERE value=4), count(*) FILTER (WHERE value=5)
    INTO v_c1,v_c2,v_c3,v_c4,v_c5 FROM inform.politician_answers WHERE topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
  IF (v_c1,v_c2,v_c3,v_c4,v_c5) <> (107,208,180,26,78) THEN
    RAISE EXCEPTION 'CA_0056: distribution %/%/%/%/% (expected 107/208/180/26/78)', v_c1,v_c2,v_c3,v_c4,v_c5;
  END IF;
  SELECT count(*) INTO v_blank_ans FROM inform.politician_answers a JOIN ss_blank b ON a.politician_id=b.pid AND a.topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
  IF v_blank_ans <> 0 THEN RAISE EXCEPTION 'CA_0056: % answer rows survived for blanked pairs', v_blank_ans; END IF;
  SELECT count(*) INTO v_blank_ctx FROM inform.politician_context c JOIN ss_blank b ON c.politician_id=b.pid AND c.topic_id='87d20824-a6e9-407b-983c-65440084a0ab';
  IF v_blank_ctx <> 58 THEN RAISE EXCEPTION 'CA_0056: expected 58 documented-blank contexts, got %', v_blank_ctx; END IF;
  RAISE NOTICE 'CA_0056 OK — chair4 re-audit; distribution now %/%/%/%/% (58 blanked, 12->5, 2->3, 3 re-sourced)', v_c1,v_c2,v_c3,v_c4,v_c5;
END $$;

COMMIT;
