-- 1273_seed_vt_2026_house_candidates.sql
-- Phase 165-07: 3 new VT candidates (Coester -500006, Malloy -500007, Ortiz -500008 — D-04
--   safe_start_seq=6, seqs 1-5 occupied live; both R primary rivals seeded per the
--   full-qualified-field rule; Ortiz per the official VT SoS XLSX) + Balint (-50000) reuse.
--   PROVISIONAL, cull >= 2026-08-11. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -500006, 'Mark Coester', 'Mark', 'Coester', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -500006);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -500007, 'Gerald Malloy', 'Gerald', 'Malloy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -500007);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -500008, 'Adam Ortiz', 'Adam', 'Ortiz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -500008);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mark Coester', 'Mark', 'Coester', false, 'active', 'VT SoS qualified-candidates list (sos.vermont.gov; pre-primary qualified field, cull >= 2026-08-11)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'VT 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -500006
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Gerald Malloy', 'Gerald', 'Malloy', false, 'active', 'VT SoS qualified-candidates list (sos.vermont.gov; pre-primary qualified field, cull >= 2026-08-11)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'VT 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -500007
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Adam Ortiz', 'Adam', 'Ortiz', false, 'active', 'VT SoS qualified-candidates list (sos.vermont.gov; pre-primary qualified field, cull >= 2026-08-11)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'VT 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -500008
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Becca Balint', 'Becca', 'Balint', true, 'active', 'VT SoS qualified-candidates list (sos.vermont.gov; pre-primary qualified field, cull >= 2026-08-11)'
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = 'VT 2026 Statewide General'
JOIN essentials.politicians p ON p.external_id = -50000
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
