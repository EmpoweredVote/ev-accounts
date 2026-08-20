-- 1837_austin_2026_council_races.sql
-- Austin City Council, November 3 2026 general: 5 races, 22 filed candidates.
--
-- SOURCE — City of Austin City Clerk, "Filed 2026 Ballot Applications"
--   https://www.austintexas.gov/clerk/elections/Ballot-Applications-November-2026
-- retrieved 2026-08-19. This is the Clerk's own filing record, not a press list or
-- an aggregator: fully server-rendered HTML, one row per applicant, giving the name
-- as it will appear on the ballot and the date filed.
--
-- WHICH SEATS ARE UP is taken from the Clerk's November 2026 Election page, which
-- states it outright — Districts 1, 3, 5, 8 and 9 — rather than inferred from term
-- arithmetic. Austin runs its general municipal elections on the November uniform
-- date in even years; the other five districts and the Mayor were elected in 2024.
--
-- TIMING. The filing period opened 2026-07-20 and closed 2026-08-17, the 78th day
-- before election day. This migration is written 2026-08-19, two days after close,
-- so the slate is complete as filed. Withdrawals are still possible after this
-- retrieval, so `source` says so explicitly and no `provisional_until` is invented —
-- these are filing facts, not a projection off pre-certification returns (contrast
-- the Seattle D5 rows, which ARE provisional off a primary feed and carry a date).
--
-- NONPARTISAN. Austin municipal elections are nonpartisan, so races.primary_party is
-- NULL. Party never belongs on a candidate row in any case.
--
-- INCUMBENTS — three of the five seats have their sitting member on the ballot:
-- Velásquez (D3), Alter (D5) and Qadri (D9). Harper-Madison (D1) and Ellis (D8) are
-- term-limited and did not file; their absence from the Clerk's list is the evidence,
-- and no row is written for them.
--
-- politician_id is resolved through the OFFICE (office_current_holder), never by
-- matching a bare name against essentials.politicians — a bare-name match is exactly
-- how "Alison Alter" would be seated onto Ryan Alter's row. The name is then used only
-- as a GUARD: the link is written only if the seated holder's name normalizes equal to
-- the filed ballot name. Normalization is NFD + DELETE combining marks + strip
-- non-letters, so "José Velásquez" == "Jose Velasquez" and
-- 'Zohaib "Zo" Qadri' == 'Zohaib "Zo" Qadri'. Deleting the marks matters: replacing
-- them with a space would split "Velásquez" into "vela squez" and the guard would
-- silently fail to link.
--
-- The post-verify gate REFUSES a partial link: any row flagged is_incumbent that did
-- not resolve to a politician aborts the migration, so a name-guard miss cannot ship
-- as a quietly unlinked incumbent.
--
-- Idempotency: NOT EXISTS on both inserts; the UPDATE is guarded on IS NULL.

BEGIN;

-- ─── Races: one per seat up in 2026, under the existing TX 2026 general ───────

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid, o.id, d.label, NULL, 1
FROM essentials.districts d
JOIN essentials.offices o ON o.district_id = d.id
WHERE d.mtfcc = 'X0030'
  AND split_part(d.geo_id, '-', 5) IN ('1', '3', '5', '8', '9')
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r
    WHERE r.election_id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid
      AND r.office_id = o.id
  );

-- ─── Candidates: the filed slate, verbatim ballot names ──────────────────────

WITH slate(dist, ballot_name, date_filed, is_inc) AS (VALUES
  -- District 1 — open seat (Harper-Madison term-limited)
  ('1',  'Alexandria Anderson',      DATE '2026-08-05', false),
  ('1',  'Steven Brown',             DATE '2026-08-11', false),
  ('1',  'Amber K. Goodwin',         DATE '2026-08-12', false),
  ('1',  'Michael Nahas',            DATE '2026-08-17', false),
  ('1',  'Misael Ramos',             DATE '2026-08-14', false),
  ('1',  'Portia Riggins',           DATE '2026-08-10', false),
  -- District 3
  ('3',  'Gavin Fernandez Jr.',      DATE '2026-08-17', false),
  ('3',  'Eduardo "Lalito" Romero',  DATE '2026-08-17', false),
  ('3',  'Neha Shah',                DATE '2026-08-11', false),
  ('3',  'Brock Skinner',            DATE '2026-07-24', false),
  ('3',  'Jose Velasquez',           DATE '2026-08-10', true),
  -- District 5
  ('5',  'Farrah Abraham',           DATE '2026-07-27', false),
  ('5',  'Ryan Alter',               DATE '2026-07-24', true),
  ('5',  'Liz Brink',                DATE '2026-07-21', false),
  ('5',  'David Weinberg',           DATE '2026-08-13', false),
  -- District 8 — open seat (Ellis term-limited)
  ('8',  'Jeffery Bowen',            DATE '2026-07-20', false),
  ('8',  'Selena Xie',               DATE '2026-07-24', false),
  -- District 9
  ('9',  'Rich Heyman',              DATE '2026-08-04', false),
  ('9',  'Kai Huang',                DATE '2026-07-21', false),
  ('9',  'Katie Kam',                DATE '2026-08-14', false),
  ('9',  'Zohaib "Zo" Qadri',        DATE '2026-08-17', true),
  ('9',  'Dave Thadani',             DATE '2026-08-17', false)
),
race_of AS (
  SELECT r.id AS race_id, split_part(d.geo_id, '-', 5) AS dist
  FROM essentials.races r
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
  WHERE r.election_id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid
)
INSERT INTO essentials.race_candidates
  (race_id, full_name, is_incumbent, candidate_status, source, last_verified_at)
SELECT ro.race_id, s.ballot_name, s.is_inc, 'active',
       'City of Austin City Clerk, "Filed 2026 Ballot Applications" '
       '(austintexas.gov/clerk/elections/Ballot-Applications-November-2026), retrieved 2026-08-19. '
       'Name is the name as it will appear on the ballot; filed ' || to_char(s.date_filed, 'YYYY-MM-DD') || '. '
       'Filing period 2026-07-20 to 2026-08-17 (78th day before the 2026-11-03 election), so the slate is '
       'complete as filed. Seats up (Districts 1, 3, 5, 8, 9) confirmed on the Clerk''s November 2026 '
       'Election page. Withdrawals remain possible after retrieval; re-check before certification.',
       now()
FROM slate s
JOIN race_of ro ON ro.dist = s.dist
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = ro.race_id AND rc.full_name = s.ballot_name
);

-- ─── Link the three incumbents through the OFFICE, guarded by name ───────────

UPDATE essentials.race_candidates rc
SET politician_id = och.politician_id
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE rc.race_id = r.id
  AND rc.is_incumbent
  AND rc.politician_id IS NULL
  AND r.election_id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid
  AND btrim(regexp_replace(regexp_replace(normalize(lower(p.full_name), NFD), E'[̀-ͯ]', '', 'g'), '[^a-z]+', ' ', 'g'))
    = btrim(regexp_replace(regexp_replace(normalize(lower(rc.full_name), NFD), E'[̀-ͯ]', '', 'g'), '[^a-z]+', ' ', 'g'));

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_races      int;
  v_cands      int;
  v_incumbents int;
  v_unlinked   int;
  v_per_race   text;
BEGIN
  SELECT count(*) INTO v_races
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
   WHERE r.election_id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid;
  IF v_races <> 5 THEN
    RAISE EXCEPTION 'Expected 5 Austin council races for Nov 2026, found %', v_races;
  END IF;

  SELECT count(*) INTO v_cands
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
   WHERE r.election_id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid;
  IF v_cands <> 22 THEN
    RAISE EXCEPTION 'Expected 22 filed Austin council candidates, found %', v_cands;
  END IF;

  SELECT count(*) INTO v_incumbents
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
   WHERE r.election_id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid AND rc.is_incumbent;
  IF v_incumbents <> 3 THEN
    RAISE EXCEPTION 'Expected 3 incumbents on the 2026 ballot (D3, D5, D9), found %', v_incumbents;
  END IF;

  -- A name-guard miss must not ship as a silently unlinked incumbent.
  SELECT count(*) INTO v_unlinked
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
   WHERE r.election_id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid
     AND rc.is_incumbent AND rc.politician_id IS NULL;
  IF v_unlinked <> 0 THEN
    RAISE EXCEPTION '% incumbent candidate row(s) did not resolve to a seated politician', v_unlinked;
  END IF;

  -- Per-race counts, so a slate that loaded into the wrong race cannot pass on the total.
  SELECT string_agg(x.dist || ':' || x.n, ' ' ORDER BY x.dist::int) INTO v_per_race
    FROM (
      SELECT split_part(d.geo_id, '-', 5) AS dist, count(rc.id) AS n
        FROM essentials.races r
        JOIN essentials.offices o ON o.id = r.office_id
        JOIN essentials.districts d ON d.id = o.district_id AND d.mtfcc = 'X0030'
        LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
       WHERE r.election_id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid
       GROUP BY 1
    ) x;
  IF v_per_race <> '1:6 3:5 5:4 8:2 9:5' THEN
    RAISE EXCEPTION 'Per-district candidate counts wrong: got "%", expected "1:6 3:5 5:4 8:2 9:5"', v_per_race;
  END IF;

  RAISE NOTICE 'OK: 5 Austin council races, 22 candidates (1:6 3:5 5:4 8:2 9:5), 3 incumbents all linked.';
END $$;

COMMIT;
