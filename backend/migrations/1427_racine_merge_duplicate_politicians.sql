-- 1427_racine_merge_duplicate_politicians.sql
-- Merge 4 pairs of duplicate Racine County politician records into one record each.
-- Idempotent (naturally: once the dropped external_id is gone, every statement no-ops).
--
-- WHY: Racine County has a systemic pattern of one person holding a county seat AND a
--   municipal seat (or being a sitting municipal official who is also a candidate). Migrations
--   1385/1422/1424/1425/1426 deliberately created SEPARATE politician rows and flagged them,
--   because a matching name is not proof of a matching person. The cost of leaving them split
--   is that one person's photo, stances, campaign finance and Compass answers scatter across
--   two rows. This migration resolves all four in one pass, as intended.
--
-- KEEP RULE, applied uniformly: keep the record that already holds an office; when BOTH hold
--   offices, keep the COUNTY record (seeded first, in 1385). Re-point the loser's references,
--   then delete it.
--
--   person                keep (external_id)                     drop (external_id)
--   ------------------    -----------------------------------    ------------------------------
--   Gina Cefalu-Paulick   -5512003  Mt Pleasant Trustee Seat 2   -5507092  AD-66 candidate (no office)
--   Renee Kelly           -5510102  County Supervisor D2         -5511014  Racine Alderman D13
--   Tom Preusker          -5510120  County Supervisor D20        -5513008  Burlington Alderman D4
--   Troy McReynolds       -5510118  County Supervisor D18        -5515003  Waterford Vlg Trustee
--
-- REFERENCE AUDIT (done before writing this — the reason it is safe):
--   essentials.politicians is referenced by 21 FOREIGN KEYS across 6 schemas, but by 41
--   columns in 12 schemas once soft (un-constrained) references are counted. The soft ones are
--   the hazard: a DELETE would not error, it would silently orphan them. All 41 were scanned
--   for the 8 UUIDs in these pairs. Exactly TWO carry any rows:
--       essentials.offices          7 rows
--       essentials.race_candidates  1 row  (Gina's AD-66 candidacy)
--   Everything else is empty for these people — including compass.answers / compass.contexts
--   (text-keyed, from the Compass app), essentials.politician_stances, politician_images,
--   endorsements, quotes, zip_politicians, the judicial and legislative tables,
--   inform.politician_answers / politician_context, transparent_motivations.politician_sources
--   (campaign finance), meetings.la_council_votes / speakers, empower.empowered_profiles
--   (claimed profiles) and public.politician_id_bridge (cross-app identity). That is expected:
--   all 8 rows were created within the last day by this branch, so nothing downstream has
--   attached to them yet.
--   Also checked: no hardcoded reference to any of these 8 UUIDs anywhere in the repos, and
--   all 8 have slug IS NULL, so none of the six politician_slug-keyed tables
--   (civic.people/segments/meeting_speakers, meetings.speakers/local_people/segments) can
--   reference them.
--
-- SAFE BY MODEL: essentials.offices has no unique constraint on politician_id, and 25
--   politicians already hold more than one office — so one person holding two seats is an
--   established shape, not a workaround.
--
-- !! RE-RUN INTERACTION, important: migrations 1422/1424/1425/1426 guard their politician
--   INSERTs on `external_id NOT EXISTS`, so re-running any of them AFTER this merge would
--   RECREATE the dropped row. Three of the four then fail loudly and roll back, because their
--   own post-verify gates would break (1424 would see an orphan politician; 1425 would see a
--   3rd alderman in Burlington District 4; 1426 would see an 8th Waterford office). 1422 is
--   the exception: it would recreate Gina -5507092 as a harmless ORPHAN and still pass, since
--   its race_candidates guard is keyed on (race_id, lower(full_name)) and that row already
--   exists. Treat those four as superseded for these four external_ids: if any is re-run,
--   re-run THIS migration afterwards.
--
-- Name variant preserved rather than lost: Gina's two sources spell her differently — Mount
--   Pleasant uses "Gina Cefalu-Paulick", the WEC ballot uses "Gina Cefalu Paulick". The kept
--   record holds the hyphenated village form; the unhyphenated ballot form is recorded in
--   essentials.politician_name_aliases so search still matches it, and the race_candidates row
--   keeps the ballot name (the established convention for ballot-vs-roster names).
--
-- TWO EARLIER SUSPECTS, both now RESOLVED as NOT duplicates — do not "fix" them later:
--   - Tom/Thomas Weatherston (County Supervisor D17) was reported by web search to also be
--     Caledonia's Village President. FALSE: Caledonia's own board page shows the president is
--     PRESCOTT BALCH. Another instance of search staleness; there is nothing to merge.
--   - Taylor Wishau (County Supervisor D21) vs LEE Wishau (Caledonia Trustee 6) — different
--     first names, two different people. Confirmed, not a merge.
--
-- STILL OPEN, and genuinely not in the database yet: Steve Wicklund is both the AD-33 candidate
--   (seeded by 1422) and Union Grove's Village President. Union Grove is not seeded (its
--   directory still shows expired terms), so there is no duplicate row to merge. Merge when
--   Union Grove lands.
BEGIN;

-- ── 1. Preserve the ballot spelling of the name we are about to drop ──
INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
SELECT p.id, 'Gina Cefalu Paulick',
       'WEC Ballot Access Report 6.9.2026 ballot spelling; merged from politician external_id -5507092 by migration 1427'
FROM essentials.politicians p
WHERE p.external_id = -5512003
  AND NOT EXISTS (
    SELECT 1 FROM essentials.politician_name_aliases a
     WHERE a.politician_id = p.id AND lower(a.alias) = lower('Gina Cefalu Paulick')
  );

-- ── 2. Re-point offices from the dropped record to the kept record ──
UPDATE essentials.offices o
   SET politician_id = keep.id
FROM (VALUES
    (-5510102::bigint, -5511014::bigint),   -- Renee Kelly:     keep county, absorb city alder
    (-5510120,         -5513008),           -- Tom Preusker:    keep county, absorb city alder
    (-5510118,         -5515003)            -- Troy McReynolds: keep county, absorb vlg trustee
  ) AS m(keep_ext, drop_ext)
JOIN essentials.politicians keep ON keep.external_id = m.keep_ext
JOIN essentials.politicians drop_p ON drop_p.external_id = m.drop_ext
WHERE o.politician_id = drop_p.id;

-- ── 3. Re-point race_candidates (Gina's AD-66 candidacy) ──
UPDATE essentials.race_candidates rc
   SET politician_id = keep.id
FROM essentials.politicians keep, essentials.politicians drop_p
WHERE keep.external_id = -5512003
  AND drop_p.external_id = -5507092
  AND rc.politician_id = drop_p.id;

-- ── 4. Delete the now-unreferenced duplicate records ──
--    Guarded: refuses to delete anything that still has an office or a candidacy, so a partial
--    failure above can never strand a reference.
DELETE FROM essentials.politicians p
WHERE p.external_id IN (-5507092, -5511014, -5513008, -5515003)
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id)
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.politician_id = p.id);

-- ── 5. Post-verify gate ──
DO $$
DECLARE n_dropped int; n_dupe_names int; r record; n_off int;
BEGIN
  -- the 4 dropped records must be gone
  SELECT count(*) INTO n_dropped FROM essentials.politicians
   WHERE external_id IN (-5507092, -5511014, -5513008, -5515003);
  IF n_dropped <> 0 THEN
    RAISE EXCEPTION '% duplicate politician rows survived the merge (still referenced?)', n_dropped;
  END IF;

  -- each kept record must now hold the expected number of offices
  FOR r IN SELECT * FROM (VALUES
      (-5512003::bigint, 1),   -- Gina: Mt Pleasant trustee (her AD-66 row is a candidacy, not an office)
      (-5510102::bigint, 2),   -- Renee Kelly:     county supervisor + Racine alderman
      (-5510120::bigint, 2),   -- Tom Preusker:    county supervisor + Burlington alderman
      (-5510118::bigint, 2)    -- Troy McReynolds: county supervisor + Waterford trustee
    ) AS t(ext, want) LOOP
    SELECT count(*) INTO n_off FROM essentials.offices o
      JOIN essentials.politicians p ON p.id = o.politician_id
     WHERE p.external_id = r.ext;
    IF n_off <> r.want THEN
      RAISE EXCEPTION 'politician % holds % offices, want %', r.ext, n_off, r.want;
    END IF;
  END LOOP;

  -- Gina's candidacy must have followed her to the kept record
  IF NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
      JOIN essentials.politicians p ON p.id = rc.politician_id
     WHERE p.external_id = -5512003 AND lower(rc.full_name) = lower('Gina Cefalu Paulick')
  ) THEN
    RAISE EXCEPTION 'Gina Cefalu Paulick candidacy did not follow the merge';
  END IF;

  -- No WI office may point at a politician that no longer exists.
  -- SCOPED TO WI ON PURPOSE. essentials.offices.politician_id has NO FOREIGN KEY (verified:
  -- zero FK constraints on that column), and prod ALREADY contains 2 orphaned office rows
  -- that predate this branch entirely — a CA 'U.S. Representative' and an IN 'Assessor'.
  -- An unscoped check trips on those and would block this migration for someone else's data.
  -- Those 2 are worth cleaning up separately; they are not this migration's business.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
     WHERE o.politician_id IS NOT NULL
       AND o.representing_state = 'WI'
       AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = o.politician_id)
  ) THEN
    RAISE EXCEPTION 'orphaned WI office rows detected after merge';
  END IF;

  -- and no duplicate names should remain among Racine County's seeded officials
  SELECT count(*) INTO n_dupe_names FROM (
    SELECT lower(full_name) FROM essentials.politicians
     WHERE external_id BETWEEN -5521999 AND -5510001
     GROUP BY lower(full_name) HAVING count(*) > 1
  ) x;
  IF n_dupe_names <> 0 THEN
    RAISE EXCEPTION '% duplicate names still present among Racine County officials', n_dupe_names;
  END IF;

  RAISE NOTICE 'Racine duplicate merge PASSED: 4 records dropped, 3 people now hold 2 offices each, 1 candidacy re-pointed, 0 orphans.';
END $$;

COMMIT;
