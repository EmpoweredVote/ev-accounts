-- 1750_seattle_d5_2026_race.sql
-- Seattle City Council District 5 — the ONLY Seattle city office on the 2026 ballot.
--
-- WHY THIS RACE EXISTS. Seattle runs its city elections in odd years: the Mayor,
-- City Attorney and Council Positions 8/9 were elected in November 2025 (terms to
-- 2029) and Districts 1-7 in November 2023 (terms to 2027). District 5 is the
-- exception. Cathy Moore resigned in July 2025; Debora Juarez was appointed to
-- the seat on 2025-07-28, and under the Seattle City Charter an appointee serves
-- only "until a successor is elected and qualified" — at a special election held
-- in concert with the 2026 state general election. Juarez is not a candidate.
--
-- This was missed in the original scoping, which recorded that Seattle had no
-- 2026 city race at all. It surfaced in King County's primary results feed and is
-- corroborated by the City Clerk's own Terms of Office page, which lists the D5
-- term as expiring 11/2026 with the charter footnote quoted above.
--
-- FIELD from the King County primary results feed
-- (results.votewa.gov/results/public/api/elections/king-county-wa/20260804/data),
-- which is authoritative for a Seattle municipal race because Seattle sits wholly
-- within King County and the county administers its elections. Write-in is a
-- ballot aggregate, not a filed candidate, and is excluded.
--
-- NOT CULLED. All four carry provisional_until = 2026-08-24, matching every other
-- 2026 row on this election. Jenks and Kang led the primary, but the cull gates on
-- the CERTIFIED canvass, not on election-night ordering.
--
-- No candidate is an incumbent: the appointed occupant is not running, so
-- is_incumbent is false for all four and none links to a politician row.

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '51e7a875-bff9-4e96-adcf-41736454d25d', o.id,
       'Seattle City Council District 5', NULL, 1
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'City Council'
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = 'Councilmember, District 5'
WHERE g.geo_id = '5363000' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r
    WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
      AND r.position_name = 'Seattle City Council District 5'
  );

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, NULL, v.name, false, 'active', DATE '2026-08-24',
       'King County primary results feed (results.votewa.gov king-county-wa/20260804) for the filed field; existence of the race corroborated by the Seattle City Clerk Terms of Office page (District 5 term expires 11/2026, successor elected at a special election in concert with the 2026 state general election). Pre-certification field; cull gates on the certified canvass. Retrieved 2026-08-13.'
FROM essentials.races r
CROSS JOIN (VALUES
  ('Nilu Jenks'),
  ('Julie Kang'),
  ('Dimitri Georgakopoulos'),
  ('Silas James')
) AS v(name)
WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
  AND r.position_name = 'Seattle City Council District 5'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id
      AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key(v.name)
  );
