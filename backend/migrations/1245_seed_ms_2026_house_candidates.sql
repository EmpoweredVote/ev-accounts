-- 1245_seed_ms_2026_house_candidates.sql
-- Phase 164-06 Task 3: 8 new MS politicians + 12 active race_candidates onto the 4
--   MS 2026 Statewide General races. Reuse 4 renominated incumbents (-28001..-28004). No open seats.
--   external_id band -(28*10000+cd*100+seq), standard seq 1. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -280101, 'Cliff Johnson', 'Cliff', 'Johnson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -280101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -280102, 'Johnny Baucom', 'Johnny', 'Baucom', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -280102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -280201, 'Ron Eller', 'Ron', 'Eller', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -280201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -280202, 'Bennie Foster', 'Bennie', 'Foster', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -280202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -280301, 'Michael Chiaradio', 'Michael', 'Chiaradio', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -280301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -280302, 'Erik Kiehle', 'Erik', 'Kiehle', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -280302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -280401, 'Jeffrey Hulum III', 'Jeffrey', 'Hulum III', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -280401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -280402, 'Carl Boyanton', 'Carl', 'Boyanton', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -280402);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Trent Kelly', 'Trent', 'Kelly', true, 'active', 'MS 2026 US House field (Clarion-Ledger + MS SoS candidate filings); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -28001
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2801'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Trent Kelly'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Cliff Johnson', 'Cliff', 'Johnson', false, 'active', 'MS 2026 US House field (Clarion-Ledger + MS SoS candidate filings); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -280101
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2801'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Cliff Johnson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Johnny Baucom', 'Johnny', 'Baucom', false, 'active', 'MS 2026 US House field (minor-party/independent filing; Clarion-Ledger + MS SoS); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -280102
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2801'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Johnny Baucom'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bennie G. Thompson', 'Bennie', 'G. Thompson', true, 'active', 'MS 2026 US House field (Clarion-Ledger + MS SoS candidate filings); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -28002
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2802'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bennie G. Thompson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Ron Eller', 'Ron', 'Eller', false, 'active', 'MS 2026 US House field (Clarion-Ledger + MS SoS candidate filings); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -280201
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2802'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Ron Eller'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Bennie Foster', 'Bennie', 'Foster', false, 'active', 'MS 2026 US House field (minor-party/independent filing; Clarion-Ledger + MS SoS); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -280202
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2802'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Bennie Foster'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Guest', 'Michael', 'Guest', true, 'active', 'MS 2026 US House field (Clarion-Ledger + MS SoS candidate filings); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -28003
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2803'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Guest'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Michael Chiaradio', 'Michael', 'Chiaradio', false, 'active', 'MS 2026 US House field (Clarion-Ledger + MS SoS candidate filings); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -280301
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2803'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Michael Chiaradio'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Erik Kiehle', 'Erik', 'Kiehle', false, 'active', 'MS 2026 US House field (minor-party/independent filing; Clarion-Ledger + MS SoS); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -280302
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2803'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Erik Kiehle'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Mike Ezell', 'Mike', 'Ezell', true, 'active', 'MS 2026 US House field (Clarion-Ledger + MS SoS candidate filings); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -28004
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2804'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Mike Ezell'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Jeffrey Hulum III', 'Jeffrey', 'Hulum III', false, 'active', 'MS 2026 US House field (Clarion-Ledger + MS SoS candidate filings); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -280401
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2804'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Jeffrey Hulum III'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Carl Boyanton', 'Carl', 'Boyanton', false, 'active', 'MS 2026 US House field (minor-party/independent filing; Clarion-Ledger + MS SoS); decided general field'
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = -280402
WHERE el.name = 'MS 2026 Statewide General' AND d.geo_id = '2804'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Carl Boyanton'));

COMMIT;
