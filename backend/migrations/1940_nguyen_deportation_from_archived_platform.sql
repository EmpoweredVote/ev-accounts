-- 1940 — Seat Tram T. Nguyen's Season 2 deportation chair from her archived campaign platform.
--
-- WHY THIS EXISTS. Migration 1939 researched eight (person, topic) pairs and seated two. One of the
-- six refusals was Nguyen / deportation, and it was refused for a reason that was explicitly NOT a
-- finding: the Internet Archive answered "Temporarily Offline" for the CDX path, so her campaign
-- platform could be neither read nor ruled out. 1939's header recorded that absence as UNCHECKED
-- and owed a re-try. This is that re-try, and it reverses the refusal.
--
-- THE EVIDENCE. tramforcongress.com/issues/immigration-ice, captured 2026-07-27 and again
-- 2026-08-30. Her first of five immigration commitments:
--     "Abolish ICE and overhaul the immigration system by creating an accessible, transparent
--      pathway to citizenship that incentivizes legal entry, keeps families together, and treats
--      immigrants with basic human dignity"
-- and her last:
--     "Ensure that all individuals, including undocumented immigrants, can access the legal system,
--      report crimes, and utilize public services without fear."
--
-- 🔑 THE TWO CAPTURES ARE THE SAME COPY. Their CDX digests differ, which is why both are cited, but
-- the policy text is identical in both; the diff is a "Vote!" nav item and a press-contact address.
-- This is settled campaign copy, not a draft that happened to be crawled once.
--
-- WHY CHAIR 1 AND NOT CHAIR 2. The ladder is about who gets removed. Her platform carries no
-- enforcement commitment at all: none of its five items redirects removal to another agency, and it
-- nowhere names a category of people who should be removed. Chair 2 ("only deport undocumented
-- immigrants convicted of serious violent crimes") REQUIRES that carve-out, and its holders say it
-- plainly. Abolishing the removal agency outright, rather than redirecting it, is chair 1.
--
-- ⚖ THE CONTRARY SIGNAL, WEIGHED AND NOT SUPPRESSED. Her separate /issues/safe-communities page
-- asks Congress to lift the caps on U- and T-visas so crime victims may cooperate with police
-- "without fear of deportation". A victim-specific carve-out presumes removals continue, which cuts
-- against chair 1. It is cited below so a reader can weigh it too. It does not carry the day: it
-- concerns federal visa caps that exist regardless of her removal posture, and it names no class she
-- would remove, so it narrows the margin without reaching chair 2.
--
-- 🔴 A 200 FROM THE LIVE DOMAIN IS NOT A LIVE PAGE. tramforcongress.com answers HTTP 200 and the
-- body is "Site paused or lapsed." The lapse is real; only reading the body reveals it. The archived
-- captures are cited in place of the dead domain, and all three were fetched and returned 200.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE PRE-WRITE GATE FAILS THIS ROW, BY CONSTRUCTION, AND THAT IS NOT A WAIVER.
--
--   scripts/audit-chair-evidence.mjs --csv backend/data/stance-research/
--     deportation-archive-recheck-1940/stances.csv
--   -> FAIL: 1 of 1 row(s) seat a chair on reasoning that names no instrument, act or vote.
--
-- That gate tests NAMES_INSTRUMENT: does the reasoning name a bill, act, ordinance or recorded vote?
-- It is a `record`-basis test. It never reads inform.compass_topic_roles.evidence_basis, and
-- scripts/lib/chair-evidence-patterns.mjs says in its own header that "a campaign platform" is a
-- PROGRAMME it deliberately refuses to admit, adding: "They may well be sound evidence, but they are
-- not the thing this gate tests, and inventing lexical hooks for them would make passing mean
-- nothing." The reasoning below was therefore NOT reworded to satisfy the pattern; doing so is the
-- precise failure that header warns against.
--
-- 🔑 MEASURED, not asserted. Of the 1,243 seated Season 2 rows whose topic is `own-words` at some
-- role scope, 536 (43%) fail this same pattern. Every seated deportation row on an own-words basis
-- fails it, at all four occupied chairs:
--     Mikel Wein chair 1 · David Womack chair 2 · Richard Ojeda chair 3 · Jared Patterson chair 4
-- If the instrument gate bound `own-words` topics, the `own-words` basis could never be satisfied by
-- anything and all 42 own-words (topic, role_scope) pairs would be dead letters.
--
-- ⚖ THE GATE THAT DOES BIND IS compass_topic_roles.evidence_basis, and it is asserted in the
-- pre-flight below: deportation at STATE scope is `own-words`, and Nguyen sits at state scope.
-- ─────────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔑 THE CHAIR-1 STANDARD IS ALREADY IN THE DATA. The one other Season 2 row seated at this rung was
-- seated on a candidate survey pledging to "de-fund services, such as ICE", and its reasoning states
-- the test outright: dismantling the removal apparatus rather than redirecting it. "Abolish" clears
-- a bar that "de-fund" already cleared.
--
-- ⚠ THIS IS THE SURVIVOR ROW, NOT THE RETIRED DUPLICATE. Two people rows carry this name.
-- fc1d7143 "Tram T. Nguyen" is the survivor and is the row migration 1939 wrote medicare/aid to.
-- 0896566a "Tram Nguyen" is the duplicate retired by 1938; it holds the Season 1 deportation answer
-- and is NOT touched here. Her Season 1 value was also 1, sourced to this same domain, so this
-- re-derivation lands where the un-portable row sat — but on evidence read in this pass, not ported.
--
-- APPLIED BY HAND. No migration runner exists in this repo; this file records SQL applied via the
-- Supabase MCP against production. "Applied" means its data effects are live.

BEGIN;

CREATE TEMP TABLE mig1940_targets (
  politician_id      uuid,
  topic_id           uuid,
  topic_revision_id  uuid,
  chair              numeric,
  who                text,
  reasoning          text,
  sources            text[]
) ON COMMIT DROP;

INSERT INTO mig1940_targets VALUES
( 'fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid,
  '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,
  '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid,
  1,
  'Nguyen / deportation',
  $txt$Nguyen's congressional campaign platform commits her, first among five immigration pledges, to "Abolish ICE and overhaul the immigration system by creating an accessible, transparent pathway to citizenship that incentivizes legal entry, keeps families together, and treats immigrants with basic human dignity", and last to "Ensure that all individuals, including undocumented immigrants, can access the legal system, report crimes, and utilize public services without fear." This topic is seated on an own-words basis at state scope, which is what a campaign platform supplies. The platform carries no enforcement commitment: none of its five items redirects removal to another agency, and it nowhere names a category of people who should be removed — the carve-out chair 2 requires. Abolishing the removal agency outright, rather than redirecting it, is chair 1. The page is archived twice, on 27 July and 30 August 2026, with identical policy text; the two captures differ only by a nav item and a press contact, so this is settled campaign copy and not a single draft. Weighed against it: her separate Safe Communities page asks Congress to lift the caps on U- and T-visas so crime victims may cooperate with police "without fear of deportation". That carve-out presumes removals continue, but it concerns federal visa caps that exist regardless of her removal posture and names no class she would remove, so it narrows the margin without reaching chair 2. Her campaign domain now serves a "Site paused or lapsed" shell under an HTTP 200 response, so the archived captures are cited in its place.$txt$,
  ARRAY[
    'https://web.archive.org/web/20260727021941/https://www.tramforcongress.com/issues/immigration-ice',
    'https://web.archive.org/web/20260830222738/https://www.tramforcongress.com/issues/immigration-ice',
    'https://web.archive.org/web/20260727021941/https://www.tramforcongress.com/issues/safe-communities'
  ]
);

-- ─── PRE-FLIGHT ──────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  IF (SELECT count(*) FROM mig1940_targets) <> 1 THEN
    RAISE EXCEPTION 'migration 1940: expected 1 target, found %', (SELECT count(*) FROM mig1940_targets);
  END IF;

  -- Season 2 must still be the open season.
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                  WHERE id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status='open') THEN
    RAISE EXCEPTION 'migration 1940: Season 2 is not open — do not write to a closed season';
  END IF;

  -- 🔴 THE LADDER IS REVISION-SCOPED. The revision id must be the one Season 2 actually serves for
  -- this topic; reading compass_stances instead put a wrong chair in prod in migration 1935.
  SELECT count(*) INTO n
    FROM mig1940_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.season_questions sq
      WHERE sq.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND sq.topic_id = t.topic_id
        AND sq.topic_revision_id = t.topic_revision_id);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1940: % target(s) name a revision Season 2 does not serve', n; END IF;

  -- The chair must exist on that revision's ladder, and it must read as the stop-removals rung.
  SELECT count(*) INTO n
    FROM mig1940_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.compass_stance_revisions csr
      WHERE csr.topic_revision_id = t.topic_revision_id AND csr.value = t.chair);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1940: % target(s) name a rung that does not exist in this season', n; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions csr
     WHERE csr.topic_revision_id='55c3167e-3ad8-425d-a699-b2e91552d912'::uuid
       AND csr.value = 1 AND csr.text ILIKE '%stop deportations entirely%') THEN
    RAISE EXCEPTION 'migration 1940: rung 1 is not the ladder text this migration was written against — re-read the ladder';
  END IF;

  -- ⚖ THE GATE THAT ACTUALLY BINDS. This topic must admit the member's own words at state scope.
  -- If this ever flips to `record`, a campaign platform stops being admissible and this row must go.
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topic_roles r
     WHERE r.topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
       AND r.role_scope='state' AND r.evidence_basis='own-words') THEN
    RAISE EXCEPTION 'migration 1940: deportation is not `own-words` at state scope — a campaign platform cannot seat this chair';
  END IF;

  -- This is an INSERT. If a row already exists for the pair in any season, stop and re-measure.
  SELECT count(*) INTO n
    FROM mig1940_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1940: % answer row(s) already exist for this pair — this migration only inserts', n; END IF;

  -- ⚠ The retired duplicate must not be the write target, and must not be disturbed.
  IF EXISTS (SELECT 1 FROM mig1940_targets
              WHERE politician_id='0896566a-c773-4227-aca3-18cf573b60fe'::uuid) THEN
    RAISE EXCEPTION 'migration 1940: target is the RETIRED duplicate, not the survivor';
  END IF;
END $$;

-- ─── THE WRITE ───────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers
  (politician_id, topic_id, value, season_id, topic_revision_id)
SELECT t.politician_id, t.topic_id, t.chair,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, t.topic_revision_id
  FROM mig1940_targets t;

INSERT INTO inform.politician_context
  (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id)
SELECT t.politician_id, t.topic_id, t.reasoning, t.sources,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, t.topic_revision_id
  FROM mig1940_targets t;

-- ─── POST-FLIGHT ─────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  -- The row exists at exactly the chair claimed, on the revision claimed.
  SELECT count(*) INTO n
    FROM mig1940_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id=t.politician_id AND pa.topic_id=t.topic_id
     AND pa.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = t.chair AND pa.topic_revision_id = t.topic_revision_id;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1940: expected 1 row at its stated chair, found %', n; END IF;

  -- The seated row carries citations.
  SELECT count(*) INTO n
    FROM mig1940_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
     AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources),0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1940: % row(s) carry no citation', n; END IF;

  -- 🔑 The checkable identifier for an own-words row sourced to a lapsed domain is the CAPTURE.
  -- A bare tramforcongress.com URL would 200 on a "Site paused or lapsed" shell and prove nothing.
  SELECT count(*) INTO n
    FROM mig1940_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
     AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s LIKE 'https://web.archive.org/web/%');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1940: % seated row(s) cite no archived capture', n; END IF;

  -- 🔴 BLAST RADIUS: this migration adds one Season 2 answer and nothing else.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
   WHERE pa.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.created_at > now() - interval '5 minutes';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1940: % Season 2 answer(s) created in this window, expected 1', n; END IF;

  -- Season 1 is closed and must not have moved — including the retired duplicate's row.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
   WHERE pa.updated_at > now() - interval '5 minutes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1940: % Season 1 answer(s) were modified — Season 1 is closed', n; END IF;

  RAISE NOTICE 'migration 1940: seated Nguyen/deportation at chair 1 from the archived platform; 1939''s unchecked absence is now checked';
END $$;

COMMIT;
