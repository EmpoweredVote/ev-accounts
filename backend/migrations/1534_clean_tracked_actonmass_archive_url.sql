-- 1534_clean_tracked_actonmass_archive_url.sql
--
-- Re-point 6 rows from a Wayback capture whose archived URL carries EMAIL-CAMPAIGN TRACKING IDs to the
-- clean-URL capture of the same page. Same bill, same page, same content -- only the query string goes.
--   Review: data/stance-retirement/2026-08-02-actonmass-bills-repoint.md
--
-- 🔴 WHY THIS IS NOT COSMETIC. 1533 chose the latest capture of
-- /bills/driver-license-regardless-immigration-status/, and the latest one Wayback holds is of the URL
-- as it appeared in an EveryAction blast:
--   ?utm_medium=&emci=62e031af-…&emdi=f18f9377-…&ceid=21506428
-- `emci`/`emdi`/`ceid` are per-recipient contact identifiers. Publishing them inside a citation
-- republishes one supporter's mail-list IDs on every profile that cites this bill, for no benefit.
--
-- ⚠ THE BUG THAT LET IT THROUGH, so the next pass does not repeat it: capture selection grouped CDX
-- rows by URL PATH, which silently merged the clean captures and the tracked ones into one bucket and
-- then took the newest -- a tracked one. Wayback treats the query string as part of the URL; grouping
-- has to as well, or a tracking parameter can win on recency alone. 9 clean captures of this page were
-- available the whole time.
--
-- The replacement capture (20241031023942, same day as the tracked one) was verified to be the same
-- page: <title> "Work & Family Mobility Act | Act On Mass", 63,034 chars, full bill history present.

BEGIN;

UPDATE inform.politician_context pc
   SET sources = array_replace(pc.sources,
         'https://web.archive.org/web/20241031040959/https://actonmass.org/bills/driver-license-regardless-immigration-status/?utm_medium=&emci=62e031af-0fef-ec11-b47a-281878b83d8a&emdi=f18f9377-2cef-ec11-b47a-281878b83d8a&ceid=21506428',
         'https://web.archive.org/web/20241031023942/https://actonmass.org/bills/driver-license-regardless-immigration-status/')
 WHERE 'https://web.archive.org/web/20241031040959/https://actonmass.org/bills/driver-license-regardless-immigration-status/?utm_medium=&emci=62e031af-0fef-ec11-b47a-281878b83d8a&emdi=f18f9377-2cef-ec11-b47a-281878b83d8a&ceid=21506428' = ANY(pc.sources);

DO $$
DECLARE v_n int;
BEGIN
  -- All 6 rows now cite the clean capture, scoped to (politician_id, topic_id).
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.value <> 0
   WHERE 'https://web.archive.org/web/20241031023942/https://actonmass.org/bills/driver-license-regardless-immigration-status/' = ANY(pc.sources);
  IF v_n <> 6 THEN RAISE EXCEPTION 'expected 6 rows citing the clean capture, found %', v_n; END IF;

  -- 🔴 And no citation anywhere still carries a contact identifier -- broader than the one URL fixed
  -- here, because the point is the class, not the instance.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
    CROSS JOIN LATERAL unnest(pc.sources) s
   WHERE s ~ '[?&](emci|emdi|ceid)=';
  IF v_n <> 0 THEN RAISE EXCEPTION '% citation(s) still carry email-campaign contact ids', v_n; END IF;
END $$;

COMMIT;
