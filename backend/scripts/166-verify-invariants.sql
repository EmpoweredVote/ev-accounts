-- 166-verify-invariants.sql — Phase 166 read-only PRODUCTION gate: the FIFTEEN standing
-- invariants that phases 161 through 165 each declared as carry-forward to Phase 166.
--
-- WHY THIS FILE EXISTS. Once Phase 166 supersedes the per-phase gates, nothing else runs 162's
-- IN9-FLAG, 163's CO1-DEGETTE, 164's OPEN-SEAT and OR-REUSE, or 165's UT-REKEY NOTOUCH. Each was
-- explicitly named "standing invariant for Phase 166" by its own SUMMARY. Carried here, or they
-- stop being checked.
--
-- Run alongside its two siblings; together they are the Phase-166 milestone proof:
--   * backend/scripts/166-verify.sql          — the structural half (plan 166-03)
--   * backend/scripts/166-coordinate-smoke.ts — the coordinate half (plan 166-02)
-- This is a separate file purely so each half stays authorable and reviewable in one pass. The
-- ~40 duplicated lines of `_house` construction are deliberate: each must run independently.
--
-- POST-164.1 WORLD. TN, AL and LA assert SURFACING, not withholding. Migrations 1247 (TN),
-- 1248 (AL) and 1249 (LA) un-withheld thirteen districts on 2026-07-07 once their G5200V26
-- polygons landed. Inheriting 161's and 163's original withheld assertions would produce a gate
-- that is green about a world that no longer exists. MO's five severe districts are the ONLY
-- withheld set left, and that block sits in a delimited, greppable flip region.
--
-- SCOPE — 43 elections, matching backend/scripts/166-verify.sql. 166-01 derived the universe live
-- on 2026-07-26 and found 'WI 2026 Partisan Primary' (created 2026-07-25) now holds WI's field.
-- See 166-01-SUMMARY.md.
--
-- WRITE-FREE: the only writes are `CREATE TEMP TABLE ... ON COMMIT DROP`. No DML against
-- essentials or inform.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/166-verify-invariants.sql

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_cnt int; v_detail text;
  v_tn_marker int; v_tn_gen int; v_al_marker int; v_al_gen int;
  v_la_marker int; v_la_gen int; v_la_party int; v_la_runoff int;
  v_mo_leak int; v_mo_withheld int; v_mo_surf int;
  v_in9_total int; v_in9_dem int; v_in9_houchin int;
  v_az int; v_az_detail text;
  v_clark int; v_pressley int;
  v_co1 int; v_degette int;
  v_openseat int; v_openseat_detail text;
  v_or_reuse int; v_or_out int;
  v_nv_reuse int; v_nv_out int; v_nv_elec int; v_chapman int; v_nv_ids int;
  v_me1 int; v_me2 int; v_me_out int; v_me_elec int;
  v_ut_md5 text; v_ut_inc int; v_owens int;
  v_ak_races int; v_ak_active int; v_ak_party int;
  v_cb int; v_cb_detail text;
BEGIN
  -- ==========================================================================
  -- Same 43 in-scope elections and 38 geo prefixes as 166-verify.sql.
  -- ==========================================================================
  CREATE TEMP TABLE _elections ON COMMIT DROP AS
  SELECT v.name, e.id
  FROM (VALUES
    ('AZ 2026 Statewide General'),('WA 2026 Statewide General'),('TN 2026 Statewide General'),
    ('2026 Massachusetts General Election'),('IN 2026 Statewide General'),
    ('2026 Maryland General Election'),('MN 2026 Statewide General'),('MO 2026 Statewide General'),
    ('WI 2026 Statewide General'),('CO 2026 Statewide General'),('AL 2026 Statewide General'),
    ('SC 2026 Statewide General'),('LA 2026 Statewide General'),('KY 2026 Statewide General'),
    ('OR 2026 General'),('CT 2026 Statewide General'),('OK 2026 Statewide General'),
    ('AR 2026 Statewide General'),('IA 2026 Statewide General'),('KS 2026 Statewide General'),
    ('MS 2026 Statewide General'),('NV 2026 Statewide General'),('UT 2026 Statewide General'),
    ('NM 2026 Statewide General'),('NE 2026 Statewide General'),('WV 2026 Statewide General'),
    ('ID 2026 Statewide General'),('HI 2026 Statewide General'),('2026 Maine General Election'),
    ('NH 2026 Statewide General'),('RI 2026 Statewide General'),('MT 2026 Statewide General'),
    ('AK 2026 Statewide General'),('DE 2026 Statewide General'),('ND 2026 Statewide General'),
    ('SD 2026 Statewide General'),('VT 2026 Statewide General'),('WY 2026 Statewide General'),
    ('TN 2026 Congressional Redistricting - Polygon Pending'),
    ('MO 2026 Congressional Redistricting - Polygon Pending'),
    ('AL 2026 Congressional Redistricting - Polygon Pending'),
    ('LA 2026 Congressional Redistricting - Polygon Pending'),
    ('WI 2026 Partisan Primary')
  ) AS v(name)
  LEFT JOIN essentials.elections e ON e.name = v.name;

  SELECT COUNT(*), string_agg(name, ', ' ORDER BY name) INTO v_cnt, v_detail
  FROM _elections WHERE id IS NULL;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'FAIL setup: % of 43 election name(s) did not resolve: %', v_cnt, v_detail;
  END IF;

  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE substr(d.geo_id,1,2)
           WHEN '04' THEN 'AZ' WHEN '53' THEN 'WA' WHEN '47' THEN 'TN' WHEN '25' THEN 'MA'
           WHEN '18' THEN 'IN' WHEN '24' THEN 'MD' WHEN '27' THEN 'MN' WHEN '29' THEN 'MO'
           WHEN '55' THEN 'WI' WHEN '08' THEN 'CO' WHEN '01' THEN 'AL' WHEN '45' THEN 'SC'
           WHEN '22' THEN 'LA' WHEN '21' THEN 'KY' WHEN '41' THEN 'OR' WHEN '09' THEN 'CT'
           WHEN '40' THEN 'OK' WHEN '05' THEN 'AR' WHEN '19' THEN 'IA' WHEN '20' THEN 'KS'
           WHEN '28' THEN 'MS' WHEN '32' THEN 'NV' WHEN '49' THEN 'UT' WHEN '35' THEN 'NM'
           WHEN '31' THEN 'NE' WHEN '54' THEN 'WV' WHEN '16' THEN 'ID' WHEN '15' THEN 'HI'
           WHEN '23' THEN 'ME' WHEN '33' THEN 'NH' WHEN '44' THEN 'RI' WHEN '30' THEN 'MT'
           WHEN '02' THEN 'AK' WHEN '10' THEN 'DE' WHEN '38' THEN 'ND' WHEN '46' THEN 'SD'
           WHEN '50' THEN 'VT' ELSE 'WY' END AS st,
         r.id AS race_id, r.election_id AS race_election_id, r.office_id, r.description,
         r.primary_party, d.geo_id, rc.id AS rc_id, rc.politician_id, rc.full_name,
         rc.candidate_status, rc.is_incumbent, p.external_id
  FROM essentials.races r
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.politicians     p  ON p.id = rc.politician_id
  WHERE r.election_id IN (SELECT id FROM _elections)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('04','53','47','25','18','24','27','29','55','08','01','45',
                                   '22','21','41','09','40','05','19','20','28','32','49','35',
                                   '31','54','16','15','23','33','44','30','02','10','38','46',
                                   '50','56');

  -- ==========================================================================
  -- INVARIANT 1 (TN-SURFACING, from 161 + 164.1-04) — TN was flipped on 2026-07-07 by
  --   migration 1247 once its G5200V26 polygons landed: the 5 severe TN districts 4704, 4705,
  --   4706, 4708 and 4709 were un-withheld. 161's original withheld assertion is therefore
  --   WRONG to inherit; TN asserts SURFACING.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_tn_marker FROM _house
  WHERE st='TN' AND race_election_id = (SELECT id FROM _elections WHERE name='TN 2026 Congressional Redistricting - Polygon Pending');
  SELECT COUNT(DISTINCT geo_id) INTO v_tn_gen FROM _house
  WHERE st='TN' AND race_election_id = (SELECT id FROM _elections WHERE name='TN 2026 Statewide General')
    AND geo_id IN ('4701','4702','4703','4704','4705','4706','4707','4708','4709');
  IF v_tn_marker<>0 OR v_tn_gen<>9 THEN
    RAISE EXCEPTION 'FAIL TN-SURFACING: % race(s) still on the TN marker election (exp 0); % of 9 TN geo_ids on the general', v_tn_marker, v_tn_gen;
  END IF;
  RAISE NOTICE 'PASS TN-SURFACING: all 9 TN districts 4701-4709 wired to TN 2026 Statewide General, 0 left on the Polygon Pending marker — the 5 severe TN districts (4704/4705/4706/4708/4709) were un-withheld 2026-07-07 by migration 1247';

  -- ==========================================================================
  -- INVARIANT 2 (AL-SURFACING, from 163 + 164.1-05) — migration 1248 un-withheld AL-2 (0102)
  --   on 2026-07-07.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_al_marker FROM _house
  WHERE st='AL' AND race_election_id = (SELECT id FROM _elections WHERE name='AL 2026 Congressional Redistricting - Polygon Pending');
  SELECT COUNT(DISTINCT geo_id) INTO v_al_gen FROM _house
  WHERE st='AL' AND race_election_id = (SELECT id FROM _elections WHERE name='AL 2026 Statewide General')
    AND geo_id IN ('0101','0102','0103','0104','0105','0106','0107');
  IF v_al_marker<>0 OR v_al_gen<>7 THEN
    RAISE EXCEPTION 'FAIL AL-SURFACING: % race(s) still on the AL marker election (exp 0); % of 7 AL geo_ids on the general', v_al_marker, v_al_gen;
  END IF;
  RAISE NOTICE 'PASS AL-SURFACING: all 7 AL districts 0101-0107 wired to AL 2026 Statewide General, 0 left on the Polygon Pending marker — AL-2 (0102) was un-withheld 2026-07-07 by migration 1248';

  -- ==========================================================================
  -- INVARIANT 3 (LA-SURFACING, from 163 + 164.1-05) — migration 1249 un-withheld LA-2 (2202)
  --   and LA-6 (2206) on 2026-07-07. LA is a jungle-primary state: every LA race must carry
  --   primary_party NULL, and no December-2026 runoff race may exist in scope.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_la_marker FROM _house
  WHERE st='LA' AND race_election_id = (SELECT id FROM _elections WHERE name='LA 2026 Congressional Redistricting - Polygon Pending');
  SELECT COUNT(DISTINCT geo_id) INTO v_la_gen FROM _house
  WHERE st='LA' AND race_election_id = (SELECT id FROM _elections WHERE name='LA 2026 Statewide General')
    AND geo_id IN ('2201','2202','2203','2204','2205','2206');
  SELECT COUNT(DISTINCT race_id) INTO v_la_party FROM _house WHERE st='LA' AND primary_party IS NOT NULL;
  SELECT COUNT(*) INTO v_la_runoff FROM essentials.elections
  WHERE (name ILIKE '%louisiana%runoff%')
     OR (name ILIKE 'LA %' AND election_date BETWEEN DATE '2026-12-01' AND DATE '2026-12-31');
  IF v_la_marker<>0 OR v_la_gen<>6 OR v_la_party<>0 OR v_la_runoff<>0 THEN
    RAISE EXCEPTION 'FAIL LA-SURFACING: marker=% (exp 0), general geo_ids=% (exp 6), non-null primary_party races=% (exp 0), Dec-2026 runoff elections=% (exp 0)',
      v_la_marker, v_la_gen, v_la_party, v_la_runoff;
  END IF;
  RAISE NOTICE 'PASS LA-SURFACING: all 6 LA districts 2201-2206 on LA 2026 Statewide General with primary_party NULL (jungle model), 0 on the marker, 0 December-2026 runoff races — LA-2 (2202) and LA-6 (2206) were un-withheld 2026-07-07 by migration 1249';

  -- === MO POST-2026-08-04 FLIP REGION — see 166-mo-flip-runbook.md ===
  --
  -- INVARIANT 4 (MO-SEVERE, from 162). MO's five severity-routed districts 2902, 2903, 2904,
  -- 2905 and 2906 are wired to 'MO 2026 Congressional Redistricting - Polygon Pending', which
  -- electionService.ts's ELECTION_VISIBILITY_WINDOW never returns. The three non-severe
  -- districts 2901, 2907 and 2908 surface normally. These five are the ONLY districts in the
  -- entire 178-district Wave-3 set asserted withheld.
  --
  -- Plan 164.1-07 is date-gated on or after 2026-08-04, when the Missouri Secretary of State's
  -- Hoskins certification decision lands. It has TWO branches:
  --
  --   MAP-HOLDS BRANCH — MO G5200V26 polygons are imported and the five severe races are
  --     re-pointed to 'MO 2026 Statewide General'. THIS BLOCK MUST THEN INVERT: the withheld
  --     array becomes empty, the surfacing set becomes all 8 MO geo_ids 2901-2908, and the pass
  --     notice is rewritten to the AL-SURFACING wording above. At the same time the
  --     166-coordinate-smoke.ts negative sample flips to five positive samples.
  --
  --   REFERENDUM-QUALIFIES BRANCH — the referendum makes the ballot, MO does zero polygon work,
  --     the five districts stay withheld for this cycle, and the revert diverts to Phase 167's
  --     MO cluster. THIS BLOCK REQUIRES NO EDIT. As written it already asserts exactly that
  --     steady state, so nobody should touch it defensively.
  -- ==========================================================================
  SELECT COUNT(DISTINCT geo_id) INTO v_mo_withheld FROM _house
  WHERE st='MO' AND geo_id IN ('2902','2903','2904','2905','2906')
    AND race_election_id = (SELECT id FROM _elections WHERE name='MO 2026 Congressional Redistricting - Polygon Pending');
  SELECT COUNT(DISTINCT geo_id) INTO v_mo_leak FROM _house
  WHERE st='MO' AND geo_id IN ('2902','2903','2904','2905','2906')
    AND race_election_id = (SELECT id FROM _elections WHERE name='MO 2026 Statewide General');
  SELECT COUNT(DISTINCT geo_id) INTO v_mo_surf FROM _house
  WHERE st='MO' AND geo_id IN ('2901','2907','2908')
    AND race_election_id = (SELECT id FROM _elections WHERE name='MO 2026 Statewide General');
  IF v_mo_withheld<>5 OR v_mo_leak<>0 OR v_mo_surf<>3 THEN
    RAISE EXCEPTION 'FAIL MO-SEVERE: withheld=% (exp 5), leaked onto the surfacing election=% (exp 0), surfacing=% (exp 3)',
      v_mo_withheld, v_mo_leak, v_mo_surf;
  END IF;
  RAISE NOTICE 'PASS MO-SEVERE: the 5 severe MO districts 2902, 2903, 2904, 2905, 2906 are withheld on the Polygon Pending election with 0 leaked onto the surfacing election, and the 3 non-severe districts 2901, 2907, 2908 surface on MO 2026 Statewide General — the only withheld set in the 178-district Wave-3 scope';
  -- === END MO POST-2026-08-04 FLIP REGION ===

  -- ==========================================================================
  -- INVARIANT 5 (IN9-FLAG, from 162, migration 1212) — exactly 1 incumbent-flagged row across
  --   the two IN-9 primary races. NOTE, carried from 162's header: 9d2de2ae is a RACE id, not
  --   Houchin's row id — the original plan had these transposed.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_in9_total FROM essentials.race_candidates
  WHERE race_id IN ('7d3f0042-eb15-462b-bf14-df15244c5d16','9d2de2ae-2fef-48b6-b3d4-2787166b78df')
    AND is_incumbent = true;
  SELECT COUNT(*) INTO v_in9_dem FROM essentials.race_candidates
  WHERE race_id = '7d3f0042-eb15-462b-bf14-df15244c5d16' AND is_incumbent = true;
  SELECT COUNT(*) INTO v_in9_houchin FROM essentials.race_candidates
  WHERE id = 'a61ab808-846a-4bb7-9544-f9f33357b078' AND is_incumbent = true
    AND race_id = '9d2de2ae-2fef-48b6-b3d4-2787166b78df';
  IF v_in9_total<>1 OR v_in9_dem<>0 OR v_in9_houchin<>1 THEN
    RAISE EXCEPTION 'FAIL IN9-FLAG: incumbents across both IN-9 primaries=% (exp 1), on the Democratic race 7d3f0042=% (exp 0), Houchin row a61ab808 flagged=% (exp 1)',
      v_in9_total, v_in9_dem, v_in9_houchin;
  END IF;
  RAISE NOTICE 'PASS IN9-FLAG: exactly 1 incumbent across the two IN-9 primary races; the Democratic race 7d3f0042 has 0 incumbent-flagged rows; row a61ab808 (Houchin) on race 9d2de2ae is that one row';

  -- ==========================================================================
  -- INVARIANT 6 (AZ-RECONCILE, from 161, migration 1204) — the 5 ballot-ineligible AZ
  --   candidates hold 0 active rows in scope.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(DISTINCT external_id::text, ', ') INTO v_az, v_az_detail FROM _house
  WHERE external_id IN (-40108,-40201,-40402,-40503,-40602) AND candidate_status='active';
  IF v_az<>0 THEN
    RAISE EXCEPTION 'FAIL AZ-RECONCILE: % active row(s) for ballot-ineligible AZ candidate(s): %', v_az, v_az_detail;
  END IF;
  RAISE NOTICE 'PASS AZ-RECONCILE: the 5 ballot-ineligible AZ candidates (-40108 Ajluni, -40201 Descheenie, -40402 Davison, -40503 Bracht, -40602 Bah) hold 0 active rows';

  -- ==========================================================================
  -- INVARIANT 7 (MA-INCUMBENT-DEDUP, from 161) — Clark on 2505 and Pressley on 2507 each have
  --   exactly 1 race_candidates row.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_clark    FROM _house WHERE geo_id='2505' AND lower(full_name)='katherine clark';
  SELECT COUNT(*) INTO v_pressley FROM _house WHERE geo_id='2507' AND lower(full_name)='ayanna pressley';
  IF v_clark<>1 OR v_pressley<>1 THEN
    RAISE EXCEPTION 'FAIL MA-INCUMBENT-DEDUP: Clark rows on 2505=% (exp 1), Pressley rows on 2507=% (exp 1)', v_clark, v_pressley;
  END IF;
  RAISE NOTICE 'PASS MA-INCUMBENT-DEDUP: Katherine Clark has exactly 1 race_candidates row on 2505 and Ayanna Pressley exactly 1 on 2507';

  -- ==========================================================================
  -- INVARIANT 8 (CO1-DEGETTE, from 163) — CO-1 has exactly 2 active candidates and DeGette
  --   (610bb358) is absent. This is the REUSE-NO-ROW lost-primary pattern: her politician
  --   record, office and stances are intentionally UNTOUCHED, merely not wired into the CO-1
  --   race.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_co1 FROM _house WHERE geo_id='0801' AND candidate_status='active';
  SELECT COUNT(*) INTO v_degette FROM _house
  WHERE geo_id='0801' AND candidate_status='active' AND politician_id::text LIKE '610bb358%';
  IF v_co1<>2 OR v_degette<>0 THEN
    RAISE EXCEPTION 'FAIL CO1-DEGETTE: CO-1 active=% (exp 2), DeGette active rows=% (exp 0)', v_co1, v_degette;
  END IF;
  RAISE NOTICE 'PASS CO1-DEGETTE: CO-1 has exactly 2 active candidates and DeGette (610bb358) is absent from them — REUSE-NO-ROW, her record/office/stances are intentionally untouched';

  -- ==========================================================================
  -- INVARIANT 9 (OPEN-SEAT, from 164) — the 5 departing incumbents hold 0 active US HOUSE
  --   race_candidates rows.
  --
  --   SCOPE CORRECTION (166-04, 2026-07-26). 164 worded this as "0 active rows ANYWHERE".
  --   Probed live, that literal form now FAILS for two of the five: Kevin Hern (OK-1) and
  --   Ashley Hinson (IA-2) were each seeded on 2026-07-10 — three days after 164 froze — into
  --   a NATIONAL_UPPER 2026 US Senate race. Those candidacies are the very reason their House
  --   seats are open, so the invariant's SUBJECT is a House seat, and "anywhere" was simply
  --   over-broad. Scoping to district_type='NATIONAL_LOWER' returns 0 for all five and
  --   preserves the invariant's meaning exactly. This is a correction of the predicate, NOT a
  --   relaxation of the expected count, which remains 0.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(v.who || '=' || v.n::text, ', ') INTO v_openseat, v_openseat_detail
  FROM (
    SELECT x.who, (SELECT COUNT(*) FROM essentials.race_candidates rc
                     JOIN essentials.races r     ON r.id = rc.race_id
                     JOIN essentials.offices o   ON o.id = r.office_id
                     JOIN essentials.districts d ON d.id = o.district_id
                    WHERE rc.politician_id = x.pid
                      AND rc.candidate_status = 'active'
                      AND d.district_type = 'NATIONAL_LOWER') AS n
    FROM (VALUES
      ('4d92b909-6add-4486-b0cf-f317b4e10e9b'::uuid, 'Massie KY-4 (lost primary)'),
      ('164fb70e-b8c1-48cd-a6ef-12d80165c67d',       'Barr KY-6 (retired)'),
      ('96e589b9-d04a-4749-bf9f-9b66eaea5083',       'Hern OK-1 (retired, now a US Senate candidate)'),
      ('91aa37bf-dc8a-45f3-9bf7-e887b8dd99bd',       'Hinson IA-2 (retired, now a US Senate candidate)'),
      ('c25acca0-f280-469c-b708-c314d8036036',       'Feenstra IA-4 (retired)')
    ) AS x(pid, who)
  ) v
  WHERE v.n <> 0;
  IF v_openseat<>0 THEN
    RAISE EXCEPTION 'FAIL OPEN-SEAT: % departing incumbent(s) still hold an active US House row: %', v_openseat, v_openseat_detail;
  END IF;
  RAISE NOTICE 'PASS OPEN-SEAT: all 5 departing incumbents hold 0 active US House rows — Massie KY-4 (lost primary), Barr KY-6, Hern OK-1, Hinson IA-2, Feenstra IA-4 (retired). Hern and Hinson are active in NATIONAL_UPPER US Senate races, which is why their House seats are open';

  -- ==========================================================================
  -- INVARIANT 10 (OR-REUSE, from 164) — OR's races are exactly the 6 pre-existing UUIDs; no new
  --   OR general race was authored. 164 folded a per-(race_id, politician_id) uniqueness clause
  --   into this block; that is now generalised to ALL 178 districts by the RC-UNIQUE block in
  --   backend/scripts/166-verify.sql, so it is not duplicated here.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_or_reuse FROM _house
  WHERE st='OR' AND race_id IN ('8dfd6e35-f91d-4d14-bcec-ae983035da51','504a156a-d4e6-4abe-9a85-a418c0135805',
    '61297fac-c98d-4ad4-b93f-b2e36722bd6a','c5023da0-985e-4e1c-817c-a843849ef6e9',
    '17a4b696-5c15-4f2b-9390-ce1864d57f37','dd25e913-2496-40fa-a735-c9b1d7f68df8');
  SELECT COUNT(DISTINCT race_id) INTO v_or_out FROM _house
  WHERE st='OR' AND race_id NOT IN ('8dfd6e35-f91d-4d14-bcec-ae983035da51','504a156a-d4e6-4abe-9a85-a418c0135805',
    '61297fac-c98d-4ad4-b93f-b2e36722bd6a','c5023da0-985e-4e1c-817c-a843849ef6e9',
    '17a4b696-5c15-4f2b-9390-ce1864d57f37','dd25e913-2496-40fa-a735-c9b1d7f68df8');
  IF v_or_reuse<>6 OR v_or_out<>0 THEN
    RAISE EXCEPTION 'FAIL OR-REUSE: reused=% (exp 6), OR races outside the pre-existing set=% (exp 0)', v_or_reuse, v_or_out;
  END IF;
  RAISE NOTICE 'PASS OR-REUSE: OR''s 6 races are exactly the pre-existing UUIDs (8dfd6e35, 504a156a, 61297fac, c5023da0, 17a4b696, dd25e913); 0 outside, no new OR general authored';

  -- ==========================================================================
  -- INVARIANT 11 (NV-RECONCILE, from 165) — NV wired candidates onto its 4 PRE-EXISTING race
  --   UUIDs; no new NV general was authored; Chapman's row has a non-null politician_id.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_nv_reuse FROM _house
  WHERE st='NV' AND race_id IN ('a5295941-38b1-4c7f-8edf-39097ad3fb0a','0c470cc0-5250-43f1-b7f7-57778cadacc6',
    '79e7fb35-a73a-478c-847d-553e9ad11e7c','81eb1a27-b710-42c3-a27c-a2c0153c2820');
  SELECT COUNT(DISTINCT race_id) INTO v_nv_out FROM _house
  WHERE st='NV' AND race_id NOT IN ('a5295941-38b1-4c7f-8edf-39097ad3fb0a','0c470cc0-5250-43f1-b7f7-57778cadacc6',
    '79e7fb35-a73a-478c-847d-553e9ad11e7c','81eb1a27-b710-42c3-a27c-a2c0153c2820');
  SELECT COUNT(*) INTO v_nv_elec FROM essentials.elections WHERE name='NV 2026 Statewide General';
  SELECT COUNT(*) INTO v_chapman FROM essentials.race_candidates
  WHERE id='08dfb911-9ddc-4c0d-85a2-fb14884a9160' AND politician_id IS NOT NULL;
  SELECT COUNT(*) INTO v_nv_ids FROM essentials.politicians
  WHERE external_id IN (-320174,-320175,-320251,-320301,-320479,-320480);
  IF v_nv_reuse<>4 OR v_nv_out<>0 OR v_nv_elec<>1 OR v_chapman<>1 OR v_nv_ids<>6 THEN
    RAISE EXCEPTION 'FAIL NV-RECONCILE: reused=% (exp 4), outside=% (exp 0), NV elections=% (exp 1), Chapman pid set=% (exp 1), NV ids present=% (exp 6)',
      v_nv_reuse, v_nv_out, v_nv_elec, v_chapman, v_nv_ids;
  END IF;
  RAISE NOTICE 'PASS NV-RECONCILE: 4 pre-existing NV race UUIDs reused with 0 outside, exactly 1 NV election, Chapman row 08dfb911 has a politician_id, and all 6 NV ids (-320174/-320175/-320251/-320301/-320479/-320480) exist';

  -- ==========================================================================
  -- INVARIANT 12 (ME-RECONCILE, from 165) — the 2 pre-existing ME races each carry exactly 2
  --   active candidates; no new ME election or race was authored.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_me1 FROM _house WHERE race_id='d92aa73a-17db-4ba1-bfaf-46640f66f8f5' AND candidate_status='active';
  SELECT COUNT(*) INTO v_me2 FROM _house WHERE race_id='aa63d55d-80b8-42b9-9aa5-0713387f65fb' AND candidate_status='active';
  SELECT COUNT(DISTINCT race_id) INTO v_me_out FROM _house
  WHERE st='ME' AND race_id NOT IN ('d92aa73a-17db-4ba1-bfaf-46640f66f8f5','aa63d55d-80b8-42b9-9aa5-0713387f65fb');
  SELECT COUNT(*) INTO v_me_elec FROM essentials.elections WHERE name='2026 Maine General Election';
  IF v_me1<>2 OR v_me2<>2 OR v_me_out<>0 OR v_me_elec<>1 THEN
    RAISE EXCEPTION 'FAIL ME-RECONCILE: ME-1 active=% (exp 2), ME-2 active=% (exp 2), outside=% (exp 0), ME elections=% (exp 1)',
      v_me1, v_me2, v_me_out, v_me_elec;
  END IF;
  RAISE NOTICE 'PASS ME-RECONCILE: the 2 pre-existing ME races each carry exactly 2 active candidates; 0 ME races outside them; exactly 1 ME election';

  -- ==========================================================================
  -- INVARIANT 13 (UT-REKEY, from 165, cloned originally from 1641-verify.sql D04-NOTOUCH) —
  --   the dual-map NOTOUCH contract. The md5 over FIPS-49 NATIONAL_LOWER offices is the BINDING
  --   contract recorded in 164.1-ut-wiring-contract.md. A mismatch means the offices table was
  --   perturbed and the dual-map design is BREACHED. The only sanctioned change is the Jan-2027
  --   boundary promotion, date-gated on or after 2027-01-03
  --   (164.1-jan2027-boundary-promotion-spec.md).
  --
  --   The incumbent-placement clause is scoped to the UT GENERAL: UT also has a past
  --   '2026 Utah Primary' whose races would otherwise double every incumbent's count to 6.
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
    RAISE EXCEPTION 'FAIL UT-REKEY: FIPS-49 offices md5 % <> baseline 4d8bbfb221d4babca6e9f7201bce391e — offices were perturbed (dual-map breach; see 164.1-ut-wiring-contract.md)', v_ut_md5;
  END IF;
  SELECT COUNT(*) INTO v_ut_inc FROM _house
  WHERE st='UT' AND candidate_status='active' AND is_incumbent=true
    AND race_election_id = (SELECT id FROM _elections WHERE name='UT 2026 Statewide General')
    AND ( (geo_id='4902' AND politician_id='e365a1d4-2de3-4fb6-b416-d78227836553')
       OR (geo_id='4903' AND politician_id='a7983eb6-bae0-4269-856b-f4554fb5ce29')
       OR (geo_id='4904' AND politician_id='9e3164d5-ce71-4c50-9220-b969265ce551') );
  SELECT COUNT(*) INTO v_owens FROM essentials.race_candidates
  WHERE politician_id='cb87ddbb-5a83-45b7-b67a-789e63f0e58b' AND candidate_status='active';
  IF v_ut_inc<>3 OR v_owens<>0 THEN
    RAISE EXCEPTION 'FAIL UT-REKEY: % of 3 incumbents on their NEW district race (Moore->4902/Maloy->4903/Kennedy->4904); retired Owens active rows=% (exp 0)', v_ut_inc, v_owens;
  END IF;
  RAISE NOTICE 'PASS UT-REKEY: FIPS-49 offices md5 matches the binding baseline 4d8bbfb221d4babca6e9f7201bce391e; Moore/Maloy/Kennedy are is_incumbent=true on 4902/4903/4904 in the UT general; retired Owens has 0 active rows';

  -- ==========================================================================
  -- INVARIANT 14 (AK-FIELD, from 165) — 1 jungle race, primary_party NULL (top-four RCV modeled
  --   per the LA/CA convention). The active count is RE-DERIVED LIVE rather than inherited: 165
  --   froze it at 15 on 2026-07-07, and AK is a PROVISIONAL: state with an August primary, so
  --   filings and withdrawals since then were expected. Live on 2026-07-26 it is still 15 — the
  --   figure is asserted because it was re-measured, not because it was inherited.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_ak_races  FROM _house WHERE st='AK';
  SELECT COUNT(*)                INTO v_ak_active FROM _house WHERE st='AK' AND candidate_status='active';
  SELECT COUNT(DISTINCT race_id) INTO v_ak_party  FROM _house WHERE st='AK' AND primary_party IS NOT NULL;
  IF v_ak_races<>1 OR v_ak_active<>15 OR v_ak_party<>0 THEN
    RAISE EXCEPTION 'FAIL AK-FIELD: races=% (exp 1), active=% (exp 15, re-derived live 2026-07-26), non-null primary_party races=% (exp 0)',
      v_ak_races, v_ak_active, v_ak_party;
  END IF;
  RAISE NOTICE 'PASS AK-FIELD: 1 AK jungle race with primary_party NULL and 15 active candidates (re-derived live 2026-07-26; 165 froze the same figure on 2026-07-07)';

  -- ==========================================================================
  -- INVARIANT 15 (COLLISION-BAND, from 164 + 165) — the 19 D-04 sub-band seq floors.
  --   District seq = -external_id - (fips*10000 + cd*100); at-large seq = -external_id -
  --   fips*10000. Active NON-INCUMBENT candidates only.
  --   From 164 (5): KY-1>=200, OK-1>=44 (the in-century fix — the audit's 200 would have
  --     collided with OK-3 seq 1), OR-1>=14, KS-1>=3, KS-2>=10.
  --   From 165 (14): NV-1>=74, NV-2>=51, NV-4>=79, ME-1>=3, ME-2>=3, NM-1>=26, NM-2>=51,
  --     NM-3>=82, NE-3>=60, NH-1>=33, MT-2>=85, AK>=5, DE>=48 (Pitfall-6 legacy trap), VT>=6.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(geo_id || ':' || external_id::text, ', ' ORDER BY external_id)
    INTO v_cb, v_cb_detail
  FROM _house
  WHERE candidate_status='active' AND is_incumbent=false AND external_id IS NOT NULL
    AND ( (geo_id='2101' AND external_id BETWEEN -210199 AND -210101 AND (-external_id - 210100) < 200)
       OR (geo_id='4001' AND external_id BETWEEN -400199 AND -400101 AND (-external_id - 400100) < 44)
       OR (geo_id='4101' AND external_id BETWEEN -410199 AND -410101 AND (-external_id - 410100) < 14)
       OR (geo_id='2001' AND external_id BETWEEN -200199 AND -200101 AND (-external_id - 200100) < 3)
       OR (geo_id='2002' AND external_id BETWEEN -200299 AND -200201 AND (-external_id - 200200) < 10)
       OR (geo_id='3201' AND external_id BETWEEN -320199 AND -320101 AND (-external_id - 320100) < 74)
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
       OR (geo_id='0200' AND external_id BETWEEN -20099  AND -20001  AND (-external_id - 20000)  < 5)
       OR (geo_id='1000' AND external_id BETWEEN -100099 AND -100001 AND (-external_id - 100000) < 48)
       OR (geo_id='5000' AND external_id BETWEEN -500099 AND -500001 AND (-external_id - 500000) < 6) );
  IF v_cb<>0 THEN
    RAISE EXCEPTION 'FAIL COLLISION-BAND: % new id(s) below their D-04 seq floor: %', v_cb, v_cb_detail;
  END IF;
  RAISE NOTICE 'PASS COLLISION-BAND: all 19 D-04 sub-band seq floors honored — KY-1>=200, OK-1>=44, OR-1>=14, KS-1>=3, KS-2>=10 (164); NV-1>=74, NV-2>=51, NV-4>=79, ME-1>=3, ME-2>=3, NM-1>=26, NM-2>=51, NM-3>=82, NE-3>=60, NH-1>=33, MT-2>=85, AK>=5, DE>=48, VT>=6 (165)';

  RAISE NOTICE 'ALL INHERITED INVARIANTS PASSED (15 blocks): TN-SURFACING (161+164.1-04), AL-SURFACING (163+164.1-05), LA-SURFACING (163+164.1-05), MO-SEVERE (162), IN9-FLAG (162), AZ-RECONCILE (161), MA-INCUMBENT-DEDUP (161), CO1-DEGETTE (163), OPEN-SEAT (164), OR-REUSE (164), NV-RECONCILE (165), ME-RECONCILE (165), UT-REKEY (165 via 1641 D04-NOTOUCH), AK-FIELD (165), COLLISION-BAND (164+165). The structural half is backend/scripts/166-verify.sql and the coordinate half is backend/scripts/166-coordinate-smoke.ts.';
END $$;
