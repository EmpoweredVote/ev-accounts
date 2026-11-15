-- CC_0431 — Cambridge MA: the Mayor is one of the NINE councillors, and a SEVENTH school
-- committee member. We modelled it backwards: a tenth council row, and no committee seat.
--
-- Found by `check:body-completeness` (PR #1472), which flagged Cambridge City Council as
-- `ma|too_many`: official_count 9, eleven office rows, TEN distinct people. That gap of one
-- person is South Portland's signature (R9i) -- somebody holds two of the rows.
--
-- 🔴 BOTH HALVES COME FROM THE TWO BODIES' OWN WORDS, not from a count.
--
--   cambridgema.gov/Departments/citycouncil:
--     "There are nine members on the City Council, including the Mayor and Vice Mayor who
--      serve a two-year term."
--
--   cpsd.us/school_committee:
--     "Six members are elected at large."
--     "The Committee's Chair is elected by the seven members."
--     "The Mayor, who is elected by the nine elected City Council members, also serves on
--      the School Committee."
--
-- So the Mayor is NOT a tenth councillor -- which is what our `Mayor` office row made her --
-- and the School Committee is SEVEN, not the six we hold. One row is deleted and one created,
-- and they are the same fact pointing in two directions.
--
-- 🔴 DELETE, NOT RETITLE -- AND THE TEST IS THE ONE `CC_0428` USED. Bangor's Mayor row was a
-- councillor's ONLY seat, so deleting it would have unseated a sitting member and `CC_0427`
-- RETITLED. Here all NINE `City Councillor` rows are held by nine different people and Sumbul
-- Siddiqui is one of them, so the `Mayor` row is a second row for a person already seated.
-- Retitling would invent a TENTH council seat and seat her twice. Gate 0 below pins exactly that.
--
-- 🔴 THE DELETED ROWS, RECORDED HERE BECAUSE NOTHING ELSE WILL. There is no history table and no
-- replay, so an `UPDATE`/`DELETE` destroys its own evidence the moment it commits (CLAUDE.md;
-- `CA_0335` cost a full production clone for four strings).
--
--   essentials.offices 3ed99968-8f0b-443e-bc84-6ae2ad99233d, in full:
--     id 3ed99968-8f0b-443e-bc84-6ae2ad99233d · chamber_id b4b8c0a1-2658-4df4-9196-9646c99d173c
--     district_id cf3274f9-48c3-4e96-8273-3f6574add756 · title 'Mayor'
--     representing_state 'MA' · representing_city 'Cambridge' · description NULL · seats 1
--     normalized_position_name 'Mayor' · partisan_type NULL · salary NULL
--     is_appointed_position true · is_vacant false · vacant_since NULL
--     faces_retention_vote false · role_canonical NULL · voting_powers 'full'
--     representation_note NULL
--
--   DELETED BY CASCADE, essentials.office_terms 4ce135d3-ed47-42f5-93d8-7687340dd0df, in full:
--     id 4ce135d3-ed47-42f5-93d8-7687340dd0df · office_id 3ed99968-8f0b-443e-bc84-6ae2ad99233d
--     politician_id cc61015f-dba2-4f52-9f1f-832ef23f6595 (Sumbul Siddiqui)
--     term_start NULL · term_end NULL · start_precision 'unknown'
--     how_started NULL · how_ended NULL
--     source 'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'
--     created_at 2026-07-26T01:09:06.415146+00:00
--
--   ⚠ That term is a phase-2 BACKFILL row carrying no dates, so nothing dated is lost. The
--     dated fact -- that she became mayor on 2026-01-05 -- is WRITTEN, not destroyed, by the
--     new School Committee term below.
--
-- 🔴 `politicians.office_id` POINTS AT THE ROW BEING DELETED AND HAS NO FOREIGN KEY, so the
-- delete would leave it dangling without complaint (CLAUDE.md; `CC_0428` hit the same thing).
-- Measured: exactly one row, Siddiqui's, pointing at 3ed99968. It is repointed to her
-- `City Councillor` office BEFORE the delete. The column is deprecated, which is a reason to
-- keep it honest rather than a reason to let it rot.
--
-- ⚠ `essentials.politician_occupancy_evidence` also names this office. It is a VIEW -- checked,
-- not assumed -- so it carries no rows of its own and needs no repointing.
--
-- 🟢 term_start 2026-01-05 IS A REAL OCCUPANCY START, AND R4b IS WHY IT QUALIFIES. A published
-- date is an occupancy start only if something broke continuity before it. Siddiqui "served two
-- prior terms as mayor from 2020-23" and was not mayor in between, so this is a fresh election
-- rather than a date copied off a roster. Cambridge Day, 2026-01-05, reporting the meeting it
-- happened at: "The new Cambridge City Council was sworn in at City Hall, after which Sumbul
-- Siddiqui was voted mayor by her fellow councillors." Its photo caption names all nine
-- councillors and they are exactly our nine.
--
-- 🔴 `is_appointed_position = true` ON THE NEW SEAT. Voters do not elect it: the committee seat
-- is conferred by a mayoralty that the nine councillors confer. The API publishes `is_elected`
-- as this column's negation, so this is the voter-facing truth (R9g). It is the same shape as
-- Lewiston's council-appointed ninth seat (`CC_0430`), from the other side -- there a councillor
-- sits on the school committee by appointment; here the mayor does by office.
--
-- ⚠ WHAT THIS FILE DOES NOT FIX, ON PURPOSE. After it, the City Council chamber holds 10 offices
-- against an official_count of 9: nine councillors plus `City Manager`, Cambridge's appointed
-- chief executive, who is not a council member. That keeps `ma|too_many` at 1 -- but it moves
-- Cambridge out of the gate's UNEXPLAINED pile and into the large, documented "surplus is an
-- exec-type office the official_count does not count" class, with El Monte, Inglewood, Pasadena,
-- DeKalb, Fulton and three Texas cities. Whether an appointed executive belongs in a legislative
-- chamber is a question about every one of them, not about Cambridge, and it is not decided here.
--
-- @incumbency-decision: no-effect — neither office touched carries a race, so there is no
-- `race_candidates.is_incumbent` answer about either seat that a term row could restate.
-- Measured on prod before writing: the deleted `Mayor` office held 0 races, and the School
-- Committee office this file creates is BRAND NEW and carries none. The delete removes a
-- backfill term with NULL dates, which cannot have been covering any election day; the insert
-- closes no predecessor, because the new office has no prior term. Gate 5 re-asserts the zero
-- race counts at apply time rather than trusting this paragraph.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0431_cambridge_ma_mayor_seat_moves_to_school_committee.sql

BEGIN;

-- ── 0. Pin the facts that make DELETE the right verb and CREATE the right counterpart ────────
DO $$
DECLARE
  v_councillors int;
  v_council_cnt int;
  v_sc_offices  int;
  v_sc_cnt      int;
  v_races       int;
BEGIN
  SELECT (SELECT count(*) FROM essentials.offices o
           WHERE o.chamber_id = 'b4b8c0a1-2658-4df4-9196-9646c99d173c' AND o.title = 'City Councillor'),
         ch.official_count
    INTO v_councillors, v_council_cnt
    FROM essentials.chambers ch WHERE ch.id = 'b4b8c0a1-2658-4df4-9196-9646c99d173c';

  IF v_councillors <> 9 OR v_council_cnt <> 9 THEN
    RAISE EXCEPTION 'CC_0431: expected 9 City Councillor offices against official_count 9; found % / %.',
      v_councillors, v_council_cnt;
  END IF;

  -- 🔴 THE CC_0428 TEST. If Siddiqui did NOT already hold a council seat, deleting the Mayor row
  -- would unseat a sitting member and the right fix would be Bangor's retitle instead.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t
     WHERE t.office_id = 'fd399703-ce64-4249-8c9d-6d2304ae51bb'
       AND t.politician_id = 'cc61015f-dba2-4f52-9f1f-832ef23f6595'
       AND t.term_end IS NULL
  ) THEN
    RAISE EXCEPTION
      'CC_0431: Sumbul Siddiqui does NOT hold a City Councillor seat, so deleting the Mayor '
      'office would unseat her. Retitle instead (see Bangor, CC_0427).';
  END IF;

  -- The row being deleted must still be the one described in the header.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.offices o
     WHERE o.id = '3ed99968-8f0b-443e-bc84-6ae2ad99233d'
       AND o.title = 'Mayor'
       AND o.chamber_id = 'b4b8c0a1-2658-4df4-9196-9646c99d173c'
  ) THEN
    RAISE EXCEPTION 'CC_0431: office 3ed99968 is not Cambridge City Council''s Mayor row any more.';
  END IF;

  SELECT count(*) INTO v_races FROM essentials.races WHERE office_id = '3ed99968-8f0b-443e-bc84-6ae2ad99233d';
  IF v_races <> 0 THEN
    RAISE EXCEPTION
      'CC_0431: the Mayor office carries % race(s). Deleting it would orphan them, and the '
      '@incumbency-decision in this header assumes zero.', v_races;
  END IF;

  SELECT (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = '41846a49-e5d5-460d-b2c2-0f4f8130b949'),
         ch.official_count
    INTO v_sc_offices, v_sc_cnt
    FROM essentials.chambers ch WHERE ch.id = '41846a49-e5d5-460d-b2c2-0f4f8130b949';

  IF v_sc_offices <> 6 OR v_sc_cnt <> 6 THEN
    RAISE EXCEPTION 'CC_0431: expected 6 School Committee offices against official_count 6; found % / %.',
      v_sc_offices, v_sc_cnt;
  END IF;

  IF EXISTS (
    SELECT 1 FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
     WHERE o.chamber_id = '41846a49-e5d5-460d-b2c2-0f4f8130b949'
       AND t.politician_id = 'cc61015f-dba2-4f52-9f1f-832ef23f6595'
  ) THEN
    RAISE EXCEPTION 'CC_0431: Siddiqui already holds a School Committee seat.';
  END IF;
END $$;

CREATE TEMP TABLE _bc_before ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM essentials.offices)                                     AS offices,
  (SELECT count(*) FROM essentials.offices o
     WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id))
                                                                                AS termless_offices,
  (SELECT count(*) FROM essentials.offices_missing_terms m
     JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)      AS drift_unflagged,
  -- ⚠ MEASURED, NOT ASSUMED TO BE ZERO. The first draft of this file gated on the TOTAL being 0
  -- and the dry run refused it: production already carries 57 politicians.office_id values
  -- pointing at offices that no longer exist. That is this column rotting exactly the way
  -- CLAUDE.md says it does -- no foreign key, so every past delete that skipped the repoint left
  -- one -- and it is NOT this migration's to fix. Gating on the total would also have been the
  -- very error this repo keeps paying for: gate the DELTA you create, never a number another
  -- session can move while you write the file.
  (SELECT count(*) FROM essentials.politicians p
     WHERE p.office_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = p.office_id))
                                                                                AS dangling_snapshots;

-- ── 1. 🔴 REPOINT THE FK-LESS SNAPSHOT BEFORE THE DELETE, or it dangles silently ─────────────
UPDATE essentials.politicians
   SET office_id = 'fd399703-ce64-4249-8c9d-6d2304ae51bb'   -- her City Councillor office
 WHERE id = 'cc61015f-dba2-4f52-9f1f-832ef23f6595'
   AND office_id = '3ed99968-8f0b-443e-bc84-6ae2ad99233d';

-- ── 2. Retire the phantom. Its one backfill office_terms row goes with it, ON DELETE CASCADE ──
DELETE FROM essentials.offices WHERE id = '3ed99968-8f0b-443e-bc84-6ae2ad99233d';

-- ── 3. The seat the Mayor actually holds ─────────────────────────────────────────────────────
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, seats,
   normalized_position_name, is_appointed_position, is_vacant, voting_powers)
SELECT '41846a49-e5d5-460d-b2c2-0f4f8130b949',
       'bde9b757-4266-4fd7-a4eb-a9a06338514a',
       'School Committee Member (Mayor)',
       'MA', 'Cambridge', 1,
       'School Committee Member',
       true,    -- conferred by the council's choice of mayor; voters do not elect it
       false,
       'full'   -- "elected by the seven members" makes the Mayor a full voting member
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices
   WHERE chamber_id = '41846a49-e5d5-460d-b2c2-0f4f8130b949'
     AND title = 'School Committee Member (Mayor)'
);

SELECT essentials.seat_officeholder(
  (SELECT id FROM essentials.offices
    WHERE chamber_id = '41846a49-e5d5-460d-b2c2-0f4f8130b949'
      AND title = 'School Committee Member (Mayor)'),
  'cc61015f-dba2-4f52-9f1f-832ef23f6595',
  DATE '2026-01-05',
  'cpsd.us/school_committee, the committee''s own page: "Six members are elected at large." '
  '"The Committee''s Chair is elected by the seven members." "The Mayor, who is elected by the '
  'nine elected City Council members, also serves on the School Committee." The 2026-27 member '
  'list on cpsd.us names our six plus "Mayor Sumbul Siddiqui". DATE: Cambridge Day 2026-01-05, '
  '"City Council seated, Siddiqui named mayor" -- "The new Cambridge City Council was sworn in at '
  'City Hall, after which Sumbul Siddiqui was voted mayor by her fellow councillors"; its photo '
  'caption names all nine councillors, exactly ours. This is a real occupancy start per R4b and '
  'not a roster date: she "served two prior terms as mayor from 2020-23" and was not mayor in '
  'between, so continuity was broken before it. term_end is NULL although the mayoralty runs two '
  'years, per ROSTERS.md R4 -- a dated expiry would unseat this seat with no human act. CC_0431.',
  'appointed',   -- p_how_started: elected by the nine councillors, never by voters
  'day'          -- p_start_precision
);

-- ── 4. The committee states its own size ─────────────────────────────────────────────────────
UPDATE essentials.chambers
   SET official_count = 7
 WHERE id = '41846a49-e5d5-460d-b2c2-0f4f8130b949'
   AND official_count = 6;

-- ── 5. Post-verify ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_council_offices int;
  v_councillors     int;
  v_mayor_rows      int;
  v_sc_offices      int;
  v_sc_people       int;
  v_sc_cnt          int;
  v_holder          text;
  v_dangling        int;
  v_sid_seats       int;
  v_net             int;
  v_termless        int;
  v_drift           int;
  v_races           int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE o.title = 'City Councillor'),
         count(*) FILTER (WHERE o.title = 'Mayor')
    INTO v_council_offices, v_councillors, v_mayor_rows
    FROM essentials.offices o WHERE o.chamber_id = 'b4b8c0a1-2658-4df4-9196-9646c99d173c';

  IF v_councillors <> 9 THEN
    RAISE EXCEPTION 'CC_0431: % City Councillor offices after the delete, expected 9.', v_councillors;
  END IF;
  IF v_mayor_rows <> 0 THEN
    RAISE EXCEPTION 'CC_0431: the council chamber still holds % Mayor row(s).', v_mayor_rows;
  END IF;
  -- 9 councillors + City Manager. Asserted so that a later change to the manager row is noticed.
  IF v_council_offices <> 10 THEN
    RAISE EXCEPTION 'CC_0431: council chamber holds % offices, expected 10 (9 councillors + City Manager).', v_council_offices;
  END IF;

  -- 🔴 Siddiqui must still be seated as a councillor. This is the whole premise of DELETE.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t
     WHERE t.office_id = 'fd399703-ce64-4249-8c9d-6d2304ae51bb'
       AND t.politician_id = 'cc61015f-dba2-4f52-9f1f-832ef23f6595'
       AND t.term_end IS NULL
  ) THEN
    RAISE EXCEPTION 'CC_0431: Siddiqui lost her City Councillor seat. The CASCADE ate the wrong term.';
  END IF;

  SELECT ch.official_count,
         (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id),
         (SELECT count(DISTINCT t.politician_id)
            FROM essentials.offices o JOIN essentials.office_terms t ON t.office_id = o.id
           WHERE o.chamber_id = ch.id AND t.politician_id IS NOT NULL
             AND (t.term_end IS NULL OR t.term_end >= current_date))
    INTO v_sc_cnt, v_sc_offices, v_sc_people
    FROM essentials.chambers ch WHERE ch.id = '41846a49-e5d5-460d-b2c2-0f4f8130b949';

  IF v_sc_offices <> 7 OR v_sc_cnt <> 7 THEN
    RAISE EXCEPTION 'CC_0431: School Committee holds % offices against official_count %; the committee says 7 and 7.',
      v_sc_offices, v_sc_cnt;
  END IF;
  IF v_sc_people <> 7 THEN
    RAISE EXCEPTION 'CC_0431: 7 School Committee offices but % distinct holders.', v_sc_people;
  END IF;

  SELECT p.full_name INTO v_holder
    FROM essentials.offices o
    JOIN essentials.office_terms t ON t.office_id = o.id
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE o.chamber_id = '41846a49-e5d5-460d-b2c2-0f4f8130b949'
     AND o.title = 'School Committee Member (Mayor)' AND t.term_end IS NULL;
  IF v_holder IS DISTINCT FROM 'Sumbul Siddiqui' THEN
    RAISE EXCEPTION 'CC_0431: the Mayor''s committee seat is held by %, expected Sumbul Siddiqui.', coalesce(v_holder,'nobody');
  END IF;

  -- She now holds exactly two Cambridge seats: councillor, and the committee seat that follows it.
  SELECT count(*) INTO v_sid_seats
    FROM essentials.offices o
    JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE t.politician_id = 'cc61015f-dba2-4f52-9f1f-832ef23f6595' AND t.term_end IS NULL;
  IF v_sid_seats <> 2 THEN
    RAISE EXCEPTION 'CC_0431: Siddiqui holds % current seats, expected exactly 2.', v_sid_seats;
  END IF;

  -- 🔴 THE FK-LESS SNAPSHOT MUST NOT DANGLE *BECAUSE OF THIS FILE*. Asserted as a delta against
  -- the 57 that production already carried, not as a total -- see the note in _bc_before.
  SELECT (SELECT count(*) FROM essentials.politicians p
            WHERE p.office_id IS NOT NULL
              AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = p.office_id))
         - b.dangling_snapshots
    INTO v_dangling
    FROM _bc_before b;
  IF v_dangling <> 0 THEN
    RAISE EXCEPTION
      'CC_0431: this file changed the number of dangling politicians.office_id snapshots by %. '
      'The repoint in step 1 did not take, so the delete left Siddiqui''s snapshot pointing at '
      'an office that no longer exists.', v_dangling;
  END IF;

  -- Re-assert the @incumbency-decision's premise rather than trusting the header.
  SELECT count(*) INTO v_races FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
   WHERE o.chamber_id IN ('b4b8c0a1-2658-4df4-9196-9646c99d173c','41846a49-e5d5-460d-b2c2-0f4f8130b949');
  IF v_races <> 0 THEN
    RAISE EXCEPTION 'CC_0431: % race(s) on Cambridge council/committee offices; the no-effect incumbency decision assumed zero.', v_races;
  END IF;

  -- Deltas: one office out, one in; nothing unseated; the drift baseline unmoved.
  SELECT (SELECT count(*) FROM essentials.offices) - b.offices,
         (SELECT count(*) FROM essentials.offices o
            WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id))
           - b.termless_offices,
         (SELECT count(*) FROM essentials.offices_missing_terms m
            JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)
           - b.drift_unflagged
    INTO v_net, v_termless, v_drift
    FROM _bc_before b;

  IF v_net <> 0 THEN
    RAISE EXCEPTION 'CC_0431: net office change is %, expected 0 (one deleted, one created).', v_net;
  END IF;
  IF v_termless <> 0 THEN
    RAISE EXCEPTION 'CC_0431: % more office(s) now carry no term.', v_termless;
  END IF;
  IF v_drift <> 0 THEN
    RAISE EXCEPTION 'CC_0431: the unflagged drift baseline moved by %; it must stay at 238.', v_drift;
  END IF;

  RAISE NOTICE 'CC_0431 OK: council 11 -> 10 offices (9 councillors + City Manager, 0 Mayor rows); School Committee 6 -> 7 offices / 7 holders / official_count 7; Siddiqui holds 2 seats; no dangling snapshot; drift unmoved.';
END $$;

COMMIT;
