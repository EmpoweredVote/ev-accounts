-- 1568_repoint_ca_governor_swapped_debate_citations.sql
--
-- The 2026-08-07 comparability audit's --verify-written pass flagged 18 CA Governor quotes whose
-- text does not appear in the video they cite. Investigation (all read-only) found the cause:
-- quotes from two ingested CA gubernatorial debates were CROSS-WIRED at bulk-import time.
--   qRNZ0kuA49k  <-->  -_LHkpd7PcM
-- The quotes are real and correctly attributed; only the citation was wrong. This is a partial
-- swap (11 of 20 quotes citing qRNZ0kuA49k, 5 of 13 citing -_LHkpd7PcM), so each row was traced
-- individually rather than by flipping the whole set.
--
-- Included here: only rows meeting BOTH bars -- a >=12-word contiguous verbatim run found in the
-- target transcript, AND meetings.segments diarization naming the candidate at the match. Weaker
-- traces (6-8 word runs, or a speaker mismatch at the hit) are deliberately EXCLUDED and left for
-- human judgment; see docs/audits/2026-08-07-ca-gov-provenance-trace.md.
--
-- All 12 rows are drafts (readrank_selected = false); nothing user-visible changes.
-- Timestamps are the start of the segment carrying the matched run.

BEGIN;

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM essentials.quotes
   WHERE id IN ('1336d1c4-59f0-4e59-bd0b-84cbf775490c',
                  '5610336d-2bfc-4e4d-9513-7a45fad7b6c4',
                  '579eed66-79ec-4585-b05f-da20b50caf25',
                  '598470e8-a0d2-4f01-9d55-5a8ca6a0d188',
                  '656250f1-522a-4da1-b871-78cb96b76001',
                  '69fbfa16-73c8-4bdf-b4cc-ec4f19c7a117',
                  '731e3186-d2a8-443b-af93-d79177706d80',
                  '89b887a0-5e7c-4eb5-bed2-30d92b51c44e',
                  '8c5d0c0d-4de5-4891-aa96-c8add3c93ea2',
                  'c3c16e55-3ac1-4ca9-8cde-33fd6f046a06',
                  'cc555fd4-da2a-4eda-ad21-e22ecb2b91ba',
                  'e4e05743-d1e8-4431-826b-1eb9f5ea557d')
     AND readrank_selected = false;
  IF n <> 12 THEN
    RAISE EXCEPTION 'Aborting: expected 12 draft rows to repoint, found %.', n;
  END IF;
END $$;


-- Steve Hilton / healthcare | 12-word run, seg-77, diarized: Steve Hilton
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM&t=1333s'
  WHERE id = '1336d1c4-59f0-4e59-bd0b-84cbf775490c' AND source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k';

-- Steve Hilton / fossil-fuels | 12-word run, seg-35, diarized: Steve Hilton
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k&t=605s'
  WHERE id = '5610336d-2bfc-4e4d-9513-7a45fad7b6c4' AND source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM';

-- Steve Hilton / housing | 12-word run, seg-200, diarized: Steve Hilton
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k&t=3573s'
  WHERE id = '579eed66-79ec-4585-b05f-da20b50caf25' AND source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM';

-- Steve Hilton / climate-change | 12-word run, seg-211, diarized: Steve Hilton
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM&t=2826s'
  WHERE id = '598470e8-a0d2-4f01-9d55-5a8ca6a0d188' AND source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k';

-- Xavier Becerra / housing | 12-word run, seg-127, diarized: Xavier Becerra
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM&t=1930s'
  WHERE id = '656250f1-522a-4da1-b871-78cb96b76001' AND source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k';

-- Xavier Becerra / data-centers | 12-word run, seg-257, diarized: Xavier Becerra
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM&t=3141s'
  WHERE id = '69fbfa16-73c8-4bdf-b4cc-ec4f19c7a117' AND source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k';

-- Steve Hilton / taxes | 12-word run, seg-33, diarized: Steve Hilton
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k&t=530s'
  WHERE id = '731e3186-d2a8-443b-af93-d79177706d80' AND source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM';

-- Xavier Becerra / healthcare | 12-word run, seg-73, diarized: Xavier Becerra
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM&t=1210s'
  WHERE id = '89b887a0-5e7c-4eb5-bed2-30d92b51c44e' AND source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k';

-- Xavier Becerra / childcare | 12-word run, seg-321, diarized: Xavier Becerra
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM&t=4001s'
  WHERE id = '8c5d0c0d-4de5-4891-aa96-c8add3c93ea2' AND source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k';

-- Xavier Becerra / civil-rights | 12-word run, seg-137, diarized: Xavier Becerra
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k&t=2404s'
  WHERE id = 'c3c16e55-3ac1-4ca9-8cde-33fd6f046a06' AND source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM';

-- Steve Hilton / abortion | 12-word run, seg-351, diarized: Steve Hilton
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM&t=4417s'
  WHERE id = 'cc555fd4-da2a-4eda-ad21-e22ecb2b91ba' AND source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k';

-- Xavier Becerra / civil-rights | 12-word run, seg-137, diarized: Xavier Becerra
UPDATE essentials.quotes SET source_url = 'https://www.youtube.com/watch?v=qRNZ0kuA49k&t=2404s'
  WHERE id = 'e4e05743-d1e8-4431-826b-1eb9f5ea557d' AND source_url = 'https://www.youtube.com/watch?v=-_LHkpd7PcM';


COMMIT;
