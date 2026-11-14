-- 1952_sahuarita_nov9_2026_council_reconcile.sql
-- ============================================================================
-- Sahuarita AZ Town Council — the 2026-11-09 reconcile, applied 5 days late.
--
-- Supersedes the staged draft at
--   backend/data/seed-sahuarita-2026-nov9/DRAFT-nov9-reconcile.sql  (PR #527)
-- which was written 2026-09-17. THREE of its assumptions turned out to be
-- wrong; each correction is marked ⚠ CORRECTION below. The draft's research —
-- canvass totals, id map, the Hundal name trap, the inclusive-bounds trap — all
-- held and is reused.
-- ============================================================================
--
-- WHAT HAPPENED
-- All three seats up in 2026 were decided outright at the 2026-07-21 primary
-- (STC § 2.05.050 / ARS 9-821.01: a primary majority is "declared elected ...
-- and no further election shall be held"), so there was no November contest.
-- Certified Pima County canvass: Morales 3,885 / Murphy 3,837 / Hundal 3,397 /
-- Cubillo 2,970 / Earl 2,583; all four columns tie to 16,722.
--
-- Oath taken 2026-11-09 per STC § 2.05.080 — "if all council members were
-- elected at the primary election, then at the first council meeting following
-- the date of the general election". Green Valley News, 2026-11-12, photo
-- caption: "Chelsea Hundal, left, Deborah Morales and Tom Murphy are sworn in
-- Nov. 9 by Town Magistrate Maria Avilez."
--
-- Kara Egbert did not seek re-election to the council (she ran for justice of
-- the peace and lost that primary to the incumbent) and LEFT THE BODY on
-- 2026-11-09. Murphy and Morales continue in the seats they already hold.
--
-- ⚠ CORRECTION 1 — THE DESIGNATION VOTE HAS NOT HAPPENED AND IS NOT DUE YET.
-- The draft assumed Mayor/Vice Mayor would be designated at the same Nov-9
-- meeting and left a "Part B" to fill from the minutes. It will not be.
-- STC § 2.10.010: "At the first meeting after the canvass of the general
-- election, OR IF ALL COUNCIL MEMBERS WERE ELECTED AT THE PRIMARY ELECTION THEN
-- AT THE SECOND MEETING FOLLOWING THE DATE OF THE GENERAL ELECTION ... the
-- council members shall choose a mayor from among their number". § 2.10.020
-- puts the vice mayor immediately after. Green Valley News confirms the date:
-- the council "will select the next mayor and vice mayor during the Dec. 14
-- meeting". So the oath is at meeting 1 and the designation at meeting 2.
-- ▶ A SECOND MIGRATION IS OWED AFTER 2026-12-14. This one must not guess it.
--
-- Murphy therefore remains Mayor in the meantime — STC § 2.10.030: the mayor
-- and vice mayor "shall serve at the pleasure of the council UNTIL THE
-- SELECTION of a mayor and vice mayor ... following the next regularly
-- scheduled council member election". Green Valley News still styles him
-- "Mayor Tom Murphy" on 2026-11-12. His row is not touched.
--
-- ⚠ CORRECTION 2 — THERE IS NO VICE MAYOR BETWEEN 2026-11-09 AND 2026-12-14.
-- Egbert held the seat whose title carries the designation. She is gone and her
-- successor in the designation is not chosen until Dec 14, so for these five
-- weeks the office exists but the designation does not. Our model (mig 1863)
-- encodes a designation IN THE OFFICE TITLE, so the honest representation is to
-- drop the suffix from that row and restore it to whichever row the new vice
-- mayor occupies on Dec 14.
--   • Seating Hundal under the title "Council Member (Vice Mayor)" would
--     publish a false fact about a real person for five weeks. Not acceptable.
--   • Leaving the row vacant and seating Hundal nowhere would publish a
--     six-member council when seven people hold office. Also false.
-- There is no precedent row to copy: all 8 designated seats across the DB are
-- currently filled, so this is the first vacant designation we have modelled.
--
-- ⚠ CORRECTION 3 — `politicians.is_incumbent` NO LONGER EXISTS (dropped by
-- CA_0378). The draft set it in three places; all three are removed. The term
-- DATE is now the whole of the occupancy test.
--
-- ⚠ "Diane" Priolo is correct — the 2024 Pima canvass ballot name is
-- PRIOLO, DIANE. The town's own council page shows "Diana" in its header and
-- "Diane" in her biography. We are right; do not "fix" ours to match theirs.
--
-- PROD STATE RE-VERIFIED 2026-11-14 (not trusted from the draft):
--   chamber Sahuarita Town Council = b8721569-4bda-4289-af47-0451879ad0ec
--   office                       office_id                             occupant          ext_id
--   Council Member (Mayor)       fdc06a34-27a6-4260-8a00-be5f7b5139ad  Tom Murphy        -4014001
--   Council Member (Vice Mayor)  f51db53e-ad1e-4659-8192-a301ee519e55  Kara Egbert       -4014002
--   Council Member               19bcd89d-1386-4e0f-854b-65208b5fe3c5  Deborah Morales   -4014003
--   Council Member               b84fc740-1ebe-4625-8709-2aad4f3c824f  Steven Gillespie  -4014004
--   Council Member               10e78a80-bac8-4991-87fd-002651ae7e73  Diane Priolo      -4014005
--   Council Member               65d04184-c9cd-4431-9709-45ce0096de34  Kim Lisk          -4014006
--   Council Member               9bc231e4-d24a-4796-a32d-af63f6da88e3  Edgar Lytle       -4014007
--   -4014008 confirmed FREE 2026-11-14.
--   Egbert's term row = b1b88ff1-c61b-4197-a5f8-658c03a26ff5
--
-- NOT IN SCOPE: all 7 rows are undated backfill (`term_start`/`term_end` NULL,
-- source "ADR 0002 phase 2, migration 1459"), so the five continuing members
-- pass the occupancy gate vacuously. Dating them is a separate question that
-- affects every 1459-backfilled town, not something to settle inside one
-- town's reconcile. Murphy's and Morales's new four-year terms are left undated
-- for the same reason.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- GUARD 0: never run before the oath date.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF CURRENT_DATE < DATE '2026-11-09' THEN
    RAISE EXCEPTION
      'migration 1952: ran % day(s) EARLY. Egbert is still the sitting Vice Mayor '
      'and Hundal has not been sworn in.', DATE '2026-11-09' - CURRENT_DATE;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- GUARD 1: Chelsea Hundal must not already exist, and her id must be free.
-- 🔴 DO NOT write this as full_name ILIKE '%hundal%'. That matches
-- 'HUNDAL FOR MAYOR 2014' (76c95733-b9b7-4b58-9d87-396f0d8687d7), a CALIFORNIA
-- campaign-finance committee with empty first_name and no office — one of the
-- ~77k committee rows in essentials.politicians. Match the person form.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE first_name = 'Chelsea' AND last_name = 'Hundal';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1952: Chelsea Hundal already present (% row(s)) — has this already run?', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.politicians WHERE external_id = -4014008;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1952: external_id -4014008 is taken; pick the next free id in the -40140xx band';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- GUARD 2: the body is the shape this migration was written against.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; who text; t text;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Sahuarita Town Council';
  IF n <> 7 THEN
    RAISE EXCEPTION 'migration 1952: expected 7 Sahuarita seats, found %', n;
  END IF;

  SELECT o.title INTO t FROM essentials.offices o
   WHERE o.id = 'f51db53e-ad1e-4659-8192-a301ee519e55';
  IF t IS DISTINCT FROM 'Council Member (Vice Mayor)' THEN
    RAISE EXCEPTION 'migration 1952: expected the Vice Mayor title on f51db53e, found % — state has moved', coalesce(t, '<missing>');
  END IF;

  SELECT p.full_name INTO who
    FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE ot.office_id = 'f51db53e-ad1e-4659-8192-a301ee519e55' AND ot.term_end IS NULL;
  IF who IS DISTINCT FROM 'Kara Egbert' THEN
    RAISE EXCEPTION 'migration 1952: expected Kara Egbert in the Vice Mayor seat, found % — state has moved', coalesce(who, '<vacant>');
  END IF;

  SELECT p.full_name INTO who
    FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE ot.office_id = 'fdc06a34-27a6-4260-8a00-be5f7b5139ad' AND ot.term_end IS NULL;
  IF who IS DISTINCT FROM 'Tom Murphy' THEN
    RAISE EXCEPTION 'migration 1952: expected Tom Murphy still in the Mayor seat, found %', coalesce(who, '<vacant>');
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Chelsea Hundal's PERSON row, created before the plan table so the gate
--    below can name her. This writes essentials.politicians only — no
--    office_terms row is written until step 3, after the snapshot.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
VALUES (gen_random_uuid(), -4014008, 'Chelsea Hundal', 'Chelsea', 'Hundal', true);

CREATE TEMP TABLE sahuarita_plan ON COMMIT DROP AS
SELECT id AS politician_id FROM essentials.politicians
 WHERE id = '071e2a28-2fef-489a-97e3-15fb5caaee51'   -- Kara Egbert, term closed below
    OR external_id = -4014008;                        -- Chelsea Hundal, term opened below

-- ---------------------------------------------------------------------------
-- INCUMBENCY DELTA GATE — block A (template: _templates/office_terms_incumbency_guard.sql)
-- @incumbency-decision: gated — closes Egbert's Sahuarita term at 2026-11-08 and opens Hundal's at 2026-11-09
--
-- Scoped to BOTH sides of the seating, per the template: the arriving member and
-- the predecessor whose term this closes.
-- ⚠ `expected` and the three WHERE clauses are character-identical to
-- reconcile-incumbency.mjs computeIncumbencyDrift. Do not simplify the
-- multi-seat rule away — Sahuarita's council race is seats = 3, so it applies.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM sahuarita_plan);

-- ---------------------------------------------------------------------------
-- 1. Kara Egbert leaves the council.
--    ⚠ office_terms_no_overlap is an EXCLUSION constraint over
--    daterange(term_start, term_end, '[]') — INCLUSIVE on both ends — and the
--    existing row is (NULL, NULL), i.e. unbounded, which overlaps everything.
--    So her row MUST be closed at 11-08 before Hundal's opens at 11-09.
--    'retired' not 'defeated': she was not beaten for this seat, she declined
--    to seek it. (She was beaten for justice of the peace, a different office
--    we do not carry.)
-- ---------------------------------------------------------------------------
UPDATE essentials.office_terms
   SET term_end = DATE '2026-11-08',
       how_ended = 'retired'
 WHERE id = 'b1b88ff1-c61b-4197-a5f8-658c03a26ff5';

-- ---------------------------------------------------------------------------
-- 2. The Vice Mayor designation lapses until 2026-12-14 (CORRECTION 2).
--    The seat continues; only the designation is in abeyance.
-- ---------------------------------------------------------------------------
UPDATE essentials.offices
   SET title = 'Council Member'
 WHERE id = 'f51db53e-ad1e-4659-8192-a301ee519e55';

-- ---------------------------------------------------------------------------
-- 3. Chelsea Hundal takes the seat, elected at the 2026-07-21 primary and sworn
--    2026-11-09. (Her person row was created in step 0, before the snapshot.)
-- ---------------------------------------------------------------------------
INSERT INTO essentials.office_terms
       (id, office_id, politician_id, term_start, start_precision, how_started, source)
SELECT gen_random_uuid(),
       'f51db53e-ad1e-4659-8192-a301ee519e55',
       p.id,
       DATE '2026-11-09',
       'day',
       'elected',
       'https://www.gvnews.com/news/local/egbert-exits-council-hundal-sworn-in/article_ec7f56e9-aeeb-4b5a-84eb-88ee53a86d5b.html'
  FROM essentials.politicians p
 WHERE p.external_id = -4014008;

-- ---------------------------------------------------------------------------
-- INCUMBENCY DELTA GATE — block B. Fires only on a race row that AGREED with
-- office_terms before this migration and DISAGREES after it.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_planned int; v_scoped int; v_people int; v_created int; v_repaired int; v_detail text;
BEGIN
  SELECT count(*) INTO v_planned FROM sahuarita_plan;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;

  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id, b.politician_id, a.stored, a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(p.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;

  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- POST-FLIGHT
-- ⚠ CORRECTION 1 shows up here: the draft asserted "exactly 1 Mayor + 1 Vice
-- Mayor seated". That assertion would FAIL today and would have been wrong to
-- satisfy — there is deliberately no Vice Mayor until Dec 14.
-- ---------------------------------------------------------------------------
DO $$
DECLARE seated int; mayors int; vices int; n int;
BEGIN
  SELECT count(*) INTO seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.current_office_holders coh ON coh.office_id = o.id
   WHERE c.name_formal = 'Sahuarita Town Council';
  IF seated <> 7 THEN
    RAISE EXCEPTION 'migration 1952: expected 7 seated members, found %', seated;
  END IF;

  SELECT count(*) INTO mayors
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Sahuarita Town Council' AND o.title = 'Council Member (Mayor)';
  IF mayors <> 1 THEN
    RAISE EXCEPTION 'migration 1952: expected exactly 1 Mayor seat, found %', mayors;
  END IF;

  SELECT count(*) INTO vices
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Sahuarita Town Council' AND o.title = 'Council Member (Vice Mayor)';
  IF vices <> 0 THEN
    RAISE EXCEPTION 'migration 1952: expected NO Vice Mayor seat until the 2026-12-14 designation, found %', vices;
  END IF;

  -- Egbert out of occupancy
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.current_office_holders coh ON coh.office_id = o.id
   WHERE c.name_formal = 'Sahuarita Town Council'
     AND coh.politician_id = '071e2a28-2fef-489a-97e3-15fb5caaee51';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1952: Kara Egbert is still seated';
  END IF;

  -- Hundal in, exactly once
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.current_office_holders coh ON coh.office_id = o.id
    JOIN essentials.politicians p ON p.id = coh.politician_id
   WHERE c.name_formal = 'Sahuarita Town Council'
     AND p.first_name = 'Chelsea' AND p.last_name = 'Hundal';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1952: expected Chelsea Hundal seated exactly once, found %', n;
  END IF;

  -- nobody holds two seats
  SELECT count(*) INTO n FROM (
    SELECT coh.politician_id
      FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.current_office_holders coh ON coh.office_id = o.id
     WHERE c.name_formal = 'Sahuarita Town Council'
     GROUP BY coh.politician_id HAVING count(*) > 1) d;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1952: % person(s) hold more than one Sahuarita seat', n;
  END IF;
END $$;

COMMIT;
