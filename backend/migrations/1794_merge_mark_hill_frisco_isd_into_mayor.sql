-- Migration 1794: Mark Hill is ONE person — merge the Frisco ISD row into the Mayor row,
--                 close his Place 5 term, and vacate Frisco ISD Place 5.
--
-- ============================================================================
-- WHY THIS EXISTS
-- ============================================================================
-- `backend/scripts/dedup-essentials-politicians.ts` groups by full_name + is_active,
-- which finds NAME COLLISIONS, not identity. Its seat-conflict guard blocked the
-- "Mark Hill" group because two rows held office_terms in different governments
-- (City of Frisco vs Frisco ISD). That block was reviewed on 2026-08-10 and recorded
-- as "two different people", but the reasoning was explicitly an UNTESTED ASSUMPTION:
-- both seats are in Frisco, so the jurisdiction screen proved nothing, and the ISD row
-- carries 0 stances so nothing contradicted it either way.
--
-- Tested 2026-08-16. The assumption was WRONG. They are the same man.
--
--   3579e02c-d480-48ba-8d95-3eb7f002a5b0  SURVIVOR  Mayor of Frisco, TX
--       office_term on 2087a453 (Mayor), 6 compass stances sourced to
--       markhill4mayor.com/policies + Community Impact's runoff Q&A, 1 headshot.
--   4612462c-7abf-4f9e-a8f8-a3aa9147e6e6  DUPLICATE  external_id -880026
--       office_term on 87fa280e (Frisco ISD Board Member, Place 5), 1 headshot.
--       Zero stances, zero finance sources, zero identifiers, zero committees.
--
-- ============================================================================
-- THE IDENTITY EVIDENCE
-- ============================================================================
-- * markhill4mayor.com/about — "He has served in critical roles in support of Frisco's
--   prosperity and the excellence of its schools, including as SCHOOL BOARD PRESIDENT."
--   The mayoral campaign claims the ISD service as its own candidate's record.
-- * Dallas Morning News — "Voters elected FORMER FRISCO ISD TRUSTEE Mark Hill as mayor."
-- * The Dallas Express — "FRISCO ELECTS MARK HILL AS NEXT MAYOR / Former Frisco ISD
--   board president Mark Hill…"
-- * KERA, CBS Texas and Yahoo all frame the June 2026 runoff as former-FISD-trustee
--   Hill vs. retired construction business owner Rod Vilhauer.
-- * LegiStorm — "Frisco (Texas) Independent School District Board of Trustees
--   (June 2023 - May 2026), Trustee, Place 5."
-- * THE HEADSHOTS. Both stored images were pulled and viewed side by side: the same
--   man, same face, same build — city-hall backdrop with the Frisco mark in one, a
--   gray studio background with an FISD lapel pin in the other. (Compare the Alex
--   Padilla group, where this same check showed visibly two different men.)
--
-- Elected to Place 5 on 2023-05-06, board president 2025-2026, elected Mayor in the
-- 2026-06-13 runoff (58.12%, def. Vilhauer). Trustee, then mayor. One person.
--
-- ============================================================================
-- THE LIVE DEFECT THIS REPAIRS
-- ============================================================================
-- Office 87fa280e (Frisco ISD Place 5) carries an OPEN-ENDED term on the duplicate row
-- from the migration-1459 current-occupancy backfill (term_start NULL, term_end NULL).
-- Occupancy reads as `term_end IS NULL AND is_incumbent`, so the corpus currently
-- asserts that Mark Hill is the SITTING Place 5 trustee. He is not — he left the board
-- in May 2026 and is now Mayor.
--
-- MISTY WAMHOFF won Place 5 on 2026-05-02 with 12,856 votes / 56%, defeating Sree Mouli
-- Majji (6,201 / 27%) and Babu Venkat (3,889 / 16%); Dynette Davis held Place 4
-- (15,212 / 66%). Source: Community Impact, 2026-05-02.
--
-- 🔴 AND THE OTHER HALF IS WRONG TOO. The occupancy predicate is `term_end IS NULL AND
-- is_incumbent`. The duplicate (ISD) row carries is_incumbent = TRUE, while the SURVIVING
-- mayoral row carries is_incumbent = FALSE. So the corpus today asserts Hill occupies
-- Frisco ISD Place 5 — which he vacated — and asserts that the City of Frisco has NO
-- sitting mayor, which is equally false. Retiring the duplicate alone would fix the first
-- and leave the second, so the survivor's incumbency flag is set here as well. Hill won
-- the 2026-06-13 runoff and is the sitting mayor; friscotexas.gov/2054/Mayor-Mark-Hill,
-- the city's own officeholder page, is already this row's photo_origin_url.
--
-- The mayoral term's term_start is deliberately left NULL / precision 'unknown'. The
-- runoff date is documented but the swearing-in date is not, and a guessed day is worse
-- than an honest unknown. Only the load-bearing occupancy flag is corrected.
--
-- ⚠ Wamhoff is deliberately NOT seeded here. Vacating the seat is the honest state; a
-- half-formed person row is worse than an acknowledged absence, and the vote totals
-- available are the pre-canvass unofficial ones. Seeding her is owed as its own item,
-- gated on the Collin/Denton canvass. This migration only stops the corpus from naming
-- the WRONG occupant.
--
-- ============================================================================
-- THE MERGE TRAP THIS AVOIDS
-- ============================================================================
-- ⚠ A naive merge would leave ONE row holding TWO open-ended terms both sourced
-- 'backfill from essentials.offices.politician_id%' — which is precisely the signature
-- of the single-row conflation detector used to find the Robert Garcia / Antonio
-- Vazquez misattribution (migration 1788). Two current-occupancy backfill terms on one
-- row means that row was the current occupant of two seats at once, which no person is.
-- So the ISD term is CLOSED as part of the move, not afterward, and its source string is
-- rewritten to the evidence above so it no longer matches that backfill LIKE pattern.
-- After this migration Hill holds exactly one open-ended term: Mayor.
--
-- Dates are month-precision. LegiStorm records the service as June 2023 - May 2026;
-- 2023-06-01 and 2026-05-31 are month markers, not asserted days. start_precision is
-- set to 'month' accordingly; office_terms has no end_precision column, hence this note.
--
-- The duplicate row is RETIRED, NOT DELETED — its external_id (-880026) and provenance
-- are the only record of how the split arose. Its headshot stays attached to it; the
-- survivor keeps the mayoral portrait, which depicts the current office.
--
-- Verified to hold ZERO rows for BOTH ids: politician_answers, politician_context,
-- politician_context_evidence, stance_research_review, topic_rewrite_stance_proposals,
-- identifiers, addresses, degrees, experiences, politician_committees,
-- politician_contacts, politician_name_aliases, quest_verified_facts, race_candidates,
-- empowered_profiles, la_council_votes, public.politician_id_bridge, and
-- transparent_motivations.politician_sources. Nothing but the office_term moves.
--
-- No answers are deleted or rewritten by this migration, so no @context-decision
-- declaration is required.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Move the Frisco ISD Place 5 term onto the surviving person row AND close it
--    in the same statement. Closing it is what vacates Place 5 and what keeps the
--    survivor from reading as the current occupant of two seats at once.
-- ---------------------------------------------------------------------------
UPDATE essentials.office_terms
SET politician_id   = '3579e02c-d480-48ba-8d95-3eb7f002a5b0',
    term_start      = DATE '2023-06-01',
    term_end        = DATE '2026-05-31',
    start_precision = 'month',
    how_ended       = 'term_expired',
    source          = 'Migration 1794: Frisco ISD Board of Trustees, Place 5. Elected '
                   || '2023-05-06 (Community Impact, "Davis, Hill win election to Frisco '
                   || 'ISD board of trustees"), board president 2025-2026, term ran to '
                   || 'May 2026 (LegiStorm: "Board of Trustees (June 2023 - May 2026), '
                   || 'Trustee, Place 5"). Succeeded by Misty Wamhoff, elected 2026-05-02 '
                   || 'with 12,856 votes / 56%. Dates are MONTH precision. Moved here from '
                   || 'duplicate person row 4612462c-7abf-4f9e-a8f8-a3aa9147e6e6 and closed; '
                   || 'previously an open-ended migration-1459 occupancy backfill that made '
                   || 'the corpus assert Hill was the sitting Place 5 trustee.'
WHERE id = '323ae4a3-e383-4327-b600-058842971140';

-- ---------------------------------------------------------------------------
-- 2. Seat the survivor as the sitting Mayor of Frisco. Occupancy is
--    `term_end IS NULL AND is_incumbent`, and this row's mayoral term is already
--    open-ended, so the flag is the only thing standing between the City of Frisco
--    and an empty mayor's chair.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians
SET is_incumbent = true
WHERE id = '3579e02c-d480-48ba-8d95-3eb7f002a5b0'
  AND is_incumbent = false;

-- ---------------------------------------------------------------------------
-- 3. Retire the duplicate person row (kept, not deleted).
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians
SET is_active    = false,
    is_incumbent = false,
    notes = ARRAY['DUPLICATE of politician 3579e02c-d480-48ba-8d95-3eb7f002a5b0 '
      || '(Mark Hill, Mayor of Frisco, TX). Same man: elected Frisco ISD Trustee Place 5 '
      || 'on 2023-05-06, served as board president 2025-2026, then won the 2026-06-13 '
      || 'Frisco mayoral runoff with 58.12%. His own campaign site claims the school-board '
      || 'presidency; DMN, the Dallas Express, KERA and CBS Texas all describe him as the '
      || 'former FISD trustee; LegiStorm dates the Place 5 service June 2023 - May 2026; '
      || 'and the two stored headshots are visibly the same person. This row existed only '
      || 'because dedup-essentials-politicians.ts groups by full_name and its seat-conflict '
      || 'guard blocked the group on City-of-Frisco vs Frisco-ISD, which is a real seat '
      || 'conflict for two rows but not evidence of two people. Migration 1794 moved the '
      || 'Place 5 term to the surviving row, closed it at May 2026, and retired this row. '
      || 'Frisco ISD Place 5 is left VACANT pending a seed for Misty Wamhoff, who won it '
      || 'on 2026-05-02.']
WHERE id = '4612462c-7abf-4f9e-a8f8-a3aa9147e6e6';

COMMIT;
