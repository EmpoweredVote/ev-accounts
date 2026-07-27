-- 166-verify.sql — Phase 166 read-only PRODUCTION gate: the milestone-level structural
-- assertion for USHC3-06 across all 178 Wave-3 US House districts (38 states).
--
-- This is the ASSERTION half of the milestone proof. Its siblings:
--   * backend/scripts/166-verify-invariants.sql — the fifteen per-phase invariants inherited
--     from phases 161 through 165 (plan 166-04)
--   * backend/scripts/166-coordinate-smoke.ts   — the coordinate-path proof (plan 166-02)
-- They are split so each file is authorable in one pass and independently runnable.
--
-- WRITE-FREE against production: the only writes are `CREATE TEMP TABLE ... ON COMMIT DROP`
-- and UPDATEs against those temp tables. No DML whatsoever against essentials or inform.
--
-- SCOPE — 43 elections, not the 42 the plan was written against. 166-01 derived the universe
--   LIVE on 2026-07-26 and found that 'WI 2026 Partisan Primary' (election row created
--   2026-07-25, contest 2026-08-11) now holds WI's field: 32 active candidates including 7
--   incumbents, while the 'WI 2026 Statewide General' holds 5 with 4 of its 8 races empty.
--   Scoping WI to its general alone would assert coverage over 5 candidates and silently ignore
--   32. IN and UT also have House primary races, but theirs are PAST (2026-05-05, 2026-06-23)
--   and hold only concluded contests, so they stay out. Full rationale: 166-01-SUMMARY.md.
--
-- DISTRICTS, NOT RACES — the 178 assertion counts DISTINCT geo_id. Those coincided in every
--   prior gate because each state ran one race per district; WI now runs three (general plus
--   two party primaries), so the 178 districts carry 194 races. Race counts are reported.
--
-- PINS — every _img_skip / _stance_skip / _stance_queue_167 id below is pasted VERBATIM from
--   backend/scripts/166-pins.generated.sql, whose header records the 2026-07-26 derivation and
--   the full delta against the 566 frozen headshot pins and 124 frozen stance pins. Nothing here
--   is inherited from an early-July snapshot without having been re-confirmed live.
--
-- The is_vacant trap (CLAUDE.md): this gate filters on `offices.is_vacant` NOWHERE. Filtering it
--   on a downstream join rather than the match emits a spurious all-NULL office row.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/166-verify.sql

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_cnt int; v_detail text; v_races int; v_districts int;
  v_noactive int; v_thin int; v_emptyrace int; v_empty_detail text;
  v_null_office int; v_nullpid int; v_dupname int; v_dupinc int; v_rcdup int; v_party_cols int;
  v_prov_bad int; v_prov_detail text; v_prov_marked int; v_prov_unmarked int; v_prov_excl int;
  v_no_image int; v_image_detail text;
  v_unsourced int;
  v_uncovered int; v_cov_detail text; v_pin_skip int; v_pin_queue int;
BEGIN
  -- ==========================================================================
  -- Resolve the 43 in-scope elections by EXACT name. Raise naming every offender.
  -- ==========================================================================
  CREATE TEMP TABLE _elections ON COMMIT DROP AS
  SELECT v.name, e.id
  FROM (VALUES
    -- 38 state general elections. Five names deviate from the '{ABBR} 2026 Statewide General'
    -- convention because those elections were PRE-EXISTING and reused rather than authored:
    -- MA (161), MD (162-08), OR (164-03), ME and NV (165-01).
    ('AZ 2026 Statewide General'),('WA 2026 Statewide General'),('TN 2026 Statewide General'),
    ('2026 Massachusetts General Election'),('IN 2026 Statewide General'),
    ('2026 Maryland General Election'),('MN 2026 Statewide General'),('MO 2026 Statewide General'),
    ('WI 2026 Statewide General'),('CO 2026 Statewide General'),('AL 2026 Statewide General'),
    ('SC 2026 Statewide General'),('LA 2026 Statewide General'),('KY 2026 Statewide General'),
    ('OR 2026 General'),('CT 2026 Statewide General'),('OK 2026 Statewide General'),
    ('AR 2026 Statewide General'),('IA 2026 Statewide General'),('KS 2026 Statewide General'),
    ('MS 2026 Statewide General'),('NV 2026 Statewide General'),('UT 2026 Statewide General'),
    ('NM 2026 Statewide General'),('NE 2026 Statewide General'),('WV 2026 Statewide General'),
    ('ID 2026 Statewide General'),('HI 2026 Statewide General'),('2026 Maine General Election'),
    ('NH 2026 Statewide General'),('RI 2026 Statewide General'),('MT 2026 Statewide General'),
    ('AK 2026 Statewide General'),('DE 2026 Statewide General'),('ND 2026 Statewide General'),
    ('SD 2026 Statewide General'),('VT 2026 Statewide General'),('WY 2026 Statewide General'),
    -- 4 withheld Polygon Pending markers (migs 1247/1248/1249 emptied TN, AL and LA).
    ('TN 2026 Congressional Redistricting - Polygon Pending'),
    ('MO 2026 Congressional Redistricting - Polygon Pending'),
    ('AL 2026 Congressional Redistricting - Polygon Pending'),
    ('LA 2026 Congressional Redistricting - Polygon Pending'),
    -- 1 live scope correction (166-01): WI's field moved here on 2026-07-25.
    ('WI 2026 Partisan Primary')
  ) AS v(name)
  LEFT JOIN essentials.elections e ON e.name = v.name;

  SELECT COUNT(*), string_agg(name, ', ' ORDER BY name) INTO v_cnt, v_detail
  FROM _elections WHERE id IS NULL;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'FAIL setup: % of 43 election name(s) did not resolve: %', v_cnt, v_detail;
  END IF;
  SELECT COUNT(*) INTO v_cnt FROM _elections;
  IF v_cnt <> 43 THEN RAISE EXCEPTION 'FAIL setup: % election rows (exp 43)', v_cnt; END IF;

  -- ==========================================================================
  -- Combined Phase-166 House working set. State derived from substr(geo_id,1,2) through a
  -- FIPS map — 43 elections make the CASE-on-election_id form used by 152 and 162 unmanageable.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE substr(d.geo_id,1,2)
           WHEN '04' THEN 'AZ' WHEN '53' THEN 'WA' WHEN '47' THEN 'TN' WHEN '25' THEN 'MA'
           WHEN '18' THEN 'IN' WHEN '24' THEN 'MD' WHEN '27' THEN 'MN' WHEN '29' THEN 'MO'
           WHEN '55' THEN 'WI' WHEN '08' THEN 'CO' WHEN '01' THEN 'AL' WHEN '45' THEN 'SC'
           WHEN '22' THEN 'LA' WHEN '21' THEN 'KY' WHEN '41' THEN 'OR' WHEN '09' THEN 'CT'
           WHEN '40' THEN 'OK' WHEN '05' THEN 'AR' WHEN '19' THEN 'IA' WHEN '20' THEN 'KS'
           WHEN '28' THEN 'MS' WHEN '32' THEN 'NV' WHEN '49' THEN 'UT' WHEN '35' THEN 'NM'
           WHEN '31' THEN 'NE' WHEN '54' THEN 'WV' WHEN '16' THEN 'ID' WHEN '15' THEN 'HI'
           WHEN '23' THEN 'ME' WHEN '33' THEN 'NH' WHEN '44' THEN 'RI' WHEN '30' THEN 'MT'
           WHEN '02' THEN 'AK' WHEN '10' THEN 'DE' WHEN '38' THEN 'ND' WHEN '46' THEN 'SD'
           WHEN '50' THEN 'VT' ELSE 'WY' END AS st,
         r.id AS race_id, r.election_id AS race_election_id, r.office_id, r.description,
         r.primary_party, d.geo_id, rc.id AS rc_id, rc.politician_id, rc.full_name,
         rc.candidate_status, rc.is_incumbent, p.external_id
  FROM essentials.races r
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.politicians     p  ON p.id = rc.politician_id
  WHERE r.election_id IN (SELECT id FROM _elections)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('04','53','47','25','18','24','27','29','55','08','01','45',
                                   '22','21','41','09','40','05','19','20','28','32','49','35',
                                   '31','54','16','15','23','33','44','30','02','10','38','46',
                                   '50','56');

  -- ==========================================================================
  -- CRITERION 1 (SCOPE) — 178 distinct NATIONAL_LOWER DISTRICTS with the per-state
  --   decomposition. Counted by distinct geo_id, not race_id: WI runs 3 races per district.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(q.st || ':' || q.n, ', ' ORDER BY q.st) INTO v_cnt, v_detail FROM (
    SELECT st, COUNT(DISTINCT geo_id) AS n FROM _house GROUP BY st
  ) q
  WHERE (q.st='WA' AND q.n<>10) OR (q.st='AZ' AND q.n<>9)  OR (q.st='TN' AND q.n<>9)
     OR (q.st='MA' AND q.n<>9)  OR (q.st='IN' AND q.n<>9)  OR (q.st='MD' AND q.n<>8)
     OR (q.st='MN' AND q.n<>8)  OR (q.st='MO' AND q.n<>8)  OR (q.st='WI' AND q.n<>8)
     OR (q.st='CO' AND q.n<>8)  OR (q.st='AL' AND q.n<>7)  OR (q.st='SC' AND q.n<>7)
     OR (q.st='LA' AND q.n<>6)  OR (q.st='KY' AND q.n<>6)  OR (q.st='OR' AND q.n<>6)
     OR (q.st='CT' AND q.n<>5)  OR (q.st='OK' AND q.n<>5)  OR (q.st='AR' AND q.n<>4)
     OR (q.st='IA' AND q.n<>4)  OR (q.st='KS' AND q.n<>4)  OR (q.st='MS' AND q.n<>4)
     OR (q.st='NV' AND q.n<>4)  OR (q.st='UT' AND q.n<>4)  OR (q.st='NM' AND q.n<>3)
     OR (q.st='NE' AND q.n<>3)  OR (q.st='WV' AND q.n<>2)  OR (q.st='ID' AND q.n<>2)
     OR (q.st='HI' AND q.n<>2)  OR (q.st='ME' AND q.n<>2)  OR (q.st='NH' AND q.n<>2)
     OR (q.st='RI' AND q.n<>2)  OR (q.st='MT' AND q.n<>2)  OR (q.st='AK' AND q.n<>1)
     OR (q.st='DE' AND q.n<>1)  OR (q.st='ND' AND q.n<>1)  OR (q.st='SD' AND q.n<>1)
     OR (q.st='VT' AND q.n<>1)  OR (q.st='WY' AND q.n<>1);
  IF v_cnt<>0 THEN
    RAISE EXCEPTION 'FAIL SCOPE: % state(s) with wrong district count: %', v_cnt, v_detail;
  END IF;
  SELECT COUNT(DISTINCT geo_id), COUNT(DISTINCT race_id) INTO v_districts, v_races FROM _house;
  IF v_districts<>178 THEN
    RAISE EXCEPTION 'FAIL SCOPE: total districts=% (exp 178)', v_districts;
  END IF;
  RAISE NOTICE 'PASS SCOPE: 178 NATIONAL_LOWER districts across 38 states (WA10 AZ9 TN9 MA9 IN9 MD8 MN8 MO8 WI8 CO8 AL7 SC7 LA6 KY6 OR6 CT5 OK5 AR4 IA4 KS4 MS4 NV4 UT4 NM3 NE3 WV2 ID2 HI2 ME2 NH2 RI2 MT2 AK1 DE1 ND1 SD1 VT1 WY1), carried by % races over 43 elections', v_races;

  -- ==========================================================================
  -- CRITERION 2 (ACTIVE) — every one of the 178 DISTRICTS has >=1 active candidate.
  --   Asserted per district, not per race: WI's field sits on its primary races, leaving 5 of
  --   its 8 general races empty. A per-race assertion would fail on a district that is in fact
  --   fully covered. The empty races are reported below as a NOTICE so the fact stays visible.
  --   Districts with <2 active are the uncontested-seat allowance carried from 152 — a NOTICE,
  --   never a failure.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_noactive FROM (
    SELECT geo_id FROM _house GROUP BY geo_id
    HAVING COUNT(*) FILTER (WHERE candidate_status='active') = 0
  ) q;
  IF v_noactive<>0 THEN
    RAISE EXCEPTION 'FAIL ACTIVE: % district(s) with 0 active candidates', v_noactive;
  END IF;
  SELECT COUNT(*) INTO v_thin FROM (
    SELECT geo_id FROM _house GROUP BY geo_id
    HAVING COUNT(*) FILTER (WHERE candidate_status='active') < 2
  ) q;
  SELECT COUNT(*), string_agg(q.geo_id, ', ' ORDER BY q.geo_id) INTO v_emptyrace, v_empty_detail FROM (
    SELECT race_id, min(geo_id) AS geo_id FROM _house GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status='active') = 0
  ) q;
  RAISE NOTICE 'PASS ACTIVE: all 178 districts have >=1 active candidate; % with <2 (uncontested-seat allowance, not a failure)', v_thin;
  IF v_emptyrace > 0 THEN
    RAISE NOTICE 'NOTE ACTIVE: % in-scope race(s) hold 0 active candidates (geo_ids %) — expected: WI''s field moved to WI 2026 Partisan Primary on 2026-07-25, leaving its general races empty. Every district is still covered.', v_emptyrace, v_empty_detail;
  END IF;

  -- ==========================================================================
  -- CRITERION 3 (NULLOFFICE) — 0 races with NULL office_id.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_null_office FROM _house WHERE office_id IS NULL;
  IF v_null_office<>0 THEN
    RAISE EXCEPTION 'FAIL NULLOFFICE: % race(s) with NULL office_id', v_null_office;
  END IF;
  RAISE NOTICE 'PASS NULLOFFICE: 0 of % in-scope races have NULL office_id — including the 5 withheld severe MO races (2902-2906), whose office_id IS populated; only their election_id is withheld', v_races;

  -- ==========================================================================
  -- CRITERION 4 (NULLPID) — 0 active race_candidates with NULL politician_id.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status='active' AND politician_id IS NULL;
  IF v_nullpid<>0 THEN
    RAISE EXCEPTION 'FAIL NULLPID: % active candidate(s) with NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS NULLPID: 0 active candidates with NULL politician_id across all 178 districts';

  -- ==========================================================================
  -- CRITERION 5 (DUPNAME) — 0 duplicate lower(full_name) groups WITHIN a state among active
  --   candidates. Per-state only: a cross-state homonym is not a data error.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(q.st || ':' || q.nm, ', ') INTO v_dupname, v_detail FROM (
    SELECT st, lower(full_name) AS nm FROM _house WHERE candidate_status='active'
    GROUP BY st, lower(full_name) HAVING COUNT(DISTINCT race_id) > 1
  ) q;
  IF v_dupname<>0 THEN
    RAISE EXCEPTION 'FAIL DUPNAME: % duplicate full_name group(s) within a state: %', v_dupname, v_detail;
  END IF;
  RAISE NOTICE 'PASS DUPNAME: 0 duplicate full_name within any state among active candidates';

  -- ==========================================================================
  -- CRITERION 6 (DUPINCUMBENT) — NEW at Wave-3 scale (152 and 158 carry it; no per-state
  --   Wave-3 gate does). 0 politician_id active in 2 or more distinct races. Probed as a plain
  --   SELECT before being asserted (166-03 Task 1): returned 0 on 2026-07-26, confirming that
  --   WI's move to a primary election RELOCATED its field rather than duplicating it.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(q.politician_id::text, ', ') INTO v_dupinc, v_detail FROM (
    SELECT politician_id FROM _house
    WHERE candidate_status='active' AND politician_id IS NOT NULL
    GROUP BY politician_id HAVING COUNT(DISTINCT race_id) > 1
  ) q;
  IF v_dupinc<>0 THEN
    RAISE EXCEPTION 'FAIL DUPINCUMBENT: % politician(s) active in 2+ distinct races: %', v_dupinc, v_detail;
  END IF;
  RAISE NOTICE 'PASS DUPINCUMBENT: 0 politicians active in more than one in-scope race';

  -- ==========================================================================
  -- CRITERION 7 (RC-UNIQUE) — NEW; generalises 162's MD-DEDUP and 164's OR-REUSE duplicate
  --   clause to all 178 districts. Exactly 1 race_candidates row per (race_id, politician_id).
  --   Also probed as a plain SELECT first: returned 0.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(q.race_id::text || '/' || q.politician_id::text, ', ')
    INTO v_rcdup, v_detail FROM (
    SELECT race_id, politician_id FROM _house WHERE politician_id IS NOT NULL
    GROUP BY race_id, politician_id HAVING COUNT(*) > 1
  ) q;
  IF v_rcdup<>0 THEN
    RAISE EXCEPTION 'FAIL RC-UNIQUE: % duplicated (race_id, politician_id) pair(s): %', v_rcdup, v_detail;
  END IF;
  RAISE NOTICE 'PASS RC-UNIQUE: exactly 1 race_candidates row per (race_id, politician_id) across all 178 districts';

  -- ==========================================================================
  -- CRITERION 8 (PARTY) — antipartisan structural invariant. Party lives on
  --   races.primary_party (which ballot a voter requests), never on the candidate card.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_party_cols FROM information_schema.columns
  WHERE table_schema='essentials' AND table_name='race_candidates'
    AND column_name IN ('party','party_affiliation');
  IF v_party_cols<>0 THEN
    RAISE EXCEPTION 'FAIL PARTY: race_candidates has % party column(s)', v_party_cols;
  END IF;
  RAISE NOTICE 'PASS PARTY: race_candidates has no party/party_affiliation column';

  -- ==========================================================================
  -- CRITERION 9 (PROVISIONAL) — the census measured LIVE on 2026-07-26 by 166-01, taken
  --   verbatim from the 166-pins.generated.sql census header. Phases 161, 162 and 163 authored
  --   NO PROVISIONAL assertion at all, so nothing could be inherited; 164 and 165 measured
  --   theirs three weeks ago. Neither 164's CT+KS list nor 165's AK/HI/NH/RI/DE/VT/WY list is
  --   carried forward as if still authoritative.
  --
  --   Asserted per STATE as an exact (marked, unmarked) race-count pair rather than as two
  --   whole-state lists, because two states are SPLIT and a whole-state list cannot express
  --   them: WI is 8 marked (its general races) / 16 unmarked (its two party primaries), and
  --   AL is 4 marked / 3 unmarked. The pair form is strictly stronger than the 164/165 shape.
  --
  --   EXCLUDED from the assertion — 6 states whose PROVISIONAL wording is inherited from a
  --   REUSED pre-existing election rather than authored by this milestone, so its wording is
  --   not ours to assert: MA (161), MD (162-08), OR (164-03), ME and NV (165-01), and UT.
  --   165 documented the NV/UT/ME exclusion; MA/MD/OR follow by the same logic. Their measured
  --   counts are reported in the pass notice so the exclusion is a visible decision, never an
  --   omission.
  --
  --   PHASE 167 clears these flags per primary-date cluster as each state's primary passes.
  --   This assertion is therefore EXPECTED to need updating at each 167 cluster execution, and
  --   the correct update is to MOVE a state's counts between marked and unmarked — never to
  --   delete the assertion.
  -- ==========================================================================
  CREATE TEMP TABLE _prov_expect ON COMMIT DROP AS
  SELECT * FROM (VALUES
    ('AZ',9,0),('WA',10,0),('TN',9,0),('MN',8,0),('MO',8,0),('WI',8,16),('AL',4,3),
    ('LA',6,0),('CT',5,0),('KS',4,0),('HI',2,0),('NH',2,0),('RI',2,0),('AK',1,0),
    ('DE',1,0),('VT',1,0),('WY',1,0),
    ('IN',0,9),('CO',0,8),('SC',0,7),('KY',0,6),('OK',0,5),('AR',0,4),('IA',0,4),
    ('MS',0,4),('NM',0,3),('NE',0,3),('WV',0,2),('ID',0,2),('MT',0,2),('ND',0,1),('SD',0,1)
  ) AS v(st, exp_marked, exp_unmarked);

  CREATE TEMP TABLE _prov_actual ON COMMIT DROP AS
  SELECT q.st,
         COUNT(*) FILTER (WHERE q.marked)     ::int AS act_marked,
         COUNT(*) FILTER (WHERE NOT q.marked) ::int AS act_unmarked
  FROM (
    SELECT DISTINCT race_id, st, (coalesce(description,'') LIKE '%PROVISIONAL:%') AS marked
    FROM _house
  ) q
  GROUP BY q.st;

  SELECT COUNT(*), string_agg(
           e.st || ' expected ' || e.exp_marked || 'm/' || e.exp_unmarked || 'u but found ' ||
           coalesce(a.act_marked,0) || 'm/' || coalesce(a.act_unmarked,0) || 'u', '; ' ORDER BY e.st)
    INTO v_prov_bad, v_prov_detail
  FROM _prov_expect e
  LEFT JOIN _prov_actual a ON a.st = e.st
  WHERE coalesce(a.act_marked,0) <> e.exp_marked OR coalesce(a.act_unmarked,0) <> e.exp_unmarked;
  IF v_prov_bad<>0 THEN
    RAISE EXCEPTION 'FAIL PROVISIONAL: % state(s) drifted from the 2026-07-26 census: %', v_prov_bad, v_prov_detail;
  END IF;

  SELECT COALESCE(SUM(exp_marked),0), COALESCE(SUM(exp_unmarked),0) INTO v_prov_marked, v_prov_unmarked
  FROM _prov_expect;
  SELECT COUNT(DISTINCT race_id) INTO v_prov_excl FROM _house
  WHERE st IN ('MA','MD','OR','ME','NV','UT');
  IF v_prov_marked + v_prov_unmarked + v_prov_excl <> v_races THEN
    RAISE EXCEPTION 'FAIL PROVISIONAL: marked % + unmarked % + excluded % <> % in-scope races',
      v_prov_marked, v_prov_unmarked, v_prov_excl, v_races;
  END IF;
  RAISE NOTICE 'PASS PROVISIONAL: % marked + % unmarked asserted across 32 states (WI split 8m/16u, AL split 4m/3u); % races EXCLUDED across MA/MD/OR/ME/NV/UT because their PROVISIONAL wording is inherited from reused pre-existing elections, not authored here; % + % + % = % in-scope races over 178 districts',
    v_prov_marked, v_prov_unmarked, v_prov_excl, v_prov_marked, v_prov_unmarked, v_prov_excl, v_races;

  -- ==========================================================================
  -- New-candidate working set — the 38 Phase-166 external_id bands, scoped THROUGH _house so
  --   polluted-band legacy records never enter (CLAUDE.md: bands can be polluted; scope via
  --   race_candidates joins, not raw band). Uses the SUPERSET candidate_status='active' filter
  --   that 161-164 used, not 165's stricter active+is_incumbent=false: 166-01 measured the
  --   difference at 13 active incumbents (12 of them cross-state band collisions) and the
  --   superset is the safe direction, demanding an image-or-pin from strictly more candidates.
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.st, h.politician_id, h.external_id
  FROM _house h
  WHERE h.candidate_status='active' AND h.politician_id IS NOT NULL AND h.external_id IS NOT NULL
    AND ( (h.external_id BETWEEN -40901  AND -40101)  OR (h.external_id BETWEEN -531005 AND -530101)
       OR (h.external_id BETWEEN -470910 AND -470101) OR (h.external_id BETWEEN -250902 AND -250101)
       OR (h.external_id BETWEEN -180999 AND -180101) OR (h.external_id BETWEEN -240899 AND -240101)
       OR (h.external_id BETWEEN -270899 AND -270101) OR (h.external_id BETWEEN -290899 AND -290101)
       OR (h.external_id BETWEEN -550899 AND -550101) OR (h.external_id BETWEEN -80899  AND -80101)
       OR (h.external_id BETWEEN -10799  AND -10101)  OR (h.external_id BETWEEN -450799 AND -450101)
       OR (h.external_id BETWEEN -220699 AND -220101) OR (h.external_id BETWEEN -210899 AND -210101)
       OR (h.external_id BETWEEN -410699 AND -410101) OR (h.external_id BETWEEN -90599  AND -90101)
       OR (h.external_id BETWEEN -400599 AND -400101) OR (h.external_id BETWEEN -50499  AND -50101)
       OR (h.external_id BETWEEN -190499 AND -190101) OR (h.external_id BETWEEN -200499 AND -200101)
       OR (h.external_id BETWEEN -280499 AND -280101) OR (h.external_id BETWEEN -320499 AND -320101)
       OR (h.external_id BETWEEN -490499 AND -490101) OR (h.external_id BETWEEN -20099  AND -20001)
       OR (h.external_id BETWEEN -350399 AND -350101) OR (h.external_id BETWEEN -310399 AND -310101)
       OR (h.external_id BETWEEN -540299 AND -540101) OR (h.external_id BETWEEN -160299 AND -160101)
       OR (h.external_id BETWEEN -150299 AND -150101) OR (h.external_id BETWEEN -230299 AND -230101)
       OR (h.external_id BETWEEN -330299 AND -330101) OR (h.external_id BETWEEN -440299 AND -440101)
       OR (h.external_id BETWEEN -300299 AND -300101) OR (h.external_id BETWEEN -100099 AND -100001)
       OR (h.external_id BETWEEN -380099 AND -380001) OR (h.external_id BETWEEN -460099 AND -460001)
       OR (h.external_id BETWEEN -500099 AND -500001) OR (h.external_id BETWEEN -560099 AND -560001) );

  -- ==========================================================================
  -- Pin tables. The three INSERT blocks below are pasted VERBATIM from
  -- backend/scripts/166-pins.generated.sql (166-01 Task 3). politician_id is resolved after
  -- the inserts, so the fragment stays byte-identical to its source.
  -- ==========================================================================
  CREATE TEMP TABLE _img_skip         (external_id bigint) ON COMMIT DROP;
  CREATE TEMP TABLE _stance_skip      (external_id bigint, reason text, politician_id uuid) ON COMMIT DROP;
  CREATE TEMP TABLE _stance_queue_167 (external_id bigint, reason text, politician_id uuid) ON COMMIT DROP;

-- === 166 CENSUS HEADER ===
-- Generated by backend/scripts/166-derive-pins.ts against production on 2026-07-26.
-- Read-only derivation. Pasted verbatim into 166-verify.sql (166-03) and consumed by
-- 166-verify-invariants.sql (166-04). Contains only comments and INSERTs into the three
-- temp tables the gate declares; no DDL of its own, and nothing that writes essentials/inform.
--
-- SCOPE: 43 elections — 38 state generals, 4 Polygon Pending markers, and
--   'WI 2026 Partisan Primary'. That last one is a LIVE CORRECTION to the 42 the plan
--   listed from the 163 snapshot: the WI primary election row was created 2026-07-25 and
--   now holds WI's field (32 active, 7 incumbents) while the WI general holds 5 with 4 of
--   8 races empty. IN and UT also have House primaries, but theirs are past (2026-05-05,
--   2026-06-23) and hold only concluded contests, so they stay out.
--
-- 1. PER-STATE DISTRICT CENSUS (districts / races / active / banded-new)
--   AZ 04: 9 districts / 9 races / 31 active / 24 banded-new
--   WA 53: 10 districts / 10 races / 69 active / 60 banded-new
--   TN 47: 9 districts / 9 races / 80 active / 73 banded-new
--   MA 25: 9 districts / 9 races / 26 active / 26 banded-new
--   IN 18: 9 districts / 9 races / 21 active / 12 banded-new
--   MD 24: 8 districts / 8 races / 20 active / 12 banded-new
--   MN 27: 8 districts / 8 races / 42 active / 35 banded-new
--   MO 29: 8 districts / 8 races / 65 active / 58 banded-new
--   WI 55: 8 districts / 24 races / 37 active / 30 banded-new
--   CO 08: 8 districts / 8 races / 16 active / 9 banded-new
--   AL 01: 7 districts / 7 races / 27 active / 21 banded-new
--   SC 45: 7 districts / 7 races / 21 active / 16 banded-new
--   LA 22: 6 districts / 6 races / 32 active / 27 banded-new
--   KY 21: 6 districts / 6 races / 19 active / 15 banded-new
--   OR 41: 6 districts / 6 races / 13 active / 6 banded-new
--   CT 09: 5 districts / 5 races / 22 active / 17 banded-new
--   OK 40: 5 districts / 5 races / 14 active / 10 banded-new
--   AR 05: 4 districts / 4 races / 10 active / 6 banded-new
--   IA 19: 4 districts / 4 races / 11 active / 9 banded-new
--   KS 20: 4 districts / 4 races / 26 active / 26 banded-new
--   MS 28: 4 districts / 4 races / 12 active / 8 banded-new
--   NV 32: 4 districts / 4 races / 14 active / 6 banded-new
--   UT 49: 4 districts / 4 races / 19 active / 12 banded-new
--   NM 35: 3 districts / 3 races / 6 active / 3 banded-new
--   NE 31: 3 districts / 3 races / 9 active / 7 banded-new
--   WV 54: 2 districts / 2 races / 7 active / 5 banded-new
--   ID 16: 2 districts / 2 races / 10 active / 8 banded-new
--   HI 15: 2 districts / 2 races / 15 active / 13 banded-new
--   ME 23: 2 districts / 2 races / 4 active / 3 banded-new
--   NH 33: 2 districts / 2 races / 20 active / 19 banded-new
--   RI 44: 2 districts / 2 races / 6 active / 4 banded-new
--   MT 30: 2 districts / 2 races / 6 active / 5 banded-new
--   AK 02: 1 districts / 1 races / 15 active / 14 banded-new
--   DE 10: 1 districts / 1 races / 2 active / 1 banded-new
--   ND 38: 1 districts / 1 races / 2 active / 1 banded-new
--   SD 46: 1 districts / 1 races / 2 active / 1 banded-new
--   VT 50: 1 districts / 1 races / 4 active / 3 banded-new
--   WY 56: 1 districts / 1 races / 14 active / 13 banded-new
--   TOTAL DISTRICTS: 178 (across 194 races)
--
-- 2. BAND FILTER DELTA
--   active=618 vs active+is_incumbent=false=605; difference=13, all active incumbents.
--   The gate uses the SUPERSET (active) form 161-164 used, not 165's stricter form:
--   a superset demands an image-or-pin from strictly more candidates. 12 of the difference
--   are cross-state band collisions (4 KS incumbents inside AK's band, 8 MA inside KS's);
--   all entered via the race_candidates join, so all are legitimately in scope.
--
-- 3. HEADSHOT DELTA
--   live=51 vs frozen 566 (161:167 + 162:110 + 163:95 + 164:85 + 165:109)
--   dropped=517 (acquired an image, or no longer active/in-band); added=2
--
-- 4. STANCE PIN PARTITION
--   surviving=123 of frozen 124 (reasons carried VERBATIM from the source gates)
--   retired=1; queue_167=2
--   queue_167 candidates are 0-stance TODAY but carry no documented search trail. They are
--   deliberately NOT merged into _stance_skip — nobody made that research judgment.
--
-- 5. PROVISIONAL CENSUS (asserts TODAY; Phase 167 clears flags per primary-date cluster,
--    so states will move between these two lists)
--   marked:   AZ:9 WA:10 TN:9 MA:9 MN:8 MO:8 WI:8 AL:4 LA:6 CT:5 KS:4 HI:2 NH:2 RI:2 AK:1 DE:1 VT:1 WY:1
--   unmarked: IN:9 MD:8 WI:16 CO:8 AL:3 SC:7 KY:6 OR:6 OK:5 AR:4 IA:4 MS:4 NV:4 UT:4 NM:3 NE:3 WV:2 ID:2 ME:2 MT:2 ND:1 SD:1
--
-- 6. WITHHELD CENSUS (Polygon Pending markers; migrations 1247/1248/1249 emptied TN/AL/LA)
--   TN: 0 race(s)
--   MO: 5 race(s) — geo_ids 2902, 2903, 2904, 2905, 2906
--   AL: 0 race(s)
--   LA: 0 race(s)
-- === END 166 CENSUS HEADER ===

-- Headshot honest-skips: 51 banded active candidates with no
-- essentials.politician_images row, regenerated live (pure derivation, not judgment).
-- Grouped by state in Wave-3 order; within a group ordered by external_id DESCENDING,
-- which reads as ascending district then seq. Ten ids per line.
INSERT INTO _img_skip (external_id) VALUES
  -- WA (1)
  (-530101),
  -- TN (12)
  (-470106),(-470107),(-470108),(-470302),(-470305),(-470306),(-470507),(-470508),(-470705),(-470807),
  (-470810),(-470910),
  -- MA (2)
  (-250301),(-250902),
  -- MD (3)
  (-240502),(-240503),(-240802),
  -- MN (6)
  (-270101),(-270103),(-270207),(-270501),(-270505),(-270601),
  -- MO (4)
  (-290103),(-290207),(-290302),(-290407),
  -- WI (3)
  (-550304),(-550404),(-550708),
  -- SC (1)
  (-450104),
  -- LA (1)
  (-220102),
  -- KY (1)
  (-210403),
  -- OR (1)
  (-410301),
  -- CT (1)
  (-90403),
  -- OK (2)
  (-400402),(-400503),
  -- KS (3)
  (-200212),(-200304),(-200410),
  -- MS (1)
  (-280102),
  -- NV (1)
  (-320480),
  -- WV (2)
  (-540102),(-540202),
  -- MT (1)
  (-300103),
  -- AK (3)
  (-20012),(-20013),(-20017),
  -- WY (2)
  (-560011),(-560013)
;

-- Whole-record stance honest-skips: 123 of the 124 frozen across
-- 161-165 that are STILL 0-stance and still in the banded in-scope universe. Each reason is
-- carried verbatim from its source gate file — a documented search trail cannot be
-- regenerated by a query, so these are intersected, never recomputed.
INSERT INTO _stance_skip (external_id, reason) VALUES
  (-10101, 'Lucas Burger AL-1 (R) -- no campaign site; Ballotpedia/BallotReady/GoodParty profiles empty of policy content'),  -- [163] AL
  (-20007, 'John E. Foddrill Sr. AK -- TX whistleblower content only, no policy positions'),  -- [165] AK
  (-20012, 'Yaquelin Reynoso AK -- out-of-state MA filer, zero policy content'),  -- [165] AK
  (-20013, 'David Richey AK -- in-state but logistics-only coverage, no positions'),  -- [165] AK
  (-20014, 'Melanie A. Salazar AK -- out-of-state SF filer, explicit no-positions pages'),  -- [165] AK
  (-20017, 'John B. Williams AK -- Fairbanks teacher, filed-only, zero policy quotes'),  -- [165] AK
  (-40301, 'Alan Aversa AZ-3 -- no Candidate Connection survey, no site/socials beyond LinkedIn'),  -- [161] AZ
  (-40603, 'Jereme Peters AZ-6 -- no survey; Ballotpedia Contact section entirely absent'),  -- [161] AZ
  (-40701, 'Daniel Butierez AZ-7 -- 2024 platform quoted by Ballotpedia is off-topic/too vague; live site failed to load'),  -- [161] AZ
  (-50302, 'Bobby Wilson AR-3 -- positions do not map to any of the 24 scales without over-inferring'),  -- [164] AR
  (-90403, 'Luz Helena Bueno CT-4 -- FEC-filed but no reachable primary source'),  -- [164] CT
  (-90405, 'Damon Lawrence Cerreta CT-4 -- FEC-filed but only generic language, unmappable'),  -- [164] CT
  (-150205, 'Edward Codelia HI-2 -- survey answered but mechanism-free, no placeable chair'),  -- [165] HI
  (-150206, 'Randall Terry HI-2 -- identity unresolved vs national activist; HI-local sources silent'),  -- [165] HI
  (-160102, 'Brendan Gomez ID-1 -- $0 FEC, no survey across 3 cycles, meme-only social'),  -- [165] ID
  (-160203, 'Carta Sierra ID-2 -- perennial candidate (legal name Idaho Law), zero policy content'),  -- [165] ID
  (-200304, 'Gavin Solomon KS-3 -- serial multi-state filer, zero KS footprint'),  -- [164] KS
  (-200305, 'Blake Stanley KS-3 -- FEC committee terminated, no site/social/positions'),  -- [164] KS
  (-200401, 'Michael Gaynor KS-4 -- fringe filer, no web presence/platform'),  -- [164] KS
  (-200408, 'Daniel Schneider KS-4 -- withdrew to a KS state-house race'),  -- [164] KS
  (-210403, 'Mohammad Wael Ahmad KY-4 -- no site/questionnaire/verified social'),  -- [164] KY
  (-210502, 'Gerardo Serrano KY-5 -- no usable position evidence located'),  -- [164] KY
  (-220101, 'Randall Arrington LA-1 (R) -- only party self-ID, no policy content; no site, trackers "no positions"'),  -- [163] LA
  (-220102, 'Jim Long LA-1 (D) -- zero issue content anywhere; collision-avoided a diff-spelled "Jim Lange"'),  -- [163] LA
  (-220201, 'Renada Collins LA-2 (D) -- one-page shell site (/issues,/platform,/about all 404); one dignity quote, no scale fit'),  -- [163] LA
  (-220303, 'Caleb Walker LA-3 -- no site; socials login-walled; only an indirect "Patients Over Profits" pledge'),  -- [163] LA
  (-220604, 'Peter Williams LA-6 (R) -- identity well-verified but only generic constituent-advocacy language, no scale-mappable specifics'),  -- [163] LA
  (-240502, 'Jonathan Burruss MD-5 -- campaign site is an empty Wix placeholder; Ballotpedia 403/451; no socials/news/positions'),  -- [162] MD
  (-250902, 'R. Tyler MacAllister MA-9 -- 4 own-site pages + Ballotpedia (no survey) + local news all biography/single-word issue labels, no chair match'),  -- [161] MA
  (-270207, 'Christopher Mosel MN-2 -- no site (West St. Paul Reader "[No response]"), $0 FEC, no survey/socials/news'),  -- [162] MN
  (-270501, 'DeVelle L. Jackson MN-5 -- no site/FEC/news; isidewith hit was a different GA-Senate Develle Jackson'),  -- [162] MN
  (-270505, 'Abbey Zieska MN-5 -- pre-infrastructure; Hometown Source noted "did not have websites" at filing'),  -- [162] MN
  (-270507, 'Abena A. McKenzie MN-5 -- site is local-community-services framing, nothing maps to the 24 federal topics'),  -- [162] MN
  (-290103, 'Carl E. Henderson MO-1 -- Civoren/GoodParty boilerplate only'),  -- [162] MO
  (-290104, 'Alissa Murphy MO-1 -- BallotReady bio only, no positions'),  -- [162] MO
  (-290106, 'Andrew Jones MO-1 -- Civoren vague growth language only'),  -- [162] MO
  (-290201, 'Elizabeth Sparks-Holmes MO-2 -- site themes only, no scale-mappable position'),  -- [162] MO
  (-290302, 'Mike Conner MO-3 -- FEC-confirmed, no site/news/social'),  -- [162] MO
  (-290303, 'Tommy Holstein MO-3 -- FEC-confirmed, no working site/news'),  -- [162] MO
  (-290305, 'Paul Wilson MO-3 -- JS-placeholder Wix platform, no extractable text'),  -- [162] MO
  (-290306, 'Jim Higgins MO-3 -- only stale 2012-2015 gubernatorial coverage'),  -- [162] MO
  (-290401, 'Heather Shelton MO-4 -- Civoren vague pledges only'),  -- [162] MO
  (-290402, 'Scott Vera MO-4 -- FEC-confirmed, no site/content'),  -- [162] MO
  (-290403, 'Jeanette Cass MO-4 -- Civoren generic phrases, unmappable'),  -- [162] MO
  (-290404, 'Hartzell Gray MO-4 -- FEC-confirmed, no policy content'),  -- [162] MO
  (-290405, 'Jordan Herrera MO-4 -- Civoren meta-political statements only'),  -- [162] MO
  (-290407, 'G Rick MO-4 -- Civoren: no bio/policy submitted'),  -- [162] MO
  (-290410, 'Thomas Holbrook MO-4 -- FEC-confirmed, ideology label only'),  -- [162] MO
  (-290505, 'Berton A. Knox MO-5 -- BallotReady-confirmed, no content'),  -- [162] MO
  (-290507, 'Randall Langkraehr MO-5 -- FEC-confirmed, unclaimed/placeholder profiles'),  -- [162] MO
  (-290701, 'John Casey MO-7 -- no site; unquotable YouTube ref only'),  -- [162] MO
  (-290805, 'Rebecca Sharpe Lombard MO-8 -- bio only, all sources walled/404'),  -- [162] MO
  (-320479, 'Russell Best NV-4 -- perennial IAP filer, dead domain, blank questionnaires, $6k lifetime'),  -- [165] NV
  (-320480, 'William Johnson NV-4 -- no-party filer, no FEC/site/social/news anywhere'),  -- [165] NV
  (-400202, 'Ronnie Hopkins OK-2 -- 2026 site 404, only stale inferred foreign-aid line'),  -- [164] OK
  (-400402, 'Rocco Bonacci OK-4 -- no FEC/site, disability-advocacy coverage only'),  -- [164] OK
  (-400503, 'Austin Nieves OK-5 -- no FEC/site, prior run withdrawn'),  -- [164] OK
  (-410301, 'Loran Ayles OR-3 -- no campaign site, $0 FEC, no web presence'),  -- [164] OR
  (-450104, 'Margo Ellis SC-1 (Alliance) -- no site, Ballotpedia blank, trackers stubs, dormant socials'),  -- [163] SC
  (-450202, 'Dayna Alane Smith SC-2 (Workers) -- only evidence was the SC Workers Party platform (party-inference; operator-ruled skip 2026-07-06)'),  -- [163] SC
  (-450402, 'Jessica Ethridge SC-4 (Libertarian) -- 3-plank Wix template too vague to pin; 2022 Lt-Gov positions do not map to the 24 keys'),  -- [163] SC
  (-470105, 'Richard G. Baker TN-1 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470106, 'Chris Campbell TN-1 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470107, 'Billy Cody TN-1 -- bare stub; Facebook page is slogan-only, no policy content'),  -- [161] TN
  (-470108, 'Tyler Brice Mitchell McClain TN-1 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470202, 'Bruce Fine TN-2 -- survey + site checked, "fiscal responsibility"/debt concern with no specifics matching a chair'),  -- [161] TN
  (-470203, 'Adam Heimerman TN-2 -- survey checked, generic subsidy-redirection/due-process content, no chair match'),  -- [161] TN
  (-470302, 'Bryan Martin TN-3 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470303, 'Dean Arnold TN-3 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470304, 'Jean Howard-Hill TN-3 -- only an incomplete 2024 survey; Facebook page has no policy content'),  -- [161] TN
  (-470305, 'Rodney Joe King TN-3 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470306, 'Donnie Lynn Ownby TN-3 -- survey checked, term limits/education/foreign-aid generalities, no chair match'),  -- [161] TN
  (-470307, 'Edward John Roland TN-3 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470401, 'Thomas E. Davis TN-4 -- survey checked, bare topic-name bullets with no elaboration matching a chair'),  -- [161] TN
  (-470403, 'Harold "Rocky" Jones TN-4 -- survey checked, term limits/insider-trading-ban content, none are federal-24 topics'),  -- [161] TN
  (-470405, 'Mike Cortese TN-4 -- site /issues 404s, /policies has only a donation page'),  -- [161] TN
  (-470410, 'Clay Faircloth TN-4 -- only a stale 2024 survey for a different district/party, context-mismatched'),  -- [161] TN
  (-470501, 'Charlie Hatcher TN-5 -- no 2026 survey; site is branding-only, no policy elaboration'),  -- [161] TN
  (-470502, 'Yolanda Cooper-Sutton TN-5 -- no 2026 survey; site content is generic, no specific mechanism'),  -- [161] TN
  (-470503, 'DeVante R. Hill TN-5 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470507, 'James A. Johnson TN-5 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470508, 'Micheal (Me-Haul) O''Leary TN-5 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470601, 'Natisha Brooks TN-6 -- 2020 survey (Senate run) + site content (2023 Mayor run) both context-mismatched'),  -- [161] TN
  (-470606, 'Mike Croley TN-6 -- 2025 survey checked, personal biography/values content, no chair match'),  -- [161] TN
  (-470607, 'Christopher Martin Finley TN-6 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470608, 'Miriam Leibowitz TN-6 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470611, 'Angus Purdy TN-6 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470701, 'Darden Copeland TN-7 -- 2025 survey checked, biography/term-limits content only, no chair match'),  -- [161] TN
  (-470703, 'Saletta Holloway TN-7 -- no 2026 survey; site /issues page empty/JS-blocked'),  -- [161] TN
  (-470705, 'Andrew J. Koontz TN-7 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470706, 'Lowell Reynolds TN-7 -- 2026 survey checked, generic constitutional-accountability themes, no chair match'),  -- [161] TN
  (-470803, 'Heidi Kuhn TN-8 -- 2026 survey checked, generic priority-list content; detailed content found is for a different race'),  -- [161] TN
  (-470804, 'Leonard Perkins TN-8 -- 2024+2026 surveys checked, bare topic-name lists with no elaboration'),  -- [161] TN
  (-470806, 'Wendell "Wells" Blankenship TN-8 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470807, 'Antonio Futch TN-8 -- bare Ballotpedia stub, no campaign website found'),  -- [161] TN
  (-470808, 'Pamela Jeanine "P." Moses TN-8 -- surveys focus on felon voting-rights restoration, no federal-24 chair addresses that specifically'),  -- [161] TN
  (-470809, 'Horace Taylor TN-8 -- 2026 survey checked, topic-label list only, no chair-matching direction'),  -- [161] TN
  (-470810, 'Henry J. Ward, III TN-8 -- bare Ballotpedia stub (both slug variants), no campaign website found'),  -- [161] TN
  (-470903, 'Jeremy Thompson TN-9 -- generic campaign-website content, no chair match'),  -- [161] TN
  (-470905, 'M. LaTroy A-Williams TN-9 -- local economic-development content across 3 cycles (2016-2026), no completed survey'),  -- [161] TN
  (-470910, 'Michelle Davis Head TN-9 -- bare Ballotpedia stub, BallotReady profile has no issue content'),  -- [161] TN
  (-490203, 'Robert M. Moesinger UT-2 -- single-issue electoral-structure platform, maps to no tracked scale'),  -- [165] UT
  (-490304, 'Michael R. Stoddard UT-3 -- audits/sound-money/militia planks map to no tracked scale'),  -- [165] UT
  (-530103, 'James Etzkorn WA-1 -- completed 2026 survey read in full, detailed platform genuinely does not intersect any federal-24 topic'),  -- [161] WA
  (-530105, 'Mary Silva WA-1 -- completed 2026 survey + 2024 statement read in full, entirely conspiratorial content, no chair match'),  -- [161] WA
  (-530302, 'John P. Roco WA-3 -- IDENTITY RISK: Ballotpedia page dominated by an apparent 2016 Hawaii Senate run (cross-state homonym); no 2026 survey'),  -- [161] WA
  (-530307, 'Austin Braswell WA-3 -- no survey, no campaign website found'),  -- [161] WA
  (-530401, 'Jacek "Jack" Kobiesa WA-4 -- completed 2026 survey read in full, populist rhetoric, no chair match'),  -- [161] WA
  (-530404, 'John C. Hughs WA-4 -- no survey; only a walled Facebook link'),  -- [161] WA
  (-530405, 'Favian Valencia WA-4 -- site is marketing-level headlines only, no elaborating text'),  -- [161] WA
  (-530410, 'Elpidia Saavedra WA-4 -- no survey; only a walled Facebook link'),  -- [161] WA
  (-530701, 'David W. Blomstrom WA-7 -- extensive but incoherent/conspiratorial record, no usable federal-24 position'),  -- [161] WA
  (-530703, 'Gwen Kirkland WA-7 -- no survey; only a walled LinkedIn link'),  -- [161] WA
  (-530802, 'Spencer Meline WA-8 -- completed 2026 survey read in full, entirely generic bio, no chair match'),  -- [161] WA
  (-530901, 'Jacob Perasso WA-9 -- 2026 survey section exists with no submitted answers; no site'),  -- [161] WA
  (-531004, 'Derek Maynes WA-10 -- Ballotpedia content is a 2015 unrelated-office statement; no 2026 survey/site'),  -- [161] WA
  (-531005, 'Chris D. Chung WA-10 -- no 2026 survey, parked GoDaddy site, 0 OpenFEC results'),  -- [161] WA
  (-540202, 'Pat Carney WV-2 -- $0-raised fringe filer (FEC H6WV02176), zero footprint'),  -- [165] WV
  (-540203, 'Chris Whitcomb WV-2 -- $0-raised fringe filer (FEC H6WV02168), zero footprint'),  -- [165] WV
  (-550402, 'Purnima Nath WI-4 (R) -- identity/culture-war site content, nothing maps to the 24 federal topics'),  -- [163] WI
  (-560005, 'Richard Dodson WY -- Candidate Connection answered but entirely non-directional'),  -- [165] WY
  (-560011, 'Elena Del Real WY -- bio-only presence, no policy content anywhere'),  -- [165] WY
  (-560013, 'Daniel Workman WY -- FEC filer (H6WY01108), zero policy content')  -- [165] WY
;

-- Phase-167 queue: 2 banded active candidate(s) that are 0-stance today but
-- carry NO documented search trail. Kept separate from _stance_skip on purpose: recording a
-- dated state of the world is honest, asserting a research judgment nobody made is not.
INSERT INTO _stance_queue_167 (external_id, reason) VALUES
  (-550304, 'new/unresearched 0-stance banded candidate detected at 166 authoring (2026-07-26); stance research queued to Phase 167'),  -- WI
  (-550708, 'new/unresearched 0-stance banded candidate detected at 166 authoring (2026-07-26); stance research queued to Phase 167')  -- WI
;
  -- Resolve external_id -> politician_id for the two reason-bearing pin tables (162/165 pattern).
  -- Temp-table writes only; nothing in essentials or inform is touched.
  UPDATE _stance_skip      s SET politician_id = p.id FROM essentials.politicians p WHERE p.external_id = s.external_id;
  UPDATE _stance_queue_167 s SET politician_id = p.id FROM essentials.politicians p WHERE p.external_id = s.external_id;

  SELECT COUNT(*) INTO v_cnt FROM _stance_skip WHERE politician_id IS NULL;
  IF v_cnt<>0 THEN
    RAISE EXCEPTION 'FAIL PINS: % _stance_skip id(s) resolve to no politician row', v_cnt;
  END IF;
  SELECT COUNT(*) INTO v_cnt FROM _stance_queue_167 WHERE politician_id IS NULL;
  IF v_cnt<>0 THEN
    RAISE EXCEPTION 'FAIL PINS: % _stance_queue_167 id(s) resolve to no politician row', v_cnt;
  END IF;

  -- ==========================================================================
  -- CRITERION 10 (HEADSHOT) — USHC3-06: every active banded new candidate has an
  --   essentials.politician_images row or a live-derived pin. 51 pins, regenerated from
  --   scratch on 2026-07-26 (the 566 frozen across 161-165 had drifted: 517 dropped, 2 added).
  --   The failure names the offenders; a bare count would not be actionable.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(nc.st || ':' || nc.external_id, ', ' ORDER BY nc.external_id)
    INTO v_no_image, v_image_detail
  FROM _new_cands nc
  WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id)
    AND nc.external_id NOT IN (SELECT external_id FROM _img_skip);
  IF v_no_image<>0 THEN
    RAISE EXCEPTION 'FAIL HEADSHOT: % active new candidate(s) lack an image and are not pinned: %', v_no_image, v_image_detail;
  END IF;
  SELECT COUNT(*) INTO v_cnt FROM _img_skip;
  RAISE NOTICE 'PASS HEADSHOT: every active banded new candidate across all 178 districts has a politician_images row or one of the % live-derived honest-skip pins', v_cnt;

  -- ==========================================================================
  -- CRITERION 11 (UNSOURCED) — an EXISTENCE CHECK, not a coverage assertion (the 152/158
  --   rationale: a coverage assertion false-fails at milestone scale). 0 stance rows may exist
  --   without a matching politician_context carrying a non-empty sources array.
  --   Scope is broadened per 162 to ALL active in-scope politicians, incumbents included, and
  --   is race-scoped through _house so polluted-band legacy records never enter.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers a
  JOIN (SELECT DISTINCT politician_id FROM _house
         WHERE candidate_status='active' AND politician_id IS NOT NULL) sc
    ON sc.politician_id = a.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
      AND c.sources IS NOT NULL AND array_length(c.sources, 1) >= 1
  );
  IF v_unsourced<>0 THEN
    RAISE EXCEPTION 'FAIL UNSOURCED: % unsourced stance row(s) in the in-scope 178-district set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS UNSOURCED: 0 unsourced stance rows across the in-scope 178-district candidate set (challengers AND incumbents)';

  -- ==========================================================================
  -- CRITERION 12 (COVERAGE) — every active banded new candidate has >=1 stance row, OR is a
  --   researched whole-record honest-skip, OR is queued to Phase 167. The two pin kinds are
  --   reported SEPARATELY and must never be conflated: a researched skip carries a documented
  --   search trail, a queued candidate carries only a dated observation that nobody has looked
  --   yet. Merging them would assert a research judgment that was never made.
  -- ==========================================================================
  SELECT COUNT(*), string_agg(x.who, ', ' ORDER BY x.external_id)
    INTO v_uncovered, v_cov_detail
  FROM (
    SELECT nc.external_id, nc.st || ':' || nc.external_id AS who,
           (SELECT COUNT(*) FROM inform.politician_answers a WHERE a.politician_id = nc.politician_id) AS ans_count
    FROM _new_cands nc
    WHERE nc.politician_id NOT IN (SELECT politician_id FROM _stance_skip)
      AND nc.politician_id NOT IN (SELECT politician_id FROM _stance_queue_167)
  ) x
  WHERE x.ans_count < 1;
  IF v_uncovered<>0 THEN
    RAISE EXCEPTION 'FAIL COVERAGE: % new candidate(s) have 0 stances and are neither pinned nor queued: %', v_uncovered, v_cov_detail;
  END IF;
  SELECT COUNT(*) INTO v_pin_skip  FROM _stance_skip;
  SELECT COUNT(*) INTO v_pin_queue FROM _stance_queue_167;
  RAISE NOTICE 'PASS COVERAGE: every active banded new candidate has >=1 sourced stance, or is one of % RESEARCHED whole-record honest-skips (documented search trail, carried verbatim from gates 161-165), or one of % candidates QUEUED TO PHASE 167 (0-stance as of 2026-07-26, no research performed — not a judgment)', v_pin_skip, v_pin_queue;

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC3-06 structural half, 178 Wave-3 districts across 38 states: SCOPE, ACTIVE, NULLOFFICE, NULLPID, DUPNAME, DUPINCUMBENT, RC-UNIQUE, PARTY, PROVISIONAL, HEADSHOT, UNSOURCED, COVERAGE)';

  RAISE NOTICE 'NATIONAL TOTAL: 178 Wave-3 (v2.22) districts asserted by this gate together with backend/scripts/166-verify-invariants.sql and backend/scripts/166-coordinate-smoke.ts; 144 v2.20 Wave-1 districts owned by backend/scripts/152-verify.sql; 89 v2.21 decided-state districts owned by backend/scripts/158-verify.sql; 24 v2.21 MI and VA districts SEEDED BUT GATE-PENDING under plan 159-06, date-gated on or after 2026-08-05 (158-verify.sql''s own header states it must not reference MI or VA, so no currently passing gate covers them). 411 gate-proven + 24 gate-pending = 435 US House districts nationally.';
END $$;
