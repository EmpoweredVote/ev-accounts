-- CC_0025_ga_legislature_structure.sql
-- Knight Foundation program, wave GA-2 (structure half).
--
-- Creates the two Georgia legislative chambers under the existing 'State of Georgia'
-- government, and one office per district: 180 Representatives + 56 Senators = 236.
-- Creates NO people and NO terms -- the incumbents migration does that, and the two are
-- applied back to back.
--
-- 🔴 SENATE DISTRICT 12 IS VACANT AND IS FLAGGED HERE, in the structure migration, not later.
-- legis.ga.gov still lists Freddie Powell Sims as its sitting senator with no vacate date.
-- She RESIGNED 2026-03-23 (WALB, Albany Herald and Early County News all name the date), and
-- Open States carries 55 Georgia senators with no District 12 at all. Two independent lines say
-- the seat is not hers and the chamber's own record is stale. Seating from that roster alone
-- would have put a departed senator in a live seat -- the TX SD-22 Birdwell failure, exactly.
--
-- vacant_since is left NULL. What is documented is the ANNOUNCEMENT of a resignation; no
-- authoritative effective date was published, and CLAUDE.md forbids inventing one.
--
-- Flagging here is load-bearing twice over, same as FL-2:
--   1. check-address-reachability.mjs classifies DEAD_GEOGRAPHY as "reachable AND offices > 0
--      AND active_holders = 0 AND vacant_offices = 0". An unflagged empty office fires a NEW
--      ga|STATE_UPPER bucket and fails the gate.
--   2. essentials.offices_missing_terms separates flagged-vacant rows from unflagged ones, and
--      only the unflagged count is drift. Flagging here keeps that count steady in the window
--      between the two applies.
--
-- Districts and geometry come from scripts/load-state-tiger-boundaries.ts (wave GA-1), not from
-- this migration. 🔴 EVERY JOIN PAIRS geo_id WITH district_type: Georgia's collision is
-- THREE-WAY -- sldl runs 13001..13180, sldu 13001..13056, and 89 of the 159 county GEOIDs fall
-- inside the sldl range, so '13009' is Baldwin County AND House District 9.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded and the vacancy UPDATE is guarded on the
-- current value. Ends with a post-verify gate.

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf', 'Georgia House of Representatives', 'Georgia House of Representatives', 180
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf' AND name = 'Georgia House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf', 'Georgia State Senate', 'Georgia State Senate', 56
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf' AND name = 'Georgia State Senate');

-- ─── 236 offices, one per district ───────────────────────────────────────────

CREATE TEMP TABLE ga_offices(geo_id text, district_type text, chamber_name text, title text) ON COMMIT DROP;
INSERT INTO ga_offices(geo_id, district_type, chamber_name, title) VALUES
  ('13001', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13002', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13003', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13004', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13005', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13006', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13007', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13008', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13009', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13010', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13011', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13012', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13013', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13014', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13015', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13016', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13017', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13018', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13019', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13020', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13021', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13022', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13023', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13024', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13025', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13026', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13027', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13028', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13029', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13030', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13031', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13032', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13033', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13034', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13035', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13036', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13037', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13038', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13039', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13040', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13041', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13042', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13043', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13044', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13045', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13046', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13047', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13048', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13049', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13050', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13051', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13052', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13053', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13054', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13055', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13056', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13057', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13058', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13059', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13060', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13061', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13062', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13063', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13064', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13065', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13066', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13067', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13068', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13069', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13070', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13071', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13072', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13073', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13074', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13075', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13076', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13077', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13078', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13079', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13080', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13081', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13082', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13083', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13084', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13085', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13086', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13087', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13088', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13089', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13090', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13091', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13092', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13093', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13094', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13095', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13096', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13097', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13098', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13099', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13100', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13101', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13102', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13103', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13104', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13105', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13106', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13107', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13108', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13109', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13110', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13111', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13112', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13113', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13114', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13115', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13116', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13117', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13118', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13119', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13120', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13121', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13122', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13123', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13124', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13125', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13126', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13127', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13128', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13129', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13130', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13131', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13132', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13133', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13134', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13135', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13136', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13137', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13138', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13139', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13140', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13141', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13142', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13143', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13144', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13145', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13146', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13147', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13148', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13149', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13150', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13151', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13152', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13153', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13154', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13155', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13156', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13157', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13158', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13159', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13160', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13161', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13162', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13163', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13164', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13165', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13166', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13167', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13168', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13169', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13170', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13171', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13172', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13173', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13174', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13175', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13176', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13177', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13178', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13179', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13180', 'STATE_LOWER', 'Georgia House of Representatives', 'Representative'),
  ('13001', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13002', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13003', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13004', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13005', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13006', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13007', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13008', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13009', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13010', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13011', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13012', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13013', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13014', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13015', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13016', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13017', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13018', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13019', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13020', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13021', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13022', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13023', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13024', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13025', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13026', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13027', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13028', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13029', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13030', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13031', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13032', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13033', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13034', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13035', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13036', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13037', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13038', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13039', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13040', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13041', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13042', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13043', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13044', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13045', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13046', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13047', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13048', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13049', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13050', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13051', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13052', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13053', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13054', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13055', 'STATE_UPPER', 'Georgia State Senate', 'Senator'),
  ('13056', 'STATE_UPPER', 'Georgia State Senate', 'Senator');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ga_offices;
  IF n <> 236 THEN RAISE EXCEPTION 'payload: expected 236 offices, got %', n; END IF;
  SELECT count(*) INTO n FROM ga_offices WHERE district_type = 'STATE_LOWER';
  IF n <> 180 THEN RAISE EXCEPTION 'payload: expected 180 House offices, got %', n; END IF;
  -- Every district must already exist from GA-1, matched on geo_id AND district_type.
  SELECT count(*) INTO n
    FROM ga_offices g
   WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d
                      WHERE d.geo_id = g.geo_id AND d.district_type = g.district_type
                        AND lower(d.state) = 'ga');
  IF n <> 0 THEN RAISE EXCEPTION 'precondition: % district(s) from GA-1 are missing', n; END IF;
END $$;

INSERT INTO essentials.offices
       (chamber_id, district_id, title, representing_state, seats,
        is_appointed_position, is_vacant, faces_retention_vote, voting_powers)
SELECT ch.id, d.id, g.title, 'GA', 1, false, false, false, 'full'
  FROM ga_offices g
  JOIN essentials.districts d
    ON d.geo_id = g.geo_id AND d.district_type = g.district_type AND lower(d.state) = 'ga'
  JOIN essentials.chambers ch
    ON ch.government_id = 'eaeb1bd2-6bdb-4475-9bdc-e29acca8bebf' AND ch.name = g.chamber_name
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── The one vacancy ─────────────────────────────────────────────────────────

UPDATE essentials.offices o
   SET is_vacant = true
  FROM essentials.districts d
 WHERE d.id = o.district_id
   AND d.geo_id = '13012' AND d.district_type = 'STATE_UPPER' AND lower(d.state) = 'ga'
   AND o.is_vacant = false;

-- ─── Post-verify ─────────────────────────────────────────────────────────────

DO $$
DECLARE n_off int; n_low int; n_upp int; n_vac int;
BEGIN
  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 236 THEN RAISE EXCEPTION 'expected 236 GA legislative offices, got %', n_off; END IF;

  SELECT count(*) INTO n_low FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga' AND d.district_type = 'STATE_LOWER';
  SELECT count(*) INTO n_upp FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga' AND d.district_type = 'STATE_UPPER';
  IF n_low <> 180 OR n_upp <> 56 THEN
    RAISE EXCEPTION 'expected 180 House / 56 Senate offices, got % / %', n_low, n_upp;
  END IF;

  -- Exactly one flagged vacancy, and it is SD-12.
  SELECT count(*) INTO n_vac FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga' AND d.district_type IN ('STATE_LOWER','STATE_UPPER') AND o.is_vacant;
  IF n_vac <> 1 THEN RAISE EXCEPTION 'expected exactly 1 flagged vacancy, got %', n_vac; END IF;

  SELECT count(*) INTO n_vac FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '13012' AND d.district_type = 'STATE_UPPER' AND lower(d.state) = 'ga'
     AND o.is_vacant AND o.vacant_since IS NULL;
  IF n_vac <> 1 THEN RAISE EXCEPTION 'SD-12 is not flagged vacant with a NULL vacant_since'; END IF;

  RAISE NOTICE 'OK: 236 Georgia legislative offices (180 House, 56 Senate); SD-12 flagged vacant';
END $$;

COMMIT;
