-- 1570_repoint_traced_quote_citations.sql
--
-- Five of the ten quotes traced by the 2026-08-07 unverified-quote research. Only these five
-- were INDEPENDENTLY RE-VERIFIED before applying: each proposed page was fetched here and the
-- quote's own distinctive run confirmed present in it. Nothing is applied on the research
-- report alone.
--
-- Held back, deliberately, and why:
--   * 8403a778 (Raman/deportation -> nithyaforthecity.com/immigrants) — the run is not in the
--     page's raw HTML. Probably a JS-rendered page rather than a bad trace, but unconfirmed. The
--     research also flagged a live scope question: it is campaign-platform prose, not speech.
--   * 9eb66701 (Hilton/fossil-fuels -> UUOsiG5tkDU&t=1226) — adds a timestamp to an
--     already-correct URL, but OUR ingested transcript for that video does not contain the run
--     (the research matched it against YouTube's caption track). Unverifiable against our data.
--   * ebb39e53, 9403fcba, e842e9d2 -> youtube.com/watch?v=xFNkHY_m_eE (CBS/SF Examiner debate).
--     That video IS NOT INGESTED, so nothing here can verify it. The right fix is to ingest it
--     and let the pipeline verify natively — a discovered_sources row is filed for that. Two of
--     those three ALSO carry text defects (see below), so they need a wording decision anyway.
--
-- QUOTE WORDING IS NOT TOUCHED. Three traced rows store text that diverges from their source and
-- must not ship as written; correcting a quote is a human call and is deliberately absent here:
--   * ebb39e53 (Hilton) — stored "I don't want…"; the audio says "We don't want…".
--   * e842e9d2 (Becerra) — stored "tariffs that are attacks"; the audio is "tariffs that are a
--     tax". The stored text reproduces an ASR homophone and is not grammatical English — evidence
--     this batch was lifted from a machine transcript rather than heard.
--   * 97459d18 / ea35df13 (Raman) — text truncates mid-sentence at "…America."; the original
--     continues ", and our affordability crisis is making it even worse". Repointed here anyway,
--     because the truncation does not make the citation wrong.
--
-- One of the five (41ac4890, Bass/public-safety) is LIVE: its citation was two months adrift
-- (an April 2026 budget story) from the 2025-12-11 letter the words actually come from.
--
-- Evidence: docs/audits/2026-08-07-unverified-quote-trace.md

BEGIN;

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM essentials.quotes WHERE id IN ('41ac4890-8de7-46b3-8e85-b62a99bdf5f5',
                                                            '17d7f049-984a-4d36-b4dd-dab0dcab0069',
                                                            'ef8712c2-f45c-4905-a177-bab2285e6a89',
                                                            '97459d18-b3dd-44d4-8648-8358c18969dd',
                                                            'ea35df13-e121-41e5-9a0d-fc63ffdfd06f');
  IF n <> 5 THEN RAISE EXCEPTION 'Aborting: expected 5 rows, found %.', n; END IF;
END $$;


UPDATE essentials.quotes SET source_url = 'https://lamag.com/news/mayor-karen-bass-pushes-city-council-to-approve-hiring-of-more-lapd-cops/', source_name = 'lamag.com'
  WHERE id = '41ac4890-8de7-46b3-8e85-b62a99bdf5f5';

UPDATE essentials.quotes SET source_url = 'https://mayor.lacity.gov/news/mayor-bass-visits-adaptive-reuse-project-will-create-more-500-units-affordable-housing', source_name = 'mayor.lacity.gov'
  WHERE id = '17d7f049-984a-4d36-b4dd-dab0dcab0069';

UPDATE essentials.quotes SET source_url = 'http://web.archive.org/web/20220819070334/https://councildistrict4.lacity.org/councilmember-nithya-raman-remarks-todays-la-city-council-meeting-revised-city-ordinance-4118', source_name = 'web.archive.org (councildistrict4.lacity.org, captured 2022-08-19)'
  WHERE id = 'ef8712c2-f45c-4905-a177-bab2285e6a89';

UPDATE essentials.quotes SET source_url = 'https://la.streetsblog.org/2021/10/28/council-approves-raman-harris-dawson-motion-to-foster-affordable-development-in-high-resource-areas', source_name = 'la.streetsblog.org'
  WHERE id = '97459d18-b3dd-44d4-8648-8358c18969dd';

UPDATE essentials.quotes SET source_url = 'https://la.streetsblog.org/2021/10/28/council-approves-raman-harris-dawson-motion-to-foster-affordable-development-in-high-resource-areas', source_name = 'la.streetsblog.org'
  WHERE id = 'ea35df13-e121-41e5-9a0d-fc63ffdfd06f';


COMMIT;
