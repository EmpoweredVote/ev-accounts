-- CC_0138_mi_legislature_structure.sql
-- Knight Foundation program, wave MI-2 (structure half). Slot RESERVED from the allocator.
--
-- Michigan has NO state legislative offices and NO legislative chambers today: production holds
-- 4 Michigan state offices in total, all statewide executives (Governor, Lieutenant Governor,
-- Secretary of State, Attorney General), plus 13 U.S. House and 2 U.S. Senate seats on the
-- federal government row.
-- ⚠ AND FOUR MORE ROWS UNDER 'U.S. Senate' ARE CANDIDATE OFFICES, NOT SENATORS — Michigan shows
-- 6 rows on that chamber for a 2-senator state. The extra four are titled
-- 'Candidate for U.S. Senate — Michigan'. This is the Sherrod Brown trap from OH-2, recurring.
-- Nothing here counts them.
--
-- MI-1 loaded the geography (110 STATE_LOWER + 38 STATE_UPPER, vintage PROVEN SEPARATELY PER
-- CHAMBER against the State of Michigan's own layers), so this migration is a clean seed with
-- nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 148 offices, one per district MI-1 loaded.
--
-- Creates NO people and NO terms -- CC_0139 does that, and the two are applied back to back.
--
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. Senate District 31 is '26031'
-- and House District 71 is '26071', while Michigan's 83 COUNTY districts occupy '26001'..'26165'.
-- All 38 Senate geo_ids are also a county's. Wayne County -- Detroit's parent and this slice's
-- own jurisdiction -- is '26163', outside the legislative range, but that is luck, not a reason
-- to match on a number. The gate below asserts no county district took a legislative office.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Michigan' row, a9c12923-c03c-407d-8b4f-30e4beca3d3f (type STATE, state MI, geo_id 26).
-- Indiana's 18 indistinguishable government rows do NOT recur here, and the gate asserts it.
--
-- 🟢 THERE ARE NO VACANCIES. All 148 seats are filled -- unlike OH-2 (two vacant) and MN-2 (one).
-- That was not assumed from a count: the House's own roster lists only 109 of 110 districts, and
-- 58 R + 51 D = 109 looks exactly like a one-seat vacancy.
-- 🔴🔴 IT IS NOT A VACANCY, AND SEATING IT AS ONE WOULD HAVE DELETED A SITTING MEMBER FROM EVERY
-- ADDRESS IN HER DISTRICT. house.mi.gov/AllRepresentatives is the UNION OF THE TWO CAUCUS
-- WEBSITES -- every row links to gophouse.org or housedems.com. Karen Whitsett (HD-4, Detroit)
-- announced in March 2026 that she was leaving the Democratic Party and would not seek
-- re-election; she holds the seat until the term ends 2026-12-31. Belonging to neither caucus,
-- she has no row to render. The Legislature's OWN list, which is not a caucus list, carries her,
-- and so does Open States.
-- ▶ AN ABSENCE ON A CHAMBER'S OWN ROSTER IS NOT A VACANCY. Ask what the roster is ASSEMBLED FROM.
--
-- 🔴 PARTY IS NOT WRITTEN. All four sources carry it; party lives on races.primary_party.
-- ⚠ Open States still lists Whitsett as a Democrat six months after she left the party, which is
-- one more reason not to read party from a roster.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: Mich. Const. art. IV, s 3 -- Representatives two years, Senators four.
-- official_count: 110 and 38, fixed by Mich. Const. art. IV, s 2 and s 3, and equal to the
-- polygon counts MI-1 loaded because Michigan is single-member in both chambers.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'a9c12923-c03c-407d-8b4f-30e4beca3d3f', $$Michigan House of Representatives$$, $$Michigan House of Representatives$$, 110, $$2$$
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f' AND name = $$Michigan House of Representatives$$);

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'a9c12923-c03c-407d-8b4f-30e4beca3d3f', $$Michigan Senate$$, $$Michigan Senate$$, 38, $$4$$
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f' AND name = $$Michigan Senate$$);

-- ─── 2. The 148 offices, one per district MI-1 loaded ─────────────────────────
-- Guarded on district_id: Michigan has no legislative office at all today, so this inserts 148
-- on a first run and 0 on any re-run. Every row is is_vacant false -- Michigan has no vacancy.

CREATE TEMP TABLE mi_offices(geo_id text, district_type text, chamber_name text, title text) ON COMMIT DROP;

INSERT INTO mi_offices(geo_id, district_type, chamber_name, title) VALUES
  ($$26001$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26002$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26003$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26004$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26005$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26006$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26007$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26008$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26009$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26010$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26011$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26012$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26013$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26014$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26015$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26016$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26017$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26018$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26019$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26020$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26021$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26022$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26023$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26024$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26025$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26026$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26027$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26028$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26029$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26030$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26031$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26032$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26033$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26034$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26035$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26036$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26037$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26038$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26039$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26040$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26041$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26042$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26043$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26044$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26045$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26046$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26047$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26048$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26049$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26050$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26051$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26052$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26053$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26054$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26055$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26056$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26057$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26058$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26059$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26060$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26061$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26062$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26063$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26064$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26065$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26066$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26067$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26068$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26069$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26070$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26071$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26072$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26073$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26074$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26075$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26076$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26077$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26078$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26079$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26080$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26081$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26082$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26083$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26084$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26085$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26086$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26087$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26088$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26089$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26090$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26091$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26092$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26093$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26094$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26095$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26096$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26097$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26098$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26099$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26100$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26101$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26102$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26103$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26104$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26105$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26106$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26107$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26108$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26109$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26110$$, $$STATE_LOWER$$, $$Michigan House of Representatives$$, $$Representative$$),
  ($$26001$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26002$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26003$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26004$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26005$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26006$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26007$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26008$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26009$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26010$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26011$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26012$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26013$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26014$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26015$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26016$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26017$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26018$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26019$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26020$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26021$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26022$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26023$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26024$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26025$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26026$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26027$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26028$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26029$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26030$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26031$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26032$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26033$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26034$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26035$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26036$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26037$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$),
  ($$26038$$, $$STATE_UPPER$$, $$Michigan Senate$$, $$Senator$$);

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, m.title, 'MI', 1, false, 'full'
FROM mi_offices m
JOIN essentials.districts d
  ON d.geo_id = m.geo_id AND d.district_type::text = m.district_type AND lower(d.state) = 'mi'
JOIN essentials.chambers c
  ON c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f' AND c.name = m.chamber_name
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── post-verify gate ─────────────────────────────────────────────────────────
DO $gate$
DECLARE
  v_gov      integer;
  v_chambers integer;
  v_lower    integer;
  v_upper    integer;
  v_vacant   integer;
  v_county   integer;
  v_nulldist integer;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'State of Michigan' AND type = 'STATE';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'MI-2 gate 1: expected exactly 1 "State of Michigan" government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_chambers FROM essentials.chambers
   WHERE government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$);
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'MI-2 gate 2: expected 2 legislative chambers, found %', v_chambers;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER'),
         count(*) FILTER (WHERE o.is_vacant)
    INTO v_lower, v_upper, v_vacant
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND c.name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$);

  IF v_lower <> 110 OR v_upper <> 38 THEN
    RAISE EXCEPTION 'MI-2 gate 3: expected 110 House and 38 Senate offices, found % and %', v_lower, v_upper;
  END IF;
  -- Michigan has no vacancy. If a later wave creates one this gate must be revisited, not relaxed.
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 4: expected 0 vacant offices, found %', v_vacant;
  END IF;

  -- The (geo_id, district_type) key: no COUNTY district may have taken a legislative office.
  SELECT count(*) INTO v_county
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND c.name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$)
     AND d.mtfcc NOT IN ('G5210', 'G5220');
  IF v_county <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 5: % legislative office(s) landed on a non-legislative district — the geo_id/county collision', v_county;
  END IF;

  SELECT count(*) INTO v_nulldist
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = 'a9c12923-c03c-407d-8b4f-30e4beca3d3f'
     AND c.name IN ($$Michigan House of Representatives$$, $$Michigan Senate$$)
     AND o.district_id IS NULL;
  IF v_nulldist <> 0 THEN
    RAISE EXCEPTION 'MI-2 gate 6: % legislative office(s) have no district — unreachable by address', v_nulldist;
  END IF;

  RAISE NOTICE 'CC_0138 OK: 2 chambers, 110 House + 38 Senate offices, 0 vacant, 0 on a county district.';
END
$gate$;

COMMIT;
