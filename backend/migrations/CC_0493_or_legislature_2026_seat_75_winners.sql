-- CC_0493 — Oregon: seat the 75 legislative winners of 2026-11-03, term beginning 2027-01-11.
--
--   75 offices · 60 re-elections · 15 handovers · 75 predecessors closed at 2027-01-10
--
-- Third of three. `CC_0491` wrote the dates, `CC_0492` created 13 people and linked 2. This file
-- writes the terms. The write-up is in backend/data/state-seating-2026/DATES.md § OR.
--
-- ── The pin ─────────────────────────────────────────────────────────────────────────────────
--   expect_winners      75        expect_offices       75
--   expect_reelections  60        expect_new           15
--   expect_predecessors 75        expect_term_start    2027-01-11
--   digest md5 = a995d10fa33a2c175294f75c5e392a7f
--
-- 🔴🔴 **THE PIN WAS CAPTURED AFTER `CC_0492`, NOT BEFORE, AND THE TWO DIFFER.** `derive-seating-
--     wave.mjs` prints **42da66dc1674f7c34788b45ad2f098bf** against production today, because
--     today 15 of the winners have no `politicians` row and the selection's `politician_id` is
--     NULL for them. Once `CC_0492` runs, those 15 ids exist and the digest is the one above.
--     ▶ The pin was taken by rehearsing `CC_0491 + CC_0492 + a probe` in one rolled-back
--     transaction, which is the only world in which this file's P1 is meaningful.
--
-- 🟢 **OREGON CANNOT PRODUCE THE `is_reelection` NULL, AND THAT IS MEASURED RATHER THAN HOPED.**
--   All 75 seats are held today — `holderless_seats` is 0 before the people file and after it —
--   so `och.politician_id IS NOT NULL` changes nothing here and the digest covers all 75 rows.
--   Both gates are in the file anyway: the digest gate catches a value that CHANGED, the
--   coverage gate catches a row that VANISHED, and they are complementary rather than redundant.
--   California found the defect with 2 vacant seats of 92; Massachusetts showed it can appear
--   only AFTER the people file runs.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 WASHINGTON'S 118 TERMS ALREADY BEGIN ON THIS DAY — EVERY COUNT HERE IS A DELTA
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `CC_0488` seated 118 Washington legislators with `term_start = 2027-01-11` under RCW
-- 44.04.021. Oregon's day comes from its constitution, Art. IV Sec. 4(1). Same calendar day,
-- unrelated rules. 🔴 **A "terms starting 2027-01-11" assertion that read 193 as a total would
-- look exactly like success.** Assertion 3 pins the delta at 75 against a pre-image of 118, and
-- P10 asserts the pre-image is the 118 this file was written against.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 ONE WINNER VACATES A SEAT IN THIS SAME WAVE, AND UNLIKE UTAH IT RESOLVES ITSELF
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Jeff Helfrich** holds **State House District 52** and wins **State Senate District 26** —
-- and Art. IV Sec. 6(5) with the Chief Clerk's own pairing put HD 52 *inside* SD 26.
--
-- 🟢 **HIS HOUSE SEAT HAS A RECORDED SUCCESSOR, SO NOTHING IS LEFT DANGLING.** Hank Sanders wins
--   House District 52 in this same wave. `seat_officeholder` closes the predecessor on the seat
--   it is seating, so seating Sanders on HD 52 closes Helfrich's House term at 2027-01-10, and
--   seating Helfrich on SD 26 closes Christine Drazan's Senate term at 2027-01-10. Both
--   closures happen because of a seat being FILLED, which is the only way this file closes
--   anything. Assertion 11 measures the whole switch.
--
-- ⚠ **CONTRAST WITH UTAH, WHERE THE SAME SHAPE COULD NOT RESOLVE.** Doug Fiefia kept Utah House
--   District 48 open after taking a Senate seat, because HD 48's own 2026 result is missing and
--   there was nobody to seat. ▶ **The difference is a result, not a rule.** Oregon has no
--   results gap, so the vacated seat closes itself.
--
-- 🟢 **AND ONE WINNER KEEPS A SEAT THIS FILE DOES NOT TOUCH, WHICH IS ALSO CORRECT.** Tammy
--   Carpenter wins House District 27 and stays a Director of Beaverton School District 48J —
--   a SCHOOL seat, outside this wave, whose term has not ended. She holds two seats from
--   2027-01-11. P8 asserts there is exactly one such term and names her; assertion 12 asserts it
--   is still open afterwards. ▶ **Do not tidy it.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- RULING B — SEATED FROM A `called` RESULT, AND THE FILE RECORDS WHICH
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- All 75 winners carry `result_certainty = 'called'`; **not one is `certified`**, and every term
-- this file writes says so in its own `source`.
--
-- ⚠ **OREGON HAS NOT CERTIFIED YET, AND THE STATUTE SAYS WHEN IT WILL.** ORS 254.545(1): "not
--   later than the **37th day after any election**, the Secretary of State … shall (a) Canvass
--   the votes for the offices". The 37th day after 2026-11-03 is **2026-12-10**. The Secretary
--   of State's own results site still says "Unofficial" and was last updated 2026-11-23.
--
-- 🔴🔴 **AND THAT SAME SENTENCE CARRIES AN EXCEPTION THAT IS THE GOVERNOR'S REFUSAL IN STATUTE
--     FORM:** the Secretary canvasses every office *"**except the office of Governor after the
--     general election**"*. Or. Const. Art. V Sec. 4 says why — the returns for Governor are
--     "sealed up, and transmitted to the Secretary of State; **directed to the Speaker of the
--     House of Representatives, who shall open, and publish them in the presence of both houses
--     of the Legislative Assembly**". ▶ **Oregon's Governor is not merely undated here; the
--     state does not canvass that race through the same channel as the other 75.** Assertion 10
--     refuses to seat the Governor and assertion 10b asserts the seat is still visibly pending.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 ALL 75 WINNERS WERE CONFIRMED AGAINST THE STATE'S OWN RESULTS BEFORE ANY OF THIS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Our winners come from the AP race calls. They were compared candidate by candidate against the
-- **Oregon Secretary of State's own legislative results export**: 75 contests parsed, 75 agree,
-- 0 disagree, 0 missing — with one name deliberately corrupted first and the comparison watched
-- going red before the real run.
--
-- 🟢 **THE EXPORT IS REACHABLE WITHOUT A BROWSER, AND THE ROUTE IS WORTH WRITING DOWN.**
--   `https://results.oregonvotes.gov/ResultsExport.aspx` is an ASP.NET page whose export links
--   are `__doPostBack` JavaScript, so there is no GET URL for the file. A plain HTTP **POST**
--   carrying the page's own `__VIEWSTATE`, `__VIEWSTATEGENERATOR` and `__EVENTVALIDATION`, with
--   `__EVENTTARGET = ctl00$MainContent$Legislative` and the CSV radio, returns
--   `Content-Disposition: attachment; filename=House and Senate.csv` — 36,024 bytes, HTTP 200,
--   no browser. ▶ **Read the form before reaching for Playwright.** This is the same lesson as
--   Utah's XML download, in a different disguise: the machine-readable route exists and is not
--   linked as a URL.
--   ⚠ The export reports "0 out of 47 Precincts Reported" beside real vote totals. Oregon votes
--     by mail and does not report by precinct; that zero is not a count of anything.
--
-- ⚠ **The 15 Senate seats with no race row are the staggered half, not a gap** — Art. IV Sec.
--   4(2) elects one-half biennially, and the state's own export holds exactly 75 legislative
--   contests, not 90. See `CC_0491`'s header.
--
-- Sources, read 2026-11-23: https://results.oregonvotes.gov/ResultsExport.aspx ·
--   https://www.oregonlegislature.gov/bills_laws/ors/ors254.html (HTTP 200, 267,074 bytes) ·
--   https://www.oregonlegislature.gov/bills_laws/Pages/OrConst.aspx

BEGIN;

CREATE TEMP TABLE cc0493_pin ON COMMIT DROP AS
SELECT 75                                 AS expect_winners,
       75                                 AS expect_offices,
       60                                 AS expect_reelections,
       15                                 AS expect_new,
       75                                 AS expect_predecessors,
       'a995d10fa33a2c175294f75c5e392a7f' AS expect_digest,
       DATE '2027-01-11'                  AS expect_term_start;
-- All three counts coincide at 75: one winner per office, every office held. 🔴 THEY ARE
-- SEPARATE CLAIMS AND ARE CHECKED SEPARATELY — in Massachusetts the predecessor count was 197
-- against 199 winners, and reading one number as the other is how that goes unnoticed.

-- 🔴 `WAVE_SELECTION_SQL` with ONE addition: `och.politician_id IS NOT NULL` closes the NULL a
--    holderless seat otherwise puts into `is_reelection`. Oregon has no holderless seat, so it
--    changes nothing here — see the header. It is here because the gate below has to be able to
--    tell.
CREATE TEMP TABLE cc0493_sel ON COMMIT DROP AS
SELECT o.id                                              AS office_id,
       (win.value ->> 'id')::uuid                        AS politician_id,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,
       si.swearing_in_date                               AS term_start,
       si.basis                                          AS basis,
       d.label                                           AS seat,
       d.district_type                                   AS district_type,
       (win.value ->> 'name')                            AS winner_name,
       och.politician_id                                 AS holder_before
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = DATE '2026-11-03'
 WHERE lower(d.state) = 'or'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0493_pre ON COMMIT DROP AS
SELECT s.office_id, s.seat, t.id AS term_id, t.politician_id, t.term_start, t.term_end,
       t.how_ended
  FROM cc0493_sel s
  JOIN essentials.office_terms t ON t.office_id = s.office_id
 WHERE (t.term_start IS NULL OR t.term_start <= s.term_start)
   AND (t.term_end   IS NULL OR t.term_end   >= s.term_start);

-- The offices OUTSIDE this wave that a winner here still holds. Named so assertion 12 can prove
-- this file left them alone, rather than nobody noticing it had not.
CREATE TEMP TABLE cc0493_kept ON COMMIT DROP AS
SELECT t.id AS term_id, p.full_name, d.label AS seat, d.district_type
  FROM essentials.office_terms t
  JOIN essentials.offices o     ON o.id = t.office_id
  JOIN essentials.districts d   ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = t.politician_id
 WHERE t.politician_id IN (SELECT politician_id FROM cc0493_sel)
   AND NOT EXISTS (SELECT 1 FROM cc0493_sel s WHERE s.office_id = t.office_id)
   AND t.term_end IS NULL;

CREATE TEMP TABLE cc0493_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_terms)                              AS terms_all,
       (SELECT count(*) FROM essentials.office_terms WHERE term_start = DATE '2027-01-11')
                                                                                   AS terms_on_the_day,
       (SELECT count(*) FROM essentials.politicians)                               AS politicians,
       (SELECT count(*) FROM essentials.offices)                                   AS offices,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant)                   AS vacant_all,
       (SELECT count(*) FROM cc0493_pre)                                           AS predecessors,
       (SELECT count(*) FROM cc0493_kept)                                          AS kept,
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
  SELECT * INTO p FROM cc0493_pin;
  SELECT * INTO b FROM cc0493_before;

  -- P2 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE THE ROW COUNTS. On a
  -- second run the seats have left office_pending_winner, so P1 would return 0 and report that
  -- the data moved — which is true of the view and false of the world.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE source LIKE '%CC_0493%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % office_terms row(s) already cite CC_0493. Applied before.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0493_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: selection returned % winner rows, expected %. The data moved under this '
                    'file. ⚠ Oregon had NO legislative results gap when this was written — 60 of '
                    '60 House seats and 15 of 30 Senate seats carried a 2026 race and a winner — '
                    'so a different number here is a change, not a backlog being filled.',
      n, p.expect_winners;
  END IF;

  SELECT count(DISTINCT office_id) INTO n FROM cc0493_sel;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION 'P1: % offices, expected %.', n, p.expect_offices;
  END IF;

  -- 🔴 THE DIGEST MUST COVER EVERY ROW IT CLAIMS TO. string_agg drops NULL input silently, so a
  --    digest over 75 rows and one over 73 of them look alike.
  SELECT count(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
               || is_reelection::text)
    INTO n FROM cc0493_sel;
  IF n <> p.expect_winners THEN
    RAISE EXCEPTION 'P1: the digest expression evaluated to NULL on % of % rows, so string_agg '
                    'would have skipped them. is_reelection is NULL on a seat with no current '
                    'holder — when this file was written all 75 Oregon legislative seats in this '
                    'wave were held, so one has fallen vacant. Read it before seating over it.',
      p.expect_winners - n, p.expect_winners;
  END IF;

  SELECT md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
                        || is_reelection::text,
                        '|' ORDER BY office_id::text))
    INTO d FROM cc0493_sel;
  IF d IS DISTINCT FROM p.expect_digest THEN
    RAISE EXCEPTION 'P1: selection digest is %, expected %. Every count above passed, so the '
                    'membership is the same size and something inside it changed — a winner '
                    'swapped, or a seat changed hands before the handover. ⚠ If it reads '
                    '42da66dc1674f7c34788b45ad2f098bf, CC_0492 has not run: that is this same '
                    'selection with 15 NULL winner ids.', d, p.expect_digest;
  END IF;

  SELECT count(*) INTO n FROM cc0493_sel WHERE is_reelection;
  IF n <> p.expect_reelections THEN
    RAISE EXCEPTION 'P1: % re-elections, expected %.', n, p.expect_reelections;
  END IF;

  SELECT count(*) INTO n FROM cc0493_sel WHERE NOT is_reelection;
  IF n <> p.expect_new THEN
    RAISE EXCEPTION 'P1: % new holders, expected %. (Counted with NOT, which a NULL would fail '
                    'as well — 60 + 15 = 75 only if every row is a real boolean.)',
      n, p.expect_new;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM cc0493_sel GROUP BY office_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % office(s) carry more than one winner. Oregon has no multi-member '
                    'legislative district, so this is Ruling A arriving where it was not '
                    'expected — stop and read the race.', n;
  END IF;

  -- P4 — 🔴 THE DATE IS READ, NEVER CARRIED. CC_0491 writes it, and it deliberately writes NO
  --    row for the Governor, so that seat reaching this selection would fail here.
  SELECT count(*) INTO n FROM cc0493_sel
   WHERE term_start IS NULL OR term_start <> p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) have no swearing-in date, or one that is not %. CC_0491 '
                    'writes it. ⚠ If a date reads 2027-01-04 somebody has applied the FIRST '
                    'Monday — Oregon''s pre-1961 rule. If it reads 2027-01-19, somebody has '
                    'reached for the day the Assembly convenes, which is eight days late.',
      n, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n FROM cc0493_sel WHERE basis IS DISTINCT FROM 'statute'
                                            AND basis IS DISTINCT FROM 'published';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % office(s) carry a date whose basis is not statute or published. An '
                    'estimate may not seat anybody.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0493_sel s
   WHERE s.politician_id IS NULL
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians po WHERE po.id = s.politician_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % winner(s) have no politician row to seat. CC_0492 creates 13 and '
                    'links 2; if this fires, it has not run.', n;
  END IF;

  -- P6 — 🔴 NOT ONE OREGON SEAT IN THIS WAVE IS FLAGGED is_vacant, ASSERTED RATHER THAN ASSUMED.
  SELECT count(*) INTO n
    FROM cc0493_sel s JOIN essentials.offices o ON o.id = s.office_id WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % seat(s) in this wave are flagged is_vacant, expected 0. A future-'
                    'dated seating does not clear a flag, so this state would need a companion '
                    'file of the CC_0480 / CC_0486 kind and it has none. ⚠ Oregon DOES have two '
                    'flagged-vacant COUNTY offices, which are not in this wave.', n;
  END IF;

  -- P7 — 🔴 THE PRE-IMAGE IS ONE OPEN, UNDATED TERM PER SEAT. All four facts are asserted: an
  -- existing term_end would be destroyed unrecorded, an existing how_ended would SURVIVE the
  -- COALESCE, and a dated predecessor would mean Oregon had acquired a control CC_0491 asserts
  -- it does not have.
  SELECT count(*) INTO n FROM cc0493_pre;
  IF n <> p.expect_predecessors THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) captured, expected % (one per seat — every Oregon '
                    'legislative seat in this wave was held when this file was written).',
      n, p.expect_predecessors;
  END IF;

  SELECT count(*) INTO n FROM cc0493_pre WHERE term_end IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a term_end. seat_officeholder '
                    'overwrites it without a guard and records nothing, so this file would '
                    'destroy a date it has not written down.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0493_pre WHERE how_ended IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) already carry a how_ended. seat_officeholder '
                    'COALESCEs that column, so an existing value survives.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0493_pre WHERE term_start IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % predecessor term(s) now carry a term_start. When this file was '
                    'written all 75 were NULL — Oregon offers no control of its own for that '
                    'reason, and CC_0491''s assertion 3d records the absence. If starts have '
                    'appeared, check 2027-01-11 against them before applying.', n;
  END IF;

  SELECT count(*) INTO n
    FROM cc0493_sel s
   WHERE NOT EXISTS (SELECT 1 FROM cc0493_pre x WHERE x.office_id = s.office_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % seat(s) have no predecessor term. A seat with nobody in it is a fact '
                    'to read, not to seat over.', n;
  END IF;

  -- P8 — 🔴 THE ONE OFFICE THIS FILE MUST LEAVE ALONE IS THERE TO BE LEFT ALONE. If this count
  -- is not 1, the shape assertion 12 checks afterwards has changed and that assertion would pass
  -- vacuously.
  SELECT count(*) INTO n FROM cc0493_kept;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P8: % open term(s) held by a winner on an office OUTSIDE this wave, '
                    'expected exactly 1 (Tammy Carpenter, Director Zone 7, Beaverton School '
                    'District 48J). Read the extra one before seating.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0493_kept
   WHERE full_name <> 'Tammy Carpenter' OR seat <> 'Beaverton School District 48J';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: the kept outside term belongs to somebody other than Tammy Carpenter on '
                    'Beaverton School District 48J, which is the one this file was written '
                    'about.';
  END IF;

  -- P9 — 🔴🔴 THE CHAMBER SWITCH IS WHAT THIS FILE THINKS IT IS, BEFORE ANYTHING IS WRITTEN.
  -- Jeff Helfrich holds House District 52 and wins Senate District 26; House District 52 is in
  -- this same wave and is won by somebody else. If HD 52 were NOT in the wave, his House term
  -- would stay open after this file ran and he would hold two legislative seats at once — the
  -- Utah shape, where the missing piece was a RESULT.
  SELECT count(*) INTO n
    FROM cc0493_sel sd
    JOIN essentials.districts dsd ON dsd.label = sd.seat AND lower(dsd.state) = 'or'
    JOIN essentials.office_terms t ON t.politician_id = sd.politician_id AND t.term_end IS NULL
    JOIN essentials.offices o      ON o.id = t.office_id
    JOIN essentials.districts dhd  ON dhd.id = o.district_id
                                  AND dhd.district_type = 'STATE_LOWER'
                                  AND lower(dhd.state) = 'or'
    JOIN cc0493_sel hd             ON hd.office_id = o.id
   WHERE sd.district_type = 'STATE_UPPER'
     AND hd.politician_id <> sd.politician_id;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P9: % Senate winner(s) currently hold an Oregon House seat that is also in '
                    'this wave and won by somebody else, expected exactly 1 (Jeff Helfrich, '
                    'House District 52 -> Senate District 26, his House seat won by Hank '
                    'Sanders). If this is 0 the switch has changed shape; if it is more than 1, '
                    'somebody else is switching and the header does not describe them.', n;
  END IF;

  -- P10 — 🔴🔴 THE WASHINGTON PRE-IMAGE IS WHAT THIS FILE THINKS IT IS. 118 terms already begin
  -- on 2027-01-11 under an unrelated statute, and assertion 3's delta is measured against that
  -- number. A total of 193 would read as success.
  IF b.terms_on_the_day <> 118 THEN
    RAISE EXCEPTION 'P10: % term(s) already begin on 2027-01-11, expected 118 (Washington, '
                    'CC_0488). Oregon shares Washington''s calendar day under an unrelated rule, '
                    'so this file''s counts are deltas against that number.', b.terms_on_the_day;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = DATE '2027-01-11'
     AND NOT (lower(d.state) = 'wa' AND d.district_type IN ('STATE_LOWER','STATE_UPPER'));
  IF n <> 0 THEN
    RAISE EXCEPTION 'P10: % term(s) on 2027-01-11 are not Washington legislative terms. A date '
                    'shared by several states is a coincidence of calendars, never a shared '
                    'rule — name the new one before adding Oregon''s 75 to the pile.', n;
  END IF;

  -- P11 — ⚠ RULING B: seated from a `called` result, and this file says so in every term it
  -- writes. Oregon certifies on the 37th day (ORS 254.545(1)), which is 2026-12-10.
  SELECT count(*) INTO n
    FROM cc0493_sel s
    JOIN essentials.office_pending_winner w ON w.office_id = s.office_id
   WHERE w.certainty <> 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P11: % seat(s) are no longer "called". If Oregon has certified since '
                    '2026-11-23, the terms this file writes should say "certified" instead.', n;
  END IF;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK A — the incumbency guard, from migrations/_templates/office_terms_incumbency_guard.sql
-- ═════════════════════════════════════════════════════════════════════════════════════════════
--
-- @incumbency-decision: gated — this closes each predecessor at 2027-01-10, well after the
-- election, so every outgoing term still covers 2026-11-03 and the predicate's answer must not
-- move for anybody. The scope covers both sides: the 75 winners and the people whose terms are
-- closed.
--
-- ⚠ OREGON'S PREDECESSOR TERMS ARE ALL UNDATED, so the guard's `term_start IS NULL OR
--   term_start <= election_date` arm is satisfied by the NULL for every one of them, both before
--   and after. The closure moves `term_end` from NULL to 2027-01-10, which is still >= the
--   election date, so no answer moves. That is what this gate measures rather than assumes.
CREATE TEMP TABLE cc0493_guarded ON COMMIT DROP AS
SELECT politician_id FROM cc0493_sel WHERE politician_id IS NOT NULL
UNION
SELECT politician_id FROM cc0493_pre WHERE politician_id IS NOT NULL;

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
   AND rc.politician_id IN (SELECT politician_id FROM cc0493_guarded);

-- ── The write ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN SELECT * FROM cc0493_sel ORDER BY office_id::text LOOP
    PERFORM essentials.seat_officeholder(
      p_office_id        => r.office_id,
      p_politician_id    => r.politician_id,
      p_term_start       => r.term_start,
      p_source           => '2026-11-03 general election; winner recorded in race_candidates and '
                         || 'called, not certified, when this ran — Oregon canvasses on the 37th '
                         || 'day after the election, 2026-12-10 (ORS 254.545(1)). Term begins '
                         || to_char(r.term_start, 'YYYY-MM-DD')
                         || ' per essentials.office_swearing_in: "The term of each Senator and '
                         || 'Representative shall commence on the second Monday in January '
                         || 'following his election … unless a different commencing day for '
                         || 'such terms shall have been appointed by law" (Or. Const. Art. IV, '
                         || 'Sec. 4(1)). NOTE: the constitutional day is a DEFAULT that a '
                         || 'statute may displace, and none does — ORS 171.051(6) names the same '
                         || 'second Monday. The Legislative Assembly does not convene until '
                         || '2027-01-19, EIGHT days later (ORS 171.010(1)), so this date is a '
                         || 'term start and not a swearing-in. Oregon''s pre-1961 rule was the '
                         || 'FIRST Monday, 2027-01-04. ⚠ Washington''s 118 legislative terms '
                         || 'also begin on 2027-01-11, under RCW 44.04.021 — the same calendar '
                         || 'day under an unrelated rule. '
                         || CASE WHEN r.is_reelection THEN 'Re-elected incumbent. '
                                 ELSE 'New holder; predecessor closed at 2027-01-10. ' END
                         || 'CC_0493',
      p_how_started      => 'elected',
      p_start_precision  => 'day',
      p_how_ended_prev   => 'term_expired',
      p_allow_reelection => r.is_reelection);
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'CC_0493: seat_officeholder called for % offices', v_seated;
END $$;

-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- BLOCK B — the incumbency guard's comparison
-- ═════════════════════════════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0493_guarded;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
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
                  coalesce(p.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;

  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

-- ── Post-verify ─────────────────────────────────────────────────────────────────────────────
-- ⚠ ORDERED SO THE NARROW CHECKS RUN FIRST, so a control aimed at a given assertion reaches it
--   instead of tripping a repo-wide count two gates earlier.
DO $$
DECLARE n bigint; m text; b record; p record; v_hd date; v_sd date;
BEGIN
  SELECT * INTO b FROM cc0493_before;
  SELECT * INTO p FROM cc0493_pin;

  -- 1. 75 new terms, one per selected office, on the day itself, naming the winner.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0493_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.politician_id = s.politician_id;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '1: % seated terms on %, expected %.', n, p.expect_term_start,
      p.expect_offices;
  END IF;

  -- 2. office_next_term answers for all 75 — the view a voter's page reads for a dated handover.
  SELECT count(*) INTO n
    FROM essentials.office_next_term nx JOIN cc0493_sel s ON s.office_id = nx.office_id
   WHERE nx.politician_id = s.politician_id AND nx.term_start = p.expect_term_start;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '2: office_next_term answers for % of % seats.', n, p.expect_offices;
  END IF;

  -- 3. 🔴🔴 THE DELTA, NOT THE TOTAL. Washington's 118 terms were already on this day; exactly
  --    75 more were added and no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE term_start = p.expect_term_start;
  IF n <> b.terms_on_the_day + p.expect_offices THEN
    RAISE EXCEPTION '3: terms starting % went % -> %, a delta of %, expected %. Washington''s '
                    '118 were already there under RCW 44.04.021.',
      p.expect_term_start, b.terms_on_the_day, n, n - b.terms_on_the_day, p.expect_offices;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.term_start = p.expect_term_start
     AND NOT (lower(d.state) = 'wa' AND d.district_type IN ('STATE_LOWER','STATE_UPPER'))
     AND NOT (lower(d.state) = 'or' AND d.district_type IN ('STATE_LOWER','STATE_UPPER'));
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % term(s) on % belong to neither Washington''s nor Oregon''s '
                    'legislature.', n, p.expect_term_start;
  END IF;

  -- 4. 🔴 NOBODY WAS UNSEATED TODAY, ANYWHERE IN THE COUNTRY.
  SELECT md5(string_agg(och.office_id::text || ':' || COALESCE(och.politician_id::text, '-'),
                        '|' ORDER BY och.office_id::text))
    INTO m FROM essentials.office_current_holder och;
  IF m IS DISTINCT FROM b.holders_md5 THEN
    RAISE EXCEPTION '4: the current-holder map changed (% -> %). A future-dated term must not '
                    'move a seat today.', b.holders_md5, m;
  END IF;

  -- 5. 🔴 AND ALL 75 SEATS STILL ANSWER WITH TODAY'S HOLDER. ⚠ IS NOT DISTINCT FROM rather than
  --    `=` so a NULL on either side would be counted rather than silently dropped.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0493_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NOT DISTINCT FROM s.holder_before;
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '5: % of % seats still answer office_current_holder with the person holding '
                    'them today.', n, p.expect_offices;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_current_holder och JOIN cc0493_sel s ON s.office_id = och.office_id
   WHERE och.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the 75 seats answer office_current_holder with nobody, expected 0 '
                    '— every Oregon legislative seat in this wave is held today.', n;
  END IF;

  -- 6. Each predecessor named in the pre-image is closed the day before the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0493_pre x ON x.term_id = t.id
   WHERE t.term_end = p.expect_term_start - 1;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6: % predecessor term(s) closed at %, expected % — the exact rows named in '
                    'cc0493_pre.', n, p.expect_term_start - 1, b.predecessors;
  END IF;

  -- 6b. ⚠ AND ALL 75 CLOSURES ARE STILL UNDATED AT THE START. This file writes an end onto a row
  --     with no beginning, 75 times, and that is the state Oregon was in — recorded so the next
  --     reader does not take it for damage this file did.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0493_pre x ON x.term_id = t.id
   WHERE t.term_start IS NULL;
  IF n <> b.predecessors THEN
    RAISE EXCEPTION '6b: % of % closed predecessor term(s) still have a NULL term_start, '
                    'expected all of them. Oregon''s tenures are undated and this file does not '
                    'date them.', n, b.predecessors;
  END IF;

  -- 7. No term of these seats was closed between today and the handover.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0493_sel s ON s.office_id = t.office_id
   WHERE t.term_end IS NOT NULL
     AND t.term_end >= CURRENT_DATE AND t.term_end < p.expect_term_start - 1;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % term(s) closed between today and the day before the handover.', n;
  END IF;

  -- 8. This file creates no people and no offices.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians THEN
    RAISE EXCEPTION '8: politicians moved from % to %.', b.politicians, n;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices;
  IF n <> b.offices THEN
    RAISE EXCEPTION '8: offices moved from % to %.', b.offices, n;
  END IF;

  -- 9. 🔴 NOT ONE SEAT STARTS ON ANY OF THE THREE WRONG DAYS. 2027-01-04 is the first Monday,
  --    Oregon's own pre-1961 rule; 2027-01-18 is the MLK holiday; 2027-01-19 is when the
  --    Assembly actually convenes, eight days late.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0493_sel s ON s.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-04', DATE '2027-01-18', DATE '2027-01-19');
  IF n <> 0 THEN
    RAISE EXCEPTION '9: % seat(s) start on one of the three wrong days (2027-01-04 the first '
                    'Monday, 2027-01-18 the MLK holiday, 2027-01-19 the convening day).', n;
  END IF;

  -- 10. 🔴🔴 THE GOVERNOR WAS NOT SEATED. ORS 176.010 commences that term on the publication of
  --     the returns by the Speaker — and ORS 254.545(1) excepts "the office of Governor after
  --     the general election" from the Secretary of State's own canvass, so the state does not
  --     even count that race through this channel.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'or' AND d.district_type = 'STATE_EXEC'
     AND t.term_start = p.expect_term_start;
  IF n <> 0 THEN
    RAISE EXCEPTION '10: % Oregon state executive seat(s) were seated on the legislature''s '
                    'date. The Governor''s commencement is an EVENT and is refused.', n;
  END IF;

  -- 10b. 🟢 AND THE REFUSAL IS STILL VISIBLE. The Governor's seat remains in the pending-winner
  --      view, which is what a voter's page reads — a refusal that disappeared would be
  --      indistinguishable from the work being done.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'or' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '10b: % Oregon state executive seat(s) still answer office_pending_winner, '
                    'expected 1 — the Governor, still refused and still visibly pending.', n;
  END IF;

  -- 10c. ⚠ AND NO SEAT BELOW THE STATE TIER WAS SEATED ON THIS DAY. Oregon has 15 pending LOCAL,
  --      LOCAL_EXEC and COUNTY seats this cycle, dated by their own rules.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'or' AND t.term_start = p.expect_term_start
     AND d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN
    RAISE EXCEPTION '10c: % Oregon seat(s) outside the legislature were seated on this day.', n;
  END IF;

  -- 11. 🔴🔴 THE CHAMBER SWITCH RESOLVED, AND BOTH HALVES ARE MEASURED. Jeff Helfrich's House
  --     District 52 term is closed at 2027-01-10 — closed by Hank Sanders being seated there,
  --     not by anything aimed at Helfrich — and his Senate District 26 term begins 2027-01-11.
  --     ⚠ This is the Utah case with the missing piece supplied: Doug Fiefia's Utah House seat
  --     stayed open because its RESULT was missing, not because of any rule.
  SELECT t.term_end INTO v_hd
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c'
     AND lower(d.state) = 'or' AND d.label = 'State House District 52';
  SELECT t.term_start INTO v_sd
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c'
     AND lower(d.state) = 'or' AND d.label = 'State Senate District 26'
     AND t.term_start = p.expect_term_start;
  IF v_hd IS DISTINCT FROM p.expect_term_start - 1 OR v_sd IS DISTINCT FROM p.expect_term_start THEN
    RAISE EXCEPTION '11: Jeff Helfrich''s House District 52 term ends % (expected %) and his '
                    'Senate District 26 term begins % (expected %). The chamber switch did not '
                    'resolve: he would hold two Oregon legislative seats at once.',
                    v_hd, p.expect_term_start - 1, v_sd, p.expect_term_start;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c'
     AND lower(d.state) = 'or' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND (t.term_end IS NULL OR t.term_end >= p.expect_term_start);
  IF n <> 1 THEN
    RAISE EXCEPTION '11: Jeff Helfrich holds % Oregon legislative term(s) running on or after %, '
                    'expected exactly 1 (Senate District 26).', n, p.expect_term_start;
  END IF;

  -- 12. 🔴 THE ONE KEPT TERM IS STILL OPEN. Tammy Carpenter stays a Director of Beaverton School
  --     District 48J while taking House District 27, and she holds both from 2027-01-11. Closing
  --     it would claim a resignation this pass has not read.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0493_kept k ON k.term_id = t.id
   WHERE t.term_end IS NULL;
  IF n <> b.kept THEN
    RAISE EXCEPTION '12: % of % term(s) held by a winner on an office outside this wave are '
                    'still open. This file closes the predecessor on the seat it seats and '
                    'nothing else.', n, b.kept;
  END IF;

  -- 13. 🔴 NO OREGON LEGISLATIVE OFFICE IS FLAGGED is_vacant AND THE REPO-WIDE COUNT DID NOT
  --     MOVE. ⚠ Oregon's two flagged-vacant COUNTY offices are outside this wave and stay as
  --     they are; the repo-wide total is what proves this file did not touch them.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'or' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION '13: % Oregon legislative office(s) are flagged is_vacant, expected 0.', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_all THEN
    RAISE EXCEPTION '13: the repo-wide count of flagged-vacant offices moved % -> %.',
      b.vacant_all, n;
  END IF;

  -- 14. Repo-wide, exactly 75 office_terms rows were added.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms_all + p.expect_offices THEN
    RAISE EXCEPTION '14: office_terms went % -> %, a delta of %, expected %.',
      b.terms_all, n, n - b.terms_all, p.expect_offices;
  END IF;

  -- 15. Every new term cites this migration (Ruling B: recoverable by slot), and every one of
  --     them records that the result was CALLED rather than certified.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0493_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%CC_0493%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '15: % of % new terms cite CC_0493.', n, p.expect_offices;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0493_sel s ON s.office_id = t.office_id
   WHERE t.term_start = p.expect_term_start AND t.source LIKE '%called, not certified%';
  IF n <> p.expect_offices THEN
    RAISE EXCEPTION '15: % of % new terms record that the result was called rather than '
                    'certified. Ruling B requires the file to say which it seated from.',
      n, p.expect_offices;
  END IF;

  -- 16. 🔴 THE SEATS HAVE LEFT THE PENDING-WINNER VIEW.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0493_sel s ON s.office_id = w.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION '16: % seat(s) still answer office_pending_winner.', n;
  END IF;

  -- 17. 🔴 THE DRIFT BASELINE DID NOT MOVE, AND NEITHER DID THE WHOLE VIEW. Every one of the 75
  --     seats already had a term row, so this file takes nothing OUT of offices_missing_terms.
  --     Both halves are asserted. 🔴 NEVER RAISE THE BASELINE.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o2 ON o2.id = m.office_id WHERE NOT o2.is_vacant;
  IF n <> b.missing_unflagged THEN
    RAISE EXCEPTION '17: the unflagged offices_missing_terms count moved % -> %.',
      b.missing_unflagged, n;
  END IF;

  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_all THEN
    RAISE EXCEPTION '17: offices_missing_terms went % -> %, expected no change — all 75 seats '
                    'already carried a term row.', b.missing_all, n;
  END IF;

  RAISE NOTICE 'CC_0493 OK: 75 Oregon legislators scheduled for % (% re-elections, % handovers), '
               '% predecessors closed at % — every one of them an UNDATED tenure, which is the '
               'state Oregon is in. A DELTA of 75 against Washington''s 118 terms already on '
               'that calendar day under an unrelated statute. Nobody moved today, no seat '
               'flagged vacant, no seat on the first Monday (2027-01-04), the MLK holiday or '
               'the convening day (2027-01-19). The GOVERNOR was not seated and is still '
               'visibly pending — ORS 176.010 names an event, and ORS 254.545(1) excepts that '
               'office from the Secretary of State''s own canvass. Jeff Helfrich''s House '
               'District 52 term closed at % because Hank Sanders was seated there, so the '
               'chamber switch resolved itself; Tammy Carpenter keeps her Beaverton School '
               'District 48J seat and holds two from %. Drift baseline % held.',
    p.expect_term_start, p.expect_reelections, p.expect_new, b.predecessors,
    p.expect_term_start - 1, p.expect_term_start - 1, p.expect_term_start, b.missing_unflagged;
END $$;

COMMIT;
