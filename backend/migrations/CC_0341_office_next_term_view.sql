-- CC_0341 — essentials.office_next_term: the successor who has not taken office yet.
--
-- WHY. During a transition a voter should see both people: the sitting officeholder marked
-- "Outgoing", and the winner marked "Incoming on <date>". Today nothing exposes the second one.
-- `essentials.current_office_holders` filters `term_start <= CURRENT_DATE`, so a future-dated
-- term -- which is exactly how a won election is recorded (ADR 0002, and CC_0201 for the worked
-- example) -- is invisible to every read path we have.
--
-- 🔴 THE LABELS ARE DERIVED FROM DATES AND ARE NEVER STORED. "Outgoing" means this office has a
-- row in this view; "Incoming on <date>" is that row's term_start. Nothing has to be flipped on
-- swearing-in day: the term simply starts matching current_office_holders and stops matching
-- this view, on the same date, by the same comparison. That is the whole reason the temporal
-- model exists, and it is why January needs no cleanup pass over 2,159 seats.
--
-- ONE ROW PER OFFICE. `DISTINCT ON (office_id)` ordered by `term_start ASC` takes the NEAREST
-- future term. An office could carry more than one (a successor and a successor's successor);
-- the next one is the only one a voter is being told about.
--
-- ⚠ THIS IS OFFICE-ROOTED, so it de-duplicates on the OFFICE. A politician-rooted read of the
-- same data needs `DISTINCT ON (p.id)` instead -- the right key is opposite in each direction,
-- and getting it wrong here would hide a second seat rather than duplicate one.
--
-- No RLS statement: a view does not carry its own policies. `security_invoker = on` makes
-- office_terms' own RLS apply as the calling user, which is what we want -- the alternative
-- would run it as the view's owner and bypass that.

BEGIN;

CREATE OR REPLACE VIEW essentials.office_next_term
WITH (security_invoker = on) AS
SELECT DISTINCT ON (t.office_id)
       t.office_id,
       t.politician_id,
       t.term_start,
       t.start_precision,
       t.source
  FROM essentials.office_terms t
 WHERE t.term_start > CURRENT_DATE
   AND t.politician_id IS NOT NULL
 ORDER BY t.office_id, t.term_start ASC;

COMMENT ON VIEW essentials.office_next_term IS
  'The nearest term that has not started yet, one row per office. Pairs with '
  'essentials.current_office_holders: a seat mid-transition appears in both, the outgoing '
  'holder in that one and the incoming in this one, and the pair flips by date with no write. '
  'A vacancy span (politician_id IS NULL) is excluded: it names nobody to show. CC_0341.';

GRANT SELECT ON essentials.office_next_term TO anon, authenticated, service_role, ev_api;

DO $$
DECLARE
  v_rows        int;
  v_dupes       int;
  v_in_the_past int;
BEGIN
  SELECT count(*) INTO v_rows FROM essentials.office_next_term;

  SELECT count(*) INTO v_dupes FROM (
    SELECT office_id FROM essentials.office_next_term GROUP BY office_id HAVING count(*) > 1
  ) d;

  SELECT count(*) INTO v_in_the_past
    FROM essentials.office_next_term WHERE term_start <= CURRENT_DATE;

  IF v_dupes <> 0 THEN
    RAISE EXCEPTION 'CC_0341: % office(s) return more than one next term', v_dupes;
  END IF;

  IF v_in_the_past <> 0 THEN
    RAISE EXCEPTION 'CC_0341: % row(s) have already started and must not be in this view', v_in_the_past;
  END IF;

  RAISE NOTICE 'CC_0341 OK: % office(s) have a successor waiting, 0 duplicates, 0 already started',
               v_rows;
END $$;

COMMIT;
