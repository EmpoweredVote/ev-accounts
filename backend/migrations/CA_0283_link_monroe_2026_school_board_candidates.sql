-- CA_0283_link_monroe_2026_school_board_candidates.sql
-- Link the five unlinked Monroe County school-board race_candidates rows in election
-- 21190350-91e3-4c2c-938d-9cf8f4ac9d5c ("IN 2026 Statewide General") to politician records, so
-- school-board stance research has a politician_id to write against. Only Ashley Pirani's row
-- (rc 96603469, linked by CA_0134) was linked before this.
--
-- WHO, AND THE IDENTITY EVIDENCE (all reads on prod 2026-09-24):
--
--   Erin Wyatt  -> EXISTING 760e1b7d-022c-4c70-b605-07b6fea2384b (ballotready, external_id 437674)
--     rc e247ec0e, race "Monroe County Community School Board - District 1" (office 8a8393ca).
--     The politician holds open terms on BOTH MCCSC District 1 offices (8a8393ca, the race's own
--     office, via CA_0136; and 12606d55 on 1800630-board-d1). Same board, same district, same
--     name, and she is the only active "Erin Wyatt" in essentials.politicians. rc.is_incumbent
--     is already true.
--   Aja Jester  -> EXISTING b3799cb0-d361-4405-b82e-59031c5ffe73 (ballotready, external_id 437675)
--     rc 5fb5051e, race "... District 7" (office d3e11729). Holds open terms on both MCCSC
--     District 7 offices (d3e11729, the race's office; 8e266c9e on 1800630-board-d7). The only
--     other Jester is Cole Jester, Arkansas Secretary of State (geo 05) -- a different person.
--   Christa Curtis  -> NEW  (RBB Bean Blossom Township, rc e6c5a3e0, not incumbent)
--   Dennis R. Adams -> NEW  (RBB Richland Township,     rc 120fec3c, not incumbent)
--   Kelly D. Scholl -> NEW  (RBB Richland Township,     rc a5f42018, not incumbent)
--     Searched essentials.politicians by last name, full_name and alternate_names, active and
--     inactive: no Christa/Christine Curtis, no Den* Adams, and no Kelly Scholl. The only
--     "Scholl" rows are four inactive cal_access_discovery CAMPAIGN-COMMITTEE stubs from
--     California (Rick Scholl, Dave Scholl, "Scholl for School Board 2010") -- not people, and not
--     Indiana. So all three get new records.
--
-- NEW RECORDS: is_active = true, is_incumbent = false (they are candidates and hold no seat --
-- CLAUDE.md: set is_incumbent explicitly on every insert). No office_terms: a candidate holds no
-- seat. Party is never stored (antipartisan). Fixed UUIDs make the insert idempotent.
--
-- CARD FIELDS: Wyatt's and Jester's rc rows carry no photo_url / website_url. Pirani's card
-- mirrors her politician's portrait and mccsc.edu URL (CA_0134), so this copies each linked
-- politician's existing photo_custom_url / urls[1] onto the card, only where the card is empty.
-- The race_candidate_mirror_data trigger copies card -> politician only when the politician is
-- empty, so it no-ops here: both politicians already carry what the card receives.
--
-- NOT IN SCOPE: the duplicate MCCSC/RBB office rows (Wyatt, Pirani, Jester, Jacobs, Kerr each
-- hold two). That is a separate operator decision -- see the data-fixes report.
--
-- IDEMPOTENT: fixed ids + ON CONFLICT DO NOTHING; every UPDATE is guarded on its own
-- precondition (politician_id IS NULL, card field empty). Re-running is a no-op.
-- NOT APPLIED. Dry-run on prod inside BEGIN ... ROLLBACK only.

BEGIN;

CREATE TEMP TABLE _ca0283 (
  rc_id          uuid PRIMARY KEY,
  politician_id  uuid NOT NULL,
  full_name      text NOT NULL,
  first_name     text NOT NULL,
  last_name      text NOT NULL,
  middle_initial text,
  is_new         boolean NOT NULL
) ON COMMIT DROP;

INSERT INTO _ca0283 VALUES
  ('e247ec0e-a698-4cbc-9dec-84fd6557980f','760e1b7d-022c-4c70-b605-07b6fea2384b','Erin Wyatt',     'Erin',   'Wyatt',  NULL, false),
  ('5fb5051e-cff6-4ed5-95ef-c947d99f9391','b3799cb0-d361-4405-b82e-59031c5ffe73','Aja Jester',     'Aja',    'Jester', NULL, false),
  ('e6c5a3e0-47ff-4981-ab7c-ad8e9b59c71f','439e68cb-eef4-4ed0-9f5a-3611268af2c5','Christa Curtis', 'Christa','Curtis', NULL, true),
  ('120fec3c-cfb3-4734-8ec2-063cd7ee7755','b5a39d79-0e05-4482-b7f4-0649857de09c','Dennis R. Adams','Dennis', 'Adams',  'R',  true),
  ('a5f42018-0c07-4087-ad01-afef62bd0d59','8ff99e87-8d94-4f3c-af18-d67ec3994f7d','Kelly D. Scholl','Kelly',  'Scholl', 'D',  true);

-- ── Pre-flight ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_bad int; v_existing int; v_namesake int;
BEGIN
  -- Every rc is in the Monroe election, and is either unlinked or already linked to the
  -- intended politician (a re-run). Anything else means the data moved under us.
  SELECT count(*) INTO v_bad
    FROM _ca0283 t
    LEFT JOIN essentials.race_candidates rc ON rc.id = t.rc_id
    LEFT JOIN essentials.races r ON r.id = rc.race_id
   WHERE rc.id IS NULL
      OR r.election_id <> '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'
      OR (rc.politician_id IS NOT NULL AND rc.politician_id <> t.politician_id);
  IF v_bad <> 0 THEN RAISE EXCEPTION 'CA_0283 pre-flight: % rc row(s) missing, outside the election, or linked elsewhere', v_bad; END IF;

  -- The two existing records still hold an open term on the office their race is on.
  SELECT count(*) INTO v_existing
    FROM _ca0283 t
    JOIN essentials.race_candidates rc ON rc.id = t.rc_id
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.office_terms ot ON ot.office_id = r.office_id AND ot.politician_id = t.politician_id AND ot.term_end IS NULL
    JOIN essentials.politicians p ON p.id = t.politician_id AND p.is_active
   WHERE NOT t.is_new;
  IF v_existing <> 2 THEN RAISE EXCEPTION 'CA_0283 pre-flight: expected Wyatt + Jester seated on their race office, got %', v_existing; END IF;

  -- No ACTIVE namesake exists for the three new people (other than a prior run of this file).
  SELECT count(*) INTO v_namesake
    FROM _ca0283 t
    JOIN essentials.politicians p
      ON p.is_active
     AND lower(btrim(p.first_name)) = lower(t.first_name)
     AND lower(btrim(p.last_name))  = lower(t.last_name)
     AND p.id <> t.politician_id
   WHERE t.is_new;
  IF v_namesake <> 0 THEN RAISE EXCEPTION 'CA_0283 pre-flight: % active namesake(s) for a new candidate -- link instead of insert', v_namesake; END IF;
END $$;

-- ── 1. New candidate records (before linking, so the rc points at a real row) ─────────────
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, middle_initial, is_active, is_incumbent, source)
SELECT t.politician_id, t.full_name, t.first_name, t.last_name, t.middle_initial, true, false,
       'CA_0283: Monroe County IN 2026 school-board candidate (Indiana SOS certified school-board list via The Indiana Citizen, 2026-08-12)'
FROM _ca0283 t
WHERE t.is_new
ON CONFLICT (id) DO NOTHING;

-- ── 2. Link the rc rows ───────────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET politician_id = t.politician_id, updated_at = now()
  FROM _ca0283 t
 WHERE rc.id = t.rc_id
   AND rc.politician_id IS NULL;

-- ── 3. Card fields for the two existing records, copied from the politician, only if empty ─
UPDATE essentials.race_candidates rc
   SET photo_url = p.photo_custom_url, updated_at = now()
  FROM _ca0283 t
  JOIN essentials.politicians p ON p.id = t.politician_id
 WHERE rc.id = t.rc_id AND NOT t.is_new
   AND coalesce(rc.photo_url, '') = ''
   AND coalesce(p.photo_custom_url, '') <> '';

UPDATE essentials.race_candidates rc
   SET website_url = p.urls[1], updated_at = now()
  FROM _ca0283 t
  JOIN essentials.politicians p ON p.id = t.politician_id
 WHERE rc.id = t.rc_id AND NOT t.is_new
   AND coalesce(rc.website_url, '') = ''
   AND coalesce(p.urls[1], '') <> '';

-- ── Post-verify gate ──────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_linked int; v_unlinked int; v_new int; v_new_terms int; v_party int;
BEGIN
  SELECT count(*) INTO v_linked
    FROM _ca0283 t JOIN essentials.race_candidates rc ON rc.id = t.rc_id AND rc.politician_id = t.politician_id;

  -- Positive control on the whole election's school races: all 6 candidates now linked
  -- (Pirani's pre-existing link included), none left NULL.
  SELECT count(*) FILTER (WHERE rc.politician_id IS NULL) INTO v_unlinked
    FROM essentials.races r JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c' AND r.position_name ILIKE '%school board%';

  SELECT count(*) INTO v_new
    FROM _ca0283 t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.is_new AND p.is_active AND p.is_incumbent = false;

  SELECT count(*) INTO v_new_terms
    FROM _ca0283 t JOIN essentials.office_terms ot ON ot.politician_id = t.politician_id WHERE t.is_new;

  SELECT count(*) INTO v_party
    FROM _ca0283 t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.is_new AND (p.party IS NOT NULL OR p.party_short_name IS NOT NULL);

  IF v_linked    <> 5 THEN RAISE EXCEPTION 'CA_0283: expected 5 rc rows linked, got %', v_linked; END IF;
  IF v_unlinked  <> 0 THEN RAISE EXCEPTION 'CA_0283: % Monroe school-board rc row(s) still unlinked', v_unlinked; END IF;
  IF v_new       <> 3 THEN RAISE EXCEPTION 'CA_0283: expected 3 new active non-incumbent records, got %', v_new; END IF;
  IF v_new_terms <> 0 THEN RAISE EXCEPTION 'CA_0283: a new candidate record carries % office_term(s)', v_new_terms; END IF;
  IF v_party     <> 0 THEN RAISE EXCEPTION 'CA_0283: party stored on % new record(s)', v_party; END IF;
  RAISE NOTICE 'CA_0283 ok: 5 rc rows linked (2 existing, 3 new), 0 Monroe school-board rc rows unlinked';
END $$;

COMMIT;
