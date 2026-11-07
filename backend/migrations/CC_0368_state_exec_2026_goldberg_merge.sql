-- CC_0368 — Deb Goldberg was split in two by CC_0360, the same fault CC_0365 fixed for Mike Pieciak.
--
-- Slot CC_0368 reserved via `npm run steward --prefix backend -- slot CC` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE.
-- ✅ APPLIED to prod 2026-11-07 by Chris Andrews: dry run (ROLLBACK) then apply, both gates green each time. Re-read after:
--   check:incumbency 0 drift (control passed) and check:duplicate-people OK.
--
-- CC_0360 seeded the 2026 Massachusetts Treasurer and Receiver-General race on office 3367d772 and created a
-- NEW person for the winner, "Deb Goldberg" (57ce8d40, Ballotpedia source, no party, no seat), with
-- is_incumbent = false on the candidacy. Office 3367d772 is held by "Deborah B. Goldberg" (eb88bdd6,
-- Democratic, 17 answers / 17 context, a portrait, a transparent_motivations source): the sitting Treasurer
-- won re-election to her own seat. Deb / Deborah, same surname, same state, same office — one person.
-- check:duplicate-people flagged the pair as NAME_STATE on 2026-11-07.
-- A sweep the same day (every 2026 candidacy whose race office is held on election day by a DIFFERENT row
-- with the same surname) found this pair and five namesakes that are different people (Nehls, Webster,
-- Weninger, Graham, Sullivan). No other CC_0360 split remains.
--
-- The second row holds exactly one thing: race_candidates c08314df (MA Treasurer, 2026-11-03, 'won'), with
-- NULL photo_url and website_url, so the race_candidate_mirror_data trigger copies nothing. Every other table
-- CA_0360 scans holds 0 rows for it, measured 2026-11-07.
--
-- WHAT CHANGES (CA_0360 / CC_0365 pattern): the candidacy moves to eb88bdd6 and becomes is_incumbent = true
-- (she held the seat on election day); race_candidates.full_name stays as printed on the ballot; 'Deb
-- Goldberg' is added as an alias; 57ce8d40 is deactivated with a note; the survivor gets a note. Season 1 is
-- not touched (the survivor already holds every answer).
--
-- ROLLBACK: re-point race_candidates c08314df to 57ce8d40 with is_incumbent = false, set 57ce8d40 is_active =
--   true, delete the alias row with source 'CC_0368', remove both CC_0368 notes.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and both gates still pass.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.politicians k
   WHERE k.id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5' AND k.full_name = 'Deborah B. Goldberg'
     AND k.is_active AND k.is_incumbent
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.politician_id = k.id AND och.office_id = '3367d772-6a6b-4c51-9a74-c294ed1dbfdc')
     AND (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = k.id) = 17;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Deborah B. Goldberg eb88bdd6 is not the seated MA Treasurer with 17 answers'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448' AND d.full_name = 'Deb Goldberg'
     AND lower(d.last_name) = 'goldberg'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = d.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Deb Goldberg 57ce8d40 is not the reviewed seatless row'; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE rc.id = 'c08314df-cd89-459e-a253-47c58cfe6981'
     AND r.office_id = '3367d772-6a6b-4c51-9a74-c294ed1dbfdc'
     AND rc.politician_id IN ('57ce8d40-3a7d-4795-a1d5-3d21980d6448', 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5')
     AND COALESCE(rc.photo_url, '') = '' AND COALESCE(rc.website_url, '') = '';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: candidacy c08314df not where this file says, or carries a photo/website'; END IF;

  SELECT (SELECT count(*) FROM essentials.race_candidates WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448'
                                                           AND id <> 'c08314df-cd89-459e-a253-47c58cfe6981')
       + (SELECT count(*) FROM essentials.quotes                 WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM meetings.speakers                 WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM inform.politician_answers         WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM inform.politician_context         WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM inform.politician_context_evidence WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM inform.stance_research_review     WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM inform.evidence_items             WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM inform.own_words_passages         WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM essentials.politician_images      WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM essentials.politician_contacts    WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM essentials.politician_name_aliases WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM essentials.legislative_politician_id_map WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM essentials.legislative_votes      WHERE politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
       + (SELECT count(*) FROM politician_id_bridge              WHERE essentials_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448')
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows on 57ce8d40 that this file does not handle', v_n; END IF;

  RAISE NOTICE 'CC_0368 pre-flight OK';
END $$;

UPDATE essentials.race_candidates
   SET politician_id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5', is_incumbent = true, updated_at = now()
 WHERE id = 'c08314df-cd89-459e-a253-47c58cfe6981'
   AND (politician_id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448' OR NOT is_incumbent);

INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
SELECT 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5', 'Deb Goldberg', 'CC_0368'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_name_aliases
                    WHERE politician_id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5' AND lower(alias) = 'deb goldberg');

UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CC_0368 (2026-11-07): DUPLICATE of eb88bdd6-d1c7-4e08-aff8-'
               || 'bb7517ad24b5, the sitting MA Treasurer''s row, created by CC_0360. Its 2026 MA Treasurer candidacy '
               || 'moved there; deactivated, not deleted.')::text
 WHERE d.id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448' AND d.is_active;

UPDATE essentials.politicians k
   SET notes = COALESCE(k.notes, ARRAY[]::text[]) || ('CC_0368 (2026-11-07): holds the 2026 MA Treasurer candidacy of '
               || '57ce8d40-3a7d-4795-a1d5-3d21980d6448 ("Deb Goldberg"), a duplicate row of the same person, now '
               || 'deactivated. Season 1 was not touched.')::text
 WHERE k.id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5'
   AND NOT EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CC_0368 (2026-11-07): holds%');

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = 'c08314df-cd89-459e-a253-47c58cfe6981'
     AND politician_id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5' AND is_incumbent AND full_name = 'Deb Goldberg';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: candidacy c08314df not on the survivor as an incumbent'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians k
   WHERE k.id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5' AND k.is_active AND k.is_incumbent
     AND (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = k.id) = 17
     AND EXISTS (SELECT 1 FROM essentials.politician_name_aliases x WHERE x.politician_id = k.id AND x.alias = 'Deb Goldberg')
     AND EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CC_0368 (2026-11-07): holds%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: survivor eb88bdd6 not in its target state'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = '57ce8d40-3a7d-4795-a1d5-3d21980d6448' AND NOT d.is_active AND NOT d.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates x WHERE x.politician_id = d.id)
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CC_0368 (2026-11-07): DUPLICATE of eb88bdd6%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: 57ce8d40 not deactivated, emptied and noted'; END IF;

  RAISE NOTICE 'CC_0368 post-verify OK';
END $$;

COMMIT;
