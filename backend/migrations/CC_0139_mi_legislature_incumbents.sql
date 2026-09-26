-- CC_0139_mi_legislature_incumbents.sql
-- Knight Foundation program, wave MI-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0138, which creates the chambers and the 148 offices.
--
-- Seats all 148 Michigan legislative offices:
--    142 people created under the live name guard, external_id band -2770001 .. -2770144
--    2 people created with the guard scoped off -- genuine namesakes in other jurisdictions
--    4 people REUSED, not created -- production already holds them
--    0 offices left unseated. MICHIGAN HAS NO VACANCY.
--
-- 🔴🔴 FOUR PEOPLE ARE REUSED, AND THIS IS THE GUARD'S OWN "NORMAL CASE", NOT AN EXCEPTION.
-- Each is a sitting Michigan legislator who won a 2026 FEDERAL primary, so production already
-- carries them as a candidate. A second row would split their quotes and race edges away from
-- the person a voter sees. The duplicate guard says this in its own error text: "A sitting
-- officeholder running for a different seat is the normal case, not a different person."
--   · lower-11 -> -261302: Donavan McKinney, HD-11, won the Democratic primary for MI-13 on 2026-08-05 (defeating Rep. Shri Thanedar); production holds him as that candidate.
--   · upper-19 -> -260402: Sean McCann, SD-19, term-limited in the Senate, won the Democratic primary for MI-04 on 2026-08-04; production holds him as that candidate.
--   · upper-7 -> -261103: Jeremy Moss, SD-7, won the Democratic primary for MI-11 on 2026-08-04; production holds him as that candidate.
--   · upper-8 -> -400123: Mallory McMorrow, SD-8, is a 2026 U.S. Senate candidate; production holds her on the office literally titled "Candidate for U.S. Senate — Michigan".
--
-- 🔴🔴 AND TWO SHARE A NAME WITH A DIFFERENT PERSON IN ANOTHER JURISDICTION. The sweep was run
-- on the GUARD'S OWN KEY -- lower(btrim(first_name)), lower(btrim(last_name)) against ACTIVE
-- rows, which is exactly what essentials.politician_name_duplicate_guard compares -- and
-- controlled at 68 active rows sharing the surname 'Smith', so a zero would have been visible
-- as blindness rather than read as agreement. It returned exactly six, and the six split four
-- reuse / two distinct:
--   · lower-68: David Martin, HD-68 (Davison, Michigan), collides with -2745026 "David Martin", who SITS TODAY as a SOUTH CAROLINA state Representative for SC HD-26 (seated by the SC-2 wave).
--   · lower-83: John Fitzgerald, HD-83 (Wyoming, Michigan), collides with -2507000008 "John FitzGerald", who SITS TODAY as a BOSTON, MASSACHUSETTS city councillor for district 3. Note the differing capitalisation — the guard lowercases, so it caught what an exact match would not.
-- A person cannot simultaneously sit in another state's legislature, or on a Boston city
-- council, and in the Michigan House. This is the GA roster trap (2 of 4 name hits were a
-- Colorado senator and a Utah treasurer) and OH-2's Tom Young, recurring for a third time.
-- The override is scoped to that one statement and switched back off immediately, so the other
-- 142 rows were inserted with the guard LIVE.
--
-- 🔴 EVERY TERM IS OPEN-ENDED AT 'unknown' PRECISION, AND NOTHING IS GUESSED. No Michigan member
-- page publishes a service-start date; the pages carry biography, not tenure. Mich. Const.
-- art. IV, s 5 fixes commencement at noon on January 1st following election, but that governs a
-- member who ARRIVED AT A GENERAL ELECTION and says nothing about anyone who arrived by
-- appointment or special election mid-term. Writing 2025-01-01 for all 148 would be the San Jose
-- D8/D10 error at scale: a rule true of most rows, applied to rows it does not govern.
-- This is the GA-2 / IN-2 / MN-2 / OH-2 pattern. essentials.seat_officeholder() is NOT used: it
-- refuses a NULL term_start by design.
-- ▶ Dating these 148 arrivals is a recorded debt, not a thing to invent here.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate -- and every
-- House term here in fact expires 2026-12-31, which is exactly why writing it would be wrong.
--
-- 🔴 THE ROSTER WAS CHANGE-CHECKED PAGE BY PAGE, NOT TAKEN FROM A LIST. 147 of 148 member pages
-- were fetched and each one names its own member in its own <title>/<h1>; HD-4 publishes no page
-- at all and is documented below. A list page is not a change-check (MN-2: house.mn.gov listed a
-- member three months after he resigned).
-- ⚠ HD-4's link is the reason status codes are not the test: legislature.mi.gov still points
-- Karen Whitsett at housedems.com/whitsett, which REDIRECTS TO THE CAUCUS HOME PAGE and answers
-- HTTP 200 with an <h1> of "Michigan House Democrats". A dead member link that returns 200.
-- ⚠ HD-101's link (house.mi.gov/repdetail/repJosephFox) returns 404; the Republican caucus page
-- titled "Joseph Fox Posts" names him and District 101. A stale link is a fact about a link.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── 1. The 142 members with no active namesake ────────────────────────────────────

CREATE TEMP TABLE mi_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO mi_new_people(external_id, full_name, first_name, last_name) VALUES
  (-2770001, $$Tyrone Carter$$, $$Tyrone$$, $$Carter$$),
  (-2770002, $$Tullio Liberati$$, $$Tullio$$, $$Liberati$$),
  (-2770003, $$Alabas Farhat$$, $$Alabas$$, $$Farhat$$),
  (-2770004, $$Karen Whitsett$$, $$Karen$$, $$Whitsett$$),
  (-2770005, $$Regina Weiss$$, $$Regina$$, $$Weiss$$),
  (-2770006, $$Natalie Price$$, $$Natalie$$, $$Price$$),
  (-2770007, $$Tonya Myers Phillips$$, $$Tonya$$, $$Myers Phillips$$),
  (-2770008, $$Helena Scott$$, $$Helena$$, $$Scott$$),
  (-2770009, $$Joseph Tate$$, $$Joseph$$, $$Tate$$),
  (-2770010, $$Veronica Paiz$$, $$Veronica$$, $$Paiz$$),
  (-2770011, $$Kimberly Edwards$$, $$Kimberly$$, $$Edwards$$),
  (-2770012, $$Mai Xiong$$, $$Mai$$, $$Xiong$$),
  (-2770013, $$Mike McFall$$, $$Mike$$, $$McFall$$),
  (-2770014, $$Erin Byrnes$$, $$Erin$$, $$Byrnes$$),
  (-2770015, $$Stephanie Young$$, $$Stephanie$$, $$Young$$),
  (-2770016, $$Laurie Pohutsky$$, $$Laurie$$, $$Pohutsky$$),
  (-2770017, $$Jason Hoskins$$, $$Jason$$, $$Hoskins$$),
  (-2770018, $$Samantha Steckloff$$, $$Samantha$$, $$Steckloff$$),
  (-2770019, $$Noah Arbit$$, $$Noah$$, $$Arbit$$),
  (-2770020, $$Kelly Breen$$, $$Kelly$$, $$Breen$$),
  (-2770021, $$Matt Koleszar$$, $$Matt$$, $$Koleszar$$),
  (-2770022, $$Jason Morgan$$, $$Jason$$, $$Morgan$$),
  (-2770023, $$Ranjeev Puri$$, $$Ranjeev$$, $$Puri$$),
  (-2770024, $$Peter Herzberg$$, $$Peter$$, $$Herzberg$$),
  (-2770025, $$Dylan Wegela$$, $$Dylan$$, $$Wegela$$),
  (-2770026, $$Rylee Linting$$, $$Rylee$$, $$Linting$$),
  (-2770027, $$Jamie Thompson$$, $$Jamie$$, $$Thompson$$),
  (-2770028, $$James DeSana$$, $$James$$, $$DeSana$$),
  (-2770029, $$William Bruck$$, $$William$$, $$Bruck$$),
  (-2770030, $$Reggie Miller$$, $$Reggie$$, $$Miller$$),
  (-2770031, $$Jimmie Wilson$$, $$Jimmie$$, $$Wilson$$),
  (-2770032, $$Morgan Foreman$$, $$Morgan$$, $$Foreman$$),
  (-2770033, $$Nancy Jenkins-Arno$$, $$Nancy$$, $$Jenkins-Arno$$),
  (-2770034, $$Jennifer Wortz$$, $$Jennifer$$, $$Wortz$$),
  (-2770035, $$Steve Carra$$, $$Steve$$, $$Carra$$),
  (-2770036, $$Brad Paquette$$, $$Brad$$, $$Paquette$$),
  (-2770037, $$Joey Andrews$$, $$Joey$$, $$Andrews$$),
  (-2770038, $$Pauline Wendzel$$, $$Pauline$$, $$Wendzel$$),
  (-2770039, $$Matt Longjohn$$, $$Matt$$, $$Longjohn$$),
  (-2770040, $$Julie Rogers$$, $$Julie$$, $$Rogers$$),
  (-2770041, $$Matt Hall$$, $$Matt$$, $$Hall$$),
  (-2770042, $$Rachelle Smit$$, $$Rachelle$$, $$Smit$$),
  (-2770043, $$Steve Frisbie$$, $$Steve$$, $$Frisbie$$),
  (-2770044, $$Sarah Lightner$$, $$Sarah$$, $$Lightner$$),
  (-2770045, $$Kathy Schmaltz$$, $$Kathy$$, $$Schmaltz$$),
  (-2770046, $$Carrie Rheingans$$, $$Carrie$$, $$Rheingans$$),
  (-2770047, $$Jennifer Conlin$$, $$Jennifer$$, $$Conlin$$),
  (-2770048, $$Ann Bollin$$, $$Ann$$, $$Bollin$$),
  (-2770049, $$Jason Woolford$$, $$Jason$$, $$Woolford$$),
  (-2770050, $$Matt Maddock$$, $$Matt$$, $$Maddock$$),
  (-2770051, $$Mike Harris$$, $$Mike$$, $$Harris$$),
  (-2770052, $$Brenda Carter$$, $$Brenda$$, $$Carter$$),
  (-2770053, $$Donni Steele$$, $$Donni$$, $$Steele$$),
  (-2770054, $$Mark Tisdel$$, $$Mark$$, $$Tisdel$$),
  (-2770055, $$Sharon MacDonell$$, $$Sharon$$, $$MacDonell$$),
  (-2770056, $$Thomas Kuhn$$, $$Thomas$$, $$Kuhn$$),
  (-2770057, $$Ron Robinson$$, $$Ron$$, $$Robinson$$),
  (-2770058, $$Douglas Wozniak$$, $$Douglas$$, $$Wozniak$$),
  (-2770059, $$Joseph Aragona$$, $$Joseph$$, $$Aragona$$),
  (-2770060, $$Denise Mentzer$$, $$Denise$$, $$Mentzer$$),
  (-2770061, $$Alicia St. Germaine$$, $$Alicia$$, $$St. Germaine$$),
  (-2770062, $$Jay DeBoyer$$, $$Jay$$, $$DeBoyer$$),
  (-2770063, $$Joseph Pavlov$$, $$Joseph$$, $$Pavlov$$),
  (-2770064, $$Jaime Greene$$, $$Jaime$$, $$Greene$$),
  (-2770065, $$Josh Schriver$$, $$Josh$$, $$Schriver$$),
  (-2770066, $$Phil Green$$, $$Phil$$, $$Green$$),
  (-2770068, $$Jasper Martus$$, $$Jasper$$, $$Martus$$),
  (-2770069, $$Cynthia Neeley$$, $$Cynthia$$, $$Neeley$$),
  (-2770070, $$Brian BeGole$$, $$Brian$$, $$BeGole$$),
  (-2770071, $$Mike Mueller$$, $$Mike$$, $$Mueller$$),
  (-2770072, $$Julie Brixie$$, $$Julie$$, $$Brixie$$),
  (-2770073, $$Kara Hope$$, $$Kara$$, $$Hope$$),
  (-2770074, $$Penelope Tsernoglou$$, $$Penelope$$, $$Tsernoglou$$),
  (-2770075, $$Angela Witwer$$, $$Angela$$, $$Witwer$$),
  (-2770076, $$Emily Dievendorf$$, $$Emily$$, $$Dievendorf$$),
  (-2770077, $$Gina Johnsen$$, $$Gina$$, $$Johnsen$$),
  (-2770078, $$Angela Rigas$$, $$Angela$$, $$Rigas$$),
  (-2770079, $$Phil Skaggs$$, $$Phil$$, $$Skaggs$$),
  (-2770080, $$Stephen Wooden$$, $$Stephen$$, $$Wooden$$),
  (-2770081, $$Kristian Grant$$, $$Kristian$$, $$Grant$$),
  (-2770083, $$Carol Glanville$$, $$Carol$$, $$Glanville$$),
  (-2770084, $$Bradley Slagh$$, $$Bradley$$, $$Slagh$$),
  (-2770085, $$Nancy DeBoer$$, $$Nancy$$, $$DeBoer$$),
  (-2770086, $$Will Snyder$$, $$Will$$, $$Snyder$$),
  (-2770087, $$Greg VanWoerkom$$, $$Greg$$, $$VanWoerkom$$),
  (-2770088, $$Luke Meerman$$, $$Luke$$, $$Meerman$$),
  (-2770089, $$Bryan Posthumus$$, $$Bryan$$, $$Posthumus$$),
  (-2770090, $$Pat Outman$$, $$Pat$$, $$Outman$$),
  (-2770091, $$Jerry Neyer$$, $$Jerry$$, $$Neyer$$),
  (-2770092, $$Tim Kelly$$, $$Tim$$, $$Kelly$$),
  (-2770093, $$Amos O'Neal$$, $$Amos$$, $$O'Neal$$),
  (-2770094, $$Bill Schuette$$, $$Bill$$, $$Schuette$$),
  (-2770095, $$Timothy Beson$$, $$Timothy$$, $$Beson$$),
  (-2770096, $$Matt Bierlein$$, $$Matt$$, $$Bierlein$$),
  (-2770097, $$Gregory Alexander$$, $$Gregory$$, $$Alexander$$),
  (-2770098, $$Mike Hoadley$$, $$Mike$$, $$Hoadley$$),
  (-2770099, $$Tom Kunse$$, $$Tom$$, $$Kunse$$),
  (-2770100, $$Joseph Fox$$, $$Joseph$$, $$Fox$$),
  (-2770101, $$Curtis VanderWall$$, $$Curtis$$, $$VanderWall$$),
  (-2770102, $$Betsy Coffia$$, $$Betsy$$, $$Coffia$$),
  (-2770103, $$John Roth$$, $$John$$, $$Roth$$),
  (-2770104, $$Ken Borton$$, $$Ken$$, $$Borton$$),
  (-2770105, $$Cameron Cavitt$$, $$Cameron$$, $$Cavitt$$),
  (-2770106, $$Parker Fairbairn$$, $$Parker$$, $$Fairbairn$$),
  (-2770107, $$David Prestin$$, $$David$$, $$Prestin$$),
  (-2770108, $$Karl Bohnak$$, $$Karl$$, $$Bohnak$$),
  (-2770109, $$Gregory Markkanen$$, $$Gregory$$, $$Markkanen$$),
  (-2770110, $$Erika Geiss$$, $$Erika$$, $$Geiss$$),
  (-2770111, $$Sylvia A. Santana$$, $$Sylvia$$, $$Santana$$),
  (-2770112, $$Stephanie Chang$$, $$Stephanie$$, $$Chang$$),
  (-2770113, $$Darrin Camilleri$$, $$Darrin$$, $$Camilleri$$),
  (-2770114, $$Dayna Polehanki$$, $$Dayna$$, $$Polehanki$$),
  (-2770115, $$Mary Cavanagh$$, $$Mary$$, $$Cavanagh$$),
  (-2770116, $$Michael Webber$$, $$Michael$$, $$Webber$$),
  (-2770117, $$Paul Wojno$$, $$Paul$$, $$Wojno$$),
  (-2770118, $$Veronica Klinefelt$$, $$Veronica$$, $$Klinefelt$$),
  (-2770119, $$Kevin Hertel$$, $$Kevin$$, $$Hertel$$),
  (-2770120, $$Rosemary Bayer$$, $$Rosemary$$, $$Bayer$$),
  (-2770121, $$Sue Shink$$, $$Sue$$, $$Shink$$),
  (-2770122, $$Jeff Irwin$$, $$Jeff$$, $$Irwin$$),
  (-2770123, $$Joseph N. Bellino Jr.$$, $$Joseph$$, $$Bellino$$),
  (-2770124, $$Jonathan Lindsey$$, $$Jonathan$$, $$Lindsey$$),
  (-2770125, $$Thomas A. Albert$$, $$Thomas$$, $$Albert$$),
  (-2770126, $$Aric Nesbitt$$, $$Aric$$, $$Nesbitt$$),
  (-2770127, $$Sarah Anthony$$, $$Sarah$$, $$Anthony$$),
  (-2770128, $$Lana Theis$$, $$Lana$$, $$Theis$$),
  (-2770129, $$Jim Runestad$$, $$Jim$$, $$Runestad$$),
  (-2770130, $$Ruth A. Johnson$$, $$Ruth$$, $$Johnson$$),
  (-2770131, $$Dan Lauwers$$, $$Dan$$, $$Lauwers$$),
  (-2770132, $$Kevin Daley$$, $$Kevin$$, $$Daley$$),
  (-2770133, $$John Cherry$$, $$John$$, $$Cherry$$),
  (-2770134, $$Sam Singh$$, $$Sam$$, $$Singh$$),
  (-2770135, $$Winnie Brinks$$, $$Winnie$$, $$Brinks$$),
  (-2770136, $$Mark E. Huizenga$$, $$Mark$$, $$Huizenga$$),
  (-2770137, $$Roger Victory$$, $$Roger$$, $$Victory$$),
  (-2770138, $$Jon C. Bumstead$$, $$Jon$$, $$Bumstead$$),
  (-2770139, $$Rick Outman$$, $$Rick$$, $$Outman$$),
  (-2770140, $$Roger Hauck$$, $$Roger$$, $$Hauck$$),
  (-2770141, $$Chedrick Greene$$, $$Chedrick$$, $$Greene$$),
  (-2770142, $$Michele Hoitenga$$, $$Michele$$, $$Hoitenga$$),
  (-2770143, $$John Damoose$$, $$John$$, $$Damoose$$),
  (-2770144, $$Edward W. McBroom$$, $$Edward$$, $$McBroom$$);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       $$Michigan Legislature combined legislator list, https://legislature.mi.gov/Legislature/Legislators; reconciled against the Michigan Senate's own list, https://senate.michigan.gov/senators/all-senators/, the Michigan House list, https://house.mi.gov/AllRepresentatives, and Open States, https://data.openstates.org/people/current/mi.csv; change-checked against 147 individual member pages (HD-4 publishes none), every one of which names its own member in its own title; read 2026-09-24 (MI-2) (CC_0139, MI-2)$$,
       true, true
FROM mi_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. 2 members who share a name with a DIFFERENT person — guard lifted ──────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE mi_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO mi_namesake_people(external_id, full_name, first_name, last_name) VALUES
  (-2770067, $$David Martin$$, $$David$$, $$Martin$$),
  (-2770082, $$John Fitzgerald$$, $$John$$, $$Fitzgerald$$);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       $$Michigan Legislature combined legislator list, https://legislature.mi.gov/Legislature/Legislators; reconciled against the Michigan Senate's own list, https://senate.michigan.gov/senators/all-senators/, the Michigan House list, https://house.mi.gov/AllRepresentatives, and Open States, https://data.openstates.org/people/current/mi.csv; change-checked against 147 individual member pages (HD-4 publishes none), every one of which names its own member in its own title; read 2026-09-24 (MI-2) (CC_0139, MI-2)$$,
       true, true
FROM mi_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 2b. The 4 reused rows are INCUMBENTS NOW ──────────────────────────────────
--
-- 🔴🔴 THE REACHABILITY GATE CAUGHT THIS AND NOTHING ELSE WOULD HAVE. All four reused rows were
-- created as CANDIDATES and therefore carry is_incumbent = false. The reps feed that address
-- search serves requires
--     (is_active OR is_vacant) AND coalesce(is_incumbent, true) AND title NOT ILIKE 'Candidate for%'
-- so seating them left FOUR DISTRICTS -- HD-11, SD-7, SD-8 and SD-19 -- with a correctly seated
-- member whom no resident could ever surface. Every count in this migration was right: 148
-- offices, 148 terms, 148 seated. The person was simply invisible.
-- ▶ REUSING A ROW MEANS INHERITING EVERY FLAG IT WAS CREATED WITH. A candidate row is not a
--   blank person; it carries a claim about what that person IS, and seating them changes it.
-- ⚠ coalesce(is_incumbent, true) means a NULL passes and only an explicit FALSE hides. The 144
--   rows created above set is_incumbent = true outright, which is why only the reused four were
--   affected — a difference invisible in any count of offices, terms or holders.
--
-- Guarded on the current value, so a re-run updates 0 rows.

UPDATE essentials.politicians
   SET is_incumbent = true
 WHERE external_id IN (-261302, -260402, -261103, -400123)
   AND is_incumbent IS DISTINCT FROM true;

-- ─── 3. The 148 terms ─────────────────────────────────────────────────────────
-- Keyed on (geo_id, district_type), never geo_id alone: '26031' is Senate District 31 AND a
-- Michigan county. The 4 reused external_ids below are NOT in the MI-2 band -- they are the
-- existing rows named in the header.

CREATE TEMP TABLE mi_terms(geo_id text, district_type text, external_id bigint) ON COMMIT DROP;

INSERT INTO mi_terms(geo_id, district_type, external_id) VALUES
  ($$26001$$, $$STATE_LOWER$$, -2770001::bigint),
  ($$26002$$, $$STATE_LOWER$$, -2770002::bigint),
  ($$26003$$, $$STATE_LOWER$$, -2770003::bigint),
  ($$26004$$, $$STATE_LOWER$$, -2770004::bigint),
  ($$26005$$, $$STATE_LOWER$$, -2770005::bigint),
  ($$26006$$, $$STATE_LOWER$$, -2770006::bigint),
  ($$26007$$, $$STATE_LOWER$$, -2770007::bigint),
  ($$26008$$, $$STATE_LOWER$$, -2770008::bigint),
  ($$26009$$, $$STATE_LOWER$$, -2770009::bigint),
  ($$26010$$, $$STATE_LOWER$$, -2770010::bigint),
  ($$26011$$, $$STATE_LOWER$$, -261302::bigint),
  ($$26012$$, $$STATE_LOWER$$, -2770011::bigint),
  ($$26013$$, $$STATE_LOWER$$, -2770012::bigint),
  ($$26014$$, $$STATE_LOWER$$, -2770013::bigint),
  ($$26015$$, $$STATE_LOWER$$, -2770014::bigint),
  ($$26016$$, $$STATE_LOWER$$, -2770015::bigint),
  ($$26017$$, $$STATE_LOWER$$, -2770016::bigint),
  ($$26018$$, $$STATE_LOWER$$, -2770017::bigint),
  ($$26019$$, $$STATE_LOWER$$, -2770018::bigint),
  ($$26020$$, $$STATE_LOWER$$, -2770019::bigint),
  ($$26021$$, $$STATE_LOWER$$, -2770020::bigint),
  ($$26022$$, $$STATE_LOWER$$, -2770021::bigint),
  ($$26023$$, $$STATE_LOWER$$, -2770022::bigint),
  ($$26024$$, $$STATE_LOWER$$, -2770023::bigint),
  ($$26025$$, $$STATE_LOWER$$, -2770024::bigint),
  ($$26026$$, $$STATE_LOWER$$, -2770025::bigint),
  ($$26027$$, $$STATE_LOWER$$, -2770026::bigint),
  ($$26028$$, $$STATE_LOWER$$, -2770027::bigint),
  ($$26029$$, $$STATE_LOWER$$, -2770028::bigint),
  ($$26030$$, $$STATE_LOWER$$, -2770029::bigint),
  ($$26031$$, $$STATE_LOWER$$, -2770030::bigint),
  ($$26032$$, $$STATE_LOWER$$, -2770031::bigint),
  ($$26033$$, $$STATE_LOWER$$, -2770032::bigint),
  ($$26034$$, $$STATE_LOWER$$, -2770033::bigint),
  ($$26035$$, $$STATE_LOWER$$, -2770034::bigint),
  ($$26036$$, $$STATE_LOWER$$, -2770035::bigint),
  ($$26037$$, $$STATE_LOWER$$, -2770036::bigint),
  ($$26038$$, $$STATE_LOWER$$, -2770037::bigint),
  ($$26039$$, $$STATE_LOWER$$, -2770038::bigint),
  ($$26040$$, $$STATE_LOWER$$, -2770039::bigint),
  ($$26041$$, $$STATE_LOWER$$, -2770040::bigint),
  ($$26042$$, $$STATE_LOWER$$, -2770041::bigint),
  ($$26043$$, $$STATE_LOWER$$, -2770042::bigint),
  ($$26044$$, $$STATE_LOWER$$, -2770043::bigint),
  ($$26045$$, $$STATE_LOWER$$, -2770044::bigint),
  ($$26046$$, $$STATE_LOWER$$, -2770045::bigint),
  ($$26047$$, $$STATE_LOWER$$, -2770046::bigint),
  ($$26048$$, $$STATE_LOWER$$, -2770047::bigint),
  ($$26049$$, $$STATE_LOWER$$, -2770048::bigint),
  ($$26050$$, $$STATE_LOWER$$, -2770049::bigint),
  ($$26051$$, $$STATE_LOWER$$, -2770050::bigint),
  ($$26052$$, $$STATE_LOWER$$, -2770051::bigint),
  ($$26053$$, $$STATE_LOWER$$, -2770052::bigint),
  ($$26054$$, $$STATE_LOWER$$, -2770053::bigint),
  ($$26055$$, $$STATE_LOWER$$, -2770054::bigint),
  ($$26056$$, $$STATE_LOWER$$, -2770055::bigint),
  ($$26057$$, $$STATE_LOWER$$, -2770056::bigint),
  ($$26058$$, $$STATE_LOWER$$, -2770057::bigint),
  ($$26059$$, $$STATE_LOWER$$, -2770058::bigint),
  ($$26060$$, $$STATE_LOWER$$, -2770059::bigint),
  ($$26061$$, $$STATE_LOWER$$, -2770060::bigint),
  ($$26062$$, $$STATE_LOWER$$, -2770061::bigint),
  ($$26063$$, $$STATE_LOWER$$, -2770062::bigint),
  ($$26064$$, $$STATE_LOWER$$, -2770063::bigint),
  ($$26065$$, $$STATE_LOWER$$, -2770064::bigint),
  ($$26066$$, $$STATE_LOWER$$, -2770065::bigint),
  ($$26067$$, $$STATE_LOWER$$, -2770066::bigint),
  ($$26068$$, $$STATE_LOWER$$, -2770067::bigint),
  ($$26069$$, $$STATE_LOWER$$, -2770068::bigint),
  ($$26070$$, $$STATE_LOWER$$, -2770069::bigint),
  ($$26071$$, $$STATE_LOWER$$, -2770070::bigint),
  ($$26072$$, $$STATE_LOWER$$, -2770071::bigint),
  ($$26073$$, $$STATE_LOWER$$, -2770072::bigint),
  ($$26074$$, $$STATE_LOWER$$, -2770073::bigint),
  ($$26075$$, $$STATE_LOWER$$, -2770074::bigint),
  ($$26076$$, $$STATE_LOWER$$, -2770075::bigint),
  ($$26077$$, $$STATE_LOWER$$, -2770076::bigint),
  ($$26078$$, $$STATE_LOWER$$, -2770077::bigint),
  ($$26079$$, $$STATE_LOWER$$, -2770078::bigint),
  ($$26080$$, $$STATE_LOWER$$, -2770079::bigint),
  ($$26081$$, $$STATE_LOWER$$, -2770080::bigint),
  ($$26082$$, $$STATE_LOWER$$, -2770081::bigint),
  ($$26083$$, $$STATE_LOWER$$, -2770082::bigint),
  ($$26084$$, $$STATE_LOWER$$, -2770083::bigint),
  ($$26085$$, $$STATE_LOWER$$, -2770084::bigint),
  ($$26086$$, $$STATE_LOWER$$, -2770085::bigint),
  ($$26087$$, $$STATE_LOWER$$, -2770086::bigint),
  ($$26088$$, $$STATE_LOWER$$, -2770087::bigint),
  ($$26089$$, $$STATE_LOWER$$, -2770088::bigint),
  ($$26090$$, $$STATE_LOWER$$, -2770089::bigint),
  ($$26091$$, $$STATE_LOWER$$, -2770090::bigint),
  ($$26092$$, $$STATE_LOWER$$, -2770091::bigint),
  ($$26093$$, $$STATE_LOWER$$, -2770092::bigint),
  ($$26094$$, $$STATE_LOWER$$, -2770093::bigint),
  ($$26095$$, $$STATE_LOWER$$, -2770094::bigint),
  ($$26096$$, $$STATE_LOWER$$, -2770095::bigint),
  ($$26097$$, $$STATE_LOWER$$, -2770096::bigint),
  ($$26098$$, $$STATE_LOWER$$, -2770097::bigint),
  ($$26099$$, $$STATE_LOWER$$, -2770098::bigint),
  ($$26100$$, $$STATE_LOWER$$, -2770099::bigint),
  ($$26101$$, $$STATE_LOWER$$, -2770100::bigint),
  ($$26102$$, $$STATE_LOWER$$, -2770101::bigint),
  ($$26103$$, $$STATE_LOWER$$, -2770102::bigint),
  ($$26104$$, $$STATE_LOWER$$, -2770103::bigint),
  ($$26105$$, $$STATE_LOWER$$, -2770104::bigint),
  ($$26106$$, $$STATE_LOWER$$, -2770105::bigint),
  ($$26107$$, $$STATE_LOWER$$, -2770106::bigint),
  ($$26108$$, $$STATE_LOWER$$, -2770107::bigint),
  ($$26109$$, $$STATE_LOWER$$, -2770108::bigint),
  ($$26110$$, $$STATE_LOWER$$, -2770109::bigint),
  ($$26001$$, $$STATE_UPPER$$, -2770110::bigint),
  ($$26002$$, $$STATE_UPPER$$, -2770111::bigint),
  ($$26003$$, $$STATE_UPPER$$, -2770112::bigint),
  ($$26004$$, $$STATE_UPPER$$, -2770113::bigint),
  ($$26005$$, $$STATE_UPPER$$, -2770114::bigint),
  ($$26006$$, $$STATE_UPPER$$, -2770115::bigint),
  ($$26007$$, $$STATE_UPPER$$, -261103::bigint),
  ($$26008$$, $$STATE_UPPER$$, -400123::bigint),
  ($$26009$$, $$STATE_UPPER$$, -2770116::bigint),
  ($$26010$$, $$STATE_UPPER$$, -2770117::bigint),
  ($$26011$$, $$STATE_UPPER$$, -2770118::bigint),
  ($$26012$$, $$STATE_UPPER$$, -2770119::bigint),
  ($$26013$$, $$STATE_UPPER$$, -2770120::bigint),
  ($$26014$$, $$STATE_UPPER$$, -2770121::bigint),
  ($$26015$$, $$STATE_UPPER$$, -2770122::bigint),
  ($$26016$$, $$STATE_UPPER$$, -2770123::bigint),
  ($$26017$$, $$STATE_UPPER$$, -2770124::bigint),
  ($$26018$$, $$STATE_UPPER$$, -2770125::bigint),
  ($$26019$$, $$STATE_UPPER$$, -260402::bigint),
  ($$26020$$, $$STATE_UPPER$$, -2770126::bigint),
  ($$26021$$, $$STATE_UPPER$$, -2770127::bigint),
  ($$26022$$, $$STATE_UPPER$$, -2770128::bigint),
  ($$26023$$, $$STATE_UPPER$$, -2770129::bigint),
  ($$26024$$, $$STATE_UPPER$$, -2770130::bigint),
  ($$26025$$, $$STATE_UPPER$$, -2770131::bigint),
  ($$26026$$, $$STATE_UPPER$$, -2770132::bigint),
  ($$26027$$, $$STATE_UPPER$$, -2770133::bigint),
  ($$26028$$, $$STATE_UPPER$$, -2770134::bigint),
  ($$26029$$, $$STATE_UPPER$$, -2770135::bigint),
  ($$26030$$, $$STATE_UPPER$$, -2770136::bigint),
  ($$26031$$, $$STATE_UPPER$$, -2770137::bigint),
  ($$26032$$, $$STATE_UPPER$$, -2770138::bigint),
  ($$26033$$, $$STATE_UPPER$$, -2770139::bigint),
  ($$26034$$, $$STATE_UPPER$$, -2770140::bigint),
  ($$26035$$, $$STATE_UPPER$$, -2770141::bigint),
  ($$26036$$, $$STATE_UPPER$$, -2770142::bigint),
  ($$26037$$, $$STATE_UPPER$$, -2770143::bigint),
  ($$26038$$, $$STATE_UPPER$$, -2770144::bigint);

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       $$Michigan Legislature combined legislator list, https://legislature.mi.gov/Legislature/Legislators; reconciled against the Michigan Senate's own list, https://senate.michigan.gov/senators/all-senators/, the Michigan House list, https://house.mi.gov/AllRepresentatives, and Open States, https://data.openstates.org/people/current/mi.csv; change-checked against 147 individual member pages (HD-4 publishes none), every one of which names its own member in its own title; read 2026-09-24 (MI-2) (CC_0139, MI-2)$$
FROM mi_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'mi'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c
  ON c.id = o.chamber_id AND c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── post-verify gate ─────────────────────────────────────────────────────────
DO $gate$
DECLARE
  v_terms   integer;
  v_people  integer;
  v_seated  integer;
  v_dated   integer;
  v_ended   integer;
  v_two     integer;
  v_reused  integer;
  v_hidden  integer;
BEGIN
  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND c.name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$);
  IF v_terms <> 148 THEN
    RAISE EXCEPTION 'MI-2 gate 1: expected 148 terms, found %', v_terms;
  END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2770144 AND -2770001;
  IF v_people <> 144 THEN
    RAISE EXCEPTION 'MI-2 gate 2: expected 144 new people in the MI-2 band, found %', v_people;
  END IF;

  -- 🔴 COUNT och.politician_id, NOT och.*: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL holder rather than an absent row and count(*) passes vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND c.name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$);
  IF v_seated <> 148 THEN
    RAISE EXCEPTION 'MI-2 gate 3: expected 148 seated offices, found %', v_seated;
  END IF;

  SELECT count(*) FILTER (WHERE t.term_start IS NOT NULL OR t.start_precision <> 'unknown'),
         count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_dated, v_ended
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND c.name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$);
  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 4: % term(s) carry an invented start date or precision', v_dated;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 5: % term(s) carry a term_end — a future end silently self-vacates the seat', v_ended;
  END IF;

  -- The exclusion constraint forbids two people on one office. It CANNOT see one person on two,
  -- which is the direction that matters when four rows are reused.
  SELECT count(*) INTO v_two FROM (
    SELECT t.politician_id
      FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
       AND c.name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$)
     GROUP BY t.politician_id HAVING count(*) > 1) x;
  IF v_two <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 6: % person(s) hold two Michigan legislative seats', v_two;
  END IF;

  -- The four reused rows must be the ones named in the header, seated on the named seats.
  SELECT count(*) INTO v_reused
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND p.external_id IN (-261302, -260402, -261103, -400123);
  IF v_reused <> 4 THEN
    RAISE EXCEPTION 'MI-2 gate 7: expected 4 reused people seated, found %', v_reused;
  END IF;

  -- Gate 8: every seated Michigan legislator must survive the REPS FEED predicate, not merely
  -- exist. This is the one the reachability gate had to teach us; it belongs in the migration.
  SELECT count(*) INTO v_hidden
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND c.name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$)
     AND NOT ((p.is_active = true OR o.is_vacant = true)
              AND coalesce(p.is_incumbent, true) = true
              AND coalesce(o.title, '') NOT ILIKE 'Candidate for%');
  IF v_hidden <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 8: % seated legislator(s) are hidden from the reps feed — seated but unreachable by any resident', v_hidden;
  END IF;

  RAISE NOTICE 'CC_0139 OK: 148 terms, 148 seated, 0 dated, 0 ended, 0 hidden from the reps feed, 144 new people, 4 reused.';
END
$gate$;

COMMIT;
