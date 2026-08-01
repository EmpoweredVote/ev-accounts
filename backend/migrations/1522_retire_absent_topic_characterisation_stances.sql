-- 1522_retire_absent_topic_characterisation_stances.sql
--
-- Retire 13 published stance answers from the NO_QUOTE characterisation cohort whose cited site
-- carries NO CONTENT ON THE TOPIC. Same rule and same operator decision as 1520 and 1521: an absent
-- topic is NO STANCE, retired until it can be re-sourced. ALL 13 TOPICS ARE OWED RE-RESEARCH.
--   Rollback record: data/stance-retirement/2026-08-01-characterisation-remedies-rollback.json
--                    (the ONLY surviving copy of these rows' value, reasoning and sources)
--   Review:          data/stance-retirement/2026-08-01-characterisation-review.md
--
-- 🔴 VERIFIED ABSENT, NOT UNSURE. Every row below was re-checked on 2026-08-01 with
-- scripts/read-site.mjs --no-cache, AFTER the review was written, because crawl status is not stable.
-- Each search ran against RAW HTML (script/style stripped only) with the haystack size printed, so
-- extractor loss cannot be mistaken for an absent claim -- the failure that nearly cost us
-- neighbors4faye.com. Every apparent survivor was opened and read; all three were substrings:
-- Kirkland "rent" = Current/parents, Fairly "removal" = privacy-policy boilerplate, Hopper "team" =
-- a National Guard "Software/Cyber Team", LaHood "exemption" = PROPERTY TAX exemptions.
--
-- KYLE KIRKLAND x4 (kirkland2026.com, 13,883c raw, ONE page) -- this is a whole-person pattern, not
--   four rows. All four chairs were cut from a single clause, "Kyle will end over-regulation, restart
--   domestic production, and attack the cost-of-living crisis head-on", plus a four-item list naming
--   housing, food, gas and healthcare as expensive. MISS across the whole site: energy, oil, drilling,
--   fossil, permit, zoning, developer, insurance, coverage, employer, medicaid, medicare, uninsured,
--   "cut taxes", "tax cut", "lower taxes", "tax relief", "flat tax", "tax rate".
--   ⚠ His FIFTH row is the only one NOT in this cohort, and it is sound -- it quotes a real sentence
--   ("stop fentanyl, human trafficking, and cartel violence while respecting legal immigration"). He
--   keeps it. 5 -> 1 answers.
--
-- CAROLINE FAIRLY x2 (fairlyfortexas.com, 36,530c raw over 2 pages)
--   Deportation, chair 5 "deport all regardless of family ties": deport, traffick, amnesty all MISS.
--     The row's stated basis was that she "previously worked for Ronny Jackson" and that the
--     "Panhandle district is strongly pro-enforcement" -- 🔴 an employer and a district, not a source.
--   Trans Athletes, chair 5 "completely ban all transgender athletes": sports, athlet, biological,
--     team, compete all MISS. "radical gender ideology" IS verbatim -- about classroom materials and
--     library books. Adjacent content is not the topic.
--
-- ANDY HOPPER (hopper4texas.com, ~38,800c raw over 8 pages) -- Trans Athletes, chair 4. sports,
--   athlet, biological, compete all MISS. The row says so itself: "No specific trans-athlete bill
--   authored by him was found but his position is unambiguous ... strongly implies". A row that
--   declares its own inference is not a sourced row. ⚠ BOTH Trans Athletes rows in this cohort failed
--   the same way; the topic is worth a corpus-wide pass.
--
-- TOM CRADDICK (tomcraddick.com, 48,736c raw) -- Deportation, chair 4. deport, immigra, undocumented,
--   "illegal alien", amnesty, remove ALL MISS. The site has border-security spending ($3bn, state
--   troopers, organized-crime penalties). The row conceded "no authored mass deportation bill found".
--
-- CHRISTOPHER LANCIA (lanciaforcongress2026.org, 8,342c raw) -- Immigration, chair 4 "make it harder
--   to immigrate legally". immigra, visa, "green card", "legal status", citizenship, migrant ALL MISS.
--   One border sentence about drugs and crime. The row reasoned from what the site does NOT say
--   ("rather than any expansion of legal immigration or services").
--
-- MARC LAHOOD x2 (marclahood.com, 20,873c raw)
--   Religious Freedom, chair 4: religio, conscience, worship, prayer, Bible, "Ten Commandments" all
--     MISS. The only faith content is biography -- "brought him back to the Church", "his family, and
--     his faith". 🔴 PRESENCE IS NOT SUPPORT, and this is the Schwab case from 1521 exactly: personal
--     faith is biography; the topic asks about exemptions from generally applicable laws.
--   Immigration, chair 4: immigra MISS. "SECURING OUR BORDER THROUGH STATE-LED OPERATIONS" is verbatim
--     and real, but it is a BORDER position, and chair 4 is about levels of LEGAL immigration.
--     ⚠ Reclassified from reasoning-fix to retirement for consistency: this site fails the identical
--     test as Craddick and Lancia above, and the same test must give the same answer.
--
-- PHIL M. HERNANDEZ (philforvirginia.com, 33,115c raw over 4 pages) -- Housing, chair 2 "rent caps,
--   inclusionary units, publicly fund new housing". "affordable housing", zoning, "rent cap",
--   "public housing", inclusionary, homeown, eviction ALL MISS. The only housing content is the word
--   "housing" once, inside a cost-of-living list. None of chair 2's three mechanisms is on the site.
--
-- BROOKS BENSON (brooksbenson4utah.com, 4,530c raw) -- Housing, chair 4 "cut regulations and zoning
--   rules so private developers can build more housing". zoning, regulation, permit, affordab ALL MISS.
--   🔴 THE ROW REFUTES ITS OWN CHAIR IN WRITING: it describes "a growth-management approach that
--   prioritizes limiting development pace over affordability", and the site says "Infrastructure-first
--   development that serves families, NOT DEVELOPERS" with unmanaged growth listed as the problem.
--   ⚠ Retired rather than re-charted. His actual position -- gate approvals until roads, schools and
--   utilities exist -- is not on this axis at all: chair 3 offers "easier building permits" and he
--   wants harder ones. A position the scale cannot represent must not be forced onto it; every
--   available chair would misinform a voter.
--
-- ⚠ NOBODY IS EMPTIED. Kirkland 5->1, Benson 4->3, Lancia 5->4, Hernandez 6->5, Hopper 8->7,
-- Fairly 10->8, LaHood 12->10, Craddick 14->13. The 1494 rule is therefore not in play, but the
-- assertions below check it rather than assume it.

BEGIN;

CREATE TEMP TABLE _retire_1522 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1522 (politician_id, topic_id) VALUES
  ('d2ff9bbf-4434-4b81-a869-e3241e954e3c', 'a22215c3-6693-4bc2-b248-01aebba14570'),  -- Kyle Kirkland: Fossil Fuels
  ('d2ff9bbf-4434-4b81-a869-e3241e954e3c', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Kyle Kirkland: Housing
  ('d2ff9bbf-4434-4b81-a869-e3241e954e3c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Kyle Kirkland: Healthcare
  ('d2ff9bbf-4434-4b81-a869-e3241e954e3c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Kyle Kirkland: Taxes
  ('0dc7e2da-505d-42b6-af05-a2105ce81379', '44905f3b-e105-4f6c-afc7-5d223813dbac'),  -- Caroline Fairly: Deportation
  ('0dc7e2da-505d-42b6-af05-a2105ce81379', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'),  -- Caroline Fairly: Trans Athletes
  ('b266c38d-9763-48d4-bcba-7b44adf79ab9', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'),  -- Andy Hopper: Trans Athletes
  ('44d86767-7041-4ce9-9d03-ce23dd663c95', '44905f3b-e105-4f6c-afc7-5d223813dbac'),  -- Tom Craddick: Deportation
  ('c63201eb-c3e1-4bcd-b24a-995e9d367fc3', '4e2c69ce-591e-4197-9cd5-7aceff79d390'),  -- Christopher Lancia: Immigration
  ('786ac925-59d3-40e3-a9ce-b63a54f4caf4', '6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Marc LaHood: Religious Freedom
  ('786ac925-59d3-40e3-a9ce-b63a54f4caf4', '4e2c69ce-591e-4197-9cd5-7aceff79d390'),  -- Marc LaHood: Immigration
  ('e9cd8a4e-9e2b-4962-be21-7a2f68a650ba', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Phil M. Hernandez: Housing
  ('9a171371-be83-456e-acd5-ece936ee84ae', '669cac97-66a6-4087-b036-936fbe62efb3')   -- Brooks Benson: Housing
;

DO $$
DECLARE v_n int;
BEGIN
  -- Refuse to run against a shifted target set: 13 rows must be present before anything is deleted.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _retire_1522 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_n <> 13 THEN RAISE EXCEPTION 'expected 13 targeted answers, found % — target set has moved', v_n; END IF;
END $$;

DELETE FROM inform.politician_context c USING _retire_1522 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1522 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
  v_bad  text;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1522 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left; END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1522 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx; END IF;

  -- 🔴 THE 1494 RULE. None of these eight should be emptied; if one is, it must not be left with a
  -- research timestamp, because a SET timestamp with zero answers means "we looked and found nothing"
  -- and that is a real finding this migration has not earned the right to assert.
  SELECT string_agg(p.full_name, ', ') INTO v_bad
    FROM essentials.politicians p
   WHERE p.id IN (SELECT DISTINCT politician_id FROM _retire_1522)
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = p.id);
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'unexpectedly emptied: % — review the 1494 rule before proceeding', v_bad;
  END IF;
END $$;

COMMIT;
