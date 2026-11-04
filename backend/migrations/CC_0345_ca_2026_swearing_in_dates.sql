-- CC_0345 — 215 California swearing-in dates for the 2026-11-03 election.
--
-- Piece 4, California slice. Fills `essentials.office_swearing_in` (CC_0344) for the offices
-- whose date a cited authority answers TODAY. 122 of California's 337 are deliberately left
-- out; see "What this does NOT seed" below. Nothing here is estimated: every row is 'statute'
-- or 'published'.
--
-- No value is overwritten. Every INSERT is `ON CONFLICT DO NOTHING` against a table this branch
-- created empty, so there is no prior value to record.
--
-- ============================================================================================
-- THE THREE CLASSES THIS SEEDS
-- ============================================================================================
--
--   197  school and community college district boards     2026-12-11   'statute'
--        Cal. Educ. Code § 5017: the term commences on the second Friday in December next
--        succeeding the election. § 5017 names school districts AND community college
--        districts, which is both of the body types present here.
--        `window_end_date` is 2026-12-25: Cal. Educ. Code § 35143 puts the organizational
--        meeting — where the oath is actually administered — on a day within the 15-day period
--        beginning that Friday, and § 5017's second sentence keeps the predecessor discharging
--        the duties of the office until the successor qualifies. So the handover is a WINDOW
--        and the table says so rather than flattening it.
--
--    14  municipal water districts, water agencies and
--        water replenishment districts                    2027-01-04   'published'
--        Cal. Water Code § 60139, Water Code Appendix §§ 98-51 and 103-5(b), Cal. Gov. Code
--        § 24200, as stated in the county's own calendar for THIS election.
--
--     4  judges of the superior court                     2027-01-04   'statute'
--        Cal. Const. art. VI § 16(c): terms begin the Monday after January 1 following the
--        election.
--
-- ============================================================================================
-- 🔴🔴 THE MISTAKE THIS MIGRATION ALMOST MADE, AND WHY THE BODIES ARE LISTED BY NAME
-- ============================================================================================
--
-- Cal. Elec. Code § 10554 reads like a blanket rule for special districts: "Elective officers,
-- elected or appointed pursuant to this part, take office at noon on the first Friday in
-- December next following the general district election." For 2026 that is 4 December. A
-- predicate over the office title — `title ILIKE 'Director%'` — would have applied it to all 25
-- California district offices in this wave, and an earlier draft of this work did exactly that.
--
-- It is wrong for 14 of the 25. § 10554 is bounded by each district's PRINCIPAL ACT, and the
-- municipal water districts, water agencies and water replenishment districts have acts that
-- override it. Los Angeles County's own Candidate Handbook for the November 3, 2026 General
-- Election lists the two groups under separate headings on separate dates:
--
--   DEC. 4 (F) E+31   TAKING OFFICE — HEALTH CARE, RECREATION, AND PARK DISTRICT
--   JAN. 4 (M) NOON E+62   TAKING OF OFFICE — MUNICIPAL WATER, WATER AGENCIES, AND WATER
--                          REPLENISHMENT DISTRICTS
--
-- A month early is not a rounding error. `office_terms` is self-executing, so those 14 seats
-- would have changed hands on the live site on 4 December, by themselves, with the people they
-- replace still in office and nobody running anything that could notice.
--
-- 🔴 SO THE EIGHT BODIES ARE WRITTEN OUT BY NAME. A name list is checkable against a roster;
-- a predicate over a title is a guess about what the title means. NO office in this seed uses
-- § 10554 — not one California body in the 2026 set falls under it.
--
-- ============================================================================================
-- WHAT THIS DOES NOT SEED — 122 offices, each for a stated reason
-- ============================================================================================
--
--   110  city offices (council members, mayors, clerks, treasurers, one city attorney)
--        Cal. Gov. Code § 36503 ties a city officer's term to "the date of the installation of
--        officers following adoption by the council of the official canvass of their election".
--        That is a per-council event. There is NO statewide date, and the handbook does not
--        carry one either. ~45 cities, each owing its own installation date.
--
--    11  district offices whose principal act is not yet established
--        Altadena Library District (1), Crescenta Valley Water District (1), La Cañada
--        Irrigation District (1), La Puente Valley County Water District (1), Palmdale Water
--        District (1), Palos Verdes Library District (1), Valley County Water District (1),
--        Walnut Valley Water District (3), Wrightwood Community Services District (1).
--        The county's calendar names health care, recreation-and-park, municipal water, water
--        agencies and water replenishment districts. It names none of these nine bodies. They
--        are PROBABLY § 10554 — the same calendar's § 10515 entry lists county water, community
--        services and irrigation districts among the districts it conducts elections for under
--        that part — but "probably" is how the 14 above would have been got wrong.
--
--     1  Los Angeles County Sheriff
--        The handbook states the rule as "noon on the first Monday in December following the
--        election" and calendars that entry at NOV. 30 (M) NOON, E+27. 30 November 2026 is a
--        Monday and is not in December; the first Monday in December 2026 is the 7th. Both
--        readings cannot hold and they are a week apart. Cited to Los Angeles County Charter,
--        Art. II § 6 and Art. IV § 13 — read the charter before seating this seat.
--
-- Those 122 are NOT written as basis='estimated' rows. An estimated row still carries a date,
-- and 122 guesses in a table the seeding script reads is a worse artefact than an empty space
-- the tracker can count. They are recorded in backend/data/ca-2026-swearing-in/RULES.md.

-- --------------------------------------------------------------------------------------------
-- The California 2026 local set, resolved once so every INSERT below reads the same rows.
-- --------------------------------------------------------------------------------------------
CREATE TEMP TABLE ca_2026_local ON COMMIT DROP AS
SELECT DISTINCT
       o.id    AS office_id,
       o.title AS title,
       d.district_type,
       regexp_replace(d.label, '\s*-\s*(Division|Trustee Area)\s*\S+$', '') AS body
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'ca'
   AND d.district_type IN ('SCHOOL', 'LOCAL', 'COUNTY', 'LOCAL_EXEC');

-- 197 — school and community college district boards.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, window_end_date, basis, rule_id, authority, source, notes)
SELECT office_id,
       DATE '2026-11-03',
       DATE '2026-12-11',
       DATE '2026-12-25',
       'statute',
       'ca-edc-5017',
       'Cal. Educ. Code § 5017 — four-year term commencing on the second Friday in December next succeeding the election',
       'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=5017. (read 2026-11-04)',
       'window_end_date is Cal. Educ. Code § 35143: the annual organizational meeting, at which the oath is administered, falls on a day within the 15-day period commencing with the second Friday in December. § 5017 keeps the predecessor discharging the duties until the successor qualifies. https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=35143. (read 2026-11-04)'
  FROM ca_2026_local
 WHERE district_type = 'SCHOOL'
ON CONFLICT (office_id, election_date) DO NOTHING;

-- 14 — municipal water districts, water agencies, water replenishment districts.
-- 🔴 BY NAME. See the header: a title predicate puts these on the wrong date by a month.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id,
       DATE '2026-11-03',
       DATE '2027-01-04',
       'published',
       'ca-water-principal-act',
       'Cal. Water Code § 60139, Water Code Appendix §§ 98-51 and 103-5(b), and Cal. Gov. Code § 24200 — noon on the first Monday in January following the election',
       'Los Angeles County Registrar-Recorder/County Clerk, Candidate Handbook and Resource Guide, November 3, 2026 General Election, Calendar of Events, "JAN. 4 (M) NOON E+62 — TAKING OF OFFICE — MUNICIPAL WATER, WATER AGENCIES, AND WATER REPLENISHMENT DISTRICTS" — https://content.lavote.gov/docs/rrcc/documents/candidate-handbook-general-election-complete-v-10.pdf (read 2026-11-04)',
       'NOT Cal. Elec. Code § 10554. These districts'' principal acts override the Uniform District Election Law''s first-Friday-in-December default, and the county lists them a month later than the health care and recreation-and-park districts.'
  FROM ca_2026_local
 WHERE body IN (
         'Antelope Valley-East Kern Water Agency',
         'Foothill Municipal Water District',
         'Las Virgenes Municipal Water District',
         'San Gabriel Valley Municipal Water District',
         'Santa Clarita Valley Water Agency',
         'Three Valleys Municipal Water District',
         'Water Replenishment District of Southern California',
         'West Basin Municipal Water District'
       )
ON CONFLICT (office_id, election_date) DO NOTHING;

-- 4 — judges of the superior court.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source)
SELECT office_id,
       DATE '2026-11-03',
       DATE '2027-01-04',
       'statute',
       'ca-const-vi-16c',
       'Cal. Const. art. VI § 16(c) — terms of judges of superior courts are six years beginning the Monday after January 1 following their election',
       'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CONS&sectionNum=SEC.%2016.&article=VI (read 2026-11-04)'
  FROM ca_2026_local
 WHERE title ILIKE 'Judge of the Superior Court%'
ON CONFLICT (office_id, election_date) DO NOTHING;

-- --------------------------------------------------------------------------------------------
-- Post-verify. Gates the DELTA this file creates, measured in its own transaction.
-- --------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_total   bigint;
  v_school  bigint;
  v_water   bigint;
  v_judges  bigint;
  v_set     bigint;
  v_bad     bigint;
BEGIN
  SELECT count(*) INTO v_set FROM ca_2026_local;
  IF v_set <> 337 THEN
    -- Not a totals-drift gate: this is the population THIS file reads, and if it has moved then
    -- the three counts below mean something different from what the header says they mean.
    RAISE EXCEPTION 'CC_0345: expected 337 California 2026 local offices, found % — re-measure before trusting the class counts', v_set;
  END IF;

  SELECT count(*) INTO v_school
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND rule_id = 'ca-edc-5017';
  SELECT count(*) INTO v_water
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND rule_id = 'ca-water-principal-act';
  SELECT count(*) INTO v_judges
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND rule_id = 'ca-const-vi-16c';

  IF v_school <> 197 THEN RAISE EXCEPTION 'CC_0345: expected 197 EDC 5017 rows, found %', v_school; END IF;
  IF v_water  <>  14 THEN RAISE EXCEPTION 'CC_0345: expected 14 water principal-act rows, found %', v_water;  END IF;
  IF v_judges <>   4 THEN RAISE EXCEPTION 'CC_0345: expected 4 superior court rows, found %', v_judges; END IF;

  SELECT count(*) INTO v_total
    FROM essentials.office_swearing_in WHERE election_date = DATE '2026-11-03';
  IF v_total <> 215 THEN
    RAISE EXCEPTION 'CC_0345: expected 215 rows for this election, found %', v_total;
  END IF;

  -- 🔴 NOT ONE ROW MAY BE ESTIMATED. The whole point of the 122 this file leaves alone is that
  -- an unsourced date is worse than an absent one, and a later edit that quietly relaxes that
  -- should trip here rather than reach the seeding script.
  SELECT count(*) INTO v_bad
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND basis NOT IN ('statute', 'published');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0345: % row(s) are not statute or published', v_bad;
  END IF;

  -- 🔴 NO ROW MAY SIT ON 2026-12-04. That is Cal. Elec. Code § 10554's first Friday in December
  -- — the blanket special-district date this migration exists to NOT apply. If a later edit
  -- reintroduces a title predicate for the district offices, 14 municipal water seats land here
  -- and this is the gate that says so.
  SELECT count(*) INTO v_bad
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND swearing_in_date = DATE '2026-12-04';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0345: % row(s) landed on the UDEL first-Friday date, which no California body in this set uses', v_bad;
  END IF;

  RAISE NOTICE 'CC_0345 OK: 215 rows (% school, % water, % judges) of 337; 122 left owed',
    v_school, v_water, v_judges;
END $$;
