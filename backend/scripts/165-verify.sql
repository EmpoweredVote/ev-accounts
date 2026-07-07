-- 165-verify.sql — Phase 165 read-only production gate (USHC3-02/03/04/05).
--
-- SELECT-only. Asserts the live state delivered across Phase 165's waves for the
-- 17-state small-delegation 2026 US House field (34 districts: NV 4, UT 4, NM 3, NE 3,
-- WV 2, ID 2, HI 2, ME 2, NH 2, RI 2, MT 2, AK 1, DE 1, ND 1, SD 1, VT 1, WY 1).
-- Cloned structurally from the validated 164-verify.sql; the UT-REKEY NOTOUCH md5 block
-- is cloned from 1641-verify.sql D04-NOTOUCH. This group has ZERO routine redistricting
-- (UT's court-ordered re-key is the dual-map exception, guarded below). SIX novel blocks:
--   * NV-RECONCILE  — NV wired candidates onto its 4 PRE-EXISTING race UUIDs; no new NV
--                     general authored; Chapman rc row 08dfb911 politician_id NOT NULL;
--                     the 5 new NV candidate ids + Chapman's fix id all present.
--   * ME-RECONCILE  — the 2 PRE-EXISTING ME races each have exactly 2 active candidates;
--                     no new ME general authored.
--   * UT-REKEY      — FIPS-49 offices per-row md5 byte-identical to the pre-migration
--                     baseline 4d8bbfb221d4babca6e9f7201bce391e (165-02, dual-map design);
--                     Moore/Maloy/Kennedy is_incumbent=true on the NEW 4902/4903/4904
--                     races; retired Owens has 0 active rows anywhere.
--   * AK-FIELD      — AK's single at-large jungle race has exactly 15 active candidates,
--                     primary_party IS NULL (top-four-RCV modeled per the LA/CA convention).
--   * PROVISIONAL   — AK/HI/NH/RI/DE/VT/WY (10 races) carry 'PROVISIONAL:'; the 7 decided
--                     states NM/NE/WV/ID/MT/ND/SD (13 races) do not. NV/UT/ME excluded
--                     from the assert (NV/UT decided; ME reuse wording pre-existing).
--   * COLLISION-BAND— D-04 sub-band seq floors honored: NV-1>=74, NV-2>=51, NV-4>=79,
--                     ME-1>=3, ME-2>=3, NM-1>=26, NM-2>=51, NM-3>=82, NE-3>=60, NH-1>=33,
--                     MT-2>=85, AK>=5, DE>=48 (Pitfall-6 legacy trap), VT>=6.
-- STANDING INVARIANTS FOR PHASE 166: NV-RECONCILE + ME-RECONCILE + UT-REKEY must be
--   inherited by the Phase 166 consolidated gate (joins the 164 OPEN-SEAT/OR-REUSE set).
--
-- PER-STATE SCOPING: 17 elections (NV + ME pre-existing names). Every assertion scoped by
--   election id AND d.district_type='NATIONAL_LOWER' AND substr(geo_id,1,2) in the 17 fips.
-- HONEST-SKIP PIN TABLES (whole-record stance skips, ORDER BY politician_id): NV 2 / UT 2 /
--   AK 5 / WV 2 / ID 2 / HI 2 / WY 3 = 18. Trails: 165-09..16-SUMMARY.md + per-state _SKIPS.md.
-- HEADSHOT PINS (_img_skip, ORDER BY external_id): 109 of 117 banded active challengers lack
--   a free-license portrait; 8 uploaded (Keohokalole/Awa/Dunlap/Forstag/Sullivan/Tang Williams/
--   Balow/Biteman). Reconstructed live against prod 2026-07-07.
-- UUID-KEYED COVERAGE: Pingree (-230201 zero-tier incumbent) + the 6 reused pids (McAdams/
--   Crosby/Udell/Larsen/Gray/Jackley) asserted >=1 stance in the extra UUID-COVERAGE block.
--
-- WRITE-FREE: only CREATE TEMP TABLE ... ON COMMIT DROP. SELECT-only against production.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/165-verify.sql

\set ON_ERROR_STOP on

DO $$
DECLARE
  eid_nv uuid; eid_me uuid; eid_ut uuid; eid_ak uuid; eid_nm uuid; eid_ne uuid;
  eid_wv uuid; eid_id uuid; eid_hi uuid; eid_nh uuid; eid_ri uuid; eid_mt uuid;
  eid_de uuid; eid_nd uuid; eid_sd uuid; eid_vt uuid; eid_wy uuid;
  v_cnt int; v_detail text;
  v_null_office int; v_nullpid int; v_dupname int; v_party_cols int;
  v_nv_reuse int; v_nv_wrong int; v_nv_elec int; v_chapman int; v_nv_new int;
  v_me1 int; v_me2 int; v_me_wrong int; v_me_elec int;
  v_ut_md5 text; v_ut_inc int; v_owens int;
  v_ak_races int; v_ak_active int; v_ak_party int;
  v_prov_missing int; v_prov_leak int;
  v_cb int; v_cb_detail text;
  v_no_image int; v_image_detail text;
  v_unsourced int; v_uncovered int; v_cov_detail text; v_uuid_cov int; v_uuid_detail text;
BEGIN
  -- ==========================================================================
  -- Resolve the 17 elections (NV + ME = pre-existing names, never created here).
  -- ==========================================================================
  SELECT id INTO eid_nv FROM essentials.elections WHERE name = 'NV 2026 Statewide General';
  SELECT id INTO eid_me FROM essentials.elections WHERE name = '2026 Maine General Election';
  SELECT id INTO eid_ut FROM essentials.elections WHERE name = 'UT 2026 Statewide General';
  SELECT id INTO eid_ak FROM essentials.elections WHERE name = 'AK 2026 Statewide General';
  SELECT id INTO eid_nm FROM essentials.elections WHERE name = 'NM 2026 Statewide General';
  SELECT id INTO eid_ne FROM essentials.elections WHERE name = 'NE 2026 Statewide General';
  SELECT id INTO eid_wv FROM essentials.elections WHERE name = 'WV 2026 Statewide General';
  SELECT id INTO eid_id FROM essentials.elections WHERE name = 'ID 2026 Statewide General';
  SELECT id INTO eid_hi FROM essentials.elections WHERE name = 'HI 2026 Statewide General';
  SELECT id INTO eid_nh FROM essentials.elections WHERE name = 'NH 2026 Statewide General';
  SELECT id INTO eid_ri FROM essentials.elections WHERE name = 'RI 2026 Statewide General';
  SELECT id INTO eid_mt FROM essentials.elections WHERE name = 'MT 2026 Statewide General';
  SELECT id INTO eid_de FROM essentials.elections WHERE name = 'DE 2026 Statewide General';
  SELECT id INTO eid_nd FROM essentials.elections WHERE name = 'ND 2026 Statewide General';
  SELECT id INTO eid_sd FROM essentials.elections WHERE name = 'SD 2026 Statewide General';
  SELECT id INTO eid_vt FROM essentials.elections WHERE name = 'VT 2026 Statewide General';
  SELECT id INTO eid_wy FROM essentials.elections WHERE name = 'WY 2026 Statewide General';
  IF eid_nv IS NULL OR eid_me IS NULL OR eid_ut IS NULL OR eid_ak IS NULL OR eid_nm IS NULL
     OR eid_ne IS NULL OR eid_wv IS NULL OR eid_id IS NULL OR eid_hi IS NULL OR eid_nh IS NULL
     OR eid_ri IS NULL OR eid_mt IS NULL OR eid_de IS NULL OR eid_nd IS NULL OR eid_sd IS NULL
     OR eid_vt IS NULL OR eid_wy IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: missing election(s) among the 17';
  END IF;

  -- ==========================================================================
  -- Combined Phase-165 House working set (17 states, LEFT JOIN candidates).
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE substr(d.geo_id,1,2)
           WHEN '32' THEN 'NV' WHEN '49' THEN 'UT' WHEN '02' THEN 'AK' WHEN '35' THEN 'NM'
           WHEN '31' THEN 'NE' WHEN '54' THEN 'WV' WHEN '16' THEN 'ID' WHEN '15' THEN 'HI'
           WHEN '23' THEN 'ME' WHEN '33' THEN 'NH' WHEN '44' THEN 'RI' WHEN '30' THEN 'MT'
           WHEN '10' THEN 'DE' WHEN '38' THEN 'ND' WHEN '46' THEN 'SD' WHEN '50' THEN 'VT'
           ELSE 'WY' END AS st,
         r.id AS race_id, r.election_id AS race_election_id, r.office_id, r.description,
         r.primary_party, d.geo_id, rc.id AS rc_id, rc.politician_id, rc.full_name,
         rc.candidate_status, rc.is_incumbent, p.external_id
  FROM essentials.races r
  JOIN essentials.offices o   ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.politicians p      ON p.id = rc.politician_id
  WHERE r.election_id IN (eid_nv, eid_me, eid_ut, eid_ak, eid_nm, eid_ne, eid_wv, eid_id,
                          eid_hi, eid_nh, eid_ri, eid_mt, eid_de, eid_nd, eid_sd, eid_vt, eid_wy)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('32','49','02','35','31','54','16','15','23','33','44','30','10','38','46','50','56');

  -- ==========================================================================
  -- CRITERION 1 — race counts: NV 4 + UT 4 + NM 3 + NE 3 + WV 2 + ID 2 + HI 2 + ME 2 +
  --   NH 2 + RI 2 + MT 2 + AK 1 + DE 1 + ND 1 + SD 1 + VT 1 + WY 1 = 34.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_cnt FROM (
    SELECT st, COUNT(DISTINCT race_id) AS n FROM _house GROUP BY st
  ) q
  WHERE (q.st='NV' AND q.n<>4) OR (q.st='UT' AND q.n<>4) OR (q.st='NM' AND q.n<>3)
     OR (q.st='NE' AND q.n<>3) OR (q.st='WV' AND q.n<>2) OR (q.st='ID' AND q.n<>2)
     OR (q.st='HI' AND q.n<>2) OR (q.st='ME' AND q.n<>2) OR (q.st='NH' AND q.n<>2)
     OR (q.st='RI' AND q.n<>2) OR (q.st='MT' AND q.n<>2) OR (q.st='AK' AND q.n<>1)
     OR (q.st='DE' AND q.n<>1) OR (q.st='ND' AND q.n<>1) OR (q.st='SD' AND q.n<>1)
     OR (q.st='VT' AND q.n<>1) OR (q.st='WY' AND q.n<>1);
  IF v_cnt<>0 THEN RAISE EXCEPTION 'FAIL scope: % state(s) with wrong race count', v_cnt; END IF;
  SELECT COUNT(DISTINCT race_id) INTO v_cnt FROM _house;
  IF v_cnt<>34 THEN RAISE EXCEPTION 'FAIL scope: total races=% (exp 34)', v_cnt; END IF;
  RAISE NOTICE 'PASS SCOPE: NV4+UT4+NM3+NE3+WV2+ID2+HI2+ME2+NH2+RI2+MT2+AK1+DE1+ND1+SD1+VT1+WY1 = 34 NATIONAL_LOWER races';

  -- CRITERION 2 — every House race office_id NOT NULL.
  SELECT COUNT(*) INTO v_null_office FROM _house WHERE office_id IS NULL;
  IF v_null_office<>0 THEN RAISE EXCEPTION 'FAIL NULLOFFICE: % races with NULL office_id', v_null_office; END IF;
  RAISE NOTICE 'PASS NULLOFFICE: 0 of 34 Phase-165 House races have NULL office_id';

  -- CRITERION 3 — 0 active race_candidates with NULL politician_id (Chapman fix included).
  SELECT COUNT(*) INTO v_nullpid FROM _house WHERE candidate_status='active' AND politician_id IS NULL;
  IF v_nullpid<>0 THEN RAISE EXCEPTION 'FAIL NULLPID: % active candidates with NULL politician_id', v_nullpid; END IF;
  RAISE NOTICE 'PASS NULLPID: 0 active candidates with NULL politician_id across the 17 states';

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
  -- CRITERION 6 (NEW, NV-RECONCILE) — NV races are exactly the 4 pre-existing UUIDs;
  --   no new NV general race; exactly 1 NV election; Chapman rc 08dfb911 pid NOT NULL;
  --   the 5 new NV candidate ids + Chapman's -320251 all exist.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_nv_reuse FROM _house
  WHERE st='NV' AND race_id IN ('a5295941-38b1-4c7f-8edf-39097ad3fb0a','0c470cc0-5250-43f1-b7f7-57778cadacc6',
    '79e7fb35-a73a-478c-847d-553e9ad11e7c','81eb1a27-b710-42c3-a27c-a2c0153c2820');
  SELECT COUNT(DISTINCT race_id) INTO v_nv_wrong FROM _house
  WHERE st='NV' AND race_id NOT IN ('a5295941-38b1-4c7f-8edf-39097ad3fb0a','0c470cc0-5250-43f1-b7f7-57778cadacc6',
    '79e7fb35-a73a-478c-847d-553e9ad11e7c','81eb1a27-b710-42c3-a27c-a2c0153c2820');
  SELECT COUNT(*) INTO v_nv_elec FROM essentials.elections WHERE name='NV 2026 Statewide General';
  SELECT COUNT(*) INTO v_chapman FROM essentials.race_candidates
  WHERE id='08dfb911-9ddc-4c0d-85a2-fb14884a9160' AND politician_id IS NOT NULL;
  SELECT COUNT(*) INTO v_nv_new FROM essentials.politicians
  WHERE external_id IN (-320174,-320175,-320251,-320301,-320479,-320480);
  IF v_nv_reuse<>4 OR v_nv_wrong<>0 OR v_nv_elec<>1 THEN
    RAISE EXCEPTION 'FAIL NV-RECONCILE: reused=% (exp 4), outside=% (exp 0), elections=% (exp 1)', v_nv_reuse, v_nv_wrong, v_nv_elec;
  END IF;
  IF v_chapman<>1 THEN RAISE EXCEPTION 'FAIL NV-RECONCILE: Chapman rc 08dfb911 politician_id still NULL/missing'; END IF;
  IF v_nv_new<>6 THEN RAISE EXCEPTION 'FAIL NV-RECONCILE: % of 6 phase NV ids present (5 new + Chapman -320251)', v_nv_new; END IF;
  RAISE NOTICE 'PASS NV-RECONCILE: 4 pre-existing NV race UUIDs reused (0 new), 1 NV election, Chapman pid fixed, 5 new + Chapman ids present';

  -- ==========================================================================
  -- CRITERION 7 (NEW, ME-RECONCILE) — the 2 pre-existing ME races each carry exactly
  --   2 active candidates; no ME race outside them; exactly 1 ME election.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_me1 FROM _house WHERE race_id='d92aa73a-17db-4ba1-bfaf-46640f66f8f5' AND candidate_status='active';
  SELECT COUNT(*) INTO v_me2 FROM _house WHERE race_id='aa63d55d-80b8-42b9-9aa5-0713387f65fb' AND candidate_status='active';
  SELECT COUNT(DISTINCT race_id) INTO v_me_wrong FROM _house
  WHERE st='ME' AND race_id NOT IN ('d92aa73a-17db-4ba1-bfaf-46640f66f8f5','aa63d55d-80b8-42b9-9aa5-0713387f65fb');
  SELECT COUNT(*) INTO v_me_elec FROM essentials.elections WHERE name='2026 Maine General Election';
  IF v_me1<>2 OR v_me2<>2 OR v_me_wrong<>0 OR v_me_elec<>1 THEN
    RAISE EXCEPTION 'FAIL ME-RECONCILE: ME-1 active=% (exp 2), ME-2 active=% (exp 2), outside=% (exp 0), elections=% (exp 1)', v_me1, v_me2, v_me_wrong, v_me_elec;
  END IF;
  RAISE NOTICE 'PASS ME-RECONCILE: 2 pre-existing ME races each have exactly 2 active candidates; 0 new ME election/race';

  -- ==========================================================================
  -- CRITERION 8 (NEW, UT-REKEY) — dual-map integrity (binding 164.1-ut-wiring-contract):
  --   FIPS-49 offices per-row md5 byte-identical to the pre-migration baseline;
  --   Moore/Maloy/Kennedy re-linked is_incumbent=true onto the NEW 4902/4903/4904 races;
  --   retired Owens 0 active rows anywhere. Cloned from 1641-verify.sql D04-NOTOUCH.
  -- ==========================================================================
  SELECT md5(coalesce(string_agg(
           o.id::text || ':' || coalesce(o.district_id::text, '') || ':' || coalesce(o.representing_state, ''),
           ',' ORDER BY o.id), ''))
    INTO v_ut_md5
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type = 'NATIONAL_LOWER'
    AND length(d.geo_id) = 4
    AND substr(d.geo_id, 1, 2) = '49';
  IF v_ut_md5 <> '4d8bbfb221d4babca6e9f7201bce391e' THEN
    RAISE EXCEPTION 'FAIL UT-REKEY: FIPS-49 offices md5 % <> baseline 4d8bbfb221d4babca6e9f7201bce391e (2026-07-07) — offices were perturbed (dual-map breach)', v_ut_md5;
  END IF;
  SELECT COUNT(*) INTO v_ut_inc FROM _house
  WHERE st='UT' AND candidate_status='active' AND is_incumbent=true
    AND ( (geo_id='4902' AND politician_id='e365a1d4-2de3-4fb6-b416-d78227836553')
       OR (geo_id='4903' AND politician_id='a7983eb6-bae0-4269-856b-f4554fb5ce29')
       OR (geo_id='4904' AND politician_id='9e3164d5-ce71-4c50-9220-b969265ce551') );
  IF v_ut_inc<>3 THEN RAISE EXCEPTION 'FAIL UT-REKEY: % of 3 incumbents on their NEW district race (Moore->4902/Maloy->4903/Kennedy->4904)', v_ut_inc; END IF;
  SELECT COUNT(*) INTO v_owens FROM essentials.race_candidates
  WHERE politician_id='cb87ddbb-5a83-45b7-b67a-789e63f0e58b' AND candidate_status='active';
  IF v_owens<>0 THEN RAISE EXCEPTION 'FAIL UT-REKEY: retired Owens has % active race_candidates row(s)', v_owens; END IF;
  RAISE NOTICE 'PASS UT-REKEY: FIPS-49 offices md5 unchanged (4d8bbfb2...); Moore/Maloy/Kennedy on 4902/4903/4904; Owens 0 active rows';

  -- ==========================================================================
  -- CRITERION 9 (NEW, AK-FIELD) — the single AK jungle race has exactly 15 active
  --   candidates and primary_party IS NULL (top-four-RCV modeling).
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_ak_races FROM _house WHERE st='AK';
  SELECT COUNT(*) INTO v_ak_active FROM _house WHERE st='AK' AND candidate_status='active';
  SELECT COUNT(DISTINCT race_id) INTO v_ak_party FROM _house WHERE st='AK' AND primary_party IS NOT NULL;
  IF v_ak_races<>1 OR v_ak_active<>15 OR v_ak_party<>0 THEN
    RAISE EXCEPTION 'FAIL AK-FIELD: races=% (exp 1), active=% (exp 15), non-null primary_party races=% (exp 0)', v_ak_races, v_ak_active, v_ak_party;
  END IF;
  RAISE NOTICE 'PASS AK-FIELD: 1 jungle race, exactly 15 active candidates (14 new + Begich), primary_party NULL';

  -- ==========================================================================
  -- CRITERION 10 (PROVISIONAL) — AK/HI/NH/RI/DE/VT/WY (10 races) marked 'PROVISIONAL:';
  --   the 7 decided states NM/NE/WV/ID/MT/ND/SD (13 races) not. NV/UT/ME excluded.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_prov_missing FROM _house
  WHERE st IN ('AK','HI','NH','RI','DE','VT','WY') AND (description IS NULL OR description NOT LIKE '%PROVISIONAL:%');
  SELECT COUNT(DISTINCT race_id) INTO v_prov_leak FROM _house
  WHERE st IN ('NM','NE','WV','ID','MT','ND','SD') AND description LIKE '%PROVISIONAL:%';
  IF v_prov_missing<>0 THEN RAISE EXCEPTION 'FAIL PROVISIONAL: % late-primary race(s) missing PROVISIONAL: marker', v_prov_missing; END IF;
  IF v_prov_leak<>0 THEN RAISE EXCEPTION 'FAIL PROVISIONAL: % decided-state race(s) wrongly marked PROVISIONAL:', v_prov_leak; END IF;
  RAISE NOTICE 'PASS PROVISIONAL: AK/HI/NH/RI/DE/VT/WY (10 races) marked; NM/NE/WV/ID/MT/ND/SD (13 races) not';

  -- ==========================================================================
  -- CRITERION 11 (COLLISION-BAND) — D-04 sub-band seq floors honored for the 14
  --   collision districts. District seq = -ext - (fips*10000 + cd*100); at-large
  --   seq = -ext - fips*10000. Active NEW candidates only (is_incumbent=false).
  -- ==========================================================================
  SELECT COUNT(*), string_agg(geo_id || ':' || external_id::text, ', ' ORDER BY external_id)
    INTO v_cb, v_cb_detail
  FROM _house
  WHERE candidate_status='active' AND is_incumbent=false AND external_id IS NOT NULL
    AND ( (geo_id='3201' AND external_id BETWEEN -320199 AND -320101 AND (-external_id - 320100) < 74)
       OR (geo_id='3202' AND external_id BETWEEN -320299 AND -320201 AND (-external_id - 320200) < 51)
       OR (geo_id='3204' AND external_id BETWEEN -320499 AND -320401 AND (-external_id - 320400) < 79)
       OR (geo_id='2301' AND external_id BETWEEN -230199 AND -230101 AND (-external_id - 230100) < 3)
       OR (geo_id='2302' AND external_id BETWEEN -230299 AND -230201 AND (-external_id - 230200) < 3)
       OR (geo_id='3501' AND external_id BETWEEN -350199 AND -350101 AND (-external_id - 350100) < 26)
       OR (geo_id='3502' AND external_id BETWEEN -350299 AND -350201 AND (-external_id - 350200) < 51)
       OR (geo_id='3503' AND external_id BETWEEN -350399 AND -350301 AND (-external_id - 350300) < 82)
       OR (geo_id='3103' AND external_id BETWEEN -310399 AND -310301 AND (-external_id - 310300) < 60)
       OR (geo_id='3301' AND external_id BETWEEN -330199 AND -330101 AND (-external_id - 330100) < 33)
       OR (geo_id='3002' AND external_id BETWEEN -300299 AND -300201 AND (-external_id - 300200) < 85)
       OR (geo_id='0200' AND external_id BETWEEN -20099 AND -20001 AND (-external_id - 20000) < 5)
       OR (geo_id='1000' AND external_id BETWEEN -100099 AND -100001 AND (-external_id - 100000) < 48)
       OR (geo_id='5000' AND external_id BETWEEN -500099 AND -500001 AND (-external_id - 500000) < 6) );
  IF v_cb<>0 THEN
    RAISE EXCEPTION 'FAIL COLLISION-BAND: % new id(s) below their D-04 seq floor: %', v_cb, v_cb_detail;
  END IF;
  RAISE NOTICE 'PASS COLLISION-BAND: NV-1>=74 NV-2>=51 NV-4>=79 ME>=3 NM 26/51/82 NE-3>=60 NH-1>=33 MT-2>=85 AK>=5 DE>=48 VT>=6 floors honored';

  -- ==========================================================================
  -- New-candidate working set (Phase-165 external_id bands, ACTIVE non-incumbent,
  --   scoped via _house so polluted-band legacy records never enter).
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.st, h.politician_id, h.external_id
  FROM _house h
  WHERE h.candidate_status='active' AND h.is_incumbent=false
    AND ( (h.external_id BETWEEN -320499 AND -320101) OR (h.external_id BETWEEN -490499 AND -490101)
       OR (h.external_id BETWEEN -20099 AND -20001)   OR (h.external_id BETWEEN -350399 AND -350101)
       OR (h.external_id BETWEEN -310399 AND -310101) OR (h.external_id BETWEEN -540299 AND -540101)
       OR (h.external_id BETWEEN -160299 AND -160101) OR (h.external_id BETWEEN -150299 AND -150101)
       OR (h.external_id BETWEEN -230299 AND -230101) OR (h.external_id BETWEEN -330299 AND -330101)
       OR (h.external_id BETWEEN -440299 AND -440101) OR (h.external_id BETWEEN -300299 AND -300101)
       OR (h.external_id BETWEEN -100099 AND -100001) OR (h.external_id BETWEEN -380099 AND -380001)
       OR (h.external_id BETWEEN -460099 AND -460001) OR (h.external_id BETWEEN -500099 AND -500001)
       OR (h.external_id BETWEEN -560099 AND -560001) );

  -- ==========================================================================
  -- Whole-record stance honest-skip pins (_stance_skip, ORDER BY politician_id).
  --   NV 2 / UT 2 / AK 5 / WV 2 / ID 2 / HI 2 / WY 3 = 18. Trails: 165-09..16-SUMMARY.md.
  -- ==========================================================================
  CREATE TEMP TABLE _stance_skip (politician_id uuid, external_id bigint, reason text) ON COMMIT DROP;
  INSERT INTO _stance_skip (politician_id, external_id, reason)
  SELECT p.id, p.external_id, v.reason
  FROM (VALUES
    (-320479::bigint, 'Russell Best NV-4 -- perennial IAP filer, dead domain, blank questionnaires, $6k lifetime'),
    (-320480, 'William Johnson NV-4 -- no-party filer, no FEC/site/social/news anywhere'),
    (-490203, 'Robert M. Moesinger UT-2 -- single-issue electoral-structure platform, maps to no tracked scale'),
    (-490304, 'Michael R. Stoddard UT-3 -- audits/sound-money/militia planks map to no tracked scale'),
    (-20007,  'John E. Foddrill Sr. AK -- TX whistleblower content only, no policy positions'),
    (-20012,  'Yaquelin Reynoso AK -- out-of-state MA filer, zero policy content'),
    (-20013,  'David Richey AK -- in-state but logistics-only coverage, no positions'),
    (-20014,  'Melanie A. Salazar AK -- out-of-state SF filer, explicit no-positions pages'),
    (-20017,  'John B. Williams AK -- Fairbanks teacher, filed-only, zero policy quotes'),
    (-540202, 'Pat Carney WV-2 -- $0-raised fringe filer (FEC H6WV02176), zero footprint'),
    (-540203, 'Chris Whitcomb WV-2 -- $0-raised fringe filer (FEC H6WV02168), zero footprint'),
    (-160102, 'Brendan Gomez ID-1 -- $0 FEC, no survey across 3 cycles, meme-only social'),
    (-160203, 'Carta Sierra ID-2 -- perennial candidate (legal name Idaho Law), zero policy content'),
    (-150205, 'Edward Codelia HI-2 -- survey answered but mechanism-free, no placeable chair'),
    (-150206, 'Randall Terry HI-2 -- identity unresolved vs national activist; HI-local sources silent'),
    (-560005, 'Richard Dodson WY -- Candidate Connection answered but entirely non-directional'),
    (-560011, 'Elena Del Real WY -- bio-only presence, no policy content anywhere'),
    (-560013, 'Daniel Workman WY -- FEC filer (H6WY01108), zero policy content')
  ) AS v(external_id, reason)
  JOIN essentials.politicians p ON p.external_id = v.external_id
  ORDER BY p.id;

  -- ==========================================================================
  -- Headshot honest-skip pins (_img_skip, ORDER BY external_id). 109 of 117 banded
  --   active challengers (8 uploaded). Reconstructed live 2026-07-07.
  -- ==========================================================================
  CREATE TEMP TABLE _img_skip (external_id bigint) ON COMMIT DROP;
  INSERT INTO _img_skip (external_id) VALUES
    (-560013),(-560012),(-560011),(-560010),(-560009),(-560008),(-560007),(-560006),
    (-560005),(-560004),(-560003),(-540203),(-540202),(-540201),(-540102),(-540101),
    (-500008),(-500007),(-500006),(-490402),(-490401),(-490304),(-490303),(-490302),
    (-490301),(-490203),(-490202),(-490201),(-490103),(-490102),(-490101),(-460001),
    (-440202),(-440201),(-440102),(-440101),(-380001),(-350382),(-350251),(-350126),
    (-330204),(-330203),(-330202),(-330201),(-330146),(-330145),(-330144),(-330143),
    (-330142),(-330141),(-330139),(-330138),(-330137),(-330136),(-330135),(-330134),
    (-330133),(-320480),(-320479),(-320301),(-320251),(-320175),(-320174),(-310361),
    (-310360),(-310203),(-310202),(-310201),(-310102),(-310101),(-300286),(-300285),
    (-300103),(-300101),(-230103),(-160205),(-160204),(-160203),(-160202),(-160201),
    (-160103),(-160102),(-160101),(-150206),(-150205),(-150203),(-150202),(-150201),
    (-150107),(-150106),(-150105),(-150104),(-150102),(-150101),(-100048),(-20018),
    (-20017),(-20016),(-20015),(-20014),(-20013),(-20012),(-20011),(-20010),
    (-20009),(-20008),(-20007),(-20006),(-20005)
  ;

  -- ==========================================================================
  -- USHC3-04 — every active banded new candidate has a politician_images row,
  --   except pinned skips (109 of 117; 8 uploaded: Keohokalole/Awa/Dunlap/Forstag/
  --   Sullivan/Tang Williams/Balow/Biteman). Reconstructed live 2026-07-07.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(nc.st || ':' || nc.external_id, ', ' ORDER BY nc.external_id)
    INTO v_no_image, v_image_detail
  FROM _new_cands nc
  WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id)
    AND nc.external_id NOT IN (SELECT external_id FROM _img_skip);
  IF v_no_image<>0 THEN
    RAISE EXCEPTION 'FAIL HEADSHOT: % active new candidate(s) lack an image and are not pinned: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS HEADSHOT: every active banded new candidate has a politician_images row or a pinned honest-skip (109 pinned)';

  -- ==========================================================================
  -- USHC3-05a — 0 unsourced stance rows for ALL active in-scope politicians
  --   (race-scoped, so polluted-band legacy records e.g. Trevor Lee never enter).
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
  RAISE NOTICE 'PASS UNSOURCED: 0 unsourced stance rows for the in-scope 17-state candidate set';

  -- ==========================================================================
  -- USHC3-05b — every banded NEW candidate has >=1 sourced stance OR is a pinned skip.
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
  RAISE NOTICE 'PASS COVERAGE: every banded new candidate has >=1 sourced stance or a pinned whole-record skip (18 pinned)';

  -- ==========================================================================
  -- USHC3-05c (NEW, UUID-COVERAGE) — Pingree (zero-tier incumbent, -230201) and the
  --   6 UUID-keyed reused pids (McAdams/Crosby/Udell/Larsen UT primary winners;
  --   Gray WY-SoS; Jackley SD-AG) each have >=1 sourced stance.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(v.who, ', ')
    INTO v_uuid_cov, v_uuid_detail
  FROM (VALUES
    ('1638b2c9-4811-466d-bb24-44c6cece8cda'::uuid, 'Pingree ME-1'),
    ('b78f058c-94de-4081-91fb-86ab7badb2fb', 'McAdams UT-1'),
    ('e3cbc264-534e-4e47-a288-8ac389bf78f4', 'Crosby UT-2'),
    ('a7e29796-a928-49cc-b795-973a4f69fafe', 'Udell UT-3'),
    ('6708ceaa-ae51-4eee-93a3-d4a3be16254d', 'Larsen UT-4'),
    ('b503b679-773a-4eee-9c16-e73bff1a723f', 'Gray WY'),
    ('2537050a-cd40-460e-9751-1d982dd73c25', 'Jackley SD')
  ) AS v(pid, who)
  WHERE (SELECT COUNT(*) FROM inform.politician_answers a WHERE a.politician_id = v.pid) < 1;
  IF v_uuid_cov<>0 THEN
    RAISE EXCEPTION 'FAIL UUID-COVERAGE: % UUID-keyed target(s) have 0 stances: %', v_uuid_cov, v_uuid_detail;
  END IF;
  RAISE NOTICE 'PASS UUID-COVERAGE: Pingree + McAdams/Crosby/Udell/Larsen/Gray/Jackley each have >=1 sourced stance';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC3-02/03/04/05, 34 districts across 17 states; NV-RECONCILE + ME-RECONCILE + UT-REKEY + AK-FIELD + PROVISIONAL + COLLISION-BAND verified; NV/ME-RECONCILE + UT-REKEY are standing invariants for the Phase 166 gate)';
END $$;
