-- CC_0193 — record Jennifer Hernandez's ballot name in politicians.alternate_names
--
-- WHY. The stance source verifier accepts a snippet only when the person is named within 500
-- characters of the span (checkNameProximity, src/lib/researchVerifier.ts). It tests the record's
-- full_name, then the surname — and a surname on COMMON_LAST_NAMES needs a title such as
-- Councilmember within 30 characters. "hernandez" is on that list.
--
-- Measured 2026-10-06 on the Duvall WA batch: every published source writes her ballot name,
-- "Jenn Hernandez", and never "Jennifer Hernandez" — the Snoqualmie Valley Record candidate
-- questionnaire, the King County voters' pamphlet, and the election results. All three occurrences
-- in the questionnaire are untitled, because she was a candidate at the time. So her answer on
-- residential-zoning, which names a chair, could not be cited at all.
--
-- The record itself is correct and was checked against the city's own publications, not the paper:
-- duvallwa.gov's council roster gives "Jennifer Hernandez, Position 7, Term Expires December 2027",
-- and her directory page (Directory.aspx?EID=173) states she "was appointed to Position #7 on the
-- Duvall City Council in January 2026". full_name is NOT changed here; the ballot name is recorded
-- beside it, which is what alternate_names is for.
--
-- The verifier reads this column as of the companion change to researchVerifier.ts (aliasesFrom):
-- a multi-token alternate name is accepted as a full name. One-token names are dropped there, so
-- never add a bare first name to this column expecting it to match.
--
-- Idempotent: re-running adds nothing. Post-verify gate raises if the row did not end up correct.

BEGIN;

UPDATE essentials.politicians
   SET alternate_names = array_append(coalesce(alternate_names, '{}'::text[]), 'Jenn Hernandez'),
       last_update_date = now()
 WHERE id = '628c3b92-99eb-44e3-9f9d-fec8dcff8bd2'
   AND full_name = 'Jennifer Hernandez'
   AND NOT ('Jenn Hernandez' = ANY(coalesce(alternate_names, '{}'::text[])));

DO $$
DECLARE
  v_full  text;
  v_alts  text[];
BEGIN
  SELECT full_name, coalesce(alternate_names, '{}'::text[])
    INTO v_full, v_alts
    FROM essentials.politicians
   WHERE id = '628c3b92-99eb-44e3-9f9d-fec8dcff8bd2';

  IF v_full IS NULL THEN
    RAISE EXCEPTION 'CC_0193: politician 628c3b92-99eb-44e3-9f9d-fec8dcff8bd2 not found';
  END IF;

  -- full_name must be untouched: the legal name is the record, the ballot name is the alias.
  IF v_full <> 'Jennifer Hernandez' THEN
    RAISE EXCEPTION 'CC_0193: full_name is %, expected Jennifer Hernandez — refusing', v_full;
  END IF;

  IF NOT ('Jenn Hernandez' = ANY(v_alts)) THEN
    RAISE EXCEPTION 'CC_0193: alternate_names does not carry Jenn Hernandez (got %)', v_alts;
  END IF;

  -- Exactly once, however many times this migration is applied.
  IF (SELECT count(*) FROM unnest(v_alts) a WHERE a = 'Jenn Hernandez') <> 1 THEN
    RAISE EXCEPTION 'CC_0193: Jenn Hernandez appears % times in alternate_names, expected 1',
      (SELECT count(*) FROM unnest(v_alts) a WHERE a = 'Jenn Hernandez');
  END IF;
END $$;

COMMIT;
