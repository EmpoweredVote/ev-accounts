-- CA_0154_la_trustee_area_boards_batch4b2_compton.sql
-- LA-County TRUSTEE-AREA unified school boards, batch 4b-2 of the roster refresh: Compton Unified.
-- Same pattern as CA_0153 (and the parallel session's CA_0144/0146): one X0002 polygon + SCHOOL
-- sub-district per trustee area, dissolved from the LA County RR/CC precinct layer
-- (Political_Boundaries/MapServer/34, DST_USD 11 / DIV_USD 1-7, read 2026-09-22); the generic 'Board
-- Member' offices move off the whole-district row; stale holders closed (how_ended 'unknown', end date
-- not researched -- operator decision 2026-09-22); current members seated from the district's own
-- board page and 2024 / 2026 media releases. NO RACES (all 2026 Compton contests were decided June 2).
--
-- 🔴 AREA-LETTER DECODE (A..G -> DIV 1..7) IS AN INFERENCE, NOT A POINT ANCHOR:
--   * The RR/CC stores Compton's areas only by NUMBER: its precinct layer (DIV_USD 1-7), its "School
--     Districts Trustee Areas" layer (LABEL 'COMPTON UNIFIED SCHOOL TA1'..'TA7') and the 2022 map
--     Compton links as its own "Trustee Area Map" (ComptonUSD_03072022.pdf, TA1..TA7). Ballots and the
--     district name the areas A..G.
--   * In the two lettered LA districts where a lettered map WAS available, the RR/CC's order is A=1:
--     Glendale (district's adopted 2021 map, >= 94 % overlap per area; CA_0153) and Torrance (anchor
--     points vs tusd.org's map, verified by the parallel session).
--   * Consistent with Satra Zurita's district bio (Area G reaches "from Compton to North Carson,
--     including ... East Rancho Dominguez ... West Rancho Dominguez") -> the southern TA7.
--   No lettered Compton map could be retrieved (the 2019 CVRA draft maps and judgment now 404).
--   OPERATOR DECISION (Chris Andrews, 2026-09-22): offered "apply with A=1..G=7" / "roster only" / "hold";
--   chose APPLY WITH A=1..G=7. If a lettered Compton map later disagrees, re-point the five-letter labels
--   (geo_id suffix, district label, office title) -- the polygons themselves are the RR/CC's and stay.
--
-- BATCH-SPECIFIC:
--   * Two stale holders are VERIFIED current members and are KEPT (row + open 1459 term untouched,
--     CA_0145 §C): Michael Hooper (Area D) and Alma Taylor-Pleasant (Area E); offices pinned.
--   * Compton votes with the statewide PRIMARY and seats winners soon after: the March 2024 cohort by the
--     2024-04-16 meeting, the June 2026 cohort on 2026-07-21 (district media releases). Terms end in the
--     month of the next primary ("Term Expires: 3/2028", "6/2026" on the board page).
--   * The DB had 5 seats for a 7-member board: two seats are added (clones), per the operator decision.
--   * Micah Ali and Satra Zurita reuse confirmed LA County NetFile rows.
--
-- NOT DONE HERE: stale holders keep party 'Nonpartisan' and is_active true.
--
-- IDEMPOTENT: every insert NOT EXISTS-guarded; office moves guarded on the whole-district row;
-- stale-term closing only touches open terms not held by the named member.
BEGIN;

CREATE TEMP TABLE _seat (parent_geo text, geo_id text, label text, ta text, ord int, full_name text, first_name text,
                         last_name text, url text, existing_pid uuid, term_start date, prec text, how text, src text,
                         pin_office uuid, vacant_since date, aw text, pid uuid) ON COMMIT DROP;
INSERT INTO _seat (parent_geo, geo_id, label, ta, ord, full_name, first_name, last_name, url, existing_pid, term_start, prec, how, src, pin_office, vacant_since, aw) VALUES
    ('0609620', '0609620-ta-a', 'Compton Unified School Board - Trustee Area A', 'A', 1, 'Denzell Perry', 'Denzell', 'Perry', 'https://www.compton.k12.ca.us/board/board-members', NULL::uuid, '2026-07-21', 'day', 'elected', 'CA_0154: compton.k12.ca.us Board Members ("Trustee Area: A", fetched 2026-09-22); re-elected Area A June 2 2026 (RR/CC list 4338: sole candidate, appointed in lieu of election, Elec. Code 10515); sworn in 2026-07-21 per CUSD media release 2026-07-29 ("... newly elected Trustee Tana McCoy was sworn in to represent Area B following her victory in the June 2 election. Trustees Alma Taylor-Pleasant (Area E), Satra Zurita (Area G), and Denzell Perry (Area A), who were reelected to their positions on June 2, were sworn in to new four-year terms" at the July 21 2026 Board meeting)', NULL::uuid, NULL, 'Trustee Area'),
    ('0609620', '0609620-ta-b', 'Compton Unified School Board - Trustee Area B', 'B', 2, 'Tana McCoy', 'Tana', 'McCoy', 'https://www.compton.k12.ca.us/board/board-members', NULL::uuid, '2026-07-21', 'day', 'elected', 'CA_0154: CUSD media release 2026-07-29 (Member: Tana McCoy, Trustee Area B Representative, fetched 2026-09-22); won Area B June 2 2026 (RR/CC 4338: 2,047 v 1,624); sworn in 2026-07-21 per CUSD media release 2026-07-29 ("... newly elected Trustee Tana McCoy was sworn in to represent Area B following her victory in the June 2 election. Trustees Alma Taylor-Pleasant (Area E), Satra Zurita (Area G), and Denzell Perry (Area A), who were reelected to their positions on June 2, were sworn in to new four-year terms" at the July 21 2026 Board meeting)', NULL::uuid, NULL, 'Trustee Area'),
    ('0609620', '0609620-ta-c', 'Compton Unified School Board - Trustee Area C', 'C', 3, 'Micah Ali', 'Micah', 'Ali', 'https://www.compton.k12.ca.us/board/board-members', '63d803ec-65e8-44fb-8532-7624c4044cda'::uuid, '2024-04-16', 'day', 'elected', 'CA_0154: compton.k12.ca.us Board Members / CUSD media release 2026-07-29 (President, Trustee Area C Representative, fetched 2026-09-22); re-elected Area C March 5 2024 (RR/CC 4316: 1,200 votes, 68.69%); sworn in by 2024-04-16 per CUSD media release 2024-04-18 ("Ali and Moss were officially sworn in to their Board positions prior to the Board meeting" of Tuesday 2024-04-16, after their March 5 2024 re-election)', NULL::uuid, NULL, 'Trustee Area'),
    ('0609620', '0609620-ta-d', 'Compton Unified School Board - Trustee Area D', 'D', 4, 'Michael Hooper', 'Michael', 'Hooper', 'https://www.compton.k12.ca.us/board/board-members', '24076e95-943f-4f94-afe3-05552575659c'::uuid, NULL, 'month', 'elected', 'CA_0154: kept -- compton.k12.ca.us lists "Michael Hooper - Vice President / Term Expires: 3/2028 / Trustees Area: D"; won Area D March 5 2024 (RR/CC 4316: 740 v 722); sworn in 2024-04-13 (CUSD media release 2024-04-15)', '4064d6c3-6c6d-424b-81ff-6427c719968f'::uuid, NULL, 'Trustee Area'),
    ('0609620', '0609620-ta-e', 'Compton Unified School Board - Trustee Area E', 'E', 5, 'Alma Taylor-Pleasant', 'Alma', 'Taylor-Pleasant', 'https://www.compton.k12.ca.us/board/board-members', '123e8e2b-4c4c-471f-80a4-216a1a73c50c'::uuid, NULL, 'month', 'elected', 'CA_0154: kept -- CUSD media release 2026-07-29 (Member: Alma Taylor-Pleasant, Trustee Area E Representative); re-elected Area E June 2 2026 (RR/CC 4338: 1,295 votes, 66.93%) and re-sworn 2026-07-21', 'c2a7a21c-64f9-4b7d-afc8-05dc65407a02'::uuid, NULL, 'Trustee Area'),
    ('0609620', '0609620-ta-f', 'Compton Unified School Board - Trustee Area F', 'F', 6, 'Sandra Moss', 'Sandra', 'Moss', 'https://www.compton.k12.ca.us/board/board-members', NULL::uuid, '2024-04-16', 'day', 'elected', 'CA_0154: CUSD media release 2026-07-29 (Member: Sandra Moss, Trustee Area F Representative, fetched 2026-09-22); re-elected Area F March 5 2024 (RR/CC list 4316: sole candidate, appointed in lieu of election, Elec. Code 10515); sworn in by 2024-04-16 per CUSD media release 2024-04-18 ("Ali and Moss were officially sworn in to their Board positions prior to the Board meeting" of Tuesday 2024-04-16, after their March 5 2024 re-election)', NULL::uuid, NULL, 'Trustee Area'),
    ('0609620', '0609620-ta-g', 'Compton Unified School Board - Trustee Area G', 'G', 7, 'Satra Zurita', 'Satra', 'Zurita', 'https://www.compton.k12.ca.us/board/board-members', '1aed9fdb-9c5c-4751-b48a-359bcdde5653'::uuid, '2026-07-21', 'day', 'elected', 'CA_0154: compton.k12.ca.us Board Members ("Trustees Area: G", fetched 2026-09-22); re-elected Area G June 2 2026 (RR/CC list 4338: sole candidate, appointed in lieu of election, Elec. Code 10515); sworn in 2026-07-21 per CUSD media release 2026-07-29 ("... newly elected Trustee Tana McCoy was sworn in to represent Area B following her victory in the June 2 election. Trustees Alma Taylor-Pleasant (Area E), Satra Zurita (Area G), and Denzell Perry (Area A), who were reelected to their positions on June 2, were sworn in to new four-year terms" at the July 21 2026 Board meeting)', NULL::uuid, NULL, 'Trustee Area');

-- ─── pre-flight: no whole-district office that may be DELETED as surplus carries a race ──────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.offices o JOIN essentials.districts pd ON pd.id = o.district_id
   WHERE pd.district_type = 'SCHOOL' AND pd.mtfcc = 'G5420' AND pd.geo_id IN (SELECT DISTINCT parent_geo FROM _seat)
     AND EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: % whole-district office(s) carry a race; stop and bind those races first', n; END IF;
END $$;

-- ─── 1. Trustee-area polygons (dissolved from the RR/CC precinct layer, DIV_USD) ─────────
INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
SELECT v.geo_id, NULL, v.name, '06', 'X0002',
       public.ST_Multi(public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON(v.gj), 4326))),
       'lacounty_rrcc_precincts_2026', now()
  FROM (VALUES
  ('0609620-ta-a', 'Compton Unified School Board - Trustee Area A', '{"type":"Polygon","coordinates":[[[-118.246423,33.916245],[-118.248936,33.916291],[-118.251253,33.916324],[-118.254179,33.916374],[-118.254874,33.916377],[-118.25506,33.916373],[-118.255497,33.916375],[-118.25579,33.91637],[-118.256557,33.916375],[-118.256531,33.916806],[-118.256518,33.920939],[-118.256527,33.923102],[-118.25361,33.923101],[-118.253604,33.923343],[-118.253597,33.924244],[-118.253568,33.924262],[-118.253524,33.924276],[-118.253513,33.924293],[-118.253513,33.92437],[-118.253519,33.924382],[-118.253527,33.924389],[-118.253539,33.924393],[-118.253595,33.924393],[-118.253563,33.927305],[-118.253761,33.927305],[-118.253761,33.92732],[-118.253794,33.92732],[-118.253791,33.927481],[-118.253825,33.927478],[-118.253818,33.928094],[-118.253816,33.928189],[-118.253782,33.928358],[-118.253542,33.928547],[-118.254228,33.929399],[-118.239157,33.929459],[-118.23896,33.929392],[-118.235145,33.929163],[-118.234012,33.9291],[-118.23025179710145,33.928932099637684],[-118.230268,33.929004],[-118.228957,33.928982],[-118.226665,33.929133],[-118.225605,33.92929],[-118.2256,33.92927],[-118.225564,33.929275],[-118.225529,33.929077],[-118.225509,33.928924],[-118.225034,33.925894],[-118.224774,33.924196],[-118.224688,33.92373],[-118.224698,33.923698],[-118.224617,33.923152],[-118.224636,33.923148],[-118.224504,33.922306],[-118.224064,33.922304],[-118.219952,33.922306],[-118.21995,33.923032],[-118.219294,33.922389],[-118.219118,33.922222],[-118.218651,33.921766],[-118.218577,33.921495],[-118.218368,33.921361],[-118.217657,33.916809],[-118.217882,33.916787],[-118.221147,33.916428],[-118.221398,33.916411],[-118.221939,33.916346],[-118.2226,33.916261],[-118.222943,33.916222],[-118.223017,33.916226],[-118.223547,33.916213],[-118.225095,33.916204],[-118.22698,33.916216],[-118.226686,33.915262],[-118.226365,33.914029],[-118.226248,33.91351],[-118.226377,33.913524],[-118.227093,33.913274],[-118.227072,33.913281],[-118.226415,33.911996],[-118.226132,33.911411],[-118.228924,33.910843],[-118.229439,33.910723],[-118.230019,33.910599],[-118.230014,33.910589],[-118.230334,33.910518],[-118.230785,33.910425],[-118.231373,33.910297],[-118.231617,33.91025],[-118.231942,33.910196],[-118.232749,33.909995],[-118.233634,33.909756],[-118.233888,33.911046],[-118.233995,33.911706],[-118.233988,33.911713],[-118.233997,33.911714],[-118.234213,33.913028],[-118.234351,33.913767],[-118.234296,33.913771],[-118.234339,33.913768],[-118.234351,33.914403],[-118.234658,33.914414],[-118.235861,33.914415],[-118.237925,33.91441],[-118.23908,33.914413],[-118.239082,33.914061],[-118.241145,33.914056],[-118.246217,33.914057],[-118.246224,33.916241],[-118.246423,33.916245]]]}'),
  ('0609620-ta-b', 'Compton Unified School Board - Trustee Area B', '{"type":"Polygon","coordinates":[[[-118.260921,33.886181],[-118.265355,33.88603],[-118.265588,33.886761],[-118.265773,33.888028],[-118.265805,33.888091],[-118.26582,33.88813],[-118.265876,33.888305],[-118.266185,33.8896],[-118.266994,33.893178],[-118.267448,33.895133],[-118.268119,33.898162],[-118.268776,33.901062],[-118.268663,33.90109],[-118.265885,33.901887],[-118.265874,33.901891],[-118.265873,33.901894],[-118.265873,33.902039],[-118.265257,33.902134],[-118.265268,33.902317],[-118.26527,33.902316],[-118.265287,33.903634],[-118.26529,33.905527],[-118.265284,33.907739],[-118.265295,33.908209],[-118.265273,33.909174],[-118.269665,33.909155],[-118.270156,33.909161],[-118.273973,33.909184],[-118.273956,33.912789],[-118.273967,33.913496],[-118.273946,33.914764],[-118.273938,33.916424],[-118.273851,33.916414],[-118.273346,33.916416],[-118.272794,33.916429],[-118.271767,33.916429],[-118.270196,33.916421],[-118.269541,33.916421],[-118.26938,33.916427],[-118.268357,33.916427],[-118.267429,33.916419],[-118.266263,33.916424],[-118.265808,33.916429],[-118.26526,33.916417],[-118.265086,33.916419],[-118.264958,33.91641],[-118.264506,33.916401],[-118.264183,33.916401],[-118.263644,33.916365],[-118.263345,33.916354],[-118.262512,33.916345],[-118.261439,33.91636],[-118.258538,33.916372],[-118.256537,33.916375],[-118.255704,33.91637],[-118.255497,33.916375],[-118.255091,33.916373],[-118.254874,33.916377],[-118.254356,33.916375],[-118.254374,33.914466],[-118.254389,33.913284],[-118.254391,33.912828],[-118.254461,33.912828],[-118.254472,33.912192],[-118.254483,33.910175],[-118.254497,33.90926],[-118.254515,33.908686],[-118.254507,33.908643],[-118.254527,33.906724],[-118.254527,33.906155],[-118.254396,33.906155],[-118.254395,33.905937],[-118.254387,33.905799],[-118.25436,33.905567],[-118.254333,33.90541],[-118.254278,33.905178],[-118.254235,33.905032],[-118.254179,33.90487],[-118.253991,33.904363],[-118.254135,33.904359],[-118.253609,33.90294],[-118.247048,33.903233],[-118.24685,33.903246],[-118.246849,33.903123],[-118.246704,33.90313],[-118.245248,33.903268],[-118.24505,33.903281],[-118.244705,33.903295],[-118.244118,33.903294],[-118.242424,33.903306],[-118.242361,33.903159],[-118.242288,33.901934],[-118.242164,33.900045],[-118.242238,33.899883],[-118.242089,33.897881],[-118.242003,33.896577],[-118.24195,33.895886],[-118.240063,33.895897],[-118.239748,33.895892],[-118.237585,33.895899],[-118.237387,33.892878],[-118.237254,33.89094],[-118.237111,33.888532],[-118.239311,33.888518],[-118.241923,33.888494],[-118.244083,33.888497],[-118.245765,33.888488],[-118.247717,33.888483],[-118.249259,33.888467],[-118.249557,33.888468],[-118.249638,33.888464],[-118.249735,33.888451],[-118.249864,33.888425],[-118.250101,33.888364],[-118.250272,33.888315],[-118.250565,33.888225],[-118.253168,33.887102],[-118.254075,33.886714],[-118.254342,33.886609],[-118.254621,33.886523],[-118.254762,33.886487],[-118.255396,33.88638],[-118.255543,33.886361],[-118.256117,33.886323],[-118.256397,33.886316],[-118.25749,33.886277],[-118.25747,33.886192],[-118.259442,33.88613],[-118.259461,33.88613],[-118.259474,33.886203],[-118.260275,33.886188],[-118.260894,33.886169],[-118.260897,33.886182],[-118.260921,33.886181]]]}'),
  ('0609620-ta-c', 'Compton Unified School Board - Trustee Area C', '{"type":"Polygon","coordinates":[[[-118.245248,33.903268],[-118.246626,33.903137],[-118.246704,33.90313],[-118.246849,33.903124],[-118.24685,33.903246],[-118.246672,33.903259],[-118.247048,33.903233],[-118.253609,33.90294],[-118.254135,33.904359],[-118.253991,33.904363],[-118.254179,33.90487],[-118.254235,33.905032],[-118.254278,33.905178],[-118.254328,33.905388],[-118.25436,33.905567],[-118.254387,33.905799],[-118.254395,33.905937],[-118.254396,33.906155],[-118.254063,33.906156],[-118.254527,33.906155],[-118.254527,33.906724],[-118.254507,33.908643],[-118.254515,33.908686],[-118.254497,33.90926],[-118.254483,33.910175],[-118.254472,33.912192],[-118.254461,33.912828],[-118.254391,33.912828],[-118.254389,33.913284],[-118.254374,33.914466],[-118.254356,33.916375],[-118.251253,33.916324],[-118.248936,33.916291],[-118.246224,33.916241],[-118.246217,33.914056],[-118.241145,33.914056],[-118.239082,33.914061],[-118.23908,33.914413],[-118.237925,33.91441],[-118.235861,33.914415],[-118.234658,33.914414],[-118.234351,33.914403],[-118.234339,33.913805],[-118.234339,33.913768],[-118.234351,33.913767],[-118.234213,33.913028],[-118.233997,33.911714],[-118.233988,33.911713],[-118.233995,33.911706],[-118.233888,33.911046],[-118.23363342930857,33.909756163054695],[-118.232749,33.909995],[-118.231942,33.910196],[-118.231617,33.91025],[-118.231373,33.910297],[-118.230785,33.910425],[-118.230334,33.910518],[-118.230014,33.910589],[-118.230019,33.910599],[-118.229439,33.910723],[-118.228924,33.910843],[-118.226114,33.911414],[-118.226132,33.911411],[-118.226415,33.911996],[-118.227072,33.913281],[-118.226377,33.913524],[-118.226248,33.91351],[-118.226365,33.914029],[-118.226686,33.915262],[-118.22698,33.916216],[-118.225095,33.916204],[-118.223547,33.916213],[-118.223017,33.916226],[-118.222943,33.916222],[-118.2226,33.916261],[-118.221939,33.916346],[-118.221398,33.916411],[-118.221147,33.916428],[-118.217882,33.916787],[-118.217657,33.916809],[-118.217211,33.913948],[-118.217073,33.913098],[-118.216951,33.912321],[-118.216827,33.912334],[-118.21667,33.911429],[-118.216388,33.909632],[-118.216196,33.908433],[-118.216159,33.908256],[-118.216146,33.908174],[-118.216142,33.908133],[-118.216142,33.908079],[-118.216171,33.907915],[-118.216211,33.907782],[-118.216386,33.907309],[-118.216428,33.907176],[-118.216451,33.907068],[-118.216469,33.906936],[-118.216379,33.905194],[-118.216372,33.905134],[-118.21631,33.903398],[-118.21803,33.903386],[-118.220002,33.903366],[-118.22266,33.903362],[-118.224799,33.903333],[-118.226502,33.903328],[-118.227969,33.903318],[-118.229964,33.903326],[-118.232243,33.903328],[-118.236192,33.903324],[-118.238111,33.903328],[-118.240262,33.90332],[-118.241342,33.903309],[-118.241709,33.903311],[-118.244118,33.903294],[-118.244705,33.903295],[-118.24505,33.903281],[-118.245248,33.903268]]]}'),
  ('0609620-ta-d', 'Compton Unified School Board - Trustee Area D', '{"type":"Polygon","coordinates":[[[-118.234846,33.888546],[-118.237111,33.888532],[-118.237254,33.89094],[-118.237387,33.892878],[-118.237585,33.895899],[-118.239748,33.895892],[-118.240063,33.895897],[-118.24195,33.895886],[-118.242003,33.896577],[-118.242089,33.897881],[-118.242238,33.899883],[-118.242164,33.900045],[-118.242288,33.901934],[-118.242361,33.903159],[-118.242424,33.903306],[-118.241673,33.903311],[-118.241342,33.903309],[-118.240262,33.90332],[-118.238111,33.903328],[-118.236192,33.903324],[-118.232312,33.903328],[-118.229964,33.903326],[-118.227969,33.903318],[-118.226502,33.903328],[-118.224799,33.903333],[-118.22266,33.903362],[-118.220002,33.903366],[-118.21803,33.903386],[-118.21631,33.903398],[-118.214624,33.903426],[-118.212248,33.903434],[-118.212039,33.903438],[-118.209714,33.903458],[-118.20846,33.903465],[-118.208292,33.90081],[-118.208116,33.898347],[-118.207985,33.896043],[-118.209377,33.896039],[-118.211556,33.896046],[-118.212656,33.896029],[-118.213745,33.896032],[-118.215633,33.896026],[-118.217541,33.896025],[-118.219752,33.896017],[-118.219948,33.896004],[-118.218787,33.888593],[-118.219339,33.888591],[-118.219817,33.888609],[-118.220509,33.888613],[-118.221522,33.888608],[-118.223738,33.888606],[-118.226039,33.888588],[-118.228197,33.888584],[-118.229227,33.888566],[-118.229601,33.888556],[-118.232803,33.888558],[-118.234846,33.888546]]]}'),
  ('0609620-ta-e', 'Compton Unified School Board - Trustee Area E', '{"type":"Polygon","coordinates":[[[-118.208262,33.90038],[-118.208317,33.901196],[-118.20846,33.903465],[-118.209714,33.903458],[-118.212039,33.903438],[-118.212248,33.903434],[-118.214624,33.903426],[-118.21631,33.903398],[-118.216372,33.905134],[-118.216379,33.905194],[-118.216469,33.906936],[-118.216451,33.907068],[-118.216428,33.907176],[-118.216386,33.907309],[-118.216211,33.907782],[-118.216171,33.907915],[-118.216142,33.908079],[-118.216142,33.908133],[-118.216159,33.908256],[-118.216196,33.908433],[-118.216388,33.909632],[-118.21667,33.911429],[-118.216827,33.912335],[-118.21576,33.912449],[-118.215659,33.912464],[-118.215187,33.912511],[-118.213976,33.912644],[-118.213979,33.912624],[-118.213934,33.912607],[-118.21409,33.911714],[-118.214117,33.911346],[-118.214196,33.910676],[-118.214214,33.910576],[-118.211479,33.909969],[-118.209567,33.909522],[-118.209446,33.909905],[-118.209543,33.90993],[-118.209374,33.910322],[-118.209661,33.910403],[-118.20948,33.910807],[-118.209623,33.910851],[-118.209777,33.910894],[-118.209588,33.91132],[-118.209915,33.911414],[-118.209935,33.911755],[-118.209134,33.911474],[-118.208601,33.911294],[-118.206444,33.910542],[-118.206451,33.910545],[-118.206449,33.910552],[-118.205829,33.912679],[-118.199342,33.910833],[-118.199356,33.910797],[-118.199205,33.910752],[-118.19919,33.910789],[-118.198398,33.910564],[-118.198803,33.909583],[-118.198098,33.909392],[-118.19675,33.908999],[-118.19604,33.908799],[-118.195033,33.91125],[-118.19464,33.911144],[-118.193836,33.910905],[-118.194485,33.909345],[-118.194569,33.909369],[-118.195844,33.906272],[-118.194878,33.906183],[-118.194654,33.906167],[-118.192728,33.905994],[-118.190269,33.90577],[-118.190195,33.906181],[-118.189608,33.906129],[-118.189395,33.907318],[-118.186861,33.907082],[-118.187185,33.90531],[-118.186641,33.905259],[-118.186605,33.905252],[-118.186562,33.905233],[-118.186527,33.905204],[-118.186506,33.905173],[-118.186498,33.90515],[-118.186488,33.90507],[-118.186475,33.905021],[-118.18644,33.904946],[-118.1864,33.904888],[-118.186367,33.90485],[-118.186309,33.904799],[-118.18625,33.90476],[-118.186175,33.904723],[-118.186129,33.904706],[-118.186026,33.904681],[-118.185437,33.90463],[-118.185354,33.904673],[-118.185322,33.904788],[-118.185246,33.904781],[-118.185199,33.904807],[-118.185124,33.904862],[-118.184391,33.905546],[-118.184177,33.905719],[-118.184067,33.905803],[-118.184014,33.905841],[-118.183781,33.905995],[-118.183589,33.906112],[-118.183384,33.906227],[-118.183267,33.906288],[-118.183098,33.90637],[-118.182865,33.906529],[-118.182706,33.906646],[-118.182253,33.90701],[-118.182094,33.907148],[-118.181801,33.907426],[-118.18166,33.907572],[-118.181359,33.907919],[-118.181149,33.908192],[-118.180976,33.908438],[-118.180844,33.908641],[-118.18058,33.909112],[-118.180493,33.909289],[-118.18035,33.909617],[-118.180311,33.909715],[-118.180394,33.909744],[-118.180118,33.910553],[-118.179869,33.91125],[-118.179742,33.912082],[-118.179508,33.911978],[-118.179527,33.911933],[-118.179019,33.911709],[-118.177265,33.910948],[-118.177299,33.91072],[-118.177303,33.91072],[-118.177398,33.909909],[-118.177595,33.908363],[-118.178181,33.90696],[-118.178375,33.906473],[-118.178905,33.90538],[-118.179327,33.904874],[-118.179612,33.904515],[-118.179744,33.904382],[-118.180477,33.903686],[-118.181444,33.902832],[-118.181987,33.902337],[-118.183014,33.901426],[-118.183278,33.901145],[-118.183553,33.900811],[-118.183817,33.900438],[-118.184052,33.900032],[-118.184078,33.899982],[-118.184206,33.899718],[-118.184331,33.899425],[-118.184419,33.899157],[-118.184658,33.898401],[-118.184734,33.898122],[-118.185018,33.897216],[-118.185298,33.896246],[-118.187075,33.896232],[-118.187202,33.896235],[-118.187964,33.896236],[-118.189961,33.896212],[-118.192283,33.896197],[-118.193474,33.896174],[-118.195599,33.896146],[-118.197415,33.896133],[-118.19836,33.896114],[-118.198361,33.896137],[-118.198853,33.896135],[-118.198835,33.896106],[-118.199581,33.896094],[-118.20164,33.89608],[-118.203255,33.896064],[-118.203667,33.89607],[-118.204586,33.896055],[-118.205567,33.896052],[-118.206575,33.896042],[-118.207985,33.896043],[-118.208116,33.898347],[-118.208262,33.90038]]]}'),
  ('0609620-ta-f', 'Compton Unified School Board - Trustee Area F', '{"type":"Polygon","coordinates":[[[-118.207127,33.874943],[-118.207124,33.874325],[-118.205511,33.874329],[-118.20551,33.873623],[-118.205522,33.872743],[-118.205681,33.87281],[-118.205918,33.872904],[-118.206319,33.873046],[-118.206636,33.873163],[-118.206983,33.8733],[-118.206992,33.873501],[-118.206984,33.873725],[-118.208505,33.873722],[-118.208613,33.873719],[-118.208818,33.873725],[-118.20918,33.873726],[-118.20964,33.873719],[-118.21443,33.873712],[-118.214715,33.873714],[-118.215062,33.873708],[-118.21615,33.873706],[-118.216127,33.873571],[-118.216434,33.873569],[-118.216364,33.873105],[-118.216696,33.873102],[-118.216838,33.874038],[-118.217356,33.877327],[-118.217576,33.87879],[-118.217959,33.881132],[-118.219116,33.888592],[-118.218692,33.888593],[-118.218787,33.888593],[-118.219948,33.896004],[-118.219752,33.896017],[-118.2181,33.896023],[-118.215633,33.896026],[-118.213745,33.896032],[-118.212656,33.896029],[-118.211556,33.896046],[-118.209377,33.896039],[-118.207985,33.896043],[-118.206575,33.896042],[-118.205567,33.896052],[-118.204586,33.896055],[-118.203667,33.89607],[-118.203255,33.896064],[-118.20164,33.89608],[-118.199581,33.896094],[-118.198835,33.896106],[-118.198853,33.896135],[-118.198361,33.896137],[-118.19836,33.896114],[-118.197415,33.896133],[-118.195599,33.896146],[-118.193474,33.896174],[-118.192283,33.896197],[-118.189961,33.896212],[-118.187964,33.896236],[-118.187202,33.896235],[-118.187075,33.896232],[-118.185298,33.896246],[-118.185352,33.896072],[-118.185324,33.896161],[-118.182388,33.896188],[-118.182258,33.894196],[-118.181785,33.8942],[-118.181682,33.892624],[-118.180125,33.892636],[-118.180075,33.892734],[-118.179957,33.892734],[-118.180064,33.892573],[-118.18237,33.88925],[-118.182366,33.88925],[-118.182569,33.888952],[-118.182715,33.888721],[-118.182806,33.88859],[-118.182871,33.888511],[-118.182972,33.888403],[-118.183112,33.888266],[-118.183304,33.888306],[-118.183535,33.888468],[-118.184456,33.888095],[-118.184684,33.8881],[-118.184642,33.887517],[-118.185714,33.88754],[-118.185732,33.886909],[-118.18641,33.88661],[-118.187564,33.886392],[-118.187919,33.886305],[-118.188266,33.886233],[-118.1883,33.886706],[-118.189327,33.885817],[-118.189567,33.885448],[-118.189603,33.885388],[-118.189568,33.885264],[-118.189683,33.885282],[-118.189765,33.885123],[-118.19003,33.88512],[-118.189967,33.884901],[-118.189537,33.884444],[-118.189068,33.883917],[-118.18857,33.883423],[-118.188284,33.883221],[-118.187905,33.883113],[-118.187499,33.88302],[-118.18752393072289,33.882927],[-118.187158,33.882941],[-118.186886,33.882879],[-118.186047,33.882476],[-118.185876,33.882398],[-118.185894,33.881822],[-118.185896,33.881482],[-118.18639,33.881478],[-118.18666,33.881472],[-118.186895,33.881472],[-118.191217,33.881431],[-118.194559,33.88141],[-118.205436,33.881332],[-118.205263,33.880791],[-118.205973,33.88079],[-118.205973,33.880744],[-118.207141,33.880749],[-118.207144,33.88132],[-118.205502,33.881332],[-118.207213,33.88132],[-118.208889,33.881307],[-118.208886,33.881225],[-118.208883,33.880785],[-118.208545,33.880787],[-118.208547,33.880046],[-118.208541,33.874938],[-118.207127,33.874943]]]}'),
  ('0609620-ta-g', 'Compton Unified School Board - Trustee Area G', '{"type":"Polygon","coordinates":[[[-118.262886,33.85822],[-118.263859,33.858212],[-118.266133,33.858213],[-118.266134,33.858448],[-118.26612,33.860252],[-118.266143,33.862472],[-118.266155,33.866996],[-118.266188,33.866996],[-118.266189,33.867073],[-118.266187,33.871897],[-118.265997,33.873001],[-118.26594,33.873004],[-118.265441,33.875858],[-118.265034,33.878366],[-118.26486,33.87957],[-118.264813,33.87993],[-118.263986,33.879955],[-118.264416,33.88181],[-118.264441,33.88181],[-118.264437,33.881854],[-118.264583,33.882442],[-118.264625,33.88274],[-118.264663,33.882957],[-118.264762,33.883473],[-118.265355,33.88603],[-118.260903,33.886182],[-118.260897,33.886182],[-118.260894,33.886169],[-118.260275,33.886188],[-118.259474,33.886203],[-118.259461,33.88613],[-118.259442,33.88613],[-118.257498,33.886191],[-118.25747023255815,33.886192],[-118.25749,33.886277],[-118.256397,33.886316],[-118.256117,33.886323],[-118.255543,33.886361],[-118.255396,33.88638],[-118.254762,33.886487],[-118.254621,33.886523],[-118.254342,33.886609],[-118.254075,33.886714],[-118.253168,33.887102],[-118.250565,33.888225],[-118.250272,33.888315],[-118.250101,33.888364],[-118.249864,33.888425],[-118.249735,33.888451],[-118.249638,33.888464],[-118.249557,33.888468],[-118.249259,33.888467],[-118.247717,33.888483],[-118.245765,33.888488],[-118.244083,33.888497],[-118.241923,33.888494],[-118.239311,33.888518],[-118.232803,33.888558],[-118.229601,33.888556],[-118.229227,33.888566],[-118.228197,33.888584],[-118.226039,33.888588],[-118.223738,33.888606],[-118.221522,33.888608],[-118.220509,33.888613],[-118.219817,33.888609],[-118.219339,33.888591],[-118.219116,33.888592],[-118.217959,33.881132],[-118.217576,33.87879],[-118.217356,33.877327],[-118.216838,33.874038],[-118.216696,33.873102],[-118.216364,33.873105],[-118.216434,33.873569],[-118.216127,33.873571],[-118.21615,33.873706],[-118.215062,33.873708],[-118.214715,33.873714],[-118.21443,33.873712],[-118.20964,33.873719],[-118.20918,33.873726],[-118.208818,33.873725],[-118.208617,33.873719],[-118.208505,33.873722],[-118.206984,33.873725],[-118.206992,33.873501],[-118.206983,33.8733],[-118.206972,33.873187],[-118.206941,33.872986],[-118.20689,33.872783],[-118.206313,33.870833],[-118.206168,33.870381],[-118.204808,33.86582],[-118.204318,33.864185],[-118.20417,33.863702],[-118.203393,33.861103],[-118.201142,33.860909],[-118.199901,33.860807],[-118.199728,33.860267],[-118.200316,33.860229],[-118.200567,33.859935],[-118.200855,33.859966],[-118.200929,33.860038],[-118.200865,33.860128],[-118.201359,33.860124],[-118.206577,33.859987],[-118.206587,33.860009],[-118.206677,33.859984],[-118.207216,33.85997],[-118.208073,33.859934],[-118.212486,33.859806],[-118.212593,33.859805],[-118.212633,33.859757],[-118.21269,33.859674],[-118.2128,33.85974],[-118.2129,33.859794],[-118.216762,33.859683],[-118.216947,33.858616],[-118.217281,33.858606],[-118.217294,33.858531],[-118.21737,33.858529],[-118.217462,33.858516],[-118.219395,33.858461],[-118.219663,33.858536],[-118.225832,33.85836],[-118.226987,33.858302],[-118.227156,33.858273],[-118.22725,33.858247],[-118.227298,33.858238],[-118.227397,33.858232],[-118.229653,33.858184],[-118.233101,33.858075],[-118.233644,33.858066],[-118.233824,33.858069],[-118.234151,33.8581],[-118.234399,33.858113],[-118.23458,33.858117],[-118.237254,33.858045],[-118.242739,33.857883],[-118.245721,33.857803],[-118.250485,33.85766],[-118.250568,33.85766],[-118.250567,33.857755],[-118.250574,33.858219],[-118.252813,33.858218],[-118.252837,33.858223],[-118.253323,33.858222],[-118.2537,33.858231],[-118.254062,33.858232],[-118.255203,33.858232],[-118.256957,33.858225],[-118.259479,33.858222],[-118.262173,33.858226],[-118.262886,33.85822]]]}')
  ) AS v(geo_id, name, gj)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b WHERE b.geo_id = v.geo_id AND b.mtfcc = 'X0002');

-- ─── 2. One SCHOOL sub-district per trustee area (X0002: the layer the Part A join admits) ─
INSERT INTO essentials.districts (label, district_type, district_id, state, num_officials, mtfcc, geo_id,
                                  is_judicial, has_unknown_boundaries, retention, representation_basis)
SELECT s.label, 'SCHOOL', s.geo_id, 'CA', 1, 'X0002', s.geo_id, false, false, false, 'residency'
  FROM _seat s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = s.geo_id AND d.district_type = 'SCHOOL');

-- ─── 3. Move the generic 'Board Member' offices onto the areas ────────────────────────────
-- They carry only STALE holders, so the office-to-area pairing is arbitrary; take id order
-- (deterministic). Guarded on the office still sitting on the whole-district row.
-- An office already held by a verified CURRENT member is pinned to that member's area.
UPDATE essentials.offices o
   SET district_id = sd.id, title = 'Board Member (' || s.aw || ' ' || s.ta || ')'
  FROM _seat s
  JOIN essentials.districts pd ON pd.geo_id = s.parent_geo AND pd.district_type = 'SCHOOL' AND pd.mtfcc = 'G5420'
  JOIN essentials.districts sd ON sd.geo_id = s.geo_id AND sd.district_type = 'SCHOOL'
 WHERE s.pin_office IS NOT NULL AND o.id = s.pin_office AND o.district_id = pd.id;
UPDATE essentials.offices o
   SET district_id = sd.id, title = 'Board Member (' || s.aw || ' ' || s.ta || ')'
  FROM (SELECT o2.id, pd.geo_id AS parent_geo, row_number() OVER (PARTITION BY pd.geo_id ORDER BY o2.id) AS ord
          FROM essentials.offices o2 JOIN essentials.districts pd ON pd.id = o2.district_id
         WHERE pd.district_type = 'SCHOOL' AND pd.mtfcc = 'G5420' AND pd.geo_id IN ('0609620')) cur
  JOIN (SELECT s2.*, row_number() OVER (PARTITION BY s2.parent_geo ORDER BY s2.ord) AS free_ord
          FROM _seat s2
         WHERE s2.pin_office IS NULL
           AND NOT EXISTS (SELECT 1 FROM essentials.offices ox JOIN essentials.districts dx ON dx.id = ox.district_id
                            WHERE dx.geo_id = s2.geo_id AND dx.district_type = 'SCHOOL')) s
    ON s.parent_geo = cur.parent_geo AND s.free_ord = cur.ord
  JOIN essentials.districts sd ON sd.geo_id = s.geo_id AND sd.district_type = 'SCHOOL'
 WHERE o.id = cur.id;

-- ─── 3b. MISSING seats (the DB had fewer offices than the board has areas): clone one ─────
-- (decision 2026-09-22: add missing seats, cloning chamber/title from an existing office)
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats,
                                normalized_position_name, partisan_type, is_appointed_position, is_vacant, role_canonical)
SELECT tpl.chamber_id, sd.id, 'Board Member (' || s.aw || ' ' || s.ta || ')', tpl.representing_state, tpl.representing_city, 1,
       tpl.normalized_position_name, tpl.partisan_type, false, false, tpl.role_canonical
  FROM _seat s
  JOIN essentials.districts sd ON sd.geo_id = s.geo_id AND sd.district_type = 'SCHOOL'
  CROSS JOIN LATERAL (SELECT o.* FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                        JOIN _seat s2 ON s2.geo_id = d.geo_id AND d.district_type = 'SCHOOL'
                       WHERE s2.parent_geo = s.parent_geo ORDER BY o.id LIMIT 1) tpl
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices ox WHERE ox.district_id = sd.id);

-- ─── 3c. SURPLUS seats (more offices than the board has seats): delete ────────────────────
-- (decision 2026-09-22: a seat that does not exist is deleted; its stale term cascades. Never
-- when a race references it -- the pre-flight above refuses that case.)
DELETE FROM essentials.offices o
 USING essentials.districts pd
 WHERE o.district_id = pd.id AND pd.district_type = 'SCHOOL' AND pd.mtfcc = 'G5420'
   AND pd.geo_id IN (SELECT DISTINCT parent_geo FROM _seat)
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);

-- ─── 4. Politician rows for the sitting members (party NULL: never stored) ────────────────
INSERT INTO essentials.politicians (first_name, last_name, full_name, party, party_short_name,
                                    is_active, is_incumbent, is_vacant, is_appointed, data_source)
SELECT s.first_name, s.last_name, s.full_name, NULL, NULL, true, true, false, false, s.url
  FROM _seat s
 WHERE s.existing_pid IS NULL AND s.full_name IS NOT NULL AND s.vacant_since IS NULL AND s.first_name IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.data_source = s.url);

UPDATE _seat s SET pid = COALESCE(s.existing_pid,
  (SELECT p.id FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.data_source = s.url ORDER BY p.created_at LIMIT 1));

-- ─── 4a. Reused rows: sourced to the board page they were verified on ─────────────────────
UPDATE essentials.politicians p SET data_source = s.url
  FROM _seat s WHERE p.id = s.existing_pid AND p.data_source IS NULL;
UPDATE essentials.politicians SET alternate_names = ARRAY(SELECT DISTINCT unnest(alternate_names || '{"Satra D. Zurita"}'::text[]))
 WHERE id = '1aed9fdb-9c5c-4751-b48a-359bcdde5653' AND NOT alternate_names @> '{"Satra D. Zurita"}';
UPDATE essentials.politicians SET alternate_names = ARRAY(SELECT DISTINCT unnest(alternate_names || '{"Alma Taylor Pleasant"}'::text[]))
 WHERE id = '123e8e2b-4c4c-471f-80a4-216a1a73c50c' AND NOT alternate_names @> '{"Alma Taylor Pleasant"}';

-- ─── 5. Close each stale term the day before its successor starts ─────────────────────────
-- Convention agreed 2026-09-22 (both LA roster sessions): how_ended 'unknown', end date not researched.
UPDATE essentials.office_terms t
   SET term_end = s.term_start - 1,
       how_ended = 'unknown',
       source = COALESCE(t.source, '') || ' | CA_0154: closed as stale; the district''s current board page does not list this person; end date NOT researched (set to the day before the verified successor''s term start)'
  FROM _seat s
  JOIN essentials.districts sd ON sd.geo_id = s.geo_id AND sd.district_type = 'SCHOOL'
  JOIN essentials.offices o ON o.district_id = sd.id
 WHERE t.office_id = o.id AND t.term_end IS NULL AND t.politician_id IS DISTINCT FROM s.pid;

UPDATE essentials.politicians p
   SET is_incumbent = false
 WHERE p.is_incumbent
   AND p.id IN (SELECT t.politician_id FROM essentials.office_terms t
                  JOIN essentials.offices o ON o.id = t.office_id
                  JOIN essentials.districts sd ON sd.id = o.district_id
                  JOIN _seat s ON s.geo_id = sd.geo_id
                 WHERE t.how_ended = 'unknown' AND t.term_end = s.term_start - 1)
   AND NOT EXISTS (SELECT 1 FROM essentials.current_office_holders coh WHERE coh.politician_id = p.id);


-- ─── 6. Seat the current members ──────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT o.id, s.pid, s.term_start, s.prec, s.how, s.src
  FROM _seat s
  JOIN essentials.districts sd ON sd.geo_id = s.geo_id AND sd.district_type = 'SCHOOL'
  JOIN essentials.offices o ON o.district_id = sd.id
 WHERE s.pid IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id AND t.politician_id = s.pid);

UPDATE essentials.politicians p SET is_incumbent = true FROM _seat s WHERE p.id = s.pid AND NOT p.is_incumbent;
-- Party is never stored: clear it on every seated member (reused rows can carry a legacy 'Nonpartisan').
UPDATE essentials.politicians p SET party = NULL, party_short_name = NULL FROM _seat s WHERE p.id = s.pid AND (p.party IS NOT NULL OR p.party_short_name IS NOT NULL);
-- A verified VACANT area: flag the seat (the span is written only where its start is known).
UPDATE essentials.offices o SET is_vacant = true, vacant_since = s.vacant_since
  FROM _seat s JOIN essentials.districts sd ON sd.geo_id = s.geo_id AND sd.district_type = 'SCHOOL'
 WHERE o.district_id = sd.id AND s.full_name IS NULL AND NOT o.is_vacant;

-- ─── 8. Post-verify gate ──────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; n2 int; worst double precision;
BEGIN
  SELECT count(*) INTO n FROM _seat s JOIN essentials.geofence_boundaries gb ON gb.geo_id = s.geo_id AND gb.mtfcc = 'X0002'
   WHERE public.ST_IsValid(gb.geometry);
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 valid trustee-area polygons, got %', n; END IF;

  -- each area: exactly one office, and it is held by exactly the member named for that area
  SELECT count(*) INTO n FROM _seat s JOIN essentials.districts sd ON sd.geo_id = s.geo_id AND sd.district_type = 'SCHOOL' AND sd.mtfcc = 'X0002'
   WHERE (SELECT count(*) FROM essentials.offices o WHERE o.district_id = sd.id) = 1
     AND (SELECT och.politician_id FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
           WHERE o.district_id = sd.id) IS NOT DISTINCT FROM s.pid
     AND (s.full_name IS NOT NULL OR (SELECT bool_and(o.is_vacant) FROM essentials.offices o WHERE o.district_id = sd.id));
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 areas each held by its named member, got %', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o JOIN essentials.districts pd ON pd.id = o.district_id
   WHERE pd.district_type = 'SCHOOL' AND pd.mtfcc = 'G5420' AND pd.geo_id IN ('0609620');
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) still on a whole-district row', n; END IF;

  SELECT count(*) INTO n FROM _seat s JOIN essentials.districts sd ON sd.geo_id = s.geo_id AND sd.district_type = 'SCHOOL'
    JOIN essentials.offices o ON o.district_id = sd.id JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE t.term_end IS NULL AND t.politician_id IS DISTINCT FROM s.pid;
  IF n <> 0 THEN RAISE EXCEPTION '% stale open term(s) remain', n; END IF;

  SELECT count(*) INTO n FROM _seat s JOIN essentials.politicians p ON p.id = s.pid WHERE p.party IS NOT NULL AND s.existing_pid IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% new member row(s) carry a party', n; END IF;

  -- coverage per district vs the TIGER unified polygon (planar ratio; no ::geography, decision 0006)
  SELECT max(abs(public.ST_Area(t.geometry) - public.ST_Area(u.g)) / public.ST_Area(t.geometry)) INTO worst
    FROM (SELECT s.parent_geo, public.ST_Union(gb.geometry) g FROM _seat s
            JOIN essentials.geofence_boundaries gb ON gb.geo_id = s.geo_id AND gb.mtfcc = 'X0002'
           WHERE s.parent_geo IN ('0609620') GROUP BY 1) u
    JOIN essentials.geofence_boundaries t ON t.geo_id = u.parent_geo AND t.mtfcc = 'G5420';
  IF worst > 0.03 THEN RAISE EXCEPTION 'a district''s trustee areas differ from its TIGER polygon by % pct', round((worst*100)::numeric, 2); END IF;

  -- partition: no two areas of one district overlap beyond ~1,000 m2 (1e-7 deg2 at 34 N)
  SELECT count(*) INTO n FROM _seat a JOIN _seat b ON a.parent_geo = b.parent_geo AND a.geo_id < b.geo_id
    JOIN essentials.geofence_boundaries ga ON ga.geo_id = a.geo_id AND ga.mtfcc = 'X0002'
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = b.geo_id AND gb.mtfcc = 'X0002'
   WHERE public.ST_Area(public.ST_Intersection(ga.geometry, gb.geometry)) > 1e-7;
  IF n <> 0 THEN RAISE EXCEPTION '% trustee-area pair(s) overlap', n; END IF;

  -- END TO END: an interior point of each area returns exactly its own member among that district's seats
  SELECT count(*) INTO n FROM _seat me JOIN essentials.geofence_boundaries mg ON mg.geo_id = me.geo_id AND mg.mtfcc = 'X0002'
   WHERE me.full_name IS NOT NULL AND (SELECT string_agg(och.politician_id::text, ',') FROM _seat s2
            JOIN essentials.geofence_boundaries gb ON gb.geo_id = s2.geo_id AND gb.mtfcc = 'X0002'
            JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.district_type = 'SCHOOL' AND d.mtfcc = 'X0002'
            JOIN essentials.offices o ON o.district_id = d.id
            JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
           WHERE s2.parent_geo = me.parent_geo AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(mg.geometry)))
         IS DISTINCT FROM me.pid::text;
  IF n <> 0 THEN RAISE EXCEPTION '% trustee area(s) do not return exactly their own member at an interior point', n; END IF;

  RAISE NOTICE 'CA_0154 applied: 7 trustee areas, 0 races, 0 candidates';
END $$;

COMMIT;
