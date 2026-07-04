-- Migration 1198: Jeffrey C. Dalin (Mayor, Cornelius OR) compass stances -- AUDIT-ONLY (not registered in the ledger)
-- Evidence-only; 100% cited; chairs model (value 1-5); 2 cited stances; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live = true (no hardcoded topic UUIDs).
-- Thin-yield city (appointee-heavy, sparsest documented-evidence city in the WashCo milestone per
-- 182-RESEARCH.md); Dalin (Mayor continuously since Nov 2011) has the deepest record of the 4 filled
-- seats, but even his documented record outside the Nov 17, 2025 immigration-enforcement emergency is
-- thin. 34 of 36 non-judicial live topics have no attributable public record for Dalin and are honestly
-- omitted rather than defaulted.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('local-immigration', 1, 'On November 17, 2025, Mayor Dalin issued a written Proclamation declaring a State of Emergency under Cornelius Municipal Code 2.60 in response to "aggressive federal law enforcement actions in and around Cornelius" that had "resulted in the disruption of normal daily life," fear, and anxiety in the majority-Latino community. He read the proclamation into the record at a 9:00 PM special council meeting that evening and made the motion (seconded by Council President Godinez Valencia; passed 5-0) adopting Resolution No. 2025-61 to ratify it. The ratified emergency powers authorized the City to redirect city funds and suspend standard procurement to expedite community-support efforts, issue emergency public information and multilingual communications through partnerships with community organizations, and coordinate with partner agencies to support community stability -- concrete redirected city resources, not a symbolic statement alone. At the earlier regular session that same evening, Dalin reported that metropolitan-area mayors and city managers were actively sharing information on federal enforcement activity and exploring lawful protective actions, and he pointed residents to Congresswoman Bonamici''s office and City Hall as points of contact for families with detained or missing relatives. Separately, an official City of Cornelius News Flash (recovered via search-index extraction -- the live page has since been reorganized and returns 404, consistent with the D-16 fallback pattern) carried "a message from Mayor Dalin" stating plainly that "As part of Oregon''s sanctuary state, the Cornelius Police Department does not work with ICE or enforce immigration laws," with both the Police and Fire Departments "dedicated to protecting and serving every person in our community" regardless of status. Declaring a civil emergency specifically to fund and coordinate community-protective measures, combined with an explicit public statement that the City''s own police department will not enforce immigration law or work with ICE, matches the refuse-cooperation / prohibit-information-sharing chair -- the most protective posture on this spoke.', ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-169', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-171', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Item/283?fileID=1401', 'https://www.corneliusor.gov/m/newsflash/Home/Detail/86']::text[]),
    ('economic-development', 3, 'At the March 2, 2026 council meeting, Mayor Dalin reported on regional meetings and legislative advocacy and discussed his support for regional land-use and economic-development efforts, specifically highlighting "the need for additional industrial land to support job growth and economic diversity" while "emphasizing the importance of balancing development with preservation of agricultural lands"; he separately voiced support for a Metro hazardous-waste transfer station in western Washington County, citing underserved access in the area. At the following March 16, 2026 meeting, Dalin reported on a Metropolitan Mayors Consortium session covering Metro''s increased involvement in economic development, and -- alongside other council members -- emphasized "the need for sufficient industrial land, economic diversity, and support for both large and small employers" amid land-availability constraints. This is a targeted, industry-and-infrastructure recruitment approach explicitly bounded by agricultural-land preservation and an explicit large-and-small-employer balance -- not an across-the-board subsidy push or a deregulation-only posture -- matching the targeted-incentives chair.', ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_03022026-192', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_03162026-194']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '856f7e70-a846-4ba3-a0df-e7d8146ed11a'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('local-immigration', 1, 'On November 17, 2025, Mayor Dalin issued a written Proclamation declaring a State of Emergency under Cornelius Municipal Code 2.60 in response to "aggressive federal law enforcement actions in and around Cornelius" that had "resulted in the disruption of normal daily life," fear, and anxiety in the majority-Latino community. He read the proclamation into the record at a 9:00 PM special council meeting that evening and made the motion (seconded by Council President Godinez Valencia; passed 5-0) adopting Resolution No. 2025-61 to ratify it. The ratified emergency powers authorized the City to redirect city funds and suspend standard procurement to expedite community-support efforts, issue emergency public information and multilingual communications through partnerships with community organizations, and coordinate with partner agencies to support community stability -- concrete redirected city resources, not a symbolic statement alone. At the earlier regular session that same evening, Dalin reported that metropolitan-area mayors and city managers were actively sharing information on federal enforcement activity and exploring lawful protective actions, and he pointed residents to Congresswoman Bonamici''s office and City Hall as points of contact for families with detained or missing relatives. Separately, an official City of Cornelius News Flash (recovered via search-index extraction -- the live page has since been reorganized and returns 404, consistent with the D-16 fallback pattern) carried "a message from Mayor Dalin" stating plainly that "As part of Oregon''s sanctuary state, the Cornelius Police Department does not work with ICE or enforce immigration laws," with both the Police and Fire Departments "dedicated to protecting and serving every person in our community" regardless of status. Declaring a civil emergency specifically to fund and coordinate community-protective measures, combined with an explicit public statement that the City''s own police department will not enforce immigration law or work with ICE, matches the refuse-cooperation / prohibit-information-sharing chair -- the most protective posture on this spoke.', ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-169', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-171', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Item/283?fileID=1401', 'https://www.corneliusor.gov/m/newsflash/Home/Detail/86']::text[]),
    ('economic-development', 3, 'At the March 2, 2026 council meeting, Mayor Dalin reported on regional meetings and legislative advocacy and discussed his support for regional land-use and economic-development efforts, specifically highlighting "the need for additional industrial land to support job growth and economic diversity" while "emphasizing the importance of balancing development with preservation of agricultural lands"; he separately voiced support for a Metro hazardous-waste transfer station in western Washington County, citing underserved access in the area. At the following March 16, 2026 meeting, Dalin reported on a Metropolitan Mayors Consortium session covering Metro''s increased involvement in economic development, and -- alongside other council members -- emphasized "the need for sufficient industrial land, economic diversity, and support for both large and small employers" amid land-availability constraints. This is a targeted, industry-and-infrastructure recruitment approach explicitly bounded by agricultural-land preservation and an explicit large-and-small-employer balance -- not an across-the-board subsidy push or a deregulation-only posture -- matching the targeted-incentives chair.', ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_03022026-192', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_03162026-194']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '856f7e70-a846-4ba3-a0df-e7d8146ed11a'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id -- a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = '856f7e70-a846-4ba3-a0df-e7d8146ed11a';
  IF v_ext IS DISTINCT FROM -4115551 THEN
    RAISE EXCEPTION 'UUID 856f7e70-a846-4ba3-a0df-e7d8146ed11a does not belong to external_id -4115551 (Jeffrey C. Dalin) -- found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = '856f7e70-a846-4ba3-a0df-e7d8146ed11a';
  IF n <> 2 THEN
    RAISE EXCEPTION 'Expected % answers, found % -- topic_key mismatch dropped rows', 2, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = '856f7e70-a846-4ba3-a0df-e7d8146ed11a';
  IF n <> 2 THEN
    RAISE EXCEPTION 'Expected % context rows, found % -- answers/context VALUES lists diverged', 2, n;
  END IF;
  -- Content-correspondence gate (WR-04, 181-REVIEW): the count checks above
  -- can't catch a hand-edit that changes one table's topic set (or blanks
  -- its reasoning/sources) without mirroring the other -- both would still
  -- report the same N. Assert set equality on topic_id between the two
  -- tables for this politician, and that every context row carries
  -- non-empty reasoning and sources.
  SELECT COUNT(*) INTO n FROM inform.politician_answers a
  WHERE a.politician_id = '856f7e70-a846-4ba3-a0df-e7d8146ed11a'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_context c
      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
        AND c.reasoning IS NOT NULL AND length(trim(c.reasoning)) > 0
        AND c.sources IS NOT NULL AND array_length(c.sources, 1) > 0
    );
  IF n <> 0 THEN
    RAISE EXCEPTION '% answers row(s) have no corresponding non-empty context row (topic_id mismatch or empty reasoning/sources)', n;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_context c
  WHERE c.politician_id = '856f7e70-a846-4ba3-a0df-e7d8146ed11a'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers a
      WHERE a.politician_id = c.politician_id AND a.topic_id = c.topic_id
    );
  IF n <> 0 THEN
    RAISE EXCEPTION '% context row(s) reference a topic_id with no corresponding answers row', n;
  END IF;
END $$;

COMMIT;
