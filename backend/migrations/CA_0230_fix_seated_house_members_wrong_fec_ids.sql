-- CA_0230_fix_seated_house_members_wrong_fec_ids.sql
--
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews, in chat, "go ahead with the two
--   follow-ups"; run by Chris Andrews with `psql -X -v ON_ERROR_STOP=1 -f`). Dry run first: body twice in
--   one rolled-back transaction — pass 1 wrote, pass 2 wrote 0, every gate passed both times, prod
--   unchanged after. The apply printed "CA_0230 OK". Verified after from a separate read-only session:
--   each of the six holds one confirmed fec_house link on the correct ID; H0GA02241 (145 rows) and
--   H4CA31170 (0 rows) are disputed; contribution counts unchanged (Ogles 14, Fields 896, Cisneros 9,384).
--
-- Six seated U.S. Representatives carry a confirmed fec_house politician_sources row whose external_id is
-- not the FEC candidate ID they are running on. Found 2026-09-24 by the sweep CA_0226 asked for: every
-- seated House/Senate member's confirmed FEC link (541 links) compared against GET /v1/candidates/ for
-- office, state, district, party, surname and election_years. 31 flagged; 25 are expected and are NOT
-- touched here:
--   - 11 sitting Representatives running for Senate, whose flagged link is their (correct) S6 Senate ID.
--   - 13 whose FEC district differs only because redistricting renumbered it; each ID lists 2026.
--   - Van Hollen, whom FEC lists under state DC; his S6MD03441 lists 2028.
-- The six below all have an ID whose last election is 2018 or earlier, or one FEC does not have at all.
-- Each correct ID was checked 2026-09-24 against the FEC API: it names the member, is the incumbent (I)
-- in their state and district, lists 2026, and has 2025-26 receipts (GET /v1/candidates/totals/?cycle=2026):
--
--   Andy Ogles     1bc25880...  H2TN04191  OGLES, WILLIAM ANDREW IV  TN-4  [2002, 2006]   -> H2TN05446  OGLES, ANDY           TN-5  $613,134.73
--   Cleo Fields    122f4dcd...  H0LA08025  FIELDS, CLEO              LA-4  [1990-1996]   -> H4LA06211  FIELDS, CLEO          LA-6  $833,358.49
--   Don Davis      f38f8dde...  H4NC01053  DAVIS, DONALD (DON)       NC-1  [2004]        -> H2NC02287  DAVIS, DON            NC-1  $4,287,385.78
--   Mike Kelly     4c34d7a5...  H4PA03117  KELLY, MIKE (challenger)  PA-16 [2016, 2018]  -> H0PA03271  KELLY, GEORGE J JR    PA-16 $1,168,432.91
--   Rick Allen     3de9e882...  H0GA02241  ALLEN, RICK (challenger)  GA-2  [2010, 2012]  -> H2GA12121  ALLEN, RICHARD W      GA-12 $993,220.17
--   Gil Cisneros   be2943b7...  H4CA31170  (FEC has no such candidate: /v1/candidate/H4CA31170/ returns 0 results,
--                                          while the same call returns H8CA39174)            -> H8CA39174  CISNEROS, GILBERT     CA-31 $705,263.13
--
-- WHAT HAPPENS TO THE CONTRIBUTIONS ALREADY ON THE OLD LINKS — decided per person, as in CA_0213 / CA_0226:
--   * SAME PERSON, EARLIER CAMPAIGN -> change external_id in place, keep the rows (they are this person's
--     real money, stamped with their own election_cycle; the next scheduled FEC run then resolves the new
--     ID's committee and upserts on sub_id, so nothing is duplicated). This is the CA_0213 shape.
--       Ogles  14 rows, cycle 2002, committee C00375170. "WILLIAM ANDREW IV" is Rep. Ogles' legal name, and
--              an operator confirmed this ID as him on 2026-07-08 (the row's notes); the ID is his, only old.
--       Fields 896 rows, cycles 1990-1996, three committees — his first House service (1993-1997).
--   * NO ROWS YET -> change external_id in place (Davis 0 rows, Kelly 0 rows). Nothing to attribute either way.
--   * DIFFERENT PERSON -> dispute the old link (rows kept, not deleted; OWN_FUNDRAISING_SQL reads confirmed
--     only, so they drop out) and add the correct link as a new row. This is the CA_0226 Ruiz shape.
--       Allen  H0GA02241 is a 2010-2012 challenger in GA-2 (145 rows, $29,264.15, committees C00481101,
--              C00506790). Rep. Allen's own ID H2GA12121 is GA-12 and starts in 2012.
--   * CISNEROS -> the RIGHT ID IS ALREADY LINKED, but demoted. Migration 1661 (b256a3b6) merged three Cisneros
--     rows and set H8CA39174 to not_applicable as a "prior CA-39 committee (2019-2021), superseded by canonical
--     FEC source H4CA31170". FEC shows the opposite: H8CA39174 is his one ID, now filed under CA-31 with
--     election_years [2018, 2020, 2024, 2026] (FEC keeps one ID per candidate per office and state), and
--     H4CA31170 does not exist. So H8CA39174 (9,384 rows, $13,250,598.66) goes back to confirmed, and
--     H4CA31170 (0 rows) is disputed. His finance_summary (total_raised 8347) is wrong as a result.
--
-- FOLLOW-UP after apply: the next scheduled FEC ingest fills the five new IDs' committees. Refresh
-- finance_summary for these six (backend/scripts/run-fec-finance-summary.ts) — Cisneros's is visibly wrong.
--
-- ROLLBACK (once applied):
--   1. UPDATE politician_sources SET external_id = <old> for 34ef06e8..., 22cf3982..., 7242d44d..., 24404dd2...
--      and strip the ' | CA_0230 ...' suffix from their notes.
--   2. Set 0bb3e5ab... and b202207a... back to 'confirmed', and 7ff209ac... back to 'not_applicable', stripping
--      the CA_0230 suffix; DELETE the new Allen row (source_system fec_house, external_id H2GA12121,
--      notes LIKE 'CA_0230%').
-- IDEMPOTENT: every write is guarded on its pre-image; a re-run changes nothing and every gate passes.

BEGIN;

-- links whose external_id changes in place
CREATE TEMP TABLE _swap (id uuid PRIMARY KEY, pid uuid, old_ext text NOT NULL, new_ext text NOT NULL,
                         n_rows int NOT NULL, why text NOT NULL) ON COMMIT DROP;
INSERT INTO _swap (id, pid, old_ext, new_ext, n_rows, why) VALUES
  ('34ef06e8-741d-454f-8907-2f5e581295d2', NULL, 'H2TN04191', 'H2TN05446', 14,
   'same person (FEC name OGLES, WILLIAM ANDREW IV = his legal name), 2002 campaign; its 14 rows stay'),
  ('22cf3982-a3d8-409c-b271-912d5c4d3541', NULL, 'H0LA08025', 'H4LA06211', 896,
   'same person, 1990-1996 campaigns (first House service 1993-1997); its 896 rows stay'),
  ('7242d44d-f284-4e0d-9d9b-2b8b0b26b3b3', NULL, 'H4NC01053', 'H2NC02287', 0,
   'H4NC01053 lists only 2004; no rows attached'),
  ('24404dd2-3f5d-4130-9436-dd4261930fec', NULL, 'H4PA03117', 'H0PA03271', 0,
   'H4PA03117 is a 2016-2018 PA-16 challenger; no rows attached');
-- pid is read from the link itself, so the table names each person once
UPDATE _swap s SET pid = ps.essentials_politician_id
  FROM transparent_motivations.politician_sources ps WHERE ps.id = s.id;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each swap link is on its person, a fec_house candidate_committee, still on the old or (re-run) new ID
  SELECT count(*) INTO v_n FROM _swap s JOIN transparent_motivations.politician_sources ps ON ps.id = s.id
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.source_system = 'fec_house' AND ps.source_type = 'candidate_committee' AND ps.research_status = 'confirmed'
     AND ps.external_id IN (s.old_ext, s.new_ext)
     AND left(p.id::text, 8) IN ('1bc25880', '122f4dcd', 'f38f8dde', '4c34d7a5')
     AND p.is_active AND p.is_incumbent
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 swap links are confirmed fec_house links of a seated incumbent', v_n; END IF;
  SELECT count(*) INTO v_n FROM _swap s
   WHERE (SELECT count(*) FROM transparent_motivations.contributions c WHERE c.politician_source_id = s.id) = s.n_rows;
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 swap links carry the measured contribution count', v_n; END IF;
  -- no collision: the new ID is not already linked to the same person under another row
  SELECT count(*) INTO v_n FROM _swap s JOIN transparent_motivations.politician_sources b
      ON b.essentials_politician_id = s.pid AND b.source_system = 'fec_house' AND b.external_id = s.new_ext AND b.id <> s.id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % new ID(s) already linked on another row', v_n; END IF;

  -- Allen: old link on the seated Allen row; the new ID either absent or (re-run) the row this file added
  PERFORM 1 FROM transparent_motivations.politician_sources ps JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.id = '0bb3e5ab-7ec8-4482-98ff-db2897ddde4f' AND ps.external_id = 'H0GA02241' AND ps.source_system = 'fec_house'
     AND p.full_name = 'Rick W. Allen' AND p.is_incumbent;
  IF NOT FOUND THEN RAISE EXCEPTION 'PRE: Rick Allen H0GA02241 link not found on the seated Allen row'; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.external_id = 'H2GA12121' AND COALESCE(ps.notes, '') NOT LIKE 'CA_0230%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: H2GA12121 is already linked somewhere (% row) — not by this file', v_n; END IF;

  -- Cisneros: both links on the seated Cisneros row
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.id IN ('7ff209ac-d093-4db1-8060-1bf1033cb8e7', 'b202207a-638e-431a-a7a8-e813020ce79a')
     AND ps.external_id IN ('H8CA39174', 'H4CA31170') AND p.full_name = 'Gil Cisneros' AND p.is_incumbent
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 Cisneros links on the seated Cisneros row', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE politician_source_id = 'b202207a-638e-431a-a7a8-e813020ce79a';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: H4CA31170 carries % contributions, expected 0', v_n; END IF;

  RAISE NOTICE 'CA_0230 pre-flight OK';
END $$;

-- ─── 1. Same person / no rows: change the ID in place ────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET external_id = s.new_ext,
       notes = COALESCE(ps.notes, '') || ' | CA_0230 (2026-09-24): external_id ' || s.old_ext || ' -> ' || s.new_ext
               || ' (FEC: ' || s.new_ext || ' is the incumbent ID and lists 2026; ' || s.why || ')',
       updated_at = now()
  FROM _swap s
 WHERE ps.id = s.id AND ps.external_id = s.old_ext;

-- ─── 2. Allen: dispute the other Rick Allen's ID, add Rep. Allen's own ─────────────────────────
UPDATE transparent_motivations.politician_sources
   SET research_status = 'disputed',
       notes = COALESCE(notes, '') || ' | CA_0230 (2026-09-24): disputed — H0GA02241 is ALLEN, RICK, a 2010-2012 '
               || 'challenger in GA-2, not Rep. Rick W. Allen (GA-12, H2GA12121). Its 145 rows are kept, not deleted.',
       updated_at = now()
 WHERE id = '0bb3e5ab-7ec8-4482-98ff-db2897ddde4f' AND research_status = 'confirmed';

INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, source_type, notes, created_at, updated_at)
SELECT ps.essentials_politician_id, 'fec_house', 'H2GA12121', 'confirmed', 'candidate_committee',
       'CA_0230 (2026-09-24): ALLEN, RICHARD W — House GA-12, incumbent, election_years 2012-2026 (FEC API). '
       || 'Replaces the disputed H0GA02241.', now(), now()
  FROM transparent_motivations.politician_sources ps
 WHERE ps.id = '0bb3e5ab-7ec8-4482-98ff-db2897ddde4f'
   AND NOT EXISTS (SELECT 1 FROM transparent_motivations.politician_sources x
                    WHERE x.essentials_politician_id = ps.essentials_politician_id
                      AND x.source_system = 'fec_house' AND x.external_id = 'H2GA12121');

-- ─── 3. Cisneros: restore his real ID, dispute the one FEC does not have ──────────────────────
UPDATE transparent_motivations.politician_sources
   SET research_status = 'confirmed',
       notes = COALESCE(notes, '') || ' | CA_0230 (2026-09-24): back to confirmed — FEC lists H8CA39174 under CA-31 '
               || 'with election_years 2018, 2020, 2024, 2026; it is his current ID. Migration 1661''s "canonical" '
               || 'H4CA31170 does not exist in FEC.',
       updated_at = now()
 WHERE id = '7ff209ac-d093-4db1-8060-1bf1033cb8e7' AND research_status = 'not_applicable';

UPDATE transparent_motivations.politician_sources
   SET research_status = 'disputed',
       notes = COALESCE(notes, '') || ' | CA_0230 (2026-09-24): disputed — FEC has no candidate H4CA31170 '
               || '(GET /v1/candidate/H4CA31170/ returns 0 results). His ID is H8CA39174.',
       updated_at = now()
 WHERE id = 'b202207a-638e-431a-a7a8-e813020ce79a' AND research_status = 'confirmed';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- every one of the six now holds exactly one confirmed fec_house link, and it is the correct ID
  SELECT count(*) INTO v_n FROM (
    SELECT p.id, array_agg(ps.external_id) ids
      FROM essentials.politicians p
      JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = p.id
       AND ps.source_system = 'fec_house' AND ps.research_status = 'confirmed'
     WHERE left(p.id::text, 8) IN ('1bc25880', '122f4dcd', 'f38f8dde', '4c34d7a5', '3de9e882', 'be2943b7')
       AND p.is_incumbent
     GROUP BY p.id) z
   WHERE cardinality(z.ids) = 1
     AND z.ids[1] IN ('H2TN05446', 'H4LA06211', 'H2NC02287', 'H0PA03271', 'H2GA12121', 'H8CA39174');
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: % of 6 members hold exactly one confirmed fec_house link on the correct ID', v_n; END IF;

  -- no old ID is still confirmed anywhere
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE research_status = 'confirmed' AND external_id IN ('H2TN04191', 'H0LA08025', 'H4NC01053', 'H4PA03117', 'H0GA02241', 'H4CA31170');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % old ID(s) still confirmed', v_n; END IF;

  -- nothing deleted: contribution counts on every touched link are what they were
  SELECT count(*) INTO v_n FROM _swap s
   WHERE (SELECT count(*) FROM transparent_motivations.contributions c WHERE c.politician_source_id = s.id) = s.n_rows;
  IF v_n <> 4 THEN RAISE EXCEPTION 'POST: % of 4 swapped links kept their contribution count', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE politician_source_id = '0bb3e5ab-7ec8-4482-98ff-db2897ddde4f';
  IF v_n <> 145 THEN RAISE EXCEPTION 'POST: disputed Allen link carries % rows, expected 145 (kept)', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE politician_source_id = '7ff209ac-d093-4db1-8060-1bf1033cb8e7';
  IF v_n <> 9384 THEN RAISE EXCEPTION 'POST: Cisneros H8CA39174 carries % rows, expected 9384', v_n; END IF;

  -- every change carries its note
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE (id IN (SELECT id FROM _swap) OR id IN ('0bb3e5ab-7ec8-4482-98ff-db2897ddde4f', '7ff209ac-d093-4db1-8060-1bf1033cb8e7',
                                                  'b202207a-638e-431a-a7a8-e813020ce79a')
          OR (external_id = 'H2GA12121' AND source_system = 'fec_house'))
     AND notes LIKE '%CA_0230 (2026-09-24)%';
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: % of 8 touched links carry the CA_0230 note', v_n; END IF;

  RAISE NOTICE 'CA_0230 OK: six seated Representatives now carry their current FEC ID (Ogles, Fields, Davis, Kelly, Allen, Cisneros)';
END $$;

COMMIT;
