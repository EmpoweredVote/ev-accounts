-- CC_0435 — six "unlinked" statewide executive races are DUPLICATES of races we already hold,
-- and the contests were never uncalled.
--
-- ── HOW THIS LOOKED, AND WHY THAT READING WAS WRONG TWICE OVER ──────────────────────────────
-- Six races on the 2026-11-03 ballot carry `essentials.races.office_id IS NULL`. They were the
-- entire remaining `blocked` bucket of the transition programme, reported as "6 with no office",
-- and they are the most visible contests in it: four governors' races plus Maryland's Attorney
-- General and Comptroller.
--
-- 🔴 FIRST WRONG READING — "WE HOLD NO SUCH OFFICE". `blocked_no_office` is `races.office_id IS
-- NULL`, a fact about the RACE ROW. Every one of these offices exists and is seated. ⚠ No state
-- is missing a governor at all: we hold **51** governor offices, the 50 states plus Puerto Rico,
-- every one seated. A count of offices titled exactly `Governor` returns **48** and reads like
-- two missing states, because Indiana, Texas and Utah title theirs `<State> Governor`.
--
-- 🔴🔴 SECOND WRONG READING, AND IT IS THE ONE THIS FILE EXISTS FOR — "SO LINK THEM TO THEIR
-- OFFICES". The first draft of CC_0435 did exactly that and the database refused it:
-- `races_election_office_party_uniq` is a unique index on
-- `(election_id, office_id, coalesce(primary_party,'~nonpartisan~')) WHERE office_id IS NOT NULL`.
-- **Each of these six offices ALREADY has a 2026-11-03 race, properly linked and more complete:**
--
--   office                         canonical race (cands)      duplicate (cands)
--   Governor of Oregon             4b90a29b "Governor"     3    8702f03a "Governor of Oregon"        2
--   Governor of Maryland           a0da88c6 "Governor"     4    8c67c58e "Governor of Maryland"      3
--   Governor of Massachusetts      550c8d9f "Governor"     3    b8f82dc8 "Governor of Massachusetts" 1
--   Governor of Maine              3b70abd2 "Governor"     5    deafeeb8 "Governor of Maine"         3
--   Attorney General of Maryland   f355f3a6 "Attorney General" 2  c08f3d4e "Attorney General of Maryland" 2
--   Comptroller of Maryland        674bc8be "Comptroller"  2    e80f817e "Comptroller of Maryland"   2
--
-- 🟢 **AND THE CANONICAL COPIES ALREADY CARRY WINNERS.** Maura Healey, Anthony G. Brown, Brooke
-- Lierman, Wes Moore, Hannah Pingree and Tina Kotek are all recorded `won`, with the losers
-- recorded too. So these six contests were **never uncalled** — the programme's last six
-- "blocked" races were an artefact of six duplicate stub rows, and nothing about the ballot was
-- unknown. ▶ A flag that names a column is not a description of the world.
--
-- ⚠ THE DUPLICATE IS A STRICT SUBSET OF THE CANONICAL ROW IN EVERY CASE. Measured: zero people
-- appear on a duplicate and not on its canonical race; zero duplicate candidacies carry a
-- `result`; zero carry a `photo_url`. The Massachusetts pair is the clearest — the duplicate has
-- only Maura Healey while the canonical race has all three and the result. Nothing is lost by
-- removing a duplicate candidacy, and that was checked rather than assumed.
--
-- ── 🔴 WHY THIS IS A MERGE AND NOT A DELETE ─────────────────────────────────────────────────
-- The duplicates are not junk. `essentials.races` has NINE inbound foreign keys and several
-- CASCADE, so deleting these rows would have silently destroyed **16 authored ReadRank
-- questions** written on 2026-07-21 — 9 on Governor of Maine, 7 on Governor of Maryland — along
-- with 4 pipeline rows and 3 discovered sources, and would have ERRORED on a `candidate_staging`
-- row that has no `ON DELETE` rule at all.
--
-- 🟢 The subsystems were working against the DUPLICATES the whole time: every canonical race
-- holds **zero** questions, zero pipeline rows, zero sources and zero staging. So the content
-- exists only on the rows being removed, the move cannot collide with anything, and this is
-- CLAUDE.md's rule for office rows wearing different clothes — **move what hangs off the row
-- first, then delete, and gate on the END STATE rather than on the delete's own row count.**
--
-- 🔴 OVERWRITTEN/REMOVED VALUES, recorded here because nothing else will: six `essentials.races`
-- rows and their 13 `race_candidates` are deleted. Their ids, names and candidate lists are in
-- the table above and in `backend/data/transition-tracker/NOTES-duplicate-exec-races.md`.
--
-- @incumbency-decision: gated — this writes no `essentials.office_terms` row, but it DELETES
-- `race_candidates` rows that `check:incumbency` reads, and the same people hold candidacies on
-- the canonical races. The guard is scoped to every politician involved and proves no canonical
-- row moves from agreeing to contradicting.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0435_merge_duplicate_statewide_exec_races.sql

BEGIN;

CREATE TEMP TABLE cc0435_dupes ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Governor of Oregon',           '8702f03a-c028-42e3-b7f8-e17569dedff8'::uuid, '4b90a29b-5630-4628-b835-3e91ac4d4183'::uuid),
  ('Governor of Maryland',         '8c67c58e-f3a7-4822-bbbf-eb426ac13f87'::uuid, 'a0da88c6-a1cd-448b-b9e1-696eb9badceb'::uuid),
  ('Governor of Massachusetts',    'b8f82dc8-4f6c-41da-904a-ec8cceb73321'::uuid, '550c8d9f-66ff-46e2-a110-3b2c6286c1f0'::uuid),
  ('Governor of Maine',            'deafeeb8-bd5e-4fb1-b55d-40d8c12309fb'::uuid, '3b70abd2-699f-467f-b793-762ed4a7ac67'::uuid),
  ('Attorney General of Maryland', 'c08f3d4e-2188-4d7c-a598-f8b2bbfaa573'::uuid, 'f355f3a6-8327-4c98-a553-f0953a1c81c5'::uuid),
  ('Comptroller of Maryland',      'e80f817e-e292-4c8c-a10c-8b801fb32a13'::uuid, '674bc8be-03b1-4f9a-b461-99a149761666'::uuid)
) AS t(label, duplicate_race, canonical_race);

-- ── Premise ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_bad int; v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0435_dupes;
  IF v_n <> 6 THEN RAISE EXCEPTION 'CC_0435: expected 6 pairs, found %.', v_n; END IF;

  -- The duplicate must still be unlinked and the canonical must still be linked to the SAME
  -- election. If either has moved, the pairing in the header no longer describes the data.
  SELECT count(*) INTO v_bad
    FROM cc0435_dupes d
    JOIN essentials.races dr ON dr.id = d.duplicate_race
    JOIN essentials.races cr ON cr.id = d.canonical_race
   WHERE dr.office_id IS NOT NULL
      OR cr.office_id IS NULL
      OR dr.election_id <> cr.election_id;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0435: % pair(s) are no longer duplicate/canonical as described.', v_bad;
  END IF;

  -- 🔴 NOBODY MAY BE LOST. A person on the duplicate who is not on the canonical race would be
  -- destroyed by the delete, and that is the whole risk of this migration.
  SELECT count(*) INTO v_bad
    FROM cc0435_dupes d
    JOIN essentials.race_candidates a ON a.race_id = d.duplicate_race
   WHERE a.politician_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates b
                      WHERE b.race_id = d.canonical_race AND b.politician_id = a.politician_id);
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0435: % candidate(s) exist on a duplicate and NOT on its canonical race. '
      'Deleting would lose them. Add them to the canonical race first.', v_bad;
  END IF;

  -- No result and no photo may be lost either.
  SELECT count(*) INTO v_bad
    FROM cc0435_dupes d JOIN essentials.race_candidates a ON a.race_id = d.duplicate_race
   WHERE a.result IS NOT NULL OR a.photo_url IS NOT NULL;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0435: % duplicate candidacy/ies carry a result or a photo.', v_bad;
  END IF;

  -- 🟢 The canonical races must actually hold the answers this file claims they do.
  SELECT count(*) INTO v_bad
    FROM cc0435_dupes d
   WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates c
                      WHERE c.race_id = d.canonical_race AND c.result = 'won');
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0435: % canonical race(s) have no recorded winner — the claim that these '
      'contests were never uncalled is wrong for those.', v_bad;
  END IF;

  -- The canonical races must have nothing attached, or the moves below would collide.
  SELECT count(*) INTO v_bad
    FROM cc0435_dupes d
   WHERE EXISTS (SELECT 1 FROM essentials.readrank_questions q WHERE q.race_id = d.canonical_race);
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0435: % canonical race(s) already hold ReadRank questions.', v_bad;
  END IF;
END $$;

CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (
     SELECT politician_id FROM essentials.race_candidates
      WHERE race_id IN (SELECT duplicate_race FROM cc0435_dupes)
        AND politician_id IS NOT NULL);

-- Count what must survive, so the post-verify gates on preservation and not on a delete count.
CREATE TEMP TABLE cc0435_attached_before ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM essentials.readrank_questions      WHERE race_id IN (SELECT duplicate_race FROM cc0435_dupes)) AS questions,
  (SELECT count(*) FROM essentials.readrank_race_pipeline  WHERE race_id IN (SELECT duplicate_race FROM cc0435_dupes)) AS pipeline,
  (SELECT count(*) FROM essentials.discovered_sources      WHERE race_id IN (SELECT duplicate_race FROM cc0435_dupes)) AS sources,
  (SELECT count(*) FROM essentials.candidate_staging       WHERE race_id IN (SELECT duplicate_race FROM cc0435_dupes)) AS staging;

-- ── Move what hangs off the duplicate ────────────────────────────────────────────────────────
UPDATE essentials.readrank_questions q
   SET race_id = d.canonical_race
  FROM cc0435_dupes d WHERE q.race_id = d.duplicate_race;

UPDATE essentials.readrank_race_pipeline pl
   SET race_id = d.canonical_race
  FROM cc0435_dupes d WHERE pl.race_id = d.duplicate_race;

UPDATE essentials.discovered_sources s
   SET race_id = d.canonical_race
  FROM cc0435_dupes d WHERE s.race_id = d.duplicate_race;

-- 🔴 `candidate_staging` has TWO references and both must move. `race_id` has no ON DELETE rule,
-- so the delete below would error on it; `matched_candidate_id` points at a candidacy that is
-- about to be cascaded away, and is repointed to the SAME PERSON on the canonical race.
UPDATE essentials.candidate_staging s
   SET matched_candidate_id = cc.id
  FROM cc0435_dupes d
  JOIN essentials.race_candidates oc ON oc.race_id = d.duplicate_race
  JOIN essentials.race_candidates cc ON cc.race_id = d.canonical_race
                                    AND cc.politician_id = oc.politician_id
 WHERE s.matched_candidate_id = oc.id;

UPDATE essentials.candidate_staging s
   SET race_id = d.canonical_race
  FROM cc0435_dupes d WHERE s.race_id = d.duplicate_race;

-- ── Remove the duplicates ────────────────────────────────────────────────────────────────────
-- Cascades the 13 duplicate candidacies, each proved above to be a strict subset carrying no
-- result and no photo.
DELETE FROM essentials.races WHERE id IN (SELECT duplicate_race FROM cc0435_dupes);

-- ── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  b record; v_q int; v_pl int; v_s int; v_st int; v_left int; v_won int;
BEGIN
  SELECT * INTO b FROM cc0435_attached_before;

  SELECT count(*) INTO v_q  FROM essentials.readrank_questions     WHERE race_id IN (SELECT canonical_race FROM cc0435_dupes);
  SELECT count(*) INTO v_pl FROM essentials.readrank_race_pipeline WHERE race_id IN (SELECT canonical_race FROM cc0435_dupes);
  SELECT count(*) INTO v_s  FROM essentials.discovered_sources     WHERE race_id IN (SELECT canonical_race FROM cc0435_dupes);
  SELECT count(*) INTO v_st FROM essentials.candidate_staging      WHERE race_id IN (SELECT canonical_race FROM cc0435_dupes);

  -- 🔴 GATE ON PRESERVATION, NOT ON THE DELETE. The question is not "did six rows go" but "did
  -- everything that hung off them arrive". A cascade that ate the questions would leave the
  -- delete count looking perfect.
  IF v_q <> b.questions THEN
    RAISE EXCEPTION 'CC_0435: % ReadRank question(s) were attached to the duplicates and % are on '
      'the canonical races. The cascade ate them.', b.questions, v_q;
  END IF;
  IF v_pl <> b.pipeline OR v_s <> b.sources OR v_st <> b.staging THEN
    RAISE EXCEPTION 'CC_0435: attachments did not survive — pipeline %/%, sources %/%, staging %/%.',
      v_pl, b.pipeline, v_s, b.sources, v_st, b.staging;
  END IF;
  RAISE NOTICE 'CC_0435: moved % question(s), % pipeline row(s), % source(s), % staging row(s)',
    v_q, v_pl, v_s, v_st;

  -- Every duplicate is gone.
  SELECT count(*) INTO v_left FROM essentials.races WHERE id IN (SELECT duplicate_race FROM cc0435_dupes);
  IF v_left <> 0 THEN RAISE EXCEPTION 'CC_0435: % duplicate race(s) survive.', v_left; END IF;

  -- The canonical races still carry their winners.
  SELECT count(*) INTO v_won
    FROM cc0435_dupes d
   WHERE EXISTS (SELECT 1 FROM essentials.race_candidates c
                  WHERE c.race_id = d.canonical_race AND c.result = 'won');
  IF v_won <> 6 THEN
    RAISE EXCEPTION 'CC_0435: only % of 6 canonical races still have a winner.', v_won;
  END IF;

  -- The programme's blocked bucket for this date must now be empty.
  SELECT count(*) INTO v_left
    FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = DATE '2026-11-03' AND r.office_id IS NULL;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'CC_0435: % race(s) for 2026-11-03 still carry no office.', v_left;
  END IF;
  RAISE NOTICE 'CC_0435: no 2026-11-03 race carries a NULL office_id any more.';
END $$;

DO $$
DECLARE v_planned int; v_created int; v_repaired int; v_detail text;
BEGIN
  SELECT count(*) INTO v_planned FROM incumbency_before;
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the scope is EMPTY, so this gate asserted nothing.';
  END IF;
  RAISE NOTICE 'incumbency guard: % race row(s) in scope', v_planned;

  WITH after_state AS (
    SELECT rc.id AS race_candidate_id, rc.is_incumbent AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  ) AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id, b.politician_id, a.stored, a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                           coalesce(p.full_name,'(unnamed)'), c.race_candidate_id, c.stored, c.expected),
                    E'\n' ORDER BY coalesce(p.full_name,''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree', v_repaired;
  END IF;
  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

COMMIT;
