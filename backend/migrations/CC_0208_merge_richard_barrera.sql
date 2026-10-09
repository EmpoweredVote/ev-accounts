-- CC_0208 — merge the two Richard Barrera politician rows into the seat row
--
-- ONE PERSON, TWO ROWS. This is a duplicate, not two roles tethered together.
--
--   96485b13-9104-4057-99de-742df6df85ee  RETIRED
--     source `ballotpedia`, photo_origin_url barreraforedu.com, no office, is_incumbent false.
--     Carries his two 2026 Superintendent of Public Instruction candidacies and one image.
--   b04e1f2d-d1a4-43de-80db-bdc29dadfaeb  CANONICAL
--     external_id -870011, holds the office_terms row for Board Member (District D) at
--     San Diego Unified School District, is_incumbent true. Carries one image and nothing else.
--
-- EVIDENCE THEY ARE ONE MAN. His own Superintendent campaign site, barreraforedu.com, states it:
-- "In 2008, Richard Barrera was an elected democrat to the Board of the San Diego Unified" and
-- "As President of the San Diego Unified School Board, Richard Barrera spent the last 20 years…".
-- sandiegounified.org independently lists "District D - Richard Barrera - Board President", which
-- is the seat b04e1f2d holds. ⚠ The two rows publish DIFFERENT photographs and a side-by-side does
-- NOT settle them on sight — one is greyer and wears glasses. The campaign site's own words are
-- what settle it. The seat row's picture turned out to be the district's own portrait,
-- `Richard NEW 2020-21.jpg`; the retired row's is a newer sitting from the campaign.
--
-- WHY b04e1f2d SURVIVES. `backend/scripts/dedup-essentials-politicians.ts` scores a canonical row:
-- an office is +2, a photo_origin_url is +1. The office outranks the photo, and it is also the
-- safer survivor — it holds the only `office_terms` row, and an office with no term row goes
-- silently invisible (CLAUDE.md, "Writing"). Moving two race_candidates rows is trivial beside
-- moving occupancy.
--
-- 🔴 NOTHING HISTORICAL IS LOST, AND THAT WAS MEASURED, NOT ASSUMED. All 24 tables with a foreign
-- key to essentials.politicians were counted for both rows before this was written:
--     race_candidates     2 / 0
--     politician_images   1 / 1
--     office_terms        0 / 1
--     every inform.* table  0 / 0   ← no answers, no context, no evidence items
-- There is no stance history on either row, so no season can lose an answer. Leaving the split in
-- place is what costs us: a stance researched for his Superintendent run would attach to a row
-- that does not hold his seat, and the next person to look him up would research him again.
--
-- 🔴 THE RETIRED ID IS RECORDED, NOT DROPPED. CC_0207 added essentials.politician_merges for
-- exactly this. A deleted id is otherwise unresolvable for anything outside the foreign-key graph
-- — an old export, a bookmarked URL, the storage object still named 96485b13-…-headshot.jpg.
--
-- THE PHOTOGRAPH. b04e1f2d's image is the district's 2020-21 portrait and its photo_origin_url is
-- NULL, so its licence was asserted about a file whose source nobody recorded. It also fails the
-- quality bar: the head is 763 px of 1280, so the tightest possible 4:5 crop is 71.7% of frame
-- against a 62% ceiling — there is no crop of that original that passes. Shipped instead: a 4:5
-- crop of `Portrait-24-Edit_pp.jpeg` from barreraforedu.com (855x1280 at the origin), cut to
-- 710x888 — head 52.1%, air above the hair 9.0%, face centre exactly 50.0% of the width,
-- chroma 40.0. A pure crop, nothing enlarged, nothing composited. Provenance is written for the
-- first time. ⚠ The head top had to be measured by hand: the graffiti mural behind him defeats
-- both the background-departure scan (said row 6) and GrabCut (said row 0, absorbing half the
-- frame). A luma-and-saturation profile down the face columns puts his hair at row 110.
--
-- Idempotent: every write is guarded, and a re-run verifies and changes nothing.
--
-- Rollback (the retired row cannot be restored by this file — its content is in the ledger):
--   UPDATE essentials.race_candidates SET politician_id = '96485b13-…' WHERE id IN
--     ('3ddafab8-4d1c-4a32-81e5-c60d2557527c','17565373-88ac-4431-a5b1-939468890a03');
--   b04e1f2d photo_custom_url was
--     .../politician_photos/b04e1f2d-d1a4-43de-80db-bdc29dadfaeb-headshot.jpg
--   b04e1f2d photo_origin_url was NULL; its image licence was 'government-official'.
--   Both old storage objects were left in place.

BEGIN;

DO $$
DECLARE
  c_retired   constant uuid := '96485b13-9104-4057-99de-742df6df85ee';
  c_canonical constant uuid := 'b04e1f2d-d1a4-43de-80db-bdc29dadfaeb';
  c_name      constant text := 'Richard Barrera';
  c_photo     constant text :=
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/merges/2026-10-barrera/b04e1f2d-d1a4-43de-80db-bdc29dadfaeb.jpg';
  c_origin    constant text :=
    'https://images.squarespace-cdn.com/content/v1/67b0f232273eb817e2f7a289/7d6f111a-19b1-488f-a3cc-7a4cebfb1bce/Portrait-24-Edit_pp.jpeg?format=original';
  c_licence   constant text :=
    'Campaign portrait published by Richard Barrera''s own site, barreraforedu.com (Portrait-24-Edit_pp.jpeg, 855x1280 at the origin). Cropped 4:5 to 710x888; nothing enlarged, nothing composited. Replaces a `government-official` claim made while photo_origin_url was NULL.';
  r           record;
  v_races     int;
  v_imgs      int;
  v_terms     int;
  v_moved     int;
  v_left      int;
BEGIN
  -- ------------------------------------------------------------- preconditions
  SELECT count(*) FILTER (WHERE id = c_retired)   AS has_retired,
         count(*) FILTER (WHERE id = c_canonical) AS has_canonical
    INTO r
    FROM essentials.politicians WHERE id IN (c_retired, c_canonical);

  IF r.has_canonical <> 1 THEN
    RAISE EXCEPTION 'CC_0208: canonical row % is missing', c_canonical;
  END IF;

  IF r.has_retired = 0 THEN
    -- Already merged. Confirm the ledger says so, then stop without touching anything.
    IF NOT EXISTS (SELECT 1 FROM essentials.politician_merges
                    WHERE retired_id = c_retired AND canonical_id = c_canonical) THEN
      RAISE EXCEPTION 'CC_0208: % is gone but no ledger entry records where it went', c_retired;
    END IF;
    RAISE NOTICE 'CC_0208: already applied — % is retired and the ledger records it', c_retired;
    RETURN;
  END IF;

  PERFORM 1 FROM essentials.politicians
   WHERE id = c_retired AND full_name = c_name AND is_active;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0208: % is not an active row named "%" — refusing', c_retired, c_name;
  END IF;
  PERFORM 1 FROM essentials.politicians
   WHERE id = c_canonical AND full_name = c_name AND is_active AND is_incumbent;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0208: % is not an active, incumbent row named "%" — refusing',
      c_canonical, c_name;
  END IF;

  -- The canonical row must be the one holding the seat. If that ever flips, the choice of
  -- survivor above is wrong and this migration must not run.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.politician_id = c_canonical) THEN
    RAISE EXCEPTION 'CC_0208: canonical row % holds no office_terms row — it is not the seat row',
      c_canonical;
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.politician_id = c_retired) THEN
    RAISE EXCEPTION 'CC_0208: retired row % holds an office_terms row — occupancy would be lost',
      c_retired;
  END IF;

  -- 🔴🔴 FIVE TABLES DO NOT PROTECT THEMSELVES, AND TWO OF THEM HOLD STANCE RESEARCH.
  -- Of the 27 foreign keys into essentials.politicians, most are NO ACTION or RESTRICT: Postgres
  -- refuses the DELETE below while any row still points at the retired id, so the FK is the guard
  -- and no count is needed. These five are different:
  --
  --     essentials.politician_name_aliases        ON DELETE CASCADE
  --     inform.evidence_items                     ON DELETE CASCADE
  --     inform.politician_context_evidence        ON DELETE CASCADE
  --     inform.topic_rewrite_stance_proposals     ON DELETE CASCADE
  --     essentials.quest_verified_facts           ON DELETE SET NULL
  --
  -- A CASCADE row is deleted with the politician, SILENTLY — no error, nothing to notice
  -- afterwards. Two of them are stance-research artefacts. That is the one way a merge can destroy
  -- history that no season and no ledger can give back, so they are counted here EXPLICITLY and a
  -- single row aborts the whole migration. Any future merge must do the same.
  --
  -- 🔴 REFUSE IF THE RETIRED ROW CARRIES ANYTHING THIS MIGRATION DOES NOT MOVE. The counts below
  -- were measured when it was written; anything else appearing since means the merge is no longer
  -- complete and would drop data on the floor.
  SELECT count(*) INTO v_races FROM essentials.race_candidates WHERE politician_id = c_retired;
  SELECT count(*) INTO v_imgs  FROM essentials.politician_images WHERE politician_id = c_retired;
  IF v_races <> 2 THEN
    RAISE EXCEPTION 'CC_0208: retired row has % race_candidates rows, expected 2', v_races;
  END IF;
  IF v_imgs <> 1 THEN
    RAISE EXCEPTION 'CC_0208: retired row has % image rows, expected 1', v_imgs;
  END IF;
  FOR r IN
    SELECT t AS tbl,
           (xpath('/row/c/text()', query_to_xml(
              format('SELECT count(*) AS c FROM %s WHERE %I = %L', t, c, c_retired),
              false, true, '')))[1]::text::int AS n
      FROM (VALUES
        -- the five that do not protect themselves, CASCADE and SET NULL
        ('essentials.politician_name_aliases','politician_id'),
        ('inform.evidence_items','politician_id'),
        ('inform.politician_context_evidence','politician_id'),
        ('inform.topic_rewrite_stance_proposals','politician_id'),
        ('essentials.quest_verified_facts','politician_id'),
        -- and the stance tables, counted anyway: their FK would stop the delete, but a merge that
        -- reached them should say so in its own words rather than as a constraint violation
        ('inform.politician_answers','politician_id'),
        ('inform.politician_context','politician_id'),
        ('inform.stance_coder_labels','politician_id'),
        ('inform.stance_gold_labels','politician_id'),
        ('inform.stance_research_review','politician_id')
      ) AS v(t, c)
  LOOP
    IF r.n <> 0 THEN
      RAISE EXCEPTION 'CC_0208: retired row carries % row(s) in % — this merge does not move them, so it would drop them',
        r.n, r.tbl;
    END IF;
  END LOOP;

  -- ---------------------------------------------------------------------- move
  UPDATE essentials.race_candidates
     SET politician_id = c_canonical
   WHERE politician_id = c_retired;
  GET DIAGNOSTICS v_moved = ROW_COUNT;
  IF v_moved <> 2 THEN
    RAISE EXCEPTION 'CC_0208: moved % race_candidates rows, expected 2', v_moved;
  END IF;

  -- The photograph. Both rows carry a real picture of him; the canonical keeps ONE image row, now
  -- pointing at the campaign crop, and gains the provenance it never had.
  UPDATE essentials.politicians
     SET photo_custom_url = c_photo,
         photo_origin_url = c_origin,
         last_update_date = now()
   WHERE id = c_canonical
     AND (photo_custom_url IS DISTINCT FROM c_photo OR photo_origin_url IS DISTINCT FROM c_origin);

  UPDATE essentials.politician_images
     SET url = c_photo, photo_license = c_licence
   WHERE politician_id = c_canonical AND type = 'default'
     AND (url IS DISTINCT FROM c_photo OR photo_license IS DISTINCT FROM c_licence);

  DELETE FROM essentials.politician_images WHERE politician_id = c_retired;

  -- -------------------------------------------------------------------- ledger
  -- Written BEFORE the delete and in the same transaction. A merge whose mapping is not recorded
  -- is the silent kind CC_0207 exists to prevent.
  INSERT INTO essentials.politician_merges
    (retired_id, canonical_id, retired_name, migration, evidence, moved)
  VALUES (
    c_retired, c_canonical, c_name, 'CC_0208',
    'One man, two rows. barreraforedu.com (his Superintendent campaign site) states "In 2008, '
    || 'Richard Barrera was an elected democrat to the Board of the San Diego Unified" and names '
    || 'him President of that board; sandiegounified.org independently lists "District D - Richard '
    || 'Barrera - Board President", the seat the canonical row holds. The two rows published '
    || 'different photographs and a side-by-side did NOT settle them — the campaign site''s own '
    || 'words did. Canonical chosen by the score in dedup-essentials-politicians.ts (office +2 '
    || 'beats photo_origin_url +1) and because it holds the only office_terms row. Measured before '
    || 'merging: the retired row carried nothing in any inform.* table, so no season lost an answer.',
    jsonb_build_object('essentials.race_candidates', v_moved,
                       'essentials.politician_images', v_imgs)
  )
  ON CONFLICT (retired_id) DO NOTHING;

  -- -------------------------------------------------------------------- delete
  -- Everything else that references politicians is NO ACTION or RESTRICT, so Postgres refuses this
  -- while any row still points at the retired id. That refusal is a guard, not a bug — translate
  -- it into words rather than letting a raw constraint name reach the operator.
  BEGIN
    DELETE FROM essentials.politicians WHERE id = c_retired;
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'CC_0208: something still references % — re-route it before retiring the row (%)',
      c_retired, SQLERRM;
  END;

  -- -------------------------------------------------------------------- verify
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE id = c_retired) THEN
    RAISE EXCEPTION 'CC_0208: retired row % still exists after the delete', c_retired;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_merges
                  WHERE retired_id = c_retired AND canonical_id = c_canonical
                    AND migration = 'CC_0208') THEN
    RAISE EXCEPTION 'CC_0208: the ledger has no entry for this merge';
  END IF;

  SELECT count(*) INTO v_races FROM essentials.race_candidates WHERE politician_id = c_canonical;
  IF v_races <> 2 THEN
    RAISE EXCEPTION 'CC_0208: canonical row has % race_candidates rows, expected 2', v_races;
  END IF;
  SELECT count(*) INTO v_imgs FROM essentials.politician_images
   WHERE politician_id = c_canonical AND type = 'default';
  IF v_imgs <> 1 THEN
    RAISE EXCEPTION 'CC_0208: canonical row has % default image rows, expected exactly 1', v_imgs;
  END IF;
  SELECT count(*) INTO v_terms FROM essentials.office_terms WHERE politician_id = c_canonical;
  IF v_terms <> 1 THEN
    RAISE EXCEPTION 'CC_0208: canonical row has % office_terms rows, expected 1 — occupancy moved', v_terms;
  END IF;

  -- The grid reads images[] and the backend reads the scalar; they must agree (CC_0195).
  PERFORM 1 FROM essentials.politicians p
    JOIN essentials.politician_images i ON i.politician_id = p.id AND i.type = 'default'
   WHERE p.id = c_canonical AND p.photo_custom_url = i.url AND p.photo_custom_url = c_photo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0208: the scalar and the images row disagree, or neither is the new crop';
  END IF;

  -- Nothing anywhere may still point at the retired id.
  SELECT count(*) INTO v_left FROM essentials.race_candidates WHERE politician_id = c_retired;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'CC_0208: % race_candidates rows still point at the retired row', v_left;
  END IF;

  -- And exactly one active Richard Barrera must remain.
  SELECT count(*) INTO v_left FROM essentials.politicians
   WHERE is_active AND first_name = 'Richard' AND last_name = 'Barrera';
  IF v_left <> 1 THEN
    RAISE EXCEPTION 'CC_0208: % active rows named Richard Barrera remain, expected 1', v_left;
  END IF;

  RAISE NOTICE 'CC_0208: Barrera merged into %; 2 candidacies moved, ledger written', c_canonical;
END $$;

COMMIT;
