BEGIN;

-- =============================================================================
-- CA_0100: AI Oversight (ai-regulation) — re-author the v2 per-stance description
--          and example_perspectives the MAJOR-path draft left blank
-- =============================================================================
-- Created 2026-09-01 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: the v2 rework (revision c594dc06-…, version 2, approved + pinned to Season 2 by
--   CA_0065) carried the reworded chair `text` but left `description` NULL and
--   `example_perspectives` empty on all five stances — the MAJOR-path convention, which
--   defers the prose until the row re-audit (CA_0098) is done. This fills them in.
--     · Chairs 1 and 2 are byte-identical to v1, so their v1 description + 3 example
--       perspectives are restored verbatim.
--     · Chairs 3, 4 and 5 were narrowed (each dropped a barrel), so they get NEW prose
--       written for the v2 wording — liability-only (3), testing-only (4), universal
--       pre-approval (5). The reversed axis (chair 1 = minimum government action) is
--       unchanged.
--   Touches only description + example_perspectives on revision 2. It does NOT change any
--   chair `text`, status, pin, or answer — so it re-opens no approval and changes nothing
--   a voter sees until Season 2 opens.
-- Idempotent: straight UPDATEs to fixed literals; re-running is a no-op.
-- =============================================================================

DO $$
DECLARE
  v_v2 CONSTANT uuid := 'c594dc06-0c70-4707-8ae0-d4bc760172db';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_v2 AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023'
                   AND revision = 2 AND version = 2) THEN
    RAISE EXCEPTION 'CA_0100: v2 revision missing/mismatched';
  END IF;
END $$;

-- Chair 1 (unchanged wording — v1 prose restored verbatim).
UPDATE inform.compass_stance_revisions SET
  description = $d$This stance holds that AI development benefits from the freedom to experiment and iterate rapidly, and that government regulation before harms are demonstrated stifles innovation. Proponents argue that industry self-governance and competitive market pressure will produce the right incentives for responsible AI development. Premature regulation risks locking in current approaches and putting U.S. companies at a disadvantage relative to less-regulated international competitors.$d$,
  example_perspectives = ARRAY[
    $p$A technology entrepreneur building AI-powered products may see regulatory constraints as slowing down the development cycle without addressing actual, proven harms.$p$,
    $p$An investor in AI startups may believe regulation creates barriers to entry that entrench large incumbents while preventing new approaches from emerging.$p$,
    $p$A researcher who believes AI's benefits—in medicine, climate, and productivity—are best unlocked by removing friction may favor a permissive development environment.$p$
  ]::text[]
WHERE topic_revision_id = 'c594dc06-0c70-4707-8ae0-d4bc760172db' AND value = 1;

-- Chair 2 (unchanged wording — v1 prose restored verbatim).
UPDATE inform.compass_stance_revisions SET
  description = $d$This stance supports developing voluntary safety guidelines and industry standards while stopping short of mandatory regulation, allowing companies to adopt best practices at their own pace. Proponents believe that the AI field is moving too fast for rigid regulation and that voluntary frameworks can be updated more flexibly as the technology evolves. They see government's role as convening and guiding, not mandating.$d$,
  example_perspectives = ARRAY[
    $p$A technology policy professional who has seen rigid regulations outlast the problems they were designed to solve may favor flexible voluntary standards over statutory requirements.$p$,
    $p$A company executive who wants to demonstrate responsibility without being bound by regulations written before the technology is fully understood may prefer voluntary commitments.$p$,
    $p$A researcher who believes that well-designed voluntary frameworks can achieve compliance rates comparable to regulation without the rigidity may favor this approach.$p$
  ]::text[]
WHERE topic_revision_id = 'c594dc06-0c70-4707-8ae0-d4bc760172db' AND value = 2;

-- Chair 3 (v2: liability only — dropped the disclosure barrel).
UPDATE inform.compass_stance_revisions SET
  description = $d$This stance holds that AI developers should be held legally responsible when their systems cause harm, applying standard product-liability and tort principles to AI. The lever is accountability after the fact rather than disclosure mandates or a pre-market approval gate: if a company deploys a system that causes documented harm, it bears the consequences. Proponents argue that liability already governs most products, that there is no principled reason AI should be exempt, and that clear legal responsibility gives developers a strong incentive to prevent foreseeable harms.$d$,
  example_perspectives = ARRAY[
    $p$A consumer advocate who believes product liability is a foundational protection may see no reason AI systems should escape responsibility for the harms they cause.$p$,
    $p$A person harmed by a biased AI hiring or lending tool may want a clear legal path to hold the developer responsible, rather than relying on the company to police itself.$p$,
    $p$A legal professional who specializes in product liability may see existing tort frameworks as the natural way to assign responsibility when an AI system causes measurable harm.$p$
  ]::text[]
WHERE topic_revision_id = 'c594dc06-0c70-4707-8ae0-d4bc760172db' AND value = 3;

-- Chair 4 (v2: safety testing only — dropped the use-ban barrel).
UPDATE inform.compass_stance_revisions SET
  description = $d$This stance holds that AI used in high-stakes areas—hiring, healthcare, lending, and policing—must pass mandatory safety testing before it can be deployed. The lever is a pre-deployment testing gate proportionate to the risk, not an outright ban on any particular use. Proponents argue that consequential decisions affecting people's lives warrant a higher standard of evidence than other applications, and that required testing catches foreseeable failures before a system reaches the public.$d$,
  example_perspectives = ARRAY[
    $p$A healthcare worker who would be subject to AI-assisted triage or diagnostic decisions may want mandatory safety testing before those systems are used in clinical settings.$p$,
    $p$A job applicant evaluated by an AI screening tool may support required testing so errors are caught before the system is used to make consequential decisions.$p$,
    $p$A civil rights attorney who tracks discriminatory outcomes in AI hiring and lending tools may see pre-deployment testing as the minimum necessary to prevent systemic harm at scale.$p$
  ]::text[]
WHERE topic_revision_id = 'c594dc06-0c70-4707-8ae0-d4bc760172db' AND value = 4;

-- Chair 5 (v2: universal government pre-approval — dropped the targeted-ban barrel).
UPDATE inform.compass_stance_revisions SET
  description = $d$This stance holds that no AI system should be deployed until it has received explicit government approval—a universal pre-market licensing regime, comparable to how new drugs or aircraft are cleared before release. The lever is prior approval for all AI, not a prohibition aimed at particular applications. Proponents argue that the pace of AI development has outrun society's ability to understand and manage its risks, and that a precautionary approval gate is the only reliable way to prevent serious harm before it occurs.$d$,
  example_perspectives = ARRAY[
    $p$A safety researcher focused on worst-case AI failure scenarios may believe that requiring government approval before any deployment is the only reliable way to prevent catastrophic outcomes.$p$,
    $p$A policymaker who has watched other powerful technologies—nuclear power, pharmaceuticals—require pre-market clearance may see the same approval model as the appropriate fit for AI.$p$,
    $p$A citizen worried about untested AI reaching the public may want a government sign-off step before any system is released, not only for the highest-risk uses.$p$
  ]::text[]
WHERE topic_revision_id = 'c594dc06-0c70-4707-8ae0-d4bc760172db' AND value = 5;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_v2 CONSTANT uuid := 'c594dc06-0c70-4707-8ae0-d4bc760172db';
  v_null_desc int;
  v_bad_persp int;
  v_text_changed int;
BEGIN
  -- All five stances now carry a description.
  SELECT count(*) INTO v_null_desc FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_v2 AND description IS NULL;
  IF v_null_desc <> 0 THEN RAISE EXCEPTION 'CA_0100: % stance(s) still have NULL description', v_null_desc; END IF;

  -- All five stances now carry exactly 3 example perspectives.
  SELECT count(*) INTO v_bad_persp FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_v2 AND coalesce(cardinality(example_perspectives),0) <> 3;
  IF v_bad_persp <> 0 THEN RAISE EXCEPTION 'CA_0100: % stance(s) do not have 3 example_perspectives', v_bad_persp; END IF;

  -- Chair wording (text) is untouched: chairs 1/2 match v1, chairs 3/4/5 diverge from v1.
  SELECT count(*) INTO v_text_changed
    FROM inform.compass_stance_revisions cur
    JOIN inform.compass_stance_revisions old
      ON old.value = cur.value AND old.topic_revision_id = '58804871-b768-4d4a-85b5-07c92eb40bc7'
   WHERE cur.topic_revision_id = v_v2
     AND ( (cur.value IN (1,2) AND cur.text <> old.text)
        OR (cur.value IN (3,4,5) AND cur.text = old.text) );
  IF v_text_changed <> 0 THEN RAISE EXCEPTION 'CA_0100: chair text drift detected (% rows)', v_text_changed; END IF;

  RAISE NOTICE 'CA_0100 OK — v2 description + 3 example_perspectives set on all 5 chairs; chair text unchanged.';
END $$;

COMMIT;
