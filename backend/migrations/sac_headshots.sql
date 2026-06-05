-- AUDIT ONLY — already applied via Supabase MCP on 2026-05-28
-- Do NOT apply via migration ledger. Pattern mirrors 200_sf_headshots.sql,
-- 209_sd_headshots.sql, 212_fremont_headshots.sql, 215_berkeley_headshots.sql, sj_headshots.sql.
--
-- Source: cityofsacramento.gov official city website (public_domain)
-- Dimensions: 600x750 JPEG q90, cropped to 4:5 before resize
-- Bucket: politician_photos
-- Path: {politician_id}-headshot.jpg

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
VALUES
  -- Kevin McCarty (Mayor, -660001)
  (gen_random_uuid(), 'b89b09f0-6a9f-46e5-9193-8a9de99867b0', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b89b09f0-6a9f-46e5-9193-8a9de99867b0-headshot.jpg', 'default', 'public_domain'),
  -- Lisa Kaplan (Council D1, -660010)
  (gen_random_uuid(), '6f8a1527-f8a4-4a2a-8270-9f0e1863826f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6f8a1527-f8a4-4a2a-8270-9f0e1863826f-headshot.jpg', 'default', 'public_domain'),
  -- Roger Dickinson (Council D2, -660011)
  (gen_random_uuid(), '8bb3b17a-334b-48e2-987a-090024c793b8', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8bb3b17a-334b-48e2-987a-090024c793b8-headshot.jpg', 'default', 'public_domain'),
  -- Karina Talamantes (Council D3, -660012)
  (gen_random_uuid(), 'cf2c7616-eb16-4830-be50-6d6096de44dd', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cf2c7616-eb16-4830-be50-6d6096de44dd-headshot.jpg', 'default', 'public_domain'),
  -- Phil Pluckebaum (Council D4, -660013)
  (gen_random_uuid(), '659de81d-ba74-4adf-98a2-dcb64de0f134', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/659de81d-ba74-4adf-98a2-dcb64de0f134-headshot.jpg', 'default', 'public_domain'),
  -- Caity Maple (Council D5, -660014)
  (gen_random_uuid(), '10758208-c20b-4729-8cea-4340caf8243c', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/10758208-c20b-4729-8cea-4340caf8243c-headshot.jpg', 'default', 'public_domain'),
  -- Eric Guerra (Council D6, -660015)
  (gen_random_uuid(), '3b3b6525-7a40-4d01-a1cb-3270ed166919', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3b3b6525-7a40-4d01-a1cb-3270ed166919-headshot.jpg', 'default', 'public_domain'),
  -- Rick Jennings II (Council D7, -660016)
  (gen_random_uuid(), 'f20601e0-0728-4c33-803c-28c88e170286', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f20601e0-0728-4c33-803c-28c88e170286-headshot.jpg', 'default', 'public_domain'),
  -- Mai Vang (Council D8, -660017)
  (gen_random_uuid(), 'ff0dc6f0-f5c8-4266-b70a-3fcc183da5c7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ff0dc6f0-f5c8-4266-b70a-3fcc183da5c7-headshot.jpg', 'default', 'public_domain')
ON CONFLICT DO NOTHING;
