-- CC_0211 — retire 8 archived duplicate politician rows, re-route what they were holding,
--            and fix TWO WRONG FACES found on the way.
--
-- Found by a lead the duplicate-people guard CANNOT generate: 8 politicians whose
-- `photo_custom_url` object name carries the id of a SECOND politician row bearing the same
-- person's name. 🔴 THE GUARD KEYS ON ACTIVE ROWS ONLY, and every one of these duplicates was
-- already `is_active = false`, so all 8 are invisible to it and none appears in the 60-pair
-- `duplicate-people-baseline.json`. The photo filename was the only remaining trace.
--
--
-- ══ ALL EIGHT PAIRS ARE ONE PERSON. Two independent sources each ═════════════════════════════
--
--   Brent Taylor        TN Senate 31 — TN legislator directory lists exactly ONE Taylor, District 31;
--                       both rows' photo_origin_url is the S31 member page.
--   London Lamar        TN Senate 33 — exactly ONE Lamar, District 33; same shape.
--   Vincent Dixie       TN House 54  — exactly ONE Dixie, District 54; same shape.
--   Patricia D. Jehlen  MA Senate, Second Middlesex — malegislature.gov/Legislators/Profile/PDJ0
--                       reads "Senator Patricia D. Jehlen … Democrat - Second Middlesex".
--   Emma Sharif         Compton Mayor — en.wikipedia.org/wiki/Emma_Sharif REDIRECTS to "List of
--                       mayors of Compton, California", which states "Incumbent Emma Sharif since
--                       June 30, 2021". Both rows cite that exact URL.
--   Chelsea Byers       West Hollywood Council — weho.org page titled "Councilmember Chelsea Lee
--                       Byers"; the council list holds exactly one Byers. The retired row carries
--                       her full legal name from the CA SoS roster.
--   Kelly Smith         Cedar Hills UT Council — the city roster holds exactly ONE Kelly Smith
--                       (per-image altText); Utah Policy, 8 Jan 2026, names "current Cedar Hills
--                       City Council member Kelly Smith".
--   Jeffrey Hulum III   MS House 119 — already ruled same_person by `CC_0186` on three sources.
--
-- Every retired row is `is_active = false` and holds NO seat, NO candidacy and NO stance answer.
-- 🔴 ALL FIVE CASCADING FOREIGN KEYS MEASURE ZERO ON ALL EIGHT — nothing is destroyed silently.
-- The gate below re-counts them at write time and refuses on a single row.
--
--
-- ══ 🔴🔴 WHAT THE RETIRED ROWS WERE ACTUALLY HOLDING: THE CAMPAIGN-FINANCE BRIDGE ═════════════
--
-- `transparent_motivations.politician_sources` had a row for every one of the eight.
--
-- 🔴 **PATRICIA JEHLEN'S ENTIRE CAMPAIGN FINANCE HUNG ON THE UNREACHABLE ROW: 3,649
--    contributions, $697,212.68.** Her seated row returned `contribution_count = 0` from
--    /api/campaign-finance/politician/<id>/summary while the archived row returned the money.
--    Confirmed live with a positive control (Brent Taylor's row returns 298).
--    The source row's own note settles the attribution: "Nov 2026 ballot seed — State Senator
--    (2nd Middlesex) — OCPF filer: Jehlen, Patricia D."
-- Emma Sharif had 5 cal_access committee registrations stranded the same way; Chelsea Byers 2.
--
--
-- ══ 🔴🔴 TWO WRONG FACES, FOUND BY LOOKING ═══════════════════════════════════════════════════
--
-- 1. **PATRICIA D. JEHLEN was publishing a photograph of SENATOR VANNA HOWARD.** Jehlen was born
--    in 1943; the published portrait is of a much younger woman. malegislature.gov's own
--    `alt="Photo of Patricia D. Jehlen"` portrait is an elderly woman with white hair.
--    A perceptual match against all 40 roster portraits returned Vanna Howard at diff 0.0571
--    against a next-best 0.6806 — the SAME photograph. The roster lists "Vanna Howard, First
--    Middlesex" IMMEDIATELY BEFORE "Patricia Jehlen, Second Middlesex": an off-by-one scrape of
--    the Senate roster page, which is exactly what the retired row's photo_origin_url points at.
--    FIXED HERE: her official portrait, cropped 4:5 to 987x1234, head 52.2%, air above the hair
--    8.8%, face centre 50.1%, chroma 58.7. A PURE CROP with no resize.
--    🟢 malegislature.gov serves portraits SIZE-PARAMETERISED IN THE PATH —
--       /Legislators/Profile/<size>/PDJ0.jpg. Edge energy at a matched 600 px plateaus at 1200
--       (2.148) and FALLS beyond it (3000 -> 2.129), so 1200x1234 is the true native file and
--       everything larger is an upscale. Worth knowing for every MA legislator.
--
-- 2. **VINCENT DIXIE was publishing a photograph of a different man.** The Tennessee member page
--    for House District 54 carries `alt="Photo of Vincent Dixie"`: a man with glasses, a
--    grey-flecked beard and a red bow tie. The published file is a clean-shaven man in a green
--    tie. The CORRECT photograph of him was already sitting unreferenced in the bucket AT HIS OWN
--    CANONICAL ID — that is the file this migration points him at.
--    ⚠ THE PERCEPTUAL METRIC GOT THIS ONE BACKWARDS: it scored the wrong man 0.6099 against the
--    right man's 1.5452, because the wrong photograph shares the generic studio composition while
--    the right one is a different pose and background. **Only looking at the three pictures
--    side by side settled it.** The programme's rule holds: the picture is the control.
--
-- ⚠ The other six photographs were each checked against an authoritative portrait whose own
--   per-image `alt` names the person, and all six are correct. Emma Sharif's is BYTE-IDENTICAL to
--   comptoncity.org's `alt="Emma Sharif"` file. Brent Taylor's and London Lamar's are the
--   Tennessee official portraits themselves.
--
-- ⚠ A SWEEP OF ALL 40 MASSACHUSETTS SENATORS found no second wrong face. It first flagged 8, and
--   7 were FALSE POSITIVES — a 64x64 luma signature cannot tell "a different photograph of the
--   right person" from "the wrong person", and the threshold was too loose. Looking at the
--   pictures reduced 8 to 1. **Do not trust that metric without the picture.**
--
--
-- ══ WHAT THIS MIGRATION DOES ═════════════════════════════════════════════════════════════════
--
--   1. re-routes `transparent_motivations.politician_sources` (8 rows) from retired -> canonical
--   2. re-routes `essentials.politician_contacts` (2 rows) likewise
--   3. DELETES the retired rows' `essentials.politician_images` rows (4). They are NOT moved:
--      each points at the very object the canonical row already serves, and moving one would give
--      the canonical row TWO type='default' rows, making the browse grid's find() pick an
--      arbitrary one. That is the CC_0195/CC_0196 hazard.
--   4. repoints each canonical row's `photo_custom_url` AND its type='default' image row at
--      politician_photos/dedupe/2026-10/<canonical-id>.jpg — so no filename names a retired id
--   5. records all 8 in `essentials.politician_merges` with evidence (CC_0207's ledger)
--   6. deletes the 8 retired rows
--
-- Every old object was left in the bucket and NOTHING was overwritten, so each photo change
-- reverts with one UPDATE. Idempotent: each UPDATE is guarded on the value differing, and the
-- retired rows are gone on a re-run, which the gate treats as already-done.
--
-- Rollback for the two faces:
--   d40a0eda … photo_custom_url .../politician_photos/215462b8-ddd2-4a38-bcca-b5f240944479-headshot.jpg  (Vanna Howard — WRONG)
--   830d155a … photo_custom_url .../politician_photos/a201565a-0aa1-4b6a-9349-6ee7abe90252-headshot.jpg  (wrong man)

BEGIN;

DO $$
DECLARE
  v_base   constant text :=
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dedupe/2026-10/';
  r        record;
  n_seen   int := 0;
  n_done   int := 0;
  n_src    int := 0;
  n_con    int := 0;
  n_img    int := 0;
  v_src    int;
  v_con    int;
  v_img    int;
  v_url    text;
  v_grid   text;
  v_ndef   int;
  v_cnt    bigint;
BEGIN
  FOR r IN
    SELECT b.a_id::uuid AS a_id, b.b_id::uuid AS b_id, b.a_nm, b.b_nm, b.origin, b.lic, b.ev
      FROM (VALUES
        ('00b1ee2d-c4e1-47f8-aae8-83974a625ef3','cad06d77-75d3-42c6-9bf2-6f9921ff9781',
         'Brent Taylor','Brent Taylor', NULL, NULL,
         'One man, two rows. The Tennessee General Assembly Senate directory lists exactly ONE Taylor — "Taylor, Brent R … District 31" — and the canonical row holds Senate District 31. Both rows carried the same photo_origin_url, the S31 member page. The retired row was already is_active=false with no seat, no candidacy and no stance answer, and all five cascading FKs measured zero. Photograph verified against the member page''s own alt="Photo of Brent Taylor": it is the same photograph, and it is correct.'),
        ('a3aac8fc-d8cb-4cb7-b6be-e5b0fa97c15a','201cc4fa-483e-418b-935b-4f7ad852c9b6',
         'Chelsea Byers','Chelsea Lee Byers', NULL, NULL,
         'One woman, two rows, differing only by her middle name. weho.org publishes a page titled "Councilmember Chelsea Lee Byers" and its council list — Heilman, Hang, Byers, Erickson, Meister — holds exactly one Byers; the canonical row holds the West Hollywood council seat. The retired row carried her full legal name from the California Secretary of State city roster and its photo_origin_url was her own campaign site, chelsea4weho.com. It held 2 cal_access committee registrations (0 contributions) and 1 contact, both re-routed here. Photograph checked against weho.org''s own portrait: same woman, correct.'),
        ('174f3f47-e4ee-4775-ab6f-f1039d608098','ad1c9e2a-2ea0-4fad-99c0-ddb2aa467f4a',
         'Emma Sharif','Emma Sharif', NULL, NULL,
         'One woman, two rows. Both carried the identical photo_origin_url, en.wikipedia.org/wiki/Emma_Sharif, which redirects to "List of mayors of Compton, California" — an article stating "Incumbent Emma Sharif since June 30, 2021". The canonical row holds the Compton Mayor seat. The retired row held 5 cal_access committee registrations (0 contributions) and 1 contact, re-routed here. Photograph verified BYTE-IDENTICAL to comptoncity.org''s portrait carrying alt="Emma Sharif".'),
        ('3e9b6f7f-1cb8-49e9-b645-086390226f75','6ff3ff30-00b9-4077-8cde-700cf687d106',
         'Jeffrey Hulum III','Jeffrey Hulum III', NULL, NULL,
         'One man, two rows, already ruled same_person when CC_0186 moved his six Season-1 stances onto the seated row on 2026-09-30 — settled then by three independent sources (Open States ms.csv, FEC H6MS04242, Wikipedia) and by the fact that his state-house district lies inside the congressional district he was the nominee for. This migration retires the emptied row CC_0186 left behind and re-keys the photo object, which still carried the retired id. Photograph checked against the Ballotpedia page "Jeffrey Hulum III": same man.'),
        ('92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4','e96d79ea-0f4f-4a17-9a94-8fbefed6e5d5',
         'Kelly Smith','Kelly Smith', NULL, NULL,
         'One woman, two rows. Both carried the identical photo_origin_url, the cedarhills.org "Mayor & City Council" roster, which holds exactly ONE Kelly Smith — her portrait asset carries altText="Kelly Smith". Utah Policy, 8 January 2026, independently names "current Cedar Hills City Council member Kelly Smith". The canonical row holds the Cedar Hills City Council seat. Photograph verified against the city asset: the same photograph, correct.'),
        ('9c83e282-cb78-4e39-aa1e-13875a86e872','a770cc10-dde6-4f1a-938d-af12e632b420',
         'London Lamar','London Lamar', NULL, NULL,
         'One woman, two rows. The Tennessee Senate directory lists exactly ONE Lamar — "Lamar, London D … District 33" — and the canonical row holds Senate District 33. Both rows carried the same photo_origin_url, the S33 member page. Photograph verified against that page''s own alt="Photo of London Lamar": it is the same photograph, and it is correct.'),
        ('d40a0eda-36fc-4032-8382-20c76a36d6a6','215462b8-ddd2-4a38-bcca-b5f240944479',
         'Patricia D. Jehlen','Patricia D. Jehlen',
         'https://malegislature.gov/Legislators/Profile/1200/PDJ0.jpg',
         'Official portrait of the Senator published by the Massachusetts General Court on her own member profile, malegislature.gov/Legislators/Profile/PDJ0, where the image carries alt="Photo of Patricia D. Jehlen". Served size-parameterised in the path; 1200x1234 is the native file (edge energy plateaus there and falls beyond). Cropped 4:5 only — no resize, nothing composited. REPLACES A PHOTOGRAPH OF A DIFFERENT PERSON: the file published here until now was Senator Vanna Howard, taken by an off-by-one scrape of the Senate roster page where Howard is listed immediately before Jehlen.',
         'One woman, two rows. malegislature.gov/Legislators/Profile/PDJ0 reads "Senator Patricia D. Jehlen … Democrat - Second Middlesex", the seat the canonical row holds. THE RETIRED ROW HELD HER ENTIRE CAMPAIGN FINANCE: one ocpf source (external_id 12008, noted "Nov 2026 ballot seed — State Senator (2nd Middlesex) — OCPF filer: Jehlen, Patricia D.") carrying 3,649 contributions totalling $697,212.68, while her seated row returned contribution_count = 0 from the live API. Re-routed here. The retired row also carried a photograph OF A DIFFERENT SENATOR, Vanna Howard, which is replaced in this migration.'),
        ('830d155a-394e-463c-999d-bcf154460225','a201565a-0aa1-4b6a-9349-6ee7abe90252',
         'Vincent Dixie','Vincent Dixie', NULL,
         'Tennessee General Assembly official member portrait for House District 54, verified against the member page''s own alt="Photo of Vincent Dixie" (glasses, grey-flecked beard, red bow tie). (C) State of Tennessee — editorial or personal use only. REPLACES A PHOTOGRAPH OF A DIFFERENT MAN: the file published here until now showed a clean-shaven man in a green tie. The correct photograph was already in the bucket, unreferenced, under his own canonical id.',
         'One man, two rows. The Tennessee House directory lists exactly ONE Dixie — "Dixie, Vincent D … District 54" — and the canonical row holds House District 54. Both rows carried the same photo_origin_url, the H54 member page. THE PUBLISHED PHOTOGRAPH WAS OF A DIFFERENT MAN; the correct one, matching the member page''s alt="Photo of Vincent Dixie", was sitting unreferenced in the bucket at his own canonical id and is what this migration publishes.')
      ) AS b(a_id, b_id, a_nm, b_nm, origin, lic, ev)
  LOOP
    n_seen := n_seen + 1;

    -- already retired on an earlier run? then this pair is done.
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.b_id) THEN
      IF NOT EXISTS (SELECT 1 FROM essentials.politician_merges WHERE retired_id = r.b_id) THEN
        RAISE EXCEPTION 'CC_0211: % retired row % is gone but has NO ledger entry', r.a_nm, r.b_id;
      END IF;
      n_done := n_done + 1;
      CONTINUE;
    END IF;

    -- ─────────────────────────────────────────────────────── preconditions
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.a_id AND full_name = r.a_nm) THEN
      RAISE EXCEPTION 'CC_0211: canonical row % is not named "%" — refusing to touch the wrong row',
        r.a_id, r.a_nm;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.b_id AND full_name = r.b_nm) THEN
      RAISE EXCEPTION 'CC_0211: retired row % is not named "%" — refusing', r.b_id, r.b_nm;
    END IF;
    IF (SELECT is_active FROM essentials.politicians WHERE id = r.b_id) THEN
      RAISE EXCEPTION 'CC_0211: % retired row is STILL ACTIVE — refusing to delete a live person', r.a_nm;
    END IF;

    -- the retired row must hold no seat, no candidacy and no researched position
    SELECT count(*) INTO v_cnt FROM essentials.office_terms WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0211: % retired row holds % office_terms', r.a_nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM essentials.race_candidates WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0211: % retired row holds % race_candidates', r.a_nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM inform.politician_answers WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0211: % retired row holds % stance answers', r.a_nm, v_cnt; END IF;

    -- 🔴 the five CASCADING foreign keys. A row here is deleted SILENTLY with the politician,
    -- and two of them are stance research. Abort on a single row.
    SELECT count(*) INTO v_cnt FROM essentials.politician_name_aliases WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0211: % would CASCADE-destroy % politician_name_aliases', r.a_nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM inform.evidence_items WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0211: % would CASCADE-destroy % inform.evidence_items (STANCE RESEARCH)', r.a_nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM inform.politician_context_evidence WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0211: % would CASCADE-destroy % politician_context_evidence (STANCE RESEARCH)', r.a_nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM inform.topic_rewrite_stance_proposals WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0211: % would CASCADE-destroy % topic_rewrite_stance_proposals', r.a_nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM essentials.quest_verified_facts WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0211: % would SET NULL on % quest_verified_facts', r.a_nm, v_cnt; END IF;

    SELECT count(*) INTO v_ndef FROM essentials.politician_images
      WHERE politician_id = r.a_id AND type = 'default';
    IF v_ndef <> 1 THEN
      RAISE EXCEPTION 'CC_0211: % canonical row has % type=default image rows, expected exactly 1', r.a_nm, v_ndef;
    END IF;

    -- ───────────────────────────────────────────────────── re-route, then write
    WITH moved AS (
      UPDATE transparent_motivations.politician_sources
         SET essentials_politician_id = r.a_id
       WHERE essentials_politician_id = r.b_id
      RETURNING 1)
    SELECT count(*) INTO v_cnt FROM moved;
    v_src := v_cnt::int; n_src := n_src + v_src;

    WITH moved AS (
      UPDATE essentials.politician_contacts
         SET politician_id = r.a_id
       WHERE politician_id = r.b_id
      RETURNING 1)
    SELECT count(*) INTO v_cnt FROM moved;
    v_con := v_cnt::int; n_con := n_con + v_con;

    -- the retired row's image rows point at the object the canonical row already serves.
    -- Moving one would make TWO type='default' rows and the grid's find() would pick arbitrarily.
    WITH gone AS (
      DELETE FROM essentials.politician_images WHERE politician_id = r.b_id RETURNING 1)
    SELECT count(*) INTO v_cnt FROM gone;
    v_img := v_cnt::int; n_img := n_img + v_img;

    v_url := v_base || r.a_id::text || '.jpg';

    UPDATE essentials.politicians
       SET photo_custom_url = v_url,
           photo_origin_url = coalesce(r.origin, photo_origin_url),
           last_update_date = now()
     WHERE id = r.a_id
       AND (photo_custom_url IS DISTINCT FROM v_url
            OR (r.origin IS NOT NULL AND photo_origin_url IS DISTINCT FROM r.origin));

    UPDATE essentials.politician_images
       SET url = v_url,
           photo_license = coalesce(r.lic, photo_license)
     WHERE politician_id = r.a_id
       AND type = 'default'
       AND (url IS DISTINCT FROM v_url
            OR (r.lic IS NOT NULL AND photo_license IS DISTINCT FROM r.lic));

    INSERT INTO essentials.politician_merges
           (retired_id, canonical_id, retired_name, migration, evidence, moved)
    VALUES (r.b_id, r.a_id, r.b_nm, 'CC_0211', r.ev,
            jsonb_build_object('transparent_motivations.politician_sources', v_src,
                               'essentials.politician_contacts', v_con,
                               'essentials.politician_images_deleted', v_img))
    ON CONFLICT (retired_id) DO NOTHING;

    DELETE FROM essentials.politicians WHERE id = r.b_id;

    -- ──────────────────────────────────────────────────────────── verify
    IF EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.b_id) THEN
      RAISE EXCEPTION 'CC_0211: % retired row still exists after the delete', r.a_nm;
    END IF;
    SELECT p.photo_custom_url,
           (SELECT i.url FROM essentials.politician_images i
             WHERE i.politician_id = r.a_id AND i.type = 'default' LIMIT 1),
           (SELECT count(*) FROM essentials.politician_images i
             WHERE i.politician_id = r.a_id AND i.type = 'default')
      INTO v_url, v_grid, v_ndef
      FROM essentials.politicians p WHERE p.id = r.a_id;
    IF v_ndef <> 1 THEN
      RAISE EXCEPTION 'CC_0211: % has % type=default rows after the write, expected 1', r.a_nm, v_ndef;
    END IF;
    IF v_url IS DISTINCT FROM v_base || r.a_id::text || '.jpg' THEN
      RAISE EXCEPTION 'CC_0211: % photo_custom_url is %, expected %', r.a_nm, coalesce(v_url,'<null>'),
        v_base || r.a_id::text || '.jpg';
    END IF;
    -- The grid reads images[] and the backend reads the scalar; if they disagree the API looks
    -- right while the page does not change. That is CC_0195.
    IF v_grid IS DISTINCT FROM v_url THEN
      RAISE EXCEPTION 'CC_0211: % renders % in the grid but % through the API — they must agree',
        r.a_nm, coalesce(v_grid,'<null>'), coalesce(v_url,'<null>');
    END IF;
    -- no object name may still carry a retired id
    IF v_url LIKE '%' || r.b_id::text || '%' THEN
      RAISE EXCEPTION 'CC_0211: % still serves an object named after the retired row', r.a_nm;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.politician_merges
                    WHERE retired_id = r.b_id AND canonical_id = r.a_id AND migration = 'CC_0211') THEN
      RAISE EXCEPTION 'CC_0211: % has no ledger entry', r.a_nm;
    END IF;

    n_done := n_done + 1;
  END LOOP;

  IF n_seen <> 8 OR n_done <> 8 THEN
    RAISE EXCEPTION 'CC_0211: saw % pairs and completed %, expected 8 and 8', n_seen, n_done;
  END IF;

  -- ───────────────────────────────── the finding this migration exists for
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
   WHERE s.essentials_politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6';
  IF v_cnt <> 3649 THEN
    RAISE EXCEPTION 'CC_0211: Jehlen''s canonical row reads % contributions, expected 3649', v_cnt;
  END IF;

  RAISE NOTICE 'CC_0211: 8 archived duplicate rows retired. Moved % finance sources and % contacts, dropped % duplicate image rows. Jehlen''s 3,649 contributions now answer on her seated row, and two wrong faces (Jehlen, Dixie) are corrected.',
    n_src, n_con, n_img;
END $$;

COMMIT;
