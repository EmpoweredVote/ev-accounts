-- CC_0376_nh_executive_council.sql
--
-- New Hampshire's Executive Council — the last body in state-executive tier 3. One chamber, five
-- districts, five offices, the five sitting councilors seated, and the five 2026-11-03 races with
-- all ten candidacies recorded.
--
-- WHAT THIS FILE CREATES: 1 chamber - 5 districts - 5 offices - 5 office_terms - 5 races - 10
-- politicians - 10 candidacies.
--
-- THE DISTRICTS. RSA 662:2 "Councilor Districts", as amended by 2022 N.H. Laws ch. 46 (SB 241),
-- effective 6 May 2022. New Hampshire states the whole composition in words: every town, city and
-- unincorporated place is named, in exactly one of the five districts. The polygons come from
-- NHGRANIT (nhgeodata.unh.edu), service APB_ElectoralDistricts, layer 7 "NHExecDists2022".
--
-- [RED] LAYER 1 OF THAT SERVICE IS "NHExecCo2012", THE SUPERSEDED MAP, AND ONLY THE YEAR IN THE
-- LAYER NAME TELLS THEM APART. Both are five valid, disjoint polygons covering the whole state;
-- both report the same extent; and measured, the 2012 map covers the TIGER state outline to
-- 99.6836%, the SAME FIGURE AS THE CURRENT MAP TO FOUR DECIMAL PLACES, because both are complete
-- partitions. No structural gate can separate them. The statute can, on 66 of 259 towns, and that
-- is what the anchor table below exists for. The loader's control B is the superseded map itself,
-- not a synthetic tamper.
--
-- [RED] THE CRS TRAP. The NHGRANIT layer is native wkid 3437 — NAD83 New Hampshire State Plane in
-- US SURVEY FEET. Loaded as 4326 it is valid, correctly shaped and matches no address on Earth.
-- The fetcher asks the server for outSR=4326 and bounds-checks every coordinate; the loader checks
-- the bounding boxes again after INSERT; and this file checks them a third time before creating
-- anything.
--
-- [GREEN] THE ANCHOR IS COMPLETE, SO NO DISTRICT IS UNPINNED. Nebraska had to record two pairs of
-- districts that no available evidence could separate, and New Mexico four. New Hampshire has
-- none: the post-verify below walks the full chain — a Census internal point, the geofence polygon
-- that covers it, the district row, the office, the current holder — for ALL 259 towns the statute
-- names, and every one must reach the councilor RSA 662:2 implies. No permutation of five
-- districts survives that.
--
-- [WARN] ONLY ONE OF THE TEN COUNTIES LIES WHOLLY IN ONE DISTRICT — Carroll, in district 1. The
-- tier-3 inventory predicted several would, and nine of ten are split, Hillsborough four ways. The
-- whole-county gate that carried Alabama and Louisiana would have had a single usable row here and
-- would have LOOKED anchored. It is kept below as corroboration, not as the anchor.
--
-- THE PEOPLE. All five sitting councilors took office on 2025-01-09, from the primary record: New
-- Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE" — "Governor Ayotte administered
-- the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet
-- Stevens, John Stephen and David Wheeler". The same Journal seats the councilors-elect by
-- district, which is a second source for the district assignments beside council.nh.gov's own
-- pages.
--
-- [RED] A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT, AND NONE OF THESE WINNERS HOLDS
-- ONE YET. Four of the five sitting councilors were defeated on 2026-11-03; they remain in office
-- until the oath is administered in January 2027. This file seats the CURRENT holders and records
-- the winners as race results only.
--
-- [RED] AND THE HANDOVER DATE IS NOT KNOWN YET, SO IT IS NOT WRITTEN DOWN. N.H. Const. pt. 2, art.
-- 60 fixes when the votes are LAID BEFORE the General Court — "the first Wednesday following the
-- first Tuesday of January", which is 2027-01-06 — and that is a date for the COUNT, not for the
-- oath. In 2025 the votes went before them on Wednesday 8 January and the Joint Convention
-- administered the oath on Thursday 9 January. Read the date a source gives before reusing it: the
-- constitutional date is one day early at best and is a date of a different event. The follow-up
-- below says to read the House Journal, not to assume a day.
--
-- [WARN] THE RESULTS ARE RETURNS, NOT A CANVASS. The Secretary of State's page states: "Tallies
-- accurately reflect the returns of votes reported by clerks but are subject to change if clerks
-- submit amendments." Every candidacy is recorded with result_certainty 'called'.
--
-- NO READ-PATH CHANGE IS NEEDED. These seats file under (X-ST-BOARD, STATE_BOARD), which CC_0366
-- registered in districtQueries.ts and geoIdGuard.ts and which is on master.
--
-- FOLLOW-UP, January 2027: seat Luz Bay (D1), Karen Liot Hill (D2, re-elected), Lisa Kennedy
-- Sheldon (D3), Jim O'Connell (D4) and Melanie Levesque (D5), on the date the House Journal
-- records the oath. Close the four defeated councilors' terms the day before.
--
-- PREREQUISITE: node scripts/CC_0376-nh-exec-geofences.mjs --geojson ... --composition ... must
-- have run and committed. This file refuses otherwise.

BEGIN;

-- The seats, their sitting holders, and whether a 2026 race is recorded for each.
CREATE TEMP TABLE seat (
  d int PRIMARY KEY, who text NOT NULL, party text NOT NULL, race_recorded boolean NOT NULL
) ON COMMIT DROP;
INSERT INTO seat VALUES
  (1, 'Joseph D. Kenney', 'r', true),
  (2, 'Karen Liot Hill', 'd', true),
  (3, 'Janet Stevens', 'r', true),
  (4, 'John Stephen', 'r', true),
  (5, 'David K. Wheeler', 'r', true);

-- 🟢 THE ANCHOR: every town, city and unincorporated place RSA 662:2 names, with the Census
--    Bureau's internal point for it. Neither column comes from the NHGRANIT map.
CREATE TEMP TABLE anchor (
  town text PRIMARY KEY, county text NOT NULL, d int NOT NULL, lon float8 NOT NULL, lat float8 NOT NULL
) ON COMMIT DROP;
INSERT INTO anchor VALUES
  ('Alton', 'Belknap', 1, -71.240617, 43.488323),
  ('Barnstead', 'Belknap', 4, -71.256896, 43.348588),
  ('Belmont', 'Belknap', 1, -71.482208, 43.474455),
  ('Center Harbor', 'Belknap', 1, -71.510443, 43.702775),
  ('Gilford', 'Belknap', 1, -71.375838, 43.519499),
  ('Gilmanton', 'Belknap', 1, -71.366322, 43.43159),
  ('Laconia', 'Belknap', 1, -71.482263, 43.576535),
  ('Meredith', 'Belknap', 1, -71.498585, 43.631211),
  ('New Hampton', 'Belknap', 1, -71.632547, 43.623436),
  ('Sanbornton', 'Belknap', 1, -71.601607, 43.524186),
  ('Tilton', 'Belknap', 1, -71.576458, 43.471211),
  ('Albany', 'Carroll', 1, -71.274251, 43.95945),
  ('Bartlett', 'Carroll', 1, -71.221265, 44.077237),
  ('Brookfield', 'Carroll', 1, -71.093391, 43.561279),
  ('Chatham', 'Carroll', 1, -71.060691, 44.127498),
  ('Conway', 'Carroll', 1, -71.06517, 44.005785),
  ('Eaton', 'Carroll', 1, -71.04752, 43.90696),
  ('Effingham', 'Carroll', 1, -71.04191, 43.746733),
  ('Freedom', 'Carroll', 1, -71.075161, 43.842036),
  ('Hale''s Location', 'Carroll', 1, -71.170888, 44.038403),
  ('Hart''s Location', 'Carroll', 1, -71.375531, 44.140888),
  ('Jackson', 'Carroll', 1, -71.155763, 44.18762),
  ('Madison', 'Carroll', 1, -71.15382, 43.908458),
  ('Moultonborough', 'Carroll', 1, -71.368582, 43.720515),
  ('Ossipee', 'Carroll', 1, -71.150349, 43.737249),
  ('Sandwich', 'Carroll', 1, -71.443132, 43.838564),
  ('Tamworth', 'Carroll', 1, -71.296068, 43.864038),
  ('Tuftonboro', 'Carroll', 1, -71.275891, 43.669877),
  ('Wakefield', 'Carroll', 1, -71.010062, 43.593582),
  ('Wolfeboro', 'Carroll', 1, -71.169156, 43.614448),
  ('Alstead', 'Cheshire', 2, -72.310321, 43.091742),
  ('Chesterfield', 'Cheshire', 2, -72.443472, 42.888002),
  ('Dublin', 'Cheshire', 2, -72.069849, 42.889279),
  ('Fitzwilliam', 'Cheshire', 5, -72.153028, 42.753205),
  ('Gilsum', 'Cheshire', 2, -72.262369, 43.041227),
  ('Harrisville', 'Cheshire', 2, -72.068986, 42.948536),
  ('Hinsdale', 'Cheshire', 2, -72.504822, 42.809298),
  ('Jaffrey', 'Cheshire', 5, -72.059901, 42.829254),
  ('Keene', 'Cheshire', 2, -72.306875, 42.953842),
  ('Marlborough', 'Cheshire', 2, -72.177684, 42.886226),
  ('Marlow', 'Cheshire', 2, -72.208769, 43.138544),
  ('Nelson', 'Cheshire', 2, -72.121703, 42.999482),
  ('Richmond', 'Cheshire', 5, -72.278745, 42.773484),
  ('Rindge', 'Cheshire', 5, -72.013247, 42.756663),
  ('Roxbury', 'Cheshire', 2, -72.199742, 42.951105),
  ('Stoddard', 'Cheshire', 5, -72.113952, 43.076314),
  ('Sullivan', 'Cheshire', 2, -72.214374, 43.020616),
  ('Surry', 'Cheshire', 2, -72.343383, 43.018778),
  ('Swanzey', 'Cheshire', 5, -72.29636, 42.858271),
  ('Troy', 'Cheshire', 5, -72.188943, 42.828798),
  ('Walpole', 'Cheshire', 2, -72.403127, 43.081102),
  ('Westmoreland', 'Cheshire', 2, -72.430856, 42.968075),
  ('Winchester', 'Cheshire', 2, -72.395238, 42.789314),
  ('Atkinson and Gilmanton Academy Grant', 'Coos', 1, -71.122281, 44.995891),
  ('Bean''s Grant', 'Coos', 1, -71.376589, 44.222683),
  ('Bean''s Purchase', 'Coos', 1, -71.152198, 44.289758),
  ('Berlin', 'Coos', 1, -71.277123, 44.484328),
  ('Cambridge', 'Coos', 1, -71.097522, 44.659301),
  ('Carroll', 'Coos', 2, -71.497376, 44.305266),
  ('Chandler''s Purchase', 'Coos', 1, -71.358654, 44.261058),
  ('Clarksville', 'Coos', 1, -71.325569, 45.018249),
  ('Colebrook', 'Coos', 1, -71.409528, 44.895204),
  ('Columbia', 'Coos', 1, -71.512441, 44.816184),
  ('Crawford''s Purchase', 'Coos', 1, -71.40151, 44.262335),
  ('Cutt''s Grant', 'Coos', 1, -71.33583, 44.204927),
  ('Dalton', 'Coos', 1, -71.688907, 44.394773),
  ('Dix''s Grant', 'Coos', 1, -71.191801, 44.920423),
  ('Dixville', 'Coos', 1, -71.256477, 44.869592),
  ('Dummer', 'Coos', 1, -71.251806, 44.66501),
  ('Errol', 'Coos', 1, -71.108812, 44.758253),
  ('Erving''s Location', 'Coos', 1, -71.343659, 44.800424),
  ('Gorham', 'Coos', 1, -71.1985, 44.393447),
  ('Green''s Grant', 'Coos', 1, -71.218153, 44.290017),
  ('Hadley''s Purchase', 'Coos', 1, -71.332407, 44.126078),
  ('Jefferson', 'Coos', 1, -71.464694, 44.396741),
  ('Kilkenny', 'Coos', 1, -71.405486, 44.479595),
  ('Lancaster', 'Coos', 1, -71.544158, 44.472409),
  ('Low and Burbank''s Grant', 'Coos', 1, -71.348094, 44.329511),
  ('Martin''s Location', 'Coos', 1, -71.202479, 44.330433),
  ('Milan', 'Coos', 1, -71.218269, 44.55386),
  ('Millsfield', 'Coos', 1, -71.261574, 44.747716),
  ('Northumberland', 'Coos', 1, -71.5193, 44.568495),
  ('Odell', 'Coos', 1, -71.381331, 44.744941),
  ('Pinkham''s Grant', 'Coos', 1, -71.241579, 44.256955),
  ('Pittsburg', 'Coos', 1, -71.254877, 45.145326),
  ('Randolph', 'Coos', 1, -71.305053, 44.397489),
  ('Sargent''s Purchase', 'Coos', 1, -71.302898, 44.215547),
  ('Second College Grant', 'Coos', 1, -71.125487, 44.92427),
  ('Shelburne', 'Coos', 1, -71.087115, 44.367172),
  ('Stark', 'Coos', 1, -71.403249, 44.595126),
  ('Stewartstown', 'Coos', 1, -71.406991, 44.96067),
  ('Stratford', 'Coos', 1, -71.52754, 44.715053),
  ('Success', 'Coos', 1, -71.072713, 44.512692),
  ('Thompson & Meserve''s Purchase', 'Coos', 1, -71.277804, 44.297119),
  ('Wentworth''s Location', 'Coos', 1, -71.095874, 44.845026),
  ('Whitefield', 'Coos', 1, -71.589598, 44.375513),
  ('Alexandria', 'Grafton', 1, -71.856277, 43.622322),
  ('Ashland', 'Grafton', 2, -71.642579, 43.725967),
  ('Bath', 'Grafton', 2, -71.987011, 44.182955),
  ('Benton', 'Grafton', 2, -71.846557, 44.035925),
  ('Bethlehem', 'Grafton', 2, -71.609203, 44.260435),
  ('Bridgewater', 'Grafton', 1, -71.686005, 43.651247),
  ('Bristol', 'Grafton', 1, -71.710324, 43.624415),
  ('Campton', 'Grafton', 2, -71.64607, 43.830862),
  ('Canaan', 'Grafton', 2, -72.043987, 43.687687),
  ('Dorchester', 'Grafton', 2, -71.988184, 43.748186),
  ('Easton', 'Grafton', 2, -71.795115, 44.101177),
  ('Ellsworth', 'Grafton', 2, -71.768996, 43.911799),
  ('Enfield', 'Grafton', 2, -72.118598, 43.603314),
  ('Franconia', 'Grafton', 2, -71.618733, 44.177045),
  ('Grafton', 'Grafton', 2, -71.951919, 43.574691),
  ('Groton', 'Grafton', 2, -71.86493, 43.725276),
  ('Hanover', 'Grafton', 2, -72.185207, 43.721023),
  ('Haverhill', 'Grafton', 2, -72.00465, 44.075844),
  ('Hebron', 'Grafton', 1, -71.792047, 43.693579),
  ('Holderness', 'Grafton', 2, -71.582529, 43.761761),
  ('Landaff', 'Grafton', 2, -71.885201, 44.160094),
  ('Lebanon', 'Grafton', 2, -72.253837, 43.635428),
  ('Lincoln', 'Grafton', 2, -71.631382, 44.09469),
  ('Lisbon', 'Grafton', 2, -71.848617, 44.242257),
  ('Littleton', 'Grafton', 2, -71.795118, 44.343351),
  ('Livermore', 'Grafton', 1, -71.420016, 44.069466),
  ('Lyman', 'Grafton', 2, -71.934489, 44.257464),
  ('Lyme', 'Grafton', 2, -72.094295, 43.816634),
  ('Monroe', 'Grafton', 2, -71.980684, 44.296605),
  ('Orange', 'Grafton', 2, -71.921827, 43.679341),
  ('Orford', 'Grafton', 2, -72.033845, 43.883333),
  ('Piermont', 'Grafton', 2, -72.001293, 43.961851),
  ('Plymouth', 'Grafton', 2, -71.726744, 43.743912),
  ('Rumney', 'Grafton', 2, -71.774335, 43.834707),
  ('Sugar Hill', 'Grafton', 2, -71.80024, 44.21841),
  ('Thornton', 'Grafton', 2, -71.635785, 43.947877),
  ('Warren', 'Grafton', 2, -71.859117, 43.965803),
  ('Waterville Valley', 'Grafton', 1, -71.448052, 43.942831),
  ('Wentworth', 'Grafton', 2, -71.923718, 43.858721),
  ('Woodstock', 'Grafton', 2, -71.714447, 43.999889),
  ('Amherst', 'Hillsborough', 5, -71.600533, 42.874824),
  ('Antrim', 'Hillsborough', 5, -71.981968, 43.050292),
  ('Bedford', 'Hillsborough', 4, -71.536871, 42.935584),
  ('Bennington', 'Hillsborough', 5, -71.903705, 43.020284),
  ('Brookline', 'Hillsborough', 5, -71.67567, 42.749263),
  ('Deering', 'Hillsborough', 5, -71.860603, 43.083105),
  ('Francestown', 'Hillsborough', 5, -71.816098, 42.994135),
  ('Goffstown', 'Hillsborough', 4, -71.555445, 43.019198),
  ('Greenfield', 'Hillsborough', 5, -71.879424, 42.93874),
  ('Greenville', 'Hillsborough', 5, -71.799416, 42.757935),
  ('Hancock', 'Hillsborough', 2, -71.997821, 42.977339),
  ('Hillsborough', 'Hillsborough', 5, -71.951025, 43.146685),
  ('Hollis', 'Hillsborough', 5, -71.585402, 42.749624),
  ('Hudson', 'Hillsborough', 5, -71.409393, 42.760497),
  ('Litchfield', 'Hillsborough', 5, -71.468283, 42.846081),
  ('Lyndeborough', 'Hillsborough', 5, -71.768331, 42.896409),
  ('Manchester', 'Hillsborough', 4, -71.444131, 42.984941),
  ('Mason', 'Hillsborough', 5, -71.750968, 42.742181),
  ('Merrimack', 'Hillsborough', 5, -71.519876, 42.852034),
  ('Milford', 'Hillsborough', 5, -71.673354, 42.818645),
  ('Mont Vernon', 'Hillsborough', 5, -71.694199, 42.908885),
  ('Nashua', 'Hillsborough', 5, -71.490544, 42.749074),
  ('New Boston', 'Hillsborough', 5, -71.67752, 42.981209),
  ('New Ipswich', 'Hillsborough', 5, -71.874434, 42.746257),
  ('Pelham', 'Hillsborough', 3, -71.337075, 42.730992),
  ('Peterborough', 'Hillsborough', 2, -71.941157, 42.890077),
  ('Sharon', 'Hillsborough', 2, -71.934424, 42.816215),
  ('Temple', 'Hillsborough', 5, -71.875416, 42.826723),
  ('Weare', 'Hillsborough', 5, -71.703508, 43.078287),
  ('Wilton', 'Hillsborough', 5, -71.769155, 42.835302),
  ('Windsor', 'Hillsborough', 5, -72.013639, 43.113044),
  ('Allenstown', 'Merrimack', 4, -71.386106, 43.143341),
  ('Andover', 'Merrimack', 2, -71.7906, 43.450724),
  ('Boscawen', 'Merrimack', 2, -71.665381, 43.311717),
  ('Bow', 'Merrimack', 2, -71.537242, 43.133177),
  ('Bradford', 'Merrimack', 2, -71.966175, 43.224128),
  ('Canterbury', 'Merrimack', 2, -71.533765, 43.352567),
  ('Chichester', 'Merrimack', 4, -71.408835, 43.265259),
  ('Concord', 'Merrimack', 2, -71.561252, 43.232493),
  ('Danbury', 'Merrimack', 1, -71.868472, 43.528318),
  ('Dunbarton', 'Merrimack', 5, -71.607479, 43.112473),
  ('Epsom', 'Merrimack', 4, -71.348563, 43.204812),
  ('Franklin', 'Merrimack', 1, -71.669893, 43.453915),
  ('Henniker', 'Merrimack', 2, -71.831201, 43.169407),
  ('Hill', 'Merrimack', 1, -71.769192, 43.528306),
  ('Hooksett', 'Merrimack', 4, -71.446616, 43.081242),
  ('Hopkinton', 'Merrimack', 2, -71.696789, 43.202191),
  ('Loudon', 'Merrimack', 4, -71.44913, 43.308134),
  ('Newbury', 'Merrimack', 2, -72.024551, 43.314026),
  ('New London', 'Merrimack', 2, -71.990609, 43.417721),
  ('Northfield', 'Merrimack', 1, -71.555391, 43.401788),
  ('Pembroke', 'Merrimack', 4, -71.438517, 43.167722),
  ('Pittsfield', 'Merrimack', 4, -71.309368, 43.288501),
  ('Salisbury', 'Merrimack', 2, -71.772917, 43.386099),
  ('Sutton', 'Merrimack', 2, -71.918365, 43.335017),
  ('Warner', 'Merrimack', 2, -71.830606, 43.283544),
  ('Webster', 'Merrimack', 2, -71.725682, 43.306572),
  ('Wilmot', 'Merrimack', 2, -71.922446, 43.443284),
  ('Atkinson', 'Rockingham', 3, -71.167192, 42.839113),
  ('Auburn', 'Rockingham', 4, -71.365806, 42.997059),
  ('Brentwood', 'Rockingham', 3, -71.053998, 42.983723),
  ('Candia', 'Rockingham', 4, -71.340635, 43.056895),
  ('Chester', 'Rockingham', 3, -71.255104, 42.98453),
  ('Danville', 'Rockingham', 3, -71.119888, 42.927892),
  ('Deerfield', 'Rockingham', 4, -71.255077, 43.136321),
  ('Derry', 'Rockingham', 3, -71.282047, 42.887613),
  ('East Kingston', 'Rockingham', 3, -71.002633, 42.925865),
  ('Epping', 'Rockingham', 3, -71.088254, 43.051027),
  ('Exeter', 'Rockingham', 3, -70.961542, 42.988453),
  ('Fremont', 'Rockingham', 3, -71.119162, 43.000369),
  ('Greenland', 'Rockingham', 3, -70.845622, 43.039732),
  ('Hampstead', 'Rockingham', 3, -71.171883, 42.881061),
  ('Hampton', 'Rockingham', 3, -70.834273, 42.93913),
  ('Hampton Falls', 'Rockingham', 3, -70.886242, 42.924811),
  ('Kensington', 'Rockingham', 3, -70.964273, 42.93287),
  ('Kingston', 'Rockingham', 3, -71.073595, 42.913731),
  ('Londonderry', 'Rockingham', 4, -71.392326, 42.879789),
  ('New Castle', 'Rockingham', 3, -70.717071, 43.062147),
  ('Newfields', 'Rockingham', 3, -70.967954, 43.038509),
  ('Newington', 'Rockingham', 3, -70.827443, 43.085924),
  ('Newmarket', 'Rockingham', 3, -70.946939, 43.070913),
  ('Newton', 'Rockingham', 3, -71.045915, 42.870369),
  ('North Hampton', 'Rockingham', 3, -70.829441, 42.979934),
  ('Northwood', 'Rockingham', 4, -71.223393, 43.211856),
  ('Nottingham', 'Rockingham', 4, -71.131859, 43.129847),
  ('Plaistow', 'Rockingham', 3, -71.09326, 42.845597),
  ('Portsmouth', 'Rockingham', 3, -70.780349, 43.060594),
  ('Raymond', 'Rockingham', 3, -71.203144, 43.032583),
  ('Rye', 'Rockingham', 3, -70.719223, 43.033467),
  ('Salem', 'Rockingham', 3, -71.221725, 42.788267),
  ('Sandown', 'Rockingham', 3, -71.183605, 42.934018),
  ('Seabrook', 'Rockingham', 3, -70.860823, 42.883123),
  ('South Hampton', 'Rockingham', 3, -70.959546, 42.889802),
  ('Stratham', 'Rockingham', 3, -70.902602, 43.014993),
  ('Windham', 'Rockingham', 3, -71.302688, 42.811092),
  ('Barrington', 'Strafford', 4, -71.03898, 43.215566),
  ('Dover', 'Strafford', 1, -70.883623, 43.18636),
  ('Durham', 'Strafford', 1, -70.918807, 43.117061),
  ('Farmington', 'Strafford', 1, -71.062503, 43.366924),
  ('Lee', 'Strafford', 4, -71.007082, 43.119202),
  ('Madbury', 'Strafford', 1, -70.941453, 43.174607),
  ('Middleton', 'Strafford', 1, -71.070641, 43.483007),
  ('Milton', 'Strafford', 1, -71.014652, 43.452229),
  ('New Durham', 'Strafford', 1, -71.152207, 43.46367),
  ('Rochester', 'Strafford', 1, -70.977005, 43.298493),
  ('Rollinsford', 'Strafford', 1, -70.843107, 43.219815),
  ('Somersworth', 'Strafford', 1, -70.887944, 43.253476),
  ('Strafford', 'Strafford', 4, -71.169956, 43.275384),
  ('Acworth', 'Sullivan', 2, -72.287033, 43.213923),
  ('Charlestown', 'Sullivan', 2, -72.383893, 43.246631),
  ('Claremont', 'Sullivan', 2, -72.334496, 43.38647),
  ('Cornish', 'Sullivan', 2, -72.311749, 43.472988),
  ('Croydon', 'Sullivan', 2, -72.178349, 43.444227),
  ('Goshen', 'Sullivan', 5, -72.101033, 43.272092),
  ('Grantham', 'Sullivan', 2, -72.149093, 43.51659),
  ('Langdon', 'Sullivan', 2, -72.359587, 43.186975),
  ('Lempster', 'Sullivan', 5, -72.184869, 43.236564),
  ('Newport', 'Sullivan', 2, -72.202789, 43.371345),
  ('Plainfield', 'Sullivan', 2, -72.295537, 43.543837),
  ('Springfield', 'Sullivan', 2, -72.038114, 43.491916),
  ('Sunapee', 'Sullivan', 2, -72.093136, 43.390095),
  ('Unity', 'Sullivan', 2, -72.274568, 43.299305),
  ('Washington', 'Sullivan', 5, -72.093871, 43.190051);

-- The county composition, derived from the same statute. One whole, nine split.
CREATE TEMP TABLE plan_county (county text PRIMARY KEY, districts text NOT NULL, whole boolean NOT NULL) ON COMMIT DROP;
INSERT INTO plan_county VALUES
  ('Belknap County', '1,4', false),
  ('Carroll County', '1', true),
  ('Cheshire County', '2,5', false),
  ('Coos County', '1,2', false),
  ('Grafton County', '1,2', false),
  ('Hillsborough County', '2,3,4,5', false),
  ('Merrimack County', '1,2,4,5', false),
  ('Rockingham County', '3,4', false),
  ('Strafford County', '1,4', false),
  ('Sullivan County', '2,5', false);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM seat;   IF n <> 5 THEN RAISE EXCEPTION 'expected 5 seats, found %', n; END IF;
  SELECT count(*) INTO n FROM anchor; IF n <> 259 THEN RAISE EXCEPTION 'expected 259 anchors, found %', n; END IF;
  SELECT count(*) INTO n FROM plan_county; IF n <> 10 THEN RAISE EXCEPTION 'expected New Hampshire''s 10 counties, found %', n; END IF;
  SELECT count(*) INTO n FROM plan_county WHERE whole;
  IF n <> 1 THEN RAISE EXCEPTION 'expected 1 whole county, found %', n; END IF;
  -- every district must carry enough anchors that a label swap cannot hide
  SELECT string_agg('D' || z.d || '=' || z.n, ', ') INTO txt FROM (SELECT d, count(*) n FROM anchor GROUP BY d) z WHERE z.n < 15;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a district has too few anchors to pin it: %', txt; END IF;
  SELECT count(DISTINCT d) INTO n FROM anchor; IF n <> 5 THEN RAISE EXCEPTION 'the anchors cover % districts', n; END IF;
  -- the counties the anchors fall in must be the ten we hold polygons for
  SELECT string_agg(pc.county, ', ') INTO txt FROM plan_county pc
   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g
                      WHERE g.mtfcc = 'G4020' AND g.state = '33' AND g.name = pc.county);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'we hold no county polygon for: %', txt; END IF;

  -- preconditions on rows this file does not create
  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = '6541c097-c589-45e2-bcd1-f187c7bf65a1'::uuid AND name = 'State of New Hampshire')
    THEN RAISE EXCEPTION 'the New Hampshire government row does not exist'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.elections WHERE id = 'c6fcba79-6b3d-4617-b227-5a745c27f849'::uuid AND election_date = DATE '2026-11-03')
    THEN RAISE EXCEPTION 'the election row is not the 2026-11-03 New Hampshire general'; END IF;

  -- idempotence: this file creates, so nothing it creates may already be there
  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE government_id = '6541c097-c589-45e2-bcd1-f187c7bf65a1'::uuid AND name = 'Executive Council')
    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;
  SELECT count(*) INTO n FROM essentials.districts WHERE geo_id LIKE 'ocd-division/country:us/state:nh/council:%';
  IF n <> 0 THEN RAISE EXCEPTION '% district(s) with this body''s geo_id prefix already exist', n; END IF;

  -- 🔴 THE POLYGONS MUST BE LOADED, AND THEY MUST BE NEW HAMPSHIRE IN 4326.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X-ST-BOARD' AND state = '33' AND geo_id LIKE 'ocd-division/country:us/state:nh/council:%';
  IF n <> 5 THEN RAISE EXCEPTION 'only % of the 5 councilor polygons are loaded — run scripts/CC_0376-nh-exec-geofences.mjs first', n; END IF;
  SELECT string_agg(g.geo_id || ' srid=' || public.ST_SRID(g.geometry) || ' bbox=' ||
           round(public.ST_XMin(g.geometry)::numeric,3) || ',' || round(public.ST_YMin(g.geometry)::numeric,3) || '..' ||
           round(public.ST_XMax(g.geometry)::numeric,3) || ',' || round(public.ST_YMax(g.geometry)::numeric,3), '; ') INTO txt
    FROM essentials.geofence_boundaries g
   WHERE g.mtfcc = 'X-ST-BOARD' AND g.state = '33' AND g.geo_id LIKE 'ocd-division/country:us/state:nh/council:%'
     AND (public.ST_SRID(g.geometry) <> 4326 OR NOT public.ST_IsValid(g.geometry) OR public.ST_IsEmpty(g.geometry)
          OR public.ST_XMin(g.geometry) < -72.8 OR public.ST_XMax(g.geometry) > -70.4
          OR public.ST_YMin(g.geometry) < 42.5  OR public.ST_YMax(g.geometry) > 45.5);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loaded polygon is not a valid 4326 New Hampshire polygon (wrong CRS?): %', txt; END IF;

  -- 🟢 and the map agrees with the statute, for every town, BEFORE anything is created
  SELECT string_agg(z.town || ': statute D' || z.d || ', map ' || coalesce(z.got, 'NOWHERE'), '; ') INTO txt
    FROM (SELECT a.town, a.d,
                 (SELECT string_agg(replace(g.geo_id, 'ocd-division/country:us/state:nh/council:', ''), ',')
                    FROM essentials.geofence_boundaries g
                   WHERE g.mtfcc = 'X-ST-BOARD' AND g.state = '33' AND g.geo_id LIKE 'ocd-division/country:us/state:nh/council:%'
                     AND public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(a.lon, a.lat), 4326))) AS got
            FROM anchor a) z
   WHERE z.got IS DISTINCT FROM z.d::text;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the map and RSA 662:2 disagree about which district a town is in: %', left(txt, 900); END IF;

  -- the coarse county view, as corroboration
  SELECT string_agg(pc.county || ' -> ' || coalesce(z.got, 'nothing') || ' (statute ' || pc.districts || ')', '; ') INTO txt
    FROM plan_county pc
    LEFT JOIN LATERAL (
      SELECT string_agg(replace(g.geo_id, 'ocd-division/country:us/state:nh/council:', ''), ',' ORDER BY (replace(g.geo_id, 'ocd-division/country:us/state:nh/council:', ''))::int) AS got
        FROM essentials.geofence_boundaries co, essentials.geofence_boundaries g
       WHERE co.mtfcc = 'G4020' AND co.state = '33' AND co.name = pc.county
         AND g.mtfcc = 'X-ST-BOARD' AND g.state = '33' AND g.geo_id LIKE 'ocd-division/country:us/state:nh/council:%'
         AND public.ST_Area(public.ST_Intersection(g.geometry, co.geometry)) > public.ST_Area(co.geometry) * 0.0005) z ON true
   WHERE z.got IS DISTINCT FROM pc.districts;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county is shared by districts RSA 662:2 does not name: %', txt; END IF;
END $$;

-- ─── Chamber, districts, offices ───
CREATE TEMP TABLE made_chamber (chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,
                                   official_count, term_length, staggered_term, website_url,
                                   inauguration_rules, election_rules, remarks)
  VALUES ('Executive Council', 'New Hampshire Executive Council', '6541c097-c589-45e2-bcd1-f187c7bf65a1'::uuid, 'full', 5,
          '2 years', false, 'https://www.council.nh.gov/',
          'All five councilors are elected together at every biennial general election; the council is NOT staggered. N.H. Const. pt. 2, art. 60 requires the returns to be laid before the Senate and House "on the first Wednesday following the first Tuesday of January" — that is the date of the COUNT, not of the oath. The oath is administered afterwards at a Joint Convention: in 2025 the votes went before the General Court on Wednesday 8 January and Governor Ayotte swore the councilors in on Thursday 9 January (House Journal No. 3). For the 2027 handover read the House Journal for the Joint Convention; do not assume 2027-01-06.',
          'Five single-member districts, one councilor each, elected by plurality (N.H. Const. pt. 2, art. 61, amended 1912 substituting plurality for majority). Districts are set by RSA 662:2, as amended by 2022 N.H. Laws ch. 46 (SB 241), eff. 6 May 2022, which names every town, city and unincorporated place in the state.',
          'Advises and consents to the Governor on appointments, contracts and pardons. Created by CC_0376; polygons from NHGRANIT layer 7 NHExecDists2022, anchored on RSA 662:2 via all 259 New Hampshire county subdivisions.')
  RETURNING id)
INSERT INTO made_chamber SELECT id FROM ins;

CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_BOARD', 'nh', 'ocd-division/country:us/state:nh/council:' || s.d, 'ocd-division/country:us/state:nh/council:' || s.d,
         'New Hampshire Executive Council District ' || s.d, 'X-ST-BOARD', s.d::text, 'residency'
    FROM seat s RETURNING id, geo_id)
INSERT INTO made_district SELECT replace(ins.geo_id, 'ocd-division/country:us/state:nh/council:', '')::int, ins.id FROM ins;

CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT 'Executive Councilor, District ' || s.d, mc.chamber_id, md.district_id, 'NH', 'full',
         false, false, false, 'seat:' || s.d
    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc
  RETURNING id, description)
INSERT INTO made_office SELECT replace(ins.description, 'seat:', '')::int, ins.id FROM ins;
UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM made_district; IF n <> 5 THEN RAISE EXCEPTION 'only % districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_office;   IF n <> 5 THEN RAISE EXCEPTION 'only % offices were created', n; END IF;
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;
  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;
  IF n <> 5 THEN RAISE EXCEPTION 'only % of the 5 districts meet a geofence row on (geo_id, mtfcc)', n; END IF;

  -- 🔴🔴 EVERY NUMBER ON A ROW MUST BE THE SAME NUMBER. A control that swapped which polygon
  --    districts 1 and 3 point at reported DRY RUN OK and the chain gate never fired: the
  --    district->office join keys on a number DERIVED FROM the geo_id, so the swap cancelled
  --    itself and left only a district whose LABEL disagreed with its geo_id. Nothing checked
  --    that, and a voter would have been shown "District 1" for the District 3 map. These two
  --    gates exist because that control passed.
  SELECT string_agg(d.label || ' carries geo_id ' || d.geo_id || ' and district_id ' || d.district_id, '; ') INTO txt
    FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
   WHERE d.label <> 'New Hampshire Executive Council District ' || replace(d.geo_id, 'ocd-division/country:us/state:nh/council:', '')
      OR d.district_id <> replace(d.geo_id, 'ocd-division/country:us/state:nh/council:', '');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a district''s label or district_id disagrees with its geo_id: %', txt; END IF;

  SELECT string_agg(o.title || ' sits on ' || d.geo_id, '; ') INTO txt
    FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.title <> 'Executive Councilor, District ' || replace(d.geo_id, 'ocd-division/country:us/state:nh/council:', '');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an office sits on a district with a different number: %', txt; END IF;
END $$;

-- ─── The people ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('Joseph D. Kenney', 'Joseph', 'Kenney',
   'https://www.council.nh.gov/district-1 — the body''s own roster, whose page is headed "Councilor Joseph D. Kenney", read 2026-11-08. Took office 2025-01-09: New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE" — "Governor Ayotte administered the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet Stevens, John Stephen and David Wheeler", https://gc.nh.gov/house/calendars_journals/Journals/2025/HJ%2003%20January%209,%202025.PDF (CC_0376)'),
  ('Karen Liot Hill', 'Karen', 'Liot Hill',
   'https://www.council.nh.gov/district-2 — the body''s own roster, whose page is headed "Councilor Karen Liot Hill", read 2026-11-08. Took office 2025-01-09: New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE" — "Governor Ayotte administered the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet Stevens, John Stephen and David Wheeler", https://gc.nh.gov/house/calendars_journals/Journals/2025/HJ%2003%20January%209,%202025.PDF (CC_0376)'),
  ('Janet Stevens', 'Janet', 'Stevens',
   'https://www.council.nh.gov/district-3 — the body''s own roster, whose page is headed "Councilor Janet Stevens", read 2026-11-08. Took office 2025-01-09: New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE" — "Governor Ayotte administered the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet Stevens, John Stephen and David Wheeler", https://gc.nh.gov/house/calendars_journals/Journals/2025/HJ%2003%20January%209,%202025.PDF (CC_0376)'),
  ('John Stephen', 'John', 'Stephen',
   'https://www.council.nh.gov/district-4 — the body''s own roster, whose page is headed "Councilor John Stephen", read 2026-11-08. Took office 2025-01-09: New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE" — "Governor Ayotte administered the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet Stevens, John Stephen and David Wheeler", https://gc.nh.gov/house/calendars_journals/Journals/2025/HJ%2003%20January%209,%202025.PDF (CC_0376)'),
  ('David K. Wheeler', 'David', 'Wheeler',
   'https://www.council.nh.gov/district-5 — the body''s own roster, whose page is headed "Councilor David K. Wheeler", read 2026-11-08. Took office 2025-01-09: New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE" — "Governor Ayotte administered the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet Stevens, John Stephen and David Wheeler", https://gc.nh.gov/house/calendars_journals/Journals/2025/HJ%2003%20January%209,%202025.PDF (CC_0376)'),
  ('Luz Bay', 'Luz', 'Bay',
   'New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District 1" return workbook (https://www.sos.nh.gov/2026-general-election-results), read 2026-11-08: Luz Bay (d) 64,227 votes, won (CC_0376)'),
  ('Tobin Menard', 'Tobin', 'Menard',
   'New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District 2" return workbook (https://www.sos.nh.gov/2026-general-election-results), read 2026-11-08: Tobin Menard (r) 44,197 votes, lost (CC_0376)'),
  ('Lisa Kennedy Sheldon', 'Lisa', 'Kennedy Sheldon',
   'New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District 3" return workbook (https://www.sos.nh.gov/2026-general-election-results), read 2026-11-08: Lisa Kennedy Sheldon (d) 70,251 votes, won (CC_0376)'),
  ('Jim O''Connell', 'Jim', 'O''Connell',
   'New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District 4" return workbook (https://www.sos.nh.gov/2026-general-election-results), read 2026-11-08: Jim O''Connell (d) 60,540 votes, won (CC_0376)'),
  ('Melanie Levesque', 'Melanie', 'Levesque',
   'New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District 5" return workbook (https://www.sos.nh.gov/2026-general-election-results), read 2026-11-08: Melanie Levesque (d) 64,712 votes, won (CC_0376)');

-- Names carrying a middle initial, so the split gate can allow exactly these and nothing else.
CREATE TEMP TABLE middle_initial (full_name text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO middle_initial VALUES ('Joseph D. Kenney'), ('David K. Wheeler');

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT lower(translate(coalesce(t, ''), 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
                                          'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc'))
$f$;

CREATE TEMP TABLE pol_keys ON COMMIT DROP AS
SELECT id, full_name, first_name, last_name, is_active, source,
       pg_temp.namekey(full_name) AS k_full, pg_temp.namekey(first_name) AS k_first, pg_temp.namekey(last_name) AS k_last
  FROM essentials.politicians;
CREATE INDEX ON pol_keys (k_full);
CREATE INDEX ON pol_keys (k_first, k_last);
ANALYZE pol_keys;

DO $$ DECLARE txt text; n int; BEGIN
  -- 🔴 A POSITIVE CONTROL ON BOTH ARMS, so a sweep that finds nothing is a clean sweep and not a
  --   blind one. Both probes name people this repo is known to hold.
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Kelly Ayotte');
  IF n < 1 THEN RAISE EXCEPTION 'the full-name index cannot see a politician known to exist'; END IF;
  SELECT count(*) INTO n FROM pol_keys WHERE k_first = pg_temp.namekey('Paul') AND k_last = pg_temp.namekey('Kenney');
  IF n < 1 THEN RAISE EXCEPTION 'the (first, last) index cannot see a politician known to exist'; END IF;
  SELECT count(*) INTO n FROM pol_keys; IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows', n; END IF;

  -- 🔴🔴 A NAMESAKE REACHES PRODUCTION AND NOTHING ERRORS. Both arms, because the duplicate-name
  --   guard keys on (first, last) and a differently-split identical full_name is invisible to it.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ')' AS msg
      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)
     WHERE p.source IS DISTINCT FROM s.source
    UNION
    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'
      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name)
     WHERE p.source IS DISTINCT FROM s.source) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;

  -- the split must reproduce the name, allowing exactly the declared middle initials
  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s
   WHERE s.full_name <> s.first_name || ' ' || s.last_name
     AND NOT (s.full_name IN (SELECT full_name FROM middle_initial)
              AND s.full_name ~ ('^' || s.first_name || ' [A-Z]\. ' || replace(s.last_name, '''', '''''') || '$'));
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;

  SELECT string_agg(s.full_name, '; ') INTO txt FROM seed_people s
   WHERE s.source NOT LIKE 'https://www.council.nh.gov/%' AND s.source NOT LIKE 'New Hampshire Secretary of State%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is neither the council''s own roster nor the Secretary of State: %', txt; END IF;
END $$;

SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, s.source, true,
       EXISTS (SELECT 1 FROM seat st WHERE st.who = s.full_name)
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source);
SET LOCAL essentials.allow_duplicate_name = 'off';

CREATE TEMP TABLE person (who text PRIMARY KEY, pid uuid NOT NULL) ON COMMIT DROP;
INSERT INTO person SELECT s.full_name, p.id FROM seed_people s
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;
DO $$ DECLARE n int; BEGIN SELECT count(*) INTO n FROM person;
  IF n <> 10 THEN RAISE EXCEPTION 'only % of the 10 people resolved to exactly one row', n; END IF;
  -- 🔴 is_incumbent is a cached flag the incumbents-only reads filter on, and it defaults to
  --   false. The five sitting councilors must carry true and the five challengers false.
  SELECT count(*) INTO n FROM person pe JOIN essentials.politicians p ON p.id = pe.pid
   WHERE p.is_incumbent <> EXISTS (SELECT 1 FROM seat s WHERE s.who = pe.who);
  IF n <> 0 THEN RAISE EXCEPTION '% seeded person(s) carry the wrong is_incumbent', n; END IF;
END $$;

-- ─── Seat the five sitting councilors ───
-- 🔴 THE DATE IS THE DAY OF THE OATH, FROM THE HOUSE JOURNAL, not the day of the election and
--    not the constitutional counting day. All five were sworn together on 2025-01-09.
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, DATE '2025-01-09', NULL, 'day', 'elected',
       'New Hampshire House Journal No. 3, 9 January 2025, "OATHS OF OFFICE": "Governor Ayotte administered the oath of office to the Honorable Executive Councilors, Joseph Kenney, Karen Liot Hill, Janet Stevens, John Stephen and David Wheeler." https://gc.nh.gov/house/calendars_journals/Journals/2025/HJ%2003%20January%209,%202025.PDF. District assignments from the same Journal (the councilors-elect are seated by district) and from council.nh.gov''s own district pages, both read 2026-11-08 (CC_0376)'
  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;

-- ─── The 5 races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT 'c6fcba79-6b3d-4617-b227-5a745c27f849'::uuid, mo.office_id, 'New Hampshire Executive Council District ' || s.d, NULL, 1,
       CASE s.d
         WHEN 1 THEN 'The seat held by Joseph D. Kenney. Luz Bay (Democratic) 64,227, Joseph D. Kenney (Republican) 60,500; 86 write-ins; 124,813 ballots counted across 91 towns and cities. Returns reported by town clerks to the Secretary of State and subject to amendment; not a certified canvass.'
         WHEN 2 THEN 'The seat held by Karen Liot Hill. Karen Liot Hill (Democratic) 81,364, Tobin Menard (Republican) 44,197; 104 write-ins; 125,665 ballots counted across 81 towns and cities. Returns reported by town clerks to the Secretary of State and subject to amendment; not a certified canvass.'
         WHEN 3 THEN 'The seat held by Janet Stevens. Lisa Kennedy Sheldon (Democratic) 70,251, Janet Stevens (Republican) 64,617; 68 write-ins; 134,936 ballots counted across 32 towns and cities. Returns reported by town clerks to the Secretary of State and subject to amendment; not a certified canvass.'
         WHEN 4 THEN 'The seat held by John Stephen. Jim O''Connell (Democratic) 60,540, John Stephen (Republican) 52,547; 64 write-ins; 113,151 ballots counted across 20 towns and cities. Returns reported by town clerks to the Secretary of State and subject to amendment; not a certified canvass.'
         WHEN 5 THEN 'The seat held by David K. Wheeler. Melanie Levesque (Democratic) 64,712, Dave Wheeler (Republican) 55,615; 75 write-ins; 120,402 ballots counted across 35 towns and cities. Returns reported by town clerks to the Secretary of State and subject to amendment; not a certified canvass. The return sheet gives the incumbent''s ballot name as "Dave Wheeler"; council.nh.gov heads his page "David K. Wheeler".'
         ELSE NULL END
  FROM seat s JOIN made_office mo ON mo.d = s.d WHERE s.race_recorded;

CREATE TEMP TABLE calls (
  d int NOT NULL, who text NOT NULL, result text NOT NULL, votes int NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (d, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  (1, 'Luz Bay', 'won', 64227, false),
  (1, 'Joseph D. Kenney', 'lost', 60500, true),
  (2, 'Karen Liot Hill', 'won', 81364, true),
  (2, 'Tobin Menard', 'lost', 44197, false),
  (3, 'Lisa Kennedy Sheldon', 'won', 70251, false),
  (3, 'Janet Stevens', 'lost', 64617, true),
  (4, 'Jim O''Connell', 'won', 60540, false),
  (4, 'John Stephen', 'lost', 52547, true),
  (5, 'Melanie Levesque', 'won', 64712, false),
  (5, 'David K. Wheeler', 'lost', 55615, true);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls; IF n <> 10 THEN RAISE EXCEPTION 'expected 10 candidacies, found %', n; END IF;
  SELECT string_agg('D' || z.d || ': ' || z.w || ' winner(s)', '; ') INTO txt FROM (
    SELECT c.d, count(*) FILTER (WHERE c.result = 'won') w FROM calls c GROUP BY c.d) z WHERE z.w <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a single-seat race does not hold exactly one winner: %', txt; END IF;
  -- 🔴 A "won" FLAG AND A VOTE COUNT ARE TWO SEPARATE FACTS. This is where they are made to agree,
  --   and it is why no loser is inferred from "not the winner" — each carries its own status.
  SELECT string_agg('D' || z.d, ', ') INTO txt FROM (
    SELECT c.d FROM calls c GROUP BY c.d
    HAVING max(c.votes) FILTER (WHERE c.result = 'won') < max(c.votes)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the winner is not the leading candidate in: %', txt; END IF;
  SELECT string_agg(c.who, '; ') INTO txt FROM calls c LEFT JOIN person pe ON pe.who = c.who WHERE pe.pid IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy resolves to no person: %', txt; END IF;
  SELECT string_agg(c.who || ' in D' || c.d, '; ') INTO txt FROM calls c JOIN seat s ON s.d = c.d
   WHERE c.is_incumbent <> (s.who = c.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an incumbent flag disagrees with the seat''s holder: %', txt; END IF;
  -- every seat's sitting holder stood again, so each race carries exactly one incumbent
  SELECT string_agg('D' || z.d || '=' || z.k, ', ') INTO txt FROM (
    SELECT c.d, count(*) FILTER (WHERE c.is_incumbent) k FROM calls c GROUP BY c.d) z WHERE z.k <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race does not carry exactly one incumbent: %', txt; END IF;
END $$;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, c.is_incumbent, 'active', false,
       'New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District N" return workbooks (https://www.sos.nh.gov/2026-general-election-results), read 2026-11-08 (CC_0376)',
       c.result, 'called',
       'New Hampshire Secretary of State, 2026 General Election Results, "Executive Council District N" return workbooks (https://www.sos.nh.gov/2026-general-election-results), read 2026-11-08. Returns as reported by town clerks, subject to amendment; not a certified canvass (CC_0376)', now()
  FROM calls c JOIN made_office mo ON mo.d = c.d
  JOIN essentials.races r ON r.office_id = mo.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN person pe ON pe.who = c.who JOIN essentials.politicians pl ON pl.id = pe.pid;

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.d = s.d
    JOIN essentials.races r ON r.office_id = mo.office_id WHERE s.race_recorded;
  IF n <> 5 THEN RAISE EXCEPTION 'expected 5 new races, found %', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN made_office mo ON mo.d = c.d
    JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN person pe ON pe.who = c.who
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called';
  IF n <> 10 THEN RAISE EXCEPTION 'only % of the 10 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED. Creating an office is an
  --    occupancy act: an unseated one RAISES the baseline, and the baseline must never be raised.
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 5 offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  SELECT count(*) INTO n FROM made_chamber mc JOIN essentials.offices o ON o.chamber_id = mc.chamber_id;
  IF n <> 5 THEN RAISE EXCEPTION 'the chamber holds % offices, not 5', n; END IF;
  SELECT official_count INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id;
  IF n <> 5 THEN RAISE EXCEPTION 'official_count is %, not 5', n; END IF;
  -- 🔴 the chamber must record that art. 60's January date is the COUNT, not the oath, or a
  --   December pass will read 2027-01-06 as a handover date and seat five people a day early.
  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id
   WHERE ch.inauguration_rules ILIKE '%not of the oath%' AND ch.inauguration_rules ILIKE '%2027-01-06%';
  IF n <> 1 THEN RAISE EXCEPTION 'the chamber does not warn that the constitutional January date is the count, not the oath'; END IF;
  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id WHERE ch.staggered_term;
  IF n <> 0 THEN RAISE EXCEPTION 'the council is recorded as staggered; all five seats are elected together'; END IF;

  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE t.term_start <> DATE '2025-01-09' OR t.term_end IS NOT NULL OR t.start_precision <> 'day';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) do not carry the 2025-01-09 oath date', n; END IF;

  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED COUNCILOR, FOR ALL 259 TOWNS.
  --    This is the gate the superseded 2012 map fails and every structural gate passes.
  SELECT string_agg(a.town || ' -> ' || coalesce(x.who, 'nobody'), '; ') INTO txt
    FROM anchor a
    JOIN seat s ON s.d = a.d
    LEFT JOIN LATERAL (
      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who
        FROM essentials.geofence_boundaries gb
        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc AND dd.district_type = 'STATE_BOARD'
        JOIN essentials.offices o ON o.district_id = dd.id
        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
        JOIN essentials.politicians pl ON pl.id = och.politician_id
       WHERE gb.mtfcc = 'X-ST-BOARD' AND gb.state = '33' AND gb.geo_id LIKE 'ocd-division/country:us/state:nh/council:%'
         AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(a.lon, a.lat), 4326))) x ON true
   WHERE x.who IS DISTINCT FROM s.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a town does not reach the councilor RSA 662:2 gives it: %', left(txt, 900); END IF;
  SELECT count(*) INTO n FROM anchor; IF n <> 259 THEN RAISE EXCEPTION 'the chain gate examined % towns', n; END IF;

  RAISE NOTICE 'CC_0376 OK — 5 New Hampshire Executive Council seats created and seated, 5 races, 10 candidacies, 10 people, 259 towns reach their councilor.';
END $$;

COMMIT;
