-- 1723_puerto_rico_headshots.sql
--
-- RENUMBERED 1722 -> 1723. It was authored, applied to prod and committed as 1722; a parallel
-- session then pushed 1722_md_medicaid_template.sql onto the same number. This file moved rather
-- than that one because that one's header cites an on-disk rollback artifact
-- (data/stance-retirement/2026-08-12-medicaid-1722-rollback.json) whose name would have drifted.
-- Nothing here embeds the number in written data — it appeared only in this header — so the
-- rename is cosmetic and the applied rows are unaffected.
--
-- Portraits for all 82 Puerto Rico officeholders seated by migration 1720 — the Governor,
-- 28 senators and 53 representatives. Every one of them had NO photograph of any kind:
-- no politician_images row, no photo_custom_url, no photo_origin_url. This was the single
-- largest headshot gap in the database.
--
-- Sources are the chambers' own rosters, both of which answer a plain fetch:
--   House  — camara.pr.gov exposes its roster as the WordPress post type
--            `representantes_team` (exactly 53 members, featured image per member).
--   Senate — senado.pr.gov/senadores, whose cards carry alt="foto de Hon. <formal name>".
--   Governor — she is NOT on a PR government page: fortaleza.pr.gov publishes no biography
--            at all (of 384 sitemap URLs only 20 are not press releases). Her portrait is the
--            U.S. House Office of Photography official portrait from her service as Resident
--            Commissioner (bioguide G000582, term ended 2025-01-03), which is public domain.
--            The ID was looked up in congress-legislators, never guessed — an early wave put
--            Ann Kirkpatrick's face on Mark Kelly's profile by guessing one.
--
-- MATCHING — read this before touching these rows.
-- Spanish naming makes the usual guards unsafe here, exactly as ADR 0003's todo warned.
-- Many of our records carry a NICKNAME plus ONE surname ("Gaby González", "Cheíto
-- Hernández", "Rafy Santos", "Pichy Torres Zamora") where the chambers publish formal
-- paternal+maternal names ("Héctor Gabriel González López", "José Hernández Concepción").
-- 74 of 81 legislators matched on a strict rule requiring EVERY token of our name to appear
-- in the roster entry. The remaining 7 were each resolved against that member's own profile
-- page using the district or an explicitly quoted nickname as independent evidence, then all
-- 81 were re-checked against the district and party their chamber publishes for them.
--
-- 🔴 TWO PROPOSED HIGH-RES UPGRADES WERE REJECTED AS DIFFERENT PEOPLE. A token-overlap
-- search of the House media library returned `rep-roberto-lopez-roman` when asked for
-- Wilson J. Román López, and `rep-jose-aponte-hernandez` when asked for José Hernández
-- Concepción. All four are sitting representatives; the surnames simply collide or reverse.
-- Both were caught by looking at the images side by side and dropped. Do not re-run a
-- surname-scoring upgrade pass on this cohort without a visual check.
--
-- Images are mirrored to storage as politician_photos/<pid>-headshot.jpg (600x750, 4:5,
-- face-anchored so the head sits in the top half) and every one was read back through the
-- public CDN, asserting HTTP 200 + image/* + >5KB, before this migration was written.
--
-- Sets BOTH photo_custom_url and photo_origin_url on purpose. The read path is
-- COALESCE(photo_custom_url, photo_origin_url, '') — writing only the origin (a source PAGE,
-- not an image) makes the portrait render broken. That is the defect migration 1475 Part B
-- had to repair for 48 Wisconsin profiles.
--
-- DELIBERATELY NOT FIXED HERE: we hold Senator Wandy Soto (Humacao, SD 7) as Partido
-- Popular Democrático; senado.pr.gov says Partido Nuevo Progresista on both her profile page
-- and her roster card, and her biography's "entró en Minoría" in 2020 is consistent with PNP
-- given the PPD majority of that term. Identity is not in doubt. A party is a factual claim
-- about a real person and belongs in its own sourced pass, not a photo migration.
--
-- Idempotent: re-running inserts nothing and updates nothing.

BEGIN;

CREATE TEMP TABLE _pr_headshots (
  politician_id uuid PRIMARY KEY,
  bucket_url    text NOT NULL,
  source_page   text NOT NULL,
  license       text NOT NULL
) ON COMMIT DROP;

INSERT INTO _pr_headshots (politician_id, bucket_url, source_page, license) VALUES
  ('1d10c52b-e94a-40a2-a3bf-5f6ae8169818'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1d10c52b-e94a-40a2-a3bf-5f6ae8169818-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Official_portrait_of_Resident_Commissioner_Jenniffer_Gonzalez_(4x5_cropped).jpg', 'public_domain'),
  ('c71ca335-45ef-404d-8528-e523bb41593d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c71ca335-45ef-404d-8528-e523bb41593d-headshot.jpg', 'https://senado.pr.gov/hon-juan-oscar-morales', 'press_use'),
  ('ff475552-e75a-4276-80b5-c8b03bd4ac58'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ff475552-e75a-4276-80b5-c8b03bd4ac58-headshot.jpg', 'https://senado.pr.gov/hon-nitza-mor-n-trinidad', 'press_use'),
  ('e62dee06-426a-48cd-b6ef-21ad3c47a654'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e62dee06-426a-48cd-b6ef-21ad3c47a654-headshot.jpg', 'https://senado.pr.gov/hon-carmelo-j-r-os-santiago', 'press_use'),
  ('60c72de0-817b-4c1a-b7b9-7d6414d07cf2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/60c72de0-817b-4c1a-b7b9-7d6414d07cf2-headshot.jpg', 'https://senado.pr.gov/hon-migdalia-padilla-alvelo', 'press_use'),
  ('f62ba9e2-cc1f-46de-8616-96acc102ae34'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f62ba9e2-cc1f-46de-8616-96acc102ae34-headshot.jpg', 'https://senado.pr.gov/brenda-pérez-soto', 'press_use'),
  ('690f2671-879c-440d-8cbe-7e63e63bf082'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/690f2671-879c-440d-8cbe-7e63e63bf082-headshot.jpg', 'https://senado.pr.gov/héctor-gabriel-gonzález-lópez', 'press_use'),
  ('fb923f76-bf7e-441e-bf4b-0651c36ccdb8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fb923f76-bf7e-441e-bf4b-0651c36ccdb8-headshot.jpg', 'https://senado.pr.gov/jeison-rosa-ramos', 'press_use'),
  ('18080957-b562-4faf-b0d7-2deed7a06db4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/18080957-b562-4faf-b0d7-2deed7a06db4-headshot.jpg', 'https://senado.pr.gov/hon-karen-michelle-román-rodríguez', 'press_use'),
  ('ebf61921-03a6-4796-953e-c9c1dce1650f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ebf61921-03a6-4796-953e-c9c1dce1650f-headshot.jpg', 'https://senado.pr.gov/jamie-barlucea-rodríguez', 'press_use'),
  ('b06541ac-9613-4ca7-91c0-bb66ad744a7a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b06541ac-9613-4ca7-91c0-bb66ad744a7a-headshot.jpg', 'https://senado.pr.gov/hon-marially-gonz-lez-huertas', 'press_use'),
  ('996bdcf6-1364-4edc-8861-96adecd2748d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/996bdcf6-1364-4edc-8861-96adecd2748d-headshot.jpg', 'https://senado.pr.gov/rafael-santos-ortiz', 'press_use'),
  ('ce3a45fd-c723-449d-9c82-e63b8f57ccd8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce3a45fd-c723-449d-9c82-e63b8f57ccd8-headshot.jpg', 'https://senado.pr.gov/wilmer-reyes-berríos', 'press_use'),
  ('2f21fc2b-f9ac-465f-a2c0-96fa6b480315'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2f21fc2b-f9ac-465f-a2c0-96fa6b480315-headshot.jpg', 'https://senado.pr.gov/luis-daniel-colón-la-santa', 'press_use'),
  ('4534a200-7e9a-44ae-ad87-9334594dbb68'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4534a200-7e9a-44ae-ad87-9334594dbb68-headshot.jpg', 'https://senado.pr.gov/hon-wanda-m-soto-tolentino', 'press_use'),
  ('dace4b67-f485-442f-a211-0baf61d6733d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dace4b67-f485-442f-a211-0baf61d6733d-headshot.jpg', 'https://senado.pr.gov/héctor-joaquín-sánchez-álvarez', 'press_use'),
  ('7e1fb830-2b8d-446b-a074-bc14630c1077'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7e1fb830-2b8d-446b-a074-bc14630c1077-headshot.jpg', 'https://senado.pr.gov/hon-marissa-jim-nez-santoni', 'press_use'),
  ('3c5878fe-b61b-4e87-ab66-117d15f167b3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3c5878fe-b61b-4e87-ab66-117d15f167b3-headshot.jpg', 'https://senado.pr.gov/hon-ada-m-álvarez-conde', 'press_use'),
  ('c88cf544-20f3-4480-ac29-849dae6fa8e6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c88cf544-20f3-4480-ac29-849dae6fa8e6-headshot.jpg', 'https://senado.pr.gov/adrian-gonzalez-costa', 'press_use'),
  ('bb0f0fa3-8d26-4bcf-8b84-5cfe2c38913f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bb0f0fa3-8d26-4bcf-8b84-5cfe2c38913f-headshot.jpg', 'https://senado.pr.gov/hon-eliezer-molina-pérez', 'press_use'),
  ('018835b6-22b0-4c52-bb9e-d9520213987e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/018835b6-22b0-4c52-bb9e-d9520213987e-headshot.jpg', 'https://senado.pr.gov/hon-gregorio-matias-rosario', 'press_use'),
  ('6d9a9544-0a08-4c62-93c6-75078d6c1e91'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6d9a9544-0a08-4c62-93c6-75078d6c1e91-headshot.jpg', 'https://senado.pr.gov/luis-javier-hern-ndez-ortiz', 'press_use'),
  ('43e43a91-9e39-4cf5-b8d6-6c0f857b8033'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/43e43a91-9e39-4cf5-b8d6-6c0f857b8033-headshot.jpg', 'https://senado.pr.gov/hon-joanne-m-rodriguez-veve', 'press_use'),
  ('c5b99cc4-8584-4877-9e6f-16e12059c2be'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c5b99cc4-8584-4877-9e6f-16e12059c2be-headshot.jpg', 'https://senado.pr.gov/josé-a-santiago-rivera', 'press_use'),
  ('8b30a3bc-8ef4-4aeb-ae6c-200f0a91f781'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8b30a3bc-8ef4-4aeb-ae6c-200f0a91f781-headshot.jpg', 'https://senado.pr.gov/hon-josé-l-dalmau-santiago', 'press_use'),
  ('3748935a-1be2-4bba-b518-4b4865b0de9a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3748935a-1be2-4bba-b518-4b4865b0de9a-headshot.jpg', 'https://senado.pr.gov/hon-maria-de-l-santiago-negron', 'press_use'),
  ('987c2cfb-e020-4710-8c07-c6c97ce02a87'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/987c2cfb-e020-4710-8c07-c6c97ce02a87-headshot.jpg', 'https://senado.pr.gov/roxanna-i-soto-aguilú', 'press_use'),
  ('15e97b57-27f7-414f-b787-c48f18ac24d7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/15e97b57-27f7-414f-b787-c48f18ac24d7-headshot.jpg', 'https://senado.pr.gov/hon-thomas-rivera-schatz', 'press_use'),
  ('724fe338-4286-4715-a9fb-50f4b229b06d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/724fe338-4286-4715-a9fb-50f4b229b06d-headshot.jpg', 'https://senado.pr.gov/ángel-toledo-lópez', 'press_use'),
  ('c9f49620-5991-4710-b052-90511a670fcd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c9f49620-5991-4710-b052-90511a670fcd-headshot.jpg', 'https://www.camara.pr.gov/team/eddie-charbonier-chinea/', 'press_use'),
  ('86c48296-fc92-4404-99e9-d91443c43e9b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/86c48296-fc92-4404-99e9-d91443c43e9b-headshot.jpg', 'https://www.camara.pr.gov/team/ricardo-chino-rey-ocasio-ramos/', 'press_use'),
  ('e5e4da61-e950-4090-b98a-87d26f7bb094'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e5e4da61-e950-4090-b98a-87d26f7bb094-headshot.jpg', 'https://www.camara.pr.gov/team/jose-hernandez-concepcion/', 'press_use'),
  ('2d72d154-5e4e-47b8-ada7-28039138f5fb'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2d72d154-5e4e-47b8-ada7-28039138f5fb-headshot.jpg', 'https://www.camara.pr.gov/team/victor-l-pares-otero/', 'press_use'),
  ('17b269fe-25a4-4427-9170-0d020c69c580'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/17b269fe-25a4-4427-9170-0d020c69c580-headshot.jpg', 'https://www.camara.pr.gov/team/jorge-navarro-suarez/', 'press_use'),
  ('af47fe5a-b926-4ce5-bd74-2ec7bf57d8ed'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/af47fe5a-b926-4ce5-bd74-2ec7bf57d8ed-headshot.jpg', 'https://www.camara.pr.gov/team/angel-morey-noble/', 'press_use'),
  ('34001ee0-5e18-4b75-bf6a-0172425afbb9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/34001ee0-5e18-4b75-bf6a-0172425afbb9-headshot.jpg', 'https://www.camara.pr.gov/team/luis-perez-ortiz/', 'press_use'),
  ('701ec2f6-d7f0-40b6-8823-225280c4c63f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/701ec2f6-d7f0-40b6-8823-225280c4c63f-headshot.jpg', 'https://www.camara.pr.gov/team/yashira-lebron-rodriguez/', 'press_use'),
  ('42d35f76-f6d8-454d-bb0a-79669a9e6ff5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/42d35f76-f6d8-454d-bb0a-79669a9e6ff5-headshot.jpg', 'https://www.camara.pr.gov/team/felix-pacheco-burgos/', 'press_use'),
  ('73479f76-dd5f-4ade-a658-f3a214ac00ff'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/73479f76-dd5f-4ade-a658-f3a214ac00ff-headshot.jpg', 'https://www.camara.pr.gov/team/pedro-j-pelle-santiago-guzman/', 'press_use'),
  ('e03e2724-980d-41c6-94f9-494e417da758'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e03e2724-980d-41c6-94f9-494e417da758-headshot.jpg', 'https://www.camara.pr.gov/team/elinette-gonzalez-aguayo/', 'press_use'),
  ('9cbc6022-9ebc-4712-95de-6c18d4e36102'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9cbc6022-9ebc-4712-95de-6c18d4e36102-headshot.jpg', 'https://www.camara.pr.gov/team/edgardo-feliciano-sanchez/', 'press_use'),
  ('8324d03e-9f9e-4c79-9be2-03c6addf76c4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8324d03e-9f9e-4c79-9be2-03c6addf76c4-headshot.jpg', 'https://www.camara.pr.gov/team/jerry-nieves-rosario/', 'press_use'),
  ('eaf818b4-4780-421b-b525-c15d9063cc57'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eaf818b4-4780-421b-b525-c15d9063cc57-headshot.jpg', 'https://www.camara.pr.gov/team/edgar-robles-rivera/', 'press_use'),
  ('4865e77e-b4f5-4d3a-9ade-755b3d074b61'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4865e77e-b4f5-4d3a-9ade-755b3d074b61-headshot.jpg', 'https://www.camara.pr.gov/team/joel-i-franqui-atiles/', 'press_use'),
  ('e6eb30ae-c513-4458-b061-f1ca15ae00e5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e6eb30ae-c513-4458-b061-f1ca15ae00e5-headshot.jpg', 'https://www.camara.pr.gov/team/reinaldo-reyfigueroa/', 'press_use'),
  ('89088285-9530-4b79-aaff-0dfd75ff01a8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/89088285-9530-4b79-aaff-0dfd75ff01a8-headshot.jpg', 'https://www.camara.pr.gov/team/wilson-j-roman-lopez/', 'press_use'),
  ('7bd1dd12-114b-4be5-be5a-b0ad4fc024cf'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7bd1dd12-114b-4be5-be5a-b0ad4fc024cf-headshot.jpg', 'https://www.camara.pr.gov/team/odalys-gonzalez-gonzalez/', 'press_use'),
  ('ab7eb28c-d79d-4043-a14e-297fe2566b6e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ab7eb28c-d79d-4043-a14e-297fe2566b6e-headshot.jpg', 'https://www.camara.pr.gov/team/lilibeth-lilly-rosas/', 'press_use'),
  ('b353a5dc-fe71-4c24-a202-78a252a01463'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b353a5dc-fe71-4c24-a202-78a252a01463-headshot.jpg', 'https://www.camara.pr.gov/team/emilio-carlo-acosta/', 'press_use'),
  ('4784413e-f6dd-45e7-ac1a-400ba62e6907'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4784413e-f6dd-45e7-ac1a-400ba62e6907-headshot.jpg', 'https://www.camara.pr.gov/team/omayra-m-martinez-vazquez/', 'press_use'),
  ('2aacf97a-a7ee-4dbe-91c8-1a3693b85cf0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2aacf97a-a7ee-4dbe-91c8-1a3693b85cf0-headshot.jpg', 'https://www.camara.pr.gov/team/joe-joito-colon-rodriguez/', 'press_use'),
  ('fd95642a-669d-4f5e-afee-551cd2750fd0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fd95642a-669d-4f5e-afee-551cd2750fd0-headshot.jpg', 'https://www.camara.pr.gov/team/ensol-a-rodriguez-torres/', 'press_use'),
  ('160666d9-6cb7-4732-9321-579b01ad7ce5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/160666d9-6cb7-4732-9321-579b01ad7ce5-headshot.jpg', 'https://www.camara.pr.gov/team/angel-a-fourquet-cordero/', 'press_use'),
  ('ed86473d-bb6d-4633-8126-24b04a970f00'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ed86473d-bb6d-4633-8126-24b04a970f00-headshot.jpg', 'https://www.camara.pr.gov/team/domingo-j-torres-garcia/', 'press_use'),
  ('db41a271-2162-4a92-9254-b01bf285177d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/db41a271-2162-4a92-9254-b01bf285177d-headshot.jpg', 'https://www.camara.pr.gov/team/luis-josean-jimenez-torres/', 'press_use'),
  ('75a41cdb-5de7-4d16-ac3d-1c03fb4705aa'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/75a41cdb-5de7-4d16-ac3d-1c03fb4705aa-headshot.jpg', 'https://www.camara.pr.gov/team/estrella-martinez-soto/', 'press_use'),
  ('8f06bf7f-3112-4a0f-b00c-a6ad23d87f4f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8f06bf7f-3112-4a0f-b00c-a6ad23d87f4f-headshot.jpg', 'https://www.camara.pr.gov/team/axel-chino-roque-gracia/', 'press_use'),
  ('7acf8750-06bd-4b14-982d-e23592ddd5b5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7acf8750-06bd-4b14-982d-e23592ddd5b5-headshot.jpg', 'https://www.camara.pr.gov/team/gretchen-hau/', 'press_use'),
  ('7c7655bc-8d3a-48b5-b6f7-0d9ae5aabc50'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c7655bc-8d3a-48b5-b6f7-0d9ae5aabc50-headshot.jpg', 'https://www.camara.pr.gov/team/fernando-sanabria-colon/', 'press_use'),
  ('c88037cb-2d0d-41ae-8af9-e1233a7f28d9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c88037cb-2d0d-41ae-8af9-e1233a7f28d9-headshot.jpg', 'https://www.camara.pr.gov/team/roberto-lopez-roman/', 'press_use'),
  ('d5775f4b-5303-447f-a976-bf55c325575a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d5775f4b-5303-447f-a976-bf55c325575a-headshot.jpg', 'https://www.camara.pr.gov/team/jose-conny-varela/', 'press_use'),
  ('19d8406f-a1eb-47ee-88a4-45b98dfba231'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/19d8406f-a1eb-47ee-88a4-45b98dfba231-headshot.jpg', 'https://www.camara.pr.gov/team/angel-r-pena-ramirez/', 'press_use'),
  ('21119f61-f7d2-4575-91e3-a08cfa5180f1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/21119f61-f7d2-4575-91e3-a08cfa5180f1-headshot.jpg', 'https://www.camara.pr.gov/team/christian-muriel-sanchez/', 'press_use'),
  ('7a53c5f9-bd37-4dd6-91f9-6f78d317a306'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7a53c5f9-bd37-4dd6-91f9-6f78d317a306-headshot.jpg', 'https://www.camara.pr.gov/team/sol-y-higgins-cuadrado/', 'press_use'),
  ('9b8f5675-3c6a-43c8-8d2a-abdc773ebcf0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9b8f5675-3c6a-43c8-8d2a-abdc773ebcf0-headshot.jpg', 'https://www.camara.pr.gov/team/carlos-johnny-mendez-nunez/', 'press_use'),
  ('97373325-12ed-4182-8138-1a2e3f9ac601'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/97373325-12ed-4182-8138-1a2e3f9ac601-headshot.jpg', 'https://www.camara.pr.gov/team/carmen-medina-calderon/', 'press_use'),
  ('014b062d-a97e-4050-9dca-37fdc7a601b8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/014b062d-a97e-4050-9dca-37fdc7a601b8-headshot.jpg', 'https://www.camara.pr.gov/team/wanda-del-valle-correa/', 'press_use'),
  ('a782538f-bab0-4f7b-95ad-ee1aea60318c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a782538f-bab0-4f7b-95ad-ee1aea60318c-headshot.jpg', 'https://www.camara.pr.gov/team/roberto-rivera-ruiz-de-porras/', 'press_use'),
  ('5d058992-de9d-4046-94db-57062a516aa3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d058992-de9d-4046-94db-57062a516aa3-headshot.jpg', 'https://www.camara.pr.gov/team/sergio-estevez-velez/', 'press_use'),
  ('99947d49-5611-4d13-bf8a-20825ff9e8c5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/99947d49-5611-4d13-bf8a-20825ff9e8c5-headshot.jpg', 'https://www.camara.pr.gov/team/adriana-gutierrez-colon/', 'press_use'),
  ('c7176754-56f3-458f-8ca7-23d64de9c874'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c7176754-56f3-458f-8ca7-23d64de9c874-headshot.jpg', 'https://www.camara.pr.gov/team/denis-marquez-lebron/', 'press_use'),
  ('89878f88-46c3-4e5c-a04e-4baef5b16242'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/89878f88-46c3-4e5c-a04e-4baef5b16242-headshot.jpg', 'https://www.camara.pr.gov/team/gabriel-rodriguez-aguilo/', 'press_use'),
  ('b6fd9808-55a9-43cf-92d1-81d28221efdc'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b6fd9808-55a9-43cf-92d1-81d28221efdc-headshot.jpg', 'https://www.camara.pr.gov/team/hector-e-ferrer-santiago/', 'press_use'),
  ('419b3cb9-fefd-4b90-b0fe-ed5169b12693'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/419b3cb9-fefd-4b90-b0fe-ed5169b12693-headshot.jpg', 'https://www.camara.pr.gov/team/jose-f-aponte-hernandez/', 'press_use'),
  ('adabd9f7-53b5-4aad-a029-57c69e50e18f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/adabd9f7-53b5-4aad-a029-57c69e50e18f-headshot.jpg', 'https://www.camara.pr.gov/team/jose-j-perez-cordero-2/', 'press_use'),
  ('e5ff5aa4-b5b3-4a6e-a252-a387431df38d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e5ff5aa4-b5b3-4a6e-a252-a387431df38d-headshot.jpg', 'https://www.camara.pr.gov/team/lisie-j-burgos-muniz/', 'press_use'),
  ('e7d102d0-f8ab-43da-9615-b42b31fb0a04'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e7d102d0-f8ab-43da-9615-b42b31fb0a04-headshot.jpg', 'https://www.camara.pr.gov/team/maria-de-lourdes-ramos-rivera/', 'press_use'),
  ('e0eb21f4-cca9-4db0-8f2a-43d073fff92c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e0eb21f4-cca9-4db0-8f2a-43d073fff92c-headshot.jpg', 'https://www.camara.pr.gov/team/nelie-lebron-robles/', 'press_use'),
  ('4bb73fc7-13e0-4085-957f-673df733069b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4bb73fc7-13e0-4085-957f-673df733069b-headshot.jpg', 'https://www.camara.pr.gov/team/jose-e-torres-zamora/', 'press_use'),
  ('f3f57652-abf2-4a9c-a677-fe1d1e765c80'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f3f57652-abf2-4a9c-a677-fe1d1e765c80-headshot.jpg', 'https://www.camara.pr.gov/team/ramon-torres-cruz/', 'press_use'),
  ('eff0e804-96bb-4cdc-b9cb-9534c6b59a95'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eff0e804-96bb-4cdc-b9cb-9534c6b59a95-headshot.jpg', 'https://www.camara.pr.gov/team/swanny-e-vargas-laureano/', 'press_use'),
  ('bee5e141-9ae2-4455-ad7a-2c99561bb30d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bee5e141-9ae2-4455-ad7a-2c99561bb30d-headshot.jpg', 'https://www.camara.pr.gov/team/tatiana-perez-ramirez/', 'press_use');

-- Refuse to run against a shifted roster rather than seating a face on the wrong person.
DO $$
DECLARE n_missing int; n_override int; n_notpr int;
BEGIN
  SELECT count(*) INTO n_missing
  FROM _pr_headshots t
  LEFT JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.id IS NULL;
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'aborting: % of 82 target politicians no longer exist', n_missing;
  END IF;

  -- Every target must still be in the PR external_id band seeded by migration 1720.
  -- If one is not, the roster has been re-seeded and these pids mean something else now.
  SELECT count(*) INTO n_notpr
  FROM _pr_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.external_id::text NOT LIKE '-72%';
  IF n_notpr <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) are outside the PR -72xxxxx band', n_notpr;
  END IF;

  -- mig 192 / D-08: a hand-picked portrait outranks anything a sweep produces.
  SELECT count(*) INTO n_override
  FROM _pr_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) carry photo_custom_url_manual_override', n_override;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT t.politician_id, t.bucket_url, 'default', t.license
FROM _pr_headshots t
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = t.politician_id AND pi.url = t.bucket_url
);

UPDATE essentials.politicians p
SET photo_custom_url = t.bucket_url,
    photo_origin_url = t.source_page
FROM _pr_headshots t
WHERE p.id = t.politician_id
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND (p.photo_custom_url IS DISTINCT FROM t.bucket_url
    OR p.photo_origin_url IS DISTINCT FROM t.source_page);

-- Post-verify: every target must end up renderable by the app's own predicate.
DO $$
DECLARE n_img int; n_custom int; n_renderable int; n_bad_origin int; n_seated int;
BEGIN
  SELECT count(*) INTO n_img
  FROM _pr_headshots t
  JOIN essentials.politician_images pi
    ON pi.politician_id = t.politician_id AND pi.url = t.bucket_url;
  IF n_img <> 82 THEN
    RAISE EXCEPTION 'expected 82 politician_images rows, found %', n_img;
  END IF;

  SELECT count(*) INTO n_custom
  FROM _pr_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url = t.bucket_url
    AND p.photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom <> 82 THEN
    RAISE EXCEPTION 'expected 82 rows with photo_custom_url on the bucket, found %', n_custom;
  END IF;

  -- HAS_RENDERABLE_PHOTO_SQL, copied from backend/src/lib/photoCoverage.ts so this
  -- migration cannot disagree with the platform's own coverage numbers.
  SELECT count(*) INTO n_renderable
  FROM _pr_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_renderable < 82 THEN
    RAISE EXCEPTION 'only % of 82 satisfy HAS_RENDERABLE_PHOTO_SQL', n_renderable;
  END IF;

  -- photo_origin_url is a research scratchpad elsewhere in this table (mig 1688 cleaned
  -- 148 breadcrumbs out of it). Every value this migration writes must be a real URL.
  SELECT count(*) INTO n_bad_origin
  FROM _pr_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_origin_url NOT LIKE 'http%';
  IF n_bad_origin <> 0 THEN
    RAISE EXCEPTION '% origin url(s) are not http', n_bad_origin;
  END IF;

  -- A portrait is only useful if the person still holds a seat. office_current_holder
  -- LEFT JOINs from offices, so a vacancy is a NULL politician_id and a bare count(*)
  -- would pass vacuously — hence the IS NOT NULL.
  SELECT count(*) INTO n_seated
  FROM _pr_headshots t
  JOIN essentials.office_current_holder och ON och.politician_id = t.politician_id
  WHERE och.politician_id IS NOT NULL;
  IF n_seated <> 82 THEN
    RAISE EXCEPTION 'expected 82 still seated, found %', n_seated;
  END IF;

  RAISE NOTICE 'ok: 82 PR officeholders renderable (% images, % custom urls, % seated)',
    n_img, n_custom, n_seated;
END $$;

COMMIT;
