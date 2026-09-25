-- CA_0291_merge_six_split_duplicate_pairs.sql
-- Identity merge of six people who are each split across two essentials.politicians rows: a CAMPAIGN row
-- (holding the compass answers, quotes, FEC link and race rows) and a separate ROSTER row (holding only the seat).
-- The seat moves to the campaign row. Same method as CA_0270 (Pearson / Klein), which set the rule.
--
-- Slot CA_0291 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE.
-- STATUS: NOT APPLIED. Dry-run only (BEGIN ... ROLLBACK), pending operator go-ahead from Chris Andrews.
--
-- 🟢 SEASON 1 IS NOT TOUCHED. Ruling 2026-09-24 (Chris Andrews): a merge never edits the closed season. The survivor
-- is the row that already holds the answers, so no inform.* row is written; the post-gate fingerprints them.
--
-- Found by check:duplicate-people (PR #773) as its 8 "split" pairs: seat on one row, answers only on the other.
-- Two of the eight are DIFFERENT people and are not touched here (recorded as different_people in the baseline):
-- Andrew K. Kim (2026 LA mayoral candidate, kimforla.com) vs Andrew C. Kim (LA County Superior Court judge); and
-- Mónica García (LAUSD) vs Monica García (Glendora Unified Trustee Area 2).
--
-- THE SIX (roster seat row -> campaign survivor), each checked 2026-09-25:
--   1. BRENT TAYLOR   cad06d77 TN Senate 31 (1855 seed, ext -4710031) -> 00b1ee2d (ext -470902; TN-9 Republican nominee:
--      4 S1 answers, race row 'advanced', fec_house H6TN09464). capitol.tn.gov/senate/members/s31.html: "Senator Brent
--      Taylor, Republican, Memphis, District 31". FEC H6TN09464 "TAYLOR, BRENT", TN-09. Action News 5 (2026-05-07):
--      "Senator Brent Taylor announces his intent to run for newly-drawn District 9 congress seat"; Tennessee Lookout
--      (2026-08-06): "Republican Taylor and Democrat Pearson set for general election".
--   2. VINCENT DIXIE  a201565a TN House 54 (1855, ext -4720054) -> 830d155a (ext -470702; TN-7 candidate, lost the
--      2026-08-06 primary: 5 S1 answers, 3 quotes, fec_house H6TN07229). capitol.tn.gov/house/members/h54.html:
--      "Representative Vincent Dixie, Democrat, Nashville, District 54". FEC H6TN07229 "DIXIE, VINCENT", Nashville, TN-07.
--      NewsChannel 5: "Tennessee Rep. Vincent Dixie launches campaign for Congress in newly drawn 7th District".
--   3. LONDON LAMAR   a770cc10 TN Senate 33 (1855, ext -4710033) -> 9c83e282 (ext -470906; TN-9 candidate, lost the
--      2026-08-06 primary: 1 S1 answer, 1 quote, fec_house H6TN09498). capitol.tn.gov/senate/members/s33.html: "Senator
--      London Lamar, Democrat, Memphis, District 33". FEC H6TN09498 "LAMAR, LONDON", Memphis, TN-09. Action News 5
--      (2026-05-26): "London Lamar launches congressional campaign for District 9".
--   4. MANNY RUTINEL  04ff7894 CO House 32 (1844 seed, ext -820032) -> b06a3665 (ext -80801; CO-8 Democratic nominee:
--      13 S1 answers, 8 quotes, fec_house H6CO08013). leg.colorado.gov/legislators/manny-rutinel: "Representative
--      Manny Rutinel ... District: 32" and "Representative Rutinel resigned 9/4/26". FEC H6CO08013 "RUTINEL, MANNY",
--      Commerce City, CO-08. Colorado Newsline (2026-06-30): "Manny Rutinel wins Democratic primary in Colorado's 8th".
--      🔴 HE NO LONGER HOLDS THE SEAT. After the term moves, essentials.vacate_office closes it with first vacant day
--      2026-09-05 (term_end 2026-09-04, the resignation date) and flags the office vacant. The Colorado Democratic
--      Party declined a vacancy committee (2026-09-08); Gov. Polis may appoint a placeholder by 2026-10-12 — none was
--      reported on 2026-09-25, so no successor is seated here. The survivor stays is_incumbent = false.
--   5. SILVIA CATTEN  10143b07 Millcreek City Council D1 (ut-city-millcreek, ext -350125) -> 63d60b50 (no ext;
--      sos_filing; Utah Senate 13 candidate, won the 2026-06-23 Democratic primary: 17 S1 answers, 7 quotes).
--      Utah Voter Information, vote.utah.gov/wp-content/uploads/2026/01/S13-Silvia-Catten.pdf; the Salt Lake Tribune
--      (2026-06-05) and her site (silviacatten.com) name her the Millcreek City Council member running in SD-13.
--   6. KELLY SMITH    e96d79ea Cedar Hills City Council (ut-city-cedar_hills, ext -363270) -> 92dba8fc (no ext;
--      sos_filing; Utah Senate 21 Republican primary candidate: 8 S1 answers). vote.utah.gov .../S21-Kelly-Smith.pdf;
--      the Salt Lake Tribune (2026-06-07): "Brady Brammer seeks reelection in SD21 against Cedar Hills City Council
--      member Kelly Smith". (Her primary race row has no result recorded; that is a separate gap, not changed here.)
--
-- WHAT CHANGES, per pair:
--   a. The roster seat's office_terms row moves to the survivor (' | merged onto <id> by CA_0291' on its source).
--   b. external_id is SWAPPED (via NULL; the UT survivors had none, so their roster rows end with NULL). All three
--      roster loaders find people by external_id: 1855 (TN terms join p.external_id), 1844 (CO,
--      ON CONFLICT (external_id) + a term join on it) and scripts/lib/politician-upsert.ts (UT, ON CONFLICT
--      (external_id) DO UPDATE). Without the swap a re-run would find the deactivated row. The survivors' old ids are
--      referenced nowhere else in the repo.
--   c. The survivor becomes is_incumbent = true (Rutinel: false — see 4), takes the roster citation where its own
--      source / data_source is NULL, and gets a CA_0291 note.
--   d. PORTRAITS follow the seat where the seat's portrait is the official one:
--      - TN (Taylor, Dixie, Lamar): the survivor takes the General Assembly portrait — its photo_custom_url and
--        photo_origin_url, and the url + photo_license on its own politician_images row — from the roster row. This is
--        what #796 did for Pearson after CA_0270, and it keeps Tennessee at "131 of 131 seated legislators from one
--        publisher". The replaced values are kept in _photo_before and listed in each survivor's note.
--      - Smith: the survivor has no portrait at all; the roster row's image row is re-pointed and its photo fields copied.
--      - Rutinel and Catten keep their own campaign portraits (Rutinel no longer holds the seat).
--   e. UT only: the roster row's OFFICE contact (city email + phone) moves to the survivor, which had only a campaign
--      contact. Without this the council member's official contact disappears with the roster row.
--   f. The roster row is deactivated (is_active = false, is_incumbent = false) with a note naming the survivor.
--
-- NOT CHANGED: every inform.* row; race_candidates, quotes, politician_sources, finance_summary (already on the
--   survivors); names (identical within each pair); party (antipartisan; Rutinel's roster row carries one, the
--   survivor does not, and it is not copied); Rutinel's coleg.gov email (he resigned).
-- check:stance-sources: each survivor's bucket (race state before, seat state after) is the same state.
-- check:duplicate-people: all six pairs resolve after apply; the two CA pairs are different_people in the baseline.
-- offices_missing_terms: unchanged except CO HD-32, which becomes a flagged vacancy (is_vacant, vacant_since 2026-09-05).
--
-- ROLLBACK (once applied), per pair: re-point the office_terms row to the roster row and strip ' | merged onto';
--   (Rutinel) set term_end NULL, how_ended NULL, strip ' | vacated:', and set the office is_vacant false /
--   vacant_since NULL; swap external_id back via NULL; restore the survivor's photo fields and image row from
--   _photo_before (the values are in its CA_0291 note); re-point Smith's image row and the UT contacts back; set the
--   survivor is_incumbent false and remove its note; set the roster row is_active true, is_incumbent true, remove its note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (who text PRIMARY KEY, keep uuid UNIQUE, seat uuid UNIQUE, term_id uuid, office_id uuid,
                         keep_ext bigint, seat_ext bigint, n_ans int, n_quotes int, n_races int,
                         portrait text, contact_id uuid, still_seated boolean) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('Brent Taylor',  '00b1ee2d-c4e1-47f8-aae8-83974a625ef3', 'cad06d77-75d3-42c6-9bf2-6f9921ff9781',
   '175b4d10-121e-4d4a-baf2-a59ddfb89234', 'b87e1d30-db38-414d-9eec-3bde71d3d9e6', -470902, -4710031, 4, 0, 1, 'official', NULL, true),
  ('Vincent Dixie', '830d155a-394e-463c-999d-bcf154460225', 'a201565a-0aa1-4b6a-9349-6ee7abe90252',
   '1290be72-d83e-4d0e-bd2c-736bc3914720', '6f1aa6a1-ac45-4e1a-8136-a8f3a6f4f1fc', -470702, -4720054, 5, 3, 1, 'official', NULL, true),
  ('London Lamar',  '9c83e282-cb78-4e39-aa1e-13875a86e872', 'a770cc10-dde6-4f1a-938d-af12e632b420',
   '8821d6d5-6ec3-46c5-bc23-fc24f2e7d952', 'b4c50e97-0026-4c6b-91a0-1eca37878b21', -470906, -4710033, 1, 1, 1, 'official', NULL, true),
  ('Manny Rutinel', 'b06a3665-412e-427a-a762-8220a293d5d0', '04ff7894-2f7c-493a-af94-b49aedaf8502',
   '3243414b-a035-42b0-b556-4916644ae4f8', '5285c397-4694-4c6d-b8d6-8fc7566ddc91', -80801, -820032, 13, 8, 1, 'keep', NULL, false),
  ('Silvia Catten', '63d60b50-2395-4cde-8999-97a9166d3563', '10143b07-141f-4dcb-a664-098869d7ff63',
   'f894fc6f-1b6b-4cef-a3b8-534e8b512a8f', 'e285a9eb-e29d-4621-98c5-33eaba9dc535', NULL, -350125, 17, 7, 2, 'keep',
   '02f906d1-9e95-4ed6-9577-7e002cf28d64', true),
  ('Kelly Smith',   '92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4', 'e96d79ea-0f4f-4a17-9a94-8fbefed6e5d5',
   '2f7c48a2-a49c-4b7c-9535-b3a3f447c802', 'cd23b4b6-ba13-4480-a180-af5e6b96054b', NULL, -363270, 8, 0, 1, 'move',
   'e1e2491a-af8f-4b43-9b39-f768383a6736', true);

-- the survivors' portraits before this file (for the note and the rollback)
CREATE TEMP TABLE _photo_before ON COMMIT DROP AS
SELECT pr.who, k.photo_custom_url, k.photo_origin_url, i.id AS image_id, i.url AS image_url, i.photo_license
  FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
  LEFT JOIN essentials.politician_images i ON i.politician_id = pr.keep AND i.type = 'default';

-- a fingerprint of the survivors' answers and context, which this file must not change
CREATE TEMP TABLE _inform_before ON COMMIT DROP AS
SELECT 'a' AS t, md5(string_agg(a::text, '|' ORDER BY a.politician_id, a.topic_id, a.season_id)) AS h
  FROM inform.politician_answers a WHERE a.politician_id IN (SELECT keep FROM _pair)
UNION ALL
SELECT 'c', md5(string_agg(c::text, '|' ORDER BY c.politician_id, c.topic_id, c.season_id))
  FROM inform.politician_context c WHERE c.politician_id IN (SELECT keep FROM _pair);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each seat term is on the roster row (first run) or on the survivor (re-run); it is each pair's only term
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.office_terms t ON t.id = pr.term_id
   WHERE t.office_id = pr.office_id AND t.politician_id IN (pr.seat, pr.keep);
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % of 6 reviewed seat terms in place', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE politician_id IN (SELECT seat FROM _pair UNION ALL SELECT keep FROM _pair);
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % office_terms rows across the pairs, expected 6', v_n; END IF;
  -- no other open term on those offices (so the moved term stays the current holder)
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.office_terms t ON t.office_id = pr.office_id
   WHERE t.id <> pr.term_id AND t.term_end IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % other open term(s) on the six offices', v_n; END IF;

  -- external_ids in their pre-image or already swapped
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep JOIN essentials.politicians s ON s.id = pr.seat
   WHERE (k.external_id IS NOT DISTINCT FROM pr.keep_ext AND s.external_id = pr.seat_ext)
      OR (k.external_id = pr.seat_ext AND s.external_id IS NOT DISTINCT FROM pr.keep_ext);
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % of 6 pairs have their reviewed external_ids', v_n; END IF;

  -- names match within each pair; survivors hold the reviewed answers, quotes and race rows
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep JOIN essentials.politicians s ON s.id = pr.seat
   WHERE k.full_name = pr.who AND s.full_name = pr.who AND k.is_active
     AND (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = pr.keep) = pr.n_ans
     AND (SELECT count(*) FROM inform.politician_context c WHERE c.politician_id = pr.keep) = pr.n_ans
     AND (SELECT count(*) FROM essentials.quotes q WHERE q.politician_id = pr.keep) = pr.n_quotes
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = pr.keep) = pr.n_races;
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % of 6 pairs match their reviewed names and survivor holdings', v_n; END IF;

  -- roster rows hold nothing but the term, their image row and (UT) the office contact
  SELECT (SELECT count(*) FROM inform.politician_answers         WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM inform.politician_context         WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM inform.politician_context_evidence WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM inform.stance_research_review     WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM inform.evidence_items             WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM essentials.race_candidates        WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM essentials.quotes                 WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM essentials.politician_name_aliases WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM politician_id_bridge              WHERE essentials_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM essentials.politician_contacts c
           WHERE c.politician_id IN (SELECT seat FROM _pair) AND c.id NOT IN (SELECT contact_id FROM _pair WHERE contact_id IS NOT NULL))
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows on a roster row that this file does not handle', v_n; END IF;
  -- the two UT office contacts are where reviewed (roster row, or the survivor on a re-run)
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politician_contacts c ON c.id = pr.contact_id
   WHERE c.politician_id IN (pr.seat, pr.keep) AND c.contact_type = 'office';
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 UT office contacts in place', v_n; END IF;

  -- portraits: the three TN roster rows carry the General Assembly portrait; each survivor has one image row,
  -- except Smith's survivor, which has none (or, on a re-run, the roster's re-pointed one)
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians s ON s.id = pr.seat
    JOIN essentials.politician_images i ON i.politician_id = s.id
   WHERE pr.portrait = 'official' AND s.photo_origin_url LIKE 'https://wapp.capitol.tn.gov/apps/LegislatorInfo/Member?%'
     AND i.photo_license LIKE '(C) State of Tennessee%';
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 TN roster rows carry the General Assembly portrait', v_n; END IF;
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE pr.portrait <> 'move' AND (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id = pr.keep) = 1;
  IF v_n <> 5 THEN RAISE EXCEPTION 'PRE: % of 5 survivors have exactly one image row', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images
   WHERE politician_id = '92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4' AND id <> '7f2d031f-160a-476d-8bf9-458e32ac0011';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: Smith''s survivor has an image row of its own now; re-review'; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images
   WHERE id = '7f2d031f-160a-476d-8bf9-458e32ac0011'
     AND politician_id IN ('e96d79ea-0f4f-4a17-9a94-8fbefed6e5d5', '92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Smith''s roster image row is not in its reviewed place'; END IF;

  -- Rutinel's term is open or already closed by this file
  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE id = '3243414b-a035-42b0-b556-4916644ae4f8' AND term_start = '2023-10-13'
     AND (term_end IS NULL OR term_end = '2026-09-04');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Rutinel''s HD-32 term is not in its reviewed state'; END IF;

  RAISE NOTICE 'CA_0291 pre-flight OK';
END $$;

-- ─── 1. Move the seats ───────────────────────────────────────────────────────────────────────────
UPDATE essentials.office_terms t
   SET politician_id = pr.keep,
       source = t.source || ' | merged onto ' || pr.keep::text || ' by CA_0291 (2026-09-25)'
  FROM _pair pr
 WHERE t.id = pr.term_id AND t.politician_id = pr.seat;

-- Rutinel resigned: close his term (first vacant day 2026-09-05) and flag HD-32 vacant
SELECT essentials.vacate_office('5285c397-4694-4c6d-b8d6-8fc7566ddc91', '2026-09-05',
  'leg.colorado.gov/legislators/manny-rutinel: "Representative Rutinel resigned 9/4/26"; no successor reported '
  || '2026-09-25 (party declined a vacancy committee 2026-09-08; governor may appoint by 2026-10-12). CA_0291');

-- ─── 2. Swap external_id (unique, so through NULL) ───────────────────────────────────────────────
UPDATE essentials.politicians s SET external_id = NULL
  FROM _pair pr WHERE s.id = pr.seat AND s.external_id = pr.seat_ext
   AND EXISTS (SELECT 1 FROM essentials.politicians k WHERE k.id = pr.keep AND k.external_id IS NOT DISTINCT FROM pr.keep_ext);
UPDATE essentials.politicians k SET external_id = pr.seat_ext
  FROM _pair pr WHERE k.id = pr.keep AND k.external_id IS NOT DISTINCT FROM pr.keep_ext
   AND EXISTS (SELECT 1 FROM essentials.politicians s WHERE s.id = pr.seat AND s.external_id IS NULL);
UPDATE essentials.politicians s SET external_id = pr.keep_ext
  FROM _pair pr WHERE s.id = pr.seat AND s.external_id IS NULL AND pr.keep_ext IS NOT NULL
   AND EXISTS (SELECT 1 FROM essentials.politicians k WHERE k.id = pr.keep AND k.external_id = pr.seat_ext);

-- ─── 3. Deactivate the roster rows ───────────────────────────────────────────────────────────────
UPDATE essentials.politicians s
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(s.notes, ARRAY[]::text[]) || ('CA_0291 (2026-09-25): DUPLICATE of ' || pr.keep::text
               || ', the row that holds this person''s compass answers and 2026 race rows. Its seat (office_terms '
               || pr.term_id::text || ') and external_id moved there; deactivated, not deleted.')::text
  FROM _pair pr
 WHERE s.id = pr.seat AND (s.is_active OR s.is_incumbent);

-- ─── 4. Portraits and contacts ───────────────────────────────────────────────────────────────────
-- TN: the survivor takes the General Assembly portrait (as #796 did for Pearson)
UPDATE essentials.politician_images ki
   SET url = si.url, photo_license = si.photo_license
  FROM _pair pr
  JOIN essentials.politician_images si ON si.politician_id = pr.seat
 WHERE pr.portrait = 'official' AND ki.politician_id = pr.keep AND ki.type = 'default'
   AND ki.url IS DISTINCT FROM si.url;
UPDATE essentials.politicians k
   SET photo_custom_url = s.photo_custom_url, photo_origin_url = s.photo_origin_url
  FROM _pair pr JOIN essentials.politicians s ON s.id = pr.seat
 WHERE pr.portrait = 'official' AND k.id = pr.keep AND NOT k.photo_custom_url_manual_override
   AND (k.photo_custom_url IS DISTINCT FROM s.photo_custom_url OR k.photo_origin_url IS DISTINCT FROM s.photo_origin_url);

-- Smith: the survivor has no portrait; the roster row's image row and photo fields move
UPDATE essentials.politician_images i SET politician_id = pr.keep
  FROM _pair pr WHERE pr.portrait = 'move' AND i.politician_id = pr.seat;
UPDATE essentials.politicians k
   SET photo_custom_url = s.photo_custom_url, photo_origin_url = s.photo_origin_url
  FROM _pair pr JOIN essentials.politicians s ON s.id = pr.seat
 WHERE pr.portrait = 'move' AND k.id = pr.keep AND COALESCE(k.photo_custom_url, '') = ''
   AND NOT k.photo_custom_url_manual_override;

-- UT: the council office contact moves to the survivor
UPDATE essentials.politician_contacts c SET politician_id = pr.keep
  FROM _pair pr WHERE c.id = pr.contact_id AND c.politician_id = pr.seat;

-- ─── 5. The survivor holds the seat ──────────────────────────────────────────────────────────────
UPDATE essentials.politicians k
   SET is_incumbent = pr.still_seated,
       source       = COALESCE(k.source, s.source),
       data_source  = COALESCE(k.data_source, s.data_source),
       notes = COALESCE(k.notes, ARRAY[]::text[]) || ('CA_0291 (2026-09-25): holds the seat (office_terms '
               || pr.term_id::text || ') and external_id of ' || pr.seat::text || ', a duplicate row of the same person, '
               || 'now deactivated. Season 1 was not touched.'
               || CASE WHEN NOT pr.still_seated THEN ' The seat is closed: resigned 2026-09-04 (vacate_office).' ELSE '' END
               || CASE WHEN pr.portrait = 'official' THEN ' Portrait replaced with the General Assembly portrait; previous '
                         || 'photo_custom_url ' || COALESCE(b.photo_custom_url, 'NULL') || ', photo_origin_url '
                         || COALESCE(b.photo_origin_url, 'NULL') || ', image ' || COALESCE(b.image_url, 'NULL')
                         || ' (' || COALESCE(b.photo_license, 'NULL') || ').' ELSE '' END)::text
  FROM _pair pr JOIN essentials.politicians s ON s.id = pr.seat JOIN _photo_before b ON b.who = pr.who
 WHERE k.id = pr.keep
   AND NOT EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CA_0291 (2026-09-25): holds%');

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- survivors: active, the right incumbency, the roster external_id, the moved term, the note
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
   WHERE k.is_active AND k.is_incumbent = pr.still_seated AND k.external_id = pr.seat_ext
     AND EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.id = pr.term_id AND t.politician_id = pr.keep
                    AND strpos(t.source, 'merged onto ' || pr.keep::text || ' by CA_0291') > 0)
     AND EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CA_0291 (2026-09-25): holds%')
     AND (k.source IS NOT NULL OR k.data_source IS NOT NULL);
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: % of 6 survivors in their target state', v_n; END IF;
  -- the five still-held seats resolve to the survivor; HD-32 is closed and flagged
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.office_current_holder och ON och.office_id = pr.office_id
   WHERE pr.still_seated AND och.politician_id = pr.keep;
  IF v_n <> 5 THEN RAISE EXCEPTION 'POST: % of 5 held seats resolve to the survivor', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t JOIN essentials.offices o ON o.id = t.office_id
   WHERE t.id = '3243414b-a035-42b0-b556-4916644ae4f8' AND t.term_end = '2026-09-04' AND t.how_ended = 'resigned'
     AND o.is_vacant AND o.vacant_since = '2026-09-05';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Rutinel''s HD-32 term is not closed on 2026-09-04 with the office vacant'; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_current_holder
   WHERE office_id = '5285c397-4694-4c6d-b8d6-8fc7566ddc91' AND politician_id IS NOT NULL;  -- the view has a row per office
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: HD-32 still resolves to a current holder'; END IF;

  -- roster rows: inactive, empty, holding the survivor's old external_id
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians s ON s.id = pr.seat
   WHERE NOT s.is_active AND NOT s.is_incumbent AND s.external_id IS NOT DISTINCT FROM pr.keep_ext
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = s.id)
     AND NOT EXISTS (SELECT 1 FROM essentials.politician_contacts c WHERE c.politician_id = s.id)
     AND EXISTS (SELECT 1 FROM unnest(s.notes) n WHERE n LIKE 'CA_0291 (2026-09-25): DUPLICATE of ' || pr.keep::text || '%');
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: % of 6 roster rows deactivated, emptied and noted', v_n; END IF;

  -- portraits: TN survivors show the General Assembly portrait; Smith has one; Rutinel and Catten unchanged
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
    JOIN essentials.politician_images i ON i.politician_id = k.id
   WHERE pr.portrait = 'official' AND k.photo_origin_url LIKE 'https://wapp.capitol.tn.gov/apps/LegislatorInfo/Member?%'
     AND i.photo_license LIKE '(C) State of Tennessee%';
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 TN survivors carry the General Assembly portrait', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians k
   WHERE k.id = '92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4' AND COALESCE(k.photo_custom_url, '') <> ''
     AND EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = k.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Smith''s survivor has no portrait'; END IF;
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep JOIN _photo_before b ON b.who = pr.who
   WHERE pr.portrait = 'keep' AND k.photo_custom_url IS NOT DISTINCT FROM b.photo_custom_url;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: Rutinel''s or Catten''s portrait changed'; END IF;

  -- UT office contacts on the survivors
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politician_contacts c ON c.id = pr.contact_id
   WHERE c.politician_id = pr.keep;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 UT office contacts on the survivors', v_n; END IF;

  -- 🟢 Season 1 untouched
  SELECT count(*) INTO v_n FROM _inform_before b
   WHERE b.h IS DISTINCT FROM (
     CASE b.t
       WHEN 'a' THEN (SELECT md5(string_agg(a::text, '|' ORDER BY a.politician_id, a.topic_id, a.season_id))
                        FROM inform.politician_answers a WHERE a.politician_id IN (SELECT keep FROM _pair))
       ELSE          (SELECT md5(string_agg(c::text, '|' ORDER BY c.politician_id, c.topic_id, c.season_id))
                        FROM inform.politician_context c WHERE c.politician_id IN (SELECT keep FROM _pair))
     END);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: survivors'' answers or context changed; this file must not write inform.*'; END IF;

  -- one active row per person
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE (SELECT count(*) FROM essentials.politicians p WHERE p.is_active AND p.full_name = pr.who
             AND p.id IN (pr.keep, pr.seat)) = 1;
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: % of 6 people have exactly one active row', v_n; END IF;

  RAISE NOTICE 'CA_0291 applied: 6 seats moved onto the rows that hold the answers; HD-32 closed; Season 1 untouched';
END $$;

COMMIT;
