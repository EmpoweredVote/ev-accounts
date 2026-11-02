-- CC_0332_replace_unidentifiable_portraits.sql
--
-- Replace 38 portraits whose origin nobody could establish, and correct their licences.
-- 21 members of Congress -> public_domain. 17 Massachusetts legislators -> a recorded
-- provenance line, because the General Court grants nothing (see below).
--
-- WHY THESE 38 WERE REPLACED RATHER THAN RELABELLED
--   All carried an unversioned 'cc_by-sa' that had been inferred from the host. Four routes were
--   measured against them and the photographs were found in NONE: they are not the Wikipedia
--   article's lead image, not elsewhere on that article, not in its infobox at any point in its
--   history, not findable on Commons by name (a control proved that search finds 4 of 5 KNOWN
--   files), and -- measured here -- not the official portrait either, scoring 40-152 where a
--   match scores under 1.5. So nobody can say what the stored files are. A relabel would have
--   kept 38 unidentifiable photographs on the site under a truthful-sounding label.
--
-- 🔴 THE VALUES THIS OVERWRITES ARE ALL ENUMERATED BELOW, per row: the old image URL, the old
--    photo_custom_url, the old photo_origin_url and the old licence (exactly 'cc_by-sa' on every
--    row -- gated). Nothing else records them once this commits.
--
-- 🟢 NO OBJECT IS OVERWRITTEN. Every new file went to a NEW key under 'portraits-2026-11/', so
--    each prior object still serves at its existing URL. Reverting is repointing columns; no
--    image has to be re-fetched. Each upload was verified by re-reading it from the PUBLIC CDN
--    and comparing sha256 against the bytes sent, and a never-uploaded key in the same prefix was
--    probed first as a negative control -- an API returning 200 is not evidence an object serves.
--
-- 🔴 BOTH PHOTO COLUMNS ARE WRITTEN. The grid reads images[] first and the backend reads the
--    scalar, so a row that updates only one of them renders the OLD photograph somewhere. The
--    post-verify gates that the two agree on all 38.
--
-- LICENCES, AND WHY THEY DIFFER
--   Federal (21): an official congressional portrait is a work of the United States
--   government and is public domain under 17 USC 105. Sources: @unitedstates project and
--   bioguide.congress.gov -- the LARGER of the two per member, because neither wins consistently
--   (bioguide serves 1000x1250 for some and 175x219 for others).
--   Massachusetts (17): 🔴 malegislature.gov publishes NO photo use policy at any discoverable
--   path -- /TermsOfUse, /Copyright, /Content/Policies and five more all 404, and the page footer
--   carries no rights statement. SILENCE IS NOT A GRANT, so no reuse terms are asserted; the
--   licence field records what was found and when, which is this repo's existing shape for
--   Kentucky, Pennsylvania and Anchorage.
--
-- IDENTITY, ESTABLISHED BEFORE ANY CROP
--   Federal: the portrait is addressed BY bioguide id, so the file is the member's by
--   construction; ids came from the @unitedstates dataset, matched on name.
--   Massachusetts: the portrait is taken from the member's OWN profile and its alt text must name
--   them. 🔴 That check exists because an off-by-one scrape of a MA roster once published Senator
--   Vanna Howard's photograph on Patricia Jehlen's profile. Alt text is HTML-unescaped first --
--   'G&#xF3;mez' fails a naive comparison and looks like a mismatch on a correct portrait.
--
-- CROP GEOMETRY IS MEASURED, NEVER CENTRED. A face box is detected per image and headroom set
--   from it. The detector was shown a flat grey frame first and found 0 faces, so its findings
--   here mean something; nothing else in this repo asks whether a headshot contains a face.
--   34 of 38 are DOWNSCALED from a larger original.
--   ⚠ 4 are enlarged, operator-approved 2026-11-02 against the rendered contact sheet:
--       Greg Casar           x1.364  (best official source published)
--       Jared Golden         x1.333  (best official source published)
--       Jasmine Crockett     x1.364  (best official source published)
--       Susan M. Collins     x2.667  (best official source published)

BEGIN;

CREATE TEMP TABLE lic_before ON COMMIT DROP AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
    FROM essentials.politician_images GROUP BY 1;

CREATE TEMP TABLE pw (
  image_id   uuid PRIMARY KEY,
  pid        uuid NOT NULL,
  who        text NOT NULL,
  old_url    text NOT NULL,
  new_url    text NOT NULL,
  old_custom text NOT NULL,
  old_origin text NOT NULL,
  new_origin text NOT NULL,
  new_lic    text NOT NULL,
  scale      numeric NOT NULL,
  sha256     text NOT NULL
) ON COMMIT DROP;

INSERT INTO pw (image_id, pid, who, old_url, new_url, old_custom, old_origin, new_origin, new_lic, scale, sha256) VALUES
  ('dcb19e6e-1c0f-474c-bfc0-5b46ca3ecbaa'::uuid, '78ae3786-e71e-4dc4-8b84-0ab28b555632'::uuid, 'Adam Gómez',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/78ae3786-e71e-4dc4-8b84-0ab28b555632-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/78ae3786-e71e-4dc4-8b84-0ab28b555632-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/78ae3786-e71e-4dc4-8b84-0ab28b555632-headshot.jpg', 'https://en.wikipedia.org/wiki/Adam_Gomez', 'https://malegislature.gov/Legislators/Profile/1200/A_G0.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.674, 'b0507e5237fea738a469647c2afc3d77caf510342672c677e6519093cac50a39'),
  ('cce24911-2793-45c4-b98e-8a189abff255'::uuid, '15f59b0c-f71c-4199-b195-7b653a05a310'::uuid, 'Barry R. Finegold',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/15f59b0c-f71c-4199-b195-7b653a05a310-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/15f59b0c-f71c-4199-b195-7b653a05a310-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/15f59b0c-f71c-4199-b195-7b653a05a310-headshot.jpg', 'https://en.wikipedia.org/wiki/Barry_Finegold', 'https://malegislature.gov/Legislators/Profile/1200/BRF0.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.683, 'c2ec3b0df93f77e60b465c84174bd40c3e647b3f82fd81cc712cd2641f6dacb6'),
  ('c0e50f21-f277-4a82-ac86-614d70897315'::uuid, '510f7802-7b58-4e4a-9824-37e169e65680'::uuid, 'Beth Van Duyne',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/510f7802-7b58-4e4a-9824-37e169e65680-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/510f7802-7b58-4e4a-9824-37e169e65680-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/510f7802-7b58-4e4a-9824-37e169e65680-headshot.jpg', 'https://en.wikipedia.org/wiki/Beth_Van_Duyne', 'https://bioguide.congress.gov/photo/V000134.jpg',
   'public_domain', 0.6, '505d2cee3ee477f049551812aca4f3bda818e9e5b132e67765e2171af459a832'),
  ('684e0fb6-324f-41a6-95bc-d5137361524e'::uuid, '99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'Brendan P. Crighton',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/99457307-afa4-4045-aebf-06ee8b39d28f-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/99457307-afa4-4045-aebf-06ee8b39d28f-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/99457307-afa4-4045-aebf-06ee8b39d28f-headshot.jpg', 'https://en.wikipedia.org/wiki/Brendan_Crighton', 'https://malegislature.gov/Legislators/Profile/1200/BPC0.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.653, '5732ee4f3a512a97b8059c87705248ebe69575c0e8a49445a2058163ae945b40'),
  ('86c06a07-ab6c-426c-a3fa-d9000b811d52'::uuid, 'c4ad307f-b38a-409c-8190-8dedad609d88'::uuid, 'Brian Babin',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c4ad307f-b38a-409c-8190-8dedad609d88-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/c4ad307f-b38a-409c-8190-8dedad609d88-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c4ad307f-b38a-409c-8190-8dedad609d88-headshot.jpg', 'https://en.wikipedia.org/wiki/Brian_Babin', 'https://unitedstates.github.io/images/congress/original/B001291.jpg',
   'public_domain', 0.909, 'b34f58cb129e1563b2d70eb9d41417b5980d4a46176f0a197e30e98f2145fff0'),
  ('399a481f-3372-4278-bd09-3e5be8b0b9fa'::uuid, '913143ad-c39b-4dde-9a93-8252a98b0181'::uuid, 'Carole A. Fiola',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/913143ad-c39b-4dde-9a93-8252a98b0181-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/913143ad-c39b-4dde-9a93-8252a98b0181-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/913143ad-c39b-4dde-9a93-8252a98b0181-headshot.jpg', 'https://en.wikipedia.org/wiki/Carole_Fiola', 'https://malegislature.gov/Legislators/Profile/1200/CAF1.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.625, 'a7b8c85c0100847d75a5c6ec32ace9b3d64c477cc14eb00f3c41a83fe83f8c95'),
  ('c899d196-d56d-4dbe-918c-ad28be812826'::uuid, '1638b2c9-4811-466d-bb24-44c6cece8cda'::uuid, 'Chellie Pingree',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1638b2c9-4811-466d-bb24-44c6cece8cda-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/1638b2c9-4811-466d-bb24-44c6cece8cda-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1638b2c9-4811-466d-bb24-44c6cece8cda-headshot.jpg', 'https://en.wikipedia.org/wiki/Chellie_Pingree', 'https://unitedstates.github.io/images/congress/original/P000597.jpg',
   'public_domain', 0.909, 'dbbdc4c20b2d7ff89ac44dfffecfb52b2a8fd40f57ca247f152975a6cc221f37'),
  ('afcc2d08-2f2a-4146-a708-2063beef7c30'::uuid, 'fd3bf15c-265b-46a9-aa72-c9097749d762'::uuid, 'Chynah Tyler',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fd3bf15c-265b-46a9-aa72-c9097749d762-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/fd3bf15c-265b-46a9-aa72-c9097749d762-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fd3bf15c-265b-46a9-aa72-c9097749d762-headshot.jpg', 'https://en.wikipedia.org/wiki/Chynah_Tyler', 'https://malegislature.gov/Legislators/Profile/1200/C_T1.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.696, 'f0464932498e1b3010bfc21829214620af75a0e957e5dca246b0aaa92c03bc03'),
  ('59bd2e72-56db-43a6-948e-9ebae431130d'::uuid, '846501ab-5b92-4270-97ed-21a43842c726'::uuid, 'Craig Goldman',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/846501ab-5b92-4270-97ed-21a43842c726-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/846501ab-5b92-4270-97ed-21a43842c726-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/846501ab-5b92-4270-97ed-21a43842c726-headshot.jpg', 'https://en.wikipedia.org/wiki/Craig_Goldman', 'https://bioguide.congress.gov/photo/G000601.jpg',
   'public_domain', 0.6, '654125b22708b74fe123bf8481421817dba99c07a0cce423d8c1d50912f37c54'),
  ('8aee51d5-6b87-4e5a-a6b0-e942fba7734d'::uuid, '5c36a94c-9006-4550-a37e-978a65d2725c'::uuid, 'Daniel J. Hunt',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5c36a94c-9006-4550-a37e-978a65d2725c-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/5c36a94c-9006-4550-a37e-978a65d2725c-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5c36a94c-9006-4550-a37e-978a65d2725c-headshot.jpg', 'https://en.wikipedia.org/wiki/Daniel_J._Hunt', 'https://malegislature.gov/Legislators/Profile/1200/djh1.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.625, '42d1c2dc5259e09205059aea71a72be72ed37d1a843048666eb513af92a9611a'),
  ('85bc5a78-1ff9-4d3e-9677-f2963c475e99'::uuid, '73afbe36-aa0c-4474-a2fc-6ff13bf20d71'::uuid, 'Edward R. Philips',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/73afbe36-aa0c-4474-a2fc-6ff13bf20d71-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/73afbe36-aa0c-4474-a2fc-6ff13bf20d71-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/73afbe36-aa0c-4474-a2fc-6ff13bf20d71-headshot.jpg', 'https://en.wikipedia.org/wiki/Ted_Philips', 'https://malegislature.gov/Legislators/Profile/1200/ERP1.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.622, 'a9146407dfac845d2c3f6f8d2a427005dde2d8d7828a9f5a15613416d50ff5aa'),
  ('f251b677-6733-4b47-a28d-149f5ae335d6'::uuid, '77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'Francisco E. Paulino',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/77ceaab2-846e-4bc8-b09d-faff40ddbc60-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/77ceaab2-846e-4bc8-b09d-faff40ddbc60-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/77ceaab2-846e-4bc8-b09d-faff40ddbc60-headshot.jpg', 'https://en.wikipedia.org/wiki/Francisco_E._Paulino', 'https://malegislature.gov/Legislators/Profile/1200/FEP1.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.625, '937731967c328792cb0cb60811bc8819e705286ede903c4d50944a68a2a85789'),
  ('bbe8b311-4ea6-4129-b5b8-00da2ed235bd'::uuid, '24e22813-4b39-4305-979d-1ea5f210a4f4'::uuid, 'Greg Casar',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/24e22813-4b39-4305-979d-1ea5f210a4f4-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/24e22813-4b39-4305-979d-1ea5f210a4f4-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/24e22813-4b39-4305-979d-1ea5f210a4f4-headshot.jpg', 'https://en.wikipedia.org/wiki/Greg_Casar', 'https://unitedstates.github.io/images/congress/original/C001131.jpg',
   'public_domain', 1.364, 'af214d4cd91702d1fecb75b8d054404c93d0c22614bebfe3f3931c02e005ca5d'),
  ('d96cc27d-d1cd-48ae-8c19-0acd6f4ea17c'::uuid, 'b28df80b-5302-4016-9274-8f8320b5b9a9'::uuid, 'Henry Cuellar',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b28df80b-5302-4016-9274-8f8320b5b9a9-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/b28df80b-5302-4016-9274-8f8320b5b9a9-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b28df80b-5302-4016-9274-8f8320b5b9a9-headshot.jpg', 'https://en.wikipedia.org/wiki/Henry_Cuellar', 'https://unitedstates.github.io/images/congress/original/C001063.jpg',
   'public_domain', 0.909, '61eb3ecfb2bd34a6d7e74b056cb655c80015678a1717076daf7e22f8561027f5'),
  ('3480ebb6-3c29-4334-9099-fd3e666cfd50'::uuid, 'bb7b3620-83cb-4b88-a823-95a8e09f6e46'::uuid, 'Jake Ellzey',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bb7b3620-83cb-4b88-a823-95a8e09f6e46-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/bb7b3620-83cb-4b88-a823-95a8e09f6e46-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bb7b3620-83cb-4b88-a823-95a8e09f6e46-headshot.jpg', 'https://en.wikipedia.org/wiki/Jake_Ellzey', 'https://unitedstates.github.io/images/congress/original/E000071.jpg',
   'public_domain', 0.209, '9d163cd6c4cd69db0edf7bdb9f27b178490f99811324508fbb89811733a316a6'),
  ('64f9d0c6-505a-431b-a99d-8ab0967d7dae'::uuid, 'c420f946-332c-46ed-be88-4cd11aa47543'::uuid, 'Jared Golden',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c420f946-332c-46ed-be88-4cd11aa47543-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/c420f946-332c-46ed-be88-4cd11aa47543-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c420f946-332c-46ed-be88-4cd11aa47543-headshot.jpg', 'https://en.wikipedia.org/wiki/Jared_Golden', 'https://unitedstates.github.io/images/congress/original/G000592.jpg',
   'public_domain', 1.333, 'b5b4907a408e78c5b5e44e9460ae2084aa00c2a4c569c93f93e64251890761ea'),
  ('b0d23f24-f2af-41eb-8a3e-0119f36e3351'::uuid, '10d7e182-3200-41d1-b391-2b9abad273ca'::uuid, 'Jasmine Crockett',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/10d7e182-3200-41d1-b391-2b9abad273ca-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/10d7e182-3200-41d1-b391-2b9abad273ca-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/10d7e182-3200-41d1-b391-2b9abad273ca-headshot.jpg', 'https://en.wikipedia.org/wiki/Jasmine_Crockett', 'https://unitedstates.github.io/images/congress/original/C001130.jpg',
   'public_domain', 1.364, '951714127b279181b8d67be46484ec8412600d98109b874d6f857e922d976c5f'),
  ('72151e3c-f33f-4705-b71a-045560e4a333'::uuid, '6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'Joan B. Lovely',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6d8717ca-45f9-42cf-bd28-6786a50d254f-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/6d8717ca-45f9-42cf-bd28-6786a50d254f-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6d8717ca-45f9-42cf-bd28-6786a50d254f-headshot.jpg', 'https://en.wikipedia.org/wiki/Joan_Lovely', 'https://malegislature.gov/Legislators/Profile/1200/JBL0.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.601, '645b1026ed9b0b17f6f9f610b1711faa01c98de086f9d7356e2cab1dcbc1014c'),
  ('29fbb792-1b37-465f-938b-b5c6342775a5'::uuid, '2bbfde18-85fc-4beb-9378-ec22e955a78a'::uuid, 'Jodey Arrington',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2bbfde18-85fc-4beb-9378-ec22e955a78a-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/2bbfde18-85fc-4beb-9378-ec22e955a78a-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2bbfde18-85fc-4beb-9378-ec22e955a78a-headshot.jpg', 'https://en.wikipedia.org/wiki/Jodey_Arrington', 'https://unitedstates.github.io/images/congress/original/A000375.jpg',
   'public_domain', 0.321, 'c9801aa33a3bdc6afd9a8309e926573ec48c864459dc6d8a947dc469e4a36981'),
  ('82bc978f-c639-4a45-8dc3-a21657b06968'::uuid, '2aa44302-0cd5-4ad1-9c43-557bb99bb88b'::uuid, 'John Carter',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2aa44302-0cd5-4ad1-9c43-557bb99bb88b-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/2aa44302-0cd5-4ad1-9c43-557bb99bb88b-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2aa44302-0cd5-4ad1-9c43-557bb99bb88b-headshot.jpg', 'https://en.wikipedia.org/wiki/John_Carter_(Texas_politician)', 'https://unitedstates.github.io/images/congress/original/C001051.jpg',
   'public_domain', 0.909, '6724e0e3c98240e8a2d5b130f7a80bdb5381f6e6b74a1b8d27566a8cf8a825c1'),
  ('ab74dde0-913d-4b81-a478-cba8774d910b'::uuid, '50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'John J. Mahoney',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/50838d91-2ce4-4aa6-8950-b87579860a4b-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/50838d91-2ce4-4aa6-8950-b87579860a4b-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/50838d91-2ce4-4aa6-8950-b87579860a4b-headshot.jpg', 'https://en.wikipedia.org/wiki/John_J._Mahoney', 'https://malegislature.gov/Legislators/Profile/1200/JJM2.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.626, '6625d60e52b275e424e238ff230b84ebd5d2388c6583842a4d51d0a8c6a9df59'),
  ('f3729a22-1f96-48ab-b135-2bd519bc207b'::uuid, 'bd451748-111f-461d-9752-95e7c243769e'::uuid, 'Julian A. Cyr',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bd451748-111f-461d-9752-95e7c243769e-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/bd451748-111f-461d-9752-95e7c243769e-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bd451748-111f-461d-9752-95e7c243769e-headshot.jpg', 'https://en.wikipedia.org/wiki/Julian_Cyr', 'https://malegislature.gov/Legislators/Profile/1200/JAC0.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.653, '366bf1fbb9436370aea94b250be3f463a02f5b04b10f633db05ab0b9bbd7c49c'),
  ('81b75637-8bf3-4fae-854c-0aab8a25b817'::uuid, '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, 'Liz Miranda',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2f7d598c-c3d7-48ba-ac9c-fb059e032bfe-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/2f7d598c-c3d7-48ba-ac9c-fb059e032bfe-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2f7d598c-c3d7-48ba-ac9c-fb059e032bfe-headshot.jpg', 'https://en.wikipedia.org/wiki/Liz_Miranda', 'https://malegislature.gov/Legislators/Profile/1200/L%20M0.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.706, '41c2bacad109457c3bd1aa334880011b1879be2637695b9a3ba2e8bb7cd62e41'),
  ('fe5466bb-5e07-4281-b0e2-b88ec6378409'::uuid, 'af3deea9-ba89-4d48-b16a-fa785b35a827'::uuid, 'Lizzie Fletcher',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/af3deea9-ba89-4d48-b16a-fa785b35a827-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/af3deea9-ba89-4d48-b16a-fa785b35a827-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/af3deea9-ba89-4d48-b16a-fa785b35a827-headshot.jpg', 'https://en.wikipedia.org/wiki/Lizzie_Fletcher', 'https://unitedstates.github.io/images/congress/original/F000468.jpg',
   'public_domain', 0.268, 'dd4ba42fca0db0102fe486d4b20040724a1e2d3b313cea83dc06e1a203448ac2'),
  ('390b65ce-64e7-4018-82ae-b9d1006ef4bc'::uuid, 'ad8e300f-59f0-4cc6-a818-1986842353d1'::uuid, 'Lloyd Doggett',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ad8e300f-59f0-4cc6-a818-1986842353d1-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/ad8e300f-59f0-4cc6-a818-1986842353d1-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ad8e300f-59f0-4cc6-a818-1986842353d1-headshot.jpg', 'https://en.wikipedia.org/wiki/Lloyd_Doggett', 'https://unitedstates.github.io/images/congress/original/D000399.jpg',
   'public_domain', 0.909, '2e1357b2d3b68cd8391006193a85a6c926974ea4b7fc09e1f100a8d53794ef7b'),
  ('05d6350e-4c48-42eb-bbaf-6eb00e813b8f'::uuid, '11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, 'Lydia M. Edwards',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/11d73e67-bcd9-419a-8b0d-a26447eb0c0b-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/11d73e67-bcd9-419a-8b0d-a26447eb0c0b-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/11d73e67-bcd9-419a-8b0d-a26447eb0c0b-headshot.jpg', 'https://en.wikipedia.org/wiki/Lydia_Edwards', 'https://malegislature.gov/Legislators/Profile/1200/LME0.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.632, 'e016ac6a4c814fbc5a09aa3c9d42cc9df4c3dc06f19d0fda20ac203d21776e00'),
  ('77201958-3a77-48dc-8407-4a703dd3e498'::uuid, 'b9f6f264-b42d-4bf6-b069-3a0d8d1f3b95'::uuid, 'Marc Veasey',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9f6f264-b42d-4bf6-b069-3a0d8d1f3b95-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/b9f6f264-b42d-4bf6-b069-3a0d8d1f3b95-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9f6f264-b42d-4bf6-b069-3a0d8d1f3b95-headshot.jpg', 'https://en.wikipedia.org/wiki/Marc_Veasey', 'https://unitedstates.github.io/images/congress/original/V000131.jpg',
   'public_domain', 0.99, '6ed7783e9469439236c8cd4452e0bce1da5bf1e1bdd9bf6d979dbb2530c5e367'),
  ('41e01327-8596-4085-baec-adaf6756f288'::uuid, '4e29212d-3ff9-42fc-bcd8-817ad6fd90d7'::uuid, 'Michael Cloud',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4e29212d-3ff9-42fc-bcd8-817ad6fd90d7-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/4e29212d-3ff9-42fc-bcd8-817ad6fd90d7-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4e29212d-3ff9-42fc-bcd8-817ad6fd90d7-headshot.jpg', 'https://en.wikipedia.org/wiki/Michael_Cloud_(politician)', 'https://unitedstates.github.io/images/congress/original/C001115.jpg',
   'public_domain', 0.214, '78990f56a60205cbf7acd3933ff8ddaf6371c5389b147eedf01c5ea0aa418b01'),
  ('f167840d-90a8-4cec-a590-f8b543c0b63d'::uuid, '541efc37-b332-4c80-8264-7b655efed5ac'::uuid, 'Nicholas A. Boldyga',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/541efc37-b332-4c80-8264-7b655efed5ac-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/541efc37-b332-4c80-8264-7b655efed5ac-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/541efc37-b332-4c80-8264-7b655efed5ac-headshot.jpg', 'https://en.wikipedia.org/wiki/Nicholas_Boldyga', 'https://malegislature.gov/Legislators/Profile/1200/NAG1.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.5, '295220a4dcd3f15e0f9578b98ea1082dabdf85cd742f51c56793b9af9cc73304'),
  ('9a926500-84b7-4727-b132-be46ce0f5d84'::uuid, 'e3cfee5b-29ab-427b-adc9-acd97e4b0f9a'::uuid, 'Pete Sessions',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e3cfee5b-29ab-427b-adc9-acd97e4b0f9a-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/e3cfee5b-29ab-427b-adc9-acd97e4b0f9a-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e3cfee5b-29ab-427b-adc9-acd97e4b0f9a-headshot.jpg', 'https://en.wikipedia.org/wiki/Pete_Sessions', 'https://unitedstates.github.io/images/congress/original/S000250.jpg',
   'public_domain', 0.909, 'd1c0e69365fbbcf594afe365c4be027e9175eb992630a2c42afa6881c1ae2bf8'),
  ('29188bdc-04e6-4363-afe0-815ff1d9416b'::uuid, 'd5b43e69-b0df-44d5-83ba-a4baca56dd3b'::uuid, 'Randy Weber',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d5b43e69-b0df-44d5-83ba-a4baca56dd3b-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/d5b43e69-b0df-44d5-83ba-a4baca56dd3b-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d5b43e69-b0df-44d5-83ba-a4baca56dd3b-headshot.jpg', 'https://en.wikipedia.org/wiki/Randy_Weber', 'https://unitedstates.github.io/images/congress/original/W000814.jpg',
   'public_domain', 0.909, 'c59b64a2652a1e70c9c52a32dc21a6ff35934eb4e93814c984869c64b656af68'),
  ('dd89e8fa-3f00-46e5-8f96-e4f791520663'::uuid, '42e2edff-6da4-49c2-ba60-fd4acbb326f7'::uuid, 'Roger Williams',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/42e2edff-6da4-49c2-ba60-fd4acbb326f7-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/42e2edff-6da4-49c2-ba60-fd4acbb326f7-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/42e2edff-6da4-49c2-ba60-fd4acbb326f7-headshot.jpg', 'https://en.wikipedia.org/wiki/Roger_Williams_(Texas_politician)', 'https://unitedstates.github.io/images/congress/original/W000816.jpg',
   'public_domain', 0.909, '9e9b085bb8de2f2f460cb7dd2202bb90c9fe06c6f454f6c9726c8bd386feacd9'),
  ('0f1372e6-6887-4ee8-ac14-2b96e86b1cff'::uuid, 'c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, 'Sal N. DiDomenico',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c7e94dda-1862-40fe-bda5-5fa2fe68f536-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/c7e94dda-1862-40fe-bda5-5fa2fe68f536-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c7e94dda-1862-40fe-bda5-5fa2fe68f536-headshot.jpg', 'https://en.wikipedia.org/wiki/Sal_DiDomenico', 'https://malegislature.gov/Legislators/Profile/1200/SND0.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.672, '5879bd951557111804411572e35d8c17224077f2460051323e97c4ae9c0554d6'),
  ('933e77cc-3283-48c3-827f-da464c9daba2'::uuid, '444ac209-7bfa-4f3a-a733-5666fd74fd66'::uuid, 'Sean Reid',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/444ac209-7bfa-4f3a-a733-5666fd74fd66-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/444ac209-7bfa-4f3a-a733-5666fd74fd66-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/444ac209-7bfa-4f3a-a733-5666fd74fd66-headshot.jpg', 'https://en.wikipedia.org/wiki/Sean_Reid_(politician)', 'https://malegislature.gov/Legislators/Profile/1200/S_R1.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.5, '589e531bcdfabe165a918fc5e346e92c243cd263ddfd8a369c359a8d4a89fc3c'),
  ('73745b66-0e3f-4946-a262-f1743b5ec57e'::uuid, '3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1'::uuid, 'Steven S. Howitt',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1-headshot.jpg', 'https://en.wikipedia.org/wiki/Steven_Howitt', 'https://malegislature.gov/Legislators/Profile/1200/SSH1.jpg',
   'Massachusetts General Court official member portrait (malegislature.gov). The General Court publishes no photo use policy at any discoverable path and the files carry no embedded rights statement; probed 2026-11-02. Identity confirmed by the member profile''s own alt text.', 0.5, 'dabc7b139ff74753b2a823cca91124235a2dd8c01583f8b3710dc52c98c132c8'),
  ('1ea3d6a1-a53f-4571-90c5-fab6c8df991b'::uuid, '6b817122-f196-4b72-b0b4-2d9763c4be47'::uuid, 'Susan M. Collins',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b817122-f196-4b72-b0b4-2d9763c4be47-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/6b817122-f196-4b72-b0b4-2d9763c4be47-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b817122-f196-4b72-b0b4-2d9763c4be47-headshot.jpg', 'https://en.wikipedia.org/wiki/Susan_Collins', 'https://unitedstates.github.io/images/congress/original/C001035.jpg',
   'public_domain', 2.667, '3fcab3b813b3ba0666a10afb64551fc5b8fcd214ee978156045bb47002565c1e'),
  ('e5194bbf-1a15-46a1-b642-ae16c8099e48'::uuid, 'a8bda21a-a5ca-4c15-9612-10fad5d5c9d6'::uuid, 'Ted Cruz',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a8bda21a-a5ca-4c15-9612-10fad5d5c9d6-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/a8bda21a-a5ca-4c15-9612-10fad5d5c9d6-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a8bda21a-a5ca-4c15-9612-10fad5d5c9d6-headshot.jpg', 'https://en.wikipedia.org/wiki/Ted_Cruz', 'https://unitedstates.github.io/images/congress/original/C001098.jpg',
   'public_domain', 0.909, '8be413a839847a259111890a283fb4d7d0df189de808ce601e65610022ffdbc4'),
  ('2193697f-f109-4097-b59d-4ca2024d7c59'::uuid, '276f0f2c-c521-417a-beb4-120b99915f13'::uuid, 'Veronica Escobar',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/276f0f2c-c521-417a-beb4-120b99915f13-headshot.jpg', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/portraits-2026-11/276f0f2c-c521-417a-beb4-120b99915f13-headshot.jpg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/276f0f2c-c521-417a-beb4-120b99915f13-headshot.jpg', 'https://en.wikipedia.org/wiki/Veronica_Escobar', 'https://unitedstates.github.io/images/congress/original/E000299.jpg',
   'public_domain', 0.179, '06fef6a2be8a95ae184bf9c92ad85ad23dccaa996df0da1de9f44eaa10bd625d');

-- ---------------------------------------------------------------------------------------------
-- Pre-flight.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM pw;
  IF v_n <> 38 THEN RAISE EXCEPTION 'pre-flight: expected 38 staged rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politician_images pi ON pi.id = f.image_id;
  IF v_n <> 38 THEN RAISE EXCEPTION 'pre-flight: % of 38 staged images exist', v_n; END IF;

  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.politician_id IS DISTINCT FROM f.pid OR pi.type <> 'default';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) are not that person''s default image', v_n;
  END IF;

  -- 🔴 Every staged row must still carry the values this file records, or the before-image is a lie.
  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE coalesce(pi.photo_license,'') IS DISTINCT FROM 'cc_by-sa'
      OR pi.url IS DISTINCT FROM f.old_url;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged image(s) no longer carry their recorded licence or URL', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politicians p ON p.id = f.pid
   WHERE coalesce(p.photo_custom_url,'') IS DISTINCT FROM f.old_custom
      OR coalesce(p.photo_origin_url,'') IS DISTINCT FROM f.old_origin;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) no longer carry their recorded scalar or origin', v_n;
  END IF;

  -- 🔴🔴 THE OBJECT IS BOUND TO THE PERSON, RECOMPUTED IN SQL FROM THE POLITICIAN ID. The storage
  --     key is <politician_id>-headshot.jpg, so a clean swap of two people's new URLs -- both
  --     well-formed, both on our CDN, both uploaded -- is caught here and nowhere else. A check
  --     derived from the generator's own pairing would move with that defect.
  SELECT count(*) INTO v_n FROM pw f
   WHERE f.new_url <> 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || 'portraits-2026-11/' || f.pid::text || '-headshot.jpg';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % new URL(s) are not this person''s own storage object', v_n;
  END IF;

  -- Licence follows the source, and the two sources carry different rights.
  SELECT count(*) INTO v_n FROM pw
   WHERE (new_lic = 'public_domain') <> (new_origin ~ 'unitedstates\.github\.io|bioguide\.congress\.gov');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % row(s) claim a licence their source does not support', v_n;
  END IF;

  -- 🔴 No Massachusetts row may assert reuse terms. The General Court grants nothing.
  SELECT count(*) INTO v_n FROM pw
   WHERE new_origin ~ 'malegislature\.gov'
     AND (new_lic ~* '^(public_domain|cc|press_use)' OR new_lic !~ 'no photo use policy');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % Massachusetts row(s) assert reuse terms that were never granted', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM pw WHERE scale > 3.0;
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

-- ---------------------------------------------------------------------------------------------
-- Post-verify.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_before int;
BEGIN
  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.url = f.new_url AND pi.photo_license = f.new_lic;
  IF v_n <> 38 THEN RAISE EXCEPTION 'post-verify: % of 38 images carry the new URL and licence', v_n; END IF;

  -- 🔴 THE SCALAR AND THE IMAGE ROW MUST AGREE, or the grid and the API serve different photographs.
  SELECT count(*) INTO v_n FROM pw f
    JOIN essentials.politicians p ON p.id = f.pid
    JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE coalesce(p.photo_custom_url,'') <> pi.url;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % row(s) have a scalar that disagrees with the image row', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM pw f JOIN essentials.politicians p ON p.id = f.pid
   WHERE p.photo_origin_url = f.new_origin;
  IF v_n <> 38 THEN RAISE EXCEPTION 'post-verify: % of 38 carry their new origin', v_n; END IF;

  -- 🔴 Delta, not a total.
  SELECT coalesce((SELECT n FROM lic_before WHERE lic = 'cc_by-sa'), 0) INTO v_before;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF v_before - v_n <> 38 THEN
    RAISE EXCEPTION 'post-verify: unversioned cc_by-sa fell by %, expected 38', v_before - v_n;
  END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
      FROM essentials.politician_images GROUP BY 1
  ) a
  FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) <> 'cc_by-sa'
     AND coalesce(a.lic, b.lic) NOT IN (SELECT DISTINCT new_lic FROM pw);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the replaced set changed count', v_n;
  END IF;
END $$;

COMMIT;
