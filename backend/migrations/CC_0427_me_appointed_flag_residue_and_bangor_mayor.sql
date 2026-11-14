-- CC_0427: Maine -- three council seats that are published to voters as NOT ELECTED. Two are
--          `CC_0292`'s own residue; the third is a phantom Mayor office in a city `CC_0292`
--          never looked at.
--
-- `CC_0426` (Wood Village OR) hit this exact shape and its notes named the two Maine rows as a
-- follow-up. Taking the follow-up meant sweeping the whole state rather than fixing the two that
-- had been spotted -- and the sweep is what found Bangor.
--
-- ═══ 🔴 WHAT `is_appointed_position` ACTUALLY DOES, WHICH IS WHY THIS IS NOT COSMETIC ═══
-- The API derives a voter-facing field straight from it:
--     is_elected: !row.is_appointed_position
-- in `essentialsService.ts` and in seven more mappers in `essentialsBrowseService.ts`. So every
-- row below is being served to a resident as a seat they do not elect.
--
-- ═══ THE SWEEP: ALL 8 FLAGGED MAINE OFFICES, CLASSIFIED ONE AT A TIME ═══
-- Measured in prod 2026-11-13. `CC_0298`'s lesson about the undated flags applies to this flag
-- too: the column cannot tell you which kind of thing a row is, and here there are four kinds.
--
--   office                                             | holder            | verdict
--   ---------------------------------------------------+-------------------+------------------
--   Presque Isle  Council Member (At-Large 7)          | Debra Plummer     | 🔴 FIX -- residue
--   Rockland      Council Member (At-Large 5)          | Adam Lachman      | 🔴 FIX -- residue
--   Bangor        Mayor                                 | Susan Hawes       | 🔴 FIX -- phantom
--   South Portland Mayor                                | Elyse Tipton      | ⚪ leave, see below
--   Lewiston Public Schools  School Cttee (Ward 5)      | Lynnea Hawkins    | ⚪ unresolved
--   Maine Attorney General                              | Aaron M. Frey     | 🟢 CORRECT
--   Maine Secretary of State                            | Shenna Bellows    | 🟢 CORRECT
--   Maine Treasurer                                     | Joseph C. Perry   | 🟢 CORRECT
--
-- 🟢 THE LAST THREE ARE THE POSITIVE CONTROL, AND THEY MATTER. Maine is the state where the
--    LEGISLATURE chooses the Attorney General, the Secretary of State and the Treasurer; none of
--    the three appears on any ballot. So `is_appointed_position = true` is RIGHT for them, and a
--    sweep that cleared the flag "wherever it looked wrong in Maine" would have made three true
--    rows false. ▶ The flag is not uniformly wrong here, which is exactly why each row was read
--    on its own rather than by a predicate over the column.
--
-- ═══ 1 & 2. THE `CC_0292` RESIDUE -- Presque Isle and Rockland ═══
-- `CC_0292` retitled six phantom Mayor offices into council seats and CLEARED NO FLAGS. In two of
-- the six the office had carried `is_appointed_position = true`, because the mayoralty really is
-- conferred by the council -- and that flag is a property of the OFFICE, which is now a council
-- seat. Both cities elect their whole council at large, which `CC_0292` established from their
-- own charters and recorded in `seed-me-municipal-2026/ROSTERS.md` R9:
--   Presque Isle  "seven individuals elected at-large"; "Each year, the City Council elects a
--                 Council Chair"
--   Rockland      "The voters elect the five City Councilors. The Mayor is chosen by the Council
--                 for a 1-year term."
-- The retitle was right and incomplete. ▶ A RETITLE IS RARELY ONLY A TITLE: an office row states
-- several things at once, and the one that reaches voters was not the name.
--
-- ═══ 3. BANGOR -- A PHANTOM MAYOR IN A CITY THE AUDIT NEVER COVERED ═══
-- `CC_0292`'s R9 pass read nine all-at-large cities and found six phantoms. Bangor was not among
-- the nine. From the city's own page, retrieved 2026-11-14 and committed under
-- `backend/data/seed-me-municipal-2026/sources/me-bangor-city-council-2026-11-14.txt`:
--
--   "Immediately following election in November, the Council selects one of its members to serve
--    as Council Chair for the year."
--   "The Council Chair serves as Mayor and represents the City at ceremonial events and in its
--    interactions with State and Federal governments."
--
-- That is R9's test answered outright -- the sentence that says who ELECTS the presiding officer
-- says the council does, from its own members. Same as Caribou; the opposite of Calais, where
-- "City Councilors are elected at large by the citizens of Calais, AS IS THE MAYOR" and the office
-- is real.
--
--   "Councilors are elected to three-year terms with three positions on the Council up for
--    election each year in November."
-- Three a year on three-year terms is NINE, which is what `chambers.official_count` already says.
-- We hold 8 `Council Member (At-Large 1..8)` plus `Mayor` = 9 offices, all nine seated by nine
-- DIFFERENT people, all on the one Bangor district. So the ninth councilor is Susan Hawes and the
-- row she sits in is titled with her role. `Mayor` -> `Council Member (At-Large 9)` is `CC_0292`'s
-- own fix (`Mayor -> At-Large 7` for Caribou), applied to the city it missed.
--
-- 🔴 WHY BANGOR SURVIVED AN AUDIT BUILT TO CATCH EXACTLY THIS. In all six `CC_0292` cities the
--    phantom label left the council one seat SHORT of its charter size, and that shortfall is what
--    the wave counted. Bangor's arithmetic already closes: 8 + 1 = 9 = official_count. ▶ THE COUNT
--    BEING RIGHT IS NOT THE BODY BEING RIGHT -- R8c said the same thing from the other side, where
--    Hallowell's titles were the right KIND and the wrong NUMBER. Only the charter settles either.
--
-- ⚠ AND THE BALLOT CANNOT CORROBORATE IT HERE, UNLIKE WOOD VILLAGE. `CC_0426` leaned on a charter
--    that predicted a missing mayoral contest and an export that confirmed the absence. Bangor
--    carries ZERO races -- but so do all nine of its offices, and so does every Maine municipal
--    office, because this repo seeds no Maine municipal races at all. ▶ An absence is only evidence
--    when the thing would have been present. Here it is not evidence, and it is not used as any.
--
-- ═══ ⚪ THE TWO LEFT ALONE, AND WHY EACH IS A DIFFERENT QUESTION ═══
--
-- SOUTH PORTLAND `Mayor` (Elyse Tipton) is NOT this defect. She holds the Mayor office AND
-- `Council Member (District 5)` -- two current terms -- so the office consumes no seat and the
-- flag is an honest statement about how that chair is filled. The arrangement PREDATES every Maine
-- wave and is already recorded, as a control in ROSTERS.md R11's dual-seat table. Whether a
-- council-chosen chair should be an office at all is R5's open question for South Portland and is
-- not something a flag-clearing migration gets to decide.
--
-- LEWISTON PUBLIC SCHOOLS `School Committee Member (Ward 5)` (Lynnea Hawkins) is UNRESOLVED, and
-- the reason is a finding rather than a search failure. The committee publishes its membership as
-- an IMAGE: the page carries no "Ward" string at all and the only machine-readable trace of her is
-- the address `lhawkins@lewistonpublicschools.org`. ⚠ That "nothing found" was checked with a
-- positive control -- the same extractor pulled 57 lines of real text off the same page, and the
-- raw HTML does contain "Hawkins" -- so it is the body's publishing practice, not a broken reader.
-- A ward school-committee seat is elective, so the flag is either wrong about the office or is
-- recording how one PERSON arrived in it, and those want opposite fixes. ▶ Its own look.
--
-- ═══ 🔴 VALUES OVERWRITTEN -- THERE IS NO HISTORY TABLE FOR EITHER COLUMN ═══
--   offices 065b5823-7a8c-40fc-a275-7d912c4a65b5  Presque Isle Council Member (At-Large 7)
--     is_appointed_position  true  -> false
--   offices 758c0601-fdce-4dde-bf14-fbdce5df0847  Rockland Council Member (At-Large 5)
--     is_appointed_position  true  -> false
--   offices 48af7975-57a6-437a-bc44-f88a445b49d7  Bangor
--     title                  'Mayor'  -> 'Council Member (At-Large 9)'
--     is_appointed_position  true     -> false
--
-- ⚠ THE SEAT NUMBER 9 IS OURS, NOT BANGOR'S (ROSTERS.md R6). Bangor numbers none of its at-large
--   seats; 1..8 were assigned by an earlier pass in the order its page listed them and carry no
--   meaning. 9 is the next free one and says nothing about Susan Hawes.
--
-- Nothing here seats, unseats or moves anybody, creates or deletes an office, or touches a race.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 0. Pin all three rows by WHO HOLDS THEM. Two of the three are identified by a title this file
--    changes, so matching on titles would be circular AND would not prove the UUIDs are right.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n integer;
BEGIN
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE (o.id = '065b5823-7a8c-40fc-a275-7d912c4a65b5' AND p.full_name = 'Debra Plummer')
      OR (o.id = '758c0601-fdce-4dde-bf14-fbdce5df0847' AND p.full_name = 'Adam Lachman')
      OR (o.id = '48af7975-57a6-437a-bc44-f88a445b49d7' AND p.full_name = 'Susan Hawes');
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0427: expected Plummer, Lachman and Hawes on the three pinned offices; matched % of 3.', v_n;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1 & 2. The CC_0292 residue. Both cities elect their whole council at large.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices
   SET is_appointed_position = false
 WHERE id IN ('065b5823-7a8c-40fc-a275-7d912c4a65b5',   -- Presque Isle At-Large 7
               '758c0601-fdce-4dde-bf14-fbdce5df0847');  -- Rockland At-Large 5

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 3. Bangor. The Council Chair serves as Mayor; the seat is a council seat.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices
   SET title                 = 'Council Member (At-Large 9)',
       is_appointed_position = false
 WHERE id = '48af7975-57a6-437a-bc44-f88a445b49d7';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-VERIFY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_three     integer;
  v_held      integer;
  v_bangor    integer;
  v_bangor_al integer;
  v_distinct  integer;
  v_me_scope  integer;
  v_me_flag   integer;
  v_state_exec integer;
  v_offices   integer;
  v_unflagged integer;
BEGIN
  -- The three rows now publish as elected.
  SELECT count(*) INTO v_three
    FROM essentials.offices
   WHERE id IN ('065b5823-7a8c-40fc-a275-7d912c4a65b5',
                '758c0601-fdce-4dde-bf14-fbdce5df0847',
                '48af7975-57a6-437a-bc44-f88a445b49d7')
     AND is_appointed_position = false;
  IF v_three <> 3 THEN
    RAISE EXCEPTION 'CC_0427: % of 3 seats publish as elected.', v_three;
  END IF;

  -- 🔴 Nobody moved. The holders are the one thing in this file that must not change.
  SELECT count(*) INTO v_held
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE (och.office_id = '065b5823-7a8c-40fc-a275-7d912c4a65b5' AND p.full_name = 'Debra Plummer')
      OR (och.office_id = '758c0601-fdce-4dde-bf14-fbdce5df0847' AND p.full_name = 'Adam Lachman')
      OR (och.office_id = '48af7975-57a6-437a-bc44-f88a445b49d7' AND p.full_name = 'Susan Hawes');
  IF v_held <> 3 THEN
    RAISE EXCEPTION 'CC_0427: % of 3 holders still hold the seat they held before this ran.', v_held;
  END IF;

  -- Bangor is a nine-seat council, nine distinct people, no role worn as a title, all on one
  -- district -- and the chamber's own stated size is what 9 is checked against.
  SELECT count(*),
         count(*) FILTER (WHERE o.title LIKE 'Council Member (At-Large %)'),
         count(DISTINCT och.politician_id)
    INTO v_bangor, v_bangor_al, v_distinct
    FROM essentials.offices o
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.chamber_id = (SELECT c.id FROM essentials.chambers c
                           JOIN essentials.governments g ON g.id = c.government_id
                          WHERE g.name = 'City of Bangor, Maine, US'
                            AND c.name_formal = 'Bangor City Council');
  IF v_bangor <> 9 OR v_bangor_al <> 9 THEN
    RAISE EXCEPTION 'CC_0427: Bangor holds % offices of which % are at-large council seats; expected 9 and 9.', v_bangor, v_bangor_al;
  END IF;
  IF v_distinct <> 9 THEN
    RAISE EXCEPTION 'CC_0427: Bangor''s 9 seats are held by % distinct people -- the Mayor row was NOT a ninth councilor.', v_distinct;
  END IF;
  IF (SELECT c.official_count FROM essentials.chambers c
        JOIN essentials.governments g ON g.id = c.government_id
       WHERE g.name = 'City of Bangor, Maine, US' AND c.name_formal = 'Bangor City Council') IS DISTINCT FROM v_bangor THEN
    RAISE EXCEPTION 'CC_0427: Bangor''s office count no longer equals the size the chamber states.';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.offices o
               WHERE o.chamber_id = (SELECT c.id FROM essentials.chambers c
                                       JOIN essentials.governments g ON g.id = c.government_id
                                      WHERE g.name = 'City of Bangor, Maine, US'
                                        AND c.name_formal = 'Bangor City Council')
                 AND o.title ILIKE '%mayor%') THEN
    RAISE EXCEPTION 'CC_0427: a Bangor office is still titled Mayor.';
  END IF;

  -- 🟢 THE POSITIVE CONTROL STAYS TRUE. Maine's legislature chooses these three, so clearing the
  --    flag on them would be the mistake this sweep was built to avoid.
  SELECT count(*) INTO v_state_exec
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_EXEC'
     AND o.title IN ('Attorney General', 'Secretary of State', 'Treasurer')
     AND o.is_appointed_position = true;
  IF v_state_exec <> 3 THEN
    RAISE EXCEPTION 'CC_0427: % of the 3 legislature-chosen Maine state offices are still flagged appointed -- this sweep must not have touched them.', v_state_exec;
  END IF;

  -- The whole Maine flagged population, re-counted: 8 before, 5 after, and the survivors are the
  -- 3 state offices plus the 2 deliberately left (South Portland Mayor, Lewiston Ward 5).
  SELECT count(*) FILTER (WHERE o.is_appointed_position = true), count(*)
    INTO v_me_flag, v_me_scope
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me';
  IF v_me_scope < 300 THEN
    RAISE EXCEPTION 'CC_0427: the Maine sweep examined only % offices -- it is reading the wrong rows.', v_me_scope;
  END IF;
  IF v_me_flag <> 5 THEN
    RAISE EXCEPTION 'CC_0427: Maine carries % appointed-flagged offices, not the 5 this file accounts for.', v_me_flag;
  END IF;

  -- No council or school seat anywhere in Maine still publishes as not elected.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'me' AND o.is_appointed_position = true
       AND o.title ~* '(council|councilor|councillor|school committee|board member)'
       AND o.id <> '411f3897-8727-4c01-9100-1f714a543308'  -- South Portland Mayor is titled Mayor, not matched here
       AND o.id <> 'e4117d9e-d048-4ba2-b13e-c65607fec97f'  -- Lewiston Ward 5, left open deliberately
  ) THEN
    RAISE EXCEPTION 'CC_0427: a Maine council or school seat still publishes as not elected.';
  END IF;

  -- Nothing was created or destroyed.
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me';
  IF v_offices <> v_me_scope THEN
    RAISE EXCEPTION 'CC_0427: Maine office count moved.';
  END IF;

  -- A flag is not a seating.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN
    RAISE EXCEPTION 'CC_0427: drift baseline reads %, not 238.', v_unflagged;
  END IF;

  RAISE NOTICE 'CC_0427 OK: 3 Maine council seats now publish as elected, Bangor is 9 at-large seats held by 9 people with no Mayor row, the 3 legislature-chosen state offices keep their flag, % Maine offices examined and 5 still flagged (3 correct + 2 left open), drift baseline 238.', v_me_scope;
END $$;

COMMIT;
