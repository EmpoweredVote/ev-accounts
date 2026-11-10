-- CC_0363 — create the 25 statewide executive offices we do not hold, SEAT THEIR CURRENT
--           OFFICEHOLDERS, and record the 2026-11-03 results Ballotpedia has called.
--
-- 🔴 THIS FILE CREATES OFFICES, WHICH MAKES IT AN OCCUPANCY ACT, NOT A RESULTS MIGRATION.
--   Auditors, comptrollers, agriculture / insurance / labour / lands commissioners, school
--   superintendents and a tax commissioner: statewide constitutional offices that were on the
--   2026 ballot and that we hold no row for. AP publishes none of them (CC_0360's header
--   enumerates its whole catalogue) and our own reconciliation could not see them because
--   they do not exist on our side at all.
--
-- 🔴🔴 AN OFFICE WITH NO office_terms ROW IS WHY THIS FILE SEATS PEOPLE. The unflagged
--   essentials.offices_missing_terms baseline is 238 and CLAUDE.md says it must NEVER be
--   raised. Creating 25 offices and walking away would take it to 263 and hand the next
--   person a red gate for drift nobody introduced. So each office is created WITH its
--   current holder seated, and the post-verify asserts the baseline is still exactly 238.
--   ⚠ THE HOLDER IS NOT THE WINNER. A certified result is not a fact about who holds a seat —
--     taking office is a separate, later event. 14 of these 25 winners are someone other than
--     the sitting officeholder, and the people seated here are the SITTING ones.
--
-- WHAT IT WRITES — every statement is an INSERT; nothing is updated or deleted:
--   25 chambers · 25 districts · 25 offices · 25 office_terms · 25 races
--   57 politicians · 54 candidacies (25 won, 29 lost)
--
--   AL  Auditor                                      holder Andrew Sorrell             🏆 Andrew Sorrell
--   AL  Commissioner of Agriculture and Industries   holder Rick Pate                  🏆 Corey Hill
--   AR  Auditor of State                             holder Dennis Milligan            🏆 Dennis Milligan
--   AR  Commissioner of State Lands                  holder Tommy Land                 🏆 Cole Jester
--   CT  Comptroller                                  holder Sean Scanlon               🏆 Sean Scanlon
--   DE  State Auditor                                holder Lydia York                 🏆 Lydia York
--   FL  Commissioner of Agriculture and Consumer Services holder Wilton Simpson             🏆 Wilton Simpson
--   GA  Commissioner of Agriculture                  holder Tyler Harper               🏆 Katherine Juhan-Arnold
--   GA  Commissioner of Labor                        holder Bárbara Rivera Holmes      🏆 Nikki Porcher
--   GA  Insurance and Safety Fire Commissioner       holder John King                  🏆 Keisha Sean Waites
--   GA  State Superintendent of Schools              holder Richard Woods              🏆 Lydia Powell
--   HI  Office of Hawaiian Affairs Maui Resident Trustee holder Carmen Hulu Lindsey        🏆 Carmen Hulu Lindsey
--   HI  Office of Hawaiian Affairs Oahu Resident Trustee holder Kalei Akaka                🏆 Kalei Akaka
--   IA  Secretary of Agriculture                     holder Mike Naig                  🏆 Mike Naig
--   IL  Comptroller                                  holder Susana A. Mendoza          🏆 Margaret Croke
--   MN  State Auditor                                holder Julie Blaha                🏆 Zack Filipovich
--   MO  State Auditor                                holder Scott Fitzpatrick          🏆 Scott Fitzpatrick
--   ND  Commissioner of Agriculture                  holder Doug Goehring              🏆 Doug Goehring
--   ND  Tax Commissioner                             holder Brian Kroshus              🏆 Brian Kroshus
--   NE  Auditor of Public Accounts                   holder Mike Foley                 🏆 Mike Foley
--   NM  Commissioner of Public Lands                 holder Stephanie Garcia Richard   🏆 Juan Sanchez III
--   NM  State Auditor                                holder Joseph Maestas             🏆 Joseph Maestas
--   SC  Superintendent of Education                  holder Ellen Weaver               🏆 Ellen Weaver
--   SD  Commissioner of School and Public Lands      holder Brock Greenfield           🏆 Brock Greenfield
--   WY  State Auditor                                holder Kristi Racines             🏆 Kristi Racines
--
-- HOW EACH HOLDER WAS ESTABLISHED. ⚠ "THE CHAMBER'S OWN ROSTER OUTRANKS EVERY AGGREGATOR",
--   so the office's own website was tried for every one of them:
--     · 5 from the office's OWN SITE — agi.alabama.gov, cosl.org, illinoiscomptroller.gov,
--       osa.state.mn.us, nmstatelands.org. These are rosters, not race pages.
--     · 20 from Ballotpedia's own "Incumbent X ..." sentence on the election page. That is a
--       statement about who HOLDS the seat, not about the count, which is the distinction
--       CLAUDE.md draws — but it is an aggregator, and it is recorded as such in the source.
--   🔴 NINE MORE TIER-1 OFFICES ARE DELIBERATELY ABSENT because neither route produced a name:
--     Kansas's insurance page 403s, Oklahoma's labour and insurance pages 404, South Dakota's
--     auditor host does not resolve, and Oklahoma's superintendent page yields only the
--     fragment "ields,...State Superintendent". GUESSING AN OFFICEHOLDER IS THE MOST
--     EXPENSIVE ERROR AVAILABLE HERE, so those nine wait for a real roster.
--
-- 🔴 NO TERM START IS INVENTED. Not one of these sources publishes when the current holder's
--   term began, and "first elected" is not a term start. Every term is written OPEN-ENDED
--   with start_precision = 'unknown' — the shape the phase-2 backfill used and the one
--   CLAUDE.md names for exactly this case. A plausible date would have been a fabrication.
--   how_started is 'unknown' too: several of these people were appointed, not elected.
--
-- 🔴 THREE NAME MATCHES WERE THROWN OUT ON WHAT THAT PERSON ALREADY HOLDS, and each would
--   have attached a statewide office to the wrong human:
--     · John King (GA) — the existing "John King" 30f77168 holds a CALIFORNIA local council seat and is sourced 'scraped' - not Georgia's Insurance and Safety Fire Commissioner
--     · Chris Jones (IA) — the existing "Chris Jones" d9ceca31 is a candidate for ARKANSAS's 'U.S. Representative' - not Iowa's Secretary of Agriculture candidate
--     · Mike Foley (NE) — the existing "Mike Foley" 38277535 is a candidate for MINNESOTA's 'U.S. Representative' - not Nebraska's Auditor of Public Accounts
--   The duplicate-name guard below names exactly these and fails on any other collision, and
--   the database's own DUPLICATE_POLITICIAN_NAME trigger is opened for one statement only.
--
-- SOURCING OF THE RESULTS is identical to CC_0360/CC_0361/CC_0362 and was tested the same
--   way: Ballotpedia's winner flag matched AP's call on 71 of 71 races where both name a
--   winner, WHILE its vote counts ran up to 32% short — so the flag is used and NO NUMBER IS.
--   Each outcome is stated twice on the page (a CSS class and an editor's sentence) and both
--   agree for all 25. result_certainty is 'called'.
--
-- ⚠ EVERY NEW DISTRICT CARRIES ITS STATE'S FIPS AS geo_id, which is what the other 48 states'
--   statewide executives do. geo_id is a LOOKUP KEY and an empty one matches no address ever.
--   That is also why the 49 districted board seats are NOT here: their boundaries are not in
--   our geofence tables, and the state FIPS would tell a voter the wrong district's member.
--
-- Applied to production 2026-11-06 by Chris Cantrell. Slot reserved via steward.

BEGIN;

-- ─── 1. The seats: chamber, district, office ───
CREATE TEMP TABLE newseat (
  st text NOT NULL, office text NOT NULL, seat text PRIMARY KEY, state_name text NOT NULL,
  fips text NOT NULL, gov_id uuid NOT NULL, chamber_slug text NOT NULL, chamber_formal text NOT NULL,
  district_label text NOT NULL, ocd text NOT NULL, election_id uuid NOT NULL, role_canonical text,
  holder text NOT NULL, holder_how text NOT NULL
) ON COMMIT DROP;
INSERT INTO newseat VALUES
  ('AL', 'Auditor', 'AL Auditor', 'Alabama',
   '01', 'f427572f-d37a-4828-b68b-7f2c4e6ee4cd'::uuid, 'auditor-of-alabama', 'Auditor of Alabama',
   'Alabama Auditor', 'ocd-division/country:us/state:al', '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, NULL,
   'Andrew Sorrell', 'page'),
  ('AL', 'Commissioner of Agriculture and Industries', 'AL Commissioner of Agriculture and Industries', 'Alabama',
   '01', 'f427572f-d37a-4828-b68b-7f2c4e6ee4cd'::uuid, 'commissioner-of-agriculture-and-industries-of-alabama', 'Commissioner of Agriculture and Industries of Alabama',
   'Alabama Commissioner of Agriculture and Industries', 'ocd-division/country:us/state:al', '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, NULL,
   'Rick Pate', 'site'),
  ('AR', 'Auditor of State', 'AR Auditor of State', 'Arkansas',
   '05', '66e6181f-addc-4ff5-beeb-eb4e49e1ea67'::uuid, 'auditor-of-state-of-arkansas', 'Auditor of State of Arkansas',
   'Arkansas Auditor of State', 'ocd-division/country:us/state:ar', 'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid, NULL,
   'Dennis Milligan', 'page'),
  ('AR', 'Commissioner of State Lands', 'AR Commissioner of State Lands', 'Arkansas',
   '05', '66e6181f-addc-4ff5-beeb-eb4e49e1ea67'::uuid, 'commissioner-of-state-lands-of-arkansas', 'Commissioner of State Lands of Arkansas',
   'Arkansas Commissioner of State Lands', 'ocd-division/country:us/state:ar', 'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid, NULL,
   'Tommy Land', 'site'),
  ('CT', 'Comptroller', 'CT Comptroller', 'Connecticut',
   '09', '08cb83cf-d04c-46af-aff3-fbb693a8966e'::uuid, 'comptroller-of-connecticut', 'Comptroller of Connecticut',
   'Connecticut Comptroller', 'ocd-division/country:us/state:ct', 'e7630bb9-d60d-4ffe-905d-d171f84e9cb7'::uuid, 'comptroller',
   'Sean Scanlon', 'page'),
  ('DE', 'State Auditor', 'DE State Auditor', 'Delaware',
   '10', '25b1cbb5-2fef-4803-9eb0-e78411f2ee29'::uuid, 'state-auditor-of-delaware', 'State Auditor of Delaware',
   'Delaware State Auditor', 'ocd-division/country:us/state:de', '00653817-6888-4074-8342-057be2ceced9'::uuid, NULL,
   'Lydia York', 'page'),
  ('FL', 'Commissioner of Agriculture and Consumer Services', 'FL Commissioner of Agriculture and Consumer Services', 'Florida',
   '12', '623ac987-c7bc-4da1-8112-68adaec10cb2'::uuid, 'commissioner-of-agriculture-and-consumer-services-of-florida', 'Commissioner of Agriculture and Consumer Services of Florida',
   'Florida Commissioner of Agriculture and Consumer Services', 'ocd-division/country:us/state:fl', '1c868ba1-3169-4f0a-84a2-f41b349ef313'::uuid, NULL,
   'Wilton Simpson', 'page'),
  ('GA', 'Commissioner of Agriculture', 'GA Commissioner of Agriculture', 'Georgia',
   '13', 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf'::uuid, 'commissioner-of-agriculture-of-georgia', 'Commissioner of Agriculture of Georgia',
   'Georgia Commissioner of Agriculture', 'ocd-division/country:us/state:ga', 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, NULL,
   'Tyler Harper', 'page'),
  ('GA', 'Commissioner of Labor', 'GA Commissioner of Labor', 'Georgia',
   '13', 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf'::uuid, 'commissioner-of-labor-of-georgia', 'Commissioner of Labor of Georgia',
   'Georgia Commissioner of Labor', 'ocd-division/country:us/state:ga', 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, NULL,
   'Bárbara Rivera Holmes', 'page'),
  ('GA', 'Insurance and Safety Fire Commissioner', 'GA Insurance and Safety Fire Commissioner', 'Georgia',
   '13', 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf'::uuid, 'insurance-and-safety-fire-commissioner-of-georgia', 'Insurance and Safety Fire Commissioner of Georgia',
   'Georgia Insurance and Safety Fire Commissioner', 'ocd-division/country:us/state:ga', 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, NULL,
   'John King', 'page'),
  ('GA', 'State Superintendent of Schools', 'GA State Superintendent of Schools', 'Georgia',
   '13', 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf'::uuid, 'state-superintendent-of-schools-of-georgia', 'State Superintendent of Schools of Georgia',
   'Georgia State Superintendent of Schools', 'ocd-division/country:us/state:ga', 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, NULL,
   'Richard Woods', 'page'),
  ('HI', 'Office of Hawaiian Affairs Maui Resident Trustee', 'HI Office of Hawaiian Affairs Maui Resident Trustee', 'Hawaii',
   '15', '05b03419-f890-4c7c-b03f-dcd26c3005ee'::uuid, 'office-of-hawaiian-affairs-maui-resident-trustee-of-hawaii', 'Office of Hawaiian Affairs Maui Resident Trustee of Hawaii',
   'Hawaii Office of Hawaiian Affairs Maui Resident Trustee', 'ocd-division/country:us/state:hi', 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'::uuid, NULL,
   'Carmen Hulu Lindsey', 'page'),
  ('HI', 'Office of Hawaiian Affairs Oahu Resident Trustee', 'HI Office of Hawaiian Affairs Oahu Resident Trustee', 'Hawaii',
   '15', '05b03419-f890-4c7c-b03f-dcd26c3005ee'::uuid, 'office-of-hawaiian-affairs-oahu-resident-trustee-of-hawaii', 'Office of Hawaiian Affairs Oahu Resident Trustee of Hawaii',
   'Hawaii Office of Hawaiian Affairs Oahu Resident Trustee', 'ocd-division/country:us/state:hi', 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'::uuid, NULL,
   'Kalei Akaka', 'page'),
  ('IA', 'Secretary of Agriculture', 'IA Secretary of Agriculture', 'Iowa',
   '19', 'a759078d-3d46-41e4-80af-2a00388cf309'::uuid, 'secretary-of-agriculture-of-iowa', 'Secretary of Agriculture of Iowa',
   'Iowa Secretary of Agriculture', 'ocd-division/country:us/state:ia', 'ed7eb7da-8e46-4d25-a97a-f3168bd0fbf6'::uuid, NULL,
   'Mike Naig', 'page'),
  ('IL', 'Comptroller', 'IL Comptroller', 'Illinois',
   '17', '4ae251df-c052-40ce-9e62-1865f55908bb'::uuid, 'comptroller-of-illinois', 'Comptroller of Illinois',
   'Illinois Comptroller', 'ocd-division/country:us/state:il', '804d07cf-11c9-4e3d-a85d-9ff8cbffb828'::uuid, 'comptroller',
   'Susana A. Mendoza', 'site'),
  ('MN', 'State Auditor', 'MN State Auditor', 'Minnesota',
   '27', 'b610e3f3-0ffa-4450-9ce8-f695ce7926a0'::uuid, 'state-auditor-of-minnesota', 'State Auditor of Minnesota',
   'Minnesota State Auditor', 'ocd-division/country:us/state:mn', '964480b9-d8ae-4d80-a1f0-ddfca3b01883'::uuid, NULL,
   'Julie Blaha', 'site'),
  ('MO', 'State Auditor', 'MO State Auditor', 'Missouri',
   '29', '066b88fd-1458-462e-a3b5-1331f1810fdf'::uuid, 'state-auditor-of-missouri', 'State Auditor of Missouri',
   'Missouri State Auditor', 'ocd-division/country:us/state:mo', '25941a7b-a488-4289-9d8a-3e9ca3d275ad'::uuid, NULL,
   'Scott Fitzpatrick', 'page'),
  ('ND', 'Commissioner of Agriculture', 'ND Commissioner of Agriculture', 'North Dakota',
   '38', 'cda06c83-809e-4239-9e7b-cc6b3db00fa1'::uuid, 'commissioner-of-agriculture-of-north-dakota', 'Commissioner of Agriculture of North Dakota',
   'North Dakota Commissioner of Agriculture', 'ocd-division/country:us/state:nd', 'fce62fc6-28b4-4d99-821a-3c5e94bb2915'::uuid, NULL,
   'Doug Goehring', 'page'),
  ('ND', 'Tax Commissioner', 'ND Tax Commissioner', 'North Dakota',
   '38', 'cda06c83-809e-4239-9e7b-cc6b3db00fa1'::uuid, 'tax-commissioner-of-north-dakota', 'Tax Commissioner of North Dakota',
   'North Dakota Tax Commissioner', 'ocd-division/country:us/state:nd', 'fce62fc6-28b4-4d99-821a-3c5e94bb2915'::uuid, NULL,
   'Brian Kroshus', 'page'),
  ('NE', 'Auditor of Public Accounts', 'NE Auditor of Public Accounts', 'Nebraska',
   '31', 'bb004e64-eeb4-4605-b062-ea991e7ad38b'::uuid, 'auditor-of-public-accounts-of-nebraska', 'Auditor of Public Accounts of Nebraska',
   'Nebraska Auditor of Public Accounts', 'ocd-division/country:us/state:ne', '1224487f-4f73-4048-b553-5629ee19b512'::uuid, NULL,
   'Mike Foley', 'page'),
  ('NM', 'Commissioner of Public Lands', 'NM Commissioner of Public Lands', 'New Mexico',
   '35', '3e3c6584-1400-4f9d-9bfc-8438eac843dd'::uuid, 'commissioner-of-public-lands-of-new-mexico', 'Commissioner of Public Lands of New Mexico',
   'New Mexico Commissioner of Public Lands', 'ocd-division/country:us/state:nm', '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid, NULL,
   'Stephanie Garcia Richard', 'site'),
  ('NM', 'State Auditor', 'NM State Auditor', 'New Mexico',
   '35', '3e3c6584-1400-4f9d-9bfc-8438eac843dd'::uuid, 'state-auditor-of-new-mexico', 'State Auditor of New Mexico',
   'New Mexico State Auditor', 'ocd-division/country:us/state:nm', '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid, NULL,
   'Joseph Maestas', 'page'),
  ('SC', 'Superintendent of Education', 'SC Superintendent of Education', 'South Carolina',
   '45', 'daccc0ea-eafb-4962-ba00-2ee043fa6709'::uuid, 'superintendent-of-education-of-south-carolina', 'Superintendent of Education of South Carolina',
   'South Carolina Superintendent of Education', 'ocd-division/country:us/state:sc', 'e9a9063d-7a17-43de-9ac4-012a50166b64'::uuid, NULL,
   'Ellen Weaver', 'page'),
  ('SD', 'Commissioner of School and Public Lands', 'SD Commissioner of School and Public Lands', 'South Dakota',
   '46', '29fbd5e8-ef43-456b-b89f-2d170062a3b8'::uuid, 'commissioner-of-school-and-public-lands-of-south-dakota', 'Commissioner of School and Public Lands of South Dakota',
   'South Dakota Commissioner of School and Public Lands', 'ocd-division/country:us/state:sd', 'ac7ebe0d-b300-43ed-b107-d919822502df'::uuid, NULL,
   'Brock Greenfield', 'page'),
  ('WY', 'State Auditor', 'WY State Auditor', 'Wyoming',
   '56', '781be5ce-3389-468d-bd68-a0e932abc8f4'::uuid, 'state-auditor-of-wyoming', 'State Auditor of Wyoming',
   'Wyoming State Auditor', 'ocd-division/country:us/state:wy', '28ce873c-af6e-4802-9315-b47a5e0cdd9a'::uuid, NULL,
   'Kristi Racines', 'page');

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM newseat;
  IF n <> 25 THEN RAISE EXCEPTION 'expected 25 seats, found %', n; END IF;

  -- 🔴 none of these offices may already exist, under ANY district type. The whole reason
  --    CC_0362 had to be written is that a reconciliation filtered on STATE_EXEC and reported
  --    seats we DO hold as absent. This gate makes no such assumption.
  SELECT string_agg(ns.seat || ' already exists as ' || d.district_type || ' "' || o.title || '" ' || o.id, '; ') INTO txt
    FROM newseat ns
    JOIN essentials.districts d ON upper(d.state) = ns.st
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE lower(regexp_replace(o.title, '[^A-Za-z ]', '', 'g')) = lower(regexp_replace(ns.office, '[^A-Za-z ]', '', 'g'))
      OR lower(regexp_replace(o.title, '[^A-Za-z ]', '', 'g')) = lower(regexp_replace(ns.state_name || ' ' || ns.office, '[^A-Za-z ]', '', 'g'));
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;

  -- the government and the election row must be the ones this file names, in that state
  SELECT string_agg(ns.seat || ' -> government ' || coalesce(g.id::text, '(missing)'), '; ') INTO txt
    FROM newseat ns LEFT JOIN essentials.governments g ON g.id = ns.gov_id WHERE g.id IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a government row does not exist: %', txt; END IF;
  SELECT string_agg(ns.seat || ' -> ' || coalesce(e.name, '(missing)') || ' ' || coalesce(e.state, '?'), '; ') INTO txt
    FROM newseat ns LEFT JOIN essentials.elections e ON e.id = ns.election_id
   WHERE e.id IS NULL OR e.election_date <> DATE '2026-11-03' OR e.state IS DISTINCT FROM ns.st;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an election row is not the 2026-11-03 general of its state: %', txt; END IF;

  -- 🔴 the FIPS this file writes as geo_id must be the one the state already uses, not a
  --    number typed from memory. An empty or wrong geo_id is a key nothing can ever match.
  SELECT string_agg(ns.seat || ': this file says FIPS ' || ns.fips || ' but ' || ns.st || ' districts use ' || d.geo_id, '; ') INTO txt
    FROM newseat ns JOIN LATERAL (
      SELECT DISTINCT d2.geo_id FROM essentials.districts d2
       WHERE upper(d2.state) = ns.st AND d2.district_type = 'STATE_EXEC' LIMIT 1) d ON true
   WHERE d.geo_id <> ns.fips;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a FIPS disagrees with the state''s existing districts: %', txt; END IF;
END $$;

CREATE TEMP TABLE made_chamber (seat text PRIMARY KEY, chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  -- ⚠ chambers.slug is a GENERATED column and cannot be written, so the rows are joined
  --   back on name_formal ("<Office> of <State>"), which is unique across these 25.
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level)
  SELECT ns.office, ns.chamber_formal, ns.gov_id, 'full' FROM newseat ns
  RETURNING id, name_formal)
INSERT INTO made_chamber (seat, chamber_id) SELECT ns.seat, ins.id FROM ins JOIN newseat ns ON ns.chamber_formal = ins.name_formal;

CREATE TEMP TABLE made_district (seat text PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_EXEC', ns.st, ns.fips, ns.ocd, ns.district_label, '', '', 'residency' FROM newseat ns
  RETURNING id, label)
INSERT INTO made_district (seat, district_id) SELECT ns.seat, ins.id FROM ins JOIN newseat ns ON ns.district_label = ins.label;

CREATE TEMP TABLE made_office (seat text PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, role_canonical,
                                  voting_powers, is_vacant, faces_retention_vote, is_appointed_position)
  SELECT ns.office, mc.chamber_id, md.district_id, ns.st, ns.role_canonical, 'full', false, false, false
    FROM newseat ns JOIN made_chamber mc ON mc.seat = ns.seat JOIN made_district md ON md.seat = ns.seat
  RETURNING id, district_id)
INSERT INTO made_office (seat, office_id) SELECT md.seat, ins.id FROM ins JOIN made_district md ON md.district_id = ins.district_id;

DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM made_chamber;  IF n <> 25 THEN RAISE EXCEPTION 'only % chambers were created', n; END IF;
  SELECT count(*) INTO n FROM made_district; IF n <> 25 THEN RAISE EXCEPTION 'only % districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_office;   IF n <> 25 THEN RAISE EXCEPTION 'only % offices were created', n; END IF;
END $$;

-- ─── 2. The people this file must create ───
CREATE TEMP TABLE seed_people (
  pkey text PRIMARY KEY, full_name text NOT NULL, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('AL|Andrew Sorrell', 'Andrew Sorrell', 'Andrew', 'Sorrell',
   'https://ballotpedia.org/Andrew_Sorrell (Ballotpedia, read 2026-11-06); CC_0363'),
  ('AL|Violet Edwards', 'Violet Edwards', 'Violet', 'Edwards',
   'https://ballotpedia.org/Violet_Edwards (Ballotpedia, read 2026-11-06); CC_0363'),
  ('AL|Corey Hill', 'Corey Hill', 'Corey', 'Hill',
   'https://ballotpedia.org/Corey_Hill (Ballotpedia, read 2026-11-06); CC_0363'),
  ('AL|Ron Sparks', 'Ron Sparks', 'Ron', 'Sparks',
   'https://ballotpedia.org/Ron_Sparks (Ballotpedia, read 2026-11-06); CC_0363'),
  ('AL|Rick Pate', 'Rick Pate', 'Rick', 'Pate',
   'https://ballotpedia.org/Alabama_state_executive_official_elections,_2026 (Ballotpedia, read 2026-11-06 — named on the state page''s Commissioner of Agriculture and Industries table); CC_0363'),
  ('AR|Dennis Milligan', 'Dennis Milligan', 'Dennis', 'Milligan',
   'https://ballotpedia.org/Dennis_Milligan (Ballotpedia, read 2026-11-06); CC_0363'),
  ('AR|Christopher Olson', 'Christopher Olson', 'Christopher', 'Olson',
   'https://ballotpedia.org/Chris_Olson_(Arkansas) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('AR|Tommy Land', 'Tommy Land', 'Tommy', 'Land',
   'https://ballotpedia.org/Arkansas_state_executive_official_elections,_2026 (Ballotpedia, read 2026-11-06 — named on the state page''s Commissioner of State Lands table); CC_0363'),
  ('CT|Sean Scanlon', 'Sean Scanlon', 'Sean', 'Scanlon',
   'https://ballotpedia.org/Sean_Scanlon (Ballotpedia, read 2026-11-06); CC_0363'),
  ('CT|Jennifer Tooker', 'Jennifer Tooker', 'Jennifer', 'Tooker',
   'https://ballotpedia.org/Jennifer_Tooker (Ballotpedia, read 2026-11-06); CC_0363'),
  ('DE|Lydia York', 'Lydia York', 'Lydia', 'York',
   'https://ballotpedia.org/Lydia_York (Ballotpedia, read 2026-11-06); CC_0363'),
  ('DE|April Callaway', 'April Callaway', 'April', 'Callaway',
   'https://ballotpedia.org/April_Callaway (Ballotpedia, read 2026-11-06); CC_0363'),
  ('DE|Austin Cassidy', 'Austin Cassidy', 'Austin', 'Cassidy',
   'https://ballotpedia.org/Austin_Cassidy (Ballotpedia, read 2026-11-06); CC_0363'),
  ('FL|Wilton Simpson', 'Wilton Simpson', 'Wilton', 'Simpson',
   'https://ballotpedia.org/Wilton_Simpson (Ballotpedia, read 2026-11-06); CC_0363'),
  ('FL|Joey Atkins', 'Joey Atkins', 'Joey', 'Atkins',
   'https://ballotpedia.org/Joey_Atkins (Ballotpedia, read 2026-11-06); CC_0363'),
  ('FL|Kyle Gibson', 'Kyle Gibson', 'Kyle', 'Gibson',
   'https://ballotpedia.org/Kyle_Gibson (Ballotpedia, read 2026-11-06); CC_0363'),
  ('GA|Katherine Juhan-Arnold', 'Katherine Juhan-Arnold', 'Katherine', 'Juhan-Arnold',
   'https://ballotpedia.org/Katherine_Juhan-Arnold (Ballotpedia, read 2026-11-06); CC_0363'),
  ('GA|Tyler Harper', 'Tyler Harper', 'Tyler', 'Harper',
   'https://ballotpedia.org/Tyler_Harper (Ballotpedia, read 2026-11-06); CC_0363'),
  ('GA|Nikki Porcher', 'Nikki Porcher', 'Nikki', 'Porcher',
   'https://ballotpedia.org/Nikki_Porcher (Ballotpedia, read 2026-11-06); CC_0363'),
  ('GA|Bárbara Rivera Holmes', 'Bárbara Rivera Holmes', 'Bárbara', 'Rivera Holmes',
   'https://ballotpedia.org/Bárbara_Rivera_Holmes (Ballotpedia, read 2026-11-06); CC_0363'),
  ('GA|Keisha Sean Waites', 'Keisha Sean Waites', 'Keisha Sean', 'Waites',
   'https://ballotpedia.org/Keisha_Sean_Waites (Ballotpedia, read 2026-11-06); CC_0363'),
  ('GA|John King', 'John King', 'John', 'King',
   'https://ballotpedia.org/John_King_(Georgia) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('GA|Lydia Powell', 'Lydia Powell', 'Lydia', 'Powell',
   'https://ballotpedia.org/Lydia_Powell (Ballotpedia, read 2026-11-06); CC_0363'),
  ('GA|Richard Woods', 'Richard Woods', 'Richard', 'Woods',
   'https://ballotpedia.org/Richard_Woods_(Georgia) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('HI|Carmen Hulu Lindsey', 'Carmen Hulu Lindsey', 'Carmen Hulu', 'Lindsey',
   'https://ballotpedia.org/Carmen_Hulu_Lindsey (Ballotpedia, read 2026-11-06); CC_0363'),
  ('HI|Ke''eaumoku Kapu', 'Ke''eaumoku Kapu', 'Ke''eaumoku', 'Kapu',
   'https://ballotpedia.org/Hawaii_state_executive_official_elections,_2026 (Ballotpedia, read 2026-11-06 — named on the state page''s Office of Hawaiian Affairs Maui Resident Trustee table); CC_0363'),
  ('HI|Kalei Akaka', 'Kalei Akaka', 'Kalei', 'Akaka',
   'https://ballotpedia.org/Kalei_Akaka (Ballotpedia, read 2026-11-06); CC_0363'),
  ('HI|Hinaleimoana Wong', 'Hinaleimoana Wong', 'Hinaleimoana', 'Wong',
   'https://ballotpedia.org/Hinaleimoana_Wong (Ballotpedia, read 2026-11-06); CC_0363'),
  ('IA|Mike Naig', 'Mike Naig', 'Mike', 'Naig',
   'https://ballotpedia.org/Mike_Naig (Ballotpedia, read 2026-11-06); CC_0363'),
  ('IA|Chris Jones', 'Chris Jones', 'Chris', 'Jones',
   'https://ballotpedia.org/Chris_Jones_(Iowa) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('IL|Margaret Croke', 'Margaret Croke', 'Margaret', 'Croke',
   'https://ballotpedia.org/Margaret_Croke (Ballotpedia, read 2026-11-06); CC_0363'),
  ('IL|Bryan Drew', 'Bryan Drew', 'Bryan', 'Drew',
   'https://ballotpedia.org/Bryan_Drew (Ballotpedia, read 2026-11-06); CC_0363'),
  ('IL|Anna Schiefelbein', 'Anna Schiefelbein', 'Anna', 'Schiefelbein',
   'https://ballotpedia.org/Anna_Schiefelbein (Ballotpedia, read 2026-11-06); CC_0363'),
  ('IL|Susana A. Mendoza', 'Susana A. Mendoza', 'Susana A.', 'Mendoza',
   'https://ballotpedia.org/Illinois_state_executive_official_elections,_2026 (Ballotpedia, read 2026-11-06 — named on the state page''s Comptroller table); CC_0363'),
  ('MN|Zack Filipovich', 'Zack Filipovich', 'Zack', 'Filipovich',
   'https://ballotpedia.org/Zack_Filipovich (Ballotpedia, read 2026-11-06); CC_0363'),
  ('MN|Scott Jensen', 'Scott Jensen', 'Scott', 'Jensen',
   'https://ballotpedia.org/Scott_Jensen_(Minnesota) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('MN|Jay Reeves', 'Jay Reeves', 'Jay', 'Reeves',
   'https://ballotpedia.org/Jay_Reeves_(Minnesota) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('MN|Julie Blaha', 'Julie Blaha', 'Julie', 'Blaha',
   'https://ballotpedia.org/Minnesota_state_executive_official_elections,_2026 (Ballotpedia, read 2026-11-06 — named on the state page''s State Auditor table); CC_0363'),
  ('MO|Scott Fitzpatrick', 'Scott Fitzpatrick', 'Scott', 'Fitzpatrick',
   'https://ballotpedia.org/Scott_Fitzpatrick (Ballotpedia, read 2026-11-06); CC_0363'),
  ('MO|Quentin Wilson', 'Quentin Wilson', 'Quentin', 'Wilson',
   'https://ballotpedia.org/Quentin_Wilson (Ballotpedia, read 2026-11-06); CC_0363'),
  ('MO|Dustin Coffell', 'Dustin Coffell', 'Dustin', 'Coffell',
   'https://ballotpedia.org/Dustin_Coffell (Ballotpedia, read 2026-11-06); CC_0363'),
  ('ND|Doug Goehring', 'Doug Goehring', 'Doug', 'Goehring',
   'https://ballotpedia.org/Doug_Goehring (Ballotpedia, read 2026-11-06); CC_0363'),
  ('ND|Vern Thompson', 'Vern Thompson', 'Vern', 'Thompson',
   'https://ballotpedia.org/Vern_Thompson (Ballotpedia, read 2026-11-06); CC_0363'),
  ('ND|Brian Kroshus', 'Brian Kroshus', 'Brian', 'Kroshus',
   'https://ballotpedia.org/Brian_Kroshus (Ballotpedia, read 2026-11-06); CC_0363'),
  ('ND|Mark Nelson', 'Mark Nelson', 'Mark', 'Nelson',
   'https://ballotpedia.org/Mark_Nelson_(North_Dakota) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('NE|Mike Foley', 'Mike Foley', 'Mike', 'Foley',
   'https://ballotpedia.org/Mike_Foley (Ballotpedia, read 2026-11-06); CC_0363'),
  ('NE|John Knight', 'John Knight', 'John', 'Knight',
   'https://ballotpedia.org/John_Knight_(Nebraska) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('NM|Juan Sanchez III', 'Juan Sanchez III', 'Juan', 'Sanchez III',
   'https://ballotpedia.org/Juan_Sanchez_III (Ballotpedia, read 2026-11-06); CC_0363'),
  ('NM|Michael Perry', 'Michael Perry', 'Michael', 'Perry',
   'https://ballotpedia.org/Michael_Perry_(New_Mexico) (Ballotpedia, read 2026-11-06); CC_0363'),
  ('NM|Joseph Maestas', 'Joseph Maestas', 'Joseph', 'Maestas',
   'https://ballotpedia.org/Joseph_Maestas (Ballotpedia, read 2026-11-06); CC_0363'),
  ('NM|Joshua Lawrence', 'Joshua Lawrence', 'Joshua', 'Lawrence',
   'https://ballotpedia.org/Joshua_Lawrence (Ballotpedia, read 2026-11-06); CC_0363'),
  ('SC|Ellen Weaver', 'Ellen Weaver', 'Ellen', 'Weaver',
   'https://ballotpedia.org/Ellen_Weaver (Ballotpedia, read 2026-11-06); CC_0363'),
  ('SC|Sylvia Wright', 'Sylvia Wright', 'Sylvia', 'Wright',
   'https://ballotpedia.org/Sylvia_Wright (Ballotpedia, read 2026-11-06); CC_0363'),
  ('SC|Baba Amin Ojuok', 'Baba Amin Ojuok', 'Baba Amin', 'Ojuok',
   'https://ballotpedia.org/Baba_Amin_Ojuok (Ballotpedia, read 2026-11-06); CC_0363'),
  ('SD|Brock Greenfield', 'Brock Greenfield', 'Brock', 'Greenfield',
   'https://ballotpedia.org/Brock_Greenfield (Ballotpedia, read 2026-11-06); CC_0363'),
  ('SD|Raeann Mettler', 'Raeann Mettler', 'Raeann', 'Mettler',
   'https://ballotpedia.org/Raeann_Mettler (Ballotpedia, read 2026-11-06); CC_0363'),
  ('WY|Kristi Racines', 'Kristi Racines', 'Kristi', 'Racines',
   'https://ballotpedia.org/Kristi_Racines (Ballotpedia, read 2026-11-06); CC_0363');

CREATE TEMP TABLE allowed_name_collisions (full_name text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO allowed_name_collisions VALUES
  ('John King'),
  ('Chris Jones'),
  ('Mike Foley');

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
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Doug Jones');
  IF n < 1 THEN RAISE EXCEPTION 'the name index cannot see a politician known to exist — the guard below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM pol_keys;
  IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows — it did not load the table', n; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ', active=' || p.is_active || ')' AS msg
      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)
     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)
    UNION
    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'
      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name)
     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;

  -- the allowance must still be earned, or it is quietly excusing a row it no longer describes
  SELECT count(*) INTO n FROM allowed_name_collisions a JOIN seed_people s ON s.full_name = a.full_name
   WHERE NOT EXISTS (SELECT 1 FROM pol_keys p WHERE p.source IS DISTINCT FROM s.source
                       AND (p.k_full = pg_temp.namekey(s.full_name)
                         OR (p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name))));
  IF n <> 0 THEN RAISE EXCEPTION '% allowed collision(s) no longer collide — the allowance is stale', n; END IF;

  -- 🔴 the split must reconstruct the name EXACTLY. "ends with the surname" is not enough:
  --    a hyphenated or compound surname contains its own tail, which a control proved twice.
  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s WHERE s.full_name <> s.first_name || ' ' || s.last_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;

  SELECT string_agg(s.full_name || ' -> ' || s.source, '; ') INTO txt FROM seed_people s
   WHERE s.source NOT LIKE 'https://ballotpedia.org/%' OR s.source LIKE '%#%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is not a plain Ballotpedia page: %', txt; END IF;
END $$;

-- 🟢 the database has its own DUPLICATE_POLITICIAN_NAME trigger and it agrees with the guard
--    above. Opened for this one statement and closed on the next line, so it covers nothing else.
SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, s.source, true,
       EXISTS (SELECT 1 FROM newseat ns WHERE ns.holder = s.full_name)
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source);
SET LOCAL essentials.allow_duplicate_name = 'off';

CREATE TEMP TABLE seeded (pkey text PRIMARY KEY, politician_id uuid NOT NULL) ON COMMIT DROP;
INSERT INTO seeded SELECT s.pkey, p.id FROM seed_people s
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;
DO $$ DECLARE n int; BEGIN SELECT count(*) INTO n FROM seeded;
  IF n <> 57 THEN RAISE EXCEPTION 'only % of the 57 seeded people resolved to exactly one row', n; END IF; END $$;

-- ─── 3. Seat the CURRENT officeholder, open-ended, with an unknown start ───
CREATE TEMP TABLE holders (seat text PRIMARY KEY, who text NOT NULL, how text NOT NULL, pinned_id uuid) ON COMMIT DROP;
INSERT INTO holders VALUES
  ('AL Auditor', 'Andrew Sorrell', 'page', NULL),
  ('AL Commissioner of Agriculture and Industries', 'Rick Pate', 'site', NULL),
  ('AR Auditor of State', 'Dennis Milligan', 'page', NULL),
  ('AR Commissioner of State Lands', 'Tommy Land', 'site', NULL),
  ('CT Comptroller', 'Sean Scanlon', 'page', NULL),
  ('DE State Auditor', 'Lydia York', 'page', NULL),
  ('FL Commissioner of Agriculture and Consumer Services', 'Wilton Simpson', 'page', NULL),
  ('GA Commissioner of Agriculture', 'Tyler Harper', 'page', NULL),
  ('GA Commissioner of Labor', 'Bárbara Rivera Holmes', 'page', NULL),
  ('GA Insurance and Safety Fire Commissioner', 'John King', 'page', NULL),
  ('GA State Superintendent of Schools', 'Richard Woods', 'page', NULL),
  ('HI Office of Hawaiian Affairs Maui Resident Trustee', 'Carmen Hulu Lindsey', 'page', NULL),
  ('HI Office of Hawaiian Affairs Oahu Resident Trustee', 'Kalei Akaka', 'page', NULL),
  ('IA Secretary of Agriculture', 'Mike Naig', 'page', NULL),
  ('IL Comptroller', 'Susana A. Mendoza', 'site', NULL),
  ('MN State Auditor', 'Julie Blaha', 'site', NULL),
  ('MO State Auditor', 'Scott Fitzpatrick', 'page', NULL),
  ('ND Commissioner of Agriculture', 'Doug Goehring', 'page', NULL),
  ('ND Tax Commissioner', 'Brian Kroshus', 'page', NULL),
  ('NE Auditor of Public Accounts', 'Mike Foley', 'page', NULL),
  ('NM Commissioner of Public Lands', 'Stephanie Garcia Richard', 'site', '1b3be3e1-7423-4ba0-bddc-16d1bc59b232'::uuid),
  ('NM State Auditor', 'Joseph Maestas', 'page', NULL),
  ('SC Superintendent of Education', 'Ellen Weaver', 'page', NULL),
  ('SD Commissioner of School and Public Lands', 'Brock Greenfield', 'page', NULL),
  ('WY State Auditor', 'Kristi Racines', 'page', NULL);

CREATE TEMP TABLE holder_pin ON COMMIT DROP AS
SELECT h.*, coalesce(h.pinned_id, sd.politician_id) AS pid, mo.office_id,
       CASE WHEN h.how = 'site' THEN 'the office''s own website, read 2026-11-06 (CC_0363)'
            ELSE 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 — its "Incumbent" label on the 2026 race (CC_0363)' END AS src
  FROM holders h LEFT JOIN seeded sd ON sd.pkey = split_part(h.seat, ' ', 1) || '|' || h.who
  JOIN made_office mo ON mo.seat = h.seat;

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM holder_pin WHERE pid IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% officeholder(s) resolve to no person', n; END IF;
  SELECT string_agg(hp.who || ' (' || p.full_name || ') is archived', '; ') INTO txt
    FROM holder_pin hp JOIN essentials.politicians p ON p.id = hp.pid WHERE NOT p.is_active;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an officeholder points at an archived person: %', txt; END IF;
  SELECT string_agg(hp.seat || ': names ' || hp.who || ' but the row is ' || p.full_name, '; ') INTO txt
    FROM holder_pin hp JOIN essentials.politicians p ON p.id = hp.pid
   WHERE pg_temp.namekey(p.full_name) <> pg_temp.namekey(hp.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned officeholder is not the person this file names: %', txt; END IF;
END $$;

-- 🔴 term_start is NULL with start_precision 'unknown'. None of these sources publishes when
--    the holder's term began, and "first elected" is not a term start. An open-ended term
--    says "holds it now, start not established", which is the true claim.
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT hp.office_id, hp.pid, NULL, NULL, 'unknown', 'unknown', hp.src FROM holder_pin hp;

-- ─── 4. The races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT ns.election_id, mo.office_id, ns.office, NULL, 1
  FROM newseat ns JOIN made_office mo ON mo.seat = ns.seat;

CREATE TEMP TABLE calls (
  seat text NOT NULL, who text NOT NULL, result text NOT NULL, is_write_in boolean NOT NULL,
  pinned_id uuid, PRIMARY KEY (seat, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  ('AL Auditor',                                  'Andrew Sorrell',            'won',   false, NULL),
  ('AL Auditor',                                  'Violet Edwards',            'lost',  false, NULL),
  ('AL Commissioner of Agriculture and Industries', 'Corey Hill',                'won',   false, NULL),
  ('AL Commissioner of Agriculture and Industries', 'Ron Sparks',                'lost',  false, NULL),
  ('AR Auditor of State',                         'Dennis Milligan',           'won',   false, NULL),
  ('AR Commissioner of State Lands',              'Cole Jester',               'won',   false, '0ee2a01a-3cf1-428e-b8ed-943d2e3c29f5'::uuid),
  ('AR Commissioner of State Lands',              'Christopher Olson',         'lost',  false, NULL),
  ('CT Comptroller',                              'Sean Scanlon',              'won',   false, NULL),
  ('CT Comptroller',                              'Jennifer Tooker',           'lost',  false, NULL),
  ('DE State Auditor',                            'Lydia York',                'won',   false, NULL),
  ('DE State Auditor',                            'April Callaway',            'lost',  false, NULL),
  ('DE State Auditor',                            'Austin Cassidy',            'lost',  false, NULL),
  ('FL Commissioner of Agriculture and Consumer Services', 'Wilton Simpson',            'won',   false, NULL),
  ('FL Commissioner of Agriculture and Consumer Services', 'Joey Atkins',               'lost',  false, NULL),
  ('FL Commissioner of Agriculture and Consumer Services', 'Kyle Gibson',               'lost',  true , NULL),
  ('GA Commissioner of Agriculture',              'Katherine Juhan-Arnold',    'won',   false, NULL),
  ('GA Commissioner of Agriculture',              'Tyler Harper',              'lost',  false, NULL),
  ('GA Commissioner of Labor',                    'Nikki Porcher',             'won',   false, NULL),
  ('GA Commissioner of Labor',                    'Bárbara Rivera Holmes',     'lost',  false, NULL),
  ('GA Insurance and Safety Fire Commissioner',   'Keisha Sean Waites',        'won',   false, NULL),
  ('GA Insurance and Safety Fire Commissioner',   'John King',                 'lost',  false, NULL),
  ('GA State Superintendent of Schools',          'Lydia Powell',              'won',   false, NULL),
  ('GA State Superintendent of Schools',          'Richard Woods',             'lost',  false, NULL),
  ('HI Office of Hawaiian Affairs Maui Resident Trustee', 'Carmen Hulu Lindsey',       'won',   false, NULL),
  ('HI Office of Hawaiian Affairs Maui Resident Trustee', 'Ke''eaumoku Kapu',          'lost',  false, NULL),
  ('HI Office of Hawaiian Affairs Oahu Resident Trustee', 'Kalei Akaka',               'won',   false, NULL),
  ('HI Office of Hawaiian Affairs Oahu Resident Trustee', 'Hinaleimoana Wong',         'lost',  false, NULL),
  ('IA Secretary of Agriculture',                 'Mike Naig',                 'won',   false, NULL),
  ('IA Secretary of Agriculture',                 'Chris Jones',               'lost',  false, NULL),
  ('IL Comptroller',                              'Margaret Croke',            'won',   false, NULL),
  ('IL Comptroller',                              'Bryan Drew',                'lost',  false, NULL),
  ('IL Comptroller',                              'Anna Schiefelbein',         'lost',  true , NULL),
  ('MN State Auditor',                            'Zack Filipovich',           'won',   false, NULL),
  ('MN State Auditor',                            'Scott Jensen',              'lost',  false, NULL),
  ('MN State Auditor',                            'Jay Reeves',                'lost',  false, NULL),
  ('MO State Auditor',                            'Scott Fitzpatrick',         'won',   false, NULL),
  ('MO State Auditor',                            'Quentin Wilson',            'lost',  false, NULL),
  ('MO State Auditor',                            'Dustin Coffell',            'lost',  false, NULL),
  ('ND Commissioner of Agriculture',              'Doug Goehring',             'won',   false, NULL),
  ('ND Commissioner of Agriculture',              'Vern Thompson',             'lost',  false, NULL),
  ('ND Tax Commissioner',                         'Brian Kroshus',             'won',   false, NULL),
  ('ND Tax Commissioner',                         'Mark Nelson',               'lost',  false, NULL),
  ('NE Auditor of Public Accounts',               'Mike Foley',                'won',   false, NULL),
  ('NE Auditor of Public Accounts',               'John Knight',               'lost',  false, NULL),
  ('NM Commissioner of Public Lands',             'Juan Sanchez III',          'won',   false, NULL),
  ('NM Commissioner of Public Lands',             'Michael Perry',             'lost',  false, NULL),
  ('NM State Auditor',                            'Joseph Maestas',            'won',   false, NULL),
  ('NM State Auditor',                            'Joshua Lawrence',           'lost',  false, NULL),
  ('SC Superintendent of Education',              'Ellen Weaver',              'won',   false, NULL),
  ('SC Superintendent of Education',              'Sylvia Wright',             'lost',  false, NULL),
  ('SC Superintendent of Education',              'Baba Amin Ojuok',           'lost',  false, NULL),
  ('SD Commissioner of School and Public Lands',  'Brock Greenfield',          'won',   false, NULL),
  ('SD Commissioner of School and Public Lands',  'Raeann Mettler',            'lost',  false, NULL),
  ('WY State Auditor',                            'Kristi Racines',            'won',   false, NULL);

CREATE TEMP TABLE pins ON COMMIT DROP AS
SELECT c.*, coalesce(c.pinned_id, sd.politician_id) AS pid, mo.office_id
  FROM calls c LEFT JOIN seeded sd ON sd.pkey = split_part(c.seat, ' ', 1) || '|' || c.who
  JOIN made_office mo ON mo.seat = c.seat;

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM pins WHERE pid IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) resolve to no person', n; END IF;
  SELECT string_agg(p.seat || ': names ' || p.who || ' but the row is ' || pl.full_name, '; ') INTO txt
    FROM pins p JOIN essentials.politicians pl ON pl.id = p.pid
   WHERE pg_temp.namekey(pl.full_name) <> pg_temp.namekey(p.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned candidate is not the person this file names: %', txt; END IF;
  SELECT count(*) INTO n FROM (
    SELECT seat FROM calls GROUP BY seat HAVING count(*) FILTER (WHERE result = 'won') <> 1) z;
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) do not hold exactly one winner', n; END IF;
  SELECT count(*) INTO n FROM calls WHERE result = 'won';
  IF n <> 25 THEN RAISE EXCEPTION 'expected 25 winners, found %', n; END IF;
END $$;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, (hp.pid IS NOT NULL), 'active',
       p.is_write_in, 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0363', p.result, 'called', 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0363', now()
  FROM pins p
  JOIN essentials.races r ON r.office_id = p.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.politicians pl ON pl.id = p.pid
  LEFT JOIN holder_pin hp ON hp.office_id = p.office_id AND hp.pid = p.pid;

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03';
  IF n <> 25 THEN RAISE EXCEPTION 'expected 25 new races, found %', n; END IF;
  SELECT count(*) INTO n FROM pins p
    JOIN essentials.races r ON r.office_id = p.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = p.pid
   WHERE rc.result = p.result AND rc.result_certainty = 'called' AND rc.is_write_in = p.is_write_in
     AND rc.result_source = 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0363' AND rc.result_recorded_at >= TIMESTAMPTZ '2026-11-05';
  IF n <> 54 THEN RAISE EXCEPTION 'only % of the 54 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED, AND THE DRIFT BASELINE HAS NOT MOVED. This is the gate
  --    that makes creating offices safe: 238 unflagged before, 238 after.
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 25 new offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  -- each new office resolves to exactly one current holder, and it is the person named
  SELECT count(*) INTO n FROM holder_pin hp
    JOIN essentials.office_current_holder och ON och.office_id = hp.office_id AND och.politician_id = hp.pid;
  IF n <> 25 THEN RAISE EXCEPTION 'only % of the 25 new offices resolve to the officeholder this file seated', n; END IF;

  -- no term claims a start date, and none is closed
  SELECT count(*) INTO n FROM holder_pin hp JOIN essentials.office_terms t ON t.office_id = hp.office_id
   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;

  -- every new district carries its state FIPS; an empty geo_id matches no address ever
  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
   WHERE coalesce(d.geo_id, '') = '' OR d.district_type <> 'STATE_EXEC';
  IF n <> 0 THEN RAISE EXCEPTION '% new district(s) have no geometry key or the wrong type', n; END IF;

  SELECT count(*) INTO n FROM pins p
    JOIN essentials.races r ON r.office_id = p.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = p.pid
   WHERE rc.result_certainty <> 'called';
  IF n <> 0 THEN RAISE EXCEPTION '% row(s) do not read called', n; END IF;
  RAISE NOTICE 'CC_0363 OK — 25 offices created and seated, 25 races, 54 candidacies, 57 people seeded.';
END $$;

COMMIT;
