-- Migration 117: LA Superior Court June 2026 contested races + challengers + LACBA ratings
--
-- Seeds 11 contested Superior Court races for the June 3, 2026 LA County Primary.
-- Creates 25 challenger politician records (attorneys not yet in DB).
-- Links all candidates (25 challengers + 3 incumbents) to their races via race_candidates.
-- Inserts LACBA JEEC ratings for all 28 rated candidates.
-- Inserts "Not evaluated" LACBA entries for 4 City Attorney candidates.
--
-- Election: 2026 LA County Primary (2026-06-03), election_id = 1ebca37f-cf96-47f4-bc2b-47ef266721fe
-- Source: LACBA 2026 JEEC Ratings (EIN Presswire mirror)
--   https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings
--
-- Incumbent judges already in DB:
--   Robert S. Draper:   fa932212-a2cf-4fa1-97ab-c6619e3db610  (Office 2)
--   David B. Walgren:   1ce3f260-d267-4569-993b-47f8dd8b0842  (Office 81)
--   Patrick Connolly:   53fd1ed7-b8f2-4c0b-a973-3592e4457472  (Office 116)
--
-- City Attorney candidates already in DB (hardcoded IDs):
--   Hydee Feldstein Soto: 3f90952e-7d1b-413d-a0e1-e319fb23fa05
--   Aida Ashouri:         0f6484bd-2fc1-4071-9648-d7b8a950d29c
--   John McKinney:        6cd2e87b-7366-429a-a049-990751bd647f
--   Marissa Roy:          7157dd95-0f1b-4e05-bd4f-39317345b47c
--
-- Idempotent: all sections use ON CONFLICT DO NOTHING guards.

BEGIN;

-- =============================================================================
-- SECTION 1: Insert 11 contested Superior Court races
-- =============================================================================

INSERT INTO essentials.races (election_id, office_id, position_name, seats)
VALUES
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 2',   1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 14',  1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 64',  1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 65',  1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 66',  1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 81',  1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 87',  1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 116', 1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 131', 1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 176', 1),
  ('1ebca37f-cf96-47f4-bc2b-47ef266721fe', NULL, 'LA Superior Court Office 181', 1)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- =============================================================================
-- SECTION 2: Create politician records for 25 challengers
-- =============================================================================

-- Office 2
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Tal K. Valbuena', 'Tal', 'Valbuena',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 14
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Angie Christides', 'Angie', 'Christides',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Irene Lee', 'Irene', 'Lee',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 64
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Francisco Amador', 'Francisco', 'Amador',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Maria Ghobadi', 'Maria', 'Ghobadi',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Rhonda A. Haymon', 'Rhonda', 'Haymon',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 65
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Justin Allen Clayton', 'Justin', 'Clayton',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Chellei G. Jimenez', 'Chellei', 'Jimenez',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Samuel Wolloch Krause', 'Samuel', 'Krause',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Anna Slotky Reitano', 'Anna', 'Reitano',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 66
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Ben Forer', 'Ben', 'Forer',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Cheryl C. Turner', 'Cheryl', 'Turner',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 81
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Dan Kapelovitz', 'Dan', 'Kapelovitz',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 87
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Anthony (A.J.) Bayne', 'Anthony', 'Bayne',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'David DeJute', 'David', 'DeJute',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Sharee Sanders Gordon', 'Sharee', 'Gordon',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 116
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Paul A. Thompson', 'Paul', 'Thompson',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 131
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Carlos Dammeier', 'Carlos', 'Dammeier',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'David Ross', 'David', 'Ross',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Troy W. Slaten', 'Troy', 'Slaten',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Donna Tryfman', 'Donna', 'Tryfman',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 176
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Gloria Marin', 'Gloria', 'Marin',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Zachary Smith', 'Zachary', 'Smith',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- Office 181
INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Ryan Dibble', 'Ryan', 'Dibble',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

INSERT INTO essentials.politicians (
  full_name, first_name, last_name,
  is_active, is_incumbent, data_source
) VALUES (
  'Thanayi Lindsey', 'Thanayi', 'Lindsey',
  true, false, 'LACBA 2026 JEEC Ratings'
) ON CONFLICT DO NOTHING;

-- =============================================================================
-- SECTION 3: Link candidates to races via race_candidates
-- =============================================================================

-- NOTE: race_candidates has no simple UNIQUE constraint to use ON CONFLICT (col) DO NOTHING.
-- Use WHERE NOT EXISTS to guard idempotency.

-- ---- Office 2 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 2'
  AND p.full_name = 'Tal K. Valbuena'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, 'fa932212-a2cf-4fa1-97ab-c6619e3db610'::uuid, 'Robert S. Draper', 'Robert', 'Draper', true, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 2'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = 'fa932212-a2cf-4fa1-97ab-c6619e3db610'::uuid
  );

-- ---- Office 14 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 14'
  AND p.full_name = 'Angie Christides'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 14'
  AND p.full_name = 'Irene Lee'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

-- ---- Office 64 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 64'
  AND p.full_name = 'Francisco Amador'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 64'
  AND p.full_name = 'Maria Ghobadi'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 64'
  AND p.full_name = 'Rhonda A. Haymon'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

-- ---- Office 65 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 65'
  AND p.full_name = 'Justin Allen Clayton'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 65'
  AND p.full_name = 'Chellei G. Jimenez'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 65'
  AND p.full_name = 'Samuel Wolloch Krause'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 65'
  AND p.full_name = 'Anna Slotky Reitano'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

-- ---- Office 66 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 66'
  AND p.full_name = 'Ben Forer'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 66'
  AND p.full_name = 'Cheryl C. Turner'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

-- ---- Office 81 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 81'
  AND p.full_name = 'Dan Kapelovitz'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '1ce3f260-d267-4569-993b-47f8dd8b0842'::uuid, 'David B. Walgren', 'David', 'Walgren', true, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 81'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = '1ce3f260-d267-4569-993b-47f8dd8b0842'::uuid
  );

-- ---- Office 87 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 87'
  AND p.full_name = 'Anthony (A.J.) Bayne'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 87'
  AND p.full_name = 'David DeJute'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 87'
  AND p.full_name = 'Sharee Sanders Gordon'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

-- ---- Office 116 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 116'
  AND p.full_name = 'Paul A. Thompson'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '53fd1ed7-b8f2-4c0b-a973-3592e4457472'::uuid, 'Patrick Connolly', 'Patrick', 'Connolly', true, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 116'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = '53fd1ed7-b8f2-4c0b-a973-3592e4457472'::uuid
  );

-- ---- Office 131 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 131'
  AND p.full_name = 'Carlos Dammeier'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 131'
  AND p.full_name = 'David Ross'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 131'
  AND p.full_name = 'Troy W. Slaten'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 131'
  AND p.full_name = 'Donna Tryfman'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

-- ---- Office 176 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 176'
  AND p.full_name = 'Gloria Marin'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 176'
  AND p.full_name = 'Zachary Smith'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

-- ---- Office 181 ----
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 181'
  AND p.full_name = 'Ryan Dibble'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active',
  'LACBA 2026 JEEC Ratings / https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.races r, essentials.politicians p
WHERE r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA Superior Court Office 181'
  AND p.full_name = 'Thanayi Lindsey'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id
  );

-- =============================================================================
-- SECTION 4: LACBA judicial_evaluations — 28 rated candidates + 4 City Attorney "not evaluated"
-- =============================================================================

-- ---- Office 2 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
VALUES (
  'fa932212-a2cf-4fa1-97ab-c6619e3db610',
  'LACBA JEEC', 'Not Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
) ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Tal K. Valbuena'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 14 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Angie Christides'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Well Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Irene Lee'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 64 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Not Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Francisco Amador'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Well Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Maria Ghobadi'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Rhonda A. Haymon'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 65 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Justin Allen Clayton'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Chellei G. Jimenez'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Samuel Wolloch Krause'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Anna Slotky Reitano'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 66 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Well Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Ben Forer'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Cheryl C. Turner'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 81 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Dan Kapelovitz'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
VALUES (
  '1ce3f260-d267-4569-993b-47f8dd8b0842',
  'LACBA JEEC', 'Exceptionally Well Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
) ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 87 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Well Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Anthony (A.J.) Bayne'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'David DeJute'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Sharee Sanders Gordon'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 116 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
VALUES (
  '53fd1ed7-b8f2-4c0b-a973-3592e4457472',
  'LACBA JEEC', 'Well Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
) ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Paul A. Thompson'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 131 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Carlos Dammeier'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'David Ross'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Troy W. Slaten'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Donna Tryfman'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 176 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Well Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Gloria Marin'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Zachary Smith'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- Office 181 ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Well Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Ryan Dibble'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
SELECT p.id, 'LACBA JEEC', 'Not Qualified', '2026-01-01',
  'https://www.einpresswire.com/article/907838894/lacba-judicial-elections-evaluation-committee-announces-2026-ratings'
FROM essentials.politicians p WHERE p.full_name = 'Thanayi Lindsey'
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

-- ---- City Attorney candidates: "Not evaluated" ----
INSERT INTO essentials.judicial_evaluations (politician_id, source, rating, rating_date, source_url)
VALUES
  ('3f90952e-7d1b-413d-a0e1-e319fb23fa05', 'LACBA JEEC', 'Not evaluated — office not covered by LACBA JEEC', '2026-01-01', 'https://www.lacba.org'),
  ('0f6484bd-2fc1-4071-9648-d7b8a950d29c', 'LACBA JEEC', 'Not evaluated — office not covered by LACBA JEEC', '2026-01-01', 'https://www.lacba.org'),
  ('6cd2e87b-7366-429a-a049-990751bd647f', 'LACBA JEEC', 'Not evaluated — office not covered by LACBA JEEC', '2026-01-01', 'https://www.lacba.org'),
  ('7157dd95-0f1b-4e05-bd4f-39317345b47c', 'LACBA JEEC', 'Not evaluated — office not covered by LACBA JEEC', '2026-01-01', 'https://www.lacba.org')
ON CONFLICT (politician_id, source, rating_date) DO NOTHING;

COMMIT;
