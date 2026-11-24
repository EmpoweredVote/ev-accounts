-- CC_0506 — New Mexico: seat the 11 winners of 2026-11-03 for 2027-01-01.
--
-- Second of two. CC_0505 writes the date — three agreeing instruments, one day, N.M. Const.
-- Art. V § 1 and Art. XX § 3(A) and HB 9 § 3(B) — and this file writes the terms. **No people
-- file**: all 11 winner rows already carry a politician_id, all 11 rows are active, and none
-- collides on either (full_name) or (first_name, last_name). **No Ruling A**: every race is
-- single-seat with one winner.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE PIN — CAPTURED BY REHEARSING `CC_0505 + A PROBE` IN ONE ROLLED-BACK TRANSACTION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   11 winners · 11 offices · **6 re-elections · 5 handovers** · 11 predecessors (1 of them dated)
--   digest 69f7470ea2e442a225dd40ac6b0f7b94 · term start 2027-01-01
--
-- 🟢 The digest expression evaluated on **11 of 11** rows: no New Mexico seat is vacant and every
--   one has a current holder, so the `is_reelection` NULL that shrank California's and
--   Massachusetts' digests cannot occur here. **P3 counts the coverage anyway** — CC_0487 kept
--   that gate in a state where the defect could not occur and a control proved the two gates are
--   complementary rather than redundant.
--
-- Ruling B: all 11 rows were **called**, not certified, when this was written. Every term's
-- `source` carries `CC_0506`, so a reversed canvass is recovered with `source LIKE '%CC_0506%'`.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE ELEVEN, AND WHAT EACH ONE IS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   office                                     leaving                    arriving
--   Governor                                   Michelle Lujan Grisham  →  Debra Haaland
--   Lieutenant Governor                        Howie Morales           →  Stephanie Garcia Richard
--   Secretary of State                         Maggie Toulouse Oliver  →  Amanda López Askin
--   Commissioner of Public Lands               Stephanie Garcia Richard → Juan Sanchez III
--   Public Education Commissioner, District 2  Timothy Beck            →  Ken Pascoe
--   Attorney General                           Raul Torrez             →  Raul Torrez      (re-elected)
--   State Auditor                              Joseph Maestas          →  Joseph Maestas   (re-elected)
--   Treasurer                                  Laura Montoya           →  Laura Montoya    (re-elected)
--   Public Education Commissioner, District 3  Jacob Trujillo          →  Jacob Trujillo   (re-elected)
--   Public Education Commissioner, District 5  Sharon E. Clahchischilliage → the same       (re-elected)
--   Public Education Commissioner, District 6  Stewart Ingham          →  Stewart Ingham   (re-elected)
--
-- 🟢 **FIVE SEATS CHANGE HANDS, so step 9's live probe CAN be read by the NAME here** — the
--   opposite of Idaho, where all seven were re-elections and only the incoming DATE discriminated.
--   The probe still reads both, because a uniform "no incoming" is a broken detector.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE "NOBODY HOLDS TWO SEATS" ZERO HAS A REAL FIXTURE HERE, AND IT RESOLVES ITSELF
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Stephanie Garcia Richard is the sitting Commissioner of Public Lands and this wave's winner of
-- the Lieutenant Governorship.** She is the only person in the wave who holds a term on an office
-- other than the one she won, and **both offices are inside this wave, on the same day**:
--
--   seating her into Lieutenant Governor      opens her LG term at 2027-01-01
--   seating Juan Sanchez III into Public Lands closes her Public Lands term at 2026-12-31
--
-- 🟢 **Both closures happen because a seat was FILLED, which is the only way these files close
--   anything.** That is Oregon's Jeff Helfrich exactly (`CC_0493`), and the contrast is Utah's Doug
--   Fiefia, who kept House District 48 open after taking a Senate seat because **that seat's own
--   2026 result is missing and there was nobody to seat**. ▶ **The difference is a result, not a
--   rule**, and New Mexico has the result for Public Lands.
--
-- 🔴 **SHE HOLDS BOTH FOR THE LENGTH OF ONE STATEMENT, AND NOTHING REFUSES — WHICH IS CORRECT AND
--   WORTH KNOWING.** `seat_officeholder` is called in `office_id` order, so between the two calls
--   her Public Lands term is still open while her Lieutenant Governor term exists.
--   `office_terms_no_overlap` is an EXCLUDE on **`office_id`**, not on `politician_id`, so the
--   constraint cannot see a person in two offices at all — the only thing that can is `P8`/`9`, and
--   `9` re-asks the question **after every write**. ⚠ A reader who assumed the database would
--   refuse this is relying on a guard that does not exist.
--
-- 🟢🟢 **AND THE CONSTITUTION EXPLAINS WHY SHE MOVED.** Art. V § 1's second paragraph makes an
--   officer who has served two terms in a state office ineligible for it "until one full term has
--   intervened". She has served two as Commissioner of Public Lands. The same clause explains
--   Michelle Lujan Grisham's departure from the Governorship. **Two of this wave's five handovers
--   are predicted by the law rather than merely observed in the data**, which is corroboration of
--   the winner set from outside it. `P9` measures the pair.
--
-- 🔴 **THE ZERO IS THEREFORE BACKED BY A REAL FIXTURE AND NOT A PLANTED ONE**, unlike Idaho
--   (`CC_0504`), where not one winner held an office outside the wave and `P8` rested entirely on
--   a control that planted a second term. `REGISTER.md`: *a planted fixture proves the gate FIRES;
--   it does not prove the gate reads the rows a real double-holder would occupy.* Here it does.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Eleven predecessor rows, one per seat, every one with `term_end` NULL and `how_ended` NULL.**
-- Each becomes `term_end = 2026-12-31`, `how_ended = 'term_expired'`. 🟢 That day is not an
-- arithmetic accident: Art. XX § 3(B) and HB 9 § 16(B) both name **December 31** as the day an
-- unexpired term runs to, so the closure the function computes as `term_start - 1` is the day the
-- instruments name.
--
-- 🔴 `seat_officeholder` closes a predecessor with an unguarded
--   `UPDATE office_terms SET term_end = p_term_start - 1` and writes nothing to that row's
--   `source`, so the new terms are recoverable by slot and **the closures are not**. The eleven
--   rows are captured in `cc0506_pre` and P6 asserts every one is open before anything is written.
--
-- 🟢🟢 **ONE OF THE ELEVEN CARRIES A `term_start`, AND IT IS THE ONLY IN-DATA EVIDENCE CC_0505'S
--   RULE HAS.**
--
--     Michelle Lujan Grisham   Governor   2019-01-01   ✅ January 1st, from the Governor's own
--                                                      office press release of that day (CA_0352)
--
--   The other ten carry no `term_start` at all — eight are the ADR 0002 phase-2 backfill or a
--   Ballotpedia roster read with `start_precision = 'unknown'` — so this file writes ten term
--   *ends* onto rows with no beginning. Normal here, and stated so nobody reads it as damage.
--   🔴 **Losing Grisham's date would destroy the whole corroboration CC_0505 rests on**, because
--   it is a corpus of one, so assertion 6b asserts it is unchanged.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT IS NOT SEATED, AND WHY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   **Public Education Commissioner, District 7 — on the ballot, won, and we hold no race row.**
--   HB 9 § 3(C) elects districts two, three, five, six **and seven** at the 2022-and-subsequent
--   general elections, and § 3(D) puts the other five on 2024's — an exhaustive partition of
--   Art. XII § 6(B)'s ten members, so **five were up and we hold four**. The Secretary of State
--   recorded Frederick Walton Parker (D) 38,596, 65%, over John Foreman (R) 20,355, 178 of 178
--   precincts. **The seat changed hands and nothing in our data says so.**
--   🔴 **So Patricia Gipson stays on our pages as the District 7 commissioner after losing it.**
--   That is the Kipke and Fiefia shape, and `P5` pins it rather than tidying it: **the fix is the
--   result.** ⚠ This file deliberately does not touch her row — `seat_officeholder` closes a
--   predecessor only on the seat it is filling, and there is nobody to fill this one.
--
--   **New Mexico's 70 House seats, which do not exist in our data at all** — and whose day is
--   **2027-01-01, this file's own day**, under Art. XX § 3(A) with Art. IV § 4 supplying the
--   two-year term. `P10` refuses to run if a legislative office or race has appeared, because this
--   is the one state in the pass where the missing body would be **absorbed into the day this wave
--   created** rather than standing out from it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 NEW MEXICO IS THE SECOND STATE ON 2027-01-01, AS TERMS AS WELL AS AS DATES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **50 terms already begin on 2027-01-01**, every one of them Utah's (`CC_0490`). A gate asking
-- "how many terms start on January 1st?" would read 61 after this file and call it success.
-- ▶ `P11` pins the before-image and assertion 3 asserts the delta is exactly 11 and that every
-- term on the day belongs to New Mexico or Utah. ⚠ The near miss as terms is **2027-01-04 with 229
-- terms** across four states — the day "the next working day after a Friday public holiday" would
-- produce.

BEGIN;

CREATE TEMP TABLE cc0506_pin ON COMMIT DROP AS
SELECT 11                                 AS expect_winners,
       11                                 AS expect_offices,
       6                                  AS expect_reelections,
       5                                  AS expect_new,
       11                                 AS expect_predecessors,
       1                                  AS expect_predecessors_dated,
       50                                 AS expect_terms_on_the_day_before,
       229                                AS expect_terms_first_monday_before,
       '69f7470ea2e442a225dd40ac6b0f7b94' AS expect_digest,
       DATE '2027-01-01'                  AS expect_term_start,
       DATE '2027-01-04'                  AS expect_first_monday,
       DATE '2019-01-01'                  AS expect_grisham_start;

-- 🟢 NO SIBLING EXPANSION: every race is single-seat, so a winner is keyed on the office that
--    carried their own race. P2 measures that rather than assuming it.
CREATE TEMP TABLE cc0506_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       o.title                                           AS title,
       (win.value ->> 'id')::uuid                        AS politician_id,
       (win.value ->> 'name')                            AS winner_name,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id')) AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       si.rule_id                                        AS rule_id,
       och.politician_id                                 AS holder_before,
       w.certainty                                       AS certainty,
       w.winner_count                                    AS winner_count
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'nm'
   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0506_pre ON COMMIT DROP AS
SELECT s.office_id, t.id AS term_id, t.politician_id, t.term_start, t.term_end, t.how_ended
  FROM cc0506_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

CREATE TEMP TABLE cc0506_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-01')
                                                                                   AS terms_on_the_day,
       -- 🔴 The near miss as TERMS. 2027-01-04 is the first Monday, where four states already sit.
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-04')
                                                                                   AS terms_jan4,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0506_pre)                                           AS predecessors,
       (SELECT md5(string_agg(och.office_id::text || ':'
                              || COALESCE(och.politician_id::text, '-'),
                              '|' ORDER BY och.office_id::text))
          FROM essentials.office_current_holder och)                               AS holders_md5,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o2 ON o2.id = m.office_id
         WHERE NOT o2.is_vacant)                                                   AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices_missing_terms)                     AS missing_all;

DO $$
DECLARE n bigint; d text; p record; b record;
BEGIN
  SELECT * INTO p FROM cc0506_pin;
  SELECT * INTO b FROM cc0506_before;

  -- P1 — ⚠ ASKED ABOVE EVERY COUNT. On a second run the seats have left office_pending_winner, so
  -- a count check fires first and blames the data for what is a repeat apply.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0506%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % office_terms row(s) already cite CC_0506. Applied before.', n;
  END IF;

  -- P2 — the shape of the wave, including the single-seat property this selection depends on.
  SELECT count(*) INTO n FROM cc0506_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P2: selection returned % winner rows, expected %.', n, p.expect_winners;
  END IF;
  SELECT count(DISTINCT office_id) INTO n FROM cc0506_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P2: % distinct offices, expected %.', n, p.expect_offices;
  END IF;
  SELECT count(*) INTO n FROM cc0506_sel WHERE winner_count <> 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 11 races carry more than one winner. 🔴 THIS SELECTION KEYS '
                    'EVERY WINNER ON THE RACE-CARRYING OFFICE, which is only correct while every '
                    'race is single-seat. Under Ruling A the extra winners belong in SIBLING '
                    'offices, post-verify 1 would not find their terms, and this file would abort '
                    'AFTER writing.', n;
  END IF;

  -- P3 — the pin. 🔴 THE COVERAGE COUNT FIRST: a NULL is_reelection renders the whole
  -- concatenation NULL and string_agg skips it, so the digest can cover fewer rows than the counts
  -- claim — and it is the holderless seats it drops. ⚠ IT CANNOT OCCUR IN NEW MEXICO, because all
  -- 11 seats are held and none is flagged vacant. The gate is here anyway: CC_0487 kept it in the
  -- same position and a control proved the two gates are complementary, not redundant.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0506_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: the digest expression evaluated to NULL on % of % row(s), so string_agg '
                    'would have skipped them and the digest below would cover fewer rows than '
                    'every count above claims. is_reelection is NULL on a seat with no current '
                    'holder — all 11 New Mexico seats were held when this file was written, so '
                    'one has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;
  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text, politician_id::text))
    INTO d FROM cc0506_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P3: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a different '
                    'office, a different winner, or a seat that changed hands before the '
                    'handover.', d, p.expect_digest;
  END IF;
  SELECT count(*) INTO n FROM cc0506_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P3: % re-elections, expected %.', n, p.expect_reelections;
  END IF;
  SELECT count(*) INTO n FROM cc0506_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P3: % handovers, expected % — five New Mexico seats change hands, which is '
                    'what lets step 9''s live probe be read by the incoming NAME rather than only '
                    'by the date.', n, p.expect_new;
  END IF;
  -- ⚠ AND THE NAMES, because a count is true of whoever is in the selection.
  SELECT count(*) INTO n
    FROM cc0506_sel
   WHERE (title = 'Governor'                                  AND winner_name = 'Debra Haaland')
      OR (title = 'Lieutenant Governor'                       AND winner_name = 'Stephanie Garcia Richard')
      OR (title = 'Secretary of State'                        AND winner_name = 'Amanda López Askin')
      OR (title = 'State Auditor'                             AND winner_name = 'Joseph Maestas')
      OR (title = 'Treasurer'                                 AND winner_name = 'Laura Montoya')
      OR (title = 'Attorney General'                          AND winner_name = 'Raul Torrez')
      OR (title = 'Commissioner of Public Lands'              AND winner_name = 'Juan Sanchez III')
      OR (title = 'Public Education Commissioner, District 2' AND winner_name = 'Ken Pascoe')
      OR (title = 'Public Education Commissioner, District 3' AND winner_name = 'Jacob Trujillo')
      OR (title = 'Public Education Commissioner, District 5' AND winner_name = 'Sharon E. Clahchischilliage')
      OR (title = 'Public Education Commissioner, District 6' AND winner_name = 'Stewart Ingham');
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P3: only % of the 11 (office, winner) pairs match the names this file was '
                    'written for. The digest moved or a name changed; read the selection before '
                    'seating it.', n;
  END IF;

  -- P4 — the date, READ from office_swearing_in and never typed here. ⚠ AND THE RULE_ID TOO,
  -- because this wave has TWO and a seat dated under the wrong body's instrument would still
  -- carry the right day.
  SELECT count(*) INTO n FROM cc0506_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 11 seats have no swearing-in date, or one that is not %. '
                    'CC_0505 writes it; if this fires, that file has not run. ⚠ If the date reads '
                    '2027-01-04 somebody has given these offices THE FIRST MONDAY — 229 live '
                    'terms in Arizona, Wisconsin, California and Idaho — which is the misreading '
                    'a Friday public holiday invites, and neither instrument carries a "next '
                    'business day" clause.', n, p.expect_term_start;
  END IF;
  SELECT count(*) INTO n FROM cc0506_sel
   WHERE rule_id NOT IN ('nm-const-art5-1-first-day-of-january',
                         'nm-22-3b-3-january-1-next-succeeding');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % seat(s) are dated under a rule this file does not know. New Mexico has '
                    'TWO instruments for one day — Art. V § 1 for the executives and HB 9 § 3(B) '
                    'for the Commission — and a seat carrying the other body''s rule_id would '
                    'still have the right date, so no date check can see it.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0506_sel
   WHERE basis IS DISTINCT FROM 'statute' AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % date(s) have a basis that is neither statute nor published. An estimate '
                    'may not seat anybody — a term start is a legal fact.', n;
  END IF;

  -- P5 — 🔴🔴 THE RESULTS GAP IS PUBLIC EDUCATION COMMISSION DISTRICT 7, AND IT IS PINNED RATHER
  -- THAN TIDIED. HB 9 § 3(C) put five districts on this ballot and we hold four. The seat changed
  -- hands; Patricia Gipson stays on our pages until the RESULT arrives.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.offices o   ON o.id = r.office_id
   WHERE o.title = 'Public Education Commissioner, District 7';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % 2026 race row(s) now exist for Public Education Commissioner, District '
                    '7, expected 0. 🟢 That is good news and it makes this wave LARGER — '
                    're-derive the pin, extend CC_0505 to five Commission seats, and seat '
                    'Frederick Walton Parker.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och
    JOIN essentials.offices o     ON o.id = och.office_id
    JOIN essentials.politicians p2 ON p2.id = och.politician_id
   WHERE o.title = 'Public Education Commissioner, District 7' AND p2.full_name = 'Patricia Gipson';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P5: Public Education Commissioner District 7 is not held by Patricia Gipson '
                    '(% matching row(s)). She is the person the missing result leaves in a seat '
                    'she lost. If the row has moved, somebody has acted on the gap.', n;
  END IF;
  -- 🟢 AND SHE IS NOT IN THIS WAVE, so this file leaves nobody in a seat they lost. Measured.
  SELECT count(*) INTO n
    FROM cc0506_sel s
    JOIN essentials.politicians p2 ON p2.id = s.politician_id
   WHERE p2.full_name = 'Patricia Gipson';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: Patricia Gipson appears in this wave as a winner (% row(s)). She is the '
                    'District 7 holder whose seat has no recorded result; if she is winning '
                    'something here, read it before seating.', n;
  END IF;

  -- P6 — not flagged is_vacant, and the predecessor pre-image, which is what this file overwrites.
  SELECT count(*) INTO n
    FROM cc0506_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % of the 11 offices are flagged is_vacant. A FUTURE-dated seating does '
                    'not clear a flag; that needs a companion file of the CC_0480 / CC_0486 kind, '
                    'applied on the handover day with a data interlock.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0506_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) captured, expected % — one per seat. A seat with '
                    'nobody in it is a fact to read, not to seat over.', n, p.expect_predecessors;
  END IF;
  SELECT count(*) INTO n FROM cc0506_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date no file has written down.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0506_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;
  -- 🟢🟢 THE ONE DATED PREDECESSOR, NAMED — IT IS CC_0505'S ONLY IN-DATA EVIDENCE.
  SELECT count(*) INTO n FROM cc0506_pre WHERE term_start IS NOT NULL;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION 'P6: % predecessor term(s) carry a term_start, expected % — Michelle Lujan '
                    'Grisham''s %. The other ten are the ADR 0002 phase-2 backfill and a '
                    'Ballotpedia roster read, all with start_precision unknown.',
      n, p.expect_predecessors_dated, p.expect_grisham_start;
  END IF;
  SELECT count(*) INTO n
    FROM cc0506_pre WHERE term_start IS NOT NULL AND term_start <> p.expect_grisham_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % dated predecessor term(s) carry a start this file does not know. The '
                    'one it knows, Michelle Lujan Grisham''s %, IS January 1st of its own year '
                    'and is the ONLY corroboration Art. XX § 3(A) and Art. V § 1 have inside our '
                    'data — a corpus of one.', n, p.expect_grisham_start;
  END IF;
  -- Every re-election's predecessor must be the winner, and every handover's must not be. 🟢 BOTH
  -- ARMS ARE REACHABLE HERE, unlike Idaho, where seven of seven were re-elections and the second
  -- arm was unreachable by construction.
  SELECT count(*) INTO n
    FROM cc0506_pre x JOIN cc0506_sel s ON s.office_id = x.office_id
   WHERE s.is_reelection AND x.politician_id IS DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a re-election have a predecessor who is not the '
                    'winner — that is a handover nobody has read.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0506_pre x JOIN cc0506_sel s ON s.office_id = x.office_id
   WHERE NOT s.is_reelection AND x.politician_id IS NOT DISTINCT FROM s.politician_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) marked as a handover have the winner as their own '
                    'predecessor.', n;
  END IF;

  -- P7 — Ruling B: every row was called, not certified, when this was written.
  SELECT count(*) INTO n FROM cc0506_sel WHERE certainty IS DISTINCT FROM 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % of the 11 results are no longer "called". If New Mexico has certified '
                    'since 2026-11-24 the terms this file writes should say "certified" instead — '
                    'the wording is what a reversed canvass is found by.', n;
  END IF;

  -- P8 — 🔴 NOBODY IN THIS WAVE ENDS UP HOLDING TWO SEATS ON THE HANDOVER DAY. Asked BEFORE the
  -- write, when it is trivially true: Stephanie Garcia Richard holds one office now (Public Lands)
  -- and wins another (Lieutenant Governor). The gate that matters is assertion 9, after the write.
  SELECT count(*) INTO n FROM (
    SELECT t.politician_id, count(DISTINCT t.office_id) AS seats
      FROM essentials.office_terms t
     WHERE t.politician_id IN (SELECT politician_id FROM cc0506_sel WHERE politician_id IS NOT NULL)
       AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
       AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
     GROUP BY 1) z WHERE seats > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % winner(s) already hold more than one office covering %. Seating them '
                    'would leave a named person in two seats at once on our pages. The fix is the '
                    'RESULT that is missing, never tidying the term rows.', n, p.expect_term_start;
  END IF;

  -- P9 — 🟢🟢 THE FIXTURE FOR THAT ZERO IS REAL, IT IS NAMED, AND BOTH ITS LEGS ARE IN THIS WAVE.
  -- Stephanie Garcia Richard is the sitting Commissioner of Public Lands and the winner of the
  -- Lieutenant Governorship. The seat she leaves has a recorded successor IN this wave, so it
  -- closes itself — Oregon's Helfrich, not Utah's Fiefia. ⚠ If that stopped being true, she would
  -- hold two seats from 2027-01-01 and assertion 9 would catch it; this gate exists so the zero is
  -- never VACUOUS, which is what it was in Idaho.
  SELECT count(*) INTO n
    FROM cc0506_sel s
    JOIN essentials.office_terms t ON t.politician_id = s.politician_id
   WHERE t.office_id <> s.office_id;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P9: % term(s) outside the office they won are held by one of this wave''s '
                    'winners, expected exactly 1 — Stephanie Garcia Richard''s Commissioner of '
                    'Public Lands term, the seat she leaves for the Lieutenant Governorship. '
                    '🔴 IT IS THE ONLY REAL FIXTURE THIS WAVE HAS FOR "nobody holds two seats"; '
                    'with 0 the zero goes vacuous (Idaho''s case, where it had to be PLANTED) and '
                    'with more than 1 there is a mover nobody has read.', n;
  END IF;
  SELECT count(*) INTO n
    FROM cc0506_sel s
    JOIN essentials.office_terms t  ON t.politician_id = s.politician_id AND t.office_id <> s.office_id
    JOIN essentials.politicians  p2 ON p2.id = s.politician_id
   WHERE p2.full_name = 'Stephanie Garcia Richard'
     AND s.title = 'Lieutenant Governor'
     AND t.office_id IN (SELECT office_id FROM cc0506_sel);
  IF n <> 1 THEN
    RAISE EXCEPTION 'P9: the one cross-office term is not Stephanie Garcia Richard''s, or the seat '
                    'she leaves is NOT inside this wave (% matching row(s)). 🔴 THAT DISTINCTION '
                    'IS THE WHOLE POINT: inside the wave it closes itself, because Juan Sanchez '
                    'III is seated into Commissioner of Public Lands on the same day. Outside it '
                    'she would hold two seats indefinitely and would need reading, not seating — '
                    'Utah''s Doug Fiefia, where the vacated seat''s own result was missing.', n;
  END IF;
  -- 🟢 AND THE CONSTITUTION PREDICTS BOTH OF THIS WAVE'S TERM-LIMITED DEPARTURES. Art. V § 1:
  -- "such officers shall, after having served two terms in a state office, be ineligible to hold
  -- that state office until one full term has intervened." Michelle Lujan Grisham and Stephanie
  -- Garcia Richard have each served two in the office they are leaving.
  SELECT count(*) INTO n
    FROM cc0506_pre x
    JOIN cc0506_sel s  ON s.office_id = x.office_id
    JOIN essentials.politicians p2 ON p2.id = x.politician_id
   WHERE NOT s.is_reelection
     AND s.title IN ('Governor', 'Commissioner of Public Lands')
     AND p2.full_name IN ('Michelle Lujan Grisham', 'Stephanie Garcia Richard');
  IF n <> 2 THEN
    RAISE EXCEPTION 'P9: % of the 2 term-limited departures are present, expected 2 — Michelle '
                    'Lujan Grisham leaving the Governorship and Stephanie Garcia Richard leaving '
                    'Commissioner of Public Lands, each after two terms, which Art. V § 1''s '
                    'second paragraph bars them from holding again until one full term has '
                    'intervened. They are the only two handovers this wave can explain from the '
                    'LAW rather than from the data, so losing them costs a corroboration.', n;
  END IF;

  -- P10 — 🔴🔴 THE LEGISLATURE IS ABSENT AND ITS DAY IS THIS FILE'S DAY.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'nm' AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P10: New Mexico now holds % legislative office row(s), expected 0 when this '
                    'file was written. 🔴 Art. IV § 4 gives representatives a two-year term, so '
                    'all 70 House seats were on this ballot as a matter of law, and Art. XX '
                    '§ 3(A) commences them on THIS FILE''S DAY. Dated now they would be absorbed '
                    'into 2027-01-01 and stand out from nothing. Read CC_0505''s header first.', n;
  END IF;

  -- P11 — 🔴 THE DAY'S BEFORE-IMAGE. New Mexico is the SECOND state on 2027-01-01, so this is a
  -- delta and never a total; and the first Monday is pinned because it is the near miss.
  IF b.terms_on_the_day <> p.expect_terms_on_the_day_before THEN
    RAISE EXCEPTION 'P11: % term(s) already begin on %, expected % (all of them Utah''s, CC_0490). '
                    'A third state has landed on this day — name its rule before adding 11 to the '
                    'pile.', b.terms_on_the_day, p.expect_term_start,
      p.expect_terms_on_the_day_before;
  END IF;
  IF b.terms_jan4 <> p.expect_terms_first_monday_before THEN
    RAISE EXCEPTION 'P11: % term(s) begin on % (THE FIRST MONDAY), expected %. It is read here so '
                    'that "no New Mexico seat landed on it" is a discrimination against a '
                    'populated day rather than a statement about an empty one.',
      b.terms_jan4, p.expect_first_monday, p.expect_terms_first_monday_before;
  END IF;
END $$;

-- 🔴 THE INCUMBENCY GUARD'S SCOPE IS A UNION OF WINNERS AND PREDECESSORS. ⚠ In New Mexico the two
--    sets genuinely differ — six re-elections overlap, five handovers do not, and Stephanie Garcia
--    Richard is in BOTH halves for two different offices — so the union is larger than either
--    side, which is the case Idaho could not exercise (there the two sets were identical).
CREATE TEMP TABLE cc0506_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0506_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0506_pre WHERE politician_id IS NOT NULL;

CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM cc0506_guarded);

DO $$
DECLARE s record; v_seated int := 0;
BEGIN
  FOR s IN SELECT * FROM cc0506_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => s.office_id,
      p_politician_id    => s.politician_id,
      p_term_start       => s.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran. Term begins '
                         || to_char(s.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in. THREE INSTRUMENTS AGREE ON THAT '
                         || 'DAY: N.M. Const. Art. XX § 3(A) commences "every state, county or '
                         || 'district officer" on "the first day of January next after the '
                         || 'officer''s election"; Art. V § 1 elects the seven state executives '
                         || '"for terms of four years beginning on the first day of January next '
                         || 'after their election"; and Laws 2021 (2nd S.S.) ch. 3 (HB 9) § 3(B), '
                         || 'NMSA 1978 § 22-3B-3, elects public education commissioners "for '
                         || 'terms commencing on January 1 next succeeding their election". '
                         || 'Art. V § 1''s "unless otherwise provided in the constitution of New '
                         || 'Mexico" was discharged by sweeping all 24 articles and 270 sections: '
                         || 'the oath (Art. XX § 1) binds "before entering upon his duties", the '
                         || 'holdover (Art. XX § 2) governs occupancy and not commencement, and '
                         || 'Art. XXII § 22 — which says terms commence "on the date of their '
                         || 'qualification" — is the 1912 Schedule and is dead. '
                         || CASE WHEN s.is_reelection
                              THEN 'RE-ELECTED INCUMBENT: the predecessor on this seat is the '
                                   || 'winner, and their own term is closed at '
                              ELSE 'HANDOVER: the predecessor''s term is closed at ' END
                         || to_char(s.term_start - 1, 'YYYY-MM-DD')
                         || ', which is the day Art. XX § 3(B) and HB 9 § 16(B) both name as the '
                         || 'end of a term ("a term ending on December 31 after the next general '
                         || 'election"). 🔴 THIS DAY IS NOT THE WHOLE STATE''S RECORD: Public '
                         || 'Education Commission District 7 was on this ballot under HB 9 '
                         || '§ 3(C) and we hold NO race row for it, so its sitting holder keeps a '
                         || 'seat she lost until the result arrives; and New Mexico''s 70 House '
                         || 'seats do not exist in our data at all although Art. XX § 3(A) puts '
                         || 'them on this very day. CC_0506',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => s.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0506: seat_officeholder called for % offices', v_seated;
END $$;

DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0506_guarded;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  -- ⚠ THE UNION IS LARGER THAN EITHER SIDE HERE, which is the property Idaho could not exercise.
  IF v_planned <= 11 THEN
    RAISE EXCEPTION 'incumbency guard: the guarded set is % people, which is not larger than the '
      '11 winners. Five New Mexico seats change hands, so the predecessors bring four further '
      'people in (Michelle Lujan Grisham, Howie Morales, Maggie Toulouse Oliver and Timothy '
      'Beck) — Stephanie Garcia Richard is in both halves for two different offices. If the union '
      'has collapsed to the winners, the guard''s scope is narrower than its name.', v_planned;
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;
  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id,
           b.politician_id,
           a.stored,
           a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b
      JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(pol.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(pol.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians pol ON pol.id = c.politician_id;
  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;
  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

DO $$
DECLARE n bigint; m text; b record; p record;
BEGIN
  SELECT * INTO b FROM cc0506_before;
  SELECT * INTO p FROM cc0506_pin;

  -- 1. Eleven terms exist, on the offices this file selected, for the people it selected.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated term(s) on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. The read path answers for all eleven.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0506_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seat(s).', n, p.expect_offices;
  END IF;

  -- 3. The day's delta, and every term on it belongs to a named state.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE t.term_start = p.expect_term_start AND lower(dd.state) NOT IN ('nm', 'ut');
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to a state other than New Mexico or Utah. A date '
                    'shared by two states is a coincidence of calendars, never a shared rule — '
                    'name the new one before absorbing it.', n, p.expect_term_start;
  END IF;
  -- 3b. 🔴 AND NO NEW MEXICO SEAT LANDED ON THE FIRST MONDAY, which is a POPULATED day.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (p.expect_first_monday, DATE '2027-01-19', DATE '2026-12-31');
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % New Mexico term(s) start on a wrong day — % (the FIRST MONDAY, 229 live '
                    'terms in four states, and the misreading a Friday public holiday invites), '
                    '2027-01-19 (the third Tuesday, NEW MEXICO''S OWN session convening day under '
                    'Art. IV § 5(A)) or 2026-12-31 (the day these terms END).',
      n, p.expect_first_monday;
  END IF;
  IF b.terms_jan4 <> (SELECT count(*) FROM essentials.office_terms
                       WHERE term_start = p.expect_first_monday) THEN
    RAISE EXCEPTION '3c: the first Monday''s term count moved from %. This file must not have '
                    'touched that day — it belongs to Arizona, Wisconsin, California and Idaho.',
      b.terms_jan4;
  END IF;

  -- 4. Nobody moved TODAY. A future-dated term must not change who holds a seat now.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not move '
                    'a seat today — and that includes Stephanie Garcia Richard, who stays '
                    'Commissioner of Public Lands until 2026-12-31 although she is seated as '
                    'Lieutenant Governor from 2027-01-01.', b.holders_md5, m;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0506_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of the 11 seats still answer office_current_holder with the person '
                    'holding them today, expected %.', n, p.expect_offices;
  END IF;

  -- 6. Every predecessor closed on the day before the handover, and the one dated row kept its
  --    start. 🟢 THAT ROW IS THE ONLY IN-DATA EVIDENCE CC_0505'S RULE HAS.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0506_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_pre x ON x.term_id = t.id
   WHERE t.term_start IS DISTINCT FROM x.term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '6b: % closed predecessor term(s) had their term_start moved. '
                    'seat_officeholder writes nothing to a closed row''s source, so a lost start '
                    'is unrecoverable — and Michelle Lujan Grisham''s % IS January 1st of its own '
                    'year and is the ONLY corroboration Art. XX § 3(A) has inside our data.',
      n, p.expect_grisham_start;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_pre x ON x.term_id = t.id
   WHERE t.term_start = p.expect_grisham_start;
  IF n <> p.expect_predecessors_dated THEN
    RAISE EXCEPTION '6c: % closed predecessor term(s) carry the one known start %, expected %.',
      n, p.expect_grisham_start, p.expect_predecessors_dated;
  END IF;

  -- 7. Nothing closed between today and the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. No person or office was created or destroyed. 🟢 This wave has no people file, and it
  --    creates neither District 7's missing race nor the 70 absent House seats.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %. This wave has no people file — all 11 '
                    'winners already existed, which was swept for rather than read off the "no '
                    'record" column.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. 🔴🔴 NOBODY HOLDS TWO SEATS ON THE HANDOVER DAY, RE-ASKED AFTER THE WRITE. 🟢 THIS IS THE
  --    GATE THE WHOLE STEPHANIE GARCIA RICHARD CHAIN RESTS ON: she opens Lieutenant Governor on
  --    2027-01-01 and her Commissioner of Public Lands term must have been closed at 2026-12-31 by
  --    Juan Sanchez III's seating. If the Public Lands seating had been skipped or had failed, she
  --    would hold both and this would fire. ⚠ Unlike Idaho's, this zero has a REAL fixture.
  SELECT count(*) INTO n FROM (
    SELECT t.politician_id, count(DISTINCT t.office_id) AS seats
      FROM essentials.office_terms t
     WHERE t.politician_id IN (SELECT politician_id FROM cc0506_guarded)
       AND (t.term_start IS NULL OR t.term_start <= p.expect_term_start)
       AND (t.term_end   IS NULL OR t.term_end   >= p.expect_term_start)
     GROUP BY 1) z WHERE seats > 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % person/people now hold more than one office covering %. The one this '
                    'file expects to be at risk is Stephanie Garcia Richard — Commissioner of '
                    'Public Lands until 2026-12-31 and Lieutenant Governor from 2027-01-01 — '
                    'whose old seat closes only because Juan Sanchez III was seated into it.',
      n, p.expect_term_start;
  END IF;
  -- 9b. 🟢 AND THE CHAIN IS ASSERTED POSITIVELY, not only as the absence of a problem: her old
  --     term is CLOSED on the right day and her new one is OPEN on the right day.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o      ON o.id = t.office_id
    JOIN essentials.politicians p2 ON p2.id = t.politician_id
   WHERE p2.full_name = 'Stephanie Garcia Richard'
     AND ((o.title = 'Commissioner of Public Lands' AND t.term_end   = p.expect_term_start - 1)
       OR (o.title = 'Lieutenant Governor'          AND t.term_start = p.expect_term_start));
  IF n <> 2 THEN
    RAISE EXCEPTION '9b: Stephanie Garcia Richard''s two terms do not read back as a clean '
                    'handover (% of 2) — her Commissioner of Public Lands term must END on % and '
                    'her Lieutenant Governor term must BEGIN on %. A count of zero double-holders '
                    'is also true of somebody who was never seated at all.',
      n, p.expect_term_start - 1, p.expect_term_start;
  END IF;

  -- 10. Ruling B — every new term names the slot and says what it seated from.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start
     AND t.source LIKE '%CC_0506%' AND t.source LIKE '%called, not certified%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '10: % of % new terms cite CC_0506 and record that the result was called '
                    'rather than certified.', n, p.expect_offices;
  END IF;
  -- 10b. ⚠ AND THE RE-ELECTIONS AND HANDOVERS SAY WHICH THEY ARE, because the source line is what
  --      a reader reconstructing a reversed canvass has.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND s.is_reelection
     AND t.source LIKE '%RE-ELECTED INCUMBENT%';
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION '10b: % of % re-elected terms say so in their source.', n,
      p.expect_reelections;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0506_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND NOT s.is_reelection
     AND t.source LIKE '%HANDOVER%';
  IF n <> p.expect_new THEN
    RAISE EXCEPTION '10b: % of % handover terms say so in their source.', n, p.expect_new;
  END IF;

  -- 11. All eleven seats have left office_pending_winner, and New Mexico has none left at all.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0506_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '11: % of the 11 seats still answer office_pending_winner.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nm' AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '11b: % New Mexico seat(s) still answer office_pending_winner for this '
                    'election, expected 0 — New Mexico is complete after this wave. ⚠ That is a '
                    'statement about the seats we hold a RESULT for: Public Education Commission '
                    'District 7 and all 70 House seats are invisible to this count.', n;
  END IF;

  -- 12. No vacancy flag moved, and exactly 11 terms were added.
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '12: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '12b: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 13. The drift baseline held, and the view did not move — every one of the 11 seats already had
  --     a term, so none of them was ever in offices_missing_terms.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '13: the unflagged offices_missing_terms count moved % -> %. NEVER RAISE THE '
                    'BASELINE TO CLEAR THIS.', b.missing_unflagged, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '13b: offices_missing_terms went % -> %, expected no change.',
      b.missing_all, n;
  END IF;

  RAISE NOTICE 'CC_0506 OK: 11 New Mexico offices scheduled for % — 7 state executives and 4 '
               'Public Education Commissioners, 6 re-elections and 5 handovers, all called. '
               'Debra Haaland takes the Governorship from Michelle Lujan Grisham and Amanda '
               'López Askin the Secretaryship of State from Maggie Toulouse Oliver. 🟢🟢 THE '
               'INTERESTING ROW IS STEPHANIE GARCIA RICHARD, who leaves Commissioner of Public '
               'Lands for the Lieutenant Governorship on the same day: her old term closes at % '
               'ONLY because Juan Sanchez III is seated into it in this same wave, so the '
               '"nobody holds two seats" zero has a REAL fixture here rather than the planted one '
               'Idaho needed. Art. V § 1''s two-term limit explains both her move and Lujan '
               'Grisham''s departure, so two of the five handovers are predicted by the law and '
               'not merely observed. The date was READ from office_swearing_in and never typed, '
               'and no seat landed on % (the FIRST MONDAY, % live terms in four states, and the '
               'misreading a Friday public holiday invites). New Mexico is the SECOND state on '
               'this calendar day; % Utah terms were already here. 🔴🔴 AND TWO GAPS ARE LEFT '
               'EXACTLY AS THEY WERE: Public Education Commission District 7 was on this ballot '
               'under HB 9 § 3(C), we hold no race row for it, and Patricia Gipson therefore '
               'keeps a seat she lost — the fix is the RESULT; and New Mexico''s 70 House seats '
               'do not exist in our data although Art. XX § 3(A) puts them on THIS VERY DAY, so '
               'they must be given their own rule_id and never absorbed into these 11. Drift '
               'baseline % held.',
    p.expect_term_start, p.expect_term_start - 1, p.expect_first_monday, b.terms_jan4,
    b.terms_on_the_day, b.missing_unflagged;
END $$;

COMMIT;
