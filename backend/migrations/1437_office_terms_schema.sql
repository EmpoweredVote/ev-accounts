-- 1437_office_terms_schema.sql
-- ADR 0002 phase 1: temporal officeholder terms. SCHEMA ONLY — writes no data, changes no
-- existing behaviour. Idempotent.
--
-- See docs/adr/0002-temporal-officeholder-terms.md for the full rationale. In short:
--   essentials.offices holds ONE politician_id, a point-in-time snapshot with no temporal
--   dimension, so an election already decided but whose term starts later is unrepresentable.
--   Chris Taylor (WI Supreme Court) and Anthony LoCoco (Court of Appeals District II, covering
--   Racine County) were certified 2026-04-07 and take office 2026-08-01; migration 1433 could
--   only seed the circuit court and had to defer both. This makes occupancy a time series.
--
-- Phase 2 (1438) backfills. Phase 3 moves read paths onto the view. Nothing reads this yet.
--
-- CONSTRAINT SEMANTICS — behaviour-tested against this database before writing, 7 cases:
--   1. one open-ended term per office                    -> allowed
--   2. a second open-ended term on the same office       -> REJECTED  (two simultaneous occupants)
--   3. a future term while the incumbent is open-ended   -> REJECTED  (see the note below)
--   4. close incumbent (term_end), then insert successor -> allowed
--   5. any overlapping span                              -> REJECTED
--   6. the same politician in a DIFFERENT office         -> allowed  (28 people already hold >1)
--   7. a vacancy span overlapping an occupant            -> REJECTED
--   Consecutive terms do NOT collide: daterange(NULL,'2026-07-31','[]') and
--   daterange('2026-08-01',NULL,'[]') are non-overlapping, verified directly. Same-day does
--   collide, correctly.
--
-- !! THE HAND-OFF IS A TWO-STEP, BY DESIGN. An open-ended term (term_end IS NULL) is an INFINITE
--    range, so it overlaps every future span — case 3 above. To seat a successor you must first
--    CLOSE the predecessor:
--        UPDATE essentials.office_terms SET term_end = '2026-07-31', how_ended = 'term_expired'
--         WHERE office_id = :office AND term_end IS NULL;
--        INSERT INTO essentials.office_terms (office_id, politician_id, term_start, how_started, source)
--        VALUES (:office, :successor, '2026-08-01', 'elected', '...');
--    That is a feature, not friction: it makes "when did the last term end?" a required answer
--    instead of an implicit overwrite. Where there is no predecessor row at all (e.g. Court of
--    Appeals District II, whose outgoing judge was never seeded), the INSERT alone is enough.
--
-- start_precision exists because sources routinely give only a year — Racine County's court page
--   says "2017 to Present". 1433 left date_seated NULL rather than invent 2017-01-01; here that
--   can be recorded honestly as 2017-01-01 with precision='year'.
--
-- politician_id is NULLABLE on purpose: a vacancy is a fact about a span of time, not a missing
--   row. Caledonia Trustee Seat 2 is vacant from Balch's elevation until it is filled.
BEGIN;

-- btree_gist is required to use uuid equality (=) inside a GiST exclusion constraint.
-- Available on this instance, not previously installed.
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS essentials.office_terms (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id       uuid NOT NULL REFERENCES essentials.offices(id) ON DELETE CASCADE,
  politician_id   uuid          REFERENCES essentials.politicians(id),
  term_start      date,
  term_end        date,
  start_precision text NOT NULL DEFAULT 'day'
                  CHECK (start_precision IN ('day','month','year','unknown')),
  how_started     text CHECK (how_started IN
                    ('elected','appointed','succeeded','redistricted','unknown')),
  how_ended       text CHECK (how_ended IN
                    ('term_expired','resigned','defeated','retired','died','recalled',
                     'removed','redistricted','unknown')),
  source          text NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT office_terms_dates_sane
    CHECK (term_start IS NULL OR term_end IS NULL OR term_end >= term_start),

  -- The constraint that columns on `offices` could never express.
  CONSTRAINT office_terms_no_overlap EXCLUDE USING gist (
    office_id WITH =,
    daterange(term_start, term_end, '[]') WITH &&
  )
);

COMMENT ON TABLE essentials.office_terms IS
  'Occupancy of an office over time (ADR 0002). One row per tenure; politician_id NULL means the '
  'seat was vacant for that span. An exclusion constraint makes two simultaneous occupants of one '
  'office impossible. Resolve "current" at READ TIME via essentials.current_office_holders — never '
  'cache it in a column, because no trigger fires merely because the calendar advanced.';

COMMENT ON COLUMN essentials.office_terms.term_end IS
  'NULL = open-ended/current. NOTE an open-ended term is an INFINITE range and therefore overlaps '
  'any future term, so seating a successor requires closing this term first.';

COMMENT ON COLUMN essentials.office_terms.start_precision IS
  'How precisely term_start is known. Use ''year'' when a source gives only a year (e.g. "2017 to '
  'Present") rather than inventing a day.';

CREATE INDEX IF NOT EXISTS office_terms_office_idx     ON essentials.office_terms (office_id);
CREATE INDEX IF NOT EXISTS office_terms_politician_idx ON essentials.office_terms (politician_id);
CREATE INDEX IF NOT EXISTS office_terms_current_idx    ON essentials.office_terms (office_id)
  WHERE term_end IS NULL;

-- ── Resolution: at query time, never cached ──
CREATE OR REPLACE VIEW essentials.current_office_holders AS
SELECT office_id, politician_id, term_start, term_end, how_started, start_precision
  FROM essentials.office_terms
 WHERE (term_start IS NULL OR term_start <= CURRENT_DATE)
   AND (term_end   IS NULL OR term_end   >= CURRENT_DATE);

COMMENT ON VIEW essentials.current_office_holders IS
  'Who holds each office TODAY, resolved from essentials.office_terms at query time. Read paths '
  'should join this rather than essentials.offices.politician_id (ADR 0002 phase 3).';

CREATE OR REPLACE FUNCTION essentials.office_holders_as_of(as_of date)
RETURNS TABLE (office_id uuid, politician_id uuid, term_start date, term_end date)
LANGUAGE sql STABLE AS $$
  SELECT ot.office_id, ot.politician_id, ot.term_start, ot.term_end
    FROM essentials.office_terms ot
   WHERE (ot.term_start IS NULL OR ot.term_start <= as_of)
     AND (ot.term_end   IS NULL OR ot.term_end   >= as_of);
$$;

COMMENT ON FUNCTION essentials.office_holders_as_of(date) IS
  'Who held each office on a given date. Answers "who represented me in 2019" without a schema '
  'change (ADR 0002).';

-- ── Post-verify gate ──
DO $$
DECLARE n_tbl int; n_excl int; n_view int; n_fn int; n_ext int; n_rows int;
BEGIN
  SELECT count(*) INTO n_ext FROM pg_extension WHERE extname='btree_gist';
  IF n_ext <> 1 THEN RAISE EXCEPTION 'btree_gist not installed'; END IF;

  SELECT count(*) INTO n_tbl FROM information_schema.tables
   WHERE table_schema='essentials' AND table_name='office_terms';
  IF n_tbl <> 1 THEN RAISE EXCEPTION 'office_terms table missing'; END IF;

  SELECT count(*) INTO n_excl FROM pg_constraint
   WHERE conname='office_terms_no_overlap' AND contype='x'
     AND conrelid='essentials.office_terms'::regclass;
  IF n_excl <> 1 THEN RAISE EXCEPTION 'exclusion constraint missing (contype must be x)'; END IF;

  SELECT count(*) INTO n_view FROM information_schema.views
   WHERE table_schema='essentials' AND table_name='current_office_holders';
  IF n_view <> 1 THEN RAISE EXCEPTION 'current_office_holders view missing'; END IF;

  SELECT count(*) INTO n_fn FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='essentials' AND p.proname='office_holders_as_of';
  IF n_fn <> 1 THEN RAISE EXCEPTION 'office_holders_as_of function missing'; END IF;

  -- phase 1 must write NO data
  SELECT count(*) INTO n_rows FROM essentials.office_terms;
  IF n_rows <> 0 THEN
    RAISE NOTICE 'office_terms already holds % rows (phase 2 has run) — schema re-verified', n_rows;
  END IF;

  RAISE NOTICE 'office_terms schema verify PASSED: table + exclusion constraint + 3 indexes + view + as-of function.';
END $$;

COMMIT;
