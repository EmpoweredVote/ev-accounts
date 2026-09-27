BEGIN;

-- =============================================================================
-- CA_0296: essentials.legislative_service — a person's SERVICE in a state legislature, by chamber
-- =============================================================================
-- Why (codebook 0.4, V5 option B, ruling 2026-09-27, Chris Andrews): a record from either chamber of
-- the same legislature counts for a person's current seat or candidacy. CONFIRM accepts such a record
-- only against earlier service ON FILE covering its date, with the page showing that service's chamber
-- (prior-service-unverified otherwise). Nothing in our data held earlier-chamber service.
--
-- Why a new table and not essentials.office_terms (decided 2026-09-27):
--   * An office is a SEAT on today's district map. A 2019 Assembly term written onto a current-map
--     seat would make essentials.office_holders_as_of('2019-…') answer the wrong representative for an
--     address, silently (redistricting moved the lines).
--   * 2,662 of 4,003 open state-legislature office_terms rows have term_start NULL — an infinite range
--     — so office_terms_no_overlap refuses any earlier term on those seats.
-- This table records service, not occupancy: nothing that resolves who holds a seat reads it. The
-- district is kept as the LABEL the source printed (its own map at the time), never an office_id.
--
-- Dates follow CLAUDE.md "Don't invent dates": a source that gives no start writes NULL with
-- start_precision 'unknown'; CONFIRM treats an unknown start as unable to settle a date (fail closed).
-- 🔴 Duplicate-person merge migrations must re-point politician_id here too.
-- =============================================================================

CREATE TABLE IF NOT EXISTS essentials.legislative_service (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  politician_id    uuid NOT NULL REFERENCES essentials.politicians(id),
  state_usps       char(2) NOT NULL CHECK (state_usps = upper(state_usps)),
  chamber          text NOT NULL CHECK (chamber IN ('upper', 'lower')),
  district_label   text,
  service_start    date,
  start_precision  text NOT NULL CHECK (start_precision IN ('day', 'month', 'year', 'unknown')),
  service_end      date,
  end_precision    text CHECK (end_precision IN ('day', 'month', 'year', 'unknown')),
  source           text NOT NULL CHECK (length(trim(source)) > 0),
  created_at       timestamptz NOT NULL DEFAULT now(),
  CHECK ((service_start IS NULL) = (start_precision = 'unknown')),
  CHECK ((service_end IS NULL) = (end_precision IS NULL OR end_precision = 'unknown')),
  CHECK (service_start IS NULL OR service_end IS NULL OR service_start <= service_end)
);
CREATE UNIQUE INDEX IF NOT EXISTS legislative_service_span_uniq
  ON essentials.legislative_service (politician_id, state_usps, chamber, coalesce(district_label, ''), coalesce(service_start, DATE '0001-01-01'), coalesce(service_end, DATE '9999-12-31'));
CREATE INDEX IF NOT EXISTS legislative_service_politician_idx ON essentials.legislative_service (politician_id);

-- RLS default-deny (CTO decision 0015): the API reads it through the pool role, never a client key.
ALTER TABLE essentials.legislative_service ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON essentials.legislative_service FROM anon, authenticated;

COMMENT ON TABLE essentials.legislative_service IS
  'A person''s service in a chamber of a state legislature (CA_0296; codebook V5 option B). SERVICE, not '
  'seat occupancy: never read to resolve who holds a seat (office_terms does that). district_label is '
  'the source''s own label at the time, not an office. Unknown start = NULL + start_precision unknown. '
  'Duplicate-person merges must re-point politician_id here.';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'essentials' AND tablename = 'legislative_service' AND rowsecurity) THEN
    RAISE EXCEPTION 'CA_0296: essentials.legislative_service missing or RLS not enabled';
  END IF;
  IF has_table_privilege('anon', 'essentials.legislative_service', 'SELECT')
     OR has_table_privilege('authenticated', 'essentials.legislative_service', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0296: anon/authenticated can still read legislative_service';
  END IF;
  IF (SELECT count(*) FROM pg_constraint WHERE conrelid = 'essentials.legislative_service'::regclass AND contype = 'c') < 7 THEN
    RAISE EXCEPTION 'CA_0296: expected at least 7 CHECK constraints on legislative_service';
  END IF;
END $$;

COMMIT;
