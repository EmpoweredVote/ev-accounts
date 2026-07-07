-- 162-verify.sql — Phase 162 read-only production gate (USHC3-02/03/04/05).
--
-- SELECT-only. Asserts the live state delivered across Phase 162's waves for the
-- IN + MD + MN + MO 2026 US House field (33 districts: IN 9, MD 8, MN 8, MO 8).
-- Cloned structurally from the validated 161-verify.sql (per-state scoping + honest-skip
-- pin discipline), with TWO novel blocks:
--   * MO-SEVERE  — clone of 161's TN-SEVERE non-surfacing assertion, for MO's 5 severity-
--                  routed districts (geo 2902/2903/2904/2905/2906 -> withheld election).
--   * IN9-FLAG   — novel: asserts the IN-9 primary incumbent-flag fix (migration 1212) holds.
--
-- ============================================================================
-- PER-STATE SCOPING (the cross-state contamination trap):
--   IN, MD, MN, MO are SEPARATE elections. MD reuses 8 PRE-EXISTING races under
--   '2026 Maryland General Election' (candidates-only seed, 162-08). MO has TWO elections:
--   the surfacing 'MO 2026 Statewide General' (3 non-severe districts) and the deliberately
--   withheld 'MO 2026 Congressional Redistricting - Polygon Pending' (5 severe districts).
--   Every assertion is scoped by election id AND d.district_type='NATIONAL_LOWER' AND
--   substr(d.geo_id,1,2) IN ('18','24','27','29'). NEVER a cross-state / election-wide count.
--
-- MO SEVERE-DISTRICT WITHHOLDING (D-01b; 162-01 correspondence audit):
--   5 of MO's 8 districts scored SEVERE (>25% pop moved / anchor city changed): geo_id
--   2902, 2903, 2904, 2905, 2906. Their races' election_id points at 'MO 2026 Congressional
--   Redistricting - Polygon Pending' (a non-general, >30-days-past-dated row) so
--   electionService.ts's ELECTION_VISIBILITY_WINDOW evaluates false and they do NOT surface
--   on /elections while remaining fully seeded (office_id NEVER null). The 3 non-severe MO
--   districts (2901, 2907, 2908) surface via 'MO 2026 Statewide General'.
--
-- IN-9 INCUMBENT-FLAG FIX (migration 1212; 162-07):
--   IN-9 has TWO primary races on prod: the DEMOCRATIC primary 7d3f0042-... (4 Dem candidates)
--   and the REPUBLICAN primary 9d2de2ae-... (Houchin, the true incumbent, rc.id a61ab808-...).
--   The seed bug had all 4 Dem-primary rows flagged is_incumbent=true and Houchin false. Mig
--   1212 corrected it: Houchin (a61ab808) -> true; the 4 Dem rows -> false. This gate asserts
--   the corrected invariant holds: exactly 1 is_incumbent=true across the two IN-9 primary
--   races, and it is Houchin's rc.id a61ab808; the D-primary race 7d3f0042 has 0 incumbents.
--   (NOTE: the plan's original ids were stale — 9d2de2ae is the R-primary RACE id, not
--   Houchin's rc.id; corrected here per the live re-verify in 162-07.)
--
-- HONEST-SKIP PIN TABLES (whole-record stance skips; the 143 lesson — pin by exact
--   external_id resolved to politician_id, ORDER BY politician_id):
--     MN 4  (162-06): Mosel -270207, Jackson -270501, Zieska -270505, McKenzie -270507
--     IN 0  (162-09): every IN target got >=1 sourced stance
--     MD 1  (162-10): Burruss -240502
--     MO 19 (162-04): enumerated below
--   Total: 24 pinned whole-record stance skips. Full trails: 162-04/06/09/10-SUMMARY.md.
--
-- HEADSHOT HONEST-SKIP PINS (_img_skip, by external_id, ORDER BY external_id):
--   110 of the active new-candidate band members (IN 11, MD 10, MN 32, MO 57) have no
--   free-license portrait (obscure down-ballot / no dedicated Wikipedia bio / wrong-person
--   guard rejection) per the seeding waves' seed-{state}-house-headshots.py runs
--   (162-02/05/07/08-SUMMARY.md). Reconstructed live against prod at gate-authoring time
--   (2026-07-05) via the "active new-band candidate lacking an image" query.
--
-- WRITE-FREE: no INSERT/UPDATE/DELETE into essentials|inform. Only CREATE TEMP TABLE ...
--   ON COMMIT DROP. SELECT-only against production; never --commit.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/162-verify.sql
--
-- IN election: 'IN 2026 Statewide General'                                 FIPS 18 / geo 1801..1809.
-- MD election: '2026 Maryland General Election' (PRE-EXISTING, reused)      FIPS 24 / geo 2401..2408.
-- MN election: 'MN 2026 Statewide General'                                 FIPS 27 / geo 2701..2708.
-- MO elections:'MO 2026 Statewide General' (surfacing, 3 non-severe)       FIPS 29 / geo 2901..2908.
--              'MO 2026 Congressional Redistricting - Polygon Pending' (withheld, 5 severe)

\set ON_ERROR_STOP on

DO $$
DECLARE
  in_eid            uuid;
  md_eid            uuid;
  mn_eid            uuid;
  mo_gen_eid        uuid;
  mo_withheld_eid   uuid;
  v_in_races        int;
  v_md_races        int;
  v_mn_races        int;
  v_mo_races        int;
  v_null_office     int;
  v_nullpid         int;
  v_dupname         int;
  v_party_cols      int;
  v_mo_leaked       int;
  v_mo_surfaced_ok  int;
  v_md_dup_pairs    int;
  v_in9_inc_total   int;
  v_in9_dprim_inc   int;
  v_in9_houchin     int;
  v_no_image        int;
  v_image_detail    text;
  v_unsourced       int;
  v_uncovered       int;
  v_cov_detail      text;
BEGIN
  -- ==========================================================================
  -- Resolve all five election rows by exact name (4 states; MO has 2 elections).
  -- ==========================================================================
  SELECT id INTO in_eid          FROM essentials.elections WHERE name = 'IN 2026 Statewide General';
  SELECT id INTO md_eid          FROM essentials.elections WHERE name = '2026 Maryland General Election';
  SELECT id INTO mn_eid          FROM essentials.elections WHERE name = 'MN 2026 Statewide General';
  SELECT id INTO mo_gen_eid      FROM essentials.elections WHERE name = 'MO 2026 Statewide General';
  SELECT id INTO mo_withheld_eid FROM essentials.elections WHERE name = 'MO 2026 Congressional Redistricting - Polygon Pending';
  IF in_eid IS NULL OR md_eid IS NULL OR mn_eid IS NULL OR mo_gen_eid IS NULL OR mo_withheld_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: one or more Phase-162 elections missing (in=%, md=%, mn=%, mo_gen=%, mo_withheld=%)',
      in_eid, md_eid, mn_eid, mo_gen_eid, mo_withheld_eid;
  END IF;

  -- ==========================================================================
  -- Combined Phase-162 House working set (all 4 states, LEFT JOIN candidates).
  -- Scoped by: election_id IN (5 eids) + NATIONAL_LOWER + geo prefix IN (18,24,27,29).
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE
           WHEN r.election_id = in_eid THEN 'IN'
           WHEN r.election_id = md_eid THEN 'MD'
           WHEN r.election_id = mn_eid THEN 'MN'
           ELSE 'MO'
         END              AS st,
         r.id             AS race_id,
         r.election_id    AS race_election_id,
         r.office_id      AS office_id,
         d.geo_id         AS geo_id,
         rc.id            AS rc_id,
         rc.politician_id,
         rc.full_name,
         rc.candidate_status,
         rc.is_incumbent,
         p.external_id
  FROM essentials.races r
  JOIN  essentials.offices o    ON o.id = r.office_id
  JOIN  essentials.districts d  ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.politicians p      ON p.id = rc.politician_id
  WHERE ( r.election_id IN (in_eid, md_eid, mn_eid, mo_gen_eid, mo_withheld_eid) )
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('18', '24', '27', '29');

  -- ==========================================================================
  -- CRITERION 1 — exactly IN 9 + MD 8 + MN 8 + MO 8 = 33 distinct NATIONAL_LOWER races.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_in_races FROM _house WHERE st = 'IN';
  SELECT COUNT(DISTINCT race_id) INTO v_md_races FROM _house WHERE st = 'MD';
  SELECT COUNT(DISTINCT race_id) INTO v_mn_races FROM _house WHERE st = 'MN';
  SELECT COUNT(DISTINCT race_id) INTO v_mo_races FROM _house WHERE st = 'MO';
  IF v_in_races <> 9 THEN RAISE EXCEPTION 'FAIL scope: expected 9 IN NATIONAL_LOWER races, got %', v_in_races; END IF;
  IF v_md_races <> 8 THEN RAISE EXCEPTION 'FAIL scope: expected 8 MD NATIONAL_LOWER races, got %', v_md_races; END IF;
  IF v_mn_races <> 8 THEN RAISE EXCEPTION 'FAIL scope: expected 8 MN NATIONAL_LOWER races, got %', v_mn_races; END IF;
  IF v_mo_races <> 8 THEN RAISE EXCEPTION 'FAIL scope: expected 8 MO NATIONAL_LOWER races, got %', v_mo_races; END IF;
  RAISE NOTICE 'PASS SCOPE: IN 9 + MD 8 + MN 8 + MO 8 = 33 distinct NATIONAL_LOWER races';

  -- ==========================================================================
  -- CRITERION 2 — every House race has office_id NOT NULL (all 33, incl. 5 withheld MO).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_null_office FROM _house WHERE office_id IS NULL;
  IF v_null_office <> 0 THEN
    RAISE EXCEPTION 'FAIL NULLOFFICE: % of 33 Phase-162 House race(s) have NULL office_id', v_null_office;
  END IF;
  RAISE NOTICE 'PASS NULLOFFICE: 0 of 33 Phase-162 House races have NULL office_id (incl. the 5 withheld severe-MO races)';

  -- ==========================================================================
  -- CRITERION 3 — 0 active race_candidates with NULL politician_id.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_nullpid FROM _house WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL NULLPID: % active Phase-162 House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS NULLPID: 0 active IN/MD/MN/MO House candidates with NULL politician_id';

  -- ==========================================================================
  -- CRITERION 4 — 0 duplicate lower(full_name) among ACTIVE candidates WITHIN each state.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT st, lower(full_name) FROM _house
    WHERE candidate_status = 'active'
    GROUP BY st, lower(full_name) HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL DUPNAME: % duplicate full_name group(s) within a state among active candidates', v_dupname;
  END IF;
  RAISE NOTICE 'PASS DUPNAME: 0 duplicate full_name within any state (IN/MD/MN/MO) among active candidates';

  -- ==========================================================================
  -- CRITERION 5 — antipartisan structural invariant: race_candidates carries no party column.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_party_cols
  FROM information_schema.columns
  WHERE table_schema = 'essentials' AND table_name = 'race_candidates'
    AND column_name IN ('party', 'party_affiliation');
  IF v_party_cols <> 0 THEN
    RAISE EXCEPTION 'FAIL PARTY: essentials.race_candidates has % party column(s) -- antipartisan invariant violated', v_party_cols;
  END IF;
  RAISE NOTICE 'PASS PARTY: race_candidates has no party/party_affiliation column';

  -- ==========================================================================
  -- CRITERION 6 (NEW, MO-SEVERE) — MO severe-district non-surfacing invariant.
  --   Every severe geo_id's race election_id MUST equal mo_withheld_eid (leaked=0);
  --   every non-severe MO geo_id's race election_id MUST equal mo_gen_eid (surfaced_ok=3).
  -- ==========================================================================
  SELECT COUNT(DISTINCT geo_id) INTO v_mo_leaked
  FROM _house
  WHERE st = 'MO'
    AND geo_id = ANY(ARRAY['2902', '2903', '2904', '2905', '2906'])
    AND race_election_id <> mo_withheld_eid;
  IF v_mo_leaked <> 0 THEN
    RAISE EXCEPTION 'FAIL MO-SEVERE-WITHHELD: % severe MO race(s) wired to a surfacing election (expected all 5 -> Polygon Pending)', v_mo_leaked;
  END IF;

  SELECT COUNT(DISTINCT geo_id) INTO v_mo_surfaced_ok
  FROM _house
  WHERE st = 'MO'
    AND geo_id = ANY(ARRAY['2901', '2907', '2908'])
    AND race_election_id = mo_gen_eid;
  IF v_mo_surfaced_ok <> 3 THEN
    RAISE EXCEPTION 'FAIL MO-NONSEVERE-SURFACING: expected all 3 non-severe MO districts wired to MO 2026 Statewide General, got %', v_mo_surfaced_ok;
  END IF;
  RAISE NOTICE 'PASS MO-SEVERE: all 5 severe MO races (2902/2903/2904/2905/2906) -> Polygon Pending (withheld); all 3 non-severe (2901/2907/2908) -> MO 2026 Statewide General (surfacing)';

  -- ==========================================================================
  -- CRITERION 7 (MD dedup) — exactly 1 race_candidates row per (race_id, politician_id) on
  --   the 8 reused MD races (no duplicate wiring from the candidates-only seed).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_md_dup_pairs FROM (
    SELECT race_id, politician_id FROM _house
    WHERE st = 'MD' AND politician_id IS NOT NULL
    GROUP BY race_id, politician_id HAVING COUNT(*) > 1
  ) q;
  IF v_md_dup_pairs <> 0 THEN
    RAISE EXCEPTION 'FAIL MD-DEDUP: % (race_id, politician_id) pair(s) wired more than once on MD races', v_md_dup_pairs;
  END IF;
  RAISE NOTICE 'PASS MD-DEDUP: exactly 1 race_candidates row per (race_id, politician_id) on all 8 reused MD races';

  -- ==========================================================================
  -- CRITERION 8 (NEW, IN9-FLAG) — the IN-9 incumbent-flag fix (migration 1212) holds.
  --   Across the two IN-9 primary races (D 7d3f0042 + R 9d2de2ae): exactly 1 is_incumbent=true,
  --   and it is Houchin's rc.id a61ab808; the D-primary race 7d3f0042 has 0 incumbents.
  -- ==========================================================================
  SELECT COUNT(*) FILTER (WHERE is_incumbent) INTO v_in9_inc_total
  FROM essentials.race_candidates
  WHERE race_id IN ('7d3f0042-eb15-462b-bf14-df15244c5d16', '9d2de2ae-2fef-48b6-b3d4-2787166b78df');

  SELECT COUNT(*) FILTER (WHERE is_incumbent) INTO v_in9_dprim_inc
  FROM essentials.race_candidates
  WHERE race_id = '7d3f0042-eb15-462b-bf14-df15244c5d16';

  SELECT COUNT(*) INTO v_in9_houchin
  FROM essentials.race_candidates
  WHERE id = 'a61ab808-846a-4bb7-9544-f9f33357b078' AND is_incumbent = true;

  IF v_in9_inc_total <> 1 THEN
    RAISE EXCEPTION 'FAIL IN9-FLAG: expected exactly 1 is_incumbent=true across the two IN-9 primary races, got %', v_in9_inc_total;
  END IF;
  IF v_in9_dprim_inc <> 0 THEN
    RAISE EXCEPTION 'FAIL IN9-FLAG: IN-9 Democratic primary race 7d3f0042 has % incumbent-flagged rows (expected 0)', v_in9_dprim_inc;
  END IF;
  IF v_in9_houchin <> 1 THEN
    RAISE EXCEPTION 'FAIL IN9-FLAG: Houchin rc.id a61ab808 is not the sole is_incumbent=true row (got %)', v_in9_houchin;
  END IF;
  RAISE NOTICE 'PASS IN9-FLAG: IN-9 has exactly 1 incumbent (Houchin, rc.id a61ab808 on R-primary 9d2de2ae); D-primary 7d3f0042 has 0 incumbents (mig 1212 holds)';

  -- ==========================================================================
  -- New-candidate (Phase-162 external_id band, ACTIVE only) working sets per state.
  --   IN -180999..-180101   MD -240899..-240101   MN -270899..-270101   MO -290899..-290101
  --   (MD's reused Boafo -2420067 is intentionally out-of-band -- he has an image + stances.)
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.st, h.politician_id, h.external_id
  FROM _house h
  WHERE h.candidate_status = 'active'
    AND ( (h.st = 'IN' AND h.external_id BETWEEN -180999 AND -180101)
       OR (h.st = 'MD' AND h.external_id BETWEEN -240899 AND -240101)
       OR (h.st = 'MN' AND h.external_id BETWEEN -270899 AND -270101)
       OR (h.st = 'MO' AND h.external_id BETWEEN -290899 AND -290101) );

  -- ==========================================================================
  -- Whole-record stance honest-skip pins (_stance_skip, by politician_id, ORDER BY politician_id).
  --   MN 4 / IN 0 / MD 1 / MO 19 = 24. Full trails: 162-04/06/09/10-SUMMARY.md.
  -- ==========================================================================
  CREATE TEMP TABLE _stance_skip (politician_id uuid, external_id bigint, reason text) ON COMMIT DROP;
  INSERT INTO _stance_skip (politician_id, external_id, reason)
  SELECT p.id, p.external_id, v.reason
  FROM (VALUES
    -- MN (162-06): 4 whole-record skips
    (-270207::bigint, 'Christopher Mosel MN-2 -- no site (West St. Paul Reader "[No response]"), $0 FEC, no survey/socials/news'),
    (-270501, 'DeVelle L. Jackson MN-5 -- no site/FEC/news; isidewith hit was a different GA-Senate Develle Jackson'),
    (-270505, 'Abbey Zieska MN-5 -- pre-infrastructure; Hometown Source noted "did not have websites" at filing'),
    (-270507, 'Abena A. McKenzie MN-5 -- site is local-community-services framing, nothing maps to the 24 federal topics'),
    -- MD (162-10): 1 whole-record skip
    (-240502, 'Jonathan Burruss MD-5 -- campaign site is an empty Wix placeholder; Ballotpedia 403/451; no socials/news/positions'),
    -- MO (162-04): 19 whole-record skips
    (-290103, 'Carl E. Henderson MO-1 -- Civoren/GoodParty boilerplate only'),
    (-290104, 'Alissa Murphy MO-1 -- BallotReady bio only, no positions'),
    (-290106, 'Andrew Jones MO-1 -- Civoren vague growth language only'),
    (-290201, 'Elizabeth Sparks-Holmes MO-2 -- site themes only, no scale-mappable position'),
    (-290302, 'Mike Conner MO-3 -- FEC-confirmed, no site/news/social'),
    (-290303, 'Tommy Holstein MO-3 -- FEC-confirmed, no working site/news'),
    (-290305, 'Paul Wilson MO-3 -- JS-placeholder Wix platform, no extractable text'),
    (-290306, 'Jim Higgins MO-3 -- only stale 2012-2015 gubernatorial coverage'),
    (-290401, 'Heather Shelton MO-4 -- Civoren vague pledges only'),
    (-290402, 'Scott Vera MO-4 -- FEC-confirmed, no site/content'),
    (-290403, 'Jeanette Cass MO-4 -- Civoren generic phrases, unmappable'),
    (-290404, 'Hartzell Gray MO-4 -- FEC-confirmed, no policy content'),
    (-290405, 'Jordan Herrera MO-4 -- Civoren meta-political statements only'),
    (-290407, 'G Rick MO-4 -- Civoren: no bio/policy submitted'),
    (-290410, 'Thomas Holbrook MO-4 -- FEC-confirmed, ideology label only'),
    (-290505, 'Berton A. Knox MO-5 -- BallotReady-confirmed, no content'),
    (-290507, 'Randall Langkraehr MO-5 -- FEC-confirmed, unclaimed/placeholder profiles'),
    (-290701, 'John Casey MO-7 -- no site; unquotable YouTube ref only'),
    (-290805, 'Rebecca Sharpe Lombard MO-8 -- bio only, all sources walled/404')
  ) AS v(external_id, reason)
  JOIN essentials.politicians p ON p.external_id = v.external_id
  ORDER BY p.id;

  -- ==========================================================================
  -- Headshot honest-skip pins (_img_skip, by external_id, ORDER BY external_id).
  --   110 total: IN 11 + MD 10 + MN 32 + MO 57. Reconstructed live 2026-07-05.
  -- ==========================================================================
  CREATE TEMP TABLE _img_skip (external_id bigint) ON COMMIT DROP;
  INSERT INTO _img_skip (external_id) VALUES
    -- IN (11)
    (-180902),(-180801),(-180702),(-180701),(-180601),(-180501),(-180401),(-180301),(-180202),(-180201),
    (-180101),
    -- MD (10)
    (-240802),(-240801),(-240701),(-240602),(-240503),(-240502),(-240501),(-240401),(-240301),(-240201),
    -- MN (32)
    (-270804),(-270803),(-270802),(-270801),(-270702),(-270701),(-270603),(-270602),(-270601),(-270509),
    (-270508),(-270507),(-270506),(-270505),(-270504),(-270503),(-270502),(-270501),(-270404),(-270403),
    (-270402),(-270401),(-270302),(-270301),(-270207),(-270206),(-270204),(-270202),(-270104),(-270103),
    (-270102),(-270101),
    -- MO (57)
    (-290805),(-290804),(-290803),(-290802),(-290801),(-290704),(-290703),(-290702),(-290701),(-290609),
    (-290608),(-290607),(-290606),(-290605),(-290604),(-290603),(-290602),(-290601),(-290507),(-290506),
    (-290505),(-290504),(-290503),(-290502),(-290501),(-290410),(-290409),(-290408),(-290407),(-290406),
    (-290405),(-290404),(-290403),(-290402),(-290401),(-290306),(-290305),(-290304),(-290303),(-290302),
    (-290301),(-290210),(-290209),(-290208),(-290207),(-290206),(-290205),(-290204),(-290203),(-290202),
    (-290201),(-290107),(-290106),(-290105),(-290104),(-290103),(-290102);

  -- ==========================================================================
  -- USHC3-04 — every active new candidate has a politician_images row, except pinned skips.
  -- ==========================================================================
  SELECT COUNT(*),
         string_agg(nc.st || ':' || nc.external_id, ', ' ORDER BY nc.external_id)
    INTO v_no_image, v_image_detail
  FROM _new_cands nc
  WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id)
    AND nc.external_id NOT IN (SELECT external_id FROM _img_skip);
  IF v_no_image <> 0 THEN
    RAISE EXCEPTION 'FAIL HEADSHOT: % active new IN/MD/MN/MO candidate(s) lack a politician_images row and are not pinned: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS HEADSHOT: every active new IN/MD/MN/MO candidate has a politician_images row or a pinned honest-skip (110 pinned)';

  -- ==========================================================================
  -- USHC3-05a — 0 unsourced stance rows for ALL active in-scope politicians (challengers
  --   AND incumbents) across the 4 states' House races.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers a
  JOIN (SELECT DISTINCT politician_id FROM _house WHERE candidate_status = 'active' AND politician_id IS NOT NULL) sc
    ON sc.politician_id = a.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id
      AND c.topic_id = a.topic_id
      AND c.sources IS NOT NULL
      AND array_length(c.sources, 1) >= 1
  );
  IF v_unsourced <> 0 THEN
    RAISE EXCEPTION 'FAIL UNSOURCED: % unsourced stance row(s) in the in-scope IN/MD/MN/MO House candidate set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS UNSOURCED: 0 unsourced stance rows for the in-scope IN/MD/MN/MO House candidate set (challengers + incumbents)';

  -- ==========================================================================
  -- USHC3-05b — every in-scope NEW candidate has >=1 sourced stance OR is a pinned
  --   whole-record honest-skip (chairs-not-polarity; no full-24 coverage required).
  -- ==========================================================================
  SELECT COUNT(*),
         string_agg(x.who, ', ' ORDER BY x.politician_id)
    INTO v_uncovered, v_cov_detail
  FROM (
    SELECT nc.politician_id,
           nc.st || ':' || nc.external_id AS who,
           (SELECT COUNT(*) FROM inform.politician_answers a WHERE a.politician_id = nc.politician_id) AS ans_count
    FROM _new_cands nc
    WHERE nc.politician_id NOT IN (SELECT politician_id FROM _stance_skip)
  ) x
  WHERE x.ans_count < 1;
  IF v_uncovered <> 0 THEN
    RAISE EXCEPTION 'FAIL COVERAGE: % in-scope new candidate(s) have 0 stances and are not pinned as whole-record honest-skip: %', v_uncovered, v_cov_detail;
  END IF;
  RAISE NOTICE 'PASS COVERAGE: every in-scope IN/MD/MN/MO new candidate has >=1 sourced stance or is a pinned whole-record honest-skip (24 pinned)';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC3-02/03/04/05, 33 districts: IN 9 / MD 8 / MN 8 / MO 8; MO severe withholding + IN-9 flag fix verified)';
END $$;
