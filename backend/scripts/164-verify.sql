-- 164-verify.sql — Phase 164 read-only production gate (USHC3-02/03/04/05).
--
-- SELECT-only. Asserts the live state delivered across Phase 164's waves for the
-- KY + OR + CT + OK + AR + IA + KS + MS 2026 US House field (38 districts:
-- KY 6, OR 6, CT 5, OK 5, AR 4, IA 4, KS 4, MS 4). Cloned structurally from the
-- validated 162-verify.sql (per-state scoping + honest-skip pin discipline). This group
-- has ZERO redistricting → NO severe/withholding block. FOUR novel blocks instead:
--   * OPEN-SEAT     — each departing incumbent (Massie/Barr/Hern/Hinson/Feenstra) has 0
--                     active race_candidates rows (mirror of 162's IN9-FLAG novel block).
--   * OR-REUSE      — OR wired candidates onto its 6 PRE-EXISTING race UUIDs; no new OR
--                     general authored; exactly 1 rc row per (race_id, politician_id).
--   * PROVISIONAL   — CT (5) + KS (4) race descriptions carry 'PROVISIONAL:'; the 6 decided
--                     states (KY/OR/OK/AR/IA/MS) do not.
--   * COLLISION-BAND— D-04 sub-band seq floors honored: KY-1 ≥200, OK-1 ≥44 (in-century fix —
--                     the audit's 200 would have collided with OK-3 seq1), OR-1 ≥14,
--                     KS-1 ≥3, KS-2 ≥10.
--
-- PER-STATE SCOPING: 8 SEPARATE elections. OR reuses 6 PRE-EXISTING races under 'OR 2026
--   General' (candidates-only seed, 164-03). Every assertion scoped by election id AND
--   d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN (21,41,09,40,05,19,20,28).
--
-- HONEST-SKIP PIN TABLES (whole-record stance skips; pin by external_id → politician_id,
--   ORDER BY politician_id): KS 4 / CT 2 / OR 1 / KY 2 / OK 3 / IA 0 / AR 1 / MS 0 = 13.
--   Full trails: 164-07..12-SUMMARY.md.
-- HEADSHOT HONEST-SKIP PINS (_img_skip, ORDER BY external_id): 85 of the 94 active new
--   candidates lack a free-license portrait (down-ballot / no dedicated bio / guard reject);
--   9 uploaded (Bronin/Gilchrest/Alvarado/Gallrein/Tedford/Bohannan/J.Mitchell/Trone Garriott/
--   Hulum). Reconstructed live against prod at gate-authoring time (2026-07-06).
--
-- WRITE-FREE: only CREATE TEMP TABLE ... ON COMMIT DROP. SELECT-only against production.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/164-verify.sql

\set ON_ERROR_STOP on

DO $$
DECLARE
  ky_eid uuid; or_eid uuid; ct_eid uuid; ok_eid uuid;
  ar_eid uuid; ia_eid uuid; ks_eid uuid; ms_eid uuid;
  v_ky int; v_or int; v_ct int; v_ok int; v_ar int; v_ia int; v_ks int; v_ms int;
  v_null_office int; v_nullpid int; v_dupname int; v_party_cols int;
  v_openseat int; v_openseat_detail text;
  v_or_reuse int; v_or_wrong int; v_or_dup int;
  v_prov_missing int; v_prov_leak int;
  v_cb int; v_cb_detail text;
  v_no_image int; v_image_detail text;
  v_unsourced int; v_uncovered int; v_cov_detail text;
BEGIN
  -- ==========================================================================
  -- Resolve the 8 elections (OR = the pre-existing 'OR 2026 General').
  -- ==========================================================================
  SELECT id INTO ky_eid FROM essentials.elections WHERE name = 'KY 2026 Statewide General';
  SELECT id INTO or_eid FROM essentials.elections WHERE name = 'OR 2026 General';
  SELECT id INTO ct_eid FROM essentials.elections WHERE name = 'CT 2026 Statewide General';
  SELECT id INTO ok_eid FROM essentials.elections WHERE name = 'OK 2026 Statewide General';
  SELECT id INTO ar_eid FROM essentials.elections WHERE name = 'AR 2026 Statewide General';
  SELECT id INTO ia_eid FROM essentials.elections WHERE name = 'IA 2026 Statewide General';
  SELECT id INTO ks_eid FROM essentials.elections WHERE name = 'KS 2026 Statewide General';
  SELECT id INTO ms_eid FROM essentials.elections WHERE name = 'MS 2026 Statewide General';
  IF ky_eid IS NULL OR or_eid IS NULL OR ct_eid IS NULL OR ok_eid IS NULL
     OR ar_eid IS NULL OR ia_eid IS NULL OR ks_eid IS NULL OR ms_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: missing election (ky=%, or=%, ct=%, ok=%, ar=%, ia=%, ks=%, ms=%)',
      ky_eid, or_eid, ct_eid, ok_eid, ar_eid, ia_eid, ks_eid, ms_eid;
  END IF;

  -- ==========================================================================
  -- Combined Phase-164 House working set (all 8 states, LEFT JOIN candidates).
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE r.election_id
           WHEN ky_eid THEN 'KY' WHEN or_eid THEN 'OR' WHEN ct_eid THEN 'CT' WHEN ok_eid THEN 'OK'
           WHEN ar_eid THEN 'AR' WHEN ia_eid THEN 'IA' WHEN ks_eid THEN 'KS' ELSE 'MS' END AS st,
         r.id AS race_id, r.election_id AS race_election_id, r.office_id, r.description,
         d.geo_id, rc.id AS rc_id, rc.politician_id, rc.full_name,
         rc.candidate_status, rc.is_incumbent, p.external_id
  FROM essentials.races r
  JOIN essentials.offices o   ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.politicians p      ON p.id = rc.politician_id
  WHERE r.election_id IN (ky_eid, or_eid, ct_eid, ok_eid, ar_eid, ia_eid, ks_eid, ms_eid)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('21','41','09','40','05','19','20','28');

  -- ==========================================================================
  -- CRITERION 1 — race counts: KY 6 + OR 6 + CT 5 + OK 5 + AR 4 + IA 4 + KS 4 + MS 4 = 38.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_ky FROM _house WHERE st='KY';
  SELECT COUNT(DISTINCT race_id) INTO v_or FROM _house WHERE st='OR';
  SELECT COUNT(DISTINCT race_id) INTO v_ct FROM _house WHERE st='CT';
  SELECT COUNT(DISTINCT race_id) INTO v_ok FROM _house WHERE st='OK';
  SELECT COUNT(DISTINCT race_id) INTO v_ar FROM _house WHERE st='AR';
  SELECT COUNT(DISTINCT race_id) INTO v_ia FROM _house WHERE st='IA';
  SELECT COUNT(DISTINCT race_id) INTO v_ks FROM _house WHERE st='KS';
  SELECT COUNT(DISTINCT race_id) INTO v_ms FROM _house WHERE st='MS';
  IF v_ky<>6 OR v_or<>6 OR v_ct<>5 OR v_ok<>5 OR v_ar<>4 OR v_ia<>4 OR v_ks<>4 OR v_ms<>4 THEN
    RAISE EXCEPTION 'FAIL scope: KY=% (exp 6) OR=% (6) CT=% (5) OK=% (5) AR=% (4) IA=% (4) KS=% (4) MS=% (4)',
      v_ky,v_or,v_ct,v_ok,v_ar,v_ia,v_ks,v_ms;
  END IF;
  RAISE NOTICE 'PASS SCOPE: KY 6 + OR 6 + CT 5 + OK 5 + AR 4 + IA 4 + KS 4 + MS 4 = 38 NATIONAL_LOWER races';

  -- CRITERION 2 — every House race office_id NOT NULL.
  SELECT COUNT(*) INTO v_null_office FROM _house WHERE office_id IS NULL;
  IF v_null_office<>0 THEN RAISE EXCEPTION 'FAIL NULLOFFICE: % races with NULL office_id', v_null_office; END IF;
  RAISE NOTICE 'PASS NULLOFFICE: 0 of 38 Phase-164 House races have NULL office_id';

  -- CRITERION 3 — 0 active race_candidates with NULL politician_id.
  SELECT COUNT(*) INTO v_nullpid FROM _house WHERE candidate_status='active' AND politician_id IS NULL;
  IF v_nullpid<>0 THEN RAISE EXCEPTION 'FAIL NULLPID: % active candidates with NULL politician_id', v_nullpid; END IF;
  RAISE NOTICE 'PASS NULLPID: 0 active KY/OR/CT/OK/AR/IA/KS/MS House candidates with NULL politician_id';

  -- CRITERION 4 — 0 duplicate lower(full_name) among ACTIVE candidates WITHIN each state.
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT st, lower(full_name) FROM _house WHERE candidate_status='active'
    GROUP BY st, lower(full_name) HAVING COUNT(*)>1
  ) q;
  IF v_dupname<>0 THEN RAISE EXCEPTION 'FAIL DUPNAME: % duplicate full_name group(s) within a state', v_dupname; END IF;
  RAISE NOTICE 'PASS DUPNAME: 0 duplicate full_name within any state among active candidates';

  -- CRITERION 5 — antipartisan structural invariant: race_candidates has no party column.
  SELECT COUNT(*) INTO v_party_cols FROM information_schema.columns
  WHERE table_schema='essentials' AND table_name='race_candidates' AND column_name IN ('party','party_affiliation');
  IF v_party_cols<>0 THEN RAISE EXCEPTION 'FAIL PARTY: race_candidates has % party column(s)', v_party_cols; END IF;
  RAISE NOTICE 'PASS PARTY: race_candidates has no party/party_affiliation column';

  -- ==========================================================================
  -- CRITERION 6 (NEW, OPEN-SEAT) — each departing incumbent has 0 active race_candidates rows.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(p.external_id::text || '(' || p.id::text || ')', ', ')
    INTO v_openseat, v_openseat_detail
  FROM essentials.race_candidates rc
  JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE rc.candidate_status='active'
    AND p.id IN ('4d92b909-6add-4486-b0cf-f317b4e10e9b',  -- Massie  KY-4 lost-primary
                 '164fb70e-b8c1-48cd-a6ef-12d80165c67d',  -- Barr    KY-6 retired
                 '96e589b9-d04a-4749-bf9f-9b66eaea5083',  -- Hern    OK-1 retired
                 '91aa37bf-dc8a-45f3-9bf7-e887b8dd99bd',  -- Hinson  IA-2 retired
                 'c25acca0-f280-469c-b708-c314d8036036'); -- Feenstra IA-4 retired
  IF v_openseat<>0 THEN
    RAISE EXCEPTION 'FAIL OPEN-SEAT: departing incumbent(s) have active race_candidates rows: %', v_openseat_detail;
  END IF;
  RAISE NOTICE 'PASS OPEN-SEAT: Massie/Barr/Hern/Hinson/Feenstra each have 0 active race_candidates rows';

  -- ==========================================================================
  -- CRITERION 7 (NEW, OR-REUSE) — OR wired candidates onto its 6 PRE-EXISTING race UUIDs;
  --   no OR race outside the 6; exactly 1 rc row per (race_id, politician_id).
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_or_reuse FROM _house
  WHERE st='OR' AND race_id IN ('8dfd6e35-f91d-4d14-bcec-ae983035da51','504a156a-d4e6-4abe-9a85-a418c0135805',
    '61297fac-c98d-4ad4-b93f-b2e36722bd6a','c5023da0-985e-4e1c-817c-a843849ef6e9',
    '17a4b696-5c15-4f2b-9390-ce1864d57f37','dd25e913-2496-40fa-a735-c9b1d7f68df8');
  SELECT COUNT(DISTINCT race_id) INTO v_or_wrong FROM _house
  WHERE st='OR' AND race_id NOT IN ('8dfd6e35-f91d-4d14-bcec-ae983035da51','504a156a-d4e6-4abe-9a85-a418c0135805',
    '61297fac-c98d-4ad4-b93f-b2e36722bd6a','c5023da0-985e-4e1c-817c-a843849ef6e9',
    '17a4b696-5c15-4f2b-9390-ce1864d57f37','dd25e913-2496-40fa-a735-c9b1d7f68df8');
  SELECT COUNT(*) INTO v_or_dup FROM (
    SELECT race_id, politician_id FROM _house WHERE st='OR' AND politician_id IS NOT NULL
    GROUP BY race_id, politician_id HAVING COUNT(*)>1
  ) q;
  IF v_or_reuse<>6 OR v_or_wrong<>0 THEN
    RAISE EXCEPTION 'FAIL OR-REUSE: OR races on the 6 existing UUIDs=% (exp 6), OR races outside them=% (exp 0)', v_or_reuse, v_or_wrong;
  END IF;
  IF v_or_dup<>0 THEN RAISE EXCEPTION 'FAIL OR-REUSE: % duplicated (race_id, politician_id) pair(s) on OR races', v_or_dup; END IF;
  RAISE NOTICE 'PASS OR-REUSE: 6 OR races are exactly the pre-existing UUIDs (no new OR general), 1 rc row per (race,pol)';

  -- ==========================================================================
  -- CRITERION 8 (NEW, PROVISIONAL) — CT (5) + KS (4) descriptions carry 'PROVISIONAL:';
  --   the 6 decided states do NOT.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_prov_missing FROM _house
  WHERE st IN ('CT','KS') AND (description IS NULL OR description NOT LIKE '%PROVISIONAL:%');
  SELECT COUNT(DISTINCT race_id) INTO v_prov_leak FROM _house
  WHERE st IN ('KY','OR','OK','AR','IA','MS') AND description LIKE '%PROVISIONAL:%';
  IF v_prov_missing<>0 THEN RAISE EXCEPTION 'FAIL PROVISIONAL: % CT/KS race(s) missing PROVISIONAL: marker', v_prov_missing; END IF;
  IF v_prov_leak<>0 THEN RAISE EXCEPTION 'FAIL PROVISIONAL: % decided-state race(s) wrongly marked PROVISIONAL:', v_prov_leak; END IF;
  RAISE NOTICE 'PASS PROVISIONAL: CT (5) + KS (4) races marked PROVISIONAL:; 6 decided states not';

  -- ==========================================================================
  -- CRITERION 9 (NEW, COLLISION-BAND) — D-04 sub-band seq floors honored for the
  --   collision districts. seq = -external_id - (fips*10000 + cd*100).
  --   KY-1 (geo 2101) ≥200; OK-1 (4001) ≥44 [in-century fix]; OR-1 (4101) ≥14;
  --   KS-1 (2001) ≥3; KS-2 (2002) ≥10. Active NEW candidates only (is_incumbent=false).
  -- ==========================================================================
  SELECT COUNT(*), string_agg(geo_id || ':' || external_id::text, ', ' ORDER BY external_id)
    INTO v_cb, v_cb_detail
  FROM _house
  WHERE candidate_status='active' AND is_incumbent=false AND external_id IS NOT NULL
    AND ( (geo_id='2101' AND (-external_id - 210100) < 200)
       OR (geo_id='4001' AND (-external_id - 400100) < 44)
       OR (geo_id='4101' AND (-external_id - 410100) < 14)
       OR (geo_id='2001' AND (-external_id - 200100) < 3)
       OR (geo_id='2002' AND (-external_id - 200200) < 10) );
  IF v_cb<>0 THEN
    RAISE EXCEPTION 'FAIL COLLISION-BAND: % new id(s) below their D-04 seq floor: %', v_cb, v_cb_detail;
  END IF;
  RAISE NOTICE 'PASS COLLISION-BAND: KY-1 >=200, OK-1 >=44, OR-1 >=14, KS-1 >=3, KS-2 >=10 sub-band floors honored';

  -- ==========================================================================
  -- New-candidate working set (Phase-164 external_id bands, ACTIVE only).
  -- Bands (per 164-01..06 SUMMARYs): KY -210899..-210101, OR -410699..-410101,
  --   CT -90599..-90101, OK -400599..-400101, AR -50499..-50101, IA -190499..-190101,
  --   KS -200499..-200101, MS -280499..-280101. Scoped via _house so MA-band overlaps
  --   (KS/KY) never enter — only real phase candidates appear.
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.st, h.politician_id, h.external_id
  FROM _house h
  WHERE h.candidate_status='active' AND h.is_incumbent=false
    AND ( (h.st='KY' AND h.external_id BETWEEN -210899 AND -210101)
       OR (h.st='OR' AND h.external_id BETWEEN -410699 AND -410101)
       OR (h.st='CT' AND h.external_id BETWEEN -90599  AND -90101)
       OR (h.st='OK' AND h.external_id BETWEEN -400599 AND -400101)
       OR (h.st='AR' AND h.external_id BETWEEN -50499  AND -50101)
       OR (h.st='IA' AND h.external_id BETWEEN -190499 AND -190101)
       OR (h.st='KS' AND h.external_id BETWEEN -200499 AND -200101)
       OR (h.st='MS' AND h.external_id BETWEEN -280499 AND -280101) );

  -- ==========================================================================
  -- Whole-record stance honest-skip pins (_stance_skip, ORDER BY politician_id).
  --   KS 4 / CT 2 / OR 1 / KY 2 / OK 3 / AR 1 = 13. Trails: 164-07..12-SUMMARY.md.
  -- ==========================================================================
  CREATE TEMP TABLE _stance_skip (politician_id uuid, external_id bigint, reason text) ON COMMIT DROP;
  INSERT INTO _stance_skip (politician_id, external_id, reason)
  SELECT p.id, p.external_id, v.reason
  FROM (VALUES
    (-200304::bigint, 'Gavin Solomon KS-3 -- serial multi-state filer, zero KS footprint'),
    (-200305, 'Blake Stanley KS-3 -- FEC committee terminated, no site/social/positions'),
    (-200401, 'Michael Gaynor KS-4 -- fringe filer, no web presence/platform'),
    (-200408, 'Daniel Schneider KS-4 -- withdrew to a KS state-house race'),
    (-90403,  'Luz Helena Bueno CT-4 -- FEC-filed but no reachable primary source'),
    (-90405,  'Damon Lawrence Cerreta CT-4 -- FEC-filed but only generic language, unmappable'),
    (-410301, 'Loran Ayles OR-3 -- no campaign site, $0 FEC, no web presence'),
    (-210403, 'Mohammad Wael Ahmad KY-4 -- no site/questionnaire/verified social'),
    (-210502, 'Gerardo Serrano KY-5 -- no usable position evidence located'),
    (-400202, 'Ronnie Hopkins OK-2 -- 2026 site 404, only stale inferred foreign-aid line'),
    (-400402, 'Rocco Bonacci OK-4 -- no FEC/site, disability-advocacy coverage only'),
    (-400503, 'Austin Nieves OK-5 -- no FEC/site, prior run withdrawn'),
    (-50302,  'Bobby Wilson AR-3 -- positions do not map to any of the 24 scales without over-inferring')
  ) AS v(external_id, reason)
  JOIN essentials.politicians p ON p.external_id = v.external_id
  ORDER BY p.id;

  -- ==========================================================================
  -- Headshot honest-skip pins (_img_skip, ORDER BY external_id). 85 of 94 active new
  --   candidates (9 uploaded). Reconstructed live 2026-07-06.
  -- ==========================================================================
  CREATE TEMP TABLE _img_skip (external_id bigint) ON COMMIT DROP;
  INSERT INTO _img_skip (external_id) VALUES
    (-410601),(-410501),(-410402),(-410401),(-410301),(-410201),(-410114),
    (-400503),(-400502),(-400501),(-400402),(-400401),(-400301),(-400202),(-400201),(-400145),
    (-280402),(-280302),(-280301),(-280202),(-280201),(-280102),(-280101),
    (-210604),(-210603),(-210602),(-210503),(-210502),(-210501),(-210404),(-210403),(-210402),(-210301),(-210300),(-210202),(-210201),
    (-200410),(-200409),(-200408),(-200407),(-200406),(-200405),(-200404),(-200403),(-200402),(-200401),
    (-200305),(-200304),(-200303),(-200302),(-200301),(-200212),(-200211),(-200210),(-200106),(-200105),(-200104),(-200103),
    (-190402),(-190401),(-190204),(-190203),(-190202),(-190102),
    (-90504),(-90503),(-90502),(-90501),(-90405),(-90404),(-90403),(-90402),(-90401),(-90303),(-90302),(-90301),(-90201),(-90104),(-90103),
    (-50401),(-50302),(-50301),(-50201),(-50102),(-50101);

  -- ==========================================================================
  -- USHC3-04 — every active new candidate has a politician_images row, except pinned skips.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(nc.st || ':' || nc.external_id, ', ' ORDER BY nc.external_id)
    INTO v_no_image, v_image_detail
  FROM _new_cands nc
  WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id)
    AND nc.external_id NOT IN (SELECT external_id FROM _img_skip);
  IF v_no_image<>0 THEN
    RAISE EXCEPTION 'FAIL HEADSHOT: % active new candidate(s) lack an image and are not pinned: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS HEADSHOT: every active new candidate has a politician_images row or a pinned honest-skip (85 pinned)';

  -- ==========================================================================
  -- USHC3-05a — 0 unsourced stance rows for ALL active in-scope politicians.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers a
  JOIN (SELECT DISTINCT politician_id FROM _house WHERE candidate_status='active' AND politician_id IS NOT NULL) sc
    ON sc.politician_id = a.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
      AND c.sources IS NOT NULL AND array_length(c.sources, 1) >= 1
  );
  IF v_unsourced<>0 THEN RAISE EXCEPTION 'FAIL UNSOURCED: % unsourced stance row(s) in the in-scope set', v_unsourced; END IF;
  RAISE NOTICE 'PASS UNSOURCED: 0 unsourced stance rows for the in-scope KY/OR/CT/OK/AR/IA/KS/MS candidate set';

  -- ==========================================================================
  -- USHC3-05b — every in-scope NEW candidate has >=1 sourced stance OR is a pinned skip.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(x.who, ', ' ORDER BY x.politician_id)
    INTO v_uncovered, v_cov_detail
  FROM (
    SELECT nc.politician_id, nc.st || ':' || nc.external_id AS who,
           (SELECT COUNT(*) FROM inform.politician_answers a WHERE a.politician_id = nc.politician_id) AS ans_count
    FROM _new_cands nc
    WHERE nc.politician_id NOT IN (SELECT politician_id FROM _stance_skip)
  ) x
  WHERE x.ans_count < 1;
  IF v_uncovered<>0 THEN
    RAISE EXCEPTION 'FAIL COVERAGE: % new candidate(s) have 0 stances and are not pinned: %', v_uncovered, v_cov_detail;
  END IF;
  RAISE NOTICE 'PASS COVERAGE: every in-scope new candidate has >=1 sourced stance or is a pinned whole-record skip (13 pinned)';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC3-02/03/04/05, 38 districts: KY 6 / OR 6 / CT 5 / OK 5 / AR 4 / IA 4 / KS 4 / MS 4; OPEN-SEAT + OR-REUSE + PROVISIONAL + COLLISION-BAND verified)';
END $$;
