-- verify-lake-county-probes.sql
-- Knight Foundation program, wave IN-6 acceptance evidence. READ-ONLY.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-lake-county-probes.sql
--
-- 🔴 "THREE, NOT ONE" is the assertion that matters, as in Allen County: Indiana elects county
-- commissioners COUNTY-WIDE, so every Lake County address must return all three.
--
-- 🔴 AND "SEVEN, NOT ANY": Lake County Council has seven single-member districts and NONE of them
-- is modelled, because Lake publishes every map as PDF and its 174-layer open-data organisation
-- carries no electoral district layer. Offices without geometry are unreachable by address, which
-- is the defect this slice measured at 671 offices. Their absence is asserted so that adding them
-- later is a decision, not an accident.

\echo ''
\echo '=== 1. What a Gary address returns from the COUNTY tier ==='

SELECT c.name AS chamber, o.title, p.full_name AS holder, ot.start_precision
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id
LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
LEFT JOIN essentials.politicians p ON p.id = och.politician_id
LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.politician_id = och.politician_id
WHERE g.name = 'Lake County, Indiana, US'
  AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-87.33780, 41.60360), 4326))
ORDER BY c.name, o.title;

\echo ''
\echo '=== 2. GATE ==='

DO $$
DECLARE v_comm int; v_officers int; v_council int; v_dated int; v_brewer int;
BEGIN
  SELECT
    count(*) FILTER (WHERE c.name = 'Board of Commissioners' AND och.politician_id IS NOT NULL),
    count(*) FILTER (WHERE c.name = 'Elected Officials' AND och.politician_id IS NOT NULL)
  INTO v_comm, v_officers
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.name = 'Lake County, Indiana, US'
    AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-87.33780, 41.60360), 4326));

  IF v_comm <> 3 THEN
    RAISE EXCEPTION 'IN-6 probe: a Gary address returns % commissioner(s), expected 3 -- Indiana elects all three county-wide', v_comm;
  END IF;
  IF v_officers <> 9 THEN
    RAISE EXCEPTION 'IN-6 probe: a Gary address returns % county officer(s), expected 9', v_officers;
  END IF;

  SELECT count(*) INTO v_council FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Lake County, Indiana, US' AND c.name = 'Lake County Council';
  IF v_council <> 0 THEN
    RAISE EXCEPTION 'IN-6 probe: % Lake County Council office(s) exist; all seven are deferred until district geometry is obtained', v_council;
  END IF;

  SELECT count(*) INTO v_dated
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'Lake County, Indiana, US' AND ot.term_start IS NOT NULL;
  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'IN-6 probe: % Lake County term(s) carry a start date; none is published for any Lake County official', v_dated;
  END IF;

  -- 🔴 Ronald G. Brewer Sr. left Gary's at-large council seat and sits on Lake County Council
  -- District 2 -- a seat this wave DEFERRED. He must therefore hold NO office in production yet.
  -- When the council seats are written, check first whether he already holds a Gary one.
  SELECT count(*) INTO v_brewer
  FROM essentials.office_current_holder och
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE lower(p.last_name) = 'brewer' AND lower(p.first_name) LIKE 'ronald%';
  IF v_brewer <> 0 THEN
    RAISE EXCEPTION 'IN-6 probe: Ronald Brewer holds % office(s). He left Gary at-large for Lake County Council District 2, which is deferred -- check for a double seating.', v_brewer;
  END IF;

  RAISE NOTICE 'IN-6 PROBE PASSED: a Gary address returns 3 commissioners + 9 county officers; 7 council district seats correctly absent; all terms undated; Ronald Brewer not double-seated';
END $$;
