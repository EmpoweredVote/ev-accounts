-- Migration 771 — Fix Utah local-government chamber linkage + duplicate cleanup
--
-- Background (investigation 2026-06-18):
--   Utah local officials were loaded in two passes. "Pass A" created
--   LOCAL/LOCAL_EXEC offices for ~99 cities with offices.chamber_id = NULL and
--   no governments row, so government_name resolves empty and the frontend
--   bucketed them under "Unknown". "Pass B" later created proper
--   governments+chambers+chamber-linked records for ~11 cities but never deleted
--   the Pass A rows, producing duplicates.
--
-- Each active NULL-chamber LOCAL/LOCAL_EXEC office is resolved to a canonical
-- city (by districts.city, else the ocd-division place slug, else the district
-- label with its body suffix stripped) and to any EXISTING city government
-- (matched by numeric place GEOID or by ocd place slug — so ward-districted
-- cities like Salt Lake City resolve to their real government and we never
-- fabricate a bogus "City of Salt Lake").
--
--   PART A  cities with NO existing government  -> CREATE government + council
--           chamber, then LINK the offices.
--   PART B  cities WITH an existing government:
--             (b1) NULL record duplicates an existing chamber-linked person
--                  (same last name + first initial) -> re-point its stances
--                  (inform.politician_answers / politician_context) onto the
--                  surviving twin where the twin lacks that topic, then
--                  DEACTIVATE the duplicate (is_active=false; reversible, removes
--                  it from address AND name search). No row deletion.
--             (b2) NULL record has no twin (genuinely missing linkage) -> LINK
--                  it to the existing council chamber.
--
-- Idempotent: re-running is a no-op (creates are NOT EXISTS-guarded; link/merge
-- only touch active chamber_id IS NULL rows, which no longer exist after success).

BEGIN;

-- ---------------------------------------------------------------------------
-- Resolve every active NULL-chamber LOCAL/LOCAL_EXEC office to a canonical city
-- key, a representative place GEOID, and (if any) its existing government.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE _resolved ON COMMIT DROP AS
WITH null_off AS (
  SELECT o.id AS office_id, o.politician_id,
         p.first_name, p.last_name,
         d.geo_id, d.district_type, d.label, d.city,
         CASE WHEN d.geo_id ~ '^[0-9]{6,7}$' THEN d.geo_id END AS numeric_geo,
         CASE WHEN d.geo_id LIKE 'ocd-division/%place:%'
              THEN replace(substring(d.geo_id from 'place:([^/]+)'), '_', ' ') END AS ocd_place
  FROM essentials.offices o
  JOIN essentials.districts d   ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.district_type IN ('LOCAL','LOCAL_EXEC')
    AND o.chamber_id IS NULL
    AND p.is_active = true
)
SELECT n.*,
       lower(COALESCE(NULLIF(btrim(n.city),''), n.ocd_place,
         btrim(regexp_replace(n.label,'(City Council|Town Council|City Commission|Council|Mayor|Board).*$','','i')))
       ) AS city_key,
       COALESCE(gnum.id, gocd.id) AS existing_gov_id
FROM null_off n
LEFT JOIN essentials.governments gnum ON gnum.type IN ('City','Town') AND gnum.geo_id = n.numeric_geo
LEFT JOIN essentials.governments gocd ON gocd.type IN ('City','Town') AND lower(gocd.city) = lower(n.ocd_place);

-- One row per canonical city: display name, representative place GEOID, and
-- whether a government already exists for it.
CREATE TEMP TABLE _city ON COMMIT DROP AS
SELECT city_key,
       initcap(city_key) AS city_name,
       max(numeric_geo)  AS place_geo,
       bool_or(existing_gov_id IS NOT NULL) AS has_existing
FROM _resolved
GROUP BY city_key;

-- ===========================================================================
-- PART A — CREATE government + chamber, then LINK (cities with no existing gov)
-- ===========================================================================

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of ' || city_name || ', Utah, US', 'City', 'ut', city_name, place_geo
FROM _city c
WHERE NOT c.has_existing
  AND NOT EXISTS (
    SELECT 1 FROM essentials.governments g
    WHERE g.type IN ('City','Town')
      AND (g.geo_id = c.place_geo OR lower(g.city) = c.city_key)
  );

INSERT INTO essentials.chambers (id, government_id, name, name_formal)
SELECT gen_random_uuid(), g.id, g.city || ' City Council', g.city || ' City Council'
FROM essentials.governments g
JOIN _city c ON NOT c.has_existing AND lower(g.city) = c.city_key AND g.geo_id = c.place_geo
WHERE g.type = 'City' AND g.state = 'ut'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id = g.id AND ch.name ILIKE '%council%');

UPDATE essentials.offices o
SET chamber_id = ch.id
FROM _resolved r
JOIN _city c          ON c.city_key = r.city_key AND NOT c.has_existing
JOIN essentials.governments g ON g.type = 'City' AND lower(g.city) = c.city_key AND g.geo_id = c.place_geo
JOIN essentials.chambers ch   ON ch.government_id = g.id AND ch.name ILIKE '%council%'
WHERE o.id = r.office_id AND o.chamber_id IS NULL;

-- ===========================================================================
-- PART B — existing-government cities
-- ===========================================================================

-- B0: map each NULL duplicate politician to its surviving chamber-linked twin
--     (same government; last_name + first initial tolerates "Ben"/"Benjamin").
CREATE TEMP TABLE _twin_map ON COMMIT DROP AS
SELECT DISTINCT ON (r.politician_id)
       r.politician_id AS dup_id,
       surv.id         AS keep_id
FROM _resolved r
JOIN essentials.offices so       ON so.chamber_id IS NOT NULL
JOIN essentials.chambers sch     ON sch.id = so.chamber_id AND sch.government_id = r.existing_gov_id
JOIN essentials.politicians surv ON surv.id = so.politician_id AND surv.is_active = true
WHERE r.existing_gov_id IS NOT NULL
  AND surv.id <> r.politician_id
  AND lower(surv.last_name) = lower(r.last_name)
  AND lower(left(surv.first_name,1)) = lower(left(r.first_name,1))
ORDER BY r.politician_id, surv.id;

-- B1: re-point stances for topics the surviving twin does NOT already have.
UPDATE inform.politician_answers a
SET politician_id = m.keep_id
FROM _twin_map m
WHERE a.politician_id = m.dup_id
  AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a2
                  WHERE a2.politician_id = m.keep_id AND a2.topic_id = a.topic_id);

UPDATE inform.politician_context c
SET politician_id = m.keep_id
FROM _twin_map m
WHERE c.politician_id = m.dup_id
  AND NOT EXISTS (SELECT 1 FROM inform.politician_context c2
                  WHERE c2.politician_id = m.keep_id AND c2.topic_id = c.topic_id);

-- B2: deactivate the duplicate NULL politicians (reversible; drops them from all surfaced queries).
UPDATE essentials.politicians p
SET is_active = false
FROM _twin_map m
WHERE p.id = m.dup_id;

-- B3: LINK the remaining (no-twin) NULL offices in existing-gov cities to the
--     existing council chamber. Their politician is still active (not a dup).
UPDATE essentials.offices o
SET chamber_id = ch.id
FROM _resolved r
JOIN essentials.chambers ch ON ch.government_id = r.existing_gov_id AND ch.name ILIKE '%council%'
JOIN essentials.politicians p ON p.id = r.politician_id AND p.is_active = true
WHERE o.id = r.office_id
  AND r.existing_gov_id IS NOT NULL
  AND o.chamber_id IS NULL
  AND r.politician_id NOT IN (SELECT dup_id FROM _twin_map);

COMMIT;
