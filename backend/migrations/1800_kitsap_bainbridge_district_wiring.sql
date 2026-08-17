-- Migration 1800: make Kitsap County and Bainbridge Island reachable by address,
--                 and retitle the Bainbridge council seats to the city's own wording.
--
-- ============================================================================
-- WHAT WAS BROKEN: SIXTEEN SEATED OFFICIALS NOBODY COULD FIND
-- ============================================================================
-- Migration 1798 seeded all 16 offices with offices.district_id = NULL, and 1799
-- hung seven 2026 races off them. Every address, browse and elections query in
-- this codebase reaches a politician through
--   districts -> offices -> office_current_holder,
-- so until this migration NO Kitsap or Bainbridge address returned any of them
-- and none of the seven races was reachable. The people and the races were
-- correct; they were simply unrouted.
--
-- The boundaries were never the blocker. The TIGER load already holds
-- Kitsap County 53035 (G4020) and Bainbridge Island city 5303736 (G4110);
-- WA has 39 G4020, 281 G4110, 49 G5210, 49 G5220 and 10 G5200 rows loaded.
-- (An earlier note recorded "0 boundary rows for 53%". That was reading
-- inform.district_boundaries, a legacy table holding only FIPS 06 and 18 —
-- it is not the routing table. essentials.geofence_boundaries is.)
--
-- ============================================================================
-- 🔴 THE RULING: NEITHER BODY IS ELECTED BY DISTRICT, SO NEITHER ROUTES BY ONE
-- ============================================================================
-- The obvious move — one polygon per commissioner district, one per ward, the
-- way Seattle (X0025) and King County (X0026) are wired — is WRONG HERE, and it
-- is wrong in a way that reads as correct on inspection.
--
--   Kitsap commissioners
--     RCW 36.32.040(1) — "the qualified electors of each county commissioner
--     district, AND THEY ONLY, shall nominate ... candidates for the office of
--     county commissioner".
--     RCW 36.32.050(1) — those candidates "shall be ELECTED BY THE QUALIFIED
--     VOTERS OF THE COUNTY and the person receiving the highest number of votes
--     for the office of commissioner FOR THE DISTRICT IN WHICH HE OR SHE RESIDES
--     shall be declared duly elected from that district."
--     RCW 36.32.052 makes district-based ELECTION mandatory only for a noncharter
--     county of 400,000 or more. Kitsap is noncharter and about 276,000, so it
--     stays on the countywide general. Corroborated independently by Kitsap Sun
--     coverage of the 2026 D3 race: "a vote within the district in the primary,
--     but a countywide general election vote."
--
--   Bainbridge council
--     BIMC 2.06 — three wards (North / Central / South); positions 2 and 7 are
--     North, 3 and 6 South, 4 and 5 Central, and position 1 is at large.
--     bainbridgewa.gov/219/Council-Representation — ward voters nominate in the
--     primary; in the general ALL city voters vote every position.
--
-- ⚠ READ THE ENACTED TEXT, NOT A SUMMARY. An automated read of RCW 36.32.050
-- returned the correct statutory quote and then asserted the OPPOSITE conclusion
-- from it ("district-based election only ... not county-wide"). The quoted words
-- say "elected by the qualified voters of the county". The summary was wrong and
-- the text was right, which is the whole reason the text gets quoted here.
--
-- CONSEQUENCE, if these had been wired per-district instead:
--   * a Kitsap address would return 1 of 3 commissioners, hiding two officials
--     that voter actually elects;
--   * a Bainbridge address would return 3 of 7 councilmembers;
--   * and on the ELECTIONS surface roughly two thirds of Kitsap addresses would
--     never see the Commissioner District 3 race — a countywide contest on
--     every Kitsap ballot in November 2026.
-- Attaching a seat to a polygon that does not elect it is not a display nicety.
-- It removes officials and races from voters who have them.
--
-- ⚖ This is also the CORPUS-WIDE MAJORITY, not a special case: Madison's 20
-- alders, Racine's 15, Fort Worth, Longview, McKinney, Arlington, the Tarrant and
-- Collin commissioner precincts, Multnomah, Deschutes, St. Mary's MD, Portland ME
-- and Auburn ME all attach districted seats to the whole-jurisdiction polygon.
-- Per-district polygons exist only where the district actually elects.
--
-- The three commissioner districts and three wards are still loaded, as REFERENCE
-- boundaries under mtfcc X0027 / X0028 — migration 1801 and
-- scripts/load-kitsap-bainbridge-boundaries.ts. They carry no office by design.
--
-- ============================================================================
-- !! geo_id 53035 IS NOT UNIQUE — the same trap 1744 documents for 53033
-- ============================================================================
-- 53035 is simultaneously Kitsap County (COUNTY, G4020), Legislative Senate
-- District 35 (STATE_UPPER, G5210) and Legislative House District 35
-- (STATE_LOWER, G5220). The lookup below keys on (geo_id, district_type, mtfcc).
-- A geo_id-only join returns three rows and silently attaches the Sheriff and the
-- Prosecuting Attorney to a legislative district.
--
-- ============================================================================
-- BAINBRIDGE TITLES: the position numbers were already right; the noun was not
-- ============================================================================
-- 1798 titled these "Councilmember, District 1..7". The city says POSITION, and
-- pairs each position with a ward. All seven position numbers in 1798 are
-- CORRECT against the city's own directory (verified name by name):
--   1 Hytopoulos At Large · 2 Fantroy-Johnson North · 3 Nelson South
--   4 Schneider Central · 5 Moriwaki Central · 6 Mathews South · 7 Lant North
-- which is exactly BIMC 2.06's assignment. Only the label is restated here, to
-- the city's wording and to the same shape Seattle already uses
-- ("Councilmember, Position 8 (Citywide)"). No seat, holder or term moves.
--
-- The ward each seat belongs to was already recorded in
-- offices.representation_note by 1798; the notes are restated in full below so
-- each one also carries the election method, and so the mayor / deputy-mayor
-- facts 1798 recorded are preserved rather than clobbered.
--
-- Sources read 2026-08-16:
--   app.leg.wa.gov/rcw/default.aspx?cite=36.32.040 / .050 / .052
--   bainbridgewa.gov/219/Council-Representation
--   bainbridgewa.gov/27/Government (council roster + ward per member)
--
-- Idempotency: no usable unique index for these keys, so inserts use NOT EXISTS
-- and updates are keyed on the government's own geo_id. Re-running is a no-op.

BEGIN;

-- ─── 1. Bainbridge citywide district (the polygon that actually elects) ──────
--
-- Mirrors Seattle's "Seattle Citywide (At-large)" LOCAL row on 5363000/G4110,
-- which is what Positions 8 and 9 hang off. Bainbridge has no separately elected
-- mayor (council-manager; the mayor is the council's own chair), so unlike
-- Seattle there is no companion LOCAL_EXEC row to create.

INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(),
       '5303736',
       'Bainbridge Island Citywide',
       'LOCAL',
       'wa',            -- lowercase: LOCAL-tier routing join key
       'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '5303736' AND mtfcc = 'G4110'
);

-- ─── 2. Wire the 9 Kitsap offices to the COUNTY district ─────────────────────
--
-- All nine: the six countywide row officers AND the three commissioners, for the
-- reason argued at the top. The COUNTY district row already exists (TIGER load).

UPDATE essentials.offices o
   SET district_id = d.id
  FROM essentials.districts d,
       essentials.chambers c,
       essentials.governments g
 WHERE o.chamber_id = c.id
   AND c.government_id = g.id
   AND g.geo_id = '53035'
   AND g.type = 'County'
   AND d.geo_id = '53035'
   AND d.district_type = 'COUNTY'      -- !! all three keys, see header
   AND d.mtfcc = 'G4020'
   AND o.district_id IS DISTINCT FROM d.id;

-- ─── 3. Wire the 7 Bainbridge offices to the CITYWIDE district ───────────────

UPDATE essentials.offices o
   SET district_id = d.id
  FROM essentials.districts d,
       essentials.chambers c,
       essentials.governments g
 WHERE o.chamber_id = c.id
   AND c.government_id = g.id
   AND g.geo_id = '5303736'
   AND d.geo_id = '5303736'
   AND d.district_type = 'LOCAL'
   AND d.mtfcc = 'G4110'
   AND o.district_id IS DISTINCT FROM d.id;

-- ─── 4. Kitsap commissioner notes: record the nominate/elect split ───────────

UPDATE essentials.offices o
   SET representation_note = v.note
  FROM (VALUES
    ('Commissioner, District 1',
     'District 1 is a residency and nomination district, not an election district. Under RCW 36.32.040(1) the electors of District 1 "and they only" nominate in the August primary; under RCW 36.32.050(1) the nominees are then "elected by the qualified voters of the county" in November. RCW 36.32.052 requires district-based election only of noncharter counties of 400,000 or more; Kitsap is noncharter and about 276,000. The district boundary is published as a reference geofence (mtfcc X0027).'),
    ('Commissioner, District 2',
     'District 2 is a residency and nomination district, not an election district. Under RCW 36.32.040(1) the electors of District 2 "and they only" nominate in the August primary; under RCW 36.32.050(1) the nominees are then "elected by the qualified voters of the county" in November. RCW 36.32.052 requires district-based election only of noncharter counties of 400,000 or more; Kitsap is noncharter and about 276,000. The district boundary is published as a reference geofence (mtfcc X0027).'),
    ('Commissioner, District 3',
     'District 3 is a residency and nomination district, not an election district. Under RCW 36.32.040(1) the electors of District 3 "and they only" nominate in the August primary; under RCW 36.32.050(1) the nominees are then "elected by the qualified voters of the county" in November. RCW 36.32.052 requires district-based election only of noncharter counties of 400,000 or more; Kitsap is noncharter and about 276,000. The district boundary is published as a reference geofence (mtfcc X0027).')
  ) AS v(title, note),
       essentials.chambers c,
       essentials.governments g
 WHERE o.chamber_id = c.id
   AND c.government_id = g.id
   AND g.geo_id = '53035'
   AND g.type = 'County'
   AND o.title = v.title;

-- ─── 5. Bainbridge: retitle to the city's wording + restate the notes ────────
--
-- Keyed on the OLD title, which 1798 wrote and nothing else has touched. Runs
-- once; on a re-run no row matches the old title and this is a no-op.

UPDATE essentials.offices o
   SET title = v.new_title,
       representation_note = v.note
  FROM (VALUES
    ('Councilmember, District 1', 'Councilmember, Position 1 (At Large)',
     'Elected at large by all city voters (BIMC 2.06). Council-manager city: the mayor is the council chair, chosen by and from the seven members. Kirsten Hytopoulos was chosen Deputy Mayor in January 2026 for a six-month term.'),
    ('Councilmember, District 2', 'Councilmember, Position 2 (North Ward)',
     'North Ward seat (BIMC 2.06). North Ward voters nominate in the August primary; every city voter elects the seat in the November general, so the ward is a residency and nomination district, not an election district. The ward boundary is published as a reference geofence (mtfcc X0028).'),
    ('Councilmember, District 3', 'Councilmember, Position 3 (South Ward)',
     'South Ward seat (BIMC 2.06). South Ward voters nominate in the August primary; every city voter elects the seat in the November general, so the ward is a residency and nomination district, not an election district. The ward boundary is published as a reference geofence (mtfcc X0028).'),
    ('Councilmember, District 4', 'Councilmember, Position 4 (Central Ward)',
     'Central Ward seat (BIMC 2.06). Central Ward voters nominate in the August primary; every city voter elects the seat in the November general, so the ward is a residency and nomination district, not an election district. The ward boundary is published as a reference geofence (mtfcc X0028).'),
    ('Councilmember, District 5', 'Councilmember, Position 5 (Central Ward)',
     'Central Ward seat (BIMC 2.06). Central Ward voters nominate in the August primary; every city voter elects the seat in the November general, so the ward is a residency and nomination district, not an election district. Council-manager city: the mayor is the council chair, chosen by and from the seven members. Clarence Moriwaki was chosen Mayor in January 2026 for a one-year term. There is no separately elected mayoralty.'),
    ('Councilmember, District 6', 'Councilmember, Position 6 (South Ward)',
     'South Ward seat (BIMC 2.06). South Ward voters nominate in the August primary; every city voter elects the seat in the November general, so the ward is a residency and nomination district, not an election district. The ward boundary is published as a reference geofence (mtfcc X0028).'),
    ('Councilmember, District 7', 'Councilmember, Position 7 (North Ward)',
     'North Ward seat (BIMC 2.06). North Ward voters nominate in the August primary; every city voter elects the seat in the November general, so the ward is a residency and nomination district, not an election district. The ward boundary is published as a reference geofence (mtfcc X0028).')
  ) AS v(old_title, new_title, note),
       essentials.chambers c,
       essentials.governments g
 WHERE o.chamber_id = c.id
   AND c.government_id = g.id
   AND g.geo_id = '5303736'
   AND o.title = v.old_title;

-- ─── 6. Guards ───────────────────────────────────────────────────────────────

DO $$
DECLARE
  unrouted   int;
  kitsap_n   int;
  bainb_n    int;
  bad_titles int;
BEGIN
  SELECT count(*) INTO unrouted
    FROM essentials.offices o
    JOIN essentials.chambers c   ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('53035', '5303736')
     AND o.district_id IS NULL;
  IF unrouted <> 0 THEN
    RAISE EXCEPTION 'Migration 1800: % Kitsap/Bainbridge offices still have a NULL district_id', unrouted;
  END IF;

  -- Every Kitsap office on the COUNTY row, every Bainbridge office on the
  -- citywide row. A non-zero count here would mean a seat landed on LD35.
  SELECT count(*) INTO kitsap_n
    FROM essentials.offices o
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d   ON d.id = o.district_id
   WHERE g.geo_id = '53035'
     AND d.geo_id = '53035' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020';
  IF kitsap_n <> 9 THEN
    RAISE EXCEPTION 'Migration 1800: expected 9 Kitsap offices on the COUNTY district, got %', kitsap_n;
  END IF;

  SELECT count(*) INTO bainb_n
    FROM essentials.offices o
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d   ON d.id = o.district_id
   WHERE g.geo_id = '5303736'
     AND d.geo_id = '5303736' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110';
  IF bainb_n <> 7 THEN
    RAISE EXCEPTION 'Migration 1800: expected 7 Bainbridge offices on the citywide district, got %', bainb_n;
  END IF;

  SELECT count(*) INTO bad_titles
    FROM essentials.offices o
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '5303736'
     AND o.title NOT LIKE 'Councilmember, Position %';
  IF bad_titles <> 0 THEN
    RAISE EXCEPTION 'Migration 1800: % Bainbridge offices still carry a non-Position title', bad_titles;
  END IF;
END $$;

COMMIT;
