-- CC_0206 — link four CA 2026 Statewide General candidates to their politician records
--
-- Fiona Ma · Gloria Romero · Richard Barrera · Sara Hernandez.
--
-- WHAT IS WRONG. Each of these four has TWO `race_candidates` rows for the same contest: a
-- 2026-06-02 primary row (source `ca-sos-2026`, external_id `ca-sos-2026-<name>`, result
-- `advanced`) that IS linked to a politician, and a 2026-11-03 general row (imported from the
-- Secretary of State's certified list PDF on 2026-09-21, external_id NULL) that is NOT. The
-- unlinked row carries no photo, so the browse page's Elections view renders a grey initials box
-- for a candidate whose photograph we already hold and publish elsewhere on the same page.
--
-- Found while verifying CC_0205: Sara Hernandez' new headshot was live on her officeholder card
-- and absent from her election card, and the photograph was not the reason.
--
--
-- 🔴 WHY ONLY FOUR, WHEN 136 ROWS ARE UNLINKED. Measured 2026-10-08 on production: the CA 2026
-- Statewide General holds 324 candidates across 164 races, of which 188 are linked and
-- **136 are not**. Those 136 break down as:
--
--     116  no politician record exists with that first and last name at all
--      19  exactly one name match, of which 3 also have a linked earlier row for the SAME office
--       1  two name matches, and it too has a linked earlier row for the same office
--
-- So 116 of them are not a linking problem — there is nothing to link to, and creating records
-- is a different job with a different standard of evidence. Of the remaining 20, only these FOUR
-- are resolved by evidence rather than by a name. ⚠ **A SHARED FIRST AND LAST NAME IS NOT
-- IDENTITY.** What makes these four safe is that the same person already appears, linked, on the
-- PRIMARY row for the SAME OFFICE in the SAME cycle — California's top-two primary sends exactly
-- the advancing candidates to the general, and both Lieutenant Governor general rows are the two
-- who advanced. The other 16 single-name matches are leads, and are deliberately left alone.
--
--
-- 🔴 RICHARD BARRERA HAS TWO ACTIVE POLITICIAN ROWS, AND THEY ARE THE SAME MAN.
--     96485b13 — source `ballotpedia`, photo_origin_url `barreraforedu.com`, no office,
--                is_incumbent false, carries the race rows.
--     b04e1f2d — source NULL, external_id -870011, holds "Board Member (District D)" at
--                San Diego Unified School District, is_incumbent true, carries no race rows.
-- His own Superintendent campaign site states it: "In 2008, Richard Barrera was an elected
-- democrat to the Board of the San Diego Unified" and "As President of the San Diego Unified
-- School Board, Richard Barrera spent the last 20 years…". So this is a SPLIT — the seat on one
-- row, the candidacies on the other — which is real harm when it is one person.
--     ▶ This migration does NOT merge them. It links the general row to 96485b13, the row its own
--     primary row already points at and the row whose recorded provenance is his Superintendent
--     campaign site. The duplicate is recorded here as a finding for a separate pass; merging two
--     politician rows is a different job with its own blast radius.
--     ⚠ The two rows publish DIFFERENT photographs and a side-by-side does not settle them on
--     sight — one is greyer and wears glasses. The campaign site's own text is what settles it,
--     not the faces.
--
--
-- 🔴 THERE IS NO UNIQUE CONSTRAINT ON (race_id, politician_id). The database will happily seat one
-- politician twice in a race, so the post-verify gate below checks that explicitly rather than
-- trusting the schema.
--
-- Idempotent: each UPDATE is guarded on politician_id IS NULL, and a re-run verifies and changes
-- nothing. No DDL, so it applies as `ev_api` or as `postgres`.
--
-- Rollback is one UPDATE; nothing else about these rows is touched:
--   UPDATE essentials.race_candidates SET politician_id = NULL
--    WHERE id IN ('cb84de45-619a-4219-a117-9a33e9c2d0c8',   -- Fiona Ma
--                 '77ae78a8-dbdc-43be-8dcc-77e5073248d7',   -- Gloria Romero
--                 '17565373-88ac-4431-a5b1-939468890a03',   -- Richard Barrera
--                 'c7a5fca4-3c81-4f63-98ec-0ffe9038e972');  -- Sara Hernandez

BEGIN;

DO $$
DECLARE
  r          record;
  n_seen     int := 0;
  n_ok       int := 0;
  v_pid      uuid;
  v_dupes    int;
  v_race     uuid;
BEGIN
  FOR r IN
    SELECT b.rc_id::uuid       AS rc_id,
           b.politician_id::uuid AS politician_id,
           b.nm, b.office,
           b.primary_rc_id::uuid AS primary_rc_id,
           rc.politician_id    AS current_link,
           rc.full_name        AS rc_name,
           rc.race_id          AS race_id,
           rc.candidate_status AS status,
           e.name              AS election_name,
           rr.position_name    AS position_name
      FROM (VALUES
        -- general row                             politician row                          name                      office                                    its own linked primary row
        ('cb84de45-619a-4219-a117-9a33e9c2d0c8', '41ef8aaa-b604-4725-b46d-dab1656cc198', 'Fiona Ma',              'Lieutenant Governor',                   'e134566b-9779-4979-9c9d-2ecb43637f45'),
        ('77ae78a8-dbdc-43be-8dcc-77e5073248d7', 'f8189ff3-311b-4c91-b61b-a8b54f569a68', 'Gloria Romero',         'Lieutenant Governor',                   '6de587b4-fc3f-4920-a76c-5eb357e95282'),
        ('17565373-88ac-4431-a5b1-939468890a03', '96485b13-9104-4057-99de-742df6df85ee', 'Richard Barrera',       'Superintendent of Public Instruction',  '3ddafab8-4d1c-4a32-81e5-c60d2557527c'),
        ('c7a5fca4-3c81-4f63-98ec-0ffe9038e972', '3ce8b7fa-a703-45be-9e07-71b1a8ebfa8d', 'Sara Hernandez',        'State Senate District 26',              '240be7d9-2c5a-40de-9448-514f740999a7')
      ) AS b(rc_id, politician_id, nm, office, primary_rc_id)
      JOIN essentials.race_candidates rc ON rc.id = b.rc_id::uuid
      JOIN essentials.races rr           ON rr.id = rc.race_id
      JOIN essentials.elections e        ON e.id = rr.election_id
  LOOP
    n_seen := n_seen + 1;

    -- ----------------------------------------------------------- preconditions
    IF r.rc_name IS DISTINCT FROM r.nm THEN
      RAISE EXCEPTION 'CC_0206: race_candidate % is named "%", expected "%" — refusing to touch the wrong row',
        r.rc_id, r.rc_name, r.nm;
    END IF;
    IF r.election_name <> 'CA 2026 Statewide General' THEN
      RAISE EXCEPTION 'CC_0206: % sits in election "%", expected the CA 2026 Statewide General',
        r.nm, r.election_name;
    END IF;
    IF r.position_name IS DISTINCT FROM r.office THEN
      RAISE EXCEPTION 'CC_0206: %''s general row is for "%", expected "%"',
        r.nm, r.position_name, r.office;
    END IF;
    IF r.status <> 'active' THEN
      RAISE EXCEPTION 'CC_0206: %''s general row is % — refusing', r.nm, r.status;
    END IF;
    IF r.current_link IS NOT NULL AND r.current_link <> r.politician_id THEN
      RAISE EXCEPTION 'CC_0206: %''s general row is already linked to % — refusing to repoint it',
        r.nm, r.current_link;
    END IF;

    -- THE EVIDENCE: the SAME person, linked, on the primary row for the SAME office. This is what
    -- separates these four from the sixteen rows that merely share a name with somebody.
    SELECT rc2.politician_id INTO v_pid
      FROM essentials.race_candidates rc2
      JOIN essentials.races r2    ON r2.id = rc2.race_id
      JOIN essentials.elections e2 ON e2.id = r2.election_id
     WHERE rc2.id = r.primary_rc_id
       AND rc2.full_name = r.nm
       AND rc2.result = 'advanced'
       AND e2.election_date < DATE '2026-11-03'
       AND regexp_replace(lower(r2.position_name), '^(ca|california)\s+', '') = lower(r.office);

    IF v_pid IS NULL THEN
      RAISE EXCEPTION 'CC_0206: no linked, advanced primary row for % at "%" — the evidence this migration rests on is not there',
        r.nm, r.office;
    END IF;
    IF v_pid <> r.politician_id THEN
      RAISE EXCEPTION 'CC_0206: %''s primary row points at %, but this migration would link the general row to %',
        r.nm, v_pid, r.politician_id;
    END IF;

    -- The politician must exist and be active.
    PERFORM 1 FROM essentials.politicians p WHERE p.id = r.politician_id AND p.is_active;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'CC_0206: politician % for % is missing or inactive', r.politician_id, r.nm;
    END IF;

    -- ------------------------------------------------------------------- write
    UPDATE essentials.race_candidates
       SET politician_id = r.politician_id
     WHERE id = r.rc_id
       AND politician_id IS NULL;

    -- ------------------------------------------------------------------ verify
    SELECT rc.politician_id, rc.race_id INTO v_pid, v_race
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;

    IF v_pid IS DISTINCT FROM r.politician_id THEN
      RAISE EXCEPTION 'CC_0206: %''s general row reads % after the write, expected %',
        r.nm, coalesce(v_pid::text, '<null>'), r.politician_id;
    END IF;

    -- No unique constraint protects this, so check it here: one politician, one row per race.
    SELECT count(*) INTO v_dupes
      FROM essentials.race_candidates rc
     WHERE rc.race_id = v_race AND rc.politician_id = r.politician_id;
    IF v_dupes <> 1 THEN
      RAISE EXCEPTION 'CC_0206: % now appears % times in race % — expected exactly 1',
        r.nm, v_dupes, v_race;
    END IF;

    n_ok := n_ok + 1;
  END LOOP;

  IF n_seen <> 4 OR n_ok <> 4 THEN
    RAISE EXCEPTION 'CC_0206: saw % rows and verified %, expected 4 and 4', n_seen, n_ok;
  END IF;
END $$;

-- Whole-election gate. The four were chosen because they are the ONLY rows the evidence resolves;
-- this asserts the arithmetic that claim rests on, so a later import that changes it is noticed.
DO $$
DECLARE
  v_total             int;
  v_unlinked          int;
  c_expected_total    constant int := 324;
  c_expected_unlinked constant int := 132;   -- 136 measured, minus the 4 linked above
BEGIN
  SELECT count(*), count(*) FILTER (WHERE rc.politician_id IS NULL)
    INTO v_total, v_unlinked
    FROM essentials.race_candidates rc
    JOIN essentials.races r    ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.name = 'CA 2026 Statewide General';

  IF v_total <> c_expected_total THEN
    RAISE EXCEPTION 'CC_0206: the CA 2026 Statewide General holds % candidates, expected % — the import changed, re-measure before trusting the unlinked figure',
      v_total, c_expected_total;
  END IF;
  IF v_unlinked <> c_expected_unlinked THEN
    RAISE EXCEPTION 'CC_0206: % candidates remain unlinked, expected % (136 measured, minus the 4 linked here)',
      v_unlinked, c_expected_unlinked;
  END IF;

  RAISE NOTICE 'CC_0206: 4 general candidates linked; % of % remain unlinked, 116 of them having no politician record at all',
    v_unlinked, v_total;
END $$;

COMMIT;
