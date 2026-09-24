-- CA_0258_confirm_52_reviewed_fec_rows.sql
-- Confirm 52 of the 148 needs_research FEC rows the 2026-09-24 auto-match run left, after a review against the FEC API.
--
-- HOW EACH WAS CHECKED (read-only, 2026-09-24): for every FEC candidate listed in the row's notes that names 2026 in
-- election_years, /v1/candidate/<id>/ gave its state, DISTRICT and filing status, and for people with two IDs
-- /candidate/<id>/totals/?cycle=2026 and /committees/?designation=P gave the 2026 receipts and principal committee.
-- A row is confirmed here only when:
--   kind 'name'     (37) exactly ONE 2026 FEC ID sits in the person's own state + district (Senate: state), and the
--                        first name matches directly, as a common nickname (Bob/Robert, Jack/John), or as a middle
--                        name the person goes by (Steve Rance = RANCE, HOWARD STEVEN). The auto-match scored these 0.6
--                        or 0 because of FEC name formatting: honorifics ("RAZACK, MD JD, NIZAM"), ",," ("BRINK,,
--                        BRIDGET"), hyphen vs space ("SIGCHO LOPEZ"), nicknames, middle names.
--   kind 'reversed'  (2) the one 2026 ID in the district stores the name FIRST, LAST ("ERIC, HAFNER", "JAY, BOWMAN J").
--   kind 'nickname'  (1) Jake Johnson = JOHNSON, JACOB (MN-1), the one 2026 ID in the district.
--   kind 'two_ids'  (12) one person holds two FEC IDs in the district. The ID taken is the one with the 2026
--                        principal committee, or -- where both IDs share ONE principal committee (9 of the 12), so the
--                        money is identical either way -- the one with the latest filing. Ted Brown (TX Senate): the
--                        second ID is a different person (BROWN GAINES, JENNIFER).
-- NOT CONFIRMED (stay needs_research, not touched): 58 with no FEC hit at all, 35 with no 2026 ID in their district,
-- 3 unresolvable two-ID cases (Zyon Khalifa: two IDs filed the same day; Paul Berry, John Elleson: no 2026 committee).
-- The full review (all 148 rows, each with its candidates and reason) is attached to this file's PR.
--
-- PRE-IMAGE (checked by the gate): every row is still needs_research on the same person and system; no proposed ID
-- sits on another person's FEC row; nobody here has a second FEC row; 52 distinct IDs; H/S prefix matches the system.
--
-- WHAT: external_id := the reviewed ID, research_status := 'confirmed', a note appended, updated_at := now(). The next
-- 06:00 UTC ev-jobs-fec-burst run loads their contributions (it ingests confirmed FEC links).
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE.
-- STATUS: NOT YET APPLIED.
--
-- ROLLBACK: for the source_ids in _c, set research_status back to 'needs_research' and strip the CA_0258 note. The
-- original external_id of each row was the auto-match's top-scored candidate; it is listed first in the row's notes.
-- IDEMPOTENT: guarded on research_status = 'needs_research'; a re-run changes nothing and the gate still passes.

BEGIN;

CREATE TEMP TABLE _c (source_id uuid PRIMARY KEY, pid uuid, sys text, fec_id text, kind text, full_name text) ON COMMIT DROP;
INSERT INTO _c VALUES
  ('44832810-4ee6-4783-a1ef-2ffe4b1d429b'::uuid, '61bd888b-a452-48b1-8b94-75dd4580c031'::uuid, 'fec_house', 'H6AK01134', 'two_ids', $$David R. Ambrose II$$),
  ('6aa2d5c0-56b9-45b1-9683-63bb204bdede'::uuid, '01f1e09e-dec1-420a-829a-8b9ff32ecb80'::uuid, 'fec_house', 'H4AK00164', 'reversed', $$Eric Hafner$$),
  ('3e4da487-c038-4909-9927-cf32b1db93aa'::uuid, '066de417-a463-4574-8cee-c2eac3700d8b'::uuid, 'fec_house', 'H6AL06168', 'name', $$Ashtyn Kennedy$$),
  ('a260da58-097d-4af4-8914-d185e3193139'::uuid, '6e6f2f55-63c8-4bc4-9204-66d051210f6f'::uuid, 'fec_house', 'H6AL01136', 'name', $$John Mills$$),
  ('e0b77128-89f2-440a-a80e-b6cc1ce9874d'::uuid, '32d3123c-cf3a-4cde-8c63-8d0ea97315cb'::uuid, 'fec_house', 'H6AL03199', 'name', $$Lee McInnis$$),
  ('f8e68acc-f7ce-41e0-8dab-fe54ae520c84'::uuid, 'b4159499-eef0-4ec2-9e50-8a8139047225'::uuid, 'fec_house', 'H4AZ08082', 'name', $$Bernadette Greene-Placentia$$),
  ('b94045ec-f0b6-4450-a61c-bcb5ebd0e12a'::uuid, 'ef18190f-e5de-440a-ba0a-8aae0b5490fc'::uuid, 'fec_house', 'H4AZ04115', 'name', $$Zuhdi Jasser$$),
  ('ea22fafe-6b65-429b-8b0f-86cbe4b6bbea'::uuid, 'e85c17b3-fd26-4e93-ac5a-cd0d15580314'::uuid, 'fec_house', 'H6CA24345', 'name', $$Bob Smith$$),
  ('8ae056f0-f33d-41dc-833e-c38e2b4a26aa'::uuid, 'eb9c3296-90ef-4b6e-a4ed-bcd85a40c072'::uuid, 'fec_house', 'H2CA38260', 'two_ids', $$Mitch Clemmons$$),
  ('6af38f9d-bc31-44d4-be1c-dc1d9bccc26b'::uuid, '89d14c56-e548-4afa-9977-06c2e94d8718'::uuid, 'fec_house', 'H6CA51140', 'name', $$Richardo Cabrera$$),
  ('e9a01e97-59b7-4987-a8bb-ac686c6eb090'::uuid, '7810ec53-a7f7-400e-823e-d5ea3b50fef2'::uuid, 'fec_house', 'H6FL06324', 'name', $$Aaron Baker$$),
  ('5d558c92-a3a3-4af0-b3e4-ae9900a5460f'::uuid, 'edc74560-277a-42b3-929c-f7e0b974a9d5'::uuid, 'fec_house', 'H6FL18121', 'two_ids', $$Carla Spalding$$),
  ('75b57b3f-1ad8-4381-bc9a-62cfbddbcff3'::uuid, '936678b9-fa41-44f2-9bbb-186846f2b5a2'::uuid, 'fec_house', 'H2FL21108', 'name', $$Dan Franzese$$),
  ('abc37c41-75b4-4fa5-8bd0-135142227723'::uuid, 'e9d56d27-12e8-47ca-b96b-7de3914d0df2'::uuid, 'fec_house', 'H4FL01197', 'name', $$Gay Valimont$$),
  ('c372a0e5-9534-4f64-abca-285d09235dfd'::uuid, '97134e74-c921-4dd2-a7a0-c04666c7d817'::uuid, 'fec_house', 'H4FL09190', 'name', $$Marcus Carter$$),
  ('78ae1703-e2e8-4620-8753-55958ef5b077'::uuid, '2e2a5155-2040-4aca-8677-6708e94ee68b'::uuid, 'fec_house', 'H6FL14203', 'name', $$Mayonna Te Brown$$),
  ('f10d3fa4-74bb-4d58-8459-fff431c4a9bd'::uuid, '0b84cc7f-9e82-4f2c-bc01-f4526fb18a62'::uuid, 'fec_house', 'H6FL22180', 'name', $$Michael Thompson$$),
  ('ebf1a31c-6ba0-4bed-97b0-f3a933be9005'::uuid, 'f43eadfc-f60c-40c9-84fb-6f7bda881c8c'::uuid, 'fec_house', 'H4FL07152', 'name', $$Mike Johnson$$),
  ('fb2249c6-bef2-454f-9b3c-8f6d118e6125'::uuid, 'f0c3c20d-3089-47ff-8116-ea98fe4a29a3'::uuid, 'fec_house', 'H6FL02323', 'name', $$Nick Lewis$$),
  ('9bae5a7c-688f-4c2b-9f1e-e86b20b0aa00'::uuid, '0e2f2d8c-cd3d-4e10-b0d0-684229f13772'::uuid, 'fec_house', 'H6FL11316', 'name', $$Nizam Razack$$),
  ('a73d2108-a4fe-438a-8210-8068a86468f9'::uuid, '1760848f-9977-4e71-9421-9707d5ff919e'::uuid, 'fec_house', 'H6FL10185', 'name', $$Steve Rance$$),
  ('d90d16c4-91ef-41a1-86e1-58ac147bccea'::uuid, '8e971836-9546-4dec-8812-b1dee9781c21'::uuid, 'fec_house', 'H6FL10177', 'name', $$Stuart Farber$$),
  ('063b77f7-10bb-4dab-b0e0-c609987a6718'::uuid, '0c6bd0d0-f968-4598-84f8-769a03de8a3f'::uuid, 'fec_house', 'H4FL02138', 'name', $$Yen Bailey$$),
  ('8c126337-c6aa-4f48-ad4a-69a69f668a02'::uuid, 'aacada00-5cff-4a4e-9bd6-c0e4935df79f'::uuid, 'fec_house', 'H6GA01109', 'name', $$Jim Kingston$$),
  ('375b6a03-ba14-4cdd-8109-e5c7244120f1'::uuid, '23daee91-beb1-405d-be9b-c1a62f3de6fa'::uuid, 'fec_house', 'H4GA05063', 'name', $$John Salvesen$$),
  ('27241906-6f6f-49df-a89c-e866c46af922'::uuid, 'c46123fb-c9e8-4f3f-976e-43d526576539'::uuid, 'fec_house', 'H6IL04161', 'name', $$Byron Sigcho-Lopez$$),
  ('acac7790-293f-4fd6-b72d-e612a3158457'::uuid, 'b1baf884-5fd5-4618-b380-f2790fa47ee5'::uuid, 'fec_house', 'H6KY06234', 'reversed', $$Jay J Bowman$$),
  ('d1fb4caf-d81f-483c-86b2-83babc48255b'::uuid, 'cc08909a-99b4-47fe-a252-248fbc9a015b'::uuid, 'fec_house', 'H6KY04205', 'two_ids', $$Jeremy Todd$$),
  ('9c15cdaf-abae-41b9-83e4-f3a1c378cda0'::uuid, 'c13b6ff5-5040-4691-9755-58a0c8981a5a'::uuid, 'fec_house', 'H6LA06158', 'name', $$Monique Appeaning$$),
  ('32274d40-31b9-47ab-9a8f-92be5b51b8c3'::uuid, 'def50b05-3bda-4f3a-abb4-867e44338f25'::uuid, 'fec_house', 'H4MD03149', 'name', $$Berney Flowers$$),
  ('6e501669-c75b-4064-bcf6-9332b8f40513'::uuid, '0a8fe6e2-47a8-4a33-9b1a-f1500987becb'::uuid, 'fec_house', 'H2MD06138', 'name', $$Dave Wallace$$),
  ('99c78d5e-110c-4622-b0b1-17956b927a3b'::uuid, '27694a99-86e7-4074-ba00-9cca51edcc20'::uuid, 'fec_house', 'H6MI07256', 'name', $$Bridget Brink$$),
  ('fc67310b-1e8c-4d7f-ac92-8030fd49f9d1'::uuid, '4782f3f1-c940-47ad-a3ab-a753b8cd719a'::uuid, 'fec_house', 'H6MI02240', 'name', $$Clyde Welford$$),
  ('1aa1caca-237c-4583-b512-2d4c516022d2'::uuid, '4af5a071-1225-439a-9ba3-3816f2de262f'::uuid, 'fec_house', 'H6MI09245', 'name', $$Ray Pooley$$),
  ('b02be7a7-3cd8-4c47-b747-7904ae118dba'::uuid, '9e00a45b-30f4-4d84-a1fe-861e81eb30ea'::uuid, 'fec_house', 'H6MN01190', 'nickname', $$Jake Johnson$$),
  ('53ef5190-2ed9-439c-bdb1-b0cd7f599a3f'::uuid, '38277535-35fb-4e98-973e-8f00a43c4546'::uuid, 'fec_house', 'H6MN06223', 'name', $$Mike Foley$$),
  ('476a0104-8cc0-48b9-b414-44f8abf8d634'::uuid, 'a64f0826-39a6-4ef1-8cf7-f62bde06509e'::uuid, 'fec_house', 'H6MS04259', 'two_ids', $$Carl Boyanton$$),
  ('ab4fda7a-cc7a-4de6-b17c-df9e159f9e72'::uuid, '159e0a9e-cf36-4746-8e70-6f1fb1a54831'::uuid, 'fec_house', 'H4NC02135', 'name', $$Gene Douglass$$),
  ('5634adfb-3b4d-4310-8258-5ff67ba46c08'::uuid, '21152a8e-df76-4431-9421-9c453b186400'::uuid, 'fec_house', 'H6NC12113', 'name', $$Jack Codiga$$),
  ('520d5d52-dde7-4740-808e-c41312e8b123'::uuid, '6017aebf-8ffc-4439-9aab-b124403c8855'::uuid, 'fec_house', 'H4NC02150', 'two_ids', $$Max Ganorkar$$),
  ('41efeef7-f124-428b-9dbb-0f0a82a5e504'::uuid, '56ff523a-2af9-42b7-9855-0c1f00f1870a'::uuid, 'fec_house', 'H6NJ06286', 'two_ids', $$Hillary Herzig$$),
  ('c36475fe-5376-4f4e-b5b5-d4d4f3d2f496'::uuid, '3dc1e457-1d4d-4cac-9234-278c47ca53e6'::uuid, 'fec_house', 'H4NV03225', 'two_ids', $$Marty O'Donnell$$),
  ('dfc689ca-092f-4f35-8b7e-11d0a00c1bf0'::uuid, '5c41400a-8ba5-4334-9add-bbfcc49cba03'::uuid, 'fec_house', 'H2OH04164', 'two_ids', $$Tamie Wilson$$),
  ('0273b3d1-4b3f-450e-931f-edccebf0c9f1'::uuid, 'dd3ab4db-c67f-493f-b94a-b2f704592ede'::uuid, 'fec_house', 'H6PA06156', 'name', $$Marty Young$$),
  ('e1b9781b-7be4-45ee-8c92-5f7c6fd7d845'::uuid, 'b8175280-a47e-45f4-8ee4-594330e348cd'::uuid, 'fec_house', 'H6TN09472', 'name', $$Todd Warner$$),
  ('a14ffee5-299d-455d-ba79-549028c5645e'::uuid, 'e63791e7-3d09-4da1-a28c-b3e221491c15'::uuid, 'fec_house', 'H6TX05189', 'two_ids', $$Chelsey Hockett$$),
  ('434e05bd-f4b8-4214-b2b4-e26248ed97c2'::uuid, '6eccd92f-958a-4ee5-8eb6-f9ca48e41af2'::uuid, 'fec_house', 'H6UT02549', 'two_ids', $$Carlton E. Bowen$$),
  ('6aafab9c-7f7b-488b-b33d-89ac39aea8e3'::uuid, 'bfb32110-4ab9-4430-9d71-fc43ebc64130'::uuid, 'fec_house', 'H6VA01232', 'name', $$Salaam Bhatti$$),
  ('31f894a8-9d3e-4531-ab36-b07176556cee'::uuid, '0149b112-d2a0-4b5c-900c-56bf1db3612b'::uuid, 'fec_house', 'H6VA05217', 'name', $$Tom Perriello$$),
  ('76dfcf52-7d1e-4669-b476-660613a9521d'::uuid, 'be210133-0125-4479-b5a7-129b73d1e092'::uuid, 'fec_house', 'H4VT01056', 'name', $$Mark Coester$$),
  ('d60431c9-9c46-4848-a3b2-a12ac9eb60c4'::uuid, '8d6faa29-2b9a-4d63-aff4-b738677a9c18'::uuid, 'fec_house', 'H6WY00241', 'name', $$Bo Biteman$$),
  ('08973a1e-c1dd-434c-a89b-c3a102002233'::uuid, 'f800d669-e56a-4ef2-9ca5-463a10a11973'::uuid, 'fec_senate', 'S4TX00888', 'two_ids', $$Ted Brown$$);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _c;
  IF v_n <> 52 THEN RAISE EXCEPTION 'PRE: % rows listed, expected 52', v_n; END IF;
  SELECT count(DISTINCT fec_id) INTO v_n FROM _c;
  IF v_n <> 52 THEN RAISE EXCEPTION 'PRE: % distinct FEC ids, expected 52', v_n; END IF;
  SELECT count(*) INTO v_n FROM _c WHERE left(fec_id, 1) <> CASE sys WHEN 'fec_senate' THEN 'S' ELSE 'H' END;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % ids whose H/S prefix disagrees with the system', v_n; END IF;

  -- each row still as reviewed (or already confirmed onto the reviewed id by a previous run of this file)
  SELECT count(*) INTO v_n FROM _c JOIN transparent_motivations.politician_sources ps
      ON ps.id = _c.source_id AND ps.essentials_politician_id = _c.pid AND ps.source_system = _c.sys
   WHERE ps.research_status = 'needs_research'
      OR (ps.research_status = 'confirmed' AND ps.external_id = _c.fec_id);
  IF v_n <> 52 THEN RAISE EXCEPTION 'PRE: % of 52 rows in their reviewed state', v_n; END IF;

  SELECT count(*) INTO v_n FROM _c JOIN transparent_motivations.politician_sources ps
      ON ps.external_id = _c.fec_id AND ps.source_system LIKE 'fec%' AND ps.essentials_politician_id <> _c.pid;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % reviewed ids already on another person', v_n; END IF;
  SELECT count(*) INTO v_n FROM _c JOIN transparent_motivations.politician_sources ps
      ON ps.essentials_politician_id = _c.pid AND ps.source_system LIKE 'fec%' AND ps.id <> _c.source_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % people here with a second FEC row', v_n; END IF;
END $$;

-- ─── Confirm ─────────────────────────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET external_id = _c.fec_id,
       research_status = 'confirmed',
       notes = COALESCE(ps.notes, '') || ' | CA_0258 (2026-09-24): confirmed ' || _c.fec_id || ' by review against the FEC API ('
               || CASE _c.kind
                    WHEN 'name' THEN 'one 2026 ID in the person''s own state and district; first name, nickname or middle name matches'
                    WHEN 'reversed' THEN 'one 2026 ID in the district; FEC stores the name FIRST, LAST'
                    WHEN 'nickname' THEN 'one 2026 ID in the district; nickname'
                    ELSE 'one person with two FEC IDs; took the 2026 principal committee''s ID, or the latest filing where both share one committee'
                  END || ').',
       updated_at = now()
  FROM _c
 WHERE ps.id = _c.source_id AND ps.research_status = 'needs_research';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _c JOIN transparent_motivations.politician_sources ps
      ON ps.id = _c.source_id AND ps.external_id = _c.fec_id AND ps.research_status = 'confirmed'
   WHERE ps.notes LIKE '%CA_0258 (2026-09-24): confirmed%';
  IF v_n <> 52 THEN RAISE EXCEPTION 'POST: % of 52 rows confirmed onto the reviewed id', v_n; END IF;

  -- still one FEC row per person here, and no id shared between people
  SELECT count(*) INTO v_n FROM (SELECT ps.external_id FROM transparent_motivations.politician_sources ps
    WHERE ps.source_system LIKE 'fec%' AND ps.external_id IN (SELECT fec_id FROM _c)
    GROUP BY 1 HAVING count(DISTINCT ps.essentials_politician_id) > 1) x;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % reviewed ids now on more than one person', v_n; END IF;

  RAISE NOTICE 'CA_0258 applied: 52 reviewed FEC rows confirmed';
END $$;

COMMIT;
