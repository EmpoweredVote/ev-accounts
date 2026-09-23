-- CA_0166_dispute_wrong_committee_links_la_placeholders.sql
-- Mark four WRONG campaign-finance committee links as 'disputed'. Each sits on a placeholder politician row
-- that CA_0159 deactivated (no evidence the person ever served on the recorded LA school board), and each
-- was auto-linked by surname, so the committee belongs to a different person:
--
--   f562b03c  Dolores Santiago   (Keppel)     la_socrata 1459824  "MIGUEL SANTIAGO FOR CITY COUNCIL 2024"
--   ac2c4d9d  Gale Reyes         (Saugus)     la_socrata 1272919  "Eddie Reyes for City Council"
--   aecdb7b6  Joe Renteria       (Lancaster)  cal_access 1410537  "RENTERIA FOR LYNWOOD SCHOOL BOARD 2018"
--   4b0f3e70  Lance Christensen  (Saugus)     cal_access 1309495  "CHRISTENSEN FOR SCHOOL BOARD, LANCE"
--
-- Linked by audit-socrata-committees.ts / confirm-cal-access.ts on first+last or surname alone. None of these
-- committees is for the board the row sat on (Keppel, Saugus, Lancaster), and CA_0159 found no evidence any of
-- the four served there. No politician row exists for the committees' real owners (Miguel Santiago, Eddie
-- Reyes, a Lynwood USD candidate Renteria, the Lance Christensen of the committee), so the links cannot be
-- re-pointed -- they are disputed, not moved.
--
-- WHY 'disputed' AND NOT DELETE: 1,034 contributions, 7 contribution_summary_agg rows and 27 ingestion_runs
-- hang off these four politician_sources rows; they describe the committee, which is real. Every read path
-- (campaignFinanceService summary/cycle reads, FEC backfill, adapters) requires research_status = 'confirmed',
-- so 'disputed' stops attributing the money to anyone at once, with no aggregate rebuild. The status is the
-- admin API's own value for a wrong link (campaignFinanceAdmin.ts).
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- ROLLBACK: UPDATE transparent_motivations.politician_sources SET research_status = 'confirmed',
--   notes = (notes::jsonb - 'disputed_by' - 'disputed_reason')::text WHERE id IN (the four ids below).
-- IDEMPOTENT: the update is guarded on research_status = 'confirmed'; a re-run is a no-op and the gate passes.

BEGIN;

CREATE TEMP TABLE _link (id uuid PRIMARY KEY, politician_id uuid, source_system text, external_id text, committee text, reason text) ON COMMIT DROP;
INSERT INTO _link VALUES
  ('f562b03c-9b0e-4e21-8168-bd557121367c','2a954d75-5a34-4753-b508-be66799bc760','la_socrata','1459824','MIGUEL SANTIAGO FOR CITY COUNCIL 2024',
   'surname-only auto-link: the committee is Miguel Santiago''s (City Council 2024); this row is a CA_0159 no-evidence Keppel USD placeholder (deactivated)'),
  ('ac2c4d9d-e23a-426d-964c-58f54bdbcb96','c471d672-413b-42ef-862b-2acf76e8c000','la_socrata','1272919','Eddie Reyes for City Council',
   'surname-only auto-link: the committee is Eddie Reyes''s (City Council); this row is a CA_0159 no-evidence Saugus USD placeholder (deactivated)'),
  ('aecdb7b6-ccb8-4e05-846a-5564bf7ce466','aa1cf148-3ad0-4295-924c-11ac69157685','cal_access','1410537','RENTERIA FOR LYNWOOD SCHOOL BOARD 2018',
   'surname-only auto-link: the committee is a 2018 LYNWOOD school board campaign; this row is a CA_0159 no-evidence Lancaster SD placeholder (deactivated)'),
  ('4b0f3e70-d331-4469-9057-cae9cfc3b221','713aba1d-06cc-4631-97b5-de89302df717','cal_access','1309495','CHRISTENSEN FOR SCHOOL BOARD, LANCE',
   'name-only auto-link: no evidence the committee''s Lance Christensen ever sought or held a Saugus USD seat; this row is a CA_0159 no-evidence Saugus USD placeholder (deactivated)');


-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each link is the recorded (system, committee id, committee name) on a CA_0159-deactivated placeholder row
  SELECT count(*) INTO v_n FROM _link l
    JOIN transparent_motivations.politician_sources ps ON ps.id = l.id
     AND ps.source_system = l.source_system AND ps.external_id = l.external_id
     AND ps.notes LIKE '%' || l.committee || '%' AND ps.research_status IN ('confirmed','disputed')
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id AND p.id = l.politician_id
     AND NOT p.is_active AND p.source = 'scraped'
     AND p.data_source LIKE 'https://empowered.vote/school-district/%'
     AND EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0159 (2026-09-22): NO EVIDENCE%');
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 links match the recorded committee on a CA_0159-deactivated row', v_n; END IF;
END $$;

-- ─── 1. Dispute the four links ───────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'disputed',
       notes = (COALESCE(NULLIF(ps.notes, ''), '{}')::jsonb
                || jsonb_build_object('disputed_by', 'CA_0166 (2026-09-23)', 'disputed_reason', l.reason))::text,
       updated_at = now()
  FROM _link l
 WHERE ps.id = l.id AND ps.research_status = 'confirmed';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN _link l ON l.id = ps.id
   WHERE ps.research_status = 'disputed' AND (ps.notes::jsonb ->> 'disputed_by') = 'CA_0166 (2026-09-23)';
  IF v_n <> 4 THEN RAISE EXCEPTION 'POST: % of 4 links disputed', v_n; END IF;

  -- the four placeholder rows now carry no confirmed committee at all
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT politician_id FROM _link) AND ps.research_status = 'confirmed';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % confirmed link(s) remain on the four rows', v_n; END IF;

  -- the money is no longer attributed: no confirmed source reaches these committees' aggregates
  SELECT count(*) INTO v_n FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
   WHERE a.politician_source_id = ANY (ARRAY['f562b03c-9b0e-4e21-8168-bd557121367c','ac2c4d9d-e23a-426d-964c-58f54bdbcb96','aecdb7b6-ccb8-4e05-846a-5564bf7ce466','4b0f3e70-d331-4469-9057-cae9cfc3b221']::uuid[]) AND ps.research_status = 'confirmed';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % aggregate row(s) still reachable as confirmed', v_n; END IF;

  -- nothing was deleted: contributions keep their committee
  -- literal ids, not a temp-table subquery: contributions is large and the planner has no stats on _link
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions c WHERE c.politician_source_id = ANY (ARRAY['f562b03c-9b0e-4e21-8168-bd557121367c','ac2c4d9d-e23a-426d-964c-58f54bdbcb96','aecdb7b6-ccb8-4e05-846a-5564bf7ce466','4b0f3e70-d331-4469-9057-cae9cfc3b221']::uuid[]);
  IF v_n <> 1034 THEN RAISE EXCEPTION 'POST: % contributions on the four sources, expected 1034 (untouched)', v_n; END IF;

  RAISE NOTICE 'CA_0166 applied: 4 wrong committee links disputed; 1,034 contributions kept, no longer attributed';
END $$;

COMMIT;
