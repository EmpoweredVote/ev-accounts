-- CC_0293 — the last five Maine municipalities: Belfast, Gardiner, Hallowell, Saco, Waterville.
-- 38 offices, every one of them filled. This finishes the Maine municipal skeleton.
--
-- Read `backend/data/seed-me-municipal-2026/ROSTERS.md` before touching any Maine municipal
-- office. R1–R9e are there, and this migration is the seventh wave written against them:
--   CC_0282 Augusta 18 · CC_0283 Westbrook 15 · CC_0291 Bath 9 · CC_0292 the nine at-large 57.
--
-- ─── THE DEFECT BEING FIXED (R1) ─────────────────────────────────────────────────────────
-- All 38 arrived `is_vacant = true` with a NULL `vacant_since` and no `office_terms` row.
-- That is not 38 vacancies. It asserts to a voter that every seat in five cities is empty,
-- and at the same time keeps the rows OUT of the drift metric, because
-- `offices_missing_terms` counts only UNFLAGGED rows as drift. Seating and un-flagging
-- happen in ONE transaction (R2): either half alone breaks something.
--
-- ─── R9 ASKED THE MAYORAL QUESTION OF FIVE CITIES AND ALL FIVE CAME BACK CORRECT ─────────
-- `CC_0292` found that six of nine cities held a `Mayor` office that was really a rotating
-- chair. The tracker therefore flagged all five of these for the same check. Every one of
-- them elects its Mayor directly, in the city's own charter words:
--
--   Belfast    Art II §2  "The Council shall be composed of the Mayor and five other members"
--              Art V §1(b) voters "cast their ballots … for the following municipal officers:
--              Mayor; City Councilors; …"                                      → KEEP
--   Gardiner   Art III §1 "A Mayor shall be elected by and from the qualified
--              voters of the City."                                            → KEEP
--   Hallowell  Art III §1 "The Mayor shall be elected by and from the qualified
--              voters of the City."  (2017 charter; the Mayor is on the 2026-11-03 ballot
--              with two candidates)                                            → KEEP
--   Saco       §2.05(a) "The Mayor shall be elected by the voters of the entire City, and
--              the City Councilors shall be elected by the voters of their respective wards."
--                                                                              → KEEP
--   Waterville Art II §2 "The Mayor shall be elected by the inhabitants of the City as
--              provided in Article IX of this Charter."                        → KEEP
--
-- ▶ The phantom-mayor defect clustered in the AT-LARGE council–manager cities, not in the
--   ward cities. That is a pattern worth knowing, and it is NOT a licence to skip the check:
--   it was only visible once all fourteen had been read.
--
-- ─── R5: THREE ROTATING ROLES APPEAR HERE AND NONE OF THEM IS AN OFFICE ──────────────────
--   Waterville  "Council Chair" (Brandon Gilley, Ward 1) — the Chair acts as Mayor only
--               during a mayoral vacancy (Art II §4). Our schema holds no Chair office. ✅
--   Saco        "Deputy Mayor" — §2.05(c), "The City Council shall nominate and elect from
--               its membership a Deputy Mayor". No office held, none created. ✅
--   Belfast     the Mayor is "ex officio president of the Council" — that is a duty OF the
--               elected mayoralty, not a separate seat. ✅
--
-- ─── R8: HALLOWELL IS A SECOND BATH. WE HAD ITS WARD COUNT WRONG. ────────────────────────
-- We modelled Hallowell as 4 wards + 3 at-large. Its 2017 charter, §1(c) and §2(a)–(b):
--
--   "The City shall continue to be divided into 5 wards with the now existing boundaries"
--   "The City Council shall be composed of the Mayor … and 7 members. Except for the
--    2 Councilors-at-Large, each Councilor shall be a resident of the ward from which the
--    Councilor is elected."
--   "One ward Councilor shall be elected by and from the qualified voters of each of the
--    5 wards"
--
-- So Hallowell is 5 wards + 2 at-large, and we were telling a Ward 5 voter they elect a
-- third at-large councillor instead of their own ward member. The city's own contact
-- addresses settle it beyond argument — `ward1@` … `ward5@` and `atlarge1@`, `atlarge2@`,
-- exactly as Bath's `ward4@` did in CC_0291.
-- 🔴 The office COUNT was right (8), the chamber was right, the district was right. Nothing
--    in the repo compares a seat's name to the body's own description of itself. The fix is
--    a RETITLE of one office, not a remodel.
-- 🟢 R6 says at-large NUMBERS are ours — but Hallowell numbers its own (`atlarge1@` McKee,
--    `atlarge2@` Cooper), so for Hallowell they are the city's. Do not "correct" them.
--
-- ─── R9c: THE DEDUPE IS A GATE. ONE COLLISION, DECLARED. ─────────────────────────────────
-- Both predicates were run against prod on 2026-10-26 — exact (first_name, last_name) on
-- active rows, and a normalised `full_name` across all rows — plus an inactive-row sweep.
-- Each pass carried a control that FIRED (Emanuel Cleaver and Jared Golden for the active
-- passes; a known archived row for the inactive sweep), so the zeroes are measured, not
-- assumed.
--
--   Flavia DeBrito, Waterville Ward 2 — REUSE, pinned by UUID. She already sits in the
--   database as Maine House District 64. Her Maine Legislature member profile gives
--   Residence: Waterville, Town(s) Represented: Waterville, Winslow, and lists the
--   affiliation "City Council Waterville, Ward 2". She holds BOTH seats — the second
--   genuine two-seat holder in this programme, after Dani O'Halloran of Brewer (CC_0292).
--
-- The other 37 are `new`, and the migration REFUSES an undeclared collision rather than
-- silently reusing or silently duplicating.
--
-- ─── R4 / R4b: 37 UNKNOWN STARTS, AND ONE REAL DATE ──────────────────────────────────────
-- Every one of these five publishes a term-expiry column, and three publish a "term start"
-- beside it. 🔴 Neither dates anyone. An expiry is the end of a TERM, not of an occupancy —
-- writing it would silently un-seat people on 1 January. A published start is the latest
-- WIN, and a re-election never opens a new `office_terms` row, so for anyone re-elected it
-- publishes a false beginning.
--
-- 🟢 ONE seat passes R4b's test, which is not "how authoritative is the page?" but "did
--    something break continuity immediately before this date?":
--
--    Waterville, Mayor — Michael Morris, 2024-01-02, `day`, `elected`.
--    The city's Mayor page: "Michael Morris is the Mayor of the City of Waterville having
--    been elected in November 2023 for a 3-year term. Mayor Morris was inducted into office
--    on January 2, 2024." The city's own "History of Mayors" numbers him the 55th Mayor,
--    "2024-present", directly after "54. J Coelho — Mayor of Waterville, 2021-2023". That
--    second document is the control: it is what establishes this is a FIRST term and not a
--    re-election, which is the only thing that makes the date an occupancy start.
--    This is the first dated term start the Maine programme has written.
--
-- ⚠ TWO LEADS LEFT UNDATED, deliberately, and recorded in ROSTERS.md:
--    Hallowell At-Large 1, Walter McKee — won a SPECIAL municipal election on 2024-06-11
--      for a 1½-year term, which implies the seat was vacant. But the council page gives his
--      term as "January 2024 - January 2026", and the conflict is unresolved: no document
--      found says who vacated or when he was sworn. A special election is strong evidence of
--      a break in continuity; it is not evidence of the date occupancy began.
--    Hallowell Ward 3, Benjamin Gagnon — "September 2024 - January 2026" is an off-cycle
--      start in a city whose every other seat begins in January, which is the signature of
--      an appointment to fill a vacancy. The council minutes before October 2024 are not
--      published online, so the appointing document could not be read.
--    ▶ Both are seated `unknown` here. An unknown start is honest; a guessed one is not.
--
-- ─── R9b REMAINS TRUE IN THE OTHER DIRECTION ─────────────────────────────────────────────
-- Gardiner divides itself into four VOTING DISTRICTS and elects four of its eight members
-- from them (Art II §1, §2) — so its `District 1..4` titles are correct and its three
-- at-large seats are correct. Belfast, Saco and Waterville elect one councillor per ward.
-- The test is always the sentence about HOW COUNCILLORS ARE ELECTED, never the word "ward".
--
-- ─── ELECTED OFFICES WE DO NOT MODEL, AND MUST NOT INVENT ────────────────────────────────
-- Waterville voters also elect a Kennebec Water District Trustee and a Charter Commissioner
-- (Art IX); Belfast elects MSAD #34 directors, wardens and ward clerks; Hallowell elects an
-- RSU 2 Director. These are regional or administrative seats outside the city government we
-- model, exactly like Westbrook's Portland Water District Rep. Do not create offices for
-- them inside a seating migration.
--
-- ─── MEASUREMENT ─────────────────────────────────────────────────────────────────────────
-- Before (prod, 2026-10-26): offices_missing_terms = 335 total / 96 flagged / 239 unflagged.
-- After:                                             297 total / 58 flagged / 239 unflagged.
-- 🔴 UNFLAGGED MUST NOT MOVE. It is the baseline (CLAUDE.md); flagged rows were never in it.
--
-- ⚠ A Maine municipal election falls on 2026-11-03, eight days after this is written. Saco's
-- Wards 2, 4, 6 and Hallowell's Mayor and Wards 2, 4 are on that ballot, among others, and
-- Hallowell's Ward 5 councillor is running for Mayor. Some of these 38 will change. That is
-- not a reason to wait: the alternative is to keep asserting to voters in five cities that
-- all 38 seats are empty. A December re-check is recorded in ROSTERS.md.

BEGIN;

CREATE TEMP TABLE _roster (
  city              text NOT NULL,
  seat              text NOT NULL,
  office_id         uuid PRIMARY KEY,
  new_title         text NOT NULL,
  full_name         text NOT NULL,
  first_name        text NOT NULL,
  last_name         text NOT NULL,
  disposition       text NOT NULL CHECK (disposition IN ('new','reuse','new-despite-namesake')),
  pin_politician_id uuid,
  term_start        date,                      -- NULL for all but Waterville's Mayor
  start_precision   text NOT NULL DEFAULT 'unknown',
  how_started       text NOT NULL DEFAULT 'unknown',
  note              text,
  politician_id     uuid
) ON COMMIT DROP;

-- office_id is pinned by UUID, never by title: Hallowell's At-Large 3 is retitled below, so
-- matching on the old title would be order-dependent.
INSERT INTO _roster (city, seat, office_id, new_title, full_name, first_name, last_name,
                     disposition, pin_politician_id, term_start, start_precision, how_started, note) VALUES
  -- ── Belfast: 5 wards + a DIRECTLY ELECTED Mayor who sits on the council ────────────────
  ('Belfast','Mayor', 'a6b0984c-7a2d-4550-9a28-e78012396a0f','Mayor',
     'Eric Sanders','Eric','Sanders','new',NULL,NULL,'unknown','unknown',
     'charter Art V sec.1(b): the voters ballot for Mayor; Art II sec.2: the Mayor is ex officio president of the Council'),
  ('Belfast','Ward 1','ee790161-aa7e-458a-956b-1c19c3b6308d','Council Member (Ward 1)',
     'Mary Mortier','Mary','Mortier','new',NULL,NULL,'unknown','unknown',NULL),
  ('Belfast','Ward 2','a976e20a-35f3-4aaa-b727-f9e7184739a3','Council Member (Ward 2)',
     'Neal Harkness','Neal','Harkness','new',NULL,NULL,'unknown','unknown',NULL),
  ('Belfast','Ward 3','27d3db1e-b384-44fa-94f4-24f8751e7603','Council Member (Ward 3)',
     'Daniel Miller','Daniel','Miller','new',NULL,NULL,'unknown','unknown',NULL),
  ('Belfast','Ward 4','6f0db3bb-4e8b-471f-9356-0d3016002dc6','Council Member (Ward 4)',
     'Christopher Bitely','Christopher','Bitely','new',NULL,NULL,'unknown','unknown',NULL),
  ('Belfast','Ward 5','6c512565-3212-43af-8271-1a838066feb7','Council Member (Ward 5)',
     'Paul Dean','Paul','Dean','new',NULL,NULL,'unknown','unknown',NULL),

  -- ── Gardiner: 4 voting districts + 3 at-large + a DIRECTLY ELECTED Mayor ───────────────
  ('Gardiner','Mayor',     '92ad06ff-481f-475c-815e-a6ce6685e81a','Mayor',
     'Patricia Hart','Patricia','Hart','new',NULL,NULL,'unknown','unknown',
     'charter Art III sec.1: "A Mayor shall be elected by and from the qualified voters of the City"'),
  ('Gardiner','District 1','43ea3af3-22f0-4ea0-8184-454eb330b572','Council Member (District 1)',
     'Debra Kimball','Debra','Kimball','new',NULL,NULL,'unknown','unknown',NULL),
  ('Gardiner','District 2','96358159-089a-4eef-bb3e-9bd11e6204e5','Council Member (District 2)',
     'Veronica Babcock','Veronica','Babcock','new',NULL,NULL,'unknown','unknown',NULL),
  ('Gardiner','District 3','e4697724-30a7-4bfd-b5e3-69354097b92a','Council Member (District 3)',
     'Shawn Dolley','Shawn','Dolley','new',NULL,NULL,'unknown','unknown',NULL),
  ('Gardiner','District 4','05a16953-c5ac-4ce3-91ff-ea99de8b1969','Council Member (District 4)',
     'Kendall Holmes','Kendall','Holmes','new',NULL,NULL,'unknown','unknown',NULL),
  -- R6: Gardiner does not number its own at-large seats. 1/2/3 follow the city's listed
  -- order and carry NO meaning; all three represent the whole city identically.
  ('Gardiner','At-Large 1','c5800b65-009b-4c21-afae-4c2cda2d1dbe','Council Member (At-Large 1)',
     'Marc Cone','Marc','Cone','new',NULL,NULL,'unknown','unknown',NULL),
  ('Gardiner','At-Large 2','e06eae97-9f1e-4455-88a6-43f54ab2d83d','Council Member (At-Large 2)',
     'Timothy Cusick','Timothy','Cusick','new',NULL,NULL,'unknown','unknown',NULL),
  ('Gardiner','At-Large 3','73b941ea-3e0d-4937-8b51-a0fc259b5789','Council Member (At-Large 3)',
     'Russell Greenleaf','Russell','Greenleaf','new',NULL,NULL,'unknown','unknown',NULL),

  -- ── Hallowell: 🔴 5 wards + 2 at-large, NOT 4 + 3. At-Large 3 becomes Ward 5. ──────────
  ('Hallowell','Mayor',     '3d83d96c-156d-45da-8dce-a525367fa049','Mayor',
     'George Lapointe','George','Lapointe','new',NULL,NULL,'unknown','unknown',
     'the city styles him "George D Lapointe"; the Mayor is on the 2026-11-03 ballot, so the office is real'),
  ('Hallowell','At-Large 1','db402ff6-6e88-4113-b7dd-1af73b2dfce6','Council Member (At-Large 1)',
     'Walter McKee','Walter','McKee','new',NULL,NULL,'unknown','unknown',
     'the city numbers this seat itself: atlarge1@hallowellmaine.org. Won a SPECIAL election 2024-06-11 - a dating lead, refused here; see the header'),
  ('Hallowell','At-Large 2','a92f076a-425b-4858-ae8c-e48a6706bd6a','Council Member (At-Large 2)',
     'Scott Cooper','Scott','Cooper','new',NULL,NULL,'unknown','unknown',
     'the city numbers this seat itself: atlarge2@hallowellmaine.org'),
  ('Hallowell','Ward 1',    'de2e03d0-1ebd-4a0c-b188-c0e2e05ee5ec','Council Member (Ward 1)',
     'Karen Knox','Karen','Knox','new',NULL,NULL,'unknown','unknown','the city styles her "Karen M T Knox"'),
  ('Hallowell','Ward 2',    'fce99ce2-e0b4-4cd4-a110-155a12c90d32','Council Member (Ward 2)',
     'Michael Frett','Michael','Frett','new',NULL,NULL,'unknown','unknown',NULL),
  ('Hallowell','Ward 3',    'b7019be8-8f98-4ce9-aa15-496740bd7905','Council Member (Ward 3)',
     'Benjamin Gagnon','Benjamin','Gagnon','new',NULL,NULL,'unknown','unknown',
     'the 2025-11-04 return styles him "COOLIDGE GAGNON, BENJAMIN M"; the council roster and the 2026-08-10 minutes both say Gagnon. Off-cycle Sept-2024 start is a dating lead, refused here'),
  ('Hallowell','Ward 4',    '335f82ea-6fd2-4790-b94e-eacc43b74320','Council Member (Ward 4)',
     'Danielle Obery','Danielle','Obery','new',NULL,NULL,'unknown','unknown',NULL),
  -- 🔴 THE RETITLE. This office was `Council Member (At-Large 3)`; Hallowell has only two
  -- at-large seats and five wards, and Lauren McPherson is ward5@hallowellmaine.org.
  ('Hallowell','Ward 5',    'ddd23701-3366-4188-8ecb-6a567911956d','Council Member (Ward 5)',
     'Lauren McPherson','Lauren','McPherson','new',NULL,NULL,'unknown','unknown',
     'RETITLED from At-Large 3: charter sec.1(c) five wards, sec.2(a) two at-large. She is also a 2026 candidate for Mayor - a December re-check item'),

  -- ── Saco: 7 wards + a DIRECTLY ELECTED Mayor; the Deputy Mayor is a rotating role ──────
  ('Saco','Mayor', 'be2dfd90-1a9c-4815-b602-e645063eb07d','Mayor',
     'Jodi MacPhail','Jodi','MacPhail','new',NULL,NULL,'unknown','unknown',
     'charter sec.2.05(a): "The Mayor shall be elected by the voters of the entire City"'),
  ('Saco','Ward 1','cd0ef807-7761-4a48-92d9-31ed645146a3','Council Member (Ward 1)',
     'Douglas Edwards','Douglas','Edwards','new',NULL,NULL,'unknown','unknown',NULL),
  ('Saco','Ward 2','8dda51a2-b1ed-4932-bcda-0c95c7cd01f8','Council Member (Ward 2)',
     'Joshua Parks','Joshua','Parks','new',NULL,NULL,'unknown','unknown','the city styles him "Joshua D. Parks"'),
  ('Saco','Ward 3','4f23e204-45db-4579-9622-0167210c5827','Council Member (Ward 3)',
     'Sandra Guay','Sandra','Guay','new',NULL,NULL,'unknown','unknown',NULL),
  ('Saco','Ward 4','243912c6-de49-40ed-bbce-410ab6cf47d2','Council Member (Ward 4)',
     'Jeffrey Onnen','Jeffrey','Onnen','new',NULL,NULL,'unknown','unknown',
     'won Ward 4 on 2025-11-04, 696 to Donald E. Pilon 510 (city clerk''s official return)'),
  ('Saco','Ward 5','f689260f-7f0b-4568-b28e-f46457e82dde','Council Member (Ward 5)',
     'William Gayle','William','Gayle','new',NULL,NULL,'unknown','unknown',NULL),
  ('Saco','Ward 6','882ee783-e4d3-4ac3-8a91-dab54a018493','Council Member (Ward 6)',
     'Tricia Huot','Tricia','Huot','new',NULL,NULL,'unknown','unknown',NULL),
  ('Saco','Ward 7','3c361a2d-99b5-407f-9e96-a1c24d9b6626','Council Member (Ward 7)',
     'Nathan Johnston','Nathan','Johnston','new',NULL,NULL,'unknown','unknown','the city styles him "Nathan D. Johnston"'),

  -- ── Waterville: 7 wards + a DIRECTLY ELECTED Mayor who is NOT a council member ─────────
  -- 🟢 The one dated seat in this wave. See the header for why this date, and only this one.
  ('Waterville','Mayor', 'c9730b77-2100-4fc2-bcd9-1122f3671505','Mayor',
     'Michael Morris','Michael','Morris','new',NULL,DATE '2024-01-02','day','elected',
     'Waterville''s 55th Mayor, inducted 2024-01-02, succeeding J Coelho (2021-2023). The city''s History of Mayors is the control that proves a FIRST term'),
  ('Waterville','Ward 1','0731090f-2071-48d8-8a80-d79eb930b311','Council Member (Ward 1)',
     'Brandon Gilley','Brandon','Gilley','new',NULL,NULL,'unknown','unknown',
     'listed as "Ward 1 City Councilor, Council Chair" - the Chair is a ROTATING ROLE and correctly not an office'),
  -- 🔴 REUSE. Already present as Maine House District 64; her legislature profile lists the
  -- affiliation "City Council Waterville, Ward 2" and Residence: Waterville. Two real seats.
  ('Waterville','Ward 2','25c5fc9d-1f9c-41ce-9783-ac2cb34b77a5','Council Member (Ward 2)',
     'Flavia DeBrito','Flavia','DeBrito','reuse','21f45688-4e19-42bb-b1c0-e17b5dba2d3a',NULL,'unknown','unknown',
     'also Maine House District 64 - a GENUINE second seat, not a duplicate row'),
  ('Waterville','Ward 3','ff131e01-f99d-4dd1-ac8e-f775fae56ed5','Council Member (Ward 3)',
     'Samantha Burdick','Samantha','Burdick','new',NULL,NULL,'unknown','unknown',
     'the 2025-11-04 return styles her "Burdick, Samantha Ann"'),
  ('Waterville','Ward 4','5173b827-ba97-4a27-83f9-ab6d4baf459e','Council Member (Ward 4)',
     'Rebecca Green','Rebecca','Green','new',NULL,NULL,'unknown','unknown',NULL),
  ('Waterville','Ward 5','698b7f15-617b-4900-b47c-87107b04dcf3','Council Member (Ward 5)',
     'Spencer Krigbaum','Spencer','Krigbaum','new',NULL,NULL,'unknown','unknown',
     'elected 2025-11-04, succeeding Kenneth Gagnon who won the 2024-04-02 Ward 5 special election'),
  ('Waterville','Ward 6','bd9dfa3d-23da-4d34-b8a9-d8810c286b4f','Council Member (Ward 6)',
     'Scott Beale','Scott','Beale','new',NULL,NULL,'unknown','unknown',NULL),
  ('Waterville','Ward 7','27c16aca-a28c-46fd-bce7-c98a1b79297b','Council Member (Ward 7)',
     'Cathy Herard','Cathy','Herard','new',NULL,NULL,'unknown','unknown',NULL);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_txt text;
BEGIN
  -- every office_id resolves, and to the right city's City Council
  SELECT count(*) INTO n FROM _roster r
    JOIN essentials.offices o     ON o.id = r.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of ' || r.city || ', Maine, US' AND c.name = 'City Council';
  IF n <> 38 THEN RAISE EXCEPTION 'CC_0293: % of 38 office_ids resolve to the named Maine city council', n; END IF;

  -- and the five cities hold EXACTLY these 38 offices and no others
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Belfast, Maine, US','City of Gardiner, Maine, US',
                    'City of Hallowell, Maine, US','City of Saco, Maine, US',
                    'City of Waterville, Maine, US');
  IF n <> 38 THEN RAISE EXCEPTION 'CC_0293: the five cities hold % offices, expected 38 - the roster is stale', n; END IF;

  -- nothing may already be seated
  SELECT count(*) INTO bad FROM _roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0293: % office(s) already carry a term', bad; END IF;

  -- the skeleton signature (R1): all 38 flagged, none dated
  SELECT count(*) INTO bad FROM _roster r
    JOIN essentials.offices o ON o.id = r.office_id
   WHERE NOT (o.is_vacant AND o.vacant_since IS NULL);
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0293: % office(s) are not flagged-without-a-date - that is not the Maine '
                    'skeleton shape, read the row before seating', bad;
  END IF;

  -- 🔴 the mayoral premise, stated before it is acted on: five mayoral offices exist today
  -- and all five are REAL, so all five must survive. CC_0292 deleted six; this wave deletes none.
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title ILIKE '%mayor%'
     AND g.name IN ('City of Belfast, Maine, US','City of Gardiner, Maine, US',
                    'City of Hallowell, Maine, US','City of Saco, Maine, US',
                    'City of Waterville, Maine, US');
  IF n <> 5 THEN
    RAISE EXCEPTION 'CC_0293: expected 5 mayoral offices across the five cities, found % '
                    '- re-read each charter before proceeding', n;
  END IF;

  -- 🔴 the retitle premise: Hallowell holds an At-Large 3 today and no Ward 5
  PERFORM 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Hallowell, Maine, US' AND o.title = 'Council Member (At-Large 3)';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0293: Hallowell has no "Council Member (At-Large 3)" to retitle - '
                    'somebody has already changed it, re-read the city before proceeding';
  END IF;
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Hallowell, Maine, US' AND o.title = 'Council Member (Ward 5)';
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0293: Hallowell already has a Ward 5 seat'; END IF;

  -- every declared reuse must point at a real, active person whose name matches
  SELECT string_agg(r.full_name, ', ') INTO v_txt FROM _roster r
   WHERE r.disposition = 'reuse'
     AND NOT EXISTS (SELECT 1 FROM essentials.politicians p
                      WHERE p.id = r.pin_politician_id AND p.is_active
                        AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
                        AND lower(btrim(p.last_name))  = lower(btrim(r.last_name)));
  IF v_txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0293: pinned reuse does not resolve: %', v_txt; END IF;

  -- and every declared namesake must actually exist, or the declaration is stale
  SELECT string_agg(r.full_name, ', ') INTO v_txt FROM _roster r
   WHERE r.disposition = 'new-despite-namesake'
     AND NOT EXISTS (SELECT 1 FROM essentials.politicians p
                      WHERE p.is_active
                        AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
                        AND lower(btrim(p.last_name))  = lower(btrim(r.last_name)));
  IF v_txt IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0293: % was declared a namesake collision and no namesake exists - the '
                    'declaration is stale, re-run the dedupe', v_txt;
  END IF;

  -- R4: exactly one seat may carry a date, and it must be Waterville's Mayor
  SELECT string_agg(city || ' ' || seat, ', ' ORDER BY city, seat) INTO v_txt
    FROM _roster WHERE term_start IS NOT NULL;
  IF v_txt IS DISTINCT FROM 'Waterville Mayor' THEN
    RAISE EXCEPTION 'CC_0293: dated seats are [%], expected only "Waterville Mayor" - a published '
                    'term expiry or latest win cannot establish continuous occupancy', coalesce(v_txt,'none');
  END IF;
END $$;

-- ─── 🔴 Retitle: Hallowell's phantom third at-large seat becomes the ward seat it is ─────
UPDATE essentials.offices o SET title = r.new_title
  FROM _roster r WHERE o.id = r.office_id AND o.title IS DISTINCT FROM r.new_title;

-- ─── People ──────────────────────────────────────────────────────────────────────────────
-- 🔴 Resolved one row at a time. An UNDECLARED collision is fatal — a (first_name, last_name)
-- resolver cannot tell "the same person holds two seats" from "two different people share a
-- name", and those two resolve OPPOSITE ways (R9c).
-- 🔴 is_incumbent EXPLICITLY true: it defaults to false, and a seated person inserted without
-- it is hidden from address search (CLAUDE.md).
DO $$
DECLARE r record; c int; new_id uuid; src text;
BEGIN
  FOR r IN SELECT * FROM _roster ORDER BY city, seat LOOP
    src := 'City of ' || r.city || ', Maine official roster, read 2026-10-26 (CC_0293)';

    IF r.disposition = 'reuse' THEN
      UPDATE _roster SET politician_id = r.pin_politician_id WHERE office_id = r.office_id;
      -- a reused person must still be flagged an active incumbent
      UPDATE essentials.politicians SET is_incumbent = true
       WHERE id = r.pin_politician_id AND is_incumbent IS DISTINCT FROM true;
      CONTINUE;
    END IF;

    SELECT count(*) INTO c FROM essentials.politicians p
     WHERE p.is_active
       AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
       AND lower(btrim(p.last_name))  = lower(btrim(r.last_name));

    IF c > 0 AND r.disposition <> 'new-despite-namesake' THEN
      RAISE EXCEPTION 'CC_0293: % (% %) collides with % active row(s) and the roster did not '
                      'declare it - read the row and choose reuse or new-despite-namesake',
                      r.full_name, r.city, r.seat, c;
    END IF;

    -- No row in this wave needs it, but the mechanism stays: the exemption is opened for ONE
    -- insert and closed again, never for a whole migration.
    IF r.disposition = 'new-despite-namesake' THEN
      PERFORM set_config('essentials.allow_duplicate_name', 'on', true);
    END IF;

    INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, true, src)
    RETURNING id INTO new_id;

    PERFORM set_config('essentials.allow_duplicate_name', 'off', true);

    UPDATE _roster SET politician_id = new_id WHERE office_id = r.office_id;
  END LOOP;
END $$;

-- ─── Seat them ───────────────────────────────────────────────────────────────────────────
-- 37 are unknown-start, so they cannot go through `seat_officeholder` — it refuses a NULL
-- term_start by design. Safe here only because no seat has a predecessor to close.
-- The one DATED seat does go through the helper, which is the house rule for a real date.
DO $$
DECLARE r record; n int := 0; src text;
BEGIN
  FOR r IN SELECT * FROM _roster ORDER BY city, seat LOOP
    IF r.politician_id IS NULL THEN
      RAISE EXCEPTION 'CC_0293: % % did not resolve to a person', r.city, r.seat;
    END IF;

    IF r.term_start IS NOT NULL THEN
      PERFORM essentials.seat_officeholder(
        r.office_id, r.politician_id, r.term_start,
        'City of ' || r.city || ', Maine - Mayor page and History of Mayors, read 2026-10-26 '
        || '(CC_0293); inducted into office on this date as the city''s 55th Mayor, succeeding '
        || 'a different person, so it is the start of CONTINUOUS OCCUPANCY and not a term label',
        r.how_started, r.start_precision);
    ELSE
      INSERT INTO essentials.office_terms
        (office_id, politician_id, term_start, start_precision, how_started, source)
      VALUES (r.office_id, r.politician_id, NULL, r.start_precision, r.how_started,
              'City of ' || r.city || ', Maine official roster, read 2026-10-26 (CC_0293); '
              || 'start_precision unknown - the published "Term Expires" is the end of a TERM, '
              || 'not of an occupancy, and a published start date is the LATEST win, which a '
              || 're-election does not reset');
    END IF;
    n := n + 1;
  END LOOP;
  IF n <> 38 THEN RAISE EXCEPTION 'CC_0293: expected 38 seatings, got %', n; END IF;
END $$;

-- ─── 🔴 Clear the flag on exactly the seats filled, in the SAME transaction (R2) ─────────
UPDATE essentials.offices o SET is_vacant = false, vacant_since = NULL
  FROM _roster r WHERE o.id = r.office_id AND o.is_vacant;

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_unflagged int; v_total int; v_txt text;
BEGIN
  SELECT count(*) INTO n FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id AND t.politician_id = r.politician_id;
  IF n <> 38 THEN RAISE EXCEPTION 'CC_0293: expected 38 terms, found %', n; END IF;

  -- 🔴 all five mayoral offices survive, named explicitly. R9 was asked and answered KEEP
  -- five times; a wave that silently deleted one would be CC_0292's error inverted.
  SELECT string_agg(g.name || ' / ' || o.title, ', ' ORDER BY g.name) INTO v_txt
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title ILIKE '%mayor%'
     AND g.name IN ('City of Belfast, Maine, US','City of Gardiner, Maine, US',
                    'City of Hallowell, Maine, US','City of Saco, Maine, US',
                    'City of Waterville, Maine, US');
  IF v_txt IS DISTINCT FROM 'City of Belfast, Maine, US / Mayor, City of Gardiner, Maine, US / Mayor, '
                         || 'City of Hallowell, Maine, US / Mayor, City of Saco, Maine, US / Mayor, '
                         || 'City of Waterville, Maine, US / Mayor' THEN
    RAISE EXCEPTION 'CC_0293: mayoral offices across the five cities are [%], expected all five', v_txt;
  END IF;

  -- 🔴 and no rotating role became a seat: Waterville's Council Chair, Saco's Deputy Mayor
  SELECT string_agg(DISTINCT o.title, ', ') INTO v_txt FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE (o.title ILIKE '%chair%' OR o.title ILIKE '%president%' OR o.title ILIKE '%deputy%'
          OR o.title ILIKE '%vice%')
     AND g.name IN ('City of Belfast, Maine, US','City of Gardiner, Maine, US',
                    'City of Hallowell, Maine, US','City of Saco, Maine, US',
                    'City of Waterville, Maine, US');
  IF v_txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0293: a rotating role was made into a seat: %', v_txt; END IF;

  -- 🔴 the whole shape of all five councils, in one string, against each charter
  SELECT string_agg(x.city || '=' || x.w || 'W/' || x.d || 'D/' || x.a || 'A/' || x.m || 'M',
                    ', ' ORDER BY x.city) INTO v_txt
    FROM (
      SELECT replace(replace(g.name, 'City of ', ''), ', Maine, US', '') AS city,
             count(*) FILTER (WHERE o.title LIKE 'Council Member (Ward %')     AS w,
             count(*) FILTER (WHERE o.title LIKE 'Council Member (District %') AS d,
             count(*) FILTER (WHERE o.title LIKE 'Council Member (At-Large %') AS a,
             count(*) FILTER (WHERE o.title = 'Mayor')                         AS m
        FROM essentials.offices o
        JOIN essentials.chambers c ON c.id = o.chamber_id
        JOIN essentials.governments g ON g.id = c.government_id
       WHERE g.name IN ('City of Belfast, Maine, US','City of Gardiner, Maine, US',
                        'City of Hallowell, Maine, US','City of Saco, Maine, US',
                        'City of Waterville, Maine, US')
       GROUP BY 1) x;
  IF v_txt IS DISTINCT FROM 'Belfast=5W/0D/0A/1M, Gardiner=0W/4D/3A/1M, Hallowell=5W/0D/2A/1M, '
                         || 'Saco=7W/0D/0A/1M, Waterville=7W/0D/0A/1M' THEN
    RAISE EXCEPTION 'CC_0293: council shapes are [%], which disagrees with the charters '
                    '(W=ward, D=district, A=at-large, M=mayor)', v_txt;
  END IF;

  SELECT count(*) INTO bad FROM _roster r JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0293: % seated person(s) are not active incumbents', bad; END IF;

  -- R4: exactly one term is dated, and it is Waterville's Mayor on 2024-01-02
  SELECT count(*) INTO bad FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id
   WHERE t.term_start IS NOT NULL OR t.start_precision <> 'unknown';
  IF bad <> 1 THEN
    RAISE EXCEPTION 'CC_0293: % term(s) carry a date, expected exactly 1 - a published term expiry '
                    'cannot establish continuous occupancy, and writing one un-seats people '
                    'on 1 January', bad;
  END IF;
  SELECT count(*) INTO bad FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id
   WHERE r.city = 'Waterville' AND r.seat = 'Mayor'
     AND t.term_start = DATE '2024-01-02' AND t.start_precision = 'day'
     AND t.how_started = 'elected' AND t.term_end IS NULL;
  IF bad <> 1 THEN
    RAISE EXCEPTION 'CC_0293: Waterville''s Mayor is not seated from 2024-01-02 day/elected and open-ended';
  END IF;

  -- 🔴 R4's own trap, asserted directly: nothing anywhere in the five carries a term_end.
  -- Writing a published "Term Expires" here would silently un-seat people on 1 January.
  SELECT count(*) INTO bad FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id
   WHERE t.term_end IS NOT NULL;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0293: % term(s) carry a term_end', bad; END IF;

  -- the reuse really did reuse: Flavia DeBrito holds two seats on ONE politician row
  SELECT count(*) INTO n FROM essentials.office_terms t
   WHERE t.politician_id = '21f45688-4e19-42bb-b1c0-e17b5dba2d3a';
  IF n <> 2 THEN
    RAISE EXCEPTION 'CC_0293: Flavia DeBrito holds % term(s), expected 2 (Maine House 64 + Waterville Ward 2)', n;
  END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE is_active AND lower(first_name) = 'flavia' AND lower(last_name) = 'debrito';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0293: % active Flavia DeBrito rows - the reuse created a duplicate', n; END IF;

  -- R2 gate 1: nothing in the five is still flagged vacant
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.is_vacant
     AND g.name IN ('City of Belfast, Maine, US','City of Gardiner, Maine, US',
                    'City of Hallowell, Maine, US','City of Saco, Maine, US',
                    'City of Waterville, Maine, US');
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0293: % office(s) in the five are still flagged vacant', bad; END IF;

  -- R2 gate 2: nothing unflagged-and-unseated (a new me|LOCAL DEAD_GEOGRAPHY bucket)
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE NOT o.is_vacant
     AND g.name IN ('City of Belfast, Maine, US','City of Gardiner, Maine, US',
                    'City of Hallowell, Maine, US','City of Saco, Maine, US',
                    'City of Waterville, Maine, US')
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0293: % office(s) are unflagged AND unseated - a new me|LOCAL '
                    'DEAD_GEOGRAPHY bucket that will redden the reachability gate', bad;
  END IF;

  -- the global invariant: zero seated-and-flagged, repo-wide
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.is_vacant AND och.politician_id IS NOT NULL;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0293: % office(s) are seated AND flagged - the is_vacant trap', bad; END IF;

  -- 🟢 THE FINISH LINE: no Maine city government may hold a flagged-undated office any more.
  -- `South Portland Public Schools` keeps its DATED April-2026 vacancy and Brewer keeps its
  -- DATED 2026-08-12 one; those are real and are what the flag is for.
  -- Keyed on the government NAME, not on a districts join: an office with a NULL district_id
  -- would silently drop out of the join and the gate would pass vacuously.
  SELECT string_agg(DISTINCT g.name, ', ') INTO v_txt FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.is_vacant AND o.vacant_since IS NULL
     AND g.name LIKE 'City of %, Maine, US';
  IF v_txt IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0293: Maine cities still holding an undated vacancy flag: % - the '
                    'skeleton was supposed to be finished by this migration', v_txt;
  END IF;

  -- R3: total falls by 38, unflagged does NOT move
  SELECT count(*) FILTER (WHERE NOT o.is_vacant), count(*) INTO v_unflagged, v_total
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 239 THEN
    RAISE EXCEPTION 'CC_0293: unflagged offices_missing_terms is %, expected the 239 baseline', v_unflagged;
  END IF;
  IF v_total <> 297 THEN
    RAISE EXCEPTION 'CC_0293: total offices_missing_terms is %, expected 335 - 38 = 297', v_total;
  END IF;

  RAISE NOTICE 'CC_0293 OK - 38 seated across the last 5 Maine cities, Hallowell At-Large 3 '
               'retitled Ward 5, all 5 mayoralties verified real; missing_terms 297/58/239';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT THIS WAVE ADDS (R10 in ROSTERS.md): A VERIFICATION RULE EARNS ITS KEEP ON THE RUNS
-- WHERE IT FINDS NOTHING, TOO.
-- R9 was written because six of nine cities failed it. Asked of these five, it passed five
-- times — and that is the result, not a wasted pass. Had it been skipped as "probably fine
-- for ward cities", R8 would still have caught Hallowell, but nobody would have been able to
-- say that Belfast's or Saco's mayoralty had ever been read.
-- ▶ A clean result is only worth having if the check could have come back dirty. Record the
--   clean ones with the same care as the defects, and name the sentence that cleared them.
--
-- 🔴 AND THE ONE THAT CAME BACK DIRTY: Hallowell is Bath again, nine cities later. Both were
-- found the same way — by trying to match PEOPLE to SEATS and running out of seats of the
-- right kind. Neither the office count, the chamber, the district nor any gate in this repo
-- would ever have reported it. ▶ Seating a city is the audit; there is no cheaper one.
