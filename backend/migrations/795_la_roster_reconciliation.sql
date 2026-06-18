-- Migration 774: Post-v15.0 LA roster reconciliation (Santa Monica + Whittier)
-- Fixes stale seed rosters surfaced during the v15.0 retrospective.
-- Decision (2026-06-16): UNLINK departed officials from council (delete/repoint office rows;
-- keep their politician + stance records). Add Whittier's two current members with stances (775/776).
--
-- Santa Monica: live council = 7 at-large seats; DB had 10 (3 surplus = terms ended Dec 2024):
--   Phil Brock, Oscar de la Torre, Christine Parra. Delete their surplus office rows.
-- Whittier: D1 + D3 occupants in DB are former members; repoint those offices to current members:
--   D1 Fernando Dutra -> Mary Ann Pacheco (Mayor Pro Tem, elected Apr 2024)
--   D3 Octavio Martinez -> Cathy Warner (re-elected 2024)
-- Becerra (Mayor), Santana (D2), Macedo (D4) are already current/correct.

BEGIN;

-- ===== Santa Monica: unlink 3 departed members =====
DELETE FROM essentials.offices WHERE id IN (
  '38b8ea40-55b1-4918-8044-a23406bc4954',  -- Phil Brock
  'eb6b176b-9226-4bd8-b73a-e8610bdb2056',  -- Oscar de la Torre
  '437ae39c-39c6-4a75-99f7-714ff273fe5c'   -- Christine Parra
);
-- Clear dangling office backlink on the 3 departed politicians (stances + politician rows kept)
UPDATE essentials.politicians SET office_id = NULL
WHERE id IN (
  '7714b7c6-9283-4ab8-802e-cbcfba5ddc96',  -- Brock
  '86e513e7-d0a7-4419-8edd-6113629d7998',  -- de la Torre
  '2d47a965-81a2-4508-865c-06d45bf6ff42'   -- Parra
);

-- ===== Whittier: install current District 1 + District 3 members =====
-- Create the two current members (Whittier ext_id block -700400..-700406)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, data_source, is_active, is_incumbent)
VALUES (-700405, 'Mary Ann Pacheco', 'Mary Ann', 'Pacheco', 'manual', 'v15.0-reconciliation', true, true);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, data_source, is_active, is_incumbent)
VALUES (-700406, 'Cathy Warner', 'Cathy', 'Warner', 'manual', 'v15.0-reconciliation', true, true);

-- Repoint existing D1 office (was Dutra) -> Pacheco, and D3 office (was Martinez) -> Warner
UPDATE essentials.offices SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -700405)
WHERE id = '0a91d027-5847-4eea-b9b7-1e9cd8988a30';  -- District 1
UPDATE essentials.offices SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -700406)
WHERE id = '9dea98b6-f127-49b4-af19-5d65d94efb97';  -- District 3

-- Backlink office_id on the new members
UPDATE essentials.politicians SET office_id = '0a91d027-5847-4eea-b9b7-1e9cd8988a30' WHERE external_id = -700405;
UPDATE essentials.politicians SET office_id = '9dea98b6-f127-49b4-af19-5d65d94efb97' WHERE external_id = -700406;

-- Unlink departed Dutra (D1) + Martinez (D3): keep politician + stance records, clear office backlink
UPDATE essentials.politicians SET office_id = NULL
WHERE external_id IN (-700401, -700403);

COMMIT;
