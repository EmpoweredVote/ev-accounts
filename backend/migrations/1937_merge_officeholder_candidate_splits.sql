-- Migration 1937 — merge SIX officeholder/candidate person splits.
--
-- Found by `check:duplicate-people`, which reported 7 "split pairs needing a look": a SEATED row
-- holding the office and a second active row holding the 2026 candidacy, for one human. The split
-- means the officeholder profile does not show they are on the ballot, and the candidate profile
-- does not show their record. Both halves carry 0 compass answers, so neither page carries the
-- person's compass either.
--
-- ⚠ SIX, NOT SEVEN. The seventh pair is NOT a duplicate; see the Moore note at the bottom.
--
-- 💰 TWO OF THESE CARRY REAL MONEY, which is the sharp end of the split: $1,561,467.66 of FEC
-- receipts sits on a seatless row today.
--   Shevrin Jones   fec_house H6FL24087    407 contributions    $390,573.79
--   Carrie Buck     fec_house H6NV01331  7,680 contributions  $1,170,893.87
-- contributions and contribution_summary_agg key on politician_source_id, so re-pointing the
-- SOURCE's owner carries the money; no row in either table is touched here.
--
-- SURVIVOR IS THE SEATED ROW in all six. It holds office_terms, office_current_holder, and (for the
-- Indiana township seat) zip routing, contacts and addresses. The duplicate holds only candidacies
-- plus, in three cases, an image or an FEC source. Census of all 28 FK references to
-- essentials.politicians was taken before writing this; the columns below are the only non-zero ones.
--
-- | pair                 | survivor (seated)                     | duplicate (candidate)                 | moves        |
-- | FL Shevrin Jones     | cd892637 State Senator                | 05658b58 U.S. Rep. D24                | rc 1, src 1  |
-- | NV Carrie Buck       | a7679d83 State Senator                | 785ab5f3 U.S. Rep. D1                 | rc 1, src 1  |
-- | TN Monty Fritts      | 9cff8f78 State House D32              | a3be7449 Governor of Tennessee        | rc 1         |
-- | WI Robyn Vining      | 99443b59 Assembly D13                 | ba7f92e0 State Senate D5              | rc 2         |
-- | WI Jenna Jacobson    | 1fbf690b Assembly D50                 | cf0a621c State Senate D17             | rc 2         |
-- | IN Joe Husk          | 85194f5e Monroe Cty Benton Twp Board  | 04d2e529 Benton Township Board        | rc 2, img 1  |
--
-- HOW EACH IDENTITY WAS ESTABLISHED — not one of these rests on the name alone:
--   Jones, Buck    HEADSHOT PAIR, the decisive test. Both rows carry an image from different
--                  sources; fetched and compared, each pair is plainly the same person.
--   Vining,        STRUCTURAL. A Wisconsin Senate district nests exactly three Assembly districts:
--   Jacobson       SD5 = AD13/14/15 and SD17 = AD49/50/51. Each member is running for the Senate
--                  seat that CONTAINS her own Assembly seat. Names are byte-identical, same state.
--   Fritts         EXTERNAL. Rep. Monty Fritts of Kingston, TN House District 32, entered the 2026
--                  Republican gubernatorial primary (announced Sept 5, filed January 9).
--                  tennesseelookout.com/2025/09/08/, ballotpedia.org/Monty_Fritts.
--   Husk           IDENTICAL geo_id. The seat and the race are both district 1810504816, Benton
--                  Township in Monroe County -- a re-election, not a move. Indiana has many Benton
--                  Townships, so the geo_id and not the label is what settles it.
--                  preferred_name on the survivor is "Joe", the duplicate's whole full_name.
--
-- 🔴 THE SEVENTH PAIR IS TWO DIFFERENT PEOPLE AND IS DELIBERATELY NOT MERGED.
--   0a377424 "Michael R Moore"  -- BROWN COUNTY CORONER
--   c554cb1f "Mike Moore"       -- candidate, Indiana House District 60
-- The HD60 candidate is a first-time candidate from MARTINSVILLE (Morgan County), age 53, a police
-- officer at Indianapolis International Airport since 1998 (dailyjournal.net 2026-04-07 and
-- 2026-04-10, ballotpedia Indiana_House_of_Representatives_District_60). The coroner is in Brown
-- County. Different county, different occupation. `preferred_name = 'Mike'` on the coroner row is
-- what made this pair LOOK like the others, and it is exactly the surname-plus-nickname shape that
-- has produced every mislink in this corpus. Recorded as different_people in
-- backend/data/duplicate-people-baseline.json instead.
--
-- DUPLICATES ARE RETIRED, NEVER DELETED (the person-merge recipe): their notes are the only
-- provenance of how the tangle arose, and a deleted row cannot be audited.
--
-- inform.politician_answers is PK (politician_id, topic_id) and a blind repoint would hard-fail on a
-- shared topic. Not reachable here -- all twelve rows carry 0 answers -- and guard 2 asserts it.
--
-- No migration runner exists; this file records SQL applied by hand via
-- mcp__supabase-local__execute_sql as `postgres`.

BEGIN;

CREATE TEMP TABLE mig1937_merges (
  survivor uuid NOT NULL,
  dup      uuid NOT NULL,
  label    text NOT NULL
) ON COMMIT DROP;

INSERT INTO mig1937_merges (survivor, dup, label) VALUES
  ('cd892637-c28b-472a-878e-f2fdf1b98935','05658b58-f1dd-4d4d-a298-6972cc36d22f','FL Shevrin Jones'),
  ('a7679d83-5a48-470e-9df2-4d1d7c18a391','785ab5f3-7756-4210-9f4b-bcbb09147241','NV Carrie Buck'),
  ('9cff8f78-ffde-4821-91e7-6d14fb093ecc','a3be7449-ec25-4511-bf3d-889a340fbb3f','TN Monty Fritts'),
  ('99443b59-c422-43c4-98ba-070cc2c97491','ba7f92e0-6dfb-4832-a4ed-a4ff4a181546','WI Robyn Vining'),
  ('1fbf690b-01c5-4d20-a938-de0c56f2e4a8','cf0a621c-b5a9-4923-9942-a8d6b6d50966','WI Jenna Jacobson'),
  ('85194f5e-6574-4371-97da-f1cc89568870','04d2e529-5456-44bb-a20f-b1ec676c2c22','IN Joe Husk');

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM mig1937_merges;
  IF n <> 6 THEN RAISE EXCEPTION 'migration 1937 pre-check: merge set is %, expected 6', n; END IF;

  -- GUARD 1 — all twelve rows exist and are active. A retired row here would mean someone already
  -- worked this queue and the sets must be re-derived, not re-applied.
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.is_active
     AND (p.id IN (SELECT survivor FROM mig1937_merges) OR p.id IN (SELECT dup FROM mig1937_merges));
  IF n <> 12 THEN RAISE EXCEPTION 'migration 1937 pre-check: expected 12 active rows, found %', n; END IF;

  -- GUARD 2 — no compass answers anywhere, so the (politician_id, topic_id) PK cannot collide.
  SELECT count(*) INTO n FROM inform.politician_answers pa
   WHERE pa.politician_id IN (SELECT survivor FROM mig1937_merges)
      OR pa.politician_id IN (SELECT dup FROM mig1937_merges);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1937 pre-check: % answer(s) appeared; the PK can now collide, stop', n; END IF;

  -- GUARD 3 — every survivor is seated and holds no candidacy; every duplicate is the mirror image.
  SELECT count(*) INTO n FROM mig1937_merges m
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = m.survivor)
      OR EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.politician_id = m.survivor)
      OR EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = m.dup);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1937 pre-check: % pair(s) are not the expected seated/candidate shape', n; END IF;

  -- GUARD 4 — the candidacies we are about to move.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.politician_id IN (SELECT dup FROM mig1937_merges);
  IF n <> 9 THEN RAISE EXCEPTION 'migration 1937 pre-check: expected 9 candidacies to move, found %', n; END IF;

  -- GUARD 5 — the money, named exactly. If this has moved, the premise has changed.
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g
    JOIN transparent_motivations.politician_sources ps ON ps.id = g.politician_source_id
   WHERE ps.essentials_politician_id IN (SELECT dup FROM mig1937_merges);
  IF d <> 1561467.66 THEN RAISE EXCEPTION 'migration 1937 pre-check: duplicate-side money is %, expected 1561467.66', d; END IF;

  -- GUARD 6 — the Moore pair must NOT be in this migration.
  SELECT count(*) INTO n FROM mig1937_merges
   WHERE survivor IN ('0a377424-7b2a-4e2a-b28f-b872373ce5ec','c554cb1f-cfd4-40b0-b430-9535b31e347d')
      OR dup      IN ('0a377424-7b2a-4e2a-b28f-b872373ce5ec','c554cb1f-cfd4-40b0-b430-9535b31e347d');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1937: the Moore pair is two different people and must not be merged'; END IF;
END $$;

-- 1. The candidacies. This is the join that was missing: the officeholder now shows as on the ballot.
UPDATE essentials.race_candidates rc
   SET politician_id = m.survivor
  FROM mig1937_merges m
 WHERE rc.politician_id = m.dup;

-- 2. The money. Jones and Buck only; re-pointing the source carries its contributions and agg rows.
UPDATE transparent_motivations.politician_sources ps
   SET essentials_politician_id = m.survivor,
       notes = coalesce(ps.notes,'') || ' | MERGED (migration 1937, 2026-10-22): moved from duplicate'
             || ' person row ' || m.dup::text || ', which held the candidacy while the seated row held'
             || ' the office. Same person; see the migration header for how identity was established.',
       updated_at = now()
  FROM mig1937_merges m
 WHERE ps.essentials_politician_id = m.dup;

-- 3. The one image whose survivor has none (IN Husk). Where the survivor already has an image the
--    duplicate's is left on the retired row rather than creating a second 'default'.
UPDATE essentials.politician_images pi
   SET politician_id = m.survivor
  FROM mig1937_merges m
 WHERE pi.politician_id = m.dup
   AND NOT EXISTS (SELECT 1 FROM essentials.politician_images s WHERE s.politician_id = m.survivor);

-- 4. Retire the duplicates. Never DELETE -- the notes are the provenance.
UPDATE essentials.politicians p
   SET is_active = false,
       is_incumbent = false,
       notes = coalesce(p.notes, '{}'::text[]) || ARRAY[
         'RETIRED by migration 1937 (2026-10-22): duplicate person row. This row held the 2026'
         || ' candidacy while ' || m.survivor::text || ' held the office; they are one person.'
         || ' Candidacies, and any FEC source and image, were moved to that row.']
  FROM mig1937_merges m
 WHERE p.id = m.dup;

DO $$
DECLARE n int; d numeric;
BEGIN
  -- Nothing is left on a duplicate.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.politician_id IN (SELECT dup FROM mig1937_merges);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1937 post-check: % candidacy(ies) still on a duplicate', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT dup FROM mig1937_merges);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1937 post-check: % source(s) still on a duplicate', n; END IF;

  -- The survivors hold them now.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.politician_id IN (SELECT survivor FROM mig1937_merges);
  IF n <> 9 THEN RAISE EXCEPTION 'migration 1937 post-check: survivors hold % candidacies, expected 9', n; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g
    JOIN transparent_motivations.politician_sources ps ON ps.id = g.politician_source_id
   WHERE ps.essentials_politician_id IN (SELECT survivor FROM mig1937_merges);
  IF d <> 1561467.66 THEN RAISE EXCEPTION 'migration 1937 post-check: survivors display %, expected 1561467.66', d; END IF;

  -- Every survivor now has a face. Five already had one; Husk's came from his duplicate.
  SELECT count(*) INTO n FROM mig1937_merges m
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = m.survivor);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1937 post-check: % survivor(s) have no image', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id IN (SELECT dup FROM mig1937_merges) AND p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1937 post-check: % duplicate(s) still active', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id IN (SELECT survivor FROM mig1937_merges) AND NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1937 post-check: % survivor(s) were retired by mistake', n; END IF;

  -- The Moore pair is untouched and still active on both sides.
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id IN ('0a377424-7b2a-4e2a-b28f-b872373ce5ec','c554cb1f-cfd4-40b0-b430-9535b31e347d')
     AND p.is_active;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1937 post-check: the Moore pair should be untouched, % active', n; END IF;
END $$;

COMMIT;
