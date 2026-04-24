-- =============================================================================
-- Migration 070: Discovery pipeline storage layer — v2.1 Claude Candidate Discovery
--
-- This migration adds three tables that form the storage backbone for the
-- v2.1 automated candidate discovery system. Each election cycle, a scheduled
-- agent (powered by Claude + web search) scrapes jurisdiction election sites
-- and proposes candidate additions or withdrawal diffs for admin review before
-- any changes land in essentials.race_candidates.
--
-- Three tables:
--
--   discovery_jurisdictions — registry of discoverable places; one row per
--     (jurisdiction_geoid, election_date) pair. Stores the source URL(s) the
--     agent is allowed to consult (allowed_domains) and human-readable metadata.
--
--   discovery_runs — one row per agent invocation. Created with status='running'
--     BEFORE the agent starts so that the run is tracked even if it crashes.
--     raw_output is populated after the agent returns and captures the full
--     Claude response for audit purposes.
--     Shape of raw_output JSONB:
--       { model, input_tokens, output_tokens,
--         candidates: [{ full_name, citation_url, race_hint }],
--         errors?: [] }
--
--   candidate_staging — one row per discovered candidate or withdrawal diff,
--     pending admin review. Rows are never auto-applied to race_candidates
--     (auto-upsert deferred to Phase 7 until confidence scoring is validated
--     against real data). Each row MUST have a citation_url (hallucination
--     prevention) and a confidence level.
--
-- Creation order matters: discovery_runs must be created BEFORE candidate_staging
-- because candidate_staging.run_id is a FK to discovery_runs.id.
--
-- NOTE on jurisdiction_geoid: there is NO essentials.jurisdictions table in this
-- codebase. The schema uses jurisdiction_geoid text columns by convention across
-- adminService, roleService, and stanceService. Do NOT add a FK to a non-existent
-- jurisdictions table — store jurisdiction_geoid text directly.
--
-- All CREATE TABLE statements use IF NOT EXISTS for idempotency (safe to re-run).
-- All CREATE INDEX statements use IF NOT EXISTS for idempotency.
-- No CREATE INDEX CONCURRENTLY — these standard indexes must run inside the
-- transaction block.
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: essentials.discovery_jurisdictions
--
-- Registry of (jurisdiction, election_date) pairs the discovery pipeline is
-- configured to scan. source_url is the canonical election results page for
-- the jurisdiction. allowed_domains restricts which domains the agent may
-- fetch during a run (safety guardrail against prompt-injection via unexpected
-- redirects).
--
-- The unique index on (jurisdiction_geoid, election_date) prevents duplicate
-- registrations for the same jurisdiction+cycle combination.
-- =============================================================================

CREATE TABLE IF NOT EXISTS essentials.discovery_jurisdictions (
  id                  uuid          NOT NULL DEFAULT uuid_generate_v4(),
  jurisdiction_geoid  text          NOT NULL,
  jurisdiction_name   text          NOT NULL,                -- human-readable, e.g. "Los Angeles County, CA"
  state               character(2)  NOT NULL,                -- ISO 3166-2 state code, e.g. 'CA', 'IN'
  election_date       date          NOT NULL,                -- the election this jurisdiction entry is scoped to
  source_url          text,                                  -- canonical election results/filing page for the agent to start from
  allowed_domains     text[],                                -- domains the agent may fetch; NULL = no restriction (use with caution)
  created_at          timestamptz   NOT NULL DEFAULT now(),
  updated_at          timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT discovery_jurisdictions_pkey PRIMARY KEY (id)
);

-- Prevent duplicate registrations for the same jurisdiction + election cycle
CREATE UNIQUE INDEX IF NOT EXISTS idx_discovery_jurisdictions_geoid_date
  ON essentials.discovery_jurisdictions (jurisdiction_geoid, election_date);

-- =============================================================================
-- Step 2: essentials.discovery_runs
--
-- One row per agent invocation. A row is INSERT-ed with status='running' and
-- raw_output=NULL before the Claude agent starts — this ensures every run is
-- tracked even if the process crashes before returning a result. The agent
-- updates completed_at, candidates_found/new/withdrawn, and raw_output on
-- completion (status='completed') or sets error_message on failure (status='failed').
--
-- raw_output JSONB shape (documented here for reference):
--   {
--     "model": "claude-3-5-sonnet-20241022",
--     "input_tokens": 1234,
--     "output_tokens": 567,
--     "candidates": [
--       { "full_name": "Jane Smith", "citation_url": "https://...", "race_hint": "City Council District 3" }
--     ],
--     "errors": []           -- optional; present only when partial errors occurred
--   }
--
-- raw_output is NOT NULL-constrained because the row is created before the
-- agent returns. Applying NOT NULL would require a two-step insert/update.
-- =============================================================================

CREATE TABLE IF NOT EXISTS essentials.discovery_runs (
  id                        uuid        NOT NULL DEFAULT uuid_generate_v4(),
  discovery_jurisdiction_id uuid        NOT NULL
                            REFERENCES essentials.discovery_jurisdictions(id) ON DELETE CASCADE,
  jurisdiction_geoid        text        NOT NULL,            -- denormalized for fast filtering without join
  election_date             date        NOT NULL,            -- denormalized for fast filtering without join
  status                    text        NOT NULL DEFAULT 'running'
                            CHECK (status IN ('running','completed','failed')),
  started_at                timestamptz NOT NULL DEFAULT now(),
  completed_at              timestamptz,                     -- NULL until run finishes or fails
  candidates_found          int         NOT NULL DEFAULT 0,  -- total candidates the agent returned (new + withdrawn)
  candidates_new            int         NOT NULL DEFAULT 0,  -- subset with action='new'
  candidates_withdrawn      int         NOT NULL DEFAULT 0,  -- subset with action='withdrawal'
  error_message             text,                            -- populated on status='failed'
  raw_output                jsonb,                           -- NULL until agent returns; shape documented in header comment above
  triggered_by              text,                            -- 'cron' | 'manual' | email address of admin who triggered

  CONSTRAINT discovery_runs_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS idx_discovery_runs_jurisdiction_started
  ON essentials.discovery_runs (discovery_jurisdiction_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_discovery_runs_status
  ON essentials.discovery_runs (status);

-- =============================================================================
-- Step 3: essentials.candidate_staging
--
-- One row per candidate the agent discovered (action='new') or flagged as
-- withdrawn (action='withdrawal'). Admin reviews each row and sets
-- status='approved' or status='dismissed'. Approved rows are then manually
-- applied to essentials.race_candidates (auto-upsert deferred to Phase 7).
--
-- Mandatory fields for every staging row:
--   - citation_url  (NOT NULL) — URL that proves the candidate exists; rows
--                                without a source are not created (hallucination
--                                prevention enforced in discoveryService.ts)
--   - confidence    (NOT NULL) — one of 'official' (SoS filing), 'matched'
--                                (local news / candidate site), 'uncertain'
--
-- FK chain: candidate_staging → discovery_runs → discovery_jurisdictions.
-- ON DELETE CASCADE means cleaning up a discovery_jurisdiction row removes
-- all its runs and all staging rows automatically.
--
-- race_id and matched_candidate_id are nullable: the agent proposes candidates
-- but matching to existing race/candidate records is done by the approval
-- workflow in discoveryService.ts. If no matching race exists, flagged=true
-- with flag_reason='no matching race in DB'.
-- =============================================================================

CREATE TABLE IF NOT EXISTS essentials.candidate_staging (
  id                        uuid        NOT NULL DEFAULT uuid_generate_v4(),
  run_id                    uuid        NOT NULL
                            REFERENCES essentials.discovery_runs(id) ON DELETE CASCADE,
  discovery_jurisdiction_id uuid        NOT NULL
                            REFERENCES essentials.discovery_jurisdictions(id) ON DELETE CASCADE,
  full_name                 text        NOT NULL,
  normalized_name           text        NOT NULL,            -- lowercased, whitespace-collapsed; used for Levenshtein dedup
  citation_url              text        NOT NULL,            -- mandatory source URL; no citation = no row (hallucination prevention)
  race_hint                 text        NOT NULL,            -- agent-provided race description, e.g. "City Council District 3"
  race_id                   uuid        REFERENCES essentials.races(id),             -- NULL until matched by approval workflow
  matched_candidate_id      uuid        REFERENCES essentials.race_candidates(id),   -- NULL until matched; used for withdrawal action
  confidence                text        NOT NULL
                            CHECK (confidence IN ('official','matched','uncertain')),
  action                    text        NOT NULL DEFAULT 'new'
                            CHECK (action IN ('new','withdrawal')),
  flagged                   boolean     NOT NULL DEFAULT false,
  flag_reason               text,                            -- e.g. 'no matching race in DB', 'duplicate normalized_name'
  status                    text        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending','approved','dismissed')),
  dismissed_reason          text,                            -- admin note when dismissing
  reviewed_at               timestamptz,                     -- when admin approved or dismissed
  reviewed_by               text,                            -- admin email address
  created_at                timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT candidate_staging_pkey PRIMARY KEY (id)
);

-- Primary lookup: all staging rows for a given run
CREATE INDEX IF NOT EXISTS idx_candidate_staging_run_id
  ON essentials.candidate_staging (run_id);

-- Admin queue: fast retrieval of all pending rows across all runs
CREATE INDEX IF NOT EXISTS idx_candidate_staging_status_pending
  ON essentials.candidate_staging (status)
  WHERE status = 'pending';

-- Filter staging rows by jurisdiction (e.g., admin viewing a specific jurisdiction's queue)
CREATE INDEX IF NOT EXISTS idx_candidate_staging_jurisdiction
  ON essentials.candidate_staging (discovery_jurisdiction_id);

-- Flagged rows need separate admin attention; partial index keeps it cheap
CREATE INDEX IF NOT EXISTS idx_candidate_staging_flagged
  ON essentials.candidate_staging (flagged)
  WHERE flagged = true;

COMMIT;
