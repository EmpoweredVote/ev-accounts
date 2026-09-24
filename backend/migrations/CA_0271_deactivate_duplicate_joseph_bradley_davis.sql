-- CA_0271_deactivate_duplicate_joseph_bradley_davis.sql
-- Monroe County, Indiana: one Clerk candidate, two active person rows.
--
--   KEEP  c0c45428-53c9-473e-ba4b-dc956d1868f2  "Joe Davis"            race row (Monroe County Clerk, 2026 Indiana
--                                                                       Primary), portrait, committee link
--                                                                       4bdbd8b8… (monroe_county_joe_davis, OCR import)
--   DUP   ba1e0001-2026-4000-8000-000000000005  "Joseph Bradley Davis" 2026-05-22 seeding stub: no seat, no race row,
--                                                                       no portrait, no compass answers; one committee
--                                                                       link ac100001…0008 (external_id NULL)
--
-- WHY THE SAME PERSON: same name (Joe = Joseph), same office (Indiana's county clerk IS the Clerk of the Circuit
-- Court: the stub's note says "Circuit Court Clerk", the race says "Monroe County Clerk"), same county, and both
-- links carry the same 2026 CFA-4 pre-primary report. Established from our own rows only.
--
-- WHY IT MATTERS: both rows are active with a confirmed committee link, so one person counted twice among the Monroe
-- politicians reading "being processed", and a filed_report_summaries migration for his report would find two
-- confirmed links and fail its one-row gate (scripts/cfa-summaries-to-migration.ts).
--
-- WHY CA_0182 DID NOT CATCH IT: CA_0182 merges a seatless duplicate into a SEATED twin; neither Davis row holds a seat.
--
-- WHAT THIS DOES (CA_0182's pattern for a duplicate committee copy): the stub is deactivated, not deleted. Its link
-- stays on the deactivated row with a note — moving it would put a second copy of the same committee on the kept
-- row. The one fact only the stub's note holds ("$42,925 prior loan debt") is carried onto the kept link's notes.
-- No money moves: both links carry 0 contributions and 0 contribution_summary_agg rows.
--
-- IDEMPOTENT: every write is guarded; a re-run writes nothing and the gates pass.
-- ROLLBACK: UPDATE essentials.politicians SET is_active = true, notes = notes[1:array_length(notes,1)-1]
--           WHERE id = 'ba1e0001-2026-4000-8000-000000000005'; and strip the ' | CA_0271 …' suffixes from both links.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = 'c0c45428-53c9-473e-ba4b-dc956d1868f2' AND full_name = 'Joe Davis' AND is_active;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: kept row Joe Davis not found active'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = 'ba1e0001-2026-4000-8000-000000000005' AND full_name = 'Joseph Bradley Davis';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: duplicate row Joseph Bradley Davis not found'; END IF;

  -- the duplicate holds nothing but its one committee link
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE politician_id = 'ba1e0001-2026-4000-8000-000000000005';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: duplicate holds % office term(s)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id = 'ba1e0001-2026-4000-8000-000000000005';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: duplicate has % race row(s)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE politician_id = 'ba1e0001-2026-4000-8000-000000000005';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: duplicate has % image(s)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = 'ba1e0001-2026-4000-8000-000000000005';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: duplicate has % compass answer(s)', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = 'ba1e0001-2026-4000-8000-000000000005' AND id <> 'ac100001-2026-4000-8000-000000000008';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: duplicate has % unreviewed link(s)', v_n; END IF;

  -- both links are the reviewed ones, and carry no money or report summaries
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE (id = 'ac100001-2026-4000-8000-000000000008' AND essentials_politician_id = 'ba1e0001-2026-4000-8000-000000000005')
      OR (id = '4bdbd8b8-31d0-433d-a396-18f3efca60f3' AND essentials_politician_id = 'c0c45428-53c9-473e-ba4b-dc956d1868f2'
          AND external_id = 'monroe_county_joe_davis');
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 committee links in their reviewed state', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions
   WHERE politician_source_id IN ('ac100001-2026-4000-8000-000000000008', '4bdbd8b8-31d0-433d-a396-18f3efca60f3');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: the links carry % contribution(s)', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.filed_report_summaries
   WHERE politician_source_id IN ('ac100001-2026-4000-8000-000000000008', '4bdbd8b8-31d0-433d-a396-18f3efca60f3');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: the links carry % filed report(s)', v_n; END IF;
END $$;

-- ─── Writes ──────────────────────────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources
   SET notes = COALESCE(notes, '') || ' | CA_0271 (2026-09-24): from the duplicate row Joseph Bradley Davis '
               || '(ba1e0001-2026-4000-8000-000000000005): CFA-4 Pre-Primary 2026 notes "$42,925 prior loan debt".',
       updated_at = now()
 WHERE id = '4bdbd8b8-31d0-433d-a396-18f3efca60f3' AND COALESCE(notes, '') NOT LIKE '%CA_0271%';

UPDATE transparent_motivations.politician_sources
   SET notes = COALESCE(notes, '') || ' | CA_0271 (2026-09-24): left on the deactivated duplicate row; the same '
               || 'committee is linked on the kept row Joe Davis (c0c45428-53c9-473e-ba4b-dc956d1868f2).',
       updated_at = now()
 WHERE id = 'ac100001-2026-4000-8000-000000000008' AND COALESCE(notes, '') NOT LIKE '%CA_0271%';

UPDATE essentials.politicians
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(notes, ARRAY[]::text[]) || ('CA_0271 (2026-09-24): DUPLICATE of c0c45428-53c9-473e-ba4b-dc956d1868f2 '
               || '(Joe Davis), the row with the race record and portrait. Same Monroe County Clerk candidate; '
               || 'deactivated, not deleted.')::text
 WHERE id = 'ba1e0001-2026-4000-8000-000000000005' AND (is_active OR is_incumbent);

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = 'ba1e0001-2026-4000-8000-000000000005' AND NOT is_active AND NOT is_incumbent
     AND array_to_string(notes, ' ') LIKE '%CA_0271%';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: duplicate not deactivated with its note'; END IF;

  -- of the pair, exactly one ACTIVE row holds a confirmed Monroe committee link — the kept one.
  -- (Scoped to the two ids: Jack Davis, Perry Township Board, is a different person with his own link.)
  SELECT count(DISTINCT p.id) INTO v_n
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id AND p.is_active
   WHERE ps.source_system = 'IN_MONROE_COUNTY_LOCAL' AND ps.research_status = 'confirmed'
     AND p.id IN ('ba1e0001-2026-4000-8000-000000000005', 'c0c45428-53c9-473e-ba4b-dc956d1868f2');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % active rows of the pair with a confirmed Monroe link, expected 1', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE id IN ('ac100001-2026-4000-8000-000000000008', '4bdbd8b8-31d0-433d-a396-18f3efca60f3') AND notes LIKE '%CA_0271%';
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 links carry the CA_0271 note', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE id = '4bdbd8b8-31d0-433d-a396-18f3efca60f3' AND notes LIKE '%$42,925 prior loan debt%';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: loan-debt fact not carried to the kept link'; END IF;
END $$;

COMMIT;
