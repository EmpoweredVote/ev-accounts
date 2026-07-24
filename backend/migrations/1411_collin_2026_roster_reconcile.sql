-- =============================================================================
-- Migration 1411: Collin County 2025/2026 municipal-election roster reconcile
-- (Phase 220 follow-up — operator-approved 2026-07-24)
--
-- The May 2, 2026 (and Frisco's June 13, 2026 mayoral runoff) elections were not
-- fully reflected in production. Phase 219 INSERTED several 2026 winners as active
-- politician rows with office_id set, but never repointed offices.politician_id nor
-- retired the prior incumbents — a "half-seated" state. Plus several re-elected/
-- continuing incumbents carry a stale valid_to. This migration reconciles 16 seats
-- from AUTHORITATIVE, cited sources (RECONCILE-RESEARCH.md; combined multi-county
-- canvass only, per the mig-1404 lesson). Idempotent throughout.
--
-- PART A — 6 half-seated winners: repoint office → winner (already active w/ office_id),
--          detach old inactive holder, set winner term + sourced contact method.
-- PART B — Frisco Mayor: Cheney termed out; Mark Hill won the June-13-2026 runoff
--          (58.12%, combined-county). The existing "Mark Hill" row is the FISD SCHOOL
--          BOARD member (different office) — do NOT reuse it; INSERT a new Mayor row.
-- PART C — 9 valid_to corrections for continuing/re-elected incumbents (Nevada &
--          Fairview use 2-YEAR terms → 2027; others 3-year → 2029).
-- NOT INCLUDED — Plano "Place 6" (research indicates it is the Mayor's own place
--          designation, not a separate seat; MEDIUM confidence, held for human verify).
--          Murphy Ison/Kelley emails: none published (GAP) → web_form_url only.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- PART A — reseat the 6 half-seated winners
-- Each: (office_id, winner_id, old_holder_id, valid_from, valid_to, email_or_null)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
  v_prosper_form TEXT;
  v_murphy_form  TEXT;
BEGIN
  -- Copy the city-wide form URLs already seeded by mig 1405 (guarantees exact match).
  SELECT p.web_form_url INTO v_prosper_form
    FROM essentials.politicians p JOIN essentials.offices o ON o.id=p.office_id
    JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id
   WHERE g.geo_id='4859696' AND p.web_form_url IS NOT NULL LIMIT 1;
  SELECT p.web_form_url INTO v_murphy_form
    FROM essentials.politicians p JOIN essentials.offices o ON o.id=p.office_id
    JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id
   WHERE g.geo_id='4850100' AND p.web_form_url IS NOT NULL LIMIT 1;

  FOR r IN
    SELECT * FROM (VALUES
      -- office_id,                              winner_id,                            old_holder_id,                        vfrom,        vto,          email,                        form
      ('98ca5ec3-7f1a-42c4-8a02-56d32b68ceb4','91128e4f-94f6-4119-8087-4449ee16964a','04d861e1-8fe2-440b-9332-9382f72e70dd','2026-05-01','2029-05-01','sbscott@celina-tx.gov',      NULL),        -- Celina P4  Shea Scott
      ('09ece103-8350-4e35-861b-118c2b02d985','2e8dc841-f8ea-42f0-b6a4-08e9c779a20e','930b565d-a397-41f5-b03d-0cdebc0e439a','2026-05-01','2029-05-01','rlambert@celina-tx.gov',     NULL),        -- Celina P5  Shane Lambert
      ('8f89f8bb-b2d6-4887-a7af-de437a990b9c','ddcb2d35-0f94-4956-ab65-ae56a900ac11','b39524df-ef91-48dc-a1a8-1880c271bd7c','2026-05-01','2029-05-01','bcolberg@friscotexas.gov',   NULL),        -- Frisco P6  Brittany Colberg
      ('cd6919fe-2792-433e-8a3e-44f56878b89e','bb9bed2f-cf0c-4997-9676-e5314ee1d7e0','b6cc39bb-f246-4e2b-8f90-252d907badd5','2026-05-01','2029-05-01', NULL,                        'MURPHY'),     -- Murphy P3  Debbie Ison (GAP email)
      ('d7109e9a-8147-4935-a160-7e2af7b2b2b9','4220560f-5c74-4c92-9a35-e2a7cecb69da','24d1c9c9-b496-4562-87a8-548430f26663','2026-05-01','2029-05-01', NULL,                        'MURPHY'),     -- Murphy P5  Kevin Kelley (GAP email)
      ('2b5e76a8-4152-4f97-a918-a18c99ddf478','48500428-3421-4298-b618-613696ca644c','c5396e9d-1a97-40ac-a877-4b6512934099','2026-05-01','2029-05-01','dcharles@prospertx.gov',     'PROSPER')    -- Prosper P5 Doug Charles
    ) AS t(office_id, winner_id, old_holder_id, vfrom, vto, email, form)
  LOOP
    -- Repoint office → winner (guarded: only if still pointing at the old holder).
    UPDATE essentials.offices
       SET politician_id = r.winner_id::uuid
     WHERE id = r.office_id::uuid AND politician_id = r.old_holder_id::uuid;

    -- Detach the old holder (already inactive; clear dangling office_id, stamp term end).
    UPDATE essentials.politicians
       SET is_active = false, is_incumbent = false, office_id = NULL,
           valid_to = COALESCE(valid_to,'2026-05-01'), term_date_precision = COALESCE(term_date_precision,'month')
     WHERE id = r.old_holder_id::uuid;

    -- Set the winner's term (guarded IS NULL so re-run is net-zero).
    UPDATE essentials.politicians
       SET valid_from = COALESCE(valid_from, r.vfrom),
           valid_to   = COALESCE(valid_to,   r.vto),
           term_date_precision = COALESCE(term_date_precision, 'month')
     WHERE id = r.winner_id::uuid;

    -- Seed sourced email (idempotent) where published.
    IF r.email IS NOT NULL THEN
      UPDATE essentials.politicians
         SET email_addresses = ARRAY[r.email]
       WHERE id = r.winner_id::uuid
         AND (email_addresses IS NULL OR NOT (r.email = ANY(email_addresses)));
    END IF;

    -- Seed city-wide web_form_url for form-cities (Prosper, Murphy).
    IF r.form = 'PROSPER' AND v_prosper_form IS NOT NULL THEN
      UPDATE essentials.politicians SET web_form_url = v_prosper_form
       WHERE id = r.winner_id::uuid AND web_form_url IS NULL;
    ELSIF r.form = 'MURPHY' AND v_murphy_form IS NOT NULL THEN
      UPDATE essentials.politicians SET web_form_url = v_murphy_form
       WHERE id = r.winner_id::uuid AND web_form_url IS NULL;
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- PART B — Frisco Mayor: insert Mark Hill (Mayor), repoint office, retire Cheney.
-- Office 2087a453 = Frisco Mayor; Cheney = ac1ed3c9. Existing "Mark Hill" row
-- (4612462c) is the FISD board member — NOT reused.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id  UUID := '2087a453-d1c4-47ab-904d-13ca58118fd1';
  v_cheney_id  UUID := 'ac1ed3c9-db6c-4931-bc55-4d53c6c81b35';
  v_holder     TEXT;
  v_hill_id    UUID;
BEGIN
  SELECT p.full_name INTO v_holder
    FROM essentials.offices o LEFT JOIN essentials.politicians p ON p.id=o.politician_id
   WHERE o.id = v_office_id;

  IF v_holder = 'Mark Hill' THEN
    RAISE NOTICE 'Migration 1411: Frisco Mayor already Mark Hill — skipping';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name, party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Mark','Hill','Mark','Mark Hill', NULL, NULL,
      true, false, false, false,
      v_office_id, '2026-07-07', '2029-05-01', 'month',
      ARRAY['mhill@friscotexas.gov'],
      ARRAY['https://www.friscotexas.gov/2054/Mayor-Mark-Hill'],
      'friscotexas.gov/2054/Mayor-Mark-Hill + WFAA/CommunityImpact June-13-2026 runoff COMBINED (Hill 58.12% def Vilhauer); Phase 220 roster reconcile'
    ) RETURNING id INTO v_hill_id;

    UPDATE essentials.offices SET politician_id = v_hill_id WHERE id = v_office_id;

    UPDATE essentials.politicians
       SET is_active = false, is_incumbent = false, office_id = NULL,
           valid_to = '2026-07-07', term_date_precision = 'day'
     WHERE id = v_cheney_id;

    RAISE NOTICE 'Migration 1411: seated Mark Hill (%) as Frisco Mayor, retired Jeff Cheney', v_hill_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- PART C — 9 valid_to corrections for continuing/re-elected incumbents.
-- Nevada + Fairview = 2-year terms → 2027; Allen/Celina/Frisco/Murphy/Prosper = 3-year → 2029.
-- Guarded on the stale value so re-run is net-zero.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians SET valid_to='2029-05-01', term_date_precision='month'
 WHERE id IN (
   '3b15d821-fc1e-4e7b-bda0-13a669a77a27', -- Allen P2 Tommy Baril
   'cb9d6924-77d1-49c9-ab3d-778b0201e623', -- Celina Mayor Ryan Tubbs
   '76c3fa35-a286-4fa1-b6da-40300d91f33e', -- Frisco P5 Laura Rummel
   'e8841ac4-bcae-4783-b24a-e6fb82f46da7', -- Murphy Mayor Scott Bradley
   '3631dd31-cb1a-46e1-ae2d-da54ea911411'  -- Prosper P3 Amy Bartley
 ) AND valid_to = '2026-05-01';

UPDATE essentials.politicians SET valid_to='2027-05-01', term_date_precision='month'
 WHERE id IN (
   'c41886b8-f4ad-4f06-a579-5140c8951c91', -- Nevada P3 Amanda Wilson (2-yr)
   '6c1dc476-507b-43a8-9061-bdaf9eafec58', -- Nevada P4 Clayton Laughter (2-yr)
   '51c0d0db-b3e6-4e71-960e-4809ad680e25', -- Nevada P5 Derrick Little (2-yr)
   'c97ba2a3-d56e-4ecc-aa7d-c5d009c9312c'  -- Fairview Seat 3 Jill Hawkins (2-yr)
 ) AND valid_to = '2026-05-01';

COMMIT;
