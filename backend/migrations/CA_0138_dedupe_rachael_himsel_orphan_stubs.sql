-- CA_0138_dedupe_rachael_himsel_orphan_stubs.sql
--
-- Data hygiene: delete 2 DUPLICATE, EMPTY, INACTIVE "Rachael Himsel" politician stubs.
--
-- Context: three `Rachael Himsel` politician records existed. CA_0134 linked the Clear Creek
-- Township Board candidate to the ACTIVE one (4f56cccb-…) and gave it a website. The other two
-- (5cb28e6a-…, cf1625a3-…) are is_active=false and carry NO data and NO references anywhere —
-- verified 2026-09-22 as 0 rows across all 21 tables that FK to essentials.politicians
-- (race_candidates, office_terms, politician_images, politician_answers, politician_context,
--  addresses, degrees, experiences, identifiers, committees, contacts, name_aliases,
--  quest_verified_facts, evidence_items, context_evidence, stance_research_review,
--  topic_rewrite_stance_proposals, la_council_votes, empowered_profiles, politician_id_bridge,
--  transparent_motivations.politician_sources). They are pure discovery-pipeline orphans.
--
-- The KEEPER (4f56cccb-…) is untouched. Idempotent: if the two stubs are already gone (re-run),
-- the pre-flight sees 0 targets and the migration no-ops.

BEGIN;

DO $$
DECLARE n_targets int; n_refs int;
BEGIN
  -- the two deletion targets must be exactly: inactive, named 'Rachael Himsel', and NOT the keeper
  SELECT count(*) INTO n_targets FROM essentials.politicians p
  WHERE p.id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c')
    AND p.full_name = 'Rachael Himsel' AND p.is_active = false;

  IF n_targets = 0 THEN
    RAISE NOTICE 'CA_0138: 0 target stubs present (already removed) — no-op';
  ELSIF n_targets <> 2 THEN
    RAISE EXCEPTION 'aborting: expected 2 inactive Rachael Himsel stubs, found % (data changed — re-check by hand)', n_targets;
  ELSE
    -- re-assert ZERO references across every FK table before deleting (guards against cascade / drift)
    SELECT
      (SELECT count(*) FROM essentials.race_candidates x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.office_terms x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.politician_images x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.addresses x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.degrees x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.experiences x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.identifiers x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.politician_committees x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.politician_contacts x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.politician_name_aliases x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM essentials.quest_verified_facts x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM inform.evidence_items x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM inform.politician_answers x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM inform.politician_context x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM inform.politician_context_evidence x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM inform.stance_research_review x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM inform.topic_rewrite_stance_proposals x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM meetings.la_council_votes x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM empower.empowered_profiles x WHERE x.politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM public.politician_id_bridge x WHERE x.essentials_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
     +(SELECT count(*) FROM transparent_motivations.politician_sources x WHERE x.essentials_politician_id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c'))
      INTO n_refs;
    IF n_refs <> 0 THEN
      RAISE EXCEPTION 'aborting: % reference(s) to the target stubs exist — NOT safe to delete', n_refs;
    END IF;

    DELETE FROM essentials.politicians
    WHERE id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c')
      AND full_name='Rachael Himsel' AND is_active=false;
  END IF;
END $$;

-- ── post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_gone int; n_keeper int; n_remaining int; n_linked int;
BEGIN
  SELECT count(*) INTO n_gone FROM essentials.politicians
   WHERE id IN ('5cb28e6a-c569-4857-816f-56cfcdabdd4f','cf1625a3-679c-467a-9777-13f288b6360c');
  IF n_gone <> 0 THEN RAISE EXCEPTION 'expected 0 target stubs remaining, found %', n_gone; END IF;

  SELECT count(*) INTO n_keeper FROM essentials.politicians WHERE id='4f56cccb-0e22-4f55-a237-a4e5fe0f5772';
  IF n_keeper <> 1 THEN RAISE EXCEPTION 'keeper 4f56cccb missing!'; END IF;

  SELECT count(*) INTO n_remaining FROM essentials.politicians WHERE full_name='Rachael Himsel';
  IF n_remaining <> 1 THEN RAISE EXCEPTION 'expected exactly 1 Rachael Himsel, found %', n_remaining; END IF;

  SELECT count(*) INTO n_linked FROM essentials.race_candidates
   WHERE id='19485c80-b2c1-49da-8c52-3c1bcd1376c2' AND politician_id='4f56cccb-0e22-4f55-a237-a4e5fe0f5772';
  IF n_linked <> 1 THEN RAISE EXCEPTION 'Clear Creek Himsel candidate no longer linked to keeper'; END IF;

  RAISE NOTICE 'ok CA_0138: 2 orphan Himsel stubs removed; keeper intact and linked';
END $$;

COMMIT;
