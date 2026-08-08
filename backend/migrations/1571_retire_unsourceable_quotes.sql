-- 1571_retire_unsourceable_quotes.sql
--
-- Hard-deletes the six quotes the 2026-08-07 provenance pass could not tie to any source, after
-- both an exhaustive search of all 153 ingested transcripts (17,660 segments) and an open-web
-- trace including archived captures. The reveal IS the provenance in Read & Rank: a quote whose
-- source cannot be established is not a quote, and keeping it in the draft pool only invites a
-- future curator to select it.
--
-- Nothing is lost. Each row's text, its cited source, the searches run against it, and the reason
-- it failed are recorded in on-the-record docs/audits/2026-08-07-unverified-quote-trace.md, which
-- is in git. Deleting the row removes it from selection; the record survives.
--
-- All six are drafts (readrank_selected = false — two were de-selected by migration 1569), and
-- none is referenced by essentials.readrank_questions.origin_quote_id.
--
--   8f51a4e3  Raman / growth-and-development  — FABRICATED. An LA Times paraphrase (no quotation
--             marks) that Wikipedia re-published WITH quote marks, an aggregator copied, and a
--             curator rebuilt into a first-person sentence. None of Raman's words survive.
--   66088b79  Becerra / deportation           — NOT A QUOTATION. "Support DACA, oppose Muslim ban
--             and family separation" is an ontheissues.org section heading — and is verbatim the
--             example QUOTE-CURATION-PRINCIPLES §5 gives for "a summary, not a quote". The cited
--             campaign URL 404s and was never archived: a page that never existed.
--   9afd3c42  Becerra / abortion              — WRONG SPEAKER. The words are in the 2026-05-15
--             debate, but the moderator thanks that speaker (Villaraigosa) and then calls Becerra,
--             who answers separately ten seconds later. An off-by-one capture.
--   1a1a9e98  Bass / homelessness             — Absent from the cited page live and in three
--             archived captures; five phrase searches found no contiguous run anywhere.
--   3975e2c3  Bass / public-safety-approach   — Unresolved; the one cited host (lapublicpress.org)
--             returns 403 to automated fetching and has no Wayback captures. A human with a
--             browser could still rescue this one.
--   3dbb0df7  Raman / immigration             — Unresolved against the cited city-clerk document.
--
-- The last three may well be real statements. They are removed because nothing supports the
-- citation, not because the candidate is judged not to have said them.

BEGIN;

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM essentials.quotes
   WHERE id IN ('8f51a4e3-954b-48b9-acb0-71a437bf8b08',
                '66088b79-e0dc-4ea7-84b2-d2d0f5c6d676',
                '9afd3c42-1aeb-45e6-87ac-5d98386543a1',
                '1a1a9e98-f428-43e0-a35d-f341e0f07510',
                '3975e2c3-0080-496b-9c9c-82c65696c454',
                '3dbb0df7-1bc1-49d1-9989-7c6e7cb890c7')
     AND readrank_selected = false;
  IF n <> 6 THEN
    RAISE EXCEPTION 'Aborting: expected 6 draft rows to retire, found %. One may have gone live.', n;
  END IF;
END $$;

DELETE FROM essentials.quotes
 WHERE id IN ('8f51a4e3-954b-48b9-acb0-71a437bf8b08',
              '66088b79-e0dc-4ea7-84b2-d2d0f5c6d676',
              '9afd3c42-1aeb-45e6-87ac-5d98386543a1',
              '1a1a9e98-f428-43e0-a35d-f341e0f07510',
              '3975e2c3-0080-496b-9c9c-82c65696c454',
              '3dbb0df7-1bc1-49d1-9989-7c6e7cb890c7');

COMMIT;
