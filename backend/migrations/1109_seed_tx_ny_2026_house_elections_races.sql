-- Migration 1109: Seed TX + NY 2026 US House elections + races scaffold (no candidates yet)
--
-- Phase 150-01 (v2.20 2026 US House Candidate Coverage). The ONE structural addition vs CA
-- (Phase 149): CA was turnkey (its 2026 Statewide General election + 52 NATIONAL_LOWER races
-- pre-existed). TX and NY have ZERO House races (verified live 2026-06-29: 0 races on any TX/NY
-- NATIONAL_LOWER office; no 'TX/NY 2026 Statewide General' election). This migration authors that
-- scaffold so Phase 150 Wave 2 can wire race_candidates onto it.
--
-- Creates: 2 elections (TX/NY 2026 Statewide General, mirroring the CA 2026 Statewide General row
-- 728d0074-... exactly: election_type='general', jurisdiction_level='state', election_date 2026-11-03)
-- + 64 races (38 TX geo_id 4801..4838 + 26 NY geo_id 3601..3626), each linked to that district's
-- EXISTING U.S. Representative office (resolved by districts.geo_id; races has no geo_id column).
--
-- Field source: .planning/phases/148-field-resolution-stance-gap-diagnostic/148-FIELD-TABLE.md
-- (per-district geo_id list, field_status=decided for all 64 rows).
--
-- ANTIPARTISAN INVARIANT (D-05): party is NOT stored on race_candidates; races.primary_party stays
-- NULL here (a multi-candidate general has no single primary party). NEVER office_id IS NULL on a
-- House race. NEVER create an essentials.offices or districts row. NEVER reuse the unrelated TX
-- municipal-general / Longview council elections.
--
-- Idempotent: NOT EXISTS guards on (name) for elections and (election_id, office_id) for races
-- (no DB unique constraint -- application-enforced). A re-run inserts 0 rows.

BEGIN;

-- 1. The 2 state general elections (mirror CA 2026 Statewide General shape).
INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), v.name, '2026-11-03T08:00:00.000Z'::timestamptz, 'general', 'state', v.st
FROM (VALUES
  ('TX 2026 Statewide General', 'TX'),
  ('NY 2026 Statewide General', 'NY')
) v(name, st)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.elections e WHERE e.name = v.name
);

-- 2. One race per TX/NY US House district, on the EXISTING NATIONAL_LOWER office (by geo_id).
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT gen_random_uuid(), el.id, o.id, 'U.S. Representative District ' || v.cd, NULL, 1
FROM (VALUES
  ('TX','4801',1),('TX','4802',2),('TX','4803',3),('TX','4804',4),('TX','4805',5),
  ('TX','4806',6),('TX','4807',7),('TX','4808',8),('TX','4809',9),('TX','4810',10),
  ('TX','4811',11),('TX','4812',12),('TX','4813',13),('TX','4814',14),('TX','4815',15),
  ('TX','4816',16),('TX','4817',17),('TX','4818',18),('TX','4819',19),('TX','4820',20),
  ('TX','4821',21),('TX','4822',22),('TX','4823',23),('TX','4824',24),('TX','4825',25),
  ('TX','4826',26),('TX','4827',27),('TX','4828',28),('TX','4829',29),('TX','4830',30),
  ('TX','4831',31),('TX','4832',32),('TX','4833',33),('TX','4834',34),('TX','4835',35),
  ('TX','4836',36),('TX','4837',37),('TX','4838',38),
  ('NY','3601',1),('NY','3602',2),('NY','3603',3),('NY','3604',4),('NY','3605',5),
  ('NY','3606',6),('NY','3607',7),('NY','3608',8),('NY','3609',9),('NY','3610',10),
  ('NY','3611',11),('NY','3612',12),('NY','3613',13),('NY','3614',14),('NY','3615',15),
  ('NY','3616',16),('NY','3617',17),('NY','3618',18),('NY','3619',19),('NY','3620',20),
  ('NY','3621',21),('NY','3622',22),('NY','3623',23),('NY','3624',24),('NY','3625',25),
  ('NY','3626',26)
) v(st, geo_id, cd)
JOIN essentials.elections el ON el.name = (v.st || ' 2026 Statewide General')
JOIN essentials.districts d ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o ON o.district_id = d.id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
);

-- 3. Post-write assertions (abort the transaction if any invariant fails).
DO $$
DECLARE
  n_elections int;
  n_tx int;
  n_ny int;
  n_nulloff int;
BEGIN
  SELECT count(*) INTO n_elections FROM essentials.elections
   WHERE name IN ('TX 2026 Statewide General','NY 2026 Statewide General');
  IF n_elections <> 2 THEN
    RAISE EXCEPTION 'Expected 2 TX/NY elections, found %', n_elections;
  END IF;

  SELECT count(DISTINCT r.id) INTO n_tx
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE el.name = 'TX 2026 Statewide General' AND d.district_type = 'NATIONAL_LOWER';
  IF n_tx <> 38 THEN
    RAISE EXCEPTION 'Expected 38 TX House races, found %', n_tx;
  END IF;

  SELECT count(DISTINCT r.id) INTO n_ny
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE el.name = 'NY 2026 Statewide General' AND d.district_type = 'NATIONAL_LOWER';
  IF n_ny <> 26 THEN
    RAISE EXCEPTION 'Expected 26 NY House races, found %', n_ny;
  END IF;

  SELECT count(*) INTO n_nulloff
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
   WHERE el.name IN ('TX 2026 Statewide General','NY 2026 Statewide General')
     AND r.office_id IS NULL;
  IF n_nulloff <> 0 THEN
    RAISE EXCEPTION 'Found % TX/NY races with NULL office_id', n_nulloff;
  END IF;

  RAISE NOTICE 'OK: 2 elections, TX 38 races, NY 26 races, 0 null office_id';
END $$;

COMMIT;
