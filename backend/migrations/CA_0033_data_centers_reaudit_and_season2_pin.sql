-- CA_0033_data_centers_reaudit_and_season2_pin.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
--
-- WHAT / WHY
-- The `data-centers` topic (id 4559b513-0fd8-4ed1-babd-f3b554162f40) has an approved substantive
-- v2 (revision ab779ac9, version 2) that split two double-barrel chairs and DROPPED one barrel from
-- each: chair 2 lost "requiring data centers to fund their own dedicated power generation" (keeping
-- the cost-pass-through ban); chair 5 lost "competitive incentives" (keeping "minimal regulatory
-- barriers"). Per the substantive-revision rule, the rows seated on the dropped barrels, and the
-- pre-existing mis-fits surfaced alongside them, are re-audited HERE, before Season 2 opens, so the
-- corrected seatings are what Season 2 carries. Season 1 (open) serves v1 and is unaffected by the
-- pin; the row edits below apply to the live Season-1 seatings, which is correct — they were wrong
-- under v1 too.
--
-- CITATION BAR (Andrews, 2026-08-30): seatings must rest on a primary instrument — the officeholder's
-- own bill/vote/letter/official statement. Wikipedia, LCV scorecards, OnTheIssues and "would likely
-- support" inference are not evidence. Ballotpedia only for a candidate's own questionnaire. Where no
-- primary instrument places a SPECIFIC chair on this spectrum, the row is a documented blank.
--
-- DISPOSITIONS (14 rows on data-centers)
--   RE-SOURCE, chair unchanged (bad citation -> primary):
--     Markey (2)   markey.senate.gov FERC/NARUC ratepayer letters + AI Environmental Impacts Act
--     Warren (2)   warren.senate.gov data-center cost-shift investigation + Warren-Hawley reporting
--     Trahan (2)   trahan.house.gov backing No Harm Data Centers Act (H.R. 8033, cost-shift ban)
--     Morrisey (5) governor.wv.gov HB 2014 (independent microgrids, one-stop permitting)
--   MOVE:
--     Foushee 2->3 congress.gov H.R. 7858 (Data Center Community Impact Act, impact study) cosponsor
--   BLANK (documented, rewritten-as-blank): Patel, Rogers, Clark, Jim McGovern, Marc McGovern,
--     Kwan, Jemison, Dill (all off chair 2) and Pitcher (off chair 5). See per-row reasoning.
--   SEASON 2: repin data-centers from v1 to the approved v2 (draft season only; DO NOT open).
--
-- Expected end state: chair counts 1=50, 2=91, 3=91, 4=40, 5=10 (was 50/100/90/40/11); 9 answer rows
-- removed; Season 2 (86d893a1) question 8 pinned to ab779ac9.

BEGIN;

-- ── 0. Preconditions ────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='4559b513-0fd8-4ed1-babd-f3b554162f40' AND topic_key='data-centers') THEN
    RAISE EXCEPTION 'precondition: data-centers topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id='ab779ac9-acd3-47d2-b1be-228ecc35e453'
                   AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40'
                   AND version=2 AND status='approved') THEN
    RAISE EXCEPTION 'precondition: v2 revision is not approved';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
                   AND number=2 AND status='draft') THEN
    RAISE EXCEPTION 'precondition: Season 2 is not a draft (pin would be frozen)';
  END IF;
END $$;

-- ── 1. Re-source keeps (chair unchanged; repoint reasoning + sources to primary) ─────────────────
-- Markey — chair 2 (bar cost pass-through to residential ratepayers)
UPDATE inform.politician_context
   SET reasoning = $r$Sen. Ed Markey has pressed federal and state regulators to stop data centers from shifting energy costs onto residential ratepayers: he led colleagues in a November 2025 letter to FERC urging it to ensure projected data-center demand does not cause "unjust or unreasonable" rate hikes for American households, and a March 2026 letter to NARUC urging state commissions to protect ratepayers from data-center-induced bill increases. He also introduced the AI Environmental Impacts Act (S.4727) requiring AI data centers to report their energy and environmental impacts.$r$,
       sources = ARRAY[
         'https://www.markey.senate.gov/news/press-releases/senator-markey-leads-colleagues-in-urging-federal-energy-regulator-to-prevent-data-centers-from-dramatically-hiking-energy-costs-for-american-families',
         'https://www.congress.gov/bill/119th-congress/senate-bill/4727/text'
       ]::text[],
       editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='faf86b5b-5add-4afb-a8e2-96b3e8be4b78' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

-- Warren — chair 2. DELIBERATE EXCEPTION to the audit-chair-evidence lexical floor: her instrument is
-- a formal Senate oversight investigation into data centers passing costs to residential ratepayers,
-- plus a secured mandatory data-center energy-reporting requirement — primary, on-point for chair 2,
-- but not a numbered bill, so scripts/audit-chair-evidence.mjs will FLAG this row. Kept on purpose
-- (decision Chris Andrews 2026-08-30); do not "fix" by inventing a bill number.
UPDATE inform.politician_context
   SET reasoning = $r$Sen. Elizabeth Warren opened an investigation into data centers driving up household electricity costs, sending letters (with Sens. Van Hollen and Blumenthal) to Google, Microsoft, Amazon, Meta, CoreWeave, Digital Realty and Equinix over data centers passing their buildout and operating costs onto ordinary ratepayers, and — with Sen. Hawley — pushed the Energy Information Administration to adopt mandatory data-center energy-use reporting. Her position is that residential customers should not bear data centers' energy costs.$r$,
       sources = ARRAY[
         'https://www.warren.senate.gov/newsroom/press-releases/senator-warren-lawmakers-open-investigation-into-big-tech-data-centers-role-in-driving-up-families-utility-costs/',
         'https://www.warren.senate.gov/newsroom/press-releases/warren-hawley-lead-bipartisan-push-for-mandatory-energy-use-reporting-requirements-for-data-centers/'
       ]::text[],
       editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='dd08c9de-076d-40ee-ab27-9298bbb72d1a' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

-- Trahan — chair 2
UPDATE inform.politician_context
   SET reasoning = $r$Rep. Lori Trahan backed bipartisan bills to protect ratepayers from data-center price hikes at the July 2026 House Energy and Commerce markup, including the No Harm Data Centers Act (H.R. 8033), which prohibits covered electric utilities from shifting data-center-related costs onto the retail rates of customers other than the data centers themselves.$r$,
       sources = ARRAY[
         'https://trahan.house.gov/news/documentsingle.aspx?DocumentID=3815',
         'https://www.congress.gov/bill/119th-congress/house-bill/8033/text'
       ]::text[],
       editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='b96758c6-2ea0-4698-8886-d574d34e366d' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

-- Morrisey — chair 5 (welcome investment, minimal regulatory barriers)
UPDATE inform.politician_context
   SET reasoning = $r$As West Virginia governor, Patrick Morrisey championed and signed the Power Generation and Consumption Act (HB 2014, effective July 2025) to make West Virginia "the most attractive state in the country for data centers." It lets data centers build their own certified microgrids instead of connecting to existing utilities, pairs with one-stop-shop permitting, and directs data-center/microgrid tax revenue to income-tax reduction and economic development — welcoming investment with minimal regulatory barriers.$r$,
       sources = ARRAY[
         'https://governor.wv.gov/article/governor-patrick-morrisey-signs-power-generation-and-consumption-and-one-stop-shop'
       ]::text[],
       editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='af0e81ec-b2dd-42eb-80b9-aa73c62c2741' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

-- ── 2. Move: Foushee chair 2 -> chair 3 (allow development with impact assessment) ───────────────
UPDATE inform.politician_answers
   SET value=3, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='248c67f9-b8bf-4627-b358-a0f49b47abe7'
   AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40' AND value=2;

UPDATE inform.politician_context
   SET reasoning = $r$Rep. Valerie Foushee is a cosponsor of the Data Center Community Impact Act (H.R. 7858), which directs the Secretary of Energy to study the environmental, economic and public-health impacts of data centers on surrounding communities, with a focus on communities of color and low-income areas — an allow-development-with-impact-assessment position rather than a moratorium or a cost-pass-through ban.$r$,
       sources = ARRAY[
         'https://www.congress.gov/bill/119th-congress/house-bill/7858/text'
       ]::text[],
       editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='248c67f9-b8bf-4627-b358-a0f49b47abe7' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

-- ── 3. Blanks: remove the seating, rewrite context as a documented blank ─────────────────────────
CREATE TEMP TABLE dc_blank(pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO dc_blank(pid, tid) VALUES
  ('9a927fae-60bf-41f9-8ec0-433cc98997fa','4559b513-0fd8-4ed1-babd-f3b554162f40'), -- Patel
  ('ffb8e526-7ad7-4911-92c5-d69528a0f280','4559b513-0fd8-4ed1-babd-f3b554162f40'), -- Rogers
  ('7bf73fb2-1b31-412e-913d-835bfd3e326d','4559b513-0fd8-4ed1-babd-f3b554162f40'), -- Clark
  ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5','4559b513-0fd8-4ed1-babd-f3b554162f40'), -- Jim McGovern
  ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec','4559b513-0fd8-4ed1-babd-f3b554162f40'), -- Marc McGovern
  ('93376853-c225-430c-bf89-dfee26c6c964','4559b513-0fd8-4ed1-babd-f3b554162f40'), -- Kwan
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4','4559b513-0fd8-4ed1-babd-f3b554162f40'), -- Jemison
  ('c0b96558-d6b2-4029-b680-40c5cc815688','4559b513-0fd8-4ed1-babd-f3b554162f40'), -- Dill
  ('4f896b69-d922-4838-b54d-51a00a452e08','4559b513-0fd8-4ed1-babd-f3b554162f40'); -- Pitcher

DELETE FROM inform.politician_answers a
 USING dc_blank b
 WHERE a.politician_id=b.pid AND a.topic_id=b.tid;

-- Rewrite each context as a documented blank. Each names what was checked and why it fails to place a
-- chair; the leading "Researched 2026-08-30" is TRUE here (each record was read against primary
-- sources this pass), not a wording trick to satisfy the guard.
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — Assemblymember Patel voted AYE on AB 222 and AB 1577, California data-center energy reporting/disclosure bills. Those establish support for transparency/reporting but do not bar utilities from passing data-center costs to residential customers, mandate dedicated generation, or otherwise place her at a specific chair on this spectrum. No primary source found for a scorable stance; left blank.$r$
 WHERE politician_id='9a927fae-60bf-41f9-8ec0-433cc98997fa' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — Rep. Rogers's cited bills (H.96, H.97, H.98, H.104) concern biometric AI, AI consumer protection, children's online privacy and data privacy — none address data-center development or energy costs. No primary source found placing him on this topic; left blank.$r$
 WHERE politician_id='ffb8e526-7ad7-4911-92c5-d69528a0f280' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — No primary instrument found tying Rep. Clark to a specific data-center development or energy-cost position; the prior seating rested on an LCV scorecard and "would likely support" inference. Left blank rather than infer from party or scorecard.$r$
 WHERE politician_id='7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — No primary instrument found placing Rep. Jim McGovern on data-center development or energy costs; the prior seating rested on an LCV scorecard and inference. Left blank.$r$
 WHERE politician_id='ee4081d5-fc3e-4a8c-b39e-481ae20135d5' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — Councillor Marc McGovern's only cited action is a unanimous Cambridge City Council vote to request a city-manager report on regulating data-center expansion — a procedural study request that does not state a personal stance on this spectrum. Left blank.$r$
 WHERE politician_id='a8f48816-2ebc-4ae4-9667-a12d4c18f5ec' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — Sen. Kwan co-signed a Utah Senate Democrats' letter opposing the Box Elder (Stratos) data center on environmental grounds; that opposition is off this topic's development/energy-cost axis and does not match a specific chair. No primary instrument found for a scorable position on this spectrum; left blank.$r$
 WHERE politician_id='93376853-c225-430c-bf89-dfee26c6c964' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — The cited Salt Lake Tribune profile of candidate Jemison does not contain a data-center position, and no other primary source was found. Left blank.$r$
 WHERE politician_id='0695eddd-6fb4-40f7-8daa-f5d6d10d6db4' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — Sen. Dill's prior seating cited two Maine roll calls on LD 307's 18-month data-center moratorium (RC 815, RC 828), but those are House votes and Dill is a state senator; the Senate held no override vote (the House sustained Gov. Mills's veto 72-65 on 4/29/2026), and Dill does not appear in the Senate enactment roll call (RC 955, 21-13, 4/14/2026). His individual position is not confirmable from a primary source; left blank.$r$
 WHERE politician_id='c0b96558-d6b2-4029-b680-40c5cc815688' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — Sen. Pitcher co-signed a Utah Senate Democrats' letter opposing the Box Elder (Stratos) data center as "not right for Utah"/an environmental catastrophe. That is opposition on environmental grounds — off this topic's development/energy-cost axis — and does not match a specific chair; it also contradicts her prior "welcoming" (chair 5) seating. No primary instrument found for a scorable position on this spectrum; left blank.$r$
 WHERE politician_id='4f896b69-d922-4838-b54d-51a00a452e08' AND topic_id='4559b513-0fd8-4ed1-babd-f3b554162f40';

-- @context-decision: rewritten-as-blank — the topic applies to each person and each record WAS read
-- against primary sources on 2026-08-30; none carried a primary instrument placing a specific chair,
-- so each context is a documented blank naming what was checked. No answer row remains for these pairs.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate, applied to the pairs this migration
-- blanked. Regexes kept character-identical to the gate.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM dc_blank t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid
   WHERE coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- ── 4. Season 2: repin data-centers from v1 to the approved v2 (draft season; not opened here) ────
SELECT inform.admin_season_pin_revision(
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid,  -- Season 2 (draft)
  '4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,  -- data-centers
  'ab779ac9-acd3-47d2-b1be-228ecc35e453'::uuid,  -- approved v2
  '854fbc06-40fc-458d-b523-20ef8e5ad1b2'::uuid   -- actor: Chris Andrews
);

-- ── 5. Post-verify gate (row-specific, idempotent) ──────────────────────────────────────────────
DO $$
DECLARE
  tid uuid := '4559b513-0fd8-4ed1-babd-f3b554162f40';
  c1 int; c2 int; c3 int; c4 int; c5 int; blanks int; pinned uuid;
BEGIN
  -- Foushee moved to 3
  IF NOT EXISTS (SELECT 1 FROM inform.politician_answers
                 WHERE politician_id='248c67f9-b8bf-4627-b358-a0f49b47abe7' AND topic_id=tid AND value=3) THEN
    RAISE EXCEPTION 'verify: Foushee not seated at chair 3';
  END IF;
  -- Re-source keeps still at their chair
  IF NOT EXISTS (SELECT 1 FROM inform.politician_answers WHERE politician_id='faf86b5b-5add-4afb-a8e2-96b3e8be4b78' AND topic_id=tid AND value=2)
   OR NOT EXISTS (SELECT 1 FROM inform.politician_answers WHERE politician_id='dd08c9de-076d-40ee-ab27-9298bbb72d1a' AND topic_id=tid AND value=2)
   OR NOT EXISTS (SELECT 1 FROM inform.politician_answers WHERE politician_id='b96758c6-2ea0-4698-8886-d574d34e366d' AND topic_id=tid AND value=2)
   OR NOT EXISTS (SELECT 1 FROM inform.politician_answers WHERE politician_id='af0e81ec-b2dd-42eb-80b9-aa73c62c2741' AND topic_id=tid AND value=5) THEN
    RAISE EXCEPTION 'verify: a re-source keep changed chair unexpectedly';
  END IF;
  -- Nine blanks have no answer row
  SELECT count(*) INTO blanks FROM dc_blank b
    JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF blanks <> 0 THEN RAISE EXCEPTION 'verify: % blanked pair(s) still have an answer row', blanks; END IF;
  -- Chair distribution
  SELECT count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2), count(*) FILTER (WHERE value=3),
         count(*) FILTER (WHERE value=4), count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid;
  IF (c1,c2,c3,c4,c5) <> (50,91,91,40,10) THEN
    RAISE EXCEPTION 'verify: chair counts are %/%/%/%/% (expected 50/91/91/40/10)', c1,c2,c3,c4,c5;
  END IF;
  -- Season 2 pin
  SELECT topic_revision_id INTO pinned FROM inform.season_questions
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id=tid;
  IF pinned <> 'ab779ac9-acd3-47d2-b1be-228ecc35e453' THEN
    RAISE EXCEPTION 'verify: Season 2 pin is % (expected the approved v2)', pinned;
  END IF;
END $$;

COMMIT;
