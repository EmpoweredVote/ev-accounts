-- CA_0168_la_unified_a2_tenure_dates.sql
-- Give the 26 real FORMER members that CA_0156 verified (class A2) their sourced tenure -- start,
-- start_precision, end, how_started, how_ended -- and put five of them on the seat they really held.
-- Also: Glendale's Telly Tse / Neda Farid seating date (2024 'year' -> 2024-04-09), two no-evidence
-- (class B) rows whose arbitrary seat slot has to move out of the way, and LaConte's second stint.
--
-- No migration runner exists; applied by hand over a `postgres` connection (psql + DATABASE_URL). Pure
-- DML. Operator approval: Chris Andrews, 2026-09-23 ("House convention", CA_0156 limits follow-up).
--
-- ---------------------------------------------------------------------------------------------------
-- A. WHY
-- ---------------------------------------------------------------------------------------------------
-- CA_0156 kept each A2 member's closed term but left its dates as CA_0143-0154 wrote them: term_start
-- NULL ('unknown') and term_end = the day before whichever successor the generic seat was paired with.
-- Those ends were modelling artefacts, often years wrong (Alissa Roston left in 2007; her row said 2024),
-- and five rows sat on a seat the person never held (Glendale's Freemon on TA E and Nahabedian on TA B,
-- Pasadena's Torres on District 2, Downey's LaPlante on TA5, and Burbank's Ferguson on a TA4 slot whose
-- successor was seated two years before he resigned).
--
-- ---------------------------------------------------------------------------------------------------
-- B. EVIDENCE -- fetched and read 2026-09-23 (URLs in each term's source)
-- ---------------------------------------------------------------------------------------------------
-- Smart Voter race pages 1999-2015 via Wayback; district minutes (oaths, resignations); district past-
-- member lists (GUSD, BUSD); Ballotpedia; local papers (SGV Tribune, Burbank Leader, Claremont Courier,
-- Culver City Crossroads, The Acorn, Downey Patriot, Daily Breeze, Altadena Now, Crescenta Valley Weekly,
-- Temple City Voice, Patch, Santa Monica Daily Press / Mirror). Every date below has a fetched source.
--
-- ---------------------------------------------------------------------------------------------------
-- C. DATE CONVENTIONS (operator ruling "house convention", 2026-09-23)
-- ---------------------------------------------------------------------------------------------------
--   * Start known to the day -> precision 'day'; month -> YYYY-MM-01 'month'; year only -> YYYY-01-01
--     'year' (CLAUDE.md). Ed Gililland's start was not found -> stays NULL / 'unknown'.
--   * office_terms has NO end_precision column (see 1467, 1798, 1814, CC_0009). An end known only to
--     the month or year of a November election is written as YYYY-11-30 -- the day before the December
--     organizational meeting, the same boundary CA_0143-0154 used for successors seated 'December,
--     precision month'. Each such row's source says the end is a month/year reading.
--   * An end is never allowed to overlap the recorded successor: where the real last meeting falls after
--     a successor recorded at month precision (Foster 2022-12-15, Cahalan 2024-12-09) or is the
--     successor's swearing day (Torres 2020-12-07, Freemon/Nahabedian 2024-04-09, Sahakian 2026-07-14),
--     the end is the day before and the real date is in the source.
--   * The seat stays where it was unless the real seat is FREE for the span. Pre-conversion service on
--     boards that now elect by trustee area was at-large; such rows stay on the slot CA_0143-0154 gave
--     them and the source says "seat was at-large".
--
-- ---------------------------------------------------------------------------------------------------
-- D. SEAT MOVES
-- ---------------------------------------------------------------------------------------------------
--   Freemon    Glendale TA E -> TA A (RR/CC Mar 2020 'Trustee Area A'; TA A had no predecessor row)
--   Nahabedian Glendale TA B -> TA E (RR/CC Mar 2020 'Trustee Area E'; TA B was Ingrid Gunnell 2022-26)
--   Torres     Pasadena D2 -> D6 (Ballotpedia; D6 had no predecessor row)
--   LaPlante   Downey TA5 -> TA4 (Downey Patriot: 41 years in TA4). TA4's slot held Nila Aikin, a class-B
--              (no evidence) row whose seat pairing was arbitrary -> Aikin takes the TA5 slot, end = day
--              before TA5's successor (2022-12-12), the same "not researched" convention she had.
--   Ferguson   Burbank TA4 -> TA2 slot (at-large member, resigned 2024-08-01; TA4 successor Kamkar was
--              seated 2022-12-01, TA2's in Dec 2024). TA2's slot held Adam Schur (class B) -> Schur takes
--              the TA4 slot, end 2022-11-30.
--   The two swaps use a transient end on the B row inside this transaction (the exclusion constraint is
--   checked per row); only the final values commit.
--   LaConte    second stint INSERTED on Claremont TA4: appointed 2023-01-18, removed 2023-03-01 when a
--              petition forced the July 2023 special election -- inside the gap between Llanusa
--              (resigned 2022-12-10) and McDonald (2023-08-01).
--   Tse, Farid (current holders, Glendale TA A / TA E) start 2024-01-01 'year' -> 2024-04-09 'day'.
--
-- ---------------------------------------------------------------------------------------------------
-- E. ROLLBACK
-- ---------------------------------------------------------------------------------------------------
--   Every changed row keeps its old values recoverable: the pre-image is the _t / constants below
--   (cur_office, cur_end; start NULL/'unknown', how_started NULL except Tse/Farid 'elected'), and each
--   source gained a ' | CA_0168 ...' suffix that can be stripped. Delete the LaConte stint-2 row by
--   (politician 19db4957..., office a63f5e88..., term_start 2023-01-18).
--
-- IDEMPOTENT: every step is guarded on the pre-image; a re-run is a no-op and the post gate still passes.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _t (term_id uuid PRIMARY KEY, politician_id uuid, full_name text, cur_office uuid, cur_end date,
                      tgt_office uuid, new_start date, prec text, new_end date, how_started text, how_ended text,
                      src text) ON COMMIT DROP;
INSERT INTO _t VALUES
  ('cd44137e-c2e8-46e8-ac2d-1ea08fe9c49a'::uuid, '90b0b8a1-c700-4786-84d6-33ddb55f5b6f'::uuid, 'Ken Tang', 'a41d946e-010d-4fab-8cf3-ff24e7e927c9'::uuid, '2025-08-05'::date, NULL::uuid, '2020-12-15'::date, 'day', '2025-08-05'::date, 'elected', 'resigned', ' | CA_0168 (2026-09-23): tenure sourced -- oath 2020-12-15; resignation effective 2025-08-06, last day 2025-08-05. Sources: https://alhambra.agendaonline.net/public/Meeting/Attachments/DisplayAttachment.aspx?AttachmentID=1261902&IsArchive=0; https://www.whittierdailynews.com/2020/11/04/who-are-the-san-gabriel-valley-school-board-members-who-lost-tuesday-and-who-are-the-new-faces/; https://www.ausd.us/apps/news/article/2107680'),
  ('627c97a6-a8af-4584-bad6-09819db35833'::uuid, 'b545317b-d799-4ca0-ae8d-f9a93c35729f'::uuid, 'Rosemary Garcia', '12664b50-03e4-4674-8039-91842da9dd42'::uuid, '2022-12-12'::date, NULL::uuid, '1984-01-01'::date, 'year', '2013-11-30'::date, 'appointed', 'retired', ' | CA_0168 (2026-09-23): tenure sourced -- start year derived from ''the past 29 years'' (SGV Tribune 2013-10-30, ''appointed ... mid-1980s''); last meeting 2013-11-19, left at the Dec 2013 reorganization (2013-11-30 = house day-before-December convention); seat was at-large. Sources: https://www.sgvtribune.com/2013/10/30/azusa-school-board-president-stepping-down-after-29-years/; https://www.sgvtribune.com/2013/10/30/azusa-school-board-president-stepping-down-after-29-years/; https://www.sgvtribune.com/2013/10/30/azusa-school-board-president-stepping-down-after-29-years/'),
  ('30db2931-c5c2-4ee4-9867-e9381ec2e414'::uuid, '09cd1f70-2a45-4393-ac52-33f55091ffd4'::uuid, 'Cristina Lucero', '0c40cf49-6d98-4255-9af7-132491047e9f'::uuid, '2024-11-30'::date, NULL::uuid, '2007-01-01'::date, 'year', '2024-11-30'::date, 'elected', 'defeated', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 2007 (year only); one continuous stint; defeated Nov 2024, left Dec 2024 (2024-11-30 = day before successor). Sources: http://web.archive.org/web/2008/http://www.smartvoter.org/2007/11/06/ca/la/race/01318000/; https://www.bpusd.net/apps/news/article/1358664; https://www.whittierdailynews.com/2020/11/04/who-are-the-san-gabriel-valley-school-board-members-who-lost-tuesday-and-who-are-the-new-faces/'),
  ('a310c80a-0f3e-43d9-a7e6-7cafcb1fdb62'::uuid, '84a73092-e2e4-4030-8b05-2113ec404df1'::uuid, 'Alissa Roston', '527e2f3c-2e4c-452e-a925-ab05c624ba18'::uuid, '2022-11-30'::date, NULL::uuid, '1999-01-01'::date, 'year', '2007-11-30'::date, 'elected', 'defeated', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 1999, re-elected 2003, defeated Nov 2007 (Smart Voter); months not sourced; end = house day-before-December convention. Sources: http://web.archive.org/web/2000/http://www.smartvoter.org/1999nov/ca/la/race/25/; http://web.archive.org/web/20040301/http://www.smartvoter.org/2003/11/04/ca/la/race/01324000/; http://web.archive.org/web/2008/http://www.smartvoter.org/2007/11/06/ca/la/race/01324000/'),
  ('a35fa7d7-bb9a-44eb-ba1a-9df2d2901b9a'::uuid, '35d08038-550b-4f13-b564-dcfe48b3dfa6'::uuid, 'Brian Goldberg', '5c8b8683-8614-4484-9bfe-7d0b39ea6fd2'::uuid, '2024-11-30'::date, NULL::uuid, '2007-01-01'::date, 'year', '2015-11-30'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 2007 and 2011; did not seek re-election 2015; end = house day-before-December convention. Sources: http://web.archive.org/web/2008/http://www.smartvoter.org/2007/11/06/ca/la/race/01324000/; https://bhweekly.com/issues/pdf/2011_633.pdf; https://mynewsla.com/education/2015/11/04/2-challengers-1-incumbent-win-beverly-hills-school-board-seats/'),
  ('78eeeb0c-964a-4c29-b633-31f3241c80e0'::uuid, '8bc76d78-5793-4ab8-ba47-ddeefeb33413'::uuid, 'Noah Margo', '51265d6b-e523-417f-9ec7-965b5effcb8c'::uuid, '2024-11-30'::date, NULL::uuid, '2011-01-01'::date, 'year', '2024-11-30'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- first elected 2011 (write-in); re-elected 2015, 2020; did not run 2024. Sources: https://bhweekly.com/issues/pdf/2011_633.pdf; https://beverlyhillsstandard.com/election-center/bhusd-board-of-education-2015; https://beverlyhillsstandard.com/election-center/bhusd-board-of-education-2020/candidates/noah-margo'),
  ('c7514695-c3e9-4ff0-a54c-7880d3be46d1'::uuid, '8d34fe9c-7363-4ec3-9587-be656b7ad8a1'::uuid, 'Roberta Reynolds', '450d59a4-f39c-49f0-ba79-7f3bdb76c49e'::uuid, '2024-11-30'::date, NULL::uuid, '2007-01-01'::date, 'year', '2020-12-17'::date, 'elected', 'defeated', ' | CA_0168 (2026-09-23): tenure sourced -- first elected 2007 (BUSD list 2007-2020); defeated Nov 2020, left 2020-12-17; seat was at-large. Sources: https://ballotpedia.org/Roberta_Grande_Reynolds; https://resources.finalsite.net/images/v1759946956/burbankusdorg/gw1wplxmsej0hhysee20/BoardMembershipListArchiveWEBSITE_1.pdf; https://myburbank.com/school-board-candidate-profile-roberta-reynolds/'),
  ('d376b6dc-98b1-4f36-ba3f-86ea6f2e0546'::uuid, '31996159-ce51-4ac7-971f-bcd78a467499'::uuid, 'Steve Ferguson', 'dc05ab2d-3536-4c10-ac39-3fb16138a833'::uuid, '2022-11-30'::date, '745badc0-f167-4a11-a6fc-9e5780fb66ae'::uuid, '2015-05-01'::date, 'day', '2024-08-01'::date, 'elected', 'resigned', ' | CA_0168 (2026-09-23): tenure sourced -- sworn 2015-05-01; re-elected 2020; resigned 2024-08-01; seat was at-large -- moved to the TA2 slot (successor seated Dec 2024) because his real tenure overlaps TA4 successor Kamkar (2022-12-01). Sources: https://www.latimes.com/socal/burbank-leader/the818now/tn-blr-reynolds-ferguson-elected-to-school-board-20150225-story.html; https://www.latimes.com/socal/burbank-leader/news/tn-blr-city-swears-in-council-school-board-members-20150501-story.html; https://myburbank.com/busd-board-member-steve-ferguson-turns-in-letter-of-resignation/'),
  ('7dbc6373-396d-4a93-a65d-54b1ab4d8b82'::uuid, '7a52ea32-cd3d-4853-ba1e-7c51087d998f'::uuid, 'Steven Llanusa', 'a63f5e88-ae36-40c1-a0b6-03360c5007c0'::uuid, '2023-07-31'::date, NULL::uuid, '2005-01-01'::date, 'year', '2022-12-10'::date, 'elected', 'resigned', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 2005 (year only); resigned 2022-12-10, a month after re-election in TA4. Sources: http://web.archive.org/web/20060301/http://www.smartvoter.org/2005/11/08/ca/la/race/053/; https://claremontcourier.com/schools/embattled-school-board-president-resigns-71426/; https://claremontcourier.com/schools/embattled-school-board-president-resigns-71426/'),
  ('137db5ed-90f0-4ec5-8343-43fa80fcca7b'::uuid, '19db4957-f8af-4e9f-b3d4-b9374e4fd37a'::uuid, 'Hilary LaConte', 'e1f15d6b-8468-462c-802d-1f141064f624'::uuid, '2024-11-30'::date, NULL::uuid, '2007-01-01'::date, 'year', '2020-12-17'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- stint 1: elected Nov 2007, did not run 2020, left 2020-12-17 (at-large seat). Stint 2 (TA4 appointment 2023-01-18 to 2023-03-01) is inserted as its own row. Sources: http://web.archive.org/web/2008/http://www.smartvoter.org/2007/11/06/ca/la/race/01350000/; https://www.dailybulletin.com/2023/01/20/claremont-unified-school-board-fills-seat-vacated-by-embattled-former-president/; https://ccourier.em03.enthusiastinc.net/schools/t39572-archer-28274/'),
  ('ce261c21-c16d-44b8-8e0d-f89e6887217c'::uuid, '5501c147-5dad-48d5-845c-b6b91e8860a9'::uuid, 'Kathy Paspalis', 'f7da018f-c43b-4a9d-8121-5be11673e73b'::uuid, '2024-11-30'::date, NULL::uuid, '2009-12-01'::date, 'day', '2018-11-30'::date, 'elected', 'retired', ' | CA_0168 (2026-09-23): tenure sourced -- CCUSD terms run 12/1-11/30 (oath 2009-12-08, final meeting 2018-11-27). Sources: http://web.archive.org/web/20100301/http://www.smartvoter.org/2009/11/03/ca/la/race/01365000/; https://www.ccusd.org/ourpages/boe/996%202009-10/002%20Minutes/2009-12-08.pdf; https://culvercitycrossroads.com/2018/11/30/paspalis-gets-a-warm-farewell-from-the-school-board-and-the-district/'),
  ('a4d082fc-fe22-46ce-8df4-b752c94ed18b'::uuid, '599376b6-bdfa-4b76-837f-dd2230a546ad'::uuid, 'Scott Zeidman', 'f53bee9a-70af-457c-b706-1b508abc022a'::uuid, '2024-11-30'::date, NULL::uuid, '2007-12-01'::date, 'day', '2011-11-30'::date, 'elected', 'defeated', ' | CA_0168 (2026-09-23): tenure sourced -- CCUSD ''Term of Office: 12/1/07 - 11/30/11''; one term only. Sources: http://web.archive.org/web/2008/http://www.smartvoter.org/2007/11/06/ca/la/race/01365000/; http://web.archive.org/web/20040301/http://www.smartvoter.org/2003/11/04/ca/la/race/01365000/; https://www.ccusd.org/ourpages/boe/998%202007-08/002%20Minutes/2007-12-11.pdf'),
  ('b4062cfe-2332-4ae2-8751-328f130cb962'::uuid, 'b0ad0f94-2ec8-499c-be99-c39082da8f4c'::uuid, 'Donald LaPlante', 'e88ca57e-d1ce-4f3b-a84b-43b2dc979910'::uuid, '2022-12-12'::date, '85327482-42a3-4867-82af-097031da25a6'::uuid, '1979-01-01'::date, 'year', '2020-11-30'::date, 'elected', 'retired', ' | CA_0168 (2026-09-23): tenure sourced -- elected 1979, served Trustee Area 4 continuously 41 years, retired at the Dec 2020 reorganization (day not sourced; house convention); moved from TA5 to his real seat TA4. Sources: https://www.thedowneypatriot.com/articles/downey-laplante-retires-from-downey-school-board; https://www.thedowneypatriot.com/articles/downey-laplante-retires-from-downey-school-board; https://docslib.org/doc/12789770/donald-laplante-calls-it-a-career-reason-elected-41-years-ago-to-the-downey-board-of-friday-for-education-donald-laplant-71-retired-this-week'),
  ('8df2819c-e3ce-407e-8e92-72724789562e'::uuid, '4a484a17-5426-403c-8c51-0b7e387a07b1'::uuid, 'Robin Funk', 'cb8276fc-8cfd-42d6-896c-98423ffd3ffa'::uuid, '2024-11-30'::date, NULL::uuid, '2005-01-01'::date, 'year', '2013-11-30'::date, 'elected', 'defeated', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 2005, re-elected 2009, defeated Nov 2013; end = house day-before-December convention. Sources: http://web.archive.org/web/20060301/http://www.smartvoter.org/2005/11/08/ca/la/race/070/; http://web.archive.org/web/20100301/http://www.smartvoter.org/2009/11/03/ca/la/race/01402000/; http://www.heraldpublications.com/herald/sites/default/files/publications/pdf-files/Herald%2011_07_13rf.pdf'),
  ('5877a644-4cdd-469c-8140-fc29b14ffe68'::uuid, 'c096896b-72e7-49e3-87ea-ddc90888b996'::uuid, 'Jennifer Freemon', 'd399c370-361c-4402-919d-7e6150949a3c'::uuid, '2023-12-31'::date, '1d696a35-2bac-4571-bc98-ccba92a8c1b1'::uuid, '2015-04-27'::date, 'day', '2024-04-08'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- sworn 2015-04-27; Trustee Area A (RR/CC Mar 2020); successor Telly Tse sworn 2024-04-09 (Crescenta Valley Weekly 2024-04-18); moved from TA E to her real seat TA A. Sources: https://ballotpedia.org/Jennifer_Freemon; https://www.latimes.com/socal/glendale-news-press/news/tn-gnp-glendale-unified-school-board-members-freemon-nahabedian-sworn-in-20150428-story.html; https://ballotpedia.org/Glendale_Unified_School_District,_California,_elections'),
  ('1aa4b304-e0d3-470f-a022-a4b345e912d8'::uuid, '9b362b24-72a3-4c81-8e38-7bd476eba72e'::uuid, 'Nayiri Nahabedian', '4ddf4921-d88e-4a0a-b6c0-026ed7274084'::uuid, '2026-07-13'::date, 'd399c370-361c-4402-919d-7e6150949a3c'::uuid, '2007-01-01'::date, 'year', '2024-04-08'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- first elected 2007 (GUSD list 2007-2024); Trustee Area E (RR/CC Mar 2020); successor Neda Farid sworn 2024-04-09; moved from TA B (never her seat; TA B was Ingrid Gunnell 2022-2026) to TA E. Sources: https://www.latimes.com/socal/glendale-news-press/news/tn-gnp-glendale-unified-school-board-members-freemon-nahabedian-sworn-in-20150428-story.html; https://www.gusd.net/board-members-past-and-present; https://ballotpedia.org/Glendale_Unified_School_District,_California,_elections'),
  ('a1cb1f30-6e39-4527-b6e8-48ec2fa24833'::uuid, '0e59e9c1-a019-4b2a-aa02-b97f17a6d761'::uuid, 'Shant Sahakian', '92a76fce-d236-4c47-ade9-d324cace7242'::uuid, '2026-07-13'::date, NULL::uuid, '2017-05-01'::date, 'day', '2026-07-13'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- elected TA D 2017-04-04, sworn 2017-05-01; successor sworn 2026-07-14 (end kept as day before). Sources: https://ballotpedia.org/Shant_Sahakian; https://www.latimes.com/socal/glendale-news-press/news/tn-gnp-glendale-organization-2017-0503-story.html; https://ballotpedia.org/Glendale_Unified_School_District,_California,_elections'),
  ('05610aec-fb48-4838-8dbb-b3e4f97b9300'::uuid, '695ab650-58df-43b8-b8c9-b075e1e519fd'::uuid, 'Kate Vadehra', 'f1cccaec-0c97-4717-8c9d-50fc4559df80'::uuid, '2024-11-30'::date, NULL::uuid, '2020-12-15'::date, 'day', '2022-11-26'::date, 'elected', 'died', ' | CA_0168 (2026-09-23): tenure sourced -- oath 2020-12-15 (LVUSD minutes); died 2022-11-26 (The Acorn). Sources: https://resources.finalsite.net/images/v1676360560/lvusdorg/jm9upjwdhcbhfvwvdsp6/2020-12-15_Board_Meeting_Minutes.pdf; https://www.theacorn.com/articles/community-mourns-death-of-school-boards-vadehra/'),
  ('2bc3e34f-0aec-485b-992f-efd46a92b35a'::uuid, 'df7e4a1a-14d1-4044-9f81-2936486b3d4a'::uuid, 'Jennifer Cochran', 'f541b163-0fc3-466e-8ac5-6b605b4ece51'::uuid, '2024-11-30'::date, NULL::uuid, '2013-12-01'::date, 'month', '2022-11-30'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 2013, re-elected 2018, did not run 2022; end = house day-before-December convention. Sources: https://patch.com/california/manhattanbeach/qa-with-school-board-candidate-jennifer-cochran; https://patch.com/california/manhattanbeach/vote-tally-signals-3-winners-for-manhattan-beach-school-board-seats; https://patch.com/california/manhattanbeach/vote-tally-signals-3-winners-for-manhattan-beach-school-board-seats'),
  ('f8a5278c-3c66-4797-b609-9d67f46555cd'::uuid, 'cca09d1e-6e2b-427c-add8-5eeea52a9633'::uuid, 'Ed Gililland', '1da68825-9578-495a-bad5-0708dee6cbab'::uuid, '2024-12-17'::date, NULL::uuid, NULL::date, 'unknown', '2020-11-30'::date, NULL, 'retired', ' | CA_0168 (2026-09-23): tenure sourced -- start not found (probably appointed c.2005-06; incumbent by 2007); did not run 2020, left at the Dec 2020 reorganization; seat was at-large. Sources: http://web.archive.org/web/20040301/http://www.smartvoter.org/2003/11/04/ca/la/race/01463000/; http://web.archive.org/web/20080301/http://www.smartvoter.org/2007/11/06/ca/la/race/01463000/; https://www.monrovianow.com/2020/08/school-board-member-ed-gililland-wont.html'),
  ('06572ad3-a6a4-4026-8e52-feeca8b64e3a'::uuid, '68eea13f-e95d-468b-bc43-aa83c19a37da'::uuid, 'Lawrence Torres', '1ba9ac86-b841-44a0-90a7-0219308cdc57'::uuid, '2024-11-30'::date, '574acfbe-fa49-44e2-ace5-9b167cf85b6c'::uuid, '2015-05-04'::date, 'day', '2020-12-06'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- sworn 2015-05-04, District 6; did not run 2020; successor sworn 2020-12-07; moved from District 2 to his real seat District 6. Sources: https://ballotpedia.org/Lawrence_Torres; https://www.altadena-now.com/main/education/three-school-board-members-take-office-dr-elizabeth-pomeroy-elected-president/; https://www.pasadenastarnews.com/2020/10/06/2020-elections-pasadena-unifieds-district-6-candidates/'),
  ('2e8e859b-8a5f-4e72-8dd6-36a2a9bb9759'::uuid, '7dae12c6-d2b7-45a4-af3f-0003e13fbacf'::uuid, 'Pat Cahalan', 'bceb21c3-9eb0-42e6-89bd-329a5fd56343'::uuid, '2024-11-30'::date, NULL::uuid, '2015-05-04'::date, 'day', '2024-11-30'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- sworn 2015-05-04 as a new member (not an appointee); re-elected 2020; last meeting 2024-12-09 -- end kept at 2024-11-30 because successor Scott Harden is recorded from 2024-12-01 (month precision). Sources: https://ballotpedia.org/Pasadena_Unified_School_District_elections_(2015); https://www.altadena-now.com/main/education/three-school-board-members-take-office-dr-elizabeth-pomeroy-elected-president/; https://www.pasadenastarnews.com/2020/11/04/election-2020-cahalan-lee-fredericks-and-measure-o-are-likely-winners-in-pasadena-unified/'),
  ('c7dca23e-2187-407c-8431-ac253b19f77f'::uuid, '592a2ac4-686f-47d5-8668-269e21ad1924'::uuid, 'Craig Foster', '9c961024-0c4b-4864-b4f8-f2a77258fe40'::uuid, '2022-11-30'::date, NULL::uuid, '2014-12-01'::date, 'month', '2022-11-30'::date, 'elected', 'term_expired', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 2014, re-elected 2018, did not seek a third term; last meeting 2022-12-15 -- end kept at 2022-11-30 because successor is recorded from 2022-12-01 (month precision). Sources: https://smmirror.com/elected-smmusd-members-look-to-breathe-new-life-into-board/; https://smdp.com/foster-will-not-seek-third-term-on-smmusd-board-2/; https://resources.finalsite.net/images/v1746642376/smmusdorg/jbhmzfe5zht1z4rsdb3a/pc-minutes121422.pdf'),
  ('4a47e141-8475-43dd-8442-1f4398613521'::uuid, '98043faa-6ece-4c24-888f-5d556c04ef98'::uuid, 'Kenneth Knollenberg', 'cac7da84-c9ef-4199-b005-d2424549bfad'::uuid, '2022-12-13'::date, NULL::uuid, '2011-12-07'::date, 'day', '2020-11-30'::date, 'elected', 'defeated', ' | CA_0168 (2026-09-23): tenure sourced -- sworn 2011-12-07; re-elected 2015; defeated Nov 2020 (day not sourced; house convention); seat was at-large. Sources: http://web.archive.org/web/20100301/http://www.smartvoter.org/2009/11/03/ca/la/race/01544000/; https://templecityvoice.wordpress.com/2011/12/20/knollenberg-tiet-and-ridley-sworn-into-office/; https://www.whittierdailynews.com/2020/11/04/who-are-the-san-gabriel-valley-school-board-members-who-lost-tuesday-and-who-are-the-new-faces/'),
  ('16d69f10-23df-4de2-8530-02f5a3beb02a'::uuid, '22dfaff5-6d3d-4bba-abc3-6c7500e42ded'::uuid, 'Don Lee', '16d8f80c-666e-459f-9a12-3e2bd7572c87'::uuid, '2024-12-15'::date, NULL::uuid, '2007-01-01'::date, 'year', '2020-12-14'::date, 'elected', 'retired', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 2007, re-elected 2011, 2015; retired 2020-12-14; seat was at-large. Sources: http://web.archive.org/web/2008/http://www.smartvoter.org/2007/11/06/ca/la/race/01547000/; https://ballotpedia.org/Don_Lee_(California); https://www.dailybreeze.com/2020/09/25/four-candidates-vying-for-two-seats-on-torrance-unified-school-district-board/'),
  ('95f7c59b-4643-4bc9-8225-e00004284c11'::uuid, '9e7f9ff8-24d7-4ab3-b09b-c9adf823a602'::uuid, 'Terry Ragins', 'cf414a7e-6c18-4697-8c9d-67f18f8bfb39'::uuid, '2022-11-30'::date, NULL::uuid, '2003-01-01'::date, 'year', '2020-12-14'::date, 'elected', 'retired', ' | CA_0168 (2026-09-23): tenure sourced -- elected Nov 2003, re-elected 2007, 2011, 2015; retired 2020-12-14; seat was at-large. Sources: http://web.archive.org/web/20040301/http://www.smartvoter.org/2003/11/04/ca/la/race/01547000/; https://ballotpedia.org/Terry_Ragins; https://www.dailybreeze.com/2020/09/25/four-candidates-vying-for-two-seats-on-torrance-unified-school-district-board/');

CREATE TEMP TABLE _baseline ON COMMIT DROP AS
  SELECT (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms;

-- ─── PRE-FLIGHT ─────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  IF (SELECT count(*) FROM _t) <> 26 THEN RAISE EXCEPTION 'PRE: expected 26 A2 terms'; END IF;

  -- every A2 term is still exactly as CA_0156 left it, or exactly as this file leaves it (re-run)
  SELECT count(*) INTO v_n FROM _t JOIN essentials.office_terms ot ON ot.id = _t.term_id AND ot.politician_id = _t.politician_id
   WHERE (ot.office_id = _t.cur_office AND ot.term_end = _t.cur_end AND ot.term_start IS NULL AND ot.source LIKE '%verified CA_0156%')
      OR (ot.office_id = COALESCE(_t.tgt_office, _t.cur_office) AND ot.term_end = _t.new_end
          AND ot.term_start IS NOT DISTINCT FROM _t.new_start AND ot.source LIKE '%CA_0168%');
  IF v_n <> 26 THEN RAISE EXCEPTION 'PRE: only % of 26 A2 terms are in a known state -- someone changed them', v_n; END IF;

  -- the A2 people are still the active, non-incumbent rows CA_0156 left
  SELECT count(*) INTO v_n FROM _t JOIN essentials.politicians p ON p.id = _t.politician_id
   WHERE p.is_active AND NOT p.is_incumbent;
  IF v_n <> 26 THEN RAISE EXCEPTION 'PRE: % of 26 A2 politicians still active + non-incumbent', v_n; END IF;

  -- in-place rows only ever SHRINK (a later end would collide with the recorded successor)
  SELECT count(*) INTO v_n FROM _t WHERE tgt_office IS NULL AND new_end > cur_end;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % in-place rows would grow', v_n; END IF;

  -- the two B rows that give up their slot, and the two Glendale holders
  SELECT count(*) INTO v_n FROM essentials.office_terms ot
   WHERE (ot.id = '23e1ce87-3517-43d6-a5ee-78fe16452640' AND ot.politician_id = '9cab21a6-f107-4789-bcd1-b5b1e6cd7a15' AND ot.term_start IS NULL
          AND ((ot.office_id = '745badc0-f167-4a11-a6fc-9e5780fb66ae' AND ot.term_end = '2024-11-30')
            OR (ot.office_id = 'dc05ab2d-3536-4c10-ac39-3fb16138a833' AND ot.term_end = '2022-11-30')))
      OR (ot.id = '4bb2d016-36ff-41af-a307-3c46fe35b978' AND ot.politician_id = '16f0ef7c-ba0b-4bc4-83ee-a7f0a223282a' AND ot.term_start IS NULL
          AND ((ot.office_id = '85327482-42a3-4867-82af-097031da25a6' AND ot.term_end = '2024-12-15')
            OR (ot.office_id = 'e88ca57e-d1ce-4f3b-a84b-43b2dc979910' AND ot.term_end = '2022-12-12')))
      OR (ot.id IN ('d91f7c74-02c1-4185-858e-3286a5b46c7c','b54e51ac-019b-4fa8-945c-7b3fc64e6dea') AND ot.term_end IS NULL
          AND ot.term_start IN ('2024-01-01','2024-04-09'));
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: Schur/Aikin/Tse/Farid rows not in a known state (%/4)', v_n; END IF;

  -- target seats are free for the incoming spans (apart from the rows this file moves)
  SELECT count(*) INTO v_n FROM _t JOIN essentials.office_terms s ON s.office_id = _t.tgt_office AND s.id <> _t.term_id
   WHERE _t.tgt_office IS NOT NULL
     AND s.id NOT IN ('23e1ce87-3517-43d6-a5ee-78fe16452640','4bb2d016-36ff-41af-a307-3c46fe35b978',
                      'd91f7c74-02c1-4185-858e-3286a5b46c7c','b54e51ac-019b-4fa8-945c-7b3fc64e6dea')
     AND s.id NOT IN (SELECT term_id FROM _t)
     AND daterange(s.term_start, s.term_end, '[]') && daterange(_t.new_start, _t.new_end, '[]');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % target-seat collisions', v_n; END IF;
END $$;

-- ─── 1. Glendale: the April 9 2024 seating (frees TA A / TA E for the real predecessors) ────────────
UPDATE essentials.office_terms
   SET term_start = '2024-04-09', start_precision = 'day',
       source = source || ' | CA_0168 (2026-09-23): start refined from 2024 (year) to 2024-04-09 -- sworn in at the '
                || 'April 9 2024 meeting "to fill the seats vacated by Nahabedian and Freemon" '
                || '(crescentavalleyweekly.com/news/04/18/2024/new-members-sworn-in-to-gusd-board-of-education/)'
 WHERE id IN ('d91f7c74-02c1-4185-858e-3286a5b46c7c','b54e51ac-019b-4fa8-945c-7b3fc64e6dea')
   AND term_start = '2024-01-01' AND start_precision = 'year';

-- ─── 2. In-place rows (every one shrinks) ───────────────────────────────────────────────────────────
UPDATE essentials.office_terms ot
   SET term_start = _t.new_start, start_precision = _t.prec, term_end = _t.new_end,
       how_started = _t.how_started, how_ended = _t.how_ended, source = ot.source || _t.src
  FROM _t
 WHERE ot.id = _t.term_id AND _t.tgt_office IS NULL AND ot.source NOT LIKE '%CA_0168%';

-- ─── 3. Seat moves ─────────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  -- Burbank: Ferguson TA4 -> TA2, Schur TA2 -> TA4
  IF EXISTS (SELECT 1 FROM essentials.office_terms WHERE id = 'd376b6dc-98b1-4f36-ba3f-86ea6f2e0546'
                                                     AND office_id = 'dc05ab2d-3536-4c10-ac39-3fb16138a833') THEN
    UPDATE essentials.office_terms SET term_end = '2015-04-30'            -- transient, overwritten below
     WHERE id = '23e1ce87-3517-43d6-a5ee-78fe16452640';
    UPDATE essentials.office_terms ot
       SET office_id = _t.tgt_office, term_start = _t.new_start, start_precision = _t.prec, term_end = _t.new_end,
           how_started = _t.how_started, how_ended = _t.how_ended, source = ot.source || _t.src
      FROM _t WHERE ot.id = _t.term_id AND _t.term_id = 'd376b6dc-98b1-4f36-ba3f-86ea6f2e0546';
    UPDATE essentials.office_terms
       SET office_id = 'dc05ab2d-3536-4c10-ac39-3fb16138a833', term_end = '2022-11-30',
           source = source || ' | CA_0168 (2026-09-23): seat slot moved TA2 -> TA4 after Steve Ferguson''s real tenure '
                    || '(2015-05-01 to 2024-08-01) was sourced for the TA2 slot; end = day before TA4''s successor, NOT '
                    || 'researched (same convention as CA_0143-0154)'
     WHERE id = '23e1ce87-3517-43d6-a5ee-78fe16452640';
  END IF;

  -- Downey: LaPlante TA5 -> TA4, Aikin TA4 -> TA5
  IF EXISTS (SELECT 1 FROM essentials.office_terms WHERE id = 'b4062cfe-2332-4ae2-8751-328f130cb962'
                                                     AND office_id = 'e88ca57e-d1ce-4f3b-a84b-43b2dc979910') THEN
    UPDATE essentials.office_terms SET term_end = '1978-12-31'            -- transient, overwritten below
     WHERE id = '4bb2d016-36ff-41af-a307-3c46fe35b978';
    UPDATE essentials.office_terms ot
       SET office_id = _t.tgt_office, term_start = _t.new_start, start_precision = _t.prec, term_end = _t.new_end,
           how_started = _t.how_started, how_ended = _t.how_ended, source = ot.source || _t.src
      FROM _t WHERE ot.id = _t.term_id AND _t.term_id = 'b4062cfe-2332-4ae2-8751-328f130cb962';
    UPDATE essentials.office_terms
       SET office_id = 'e88ca57e-d1ce-4f3b-a84b-43b2dc979910', term_end = '2022-12-12',
           source = source || ' | CA_0168 (2026-09-23): seat slot moved TA4 -> TA5 after Donald LaPlante''s real tenure '
                    || 'in Trustee Area 4 (1979 to Dec 2020) was sourced; end = day before TA5''s successor, NOT '
                    || 'researched (same convention as CA_0143-0154)'
     WHERE id = '4bb2d016-36ff-41af-a307-3c46fe35b978';
  END IF;
END $$;

-- Glendale (Freemon first: she vacates TA E for Nahabedian) and Pasadena -- target seats are free
UPDATE essentials.office_terms ot
   SET office_id = _t.tgt_office, term_start = _t.new_start, start_precision = _t.prec, term_end = _t.new_end,
       how_started = _t.how_started, how_ended = _t.how_ended, source = ot.source || _t.src
  FROM _t
 WHERE ot.id = _t.term_id AND _t.term_id = '5877a644-4cdd-469c-8140-fc29b14ffe68' AND ot.source NOT LIKE '%CA_0168%';
UPDATE essentials.office_terms ot
   SET office_id = _t.tgt_office, term_start = _t.new_start, start_precision = _t.prec, term_end = _t.new_end,
       how_started = _t.how_started, how_ended = _t.how_ended, source = ot.source || _t.src
  FROM _t
 WHERE ot.id = _t.term_id AND _t.term_id IN ('1aa4b304-e0d3-470f-a022-a4b345e912d8','06572ad3-a6a4-4026-8e52-feeca8b64e3a')
   AND ot.source NOT LIKE '%CA_0168%';

-- ─── 4. LaConte's second stint ─────────────────────────────────────────────────────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, how_ended, source)
SELECT 'a63f5e88-ae36-40c1-a0b6-03360c5007c0', '19db4957-f8af-4e9f-b3d4-b9374e4fd37a'::uuid, '2023-01-18', '2023-03-01', 'day',
       'appointed', 'removed',
       'CA_0168 (2026-09-23): appointed to Trustee Area 4 on 2023-01-18 ("LaConte takes over the vacant seat in Trustee '
       || 'Area 4" -- dailybulletin.com/2023/01/20/claremont-unified-school-board-fills-seat-vacated-by-embattled-former-president/); '
       || 'removed 2023-03-01 when the county validated a petition forcing the July 25 2023 special election ("was immediately '
       || 'removed" -- ccourier.em03.enthusiastinc.net/latest-news/petition-succeeds-forces-special-election-for-cusd-board-seat-72814/)'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms
                    WHERE politician_id = '19db4957-f8af-4e9f-b3d4-b9374e4fd37a' AND office_id = 'a63f5e88-ae36-40c1-a0b6-03360c5007c0'
                      AND term_start = '2023-01-18');

-- ─── POST-VERIFY ────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _t JOIN essentials.office_terms ot ON ot.id = _t.term_id
   WHERE ot.office_id = COALESCE(_t.tgt_office, _t.cur_office)
     AND ot.term_start IS NOT DISTINCT FROM _t.new_start AND ot.start_precision = _t.prec
     AND ot.term_end = _t.new_end AND ot.how_started IS NOT DISTINCT FROM _t.how_started
     AND ot.how_ended = _t.how_ended
     AND (SELECT count(*) FROM regexp_matches(ot.source, 'CA_0168', 'g')) = 1;
  IF v_n <> 26 THEN RAISE EXCEPTION 'POST: only % of 26 A2 terms match the plan', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE (id = '23e1ce87-3517-43d6-a5ee-78fe16452640' AND office_id = 'dc05ab2d-3536-4c10-ac39-3fb16138a833' AND term_end = '2022-11-30' AND term_start IS NULL)
      OR (id = '4bb2d016-36ff-41af-a307-3c46fe35b978' AND office_id = 'e88ca57e-d1ce-4f3b-a84b-43b2dc979910' AND term_end = '2022-12-12' AND term_start IS NULL)
      OR (id IN ('d91f7c74-02c1-4185-858e-3286a5b46c7c','b54e51ac-019b-4fa8-945c-7b3fc64e6dea') AND term_start = '2024-04-09' AND start_precision = 'day' AND term_end IS NULL);
  IF v_n <> 4 THEN RAISE EXCEPTION 'POST: Schur/Aikin/Tse/Farid rows wrong (%/4)', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE politician_id = '19db4957-f8af-4e9f-b3d4-b9374e4fd37a' AND office_id = 'a63f5e88-ae36-40c1-a0b6-03360c5007c0'
     AND term_start = '2023-01-18' AND term_end = '2023-03-01' AND how_ended = 'removed';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: LaConte stint-2 rows = %', v_n; END IF;

  -- no A2 term is left with the old successor-derived shape
  SELECT count(*) INTO v_n FROM _t JOIN essentials.office_terms ot ON ot.id = _t.term_id
   WHERE ot.term_start IS NULL AND _t.new_start IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % A2 terms still start NULL', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms;
  IF v_n <> (SELECT missing_terms FROM _baseline) THEN
    RAISE EXCEPTION 'POST: offices_missing_terms moved from % to %', (SELECT missing_terms FROM _baseline), v_n; END IF;
END $$;

COMMIT;
