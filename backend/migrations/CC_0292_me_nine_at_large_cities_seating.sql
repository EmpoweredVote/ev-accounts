-- CC_0292_me_nine_at_large_cities_seating.sql
-- Maine municipal skeleton, wave 2 — the NINE cities ROSTERS.md listed as "all at-large —
-- VERIFY EACH" after Bath (`CC_0291`) proved that column was a claim, not a fact:
--   Brewer 5 · Calais 7 · Caribou 7 · Eastport 5 · Ellsworth 7 · Old Town 7 ·
--   Presque Isle 7 · Rockland 5 · Sanford 7   =  57 offices, every one of them flagged
--   `is_vacant = true` with a NULL `vacant_since` and no `office_terms` row (R1).
--
-- ═══ 🔴 THE CHECK WAS RIGHT TO RUN AND THE HYPOTHESIS WAS WRONG ═══
--
-- R8 told the next session to count the wards on each city's own page, because Bath's nine
-- "At-Large" seats were seven ward seats. That check was run on all nine cities here.
--
--   🟢 NOT ONE OF THE NINE HAS A WARD SEAT. Every one of them elects its whole council at
--      large, and our At-Large titles were correct.
--
--   🔴 SIX OF THEM CARRY A `Mayor` OFFICE THAT IS NOT A SEAT. The same reading that cleared
--      the ward question found a different title defect, in two thirds of the set.
--
-- ▶ **A VERIFICATION PASS FINDS WHAT IS THERE, NOT WHAT YOU WENT LOOKING FOR.** Had this been
--   scoped to "count the wards", nine cities would have come back green and six phantom
--   offices would have survived the audit that was supposed to catch them.
--
-- ═══ 🔴 THE DEFECT: A ROTATING CHAIR MODELLED AS AN OFFICE, AND IT COSTS A REAL SEAT ═══
--
-- In six of the nine, the council elects one of its own members to preside, and that person is
-- styled Mayor, Council President or Council Chair. R5 already says a rotating role is a
-- parenthetical on a seat, never its own office. Modelled as an office it does two things at
-- once: it asserts to a voter that their city elects a Mayor, and it CONSUMES the seat that
-- the presiding councillor actually holds — so the city is one council seat short and the last
-- councillor has nowhere to sit. Exactly Bath's shape, wearing a different label.
--
--   city          | our model        | the city's own words                        | fix
--   --------------+------------------+---------------------------------------------+-------------------
--   Brewer        | 4 AL + Mayor     | charter §2: "five (5) members ... elected at | Mayor -> At-Large 5
--                 |                  | large"; §3 chairman "styled as Mayor"        |
--   Caribou       | 6 AL + Mayor     | charter §2.01(a) "seven (7) members elected  | Mayor -> At-Large 7
--                 |                  | ... at large"; §2.03 council elects the      |
--                 |                  | Mayor "from among its members"               |
--   Eastport      | 4 AL + Mayor     | charter §2 "5 members elected at large"; §3  | Mayor -> At-Large 5
--                 |                  | council elects "1 of its members as          |
--                 |                  | president of the council"                    |
--   Ellsworth     | 6 AL + Mayor     | "Seven City Council members are elected";    | Mayor -> At-Large 7
--                 |                  | no mayor on any municipal ballot             |
--   Presque Isle  | 6 AL + Mayor     | "seven individuals elected at-large";        | Mayor -> At-Large 7
--                 |                  | "Each year, the City Council elects a        |
--                 |                  | Council Chair"                               |
--   Rockland      | 4 AL + Mayor     | "The voters elect the five City Councilors.  | Mayor -> At-Large 5
--                 |                  | The Mayor is chosen by the Council for a     |
--                 |                  | 1-year term."                                |
--
-- 🟢 THREE OF THE NINE ARE CORRECT AS MODELLED, AND THE DIFFERENCE IS NOT COSMETIC:
--   Calais  — "City Councilors are elected at large by the citizens of Calais, AS IS THE
--             MAYOR." 6 councillors + a directly elected Mayor. Keep the Mayor office.
--   Sanford — Mayor is a separately nominated municipal office: the clerk's 2026 filings list
--             four qualified candidates "for Mayor" beside "City Council" filings that carry
--             no ward. 6 councillors + an elected Mayor. Keep the Mayor office.
--   Old Town— "seven elected councilors, including one Council President", and no mayoral
--             office exists in our schema or theirs. Nothing to change.
--
-- 🔴 SO "DOES THIS CITY HAVE A MAYOR?" HAS THREE ANSWERS, NOT TWO: directly elected (Calais,
--    Sanford), a rotating title worn by a councillor (Brewer, Caribou, Ellsworth, Presque
--    Isle, Rockland — and Eastport/Old Town call theirs President), or absent (Bath). Only the
--    first is an office. **Never infer it from whether the city uses the word.** Caribou's own
--    page says "Mayor Courtney Boma" in the same breath as a charter that gives the city seven
--    councillors and no mayoralty.
--
-- ═══ ⚠ WARDS EXIST IN THESE CITIES. THEY ARE VOTING WARDS, NOT COUNCIL DISTRICTS. ═══
-- Brewer's charter divides the city into wards and elects the council at large in the same
-- document; Eastport's 1935 charter does the same with four wards; Ellsworth ran a 2024
-- proposal to consolidate four wards into one for election-day administration. A session that
-- greps a Maine charter for "ward" and ward-titles the seats would invert Bath's defect and
-- tell voters they elect a councillor they do not. ▶ The test is the sentence that says how
-- COUNCILLORS ARE ELECTED, never the presence of the word "ward".
--
-- ═══ DATES: ALL UNKNOWN, DELIBERATELY (R4) ═══
-- `term_start` is the start of CONTINUOUS occupancy and a re-election never opens a new
-- `office_terms` row. Every one of these cities publishes a "Term Expires" year, and Caribou
-- publishes "First elected YYYY" for all seven. 🔴 NEITHER DATES ANYONE. An expiry is the end
-- of a TERM, not of an occupancy (R4's trap — writing it would silently un-seat people on
-- 1 January). "First elected" is a label about how someone ARRIVED and cannot exclude a gap
-- and a later return. All 56 get `start_precision => 'unknown'`; the gate below refuses any
-- term that carries a date. The published figures are recorded in ROSTERS.md as a dating lead.
--
-- ═══ 🔴 BREWER HAS A REAL, DATED VACANCY — THE FIRST ONE THIS PROGRAMME HAS SEEN ═══
-- Four of Brewer's five seats are filled. The fifth is genuinely empty, and unlike the 152
-- undated skeleton flags this one has a document behind it. City Council Minutes, Regular
-- Meeting of Tuesday 11 August 2026, Resolve 2026-B029:
--
--     "WHEREAS, Brewer City Councilor William Kimball has submitted a letter of resignation as
--      a member of the City Council of the City of Brewer dated July 29, 2026; and
--      WHEREAS, Mr. Kimball's term of office was not set to expire until November 16, 2027 ...
--      BE IT FURTHER RESOLVED, that the remainder of this vacancy shall be filled by vote of
--      the citizens of the City of Brewer at the next general election."
--
-- The same minutes' roll call records "Councilor Kimball-absent" for that meeting, so he was
-- still a member of record when it opened and the seat became empty when the council accepted
-- the resignation. ▶ `vacant_since = 2026-08-12`, the first day it was vacant — NOT the date
-- on the letter, and not today. This seat stays flagged, now as a DOCUMENTED vacancy of the
-- Florida kind rather than a skeleton. We write no `office_terms` vacancy span: Kimball was
-- never seeded, so there is no term to close.
--
-- ═══ 🔴 DEDUPE IS A GATE HERE, NOT A PRE-FLIGHT NOTE ═══
-- Two of the 56 collide with rows already in `politicians`, and they resolve OPPOSITE ways.
-- Bath's resolver matched on (first_name, last_name) + is_active and would have got one of
-- them wrong, silently. So every roster row below declares its disposition and the loop
-- REFUSES an undeclared collision:
--
--   'reuse'               — Dani O'Halloran, Brewer. Already present as Maine House District
--                           20 (geo_id 23020), active incumbent, and the legislature's own
--                           member profile gives her residence as Brewer. She holds BOTH
--                           seats; the Brewer council page lists her today and the 11 August
--                           minutes record her present. ⚠ That profile's biography calls her
--                           "Former ... Brewer City Council" and is simply out of date — a
--                           source can be authoritative for one field and stale for another.
--                           Pinned to her UUID so the reuse is a decision, not a match.
--   'new-despite-namesake'— Nancy Smith, Ellsworth. An active Nancy Smith exists: a Palmdale
--                           Elementary (California) board member seeded by CA_0158. Different
--                           person. A (first,last) resolver would have seated the Californian
--                           on the Maine seat and nothing would have errored.
--   'new'                 — the other 54, each gated on there being NO active namesake.
--
-- 🔴 The zero for those 54 was CONTROLLED: the identical predicate over two names known to be
-- present returned Emanuel Cleaver and Jared Golden, and the full_name-normalised variant
-- returned Cleaver too. The detector discriminates, so the zeros mean something.
--
-- ═══ SOURCES, all read 2026-10-25, from each body's own page ═══
--   Brewer       brewermaine.gov/159/City-Council · charter DocumentCenter/View/227 ·
--                AgendaCenter minutes _08112026-242
--   Calais       calaismaine.org/mayor-and-council
--   Caribou      cariboumaine.org/government/city-council/ · cariboumaine.org/pdf/BCityCharter.pdf
--   Eastport     eastport-me.gov/283/City-Council · charter: Maine P&S Laws 1935 c.66 §§2-3
--   Ellsworth    ellsworthmaine.gov/government/city-council/ (403 to curl; read in Playwright)
--                · nomination-paper notice for the 2026-11-03 municipal election
--   Old Town     old-town.org/councilors
--   Presque Isle presqueislemaine.gov/government/city_councilors.php
--   Rockland     rocklandmaine.gov/285/City-Council
--   Sanford      sanfordmaine.org/government/city_council/meet_the_council.php and
--                .../departments/election___voter_information/municipal_candidates.php
-- ⚠ No name, date or count in this migration comes from a search summary.
--
-- ⚠ A Maine municipal election falls on 2026-11-03, nine days after this is written, and every
-- one of these councils is staggered. Some of these 56 will change. That is not a reason to
-- wait: the alternative is to keep asserting to voters in nine cities that all 57 seats are
-- empty. A December re-check is recorded in ROSTERS.md.

BEGIN;

CREATE TEMP TABLE _roster (
  city          text NOT NULL,
  seat          text NOT NULL,
  office_id     uuid PRIMARY KEY,
  new_title     text NOT NULL,
  full_name     text NOT NULL,
  first_name    text NOT NULL,
  last_name     text NOT NULL,
  disposition   text NOT NULL CHECK (disposition IN ('new','reuse','new-despite-namesake')),
  pin_politician_id uuid,
  note          text,
  politician_id uuid
) ON COMMIT DROP;

-- The Brewer seat nobody holds. It is retitled like the rest, then flagged with a real date.
CREATE TEMP TABLE _vacancy (
  city         text NOT NULL,
  office_id    uuid PRIMARY KEY,
  new_title    text NOT NULL,
  vacant_since date NOT NULL,
  note         text NOT NULL
) ON COMMIT DROP;

-- office_id is pinned by UUID, never by title: six Mayor offices are renumbered below, so
-- matching on the old title would be order-dependent.
INSERT INTO _roster (city, seat, office_id, new_title, full_name, first_name, last_name, disposition, pin_politician_id, note) VALUES
  -- ── Brewer: 5 at-large; the Mayor is the council's own chairman (charter §3) ───────────
  ('Brewer','At-Large 1','f6caac11-4c71-4d10-aab5-5ce8b7120273','Council Member (At-Large 1)','Jenn Morin','Jenn','Morin','new',NULL,'listed as Mayor - a ROTATING ROLE: charter sec.3, the council elects one of its members chairman, "styled as Mayor"'),
  ('Brewer','At-Large 2','82f79581-e194-4572-8999-f6018f154d95','Council Member (At-Large 2)','Michele LaBree Daniels','Michele','LaBree Daniels','new',NULL,NULL),
  ('Brewer','At-Large 3','6bed7644-4f11-4d51-949c-822f55132a03','Council Member (At-Large 3)','Soubanh Phanthay','Soubanh','Phanthay','new',NULL,NULL),
  ('Brewer','At-Large 4','bf91d853-3efd-483c-95ed-eb65d07308d7','Council Member (At-Large 4)','Dani O''Halloran','Dani','O''Halloran','reuse','59df0b0d-f559-4e37-8f3a-1f8ae5b09485','also Maine House District 20 - a GENUINE second seat, not a duplicate row'),

  -- ── Calais: 6 at-large + a DIRECTLY ELECTED Mayor; the Mayor office is correct ─────────
  ('Calais','Mayor',      '8618646a-4527-4ad4-8b10-e6f0cdb5b5ca','Mayor',                      'Marcia Rogers','Marcia','Rogers','new',NULL,'"City Councilors are elected at large by the citizens of Calais, as is the Mayor"'),
  ('Calais','At-Large 1','48e5b92b-8fb6-4187-b577-c1920709f4bf','Council Member (At-Large 1)','Michael Sherrard','Michael','Sherrard','new',NULL,NULL),
  ('Calais','At-Large 2','7c0600e4-654e-41c2-99de-94738061368a','Council Member (At-Large 2)','Elery Beale','Elery','Beale','new',NULL,NULL),
  ('Calais','At-Large 3','e92efb69-1bb2-47d8-88c7-e1423a3d6a60','Council Member (At-Large 3)','C. Edward Moreside','Edward','Moreside','new',NULL,'the city styles him "C. Edward Moreside"'),
  ('Calais','At-Large 4','5106e440-5c80-49ab-a10a-c63082423759','Council Member (At-Large 4)','William Quinn','William','Quinn','new',NULL,NULL),
  ('Calais','At-Large 5','0bb88927-5b4c-4f89-ae34-1238c6af557c','Council Member (At-Large 5)','Peter Foster','Peter','Foster','new',NULL,NULL),
  ('Calais','At-Large 6','6c29a82d-b530-4b01-a41c-f54fa4d4cd24','Council Member (At-Large 6)','James Macdonald','James','Macdonald','new',NULL,NULL),

  -- ── Caribou: charter §2.01(a) seven at large; §2.03 Mayor elected from among them ──────
  ('Caribou','At-Large 1','4f2aa40b-d235-4470-b034-732dfb014904','Council Member (At-Large 1)','Jody Smith','Jody','Smith','new',NULL,'listed as Deputy Mayor - a ROTATING ROLE (charter sec. 2.03)'),
  ('Caribou','At-Large 2','9aa70617-0d2d-4d3d-9fbd-e7140cc2be08','Council Member (At-Large 2)','Lori Knight Phair','Lori','Knight Phair','new',NULL,NULL),
  ('Caribou','At-Large 3','b408e557-aa29-4310-b13f-c3be4debb86a','Council Member (At-Large 3)','Dan Bagley','Dan','Bagley','new',NULL,NULL),
  ('Caribou','At-Large 4','7166c161-4b17-427d-98ff-884fc6a3b366','Council Member (At-Large 4)','Jennifer Kelley','Jennifer','Kelley','new',NULL,NULL),
  ('Caribou','At-Large 5','e3454a9d-5202-4fc6-9f93-c1db82b0ffe2','Council Member (At-Large 5)','Tamara Lovewell','Tamara','Lovewell','new',NULL,NULL),
  ('Caribou','At-Large 6','32d994aa-2b18-460a-ba12-f75bd101677a','Council Member (At-Large 6)','Paul Watson','Paul','Watson','new',NULL,NULL),
  ('Caribou','At-Large 7','18393c45-9e8f-4602-bf44-3a21c4ffdfcc','Council Member (At-Large 7)','Courtney Boma','Courtney','Boma','new',NULL,'was titled Mayor - a ROTATING ROLE (charter sec. 2.03), so this is the 7th council seat'),

  -- ── Eastport: 5 at large (P&S 1935 c.66 §2); §3 council elects a President ─────────────
  ('Eastport','At-Large 1','fb798dea-25a1-425f-a4c7-bb7957c3baa9','Council Member (At-Large 1)','Colleen Dana-Cummings','Colleen','Dana-Cummings','new',NULL,NULL),
  ('Eastport','At-Large 2','23321ac6-2656-4689-9206-46affff260dc','Council Member (At-Large 2)','David R. Morang','David','Morang','new',NULL,NULL),
  ('Eastport','At-Large 3','df490d25-110f-478b-b054-467002bf83a9','Council Member (At-Large 3)','Rhonda Stevens','Rhonda','Stevens','new',NULL,NULL),
  ('Eastport','At-Large 4','b4b95984-66c4-41c1-bd54-d95e16e8c60d','Council Member (At-Large 4)','Alvah Seeley III','Alvah','Seeley','new',NULL,'the city styles him "Alvah Seeley, III"'),
  ('Eastport','At-Large 5','0727afbd-938f-443d-b050-efca6e8efd8c','Council Member (At-Large 5)','William Boone','William','Boone','new',NULL,'was titled Mayor - Eastport has none; he is Council President, a ROTATING ROLE (charter sec. 3)'),

  -- ── Ellsworth: seven council members, no mayor on any ballot ───────────────────────────
  ('Ellsworth','At-Large 1','3307b0de-f45b-4f5c-ba37-6c5de7d3e15c','Council Member (At-Large 1)','Carol Patterson-Martineau','Carol','Patterson-Martineau','new',NULL,NULL),
  ('Ellsworth','At-Large 2','157852ab-5346-4a9f-a6b7-5f6cbdd4812b','Council Member (At-Large 2)','Patrick Shea','Patrick','Shea','new',NULL,NULL),
  ('Ellsworth','At-Large 3','f5bd2ae5-93ec-487f-82ea-e67841090629','Council Member (At-Large 3)','Marinna Smith','Marinna','Smith','new',NULL,NULL),
  ('Ellsworth','At-Large 4','521c02c7-002a-4696-9351-0f5baecfddf3','Council Member (At-Large 4)','Nancy Smith','Nancy','Smith','new-despite-namesake',NULL,'an active Nancy Smith exists on Palmdale Elementary, California (CA_0158) - a DIFFERENT person'),
  ('Ellsworth','At-Large 5','3f06b840-4e96-48a7-8912-828dfac27a70','Council Member (At-Large 5)','Steven E. O''Halloran','Steven','O''Halloran','new',NULL,'no relation asserted to Dani O''Halloran of Brewer; different city, different person'),
  ('Ellsworth','At-Large 6','f76cbf98-0dcc-44cf-bbb7-53bf58e30f2c','Council Member (At-Large 6)','Patrick Lyons','Patrick','Lyons','new',NULL,NULL),
  ('Ellsworth','At-Large 7','2d19fd89-c317-4242-b8f0-8423dec4f7bb','Council Member (At-Large 7)','Tabatha White','Tabatha','White','new',NULL,'was titled Mayor - Ellsworth elects no mayor; the 2026 ballot carries City Council seats only'),

  -- ── Old Town: already correct, 7 at-large, no mayoral office ───────────────────────────
  ('Old Town','At-Large 1','922bef22-70ee-483c-9678-2bb268727873','Council Member (At-Large 1)','Christian Pushor','Christian','Pushor','new',NULL,'listed as City Council President - a ROTATING ROLE, correctly not an office'),
  ('Old Town','At-Large 2','26487a5c-5b2f-48d8-a47e-e683c11c49a0','Council Member (At-Large 2)','Michael May','Michael','May','new',NULL,NULL),
  ('Old Town','At-Large 3','cd815f9c-d142-49c6-9466-ee7369053883','Council Member (At-Large 3)','Linda McLeod','Linda','McLeod','new',NULL,NULL),
  ('Old Town','At-Large 4','e6ba92d0-c4e4-49e1-9501-d6b9cabfe552','Council Member (At-Large 4)','Charlene Virgilio','Charlene','Virgilio','new',NULL,NULL),
  ('Old Town','At-Large 5','af8ae401-005d-4d5e-b6e5-1334332dfbd8','Council Member (At-Large 5)','Katrina Wynn','Katrina','Wynn','new',NULL,NULL),
  ('Old Town','At-Large 6','902198e5-b959-4029-ba15-c68ac4ca84b9','Council Member (At-Large 6)','Zachary Wyles','Zachary','Wyles','new',NULL,NULL),
  ('Old Town','At-Large 7','d07b1036-2390-4e8b-a9f2-0fea98e3b886','Council Member (At-Large 7)','David Wight','David','Wight','new',NULL,NULL),

  -- ── Presque Isle: "seven individuals elected at-large"; the Chair is annual ────────────
  ('Presque Isle','At-Large 1','29367be5-c9c9-411a-b0b6-9da51e31a376','Council Member (At-Large 1)','Jeffery Willette','Jeffery','Willette','new',NULL,'listed as Chair - a ROTATING ROLE, elected by the council each year'),
  ('Presque Isle','At-Large 2','0d70457f-428a-4341-ac9b-879b63dd2d0e','Council Member (At-Large 2)','Doug Cyr','Doug','Cyr','new',NULL,NULL),
  ('Presque Isle','At-Large 3','2e872667-173c-4f03-a8f2-749c0729b531','Council Member (At-Large 3)','Craig Green','Craig','Green','new',NULL,NULL),
  ('Presque Isle','At-Large 4','2c0313d9-217e-42eb-9a23-ccc6e91cf241','Council Member (At-Large 4)','Hank King','Hank','King','new',NULL,'listed as Deputy Chair - a ROTATING ROLE'),
  ('Presque Isle','At-Large 5','dc975a9b-a5fc-455d-a2b8-d3cfd56bed5a','Council Member (At-Large 5)','Michael Chasse','Michael','Chasse','new',NULL,NULL),
  ('Presque Isle','At-Large 6','219aa51d-1908-4a00-87a8-7dfad2d8c55c','Council Member (At-Large 6)','Herman Legassie','Herman','Legassie','new',NULL,NULL),
  ('Presque Isle','At-Large 7','065b5823-7a8c-40fc-a275-7d912c4a65b5','Council Member (At-Large 7)','Debra Plummer','Debra','Plummer','new',NULL,'was titled Mayor - Presque Isle has none; this is the 7th at-large seat'),

  -- ── Rockland: "The voters elect the five City Councilors. The Mayor is chosen by the
  --    Council for a 1-year term." ─────────────────────────────────────────────────────
  ('Rockland','At-Large 1','443a5376-b32f-41eb-acbf-971f58ff4e03','Council Member (At-Large 1)','Nate Davis','Nate','Davis','new',NULL,NULL),
  ('Rockland','At-Large 2','4fe3a9de-2573-4e7c-97b6-b2d55126cc8d','Council Member (At-Large 2)','Penelope York','Penelope','York','new',NULL,NULL),
  ('Rockland','At-Large 3','54427f11-5335-4916-80fb-97d97eba3296','Council Member (At-Large 3)','Kaitlin Callahan','Kaitlin','Callahan','new',NULL,NULL),
  ('Rockland','At-Large 4','cd4f5777-5243-4cb1-a87c-b57ba509c152','Council Member (At-Large 4)','Nicole Kalloch','Nicole','Kalloch','new',NULL,NULL),
  ('Rockland','At-Large 5','758c0601-fdce-4dde-bf14-fbdce5df0847','Council Member (At-Large 5)','Adam Lachman','Adam','Lachman','new',NULL,'was titled Mayor - chosen by the Council for a 1-year term, so the 5th elected seat'),

  -- ── Sanford: 6 at-large + a DIRECTLY ELECTED Mayor; the Mayor office is correct ────────
  ('Sanford','Mayor',      '1dd3b4f1-11d8-45ff-938c-4581514b35e0','Mayor',                      'Becky Brink','Becky','Brink','new',NULL,'the clerk''s 2026 filings list four qualified candidates "for Mayor" - a contested municipal office'),
  ('Sanford','At-Large 1','36c67ba0-4c24-485d-ae50-e72e8c6eb77f','Council Member (At-Large 1)','Maura Herlihy','Maura','Herlihy','new',NULL,'listed as Deputy Mayor - a ROTATING ROLE, not a seat'),
  ('Sanford','At-Large 2','761e7a12-ddcf-4f57-b206-a82adf0636ee','Council Member (At-Large 2)','Ayn Hanselmann','Ayn','Hanselmann','new',NULL,NULL),
  ('Sanford','At-Large 3','c4390872-c8e7-41ed-8c9f-c6abb0bd3955','Council Member (At-Large 3)','Nathan Hitchcock','Nathan','Hitchcock','new',NULL,NULL),
  ('Sanford','At-Large 4','d124cd76-ea54-4c01-9d2a-e0b601b88bfb','Council Member (At-Large 4)','Jonathan Martell','Jonathan','Martell','new',NULL,NULL),
  ('Sanford','At-Large 5','f581aaff-8615-4246-907b-c9dea6f84c0b','Council Member (At-Large 5)','Pete Tranchemontagne','Pete','Tranchemontagne','new',NULL,NULL),
  ('Sanford','At-Large 6','e17170aa-4299-48e6-8edb-b8b3dc9fe9d0','Council Member (At-Large 6)','Charlene Plante','Charlene','Plante','new',NULL,'the contact page styles her "Charlene S. Plante"; the roster page calls her "Cheeny"');

INSERT INTO _vacancy (city, office_id, new_title, vacant_since, note) VALUES
  ('Brewer','422089ff-a537-4dea-85f7-4926e6eb9287','Council Member (At-Large 5)','2026-08-12',
   'William Kimball resigned (letter dated 2026-07-29); Brewer City Council Resolve 2026-B029 of '
   '2026-08-11 accepted it and declared the vacancy, to be filled at the 2026-11-03 election for '
   'the unexpired term ending 2027-11-16. He was recorded absent, not departed, at that meeting, '
   'so the first vacant day is the day after. This office was titled Mayor, which Brewer does not '
   'elect (charter sec. 2: five members elected at large; sec. 3: the chairman is styled Mayor).');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_txt text;
BEGIN
  -- every office_id resolves, and to the right city's City Council
  SELECT count(*) INTO n
    FROM (SELECT city, office_id FROM _roster UNION ALL SELECT city, office_id FROM _vacancy) r
    JOIN essentials.offices o     ON o.id = r.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of ' || r.city || ', Maine, US' AND c.name = 'City Council';
  IF n <> 57 THEN RAISE EXCEPTION 'CC_0292: % of 57 office_ids resolve to the named Maine city council', n; END IF;

  -- and the nine cities hold EXACTLY these 57 offices and no others
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('City of Brewer, Maine, US','City of Calais, Maine, US','City of Caribou, Maine, US',
                    'City of Eastport, Maine, US','City of Ellsworth, Maine, US','City of Old Town, Maine, US',
                    'City of Presque Isle, Maine, US','City of Rockland, Maine, US','City of Sanford, Maine, US');
  IF n <> 57 THEN RAISE EXCEPTION 'CC_0292: the nine cities hold % offices, expected 57 - the roster is stale', n; END IF;

  -- nothing may already be seated
  SELECT count(*) INTO bad FROM _roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0292: % office(s) already carry a term', bad; END IF;

  -- the skeleton signature (R1): all 57 flagged, none dated
  SELECT count(*) INTO bad
    FROM (SELECT office_id FROM _roster UNION ALL SELECT office_id FROM _vacancy) r
    JOIN essentials.offices o ON o.id = r.office_id
   WHERE NOT (o.is_vacant AND o.vacant_since IS NULL);
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0292: % office(s) are not flagged-without-a-date - that is not the Maine '
                    'skeleton shape, read the row before seating', bad;
  END IF;

  -- 🔴 the mayoral premise, stated before it is acted on: exactly 8 mayoral offices exist
  -- across the nine cities today (all but Old Town), and exactly 2 may survive.
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title ILIKE '%mayor%'
     AND g.name IN ('City of Brewer, Maine, US','City of Calais, Maine, US','City of Caribou, Maine, US',
                    'City of Eastport, Maine, US','City of Ellsworth, Maine, US','City of Old Town, Maine, US',
                    'City of Presque Isle, Maine, US','City of Rockland, Maine, US','City of Sanford, Maine, US');
  IF n <> 8 THEN
    RAISE EXCEPTION 'CC_0292: expected 8 mayoral offices across the nine cities before the fix, found % '
                    '- re-read each charter before proceeding', n;
  END IF;

  -- every declared reuse must point at a real, active person whose name matches
  SELECT string_agg(r.full_name, ', ') INTO v_txt FROM _roster r
   WHERE r.disposition = 'reuse'
     AND NOT EXISTS (SELECT 1 FROM essentials.politicians p
                      WHERE p.id = r.pin_politician_id AND p.is_active
                        AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
                        AND lower(btrim(p.last_name))  = lower(btrim(r.last_name)));
  IF v_txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0292: pinned reuse does not resolve: %', v_txt; END IF;

  -- and every declared namesake must actually exist, or the declaration is stale
  SELECT string_agg(r.full_name, ', ') INTO v_txt FROM _roster r
   WHERE r.disposition = 'new-despite-namesake'
     AND NOT EXISTS (SELECT 1 FROM essentials.politicians p
                      WHERE p.is_active
                        AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
                        AND lower(btrim(p.last_name))  = lower(btrim(r.last_name)));
  IF v_txt IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0292: % was declared a namesake collision and no namesake exists - the '
                    'declaration is stale, re-run the dedupe', v_txt;
  END IF;
END $$;

-- ─── 🔴 Retitle: six phantom Mayor offices become the council seats they always were ─────
UPDATE essentials.offices o SET title = r.new_title
  FROM _roster r WHERE o.id = r.office_id AND o.title IS DISTINCT FROM r.new_title;

UPDATE essentials.offices o SET title = v.new_title
  FROM _vacancy v WHERE o.id = v.office_id AND o.title IS DISTINCT FROM v.new_title;

-- ─── People ──────────────────────────────────────────────────────────────────────────────
-- 🔴 Resolved one row at a time, because the two collisions resolve OPPOSITE ways and a
-- (first_name, last_name) resolver cannot tell them apart. An UNDECLARED collision is fatal.
-- 🔴 is_incumbent EXPLICITLY true: it defaults to false, and a seated person inserted without
-- it is hidden from address search (CLAUDE.md).
DO $$
DECLARE r record; c int; new_id uuid; src text;
BEGIN
  FOR r IN SELECT * FROM _roster ORDER BY city, seat LOOP
    src := 'City of ' || r.city || ', Maine official roster, read 2026-10-25 (CC_0292)';

    IF r.disposition = 'reuse' THEN
      UPDATE _roster SET politician_id = r.pin_politician_id WHERE office_id = r.office_id;
      -- a reused person must still be flagged an active incumbent
      UPDATE essentials.politicians SET is_incumbent = true
       WHERE id = r.pin_politician_id AND is_incumbent IS DISTINCT FROM true;
      CONTINUE;
    END IF;

    SELECT count(*) INTO c FROM essentials.politicians p
     WHERE p.is_active
       AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
       AND lower(btrim(p.last_name))  = lower(btrim(r.last_name));

    IF c > 0 AND r.disposition <> 'new-despite-namesake' THEN
      RAISE EXCEPTION 'CC_0292: % (% %) collides with % active row(s) and the roster did not '
                      'declare it - read the row and choose reuse or new-despite-namesake',
                      r.full_name, r.city, r.seat, c;
    END IF;

    -- 🔴 The repo's DUPLICATE_POLITICIAN_NAME guard fires on Nancy Smith, and it is RIGHT to:
    -- an active Nancy Smith already sits on Palmdale Elementary in California (CA_0158), with a
    -- race edge of her own. It is a DIFFERENT person — a Maine city councillor 3,000 miles away,
    -- read off Ellsworth's own council page. The exemption is opened for that ONE insert and
    -- closed again immediately, so the other 55 stay under the guard.
    IF r.disposition = 'new-despite-namesake' THEN
      PERFORM set_config('essentials.allow_duplicate_name', 'on', true);
    END IF;

    INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, true, src)
    RETURNING id INTO new_id;

    PERFORM set_config('essentials.allow_duplicate_name', 'off', true);

    UPDATE _roster SET politician_id = new_id WHERE office_id = r.office_id;
  END LOOP;
END $$;

-- ─── Seat them ───────────────────────────────────────────────────────────────────────────
-- All 56 are unknown-start, so none can go through `seat_officeholder` — it refuses a NULL
-- term_start by design. Safe here only because no seat has a predecessor to close.
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM _roster ORDER BY city, seat LOOP
    IF r.politician_id IS NULL THEN
      RAISE EXCEPTION 'CC_0292: % % did not resolve to a person', r.city, r.seat;
    END IF;
    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, how_started, source)
    VALUES (r.office_id, r.politician_id, NULL, 'unknown', 'unknown',
            'City of ' || r.city || ', Maine official roster, read 2026-10-25 (CC_0292); '
            || 'start_precision unknown - the published "Term Expires" is the end of a TERM, not '
            || 'of an occupancy, and "First elected" cannot exclude a gap and a later return');
    n := n + 1;
  END LOOP;
  IF n <> 56 THEN RAISE EXCEPTION 'CC_0292: expected 56 seatings, got %', n; END IF;
END $$;

-- ─── 🔴 Clear the flag on exactly the seats filled, in the SAME transaction (R2) ─────────
UPDATE essentials.offices o SET is_vacant = false, vacant_since = NULL
  FROM _roster r WHERE o.id = r.office_id AND o.is_vacant;

-- ─── And date the one real vacancy, which STAYS flagged ─────────────────────────────────
UPDATE essentials.offices o SET is_vacant = true, vacant_since = v.vacant_since
  FROM _vacancy v WHERE o.id = v.office_id;

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_unflagged int; v_total int; v_txt text;
BEGIN
  SELECT count(*) INTO n FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id AND t.politician_id = r.politician_id;
  IF n <> 56 THEN RAISE EXCEPTION 'CC_0292: expected 56 terms, found %', n; END IF;

  -- 🔴 exactly two mayoral offices survive across the nine cities: Calais and Sanford
  SELECT string_agg(g.name || ' / ' || o.title, ', ' ORDER BY g.name) INTO v_txt
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title ILIKE '%mayor%'
     AND g.name IN ('City of Brewer, Maine, US','City of Calais, Maine, US','City of Caribou, Maine, US',
                    'City of Eastport, Maine, US','City of Ellsworth, Maine, US','City of Old Town, Maine, US',
                    'City of Presque Isle, Maine, US','City of Rockland, Maine, US','City of Sanford, Maine, US');
  IF v_txt IS DISTINCT FROM 'City of Calais, Maine, US / Mayor, City of Sanford, Maine, US / Mayor' THEN
    RAISE EXCEPTION 'CC_0292: mayoral offices across the nine cities are [%], expected Calais and Sanford only', v_txt;
  END IF;

  -- 🔴 and no other rotating role became a seat anywhere in the nine
  SELECT string_agg(DISTINCT o.title, ', ') INTO v_txt FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE (o.title ILIKE '%chair%' OR o.title ILIKE '%president%' OR o.title ILIKE '%deputy%')
     AND g.name IN ('City of Brewer, Maine, US','City of Calais, Maine, US','City of Caribou, Maine, US',
                    'City of Eastport, Maine, US','City of Ellsworth, Maine, US','City of Old Town, Maine, US',
                    'City of Presque Isle, Maine, US','City of Rockland, Maine, US','City of Sanford, Maine, US');
  IF v_txt IS NOT NULL THEN RAISE EXCEPTION 'CC_0292: a rotating role was made into a seat: %', v_txt; END IF;

  -- per-city at-large seat counts match each city's own description of itself
  SELECT string_agg(x.city || '=' || x.n, ', ' ORDER BY x.city) INTO v_txt FROM (
    SELECT replace(replace(g.name, 'City of ', ''), ', Maine, US', '') AS city, count(*)::text AS n
      FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE o.title LIKE 'Council Member (At-Large %'
       AND g.name IN ('City of Brewer, Maine, US','City of Calais, Maine, US','City of Caribou, Maine, US',
                      'City of Eastport, Maine, US','City of Ellsworth, Maine, US','City of Old Town, Maine, US',
                      'City of Presque Isle, Maine, US','City of Rockland, Maine, US','City of Sanford, Maine, US')
     GROUP BY 1) x;
  IF v_txt IS DISTINCT FROM 'Brewer=5, Calais=6, Caribou=7, Eastport=5, Ellsworth=7, Old Town=7, Presque Isle=7, Rockland=5, Sanford=6' THEN
    RAISE EXCEPTION 'CC_0292: at-large seat counts are [%], which disagrees with the charters', v_txt;
  END IF;

  -- no ward seat was invented: these nine elect their councils at large
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title ILIKE '%ward%'
     AND g.name IN ('City of Brewer, Maine, US','City of Calais, Maine, US','City of Caribou, Maine, US',
                    'City of Eastport, Maine, US','City of Ellsworth, Maine, US','City of Old Town, Maine, US',
                    'City of Presque Isle, Maine, US','City of Rockland, Maine, US','City of Sanford, Maine, US');
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0292: % ward seat(s) exist in the nine - every one of these cities elects '
                    'its council AT LARGE; a voting ward is not a council district', bad;
  END IF;

  SELECT count(*) INTO bad FROM _roster r JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0292: % seated person(s) are not active incumbents', bad; END IF;

  -- R4: no seat may be dated
  SELECT count(*) INTO bad FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id
   WHERE t.term_start IS NOT NULL OR t.start_precision <> 'unknown';
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0292: % term(s) carry a date - a published term expiry cannot establish '
                    'continuous occupancy, and writing one un-seats people on 1 January', bad;
  END IF;

  -- the reuse really did reuse: Dani O'Halloran holds two seats on ONE politician row
  SELECT count(*) INTO n FROM essentials.office_terms t
   WHERE t.politician_id = '59df0b0d-f559-4e37-8f3a-1f8ae5b09485';
  IF n <> 2 THEN
    RAISE EXCEPTION 'CC_0292: Dani O''Halloran holds % term(s), expected 2 (Maine House 20 + Brewer council)', n;
  END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE is_active AND lower(first_name) = 'dani' AND lower(last_name) = 'o''halloran';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0292: % active Dani O''Halloran rows - the reuse created a duplicate', n; END IF;

  -- and the namesake really did split: two distinct active Nancy Smiths, different offices
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE is_active AND lower(first_name) = 'nancy' AND lower(last_name) = 'smith';
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0292: % active Nancy Smith rows, expected 2 (Ellsworth ME + Palmdale CA)', n; END IF;

  -- R2 gate 1: nothing in the nine still flagged EXCEPT Brewer's documented vacancy
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.is_vacant
     AND g.name IN ('City of Brewer, Maine, US','City of Calais, Maine, US','City of Caribou, Maine, US',
                    'City of Eastport, Maine, US','City of Ellsworth, Maine, US','City of Old Town, Maine, US',
                    'City of Presque Isle, Maine, US','City of Rockland, Maine, US','City of Sanford, Maine, US')
     AND o.id NOT IN (SELECT office_id FROM _vacancy);
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0292: % office(s) in the nine are still flagged vacant', bad; END IF;

  -- and that vacancy is DATED, which is what separates it from the skeleton flag it replaced
  SELECT count(*) INTO bad FROM _vacancy v JOIN essentials.offices o ON o.id = v.office_id
   WHERE NOT (o.is_vacant AND o.vacant_since = v.vacant_since);
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0292: Brewer''s vacancy is not flagged with its date'; END IF;

  -- R2 gate 2: nothing unflagged-and-unseated (a new me|LOCAL DEAD_GEOGRAPHY bucket)
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE NOT o.is_vacant
     AND g.name IN ('City of Brewer, Maine, US','City of Calais, Maine, US','City of Caribou, Maine, US',
                    'City of Eastport, Maine, US','City of Ellsworth, Maine, US','City of Old Town, Maine, US',
                    'City of Presque Isle, Maine, US','City of Rockland, Maine, US','City of Sanford, Maine, US')
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0292: % office(s) are unflagged AND unseated - a new me|LOCAL '
                    'DEAD_GEOGRAPHY bucket that will redden the reachability gate', bad;
  END IF;

  -- the global invariant: zero seated-and-flagged, repo-wide
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.is_vacant AND och.politician_id IS NOT NULL;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0292: % office(s) are seated AND flagged - the is_vacant trap', bad; END IF;

  -- R3: total falls by 56, unflagged does NOT move
  SELECT count(*) FILTER (WHERE NOT o.is_vacant), count(*) INTO v_unflagged, v_total
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 239 THEN
    RAISE EXCEPTION 'CC_0292: unflagged offices_missing_terms is %, expected the 239 baseline', v_unflagged;
  END IF;
  IF v_total <> 335 THEN
    RAISE EXCEPTION 'CC_0292: total offices_missing_terms is %, expected 391 - 56 = 335', v_total;
  END IF;

  RAISE NOTICE 'CC_0292 OK - 56 seated across 9 Maine cities, 6 phantom Mayor offices retitled, '
               'Brewer vacancy dated 2026-08-12; missing_terms 335/96/239';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS WAVE ADDS (R9 in ROSTERS.md): "DOES THIS CITY HAVE A MAYOR?" IS A QUESTION
-- ABOUT HOW THE PRESIDING OFFICER IS CHOSEN, NOT ABOUT WHETHER THE CITY USES THE WORD.
-- Six of these nine printed "Mayor" or "Council President" beside a councillor's name and held
-- no such office. Modelling the role as a seat tells a voter they elect a mayor they do not,
-- and silently eats the seat its holder actually occupies — so the council comes out one short
-- and the shortfall looks like a vacancy.
-- ▶ Read the sentence that says who ELECTS the presiding officer. "The Mayor is chosen by the
--   Council" and "elected at large by the citizens, as is the Mayor" are three words apart and
--   opposite in meaning.
-- ▶ And R8's lesson generalises: the ward check cleared all nine, and running it is what
--   surfaced this. A verification pass finds what is there, not what it went looking for.
