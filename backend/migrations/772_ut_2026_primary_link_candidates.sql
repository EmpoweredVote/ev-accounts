-- Migration 772: UT 2026 Primary — link every candidate to a politician record (Phase 1)
--
-- Canonical election: '2026 Utah Primary', 2026-06-23, UT (id 02dee6b2-76cd-4aa3-a365-6ee362f8a719).
-- Goal: give every race_candidate a politician_id so it renders as a full PoliticianProfile and
--       can later receive enrichment (website/social/photo) and, eventually, stances + finance.
--       (CompassCard / CampaignFinanceSection both render null when the politician has no data,
--        so linking does NOT create empty broken sections.)
--
-- Pre-check (2026-06-18): 171 candidates, 79 linked, 92 unlinked.
--   • 18 unlinked have exactly one existing politician name-match  -> Section A (link)
--   • 1  ambiguous ('Travis Hoban', two records)                  -> Section B (link to ut-city-provo)
--   • 73 have no match                                            -> Section C (create sos_filing record + link)
-- (Travis Hoban is subsequently re-pointed to his active record in migration 774.)
--
-- Convention (matches existing UT challenger records, e.g. data_source='sos_filing', external_id NULL):
--   minimal politician row, is_incumbent=false, is_active=true, no office.
--
-- Idempotent: every step guards on rc.politician_id IS NULL.
-- NOTE: already applied to production 2026-06-18 (recorded here for history).

BEGIN;

-- ── Section A: link candidates that have exactly one existing politician name-match ──────────────
WITH e AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
UPDATE essentials.race_candidates rc
SET politician_id = p.id, updated_at = now()
FROM essentials.races r, essentials.politicians p, e
WHERE r.election_id = e.id
  AND rc.race_id = r.id
  AND rc.politician_id IS NULL
  AND lower(p.full_name) = lower(rc.full_name)
  AND (SELECT count(*) FROM essentials.politicians p2 WHERE lower(p2.full_name) = lower(rc.full_name)) = 1;

-- ── Section B: resolve ambiguous 'Travis Hoban' -> the ut-city-provo record (not the bare dup) ───
WITH e AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
UPDATE essentials.race_candidates rc
SET politician_id = '36fa56a1-fe67-440a-a8fd-dccb34845e2a', updated_at = now()
FROM essentials.races r, e
WHERE r.election_id = e.id
  AND rc.race_id = r.id
  AND rc.politician_id IS NULL
  AND lower(rc.full_name) = 'travis hoban';

-- ── Section C: create a minimal sos_filing politician for each remaining unmatched candidate ─────
DO $$
DECLARE
  v_e uuid;
  rec RECORD;
  new_pid uuid;
BEGIN
  SELECT id INTO v_e FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT';

  FOR rec IN
    SELECT rc.id, rc.full_name, rc.first_name, rc.last_name
    FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id
    WHERE ra.election_id = v_e
      AND rc.politician_id IS NULL
  LOOP
    INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, data_source)
    VALUES (rec.full_name, rec.first_name, rec.last_name, true, false, 'sos_filing')
    RETURNING id INTO new_pid;

    UPDATE essentials.race_candidates
    SET politician_id = new_pid, updated_at = now()
    WHERE id = rec.id;
  END LOOP;
END $$;

-- ── Verification (raise notice; transaction still commits) ───────────────────────────────────────
DO $$
DECLARE v_e uuid; v_unlinked int; v_total int;
BEGIN
  SELECT id INTO v_e FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT';
  SELECT count(*), count(*) FILTER (WHERE rc.politician_id IS NULL)
    INTO v_total, v_unlinked
  FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
  WHERE r.election_id = v_e;
  RAISE NOTICE 'UT 2026 Primary: % candidates, % still unlinked (expect 0)', v_total, v_unlinked;
END $$;

COMMIT;
