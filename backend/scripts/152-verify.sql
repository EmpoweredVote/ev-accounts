-- 152-verify.sql — Phase 152 consolidated read-only milestone gate (USHC-06).
--
-- SELECT-only. Asserts the live state delivered across Phases 149/150/151 for the full
-- v2.20 Wave-1 US House field: CA (52) + TX (38) + FL (28) + NY (26) = 144 districts.
--
-- ============================================================================
-- MILESTONE-LEVEL PURPOSE (Phase 144 precedent):
--   Phases 149/150/151 each carry their own passing per-phase gate (149-verify.sql,
--   150-verify.sql, 151-verify.sql). Those gates own all granular per-candidate
--   stance/headshot honest-skip pins. THIS gate asserts the MILESTONE INVARIANTS fresh
--   across all 144 districts — structural correctness that only makes sense at the
--   full 4-state scale.
--
-- FOUR-ELECTION SCOPE:
--   CA 2026 Statewide General (geo prefix '06') — 52 NATIONAL_LOWER races
--   TX 2026 Statewide General (geo prefix '48') — 38 NATIONAL_LOWER races
--   FL 2026 Statewide General (geo prefix '12') — 28 NATIONAL_LOWER races (PROVISIONAL pre-Aug-18)
--   NY 2026 Statewide General (geo prefix '36') — 26 NATIONAL_LOWER races
--   TOTAL = 144 districts
--
-- FL-ASYMMETRY-SAFE UNSOURCED CHECK:
--   USHC-06-UNSOURCED is an EXISTENCE check on answer rows that lack a sourced context row.
--   It is NOT a coverage assertion ("every candidate has >=1 stance"). FL's ~138 partisan
--   new candidates intentionally have records but NO stances yet (deferred to Phase 153),
--   and uncontested seats are by design — a coverage assertion would FALSE-FAIL. An
--   existence check is satisfiable even when most candidates have 0 stances.
--
-- ACTIVE CANDIDATE TOTALS (prod-verified 2026-06-30):
--   CA 104 active / TX 76 active / FL 181 active / NY 54 active = 415 total
--   NULL politician_id among active: 0 in every state
--   Unsourced answer rows: 0 in every state
--   Duplicate full_name groups: 0 in every state
--   Politician_id in 2+ distinct races: 0
--
-- PER-PHASE GRANULAR SKIP PINS (NOT re-pinned here — owned by the per-phase gates):
--   149-verify.sql: 17 CA UUID headshot honest-skips + 17 CA whole-record stance skips
--   150-verify.sql: 43+27 TX/NY headshot honest-skips + 4+15 TX/NY stance honest-skips
--   151-verify.sql: 17 FL headshot honest-skips + 11 FL stance honest-skips
--
-- WRITE-FREE: only CREATE TEMP TABLE ... ON COMMIT DROP. SELECT-only otherwise.
--   No INSERT/UPDATE/DELETE against essentials or inform tables.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/152-verify.sql

\set ON_ERROR_STOP on

DO $$
DECLARE
  ca_eid          uuid;
  tx_eid          uuid;
  fl_eid          uuid;
  ny_eid          uuid;
  v_ca_races      int;
  v_tx_races      int;
  v_fl_races      int;
  v_ny_races      int;
  v_total_races   int;
  v_under1        int;
  v_under2        int;
  v_nullpid       int;
  v_dupname       int;
  v_dupincumbent  int;
  v_unsourced     int;
  v_prov          int;
  v_party_cols    int;
BEGIN
  -- Resolve all four election ids by exact name (CA resolves by name like the others).
  SELECT id INTO ca_eid FROM essentials.elections WHERE name = 'CA 2026 Statewide General';
  SELECT id INTO tx_eid FROM essentials.elections WHERE name = 'TX 2026 Statewide General';
  SELECT id INTO fl_eid FROM essentials.elections WHERE name = 'FL 2026 Statewide General';
  SELECT id INTO ny_eid FROM essentials.elections WHERE name = 'NY 2026 Statewide General';
  IF ca_eid IS NULL OR tx_eid IS NULL OR fl_eid IS NULL OR ny_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: one or more Wave-1 elections missing (ca=%, tx=%, fl=%, ny=%)',
      ca_eid, tx_eid, fl_eid, ny_eid;
  END IF;

  -- ==========================================================================
  -- Combined Wave-1 House working set (all 4 states, LEFT JOIN candidates).
  -- Scoped by: election_id IN (4 eids) + NATIONAL_LOWER + geo prefix IN (06,48,12,36).
  -- st column distinguishes states; p.external_id included for structural checks.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE
           WHEN r.election_id = ca_eid THEN 'CA'
           WHEN r.election_id = tx_eid THEN 'TX'
           WHEN r.election_id = fl_eid THEN 'FL'
           ELSE 'NY'
         END              AS st,
         r.id             AS race_id,
         d.geo_id         AS geo_id,
         r.description    AS race_desc,
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
  WHERE r.election_id IN (ca_eid, tx_eid, fl_eid, ny_eid)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('06', '48', '12', '36');

  -- ==========================================================================
  -- USHC-06-SCOPE (criterion 1/3) — exactly 52 CA + 38 TX + 28 FL + 26 NY = 144
  --   distinct NATIONAL_LOWER races. Denominators baked as integer literals from
  --   prod-verified counts (2026-06-30).
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'CA') INTO v_ca_races FROM _house;
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'TX') INTO v_tx_races FROM _house;
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'FL') INTO v_fl_races FROM _house;
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'NY') INTO v_ny_races FROM _house;
  SELECT COUNT(DISTINCT race_id) INTO v_total_races FROM _house;

  IF v_ca_races <> 52 THEN
    RAISE EXCEPTION 'FAIL USHC-06-SCOPE: expected 52 CA NATIONAL_LOWER races, got %', v_ca_races;
  END IF;
  IF v_tx_races <> 38 THEN
    RAISE EXCEPTION 'FAIL USHC-06-SCOPE: expected 38 TX NATIONAL_LOWER races, got %', v_tx_races;
  END IF;
  IF v_fl_races <> 28 THEN
    RAISE EXCEPTION 'FAIL USHC-06-SCOPE: expected 28 FL NATIONAL_LOWER races, got %', v_fl_races;
  END IF;
  IF v_ny_races <> 26 THEN
    RAISE EXCEPTION 'FAIL USHC-06-SCOPE: expected 26 NY NATIONAL_LOWER races, got %', v_ny_races;
  END IF;
  IF v_total_races <> 144 THEN
    RAISE EXCEPTION 'FAIL USHC-06-SCOPE: expected 144 total NATIONAL_LOWER races, got %', v_total_races;
  END IF;
  RAISE NOTICE 'PASS USHC-06-SCOPE: 52 CA + 38 TX + 28 FL + 26 NY = 144 distinct NATIONAL_LOWER races';  -- criterion 1/3

  -- ==========================================================================
  -- USHC-06-ACTIVE (criterion 1) — every one of the 144 races has >=1 active candidate.
  --   Uncontested-seat allowance: count of races with <2 is reported as NOTICE, not failure.
  --   FL-10 Frost is uncontested by design; FL is pre-primary crowded (no upper-bound assertion).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_under1 FROM (
    SELECT race_id FROM _house
    GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 1
  ) q;
  IF v_under1 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-06-ACTIVE: % of 144 Wave-1 House race(s) have 0 active candidates', v_under1;
  END IF;
  SELECT COUNT(*) INTO v_under2 FROM (
    SELECT race_id FROM _house
    GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 2
  ) q;
  RAISE NOTICE 'PASS USHC-06-ACTIVE: all 144 Wave-1 House races have >=1 active candidate (% race(s) have <2 — uncontested-seat allowance, e.g. FL-10 Frost)', v_under2;  -- criterion 1/3

  -- ==========================================================================
  -- USHC-06-NULLPID (criterion 3) — 0 active race_candidates with NULL politician_id
  --   across all 144 districts. Ensures headshots+stances resolve for every active card.
  --   Prod-verified: CA 0 / TX 0 / FL 0 / NY 0 (2026-06-30).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-06-NULLPID: % active Wave-1 race_candidates have NULL politician_id (headshot/stance resolution broken)', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS USHC-06-NULLPID: 0 active candidates with NULL politician_id across all 144 districts';  -- criterion 3/3

  -- ==========================================================================
  -- USHC-06-DUPNAME (criterion 2) — 0 duplicate lower(full_name) among ACTIVE candidates
  --   WITHIN each state. Per-state only; cross-state same-name is not a data error.
  --   Prod-verified: 0 dup groups in CA, TX, FL, NY (2026-06-30).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT st, lower(full_name)
    FROM _house
    WHERE candidate_status = 'active'
    GROUP BY st, lower(full_name)
    HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-06-DUPNAME: % duplicate full_name group(s) within a state among active candidates (D-03 / dup-incumbent trap)', v_dupname;
  END IF;
  RAISE NOTICE 'PASS USHC-06-DUPNAME: 0 duplicate full_name within any state (CA/TX/FL/NY) among active candidates';  -- criterion 2/3

  -- ==========================================================================
  -- USHC-06-DUPINCUMBENT (criterion 2) — 0 politician_id appearing as ACTIVE in 2+
  --   DISTINCT races across the 144 districts. Catches the v2.4 two-Andy-Barrs /
  --   cross-district double-seeding trap. Prod-verified: 0 (2026-06-30).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_dupincumbent FROM (
    SELECT politician_id
    FROM _house
    WHERE candidate_status = 'active' AND politician_id IS NOT NULL
    GROUP BY politician_id
    HAVING COUNT(DISTINCT race_id) > 1
  ) q;
  IF v_dupincumbent <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-06-DUPINCUMBENT: % politician_id(s) active in 2+ distinct races (cross-district dup-incumbent — v2.4 trap)', v_dupincumbent;
  END IF;
  RAISE NOTICE 'PASS USHC-06-DUPINCUMBENT: 0 politician_id active in 2+ distinct races across the 144 districts';  -- criterion 2/3

  -- ==========================================================================
  -- USHC-06-UNSOURCED (criterion 2) — 0 UNSOURCED stance rows across all newly-seeded
  --   Wave-1 candidates. EXISTENCE CHECK ONLY (NOT a coverage assertion):
  --   A row in inform.politician_answers for an active Wave-1 candidate politician_id
  --   must have a matching inform.politician_context row with sources IS NOT NULL AND
  --   array_length(sources,1)>=1. Rows with 0 answer rows are NOT a failure (FL ~138
  --   partisan new candidates and uncontested seats intentionally have no stances yet —
  --   the FL-asymmetry trap). Prod-verified unsourced=0 in CA, TX, FL, and NY (2026-06-30).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers a
  WHERE a.politician_id IN (
    SELECT DISTINCT h.politician_id FROM _house h
    WHERE h.candidate_status = 'active' AND h.politician_id IS NOT NULL
  )
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id
      AND c.topic_id = a.topic_id
      AND c.sources IS NOT NULL
      AND array_length(c.sources, 1) >= 1
  );
  IF v_unsourced <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-06-UNSOURCED: % answer row(s) for active Wave-1 candidates lack a sourced context row (0-unsourced floor violated)', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS USHC-06-UNSOURCED: 0 unsourced answer rows across all active Wave-1 candidates (CA/TX/FL/NY — existence check, FL-asymmetry-safe)';  -- criterion 2/3

  -- ==========================================================================
  -- USHC-06-FL-PROVISIONAL (criterion 3) — all 28 FL House races carry the
  --   PROVISIONAL: description sentinel (Phase 153 will prune after FL primary Aug-18).
  --   FL presence is already proven by USHC-06-SCOPE FL=28.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_prov
  FROM _house
  WHERE st = 'FL' AND race_desc LIKE 'PROVISIONAL:%';
  IF v_prov <> 28 THEN
    RAISE EXCEPTION 'FAIL USHC-06-FL-PROVISIONAL: only %/28 FL House races carry the PROVISIONAL:* description sentinel', v_prov;
  END IF;
  RAISE NOTICE 'PASS USHC-06-FL-PROVISIONAL: all 28 FL House races marked PROVISIONAL (Phase 153 will prune after Aug-18 primary)';  -- criterion 3/3

  -- ==========================================================================
  -- USHC-06-PARTY (criterion 3) — party-not-on-candidate-card structural invariant.
  --   Party lives on races.primary_party only. Assert that essentials.race_candidates
  --   has no 'party' or 'party_affiliation' column (information_schema check).
  --   Antipartisan invariant: candidate cards never surface party directly.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_party_cols
  FROM information_schema.columns
  WHERE table_schema = 'essentials'
    AND table_name = 'race_candidates'
    AND column_name IN ('party', 'party_affiliation');
  IF v_party_cols <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC-06-PARTY: essentials.race_candidates has % party/party_affiliation column(s) — antipartisan invariant violated', v_party_cols;
  END IF;
  RAISE NOTICE 'PASS USHC-06-PARTY: race_candidates has no party/party_affiliation column (party reads from races.primary_party only — antipartisan structural invariant)';  -- criterion 3/3

  -- ==========================================================================
  -- FOOTER: Milestone summary documented for the gate record.
  --   415 active candidates: CA 104 / TX 76 / FL 181 / NY 54.
  --   Per-phase granular skip pins are owned by the three passing per-phase gates:
  --     149-verify.sql: 17 CA headshot honest-skips + 17 CA stance whole-record skips
  --     150-verify.sql: 43+27 TX/NY headshot honest-skips + 4+15 TX/NY stance whole-record skips
  --     151-verify.sql: 17 FL headshot honest-skips + 11 FL stance whole-record skips
  -- ==========================================================================
  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC-06-SCOPE / USHC-06-ACTIVE / USHC-06-NULLPID / USHC-06-DUPNAME / USHC-06-DUPINCUMBENT / USHC-06-UNSOURCED / USHC-06-FL-PROVISIONAL / USHC-06-PARTY)';
END $$;
