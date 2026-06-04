-- Migration 268: Add finance_summary JSONB column to essentials.politicians
-- Phase: 90 (campaign-finance-schema-ingestion-api)
-- Requirement: FINA-01
-- Target table: essentials.politicians
-- Rationale: Post-Phase-35 deduplication (migration 050), essentials.politicians is the
--   unified politician table read by GET /api/essentials/politicians via essentialsService.ts.
--   The column lives here (not on the legacy inform schema politician table) because
--   FINA-03 reads exclusively from this table via essentialsService.ts.
-- Idempotent: ADD COLUMN IF NOT EXISTS — safe to run twice with no side effects.
-- Applied via: mcp__supabase-local__execute_sql

ALTER TABLE essentials.politicians
  ADD COLUMN IF NOT EXISTS finance_summary JSONB;

COMMENT ON COLUMN essentials.politicians.finance_summary IS
  'Campaign finance summary from FEC. NULL means no finance data has been ingested for this
   politician — applies to all non-federal politicians and to federal politicians without a
   matched FEC candidate ID.

   Shape when populated:
     {
       total_raised: number,            -- float, total receipts from FEC candidates/totals endpoint for cycle
       top_donors: [                    -- up to 10 entries, sorted descending by amount; null/empty employer filtered out
         {
           employer: string,            -- FEC by_employer.employer string (e.g. "RETIRED", "NOT EMPLOYED")
           amount: number,              -- float, total dollar amount from this employer for the cycle
           count: number                -- integer, number of contributions from this employer
         }
       ],
       cycle: string,                   -- election cycle, e.g. "2026" (4-digit year string)
       source: "FEC"                    -- always the literal string "FEC" for data ingested by run-fec-finance-summary.ts
     }

   Populated by: backend/scripts/run-fec-finance-summary.ts (Phase 90, FINA-02).
   Surfaced by: essentialsService.ts getPoliticiansFlatList() + getPoliticianById() (Phase 90, FINA-03).
   No index: JSONB is read-only display data; not queried with WHERE clauses.';
