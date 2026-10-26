BEGIN;

-- =============================================================================
-- CA_0326: seat Everton Blair Jr. in U.S. House GA-13 (issue #1088)
-- =============================================================================
-- Found by the ev-qa federal check (2026-10-21, again 2026-10-26): GA-13 (geo_id 1313) is missing from
-- /api/essentials/browse/federal/officials, and address search in the district returns a NATIONAL_LOWER
-- row for 1313 with an empty full_name.
--
-- Cause: the GA-13 office (0d031c4f) has NO office_terms row at all and is flagged is_vacant with no
-- vacant_since. Seeding (1129) treated the seat as a true vacancy after David Scott died, and nobody was
-- ever seated after the special election. The flag kept it out of the drift baseline; the LEFT JOIN in
-- office_current_holder rendered it as a nameless row (CLAUDE.md, "A flagged-vacant office is still
-- returned by address search").
--
-- Facts and sources (read 2026-10-26):
--   * House Clerk member list (clerk.house.gov/xml/lists/MemberData.xml, publish-date "October 1, 2026"),
--     statedistrict GA13: official-name "Everton Blair Jr.", bioguideID B001328, elected-date 20260825,
--     sworn-date 20260901; footnote "Elected August 25, 2026, to fill the vacancy due to the death of David
--     Scott, April 22, 2026."
--   * The 119th Congress ends 2027-01-03 (U.S. Const. amend. XX §1), so the unexpired term ends then.
--     Blair is not a candidate in the 2026-11-03 GA-13 race (race f8294135: Clark, Chavez).
--
-- Writes:
--   1. One new politician, Everton Blair Jr. (external_id -13013 — the GA incumbent band -13000-cd, where
--      the GA-13 slot was never used), is_incumbent true (he holds a seat). No party is stored.
--   2. seat_officeholder(GA-13, Blair, 2026-09-01, 'elected', 'day'). GA-13 has no prior term row, so
--      nothing is closed. Scott's historical term is absent from office_terms and is not added here.
--   3. term_end 2027-01-03 on that term; how_ended left NULL (it has not happened yet). The next holder's
--      seat_officeholder will trim it to the day before their start.
--   4. seat_officeholder does NOT clear the vacancy flag, so is_vacant/vacant_since are cleared here
--      explicitly (CLAUDE.md "The is_vacant trap").
--
-- offices_missing_terms moves by one FLAGGED office (the undated GA-13 flag); the 239 unflagged baseline
-- does not move.
-- Idempotent: a re-run inserts nothing, seat_officeholder returns the existing term, the UPDATEs match
-- nothing new, and the post-verify passes.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                  WHERE o.id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e'
                    AND d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '1313') THEN
    RAISE EXCEPTION 'CA_0326: pre-flight — GA-13 office 0d031c4f not found on NATIONAL_LOWER 1313';
  END IF;
  -- The only term allowed on GA-13 is Blair's own (a re-run).
  IF EXISTS (SELECT 1 FROM essentials.office_terms t
              WHERE t.office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e'
                AND t.politician_id IS DISTINCT FROM (SELECT id FROM essentials.politicians WHERE external_id = -13013)) THEN
    RAISE EXCEPTION 'CA_0326: pre-flight — GA-13 already has a term for someone else; reconcile first';
  END IF;
  -- -13013 is free, or already Blair's.
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -13013 AND bioguide_id IS DISTINCT FROM 'B001328') THEN
    RAISE EXCEPTION 'CA_0326: pre-flight — external_id -13013 is held by someone else';
  END IF;
  -- No second Blair row under another id (bioguide is the House's own key).
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE bioguide_id = 'B001328' AND external_id IS DISTINCT FROM -13013) THEN
    RAISE EXCEPTION 'CA_0326: pre-flight — bioguide B001328 already exists under another external_id';
  END IF;
END $$;

-- 1. Everton Blair Jr.
INSERT INTO essentials.politicians (external_id, first_name, last_name, name_suffix, full_name, bioguide_id,
                                    is_incumbent, is_active, is_appointed, source, data_source)
SELECT -13013, 'Everton', 'Blair', 'Jr.', 'Everton Blair Jr.', 'B001328',
       true, true, false,
       'CA_0326 (2026-10-26): House Clerk MemberData.xml (publish-date October 1, 2026), GA13: Everton Blair Jr., bioguide B001328, elected 2026-08-25, sworn 2026-09-01',
       'manual'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -13013);

-- 2. Seat him in GA-13 from his swearing-in.
SELECT essentials.seat_officeholder('0d031c4f-07d4-4adb-8839-2bf25f5c533e'::uuid,
  (SELECT id FROM essentials.politicians WHERE external_id = -13013),
  DATE '2026-09-01',
  'House Clerk MemberData.xml (publish-date October 1, 2026), GA13: elected 2026-08-25 to fill the vacancy due to the death of David Scott (2026-04-22), sworn 2026-09-01; term ends with the 119th Congress 2027-01-03 (CA_0326)',
  'elected', 'day');

-- 3. The unexpired term ends with the 119th Congress.
UPDATE essentials.office_terms
   SET term_end = DATE '2027-01-03'
 WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e'
   AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -13013)
   AND term_start = DATE '2026-09-01'
   AND term_end IS NULL;

-- 4. Clear the vacancy flag.
UPDATE essentials.offices SET is_vacant = false, vacant_since = NULL
 WHERE id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND is_vacant;

DO $$
DECLARE
  v int;
  v_pid uuid;
BEGIN
  SELECT id INTO v_pid FROM essentials.politicians WHERE external_id = -13013;
  SELECT count(*) INTO v FROM essentials.politicians
   WHERE external_id = -13013 AND full_name = 'Everton Blair Jr.' AND bioguide_id = 'B001328'
     AND is_incumbent AND is_active AND party IS NULL;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0326: Blair row not as expected (found %)', v; END IF;
  -- Exactly one term on GA-13: his, 2026-09-01 .. 2027-01-03.
  SELECT count(*) INTO v FROM essentials.office_terms WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0326: GA-13 has % terms, expected 1', v; END IF;
  SELECT count(*) INTO v FROM essentials.office_terms
   WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND politician_id = v_pid
     AND term_start = DATE '2026-09-01' AND term_end = DATE '2027-01-03'
     AND start_precision = 'day' AND how_started = 'elected' AND how_ended IS NULL;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0326: Blair GA-13 term not as expected'; END IF;
  -- He is the current holder, of exactly one seat, and the seat is not flagged vacant.
  SELECT count(*) INTO v FROM essentials.office_current_holder
   WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND politician_id = v_pid;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0326: Blair is not the current GA-13 holder (found %)', v; END IF;
  SELECT count(*) INTO v FROM essentials.office_current_holder WHERE politician_id = v_pid;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0326: Blair holds % current seats, expected 1', v; END IF;
  IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND (is_vacant OR vacant_since IS NOT NULL)) THEN
    RAISE EXCEPTION 'CA_0326: GA-13 still flagged vacant';
  END IF;
END $$;

COMMIT;
