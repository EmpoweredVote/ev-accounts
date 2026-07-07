-- Migration 1199: Angeles Godinez Valencia (Councilor / Council President, Cornelius OR) compass stances
-- AUDIT-ONLY (not registered in the ledger).
-- Evidence-only; 100% cited; chairs model (value 1-5); 1 cited stance; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live = true (no hardcoded topic UUIDs).
-- Thin-yield city (appointee-heavy, sparsest documented-evidence city in the WashCo milestone per
-- 182-RESEARCH.md). Godinez Valencia's City Council Reports across five consecutive meetings are
-- consistently anchored to community support for immigration-enforcement impacts -- a genuinely deep,
-- well-corroborated record on that single topic -- but no other compass-relevant policy statement or
-- roll-call vote attributable specifically to her (as distinct from a routine, unanimous procedural
-- motion) was found in the council-minutes archive scanned (Nov 2025-Jul 2026). 35 of 36 non-judicial
-- live topics have no attributable public record for her and are honestly omitted rather than defaulted.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('local-immigration', 2, 'Council President Godinez Valencia has repeatedly and consistently used her City Council Reports to organize community protection in response to federal immigration enforcement. At the November 17, 2025 regular meeting she reminded the community of immigration-related resources on the City''s website, encouraged registration with the Equity Corps of Oregon "to ensure access to legal support if detained," walked through know-your-rights guidance (the right to remain silent, the right to a lawyer, and the right to translation services, and a caution against signing documents without legal guidance), and encouraged residents able to do so to become ACLU legal observers to monitor ongoing enforcement activity. At the 9:00 PM special meeting later that same evening she read Mayor Dalin''s State-of-Emergency proclamation into the record in Spanish and seconded his motion adopting Resolution No. 2025-61, which authorized redirecting city funds and multilingual community-support communications (passed 5-0). At the February 2, 2026 meeting she again "highlighted ongoing concerns in the community related to recent protests and actions by ICE, emphasizing the importance of staying safe and aware" and pointed residents to available resources; at the March 2, 2026 and April 6, 2026 meetings she again encouraged the community to use the City''s immigration-related resources. This sustained pattern -- resource navigation, rights education, legal-observer recruitment, and co-sponsorship of the City''s emergency community-support funding -- is a protective, services-and-information posture; no independent statement or vote by her declaring an outright refusal of all cooperation with federal authorities (distinct from Mayor Dalin''s own separately-sourced police-department statement) was found, so it matches the support-community-organizations / comply-only-with-court-ordered-process chair rather than the strongest refuse-cooperation chair.', ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-169', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-171', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_02022026-187', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_03022026-192', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_04062026-199']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f75a20a9-1a22-4d23-ac9c-ac1040e27754'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('local-immigration', 2, 'Council President Godinez Valencia has repeatedly and consistently used her City Council Reports to organize community protection in response to federal immigration enforcement. At the November 17, 2025 regular meeting she reminded the community of immigration-related resources on the City''s website, encouraged registration with the Equity Corps of Oregon "to ensure access to legal support if detained," walked through know-your-rights guidance (the right to remain silent, the right to a lawyer, and the right to translation services, and a caution against signing documents without legal guidance), and encouraged residents able to do so to become ACLU legal observers to monitor ongoing enforcement activity. At the 9:00 PM special meeting later that same evening she read Mayor Dalin''s State-of-Emergency proclamation into the record in Spanish and seconded his motion adopting Resolution No. 2025-61, which authorized redirecting city funds and multilingual community-support communications (passed 5-0). At the February 2, 2026 meeting she again "highlighted ongoing concerns in the community related to recent protests and actions by ICE, emphasizing the importance of staying safe and aware" and pointed residents to available resources; at the March 2, 2026 and April 6, 2026 meetings she again encouraged the community to use the City''s immigration-related resources. This sustained pattern -- resource navigation, rights education, legal-observer recruitment, and co-sponsorship of the City''s emergency community-support funding -- is a protective, services-and-information posture; no independent statement or vote by her declaring an outright refusal of all cooperation with federal authorities (distinct from Mayor Dalin''s own separately-sourced police-department statement) was found, so it matches the support-community-organizations / comply-only-with-court-ordered-process chair rather than the strongest refuse-cooperation chair.', ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-169', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-171', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_02022026-187', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_03022026-192', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_04062026-199']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f75a20a9-1a22-4d23-ac9c-ac1040e27754'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id -- a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = 'f75a20a9-1a22-4d23-ac9c-ac1040e27754';
  IF v_ext IS DISTINCT FROM -4115552 THEN
    RAISE EXCEPTION 'UUID f75a20a9-1a22-4d23-ac9c-ac1040e27754 does not belong to external_id -4115552 (Angeles Godinez Valencia) -- found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = 'f75a20a9-1a22-4d23-ac9c-ac1040e27754';
  IF n <> 1 THEN
    RAISE EXCEPTION 'Expected % answers, found % -- topic_key mismatch dropped rows', 1, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = 'f75a20a9-1a22-4d23-ac9c-ac1040e27754';
  IF n <> 1 THEN
    RAISE EXCEPTION 'Expected % context rows, found % -- answers/context VALUES lists diverged', 1, n;
  END IF;
  -- Content-correspondence gate (WR-04, 181-REVIEW): the count checks above
  -- can't catch a hand-edit that changes one table's topic set (or blanks
  -- its reasoning/sources) without mirroring the other -- both would still
  -- report the same N. Assert set equality on topic_id between the two
  -- tables for this politician, and that every context row carries
  -- non-empty reasoning and sources.
  SELECT COUNT(*) INTO n FROM inform.politician_answers a
  WHERE a.politician_id = 'f75a20a9-1a22-4d23-ac9c-ac1040e27754'
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
  WHERE c.politician_id = 'f75a20a9-1a22-4d23-ac9c-ac1040e27754'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers a
      WHERE a.politician_id = c.politician_id AND a.topic_id = c.topic_id
    );
  IF n <> 0 THEN
    RAISE EXCEPTION '% context row(s) reference a topic_id with no corresponding answers row', n;
  END IF;
END $$;

COMMIT;
