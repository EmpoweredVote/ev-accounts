-- 1669_backfill_1668_provenance_notes.sql
--
-- Fixes a defect in migration 1668. The repoint UPDATE built its note as:
--
--   notes = nullif(trim(coalesce(ps.notes,'')),'')
--           || CASE WHEN nullif(...) IS NULL THEN '' ELSE ' | ' END
--           || 'mig 1668: repointed from deleted politician ' || ...
--
-- The CASE correctly handles the separator, but the leading nullif() returns
-- NULL for a row whose notes were empty, and NULL || text is NULL in SQL -- so
-- the whole note evaluated to NULL and the stamp was dropped. 8 of the 13 FEC
-- rows had empty notes and therefore ended up with notes = NULL instead of the
-- provenance line. The repointing itself was correct on all 13; only the audit
-- trail was lost, and no pre-existing note content was destroyed (those rows
-- held an empty string).
--
-- The deleted politician ids below were captured from the live table BEFORE
-- 1668 overwrote the column -- they cannot be recovered from the database now,
-- which is precisely why the stamp matters.
--
-- Lesson for future cleanup migrations: `coalesce(notes,'') || 'text'` is the
-- safe form. Reserve nullif() for the separator decision only, and verify the
-- stamp count after the fact rather than trusting the UPDATE's row count --
-- 1668's own guard checked that 13 rows had been repointed, which they had,
-- so it passed while the notes were silently NULL.

BEGIN;

UPDATE transparent_motivations.politician_sources ps
SET notes = 'mig 1668: repointed from deleted politician ' || v.old_pol
            || ' (FEC id verified via api.open.fec.gov); note backfilled by mig 1669'
FROM (VALUES
  ('39b763e0-4716-43be-8ca7-9870dc5ce5f2'::uuid,'0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff'), -- S6MN00499 Angie Craig
  ('182a9d66-a9cf-4d5e-85c2-a9e1e2a1d0ed','3957855d-a78c-492d-b3b6-0f680c1f82c8'),       -- S6MI00426 Haley Stevens
  ('33ee4cba-5509-470a-84ca-da21b7ac47e7','15bd3382-0d8a-4c3e-8ab9-ab324517882d'),       -- S6MN00440 Peggy Flanagan
  ('b998192d-a8ac-478b-81e3-72af5e2127a4','e2f59e14-a81d-45fe-86c0-c992a63d86cd'),       -- S6WY00209 Harriet Hageman
  ('c560a02a-371c-459f-acaf-eed509c3c7bd','965ffd53-89a8-46cc-adb1-16bf588ed1c3'),       -- S6IL00458 Juliana Stratton
  ('421c8343-e4ef-4dca-94c0-c09d8e36e9f4','a4f51d46-c361-4b17-bd63-7932a01ee2c3'),       -- S6NH00141 Chris Pappas
  ('31ff8739-26df-4915-8431-ce14a430c068','c79994ff-9e88-4318-97d9-d06b0ede183f'),       -- S6LA00664 Julia Letlow
  ('fcbe0553-e796-46b1-96cd-28f17c03009d','b1114b75-8ca1-494e-9251-e8faa84ff408')        -- S6OK04247 Kevin Hern
) AS v(source_id, old_pol)
WHERE ps.id = v.source_id
  AND ps.notes IS NULL;   -- never clobber a note written since 1668

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
  FROM transparent_motivations.politician_sources
  WHERE notes LIKE '%mig 1668%';
  IF n <> 29 THEN
    RAISE EXCEPTION 'aborting: expected 29 rows stamped with mig 1668 (13 FEC + 14 local + 2 Lee), got %', n;
  END IF;
END $$;

COMMIT;
