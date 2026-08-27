BEGIN;

-- =============================================================================
-- CC_wip: A CLOSED SEASON IS IMMUTABLE. Enforced by the database.
-- =============================================================================
-- 🔴🔴 NOT APPLIED. Written 2026-08-27. THIS IS THE LAST STEP of the
-- compass-seasons sequence and it MUST NOT be applied before a season is open —
-- see "WHY THE ORDER MATTERS" below, it would stop all editing.
--
-- WHY THIS EXISTS. Chris's concern, in his words: "We should be holding on to
-- season 1 and season 2 answers so that this type of destructive pattern isn't
-- possible." Scoping each DELETE to the open season — which is what the code
-- does today — is necessary and NOT sufficient: it relies on every consumer
-- remembering. There are five SECURITY DEFINER functions, eleven repo sites,
-- and any human with a connection string. That is a convention, not a guarantee.
--
-- This makes it a guarantee. A row whose season is 'closed' cannot be UPDATEd or
-- DELETEd, by anything, for any reason.
--
-- ✅ PROVEN AGAINST REAL DATA 2026-08-27, in a rolled-back transaction, on the
-- live 33,164-row corpus (season 1 is closed, so every row was in scope):
--   1 DELETE a closed-season answer            -> REFUSED, CLOSED_SEASON_IS_IMMUTABLE
--   2 UPDATE a closed-season answer            -> REFUSED
--   3 the empty-payload wipe of one politician -> REFUSED
--   4 ad-hoc mass `DELETE ... WHERE value = 3` -> REFUSED
--   5 answers still present afterwards         -> 33,164
-- Case 4 is the one that matters: no application-level fix covers a human at a
-- psql prompt. That is the difference between a convention and a guarantee.
--
-- 🔴 WHY THE ORDER MATTERS — DO NOT APPLY THIS EARLY. Season 1 is closed and
-- holds ALL 33,164 answers. Turn this on before another season is open and every
-- edit path stops, because there is nowhere writable left. The sequence is:
--   (a) drop the *_legacy_pair_scaffold indexes from CC_0002
--   (b) open season 2  (editorial: a name, a question set, a voter-facing note)
--   (c) THEN apply this
--
-- ⚠ ONE CONSEQUENCE TO ACCEPT DELIBERATELY, NOT DISCOVER. This blocks correcting
-- a dead or fabricated source URL inside season 1, because
-- sourceVerificationService patches the newest season holding that URL — which
-- is season 1 today. Sealing the record seals its citations too. If those must
-- stay correctable, this trigger needs a narrow carve-out allowing `sources` to
-- change while `value` and `reasoning` cannot. That is an editorial call and it
-- is deliberately NOT made here. It is the same open question flagged in
-- src/lib/sourceVerificationService.ts.
--
-- ALSO RECOMMENDED, INDEPENDENT OF THIS TRIGGER: a tripwire asserting season 1
-- never falls below 33,164 answers / 33,818 context rows. A trigger can be
-- dropped; a CI check notices that it was. Baselined per season, same shape as
-- check-stance-sources.
-- =============================================================================

CREATE OR REPLACE FUNCTION inform.refuse_closed_season_write()
RETURNS trigger LANGUAGE plpgsql AS $fn$
DECLARE v_status text;
BEGIN
  SELECT s.status::text INTO v_status FROM inform.seasons s WHERE s.id = OLD.season_id;
  IF v_status = 'closed' THEN
    RAISE EXCEPTION 'CLOSED_SEASON_IS_IMMUTABLE: % on a row in a closed season is refused', TG_OP
      USING HINT = 'Write to the open season instead. A closed season is a record, not a workspace.';
  END IF;
  RETURN CASE TG_OP WHEN 'DELETE' THEN OLD ELSE NEW END;
END $fn$;

DROP TRIGGER IF EXISTS answers_closed_season_immutable ON inform.politician_answers;
CREATE TRIGGER answers_closed_season_immutable
  BEFORE UPDATE OR DELETE ON inform.politician_answers
  FOR EACH ROW EXECUTE FUNCTION inform.refuse_closed_season_write();

DROP TRIGGER IF EXISTS context_closed_season_immutable ON inform.politician_context;
CREATE TRIGGER context_closed_season_immutable
  BEFORE UPDATE OR DELETE ON inform.politician_context
  FOR EACH ROW EXECUTE FUNCTION inform.refuse_closed_season_write();

DO $$
DECLARE v_open int;
BEGIN
  -- 🔴 THE GUARD THAT MAKES THIS SAFE TO RUN. Refuse to seal the corpus while
  -- there is nowhere else to write. Without this, applying in the wrong order
  -- silently stops all compass editing and the cause is not obvious.
  SELECT count(*) INTO v_open FROM inform.seasons WHERE status = 'open';
  IF v_open <> 1 THEN
    RAISE EXCEPTION
      'NO_OPEN_SEASON: % open season(s). Applying this now would make every '
      'answer read-only, because season 1 is closed and holds the whole corpus. '
      'Drop the *_legacy_pair_scaffold indexes and open season 2 first.', v_open;
  END IF;

  IF (SELECT count(*) FROM pg_trigger
       WHERE tgname IN ('answers_closed_season_immutable','context_closed_season_immutable')
         AND NOT tgisinternal) <> 2 THEN
    RAISE EXCEPTION 'both immutability triggers should be present';
  END IF;

  RAISE NOTICE 'closed seasons are now immutable — enforced for every writer, including psql';
END $$;

COMMIT;
