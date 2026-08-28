-- CC_0007_fl_legislature_incumbents.sql
-- Knight Foundation program, wave FL-2 (occupancy half).
--
-- Seats 155 Florida legislators: 116 Representatives + 39 Senators.
--
-- 🔴 155 PEOPLE, NOT 160. 5 seats are vacant and were flagged is_vacant by the
-- structure migration; they get NO politician and NO office_terms row here:
--   HD-55: vacant since 2026-08-06, after Kevin M. Steele
--   HD-78: vacant since 2026-05-21, after Jenna Persons-Mulicka
--   HD-113: vacant since 2025-11-19, after Vicki L. Lopez
--   HD-116: vacant since 2026-08-22, after Daniel Perez
--   SD-39: vacant since UNKNOWN (not published)
--
-- SOURCE: flhouse.gov/Representatives and flsenate.gov/Senators/ for identity,
-- district and the canonical name spelling, plus EACH MEMBER'S OWN PAGE for the
-- assumed-office date and the change-since-source check. All 155 member pages
-- mention their member's surname. Built by build-fl-legislature-roster.mjs into
-- data/fl-legislature-roster.json; defects documented in
-- data/seed-fl-legislature-2026/ROSTERS.md. Retrieved 2026-08-28T16:54:10.544Z.
--
-- ⚠ THE ROSTER'S OWN DATE IS THE CURRENT TERM, NOT CONTINUOUS OCCUPANCY. 120 of the
-- 127 House records read 11/06/24, the 2024 general election. term_start is the start
-- of continuous occupancy by that person and re-election does not end an occupancy, so
-- every date here comes from the member's own "Legislative Service" line instead.
--
-- DATE PRECISION is recorded, never fabricated: 39 seats carry a full date
-- (start_precision='day'); 116 carry only a year (stored YYYY-01-01 with
-- start_precision='year', so month and day are explicitly NOT claimed); 0 unknown.
-- 0 seat(s) carry a NULL term_start.
--
-- HOW STARTED: elected 155, appointed 0, unknown 0. Florida fills
-- legislative vacancies by SPECIAL ELECTION, not appointment (Fla. Const. art. III,
-- s. 15(d); ch. 100, F.S.), so every seat is 'elected'. Stated explicitly because
-- seat_officeholder() DEFAULTS p_how_started to 'elected' and a silent default is not
-- evidence.
--
-- 🔴 external_id band: House -(1220000+n), Senate -(1230000+n). NOT -(1210000+n),
-- which holds 166 FL US House candidate rows (-1212802..-1210101). Both bands used
-- here were measured empty against prod on 2026-08-28 and are re-asserted below
-- BEFORE any insert, because ON CONFLICT DO NOTHING would silently absorb a collision
-- and leave the seat held by whoever already owned that id.

BEGIN;

-- ─── Refuse to run if the external_id bands are not as expected ─────────────
DO $$
DECLARE v_house int; v_senate int;
BEGIN
  SELECT count(*) INTO v_house FROM essentials.politicians
   WHERE external_id BETWEEN -1220120 AND -1220001;
  SELECT count(*) INTO v_senate FROM essentials.politicians
   WHERE external_id BETWEEN -1230040 AND -1230001;
  IF v_house NOT IN (0, 116) THEN
    RAISE EXCEPTION 'CC_0007: FL House external_id band holds % rows (expected 0 on first run, 116 on a re-run)', v_house;
  END IF;
  IF v_senate NOT IN (0, 39) THEN
    RAISE EXCEPTION 'CC_0007: FL Senate external_id band holds % rows (expected 0 on first run, 39 on a re-run)', v_senate;
  END IF;
END $$;

CREATE TEMP TABLE fl_leg_seed (
  geo_id          text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_name     text,
  name_suffix     text,
  aliases         text[],
  photo_url       text,
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO fl_leg_seed VALUES
    ('12001', 'STATE_UPPER', 'Senator', -1230001, 'Don Gaetz', 'Don', 'Gaetz', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S01_4804_Thumbnail.jpg', DATE '2024-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S1 "Legislative Service": Elected to the Senate in 2024, prior Senate 2006-2016'),
    ('12002', 'STATE_UPPER', 'Senator', -1230002, 'Jay Trumbull', 'Jay', 'Trumbull', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S02_5389_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S2 "Legislative Service": Elected to the Senate in 2022'),
    ('12003', 'STATE_UPPER', 'Senator', -1230003, 'Corey Simon', 'Corey', 'Simon', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S03_5522_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S3 "Legislative Service": Elected to the Senate in 2022, reelected subsequently'),
    ('12004', 'STATE_UPPER', 'Senator', -1230004, 'Clay Yarborough', 'Clay', 'Yarborough', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S04_5394_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S4 "Legislative Service": Elected to the Senate in 2022'),
    ('12005', 'STATE_UPPER', 'Senator', -1230005, 'Tracie Davis', 'Tracie', 'Davis', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S05_5385_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S5 "Legislative Service": Elected to the Senate in 2022, reelected subsequently'),
    ('12006', 'STATE_UPPER', 'Senator', -1230006, 'Jennifer Bradley', 'Jennifer', 'Bradley', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S06_5476_Thumbnail.jpg', DATE '2020-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S6 "Legislative Service": Elected to the Senate in 2020, reelected subsequently'),
    ('12007', 'STATE_UPPER', 'Senator', -1230007, 'Thomas J. "Tom" Leek', 'Thomas', 'Leek', 'J.', NULL, ARRAY['Tom']::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S07_5232_Thumbnail.jpg', DATE '2024-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S7 "Legislative Service": Elected to the Senate in 2024'),
    ('12008', 'STATE_UPPER', 'Senator', -1230008, 'Tom A. Wright', 'Tom', 'Wright', 'A.', NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S08_5346_Thumbnail.jpg', DATE '2018-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S8 "Legislative Service": Elected to the Senate in 2018, reelected subsequently'),
    ('12009', 'STATE_UPPER', 'Senator', -1230009, 'Stan McClain', 'Stan', 'McClain', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S09_5571_Thumbnail.jpg', DATE '2024-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S9 "Legislative Service": Elected to the Senate in 2024'),
    ('12010', 'STATE_UPPER', 'Senator', -1230010, 'Jason Brodeur', 'Jason', 'Brodeur', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S10_5077_Thumbnail.jpg', DATE '2020-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S10 "Legislative Service": Elected to the Senate in 2020, reelected subsequently'),
    ('12011', 'STATE_UPPER', 'Senator', -1230011, 'Ralph E. Massullo, Jr.', 'Ralph', 'Massullo', 'E.', 'Jr.', '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S11_5603_Thumbnail.jpg', DATE '2025-12-09', 'day', 'elected', 'flsenate.gov/Senators/2024-2026/S11 "Legislative Service": Elected to the Senate on December 9, 2025 [confirmed by "Elected 12/9/2025"]'),
    ('12012', 'STATE_UPPER', 'Senator', -1230012, 'Colleen Burton', 'Colleen', 'Burton', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S12_5414_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S12 "Legislative Service": Elected to the Senate in 2022'),
    ('12013', 'STATE_UPPER', 'Senator', -1230013, 'Keith L. Truenow', 'Keith', 'Truenow', 'L.', NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S13_5492_Thumbnail.jpg', DATE '2024-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S13 "Legislative Service": Elected to the Senate in 2024'),
    ('12014', 'STATE_UPPER', 'Senator', -1230014, 'Brian Nathan', 'Brian', 'Nathan', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S14_5606_Thumbnail.jpg', DATE '2026-03-24', 'day', 'elected', 'flsenate.gov/Senators/2024-2026/S14 "Legislative Service": Elected to the Senate on March 24, 2026 [confirmed by "Elected 3/24/2026"]'),
    ('12015', 'STATE_UPPER', 'Senator', -1230015, 'LaVon Bracy Davis', 'LaVon', 'Bracy Davis', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S15_5601_Thumbnail.jpg', DATE '2025-09-02', 'day', 'elected', 'flsenate.gov/Senators/2024-2026/S15 "Legislative Service": Elected to the Senate on September 2, 2025 [confirmed by "Elected 9/2/2025"]'),
    ('12016', 'STATE_UPPER', 'Senator', -1230016, 'Darryl Ervin Rouson', 'Darryl', 'Rouson', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S16_5203_Thumbnail.jpg', DATE '2016-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S16 "Legislative Service": Elected to the Senate in 2016, reelected subsequently'),
    ('12017', 'STATE_UPPER', 'Senator', -1230017, 'Carlos Guillermo Smith', 'Carlos', 'Smith', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S17_5256_Thumbnail.jpg', DATE '2024-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S17 "Legislative Service": Elected to the Senate in 2024'),
    ('12018', 'STATE_UPPER', 'Senator', -1230018, 'Nick DiCeglie', 'Nick', 'DiCeglie', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S18_5365_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S18 "Legislative Service": Elected to the Senate in 2022'),
    ('12019', 'STATE_UPPER', 'Senator', -1230019, 'Debbie Mayfield', 'Debbie', 'Mayfield', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S19_5199_Thumbnail.jpg', DATE '2025-06-10', 'day', 'elected', 'flsenate.gov/Senators/2024-2026/S19 "Legislative Service": Elected to the Senate on June 10, 2025, prior service 2016-2024 [confirmed by "Elected 6/10/2025"]'),
    ('12020', 'STATE_UPPER', 'Senator', -1230020, 'Jim Boyd', 'Jim', 'Boyd', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S20_5070_Thumbnail.jpg', DATE '2020-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S20 "Legislative Service": Elected to the Senate in 2020, reelected subsequently'),
    ('12021', 'STATE_UPPER', 'Senator', -1230021, 'Ed Hooper', 'Ed', 'Hooper', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S21_5344_Thumbnail.jpg', DATE '2018-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S21 "Legislative Service": Elected to the Senate in 2018, reelected subsequently'),
    ('12022', 'STATE_UPPER', 'Senator', -1230022, 'Joe Gruters', 'Joe', 'Gruters', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S22_5347_Thumbnail.jpg', DATE '2018-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S22 "Legislative Service": Elected to the Senate in 2018, reelected subsequently'),
    ('12023', 'STATE_UPPER', 'Senator', -1230023, 'Danny Burgess', 'Danny', 'Burgess', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S23_5169_Thumbnail.jpg', DATE '2020-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S23 "Legislative Service": Elected to the Senate in 2020, reelected subsequently'),
    ('12024', 'STATE_UPPER', 'Senator', -1230024, 'Mack Bernard', 'Mack', 'Bernard', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S24_5570_Thumbnail.jpg', DATE '2024-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S24 "Legislative Service": Elected to the Senate in 2024'),
    ('12025', 'STATE_UPPER', 'Senator', -1230025, 'Kristen Aston Arrington', 'Kristen', 'Arrington', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S25_5494_Thumbnail.jpg', DATE '2024-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S25 "Legislative Service": Elected to the Senate in 2024'),
    ('12026', 'STATE_UPPER', 'Senator', -1230026, 'Lori Berman', 'Lori', 'Berman', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S26_5339_Thumbnail.jpg', DATE '2018-04-10', 'day', 'elected', 'flsenate.gov/Senators/2024-2026/S26 "Legislative Service": Elected to the Senate April 10, 2018, reelected subsequently'),
    ('12027', 'STATE_UPPER', 'Senator', -1230027, 'Ben Albritton', 'Ben', 'Albritton', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S27_5342_Thumbnail.jpg', DATE '2018-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S27 "Legislative Service": Elected to the Senate in 2018, reelected subsequently'),
    ('12028', 'STATE_UPPER', 'Senator', -1230028, 'Kathleen Passidomo', 'Kathleen', 'Passidomo', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S28_5196_Thumbnail.jpg', DATE '2016-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S28 "Legislative Service": Elected to the Senate in 2016, reelected subsequently'),
    ('12029', 'STATE_UPPER', 'Senator', -1230029, 'Erin Grall', 'Erin', 'Grall', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S29_5426_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S29 "Legislative Service": Elected to the Senate in 2022, reelected subsequently'),
    ('12030', 'STATE_UPPER', 'Senator', -1230030, 'Tina Scott Polsky', 'Tina', 'Polsky', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S30_5371_Thumbnail.jpg', DATE '2020-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S30 "Legislative Service": Elected to the Senate in 2020, reelected subsequently'),
    ('12031', 'STATE_UPPER', 'Senator', -1230031, 'Gayle Harrell', 'Gayle', 'Harrell', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S31_5348_Thumbnail.jpg', DATE '2018-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S31 "Legislative Service": Elected to the Senate in 2018, reelected subsequently'),
    ('12032', 'STATE_UPPER', 'Senator', -1230032, 'Rosalind Osgood', 'Rosalind', 'Osgood', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S32_5520_Thumbnail.jpg', DATE '2022-03-08', 'day', 'elected', 'flsenate.gov/Senators/2024-2026/S32 "Legislative Service": Elected to the Senate March 8, 2022, reelected subsequently'),
    ('12033', 'STATE_UPPER', 'Senator', -1230033, 'Jonathan Martin', 'Jonathan', 'Martin', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S33_5524_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S33 "Legislative Service": Elected to the Senate in 2022, reelected subsequently'),
    ('12034', 'STATE_UPPER', 'Senator', -1230034, 'Shevrin D. "Shev" Jones', 'Shevrin', 'Jones', 'D.', NULL, ARRAY['Shev']::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S34_5453_Thumbnail.jpg', DATE '2020-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S34 "Legislative Service": Elected to the Senate in 2020, reelected subsequently'),
    ('12035', 'STATE_UPPER', 'Senator', -1230035, 'Barbara Sharief', 'Barbara', 'Sharief', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S35_5572_Thumbnail.jpg', DATE '2024-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S35 "Legislative Service": Elected to the Senate in 2024'),
    ('12036', 'STATE_UPPER', 'Senator', -1230036, 'Ileana Garcia', 'Ileana', 'Garcia', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S36_5515_Thumbnail.jpg', DATE '2020-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S36 "Legislative Service": Elected to the Senate in 2020, reelected subsequently'),
    ('12037', 'STATE_UPPER', 'Senator', -1230037, 'Jason W. B. Pizzo', 'Jason', 'Pizzo', 'W.', NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S37_5345_Thumbnail.jpg', DATE '2018-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S37 "Legislative Service": Elected to the Senate in 2018, reelected subsequently'),
    ('12038', 'STATE_UPPER', 'Senator', -1230038, 'Alexis Calatayud', 'Alexis', 'Calatayud', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S38_5525_Thumbnail.jpg', DATE '2022-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S38 "Legislative Service": Elected to the Senate in 2022'),
    ('12040', 'STATE_UPPER', 'Senator', -1230040, 'Ana Maria Rodriguez', 'Ana', 'Rodriguez', NULL, NULL, '{}'::text[], 'https://www.flsenate.gov/PublishedContent/Senators/2024-2026/Photos/S40_5379_Thumbnail.jpg', DATE '2020-01-01', 'year', 'elected', 'flsenate.gov/Senators/2024-2026/S40 "Legislative Service": Elected to the Senate in 2020, reelected subsequently'),
    ('12001', 'STATE_LOWER', 'Representative', -1220001, 'Michelle Salzman', 'Michelle', 'Salzman', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4763.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4763 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12002', 'STATE_LOWER', 'Representative', -1220002, 'Robert Alexander "Alex" Andrade', 'Robert', 'Andrade', NULL, NULL, ARRAY['Alex']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4710.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4710 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12003', 'STATE_LOWER', 'Representative', -1220003, 'Nathan Boyles', 'Nathan', 'Boyles', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/5063.jpg', DATE '2025-06-10', 'day', 'elected', 'flhouse.gov/Representatives roster term window 06/10/25-11/03/26 (no Legislative Service block on details.aspx?MemberId=5063: first term)'),
    ('12004', 'STATE_LOWER', 'Representative', -1220004, 'Patt Maney', 'Patt', 'Maney', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4764.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4764: first term)'),
    ('12005', 'STATE_LOWER', 'Representative', -1220005, 'Shane G. Abbott', 'Shane', 'Abbott', 'G.', NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4864.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4864 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12006', 'STATE_LOWER', 'Representative', -1220006, 'Philip Wayne "Griff" Griffitts, Jr.', 'Philip', 'Griffitts', NULL, 'Jr.', ARRAY['Griff']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4862.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4862 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12007', 'STATE_LOWER', 'Representative', -1220007, 'Jason Shoaf', 'Jason', 'Shoaf', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4756.jpg', DATE '2019-06-18', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=4756 "Legislative Service": Elected to the Florida House of Representatives on June 18, 2019, reelected subsequently'),
    ('12008', 'STATE_LOWER', 'Representative', -1220008, 'Gallop Franklin, II', 'Gallop', 'Franklin', NULL, 'II', '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4863.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4863: first term)'),
    ('12009', 'STATE_LOWER', 'Representative', -1220009, 'Allison Tant', 'Allison', 'Tant', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4765.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4765: first term)'),
    ('12010', 'STATE_LOWER', 'Representative', -1220010, 'Robert Charles "Chuck" Brannan, III', 'Robert', 'Brannan', NULL, 'III', ARRAY['Chuck']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4708.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4708 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12011', 'STATE_LOWER', 'Representative', -1220011, 'Sam Garrison', 'Sam', 'Garrison', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4767.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4767 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12012', 'STATE_LOWER', 'Representative', -1220012, 'Wyman Duggan', 'Wyman', 'Duggan', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4712.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4712 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12013', 'STATE_LOWER', 'Representative', -1220013, 'Angela "Angie" Nixon', 'Angela', 'Nixon', NULL, NULL, ARRAY['Angie']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4766.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4766: first term)'),
    ('12014', 'STATE_LOWER', 'Representative', -1220014, 'Kimberly Daniels', 'Kimberly', 'Daniels', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4652.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4652 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12015', 'STATE_LOWER', 'Representative', -1220015, 'Dean Black', 'Dean', 'Black', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4865.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4865 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12016', 'STATE_LOWER', 'Representative', -1220016, 'Kiyan Michael', 'Kiyan', 'Michael', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4869.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4869 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12017', 'STATE_LOWER', 'Representative', -1220017, 'Jessica Baker', 'Jessica', 'Baker', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4866.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4866 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12018', 'STATE_LOWER', 'Representative', -1220018, 'Kim Kendall', 'Kim', 'Kendall', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4905.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4905 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12019', 'STATE_LOWER', 'Representative', -1220019, 'Sam Greco', 'Sam', 'Greco', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4906.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4906 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12020', 'STATE_LOWER', 'Representative', -1220020, 'Judson Sapp', 'Judson', 'Sapp', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4907.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4907 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12021', 'STATE_LOWER', 'Representative', -1220021, 'Yvonne Hayes Hinson', 'Yvonne', 'Hinson', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4768.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4768 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12022', 'STATE_LOWER', 'Representative', -1220022, 'Chad Johnson', 'Chad', 'Johnson', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4908.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4908 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12023', 'STATE_LOWER', 'Representative', -1220023, 'J.J. Grow', 'J.J.', 'Grow', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4909.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4909 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12024', 'STATE_LOWER', 'Representative', -1220024, 'Ryan Chamberlin', 'Ryan', 'Chamberlin', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4901.jpg', DATE '2023-05-16', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=4901 "Legislative Service": Elected to the Florida House of Representatives on May 16, 2023, reelected subsequently'),
    ('12025', 'STATE_LOWER', 'Representative', -1220025, 'Taylor Michael Yarkosky', 'Taylor', 'Yarkosky', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4868.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4868 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12026', 'STATE_LOWER', 'Representative', -1220026, 'Nan Cobb', 'Nan', 'Cobb', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4910.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4910 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12027', 'STATE_LOWER', 'Representative', -1220027, 'Richard Gentry', 'Richard', 'Gentry', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4911.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4911 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12028', 'STATE_LOWER', 'Representative', -1220028, 'Bill Partington', 'Bill', 'Partington', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4912.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4912 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12029', 'STATE_LOWER', 'Representative', -1220029, 'Webster Barnaby', 'Webster', 'Barnaby', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4770.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4770: first term)'),
    ('12030', 'STATE_LOWER', 'Representative', -1220030, 'Chase Tramont', 'Chase', 'Tramont', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4867.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4867 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12031', 'STATE_LOWER', 'Representative', -1220031, 'Tyler I. Sirois', 'Tyler', 'Sirois', 'I.', NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4748.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4748 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12032', 'STATE_LOWER', 'Representative', -1220032, 'Brian Hodgers', 'Brian', 'Hodgers', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/5064.jpg', DATE '2025-06-10', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=5064 "Legislative Service": Elected to the Florida House of Representatives on June 10, 2025'),
    ('12033', 'STATE_LOWER', 'Representative', -1220033, 'Monique Miller', 'Monique', 'Miller', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4913.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4913 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12034', 'STATE_LOWER', 'Representative', -1220034, 'Robert A. "Robbie" Brackett', 'Robert', 'Brackett', 'A.', NULL, ARRAY['Robbie']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4870.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4870 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12035', 'STATE_LOWER', 'Representative', -1220035, 'Erika Booth', 'Erika', 'Booth', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4914.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4914: first term)'),
    ('12036', 'STATE_LOWER', 'Representative', -1220036, 'Rachel Saunders Plakon', 'Rachel', 'Plakon', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4871.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4871 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12037', 'STATE_LOWER', 'Representative', -1220037, 'Susan Plasencia', 'Susan', 'Plasencia', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4872.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4872 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12038', 'STATE_LOWER', 'Representative', -1220038, 'David Smith', 'David', 'Smith', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4718.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4718 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12039', 'STATE_LOWER', 'Representative', -1220039, 'Douglas Michael "Doug" Bankson', 'Douglas', 'Bankson', NULL, NULL, ARRAY['Doug']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4873.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4873 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12040', 'STATE_LOWER', 'Representative', -1220040, 'RaShon Young', 'RaShon', 'Young', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/5065.jpg', DATE '2025-09-02', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=5065 "Legislative Service": Elected to the Florida House of Representatives on September 2, 2025'),
    ('12041', 'STATE_LOWER', 'Representative', -1220041, 'Bruce Hadley Antone', 'Bruce', 'Antone', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4269.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4269 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12042', 'STATE_LOWER', 'Representative', -1220042, 'Anna V. Eskamani', 'Anna', 'Eskamani', 'V.', NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4746.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4746 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12043', 'STATE_LOWER', 'Representative', -1220043, 'Johanna López', 'Johanna', 'López', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4875.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4875 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12044', 'STATE_LOWER', 'Representative', -1220044, 'Jennifer "Rita" Harris', 'Jennifer', 'Harris', NULL, NULL, ARRAY['Rita']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4877.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4877 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12045', 'STATE_LOWER', 'Representative', -1220045, 'Leonard Spencer', 'Leonard', 'Spencer', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4915.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4915: first term)'),
    ('12046', 'STATE_LOWER', 'Representative', -1220046, 'Jose Alvarez', 'Jose', 'Alvarez', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4916.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4916 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12047', 'STATE_LOWER', 'Representative', -1220047, 'Paula A. Stark', 'Paula', 'Stark', 'A.', NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4878.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4878 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12048', 'STATE_LOWER', 'Representative', -1220048, 'Jon Albert', 'Jon', 'Albert', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4917.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4917 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12049', 'STATE_LOWER', 'Representative', -1220049, 'Jennifer Kincart Jonsson', 'Jennifer', 'Kincart Jonsson', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4918.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4918 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12050', 'STATE_LOWER', 'Representative', -1220050, 'Jennifer Canady', 'Jennifer', 'Canady', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4879.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4879 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12051', 'STATE_LOWER', 'Representative', -1220051, 'Hilary Holley', 'Hilary', 'Holley', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/5072.jpg', DATE '2026-03-24', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=5072 "Legislative Service": Elected to the Florida House of Representatives on March 24, 2026'),
    ('12052', 'STATE_LOWER', 'Representative', -1220052, 'Samantha Scott', 'Samantha', 'Scott', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/5070.jpg', DATE '2026-03-24', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=5070 "Legislative Service": Elected to the Florida House of Representatives on March 24, 2026'),
    ('12053', 'STATE_LOWER', 'Representative', -1220053, 'Jeff Holcomb', 'Jeff', 'Holcomb', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4890.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4890 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12054', 'STATE_LOWER', 'Representative', -1220054, 'Randall Scott "Randy" Maggard', 'Randall', 'Maggard', NULL, NULL, ARRAY['Randy']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4758.jpg', DATE '2019-06-18', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=4758 "Legislative Service": Elected to the Florida House of Representatives on June 18, 2019, reelected subsequently'),
    ('12056', 'STATE_LOWER', 'Representative', -1220056, 'Bradford Troy "Brad" Yeager', 'Bradford', 'Yeager', NULL, NULL, ARRAY['Brad']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4882.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4882 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12057', 'STATE_LOWER', 'Representative', -1220057, 'Adam Anderson', 'Adam', 'Anderson', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4885.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4885 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12058', 'STATE_LOWER', 'Representative', -1220058, 'Kimberly Berfield', 'Kimberly', 'Berfield', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4210.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4210 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12059', 'STATE_LOWER', 'Representative', -1220059, 'Berny Jacques', 'Berny', 'Jacques', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4886.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4886 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12060', 'STATE_LOWER', 'Representative', -1220060, 'Lindsay Cross', 'Lindsay', 'Cross', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4887.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4887 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12061', 'STATE_LOWER', 'Representative', -1220061, 'Linda Chaney', 'Linda', 'Chaney', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4778.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4778: first term)'),
    ('12062', 'STATE_LOWER', 'Representative', -1220062, 'Michele K. Rayner', 'Michele', 'Rayner', 'K.', NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4781.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4781: first term)'),
    ('12063', 'STATE_LOWER', 'Representative', -1220063, 'Dianne "Ms Dee" Hart-Lowman', 'Dianne', 'Hart-Lowman', NULL, NULL, ARRAY['Ms Dee']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4736.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4736 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12064', 'STATE_LOWER', 'Representative', -1220064, 'Susan L. Valdés', 'Susan', 'Valdés', 'L.', NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4752.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4752 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12065', 'STATE_LOWER', 'Representative', -1220065, 'Karen Gonzalez Pittman', 'Karen', 'Gonzalez Pittman', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4888.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4888 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12066', 'STATE_LOWER', 'Representative', -1220066, 'Traci Koster', 'Traci', 'Koster', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4779.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4779 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12067', 'STATE_LOWER', 'Representative', -1220067, 'Fentrice Driskell', 'Fentrice', 'Driskell', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4745.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4745 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12068', 'STATE_LOWER', 'Representative', -1220068, 'Lawrence McClure', 'Lawrence', 'McClure', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4686.jpg', DATE '2017-12-19', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=4686 "Legislative Service": Elected to the Florida House of Representatives on December 19, 2017, reelected subsequently'),
    ('12069', 'STATE_LOWER', 'Representative', -1220069, 'Daniel Antonio "Danny" Alvarez', 'Daniel', 'Alvarez', NULL, NULL, ARRAY['Danny']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4889.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4889 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12070', 'STATE_LOWER', 'Representative', -1220070, 'Michael Owen', 'Michael', 'Owen', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4919.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4919 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12071', 'STATE_LOWER', 'Representative', -1220071, 'William Cloud "Will" Robinson, Jr.', 'William', 'Robinson', NULL, 'Jr.', ARRAY['Will']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4733.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4733 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12072', 'STATE_LOWER', 'Representative', -1220072, 'William "Bill" Conerly', 'William', 'Conerly', NULL, NULL, ARRAY['Bill']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4920.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4920: first term)'),
    ('12073', 'STATE_LOWER', 'Representative', -1220073, 'Fiona McFarland', 'Fiona', 'McFarland', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4780.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4780 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12074', 'STATE_LOWER', 'Representative', -1220074, 'James Buchanan', 'James', 'Buchanan', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4731.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4731 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12075', 'STATE_LOWER', 'Representative', -1220075, 'Danny Nix, Jr.', 'Danny', 'Nix', NULL, 'Jr.', '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4921.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4921 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12076', 'STATE_LOWER', 'Representative', -1220076, 'Vanessa Oliver', 'Vanessa', 'Oliver', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4922.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4922 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12077', 'STATE_LOWER', 'Representative', -1220077, 'Tiffany Esposito', 'Tiffany', 'Esposito', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4892.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4892 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12079', 'STATE_LOWER', 'Representative', -1220079, 'Mike Giallombardo', 'Mike', 'Giallombardo', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4783.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4783 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12080', 'STATE_LOWER', 'Representative', -1220080, 'Adam Botana', 'Adam', 'Botana', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4782.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4782 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12081', 'STATE_LOWER', 'Representative', -1220081, 'Yvette Benarroch', 'Yvette', 'Benarroch', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4923.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4923: first term)'),
    ('12082', 'STATE_LOWER', 'Representative', -1220082, 'Lauren Melo', 'Lauren', 'Melo', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4784.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4784 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12083', 'STATE_LOWER', 'Representative', -1220083, 'Kaylee Tuck', 'Kaylee', 'Tuck', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4776.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4776 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12084', 'STATE_LOWER', 'Representative', -1220084, 'Dana Trabulsy', 'Dana', 'Trabulsy', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4788.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4788 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12085', 'STATE_LOWER', 'Representative', -1220085, 'Tobin Rogers "Toby" Overdorf', 'Tobin', 'Overdorf', NULL, NULL, ARRAY['Toby']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4728.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4728 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12086', 'STATE_LOWER', 'Representative', -1220086, 'John Snyder', 'John', 'Snyder', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4787.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4787 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12087', 'STATE_LOWER', 'Representative', -1220087, 'Emily Gregory', 'Emily', 'Gregory', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/5069.jpg', DATE '2026-03-24', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=5069 "Legislative Service": Elected to the Florida House of Representatives on March 24, 2026'),
    ('12088', 'STATE_LOWER', 'Representative', -1220088, 'Jervonte "Tae" Edmonds', 'Jervonte', 'Edmonds', NULL, NULL, ARRAY['Tae']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4842.jpg', DATE '2022-03-08', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=4842 "Legislative Service": Elected to the Florida House of Representatives on March 8, 2022, reelected subsequently'),
    ('12089', 'STATE_LOWER', 'Representative', -1220089, 'Debra Tendrich', 'Debra', 'Tendrich', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4924.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4924 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12090', 'STATE_LOWER', 'Representative', -1220090, 'Rob Long', 'Rob', 'Long', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/5067.jpg', DATE '2025-12-09', 'day', 'elected', 'flhouse.gov/Representatives roster term window 12/09/25-11/03/26 (no Legislative Service block on details.aspx?MemberId=5067: first term)'),
    ('12091', 'STATE_LOWER', 'Representative', -1220091, 'Peggy Gossett-Seidman', 'Peggy', 'Gossett-Seidman', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4891.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4891 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12092', 'STATE_LOWER', 'Representative', -1220092, 'Kelly Skidmore', 'Kelly', 'Skidmore', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4786.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4786: first term)'),
    ('12093', 'STATE_LOWER', 'Representative', -1220093, 'Anne Gerwig', 'Anne', 'Gerwig', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4925.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4925: first term)'),
    ('12094', 'STATE_LOWER', 'Representative', -1220094, 'Meg Weinberger', 'Meg', 'Weinberger', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4926.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4926: first term)'),
    ('12095', 'STATE_LOWER', 'Representative', -1220095, 'Christine Hunschofsky', 'Christine', 'Hunschofsky', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4799.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4799 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12096', 'STATE_LOWER', 'Representative', -1220096, 'Dan Daley', 'Dan', 'Daley', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4757.jpg', DATE '2019-06-18', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=4757 "Legislative Service": Elected to the Florida House of Representatives on June 18, 2019, reelected subsequently'),
    ('12097', 'STATE_LOWER', 'Representative', -1220097, 'Lisa Dunkley', 'Lisa', 'Dunkley', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4893.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4893 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12098', 'STATE_LOWER', 'Representative', -1220098, 'Mitch Rosenwald', 'Mitch', 'Rosenwald', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4927.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4927 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12099', 'STATE_LOWER', 'Representative', -1220099, 'Daryl Campbell', 'Daryl', 'Campbell', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4843.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4843: first term)'),
    ('12100', 'STATE_LOWER', 'Representative', -1220100, 'Chip LaMarca', 'Chip', 'LaMarca', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4722.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4722 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12101', 'STATE_LOWER', 'Representative', -1220101, 'Hillary Cassel', 'Hillary', 'Cassel', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4895.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4895: first term)'),
    ('12102', 'STATE_LOWER', 'Representative', -1220102, 'Michael "Mike" Gottlieb', 'Michael', 'Gottlieb', NULL, NULL, ARRAY['Mike']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4724.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4724 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12103', 'STATE_LOWER', 'Representative', -1220103, 'Robin Bartleman', 'Robin', 'Bartleman', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4793.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4793 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12104', 'STATE_LOWER', 'Representative', -1220104, 'Felicia Simone Robinson', 'Felicia', 'Robinson', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4791.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4791: first term)'),
    ('12105', 'STATE_LOWER', 'Representative', -1220105, 'Marie Paule Woodson', 'Marie', 'Woodson', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4789.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4789 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12106', 'STATE_LOWER', 'Representative', -1220106, 'Fabián Basabe', 'Fabián', 'Basabe', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4900.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4900 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12107', 'STATE_LOWER', 'Representative', -1220107, 'Wallace Aristide', 'Wallace', 'Aristide', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4928.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4928 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12108', 'STATE_LOWER', 'Representative', -1220108, 'Dotie Joseph', 'Dotie', 'Joseph', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4716.jpg', DATE '2018-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4716 "Legislative Service": Elected to the Florida House of Representatives in 2018, reelected subsequently'),
    ('12109', 'STATE_LOWER', 'Representative', -1220109, 'Ashley Viola Gantt', 'Ashley', 'Gantt', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4897.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4897: first term)'),
    ('12110', 'STATE_LOWER', 'Representative', -1220110, 'Tom Fabricio', 'Tom', 'Fabricio', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4792.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4792 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12111', 'STATE_LOWER', 'Representative', -1220111, 'David Borrero', 'David', 'Borrero', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4794.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4794 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12112', 'STATE_LOWER', 'Representative', -1220112, 'Alex Rizo', 'Alex', 'Rizo', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4796.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4796 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12114', 'STATE_LOWER', 'Representative', -1220114, 'Demi Busatta', 'Demi', 'Busatta', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4800.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4800 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12115', 'STATE_LOWER', 'Representative', -1220115, 'Omar Blanco', 'Omar', 'Blanco', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4929.jpg', DATE '2024-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4929 "Legislative Service": Elected to the Florida House of Representatives in 2024'),
    ('12117', 'STATE_LOWER', 'Representative', -1220117, 'Kevin D. Chambliss', 'Kevin', 'Chambliss', 'D.', NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4798.jpg', DATE '2020-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4798 "Legislative Service": Elected to the Florida House of Representatives in 2020, reelected subsequently'),
    ('12118', 'STATE_LOWER', 'Representative', -1220118, 'Mike Redondo', 'Mike', 'Redondo', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4902.jpg', DATE '2023-12-05', 'day', 'elected', 'flhouse.gov details.aspx?MemberId=4902 "Legislative Service": Elected to the Florida House of Representatives on December 5, 2023, reelected subsequently'),
    ('12119', 'STATE_LOWER', 'Representative', -1220119, 'Juan Carlos Porras', 'Juan', 'Porras', NULL, NULL, '{}'::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4898.jpg', DATE '2022-01-01', 'year', 'elected', 'flhouse.gov details.aspx?MemberId=4898 "Legislative Service": Elected to the Florida House of Representatives in 2022, reelected subsequently'),
    ('12120', 'STATE_LOWER', 'Representative', -1220120, 'James Vernon "Jim" Mooney, Jr.', 'James', 'Mooney', NULL, 'Jr.', ARRAY['Jim']::text[], 'https://www.flhouse.gov/FileStores/Web/Imaging/Member/4797.jpg', DATE '2024-11-06', 'day', 'elected', 'flhouse.gov/Representatives roster term window 11/06/24-11/03/26 (no Legislative Service block on details.aspx?MemberId=4797: first term)');

-- Guard the payload itself before it touches anything.
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM fl_leg_seed;
  IF v_n <> 155 THEN RAISE EXCEPTION 'seed payload: expected 155 rows, got %', v_n; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM fl_leg_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT geo_id, district_type FROM fl_leg_seed GROUP BY geo_id, district_type HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate (geo_id, district_type) key(s)', v_dup; END IF;
  -- A seeded person must never target an office the structure migration flagged vacant.
  SELECT count(*) INTO v_dup
    FROM fl_leg_seed s
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id AND d.district_type = s.district_type AND lower(d.state) = 'fl'
    JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
   WHERE o.is_vacant = true;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % row(s) target an office flagged is_vacant', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, photo_origin_url, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_name, s.name_suffix,
       s.aliases, s.photo_url, true, true, s.source
FROM fl_leg_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy: dated seats, via the helper ──────────────────────────────────
-- seat_officeholder() closes any predecessor's open-ended term before inserting,
-- which is the whole reason it exists.
--
-- 🔴 The districts join pairs geo_id WITH district_type. FL's sldl and sldu GEOIDs
-- both start at 12001, so dropping the pairing would match HD-n against SD-n for
-- every n <= 40.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
    FROM fl_leg_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id
     AND d.district_type = s.district_type
     AND lower(d.state) = 'fl'
    JOIN essentials.offices o
      ON o.district_id = d.id AND o.title = s.office_title
    WHERE s.term_start IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM essentials.office_terms t
        WHERE t.office_id = o.id AND t.politician_id = p.id
      )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      r.source,
      r.how_started,
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % FL legislator(s) with a known start date', v_seated;
END $$;

-- ─── Occupancy: unknown-start seats, direct insert ──────────────────────────
-- seat_officeholder() RAISE EXCEPTIONs on a NULL p_term_start by design, so a
-- genuinely unknown start is inserted directly -- the identical shape migration
-- 1459's phase-2 backfill and its corrections (1465, 1546, 1635, 1798, 1814) use.
-- essentials.current_office_holders treats term_start IS NULL / term_end IS NULL as
-- "currently holds", so such a member still counts as seated in the gate below.

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, s.start_precision, s.how_started, s.source
FROM fl_leg_seed s
JOIN essentials.politicians p ON p.external_id = s.ext_id
JOIN essentials.districts d
  ON d.geo_id = s.geo_id
 AND d.district_type = s.district_type
 AND lower(d.state) = 'fl'
JOIN essentials.offices o
  ON o.district_id = d.id AND o.title = s.office_title
WHERE s.term_start IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE v_pol int; v_seated int; v_lower int; v_upper int; v_vac_seated int;
BEGIN
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id BETWEEN -1220120 AND -1220001
      OR external_id BETWEEN -1230040 AND -1230001;
  IF v_pol <> 155 THEN RAISE EXCEPTION 'CC_0007: FL legislators inserted: expected 155, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs from
  -- offices, so a vacancy is a NULL politician_id, never an absent row. count(*) would
  -- pass vacuously with every seat empty -- and with 5 genuinely vacant seats here,
  -- count(*) would also read 160 and hide the difference that matters.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> 155 THEN RAISE EXCEPTION 'CC_0007: expected 155 seated FL legislators, found %', v_seated; END IF;

  SELECT count(och.politician_id) INTO v_lower
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type = 'STATE_LOWER';
  IF v_lower <> 116 THEN RAISE EXCEPTION 'CC_0007: expected 116 seated FL Representatives, found %', v_lower; END IF;

  SELECT count(och.politician_id) INTO v_upper
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type = 'STATE_UPPER';
  IF v_upper <> 39 THEN RAISE EXCEPTION 'CC_0007: expected 39 seated FL Senators, found %', v_upper; END IF;

  -- The 5 flagged-vacant offices must still hold nobody.
  SELECT count(och.politician_id) INTO v_vac_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND o.is_vacant = true;
  IF v_vac_seated <> 0 THEN RAISE EXCEPTION 'CC_0007: % vacant FL legislative office(s) somehow hold a person', v_vac_seated; END IF;
END $$;

COMMIT;
