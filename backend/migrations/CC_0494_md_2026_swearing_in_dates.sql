-- CC_0494 — Maryland: the start date for the 178 General Assembly seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SECOND WEDNESDAY IN JANUARY — 2027-01-13
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-13  House of Delegates (131 of 141) and Senate (47 of 47)
--
-- Sourced 2026-11-22, re-read 2026-11-23; the write-up is in
-- backend/data/state-seating-2026/DATES.md § MD. This file writes the rows and seats nobody:
-- CC_0495 links and creates the people, CC_0496 seats.
--
-- 🔴🔴 THIS FILE DATES 178 OFFICES WHILE ONLY 114 OF THEM CARRY A RACE, AND THAT IS RULING A.
--     Maryland elects three Delegates from most districts in ONE multi-seat contest, and a
--     multi-seat race attaches ALL its winners to ONE office row. 67 Delegate office rows carry
--     131 winners between them; the other 64 Delegate offices in the same districts carry no
--     race at all. CC_0496 seats those winners into SIBLING offices under REGISTER.md's Ruling
--     A, so the seat that receives a term must carry the date — the seating file reads
--     office_swearing_in on the office it SEATS, not on the office that carried the race.
--     ▶ A date written only on the 114 race-carrying offices would abort CC_0496 at its P4 for
--     64 seats, AFTER the first seats were written.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — Md. Const. Art. III, § 6, QUOTED TO ITS FULL STOP
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **SEC. 6.** "A member of the General Assembly shall be elected by the registered voters of the
--   legislative or delegate district from which he seeks election, **to serve for a term of four
--   years beginning on the second Wednesday of January following his election**" (amended by
--   Chapter 99, Acts of 1956, ratified Nov. 6, 1956; Chapter 785, Acts of 1969, ratified Nov. 3,
--   1970; Chapter 681, Acts of 1977, ratified Nov. 7, 1978).
--
-- 🟢 **THE CLAUSE ENDS THERE.** Oregon's Art. IV Sec. 4(1) ends in "unless a different commencing
--   day for such terms shall have been appointed by law" and CC_0491 was written around that
--   escape hatch. Maryland's § 6 has none: the sentence runs from "A member" to "his election"
--   and then into its own amendment history. Read to the full stop, 2026-11-23, in the Maryland
--   State Archives' own HTML of the Constitution.
--
-- 🔴🔴 **MARYLAND IS A SAME-DAY STATE AND THE NEIGHBOURING CLAUSE IS THE WRONG ONE.**
--   Art. III, § 14 puts the General Assembly's own MEETING on the same day — "The General
--   Assembly shall meet on the second Wednesday of January, nineteen hundred and seventy-one,
--   and on the same day in every year thereafter". § 6 is the TERM; § 14 is the MEETING; they
--   agree in 2027 and they are different facts. Maine is the proof they can diverge (term
--   2026-12-01, convening 2026-12-02) and Oregon is the proof they often do (eight days apart).
--   ▶ This file cites § 6. A citation that is right about the date and wrong about the law is
--     invisible to every count — only a person reading the `authority` text can catch it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE CORROBORATION IS THE STRONGEST IN THIS PASS, AND IT NAMES THE DAY THIS FILE WRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The Maryland Manual On-Line's roster pages for BOTH chambers open with one sentence:
--
--   "Legislators elected in the 2022 General Election **took office on January 11, 2023, and
--    serve until January 13, 2027**."
--
--   …/msa/mdmanual/06hse/html/hsedist.html (19,161 B) and …/05sen/html/sendist.html (10,492 B),
--   both HTTP 200, read 2026-11-23.
--
-- Two independent things fall out of it:
--   • 2023-01-11 IS the second Wednesday of January 2023, so the clause evaluated for a cycle
--     this file does not write lands on the day the State Archives says those terms began.
--     Assertion 3d computes it rather than trusting the arithmetic.
--   • the State Archives names **2027-01-13** outright, as the last day of the sitting members'
--     service. That is this file's date, from a publication that is not the constitution.
--
-- ⚠ **"SERVE UNTIL JANUARY 13, 2027" AND OUR `term_end` OF 2027-01-12 ARE NOT A CONTRADICTION.**
--   `essentials.seat_officeholder` closes a predecessor at `term_start - 1` everywhere in this
--   programme, so the outgoing member's row will read 2027-01-12 and the incoming member's
--   2027-01-13 — one handover, written as two adjacent days. The Manual counts the handover day
--   itself as the last day served. Nothing in our data should be moved to match its wording.
--
-- 🔴 **THE ONE MARYLAND LEGISLATIVE TERM THAT CARRIES A START DATE IS NOT CORROBORATION.**
--   Alexander M. Harlan, Subdistrict 42A, term_start 2026-08-03 — an APPOINTMENT by Gov. Moore
--   after Mangione resigned (migration 1715, from mgaleg's "since August 3, 2026"). It is a
--   tenure start under a vacancy clause, not a term start under § 6. Assertion 3e pins it so
--   that a later reader cannot mistake it for evidence about this rule. The other 187
--   legislative terms carry term_start = NULL.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE NEAR MISSES — AND IN MARYLAND ONE OF THEM IS A LIVE DATE IN THE SAME STATE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-06  the FIRST Wednesday of January  — wrong, and nothing in Maryland law names it
--   2027-01-13  the SECOND Wednesday            — § 6, THE GENERAL ASSEMBLY, this file
--   2027-01-20  the THIRD Wednesday             — Art. II, § 1, THE GOVERNOR, a separate wave
--
-- 🔴🔴 So reaching one week past the right answer in Maryland does not produce an obviously
--   absurd day — it produces **the Governor's real commencement date**, which a later wave will
--   write for a different office. Utah's first Monday was the same shape. Assertion 3 computes
--   all three and refuses the two this file is not about.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THREE MARYLAND STATE EXECUTIVES ARE PENDING AND THIS FILE DATES NONE OF THEM
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   Governor              2027-01-20, Art. II § 1 — REAL, SOURCED, AND A SEPARATE WAVE. It is
--                         not in this file because it is a different clause naming a different
--                         day, and because "one state, one date" is the assumption Massachusetts
--                         already broke (CC_0481, three days from one clause).
--   Attorney General      🔴 REFUSED. Art. V § 1 gives a four-year term "from the time of his
--                         election and qualification" and names no day.
--   Comptroller           🔴 REFUSED. Art. VI § 1 says "for four years, and until their
--                         successors shall qualify" and names none.
--
-- ⚠ **MARYLAND'S REFUSALS ARE A DIFFERENT KIND FROM OREGON'S, AND THE DIFFERENCE MATTERS.**
--   Oregon's Governor has a precise rule about an EVENT (ORS 176.010, the publication of the
--   returns). Maryland's AG and Comptroller have **no rule at all**, so they fall to the
--   residual Art. XVII § 4 — "The term of office of all Judges and other officers … shall,
--   except in cases otherwise expressly provided herein, commence from the time of their
--   Election" — which Art. XVII § 9 makes prevail over anything inconsistent with it.
--   🔴 **READ LITERALLY THAT DATE IS 2026-11-03 AND WE CANNOT WRITE IT.** The predecessor holds
--   "until their successor shall qualify"; the successor's term commences at the election. The
--   two spans OVERLAP by design, so that the office is never empty — and `office_terms` carries
--   an exclusion constraint forbidding two holders of one office over overlapping ranges, which
--   is the whole basis of office_current_holder returning exactly one row per office. The
--   constitution's own answer is a date our model cannot express, and the date we could express
--   — the qualification — is the one the constitution declines to fix.
--   ▶ Both need a `published` date: the day each officer actually qualifies, recorded when it
--     happens. NOT `estimated` — CC_0496's P4 refuses an estimate and so does the register.
--   ⚠ Do not reach for "the third Wednesday, like the Governor". The Maryland Manual's own list
--     of Attorneys General gives years and no days, which is what a state publishes when there
--     is no fixed day to publish.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TEN DELEGATE SEATS ARE UNDATED BECAUSE WE HOLD NO RESULT, AND THE STATE HAS COUNTED THEM
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. III § 2 fixes the House of Delegates at 141 members and § 7 elects the whole General
-- Assembly every fourth year from 1958 — 1958 + 17×4 = 2026 — so **all 141 Delegates and all 47
-- Senators were on this ballot as a matter of law**. We hold 131 Delegate seats with a winner.
-- The other 10 sit in four contests that carry a 2026 race, candidates, and NO `won` row:
--
--   District 4   (3 seats)  Jerry Donald 29,901 · Andrew Duck 29,106 · Jesse T. Pippy 28,015
--                           next: Alleria Stanley 27,888 — margin 127
--   District 6   (3 seats)  Bob Long 17,041 · Ric Metzgar 16,217 · Robin L. Grammer 16,014
--                           next: Megan Ann Mioduszewski 14,247 — margin 1,767
--   District 31  (3 seats)  Brian A. Chisholm 27,474 · Mike Jacobs 26,354 ·
--                           LaToya Marie Caldwell-Nkongolo 24,927
--                           next: Heidi Buchanan Schmidt 24,662 — margin 265
--   District 34B (1 seat)   Jake Taylor 9,828 · next: Anthony Lyon 9,603 — margin 225
--
--   (Maryland State Board of Elections, "Unofficial 2026 Gubernatorial General Election
--    Results", gen_results_2026_6.html, last refreshed 11/20/2026 06:47:33 PM, read 2026-11-23.)
--
-- 🔴 **THESE ARE UNRECORDED, NOT UNDECIDED, AND THE TWO LOOK IDENTICAL FROM THE SEAT.** The
--   state has counted every one of them. Three of the four are inside half a percent, which is
--   why a caller may still be holding them; District 6's margin is 1,767 and is not close at
--   all. ▶ This belongs to the RESULTS programme, not to seating. This file dates what it can
--   see a winner for, and P3 gates on those ten seats STAYING unrecorded — if one gains a
--   winner, the wave is larger and this file's 178 is stale.
--
-- ⚠ **AND ONE OF THEM LEAVES A PERSON HOLDING TWO SEATS, WHICH IS CORRECT UNTIL THE RESULT
--   ARRIVES.** Nicholaus R. Kipke holds Delegate District 31 — one of the four — and wins Senate
--   District 31. CC_0496 seats him in the Senate and closes the predecessor on THAT seat only,
--   so from 2027-01-13 our data shows him in both. Closing his Delegate term would mean
--   inventing a successor. **The fix is the result.** (Utah's Doug Fiefia, CC_0490, is the same
--   shape.)
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SOURCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   https://msa.maryland.gov/msa/mdmanual/43const/html/03art3.html — 70,428 bytes, HTTP 200,
--   read 2026-11-22 and again 2026-11-23 at the identical byte count. The Maryland Manual
--   On-Line is the Maryland State Archives' own publication of the Constitution of Maryland,
--   and each section carries its amendment history, which is how the current wording was
--   separated from the superseded one.
--
-- 🔴🔴 **`mgaleg.maryland.gov` SERVES ITS "NotFound" PAGE WITH HTTP 200 AT EXACTLY 57,164
--   BYTES.** …/Laws/Constitution, …/Laws/Constitution?article=gml and …/Session/Index/2026rs all
--   answer 200 at that size; in a browser the first redirects to
--   /mgawebsite/Error/NotFound?error=404. A second official copy of the Maryland constitution
--   was sought at that host and does not exist. ▶ Any probe of mgaleg must assert on CONTENT;
--   57164 is the tell. This is CLAUDE.md's soft-404, met in the wild.
--
-- ⚠ msa.maryland.gov's own roster HTML is malformed in one place — District 28's second
--   delegate is written `<a href="…">Edith J. Patterson (D)<br>` with no closing tag — which
--   made a first parse of the roster return 140 delegates instead of 141. The number the
--   constitution names (141) is what exposed it. A roster parse that returns a plausible number
--   is not a roster parse that is right.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Term start or oath? — **TERM START**
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- § 6 says "beginning on". It is a calendar date and it is not conditioned on qualification, so
-- the oath is a separate event that this date does not describe. (Contrast Nevada's six
-- executives, refused in CC_0465 because their terms begin on qualification.)
--
-- basis: `statute` for all 178 rows.
-- rule_id: `md-const-art3-s6-second-wed-january`

BEGIN;

-- ── The selection: every office this wave will SEAT, not every office that carries a race. ────
CREATE TEMP TABLE cc0494_sel ON COMMIT DROP AS
WITH race AS (
  SELECT o.id AS race_office_id, o.district_id, o.chamber_id, o.title, d.district_type
    FROM essentials.office_pending_winner w
    JOIN essentials.offices   o ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03'
)
SELECT DISTINCT o2.id                                   AS office_id,
       r.district_type                                  AS district_type,
       d2.label                                         AS seat,
       (o2.id = r.race_office_id)                       AS carries_the_race
  FROM race r
  JOIN essentials.offices   o2 ON o2.district_id = r.district_id
                              AND o2.chamber_id IS NOT DISTINCT FROM r.chamber_id
                              AND o2.title = r.title
  JOIN essentials.districts d2 ON d2.id = o2.district_id;

CREATE TEMP TABLE cc0494_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'md' AND s.election_date = DATE '2026-11-03')      AS rows_md,
       -- 🟢 NOBODY IS ON THIS DAY YET. Washington and Oregon shared 2027-01-11 and every count
       -- in CC_0491 had to be a delta against 118; Maryland's 2027-01-13 is empty, so the delta
       -- and the total are the same number. The gate is written as a delta anyway, because
       -- "nothing else is here" expires the moment another state lands on it.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-13')                               AS rows_jan13,
       (SELECT count(*) FROM essentials.office_pending_winner w
          JOIN essentials.offices o   ON o.id = w.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'md' AND w.election_date = DATE '2026-11-03'
           AND d.district_type NOT IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC')) AS pending_below_state;

DO $$
DECLARE n bigint; m bigint;
BEGIN
  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. This file
  -- writes no term, so on a second run all 178 seats are still pending and every P1 check would
  -- pass; the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0494_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 178 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — the two bodies, and the Ruling A split inside the House.
  SELECT count(*) INTO n FROM cc0494_sel;
  IF n <> 178 THEN
    RAISE EXCEPTION 'P1: % Maryland legislative seats are reachable from a 2026 race, expected '
                    '178 (131 of the 141 Delegate seats + all 47 Senate seats). The data moved '
                    'under this file.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0494_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 131 THEN
    RAISE EXCEPTION 'P1: % Delegate seats reachable, expected 131 of 141 — the missing 10 are '
                    'the four contests we hold no recorded result for (Districts 4, 6, 31 and '
                    'Subdistrict 34B).', n;
  END IF;
  SELECT count(*) INTO n FROM cc0494_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 47 THEN
    RAISE EXCEPTION 'P1: % Senate seats reachable, expected 47 — THE WHOLE CHAMBER. Art. III '
                    '§ 7 elects the General Assembly every fourth year from 1958, so Maryland '
                    'has no staggered chamber and no Senate results gap.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0494_sel WHERE carries_the_race;
  IF n <> 114 THEN
    RAISE EXCEPTION 'P1: % of the 178 offices carry the race, expected 114 (67 Delegate + 47 '
                    'Senate). The other 64 are Ruling A siblings and are the whole reason this '
                    'file dates 178 offices rather than 114.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0494_sel WHERE NOT carries_the_race;
  IF n <> 64 THEN
    RAISE EXCEPTION 'P1: % sibling offices, expected 64.', n;
  END IF;

  -- P2 — 🟢 THE CONSTITUTION'S OWN ARITHMETIC, CHECKED AGAINST OUR OFFICE ROWS. Art. III § 2:
  -- "The membership of the Senate shall consist of forty-seven (47) Senators. The membership of
  -- the House of Delegates shall consist of one hundred forty-one (141) Delegates." Art. III § 3
  -- adds that "Each legislative district shall contain one (1) Senator and three (3) Delegates",
  -- however the district is subdivided for electing Delegates. This is what makes "10 seats are
  -- missing" a certainty rather than a suspicion — and it is also Ruling A's structural floor:
  -- if a district held four Delegate offices, "fill a remaining eligible office" could claim a
  -- seat nobody elected.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER';
  IF n <> 141 THEN
    RAISE EXCEPTION 'P2: Maryland holds % Delegate office rows, expected 141 (Art. III § 2).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_UPPER';
  IF n <> 47 THEN
    RAISE EXCEPTION 'P2: Maryland holds % Senate office rows, expected 47 (Art. III § 2).', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT (regexp_match(d.label, '(\d+)'))[1]::int AS dnum, count(*) AS per
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     GROUP BY 1) z WHERE per <> 3;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % Maryland legislative district(s) do not hold exactly 3 Delegate '
                    'offices. Art. III § 3 gives every district one Senator and three '
                    'Delegates, so a district holding two or four is a defect in our office '
                    'rows and Ruling A must not run over it.', n;
  END IF;
  SELECT count(*) INTO n FROM (
    SELECT (regexp_match(d.label, '(\d+)'))[1]::int AS dnum, count(*) AS per
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_UPPER'
     GROUP BY 1) z WHERE per <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % Maryland legislative district(s) do not hold exactly 1 Senate '
                    'office.', n;
  END IF;

  -- P3 — 🔴 THE TEN UNDATED DELEGATE SEATS, NAMED, AND GATED ON STAYING UNRECORDED.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     AND o.id NOT IN (SELECT office_id FROM cc0494_sel);
  IF n <> 10 THEN
    RAISE EXCEPTION 'P3: % Delegate office(s) are unreachable from any 2026 race, expected 10. '
                    'If this has fallen, a result has arrived and this file''s 178 is stale; if '
                    'it has risen, a race has been withdrawn.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     AND o.id NOT IN (SELECT office_id FROM cc0494_sel)
     AND d.label NOT IN ('State Legislative District 4', 'State Legislative District 6',
                         'State Legislative District 31', 'State Legislative Subdistrict 34B');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % unreachable Delegate seat(s) sit outside Districts 4, 6, 31 and '
                    'Subdistrict 34B — the four contests this file''s header measured against '
                    'the state''s own count. A fifth gap is a different fact and needs reading.',
                    n;
  END IF;
  -- 🔴 UNRECORDED, NOT ABSENT: each of the four carries a 2026 race with candidates and no
  -- winner. Utah's gap was 31 seats with NO RACE ROW AT ALL, which looks identical from the seat
  -- and is a different repair.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_LOWER'
     AND d.label IN ('State Legislative District 4', 'State Legislative District 6',
                     'State Legislative District 31', 'State Legislative Subdistrict 34B')
     AND EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id)
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                      WHERE rc.race_id = r.id AND rc.result = 'won');
  IF n <> 4 THEN
    RAISE EXCEPTION 'P3: % of the four gap contests still carry candidates and no recorded '
                    'winner, expected 4. The Maryland State Board of Elections has published a '
                    'count for all four (margins 127, 1767, 265 and 225); if one has reached '
                    'our data, this wave is larger than 178.', n;
  END IF;

  -- P4 — 🔴 MARYLAND'S THREE STATE EXECUTIVES ARE PENDING AND NONE IS IN THIS SELECTION.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P4: % Maryland state executive seats are pending, expected 3 (Governor, '
                    'Attorney General, Comptroller). The Governor is dated 2027-01-20 by Art. '
                    'II § 1 in a SEPARATE wave; the other two are REFUSED. This file must be '
                    'refusing the seats it was written about.', n;
  END IF;

  -- P5 — ⚠ MARYLAND HAS NO PENDING SEAT BELOW THE STATE TIER THIS CYCLE. Oregon had 15 and a
  -- state-wide selection would have swept them in. Counted so that assertion 5's zero means
  -- something rather than being true by luck.
  SELECT pending_below_state INTO n FROM cc0494_before;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % Maryland pending seats now sit below the state tier, expected 0. '
                    'They are dated by their own rules; check that none has reached this '
                    'file''s selection.', n;
  END IF;

  -- P6 — 🟢 NOBODY IS ON 2027-01-13 YET, AND THE NUMBER IS PINNED SO THE DELTA MEANS SOMETHING.
  SELECT rows_jan13 INTO m FROM cc0494_before;
  IF m <> 0 THEN
    RAISE EXCEPTION 'P6: % row(s) already carry 2027-01-13, expected 0. Washington and Oregon '
                    'shared 2027-01-11 under unrelated rules and every count in CC_0491 had to '
                    'be a delta against 118. If a state has landed on Maryland''s day, name its '
                    'rule_id before adding 178 to the pile.', m;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-13',
       'statute',
       'md-const-art3-s6-second-wed-january',
       'Md. Const. Art. III, § 6 — "A member of the General Assembly shall be elected by the '
         || 'registered voters of the legislative or delegate district from which he seeks '
         || 'election, to serve for a term of four years beginning on the second Wednesday of '
         || 'January following his election" (amended by Chapter 99, Acts of 1956, ratified '
         || 'Nov. 6, 1956; Chapter 785, Acts of 1969, ratified Nov. 3, 1970; Chapter 681, Acts '
         || 'of 1977, ratified Nov. 7, 1978). The second Wednesday of January following the '
         || '2026-11-03 general election is 2027-01-13. 🟢 THE CLAUSE HAS NO ESCAPE HATCH: it '
         || 'runs from "A member" to "his election" and then into its own amendment history, '
         || 'read to the full stop — unlike Or. Const. Art. IV Sec. 4(1), which ends in "unless '
         || 'a different commencing day for such terms shall have been appointed by law". '
         || '🔴 CITED FROM § 6 (THE TERM) AND NOT § 14 (THE MEETING), which puts the General '
         || 'Assembly''s own convening on the same second Wednesday. Maryland is a same-day '
         || 'state like Wisconsin and Washington; Maine is the proof the two can diverge.',
       'https://msa.maryland.gov/msa/mdmanual/43const/html/03art3.html (HTTP 200, 70,428 bytes) '
         || '— the Maryland Manual On-Line, the Maryland State Archives'' own publication of the '
         || 'Constitution of Maryland, read 2026-11-22 and again 2026-11-23 at the identical '
         || 'byte count, with each section''s amendment history used to separate the current '
         || 'wording from the superseded one. 🟢🟢 CORROBORATED BY THE STATE ARCHIVES'' OWN '
         || 'ROSTER, WHICH NAMES THIS DAY: both chamber roster pages open "Legislators elected '
         || 'in the 2022 General Election took office on January 11, 2023, and serve until '
         || 'January 13, 2027" — …/06hse/html/hsedist.html (19,161 B) and '
         || '…/05sen/html/sendist.html (10,492 B), both HTTP 200, read 2026-11-23. 2023-01-11 '
         || 'is itself the second Wednesday of January 2023, so the clause evaluated for a '
         || 'cycle this file does not write lands where the Archives says those terms began. '
         || '⚠ "SERVE UNTIL JANUARY 13, 2027" IS NOT IN CONFLICT WITH OUR term_end OF '
         || '2027-01-12: seat_officeholder closes a predecessor at term_start - 1 throughout '
         || 'this programme, so one handover is written as two adjacent days. '
         || '🔴 THE ONE MARYLAND LEGISLATIVE TERM CARRYING A START DATE IS NOT CORROBORATION — '
         || 'Alexander M. Harlan, Subdistrict 42A, 2026-08-03, an APPOINTMENT after a '
         || 'resignation (migration 1715), which is a tenure start under a vacancy clause and '
         || 'not a term start under § 6. The other 187 are NULL. '
         || '🔴🔴 mgaleg.maryland.gov SERVES ITS "NotFound" PAGE WITH HTTP 200 AT EXACTLY '
         || '57,164 BYTES, so no second official copy of the constitution was obtainable there; '
         || 'any probe of that host must assert on content.',
       '🔴 THREE CANDIDATE WEDNESDAYS SIT IN THIS ONE MONTH AND THE WRONG ONE IS A LIVE '
         || 'MARYLAND DATE. 2027-01-06 is the FIRST Wednesday and nothing in Maryland law names '
         || 'it. 2027-01-13 is the SECOND, which is § 6 and this file. 2027-01-20 is the THIRD '
         || '— which is the GOVERNOR''s real commencement under Art. II § 1 ("whose term of '
         || 'office shall commence on the third Wednesday of January next ensuing his '
         || 'election"), written in a separate wave. Reaching one week too far in Maryland does '
         || 'not produce an absurd day; it produces another office''s correct one. '
         || '🔴 THE ATTORNEY GENERAL AND THE COMPTROLLER ARE REFUSED. Art. V § 1 gives the AG '
         || 'four years "from the time of his election and qualification" and Art. VI § 1 gives '
         || 'the Comptroller four years "and until their successors shall qualify"; neither '
         || 'names a day, so both fall to the residual rule in Art. XVII § 4 — "shall … '
         || 'commence from the time of their Election" — which Art. XVII § 9 makes prevail. '
         || 'Read literally both terms began on 2026-11-03 and OVERLAP the predecessors, who '
         || 'hold until their successors qualify; office_terms forbids two holders of one '
         || 'office over overlapping ranges, so the constitution''s own answer is a date our '
         || 'model cannot express. Each needs a published qualification date, recorded when it '
         || 'happens, with basis = ''published''. '
         || '🔴🔴 THIS FILE DATES 178 OFFICES AND ONLY 114 CARRY A RACE. Maryland elects three '
         || 'Delegates from most districts in one multi-seat contest and a multi-seat race '
         || 'attaches all its winners to one office row, so CC_0496 seats 64 winners into '
         || 'SIBLING offices under REGISTER.md''s Ruling A. The seating file reads this table '
         || 'on the office it SEATS; a date written only on the race-carrying offices would '
         || 'abort it after writing. '
         || '🔴 TEN DELEGATE SEATS ARE DELIBERATELY NOT DATED: Districts 4, 6 and 31 (three '
         || 'seats each) and Subdistrict 34B (one) carry a 2026 race with candidates and no '
         || 'recorded winner. The Maryland State Board of Elections has counted all four '
         || '(margins 127, 1,767, 265 and 225 votes, gen_results_2026_6.html, last refreshed '
         || '2026-11-20) — they are UNRECORDED here, not undecided there, and they belong to '
         || 'the results programme. Art. III § 2 fixes the House at 141 and § 7 elects the '
         || 'whole General Assembly every fourth year from 1958, so all 141 were on this ballot '
         || 'and those ten are certainly missing data. '
         || 'Written by CC_0494.'
  FROM cc0494_sel c;

DO $$
DECLARE n bigint; b record; jan1 date; first_wed date; second_wed date; third_wed date;
        jan1_2023 date; second_wed_2023 date; harlan date;
        -- ⚠ ONE LITERAL, READ BY BOTH THE CONDITION AND ITS MESSAGE. Two Oregon controls fired
        -- correctly and printed a self-contradiction because the expectation was written twice.
        harlan_expected   CONSTANT date := DATE '2026-08-03';
        archives_2023     CONSTANT date := DATE '2023-01-11';   -- the Manual's own sentence
        archives_2027     CONSTANT date := DATE '2027-01-13';   -- the Manual's own sentence
BEGIN
  SELECT * INTO b FROM cc0494_before;

  -- 1. All 178 carry the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0494_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = archives_2027;
  IF n <> 178 THEN
    RAISE EXCEPTION '1: % of 178 seats carry %.', n, archives_2027;
  END IF;

  -- 2. Exactly one distinct date was written. One clause covers both chambers here — which is
  --    NOT the default: Massachusetts' Amend. Art. LXIV § 1 named three days a fortnight apart.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0494_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 1.', n;
  END IF;

  -- 3. 🔴🔴 THE CLAUSE EVALUATED AS WRITTEN, WITH BOTH WRONG WEDNESDAYS COMPUTED BESIDE IT.
  --    (a) "the second Wednesday of January following his election" — computed, not typed.
  jan1       := make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1);
  first_wed  := jan1 + ((3 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  second_wed := first_wed + 7;
  third_wed  := first_wed + 14;
  IF second_wed <> archives_2027 THEN
    RAISE EXCEPTION '3a: the second Wednesday of January following 2026-11-03 computes as %, '
                    'not %.', second_wed, archives_2027;
  END IF;
  --    (b) 🔴 THE TWO WRONG DAYS ARE REAL DAYS IN THE RIGHT MONTH, AND ONE OF THEM IS THE
  --        GOVERNOR'S. They must be three distinct days or this control cannot tell the rules
  --        apart.
  IF first_wed <> DATE '2027-01-06' OR third_wed <> DATE '2027-01-20' THEN
    RAISE EXCEPTION '3b: the near-miss arithmetic is broken — first Wednesday %, third Wednesday '
                    '%. Expected 2027-01-06 and 2027-01-20. The comparison below proves nothing '
                    'while this is wrong.', first_wed, third_wed;
  END IF;
  IF first_wed = second_wed OR second_wed = third_wed OR first_wed = third_wed THEN
    RAISE EXCEPTION '3b: the three candidate Wednesdays are not three distinct days (%, %, %).',
      first_wed, second_wed, third_wed;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0494_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date IN (first_wed, third_wed);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % seat(s) carry one of the two wrong Wednesdays — % (the first, which '
                    'no Maryland clause names) or % (the third, which is the GOVERNOR''s own '
                    'commencement under Art. II § 1).', n, first_wed, third_wed;
  END IF;
  --    (c) 🔴 AND NO MARYLAND STATE EXECUTIVE WAS GIVEN A DATE BY THIS FILE. The Governor's
  --        date is real and is a separate wave; the other two are refused.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md' AND dd.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % Maryland state executive seat(s) were dated by this file. The '
                    'Governor belongs to a separate wave (2027-01-20, Art. II § 1); the '
                    'Attorney General and the Comptroller are REFUSED — no clause names a day '
                    'for either.', n;
  END IF;
  --    (d) 🟢🟢 THE RULE RUN FOR A CYCLE THIS FILE DOES NOT WRITE, AGAINST THE STATE ARCHIVES'
  --        OWN SENTENCE. The Maryland Manual says the sitting members "took office on January
  --        11, 2023, and serve until January 13, 2027". The same expression, evaluated for
  --        2023, must produce the first of those two days — otherwise either the arithmetic or
  --        the reading of the clause is wrong, and this file's day rests on both.
  jan1_2023       := make_date(2023, 1, 1);
  second_wed_2023 := jan1_2023 + ((3 - EXTRACT(ISODOW FROM jan1_2023)::int + 7) % 7) + 7;
  IF second_wed_2023 <> archives_2023 THEN
    RAISE EXCEPTION '3d: the second Wednesday of January 2023 computes as %, but the Maryland '
                    'Manual''s roster says the sitting members took office on %. The clause and '
                    'the Archives disagree, which means this file''s reading of § 6 is wrong.',
                    second_wed_2023, archives_2023;
  END IF;
  --    (e) 🔴 THE ONE MARYLAND LEGISLATIVE TERM WITH A START DATE IS AN APPOINTMENT, NOT
  --        EVIDENCE ABOUT THIS CLAUSE. It reads like corroboration and is not.
  SELECT t.term_start INTO harlan
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md' AND dd.district_type = 'STATE_LOWER'
     AND dd.label = 'State Legislative Subdistrict 42A' AND t.term_end IS NULL;
  IF harlan IS DISTINCT FROM harlan_expected THEN
    RAISE EXCEPTION '3e: the open Subdistrict 42A term starts %, expected % — Alexander M. '
                    'Harlan, APPOINTED after a resignation. It is the only Maryland legislative '
                    'term carrying a start date and this file''s header explains at length why '
                    'it is not corroboration for § 6. If it has changed, re-read the argument.',
                    harlan, harlan_expected;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md'
     AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start IS NOT NULL;
  IF n <> 1 THEN
    RAISE EXCEPTION '3e: % Maryland legislative term(s) carry a start date, expected exactly 1 '
                    '(Harlan''s appointment). When this file was written the other 187 were '
                    'NULL, so § 6 has no corroboration inside our own data and rests on the '
                    'constitution and the State Archives'' roster sentence.', n;
  END IF;

  -- 4. 🔴🔴 THE 2027-01-13 DELTA, NAMED. Maryland was alone on this calendar day when this file
  --    was written, so the delta and the total are the same number — which is exactly the state
  --    Washington was in before Oregon landed on 2027-01-11 and made every count there a delta
  --    against 118. Written as a delta on purpose.
  SELECT count(*) INTO n FROM essentials.office_swearing_in
   WHERE swearing_in_date = archives_2027;
  IF n <> b.rows_jan13 + 178 THEN
    RAISE EXCEPTION '4: rows on % went % -> %, a delta of %, expected 178.',
      archives_2027, b.rows_jan13, n, n - b.rows_jan13;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.swearing_in_date = archives_2027
     AND NOT (lower(dd.state) = 'md'
              AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
              AND s.rule_id = 'md-const-art3-s6-second-wed-january');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % row(s) on % belong to something other than Maryland''s Art. III § 6. '
                    'A date shared by several states is a coincidence of calendars, never a '
                    'shared rule — name the new one before absorbing it into Maryland''s count.',
                    n, archives_2027;
  END IF;

  -- 5. Maryland rows for this election moved by exactly 178, and every row that is NOT one of
  --    the 178 is one of the 8 federal seats the federal programme dated to 2027-01-03.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md' AND s.election_date = DATE '2026-11-03'
     AND dd.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER')
     AND NOT (dd.district_type = 'NATIONAL_LOWER'
              AND s.swearing_in_date = DATE '2027-01-03'
              AND s.rule_id = 'us-const-amend-xx-1');
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % Maryland row(s) for this election are neither one of this file''s 178 '
                    'nor one of the 8 NATIONAL_LOWER rows (2027-01-03, us-const-amend-xx-1).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_md + 178 THEN
    RAISE EXCEPTION '5: Maryland rows for this election went % -> %, a delta of %, expected 178.',
      b.rows_md, n, n - b.rows_md;
  END IF;

  -- 6. Repo-wide, exactly 178 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 178 THEN
    RAISE EXCEPTION '6: office_swearing_in went % -> %, a delta of %, expected 178.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 7. Every one of the 178 reads back as a Maryland legislative row under this rule.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN cc0494_sel c            ON c.office_id = s.office_id
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03'
     AND lower(dd.state) = 'md'
     AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND s.basis = 'statute'
     AND s.rule_id = 'md-const-art3-s6-second-wed-january';
  IF n <> 178 THEN
    RAISE EXCEPTION '7: % of 178 rows read back as a Maryland legislative row with basis '
                    'statute under md-const-art3-s6-second-wed-january.', n;
  END IF;

  -- 8. The ten gap seats are still undated. This file dated what it can see a winner for.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts dd ON dd.id = o.district_id
    JOIN essentials.office_swearing_in s ON s.office_id = o.id
                                        AND s.election_date = DATE '2026-11-03'
   WHERE lower(dd.state) = 'md' AND dd.district_type = 'STATE_LOWER'
     AND o.id NOT IN (SELECT office_id FROM cc0494_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % of the ten unrecorded Delegate seats were dated. A seat we hold no '
                    'winner for is not a seat this wave can schedule.', n;
  END IF;

  -- 9. No term was written. CC_0496 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0494_sel c ON c.office_id = t.office_id
   WHERE t.term_start = archives_2027;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0494 OK: 178 Maryland General Assembly seats (131 of 141 Delegate seats + all '
               '47 Senate seats) dated % — THE SECOND WEDNESDAY in January, Md. Const. Art. III '
               '§ 6, quoted to its full stop and cited from the TERM clause rather than § 14''s '
               'identical MEETING day. The day was computed and both wrong Wednesdays computed '
               'beside it: % (the first, which no Maryland clause names) and % (the third, '
               'which is the GOVERNOR''s own date under Art. II § 1). The rule was run again '
               'for 2023 and produced %, which is the day the Maryland State Archives'' own '
               'roster says the sitting members took office — the same sentence that names % as '
               'the day their service ends. 178 offices were dated although only 114 carry a '
               'race: Ruling A seats 64 winners into sibling Delegate offices and the seating '
               'file reads this table on the office it SEATS. Ten Delegate seats in Districts '
               '4, 6, 31 and Subdistrict 34B were NOT dated — the state has counted all four '
               'contests and we hold no result. The Governor is a separate wave; the Attorney '
               'General and the Comptroller are REFUSED.',
    archives_2027, first_wed, third_wed, second_wed_2023, archives_2027;
END $$;

COMMIT;
