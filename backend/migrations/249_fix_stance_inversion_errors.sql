-- Migration 249: Fix 9 individual stance inversion errors in politician_answers
-- Identified during 2026-06-01 audit of inversion-trap topics.
-- Each correction moves the politician to the stance text that matches their documented public record.
-- Politician IDs and topic IDs are stable UUIDs — do not change.

-- Micah Beckwith (R-IN): school-vouchers 1→5
-- Strongly pro-voucher conservative; was wrongly placed at stance 1 ("eliminate vouchers/fund public schools").
-- Correct stance 5 = "universal vouchers so education funding follows the student."
UPDATE inform.politician_answers
SET value = 5
WHERE politician_id = '929346a2-8037-4b14-af33-4820eb365323'
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

-- Ashley Hinson (R-IA): school-vouchers 1→4
-- Supports school choice; was wrongly placed at stance 1 ("eliminate vouchers/fund public schools").
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

-- Jeff Gonzalez (R-CA): trans-athletes 1→4
-- Republican politician; was wrongly placed at stance 1 ("allow all trans athletes without restrictions").
-- Correct stance 4 = supports restrictions on trans athlete participation.
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';

-- Alex Vindman (D): fossil-fuels 4→2
-- Progressive Democrat who opposes fossil fuel expansion; was wrongly placed at stance 4 (leans toward maximize extraction).
UPDATE inform.politician_answers
SET value = 2
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

-- Alex Vindman (D): school-vouchers 4→1
-- Progressive Democrat who supports public education; was wrongly placed at stance 4 (leans pro-voucher).
-- Correct stance 1 = "fully fund public schools and eliminate voucher programs."
UPDATE inform.politician_answers
SET value = 1
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

-- Angie Nixon (D-FL): fossil-fuels 4→2
-- Progressive Democrat who supports clean energy; was wrongly placed at stance 4 (leans toward maximize extraction).
UPDATE inform.politician_answers
SET value = 2
WHERE politician_id = '0ac89151-2b8d-4430-b9bd-3a80bef3413b'
  AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

-- Patrick M. O'Connor (R): fossil-fuels 2→4
-- Republican politician; was wrongly placed at stance 2 (leans toward banning drilling).
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = 'e1f72270-5809-4d0e-969c-48d1ab34fbdc'
  AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

-- Alexandra M. Macedo (R): fossil-fuels 2→4
-- Republican politician; was wrongly placed at stance 2 (leans toward banning drilling).
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = '8566674a-3a3b-4c88-bba0-c9f42e4ff810'
  AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

-- Alexandra M. Macedo (R): deportation 2→4
-- Republican politician; was wrongly placed at stance 2 (leans against deportation enforcement).
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = '8566674a-3a3b-4c88-bba0-c9f42e4ff810'
  AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
