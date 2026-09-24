-- CA_0187_resolve_two_judges_ca0183_left_unresolved.sql
-- Resolve the 2 active "incumbent" rows with no seat that CA_0183 left unresolved, because their names did not
-- match the LA Superior Court roster exactly. After this file, no active row reads is_incumbent = true without an
-- office_terms row (1,817 before CA_0181).
--
-- EVIDENCE (fetched 2026-09-23):
--   Roy G. Delgado (61b69001) -> SEATED on his own termless office c2f50030 ("LA County Superior Court - Roy G.
--     Delgado"). The court's judicial-officers roster lists "Rogelio Delgado" (Pomona, Dept. M,
--     https://www.lacourt.ca.gov/apps/judicial-officers/home); Bloomberg's profile names him "Hon Rogelio Delgado
--     'Roy'"; Ballotpedia (https://ballotpedia.org/Roy_G._Delgado): "Delgado was appointed by Gov. Arnold
--     Schwarzenegger (R) in January 2008", current term ends 2029-01-08. Same person. No other Delgado row exists
--     except an inactive committee-named row (4a8f0775, "DELGADO FOR SCHOOL BOARD 2016, ROGELIO"), a different filer.
--     Start: January 2008 -> term_start 2008-01-01, start_precision 'month', how_started 'appointed'.
--   Juan Carlos Dominguez (906b55ef) -> is_incumbent CLEARED. Ballotpedia (https://ballotpedia.org/Juan_Carlos_Dominguez):
--     "He left office on May 9, 2025" (appointed 2006). The roster's "E. Carlos Dominguez" is a DIFFERENT judge
--     (appointed by Gov. Newsom 2021-09-03, former Deputy Attorney General; https://ballotpedia.org/E._Carlos_Dominguez),
--     who already has his own row (46d429fb), seated by CA_0183. Nothing is merged.
--     House convention (CA_0156, CA_0185): a real former officeholder stays ACTIVE with is_incumbent = false. No past
--     term is written: his office 35d33ab3 has no term to close, and a start date for his tenure there is not needed.
--
-- Both rows are 'manual' seeds of 2026-05-22 with no committee links, answers or race rows.
-- Seating Delgado adds 1 district to the reachability check's UNREACHABLE ca|JUDICIAL bucket (421 -> 422), because
-- no CA JUDICIAL district has a geo_id yet; the separate court-geography task fixes the whole bucket.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews). Dry run x2 with a snapshot control right before
--   the apply; re-run after it changed nothing. Verified after: Delgado holds c2f50030 (2008-01-01, month, appointed);
--   Juan Carlos Dominguez is_incumbent false; active incumbents with no seat = 0; offices_missing_terms 429 -> 428.
--
-- ROLLBACK: DELETE FROM essentials.office_terms WHERE office_id = 'c2f50030-4925-4c39-bb47-8c2e90c488cd'
--             AND source LIKE 'CA_0187 (2026-09-23)%';
--           UPDATE essentials.politicians SET is_incumbent = true,
--             notes = array(SELECT n FROM unnest(notes) n WHERE n NOT LIKE 'CA_0187 (2026-09-23)%')
--             WHERE id = '906b55ef-4cef-472c-b619-605a970dda18';
-- IDEMPOTENT: seat_officeholder is idempotent; the UPDATE is guarded on is_incumbent = true. A re-run changes nothing
-- and every gate still passes -- except the last one, which reads the WHOLE table: it fails if any other row has since
-- become an active incumbent with no seat. That failure is a real finding, not a defect in this file.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- Delgado: active, the right office, and either not yet seated or seated by this file
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = '61b69001-71cf-480c-a8e0-bebb6ff71b22' AND p.full_name = 'Roy G. Delgado' AND p.is_active AND p.is_incumbent;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Roy G. Delgado row not in its reviewed state (% found)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.id = 'c2f50030-4925-4c39-bb47-8c2e90c488cd' AND d.label = 'LA County Superior Court - Roy G. Delgado'
     AND o.title = 'Judge, Los Angeles County Superior Court';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: office c2f50030 is not Delgado''s LASC office'; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE (t.office_id = 'c2f50030-4925-4c39-bb47-8c2e90c488cd' OR t.politician_id = '61b69001-71cf-480c-a8e0-bebb6ff71b22')
     AND t.source NOT LIKE 'CA_0187 (2026-09-23)%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % term(s) from elsewhere already on Delgado or his office', v_n; END IF;

  -- Dominguez: active, seatless, incumbent or already cleared by this file
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = '906b55ef-4cef-472c-b619-605a970dda18' AND p.full_name = 'Juan Carlos Dominguez' AND p.is_active
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = p.id)
     AND (p.is_incumbent OR EXISTS (SELECT 1 FROM unnest(p.notes) n WHERE n LIKE 'CA_0187 (2026-09-23)%'));
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Juan Carlos Dominguez row not in its reviewed state (% found)', v_n; END IF;

  -- the other Dominguez is a different, seated judge and stays untouched
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och
   WHERE och.politician_id = '46d429fb-919f-47f9-9032-c2391185c3c5' AND och.office_id = '4bd834ee-f9d4-43f3-9745-20b93635b78d';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: E. Carlos Dominguez is not seated on 4bd834ee'; END IF;
END $$;

SELECT essentials.seat_officeholder(
  'c2f50030-4925-4c39-bb47-8c2e90c488cd'::uuid,
  '61b69001-71cf-480c-a8e0-bebb6ff71b22'::uuid,
  DATE '2008-01-01',
  'CA_0187 (2026-09-23): current LA Superior Court judge. Listed as "Rogelio Delgado" on https://www.lacourt.ca.gov/apps/judicial-officers/home (fetched 2026-09-23); appointed January 2008 by Gov. Schwarzenegger, term ends 2029-01-08 (https://ballotpedia.org/Roy_G._Delgado).',
  p_how_started => 'appointed',
  p_start_precision => 'month');

UPDATE essentials.politicians p
   SET is_incumbent = false,
       notes = COALESCE(p.notes, ARRAY[]::text[]) || ('CA_0187 (2026-09-23): former LA Superior Court judge; left office 2025-05-09 (https://ballotpedia.org/Juan_Carlos_Dominguez). '
               || 'Not the roster''s E. Carlos Dominguez (46d429fb, appointed 2021). No seat here, so is_incumbent cleared.')::text
 WHERE p.id = '906b55ef-4cef-472c-b619-605a970dda18' AND p.is_incumbent;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och
   WHERE och.office_id = 'c2f50030-4925-4c39-bb47-8c2e90c488cd' AND och.politician_id = '61b69001-71cf-480c-a8e0-bebb6ff71b22';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Delgado does not read as the holder of c2f50030'; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t
   WHERE t.office_id = 'c2f50030-4925-4c39-bb47-8c2e90c488cd' AND t.term_start = DATE '2008-01-01'
     AND t.start_precision = 'month' AND t.how_started = 'appointed' AND t.term_end IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % Delgado term(s) with the expected start', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = '906b55ef-4cef-472c-b619-605a970dda18' AND p.is_active AND NOT p.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(p.notes) n WHERE n LIKE 'CA_0187 (2026-09-23)%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Juan Carlos Dominguez not cleared with the note'; END IF;

  -- the class this clean-up set out to empty
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.is_active AND p.is_incumbent AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % active incumbent row(s) still hold no seat', v_n; END IF;
  RAISE NOTICE 'CA_0187 applied: Delgado seated, Juan Carlos Dominguez cleared; 0 active incumbents without a seat';
END $$;

COMMIT;
