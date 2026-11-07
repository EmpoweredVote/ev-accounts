-- CC_0365 — two identity faults CC_0360 and CC_0363 left in production, found by master CI on 2026-11-07
--           (jobs "duplicate people" and "address-search reachability" -> check:incumbency, both red from the
--           17:59 UTC scheduled run onward).
--
-- Slot CC_0365 reserved via `npm run steward --prefix backend -- slot CC` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE.
-- ✅ APPLIED to prod 2026-11-07 by Chris Andrews: dry run (ROLLBACK) then apply, both gates green each time. Re-read after:
--   check:incumbency 0 drift (control passed) and check:duplicate-people OK.
--
-- 1. MIKE PIECIAK WAS SPLIT IN TWO.
--    CC_0360 seeded the 2026 Vermont Treasurer race on office 0317b579 and created a NEW person for the winner,
--    "Michael Pieciak" (c185ddef, Ballotpedia source, no party, no seat), with is_incumbent = false on the
--    candidacy. Office 0317b579 is the seat "Mike Pieciak" (20bcd3a8, Democrat, ext -5000005, 3 answers /
--    3 context) has held since before this programme began: the sitting Treasurer won re-election to his own
--    seat. Same first name (Michael / Mike), same surname, same state, same office — one person.
--    check:duplicate-people flagged the pair as NAME_STATE.
--    The second row holds exactly one thing: race_candidates 00a1cfe6 (VT Treasurer, 2026-11-03, 'won'), with
--    NULL photo_url and website_url, so the race_candidate_mirror_data trigger copies nothing. Every other table
--    CA_0360 scans (quotes, speakers, office_terms, answers, context, evidence, review, own-words, images,
--    contacts, aliases, id map, votes, transparent_motivations, bridge) holds 0 rows for it, measured
--    2026-11-07.
--    WHAT CHANGES (CA_0360 pattern): the candidacy moves to 20bcd3a8 and becomes is_incumbent = true (he held
--    the seat on election day — check:incumbency reads exactly that); race_candidates.full_name stays as
--    printed on the ballot; 'Michael Pieciak' is added as an alias; c185ddef is deactivated with a note; the
--    survivor gets a note. Season 1 is not touched (the survivor already holds every answer).
--
-- 2. STEPHANIE GARCIA RICHARD IS SEATED BUT NOT AN INCUMBENT.
--    CC_0360 created her row (1b3be3e1) as a candidate for Lieutenant Governor, is_incumbent = false. CC_0363
--    then pinned that row as the sitting NM Commissioner of Public Lands and wrote her office_terms row, but its
--    INSERT only sets is_incumbent on rows it creates, so the pinned row kept false. A seated person with
--    is_incumbent = false is HIDDEN from the incumbents-only reads (address search). She holds the seat until
--    her successor, Juan Sanchez III, takes office in January.
--    WHAT CHANGES: politicians.is_incumbent = true on 1b3be3e1. Her Lt. Governor candidacy stays
--    is_incumbent = false (she does not hold that office).
--
-- ROLLBACK: re-point race_candidates 00a1cfe6 to c185ddef with is_incumbent = false, set c185ddef is_active =
--   true, delete the alias row with source 'CC_0365', remove both CC_0365 notes, set 1b3be3e1 is_incumbent = false.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and both gates still pass.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- survivor: the sitting VT Treasurer, active, seated on 0317b579, holding his answers
  SELECT count(*) INTO v_n FROM essentials.politicians k
   WHERE k.id = '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8' AND k.full_name = 'Mike Pieciak'
     AND k.is_active AND k.is_incumbent
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.politician_id = k.id AND och.office_id = '0317b579-578e-4e5a-8ab0-010be70979f2')
     AND (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = k.id) = 3;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Mike Pieciak 20bcd3a8 is not the seated VT Treasurer with 3 answers'; END IF;

  -- second row: 'Michael Pieciak', same surname, no seat
  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1' AND d.full_name = 'Michael Pieciak'
     AND lower(d.last_name) = 'pieciak'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = d.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Michael Pieciak c185ddef is not the reviewed seatless row'; END IF;

  -- the candidacy is on the VT Treasurer seat, on either row (re-run), with no photo or website
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE rc.id = '00a1cfe6-b6a0-4294-a23f-e20ddbd650bc'
     AND r.office_id = '0317b579-578e-4e5a-8ab0-010be70979f2'
     AND rc.politician_id IN ('c185ddef-06f2-4df8-8d33-96201f7a31c1', '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8')
     AND COALESCE(rc.photo_url, '') = '' AND COALESCE(rc.website_url, '') = '';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: candidacy 00a1cfe6 not where this file says, or carries a photo/website'; END IF;

  -- the second row holds nothing else
  SELECT (SELECT count(*) FROM essentials.race_candidates WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1'
                                                           AND id <> '00a1cfe6-b6a0-4294-a23f-e20ddbd650bc')
       + (SELECT count(*) FROM essentials.quotes                 WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM meetings.speakers                 WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM inform.politician_answers         WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM inform.politician_context         WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM inform.politician_context_evidence WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM inform.stance_research_review     WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM inform.evidence_items             WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM inform.own_words_passages         WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM essentials.politician_images      WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM essentials.politician_contacts    WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM essentials.politician_name_aliases WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM essentials.legislative_politician_id_map WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM essentials.legislative_votes      WHERE politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
       + (SELECT count(*) FROM politician_id_bridge              WHERE essentials_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1')
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows on c185ddef that this file does not handle', v_n; END IF;

  -- Garcia Richard: the reviewed row, currently seated as NM Commissioner of Public Lands
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = '1b3be3e1-7423-4ba0-bddc-16d1bc59b232' AND p.full_name = 'Stephanie Garcia Richard' AND p.is_active
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
                  WHERE och.politician_id = p.id AND o.title = 'Commissioner of Public Lands');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Garcia Richard 1b3be3e1 is not the seated NM Commissioner of Public Lands'; END IF;

  RAISE NOTICE 'CC_0365 pre-flight OK';
END $$;

-- ─── 1. Pieciak: move the candidacy, alias, deactivate, notes ───────────────────────────────────
UPDATE essentials.race_candidates
   SET politician_id = '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8', is_incumbent = true, updated_at = now()
 WHERE id = '00a1cfe6-b6a0-4294-a23f-e20ddbd650bc'
   AND (politician_id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1' OR NOT is_incumbent);

INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
SELECT '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8', 'Michael Pieciak', 'CC_0365'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_name_aliases
                    WHERE politician_id = '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8' AND lower(alias) = 'michael pieciak');

UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CC_0365 (2026-11-07): DUPLICATE of 20bcd3a8-ccef-4fe3-8897-'
               || '9333d7e79eb8, the sitting VT Treasurer''s row, created by CC_0360. Its 2026 VT Treasurer candidacy '
               || 'moved there; deactivated, not deleted.')::text
 WHERE d.id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1' AND d.is_active;

UPDATE essentials.politicians k
   SET notes = COALESCE(k.notes, ARRAY[]::text[]) || ('CC_0365 (2026-11-07): holds the 2026 VT Treasurer candidacy of '
               || 'c185ddef-06f2-4df8-8d33-96201f7a31c1 ("Michael Pieciak"), a duplicate row of the same person, now '
               || 'deactivated. Season 1 was not touched.')::text
 WHERE k.id = '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8'
   AND NOT EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CC_0365 (2026-11-07): holds%');

-- ─── 2. Garcia Richard: seated, so an incumbent ──────────────────────────────────────────────────
UPDATE essentials.politicians SET is_incumbent = true
 WHERE id = '1b3be3e1-7423-4ba0-bddc-16d1bc59b232' AND NOT is_incumbent;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = '00a1cfe6-b6a0-4294-a23f-e20ddbd650bc'
     AND politician_id = '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8' AND is_incumbent AND full_name = 'Michael Pieciak';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: candidacy 00a1cfe6 not on the survivor as an incumbent'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians k
   WHERE k.id = '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8' AND k.is_active AND k.is_incumbent
     AND (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = k.id) = 3
     AND EXISTS (SELECT 1 FROM essentials.politician_name_aliases x WHERE x.politician_id = k.id AND x.alias = 'Michael Pieciak')
     AND EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CC_0365 (2026-11-07): holds%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: survivor 20bcd3a8 not in its target state'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = 'c185ddef-06f2-4df8-8d33-96201f7a31c1' AND NOT d.is_active AND NOT d.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates x WHERE x.politician_id = d.id)
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CC_0365 (2026-11-07): DUPLICATE of 20bcd3a8%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: c185ddef not deactivated, emptied and noted'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = '1b3be3e1-7423-4ba0-bddc-16d1bc59b232' AND is_incumbent AND is_active;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Garcia Richard not an active incumbent'; END IF;

  RAISE NOTICE 'CC_0365 post-verify OK';
END $$;

COMMIT;
