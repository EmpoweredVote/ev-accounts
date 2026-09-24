-- CA_0248_la_special_districts_gap_fixes.sql
-- CA_0248: LA County special districts gap fixes -- new boards for Pico Water District and West Valley County Water District;
--   Westfield Rec & Park 5th director; appointee start dates (South Montebello, Palm Ranch, Green Valley).
--
-- MODEL (new: the DB had NO special-district rows at all -- no government, chamber, district, polygon or office):
--   per special district: one government ("<District>, California, US", LOCAL) + one chamber (its board);
--   by-division boards: one LOCAL district + one polygon per division (geo_id 'ca-spd-<slug>-div-N'), one office each;
--   at-large boards: one LOCAL district + one polygon for the whole district, one office per seat.
--   Polygons use the NEW geofence layer mtfcc 'X-CA-SPD' (operator decision 2026-09-24): GEOFENCE_DISTRICT_JOIN and
--   MTFCC_DISTRICT_TYPE_GUARD admit LOCAL for any X layer other than X0001-X0004, so no code change is needed. The
--   app shows these boards in the Representatives tab, Local tier, one accordion per district (government_name).
-- POLYGONS: LA RR/CC master precinct layer (public.gis.lacounty.gov/.../Political_Boundaries/MapServer/34, 33,236
--   precincts) dissolved by the district's DST_x code / DIV_x division. DIV_x = the director division number (checked
--   against each district's own division descriptions -- see per-district notes). LA County portion only (AVEK and
--   SCV Water also reach Kern / Ventura). Slivers < 1e-8 deg2 dropped, simplified at 2e-6 deg, make_valid, and any
--   residual overlap between two divisions of one district given to the lower-numbered division. Local QA: each
--   district's divisions union to its whole-district dissolve (ratio >= 0.99999), max pair overlap < 1e-9 deg2.
--   Special districts legitimately overlap one another and cities / school districts; that is expected.
-- DIRECTORS: each district's own board page (read 2026-09-24), cross-checked with RR/CC candidate lists + results for
--   Nov 2022 (id 4300) and Nov 2024 (4324). Term start: Nov-election winners YYYY-12-01 'month' 'elected'; appointed
--   in lieu of election: YYYY-12-01 'month' 'appointed'; board appointees: the appointment date. Party is never stored.
-- CANDIDATES: RR/CC Nov 3 2026 list (lavote.gov/Apps/CandidateList/Index?id=4348); only names whose nomination papers
--   were FILED (arg[8]); ballot designation = the line under the name. ONLY CONTESTS ON THE BALLOT are seeded
--   (operator decision 2026-09-24): where filed candidates <= seats up, the seat is appointed in lieu of election
--   (Elections Code 10515) and no race is created; the current holder stays seated. Incumbents (RR/CC flag E/A) are
--   linked to the seated director; challengers unlinked.
-- RACES go on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14); primary_party NULL.
-- Apply with: npx tsx scripts/_apply-file.ts <abs path>   (geometry-heavy; do not paste through MCP).
--
-- Pico Water District (at large, 5 seats; RR/CC DST CW PC; https://www.picowaterdistrict.net/governance/):
--   Director: Raymond M. Rodriguez -- appointed 2022-12-01 (month)
--   Director: Victor Caballero -- appointed 2022-12-01 (month)
--   Director: David Angelo -- appointed 2022-12-01 (month)
--   Director: Pete Ramirez -- appointed 2024-12-01 (month)
--   Director: David Raul Gonzales -- appointed 2024-12-01 (month)
-- West Valley County Water District (at large, 5 seats; RR/CC DST CW WV; https://wvcwd.myruralwater.com/):
--   Director: Brian Richmond -- appointed 2024-12-01 (month)
--   Director: Lisa Ballentine -- appointed 2024-12-03 (day)
--   Director: Jessie Kerr -- appointed 2025-04-22 (day)
--   Director: Kenneth Hooker -- unknown None (unknown)
--   Director: Teresa Green -- unknown None (unknown)
--
-- BATCH NOTES:
--   NEW BOARDS (no Nov 2026 race: NO candidate filed for Pico's 3 seats or West Valley's 2 full + 1 unexpired seats;
--     they are filled after Dec 4 2026 by appointment): Pico Water District (Pico Rivera) and West Valley County Water
--     District (west Antelope Valley, Lancaster). Both 5 directors at large. Sources: district sites/agendas, BOS in-lieu
--     list Nov 26 2024, RR/CC List of Offices 2026.
--   WESTFIELD REC & PARK 5th DIRECTOR: Brenda L. Swanney-Caropino -- reappointed in lieu of election by the BOS on Nov
--     26 2024 ("Alan R. Hoffman+ and Brenda L. Swanney-Caropino+, Westfield Recreation and Park District"). Adds office
--     seat 5 to the CA_0244 board.
--   APPOINTEE START DATES (CA_0242/CA_0244 terms): South Montebello Div 1 Thomas Nunez -> 2025-05-21 (board agenda:
--     "Nomination and Appointment of Director for Division 1"); Palm Ranch Div 4 Kevin Gilliland -> 2023-05 at month
--     precision (the May 10 2023 board agenda holds interviews for the vacant seat; archived copies of the district site
--     show Spalla in Jun 2023, a copy the district updates rarely, and Gilliland by May 2024); Green Valley Robert E.
--     Garth -> start UNKNOWN (was 2025 'year': the BOS appointed only Delgado on Nov 26 2024, so Garth was appointed by
--     the district board some time after Dec 2024; no minutes online since Oct 2024).
BEGIN;

-- ─── 1. Government + governing board (chamber) per special district (none existed) ─────────
INSERT INTO essentials.governments (id, name, type, state)
SELECT v.id, v.name, 'LOCAL', 'CA'
  FROM (VALUES
    ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, 'Pico Water District, California, US'),
    ('2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid, 'West Valley County Water District, California, US')
  ) AS v(id, name)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = v.id);

INSERT INTO essentials.chambers (id, government_id, name, name_formal, term_length, election_frequency, website_url, policy_engagement_level)
SELECT v.id, v.gid, v.name, v.name_formal, '4 years', '2 years', v.url, 'full'   -- slug is generated
  FROM (VALUES
    ('a7420593-4b9c-529a-bec7-49a10241c782'::uuid, 'f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, 'Board of Directors', 'Pico Water District Board of Directors', 'https://www.picowaterdistrict.net/governance/'),
    ('8bafacda-74e9-5bea-844e-c83c9ced4dff'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid, 'Board of Directors', 'West Valley County Water District Board of Directors', 'https://wvcwd.myruralwater.com/')
  ) AS v(id, gid, name, name_formal, url)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = v.id);

-- ─── 2. Polygons (RR/CC precinct layer dissolved by DST_x / DIV_x) on the new 'X-CA-SPD' layer ─
INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
SELECT v.geo_id, NULL, v.name, '06', 'X-CA-SPD',
       public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON(v.gj), 4326)), 3)),
       'lacounty_rrcc_precincts_2026', now()
  FROM (VALUES
  ('ca-spd-pico-cwd', 'Pico Water District', '{"type":"MultiPolygon","coordinates":[[[[-118.101727,33.990998],[-118.100596,33.991375],[-118.099611,33.99202],[-118.099576,33.991989],[-118.09956899999999,33.991989],[-118.098823,33.992627],[-118.09798099999999,33.993122],[-118.097937,33.993145],[-118.097043,33.993296],[-118.09671999999999,33.993384],[-118.096752,33.993353],[-118.096752,33.993345],[-118.09643899999999,33.9934],[-118.09625799999999,33.993426],[-118.096215,33.993466999999995],[-118.096187,33.993501],[-118.096171,33.993506],[-118.09463,33.994261],[-118.094629,33.994265999999996],[-118.09483399999999,33.995174999999996],[-118.094562,33.995414],[-118.09414699999999,33.995768],[-118.092475,33.997136],[-118.092395,33.997206],[-118.09234199999999,33.997257],[-118.09229699999999,33.997316999999995],[-118.09216099999999,33.997536],[-118.091909,33.997952999999995],[-118.09181299999999,33.998143999999996],[-118.091495,33.998657],[-118.09125999999999,33.99905],[-118.09122699999999,33.999128999999996],[-118.091145,33.999238],[-118.09068599999999,33.99999],[-118.09061399999999,34.000091],[-118.090616,34.000098],[-118.090723,34.000147999999996],[-118.092648,34.000976],[-118.091895,34.002207999999996],[-118.091523,34.002842],[-118.091286,34.002738],[-118.09128,34.002741],[-118.09049399999999,34.00405],[-118.09040999999999,34.004182],[-118.09040999999999,34.004186],[-118.092652,34.005145999999996],[-118.092334,34.005153],[-118.091709,34.005148999999996],[-118.09141199999999,34.005142],[-118.09050599999999,34.005099],[-118.090012,34.005069],[-118.08999499999999,34.005182],[-118.08968999999999,34.005154],[-118.08939699999999,34.005123],[-118.088816,34.00505],[-118.088239,34.004963],[-118.08782599999999,34.004889999999996],[-118.087514,34.005243],[-118.087339,34.00546],[-118.08714599999999,34.005685],[-118.087029,34.005835],[-118.08695499999999,34.005942],[-118.086867,34.006088],[-118.086787,34.00624],[-118.086733,34.006356],[-118.08668999999999,34.006461],[-118.08664599999999,34.006592999999995],[-118.086613,34.006724999999996],[-118.08652699999999,34.007175],[-118.086446,34.007706],[-118.086418,34.008016999999995],[-118.086339,34.008513],[-118.086272,34.008977],[-118.086018,34.010798],[-118.085887,34.01178],[-118.08584599999999,34.012119999999996],[-118.085814,34.012423999999996],[-118.085757,34.013193],[-118.08574499999999,34.013315999999996],[-118.085709,34.013602],[-118.08567099999999,34.013819999999996],[-118.08564899999999,34.013926999999995],[-118.085583,34.014196],[-118.085532,34.014384],[-118.085481,34.014495],[-118.085456,34.014649],[-118.08534399999999,34.014589],[-118.08509099999999,34.014441999999995],[-118.08219,34.012732],[-118.08113999999999,34.012118],[-118.080536,34.011772],[-118.08057799999999,34.011642],[-118.080575,34.011635],[-118.08036999999999,34.011593],[-118.079594,34.011423],[-118.075863,34.010683],[-118.075857,34.010686],[-118.075606,34.011497],[-118.07560799999999,34.011503],[-118.079253,34.012245],[-118.079258,34.012243],[-118.07927099999999,34.012201],[-118.080331,34.012423],[-118.080028,34.013369],[-118.079889,34.013841],[-118.079736,34.014376],[-118.07951999999999,34.014333],[-118.07824,34.014061999999996],[-118.07823499999999,34.014064],[-118.078223,34.014102],[-118.077378,34.013931],[-118.077655,34.013042999999996],[-118.077652,34.013036],[-118.075288,34.012539],[-118.075282,34.012541999999996],[-118.075195,34.012822],[-118.07151499999999,34.012015999999996],[-118.072164,34.009837],[-118.07233,34.009828],[-118.07233199999999,34.009825],[-118.072537,34.009091],[-118.072587,34.008925],[-118.07277599999999,34.008241999999996],[-118.072772,34.008236],[-118.07101399999999,34.008312],[-118.067562,34.009746],[-118.06612799999999,34.010331],[-118.066037,34.010284],[-118.066143,34.010177999999996],[-118.06653999999999,34.009752999999996],[-118.067066,34.009125],[-118.067619,34.008359],[-118.06805,34.007667],[-118.068552,34.006724999999996],[-118.06866099999999,34.006501],[-118.068666,34.006499],[-118.06881899999999,34.006166],[-118.068981,34.005767],[-118.069054,34.005573],[-118.069132,34.005351999999995],[-118.069273,34.004923],[-118.069527,34.003972],[-118.07087299999999,33.999083999999996],[-118.072267,33.995788999999995],[-118.07227599999999,33.995761],[-118.072329,33.995652],[-118.072327,33.995646],[-118.072288,33.995613999999996],[-118.073674,33.992274],[-118.07419999999999,33.992492],[-118.07634999999999,33.993362999999995],[-118.076357,33.993361],[-118.076663,33.992711],[-118.076926,33.992829],[-118.07693099999999,33.992827],[-118.077874,33.990527],[-118.07802799999999,33.990591],[-118.07803399999999,33.990587],[-118.07824199999999,33.988745],[-118.077975,33.987823999999996],[-118.07835899999999,33.986744],[-118.07839899999999,33.986647999999995],[-118.078459,33.986675],[-118.078465,33.986674],[-118.07882,33.986335],[-118.078823,33.986274],[-118.07919299999999,33.986098999999996],[-118.07928199999999,33.986027],[-118.07955199999999,33.985711],[-118.079633,33.985628999999996],[-118.079736,33.985502],[-118.07973399999999,33.985495],[-118.079668,33.985462],[-118.07932,33.98531],[-118.07993099999999,33.984429],[-118.080362,33.984609],[-118.080467,33.984451],[-118.08084799999999,33.984141],[-118.081001,33.984027999999995],[-118.081221,33.984192],[-118.081228,33.98419],[-118.081378,33.983894],[-118.08160699999999,33.983419],[-118.083019,33.980469],[-118.083317,33.980596],[-118.083179,33.980888],[-118.083164,33.980923],[-118.083165,33.980927],[-118.083338,33.980999],[-118.085465,33.981916],[-118.087611,33.982832],[-118.08769799999999,33.982863],[-118.086995,33.984003],[-118.085898,33.985771],[-118.085898,33.985776],[-118.089101,33.987152],[-118.08970699999999,33.987401999999996],[-118.08971299999999,33.987401],[-118.09151299999999,33.984505],[-118.091753,33.984198],[-118.09174999999999,33.984193999999995],[-118.090076,33.983477],[-118.08788799999999,33.982552],[-118.088427,33.981677999999995],[-118.089124,33.980529],[-118.08915999999999,33.980475],[-118.08933599999999,33.980177],[-118.089382,33.980104],[-118.089473,33.979973],[-118.089517,33.979915999999996],[-118.089585,33.979839],[-118.089638,33.979788],[-118.089732,33.979712],[-118.089794,33.979667],[-118.090041,33.979502],[-118.090104,33.979456],[-118.09016299999999,33.979408],[-118.09025199999999,33.979327999999995],[-118.09037099999999,33.979213],[-118.090578,33.979],[-118.090655,33.978925],[-118.091302,33.977972],[-118.096132,33.980601],[-118.096138,33.980599],[-118.09620299999999,33.980514],[-118.096201,33.980508],[-118.096184,33.980498],[-118.09632599999999,33.980308],[-118.09639999999999,33.980202],[-118.09701,33.979369],[-118.097009,33.979362],[-118.096795,33.979248999999996],[-118.09520499999999,33.978379],[-118.09216199999999,33.976709],[-118.09235899999999,33.97642],[-118.09457599999999,33.977627],[-118.09576,33.975896999999996],[-118.09584,33.975708],[-118.09583699999999,33.975701],[-118.095776,33.975673],[-118.095146,33.975324],[-118.095704,33.974078999999996],[-118.095766,33.974112999999996],[-118.095771,33.974109999999996],[-118.095945,33.973689],[-118.095151,33.973281],[-118.095258,33.973034],[-118.09589199999999,33.973348],[-118.09589799999999,33.973345],[-118.095929,33.973264],[-118.09526699999999,33.972913],[-118.095379,33.972632],[-118.095377,33.972626],[-118.094625,33.972252999999995],[-118.094664,33.972158],[-118.09478299999999,33.971909],[-118.095759,33.969518],[-118.09606799999999,33.969367999999996],[-118.09655699999999,33.969682],[-118.096768,33.969825],[-118.10002899999999,33.972094],[-118.10003499999999,33.972093],[-118.100104,33.971956],[-118.10073399999999,33.972395],[-118.10073999999999,33.972394],[-118.10075499999999,33.972376],[-118.10335599999999,33.974179],[-118.103482,33.974242],[-118.103292,33.974577],[-118.103116,33.974872999999995],[-118.103,33.975055],[-118.102987,33.97508],[-118.102902,33.975213],[-118.102773,33.975404999999995],[-118.102465,33.975843999999995],[-118.102115,33.976326],[-118.101838,33.976714],[-118.100414,33.978660999999995],[-118.09877399999999,33.980883999999996],[-118.097681,33.982403999999995],[-118.09709699999999,33.983198],[-118.09709799999999,33.983204],[-118.098334,33.983885],[-118.09901199999999,33.984263999999996],[-118.10027,33.984954],[-118.101412,33.985576],[-118.102615,33.986225999999995],[-118.105003,33.987504],[-118.10600799999999,33.988054999999996],[-118.10645199999999,33.988304],[-118.10628799999999,33.988403],[-118.101727,33.990998]]],[[[-118.07676,34.015941],[-118.07438099999999,34.01544],[-118.07474599999999,34.014272999999996],[-118.076004,34.014527],[-118.07665999999999,34.014649999999996],[-118.076757,34.014675],[-118.077119,34.014748],[-118.077078,34.014886],[-118.07676,34.015941]]],[[[-118.093938,33.973887],[-118.094034,33.973659],[-118.09415,33.973718999999996],[-118.094546,33.973935],[-118.094518,33.973971],[-118.09451999999999,33.973977999999995],[-118.094715,33.974084],[-118.094591,33.974243],[-118.093938,33.973887]]]]}'),
  ('ca-spd-west-valley-cwd', 'West Valley County Water District', '{"type":"MultiPolygon","coordinates":[[[[-118.60302499999999,34.787516],[-118.599672,34.787507999999995],[-118.596363,34.787515],[-118.59266799999999,34.787501],[-118.590791,34.787497],[-118.589981,34.787351],[-118.589979,34.787355],[-118.589987,34.7891],[-118.58998899999999,34.789103],[-118.590154,34.789103],[-118.590155,34.789141],[-118.59018499999999,34.796394],[-118.590021,34.796395],[-118.590018,34.796399],[-118.590049,34.803675999999996],[-118.587375,34.803689],[-118.572385,34.803698],[-118.572312,34.789089],[-118.572245,34.781787],[-118.57224799999999,34.781783],[-118.572221,34.779496],[-118.57218999999999,34.775767],[-118.604222,34.7757],[-118.604216,34.777924999999996],[-118.605595,34.780522],[-118.60684699999999,34.781295],[-118.607733,34.781296],[-118.607738,34.783049999999996],[-118.607704,34.783049],[-118.60770199999999,34.783054],[-118.607748,34.78762],[-118.60374399999999,34.787619],[-118.60302499999999,34.787516]]],[[[-118.59070799999999,34.766495],[-118.59052199999999,34.766642],[-118.590369,34.766796],[-118.59026499999999,34.766925],[-118.59012299999999,34.767159],[-118.59004999999999,34.767308],[-118.590009,34.767401],[-118.58995499999999,34.767542999999996],[-118.58992599999999,34.767634],[-118.589973,34.773931],[-118.589974,34.774543],[-118.589923,34.774543],[-118.58991999999999,34.77454],[-118.58104999999999,34.774513],[-118.58106699999999,34.767230999999995],[-118.58991999999999,34.767257],[-118.589924,34.767253],[-118.589924,34.766158],[-118.591185,34.766162],[-118.59070799999999,34.766495]]]]}')
  ) AS v(geo_id, name, gj)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b WHERE b.geo_id = v.geo_id AND b.mtfcc = 'X-CA-SPD');

-- ─── 3. LOCAL districts on those polygons ('X-CA-SPD' reaches LOCAL through the X-layer clause) ─
INSERT INTO essentials.districts (id, label, district_type, district_id, state, num_officials, mtfcc, geo_id,
                                  is_judicial, has_unknown_boundaries, retention, representation_basis, government_id, official_web_url)
SELECT v.id, v.label, 'LOCAL', v.geo_id, 'CA', v.n, 'X-CA-SPD', v.geo_id, false, false, false, 'residency', v.gid, v.url
  FROM (VALUES
    ('c8039d1d-b04e-5c2c-8f3b-ff197efc3bbb'::uuid, 'Pico Water District', 'ca-spd-pico-cwd', 5, 'f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, 'https://www.picowaterdistrict.net/governance/'),
    ('cb5b322a-a7b4-57e0-a76f-080aa8d19668'::uuid, 'West Valley County Water District', 'ca-spd-west-valley-cwd', 5, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid, 'https://wvcwd.myruralwater.com/')
  ) AS v(id, label, geo_id, n, gid, url)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = v.id);

-- ─── 4. One office per seat ───────────────────────────────────────────────────────────────
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers)
SELECT v.id, v.cid, v.did, v.title, 'CA', 1, 'Board Member', false, v.vac, false, 'full'
  FROM (VALUES
    ('84c44468-866f-5cf9-b60a-26f2fff70860'::uuid, 'a7420593-4b9c-529a-bec7-49a10241c782'::uuid, 'c8039d1d-b04e-5c2c-8f3b-ff197efc3bbb'::uuid, 'Director', false),
    ('82270457-58c5-5d16-9866-2f24ffbfb896'::uuid, 'a7420593-4b9c-529a-bec7-49a10241c782'::uuid, 'c8039d1d-b04e-5c2c-8f3b-ff197efc3bbb'::uuid, 'Director', false),
    ('d8dc240e-a77a-56df-95e2-f0bdec39c312'::uuid, 'a7420593-4b9c-529a-bec7-49a10241c782'::uuid, 'c8039d1d-b04e-5c2c-8f3b-ff197efc3bbb'::uuid, 'Director', false),
    ('6eae810b-919a-5052-a886-f8ec691eb2e3'::uuid, 'a7420593-4b9c-529a-bec7-49a10241c782'::uuid, 'c8039d1d-b04e-5c2c-8f3b-ff197efc3bbb'::uuid, 'Director', false),
    ('dcc652f5-ebcd-5445-a9a4-7f4f56283826'::uuid, 'a7420593-4b9c-529a-bec7-49a10241c782'::uuid, 'c8039d1d-b04e-5c2c-8f3b-ff197efc3bbb'::uuid, 'Director', false),
    ('5715aa13-060d-57be-aeb3-182ce13513bc'::uuid, '8bafacda-74e9-5bea-844e-c83c9ced4dff'::uuid, 'cb5b322a-a7b4-57e0-a76f-080aa8d19668'::uuid, 'Director', false),
    ('e705093c-fed8-5b45-9e86-3065f285411c'::uuid, '8bafacda-74e9-5bea-844e-c83c9ced4dff'::uuid, 'cb5b322a-a7b4-57e0-a76f-080aa8d19668'::uuid, 'Director', false),
    ('1e426572-886d-55e9-aade-7319e142ac39'::uuid, '8bafacda-74e9-5bea-844e-c83c9ced4dff'::uuid, 'cb5b322a-a7b4-57e0-a76f-080aa8d19668'::uuid, 'Director', false),
    ('10995d9c-15d7-5148-97fb-20d7d8357edd'::uuid, '8bafacda-74e9-5bea-844e-c83c9ced4dff'::uuid, 'cb5b322a-a7b4-57e0-a76f-080aa8d19668'::uuid, 'Director', false),
    ('0fbc37c4-d8f7-5909-8b5c-1b0078ebd735'::uuid, '8bafacda-74e9-5bea-844e-c83c9ced4dff'::uuid, 'cb5b322a-a7b4-57e0-a76f-080aa8d19668'::uuid, 'Director', false)
  ) AS v(id, cid, did, title, vac)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.id);

-- ─── 5. Politician rows for directors not already in the DB (party NULL: never stored) ─────
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, party_short_name,
                                    is_active, is_incumbent, is_vacant, is_appointed, data_source)
SELECT v.id, v.first_name, v.last_name, v.full_name, NULL, NULL, true, true, false, v.appt, v.url
  FROM (VALUES
    ('dd99ed5b-8fae-558a-adcf-e6e3b75457d8'::uuid, 'Raymond', 'Rodriguez', 'Raymond M. Rodriguez', true, 'https://www.picowaterdistrict.net/governance/'),
    ('337b5faa-8b51-586d-9657-f8b2ee95af1c'::uuid, 'Victor', 'Caballero', 'Victor Caballero', true, 'https://www.picowaterdistrict.net/governance/'),
    ('5adf725e-31aa-5339-9b75-c98007aaf748'::uuid, 'David', 'Angelo', 'David Angelo', true, 'https://www.picowaterdistrict.net/governance/'),
    ('d27b3e62-51ff-5d27-9ac7-3672de154364'::uuid, 'Pete', 'Ramirez', 'Pete Ramirez', true, 'https://www.picowaterdistrict.net/governance/'),
    ('6227cbad-8dad-5607-bf80-a043ab4f08ff'::uuid, 'David', 'Gonzales', 'David Raul Gonzales', true, 'https://www.picowaterdistrict.net/governance/'),
    ('c298be65-c8ae-5abe-8be6-48a0348390f1'::uuid, 'Brian', 'Richmond', 'Brian Richmond', true, 'https://wvcwd.myruralwater.com/'),
    ('098e2ba4-7ab5-58bf-b96d-4eac15fecde8'::uuid, 'Lisa', 'Ballentine', 'Lisa Ballentine', true, 'https://wvcwd.myruralwater.com/'),
    ('56bf8769-59a6-54ed-87b0-efc02bd59a88'::uuid, 'Jessie', 'Kerr', 'Jessie Kerr', true, 'https://wvcwd.myruralwater.com/'),
    ('6cbc0be6-ed86-514d-afd5-5147986f8561'::uuid, 'Kenneth', 'Hooker', 'Kenneth Hooker', false, 'https://wvcwd.myruralwater.com/'),
    ('5d84a2a5-755e-5848-8447-108eddf514fd'::uuid, 'Teresa', 'Green', 'Teresa Green', false, 'https://wvcwd.myruralwater.com/')
  ) AS v(id, first_name, last_name, full_name, appt, url)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

-- ─── 6. Seat the current directors ────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, v.ts, v.prec, v.how, v.src
  FROM (VALUES
    ('84c44468-866f-5cf9-b60a-26f2fff70860'::uuid, 'dd99ed5b-8fae-558a-adcf-e6e3b75457d8'::uuid, '2022-12-01'::date, 'month', 'appointed', 'CA_0248: seated per https://www.picowaterdistrict.net/governance/ (read 2026-09-24) -- "Raymond Rodriguez, President". Term basis: sole filers for the 3 seats on the RR/CC Nov 2022 list (lavote.gov/Apps/CandidateList/Index?id=4300: ANGELO, CABALLERO, RODRIGUEZ), no contest in the results -> appointed in lieu of election. RR/CC List of Offices, Nov 3 2026 (content.lavote.gov/docs/rrcc/documents/list-of-offices-booklet-8-5-2026.pdf): "Pico 3 Full Terms Victor Caballero / David Angelo / Raymond Rodriguez".'),
    ('82270457-58c5-5d16-9866-2f24ffbfb896'::uuid, '337b5faa-8b51-586d-9657-f8b2ee95af1c'::uuid, '2022-12-01'::date, 'month', 'appointed', 'CA_0248: seated per https://www.picowaterdistrict.net/governance/ (read 2026-09-24) -- "Victor Caballero, Director". Term basis: sole filers for the 3 seats on the RR/CC Nov 2022 list (id=4300), no contest -> appointed in lieu of election.'),
    ('d8dc240e-a77a-56df-95e2-f0bdec39c312'::uuid, '5adf725e-31aa-5339-9b75-c98007aaf748'::uuid, '2022-12-01'::date, 'month', 'appointed', 'CA_0248: seated per https://www.picowaterdistrict.net/governance/ (read 2026-09-24) -- "David Angelo, Director". Term basis: sole filers for the 3 seats on the RR/CC Nov 2022 list (id=4300), no contest -> appointed in lieu of election.'),
    ('6eae810b-919a-5052-a886-f8ec691eb2e3'::uuid, 'd27b3e62-51ff-5d27-9ac7-3672de154364'::uuid, '2024-12-01'::date, 'month', 'appointed', 'CA_0248: seated per https://www.picowaterdistrict.net/governance/ (read 2026-09-24) -- "Elpidio "Pete" Ramirez, Vice President". Term basis: LA County Board of Supervisors Statement of Proceedings Nov 26 2024, item 1 "In Lieu of Election" (file.lacounty.gov/SDSInter/bos/sop/1172054_112624.pdf) -- appointed in lieu of election for the term starting Dec 2024. Listed as "E A Pete Ramirez".'),
    ('dcc652f5-ebcd-5445-a9a4-7f4f56283826'::uuid, '6227cbad-8dad-5607-bf80-a043ab4f08ff'::uuid, '2024-12-01'::date, 'month', 'appointed', 'CA_0248: seated per https://www.picowaterdistrict.net/governance/ (read 2026-09-24) -- "David Gonzales, Director". Term basis: LA County Board of Supervisors Statement of Proceedings Nov 26 2024, item 1 "In Lieu of Election" (file.lacounty.gov/SDSInter/bos/sop/1172054_112624.pdf) -- appointed in lieu of election for the term starting Dec 2024.'),
    ('5715aa13-060d-57be-aeb3-182ce13513bc'::uuid, 'c298be65-c8ae-5abe-8be6-48a0348390f1'::uuid, '2024-12-01'::date, 'month', 'appointed', 'CA_0248: seated per https://wvcwd.myruralwater.com/ (read 2026-09-24) -- "President B. Richmond (board agenda 2026-08-25)". Term basis: LA County Board of Supervisors Statement of Proceedings Nov 26 2024, item 1 "In Lieu of Election" (file.lacounty.gov/SDSInter/bos/sop/1172054_112624.pdf) -- appointed in lieu of election for the term starting Dec 2024.'),
    ('e705093c-fed8-5b45-9e86-3065f285411c'::uuid, '098e2ba4-7ab5-58bf-b96d-4eac15fecde8'::uuid, '2024-12-03'::date, 'day', 'appointed', 'CA_0248: seated per https://wvcwd.myruralwater.com/ (read 2026-09-24) -- "Vice President E. Ballentine (board agenda 2026-08-25)". Term basis: district board Resolution 2-2024, Dec 3 2024, filled a 2024-cycle seat that had no filer (December 2024 board minutes, wvcwd.myruralwater.com/documents/1675/WCVWD_December_2024_Board_Minutes_000028.pdf).'),
    ('1e426572-886d-55e9-aade-7319e142ac39'::uuid, '56bf8769-59a6-54ed-87b0-efc02bd59a88'::uuid, '2025-04-22'::date, 'day', 'appointed', 'CA_0248: seated per https://wvcwd.myruralwater.com/ (read 2026-09-24) -- "Director J. Kerr (board agenda 2026-08-25)". Term basis: "Jesse Kerr is voted into the vacant board seat" (board minutes 2025-04-22, wvcwd.myruralwater.com/documents/1675/Minutes_-_04.22.2025.pdf); unexpired term to Dec 1 2028 (special election Nov 3 2026, no filer).'),
    ('10995d9c-15d7-5148-97fb-20d7d8357edd'::uuid, '6cbc0be6-ed86-514d-afd5-5147986f8561'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0248: seated per https://wvcwd.myruralwater.com/ (read 2026-09-24) -- "Secretary K. Hooker (board agenda 2026-08-25)". Term basis: RR/CC List of Offices, Nov 3 2026 (content.lavote.gov/docs/rrcc/documents/list-of-offices-booklet-8-5-2026.pdf): 2 full terms up 2026 (Kenneth Hooker, Teresa Green); no filer for these seats on the RR/CC Nov 2022 list, and start date not published.'),
    ('0fbc37c4-d8f7-5909-8b5c-1b0078ebd735'::uuid, '5d84a2a5-755e-5848-8447-108eddf514fd'::uuid, NULL::date, 'unknown', 'unknown', 'CA_0248: seated per https://wvcwd.myruralwater.com/ (read 2026-09-24) -- "Director T. Green (board agenda 2026-08-25)". Term basis: RR/CC List of Offices, Nov 3 2026 (content.lavote.gov/docs/rrcc/documents/list-of-offices-booklet-8-5-2026.pdf): 2 full terms up 2026 (Kenneth Hooker, Teresa Green); no filer for these seats on the RR/CC Nov 2022 list, and start date not published.')
  ) AS v(oid, pid, ts, prec, how, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid AND t.politician_id = v.pid);

-- ─── 7b. Westfield Rec & Park: 5th director (CA_0244 modeled 4 of 5) ─────────────────────────
UPDATE essentials.districts SET num_officials = 5 WHERE id = '97c7f73d-425c-5ba9-989b-fa20cac51f31'::uuid AND num_officials <> 5;
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers)
SELECT 'f42d5977-8a96-555b-980d-56e1d094553d'::uuid, '5e2fa7c5-fcc4-53f0-af24-325488757422'::uuid, '97c7f73d-425c-5ba9-989b-fa20cac51f31'::uuid, 'Director', 'CA', 1, 'Board Member', false, false, false, 'full'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = 'f42d5977-8a96-555b-980d-56e1d094553d'::uuid);
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, party_short_name,
                                    is_active, is_incumbent, is_vacant, is_appointed, data_source)
SELECT '702b5de8-d74a-54ce-a858-ecb905e2edb4'::uuid, 'Brenda', 'Swanney-Caropino', 'Brenda L. Swanney-Caropino', NULL, NULL, true, true, false, true,
       'https://file.lacounty.gov/SDSInter/bos/sop/1172054_112624.pdf'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = '702b5de8-d74a-54ce-a858-ecb905e2edb4'::uuid);
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT 'f42d5977-8a96-555b-980d-56e1d094553d'::uuid, '702b5de8-d74a-54ce-a858-ecb905e2edb4'::uuid, '2024-12-01'::date, 'month', 'appointed',
       'CA_0248: LA County BOS Statement of Proceedings Nov 26 2024, item 1 "In Lieu of Election": "Alan R. Hoffman+ and Brenda L. Swanney-Caropino+, Westfield Recreation and Park District" (file.lacounty.gov/SDSInter/bos/sop/1172054_112624.pdf). Appointed in lieu of election for the term Dec 2024 - Dec 2028 (she did not file; RR/CC Nov 2024 list id=4324 shows BRENDA LEE SWANNEY CAROPINO, incumbent, papers not filed).'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = 'f42d5977-8a96-555b-980d-56e1d094553d'::uuid AND t.politician_id = '702b5de8-d74a-54ce-a858-ecb905e2edb4'::uuid);

-- ─── 7c. Appointee start dates found after CA_0242 / CA_0244 ──────────────────────────────────
UPDATE essentials.office_terms SET term_start = '2025-05-21'::date, start_precision = 'day',
       source = source || ' | CA_0248: appointed May 21 2025 -- SMID board agenda 2025-05-21 "Nomination and Appointment of Director for Division 1" + oath of office; on the roll call from Jun 18 2025.'
 WHERE office_id = 'b9795fc3-51bf-5e02-8a55-41d4750f10ee'::uuid AND politician_id = '86d59fe7-ca3f-5c98-ab72-05ce5fc8fc19'::uuid AND term_start IS NULL;
UPDATE essentials.office_terms SET term_start = '2023-05-01'::date, start_precision = 'month',
       source = source || ' | CA_0248: appointed about May 2023 -- Palm Ranch ID board agenda 2023-05-10 "interviews of those individuals interested in being appointed to the vacant Board seat" (Spalla seat); district site lists Gilliland by May 2024.'
 WHERE office_id = '21355f02-f40f-50b9-9fe2-94616070aa01'::uuid AND politician_id = '5b39eb59-55ba-5bb9-ac49-206c2b269cd8'::uuid AND term_start IS NULL;
UPDATE essentials.office_terms SET term_start = NULL, start_precision = 'unknown',
       source = source || ' | CA_0248: start date reset to unknown -- the BOS in-lieu list of Nov 26 2024 appointed only Russell Delgado to Green Valley''s 2 seats, so Garth was appointed by the district board after Dec 2024 (RR/CC List of Offices 2026: "1 Unexpired Term ending 12/01/2028 Robert Garth (A)"); no district minutes online after Oct 2024.'
 WHERE office_id = '1984d028-4ce2-53cd-98c4-e42248b585fb'::uuid AND politician_id = 'ccece634-ffe5-5afa-b1fb-39c9651b6539'::uuid AND term_start = '2025-01-01'::date;

-- ─── 8. Post-verify gate ──────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; n2 int;
BEGIN
  SELECT count(*) INTO n FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'X-CA-SPD' AND gb.geo_id IN (SELECT d.geo_id FROM essentials.districts d WHERE d.government_id IN ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid))
     AND public.ST_IsValid(gb.geometry) AND NOT public.ST_IsEmpty(gb.geometry) AND public.ST_SRID(gb.geometry) = 4326;
  IF n <> 2 THEN RAISE EXCEPTION 'expected 2 valid polygons, got %', n; END IF;

  SELECT count(*) INTO n FROM essentials.districts d WHERE d.government_id IN ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid) AND d.district_type = 'LOCAL' AND d.mtfcc = 'X-CA-SPD';
  IF n <> 2 THEN RAISE EXCEPTION 'expected 2 LOCAL districts, got %', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE d.government_id IN ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid);
  IF n <> 10 THEN RAISE EXCEPTION 'expected 10 offices, got %', n; END IF;

  -- every held seat is held by exactly the director named for it (office_current_holder = query-time occupant)
  SELECT count(*) INTO n FROM (VALUES ('84c44468-866f-5cf9-b60a-26f2fff70860'::uuid, 'dd99ed5b-8fae-558a-adcf-e6e3b75457d8'::uuid), ('82270457-58c5-5d16-9866-2f24ffbfb896'::uuid, '337b5faa-8b51-586d-9657-f8b2ee95af1c'::uuid), ('d8dc240e-a77a-56df-95e2-f0bdec39c312'::uuid, '5adf725e-31aa-5339-9b75-c98007aaf748'::uuid), ('6eae810b-919a-5052-a886-f8ec691eb2e3'::uuid, 'd27b3e62-51ff-5d27-9ac7-3672de154364'::uuid), ('dcc652f5-ebcd-5445-a9a4-7f4f56283826'::uuid, '6227cbad-8dad-5607-bf80-a043ab4f08ff'::uuid), ('5715aa13-060d-57be-aeb3-182ce13513bc'::uuid, 'c298be65-c8ae-5abe-8be6-48a0348390f1'::uuid), ('e705093c-fed8-5b45-9e86-3065f285411c'::uuid, '098e2ba4-7ab5-58bf-b96d-4eac15fecde8'::uuid), ('1e426572-886d-55e9-aade-7319e142ac39'::uuid, '56bf8769-59a6-54ed-87b0-efc02bd59a88'::uuid), ('10995d9c-15d7-5148-97fb-20d7d8357edd'::uuid, '6cbc0be6-ed86-514d-afd5-5147986f8561'::uuid), ('0fbc37c4-d8f7-5909-8b5c-1b0078ebd735'::uuid, '5d84a2a5-755e-5848-8447-108eddf514fd'::uuid)) AS v(oid, pid)
    JOIN essentials.office_current_holder och ON och.office_id = v.oid AND och.politician_id = v.pid;
  IF n <> 10 THEN RAISE EXCEPTION 'expected 10 seats each held by its named director, got %', n; END IF;

  SELECT count(*) INTO n FROM (VALUES ('84c44468-866f-5cf9-b60a-26f2fff70860'::uuid, 'dd99ed5b-8fae-558a-adcf-e6e3b75457d8'::uuid), ('82270457-58c5-5d16-9866-2f24ffbfb896'::uuid, '337b5faa-8b51-586d-9657-f8b2ee95af1c'::uuid), ('d8dc240e-a77a-56df-95e2-f0bdec39c312'::uuid, '5adf725e-31aa-5339-9b75-c98007aaf748'::uuid), ('6eae810b-919a-5052-a886-f8ec691eb2e3'::uuid, 'd27b3e62-51ff-5d27-9ac7-3672de154364'::uuid), ('dcc652f5-ebcd-5445-a9a4-7f4f56283826'::uuid, '6227cbad-8dad-5607-bf80-a043ab4f08ff'::uuid), ('5715aa13-060d-57be-aeb3-182ce13513bc'::uuid, 'c298be65-c8ae-5abe-8be6-48a0348390f1'::uuid), ('e705093c-fed8-5b45-9e86-3065f285411c'::uuid, '098e2ba4-7ab5-58bf-b96d-4eac15fecde8'::uuid), ('1e426572-886d-55e9-aade-7319e142ac39'::uuid, '56bf8769-59a6-54ed-87b0-efc02bd59a88'::uuid), ('10995d9c-15d7-5148-97fb-20d7d8357edd'::uuid, '6cbc0be6-ed86-514d-afd5-5147986f8561'::uuid), ('0fbc37c4-d8f7-5909-8b5c-1b0078ebd735'::uuid, '5d84a2a5-755e-5848-8447-108eddf514fd'::uuid)) AS v(oid, pid) JOIN essentials.politicians p ON p.id = v.pid
   WHERE p.party IS NOT NULL OR NOT p.is_active OR NOT p.is_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION '% seated director row(s) carry a party or are not active incumbents', n; END IF;

  -- partition: no two divisions of one district overlap beyond ~1,000 m2 (1e-7 deg2 at 34 N; planar, decision 0006)
  SELECT count(*) INTO n FROM essentials.districts a JOIN essentials.districts c ON c.government_id = a.government_id AND a.geo_id < c.geo_id
    JOIN essentials.geofence_boundaries ga ON ga.geo_id = a.geo_id AND ga.mtfcc = 'X-CA-SPD'
    JOIN essentials.geofence_boundaries gc ON gc.geo_id = c.geo_id AND gc.mtfcc = 'X-CA-SPD'
   WHERE a.government_id IN ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid) AND a.geo_id LIKE '%-div-%' AND c.geo_id LIKE '%-div-%' AND public.ST_Area(public.ST_Intersection(ga.geometry, gc.geometry)) > 1e-7;
  IF n <> 0 THEN RAISE EXCEPTION '% division pair(s) overlap', n; END IF;

  -- END TO END: an interior point of each polygon resolves (geofence -> LOCAL district -> office -> holder)
  -- to exactly that district's own director(s) among this board's seats
  SELECT count(*) INTO n FROM essentials.districts me
    JOIN essentials.geofence_boundaries mg ON mg.geo_id = me.geo_id AND mg.mtfcc = 'X-CA-SPD'
   WHERE me.government_id IN ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid)
     AND (SELECT string_agg(och.politician_id::text, ',' ORDER BY och.politician_id)
            FROM essentials.geofence_boundaries gb
            JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.district_type = 'LOCAL' AND d.mtfcc = gb.mtfcc
            JOIN essentials.offices o ON o.district_id = d.id
            JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
           WHERE d.government_id = me.government_id AND gb.mtfcc = 'X-CA-SPD'
             AND (d.geo_id LIKE '%-div-%') = (me.geo_id LIKE '%-div-%')
             AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(mg.geometry)))
         IS DISTINCT FROM
         (SELECT string_agg(och.politician_id::text, ',' ORDER BY och.politician_id)
            FROM essentials.offices o JOIN essentials.office_current_holder och ON och.office_id = o.id
           WHERE o.district_id = me.id AND och.politician_id IS NOT NULL);
  IF n <> 0 THEN RAISE EXCEPTION '% polygon(s) do not return exactly their own director(s) at an interior point', n; END IF;

  SELECT count(*), count(*) FILTER (WHERE r.office_id IS NULL OR r.primary_party IS NOT NULL) INTO n, n2
    FROM essentials.races r JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.districts d ON d.id = o.district_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND d.government_id IN ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid);
  IF n <> 0 OR n2 <> 0 THEN RAISE EXCEPTION 'expected 0 office-bound nonpartisan races, got % (% bad)', n, n2; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.districts d ON d.id = o.district_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND d.government_id IN ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'expected 0 candidates, got %', n; END IF;

  -- every incumbent candidate is linked to a director seated on this board
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.districts d ON d.id = o.district_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND d.government_id IN ('f3969e07-4866-5e59-99d4-e1763c95631e'::uuid, '2739d9f4-965b-5573-9e48-4966e098fc0c'::uuid) AND rc.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o2 JOIN essentials.districts d2 ON d2.id = o2.district_id
                       JOIN essentials.office_current_holder och ON och.office_id = o2.id
                      WHERE d2.government_id = d.government_id AND och.politician_id = rc.politician_id);
  IF n <> 0 THEN RAISE EXCEPTION '% incumbent candidate(s) not linked to a seated director', n; END IF;


  -- 7b/7c checks
  SELECT count(*) INTO n FROM essentials.office_current_holder och
   WHERE och.office_id = 'f42d5977-8a96-555b-980d-56e1d094553d'::uuid AND och.politician_id = '702b5de8-d74a-54ce-a858-ecb905e2edb4'::uuid;
  IF n <> 1 THEN RAISE EXCEPTION 'Westfield seat 5 not held by Swanney-Caropino'; END IF;
  SELECT count(*) INTO n FROM essentials.offices o WHERE o.district_id = '97c7f73d-425c-5ba9-989b-fa20cac51f31'::uuid;
  IF n <> 5 THEN RAISE EXCEPTION 'Westfield should have 5 offices, got %', n; END IF;
  SELECT count(*) INTO n FROM essentials.office_terms t
   WHERE (t.office_id, t.politician_id, t.term_start, t.start_precision) IN
         (('b9795fc3-51bf-5e02-8a55-41d4750f10ee'::uuid, '86d59fe7-ca3f-5c98-ab72-05ce5fc8fc19'::uuid, '2025-05-21'::date, 'day'),
          ('21355f02-f40f-50b9-9fe2-94616070aa01'::uuid, '5b39eb59-55ba-5bb9-ac49-206c2b269cd8'::uuid, '2023-05-01'::date, 'month'));
  SELECT n + count(*) INTO n FROM essentials.office_terms t
   WHERE t.office_id = '1984d028-4ce2-53cd-98c4-e42248b585fb'::uuid AND t.politician_id = 'ccece634-ffe5-5afa-b1fb-39c9651b6539'::uuid AND t.term_start IS NULL AND t.start_precision = 'unknown';
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 corrected appointee terms, got %', n; END IF;
  SELECT count(*) INTO n FROM essentials.office_current_holder och
   WHERE och.office_id IN ('b9795fc3-51bf-5e02-8a55-41d4750f10ee'::uuid, '21355f02-f40f-50b9-9fe2-94616070aa01'::uuid, '1984d028-4ce2-53cd-98c4-e42248b585fb'::uuid) AND och.politician_id IS NOT NULL;
  IF n <> 3 THEN RAISE EXCEPTION 'corrected appointees must still be current holders, got %', n; END IF;

  RAISE NOTICE 'CA_0248 applied: 2 new boards (Pico WD, West Valley CWD), 2 polygons, 10 seats held; Westfield seat 5 added; 3 appointee start dates corrected';
END $$;

COMMIT;
