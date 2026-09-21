-- CA_0126_seed_monroe_judges_trustees_2026_general.sql
-- Monroe County 2026 general: elected Circuit Court judges, township trustees, and the
-- Ellettsville town-council ward seats. All existed only on the '2026 Indiana Primary';
-- the general held none. Reuses the existing (geofenced) offices — no office creation.
--
-- Extends 'IN 2026 Statewide General'. Township boards (3-seat, at-large) are deliberately
-- NOT here — they need per-board primary-result winnowing and are a separate step.
--
-- ADDS 15 RACES / 17 CANDIDATES (certified Nov field; primary_party NULL = general):
--   Circuit Court Judge No. 5   Kara Elaine Krothe (D, inc) — unopposed
--   Circuit Court Judge No. 9   Geoff Bradley (D, inc) — unopposed
--   Bean Blossom Twp Trustee    Ronald H. Hutson (R, inc) — unopposed
--   Benton Twp Trustee          Michelle Bright (D, inc) — unopposed
--   Bloomington Twp Trustee     Efrat Rosser (D, inc) — unopposed
--   Clear Creek Twp Trustee     Susan Luther (D), Steven A. Hinds (R, inc)   [contested]
--   Indian Creek Twp Trustee    Susan Hingle (D), Christopher Reynolds (R, inc) [contested]
--   Perry Twp Trustee           Leon Gordon (D) — unopposed (won D primary; Petry withdrew)
--   Polk Twp Trustee            Scott Smith (R, inc) — unopposed
--   Richland Twp Trustee        Dawn Marie Durnil (R, inc) — unopposed
--   Salt Creek Twp Trustee      Joan C. Hall (D, inc) — unopposed
--   Van Buren Twp Trustee       Rita Barrow (R, inc) — unopposed
--   Washington Twp Trustee      Mary VanDeventer (R, inc) — unopposed
--   Ellettsville Council Ward 4 Andrew Henry (R) — unopposed
--   Ellettsville Council Ward 5 Marv Ulmet (R) — unopposed
--
-- CONTESTED-PRIMARY WINNERS confirmed from May-5 results: Clear Creek Trustee R → Hinds
-- (over Jeffries, Mungle); Perry Trustee D → Gordon (over Combs). No independent filed for
-- any of the 15. Party never stored (antipartisan). 13 of 17 candidates link to their
-- existing politician rows; the four with none in the primary data (Luther, Hingle, Henry,
-- Ulmet) get politician_id NULL.
--
-- NOTE (pre-existing, not fixed here): both Ellettsville wards sit on the town geo_id
-- '1820800' (no ward-level geofence), so an Ellettsville address sees both ward races —
-- same as the primary modelled them.
--
-- SOURCE: Ballotpedia "Monroe County, Indiana, elections, 2026" (final general field),
-- cross-checked vs B Square Bulletin certified primary results for the two contested
-- trustees. County filing page was offline. Retrieved 2026-09-21.
--
-- IDEMPOTENCY: races guard on (election_id, position_name); candidates on
-- (race_id, lower(full_name)).

BEGIN;

CREATE TEMP TABLE jt_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO jt_race_seed VALUES
  ('Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 5', '7cb0aaa5-1028-4f1b-8bcb-846ef6774305'),
  ('Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 9', '69ea8243-4cd3-42fb-abcf-e1b9b40edc6d'),
  ('Bean Blossom Township Trustee', 'd7d6bd6f-9f40-4895-b221-7819323f8a38'),
  ('Benton Township Trustee',       'd1d466c3-c4af-4f1e-8bb0-9a7bd163c829'),
  ('Bloomington Township Trustee',  '16cf2b08-aa20-461b-9264-61363b92558e'),
  ('Clear Creek Township Trustee',  '2025b982-3f1c-4a0d-9a1c-a24d46ac1a79'),
  ('Indian Creek Township Trustee', 'ce661f57-ef86-432e-8332-c59abbef4170'),
  ('Perry Township Trustee',        'a8c9cc56-47ca-4853-9c2f-87231ee547c1'),
  ('Polk Township Trustee',         '11be4cdb-141e-4675-a78e-8fecf45d9416'),
  ('Richland Township Trustee',     '15ffa6a5-2af6-4b15-bc1c-3d9f900e2334'),
  ('Salt Creek Township Trustee',   '0bbce550-0b3b-48cf-92b8-05dc6eb20eda'),
  ('Van Buren Township Trustee',    'd7346490-6000-439b-97d6-e05f242a40bc'),
  ('Washington Township Trustee',   'c92cba7b-1443-4104-ab1f-d1ec98dd8a06'),
  ('Ellettsville Town Council Ward 4', '7616b007-4e0d-4617-a80f-037ad30fc55a'),
  ('Ellettsville Town Council Ward 5', 'adccb33f-579b-4378-975a-c6762fd47eb0');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid, s.office_id, s.position_name, NULL, 1
FROM jt_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=s.position_name
);

CREATE TEMP TABLE jt_cand_seed
  (position_name text, full_name text, first_name text, last_name text,
   is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO jt_cand_seed VALUES
  ('Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 5', 'Kara Elaine Krothe', 'Kara',  'Krothe',     true,  '048cb4ba-9b07-42e6-b45d-f4dffad2a088'::uuid),
  ('Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 9', 'Geoff Bradley',      'Geoff', 'Bradley',    true,  '999a9d38-9894-45f0-80c7-228880089699'::uuid),
  ('Bean Blossom Township Trustee', 'Ronald H. Hutson',    'Ronald',      'Hutson',      true,  'b407f620-d412-46b4-939a-d0967f8f80d2'::uuid),
  ('Benton Township Trustee',       'Michelle Bright',     'Michelle',    'Bright',      true,  'c096fd15-2656-4e1c-bf86-beb506d472d7'::uuid),
  ('Bloomington Township Trustee',  'Efrat Rosser',        'Efrat',       'Rosser',      true,  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd'::uuid),
  ('Clear Creek Township Trustee',  'Susan Luther',        'Susan',       'Luther',      false, NULL::uuid),
  ('Clear Creek Township Trustee',  'Steven A. Hinds',     'Steven',      'Hinds',       true,  'ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d'::uuid),
  ('Indian Creek Township Trustee', 'Susan Hingle',        'Susan',       'Hingle',      false, NULL::uuid),
  ('Indian Creek Township Trustee', 'Christopher Reynolds','Christopher', 'Reynolds',    true,  'c905324f-0568-48e9-931f-d42ddc657ec3'::uuid),
  ('Perry Township Trustee',        'Leon Gordon',         'Leon',        'Gordon',      false, '7f3c23d7-3878-4735-9e2c-a805413a9c6b'::uuid),
  ('Polk Township Trustee',         'Scott Smith',         'Scott',       'Smith',       true,  '4e663791-4b3a-4df3-8cd1-aff5a133d100'::uuid),
  ('Richland Township Trustee',     'Dawn Marie Durnil',   'Dawn',        'Durnil',      true,  'd29e4645-d19f-4081-992d-fe66344a126c'::uuid),
  ('Salt Creek Township Trustee',   'Joan C. Hall',        'Joan',        'Hall',        true,  '6775a8e6-37cb-437b-923b-5f664f6b3b5d'::uuid),
  ('Van Buren Township Trustee',    'Rita Barrow',         'Rita',        'Barrow',      true,  'a41df72a-b1ee-43b6-8b41-02b4966503db'::uuid),
  ('Washington Township Trustee',   'Mary VanDeventer',    'Mary',        'VanDeventer', true,  'be355b0e-79a9-4af2-9926-d5bee7ae2515'::uuid),
  ('Ellettsville Town Council Ward 4', 'Andrew Henry',     'Andrew',      'Henry',       false, NULL::uuid),
  ('Ellettsville Town Council Ward 5', 'Marv Ulmet',       'Marv',        'Ulmet',       false, NULL::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'Ballotpedia "Monroe County, Indiana, elections, 2026" (final general field); contested trustees cross-checked vs B Square Bulletin certified primary results. Retrieved 2026-09-21.'
FROM jt_cand_seed cs
JOIN essentials.races r
  ON r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_races int; v_cands int; v_orphan int; v_party int; v_dup int; v_nogeo int;
BEGIN
  SELECT count(*) INTO v_races
    FROM essentials.races r JOIN jt_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid;

  SELECT count(*) INTO v_cands
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN jt_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid;

  SELECT count(*) INTO v_orphan
    FROM essentials.races r JOIN jt_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.office_id IS NULL;

  -- Every office must sit on a district that has a geofence, or it never matches an address.
  SELECT count(*) INTO v_nogeo
    FROM essentials.races r JOIN jt_race_seed s ON s.position_name=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id);

  SELECT count(*) INTO v_party
    FROM essentials.races r JOIN jt_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid AND r.primary_party IS NOT NULL;

  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n
      FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
      JOIN jt_race_seed s ON s.position_name=r.position_name
     WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_races  <> 15 THEN RAISE EXCEPTION 'races: expected 15, got %', v_races; END IF;
  IF v_cands  <> 17 THEN RAISE EXCEPTION 'candidates: expected 17, got %', v_cands; END IF;
  IF v_orphan <> 0  THEN RAISE EXCEPTION '% race(s) with NULL office_id', v_orphan; END IF;
  IF v_nogeo  <> 0  THEN RAISE EXCEPTION '% race(s) on a district with no geofence', v_nogeo; END IF;
  IF v_party  <> 0  THEN RAISE EXCEPTION '% general race(s) carry primary_party', v_party; END IF;
  IF v_dup    <> 0  THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
END $$;

COMMIT;
