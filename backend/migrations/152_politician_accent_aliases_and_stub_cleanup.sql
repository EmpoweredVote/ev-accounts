-- Migration 152: Add accent/alternate-name aliases and remove empty context stubs
--
-- Three politicians have duplicate rows in essentials.politicians due to
-- accent/spelling variants (e.g. "Tony Cárdenas" vs "Tony Cardenas"). The
-- canonical rows (without accents) already have full stance data. The variant
-- rows accumulated empty politician_context stubs with no reasoning or sources.
--
-- This migration:
--   1. Adds aliases so lookups on the accented/alternate names resolve to the
--      canonical politician_id.
--   2. Deletes the empty context stubs from the orphan variant rows.

-- 1. Name aliases → canonical politician IDs
INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
VALUES
  -- Tony Cárdenas (accented) → Tony Cardenas (canonical bda8ce6a)
  ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c', 'Tony Cárdenas', 'accent-dedup'),
  -- Nanette Diaz Baragán (accented, middle name) → Nanette Barragan (canonical 6f5db776)
  ('6f5db776-afcb-40c3-87a5-83e9408d3044', 'Nanette Diaz Baragán', 'accent-dedup'),
  ('6f5db776-afcb-40c3-87a5-83e9408d3044', 'Nanette Barragán',     'accent-dedup'),
  -- Gil Cisneros (nickname) → Gilbert Cisneros (canonical 65f08851)
  ('65f08851-9336-4a38-a239-3f5bf3333095', 'Gil Cisneros',         'accent-dedup')
ON CONFLICT DO NOTHING;

-- 2. Delete empty context stubs from orphan variant rows
DELETE FROM inform.politician_context
WHERE politician_id IN (
  'ee52c1ec-85b8-486e-83ea-4fe337497486',  -- Tony Cárdenas (variant)
  '5bd54ac0-c8b9-486c-844c-ecc4313e5de7',  -- Nanette Diaz Baragán (variant)
  'be2943b7-f634-42f4-8ab8-15db8138169f'   -- Gil Cisneros (variant)
)
AND (reasoning = '' OR reasoning IS NULL);
