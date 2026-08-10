-- Migration 1664: purge the contributions ingested through relink-socrata-skipped.ts
--                 surname-substring mislinks
--
-- ============================================================================
-- THE DEFECT
-- ============================================================================
-- backend/scripts/relink-socrata-skipped.ts matched politicians to LA Socrata committees
-- with, in full:
--
--     const matches = normalizedCommittees.filter(c =>
--       c.normalized_nm.includes(normalizedLastName)
--     );
--
-- That is not surname matching. It is SUBSTRING CONTAINMENT of the surname anywhere in
-- the committee name, and any politician with exactly one such hit was linked
-- automatically. Two failure modes, both live in production:
--
--   1. The surname appears INSIDE AN UNRELATED WORD:
--        Derek Tran, Tim Tran  -> "Angelenos for Safe TRANsportation PAC"
--        Andrew E. Cooper      -> "South Bay COOPERative, Inc."
--        Cheryl Cox            -> "Rob WilCOX for Controller 2022"
--        Megan Ngo, Vinh Ngo   -> "LoviNGOod for City Council 2020"
--        Polly Low, Ruth Low   -> "WinsLOW City Council 2015"
--        Lorene Reed           -> "CREED for Council 2017"
--        Randell Herr          -> "SHERRi Onica Valle Cole for City Attorney 2022"
--
--   2. A DIFFERENT PERSON WHO SHARES THE SURNAME. Worse, "exactly one match" is counted
--      per POLITICIAN, so several people sharing a surname all get linked to the SAME
--      committee — a candidate committee that can only belong to one of them:
--        Fred Flores committee   -> 5 politicians (Anastasia, Arturo, Francis, Jaime, Xochitl)
--        Walter Moore committee  -> 5 politicians (Cherise, James, Laquita, Lorraine, Suzy)
--        Olga Ayala committee    -> 4 politicians
--        Eduardo Cisneros/LAUSD  -> Gil Cisneros and Ramiro P. Cisneros (found in mig 1661)
--      28 committees are linked to 2+ politicians; one to seven.
--
-- The script inserts research_status='needs_research' and its own header says "operator
-- must confirm before ingestion runs". Something later bulk-confirmed them: 127 of the
-- 128 rows were 'confirmed'. Ingestion then ran — 1,069 completed ingestion_runs across
-- 124 sources — pulling 12,466 contributions worth $6,552,730.77 onto the wrong people.
--
-- ============================================================================
-- CLASSIFICATION AND SCOPE (operator decision: purge A+B+C, keep D)
-- ============================================================================
--   A  surname inside another word     28 src   5,544 contrib  $3,318,077   PURGE
--   B  committee names a DIFFERENT     50 src   2,673 contrib  $1,300,814   PURGE
--      given name before the surname
--   C  committee carries no given name 46 src   2,839 contrib  $1,303,711   PURGE
--      ("SMITH FOR COUNCIL") — unverifiable from the name alone, and 29 of the 46
--      sit on a committee shared with another politician, so most cannot be right
--   D  committee carries the politician's own first name   2 src  645 contrib  $488,480  KEEP
--        Michael R. Amerian -> "Michael Amerian for City Attorney 2009"
--        David A. Berger    -> "Committee to Elect David Berger"
--      Both are the sole politician on their committee.
--
-- C is purged rather than left because these links were never operator-confirmed —
-- ingestion was never authorised for them — and attributing $1.3M through an unverified
-- surname-only match is worse than showing nothing. The data is recoverable: re-ingest
-- if and when a link is genuinely confirmed. ingestion_runs are deleted for the purged
-- sources precisely so a future confirmed link is not skipped as already-ingested.
--
-- 🔑 NOTE the detector that did NOT work: "committee name lacks the politician's first
-- name" fires on 124 of 126 rows, because LA committee names are usually just
-- "SMITH FOR CITY COUNCIL 2020". Useless as a discriminator. What distinguishes the
-- defect is the surname sitting inside another word, or a DIFFERENT given name standing
-- immediately before the surname.
--
-- Link states after this migration:
--   A, B -> not_applicable  (demonstrably wrong)
--   C    -> needs_research  (unverified; back to what the script actually wrote)
--   D    -> confirmed       (unchanged)
--
-- No FK references transparent_motivations.contributions, ingestion_runs or
-- politician_sources, so these deletes are unconstrained.
-- contribution_summary_agg is a real TABLE keyed by politician_source_id, not a view —
-- it must be deleted explicitly or the summary card keeps showing money whose
-- contributions are gone (113 agg rows exist for these sources).

BEGIN;

-- ---------------------------------------------------------------------------
-- Classify every row this script created, exactly as audited.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE relink_classified ON COMMIT DROP AS
WITH rows AS (
  SELECT ps.id, ps.external_id, ps.essentials_politician_id AS pid,
         lower(coalesce(NULLIF(p.last_name,''), split_part(p.full_name,' ',-1)))  AS ln,
         lower(coalesce(NULLIF(p.first_name,''), split_part(p.full_name,' ',1))) AS fn,
         substring(ps.notes from '"cmt_nm":"([^"]*)"') AS cmt
  FROM transparent_motivations.politician_sources ps
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
  WHERE ps.source_system = 'la_socrata'
    AND ps.notes LIKE '{%relink-socrata-skipped.ts%'
)
SELECT id, external_id, pid,
  CASE
    WHEN cmt IS NULL                              THEN 'C'
    WHEN NOT (lower(cmt) ~ ('\m'||ln||'\M'))      THEN 'A'
    WHEN lower(cmt) LIKE '%'||fn||'%'             THEN 'D'
    WHEN coalesce((regexp_match(lower(cmt), '([a-z]+)\s+'||ln||'\M'))[1],'')
         IN ('','elect','reelect','re','for','of','friends','committee','the','to',
             'support','citizens','a','de')       THEN 'C'
    ELSE 'B'
  END AS bucket
FROM rows;

-- ---------------------------------------------------------------------------
-- 1. Drop the denormalized aggregate rows first (they are what the UI reads).
-- ---------------------------------------------------------------------------
DELETE FROM transparent_motivations.contribution_summary_agg a
USING relink_classified r
WHERE a.politician_source_id = r.id AND r.bucket IN ('A','B','C');

-- ---------------------------------------------------------------------------
-- 2. Drop the misattributed contributions.
-- ---------------------------------------------------------------------------
DELETE FROM transparent_motivations.contributions c
USING relink_classified r
WHERE c.politician_source_id = r.id AND r.bucket IN ('A','B','C');

-- ---------------------------------------------------------------------------
-- 3. Drop the ingestion history for the purged sources, so that a link which is
--    later genuinely confirmed is not skipped as already-ingested.
-- ---------------------------------------------------------------------------
DELETE FROM transparent_motivations.ingestion_runs ir
USING relink_classified r
WHERE ir.politician_source_id = r.id AND r.bucket IN ('A','B','C');

-- ---------------------------------------------------------------------------
-- 4. Retire the demonstrably wrong links.
-- ---------------------------------------------------------------------------
UPDATE transparent_motivations.politician_sources ps
SET research_status = 'not_applicable',
    notes = coalesce(ps.notes,'') || ' | sweep 1664: WRONG LINK — relink-socrata-skipped.ts'
            || ' matched the surname as a SUBSTRING of the committee name. Contributions,'
            || ' aggregate and ingestion history purged.',
    updated_at = now()
FROM relink_classified r
WHERE ps.id = r.id AND r.bucket IN ('A','B')
  AND ps.research_status <> 'not_applicable';

-- ---------------------------------------------------------------------------
-- 5. Demote the unverifiable links to the status the script actually wrote.
-- ---------------------------------------------------------------------------
UPDATE transparent_motivations.politician_sources ps
SET research_status = 'needs_research',
    notes = coalesce(ps.notes,'') || ' | sweep 1664: UNVERIFIED — surname-only match with'
            || ' no given name in the committee name; auto-confirmed without operator'
            || ' review. Contributions, aggregate and ingestion history purged pending'
            || ' genuine confirmation.',
    updated_at = now()
FROM relink_classified r
WHERE ps.id = r.id AND r.bucket = 'C';

COMMIT;
