-- CC_0220 — retire the last two CAL-ACCESS scraped duplicates into their seated rows.
--
-- `CC_0217` found four `source = 'scraped'` rows that duplicate a seated official. `CC_0218` moved
-- John Erickson's finance without retiring his. These are the other two, and unlike his they hold
-- **nothing of the person's at all**:
--
--     retired                                    canonical
--     837613f5  Bryan "Bubba" Fish      ->  6ed5080f  Bryan Fish          Council Member, Culver City
--     97f376e1  Angie Reyes English     ->  be3ca929  Angie Reyes English Council Member, Hawthorne
--
--     measured on both retired rows: 0 answers, 0 contexts, 0 office_terms, 0 race_candidates,
--     0 images, 0 aliases, 0 evidence_items, 0 context_evidence, 0 proposals, 0 quest facts.
--     They hold ONE contact each and the CAL-ACCESS sources `CC_0217` adjudicated. That is all.
--
-- ⚠ **SO THIS IS NOT A MERGE — NOTHING OF THEIRS MOVES.** The canonical rows already hold the seat,
-- the stances and the photo. This deletes two empty rows and relocates 18 committees belonging to
-- OTHER people. Operator ruling 2026-10-09, taken against my recommendation, which is recorded in
-- `.planning/todos/2026-10-09-finance-surname-buckets.md`: the gain is removing two rows the
-- duplicate guard cannot see; the cost is that other people's committees now hang on a live row.
--
-- 🔴 **THE COST IS REAL AND IS GATED BELOW.** `CC_0217` argued that a foreign committee on a LIVE
-- politician is a loaded gun — it publishes the moment somebody re-runs a confirm pass or the
-- CAL-ACCESS ingestion gap closes. All 18 arrive `not_applicable` (17) or `disputed` (1), so they
-- publish nothing today, and post-verify 3 asserts both canonical rows still publish **zero**.
-- ▶ Anyone later confirming a cal_access source must check it names the politician it sits on.
--
-- ## Identity — each city's own page, and only one such person on each council
--
--   **culvercity.gov/City-Hall/City-Council** lists `BRYAN "BUBBA" FISH`, Vice Mayor,
--   `bubba.fish@culvercity.org`. The retired row's `full_name` is the city's own rendering, which
--   is where the scrape took it from, and its `politician_contacts` row is `culvercity.org`.
--   The council seats one Fish.
--   ⚠ The city lists him as **Vice Mayor**; our canonical row says `Council Member`. Not touched
--   here — that is an occupancy question, not an identity one, and it is logged as follow-up.
--
--   **cityofhawthorne.org/government** lists `Council Member Angie Reyes English`, one of seven.
--   The retired row's contact is `cityofhawthorne.org` and its `full_name` is **byte-identical** to
--   the canonical row's.
--
-- 🔴 **THE DUPLICATE GUARD IS BLIND TO BOTH, AND REYES ENGLISH IS A BLINDNESS WORTH NAMING.**
-- `check:duplicate-people` compares `(lower(first_name), lower(last_name))`:
--     canonical be3ca929   first_name 'Angie'        last_name 'Reyes English'
--     retired   97f376e1   first_name 'Angie Reyes'  last_name 'English'
-- Same `full_name`, split at a different point — invisible to the guard and to any hand-rolled
-- (first,last) sweep. Fish is the nickname shape, `Bryan "Bubba"` against `Bryan`. Both retired
-- rows are also `is_active = false`, which the guard skips outright.
--
-- ## What moves
--
-- Measured across EVERY foreign key into `essentials.politicians`, exactly two tables reference
-- these rows: `politician_sources` (18, RESTRICT) and `politician_contacts` (2, NO ACTION). Every
-- other FK counts zero, so once those 20 rows move the DELETE is unobstructed — and for anything
-- missed, the FK itself refuses. The five CASCADE/SET NULL keys are the ones no FK would catch,
-- and all five are asserted zero before the delete.
--
-- ⚠ `politician_sources` has a UNIQUE index on `(essentials_politician_id, source_system,
-- external_id)`. Both canonical rows hold **zero** sources, so nothing can collide; asserted.
--
-- The retirement is recorded in `essentials.politician_merges` — without it a deleted id is
-- unresolvable for everything outside the FK graph.

BEGIN;

DO $$
DECLARE
  r           record;
  v_cnt       bigint;
  v_ret       uuid;
  v_can       uuid;
  v_src       bigint;
  v_con       bigint;
  n_done      int := 0;
BEGIN
  -- ── idempotence
  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id IN ('837613f5-2022-4844-95d7-df0848ca6fef','97f376e1-a21b-48eb-ac4b-b58cff2911d5');
  IF v_cnt = 0 THEN
    RAISE NOTICE 'CC_0220: already applied (both retired rows are gone) — skipping';
    RETURN;
  END IF;
  IF v_cnt <> 2 THEN
    RAISE EXCEPTION 'CC_0220: % of the 2 retired rows exist — refusing a partial state', v_cnt;
  END IF;

  FOR r IN
    SELECT x.ret, x.can, x.ret_name, x.can_name, x.govt, x.n_src, x.ev
      FROM (VALUES
        ('837613f5-2022-4844-95d7-df0848ca6fef','6ed5080f-e7cf-493b-9424-80dcbc8d54d0',
         'Bryan "Bubba" Fish','Bryan Fish','City of Culver City', 6,
         'culvercity.gov/City-Hall/City-Council lists BRYAN "BUBBA" FISH (bubba.fish@culvercity.org) and seats one Fish; the retired row is a cal_access scrape of that page, carrying a culvercity.org city_website contact and the city''s own rendering of his name. It held no seat, stance, candidacy or image of its own.'),
        ('97f376e1-a21b-48eb-ac4b-b58cff2911d5','be3ca929-4fe1-4797-acf2-570ba8fcebbf',
         'Angie Reyes English','Angie Reyes English','City of Hawthorne', 12,
         'cityofhawthorne.org/government lists Council Member Angie Reyes English, one of seven, and the retired row carries a cityofhawthorne.org city_website contact with a full_name byte-identical to the canonical row''s. The two rows split the same name differently (Angie/Reyes English against Angie Reyes/English), which is why the duplicate guard never saw them. It held no seat, stance, candidacy or image of its own.')
      ) AS x(ret, can, ret_name, can_name, govt, n_src, ev)
  LOOP
    v_ret := r.ret::uuid;
    v_can := r.can::uuid;

    -- canonical must be live, named, and hold the seat the identity rests on
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.id = v_can AND p.full_name = r.can_name AND p.is_active) THEN
      RAISE EXCEPTION 'CC_0220: canonical % is not an active "%"', v_can, r.can_name;
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
        JOIN essentials.offices o ON o.id = t.office_id
        JOIN essentials.chambers ch ON ch.id = o.chamber_id
        JOIN essentials.governments g ON g.id = ch.government_id
       WHERE t.politician_id = v_can AND g.name = r.govt
    ) THEN
      RAISE EXCEPTION 'CC_0220: canonical % holds no % term — identity chain broken', v_can, r.govt;
    END IF;

    -- retired must be the inactive scrape, named as expected
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.id = v_ret AND p.full_name = r.ret_name
                      AND NOT p.is_active AND p.source = 'scraped') THEN
      RAISE EXCEPTION 'CC_0220: retired % is not the inactive scraped "%"', v_ret, r.ret_name;
    END IF;

    -- 🔴 the five keys no foreign key would catch. A single row aborts.
    SELECT (SELECT count(*) FROM essentials.politician_name_aliases x WHERE x.politician_id = v_ret)
         + (SELECT count(*) FROM inform.evidence_items x WHERE x.politician_id = v_ret)
         + (SELECT count(*) FROM inform.politician_context_evidence x WHERE x.politician_id = v_ret)
         + (SELECT count(*) FROM inform.topic_rewrite_stance_proposals x WHERE x.politician_id = v_ret)
         + (SELECT count(*) FROM essentials.quest_verified_facts x WHERE x.politician_id = v_ret)
      INTO v_cnt;
    IF v_cnt <> 0 THEN
      RAISE EXCEPTION 'CC_0220: retired % holds % CASCADE/SET NULL rows — they would vanish silently', v_ret, v_cnt;
    END IF;

    -- it must also hold nothing a voter would miss
    SELECT (SELECT count(*) FROM inform.politician_answers x WHERE x.politician_id = v_ret)
         + (SELECT count(*) FROM inform.politician_context x WHERE x.politician_id = v_ret)
         + (SELECT count(*) FROM essentials.office_terms x WHERE x.politician_id = v_ret)
         + (SELECT count(*) FROM essentials.race_candidates x WHERE x.politician_id = v_ret)
         + (SELECT count(*) FROM essentials.politician_images x WHERE x.politician_id = v_ret)
      INTO v_cnt;
    IF v_cnt <> 0 THEN
      RAISE EXCEPTION 'CC_0220: retired % holds % rows of its own — this is not the empty-duplicate shape', v_ret, v_cnt;
    END IF;

    -- sources: the expected count, none publishing, and no unique-index collision on the canonical
    SELECT count(*) INTO v_src FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = v_ret;
    IF v_src <> r.n_src THEN
      RAISE EXCEPTION 'CC_0220: retired % holds % sources, expected %', v_ret, v_src, r.n_src;
    END IF;
    SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = v_ret
       AND research_status = 'confirmed' AND source_type = 'candidate_committee';
    IF v_cnt <> 0 THEN
      RAISE EXCEPTION 'CC_0220: retired % holds % PUBLISHING sources — moving them would publish on a live page', v_ret, v_cnt;
    END IF;
    SELECT count(*) INTO v_cnt
      FROM transparent_motivations.politician_sources a
      JOIN transparent_motivations.politician_sources b
        ON b.essentials_politician_id = v_can
       AND b.source_system = a.source_system AND b.external_id = a.external_id
     WHERE a.essentials_politician_id = v_ret;
    IF v_cnt <> 0 THEN
      RAISE EXCEPTION 'CC_0220: % sources would collide on idx_politician_source_system_extid', v_cnt;
    END IF;

    SELECT count(*) INTO v_con FROM essentials.politician_contacts WHERE politician_id = v_ret;

    UPDATE transparent_motivations.politician_sources
       SET essentials_politician_id = v_can, updated_at = now()
     WHERE essentials_politician_id = v_ret;

    UPDATE essentials.politician_contacts SET politician_id = v_can WHERE politician_id = v_ret;

    INSERT INTO essentials.politician_merges
      (retired_id, canonical_id, retired_name, migration, merged_at, evidence, moved)
    VALUES (v_ret, v_can, r.ret_name, 'CC_0220', now(), r.ev,
            jsonb_build_object('politician_sources', v_src, 'politician_contacts', v_con));

    DELETE FROM essentials.politicians WHERE id = v_ret;

    n_done := n_done + 1;
  END LOOP;

  IF n_done <> 2 THEN RAISE EXCEPTION 'CC_0220: retired % rows, expected 2', n_done; END IF;

  -- ══ POST-VERIFY ═════════════════════════════════════════════════════════════════════════════

  -- 1. Both retired rows are gone and both canonical rows survive, live.
  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id IN ('837613f5-2022-4844-95d7-df0848ca6fef','97f376e1-a21b-48eb-ac4b-b58cff2911d5');
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0220: % retired rows survive', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id IN ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0','be3ca929-4fe1-4797-acf2-570ba8fcebbf')
     AND is_active;
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'CC_0220: % canonical rows are live, expected 2', v_cnt; END IF;

  -- 2. The ledger records both, so the deleted ids stay resolvable outside the FK graph.
  SELECT count(*) INTO v_cnt FROM essentials.politician_merges WHERE migration = 'CC_0220';
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'CC_0220: ledger holds % rows, expected 2', v_cnt; END IF;

  -- 3. 🔴 THE ONE THAT PROTECTS A VOTER: neither canonical row publishes a penny. 18 foreign
  --    committees now hang on two live politicians, and every one must stay non-publishing.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
   WHERE s.essentials_politician_id IN ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0','be3ca929-4fe1-4797-acf2-570ba8fcebbf')
     AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0220: the canonical rows now publish % contributions — they must publish none', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0','be3ca929-4fe1-4797-acf2-570ba8fcebbf')
     AND research_status NOT IN ('not_applicable','disputed');
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0220: % moved sources are in a publishable state', v_cnt;
  END IF;

  -- 4. Everything arrived: 18 sources and 2 contacts across the two canonical rows.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0','be3ca929-4fe1-4797-acf2-570ba8fcebbf');
  IF v_cnt <> 18 THEN RAISE EXCEPTION 'CC_0220: canonical rows hold % sources, expected 18', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politician_contacts
   WHERE politician_id IN ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0','be3ca929-4fe1-4797-acf2-570ba8fcebbf');
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'CC_0220: canonical rows hold % contacts, expected 2', v_cnt; END IF;

  -- 5. The stances and seats the canonical rows already held are untouched.
  SELECT (SELECT count(*) FROM inform.politician_answers WHERE politician_id = '6ed5080f-e7cf-493b-9424-80dcbc8d54d0')
       + (SELECT count(*) FROM inform.politician_answers WHERE politician_id = 'be3ca929-4fe1-4797-acf2-570ba8fcebbf')
    INTO v_cnt;
  IF v_cnt <> 12 THEN RAISE EXCEPTION 'CC_0220: canonical rows hold % answers, expected 12 (7 + 5)', v_cnt; END IF;

  SELECT (SELECT count(*) FROM essentials.office_terms WHERE politician_id = '6ed5080f-e7cf-493b-9424-80dcbc8d54d0')
       + (SELECT count(*) FROM essentials.office_terms WHERE politician_id = 'be3ca929-4fe1-4797-acf2-570ba8fcebbf')
    INTO v_cnt;
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'CC_0220: canonical rows hold % office terms, expected 2', v_cnt; END IF;

  RAISE NOTICE 'CC_0220: 2 scraped duplicates retired; 18 sources and 2 contacts moved; nothing publishes';
END $$;

COMMIT;
