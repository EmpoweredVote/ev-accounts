-- Migration 1066: Security advisor remediation — function_search_path_mutable (2 WARN)
--
-- The advisor flagged two functions with a mutable (unset) search_path:
--   essentials.mirror_candidate_data_to_politician(uuid, text, text)
--   essentials.trg_race_candidate_mirror_data()        [trigger]
--
-- Both already reference every object fully schema-qualified (essentials.*) and
-- otherwise use only pg_catalog built-ins (coalesce, array_length,
-- gen_random_uuid — pg_catalog is always implicitly searched even with an empty
-- search_path). So pinning search_path = '' is safe and is the gold-standard
-- remediation: it removes the mutable-search_path attack surface without
-- changing behavior. Reversible via RESET.

BEGIN;

ALTER FUNCTION essentials.mirror_candidate_data_to_politician(uuid, text, text)
  SET search_path = '';

ALTER FUNCTION essentials.trg_race_candidate_mirror_data()
  SET search_path = '';

-- Verify both now carry an explicit search_path config.
SELECT n.nspname || '.' || p.proname AS func, p.proconfig
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'essentials'
  AND p.proname IN ('mirror_candidate_data_to_politician', 'trg_race_candidate_mirror_data');

COMMIT;
