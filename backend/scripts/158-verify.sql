-- 158-verify.sql — Phase 158 consolidated read-only milestone gate (USHC2-06).
--
-- SELECT-only. Asserts the live state delivered across Phases 155/156/157 for the six
-- DECIDED-state Wave-2 US House delegations:
--   PA (17) + IL (17) + OH (15) + GA (14) + NC (14) + NJ (12) = 89 districts.
--
-- ============================================================================
-- MILESTONE-LEVEL PURPOSE (Phase 152 precedent):
--   Phases 155/156/157 each carry their own passing per-phase gate (155-verify.sql,
--   156-verify.sql, 157-verify.sql). Those gates OWN all granular per-candidate
--   stance/headshot honest-skip pins. THIS gate asserts the MILESTONE INVARIANTS fresh
--   across all 89 decided-state districts — structural correctness that only makes sense
--   at the full 6-state scale, NOT per phase. It does NOT re-pin per-candidate skips.
--
-- SIX-ELECTION SCOPE (resolved by EXACT name at runtime; RAISE EXCEPTION on any NULL):
--   PA 2026 Statewide General (geo prefix '42') — 17 NATIONAL_LOWER races
--   IL 2026 Statewide General (geo prefix '17') — 17 NATIONAL_LOWER races
--   OH 2026 Statewide General (geo prefix '39') — 15 NATIONAL_LOWER races
--   GA 2026 Statewide General (geo prefix '13') — 14 NATIONAL_LOWER races (1313 = TRUE VACANCY)
--   NC 2026 Statewide General (geo prefix '37') — 14 NATIONAL_LOWER races
--   NJ 2026 Statewide General (geo prefix '34') — 12 NATIONAL_LOWER races (3408 = uncontested)
--   TOTAL = 89 districts
--
-- MI + VA ARE NOT ASSERTED HERE:
--   MI (13) + VA (11) are seeded and asserted separately by the DATE-GATED Phase 159
--   (both primaries Aug 4, 2026). The full 113-district v2.21 milestone is the UNION of
--   this 89-district gate + Phase 159's MI+VA gate. This gate MUST NOT reference MI or VA.
--
-- ASYMMETRY-SAFE UNSOURCED CHECK:
--   USHC2-06-UNSOURCED is an EXISTENCE check on answer rows that lack a sourced context row.
--   It is NOT a coverage assertion ("every candidate has >=1 stance"). All-partial incumbents
--   plus documented whole-record honest-skip candidates (the 149/155 chairs-not-polarity
--   standard) intentionally have records but few/no stances — a coverage assertion would
--   FALSE-FAIL. An existence check is satisfiable even when most candidates have 0 stances.
--   Mirrors 152-verify.sql USHC-06-UNSOURCED exactly.
--
-- PER-PHASE GRANULAR SKIP PINS (NOT re-pinned here — owned by the per-phase gates):
--   155-verify.sql: PA/IL headshot honest-skips + PA/IL whole-record stance skips
--   156-verify.sql: OH/GA/NC headshot honest-skips + OH/GA/NC whole-record stance skips
--                   (incl. D-04-GA13 Clark/Chavez vacancy handling)
--   157-verify.sql: NJ headshot honest-skips + NJ whole-record stance skips
--                   (incl. NJ-12 retirement + NJ-8 uncontested handling)
--
-- WRITE-FREE: only CREATE TEMP TABLE ... ON COMMIT DROP. SELECT-only otherwise.
--   No INSERT/UPDATE/DELETE against essentials or inform tables. No --commit, no migration,
--   no deploy.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/158-verify.sql

\set ON_ERROR_STOP on

DO $$
DECLARE
  pa_eid          uuid;
  il_eid          uuid;
  oh_eid          uuid;
  ga_eid          uuid;
  nc_eid          uuid;
  nj_eid          uuid;
  v_pa_races      int;
  v_il_races      int;
  v_oh_races      int;
  v_ga_races      int;
  v_nc_races      int;
  v_nj_races      int;
  v_total_races   int;
  v_under1        int;
  v_under2        int;
  v_nullpid       int;
  v_dupname       int;
  v_dupincumbent  int;
  v_unsourced     int;
  v_party_cols    int;
  -- USHC2-06-VACANCY sub-assertion holders
  v_ga13_missing   int;
  v_ga13_incumbent int;
  v_nj12_wc        int;
  v_nj12_missing   int;
  v_nj8_active     int;
  v_nj8_menendez   int;
BEGIN
  -- Resolve all six decided-state election ids by exact name.
  SELECT id INTO pa_eid FROM essentials.elections WHERE name = 'PA 2026 Statewide General';
  SELECT id INTO il_eid FROM essentials.elections WHERE name = 'IL 2026 Statewide General';
  SELECT id INTO oh_eid FROM essentials.elections WHERE name = 'OH 2026 Statewide General';
  SELECT id INTO ga_eid FROM essentials.elections WHERE name = 'GA 2026 Statewide General';
  SELECT id INTO nc_eid FROM essentials.elections WHERE name = 'NC 2026 Statewide General';
  SELECT id INTO nj_eid FROM essentials.elections WHERE name = 'NJ 2026 Statewide General';
  IF pa_eid IS NULL OR il_eid IS NULL OR oh_eid IS NULL
     OR ga_eid IS NULL OR nc_eid IS NULL OR nj_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: one or more Wave-2 decided elections missing (pa=%, il=%, oh=%, ga=%, nc=%, nj=%)',
      pa_eid, il_eid, oh_eid, ga_eid, nc_eid, nj_eid;
  END IF;

  -- ==========================================================================
  -- Combined Wave-2 decided-state House working set (all 6 states, LEFT JOIN candidates).
  -- Scoped by: election_id IN (6 eids) + NATIONAL_LOWER + geo prefix IN (42,17,39,13,37,34).
  -- st column distinguishes states; p.external_id included for structural checks.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE
           WHEN r.election_id = pa_eid THEN 'PA'
           WHEN r.election_id = il_eid THEN 'IL'
           WHEN r.election_id = oh_eid THEN 'OH'
           WHEN r.election_id = ga_eid THEN 'GA'
           WHEN r.election_id = nc_eid THEN 'NC'
           ELSE 'NJ'
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
  WHERE r.election_id IN (pa_eid, il_eid, oh_eid, ga_eid, nc_eid, nj_eid)
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('42', '17', '39', '13', '37', '34');

  -- ==========================================================================
  -- USHC2-06-SCOPE (criterion 1) — exactly 17 PA + 17 IL + 15 OH + 14 GA + 14 NC + 12 NJ = 89
  --   distinct NATIONAL_LOWER races. Denominators baked as integer literals from the three
  --   prod-verified per-phase gates (155/156/157).
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'PA') INTO v_pa_races FROM _house;
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'IL') INTO v_il_races FROM _house;
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'OH') INTO v_oh_races FROM _house;
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'GA') INTO v_ga_races FROM _house;
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'NC') INTO v_nc_races FROM _house;
  SELECT COUNT(DISTINCT race_id) FILTER (WHERE st = 'NJ') INTO v_nj_races FROM _house;
  SELECT COUNT(DISTINCT race_id) INTO v_total_races FROM _house;

  IF v_pa_races <> 17 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-SCOPE: expected 17 PA NATIONAL_LOWER races, got %', v_pa_races;
  END IF;
  IF v_il_races <> 17 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-SCOPE: expected 17 IL NATIONAL_LOWER races, got %', v_il_races;
  END IF;
  IF v_oh_races <> 15 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-SCOPE: expected 15 OH NATIONAL_LOWER races, got %', v_oh_races;
  END IF;
  IF v_ga_races <> 14 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-SCOPE: expected 14 GA NATIONAL_LOWER races, got %', v_ga_races;
  END IF;
  IF v_nc_races <> 14 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-SCOPE: expected 14 NC NATIONAL_LOWER races, got %', v_nc_races;
  END IF;
  IF v_nj_races <> 12 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-SCOPE: expected 12 NJ NATIONAL_LOWER races, got %', v_nj_races;
  END IF;
  IF v_total_races <> 89 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-SCOPE: expected 89 total NATIONAL_LOWER races, got %', v_total_races;
  END IF;
  RAISE NOTICE 'PASS USHC2-06-SCOPE: PA 17 + IL 17 + OH 15 + GA 14 + NC 14 + NJ 12 = 89 distinct NATIONAL_LOWER races';  -- criterion 1

  -- ==========================================================================
  -- USHC2-06-ACTIVE (criterion 1/3) — every one of the 89 races has >=1 active candidate.
  --   Uncontested-seat allowance: count of races with <2 active is reported as a NOTICE,
  --   NOT a failure (NJ-8 Menendez-only, PA-3 Rabb, and any other genuinely safe seat).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_under1 FROM (
    SELECT race_id FROM _house
    GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 1
  ) q;
  IF v_under1 <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-ACTIVE: % of 89 Wave-2 decided House race(s) have 0 active candidates', v_under1;
  END IF;
  SELECT COUNT(*) INTO v_under2 FROM (
    SELECT race_id FROM _house
    GROUP BY race_id
    HAVING COUNT(*) FILTER (WHERE candidate_status = 'active') < 2
  ) q;
  RAISE NOTICE 'PASS USHC2-06-ACTIVE: all 89 decided Wave-2 House races have >=1 active candidate (% race(s) have <2 — uncontested-seat allowance, e.g. NJ-8 Menendez / PA-3 Rabb)', v_under2;  -- criterion 1/3

  -- ==========================================================================
  -- USHC2-06-NULLPID (criterion 3) — 0 active race_candidates with NULL politician_id
  --   across all 89 districts. Ensures headshots+stances resolve for every active card.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-NULLPID: % active Wave-2 race_candidates have NULL politician_id (headshot/stance resolution broken)', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS USHC2-06-NULLPID: 0 active candidates with NULL politician_id across all 89 districts';  -- criterion 3

  -- ==========================================================================
  -- USHC2-06-DUPNAME (criterion 2) — 0 duplicate lower(full_name) among ACTIVE candidates
  --   WITHIN each state. Per-state only; cross-state same-name is not a data error.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT st, lower(full_name)
    FROM _house
    WHERE candidate_status = 'active'
    GROUP BY st, lower(full_name)
    HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-DUPNAME: % duplicate full_name group(s) within a state among active candidates', v_dupname;
  END IF;
  RAISE NOTICE 'PASS USHC2-06-DUPNAME: 0 duplicate full_name within any state (PA/IL/OH/GA/NC/NJ) among active candidates';  -- criterion 2

  -- ==========================================================================
  -- USHC2-06-DUPINCUMBENT (criterion 2) — 0 politician_id appearing as ACTIVE in 2+
  --   DISTINCT races across the 89 districts. Catches the v2.4 two-Andy-Barrs /
  --   cross-district double-seeding trap.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_dupincumbent FROM (
    SELECT politician_id
    FROM _house
    WHERE candidate_status = 'active' AND politician_id IS NOT NULL
    GROUP BY politician_id
    HAVING COUNT(DISTINCT race_id) > 1
  ) q;
  IF v_dupincumbent <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-DUPINCUMBENT: % politician_id(s) active in 2+ distinct races (cross-district dup-incumbent — v2.4 trap)', v_dupincumbent;
  END IF;
  RAISE NOTICE 'PASS USHC2-06-DUPINCUMBENT: 0 politician_id active in 2+ distinct races across the 89 districts';  -- criterion 2

  -- ==========================================================================
  -- USHC2-06-UNSOURCED (criterion 2) — 0 UNSOURCED stance rows across all active Wave-2
  --   decided candidates. EXISTENCE CHECK ONLY (NOT a coverage assertion):
  --   A row in inform.politician_answers for an active Wave-2 candidate politician_id must
  --   have a matching inform.politician_context row with sources IS NOT NULL AND
  --   array_length(sources,1)>=1. Candidates with 0 answer rows are NOT a failure
  --   (all-partial incumbents + documented whole-record honest-skips — chairs-not-polarity).
  --   Mirrors 152-verify.sql USHC-06-UNSOURCED exactly.
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
    RAISE EXCEPTION 'FAIL USHC2-06-UNSOURCED: % answer row(s) for active Wave-2 candidates lack a sourced context row (0-unsourced floor violated)', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS USHC2-06-UNSOURCED: 0 unsourced answer rows across all active Wave-2 decided candidates (existence check, asymmetry-safe)';  -- criterion 2

  -- ==========================================================================
  -- USHC2-06-VACANCY (criterion 1/3) — the state-wrinkle pins folded from 156/157:
  --   GA-13 (geo 1313) TRUE VACANCY: Jasmine Clark AND Jonathan Chavez both active,
  --     non-null pid, AND 0 active is_incumbent=true rows (David Scott died Apr 2026).
  --   NJ-12 (geo 3412) RETIREMENT: Bonnie Watson Coleman
  --     (a75a3e6e-31ff-4870-8aea-501e41326fd1) 0 active rows AND Adam Hamawy + Gregg Mele
  --     both active (no vacancy office — she retired).
  --   NJ-8 (geo 3408) UNCONTESTED: exactly 1 active row = Robert Menendez
  --     (fc7a00d6-c552-4627-87f7-b0fc5cfe486c), is_incumbent=true (documented allowance).
  -- ==========================================================================
  -- GA-13: both nominees present, active, non-null pid.
  SELECT COUNT(*) INTO v_ga13_missing
  FROM (VALUES ('Jasmine Clark'), ('Jonathan Chavez')) AS n(who)
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = 'GA' AND h.geo_id = '1313'
      AND h.candidate_status = 'active' AND h.politician_id IS NOT NULL
      AND lower(h.full_name) = lower(n.who)
  );
  IF v_ga13_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-VACANCY: % GA-13 vacancy nominee(s) (Clark/Chavez) absent from the active non-null field', v_ga13_missing;
  END IF;
  SELECT COUNT(*) INTO v_ga13_incumbent
  FROM _house h
  WHERE h.st = 'GA' AND h.geo_id = '1313'
    AND h.candidate_status = 'active' AND h.is_incumbent = true;
  IF v_ga13_incumbent <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-VACANCY: GA-13 is a true vacancy but % active candidate(s) flagged is_incumbent=true', v_ga13_incumbent;
  END IF;

  -- NJ-12: retired incumbent Watson Coleman 0 active; both nominees active.
  SELECT COUNT(*) INTO v_nj12_wc
  FROM _house h
  WHERE h.st = 'NJ' AND h.geo_id = '3412'
    AND h.candidate_status = 'active'
    AND h.politician_id = 'a75a3e6e-31ff-4870-8aea-501e41326fd1';
  IF v_nj12_wc <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-VACANCY: NJ-12 retired incumbent Watson Coleman present as % active row(s)', v_nj12_wc;
  END IF;
  SELECT COUNT(*) INTO v_nj12_missing
  FROM (VALUES ('Adam Hamawy'), ('Gregg Mele')) AS n(who)
  WHERE NOT EXISTS (
    SELECT 1 FROM _house h
    WHERE h.st = 'NJ' AND h.geo_id = '3412'
      AND h.candidate_status = 'active' AND h.politician_id IS NOT NULL
      AND lower(h.full_name) = lower(n.who)
  );
  IF v_nj12_missing <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-VACANCY: % NJ-12 open-seat nominee(s) (Hamawy/Mele) absent from the active field', v_nj12_missing;
  END IF;

  -- NJ-8: exactly 1 active = Menendez, is_incumbent=true.
  SELECT COUNT(*) INTO v_nj8_active
  FROM _house h
  WHERE h.st = 'NJ' AND h.geo_id = '3408' AND h.candidate_status = 'active';
  IF v_nj8_active <> 1 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-VACANCY: NJ-8 uncontested expected exactly 1 active, got %', v_nj8_active;
  END IF;
  SELECT COUNT(*) INTO v_nj8_menendez
  FROM _house h
  WHERE h.st = 'NJ' AND h.geo_id = '3408' AND h.candidate_status = 'active'
    AND h.politician_id = 'fc7a00d6-c552-4627-87f7-b0fc5cfe486c' AND h.is_incumbent = true;
  IF v_nj8_menendez <> 1 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-VACANCY: NJ-8 sole active row is not Robert Menendez is_incumbent=true (got % matching)', v_nj8_menendez;
  END IF;
  RAISE NOTICE 'PASS USHC2-06-VACANCY: GA-13 Clark+Chavez active/no-incumbent; NJ-12 Watson Coleman 0-active + Hamawy+Mele active; NJ-8 exactly 1 active Menendez (incumbent)';  -- criterion 1/3

  -- ==========================================================================
  -- USHC2-06-PARTY (criterion 3) — party-not-on-candidate-card structural invariant.
  --   Party lives on races.primary_party only. Assert essentials.race_candidates has no
  --   'party' or 'party_affiliation' column. Antipartisan invariant.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_party_cols
  FROM information_schema.columns
  WHERE table_schema = 'essentials'
    AND table_name = 'race_candidates'
    AND column_name IN ('party', 'party_affiliation');
  IF v_party_cols <> 0 THEN
    RAISE EXCEPTION 'FAIL USHC2-06-PARTY: essentials.race_candidates has % party/party_affiliation column(s) — antipartisan invariant violated', v_party_cols;
  END IF;
  RAISE NOTICE 'PASS USHC2-06-PARTY: race_candidates has no party/party_affiliation column (party reads from races.primary_party only — antipartisan structural invariant)';  -- criterion 3

  -- ==========================================================================
  -- FOOTER: Milestone summary documented for the gate record.
  --   89 decided-state districts: PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / NJ 12.
  --   MI (13) + VA (11) asserted by the date-gated Phase 159; the full 113-district
  --   v2.21 milestone closes as the UNION of this gate + Phase 159's MI+VA gate.
  --   Per-phase granular skip pins are owned by the three passing per-phase gates:
  --     155-verify.sql (PA/IL) / 156-verify.sql (OH/GA/NC) / 157-verify.sql (NJ).
  -- ==========================================================================
  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC2-06-SCOPE / USHC2-06-ACTIVE / USHC2-06-NULLPID / USHC2-06-DUPNAME / USHC2-06-DUPINCUMBENT / USHC2-06-UNSOURCED / USHC2-06-VACANCY / USHC2-06-PARTY)';
END $$;
