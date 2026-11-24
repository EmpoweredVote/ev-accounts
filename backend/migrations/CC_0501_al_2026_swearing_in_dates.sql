-- CC_0501 — Alabama: the start date for the 13 offices won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE FIRST MONDAY AFTER THE SECOND TUESDAY IN JANUARY — 2027-01-18
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-18  Governor · Lieutenant Governor · Attorney General · Auditor ·
--               Secretary of State · Treasurer · Commissioner of Agriculture
--               and Industries                                   (7)  Ala. Const. 2022, § 116
--   2027-01-18  Public Service Commissioner, Places 1 and 2       (2)  Code of Ala. § 37-1-3(c)(1)
--   2027-01-18  State Board of Education, Districts 2, 4, 6, 8    (4)  Code of Ala. § 16-3-1
--
-- Sourced 2026-11-22 and every section re-read 2026-11-24 through ALISON, the Alabama
-- Legislature's own system; the write-up is in backend/data/state-seating-2026/DATES.md § AL.
-- This file writes the dates and seats nobody: CC_0502 seats.
--
-- 🟢 **THERE IS NO PEOPLE FILE.** All 13 winner rows already carry a politician_id, every one of
--   those rows is active, and none collides on either (full_name) or (first_name, last_name) —
--   measured 2026-11-24. Arizona was the first state in this pass to need no people file;
--   Alabama is the second. (Nevada needed 1 of 13, Maine 18 of 77, Maryland 25 of 85.)
--
-- 🟢 **AND NO RULING A.** Every one of the 13 races is single-seat with exactly one winner, so
--   each winner is seated into the office that carried their own race. There is no sibling
--   expansion here, and this file dates 13 offices because 13 offices carry a race. P3 measures
--   that rather than assuming it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITIES, EACH QUOTED, EACH SAYING THE SAME THING IN NEARLY THE SAME WORDS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   Ala. Const. 2022, § 116 — *Governor, Lieutenant Governor, Attorney General, State Auditor,
--     Secretary of State, State Treasurer, and Commissioner of Agriculture and Industries —
--     Term of Office; Officers May Succeed Selves for One Additional Term*:
--     "The governor, lieutenant governor, attorney general, state auditor, secretary of state,
--      state treasurer, and commissioner of agriculture and industries, shall hold their
--      respective offices for the term of four years FROM THE FIRST MONDAY AFTER THE SECOND
--      TUESDAY IN JANUARY next succeeding their election and until their successors shall be
--      elected and qualified."
--
--   Code of Alabama § 16-3-1 — *Composition; Election; Term of Office*:
--     "Each member shall hold office FROM THE FIRST MONDAY AFTER THE SECOND TUESDAY IN JANUARY
--      next after his or her election and until his or her successor is elected and qualified."
--
--   Code of Alabama § 37-1-3(c)(1):
--     "All commissioners who are elected after June 1, 2026, shall serve terms of six years that
--      BEGIN ON THE FIRST MONDAY AFTER THE SECOND TUESDAY IN JANUARY following the general
--      election."
--
-- ⚠ § 116 and § 16-3-1 both add "and until his or her successor is elected and qualified". That
--   is the familiar HOLDOVER clause, which attaches to the END of the predecessor's term, not to
--   the start of this one. It does not make these terms begin at qualification — contrast
--   Nevada's six executives (CC_0465), refused because their terms begin ON qualification.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE CONTROL IS THE LEGISLATURE'S OWN ARITHMETIC, WRITTEN OUT AS A CALENDAR DATE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- § 37-1-3(b)(2), describing the four commissioners the Governor appoints to expand the
-- commission, says they
--
--     "serve initial terms BEGINNING JANUARY 18, 2027".
--
-- 🔴 **ALABAMA'S LEGISLATURE APPLIED ITS OWN FORMULA TO THIS EXACT CYCLE, IN WORDS, AND GOT
--   2027-01-18** — the same answer the formula gives here. That is a stronger control than any
--   aggregator and stronger than any row in our own data, because it is the body that wrote the
--   rule applying it to the cycle this file writes. It is quoted in the `source` of all 13 rows.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS RULE LANDS ON A DIFFERENT ORDINAL MONDAY IN DIFFERENT YEARS, SO "THE Nth MONDAY" IS
--      NOT A SHORTHAND FOR IT — AND THE SHORTHAND IS RIGHT SEVEN CYCLES OUT OF EIGHT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Computed over Alabama's own quadrennial cycles (2026-11-24, arithmetic only, no data):
--
--   cycle  Jan 1   2nd Tuesday   THE RULE     3rd Monday    agree?   1st Monday  2nd Monday
--   2003   Wed     01-14         2003-01-20   2003-01-20    yes      01-06       01-13
--   2007   Mon     01-09         2007-01-15   2007-01-15    yes      01-01       01-08
--   2011   Sat     01-11         2011-01-17   2011-01-17    yes      01-03       01-10
--   2015   Thu     01-13         2015-01-19   2015-01-19    yes      01-05       01-12
--   2019   Tue     01-08         2019-01-14   2019-01-21    🔴 NO    01-07       01-14
--   2023   Sun     01-10         2023-01-16   2023-01-16    yes      01-02       01-09
--   2027   Fri     01-12         2027-01-18   2027-01-18    yes      01-04       01-11
--   2031   Wed     01-14         2031-01-20   2031-01-20    yes      01-06       01-13
--
-- 🔴 **IN 2027 THE RULE COINCIDES WITH THE THIRD MONDAY; IN 2019 IT COINCIDED WITH THE SECOND.**
--   When January 1st is itself a Tuesday the second Tuesday falls on the 8th and the first Monday
--   after it is the 14th — the SECOND Monday, a full week before the third. So a reader who
--   writes down "Alabama inaugurates on the third Monday in January" is right in seven of these
--   eight cycles and wrong in 2019, the cycle Alabama actually inaugurated on 2019-01-14.
--   ▶ The day is COMPUTED from the second Tuesday in assertion 3a and never typed, and 3b
--   computes the third-Monday look-alike beside it in the year it agrees AND the year it does
--   not — which separates the two rules instead of merely agreeing with one of them this cycle.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ALABAMA'S DAY IS EMPTY AND BOTH NEAR-MISS MONDAYS CARRY 427 OTHER SEATS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24, before this file:
--
--   2027-01-04  the FIRST Monday   234 rows  az-const-first-monday-january (94),
--                                            wi-legislature-first-monday (116),
--                                            wi-state-exec-first-monday (5), two Wisconsin
--                                            county rules (2),
--                                            ca-const-art2-s20-monday-after-january-1 (7),
--                                            ca-const-vi-16c (4), ca-water-principal-act (6)
--   2027-01-11  the SECOND Monday  193 rows  wa-rcw-44-04-021-second-monday-january (118),
--                                            or-const-art4-s4-second-monday-january (75)
--   2027-01-12  the SECOND TUESDAY   0 rows  the ANCHOR this rule counts FROM, never the answer
--   2027-01-18  THE RULE             0 rows  🟢 ALABAMA IS THE FIRST STATE ON THIS DAY
--
-- 🟢 So the delta on 2027-01-18 is 0 -> 13 and needs no other state named. ⚠ **That is a fact
--   about today, not a property of the day**, so assertion 4 still requires every row on it to be
--   an Alabama row under this file's rule_id — a second state landing here must be named rather
--   than absorbed. Washington and Oregon paid for the absorbing version on 2027-01-11 (CC_0491
--   P5, CC_0493 P10) and Arizona on 2027-01-04 (CC_0497 P6).
--
-- 🔴 And reaching one or two Mondays short of the right answer in Alabama does not produce an
--   absurd day: it produces the real term start of 234 or 193 seats in five other states.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THERE IS A FOURTH ALABAMA RULE, IT NAMES A DIFFERENT DAY, AND THAT DAY IS ALREADY PAST
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Ala. Const. 2022, § 46(a) — *Election and Terms of Office of Senators and Representatives*:
--
--     "Senators and representatives shall be elected by the qualified electors on the first
--      Tuesday after the first Monday in November … and in every fourth year thereafter. **The
--      terms of office of the senators and representatives shall commence ON THE DAY AFTER THE
--      GENERAL ELECTION at which they are elected**, and expire on the day after the general
--      election held in the fourth year after their election … In the year nineteen hundred and
--      six, and in every fourth year thereafter, all the senators and representatives shall be
--      elected."
--
-- 🔴 **SO THE ALABAMA LEGISLATURE'S 2026 TERMS BEGAN ON 2026-11-04, SEVENTY-FIVE DAYS BEFORE
--   THIS FILE'S DAY.** 1906 + 30 four-year cycles = 2026, so all 35 Senate seats and all 105
--   House seats were on this ballot as a matter of law. Alabama counts FORWARD from the election,
--   like Nevada (Nev. Const. art. 4 §§ 3, 4) and Indiana (Ind. Const. art. 4 § 3) and unlike
--   Maine, which counts back.
--
-- ▶ **THIS IS UTAH'S LESSON IN A STATE THAT CAN AFFORD IT LESS.** Two elected bodies in one
--   state need not share a boundary, and borrowing is the mistake — and the body missing here
--   would be borrowing a date 75 days too late, for 140 seats. The clause is written out above
--   so that whoever seeds the Alabama legislature inherits 2026-11-04 and § 46(a) rather than
--   re-deriving them, or worse, assuming this file's day covers the whole state.
--
-- 🔴🔴 **AND THE REASON IT DOES NOT BLOCK THIS WAVE IS THAT WE HOLD NO ALABAMA LEGISLATURE AT
--   ALL.** Measured 2026-11-24: Alabama holds 7 NATIONAL_LOWER, 5 NATIONAL_UPPER, 10 STATE_EXEC
--   and 8 STATE_BOARD_EDUCATION office rows and **ZERO STATE_UPPER and ZERO STATE_LOWER rows**.
--   Not an unrecorded result and not an empty race — *the offices do not exist*. That is
--   CLAUDE.md's **an office with no term is invisible and nothing errors**, reached from the
--   seeding side and at the largest scale this pass has found: Arizona was missing one office
--   (its Lieutenant Governor, CC_0497), Alabama is missing 140. ▶ It is a SEEDING job, it belongs
--   to the results and seeding programme, and this file does not invent a row. P4 refuses to run
--   if one has appeared and assertion 3d pins the absence, so the next reader finds this
--   paragraph rather than re-deriving § 46(a).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE PUBLIC SERVICE COMMISSION — TWO SEATS WERE UP, AND THE STATUTE SAYS SO TWICE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- We hold three PSC office rows: `Public Service Commission President` (not pending) and
-- `Places 1` and `2` (both pending). § 37-1-3 settles that split from the law rather than from
-- our data, which is what makes it a fact instead of an assumption:
--
--   (a)(2)   "at the general election held in November 1942, and every four years thereafter
--             UNTIL THE GENERAL ELECTION HELD IN NOVEMBER 2026, TWO ASSOCIATES, who, with the
--             president, shall constitute the commission, shall be elected" — and the president
--             "every four years thereafter UNTIL THE GENERAL ELECTION HELD IN NOVEMBER 2028".
--   (b)(3)a  "At the general election held in November 2026, TWO commissioners shall be elected
--             in the same manner as commissioners were elected before June 1, 2026."
--
-- 🟢 **TWO SEATS, AND THE PRESIDENT'S NEXT ELECTION IS 2028.** So "the President is not pending"
--   is the correct state of our data and not a missing result. Assertion 3e pins it.
--
-- ▶ **DATED FOLLOW-UP, 2027-01-18 — THE COMMISSION BECOMES SEVEN SEATS AND WE MODEL THREE.**
--   § 37-1-3(b)(1) expands it so each commissioner represents a congressional district, and
--   (b)(2) has the Governor appoint FOUR commissioners "to serve initial terms beginning January
--   18, 2027" — this file's own day. Those four are appointees, not election winners, so no 2026
--   wave reaches them and none is created here. ⚠ **Do not rename or re-district Places 1 and 2
--   now**: (b)(3)a elects the 2026 pair "in the same manner as commissioners were elected before
--   June 1, 2026", so the at-large shape is correct for this cycle. (b)(3)b–d then move the body
--   to districts across 2028–2032, and (e) replaces the elected President with one the
--   commissioners choose "starting with the term elected in November 2028".
--
-- 🔴 **AND THE TWO SEATS THIS FILE DATES CARRY SIX-YEAR TERMS, NOT FOUR** — § 37-1-3(c)(1),
--   quoted above, applies to "all commissioners who are elected after June 1, 2026", while
--   (a)(1) gives four years only to those "serving on or before June 1, 2026". This file writes
--   only a start date and CC_0502 writes only a `term_start`, so nothing here depends on the
--   length; it is recorded because the next reader of these rows will need it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THE BOARD OF EDUCATION'S STAGGERING IS NOT IN LAW, SO "FOUR OF EIGHT" CANNOT BE PROVED HERE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- § 16-3-1 gives the board "eight members elected from districts provided by general law … for
-- terms of four years each", each elected "at the general election immediately preceding the
-- expiration of the term of office of the member, **AS DESIGNATED BY THE BOARD**, representing
-- such district".
--
-- 🔴 **THE STATUTE DELEGATES THE STAGGERING TO THE BOARD ITSELF AND NAMES NO DISTRICT.** So
--   unlike Arizona's House (Art. IV, Pt. 2 § 1(1) elects two Representatives from each of thirty
--   districts, which turned "two seats are missing" into a certainty) and unlike § 46(a) above,
--   the law here cannot say how many board seats should have been on the 2026 ballot. § 16-3-1.1
--   is the district map and answers only geography.
--
-- ⚠ **AND THE COMPLEMENTARY CHECK IS STRUCTURALLY UNAVAILABLE**: we hold no Alabama race at all
--   before 2026, and 17 of our 18 Alabama state terms carry `term_start IS NULL`
--   (`start_precision = 'unknown'`), the one exception being Kay Ivey's 2017-04-10 accession. So
--   neither "which districts were up last time" nor "when did the sitting members start" can be
--   asked of our own data. ▶ **An unavailable check is a finding and is recorded beside the ones
--   that passed** — Oregon's CC_0491 is the precedent.
--
-- What IS known: four districts (2, 4, 6, 8) carry a 2026 race with a recorded winner and four
-- (1, 3, 5, 7) carry no 2026 race row at all, which is consistent with a four-year staggered
-- board and is what a four-year term requires. Assertion 3f pins that 4/4 split so a fifth race
-- arriving stops the next wave rather than being absorbed. The documents that would settle it
-- are the board's own designation and the Secretary of State's 2026 certified candidate list.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE `chambers.inauguration_rules` LEAD WAS CORRECT — THE FIRST ONE IN THIS PASS THAT WAS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Alabama's State Board of Education rule row reads: "Code of Alabama § 16-3-1: a member holds
-- office from the first Monday after the second Tuesday in January next after their election.
-- For the 2026 winners that is 2027-01-18." **Opened and checked against § 16-3-1: the citation
-- is right, the paraphrase is right, and the computed date is right.**
--
-- ⚠ That does not retire the rule. Three California executive rows said only "1st Monday in the
--   new year following election", cited nothing, and would have been right this cycle for the
--   wrong reason. Alabama's earns its way in **because it names a section that says what the row
--   says it says**. ▶ The test stays "does the row carry a citation that checks out", never "has
--   a rule row ever been right".
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SOURCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   https://alison.legislature.state.al.us/constitution?section=116      Ala. Const. § 116
--   https://alison.legislature.state.al.us/constitution?section=46       Ala. Const. § 46 — the
--                                                                       LEGISLATURE, 2026-11-04
--   https://alison.legislature.state.al.us/code-of-alabama?section=16-3-1      § 16-3-1
--   https://alison.legislature.state.al.us/code-of-alabama?section=16-3-1.1    § 16-3-1.1, the map
--   https://alison.legislature.state.al.us/code-of-alabama?section=37-1-3      § 37-1-3
--
-- ALISON, the Alabama Legislature's own system. Read 2026-11-22 and every section re-read
-- 2026-11-24.
--
-- ⚠ **ALISON IS A JAVASCRIPT APPLICATION WITH NO SERVER-RENDERED LAW.** A full browser header set
--   gets HTTP 200 and 59,643 bytes of navigation with no section text in it — confirmed
--   2026-11-24 by a positive control: the fetched body contains the string "first Monday" ZERO
--   times while the rendered page contains it. This is not a WAF, and sending more headers does
--   not help; the sections above were read in a real browser.
-- ⚠ **AND IT IS NOT ADDRESSABLE BY A NAIVE URL UNTIL YOU HAVE WALKED THE TREE ONCE** — the
--   `?section=` parameter appears in the address bar only after Title → Chapter → Section, after
--   which a direct `?section=16-3-1` works. Click through once, read the resulting URL, reuse it.
-- ⚠ `law.justia.com` returns HTTP 403 to `curl` for Alabama and `codes.findlaw.com` answers with
--   a Cloudflare interstitial. Neither would have been usable and neither is the state.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Term start or oath? — **TERM START**
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- All three provisions attach the term itself to a computed calendar day: officers "shall hold
-- their respective offices for the term of four years FROM" it, a member "shall hold office FROM"
-- it, commissioners "shall serve terms of six years that BEGIN ON" it. None is conditioned on
-- qualification. Alabama's oath is a separate requirement — § 16-3-6 is the board's own oath
-- section, sitting beside § 16-3-1 in the same chapter — so the oath is an event this date does
-- not describe.
--
-- basis: `statute` for all 13 rows.
-- rule_id: `al-first-monday-after-second-tuesday-january`, with the per-body provision in
-- `authority`.

BEGIN;

-- ── The selection: every office this wave will DATE. ──────────────────────────────────────────
--
-- 🟢 NO SIBLING EXPANSION. Every Alabama race in this wave is single-seat with one winner, so
--    each office is taken by its own row and `grp` records which of the three provisions dates
--    it. The three groups are disjoint and their sizes are gated separately below, because one
--    rule_id covers three provisions and the authority TEXT is the only mechanical trace of which
--    clause dated which seat.
CREATE TEMP TABLE cc0501_sel ON COMMIT DROP AS
SELECT o.id                     AS office_id,
       d.district_type          AS district_type,
       o.title                  AS title,
       CASE
         WHEN d.district_type = 'STATE_BOARD_EDUCATION'           THEN 'sboe'
         WHEN o.title LIKE 'Public Service Commissioner, Place %' THEN 'psc'
         ELSE 'exec7'
       END                      AS grp
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'al'
   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION')
   AND w.election_date = DATE '2026-11-03'
   AND (d.district_type = 'STATE_BOARD_EDUCATION'
        OR o.title IN ('Governor', 'Lieutenant Governor', 'Attorney General', 'Auditor',
                       'Secretary of State', 'Treasurer',
                       'Commissioner of Agriculture and Industries',
                       'Public Service Commissioner, Place 1',
                       'Public Service Commissioner, Place 2'));

CREATE TEMP TABLE cc0501_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'al' AND s.election_date = DATE '2026-11-03')      AS rows_al,
       -- 🟢 ALABAMA IS THE FIRST STATE ON 2027-01-18, so this is 0 and the delta needs no other
       -- state named. ⚠ A fact about today, not a property of the day — assertion 4 still
       -- requires every row on it to belong to a NAMED rule.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-18')                               AS rows_jan18,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-04')                               AS rows_jan4,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-11')                               AS rows_jan11,
       (SELECT count(*) FROM essentials.office_pending_winner w
          JOIN essentials.offices o   ON o.id = w.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'al' AND w.election_date = DATE '2026-11-03'
           AND d.district_type NOT IN ('STATE_EXEC','STATE_BOARD_EDUCATION'))      AS pending_outside;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0501_before;

  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. It writes no
  -- term, so on a second run all 13 seats are still pending and every P1 check below would pass;
  -- the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0501_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 13 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — the three provision groups, counted separately. 🔴 ONE rule_id COVERS THREE PROVISIONS,
  -- so the only mechanical trace of which clause dated a seat is the authority text, and the only
  -- way a mis-grouping is caught is by counting the groups.
  SELECT count(*) INTO n FROM cc0501_sel;
  IF n <> 13 THEN
    RAISE EXCEPTION 'P1: % Alabama seats are reachable from a 2026 race, expected 13 (7 § 116 '
                    'executives + 2 Public Service Commissioners + 4 State Board of Education '
                    'districts). The data moved under this file.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0501_sel WHERE grp = 'exec7';
  IF n <> 7 THEN
    RAISE EXCEPTION 'P1: % offices in the § 116 group, expected exactly 7 — Governor, Lieutenant '
                    'Governor, Attorney General, Auditor, Secretary of State, Treasurer and '
                    'Commissioner of Agriculture and Industries, which is the complete list that '
                    'section names and nothing else.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0501_sel WHERE grp = 'psc';
  IF n <> 2 THEN
    RAISE EXCEPTION 'P1: % Public Service Commissioner row(s), expected 2 — Places 1 and 2. '
                    '§ 37-1-3(a)(2) elects TWO associates in November 2026 and (b)(3)a says so '
                    'again; the President''s next election is November 2028.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0501_sel WHERE grp = 'sboe';
  IF n <> 4 THEN
    RAISE EXCEPTION 'P1: % State Board of Education seat(s), expected 4 (Districts 2, 4, 6, 8).', n;
  END IF;
  SELECT count(*) INTO n FROM cc0501_sel WHERE grp NOT IN ('exec7', 'psc', 'sboe');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % selected office(s) fell outside the three provision groups.', n;
  END IF;

  -- P2 — ⚠ AND THE SELECTION IS THE WHOLE PENDING SET, not a subset of it. The WHERE clause names
  -- nine executive titles explicitly, so a tenth pending executive would be silently dropped and
  -- nothing would error — which is the failure this gate exists for.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND w.election_date = DATE '2026-11-03'
     AND o.id NOT IN (SELECT office_id FROM cc0501_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % pending Alabama seat(s) did not reach this file''s selection. Each of '
                    'the 13 is dated by one of the three provisions; a seat outside them is a '
                    'body nobody has sourced, not a seat to add to a group.', n;
  END IF;
  IF b.pending_outside <> 0 THEN
    RAISE EXCEPTION 'P2: % Alabama pending seat(s) now sit outside STATE_EXEC and '
                    'STATE_BOARD_EDUCATION, expected 0. They are dated by their own rules; check '
                    'that none has reached this file.', b.pending_outside;
  END IF;

  -- P3 — every selected race is SINGLE-SEAT with exactly one winner. 🔴 THIS IS WHAT MAKES "NO
  -- RULING A" A MEASUREMENT RATHER THAN AN ASSUMPTION. A multi-seat race attaches all its winners
  -- to one office row, and the seating file would then have to write a winner into a SIBLING
  -- office — which must carry a date, so this file's 13 would be too few.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0501_sel c ON c.office_id = w.office_id
   WHERE w.election_date = DATE '2026-11-03' AND w.winner_count <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % of the 13 races carry more than one winner. Ruling A would then apply '
                    'and this file would have to date the SIBLING offices that receive the extra '
                    'winners — Maryland dated 178 offices against 114 races and Arizona 94 '
                    'against 65 for exactly this reason.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0501_sel c ON c.office_id = w.office_id
   WHERE w.election_date = DATE '2026-11-03' AND w.seats IS DISTINCT FROM 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % of the 13 races do not declare seats = 1.', n;
  END IF;

  -- P4 — 🔴🔴 THE ALABAMA LEGISLATURE IS NOT HERE, AND IT IS 140 OFFICES THAT DO NOT EXIST.
  -- § 46(a) elects all senators and representatives "in the year nineteen hundred and six, and in
  -- every fourth year thereafter" (1906 + 30x4 = 2026) and commences their terms "on the day
  -- after the general election" — 2026-11-04, already past, and 75 days before this file's day.
  -- Gated here so that creating those offices stops this file rather than inheriting its date.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % Alabama legislative office row(s) now exist, expected 0 when this file '
                    'was written. 🔴 THEY DO NOT TAKE THIS FILE''S DATE: Ala. Const. § 46(a) '
                    'commences a senator''s or representative''s term ON THE DAY AFTER THE '
                    'GENERAL ELECTION, which for 2026 is 2026-11-04 — not the first Monday after '
                    'the second Tuesday in January. Read this file''s header before dating '
                    'them.', n;
  END IF;

  -- P5 — the Board of Education's 4/4 split and the PSC President's absence, pinned as data facts
  -- because the law cannot prove the first of them. § 16-3-1 delegates the board's staggering to
  -- the board itself ("as designated by the board") and names no district.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND d.district_type = 'STATE_BOARD_EDUCATION';
  IF n <> 8 THEN
    RAISE EXCEPTION 'P5: Alabama holds % State Board of Education office rows, expected 8 '
                    '(§ 16-3-1: "eight members elected from districts provided by general law"). '
                    'The 4-of-8 split this file rests on is measured against this number.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND d.district_type = 'STATE_BOARD_EDUCATION'
     AND o.id NOT IN (SELECT office_id FROM cc0501_sel);
  IF n <> 4 THEN
    RAISE EXCEPTION 'P5: % board seat(s) carry no 2026 race, expected 4 (Districts 1, 3, 5, 7). '
                    '⚠ The statute CANNOT settle this — § 16-3-1 elects each member "at the '
                    'general election immediately preceding the expiration of the term of office '
                    'of the member, AS DESIGNATED BY THE BOARD" — and we hold no Alabama race '
                    'before 2026, so neither check is available. If this has fallen, a fifth race '
                    'has arrived and the wave is larger.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND d.district_type = 'STATE_EXEC'
     AND o.title = 'Public Service Commission President';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P5: Alabama holds % Public Service Commission President office row(s), '
                    'expected 1.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND o.title = 'Public Service Commission President'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: the Public Service Commission President carries a 2026 pending winner. '
                    '§ 37-1-3(a)(2) elects the president "every four years thereafter until the '
                    'general election held in November 2028", so the 2026 ballot carried the TWO '
                    'associates and not this seat. Read the result before dating it.';
  END IF;

  -- P6 — the day and its two near-miss Mondays, pinned by their before-image. 🔴 Both near misses
  -- are live elsewhere, so a gate reading a total rather than a delta would be reading 427 other
  -- seats.
  IF b.rows_jan18 <> 0 THEN
    RAISE EXCEPTION 'P6: % row(s) already carry 2027-01-18, expected 0 — Alabama is the FIRST '
                    'state in this pass on that day. Another state has landed on it since this '
                    'file was written; name its rule_id before adding 13 to the pile.',
      b.rows_jan18;
  END IF;
  IF b.rows_jan4 <> 234 OR b.rows_jan11 <> 193 THEN
    RAISE EXCEPTION 'P6: the near-miss days have moved — 2027-01-04 (the FIRST Monday) carries % '
                    'rows, expected 234, and 2027-01-11 (the SECOND Monday) carries %, expected '
                    '193. Those are Arizona, Wisconsin and California on the first and Washington '
                    'and Oregon on the second. They are pinned because reaching one or two '
                    'Mondays short of Alabama''s answer produces another body''s correct day, '
                    'never an absurd one.', b.rows_jan4, b.rows_jan11;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-18',
       'statute',
       'al-first-monday-after-second-tuesday-january',
       CASE c.grp
         WHEN 'exec7' THEN
           'Ala. Const. 2022, § 116 — "The governor, lieutenant governor, attorney general, '
             || 'state auditor, secretary of state, state treasurer, and commissioner of '
             || 'agriculture and industries, shall hold their respective offices for the term of '
             || 'four years FROM THE FIRST MONDAY AFTER THE SECOND TUESDAY IN JANUARY next '
             || 'succeeding their election and until their successors shall be elected and '
             || 'qualified." The second Tuesday in January 2027 is the 12th and the first Monday '
             || 'after it is 2027-01-18. ⚠ THE TRAILING CLAUSE IS A HOLDOVER PROVISION, which '
             || 'attaches to the END of the predecessor''s term — it does not make this term '
             || 'start at qualification (contrast Nevada''s six executives, refused in CC_0465 '
             || 'for exactly that). 🔴 THESE SEVEN OFFICES ARE NOT THE WHOLE STATE: § 46(a) '
             || 'commences a senator''s or representative''s term ON THE DAY AFTER THE GENERAL '
             || 'ELECTION, which for 2026 was 2026-11-04 — and we hold no Alabama legislative '
             || 'office row at all.'
         WHEN 'psc' THEN
           'Code of Alabama § 37-1-3(c)(1) — "All commissioners who are elected after June 1, '
             || '2026, shall serve terms of six years that BEGIN ON THE FIRST MONDAY AFTER THE '
             || 'SECOND TUESDAY IN JANUARY following the general election." The second Tuesday '
             || 'in January 2027 is the 12th and the first Monday after it is 2027-01-18. '
             || '🟢 THE SAME SECTION COMPUTES THIS CYCLE ITSELF: (b)(2) has the Governor appoint '
             || 'four commissioners "to serve initial terms BEGINNING JANUARY 18, 2027". '
             || '⚠ THESE TWO SEATS CARRY SIX-YEAR TERMS, NOT FOUR — (a)(1) gives four years only '
             || 'to commissioners serving on or before June 1, 2026. ⚠ AND THE COMMISSION IS '
             || 'MID-RESTRUCTURE: (b)(1) expands it to seven members, one per congressional '
             || 'district, phased to completion "by the terms beginning in January 2033", so on '
             || 'this very day it gains four appointed members we do not model. (b)(3)a elects '
             || 'the 2026 pair "in the same manner as commissioners were elected before June 1, '
             || '2026", which is why Place 1 and Place 2 are still at-large for this cycle and '
             || 'must not be re-districted now.'
         ELSE
           'Code of Alabama § 16-3-1 — "Each member shall hold office FROM THE FIRST MONDAY '
             || 'AFTER THE SECOND TUESDAY IN JANUARY next after his or her election and until '
             || 'his or her successor is elected and qualified." The second Tuesday in January '
             || '2027 is the 12th and the first Monday after it is 2027-01-18. ⚠ THE SAME '
             || 'SECTION DELEGATES THE BOARD''S STAGGERING TO THE BOARD ITSELF — each member is '
             || 'elected "at the general election immediately preceding the expiration of the '
             || 'term of office of the member, AS DESIGNATED BY THE BOARD" — so the law names no '
             || 'district and cannot say how many of the eight seats were on the 2026 ballot. '
             || 'Four carry a race (Districts 2, 4, 6, 8) and four do not, which is consistent '
             || 'with a four-year staggered board; the documents that would settle it are the '
             || 'board''s own designation and the Secretary of State''s certified candidate '
             || 'list. ⚠ THE HOLDOVER CLAUSE AT THE END ATTACHES TO THE PREDECESSOR''S TERM, not '
             || 'to this one''s start.'
       END,
       'ALISON, the Alabama Legislature''s own system, read 2026-11-22 and every section '
         || 're-read 2026-11-24: '
         || 'https://alison.legislature.state.al.us/constitution?section=116 (§ 116), '
         || '…/constitution?section=46 (§ 46, the LEGISLATURE — a fourth Alabama rule, naming '
         || '2026-11-04), …/code-of-alabama?section=16-3-1, …?section=16-3-1.1 (the district '
         || 'map) and …?section=37-1-3. '
         || '🟢🟢 THE CONTROL IS THE LEGISLATURE''S OWN ARITHMETIC, WRITTEN OUT AS A DATE: '
         || '§ 37-1-3(b)(2) says the Governor shall appoint four commissioners "to serve initial '
         || 'terms BEGINNING JANUARY 18, 2027" — the body that wrote the formula applying it to '
         || 'this exact cycle, which is stronger than any aggregator and stronger than any row '
         || 'in our own data. '
         || '⚠ ALISON IS A JAVASCRIPT APPLICATION WITH NO SERVER-RENDERED LAW. A full browser '
         || 'header set returns HTTP 200 and 59,643 bytes of navigation containing the string '
         || '"first Monday" ZERO times, confirmed by positive control 2026-11-24; it is not a '
         || 'WAF and more headers do not help. The sections were read in a real browser. '
         || '⚠ AND THE ?section= URL IS NOT GUESSABLE UNTIL YOU HAVE WALKED THE TREE ONCE — the '
         || 'parameter appears in the address bar only after Title -> Chapter -> Section, after '
         || 'which a direct ?section=16-3-1 works. law.justia.com returns HTTP 403 to curl for '
         || 'Alabama and codes.findlaw.com answers with a Cloudflare interstitial; neither is '
         || 'the state. '
         || '🟢 THE chambers.inauguration_rules LEAD WAS CORRECT, THE FIRST IN THIS PASS: '
         || 'Alabama''s board row cites § 16-3-1, paraphrases it accurately and computes '
         || '2027-01-18. It earns its way in because it names a section that says what the row '
         || 'says it says — not because a rule row has ever been right.',
       '🔴🔴 "THE Nth MONDAY" IS NOT A SHORTHAND FOR THIS RULE, AND THE SHORTHAND IS RIGHT SEVEN '
         || 'CYCLES OUT OF EIGHT. Computed over Alabama''s quadrennial cycles: in 2003, 2007, '
         || '2011, 2015, 2023, 2027 and 2031 the first Monday after the second Tuesday IS the '
         || 'third Monday, and in 2019 it is NOT — January 1st 2019 was itself a Tuesday, so the '
         || 'second Tuesday fell on the 8th and the first Monday after it was the 14th, the '
         || 'SECOND Monday, a week before the third Monday of the 21st. Alabama duly inaugurated '
         || 'on 2019-01-14. The day is computed from the second Tuesday in assertion 3a and the '
         || 'third-Monday look-alike is computed beside it in 3b for both years. '
         || '🔴 ALABAMA''S DAY WAS EMPTY AND BOTH NEAR-MISS MONDAYS ARE CROWDED. Measured before '
         || 'this file: 2027-01-18 carried 0 rows — Alabama is the FIRST state in this pass on '
         || 'it — while 2027-01-04, the FIRST Monday, carried 234 (Arizona 94, Wisconsin 123, '
         || 'California 17) and 2027-01-11, the SECOND Monday, carried 193 (Washington 118, '
         || 'Oregon 75). Reaching one or two Mondays short of Alabama''s answer produces another '
         || 'body''s correct term start, never an absurd day. '
         || '🔴🔴 WE HOLD NO ALABAMA LEGISLATURE AT ALL — ZERO STATE_UPPER AND ZERO STATE_LOWER '
         || 'OFFICE ROWS, against 35 Senate and 105 House seats that § 46(a) put on this ballot '
         || 'as a matter of law ("in the year nineteen hundred and six, and in every fourth year '
         || 'thereafter, all the senators and representatives shall be elected"; 1906 + 30x4 = '
         || '2026). Their terms began 2026-11-04, "the day after the general election", 75 days '
         || 'before this file''s day. The offices do not exist, so nothing errors and no count '
         || 'sees them: it is a SEEDING job, and whoever does it must NOT borrow this date. '
         || '⚠ THE BOARD OF EDUCATION''S 4-OF-8 SPLIT CANNOT BE PROVED FROM LAW OR FROM OUR DATA. '
         || '§ 16-3-1 says "as designated by the board"; we hold no Alabama race before 2026; '
         || 'and 17 of our 18 Alabama state terms carry term_start IS NULL. An unavailable check '
         || 'is a finding and is recorded as one. '
         || 'Written by CC_0501.'
  FROM cc0501_sel c;

DO $$
DECLARE n bigint; b record;
        jan1 date; first_tue date; second_tue date; rule_day date;
        first_mon date; second_mon date; third_mon date;
        j19 date; t19 date; r19 date; m19 date;
        al_day        CONSTANT date := DATE '2027-01-18';  -- the rule, this file
        al_second_tue CONSTANT date := DATE '2027-01-12';  -- the ANCHOR, never the answer
        al_first_mon  CONSTANT date := DATE '2027-01-04';  -- 234 rows, five other bodies
        al_second_mon CONSTANT date := DATE '2027-01-11';  -- 193 rows, Washington and Oregon
BEGIN
  SELECT * INTO b FROM cc0501_before;

  -- 1. All 13 carry the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0501_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = al_day;
  IF n <> 13 THEN
    RAISE EXCEPTION '1: % of 13 seats carry %.', n, al_day;
  END IF;

  -- 2. Exactly one distinct date was written. Three provisions, one day — which is NOT the
  --    default: Massachusetts' Amend. Art. LXIV § 1 is a SINGLE clause naming three days a
  --    fortnight apart, and Maryland's Governor sits a week past its General Assembly. ⚠ And in
  --    THIS state a fourth provision names a day 75 days earlier, for a body we do not hold.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0501_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 1.', n;
  END IF;

  -- 3a. 🔴 THE CLAUSE EVALUATED AS WRITTEN — the day is COMPUTED from the second Tuesday and
  --     never typed. "The first Monday after the second Tuesday" is the second Tuesday plus six
  --     days. ISODOW: Monday = 1, Tuesday = 2.
  jan1       := make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1);
  first_tue  := jan1 + ((2 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  second_tue := first_tue + 7;
  rule_day   := second_tue + 6;
  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  second_mon := first_mon + 7;
  third_mon  := first_mon + 14;
  IF EXTRACT(ISODOW FROM second_tue)::int <> 2 OR EXTRACT(ISODOW FROM rule_day)::int <> 1 THEN
    RAISE EXCEPTION '3a: the arithmetic is broken — % is not a Tuesday, or % is not a Monday. '
                    'Every comparison below proves nothing while this is wrong.',
      second_tue, rule_day;
  END IF;
  IF second_tue <> al_second_tue THEN
    RAISE EXCEPTION '3a: the second Tuesday of January following 2026-11-03 computes as %, not %.',
      second_tue, al_second_tue;
  END IF;
  IF rule_day <> al_day THEN
    RAISE EXCEPTION '3a: the first Monday after the second Tuesday computes as %, not %.',
      rule_day, al_day;
  END IF;

  -- 3b. 🔴🔴 THE LOOK-ALIKE COMPUTED BESIDE IT, IN THE YEAR WHERE IT AGREES *AND* THE YEAR WHERE
  --     IT DOES NOT. A control that only shows the rule and its shorthand landing on the same day
  --     this cycle cannot tell the two rules apart — which is the whole failure this guards. 2019
  --     is the separating cycle: the rule gives 2019-01-14, the day Alabama actually inaugurated,
  --     and the third Monday gives 2019-01-21.
  IF third_mon <> al_day THEN
    RAISE EXCEPTION '3b: in 2027 the third Monday computes as % and the rule as %. They agree '
                    'this cycle; if they have stopped agreeing the arithmetic is wrong, because '
                    'January 1st 2027 is a Friday.', third_mon, rule_day;
  END IF;
  j19 := DATE '2019-01-01';
  t19 := (j19 + ((2 - EXTRACT(ISODOW FROM j19)::int + 7) % 7)) + 7;   -- second Tuesday 2019
  r19 := t19 + 6;                                                    -- THE RULE
  m19 := (j19 + ((1 - EXTRACT(ISODOW FROM j19)::int + 7) % 7)) + 14;  -- the third Monday
  IF r19 <> DATE '2019-01-14' OR m19 <> DATE '2019-01-21' OR r19 = m19 THEN
    RAISE EXCEPTION '3b: the 2019 separator failed — the rule computes % (expected 2019-01-14, '
                    'the day Alabama actually inaugurated) and the third Monday % (expected '
                    '2019-01-21). Without a cycle where the two DISAGREE this control shows only '
                    'that they coincide in 2027, which is true of any rule that lands there.',
      r19, m19;
  END IF;
  RAISE NOTICE '3b: 2027 — the rule and the third Monday are the SAME day (%); 2019 — the rule is '
               '% and the third Monday is %, SEVEN DAYS APART. The shorthand is right in seven of '
               'Alabama''s eight cycles 2003-2031 and wrong in 2019.', rule_day, r19, m19;

  -- 3c. 🔴 AND NEITHER NEAR-MISS MONDAY CARRIES AN ALABAMA SEAT. Both are live elsewhere, which
  --     is what makes a wrong answer here look like a right one.
  IF first_mon <> al_first_mon OR second_mon <> al_second_mon THEN
    RAISE EXCEPTION '3c: the near-miss arithmetic is broken — first Monday %, second Monday %. '
                    'Expected % and %.', first_mon, second_mon, al_first_mon, al_second_mon;
  END IF;
  IF rule_day IN (first_mon, second_mon, second_tue) THEN
    RAISE EXCEPTION '3c: the rule day % collides with a near miss (first Monday %, second Monday '
                    '%, second Tuesday %), so the comparison below cannot discriminate.',
      rule_day, first_mon, second_mon, second_tue;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0501_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date IN (first_mon, second_mon, second_tue);
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % Alabama seat(s) carry a near-miss day — % (the FIRST Monday, 234 rows '
                    'in Arizona, Wisconsin and California), % (the SECOND Monday, 193 rows in '
                    'Washington and Oregon) or % (the second TUESDAY, the anchor this rule counts '
                    'FROM and never the answer).', n, first_mon, second_mon, second_tue;
  END IF;

  -- 3d. 🔴🔴 THE ALABAMA LEGISLATURE IS STILL ABSENT — 140 OFFICES THAT DO NOT EXIST, AND A
  --     FOURTH RULE NAMING 2026-11-04. Pinned after the write so the next reader finds this
  --     file's header rather than re-deriving § 46(a).
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION '3d: % Alabama legislative office row(s) exist. They must not take this '
                    'file''s date — § 46(a) commences their terms "on the day after the general '
                    'election", 2026-11-04.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al';
  IF n <> 30 THEN
    RAISE EXCEPTION '3d: Alabama holds % office rows in total, expected 30 (7 NATIONAL_LOWER, 5 '
                    'NATIONAL_UPPER, 10 STATE_EXEC, 8 STATE_BOARD_EDUCATION — and NO legislature '
                    'at all). A changed total is the seeding programme arriving; read this '
                    'file''s header before assuming the new rows share this date.', n;
  END IF;

  -- 3e. The PSC's three rows, and the President still not pending. § 37-1-3 settles both from
  --     law: (a)(2) elects two associates "until the general election held in November 2026" and
  --     the president "until the general election held in November 2028".
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'al' AND o.title LIKE 'Public Service Commission%';
  IF n <> 3 THEN
    RAISE EXCEPTION '3e: Alabama holds % Public Service Commission office row(s), expected 3 — '
                    'the President and Places 1 and 2. ⚠ ON THIS VERY DAY the commission becomes '
                    'SEVEN members under § 37-1-3(b)(1)-(2): the Governor appoints four "to '
                    'serve initial terms beginning January 18, 2027". They are appointees, not '
                    'election winners, so no 2026 wave reaches them and this file creates '
                    'none.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'al' AND o.title = 'Public Service Commission President'
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '3e: the Public Service Commission President was dated for this election. Its '
                    'next election is November 2028 under § 37-1-3(a)(2), and (b)(3)b then '
                    'replaces it with a district seat.';
  END IF;

  -- 3f. The board's 4/4 split, after the write.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts dd ON dd.id = o.district_id
    LEFT JOIN essentials.office_swearing_in s ON s.office_id = o.id
                                             AND s.election_date = DATE '2026-11-03'
   WHERE lower(dd.state) = 'al' AND dd.district_type = 'STATE_BOARD_EDUCATION'
     AND s.office_id IS NULL;
  IF n <> 4 THEN
    RAISE EXCEPTION '3f: % of the 8 board seats are undated for this election, expected 4 '
                    '(Districts 1, 3, 5, 7, which carry no 2026 race). ⚠ Neither the statute nor '
                    'our own data can prove that split — § 16-3-1 leaves the staggering to the '
                    'board and we hold no Alabama race before 2026 — so it is pinned as a '
                    'measurement and not argued.', n;
  END IF;

  -- 4. 🔴 THE 2027-01-18 DELTA. It starts from zero, and every row on the day must still belong
  --    to a NAMED rule: an empty day is a fact about today, not a property of the day.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = al_day;
  IF n <> b.rows_jan18 + 13 THEN
    RAISE EXCEPTION '4: rows on % went % -> %, a delta of %, expected 13.',
      al_day, b.rows_jan18, n, n - b.rows_jan18;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.swearing_in_date = al_day
     AND NOT (lower(dd.state) = 'al'
              AND s.rule_id = 'al-first-monday-after-second-tuesday-january');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % row(s) on % belong to neither Alabama nor this file''s rule. A date '
                    'shared by several states is a coincidence of calendars, never a shared rule '
                    '— name the new one before absorbing it.', n, al_day;
  END IF;

  -- 5. Alabama rows for this election moved by exactly 13, and every row that is NOT one of the
  --    13 is one of the 8 federal seats the federal programme dated to 2027-01-03.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'al' AND s.election_date = DATE '2026-11-03'
     AND s.office_id NOT IN (SELECT office_id FROM cc0501_sel)
     AND NOT (dd.district_type IN ('NATIONAL_LOWER', 'NATIONAL_UPPER')
              AND s.swearing_in_date = DATE '2027-01-03'
              AND s.rule_id = 'us-const-amend-xx-1');
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % Alabama row(s) for this election are neither one of this file''s 13 nor '
                    'one of the 8 federal rows (7 NATIONAL_LOWER + 1 NATIONAL_UPPER, 2027-01-03, '
                    'us-const-amend-xx-1).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'al' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_al + 13 THEN
    RAISE EXCEPTION '5: Alabama rows for this election went % -> %, a delta of %, expected 13.',
      b.rows_al, n, n - b.rows_al;
  END IF;

  -- 6. Repo-wide, exactly 13 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 13 THEN
    RAISE EXCEPTION '6: office_swearing_in went % -> %, a delta of %, expected 13.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 7. Every one of the 13 reads back as an Alabama row under this rule, with basis statute.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN cc0501_sel c            ON c.office_id = s.office_id
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03'
     AND lower(dd.state) = 'al'
     AND s.basis = 'statute'
     AND s.rule_id = 'al-first-monday-after-second-tuesday-january';
  IF n <> 13 THEN
    RAISE EXCEPTION '7: % of 13 rows read back as an Alabama row with basis statute under '
                    'al-first-monday-after-second-tuesday-january.', n;
  END IF;

  -- 7b. 🔴 THE THREE AUTHORITIES, COUNTED SEPARATELY. One rule_id covers three provisions here,
  --     so the only mechanical trace of "which clause dated this seat" is the authority text
  --     itself. Washington's lesson (CC_0487): a citation can be right about the date and wrong
  --     about the law, and no count, digest or view can tell them apart unless a count is written
  --     for it.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0501_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'exec7'
     AND s.authority LIKE 'Ala. Const. 2022, § 116 %';
  IF n <> 7 THEN
    RAISE EXCEPTION '7b: % of the 7 § 116 executives cite Ala. Const. 2022, § 116.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0501_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'psc'
     AND s.authority LIKE 'Code of Alabama § 37-1-3(c)(1) %';
  IF n <> 2 THEN
    RAISE EXCEPTION '7b: % of the 2 Public Service Commissioner rows cite § 37-1-3(c)(1).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0501_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'sboe'
     AND s.authority LIKE 'Code of Alabama § 16-3-1 %';
  IF n <> 4 THEN
    RAISE EXCEPTION '7b: % of the 4 State Board of Education rows cite § 16-3-1.', n;
  END IF;
  -- 7c. ⚠ AND NO ROW IS DATED ON A CLAUSE FOR A BODY IT DOES NOT BELONG TO. § 46(a) is quoted
  --     inside the § 116 rows' authority as a WARNING about the legislature; it must never be
  --     the citation a seat is dated ON, because its day is 2026-11-04.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0501_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.authority LIKE 'Ala. Const. 2022, § 46%';
  IF n <> 0 THEN
    RAISE EXCEPTION '7c: % row(s) are dated ON § 46. That section commences a senator''s or '
                    'representative''s term on the day after the general election — 2026-11-04 — '
                    'and dates none of these 13 offices.', n;
  END IF;

  -- 8. The four undated board seats are still undated, and so is every Alabama office with no
  --    2026 race. This file dated what it can see a winner for.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'al'
     AND dd.district_type IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION')
     AND s.election_date = DATE '2026-11-03'
     AND s.office_id NOT IN (SELECT office_id FROM cc0501_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % Alabama state seat(s) outside this file''s selection carry a date for '
                    'this election — the four board districts with no 2026 race (1, 3, 5, 7) and '
                    'the Public Service Commission President, whose next election is 2028. A seat '
                    'we hold no winner for is not a seat this wave can schedule.', n;
  END IF;

  -- 9. No term was written. CC_0502 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0501_sel c ON c.office_id = t.office_id
   WHERE t.term_start = al_day;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0501 OK: 13 Alabama seats dated % — THE FIRST MONDAY AFTER THE SECOND TUESDAY '
               'in January, from three provisions that say the same thing in nearly the same '
               'words: Ala. Const. 2022 § 116 (7 executives), Code of Ala. § 37-1-3(c)(1) (2 '
               'Public Service Commissioners, SIX-year terms) and § 16-3-1 (4 State Board of '
               'Education districts). The day was COMPUTED from the second Tuesday (%) and never '
               'typed, and the third-Monday look-alike was computed beside it in both the year it '
               'agrees (2027) and the year it does not (2019: the rule gives 2019-01-14, the '
               'shorthand 2019-01-21, and Alabama inaugurated on the 14th). 🟢 The strongest '
               'control is the Legislature''s own arithmetic: § 37-1-3(b)(2) writes "initial '
               'terms beginning January 18, 2027" in words. Alabama is the FIRST state in this '
               'pass on this day, while both near-miss Mondays are crowded — % carries 234 rows '
               'and % carries 193. 🔴🔴 WE HOLD NO ALABAMA LEGISLATURE AT ALL: zero STATE_UPPER '
               'and zero STATE_LOWER office rows against 35 + 105 seats that § 46(a) put on this '
               'ballot as a matter of law, and whose terms began 2026-11-04 — "the day after the '
               'general election" — under a FOURTH Alabama rule this date must never be borrowed '
               'for. ⚠ The Board of Education''s 4-of-8 split is pinned as a measurement because '
               'neither the statute ("as designated by the board") nor our own data can prove it. '
               '⚠ And on this same day the Public Service Commission becomes seven seats while we '
               'model three: § 37-1-3(b)(2) seats four gubernatorial appointees, who are not '
               'election winners and are not created here.',
    al_day, al_second_tue, al_first_mon, al_second_mon;
END $$;

COMMIT;
