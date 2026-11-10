-- CC_0362 — 2026-11-03 state boards: record Ballotpedia's called results for the Utah State
--           Board of Education and the California Board of Equalization.
--
-- 🔴 WHY THIS FILE EXISTS, AND IT IS A CORRECTION. CC_0360's header said 119 Ballotpedia
--   state-executive voteboxes "match no seat we hold". That number was produced by MY OWN
--   WHERE CLAUSE, not by the data: the reconciliation loaded our offices with
--   `district_type = 'STATE_EXEC'` and nothing else. Utah's 15 State Board of Education
--   districts are STATE_BOARD_EDUCATION and California's 4 Board of Equalization districts are
--   STATE_BOARD, so every one of them came back as "we hold no such seat" — a FALSE ABSENCE
--   reported as a finding about the world.
--   ▶ A PREDICATE READS THE SHAPE OF A VALUE, NEVER WHAT THE VALUE IS. Re-run against EVERY
--     office, the 119 becomes: 7 seats we hold and can record (this file), 90 with no seat at
--     all, 22 Ballotpedia has not called.
--   ⚠ These seats also have REAL GEOMETRY already — `ocd-division/country:us/state:ut/sboe:N`
--     and `06-sboe-d3` — which is exactly why they must not be rebuilt as new offices.
--
-- WHAT IT WRITES:
--   2 politicians · 3 races · 5 candidacies INSERTED · 6 existing candidacies UPDATED
--   7 winners in all, across 7 races.
--
--   Utah State Board of Education   (STATE_BOARD_EDUCATION, into "2026 Utah General")
--     District 1   🏆 Jennie Earl (R)        — incumbent, holds this seat   [race CREATED]
--                     Cathy Callow-Heusser (D)                              NEW person
--     District 2   🏆 Kacee Weaver (D)                                      NEW person, [race CREATED]
--                     Joseph Kerry (R) — HOLDS THIS SEAT and withdrew, still on the ballot
--     District 4   🏆 LeAnn Wood (R)         — incumbent, holds this seat   [race CREATED]
--     District 5   🏆 Sarah Reale (D)        — unopposed                    [race existed]
--     District 11  🏆 Tracy Nuttall (R)                                     [race existed]
--                     Lacey Peterson (D)
--     District 14  🏆 Linda Hanks (R)        — unopposed                    [race existed]
--   California Board of Equalization (STATE_BOARD, into "CA 2026 Statewide General")
--     District 3   🏆 Mike Gipson (D)                                       [race existed]
--                     Samuel P. Sukaton (D)   ⚠ two Democrats — California's top-two primary
--                     sends the two leading candidates to November regardless of party.
--
-- 🔴 THIS FILE OVERWRITES 6 ROWS AND EVERY PRIOR VALUE WAS **NULL**. There is no history table
--   and no replayable runner, so the previous values exist nowhere once it commits; they are
--   written down here, and the gate refuses to replace anything that is not NULL.
--   ⚠ result_source and result_recorded_at are replaced ALONGSIDE result, never left behind.
--
-- SOURCING — identical to CC_0360/CC_0361 and tested the same way. AP publishes no race for any
--   of these seats. Ballotpedia's winner flag agreed with AP's call on 71 of 71 races where both
--   name a winner, WHILE its vote counts ran up to 32% short of AP's, so the flag is used and
--   NO NUMBER IS. Each outcome is stated twice on the page — a CSS class on the row and an
--   editor's sentence — and both agree for all 7. result_certainty is 'called'.
--
-- 🔴 THREE CANDIDATES ARE ANCHORED ON THE SEAT ITSELF, not on a name match. Jennie Earl (D1),
--   Joseph Kerry (D2) and LeAnn Wood (D4) each appear in essentials.office_current_holder for
--   the exact office this file attaches them to. That is a fact this file does not supply, so
--   it can disagree with it — and the gate below checks it in both directions.
--   ⚠ Joseph Kerry HOLDS District 2 AND LOST IT. Ballotpedia records "(Withdrew, still on
--     ballot)", so his row reads candidate_status 'withdrawn' with result 'lost': votes were
--     cast for him. "Never filed" would mean deleting a row; this is the opposite.
--
-- Applied to production 2026-11-06 by Chris Cantrell. Slot reserved via steward.

BEGIN;

-- ─── 1. The two people we hold no row for ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people (full_name, first_name, last_name, source) VALUES
  ('Cathy Callow-Heusser', 'Cathy', 'Callow-Heusser',
   'https://ballotpedia.org/Cathy_Callow-Heusser (Ballotpedia, read 2026-11-06); outcome from the Utah state executive elections page''s winner flag (CC_0362)'),
  ('Kacee Weaver',         'Kacee', 'Weaver',
   'https://ballotpedia.org/Kacee_Weaver (Ballotpedia, read 2026-11-06); outcome from the Utah state executive elections page''s winner flag (CC_0362)');

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT lower(translate(coalesce(t, ''), 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
                                          'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc'))
$f$;

DO $$
DECLARE txt text; n int;
BEGIN
  -- a positive control before any "nothing found" is believed
  SELECT count(*) INTO n FROM essentials.politicians WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Jennie Earl');
  IF n < 1 THEN RAISE EXCEPTION 'the name comparison cannot see a politician known to exist — the guard below would pass vacuously'; END IF;

  -- 🔴 both collision keys, across the whole table, ARCHIVED ROWS INCLUDED
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ', active=' || p.is_active || ')' AS msg
      FROM seed_people s JOIN essentials.politicians p
        ON pg_temp.namekey(p.full_name) = pg_temp.namekey(s.full_name)
    UNION
    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'
      FROM seed_people s JOIN essentials.politicians p
        ON pg_temp.namekey(p.first_name) = pg_temp.namekey(s.first_name)
       AND pg_temp.namekey(p.last_name)  = pg_temp.namekey(s.last_name)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;

  -- 🔴 the split must reconstruct the name EXACTLY. A control on CC_0360 proved the weaker
  --    "ends with the surname" form useless on a hyphenated name, and one of these two is
  --    hyphenated: "Cathy Callow-Heusser" ends with "Heusser" too.
  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s WHERE s.full_name <> s.first_name || ' ' || s.last_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;

  -- a source must be that person's own Ballotpedia article, never a fragment into someone else's
  SELECT string_agg(s.full_name || ' -> ' || s.source, '; ') INTO txt FROM seed_people s
   WHERE s.source NOT LIKE 'https://ballotpedia.org/%' OR s.source LIKE '%#%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is not a plain Ballotpedia page: %', txt; END IF;
END $$;

INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, s.source, true, false
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source);

CREATE TEMP TABLE seeded (full_name text PRIMARY KEY, politician_id uuid NOT NULL) ON COMMIT DROP;
INSERT INTO seeded (full_name, politician_id)
SELECT s.full_name, p.id FROM seed_people s
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM seeded;
  IF n <> 2 THEN RAISE EXCEPTION 'only % of the 2 seeded people resolved to exactly one row', n; END IF;
END $$;

-- ─── 2. The three Utah races that do not exist yet ───
CREATE TEMP TABLE new_races (
  seat text PRIMARY KEY, office_id uuid NOT NULL, election_id uuid NOT NULL, position_name text NOT NULL
) ON COMMIT DROP;
INSERT INTO new_races (seat, office_id, election_id, position_name) VALUES
  ('UT State Board of Education District 1', '6ca19238-7db3-4e28-afba-02ab742b8068'::uuid, '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea'::uuid, 'State Board of Education District 1'),
  ('UT State Board of Education District 2', 'c6461ab6-c71f-482d-9417-233bfda6230c'::uuid, '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea'::uuid, 'State Board of Education District 2'),
  ('UT State Board of Education District 4', '7b43ff9f-fd6b-4698-83b0-e6202e7571c1'::uuid, '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea'::uuid, 'State Board of Education District 4');

DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM new_races nr JOIN essentials.offices o ON o.id = nr.office_id;
  IF n <> 3 THEN RAISE EXCEPTION 'only % of the 3 target offices exist', n; END IF;

  -- each must be a Utah state-board-of-education seat, and its geometry must be real: an empty
  -- geo_id is a lookup key nothing can ever match, so the office would answer no address at all
  SELECT string_agg(nr.position_name || ' -> ' || upper(d.state) || ' ' || d.district_type || ' geo=' || coalesce(d.geo_id, '(null)'), '; ') INTO txt
    FROM new_races nr JOIN essentials.offices o ON o.id = nr.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE upper(d.state) <> 'UT' OR d.district_type <> 'STATE_BOARD_EDUCATION' OR coalesce(d.geo_id, '') = '';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an office is not a Utah state-board seat with real geometry: %', txt; END IF;

  SELECT count(*) INTO n FROM new_races nr
    JOIN essentials.races r ON r.office_id = nr.office_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = DATE '2026-11-03';
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) already exist on these offices for 2026-11-03', n; END IF;

  PERFORM 1 FROM essentials.elections
   WHERE id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea'::uuid AND election_date = DATE '2026-11-03' AND state = 'UT';
  IF NOT FOUND THEN RAISE EXCEPTION 'the 2026 Utah General election row is not where this file expects it'; END IF;
END $$;

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT nr.election_id, nr.office_id, nr.position_name, NULL, 1
  FROM new_races nr
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races r
                     JOIN essentials.elections e ON e.id = r.election_id
                    WHERE r.office_id = nr.office_id AND e.election_date = DATE '2026-11-03');

-- ─── 3. The five new candidacies ───
CREATE TEMP TABLE adds (
  seat text NOT NULL, office_id uuid NOT NULL, who text NOT NULL, result text NOT NULL,
  status text NOT NULL, pinned_id uuid, PRIMARY KEY (office_id, who)
) ON COMMIT DROP;
INSERT INTO adds (seat, office_id, who, result, status, pinned_id) VALUES
  ('UT State Board of Education District 1', '6ca19238-7db3-4e28-afba-02ab742b8068'::uuid,
   'Jennie Earl',          'won',  'active',    '21931d93-28de-407f-adc9-ac3844a9e865'::uuid),
  ('UT State Board of Education District 1', '6ca19238-7db3-4e28-afba-02ab742b8068'::uuid,
   'Cathy Callow-Heusser', 'lost', 'active',    NULL),
  ('UT State Board of Education District 2', 'c6461ab6-c71f-482d-9417-233bfda6230c'::uuid,
   'Kacee Weaver',         'won',  'active',    NULL),
  ('UT State Board of Education District 2', 'c6461ab6-c71f-482d-9417-233bfda6230c'::uuid,
   'Joseph Kerry',         'lost', 'withdrawn', '7689e548-bbea-4900-be45-4ce8df3e5790'::uuid),
  ('UT State Board of Education District 4', '7b43ff9f-fd6b-4698-83b0-e6202e7571c1'::uuid,
   'LeAnn Wood',           'won',  'active',    '7f68edeb-7087-4e14-a02f-7c5ebcb20f7f'::uuid);

CREATE TEMP TABLE pins ON COMMIT DROP AS
SELECT a.*, coalesce(a.pinned_id, s.politician_id) AS pid
  FROM adds a LEFT JOIN seeded s ON s.full_name = a.who;

DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM pins WHERE pid IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) resolve to no person', n; END IF;

  -- 🔴 a pinned uuid must be the person this file names. The INSERT takes the name FROM THAT
  --    ROW, so a swapped id would be written under the wrong person with every other gate green.
  SELECT string_agg(a.seat || ': this file names ' || a.who || ' but the pinned row is ' || p.full_name, '; ') INTO txt
    FROM adds a JOIN essentials.politicians p ON p.id = a.pinned_id
   WHERE a.pinned_id IS NOT NULL AND pg_temp.namekey(p.full_name) <> pg_temp.namekey(a.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned politician is not the person this file names: %', txt; END IF;

  -- 🔴 AND THE THREE SITTING MEMBERS ARE CHECKED AGAINST THE SEAT THEY ACTUALLY HOLD, BOTH WAYS.
  --    office_current_holder is a fact this file does not supply, so it can contradict it.
  SELECT string_agg(msg, '; ') INTO txt FROM (
    SELECT a.seat || ': this file pins ' || a.who || ' to a seat held by ' || coalesce(h.full_name, '(nobody)') AS msg
      FROM adds a
      LEFT JOIN essentials.office_current_holder och ON och.office_id = a.office_id
      LEFT JOIN essentials.politicians h ON h.id = och.politician_id
     WHERE a.pinned_id IS NOT NULL AND och.politician_id IS DISTINCT FROM a.pinned_id
    UNION ALL
    SELECT a.seat || ': ' || h.full_name || ' holds this seat but this file seeds ' || a.who || ' as a new person'
      FROM adds a
      JOIN essentials.office_current_holder och ON och.office_id = a.office_id
      JOIN essentials.politicians h ON h.id = och.politician_id
     WHERE a.pinned_id IS NULL AND pg_temp.namekey(h.full_name) = pg_temp.namekey(a.who)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned candidate disagrees with the current officeholder: %', txt; END IF;

  SELECT count(*) INTO n FROM (
    SELECT office_id FROM adds GROUP BY office_id HAVING count(*) FILTER (WHERE result = 'won') <> 1) z;
  IF n <> 0 THEN RAISE EXCEPTION '% new race(s) do not hold exactly one winner', n; END IF;
END $$;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name,
       (och.politician_id IS NOT NULL), a.status, false,
       'Ballotpedia, "Utah state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0362',
       a.result, 'called',
       'Ballotpedia, "Utah state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0362',
       now()
  FROM pins a
  JOIN essentials.races r ON r.office_id = a.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.politicians p ON p.id = a.pid
  LEFT JOIN essentials.office_current_holder och ON och.office_id = a.office_id AND och.politician_id = a.pid
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

-- ─── 4. The six existing candidacies, which hold no result ───
CREATE TEMP TABLE calls (
  rc_id uuid PRIMARY KEY, seat text NOT NULL, who text NOT NULL, result text NOT NULL, src text NOT NULL
) ON COMMIT DROP;
INSERT INTO calls (rc_id, seat, who, result, src) VALUES
  ('41e22561-3dbc-4d52-bdcc-a95bb5da6b8d'::uuid, 'CA Board of Equalization District 3',     'Mike Gipson',       'won',  'California'),
  ('0dea0892-f66a-4f14-958e-fe698afe8f89'::uuid, 'CA Board of Equalization District 3',     'Samuel P. Sukaton', 'lost', 'California'),
  ('9194fa28-6dc5-4f1b-83f5-d55e533569ce'::uuid, 'UT State Board of Education District 11', 'Tracy Nuttall',     'won',  'Utah'),
  ('86a47e3b-261f-4941-b12a-aaa3f72f5dd2'::uuid, 'UT State Board of Education District 11', 'Lacey Peterson',    'lost', 'Utah'),
  ('d44ba719-a3b9-48c8-a25b-9dfdfc2edb50'::uuid, 'UT State Board of Education District 14', 'Linda Hanks',       'won',  'Utah'),
  ('e3216474-d5a3-42ad-9800-b5b96de7433b'::uuid, 'UT State Board of Education District 5',  'Sarah Reale',       'won',  'Utah');

-- every candidacy in the races this file touches, as it stands BEFORE the write
CREATE TEMP TABLE before_rows ON COMMIT DROP AS
SELECT rc.id, rc.result, rc.result_certainty, rc.result_source, rc.candidate_status
  FROM essentials.race_candidates rc
 WHERE rc.race_id IN (SELECT race_id FROM essentials.race_candidates WHERE id IN (SELECT rc_id FROM calls));

DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM calls;
  IF n <> 6 THEN RAISE EXCEPTION 'expected 6 pinned rows, found %', n; END IF;

  -- the pin is a uuid, so the row must still carry the NAME this file read against it
  SELECT string_agg(c.seat || ': pinned as ' || c.who || ' but the row reads ' || rc.full_name, '; ') INTO txt
    FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE pg_temp.namekey(rc.full_name) <> pg_temp.namekey(c.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned candidacy no longer names the person this file read: %', txt; END IF;

  -- 🔴 THE OVERWRITE GATE: every one of these was NULL and nothing else may be replaced
  SELECT string_agg(c.seat || ' ' || c.who || ' = ' || rc.result, '; ') INTO txt
    FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS NOT NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned row already holds a result, which this file did not record: %', txt; END IF;

  SELECT count(*) INTO n FROM (
    SELECT rc.race_id FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
     GROUP BY rc.race_id HAVING count(*) FILTER (WHERE c.result = 'won') <> 1) z;
  IF n <> 0 THEN RAISE EXCEPTION '% existing race(s) do not get exactly one winner', n; END IF;
END $$;

UPDATE essentials.race_candidates rc
   SET result             = c.result,
       result_certainty   = 'called',
       result_source      = 'Ballotpedia, "' || c.src || ' state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0362',
       result_recorded_at = now()
  FROM calls c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ─── Post-verify ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM new_races nr
    JOIN essentials.races r ON r.office_id = nr.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03';
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 new races, found %', n; END IF;

  SELECT count(*) INTO n
    FROM pins a
    JOIN essentials.races r ON r.office_id = a.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = a.pid
   WHERE rc.result = a.result AND rc.result_certainty = 'called'
     AND rc.candidate_status = a.status
     AND rc.result_source LIKE '%CC_0362%' AND rc.result_recorded_at >= TIMESTAMPTZ '2026-11-05';
  IF n <> 5 THEN RAISE EXCEPTION 'only % of the 5 new candidacies hold their stated result', n; END IF;

  SELECT count(*) INTO n FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result = c.result AND rc.result_certainty = 'called'
     AND rc.result_source LIKE '%CC_0362%' AND rc.result_recorded_at >= TIMESTAMPTZ '2026-11-05';
  IF n <> 6 THEN RAISE EXCEPTION 'only % of the 6 pinned rows hold their stated result', n; END IF;

  -- 🔴 nothing outside the pins moved. This is what catches an UPDATE whose WHERE is too wide.
  --    ⚠ IN THIS FILE THIS GATE IS VACUOUS AND THAT IS SAID OUT LOUD: before_rows holds every
  --      candidacy in the four races being updated and ALL SIX ARE PINNED, so there is no
  --      unpinned row for it to protect and no tamper can make it fire. It is kept because it
  --      costs nothing and goes live the moment a seventh candidacy appears in one of those
  --      races — but it is not evidence here. The identical gate was proved to fire by
  --      CC_0361's control G, on races that did carry untouched rows.
  SELECT string_agg(b.id::text || ': ' || coalesce(b.result, 'NULL') || ' -> ' || coalesce(rc.result, 'NULL'), '; ') INTO txt
    FROM before_rows b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE b.id NOT IN (SELECT rc_id FROM calls)
     AND (rc.result IS DISTINCT FROM b.result OR rc.result_certainty IS DISTINCT FROM b.result_certainty
       OR rc.result_source IS DISTINCT FROM b.result_source OR rc.candidate_status IS DISTINCT FROM b.candidate_status);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a row this file does not pin was changed: %', txt; END IF;

  -- all 7 races now hold exactly one winner and nobody undecided
  SELECT count(*) INTO n FROM (
    SELECT r.id FROM essentials.races r
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE r.office_id IN (SELECT office_id FROM new_races)
        OR r.id IN (SELECT rc2.race_id FROM essentials.race_candidates rc2 WHERE rc2.id IN (SELECT rc_id FROM calls))
     GROUP BY r.id
    HAVING count(*) FILTER (WHERE rc.result = 'won') <> 1 OR count(*) FILTER (WHERE rc.result IS NULL) <> 0) z;
  IF n <> 0 THEN RAISE EXCEPTION '% of the 7 races lack exactly one winner or hold an undecided row', n; END IF;

  -- the two seeded people exist exactly once, active, not incumbent
  SELECT count(*) INTO n FROM seeded sd JOIN essentials.politicians p ON p.id = sd.politician_id
   WHERE p.is_active AND NOT p.is_incumbent;
  IF n <> 2 THEN RAISE EXCEPTION 'only % of the 2 seeded people read active and non-incumbent', n; END IF;

  -- ⚠ this file creates NO office, so the occupancy drift metric must not move. Measured at
  --    293 / 55 / 238 before it ran; only the unflagged number is a baseline.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — this file creates no office and must not touch it', n; END IF;

  RAISE NOTICE 'CC_0362 OK — 3 races created, 5 candidacies inserted, 6 updated, 7 winners, 2 people seeded.';
END $$;

COMMIT;
