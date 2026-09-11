\set ON_ERROR_STOP on
-- IN-8 planted controls. Each runs inside BEGIN ... ROLLBACK. 🔴 The row count of the PLANT is
-- checked, not just the verdict that follows it: IN-2 had a control "pass" while its INSERT hit
-- zero rows, so nothing was ever planted.

\echo '=== CONTROL 1: unseat District 3 (away from the City Hall anchor) ==='
BEGIN;
DO $$
DECLARE v_del int; v_n int;
BEGIN
  DELETE FROM essentials.office_terms ot
   USING essentials.offices o, essentials.districts d
   WHERE ot.office_id = o.id AND o.district_id = d.id AND d.geo_id = 'gary-in-council-district-3';
  GET DIAGNOSTICS v_del = ROW_COUNT;
  RAISE NOTICE '  plant removed % term row(s)', v_del;
  IF v_del <> 1 THEN RAISE EXCEPTION 'CONTROL 1 PLANT FAILED: deleted % rows, expected 1 -- nothing was planted', v_del; END IF;

  -- 🔴 COUNT och.politician_id, NOT count(*). office_current_holder LEFT JOINs from offices, so
  -- an UNSEATED office still returns a row carrying a NULL politician_id. The first version of
  -- this control used count(*), read 1 after a successful unseat, and reported DID NOT FIRE --
  -- a broken control, not a defect. The probe itself was never wrong: it inner-joins politicians.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.geofence_boundaries g2
    JOIN essentials.districts d2 ON d2.geo_id = g2.geo_id AND d2.mtfcc = g2.mtfcc
    JOIN essentials.offices o ON o.district_id = d2.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = 'gary-in-council-district-3' AND gb.mtfcc='X0050'
   WHERE g2.mtfcc='X0050' AND ST_Covers(g2.geometry, ST_PointOnSurface(gb.geometry));
  RAISE NOTICE '  District 3 interior point now returns % councilmember(s)', v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CONTROL 1 DID NOT FIRE: still % holder(s)', v_n; END IF;
  RAISE NOTICE '  ✓ CONTROL 1 FIRED -- the per-district sweep sees an unseated district';
END $$;
ROLLBACK;

\echo ''
\echo '=== CONTROL 2: the Long Beach defect -- move District 6 onto the CITYWIDE polygon ==='
BEGIN;
DO $$
DECLARE v_upd int; v_dist int;
BEGIN
  UPDATE essentials.offices o
     SET district_id = (SELECT id FROM essentials.districts
                         WHERE geo_id='1827000' AND district_type='LOCAL' AND lower(state)='in')
   WHERE o.title = 'Council Member, District 6'
     AND o.district_id = (SELECT id FROM essentials.districts WHERE geo_id='gary-in-council-district-6');
  GET DIAGNOSTICS v_upd = ROW_COUNT;
  RAISE NOTICE '  plant moved % office row(s) onto the citywide polygon', v_upd;
  IF v_upd <> 1 THEN RAISE EXCEPTION 'CONTROL 2 PLANT FAILED: moved % rows, expected 1', v_upd; END IF;

  SELECT count(*) FILTER (WHERE o.title LIKE 'Council Member, District%') INTO v_dist
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-87.33780, 41.60360), 4326));
  RAISE NOTICE '  Gary City Hall now returns % district councilmember(s)', v_dist;
  IF v_dist < 2 THEN RAISE EXCEPTION 'CONTROL 2 DID NOT FIRE: City Hall returns %, expected >= 2', v_dist; END IF;
  RAISE NOTICE '  ✓ CONTROL 2 FIRED -- a district seat on the citywide polygon reaches every Gary address';
END $$;
ROLLBACK;

\echo ''
\echo '=== CONTROL 3: seat Marian Ivey on her OLD at-large seat as well as District 4 ==='
BEGIN;
-- 🔴 THE FIRST VERSION OF THIS PLANT WAS REFUSED BY THE DATABASE, AND THAT IS A FINDING.
-- Inserting Ivey onto an at-large seat that Tolliver already holds open-ended violates
-- `office_terms_no_overlap`: an open-ended term is an INFINITE range, so the schema already
-- makes TWO PEOPLE ON ONE OFFICE impossible. What it cannot see is ONE PERSON ON TWO OFFICES --
-- which is exactly the Mark Spencer failure, and exactly why CC_0097 gates it in SQL rather than
-- relying on a constraint. So the plant first vacates the at-large seat, then double-seats Ivey.
DO $$
DECLARE v_ins int; v_ivey int; v_del int;
BEGIN
  DELETE FROM essentials.office_terms ot
   USING essentials.offices o, essentials.chambers c, essentials.governments g
   WHERE ot.office_id = o.id AND c.id = o.chamber_id AND g.id = c.government_id
     AND g.name = 'City of Gary, Indiana, US'
     AND o.title = 'Council Member, At Large'
     AND o.description LIKE 'Internal ordinal 1 of 3%';
  GET DIAGNOSTICS v_del = ROW_COUNT;
  IF v_del <> 1 THEN RAISE EXCEPTION 'CONTROL 3 PLANT FAILED: vacated % at-large seat(s), expected 1', v_del; END IF;

  INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
  SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown', 'CONTROL PLANT'
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id AND g.name='City of Gary, Indiana, US'
    JOIN essentials.politicians p ON p.full_name = 'Marian Ivey'
   WHERE o.title = 'Council Member, At Large'
     AND o.description LIKE 'Internal ordinal 1 of 3%'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id=o.id AND ot.politician_id=p.id);
  GET DIAGNOSTICS v_ins = ROW_COUNT;
  RAISE NOTICE '  plant inserted % term row(s)', v_ins;
  IF v_ins <> 1 THEN RAISE EXCEPTION 'CONTROL 3 PLANT FAILED: inserted % rows, expected 1 -- the tell IN-2 missed', v_ins; END IF;

  SELECT count(*) INTO v_ivey
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name='City of Gary, Indiana, US' AND p.full_name='Marian Ivey';
  RAISE NOTICE '  Marian Ivey now holds % Gary offices', v_ivey;
  IF v_ivey <> 2 THEN RAISE EXCEPTION 'CONTROL 3 DID NOT FIRE: Ivey holds %, expected 2', v_ivey; END IF;
  RAISE NOTICE '  ✓ CONTROL 3 FIRED -- CC_0097''s gate would catch the same person on two live seats';
END $$;
ROLLBACK;

\echo ''
\echo '=== after all three rollbacks, production must be untouched ==='
SELECT (SELECT count(och.politician_id) FROM essentials.offices o
          JOIN essentials.chambers c ON c.id=o.chamber_id
          JOIN essentials.governments g ON g.id=c.government_id
          LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
         WHERE g.name='City of Gary, Indiana, US' AND c.name='Gary Common Council') AS council_seated,
       (SELECT count(*) FROM essentials.office_current_holder och
          JOIN essentials.politicians p ON p.id=och.politician_id
         WHERE p.full_name='Marian Ivey') AS ivey_seats;
