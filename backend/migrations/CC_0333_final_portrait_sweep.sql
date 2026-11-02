-- CC_0333_final_portrait_sweep.sql
--
-- The last of the unversioned CC BY-SA cohort. 25 portraits replaced, 1 licence corrected in
-- place, and 1 row deliberately left alone. After this, exactly ONE row still carries the
-- unsupported value -- see the bottom of this header, and the gate that pins it.
--
--   10  public_domain
--    7  (Colorado provenance line)
--    2  cc_by-sa_4.0
--    2  cc_by-sa_3.0
--    1  cc_by_2.0
--    1  cc_by_4.0
--    1  cc_by_3.0
--    1  cc_by-sa_2.0
--
-- 🔴 THE VALUES THIS OVERWRITES are enumerated per row: old image URL, old photo_custom_url, old
--    photo_origin_url, and the old licence (exactly 'cc_by-sa' on every row -- gated). Nothing
--    else records them once this commits.
--
-- 🟢 NO OBJECT IS OVERWRITTEN. Every file went to a NEW key under 'portraits-2026-11/', verified
--    by re-reading it from the public CDN and comparing sha256 against the bytes sent. A
--    never-uploaded key in the same prefix was probed first and answered HTTP 400, so the
--    verification can tell a served object from an absent one.
--
-- SOURCES AND WHY THE LICENCES DIFFER
--   Wikimedia Commons (18): the licence its file page STATES, canonicalised by rule.
--   leg.colorado.gov (7): a provenance line, NOT a licence. The General Assembly publishes no
--     rights statement on the member page, the home page, or any probed policy path. Silence is
--     not a grant.
--   🔴 gov.texas.gov was REFUSED OUTRIGHT. It had the best Greg Abbott portrait found anywhere
--     (1000x1499), and its site policy reads "All photographs and videos are copyrighted and may
--     not be used without permission." That is an express reservation, not silence. He comes from
--     Commons instead. ▶ Read a source's policy before taking its files, not after.
--
-- IDENTITY: 🔴 A NAME IS NOT AN IDENTITY, AND A FIRST-PLUS-LAST-NAME FILTER IS NOT EITHER.
--   A Commons name search offered a NASA engineer for Dan Cox and a Civil War soldier for John
--   Deaton; tightening to first AND last name then offered a PROFESSIONAL TENNIS PLAYER for Cox,
--   which the operator caught by eye. What actually settles it is Commons' CURATED CATEGORY for
--   the person -- Category:Dan Cox contains only the Maryland politician. For Colorado, identity
--   is the portrait filename on the member's own directory page, which carries their name.
--
-- CROP: sized from the subject's own face (a head-and-shoulders box ~3.1 face-widths across),
--   and the subject chosen by size AND centrality.
--   ⚠ The first pass took the FULL IMAGE WIDTH and centred on the largest face. On an event
--     photograph that keeps everyone else in frame and can centre on a bystander: it put other
--     people's shoulders in front of William Galvin and cut Sid Miller off at the nose.
--   17 of 25 are DOWNSCALED. ⚠ 8 are enlarged, operator-approved 2026-11-02:
--       Eliza Hamrick          x1.911
--       Junie Joseph           x1.911
--       Mike Weissman          x1.911
--       Rick Taggart           x1.911
--       Steven Woodrow         x1.911
--       Deborah B. Goldberg    x1.566
--       Dan Patrick            x1.152
--       William Francis Galvin x1.003
--     Colorado publishes most members at 314x432 and that is its original, not a thumbnail --
--     two members (Gilchrist, Carter) are served at 3000x4200 from the same system.
--
-- 🔴 SID MILLER IS DELIBERATELY NOT IN THIS MIGRATION and still carries 'cc_by-sa'.
--    Both Commons candidates defeated the face detector outright: on one it locked onto a patch
--    of cloud, on the other a gold necklace against denim. ⚠ The detector control (a flat grey
--    frame yields no faces) proves it CAN fail to find a face; it proves nothing about whether
--    what it finds IS one. texasagriculture.gov publishes only a 250x375 portrait. He needs a
--    source nobody has found yet, and his unsupported licence is left visible rather than
--    quietly blanked. The post-verify pins the remainder at exactly 1.

BEGIN;

CREATE TEMP TABLE lic_before ON COMMIT DROP AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
    FROM essentials.politician_images GROUP BY 1;

CREATE TEMP TABLE pw (
  image_id uuid PRIMARY KEY, pid uuid NOT NULL, who text NOT NULL,
  old_url text NOT NULL, new_url text NOT NULL,
  old_custom text NOT NULL, old_origin text NOT NULL, new_origin text NOT NULL,
  new_lic text NOT NULL, scale numeric NOT NULL, faces int NOT NULL, sha256 text NOT NULL
) ON COMMIT DROP;

INSERT INTO pw (image_id, pid, who, old_url, new_url, old_custom, old_origin, new_origin, new_lic, scale, faces, sha256) VALUES
  ('613fddd0-e27f-4ca9-a16e-0921020aec42'::uuid, '602f147a-90bc-4083-aeab-1d0becf088e9'::uuid, 'Andrea Joy Campbell',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/602f147a-90bc-4083-aeab-1d0becf088e9-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/602f147a-90bc-4083-aeab-1d0becf088e9-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/602f147a-90bc-4083-aeab-1d0becf088e9-headshot.jpg', 'https://en.wikipedia.org/wiki/Andrea_Joy_Campbell', 'https://commons.wikimedia.org/wiki/File:Andrea_Campbell_official_attorney_general_headshot,_2023_(3x4).jpg',
   'public_domain', 0.24, 2, '5b6be12ffaad075a81ef47f96db85718040de3aca9583a2b2ccfcced914577c6'),
  ('4d8cea62-e908-44b7-b6f8-67a834d0d751'::uuid, '4a876d03-4e8f-4d0a-a236-4f594b59f29c'::uuid, 'Dan Cox',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4a876d03-4e8f-4d0a-a236-4f594b59f29c-headshot.jpg?v=20260627', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/4a876d03-4e8f-4d0a-a236-4f594b59f29c-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4a876d03-4e8f-4d0a-a236-4f594b59f29c-headshot.jpg?v=20260627', 'https://en.wikipedia.org/wiki/Dan_Cox', 'https://commons.wikimedia.org/wiki/File:Dan_Cox.jpg',
   'cc_by_2.0', 0.725, 1, '9b37623a5bcb596bc5e2fca3ea8cb7ef530709f86b0dbc1a59f8fd680ed25ec6'),
  ('50f036dc-df0a-42c8-8c09-d3f0254ddc3a'::uuid, 'efac375f-89b2-43a7-bc28-80e99182e454'::uuid, 'Dan Patrick',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/efac375f-89b2-43a7-bc28-80e99182e454-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/efac375f-89b2-43a7-bc28-80e99182e454-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/efac375f-89b2-43a7-bc28-80e99182e454-headshot.jpg', 'https://en.wikipedia.org/wiki/Dan_Patrick_(Texas_politician)', 'https://commons.wikimedia.org/wiki/File:Dan_Patrick_Texas.jpg',
   'cc_by-sa_4.0', 1.152, 1, 'de37cb72b464eceba914137295839373f250f555f3e7cffe83a701417cf29e26'),
  ('8a6b77ad-e390-4255-a807-5a80483229b6'::uuid, 'b207a60b-0879-4135-b6d3-164c5d5c5701'::uuid, 'Dawn Buckingham',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b207a60b-0879-4135-b6d3-164c5d5c5701-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/b207a60b-0879-4135-b6d3-164c5d5c5701-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b207a60b-0879-4135-b6d3-164c5d5c5701-headshot.jpg', 'https://en.wikipedia.org/wiki/Dawn_Buckingham', 'https://commons.wikimedia.org/wiki/File:Sen._Dawn_Buckingham,_M.D_(cropped).jpg',
   'public_domain', 0.673, 1, '5b1a4d8481d9fbc22865fa2357a869e6162446b1219baa8ba5f4d6043de779cd'),
  ('e876dcd8-ca3b-42a3-adc0-7d9cbf8f5f9f'::uuid, '30b6b674-509f-46f6-a9aa-aa3dbefc2f42'::uuid, 'Diana DiZoglio',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/30b6b674-509f-46f6-a9aa-aa3dbefc2f42-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/30b6b674-509f-46f6-a9aa-aa3dbefc2f42-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/30b6b674-509f-46f6-a9aa-aa3dbefc2f42-headshot.jpg', 'https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://commons.wikimedia.org/wiki/File:Diana_DiZoglio,_State_Auditor.png',
   'public_domain', 0.833, 1, 'b9f18761736a9f5eacc264f12dbccd0967c8bb1a0b8b59c87e9d8637ca767ce8'),
  ('0cc81f5d-78bf-4668-ad08-7f2d62ebf42c'::uuid, '1018a81d-652c-46bb-9e18-3adf91d1f474'::uuid, 'Erika Evans',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1018a81d-652c-46bb-9e18-3adf91d1f474-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/1018a81d-652c-46bb-9e18-3adf91d1f474-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1018a81d-652c-46bb-9e18-3adf91d1f474-headshot.jpg', 'https://en.wikipedia.org/wiki/Erika_Evans', 'https://commons.wikimedia.org/wiki/File:Erika_Evans_Seattle_City_Attorney.png',
   'cc_by-sa_4.0', 0.388, 1, 'e8c4ab0e63b7c2acd4533b3d2fd2017463ff8e99701b0bfdb83e6d43ca5a409a'),
  ('3d7a57cf-c6b7-4084-8800-cd8114e6d6a0'::uuid, 'ac09c6dc-d7db-4bdb-9829-0e746c8ca665'::uuid, 'Hannah Pingree',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ac09c6dc-d7db-4bdb-9829-0e746c8ca665-headshot.jpg?v=20260627', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/ac09c6dc-d7db-4bdb-9829-0e746c8ca665-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ac09c6dc-d7db-4bdb-9829-0e746c8ca665-headshot.jpg?v=20260627', 'https://en.wikipedia.org/wiki/Hannah_Pingree', 'https://commons.wikimedia.org/wiki/File:Headshot_of_Hannah_Pingree_in_February_2026.jpg',
   'cc_by_4.0', 0.234, 1, 'f424798a5f2f684abd32cb14280e370ab94af9617fa22d985e45fa0b62e1a46c'),
  ('cc6d2382-893b-4c52-a9db-7657fbaf1cc9'::uuid, '3f90952e-7d1b-413d-a0e1-e319fb23fa05'::uuid, 'Hydee Feldstein Soto',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3f90952e-7d1b-413d-a0e1-e319fb23fa05-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/3f90952e-7d1b-413d-a0e1-e319fb23fa05-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3f90952e-7d1b-413d-a0e1-e319fb23fa05-headshot.jpg', 'https://en.wikipedia.org/wiki/Hydee_Feldstein_Soto', 'https://commons.wikimedia.org/wiki/File:Hydee_Feldstein_Soto,_2022.jpg',
   'public_domain', 0.526, 1, 'aa5cc8f034ceb369eb0fb438640af93b393c61083d0f79cef8f8877a61bd2ffd'),
  ('d7d7ccb5-3c72-45b1-b887-b7ddee1b875b'::uuid, '1f0e5440-d565-4927-9014-43a904c84acf'::uuid, 'John Deaton',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1f0e5440-d565-4927-9014-43a904c84acf-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/1f0e5440-d565-4927-9014-43a904c84acf-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1f0e5440-d565-4927-9014-43a904c84acf-headshot.jpg', 'https://en.wikipedia.org/wiki/John_Deaton', 'https://commons.wikimedia.org/wiki/File:John_Deaton,_2024.jpg',
   'cc_by_3.0', 0.913, 1, 'f397bd1c246df34f5f4027cff6c5865831a75fe4a05dc61f860b98279c77db9f'),
  ('fba7fb48-e4ed-4abe-b04a-06ff651ffe7a'::uuid, 'd0ce1d94-216a-46ed-acc8-6febccfe1844'::uuid, 'Ken Paxton',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d0ce1d94-216a-46ed-acc8-6febccfe1844-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/d0ce1d94-216a-46ed-acc8-6febccfe1844-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d0ce1d94-216a-46ed-acc8-6febccfe1844-headshot.jpg', 'https://en.wikipedia.org/wiki/Ken_Paxton', 'https://commons.wikimedia.org/wiki/File:Ken_Paxton_2024_(cropped).jpg',
   'cc_by-sa_2.0', 0.513, 1, 'd0ed135038a9c17b023980902580f8cbbb76d9d156a03a68d77907b931971186'),
  ('aece92cd-5899-4622-abfc-896285d95d76'::uuid, '590fd6ec-3194-43af-97fc-25490490c565'::uuid, 'Kenneth Mejia',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/590fd6ec-3194-43af-97fc-25490490c565-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/590fd6ec-3194-43af-97fc-25490490c565-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/590fd6ec-3194-43af-97fc-25490490c565-headshot.jpg', 'https://en.wikipedia.org/wiki/Kenneth_Mejia', 'https://commons.wikimedia.org/wiki/File:Kenneth_Mejia,_2023_(cropped).jpg',
   'public_domain', 0.384, 1, '4682cbd4eb2f4ea7e5aca0e936346b76b4ed09a227807009612303593e798158'),
  ('d7c92dba-1585-45ad-aaa3-b1029e29cbf9'::uuid, 'e687c089-f00d-464c-aa37-3b021a3aba2c'::uuid, 'Kim Driscoll',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e687c089-f00d-464c-aa37-3b021a3aba2c-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/e687c089-f00d-464c-aa37-3b021a3aba2c-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e687c089-f00d-464c-aa37-3b021a3aba2c-headshot.jpg', 'https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://commons.wikimedia.org/wiki/File:Kim_Driscoll,_official_portrait,_lieutenant_governor.jpg',
   'public_domain', 0.139, 1, '0e3984ef99c605b3e2ab8d00a5b9ca6310b23481a66147948b942326e1345dbf'),
  ('bbbba77b-137b-4a77-a4b6-d653852ee6a1'::uuid, 'ce9f08b9-fb8b-4ba2-8b2e-99e1ec14617d'::uuid, 'Paul LePage',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce9f08b9-fb8b-4ba2-8b2e-99e1ec14617d-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/ce9f08b9-fb8b-4ba2-8b2e-99e1ec14617d-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce9f08b9-fb8b-4ba2-8b2e-99e1ec14617d-headshot.jpg', 'https://en.wikipedia.org/wiki/Paul_LePage', 'https://commons.wikimedia.org/wiki/File:Paul_LePage_by_Gage_Skidmore.jpg',
   'cc_by-sa_3.0', 0.249, 1, '1e3328da72f27f615d146a1c7c613c41d4b0e6d5636ae8baa2a6f505656f6153'),
  ('94081ef3-b989-4093-aadc-c8e7bdec335d'::uuid, '053b2bdf-2845-4cee-ac3a-5264059d3eaa'::uuid, 'Shenna Bellows',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/053b2bdf-2845-4cee-ac3a-5264059d3eaa-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/053b2bdf-2845-4cee-ac3a-5264059d3eaa-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/053b2bdf-2845-4cee-ac3a-5264059d3eaa-headshot.jpg', 'https://en.wikipedia.org/wiki/Shenna_Bellows', 'https://commons.wikimedia.org/wiki/File:Shenna_Bellows.jpg',
   'cc_by-sa_3.0', 0.234, 2, '68b909105aefe3b6cbb2e13a9b1a689c3ccfc469d788afdf0e1909ce83f04d91'),
  ('16bfc0bb-383b-4957-ae24-069885b07610'::uuid, 'a0e4e813-6c10-45d8-8f59-f444c6747b61'::uuid, 'William Francis Galvin',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a0e4e813-6c10-45d8-8f59-f444c6747b61-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/a0e4e813-6c10-45d8-8f59-f444c6747b61-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a0e4e813-6c10-45d8-8f59-f444c6747b61-headshot.jpg', 'https://en.wikipedia.org/wiki/William_Francis_Galvin', 'https://commons.wikimedia.org/wiki/File:WFGalvin_Official_Portrait.png',
   'public_domain', 1.003, 1, '692c32def3bd6e53a7d54b39e7bc986e346d55896d7dbc31fe58df09b39a87e7'),
  ('7fc05f2c-548f-4df0-88b9-7b656805e1f4'::uuid, '8b1a1407-4774-41c1-80f4-193a401d3c86'::uuid, 'Greg Abbott',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8b1a1407-4774-41c1-80f4-193a401d3c86-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/8b1a1407-4774-41c1-80f4-193a401d3c86-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8b1a1407-4774-41c1-80f4-193a401d3c86-headshot.jpg', 'https://en.wikipedia.org/wiki/Greg_Abbott', 'https://commons.wikimedia.org/wiki/File:Greg_Abbott_2026.jpg',
   'public_domain', 0.287, 1, '8617d2f4180a1c430b7ea6c1893661c7e22f6d683d24f07d84f8094666ce8ab3'),
  ('53f74ad4-17ed-45f1-a488-3e8983c5788e'::uuid, '237ac7cd-7835-4fb4-a69a-cd6524e40fdc'::uuid, 'Keith E. Sonderling',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/237ac7cd-7835-4fb4-a69a-cd6524e40fdc-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/237ac7cd-7835-4fb4-a69a-cd6524e40fdc-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/237ac7cd-7835-4fb4-a69a-cd6524e40fdc-headshot.jpg', 'https://en.wikipedia.org/wiki/Keith_Sonderling', 'https://commons.wikimedia.org/wiki/File:Keith_Sonderling_EEOC.jpg',
   'public_domain', 0.26, 1, '13a16e26ecee11f8a571c956b6e86cd90c82e74f477a06209e3d91437c72fde0'),
  ('4827d81b-a353-4e33-81df-4b868fab5b25'::uuid, 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5'::uuid, 'Deborah B. Goldberg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5-headshot.jpg', 'https://en.wikipedia.org/wiki/Deborah_Goldberg', 'https://commons.wikimedia.org/wiki/File:Deb_Goldberg.jpg',
   'public_domain', 1.566, 1, '903379913d2044db750276b1de69141b7146af918d2400eb62618dd9fb32114c'),
  ('179562d5-fe65-4550-8f06-e18e84c3db7b'::uuid, 'eb5f359e-57d4-414a-ad61-65e74f10bbec'::uuid, 'Eliza Hamrick',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb5f359e-57d4-414a-ad61-65e74f10bbec-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/eb5f359e-57d4-414a-ad61-65e74f10bbec-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb5f359e-57d4-414a-ad61-65e74f10bbec-headshot.jpg', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBd3RUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--291f32764a20e23b89e6ea44560dea6151853b61/Hamrick,Eliza-.jpg', 'https://leg.colorado.gov/legislators/eliza-hamrick',
   'Colorado General Assembly official member portrait (leg.colorado.gov). The General Assembly publishes no rights statement on the member page, the home page or any probed policy path; read 2026-11-02. Identity confirmed by the portrait filename, which carries the member name, on the member''s own directory page.', 1.911, 1, '9e0c9ab4ab4a884d9683b06ac7143fff06ddaa1127e1ab01a29780b14597cce2'),
  ('f23e37a8-899e-4b6c-8fc7-b7cb68abbd24'::uuid, 'be725434-8449-4938-a04b-1d6e41c06631'::uuid, 'Junie Joseph',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/be725434-8449-4938-a04b-1d6e41c06631-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/be725434-8449-4938-a04b-1d6e41c06631-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/be725434-8449-4938-a04b-1d6e41c06631-headshot.jpg', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeWRUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--c05fd8101f2bb8458f9e92fcaac1e5d867b1b662/Joseph,Junie.jpg', 'https://leg.colorado.gov/legislators/junie-joseph',
   'Colorado General Assembly official member portrait (leg.colorado.gov). The General Assembly publishes no rights statement on the member page, the home page or any probed policy path; read 2026-11-02. Identity confirmed by the portrait filename, which carries the member name, on the member''s own directory page.', 1.911, 1, '5132d997c7d635f643d50895a935aa0c61d80f9991d150914e69ea12114cd8c1'),
  ('f8236503-7cdc-45dd-afb3-53b05b545aee'::uuid, '6ab6c9fe-e616-4f46-9039-bcf8c94bf163'::uuid, 'Lindsay Gilchrist',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6ab6c9fe-e616-4f46-9039-bcf8c94bf163-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/6ab6c9fe-e616-4f46-9039-bcf8c94bf163-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6ab6c9fe-e616-4f46-9039-bcf8c94bf163-headshot.jpg', 'https://images.squarespace-cdn.com/content/v1/5ea0cb44b06d660224de3cc9/1588045290088-U5X5Z0VC06EFGHN9K1AC/lindsay-gilchrist.jpg?format=500w', 'https://leg.colorado.gov/legislators/lindsay-gilchrist',
   'Colorado General Assembly official member portrait (leg.colorado.gov). The General Assembly publishes no rights statement on the member page, the home page or any probed policy path; read 2026-11-02. Identity confirmed by the portrait filename, which carries the member name, on the member''s own directory page.', 0.2, 1, '3bdfa862187173f0e97a55d1a43c22e7a7d405f36e72edc7cb2fbb1f10efbae3'),
  ('d57b6819-c70b-4209-9add-ebc8894a2ed9'::uuid, 'a6e85962-165f-40f4-82b5-fb0e77be7af0'::uuid, 'Michael Carter',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a6e85962-165f-40f4-82b5-fb0e77be7af0-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/a6e85962-165f-40f4-82b5-fb0e77be7af0-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a6e85962-165f-40f4-82b5-fb0e77be7af0-headshot.jpg', 'https://aps.ss20.sharpschool.com/UserFiles/Servers/Server_3217444/Image/Board%20of%20Education/Members/Carter_Michael_152-200x300.jpg', 'https://leg.colorado.gov/legislators/michael-carter',
   'Colorado General Assembly official member portrait (leg.colorado.gov). The General Assembly publishes no rights statement on the member page, the home page or any probed policy path; read 2026-11-02. Identity confirmed by the portrait filename, which carries the member name, on the member''s own directory page.', 0.2, 1, '264501f84c982c5f8f5622608819313a23507bffc00aa2803fc32416f8a32431'),
  ('7c219a86-fd6c-4f4a-8ca8-d0513d5b18f9'::uuid, '1b91349f-6a61-406e-ba75-27eedc9eb851'::uuid, 'Mike Weissman',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1b91349f-6a61-406e-ba75-27eedc9eb851-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/1b91349f-6a61-406e-ba75-27eedc9eb851-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1b91349f-6a61-406e-ba75-27eedc9eb851-headshot.jpg', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOUJTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--8f5c3253e6bdff26fefd8864913fd683300d7176/Weissman,Mike.jpg', 'https://leg.colorado.gov/legislators/mike-weissman',
   'Colorado General Assembly official member portrait (leg.colorado.gov). The General Assembly publishes no rights statement on the member page, the home page or any probed policy path; read 2026-11-02. Identity confirmed by the portrait filename, which carries the member name, on the member''s own directory page.', 1.911, 1, 'a2111378c3982df126a5b35fbdb252a1601d47a67daf1c63564cc3840246d4d0'),
  ('94a6cf9f-a661-4403-9069-3a0955bdc997'::uuid, '6b42e678-389a-480e-8973-4f8a3a1eaf0c'::uuid, 'Rick Taggart',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b42e678-389a-480e-8973-4f8a3a1eaf0c-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/6b42e678-389a-480e-8973-4f8a3a1eaf0c-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b42e678-389a-480e-8973-4f8a3a1eaf0c-headshot.jpg', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBd3BUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--6b1fb5526e7780f89f9b2fb79535d4e7c39fc37b/TaggartRick.jpg', 'https://leg.colorado.gov/legislators/rick-taggart',
   'Colorado General Assembly official member portrait (leg.colorado.gov). The General Assembly publishes no rights statement on the member page, the home page or any probed policy path; read 2026-11-02. Identity confirmed by the portrait filename, which carries the member name, on the member''s own directory page.', 1.911, 1, '01bb5f00b354cd9342ccdd2cd1959d304d70884dbccb7680a869f56a9519a0e3'),
  ('8c0a0422-d660-42b8-99a9-9e844590ab04'::uuid, 'ceaeed12-53d1-4341-9ffc-22e426014de8'::uuid, 'Steven Woodrow',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ceaeed12-53d1-4341-9ffc-22e426014de8-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/ceaeed12-53d1-4341-9ffc-22e426014de8-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ceaeed12-53d1-4341-9ffc-22e426014de8-headshot.jpg', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMXhUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--b28a2d8e234c37d646a99efd0b7aea44a198fe9d/Woodrow,Steven-.jpg', 'https://leg.colorado.gov/legislators/steven-woodrow',
   'Colorado General Assembly official member portrait (leg.colorado.gov). The General Assembly publishes no rights statement on the member page, the home page or any probed policy path; read 2026-11-02. Identity confirmed by the portrait filename, which carries the member name, on the member''s own directory page.', 1.911, 1, '5a4bee64db0e3ccea7a9970fcae9a0ddd5e8f6a1e123a01fb61d58f51cd592f3');

-- Licence-only correction: her recorded origin was already the right Commons file page, and that
-- page states CC BY 4.0 (author Gidgetcl). The photograph does not change.
-- ⚠ The image check scored this pair 33.3 and called it a different photograph. It is the same
--   one: the Commons original is SQUARE and ours is a 4:5 crop, and mean-absolute-difference
--   compares FRAMING as well as content. Looking at the two images is what settled it.
CREATE TEMP TABLE rl (
  image_id uuid PRIMARY KEY, pid uuid NOT NULL, who text NOT NULL,
  old_lic text NOT NULL, new_lic text NOT NULL, origin text NOT NULL
) ON COMMIT DROP;

INSERT INTO rl (image_id, pid, who, old_lic, new_lic, origin) VALUES
  ('bb2af711-2ea1-4984-b22b-70f511493a31'::uuid, '9e24181e-f5e5-477f-a6e0-94a007b6b3a0'::uuid, 'Bridgett Lewis',
   'cc_by-sa', 'cc_by_4.0', 'https://commons.wikimedia.org/wiki/File:Bridgett_Christian_Lewis_2025.jpg');

-- ---------------------------------------------------------------------------------------------
-- Pre-flight.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM pw;
  IF v_n <> 25 THEN RAISE EXCEPTION 'pre-flight: expected 25 replacements, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM rl;
  IF v_n <> 1 THEN RAISE EXCEPTION 'pre-flight: expected 1 relabel, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.politician_id IS DISTINCT FROM f.pid OR pi.type <> 'default';
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % row(s) are not that person''s default image', v_n; END IF;

  -- 🔴 Every staged row must still carry what this file records for it.
  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE coalesce(pi.photo_license,'') <> 'cc_by-sa' OR pi.url IS DISTINCT FROM f.old_url;
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % staged image(s) no longer match their before-image', v_n; END IF;

  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politicians p ON p.id = f.pid
   WHERE coalesce(p.photo_custom_url,'') IS DISTINCT FROM f.old_custom
      OR coalesce(p.photo_origin_url,'') IS DISTINCT FROM f.old_origin;
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % staged row(s) no longer carry their recorded scalar or origin', v_n; END IF;

  SELECT count(*) INTO v_n FROM rl f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE coalesce(pi.photo_license,'') IS DISTINCT FROM f.old_lic;
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: the relabel row no longer carries cc_by-sa'; END IF;

  -- 🔴🔴 THE OBJECT IS BOUND TO THE PERSON, RECOMPUTED IN SQL FROM THE POLITICIAN ID. A clean
  --     swap of two people's new URLs -- both well-formed, both uploaded -- dies here and
  --     nowhere else.
  SELECT count(*) INTO v_n FROM pw f
   WHERE f.new_url <> 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || 'portraits-2026-11/' || f.pid::text || '-headshot.jpg';
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % new URL(s) are not this person''s own object', v_n; END IF;

  -- Licence must follow the source, and the two families carry different rights.
  SELECT count(*) INTO v_n FROM pw
   WHERE (new_origin ~ 'commons\.wikimedia\.org')
     AND new_lic NOT IN ('cc0', 'cc_by_2.0', 'cc_by_3.0', 'cc_by_4.0', 'cc_by-sa_2.0', 'cc_by-sa_3.0', 'cc_by-sa_4.0', 'public_domain');
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % Commons row(s) carry a non-canonical licence', v_n; END IF;

  -- 🔴 No Colorado row may assert reuse terms that were never granted.
  SELECT count(*) INTO v_n FROM pw
   WHERE new_origin ~ 'leg\.colorado\.gov'
     AND (new_lic ~* '^(public_domain|cc|press_use)' OR new_lic !~ 'no rights statement');
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % Colorado row(s) assert terms never granted', v_n; END IF;

  SELECT count(*) INTO v_n FROM pw WHERE scale > 2.0;
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % row(s) exceed the approved upscale ceiling', v_n; END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images pi
   SET url = f.new_url, photo_license = f.new_lic
  FROM pw f
 WHERE pi.id = f.image_id AND pi.url = f.old_url;

UPDATE essentials.politicians p
   SET photo_custom_url = f.new_url, photo_origin_url = f.new_origin
  FROM pw f
 WHERE p.id = f.pid AND coalesce(p.photo_origin_url,'') = f.old_origin;

UPDATE essentials.politician_images pi
   SET photo_license = f.new_lic
  FROM rl f
 WHERE pi.id = f.image_id AND pi.photo_license = f.old_lic;

-- ---------------------------------------------------------------------------------------------
-- Post-verify.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_before int;
BEGIN
  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.url = f.new_url AND pi.photo_license = f.new_lic;
  IF v_n <> 25 THEN RAISE EXCEPTION 'post-verify: % of 25 images carry the new URL and licence', v_n; END IF;

  -- 🔴 THE SCALAR AND THE IMAGE ROW MUST AGREE, or the grid and the API serve different photos.
  SELECT count(*) INTO v_n FROM pw f
    JOIN essentials.politicians p ON p.id = f.pid
    JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE coalesce(p.photo_custom_url,'') <> pi.url;
  IF v_n <> 0 THEN RAISE EXCEPTION 'post-verify: % row(s) have a scalar disagreeing with the image row', v_n; END IF;

  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politicians p ON p.id = f.pid
   WHERE p.photo_origin_url = f.new_origin;
  IF v_n <> 25 THEN RAISE EXCEPTION 'post-verify: % of 25 carry their new origin', v_n; END IF;

  -- The relabel changed the licence and NOTHING else.
  SELECT count(*) INTO v_n FROM rl f
    JOIN essentials.politician_images pi ON pi.id = f.image_id
    JOIN essentials.politicians p ON p.id = f.pid
   WHERE pi.photo_license = f.new_lic AND coalesce(p.photo_origin_url,'') = f.origin;
  IF v_n <> 1 THEN RAISE EXCEPTION 'post-verify: the relabel did not land cleanly'; END IF;

  -- 🔴 Delta, not a total.
  SELECT coalesce((SELECT n FROM lic_before WHERE lic = 'cc_by-sa'), 0) INTO v_before;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF v_before - v_n <> 26 THEN
    RAISE EXCEPTION 'post-verify: unversioned cc_by-sa fell by %, expected 26', v_before - v_n;
  END IF;

  -- 🔴 EXACTLY ONE IS MEANT TO REMAIN: Sid Miller, whose portrait nobody has found. If this is
  --    0 the migration swept up a row it was told to leave; if it is more, one was missed.
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF v_n <> 1 THEN RAISE EXCEPTION 'post-verify: expected exactly 1 unversioned row left, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
      FROM essentials.politician_images GROUP BY 1
  ) a
  FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) <> 'cc_by-sa'
     AND coalesce(a.lic, b.lic) NOT IN (SELECT new_lic FROM pw UNION SELECT new_lic FROM rl);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the changed set moved', v_n;
  END IF;
END $$;

COMMIT;
