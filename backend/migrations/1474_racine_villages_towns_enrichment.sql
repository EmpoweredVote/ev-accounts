-- Migration 1474: Racine County villages & towns enrichment (headshots + emails)
--
-- Covers the 16 Racine County municipalities outside the City of Racine (96 officials).
-- Every source reachable with `curl -sL --compressed -A "<browser UA>"` except where noted.
--
-- HEADSHOTS (9): Village of Rochester 7 (Google Cloud `juniper-media-library`, high-res
--   427x461 to 2395x2560 -- only Beck needed upscaling) and Village of Caledonia 2
--   (Wishau, Balch). Small-village boards overwhelmingly publish NO portraits.
-- EMAILS (55) across 10 municipalities. Patterns differ per village and are NOT derivable:
--   Mount Pleasant {i}{surname}@mtpleasantwi.gov · Waterford {i}{surname}@waterfordwi.gov
--   (Robert Nash publishes bnash@) · Yorkville {i}{surname}@villageofyorkville.com
--   Wind Point {i}.{surname}@windpoint.org · Elmwood Park {first}.{last}@elmwoodparkwi.gov
--   Caledonia {I}{Surname}@Caledonia-WI.gov · Union Grove {i}{surname}@vi.uniongrove.wi.gov
--   Sturtevant {surname}{i}@sturtevant-wi.gov (surname FIRST -- inverted vs everyone else).
--   Domains normalised to lowercase; local parts left exactly as published.
--
-- DELIBERATELY EXCLUDED after visual inspection -- do not "fix" these later:
--   * Village of Raymond: the Munibit API returns a personPhoto for all 5 officials, but all
--     4 trustee files are BYTE-IDENTICAL (md5 3f8a0ed2...) and are the village crest, not
--     faces. Importing them would give 4 officials the same picture. 0 photos imported.
--   * Caledonia Michael Lambrecht: his personPhoto is the village LOGO. Excluded.
--   * Caledonia McManus + Raymond Paap: personPhoto URLs return HTTP 400 / 0 bytes.
--   * Caledonia Pierce (meeting-video still w/ signage) and Martin (composite name-card,
--     photo is only ~45% of the frame): user reviewed and declined, 2026-07-26.
--   * Town of Norway: 5 portraits exist but ONLY as 75x100 thumbnails (no larger variant --
--     (Large)/(Medium)/bare-name all 404, gallery dir 403). 7.5x upscale; user declined.
--   * North Bay: publishes only role inboxes (vnbpublicworks@, vnbwastewater@, vnbconstable@).
--     Per user decision only the President's role address is stored; portfolio mailboxes are not
--     attributed to individuals. Same rule applied to Raymond (president@raymondwi.com only).
--
-- NOT REACHED: Town of Waterford (5 officials) -- tn.waterford.wi.gov TLS handshake fails
--   entirely (curl 000 on any TLS version, openssl gets no response, browser refused);
--   http:// 301s into the failing https. Retry later, the site has been flaky before.
-- NO EMAILS PUBLISHED: City of Burlington (9 -- roster page has names but zero addresses;
--   Directory.aspx and Mayor-Council carry no member names), Rochester (7), Town of Norway (5),
--   Town of Dover (3 -- only a shared "Roads @towndover.com"), Town of Burlington (5).
--
-- Emails use array_append so dual officeholders keep every address: Troy McReynolds
-- (County D18 + Waterford Village Trustee) gains his village address alongside the county one
-- from migration 1472. Idempotent throughout.

BEGIN;

-- 1) Headshot rows ---------------------------------------------------------
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9798bf5f-86f2-404d-b409-f874dcf38cdd', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9798bf5f-86f2-404d-b409-f874dcf38cdd-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='9798bf5f-86f2-404d-b409-f874dcf38cdd');  -- Adam Schaefer (Village of Rochester)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2b88da91-d520-439a-a76e-155eeacdfc24', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2b88da91-d520-439a-a76e-155eeacdfc24-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='2b88da91-d520-439a-a76e-155eeacdfc24');  -- Pat Nannemann (Village of Rochester)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6b0fa0a1-e8f8-4329-8d70-ec043f5d63f8', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b0fa0a1-e8f8-4329-8d70-ec043f5d63f8-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='6b0fa0a1-e8f8-4329-8d70-ec043f5d63f8');  -- Doug Webb (Village of Rochester)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ec3380b3-12bc-4cea-8bf3-278b5840075d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ec3380b3-12bc-4cea-8bf3-278b5840075d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='ec3380b3-12bc-4cea-8bf3-278b5840075d');  -- Gary Beck, Jr. (Village of Rochester)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '93039f23-defc-4274-bb96-554d30fe8683', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/93039f23-defc-4274-bb96-554d30fe8683-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='93039f23-defc-4274-bb96-554d30fe8683');  -- Jeff Sterling (Village of Rochester)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4901ee85-4731-4253-a2ab-aaf784b15173', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4901ee85-4731-4253-a2ab-aaf784b15173-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='4901ee85-4731-4253-a2ab-aaf784b15173');  -- Nick Ahlers (Village of Rochester)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1d77eab3-465c-4b0e-9cda-19d85400a18f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1d77eab3-465c-4b0e-9cda-19d85400a18f-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='1d77eab3-465c-4b0e-9cda-19d85400a18f');  -- Russ Kumbier (Village of Rochester)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '99fa1a17-73b4-418c-b8ac-a942f0c25f84', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/99fa1a17-73b4-418c-b8ac-a942f0c25f84-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='99fa1a17-73b4-418c-b8ac-a942f0c25f84');  -- Lee Wishau (Village of Caledonia)
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3ea2a666-643d-4518-b19c-81cd3f61fd34', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3ea2a666-643d-4518-b19c-81cd3f61fd34-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='3ea2a666-643d-4518-b19c-81cd3f61fd34');  -- Prescott Balch (Village of Caledonia)

-- 2) photo_origin_url -----------------------------------------------------
UPDATE essentials.politicians SET photo_origin_url='https://rochesterwi.gov/village-board/' WHERE id='9798bf5f-86f2-404d-b409-f874dcf38cdd' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://rochesterwi.gov/village-board/' WHERE id='2b88da91-d520-439a-a76e-155eeacdfc24' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://rochesterwi.gov/village-board/' WHERE id='6b0fa0a1-e8f8-4329-8d70-ec043f5d63f8' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://rochesterwi.gov/village-board/' WHERE id='ec3380b3-12bc-4cea-8bf3-278b5840075d' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://rochesterwi.gov/village-board/' WHERE id='93039f23-defc-4274-bb96-554d30fe8683' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://rochesterwi.gov/village-board/' WHERE id='4901ee85-4731-4253-a2ab-aaf784b15173' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://rochesterwi.gov/village-board/' WHERE id='1d77eab3-465c-4b0e-9cda-19d85400a18f' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://caledonia-wi.gov/board' WHERE id='99fa1a17-73b4-418c-b8ac-a942f0c25f84' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://caledonia-wi.gov/board' WHERE id='3ea2a666-643d-4518-b19c-81cd3f61fd34' AND photo_origin_url IS NULL;

-- 3) Emails (array_append preserves other tiers' addresses) ---------------
-- Village of Mount Pleasant, Wisconsin, US  [https://www.mtpleasantwi.gov/319/Village-Board]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'ddegroot@mtpleasantwi.gov')
 WHERE id='4bbafa07-020e-4f89-8a72-6f427d47c069' AND NOT ('ddegroot@mtpleasantwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- David DeGroot
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'dkaras@mtpleasantwi.gov')
 WHERE id='397b57a0-6dfc-41fe-b39f-e42fe0e40f9c' AND NOT ('dkaras@mtpleasantwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- David Karas
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'gcefalu-paulick@mtpleasantwi.gov')
 WHERE id='1d3dabab-3ecf-46e0-8a5e-34be8a7d27b9' AND NOT ('gcefalu-paulick@mtpleasantwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Gina Cefalu-Paulick
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'nwashburn@mtpleasantwi.gov')
 WHERE id='cf909d3f-2395-4a9e-856f-367302829ef5' AND NOT ('nwashburn@mtpleasantwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Nancy Washburn
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'danastasio@mtpleasantwi.gov')
 WHERE id='a672a629-7be8-415d-8015-146b4e130685' AND NOT ('danastasio@mtpleasantwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Denise Anastasio
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'rbhatia@mtpleasantwi.gov')
 WHERE id='d2fac01d-7489-4932-89e9-e3b0e3640fe7' AND NOT ('rbhatia@mtpleasantwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Ram Bhatia
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'jventurini@mtpleasantwi.gov')
 WHERE id='99f0eae3-5f96-475a-b3c3-b4df2a7695fc' AND NOT ('jventurini@mtpleasantwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Jim Venturini
-- Village of Waterford, Wisconsin, US  [https://www.waterfordwi.gov/171/Village-Board-of-Trustees]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'ajaskie@waterfordwi.gov')
 WHERE id='ab035a52-9f7a-4a46-a1a0-f117bbf5bad4' AND NOT ('ajaskie@waterfordwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Adam Jaskie
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'kdunham@waterfordwi.gov')
 WHERE id='903f5c34-96b1-4aa1-bbc9-34cf427137ad' AND NOT ('kdunham@waterfordwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Kelli Dunham
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'tmcreynolds@waterfordwi.gov')
 WHERE id='19b1b32b-7561-410e-bffd-8b62ba7a1344' AND NOT ('tmcreynolds@waterfordwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Troy McReynolds
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'jtodryk@waterfordwi.gov')
 WHERE id='4130b553-c031-4130-9f5f-bcba283b4e92' AND NOT ('jtodryk@waterfordwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- John Todryk
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'pgoldammer@waterfordwi.gov')
 WHERE id='5531302c-c3e9-4ba3-9d55-c465e628a876' AND NOT ('pgoldammer@waterfordwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Pat Goldammer
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'bnash@waterfordwi.gov')
 WHERE id='f8fdd78f-8a74-4c70-991c-7f708604fbc2' AND NOT ('bnash@waterfordwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Robert Nash
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'tpollnow@waterfordwi.gov')
 WHERE id='9019d3a4-ba86-47bf-99e3-241044317506' AND NOT ('tpollnow@waterfordwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Tamara Pollnow
-- Village of Yorkville, Wisconsin, US  [https://villageofyorkville.com/government/elected-and-appointed-officials/town-and-board-plan-commission/]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'dnelson@villageofyorkville.com')
 WHERE id='3c297787-e102-4678-b576-620a1e72ebec' AND NOT ('dnelson@villageofyorkville.com' = ANY(coalesce(email_addresses,'{}')));  -- Douglas Nelson
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'dmaurice@villageofyorkville.com')
 WHERE id='136baf8a-84e1-489c-af4e-9c43c3665b10' AND NOT ('dmaurice@villageofyorkville.com' = ANY(coalesce(email_addresses,'{}')));  -- Daniel Maurice
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'cbartlett@villageofyorkville.com')
 WHERE id='57fc0a81-f2c1-4429-901c-b05ccd76a546' AND NOT ('cbartlett@villageofyorkville.com' = ANY(coalesce(email_addresses,'{}')));  -- Cory Bartlett
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'rfunk@villageofyorkville.com')
 WHERE id='f6e1591f-1e9a-4613-b252-8378722998b9' AND NOT ('rfunk@villageofyorkville.com' = ANY(coalesce(email_addresses,'{}')));  -- Robert Funk
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'snelson@villageofyorkville.com')
 WHERE id='4506c9ca-961e-4bc9-9ad1-72fa9c74fa94' AND NOT ('snelson@villageofyorkville.com' = ANY(coalesce(email_addresses,'{}')));  -- Steve Nelson
-- Village of Wind Point, Wisconsin, US  [https://windpoint.org/government/village_board.php]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'a.mcculloch@windpoint.org')
 WHERE id='a516a90f-8c5c-410b-8011-490176f0f423' AND NOT ('a.mcculloch@windpoint.org' = ANY(coalesce(email_addresses,'{}')));  -- Alison McCulloch
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'j.westfall@windpoint.org')
 WHERE id='0c71e9e8-139e-4354-9f77-8331c4803e72' AND NOT ('j.westfall@windpoint.org' = ANY(coalesce(email_addresses,'{}')));  -- James Westfall
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'c.manning@windpoint.org')
 WHERE id='77112407-ca98-4a56-835d-d113a60127b7' AND NOT ('c.manning@windpoint.org' = ANY(coalesce(email_addresses,'{}')));  -- Charlie Manning
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'m.fox@windpoint.org')
 WHERE id='50a2523b-34fd-4942-a07e-a2a1aea63679' AND NOT ('m.fox@windpoint.org' = ANY(coalesce(email_addresses,'{}')));  -- Michael Fox
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'m.hall@windpoint.org')
 WHERE id='f20f076e-c3cf-4979-9c5d-d63bb229af61' AND NOT ('m.hall@windpoint.org' = ANY(coalesce(email_addresses,'{}')));  -- Mary Kay Hall
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'c.gaspero@windpoint.org')
 WHERE id='c66fa1df-72d8-4ba4-98ea-53e8f617759b' AND NOT ('c.gaspero@windpoint.org' = ANY(coalesce(email_addresses,'{}')));  -- Carmen Gaspero
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'l.johnson@windpoint.org')
 WHERE id='fd680f3b-0be7-414a-a447-f6effa0e0ee6' AND NOT ('l.johnson@windpoint.org' = ANY(coalesce(email_addresses,'{}')));  -- Linda Johnson
-- Village of Elmwood Park, Wisconsin, US  [https://www.elmwoodparkwi.gov/1197/Board-of-Trustees]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'alicia.gasser@elmwoodparkwi.gov')
 WHERE id='e4166382-4534-449e-930a-5a0a31b69a39' AND NOT ('alicia.gasser@elmwoodparkwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Ali Gasser
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'barb.witek@elmwoodparkwi.gov')
 WHERE id='ce714870-9224-4ea3-91e3-aa0e55f938b9' AND NOT ('barb.witek@elmwoodparkwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Barb Witek
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'kelli.stein@elmwoodparkwi.gov')
 WHERE id='a62d1b11-8044-47a0-a4ca-c28081e8fbe3' AND NOT ('kelli.stein@elmwoodparkwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Kelli Stein
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'laura.rude@elmwoodparkwi.gov')
 WHERE id='0c843cf1-0b1e-4610-9bd1-98776375daca' AND NOT ('laura.rude@elmwoodparkwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Laura Rude
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'brian.johnson@elmwoodparkwi.gov')
 WHERE id='73087f4d-3daf-4065-9b72-6a3e598cf7d1' AND NOT ('brian.johnson@elmwoodparkwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Brian Johnson
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'ken.hinkle@elmwoodparkwi.gov')
 WHERE id='d513a57c-2c38-41a8-89c3-b78359abd40f' AND NOT ('ken.hinkle@elmwoodparkwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Ken Hinkle
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'matt.seivert@elmwoodparkwi.gov')
 WHERE id='d8cdee35-5910-4c3c-a60f-9fe0843bd1b8' AND NOT ('matt.seivert@elmwoodparkwi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Matt Seivert
-- Village of Caledonia, Wisconsin, US  [https://caledonia-wi.gov/board]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'FMartin@caledonia-wi.gov')
 WHERE id='3b814fa0-c74e-4915-ae7a-ef826d3300d7' AND NOT ('FMartin@caledonia-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Fran Martin
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'HMcmanus@caledonia-wi.gov')
 WHERE id='3fa607ac-8824-4bb5-99a8-c5267c41af21' AND NOT ('HMcmanus@caledonia-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Holly McManus
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'LWishau@caledonia-wi.gov')
 WHERE id='99fa1a17-73b4-418c-b8ac-a942f0c25f84' AND NOT ('LWishau@caledonia-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Lee Wishau
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'MLambrecht@caledonia-wi.gov')
 WHERE id='09b4c8ea-5f00-48bd-a715-f31c40732053' AND NOT ('MLambrecht@caledonia-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Michael Lambrecht
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'NPierce@caledonia-wi.gov')
 WHERE id='b3243e2c-aa25-4be9-b5d1-2061765e0c80' AND NOT ('NPierce@caledonia-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Nancy Pierce
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'PBalch@caledonia-wi.gov')
 WHERE id='3ea2a666-643d-4518-b19c-81cd3f61fd34' AND NOT ('PBalch@caledonia-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Prescott Balch
-- Village of Union Grove, Wisconsin, US  [https://uniongrovewi.gov/village-government/directory/]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'swicklund@vi.uniongrove.wi.gov')
 WHERE id='165d3a2e-5515-4a6e-8c5a-8e2caec579ba' AND NOT ('swicklund@vi.uniongrove.wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Steve Wicklund
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'sgloeckler@vi.uniongrove.wi.gov')
 WHERE id='c9630573-4f75-4e28-b761-e6e56b91b819' AND NOT ('sgloeckler@vi.uniongrove.wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Sara Gloeckler
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'kboyle@vi.uniongrove.wi.gov')
 WHERE id='d2a77e1a-5708-4df2-87d5-7942f9b1b2cf' AND NOT ('kboyle@vi.uniongrove.wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Kristy Boyle
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'speterson@vi.uniongrove.wi.gov')
 WHERE id='5fb56d68-3716-4f75-8468-5fad3cb9bef5' AND NOT ('speterson@vi.uniongrove.wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Steve Peterson
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'agraf@vi.uniongrove.wi.gov')
 WHERE id='bed2a2d8-491c-4f51-a2ca-a0de3e2df98f' AND NOT ('agraf@vi.uniongrove.wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Adam Graf
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'jditscheit@vi.uniongrove.wi.gov')
 WHERE id='674baf82-204c-40f4-9e6e-7a0166aa2347' AND NOT ('jditscheit@vi.uniongrove.wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Jennifer Ditscheit
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'ebower@vi.uniongrove.wi.gov')
 WHERE id='0876e34b-19a5-492d-9eb7-c384bb6e98e5' AND NOT ('ebower@vi.uniongrove.wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Eugene Bower
-- Village of Sturtevant, Wisconsin, US  [https://www.sturtevant-wi.gov/villageboard/page/village-board-members]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'rosenbaumm@sturtevant-wi.gov')
 WHERE id='4fa7daa6-2ac5-4b7d-b54c-f7bf0c47bbec' AND NOT ('rosenbaumm@sturtevant-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Mike Rosenbaum
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'davisw@sturtevant-wi.gov')
 WHERE id='945b5c00-7a52-47ec-9eb1-03aadb8914be' AND NOT ('davisw@sturtevant-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Walter Davis
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'inglej@sturtevant-wi.gov')
 WHERE id='ccfbe508-5951-4b48-9035-37ffaaa7d190' AND NOT ('inglej@sturtevant-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Jason Ingle
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'nelsonr@sturtevant-wi.gov')
 WHERE id='8c6d1a44-f10a-4197-8dfa-f09adf231c97' AND NOT ('nelsonr@sturtevant-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Ryan Nelson
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'ruffoloj@sturtevant-wi.gov')
 WHERE id='bea5a9c3-479a-490f-8efa-2e7c10e24e69' AND NOT ('ruffoloj@sturtevant-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Janet Ruffolo
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'villalpandok@sturtevant-wi.gov')
 WHERE id='ff6e2e2b-0b00-4755-8b75-b7332487f763' AND NOT ('villalpandok@sturtevant-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Kari Villalpando
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'welchb@sturtevant-wi.gov')
 WHERE id='4165290d-132d-4063-93e7-facef421535b' AND NOT ('welchb@sturtevant-wi.gov' = ANY(coalesce(email_addresses,'{}')));  -- Brittany Welch
-- Village of North Bay, Wisconsin, US  [https://northbay-wi.us/contacts/]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'vnbpresident@northbay-wi.us')
 WHERE id='02cf5cf0-3308-4db4-903c-50042a5eab77' AND NOT ('vnbpresident@northbay-wi.us' = ANY(coalesce(email_addresses,'{}')));  -- Roger Mellem
-- Village of Raymond, Wisconsin, US  [https://raymondwi.com/board]
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'president@raymondwi.com')
 WHERE id='9fc9a6c4-919f-4d31-b502-06cbd9d4b273' AND NOT ('president@raymondwi.com' = ANY(coalesce(email_addresses,'{}')));  -- Douglas White

COMMIT;
