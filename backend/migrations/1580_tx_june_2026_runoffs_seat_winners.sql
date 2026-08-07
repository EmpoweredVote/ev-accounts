-- 1580_tx_june_2026_runoffs_seat_winners.sql
--
-- Record the outcomes of the two 2026-06-13 Texas municipal runoffs and repair the occupancy flags
-- they left behind.
--
--   Rollback: see the ROLLBACK block at the foot of this file.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1580_tx_june_2026_runoffs_seat_winners.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE BUG THIS FOUND: A WINNER IN HIS SEAT WITH THE FLAG STILL OFF
-- ---------------------------------------------------------------------------------------------------
-- Both offices already pointed at the right person — someone linked the winners after the runoffs.
-- But Longview District 3 looked like this:
--
--     Brandon Smith · Council Member District 3 · Longview · is_incumbent = FALSE
--
-- Occupancy in this schema is a TWO-GATE model (`term_end` AND `is_incumbent`). Smith passes the date
-- gate — his term row has no end — and fails the flag gate. Depending on which gate a query applies,
-- Longview's District 3 councilman is either present or missing. This is the same shape as the
-- Wisconsin Supreme Court handoff in migration 1571 and the Beverly Hills/Mirisch case before it: the
-- person got linked, the flag never got flipped.
--
-- 🔑 GENERALISABLE: linking a winner to an office is TWO writes, and the second one is silent when
-- you forget it. Nothing errors, nothing looks empty in the admin — the row is simply invisible to
-- half the queries that ask who holds the seat. Princeton's row got both writes; Longview's got one.
--
-- ---------------------------------------------------------------------------------------------------
-- RESULTS (fetched 2026-08-07)
-- ---------------------------------------------------------------------------------------------------
--   Longview City Council District 3 runoff, 2026-06-13
--     Brandon Smith .... 223 votes (52.22%)  WON
--     Marlena Cooper ... 204 votes (47.78%)  LOST
--     — Longview News-Journal, "Brandon Smith wins District 3 seat on Longview City Council",
--       2026-06-13. Reports he "can be sworn into office during the June 25 council meeting" once
--       the city holds a special canvassing meeting.
--     — CONFIRMED SEATED: the City of Longview's own council roster page
--       (longviewtexas.gov/2204/District-3---Brandon-Smith) states "Elected: June 2026,
--       Current Term Expires: May 2029". A news report of a win is a claim about an election; the
--       city listing him as its District 3 member is the fact that he holds the seat.
--
--   Princeton City Council Place 4 runoff, 2026-06-13
--     Jaisen Rutledge .. 293 votes (54.46%)  WON
--     Jan Goria ........ 245 votes (45.54%)  LOST   (538 votes cast)
--     — Princeton Herald, "City council runoff results FINAL", 2026-06-13, which notes results are
--       "unofficial until canvassed by the Princeton City Council, expected to be at the Monday,
--       June 22, council meeting".
-- ---------------------------------------------------------------------------------------------------

-- Longview District 3 — outcomes.
UPDATE essentials.race_candidates
   SET result = 'won', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'Longview News-Journal, "Brandon Smith wins District 3 seat on Longview City '
                    || 'Council", 2026-06-13: Smith 223 votes (52.22%) def. Marlena Cooper 204 '
                    || '(47.78%). Seat confirmed by the City of Longview council roster '
                    || '(longviewtexas.gov/2204/District-3---Brandon-Smith): "Elected: June 2026, '
                    || 'Current Term Expires: May 2029". (fetched 2026-08-07)'
 WHERE race_id = '038238c7-7eac-4680-86ff-baaf46bfd6ed' AND full_name = 'Brandon Smith';

UPDATE essentials.race_candidates
   SET result = 'lost', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'Longview News-Journal, "Brandon Smith wins District 3 seat on Longview City '
                    || 'Council", 2026-06-13: Cooper 204 votes (47.78%) to Smith''s 223 (52.22%) in '
                    || 'the 2026-06-13 runoff. (fetched 2026-08-07)'
 WHERE race_id = '038238c7-7eac-4680-86ff-baaf46bfd6ed' AND full_name = 'Marlena Cooper';

-- Princeton Place 4 — outcomes.
UPDATE essentials.race_candidates
   SET result = 'won', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'Princeton Herald, "City council runoff results FINAL", 2026-06-13: Rutledge '
                    || '293 votes (54.46%) def. Jan Goria 245 (45.54%), 538 cast; canvass expected '
                    || 'at the 2026-06-22 council meeting. (fetched 2026-08-07)'
 WHERE race_id = 'f2595388-ec6a-442c-afd9-ad42aa61a17c' AND full_name = 'Jaisen Rutledge';

UPDATE essentials.race_candidates
   SET result = 'lost', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'Princeton Herald, "City council runoff results FINAL", 2026-06-13: Goria 245 '
                    || 'votes (45.54%) to Rutledge''s 293 (54.46%). (fetched 2026-08-07)'
 WHERE race_id = 'f2595388-ec6a-442c-afd9-ad42aa61a17c' AND full_name = 'Jan Goria';

-- ---------------------------------------------------------------------------------------------------
-- Close the occupancy gate on Longview District 3.
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.politicians
   SET is_incumbent = true
 WHERE id = 'c6ec603a-3ba9-478b-a43d-35ef9bb5b0f0'   -- Brandon Smith
   AND is_incumbent IS DISTINCT FROM true;

-- Give the backfilled term row its dates and provenance. Migration 1459 created it from
-- `offices.politician_id` with every field but the link left NULL.
--
-- ⚠️ PRECISION IS DELIBERATE. `term_start` is recorded at DAY precision from the News-Journal's
-- reported swearing-in meeting (2026-06-25). `term_end` comes from the city's own "Current Term
-- Expires: May 2029", which is a MONTH — there is no end_precision column, so it is stored as the
-- last day of that month and the imprecision is stated here and in `source` rather than implied
-- by a date that looks more exact than the source was.
UPDATE essentials.office_terms
   SET term_start      = '2026-06-25',
       start_precision = 'day',
       term_end        = '2029-05-31',
       how_started     = 'elected',
       source = 'Won the 2026-06-13 Longview City Council District 3 runoff (Longview News-Journal, '
             || '2026-06-13: 223 votes / 52.22% def. Marlena Cooper 204 / 47.78%). term_start is the '
             || '2026-06-25 council meeting the News-Journal reported as his swearing-in, after the '
             || 'special canvassing meeting. term_end is the last day of "May 2029", the month the '
             || 'City of Longview roster gives as "Current Term Expires" '
             || '(longviewtexas.gov/2204/District-3---Brandon-Smith) — MONTH precision stored as a '
             || 'day. Recorded by migration 1580, 2026-08-07.'
 WHERE office_id = 'b3085207-009b-4e57-9d58-d820dcde3e61'
   AND politician_id = 'c6ec603a-3ba9-478b-a43d-35ef9bb5b0f0';

-- Princeton Place 4 — Rutledge's flags were already correct; record only how the term started.
-- Term dates are deliberately NOT set: Place 4 was filled at a SPECIAL election (KERA, 2026-05-02,
-- "Princeton likely headed for a runoff for special city council election"), so the term runs to the
-- end of the seat's original cycle, and no source read tonight states that date. A guessed term_end
-- is worse than a NULL one — NULL reads as "unknown", a wrong date reads as known.
UPDATE essentials.office_terms
   SET how_started = 'elected',
       source = 'Won the 2026-06-13 Princeton City Council Place 4 SPECIAL-election runoff (Princeton '
             || 'Herald, 2026-06-13: 293 votes / 54.46% def. Jan Goria 245 / 45.54%, 538 cast). Term '
             || 'dates left NULL — the seat was filled at a special election and no source read '
             || 'states the term''s end. Recorded by migration 1580, 2026-08-07.'
 WHERE office_id = '327a50dd-e40f-4892-a3c2-208b1cc0d9b9'
   AND politician_id = '53f97990-822e-46de-8e18-f09e5a160c2b';

-- ---------------------------------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------------------------------
--   UPDATE essentials.race_candidates SET result=NULL, result_source=NULL, result_recorded_at=NULL
--    WHERE race_id IN ('038238c7-7eac-4680-86ff-baaf46bfd6ed','f2595388-ec6a-442c-afd9-ad42aa61a17c');
--   UPDATE essentials.politicians SET is_incumbent=false
--    WHERE id='c6ec603a-3ba9-478b-a43d-35ef9bb5b0f0';
--   UPDATE essentials.office_terms
--      SET term_start=NULL, start_precision='unknown', term_end=NULL, how_started=NULL,
--          source='backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'
--    WHERE office_id IN ('b3085207-009b-4e57-9d58-d820dcde3e61','327a50dd-e40f-4892-a3c2-208b1cc0d9b9');
