-- Migration 1379: judicial schema (all 6 tables)
-- Phase 30 (Judicial Schema & Cal-Access Retention Finance Ingest), Plan 01.
--
-- FIRST schema-creation migration in this repo (base transparent_motivations DDL
-- predates the migrations/ folder -- no other file does CREATE SCHEMA). Creates the
-- `judicial` schema and all 6 tables from design doc transparent-motivations-judicial-
-- design.md v2 Sec5.2: judges, donations, attorneys, cases, appearances, matches.
--
-- Satisfies JUD-ING-01 (schema exists) and establishes the JUD-ING-06 attribution/
-- idempotency shape on judicial.donations that Phase 30 Plans 02/03 write into.
--
-- Three deliberate deviations from the Sec5.2 sketch (sign-off in 30-RESEARCH.md):
--   1. judicial.donations adds confidence_level/raw_record/ingest_timestamp/source_url
--      (D-13) -- Sec5.2's sketch predates the reuse-the-attribution-pattern decision.
--   2. Filing reference is named source_transaction_id (not source_filing_id) to match
--      transparent_motivations.contributions' column name exactly, for pattern
--      consistency (`${filingID}_${amendID}_${lineItem}`).
--   3. judicial.matches.match_confidence uses a 4-tier vocabulary
--      (bar_number/high/medium/low, per Sec5.3) that is DISTINCT from the platform's
--      3-tier HIGH/MEDIUM/ESTIMATED confidence_level used everywhere else -- these
--      answer different questions (source authority vs. match certainty) and must
--      not be conflated. matches.appearance_id is nullable: identity match (donation
--      -> attorney) may be established before the appearance linkage is confirmed.
--
-- judicial.donations idempotency: UNIQUE (data_source, source_transaction_id);
-- data_source is CHECK'd to the single value 'cal_access' since no other source will
-- ever write donations (CourtListener/State Bar write to cases/attorneys, not
-- donations) -- see 30-RESEARCH.md Pitfall 4. judicial.judges gets a
-- UNIQUE(full_name, court) constraint so a seed script's ON CONFLICT DO NOTHING is
-- meaningful (resolves the 30-PATTERNS.md open decision point in favor of adding the
-- constraint here rather than check-then-insert in the seed script).
--
-- Idempotency: CREATE SCHEMA/TABLE ... IF NOT EXISTS throughout. Safe to re-apply.

BEGIN;

CREATE SCHEMA IF NOT EXISTS judicial;

CREATE TABLE IF NOT EXISTS judicial.judges (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name                 text NOT NULL,
  court                     text NOT NULL, -- 'ca_supreme' | 'ca_court_of_appeal'
  division                  text,          -- e.g. 'First Appellate District' (Court of Appeal only)
  seat_type                 text,          -- 'chief_justice' | 'associate_justice'
  appointment_date          date,
  appointing_governor       text,
  retention_election_dates  date[] NOT NULL DEFAULT '{}',
  calbar_number             text,
  prior_firm_affiliations   text[] NOT NULL DEFAULT '{}',
  external_ids              jsonb NOT NULL DEFAULT '{}'::jsonb, -- {"cal_access_filer_ids": ["123456"]}
  created_at                timestamptz NOT NULL DEFAULT now(),
  updated_at                timestamptz NOT NULL DEFAULT now(),
  UNIQUE (full_name, court)
);

COMMENT ON TABLE judicial.judges IS
  'CA appellate justices (Supreme Court + Courts of Appeal). external_ids.cal_access_filer_ids maps a judge to their retention-committee Cal-Access filer ID(s) -- judicial-native mapping (D-07), deliberately NOT via transparent_motivations.politician_sources (D-08).';

CREATE TABLE IF NOT EXISTS judicial.donations (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  judge_id               uuid NOT NULL REFERENCES judicial.judges(id),
  donor_name_raw         text NOT NULL DEFAULT '',
  donor_name_normalized  text NOT NULL DEFAULT 'anonymous',
  donor_type             text, -- nullable -- deferred to Phase 32/33 (attorney/firm classification needs State Bar)
  donor_employer_raw     text,
  donor_occupation_raw   text,
  donor_calbar_number_matched text, -- populated by Phase 33 matcher; null at ingest
  amount                 numeric(16,2) NOT NULL,
  contribution_date      date,
  data_source            text NOT NULL DEFAULT 'cal_access'
                           CHECK (data_source = 'cal_access'),
  source_transaction_id  text NOT NULL, -- ${filingID}_${amendID}_${lineItem}, mirrors transparent_motivations.contributions
  source_url             text NOT NULL,
  confidence_level       text NOT NULL DEFAULT 'HIGH'
                           CHECK (confidence_level IN ('HIGH','MEDIUM','ESTIMATED')),
  raw_record             jsonb NOT NULL DEFAULT '{}'::jsonb,
  ingest_timestamp       timestamptz NOT NULL DEFAULT now(),
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  UNIQUE (data_source, source_transaction_id)
);
CREATE INDEX IF NOT EXISTS idx_judicial_donations_judge ON judicial.donations (judge_id);

COMMENT ON TABLE judicial.donations IS
  'Cal-Access retention-finance contributions to judicial.judges, reusing calAccessAdapter.ts fetch()/normalize() (unmodified) via a fake PoliticianSource wrapper (D-10/D-11). JUD-ING-06 attribution: source_transaction_id/source_url/confidence_level/ingest_timestamp/raw_record on every row.';

CREATE TABLE IF NOT EXISTS judicial.attorneys (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  calbar_number   text,
  full_name       text NOT NULL,
  current_firm    text,
  admission_date  date,
  name_variants   text[] NOT NULL DEFAULT '{}',
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS judicial.cases (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_name          text NOT NULL,
  docket_number      text,
  court              text,
  filing_date        date,
  disposition_date   date,
  opinion_url        text,
  panel_judge_ids    uuid[] NOT NULL DEFAULT '{}',
  authoring_judge_id uuid REFERENCES judicial.judges(id),
  disposition_type   text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS judicial.appearances (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id             uuid NOT NULL REFERENCES judicial.cases(id),
  attorney_id         uuid NOT NULL REFERENCES judicial.attorneys(id),
  side                text,
  role                text,
  firm_at_time_of_case text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS judicial.matches (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  donation_id         uuid NOT NULL REFERENCES judicial.donations(id),
  attorney_id         uuid NOT NULL REFERENCES judicial.attorneys(id),
  appearance_id       uuid REFERENCES judicial.appearances(id), -- nullable: identity match may precede appearance discovery
  match_confidence    text NOT NULL CHECK (match_confidence IN ('bar_number','high','medium','low')),
  match_method        text NOT NULL,
  human_reviewed_bool boolean NOT NULL DEFAULT false,
  human_reviewed_by   text,
  human_review_notes  text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE judicial.matches IS
  'match_confidence uses a 4-tier vocabulary (bar_number/high/medium/low, design Sec5.3) distinct from the platform-wide 3-tier HIGH/MEDIUM/ESTIMATED confidence_level -- do not conflate. No human match publishes without human_reviewed_bool=true (Phase 34 review gate).';

-- Post-verify: all 6 judicial tables must exist before this migration is considered applied.
DO $$
DECLARE
  v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM information_schema.tables
  WHERE table_schema = 'judicial'
    AND table_name IN ('judges','donations','attorneys','cases','appearances','matches');
  IF v_count <> 6 THEN
    RAISE EXCEPTION 'Migration 1379: expected 6 judicial tables, found %', v_count;
  END IF;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('1379') ON CONFLICT (version) DO NOTHING;

COMMIT;
