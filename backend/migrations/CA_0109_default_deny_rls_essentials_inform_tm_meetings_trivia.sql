BEGIN;

-- =============================================================================
-- CA_0109: default-deny RLS on flagged tables in essentials / inform /
--          transparent_motivations / meetings / trivia (+ tighten a stray
--          anon write grant on trivia.claim_fingerprints)
-- =============================================================================
-- Created 2026-09-10 with Chris Andrews. Steward slot CA_0109.
-- Source: CTO decision 0015 (ev-cto/knowledge/decisions/0015-rls-audit-2026-09.md),
--         watchlist #24. Founder decision 2026-09-10: "protect them all."
--
-- The four treasury.frozen_* tables and the four public.treasury_* function
-- revokes from the same decision live in the treasury-tracker repo
-- (supabase/migrations/), because treasury schema objects are owned there.
--
-- WHAT THIS DOES
-- Enables ROW LEVEL SECURITY, with NO policy, on 23 flagged tables. RLS-on with
-- no policy denies every row to any role that does not bypass RLS. This is
-- "default-deny": it clears the advisor `rls_disabled_in_public` finding and
-- removes direct anon/authenticated read access, adding defence in depth.
--
-- Also REVOKEs INSERT, UPDATE, DELETE, TRUNCATE on trivia.claim_fingerprints
-- from anon (measured 2026-09-10: anon held a,r,w,d,D,x,t,m on it — a stray write
-- grant). TRUNCATE is included on purpose: RLS does NOT govern TRUNCATE, so
-- default-deny alone would leave that one anon write path open.
--
-- WHY IT IS SAFE FOR THE BACKEND (measured live 2026-09-10, project
-- kxsdzaojfaibhuzmclfq)
-- Every role the platform uses to reach the database bypasses RLS:
--   postgres, service_role, ev_api, ctc_app, trivia_service  -> rolbypassrls = true
-- Only anon, authenticated, authenticator do NOT bypass. No flagged table forces
-- RLS (relforcerowsecurity = false everywhere), so even a table's owner is not
-- subject to the deny. Therefore default-deny blocks only direct
-- anon/authenticated reads through PostgREST — never the server.
-- A code grep across all EV repos (CTO decision 0015) found no frontend that
-- reads any of these tables directly via supabase-js.
--
-- OWNERSHIP NOTE
-- 22 of these 23 tables are owned by postgres. One,
-- transparent_motivations.fec_candidate_totals, is owned by ev_api. postgres is
-- a member of ev_api (verified 2026-09-10: pg_auth_members), so it holds owner
-- privileges on that table and ALTER succeeds. No SET ROLE needed.
--
-- SCHEMA REACH CONTEXT
-- essentials, transparent_motivations, meetings and trivia are NOT in
-- pgrst.db_schemas, so their tables are already unreachable from the public API;
-- default-deny is defence in depth there. inform IS exposed: inform.seasons is
-- readable by `authenticated` (not anon) today; after this, that read is denied.
--
-- IDEMPOTENT: ENABLE ROW LEVEL SECURITY on an already-enabled table is a no-op;
-- REVOKE of an absent privilege is a no-op. Safe to re-run.
--
-- REVERSAL: ALTER TABLE <t> DISABLE ROW LEVEL SECURITY;  (and, if ever needed,
-- GRANT INSERT, UPDATE, DELETE ON trivia.claim_fingerprints TO anon;)
-- =============================================================================

-- transparent_motivations (4) --------------------------------------------------
ALTER TABLE transparent_motivations.fec_candidate_cycles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.fec_ingest_window_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.fec_candidate_totals       ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.contribution_summary_agg   ENABLE ROW LEVEL SECURITY;

-- meetings (1) -----------------------------------------------------------------
ALTER TABLE meetings.event_races                               ENABLE ROW LEVEL SECURITY;

-- essentials reference + pipeline (11) -----------------------------------------
ALTER TABLE essentials.readrank_questions                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.readrank_race_topic_questions           ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.readrank_race_pipeline                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.office_terms                            ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.discovery_race_state                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.discovered_sources                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.district_county_overlap                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.gazetteer_places                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.gazetteer_counties                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.source_discovery_runs                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.source_outlets                          ENABLE ROW LEVEL SECURITY;

-- essentials cleanup-residue archives (5) — KEEP and protect (decision 0015 C) --
ALTER TABLE essentials._dedupe_1586_removed                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials._fabricated_1588_removed               ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials._fabricated_1590_removed               ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials._retired_1589_races                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials._retired_1589_candidates                ENABLE ROW LEVEL SECURITY;

-- inform (1) -------------------------------------------------------------------
ALTER TABLE inform.seasons                                     ENABLE ROW LEVEL SECURITY;

-- trivia (1) -------------------------------------------------------------------
ALTER TABLE trivia.claim_fingerprints                          ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON trivia.claim_fingerprints FROM anon;

-- =============================================================================
-- Post-verify gate — fail loudly if any target is not protected.
-- =============================================================================
DO $$
DECLARE
  rel      text;
  missing  int := 0;
  targets  text[] := ARRAY[
    'transparent_motivations.fec_candidate_cycles',
    'transparent_motivations.fec_ingest_window_progress',
    'transparent_motivations.fec_candidate_totals',
    'transparent_motivations.contribution_summary_agg',
    'meetings.event_races',
    'essentials.readrank_questions',
    'essentials.readrank_race_topic_questions',
    'essentials.readrank_race_pipeline',
    'essentials.office_terms',
    'essentials.discovery_race_state',
    'essentials.discovered_sources',
    'essentials.district_county_overlap',
    'essentials.gazetteer_places',
    'essentials.gazetteer_counties',
    'essentials.source_discovery_runs',
    'essentials.source_outlets',
    'essentials._dedupe_1586_removed',
    'essentials._fabricated_1588_removed',
    'essentials._fabricated_1590_removed',
    'essentials._retired_1589_races',
    'essentials._retired_1589_candidates',
    'inform.seasons',
    'trivia.claim_fingerprints'
  ];
BEGIN
  IF array_length(targets, 1) <> 23 THEN
    RAISE EXCEPTION 'CA_0109: expected 23 targets, listed %', array_length(targets, 1);
  END IF;

  FOREACH rel IN ARRAY targets LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = split_part(rel, '.', 1)
        AND c.relname = split_part(rel, '.', 2)
        AND c.relrowsecurity
    ) THEN
      missing := missing + 1;
      RAISE WARNING 'CA_0109: RLS NOT enabled on %', rel;
    END IF;
  END LOOP;

  IF missing > 0 THEN
    RAISE EXCEPTION 'CA_0109: % of 23 tables did not get RLS enabled', missing;
  END IF;

  IF has_table_privilege('anon', 'trivia.claim_fingerprints', 'INSERT')
     OR has_table_privilege('anon', 'trivia.claim_fingerprints', 'UPDATE')
     OR has_table_privilege('anon', 'trivia.claim_fingerprints', 'DELETE')
     OR has_table_privilege('anon', 'trivia.claim_fingerprints', 'TRUNCATE') THEN
    RAISE EXCEPTION 'CA_0109: anon still holds a write grant on trivia.claim_fingerprints';
  END IF;

  RAISE NOTICE 'CA_0109 OK — 23 tables default-deny RLS; anon write grant cleared on trivia.claim_fingerprints';
END $$;

COMMIT;
