-- 1495_dedupe_la_city_controller_office.sql
--
-- Los Angeles had TWO `City Controller` offices on the same LOCAL_EXEC district
-- (feeb6b8c-f099-47b8-80eb-f984560d3d6e), each carrying its own race for the same
-- 2026-06-02 "2026 LA County Primary" with the same two candidates (Kenneth Mejia,
-- Zach Sokoloff). The 2026 LA City Controller race therefore rendered twice, and the
-- unheld office emitted a spurious all-NULL row through essentials.office_current_holder.
--
-- How it happened:
--   2026-04-13  stub office 71b601a1 + race b83b4b97 created (description written,
--               but no chamber_id, no seats, no representing_city, and no office_terms row)
--   2026-04-25..05-24  discovery-sweep staged Mejia/Sokoloff against the STUB race weekly
--   2026-05-07  canonical office e5435b0e + race 6a94215c created (chamber_id, seats=1,
--               representing_city, office_terms row seating Mejia, legacy politicians.office_id)
--   2026-05-31  discovery-sweep switched to staging against the CANONICAL race
--
-- Resolution: keep the canonical office/race, fold the stub away.
--   KEEP  office e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6  race 6a94215c-f629-45a7-9deb-3cc31f80b5d1
--   DROP  office 71b601a1-8afe-4612-98f5-00a1455e16c3  race b83b4b97-490a-4f42-a991-f055744f7c93
--
-- The 14 essentials.candidate_staging rows on the stub race are discovery-sweep audit
-- history (the same two people re-detected weekly, no unique candidates). Their FKs are
-- ON DELETE NO ACTION, so they would BLOCK the delete rather than cascade. They are
-- repointed at the canonical race/race_candidates to preserve the audit trail rather than
-- dropped. Both readrank_* tables and meetings.event_races hold zero rows for the stub race.
--
-- Idempotent: every step is guarded or matches zero rows once applied.

BEGIN;

-- 1. Carry the stub race's description onto the canonical race (canonical had none).
UPDATE essentials.races
   SET description = 'Los Angeles City Controller — citywide elected office, 4-year term.',
       updated_at  = now()
 WHERE id = '6a94215c-f629-45a7-9deb-3cc31f80b5d1'
   AND description IS NULL;

-- 2. Repoint staging's matched_candidate_id from the stub's race_candidates to the
--    canonical race_candidates for the SAME politician (mapped by politician_id, not by
--    hard-coded row id, so this stays correct if the rows are ever rebuilt).
UPDATE essentials.candidate_staging cs
   SET matched_candidate_id = keep_rc.id
  FROM essentials.race_candidates drop_rc
  JOIN essentials.race_candidates keep_rc
    ON keep_rc.race_id       = '6a94215c-f629-45a7-9deb-3cc31f80b5d1'
   AND keep_rc.politician_id = drop_rc.politician_id
 WHERE drop_rc.race_id            = 'b83b4b97-490a-4f42-a991-f055744f7c93'
   AND cs.matched_candidate_id    = drop_rc.id;

-- 3. Repoint staging rows from the stub race to the canonical race.
UPDATE essentials.candidate_staging
   SET race_id = '6a94215c-f629-45a7-9deb-3cc31f80b5d1'
 WHERE race_id = 'b83b4b97-490a-4f42-a991-f055744f7c93';

-- 4. Drop the stub race. Cascades its own two race_candidates rows
--    (race_candidates_race_id_fkey is ON DELETE CASCADE).
DELETE FROM essentials.races
 WHERE id = 'b83b4b97-490a-4f42-a991-f055744f7c93';

-- 5. Drop the now-unreferenced stub office. It has no office_terms row, so the
--    ON DELETE CASCADE on office_terms_office_id_fkey removes nothing.
DELETE FROM essentials.offices
 WHERE id = '71b601a1-8afe-4612-98f5-00a1455e16c3'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = '71b601a1-8afe-4612-98f5-00a1455e16c3')
   AND NOT EXISTS (SELECT 1 FROM essentials.races        r WHERE r.office_id = '71b601a1-8afe-4612-98f5-00a1455e16c3');

-- ── post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices   int;
  v_races     int;
  v_cands     int;
  v_staging   int;
  v_orphans   int;
  v_holder    int;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o
   WHERE o.district_id = 'feeb6b8c-f099-47b8-80eb-f984560d3d6e'
     AND o.title = 'City Controller';
  IF v_offices <> 1 THEN
    RAISE EXCEPTION '1495: expected exactly 1 LA City Controller office, found %', v_offices;
  END IF;

  SELECT count(*) INTO v_races
    FROM essentials.races r
   WHERE r.office_id = 'e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6';
  IF v_races <> 1 THEN
    RAISE EXCEPTION '1495: expected exactly 1 race on the canonical office, found %', v_races;
  END IF;

  -- the canonical race must still hold both candidates, exactly once each
  SELECT count(*) INTO v_cands
    FROM essentials.race_candidates rc
   WHERE rc.race_id = '6a94215c-f629-45a7-9deb-3cc31f80b5d1';
  IF v_cands <> 2 THEN
    RAISE EXCEPTION '1495: expected 2 candidates on the canonical race, found %', v_cands;
  END IF;

  -- all 16 staging rows (14 folded + 2 original) now hang off the canonical race
  SELECT count(*) INTO v_staging
    FROM essentials.candidate_staging cs
   WHERE cs.race_id = '6a94215c-f629-45a7-9deb-3cc31f80b5d1';
  IF v_staging <> 16 THEN
    RAISE EXCEPTION '1495: expected 16 staging rows on the canonical race, found %', v_staging;
  END IF;

  -- no staging row may point at a race_candidates row that no longer exists
  SELECT count(*) INTO v_orphans
    FROM essentials.candidate_staging cs
   WHERE cs.matched_candidate_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.id = cs.matched_candidate_id);
  IF v_orphans <> 0 THEN
    RAISE EXCEPTION '1495: % staging rows reference a deleted race_candidates row', v_orphans;
  END IF;

  -- the surviving office resolves to exactly one holder (Kenneth Mejia), no all-NULL row
  SELECT count(*) INTO v_holder
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = 'e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6'
     AND p.full_name = 'Kenneth Mejia';
  IF v_holder <> 1 THEN
    RAISE EXCEPTION '1495: canonical office does not resolve to Kenneth Mejia (found %)', v_holder;
  END IF;

  RAISE NOTICE '1495 OK: 1 LA City Controller office, 1 race, 2 candidates, 16 staging rows, holder=Kenneth Mejia';
END $$;

COMMIT;
