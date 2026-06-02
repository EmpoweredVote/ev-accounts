-- =============================================================================
-- PATCH: Utah school district board member contacts
--
-- Districts covered:
--   1. Box Elder School District (besd.net) — Stephanie DeFilippis
--   2. Provo City School District (provo.edu) — 7 board members
--   3. Weber School District (wsd.net) — 7 board members
--
-- Notes:
--   - Box Elder and Weber do not publish individual member emails or phones;
--     only the district board page URL is stored.
--   - Provo publishes emails for 4 of 7 members (Emily Harrison, Lisa Boyce,
--     and Megan Van Wagenen were not found in any indexed source).
--   - Phone (801) 374-4805 is the Provo district main line shared by all members.
--
-- Sources: besd.net, provo.edu (via utah.gov public body registry), wsd.net
--          Verified 2026-06-01
-- Idempotent: all inserts guarded by WHERE NOT EXISTS (politician_id, contact_type)
-- =============================================================================

BEGIN;

-- =============================================================================
-- SECTION 1: Box Elder School District
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, email, phone)
SELECT id, 'manual', 'primary', url, email, phone FROM (VALUES
  ('74cc4f89-eb43-4413-b964-277da7fd7549'::uuid, 'https://www.besd.net/o/besd/page/board-of-education', NULL, NULL) -- Stephanie DeFilippis
) AS v(id, url, email, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- =============================================================================
-- SECTION 2: Provo City School District
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, email, phone)
SELECT id, 'manual', 'primary', url, email, phone FROM (VALUES
  ('7e25bb14-7369-469e-8e70-9efc9c8ff0da'::uuid, 'https://provo.edu/board-of-education/contact-your-board-representative/', NULL,                  NULL           ), -- Emily Harrison
  ('cf3373d3-3694-4993-a3fb-723bb3402893'::uuid, 'https://provo.edu/board-of-education/contact-your-board-representative/', 'ginah@provo.edu',      '801-374-4805' ), -- Gina Hales
  ('c094510c-c61a-48d0-8ecf-75507452939e'::uuid, 'https://provo.edu/board-of-education/contact-your-board-representative/', 'jenniferpa@provo.edu', '801-374-4805' ), -- Jennifer Partridge
  ('7c457a73-3e59-43cf-a88f-42cd6e104060'::uuid, 'https://provo.edu/board-of-education/contact-your-board-representative/', NULL,                  NULL           ), -- Lisa Boyce
  ('cc5d770d-c298-43f3-992c-c66ec773cfcf'::uuid, 'https://provo.edu/board-of-education/contact-your-board-representative/', NULL,                  NULL           ), -- Megan Van Wagenen
  ('79b453e3-6a30-44e0-9309-ac0e17cb4a2f'::uuid, 'https://provo.edu/board-of-education/contact-your-board-representative/', 'melanieh@provo.edu',  '801-374-4805' ), -- Melanie Hall
  ('df45ee8f-267b-4e97-9102-022c62d4311a'::uuid, 'https://provo.edu/board-of-education/contact-your-board-representative/', 'terim@provo.edu',     '801-374-4805' )  -- Teri McCabe
) AS v(id, url, email, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- =============================================================================
-- SECTION 3: Weber School District
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, email, phone)
SELECT id, 'manual', 'primary', url, email, phone FROM (VALUES
  ('64270b6a-8163-4a3e-9d7c-37d69c43e74e'::uuid, 'https://www.wsd.net/page/board-members/', NULL, NULL), -- Bruce Jardine
  ('f1a7a02b-0a73-44f2-bd60-4e2850e091e5'::uuid, 'https://www.wsd.net/page/board-members/', NULL, NULL), -- Douglas Hurst
  ('b93b1087-e304-4bbf-a57c-d2000682ef34'::uuid, 'https://www.wsd.net/page/board-members/', NULL, NULL), -- Jan Burrell
  ('9548e9ae-4762-4651-a864-2cae9f359ad2'::uuid, 'https://www.wsd.net/page/board-members/', NULL, NULL), -- Janis Christensen
  ('9399f6ca-53a0-41ce-875f-0a9c19c8437c'::uuid, 'https://www.wsd.net/page/board-members/', NULL, NULL), -- Kelly Larson
  ('af65e96b-5ada-4d2f-84bd-65f5e027e659'::uuid, 'https://www.wsd.net/page/board-members/', NULL, NULL), -- Paul Widdison
  ('ecb989f4-4d1a-46ae-a574-092be1740bfa'::uuid, 'https://www.wsd.net/page/board-members/', NULL, NULL)  -- Wyle Williams
) AS v(id, url, email, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

COMMIT;

-- =============================================================================
-- Verification
-- =============================================================================
-- SELECT p.full_name, pc.website_url, pc.email, pc.phone
-- FROM essentials.politician_contacts pc
-- JOIN essentials.politicians p ON p.id = pc.politician_id
-- WHERE pc.politician_id IN (
--   '74cc4f89-eb43-4413-b964-277da7fd7549',
--   '7e25bb14-7369-469e-8e70-9efc9c8ff0da',
--   'cf3373d3-3694-4993-a3fb-723bb3402893',
--   'c094510c-c61a-48d0-8ecf-75507452939e',
--   '7c457a73-3e59-43cf-a88f-42cd6e104060',
--   'cc5d770d-c298-43f3-992c-c66ec773cfcf',
--   '79b453e3-6a30-44e0-9309-ac0e17cb4a2f',
--   'df45ee8f-267b-4e97-9102-022c62d4311a',
--   '64270b6a-8163-4a3e-9d7c-37d69c43e74e',
--   'f1a7a02b-0a73-44f2-bd60-4e2850e091e5',
--   'b93b1087-e304-4bbf-a57c-d2000682ef34',
--   '9548e9ae-4762-4651-a864-2cae9f359ad2',
--   '9399f6ca-53a0-41ce-875f-0a9c19c8447c',
--   'af65e96b-5ada-4d2f-84bd-65f5e027e659',
--   'ecb989f4-4d1a-46ae-a574-092be1740bfa'
-- )
-- ORDER BY p.full_name;
