-- 1219_portland_admin_chambers_no_compass.sql
-- Mark Portland's three non-policy administrative chambers as policy_engagement_level='none'
-- so they render the "administrative office — no compass applies" treatment instead of an
-- empty/"no stances" compass card. They REMAIN listed as officials; only the compass surface changes.
--
-- Scope: City of Portland only. Per-chamber (each of these is its own single-office chamber), so
-- elected City Attorneys / Auditors in OTHER cities (their own chambers) are UNAFFECTED and keep
-- their compasses. City Council (12) and Mayor chambers stay 'full'.
--   City Administrator (appointed) -> none
--   City Attorney     (appointed) -> none
--   City Auditor      (elected oversight, non-policy) -> none
--
-- policy_engagement_level is consumed live by the API (essentialsService/essentialsBrowseService) and
-- Profile.jsx (engagement==='none' -> administrative message). No deploy required; effect is immediate.
-- AUDIT-ONLY, idempotent, no schema_migrations ledger row.

UPDATE essentials.chambers ch
SET policy_engagement_level = 'none'
FROM essentials.governments g
WHERE ch.government_id = g.id
  AND g.name = 'City of Portland, Oregon, US'
  AND ch.name IN ('City Administrator', 'City Attorney', 'City Auditor')
  AND ch.policy_engagement_level IS DISTINCT FROM 'none';

-- Post-verify: exactly the 3 admin chambers are 'none'; Council + Mayor remain 'full'.
DO $$
DECLARE v_none int; v_full int;
BEGIN
  SELECT
    count(*) FILTER (WHERE ch.name IN ('City Administrator','City Attorney','City Auditor') AND ch.policy_engagement_level='none'),
    count(*) FILTER (WHERE ch.name IN ('City Council','Mayor') AND ch.policy_engagement_level='full')
  INTO v_none, v_full
  FROM essentials.chambers ch JOIN essentials.governments g ON g.id=ch.government_id
  WHERE g.name='City of Portland, Oregon, US';
  IF v_none <> 3 THEN RAISE EXCEPTION 'Expected 3 Portland admin chambers set to none, found %', v_none; END IF;
  IF v_full <> 2 THEN RAISE EXCEPTION 'Expected Council+Mayor to remain full, found %', v_full; END IF;
  RAISE NOTICE 'OK: 3 Portland admin chambers -> none; Council + Mayor remain full';
END $$;
