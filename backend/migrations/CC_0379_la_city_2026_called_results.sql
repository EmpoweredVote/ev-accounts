-- CC_0379 — 2026-11-03 City of Los Angeles: record the City Attorney, the one contest of the
--           four that is decisive against the county's outstanding-ballot estimate.
--
-- WHY THIS FILE EXISTS. Four Los Angeles city seats hand over on **2026-12-14** — Charter
--   § 205(c), the second Monday in December. It is the third and last dated piece of the
--   December local wave, after CC_0377 (19 special districts, 2026-12-04) and CC_0378 (197
--   school boards, 2026-12-11). Method, sources and the arithmetic are in
--   backend/data/ca-special-districts-2026-results/NOTES.md — read that first.
--
-- WHAT IT WRITES: 2 existing candidacies UPDATED in 1 race — 1 won, 1 lost, `called`.
--   Both prior values are NULL in all four result columns, and the gate refuses anything else.
--
--   City Attorney   🏆 Marissa Roy 673,463      John McKinney 313,281
--                      margin 360,182 against a bound of 131,000
--
-- 🔴 THREE OF THE FOUR ARE HELD, AND ONE OF THEM IS THE MAYORALTY. This is the rule working,
--   not a gap:
--     Mayor               Nithya Raman 579,501 · Karen Ruth Bass 484,580 (incumbent)
--                         margin  94,921 against a bound of 131,000  — NOT DECISIVE
--     Council District 3  Barri Worth Girvan 34,442 · Timothy K. Gaspar 32,573
--                         margin   1,869 against a bound of  10,080  — NOT DECISIVE
--     Council District 9  Jose Ugarte 18,487 · Estuardo Mazariegos 18,070
--                         margin     417 against a bound of   5,094  — NOT DECISIVE
--   ⚠ A SITTING MAYOR IS 94,921 VOTES BEHIND AND THAT IS STILL NOT ARITHMETIC. 131,000 ballots
--     remain uncounted countywide. AP would call this; we have no caller, so this programme
--     records `called` only where the trailing candidate could not overtake even if EVERY
--     remaining ballot broke their way. Leaving it NULL for three more weeks is the cost of
--     that standard, and it is the right cost. LA certifies by 2026-12-01, ten working days
--     before these seats turn over.
--
-- 🔴 A SAFETY MULTIPLE CAN EXCEED THE WHOLE COUNTY'S OUTSTANDING PILE, AND THEN IT IS NOT A
--   BOUND. The mayoral contest is 37% of the county's ballots, so its proportional share of
--   the 131,000 is ~49,025 and three times that is 147,087 — more late ballots than exist
--   anywhere in Los Angeles County. The bound is capped at the countywide figure. It changes
--   no outcome here, but a cap that only bites in the largest contests is exactly the one
--   nobody notices is missing.
--
-- ⚠ ALL FOUR CITY CONTESTS SHARE ONE TITLE PREFIX — "LOS ANGELES CITY GENERAL MUNICIPAL
--   ELECTION" — so the title alone cannot say which council district a contest is, and our own
--   district labels are bare ("District 3", "District 9") with the city named nowhere in them.
--   The anchor is the candidate set; the seat number is checked against the county's ORDINAL
--   form ("9th District"), and the city's name is taken from the government row.
--
-- Slot reserved via steward. Applied to production 2026-11-__ by Chris Cantrell.

BEGIN;

-- ─── 1. What was measured ───
CREATE TEMP TABLE called (
  district     text NOT NULL,
  office_title text NOT NULL,
  race_id      uuid NOT NULL,
  rc_id        uuid PRIMARY KEY,
  ballot_name  text NOT NULL,
  votes        int  NOT NULL,
  rank         int  NOT NULL,
  outcome      text NOT NULL CHECK (outcome IN ('won', 'lost'))
) ON COMMIT DROP;

INSERT INTO called (district, office_title, race_id, rc_id, ballot_name, votes, rank, outcome) VALUES
  -- Los Angeles city — City Attorney, 1 seat; margin 360182 vs bound 131000
  ('Los Angeles city', 'City Attorney', '7caf9b67-6529-471c-9d8d-3ab29aa1908a'::uuid, 'f7299480-14a2-47f3-86e4-7cde655e442d'::uuid, 'MARISSA ROY', 673463, 1, 'won'),
  ('Los Angeles city', 'City Attorney', '7caf9b67-6529-471c-9d8d-3ab29aa1908a'::uuid, 'cd54abd9-b430-487b-9e73-e4970c5daa58'::uuid, 'JOHN MCKINNEY', 313281, 2, 'lost');

CREATE TEMP TABLE bound (
  race_id         uuid PRIMARY KEY,
  ballots_cast    int NOT NULL,
  est_outstanding int NOT NULL,
  safety          int NOT NULL,
  county_total    int NOT NULL,   -- the cap: no contest can receive more than this
  bound           int NOT NULL
) ON COMMIT DROP;
INSERT INTO bound (race_id, ballots_cast, est_outstanding, safety, county_total, bound) VALUES
  ('7caf9b67-6529-471c-9d8d-3ab29aa1908a'::uuid, 1138078, 49025, 3, 131000, 131000);

-- ─── 2. Everything that must be true before a single row is written ───
CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT regexp_replace(
           upper(translate(coalesce(t, ''),
             'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
             'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc')),
           '[^A-Z0-9]', '', 'g')
$f$;

DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM called;
  IF n <> 2 THEN RAISE EXCEPTION 'expected 2 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM called;
  IF n <> 1 THEN RAISE EXCEPTION 'expected 1 race, the file carries %', n; END IF;

  PERFORM 1 FROM essentials.race_candidates WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Marissa Roy');
  IF NOT FOUND THEN RAISE EXCEPTION 'the name comparison cannot see a candidacy known to exist — the name gate would pass vacuously'; END IF;

  -- the name written here is compared with the DATABASE ROW'S name (CC_0359 gate D)
  SELECT string_agg(c.ballot_name || ' (rc ' || c.rc_id || ') is ' ||
                    coalesce(rc.full_name, '(no such candidacy)') || ' in the database', '; ') INTO txt
    FROM called c LEFT JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.id IS NULL OR pg_temp.namekey(rc.full_name) <> pg_temp.namekey(c.ballot_name);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a measured name does not match the row it is written against: %', txt; END IF;

  SELECT string_agg(c.ballot_name || ' sits in race ' || rc.race_id || ', not ' || c.race_id, '; ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.race_id <> c.race_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy is attached to the wrong race: %', txt; END IF;

  -- 🔴 THE WAVE'S DEFINITION COMES FROM THE DATABASE: a 2026-11-03 contest handing over 2026-12-14
  SELECT string_agg(c.district || ' -> ' || coalesce(s.swearing_in_date::text, '(no row)'), '; ') INTO txt
    FROM (SELECT DISTINCT race_id, district FROM called) c
    JOIN essentials.races r ON r.id = c.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
   WHERE e.election_date <> DATE '2026-11-03' OR s.swearing_in_date IS DISTINCT FROM DATE '2026-12-14';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is not a 2026-11-03 contest handing over on 2026-12-14: %', txt; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || count(*) FILTER (WHERE c.outcome = 'won') || ' winners for ' || r.seats || ' seat(s)' AS msg
      FROM called c JOIN essentials.races r ON r.id = c.race_id
     GROUP BY c.race_id, c.district, r.seats
    HAVING count(*) FILTER (WHERE c.outcome = 'won') <> r.seats) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race records the wrong number of winners: %', txt; END IF;

  -- every candidacy in the race must be measured, or a winner could be hidden
  SELECT string_agg(rc.full_name, '; ') INTO txt
    FROM (SELECT DISTINCT race_id FROM called) c
    JOIN essentials.race_candidates rc ON rc.race_id = c.race_id
   WHERE NOT EXISTS (SELECT 1 FROM called x WHERE x.rc_id = rc.id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the race is only partly measured, missing: %', txt; END IF;

  SELECT string_agg(rc.full_name || ' already reads result=' || coalesce(rc.result, '(null)'), '; ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS NOT NULL OR rc.result_certainty IS NOT NULL
      OR rc.result_source IS NOT NULL OR rc.result_recorded_at IS NOT NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file only writes over NULL and found a value: %', txt; END IF;

  SELECT string_agg(w.district || ': ' || l.ballot_name || ' (' || l.votes || ') is recorded LOST above ' ||
                    w.ballot_name || ' (' || w.votes || ') recorded WON', '; ') INTO txt
    FROM called w JOIN called l ON l.race_id = w.race_id
   WHERE w.outcome = 'won' AND l.outcome = 'lost' AND l.votes >= w.votes;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loser out-polls a winner: %', txt; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT z2.district || ': margin ' || z2.margin || ' does not clear its bound of ' || z2.bound AS msg
      FROM (SELECT c.district, min(c.votes) FILTER (WHERE c.outcome = 'won')
                     - max(c.votes) FILTER (WHERE c.outcome = 'lost') AS margin, b.bound
              FROM called c JOIN bound b ON b.race_id = c.race_id
             GROUP BY c.district, b.bound) z2
     WHERE z2.margin IS NULL OR z2.margin <= z2.bound) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a recorded contest is not decisive against its own bound: %', txt; END IF;

  -- 🔴 AND THE BOUND MUST BE THE CAPPED SAFETY MULTIPLE, derived rather than typed
  SELECT string_agg(b.race_id || ': bound ' || b.bound || ' <> least(' || b.est_outstanding || ' x ' ||
                    b.safety || ', ' || b.county_total || ')', '; ') INTO txt
    FROM bound b
   WHERE b.bound <> least(b.est_outstanding * b.safety, b.county_total) OR b.safety < 3;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a bound does not follow from its own inputs: %', txt; END IF;

  -- 🔴 AN INDEPENDENT FACT, BOTH DIRECTIONS — the view, not the file's own table
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || rc.full_name || ' is flagged incumbent but the seat is held by ' ||
           coalesce(p.full_name, '(nobody)') AS msg
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND rc.is_incumbent AND och.politician_id IS DISTINCT FROM rc.politician_id
    UNION
    SELECT c.district || ': the seat is held by ' || p.full_name || ', who is on this ballot and is NOT flagged incumbent'
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND och.politician_id = rc.politician_id AND NOT rc.is_incumbent) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the incumbent flag disagrees with who holds the seat: %', txt; END IF;

  RAISE NOTICE 'CC_0379 pre-checks passed: 2 candidacies, 1 race, both NULL, decisive against a capped bound';
END $$;

-- ─── 3. The write ───
UPDATE essentials.race_candidates rc
   SET result = c.outcome,
       result_certainty = 'called',
       result_source = 'Los Angeles County RR/CC official results for the 2026-11-03 General Election '
         || '(results.lavote.gov, election 4348; ElectionResults/GetElectionData joined to '
         || 'ElectionResults/GetCounterData and re-read against results.lavote.gov/text-results/4348), '
         || 'count of 2026-11-07 16:38 PT, retrieved 2026-11-08: ' || c.ballot_name || ' '
         || c.votes || ' votes, rank ' || c.rank || '. The county publishes no winner flag; '
         || 'recorded as called by CC_0379 because the margin exceeds every ballot the RR/CC '
         || 'reports still outstanding countywide (131,000).',
       result_recorded_at = now()
  FROM called c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result_source LIKE '%CC_0379%';
  IF n <> 2 THEN RAISE EXCEPTION 'this file wrote % of its 2 rows', n; END IF;

  SELECT count(*) FILTER (WHERE rc.result = 'won'), count(*) FILTER (WHERE rc.result = 'lost')
    INTO n, total FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id;
  IF n <> 1 OR total <> 1 THEN RAISE EXCEPTION 'expected 1 won and 1 lost, wrote % and %', n, total; END IF;

  -- 🔴 THE OTHER THREE RACES MUST BE UNTOUCHED — the mayoralty above all, which is the one a
  --   hurried pass would be most tempted to call.
  SELECT string_agg(d.label || ' / ' || o.title || ': ' || rc.full_name || ' = ' || rc.result, '; ') INTO txt
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-14'
     AND r.id NOT IN (SELECT race_id FROM bound)
     AND (rc.result IS NOT NULL OR rc.result_certainty IS NOT NULL OR rc.result_source IS NOT NULL);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race this file holds back has acquired a result: %', txt; END IF;

  SELECT count(DISTINCT r.id) FILTER (WHERE rc.result = 'won'), count(*) FILTER (WHERE rc.result IS NULL)
    INTO n, total
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-14';
  IF n <> 1 THEN RAISE EXCEPTION 'the 2026-12-14 wave shows % races with a winner, expected 1', n; END IF;
  IF total <> 6 THEN RAISE EXCEPTION 'the wave shows % candidacies still unrecorded, expected 6', total; END IF;

  -- 🔴 NOBODY IS SEATED. These winners take office on 2026-12-14, not a day earlier.
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF unflagged <> 238 THEN
    RAISE EXCEPTION 'the unflagged offices_missing_terms baseline reads %, not 238 (total %, flagged %)', unflagged, total, flagged;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms ot
    JOIN essentials.races r ON r.office_id = ot.office_id
   WHERE r.id IN (SELECT race_id FROM bound) AND ot.term_start >= DATE '2026-11-04';
  IF n <> 0 THEN RAISE EXCEPTION '% term row(s) start after the election on an office this file touched', n; END IF;

  RAISE NOTICE 'CC_0379 post-verify passed: 1 of the 4 Los Angeles city races decided, 6 candidacies still open (the mayoralty among them), baseline unflagged 238 (total %, flagged %)', total, flagged;
END $$;

COMMIT;
