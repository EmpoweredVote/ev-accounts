-- 1677_retire_md_dead_citation_stances.sql
--
-- Retire 85 published stance answers across 8 Maryland legislators whose ENTIRE cited source set
-- consists of pages that DO NOT EXIST. A citation to a page that never existed supports nothing,
-- so these chairs rested on inference alone.
--   Rollback record: data/stance-retirement/2026-08-10-md-dead-citation-retirements-rollback.json
--                    (the ONLY surviving copy of these rows' reasoning and sources)
--
-- HOW THE URLS WERE JUDGED -- measurement, not intuition. All 16 distinct URLs (one mgaleg + one
-- Ballotpedia per politician) were fetched twice, the second time immediately before this migration:
--   * mgaleg member pages 302 to /mgawebsite/Error/NotFound. The cited member id is simply wrong --
--     `rogers02` does not exist while `rogers01` does, `allen04` does not while `allen01` does. A
--     plausible-looking id with the wrong numeric suffix is a GUESSED citation, not link rot; rot
--     removes the member's page altogether.
--   * Ballotpedia articles return `"wgArticleId":0`, which is how Ballotpedia says "no such article"
--     while still serving HTTP 200 with a title derived from the URL.
--
-- ⚠ TWO TRAPS THAT NEARLY CORRUPTED THIS LIST, both worth remembering:
--   1. Ballotpedia rate-limits after ~50 rapid requests, then answers HTTP 202 with a ZERO-BYTE body.
--      A first sweep scored those as "dead" and produced a bogus 50-dead result -- 36 of them are
--      alive. The tells: the dead run was alphabetically contiguous, and the failures had NO
--      wgArticleId field at all (`aid=none`) rather than a field reading zero (`aid=0`). The verify
--      pass therefore aborts on any response under 1KB, and every row here was confirmed on a
--      full-size ~51KB response.
--   2. `count(DISTINCT sources) = 1` -- one source set reused across every topic -- OVER-FIRES. More
--      than half the national population it flags is legitimate: a candidate whose every stance
--      cites their own Issues page is correct, as is one sourced to a positions aggregator. Source
--      TYPE decides, not source COUNT. Nobody is retired here for reusing one source; they are
--      retired because the source does not exist.
--
-- SCOPE IS DELIBERATELY NARROW. 100 Maryland politicians / 1,125 rows cite a member landing page for
-- every topic, and 43 of 183 cited member URLs are dead. Only the 8 whose sources are ALL dead are
-- retired. Anyone holding even one resolving citation is left alone, because a live member page may
-- genuinely list sponsored legislation and this workstream's standing rule is that doubt resolves
-- toward KEEPING a row. The remaining ~92 politicians are a READING QUEUE, not a delete list.
--
-- ⚠ ALL 8 DROP TO ZERO ANSWERS. That is the correct outcome, not a reason to keep unsupported rows:
-- a profile with no compass is honest, one with a chair the source never supported is not. Every one
-- already has last_stances_researched_at IS NULL, so they read as UNRESEARCHED and resurface in the
-- research queue on their own -- distinct from a SET timestamp with zero answers, which is how an
-- honest "we looked and found nothing" is recorded and must never be manufactured. The migration
-- asserts this rather than assuming it. All 8 are REAL, currently-serving Maryland legislators
-- (verified on the MGA roster); the people stay, only the unsupported chairs go. All 8 topics are
-- OWED RE-RESEARCH.

BEGIN;

CREATE TEMP TABLE _retire_1677 (politician_id uuid, who text, expect int) ON COMMIT DROP;
INSERT INTO _retire_1677 VALUES
  ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344', 'Charles E. Sydnor, III', 15), -- sydnor01 + Charles_Sydnor
  ('72287137-7faf-4570-8d9e-c6f8d162f4e0', 'Stephen S. Hershey, Jr.', 12), -- hershey01 + Stephen_Hershey
  ('7d818044-a989-47e1-b6cf-d482ebad0600', 'J. Sandy Bartlett',       11), -- bartlett04 + Sandy_Bartlett
  ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c', 'Gary Simmons',            10), -- simmons05 + Gary_Simmons_(Maryland)
  ('d80816fc-da1d-48f4-95c9-467f8831933c', 'Jennifer White Holland',  10), -- holland03 + Jennifer_White_Holland
  ('a1f58b34-76ee-43ce-b152-4843c42f4f79', 'Nick Allen',              10), -- allen04 + Nick_Allen_(Maryland)
  ('24980735-6a39-4e48-94b0-7318cac8dfde', 'Mike Rogers (MD)',         9), -- rogers02 + Mike_Rogers_(Maryland_delegate)
  ('7d79931f-101c-415b-a6a0-b7a919f70905', 'Todd B. Morgan',           8); -- morgan04 + Todd_Morgan_(Maryland)

-- Abort unless the corpus still looks exactly as audited: the row counts must match, and every
-- context row must still carry ONLY the two dead URLs. If re-research has since landed a real
-- citation on any of these, that row must NOT be swept away silently.
DO $$
DECLARE bad text;
BEGIN
  SELECT string_agg(r.who || ': expected ' || r.expect || ' answers, found ' || c.n, '; ') INTO bad
  FROM _retire_1677 r
  JOIN LATERAL (SELECT count(*) AS n FROM inform.politician_answers a
                WHERE a.politician_id = r.politician_id) c ON true
  WHERE c.n <> r.expect;
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'answer counts changed since audit -- %', bad; END IF;

  SELECT string_agg(r.who || ' has a context row citing something other than the two dead URLs', '; ')
    INTO bad
  FROM _retire_1677 r
  WHERE EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = r.politician_id
      AND (c.sources IS NULL
           OR c.sources::text !~ 'mgaleg\.maryland\.gov/mgawebsite/Members/Details/'
           OR c.sources::text !~ 'ballotpedia\.org/')
  );
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'source set changed since audit -- %', bad; END IF;
END $$;

DELETE FROM inform.politician_context c USING _retire_1677 r
 WHERE c.politician_id = r.politician_id;

DELETE FROM inform.politician_answers a USING _retire_1677 r
 WHERE a.politician_id = r.politician_id;

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM inform.politician_answers a
    JOIN _retire_1677 r ON r.politician_id = a.politician_id;
  IF v <> 0 THEN RAISE EXCEPTION 'expected 0 answers to remain, found %', v; END IF;

  SELECT count(*) INTO v FROM inform.politician_context c
    JOIN _retire_1677 r ON r.politician_id = c.politician_id;
  IF v <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v; END IF;

  -- Emptied politicians MUST read as unresearched, never as an honest "we looked and found nothing".
  SELECT count(*) INTO v FROM essentials.politicians p
    JOIN _retire_1677 r ON r.politician_id = p.id
   WHERE p.last_stances_researched_at IS NOT NULL;
  IF v <> 0 THEN
    RAISE EXCEPTION '% emptied politician(s) still carry a research timestamp -- that reads as "we looked and found nothing"', v;
  END IF;

  -- The people themselves stay. Retiring a chair must never retire the officeholder.
  SELECT count(*) INTO v FROM essentials.politicians p
    JOIN _retire_1677 r ON r.politician_id = p.id
   WHERE p.is_active;
  IF v <> 8 THEN RAISE EXCEPTION 'expected all 8 politicians to remain active, found %', v; END IF;
END $$;

COMMIT;
