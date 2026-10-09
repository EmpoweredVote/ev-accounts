-- CC_0212 — retire 3 `ocpf_seed` duplicate rows and recover the campaign finance stranded on them.
--
-- Direct follow-on from CC_0211, which fixed the FOURTH member of this same batch (Patricia D.
-- Jehlen, 3,649 contributions / $697,212.68). The sweep that found these started from CC_0211's
-- lesson: **`check:duplicate-people` keys on `is_active` rows only, so an archived duplicate is
-- invisible to it.** 170 inactive rows share a first and last name with an active row; 9 of them
-- hold contributions. These three are the clearest.
--
--
-- ══ THE BATCH ════════════════════════════════════════════════════════════════════════════════
--
-- `essentials.politicians.data_source = 'ocpf_seed'` is a **Nov 2026 Massachusetts ballot seed of
-- SIX rows, and EVERY ONE OF THEM DUPLICATED A POLITICIAN WE ALREADY HELD.** It created its own
-- rows instead of matching, and the rows were later archived rather than merged — which is why the
-- finance stayed on them and why nothing reported it.
--
--   Patricia D. Jehlen   3,649 contributions   ✅ already retired by CC_0211
--   Sal N. DiDomenico    8,598 contributions   ← this migration
--   Marjorie C. Decker   6,926 contributions   ← this migration
--   David M. Rogers      2,783 contributions   ← this migration
--   Kimberley Driscoll   nothing at all        ⚠ NOT TOUCHED — see below
--   Michael L. Connolly  nothing but one image ⚠ NOT TOUCHED — see below
--
-- 🔴🔴 **TWO OF THE SIX ARE INVISIBLE EVEN TO A (first_name, last_name) SWEEP, BECAUSE THE SEED
--    USED LEGAL NAMES WHERE OUR ROWS USE THE NAME THE OFFICIAL ACTUALLY USES.** "Kimberley"
--    Driscoll against our "Kim Driscoll" (Lieutenant Governor of Massachusetts, 15,269
--    contributions); "Michael L. Connolly" against our "Mike Connolly" (Representative, 26th
--    Middlesex, 2,986 contributions). `politician_name_duplicate_guard()` compares
--    `lower(btrim(first_name))` — "Kimberley" <> "Kim" and "Michael" <> "Mike", so it will never
--    fire on either. ▶ A NICKNAME DEFEATS THE DUPLICATE GUARD COMPLETELY.
--    Neither is retired here: both hold no finance and no research, so nothing is stranded, and I
--    could not source a statement that "Kimberley Driscoll" is the Lieutenant Governor's legal
--    name. Ballotpedia's page for her does not contain the string. A shared name is not identity;
--    they are recorded as leads, not ruled.
--
--
-- ══ IDENTITY — SETTLED, TWO SOURCES EACH ═════════════════════════════════════════════════════
--
-- 🟢 **THE FINANCE SOURCE ROW NAMES THE SEAT THE CANONICAL ROW HOLDS.** That is the same
-- self-identifying evidence that settled Jehlen, and it is stronger than the name:
--
--   Sal N. DiDomenico   ocpf:15031 "Nov 2026 ballot seed — State Senator (Middlesex & Suffolk)
--                       — OCPF filer: DiDomenico, Sal N."
--                       canonical row holds "Senator, Middlesex and Suffolk District".
--                       malegislature.gov Senate roster: "Sal DiDomenico  Middlesex and Suffolk".
--   Marjorie C. Decker  ocpf:13736 "… State Representative (25th Middlesex) — OCPF filer:
--                       Decker, Marjorie C."  canonical row holds "Representative, 25th Middlesex
--                       District". MA House roster: "Marjorie Decker  25th Middlesex".
--   David M. Rogers     ocpf:15483 "… State Representative (24th Middlesex) — OCPF filer:
--                       Rogers, David M."  canonical row holds "Representative, 24th Middlesex
--                       District". MA House roster: "David Rogers  24th Middlesex".
--                       ⚠ The House holds more than one Rogers — "John Rogers 12th …" — so the
--                       DISTRICT is the discriminator here, not the surname.
--
-- Each retired row holds 0 office_terms, 0 race_candidates, 0 stance answers, and **all five
-- cascading foreign keys measure zero**. The gate re-counts them at write time.
--
--
-- ══ THE PHOTOGRAPHS ARE ALL CORRECT — CHECKED, BECAUSE CC_0211 FOUND TWO THAT WERE NOT ════════
--
-- CC_0211 found Jehlen publishing Senator Vanna Howard's face, scraped off the Senate ROSTER page.
-- All three retired rows here carry the same risky shape — their `photo_origin_url` is
-- `…/Legislators/Members/House` or `…/Members/Senate`, a roster. **But the three CANONICAL rows do
-- not**: they use person pages (`Profile/MCD1`, `Profile/DMR1`) and Wikipedia, and each was
-- verified against the official portrait whose own alt names the person
-- ("Photo of  Marjorie C. Decker", "Photo of  David M. Rogers"). Same photograph in both cases.
-- DiDomenico's was already cleared in CC_0211's sweep of all 40 MA senators.
-- ▶ **A ROSTER-PAGE `photo_origin_url` IS THE WRONG-FACE RISK SIGNAL; a person-page one is not.**
-- No photograph changes in this migration.
--
--
-- ══ WHAT THIS DOES ═══════════════════════════════════════════════════════════════════════════
--   1. re-routes `transparent_motivations.politician_sources` (1 per pair) retired -> canonical
--   2. deletes the retired rows' `politician_images` (1 each). NOT moved: the canonical row
--      already has its own correct type='default' row, and a second would make the browse grid's
--      find() pick an arbitrary one — the CC_0195 hazard. The objects stay in the bucket.
--   3. records all three in `essentials.politician_merges` (CC_0207's ledger)
--   4. deletes the three retired rows
--
-- No photograph and no object is touched, so there is nothing to revert in storage. Idempotent:
-- a re-run finds the rows gone and the ledger present, and changes nothing.
--
-- Rollback: re-insert the politician row from the ledger and point its ocpf source back at it.
--   a6b82d2e-d562-4ca6-a09b-a396d45cf1a7  Sal N. DiDomenico   ocpf:15031
--   81dbc898-213c-4789-8c0d-59fd6faa1202  Marjorie C. Decker  ocpf:13736
--   81a138f1-805e-46e0-ae95-e75c2211f6ea  David M. Rogers     ocpf:15483

BEGIN;

DO $$
DECLARE
  r        record;
  n_seen   int := 0;
  n_done   int := 0;
  v_src    int;
  v_img    int;
  v_cnt    bigint;
BEGIN
  FOR r IN
    SELECT b.a_id::uuid AS a_id, b.b_id::uuid AS b_id, b.nm, b.seat, b.expect::bigint AS expect, b.ev
      FROM (VALUES
        ('c7e94dda-1862-40fe-bda5-5fa2fe68f536','a6b82d2e-d562-4ca6-a09b-a396d45cf1a7',
         'Sal N. DiDomenico','Senator, Middlesex and Suffolk District', 8598,
         'One man, two rows, both created 2026-05-22. The retired row came from the Nov 2026 Massachusetts ballot seed (data_source=ocpf_seed) and carried his ENTIRE campaign finance: ocpf source 15031, 8,598 contributions totalling $1,662,042.67, while the seated row read zero. The source row names the seat itself — "Nov 2026 ballot seed — State Senator (Middlesex & Suffolk) — OCPF filer: DiDomenico, Sal N." — and the canonical row holds exactly that seat; malegislature.gov''s Senate roster lists "Sal DiDomenico  Middlesex and Suffolk". The retired row held no seat, no candidacy, no stance answer, and all five cascading FKs measured zero. His published photograph was verified correct in CC_0211''s sweep of all 40 Massachusetts senators and is unchanged here.'),
        ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10','81dbc898-213c-4789-8c0d-59fd6faa1202',
         'Marjorie C. Decker','Representative, 25th Middlesex District', 6926,
         'One woman, two rows, both created 2026-05-22. The retired row came from the Nov 2026 Massachusetts ballot seed (data_source=ocpf_seed) and carried her ENTIRE campaign finance: ocpf source 13736, 6,926 contributions totalling $1,566,884.92, while the seated row read zero. The source row names the seat itself — "Nov 2026 ballot seed — State Representative (25th Middlesex) — OCPF filer: Decker, Marjorie C." — and the canonical row holds exactly that seat; the malegislature.gov House roster lists "Marjorie Decker  25th Middlesex". The retired row held no seat, no candidacy, no stance answer, and all five cascading FKs measured zero. The canonical row''s photograph was verified against malegislature.gov''s own portrait carrying alt="Photo of  Marjorie C. Decker" — the same photograph — and is unchanged here.'),
        ('ffb8e526-7ad7-4911-92c5-d69528a0f280','81a138f1-805e-46e0-ae95-e75c2211f6ea',
         'David M. Rogers','Representative, 24th Middlesex District', 2783,
         'One man, two rows, both created 2026-05-22. The retired row came from the Nov 2026 Massachusetts ballot seed (data_source=ocpf_seed) and carried his ENTIRE campaign finance: ocpf source 15483, 2,783 contributions totalling $449,607.14, while the seated row read zero. The source row names the seat itself — "Nov 2026 ballot seed — State Representative (24th Middlesex) — OCPF filer: Rogers, David M." — and the canonical row holds exactly that seat; the malegislature.gov House roster lists "David Rogers  24th Middlesex". NOTE the House also seats a John Rogers, so the DISTRICT and not the surname is what identifies him. The retired row held no seat, no candidacy, no stance answer, and all five cascading FKs measured zero. The canonical row''s photograph was verified against malegislature.gov''s own portrait carrying alt="Photo of  David M. Rogers" — the same photograph — and is unchanged here.')
      ) AS b(a_id, b_id, nm, seat, expect, ev)
  LOOP
    n_seen := n_seen + 1;

    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.b_id) THEN
      IF NOT EXISTS (SELECT 1 FROM essentials.politician_merges WHERE retired_id = r.b_id) THEN
        RAISE EXCEPTION 'CC_0212: % retired row is gone but has NO ledger entry', r.nm;
      END IF;
      n_done := n_done + 1; CONTINUE;
    END IF;

    -- ──────────────────────────────────────────────────────── preconditions
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.a_id AND full_name = r.nm) THEN
      RAISE EXCEPTION 'CC_0212: canonical row % is not named "%" — refusing', r.a_id, r.nm;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.b_id AND full_name = r.nm) THEN
      RAISE EXCEPTION 'CC_0212: retired row % is not named "%" — refusing', r.b_id, r.nm;
    END IF;
    IF (SELECT is_active FROM essentials.politicians WHERE id = r.b_id) THEN
      RAISE EXCEPTION 'CC_0212: % retired row is STILL ACTIVE — refusing to delete a live person', r.nm;
    END IF;
    -- the retired row must be from the batch this migration is about
    IF (SELECT data_source FROM essentials.politicians WHERE id = r.b_id) IS DISTINCT FROM 'ocpf_seed' THEN
      RAISE EXCEPTION 'CC_0212: % retired row is not an ocpf_seed row — refusing', r.nm;
    END IF;
    -- the canonical row must actually hold the seat the OCPF note names
    IF NOT EXISTS (
      SELECT 1 FROM essentials.office_current_holder och
        JOIN essentials.offices o ON o.id = och.office_id
       WHERE och.politician_id = r.a_id AND o.title = r.seat) THEN
      RAISE EXCEPTION 'CC_0212: canonical row for % does not hold "%" — the identity evidence does not hold', r.nm, r.seat;
    END IF;

    SELECT count(*) INTO v_cnt FROM essentials.office_terms WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0212: % retired row holds % office_terms', r.nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM essentials.race_candidates WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0212: % retired row holds % race_candidates', r.nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM inform.politician_answers WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0212: % retired row holds % stance answers', r.nm, v_cnt; END IF;

    -- 🔴 the five CASCADING foreign keys; two of them are stance research
    SELECT count(*) INTO v_cnt FROM essentials.politician_name_aliases WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0212: % would CASCADE-destroy % politician_name_aliases', r.nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM inform.evidence_items WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0212: % would CASCADE-destroy % inform.evidence_items (STANCE RESEARCH)', r.nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM inform.politician_context_evidence WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0212: % would CASCADE-destroy % politician_context_evidence (STANCE RESEARCH)', r.nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM inform.topic_rewrite_stance_proposals WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0212: % would CASCADE-destroy % topic_rewrite_stance_proposals', r.nm, v_cnt; END IF;
    SELECT count(*) INTO v_cnt FROM essentials.quest_verified_facts WHERE politician_id = r.b_id;
    IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0212: % would SET NULL on % quest_verified_facts', r.nm, v_cnt; END IF;

    -- the money really is on the retired row, and really is not on the canonical one
    SELECT count(*) INTO v_cnt FROM transparent_motivations.contributions c
      JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
     WHERE s.essentials_politician_id = r.b_id;
    IF v_cnt <> r.expect THEN
      RAISE EXCEPTION 'CC_0212: % retired row holds % contributions, expected %', r.nm, v_cnt, r.expect;
    END IF;

    -- ────────────────────────────────────────────────────────── re-route
    WITH moved AS (
      UPDATE transparent_motivations.politician_sources
         SET essentials_politician_id = r.a_id
       WHERE essentials_politician_id = r.b_id
      RETURNING 1)
    SELECT count(*) INTO v_cnt FROM moved;
    v_src := v_cnt::int;

    WITH gone AS (
      DELETE FROM essentials.politician_images WHERE politician_id = r.b_id RETURNING 1)
    SELECT count(*) INTO v_cnt FROM gone;
    v_img := v_cnt::int;

    INSERT INTO essentials.politician_merges
           (retired_id, canonical_id, retired_name, migration, evidence, moved)
    VALUES (r.b_id, r.a_id, r.nm, 'CC_0212', r.ev,
            jsonb_build_object('transparent_motivations.politician_sources', v_src,
                               'essentials.politician_images_deleted', v_img))
    ON CONFLICT (retired_id) DO NOTHING;

    DELETE FROM essentials.politicians WHERE id = r.b_id;

    -- ──────────────────────────────────────────────────────────── verify
    IF EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.b_id) THEN
      RAISE EXCEPTION 'CC_0212: % retired row still exists after the delete', r.nm;
    END IF;
    SELECT count(*) INTO v_cnt FROM transparent_motivations.contributions c
      JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
     WHERE s.essentials_politician_id = r.a_id;
    IF v_cnt < r.expect THEN
      RAISE EXCEPTION 'CC_0212: % canonical row reads % contributions after the move, expected at least %',
        r.nm, v_cnt, r.expect;
    END IF;
    -- the canonical row must still have exactly one default image, and it must not be the deleted one
    SELECT count(*) INTO v_cnt FROM essentials.politician_images
      WHERE politician_id = r.a_id AND type = 'default';
    IF v_cnt <> 1 THEN
      RAISE EXCEPTION 'CC_0212: % canonical row has % type=default image rows, expected exactly 1', r.nm, v_cnt;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.politician_merges
                    WHERE retired_id = r.b_id AND canonical_id = r.a_id AND migration = 'CC_0212') THEN
      RAISE EXCEPTION 'CC_0212: % has no ledger entry', r.nm;
    END IF;

    n_done := n_done + 1;
  END LOOP;

  IF n_seen <> 3 OR n_done <> 3 THEN
    RAISE EXCEPTION 'CC_0212: saw % pairs and completed %, expected 3 and 3', n_seen, n_done;
  END IF;

  -- no ocpf_seed row may still hold contributions after this
  SELECT count(*) INTO v_cnt
    FROM essentials.politicians p
   WHERE p.data_source = 'ocpf_seed'
     AND EXISTS (SELECT 1 FROM transparent_motivations.politician_sources s
                  WHERE s.essentials_politician_id = p.id);
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0212: % ocpf_seed rows still carry a finance source', v_cnt;
  END IF;

  RAISE NOTICE 'CC_0212: 3 ocpf_seed duplicates retired; 18,307 contributions now answer on the seated rows. The ocpf_seed batch holds no finance source at all. Two more of that batch (Kimberley Driscoll, Michael L. Connolly) are nickname-hidden duplicates holding nothing — recorded, deliberately NOT retired.';
END $$;

COMMIT;
