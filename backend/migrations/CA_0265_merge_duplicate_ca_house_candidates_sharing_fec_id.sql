-- CA_0265_merge_duplicate_ca_house_candidates_sharing_fec_id.sql
-- Merge 3 duplicate person rows of 2026 California U.S. House candidates, each pair confirmed onto the SAME FEC id,
-- into the row that carries the person's race; deactivate the duplicates. Same pattern as CA_0182: the row the read
-- paths use is the person; what hangs on the duplicate moves to it; nothing is deleted.
--
-- THE PAIRS (duplicate -> kept row; FEC id):
--   Samuel Gallucci        9fe24d34-87c6-400e-8d81-b94646753b1d -> Sam Gallucci          9ca4ac11-5d8c-46e6-b0ff-1a065b2e2af9  H6CA26241
--   Angela Gonzalestorres  7b3fd2da-2ce0-4fef-aa7e-5fd24c03ca5d -> Angela Gonzales-Torres 7b99c301-222a-4ebf-8427-c7290685e245  H6CA34286
--   Angelica Duenas        3b0d3064-ead8-402d-b425-a2ce76f7c095 -> Angélica María Dueñas  07e97df5-c8d6-4e9c-9ea5-564b37c72b37  H8CA29100
--   The kept row holds the person's race rows (1 / 2 / 1), compass answers (1 / 0 / 17), context and image. The
--   duplicates (created 2026-05-22) hold ONLY campaign-finance links, seeded "via CLI on 2026-03-29".
--   Found 2026-09-24 verifying CA_0258: the 2026-09-24 FEC auto-match (#723 queue) found each person through their
--   race row and confirmed the same FEC id a second time, on the kept row, so the 06:00 UTC FEC ingest would have
--   loaded the same contributions twice.
--
-- THE MONEY IS ON THE DUPLICATES, so the links move, not the other way round:
--   Gonzalestorres FEC e4fe45bd-6690-4177-9e1b-8202d4310bd8: 320 contributions, $120,927.64
--   Duenas         FEC 57d9ddfb-77a8-45a7-bd9d-8d21d57cc349: 701 contributions, $185,304.34
--   Samuel         FEC 6ed9dca9-afdc-4a1e-a386-ebd6f648b68f: 142 contributions, $403,262.88
--                  Cal-Access 1439469 bfeef88f-fc5f-4856-9edd-29a77a389d3f (confirmed, "GALLUCCI FOR GOVERNOR 2021"):
--                    124 contributions, $180,045.00
--                  Cal-Access 1436083 6028f18a-15a7-4e12-83cf-b0bba5fa6197 (not_applicable) and 1025214
--                    facd6e60-dcd4-4ef2-aefd-008b5e1796d5 (needs_research): no money; moved with their status unchanged.
--   Contributions, aggregates and ingestion runs follow the link id, so moving a link moves its money.
--
-- THE COLLISION: each kept row already has an EMPTY copy of the same FEC link, written today by the auto-match
-- (07b1ab19-9f97-42de-9c93-4c170be6168b, 29d44fd7-374a-4441-843e-49d8cd91b260, 4fb155bc-4a84-4500-85bd-9694abe42499:
-- 0 contributions, 0 aggregates, 0 ingestion runs). The (politician, system, external_id) key is checked row by row, so
-- the two copies cannot trade places in one statement. As in CA_0182, a three-step swap: (a) the empty copy takes a
-- transient external_id, (b) the funded copy moves to the kept row, (c) the empty copy lands on the deactivated
-- duplicate under its real external_id, as not_applicable with a note -- NOT confirmed, because getConfirmedFecSources
-- has no is_active filter and would ingest it again.
--
-- THEN: each duplicate is deactivated (is_active = false, is_incumbent = false) with a note naming its twin.
-- No compass data, quotes, race rows or images are on the duplicates. finance_summary is NULL on all six rows.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE. No office_terms change.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval and apply: Chris Andrews). Dry run (BEGIN ... ROLLBACK) passed and
--   was confirmed reverted before the apply; verified after: 3 duplicates inactive, each holding only its parked
--   not_applicable empty copy; the 6 links (1,287 contributions, $889,539.86 in aggregates) on the kept rows; no FEC id
--   confirmed on two people anywhere.
--
-- ROLLBACK: re-point the _move link ids back to their duplicate row; give each _empty link a transient external_id,
-- move it back to its kept row, restore external_id and research_status 'confirmed' and strip its CA_0265 note; set the
-- duplicates' is_active back to true, removing their CA_0265 note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (dup uuid PRIMARY KEY, keep uuid, dup_name text, keep_name text, fec_id text) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('9fe24d34-87c6-400e-8d81-b94646753b1d', '9ca4ac11-5d8c-46e6-b0ff-1a065b2e2af9', 'Samuel Gallucci', 'Sam Gallucci', 'H6CA26241'),
  ('7b3fd2da-2ce0-4fef-aa7e-5fd24c03ca5d', '7b99c301-222a-4ebf-8427-c7290685e245', 'Angela Gonzalestorres', 'Angela Gonzales-Torres', 'H6CA34286'),
  ('3b0d3064-ead8-402d-b425-a2ce76f7c095', '07e97df5-c8d6-4e9c-9ea5-564b37c72b37', 'Angelica Duenas', 'Angélica María Dueñas', 'H8CA29100');

-- links that move from the duplicate to the kept row
CREATE TEMP TABLE _move (id uuid PRIMARY KEY, dup uuid) ON COMMIT DROP;
INSERT INTO _move VALUES
  ('6ed9dca9-afdc-4a1e-a386-ebd6f648b68f', '9fe24d34-87c6-400e-8d81-b94646753b1d'),  -- FEC H6CA26241, funded
  ('bfeef88f-fc5f-4856-9edd-29a77a389d3f', '9fe24d34-87c6-400e-8d81-b94646753b1d'),  -- Cal-Access 1439469, confirmed
  ('6028f18a-15a7-4e12-83cf-b0bba5fa6197', '9fe24d34-87c6-400e-8d81-b94646753b1d'),  -- Cal-Access 1436083, not_applicable
  ('facd6e60-dcd4-4ef2-aefd-008b5e1796d5', '9fe24d34-87c6-400e-8d81-b94646753b1d'),  -- Cal-Access 1025214, needs_research
  ('e4fe45bd-6690-4177-9e1b-8202d4310bd8', '7b3fd2da-2ce0-4fef-aa7e-5fd24c03ca5d'),  -- FEC H6CA34286, funded
  ('57d9ddfb-77a8-45a7-bd9d-8d21d57cc349', '3b0d3064-ead8-402d-b425-a2ce76f7c095');  -- FEC H8CA29100, funded

-- the kept rows' empty copies of the same FEC link, which step aside onto the duplicate
CREATE TEMP TABLE _empty (id uuid PRIMARY KEY, keep uuid, fec_id text) ON COMMIT DROP;
INSERT INTO _empty VALUES
  ('4fb155bc-4a84-4500-85bd-9694abe42499', '9ca4ac11-5d8c-46e6-b0ff-1a065b2e2af9', 'H6CA26241'),
  ('07b1ab19-9f97-42de-9c93-4c170be6168b', '7b99c301-222a-4ebf-8427-c7290685e245', 'H6CA34286'),
  ('29d44fd7-374a-4441-843e-49d8cd91b260', '07e97df5-c8d6-4e9c-9ea5-564b37c72b37', 'H8CA29100');

-- Fresh temp tables carry no statistics; without ANALYZE the planner scans all of contributions for the
-- IN (SELECT id FROM _move) counts below and the statement times out (found in the dry run).
ANALYZE _pair;
ANALYZE _move;
ANALYZE _empty;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
          JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
         WHERE ps.research_status = 'confirmed') AS confirmed_total,
       (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
         WHERE a.politician_source_id IN (SELECT id FROM _move)) AS moved_money,
       (SELECT count(*) FROM transparent_motivations.contributions c
         WHERE c.politician_source_id IN (SELECT id FROM _move)) AS moved_contributions;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- every kept row is active, named as reviewed, and carries at least one race row; every duplicate holds no term,
  -- no race row, no compass data, no quote
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep AND k.full_name = pr.keep_name AND k.is_active
    JOIN essentials.politicians d ON d.id = pr.dup AND d.full_name = pr.dup_name
   WHERE EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.politician_id = pr.keep)
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = pr.dup)
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.politician_id = pr.dup)
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = pr.dup)
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c WHERE c.politician_id = pr.dup)
     AND NOT EXISTS (SELECT 1 FROM essentials.quotes q WHERE q.politician_id = pr.dup);
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 pairs in their reviewed state', v_n; END IF;

  -- the duplicates carry exactly the reviewed links (on the duplicate, or already moved to the kept row)
  SELECT count(*) INTO v_n FROM _move m JOIN transparent_motivations.politician_sources ps ON ps.id = m.id
   WHERE ps.essentials_politician_id IN (m.dup, (SELECT keep FROM _pair WHERE dup = m.dup));
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % of 6 reviewed links on their duplicate or kept row', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT dup FROM _pair)
     AND ps.id NOT IN (SELECT id FROM _move) AND ps.id NOT IN (SELECT id FROM _empty);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed link(s) on the duplicates', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT keep FROM _pair)
     AND ps.id NOT IN (SELECT id FROM _move) AND ps.id NOT IN (SELECT id FROM _empty);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed link(s) on the kept rows', v_n; END IF;

  -- the empty copies are still empty: no money, no aggregate, no ingestion run
  SELECT count(*) INTO v_n FROM _empty e JOIN transparent_motivations.politician_sources ps ON ps.id = e.id
   WHERE ps.source_system = 'fec_house'
     AND ps.external_id IN (e.fec_id, e.fec_id || '#CA_0265')
     AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contributions c WHERE c.politician_source_id = ps.id)
     AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contribution_summary_agg a WHERE a.politician_source_id = ps.id)
     AND NOT EXISTS (SELECT 1 FROM transparent_motivations.ingestion_runs r WHERE r.politician_source_id = ps.id);
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 empty FEC copies still empty', v_n; END IF;

  -- the FEC id is on no third person
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN _pair pr ON ps.external_id = pr.fec_id
   WHERE ps.source_system LIKE 'fec%' AND ps.essentials_politician_id NOT IN (pr.dup, pr.keep);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % FEC link(s) with these ids on a third person', v_n; END IF;
END $$;

-- ─── 1. The swap: empty copy aside, funded links across, empty copy onto the duplicate ─────────
UPDATE transparent_motivations.politician_sources ps
   SET external_id = e.fec_id || '#CA_0265'
  FROM _empty e
 WHERE ps.id = e.id AND ps.essentials_politician_id = e.keep AND ps.external_id = e.fec_id;

UPDATE transparent_motivations.politician_sources ps SET essentials_politician_id = pr.keep, updated_at = now()
  FROM _move m JOIN _pair pr ON pr.dup = m.dup
 WHERE ps.id = m.id AND ps.essentials_politician_id = m.dup;

UPDATE transparent_motivations.politician_sources ps
   SET essentials_politician_id = pr.dup, external_id = e.fec_id, research_status = 'not_applicable',
       notes = COALESCE(ps.notes, '') || ' | CA_0265 (2026-09-24): EMPTY duplicate of the funded ' || e.fec_id
               || ' link, which moved to ' || pr.keep_name || ' (' || pr.keep::text || '). Parked on the deactivated '
               || 'duplicate row as not_applicable so the FEC ingest does not load the same money twice.',
       updated_at = now()
  FROM _empty e JOIN _pair pr ON pr.keep = e.keep
 WHERE ps.id = e.id AND ps.external_id = e.fec_id || '#CA_0265';

-- ─── 2. Deactivate the duplicates ─────────────────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0265 (2026-09-24): DUPLICATE of ' || pr.keep::text || ' ('
               || pr.keep_name || '), the row that carries the race. Campaign-finance links (with their contributions) '
               || 'moved there; deactivated, not deleted.')::text
  FROM _pair pr
 WHERE d.id = pr.dup AND (d.is_active OR d.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_amt numeric; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM essentials.politicians d JOIN _pair pr ON pr.dup = d.id
   WHERE NOT d.is_active AND NOT d.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0265 (2026-09-24): DUPLICATE of%');
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 duplicates deactivated with the note', v_n; END IF;

  -- each kept row: exactly one FEC link, confirmed, onto its id, and it is the funded one
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE (SELECT count(*) FROM transparent_motivations.politician_sources ps
           WHERE ps.essentials_politician_id = pr.keep AND ps.source_system LIKE 'fec%') = 1
     AND EXISTS (SELECT 1 FROM transparent_motivations.politician_sources ps JOIN _move m ON m.id = ps.id
                  WHERE ps.essentials_politician_id = pr.keep AND ps.external_id = pr.fec_id AND ps.research_status = 'confirmed');
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 kept rows hold exactly one confirmed, funded FEC link', v_n; END IF;

  SELECT count(*) INTO v_n FROM _move m JOIN _pair pr ON pr.dup = m.dup JOIN transparent_motivations.politician_sources ps ON ps.id = m.id
   WHERE ps.essentials_politician_id = pr.keep;
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: % of 6 links on the kept rows', v_n; END IF;

  -- the duplicates keep only the parked empty copies, none confirmed
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT dup FROM _pair);
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % links on the duplicates, expected the 3 parked empty copies', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT dup FROM _pair) AND ps.research_status = 'confirmed';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % confirmed links left on the duplicates', v_n; END IF;

  -- no FEC id is confirmed on two people any more
  SELECT count(*) INTO v_n FROM (SELECT ps.external_id FROM transparent_motivations.politician_sources ps
    WHERE ps.source_system LIKE 'fec%' AND ps.research_status = 'confirmed' AND ps.external_id IN (SELECT fec_id FROM _pair)
    GROUP BY 1 HAVING count(DISTINCT ps.essentials_politician_id) > 1) x;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % of these FEC ids still confirmed on two people', v_n; END IF;

  -- the money that moved sits on the kept rows, the contributions came along, and the confirmed total did not move
  SELECT COALESCE(sum(a.total_amount), 0) INTO v_amt FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
   WHERE ps.id IN (SELECT id FROM _move) AND ps.essentials_politician_id IN (SELECT keep FROM _pair);
  IF v_amt <> b.moved_money THEN RAISE EXCEPTION 'POST: % of the % moved money sits on the kept rows', v_amt, b.moved_money; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _move);
  IF v_n <> b.moved_contributions THEN RAISE EXCEPTION 'POST: moved contributions % <> %', v_n, b.moved_contributions; END IF;
  SELECT b.confirmed_total - (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
                               JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
                              WHERE ps.research_status = 'confirmed') INTO v_amt;
  IF v_amt <> 0 THEN RAISE EXCEPTION 'POST: the confirmed total moved by %', v_amt; END IF;

  RAISE NOTICE 'CA_0265 applied: 3 duplicates merged and deactivated; 6 links (% in aggregates, % contributions) on the kept rows',
    b.moved_money, b.moved_contributions;
END $$;

COMMIT;
