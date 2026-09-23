-- CA_0195_politicians_is_vacant_not_null.sql
-- essentials.politicians.is_vacant: backfill NULL -> false, then DEFAULT false + NOT NULL.
--
-- WHY. The column was nullable with NO default, so every insert that omitted it wrote NULL: 964 of 3,845 politician
-- INSERTs in 148 migrations, 77 of 86 in the backend/scripts generators, and adminService.createPolitician. Measured
-- 2026-09-23: 4,777 NULL rows (created 2026-05-22..2026-09-21), 2,760 of them seated and active. Two reads filter
-- `p.is_vacant = false` and so silently dropped every NULL:
--   * getPoliticiansByGovernmentList (POST /essentials/browse/by-government-list, the landing city chips and the
--     Treasury Tracker / Civic Spaces county links; also the county bucket of /location-search/resolve). All 408 LA
--     Superior Court judges were missing from the government step for LA County 06037, as were whole state
--     legislatures (PA 253, GA 235, MN 200, SC 170, NC 170, FL 155, WA 151, TN 131, CO 100) for a state geo.
--   * getUnmatchedFederalPoliticians (fecResearch.ts): 12 seated U.S. House/Senate rows were never queued for FEC
--     matching, among them 4 sitting Utah representatives with no FEC link.
--
-- WHAT THE FLAG MEANS. true marks a PLACEHOLDER row standing in for an empty seat -- the pre-ADR-0002 pattern. Exactly
-- 4 rows carry it ("Vacant" x2, "VACANT - District 5", "VACANT - Ward 5"), all inactive, none holding a term. ADR 0002
-- moved vacancy to essentials.office_terms (a span with politician_id NULL) and essentials.offices.is_vacant. A person
-- is never vacant, so false is the correct value for EVERY real politician -- which is why this backfills all NULLs,
-- not only the seated ones, and why no check:occupancy rule is needed: unlike is_incumbent, the right value never
-- depends on the row, so DEFAULT false is safe to rely on, and an explicit NULL now fails loudly at insert.
--
-- ORDER. Apply only AFTER the code in the same PR is deployed. The browse government step used to derive district_type
-- from governments.type, and its row wins the merge over the overlap step's row for the same person. The NULL rows were
-- reaching pages through the overlap step with the correct districts.district_type; backfilling first would have
-- replaced them with government-step rows (measured: the 408 LASC judges JUDICIAL -> COUNTY on the LA County link, King
-- County's council filed under "Sheriff", Philadelphia/Travis/Columbus/Macon officers merged into the council). The code
-- now prefers d.district_type, and with it the backfill changed no live page except to add the missing people.
--
-- Checked before writing (2026-09-23): no database function inserts into essentials.politicians or names is_vacant; no
-- view depends on the column; the only trigger (politicians_name_duplicate_guard) is BEFORE INSERT, so the UPDATE below
-- does not fire it. staging.politicians.is_vacant is nullable (2 NULL rows); stagingService's promote now sends
-- `isVacant ?? false`, so promoting those rows does not hit the new NOT NULL.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: NOT YET APPLIED.
--
-- ROLLBACK: ALTER TABLE essentials.politicians ALTER COLUMN is_vacant DROP NOT NULL;
--           ALTER TABLE essentials.politicians ALTER COLUMN is_vacant DROP DEFAULT;
--           COMMENT ON COLUMN essentials.politicians.is_vacant IS NULL;
--           (The backfill is not reversed: NULL carried no information the value false does not.)
-- IDEMPOTENT: the UPDATE matches nothing on a re-run; SET DEFAULT, SET NOT NULL and COMMENT ON are idempotent.

BEGIN;

-- ALTER TABLE takes an ACCESS EXCLUSIVE lock, and SET NOT NULL scans the table (~88k rows) while holding it. Waiting
-- for that lock behind a long read would queue every other query on the table, so give up quickly instead.
SET LOCAL lock_timeout = '5s';

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_type text; v_true int; v_bad_true int; v_null int; v_placeholder_null int;
BEGIN
  SELECT data_type INTO v_type FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'is_vacant';
  IF v_type IS DISTINCT FROM 'boolean' THEN RAISE EXCEPTION 'PRE: is_vacant is not a boolean column (%)', v_type; END IF;

  -- The premise: true is only ever a placeholder, never a person who could be seated.
  SELECT count(*),
         count(*) FILTER (WHERE p.is_active OR EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = p.id))
    INTO v_true, v_bad_true
    FROM essentials.politicians p WHERE p.is_vacant;
  IF v_bad_true <> 0 THEN
    RAISE EXCEPTION 'PRE: % is_vacant=true row(s) are active or hold a term -- the flag means something else now; stop', v_bad_true;
  END IF;

  -- A NULL row that looks like a placeholder would need a human decision, not false.
  SELECT count(*) FILTER (WHERE full_name ILIKE 'vacant%' OR full_name ILIKE '%vacancy%'), count(*)
    INTO v_placeholder_null, v_null
    FROM essentials.politicians WHERE is_vacant IS NULL;
  IF v_placeholder_null <> 0 THEN
    RAISE EXCEPTION 'PRE: % NULL row(s) are named like a vacancy placeholder; classify them by hand first', v_placeholder_null;
  END IF;

  RAISE NOTICE 'CA_0195 pre-flight: % NULL row(s) to backfill; % placeholder row(s) keep true', v_null, v_true;
END $$;

-- ─── Backfill ────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.politicians SET is_vacant = false WHERE is_vacant IS NULL;

ALTER TABLE essentials.politicians ALTER COLUMN is_vacant SET DEFAULT false;
ALTER TABLE essentials.politicians ALTER COLUMN is_vacant SET NOT NULL;

COMMENT ON COLUMN essentials.politicians.is_vacant IS
  'Legacy placeholder flag: true marks a row that stood in for an EMPTY SEAT before ADR 0002 (4 inactive rows named '
  '"Vacant"). A person is never vacant -- false for every real politician. Vacancy is essentials.office_terms (a span '
  'with politician_id NULL) plus essentials.offices.is_vacant; read those, not this. NOT NULL DEFAULT false since '
  'CA_0195 (2026-09-23): 4,777 NULLs had hidden 2,760 seated people from by-government-list and FEC matching.';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_null int; v_notnull boolean; v_default text; v_n int; v_true int;
BEGIN
  SELECT count(*) INTO v_null FROM essentials.politicians WHERE is_vacant IS NULL;
  IF v_null <> 0 THEN RAISE EXCEPTION 'POST: % NULL row(s) remain', v_null; END IF;

  SELECT a.attnotnull INTO v_notnull FROM pg_attribute a
   WHERE a.attrelid = 'essentials.politicians'::regclass AND a.attname = 'is_vacant';
  IF v_notnull IS DISTINCT FROM true THEN RAISE EXCEPTION 'POST: is_vacant is still nullable'; END IF;

  SELECT column_default INTO v_default FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'is_vacant';
  IF v_default IS DISTINCT FROM 'false' THEN RAISE EXCEPTION 'POST: default is %, expected false', v_default; END IF;

  SELECT count(*) INTO v_n FROM pg_attribute a
   WHERE a.attrelid = 'essentials.politicians'::regclass AND a.attname = 'is_vacant'
     AND col_description(a.attrelid, a.attnum) LIKE 'Legacy placeholder flag:%CA_0195%';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: column comment not set'; END IF;

  -- The placeholders are untouched: the UPDATE only matched NULL.
  SELECT count(*) INTO v_true FROM essentials.politicians WHERE is_vacant;

  -- The originating symptom: all 408 seated LA Superior Court judges now pass the government step's filter.
  SELECT count(DISTINCT p.id) INTO v_n
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = ch.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.geo_id = '06037' AND ch.name_formal = 'Los Angeles County Superior Court'
     AND p.is_active AND p.is_vacant = false;
  IF v_n < 400 THEN RAISE EXCEPTION 'POST: only % LASC judges pass the browse filter (expected ~408)', v_n; END IF;

  RAISE NOTICE 'CA_0195 applied: is_vacant NOT NULL DEFAULT false; placeholders true = %; LASC judges visible to the government step = %', v_true, v_n;
END $$;

COMMIT;
