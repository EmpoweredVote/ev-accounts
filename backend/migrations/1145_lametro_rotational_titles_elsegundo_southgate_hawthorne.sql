-- 1145: Rotational leadership titles for 3 LA-metro cities (title-on-seat pattern, per mig 1144 WeHo)
-- Verified on official city sites 2026-07-01:
--   El Segundo (elsegundo.gov): Mayor Chris Pimentel + Mayor Pro Tem Ryan Baldino (selected Dec 2024)
--   South Gate (cityofsouthgate.org): Mayor Joshua Barron + Vice Mayor Al Rios (rotated ~May 2026)
--   Hawthorne (cityofhawthorne.org): Mayor Pro Tem Faye Johnson (Mayor Vargas already titled in DB)

-- El Segundo
UPDATE essentials.offices SET title = 'Mayor'
WHERE id = '59d5c544-b06f-457b-96ed-83be5667ca87'  -- Chris Pimentel 1c77d036
  AND title = 'Council Member';
UPDATE essentials.offices SET title = 'Mayor Pro Tem'
WHERE id = '58ef6bf2-8771-437a-bb03-200a64edc856'  -- Ryan Baldino eb515636
  AND title = 'Council Member';

-- South Gate
UPDATE essentials.offices SET title = 'Mayor'
WHERE id = '94d93446-689e-469e-a39d-302ef3588c3d'  -- Joshua Barron e109a1be
  AND title = 'Council Member';
UPDATE essentials.offices SET title = 'Vice Mayor'
WHERE id = '518ac3d2-01ef-49a0-99e2-1864c7fa3663'  -- Al Rios 8247e088
  AND title = 'Council Member';

-- Hawthorne
UPDATE essentials.offices SET title = 'Mayor Pro Tem'
WHERE id = '8e8cea85-b675-417a-890e-1ceae5e31f3a'  -- Faye Johnson e44eb637
  AND title = 'Council Member';
