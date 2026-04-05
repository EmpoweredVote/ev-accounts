-- 054_link_unlinked_races_to_offices.sql
-- Link races with null office_id to their matching offices via position_name parsing.
-- This ensures district-specific races (State Rep, US Rep, Board of Supervisors)
-- are matched via geofence instead of appearing for the entire state.

-- State Representatives: "State Representative, District 060" → STATE_LOWER district 60
UPDATE essentials.races r
SET office_id = matched.office_id
FROM (
  SELECT r.id AS race_id, o.id AS office_id
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  CROSS JOIN LATERAL (
    SELECT (regexp_match(r.position_name, 'State Representative,?\s*District\s*0*(\d+)', 'i'))[1] AS dist_num
  ) parsed
  JOIN essentials.districts d ON d.district_type = 'STATE_LOWER'
    AND d.state = e.state
    AND d.district_id = parsed.dist_num
  JOIN essentials.offices o ON o.district_id = d.id
  WHERE r.office_id IS NULL
    AND r.position_name ~* 'State Representative'
    AND parsed.dist_num IS NOT NULL
) matched
WHERE r.id = matched.race_id;

-- US Representatives: "United States Representative, Ninth District" → NATIONAL_LOWER
-- Handle both numeric and word-form district numbers
UPDATE essentials.races r
SET office_id = matched.office_id
FROM (
  SELECT r.id AS race_id, o.id AS office_id
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  CROSS JOIN LATERAL (
    SELECT COALESCE(
      (regexp_match(r.position_name, '(\d+)', 'i'))[1],
      CASE lower((regexp_match(r.position_name, '(First|Second|Third|Fourth|Fifth|Sixth|Seventh|Eighth|Ninth|Tenth)', 'i'))[1])
        WHEN 'first' THEN '1' WHEN 'second' THEN '2' WHEN 'third' THEN '3'
        WHEN 'fourth' THEN '4' WHEN 'fifth' THEN '5' WHEN 'sixth' THEN '6'
        WHEN 'seventh' THEN '7' WHEN 'eighth' THEN '8' WHEN 'ninth' THEN '9'
        WHEN 'tenth' THEN '10' ELSE NULL
      END
    ) AS dist_num
  ) parsed
  JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER'
    AND d.state = e.state
    AND d.district_id = parsed.dist_num
  JOIN essentials.offices o ON o.district_id = d.id
  WHERE r.office_id IS NULL
    AND r.position_name ~* 'United States Representative'
    AND parsed.dist_num IS NOT NULL
) matched
WHERE r.id = matched.race_id;

-- Board of Supervisors: "Board of Supervisors District X" → LOCAL with matching chamber
UPDATE essentials.races r
SET office_id = matched.office_id
FROM (
  SELECT r.id AS race_id, o.id AS office_id
  FROM essentials.races r
  CROSS JOIN LATERAL (
    SELECT (regexp_match(r.position_name, 'Board of Supervisors District\s*(\d+)', 'i'))[1] AS dist_num
  ) parsed
  JOIN essentials.districts d ON d.district_id = parsed.dist_num
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  WHERE r.office_id IS NULL
    AND r.position_name ~* 'Board of Supervisors District'
    AND ch.name_formal LIKE '%Board of Supervisors%'
    AND parsed.dist_num IS NOT NULL
) matched
WHERE r.id = matched.race_id;
