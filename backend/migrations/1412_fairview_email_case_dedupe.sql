-- =============================================================================
-- Migration 1412: Fairview email case-variant dedupe (3 officials)
-- (Phase 220 follow-up — 2026-07-24)
--
-- Mig 1407 appended the RESEARCH-sourced mixed-case Fairview emails, but 3 members
-- already carried a lowercase variant of the SAME address from a prior phase, leaving
-- a case-duplicate array (e.g. ['jhawkins@fairviewtexas.org','JHawkins@FairviewTexas.org']).
-- Collapse each to the single mixed-case form (matching Fairview's other members).
-- Idempotent: only rewrites rows whose array still contains >1 entry.
-- =============================================================================

BEGIN;

UPDATE essentials.politicians SET email_addresses = ARRAY['JHawkins@FairviewTexas.org']
 WHERE id = 'c97ba2a3-d56e-4ecc-aa7d-c5d009c9312c'
   AND array_length(email_addresses,1) > 1;

UPDATE essentials.politicians SET email_addresses = ARRAY['Mayor@FairviewTexas.org']
 WHERE full_name = 'John Hubbard'
   AND email_addresses @> ARRAY['mayor@fairviewtexas.org']
   AND array_length(email_addresses,1) > 1;

UPDATE essentials.politicians SET email_addresses = ARRAY['PSheehan@FairviewTexas.org']
 WHERE full_name = 'Pat Sheehan'
   AND email_addresses @> ARRAY['psheehan@fairviewtexas.org']
   AND array_length(email_addresses,1) > 1;

COMMIT;
