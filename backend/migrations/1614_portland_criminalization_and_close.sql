-- 1614: Criminalization of Homelessness x3 recovered from non-council sources, and a formal close
--        on the 13 Portland rows that stay retired.
--
-- Operator authorised non-council sources. That changed three outcomes. Portland councilors publish
-- per-member TOPICAL pages under /council/districts/<n>/<name>/<slug> -- position and record pages,
-- distinct from the vote record and from the news feed. Swept all nine remaining councilors' topical
-- pages; three carry a real, attributable position on camping enforcement.
--
-- ⚠ ALSO A CORRECTION TO MY OWN SCOPING. I previously grouped Dan Ryan's Criminalization row into the
-- "no vote exists" block. That was wrong: the 2023 and 2024 public camping restriction votes are in
-- HIS OWN record from his earlier term -- the same reason his Homelessness row was chairable in mig
-- 1608. Only the ten members seated in January 2025 lack such votes. Ryan was always recoverable.
--
-- ===================================== RECOVERED (3) ========================================
--
-- Dan Ryan -- chair 3 (retired chair 3, unchanged).
--   /community-safety states that Ryan "supported the latest City Camping Ordinance in Spring 2024
--   that limits what people can do while camping ... and allows for people to be arrested for camping
--   on public property IF THEY REFUSE MULTIPLE OFFERS OF SHELTER", and that he "worked to ensure this
--   policy offers people services prior to involving law enforcement". Enforcement conditioned on a
--   refused shelter offer, services first: chair 3 almost verbatim, and the same chair as Wilson in
--   mig 1613, who is bound by the same ordinance. Corroborated by his own Yea votes on the 2023 and
--   2024 camping restriction ordinances.
--
-- Mitch Green -- chair 1 (retired 2).
--   His published policy page lists an amendment he authored, "Sanitation, Hygiene, and Workforce
--   Development, Green 3 (2026 Budget)", which "Redirects $1 million from the city's homeless sweeps
--   budget into programs that provide basic hygiene, public sanitation, and workforce development".
--   Redirecting an enforcement budget away from sweeps is chair 1's distinctive MECHANISM.
--   ⚠ Chair 1's wording sends that money to "permanent supportive housing and mental health services";
--   Green's sends it to bathrooms, laundry and low-barrier jobs. The reasoning states his actual
--   destination rather than the chair's label -- cite what the page says, not what the chair says.
--
-- Angelita Morillo -- chair 1 (retired 2).
--   Her published record page says she prepared legislation strengthening oversight of homelessness
--   services "while supporting a shift away from costly homeless camp sweeps and toward proven
--   investments like public bathrooms, sanitation, and low-barrier jobs". Same direction and same
--   mechanism as Green, stated as her own work.
--
-- ================================ STAYING RETIRED (13) ======================================
-- 🔴 THESE ROWS DO NOT EXIST IN THE DATABASE AND NOTHING IS DELETED HERE. Migration 1558 removed all
-- 57, and these 13 were never restored. "Retiring" them is a bookkeeping decision -- they are closed,
-- not owed -- so this migration ASSERTS their absence rather than acting on it. Recording the reason
-- is the whole point: without it the next sweep re-queues them.
--
--   Criminalization of Homelessness x7 -- Avalos, Novick, Pirtle-Guiney, Kanal, Koyama Lane,
--     Zimmerman, Dunphy. Portland's camping restrictions passed in 2023 and 2024, before all seven
--     were seated, and enforcement resumed administratively rather than by vote. Their topical pages
--     were swept for camping / encampment / sweep and carry nothing on the subject.
--   School Vouchers & Public Education Funding x2 -- Pirtle-Guiney, Koyama Lane. Portland has NO K-12
--     jurisdiction; Portland Public Schools has a separately elected board. The apparent "coverage"
--     was Preschool for All labour agreements and a PEG cable franchise fund.
--   Rent Regulation x2 -- Novick (ABSENT for 2025-045, the only rent vote in the record) and Wilson
--     (no attributable source; his agenda scores tenant 0, eviction 0, landlord 0).
--   Homelessness Response x2 -- Avalos, Novick. Their four in-term items are two appointments, a
--     governance framework and Portland Street Response; none locates them on the housing-first /
--     shelter / enforcement scale. Same standard that retired Smith's row in mig 1608.
--
-- All 4 citations were fetched and asserted to carry their claim terms before this was written.

BEGIN;

DO $$
DECLARE v_existing int;
BEGIN
  SELECT count(*) INTO v_existing FROM inform.politician_context
   WHERE topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a'
     AND politician_id IN ('60fa9870-d984-46a7-a6ed-5f6fbebe72ce',
                           'acc73d7e-6522-40a9-bbe0-17cf56a96466',
                           'c6799d98-362a-4e27-b7c5-be45a82a150f');
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing criminalization rows, found %', v_existing; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES

('60fa9870-d984-46a7-a6ed-5f6fbebe72ce', '4938766b-b45a-46e3-93bd-b8b30651271a',
 'Ryan supports enforcing Portland''s camping rules, but only after shelter has been offered and refused. His council page records that he backed the 2024 City Camping Ordinance, which limits what people may do while camping and allows arrest for camping on public property if a person refuses multiple offers of shelter, and that he worked to ensure the policy offers people services before law enforcement becomes involved. He also voted for the 2023 and 2024 ordinances updating those public camping restrictions.',
 ARRAY['https://www.portland.gov/council/districts/2/dan-ryan/community-safety',
       'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=camping']),

('acc73d7e-6522-40a9-bbe0-17cf56a96466', '4938766b-b45a-46e3-93bd-b8b30651271a',
 'Green wants Portland to spend less on clearing camps and more on services for the people living in them. He authored a 2026 budget amendment, Sanitation, Hygiene and Workforce Development, that redirects $1 million out of the city''s homeless sweeps budget into basic hygiene, public sanitation and workforce development programs, including public bathrooms, free laundry services and low-barrier job opportunities.',
 ARRAY['https://www.portland.gov/council/districts/4/mitch-green/policy']),

('c6799d98-362a-4e27-b7c5-be45a82a150f', '4938766b-b45a-46e3-93bd-b8b30651271a',
 'Morillo wants Portland to move away from clearing homeless camps and toward services. Her published record states that she prepared legislation strengthening oversight of the city''s homelessness services while supporting a shift away from costly homeless camp sweeps and toward investments such as public bathrooms, sanitation and low-barrier jobs.',
 ARRAY['https://www.portland.gov/council/districts/3/angelita-morillo/2026-morillo-work']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('60fa9870-d984-46a7-a6ed-5f6fbebe72ce','4938766b-b45a-46e3-93bd-b8b30651271a',3),
('acc73d7e-6522-40a9-bbe0-17cf56a96466','4938766b-b45a-46e3-93bd-b8b30651271a',1),
('c6799d98-362a-4e27-b7c5-be45a82a150f','4938766b-b45a-46e3-93bd-b8b30651271a',1);

DO $$
DECLARE v_ctx int; v_ans int; v_closed int; v_orphan int; v_empty int; v_prose int;
  -- the 13 that stay retired: asserted ABSENT, not deleted
  closed text[] := ARRAY[
    -- Criminalization x7
    'c5db367e-9403-4a88-a95f-bf864279e13b|4938766b-b45a-46e3-93bd-b8b30651271a',
    'c9e19031-259e-4133-b5d9-96cf1a5f31ff|4938766b-b45a-46e3-93bd-b8b30651271a',
    '987e0304-acd0-4b00-bf65-9e4fdbe4af3a|4938766b-b45a-46e3-93bd-b8b30651271a',
    'dc00f7c1-54d1-46d8-8b35-545abdd38d8d|4938766b-b45a-46e3-93bd-b8b30651271a',
    '2947c92f-fee2-46e4-b472-9fd89a8f0f65|4938766b-b45a-46e3-93bd-b8b30651271a',
    '1518349b-3d63-49d0-9411-be19f86a7ea7|4938766b-b45a-46e3-93bd-b8b30651271a',
    '14ebbd1c-597e-483a-a846-73a7aca54ed2|4938766b-b45a-46e3-93bd-b8b30651271a',
    -- Rent Regulation x2
    'c9e19031-259e-4133-b5d9-96cf1a5f31ff|c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    'bd39d61e-3040-4ec1-815e-df16b1f9a8a0|c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    -- Homelessness Response x2
    'c5db367e-9403-4a88-a95f-bf864279e13b|6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    'c9e19031-259e-4133-b5d9-96cf1a5f31ff|6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'];
  added text[] := ARRAY[
    '60fa9870-d984-46a7-a6ed-5f6fbebe72ce|4938766b-b45a-46e3-93bd-b8b30651271a',
    'acc73d7e-6522-40a9-bbe0-17cf56a96466|4938766b-b45a-46e3-93bd-b8b30651271a',
    'c6799d98-362a-4e27-b7c5-be45a82a150f|4938766b-b45a-46e3-93bd-b8b30651271a'];
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(added);
  IF v_ctx <> 3 THEN RAISE EXCEPTION 'expected 3 new context rows, found %', v_ctx; END IF;
  SELECT count(*) INTO v_ans FROM inform.politician_answers WHERE politician_id::text||'|'||topic_id::text = ANY(added);
  IF v_ans <> 3 THEN RAISE EXCEPTION 'expected 3 new answer rows, found %', v_ans; END IF;

  -- the closed rows must remain absent from BOTH tables
  SELECT count(*) INTO v_closed FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(closed);
  IF v_closed <> 0 THEN RAISE EXCEPTION '% closed rows unexpectedly present in context', v_closed; END IF;
  SELECT count(*) INTO v_closed FROM inform.politician_answers WHERE politician_id::text||'|'||topic_id::text = ANY(closed);
  IF v_closed <> 0 THEN RAISE EXCEPTION '% closed rows unexpectedly present in answers', v_closed; END IF;

  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pc.politician_id::text||'|'||pc.topic_id::text = ANY(added) AND pa.politician_id IS NULL;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan rows', v_orphan; END IF;
  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(added) AND (sources IS NULL OR cardinality(sources)=0);
  IF v_empty <> 0 THEN RAISE EXCEPTION '% rows with empty sources', v_empty; END IF;
  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(added) AND reasoning ~ 'https?://';
  IF v_prose <> 0 THEN RAISE EXCEPTION '% rows embed a URL in reasoning', v_prose; END IF;
END $$;

COMMIT;
