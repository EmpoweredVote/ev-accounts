-- CA_0226_merge_ca_federal_duplicates_fix_ruiz_fec_id.sql
--
-- STATUS: NOT YET APPLIED. Dry-run only (BEGIN ... ROLLBACK), pending operator go-ahead.
--
-- Found 2026-09-24 while checking the 94 confirmed FEC politician_sources rows whose politician holds
-- no current office (the rows run-fec-ingest-backfill.ts skips since #713). 92 of the 94 are 2026
-- House/Senate primary candidates with no seat, and 2 are Dooley/Wahls (closed by CA_0216). None is
-- a sitting officeholder with a missing term. But five known federal names among them carry defects:
--
-- 1. RAUL RUIZ — the SEATED row is linked to the WRONG PERSON'S FEC ID. (The one that matters.)
--      seated  5238b298-6004-4bcc-94c2-ee43a9c2999e  U.S. Representative CA-25, is_incumbent true
--              fec_house H0CA36177  e075f546-bae5-42fd-a5c8-36c3dbb162f3  confirmed
--      dup     05349fa0-8529-4738-8556-f386965e4cc8  inactive, source federal_2026_bulk_seed
--              fec_house H2CA36439  24017616-a2ee-4098-b05e-9b12483d7887  confirmed
--    FEC API, 2026-09-24 (GET /v1/candidates/?candidate_id=...):
--      H0CA36177  RUIZ, RAUL      CA-36  REP  Challenger  election_years [2020]            status P
--      H2CA36439  RUIZ, RAUL DR.  CA-25  DEM  Incumbent   election_years [2012 ... 2026]  status C
--    So the seated Democratic Representative showed a 2020 Republican challenger's money: 14 rows,
--    $6,170.00, all committee C00718387. His own committee's 39,905 rows ($11,788,393.09 in
--    contribution_summary_agg) hung off the invisible inactive duplicate.
--    Fix: dispute H0CA36177 (the OWN_FUNDRAISING_SQL predicate in campaignFinanceService.ts reads
--    research_status = 'confirmed' only, so its 14 rows drop out of every own-fundraising read; they
--    are kept, not deleted — they are a real record of a different person's committee), and move
--    H2CA36439 onto the seated row. Unlike CA_0213, the old rows are NOT this person's money, which
--    is why this one is disputed rather than left confirmed.
--
-- 2. ERIC SWALWELL — two active rows, neither seated (CA-14 is flagged vacant since 2026-04-14; FEC
--    lists H2CA15094 as candidate_inactive).
--      keep    c98fd0a3-ea50-4659-967a-209ea5da6087  party, photo, finance_summary, fec_house H2CA15094
--      dup     b0cddcaa-10e1-49a8-88e8-4489a4f4615b  source calmatters_2026, holds the CA Governor
--              race_candidates row 453da9c1-e864-4079-a201-3b3d3a75d90a (race bc936a36...)
--    Fix: move the Governor race_candidates row onto the keep row, deactivate the dup. The race row
--    carries no photo_url or website_url, so the race_candidate_mirror_data trigger writes nothing.
--
-- 3. TONY CÁRDENAS — left the House in January 2025; both rows already inactive. An earlier
--    "accent-dedup" pass chose bda8ce6a as the survivor (its politician_name_aliases row reads
--    'Tony Cárdenas', source accent-dedup) but left the FEC link on the accented row.
--      keep    bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c  23 answers + 23 context, alias, id bridge,
--              la_socrata 1327335 ("Councilman Tony Cardenas 2011")
--      dup     ee52c1ec-85b8-486e-83ea-4fe337497486  fec_house H2CA28113 cdaf3cb6-7a21-4628-ad4b-cc334d93ffda
--    Fix: move the FEC link onto the survivor, so one row holds both of his committees.
--
-- 4. CALVIN LEE — 2026 CA-34 candidate split across two rows.
--      keep    361c6a80-ed8a-4399-b09e-29b2011f6a9a  active, source ballotpedia, CA-34 race_candidates row
--      dup     1d7ca756-46a6-4ea6-b6f7-2bb629439ff0  inactive, federal_2026_bulk_seed,
--              fec_house H4CA34091 20eb962b-a9f3-4996-ae89-37099978e9af (0 contributions yet)
--    FEC: H4CA34091 LEE, CALVIN CA-34 REP, election_years [2024, 2026] — it IS the current-cycle ID,
--    so isCurrentFecId (#704) would accept it for a candidate.
--    Fix: move the FEC link onto the active row.
--
-- 5. DOUG LaMALFA — died in office in January 2026; James Gallagher won the special election and
--    holds CA-1 from 2026-06-10 (office_terms 1bee1841..., migration 1536). LaMalfa's row
--    339de020-9105-4dfd-a34c-a591f88a7ca1 holds no term and no race but was still is_active = true.
--    Fix: is_active = false. His confirmed fec_house H2CA02142 link stays: that money is his.
--
-- NOT moved (same rules as CA_0204):
--   - inform.politician_answers / inform.politician_context: none of the dup rows has any.
--   - essentials.politician_images: keyed by each row's own id in its storage path; left in place.
--   - finance_summary: left as it is on every row. FOLLOW-UP after apply: re-run the federal
--     finance-summary writer for Ruiz (backend/scripts/run-fec-finance-summary.ts), because his
--     seated row's 2026 summary may have been written from the wrong ID.
--   Every other table with a politician_id FK into essentials.politicians was checked 2026-09-24 and
--   holds zero rows for the four dup rows.
--
-- Nothing is deleted. Dup rows are deactivated with a note.
--
-- ROLLBACK (once applied):
--   1. UPDATE politician_sources SET essentials_politician_id = <dup> for 24017616..., cdaf3cb6...,
--      20eb962b... (dups listed above); set e075f546... back to research_status 'confirmed' and strip
--      the ' | CA_0226 ...' suffix from its notes.
--   2. UPDATE race_candidates SET politician_id = 'b0cddcaa-10e1-49a8-88e8-4489a4f4615b' for 453da9c1....
--   3. Set is_active = true on b0cddcaa... and 339de020...; strip the 'CA_0226 (2026-09-24):' notes
--      entries from all five politicians rows.
-- IDEMPOTENT: every write is guarded on its pre-image; a re-run changes nothing and every gate passes.

BEGIN;

CREATE TEMP TABLE _pair (loser uuid PRIMARY KEY, keep uuid NOT NULL, who text NOT NULL) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('05349fa0-8529-4738-8556-f386965e4cc8', '5238b298-6004-4bcc-94c2-ee43a9c2999e', 'Raul Ruiz'),
  ('b0cddcaa-10e1-49a8-88e8-4489a4f4615b', 'c98fd0a3-ea50-4659-967a-209ea5da6087', 'Eric Swalwell'),
  ('ee52c1ec-85b8-486e-83ea-4fe337497486', 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c', 'Tony Cárdenas'),
  ('1d7ca756-46a6-4ea6-b6f7-2bb629439ff0', '361c6a80-ed8a-4399-b09e-29b2011f6a9a', 'Calvin Lee');

-- FEC links that move from a dup onto its keep row (measured 2026-09-24: the only source on each dup)
CREATE TEMP TABLE _src (id uuid PRIMARY KEY, loser uuid NOT NULL, keep uuid NOT NULL, ext text NOT NULL) ON COMMIT DROP;
INSERT INTO _src VALUES
  ('24017616-a2ee-4098-b05e-9b12483d7887', '05349fa0-8529-4738-8556-f386965e4cc8', '5238b298-6004-4bcc-94c2-ee43a9c2999e', 'H2CA36439'),
  ('cdaf3cb6-7a21-4628-ad4b-cc334d93ffda', 'ee52c1ec-85b8-486e-83ea-4fe337497486', 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c', 'H2CA28113'),
  ('20eb962b-a9f3-4996-ae89-37099978e9af', '1d7ca756-46a6-4ea6-b6f7-2bb629439ff0', '361c6a80-ed8a-4399-b09e-29b2011f6a9a', 'H4CA34091');

-- Own-fundraising money per keep row BEFORE: confirmed candidate_committee sources on keep + dup,
-- minus the Ruiz link this migration disputes. After the merge the keep row alone must hold exactly this.
CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT pr.keep,
       (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
          JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
         WHERE ps.essentials_politician_id IN (pr.keep, pr.loser)
           AND ps.research_status = 'confirmed' AND ps.source_type = 'candidate_committee'
           AND ps.id <> 'e075f546-bae5-42fd-a5c8-36c3dbb162f3') AS own_total
FROM _pair pr;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- every pair: same name (accent-insensitive for Cárdenas), keep row exists
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep
    JOIN essentials.politicians d ON d.id = pr.loser
   WHERE translate(lower(k.full_name), 'á', 'a') = translate(lower(pr.who), 'á', 'a')
     AND translate(lower(d.full_name), 'á', 'a') = translate(lower(pr.who), 'á', 'a');
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 pairs have the expected names', v_n; END IF;

  -- Ruiz: keep is the seated CA-25 incumbent
  PERFORM 1 FROM essentials.politicians p WHERE p.id = '5238b298-6004-4bcc-94c2-ee43a9c2999e' AND p.is_active AND p.is_incumbent
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);
  IF NOT FOUND THEN RAISE EXCEPTION 'PRE: seated Raul Ruiz row is not an active seated incumbent'; END IF;

  -- the wrong Ruiz link is still on the seated row, as fec_house H0CA36177
  PERFORM 1 FROM transparent_motivations.politician_sources
   WHERE id = 'e075f546-bae5-42fd-a5c8-36c3dbb162f3' AND essentials_politician_id = '5238b298-6004-4bcc-94c2-ee43a9c2999e'
     AND source_system = 'fec_house' AND external_id = 'H0CA36177';
  IF NOT FOUND THEN RAISE EXCEPTION 'PRE: Ruiz H0CA36177 link not found on the seated row'; END IF;

  -- each moving source is on its dup or (re-run) its keep row, with the expected FEC ID
  SELECT count(*) INTO v_n FROM _src s JOIN transparent_motivations.politician_sources x ON x.id = s.id
   WHERE x.essentials_politician_id IN (s.loser, s.keep) AND x.external_id = s.ext AND x.source_system = 'fec_house';
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 moving sources are where expected', v_n; END IF;
  -- no unreviewed source on any dup
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN (SELECT loser FROM _pair) AND id NOT IN (SELECT id FROM _src);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed politician_sources row(s) on a dup', v_n; END IF;
  -- no collision on (politician, source_system, external_id)
  SELECT count(*) INTO v_n FROM _src s JOIN transparent_motivations.politician_sources b
      ON b.essentials_politician_id = s.keep AND b.id <> s.id AND b.source_system = 'fec_house' AND b.external_id = s.ext;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % moving source(s) would collide on the keep row', v_n; END IF;

  -- Swalwell's Governor race row is on the dup or (re-run) the keep row; the keep row is not already in that race
  PERFORM 1 FROM essentials.race_candidates WHERE id = '453da9c1-e864-4079-a201-3b3d3a75d90a'
     AND politician_id IN ('b0cddcaa-10e1-49a8-88e8-4489a4f4615b', 'c98fd0a3-ea50-4659-967a-209ea5da6087');
  IF NOT FOUND THEN RAISE EXCEPTION 'PRE: Swalwell Governor race_candidates row not found'; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE race_id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5' AND politician_id = 'c98fd0a3-ea50-4659-967a-209ea5da6087'
     AND id <> '453da9c1-e864-4079-a201-3b3d3a75d90a';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: Swalwell keep row already holds another row in the Governor race'; END IF;
  -- no other race row, term, answer or context on any dup
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE politician_id IN (SELECT loser FROM _pair) AND id <> '453da9c1-e864-4079-a201-3b3d3a75d90a';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed race_candidates row(s) on a dup', v_n; END IF;
  SELECT (SELECT count(*) FROM essentials.office_terms WHERE politician_id IN (SELECT loser FROM _pair))
       + (SELECT count(*) FROM inform.politician_answers WHERE politician_id IN (SELECT loser FROM _pair))
       + (SELECT count(*) FROM inform.politician_context WHERE politician_id IN (SELECT loser FROM _pair)) INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % term/answer/context row(s) on a dup — not reviewed', v_n; END IF;

  -- LaMalfa: no seat, no race
  SELECT (SELECT count(*) FROM essentials.office_terms WHERE politician_id = '339de020-9105-4dfd-a34c-a591f88a7ca1')
       + (SELECT count(*) FROM essentials.race_candidates WHERE politician_id = '339de020-9105-4dfd-a34c-a591f88a7ca1') INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: Doug LaMalfa holds % term/race row(s); expected none', v_n; END IF;

  RAISE NOTICE 'CA_0226 pre-flight OK';
END $$;

-- ─── 1. Ruiz: dispute the other Raul Ruiz's FEC ID on the seated row ─────────────────────────────
UPDATE transparent_motivations.politician_sources
   SET research_status = 'disputed',
       notes = COALESCE(notes, '') || ' | CA_0226 (2026-09-24): disputed — H0CA36177 is RUIZ, RAUL, a 2020 '
               || 'Republican challenger in CA-36 (FEC election_years [2020]), not Rep. Raul Ruiz (D, CA-25), '
               || 'whose ID is H2CA36439. Its 14 contributions (committee C00718387) are kept, not deleted.',
       updated_at = now()
 WHERE id = 'e075f546-bae5-42fd-a5c8-36c3dbb162f3' AND research_status = 'confirmed';

-- ─── 2. Move the FEC links onto the keep rows ───────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET essentials_politician_id = s.keep, updated_at = now()
  FROM _src s WHERE ps.id = s.id AND ps.essentials_politician_id = s.loser;

-- ─── 3. Swalwell: move the Governor race row ─────────────────────────────────────────────────────
UPDATE essentials.race_candidates
   SET politician_id = 'c98fd0a3-ea50-4659-967a-209ea5da6087'
 WHERE id = '453da9c1-e864-4079-a201-3b3d3a75d90a' AND politician_id = 'b0cddcaa-10e1-49a8-88e8-4489a4f4615b';

-- ─── 4. Deactivate the dup rows, with a note; nothing deleted ──────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0226 (2026-09-24): DUPLICATE of ' || pr.keep::text
               || ' (same person). Its FEC link / race row moved there. Deactivated, not deleted.')
  FROM _pair pr
 WHERE d.id = pr.loser
   AND NOT EXISTS (SELECT 1 FROM unnest(COALESCE(d.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0226 (2026-09-24):%');

-- ─── 5. LaMalfa: no longer an active person record ──────────────────────────────────────────────
UPDATE essentials.politicians
   SET is_active = false,
       notes = COALESCE(notes, ARRAY[]::text[]) || ('CA_0226 (2026-09-24): died in office January 2026; James '
               || 'Gallagher holds CA-1 from 2026-06-10 (special election). Deactivated; FEC link kept.')::text
 WHERE id = '339de020-9105-4dfd-a34c-a591f88a7ca1'
   AND NOT EXISTS (SELECT 1 FROM unnest(COALESCE(notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0226 (2026-09-24):%');

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; r record; v_after numeric;
BEGIN
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT loser FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % politician_sources row(s) still on a dup', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id IN (SELECT loser FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % race_candidates row(s) still on a dup', v_n; END IF;

  -- Ruiz seated row: exactly one confirmed FEC link, and it is H2CA36439
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '5238b298-6004-4bcc-94c2-ee43a9c2999e' AND source_system LIKE 'fec%' AND research_status = 'confirmed';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Ruiz seated row has % confirmed FEC links, expected 1', v_n; END IF;
  PERFORM 1 FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '5238b298-6004-4bcc-94c2-ee43a9c2999e' AND external_id = 'H2CA36439' AND research_status = 'confirmed';
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: Ruiz seated row does not hold confirmed H2CA36439'; END IF;
  PERFORM 1 FROM transparent_motivations.politician_sources
   WHERE id = 'e075f546-bae5-42fd-a5c8-36c3dbb162f3' AND research_status = 'disputed' AND notes LIKE '%CA_0226 (2026-09-24): disputed%';
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: Ruiz H0CA36177 link is not disputed with the note'; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE politician_source_id = 'e075f546-bae5-42fd-a5c8-36c3dbb162f3';
  IF v_n <> 14 THEN RAISE EXCEPTION 'POST: % contributions on the disputed Ruiz link, expected 14 (kept)', v_n; END IF;

  PERFORM 1 FROM essentials.race_candidates
   WHERE id = '453da9c1-e864-4079-a201-3b3d3a75d90a' AND politician_id = 'c98fd0a3-ea50-4659-967a-209ea5da6087';
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: Swalwell Governor race row is not on the keep row'; END IF;

  -- dups deactivated with the note; keeps unchanged in is_active
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id IN (SELECT loser FROM _pair) AND NOT is_active
     AND EXISTS (SELECT 1 FROM unnest(notes) n WHERE n LIKE 'CA_0226 (2026-09-24): DUPLICATE of%');
  IF v_n <> 4 THEN RAISE EXCEPTION 'POST: % of 4 dup rows deactivated with the note', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id IN ('5238b298-6004-4bcc-94c2-ee43a9c2999e', 'c98fd0a3-ea50-4659-967a-209ea5da6087', '361c6a80-ed8a-4399-b09e-29b2011f6a9a') AND is_active;
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 active keep rows still active', v_n; END IF;
  PERFORM 1 FROM essentials.politicians WHERE id = '5238b298-6004-4bcc-94c2-ee43a9c2999e' AND is_incumbent;
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: seated Ruiz row lost is_incumbent'; END IF;

  PERFORM 1 FROM essentials.politicians WHERE id = '339de020-9105-4dfd-a34c-a591f88a7ca1' AND NOT is_active AND NOT is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(notes) n WHERE n LIKE 'CA_0226 (2026-09-24): died in office%');
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: LaMalfa not deactivated with the note'; END IF;

  -- no own-fundraising money created or lost, except the disputed Ruiz link that is meant to drop out
  FOR r IN SELECT * FROM _before LOOP
    SELECT COALESCE(sum(a.total_amount), 0) INTO v_after FROM transparent_motivations.contribution_summary_agg a
      JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
     WHERE ps.essentials_politician_id = r.keep AND ps.research_status = 'confirmed' AND ps.source_type = 'candidate_committee';
    IF v_after <> r.own_total THEN
      RAISE EXCEPTION 'POST: own-fundraising total on % moved from % to %', r.keep, r.own_total, v_after;
    END IF;
  END LOOP;
  -- and the Ruiz figure is his own committee's, as measured 2026-09-24
  SELECT own_total INTO v_after FROM _before WHERE keep = '5238b298-6004-4bcc-94c2-ee43a9c2999e';
  IF v_after <> 11788393.09 THEN RAISE EXCEPTION 'POST: Ruiz own total is %, expected 11788393.09', v_after; END IF;

  RAISE NOTICE 'CA_0226 OK: Ruiz FEC ID corrected; Ruiz, Swalwell, Cárdenas, Calvin Lee dups merged; LaMalfa deactivated';
END $$;

COMMIT;
