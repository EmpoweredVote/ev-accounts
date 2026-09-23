-- CA_0188_is_incumbent_default_false.sql
-- essentials.politicians.is_incumbent: DEFAULT true -> DEFAULT false.
--
-- WHY. is_incumbent is a cached occupancy flag: the incumbents-only reads (getPoliticiansFlatList, address search,
-- browse) filter on it. With DEFAULT true, every insert that omitted the column created an "incumbent" -- the 2026
-- race seeding, the court and city rosters, the discovery sweeps. By 2026-09-23 there were 1,817 active rows reading
-- is_incumbent = true with NO office_terms row; CA_0181-CA_0187 cleared or seated every one of them (0 left).
--
-- WHAT THE NEW DEFAULT CHANGES. An insert that omits the column now creates a NON-incumbent. That is the safe side
-- for a candidate. For a seated person it is not: the row is hidden from address search until someone sets the flag.
-- But that side is WATCHED -- the reachability check's REPS_FILTER_HIDDEN (zero tolerance) fails on any occupied
-- district whose holder the reps filter drops -- while the old side (an incumbent with no seat) was watched by nothing.
-- Neither default is safe to rely on, so the same change adds a rule to `npm run check:occupancy` (CI): every
-- INSERT into essentials.politicians in a file added or changed on a branch must name is_incumbent.
--
-- Checked before writing (2026-09-23): no function in the database inserts into essentials.politicians; the runtime
-- insert paths set the flag explicitly (stagingService.ts: true; adminService.ts: data.is_incumbent ?? true); the
-- shared roster library scripts/lib/politician-upsert.ts is changed in the same PR to set true. About 55 historical
-- generator statements omit the column; their output is already applied, and the guard flags one only if it is edited.
-- Existing rows are NOT touched: SET DEFAULT changes nothing already stored.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews, who chose "all three parts"). Dry run x2 right
--   before the apply, with a control insert that omitted the column and read back false; re-run after it changed
--   nothing. Verified after: column_default = false, comment set, active incumbents with no seat = 0.
--
-- ROLLBACK: ALTER TABLE essentials.politicians ALTER COLUMN is_incumbent SET DEFAULT true;
--           COMMENT ON COLUMN essentials.politicians.is_incumbent IS NULL;
-- IDEMPOTENT: SET DEFAULT and COMMENT ON are idempotent; a re-run changes nothing and every gate still passes.

BEGIN;

-- ALTER TABLE takes an ACCESS EXCLUSIVE lock. SET DEFAULT is metadata-only, but waiting for the lock behind a long
-- read would queue every other query on this table, so give up quickly instead.
SET LOCAL lock_timeout = '5s';

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_default text; v_nullable text; v_type text;
BEGIN
  SELECT column_default, is_nullable, data_type INTO v_default, v_nullable, v_type
    FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'is_incumbent';
  IF v_type IS DISTINCT FROM 'boolean' THEN RAISE EXCEPTION 'PRE: is_incumbent is not a boolean column (%)', v_type; END IF;
  IF v_default NOT IN ('true', 'false') THEN RAISE EXCEPTION 'PRE: unexpected default %', v_default; END IF;
END $$;

ALTER TABLE essentials.politicians ALTER COLUMN is_incumbent SET DEFAULT false;

COMMENT ON COLUMN essentials.politicians.is_incumbent IS
  'Cached flag: true = this person holds a seat now (not a candidate row). Read paths filter on it, so it must agree '
  'with essentials.office_terms, the only source of occupancy. Default false since CA_0188 (2026-09-23); DEFAULT true '
  'had created 1,817 seatless "incumbents". Set it explicitly: true when seating someone (with seat_officeholder), '
  'false for a candidate or a former officeholder. check:occupancy requires the column in every new INSERT.';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_default text; v_n int;
BEGIN
  SELECT column_default INTO v_default FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'is_incumbent';
  IF v_default IS DISTINCT FROM 'false' THEN RAISE EXCEPTION 'POST: default is %, expected false', v_default; END IF;

  SELECT count(*) INTO v_n FROM pg_attribute a
   WHERE a.attrelid = 'essentials.politicians'::regclass AND a.attname = 'is_incumbent'
     AND col_description(a.attrelid, a.attnum) LIKE 'Cached flag:%CA_0188%';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: column comment not set'; END IF;

  -- Reported, not gated: the default does not touch stored rows, so this count is whatever it was before.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.is_active AND p.is_incumbent AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = p.id);
  RAISE NOTICE 'CA_0188 applied: is_incumbent DEFAULT false (active incumbents with no seat: %)', v_n;
END $$;

COMMIT;
