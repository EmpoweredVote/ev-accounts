-- 1807_deselect_unverifiable_live_quotes.sql
--
-- URGENT. Two quotes that are LIVE to voters cannot be verified against any source. The reveal
-- IS the provenance in Read & Rank, so an unverifiable live quote is the one thing the product
-- cannot ship. Both are de-selected here; neither is deleted, so both are recoverable if a source
-- is later found.
--
-- 1. Nithya Raman / growth-and-development (8f51a4e3) — A FABRICATED QUOTATION.
--    Stored as: "[Measure ULA has] become a major obstacle [to new housing development]."
--    Traced to its origin. The Los Angeles Times (2026-02-15) wrote, with NO quotation marks:
--      "Although she has been a supporter of the tax, she has also concluded that it is a major
--       obstacle to building new housing."
--    — the reporter's own summary of Raman's position. Wikipedia then rewrote that sentence and
--    ADDED quotation marks the source does not have; American Kahani copied Wikipedia verbatim
--    ("According to Wikipedia..."); a curator then reconstructed a first-person sentence with
--    bracketed subject and object. NONE of Raman's own words survive. The only quoted phrase
--    anywhere in the chain, "major obstacle", originates with the LA Times reporter.
--
--    This is the same failure mode as the 2026-07-25 aggregator purge, which hard-deleted 1,173
--    ontheissues.org and 273 en.wikipedia.org quotes. It survived that purge because the purge
--    matched on SOURCE URL and this row cites the candidate's own campaign site — the laundering
--    hid it. Worth remembering: filtering aggregators by URL cannot catch a re-cited paraphrase.
--
-- 2. Karen Bass / homelessness (1a1a9e98) — UNRESOLVED.
--    "I will maintain focus on interim housing until the last street encampment is gone."
--    Not present on the cited mayor.lacity.gov/InsideSafe page, live or in three archived
--    captures, and five phrase searches found no contiguous run anywhere. May well be a real
--    statement, but nothing supports the citation.
--
-- Evidence: on-the-record docs/audits/2026-08-07-unverified-quote-trace.md
-- Recommend hard-deleting #1 once reviewed; a fabricated quotation has no route back.

BEGIN;

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM essentials.quotes
   WHERE id IN ('8f51a4e3-954b-48b9-acb0-71a437bf8b08',
                '1a1a9e98-f428-43e0-a35d-f341e0f07510')
     AND readrank_selected = true;
  IF n <> 2 THEN
    RAISE EXCEPTION 'Aborting: expected 2 live rows to de-select, found %.', n;
  END IF;
END $$;

UPDATE essentials.quotes
   SET readrank_selected = false
 WHERE id IN ('8f51a4e3-954b-48b9-acb0-71a437bf8b08',
              '1a1a9e98-f428-43e0-a35d-f341e0f07510');

COMMIT;
