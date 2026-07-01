-- 157-verify.sql — Phase 157 read-only production gate (USHC2-02/03/04/05 + D-01/02/03/04).
--
-- SELECT-only. Asserts the live state delivered across Phase 157's waves for the NJ 2026 US House
-- field. A SINGLE-STATE reduction of the validated 156-verify.sql precedent (three states) with
-- three NJ-specific wrinkles + one crucial simplification:
--
--   USHC2-03a — all 12 NJ races have >=1 active race_candidate, and the race COUNT is exactly 12
--               (no district missing). Every race asserts >=2 active EXCEPT the pinned uncontested
--               NJ-8 (geo 3408), which asserts EXACTLY 1 active (Robert Menendez only — a documented
--               single-candidate general, D-04, NOT an error).
--   USHC2-03b — 0 active race_candidates with NULL politician_id (NJ House-scoped).
--   USHC2-02a — 0 duplicate full_name among ACTIVE NJ candidates (D-03).
--   USHC2-02c — every renominated/reused NJ incumbent reuses its 154 incumbent_pid as an ACTIVE
--               House candidate (no new duplicate-incumbent record — the v2.4 two-Andy-Barrs trap).
--               NJ-1..11 (11 sitting incumbents), INCLUDING NJ-11 Analilia Mejia 93874414-... reused
--               as the special-seated incumbent. NJ-12 Watson Coleman EXCLUDED (retired, asserted
--               ABSENT below).
--   D-04-NJ12 — NJ-12 is a RETIREMENT (NOT a vacancy): Watson Coleman (a75a3e6e-... / -34012) keeps
--               her politician record + office but appears 0 times as an ACTIVE candidate; her
--               certified nominees Adam Hamawy + Gregg Mele ARE active (geo 3412). NO office/vacancy
--               is created or asserted (contrast GA-13 in 156).
--   D-04-NJ8  — NJ-8 (geo 3408) is UNCONTESTED: exactly 1 active candidate = Robert Menendez
--               (fc7a00d6-... , is_incumbent=true), 0 challengers. Documented single-candidate general.
--   D-02      — named NJ minor-line fields are seeded (party-agnostic presence): NJ-3 Steven Welzer
--               (Green) + Ryan Michael Kelly (Affordability Accountability People); NJ-5 Adam Rueda
--               (Humane Sustainable Future). No minor line dropped.
--   USHC2-04  — every newly-seeded NJ candidate (politician_id in the new-candidate external_id band
--               -341299..-340101) has an essentials.politician_images row; documented headshot
--               honest-skips pinned in _img_skip by exact external_id WITH ORDER BY external_id (143).
--   USHC2-05a — 0 unsourced stance rows for the in-scope set (every answer has a matching
--               inform.politician_context with a non-empty sources array).
--   USHC2-05b — each in-scope candidate has >=1 sourced federal stance OR is a pinned whole-record
--               honest-skip (per-topic gaps accepted; full-24 NOT required — chairs-not-polarity
--               forbids party-inference inflation; [[project-149-stance-gate-standard]]).
--
-- ============================================================================
-- NJ SINGLE-STATE SCOPING: every assertion is scoped by the NJ election id AND
--   d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2)='34'. NEVER a cross-state count.
--
-- D-01 ASYMMETRY (SIMPLER than 156 — NJ has NO zero-stance incumbent):
--   Every one of NJ's 12 incumbents is PARTIAL (stance 6-23) and LEFT AS-IS this phase. Unlike Phase
--   156 (NC-6 McDowell had stance_count 0 and WAS pulled into scope), NJ has NO zero-stance incumbent,
--   so the USHC2-05a/05b in-scope set = the new-candidate external_id band ONLY. NO incumbent pid is
--   in scope; ALL 12 NJ partial incumbents are EXCLUDED so their pre-existing partial coverage cannot
--   false-fail a 0-unsourced or coverage check. (No incumbent is UNIONed in — contrast 156.)
--   The incumbent external_id band is -34001..-34012, which is NUMERICALLY GREATER than -340101, so
--   the `<= -340101` cut cleanly separates new candidates from incumbents.
--
-- THE 143 HONEST-SKIP-ORDERING LESSON:
--   Any whole-record stance honest-skip (_stance_skip) and any headshot honest-skip (_img_skip) is
--   pinned by exact UUID / external_id WITH the query's exact ORDER BY. An ordering mismatch false-fails.
--
-- WRITE-FREE: no DELETE/UPDATE/INSERT INTO essentials|inform. The only writes are
--   CREATE TEMP TABLE ... ON COMMIT DROP (149/150/155/156-verify.sql precedent). SELECT-only.
--
-- WAVE TIMING (data-dependent assertions FAIL pre-seed, go green after):
--   157-02 AUTHORS this gate. 157-01 shipped the races scaffold -> USHC2-03 race-count passes now;
--   candidate/dedup (USHC2-02 + D-02/04) pass after 157-03; USHC2-04 after 157-04; USHC2-05 after
--   157-05. The _stance_skip + _img_skip pins are ADDED to this file by the relevant wave (150/155/156
--   model). 157-04/05 may run this gate mid-wave; 157-06 runs it as the final proof.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/157-verify.sql
--
-- NJ election: cdb3f77b-7f10-4d0a-ae79-0d8329cbd026  NJ FIPS 34 / geo 3401..3412 (3408 = uncontested).

\set ON_ERROR_STOP on

DO $$
DECLARE
  nj_eid           uuid;
  v_nj_races       int;
  v_under1         int;
  v_nj8_active     int;
  v_nonnj8_under2  int;
  v_nj8_pid        uuid;
  v_nullpid        int;
  v_dupname        int;
  v_reuse_missing  int;
  v_wc_active      int;
  v_nj12_missing   int;
  v_minor_missing  int;
  v_no_image       int;
  v_image_detail   text;
  v_unsourced      int;
  v_uncovered      int;
  v_cov_detail     text;
  menendez_pid     uuid := 'fc7a00d6-c552-4627-87f7-b0fc5cfe486c';
  watson_coleman   uuid := 'a75a3e6e-31ff-4870-8aea-501e41326fd1';
BEGIN
  SELECT id INTO nj_eid FROM essentials.elections WHERE name = 'NJ 2026 Statewide General';
  IF nj_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: NJ 2026 Statewide General election not found';
  END IF;

  -- ==========================================================================
  -- NJ House working set (every race + LEFT JOIN candidates), scoped by election +
  -- NATIONAL_LOWER + geo prefix '34'.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT r.id            AS race_id,
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
  WHERE r.election_id = nj_eid
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) = '34';

  -- Scope sanity: exactly 12 NJ House races.
  SELECT COUNT(DISTINCT race_id) INTO v_nj_races FROM _house;
  IF v_nj_races <> 12 THEN RAISE EXCEPTION 'FAIL scope: expected 12 NJ House races, got %', v_nj_races; END IF;

  -- ===== USHC2-03a — every race >=1 active; NJ-8 exactly 1; all other 11 >=2 ==========
  SELECT COUNT(*) INTO v_under1 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 1
  ) q;
  IF v_under1 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-03a: % NJ House race(s) have 0 active candidates', v_under1;
  END IF;
  -- NJ-8 (geo 3408) uncontested: exactly 1 active.
  SELECT COUNT(*) FILTER (WHERE candidate_status = 'active') INTO v_nj8_active FROM _house WHERE geo_id = '3408';
  IF v_nj8_active <> 1 THEN
    RAISE EXCEPTION 'FAIL USHC2-03a/D-04-NJ8: NJ-8 (uncontested) expected exactly 1 active candidate, got %', v_nj8_active;
  END IF;
  -- Every district EXCEPT NJ-8 has >=2 active.
  SELECT COUNT(*) INTO v_nonnj8_under2 FROM (
    SELECT race_id FROM _house WHERE geo_id <> '3408' GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 2
  ) q;
  IF v_nonnj8_under2 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-03a: % contested NJ House race(s) (excl. uncontested NJ-8) have <2 active candidates', v_nonnj8_under2;
  END IF;
  RAISE NOTICE 'PASS USHC2-03a: 12 NJ races, all >=1 active; NJ-8 uncontested (exactly 1); other 11 >=2';

  -- ===== USHC2-03b — 0 active rows with NULL politician_id =========
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-03b: % active NJ House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS USHC2-03b: 0 active NJ House candidates with NULL politician_id';

  -- ===== USHC2-02a — 0 duplicate full_name among ACTIVE NJ candidates =========
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT lower(full_name)
    FROM _house
    WHERE candidate_status = 'active'
    GROUP BY lower(full_name)
    HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-02a: % duplicate full_name(s) among active NJ candidates (D-03 / v2.4 dup-incumbent trap)', v_dupname;
  END IF;
  RAISE NOTICE 'PASS USHC2-02a: 0 duplicate full_name within NJ (D-03)';

  -- ===== USHC2-02c — renominated/reused incumbents reuse their 154 pid ==========
  -- NJ-1..11 (11 sitting incumbents, incl. NJ-11 Mejia reused as special-seated incumbent).
  -- NJ-12 Watson Coleman EXCLUDED (retired, asserted absent below).
  CREATE TEMP TABLE _reuse_pid (expected_pid uuid, who text) ON COMMIT DROP;
  INSERT INTO _reuse_pid (expected_pid, who) VALUES
    ('b74a616d-9c47-4328-8c25-b1a3dc0a4f9d','Donald Norcross NJ-1'),
    ('ac328544-b0d7-4714-8487-e2467f9713e8','Jefferson Van Drew NJ-2'),
    ('f0235587-d1e8-412d-970c-16b50b2b185f','Herbert C. Conaway Jr. NJ-3'),
    ('99022a78-79ea-417c-8a7c-0bc5f773e329','Christopher H. Smith NJ-4'),
    ('c4251d10-6fba-4a5a-b8a9-f4b2f4634f0d','Josh Gottheimer NJ-5'),
    ('332de859-029c-43ff-baa7-0113ad436d0f','Frank Pallone Jr. NJ-6'),
    ('1bc949f5-0696-481c-979b-64cfd494983a','Thomas H. Kean Jr. NJ-7'),
    ('fc7a00d6-c552-4627-87f7-b0fc5cfe486c','Robert Menendez NJ-8'),
    ('149d987d-78f6-4547-92d4-19b103a62f5e','Nellie Pou NJ-9'),
    ('c8cd097f-ce28-40b1-8236-18bc111ad868','LaMonica McIver NJ-10'),
    ('93874414-6d14-4c12-87b2-d254b3855570','Analilia Mejia NJ-11 (special-seated, reused)');

  SELECT COUNT(*) INTO v_reuse_missing
  FROM _reuse_pid rp
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.candidate_status = 'active' AND h.is_incumbent = true AND h.politician_id = rp.expected_pid
  );
  IF v_reuse_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-02c: % reused-incumbent pid(s) absent from active is_incumbent candidates (possible new duplicate-incumbent record — v2.4 trap)', v_reuse_missing;
  END IF;
  RAISE NOTICE 'PASS USHC2-02c: all 11 pinned renominated NJ incumbents reuse their 154 pid (incl. NJ-11 Mejia)';

  -- ===== D-04-NJ12 — retired Watson Coleman ABSENT; Hamawy + Mele PRESENT (retirement, NOT vacancy) =====
  SELECT COUNT(*) INTO v_wc_active
  FROM _house h
  WHERE h.candidate_status = 'active' AND h.politician_id = watson_coleman;
  IF v_wc_active <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04-NJ12: retired NJ-12 incumbent Watson Coleman surfaced as ACTIVE candidate (% rows)', v_wc_active;
  END IF;
  SELECT COUNT(*) INTO v_nj12_missing
  FROM (VALUES ('Adam Hamawy'), ('Gregg Mele')) AS n(who)
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.geo_id = '3412'
      AND h.candidate_status = 'active' AND h.politician_id IS NOT NULL
      AND lower(h.full_name) = lower(n.who)
  );
  IF v_nj12_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04-NJ12: % NJ-12 open-seat nominee(s) (Hamawy/Mele) absent from the active field', v_nj12_missing;
  END IF;
  RAISE NOTICE 'PASS D-04-NJ12: Watson Coleman absent (retired); Hamawy + Mele active (retirement, no vacancy/office)';

  -- ===== D-04-NJ8 — uncontested: the single active NJ-8 candidate is Menendez, is_incumbent=true =====
  SELECT politician_id INTO v_nj8_pid FROM _house
  WHERE geo_id = '3408' AND candidate_status = 'active';
  IF v_nj8_pid IS DISTINCT FROM menendez_pid THEN
    RAISE EXCEPTION 'FAIL D-04-NJ8: the single active NJ-8 candidate is not Menendez (got pid %)', v_nj8_pid;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM _house WHERE geo_id = '3408' AND candidate_status = 'active' AND is_incumbent = true) THEN
    RAISE EXCEPTION 'FAIL D-04-NJ8: NJ-8 Menendez not flagged is_incumbent=true';
  END IF;
  RAISE NOTICE 'PASS D-04-NJ8: NJ-8 uncontested — Menendez only, is_incumbent=true (documented single-candidate general)';

  -- ===== D-02 — NJ minor-line fields seeded (party-agnostic presence) ==
  CREATE TEMP TABLE _minor (geo_id text, who text) ON COMMIT DROP;
  INSERT INTO _minor (geo_id, who) VALUES
    ('3403','Steven Welzer'),        -- NJ-3 Green
    ('3403','Ryan Michael Kelly'),   -- NJ-3 Affordability Accountability People
    ('3405','Adam Rueda');           -- NJ-5 Humane Sustainable Future
  SELECT COUNT(*) INTO v_minor_missing
  FROM _minor m
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.geo_id = m.geo_id
      AND h.candidate_status = 'active' AND lower(h.full_name) = lower(m.who)
  );
  IF v_minor_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-02: % NJ minor-line candidate(s) (NJ-3 Welzer/Kelly, NJ-5 Rueda) not seeded as active', v_minor_missing;
  END IF;
  RAISE NOTICE 'PASS D-02: NJ-3 Welzer + Kelly + NJ-5 Rueda seeded as active (minor lines not dropped)';

  -- ==========================================================================
  -- In-scope STANCE/HEADSHOT set (D-01 — NJ has NO zero-stance incumbent, so the in-scope set is
  -- the new-candidate external_id band ONLY; NO incumbent pid is UNIONed in).
  --   _new_cands = newly-seeded NJ candidates (external_id band -341299..-340101).
  -- USHC2-04/05 data is populated by later waves; these assertions FAIL pre-seed (expected).
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.politician_id
  FROM _house h
  JOIN essentials.politicians p ON p.id = h.politician_id
  WHERE h.candidate_status = 'active'
    AND p.external_id BETWEEN -341299 AND -340101;

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
  -- politician_id (143 lesson). POPULATED-BY-157-05: thin/no-source minor & first-time challengers
  -- whose primary sources are dead/JS-walled; party-inference refused (chairs-not-polarity).
  CREATE TEMP TABLE _stance_skip (politician_id uuid, reason text) ON COMMIT DROP;
  -- (populated by 157-05)

  -- Headshot honest-skip set (no free-license portrait anywhere). Pinned by exact external_id WITH
  -- ORDER BY external_id (143 lesson). POPULATED-BY-157-04 (NJ headshot pass).
  CREATE TEMP TABLE _img_skip (external_id bigint, reason text) ON COMMIT DROP;
  -- (populated by 157-04)

  -- ===== USHC2-04 — every newly-seeded NJ candidate has a politician_images row ====
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
    RAISE EXCEPTION 'FAIL USHC2-04 (Wave 3): % newly-seeded NJ candidate(s) lack a politician_images row: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS USHC2-04: every newly-seeded NJ candidate has a politician_images row';

  -- ===== USHC2-05a — 0 unsourced stance rows for the in-scope set (Wave 3) =====
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers a
  JOIN _new_cands s ON s.politician_id = a.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id
      AND c.topic_id = a.topic_id
      AND c.sources IS NOT NULL
      AND array_length(c.sources, 1) >= 1
  );
  IF v_unsourced <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-05a (Wave 3): % unsourced stance row(s) in the in-scope NJ candidate set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS USHC2-05a: 0 unsourced stance rows for the in-scope NJ candidate set';

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
    FROM _new_cands s
    LEFT JOIN essentials.politicians p ON p.id = s.politician_id
    WHERE s.politician_id NOT IN (SELECT politician_id FROM _stance_skip)
  ) x
  WHERE x.fed_count < 1;
  IF v_uncovered <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-05b: % in-scope candidate(s) have 0 federal stances and are not pinned as whole-record honest-skip: %', v_uncovered, v_cov_detail;
  END IF;
  RAISE NOTICE 'PASS USHC2-05b: every in-scope NJ candidate has >=1 sourced federal stance or is a pinned whole-record honest-skip';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC2-02/03/04/05 + D-01/02/03/04)';
END $$;
