BEGIN;

-- =============================================================================
-- CA_0294: Aisha Wahab moved from the California State Senate (SD10) to the U.S. House (CA-14)
-- =============================================================================
-- Found by the term-date roster pilot (CA_0293): CA SD10 is on no official Senate roster and has no
-- current OpenStates holder, but our data still seated Wahab there — and showed CA-14 vacant with no
-- holder.
--
-- Facts and sources (read 2026-09-25):
--   * House Clerk, Vacancies of the 119th Congress (clerk.house.gov/Members/ViewVacancies), CA-14:
--     "Rep. Eric Swalwell — Resigned April 14, 2026"; successor "Rep. Aisha Wahab", "Succeeded August 18,
--     2026", "Oath of Office on September 02, 2026".
--   * House directory (house.gov/representatives), California: "14th | Wahab, Aisha | D".
--   * California Senate roster (senate.ca.gov/senators, saved in backend/data/term-dates/official/
--     CA-upper.json): 39 senators; District 10 absent.
--   * Press (Local News Matters 2026-09-04; Danville San Ramon 2026-09-08): the SD10 seat stays empty
--     until after the November general election; no special election.
--   * Her last day as a state senator is 2026-09-01 (secondary: Wikipedia), consistent with taking the
--     House oath — an incompatible office — on 2026-09-02. So SD10's first vacant day is 2026-09-02.
--
-- Writes:
--   1. Her SD10 tenure gets its real start: 2022-12-05, the first Monday in December after the 2022
--      election (CA Const. art. IV §2(a)); precision 'day'. It was NULL/'unknown' (ADR 0002 backfill).
--   2. vacate_office(SD10, 2026-09-02, 'resigned'): closes her term 2026-09-01, sets is_vacant and
--      vacant_since.
--   3. seat_officeholder(CA-14, Wahab, 2026-09-02, how_started 'elected'): a special election. CA-14 has
--      no prior term row, so nothing is closed. seat_officeholder does NOT clear the vacancy flag, so
--      is_vacant/vacant_since are cleared here explicitly (CLAUDE.md "The is_vacant trap").
--   politicians.is_incumbent stays true: she holds a seat.
--
-- Not done here: Swalwell's historical CA-14 term (absent from office_terms); her November 2026 CA-14
-- candidacy is already in race_candidates and is unaffected.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms WHERE id = 'b555d6a9-fc7b-412d-9f8d-a862174a448e'
                   AND office_id = '402781ee-b5df-472f-b67c-485c07c4782f'
                   AND politician_id = 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70')
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms WHERE office_id = '4cb713ee-8764-41b7-828b-19d42abefaaf'
                   AND politician_id = 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70' AND term_start = DATE '2026-09-02') THEN
    RAISE EXCEPTION 'CA_0294: pre-flight — Wahab''s SD10 term b555d6a9 is not where expected';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_terms WHERE office_id = '4cb713ee-8764-41b7-828b-19d42abefaaf'
               AND politician_id IS DISTINCT FROM 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70') THEN
    RAISE EXCEPTION 'CA_0294: pre-flight — CA-14 already has a term for someone else; reconcile first';
  END IF;
END $$;

-- 1. Date the SD10 tenure (only while still unknown — idempotent).
UPDATE essentials.office_terms
   SET term_start = DATE '2022-12-05', start_precision = 'day', how_started = COALESCE(how_started, 'elected'),
       source = source || ' | term_start 2022-12-05 = first Monday in December after the 2022 general election (CA Const. art. IV §2(a)) (CA_0294)'
 WHERE id = 'b555d6a9-fc7b-412d-9f8d-a862174a448e' AND term_start IS NULL AND start_precision = 'unknown';

-- 2. SD10 vacant from 2026-09-02 (her term closes 2026-09-01).
SELECT essentials.vacate_office('402781ee-b5df-472f-b67c-485c07c4782f'::uuid, DATE '2026-09-02',
  'Wahab took the U.S. House oath for CA-14 on 2026-09-02 (House Clerk, Vacancies of the 119th Congress); SD10 absent from senate.ca.gov/senators 2026-09-25 (CA_0294)',
  'resigned');

-- 3. Seat her in CA-14 from 2026-09-02 and clear the vacancy flag.
SELECT essentials.seat_officeholder('4cb713ee-8764-41b7-828b-19d42abefaaf'::uuid, 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70'::uuid,
  DATE '2026-09-02',
  'House Clerk, Vacancies of the 119th Congress: CA-14 succeeded 2026-08-18, oath of office 2026-09-02; house.gov/representatives lists "14th | Wahab, Aisha" (CA_0294)',
  'elected', 'day');
UPDATE essentials.offices SET is_vacant = false, vacant_since = NULL
 WHERE id = '4cb713ee-8764-41b7-828b-19d42abefaaf' AND is_vacant;

DO $$
DECLARE v int;
BEGIN
  -- SD10: her term dated and closed; seat vacant from 2026-09-02; no current holder.
  SELECT count(*) INTO v FROM essentials.office_terms
   WHERE id = 'b555d6a9-fc7b-412d-9f8d-a862174a448e' AND term_start = DATE '2022-12-05' AND start_precision = 'day'
     AND term_end = DATE '2026-09-01' AND how_ended = 'resigned';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0294: SD10 term not dated/closed as expected'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.offices WHERE id = '402781ee-b5df-472f-b67c-485c07c4782f'
                   AND is_vacant AND vacant_since::date = DATE '2026-09-02') THEN
    RAISE EXCEPTION 'CA_0294: SD10 not flagged vacant from 2026-09-02';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder WHERE office_id = '402781ee-b5df-472f-b67c-485c07c4782f') THEN
    RAISE EXCEPTION 'CA_0294: SD10 still has a current holder';
  END IF;
  -- CA-14: Wahab is the one current holder, from 2026-09-02; not flagged vacant.
  SELECT count(*) INTO v FROM essentials.office_current_holder
   WHERE office_id = '4cb713ee-8764-41b7-828b-19d42abefaaf' AND politician_id = 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0294: Wahab is not the current CA-14 holder (found %)', v; END IF;
  IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = '4cb713ee-8764-41b7-828b-19d42abefaaf' AND is_vacant) THEN
    RAISE EXCEPTION 'CA_0294: CA-14 still flagged vacant';
  END IF;
  -- She holds exactly one current seat, and stays an incumbent.
  SELECT count(*) INTO v FROM essentials.office_current_holder WHERE politician_id = 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0294: Wahab holds % current seats, expected 1', v; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70' AND is_incumbent) THEN
    RAISE EXCEPTION 'CA_0294: Wahab is_incumbent is not true';
  END IF;
END $$;

COMMIT;
