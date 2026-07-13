-- 1330: compass lenses — add per-office auto-apply mapping + seed Federal & Judicial lenses.
-- (Applied to prod on 2026-07-12 under the name 1329 via MCP before the Palm Springs
--  migration claimed 1329; renumbered to 1330 here to resolve the file-name collision.)
--
-- The inform.compass_lenses / compass_lens_topics tables already existed in the
-- database but were never tracked by a migration and only had the Local lens
-- seeded. This migration is the first tracked touch: it adds the auto_district_types
-- column (drives per-office lens defaults) and seeds the Federal and Judicial lenses.
-- Additive + idempotent (safe to re-run).

alter table inform.compass_lenses add column if not exists auto_district_types text[];

-- Upsert the three lenses (Local already exists; Federal & Judicial are new).
-- On conflict we only set auto_district_types so we never clobber an existing copy.
insert into inform.compass_lenses (key, name, description, color, icon, is_active, auto_district_types) values
  ('local',    'Local Lens',    '8 questions most local candidates have already answered',               '#5A9A6E', 'building', true, array['LOCAL','LOCAL_EXEC','COUNTY','SCHOOL']),
  ('federal',  'Federal Lens',  '8 issues most U.S. House & Senate members and candidates have answered', '#1E3A5F', 'capitol',  true, array['NATIONAL_EXEC','NATIONAL_UPPER','NATIONAL_LOWER']),
  ('judicial', 'Judicial Lens', '8 questions for judicial and DA candidates',                            '#C2440A', 'gavel',    true, array['JUDICIAL','NATIONAL_JUDICIAL'])
on conflict (key) do update set auto_district_types = excluded.auto_district_types;

-- Federal lens topics (popularity order, derived from inform.politician_answers 2026-07-12).
insert into inform.compass_lens_topics (lens_id, topic_id, sort_order)
select (select id from inform.compass_lenses where key='federal'), v.id, v.ord
from (values
  ('e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 0),  -- Healthcare
  ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 1),  -- Taxes
  ('4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid, 2),  -- Immigration
  ('af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 3),  -- Abortion
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),  -- Climate Change
  ('44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 5),  -- Deportation
  ('cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 6),  -- Medicare/aid
  ('a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 7)   -- Fossil Fuels
) as v(id, ord)
on conflict (lens_id, topic_id) do update set sort_order = excluded.sort_order;

-- Judicial lens topics.
insert into inform.compass_lens_topics (lens_id, topic_id, sort_order)
select (select id from inform.compass_lenses where key='judicial'), v.id, v.ord
from (values
  ('1fab5edf-6151-4da0-9704-a7f2113ba54c'::uuid, 0),  -- Bail & Pretrial
  ('9d45acaf-1ba4-4cb8-95e1-5ed985223b91'::uuid, 1),  -- Court Access
  ('9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, 2),  -- Criminal Justice
  ('e5e48f0e-8f3a-40e1-8080-889fea389603'::uuid, 3),  -- Government Deference
  ('448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee'::uuid, 4),  -- Interpretation
  ('c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 5),  -- Jail Capacity
  ('6674d87e-999d-433a-aab7-3f626f59fd5f'::uuid, 6),  -- Legal Transparency
  ('abb99d95-cbb1-4617-8f8b-f220ef6028ca'::uuid, 7)   -- Prosecution
) as v(id, ord)
on conflict (lens_id, topic_id) do update set sort_order = excluded.sort_order;
