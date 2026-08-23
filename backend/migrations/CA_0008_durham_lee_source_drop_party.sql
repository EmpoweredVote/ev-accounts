-- CA_0008_durham_lee_source_drop_party.sql
-- Drop the party word from the Mike Lee disambiguator provenance strings.
--
-- WHY. Wave 2 (CA_0007) seated Durham County's board chair as
-- `Dr. Michael "Mike" Lee` and recorded, in the provenance string, WHY he is a
-- distinct person from the two Lees already in the corpus. That string named the
-- NC senator's party:
--
--   ... District 7's Michael V. Lee (external_id -3710007, Republican,
--       New Hanover County) -- see ROSTERS.md 'Mike Lee collision' section.
--
-- The party word is identity evidence about a DIFFERENT person, not a claim about
-- Durham's Lee, and `data_source` is read by no essentials read path. But party
-- affiliation is antipartisan by design in this corpus -- it lives on
-- `races.primary_party`, never on an officeholder row -- and these were the only
-- rows breaking that. The disambiguation is unchanged without it: external_id
-- -3710007 plus chamber plus New Hanover County is already unique.
--
-- 🔴 SCOPE IS EXACTLY TWO ROWS, AND THAT MATTERS. A blanket sweep of
-- `source ILIKE '%republican%'` would have CORRUPTED TWO LEGITIMATE CITATIONS.
-- Measured 2026-08-22 -- four rows matched a party word across provenance columns:
--
--   1. Nancy J. Theriault (ME House 29), office_terms.source:
--      "... Maine House Republicans release 2026-07-14"
--      -> a PUBLISHER NAME citing who issued the source document. LEGITIMATE.
--   2. Penelope Sapp (Kitsap County), office_terms.source:
--      "... three names forwarded by the county Democratic central committee ..."
--      -> a factual description of the LEGAL APPOINTMENT MECHANISM under WA law.
--         LEGITIMATE.
--   3. Dr. Michael "Mike" Lee, politicians.data_source   <- this migration
--   4. Dr. Michael "Mike" Lee, office_terms.source       <- this migration
--
-- Rows 1 and 2 are deliberately left alone, and the post-verify gate below
-- ASSERTS they survive untouched. A predicate must read the SHAPE of a value,
-- never merely what substring it contains.
--
-- The generator (scripts/gen-durham-migrations.mjs, via
-- data/seed-durham-2026/durham-roster.json) was already corrected forward, so
-- wave 3 will not re-emit the party word. This migration cleans the applied rows.
--
-- Idempotent: both UPDATEs are guarded on the substring still being present, and
-- re-running is a no-op.

BEGIN;

-- ─── 1. politicians.data_source ──────────────────────────────────────────────
UPDATE essentials.politicians
   SET data_source = replace(data_source, ', Republican,', ',')
 WHERE external_id::bigint = -3730008
   AND data_source LIKE '%, Republican,%';

-- ─── 2. office_terms.source (same person, same string) ───────────────────────
UPDATE essentials.office_terms ot
   SET source = replace(ot.source, ', Republican,', ',')
  FROM essentials.politicians p
 WHERE p.id = ot.politician_id
   AND p.external_id::bigint = -3730008
   AND ot.source LIKE '%, Republican,%';

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  n_lee_party   int;
  n_lee_rows    int;
  n_theriault   int;
  n_sapp        int;
BEGIN
  -- (a) Durham's Lee carries no party word in either provenance column.
  SELECT (SELECT count(*) FROM essentials.politicians p
           WHERE p.external_id::bigint = -3730008
             AND (p.data_source ILIKE '%republican%' OR p.data_source ILIKE '%democrat%'))
       + (SELECT count(*) FROM essentials.office_terms ot
           JOIN essentials.politicians p2 ON p2.id = ot.politician_id
          WHERE p2.external_id::bigint = -3730008
            AND (ot.source ILIKE '%republican%' OR ot.source ILIKE '%democrat%'))
    INTO n_lee_party;
  IF n_lee_party <> 0 THEN
    RAISE EXCEPTION 'CA_0008: Durham Lee still carries a party word in % provenance row(s)', n_lee_party;
  END IF;

  -- (b) The disambiguator itself SURVIVED -- we trimmed a word, not the evidence.
  SELECT count(*) INTO n_lee_rows
    FROM essentials.politicians p
   WHERE p.external_id::bigint = -3730008
     AND p.data_source LIKE '%-3710007%'
     AND p.data_source LIKE '%New Hanover County%';
  IF n_lee_rows <> 1 THEN
    RAISE EXCEPTION 'CA_0008: Lee disambiguator damaged — expected 1 row still citing -3710007 and New Hanover County, found %', n_lee_rows;
  END IF;

  -- (c) 🔴 The two LEGITIMATE party mentions are UNTOUCHED. This is the assertion
  --     that proves we did not over-reach into a publisher name or a description
  --     of a statutory appointment mechanism.
  SELECT count(*) INTO n_theriault
    FROM essentials.office_terms ot
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE p.full_name = 'Nancy J. Theriault'
     AND ot.source ILIKE '%Maine House Republicans%';
  IF n_theriault <> 1 THEN
    RAISE EXCEPTION 'CA_0008: over-reach — Theriault publisher citation altered (expected 1, found %)', n_theriault;
  END IF;

  SELECT count(*) INTO n_sapp
    FROM essentials.office_terms ot
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE p.full_name = 'Penelope Sapp'
     AND ot.source ILIKE '%Democratic central committee%';
  IF n_sapp <> 1 THEN
    RAISE EXCEPTION 'CA_0008: over-reach — Sapp appointment-mechanism citation altered (expected 1, found %)', n_sapp;
  END IF;
END $$;

COMMIT;
