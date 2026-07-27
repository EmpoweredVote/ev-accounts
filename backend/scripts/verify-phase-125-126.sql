-- verify-phase-125-126.sql
-- Consolidated phase gate for v2.15 (National House Rep Seeding, Tier 1).
-- Labeled assertions for USHR-01..05. Read-only; RAISE EXCEPTION on failure, RAISE NOTICE on pass.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-125-126.sql
--
-- Batch = the Phase 125 seeded House reps: external_id BETWEEN -56999 AND -1000 AND created_at
-- before 2026-07-01. The created_at half was added 2026-07-26 — the raw band alone had grown from
-- 299 to 372 as later phases seeded into it, silently broadening USHR-01b/02a/03/04. The batch is
-- now materialised ONCE into the _v215_batch temp table; see the BATCH DEFINITION block below.
--
-- Known unlinked NATIONAL_LOWER districts (all four are genuine vacancies, each flagged
-- offices.is_vacant = true): 0614 (CA-14, vacant since 2026-04-14), 1220 (FL-20), 1313 (GA-13),
-- 4823 (TX-23).
--
-- UPDATED 2026-07-26. This list previously read "1198 (dup DC delegate, seeded under dc-prefixed
-- geoid), 1220, 1313, 4823". That header was the only place the duplicate DC delegate district was
-- ever written down, and allowlisting it here is why it survived: nobody connected "dup DC
-- delegate" to the fact that DC's polygon lived on 1198 while Norton lived on dc-national-lower,
-- so no DC address could resolve a House delegate. Migration 1479 merged the two rows onto 1198,
-- so 1198 is now LINKED and drops off this list. 0614 takes its place — CA-14 went vacant on
-- 2026-04-14, after v2.15 was written.
--
-- Occupancy throughout resolves via essentials.office_current_holder: ADR 0002 phase 5 /
-- migration 1463 dropped essentials.offices.politician_id, which had left this gate broken at
-- runtime (42703) independently of the DC issue.

-- ===== USHR-01 (a): coverage — only the 4 known districts remain unlinked =====
DO $$
DECLARE v_unlinked INT; v_unexpected INT;
BEGIN
  -- Occupancy resolves through essentials.office_current_holder (ADR 0002 phase 5 / mig 1463
  -- dropped essentials.offices.politician_id). "Unlinked" = the district has no office carrying a
  -- current holder.
  SELECT COUNT(*) INTO v_unlinked FROM (
    SELECT d.id
    FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE d.district_type='NATIONAL_LOWER'
    GROUP BY d.id HAVING COUNT(och.politician_id) = 0
  ) q;
  IF v_unlinked <> 4 THEN
    RAISE EXCEPTION 'USHR-01a FAILED: expected 4 unlinked NATIONAL_LOWER districts, found %', v_unlinked;
  END IF;
  SELECT COUNT(*) INTO v_unexpected FROM (
    SELECT d.tiger_geoid
    FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE d.district_type='NATIONAL_LOWER'
    GROUP BY d.id, d.tiger_geoid HAVING COUNT(och.politician_id) = 0
  ) q
  WHERE q.tiger_geoid NOT IN ('0614','1220','1313','4823');
  IF v_unexpected <> 0 THEN
    RAISE EXCEPTION 'USHR-01a FAILED: % unlinked district(s) outside the known vacancy set (0614/1220/1313/4823)', v_unexpected;
  END IF;
  RAISE NOTICE 'USHR-01a PASS: exactly the 4 known districts unlinked, all genuine vacancies (CA-14/FL-20/GA-13/TX-23)';
END $$;

-- ===== BATCH DEFINITION — the v2.15 Phase 125 seeding run =====
--
-- The raw external_id band -56999..-1000 is NO LONGER the batch. It held exactly the 299 v2.15
-- reps when this gate was written; it now holds 372, because later phases seeded into the same
-- range. That is the band-pollution trap CLAUDE.md warns about ("new external_id bands can be
-- POLLUTED -> scope via race_candidates joins, not raw band"), and it silently broadened every
-- band-scoped assertion below — USHR-01b, 02a, 03 and 04 were all measuring 372 rows, not 299.
--
-- created_at separates them cleanly. Distribution across the band:
--     2026-06-16 → 299   ← the Phase 125 run, this batch
--     2026-07-03 →  32
--     2026-07-05 →  21
--     2026-07-07 →  20
-- A 17-day gap sits between the batch and the next seeding, so the cutoff below is nowhere near a
-- boundary and cannot be shifted by session timezone. It is written as a timestamptz comparison
-- rather than created_at::date = '2026-06-16' for exactly that reason.
--
-- created_at is the ONLY discriminator available: `source` and `data_source` are NULL/empty for
-- all 372 rows, so there is no provenance column to key on.
--
-- Defining the batch once, here, is deliberate. Repeating the predicate at each of the seven call
-- sites is how the drift went unnoticed in the first place.
--
-- Plain TEMP (no ON COMMIT DROP): these are separate top-level statements, so in autocommit each
-- one is its own transaction and ON COMMIT DROP would destroy the table before the next block.
-- Session-scoped is correct; the DROP IF EXISTS makes a re-run in one psql session safe.
DROP TABLE IF EXISTS _v215_batch;
CREATE TEMP TABLE _v215_batch AS
SELECT id, external_id, party, photo_origin_url, office_id, created_at
FROM essentials.politicians
WHERE external_id BETWEEN -56999 AND -1000
  AND created_at < TIMESTAMPTZ '2026-07-01';

-- ===== USHR-01 (b): batch size = 299 =====
DO $$
DECLARE v INT; v_band INT;
BEGIN
  SELECT COUNT(*) INTO v FROM _v215_batch;
  SELECT COUNT(*) INTO v_band FROM essentials.politicians WHERE external_id BETWEEN -56999 AND -1000;
  IF v <> 299 THEN RAISE EXCEPTION 'USHR-01b FAILED: expected 299 batch reps, found % (raw band holds %)', v, v_band; END IF;
  RAISE NOTICE 'USHR-01b PASS: 299 batch House reps seeded (raw band now holds % — % seeded by later phases, correctly excluded)', v_band, v_band - v;
END $$;

-- ===== USHR-02 (a): no orphan politicians (every batch rep has an office) =====
DO $$
DECLARE v INT;
BEGIN
  -- "Has an office" now means "is the current holder of one" (ADR 0002). The legacy
  -- politicians.office_id snapshot still exists but CLAUDE.md says not to read it in new code —
  -- it is point-in-time and carries the same flaw the dropped offices.politician_id did.
  SELECT COUNT(*) INTO v FROM _v215_batch b
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = b.id);
  IF v <> 0 THEN RAISE EXCEPTION 'USHR-02a FAILED: % orphan batch politicians (hold no office)', v; END IF;
  RAISE NOTICE 'USHR-02a PASS: 0 orphan batch politicians — all 299 are current officeholders';
END $$;

-- ===== USHR-02 (b): pre-existing states untouched (CA=52, VA=11, MA=9) =====
-- CA corrected 53 -> 52 on 2026-07-26. California has had 52 House seats since the 2020 census
-- reapportionment (effective 2022); 53 was its pre-2022 count. Verified this is the database being
-- right rather than the expectation being loosened: nationally there are exactly 435 state
-- NATIONAL_LOWER districts + 1 DC = 436, and the four largest delegations are CA 52 / TX 38 /
-- FL 28 / NY 26 — the 2020 apportionment exactly. Every CA district has exactly 1 office.
-- Counting offices (not holders) keeps this stable across vacancies: CA-14 is currently vacant,
-- so CA has 52 offices but only 51 current holders.
DO $$
DECLARE v_ca INT; v_va INT; v_ma INT;
BEGIN
  SELECT COUNT(*) INTO v_ca FROM essentials.districts d JOIN essentials.offices o ON o.district_id=d.id
   WHERE d.district_type='NATIONAL_LOWER' AND LEFT(d.tiger_geoid,2)='06';
  SELECT COUNT(*) INTO v_va FROM essentials.districts d JOIN essentials.offices o ON o.district_id=d.id
   WHERE d.district_type='NATIONAL_LOWER' AND LEFT(d.tiger_geoid,2)='51';
  SELECT COUNT(*) INTO v_ma FROM essentials.districts d JOIN essentials.offices o ON o.district_id=d.id
   WHERE d.district_type='NATIONAL_LOWER' AND LEFT(d.tiger_geoid,2)='25';
  IF v_ca <> 52 OR v_va <> 11 OR v_ma <> 9 THEN
    RAISE EXCEPTION 'USHR-02b FAILED: CA=% (exp 52), VA=% (exp 11), MA=% (exp 9)', v_ca, v_va, v_ma;
  END IF;
  RAISE NOTICE 'USHR-02b PASS: CA=52, VA=11, MA=9 (pre-existing untouched)';
END $$;

-- ===== USHR-03: party normalization =====
DO $$
DECLARE v_dem INT; v_bad INT;
BEGIN
  SELECT COUNT(*) INTO v_dem FROM _v215_batch WHERE party='Democrat';
  IF v_dem <> 0 THEN RAISE EXCEPTION 'USHR-03 FAILED: % batch reps with party=''Democrat''', v_dem; END IF;
  SELECT COUNT(*) INTO v_bad FROM _v215_batch
   WHERE party NOT IN ('Democratic','Republican','Independent');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'USHR-03 FAILED: % batch reps with unexpected party value', v_bad; END IF;
  RAISE NOTICE 'USHR-03 PASS: 0 ''Democrat'' rows; all batch parties in (Democratic,Republican,Independent)';
END $$;

-- ===== USHR-04: every batch rep has a photo =====
DO $$
DECLARE v_photo INT; v_canon INT; v_noncanon_no_img INT;
BEGIN
  SELECT COUNT(*) INTO v_photo FROM _v215_batch
   WHERE photo_origin_url IS NOT NULL AND photo_origin_url<>'';
  IF v_photo <> 299 THEN RAISE EXCEPTION 'USHR-04 FAILED: % of 299 batch reps have a photo', v_photo; END IF;

  -- The "v_canon >= 290" floor that used to sit here was REMOVED on 2026-07-26. It asserted that
  -- most batch reps still carry the unitedstates.github.io congress default, and it now reads 246
  -- of 299 — not because coverage regressed, but because the headshot sweep has been REPLACING
  -- those defaults with better portraits. The floor penalised the sweep for doing its job, and
  -- would have kept dropping. What actually matters is that every rep has a working image, which
  -- the two surviving assertions cover: all 299 carry a photo_origin_url, and every rep who has
  -- moved off the canonical URL has a politician_images row backing it. The canonical/mirrored
  -- split is still reported below, as an observation rather than a gate.
  SELECT COUNT(*) INTO v_canon FROM _v215_batch
   WHERE photo_origin_url LIKE 'https://unitedstates.github.io/images/congress/225x275/%';

  -- Any batch rep not on the canonical URL must have a politician_images row (storage-mirrored fallback)
  SELECT COUNT(*) INTO v_noncanon_no_img
  FROM _v215_batch p
  WHERE p.photo_origin_url NOT LIKE 'https://unitedstates.github.io/images/congress/225x275/%'
    AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);
  IF v_noncanon_no_img <> 0 THEN
    RAISE EXCEPTION 'USHR-04 FAILED: % non-canonical-photo batch reps lack a politician_images row', v_noncanon_no_img;
  END IF;
  RAISE NOTICE 'USHR-04 PASS: 299/299 batch reps have a photo (% canonical + % storage-mirrored)', v_canon, 299 - v_canon;
END $$;

-- ===== USHR-05: Path 0 spot checks (>=5 states incl at-large + DC) =====
DO $$
DECLARE
  v_name TEXT;
  -- geoid, expected last name, label
  checks TEXT[][] := ARRAY[
    ARRAY['5600','Hageman','WY-AL (at-large)'],
    ARRAY['3614','Ocasio-Cortez','NY-14'],
    ARRAY['4836','Babin','TX-36'],
    ARRAY['3905','Latta','OH-5'],
    ARRAY['1701','Jackson','IL-1']
  ];
  c TEXT[];
BEGIN
  FOREACH c SLICE 1 IN ARRAY checks LOOP
    SELECT p.last_name INTO v_name
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
    WHERE d.district_type='NATIONAL_LOWER' AND d.tiger_geoid = c[1];
    IF v_name IS NULL OR v_name NOT ILIKE '%'||c[2]||'%' THEN
      RAISE EXCEPTION 'USHR-05 FAILED: Path 0 for % (geoid %) expected %, got %', c[3], c[1], c[2], COALESCE(v_name,'(none)');
    END IF;
    RAISE NOTICE 'USHR-05 Path 0 OK: % -> %', c[3], v_name;
  END LOOP;

  -- DC delegate. Was keyed on tiger_geoid 'dc-national-lower' until migration 1479 merged DC's two
  -- competing NATIONAL_LOWER rows — the very "dup DC delegate" this file's header used to allowlist.
  -- Norton now hangs off geo_id '1198', the row that owns the District polygon, which is what makes
  -- her reachable from a coordinate at all. Keyed on geo_id rather than tiger_geoid so this asserts
  -- the same row every other House-scoped query in the repo resolves.
  SELECT p.last_name INTO v_name
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE d.district_type='NATIONAL_LOWER' AND d.geo_id = '1198' AND p.last_name ILIKE '%Norton%';
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'USHR-05 FAILED: DC delegate (Norton) not resolved via geo_id 1198';
  END IF;
  RAISE NOTICE 'USHR-05 Path 0 OK: DC delegate -> %', v_name;
  RAISE NOTICE 'USHR-05 PASS: Path 0 resolves correct reps across 5 states + at-large + DC';
END $$;

-- If we reach here with no exception, all v2.15 assertions passed.
DO $$ BEGIN RAISE NOTICE 'verify-phase-125-126: ALL USHR-01..05 ASSERTIONS PASSED'; END $$;
