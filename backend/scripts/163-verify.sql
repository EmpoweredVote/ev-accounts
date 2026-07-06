-- 163-verify.sql — Phase 163 read-only production gate (USHC3-02/03/04/05).
--
-- SELECT-only. Asserts the live state delivered across Phase 163's waves for the
-- WI + CO + AL + SC + LA 2026 US House field (36 districts: WI 8, CO 8, AL 7, SC 7, LA 6).
-- Cloned structurally from the validated 162-verify.sql (per-state scoping + honest-skip
-- pin discipline), with THREE novel blocks:
--   * AL-SEVERE  — clone of 162's MO-SEVERE non-surfacing assertion, for AL's 1 severe
--                  district (geo 0102 -> withheld 'AL 2026 Congressional Redistricting -
--                  Polygon Pending'; the other 6 -> 'AL 2026 Statewide General').
--   * LA-SEVERE  — same structure for LA's 2 severe districts (geo 2202/2206 -> withheld
--                  'LA 2026 Congressional Redistricting - Polygon Pending'; the other 4 ->
--                  'LA 2026 Statewide General'), PLUS the LA jungle-model invariant:
--                  exactly 6 LA races, every LA race primary_party IS NULL, no Dec-2026 runoff.
--   * CO1-DEGETTE — novel (analogous to 162's IN9-FLAG): CO-1 (geo 0801) has exactly 2 active
--                  candidates and DeGette (pid 610bb358-...) is absent (she lost the primary).
--
-- ============================================================================
-- PER-STATE SCOPING (the cross-state contamination trap):
--   WI, CO, AL, SC, LA are SEPARATE elections. AL and LA each have TWO elections: the
--   surfacing 'XX 2026 Statewide General' and the deliberately withheld 'XX 2026 Congressional
--   Redistricting - Polygon Pending' carrying the severe (D-01b) districts. Every assertion is
--   scoped by election id AND d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN
--   ('55','08','01','45','22'). NEVER a cross-state / election-wide count.
--
-- AL SEVERE-DISTRICT WITHHOLDING (163-04; 163-al-correspondence-audit.md "Severe geo_id list: 0102"):
--   AL-2 (geo 0102, Shomari Figures' 2023-special-master seat) scored SEVERE. Its race's
--   election_id points at 'AL 2026 Congressional Redistricting - Polygon Pending' so it does NOT
--   surface on /elections while remaining fully seeded (office_id NEVER null). The 6 non-severe AL
--   districts (0101, 0103, 0104, 0105, 0106, 0107) surface via 'AL 2026 Statewide General'.
--   NB: AL-2 and AL-6 are Aug-11-2026 SPECIAL primaries in reality; that does not change the
--   withholding wiring the gate asserts here (only AL-2 is severity-routed).
--
-- LA SEVERE-DISTRICT WITHHOLDING (163-06; 163-la-correspondence-audit.md "Severe geo_id list: 2202, 2206"):
--   LA-2 (geo 2202, Troy Carter) and LA-6 (geo 2206, Cleo Fields' dissolved majority-Black seat)
--   scored SEVERE after SB121/Act 2 (Louisiana v. Callais). Both races' election_id points at
--   'LA 2026 Congressional Redistricting - Polygon Pending' (withheld); the 4 non-severe LA
--   districts (2201, 2203, 2204, 2205) surface via 'LA 2026 Statewide General'. LA runs a JUNGLE
--   ballot (all parties, one Nov-3 election): every LA race has primary_party IS NULL, there are
--   exactly 6 LA races, and no December-2026 runoff election row exists (contingent runoff not seeded).
--   NB: Rick Edmonds was re-keyed -220503 (LA-5) -> -220605 (LA-6) by migration 1230 (he switched
--   to challenge Fields); he is on the withheld LA-6 race. LA-5 now has 12 active, LA-6 has 6.
--
-- CO-1 DEGETTE EXCLUSION (163-03):
--   Rep. Diana DeGette (pid 610bb358-bae9-4ce8-beaf-a33a27d5ba49) LOST the CO-1 Democratic primary
--   and is therefore NOT a 2026 candidate. This gate asserts CO-1 (geo 0801) has exactly 2 active
--   race_candidates and DeGette has 0 rows there; RAISE EXCEPTION otherwise.
--
-- HONEST-SKIP PIN TABLES (whole-record stance skips; the 143 lesson — pin by exact
--   external_id resolved to politician_id, ORDER BY politician_id):
--     WI 1 (163-07): Nath -550402
--     CO 0 (163-10): every CO target got >=1 sourced stance
--     AL 1 (163-08): Burger -10101
--     SC 3 (163-10): Ellis -450104, Smith -450202, Ethridge -450402
--     LA 5 (163-09): Arrington -220101, Long -220102, Collins -220201, Walker -220303, Williams -220604
--   Total: 10 pinned whole-record stance skips. Full trails: 163-07/08/09/10-SUMMARY.md + each state's _SKIPS.md.
--
-- HEADSHOT HONEST-SKIP PINS (_img_skip, by external_id, ORDER BY external_id):
--   95 of the active new-candidate band members (WI 27, CO 7, AL 20, SC 15, LA 26) have no
--   free-license portrait (obscure down-ballot / no dedicated Wikipedia bio / wrong-person
--   guard rejection) per the seeding waves' seed-{state}-house-headshots.py runs
--   (163-02/03/04/05/06-SUMMARY.md). Reconstructed live against prod at gate-authoring time
--   (2026-07-06) via the "active new-band candidate lacking an image" query. Edmonds appears as
--   -220605 (post-mig-1230 re-key), not the stale -220503.
--
-- WRITE-FREE: no INSERT/UPDATE/DELETE into essentials|inform. Only CREATE TEMP TABLE ...
--   ON COMMIT DROP. SELECT-only against production; never --commit.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/163-verify.sql
--
-- WI election: 'WI 2026 Statewide General'                                  FIPS 55 / geo 5501..5508.
-- CO election: 'CO 2026 Statewide General'                                  FIPS 08 / geo 0801..0808.
-- AL elections:'AL 2026 Statewide General' (surfacing, 6 non-severe)        FIPS 01 / geo 0101..0107.
--              'AL 2026 Congressional Redistricting - Polygon Pending' (withheld, 1 severe: 0102)
-- SC election: 'SC 2026 Statewide General'                                  FIPS 45 / geo 4501..4507.
-- LA elections:'LA 2026 Statewide General' (surfacing, 4 non-severe)        FIPS 22 / geo 2201..2206.
--              'LA 2026 Congressional Redistricting - Polygon Pending' (withheld, 2 severe: 2202, 2206)

\set ON_ERROR_STOP on

DO $$
DECLARE
  wi_eid            uuid;
  co_eid            uuid;
  al_gen_eid        uuid;
  al_withheld_eid   uuid;
  sc_eid            uuid;
  la_gen_eid        uuid;
  la_withheld_eid   uuid;
  v_wi_races        int;
  v_co_races        int;
  v_al_races        int;
  v_sc_races        int;
  v_la_races        int;
  v_null_office     int;
  v_nullpid         int;
  v_dupname         int;
  v_party_cols      int;
  v_al_leaked       int;
  v_al_surfaced_ok  int;
  v_la_leaked       int;
  v_la_surfaced_ok  int;
  v_la_party        int;
  v_la_runoff       int;
  v_co1_active      int;
  v_co1_degette     int;
  v_no_image        int;
  v_image_detail    text;
  v_unsourced       int;
  v_uncovered       int;
  v_cov_detail      text;
BEGIN
  -- ==========================================================================
  -- Resolve all seven election rows by exact name (5 states; AL + LA have 2 each).
  -- ==========================================================================
  SELECT id INTO wi_eid          FROM essentials.elections WHERE name = 'WI 2026 Statewide General';
  SELECT id INTO co_eid          FROM essentials.elections WHERE name = 'CO 2026 Statewide General';
  SELECT id INTO al_gen_eid      FROM essentials.elections WHERE name = 'AL 2026 Statewide General';
  SELECT id INTO al_withheld_eid FROM essentials.elections WHERE name = 'AL 2026 Congressional Redistricting - Polygon Pending';
  SELECT id INTO sc_eid          FROM essentials.elections WHERE name = 'SC 2026 Statewide General';
  SELECT id INTO la_gen_eid      FROM essentials.elections WHERE name = 'LA 2026 Statewide General';
  SELECT id INTO la_withheld_eid FROM essentials.elections WHERE name = 'LA 2026 Congressional Redistricting - Polygon Pending';
  IF wi_eid IS NULL OR co_eid IS NULL OR al_gen_eid IS NULL OR al_withheld_eid IS NULL
     OR sc_eid IS NULL OR la_gen_eid IS NULL OR la_withheld_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: one or more Phase-163 elections missing (wi=%, co=%, al_gen=%, al_withheld=%, sc=%, la_gen=%, la_withheld=%)',
      wi_eid, co_eid, al_gen_eid, al_withheld_eid, sc_eid, la_gen_eid, la_withheld_eid;
  END IF;

  -- ==========================================================================
  -- Combined Phase-163 House working set (all 5 states, LEFT JOIN candidates).
  -- Scoped by: election_id IN (7 eids) + NATIONAL_LOWER + geo prefix IN (55,08,01,45,22).
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE
           WHEN r.election_id = wi_eid THEN 'WI'
           WHEN r.election_id = co_eid THEN 'CO'
           WHEN r.election_id IN (al_gen_eid, al_withheld_eid) THEN 'AL'
           WHEN r.election_id = sc_eid THEN 'SC'
           ELSE 'LA'
         END              AS st,
         r.id             AS race_id,
         r.election_id    AS race_election_id,
         r.office_id      AS office_id,
         r.primary_party  AS primary_party,
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
  WHERE ( r.election_id IN (wi_eid, co_eid, al_gen_eid, al_withheld_eid, sc_eid, la_gen_eid, la_withheld_eid) )
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('55', '08', '01', '45', '22');

  -- ==========================================================================
  -- CRITERION 1 — exactly WI 8 + CO 8 + AL 7 + SC 7 + LA 6 = 36 distinct NATIONAL_LOWER races.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_wi_races FROM _house WHERE st = 'WI';
  SELECT COUNT(DISTINCT race_id) INTO v_co_races FROM _house WHERE st = 'CO';
  SELECT COUNT(DISTINCT race_id) INTO v_al_races FROM _house WHERE st = 'AL';
  SELECT COUNT(DISTINCT race_id) INTO v_sc_races FROM _house WHERE st = 'SC';
  SELECT COUNT(DISTINCT race_id) INTO v_la_races FROM _house WHERE st = 'LA';
  IF v_wi_races <> 8 THEN RAISE EXCEPTION 'FAIL scope: expected 8 WI NATIONAL_LOWER races, got %', v_wi_races; END IF;
  IF v_co_races <> 8 THEN RAISE EXCEPTION 'FAIL scope: expected 8 CO NATIONAL_LOWER races, got %', v_co_races; END IF;
  IF v_al_races <> 7 THEN RAISE EXCEPTION 'FAIL scope: expected 7 AL NATIONAL_LOWER races, got %', v_al_races; END IF;
  IF v_sc_races <> 7 THEN RAISE EXCEPTION 'FAIL scope: expected 7 SC NATIONAL_LOWER races, got %', v_sc_races; END IF;
  IF v_la_races <> 6 THEN RAISE EXCEPTION 'FAIL scope: expected 6 LA NATIONAL_LOWER races, got %', v_la_races; END IF;
  RAISE NOTICE 'PASS SCOPE: WI 8 + CO 8 + AL 7 + SC 7 + LA 6 = 36 distinct NATIONAL_LOWER races';

  -- ==========================================================================
  -- CRITERION 2 — every House race has office_id NOT NULL (all 36, incl. severe AL/LA).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_null_office FROM _house WHERE office_id IS NULL;
  IF v_null_office <> 0 THEN
    RAISE EXCEPTION 'FAIL NULLOFFICE: % of 36 Phase-163 House race(s) have NULL office_id', v_null_office;
  END IF;
  RAISE NOTICE 'PASS NULLOFFICE: 0 of 36 Phase-163 House races have NULL office_id (incl. the 3 withheld severe AL/LA races)';

  -- ==========================================================================
  -- CRITERION 3 — 0 active race_candidates with NULL politician_id.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_nullpid FROM _house WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL NULLPID: % active Phase-163 House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS NULLPID: 0 active WI/CO/AL/SC/LA House candidates with NULL politician_id';

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
  RAISE NOTICE 'PASS DUPNAME: 0 duplicate full_name within any state (WI/CO/AL/SC/LA) among active candidates';

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
  -- CRITERION 6 (NEW, AL-SEVERE) — AL severe-district non-surfacing invariant.
  --   AL-2 (geo 0102) race election_id MUST equal al_withheld_eid (leaked=0);
  --   the 6 non-severe AL geo_ids' race election_id MUST equal al_gen_eid (surfaced_ok=6).
  -- ==========================================================================
  SELECT COUNT(DISTINCT geo_id) INTO v_al_leaked
  FROM _house
  WHERE st = 'AL'
    AND geo_id = '0102'
    AND race_election_id <> al_withheld_eid;
  IF v_al_leaked <> 0 THEN
    RAISE EXCEPTION 'FAIL AL-SEVERE-WITHHELD: severe AL-2 (0102) race wired to a surfacing election (expected -> Polygon Pending)';
  END IF;

  SELECT COUNT(DISTINCT geo_id) INTO v_al_surfaced_ok
  FROM _house
  WHERE st = 'AL'
    AND geo_id = ANY(ARRAY['0101', '0103', '0104', '0105', '0106', '0107'])
    AND race_election_id = al_gen_eid;
  IF v_al_surfaced_ok <> 6 THEN
    RAISE EXCEPTION 'FAIL AL-NONSEVERE-SURFACING: expected all 6 non-severe AL districts wired to AL 2026 Statewide General, got %', v_al_surfaced_ok;
  END IF;
  RAISE NOTICE 'PASS AL-SEVERE: AL-2 (0102) -> Polygon Pending (withheld); all 6 non-severe (0101/0103/0104/0105/0106/0107) -> AL 2026 Statewide General (surfacing)';

  -- ==========================================================================
  -- CRITERION 7 (NEW, LA-SEVERE) — LA severe-district non-surfacing + jungle-model invariant.
  --   LA-2 (2202) + LA-6 (2206) race election_id MUST equal la_withheld_eid (leaked=0);
  --   the 4 non-severe LA geo_ids' race election_id MUST equal la_gen_eid (surfaced_ok=4).
  --   PLUS: every LA race primary_party IS NULL (jungle), and no Dec-2026 LA runoff election exists.
  -- ==========================================================================
  SELECT COUNT(DISTINCT geo_id) INTO v_la_leaked
  FROM _house
  WHERE st = 'LA'
    AND geo_id = ANY(ARRAY['2202', '2206'])
    AND race_election_id <> la_withheld_eid;
  IF v_la_leaked <> 0 THEN
    RAISE EXCEPTION 'FAIL LA-SEVERE-WITHHELD: % severe LA race(s) wired to a surfacing election (expected both 2202/2206 -> Polygon Pending)', v_la_leaked;
  END IF;

  SELECT COUNT(DISTINCT geo_id) INTO v_la_surfaced_ok
  FROM _house
  WHERE st = 'LA'
    AND geo_id = ANY(ARRAY['2201', '2203', '2204', '2205'])
    AND race_election_id = la_gen_eid;
  IF v_la_surfaced_ok <> 4 THEN
    RAISE EXCEPTION 'FAIL LA-NONSEVERE-SURFACING: expected all 4 non-severe LA districts wired to LA 2026 Statewide General, got %', v_la_surfaced_ok;
  END IF;

  -- jungle-model: every LA race primary_party IS NULL
  SELECT COUNT(DISTINCT race_id) INTO v_la_party FROM _house WHERE st = 'LA' AND primary_party IS NOT NULL;
  IF v_la_party <> 0 THEN
    RAISE EXCEPTION 'FAIL LA-JUNGLE: % LA race(s) have a non-NULL primary_party (jungle-model requires all NULL)', v_la_party;
  END IF;

  -- no December-2026 LA runoff election row (contingent runoff not seeded)
  SELECT COUNT(*) INTO v_la_runoff
  FROM essentials.elections
  WHERE name LIKE 'LA %'
    AND (name ILIKE '%runoff%' OR (election_date >= DATE '2026-12-01' AND election_date < DATE '2027-01-01'));
  IF v_la_runoff <> 0 THEN
    RAISE EXCEPTION 'FAIL LA-RUNOFF: % December-2026 LA runoff election row(s) exist (expected 0 -- contingent runoff not seeded)', v_la_runoff;
  END IF;
  RAISE NOTICE 'PASS LA-SEVERE: LA-2/LA-6 (2202/2206) -> Polygon Pending (withheld); 4 non-severe (2201/2203/2204/2205) -> LA 2026 Statewide General; all 6 LA races primary_party NULL (jungle); no Dec-2026 runoff';

  -- ==========================================================================
  -- CRITERION 8 (NEW, CO1-DEGETTE) — CO-1 (geo 0801) has exactly 2 active candidates and
  --   DeGette (pid 610bb358-...) is absent (she lost the CO-1 Democratic primary).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_co1_active
  FROM _house
  WHERE st = 'CO' AND geo_id = '0801' AND candidate_status = 'active';
  IF v_co1_active <> 2 THEN
    RAISE EXCEPTION 'FAIL CO1-DEGETTE: CO-1 (0801) has % active candidate(s) (expected exactly 2)', v_co1_active;
  END IF;

  SELECT COUNT(*) INTO v_co1_degette
  FROM _house
  WHERE st = 'CO' AND geo_id = '0801'
    AND politician_id = '610bb358-bae9-4ce8-beaf-a33a27d5ba49';
  IF v_co1_degette <> 0 THEN
    RAISE EXCEPTION 'FAIL CO1-DEGETTE: DeGette (610bb358) has % row(s) in CO-1 (expected 0 -- lost primary, not a candidate)', v_co1_degette;
  END IF;
  RAISE NOTICE 'PASS CO1-DEGETTE: CO-1 (0801) has exactly 2 active candidates and DeGette (610bb358) is absent';

  -- ==========================================================================
  -- New-candidate (Phase-163 external_id band, ACTIVE only) working sets per state.
  --   WI -550899..-550101   CO -80899..-80101   AL -10799..-10101   SC -450799..-450101   LA -220699..-220101
  --   (Reused incumbents carry their pre-existing external_ids, out of these bands.)
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.st, h.politician_id, h.external_id
  FROM _house h
  WHERE h.candidate_status = 'active'
    AND ( (h.st = 'WI' AND h.external_id BETWEEN -550899 AND -550101)
       OR (h.st = 'CO' AND h.external_id BETWEEN -80899  AND -80101)
       OR (h.st = 'AL' AND h.external_id BETWEEN -10799  AND -10101)
       OR (h.st = 'SC' AND h.external_id BETWEEN -450799 AND -450101)
       OR (h.st = 'LA' AND h.external_id BETWEEN -220699 AND -220101) );

  -- ==========================================================================
  -- Whole-record stance honest-skip pins (_stance_skip, by politician_id, ORDER BY politician_id).
  --   WI 1 / CO 0 / AL 1 / SC 3 / LA 5 = 10. Full trails: 163-07/08/09/10-SUMMARY.md + _SKIPS.md.
  -- ==========================================================================
  CREATE TEMP TABLE _stance_skip (politician_id uuid, external_id bigint, reason text) ON COMMIT DROP;
  INSERT INTO _stance_skip (politician_id, external_id, reason)
  SELECT p.id, p.external_id, v.reason
  FROM (VALUES
    -- WI (163-07): 1 whole-record skip
    (-550402::bigint, 'Purnima Nath WI-4 (R) -- identity/culture-war site content, nothing maps to the 24 federal topics'),
    -- AL (163-08): 1 whole-record skip
    (-10101, 'Lucas Burger AL-1 (R) -- no campaign site; Ballotpedia/BallotReady/GoodParty profiles empty of policy content'),
    -- SC (163-10): 3 whole-record skips
    (-450104, 'Margo Ellis SC-1 (Alliance) -- no site, Ballotpedia blank, trackers stubs, dormant socials'),
    (-450202, 'Dayna Alane Smith SC-2 (Workers) -- only evidence was the SC Workers Party platform (party-inference; operator-ruled skip 2026-07-06)'),
    (-450402, 'Jessica Ethridge SC-4 (Libertarian) -- 3-plank Wix template too vague to pin; 2022 Lt-Gov positions do not map to the 24 keys'),
    -- LA (163-09): 5 whole-record skips
    (-220101, 'Randall Arrington LA-1 (R) -- only party self-ID, no policy content; no site, trackers "no positions"'),
    (-220102, 'Jim Long LA-1 (D) -- zero issue content anywhere; collision-avoided a diff-spelled "Jim Lange"'),
    (-220201, 'Renada Collins LA-2 (D) -- one-page shell site (/issues,/platform,/about all 404); one dignity quote, no scale fit'),
    (-220303, 'Caleb Walker LA-3 -- no site; socials login-walled; only an indirect "Patients Over Profits" pledge'),
    (-220604, 'Peter Williams LA-6 (R) -- identity well-verified but only generic constituent-advocacy language, no scale-mappable specifics')
  ) AS v(external_id, reason)
  JOIN essentials.politicians p ON p.external_id = v.external_id
  ORDER BY p.id;

  -- ==========================================================================
  -- Headshot honest-skip pins (_img_skip, by external_id, ORDER BY external_id).
  --   95 total: WI 27 + CO 7 + AL 20 + SC 15 + LA 26. Reconstructed live 2026-07-06.
  --   (Edmonds appears as -220605, post-mig-1230 re-key.)
  -- ==========================================================================
  CREATE TEMP TABLE _img_skip (external_id bigint) ON COMMIT DROP;
  INSERT INTO _img_skip (external_id) VALUES
    -- WI (27)
    (-550803),(-550802),(-550801),(-550707),(-550706),(-550705),(-550704),(-550703),(-550702),(-550701),
    (-550605),(-550604),(-550603),(-550602),(-550601),(-550501),(-550404),(-550403),(-550402),(-550401),
    (-550303),(-550301),(-550201),(-550104),(-550103),(-550102),(-550101),
    -- SC (15)
    (-450701),(-450602),(-450601),(-450503),(-450502),(-450501),(-450402),(-450401),(-450302),(-450301),
    (-450202),(-450201),(-450104),(-450103),(-450101),
    -- LA (26)
    (-220605),(-220604),(-220603),(-220602),(-220601),(-220513),(-220512),(-220511),(-220510),(-220509),
    (-220508),(-220507),(-220506),(-220505),(-220504),(-220501),(-220404),(-220403),(-220402),(-220401),
    (-220303),(-220302),(-220301),(-220201),(-220102),(-220101),
    -- CO (7)
    (-80701),(-80601),(-80501),(-80401),(-80301),(-80201),(-80102),
    -- AL (20)
    (-10702),(-10701),(-10605),(-10604),(-10603),(-10602),(-10601),(-10501),(-10401),(-10301),
    (-10206),(-10205),(-10204),(-10203),(-10202),(-10201),(-10105),(-10104),(-10103),(-10101);

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
    RAISE EXCEPTION 'FAIL HEADSHOT: % active new WI/CO/AL/SC/LA candidate(s) lack a politician_images row and are not pinned: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS HEADSHOT: every active new WI/CO/AL/SC/LA candidate has a politician_images row or a pinned honest-skip (95 pinned)';

  -- ==========================================================================
  -- USHC3-05a — 0 unsourced stance rows for ALL active in-scope politicians (challengers
  --   AND incumbents) across the 5 states' House races.
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
    RAISE EXCEPTION 'FAIL UNSOURCED: % unsourced stance row(s) in the in-scope WI/CO/AL/SC/LA House candidate set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS UNSOURCED: 0 unsourced stance rows for the in-scope WI/CO/AL/SC/LA House candidate set (challengers + incumbents)';

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
  RAISE NOTICE 'PASS COVERAGE: every in-scope WI/CO/AL/SC/LA new candidate has >=1 sourced stance or is a pinned whole-record honest-skip (10 pinned)';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC3-02/03/04/05, 36 districts: WI 8 / CO 8 / AL 7 / SC 7 / LA 6; AL+LA severe withholding + LA jungle-model + CO-1 DeGette exclusion verified)';
END $$;
