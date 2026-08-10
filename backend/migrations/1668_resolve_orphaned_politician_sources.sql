-- 1668_resolve_orphaned_politician_sources.sql
--
-- Resolves the 49 `transparent_motivations.politician_sources` rows whose
-- `essentials_politician_id` referenced a politician that no longer exists.
-- These were invisible to voters (no politician to display against) but held
-- 97,224 contributions, and nothing in the schema prevented more of them.
--
-- Identity of every FEC row was established INDEPENDENTLY of the matcher that
-- created the link: each `external_id` was resolved against the live FEC API
-- (/v1/candidate/{id}/) and the resulting name/office/state compared to
-- essentials.politicians. This deliberately avoids re-applying the producer's
-- own predicate, which is what made the earlier confirm-la-socrata.ts pass
-- worthless (see migrations 1664/1665).
--
-- Verified before writing:
--   * 0 of 97,224 contributions on these sources share a source_transaction_id
--     with any contribution already under the target politician, so repointing
--     cannot double-count. All 97,224 rows carry a non-null transaction id, so
--     that zero is real and not an artefact of NULLs.
--   * No orphan id appears in public.politician_id_bridge or inform.politicians.
--
-- Effect: 27 sources repointed as confirmed (96,619 FEC + 605 local
-- contributions become voter-visible), 2 repointed as needs_research,
-- 20 defective zero-contribution rows deleted, and a FOREIGN KEY added so a
-- politician can no longer be deleted out from under their finance sources.

BEGIN;

-- The FK validation at the end scans all 86k source rows; give it room.
SET LOCAL statement_timeout = '600s';

-- ---------------------------------------------------------------------------
-- 1. FEC sources (13) -> the living politician the FEC candidate id belongs to.
--    Each is a 2026 Senate campaign of a sitting House member, two sitting
--    Lieutenant Governors, an LAUSD board member, and one CA-34 candidate.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE _fec_repoint (source_id uuid, new_pol uuid, who text) ON COMMIT DROP;
INSERT INTO _fec_repoint VALUES
 ('39b763e0-4716-43be-8ca7-9870dc5ce5f2','00b75ed0-3355-4bc5-a426-1667c12e2486','S6MN00499 Angie Craig'),
 ('1a2c4d1a-0a19-46b2-981e-f59e5c4c9bdd','b6542655-fc71-4b18-a022-6528522cdcae','S6GA00390 Mike Collins'),
 ('182a9d66-a9cf-4d5e-85c2-a9e1e2a1d0ed','5b642054-504c-46c8-a68b-324e7b593587','S6MI00426 Haley Stevens'),
 ('33ee4cba-5509-470a-84ca-da21b7ac47e7','c788d228-1757-4069-bca4-6a9586819dc8','S6MN00440 Peggy Flanagan'),
 ('b998192d-a8ac-478b-81e3-72af5e2127a4','1e08c7c7-68c1-4498-90b2-20850bac1c80','S6WY00209 Harriet Hageman'),
 ('c560a02a-371c-459f-acaf-eed509c3c7bd','40373be4-5a51-48d7-8afc-e6be734653ce','S6IL00458 Juliana Stratton'),
 ('421c8343-e4ef-4dca-94c0-c09d8e36e9f4','36c07696-c330-45c8-aad9-eac9ee560cf1','S6NH00141 Chris Pappas'),
 ('c2361c82-eb6e-4733-92ce-821514279883','72828ba8-a748-4a81-80ff-774464e42640','H4CA30131 Nick Melvoin'),
 ('fd08a29c-f7da-47cb-ad43-6cb64ee5f0f1','91aa37bf-dc8a-45f3-9bf7-e887b8dd99bd','S6IA00314 Ashley Hinson'),
 ('31ff8739-26df-4915-8431-ce14a430c068','b0ef94c3-d047-4af3-907d-3d1da2b09e50','S6LA00664 Julia Letlow'),
 ('fcbe0553-e796-46b1-96cd-28f17c03009d','96e589b9-d04a-4749-bf9f-9b66eaea5083','S6OK04247 Kevin Hern'),
 ('c7af98d8-e52d-41e1-b611-48ba7d242599','ea4cb6d8-76aa-47f4-a064-babaac0bc436','S6AL00476 Barry Moore'),
 ('7b2a93ea-382a-40ce-ba18-532bf636712c','184a7967-0eaf-4ee1-993e-f37c0773a976','H6CA34278 Loren Colin');

-- Every target must exist, or the repoint would simply re-orphan the row.
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing
  FROM _fec_repoint r
  WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = r.new_pol);
  IF missing <> 0 THEN
    RAISE EXCEPTION 'aborting: % FEC repoint targets do not exist', missing;
  END IF;
END $$;

-- Record the deleted id in notes before overwriting it: the old value is the
-- only forensic trace of which politician record was removed.
UPDATE transparent_motivations.politician_sources ps
SET essentials_politician_id = r.new_pol,
    notes = nullif(trim(coalesce(ps.notes, '')), '')
            || CASE WHEN nullif(trim(coalesce(ps.notes, '')), '') IS NULL THEN '' ELSE ' | ' END
            || 'mig 1668: repointed from deleted politician ' || ps.essentials_politician_id
            || ' (FEC id verified via api.open.fec.gov)',
    updated_at = now()
FROM _fec_repoint r
WHERE ps.id = r.source_id;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
  FROM transparent_motivations.politician_sources ps
  JOIN _fec_repoint r ON r.source_id = ps.id AND r.new_pol = ps.essentials_politician_id;
  IF n <> 13 THEN RAISE EXCEPTION 'aborting: expected 13 FEC repoints, got %', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Local sources whose committee names carry the politician's FULL name
--    (first AND last) -- the one bucket the surname-substring defect cannot
--    produce. 14 rows across four people.
--      Scott Schmerelson  "Scott Schmerelson for School Board 2024-General"
--      Kelly Gonez        "Kelly Gonez for School Board 2026"
--      Dr. Rocio Rivas    "Dr Rocio Rivas for School Board 2026"
--      Nick Melvoin       "MELVOIN FOR SCHOOL BOARD 2017/2022/2026; NICK"
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE _local_repoint (gone uuid, new_pol uuid, who text, expect int) ON COMMIT DROP;
INSERT INTO _local_repoint VALUES
 ('ba333bf5-bba4-4c9c-9791-4a603d1a4d0a','fcafc695-2a41-41c0-831d-da28c5bf3c9e','Scott Schmerelson', 4),
 ('5bf68f9c-0c4c-4315-a51c-54586997aa1f','48f9dd33-0c21-4c49-a128-90dc8736bcef','Kelly Gonez',       5),
 ('b2cb156d-7322-470d-9f82-6f08e18991e8','aefa83dc-6bd7-49fd-a759-2187a94ac0db','Dr. Rocio Rivas',   1),
 ('3c29ed93-ba65-468d-b310-448134890d96','72828ba8-a748-4a81-80ff-774464e42640','Nick Melvoin',      4);

DO $$
DECLARE bad text;
BEGIN
  -- targets exist, and the row count under each deleted id is what was audited
  SELECT string_agg(l.who || ' (target missing)', ', ') INTO bad
  FROM _local_repoint l WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = l.new_pol);
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'aborting: %', bad; END IF;

  SELECT string_agg(l.who || ' expected ' || l.expect || ' rows, found ' || c.n, ', ') INTO bad
  FROM _local_repoint l
  JOIN LATERAL (SELECT count(*) AS n FROM transparent_motivations.politician_sources ps
                WHERE ps.essentials_politician_id = l.gone) c ON true
  WHERE c.n <> l.expect;
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'aborting: %', bad; END IF;
END $$;

UPDATE transparent_motivations.politician_sources ps
SET essentials_politician_id = l.new_pol,
    notes = nullif(trim(coalesce(ps.notes, '')), '')
            || CASE WHEN nullif(trim(coalesce(ps.notes, '')), '') IS NULL THEN '' ELSE ' | ' END
            || 'mig 1668: repointed from deleted politician ' || ps.essentials_politician_id
            || ' (committee name carries full given + family name)',
    updated_at = now()
FROM _local_repoint l
WHERE ps.essentials_politician_id = l.gone;

-- ---------------------------------------------------------------------------
-- 3. Katherine Lee -- "LEE FOR CITY COUNCIL 2018/2022; KATHERINE", 0
--    contributions. A Katherine Lee exists (Alhambra city council, LA County,
--    consistent with the seeding script) but the committee names carry no city
--    and the name is common, so the link is a LEAD, not a confirmed fact.
--    Repointed so it is not lost, demoted so nothing is asserted from it:
--    the display path requires research_status = 'confirmed'.
-- ---------------------------------------------------------------------------
UPDATE transparent_motivations.politician_sources
SET essentials_politician_id = 'f22187bb-dc57-4088-bb19-8bc39bcb95c9',
    research_status = 'needs_research',
    notes = coalesce(notes, '')
            || ' | mig 1668: repointed from deleted politician 22466ac0-0239-4dcb-80f2-26c5ff0e5f18 '
            || 'to Katherine Lee (Alhambra) -- UNVERIFIED name-only match, demoted from confirmed',
    updated_at = now()
WHERE essentials_politician_id = '22466ac0-0239-4dcb-80f2-26c5ff0e5f18';

-- ---------------------------------------------------------------------------
-- 4. Delete the 20 defective rows. All carry ZERO contributions.
--
--    18 of them sat on one deleted "Colin" record and are the surname/given-name
--    SUBSTRING defect again: every cal_access committee containing the string
--    COLIN was attached to it, and they belong to fourteen different people --
--    Colin J. Kooyunjian (Fresno DA), Jonathan Colin, Enrique Colin, Paul Colin,
--    Kate Colin (San Rafael), Colin Gallagher, Colin Clements, Colin Braudrick,
--    Colin Mc Carthy, Colin Fernie, Colin Walch, Colin Medalie, Colin Parent,
--    Steve Colin. Not one of them is Loren Colin, the FEC candidate whose row
--    also hung off that record (repointed in step 1).
--
--    The other 2 are already-superseded relink-socrata-skipped.ts rows marked
--    not_applicable: "Lewis for City Council District 9 2013" and a Mazariegos
--    duplicate whose live counterpart already exists on the real politician.
-- ---------------------------------------------------------------------------
-- The ids are spelled out as literals rather than collected into a temp table.
-- A freshly created temp table has no statistics, so the planner ignores
-- idx_transparent_motivations_contributions_politician_source_id and
-- seq-scans the multi-GB contributions table; the first attempt at this
-- migration died on statement_timeout inside the safety check below for
-- exactly that reason. Literal ids let the index drive it.
DO $$
DECLARE n int; carrying int;
BEGIN
  -- The population must be the 20 rows that were audited, no more, no less.
  SELECT count(*) INTO n
  FROM transparent_motivations.politician_sources
  WHERE id IN (
    'efa61e03-e010-4e86-be02-bb27d09bfb98','b6324d0f-3961-4351-a5a8-43cd2f59d18d',
    '92eacb17-8ad4-422e-8a3f-fd6edee75412','6d12d042-eb5b-4f02-9d30-bc5119b0be61',
    '5065faf2-4cd3-4cf4-b3bd-9bbdad1b71c8','e54c2cca-6e4b-4c97-b248-f717bc7641db',
    '41714d16-93bc-4487-95f8-b70e82fbacc3','bc7c53d2-5ebf-4df3-bb19-d5dec3a5e70d',
    '35660764-10c5-4a5a-a157-2be632a73d87','164e9091-7211-4606-89d8-cf2bcb2d9e3b',
    '7b48a829-926e-4ce9-8624-083c4ed2e3ba','6b606a4a-67e9-4bcd-870c-16d789f946f4',
    '63a462cd-95da-4808-ad14-1277dace2655','5576f1ac-48f2-4ae7-ae03-ccd90ec9fc58',
    'deb874f1-ed74-4146-8821-f8bf833a1fb9','1aa1e096-034e-4ad9-92a6-e6f1cd13239e',
    'e3f16178-d08e-4a2f-8cb5-fcc60bcb3120','12e88847-43eb-4631-adf3-7c14453c3736',
    '74665e25-d936-4fbb-bfd1-f137e51ad058','25074afc-3c84-418b-bdc5-d859e9ae16d6');
  IF n <> 20 THEN RAISE EXCEPTION 'aborting: expected 20 rows to delete, got %', n; END IF;

  -- Never delete a source that still carries data.
  SELECT count(*) INTO carrying
  FROM transparent_motivations.contributions
  WHERE politician_source_id IN (
    'efa61e03-e010-4e86-be02-bb27d09bfb98','b6324d0f-3961-4351-a5a8-43cd2f59d18d',
    '92eacb17-8ad4-422e-8a3f-fd6edee75412','6d12d042-eb5b-4f02-9d30-bc5119b0be61',
    '5065faf2-4cd3-4cf4-b3bd-9bbdad1b71c8','e54c2cca-6e4b-4c97-b248-f717bc7641db',
    '41714d16-93bc-4487-95f8-b70e82fbacc3','bc7c53d2-5ebf-4df3-bb19-d5dec3a5e70d',
    '35660764-10c5-4a5a-a157-2be632a73d87','164e9091-7211-4606-89d8-cf2bcb2d9e3b',
    '7b48a829-926e-4ce9-8624-083c4ed2e3ba','6b606a4a-67e9-4bcd-870c-16d789f946f4',
    '63a462cd-95da-4808-ad14-1277dace2655','5576f1ac-48f2-4ae7-ae03-ccd90ec9fc58',
    'deb874f1-ed74-4146-8821-f8bf833a1fb9','1aa1e096-034e-4ad9-92a6-e6f1cd13239e',
    'e3f16178-d08e-4a2f-8cb5-fcc60bcb3120','12e88847-43eb-4631-adf3-7c14453c3736',
    '74665e25-d936-4fbb-bfd1-f137e51ad058','25074afc-3c84-418b-bdc5-d859e9ae16d6');
  IF carrying <> 0 THEN
    RAISE EXCEPTION 'aborting: % contributions still attached to rows queued for deletion', carrying;
  END IF;
END $$;

-- contribution_summary_agg is a real TABLE keyed by politician_source_id, not a
-- view; it has to be cleared explicitly or the UI keeps showing money whose
-- contributions are gone.
DELETE FROM transparent_motivations.contribution_summary_agg
WHERE politician_source_id IN (
  'efa61e03-e010-4e86-be02-bb27d09bfb98','b6324d0f-3961-4351-a5a8-43cd2f59d18d',
  '92eacb17-8ad4-422e-8a3f-fd6edee75412','6d12d042-eb5b-4f02-9d30-bc5119b0be61',
  '5065faf2-4cd3-4cf4-b3bd-9bbdad1b71c8','e54c2cca-6e4b-4c97-b248-f717bc7641db',
  '41714d16-93bc-4487-95f8-b70e82fbacc3','bc7c53d2-5ebf-4df3-bb19-d5dec3a5e70d',
  '35660764-10c5-4a5a-a157-2be632a73d87','164e9091-7211-4606-89d8-cf2bcb2d9e3b',
  '7b48a829-926e-4ce9-8624-083c4ed2e3ba','6b606a4a-67e9-4bcd-870c-16d789f946f4',
  '63a462cd-95da-4808-ad14-1277dace2655','5576f1ac-48f2-4ae7-ae03-ccd90ec9fc58',
  'deb874f1-ed74-4146-8821-f8bf833a1fb9','1aa1e096-034e-4ad9-92a6-e6f1cd13239e',
  'e3f16178-d08e-4a2f-8cb5-fcc60bcb3120','12e88847-43eb-4631-adf3-7c14453c3736',
  '74665e25-d936-4fbb-bfd1-f137e51ad058','25074afc-3c84-418b-bdc5-d859e9ae16d6');

DELETE FROM transparent_motivations.ingestion_runs
WHERE politician_source_id IN (
  'efa61e03-e010-4e86-be02-bb27d09bfb98','b6324d0f-3961-4351-a5a8-43cd2f59d18d',
  '92eacb17-8ad4-422e-8a3f-fd6edee75412','6d12d042-eb5b-4f02-9d30-bc5119b0be61',
  '5065faf2-4cd3-4cf4-b3bd-9bbdad1b71c8','e54c2cca-6e4b-4c97-b248-f717bc7641db',
  '41714d16-93bc-4487-95f8-b70e82fbacc3','bc7c53d2-5ebf-4df3-bb19-d5dec3a5e70d',
  '35660764-10c5-4a5a-a157-2be632a73d87','164e9091-7211-4606-89d8-cf2bcb2d9e3b',
  '7b48a829-926e-4ce9-8624-083c4ed2e3ba','6b606a4a-67e9-4bcd-870c-16d789f946f4',
  '63a462cd-95da-4808-ad14-1277dace2655','5576f1ac-48f2-4ae7-ae03-ccd90ec9fc58',
  'deb874f1-ed74-4146-8821-f8bf833a1fb9','1aa1e096-034e-4ad9-92a6-e6f1cd13239e',
  'e3f16178-d08e-4a2f-8cb5-fcc60bcb3120','12e88847-43eb-4631-adf3-7c14453c3736',
  '74665e25-d936-4fbb-bfd1-f137e51ad058','25074afc-3c84-418b-bdc5-d859e9ae16d6');

DELETE FROM transparent_motivations.fec_ingest_window_progress
WHERE politician_source_id IN (
  'efa61e03-e010-4e86-be02-bb27d09bfb98','b6324d0f-3961-4351-a5a8-43cd2f59d18d',
  '92eacb17-8ad4-422e-8a3f-fd6edee75412','6d12d042-eb5b-4f02-9d30-bc5119b0be61',
  '5065faf2-4cd3-4cf4-b3bd-9bbdad1b71c8','e54c2cca-6e4b-4c97-b248-f717bc7641db',
  '41714d16-93bc-4487-95f8-b70e82fbacc3','bc7c53d2-5ebf-4df3-bb19-d5dec3a5e70d',
  '35660764-10c5-4a5a-a157-2be632a73d87','164e9091-7211-4606-89d8-cf2bcb2d9e3b',
  '7b48a829-926e-4ce9-8624-083c4ed2e3ba','6b606a4a-67e9-4bcd-870c-16d789f946f4',
  '63a462cd-95da-4808-ad14-1277dace2655','5576f1ac-48f2-4ae7-ae03-ccd90ec9fc58',
  'deb874f1-ed74-4146-8821-f8bf833a1fb9','1aa1e096-034e-4ad9-92a6-e6f1cd13239e',
  'e3f16178-d08e-4a2f-8cb5-fcc60bcb3120','12e88847-43eb-4631-adf3-7c14453c3736',
  '74665e25-d936-4fbb-bfd1-f137e51ad058','25074afc-3c84-418b-bdc5-d859e9ae16d6');

DELETE FROM transparent_motivations.committees
WHERE politician_source_id IN (
  'efa61e03-e010-4e86-be02-bb27d09bfb98','b6324d0f-3961-4351-a5a8-43cd2f59d18d',
  '92eacb17-8ad4-422e-8a3f-fd6edee75412','6d12d042-eb5b-4f02-9d30-bc5119b0be61',
  '5065faf2-4cd3-4cf4-b3bd-9bbdad1b71c8','e54c2cca-6e4b-4c97-b248-f717bc7641db',
  '41714d16-93bc-4487-95f8-b70e82fbacc3','bc7c53d2-5ebf-4df3-bb19-d5dec3a5e70d',
  '35660764-10c5-4a5a-a157-2be632a73d87','164e9091-7211-4606-89d8-cf2bcb2d9e3b',
  '7b48a829-926e-4ce9-8624-083c4ed2e3ba','6b606a4a-67e9-4bcd-870c-16d789f946f4',
  '63a462cd-95da-4808-ad14-1277dace2655','5576f1ac-48f2-4ae7-ae03-ccd90ec9fc58',
  'deb874f1-ed74-4146-8821-f8bf833a1fb9','1aa1e096-034e-4ad9-92a6-e6f1cd13239e',
  'e3f16178-d08e-4a2f-8cb5-fcc60bcb3120','12e88847-43eb-4631-adf3-7c14453c3736',
  '74665e25-d936-4fbb-bfd1-f137e51ad058','25074afc-3c84-418b-bdc5-d859e9ae16d6');

DELETE FROM transparent_motivations.politician_sources
WHERE id IN (
  'efa61e03-e010-4e86-be02-bb27d09bfb98','b6324d0f-3961-4351-a5a8-43cd2f59d18d',
  '92eacb17-8ad4-422e-8a3f-fd6edee75412','6d12d042-eb5b-4f02-9d30-bc5119b0be61',
  '5065faf2-4cd3-4cf4-b3bd-9bbdad1b71c8','e54c2cca-6e4b-4c97-b248-f717bc7641db',
  '41714d16-93bc-4487-95f8-b70e82fbacc3','bc7c53d2-5ebf-4df3-bb19-d5dec3a5e70d',
  '35660764-10c5-4a5a-a157-2be632a73d87','164e9091-7211-4606-89d8-cf2bcb2d9e3b',
  '7b48a829-926e-4ce9-8624-083c4ed2e3ba','6b606a4a-67e9-4bcd-870c-16d789f946f4',
  '63a462cd-95da-4808-ad14-1277dace2655','5576f1ac-48f2-4ae7-ae03-ccd90ec9fc58',
  'deb874f1-ed74-4146-8821-f8bf833a1fb9','1aa1e096-034e-4ad9-92a6-e6f1cd13239e',
  'e3f16178-d08e-4a2f-8cb5-fcc60bcb3120','12e88847-43eb-4631-adf3-7c14453c3736',
  '74665e25-d936-4fbb-bfd1-f137e51ad058','25074afc-3c84-418b-bdc5-d859e9ae16d6');

-- ---------------------------------------------------------------------------
-- 5. Nothing may remain orphaned -- the FK below cannot be added otherwise, and
--    a bare "constraint failed" would not say which rows were missed.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
  FROM transparent_motivations.politician_sources ps
  LEFT JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
  WHERE ps.essentials_politician_id IS NOT NULL AND p.id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'aborting: % orphaned politician_sources remain', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 6. The structural fix. Deleting a politician who still has finance sources
--    now fails loudly instead of silently stranding their contributions.
--    Merge/cleanup scripts must detach or delete the sources first.
-- ---------------------------------------------------------------------------
ALTER TABLE transparent_motivations.politician_sources
  ADD CONSTRAINT politician_sources_essentials_politician_id_fkey
  FOREIGN KEY (essentials_politician_id)
  REFERENCES essentials.politicians (id)
  ON DELETE RESTRICT;

COMMIT;
