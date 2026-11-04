-- CC_0346 — correct 8 California municipal water seats, and date the last 11 district offices.
--
-- Piece 4, California slice, second pass. After this, **all 25 California district offices and
-- both library districts carry a cited date**, and the only California offices still owed one
-- are the 110 city seats and the Los Angeles County Sheriff.
--
-- ============================================================================================
-- 🔴🔴 PART A — AN OVERWRITE. CC_0345 PUT 8 SEATS ON THE WRONG DATE, A MONTH LATE.
-- ============================================================================================
--
-- `CC_0345` seated the municipal water districts at **2027-01-04**. That was wrong. They take
-- office **2026-12-04**.
--
-- THE VALUES BEING OVERWRITTEN, recorded here because nothing else records them (repo rule: a
-- migration that overwrites a value must write the old value in its own header). Every one of
-- the 8 rows currently reads, identically:
--
--     election_date    = 2026-11-03
--     swearing_in_date = 2027-01-04          -> becomes 2026-12-04
--     window_end_date  = NULL                 (unchanged)
--     basis            = 'published'          -> becomes 'statute'
--     rule_id          = 'ca-water-principal-act'  -> becomes 'ca-wat-71253'
--     authority        = 'Cal. Water Code § 60139, Water Code Appendix §§ 98-51 and 103-5(b),
--                         and Cal. Gov. Code § 24200 — noon on the first Monday in January
--                         following the election'
--     source           = 'Los Angeles County Registrar-Recorder/County Clerk, Candidate
--                         Handbook and Resource Guide, November 3, 2026 General Election,
--                         Calendar of Events, "JAN. 4 (M) NOON E+62 — TAKING OF OFFICE —
--                         MUNICIPAL WATER, WATER AGENCIES, AND WATER REPLENISHMENT DISTRICTS" —
--                         https://content.lavote.gov/docs/rrcc/documents/candidate-handbook-general-election-complete-v-10.pdf (read 2026-11-04)'
--     notes            = 'NOT Cal. Elec. Code § 10554. These districts'' principal acts override
--                         the Uniform District Election Law''s first-Friday-in-December default,
--                         and the county lists them a month later than the health care and
--                         recreation-and-park districts.'
--
-- The 8 office_id values, so the set is recoverable without re-deriving it:
--     7d5d8326-6dfa-54ec-aae4-023a985c3560  Foothill MWD - Division 2
--     b9ae0830-b8e4-5f3c-8bdf-0e90bcd64fa6  Foothill MWD - Division 4
--     a1ff23fb-dfe2-52ab-90ab-10aa0a5d1903  Foothill MWD - Division 5
--     730e799b-a7e3-5599-87fe-7d25b72dead0  Las Virgenes MWD - Division 2
--     8ab37cd9-c692-5a4a-ab4a-08ef7faa8dd1  San Gabriel Valley MWD - Division 5
--     424d30d7-914c-5d77-9ad4-e40b74b140be  Three Valleys MWD - Division 3
--     09e9e913-110f-5365-b84e-752bab2662e8  West Basin MWD - Division 1
--     e1e4c2f5-e96b-58aa-baba-917574a80e96  West Basin MWD - Division 2
--
-- 🔴 WHY IT WAS WRONG: THE HEADING NAMED THEM AND THE CITATIONS DID NOT.
-- The LA County handbook's Calendar of Events reads:
--
--     JAN. 4 (M) NOON E+62
--     TAKING OF OFFICE — MUNICIPAL WATER, WATER AGENCIES, AND WATER REPLENISHMENT DISTRICTS
--     (Water Code § 60139, Water Code Appendix 98–51 and 103–5 (b) and Govt. Code § 24200)
--
-- Water Code § 60139 is the Water Replenishment District act. Appendix 98-51 and 103-5(b) are
-- the special acts of two WATER AGENCIES. **Not one of those three citations is the Municipal
-- Water District Law.** The heading swept in a class its own authorities do not reach.
--
-- The SAME handbook's General Information table gives municipal water districts their own row —
-- "Friday at Noon, December 4, 2026 (Water Code §§ 71252, 71253 ...)" — and the statute is
-- unambiguous:
--
--     Water Code § 71253. "Except for the directors elected at a formation election, directors
--     elected to office shall take office at noon on the first Friday in December succeeding
--     their election."  (Amended by Stats. 2013, Ch. 8, Sec. 1. (AB 72))
--
-- ▶ **READ THE CITATION, NOT THE HEADING.** This is the repo's "a source can be authoritative
-- for one field and stale for another" rule, inside a single document: the same handbook is
-- right in its table and wrong in its calendar heading.
--
-- ⚠ A MONTH LATE IS NOT THE SAFE DIRECTION. CC_0345's note argued against seating these seats a
-- month EARLY, and in avoiding that it seated them a month LATE — which leaves the departing
-- director resolving as the current officeholder for a month after they have gone. Both errors
-- are live on the site and neither raises anything.
--
-- The 6 rows that KEEP 2027-01-04 are the ones whose citations really do cover them: the
-- Antelope Valley-East Kern and Santa Clarita Valley water agencies (Water Code Appendix 98-51
-- and 103-5(b)) and the Water Replenishment District of Southern California (§ 60139). The
-- handbook's own General Information table corroborates this with a dedicated AVEK row reading
-- "Monday at noon, January 4, 2027".
--
-- ============================================================================================
-- PART B — THE LAST 11 DISTRICT OFFICES. ALL NINE BODIES LAND ON 2026-12-04.
-- ============================================================================================
--
-- `CC_0345` left these owed because the county's calendar names five district classes and none
-- of these bodies. Each body's PRINCIPAL ACT was established one at a time, from that body's own
-- records, and every one of the five acts sets the same day:
--
--   Walnut Valley Water District (3)        California water district, Water Code division 13.
--       Its own audited financial statements: "operates under the authority of Division 13 of
--       the California Water Code". Water Code § 35057 routes the conduct of its division
--       elections to the Uniform District Election Law; Elec. Code § 10554 then sets noon on
--       the first Friday in December.
--   Crescenta Valley Water District (1)     County water district, Water Code division 12.
--   La Puente Valley County Water District (1)   County water district (its legal name).
--   Valley County Water District (1)        County water district (its legal name).
--       Water Code § 30502 gives these districts' term LENGTH and says nothing about when it
--       starts, so Elec. Code § 10554 supplies the date.
--   La Cañada Irrigation District (1)       Irrigation district (its legal name).
--   Palmdale Water District (1)             Irrigation district: formed 1918 as the Palmdale
--       Irrigation District "under Division 11 of the Water Code", renamed 1973. ⚠ THE NAME
--       STOPPED SAYING WHAT IT IS — "Water District" is not a class, and the 1973 rename did not
--       change the act it runs under.
--       Water Code § 21101 covers both: "notwithstanding Sections 10505 and 10554 ... officers
--       elected at a general district election take office at noon on the first Friday in
--       December next following".
--   Wrightwood Community Services District (1)   Gov. Code § 61042(a): "Directors shall take
--       office at noon on the first Friday in December following their election."
--       ⚠ This district draws property tax from BOTH San Bernardino and Los Angeles counties and
--       its formation election was run by San Bernardino County, so the LA County handbook is
--       NOT its authority. The statute is statewide, so the date is the same — but it is cited
--       to the Government Code here, not to the handbook.
--   Altadena Library District (1)           Educ. Code chapter 9. The district's own board page:
--       "Pursuant to Education Code Section 19700, Trustees take office the first Friday in
--       December succeeding their election."
--   Palos Verdes Library District (1)       Educ. Code chapter 9. Its own history page: "formed
--       in April 1928 under the provision of Sections 19600-19734 of the California Education
--       Code".
--
-- 🔴 THE LIBRARY DISTRICTS WERE THE ONES THAT COULD HAVE BEEN A WEEK WRONG, IN THE EARLIEST
-- DIRECTION. California has TWO library-district chapters and they seat trustees a week apart:
--     Educ. Code ch. 8 (§§ 19400-19532)   § 19422: the LAST FRIDAY IN NOVEMBER  -> 2026-11-27
--     Educ. Code ch. 9 (§§ 19600-19734)   § 19700(b): the FIRST FRIDAY IN DECEMBER -> 2026-12-04
-- 2026-11-27 would be the earliest handover in the entire transition programme. Both districts
-- here are chapter 9, in their own words, so nothing lands there.
--
-- ⚠ AND THE TERRITORY DOES NOT DECIDE THE CHAPTER. Chapter 9 is titled "Library Districts and
-- Museums in UNINCORPORATED Towns and Villages", and Palos Verdes Library District serves four
-- INCORPORATED cities — while still being a chapter 9 district, because that is how it was
-- formed in 1928. Its own trustee roster prints "Term Expires: 11/27/2026", the chapter 8 date,
-- beside "Term Began: 12/02/2022", which is the first Friday in December 2022 and therefore
-- chapter 9. The formation statute and the term-start field agree; the term-expiry field is the
-- odd one out. Judged field by field, not page by page.

CREATE TEMP TABLE ca_2026_bodies ON COMMIT DROP AS
SELECT DISTINCT
       o.id AS office_id,
       regexp_replace(d.label, '\s*-\s*(Division|Trustee Area)\s*\S+$', '') AS body
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'ca';

-- --------------------------------------------------------------------------------------------
-- PART A — correct the 8 municipal water rows. Guarded on the value it changes, so a re-run
-- writes nothing and reports nothing it did not do.
-- --------------------------------------------------------------------------------------------
UPDATE essentials.office_swearing_in s
   SET swearing_in_date = DATE '2026-12-04',
       basis            = 'statute',
       rule_id          = 'ca-wat-71253',
       authority        = 'Cal. Water Code § 71253 — "directors elected to office shall take office at noon on the first Friday in December succeeding their election"',
       source           = 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=71253. (read 2026-11-04), corroborated by the Los Angeles County RR/CC Candidate Handbook for the November 3, 2026 General Election, General Information table, row "DIRECTOR - MUNICIPAL WATER DISTRICT": "Friday at Noon, December 4, 2026 (Water Code §§ 71252, 71253 ...)"',
       notes            = 'CORRECTED BY CC_0346 from 2027-01-04. CC_0345 followed the same handbook''s Calendar of Events heading "TAKING OF OFFICE - MUNICIPAL WATER, WATER AGENCIES, AND WATER REPLENISHMENT DISTRICTS ... first Monday in January", whose citations (Water Code § 60139, Appendix 98-51 and 103-5(b)) are the water-replenishment and water-agency acts and do NOT reach municipal water districts. Read the citation, not the heading.',
       updated_at       = now()
  FROM ca_2026_bodies b
 WHERE b.office_id = s.office_id
   AND s.election_date = DATE '2026-11-03'
   AND b.body IN (
         'Foothill Municipal Water District',
         'Las Virgenes Municipal Water District',
         'San Gabriel Valley Municipal Water District',
         'Three Valleys Municipal Water District',
         'West Basin Municipal Water District'
       )
   AND s.swearing_in_date IS DISTINCT FROM DATE '2026-12-04';

-- --------------------------------------------------------------------------------------------
-- PART B — the 11 remaining district offices, by principal act. Four inserts, four authorities.
-- 🔴 BY BODY NAME, never by office title. CC_0345's header has the account of why.
-- --------------------------------------------------------------------------------------------

-- 3 — Walnut Valley Water District. California water district -> UDEL -> Elec. Code § 10554.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id, DATE '2026-11-03', DATE '2026-12-04', 'statute', 'ca-wat-35057-udel',
       'Cal. Water Code § 35057 routes the conduct of these elections to the Uniform District Election Law; Cal. Elec. Code § 10554 then sets taking office at noon on the first Friday in December',
       'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=35057. and https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10554. (both read 2026-11-04)',
       'Class established from the district''s own audited financial statements: "an independent special district, operates under the authority of Division 13 of the California Water Code" (walnutvalleywater.gov, read 2026-11-04). Division 13 is the California Water District Law.'
  FROM ca_2026_bodies WHERE body = 'Walnut Valley Water District'
ON CONFLICT (office_id, election_date) DO NOTHING;

-- 3 — county water districts. Water Code § 30502 gives the term's length only.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id, DATE '2026-11-03', DATE '2026-12-04', 'statute', 'ca-elec-10554',
       'Cal. Elec. Code § 10554 — "Elective officers, elected or appointed pursuant to this part, take office at noon on the first Friday in December next following the general district election"',
       'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10554. (read 2026-11-04)',
       'County water districts, Water Code division 12. Cal. Water Code § 30502 fixes the four-year TERM LENGTH and is silent on when the term starts, so the Uniform District Election Law supplies the date. Crescenta Valley Water District''s class is from its own description as "regulated by the State of California under Division 12 of the California Water Code"; the other two carry "County Water District" in their legal names.'
  FROM ca_2026_bodies
 WHERE body IN ('Crescenta Valley Water District',
                'La Puente Valley County Water District',
                'Valley County Water District')
ON CONFLICT (office_id, election_date) DO NOTHING;

-- 2 — irrigation districts.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id, DATE '2026-11-03', DATE '2026-12-04', 'statute', 'ca-wat-21101',
       'Cal. Water Code § 21101 — notwithstanding Elec. Code §§ 10505 and 10554, officers elected at a general district election take office at noon on the first Friday in December next following',
       'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=21101. (read 2026-11-04)',
       'Palmdale Water District is an irrigation district despite its name: formed in 1918 as the Palmdale Irrigation District "under Division 11 of the Water Code" and renamed in 1973 (palmdalewater.org, read 2026-11-04). The rename did not change the act it runs under.'
  FROM ca_2026_bodies
 WHERE body IN ('La Cañada Irrigation District', 'Palmdale Water District')
ON CONFLICT (office_id, election_date) DO NOTHING;

-- 1 — community services district.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id, DATE '2026-11-03', DATE '2026-12-04', 'statute', 'ca-gov-61042',
       'Cal. Gov. Code § 61042(a) — "Directors shall take office at noon on the first Friday in December following their election"',
       'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=GOV&sectionNum=61042. (read 2026-11-04)',
       'Cited to the Government Code, not to the Los Angeles County handbook: this district draws property tax from both San Bernardino and Los Angeles counties and its 2017 formation election was conducted by San Bernardino County, so the LA handbook is not its authority. The statute is statewide.'
  FROM ca_2026_bodies WHERE body = 'Wrightwood Community Services District'
ON CONFLICT (office_id, election_date) DO NOTHING;

-- 2 — library districts, Educ. Code chapter 9.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id, DATE '2026-11-03', DATE '2026-12-04', 'statute', 'ca-edc-19700',
       'Cal. Educ. Code § 19700(b) — "The trustees shall hold office for the term of four years beginning on the first Friday in December next succeeding their appointment or election"',
       'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=19700. (read 2026-11-04)',
       'Both are chapter 9 districts (§§ 19600-19734) in their own words: Altadena''s board page states "Pursuant to Education Code Section 19700, Trustees take office the first Friday in December succeeding their election"; Palos Verdes'' history page states it was "formed in April 1928 under the provision of Sections 19600-19734". NOT chapter 8, whose § 19422 would seat them on the last Friday in NOVEMBER - 2026-11-27, which would be the earliest handover in the programme. Palos Verdes serves four incorporated cities and is a chapter 9 district anyway, and its own roster prints the chapter 8 expiry date beside a chapter 9 start date.'
  FROM ca_2026_bodies
 WHERE body IN ('Altadena Library District', 'Palos Verdes Library District')
ON CONFLICT (office_id, election_date) DO NOTHING;

-- --------------------------------------------------------------------------------------------
-- Post-verify. Gates the delta this file creates, in its own transaction.
-- --------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_total     bigint;
  v_dec4      bigint;
  v_jan4      bigint;
  v_mwd_wrong bigint;
  v_jan4_body bigint;
  v_bad       bigint;
BEGIN
  SELECT count(*) INTO v_total
    FROM essentials.office_swearing_in WHERE election_date = DATE '2026-11-03';
  IF v_total <> 226 THEN
    RAISE EXCEPTION 'CC_0346: expected 226 rows for this election (215 + 11), found %', v_total;
  END IF;

  -- 25 district offices on 4 December: 8 municipal water (corrected) + 3 California water
  -- + 3 county water + 2 irrigation + 1 CSD + 2 library = 19. Plus nothing else.
  SELECT count(*) INTO v_dec4
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND swearing_in_date = DATE '2026-12-04';
  IF v_dec4 <> 19 THEN
    RAISE EXCEPTION 'CC_0346: expected 19 rows on 2026-12-04, found %', v_dec4;
  END IF;

  -- 🔴 EXACTLY 6 MAY REMAIN ON 4 JANUARY, and they are the water agencies and the water
  -- replenishment district. If a municipal water row is still there, Part A did not apply.
  SELECT count(*) INTO v_jan4
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND swearing_in_date = DATE '2027-01-04'
     AND rule_id = 'ca-water-principal-act';
  IF v_jan4 <> 6 THEN
    RAISE EXCEPTION 'CC_0346: expected 6 water agency / replenishment rows on 2027-01-04, found %', v_jan4;
  END IF;

  SELECT count(*) INTO v_mwd_wrong
    FROM essentials.office_swearing_in s
    JOIN ca_2026_bodies b ON b.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND b.body LIKE '%Municipal Water District'
     AND s.swearing_in_date <> DATE '2026-12-04';
  IF v_mwd_wrong <> 0 THEN
    RAISE EXCEPTION 'CC_0346: % municipal water row(s) are not on 2026-12-04 (Water Code 71253)', v_mwd_wrong;
  END IF;

  -- 🔴 AND THE INVERSE: nothing that is NOT a water agency or replenishment district may sit on
  -- 4 January except the 4 superior court judges. This is the gate that would have caught
  -- CC_0345's mistake, and it is written now because it was not written then.
  SELECT count(*) INTO v_jan4_body
    FROM essentials.office_swearing_in s
    JOIN ca_2026_bodies b ON b.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date = DATE '2027-01-04'
     AND s.rule_id NOT IN ('ca-water-principal-act', 'ca-const-vi-16c');
  IF v_jan4_body <> 0 THEN
    RAISE EXCEPTION 'CC_0346: % row(s) sit on 2027-01-04 under a rule that does not set that date', v_jan4_body;
  END IF;

  -- No row may be estimated, and nothing may land on 2026-11-27: both California library
  -- districts are Educ. Code chapter 9, so the chapter 8 date must not appear.
  SELECT count(*) INTO v_bad
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03'
     AND (basis NOT IN ('statute', 'published') OR swearing_in_date = DATE '2026-11-27');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0346: % row(s) are estimated or sit on the chapter 8 library date', v_bad;
  END IF;

  RAISE NOTICE 'CC_0346 OK: 226 rows — % on 2026-12-04, % water agency rows on 2027-01-04', v_dec4, v_jan4;
END $$;
