-- CA_0250_wrightwood_csd_board_and_2026_race.sql
-- CA_0250: Wrightwood Community Services District (Wrightwood, CA) -- board of directors + its Nov 3 2026 race.
--
-- WHY SEPARATE: the LA special-district series (CA_0239/0241/0242/0244/0248) skipped Wrightwood CSD. It lies mostly
--   in San Bernardino County, with a small part (about 2,055 acres, ~140 voters) in LA County, and the LA RR/CC
--   precinct layer has no DST code for it. The San Bernardino County Registrar of Voters (SB ROV) runs its elections.
-- MODEL (same as the LA special districts): one government ("Wrightwood Community Services District, California,
--   US", LOCAL) + one chamber (Board of Directors); one LOCAL district on one polygon for the WHOLE district (both
--   counties), geofence layer mtfcc 'X-CA-SPD', geo_id 'ca-spd-wrightwood-csd'; 5 at-large Director offices, each
--   with its current holder in office_terms. Party is never stored.
-- POLYGON: LA LAFCO "LAFCo Service Data Layers" FeatureServer layer 8 (Community Services Districts,
--   services5.arcgis.com/HCt5oVeONcW4cN7w/.../LAFCoService_Data_Layers/FeatureServer/8), features
--   "LA County Wrightwood Community Services District" (2,054.7 ac) + "San Bernardino County Wrightwood Community
--   Services District" (8,678.4 ac), unioned (4 seam holes < 1e-11 deg2 dropped), simplified at 2e-6 deg.
--   Cross-checks: the SB part matches SB LAFCO's own CSD layer (LAFCO_WebMap_V2_0_WFL1/FeatureServer/45 "Wrightwood
--   CSD", formed 05/25/2017) at IoU 0.996; the LA part is covered by RR/CC precincts 3750012A/3750014A/3750015A
--   (LLANO), which lie 100% inside it.
-- DIRECTORS: https://wrightwoodcsd.org/our-team (read 2026-09-24): Schoenwetter (appointed 2025-08-06), DeGroot (appointed 2025-05-07),
--   Claiborne (appointed in lieu 2022), Christensen + McFauls (elected Nov 2024).
-- RACE: 3 full terms. SB ROV candidate list (last updated 9/8/2026): 5 filed, 5 on the ballot, "Will contest appear on
--   the ballot: Yes" -> contested. Incumbents Schoenwetter + DeGroot linked; Claiborne did not file (open seat).
--   The RR/CC List of Offices 2026 (content.lavote.gov/docs/rrcc/documents/list-of-offices-booklet-8-5-2026.pdf)
--   lists the same 3 seats for the LA-side voters.
-- ELECTION (operator decision 2026-09-24): a NEW election row '2026 San Bernardino County General' (county, CA,
--   2026-11-03). SB ROV runs this contest, and the polygon covers SB addresses too, so the '2026 LA County General'
--   label would be wrong for most voters. The race is office-bound; primary_party NULL (nonpartisan).
-- Apply with: npx tsx scripts/_apply-file.ts <abs path>
BEGIN;

-- ─── 1. Government + board ────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name, type, state)
SELECT '64df7501-82f9-58ae-8c16-ab28c2596d72'::uuid, 'Wrightwood Community Services District, California, US', 'LOCAL', 'CA'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = '64df7501-82f9-58ae-8c16-ab28c2596d72'::uuid);

INSERT INTO essentials.chambers (id, government_id, name, name_formal, term_length, election_frequency, website_url, policy_engagement_level)
SELECT '69c4f6f3-f814-553d-8c95-b5910b2236be'::uuid, '64df7501-82f9-58ae-8c16-ab28c2596d72'::uuid, 'Board of Directors', 'Wrightwood Community Services District Board of Directors',
       '4 years', '2 years', 'https://wrightwoodcsd.org/our-team', 'full'   -- slug is generated
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = '69c4f6f3-f814-553d-8c95-b5910b2236be'::uuid);

-- ─── 2. Polygon (whole district, LA + SB parts) on the 'X-CA-SPD' layer ───────────────────
INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
SELECT 'ca-spd-wrightwood-csd', NULL, 'Wrightwood Community Services District', '06', 'X-CA-SPD',
       public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON(v.gj), 4326)), 3)),
       'lalafco_csd_layer8_2026', now()
  FROM (VALUES ('{"type":"MultiPolygon","coordinates":[[[[-117.653287,34.373348],[-117.650651,34.372964],[-117.646264,34.372835],[-117.646568,34.368587],[-117.642224,34.368505],[-117.633316,34.368494],[-117.624408,34.368417],[-117.625213,34.376916],[-117.625587,34.382943],[-117.624526,34.382987],[-117.615996,34.383036],[-117.607368,34.383041],[-117.598637,34.383018],[-117.588718,34.382958],[-117.5889,34.376589],[-117.588954,34.368706],[-117.589399,34.353919],[-117.589424,34.346288],[-117.589529,34.339486],[-117.580946,34.339606],[-117.572401,34.339675],[-117.572256,34.332767],[-117.572279,34.325588],[-117.581031,34.325699],[-117.589629,34.325828],[-117.597807,34.325298],[-117.607009,34.325439],[-117.62481,34.325576],[-117.633553,34.325756],[-117.642281,34.325939],[-117.649412,34.32612],[-117.650583,34.340387],[-117.660203,34.341216],[-117.660269,34.339611],[-117.676009,34.339395],[-117.677076,34.346413],[-117.677028,34.353836],[-117.676792,34.361549],[-117.672497,34.361553],[-117.672266,34.369212],[-117.67226,34.372811],[-117.665864,34.372757],[-117.665841,34.376378],[-117.663971,34.376368],[-117.659426,34.376363],[-117.659431,34.377827],[-117.654527,34.377477],[-117.654756,34.37342],[-117.653273,34.373176],[-117.653287,34.373348]]]]}')) AS v(gj)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b WHERE b.geo_id = 'ca-spd-wrightwood-csd' AND b.mtfcc = 'X-CA-SPD');

-- ─── 3. LOCAL district ────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (id, label, district_type, district_id, state, num_officials, mtfcc, geo_id,
                                  is_judicial, has_unknown_boundaries, retention, representation_basis, government_id, official_web_url)
SELECT '4e660b83-d968-523d-a211-375adccf240a'::uuid, 'Wrightwood Community Services District', 'LOCAL', 'ca-spd-wrightwood-csd', 'CA', 5, 'X-CA-SPD',
       'ca-spd-wrightwood-csd', false, false, false, 'residency', '64df7501-82f9-58ae-8c16-ab28c2596d72'::uuid, 'https://wrightwoodcsd.org/'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = '4e660b83-d968-523d-a211-375adccf240a'::uuid);

-- ─── 4. One office per seat ───────────────────────────────────────────────────────────────
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers)
SELECT v.id, '69c4f6f3-f814-553d-8c95-b5910b2236be'::uuid, '4e660b83-d968-523d-a211-375adccf240a'::uuid, 'Director', 'CA', 1, 'Board Member', false, false, false, 'full'
  FROM (VALUES ('b3fb1b74-3168-5eaa-9f90-e059bee26fd0'::uuid), ('7a2adc81-6487-56cf-906b-21c44fed6b3f'::uuid), ('25a12bc5-e862-5f97-8b78-1ef83fd26da7'::uuid), ('85cfcc23-479a-59c8-af3b-026fbd20ae87'::uuid), ('aa2ebeff-ab67-541e-b87c-e690a35779ca'::uuid)) AS v(id)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.id);

-- ─── 5. Politician rows (none existed; party NULL) ────────────────────────────────────────
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, party_short_name,
                                    is_active, is_incumbent, is_vacant, is_appointed, data_source)
SELECT v.id, v.first_name, v.last_name, v.full_name, NULL, NULL, true, true, false, v.appt, 'https://wrightwoodcsd.org/our-team'
  FROM (VALUES
    ('2ce2810a-25ae-5f59-9347-028ee0c82a62'::uuid, 'David', 'Schoenwetter', 'David E. Schoenwetter', true),
    ('c1488832-9356-5fce-a141-01b49125032c'::uuid, 'Erin', 'DeGroot', 'Erin C. DeGroot', true),
    ('8ddcdfbf-1604-54ce-9975-0cfa4f505e35'::uuid, 'Alexis', 'Claiborne', 'Alexis Claiborne', true),
    ('fa58cd37-515d-5790-a5a7-31b311e491e4'::uuid, 'Rick', 'Christensen', 'Rick J. Christensen', false),
    ('12894e69-f0c9-5b18-b0bc-199a739de65d'::uuid, 'Martha', 'McFauls', 'Martha McFauls', false)
  ) AS v(id, first_name, last_name, full_name, appt)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

-- ─── 6. Seat the current directors ────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, v.ts, v.prec, v.how, v.src
  FROM (VALUES
    ('b3fb1b74-3168-5eaa-9f90-e059bee26fd0'::uuid, '2ce2810a-25ae-5f59-9347-028ee0c82a62'::uuid, '2025-08-06'::date, 'day', 'appointed', 'CA_0250: seated per https://wrightwoodcsd.org/our-team (read 2026-09-24) -- "President Dave Schoenwetter, Term: 08/06/2025 - 12/06/2026". Appointed by the board to an unexpired term; SB ROV Nov 3 2026 candidate list shows him as "Appointed Incumbent".'),
    ('7a2adc81-6487-56cf-906b-21c44fed6b3f'::uuid, 'c1488832-9356-5fce-a141-01b49125032c'::uuid, '2025-05-07'::date, 'day', 'appointed', 'CA_0250: seated per https://wrightwoodcsd.org/our-team (read 2026-09-24) -- "Vice President Erin DeGroot, Term: 05/07/2025 - 12/06/2026". Appointed by the board to an unexpired term.'),
    ('25a12bc5-e862-5f97-8b78-1ef83fd26da7'::uuid, '8ddcdfbf-1604-54ce-9975-0cfa4f505e35'::uuid, '2022-12-01'::date, 'month', 'appointed', 'CA_0250: seated per https://wrightwoodcsd.org/our-team (read 2026-09-24) -- "Director Alexis Claiborne, Term: 12/06/2022 - 12/06/2026". Term basis: SB ROV notice of special district appointments in lieu of election, Nov 8 2022 (https://uploads.rov.sbcounty.gov/rov/News/2022/1108/PublicNotice_AppointmentsInLieuSpecials.pdf): "Alexis Laurel Claiborne, Wrightwood Community Services District, Member, Board of Directors, 4 years". She did not file for 2026 (SB ROV candidate list 9/8/2026) -> open seat.'),
    ('85cfcc23-479a-59c8-af3b-026fbd20ae87'::uuid, 'fa58cd37-515d-5790-a5a7-31b311e491e4'::uuid, '2024-12-01'::date, 'month', 'elected', 'CA_0250: seated per https://wrightwoodcsd.org/our-team (read 2026-09-24) -- "Director Rick Christensen, Term: 12/06/2024 - 12/06/2028". Elected Nov 5 2024 (2 seats; RR/CC results 4324 list RICK J. CHRISTENSEN for the LA part; SB ROV ran the contest).'),
    ('aa2ebeff-ab67-541e-b87c-e690a35779ca'::uuid, '12894e69-f0c9-5b18-b0bc-199a739de65d'::uuid, '2024-12-01'::date, 'month', 'elected', 'CA_0250: seated per https://wrightwoodcsd.org/our-team (read 2026-09-24) -- "Director Martha McFauls, Term: 12/06/2024 - 12/06/2028". Elected Nov 5 2024 (2 seats; RR/CC results 4324 list MARTHA MCFAULS for the LA part; SB ROV ran the contest).')
  ) AS v(oid, pid, ts, prec, how, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid AND t.politician_id = v.pid);

-- ─── 7. New election row: 2026 San Bernardino County General ──────────────────────────────
INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT 'aadff7cf-a432-59ff-add4-28d4675d36bf'::uuid, '2026 San Bernardino County General', '2026-11-03'::date, 'general', 'county', 'CA'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.elections e WHERE e.id = 'aadff7cf-a432-59ff-add4-28d4675d36bf'::uuid
                      OR (e.name = '2026 San Bernardino County General' AND e.election_date = '2026-11-03'::date));

-- ─── 8. The race (3 seats, nonpartisan, office-bound to Claiborne's open seat) + candidates ─
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT '5c81536d-9f07-5401-a11b-2c3e2d482df3'::uuid, e.id, '25a12bc5-e862-5f97-8b78-1ef83fd26da7'::uuid, 'Wrightwood Community Services District Board', NULL, 3
  FROM essentials.elections e
 WHERE e.name = '2026 San Bernardino County General' AND e.election_date = '2026-11-03'::date
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = e.id AND r.position_name = 'Wrightwood Community Services District Board');

INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, occupational_designation, source)
SELECT r.id, v.pid, v.full_name, v.first_name, v.last_name, v.inc, 'active', v.desig, 'SB County ROV Nov 3 2026 candidate list (https://uploads.rov.sbcounty.gov/ROV/Elections/2026/1103/Report_CandidateList.pdf, last updated 9/8/2026): declaration of candidacy filed, on the ballot; retrieved 2026-09-24.'
  FROM (VALUES
    ('David E. Schoenwetter', 'David', 'Schoenwetter', '2ce2810a-25ae-5f59-9347-028ee0c82a62'::uuid, true, 'Appointed Incumbent'),
    ('Jason Agraz', 'Jason', 'Agraz', NULL::uuid, false, 'Business Owner'),
    ('Erin C. DeGroot', 'Erin', 'DeGroot', 'c1488832-9356-5fce-a141-01b49125032c'::uuid, true, 'Mother / Business Owner'),
    ('Wes Zuber', 'Wes', 'Zuber', NULL::uuid, false, 'Local Businessman'),
    ('Russ Drew', 'Russ', 'Drew', NULL::uuid, false, 'Retired / Community Volunteer')
  ) AS v(full_name, first_name, last_name, pid, inc, desig)
  JOIN essentials.elections e ON e.name = '2026 San Bernardino County General' AND e.election_date = '2026-11-03'::date
  JOIN essentials.races r ON r.election_id = e.id AND r.position_name = 'Wrightwood Community Services District Board'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name));

-- ─── 9. Post-verify gate ──────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; n2 int; fla float8; fsb float8;
BEGIN
  SELECT count(*) INTO n FROM essentials.geofence_boundaries gb
   WHERE gb.geo_id = 'ca-spd-wrightwood-csd' AND gb.mtfcc = 'X-CA-SPD'
     AND public.ST_IsValid(gb.geometry) AND NOT public.ST_IsEmpty(gb.geometry) AND public.ST_SRID(gb.geometry) = 4326;
  IF n <> 1 THEN RAISE EXCEPTION 'expected 1 valid polygon, got %', n; END IF;

  -- the polygon spans both counties: LA part ~19%, SB part ~81% of the area (planar ratios, decision 0006)
  SELECT public.ST_Area(public.ST_Intersection(gb.geometry, la.geometry)) / public.ST_Area(gb.geometry),
         public.ST_Area(public.ST_Intersection(gb.geometry, sb.geometry)) / public.ST_Area(gb.geometry)
    INTO fla, fsb
    FROM essentials.geofence_boundaries gb
    JOIN essentials.geofence_boundaries la ON la.geo_id = '06037' AND la.mtfcc = 'G4020'
    JOIN essentials.geofence_boundaries sb ON sb.geo_id = '06071' AND sb.mtfcc = 'G4020'
   WHERE gb.geo_id = 'ca-spd-wrightwood-csd' AND gb.mtfcc = 'X-CA-SPD';
  IF fla IS NULL OR fla < 0.15 OR fla > 0.23 OR fsb < 0.77 OR fla + fsb < 0.99 THEN
    RAISE EXCEPTION 'county split off: LA % / SB %', fla, fsb; END IF;

  SELECT count(*) INTO n FROM essentials.districts d
   WHERE d.government_id = '64df7501-82f9-58ae-8c16-ab28c2596d72'::uuid AND d.district_type = 'LOCAL' AND d.mtfcc = 'X-CA-SPD' AND d.geo_id = 'ca-spd-wrightwood-csd';
  IF n <> 1 THEN RAISE EXCEPTION 'expected 1 LOCAL district, got %', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o WHERE o.district_id = '4e660b83-d968-523d-a211-375adccf240a'::uuid;
  IF n <> 5 THEN RAISE EXCEPTION 'expected 5 offices, got %', n; END IF;

  SELECT count(*) INTO n FROM (VALUES ('b3fb1b74-3168-5eaa-9f90-e059bee26fd0'::uuid, '2ce2810a-25ae-5f59-9347-028ee0c82a62'::uuid), ('7a2adc81-6487-56cf-906b-21c44fed6b3f'::uuid, 'c1488832-9356-5fce-a141-01b49125032c'::uuid), ('25a12bc5-e862-5f97-8b78-1ef83fd26da7'::uuid, '8ddcdfbf-1604-54ce-9975-0cfa4f505e35'::uuid), ('85cfcc23-479a-59c8-af3b-026fbd20ae87'::uuid, 'fa58cd37-515d-5790-a5a7-31b311e491e4'::uuid), ('aa2ebeff-ab67-541e-b87c-e690a35779ca'::uuid, '12894e69-f0c9-5b18-b0bc-199a739de65d'::uuid)) AS v(oid, pid)
    JOIN essentials.office_current_holder och ON och.office_id = v.oid AND och.politician_id = v.pid;
  IF n <> 5 THEN RAISE EXCEPTION 'expected 5 seats each held by its named director, got %', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id IN (SELECT pid FROM (VALUES ('b3fb1b74-3168-5eaa-9f90-e059bee26fd0'::uuid, '2ce2810a-25ae-5f59-9347-028ee0c82a62'::uuid), ('7a2adc81-6487-56cf-906b-21c44fed6b3f'::uuid, 'c1488832-9356-5fce-a141-01b49125032c'::uuid), ('25a12bc5-e862-5f97-8b78-1ef83fd26da7'::uuid, '8ddcdfbf-1604-54ce-9975-0cfa4f505e35'::uuid), ('85cfcc23-479a-59c8-af3b-026fbd20ae87'::uuid, 'fa58cd37-515d-5790-a5a7-31b311e491e4'::uuid), ('aa2ebeff-ab67-541e-b87c-e690a35779ca'::uuid, '12894e69-f0c9-5b18-b0bc-199a739de65d'::uuid)) AS v(oid, pid))
     AND (p.party IS NOT NULL OR NOT p.is_active OR NOT p.is_incumbent);
  IF n <> 0 THEN RAISE EXCEPTION '% seated director row(s) carry a party or are not active incumbents', n; END IF;

  -- END TO END: an interior point of each county part resolves to all 5 directors
  SELECT count(*) INTO n FROM (
    SELECT (SELECT count(DISTINCT och.politician_id)
              FROM essentials.geofence_boundaries gb
              JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.district_type = 'LOCAL' AND d.mtfcc = gb.mtfcc
              JOIN essentials.offices o ON o.district_id = d.id
              JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
             WHERE d.government_id = '64df7501-82f9-58ae-8c16-ab28c2596d72'::uuid AND public.ST_Covers(gb.geometry, pt.g)) AS k
      FROM (SELECT public.ST_PointOnSurface(public.ST_Intersection(w.geometry, c.geometry)) AS g
              FROM essentials.geofence_boundaries w
              JOIN essentials.geofence_boundaries c ON c.geo_id IN ('06037', '06071') AND c.mtfcc = 'G4020'
             WHERE w.geo_id = 'ca-spd-wrightwood-csd' AND w.mtfcc = 'X-CA-SPD') pt) s
   WHERE s.k = 5;
  IF n <> 2 THEN RAISE EXCEPTION 'expected both county parts to return 5 directors, got % part(s)', n; END IF;

  SELECT count(*) INTO n FROM essentials.elections e WHERE e.name = '2026 San Bernardino County General' AND e.election_date = '2026-11-03'::date;
  IF n <> 1 THEN RAISE EXCEPTION 'expected 1 SB County general election row, got %', n; END IF;

  SELECT count(*), count(*) FILTER (WHERE r.office_id IS NULL OR r.primary_party IS NOT NULL OR r.seats <> 3) INTO n, n2
    FROM essentials.races r JOIN essentials.offices o ON o.id = r.office_id
   WHERE o.district_id = '4e660b83-d968-523d-a211-375adccf240a'::uuid;
  IF n <> 1 OR n2 <> 0 THEN RAISE EXCEPTION 'expected 1 office-bound nonpartisan 3-seat race, got % (% bad)', n, n2; END IF;

  SELECT count(*), count(*) FILTER (WHERE rc.is_incumbent) INTO n, n2
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id JOIN essentials.offices o ON o.id = r.office_id
   WHERE o.district_id = '4e660b83-d968-523d-a211-375adccf240a'::uuid;
  IF n <> 5 OR n2 <> 2 THEN RAISE EXCEPTION 'expected 5 candidates / 2 incumbents, got % / %', n, n2; END IF;

  -- every incumbent candidate is linked to a director seated on this board
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
   WHERE o.district_id = '4e660b83-d968-523d-a211-375adccf240a'::uuid AND rc.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o2 JOIN essentials.office_current_holder och ON och.office_id = o2.id
                      WHERE o2.district_id = '4e660b83-d968-523d-a211-375adccf240a'::uuid AND och.politician_id = rc.politician_id);
  IF n <> 0 THEN RAISE EXCEPTION '% incumbent candidate(s) not linked to a seated director', n; END IF;

  RAISE NOTICE 'CA_0250 OK: 1 polygon (LA % / SB %), 5 seats held, 1 race / 5 candidates', round(fla::numeric, 3), round(fsb::numeric, 3);
END $$;

COMMIT;
