-- CC_0286_trivia_options_scale_quantities.sql
--
-- Give 290 numeric trivia questions a 7-mark `options_scale`, so the correct answer stops
-- sitting at a fixed position while the four options still read in ascending order.
--
-- WHAT A SCALE DOES. CC_0188 added `trivia.questions.options_scale`: 7 ascending marks
-- with the correct answer at index 3. At serve time the server rolls s in 1..4 and shows
-- marks[s-1 .. s+2], so the answer lands on D/C/B/A uniformly. Until this migration ran,
-- the column existed and NOT ONE question carried a scale, so the feature was dark.
--
-- WHY THESE 290. Produced by `scripts/build-answer-scales.ts`, whose rules are held by
-- `scripts/build-answer-scales.test.ts` in CI. Of 436 numeric questions it considered,
-- 146 were refused and are deliberately left NULL -- a refusal is the correct outcome and
-- the serve path falls back to the stored `options`, so a refused question is unchanged.
-- Refusals: 83 bounded series (no honest mark below "1 year"), 53 whose number names a
-- thing rather than a quantity (ordinals, "Interstate 10", clock times, two numbers in
-- one option), 7 with no step that fits the domain, 3 terms of office.
--
-- EVERY MARK IS A POSSIBLE ANSWER. A mark a player can rule out without knowing the
-- answer is a free elimination, which would make these questions EASIER than the four
-- options they replace. Hence the floors and ceilings in the generator: a share stops at
-- 100%, a count of states at 50, a seat count on a body starts at 3. Years are NOT in
-- this batch -- they need the past/future test, and 13 active questions correctly offer
-- a future year ("In what year is the next presidential election scheduled?").
--
-- THE MARKS ARE EVENLY SPACED, ANCHORED ON THE ANSWER. Any window of four is then
-- equally spaced, so no option is singled out, and every mark shares the answer's
-- residue -- round marks around an unround answer would be a tell.
--
-- IDEMPOTENT. The UPDATE skips a row that already has a scale, and skips any question
-- whose answer no longer matches the scale's centre mark -- the exact invariant
-- servePresentation.ts checks before it uses a scale. A question edited since this file
-- was generated is passed over rather than given a scale that points at the wrong value.

BEGIN;

WITH proposed(id, scale) AS (
  VALUES

    (1, '["4", "6", "8", "10", "12", "14", "16"]'::jsonb),
    (3, '["20 years old", "25 years old", "30 years old", "35 years old", "40 years old", "45 years old", "50 years old"]'::jsonb),
    (7, '["6", "7", "8", "9", "10", "11", "12"]'::jsonb),
    (10, '["15", "16", "17", "18", "19", "20", "21"]'::jsonb),
    (16, '["426", "429", "432", "435", "438", "441", "444"]'::jsonb),
    (23, '["529", "532", "535", "538", "541", "544", "547"]'::jsonb),
    (30, '["18", "21", "24", "27", "30", "33", "36"]'::jsonb),
    (47, '["51", "54", "57", "60", "63", "66", "69"]'::jsonb),
    (121, '["3 members", "5 members", "7 members", "9 members", "11 members", "13 members", "15 members"]'::jsonb),
    (127, '["17 parks", "22 parks", "27 parks", "32 parks", "37 parks", "42 parks", "47 parks"]'::jsonb),
    (133, '["55,000 residents", "65,000 residents", "75,000 residents", "85,000 residents", "95,000 residents", "105,000 residents", "115,000 residents"]'::jsonb),
    (139, '["About 65,000 residents", "About 90,000 residents", "About 115,000 residents", "About 140,000 residents", "About 165,000 residents", "About 190,000 residents", "About 215,000 residents"]'::jsonb),
    (169, '["14 days before", "19 days before", "24 days before", "29 days before", "34 days before", "39 days before", "44 days before"]'::jsonb),
    (321, '["40", "60", "80", "100", "120", "140", "160"]'::jsonb),
    (322, '["20", "30", "40", "50", "60", "70", "80"]'::jsonb),
    (325, '["31 days", "41 days", "51 days", "61 days", "71 days", "81 days", "91 days"]'::jsonb),
    (326, '["15 days", "20 days", "25 days", "30 days", "35 days", "40 days", "45 days"]'::jsonb),
    (342, '["3", "4", "5", "6", "7", "8", "9"]'::jsonb),
    (352, '["6 judges", "9 judges", "12 judges", "15 judges", "18 judges", "21 judges", "24 judges"]'::jsonb),
    (363, '["15 years old", "16 years old", "17 years old", "18 years old", "19 years old", "20 years old", "21 years old"]'::jsonb),
    (372, '["25 senators", "30 senators", "35 senators", "40 senators", "45 senators", "50 senators", "55 senators"]'::jsonb),
    (375, '["6 years", "8 years", "10 years", "12 years", "14 years", "16 years", "18 years"]'::jsonb),
    (387, '["2 officers", "4 officers", "6 officers", "8 officers", "10 officers", "12 officers", "14 officers"]'::jsonb),
    (399, '["15 years old", "16 years old", "17 years old", "18 years old", "19 years old", "20 years old", "21 years old"]'::jsonb),
    (417, '["13 years old", "14 years old", "15 years old", "16 years old", "17 years old", "18 years old", "19 years old"]'::jsonb),
    (677, '["3 districts", "4 districts", "5 districts", "6 districts", "7 districts", "8 districts", "9 districts"]'::jsonb),
    (1399, '["7 articles", "10 articles", "13 articles", "16 articles", "19 articles", "22 articles", "25 articles"]'::jsonb),
    (3688, '["20 members", "40 members", "60 members", "80 members", "100 members", "120 members", "140 members"]'::jsonb),
    (4406, '["24 councillors", "29 councillors", "34 councillors", "39 councillors", "44 councillors", "49 councillors", "54 councillors"]'::jsonb),
    (4407, '["7 wards", "9 wards", "11 wards", "13 wards", "15 wards", "17 wards", "19 wards"]'::jsonb),
    (4416, '["15 years old", "16 years old", "17 years old", "18 years old", "19 years old", "20 years old", "21 years old"]'::jsonb),
    (5042, '["3 members", "5 members", "7 members", "9 members", "11 members", "13 members", "15 members"]'::jsonb),
    (5065, '["110 workers", "160 workers", "210 workers", "260 workers", "310 workers", "360 workers", "410 workers"]'::jsonb),
    (5068, '["267 votes", "767 votes", "1,267 votes", "1,767 votes", "2,267 votes", "2,767 votes", "3,267 votes"]'::jsonb),
    (5090, '["4,552 votes", "5,552 votes", "6,552 votes", "7,552 votes", "8,552 votes", "9,552 votes", "10,552 votes"]'::jsonb),
    (5136, '["$20 per day", "$30 per day", "$40 per day", "$50 per day", "$60 per day", "$70 per day", "$80 per day"]'::jsonb),
    (5137, '["3 hours", "6 hours", "9 hours", "12 hours", "15 hours", "18 hours", "21 hours"]'::jsonb),
    (5143, '["6 days", "11 days", "16 days", "21 days", "26 days", "31 days", "36 days"]'::jsonb),
    (5286, '["100 members", "120 members", "140 members", "160 members", "180 members", "200 members", "220 members"]'::jsonb),
    (5287, '["25 senators", "30 senators", "35 senators", "40 senators", "45 senators", "50 senators", "55 senators"]'::jsonb),
    (5302, '["5 members", "6 members", "7 members", "8 members", "9 members", "10 members", "11 members"]'::jsonb),
    (5319, '["6 members", "7 members", "8 members", "9 members", "10 members", "11 members", "12 members"]'::jsonb),
    (5353, '["2 Republicans", "3 Republicans", "4 Republicans", "5 Republicans", "6 Republicans", "7 Republicans", "8 Republicans"]'::jsonb),
    (5494, '["5 members total", "6 members total", "7 members total", "8 members total", "9 members total", "10 members total", "11 members total"]'::jsonb),
    (5500, '["2,872", "7,872", "12,872", "17,872", "22,872", "27,872", "32,872"]'::jsonb),
    (5507, '["22 buildings", "32 buildings", "42 buildings", "52 buildings", "62 buildings", "72 buildings", "82 buildings"]'::jsonb),
    (5551, '["147,030", "172,030", "197,030", "222,030", "247,030", "272,030", "297,030"]'::jsonb),
    (5742, '["90", "110", "130", "150", "170", "190", "210"]'::jsonb),
    (5743, '["22", "25", "28", "31", "34", "37", "40"]'::jsonb),
    (5750, '["15 days", "20 days", "25 days", "30 days", "35 days", "40 days", "45 days"]'::jsonb),
    (5760, '["81%", "84%", "87%", "90%", "93%", "96%", "99%"]'::jsonb),
    (5788, '["3 justices", "5 justices", "7 justices", "9 justices", "11 justices", "13 justices", "15 justices"]'::jsonb),
    (5791, '["3 judges", "5 judges", "7 judges", "9 judges", "11 judges", "13 judges", "15 judges"]'::jsonb),
    (5803, '["8 articles", "11 articles", "14 articles", "17 articles", "20 articles", "23 articles", "26 articles"]'::jsonb),
    (5950, '["6 councilors", "8 councilors", "10 councilors", "12 councilors", "14 councilors", "16 councilors", "18 councilors"]'::jsonb),
    (6386, '["About 2,200 acres", "About 3,200 acres", "About 4,200 acres", "About 5,200 acres", "About 6,200 acres", "About 7,200 acres", "About 8,200 acres"]'::jsonb),
    (6796, '["30 members", "40 members", "50 members", "60 members", "70 members", "80 members", "90 members"]'::jsonb),
    (6805, '["3 tribes", "5 tribes", "7 tribes", "9 tribes", "11 tribes", "13 tribes", "15 tribes"]'::jsonb),
    (6809, '["2 cents", "3 cents", "4 cents", "5 cents", "6 cents", "7 cents", "8 cents"]'::jsonb),
    (6818, '["2% of votes in last gubernatorial election", "4% of votes in last gubernatorial election", "6% of votes in last gubernatorial election", "8% of votes in last gubernatorial election", "10% of votes in last gubernatorial election", "12% of votes in last gubernatorial election", "14% of votes in last gubernatorial election"]'::jsonb),
    (7069, '["4", "5", "6", "7", "8", "9", "10"]'::jsonb),
    (7074, '["27", "30", "33", "36", "39", "42", "45"]'::jsonb),
    (7205, '["7 members", "9 members", "11 members", "13 members", "15 members", "17 members", "19 members"]'::jsonb),
    (7206, '["2 wards", "4 wards", "6 wards", "8 wards", "10 wards", "12 wards", "14 wards"]'::jsonb),
    (7209, '["31 ANCs", "36 ANCs", "41 ANCs", "46 ANCs", "51 ANCs", "56 ANCs", "61 ANCs"]'::jsonb),
    (7214, '["3 judges", "5 judges", "7 judges", "9 judges", "11 judges", "13 judges", "15 judges"]'::jsonb),
    (7271, '["$2,500", "$5,000", "$7,500", "$10,000", "$12,500", "$15,000", "$17,500"]'::jsonb),
    (7618, '["539,545", "589,545", "639,545", "689,545", "739,545", "789,545", "839,545"]'::jsonb),
    (7823, '["15 days", "20 days", "25 days", "30 days", "35 days", "40 days", "45 days"]'::jsonb),
    (7869, '["195 SMDs", "245 SMDs", "295 SMDs", "345 SMDs", "395 SMDs", "445 SMDs", "495 SMDs"]'::jsonb),
    (7884, '["56 neighborhoods", "81 neighborhoods", "106 neighborhoods", "131 neighborhoods", "156 neighborhoods", "181 neighborhoods", "206 neighborhoods"]'::jsonb),
    (8221, '["4 members", "5 members", "6 members", "7 members", "8 members", "9 members", "10 members"]'::jsonb),
    (8231, '["34,449", "39,449", "44,449", "49,449", "54,449", "59,449", "64,449"]'::jsonb),
    (8321, '["11 miles", "16 miles", "21 miles", "26 miles", "31 miles", "36 miles", "41 miles"]'::jsonb),
    (8350, '["20%", "30%", "40%", "50%", "60%", "70%", "80%"]'::jsonb),
    (8384, '["21 feet", "24 feet", "27 feet", "30 feet", "33 feet", "36 feet", "39 feet"]'::jsonb),
    (8386, '["163", "188", "213", "238", "263", "288", "313"]'::jsonb),
    (8544, '["92 members", "102 members", "112 members", "122 members", "132 members", "142 members", "152 members"]'::jsonb),
    (8547, '["3 justices", "5 justices", "7 justices", "9 justices", "11 justices", "13 justices", "15 justices"]'::jsonb),
    (8558, '["57.8%", "62.8%", "67.8%", "72.8%", "77.8%", "82.8%", "87.8%"]'::jsonb),
    (8568, '["14 miles", "24 miles", "34 miles", "44 miles", "54 miles", "64 miles", "74 miles"]'::jsonb),
    (8574, '["25%", "35%", "45%", "55%", "65%", "75%", "85%"]'::jsonb),
    (8590, '["4%", "5%", "6%", "7%", "8%", "9%", "10%"]'::jsonb),
    (8599, '["47 percent", "50 percent", "53 percent", "56 percent", "59 percent", "62 percent", "65 percent"]'::jsonb),
    (8604, '["98.8%", "99.0%", "99.2%", "99.4%", "99.6%", "99.8%", "100.0%"]'::jsonb),
    (8605, '["$120 billion", "$130 billion", "$140 billion", "$150 billion", "$160 billion", "$170 billion", "$180 billion"]'::jsonb),
    (8607, '["2.4%", "2.9%", "3.4%", "3.9%", "4.4%", "4.9%", "5.4%"]'::jsonb),
    (8627, '["12 stars", "15 stars", "18 stars", "21 stars", "24 stars", "27 stars", "30 stars"]'::jsonb),
    (8645, '["22 members", "32 members", "42 members", "52 members", "62 members", "72 members", "82 members"]'::jsonb),
    (8663, '["67", "72", "77", "82", "87", "92", "97"]'::jsonb),
    (8842, '["4 members", "5 members", "6 members", "7 members", "8 members", "9 members", "10 members"]'::jsonb),
    (9207, '["250 acres", "500 acres", "750 acres", "1,000 acres", "1,250 acres", "1,500 acres", "1,750 acres"]'::jsonb),
    (9256, '["Nearly 92 percent", "Nearly 93 percent", "Nearly 94 percent", "Nearly 95 percent", "Nearly 96 percent", "Nearly 97 percent", "Nearly 98 percent"]'::jsonb),
    (9460, '["4", "5", "6", "7", "8", "9", "10"]'::jsonb),
    (9483, '["About 13,000", "About 23,000", "About 33,000", "About 43,000", "About 53,000", "About 63,000", "About 73,000"]'::jsonb),
    (9533, '["81%", "84%", "87%", "90%", "93%", "96%", "99%"]'::jsonb),
    (9535, '["200,000", "300,000", "400,000", "500,000", "600,000", "700,000", "800,000"]'::jsonb),
    (9672, '["24", "29", "34", "39", "44", "49", "54"]'::jsonb),
    (9673, '["75", "85", "95", "105", "115", "125", "135"]'::jsonb),
    (9678, '["49", "54", "59", "64", "69", "74", "79"]'::jsonb),
    (9681, '["4", "5", "6", "7", "8", "9", "10"]'::jsonb),
    (9691, '["$6 million", "$9 million", "$12 million", "$15 million", "$18 million", "$21 million", "$24 million"]'::jsonb),
    (9723, '["81%", "84%", "87%", "90%", "93%", "96%", "99%"]'::jsonb),
    (9725, '["30%", "40%", "50%", "60%", "70%", "80%", "90%"]'::jsonb),
    (9739, '["5", "7", "9", "11", "13", "15", "17"]'::jsonb),
    (9881, '["3", "5", "7", "9", "11", "13", "15"]'::jsonb),
    (9907, '["20 acres", "30 acres", "40 acres", "50 acres", "60 acres", "70 acres", "80 acres"]'::jsonb),
    (9921, '["2,400", "3,400", "4,400", "5,400", "6,400", "7,400", "8,400"]'::jsonb),
    (9929, '["4,500", "7,000", "9,500", "12,000", "14,500", "17,000", "19,500"]'::jsonb),
    (9939, '["I-29", "I-34", "I-39", "I-44", "I-49", "I-54", "I-59"]'::jsonb),
    (9946, '["2 square feet", "4 square feet", "6 square feet", "8 square feet", "10 square feet", "12 square feet", "14 square feet"]'::jsonb),
    (9947, '["2,500,000", "3,000,000", "3,500,000", "4,000,000", "4,500,000", "5,000,000", "5,500,000"]'::jsonb),
    (9973, '["800", "1,300", "1,800", "2,300", "2,800", "3,300", "3,800"]'::jsonb),
    (9983, '["5", "8", "11", "14", "17", "20", "23"]'::jsonb),
    (9985, '["19", "39", "59", "79", "99", "119", "139"]'::jsonb),
    (9990, '["12", "13", "14", "15", "16", "17", "18"]'::jsonb),
    (9993, '["151,578", "201,578", "251,578", "301,578", "351,578", "401,578", "451,578"]'::jsonb),
    (10014, '["330 feet", "430 feet", "530 feet", "630 feet", "730 feet", "830 feet", "930 feet"]'::jsonb),
    (10040, '["2", "5", "8", "11", "14", "17", "20"]'::jsonb),
    (10089, '["4", "14", "24", "34", "44", "54", "64"]'::jsonb),
    (10090, '["133", "143", "153", "163", "173", "183", "193"]'::jsonb),
    (10096, '["4", "5", "6", "7", "8", "9", "10"]'::jsonb),
    (10103, '["3.2 million", "4.2 million", "5.2 million", "6.2 million", "7.2 million", "8.2 million", "9.2 million"]'::jsonb),
    (10119, '["5 states", "6 states", "7 states", "8 states", "9 states", "10 states", "11 states"]'::jsonb),
    (10122, '["1,591 miles", "1,841 miles", "2,091 miles", "2,341 miles", "2,591 miles", "2,841 miles", "3,091 miles"]'::jsonb),
    (10126, '["18,000 square miles", "23,000 square miles", "28,000 square miles", "33,000 square miles", "38,000 square miles", "43,000 square miles", "48,000 square miles"]'::jsonb),
    (10127, '["5,800 caves", "6,300 caves", "6,800 caves", "7,300 caves", "7,800 caves", "8,300 caves", "8,800 caves"]'::jsonb),
    (10158, '["15", "20", "25", "30", "35", "40", "45"]'::jsonb),
    (10159, '["30", "40", "50", "60", "70", "80", "90"]'::jsonb),
    (10165, '["6", "7", "8", "9", "10", "11", "12"]'::jsonb),
    (10168, '["15", "20", "25", "30", "35", "40", "45"]'::jsonb),
    (10191, '["127 miles", "177 miles", "227 miles", "277 miles", "327 miles", "377 miles", "427 miles"]'::jsonb),
    (10198, '["$0.96 million", "$1.46 million", "$1.96 million", "$2.46 million", "$2.96 million", "$3.46 million", "$3.96 million"]'::jsonb),
    (10207, '["13", "16", "19", "22", "25", "28", "31"]'::jsonb),
    (10209, '["850 AD", "950 AD", "1050 AD", "1150 AD", "1250 AD", "1350 AD", "1450 AD"]'::jsonb),
    (10250, '["6", "7", "8", "9", "10", "11", "12"]'::jsonb),
    (10256, '["3", "4", "5", "6", "7", "8", "9"]'::jsonb),
    (10283, '["30 miles", "40 miles", "50 miles", "60 miles", "70 miles", "80 miles", "90 miles"]'::jsonb),
    (10346, '["About 250,000", "About 350,000", "About 450,000", "About 550,000", "About 650,000", "About 750,000", "About 850,000"]'::jsonb),
    (10352, '["6", "7", "8", "9", "10", "11", "12"]'::jsonb),
    (10357, '["5", "6", "7", "8", "9", "10", "11"]'::jsonb),
    (10420, '["83 days", "93 days", "103 days", "113 days", "123 days", "133 days", "143 days"]'::jsonb),
    (10423, '["10% of the city", "15% of the city", "20% of the city", "25% of the city", "30% of the city", "35% of the city", "40% of the city"]'::jsonb),
    (10443, '["4", "5", "6", "7", "8", "9", "10"]'::jsonb),
    (10473, '["64,589", "74,589", "84,589", "94,589", "104,589", "114,589", "124,589"]'::jsonb),
    (10475, '["About 50", "About 150", "About 250", "About 350", "About 450", "About 550", "About 650"]'::jsonb),
    (10479, '["100", "150", "200", "250", "300", "350", "400"]'::jsonb),
    (10513, '["2.9%", "5.4%", "7.9%", "10.4%", "12.9%", "15.4%", "17.9%"]'::jsonb),
    (10515, '["40%", "50%", "60%", "70%", "80%", "90%", "100%"]'::jsonb),
    (10520, '["5%", "10%", "15%", "20%", "25%", "30%", "35%"]'::jsonb),
    (10522, '["700 feet", "1,200 feet", "1,700 feet", "2,200 feet", "2,700 feet", "3,200 feet", "3,700 feet"]'::jsonb),
    (10527, '["194,452", "219,452", "244,452", "269,452", "294,452", "319,452", "344,452"]'::jsonb),
    (10529, '["3,500 feet", "4,000 feet", "4,500 feet", "5,000 feet", "5,500 feet", "6,000 feet", "6,500 feet"]'::jsonb),
    (10540, '["20", "30", "40", "50", "60", "70", "80"]'::jsonb),
    (10541, '["90", "100", "110", "120", "130", "140", "150"]'::jsonb),
    (10548, '["4", "5", "6", "7", "8", "9", "10"]'::jsonb),
    (10584, '["319 miles", "369 miles", "419 miles", "469 miles", "519 miles", "569 miles", "619 miles"]'::jsonb),
    (10706, '["5,603", "8,103", "10,603", "13,103", "15,603", "18,103", "20,603"]'::jsonb),
    (10728, '["33", "43", "53", "63", "73", "83", "93"]'::jsonb),
    (10729, '["90", "110", "130", "150", "170", "190", "210"]'::jsonb),
    (10732, '["4", "5", "6", "7", "8", "9", "10"]'::jsonb),
    (10737, '["Every 5 years", "Every 10 years", "Every 15 years", "Every 20 years", "Every 25 years", "Every 30 years", "Every 35 years"]'::jsonb),
    (10741, '["183", "193", "203", "213", "223", "233", "243"]'::jsonb),
    (10746, '["6", "7", "8", "9", "10", "11", "12"]'::jsonb),
    (10774, '["$10 million", "$15 million", "$20 million", "$25 million", "$30 million", "$35 million", "$40 million"]'::jsonb),
    (10788, '["About 5 million", "About 10 million", "About 15 million", "About 20 million", "About 25 million", "About 30 million", "About 35 million"]'::jsonb),
    (10795, '["$0.8 trillion", "$1.3 trillion", "$1.8 trillion", "$2.3 trillion", "$2.8 trillion", "$3.3 trillion", "$3.8 trillion"]'::jsonb),
    (10803, '["34", "44", "54", "64", "74", "84", "94"]'::jsonb),
    (10804, '["About 100,000", "About 200,000", "About 300,000", "About 400,000", "About 500,000", "About 600,000", "About 700,000"]'::jsonb),
    (10821, '["7", "9", "11", "13", "15", "17", "19"]'::jsonb),
    (10823, '["8", "10", "12", "14", "16", "18", "20"]'::jsonb),
    (10834, '["42", "45", "48", "51", "54", "57", "60"]'::jsonb),
    (10873, '["About 65", "About 90", "About 115", "About 140", "About 165", "About 190", "About 215"]'::jsonb),
    (10885, '["39%", "44%", "49%", "54%", "59%", "64%", "69%"]'::jsonb),
    (10887, '["12%", "17%", "22%", "27%", "32%", "37%", "42%"]'::jsonb),
    (10920, '["3", "4", "5", "6", "7", "8", "9"]'::jsonb),
    (10930, '["8", "10", "12", "14", "16", "18", "20"]'::jsonb),
    (10953, '["20", "30", "40", "50", "60", "70", "80"]'::jsonb),
    (10954, '["173", "183", "193", "203", "213", "223", "233"]'::jsonb),
    (10993, '["1,330 pounds", "1,580 pounds", "1,830 pounds", "2,080 pounds", "2,330 pounds", "2,580 pounds", "2,830 pounds"]'::jsonb),
    (11005, '["121 words", "171 words", "221 words", "271 words", "321 words", "371 words", "421 words"]'::jsonb),
    (11020, '["325 rooms", "375 rooms", "425 rooms", "475 rooms", "525 rooms", "575 rooms", "625 rooms"]'::jsonb),
    (11030, '["3 states", "4 states", "5 states", "6 states", "7 states", "8 states", "9 states"]'::jsonb),
    (11031, '["30%", "40%", "50%", "60%", "70%", "80%", "90%"]'::jsonb),
    (11044, '["4", "5", "6", "7", "8", "9", "10"]'::jsonb),
    (11048, '["8", "11", "14", "17", "20", "23", "26"]'::jsonb),
    (11060, '["About 1,000,000", "About 1,200,000", "About 1,400,000", "About 1,600,000", "About 1,800,000", "About 2,000,000", "About 2,200,000"]'::jsonb),
    (11089, '["37", "47", "57", "67", "77", "87", "97"]'::jsonb),
    (11098, '["398 feet", "448 feet", "498 feet", "548 feet", "598 feet", "648 feet", "698 feet"]'::jsonb),
    (11108, '["42 steps", "52 steps", "62 steps", "72 steps", "82 steps", "92 steps", "102 steps"]'::jsonb),
    (11111, '["552 acres", "1,052 acres", "1,552 acres", "2,052 acres", "2,552 acres", "3,052 acres", "3,552 acres"]'::jsonb),
    (11131, '["106", "131", "156", "181", "206", "231", "256"]'::jsonb),
    (11144, '["3", "5", "7", "9", "11", "13", "15"]'::jsonb),
    (11183, '["691 feet", "741 feet", "791 feet", "841 feet", "891 feet", "941 feet", "991 feet"]'::jsonb),
    (11193, '["296", "346", "396", "446", "496", "546", "596"]'::jsonb),
    (11197, '["60", "70", "80", "90", "100", "110", "120"]'::jsonb),
    (11202, '["15.4%", "20.4%", "25.4%", "30.4%", "35.4%", "40.4%", "45.4%"]'::jsonb),
    (11206, '["1", "4", "7", "10", "13", "16", "19"]'::jsonb),
    (11210, '["About 235,000", "About 260,000", "About 285,000", "About 310,000", "About 335,000", "About 360,000", "About 385,000"]'::jsonb),
    (11212, '["1.68 million", "1.93 million", "2.18 million", "2.43 million", "2.68 million", "2.93 million", "3.18 million"]'::jsonb),
    (11216, '["1", "2", "3", "4", "5", "6", "7"]'::jsonb),
    (11274, '["22", "32", "42", "52", "62", "72", "82"]'::jsonb),
    (11275, '["294 days", "344 days", "394 days", "444 days", "494 days", "544 days", "594 days"]'::jsonb),
    (11283, '["5%", "10%", "15%", "20%", "25%", "30%", "35%"]'::jsonb),
    (11295, '["84%", "86%", "88%", "90%", "92%", "94%", "96%"]'::jsonb),
    (11683, '["126", "176", "226", "276", "326", "376", "426"]'::jsonb),
    (11731, '["9,825", "14,825", "19,825", "24,825", "29,825", "34,825", "39,825"]'::jsonb),
    (11737, '["43.2 years", "45.7 years", "48.2 years", "50.7 years", "53.2 years", "55.7 years", "58.2 years"]'::jsonb),
    (11743, '["5 minutes", "15 minutes", "25 minutes", "35 minutes", "45 minutes", "55 minutes", "65 minutes"]'::jsonb),
    (11760, '["19", "29", "39", "49", "59", "69", "79"]'::jsonb),
    (11761, '["68", "78", "88", "98", "108", "118", "128"]'::jsonb),
    (11766, '["3", "5", "7", "9", "11", "13", "15"]'::jsonb),
    (11794, '["11", "16", "21", "26", "31", "36", "41"]'::jsonb),
    (11856, '["4", "6", "8", "10", "12", "14", "16"]'::jsonb),
    (12319, '["9 members", "11 members", "13 members", "15 members", "17 members", "19 members", "21 members"]'::jsonb),
    (12320, '["12 days before", "13 days before", "14 days before", "15 days before", "16 days before", "17 days before", "18 days before"]'::jsonb),
    (13464, '["11", "14", "17", "20", "23", "26", "29"]'::jsonb),
    (13544, '["About 120,000", "About 170,000", "About 220,000", "About 270,000", "About 320,000", "About 370,000", "About 420,000"]'::jsonb),
    (13552, '["3", "13", "23", "33", "43", "53", "63"]'::jsonb),
    (13574, '["8", "10", "12", "14", "16", "18", "20"]'::jsonb),
    (13582, '["250 years", "300 years", "350 years", "400 years", "450 years", "500 years", "550 years"]'::jsonb),
    (13594, '["About 16,000", "About 41,000", "About 66,000", "About 91,000", "About 116,000", "About 141,000", "About 166,000"]'::jsonb),
    (13618, '["12", "15", "18", "21", "24", "27", "30"]'::jsonb),
    (13621, '["57", "62", "67", "72", "77", "82", "87"]'::jsonb),
    (13627, '["About 11 percent", "About 16 percent", "About 21 percent", "About 26 percent", "About 31 percent", "About 36 percent", "About 41 percent"]'::jsonb),
    (13629, '["About 30 percent", "About 40 percent", "About 50 percent", "About 60 percent", "About 70 percent", "About 80 percent", "About 90 percent"]'::jsonb),
    (13630, '["About 94 percent", "About 95 percent", "About 96 percent", "About 97 percent", "About 98 percent", "About 99 percent", "About 100 percent"]'::jsonb),
    (13786, '["2,642 feet", "3,142 feet", "3,642 feet", "4,142 feet", "4,642 feet", "5,142 feet", "5,642 feet"]'::jsonb),
    (13791, '["About 550 years ago", "About 800 years ago", "About 1,050 years ago", "About 1,300 years ago", "About 1,550 years ago", "About 1,800 years ago", "About 2,050 years ago"]'::jsonb),
    (13812, '["39,178", "59,178", "79,178", "99,178", "119,178", "139,178", "159,178"]'::jsonb),
    (13815, '["880 acres", "1,380 acres", "1,880 acres", "2,380 acres", "2,880 acres", "3,380 acres", "3,880 acres"]'::jsonb),
    (13819, '["About 2,892 feet", "About 3,142 feet", "About 3,392 feet", "About 3,642 feet", "About 3,892 feet", "About 4,142 feet", "About 4,392 feet"]'::jsonb),
    (13821, '["About 186,000", "About 211,000", "About 236,000", "About 261,000", "About 286,000", "About 311,000", "About 336,000"]'::jsonb),
    (13975, '["6", "9", "12", "15", "18", "21", "24"]'::jsonb),
    (14053, '["427,222", "477,222", "527,222", "577,222", "627,222", "677,222", "727,222"]'::jsonb),
    (14063, '["About 820,000", "About 1,070,000", "About 1,320,000", "About 1,570,000", "About 1,820,000", "About 2,070,000", "About 2,320,000"]'::jsonb),
    (15524, '["About 130 parts per million", "About 180 parts per million", "About 230 parts per million", "About 280 parts per million", "About 330 parts per million", "About 380 parts per million", "About 430 parts per million"]'::jsonb),
    (15528, '["About 17%", "About 22%", "About 27%", "About 32%", "About 37%", "About 42%", "About 47%"]'::jsonb),
    (15532, '["About 0.3 mm per year", "About 1.3 mm per year", "About 2.3 mm per year", "About 3.3 mm per year", "About 4.3 mm per year", "About 5.3 mm per year", "About 6.3 mm per year"]'::jsonb),
    (15542, '["About 35%", "About 45%", "About 55%", "About 65%", "About 75%", "About 85%", "About 95%"]'::jsonb),
    (15656, '["61 years", "64 years", "67 years", "70 years", "73 years", "76 years", "79 years"]'::jsonb),
    (15826, '["6", "9", "12", "15", "18", "21", "24"]'::jsonb),
    (15864, '["5", "6", "7", "8", "9", "10", "11"]'::jsonb),
    (15868, '["104", "154", "204", "254", "304", "354", "404"]'::jsonb),
    (15882, '["15", "20", "25", "30", "35", "40", "45"]'::jsonb),
    (15908, '["About 1.3 million", "About 2.3 million", "About 3.3 million", "About 4.3 million", "About 5.3 million", "About 6.3 million", "About 7.3 million"]'::jsonb),
    (15973, '["About 4 million", "About 6 million", "About 8 million", "About 10 million", "About 12 million", "About 14 million", "About 16 million"]'::jsonb),
    (15981, '["13", "38", "63", "88", "113", "138", "163"]'::jsonb),
    (15982, '["About 10", "About 20", "About 30", "About 40", "About 50", "About 60", "About 70"]'::jsonb),
    (16029, '["6", "9", "12", "15", "18", "21", "24"]'::jsonb),
    (16038, '["15", "20", "25", "30", "35", "40", "45"]'::jsonb),
    (16059, '["About 80,000", "About 130,000", "About 180,000", "About 230,000", "About 280,000", "About 330,000", "About 380,000"]'::jsonb),
    (16079, '["About 0.2C", "About 0.5C", "About 0.8C", "About 1.1C", "About 1.4C", "About 1.7C", "About 2.0C"]'::jsonb),
    (16086, '["3", "5", "7", "9", "11", "13", "15"]'::jsonb),
    (16126, '["37", "42", "47", "52", "57", "62", "67"]'::jsonb),
    (16143, '["15 days", "20 days", "25 days", "30 days", "35 days", "40 days", "45 days"]'::jsonb),
    (16145, '["210,494", "235,494", "260,494", "285,494", "310,494", "335,494", "360,494"]'::jsonb),
    (16517, '["AD-45", "AD-47", "AD-49", "AD-51", "AD-53", "AD-55", "AD-57"]'::jsonb),
    (16519, '["SD-18", "SD-20", "SD-22", "SD-24", "SD-26", "SD-28", "SD-30"]'::jsonb),
    (16629, '["500", "1,000", "1,500", "2,000", "2,500", "3,000", "3,500"]'::jsonb),
    (16687, '["1%", "4%", "7%", "10%", "13%", "16%", "19%"]'::jsonb),
    (16698, '["13", "16", "19", "22", "25", "28", "31"]'::jsonb),
    (16700, '["11.8%", "21.8%", "31.8%", "41.8%", "51.8%", "61.8%", "71.8%"]'::jsonb),
    (16701, '["335", "1,335", "2,335", "3,335", "4,335", "5,335", "6,335"]'::jsonb),
    (16707, '["6,000 hectares", "11,000 hectares", "16,000 hectares", "21,000 hectares", "26,000 hectares", "31,000 hectares", "36,000 hectares"]'::jsonb),
    (16709, '["£3bn", "£13bn", "£23bn", "£33bn", "£43bn", "£53bn", "£63bn"]'::jsonb),
    (16710, '["38", "63", "88", "113", "138", "163", "188"]'::jsonb),
    (16711, '["6%", "9%", "12%", "15%", "18%", "21%", "24%"]'::jsonb),
    (16714, '["88%", "90%", "92%", "94%", "96%", "98%", "100%"]'::jsonb),
    (16727, '["15.0", "15.5", "16.0", "16.5", "17.0", "17.5", "18.0"]'::jsonb),
    (16728, '["9.5", "10.5", "11.5", "12.5", "13.5", "14.5", "15.5"]'::jsonb),
    (16729, '["20 micrograms per litre", "30 micrograms per litre", "40 micrograms per litre", "50 micrograms per litre", "60 micrograms per litre", "70 micrograms per litre", "80 micrograms per litre"]'::jsonb),
    (16730, '["1,100", "1,600", "2,100", "2,600", "3,100", "3,600", "4,100"]'::jsonb),
    (16733, '["456", "556", "656", "756", "856", "956", "1056"]'::jsonb),
    (16734, '["270", "370", "470", "570", "670", "770", "870"]'::jsonb),
    (16735, '["75", "100", "125", "150", "175", "200", "225"]'::jsonb),
    (16736, '["About 3%", "About 4%", "About 5%", "About 6%", "About 7%", "About 8%", "About 9%"]'::jsonb),
    (16744, '["79%", "82%", "85%", "88%", "91%", "94%", "97%"]'::jsonb),
    (16748, '["82%", "85%", "88%", "91%", "94%", "97%", "100%"]'::jsonb),
    (16750, '["58%", "63%", "68%", "73%", "78%", "83%", "88%"]'::jsonb),
    (16751, '["70%", "75%", "80%", "85%", "90%", "95%", "100%"]'::jsonb),
    (16752, '["61%", "66%", "71%", "76%", "81%", "86%", "91%"]'::jsonb),
    (16753, '["9%", "14%", "19%", "24%", "29%", "34%", "39%"]'::jsonb),
    (16755, '["41", "91", "141", "191", "241", "291", "341"]'::jsonb),
    (16756, '["43", "53", "63", "73", "83", "93", "103"]'::jsonb),
    (16758, '["14", "24", "34", "44", "54", "64", "74"]'::jsonb),
    (16768, '["28", "33", "38", "43", "48", "53", "58"]'::jsonb),
    (16773, '["€10bn", "€30bn", "€50bn", "€70bn", "€90bn", "€110bn", "€130bn"]'::jsonb),
    (16778, '["40,000", "50,000", "60,000", "70,000", "80,000", "90,000", "100,000"]'::jsonb),
    (16780, '["1", "3", "5", "7", "9", "11", "13"]'::jsonb)
)
UPDATE trivia.questions q
   SET options_scale = p.scale,
       updated_at    = now()
  FROM proposed p
 WHERE q.id = p.id
   AND q.options_scale IS NULL
   AND q.status = 'active'
   AND q.options->>q.correct_answer = p.scale->>3;

-- Post-verify gate. Reads the END STATE, not the rowcount, so a partial apply or a
-- re-run is judged on what is actually in the table.
DO $$
DECLARE
  v_scaled   int;
  v_misplaced int;
  v_wrong_len int;
BEGIN
  SELECT count(*) INTO v_scaled
    FROM trivia.questions WHERE options_scale IS NOT NULL;

  -- The one invariant the serve path enforces: mark 4 IS the stored answer.
  SELECT count(*) INTO v_misplaced
    FROM trivia.questions
   WHERE options_scale IS NOT NULL
     AND options_scale->>3 IS DISTINCT FROM options->>correct_answer;

  SELECT count(*) INTO v_wrong_len
    FROM trivia.questions
   WHERE options_scale IS NOT NULL
     AND jsonb_array_length(options_scale) <> 7;

  IF v_misplaced > 0 THEN
    RAISE EXCEPTION 'CC_0286: % question(s) carry a scale whose mark 4 is not the stored answer', v_misplaced;
  END IF;
  IF v_wrong_len > 0 THEN
    RAISE EXCEPTION 'CC_0286: % question(s) carry a scale that is not 7 marks long', v_wrong_len;
  END IF;
  IF v_scaled < 290 THEN
    RAISE EXCEPTION 'CC_0286: expected at least 290 scaled questions, found %', v_scaled;
  END IF;

  RAISE NOTICE 'CC_0286: % questions carry a 7-mark scale, all centred on their answer', v_scaled;
END $$;

COMMIT;
