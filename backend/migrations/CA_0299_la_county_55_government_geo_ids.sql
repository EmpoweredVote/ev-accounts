-- CA_0299_la_county_55_government_geo_ids.sql
-- Slot CA_0299 RESERVED from the allocator (steward.mjs slot CA).
--
-- Sets essentials.governments.geo_id on FIFTY-FIVE Los Angeles-area city governments that are
-- seeded, occupied and unreachable from any browse URL. Creates NO people, NO terms, NO districts,
-- NO chambers and NO offices. Touches exactly one column on exactly 55 rows.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE DEFECT, AND WHY IT IS INVISIBLE. This is the same defect CC_0183 fixed for Wichita,
-- Lexington, St. Louis and Bloomington, at larger scale. An Essentials landing-page chip is a row
-- in the frontend's src/lib/coverage.js carrying browseGovernmentList: ['<geo_id>'], resolved by
-- essentialsBrowseService.getPoliticiansByGovernmentList with
--
--     FROM essentials.governments g JOIN essentials.chambers ch ON ch.government_id = g.id
--     JOIN essentials.offices o ON o.chamber_id = ch.id ...
--     WHERE g.geo_id = ANY($1)
--
-- so a government with a NULL geo_id CANNOT BE NAMED BY ANY BROWSE URL. Nothing errors and no gate
-- fires. Address search keeps working perfectly, because it goes districts -> offices ->
-- office_current_holder and never touches essentials.governments at all. That is exactly why this
-- survived: all 55 answer an address today, and 261 sitting officials are reachable that way and
-- only that way.
--
-- Measured against production 2026-10-06: 55 city governments, 261 seated officials, 0 stance rows.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 HOW EVERY geo_id BELOW WAS OBTAINED. Not composed from a name, and not looked up in an
-- external gazetteer. Each one is read out of the government's OWN WIRING:
--
--     governments -> chambers -> offices -> districts (mtfcc = 'G4110')
--       joined to essentials.geofence_boundaries ON (geo_id, mtfcc)
--
-- i.e. the place code already attached to that city's own offices, and only where that code carries
-- a real polygon. This is the CC_0183 rule ("verified against a district that exists in production
-- and carries a polygon") applied to all 55.
--
-- Four gates were measured before this file was written, all clean:
--   * all 55 have a G4110 place district AND that district has a polygon  (55/55)
--   * the mapping is 1:1 — no city resolves to two codes, no code is claimed by two cities
--   * zero collisions against any existing governments.geo_id
--   * an INDEPENDENT cross-check against geofence_boundaries.name (TIGER's own label, not our
--     wiring) agrees on 55 of 55. The single apparent mismatch is
--     'City of La Canada Flintridge' vs TIGER 'La Cañada Flintridge city' — a diacritic, not a
--     disagreement. It is called out here so the next reader does not re-investigate it.
--
-- ⚠ DOWNSTREAM, NOT FIXED HERE (frontend): once these cities carry chips, the label
-- "South El Monte" resolves to cities/el-monte.jpg, because CURATED_LOCAL matches by SUBSTRING and
-- 'el monte' is a key. That publishes El Monte's photographer against another city and is fixed in
-- essentials by putting match:'exact' on the 'el monte' entry. It is a frontend change and has no
-- bearing on this migration; recorded so the two are not separated.
--
-- Idempotent: the UPDATE is value-guarded (geo_id IS NULL), so a row that already carries a geo_id
-- is never overwritten and re-running is a no-op. Ends with a post-verify gate that RAISEs.
--
-- No migration runner exists in this repo; this file records SQL applied by hand via
-- mcp__supabase-local__execute_sql as the postgres role.

CREATE TEMP TABLE gov_fix(name text, geo_id text) ON COMMIT DROP;

INSERT INTO gov_fix VALUES
    ('City of Agoura Hills, California, US', '0600394'),
    ('City of Artesia, California, US', '0602896'),
    ('City of Avalon, California, US', '0603274'),
    ('City of Azusa, California, US', '0603386'),
    ('City of Baldwin Park, California, US', '0603666'),
    ('City of Bell Gardens, California, US', '0604996'),
    ('City of Bell, California, US', '0604870'),
    ('City of Bradbury, California, US', '0607946'),
    ('City of Calabasas, California, US', '0609598'),
    ('City of Cerritos, California, US', '0612552'),
    ('City of Commerce, California, US', '0614974'),
    ('City of Covina, California, US', '0616742'),
    ('City of Cudahy, California, US', '0617498'),
    ('City of Hawaiian Gardens, California, US', '0632506'),
    ('City of Hermosa Beach, California, US', '0633364'),
    ('City of Hidden Hills, California, US', '0633518'),
    ('City of Huntington Beach, California, US', '0636000'),
    ('City of Industry, California, US', '0636490'),
    ('City of Irwindale, California, US', '0636826'),
    ('City of La Canada Flintridge, California, US', '0639003'),
    ('City of La Habra Heights, California, US', '0639304'),
    ('City of La Mirada, California, US', '0640032'),
    ('City of La Palma, California, US', '0640256'),
    ('City of La Puente, California, US', '0640340'),
    ('City of Lakewood, California, US', '0639892'),
    ('City of Lawndale, California, US', '0640886'),
    ('City of Lomita, California, US', '0642468'),
    ('City of Los Alamitos, California, US', '0643224'),
    ('City of Lynwood, California, US', '0644574'),
    ('City of Malibu, California, US', '0645246'),
    ('City of Manhattan Beach, California, US', '0645400'),
    ('City of Maywood, California, US', '0646492'),
    ('City of Monrovia, California, US', '0648648'),
    ('City of Montebello, California, US', '0648816'),
    ('City of Monterey Park, California, US', '0648914'),
    ('City of Palos Verdes Estates, California, US', '0655380'),
    ('City of Paramount, California, US', '0655618'),
    ('City of Pico Rivera, California, US', '0656924'),
    ('City of Rancho Palos Verdes, California, US', '0659514'),
    ('City of Redondo Beach, California, US', '0660018'),
    ('City of Rolling Hills Estates, California, US', '0662644'),
    ('City of Rolling Hills, California, US', '0662602'),
    ('City of Rosemead, California, US', '0662896'),
    ('City of San Dimas, California, US', '0666070'),
    ('City of San Fernando, California, US', '0666140'),
    ('City of San Gabriel, California, US', '0667042'),
    ('City of San Marino, California, US', '0668224'),
    ('City of Santa Fe Springs, California, US', '0669154'),
    ('City of Sierra Madre, California, US', '0671806'),
    ('City of Signal Hill, California, US', '0671876'),
    ('City of South El Monte, California, US', '0672996'),
    ('City of Temple City, California, US', '0678148'),
    ('City of Vernon, California, US', '0682422'),
    ('City of Walnut, California, US', '0683332'),
    ('City of Westlake Village, California, US', '0684438');

-- ─── 1. Pre-flight: the name must name exactly one row ────────────────────────
-- 🔴 The UPDATE joins on name. If any label matched two governments it would write the same
-- place code onto both, which is the one way this file could create a duplicate. Refuse first.
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad FROM gov_fix f
   WHERE (SELECT count(*) FROM essentials.governments g WHERE g.name = f.name) <> 1;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CA_0299 pre-flight: % name(s) do not match exactly one government row', v_bad;
  END IF;
END $$;

-- ─── 2. The write ─────────────────────────────────────────────────────────────
UPDATE essentials.governments g
   SET geo_id = f.geo_id
  FROM gov_fix f
 WHERE g.name = f.name
   AND g.geo_id IS NULL;

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  r record;
  v_dupe int; v_reach int; v_browse int; v_nonca int;
BEGIN
  -- 1. Every one of the 55 carries exactly the geo_id it was verified against.
  FOR r IN SELECT * FROM gov_fix LOOP
    PERFORM 1 FROM essentials.governments g WHERE g.name = r.name AND g.geo_id = r.geo_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'CA_0299 gate: % does not carry geo_id % — it has %',
        r.name, r.geo_id,
        coalesce((SELECT geo_id FROM essentials.governments WHERE name = r.name), 'NULL (or no such row)');
    END IF;
  END LOOP;

  -- 2. 🔴 Every geo_id written must name a district that actually exists WITH A POLYGON, or the
  -- chip would resolve to a government whose ground is not in the database.
  SELECT count(*) INTO v_reach FROM gov_fix f
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.districts d
      JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
     WHERE d.geo_id = f.geo_id);
  IF v_reach <> 0 THEN
    RAISE EXCEPTION 'CA_0299 gate: % geo_id(s) name no district with a polygon', v_reach;
  END IF;

  -- 3. 🔴 geo_id must stay unique across the WHOLE table, not just among these 55.
  SELECT count(*) INTO v_dupe FROM (
    SELECT geo_id FROM essentials.governments WHERE geo_id IS NOT NULL
     GROUP BY geo_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'CA_0299 gate: % government geo_id(s) are now shared by more than one row', v_dupe;
  END IF;

  -- 4. 🔴 Nothing outside California may have been touched. Every label here ends in
  -- ', California, US', but the gate asserts the outcome rather than trusting the string.
  SELECT count(*) INTO v_nonca FROM essentials.governments g
    JOIN gov_fix f ON f.name = g.name
   WHERE g.state IS DISTINCT FROM 'CA';
  IF v_nonca <> 0 THEN
    RAISE EXCEPTION 'CA_0299 gate: % updated government(s) are not in CA', v_nonca;
  END IF;

  -- 5. 🔴🔴 THE POINT OF THE MIGRATION. Each of the 55 must now be reachable through the REAL
  -- browse join the frontend uses — governments -> chambers -> offices -> a seated holder.
  -- Writing the column is not the deliverable; being nameable by a browse URL is.
  SELECT count(*) INTO v_browse FROM gov_fix f
   WHERE NOT EXISTS (
     SELECT 1
       FROM essentials.governments g
       JOIN essentials.chambers ch ON ch.government_id = g.id
       JOIN essentials.offices o   ON o.chamber_id = ch.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
      WHERE g.geo_id = f.geo_id
        AND och.politician_id IS NOT NULL);
  IF v_browse <> 0 THEN
    RAISE EXCEPTION 'CA_0299 gate: % of the 55 still resolve to no seated official via the browse join', v_browse;
  END IF;

  RAISE NOTICE 'CA_0299 OK: 55 governments carry a polygon-backed place code and all 55 answer the browse join';
END $$;
