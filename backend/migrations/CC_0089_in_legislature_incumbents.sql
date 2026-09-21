-- CC_0089_in_legislature_incumbents.sql
-- Knight Foundation program, wave IN-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0088, which creates the chambers, districts and offices.
--
-- Seats the 132 Indiana legislative offices CC_0088 created:
--    48 people created here, external_id band -1332001 .. -1332150
--    84 people REUSED from the existing indiana_discovery cohort
--    18 seats already held a person and are NOT touched by this migration
--
-- 🔴🔴 THE 92 REUSED ROWS ARE THE WHOLE POINT, AND THEY ARE NOT DUPLICATES BEING CREATED --
-- THEY ARE DUPLICATES BEING AVOIDED. Production holds 672 politicians sourced
-- 'indiana_discovery', 671 of whom hold an office with NO district_id, NO chamber_id and no
-- government: 305 'Indiana Elected Official', 231 'State Representative', 102 'State Senator'.
-- No address can reach any of them and nothing errors. 92 of the 150 sitting legislators are in
-- that cohort. Creating fresh rows for them would add 92 duplicates to Indiana's existing
-- duplicate problem, so this migration seats the people who are already there.
--
-- ⚠ 92 MATCHED, 84 ARE REUSED HERE, AND THE DIFFERENCE IS NOT A ROUNDING ERROR. The other
-- 8 sit on seats that were ALREADY held by a 'ballotready' row, so their office needs no
-- term and this migration does not touch them:
--     HD-46  roster "Robert Heaton"; already seated by a ballotready row; duplicate indiana_discovery row "Robert Heaton"
--     HD-63  roster "Shane Lindauer"; already seated by a ballotready row; duplicate indiana_discovery row "Shane Lindauer"
--     HD-96  roster "Gregory Porter"; already seated by a ballotready row; duplicate indiana_discovery row "Gregory Porter"
--     HD-99  roster "Vanessa Summers"; already seated by a ballotready row; duplicate indiana_discovery row "Vanessa Summers"
--     HD-100 roster "Blake Johnson"; already seated by a ballotready row; duplicate indiana_discovery row "Blake Johnson"
--     SD-37  roster "Rodric Bray"; already seated by a ballotready row; duplicate indiana_discovery row "Rodric Bray"
--     SD-39  roster "Eric Bassler"; already seated by a ballotready row; duplicate indiana_discovery row "Eric Bassler"
--     SD-44  roster "Eric Koch"; already seated by a ballotready row; duplicate indiana_discovery row "Eric Koch"
-- Each of those is TWO person rows for ONE human -- a genuine duplicate PERSON, not merely a
-- duplicate office. The ballotready row keeps the seat; the discovery row is left alone and is
-- part of the same recorded debt. Merging them is a dedupe decision about identity, and it is
-- deliberately not made inside a seeding wave.
--
-- 🟢 THE MATCH WAS TESTED, NOT ASSUMED. Not one of the 150 roster names matches more than one
-- indiana_discovery row -- checked explicitly, because 2 of 4 name hits in the GA wave were a
-- Colorado senator and a Utah treasurer. Corroborated a second way: of the 92, 57 hold an orphan
-- office whose title agrees with the chamber ('State Representative' for a House member), 35 hold
-- the generic 'Indiana Elected Official', and ZERO hold one that contradicts it.
--
-- ⚠ CONSEQUENCE, STATED RATHER THAN DISCOVERED LATER: after this migration each of those 92
-- people holds TWO offices -- the real, reachable one created by CC_0088, and the orphan one
-- they already had. That is expected and recorded. Retiring the 671 orphan offices is its own
-- wave: closing a term without flagging the office vacant pushes essentials.offices_missing_terms
-- unflagged drift up, and that is the count CI watches. Cleaning a seventh of the cohort would
-- make it harder to reason about, not easier.
--
-- 🔴 NO term_start EXISTS TO BE HAD, AND NONE IS INVENTED. getLegislatorDetails -- the richest
-- per-member endpoint iga.in.gov has -- returns lpid, honorific, firstname, lastname, statephone,
-- district_id, party, busemail, contact_form_url, caucus_page_url, bills[] and committees[].
-- No service-start of any kind. So every term is written OPEN-ENDED with start_precision
-- 'unknown', which is the GA-2 pattern (all 235 Georgia terms are 'unknown') and is what the 18
-- Indiana rows already in production carry. The seat_officeholder() helper is NOT used: it
-- refuses a NULL term_start, exactly as GA-4 found for its nine undated seats.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. Both sources carry it; party lives on races.primary_party.
--
-- 🔴 alternate_names IS NOT NULL DEFAULT '{}' -- an empty array is emitted, never NULL.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── 48 new people ────────────────────────────────────────────────────────────

CREATE TEMP TABLE in_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;
INSERT INTO in_new_people(external_id, full_name, first_name, last_name) VALUES
  (-1332002, 'Earl Harris', 'Earl', 'Harris'),
  (-1332007, 'Jake Teshka', 'Jake', 'Teshka'),
  (-1332009, 'Randy Novak', 'Randy', 'Novak'),
  (-1332010, 'Chuck Moseley', 'Chuck', 'Moseley'),
  (-1332011, 'Mike Aylesworth', 'Mike', 'Aylesworth'),
  (-1332012, 'Mike Andrade', 'Mike', 'Andrade'),
  (-1332013, 'Matt Commons', 'Matt', 'Commons'),
  (-1332020, 'Jim Pressel', 'Jim', 'Pressel'),
  (-1332025, 'Becky Cash', 'Becky', 'Cash'),
  (-1332026, 'Chris Campbell', 'Chris', 'Campbell'),
  (-1332032, 'Victoria Garcia Wilburn', 'Victoria', 'Garcia Wilburn'),
  (-1332033, 'J.D. Prescott', 'J.D.', 'Prescott'),
  (-1332038, 'Heath VanNatter', 'Heath', 'VanNatter'),
  (-1332039, 'Danny Lopez', 'Danny', 'Lopez'),
  (-1332044, 'Beau Baird', 'Beau', 'Baird'),
  (-1332047, 'Robb Greene', 'Robb', 'Greene'),
  (-1332048, 'Doug Miller', 'Doug', 'Miller'),
  (-1332051, 'Tony Isa', 'Tony', 'Isa'),
  (-1332052, 'Ben Smaltz', 'Ben', 'Smaltz'),
  (-1332056, 'Brad Barrett', 'Brad', 'Barrett'),
  (-1332058, 'Michelle Davis', 'Michelle', 'Davis'),
  (-1332064, 'Matt Hostettler', 'Matt', 'Hostettler'),
  (-1332066, 'Zach Payne', 'Zach', 'Payne'),
  (-1332067, 'Alex Zimmerman', 'Alex', 'Zimmerman'),
  (-1332069, 'Jim Lucas', 'Jim', 'Lucas'),
  (-1332071, 'Wendy Dant Chesser', 'Wendy', 'Dant Chesser'),
  (-1332074, 'Steve Bartels', 'Steve', 'Bartels'),
  (-1332077, 'Alex Burton', 'Alex', 'Burton'),
  (-1332079, 'Matt Lehman', 'Matt', 'Lehman'),
  (-1332083, 'Chris Judy', 'Chris', 'Judy'),
  (-1332088, 'Chris Jeter', 'Chris', 'Jeter'),
  (-1332089, 'Mitch Gore', 'Mitch', 'Gore'),
  (-1332101, 'Dan Dernulc', 'Dan', 'Dernulc'),
  (-1332105, 'Ed Charbonneau', 'Ed', 'Charbonneau'),
  (-1332112, 'Blake Doriot', 'Blake', 'Doriot'),
  (-1332113, 'Susan Glick', 'Susan', 'Glick'),
  (-1332115, 'Liz Brown', 'Liz', 'Brown'),
  (-1332117, 'Nick McKinley', 'Nick', 'McKinley'),
  (-1332122, 'Ron Alting', 'Ron', 'Alting'),
  (-1332125, 'Mike Gaskill', 'Mike', 'Gaskill'),
  (-1332127, 'Jeff Raatz', 'Jeff', 'Raatz'),
  (-1332128, 'Michael Crider', 'Michael', 'Crider'),
  (-1332129, 'J.D. Ford', 'J.D.', 'Ford'),
  (-1332134, 'La Keisha Jackson', 'La Keisha', 'Jackson'),
  (-1332135, 'Michael Young', 'Michael', 'Young'),
  (-1332138, 'Greg Goode', 'Greg', 'Goode'),
  (-1332143, 'Randy Maxwell', 'Randy', 'Maxwell'),
  (-1332145, 'Chris Garten', 'Chris', 'Garten');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Indiana General Assembly member list, https://iga.in.gov/api/getLegislators?session_lpid=session_2026', '{}'
FROM in_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 132 terms, one per office CC_0088 created ───────────────────────────

CREATE TEMP TABLE in_terms(geo_id text, district_type text, external_id bigint, politician_id uuid)
  ON COMMIT DROP;
INSERT INTO in_terms(geo_id, district_type, external_id, politician_id) VALUES
  ('18001', 'STATE_LOWER', NULL::bigint, '9ec5d907-b5d8-4f16-8379-703f748b58e0'::uuid),
  ('18002', 'STATE_LOWER', -1332002::bigint, NULL::uuid),
  ('18003', 'STATE_LOWER', NULL::bigint, 'cf1be32b-b0f4-47b7-9a46-1394f65987e6'::uuid),
  ('18004', 'STATE_LOWER', NULL::bigint, '79bb9e5a-a74a-44ef-a1c4-5b956ad36e5e'::uuid),
  ('18005', 'STATE_LOWER', NULL::bigint, 'eae88f55-a772-4aa7-9bae-8bc4e6c55ced'::uuid),
  ('18006', 'STATE_LOWER', NULL::bigint, 'fd414331-30b2-4be3-93f1-54b51af4ac49'::uuid),
  ('18007', 'STATE_LOWER', -1332007::bigint, NULL::uuid),
  ('18008', 'STATE_LOWER', NULL::bigint, '25b4eea9-089e-4a33-b39b-a6a7af676ac8'::uuid),
  ('18009', 'STATE_LOWER', -1332009::bigint, NULL::uuid),
  ('18010', 'STATE_LOWER', -1332010::bigint, NULL::uuid),
  ('18011', 'STATE_LOWER', -1332011::bigint, NULL::uuid),
  ('18012', 'STATE_LOWER', -1332012::bigint, NULL::uuid),
  ('18013', 'STATE_LOWER', -1332013::bigint, NULL::uuid),
  ('18014', 'STATE_LOWER', NULL::bigint, '6c52f78a-51c2-4b1f-b91d-a0c9451f5cc2'::uuid),
  ('18015', 'STATE_LOWER', NULL::bigint, '98255886-e292-47e7-bfd1-8bfe760bb460'::uuid),
  ('18016', 'STATE_LOWER', NULL::bigint, '634d4e4c-57e4-454d-9e40-94e6a0e46f04'::uuid),
  ('18017', 'STATE_LOWER', NULL::bigint, '45e48053-6db5-4e63-a5d7-2ad613340bd9'::uuid),
  ('18018', 'STATE_LOWER', NULL::bigint, '1e239b16-89e0-4a93-9724-0df547e079f3'::uuid),
  ('18019', 'STATE_LOWER', NULL::bigint, 'befd0035-e611-4d14-9da9-227156bb2c10'::uuid),
  ('18020', 'STATE_LOWER', -1332020::bigint, NULL::uuid),
  ('18021', 'STATE_LOWER', NULL::bigint, '48f99b45-486d-4d6d-8f48-ed21a793778f'::uuid),
  ('18022', 'STATE_LOWER', NULL::bigint, '4c3f4c61-882e-487b-a1dc-2fafce2539de'::uuid),
  ('18023', 'STATE_LOWER', NULL::bigint, '65534e3a-7ea3-4e85-98f8-57c6c3082ad2'::uuid),
  ('18024', 'STATE_LOWER', NULL::bigint, '452300b4-c6da-4866-be08-7462421673f1'::uuid),
  ('18025', 'STATE_LOWER', -1332025::bigint, NULL::uuid),
  ('18026', 'STATE_LOWER', -1332026::bigint, NULL::uuid),
  ('18027', 'STATE_LOWER', NULL::bigint, '4b0d1306-5004-482c-b5e4-44a6c1d542eb'::uuid),
  ('18028', 'STATE_LOWER', NULL::bigint, '3688a87d-4b4c-400c-ab5a-52c90896ef2f'::uuid),
  ('18029', 'STATE_LOWER', NULL::bigint, 'e0244003-7c41-48ba-863c-12cff608642b'::uuid),
  ('18030', 'STATE_LOWER', NULL::bigint, '9c4aa310-5706-42e8-b3f1-b5dee9b6f6fa'::uuid),
  ('18031', 'STATE_LOWER', NULL::bigint, '1e3c9273-2989-4511-9763-a431394792de'::uuid),
  ('18032', 'STATE_LOWER', -1332032::bigint, NULL::uuid),
  ('18033', 'STATE_LOWER', -1332033::bigint, NULL::uuid),
  ('18034', 'STATE_LOWER', NULL::bigint, '627467eb-e823-4bf1-b97d-026a36d55f43'::uuid),
  ('18035', 'STATE_LOWER', NULL::bigint, 'd9ca3eac-f51d-4d1a-b7ae-df5249459d24'::uuid),
  ('18036', 'STATE_LOWER', NULL::bigint, 'aa2ee278-9763-4a30-90a9-9231331ac129'::uuid),
  ('18037', 'STATE_LOWER', NULL::bigint, 'd2b8e2ab-dc6b-42a9-9aea-b6b661e0476e'::uuid),
  ('18038', 'STATE_LOWER', -1332038::bigint, NULL::uuid),
  ('18039', 'STATE_LOWER', -1332039::bigint, NULL::uuid),
  ('18040', 'STATE_LOWER', NULL::bigint, '946f7bc2-48ed-447e-a9a5-cb99aae00b31'::uuid),
  ('18041', 'STATE_LOWER', NULL::bigint, '6a200c04-7360-455e-b43d-f0ab2591a3cc'::uuid),
  ('18042', 'STATE_LOWER', NULL::bigint, 'd64c6b22-8a5a-41d2-b53b-c75fb57d1425'::uuid),
  ('18043', 'STATE_LOWER', NULL::bigint, '40200c4e-48b7-41b2-9c58-c8f2ab890ca4'::uuid),
  ('18044', 'STATE_LOWER', -1332044::bigint, NULL::uuid),
  ('18047', 'STATE_LOWER', -1332047::bigint, NULL::uuid),
  ('18048', 'STATE_LOWER', -1332048::bigint, NULL::uuid),
  ('18049', 'STATE_LOWER', NULL::bigint, 'b5a9a489-0784-428a-b1ed-81fd40e07ff5'::uuid),
  ('18050', 'STATE_LOWER', NULL::bigint, '7683de6a-e18c-42d2-9c90-6f5fe38f6932'::uuid),
  ('18051', 'STATE_LOWER', -1332051::bigint, NULL::uuid),
  ('18052', 'STATE_LOWER', -1332052::bigint, NULL::uuid),
  ('18053', 'STATE_LOWER', NULL::bigint, 'e869ec2a-2b8e-4b1f-a725-3f8cd4a2c48a'::uuid),
  ('18054', 'STATE_LOWER', NULL::bigint, '95e4f47c-a7e4-48c4-8b89-016c4cf3a44a'::uuid),
  ('18055', 'STATE_LOWER', NULL::bigint, '0408c7bf-e5f9-4754-b978-ad45e317afca'::uuid),
  ('18056', 'STATE_LOWER', -1332056::bigint, NULL::uuid),
  ('18057', 'STATE_LOWER', NULL::bigint, 'a8ef5f09-5bd2-4acb-9e83-549466878901'::uuid),
  ('18058', 'STATE_LOWER', -1332058::bigint, NULL::uuid),
  ('18059', 'STATE_LOWER', NULL::bigint, '217b8c85-424b-41df-aa1b-7818425623d7'::uuid),
  ('18064', 'STATE_LOWER', -1332064::bigint, NULL::uuid),
  ('18066', 'STATE_LOWER', -1332066::bigint, NULL::uuid),
  ('18067', 'STATE_LOWER', -1332067::bigint, NULL::uuid),
  ('18068', 'STATE_LOWER', NULL::bigint, 'ea05323c-8b6d-4b16-873c-083d9873889d'::uuid),
  ('18069', 'STATE_LOWER', -1332069::bigint, NULL::uuid),
  ('18070', 'STATE_LOWER', NULL::bigint, '066daefa-0c25-447b-8a80-e4007ee3103d'::uuid),
  ('18071', 'STATE_LOWER', -1332071::bigint, NULL::uuid),
  ('18072', 'STATE_LOWER', NULL::bigint, 'f58ce6de-755d-448f-9c0c-b21f9d386dad'::uuid),
  ('18073', 'STATE_LOWER', NULL::bigint, 'c93d27ca-26e9-46a1-a261-ed127313d43b'::uuid),
  ('18074', 'STATE_LOWER', -1332074::bigint, NULL::uuid),
  ('18075', 'STATE_LOWER', NULL::bigint, 'cd5fc12d-8d96-41e2-97ca-e00d28b1069a'::uuid),
  ('18076', 'STATE_LOWER', NULL::bigint, 'b79f38f2-02a9-4659-b4df-9e12535a2255'::uuid),
  ('18077', 'STATE_LOWER', -1332077::bigint, NULL::uuid),
  ('18078', 'STATE_LOWER', NULL::bigint, 'bba53cbb-15de-432f-9d6e-d0ab431eac15'::uuid),
  ('18079', 'STATE_LOWER', -1332079::bigint, NULL::uuid),
  ('18080', 'STATE_LOWER', NULL::bigint, '3dc58f52-11b7-43f3-80ce-64e4f82a0e7a'::uuid),
  ('18081', 'STATE_LOWER', NULL::bigint, 'a9bf758c-e902-40cc-ace0-b306c63eb936'::uuid),
  ('18082', 'STATE_LOWER', NULL::bigint, '32fbb733-d65c-457b-8ef0-f52e1701d284'::uuid),
  ('18083', 'STATE_LOWER', -1332083::bigint, NULL::uuid),
  ('18084', 'STATE_LOWER', NULL::bigint, 'fb5368e7-35c6-4ae0-b97b-b2e1fb5fb9a6'::uuid),
  ('18085', 'STATE_LOWER', NULL::bigint, '25b37d28-3c79-44bc-b5ee-6ff777d43c5e'::uuid),
  ('18086', 'STATE_LOWER', NULL::bigint, '3de8d183-2323-45d5-a178-4d24b8f56702'::uuid),
  ('18087', 'STATE_LOWER', NULL::bigint, '4810c896-5f26-41c4-837d-f1e8f5f6dc53'::uuid),
  ('18088', 'STATE_LOWER', -1332088::bigint, NULL::uuid),
  ('18089', 'STATE_LOWER', -1332089::bigint, NULL::uuid),
  ('18090', 'STATE_LOWER', NULL::bigint, 'c68d71a3-1ed0-4f20-804e-8d39fe0930e9'::uuid),
  ('18091', 'STATE_LOWER', NULL::bigint, '5922a7c4-65a4-46da-acb2-6df183e596b2'::uuid),
  ('18092', 'STATE_LOWER', NULL::bigint, '6a849ebb-4642-409f-98fc-4a85598fdd8c'::uuid),
  ('18093', 'STATE_LOWER', NULL::bigint, 'cfcb73c9-7689-4df6-b29f-0a8112af1336'::uuid),
  ('18094', 'STATE_LOWER', NULL::bigint, '5dd4fa3d-3348-4158-8d77-3b804c095a18'::uuid),
  ('18095', 'STATE_LOWER', NULL::bigint, '9613e582-652f-43d3-a986-0d941d3d2599'::uuid),
  ('18001', 'STATE_UPPER', -1332101::bigint, NULL::uuid),
  ('18002', 'STATE_UPPER', NULL::bigint, 'e8054d02-34c2-485b-b54a-47658cc269b7'::uuid),
  ('18003', 'STATE_UPPER', NULL::bigint, 'e5a011bc-2107-4d33-a3d0-827cbacf9398'::uuid),
  ('18004', 'STATE_UPPER', NULL::bigint, '4b938d2b-2e54-4fbc-b048-5406968644d2'::uuid),
  ('18005', 'STATE_UPPER', -1332105::bigint, NULL::uuid),
  ('18006', 'STATE_UPPER', NULL::bigint, '6e1a895d-a956-4806-8938-4977e34cac9a'::uuid),
  ('18007', 'STATE_UPPER', NULL::bigint, '5d57215a-7a47-4650-9c7b-47ff41d6322b'::uuid),
  ('18008', 'STATE_UPPER', NULL::bigint, '254be2be-bda5-40c3-b4de-fc261c3327b6'::uuid),
  ('18009', 'STATE_UPPER', NULL::bigint, '25becdfe-46ec-4a8a-88ec-8c85eed418b5'::uuid),
  ('18010', 'STATE_UPPER', NULL::bigint, '275cabb1-7a15-4bcf-88b5-10469a721244'::uuid),
  ('18011', 'STATE_UPPER', NULL::bigint, 'fe167afd-f670-4f13-9fee-2aa3fd6d048e'::uuid),
  ('18012', 'STATE_UPPER', -1332112::bigint, NULL::uuid),
  ('18013', 'STATE_UPPER', -1332113::bigint, NULL::uuid),
  ('18014', 'STATE_UPPER', NULL::bigint, '162def26-1875-44f6-8f46-1ac8128ead01'::uuid),
  ('18015', 'STATE_UPPER', -1332115::bigint, NULL::uuid),
  ('18016', 'STATE_UPPER', NULL::bigint, '3b65fd20-b548-4b7a-89b6-49ea5757218c'::uuid),
  ('18017', 'STATE_UPPER', -1332117::bigint, NULL::uuid),
  ('18018', 'STATE_UPPER', NULL::bigint, '250a7ae0-f130-449e-9625-4c2d1512bbf6'::uuid),
  ('18019', 'STATE_UPPER', NULL::bigint, '8b98d8e9-c41c-4722-80de-3bc5192656ee'::uuid),
  ('18020', 'STATE_UPPER', NULL::bigint, '4dcf4fa8-90f3-4717-9fa6-8e2fdbe9e602'::uuid),
  ('18021', 'STATE_UPPER', NULL::bigint, '6280a36a-9c26-4c22-a0d8-3ac06693fbfb'::uuid),
  ('18022', 'STATE_UPPER', -1332122::bigint, NULL::uuid),
  ('18023', 'STATE_UPPER', NULL::bigint, '8a3eb0a4-fa2a-4918-bf67-8d9ff22253f3'::uuid),
  ('18024', 'STATE_UPPER', NULL::bigint, '46652b6e-6439-4047-8616-0ec86460a2a3'::uuid),
  ('18025', 'STATE_UPPER', -1332125::bigint, NULL::uuid),
  ('18026', 'STATE_UPPER', NULL::bigint, '96f697c8-8614-4bc3-b796-bcf02a0380a1'::uuid),
  ('18027', 'STATE_UPPER', -1332127::bigint, NULL::uuid),
  ('18028', 'STATE_UPPER', -1332128::bigint, NULL::uuid),
  ('18029', 'STATE_UPPER', -1332129::bigint, NULL::uuid),
  ('18030', 'STATE_UPPER', NULL::bigint, '33e307e0-dc84-43c0-b842-de34268c206d'::uuid),
  ('18031', 'STATE_UPPER', NULL::bigint, 'eb94127d-d394-4704-a53b-1efb2db3bc60'::uuid),
  ('18032', 'STATE_UPPER', NULL::bigint, '7ac75846-3990-45d0-b74a-b85d6d672f61'::uuid),
  ('18034', 'STATE_UPPER', -1332134::bigint, NULL::uuid),
  ('18035', 'STATE_UPPER', -1332135::bigint, NULL::uuid),
  ('18036', 'STATE_UPPER', NULL::bigint, '326c5247-950b-407d-a10b-1116c49098f0'::uuid),
  ('18038', 'STATE_UPPER', -1332138::bigint, NULL::uuid),
  ('18041', 'STATE_UPPER', NULL::bigint, 'e93bb9f1-8f60-4f56-a492-0e40d7d49647'::uuid),
  ('18042', 'STATE_UPPER', NULL::bigint, '38aa44f1-2579-44fb-b520-f055f2edfd70'::uuid),
  ('18043', 'STATE_UPPER', -1332143::bigint, NULL::uuid),
  ('18045', 'STATE_UPPER', -1332145::bigint, NULL::uuid),
  ('18047', 'STATE_UPPER', NULL::bigint, '1ea3c520-481e-4975-9fcb-ef1c508d680f'::uuid),
  ('18048', 'STATE_UPPER', NULL::bigint, '82bb4a77-7067-474f-a442-0b6c65988323'::uuid),
  ('18049', 'STATE_UPPER', NULL::bigint, 'dfab8491-551f-4a3f-b76c-d220a9f4b23b'::uuid),
  ('18050', 'STATE_UPPER', NULL::bigint, '34f7e7f3-84f9-484e-be41-e3300c18f7f1'::uuid);

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown', 'Indiana General Assembly member list, https://iga.in.gov/api/getLegislators?session_lpid=session_2026, reconciled against Open States, https://data.openstates.org/people/current/in.csv, read 2026-09-10 (CC_0089, IN-2)'
FROM in_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type = t.district_type AND lower(d.state) = 'in'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p
  ON (t.politician_id IS NOT NULL AND p.id = t.politician_id)
  OR (t.external_id  IS NOT NULL AND p.external_id = t.external_id)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_seated   int;
  v_offices  int;
  v_dated    int;
  v_ended    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -1332150 AND -1332001;
  IF v_people <> 48 THEN
    RAISE EXCEPTION 'IN-2 occupancy: expected 48 people in the reserved band, got %', v_people;
  END IF;

  -- count(och.politician_id), never count(*): office_current_holder LEFT JOINs from offices.
  SELECT count(o.id), count(och.politician_id) INTO v_offices, v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> 150 OR v_seated <> 150 THEN
    RAISE EXCEPTION 'IN-2 occupancy: expected 150 offices all seated, got % offices / % seated',
      v_offices, v_seated;
  END IF;

  -- Nothing may carry an invented date, and nothing may carry an end date.
  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_dated <> 0 OR v_ended <> 0 THEN
    RAISE EXCEPTION 'IN-2 occupancy: % terms carry a term_start and % carry a term_end; Indiana publishes neither',
      v_dated, v_ended;
  END IF;

  RAISE NOTICE 'IN-2 occupancy OK: 150 offices, 150 seated, 0 dated, 0 ended';
END $$;

COMMIT;
