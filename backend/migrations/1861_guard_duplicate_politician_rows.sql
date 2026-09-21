-- 1861_guard_duplicate_politician_rows.sql
--
-- Stops a person row being minted for somebody who already exists, which is the defect behind
-- migrations 1554, 1555, 1572 and 1860.
--
-- No migration runner exists; this file records SQL applied by hand.
--
-- =============================================================================================
-- WHY A TRIGGER, AND WHY NOT A UNIQUE INDEX
-- =============================================================================================
-- The failure: a hand-add session mints a NEW essentials.politicians row for a person who is
-- already there, the race_candidates edge lands on the new row, and the curated quotes stay on
-- the old one. Read & Rank reaches a quote ONLY through
-- race_candidates.politician_id = quotes.politician_id, so those quotes go permanently invisible.
--
-- UNIQUE(external_id) (mig 191) cannot catch it. A fresh synthetic -66000122 never collides with
-- Kris Mayes's real -400092, so the insert passes and mints a twin. There is no name or slug
-- uniqueness anywhere in the schema.
--
-- 🔴 A UNIQUE INDEX ON THE NAME IS IMPOSSIBLE, and this is the whole reason the guard is shaped
--   like this. Same-name-different-human is common and legitimate here: three Mike Rogers, two
--   Andrew Rices (a CT-03 progressive Democrat and a VA Delegate Republican), a Jason Hart in
--   Kansas and another in Indiana, three Scott Smiths. At the time of writing 190 active rows
--   share a first+last with another active row and most are genuinely different people. A unique
--   index would refuse all of them, permanently, with no way through.
--
-- So the guard cannot DECIDE. It can only make the operator look. It raises, names the rows it
-- found, and offers a transaction-scoped way past — modelled on CC_0044's closed-season trigger,
-- which faced the same "must be blockable, must be escapable" problem.
--
--     SET LOCAL essentials.allow_duplicate_name = 'on';
--
-- =============================================================================================
-- WHAT THIS DOES NOT CATCH, STATED PLAINLY
-- =============================================================================================
-- A bulk loader that sets the GUC once for a 400-row migration has the guard off for all 400.
-- That is not a hole to be plugged, it is the shape of the tool: a trigger fires per row but the
-- hatch is per transaction. The trigger is aimed at the path that actually caused the damage —
-- an interactive or agent-driven hand-add, a few rows at a time, where a raised exception is
-- read by someone who can act on it.
--
-- The net under the bulk path is essentials.v_duplicate_person_suspects, created below. It has no
-- opinion about who is who; it reports name twins and what each row holds, and flags the exact
-- damaging shape: one row holds the quotes, another holds the race edge. Nothing schedules it.
-- Run it after any bulk load, and periodically.
--
-- It also does not fire on UPDATE. Renaming an existing row into a collision is possible but has
-- never happened here, and an UPDATE-side check would fire on every ordinary name correction.
--
-- =============================================================================================
-- BLAST RADIUS
-- =============================================================================================
-- Only INSERT, only when first_name AND last_name are both present, and only against ACTIVE
-- rows. Deactivated rows are ignored on purpose: they are usually the loser of an earlier merge
-- (1554, 1860), and matching one must not block a legitimate new person.
--
-- Known callers that will now raise on a namesake and have no GUC: adminService.ts
-- adminCreatePolitician (the admin UI "create politician" button), stagingService.ts
-- promoteToEssentials on its null-external_id branch, and seedPolitician.ts createFederalPolitician.
-- The exception text is written to be readable by whoever hits it. Making the admin UI turn it
-- into a "possible duplicate — confirm" prompt is app work and is NOT done here.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- 1. The guard
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION essentials.politician_name_duplicate_guard()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
  v_allowed boolean;
  v_hits    text;
  v_n       integer;
BEGIN
  -- current_setting(..., true) returns NULL rather than raising when the GUC was never set,
  -- which is the normal case on every ordinary insert.
  v_allowed := COALESCE(
    NULLIF(current_setting('essentials.allow_duplicate_name', true), ''),
    'off'
  ) = 'on';

  IF v_allowed THEN
    RETURN NEW;
  END IF;

  -- Nothing to compare against. Rows arriving with only a full_name are out of scope; the
  -- monitoring view still sees them.
  IF NEW.first_name IS NULL OR NEW.last_name IS NULL THEN
    RETURN NEW;
  END IF;

  -- Only an ACTIVE namesake blocks. A deactivated row is normally the loser of an earlier merge.
  SELECT count(*),
         string_agg(
           format('%s (external_id %s, %s quote(s), %s race edge(s), office %L)',
                  p.id, COALESCE(p.external_id::text, 'NULL'),
                  (SELECT count(*) FROM essentials.quotes q WHERE q.politician_id = p.id),
                  (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id),
                  COALESCE((SELECT o.title
                              FROM essentials.office_terms t
                              JOIN essentials.offices o ON o.id = t.office_id
                             WHERE t.politician_id = p.id
                             LIMIT 1), 'none')),
           E'\n    ')
    INTO v_n, v_hits
  FROM essentials.politicians p
  WHERE p.is_active
    AND lower(btrim(p.first_name)) = lower(btrim(NEW.first_name))
    AND lower(btrim(p.last_name))  = lower(btrim(NEW.last_name));

  IF v_n > 0 THEN
    RAISE EXCEPTION E'DUPLICATE_POLITICIAN_NAME: % active politician row(s) already carry the name %.\n    %\nIf this is the SAME person, do NOT insert. Point race_candidates.politician_id at the existing row instead — quotes attach to politician_id, and a quote on a row with no race edge is invisible in Read & Rank. A sitting officeholder running for a different seat is the normal case, not a different person.\nIf it is genuinely a DIFFERENT person (there are three Mike Rogers and two Andrew Rices), say so and proceed: SET LOCAL essentials.allow_duplicate_name = ''on'';',
      v_n, btrim(NEW.first_name) || ' ' || btrim(NEW.last_name), v_hits;
  END IF;

  RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION essentials.politician_name_duplicate_guard() IS
  'Blocks INSERT of a politician whose first+last matches an ACTIVE row, so a duplicate person '
  'cannot be minted silently (see migrations 1554/1555/1572/1860). Escape hatch: '
  'SET LOCAL essentials.allow_duplicate_name = ''on''. Does not fire on UPDATE, on rows lacking '
  'first/last, or against deactivated rows.';

DROP TRIGGER IF EXISTS politicians_name_duplicate_guard ON essentials.politicians;
CREATE TRIGGER politicians_name_duplicate_guard
  BEFORE INSERT ON essentials.politicians
  FOR EACH ROW EXECUTE FUNCTION essentials.politician_name_duplicate_guard();

-- ---------------------------------------------------------------------------------------------
-- 2. The net under the bulk path
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW essentials.v_duplicate_person_suspects AS
WITH active AS (
  SELECT p.id, p.full_name, p.external_id,
         lower(btrim(p.first_name)) AS fk,
         lower(btrim(p.last_name))  AS lk,
         (SELECT count(*) FROM essentials.quotes q
           WHERE q.politician_id = p.id)                              AS quotes,
         (SELECT count(*) FROM essentials.quotes q
           WHERE q.politician_id = p.id AND q.readrank_selected)      AS selected_quotes,
         (SELECT count(*) FROM essentials.race_candidates rc
           WHERE rc.politician_id = p.id)                             AS race_edges,
         (SELECT o.title FROM essentials.office_terms t
             JOIN essentials.offices o ON o.id = t.office_id
            WHERE t.politician_id = p.id LIMIT 1)                     AS office
  FROM essentials.politicians p
  WHERE p.is_active AND p.first_name IS NOT NULL AND p.last_name IS NOT NULL
)
SELECT
  a.fk || ' ' || a.lk AS name_key,
  a.id, a.full_name, a.external_id, a.office,
  a.quotes, a.selected_quotes, a.race_edges,
  count(*) OVER (PARTITION BY a.fk, a.lk) AS rows_with_this_name,
  -- 🔴 the damaging shape: this row holds quotes but no race edge, while a namesake holds one.
  -- That is exactly what made Mayes's, Kolodin's and Schweikert's quotes invisible.
  (a.quotes > 0 AND a.race_edges = 0 AND EXISTS (
     SELECT 1 FROM active b
      WHERE b.fk = a.fk AND b.lk = a.lk AND b.id <> a.id AND b.race_edges > 0
   )) AS quotes_stranded_off_the_race,
  (a.selected_quotes > 0 AND a.race_edges = 0 AND EXISTS (
     SELECT 1 FROM active b
      WHERE b.fk = a.fk AND b.lk = a.lk AND b.id <> a.id AND b.race_edges > 0
   )) AS live_quotes_stranded_off_the_race
FROM active a
WHERE EXISTS (SELECT 1 FROM active b WHERE b.fk = a.fk AND b.lk = a.lk AND b.id <> a.id);

COMMENT ON VIEW essentials.v_duplicate_person_suspects IS
  'Active politicians sharing a first+last with another active row, with what each row holds. '
  'Most rows here are legitimately different people — this view reports, it does not judge. '
  'The column that matters is quotes_stranded_off_the_race: quotes on one row, the race edge on '
  'a namesake, which is invisible in Read & Rank. Run after any bulk load.';

GRANT SELECT ON essentials.v_duplicate_person_suspects TO PUBLIC;

-- ---------------------------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n integer; blocked boolean;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger
                  WHERE tgname = 'politicians_name_duplicate_guard'
                    AND tgrelid = 'essentials.politicians'::regclass) THEN
    RAISE EXCEPTION 'trigger was not created';
  END IF;

  IF to_regclass('essentials.v_duplicate_person_suspects') IS NULL THEN
    RAISE EXCEPTION 'monitoring view was not created';
  END IF;

  -- It must actually block. Kris Mayes is active, so this insert has to fail.
  blocked := false;
  BEGIN
    INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, is_active)
    VALUES (-99999001, 'Kris', 'Mayes', 'Kris Mayes', true);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'DUPLICATE_POLITICIAN_NAME:%' THEN blocked := true;
    ELSE RAISE; END IF;
  END;
  IF NOT blocked THEN RAISE EXCEPTION 'guard did NOT block a known duplicate name'; END IF;

  -- The hatch must work.
  SET LOCAL essentials.allow_duplicate_name = 'on';
  INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, is_active)
  VALUES (-99999001, 'Kris', 'Mayes', 'Kris Mayes', true);
  DELETE FROM essentials.politicians WHERE external_id = -99999001;
  SET LOCAL essentials.allow_duplicate_name = 'off';

  -- A genuinely new name must pass with no hatch.
  INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, is_active)
  VALUES (-99999002, 'Zzqx', 'Wvutt', 'Zzqx Wvutt', true);
  DELETE FROM essentials.politicians WHERE external_id = -99999002;

  SELECT count(*) INTO n FROM essentials.v_duplicate_person_suspects;
  RAISE NOTICE 'PASSED: guard blocks duplicates, hatch opens, new names pass; view reports % namesake row(s), % with quotes stranded off the race.',
    n, (SELECT count(*) FROM essentials.v_duplicate_person_suspects WHERE quotes_stranded_off_the_race);
END $$;

COMMIT;
