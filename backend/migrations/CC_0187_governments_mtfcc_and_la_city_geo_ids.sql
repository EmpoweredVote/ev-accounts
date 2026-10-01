-- CC_0187 — essentials.governments gains an MTFCC discriminator, and seven LA County cities
--           get the place GEOID they were missing.
--
-- WHY THIS EXISTS
-- ---------------
-- `essentials.governments.geo_id` is a bare text column with no partner telling you WHICH
-- geography vocabulary a value is drawn from. Measured against production 2026-09-30, it already
-- mixes five of them in one namespace:
--
--     length  rows  what they are
--        2      51  states            (G4000)
--        5      83  counties          (G4020)
--        7     210  Census PLACES     (G4110)
--        7      55  school districts  (G5420)
--       10       4  county subdivs    (G4040)
--       25       1  a SLUG, not a GEOID at all — see the Bend note below
--
-- The 7-digit rows are the live hazard: a place GEOID and a unified school district GEOID are
-- both 2-digit state + 5-digit code, so they occupy the SAME value space and nothing in the row
-- says which is which. No two `governments.geo_id` values collide today — checked — but the
-- collision is not hypothetical anywhere else in this schema. In `essentials.districts`, geo_id
-- '06075' is BOTH San Francisco County (G4020) AND Assembly District 75 (G5220); 1,159 geo_id
-- collisions across 13 states are already documented, and `src/lib/geoIdGuard.ts` exists because
-- of them. The repo rule is that the key is (mtfcc, geo_id), never geo_id alone. This migration
-- makes `governments` able to honour that rule before the column grows.
--
-- HOW EACH mtfcc WAS DECIDED, AND WHAT WAS REFUSED
-- ------------------------------------------------
-- Lengths 2, 5 and 10 are unambiguous: nothing else in the column is that long.
--
-- For the 7-digit rows, the first route is evidence from `districts` — a district row carrying
-- the SAME geo_id and a Census G-code. That answers 176 of 265 (137 G4110, 39 G5420) and leaves
-- 89 with no district row to read.
--
-- The second route reads the government's own CHAMBER, which is the discriminating field: a city
-- has a City Council, a school district has a Board of Trustees or Board of Education. That
-- predicate was NOT trusted on assertion. It was run against the 176 rows whose answer is
-- already known from `districts`:
--
--     truth   predicted         rows
--     G4110   G4110              133
--     G4110   UNDECIDED            4
--     G5420   G5420               27
--     G5420   UNDECIDED           12
--
-- Zero wrong answers, and it abstains rather than guessing. Then the labels were SWAPPED as a
-- tamper control and the same comparison returned 160 WRONG — so the comparison can fail, and
-- the clean result above is a measurement rather than a detector that always says yes.
--
-- 🔴 THE REGEX WAS NOT WIDENED TO SWALLOW THE LEFTOVERS. Two rows still refuse to decide, and
-- both are findings rather than noise:
--
--   * 'City and County of San Francisco' (0667000). A consolidated city-county: its chamber is a
--     BOARD OF SUPERVISORS, which matches neither pattern. 0667000 is the Census PLACE code, so
--     G4110 is correct — but it is set below as a NAMED exception with its evidence, not by
--     loosening a pattern until the row fell in. Corroboration: production separately holds
--     San Francisco County as geo_id '06075' (G4020) and a citywide district on '0667000', and
--     San Francisco Unified holds its own 7-digit code '0634410'. Three codes, one city, all in
--     the namespace this column mixes.
--
--   * 'Bend Metro Park & Recreation District, Oregon, US' carries geo_id
--     'bend-or-park-rec-district' — a SLUG, not a GEOID. It is LEFT NULL deliberately. There is
--     no Census code to write and inventing one would be the dishonesty this schema's rules
--     exist to prevent. It is flagged here so the next reader knows the value is not a GEOID.
--
-- THE SEVEN CITIES
-- ----------------
-- Separately, 209 governments carry a NULL geo_id while holding at least one occupant. Classified
-- by CHAMBER (not by name — a name regex called 'El Monte City', 'Castaic Union' and 'Lennox'
-- cities when all three carry a Board of Trustees and are school districts), they are:
--
--     96 school / college districts · 64 cities and towns · 31 special districts
--     16 Indiana townships · 2 federal rows
--
-- Of the 64 cities and towns, 57 already resolve through the 212-06 gap closure in
-- locationSearchService.ts, which reaches a G4110/G4020 district through the government's own
-- offices. SEVEN do not, and those seven are this migration's scope. Every one of them already
-- has an authoritative G4110 polygon sitting in production, unlinked to any office — so no GEOID
-- here was typed from memory. The gate below re-reads each one from `districts` and refuses the
-- migration if the pair disagrees.
--
-- NOT IN SCOPE, on purpose: the 96 school/college districts, 31 special districts and 16
-- townships. They are a different geography vocabulary with a different key, and the townships
-- are county subdivisions (G4040), not places.

BEGIN;

-- ── 1. The discriminator ────────────────────────────────────────────────────────────────────
ALTER TABLE essentials.governments
  ADD COLUMN IF NOT EXISTS mtfcc text;

COMMENT ON COLUMN essentials.governments.mtfcc IS
  'Census MTFCC naming which geography vocabulary geo_id is drawn from. The key is '
  '(mtfcc, geo_id) — geo_id alone is ambiguous, because a 7-digit place code (G4110) and a '
  '7-digit unified school district code (G5420) share one value space. NULL means the geo_id '
  'is not a Census identifier (one row holds a slug) or its vocabulary is not yet evidenced; '
  'NULL is the honest value, never a guess. Added by CC_0187.';

-- ── 2. Backfill by length, where length is unambiguous ──────────────────────────────────────
UPDATE essentials.governments SET mtfcc = 'G4000'
 WHERE geo_id IS NOT NULL AND mtfcc IS NULL AND length(geo_id) = 2;

UPDATE essentials.governments SET mtfcc = 'G4020'
 WHERE geo_id IS NOT NULL AND mtfcc IS NULL AND length(geo_id) = 5;

UPDATE essentials.governments SET mtfcc = 'G4040'
 WHERE geo_id IS NOT NULL AND mtfcc IS NULL AND length(geo_id) = 10;

-- ── 3. Backfill 7-digit rows from a district carrying the SAME geo_id ───────────────────────
-- Evidence first: where production already states the vocabulary, read it rather than infer it.
UPDATE essentials.governments g SET mtfcc = sub.mtfcc
  FROM (
    SELECT gg.id, min(d.mtfcc) AS mtfcc
      FROM essentials.governments gg
      JOIN essentials.districts d ON d.geo_id = gg.geo_id AND d.mtfcc IN ('G4110', 'G5420')
     WHERE gg.geo_id IS NOT NULL AND gg.mtfcc IS NULL AND length(gg.geo_id) = 7
     GROUP BY gg.id
    HAVING count(DISTINCT d.mtfcc) = 1      -- refuse a row that two vocabularies both claim
  ) sub
 WHERE g.id = sub.id AND g.mtfcc IS NULL;

-- ── 4. Backfill the remainder from the government's own chamber ─────────────────────────────
-- Validated against the 176 rows answered by step 3: 160 decided, 0 wrong, 16 abstained; the
-- swapped-label tamper returned 160 wrong, so the comparison is capable of failing.
UPDATE essentials.governments g SET mtfcc = 'G4110'
 WHERE g.geo_id IS NOT NULL AND g.mtfcc IS NULL AND length(g.geo_id) = 7
   AND EXISTS (
     SELECT 1 FROM essentials.chambers c
      WHERE c.government_id = g.id
        AND c.name ~* '(city council|town council|board of aldermen|village board|common council|city commission)'
   );

UPDATE essentials.governments g SET mtfcc = 'G5420'
 WHERE g.geo_id IS NOT NULL AND g.mtfcc IS NULL AND length(g.geo_id) = 7
   AND EXISTS (
     SELECT 1 FROM essentials.chambers c
      WHERE c.government_id = g.id
        AND c.name ~* '(board of trustees|board of education|school board|governing board)'
   );

-- ── 5. San Francisco, as a named exception with its reasoning ───────────────────────────────
-- A consolidated city-county. 0667000 is the Census PLACE code; the county-equivalent code
-- 06075 is held separately by a G4020 district. Set explicitly so the exception is auditable,
-- rather than by widening step 4's pattern.
UPDATE essentials.governments
   SET mtfcc = 'G4110'
 WHERE name = 'City and County of San Francisco'
   AND geo_id = '0667000'
   AND mtfcc IS NULL;

-- ── 6. The seven LA County cities ───────────────────────────────────────────────────────────
-- Each geo_id is the one production already carries on that city's G4110 district. The gate
-- re-reads every pair from `districts`; a typo cannot survive it.
UPDATE essentials.governments g
   SET geo_id = v.geo_id, mtfcc = 'G4110'
  FROM (VALUES
    ('City of Arcadia, California, US',        '0602462'),
    ('City of Claremont, California, US',      '0613756'),
    ('City of Diamond Bar, California, US',    '0619192'),
    ('City of Duarte, California, US',         '0619990'),
    ('City of Glendora, California, US',       '0630014'),
    ('City of La Verne, California, US',       '0640830'),
    ('City of South Pasadena, California, US', '0673220')
  ) AS v(name, geo_id)
 WHERE g.name = v.name
   AND g.geo_id IS NULL;

-- ── 7. Make (mtfcc, geo_id) structural ──────────────────────────────────────────────────────
-- Two governments sharing a vocabulary AND a code are the same government twice. Partial, so
-- the many NULL-geo_id rows are unaffected.
CREATE UNIQUE INDEX IF NOT EXISTS governments_mtfcc_geo_id_key
  ON essentials.governments (mtfcc, geo_id)
  WHERE mtfcc IS NOT NULL AND geo_id IS NOT NULL;

-- ── 8. Post-verify ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n     bigint;
  v_name  text;
  v_geo   text;
BEGIN
  -- the column exists and is text
  SELECT count(*) INTO v_n FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'governments'
     AND column_name = 'mtfcc' AND data_type = 'text';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: essentials.governments.mtfcc is missing or not text'; END IF;

  -- every geo_id-bearing row is classified EXCEPT the one that holds a slug
  SELECT count(*) INTO v_n FROM essentials.governments
   WHERE geo_id IS NOT NULL AND mtfcc IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'POST: % geo_id-bearing rows carry no mtfcc, expected exactly 1 (Bend, which holds a slug)', v_n;
  END IF;

  SELECT name INTO v_name FROM essentials.governments
   WHERE geo_id IS NOT NULL AND mtfcc IS NULL;
  IF v_name <> 'Bend Metro Park & Recreation District, Oregon, US' THEN
    RAISE EXCEPTION 'POST: the unclassified row is "%", not the expected Bend slug row — read it before proceeding', v_name;
  END IF;

  -- no row was classified by length alone into a vocabulary of the wrong width
  SELECT count(*) INTO v_n FROM essentials.governments
   WHERE mtfcc IS NOT NULL AND geo_id IS NOT NULL
     AND NOT ( (mtfcc = 'G4000' AND length(geo_id) = 2)
            OR (mtfcc = 'G4020' AND length(geo_id) = 5)
            OR (mtfcc = 'G4040' AND length(geo_id) = 10)
            OR (mtfcc IN ('G4110', 'G5420') AND length(geo_id) = 7) );
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % row(s) carry an mtfcc whose code width does not match geo_id', v_n; END IF;

  -- NEGATIVE CONTROL on the step-4 predicate: no row may be labelled a place while its only
  -- chamber is a school board, nor the reverse. This is the tamper, asserted as an invariant.
  SELECT count(*) INTO v_n FROM essentials.governments g
   WHERE g.mtfcc = 'G4110'
     AND EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id
                  AND c.name ~* '(board of trustees|board of education|school board)')
     AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id
                  AND c.name ~* '(city council|town council|board of aldermen|village board|common council|city commission|board of supervisors)');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % government(s) labelled G4110 have only a school board', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.governments g
   WHERE g.mtfcc = 'G5420'
     AND EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id
                  AND c.name ~* '(city council|town council|common council)');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % government(s) labelled G5420 have a city council', v_n; END IF;

  -- San Francisco took the named exception
  SELECT count(*) INTO v_n FROM essentials.governments
   WHERE name = 'City and County of San Francisco' AND geo_id = '0667000' AND mtfcc = 'G4110';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: San Francisco is not classified G4110 on 0667000'; END IF;

  -- the seven cities: each now carries a geo_id, and that geo_id is the one production's own
  -- G4110 district carries for that city. A transposed digit fails HERE, not in a landing page.
  FOR v_name, v_geo IN
    SELECT * FROM (VALUES
      ('City of Arcadia, California, US',        'Arcadia'),
      ('City of Claremont, California, US',      'Claremont'),
      ('City of Diamond Bar, California, US',    'Diamond Bar'),
      ('City of Duarte, California, US',         'Duarte'),
      ('City of Glendora, California, US',       'Glendora'),
      ('City of La Verne, California, US',       'La Verne'),
      ('City of South Pasadena, California, US', 'South Pasadena')
    ) AS t(gov_name, city)
  LOOP
    SELECT count(*) INTO v_n
      FROM essentials.governments g
      JOIN essentials.districts d
        ON d.geo_id = g.geo_id AND d.mtfcc = 'G4110' AND lower(d.state) = 'ca'
     WHERE g.name = v_name
       AND g.mtfcc = 'G4110'
       AND d.label ILIKE v_geo || ' %';
    IF v_n < 1 THEN
      RAISE EXCEPTION 'POST: % has no geo_id matching a CA G4110 district labelled "% ..."', v_name, v_geo;
    END IF;
  END LOOP;

  -- and all seven actually moved off NULL
  SELECT count(*) INTO v_n FROM essentials.governments
   WHERE name IN ('City of Arcadia, California, US', 'City of Claremont, California, US',
                  'City of Diamond Bar, California, US', 'City of Duarte, California, US',
                  'City of Glendora, California, US', 'City of La Verne, California, US',
                  'City of South Pasadena, California, US')
     AND geo_id IS NOT NULL AND mtfcc = 'G4110';
  IF v_n <> 7 THEN RAISE EXCEPTION 'POST: % of 7 LA County cities carry a place geo_id, expected 7', v_n; END IF;

  -- the uniqueness the column now claims actually holds
  SELECT count(*) INTO v_n FROM (
    SELECT mtfcc, geo_id FROM essentials.governments
     WHERE mtfcc IS NOT NULL AND geo_id IS NOT NULL
     GROUP BY mtfcc, geo_id HAVING count(*) > 1
  ) dupes;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % (mtfcc, geo_id) pair(s) are held by more than one government', v_n; END IF;

  RAISE NOTICE 'CC_0187 OK: mtfcc backfilled, 1 slug row left NULL by design, 7 LA County cities seated on their place GEOID.';
END $$;

COMMIT;
