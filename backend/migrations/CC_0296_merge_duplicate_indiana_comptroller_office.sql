-- CC_0296 — merge the duplicate Indiana Comptroller office.
--
-- This finishes what `CC_0295` started and deliberately left. That migration retired Indiana's
-- duplicate Secretary of State and Treasurer rows; its own post-verify gate then FAILED the dry
-- run on a third duplicate, `Comptroller x2`, which could not be retired the same way. This is
-- that third one.
--
-- ─── WHY THE OTHER TWO WERE A DELETE AND THIS ONE IS A MERGE ─────────────────────────────
-- `CC_0295`'s pair were each held by one person on BOTH copies, so the duplicate row carried
-- nothing the canonical row did not already have and could simply go. The Comptroller is split
-- the other way round — the term and the race sit on DIFFERENT copies:
--
--   | copy                                  | district                          | term | race |
--   | ------------------------------------- | --------------------------------- | ---- | ---- |
--   | 22565e22-45aa-4e33-bafc-2c8816f2a984  | 97db28b9… `geo_id=''`  "Indiana"  |  1   |  0   |
--   | 5b86a68f-e42a-4b79-bbf9-a3cb6ce94896  | 883ffb10… `geo_id='18'` "Indiana Comptroller" | 0 | 1 |
--
-- Deleting the held copy would unseat Indiana's sitting Comptroller. Deleting the empty copy
-- would orphan her election. So the term moves onto the canonical copy and the other row goes.
--
-- ─── 🔴 A CORRECTION TO WHAT `CC_0295`'s PR SAID ABOUT THIS SEAT ─────────────────────────
-- That PR stated the two Comptroller rows "key differently under BOTH the old and the new
-- scheme, so Indiana already returns two Comptroller rows today". **That is wrong, and it was
-- never measured end to end — only reasoned about from the de-dup key.**
--
-- Measured against the LIVE endpoint after `CC_0295` deployed: an Indianapolis address returns
-- exactly ONE Comptroller row. The empty copy never reaches a voter at all, and the de-dup key
-- has nothing to do with it. `buildStatewideQuery` in `backend/src/lib/districtQueries.ts` ends
-- its WHERE with
--
--     AND (p.is_active = true OR o.is_vacant = true)
--
-- and `5b86a68f…` is unseated AND unflagged, so it satisfies neither arm. This is CLAUDE.md's
-- own rule — *"an office with no `office_terms` row is invisible… and nothing errors"* — and the
-- read-path fix did not change it.
-- ▶ **REASONING ABOUT A READ PATH IS NOT MEASURING IT.** The de-dup key was the right thing to
--   look at for the other two duplicates and the wrong thing to look at for this one, and the
--   difference was only visible by asking the live endpoint.
--
-- ─── WHICH COPY IS CANONICAL, AND THE SHAPE QUESTION `CC_0295` LEFT OPEN ─────────────────
-- `CC_0295` kept the race-carrying copies and wrote down that it was dodging the wider question:
-- which district shape is right for Indiana's statewide executives. Measuring all 17 Indiana
-- STATE_EXEC offices answers it, and the split is not arbitrary:
--
--   `geo_id = '18'`, one district PER OFFICE, each labelled for its seat
--     → Indiana Governor · Indiana Lieutenant Governor · Indiana Attorney General
--       Secretary of State · Treasurer · **Comptroller**
--     — exactly Indiana's SIX statewide ELECTED constitutional officers.
--
--   `geo_id = ''`, ONE shared district labelled just "Indiana"
--     → Commissioner of Labor · Director of Agriculture · Director of Natural Resources
--       Insurance Commissioner · Secretary of Education · Utility Regulatory Commissioner ×4
--       · Chairman
--     — ten APPOINTED agency heads and commissioners, none of whom stands for election.
--
-- So the canonical copy is the `geo_id = '18'` one on every reading available: it is the shape
-- the other five elected officers already use, its district is labelled "Indiana Comptroller"
-- rather than "Indiana", and it is the office the 2026-11-03 general election points at.
-- 🟢 The elected/appointed line is what the two shapes already encode. This migration does not
-- impose it — it moves the one row that was on the wrong side of it.
--
-- ⚠ The ten appointed offices are NOT touched. Whether a shared district is the right home for
-- them is a separate question with no defect behind it: none of them is duplicated, none carries
-- a race, and all ten are seated and reachable.
--
-- ─── THE RACE THIS PROTECTS ──────────────────────────────────────────────────────────────
-- `0f1bd30c-1cce-4a23-8ecd-a79c087171c6` — IN 2026 Statewide General, 2026-11-03, three active
-- candidates: Elise M. Nieshalla (the incumbent), John Schick, Jessica Bailey. It hangs off the
-- canonical copy. After this migration the incumbent is seated on the very office her own race
-- is for, which is what every other Indiana statewide officer already looks like.
--
-- ─── 🔴 ONE REPOINT THAT NO FOREIGN KEY WILL REMIND YOU ABOUT ────────────────────────────
-- `essentials.politicians.office_id` is the deprecated point-in-time snapshot (ADR 0002) and it
-- has NO foreign key to `essentials.offices`. Nieshalla's row points at the copy being deleted.
-- Delete the office without repointing it first and the column silently dangles — the same class
-- of silent drop CLAUDE.md records for `chambers.government_id`.
-- It is repointed rather than nulled: she does hold that seat, so the honest value is the
-- surviving office id, not a blank.
--
-- Every other reference was enumerated from `pg_constraint` and `information_schema.columns`,
-- not assumed: `office_terms` (1, moved), `races` (0 on the retired copy), `inform.stance_*`
-- (0, all three), and the four `essentials._retired_*` / `_fabricated_*` archive tables (0 —
-- and archives record what WAS, so they would be left alone even if they had rows).
--
-- ─── WHAT THIS CHANGES FOR A VOTER ───────────────────────────────────────────────────────
-- An Indiana address returns exactly one Comptroller row before and after. What changes is the
-- district the row carries: `geo_id` '' → '18', `district_label` "Indiana" → "Indiana
-- Comptroller". `government_body_name` is '' both before and after — the join key is the
-- chamber's `name_formal`, "Indiana State Auditor", and no `government_bodies` row carries that
-- key at either `geo_id`. (The chamber's formal name is stale: the office was renamed Comptroller
-- in 2023. Out of scope here, and recorded rather than quietly fixed.)
--
-- ─── OCCUPANCY ───────────────────────────────────────────────────────────────────────────
-- `5b86a68f…` is unflagged-and-unseated, so it sits INSIDE the 239 baseline. Seating it lowers
-- `offices_missing_terms` unflagged 239 → 238. The retired copy held a term and was never in the
-- view, so it leaves the other two numbers alone.
--
-- ⚠ **THE OTHER TWO NUMBERS HAD ALREADY MOVED UNDER ME.** `CC_0295` recorded 297/58/239 hours
-- before this file was written; measured again just now, prod reads **296/57/239** — another
-- session seated or removed one FLAGGED office in between. Nothing here caused it and nothing
-- here depends on it. So the gate below asserts the DELTA this migration creates, captured in
-- the same transaction, rather than a hard total measured at some earlier moment. Only the
-- unflagged baseline is asserted absolutely, because that is the number CLAUDE.md watches.
--
-- Author: Chris Cantrell. Slot reserved through the steward.

BEGIN;

-- Snapshot the three occupancy numbers BEFORE any write, so the gate can assert a delta rather
-- than a total somebody else's merge can move.
-- `did_run` makes the delta gate honest on a SECOND run: re-applied, this file writes nothing, so
-- the expected delta is 0/0/0 and not 1/0/1. Without it the idempotent path would fail its own gate.
CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT count(*)                                    AS total,
       count(*) FILTER (WHERE o.is_vacant)         AS flagged,
       count(*) FILTER (WHERE NOT o.is_vacant)     AS unflagged,
       EXISTS (SELECT 1 FROM essentials.offices
                WHERE id = '22565e22-45aa-4e33-bafc-2c8816f2a984') AS did_run
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

-- ─── PRE-FLIGHT ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_retire CONSTANT uuid := '22565e22-45aa-4e33-bafc-2c8816f2a984';
  v_keep   CONSTANT uuid := '5b86a68f-e42a-4b79-bbf9-a3cb6ce94896';
  v_n      int;
  v_txt    text;
BEGIN
  -- Idempotent: if the retired copy is already gone, the merge has run. Check the end state and stop.
  IF NOT EXISTS (SELECT 1 FROM essentials.offices WHERE id = v_retire) THEN
    IF NOT EXISTS (SELECT 1 FROM essentials.office_terms WHERE office_id = v_keep) THEN
      RAISE EXCEPTION 'CC_0296 pre-flight: the retired copy is gone but the canonical copy % has no term — the merge half-ran', v_keep;
    END IF;
    RAISE NOTICE 'CC_0296: already applied — nothing to do.';
    RETURN;
  END IF;

  -- Both copies must still be the two rows this migration was measured against.
  SELECT string_agg(o.title || ' @ ' || d.geo_id || ' /' || d.label || '/ ch=' || o.chamber_id::text, ' ;; ' ORDER BY d.geo_id)
    INTO v_txt
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.id IN (v_retire, v_keep);
  IF v_txt IS DISTINCT FROM
       'Comptroller @  /Indiana/ ch=c5f568d4-f295-46c4-ad91-dcbba493eab2 ;; '
    || 'Comptroller @ 18 /Indiana Comptroller/ ch=c5f568d4-f295-46c4-ad91-dcbba493eab2' THEN
    RAISE EXCEPTION 'CC_0296 pre-flight: the two Comptroller rows are not the shape measured. Got: %', v_txt;
  END IF;

  -- The term is on the copy being retired, and there is exactly one of it.
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE office_id = v_retire;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0296 pre-flight: expected exactly 1 term on the retired copy, found %', v_n;
  END IF;
  -- And the canonical copy has none, so the move cannot collide with the exclusion constraint.
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE office_id = v_keep;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0296 pre-flight: the canonical copy already carries % term(s) — this is no longer a clean merge', v_n;
  END IF;

  -- The race is on the canonical copy, and there is exactly one of it. The retired copy has none.
  SELECT count(*) INTO v_n FROM essentials.races WHERE office_id = v_keep;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0296 pre-flight: expected exactly 1 race on the canonical copy, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.races WHERE office_id = v_retire;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0296 pre-flight: the retired copy carries % race(s) — deleting it would orphan an election', v_n;
  END IF;

  -- 🔴 Nothing in the stance tables may point at the row about to be deleted. Two of those FKs
  -- are ON DELETE SET NULL, so a hit would be lost silently rather than refused.
  SELECT (SELECT count(*) FROM inform.stance_coder_labels    WHERE office_id = v_retire)
       + (SELECT count(*) FROM inform.stance_gold_labels     WHERE office_id = v_retire)
       + (SELECT count(*) FROM inform.stance_research_review WHERE office_id = v_retire)
    INTO v_n;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0296 pre-flight: % stance row(s) reference the retired copy — repoint them first', v_n;
  END IF;

  -- The holder, and that she holds exactly this one seat.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = v_retire AND p.full_name = 'Elise M. Nieshalla'
     AND p.is_active AND p.is_incumbent;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0296 pre-flight: the retired copy is not held by an active, incumbent Elise M. Nieshalla';
  END IF;
END $$;

-- ─── THE MERGE ───────────────────────────────────────────────────────────────────────────

-- 1. Move the term onto the canonical copy. This is the whole merge; everything else is tidying.
UPDATE essentials.office_terms
   SET office_id = '5b86a68f-e42a-4b79-bbf9-a3cb6ce94896'
 WHERE office_id = '22565e22-45aa-4e33-bafc-2c8816f2a984';

-- 2. Repoint the deprecated snapshot column. NO FOREIGN KEY GUARDS THIS — see the header.
UPDATE essentials.politicians
   SET office_id = '5b86a68f-e42a-4b79-bbf9-a3cb6ce94896'
 WHERE office_id = '22565e22-45aa-4e33-bafc-2c8816f2a984';

-- 3. Retire the empty duplicate. Its term has already moved, so the ON DELETE CASCADE on
--    office_terms has nothing left to take with it.
DELETE FROM essentials.offices
 WHERE id = '22565e22-45aa-4e33-bafc-2c8816f2a984';

-- ─── POST-VERIFY ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_retire CONSTANT uuid := '22565e22-45aa-4e33-bafc-2c8816f2a984';
  v_keep   CONSTANT uuid := '5b86a68f-e42a-4b79-bbf9-a3cb6ce94896';
  v_n      int;
  v_txt    text;
  b        record;
  a_total  int; a_flagged int; a_unflagged int;
BEGIN
  -- The retired copy is gone and exactly one Indiana Comptroller office remains.
  IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = v_retire) THEN
    RAISE EXCEPTION 'CC_0296: the duplicate office still exists';
  END IF;
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND d.district_type = 'STATE_EXEC' AND o.title = 'Comptroller';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0296: expected exactly 1 Indiana Comptroller office, found %', v_n;
  END IF;

  -- 🔴 Nothing anywhere still points at the deleted id. Enumerated from the catalogue, including
  -- the two columns that carry no foreign key and the four archive tables.
  SELECT (SELECT count(*) FROM essentials.office_terms              WHERE office_id = v_retire)
       + (SELECT count(*) FROM essentials.races                     WHERE office_id = v_retire)
       + (SELECT count(*) FROM essentials.politicians               WHERE office_id = v_retire)
       + (SELECT count(*) FROM inform.stance_coder_labels           WHERE office_id = v_retire)
       + (SELECT count(*) FROM inform.stance_gold_labels            WHERE office_id = v_retire)
       + (SELECT count(*) FROM inform.stance_research_review        WHERE office_id = v_retire)
       + (SELECT count(*) FROM essentials._fabricated_ca0156_removed   WHERE office_id = v_retire)
       + (SELECT count(*) FROM essentials._retired_1589_races          WHERE office_id = v_retire)
       + (SELECT count(*) FROM essentials._retired_ca0206_office_terms WHERE office_id = v_retire)
       + (SELECT count(*) FROM essentials._retired_ca0286_office_terms WHERE office_id = v_retire)
    INTO v_n;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0296: % reference(s) still point at the deleted office', v_n;
  END IF;

  -- The term survived the move UNCHANGED, not re-created. Same row id, same person, same
  -- undated open-ended span, same precision, same phase-2 provenance.
  SELECT t.id::text || ' | ' || p.full_name
       || ' | start=' || coalesce(t.term_start::text, 'NULL')
       || ' | end='   || coalesce(t.term_end::text, 'NULL')
       || ' | prec='  || coalesce(t.start_precision, 'NULL')
       || ' | how='   || coalesce(t.how_started, 'NULL')
       || ' | src='   || coalesce(t.source, 'NULL')
    INTO v_txt
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = v_keep;
  IF v_txt IS DISTINCT FROM
       'b72f59a3-f2b2-4c90-81aa-6b14a762bfd9 | Elise M. Nieshalla | start=NULL | end=NULL '
    || '| prec=unknown | how=NULL | src=backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)' THEN
    RAISE EXCEPTION 'CC_0296: the moved term is not the row that was measured. Got: %', v_txt;
  END IF;

  -- The holder is seated on exactly one seat, still active and still flagged incumbent, and the
  -- snapshot column points at the surviving office rather than at nothing.
  SELECT count(*) INTO v_n
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name = 'Elise M. Nieshalla' AND p.is_active AND p.is_incumbent;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0296: expected Nieshalla to hold exactly 1 seat, found %', v_n;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians
                  WHERE full_name = 'Elise M. Nieshalla' AND office_id = v_keep) THEN
    RAISE EXCEPTION 'CC_0296: the deprecated politicians.office_id snapshot was not repointed';
  END IF;

  -- The race is untouched and now sits on the office its own incumbent holds.
  SELECT count(*) INTO v_n FROM essentials.races WHERE office_id = v_keep;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0296: expected 1 race on the canonical copy, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.office_id = v_keep;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0296: expected 3 candidates on the Comptroller race, found %', v_n;
  END IF;

  -- The appointed-officials district kept every one of its other offices. It is NOT deleted —
  -- essentials.districts has no inbound FKs, so a delete here would silently orphan ten offices.
  SELECT count(*) INTO v_n FROM essentials.offices WHERE district_id = '97db28b9-6b56-4427-a6e3-82645d0d6ad5';
  IF v_n <> 10 THEN
    RAISE EXCEPTION 'CC_0296: the shared geo_id='''' district should hold 10 offices after this, found %', v_n;
  END IF;
  SELECT string_agg(DISTINCT o.title, ', ' ORDER BY o.title) INTO v_txt
    FROM essentials.offices o WHERE o.district_id = '97db28b9-6b56-4427-a6e3-82645d0d6ad5';
  IF v_txt IS DISTINCT FROM 'Chairman, Commissioner of Labor, Director of Agriculture, '
                         || 'Director of Natural Resources, Insurance Commissioner, '
                         || 'Secretary of Education, Utility Regulatory Commissioner' THEN
    RAISE EXCEPTION 'CC_0296: the appointed bucket is not the ten offices measured. Got: %', v_txt;
  END IF;
  -- And none of the ten carries a race — the elected/appointed line the two shapes encode.
  SELECT count(*) INTO v_n
    FROM essentials.races r JOIN essentials.offices o ON o.id = r.office_id
   WHERE o.district_id = '97db28b9-6b56-4427-a6e3-82645d0d6ad5';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0296: % race(s) now hang off the appointed-officials district', v_n;
  END IF;

  -- All six Indiana statewide ELECTED officers now sit on per-office geo_id='18' districts and
  -- all six are seated. This is the shape claim, asserted rather than described.
  SELECT string_agg(o.title, ', ' ORDER BY o.title) INTO v_txt
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND d.district_type = 'STATE_EXEC' AND d.geo_id = '18';
  IF v_txt IS DISTINCT FROM 'Comptroller, Indiana Attorney General, Indiana Governor, '
                         || 'Indiana Lieutenant Governor, Secretary of State, Treasurer' THEN
    RAISE EXCEPTION 'CC_0296: the geo_id=18 elected set is not the six measured. Got: %', v_txt;
  END IF;
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND d.district_type = 'STATE_EXEC' AND d.geo_id = '18'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = o.id AND och.politician_id IS NOT NULL);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0296: % of the six elected Indiana statewide offices are unseated', v_n;
  END IF;

  -- 🟢 THE GATE THAT FOUND THIS SEAT IN THE FIRST PLACE, now with the Comptroller gone from it.
  SELECT string_agg(x.title || ' x' || x.n, ', ' ORDER BY x.title) INTO v_txt
    FROM (SELECT o.title, count(*) AS n
            FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
           WHERE lower(d.state) = 'in' AND d.district_type = 'STATE_EXEC'
           GROUP BY o.title HAVING count(*) > 1) x;
  IF v_txt IS DISTINCT FROM 'Utility Regulatory Commissioner x4' THEN
    RAISE EXCEPTION 'CC_0296: duplicated Indiana STATE_EXEC titles are [%], expected only the four genuine Utility Regulatory Commissioners', v_txt;
  END IF;

  -- Repo-wide: nobody holds the same office title twice. CC_0295 asserted this and it must hold.
  SELECT count(*) INTO v_n FROM (
    SELECT och.politician_id
      FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
     WHERE och.politician_id IS NOT NULL
     GROUP BY och.politician_id, o.title HAVING count(*) > 1) y;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0296: % person/title pair(s) are seated twice repo-wide', v_n;
  END IF;

  -- ─── OCCUPANCY: the DELTA, not a total somebody else can move ──────────────────────────
  SELECT * INTO b FROM _before;
  SELECT count(*),
         count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE NOT o.is_vacant)
    INTO a_total, a_flagged, a_unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;

  IF (b.total - a_total, b.flagged - a_flagged, b.unflagged - a_unflagged)
       IS DISTINCT FROM (CASE WHEN b.did_run THEN 1 ELSE 0 END, 0, CASE WHEN b.did_run THEN 1 ELSE 0 END) THEN
    RAISE EXCEPTION 'CC_0296: offices_missing_terms moved %/%/% -> %/%/% (first run: %), expected -1 total, -0 flagged, -1 unflagged on a first run and no movement on a re-run',
      b.total, b.flagged, b.unflagged, a_total, a_flagged, a_unflagged, b.did_run;
  END IF;
  -- The unflagged baseline is the one number CLAUDE.md watches, so it is asserted absolutely.
  IF a_unflagged <> 238 THEN
    RAISE EXCEPTION 'CC_0296: unflagged baseline is % after this migration, expected 238', a_unflagged;
  END IF;

  RAISE NOTICE 'CC_0296 OK — Comptroller merged onto %; offices_missing_terms %/%/% -> %/%/%',
    v_keep, b.total, b.flagged, b.unflagged, a_total, a_flagged, a_unflagged;
END $$;

COMMIT;
