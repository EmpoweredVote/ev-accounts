-- CC_0275_texas_2026_general_candidate_people.sql
--
-- Texas 2026 General. Creates 11 politician rows and links them. Texas then reads 170 of 170.
--
-- All eleven are **Austin City Council** candidates, across districts 1, 3, 5, 8 and 9.
--
-- ═══ THE SIMPLEST COHORT IN THE PROGRAMME, AND THAT IS THE FINDING ═══
-- Texas is the only state where the dedupe pass returned **ZERO variant hits**. No exact name, no
-- differently split name, no accent, no punctuation difference, no diminutive, no archived twin.
-- Eleven candidates, eleven genuinely new people.
-- ⚠ THAT IS NOT A REASON TO SKIP THE PASS -- it is the result of running it. Indiana looked
-- equally routine and came back 10 hits against 13 candidates. The pass is cheap; the assumption
-- that a cohort is clean is what is expensive.
-- 🔴 And there is nothing to refuse here, which is itself unusual: this is the first state cohort
-- since California with no cross-state namesake to catch.
--
-- ═══ CREATED -- 11 ═══
--   District 1  Portia Riggins
--   District 3  Eduardo "Lalito" Romero · Gavin Fernandez Jr. · Neha Shah
--   District 5  David Weinberg · Farrah Abraham · Liz Brink
--   District 8  Selena Xie
--   District 9  Dave Thadani · Kai Huang · Katie Kam
--
-- ⚠ TWO NAMES NEED THE SPLIT RULES AND BOTH ARE HANDLED:
--   * `Eduardo "Lalito" Romero` -- the QUOTED NICKNAME is stripped from the first/last split but
--     kept verbatim in full_name, because full_name is what the voter sees on the ballot. Without
--     stripping, first_name would be `Eduardo "Lalito"` and the duplicate guard would key on a
--     string no other row can ever match -- silently defeating the guard for this person. There
--     are 11 active Romeros, so this is exactly the row where the key must be right.
--   * `Gavin Fernandez Jr.` -- the generational suffix is excluded from last_name, so the guard
--     keys on `Gavin` / `Fernandez`. ⚠ The suffix stays in full_name: CC_0273 refused William E.
--     Smith III precisely because a suffix distinguishes two people, so it must never be dropped
--     from the displayed name.
--
-- ▶ WHAT EACH ROW ASSERTS: existence and nothing else. `is_active=true`,
-- **`is_incumbent=FALSE` named explicitly** (CA_0188), `external_id` NULL, `party` NULL
-- (antipartisan -- it lives on `races.primary_party`), and NO office_terms row. None of them
-- holds anything and none is claimed to.
-- ▶ Inserted ONE AT A TIME, linking on `rc_id` rather than `full_name`, because two candidates in
-- different districts can share a name. Three of these races have three candidates each.
-- 🔴 The database's own duplicate-name trigger stays ARMED for all eleven. No escape hatch is
-- opened in this migration -- there is no adjudicated collision to excuse.
--
-- Idempotent: re-running inserts nothing.

BEGIN;

CREATE TEMP TABLE _new AS
WITH src AS (
  SELECT rc.id AS rc_id, rc.full_name,
         btrim(regexp_replace(rc.full_name, '\s*"[^"]*"\s*', ' ', 'g')) AS clean
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.state = 'TX' AND e.election_date >= current_date
    AND rc.politician_id IS NULL
)
SELECT rc_id, full_name,
       btrim(regexp_replace(
         btrim(regexp_replace(clean, '\s+(Jr\.?|Sr\.?|I{2,3}|IV)$', '', 'i')),
         '\s+\S+$', '')) AS first_name,
       regexp_replace(
         btrim(regexp_replace(clean, '\s+(Jr\.?|Sr\.?|I{2,3}|IV)$', '', 'i')),
         '^.*\s', '') AS last_name,
       NULL::uuid AS new_id
FROM src;

DO $$
DECLARE n int; bad int;
BEGIN
  SELECT count(*) INTO n FROM _new;
  IF n <> 11 THEN
    RAISE EXCEPTION 'CC_0275: expected 11 to create, found % - the set moved, re-run the dedupe '
                    'pass before writing', n;
  END IF;

  SELECT count(*) INTO bad FROM _new
   WHERE coalesce(btrim(first_name),'')='' OR coalesce(btrim(last_name),'')='';
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0275: % split to an empty name part', bad; END IF;

  -- 🔴 the nickname must be gone from the SPLIT and present in full_name
  PERFORM 1 FROM _new WHERE full_name LIKE '%"Lalito"%' AND first_name = 'Eduardo'
                        AND last_name = 'Romero';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0275: the quoted nickname was not stripped from the first/last split - '
                    'the duplicate guard would key on a string nothing can match';
  END IF;
  -- and the suffix must be gone from last_name but kept in full_name
  PERFORM 1 FROM _new WHERE full_name = 'Gavin Fernandez Jr.' AND last_name = 'Fernandez';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0275: the generational suffix handling changed';
  END IF;

  -- no collisions on either key, active or archived. No carve-outs in this migration.
  SELECT count(*) INTO bad FROM _new nw
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE (lower(p.first_name)=lower(nw.first_name)
                     AND lower(p.last_name)=lower(nw.last_name))
                     OR lower(p.full_name)=lower(nw.full_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0275: % of the 11 collide with an existing person - Texas was measured '
                    'as having ZERO variant hits, so this means the data moved. REFUSING', bad;
  END IF;
END $$;

DO $$
DECLARE r record; v_id uuid;
BEGIN
  FOR r IN SELECT * FROM _new ORDER BY full_name LOOP
    INSERT INTO essentials.politicians (full_name, first_name, last_name,
                                        is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, false,
            'tx-2026-general CC_0275 (Austin City Council candidate list; no office asserted)')
    RETURNING id INTO v_id;
    UPDATE _new SET new_id = v_id WHERE rc_id = r.rc_id;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = nw.new_id
FROM _new nw
WHERE rc.id = nw.rc_id AND nw.new_id IS NOT NULL AND rc.politician_id IS NULL;

DO $$
DECLARE n_make int; n_left int; n_bad int; n_terms int;
BEGIN
  SELECT count(*) INTO n_make FROM essentials.race_candidates rc
    JOIN _new nw ON nw.rc_id=rc.id WHERE rc.politician_id = nw.new_id;
  IF n_make <> 11 THEN RAISE EXCEPTION 'CC_0275: expected 11 created+linked, found %', n_make; END IF;

  SELECT count(*) INTO n_bad FROM _new nw JOIN essentials.politicians p ON p.id=nw.new_id
   WHERE p.is_incumbent IS DISTINCT FROM false OR p.is_active IS DISTINCT FROM true
      OR p.external_id IS NOT NULL OR p.party IS NOT NULL;
  IF n_bad <> 0 THEN RAISE EXCEPTION 'CC_0275: % new row(s) assert more than existence', n_bad; END IF;

  SELECT count(*) INTO n_terms FROM essentials.office_terms ot
    JOIN _new nw ON nw.new_id = ot.politician_id;
  IF n_terms <> 0 THEN RAISE EXCEPTION 'CC_0275: % new person(s) hold an office term', n_terms; END IF;

  -- 🟢 Texas must now be complete
  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.state='TX' AND e.election_date >= current_date AND rc.politician_id IS NULL;
  IF n_left <> 0 THEN RAISE EXCEPTION 'CC_0275: % TX rows still unlinked, expected 0', n_left; END IF;

  RAISE NOTICE 'CC_0275 OK - 11 created and linked; Texas fully linked';
END $$;

DROP TABLE _new;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: A CLEAN COHORT IS A RESULT, NOT AN ASSUMPTION.
-- Texas returned ZERO variant hits -- the only state that has. Indiana looked just as routine
-- and came back with 10 hits against 13 candidates, 8 of which were real people we already held.
-- The pass costs one query. Skipping it is what costs merges.
-- ⚠ AND THE SPLIT RULES EARN THEIR KEEP ON ONE ROW IN ELEVEN. `Eduardo "Lalito" Romero` would
-- have keyed the duplicate guard on `Eduardo "Lalito"` / `Romero` -- a string no other row can
-- ever equal -- silently exempting him from the guard among 11 active Romeros. Strip the nickname
-- from the SPLIT, never from the displayed name.
-- ───────────────────────────────────────────────────────────────────────────────────────────
