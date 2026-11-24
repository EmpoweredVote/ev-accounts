-- CC_0491 — Oregon: the start date for the 75 legislative seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SECOND MONDAY IN JANUARY — 2027-01-11
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-11  House of Representatives (60) and Senate (15 of 30, the chamber being staggered)
--
-- Sourced 2026-11-22, re-read 2026-11-23; the write-up is in
-- backend/data/state-seating-2026/DATES.md § OR. This file writes the rows and seats nobody:
-- CC_0492 creates and links the people, CC_0493 seats.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — Or. Const. Art. IV, Sec. 4(1), QUOTED TO ITS LAST CLAUSE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Section 4. Term of office of legislators; classification of Senators.**
--   "(1) The Senators shall be elected for the term of four years, and Representatives for the
--    term of two years. The term of each Senator and Representative shall commence on the second
--    Monday in January following his election, and shall continue for the full period of four
--    years or two years, as the case may be, **unless a different commencing day for such terms
--    shall have been appointed by law**."
--
-- 🔴🔴 **DATES.md QUOTES THIS CLAUSE AND STOPS AT "as the case may be", WHICH DROPS THE PART
--     THAT MATTERS.** The constitutional date is a DEFAULT the Legislative Assembly may displace
--     by statute. A citation that ends one clause early reads as a fixed rule and is not one.
--     ▶ **Read a term clause to its full stop. The escape hatch is usually at the end.**
--
-- 🟢 **THE HATCH HAS NOT BEEN EXERCISED, AND THE ONE STATUTE ON POINT REAFFIRMS THE DAY.**
--   **ORS 171.051(6)**, on filling the back half of a Senate term: *"The remaining two years of
--   the term of office of a state Senator under subsection (4) of this section will commence on
--   the second Monday in January following the general election."* A different draftsman, in a
--   different code, writing for a different purpose, reaching for the same boundary.
--   ⚠ **The search was BOUNDED, and the bound is recorded rather than implied.** Five ORS
--   chapters were read in full for a statute appointing a different commencing day for a
--   legislator's term — 171 (Legislative Branch), 236 (vacancies), 249, 254 and 260 (elections).
--   Only ORS 171.051(6) speaks to it. 🔴 That is five chapters, not all of ORS; the scan's own
--   positive control is that the same pattern fired twice inside 171 while returning zero in the
--   other four, so the detector was alive on real input.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 FOUR CANDIDATE DAYS SIT IN THIS ONE MONTH, AND ONE OF THE WRONG ONES IS A SUPERSEDED RULE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-04   first Monday    — 🔴 THE RULE OREGON USED BEFORE 1961. Art. IV Sec. 4(3) is the
--                                  transition itself: a Senator or Representative "whose term,
--                                  under the former provisions of this section, would have
--                                  expired on the FIRST Monday in January 1961, shall continue
--                                  in office until the SECOND Monday in January 1961."
--   2027-01-11   second Monday   — ✅ the rule, Art. IV Sec. 4(1)
--   2027-01-18   third Monday    — the holiday for Martin Luther King, Jr.'s Birthday
--   2027-01-19   the Tuesday after that holiday — 🔴 WHEN THE LEGISLATURE ACTUALLY CONVENES,
--                                  ORS 171.010(1), EIGHT DAYS AFTER THE TERMS BEGIN.
--
-- ⚠ **OREGON IS A STATE WHERE THE TERM START AND THE CONVENING GENUINELY DIFFER**, unlike
--   Washington, Wisconsin, Maryland and California where they fall together. Reaching for the
--   session date here is wrong by more than a week. Assertion 3 computes all four days, proves
--   they are four distinct days, measures the gap between the term start and the convening at
--   exactly 8 days, and refuses to let any seat carry one of the three wrong ones.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 WASHINGTON'S 118 SEATS ALREADY START ON THIS DAY, UNDER A DIFFERENT RULE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `CC_0487` dated 95 Washington House and 23 Washington Senate seats to **2027-01-11** under
-- `wa-rcw-44-04-021-second-monday-january` — a STATUTE (RCW 44.04.021). Oregon's day comes from
-- its CONSTITUTION (Art. IV Sec. 4(1)). Two states, one calendar day, two unrelated rules.
--
-- 🔴 **SO EVERY COUNT IN THIS FILE ABOUT "2027-01-11" IS A DELTA, NEVER A TOTAL.** The before
--   image is 118, not 0. A gate that counted rows on that day without naming the state would
--   have reported 193 and called it success. Assertion 6 pins the delta AND names Washington's
--   `rule_id`, so a third state landing on this day is caught rather than absorbed.
--   ⚠ Idaho's Ada County is scheduled for the same day. It is not in this file.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE GOVERNOR IS REFUSED, AND THE REASON IS AN EVENT RATHER THAN A SILENCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Or. Const. Art. V, Sec. 7**: "The official term of the Governor shall be four years; and
-- shall commence at such times as may be prescribed by this constitution, or prescribed by law."
--
-- The law it defers to is **ORS 176.010 — Commencement of term; inauguration**: *"The official
-- term of the Governor shall commence upon the publication of the returns by the Speaker of the
-- House of Representatives, as provided in section 4, Article V, Oregon Constitution; … and the
-- Governor shall be inaugurated by taking the oath of office."*
--
-- ⚠ **THIS IS A DIFFERENT REFUSAL FROM MARYLAND'S.** Maryland's Comptroller has no rule at all.
--   Oregon's Governor has a precise rule about an **event that has not happened yet** — and the
--   event cannot precede this file's own date, because there is no Speaker until the new House
--   has organised, and the new House's members take office on 2027-01-11.
-- ⚠ **AND THE TWO EVENTS ARE SPLIT ACROSS TWO SECTIONS.** ORS 176.010 attaches the successor's
--   term to the PUBLICATION; **ORS 176.020** attaches the predecessor's exit to the OATH: "The
--   term of office of the Governor ceases when the successor … is inaugurated by taking the oath
--   of office." They are consistent only because both happen the same morning. ▶ Whoever records
--   this date must record WHICH of the two events it is.
--
-- ▶ **WHAT WOULD SETTLE IT:** the Oregon House Journal for the organisational day of the 2027
--   session, which records the Speaker publishing the returns. Record it then with
--   `basis = 'published'`. Assertion 4 refuses to date the Governor now.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE ONE OREGON DATE IN OUR OWN DATA LOOKS LIKE CORROBORATION AND IS NOT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **All 90 Oregon legislative terms carry `term_start = NULL`** (measured 2026-11-23), so
-- nothing in this database corroborates or contradicts 2027-01-11 for the legislature.
--
-- There is exactly ONE Oregon state-level term with a start date: **Tina Kotek, Governor,
-- 2023-01-09** — and 2023-01-09 **is** the second Monday of January 2023, which is why DATES.md
-- reaches for it. 🔴 **It is not evidence for this clause, on two separate counts.**
--   1. It belongs to the office this file REFUSES, governed by ORS 176.010's event, not by
--      Art. IV Sec. 4(1).
--   2. Its own `source` line says what it is a date of — *"first day in office, elected"*, taken
--      from a Blue Book biography and an NGA page (CA_0352) — **not** the publication of the
--      returns and **not** the oath. The row does not record which event it is, which is exactly
--      the defect ORS 176.010/176.020 make dangerous.
-- ▶ **A DATE THAT AGREES IS NOT A RULE THAT AGREES.** Assertion 5 asserts that row is the
--   Governor's and that this file left it alone; assertion 3d asserts the legislature's zero.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 OREGON HAS NO RESULTS GAP, AND THE STATE'S OWN EXPORT IS WHY WE CAN SAY SO
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Every state in this pass so far has had seats on the ballot with no recorded winner. Oregon
-- has none. Measured against production 2026-11-23:
--
--     House    60 offices    60 with a 2026 race    60 with a winner    0 missing
--     Senate   30 offices    15 with a 2026 race    15 with a winner    15 WITH NO RACE ROW
--
-- ⚠ **THOSE 15 ARE NOT A GAP.** Art. IV Sec. 4(2) divides the Senate into two classes "so that
--   one-half, as nearly as possible, of the number of Senators shall be elected biennially" —
--   15 of 30. 🔴 **AND THE COUNT IS CONFIRMED FROM OUTSIDE OUR DATA**: the Oregon Secretary of
--   State's own results export for this election contains exactly **75 legislative contests**,
--   not 90. This is the inverse of Utah, where the constitution turned "probably missing" into
--   "certainly missing"; here it turns "possibly missing" into "certainly complete".
--
-- 🔴 **WHICH half is up cannot be derived, and nothing in our data can check it.** Art. IV
--   Sec. 4(2) assigns the classes by the original division BY LOT, so there is no formula: the
--   15 pending districts are 3,4,6,7,8,10,11,13,15,16,17,19,20,24,26 — 7 odd and 8 even, not a
--   parity class. And our database holds **no Oregon races at all before 2026**, so the
--   complementary check ("were the other 15 elected in 2024?") is structurally unavailable.
--
-- 🟢 **ALL 75 WINNERS WERE CONFIRMED AGAINST THE STATE'S OWN RESULTS**, candidate by candidate,
--   before this file was written. Our winners came from the AP race calls; the Secretary of
--   State's export is an independent second source. 75 contests parsed, 75 agree, 0 disagree,
--   0 missing — with a positive control (one name deliberately corrupted) watched going red
--   first. Fetched over plain HTTP POST with no browser; see CC_0493's header for the route.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY, AND IT DATES ONLY THE STATE TIER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Overwrites nothing: P0 refuses if any of the 75 already carries a row for this election.
-- ⚠ 7 OTHER Oregon offices DO carry a 2026-11-03 row already — 6 NATIONAL_LOWER and 1
--   NATIONAL_UPPER, dated 2027-01-03 under `us-const-amend-xx-1` by the federal programme.
--   None is in this selection and assertion 7 pins the Oregon total at 7 + 75.
-- ⚠ **AND OREGON HAS 15 PENDING SEATS BELOW THE STATE TIER THIS CYCLE** — 9 LOCAL, 4 LOCAL_EXEC
--   and 2 COUNTY, two of them multi-winner. They are dated by their own rules and are NOT part
--   of this pass. The `state:or` claim covers them, so a wave that selected on state alone would
--   sweep them in. P4 counts them and assertion 7 proves none was dated.
--
-- Sources, opened and read 2026-11-22 and again 2026-11-23:
--   https://www.oregonlegislature.gov/bills_laws/Pages/OrConst.aspx  (HTTP 200, 647,166 bytes;
--     "second Monday in January" occurs 3 times, one of them Art. IV Sec. 4(1))
--   https://www.oregonlegislature.gov/bills_laws/ors/ors171.html     (HTTP 200, 487,315 bytes)
--   https://www.oregonlegislature.gov/bills_laws/ors/ors176.html     (HTTP 200, 113,138 bytes)
--   https://www.oregonlegislature.gov/bills_laws/ors/ors236.html, …/ors249.html, …/ors254.html,
--     …/ors260.html  (read in full for a displacing statute; none found)
--   ⚠ `…/bills_laws/Documents/OrConst.pdf` is a 404. The `.aspx` page carries the full text, and
--     plain `curl` gets it — no browser, no JavaScript shell. 🟢 Each chapter came back at a
--     DIFFERENT byte count, which is the check Utah's identical 26,677s failed.

BEGIN;

CREATE TEMP TABLE cc0491_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.district_type, o.title, d.label AS seat
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'or'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0491_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'or' AND s.election_date = DATE '2026-11-03')      AS rows_or,
       -- 🔴 THE WASHINGTON PRE-IMAGE. This is 118, not 0, and every later count is a delta.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-11')                               AS rows_jan11,
       (SELECT count(*) FROM essentials.office_pending_winner w
          JOIN essentials.offices o   ON o.id = w.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'or' AND w.election_date = DATE '2026-11-03'
           AND d.district_type NOT IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC')) AS pending_below_state;

DO $$
DECLARE n bigint; m bigint;
BEGIN
  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. This file
  -- writes no term, so on a second run all 75 seats are still pending and every P1 check would
  -- pass; the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0491_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 75 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — exactly the two bodies this file was written against. One clause covers both.
  SELECT count(*) INTO n FROM cc0491_sel;
  IF n <> 75 THEN
    RAISE EXCEPTION 'P1: % Oregon legislative seats are pending, expected 75 (60 House + 15 of '
                    'the 30 Senate seats). The data moved under this file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0491_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 60 THEN
    RAISE EXCEPTION 'P1: % House seats pending, expected 60 — THE WHOLE CHAMBER. Art. IV Sec. '
                    '4(1) gives Representatives a two-year term, so every seat is up every '
                    'biennium and Oregon has no House results gap.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0491_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 15 THEN
    RAISE EXCEPTION 'P1: % Senate seats pending, expected 15.', n;
  END IF;

  -- P2 — 🟢 THE SENATE SHORTFALL IS THE CONSTITUTION WORKING, NOT A GAP, AND THIS PROVES IT
  -- ARITHMETICALLY RATHER THAN ASSERTING IT. Art. IV Sec. 4(2): the Senate is divided into two
  -- classes "so that one-half, as nearly as possible, of the number of Senators shall be elected
  -- biennially". 15 pending of 30 offices is exactly one-half. ⚠ WHICH half is set BY LOT and
  -- cannot be derived — the pending districts are 7 odd and 8 even, not a parity class.
  SELECT count(*) INTO m
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER';
  SELECT count(*) INTO n FROM cc0491_sel WHERE district_type = 'STATE_UPPER';
  IF m <> 30 THEN
    RAISE EXCEPTION 'P2: Oregon has % Senate offices, expected 30. The one-half test below is '
                    'meaningless against a different chamber size.', m;
  END IF;
  IF n * 2 <> m THEN
    RAISE EXCEPTION 'P2: % of % Oregon Senate seats are pending. Art. IV Sec. 4(2) elects "one-'
                    'half, as nearly as possible" biennially, so this should be exactly half. '
                    'It is not — read whether a seat was added, a race lost, or a special '
                    'election held before treating the remainder as missing data.', n, m;
  END IF;

  -- P3 — 🔴 THE GOVERNOR IS PENDING AND IS DELIBERATELY NOT IN THIS SELECTION. If this is not
  -- exactly 1, the refusal this file documents is about a different set of seats than the one
  -- that is there.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'or' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P3: % Oregon state executive seats are pending, expected 1 (the Governor). '
                    'It is REFUSED for dating — ORS 176.010 commences the term on the '
                    'publication of the returns, an event, not a day — and this file must be '
                    'refusing the seat it was written about.', n;
  END IF;

  -- P4 — ⚠ AND OREGON HAS PENDING SEATS BELOW THE STATE TIER. They are dated by their own rules
  -- and this wave must not reach them. Counted here so assertion 7's zero means something.
  SELECT pending_below_state INTO n FROM cc0491_before;
  IF n <> 15 THEN
    RAISE EXCEPTION 'P4: % Oregon pending seats sit below the state tier, expected 15 (9 LOCAL, '
                    '4 LOCAL_EXEC, 2 COUNTY). They are not part of this pass; if the number has '
                    'moved, check that none of them has reached this file''s selection.', n;
  END IF;

  -- P5 — 🔴🔴 THE WASHINGTON PRE-IMAGE IS WHAT THIS FILE THINKS IT IS. 118 rows already carry
  -- 2027-01-11, and every one of them must be Washington's, under Washington's rule_id. If a
  -- third state has landed on this day since, assertion 6's delta arithmetic would still add up
  -- while meaning something different.
  SELECT rows_jan11 INTO n FROM cc0491_before;
  IF n <> 118 THEN
    RAISE EXCEPTION 'P5: % rows already carry 2027-01-11, expected 118 (Washington, CC_0487). '
                    'Oregon shares Washington''s calendar day under an unrelated rule, so this '
                    'file''s counts are deltas against that number and it must be the one this '
                    'file was written against.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.swearing_in_date = DATE '2027-01-11'
     AND NOT (lower(d.state) = 'wa'
              AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
              AND s.rule_id = 'wa-rcw-44-04-021-second-monday-january');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % row(s) on 2027-01-11 are not Washington legislative rows under '
                    'wa-rcw-44-04-021-second-monday-january. A date shared by several states is '
                    'a coincidence of calendars, never a shared rule — name the new one before '
                    'adding Oregon''s 75 to the pile.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-11',
       'statute',
       'or-const-art4-s4-second-monday-january',
       'Or. Const. Art. IV, Sec. 4 (Term of office of legislators; classification of Senators) '
         || '— "(1) The Senators shall be elected for the term of four years, and '
         || 'Representatives for the term of two years. The term of each Senator and '
         || 'Representative shall commence on the second Monday in January following his '
         || 'election, and shall continue for the full period of four years or two years, as '
         || 'the case may be, unless a different commencing day for such terms shall have been '
         || 'appointed by law." The second Monday in January following the 2026-11-03 general '
         || 'election is 2027-01-11. 🔴 THE CLAUSE ENDS IN AN ESCAPE HATCH AND IS QUOTED TO IT: '
         || 'the constitutional day is a default the Legislative Assembly may displace by '
         || 'statute. It has not. ORS 171.051(6), on filling the back half of a Senate term, '
         || 'names the same boundary — "The remaining two years of the term of office of a '
         || 'state Senator under subsection (4) of this section will commence on the second '
         || 'Monday in January following the general election" — which is a different '
         || 'draftsman, in a different code, for a different purpose, reaching for the same '
         || 'day. ⚠ THE SEARCH FOR A DISPLACING STATUTE WAS BOUNDED: ORS chapters 171, 236, '
         || '249, 254 and 260 were read in full, not all of ORS.',
       'https://www.oregonlegislature.gov/bills_laws/Pages/OrConst.aspx (HTTP 200, 647,166 '
         || 'bytes) for the constitution and https://www.oregonlegislature.gov/bills_laws/ors/'
         || 'ors171.html (487,315 bytes), …/ors176.html (113,138 bytes), …/ors236.html, '
         || '…/ors249.html, …/ors254.html, …/ors260.html for the statutes — the Legislative '
         || 'Assembly''s own publications, read 2026-11-22 and again 2026-11-23. Plain curl '
         || 'returns the full text; no browser and no JavaScript shell, and every chapter came '
         || 'back at a different byte count. ⚠ …/bills_laws/Documents/OrConst.pdf is a 404; the '
         || '.aspx page carries the text. ⚠ NO CORROBORATION EXISTS IN OUR OWN DATA: all 90 '
         || 'Oregon legislative terms carry term_start = NULL, measured 2026-11-23, so this '
         || 'date rests on the constitutional text and ORS 171.051(6) alone. 🔴 THE ONE OREGON '
         || 'STATE TERM THAT DOES CARRY A START IS NOT CORROBORATION: Tina Kotek, Governor, '
         || '2023-01-09 — which IS a second Monday, but belongs to the office this file refuses '
         || '(ORS 176.010 commences it on an event) and whose own source line calls it "first '
         || 'day in office, elected" from a Blue Book biography, not the publication of the '
         || 'returns and not the oath. A date that agrees is not a rule that agrees.',
       '🔴🔴 FOUR CANDIDATE DAYS SIT IN THIS ONE MONTH AND THREE OF THEM ARE WRONG. '
         || '2027-01-04 is the first Monday — THE RULE OREGON USED BEFORE 1961, and Art. IV '
         || 'Sec. 4(3) is the transition itself, continuing members who "would have expired on '
         || 'the first Monday in January 1961" until "the second Monday in January 1961". '
         || '2027-01-18 is the third Monday, the holiday for Martin Luther King, Jr.''s '
         || 'Birthday. 2027-01-19 is the Tuesday after that holiday — WHEN THE LEGISLATIVE '
         || 'ASSEMBLY ACTUALLY CONVENES, ORS 171.010(1), EIGHT DAYS AFTER THESE TERMS BEGIN. '
         || 'Oregon is a state where the term start and the convening genuinely differ, so a '
         || 'convening date reached for here is wrong by more than a week. '
         || '🔴🔴 WASHINGTON''S 118 LEGISLATIVE SEATS ALREADY START ON 2027-01-11 under RCW '
         || '44.04.021 (CC_0487). Same calendar day, unrelated rule: Washington''s is a '
         || 'statute, Oregon''s is its constitution. Every count about this day is a delta '
         || 'against 118, never a total. Idaho''s Ada County is scheduled for it too. '
         || '🔴 THE GOVERNOR IS REFUSED. Or. Const. Art. V Sec. 7 hands the commencement to the '
         || 'Legislature, and ORS 176.010 commences the term "upon the publication of the '
         || 'returns by the Speaker of the House of Representatives" — an event that cannot '
         || 'precede this date, because there is no Speaker until the new House has organised. '
         || 'ORS 176.020 then attaches the PREDECESSOR''s exit to the oath instead, so the two '
         || 'events are split across two sections and agree only because they fall on one '
         || 'morning. Record it from the 2027 House Journal with basis = ''published'', and '
         || 'record WHICH event it is. '
         || '🟢 OREGON HAS NO RESULTS GAP. 60 of 60 House seats and 15 of 30 Senate seats carry '
         || 'a 2026 race and a winner; the 15 Senate seats with no race row are the staggered '
         || 'half (Art. IV Sec. 4(2), "one-half, as nearly as possible"), and the Secretary of '
         || 'State''s own results export for this election holds exactly 75 legislative '
         || 'contests, not 90. Which half is up is set BY LOT and is not derivable. '
         || 'Written by CC_0491.'
  FROM cc0491_sel c;

DO $$
DECLARE n bigint; b record; jan1 date; first_mon date; second_mon date; third_mon date;
        convene date; kotek date;
        -- ⚠ ONE LITERAL, READ BY BOTH THE CONDITION AND ITS MESSAGE. A control on assertion 5
        -- printed "starts 2023-01-09, expected 2023-01-09" because the expectation was written
        -- twice; a gate that restates its own expectation as a second literal can print a
        -- self-contradiction, and only a control shows it.
        kotek_expected CONSTANT date := DATE '2023-01-09';
BEGIN
  SELECT * INTO b FROM cc0491_before;

  -- 1. All 75 carry the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0491_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2027-01-11';
  IF n <> 75 THEN
    RAISE EXCEPTION '1: % of 75 seats carry 2027-01-11.', n;
  END IF;

  -- 2. Exactly one distinct date was written. One clause covers both chambers here.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0491_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 1.', n;
  END IF;

  -- 3. 🔴🔴 THE CLAUSE EVALUATED AS WRITTEN, WITH EVERY WRONG RULE COMPUTED BESIDE IT.
  --
  --    (a) "the second Monday in January following his election" — computed, not typed.
  SELECT make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1) INTO jan1;
  SELECT jan1 + ((8 - EXTRACT(ISODOW FROM jan1))::int % 7) INTO first_mon;
  second_mon := first_mon + 7;
  third_mon  := first_mon + 14;
  convene    := third_mon + 1;                       -- ORS 171.010(1): the Tuesday after the
                                                     -- holiday for Martin Luther King, Jr.'s
                                                     -- Birthday, which is the third Monday.
  IF second_mon <> DATE '2027-01-11' THEN
    RAISE EXCEPTION '3a: the second Monday in January following 2026-11-03 computes as %, not '
                    '2027-01-11.', second_mon;
  END IF;

  --    (b) 🔴 THE THREE WRONG DAYS ARE REAL DAYS IN THE RIGHT MONTH, AND THEY MUST BE FOUR
  --        DISTINCT DAYS OR THIS CONTROL CANNOT TELL THE RULES APART.
  IF first_mon <> DATE '2027-01-04' OR third_mon <> DATE '2027-01-18'
     OR convene <> DATE '2027-01-19' THEN
    RAISE EXCEPTION '3b: the near-miss arithmetic is broken — first Monday %, third Monday %, '
                    'convening %. Expected 2027-01-04, 2027-01-18, 2027-01-19. The comparison '
                    'below proves nothing while this is wrong.', first_mon, third_mon, convene;
  END IF;
  IF first_mon = second_mon OR second_mon = third_mon OR second_mon = convene
     OR third_mon = convene OR first_mon = third_mon THEN
    RAISE EXCEPTION '3b: the four candidate days are not four distinct days (%, %, %, %).',
      first_mon, second_mon, third_mon, convene;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0491_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date IN (first_mon, third_mon, convene);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % seat(s) carry one of the three wrong days — % (the first Monday, '
                    'Oregon''s pre-1961 rule), % (the third Monday, the MLK holiday) or % (the '
                    'Tuesday after it, when the Assembly convenes).', n, first_mon, third_mon,
                    convene;
  END IF;

  --    (c) 🔴🔴 OREGON'S TERM START AND ITS CONVENING GENUINELY DIFFER, AND THE GAP IS MEASURED
  --        RATHER THAN ASSERTED. ORS 171.010(1) convenes the odd-year regular session on the
  --        Tuesday after the MLK holiday. If this gap were ever zero, the whole "a term start is
  --        not a swearing-in" argument would be untestable in this state — which is the state
  --        Washington, Wisconsin, Maryland and California are in.
  IF convene - second_mon <> 8 THEN
    RAISE EXCEPTION '3c: the Legislative Assembly convenes % days after these terms begin, '
                    'expected 8 (terms %, convening %). Oregon''s separation of the two is the '
                    'reason a convening date must not be reached for here.',
                    convene - second_mon, second_mon, convene;
  END IF;

  --    (d) ⚠ AND THE CORROBORATION STOPS THERE — ASSERTED, NOT ASSUMED. Not one Oregon
  --        legislative term carries a start date anywhere in this database, so 2027-01-11 rests
  --        on Art. IV Sec. 4(1) and ORS 171.051(6) alone.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'or'
     AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '3d: % Oregon legislative term(s) now carry a start date. When this file was '
                    'written all 90 were NULL, so this date had NO corroboration in our own '
                    'data. If rows have appeared, check this file''s date against them.', n;
  END IF;

  -- 4. 🔴🔴 THE GOVERNOR WAS NOT DATED. ORS 176.010 commences the term on the publication of
  --    the returns — an event, and one that cannot precede 2027-01-11 because there is no
  --    Speaker until the new House has organised. Borrowing the legislature's day would assert
  --    a rule nobody has read.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'or' AND dd.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % Oregon state executive seat(s) were dated by this file. The Governor '
                    'is refused: ORS 176.010 names an event, not a day.', n;
  END IF;

  -- 5. 🔴 THE ONE TEMPTING DATE IS STILL THE GOVERNOR'S, AND THIS FILE DID NOT TOUCH IT.
  --    Tina Kotek's term starts 2023-01-09, which IS the second Monday of January 2023 — and is
  --    sourced as "first day in office", not as the publication of the returns. It reads like
  --    corroboration for this clause and is evidence about a different rule entirely.
  SELECT t.term_start INTO kotek
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'or' AND dd.district_type = 'STATE_EXEC'
     AND o.title = 'Governor' AND t.term_end IS NULL;
  IF kotek IS DISTINCT FROM kotek_expected THEN
    RAISE EXCEPTION '5: the open Oregon Governor term starts %, expected %. That row is '
                    'the only Oregon state term with a start date and this file''s header '
                    'explains at length why it is NOT corroboration for Art. IV Sec. 4(1). If '
                    'it has changed, re-read the argument before trusting either.',
                    kotek, kotek_expected;
  END IF;

  -- 6. 🔴🔴 THE 2027-01-11 DELTA, NAMED. Oregon's 75 were added to Washington's 118 and nothing
  --    else joined them. A total here would be 193 and would look like success.
  SELECT count(*) INTO n FROM essentials.office_swearing_in
   WHERE swearing_in_date = DATE '2027-01-11';
  IF n <> b.rows_jan11 + 75 THEN
    RAISE EXCEPTION '6: rows on 2027-01-11 went % -> %, a delta of %, expected 75. Washington''s '
                    '118 were already there under a different rule.', b.rows_jan11, n,
                    n - b.rows_jan11;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.swearing_in_date = DATE '2027-01-11'
     AND NOT (lower(dd.state) = 'wa' AND s.rule_id = 'wa-rcw-44-04-021-second-monday-january')
     AND NOT (lower(dd.state) = 'or' AND s.rule_id = 'or-const-art4-s4-second-monday-january');
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % row(s) on 2027-01-11 belong to neither Washington''s statute nor '
                    'Oregon''s constitution. Two states on one day is already a coincidence; a '
                    'third needs naming before it is absorbed into either count.', n;
  END IF;

  -- 7. Oregon rows for this election moved by exactly 75, and every row that is NOT one of the
  --    75 is one of the 7 federal seats the federal programme dated to 2027-01-03 under
  --    `us-const-amend-xx-1`. ⚠ 6 are NATIONAL_LOWER and 1 is NATIONAL_UPPER — Utah's equivalent
  --    assertion needed only NATIONAL_LOWER, so this predicate was measured, not copied.
  --    🔴 THIS IS ALSO THE GATE ON THE 15 PENDING SEATS BELOW THE STATE TIER: a wave that
  --    selected on state alone would have swept in 9 LOCAL, 4 LOCAL_EXEC and 2 COUNTY offices,
  --    and every one of them would land here.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'or' AND s.election_date = DATE '2026-11-03'
     AND dd.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER')
     AND NOT (dd.district_type IN ('NATIONAL_LOWER', 'NATIONAL_UPPER')
              AND s.swearing_in_date = DATE '2027-01-03'
              AND s.rule_id = 'us-const-amend-xx-1');
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % Oregon row(s) for this election are neither one of this file''s 75 nor '
                    'one of the 7 federal rows (6 NATIONAL_LOWER + 1 NATIONAL_UPPER, 2027-01-03, '
                    'us-const-amend-xx-1). Oregon has 15 pending seats below the state tier this '
                    'cycle and they are dated by their own rules, not this one.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'or' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_or + 75 THEN
    RAISE EXCEPTION '7: Oregon rows for this election went % -> %, a delta of %, expected 75.',
      b.rows_or, n, n - b.rows_or;
  END IF;

  -- 8. Repo-wide, exactly 75 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 75 THEN
    RAISE EXCEPTION '8: office_swearing_in went % -> %, a delta of %, expected 75.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 9. No term was written. CC_0493 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0491_sel c ON c.office_id = t.office_id
   WHERE t.term_start = DATE '2027-01-11';
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0491 OK: 75 Oregon legislative seats (60 House, 15 of 30 Senate) dated '
               '2027-01-11 — THE SECOND MONDAY in January, Or. Const. Art. IV Sec. 4(1), quoted '
               'to its escape hatch and with ORS 171.051(6) naming the same day. The day was '
               'computed and all three wrong days computed beside it: the first Monday '
               '(2027-01-04, Oregon''s pre-1961 rule), the MLK holiday (2027-01-18) and the '
               'convening day (2027-01-19, ORS 171.010(1)), which is EIGHT days after these '
               'terms begin. Washington''s 118 seats were already on this calendar day under an '
               'unrelated statute, so every count here is a delta against 118. The Governor is '
               'REFUSED — ORS 176.010 names an event — and the one Oregon term that carries a '
               'start date is that same Governor''s, which is not corroboration.';
END $$;

COMMIT;
