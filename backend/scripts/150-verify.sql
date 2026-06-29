-- 150-verify.sql — Phase 150 read-only production gate (USHC-02/03/04/05 + D-01/02/03/05).
--
-- SELECT-only. Asserts the live state delivered across Phase 150's waves for the TX + NY
-- 2026 US House field. Adapts the validated 149-verify.sql precedent for TWO states.
--
--   USHC-03a — all 38 TX races (resp. 26 NY) have >=1 active race_candidate, and the race
--              COUNT is exactly 38 TX / 26 NY (no district missing). Hard floor is >=1 (a safe
--              seat may be uncontested); a NOTICE reports any race with <2 (typical field is >=2).
--   USHC-03b — 0 active race_candidates with NULL politician_id (per-state, House-scoped).
--   USHC-02a — 0 duplicate full_name among ACTIVE candidates WITHIN each state (D-03).
--   USHC-02c — every renominated/home-running TX & NY incumbent + cross-district reuse (Casar
--              TX-37) reuses its 148 incumbent_pid as an ACTIVE House candidate (no new
--              duplicate-incumbent record — the v2.4 two-Andy-Barrs trap).
--   D-05     — lost/redistricted-away incumbents whose old seat now has a different nominee are
--              ABSENT from the active field: TX-2 Crenshaw, NY-10 Goldman, NY-13 Espaillat each
--              appear 0 times as active; their winners (Steve Toth, Brad Lander, Darializa Avila
--              Chevalier) ARE active.
--   D-02     — fusion minor-line candidates are seeded: NY-13 Bob Cohen + NY-21 Robert Smullen
--              each appear as an ACTIVE candidate (party-agnostic — presence, not party).
--   USHC-04  — every newly-seeded TX/NY candidate (politician_id in the new-candidate external_id
--              band: TX -4819999..-4810000, NY -3619999..-3610000) has an essentials.politician_images
--              row; documented headshot honest-skips pinned by exact external_id with explicit ORDER BY.
--   USHC-05a — 0 unsourced stance rows for the in-scope set (every answer has a matching
--              inform.politician_context with a non-empty sources array).
--   USHC-05b — each in-scope candidate has >=1 sourced federal stance OR is a pinned whole-record
--              honest-skip (per-topic gaps accepted; full-24 NOT required — chairs-not-polarity
--              forbids party-inference inflation; [[project-149-stance-gate-standard]]).
--
-- ============================================================================
-- PER-STATE SCOPING (the cross-state contamination trap):
--   TX and NY are SEPARATE elections. Every assertion is scoped by election id AND
--   d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2)='48' (TX) / '36' (NY).
--   NEVER write a cross-state or election-wide count.
--
-- D-01 ASYMMETRY (the NY-partial false-fail trap):
--   TX: all 37 incumbents were zero-stance -> every ACTIVE TX candidate (new + incumbent) is
--       in the stance in-scope set.
--   NY: the 25 partial incumbents are LEFT AS-IS this phase (NOT topped up) + NY-14 AOC is done.
--       Only the NEW NY candidates (new external_id band) are in the stance in-scope set. The
--       renominated NY incumbents are EXCLUDED so their pre-existing partial coverage cannot
--       false-fail a 0-unsourced or coverage check.
--
-- THE 143 HONEST-SKIP-ORDERING LESSON:
--   Any whole-record stance honest-skip (and any headshot honest-skip) is pinned by exact UUID /
--   external_id WITH the query's exact ORDER BY. An ordering mismatch false-fails.
--
-- WRITE-FREE: no DELETE/UPDATE/INSERT INTO essentials|inform. The only writes are
--   CREATE TEMP TABLE ... ON COMMIT DROP (149/148-verify.sql precedent). SELECT-only.
--
-- WAVE TIMING (documented expectation — data-dependent assertions FAIL pre-seed, go green after):
--   150-02 AUTHORS this gate. 150-01 shipped the races scaffold -> USHC-03 race-count passes now;
--   candidate/dedup (USHC-02 + D-02/05) pass after 150-03/04; USHC-04 after 150-05/06; USHC-05
--   after 150-07..11. Reuse-pid pins for the 4 redistricted-away TX runners (TX-9/30/32/33) +
--   honest-skip pins are ADDED to this file by the relevant wave (the 149 model). 150-05..11 may
--   run this gate mid-wave to verify their slice.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/150-verify.sql
--
-- TX election: 783b7506-...  TX FIPS 48 / geo 4801..4838.   NY election: 80a2b03d-...  NY FIPS 36 / geo 3601..3626.

\set ON_ERROR_STOP on

DO $$
DECLARE
  tx_eid          uuid;
  ny_eid          uuid;
  v_tx_races      int;
  v_ny_races      int;
  v_under1        int;
  v_under2        int;
  v_nullpid       int;
  v_dupname       int;
  v_reuse_missing int;
  v_lost_active   int;
  v_winner_missing int;
  v_minor_missing int;
  v_no_image      int;
  v_image_detail  text;
  v_unsourced     int;
  v_uncovered     int;
  v_cov_detail    text;
BEGIN
  SELECT id INTO tx_eid FROM essentials.elections WHERE name = 'TX 2026 Statewide General';
  SELECT id INTO ny_eid FROM essentials.elections WHERE name = 'NY 2026 Statewide General';
  IF tx_eid IS NULL OR ny_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: TX/NY 2026 Statewide General election(s) not found (tx=%, ny=%)', tx_eid, ny_eid;
  END IF;

  -- ==========================================================================
  -- Per-state House working sets (every race + LEFT JOIN candidates), scoped by
  -- election + NATIONAL_LOWER + geo prefix. _state column distinguishes TX/NY.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE WHEN r.election_id = tx_eid THEN 'TX' ELSE 'NY' END AS st,
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
  WHERE r.election_id IN (tx_eid, ny_eid)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN ('48','36');

  -- Scope sanity: exactly 38 TX + 26 NY distinct House races.
  SELECT COUNT(DISTINCT race_id) INTO v_tx_races FROM _house WHERE st = 'TX';
  SELECT COUNT(DISTINCT race_id) INTO v_ny_races FROM _house WHERE st = 'NY';
  IF v_tx_races <> 38 THEN RAISE EXCEPTION 'FAIL scope: expected 38 TX House races, got %', v_tx_races; END IF;
  IF v_ny_races <> 26 THEN RAISE EXCEPTION 'FAIL scope: expected 26 NY House races, got %', v_ny_races; END IF;

  -- ===== USHC-03a — every race has >=1 active candidate (hard floor); count exact ==========
  SELECT COUNT(*) INTO v_under1 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 1
  ) q;
  IF v_under1 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-03a: % TX/NY House race(s) have 0 active candidates', v_under1;
  END IF;
  SELECT COUNT(*) INTO v_under2 FROM (
    SELECT race_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 2
  ) q;
  RAISE NOTICE 'PASS USHC-03a: all % TX/NY House races have >=1 active candidate (% race(s) have <2 — uncontested-seat allowance)', v_tx_races + v_ny_races, v_under2;

  -- ===== USHC-03b — 0 active rows with NULL politician_id (per-state) =========
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-03b: % active TX/NY House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS USHC-03b: 0 active TX/NY House candidates with NULL politician_id';

  -- ===== USHC-02a — 0 duplicate full_name among ACTIVE candidates WITHIN each state =========
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT st, lower(full_name)
    FROM _house
    WHERE candidate_status = 'active'
    GROUP BY st, lower(full_name)
    HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-02a: % duplicate full_name(s) within a state among active candidates (D-03 / v2.4 dup-incumbent trap)', v_dupname;
  END IF;
  RAISE NOTICE 'PASS USHC-02a: 0 duplicate full_name within TX and within NY (D-03)';

  -- ===== USHC-02c — renominated/home incumbents reuse their 148 pid ==========
  -- Pin every renominated incumbent (148-incumbent-map.csv) + the cross-district reuse case
  -- (Greg Casar TX-35 pid -> active TX-37). Assert each pid appears as an ACTIVE House
  -- candidate anywhere in its state (redistricted runners appear in their NEW district).
  -- EXCLUDED (intentionally NOT in the set): lost-primary (TX-2 Crenshaw, NY-10 Goldman,
  -- NY-13 Espaillat), retired (TX-8/10/19/21/37/38, NY-7/12/21), and the 4 redistricted-away
  -- TX incumbents (TX-9 Green / TX-30 Crockett / TX-32 Johnson / TX-33 Veasey) whose new-district
  -- reuse is ADDED here from the 150-03 reconciliation (POPULATED-BY-150-03 marker below).
  CREATE TEMP TABLE _reuse_pid (st text, expected_pid uuid, who text) ON COMMIT DROP;
  INSERT INTO _reuse_pid (st, expected_pid, who) VALUES
    -- TX renominated home incumbents (25)
    ('TX','e9236454-c687-4721-8193-e37e018c6905','Nathaniel Moran TX-1'),
    ('TX','65013b5e-faf5-458a-abc7-24cd61e32bdb','Keith Self TX-3'),
    ('TX','c6187c67-fa60-4fa2-917f-543cd7fc441f','Pat Fallon TX-4'),
    ('TX','d141e4b7-f9a7-4ab0-927a-ba08348eab13','Lance Gooden TX-5'),
    ('TX','bb7b3620-83cb-4b88-a823-95a8e09f6e46','Jake Ellzey TX-6'),
    ('TX','af3deea9-ba89-4d48-b16a-fa785b35a827','Lizzie Fletcher TX-7'),
    ('TX','4b04c042-bae9-456a-8ebc-e84e11397b23','August Pfluger TX-11'),
    ('TX','846501ab-5b92-4270-97ed-21a43842c726','Craig Goldman TX-12'),
    ('TX','184670b8-6647-4f84-a5fb-f2a9cfae3f5a','Ronny Jackson TX-13'),
    ('TX','d5b43e69-b0df-44d5-83ba-a4baca56dd3b','Randy Weber TX-14'),
    ('TX','c3cb5289-17af-4952-9894-dbddfcd50484','Monica De La Cruz TX-15'),
    ('TX','276f0f2c-c521-417a-beb4-120b99915f13','Veronica Escobar TX-16'),
    ('TX','e3cfee5b-29ab-427b-adc9-acd97e4b0f9a','Pete Sessions TX-17'),
    ('TX','76cfc903-921f-4c45-b10a-cbfa8bb1859f','Christian Menefee TX-18'),
    ('TX','7c7b5942-8ad8-4e15-bd62-f16be22d676e','Joaquin Castro TX-20'),
    ('TX','a0bc977b-71c6-4973-9082-3cc009445a02','Troy Nehls TX-22'),
    ('TX','510f7802-7b58-4e4a-9824-37e169e65680','Beth Van Duyne TX-24'),
    ('TX','42e2edff-6da4-49c2-ba60-fd4acbb326f7','Roger Williams TX-25'),
    ('TX','4b7c5474-9a09-4e12-8f74-17d5748909b3','Brandon Gill TX-26'),
    ('TX','4e29212d-3ff9-42fc-bcd8-817ad6fd90d7','Michael Cloud TX-27'),
    ('TX','b28df80b-5302-4016-9274-8f8320b5b9a9','Henry Cuellar TX-28'),
    ('TX','b956345e-e9fb-4e4f-97b3-ed2213f5da1e','Sylvia Garcia TX-29'),
    ('TX','2aa44302-0cd5-4ad1-9c43-557bb99bb88b','John Carter TX-31'),
    ('TX','6a18fa31-ad05-481a-bf5e-ecaa5cd193d1','Vicente Gonzalez TX-34'),
    ('TX','c4ad307f-b38a-409c-8190-8dedad609d88','Brian Babin TX-36'),
    -- TX cross-district reuse: Greg Casar (TX-35 incumbent pid) active in TX-37
    ('TX','24e22813-4b39-4305-979d-1ea5f210a4f4','Greg Casar (TX-35 pid, active TX-37)'),
    -- POPULATED-BY-150-03: TX-9 Green / TX-30 Crockett / TX-32 Johnson / TX-33 Veasey new-district reuse
    -- NY renominated home incumbents (21)
    ('NY','4c5a2401-4b0c-4a48-9225-11c2ad768a12','Nick LaLota NY-1'),
    ('NY','587df016-35d9-43af-b839-db4899c384fc','Andrew R. Garbarino NY-2'),
    ('NY','a1c608d4-3feb-4bb0-b797-00453d08a0e8','Thomas R. Suozzi NY-3'),
    ('NY','643cde96-6b12-4fce-a404-0191a5c7f9bd','Laura Gillen NY-4'),
    ('NY','b2f09c72-ceda-4942-a7db-9f0c5f229713','Gregory W. Meeks NY-5'),
    ('NY','a49af796-7961-4b82-8327-989691880a39','Grace Meng NY-6'),
    ('NY','42f9ff9e-b15d-4b0a-9f73-23015121069c','Hakeem S. Jeffries NY-8'),
    ('NY','efa0cb88-6ae0-47dc-abe1-b1388983addf','Yvette D. Clarke NY-9'),
    ('NY','56dfd8dd-ac7a-482a-848a-7c1d0e979606','Nicole Malliotakis NY-11'),
    ('NY','86533db6-cfb8-49bf-a265-74a3b3845575','Alexandria Ocasio-Cortez NY-14'),
    ('NY','606e50d6-7c2d-424e-86f3-e7da3c2d37f7','Ritchie Torres NY-15'),
    ('NY','147f2883-d8c0-4a56-9adb-6b8c7990264b','George Latimer NY-16'),
    ('NY','cd4e9f29-d1b0-40c1-9e4a-5024cdc7b028','Michael Lawler NY-17'),
    ('NY','8a42070d-5aaf-49f2-bdcd-5086adab496c','Patrick Ryan NY-18'),
    ('NY','a6a6d7b2-88d4-441b-8191-d5baa0db6987','Josh Riley NY-19'),
    ('NY','52bbba11-e099-457b-a05b-aa8f4f5a5b13','Paul Tonko NY-20'),
    ('NY','09a47b4e-566f-46dc-b14b-547b93282f09','John W. Mannion NY-22'),
    ('NY','556dded4-bd76-4e22-863f-60fa5e1d4d56','Nicholas A. Langworthy NY-23'),
    ('NY','e1d8c7bb-cde0-4ec5-8863-0b8ce838cb57','Claudia Tenney NY-24'),
    ('NY','c02d8232-aa7a-429a-9abe-dccb409c1c6f','Joseph D. Morelle NY-25'),
    ('NY','7e37b0b1-d311-4cf3-8f19-f861626d5d98','Timothy M. Kennedy NY-26');

  SELECT COUNT(*) INTO v_reuse_missing
  FROM _reuse_pid rp
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = rp.st AND h.candidate_status = 'active' AND h.politician_id = rp.expected_pid
  );
  IF v_reuse_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-02c: % reused-incumbent pid(s) absent from active candidates (possible new duplicate-incumbent record — v2.4 trap)', v_reuse_missing;
  END IF;
  RAISE NOTICE 'PASS USHC-02c: all % pinned renominated/cross-district incumbents reuse their 148 pid', (SELECT COUNT(*) FROM _reuse_pid);

  -- ===== D-05 — lost/redistricted-away incumbents ABSENT; winners PRESENT =====
  SELECT COUNT(*) INTO v_lost_active
  FROM _house h
  WHERE h.candidate_status = 'active'
    AND h.politician_id IN (
      'deae1b6d-3aa5-43fe-aff3-df73052cc434',  -- TX-2 Dan Crenshaw (lost primary)
      'c7f357ce-2fa0-4760-921b-905ff6a63944',  -- NY-10 Daniel S. Goldman (lost primary)
      '26636234-c292-4a02-8205-6b84f6864f82'   -- NY-13 Adriano Espaillat (lost primary)
    );
  IF v_lost_active <> 0 THEN
    RAISE EXCEPTION 'FAIL D-05: % lost-primary incumbent(s) (Crenshaw/Goldman/Espaillat) surfaced as ACTIVE candidate', v_lost_active;
  END IF;
  -- Winners present (match by name within the district's active field).
  CREATE TEMP TABLE _winners (st text, geo_id text, who text) ON COMMIT DROP;
  INSERT INTO _winners (st, geo_id, who) VALUES
    ('TX','4802','Steve Toth'),
    ('NY','3610','Brad Lander'),
    ('NY','3613','Darializa Avila Chevalier');
  SELECT COUNT(*) INTO v_winner_missing
  FROM _winners w
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = w.st AND h.geo_id = w.geo_id
      AND h.candidate_status = 'active' AND lower(h.full_name) = lower(w.who)
  );
  IF v_winner_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-05: % lost-seat primary winner(s) absent from the active field', v_winner_missing;
  END IF;
  RAISE NOTICE 'PASS D-05: Crenshaw/Goldman/Espaillat absent; Toth/Lander/Avila Chevalier active';

  -- ===== D-02 — fusion minor-line candidates seeded (party-agnostic presence) ==
  CREATE TEMP TABLE _minor (st text, geo_id text, who text) ON COMMIT DROP;
  INSERT INTO _minor (st, geo_id, who) VALUES
    ('NY','3613','Bob Cohen'),       -- NY-13 Working Families
    ('NY','3621','Robert Smullen');  -- NY-21 Conservative
  SELECT COUNT(*) INTO v_minor_missing
  FROM _minor m
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = m.st AND h.geo_id = m.geo_id
      AND h.candidate_status = 'active' AND lower(h.full_name) = lower(m.who)
  );
  IF v_minor_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL D-02: % minor-line candidate(s) (Cohen/Smullen) not seeded as active', v_minor_missing;
  END IF;
  RAISE NOTICE 'PASS D-02: NY-13 Cohen + NY-21 Smullen seeded as active (minor lines not dropped)';

  -- ==========================================================================
  -- In-scope STANCE/HEADSHOT sets (D-01 asymmetry).
  --   _new_cands  = newly-seeded TX/NY candidates (new external_id band) — HEADSHOT scope.
  --   _tx_in_scope = ALL active TX House candidates (TX all-zero-incumbent: new + incumbent).
  --   _ny_in_scope = only NEW NY candidates (new band) — NY partial incumbents + AOC EXCLUDED.
  --   _in_scope    = stance scope = _tx_in_scope UNION _ny_in_scope.
  -- USHC-04/05 data is populated by later waves; these assertions FAIL pre-seed (expected).
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.politician_id
  FROM _house h
  JOIN essentials.politicians p ON p.id = h.politician_id
  WHERE h.candidate_status = 'active'
    AND ( (h.st = 'TX' AND p.external_id BETWEEN -4819999 AND -4810000)
       OR (h.st = 'NY' AND p.external_id BETWEEN -3619999 AND -3610000) );

  CREATE TEMP TABLE _in_scope ON COMMIT DROP AS
  -- TX: every active TX House candidate.
  SELECT DISTINCT h.politician_id
  FROM _house h
  WHERE h.st = 'TX' AND h.candidate_status = 'active' AND h.politician_id IS NOT NULL
  UNION
  -- NY: only the NEW NY candidates (new external_id band).
  SELECT DISTINCT h.politician_id
  FROM _house h
  JOIN essentials.politicians p ON p.id = h.politician_id
  WHERE h.st = 'NY' AND h.candidate_status = 'active'
    AND p.external_id BETWEEN -3619999 AND -3610000;

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
  -- query's ORDER BY (143 lesson). EMPTY now — POPULATED-BY-150-07..11 for genuinely no-record
  -- challengers (campaign sites dead/slogan-only; no Ballotpedia survey; inference refused).
  CREATE TEMP TABLE _stance_skip (politician_id uuid, reason text) ON COMMIT DROP;
  -- (no rows yet)

  -- ===== USHC-04 — every newly-seeded TX/NY candidate has a politician_images row ====
  -- Headshot honest-skips (no free-license portrait anywhere) pinned by exact external_id
  -- WITH ORDER BY (POPULATED-BY-150-05/06). A wrong-person/copyrighted image is refused over filling.
  SELECT COUNT(*),
         string_agg(p.full_name || ' (' || p.external_id || ')', ', ' ORDER BY p.external_id)
    INTO v_no_image, v_image_detail
  FROM _new_cands nc
  JOIN essentials.politicians p ON p.id = nc.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id
  )
  AND p.external_id NOT IN (
    -- POPULATED-BY-150-05/06: documented headshot honest-skips (external_id list, ORDER BY external_id)
    0  -- placeholder (no real external_id is 0); replaced/extended by the headshot waves
  );
  IF v_no_image <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-04 (Wave 3/4): % newly-seeded TX/NY candidate(s) lack a politician_images row: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS USHC-04: every newly-seeded TX/NY candidate has a politician_images row';

  -- ===== USHC-05a — 0 unsourced stance rows for the in-scope set (Wave 3) =====
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
    RAISE EXCEPTION 'FAIL USHC-05a (Wave 3): % unsourced stance row(s) in the in-scope TX/NY candidate set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS USHC-05a: 0 unsourced stance rows for the in-scope TX/NY candidate set';

  -- ===== USHC-05b — >=1 sourced federal stance OR pinned whole-record skip =====
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
    RAISE EXCEPTION 'FAIL USHC-05b: % in-scope candidate(s) have 0 federal stances and are not pinned as whole-record honest-skip: %', v_uncovered, v_cov_detail;
  END IF;
  RAISE NOTICE 'PASS USHC-05b: every in-scope candidate has >=1 sourced federal stance or is a pinned whole-record honest-skip';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC-02/03/04/05 + D-01/02/03/05)';
END $$;
