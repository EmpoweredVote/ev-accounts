-- CA_0182_merge_seatless_duplicate_rows_into_seated_twins.sql
-- Merge 16 seatless DUPLICATE person rows into their seated twins, and deactivate the duplicates. Part of the
-- "active incumbent with no office_terms row" clean-up (CA_0180, CA_0181). Same pattern as CC_0102 and CA_0180:
-- the SEATED row is the person; what hangs on the duplicate moves to it; nothing is deleted.
--
-- EACH PAIR (duplicate -> seated twin, and the seat the twin holds):
--   Arizona statewide officials: a 2026 race seed created a second row for each and attached the race to it.
--   The race rows themselves say is_incumbent = true for the same office the twin holds:
--     Adrian Fontes -> Adrian Fontes (Secretary of State) | Katie Hobbs -> Katie Hobbs (Governor)
--     Kevin Thompson, Nick Myers -> same names (Corporation Commission) | Les Presmyk -> Les Presmyk (State Mine
--     Inspector) | Tom Horne -> Tom Horne (Superintendent of Public Instruction)
--   Dan Brotman -> Daniel Brotman (Glendale City Council; the Jun 2026 race row says incumbent)
--   Martha Hawk -> Marty Hawk (Monroe County, Indiana, Council District 3; both race rows are for that seat; one
--     spells her "Matha Hawk")
--   Eloy Morales Jr. -> Eloy Morales (Inglewood City Council District 3; the city lists the councilmember as
--     "Eloy Morales, Jr."). The duplicate holds his three CONFIRMED committees ($87,492).
--   Kimberley Driscoll -> Kim Driscoll (Lieutenant Governor of Massachusetts). The duplicate's own legacy office_id
--     is that office, and it holds her only campaign-finance link: OCPF filer 15268 "Driscoll, Kimberley", confirmed,
--     $6,532,256 across 15,269 contributions. Her seated row shows no money today; after this file it does.
--   Michael L. Connolly -> Mike Connolly (Massachusetts House, 26th Middlesex; legacy office_id = that seat;
--     OCPF filer 15470 "Connolly, Michael L.", confirmed).
--   Katrina Ladwig -> Katrina W Ladwig, Roger Taylor -> Roger L Taylor (Indian Creek Township Board, Monroe County,
--     Indiana; the duplicates' legacy office is another seat slot of the same 3-seat board), Thelma Kelley Jeffries
--     -> Thelma K Jeffries (Clear Creek Township Trustee; same office).
--   Richard A. Hyer -> Richard Hyer (Ogden City Council District 2), Bettina Smith Edmondson -> same name (Layton
--     City Council). These duplicates carry only a contact row and an image.
--
-- WHAT MOVES: 9 race_candidates rows; 5 committee links (with their contributions, aggregates and ingestion runs,
-- which follow the link id); 2 contact rows (to twins that have none). Images stay on the duplicates (each twin has
-- its own). None of the 16 duplicates carries compass answers, context or evidence.
-- ONE LINK COLLISION: Cal-Access 1357192 "MORALES FOR STATE ASSEMBLY 2014, ELOY" is linked to both Eloy rows -- as
-- confirmed with money ($32,622) on the duplicate and as needs_research with no money on the twin. The twin's
-- needs_research copy (9c39ed5a-251b-48fc-bbfe-621c7cb28cb0) is moved onto the deactivated duplicate, with a note,
-- so the confirmed copy can take its place on the twin. Nothing is deleted.
--
-- THEN: each duplicate is deactivated (is_active = false, is_incumbent = false) with a note naming its twin.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE. No office_terms change.
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews). Dry run x2 repeated right before the apply;
--   verified after: 16 duplicates inactive; 5 links ($7,024,053.18 confirmed) on the seated rows, incl. Kim Driscoll OCPF 15268.
--
-- ROLLBACK: re-point the _race, _link and _contact ids below back to their duplicate row, move link
-- 9c39ed5a-251b-48fc-bbfe-621c7cb28cb0 back to 6ed19c10-7b34-47f0-8705-0d154271e362 (stripping its CA_0182 note),
-- and set the duplicates' is_active / is_incumbent back to true, removing their CA_0182 note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (dup uuid PRIMARY KEY, keep uuid, dup_name text, keep_name text, keep_office uuid) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('d863a7c9-6fb1-425f-8086-9f3b91fece38', '352876f0-02b4-4eba-b979-c99079ab368a', 'Adrian Fontes', 'Adrian Fontes', '520719e6-cb1e-46a2-a99d-b83cc4d16d38'),
  ('cfd3f975-3ecf-4279-93a8-d95686462c45', 'ca092ddd-8ce5-4521-bbbe-38f453650b04', 'Katie Hobbs', 'Katie Hobbs', '4d870c55-7937-41ba-8716-7a30da7e3e06'),
  ('8775ab9f-7e75-4f10-869e-84610ef5aa6d', '760f51b2-657e-43b8-9340-038e06b4d9a5', 'Kevin Thompson', 'Kevin Thompson', 'a1af9a2f-bfb6-4f6a-a0f7-74789bcc06e9'),
  ('f794e25a-bcd1-46ab-af12-8a78373ed26b', '8bcdaf44-f392-410d-83c3-7597a52a8140', 'Les Presmyk', 'Les Presmyk', '73481f59-8969-4734-bd69-cdf6d97df7a3'),
  ('575c6547-0ed1-45bc-8d74-44a93797698c', '9170233d-a01b-4fd0-bd68-6c961948ab79', 'Nick Myers', 'Nick Myers', '6e883147-c214-49b5-828b-e2ee2d813c72'),
  ('87ea1c03-10cc-40c9-9c6d-2880243ba411', 'f8c46490-a465-4ec3-a442-1b7f9ea6886c', 'Tom Horne', 'Tom Horne', 'ba26bb00-515a-4445-8cc5-b24f28107663'),
  ('cdd0537b-4e95-4805-b384-4b1d65594f11', '9db24324-3d82-4c2b-8404-078a53708447', 'Dan Brotman', 'Daniel Brotman', '0b17284a-a65f-4821-bf05-00476da671ea'),
  ('ff97a6bb-0c1c-465a-9300-817385a8fceb', '6ed19c10-7b34-47f0-8705-0d154271e362', 'Eloy Morales Jr.', 'Eloy Morales', 'ddcd280b-565d-496c-9ec4-0e43abb7b580'),
  ('55d8239c-fd6e-4b43-901b-71b31e1117ab', 'e687c089-f00d-464c-aa37-3b021a3aba2c', 'Kimberley Driscoll', 'Kim Driscoll', '66c34aa8-db37-4aed-a369-fa5729f62b4a'),
  ('2c5eb897-6ea2-4f1c-ba6e-eadc8539914e', '49963775-d2d5-4ae2-95cf-b2b8d0ed2a92', 'Michael L. Connolly', 'Mike Connolly', '06e4afe2-cbcf-421c-a569-c15b7d55a236'),
  ('e25758f8-1e4b-4c24-9ab8-dccf6773dd6a', '8d4c84a6-d928-42c1-b9c6-6a1433a161da', 'Katrina Ladwig', 'Katrina W Ladwig', 'be8d2e21-9983-474a-a443-5b7933b9aa8f'),
  ('3aa2406c-766f-444f-b673-e5831a68a49b', '4e020b4f-662b-4f9e-adc1-6635311f6b6b', 'Roger Taylor', 'Roger L Taylor', 'f054aaa9-8382-4e15-8b77-72567203fc14'),
  ('4140bab7-459d-4735-a2ca-f319377db452', '909d124c-63e0-4887-9987-15b78383d406', 'Thelma Kelley Jeffries', 'Thelma K Jeffries', '1e8d2cc6-f047-4b5e-98ba-9ae4b6e309f4'),
  ('05624287-c90f-40be-bada-12a883040d60', '11c6810e-3e00-400c-9734-e813d712c92f', 'Richard A. Hyer', 'Richard Hyer', '70656648-e8a2-4e37-8059-a25ffccb5cfb'),
  ('053fb431-dc21-4aea-8e10-39e8ec5164d4', '88502130-65ab-48a2-9b12-58a8511949b9', 'Bettina Smith Edmondson', 'Bettina Smith Edmondson', '0aefac6f-8a48-454f-afdf-8b0a60c51bb6'),
  ('6972209b-13b7-4595-b7f1-8f6df06de1e9', '78ab8148-5919-46b1-8de3-74d9467c3357', 'Martha Hawk', 'Marty Hawk', 'b71fbb04-df8b-45c9-b3ee-ea9e2be25055');

CREATE TEMP TABLE _race (id uuid PRIMARY KEY, dup uuid) ON COMMIT DROP;
INSERT INTO _race VALUES
  ('f509b4fb-487c-4d82-a431-e6b94e15054b','d863a7c9-6fb1-425f-8086-9f3b91fece38'),
  ('fcd85751-3fd7-4c63-9f2a-b3d2552ea23a','cfd3f975-3ecf-4279-93a8-d95686462c45'),
  ('e4b506cc-9c06-48e7-b3ba-9b0cdb14fa08','8775ab9f-7e75-4f10-869e-84610ef5aa6d'),
  ('4cca6a73-3bd8-4614-919d-cfbca7148509','f794e25a-bcd1-46ab-af12-8a78373ed26b'),
  ('2db1547a-59ed-477e-b38e-8077b53da2dd','575c6547-0ed1-45bc-8d74-44a93797698c'),
  ('3c2edfc7-e318-4ea0-ac5d-b33c1b7fcd2b','87ea1c03-10cc-40c9-9c6d-2880243ba411'),
  ('6f4994bf-4f97-4ef2-b68f-b8618f522d40','cdd0537b-4e95-4805-b384-4b1d65594f11'),
  ('82e8708c-0297-495a-851e-256e58753041','6972209b-13b7-4595-b7f1-8f6df06de1e9'),
  ('c126cf5c-5721-47fb-b360-ca71bebe8971','6972209b-13b7-4595-b7f1-8f6df06de1e9');

CREATE TEMP TABLE _link (id uuid PRIMARY KEY, dup uuid) ON COMMIT DROP;
INSERT INTO _link VALUES
  ('6a675d76-a518-4826-8bf5-6b6cdd409337','ff97a6bb-0c1c-465a-9300-817385a8fceb'),
  ('51858975-2079-4a4f-8281-89ae7ad7c84a','ff97a6bb-0c1c-465a-9300-817385a8fceb'),
  ('dc5ba982-515c-46e1-b47d-e84c8c8fc39a','ff97a6bb-0c1c-465a-9300-817385a8fceb'),
  ('d1de312c-1980-46a1-bcc2-d1ab59c90c9e','55d8239c-fd6e-4b43-901b-71b31e1117ab'),
  ('e818a488-b2ed-45ff-b21b-80d38c34eb54','2c5eb897-6ea2-4f1c-ba6e-eadc8539914e');

CREATE TEMP TABLE _contact (id uuid PRIMARY KEY, dup uuid) ON COMMIT DROP;
INSERT INTO _contact VALUES
  ('90186d37-9cd8-49cf-93ee-a81e1bf12835','053fb431-dc21-4aea-8e10-39e8ec5164d4'),
  ('7206b46b-7505-4f65-9ed3-70e690f4b64a','05624287-c90f-40be-bada-12a883040d60');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
          JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
         WHERE ps.research_status = 'confirmed') AS confirmed_total,
       (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
         WHERE a.politician_source_id IN (SELECT id FROM _link)) AS moved_money;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- every twin is active and still holds its seat; every duplicate holds no term
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep AND k.full_name = pr.keep_name AND k.is_active
    JOIN essentials.politicians d ON d.id = pr.dup AND d.full_name = pr.dup_name
    JOIN essentials.office_current_holder och ON och.politician_id = pr.keep AND och.office_id = pr.keep_office
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = pr.dup);
  IF v_n <> 16 THEN RAISE EXCEPTION 'PRE: % of 16 pairs match (twin on its seat, duplicate holding no term)', v_n; END IF;

  -- the duplicates carry exactly the reviewed race rows, links and contacts (or those already moved), and no
  -- compass data
  SELECT count(*) INTO v_n FROM _race x JOIN essentials.race_candidates rc ON rc.id = x.id
   WHERE rc.politician_id IN (x.dup, (SELECT keep FROM _pair WHERE dup = x.dup));
  IF v_n <> 9 THEN RAISE EXCEPTION 'PRE: % of 9 race rows on their duplicate or twin', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
   WHERE rc.politician_id IN (SELECT dup FROM _pair) AND rc.id NOT IN (SELECT id FROM _race);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed race row(s) on the duplicates', v_n; END IF;
  SELECT count(*) INTO v_n FROM _link x JOIN transparent_motivations.politician_sources ps ON ps.id = x.id
   WHERE ps.essentials_politician_id IN (x.dup, (SELECT keep FROM _pair WHERE dup = x.dup)) AND ps.research_status = 'confirmed';
  IF v_n <> 5 THEN RAISE EXCEPTION 'PRE: % of 5 confirmed links on their duplicate or twin', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT dup FROM _pair)
     AND ps.id NOT IN (SELECT id FROM _link) AND ps.id <> '9c39ed5a-251b-48fc-bbfe-621c7cb28cb0';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed link(s) on the duplicates', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.id = '9c39ed5a-251b-48fc-bbfe-621c7cb28cb0' AND ps.external_id = '1357192' AND ps.research_status = 'needs_research'
     AND ps.essentials_politician_id IN ('6ed19c10-7b34-47f0-8705-0d154271e362', 'ff97a6bb-0c1c-465a-9300-817385a8fceb')
     AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contribution_summary_agg a WHERE a.politician_source_id = ps.id)
     AND NOT EXISTS (SELECT 1 FROM transparent_motivations.ingestion_runs r WHERE r.politician_source_id = ps.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the colliding needs_research copy of 1357192 is not in its reviewed state'; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE politician_source_id = '9c39ed5a-251b-48fc-bbfe-621c7cb28cb0';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: the colliding copy carries % contributions', v_n; END IF;
  SELECT count(*) INTO v_n FROM _contact x JOIN essentials.politician_contacts c ON c.id = x.id
   WHERE c.politician_id IN (x.dup, (SELECT keep FROM _pair WHERE dup = x.dup));
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 contacts on their duplicate or twin', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id IN (SELECT dup FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % compass answers on the duplicates; this file moves none', v_n; END IF;
END $$;

-- ─── 1. Move race rows, links and contacts to the twins ────────────────────────────────────────
UPDATE essentials.race_candidates rc SET politician_id = pr.keep
  FROM _race x JOIN _pair pr ON pr.dup = x.dup
 WHERE rc.id = x.id AND rc.politician_id = x.dup;

-- the collision, as a three-step swap (the (politician, system, external_id) key is checked row by row, so the two
-- copies of 1357192 cannot trade places in one statement): (a) the twin's needs_research copy takes a transient
-- external_id, (b) the confirmed copies move to the twins, (c) the stepped-aside copy lands on the duplicate under its
-- real external_id.
UPDATE transparent_motivations.politician_sources ps
   SET external_id = '1357192#CA_0182'
 WHERE ps.id = '9c39ed5a-251b-48fc-bbfe-621c7cb28cb0' AND ps.essentials_politician_id = '6ed19c10-7b34-47f0-8705-0d154271e362'
   AND ps.external_id = '1357192';

UPDATE transparent_motivations.politician_sources ps SET essentials_politician_id = pr.keep, updated_at = now()
  FROM _link x JOIN _pair pr ON pr.dup = x.dup
 WHERE ps.id = x.id AND ps.essentials_politician_id = x.dup;

UPDATE transparent_motivations.politician_sources ps
   SET essentials_politician_id = 'ff97a6bb-0c1c-465a-9300-817385a8fceb', external_id = '1357192',
       notes = ps.notes || ' | CA_0182 (2026-09-23): moved to the deactivated duplicate row Eloy Morales Jr. so the '
               || 'CONFIRMED copy of the same committee (from that row) can sit on the seated row.',
       updated_at = now()
 WHERE ps.id = '9c39ed5a-251b-48fc-bbfe-621c7cb28cb0' AND ps.external_id = '1357192#CA_0182';

UPDATE essentials.politician_contacts c SET politician_id = pr.keep
  FROM _contact x JOIN _pair pr ON pr.dup = x.dup
 WHERE c.id = x.id AND c.politician_id = x.dup;

-- ─── 2. Deactivate the duplicates ─────────────────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0182 (2026-09-23): DUPLICATE of ' || pr.keep::text || ' ('
               || pr.keep_name || '), the row that holds the seat. Race rows, committee links and contacts moved there; '
               || 'deactivated, not deleted.')::text
  FROM _pair pr
 WHERE d.id = pr.dup AND (d.is_active OR d.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_amt numeric; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM essentials.politicians d JOIN _pair pr ON pr.dup = d.id
   WHERE NOT d.is_active AND NOT d.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0182 (2026-09-23): DUPLICATE of%');
  IF v_n <> 16 THEN RAISE EXCEPTION 'POST: % of 16 duplicates deactivated with the note', v_n; END IF;

  SELECT count(*) INTO v_n FROM _race x JOIN _pair pr ON pr.dup = x.dup JOIN essentials.race_candidates rc ON rc.id = x.id
   WHERE rc.politician_id = pr.keep;
  IF v_n <> 9 THEN RAISE EXCEPTION 'POST: % of 9 race rows on the twins', v_n; END IF;
  SELECT count(*) INTO v_n FROM _link x JOIN _pair pr ON pr.dup = x.dup JOIN transparent_motivations.politician_sources ps ON ps.id = x.id
   WHERE ps.essentials_politician_id = pr.keep AND ps.research_status = 'confirmed';
  IF v_n <> 5 THEN RAISE EXCEPTION 'POST: % of 5 confirmed links on the twins', v_n; END IF;
  SELECT count(*) INTO v_n FROM _contact x JOIN _pair pr ON pr.dup = x.dup JOIN essentials.politician_contacts c ON c.id = x.id
   WHERE c.politician_id = pr.keep;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 contacts on the twins', v_n; END IF;

  -- the duplicates keep only the stepped-aside copy of 1357192
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT dup FROM _pair);
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % links on the duplicates, expected 1 (the stepped-aside 1357192 copy)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id IN (SELECT dup FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % race rows still on the duplicates', v_n; END IF;

  -- the money that moved sits on the twins, and the total did not move
  SELECT COALESCE(sum(a.total_amount), 0) INTO v_amt FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
   WHERE ps.id IN (SELECT id FROM _link) AND ps.essentials_politician_id IN (SELECT keep FROM _pair);
  IF v_amt <> b.moved_money THEN RAISE EXCEPTION 'POST: % of the % moved money sits on the twins', v_amt, b.moved_money; END IF;
  SELECT b.confirmed_total - (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
                               JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
                              WHERE ps.research_status = 'confirmed') INTO v_amt;
  IF v_amt <> 0 THEN RAISE EXCEPTION 'POST: the confirmed total moved by %', v_amt; END IF;

  -- every twin still holds its seat
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.office_current_holder och ON och.politician_id = pr.keep AND och.office_id = pr.keep_office;
  IF v_n <> 16 THEN RAISE EXCEPTION 'POST: % of 16 twins still on their seat', v_n; END IF;

  RAISE NOTICE 'CA_0182 applied: 16 duplicates merged and deactivated; 9 race rows, 5 links (% moved), 2 contacts', b.moved_money;
END $$;

COMMIT;
