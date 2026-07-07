-- 1267_seed_nh_2026_house_candidates.sql
-- Phase 165-06: 19 new NH candidates — NH-1 OPEN 14-candidate field (9D+5R, seq from 33:
--   -330133..-330146; Pappas 36c07696 -> Senate, NO row) + NH-2 5 new (-330201..-330205) +
--   Goodlander (-33002) renominated reuse (is_incumbent=true). PROVISIONAL, cull >= 2026-09-08.
--   EXCLUDED pending-independents (window to 2026-09-02 -> Phase 167): Black, Mahrou, Sykes.
--   NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330133, 'Carleigh Beriont', 'Carleigh', 'Beriont', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330133);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330134, 'Sarah Chadzynski', 'Sarah', 'Chadzynski', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330134);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330135, 'Bill Conlin', 'Bill', 'Conlin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330135);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330136, 'Matthew Emerson', 'Matthew', 'Emerson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330136);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330137, 'Heath Howard', 'Heath', 'Howard', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330137);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330138, 'Stefany Shaheen', 'Stefany', 'Shaheen', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330138);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330139, 'Sarah Bella Spinosa', 'Sarah', 'Bella Spinosa', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330139);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330140, 'Maura Sullivan', 'Maura', 'Sullivan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330140);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330141, 'Christian Urrutia', 'Christian', 'Urrutia', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330141);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330142, 'Lindsey Anderson', 'Lindsey', 'Anderson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330142);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330143, 'Melissa Bailey', 'Melissa', 'Bailey', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330143);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330144, 'Brian Cole', 'Brian', 'Cole', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330144);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330145, 'Anthony DiLorenzo', 'Anthony', 'DiLorenzo', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330145);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330146, 'Hollie Noveletsky', 'Hollie', 'Noveletsky', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330146);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330201, 'Paige Beauchemin', 'Paige', 'Beauchemin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330202, 'Michael Callis', 'Michael', 'Callis', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330203, 'Dan Nicholson', 'Dan', 'Nicholson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330204, 'Victor Orlando', 'Victor', 'Orlando', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -330205, 'Lily Tang Williams', 'Lily', 'Tang Williams', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -330205);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carleigh Beriont', 'Carleigh', 'Beriont', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330133
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sarah Chadzynski', 'Sarah', 'Chadzynski', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330134
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bill Conlin', 'Bill', 'Conlin', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330135
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Matthew Emerson', 'Matthew', 'Emerson', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330136
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Heath Howard', 'Heath', 'Howard', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330137
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Stefany Shaheen', 'Stefany', 'Shaheen', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330138
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Sarah Bella Spinosa', 'Sarah', 'Bella Spinosa', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330139
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Maura Sullivan', 'Maura', 'Sullivan', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330140
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Christian Urrutia', 'Christian', 'Urrutia', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330141
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lindsey Anderson', 'Lindsey', 'Anderson', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330142
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Melissa Bailey', 'Melissa', 'Bailey', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330143
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Brian Cole', 'Brian', 'Cole', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330144
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Anthony DiLorenzo', 'Anthony', 'DiLorenzo', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330145
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Hollie Noveletsky', 'Hollie', 'Noveletsky', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3301'
JOIN essentials.politicians p ON p.external_id = -330146
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Paige Beauchemin', 'Paige', 'Beauchemin', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3302'
JOIN essentials.politicians p ON p.external_id = -330201
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Callis', 'Michael', 'Callis', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3302'
JOIN essentials.politicians p ON p.external_id = -330202
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Dan Nicholson', 'Dan', 'Nicholson', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3302'
JOIN essentials.politicians p ON p.external_id = -330203
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Victor Orlando', 'Victor', 'Orlando', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3302'
JOIN essentials.politicians p ON p.external_id = -330204
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Lily Tang Williams', 'Lily', 'Tang Williams', false, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3302'
JOIN essentials.politicians p ON p.external_id = -330205
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Maggie Goodlander', 'Maggie', 'Goodlander', true, 'active', 'NH SoS cumulative filings 6/29/26 (sos.nh.gov; pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-09-02 -> Phase 167)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'NH 2026 Statewide General'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = '3302'
JOIN essentials.politicians p ON p.external_id = -33002
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
