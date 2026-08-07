-- 1586_dedupe_race_candidates_and_unique_index.sql
--
-- Merge 26 groups of duplicate race_candidates rows (60 rows in, 26 out, 34 deleted), then make the
-- defect structurally impossible with a unique index.
--
--   Rollback: the deleted rows are listed with full values in the audit table created below,
--             essentials._dedupe_1586_removed. DROP INDEX race_candidates_race_name_key_uniq to undo
--             the safeguard.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1586_dedupe_race_candidates_and_unique_index.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- ROOT CAUSE — A REGEX THAT DISAGREED WITH ITS OWN TWIN
-- ---------------------------------------------------------------------------------------------------
-- `autoUpsertToRaceCandidates` in backend/src/lib/discoveryService.ts does a SELECT-then-INSERT and
-- normalises the candidate name on BOTH sides. The two sides do not agree:
--
--   incoming (TypeScript, stripMiddleInitials) .... .replace(/\./g, '')  → "clayton saunders"
--   stored   (SQL, regexp_replace)  '\m[A-Za-z]\.?\M\s*'                 → "clayton . saunders"
--
-- In Postgres ARE, `\M` asserts END OF WORD. For the token "M." the engine cannot consume the period
-- and still sit at a word end, so it backtracks and matches the bare letter — deleting "M" and
-- leaving ". " behind. The stored side therefore keeps a stray period the incoming side always
-- strips, the equality test can never be true, and the row is re-inserted.
--
-- 🔑 THE FAILURE IS PERFECTLY SELECTIVE, WHICH IS WHY IT WENT UNNOTICED. It fires if and only if the
-- name contains a middle initial. In the Beverly Hills council race, every duplicated candidate has
-- one (Clayton M. Saunders, John A. Mirisch, Sharona R. Nazarian, Lester J. Friedman) and every
-- clean candidate does not (Andrew Kole, Andy Licht, Ariel Rofeim, Barry Axelrod, Rebecca Pynoos,
-- Roger Tanenbaum, Russell Stuart, Jonathan Mariande). A weekly cron then re-inserted each affected
-- candidate once per run: Saunders appears on 2026-04-26 (clerk) and again on 05-17, 05-24, 05-31.
--
-- Two smaller variants ride along on the same root cause — the normalisation was never a
-- single definition, so every caller invented its own:
--   * credentials — "Sharona R. Nazarian" vs "Sharona R. Nazarian, PsyD"
--   * quoted nicknames — 'Thomas "TJ" Nass' vs 'Thomas Nass'
--
-- ---------------------------------------------------------------------------------------------------
-- THE SAFEGUARD: STOP RELYING ON CALLERS TO CHECK
-- ---------------------------------------------------------------------------------------------------
-- The code comment on autoUpsertToRaceCandidates says it uses SELECT-then-INSERT "because
-- race_candidates has no unique index on (race_id, full_name)". That is the actual bug — not the
-- regex, which is only how it manifested this time. A uniqueness rule enforced by a SELECT is a
-- uniqueness rule that every future caller must remember, implement identically, and win a race
-- condition to honour.
--
-- This migration moves the rule into the database:
--   1. `essentials.candidate_name_key(text)` — ONE canonical normalisation (migration 1586a/1586b).
--   2. A UNIQUE INDEX on (race_id, candidate_name_key(full_name)).
--
-- After this, a duplicate insert fails loudly instead of succeeding silently, and the discovery
-- service can drop its hand-rolled check for a plain ON CONFLICT DO NOTHING.
-- ---------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------
-- STEP 1 — audit table: every row this migration deletes, preserved in full
-- ---------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS essentials._dedupe_1586_removed AS
  SELECT rc.*, NULL::uuid AS merged_into, now() AS removed_at
  FROM essentials.race_candidates rc WHERE false;

-- ---------------------------------------------------------------------------------------------------
-- STEP 2 — pick one survivor per duplicate group
-- ---------------------------------------------------------------------------------------------------
-- Preference order, most decisive first:
--   1. has a politician_id — the row wired to a real person record
--   2. has a recorded result — never orphan an outcome recorded in 1583/1584 (currently none, but
--      the rule must hold if this migration is ever re-run)
--   3. NOT sourced from discovery_cron — prefer the clerk/official/SoS row over the cron's copy
--   4. earliest created_at — the original rather than a later re-insert
CREATE TEMP TABLE dedupe_plan AS
WITH ranked AS (
  SELECT rc.id, rc.race_id,
         essentials.candidate_name_key(rc.full_name) AS k,
         COUNT(*)      OVER (PARTITION BY rc.race_id, essentials.candidate_name_key(rc.full_name)) AS grp_size,
         ROW_NUMBER()  OVER (PARTITION BY rc.race_id, essentials.candidate_name_key(rc.full_name)
                             ORDER BY (rc.politician_id IS NOT NULL) DESC,
                                      (rc.result IS NOT NULL)        DESC,
                                      (rc.source IS DISTINCT FROM 'discovery_cron') DESC,
                                      rc.created_at ASC,
                                      rc.id ASC) AS rn
  FROM essentials.race_candidates rc
)
SELECT r.id, r.race_id, r.k, r.rn,
       FIRST_VALUE(r.id) OVER (PARTITION BY r.race_id, r.k ORDER BY r.rn) AS survivor_id
FROM ranked r
WHERE r.grp_size > 1;

-- ---------------------------------------------------------------------------------------------------
-- STEP 3 — carry forward anything the losers know that the survivor does not
-- ---------------------------------------------------------------------------------------------------
-- Attributes are merged, not discarded. is_incumbent especially: the Beverly Hills clerk row carries
-- is_incumbent=true for Friedman and Nazarian while the cron's copies carry false, and an incumbency
-- flag silently flipping to false is exactly the two-gate occupancy bug found in migration 1580.
UPDATE essentials.race_candidates s
   SET is_incumbent     = COALESCE(s.is_incumbent, false) OR agg.any_incumbent,
       politician_id    = COALESCE(s.politician_id, agg.any_politician),
       photo_url        = COALESCE(s.photo_url, agg.any_photo),
       website_url      = COALESCE(s.website_url, agg.any_website),
       last_verified_at = GREATEST(s.last_verified_at, agg.max_verified)
  FROM (
    SELECT p.survivor_id,
           bool_or(COALESCE(rc.is_incumbent,false)) AS any_incumbent,
           max(rc.politician_id::text)::uuid        AS any_politician,
           max(rc.photo_url)                        AS any_photo,
           max(rc.website_url)                      AS any_website,
           max(rc.last_verified_at)                 AS max_verified
    FROM dedupe_plan p
    JOIN essentials.race_candidates rc ON rc.id = p.id
    GROUP BY p.survivor_id
  ) agg
 WHERE s.id = agg.survivor_id;

-- ---------------------------------------------------------------------------------------------------
-- STEP 4 — repoint the only foreign key, then archive and delete the losers
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.candidate_staging cs
   SET matched_candidate_id = p.survivor_id
  FROM dedupe_plan p
 WHERE cs.matched_candidate_id = p.id AND p.rn > 1;

INSERT INTO essentials._dedupe_1586_removed
  SELECT rc.*, p.survivor_id, now()
  FROM dedupe_plan p JOIN essentials.race_candidates rc ON rc.id = p.id
 WHERE p.rn > 1;

DELETE FROM essentials.race_candidates rc
 USING dedupe_plan p
 WHERE rc.id = p.id AND p.rn > 1;

-- ---------------------------------------------------------------------------------------------------
-- STEP 5 — the safeguard
-- ---------------------------------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS race_candidates_race_name_key_uniq
  ON essentials.race_candidates (race_id, essentials.candidate_name_key(full_name));

COMMENT ON INDEX essentials.race_candidates_race_name_key_uniq IS
  'One candidacy per person per race. Added by migration 1586 after a weekly discovery cron inserted 34 duplicate rows over three months. Callers must use ON CONFLICT DO NOTHING rather than a hand-rolled SELECT-then-INSERT — the previous hand-rolled check normalised names differently in TypeScript and SQL and never matched a name containing a middle initial.';
