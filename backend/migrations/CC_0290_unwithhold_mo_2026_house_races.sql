-- CC_0290_unwithhold_mo_2026_house_races.sql
-- Un-withhold the 5 severe MO 2026 U.S. House races (the D-01b flip, MO edition).
--
-- ============================================================================
-- WHY, AND WHY IT IS THE MIRROR IMAGE OF TN's 1247
-- ============================================================================
-- Migration 1206 (Phase 162-02) seeded all 8 MO districts but WITHHELD 5 of them
-- (geo_id 2902, 2903, 2904, 2905, 2906) by pointing their races at the past-dated
-- special 'MO 2026 Congressional Redistricting - Polygon Pending' (2026-03-24),
-- which electionService.ts's ELECTION_VISIBILITY_WINDOW never returns. Its stated
-- reason was "new-map field vs. old-map polygon": MO redistricted mid-decade in
-- 2025, and a 2025-map candidate slate served against our 2024-TIGER (2022-map)
-- polygon would have misled a voter. 1206 flagged the hedge explicitly:
--
--     "MO's general-election map is unsettled pending the veto referendum
--      ... The D-01b withholding hedges correctly either way."
--
-- It is settled now, and it settled the OTHER way from TN and AL.
--
--   * TN (1247) and AL (1248) un-withheld because their NEW maps took effect and
--     Phase 164.1 loaded 2026-vintage polygons (mtfcc='G5200V26') to match.
--   * MO un-withholds because its new map was STRUCK DOWN. There is no new polygon
--     to load. The map we already hold IS the operative one.
--
-- Supreme Court of the United States, PEOPLE NOT POLITICIANS v. ONDER, No. 26A388,
-- per curiam, September 25, 2026, at 1:
--
--     "In short, as a matter of state law, the 2022 map -- not the 2025 map --
--      must be used in the 2026 congressional election."
--
-- quoting the Missouri Supreme Court's September 3, 2026 holding that the 2025 map
-- "is not the law and has never been the law" in Missouri, and will not take effect
-- unless and until Missouri voters approve it by referendum (Proposition A, on the
-- 2026-11-03 ballot). 609 U.S. ___ (2026).
--
-- So essentials.districts geo_id 2901-2908 on mtfcc G5200 / census_tiger_2024 -- the
-- 2022 map -- is correct for BOTH questions our read paths ask: who represents you
-- now, AND whose race is on your ballot. The withholding has outlived its reason and
-- is now the only thing wrong with Missouri.
--
-- ============================================================================
-- WHAT A MISSOURI VOTER SEES TODAY (measured against prod, 2026-10-25, 9 days out)
-- ============================================================================
-- GET /api/essentials/elections-by-address, production:
--
--   414 E 12th St, Kansas City MO     (CD-5, withheld)  -> NO ELECTIONS AT ALL
--   701 E Broadway, Columbia MO       (CD-4, withheld)  -> NO ELECTIONS AT ALL
--   1200 Market St, St. Louis MO      (CD-1, control )  -> U.S. Rep District 1:
--                                        Wesley Bell, Paul Berry, Tom Schmitz
--   840 Boonville Ave, Springfield MO (CD-7, control )  -> U.S. Rep District 7:
--                                        Eric Burlison, Kevin Craig, Missi Hesketh
--
-- The two controls discriminate: the read path works, the slates are already the
-- certified ones, and the 5 withheld districts are the only silence. Emanuel Cleaver
-- v. Rick Brattin -- the race the whole redistricting fight was about -- is among them.
--
-- ============================================================================
-- THE CANDIDATE FIELD IS ALREADY CORRECT -- VERIFIED AGAINST THE CERTIFICATION
-- ============================================================================
-- Nothing here touches essentials.race_candidates. Migration 1578 and the 2026-08-07
-- re-verify pass already culled the pre-primary field by setting result='not_nominated'
-- on 41 of the 65 rows, and electionService.ts's BALLOT_CANDIDATE_JOIN excludes those.
-- The surviving 24 were checked row by row, today, against the primary source:
--
--   "Certification of Candidates and Party Emblems", Denny Hoskins, CPA, Secretary of
--   State of Missouri, August 25, 2026, Sec. 115.401 RSMo --
--   sos.mo.gov/CMSImages/ElectionCandidates/2026GeneralElectionCertifiedCandidates.pdf
--
-- 24 of 24 match, 3 per district (R / D / L -- Missouri certified exactly three parties).
-- Where the certification styles a name differently from our row, the person is the same
-- and OUR spelling is left alone; re-styling display names to ballot form is a separate
-- decision and would touch politician links. The crosswalk, for the next reader:
--
--   geo   REPUBLICAN                    DEMOCRATIC                    LIBERTARIAN
--   2901  Paul Berry [III]              Wesley Bell                   Tom Schmitz
--   2902  Ann Wagner                    Fred Wellman                  Brandon Coulter Daugherty
--   2903  Robert F. Onder, Jr. [Bob]    Bethany Mann [Bethany E]      Jim Higgins
--   2904  Mark Alford                   Jordan Herrera                Thomas Holbrook
--   2905  Rick Brattin                  Emanuel Cleaver [, II]        Randall Langkraehr [(Randy)]
--   2906  Chris Stigall                 Josh Smead                    Andy Maidment
--   2907  Eric Burlison [Eric W.]       Missi Hesketh                 Kevin Craig
--   2908  Jason Smith [Jason T.]        Christopher Reichard [Chris]  Rebecca Sharpe Lombard
--
--   [bracketed] = the certification's spelling where it differs from ours.
--
-- ANTIPARTISAN INVARIANT: the party column above is documentation of the certification's
-- own section headings. It is NOT stored -- races.primary_party stays NULL and party is
-- never written to race_candidates.
--
-- ============================================================================
-- THE PRECONDITION THAT MATTERS MOST
-- ============================================================================
-- 🔴 MISSOURI MUST CARRY ZERO G5200V26 POLYGONS, AND THIS MIGRATION REFUSES TO RUN
--    OTHERWISE. electionService.ts prefers a G5200V26 polygon for a NATIONAL_LOWER
--    geo_id whenever one exists and falls back to the current vintage only when none
--    does. MO has none, so elections resolve against the 2022 map -- which is exactly
--    right. Loading MO's 2025 map into G5200V26 would therefore silently re-point every
--    un-withheld race at the map the courts BLOCKED, with nothing erroring. That load
--    would look like helpful catch-up work; it is the defect. Do not do it unless
--    Proposition A passes -- and then it is a January-2027 change, not a 2026 one.
--
-- The 'Polygon Pending' marker election is NOT deleted (historical artifact, the 163-11
-- convention that 1247 also followed).
--
-- Idempotent: the UPDATE is guarded on the OLD (withheld) election_id, so a re-run
-- matches zero rows and every gate below still passes.

BEGIN;

-- ---------------------------------------------------------------------------
-- PRECONDITION 1: no MO 2026-vintage congressional polygons (see above).
-- PRECONDITION 2: the 8 MO district rows still carry the 2022 map we are relying on.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_v26  integer;
  v_2022 integer;
BEGIN
  SELECT count(*) INTO v_v26
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'G5200V26' AND gb.state = '29';
  IF v_v26 <> 0 THEN
    RAISE EXCEPTION 'unwithhold_mo: MO carries % G5200V26 polygon(s) - elections would resolve against the BLOCKED 2025 map. Refusing.', v_v26;
  END IF;

  SELECT count(*) INTO v_2022
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb
      ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
   WHERE d.district_type = 'NATIONAL_LOWER'
     AND d.geo_id IN ('2901','2902','2903','2904','2905','2906','2907','2908')
     AND d.mtfcc = 'G5200'
     AND gb.source = 'census_tiger_2024';
  IF v_2022 <> 8 THEN
    RAISE EXCEPTION 'unwithhold_mo: expected 8 MO congressional districts on G5200/census_tiger_2024 (the 2022 map), found %', v_2022;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- The flip: re-point the 5 withheld races at the surfacing general election.
-- ---------------------------------------------------------------------------
UPDATE essentials.races r
   SET election_id = (
         SELECT id FROM essentials.elections
          WHERE name = 'MO 2026 Statewide General'
       )
 WHERE r.election_id = (
         SELECT id FROM essentials.elections
          WHERE name = 'MO 2026 Congressional Redistricting - Polygon Pending'
       )
   AND r.office_id IN (
         SELECT o.id
           FROM essentials.offices o
           JOIN essentials.districts d ON d.id = o.district_id
          WHERE d.district_type = 'NATIONAL_LOWER'
            AND d.geo_id IN ('2902', '2903', '2904', '2905', '2906')
       );

-- ---------------------------------------------------------------------------
-- POST-VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_general   integer;
  v_withheld  integer;
  v_offdistrict integer;
  v_slate     text;
BEGIN
  -- 1. all 8 MO congressional races now sit on the surfacing general election
  SELECT count(*) INTO v_general
    FROM essentials.races r
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
    JOIN essentials.elections e  ON e.id = r.election_id
   WHERE d.district_type = 'NATIONAL_LOWER'
     AND d.geo_id IN ('2901','2902','2903','2904','2905','2906','2907','2908')
     AND e.name = 'MO 2026 Statewide General';
  IF v_general <> 8 THEN
    RAISE EXCEPTION 'unwithhold_mo: expected 8 MO House races on the general, found %', v_general;
  END IF;

  -- 2. nothing MO-congressional is left parked on the marker election
  SELECT count(*) INTO v_withheld
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.name = 'MO 2026 Congressional Redistricting - Polygon Pending';
  IF v_withheld <> 0 THEN
    RAISE EXCEPTION 'unwithhold_mo: % race(s) still parked on the Polygon Pending election', v_withheld;
  END IF;

  -- 3. every district carries exactly the 3 certified candidates the read path will
  --    serve. is_live_candidate is the SAME predicate electionService.ts applies, so a
  --    pass here is a statement about what a voter gets, not about row counts.
  --    ⚠ 65 rows exist; 41 carry result='not_nominated' and must stay excluded.
  SELECT string_agg(d.geo_id || '=' || cnt, ', ' ORDER BY d.geo_id) INTO v_slate
    FROM essentials.districts d
    JOIN LATERAL (
      SELECT count(*) AS cnt
        FROM essentials.offices o
        JOIN essentials.races r  ON r.office_id = o.id
        JOIN essentials.race_candidates rc ON rc.race_id = r.id
       WHERE o.district_id = d.id
         AND essentials.is_live_candidate(rc.candidate_status, rc.result)
    ) c ON true
   WHERE d.district_type = 'NATIONAL_LOWER'
     AND d.geo_id IN ('2901','2902','2903','2904','2905','2906','2907','2908')
     AND c.cnt <> 3;
  IF v_slate IS NOT NULL THEN
    RAISE EXCEPTION 'unwithhold_mo: district(s) not carrying exactly 3 certified candidates: %', v_slate;
  END IF;

  -- 4. the certified 24, by name, against the SoS certification of 2026-08-25.
  --    An EXCEPT in BOTH directions: a missing name and a surprise name both fail.
  SELECT string_agg(diff, '; ') INTO v_slate FROM (
    SELECT 'MISSING ' || geo_id || ' ' || full_name AS diff FROM (
      VALUES ('2901','Paul Berry'),('2901','Wesley Bell'),('2901','Tom Schmitz'),
             ('2902','Ann Wagner'),('2902','Fred Wellman'),('2902','Brandon Coulter Daugherty'),
             ('2903','Robert F. Onder, Jr.'),('2903','Bethany Mann'),('2903','Jim Higgins'),
             ('2904','Mark Alford'),('2904','Jordan Herrera'),('2904','Thomas Holbrook'),
             ('2905','Rick Brattin'),('2905','Emanuel Cleaver'),('2905','Randall Langkraehr'),
             ('2906','Chris Stigall'),('2906','Josh Smead'),('2906','Andy Maidment'),
             ('2907','Eric Burlison'),('2907','Missi Hesketh'),('2907','Kevin Craig'),
             ('2908','Jason Smith'),('2908','Christopher Reichard'),('2908','Rebecca Sharpe Lombard')
    ) AS certified(geo_id, full_name)
    EXCEPT
    SELECT 'MISSING ' || d.geo_id || ' ' || rc.full_name
      FROM essentials.race_candidates rc
      JOIN essentials.races r     ON r.id = rc.race_id
      JOIN essentials.offices o   ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.district_type = 'NATIONAL_LOWER' AND lower(d.state) = 'mo'
       AND essentials.is_live_candidate(rc.candidate_status, rc.result)
    UNION ALL
    SELECT 'UNEXPECTED ' || d.geo_id || ' ' || rc.full_name
      FROM essentials.race_candidates rc
      JOIN essentials.races r     ON r.id = rc.race_id
      JOIN essentials.offices o   ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.district_type = 'NATIONAL_LOWER' AND lower(d.state) = 'mo'
       AND essentials.is_live_candidate(rc.candidate_status, rc.result)
       AND (d.geo_id, rc.full_name) NOT IN (
             ('2901','Paul Berry'),('2901','Wesley Bell'),('2901','Tom Schmitz'),
             ('2902','Ann Wagner'),('2902','Fred Wellman'),('2902','Brandon Coulter Daugherty'),
             ('2903','Robert F. Onder, Jr.'),('2903','Bethany Mann'),('2903','Jim Higgins'),
             ('2904','Mark Alford'),('2904','Jordan Herrera'),('2904','Thomas Holbrook'),
             ('2905','Rick Brattin'),('2905','Emanuel Cleaver'),('2905','Randall Langkraehr'),
             ('2906','Chris Stigall'),('2906','Josh Smead'),('2906','Andy Maidment'),
             ('2907','Eric Burlison'),('2907','Missi Hesketh'),('2907','Kevin Craig'),
             ('2908','Jason Smith'),('2908','Christopher Reichard'),('2908','Rebecca Sharpe Lombard')
           )
  ) AS d(diff);
  IF v_slate IS NOT NULL THEN
    RAISE EXCEPTION 'unwithhold_mo: certified-slate mismatch -- %', v_slate;
  END IF;

  -- 5. the reps feed is untouched: every MO district still holds its old-map office.
  --    1206 never touched essentials.offices and neither does this; assert it anyway,
  --    because "the incumbent still shows" is the half a voter checks first.
  SELECT count(*) INTO v_offdistrict
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE d.district_type = 'NATIONAL_LOWER'
     AND d.geo_id IN ('2901','2902','2903','2904','2905','2906','2907','2908');
  IF v_offdistrict <> 8 THEN
    RAISE EXCEPTION 'unwithhold_mo: expected 8 MO NATIONAL_LOWER offices, found %', v_offdistrict;
  END IF;

  RAISE NOTICE 'unwithhold_mo: PASS - 8/8 MO House races on the 2026-11-03 general, 24 certified candidates, 0 parked, 2022 map intact';
END $$;

COMMIT;
