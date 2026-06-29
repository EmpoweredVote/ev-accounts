-- 149-verify.sql — Phase 149 read-only production gate (USHC-02/03/04/05 + D-04).
--
-- SELECT-only. Asserts the live state delivered across Phase 149's waves for the
-- CA 2026 US House field:
--   USHC-03a — all 52 CA House races have >= 2 ACTIVE race_candidates.
--   USHC-03b — 0 ACTIVE race_candidates with NULL politician_id (House-scoped).
--   USHC-02a — 0 duplicate full_name among ACTIVE CA House candidates.
--   USHC-02b — Raul Ruiz CA-25 dedup: canonical pid wired active; dup retired.
--   USHC-02c — every renominated/home-running incumbent reuses its 148 pid
--              (the reused incumbent pid appears as an ACTIVE CA House candidate;
--              no new duplicate-incumbent record — the v2.4 two-Andy-Barrs trap).
--   D-04     — each of the 9 same-party-general districts (CA-4/7/11/12/14/29/34/37/40)
--              carries BOTH named advancers as ACTIVE candidates.
--   USHC-04  — every newly-seeded CA candidate (politician_id in the -601xxxx
--              new-candidate band from 149-01) has an essentials.politician_images row.
--   USHC-05a — 0 unsourced stance rows for the in-scope CA candidate set
--              (every inform.politician_answers row has a matching
--               inform.politician_context with a non-empty sources array).
--   USHC-05b — per in-scope candidate, federal-24 stance coverage OR a pinned
--              whole-record honest-skip (pinned by UUID with explicit ORDER BY).
--
-- ============================================================================
-- THE 52-vs-53 TRAP (RESEARCH §Pitfall 1 — the single biggest gate trap):
--   The "CA 2026 Statewide General" election (728d0074-...) contains 53 races.
--   The 53rd is GOVERNOR, which already carries ~76 pre-existing candidates
--   (quick-016/023 leftovers). EVERY assertion below is therefore House-scoped
--   via the join chain races -> offices -> districts, filtered
--   `d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id,1,2)='06'`
--   within election 728d0074. NEVER write an election-wide count — it false-fails.
--
-- THE 143 HONEST-SKIP-ORDERING LESSON:
--   Any whole-record stance honest-skip MUST be pinned by exact UUID with the
--   query's EXACT `ORDER BY`. An ordering mismatch between the expected literal
--   and the live `ORDER BY` false-fails. The skip set + its ORDER BY are pinned
--   together in the _skip TEMP table below.
--
-- WRITE-FREE: no DELETE/UPDATE/INSERT INTO essentials|inform. The only writes
--   are `CREATE TEMP TABLE ... ON COMMIT DROP` for diffing (148-verify.sql
--   precedent). SELECT-only against production; never `--commit`.
--
-- WAVE TIMING (documented expectation):
--   149-02 only AUTHORS this gate. 149-01 already shipped records + wiring, so
--   USHC-02/03 + D-04 PASS now. USHC-04 (headshots, Wave 2) and USHC-05
--   (stances, Wave 3) assertions are authored now so the final gate (149-11) is
--   complete; they legitimately FAIL pre-Wave-2/3 and go green only after those
--   waves run. 149-04..10 may run this gate mid-wave to verify their slice.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/149-verify.sql
--
-- CA general election id prefix: 728d0074-...   CA FIPS: 06.
-- Join path: races.office_id -> offices.id, offices.district_id -> districts.id.

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_eid          uuid;
  v_races        int;
  v_under2       int;
  v_nullpid      int;
  v_dupname      int;
  v_ruiz_active  int;
  v_ruiz_dup     int;
  v_reuse_missing int;
  v_d04_missing  int;
  v_d04_detail   text;
  v_no_image     int;
  v_image_detail text;
  v_unsourced    int;
  v_uncovered    int;
  v_cov_detail   text;
BEGIN
  -- Resolve the CA 2026 Statewide General election id.
  SELECT id INTO v_eid
  FROM essentials.elections
  WHERE id::text LIKE '728d0074%';
  IF v_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: CA 2026 Statewide General election (728d0074-...) not found';
  END IF;

  -- ==========================================================================
  -- House-scoped working set: every ACTIVE race_candidate on the 52 CA House
  -- races in election 728d0074. Governor (53rd race) is excluded by the
  -- NATIONAL_LOWER + geo_id '06' filter (Pitfall 1).
  -- ==========================================================================
  CREATE TEMP TABLE _ca_house ON COMMIT DROP AS
  SELECT r.id            AS race_id,
         d.geo_id        AS geo_id,
         rc.id           AS rc_id,
         rc.politician_id,
         rc.full_name,
         rc.candidate_status
  FROM essentials.races r
  JOIN essentials.offices o     ON o.id = r.office_id
  JOIN essentials.districts d   ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  WHERE r.election_id = v_eid
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) = '06';

  -- Sanity: exactly 52 distinct CA House races (the 53rd Gov race must be absent).
  SELECT COUNT(DISTINCT race_id) INTO v_races FROM _ca_house;
  IF v_races <> 52 THEN
    RAISE EXCEPTION 'FAIL scope: expected 52 CA House races in 728d0074, got % (53rd Gov race must be excluded by NATIONAL_LOWER/geo06)', v_races;
  END IF;

  -- ===== USHC-03a — every CA House race has >= 2 ACTIVE candidates ===========
  SELECT COUNT(*) INTO v_under2
  FROM (
    SELECT race_id
    FROM _ca_house
    WHERE candidate_status = 'active'
    GROUP BY race_id
    HAVING COUNT(*) < 2
  ) q;
  IF v_under2 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-03a: % CA House race(s) have < 2 active candidates', v_under2;
  END IF;
  RAISE NOTICE 'PASS USHC-03a: all 52 CA House races have >= 2 active candidates';

  -- ===== USHC-03b — 0 active rows with NULL politician_id (House-scoped) ======
  SELECT COUNT(*) INTO v_nullpid
  FROM _ca_house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-03b: % active CA House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS USHC-03b: 0 active CA House candidates with NULL politician_id';

  -- ===== USHC-02a — 0 duplicate full_name among ACTIVE CA House candidates ====
  SELECT COUNT(*) INTO v_dupname
  FROM (
    SELECT lower(full_name)
    FROM _ca_house
    WHERE candidate_status = 'active'
    GROUP BY lower(full_name)
    HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-02a: % duplicate full_name(s) among active CA House candidates (v2.4 dup-incumbent trap)', v_dupname;
  END IF;
  RAISE NOTICE 'PASS USHC-02a: 0 duplicate full_name among active CA House candidates';

  -- ===== USHC-02b — Raul Ruiz CA-25 dedup ====================================
  -- Canonical 5238b298 wired active to CA-25 (geo_id 0625); dup 05349fa0 retired.
  SELECT COUNT(*) INTO v_ruiz_active
  FROM _ca_house
  WHERE geo_id = '0625'
    AND candidate_status = 'active'
    AND politician_id = '5238b298-6004-4bcc-94c2-ee43a9c2999e';
  IF v_ruiz_active <> 1 THEN
    RAISE EXCEPTION 'FAIL USHC-02b: expected exactly 1 active CA-25 Ruiz on canonical pid 5238b298, got %', v_ruiz_active;
  END IF;
  SELECT COUNT(*) INTO v_ruiz_dup
  FROM essentials.politicians p
  WHERE p.id::text LIKE '05349fa0%' AND p.is_active = true;
  IF v_ruiz_dup <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-02b: Ruiz duplicate (05349fa0-...) is still is_active=true (% rows)', v_ruiz_dup;
  END IF;
  RAISE NOTICE 'PASS USHC-02b: Ruiz CA-25 canonical 5238b298 wired active; duplicate 05349fa0 retired';

  -- ===== USHC-02c — renominated/home incumbents reuse their 148 pid ==========
  -- A new duplicate-incumbent record (v2.4 two-Andy-Barrs) would mean the 148
  -- incumbent_pid is NOT among the active CA House candidates. Pin every reused
  -- incumbent pid (from 148-field-table.csv) that runs as a 2026 CA candidate;
  -- assert each appears as an ACTIVE CA House race_candidate.
  -- Excludes: CA-1 LaMalfa (deceased, not running), and retired incumbents whose
  -- seats have all-new fields (CA-11 Pelosi / CA-14 Swalwell / CA-26 Brownley /
  -- CA-48 Issa). All others (renominated + redistricted-home runners) reuse pid.
  CREATE TEMP TABLE _reuse_pid (geo_id text, expected_pid uuid, who text) ON COMMIT DROP;
  INSERT INTO _reuse_pid (geo_id, expected_pid, who) VALUES
    ('0602','960e5acd-c847-4c8b-9a00-980483647849','Jared Huffman'),
    ('0603','0d635e23-f206-44fc-bac1-e309b932a081','Ami Bera (redistricted CA-6 pid, runs CA-3)'),
    ('0604','4466bd8c-8dba-4f2e-9471-c06d8429a779','Mike Thompson'),
    ('0605','f7704cd1-eec4-40d8-b44f-429b4f9c8611','Tom McClintock'),
    ('0606','645a79be-ad06-461f-b2d6-3f811a0c48ee','Kevin Kiley (redistricted CA-3 pid, runs CA-6 Ind)'),
    ('0607','5be0c642-33b3-4ea4-8bb1-2eb25df2b4ef','Doris Matsui'),
    ('0608','28eeeb86-5ec1-48dd-86a7-9cf6d7771949','John Garamendi'),
    ('0609','3ab13c27-f66e-486f-b3d4-87ddb927c35f','Josh Harder'),
    ('0610','bc29096f-63ce-41f7-8d51-c4e6cfa87f8c','Mark DeSaulnier'),
    ('0612','39db6eee-ccf5-4901-90a0-1c2580731b0e','Lateefah Simon'),
    ('0613','1b473093-b86b-4b39-990b-19859d163080','Adam Gray'),
    ('0615','9c880377-7e1f-4994-91b3-82d9cb15bbb4','Kevin Mullin'),
    ('0616','7ceb0371-baba-4d05-9204-2852cc91dee0','Sam Liccardo'),
    ('0617','07255876-bbe6-4f6a-8c68-75939d9b5128','Ro Khanna'),
    ('0618','956281d7-e27e-43cc-84e9-244879ed5ecf','Zoe Lofgren'),
    ('0619','29a4c8f8-67a4-45a1-b4e8-ea708523cf3f','Jimmy Panetta'),
    ('0620','e228243c-4d7c-4a61-87c9-2e3f7a9d6afd','Vince Fong'),
    ('0621','196e8502-0aab-49a8-a6a0-6626bf121f34','Jim Costa'),
    ('0622','42bff283-c977-43f1-9d54-a06131dc5eac','David Valadao'),
    ('0623','18db5d61-6bce-4f55-ad45-bed01f329548','Jay Obernolte'),
    ('0624','565438e0-04f1-4d2d-87cf-44df42ac1173','Salud Carbajal'),
    ('0625','5238b298-6004-4bcc-94c2-ee43a9c2999e','Raul Ruiz (canonical)'),
    ('0627','c2f8656e-f73a-42ec-996e-87fceedf0389','George Whitesides'),
    ('0628','d75dfa60-351b-4f0d-880a-45acf013c82a','Judy Chu'),
    ('0629','a1fc524b-7c90-43c0-83a7-c76664293913','Luz Maria Rivas'),
    ('0630','e099da71-f9d9-445d-96d9-179952bd539c','Laura Friedman'),
    ('0631','be2943b7-f634-42f4-8ab8-15db8138169f','Gil Cisneros'),
    ('0632','96c77e2b-df35-4d56-a573-8bc0c15a142d','Brad Sherman'),
    ('0633','822966a7-5f09-4151-ba43-630afbd676c2','Pete Aguilar'),
    ('0634','99d93781-7c5f-492c-b959-ee502ca05c29','Jimmy Gomez'),
    ('0635','e4d5cd69-0a54-48d6-9d8c-11da8f091cb6','Norma Torres'),
    ('0636','3a39c313-b994-447b-b3fd-592e4994769b','Ted W. Lieu'),
    ('0637','a2c6adc7-7689-49b9-964f-8f2aeb243a83','Sydney Kamlager-Dove'),
    ('0639','0af35a49-9908-474a-a3b6-f0f0ad1e85a0','Mark Takano'),
    ('0640','504a0b06-6729-4fc5-93cd-7c43b1e153fe','Young Kim (home CA-40)'),
    ('0640','97b8516d-37a6-46e5-8030-60ac927ced4f','Ken Calvert (redistricted CA-41 pid, runs CA-40)'),
    -- NOTE: Linda Sánchez (CA-38 incumbent bb73793e, redistricted to run CA-41) was
    -- seeded by 149-01 as a NEW record (-6014101), NOT a pid reuse — unlike Bera/
    -- Kiley/Calvert. She is therefore NOT in the reuse set; CA-38 incumbent pid
    -- bb73793e correctly carries no 2026 candidacy (Hilda Solis is the new CA-38 nominee).
    ('0642','28a5f098-7f90-4fa9-af7e-c034d49cb538','Robert Garcia'),
    ('0643','203ab943-324d-4478-9093-d827d5d9c7da','Maxine Waters'),
    ('0644','5bd54ac0-c8b9-486c-844c-ecc4313e5de7','Nanette Diaz Baragan'),
    ('0645','b7612f49-c914-4ea7-a6da-559d71f313c2','Derek Tran'),
    ('0646','c06165d2-008c-4fe3-93cd-e31fbd6e377f','Lou Correa'),
    ('0647','59b9f70a-b67d-4ff9-a99a-829442300178','Dave Min'),
    ('0649','821be1ee-ba55-4f47-9e5f-7a39f8514271','Mike Levin'),
    ('0650','3a9072fc-cb5c-4435-ad77-86562481830f','Scott Peters'),
    ('0651','51e4c723-299f-46a6-b1b2-f75386ee64f0','Sara Jacobs'),
    ('0652','afa3cab9-4caf-4df3-a9ce-f739cc12b89d','Juan Vargas');

  -- Each reused incumbent pid must appear as an ACTIVE CA House candidate
  -- (no new duplicate-incumbent row). We assert presence anywhere in the 52
  -- House races (redistricted runners appear in their NEW district).
  SELECT COUNT(*) INTO v_reuse_missing
  FROM _reuse_pid rp
  WHERE NOT EXISTS (
    SELECT 1 FROM _ca_house h
    WHERE h.candidate_status = 'active' AND h.politician_id = rp.expected_pid
  );
  IF v_reuse_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-02c: % reused-incumbent pid(s) absent from active CA House candidates (possible new duplicate-incumbent record — v2.4 trap)', v_reuse_missing;
  END IF;
  RAISE NOTICE 'PASS USHC-02c: all % renominated/redistricted-home incumbents reuse their 148 pid (no new dup record)', (SELECT COUNT(*) FROM _reuse_pid);

  -- ===== D-04 — both same-party advancers present in the 9 districts =========
  -- CA-4/7/11/12/14/29/34/37/40 (148-FIELD-TABLE.md §CA same-party generals).
  -- Pin each district to its two named advancers (party-agnostic, read from
  -- results). Assert each name is an ACTIVE candidate in that district.
  CREATE TEMP TABLE _d04 (geo_id text, advancer text) ON COMMIT DROP;
  INSERT INTO _d04 (geo_id, advancer) VALUES
    ('0604','Mike Thompson'),      ('0604','Eric Jones'),
    ('0607','Doris Matsui'),       ('0607','Mai Vang'),
    ('0611','Connie Chan'),        ('0611','Scott Wiener'),
    ('0612','Lateefah Simon'),     ('0612','Jamie Joyce'),
    ('0614','Melissa Hernandez'),  ('0614','Aisha Wahab'),
    ('0629','Luz Rivas'),          ('0629','Angélica María Dueñas'),
    ('0634','Jimmy Gomez'),        ('0634','Angela Gonzales-Torres'),
    ('0637','Sydney Kamlager-Dove'),('0637','Samantha Mota'),
    ('0640','Ken Calvert'),        ('0640','Young Kim');

  -- Match by case-insensitive full_name within the district's active candidates.
  SELECT COUNT(*), string_agg(geo_id || ':' || advancer, ', ' ORDER BY geo_id, advancer)
    INTO v_d04_missing, v_d04_detail
  FROM _d04 e
  WHERE NOT EXISTS (
    SELECT 1 FROM _ca_house h
    WHERE h.geo_id = e.geo_id
      AND h.candidate_status = 'active'
      AND lower(h.full_name) = lower(e.advancer)
  );
  IF v_d04_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-04: % same-party advancer(s) missing as active candidate: %', v_d04_missing, v_d04_detail;
  END IF;
  RAISE NOTICE 'PASS D-04: both named advancers present in all 9 same-party CA districts';

  -- ==========================================================================
  -- In-scope STANCE/HEADSHOT set (D-01/D-05): the 74 candidates seeded by
  -- Phase 149 — 38 genuinely-new CA candidates (politician_id in the -601xxxx
  -- band, -6010000..-6015999) + the 36 zero-stance CA incumbents.
  -- NOTE: USHC-04 (headshots, Wave 2) + USHC-05 (stances, Wave 3) data are NOT
  -- populated by 149-01. These assertions are authored now; they legitimately
  -- FAIL pre-Wave-2/3 and go green only after those waves run.
  -- ==========================================================================

  -- New-candidate set: the 38 -601xxxx politicians wired as active CA House cands.
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.politician_id
  FROM _ca_house h
  JOIN essentials.politicians p ON p.id = h.politician_id
  WHERE h.candidate_status = 'active'
    AND p.external_id BETWEEN -6015999 AND -6010000;

  -- 36 zero-stance CA incumbents (per 148 field table, zero-tier renominated/
  -- redistricted-home runners). Pinned by 148 incumbent_pid. (LaMalfa CA-1
  -- deceased and the partial/done incumbents are NOT in the zero-stance set.)
  CREATE TEMP TABLE _zero_incumbents (politician_id uuid, who text) ON COMMIT DROP;
  INSERT INTO _zero_incumbents (politician_id, who) VALUES
    ('960e5acd-c847-4c8b-9a00-980483647849','Jared Huffman CA-2'),
    ('645a79be-ad06-461f-b2d6-3f811a0c48ee','Kevin Kiley CA-6'),
    ('4466bd8c-8dba-4f2e-9471-c06d8429a779','Mike Thompson CA-4'),
    ('f7704cd1-eec4-40d8-b44f-429b4f9c8611','Tom McClintock CA-5'),
    ('0d635e23-f206-44fc-bac1-e309b932a081','Ami Bera CA-3'),
    ('5be0c642-33b3-4ea4-8bb1-2eb25df2b4ef','Doris Matsui CA-7'),
    ('28eeeb86-5ec1-48dd-86a7-9cf6d7771949','John Garamendi CA-8'),
    ('3ab13c27-f66e-486f-b3d4-87ddb927c35f','Josh Harder CA-9'),
    ('bc29096f-63ce-41f7-8d51-c4e6cfa87f8c','Mark DeSaulnier CA-10'),
    ('39db6eee-ccf5-4901-90a0-1c2580731b0e','Lateefah Simon CA-12'),
    ('1b473093-b86b-4b39-990b-19859d163080','Adam Gray CA-13'),
    ('9c880377-7e1f-4994-91b3-82d9cb15bbb4','Kevin Mullin CA-15'),
    ('7ceb0371-baba-4d05-9204-2852cc91dee0','Sam Liccardo CA-16'),
    ('07255876-bbe6-4f6a-8c68-75939d9b5128','Ro Khanna CA-17'),
    ('956281d7-e27e-43cc-84e9-244879ed5ecf','Zoe Lofgren CA-18'),
    ('29a4c8f8-67a4-45a1-b4e8-ea708523cf3f','Jimmy Panetta CA-19'),
    ('e228243c-4d7c-4a61-87c9-2e3f7a9d6afd','Vince Fong CA-20'),
    ('196e8502-0aab-49a8-a6a0-6626bf121f34','Jim Costa CA-21'),
    ('42bff283-c977-43f1-9d54-a06131dc5eac','David Valadao CA-22'),
    ('565438e0-04f1-4d2d-87cf-44df42ac1173','Salud Carbajal CA-24'),
    ('5238b298-6004-4bcc-94c2-ee43a9c2999e','Raul Ruiz CA-25'),
    ('be2943b7-f634-42f4-8ab8-15db8138169f','Gil Cisneros CA-31'),
    ('0af35a49-9908-474a-a3b6-f0f0ad1e85a0','Mark Takano CA-39'),
    ('504a0b06-6729-4fc5-93cd-7c43b1e153fe','Young Kim CA-40'),
    ('97b8516d-37a6-46e5-8030-60ac927ced4f','Ken Calvert CA-41-pid'),
    ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7','Nanette Diaz Baragan CA-44'),
    ('c06165d2-008c-4fe3-93cd-e31fbd6e377f','Lou Correa CA-46'),
    ('59b9f70a-b67d-4ff9-a99a-829442300178','Dave Min CA-47'),
    ('821be1ee-ba55-4f47-9e5f-7a39f8514271','Mike Levin CA-49'),
    ('3a9072fc-cb5c-4435-ad77-86562481830f','Scott Peters CA-50'),
    ('51e4c723-299f-46a6-b1b2-f75386ee64f0','Sara Jacobs CA-51'),
    ('afa3cab9-4caf-4df3-a9ce-f739cc12b89d','Juan Vargas CA-52');

  -- Union into the single in-scope candidate set (38 new + the zero-incumbents).
  CREATE TEMP TABLE _in_scope ON COMMIT DROP AS
  SELECT politician_id FROM _new_cands
  UNION
  SELECT politician_id FROM _zero_incumbents;

  -- Federal-24 topic_ids (RESEARCH §Federal-24 Topic Set), resolved live by key.
  CREATE TEMP TABLE _fed24 ON COMMIT DROP AS
  SELECT id AS topic_id, topic_key
  FROM inform.compass_topics
  WHERE topic_key IN (
    'abortion','ai-regulation','campaign-finance','childcare','civil-rights',
    'climate-change','deportation','fossil-fuels','healthcare','homelessness',
    'housing','immigration','medicare/aid','misinformation','redistricting',
    'religious-freedom','same-sex-marriage','school-vouchers','social-security',
    'tariffs','taxes','trans-athletes','voting-rights','ukraine-support');

  -- Whole-record stance honest-skip set (USHS-14a pattern). Pinned by exact
  -- UUID with the EXACT ORDER BY (the 143 lesson). Currently EMPTY — populated
  -- by the Wave-3 stance plan if any candidate is a documented whole-record skip.
  CREATE TEMP TABLE _stance_skip (politician_id uuid, reason text) ON COMMIT DROP;
  -- INSERT INTO _stance_skip (politician_id, reason) VALUES
  --   ('<uuid>','<documented whole-record honest-skip reason>');
  -- (Wave-3 pins go here; the coverage query below uses ORDER BY politician_id
  --  to match any pinned-set literal exactly.)

  -- ===== USHC-04 — every newly-seeded CA candidate has a politician_images row
  -- (Wave 2). Honest-skip headshots, if any, are pinned by UUID with ORDER BY.
  SELECT COUNT(*),
         string_agg(p.full_name || ' (' || p.external_id || ')', ', ' ORDER BY p.external_id)
    INTO v_no_image, v_image_detail
  FROM _new_cands nc
  JOIN essentials.politicians p ON p.id = nc.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id
  )
  -- Documented USHC-04 honest-skips (149-03): obscure House challengers with NO free-license
  -- portrait anywhere (all-rights-reserved campaign/social/news only; no Commons file; no current
  -- gov office yielding a PD .gov portrait). Pinned by exact external_id (see 149-03-SUMMARY.md).
  -- A wrong-person or copyrighted image was explicitly refused over filling these (T-149-09/10).
  AND p.external_id NOT IN (
    -6015201, -6015101, -6014901, -6014701, -6014601, -6014401, -6014301, -6014201, -6014102,
    -6013802, -6012901, -6012601, -6012401, -6012301, -6012001, -6011901, -6011801, -6011701,
    -6011601, -6011501, -6011201, -6011001, -6010901, -6010801, -6010501, -6010401, -6010201
  );
  IF v_no_image <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-04 (Wave 2): % newly-seeded CA candidate(s) lack a politician_images row: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS USHC-04: every newly-seeded CA candidate has a politician_images row';

  -- ===== USHC-05a — 0 unsourced stance rows for the in-scope set (Wave 3) =====
  -- An answer is "unsourced" if it has no inform.politician_context row for
  -- (politician_id, topic_id) with a non-empty sources array.
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
    RAISE EXCEPTION 'FAIL USHC-05a (Wave 3): % unsourced stance row(s) in the in-scope CA candidate set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS USHC-05a: 0 unsourced stance rows for the in-scope CA candidate set';

  -- ===== USHC-05b — federal-24 coverage OR pinned honest-skip (Wave 3) ========
  -- Every in-scope candidate not in the pinned whole-record skip set must carry
  -- all 24 federal topics. (Per-topic honest-skips are allowed within a record
  -- only where evidence is thin; D-05/D-01 target is full federal-24 — uncovered
  -- topics surface here so Wave 3 can confirm each as a deliberate honest-skip.)
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
  WHERE x.fed_count < 24;
  IF v_uncovered <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-05b (Wave 3): % in-scope candidate(s) below federal-24 coverage and not pinned as whole-record honest-skip: %', v_uncovered, v_cov_detail;
  END IF;
  RAISE NOTICE 'PASS USHC-05b: every in-scope candidate has federal-24 coverage or is a pinned honest-skip';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC-02/03/04/05 + D-04)';
END $$;
