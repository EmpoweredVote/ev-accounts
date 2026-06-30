-- 155-verify.sql — Phase 155 read-only production gate (USHC2-02/03/04/05 + D-01/02/03/04).
--
-- SELECT-only. Asserts the live state delivered across Phase 155's waves for the PA + IL
-- 2026 US House field. Adapts the validated 150-verify.sql precedent (two states) for PA/IL.
--
--   USHC2-03a — all 17 PA races (resp. 17 IL) have >=1 active race_candidate, and the race
--               COUNT is exactly 17 PA / 17 IL (no district missing). Hard floor is >=1 (a safe
--               seat may be uncontested — e.g. PA-3 Chris Rabb unopposed-D per 154 field); a
--               NOTICE reports any race with <2 (typical field is >=2).
--   USHC2-03b — 0 active race_candidates with NULL politician_id (per-state, House-scoped).
--   USHC2-02a — 0 duplicate full_name among ACTIVE candidates WITHIN each state (D-03).
--   USHC2-02c — every renominated PA & IL incumbent reuses its 154 incumbent_pid as an ACTIVE
--               House candidate (no new duplicate-incumbent record — the v2.4 two-Andy-Barrs trap).
--   D-04      — lost/retired/open incumbents whose seat now has a different nominee are ABSENT
--               from the active field: PA-3 Evans, IL-2 Kelly, IL-4 García, IL-7 Davis, IL-8
--               Krishnamoorthi, IL-9 Schakowsky each appear 0 times as active; their certified
--               general nominees ARE active.
--   D-02      — named minor-line / multi-candidate fields are seeded (party-agnostic presence):
--               PA-10 Isabelle Harman + Steven Long, PA-13 Cody Thomas, IL-2 Ashley Banks.
--   USHC2-04  — every newly-seeded PA/IL candidate (politician_id in the new-candidate external_id
--               band: PA -429999..-420000, IL -179999..-170000) has an essentials.politician_images
--               row; documented headshot honest-skips pinned in _img_skip by exact external_id.
--   USHC2-05a — 0 unsourced stance rows for the in-scope set (every answer has a matching
--               inform.politician_context with a non-empty sources array).
--   USHC2-05b — each in-scope candidate has >=1 sourced federal stance OR is a pinned whole-record
--               honest-skip (per-topic gaps accepted; full-24 NOT required — chairs-not-polarity
--               forbids party-inference inflation; [[project-149-stance-gate-standard]]).
--
-- ============================================================================
-- PER-STATE SCOPING (the cross-state contamination trap):
--   PA and IL are SEPARATE elections. Every assertion is scoped by election id AND
--   d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2)='42' (PA) / '17' (IL).
--   NEVER write a cross-state or election-wide count.
--
-- D-01 SYMMETRY (the partial-incumbent false-fail trap):
--   Unlike Phase 150's TX (all-zero -> in scope) vs NY (all-partial -> excluded) ASYMMETRY,
--   in Phase 155 BOTH PA and IL incumbents are ALL-PARTIAL (1-23 of fed-24; none zero, none full).
--   Per D-01 they are LEFT AS-IS this phase (NOT topped up). So the stance/headshot in-scope set
--   is ONLY the NEW PA/IL challengers + open-seat nominees (new external_id band). ALL PA + IL
--   incumbents are EXCLUDED so their pre-existing partial coverage cannot false-fail a 0-unsourced
--   or coverage check.
--
-- THE 143 HONEST-SKIP-ORDERING LESSON:
--   Any whole-record stance honest-skip (_stance_skip) and any headshot honest-skip (_img_skip) is
--   pinned by exact UUID / external_id WITH the query's exact ORDER BY. An ordering mismatch false-fails.
--
-- WRITE-FREE: no DELETE/UPDATE/INSERT INTO essentials|inform. The only writes are
--   CREATE TEMP TABLE ... ON COMMIT DROP (149/150-verify.sql precedent). SELECT-only.
--
-- WAVE TIMING (documented expectation — data-dependent assertions FAIL pre-seed, go green after):
--   155-02 AUTHORS this gate. 155-01 shipped the races scaffold -> USHC2-03 race-count passes now;
--   candidate/dedup (USHC2-02 + D-02/04) pass after 155-03/04; USHC2-04 after 155-05/06; USHC2-05
--   after 155-07/08. The IL-4 certified-general winner pin + _stance_skip + _img_skip pins are
--   ADDED to this file by the relevant wave (the 150 model). 155-05..08 may run this gate mid-wave.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/155-verify.sql
--
-- PA election: ed54a0a5-4204-462b-9f3e-c3debed12501  PA FIPS 42 / geo 4201..4217.
-- IL election: 804d07cf-11c9-4e3d-a85d-9ff8cbffb828  IL FIPS 17 / geo 1701..1717.

\set ON_ERROR_STOP on

DO $$
DECLARE
  pa_eid           uuid;
  il_eid           uuid;
  v_pa_races       int;
  v_il_races       int;
  v_under1         int;
  v_under2         int;
  v_nullpid        int;
  v_dupname        int;
  v_reuse_missing  int;
  v_lost_active    int;
  v_winner_missing int;
  v_minor_missing  int;
  v_no_image       int;
  v_image_detail   text;
  v_unsourced      int;
  v_uncovered      int;
  v_cov_detail     text;
BEGIN
  SELECT id INTO pa_eid FROM essentials.elections WHERE name = 'PA 2026 Statewide General';
  SELECT id INTO il_eid FROM essentials.elections WHERE name = 'IL 2026 Statewide General';
  IF pa_eid IS NULL OR il_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: PA/IL 2026 Statewide General election(s) not found (pa=%, il=%)', pa_eid, il_eid;
  END IF;

  -- ==========================================================================
  -- Per-state House working sets (every race + LEFT JOIN candidates), scoped by
  -- election + NATIONAL_LOWER + geo prefix. _state column distinguishes PA/IL.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE WHEN r.election_id = pa_eid THEN 'PA' ELSE 'IL' END AS st,
         r.id            AS race_id,
         d.geo_id        AS geo_id,
         rc.id           AS rc_id,
         rc.politician_id,
         rc.full_name,
         rc.candidate_status,
         rc.is_incumbent
  FROM essentials.races r
  JOIN essentials.offices o     ON o.id = r.office_id
  JOIN essentials.districts d   ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  WHERE r.election_id IN (pa_eid, il_eid)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN ('42','17');

  -- Scope sanity: exactly 17 PA + 17 IL distinct House races.
  SELECT COUNT(DISTINCT race_id) INTO v_pa_races FROM _house WHERE st = 'PA';
  SELECT COUNT(DISTINCT race_id) INTO v_il_races FROM _house WHERE st = 'IL';
  IF v_pa_races <> 17 THEN RAISE EXCEPTION 'FAIL scope: expected 17 PA House races, got %', v_pa_races; END IF;
  IF v_il_races <> 17 THEN RAISE EXCEPTION 'FAIL scope: expected 17 IL House races, got %', v_il_races; END IF;

  -- ===== USHC2-03a — every race has >=1 active candidate (hard floor); count exact ==========
  SELECT COUNT(*) INTO v_under1 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 1
  ) q;
  IF v_under1 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-03a: % PA/IL House race(s) have 0 active candidates', v_under1;
  END IF;
  SELECT COUNT(*) INTO v_under2 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 2
  ) q;
  RAISE NOTICE 'PASS USHC2-03a: all % PA/IL House races have >=1 active candidate (% race(s) have <2 — uncontested-seat allowance, e.g. PA-3 Rabb)', v_pa_races + v_il_races, v_under2;

  -- ===== USHC2-03b — 0 active rows with NULL politician_id (per-state) =========
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-03b: % active PA/IL House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS USHC2-03b: 0 active PA/IL House candidates with NULL politician_id';

  -- ===== USHC2-02a — 0 duplicate full_name among ACTIVE candidates WITHIN each state =========
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT st, lower(full_name)
    FROM _house
    WHERE candidate_status = 'active'
    GROUP BY st, lower(full_name)
    HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-02a: % duplicate full_name(s) within a state among active candidates (D-03 / v2.4 dup-incumbent trap)', v_dupname;
  END IF;
  RAISE NOTICE 'PASS USHC2-02a: 0 duplicate full_name within PA and within IL (D-03)';

  -- ===== USHC2-02c — renominated incumbents reuse their 154 pid ==========
  -- Pin every renominated incumbent (154-incumbent-map.csv): PA all 17 except PA-3 (Evans retired);
  -- IL all except IL-2/4/7/8/9 (Kelly/García/Davis/Krishnamoorthi/Schakowsky). Assert each pinned pid
  -- appears as an ACTIVE is_incumbent=true House candidate in its state.
  -- EXCLUDED (intentionally NOT in the set): the 6 lost/retired incumbents (asserted ABSENT in D-04).
  CREATE TEMP TABLE _reuse_pid (st text, expected_pid uuid, who text) ON COMMIT DROP;
  INSERT INTO _reuse_pid (st, expected_pid, who) VALUES
    -- PA renominated incumbents (16; PA-3 Evans EXCLUDED — retired)
    ('PA','a5d68f92-d5e2-4fa1-a191-a64e8ebb2ada','Brian K. Fitzpatrick PA-1'),
    ('PA','6d11b72d-fb42-49ca-b44f-89ef02defbb7','Brendan F. Boyle PA-2'),
    ('PA','bf942e86-fe8c-496f-9a36-212e9f9403e3','Madeleine Dean PA-4'),
    ('PA','ba906956-7359-4b26-8f1b-0d8f8d60b9fc','Mary Gay Scanlon PA-5'),
    ('PA','abf87328-e0fa-4ebd-89e6-6f1631e5a5c2','Chrissy Houlahan PA-6'),
    ('PA','38f9fb6c-b2de-4a79-a9fa-82f400a6a6f2','Ryan Mackenzie PA-7'),
    ('PA','ac16b65b-c438-40e4-b192-1a01418c2225','Robert P. Bresnahan, Jr. PA-8'),
    ('PA','345511a8-3f1a-40a7-96a6-b87d6ec011b1','Daniel Meuser PA-9'),
    ('PA','7412719e-e468-4ce7-85fb-26516ca7610f','Scott Perry PA-10'),
    ('PA','a4f800f0-6634-47c6-a340-ca494544d9b5','Lloyd Smucker PA-11'),
    ('PA','117883ff-7a9a-42cb-b42b-82223f1d618d','Summer L. Lee PA-12'),
    ('PA','7a858437-ac72-45bf-a2b7-3cc130ca6584','John Joyce PA-13'),
    ('PA','6840c7e6-2169-43a4-8490-1e73c8704cbd','Guy Reschenthaler PA-14'),
    ('PA','6cf68d79-f822-47c4-b702-1f14f20270e4','Glenn Thompson PA-15'),
    ('PA','4c34d7a5-ceea-493f-a6a4-cb5d14763593','Mike Kelly PA-16'),
    ('PA','c20345d9-e451-4813-8645-985734fedba3','Christopher R. Deluzio PA-17'),
    -- IL renominated incumbents (12; IL-2/4/7/8/9 EXCLUDED — retired/Senate run)
    ('IL','66da3b64-3dab-4f79-950a-475acc006dc8','Jonathan L. Jackson IL-1'),
    ('IL','f74970a7-a63c-43e2-8033-d04b7f2bd64d','Delia C. Ramirez IL-3'),
    ('IL','05e88b53-b6f4-4c5d-bcd2-f6b7b20f98d6','Mike Quigley IL-5'),
    ('IL','05cf439f-3932-4398-b97b-4fd9a7506934','Sean Casten IL-6'),
    ('IL','ecdb6fda-81cd-48bd-9403-a03a82f3ebad','Bradley Scott Schneider IL-10'),
    ('IL','f45dfff4-2279-4d59-b682-160bb402b37b','Bill Foster IL-11'),
    ('IL','01c4093a-db5a-4f92-9caa-b54c1e44c63a','Mike Bost IL-12'),
    ('IL','6192aa12-077f-42a8-a4cc-fcdf5d56355f','Nikki Budzinski IL-13'),
    ('IL','4774c04d-23cd-4e0f-91d2-e294864f0dbb','Lauren Underwood IL-14'),
    ('IL','73816ba4-4235-400c-a0a1-00c67b762687','Mary E. Miller IL-15'),
    ('IL','f0d27c86-02f3-4014-9162-e4e940f2afdd','Darin LaHood IL-16'),
    ('IL','a87adee0-ca19-4e02-b734-e6a91ca34245','Eric Sorensen IL-17');

  SELECT COUNT(*) INTO v_reuse_missing
  FROM _reuse_pid rp
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = rp.st AND h.candidate_status = 'active' AND h.politician_id = rp.expected_pid
  );
  IF v_reuse_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-02c: % reused-incumbent pid(s) absent from active candidates (possible new duplicate-incumbent record — v2.4 trap)', v_reuse_missing;
  END IF;
  RAISE NOTICE 'PASS USHC2-02c: all % pinned renominated incumbents reuse their 154 pid', (SELECT COUNT(*) FROM _reuse_pid);

  -- ===== D-04 — lost/retired/open incumbents ABSENT; certified nominees PRESENT =====
  SELECT COUNT(*) INTO v_lost_active
  FROM _house h
  WHERE h.candidate_status = 'active'
    AND h.politician_id IN (
      '3c962502-99c7-46ec-ae6b-0c69143f571c',  -- PA-3 Dwight Evans (retired)
      '9d9ce75d-b1ba-4051-a87e-e84c1619be8a',  -- IL-2 Robin L. Kelly (ran for Senate)
      '2bc2ecee-9c21-47cd-ae0f-d712b1fa8b3e',  -- IL-4 Jesús G. "Chuy" García (retired)
      '0e65d006-9ede-4d90-b13b-23874d67b674',  -- IL-7 Danny K. Davis (retired)
      'ee1a8680-16cf-40ee-bbee-09670cb296cc',  -- IL-8 Raja Krishnamoorthi (ran for Senate)
      '4fbdecd3-3161-49da-a610-9b9312e72507'   -- IL-9 Janice D. Schakowsky (retired)
    );
  IF v_lost_active <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04: % lost/retired incumbent(s) (Evans/Kelly/García/Davis/Krishnamoorthi/Schakowsky) surfaced as ACTIVE candidate', v_lost_active;
  END IF;
  -- Certified general nominees present (match by name within the district's active field).
  -- NOTE (155-04 TODO): IL-4 (geo 1704) certified D nominee is re-confirmed from the IL SoS certified
  -- ballot in 155-04 (the 154 field listed the 7-name PRIMARY field, not the general). Add the IL-4
  -- winner row below once 155-04 confirms it; left out here to avoid pinning an unconfirmed name.
  CREATE TEMP TABLE _winners (st text, geo_id text, who text) ON COMMIT DROP;
  INSERT INTO _winners (st, geo_id, who) VALUES
    ('PA','4203','Chris Rabb'),      -- PA-3 (Evans retired)
    ('IL','1702','Donna Miller'),    -- IL-2 (Kelly -> Senate)
    ('IL','1707','La Shawn Ford'),   -- IL-7 (Davis retired)
    ('IL','1708','Melissa Bean'),    -- IL-8 (Krishnamoorthi -> Senate)
    ('IL','1709','Daniel Biss');     -- IL-9 (Schakowsky retired)
  SELECT COUNT(*) INTO v_winner_missing
  FROM _winners w
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = w.st AND h.geo_id = w.geo_id
      AND h.candidate_status = 'active' AND lower(h.full_name) = lower(w.who)
  );
  IF v_winner_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04: % certified general nominee(s) absent from the active field', v_winner_missing;
  END IF;
  RAISE NOTICE 'PASS D-04: 6 lost/retired incumbents absent; certified nominees active (IL-4 winner pin added by 155-04)';

  -- ===== D-02 — minor-line / multi-candidate fields seeded (party-agnostic presence) ==
  CREATE TEMP TABLE _minor (st text, geo_id text, who text) ON COMMIT DROP;
  INSERT INTO _minor (st, geo_id, who) VALUES
    ('PA','4210','Isabelle Harman'),  -- PA-10 Independent
    ('PA','4210','Steven Long'),      -- PA-10 Independent
    ('PA','4213','Cody Thomas'),      -- PA-13 Independent
    ('IL','1702','Ashley Banks');     -- IL-2 Independent
  SELECT COUNT(*) INTO v_minor_missing
  FROM _minor m
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = m.st AND h.geo_id = m.geo_id
      AND h.candidate_status = 'active' AND lower(h.full_name) = lower(m.who)
  );
  IF v_minor_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-02: % minor-line candidate(s) (Harman/Long/Thomas/Banks) not seeded as active', v_minor_missing;
  END IF;
  RAISE NOTICE 'PASS D-02: PA-10 Harman+Long / PA-13 Thomas / IL-2 Banks seeded as active (minor lines not dropped)';

  -- ==========================================================================
  -- In-scope STANCE/HEADSHOT sets (D-01 symmetry — BOTH states exclude incumbents).
  --   _new_cands = newly-seeded PA/IL candidates (new external_id band) — HEADSHOT + STANCE scope.
  --   ALL PA + IL partial incumbents are EXCLUDED (left as-is this phase).
  -- USHC2-04/05 data is populated by later waves; these assertions FAIL pre-seed (expected).
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.politician_id
  FROM _house h
  JOIN essentials.politicians p ON p.id = h.politician_id
  WHERE h.candidate_status = 'active'
    AND ( (h.st = 'PA' AND p.external_id BETWEEN -429999 AND -420000)
       OR (h.st = 'IL' AND p.external_id BETWEEN -179999 AND -170000) );

  CREATE TEMP TABLE _in_scope ON COMMIT DROP AS
  SELECT DISTINCT politician_id FROM _new_cands;

  -- Federal-24 topic_ids (resolved live by key).
  CREATE TEMP TABLE _fed24 ON COMMIT DROP AS
  SELECT id AS topic_id, topic_key
  FROM inform.compass_topics
  WHERE topic_key IN (
    'abortion','ai-regulation','campaign-finance','childcare','civil-rights',
    'climate-change','deportation','fossil-fuels','healthcare','homelessness',
    'housing','immigration','medicare/aid','misinformation','redistricting',
    'religious-freedom','same-sex-marriage','school-vouchers','social-security',
    'tariffs','taxes','trans-athletes','voting-rights','ukraine-support');

  -- Whole-record stance honest-skip set (USHS-14a pattern). Pinned by exact UUID WITH the
  -- query's ORDER BY (143 lesson). EMPTY now — POPULATED-BY-155-07/08 for genuinely no-record
  -- challengers (campaign sites dead/slogan-only; no Ballotpedia survey; inference refused).
  CREATE TEMP TABLE _stance_skip (politician_id uuid, reason text) ON COMMIT DROP;

  -- Headshot honest-skip set (no free-license portrait anywhere). Pinned by exact external_id WITH
  -- ORDER BY. EMPTY now — POPULATED-BY-155-05/06. A wrong-person/copyrighted image is refused over filling.
  CREATE TEMP TABLE _img_skip (external_id bigint, reason text) ON COMMIT DROP;

  -- ===== USHC2-04 — every newly-seeded PA/IL candidate has a politician_images row ====
  SELECT COUNT(*),
         string_agg(p.full_name || ' (' || p.external_id || ')', ', ' ORDER BY p.external_id)
    INTO v_no_image, v_image_detail
  FROM _new_cands nc
  JOIN essentials.politicians p ON p.id = nc.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id
  )
  AND p.external_id NOT IN (SELECT external_id FROM _img_skip);
  IF v_no_image <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-04 (Wave 3): % newly-seeded PA/IL candidate(s) lack a politician_images row: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS USHC2-04: every newly-seeded PA/IL candidate has a politician_images row';

  -- ===== USHC2-05a — 0 unsourced stance rows for the in-scope set (Wave 3) =====
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers a
  JOIN _in_scope s ON s.politician_id = a.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id
      AND c.topic_id = a.topic_id
      AND c.sources IS NOT NULL
      AND array_length(c.sources, 1) >= 1
  );
  IF v_unsourced <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-05a (Wave 3): % unsourced stance row(s) in the in-scope PA/IL candidate set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS USHC2-05a: 0 unsourced stance rows for the in-scope PA/IL candidate set';

  -- ===== USHC2-05b — >=1 sourced federal stance OR pinned whole-record skip =====
  SELECT COUNT(*),
         string_agg(x.who, ', ' ORDER BY x.politician_id)
    INTO v_uncovered, v_cov_detail
  FROM (
    SELECT s.politician_id,
           COALESCE(p.full_name, s.politician_id::text) AS who,
           (SELECT COUNT(*) FROM inform.politician_answers a
              JOIN _fed24 f ON f.topic_id = a.topic_id
             WHERE a.politician_id = s.politician_id) AS fed_count
    FROM _in_scope s
    LEFT JOIN essentials.politicians p ON p.id = s.politician_id
    WHERE s.politician_id NOT IN (SELECT politician_id FROM _stance_skip)
  ) x
  WHERE x.fed_count < 1;
  IF v_uncovered <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-05b: % in-scope candidate(s) have 0 federal stances and are not pinned as whole-record honest-skip: %', v_uncovered, v_cov_detail;
  END IF;
  RAISE NOTICE 'PASS USHC2-05b: every in-scope candidate has >=1 sourced federal stance or is a pinned whole-record honest-skip';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC2-02/03/04/05 + D-01/02/03/04)';
END $$;
