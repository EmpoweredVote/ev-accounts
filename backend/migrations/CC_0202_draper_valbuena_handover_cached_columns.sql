-- CC_0202 — 🔴🔴 DO NOT APPLY BEFORE 2027-01-05. It refuses to run early; that is deliberate.
--
-- The second half of the Draper → Valbuena handover: the two columns that cache "current" and do
-- not move when the calendar does.
--
-- CC_0201 (applied 2026-10-08) wrote the handover as dated office_terms rows. Those are
-- self-executing: essentials.current_office_holders filters on CURRENT_DATE, so on 2027-01-05 the
-- view stops returning Draper and starts returning Valbuena with no deploy, no job and no trigger.
--
-- These two do not:
--
--     politicians.is_incumbent   a cached flag the incumbents-only reads filter on. It is only
--                                READ in the codebase — four `p.is_incumbent = true` filters in
--                                essentialsBrowseService.ts — and NOTHING recomputes it. Left
--                                alone, Draper stays a "current incumbent" with no seat (the exact
--                                defect CA_0188 created 1,817 times) and Valbuena is HIDDEN from
--                                address search despite holding the seat.
--
--     politicians.office_id      the legacy point-in-time snapshot. Deprecated and not to be read
--                                in new code, but it still points at this office for Draper and is
--                                NULL for Valbuena, so it would assert the opposite of the truth.
--
-- This is why CLAUDE.md says never to cache "current" in a column. We have two, inherited, and this
-- file is the price.
--
-- 🔴 THE DATE GUARD IS THE POINT. Applying this before 2027-01-05 would make TODAY wrong — Draper
-- is the sitting judge until his term ends and must read as the incumbent until then. The gate
-- below refuses early, and also refuses if the dated rows CC_0201 wrote are not what it expects.
--
-- Rollback: swap the two is_incumbent values back and restore office_id (Draper
-- '83969e0c-c530-4649-bf82-68e25eca0c85', Valbuena NULL).

BEGIN;

DO $$
DECLARE
  v_office   uuid := '83969e0c-c530-4649-bf82-68e25eca0c85';
  v_draper   uuid := 'fa932212-a2cf-4fa1-97ab-c6619e3db610';
  v_valbuena uuid := '917d6200-f048-4b7b-85f7-3a390abeecf2';
  v_holder   uuid;
BEGIN
  -- 🔴 REFUSE EARLY. Not a warning: an exception, so a stray run cannot corrupt today.
  IF CURRENT_DATE < DATE '2027-01-05' THEN
    RAISE EXCEPTION 'CC_0202: today is %, and this migration must not be applied before 2027-01-05. '
                    'Draper holds the seat until his term ends on 2027-01-04; flipping these '
                    'columns now would make the live site wrong.', CURRENT_DATE;
  END IF;

  -- The dated rows must already say the handover happened. If CC_0201 was reverted or re-dated,
  -- stop: this migration only ever follows the terms, it never leads them.
  SELECT politician_id INTO v_holder
    FROM essentials.office_current_holder WHERE office_id = v_office;
  IF v_holder IS DISTINCT FROM v_valbuena THEN
    RAISE EXCEPTION 'CC_0202: office % currently resolves to %, expected Valbuena (%). Fix the '
                    'office_terms rows first — CC_0201 is the source of truth for the handover.',
                    v_office, coalesce(v_holder::text, '<vacant>'), v_valbuena;
  END IF;
END $$;

UPDATE essentials.politicians
   SET is_incumbent     = false,
       office_id        = NULL,
       last_update_date = now()
 WHERE id = 'fa932212-a2cf-4fa1-97ab-c6619e3db610'
   AND full_name = 'Robert S. Draper'
   AND (is_incumbent IS DISTINCT FROM false OR office_id IS NOT NULL);

UPDATE essentials.politicians
   SET is_incumbent     = true,
       office_id        = '83969e0c-c530-4649-bf82-68e25eca0c85',
       last_update_date = now()
 WHERE id = '917d6200-f048-4b7b-85f7-3a390abeecf2'
   AND full_name = 'Tal K. Valbuena'
   AND (is_incumbent IS DISTINCT FROM true
        OR office_id IS DISTINCT FROM '83969e0c-c530-4649-bf82-68e25eca0c85'::uuid);

DO $$
DECLARE
  d record;
  v record;
BEGIN
  SELECT is_incumbent, office_id, is_active INTO d
    FROM essentials.politicians WHERE id = 'fa932212-a2cf-4fa1-97ab-c6619e3db610';
  SELECT is_incumbent, office_id, is_active INTO v
    FROM essentials.politicians WHERE id = '917d6200-f048-4b7b-85f7-3a390abeecf2';

  IF d.is_incumbent IS DISTINCT FROM false OR d.office_id IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0202: Draper still reads is_incumbent=% office_id=%',
      d.is_incumbent, coalesce(d.office_id::text, '<null>');
  END IF;
  IF v.is_incumbent IS DISTINCT FROM true
     OR v.office_id IS DISTINCT FROM '83969e0c-c530-4649-bf82-68e25eca0c85'::uuid THEN
    RAISE EXCEPTION 'CC_0202: Valbuena reads is_incumbent=% office_id=%',
      v.is_incumbent, coalesce(v.office_id::text, '<null>');
  END IF;
  -- Valbuena must be ACTIVE as well as incumbent, or the incumbents-only reads still skip him.
  IF v.is_active IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'CC_0202: Valbuena is_active=%, expected true — he would stay hidden', v.is_active;
  END IF;
  -- Draper stays an active person; only his incumbency ended.
  IF d.is_active IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'CC_0202: Draper is_active=%, expected true — losing a seat is not leaving the corpus',
      d.is_active;
  END IF;

  RAISE NOTICE 'CC_0202: cached columns now agree with the dated terms — Valbuena incumbent, Draper not.';
END $$;

COMMIT;
