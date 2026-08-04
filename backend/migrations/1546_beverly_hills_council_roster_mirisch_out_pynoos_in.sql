-- 1546_beverly_hills_council_roster_mirisch_out_pynoos_in.sql
--
-- Close John A. Mirisch's Beverly Hills council term and seat Rebecca Pynoos in the seat he vacated.
--
--   Review:   data/stance-research/reresearch-beverly-hills/FINDINGS.md (FINDING 1)
--   Rollback: DELETE FROM essentials.office_terms
--              WHERE office_id = '54ccbc54-a57f-4199-b9c7-ff1eb75a2e8b' AND term_start = '2026-07-07';
--             DELETE FROM essentials.politicians WHERE full_name = 'Rebecca Pynoos';
--             UPDATE essentials.office_terms SET term_end = NULL, how_ended = NULL, source = <prior value>
--              WHERE id = '4da8d225-2a73-4b61-b936-15817484e2cd';
--             UPDATE essentials.politicians SET is_incumbent = true
--              WHERE id = '30f6667d-a88b-46e4-91d8-678130ae37b6';
--             Reversible, but note Pynoos's uuid is generated, so the rollback deletes by name.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1546_beverly_hills_council_roster_mirisch_out_pynoos_in.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------------------------------
-- Found while opening the 303-row stance re-research worklist on the Beverly Hills cluster: before
-- re-researching five councilmembers' retired stances, the roster itself was checked, and one of the five
-- had left office.
--
-- **John Mirisch completed his fourth and final term on 2026-07-07** and is no longer a councilmember.
-- **Rebecca Pynoos** won that seat and was not in the database at all. Two independent sources, both
-- fetched and read rather than recalled:
--
--   * <https://www.beverlyhills.org/223/City-Council> -- the city's own page lists exactly five:
--     Mayor Craig A. Corman, Vice Mayor Mary N. Wells, and Councilmembers Lester Friedman,
--     Sharona R. Nazarian PsyD and Rebecca Pynoos. Mirisch is absent; Pynoos's photo reads
--     "Photo Coming Soon", which is itself a sign the page is current.
--   * <https://beverlypress.com/2026/07/beverly-hills-installs-new-city-council/> -- installation
--     2026-07-07 at the Samuel Goldwyn Theater. Friedman reelected to a third and final term, Nazarian
--     to a second, Pynoos new, and Mirisch out having "completed his fourth and final term on the dais".
--
-- Until this runs, Beverly Hills shows a councilmember who left a month ago and hides the one who
-- replaced him, and the city's stance-coverage denominator counts the wrong five people.
--
-- **This migration touches no stance data.** Mirisch holds zero compass answers (migration 1538 retired
-- all of his as composed citations), so nothing is orphaned by his departure, and that is asserted rather
-- than assumed.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 WHY THE HANDOFF IS DATED 07-06 -> 07-07 AND NOT 07-07 -> 07-07
-- ---------------------------------------------------------------------------------------------------
-- `office_terms_no_overlap` is `EXCLUDE USING gist (office_id WITH =, daterange(term_start, term_end,
-- '[]') WITH &&)` -- **inclusive on both ends**. Mirisch's existing row has term_start NULL and term_end
-- NULL, i.e. an unbounded range. Ending him on 07-07 while starting Pynoos on 07-07 would overlap on that
-- single day and the constraint would reject the insert. So the predecessor's term ends the day before the
-- successor's begins, which is the only way this schema can express consecutive occupancy.
-- **Pynoos's 2026-07-07 is the verified fact** (the installation date); Mirisch's 2026-07-06 is the
-- modelling consequence. His term_start stays NULL -- it was never known (the 1459 backfill wrote
-- start_precision 'unknown') and this migration does not invent one.
--
-- ---------------------------------------------------------------------------------------------------
-- ⚠ WHY BOTH `term_end` AND `is_incumbent` HAVE TO CHANGE
-- ---------------------------------------------------------------------------------------------------
-- Two different gates decide whether a departed official still shows up, and fixing one alone leaves a
-- half-repair:
--   * `essentials.current_office_holders` (which `essentials.office_current_holder` and every
--     government-officials query in essentialsService.ts read through) filters
--     `(term_start IS NULL OR term_start <= CURRENT_DATE) AND (term_end IS NULL OR term_end >= CURRENT_DATE)`.
--     Setting term_end removes him there.
--   * `getPoliticiansFlatList`'s incumbents-only view filters `p.is_incumbent = true` directly on the
--     politicians table, with no occupancy join at all. Only clearing the flag removes him there.
-- `is_active` is deliberately LEFT ALONE. It is selected by several surfaces and its blast radius was not
-- measured here; occupancy is what changed, and occupancy now lives in office_terms.
--
-- ⚠ NOT DONE HERE, and owed: Friedman and Nazarian were both re-elected on 2026-07-07, so each strictly
-- began a NEW term. Their office_terms rows still carry the NULL start/end the migration 1459 backfill
-- wrote. Closing and reopening them would need verified prior-term dates this file does not have, and it
-- changes no display today, so it is recorded rather than guessed.
-- ⚠ Beverly Hills rotates mayor and vice mayor annually, and the seat model carries the title on the
-- office ('Mayor' is a separate office, currently Corman's). That rotation is a standing currency risk
-- this migration does not address.

BEGIN;

-- Snapshot, rather than hard-code, the stance counts this migration must not move. Three sessions write
-- this database concurrently, so an absolute total is a guard that fails for unrelated reasons.
CREATE TEMP TABLE _before_1546 AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS n_answers,
       (SELECT count(*) FROM inform.politician_context) AS n_context;

CREATE TEMP TABLE _ids_1546 (k text PRIMARY KEY, v uuid) ON COMMIT DROP;
INSERT INTO _ids_1546 (k, v) VALUES
  ('mirisch_pol',  '30f6667d-a88b-46e4-91d8-678130ae37b6'),
  ('mirisch_term', '4da8d225-2a73-4b61-b936-15817484e2cd'),
  ('seat_office',  '54ccbc54-a57f-4199-b9c7-ff1eb75a2e8b'),
  ('bh_chamber',   '9c1ac8de-42ef-4cf1-90ee-b5e8d9f5f5d6');

-- ---- pre-flight ------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_txt text;
BEGIN
  -- Derive-then-verify every identifier: name must match the uuid, never trust the uuid alone.
  SELECT p.full_name INTO v_txt FROM essentials.politicians p
    JOIN _ids_1546 i ON i.k = 'mirisch_pol' AND i.v = p.id;
  IF v_txt IS DISTINCT FROM 'John A. Mirisch' THEN
    RAISE EXCEPTION 'mirisch_pol uuid is % , not John A. Mirisch', COALESCE(v_txt, '(no such politician)');
  END IF;

  -- The seat must be a Beverly Hills City Council seat.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN _ids_1546 io ON io.k = 'seat_office'  AND io.v = o.id
    JOIN _ids_1546 ic ON ic.k = 'bh_chamber'   AND ic.v = o.chamber_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'City of Beverly Hills, California, US' AND ch.name = 'City Council'
     AND o.title = 'Council Member';
  IF v_n <> 1 THEN RAISE EXCEPTION 'seat_office is not a Beverly Hills City Council "Council Member" office (found %)', v_n; END IF;

  -- Mirisch's term must be the open one on that seat.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN _ids_1546 it ON it.k = 'mirisch_term' AND it.v = t.id
    JOIN _ids_1546 ip ON ip.k = 'mirisch_pol'  AND ip.v = t.politician_id
    JOIN _ids_1546 io ON io.k = 'seat_office'  AND io.v = t.office_id
   WHERE t.term_end IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected exactly 1 open Mirisch term on that seat, found %', v_n; END IF;

  -- He must currently display, or this migration is fixing something that is not broken.
  SELECT count(*) INTO v_n FROM essentials.current_office_holders coh
    JOIN _ids_1546 ip ON ip.k = 'mirisch_pol' AND ip.v = coh.politician_id;
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected Mirisch to be a current office holder, found % rows', v_n; END IF;

  -- Pynoos must not already be seated as a PERSON.
  -- 🔴 A `LIKE '%pynoos%'` guard here over-fired on the first cut, and the reason matters: most of
  -- essentials.politicians is not people. Three rows match that pattern and all three are
  -- campaign-finance committees -- 'PYNOOS FOR BH CITY COUNCIL 2026; REBECCA' (twice) and
  -- 'PYNOOS FOR LA CITY COUNCIL 2022; KATE' -- with empty first_name, is_active false, and offices
  -- carrying no title, chamber or government. They are not this person and must not block the seating.
  -- So: exact person-form name, plus an occupancy check that no Pynoos already holds a council seat.
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE full_name = 'Rebecca Pynoos';
  IF v_n <> 0 THEN RAISE EXCEPTION 'a person row named Rebecca Pynoos already exists (%) — resolve by hand, do not double-seat', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.current_office_holders coh
    JOIN essentials.offices o ON o.id = coh.office_id
    JOIN _ids_1546 ic ON ic.k = 'bh_chamber' AND ic.v = o.chamber_id
    JOIN essentials.politicians p ON p.id = coh.politician_id
   WHERE p.last_name ILIKE '%pynoos%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'a Pynoos already holds a Beverly Hills council seat (%)', v_n; END IF;

  -- The council must currently show exactly five current holders (4 Council Member + 1 Mayor).
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN _ids_1546 ic ON ic.k = 'bh_chamber' AND ic.v = o.chamber_id
    JOIN essentials.current_office_holders coh ON coh.office_id = o.id;
  IF v_n <> 5 THEN RAISE EXCEPTION 'expected 5 current Beverly Hills council holders before the change, found %', v_n; END IF;

  -- Mirisch holds no stance rows, so his departure orphans nothing. Assert it.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _ids_1546 ip ON ip.k = 'mirisch_pol' AND ip.v = a.politician_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'Mirisch unexpectedly holds % compass answers — stop and decide what happens to them', v_n; END IF;
END $$;

-- ---- close the departed term -----------------------------------------------------------------------
UPDATE essentials.office_terms t
   SET term_end   = DATE '2026-07-06',
       how_ended  = 'term_expired',
       source     = 'migration 1546 — fourth and final term completed at the 2026-07-07 installation; '
                 || 'beverlyhills.org/223/City-Council no longer lists him and '
                 || 'beverlypress.com/2026/07/beverly-hills-installs-new-city-council/ reports him out; '
                 || 'ends 07-06 because office_terms_no_overlap uses inclusive bounds'
  FROM _ids_1546 i
 WHERE i.k = 'mirisch_term' AND i.v = t.id;

UPDATE essentials.politicians p
   SET is_incumbent = false
  FROM _ids_1546 i
 WHERE i.k = 'mirisch_pol' AND i.v = p.id;

-- ---- seat the successor ----------------------------------------------------------------------------
-- external_id is left NULL: that is the norm (78,492 of 85,139 politicians), and inventing an id in the
-- -700xxx band would assert a provenance this row does not have.
WITH new_pol AS (
  INSERT INTO essentials.politicians (
    first_name, last_name, full_name, party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    data_source
  ) VALUES (
    'Rebecca', 'Pynoos', 'Rebecca Pynoos', 'Nonpartisan', NULL,
    true, true, false, false,
    'https://www.beverlyhills.org/223/City-Council (fetched 2026-08-04)'
  ) RETURNING id
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, how_started, start_precision, source)
SELECT i.v, np.id, DATE '2026-07-07', NULL, 'elected', 'day',
       'migration 1546 — installed 2026-07-07 (Samuel Goldwyn Theater); '
    || 'beverlyhills.org/223/City-Council lists her as Councilmember and '
    || 'beverlypress.com/2026/07/beverly-hills-installs-new-city-council/ reports her as the newly elected member'
  FROM new_pol np, _ids_1546 i
 WHERE i.k = 'seat_office';

-- ---- verify ----------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_a int; v_c int; v_names text;
BEGIN
  -- Mirisch is gone from every occupancy surface, and by both gates.
  SELECT count(*) INTO v_n FROM essentials.current_office_holders coh
    JOIN _ids_1546 ip ON ip.k = 'mirisch_pol' AND ip.v = coh.politician_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'Mirisch is still a current office holder (% rows)', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians p
    JOIN _ids_1546 ip ON ip.k = 'mirisch_pol' AND ip.v = p.id
   WHERE p.is_incumbent = false;
  IF v_n <> 1 THEN RAISE EXCEPTION 'Mirisch is_incumbent was not cleared'; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN _ids_1546 it ON it.k = 'mirisch_term' AND it.v = t.id
   WHERE t.term_end = DATE '2026-07-06' AND t.how_ended = 'term_expired';
  IF v_n <> 1 THEN RAISE EXCEPTION 'Mirisch term row not closed as expected'; END IF;

  -- Pynoos seated, exactly once, on the vacated seat, and currently displaying. Counted on the exact
  -- person-form name so the three campaign-finance committee rows cannot satisfy or break this check.
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE full_name = 'Rebecca Pynoos';
  IF v_n <> 1 THEN RAISE EXCEPTION 'expected exactly 1 Rebecca Pynoos, found %', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.current_office_holders coh
    JOIN essentials.politicians p ON p.id = coh.politician_id
    JOIN _ids_1546 io ON io.k = 'seat_office' AND io.v = coh.office_id
   WHERE p.full_name = 'Rebecca Pynoos' AND coh.term_start = DATE '2026-07-07' AND coh.how_started = 'elected';
  IF v_n <> 1 THEN RAISE EXCEPTION 'Pynoos is not the current holder of the vacated seat (% rows)', v_n; END IF;

  -- The council is still five people, and they are exactly the five the city publishes.
  SELECT count(*), string_agg(p.full_name, ', ' ORDER BY p.full_name) INTO v_n, v_names
    FROM essentials.offices o
    JOIN _ids_1546 ic ON ic.k = 'bh_chamber' AND ic.v = o.chamber_id
    JOIN essentials.current_office_holders coh ON coh.office_id = o.id
    JOIN essentials.politicians p ON p.id = coh.politician_id;
  IF v_n <> 5 THEN RAISE EXCEPTION 'expected 5 current council holders after the change, found % (%)', v_n, v_names; END IF;
  IF v_names <> 'Craig A. Corman, Lester Friedman, Mary N. Wells, Rebecca Pynoos, Sharona R. Nazarian' THEN
    RAISE EXCEPTION 'council roster is not the five the city publishes: %', v_names;
  END IF;

  -- No stance data moved.
  SELECT n_answers, n_context INTO v_a, v_c FROM _before_1546;
  SELECT count(*) INTO v_n FROM inform.politician_answers;
  IF v_n <> v_a THEN RAISE EXCEPTION 'politician_answers moved from % to % — this migration must not touch stance data', v_a, v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context;
  IF v_n <> v_c THEN RAISE EXCEPTION 'politician_context moved from % to % — this migration must not touch stance data', v_c, v_n; END IF;
END $$;

DROP TABLE _before_1546;

-- Report: the council as it now stands, with each seat's title and the holder's compass answer count.
SELECT o.title,
       p.full_name,
       coh.term_start,
       (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = p.id) AS compass_answers
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  JOIN essentials.current_office_holders coh ON coh.office_id = o.id
  JOIN essentials.politicians p ON p.id = coh.politician_id
 WHERE g.name = 'City of Beverly Hills, California, US' AND ch.name = 'City Council'
 ORDER BY o.title, p.full_name;

COMMIT;
