-- CA_0286_monroe_school_boards_one_seat_per_member.sql
-- Monroe County, IN school boards: every sitting member holds exactly ONE current seat, on the
-- corporation-level (G5420) offices. The per-seat (X0002) duplicate offices are archived, then deleted.
-- Operator decision (Chris Andrews, 2026-09-24): Option A -- keep the corporation-level seats, move the whole
-- board onto them.
--
-- WHAT WAS WRONG. Both boards existed under two office schemes at once:
--   (a) per-seat districts, mtfcc X0002 -- MCCSC geo_ids '1800630-board-d1'..'-d7', RBB geo_ids
--       '1809480-twp-beanblossom' / '1809480-twp-richland'. 11 offices, 11 open terms (the ADR 0002 phase-2
--       backfill, term_start NULL / 'unknown'), no races.
--   (b) corporation-level districts, mtfcc G5420 -- MCCSC geo_id '1800630' (district 9bdc2b0f), RBB geo_id
--       '1809480' (Bean Blossom 76d0828f, Richland a2c00ac4, At-Large 5490c02e). CA_0127 created the 5 (b) seat
--       offices that carry all 5 of the 2026 races, with no holder; CA_0136 then COPIED 5 incumbents (Wyatt,
--       Pirani, Jester, Jacobs, Kerr) onto them, leaving those 5 people seated twice.
-- The double seat shows in the address lookup: a point inside MCCSC board District 1 joined Erin Wyatt twice,
-- once through '1800630' and once through '1800630-board-d1'. The API's DISTINCT ON (p.id) hid the second row,
-- but it chose between the two offices arbitrarily.
--
-- 🔴 CORRECTION TO CA_0136. Its header says scheme (a) is "STALE, non-address-reachable". That is FALSE.
-- Every (a) district has an X0002 geofence, and X0002 -> SCHOOL is an explicit branch of GEOFENCE_DISTRICT_JOIN
-- (src/lib/districtQueries.ts). Scheme (a) WAS reachable by address; that is why Wyatt came back twice.
-- CA_0136's premise ("give the reachable scheme a holder") was mistaken. Its 5 terms stay; they are now the
-- ONLY terms those 5 people hold.
--
-- ⚠ OPEN QUESTION -- AT-LARGE OR SUBDISTRICT. Sources disagree on how these boards are elected. CA_0127 says
-- both corporations elect AT-LARGE (every voter in the corporation votes for every seat; the district or
-- township sets only where a candidate must live), citing the Indiana SOS certified list via The Indiana
-- Citizen, B Square Bulletin and Indiana Public Media. Scheme (a) encoded the opposite: who-votes by
-- subdistrict. This file follows the 2026-09-24 ruling, which puts every seat on the whole-corporation
-- geofence. The visible effect: a resident anywhere in MCCSC now sees all 7 MCCSC members (before, they saw
-- their own subdistrict member plus the 3 members CA_0136 copied). If a later ruling says subdistrict
-- voting, the (a) districts and their geofences are still here to re-point the offices at (see DISTRICTS).
--
-- WHAT THIS FILE DOES.
--   1. Creates the 6 missing (b) offices, one per seat -- no two seats are merged into one office:
--        MCCSC Districts 2, 4, 5, 6 on district 9bdc2b0f, each with its per-district MCCSC chamber (CA_0127's
--        shape for Districts 1/3/7);
--        a second Bean Blossom Township seat (76d0828f) and a second Richland Township seat (a2c00ac4) --
--        each township elects 2 trustees, and office_terms' exclusion constraint allows one holder per office.
--      Each new office copies its (a) office's columns (title, chamber, partisan_type, normalized_position_name,
--      voting_powers, ...) except id, district_id and seats (1, as CA_0127; the RBB (a) rows said 2 per office,
--      which cannot be true of a one-holder office). Ids are pinned so a re-run inserts nothing.
--   2. Attaches the existing RBB township chambers to the two CA_0127 RBB offices (chamber_id was NULL).
--      CA_0127 said "no Richland/Bean Blossom chamber exists"; they do (b5b25524, 611475ec, both under the RBB
--      government e7a00f4b). Without a chamber, browse-by-government cannot show these seats, and deleting (a)
--      would remove the only RBB township seats it can show today.
--   3. Seats the 6 members that hold no (b) term yet (Hennessey, Williams Iruoje, Cooperman, Grimes, Durnil,
--      Demoss), copying term_start, term_end, start_precision, how_started and how_ended from their (a) term.
--      All 11 (a) terms have term_start NULL / start_precision 'unknown'. essentials.seat_officeholder() refuses
--      a NULL term_start by design ("requires a real term_start"), and inventing a date is forbidden, so this
--      is a direct INSERT of the same honest open-ended 'unknown' term the phase-2 backfill and CA_0136 wrote.
--      The 5 CA_0136 terms already carry the same NULL / 'unknown' values as their (a) twins (pre-flight checks
--      this), so nothing is lost when the twins go.
--   4. Re-points the 9 legacy politicians.office_id values that point at an (a) office (Wyatt, Hennessey,
--      Pirani, Williams Iruoje, Cooperman, Grimes, Jester, Durnil, Demoss) to that person's (b) office. The
--      column is a deprecated snapshot with no foreign key; left alone it would dangle. Jacobs' and Kerr's are
--      NULL and stay NULL -- new code must not read this column, so it is not widened.
--   5. Archives the 11 (a) offices and their 11 terms, row for row, into essentials._retired_ca0286_offices /
--      _retired_ca0286_office_terms (LIKE the live tables, as CA_0206), md5-compares the copies, then deletes
--      the offices; the terms cascade (office_terms.office_id ON DELETE CASCADE). races.office_id is NO ACTION
--      and no race points at an (a) office (pre-flight). Locks both archives (RLS on, no policy; anon and
--      authenticated revoked).
--
-- DISTRICTS -- KEPT, deliberately. The 9 (a) districts are left in place with no offices. Nothing references a
-- district except offices (no foreign key from races or terms), and a district with no office is dropped by the
-- offices join in both the address lookup and check-address-reachability.mjs, so they surface nobody and fire
-- no finding. They are kept because they hold the subdistrict / township geometry: CA_0127 notes the board
-- districts still define candidate residency, and the at-large question above is not closed.
-- NOT TOUCHED: the 5 races and their candidates; Brad Tucker's RBB At-Large seat (already on (b), 4a7a8ced);
-- the 7 unrelated G5420 '180063000001'..'07' "District N" rows (no offices; their numbering does not match the
-- board districts -- a point in board District 1 falls in '180063000006'); every politician row except the 9
-- office_id snapshots; politicians.is_incumbent (already true for all 12 members; gated).
--
-- SOURCE: the existing (a) office_terms (phase-2 backfill / rbbschools.net roster) and the CA_0127 / CA_0136
-- records; ruling 2026-09-24. No new dates or people are asserted.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: DRAFT -- dry-run on prod inside BEGIN ... ROLLBACK only, 2026-09-24. NOT APPLIED.
--
-- ROLLBACK (restore scheme (a); then remove the 6 new offices and 6 new terms by the ids pinned in _map, and
-- re-point the 9 office_id snapshots back from the archive):
--   INSERT INTO essentials.offices SELECT * FROM essentials._retired_ca0286_offices ON CONFLICT (id) DO NOTHING;
--   INSERT INTO essentials.office_terms SELECT * FROM essentials._retired_ca0286_office_terms ON CONFLICT (id) DO NOTHING;
-- IDEMPOTENT: a re-run finds the (a) offices gone, the archive full, the 6 offices and 6 terms present; it
-- changes nothing and every gate still passes.

-- OPEN QUESTION (review 2026-09-24): which RBB incumbent holds the seat up in 2026 is UNEVIDENCED.
--   No RBB incumbent is a 2026 candidate; CA_0136 assumed Jacobs (Bean Blossom) and Kerr (Richland) hold
--   the race seats (956b21a1 / ea3c3a2e), and this file keeps that. Verify before seating a winner with
--   seat_officeholder, or it may close the wrong member's term (see the Durnil trustee-seat check).
-- RE-RUN: idempotent across SEPARATE transactions (verified: two passes, same end state). Do not paste it
--   twice into one transaction: its ON COMMIT DROP temp tables only drop at commit.

BEGIN;

SET LOCAL statement_timeout = '5min';
SET LOCAL lock_timeout = '10s';

-- ─── The move, pinned: (a) office -> (b) office, per person ──────────────────────────────────────
CREATE TEMP TABLE _map (
  a_office uuid PRIMARY KEY, b_office uuid NOT NULL UNIQUE, politician_id uuid NOT NULL UNIQUE,
  b_district uuid NOT NULL, b_is_new boolean NOT NULL, who text NOT NULL
) ON COMMIT DROP;
INSERT INTO _map VALUES
  ('12606d55-5005-414b-ae99-f1ba2709e5f1','8a8393ca-57af-46ce-b13e-d3e936640b85','760e1b7d-022c-4c70-b605-07b6fea2384b','9bdc2b0f-6e27-4480-854b-be820d99013a',false,'Erin Wyatt / MCCSC District 1'),
  ('e37be1a4-63dd-4327-8d90-8d85c5afede0','c64405e2-814c-4ec0-8fc2-2285c5974b54','2bf43cdc-5580-4288-ad1e-2c2bd1d40511','9bdc2b0f-6e27-4480-854b-be820d99013a',true, 'April Hennessey / MCCSC District 2'),
  ('06a2050d-5b28-46dc-b187-5bdae3317ff9','a8fb059c-7060-47f2-9268-1e9071e437f6','556a7d23-3acb-4068-a7bc-cecf5194296c','9bdc2b0f-6e27-4480-854b-be820d99013a',false,'Ashley Pirani / MCCSC District 3'),
  ('1f08a920-8833-49d8-99fa-ef760134e11a','ad1ec584-a73c-4b02-bebc-eef60448d86a','a167974b-4419-4346-acfb-606842ed963d','9bdc2b0f-6e27-4480-854b-be820d99013a',true, 'Tiana Williams Iruoje / MCCSC District 4'),
  ('e14aff60-9486-4747-aef3-77810523934d','677b48eb-5b51-4d00-b2c2-6dbf94cf34b3','e0714c0f-5691-4f55-99b0-8ca5f72777ab','9bdc2b0f-6e27-4480-854b-be820d99013a',true, 'Erin Cooperman / MCCSC District 5'),
  ('a6ac7361-9464-49bb-81b4-69a4112fb38d','0e6e40f2-0aab-457f-b5b7-723fa24ad3ce','c062b964-c7bb-4258-8b3f-462f4d5527ae','9bdc2b0f-6e27-4480-854b-be820d99013a',true, 'Ross Grimes / MCCSC District 6'),
  ('8e266c9e-85bd-4aaa-a946-676ec92703f0','d3e11729-0df8-424a-a777-d4bf655a0e84','b3799cb0-d361-4405-b82e-59031c5ffe73','9bdc2b0f-6e27-4480-854b-be820d99013a',false,'Aja Jester / MCCSC District 7'),
  ('c8bca79d-4319-49a4-925a-7580c74d3800','956b21a1-f1ce-44dd-a207-643d19885599','234cb50f-b0fb-4902-b807-da06ac2faddf','76d0828f-b78f-417d-9c49-21b129ba05b9',false,'Angie Jacobs / RBB Bean Blossom Twp (2026 race seat)'),
  ('64065558-9cc0-4b09-b9d0-79f1770976e8','338b7bf6-08e4-4903-b005-095633c86bac','a5ad7a20-4874-4358-8bbc-d78587e17096','76d0828f-b78f-417d-9c49-21b129ba05b9',true, 'Jimmie D Durnil / RBB Bean Blossom Twp (second seat)'),
  ('c1f0faa5-0707-46ae-b13e-0f0e6c226cf8','ea3c3a2e-68fa-4032-b2aa-d01d79716cfb','55dc950c-cd52-4460-ae3f-630c1c4f771a','a2c00ac4-0e1b-4a91-b670-4d6b3ef09c6e',false,'Dana Kerr / RBB Richland Twp (2026 race seat)'),
  ('3b8a4427-f68f-41a0-8144-11379f58ac01','062af08b-78dd-4f1b-8a3b-2a2a25874721','006cec13-0c52-46b2-a509-703826a0f06b','a2c00ac4-0e1b-4a91-b670-4d6b3ef09c6e',true, 'Lawrence J Demoss / RBB Richland Twp (second seat)');

-- The whole of both boards after the move: the 11 above plus Brad Tucker, already on (b) RBB At-Large.
CREATE TEMP TABLE _board ON COMMIT DROP AS
SELECT politician_id, b_office FROM _map
UNION ALL SELECT '6093ca32-97c2-4398-abc9-fd0a803e431d'::uuid, '4a7a8ced-6c96-4c46-bbbf-37db7ed90b60'::uuid;

-- The 5 races, and the office each must still point to afterwards.
CREATE TEMP TABLE _races (race_id uuid PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
INSERT INTO _races VALUES
  ('d6e37e16-e66b-463c-a2c8-a0804933f813','8a8393ca-57af-46ce-b13e-d3e936640b85'),  -- MCCSC District 1
  ('41e0c3a8-ce3f-4ce1-9926-2af9e0bc37d8','a8fb059c-7060-47f2-9268-1e9071e437f6'),  -- MCCSC District 3
  ('79091c94-9255-430c-90cc-bd25bec558f2','d3e11729-0df8-424a-a777-d4bf655a0e84'),  -- MCCSC District 7
  ('4c7830e9-dcc7-4850-929b-f416db7750fe','956b21a1-f1ce-44dd-a207-643d19885599'),  -- RBB Bean Blossom Twp
  ('cde100c0-9767-4d6f-8eea-08db6978f612','ea3c3a2e-68fa-4032-b2aa-d01d79716cfb');  -- RBB Richland Twp

-- The (b) districts: whole MCCSC, and RBB's three whole-corporation rows.
CREATE TEMP TABLE _b_districts (id uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO _b_districts VALUES
  ('9bdc2b0f-6e27-4480-854b-be820d99013a'), ('76d0828f-b78f-417d-9c49-21b129ba05b9'),
  ('a2c00ac4-0e1b-4a91-b670-4d6b3ef09c6e'), ('5490c02e-2710-42fe-8821-e6e95498f217');

-- The (a) districts (kept; see DISTRICTS in the header).
CREATE TEMP TABLE _a_districts ON COMMIT DROP AS
SELECT id FROM essentials.districts
 WHERE geo_id IN ('1800630-board-d1','1800630-board-d2','1800630-board-d3','1800630-board-d4','1800630-board-d5',
                  '1800630-board-d6','1800630-board-d7','1809480-twp-beanblossom','1809480-twp-richland')
   AND mtfcc = 'X0002' AND district_type = 'SCHOOL';

CREATE TABLE IF NOT EXISTS essentials._retired_ca0286_offices (LIKE essentials.offices INCLUDING DEFAULTS);
CREATE TABLE IF NOT EXISTS essentials._retired_ca0286_office_terms (LIKE essentials.office_terms INCLUDING DEFAULTS);
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '_retired_ca0286_offices_pkey') THEN
    ALTER TABLE essentials._retired_ca0286_offices ADD CONSTRAINT _retired_ca0286_offices_pkey PRIMARY KEY (id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '_retired_ca0286_office_terms_pkey') THEN
    ALTER TABLE essentials._retired_ca0286_office_terms ADD CONSTRAINT _retired_ca0286_office_terms_pkey PRIMARY KEY (id);
  END IF;
END $$;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices) AS offices,
       (SELECT count(*) FROM essentials.office_terms) AS terms,
       (SELECT count(*) FROM essentials.offices_missing_terms WHERE NOT coalesce(is_vacant, false)) AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices o JOIN _map m ON m.a_office = o.id) AS a_live;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_a int; v_a_terms int; v_a_ok int; v_arch_o int; v_arch_t int; v_new int; v_old_b int;
        v_twins int; v_twins_same int; v_a_races int; v_races int; v_a_dist int; v_a_other int;
BEGIN
  SELECT count(*) INTO v_a_dist FROM _a_districts;
  IF v_a_dist <> 9 THEN RAISE EXCEPTION 'PRE: expected 9 (a) districts, found %', v_a_dist; END IF;

  SELECT count(*) INTO v_a FROM essentials.offices o JOIN _map m ON m.a_office = o.id;
  SELECT count(*) INTO v_arch_o FROM essentials._retired_ca0286_offices;
  SELECT count(*) INTO v_arch_t FROM essentials._retired_ca0286_office_terms;
  SELECT count(*) INTO v_new FROM essentials.offices o JOIN _map m ON m.b_office = o.id AND m.b_is_new;
  SELECT count(*) INTO v_old_b FROM essentials.offices o JOIN _map m ON m.b_office = o.id AND NOT m.b_is_new
   WHERE o.district_id = m.b_district;

  IF v_old_b <> 5 THEN RAISE EXCEPTION 'PRE: expected the 5 CA_0127 (b) offices on their districts, found %', v_old_b; END IF;

  -- no office other than the 11 mapped ones sits on an (a) district
  SELECT count(*) INTO v_a_other FROM essentials.offices o
   WHERE o.district_id IN (SELECT id FROM _a_districts) AND o.id NOT IN (SELECT a_office FROM _map);
  IF v_a_other <> 0 THEN RAISE EXCEPTION 'PRE: % unmapped office(s) on an (a) district', v_a_other; END IF;

  IF v_a = 11 AND v_arch_o = 0 AND v_arch_t = 0 AND v_new = 0 THEN
    -- first run: each (a) office has exactly one term -- open, held by the mapped person
    SELECT count(*) INTO v_a_terms FROM essentials.office_terms t JOIN _map m ON m.a_office = t.office_id;
    SELECT count(*) INTO v_a_ok FROM essentials.office_terms t JOIN _map m
        ON m.a_office = t.office_id AND m.politician_id = t.politician_id AND t.term_end IS NULL;
    IF v_a_terms <> 11 OR v_a_ok <> 11 THEN
      RAISE EXCEPTION 'PRE: (a) terms are not the reviewed 11 open terms: % terms, % match', v_a_terms, v_a_ok;
    END IF;

    -- the 5 CA_0136 twins exist on (b) with the same start values as the (a) term they duplicate
    SELECT count(*), count(*) FILTER (WHERE bt.term_start IS NOT DISTINCT FROM at.term_start
                                        AND bt.start_precision IS NOT DISTINCT FROM at.start_precision)
      INTO v_twins, v_twins_same
      FROM _map m
      JOIN essentials.office_terms at ON at.office_id = m.a_office
      JOIN essentials.office_terms bt ON bt.office_id = m.b_office AND bt.politician_id = m.politician_id AND bt.term_end IS NULL
     WHERE NOT m.b_is_new;
    IF v_twins <> 5 OR v_twins_same <> 5 THEN
      RAISE EXCEPTION 'PRE: expected 5 CA_0136 twin terms matching their (a) start values, got % (% matching)', v_twins, v_twins_same;
    END IF;

  ELSIF v_a = 0 AND v_arch_o = 11 AND v_arch_t = 11 AND v_new = 6 THEN
    NULL;  -- re-run: already applied
  ELSE
    RAISE EXCEPTION 'PRE: unexpected state: % (a) offices live, archive % offices / % terms, % new (b) offices present',
      v_a, v_arch_o, v_arch_t, v_new;
  END IF;

  SELECT count(*) INTO v_a_races FROM essentials.races r JOIN _map m ON m.a_office = r.office_id;
  IF v_a_races <> 0 THEN RAISE EXCEPTION 'PRE: % race(s) point at an (a) office', v_a_races; END IF;
  SELECT count(*) INTO v_races FROM essentials.races r JOIN _races x ON x.race_id = r.id AND x.office_id = r.office_id;
  IF v_races <> 5 THEN RAISE EXCEPTION 'PRE: expected the 5 races on their (b) offices, found %', v_races; END IF;
END $$;

-- ─── 1. The 6 missing (b) offices, one per seat ──────────────────────────────────────────────────
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
   normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
   faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT m.b_office, a.chamber_id, m.b_district, a.title, a.representing_state, a.representing_city, a.description, 1,
       a.normalized_position_name, a.partisan_type, a.salary, a.is_appointed_position, a.is_vacant, a.vacant_since,
       a.faces_retention_vote, a.role_canonical, a.voting_powers, a.representation_note
  FROM _map m JOIN essentials.offices a ON a.id = m.a_office
 WHERE m.b_is_new
ON CONFLICT (id) DO NOTHING;

-- ─── 2. RBB township chambers on the two CA_0127 RBB offices ─────────────────────────────────────
UPDATE essentials.offices SET chamber_id = 'b5b25524-a225-49fc-a48b-91acb0b53793'  -- RBB Bean Blossom Township
 WHERE id = '956b21a1-f1ce-44dd-a207-643d19885599' AND chamber_id IS NULL;
UPDATE essentials.offices SET chamber_id = '611475ec-873b-4b3c-9c78-9fe53ff018a6'  -- RBB Richland Township
 WHERE id = 'ea3c3a2e-68fa-4032-b2aa-d01d79716cfb' AND chamber_id IS NULL;

-- ─── 3. Seat the 6 members that hold no (b) term, carrying their (a) term over unchanged ─────────
-- Not essentials.seat_officeholder(): it refuses term_start NULL, and every one of these starts is unknown.
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, how_ended, source)
SELECT m.b_office, m.politician_id, at.term_start, at.term_end, at.start_precision, at.how_started, at.how_ended,
       'CA_0286: moved from retired per-seat office ' || m.a_office || ' (term ' || at.id || ') onto the '
       || 'corporation-level office, ruling 2026-09-24 (Option A). Original source: ' || coalesce(at.source, '(none)')
  FROM _map m
  JOIN essentials.office_terms at ON at.office_id = m.a_office AND at.politician_id = m.politician_id
 WHERE m.b_is_new
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                    WHERE t.office_id = m.b_office AND t.politician_id = m.politician_id AND t.term_end IS NULL);

-- ─── 4. Legacy politicians.office_id snapshots that point at an (a) office ───────────────────────
UPDATE essentials.politicians p SET office_id = m.b_office
  FROM _map m
 WHERE p.id = m.politician_id AND p.office_id = m.a_office;

-- ─── 5. Archive (a), prove the copy exact, delete (terms cascade) ────────────────────────────────
INSERT INTO essentials._retired_ca0286_offices
SELECT o.* FROM essentials.offices o JOIN _map m ON m.a_office = o.id
ON CONFLICT (id) DO NOTHING;

INSERT INTO essentials._retired_ca0286_office_terms
SELECT t.* FROM essentials.office_terms t JOIN _map m ON m.a_office = t.office_id
ON CONFLICT (id) DO NOTHING;

DO $$
DECLARE v_live text; v_arch text;
BEGIN
  IF EXISTS (SELECT 1 FROM essentials.offices o JOIN _map m ON m.a_office = o.id) THEN
    SELECT md5(string_agg(o::text, '|' ORDER BY o.id)) INTO v_live FROM essentials.offices o JOIN _map m ON m.a_office = o.id;
    SELECT md5(string_agg(a::text, '|' ORDER BY a.id)) INTO v_arch FROM essentials._retired_ca0286_offices a JOIN _map m ON m.a_office = a.id;
    IF v_live IS DISTINCT FROM v_arch THEN RAISE EXCEPTION 'ARCHIVE: office copies differ from the live rows (% vs %)', v_live, v_arch; END IF;
    SELECT md5(string_agg(t::text, '|' ORDER BY t.id)) INTO v_live FROM essentials.office_terms t JOIN _map m ON m.a_office = t.office_id;
    SELECT md5(string_agg(a::text, '|' ORDER BY a.id)) INTO v_arch FROM essentials._retired_ca0286_office_terms a JOIN _map m ON m.a_office = a.office_id;
    IF v_live IS DISTINCT FROM v_arch THEN RAISE EXCEPTION 'ARCHIVE: term copies differ from the live rows (% vs %)', v_live, v_arch; END IF;
  END IF;
END $$;

DELETE FROM essentials.offices o USING _map m WHERE o.id = m.a_office;

ALTER TABLE essentials._retired_ca0286_offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials._retired_ca0286_office_terms ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON essentials._retired_ca0286_offices, essentials._retired_ca0286_office_terms FROM anon, authenticated;
COMMENT ON TABLE essentials._retired_ca0286_offices IS
  'CA_0286 (2026-09-24): archive of the 11 per-seat (X0002) Monroe County IN school-board offices (MCCSC board-d1..d7, RBB twp), deleted after their members moved to the corporation-level offices (Option A). Restore: see the migration header.';
COMMENT ON TABLE essentials._retired_ca0286_office_terms IS
  'CA_0286 (2026-09-24): archive of the 11 office_terms on the retired per-seat Monroe County IN school-board offices.';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  -- each of the 12 members (11 moved + Tucker) holds exactly one current office, and it is the mapped (b) office
  SELECT count(*) INTO v_n FROM _board bd
   WHERE (SELECT count(*) FROM essentials.office_current_holder och WHERE och.politician_id = bd.politician_id) = 1
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                   JOIN essentials.offices o ON o.id = och.office_id
                  WHERE och.politician_id = bd.politician_id AND och.office_id = bd.b_office
                    AND o.district_id IN (SELECT id FROM _b_districts));
  IF v_n <> 12 THEN RAISE EXCEPTION 'POST: % of 12 members hold exactly one current office, on their (b) seat', v_n; END IF;

  -- and each is still an active incumbent, so the incumbents-only reads keep showing them
  SELECT count(*) INTO v_n FROM _board bd JOIN essentials.politicians p ON p.id = bd.politician_id
   WHERE p.is_active AND p.is_incumbent;
  IF v_n <> 12 THEN RAISE EXCEPTION 'POST: % of 12 members are active incumbents', v_n; END IF;

  -- no office, and so no current term, remains on scheme (a)
  SELECT count(*) INTO v_n FROM essentials.offices o WHERE o.district_id IN (SELECT id FROM _a_districts);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % office(s) still on an (a) district', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t JOIN _map m ON m.a_office = t.office_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % term(s) still on an (a) office', v_n; END IF;

  -- archive = exactly what was deleted: the 11 mapped offices and their 11 terms, none still live
  SELECT count(*) INTO v_n FROM essentials._retired_ca0286_offices a JOIN _map m ON m.a_office = a.id;
  IF v_n <> 11 OR (SELECT count(*) FROM essentials._retired_ca0286_offices) <> 11 THEN
    RAISE EXCEPTION 'POST: archive holds % mapped of % offices; expected 11', v_n, (SELECT count(*) FROM essentials._retired_ca0286_offices);
  END IF;
  SELECT count(*) INTO v_n FROM essentials._retired_ca0286_office_terms a JOIN _map m ON m.a_office = a.office_id AND m.politician_id = a.politician_id;
  IF v_n <> 11 OR (SELECT count(*) FROM essentials._retired_ca0286_office_terms) <> 11 THEN
    RAISE EXCEPTION 'POST: archive holds % mapped of % terms; expected 11', v_n, (SELECT count(*) FROM essentials._retired_ca0286_office_terms);
  END IF;
  -- live totals moved by exactly (-deleted +created): -11 +6 on the first run, 0 on a re-run
  SELECT count(*) INTO v_n FROM essentials.offices;
  IF v_n <> b.offices - b.a_live + (CASE WHEN b.a_live = 11 THEN 6 ELSE 0 END) THEN
    RAISE EXCEPTION 'POST: offices % -> %, expected -% +%', b.offices, v_n, b.a_live, CASE WHEN b.a_live = 11 THEN 6 ELSE 0 END;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms;
  IF v_n <> b.terms - b.a_live + (CASE WHEN b.a_live = 11 THEN 6 ELSE 0 END) THEN
    RAISE EXCEPTION 'POST: terms % -> %, expected -% +%', b.terms, v_n, b.a_live, CASE WHEN b.a_live = 11 THEN 6 ELSE 0 END;
  END IF;

  -- every race still points at its original office
  SELECT count(*) INTO v_n FROM essentials.races r JOIN _races x ON x.race_id = r.id AND x.office_id = r.office_id;
  IF v_n <> 5 THEN RAISE EXCEPTION 'POST: % of 5 races still on their original office', v_n; END IF;

  -- no (b) school office is missing a term, and the unflagged baseline did not grow
  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms mt WHERE mt.district_id IN (SELECT id FROM _b_districts);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % (b) school office(s) in offices_missing_terms', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms WHERE NOT coalesce(is_vacant, false);
  IF v_n > b.missing_unflagged THEN RAISE EXCEPTION 'POST: unflagged offices_missing_terms grew % -> %', b.missing_unflagged, v_n; END IF;

  -- no legacy office_id snapshot dangles at a retired office
  SELECT count(*) INTO v_n FROM essentials.politicians p JOIN essentials._retired_ca0286_offices a ON a.id = p.office_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % politicians.office_id value(s) point at a retired office', v_n; END IF;

  -- the RBB township offices are browsable (chamber set) and every (b) board office is one seat
  SELECT count(*) INTO v_n FROM essentials.offices o
   WHERE o.district_id IN (SELECT id FROM _b_districts) AND (o.chamber_id IS NULL OR o.seats <> 1);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % (b) board office(s) with no chamber or seats <> 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices o WHERE o.district_id IN (SELECT id FROM _b_districts);
  IF v_n <> 12 THEN RAISE EXCEPTION 'POST: expected 12 (b) board offices (7 MCCSC + 5 RBB), found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials' AND c.relname IN ('_retired_ca0286_offices', '_retired_ca0286_office_terms') AND c.relrowsecurity;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: row-level security is on for % of 2 archive tables', v_n; END IF;

  RAISE NOTICE 'CA_0286 applied: 12 Monroe school-board members, one current seat each, all on corporation-level offices; 11 per-seat offices + terms archived and retired';
END $$;

COMMIT;
