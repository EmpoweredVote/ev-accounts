-- Migration 1201: Edén López (Councilor, Cornelius OR) compass stances -- AUDIT-ONLY (not registered
-- in the ledger). Saved UTF-8 WITHOUT a byte-order mark -- this file carries the accented "Edén López"
-- literal in this header comment and in the identity-gate error message below.
-- Evidence-only; 100% cited; chairs model (value 1-5); 1 cited stance; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live = true (no hardcoded topic UUIDs).
-- Thin-yield city (appointee-heavy, sparsest documented-evidence city in the WashCo milestone per
-- 182-RESEARCH.md). López holds her seat by APPOINTMENT since April 2023 -- not election -- and the
-- council-minutes archive scanned (Nov 2025-Jul 2026) shows only routine unanimous procedural motions
-- and roll-call votes attributed to her, with no individually-authored statement or report. The single
-- roll-call vote below is the only vote in the scanned record tied to a compass-relevant, non-procedural
-- City action; it is used here rather than any of her many other routine unanimous consent-agenda votes,
-- which do not correspond to a compass topic. 35 of 36 non-judicial live topics have no attributable
-- public record for her and are honestly omitted rather than defaulted.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('local-immigration', 2, 'As a seated councilor at the time, Lopez was present at both the November 17, 2025 regular meeting and the 9:00 PM special meeting that followed that same evening, and voted (roll call, 5-0, both sessions) in favor of Resolution No. 2025-61, ratifying Mayor Dalin''s State of Emergency proclamation issued in direct response to "aggressive federal law enforcement actions in and around Cornelius." The ratified resolution authorized the City to redirect funds and suspend standard procurement to fund community-support efforts, issue multilingual emergency communications through community-organization partnerships, and coordinate with partner agencies to support community stability. No independent statement, report, or additional vote by Lopez on this topic was found in the council-minutes archive scanned beyond this roll-call vote. Voting to fund and coordinate a community-protective municipal response to federal immigration enforcement -- without a documented individual statement declaring outright non-cooperation with federal authorities -- matches the support-community-organizations / comply-only-with-court-ordered-process chair rather than the strongest refuse-cooperation chair.', ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-169', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-171', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Item/283?fileID=1401']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '18d8515e-3b3e-4d53-a1a3-4eece6e17dcc'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('local-immigration', 2, 'As a seated councilor at the time, Lopez was present at both the November 17, 2025 regular meeting and the 9:00 PM special meeting that followed that same evening, and voted (roll call, 5-0, both sessions) in favor of Resolution No. 2025-61, ratifying Mayor Dalin''s State of Emergency proclamation issued in direct response to "aggressive federal law enforcement actions in and around Cornelius." The ratified resolution authorized the City to redirect funds and suspend standard procurement to fund community-support efforts, issue multilingual emergency communications through community-organization partnerships, and coordinate with partner agencies to support community stability. No independent statement, report, or additional vote by Lopez on this topic was found in the council-minutes archive scanned beyond this roll-call vote. Voting to fund and coordinate a community-protective municipal response to federal immigration enforcement -- without a documented individual statement declaring outright non-cooperation with federal authorities -- matches the support-community-organizations / comply-only-with-court-ordered-process chair rather than the strongest refuse-cooperation chair.', ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-169', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-171', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Item/283?fileID=1401']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '18d8515e-3b3e-4d53-a1a3-4eece6e17dcc'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id -- a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = '18d8515e-3b3e-4d53-a1a3-4eece6e17dcc';
  IF v_ext IS DISTINCT FROM -4115554 THEN
    RAISE EXCEPTION 'UUID 18d8515e-3b3e-4d53-a1a3-4eece6e17dcc does not belong to external_id -4115554 (Eden Lopez) -- found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = '18d8515e-3b3e-4d53-a1a3-4eece6e17dcc';
  IF n <> 1 THEN
    RAISE EXCEPTION 'Expected % answers, found % -- topic_key mismatch dropped rows', 1, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = '18d8515e-3b3e-4d53-a1a3-4eece6e17dcc';
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
  WHERE a.politician_id = '18d8515e-3b3e-4d53-a1a3-4eece6e17dcc'
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
  WHERE c.politician_id = '18d8515e-3b3e-4d53-a1a3-4eece6e17dcc'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers a
      WHERE a.politician_id = c.politician_id AND a.topic_id = c.topic_id
    );
  IF n <> 0 THEN
    RAISE EXCEPTION '% context row(s) reference a topic_id with no corresponding answers row', n;
  END IF;
END $$;

COMMIT;
