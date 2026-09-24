-- CA_0287_retire_lewiston_local_school_committee_duplicates.sql
-- Retire the 8 duplicate Lewiston School Committee offices filed on the CITY district, and their empty chamber --
-- ARCHIVED FIRST into two locked tables (as CA_0206), then deleted from the live tables.
--
-- WHY. Lewiston's School Committee exists twice:
--   - SCHOOL district "Lewiston Public Schools" (eb583223, G5420 geo_id 2307320), chamber "Lewiston Public Schools
--     School Committee" (72841b2e, government "Lewiston Public Schools, Maine, US"): 8 offices, all 8 held.
--     Seeded by migration 265 (Phase 89) with rosters.
--   - LOCAL district "Lewiston" (ded42cc8, G4110 geo_id 2338740 -- the city polygon, shared with the council and
--     mayor), chamber "Lewiston School Committee" (50644de7, government "City of Lewiston, Maine, US"): the same 8
--     seats (At-Large + Wards 1-7), no terms, all flagged is_vacant.
-- An address in Lewiston resolves both districts, so the second set shows as 8 phantom vacant seats next to the real
-- holders. It is also level-unknown to the compass (a school board on a LOCAL district, topicApplicability's
-- SCHOOL_BOARD_OFFICE_RE), which is how it was found.
--
-- MEASURED 2026-09-24, before writing this file:
--   - every uuid column in every non-system schema was scanned for the 8 office ids and the chamber id: the only
--     hits are the rows themselves (essentials.offices.id x8, offices.chamber_id x8, chambers.id x1).
--   - FK references (pg_constraint): races.office_id (NO ACTION) 0 rows; office_terms.office_id (CASCADE) 0 rows;
--     meetings.meetings.chamber_id (NO ACTION) 0; discovered_sources / source_outlets .chamber_id (SET NULL) 0.
--   - non-FK references: politicians.office_id 0, politician_occupancy_evidence.office_id 0.
--   All of these are re-asserted by the pre-flight below, so a reference added since fails the file.
--
-- WHAT THIS FILE DOES.
--   1. Copies the 8 offices and the chamber into essentials._retired_ca0287_offices / _retired_ca0287_chambers
--      (LIKE the live tables) and compares the copies to the live rows before deleting anything.
--   2. Deletes the 8 offices, then the chamber.
--   3. Locks both archive tables the house way: RLS on with no policy (default-deny, as CA_0186), SELECT revoked
--      from anon and authenticated.
-- NOT TOUCHED: the LOCAL district ded42cc8 (it still carries the council and mayor), the City of Lewiston government,
-- and the SCHOOL copies. offices_missing_terms falls by exactly 8 (all 8 were flagged is_vacant, so the "flagged"
-- share falls by 8 and the unflagged drift count does not move).
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: NOT APPLIED. Dry run (BEGIN ... ROLLBACK) 2026-09-24, together with CA_0288: gates pass, a re-run is a no-op,
--   and a planted office_terms row on a duplicate trips the pre-flight. The rollback was confirmed to revert.
--
-- ROLLBACK (restore both, then the archive may be dropped). chambers.slug is GENERATED, so name the columns:
--   INSERT INTO essentials.chambers (id, external_id, government_id, name, name_formal, official_count, term_limit,
--     term_length, inauguration_rules, election_frequency, election_rules, vacancy_rules, remarks, staggered_term,
--     website_url, policy_engagement_level, election_method)
--   SELECT id, external_id, government_id, name, name_formal, official_count, term_limit, term_length,
--     inauguration_rules, election_frequency, election_rules, vacancy_rules, remarks, staggered_term, website_url,
--     policy_engagement_level, election_method FROM essentials._retired_ca0287_chambers ON CONFLICT (id) DO NOTHING;
--   INSERT INTO essentials.offices SELECT * FROM essentials._retired_ca0287_offices ON CONFLICT (id) DO NOTHING;
-- IDEMPOTENT: a re-run finds nothing live and the full set archived; it changes nothing and every gate passes.

BEGIN;

SET LOCAL lock_timeout = '10s';

CREATE TEMP TABLE _dup (office_id uuid PRIMARY KEY, title text NOT NULL) ON COMMIT DROP;
INSERT INTO _dup VALUES
  ('4993d6db-2dd8-4e76-8b40-24a5a8745798', 'School Committee Member (At-Large)'),
  ('2346c14e-f48e-4e95-8456-a9a84a33d302', 'School Committee Member (Ward 1)'),
  ('b37b3bf8-026e-478f-b5ce-791261dd4d82', 'School Committee Member (Ward 2)'),
  ('9902a8e7-c52a-4ab4-b6f2-31429f02ed68', 'School Committee Member (Ward 3)'),
  ('b67215e7-c26e-4c9c-aea5-0c96e92d3e26', 'School Committee Member (Ward 4)'),
  ('927c5c01-5a21-4615-8614-f2335d58c770', 'School Committee Member (Ward 5)'),
  ('0e68e961-e773-4adb-bdb1-b7fe7caaf6c2', 'School Committee Member (Ward 6)'),
  ('278790c1-7705-4550-a7df-616a48b690bb', 'School Committee Member (Ward 7)');

CREATE TABLE IF NOT EXISTS essentials._retired_ca0287_offices  (LIKE essentials.offices  INCLUDING DEFAULTS);
CREATE TABLE IF NOT EXISTS essentials._retired_ca0287_chambers (LIKE essentials.chambers INCLUDING DEFAULTS);
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '_retired_ca0287_offices_pkey') THEN
    ALTER TABLE essentials._retired_ca0287_offices ADD CONSTRAINT _retired_ca0287_offices_pkey PRIMARY KEY (id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '_retired_ca0287_chambers_pkey') THEN
    ALTER TABLE essentials._retired_ca0287_chambers ADD CONSTRAINT _retired_ca0287_chambers_pkey PRIMARY KEY (id);
  END IF;
END $$;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices) AS offices,
       (SELECT count(*) FROM essentials.chambers) AS chambers,
       (SELECT count(*) FROM essentials.office_terms) AS terms,
       (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms,
       (SELECT count(*) FROM essentials.offices_missing_terms WHERE NOT COALESCE(is_vacant, false)) AS missing_unflagged,
       (SELECT count(*) FROM essentials.offices o JOIN _dup ON _dup.office_id = o.id) AS live_dups;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  c_local_chamber CONSTANT uuid := '50644de7-e209-4dfa-adc4-058c0e9a0f70';
  c_local_district CONSTANT uuid := 'ded42cc8-1b22-4523-bd38-692f08caab64';
  c_school_chamber CONSTANT uuid := '72841b2e-34a0-4a24-a27d-cded6a0442ab';
  c_school_district CONSTANT uuid := 'eb583223-6ddc-4c0e-97e9-795ba88d4aa0';
  v_live int; v_arch int; v_n int;
BEGIN
  SELECT count(*) INTO v_live FROM essentials.offices o JOIN _dup ON _dup.office_id = o.id;
  SELECT count(*) INTO v_arch FROM essentials._retired_ca0287_offices a JOIN _dup ON _dup.office_id = a.id;
  IF NOT ((v_live = 8 AND v_arch = 0) OR (v_live = 0 AND v_arch = 8)) THEN
    RAISE EXCEPTION 'PRE: expected 8 live / 0 archived (first run) or 0 / 8 (re-run); found % / %', v_live, v_arch;
  END IF;

  IF v_live = 8 THEN
    -- the live rows are exactly the reviewed ones: right titles, on the city district, in the city chamber
    SELECT count(*) INTO v_n FROM essentials.offices o JOIN _dup ON _dup.office_id = o.id
     WHERE o.title = _dup.title AND o.district_id = c_local_district AND o.chamber_id = c_local_chamber;
    IF v_n <> 8 THEN RAISE EXCEPTION 'PRE: only % of 8 duplicates still match their reviewed title/district/chamber', v_n; END IF;
    -- the chamber holds nothing else
    SELECT count(*) INTO v_n FROM essentials.offices WHERE chamber_id = c_local_chamber;
    IF v_n <> 8 THEN RAISE EXCEPTION 'PRE: chamber % holds % offices, expected the 8 duplicates', c_local_chamber, v_n; END IF;
  END IF;

  -- nothing points at them (FK and non-FK; see header)
  SELECT count(*) INTO v_n FROM essentials.office_terms t JOIN _dup ON _dup.office_id = t.office_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % office_terms row(s) on a duplicate -- it is not unheld', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.races r JOIN _dup ON _dup.office_id = r.office_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race(s) point at a duplicate', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians p JOIN _dup ON _dup.office_id = p.office_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % politician(s) carry a duplicate as office_id', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_occupancy_evidence e JOIN _dup ON _dup.office_id = e.office_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % occupancy-evidence row(s) point at a duplicate', v_n; END IF;
  SELECT (SELECT count(*) FROM meetings.meetings WHERE chamber_id = c_local_chamber)
       + (SELECT count(*) FROM essentials.discovered_sources WHERE chamber_id = c_local_chamber)
       + (SELECT count(*) FROM essentials.source_outlets WHERE chamber_id = c_local_chamber) INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % meeting/source row(s) point at chamber %', v_n, c_local_chamber; END IF;

  -- the real board is intact: every duplicated seat exists on the SCHOOL district and is held today
  SELECT count(*) INTO v_n FROM _dup
    JOIN essentials.offices s ON s.title = _dup.title AND s.chamber_id = c_school_chamber AND s.district_id = c_school_district
    JOIN essentials.office_current_holder och ON och.office_id = s.id AND och.politician_id IS NOT NULL;
  IF v_n <> 8 THEN RAISE EXCEPTION 'PRE: only % of 8 seats are held on the SCHOOL copy -- do not retire the city copy', v_n; END IF;
END $$;

-- ─── 1. Archive, and prove the copy is exact before deleting ─────────────────────────────────────
INSERT INTO essentials._retired_ca0287_offices
SELECT o.* FROM essentials.offices o JOIN _dup ON _dup.office_id = o.id
ON CONFLICT (id) DO NOTHING;

INSERT INTO essentials._retired_ca0287_chambers
SELECT c.* FROM essentials.chambers c WHERE c.id = '50644de7-e209-4dfa-adc4-058c0e9a0f70'
ON CONFLICT (id) DO NOTHING;

DO $$
DECLARE v_live text; v_arch text;
BEGIN
  IF (SELECT live_dups FROM _before) > 0 THEN
    SELECT md5(string_agg(o::text, '|' ORDER BY o.id)) INTO v_live FROM essentials.offices o JOIN _dup ON _dup.office_id = o.id;
    SELECT md5(string_agg(a::text, '|' ORDER BY a.id)) INTO v_arch FROM essentials._retired_ca0287_offices a JOIN _dup ON _dup.office_id = a.id;
    IF v_live IS DISTINCT FROM v_arch THEN RAISE EXCEPTION 'ARCHIVE: office copies differ from the live rows (% vs %)', v_live, v_arch; END IF;
    SELECT md5(c::text) INTO v_live FROM essentials.chambers c WHERE c.id = '50644de7-e209-4dfa-adc4-058c0e9a0f70';
    SELECT md5(a::text) INTO v_arch FROM essentials._retired_ca0287_chambers a WHERE a.id = '50644de7-e209-4dfa-adc4-058c0e9a0f70';
    IF v_live IS DISTINCT FROM v_arch THEN RAISE EXCEPTION 'ARCHIVE: chamber copy differs from the live row (% vs %)', v_live, v_arch; END IF;
  END IF;
END $$;

-- ─── 2. Delete ───────────────────────────────────────────────────────────────────────────────────
DELETE FROM essentials.offices o USING _dup WHERE o.id = _dup.office_id;
DELETE FROM essentials.chambers WHERE id = '50644de7-e209-4dfa-adc4-058c0e9a0f70';

-- ─── 3. Lock the archive (default-deny, as CA_0186) ──────────────────────────────────────────────
ALTER TABLE essentials._retired_ca0287_offices  ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials._retired_ca0287_chambers ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON essentials._retired_ca0287_offices, essentials._retired_ca0287_chambers FROM anon, authenticated;
COMMENT ON TABLE essentials._retired_ca0287_offices IS
  'CA_0287 (2026-09-24): archive of the 8 duplicate Lewiston School Committee offices on the city LOCAL district (ded42cc8); the held seats live on SCHOOL district eb583223. Restore: see the migration header.';
COMMENT ON TABLE essentials._retired_ca0287_chambers IS
  'CA_0287 (2026-09-24): archive of the empty duplicate chamber "Lewiston School Committee" (50644de7). Restore: see the migration header (chambers.slug is generated).';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM essentials._retired_ca0287_offices a JOIN _dup ON _dup.office_id = a.id;
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: archive holds % of 8 offices', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials._retired_ca0287_offices;
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: archive holds % offices, expected exactly 8', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials._retired_ca0287_chambers;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: chamber archive holds % rows, expected 1', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o JOIN _dup ON _dup.office_id = o.id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % duplicate(s) still live', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.chambers WHERE id = '50644de7-e209-4dfa-adc4-058c0e9a0f70';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: the duplicate chamber is still live'; END IF;

  -- exactly the retired rows left the live tables
  SELECT count(*) INTO v_n FROM essentials.offices;
  IF v_n <> b.offices - b.live_dups THEN RAISE EXCEPTION 'POST: offices % -> %, expected -%', b.offices, v_n, b.live_dups; END IF;
  SELECT count(*) INTO v_n FROM essentials.chambers;
  IF v_n <> b.chambers - (CASE WHEN b.live_dups > 0 THEN 1 ELSE 0 END) THEN RAISE EXCEPTION 'POST: chambers % -> %', b.chambers, v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms;
  IF v_n <> b.terms THEN RAISE EXCEPTION 'POST: office_terms moved % -> % (the duplicates had none)', b.terms, v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms;
  IF v_n <> b.missing_terms - b.live_dups THEN RAISE EXCEPTION 'POST: offices_missing_terms % -> %, expected -%', b.missing_terms, v_n, b.live_dups; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms WHERE NOT COALESCE(is_vacant, false);
  IF v_n <> b.missing_unflagged THEN RAISE EXCEPTION 'POST: unflagged missing-terms moved % -> %', b.missing_unflagged, v_n; END IF;

  -- the city district keeps its council and mayor; the SCHOOL board keeps its 8 held seats
  SELECT count(*) INTO v_n FROM essentials.offices WHERE district_id = 'ded42cc8-1b22-4523-bd38-692f08caab64';
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: Lewiston city district holds % offices, expected 8 (7 wards + mayor)', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
   WHERE o.district_id = 'eb583223-6ddc-4c0e-97e9-795ba88d4aa0';
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: Lewiston Public Schools shows % held seats, expected 8', v_n; END IF;

  SELECT count(*) INTO v_n FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials' AND c.relname IN ('_retired_ca0287_offices', '_retired_ca0287_chambers') AND c.relrowsecurity;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: row-level security is on for % of 2 archive tables', v_n; END IF;
  IF has_table_privilege('anon', 'essentials._retired_ca0287_offices', 'SELECT')
     OR has_table_privilege('authenticated', 'essentials._retired_ca0287_chambers', 'SELECT') THEN
    RAISE EXCEPTION 'POST: an archive table is still readable by anon/authenticated';
  END IF;

  RAISE NOTICE 'CA_0287 applied: 8 duplicate Lewiston LOCAL school-committee offices + their chamber archived and retired';
END $$;

COMMIT;
