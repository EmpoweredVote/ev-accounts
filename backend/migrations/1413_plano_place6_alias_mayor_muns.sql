-- =============================================================================
-- Migration 1413: Plano "Council Place 6" alias → Mayor John B. Muns
-- (Phase 220 follow-up — operator-approved 2026-07-24)
--
-- Plano numbers the Mayor as "Place 6" (research: Wikipedia/Ballotpedia; plano.gov
-- JS-blocked, MEDIUM confidence). There is no separate Place-6 councilmember — the
-- 8 council members occupy Places 1-8 with the Mayor holding Place 6. The DB
-- double-models this as a distinct "Mayor" office plus a phantom VACANT "Council
-- Place 6". Per operator decision, ALIAS the Place 6 office to Muns rather than
-- remove it.
--
-- INTENTIONAL ALIAS — NOT a half-seated bug: offices.politician_id for Place 6 is
-- set to Muns, but Muns.office_id stays on his primary Mayor office. A future
-- reciprocal-FK / half-seated scan will see Place 6 as a mismatch; that is expected
-- here and must NOT be "corrected" by reseating. (Confirm against plano.gov via a
-- Playwright/operator pass when the Plano GAP is resolved.)
--
-- Idempotent: only sets Place 6 when it is currently unset / not already Muns.
-- =============================================================================

BEGIN;

UPDATE essentials.offices
   SET politician_id = '5584e869-4a54-4a68-a3c8-c14db45a71c5'  -- John B. Muns (Plano Mayor)
 WHERE id = '02e9e43b-7f65-4443-812b-4b4eb303e40f'             -- Plano Council Place 6 office
   AND politician_id IS DISTINCT FROM '5584e869-4a54-4a68-a3c8-c14db45a71c5';

COMMIT;
