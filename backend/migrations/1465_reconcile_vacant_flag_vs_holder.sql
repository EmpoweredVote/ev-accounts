-- 1465_reconcile_vacant_flag_vs_holder.sql
-- Reconcile the five offices where essentials.offices.is_vacant = true contradicted a CURRENT term
-- in essentials.office_terms. Idempotent. Requires 1458 + 1459 + 1462 + 1463.
--
-- THE CONTRADICTION. These five rows claimed both "this seat is empty" and "this person holds it":
--
--   SELECT o.id, o.title, o.representing_city, o.representing_state, p.full_name
--     FROM essentials.offices o
--     JOIN essentials.office_current_holder och ON och.office_id = o.id
--     JOIN essentials.politicians p ON p.id = och.politician_id
--    WHERE o.is_vacant = true;
--
--   Council Member Place 6           | Plano | TX | John B. Muns
--   School Committee Member (Ward 5) |       | ME | VACANT - Ward 5
--   Board Member (District 5)        |       | ME | VACANT - District 5
--   Delegate (MD 42A)                |       | MD | Vacant
--   Delegate (VA HD-20)              |       | VA | Vacant
--
-- PRE-EXISTING, NOT CAUSED BY ADR 0002. Every one of the five office_terms rows came from the 1459
--   backfill, i.e. they are copies of what offices.politician_id already said. Phase 5 only made
--   the disagreement visible by giving occupancy its own table to disagree from.
--
-- FOUR OF THE FIVE "HOLDERS" ARE NOT PEOPLE. They are placeholder politician rows literally named
--   'Vacant' / 'VACANT - Ward 5' / 'VACANT - District 5', with negative synthetic external_ids and
--   politicians.is_vacant = true, created by seed migrations 265 (Maine school boards), 274 (MD
--   delegates) and 319 (VA delegates). Before ADR 0002 a vacancy had nowhere else to live: occupancy
--   was one non-temporal column, so "empty" was spelled either NULL or a fake occupant. Those four
--   seats therefore encode the same fact twice, once correctly (offices.is_vacant) and once as a
--   phantom person — and in two cases the phantom is now simply out of date.
--
-- WHY THE PLACEHOLDER TERMS ARE DELETED RATHER THAN CLOSED WITH vacate_office(). Closing a term
--   writes term_end + how_ended, i.e. it asserts that somebody's tenure ENDED on a date. Applied to
--   a placeholder that would read "the person named 'VACANT - Ward 5' resigned on 2026-06-30" —
--   false history, permanently, in the table that is now the system of record. A placeholder never
--   held the seat, so there is no span to end. essentials.vacate_office() remains the right tool
--   whenever a REAL predecessor is stepping down; it is deliberately not used here.
--
--   Order matters when re-seating: an open-ended term is daterange(NULL, NULL, '[]') = (-inf, inf),
--   which overlaps every other span, so office_terms_no_overlap rejects the pair. The placeholder's
--   row must be deleted before the successor's row is inserted, not after.
--
-- CAMPAIGN-FINANCE FOLLOW-UP. backend/src/lib/campaignFinanceSearchService.ts and
--   campaignFinanceService.ts both carry a comment saying "5 offices in prod carry a current term
--   while still flagged is_vacant (e.g. John B. Muns ...)". After this migration that count is 0 and
--   those comments are stale. The derived-table join shape they explain SHOULD STAY: is_vacant has
--   to constrain the match rather than a downstream join, or a held-but-flagged-vacant office emits
--   a spurious all-NULL office row for its holder. That is the more correct form whether or not any
--   such office exists today, and it stops this class of data drift becoming a rendering bug again.
--
-- Research date: 2026-07-26. Every verdict below is sourced; no date is inferred from a party, a
--   term length or a neighbouring row.

BEGIN;

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- A. Plano, TX "Council Member Place 6" (02e9e43b) — HELD, and the row itself is the error.
--
-- Plano numbers the MAYOR as Place 6. There is no separate Place-6 councilmember: the body is a
-- mayor plus seven councillors occupying Places 1-8, with Place 6 being the mayoralty.
--   * Wikipedia "Plano City Council" member table: Place 6 = John B. Muns, "Place 6 is always the
--     mayor", first elected 2021.
--   * Wikipedia "2025 Plano municipal elections": the 2026-05-03 mayoral contest ran ON THE BALLOT
--     as Place 6; Muns unopposed, 14,603 votes, 100%. Matches politicians.valid_from/valid_to
--     2025-05-01 / 2029-05-01 already on his row.
--   * plano.gov "Mayor and City Council" (fetched 2026-07-26): Mayor Muns plus exactly SEVEN
--     councillors — Tu, Kehr, Horne, Downs, Lavine, Thomas, Quintanilla — which is precisely this
--     DB's Places 1-5, 7 and 8. Nobody is missing; Place 6 is the mayor's seat, double-modelled.
--
-- Migration 1413 (2026-07-24) established the same finding and, per operator decision, ALIASED the
-- phantom to Muns rather than removing it, leaving both signals set at once. Neither signal is wrong
-- about Muns; the duplicate office row is the defect. Operator decision 2026-07-26: remove it.
--
-- Why not simply clear is_vacant, which is the smaller edit: essentialsBodiesService.ts filters
-- rosters on o.is_vacant = false, so an un-flagged Place 6 puts Muns on the Plano City Council
-- roster TWICE and takes member_count from 8 to 9. The flag was load-bearing precisely because the
-- row is a phantom.
--
-- Safe to delete: 0 essentials.races reference it (verified against prod), its single office_terms
-- row goes with it via ON DELETE CASCADE, and no politician's office_id points at it — Muns's
-- office_id is the Mayor office 525cf2ee-0948-45a3-be43-76f888b1d5af, which is untouched and keeps
-- its own current term. This supersedes 1413; re-running 1413 afterwards is a no-op because its
-- UPDATE targets an id that no longer exists.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE n_races int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.offices WHERE id = '02e9e43b-7f65-4443-812b-4b4eb303e40f') THEN
    RAISE NOTICE 'Plano Place 6 phantom already removed — skipping.';
    RETURN;
  END IF;

  -- refuse to delete a seat that any race points at: that would be a real seat, not a phantom
  SELECT count(*) INTO n_races FROM essentials.races
   WHERE office_id = '02e9e43b-7f65-4443-812b-4b4eb303e40f';
  IF n_races <> 0 THEN
    RAISE EXCEPTION 'REFUSING to delete Plano Place 6: % race(s) reference it', n_races;
  END IF;

  -- and refuse unless the Mayor office it duplicates is present and held by Muns
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_current_holder och
     WHERE och.office_id     = '525cf2ee-0948-45a3-be43-76f888b1d5af'
       AND och.politician_id = '5584e869-4a54-4a68-a3c8-c14db45a71c5'
  ) THEN
    RAISE EXCEPTION 'REFUSING to delete Plano Place 6: the Mayor office it duplicates is not currently held by Muns';
  END IF;

  DELETE FROM essentials.offices WHERE id = '02e9e43b-7f65-4443-812b-4b4eb303e40f';
  RAISE NOTICE 'Plano Place 6 phantom removed; Mayor office retains John B. Muns.';
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- B. Lewiston, ME "School Committee Member (Ward 5)" (e4117d9e) — HELD by Lynnea Hawkins.
--
-- Migration 265 (ran 2026-06-03) seeded the placeholder 'VACANT - Ward 5' (external_id -890015) on
-- research that its own header dates to Jan 5 2026: "Ward 5 VACANT (Iman Osman resigned after
-- indictment/residency controversy; unfilled as of Jan 5 2026)" and "appointee not confirmed at
-- implementation time — using is_vacant=true placeholder". The seat had been filled by the time the
-- migration ran, so the placeholder was stale on arrival. The intent was always to replace it.
--
-- Ward 5 is held by Lynnea Hawkins:
--   * Sun Journal, 2026-06-19, "Lewiston municipal election nomination papers available Monday",
--     listing the four school committee seats up in Nov 2026 with their sitting incumbents —
--     Ward 1 Phoenix McLaughlin, Ward 3 Elizabeth Eames, Ward 5 Lynnea Hawkins, Ward 7 Donna
--     Gallant. The other three names match this DB exactly (-890011, -890013, -890017).
--   * Corroborating chronology: Hawkins previously ran for this same Ward 5 seat in 2019 (Sun
--     Journal "Election 2019: Lewiston School Committee Ward 5"); Lewiston fills school-committee
--     vacancies by prompt mayoral appointment, three times documented in 18 months (Osman to Ward 5
--     Dec 2024, Noble to the Ward 5 COUNCIL seat Jan 2026, Levasseur to Ward 7 July 2026), so a
--     six-month vacancy is not the plausible reading.
--
-- TERM START IS NOT KNOWN and is not invented. She was seated by appointment at some point after
-- Osman forfeited the seat on taking the council oath in Jan 2026; no source gives the date. Per
-- ADR 0002 that is recorded as term_start NULL + start_precision 'unknown' — the identical shape
-- the 1459 backfill used for 82,336 rows — rather than guessing a day. essentials.seat_officeholder()
-- is not used here because it (correctly) refuses a NULL term_start.
--
-- how_started = 'appointed': the seat was filled by mayoral appointment under the city charter, not
-- at an election. The office row already carries is_appointed_position = true from 265.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- B1. The real member. -890019 continues Lewiston's -8900xx block (-890011..-890018 are the eight
--     seats seeded by 265, -890015 being the placeholder this replaces).
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed,
   is_vacant, is_incumbent, external_id, data_source)
VALUES (gen_random_uuid(), 'Lynnea Hawkins', 'Lynnea', 'Hawkins', NULL,
        true, true, false, true, -890019, 'sunjournal.com')
ON CONFLICT (external_id) DO NOTHING;

-- B2. Drop the placeholder's backfilled term FIRST — see the header note on (-inf, inf) overlap.
DELETE FROM essentials.office_terms
 WHERE office_id     = 'e4117d9e-d048-4ba2-b13e-c65607fec97f'
   AND politician_id = 'cfd9020c-6769-4386-80ad-877ad1a5d764';   -- 'VACANT - Ward 5'

-- B3. Seat her, with an honestly-unknown start.
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT 'e4117d9e-d048-4ba2-b13e-c65607fec97f', p.id, NULL, NULL, 'unknown', 'appointed',
       'sunjournal.com 2026-06-19 "Lewiston municipal election nomination papers available Monday" '
       '(Ward 5 incumbent); replaces placeholder politician -890015 seeded by migration 265. '
       'Appointment date unknown — term_start deliberately NULL per ADR 0002.'
  FROM essentials.politicians p
 WHERE p.external_id = -890019
   AND NOT EXISTS (
     SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id     = 'e4117d9e-d048-4ba2-b13e-c65607fec97f'
        AND t.politician_id = p.id
   );

-- B4. The seat is not vacant.
UPDATE essentials.offices
   SET is_vacant = false, vacant_since = NULL
 WHERE id = 'e4117d9e-d048-4ba2-b13e-c65607fec97f'
   AND (is_vacant IS DISTINCT FROM false OR vacant_since IS NOT NULL);

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- C/D/E. Three seats that ARE genuinely vacant — drop the phantom holder, keep the flag, record
--        the date we can actually source.
--
-- C. South Portland, ME "Board Member (District 5)" (780ce54e) — VACANT since 2026-04-06.
--      Adrian Dowling held District 5, elected as a write-in in Nov 2024 (Press Herald 2024-10-15,
--      "Write in Adrian Dowling ... for the District 5 South Portland school board"). Press Herald
--      2026-04-07: "South Portland School Board Vice Chair Adrian Dowling resigned effective
--      Monday" — the Monday before that Tuesday publication is 2026-04-06. Ballotpedia's recall
--      page records his status as "Resigned". spsdme.org "Members of the Board" (fetched
--      2026-07-26) lists six of seven members — D1, D2, D3, D4 and two At-Large — with District 5
--      absent, so the seat is still unfilled. Migration 265's own header already said "D5 VACANT
--      (Adrian Dowling resigned April 2026)".
--
-- D. Maryland "Delegate", Legislative Subdistrict 42A (7f8936f1) — VACANT since 2026-06-01.
--      Nino Mangione (R) resigned 2026-06-01 (Maryland State Archives, Maryland Manual, "Maryland
--      House of Delegates, Appointments by Governor": "no appointment yet made to replace Nino
--      Mangione (R), who resigned June 1, 2026"). mgaleg.maryland.gov's House member roster, last
--      updated 2026-07-20, lists District 42A as "To Be Announced ... vacant". The party central
--      committee / governor appointment has not landed.
--
-- E. Virginia "Delegate", House District 20 (43387a09) — VACANT since 2026-05-31.
--      Michelle Lopes Maldonado (D-Manassas) resigned effective 2026-05-31 (Potomac Local
--      2026-05-05; InsideNoVa and WRIC concur). The date is already recorded in this repo, in
--      migration 323's header: "HD-20 (-5120020, Vacant — Maldonado resigned 2026-05-31)".
--      house.vga.virginia.gov/members (fetched 2026-07-26) shows District 20 as "Vacant" with no
--      named delegate; no special election has been held.
--
-- WHY NO NULL-POLITICIAN TERM ROW IS WRITTEN, even though these three dates ARE known. 1459
--   established the shape for a vacancy as offices.is_vacant with no term row, and 1464's
--   vacate_office() records the date on offices.vacant_since rather than as a span. Prod has zero
--   NULL-politician term rows and nothing reads them. A dated vacancy span would be defensible
--   under ADR 0002 — politician_id is nullable exactly for that — but introducing the first three
--   of them as a side effect of a cleanup would fork the representation of "vacant" without a read
--   path asking for it. vacant_since carries the date; the span stays unwritten. These three
--   offices consequently join the 158 already in essentials.offices_missing_terms that are
--   legitimately flagged is_vacant (158 -> 161); the drift-relevant unflagged count stays at 699.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- C/D/E-1. Delete the placeholder-derived terms. No term_end, no how_ended: nobody held these.
DELETE FROM essentials.office_terms
 WHERE (office_id, politician_id) IN (
   ('780ce54e-2af2-4383-af8b-f2e8f968a2dc', '6f9aab95-b05b-4f34-9b6f-5cd22556ac63'),  -- VACANT - District 5
   ('7f8936f1-734a-4f4e-9d48-d73399dba7f1', '67acad60-5839-4a8a-95ac-c881c3ca39a9'),  -- Vacant (MD 42A)
   ('43387a09-85fe-45a9-b2d8-84e0c2fa0971', 'a8996e30-a386-45b5-8157-5d39b56a726f')   -- Vacant (VA HD-20)
 );

-- C/D/E-2. Keep is_vacant = true and stamp the sourced date. COALESCE so a re-run never overwrites
--          a date somebody has since refined by hand.
UPDATE essentials.offices o
   SET is_vacant    = true,
       vacant_since = COALESCE(o.vacant_since, v.since)
  FROM (VALUES
    ('780ce54e-2af2-4383-af8b-f2e8f968a2dc'::uuid, DATE '2026-04-06'),  -- Dowling resigned
    ('7f8936f1-734a-4f4e-9d48-d73399dba7f1'::uuid, DATE '2026-06-01'),  -- Mangione resigned
    ('43387a09-85fe-45a9-b2d8-84e0c2fa0971'::uuid, DATE '2026-05-31')   -- Maldonado resigned
  ) AS v(office_id, since)
 WHERE o.id = v.office_id
   AND (o.is_vacant IS DISTINCT FROM true OR o.vacant_since IS NULL);

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- F. Retire the four placeholder politician rows.
--
-- DETACHED (politicians.office_id -> NULL) so no reciprocal-FK or "half-seated" sweep can reattach
-- them to the seat they were standing in for, and DEACTIVATED (is_active = false) so they cannot
-- surface as people: public.admin_list_politicians filters p.is_active = true, and two of the four
-- ('VACANT - Ward 5', 'VACANT - District 5') were still active.
--
-- NOT DELETED, deliberately. Their negative external_ids are the ON CONFLICT keys their seed
-- migrations re-run against, and migration 323 still asserts a fact about -5120020 by external_id
-- ("HD-20 ... intentionally excluded" from the photo backfill, verified via a COUNT). Deleting the
-- rows would silently break those migrations' idempotency to save four unreferenced rows. They hold
-- no answers and no candidacies (verified: 0 rows in essentials.race_candidates and
-- inform.politician_answers for all four).
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

UPDATE essentials.politicians
   SET office_id = NULL,
       is_active = false
 WHERE external_id IN (-890015, -890035, -2420124, -5120020)
   AND (office_id IS NOT NULL OR is_active IS DISTINCT FROM false);

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- Post-verify gate
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  n_contradictions int; n_sentinel_held int; n_place6 int; n_mayor int;
  n_missing int; n_unflagged int; v_hawkins uuid; r record;
BEGIN
  -- ── THE assertion: the finding query from the header must return nothing ──
  SELECT count(*) INTO n_contradictions
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.is_vacant = true;
  IF n_contradictions <> 0 THEN
    RAISE EXCEPTION 'still % office(s) flagged is_vacant while holding a current term', n_contradictions;
  END IF;

  -- ── no placeholder may hold ANY seat, here or elsewhere ──
  SELECT count(*) INTO n_sentinel_held
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.is_vacant = true OR p.full_name ILIKE '%vacant%';
  IF n_sentinel_held <> 0 THEN
    RAISE EXCEPTION '% office(s) still resolve to a placeholder "vacant" politician', n_sentinel_held;
  END IF;

  IF EXISTS (SELECT 1 FROM essentials.politicians
              WHERE external_id IN (-890015, -890035, -2420124, -5120020)
                AND (office_id IS NOT NULL OR is_active = true)) THEN
    RAISE EXCEPTION 'a placeholder politician is still attached to an office or still active';
  END IF;

  -- ── A. Plano: phantom gone, Mayor intact ──
  SELECT count(*) INTO n_place6 FROM essentials.offices
   WHERE id = '02e9e43b-7f65-4443-812b-4b4eb303e40f';
  IF n_place6 <> 0 THEN RAISE EXCEPTION 'Plano Place 6 phantom office still present'; END IF;

  IF EXISTS (SELECT 1 FROM essentials.office_terms
              WHERE office_id = '02e9e43b-7f65-4443-812b-4b4eb303e40f') THEN
    RAISE EXCEPTION 'orphan office_terms row survived the Place 6 delete — CASCADE did not fire';
  END IF;

  SELECT count(*) INTO n_mayor FROM essentials.office_current_holder
   WHERE office_id = '525cf2ee-0948-45a3-be43-76f888b1d5af'
     AND politician_id = '5584e869-4a54-4a68-a3c8-c14db45a71c5';
  IF n_mayor <> 1 THEN RAISE EXCEPTION 'Plano Mayor office no longer resolves to John B. Muns'; END IF;

  -- Plano's council chamber must now expose exactly 8 seats, each held by a distinct person
  IF (SELECT count(*) FROM essentials.offices
       WHERE chamber_id = (SELECT chamber_id FROM essentials.offices
                            WHERE id = '525cf2ee-0948-45a3-be43-76f888b1d5af')) <> 8 THEN
    RAISE EXCEPTION 'Plano City Council should have 8 seats after removing the Place 6 duplicate';
  END IF;
  IF (SELECT count(DISTINCT och.politician_id) FROM essentials.offices o
        JOIN essentials.office_current_holder och ON och.office_id = o.id
       WHERE o.chamber_id = (SELECT chamber_id FROM essentials.offices
                              WHERE id = '525cf2ee-0948-45a3-be43-76f888b1d5af')
         AND och.politician_id IS NOT NULL) <> 8 THEN
    RAISE EXCEPTION 'Plano City Council no longer has 8 distinct holders — duplicate or lost holder';
  END IF;

  -- ── B. Lewiston Ward 5: held by Hawkins, not flagged vacant, start honestly unknown ──
  SELECT id INTO v_hawkins FROM essentials.politicians WHERE external_id = -890019;
  IF v_hawkins IS NULL THEN RAISE EXCEPTION 'Lynnea Hawkins (-890019) was not created'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_current_holder
     WHERE office_id = 'e4117d9e-d048-4ba2-b13e-c65607fec97f' AND politician_id = v_hawkins
  ) THEN
    RAISE EXCEPTION 'Lewiston Ward 5 does not resolve to Lynnea Hawkins';
  END IF;

  IF (SELECT count(*) FROM essentials.office_terms
       WHERE office_id = 'e4117d9e-d048-4ba2-b13e-c65607fec97f') <> 1 THEN
    RAISE EXCEPTION 'Lewiston Ward 5 should have exactly one term row';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms
     WHERE office_id       = 'e4117d9e-d048-4ba2-b13e-c65607fec97f'
       AND term_start IS NULL AND start_precision = 'unknown' AND how_started = 'appointed'
  ) THEN
    RAISE EXCEPTION 'Lewiston Ward 5 term must keep term_start NULL / precision unknown — no invented date';
  END IF;

  IF (SELECT is_vacant OR vacant_since IS NOT NULL FROM essentials.offices
       WHERE id = 'e4117d9e-d048-4ba2-b13e-c65607fec97f') THEN
    RAISE EXCEPTION 'Lewiston Ward 5 is still flagged vacant';
  END IF;

  -- ── C/D/E. The three real vacancies: flagged, dated, and holding nobody ──
  FOR r IN
    SELECT * FROM (VALUES
      ('780ce54e-2af2-4383-af8b-f2e8f968a2dc'::uuid, DATE '2026-04-06', 'South Portland D5'),
      ('7f8936f1-734a-4f4e-9d48-d73399dba7f1'::uuid, DATE '2026-06-01', 'MD 42A'),
      ('43387a09-85fe-45a9-b2d8-84e0c2fa0971'::uuid, DATE '2026-05-31', 'VA HD-20')
    ) AS t(office_id, since, label)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM essentials.offices
                    WHERE id = r.office_id AND is_vacant = true
                      AND vacant_since::date = r.since) THEN
      RAISE EXCEPTION '% must stay is_vacant = true with vacant_since = %', r.label, r.since;
    END IF;
    IF EXISTS (SELECT 1 FROM essentials.office_terms WHERE office_id = r.office_id) THEN
      RAISE EXCEPTION '% still has an office_terms row', r.label;
    END IF;
    IF (SELECT politician_id FROM essentials.office_current_holder
         WHERE office_id = r.office_id) IS NOT NULL THEN
      RAISE EXCEPTION '% still resolves to a holder', r.label;
    END IF;
  END LOOP;

  -- ── the view must still be exactly one row per office ──
  IF (SELECT count(*) FROM essentials.office_current_holder)
     <> (SELECT count(*) FROM essentials.offices) THEN
    RAISE EXCEPTION 'office_current_holder is no longer one row per office';
  END IF;

  -- ── drift baseline: the three new term-less offices are all FLAGGED, so the number 1464 tells
  --    readers to watch (unflagged) must not move. Guarded: the view is from 1464.
  IF to_regclass('essentials.offices_missing_terms') IS NOT NULL THEN
    SELECT count(*) INTO n_missing   FROM essentials.offices_missing_terms;
    SELECT count(*) INTO n_unflagged FROM essentials.offices_missing_terms
     WHERE is_vacant IS DISTINCT FROM true;
    IF n_unflagged <> 699 THEN
      RAISE EXCEPTION 'unflagged missing-term count moved to % (must stay at the 699 baseline — '
                      'this migration only ever adds is_vacant-flagged offices to that view)', n_unflagged;
    END IF;
    IF n_missing <> 860 THEN
      RAISE NOTICE 'missing-term total is % (expected 860 = 857 baseline + 3 real vacancies)', n_missing;
    END IF;
  ELSE
    RAISE NOTICE 'essentials.offices_missing_terms absent (1464 not applied) — drift check skipped.';
  END IF;

  RAISE NOTICE '1465 verify PASSED: 0 offices flagged vacant while held; 0 placeholder holders anywhere; '
               'Plano Place 6 phantom removed (council at 8 distinct holders); Lewiston Ward 5 seated to '
               'Lynnea Hawkins with an undated term; South Portland D5 / MD 42A / VA HD-20 vacant and dated; '
               'unflagged missing-term drift still %.', COALESCE(n_unflagged::text, 'unchecked');
END $$;

COMMIT;
