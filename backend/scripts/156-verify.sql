-- 156-verify.sql — Phase 156 read-only production gate (USHC2-02/03/04/05 + D-01/02/03/04).
--
-- SELECT-only. Asserts the live state delivered across Phase 156's waves for the OH + GA + NC
-- 2026 US House field. Adapts the validated 155-verify.sql precedent (two states) to THREE states.
--
--   USHC2-03a — all 15 OH races (resp. 14 GA, 14 NC) have >=1 active race_candidate, and the race
--               COUNT is exactly 15 OH / 14 GA / 14 NC (no district missing). Hard floor is >=1 (a
--               safe seat may be uncontested); a NOTICE reports any race with <2.
--   USHC2-03b — 0 active race_candidates with NULL politician_id (per-state, House-scoped).
--   USHC2-02a — 0 duplicate full_name among ACTIVE candidates WITHIN each state (D-03).
--   USHC2-02c — every renominated OH/GA/NC incumbent reuses its 154 incumbent_pid as an ACTIVE
--               House candidate (no new duplicate-incumbent record — the v2.4 two-Andy-Barrs trap).
--               OH all 15; GA the 10 renominated (GA-2..9,12,14 incl. Clay Fuller -13014) — GA-1/10/11
--               EXCLUDED (lost/retired, asserted absent) and GA-13 has NO incumbent at all (vacancy);
--               NC all 14 INCL. NC-6 McDowell -37006 (reused as active incumbent, D-01).
--   D-04-GA   — GA lost/retired/open incumbents whose seat now has a different nominee are ABSENT
--               from the active field: GA-1 Carter, GA-10 Collins, GA-11 Loudermilk each appear 0
--               times as active; their certified general nominees ARE active.
--   D-04-GA13 — GA-13 is a TRUE VACANCY (David Scott died Apr 2026): NO incumbent-absent pin (there is
--               no incumbent pid). Assert instead Jasmine Clark AND Jonathan Chavez are BOTH active in
--               the GA-13 (geo 1313) race, both non-null politician_id, neither is_incumbent=true.
--   D-02      — named minor-line / multi-candidate fields are seeded (party-agnostic presence):
--               OH-4 Independent Tamie Wilson + NC-11 Independent John Rogers pinned by name here; the
--               OH/NC Libertarian + NC-13 Green lines are structurally covered by USHC2-03a and pinned
--               by the seeding waves (156-03/05 append named minor-line rows to _minor).
--   USHC2-04  — every newly-seeded OH/GA/NC candidate (politician_id in the new-candidate external_id
--               band: OH -399999..-390000, GA -139999..-130000, NC -379999..-370000) has an
--               essentials.politician_images row; documented headshot honest-skips pinned in _img_skip
--               by exact external_id WITH ORDER BY external_id (143 lesson).
--   USHC2-05a — 0 unsourced stance rows for the in-scope set (every answer has a matching
--               inform.politician_context with a non-empty sources array).
--   USHC2-05b — each in-scope candidate has >=1 sourced federal stance OR is a pinned whole-record
--               honest-skip (per-topic gaps accepted; full-24 NOT required — chairs-not-polarity
--               forbids party-inference inflation; [[project-149-stance-gate-standard]]).
--
-- ============================================================================
-- PER-STATE SCOPING (the cross-state contamination trap):
--   OH, GA, NC are SEPARATE elections. Every assertion is scoped by election id AND
--   d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN ('39','13','37').
--   NEVER write a cross-state or election-wide count.
--
-- D-01 ASYMMETRY (the partial-incumbent false-fail trap — the 150 TX/NY model, NOT 155):
--   Every OH/GA/NC incumbent is PARTIAL (stance 1-20) and LEFT AS-IS this phase EXCEPT
--   NC-6 Addison P. McDowell (74579547-1454-475e-ab35-12cf88a998b9 / -37006), whose stance_count is
--   ZERO. Per the zero-stance-gets-full-set rule (TX in Phase 150), McDowell IS in the stance
--   in-scope set and gets full-24 research (pushed by existing pid, _push.ts). ALL OTHER OH/GA/NC
--   partial incumbents are EXCLUDED from the USHC2-05a/05b in-scope set so their pre-existing
--   partial coverage cannot false-fail a 0-unsourced or coverage check. The in-scope set therefore =
--   the three new-candidate external_id bands UNION the single McDowell pid.
--
-- THE 143 HONEST-SKIP-ORDERING LESSON:
--   Any whole-record stance honest-skip (_stance_skip) and any headshot honest-skip (_img_skip) is
--   pinned by exact UUID / external_id WITH the query's exact ORDER BY. An ordering mismatch false-fails.
--
-- WRITE-FREE: no DELETE/UPDATE/INSERT INTO essentials|inform. The only writes are
--   CREATE TEMP TABLE ... ON COMMIT DROP (149/150/155-verify.sql precedent). SELECT-only.
--
-- WAVE TIMING (documented expectation — data-dependent assertions FAIL pre-seed, go green after):
--   156-02 AUTHORS this gate. 156-01 shipped the races scaffold -> USHC2-03 race-count passes now;
--   candidate/dedup (USHC2-02 + D-02/04) pass after 156-03/04/05; USHC2-04 after 156-06; USHC2-05
--   after 156-07/08/09. The _stance_skip + _img_skip pins are ADDED to this file by the relevant wave
--   (the 150/155 model). 156-06..09 may run this gate mid-wave. 156-10 runs it as the final proof.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/156-verify.sql
--
-- OH election: 32657ce8-8606-420b-8782-ca2c7f01c5ae  OH FIPS 39 / geo 3901..3915.
-- GA election: e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7  GA FIPS 13 / geo 1301..1314 (1313 = vacancy office).
-- NC election: 12e0bce3-d4c3-4e09-ba5d-18e8bc68be5e  NC FIPS 37 / geo 3701..3714.

\set ON_ERROR_STOP on

DO $$
DECLARE
  oh_eid           uuid;
  ga_eid           uuid;
  nc_eid           uuid;
  v_oh_races       int;
  v_ga_races       int;
  v_nc_races       int;
  v_under1         int;
  v_under2         int;
  v_nullpid        int;
  v_dupname        int;
  v_reuse_missing  int;
  v_lost_active    int;
  v_winner_missing int;
  v_ga13_missing   int;
  v_ga13_incumbent int;
  v_minor_missing  int;
  v_no_image       int;
  v_image_detail   text;
  v_unsourced      int;
  v_uncovered      int;
  v_cov_detail     text;
BEGIN
  SELECT id INTO oh_eid FROM essentials.elections WHERE name = 'OH 2026 Statewide General';
  SELECT id INTO ga_eid FROM essentials.elections WHERE name = 'GA 2026 Statewide General';
  SELECT id INTO nc_eid FROM essentials.elections WHERE name = 'NC 2026 Statewide General';
  IF oh_eid IS NULL OR ga_eid IS NULL OR nc_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: OH/GA/NC 2026 Statewide General election(s) not found (oh=%, ga=%, nc=%)', oh_eid, ga_eid, nc_eid;
  END IF;

  -- ==========================================================================
  -- Per-state House working sets (every race + LEFT JOIN candidates), scoped by
  -- election + NATIONAL_LOWER + geo prefix. _state column distinguishes OH/GA/NC.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE WHEN r.election_id = oh_eid THEN 'OH'
              WHEN r.election_id = ga_eid THEN 'GA'
              ELSE 'NC' END AS st,
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
  WHERE r.election_id IN (oh_eid, ga_eid, nc_eid)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN ('39','13','37');

  -- Scope sanity: exactly 15 OH + 14 GA + 14 NC distinct House races.
  SELECT COUNT(DISTINCT race_id) INTO v_oh_races FROM _house WHERE st = 'OH';
  SELECT COUNT(DISTINCT race_id) INTO v_ga_races FROM _house WHERE st = 'GA';
  SELECT COUNT(DISTINCT race_id) INTO v_nc_races FROM _house WHERE st = 'NC';
  IF v_oh_races <> 15 THEN RAISE EXCEPTION 'FAIL scope: expected 15 OH House races, got %', v_oh_races; END IF;
  IF v_ga_races <> 14 THEN RAISE EXCEPTION 'FAIL scope: expected 14 GA House races, got %', v_ga_races; END IF;
  IF v_nc_races <> 14 THEN RAISE EXCEPTION 'FAIL scope: expected 14 NC House races, got %', v_nc_races; END IF;

  -- ===== USHC2-03a — every race has >=1 active candidate (hard floor); count exact ==========
  SELECT COUNT(*) INTO v_under1 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 1
  ) q;
  IF v_under1 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-03a: % OH/GA/NC House race(s) have 0 active candidates', v_under1;
  END IF;
  SELECT COUNT(*) INTO v_under2 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 2
  ) q;
  RAISE NOTICE 'PASS USHC2-03a: all % OH/GA/NC House races have >=1 active candidate (% race(s) have <2 — uncontested-seat allowance)', v_oh_races + v_ga_races + v_nc_races, v_under2;

  -- ===== USHC2-03b — 0 active rows with NULL politician_id (per-state) =========
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-03b: % active OH/GA/NC House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS USHC2-03b: 0 active OH/GA/NC House candidates with NULL politician_id';

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
  RAISE NOTICE 'PASS USHC2-02a: 0 duplicate full_name within OH, GA, and NC (D-03)';

  -- ===== USHC2-02c — renominated incumbents reuse their 154 pid ==========
  -- Pin every renominated incumbent (154-incumbent-map.csv): OH all 15; GA the 10 renominated
  -- (GA-2..9, 12, 14 incl. Clay Fuller -13014); NC all 14 incl. NC-6 McDowell -37006.
  -- EXCLUDED (intentionally NOT in the set): GA-1 Carter / GA-10 Collins / GA-11 Loudermilk (lost/
  -- retired, asserted ABSENT below), and GA-13 which has NO incumbent at all (true vacancy).
  CREATE TEMP TABLE _reuse_pid (st text, expected_pid uuid, who text) ON COMMIT DROP;
  INSERT INTO _reuse_pid (st, expected_pid, who) VALUES
    -- OH incumbents (all 15 renominated)
    ('OH','6cad043f-a4c0-48d5-af76-fdf70d319920','Greg Landsman OH-1'),
    ('OH','1938e59f-bd7c-45fb-8dd1-2f7591a0fc3d','David J. Taylor OH-2'),
    ('OH','dd93f609-82f5-4923-8a0e-d73b58120b80','Joyce Beatty OH-3'),
    ('OH','09531f42-9724-4211-b33a-7f1af94b250e','Jim Jordan OH-4'),
    ('OH','e3c5cef5-08ff-4066-9fee-344733cb4137','Robert E. Latta OH-5'),
    ('OH','3fe892d9-3086-4088-a6d8-af7b3a8b80c1','Michael A. Rulli OH-6'),
    ('OH','02706ab4-75fc-4bbd-ae1e-b879c0955d3f','Max L. Miller OH-7'),
    ('OH','d7f3b400-2d9f-4d23-bd02-9edea5274e92','Warren Davidson OH-8'),
    ('OH','4d530660-da80-4d96-9c59-1a33ddf08e4b','Marcy Kaptur OH-9'),
    ('OH','792fbe55-46f5-49db-8400-2ce2632fd1ea','Michael R. Turner OH-10'),
    ('OH','e7f9cb36-33ae-4291-94da-57d956c822af','Shontel M. Brown OH-11'),
    ('OH','d053e66a-762e-4514-8e16-2ae672ee47e1','Troy Balderson OH-12'),
    ('OH','5dc95a47-7f94-46b3-b797-4bd2429ceb3e','Emilia Strong Sykes OH-13'),
    ('OH','811f725f-1eaa-4e67-9dbc-389698615e00','David P. Joyce OH-14'),
    ('OH','2dadf0d8-b767-4963-89ff-04441e995501','Mike Carey OH-15'),
    -- GA renominated incumbents (10; GA-1/10/11 lost/retired + GA-13 vacancy EXCLUDED)
    ('GA','a172a95a-b866-4ece-a7e2-47487c5ec471','Sanford D. Bishop, Jr. GA-2'),
    ('GA','eabb384b-b541-4232-978a-fbb7fcad9290','Brian Jack GA-3'),
    ('GA','135f4a8f-6e03-453f-a5b2-9a3b338f26c3','Henry C. "Hank" Johnson, Jr. GA-4'),
    ('GA','acb046eb-1db6-44bf-a50b-32d16df15057','Nikema Williams GA-5'),
    ('GA','66e69f62-7694-4e9a-89cf-8b699add8e1f','Lucy McBath GA-6'),
    ('GA','b295210e-a45d-4a80-8001-47cdc522a3e5','Richard McCormick GA-7'),
    ('GA','247e657a-8c30-4194-8702-81adce0beea4','Austin Scott GA-8'),
    ('GA','94d6a044-7a03-400d-8092-00aac9859c9b','Andrew S. Clyde GA-9'),
    ('GA','3de9e882-a816-42fc-ae70-aa93098c5d02','Rick W. Allen GA-12'),
    ('GA','8c4ce29b-84ae-445b-9531-9fdaceb5d420','Clay Fuller GA-14'),
    -- NC incumbents (all 14 renominated, incl. NC-6 McDowell reused as active incumbent, D-01)
    ('NC','f38f8dde-2073-4a22-a577-2a96ea9c15c3','Donald G. Davis NC-1'),
    ('NC','291f71df-c5c2-4f0a-b6be-d762d7aec9dd','Deborah K. Ross NC-2'),
    ('NC','6c2a7eee-dd04-4844-801d-5acddc4facba','Gregory F. Murphy NC-3'),
    ('NC','248c67f9-b8bf-4627-b358-a0f49b47abe7','Valerie P. Foushee NC-4'),
    ('NC','21b9bbfb-cb9b-44ab-90d5-8d3c847b8485','Virginia Foxx NC-5'),
    ('NC','74579547-1454-475e-ab35-12cf88a998b9','Addison P. McDowell NC-6'),
    ('NC','1fd041d0-473c-45f5-bbfb-54b42aaabc8d','David Rouzer NC-7'),
    ('NC','a10b5487-6874-4395-b193-aee6980d5bfe','Mark Harris NC-8'),
    ('NC','951d32a1-8ff1-4c4f-be20-01efdf8f02dc','Richard Hudson NC-9'),
    ('NC','93573d4e-f9e8-41df-b1b4-cbb5b8006e3f','Pat Harrigan NC-10'),
    ('NC','f7763de5-8cb1-439b-9176-2c16070c01df','Chuck Edwards NC-11'),
    ('NC','2c12afd3-178d-46c3-a4ea-a09f2f796ce9','Alma S. Adams NC-12'),
    ('NC','c432657b-d48d-4d3c-b2f2-6b83f6de47fc','Brad Knott NC-13'),
    ('NC','e27f0fc2-ef98-4592-ae87-f6320f2b847e','Tim Moore NC-14');

  SELECT COUNT(*) INTO v_reuse_missing
  FROM _reuse_pid rp
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = rp.st AND h.candidate_status = 'active' AND h.politician_id = rp.expected_pid
  );
  IF v_reuse_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-02c: % reused-incumbent pid(s) absent from active candidates (possible new duplicate-incumbent record — v2.4 trap)', v_reuse_missing;
  END IF;
  RAISE NOTICE 'PASS USHC2-02c: all % pinned renominated incumbents reuse their 154 pid (incl. NC-6 McDowell)', (SELECT COUNT(*) FROM _reuse_pid);

  -- ===== D-04-GA — lost/retired/open GA incumbents ABSENT; certified nominees PRESENT =====
  SELECT COUNT(*) INTO v_lost_active
  FROM _house h
  WHERE h.candidate_status = 'active'
    AND h.politician_id IN (
      '4bf58192-5208-4c5f-93f1-ac0a7e6b162d',  -- GA-1 Earl L. "Buddy" Carter (ran for Senate)
      'b6542655-fc71-4b18-a022-6528522cdcae',  -- GA-10 Mike Collins (ran for Senate)
      '7f0bb866-57f4-45de-88ae-5c9977f086bd'   -- GA-11 Barry Loudermilk (retired)
    );
  IF v_lost_active <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04-GA: % lost/retired GA incumbent(s) (Carter/Collins/Loudermilk) surfaced as ACTIVE candidate', v_lost_active;
  END IF;
  -- Certified general nominees present (match by name within the district's active field).
  CREATE TEMP TABLE _winners (st text, geo_id text, who text) ON COMMIT DROP;
  INSERT INTO _winners (st, geo_id, who) VALUES
    ('GA','1301','Jim Kingston'),      -- GA-1 R (Carter -> Senate)
    ('GA','1301','Amanda Hollowell'),  -- GA-1 D
    ('GA','1310','Houston Gaines'),    -- GA-10 R (Collins -> Senate)
    ('GA','1310','Pamela DeLancy'),    -- GA-10 D
    ('GA','1311','John Cowan'),        -- GA-11 R (Loudermilk retired)
    ('GA','1311','Chris Harden');      -- GA-11 D
  SELECT COUNT(*) INTO v_winner_missing
  FROM _winners w
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = w.st AND h.geo_id = w.geo_id
      AND h.candidate_status = 'active' AND lower(h.full_name) = lower(w.who)
  );
  IF v_winner_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04-GA: % certified GA general nominee(s) absent from the active field', v_winner_missing;
  END IF;
  RAISE NOTICE 'PASS D-04-GA: GA-1/10/11 lost/retired incumbents absent; certified nominees active';

  -- ===== D-04-GA13 — TRUE VACANCY: NO incumbent-absent pin; Clark + Chavez both active non-incumbent =====
  -- GA-13 (geo 1313) had NO incumbent (David Scott died Apr 2026), so there is no pid to assert absent.
  -- Assert both certified nominees are active with non-null pid and neither flagged is_incumbent.
  SELECT COUNT(*) INTO v_ga13_missing
  FROM (VALUES ('Jasmine Clark'), ('Jonathan Chavez')) AS n(who)
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = 'GA' AND h.geo_id = '1313'
      AND h.candidate_status = 'active' AND h.politician_id IS NOT NULL
      AND lower(h.full_name) = lower(n.who)
  );
  IF v_ga13_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04-GA13: % GA-13 vacancy nominee(s) (Clark/Chavez) absent from the active field', v_ga13_missing;
  END IF;
  SELECT COUNT(*) INTO v_ga13_incumbent
  FROM _house h
  WHERE h.st = 'GA' AND h.geo_id = '1313'
    AND h.candidate_status = 'active' AND h.is_incumbent = true;
  IF v_ga13_incumbent <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04-GA13: GA-13 is a true vacancy but % active candidate(s) flagged is_incumbent=true', v_ga13_incumbent;
  END IF;
  RAISE NOTICE 'PASS D-04-GA13: Clark + Chavez both active in GA-13 vacancy; no incumbent flag (no incumbent-absent pin)';

  -- ===== D-02 — minor-line / multi-candidate fields seeded (party-agnostic presence) ==
  -- Named independents pinned here; the OH/NC Libertarian + NC-13 Green lines are structurally
  -- covered by USHC2-03a and appended to _minor by the seeding waves (156-03/05) once their
  -- certified names are confirmed (D-03 re-confirm may trim unqualified lines).
  CREATE TEMP TABLE _minor (st text, geo_id text, who text) ON COMMIT DROP;
  INSERT INTO _minor (st, geo_id, who) VALUES
    ('OH','3904','Tamie Wilson'),   -- OH-4 Independent
    ('NC','3711','John Rogers');    -- NC-11 Independent
  SELECT COUNT(*) INTO v_minor_missing
  FROM _minor m
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = m.st AND h.geo_id = m.geo_id
      AND h.candidate_status = 'active' AND lower(h.full_name) = lower(m.who)
  );
  IF v_minor_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-02: % minor-line candidate(s) (OH-4 Wilson / NC-11 Rogers) not seeded as active', v_minor_missing;
  END IF;
  RAISE NOTICE 'PASS D-02: OH-4 Wilson + NC-11 Rogers seeded as active (minor lines not dropped)';

  -- ==========================================================================
  -- In-scope STANCE/HEADSHOT sets (D-01 ASYMMETRY — exclude ALL partial incumbents EXCEPT McDowell).
  --   _new_cands = newly-seeded OH/GA/NC candidates (new external_id band) — HEADSHOT + STANCE scope.
  --   _in_scope  = _new_cands UNION the single NC-6 McDowell pid (the ONLY in-scope incumbent).
  -- USHC2-04/05 data is populated by later waves; these assertions FAIL pre-seed (expected).
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.politician_id
  FROM _house h
  JOIN essentials.politicians p ON p.id = h.politician_id
  WHERE h.candidate_status = 'active'
    AND ( (h.st = 'OH' AND p.external_id BETWEEN -399999 AND -390000)
       OR (h.st = 'GA' AND p.external_id BETWEEN -139999 AND -130000)
       OR (h.st = 'NC' AND p.external_id BETWEEN -379999 AND -370000) );

  -- In-scope = new candidates UNION NC-6 McDowell (the ONE incumbent in scope — zero-stance, D-01).
  CREATE TEMP TABLE _in_scope ON COMMIT DROP AS
  SELECT DISTINCT politician_id FROM _new_cands
  UNION
  SELECT '74579547-1454-475e-ab35-12cf88a998b9'::uuid;

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

  -- Whole-record stance honest-skip set (USHS-14a pattern). Pinned by exact UUID, ORDER BY
  -- politician_id (143 lesson). POPULATED-BY-156-07/08/09: thin/no-source minor & first-time
  -- challengers whose primary sources are dead/JS-walled; party-inference refused (chairs-not-polarity).
  CREATE TEMP TABLE _stance_skip (politician_id uuid, reason text) ON COMMIT DROP;
  INSERT INTO _stance_skip (politician_id, reason) VALUES
    -- OH (156-07): 10 whole-record skips of 19 — no fetchable primary-source positions; party-inference refused
    ('2e23b789-8003-4f85-ae06-9401711429d8', 'Maria Jukic OH-14 — campaign site under development; no fetchable positions'),
    ('31ed91bc-f2f7-41d3-b08b-2d0f7b22beda', 'Jennifer Mazzuckelli OH-2 — no fetchable positions (site down, Ballotpedia empty)'),
    ('44d8e07d-1b11-4b5b-95e5-86e6c13ca320', 'Mike Kirchner OH-11 — no fetchable positions (site ECONNREFUSED)'),
    ('4d5e028c-5a9c-4f6b-b408-0f97996cd5b2', 'Joshua Kolasinski OH-4 — no issues content anywhere'),
    ('5371d8cf-6e66-47e1-a70b-7d5a7b470969', 'Brian Poindexter OH-7 — ActBlue-only, no policy specifics'),
    ('5c41400a-8ba5-4334-9add-bbfcc49cba03', 'Tamie Wilson OH-4 (I) — site 404s, Ballotpedia blank'),
    ('9e92b2e5-1222-4b58-8fe0-75a895be662f', 'Don Leonard OH-15 — site ECONNREFUSED, all sources blocked'),
    ('afb4ccea-8530-4e54-a075-9b4168924326', 'Elizabeth Kirtley OH-6 — site ECONNREFUSED, no record'),
    ('d923d20a-3ba6-46a2-a0d2-49534685ca3c', 'Cleophus Dulaney OH-3 — site ECONNREFUSED, Ballotpedia stub'),
    ('ec72b7c5-635a-4590-a730-7e1bd62ce2f7', 'John Hancock OH-1 (L) — no campaign/platform; LPO lists Stoops for OH-1 (154 field flag)');
  INSERT INTO _stance_skip (politician_id, reason) VALUES
    -- GA (156-08): 13 whole-record skips of 18 — no fetchable primary-source positions; party-inference refused
    ('16aca704-48ca-40dc-826e-8af5bb12dee3', 'James Duffe GA-4 — campaign domains ECONNREFUSED, no record'),
    ('23daee91-beb1-405d-be9b-c1a62f3de6fa', 'John Salvesen GA-5 — no reachable site/Ballotpedia/press'),
    ('3467ec59-d701-4e4e-899b-34756dee3ebf', 'Anthony Kozycki GA-7 — all domains refused, no Ballotpedia'),
    ('407ca254-9f51-4aa2-becb-2f1e9ca5ea70', 'Pamela DeLancy GA-10 — Ballotpedia empty, site redirects, no coverage'),
    ('57a9bf3e-4889-4b35-8a44-57430e7717ae', 'Houston Gaines GA-10 — GA-legislature roll-call record JS-walled (SPA); Ballotpedia/OTI empty'),
    ('66cae409-332e-4b3c-a352-675dcbb58863', 'Jasmine Clark GA-13 — GA-legislature roll-call record JS-walled (SPA); Ballotpedia/OTI empty'),
    ('8f9a8213-108f-45b6-a3bc-295dbe19339a', 'Kevin Martin GA-6 — site has only values language, no positions'),
    ('a8e23eef-136d-4cf1-bb0f-f5203c0eea81', 'Kelly Esti GA-8 — domains refused, no Ballotpedia/press'),
    ('aacada00-5cff-4a4e-9bd6-c0e4935df79f', 'Jim Kingston GA-1 — no published issue positions (bio only)'),
    ('be8701e2-af66-440f-84e4-1dd72525df86', 'Jonathan Chavez GA-13 — domains refused, no Ballotpedia/Wikipedia'),
    ('d2e4cc46-d553-410a-8733-16692b7ae64e', 'Caitlyn Gegen GA-9 — no online footprint in fetchable sources'),
    ('f7bf88b3-caa2-4856-9395-e0354b060828', 'Ceretta Smith GA-12 — site launching-soon placeholder, no content'),
    ('fcd56384-a715-4ae9-8804-b24bdfa46768', 'Matt Day GA-2 — site offline, no Ballotpedia/OTI/Wikipedia');
  -- (156-09 NC skip rows appended below)

  -- Headshot honest-skip set (no free-license portrait anywhere). Pinned by exact external_id WITH
  -- ORDER BY external_id (143 lesson). POPULATED-BY-156-06 (OH/GA/NC headshot pass).
  CREATE TEMP TABLE _img_skip (external_id bigint, reason text) ON COMMIT DROP;
  -- POPULATED-BY-156-06: 57 of 62 new OH/GA/NC candidates have no free-license portrait
  -- (only 5 imaged: Jasmine Clark, Houston Gaines, Richard Ojeda, Raymond Smith Jr., Laurie Buckhout).
  -- Ordered by external_id (143 lesson).
  INSERT INTO _img_skip (external_id, reason) VALUES
    (-391502, 'Brennan Barrington — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-391501, 'Don Leonard — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-391401, 'Maria Jukic — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-391301, 'Carey Coleman — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-391201, 'Jerrad Christian — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-391101, 'Mike Kirchner — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-391001, 'Kristina Knickerbocker — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390902, 'Matthew Althaus — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390901, 'Derek Merrin — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390801, 'Vanessa Enoch — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390701, 'Brian Poindexter — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390601, 'Elizabeth Kirtley — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390501, 'Brian Shaver — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390402, 'Tamie Wilson — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390401, 'Joshua Kolasinski — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390301, 'Cleophus Dulaney — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390201, 'Jennifer Mazzuckelli — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390102, 'John Hancock — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-390101, 'Eric Conroy — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371401, 'Lakesha Womack — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371303, 'Steven Swinton — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371302, 'Anthony Aguilar — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371301, 'Paul Barringer — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371201, 'Jack Codiga — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371103, 'John Rogers — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371102, 'Travis Groo — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371101, 'Jamie Ager — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371002, 'Steven Feldman — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-371001, 'Ashley Bell — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370801, 'Colby Watson — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370702, 'Maad Abu-Ghazalah — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370701, 'Kimberly Hardy — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370601, 'Cyril Jefferson — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370502, 'Robert Luffman — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370501, 'Chuck Hubbard — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370402, 'Guy Meilleur — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370401, 'Max Ganorkar — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370302, 'Daniel Cavender — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370202, 'Matt Laszacs — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370201, 'Gene Douglass — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-370102, 'Tom Bailey — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-131401, 'Shawn Harris — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-131302, 'Jonathan Chavez — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-131201, 'Ceretta Smith — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-131102, 'Chris Harden — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-131101, 'John Cowan — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-131002, 'Pamela DeLancy — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130901, 'Caitlyn Gegen — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130801, 'Kelly Esti — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130701, 'Anthony Kozycki — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130601, 'Kevin Martin — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130501, 'John Salvesen — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130401, 'James Duffe — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130301, 'Maura Keller — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130201, 'Matt Day — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130102, 'Amanda Hollowell — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
    (-130101, 'Jim Kingston — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused');

  -- ===== USHC2-04 — every newly-seeded OH/GA/NC candidate has a politician_images row ====
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
    RAISE EXCEPTION 'FAIL USHC2-04 (Wave 3): % newly-seeded OH/GA/NC candidate(s) lack a politician_images row: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS USHC2-04: every newly-seeded OH/GA/NC candidate has a politician_images row';

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
    RAISE EXCEPTION 'FAIL USHC2-05a (Wave 3): % unsourced stance row(s) in the in-scope OH/GA/NC candidate set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS USHC2-05a: 0 unsourced stance rows for the in-scope OH/GA/NC candidate set';

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
