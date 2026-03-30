-- =============================================================================
-- Migration 042: Election schema foundation — elections, races, race_candidates
--
-- These three tables model upcoming/current election events for the
-- Essentials Election Central feature (v2026.3.8). They are DIFFERENT from
-- essentials.election_records which is a legacy BallotReady table for
-- historical career data (past races a politician ran in, linked to BallotReady
-- external IDs). Do NOT confuse them — election_records is untouched by this
-- migration.
--
-- Three-level hierarchy:
--   elections       — the event (date, type, geographic scope)
--   races           — a specific position within that election
--   race_candidates — a person running in a specific race
--
-- ANTIPARTISAN RATIONALE:
-- NO party affiliation on candidates. Empowered Vote derives political
-- alignment from compass answers, legislative votes, and sourced quotes.
-- Party labels are partisan signals that undermine voter independence.
--
-- EXCEPTION — PRIMARY ELECTIONS:
-- Many states (including Indiana) have closed or semi-closed primaries where
-- voters can only participate in one party's primary. For primary elections,
-- the race itself is party-scoped (e.g., "Republican Primary — State Senate
-- District 40"). The primary_party column on essentials.races captures this
-- structural reality. It is NULL for general/retention/special elections.
-- Party lives on the RACE (the structural container), never on the CANDIDATE.
--
-- All CREATE TABLE statements use IF NOT EXISTS for idempotency (safe to re-run).
-- All CREATE INDEX statements use IF NOT EXISTS for idempotency.
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Create essentials.elections
--
-- The election event itself. One election can contain many races across
-- multiple levels (e.g., a general election ballot with federal, state,
-- and local races simultaneously).
-- =============================================================================

CREATE TABLE IF NOT EXISTS essentials.elections (
  id                 uuid        NOT NULL DEFAULT uuid_generate_v4(),
  name               text        NOT NULL,                 -- e.g. "2026 Indiana Primary"
  election_date      date        NOT NULL,                 -- PostgreSQL date type (NOT text) — enables countdown arithmetic in Phase 99
  election_type      text        NOT NULL
                     CHECK (election_type IN ('primary','general','retention','special')),
  jurisdiction_level text        NOT NULL
                     CHECK (jurisdiction_level IN ('federal','state','county','city','district')),
  state              character(2),                         -- e.g. 'IN', 'CA' — nullable for multi-state federal elections
  description        text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT elections_pkey PRIMARY KEY (id)
);

-- =============================================================================
-- Step 2: Create essentials.races
--
-- A specific position within an election. Links to essentials.elections (the
-- event) and optionally to essentials.offices (the seat being contested).
-- office_id is nullable because some races may not yet have a corresponding
-- offices record (e.g., new districts, positions added after redistricting).
-- =============================================================================

CREATE TABLE IF NOT EXISTS essentials.races (
  id            uuid        NOT NULL DEFAULT uuid_generate_v4(),
  election_id   uuid        NOT NULL
                REFERENCES essentials.elections(id) ON DELETE CASCADE,
  office_id     uuid                                       -- nullable: some races may not yet have a corresponding offices record
                REFERENCES essentials.offices(id),
  position_name text        NOT NULL,                      -- display name, e.g. "City Council District 3"
  primary_party text,                                      -- only for primary elections (closed/semi-closed states); NULL for general/retention/special
  seats         int         NOT NULL DEFAULT 1,
  description   text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT races_pkey PRIMARY KEY (id)
);

-- =============================================================================
-- Step 3: Create essentials.race_candidates
--
-- A person running in a specific race. The politician_id FK is optional:
-- - Incumbents: link to existing essentials.politicians records (photos, bio,
--   legislative data, compass stances all flow through automatically)
-- - Challengers: politician_id = NULL; carry their own name/photo fields (D-05)
--
-- NO party fields on candidates. Party context for primaries lives on the
-- RACE (races.primary_party), not on individual candidates. See antipartisan
-- rationale above. This exclusion is enforced at the schema layer.
-- =============================================================================

CREATE TABLE IF NOT EXISTS essentials.race_candidates (
  id               uuid        NOT NULL DEFAULT uuid_generate_v4(),
  race_id          uuid        NOT NULL
                   REFERENCES essentials.races(id) ON DELETE CASCADE,
  politician_id    uuid                                    -- NULL for challengers per D-05; incumbents link to existing records
                   REFERENCES essentials.politicians(id),
  full_name        text        NOT NULL,                   -- denormalized for challengers without a politician record
  first_name       text,
  last_name        text,
  photo_url        text,                                   -- for challengers without a politician record
  is_incumbent     boolean     NOT NULL DEFAULT false,
  candidate_status text        NOT NULL DEFAULT 'active'   -- active=on ballot, filed=early-stage unconfirmed, withdrawn=removed (D-06)
                   CHECK (candidate_status IN ('active','withdrawn','filed')),
  last_verified_at timestamptz,                            -- data freshness tracking
  source           text,                                   -- data origin: sos_excel | county_clerk | manual
  external_id      text,                                   -- SoS filing ID if available
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT race_candidates_pkey PRIMARY KEY (id)
  -- NO party_name, party_affiliation, or partisan fields. See antipartisan rationale above.
);

-- =============================================================================
-- Step 4: Indexes for query performance
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_elections_election_date
  ON essentials.elections(election_date);

CREATE INDEX IF NOT EXISTS idx_elections_state
  ON essentials.elections(state);

CREATE INDEX IF NOT EXISTS idx_races_election_id
  ON essentials.races(election_id);

CREATE INDEX IF NOT EXISTS idx_races_office_id
  ON essentials.races(office_id);

-- Partial index: only index rows where primary_party is set (primary elections)
CREATE INDEX IF NOT EXISTS idx_races_primary_party
  ON essentials.races(primary_party)
  WHERE primary_party IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_race_candidates_race_id
  ON essentials.race_candidates(race_id);

-- Partial index: only index rows where politician_id is set (incumbents)
CREATE INDEX IF NOT EXISTS idx_race_candidates_politician_id
  ON essentials.race_candidates(politician_id)
  WHERE politician_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_race_candidates_status
  ON essentials.race_candidates(candidate_status);

-- Partial unique index: enforce SoS filing ID uniqueness only when present
CREATE UNIQUE INDEX IF NOT EXISTS idx_race_candidates_external_id
  ON essentials.race_candidates(external_id)
  WHERE external_id IS NOT NULL;

-- =============================================================================
-- ISOLATION WARNING
--
-- WARNING: race_candidates must NEVER be joined into the geofence search path
-- (getRepresentativesByAddress). The politician_id FK exists for incumbent
-- linking only. Candidate records are served via separate election-specific
-- endpoints (Phase 99).
-- =============================================================================

COMMIT;
