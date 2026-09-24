-- CA_0270_merge_pearson_klein_candidate_duplicates.sql
-- Identity merge of two sitting state legislators who are each split across two essentials.politicians rows: a
-- seated state-legislature row, and a separate 2026 U.S. House candidate row. Same pattern as CA_0234 (answers,
-- race row and quotes only on the duplicate) and CA_0204 (FEC link on the duplicate): the SEATED row is the person;
-- what hangs on the duplicate moves to it; nothing is deleted.
--
-- Slot CA_0270 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: NOT APPLIED. Dry-run only (BEGIN ... ROLLBACK), pending operator go-ahead from Chris Andrews, which must
--   also cover the closed-season override below.
--
-- Found 2026-09-24 by CA_0267 (PR #764): once a leading middle initial moves out of last_name, first_name + surname
-- matches three pairs. Two are merged here. The third is already done:
--
-- THE PAIRS (duplicate -> seated twin):
--   1. JUSTIN J. PEARSON
--      5d56470c-fb82-42f7-82e3-d28bf74ace47 (external_id -470907, from 1197; created 2026-07-04; no seat)
--        -> de50a88b-1366-4088-bb0a-baeb16e19e2d (external_id -4720086, TN General Assembly directory; created
--           2026-09-11; holds State House District 86, office 03bf94b9).
--      ONE PERSON: the Tennessee General Assembly page for District 86 names "Representative Justin J. Pearson,
--      Democrat, Memphis" (capitol.tn.gov/house/members/h86.html). FEC H6TN09449 is "PEARSON, JUSTIN J.", Memphis
--      TN, TN-09, committee C00922633 "The Committee to Elect Justin J. Pearson". NBC News, 2025-10, reports the
--      "Tennessee Three legislator Justin Pearson" launching the TN-9 primary challenge to Rep. Steve Cohen, and the
--      TN SOS 2026-08-06 Democratic primary totals name "Justin J. Pearson" the District 9 winner (CA_0266). The
--      duplicate's own Season 1 context already reads "As a TN state representative Pearson ..." and cites his
--      state bill HB1393.
--   2. MATTHEW D. KLEIN
--      5e86fb53-a6eb-4b35-82de-79706a66dc1a (external_id -270204, from 1211; created 2026-07-04; no seat)
--        -> 4966792b-a05c-41df-8f4b-9b81deebb166 "Matt D. Klein" (external_id -2732185, MN Legislature member lists;
--           created 2026-09-14; holds State Senate District 53, office 2eecc490).
--      ONE PERSON: the Minnesota Senate member page names "Senator Matt D. Klein (53, DFL)" (senate.mn, mem_id 1235).
--      FEC H6MN02248 is "KLEIN, MATTHEW DAVID", West St. Paul MN, MN-02, committee C00904292 "Matt Klein for
--      Congress", whose site (kleinforcongress.com) says he has served in the state Senate since 2017 and represents
--      Senate District 53. The duplicate's own Season 1 context cites his MN Senate committee work.
--   3. RICHARD A. HYER — NO CHANGE. 05624287 was already merged into 11c6810e (Ogden City Council District 2) and
--      deactivated by CA_0182 (applied 2026-09-23). Only its own politician_images row remains on it, as that
--      precedent leaves it. The pre-flight asserts this is still so. ogdencity.gov/164/Richard-Hyer: "District 2,
--      Term: January 2012 - December 2027".
--
-- 🔴 THIS FILE EDITS A CLOSED SEASON, WITH THE OVERRIDE THE TRIGGER ASKS FOR. inform.closed_season_is_immutable()
-- blocks every write to a Season 1 answer or context row unless inform.allow_closed_season_write = 'on'. Why: this is
-- an IDENTITY correction, not a position change. No value, season, topic or topic_revision pin changes; each answer
-- moves from one row of the person to the other row of the SAME person, where the read paths look for it. Left alone,
-- deactivating the duplicates would hide 4 (Pearson) and 6 (Klein) Season 1 answers from their own profiles. Neither
-- seated twin answers ANY topic in any season, so nothing collides and nothing is chosen between. No Season 2 row
-- exists on any of the four rows. The override is SET LOCAL and RESET straight after, so it covers the two UPDATEs only.
--
-- WHAT MOVES (every column named like politician_id, plus politician_id_bridge.essentials_id, counted 2026-09-24):
--   Pearson: race_candidates 5273ca75 (TN-9 2026 general, result 'advanced' by CA_0266); politician_sources 5c6f96fe
--     (fec_house H6TN09449, confirmed); quote be4f91d6 (readrank_selected); 4 Season 1 answers + 4 context rows;
--     AND his politician_images row 591fb604 plus photo_custom_url — the seated twin has NO photo and no image row,
--     so without this the merge would blank his portrait. The image URL is a storage path; it keeps working when
--     the row is re-pointed.
--   Klein: race_candidates 13bdc18a (MN-2 2026 general, result 'not_nominated' by CA_0263 — he lost the 2026-08-11
--     DFL primary); politician_sources f3f702f8 (fec_house H6MN02248, confirmed); 5 quotes (3 readrank_selected);
--     6 Season 1 answers + 6 context rows. His image row stays (the twin has its own), as in CA_0229 / CA_0261.
--   No politician_context_evidence, stance_research_review, contacts, aliases, bridge or office_terms rows exist on
--   either duplicate; the pre-flight refuses to run if that changes. No politician_sources collision: neither twin
--   holds any source. Contribution aggregates key off politician_source_id, so they follow the link unchanged.
--   Both race rows carry no photo_url or website_url, so race_candidate_mirror_data writes nothing.
--   finance_summary is NULL on all four rows; nothing to carry. FOLLOW-UP after apply: run the federal
--   finance-summary writer for both twins (backend/scripts/run-fec-finance-summary.ts --politician <id>).
--
-- THEN: each duplicate is deactivated (is_active = false, is_incumbent stays false) with a note naming its twin.
--
-- NOT CHANGED: any name. CA_0267 (not yet applied) edits last_name / middle_initial on both duplicates, keyed on id and
--   full_name only, so the two files apply in either order. The twins keep their names ("Justin J. Pearson",
--   "Matt D. Klein"); the race rows keep the names they were filed under. is_incumbent on the twins stays true
--   (each holds a state seat). check:stance-sources: Klein's one BALLOTPEDIA_ONLY row stays in bucket 'mn' (the twin's
--   seat is in MN), so the baseline does not move.
--
-- ROLLBACK (once applied): with the same override, re-point the rows listed in _move / _ans back to each duplicate;
--   re-point image 591fb604 back to 5d56470c and set de50a88b's photo_custom_url back to NULL; set both duplicates
--   is_active = true and remove their CA_0270 note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run moves nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (dup uuid PRIMARY KEY, keep uuid, dup_name text, keep_name text, keep_office uuid,
                         n_ans int, n_quotes int) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('5d56470c-fb82-42f7-82e3-d28bf74ace47', 'de50a88b-1366-4088-bb0a-baeb16e19e2d', 'Justin J. Pearson', 'Justin J. Pearson',
   '03bf94b9-7c03-466d-99c6-594128709cfd', 4, 1),
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a', '4966792b-a05c-41df-8f4b-9b81deebb166', 'Matthew D. Klein', 'Matt D. Klein',
   '2eecc490-1173-46d0-a520-11a6ada9b2a7', 6, 5);

-- the reviewed race and FEC rows, one each per pair
CREATE TEMP TABLE _move (tbl text, id uuid, dup uuid, keep uuid, PRIMARY KEY (tbl, id)) ON COMMIT DROP;
INSERT INTO _move VALUES
  ('race',   '5273ca75-fe58-48d4-b6a4-55d1d4f3663c', '5d56470c-fb82-42f7-82e3-d28bf74ace47', 'de50a88b-1366-4088-bb0a-baeb16e19e2d'),
  ('source', '5c6f96fe-405e-4456-a08c-21440c2ecc44', '5d56470c-fb82-42f7-82e3-d28bf74ace47', 'de50a88b-1366-4088-bb0a-baeb16e19e2d'),
  ('race',   '13bdc18a-3447-49b1-a348-2e39728b8677', '5e86fb53-a6eb-4b35-82de-79706a66dc1a', '4966792b-a05c-41df-8f4b-9b81deebb166'),
  ('source', 'f3f702f8-f2bb-4c6c-a654-891456134db7', '5e86fb53-a6eb-4b35-82de-79706a66dc1a', '4966792b-a05c-41df-8f4b-9b81deebb166');

-- the answer keys across each pair (on the duplicate before a first run, on the twin after)
CREATE TEMP TABLE _ans (dup uuid, keep uuid, topic_id uuid, season_id uuid, PRIMARY KEY (dup, topic_id, season_id)) ON COMMIT DROP;
INSERT INTO _ans
SELECT pr.dup, pr.keep, a.topic_id, a.season_id
  FROM _pair pr JOIN inform.politician_answers a ON a.politician_id IN (pr.dup, pr.keep);

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT pr.keep,
       (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
          JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
         WHERE ps.essentials_politician_id IN (pr.keep, pr.dup)) AS pair_total
  FROM _pair pr;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each twin is active, the incumbent, and holds its reviewed state-legislature seat (EXISTS: a politician-rooted
  -- join on office_current_holder can fan out)
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
   WHERE k.full_name = pr.keep_name AND k.is_active AND k.is_incumbent
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.politician_id = pr.keep AND och.office_id = pr.keep_office);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 twins are the active holder of their reviewed seat', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE politician_id IN (SELECT keep FROM _pair);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: twins hold % office_terms rows, expected 2', v_n; END IF;

  -- each duplicate is the reviewed name, not an incumbent, and holds no term
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians d ON d.id = pr.dup
   WHERE d.full_name = pr.dup_name AND NOT d.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = d.id);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 duplicates are the reviewed seatless non-incumbent row', v_n; END IF;

  -- the reviewed race and FEC rows are on the duplicate (or already on the twin), and there are no others
  SELECT count(*) INTO v_n FROM _move m
   WHERE (m.tbl = 'race'   AND EXISTS (SELECT 1 FROM essentials.race_candidates x
                                        WHERE x.id = m.id AND x.politician_id IN (m.dup, m.keep)))
      OR (m.tbl = 'source' AND EXISTS (SELECT 1 FROM transparent_motivations.politician_sources x
                                        WHERE x.id = m.id AND x.essentials_politician_id IN (m.dup, m.keep)
                                          AND x.source_system = 'fec_house' AND x.research_status = 'confirmed'));
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 reviewed race/FEC rows in place', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE politician_id IN (SELECT dup FROM _pair UNION ALL SELECT keep FROM _pair);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % race rows across the pairs, expected 2', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN (SELECT dup FROM _pair UNION ALL SELECT keep FROM _pair);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % politician_sources rows across the pairs, expected 2', v_n; END IF;
  -- the race rows carry no photo or website, so the mirror trigger writes nothing
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id IN (SELECT id FROM _move WHERE tbl = 'race')
     AND (COALESCE(photo_url, '') <> '' OR COALESCE(website_url, '') <> '');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race rows now carry a photo or website', v_n; END IF;

  -- quotes: 1 Pearson + 5 Klein across each pair
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE (SELECT count(*) FROM essentials.quotes q WHERE q.politician_id IN (pr.dup, pr.keep)) = pr.n_quotes;
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: quote counts across the pairs are not 1 and 5'; END IF;

  -- answers: 4 + 6, all in the closed Season 1, each with its context row and no context row without an answer
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE (SELECT count(*) FROM _ans x WHERE x.dup = pr.dup) = pr.n_ans;
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: answer counts across the pairs are not 4 and 6'; END IF;
  SELECT count(*) INTO v_n FROM _ans x JOIN inform.seasons s ON s.id = x.season_id
   WHERE s.id <> '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' OR s.status <> 'closed';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % answers outside the closed Season 1; this file was reviewed for S1 only', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context c
   WHERE c.politician_id IN (SELECT dup FROM _pair UNION ALL SELECT keep FROM _pair);
  IF v_n <> 10 THEN RAISE EXCEPTION 'PRE: % context rows across the pairs, expected 10', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context c
   WHERE c.politician_id IN (SELECT dup FROM _pair UNION ALL SELECT keep FROM _pair)
     AND NOT EXISTS (SELECT 1 FROM _ans x WHERE x.topic_id = c.topic_id AND x.season_id = c.season_id
                        AND c.politician_id IN (x.dup, x.keep));
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % context rows with no matching answer', v_n; END IF;
  -- no (topic, season) answered on both rows of a pair
  SELECT count(*) INTO v_n FROM _pair pr JOIN inform.politician_answers a ON a.politician_id = pr.dup
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers k
                  WHERE k.politician_id = pr.keep AND k.topic_id = a.topic_id AND k.season_id = a.season_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % answer conflicts between a duplicate and its twin', v_n; END IF;

  -- nothing references a context row by key, and nothing else hangs on a duplicate
  SELECT (SELECT count(*) FROM inform.politician_context_evidence WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.stance_research_review      WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.evidence_items               WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.politician_contacts      WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.politician_name_aliases  WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM politician_id_bridge                WHERE essentials_id IN (SELECT dup FROM _pair))
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows on a duplicate that this file does not move', v_n; END IF;

  -- images: Pearson's twin has none (his moves); Klein's twin has its own (his stays)
  SELECT count(*) INTO v_n FROM essentials.politician_images
   WHERE id = '591fb604-01b7-4aa9-9995-89dd394a995e'
     AND politician_id IN ('5d56470c-fb82-42f7-82e3-d28bf74ace47', 'de50a88b-1366-4088-bb0a-baeb16e19e2d');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Pearson''s image row is not in its reviewed place'; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images
   WHERE politician_id = 'de50a88b-1366-4088-bb0a-baeb16e19e2d' AND id <> '591fb604-01b7-4aa9-9995-89dd394a995e';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: Pearson''s twin has % image(s) of its own now; re-review', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = 'de50a88b-1366-4088-bb0a-baeb16e19e2d' AND NOT photo_custom_url_manual_override
     AND (COALESCE(photo_custom_url, '') = ''
          OR photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d56470c-fb82-42f7-82e3-d28bf74ace47-headshot.jpg');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Pearson''s twin has a photo of its own now; re-review'; END IF;

  -- pair 3 (Hyer) needs nothing: CA_0182 left only the duplicate's own image row on it
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = '05624287-c90f-40be-bada-12a883040d60' AND NOT is_active AND NOT is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(notes) n WHERE n LIKE 'CA_0182 (2026-09-23): DUPLICATE of 11c6810e%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Hyer duplicate is no longer the inactive CA_0182 row'; END IF;
  SELECT (SELECT count(*) FROM essentials.race_candidates WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM essentials.office_terms WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM inform.politician_answers WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM essentials.quotes WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM essentials.politician_contacts WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows hang on the Hyer duplicate again; re-review', v_n; END IF;

  RAISE NOTICE 'CA_0270 pre-flight OK';
END $$;

-- ─── 1. Race rows, FEC links, quotes ─────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc SET politician_id = m.keep, updated_at = now()
  FROM _move m WHERE m.tbl = 'race' AND rc.id = m.id AND rc.politician_id = m.dup;

UPDATE transparent_motivations.politician_sources ps SET essentials_politician_id = m.keep, updated_at = now()
  FROM _move m WHERE m.tbl = 'source' AND ps.id = m.id AND ps.essentials_politician_id = m.dup;

UPDATE essentials.quotes q SET politician_id = pr.keep, updated_at = now()
  FROM _pair pr WHERE q.politician_id = pr.dup;

-- ─── 2. Pearson's portrait: his twin has none ────────────────────────────────────────────────────
UPDATE essentials.politician_images SET politician_id = 'de50a88b-1366-4088-bb0a-baeb16e19e2d'
 WHERE id = '591fb604-01b7-4aa9-9995-89dd394a995e' AND politician_id = '5d56470c-fb82-42f7-82e3-d28bf74ace47';

UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d56470c-fb82-42f7-82e3-d28bf74ace47-headshot.jpg'
 WHERE id = 'de50a88b-1366-4088-bb0a-baeb16e19e2d' AND COALESCE(photo_custom_url, '') = ''
   AND NOT photo_custom_url_manual_override;

-- ─── 3. Season 1 answers and their context (closed season: identity correction) ──────────────────
SET LOCAL inform.allow_closed_season_write = 'on';

UPDATE inform.politician_context c SET politician_id = x.keep
  FROM _ans x
 WHERE c.politician_id = x.dup AND c.topic_id = x.topic_id AND c.season_id = x.season_id;

UPDATE inform.politician_answers a SET politician_id = x.keep
  FROM _ans x
 WHERE a.politician_id = x.dup AND a.topic_id = x.topic_id AND a.season_id = x.season_id;

RESET inform.allow_closed_season_write;

-- ─── 4. Deactivate the duplicates ────────────────────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0270 (2026-09-24): DUPLICATE of ' || pr.keep::text || ' ('
               || pr.keep_name || '), the row that holds the same person''s state-legislature seat. 2026 U.S. House '
               || 'race row, FEC link, quotes and ' || pr.n_ans || ' Season 1 answers with their context moved there'
               || CASE WHEN pr.dup = '5d56470c-fb82-42f7-82e3-d28bf74ace47' THEN ', and the portrait' ELSE '' END
               || '; deactivated, not deleted.')::text
  FROM _pair pr
 WHERE d.id = pr.dup AND (d.is_active OR d.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_amt numeric; v_before numeric;
BEGIN
  IF COALESCE(NULLIF(current_setting('inform.allow_closed_season_write', true), ''), 'off') <> 'off' THEN
    RAISE EXCEPTION 'POST: the closed-season override is still on';
  END IF;

  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians d ON d.id = pr.dup
   WHERE NOT d.is_active AND NOT d.is_incumbent AND d.full_name = pr.dup_name
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0270 (2026-09-24): DUPLICATE of ' || pr.keep::text || '%');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 duplicates deactivated with the note', v_n; END IF;

  -- nothing left on a duplicate but Klein's own image
  SELECT (SELECT count(*) FROM essentials.race_candidates WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.quotes WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.politician_answers WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.politician_context WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.politician_images WHERE politician_id = '5d56470c-fb82-42f7-82e3-d28bf74ace47')
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows still on a duplicate', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE politician_id = '5e86fb53-a6eb-4b35-82de-79706a66dc1a';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Klein''s duplicate image row was touched'; END IF;

  -- everything reviewed is on the twin
  SELECT count(*) INTO v_n FROM _move m
   WHERE (m.tbl = 'race'   AND EXISTS (SELECT 1 FROM essentials.race_candidates x WHERE x.id = m.id AND x.politician_id = m.keep))
      OR (m.tbl = 'source' AND EXISTS (SELECT 1 FROM transparent_motivations.politician_sources x
                                        WHERE x.id = m.id AND x.essentials_politician_id = m.keep));
  IF v_n <> 4 THEN RAISE EXCEPTION 'POST: % of 4 race/FEC rows on the twins', v_n; END IF;
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE (SELECT count(*) FROM essentials.quotes q WHERE q.politician_id = pr.keep) = pr.n_quotes
     AND (SELECT count(*) FROM inform.politician_answers a JOIN _ans x USING (topic_id, season_id)
           WHERE a.politician_id = pr.keep AND x.keep = pr.keep) = pr.n_ans
     AND (SELECT count(*) FROM inform.politician_context c JOIN _ans x USING (topic_id, season_id)
           WHERE c.politician_id = pr.keep AND x.keep = pr.keep) = pr.n_ans;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 twins hold all their quotes, answers and context', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = 'de50a88b-1366-4088-bb0a-baeb16e19e2d'
     AND photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d56470c-fb82-42f7-82e3-d28bf74ace47-headshot.jpg'
     AND EXISTS (SELECT 1 FROM essentials.politician_images i
                  WHERE i.id = '591fb604-01b7-4aa9-9995-89dd394a995e' AND i.politician_id = 'de50a88b-1366-4088-bb0a-baeb16e19e2d');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Pearson''s twin lacks the portrait'; END IF;

  -- the twins keep their seats and flags; one active row per person
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
   WHERE k.is_active AND k.is_incumbent AND k.full_name = pr.keep_name
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.politician_id = pr.keep AND och.office_id = pr.keep_office);
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 twins still active incumbents holding their seat', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE politician_id IN (SELECT keep FROM _pair);
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: twins hold % office_terms rows, expected 2 (none moved)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE is_active AND ((first_name = 'Justin' AND full_name LIKE '%Pearson')
                     OR (first_name IN ('Matt', 'Matthew') AND full_name LIKE '% Klein' AND full_name LIKE '% D. %'));
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % active Justin Pearson / Matt D. Klein rows, expected 2', v_n; END IF;

  -- no money created or destroyed
  FOR v_before, v_amt IN
    SELECT b.pair_total, (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
                            JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
                           WHERE ps.essentials_politician_id = b.keep)
      FROM _before b
  LOOP
    IF v_before <> v_amt THEN RAISE EXCEPTION 'POST: pair confirmed total moved from % to %', v_before, v_amt; END IF;
  END LOOP;

  RAISE NOTICE 'CA_0270 applied: Pearson and Klein duplicates deactivated; race rows, FEC links, quotes and 10 Season 1 answers on the seated twins';
END $$;

COMMIT;
