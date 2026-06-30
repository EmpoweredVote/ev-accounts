-- 151-verify.sql — Phase 151 read-only production gate (USHC-02/03/04/05 + D-01..D-05).
--
-- SELECT-only. Asserts the live state delivered across Phase 151's waves for the FL 2026 US House
-- PROVISIONAL (pre-Aug-18-primary) field. Single-state adaptation of the validated 150-verify.sql.
--
-- ============================================================================
-- SINGLE-STATE SCOPING:
--   Every assertion is scoped by the FL 2026 Statewide General election id AND
--   d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2)='12'. 28 FL House races.
--
-- D-01 ASYMMETRY (the NY-partial false-fail trap, FL edition):
--   FL's 27 incumbents are ALL partial-stance (none zero); by the zero-only top-up rule they are
--   LEFT AS-IS this phase and are NOT in the stance/headshot in-scope set. Per the records-now/
--   stances-at-153 decision (CONTEXT D-01), the ~138 PARTISAN (R/D) new candidates get records ONLY
--   now — their headshots+stances defer to Phase 153. The stance/headshot in-scope set is EXACTLY
--   the 17 INDEPENDENT/NPA new candidates (Nov-final, not pruned by the primary). USHC-04/05 are
--   scoped to `_indep_scope` ONLY; the 27 incumbents + 138 partisan new candidates are EXCLUDED so
--   their (intentionally) absent coverage cannot false-fail.
--
-- NO PER-PARTY CAP (D-02): FL is pre-primary CROWDED — FL-19 has 11 Republicans, FL-2 has 12, FL-24
--   has 10, all by design. There is NO one-D-one-R / <=2 upper-bound assertion. USHC-03a uses a >=1
--   hard floor (FL-10 Frost is uncontested → incumbent-only); a NOTICE reports <2 (not a failure).
--
-- THE 143 HONEST-SKIP-ORDERING LESSON:
--   Any whole-record stance/headshot honest-skip is pinned by exact UUID/external_id WITH the query's
--   exact ORDER BY. An ordering mismatch false-fails.
--
-- DEDUP (D-03): only 3 reuse targets, matched by EXACT external_id (NOT name substring — FEC committee
--   noise rows like "FRANKEL 4 PV SCHOOLS" exist). Sheila Cherfilus-McCormick is a NEW record (0 prior
--   DB rows — RESEARCH Pitfall 3), NOT a reuse.
--
-- WRITE-FREE: only CREATE TEMP TABLE ... ON COMMIT DROP. SELECT-only otherwise.
--
-- WAVE TIMING (data-dependent assertions FAIL pre-seed, go green after):
--   151-01 ships the scaffold → USHC-03 race-count + D-04 provisional + FL-20-office pass now.
--   USHC-02/D-05 pass after 151-03; USHC-04 after 151-04; USHC-05 after 151-05. _stance_skip /
--   _headshot_skip pins are ADDED by the relevant wave (the 149/150 model).
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/151-verify.sql

\set ON_ERROR_STOP on

DO $$
DECLARE
  fl_eid          uuid;
  fl20_office     uuid;
  v_races         int;
  v_under1        int;
  v_under2        int;
  v_nullpid       int;
  v_fl20_office_n int;
  v_fl20_nullpid  int;
  v_fl20_race_off int;
  v_prov          int;
  v_dupname       int;
  v_reuse_missing int;
  v_cherf         int;
  v_lost_active   int;
  v_no_image      int;
  v_image_detail  text;
  v_unsourced     int;
  v_uncovered     int;
  v_cov_detail    text;
  v_indep_n       int;
BEGIN
  SELECT id INTO fl_eid FROM essentials.elections WHERE name = 'FL 2026 Statewide General';
  IF fl_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: FL 2026 Statewide General election not found';
  END IF;

  -- ==========================================================================
  -- FL House working set (every race + LEFT JOIN candidates), scoped by election
  -- + NATIONAL_LOWER + geo prefix '12'.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT r.id            AS race_id,
         d.geo_id        AS geo_id,
         r.description    AS race_desc,
         rc.id           AS rc_id,
         rc.politician_id,
         rc.full_name,
         rc.candidate_status,
         rc.is_incumbent,
         p.external_id
  FROM essentials.races r
  JOIN essentials.offices o     ON o.id = r.office_id
  JOIN essentials.districts d   ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE r.election_id = fl_eid
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) = '12';

  -- ===== USHC-03a — exactly 28 FL House races; each has >=1 active candidate ====
  SELECT COUNT(DISTINCT race_id) INTO v_races FROM _house;
  IF v_races <> 28 THEN RAISE EXCEPTION 'FAIL USHC-03a scope: expected 28 FL House races, got %', v_races; END IF;
  SELECT COUNT(*) INTO v_under1 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 1
  ) q;
  IF v_under1 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-03a: % FL House race(s) have 0 active candidates', v_under1;
  END IF;
  SELECT COUNT(*) INTO v_under2 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 2
  ) q;
  RAISE NOTICE 'PASS USHC-03a: all 28 FL House races have >=1 active candidate (% race(s) have <2 — uncontested-seat allowance, e.g. FL-10 Frost)', v_under2;

  -- ===== USHC-03b — 0 active rows with NULL politician_id =====
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-03b: % active FL House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS USHC-03b: 0 active FL House candidates with NULL politician_id';

  -- ===== USHC-03c — FL-20 vacant-seat office present (NULL pid) + its race links ====
  SELECT o.id INTO fl20_office
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '1220' AND d.district_type = 'NATIONAL_LOWER'
    AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = 'U.S. House of Representatives');
  IF fl20_office IS NULL THEN RAISE EXCEPTION 'FAIL USHC-03c: FL-20 (geo 1220) U.S. House office not found'; END IF;
  SELECT COUNT(*) INTO v_fl20_nullpid FROM essentials.offices WHERE id = fl20_office AND politician_id IS NULL;
  IF v_fl20_nullpid <> 1 THEN RAISE EXCEPTION 'FAIL USHC-03c: FL-20 office politician_id is not NULL (expected vacant)'; END IF;
  SELECT COUNT(*) INTO v_fl20_race_off
  FROM essentials.races r WHERE r.election_id = fl_eid AND r.office_id = fl20_office;
  IF v_fl20_race_off <> 1 THEN RAISE EXCEPTION 'FAIL USHC-03c: FL-20 office does not carry exactly 1 race (got %)', v_fl20_race_off; END IF;
  RAISE NOTICE 'PASS USHC-03c: FL-20 vacant office present (NULL pid), its race links (office_id non-null)';

  -- ===== D-04 — all 28 FL House races marked PROVISIONAL =====
  SELECT COUNT(DISTINCT race_id) INTO v_prov FROM _house WHERE race_desc LIKE 'PROVISIONAL:%';
  IF v_prov <> 28 THEN
    RAISE EXCEPTION 'FAIL D-04: only %/28 FL House races carry the PROVISIONAL description sentinel', v_prov;
  END IF;
  RAISE NOTICE 'PASS D-04: all 28 FL House races marked PROVISIONAL';

  -- ===== USHC-02a — 0 duplicate full_name among ACTIVE FL candidates =====
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT lower(full_name)
    FROM _house
    WHERE candidate_status = 'active'
    GROUP BY lower(full_name)
    HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-02a: % duplicate full_name(s) among active FL candidates (D-03 / dup-incumbent trap)', v_dupname;
  END IF;
  RAISE NOTICE 'PASS USHC-02a: 0 duplicate full_name among active FL candidates (D-03)';

  -- ===== USHC-02b — the 3 cross-district reuse incumbents active in their NEW seat =====
  -- Matched by EXACT external_id (Pitfall 2 FEC-noise guard). Frankel FL-23, Moskowitz FL-25,
  -- Wasserman Schultz FL-20. (Their OLD seats are checked absent in D-05.)
  CREATE TEMP TABLE _reuse_pid (geo_id text, expected_pid uuid, external_id int, who text) ON COMMIT DROP;
  INSERT INTO _reuse_pid (geo_id, expected_pid, external_id, who) VALUES
    ('1223','b4040115-b3ea-4500-89cf-1ddaecafc94e',-12022,'Lois Frankel (-12022) active FL-23'),
    ('1225','1cb8827c-6ae0-4fcf-884c-94ad2246f15d',-12023,'Jared Moskowitz (-12023) active FL-25'),
    ('1220','097623b0-3063-4943-a13c-89d213ca5829',-12025,'Debbie Wasserman Schultz (-12025) active FL-20')
  ORDER BY external_id;
  SELECT COUNT(*) INTO v_reuse_missing
  FROM _reuse_pid rp
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.geo_id = rp.geo_id AND h.candidate_status = 'active' AND h.politician_id = rp.expected_pid
  );
  IF v_reuse_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-02b: % reuse incumbent pid(s) absent from their NEW-district active field', v_reuse_missing;
  END IF;
  RAISE NOTICE 'PASS USHC-02b: all 3 cross-district reuse incumbents (Frankel/Moskowitz/Wasserman Schultz) active in their new seat';

  -- ===== USHC-02c — Cherfilus-McCormick is a NEW FL-20 active candidate (NOT a reuse) =====
  SELECT COUNT(*) INTO v_cherf
  FROM _house h
  WHERE h.geo_id = '1220' AND h.candidate_status = 'active'
    AND lower(h.full_name) = lower('Sheila Cherfilus-McCormick')
    AND h.external_id BETWEEN -1229999 AND -1210000;
  IF v_cherf <> 1 THEN
    RAISE EXCEPTION 'FAIL USHC-02c: Sheila Cherfilus-McCormick not present as exactly 1 NEW-band active FL-20 candidate (got %)', v_cherf;
  END IF;
  RAISE NOTICE 'PASS USHC-02c: Cherfilus-McCormick active in FL-20 as a NEW record (Pitfall 3)';

  -- ===== D-05 — retired/redistricted incumbents ABSENT in the seat they LEFT =====
  -- Retired: FL-2 Dunn -12002, FL-16 Buchanan -12016, FL-19 Donalds -12019, FL-24 Wilson -12024.
  -- Redistricted (absent in OLD seat; present in NEW per USHC-02b): FL-22 Frankel -12022,
  -- FL-23 Moskowitz -12023, FL-25 Wasserman Schultz -12025. FL-20 had no incumbent (vacant).
  CREATE TEMP TABLE _lost (old_geo text, external_id int, who text) ON COMMIT DROP;
  INSERT INTO _lost (old_geo, external_id, who) VALUES
    ('1202',-12002,'Neal Dunn (retired)'),
    ('1216',-12016,'Vern Buchanan (retired)'),
    ('1219',-12019,'Byron Donalds (retired)'),
    ('1222',-12022,'Lois Frankel (redistricted FL-22->FL-23)'),
    ('1223',-12023,'Jared Moskowitz (redistricted FL-23->FL-25)'),
    ('1224',-12024,'Frederica Wilson (retired)'),
    ('1225',-12025,'Debbie Wasserman Schultz (redistricted FL-25->FL-20)')
  ORDER BY external_id;
  SELECT COUNT(*) INTO v_lost_active
  FROM _lost l
  JOIN _house h ON h.geo_id = l.old_geo AND h.candidate_status = 'active' AND h.external_id = l.external_id;
  IF v_lost_active <> 0 THEN
    RAISE EXCEPTION 'FAIL D-05: % retired/redistricted incumbent(s) still active in the seat they LEFT', v_lost_active;
  END IF;
  RAISE NOTICE 'PASS D-05: retired/redistricted incumbents (Dunn/Buchanan/Donalds/Wilson/Frankel/Moskowitz/Wasserman Schultz) absent in their old seat';

  -- ==========================================================================
  -- STANCE/HEADSHOT in-scope set = the 17 INDEPENDENT/NPA new candidates ONLY (D-01).
  -- Pinned by (geo_id, full_name) from the 148 field; resolved to pid via active FL candidates.
  -- ==========================================================================
  CREATE TEMP TABLE _indep_scope ON COMMIT DROP AS
  SELECT v.geo_id, v.full_name,
         (SELECT h.politician_id FROM _house h
           WHERE h.geo_id = v.geo_id AND h.candidate_status = 'active'
             AND lower(h.full_name) = lower(v.full_name)
             AND h.external_id BETWEEN -1229999 AND -1210000
           LIMIT 1) AS politician_id
  FROM (VALUES
    ('1201','Tyler Davis'),
    ('1203','Mike Klein'),
    ('1204','Todd Schaefer'),
    ('1206','Andrew Parrott'),
    ('1206','Alec Pavlik'),
    ('1212','Branden Scrivener'),
    ('1213','Tony D''Arrigo'),
    ('1216','Mark Davis'),
    ('1217','Michael Quirk'),
    ('1218','Deva Simmons'),
    ('1219','Seth Haskins'),
    ('1220','Kedner MaximeDe'),
    ('1221','Alexander Cooke'),
    ('1224','Andy Daro'),
    ('1224','Patricia Gonzalez'),
    ('1226','Deborah Ann Meidinger Hosey'),
    ('1228','Eddy Rojas')
  ) AS v(geo_id, full_name);
  SELECT COUNT(*) FILTER (WHERE politician_id IS NULL) INTO v_indep_n FROM _indep_scope;
  IF v_indep_n <> 0 THEN
    RAISE EXCEPTION 'FAIL in-scope: % of the 17 independent/NPA candidates did not resolve to a NEW-band active FL candidate (name/seed mismatch)', v_indep_n;
  END IF;
  RAISE NOTICE 'PASS in-scope: all 17 independent/NPA new candidates resolved (the USHC-04/05 in-scope set)';

  -- Federal-24 topic_ids.
  CREATE TEMP TABLE _fed24 ON COMMIT DROP AS
  SELECT id AS topic_id FROM inform.compass_topics
  WHERE topic_key IN (
    'abortion','ai-regulation','campaign-finance','childcare','civil-rights',
    'climate-change','deportation','fossil-fuels','healthcare','homelessness',
    'housing','immigration','medicare/aid','misinformation','redistricting',
    'religious-freedom','same-sex-marriage','school-vouchers','social-security',
    'tariffs','taxes','trans-athletes','voting-rights','ukraine-support');

  -- Whole-record honest-skip sets (POPULATED-BY-151-04 / 151-05). Pinned by exact UUID w/ ORDER BY.
  CREATE TEMP TABLE _stance_skip (politician_id uuid, reason text) ON COMMIT DROP;
  CREATE TEMP TABLE _headshot_skip (external_id int, reason text) ON COMMIT DROP;
  -- (empty placeholders; W3 plans INSERT their documented skips here with explicit ORDER BY)

  -- ===== USHC-04 — every in-scope independent has a politician_images row (or pinned skip) ====
  SELECT COUNT(*),
         string_agg(s.full_name || ' (' || COALESCE(p.external_id::text,'?') || ')', ', ' ORDER BY p.external_id)
    INTO v_no_image, v_image_detail
  FROM _indep_scope s
  JOIN essentials.politicians p ON p.id = s.politician_id
  WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = s.politician_id)
    AND p.external_id NOT IN (SELECT external_id FROM _headshot_skip);
  IF v_no_image <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-04: % in-scope independent(s) lack a politician_images row and are not pinned: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS USHC-04: every in-scope independent has a headshot or a pinned honest-skip';

  -- ===== USHC-05a — 0 unsourced stance rows for the in-scope independents ONLY ====
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers a
  JOIN _indep_scope s ON s.politician_id = a.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
      AND c.sources IS NOT NULL AND array_length(c.sources, 1) >= 1
  );
  IF v_unsourced <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-05a: % unsourced stance row(s) in the in-scope independent set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS USHC-05a: 0 unsourced stance rows for the 17 in-scope independents';

  -- ===== USHC-05b — each in-scope independent has >=1 sourced federal stance OR pinned skip ====
  SELECT COUNT(*),
         string_agg(x.full_name, ', ' ORDER BY x.politician_id)
    INTO v_uncovered, v_cov_detail
  FROM (
    SELECT s.politician_id, s.full_name,
           (SELECT COUNT(*) FROM inform.politician_answers a
              JOIN _fed24 f ON f.topic_id = a.topic_id
             WHERE a.politician_id = s.politician_id) AS fed_count
    FROM _indep_scope s
    WHERE s.politician_id NOT IN (SELECT politician_id FROM _stance_skip)
  ) x
  WHERE x.fed_count < 1;
  IF v_uncovered <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-05b: % in-scope independent(s) have 0 federal stances and are not pinned whole-record skips: %', v_uncovered, v_cov_detail;
  END IF;
  RAISE NOTICE 'PASS USHC-05b: every in-scope independent has >=1 sourced federal stance or is a pinned whole-record honest-skip';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC-02/03/04/05 + D-01/02/03/04/05)';
END $$;
