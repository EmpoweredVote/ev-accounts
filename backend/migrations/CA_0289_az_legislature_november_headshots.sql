-- CA_0289_az_legislature_november_headshots.sql
--
-- Slot CA_0289 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Headshots for 82 of the 91 people CA_0282 created (AZ legislature, November 2026 candidates). The 71
-- existing people in those races already had one.
--
-- Source: Arizona Secretary of State, 2026 General Election candidate list
--   (apps.arizona.vote/electioninfo/Election/69), the candidate photos the page shows. The site blocks
--   scripted fetches (Cloudflare), so the operator saved the page from a browser ("Webpage, Complete",
--   2026-09-24) and the files were matched to people by the photo URL in the captured list.
-- Processing (find-headshots convention): near-white letterbox padding removed where the SOS had padded
--   the image (48 of 85), centre crop to 4:5, Lanczos resize to 600x750, JPEG q90. Sources are ~248x348,
--   so these are upscaled — the NV / ME / 1283 low-res precedent. Uploaded to Storage politician_photos
--   as <politician_id>-headshot.jpg; every public URL was re-fetched and byte-compared to the local file
--   (82/82 identical) before this file was written.
-- Licence: 'press_use'. The photos are candidate-supplied for the state voter guide — not government works.
-- Every photo was reviewed by the operator on a contact page (2026-09-24). REJECTED, no row:
--   Michiel "Mike" Montiel, Nick Fierro, Charles "Charlie" Eakins (distant full-body shots / face not the subject).
-- NO SOS PHOTO: Royce "RJ" Mark Jenkins, Samuel "Sam" Martin, Jacob D. Martinez, Jackie O'Donnell Anderson, Jonathan McKenna, Hector Gomez.
--
-- IDEMPOTENT: an image row is inserted only when the person has none; photo_origin_url only when NULL.
-- ROLLBACK: DELETE FROM essentials.politician_images WHERE url LIKE the 82 files below; set
--   photo_origin_url NULL on the same people; remove the Storage objects.

BEGIN;

CREATE TEMP TABLE ca0289_img ON COMMIT DROP AS
SELECT v.ext, v.full_name, p.id AS pid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || v.file AS url,
       v.sos_file
  FROM (VALUES
  (-66000333::bigint, 'Christine Ellen Dargon', 'bec05bfa-5963-4efa-bb32-59e0eb2364ae-headshot.jpg', 'dargon-christine-23774-29724.jpg'),
  (-66000334::bigint, 'Amelia Gallitano', '40fd6d44-21e9-4244-8806-a058f94596af-headshot.jpg', 'gallitano-mendel-amelia-24752-29785.jpg'),
  (-66000335::bigint, 'Jeffrey Fortney', '4398ee7f-d169-4a6a-960c-767990667728-headshot.jpg', 'fortney-jeffrey-23926-29305.jpg'),
  (-66000336::bigint, 'Frank Bertone', 'da6841a8-0bc9-43f9-92bc-9dca07b45a63-headshot.jpg', 'bertone-frank-24909.jpg'),
  (-66000337::bigint, 'Aaron Lieberman', 'a6d492a6-0d29-4d8d-8533-a3ae82284696-headshot.jpg', 'lieberman-aaron-23837-28171.jpg'),
  (-66000338::bigint, 'Christine Marsh', 'e7ce87c4-3b49-418d-ba10-88aaf4d827e2-headshot.jpg', 'marsh-christine-24977.jpg'),
  (-66000339::bigint, 'Jason LaForest', '98a6dd9e-3341-4b61-99f0-ef1c58e433ca-headshot.jpg', 'laforest-jason-24445-30094.jpg'),
  (-66000340::bigint, 'Lloyd Johnson', 'b8bed9af-8d85-47a9-8b5e-5ec0a3179931-headshot.jpg', 'johnson-lloyd-22889-26426.jpg'),
  (-66000341::bigint, 'Jamescita Peshlakai', 'b285d29b-14f3-491e-a7a1-d94e30219bb8-headshot.jpg', 'peshlakai-jamescita-24732-28987.jpg'),
  (-66000343::bigint, 'Bill Loughrige', '99f7ca91-2092-42b2-b0b8-991d193da5d1-headshot.jpg', 'loughrige-bill-24873-30259.jpg'),
  (-66000344::bigint, 'Bridget Fitzgibbons', '406ec8f2-496f-4581-8b90-390f3de42c61-headshot.jpg', 'fittzgibbons-bridget-23938-27876.jpg'),
  (-66000345::bigint, 'Blair Moses', '4f1e579c-f749-48d9-ac84-a0d67aeb7d73-headshot.jpg', 'moses-blair-24135-28256.jpg'),
  (-66000347::bigint, 'Joshua Ayala', 'c18348ab-53dd-47ae-8e1a-43cb7f4a0bca-headshot.jpg', 'ayala-joshua-23960-27920.jpg'),
  (-66000348::bigint, 'Anthony Jason Ramirez', 'b346d645-5ec3-4d81-8fc1-fa2646c4940d-headshot.jpg', 'ramirez-anthony-24725-28934.jpg'),
  (-66000349::bigint, 'Gary Hatch', '0b59d571-71e3-494b-bb5b-f8df403ba483-headshot.jpg', 'hatch-gary-24906-30312.jpg'),
  (-66000350::bigint, 'Kristie O''Brien', '662e8d2c-e6db-4cb8-a59e-afe84f98fcba-headshot.jpg', 'obrien-kristie-23667-28955.jpg'),
  (-66000351::bigint, 'Mylie Biggs', '5228b577-e6f3-424a-8b65-f59e66011fca-headshot.jpg', 'biggs-mylie-23823-27755.jpg'),
  (-66000352::bigint, 'Stephanie Walsh', '7a106961-81b8-4e70-9c71-8b5d29adb393-headshot.jpg', 'walsh-stephanie-24063-30132.jpg'),
  (-66000353::bigint, 'Jayme Accalia', '9ad33d82-ff55-42e2-a061-8b6f3b1c6486-headshot.jpg', 'accalia-jayme-24597-28751.jpg'),
  (-66000354::bigint, 'Elaine Aldrete', 'c8e2ec0c-5f00-450f-ac09-2959c072b262-headshot.jpg', 'aldrete-elaine-23884-27923.jpg'),
  (-66000355::bigint, 'Christopher King', 'c3a2280d-1b31-4753-b090-7599f6110988-headshot.jpg', 'king-christopher-23970-27947.jpg'),
  (-66000356::bigint, 'Edgar Soto', '5f8498b8-913e-4126-9b94-fe224e96bbee-headshot.jpg', 'soto-edgar-24378-28486.jpg'),
  (-66000357::bigint, 'Douglas Everett', 'c279ce30-1b32-44da-ba58-f45e40f0f906-headshot.jpg', 'everett-douglas-23752-27573.jpg'),
  (-66000358::bigint, 'Bob Karp', '300a3a29-5220-48d1-9754-758308e5c9b9-headshot.jpg', 'karp-bob-25116.jpg'),
  (-66000359::bigint, 'Esteban Flores', '8383e359-8dfd-4b40-b7b2-22de0df76173-headshot.jpg', 'flores-esteban-24961.jpg'),
  (-66000360::bigint, 'Michelle Altherr', '0f46b706-0c33-4466-9241-204ceb34a5ca-headshot.jpg', 'altherr-michelle-23542-28972.jpg'),
  (-66000361::bigint, 'Frank Steele', 'b3d2e07f-d503-4d3e-a230-0e7d7abe0272-headshot.jpg', 'steele-frank-24405-28519.jpg'),
  (-66000362::bigint, 'Laura Huber', '4dab6220-2d87-4d28-ad98-f863899a2861-headshot.jpg', 'huber-laura-24021-28021.jpg'),
  (-66000363::bigint, 'Jim Bishop', '3ece9161-6073-4f01-b338-c944cf0324d4-headshot.jpg', 'bishop-jim-24094-28156.jpg'),
  (-66000364::bigint, 'Kyle Clayton', '5c195e73-0c38-40a6-a37f-0c4be15d2aae-headshot.jpg', 'clayton-kyle-24111-28663.jpg'),
  (-66000365::bigint, 'Michael Braun', 'e8052df2-a15f-447d-a97b-86da48dd8498-headshot.jpg', 'braun-michael-23895-30149.jpg'),
  (-66000366::bigint, 'Eric Stafford', '0688018a-0996-4ba8-ba45-021e848bce49-headshot.jpg', 'stafford-eric-25042.jpg'),
  (-66000367::bigint, 'Sandy Zalecki', '709ce928-607a-4395-b1d3-1b4811fbc39c-headshot.jpg', 'zalecki-sandy-23950-28084.jpg'),
  (-66000369::bigint, 'Paul Carver', 'a4247832-2028-4035-a1b8-e8b722754da2-headshot.jpg', 'carver-paul-24881-30236.jpg'),
  (-66000370::bigint, 'George Khalaf', '96779cfb-7dce-4cca-9143-72c399acba3a-headshot.jpg', 'khalaf-george-24102-29713.jpg'),
  (-66000371::bigint, 'Julie Gable', '583c17bf-66f7-4575-b710-d265183fd9aa-headshot.jpg', 'gable-julie-24739-29389.jpg'),
  (-66000372::bigint, 'Richard "Rick" Robert Spargo', '42b81e16-b007-4319-a123-f16ee3abc736-headshot.jpg', 'spargo-richard-23948-27995.jpg'),
  (-66000373::bigint, 'John Skirbst', '60a5f6f1-03c3-44ed-b232-b94ca44ed623-headshot.jpg', 'skirbst-john-25113.jpg'),
  (-66000374::bigint, 'Tammy Caputi', '07013ded-08dd-4a36-b5b6-308e481593eb-headshot.jpg', 'caputi-tammy-24755-29102.jpg'),
  (-66000375::bigint, 'Karen Gresham', 'f49e66b1-28ab-4256-8d5c-1cc28e0f9f5e-headshot.jpg', 'gresham-karen-25015.jpg'),
  (-66000376::bigint, 'Ian Teller', 'e25fc2cd-d932-431a-bcc0-99a9b6b3c631-headshot.jpg', 'teller-ian-23842-27744.jpg'),
  (-66000377::bigint, 'Brendan Trachsel', 'e4b83e10-c332-4f35-ad88-18a72b36de32-headshot.jpg', 'trachsel-brendan-24806-29455.jpg'),
  (-66000379::bigint, 'David Cook Sr.', 'b2def48c-4092-4518-babc-c6080ded42cf-headshot.jpg', 'cook-david-24940.jpg'),
  (-66000381::bigint, 'Richard Grayson', '21d125ba-69b0-4b5e-a44c-85aa82ae7b6f-headshot.jpg', 'grayson-richard-25114.jpg'),
  (-66000382::bigint, 'Donald Hawker', '2af0db83-5c21-41e4-9d4a-89c7b2e7c133-headshot.jpg', 'hawker-donald-24756-29054.jpg'),
  (-66000383::bigint, 'Bradley D. Bettencourt', '832fafc5-36d4-48e2-88e9-5923986e36fb-headshot.jpg', 'bettencourt-bradley-23868-29940.jpg'),
  (-66000385::bigint, 'James Rogers', '42c171d8-3a23-46b8-8593-e29374274a3e-headshot.jpg', 'rogers-james-23803-30022.jpg'),
  (-66000386::bigint, 'Brian Calaway', '3ef6e94f-0a9d-4d3d-bc33-2d6f95c41add-headshot.jpg', 'calaway-brian-24163-28253.jpg'),
  (-66000387::bigint, 'Helen Hunter', '9b456bc1-ec35-4617-9bc7-685114906971-headshot.jpg', 'hunter-helen-25068.jpg'),
  (-66000388::bigint, 'David Scott', '508fa6d8-a830-4556-bc8f-88c95306f75d-headshot.jpg', 'scott-david-24760-30154.jpg'),
  (-66000389::bigint, 'Cesar Aleman', '8f41f8c9-a073-4956-8799-80c7d9ba2976-headshot.jpg', 'aleman-cesar-23962-27929.jpg'),
  (-66000390::bigint, 'Joseph Charles Dailey', '8673f82d-bf26-4ddd-9dc6-6c1ed3480863-headshot.jpg', 'dailey-joseph-23956-28155.jpg'),
  (-66000391::bigint, 'David Richardson', 'd49351b8-eb13-41b9-bb80-6c7ada640d19-headshot.jpg', 'richardson-david-25072.jpg'),
  (-66000392::bigint, 'Armando Montero', 'cb3d61dd-5569-4083-b732-3926afa80fa1-headshot.jpg', 'montero-armando-23974-30107.jpg'),
  (-66000393::bigint, 'Kevin Hartke', '7a991413-5e99-4473-8665-c50d156edfa6-headshot.jpg', 'hartke-kevin-23829-30148.jpg'),
  (-66000394::bigint, 'Janet Weninger', 'ad080c0e-e211-49b3-bbd2-694def3e524a-headshot.jpg', 'weninger-janet-23917-28113.jpg'),
  (-66000395::bigint, 'Racquel "Rockee" Armstrong', '8faecbdb-437b-45ed-a061-4e7c92bb804d-headshot.jpg', 'armstrong-rockee-23805-27663.jpg'),
  (-66000396::bigint, 'Jacob Weinberg', 'd6b66293-551a-42c7-9158-acf6d179d35f-headshot.jpg', 'weinberg-jacob-24774-29217.jpg'),
  (-66000397::bigint, 'Tyler Andrew Farnsworth', 'a606ad9f-bc71-4154-9d7f-1f4b593a584f-headshot.jpg', 'farnsworth-tyler-24797-29431.jpg'),
  (-66000398::bigint, 'Mary Rose', 'fe9517ef-324a-44a3-95e7-4f5c3eb7e2c5-headshot.jpg', 'rose-mary-23783-27811.jpg'),
  (-66000399::bigint, 'Julia Romero Gusse', 'c4844e6a-8463-4611-86c5-fc3b418e8307-headshot.jpg', 'gusse-juliaromero-25092-30923.jpg'),
  (-66000400::bigint, 'John Winchester', 'bc898046-f89b-48c3-a56f-dbc2adc73e71-headshot.jpg', 'winchester-john-24052-28088.jpg'),
  (-66000401::bigint, 'Hollace "Holly" Lyon', '8e9c654c-96ca-4400-9546-b87f5e1e6ce0-headshot.jpg', 'lyon-hollace-25091.jpg'),
  (-66000402::bigint, 'Bob Dohse', '343d8f1f-63b0-4805-9ad0-940995a35e3e-headshot.jpg', 'dohse-bob-23484-30129.jpg'),
  (-66000404::bigint, 'Aiden Nicholette Swallow', '102305cc-e6aa-480d-adb5-bbc2d2aa7eff-headshot.jpg', 'swallow-aiden-23890-28969.jpg'),
  (-66000405::bigint, 'Christopher Kibbey', 'd7e8bfdb-9575-4137-a85c-95adc2a8c997-headshot.jpg', 'kibbey-christopher-23488-27191.jpg'),
  (-66000406::bigint, 'Miranda Lopez', '0755c7f9-868a-4f0f-812f-23b0bf809735-headshot.jpg', 'lopez-miranda-24344-28661.jpg'),
  (-66000407::bigint, 'Betsy Munoz', 'fb782cf9-f5cf-444b-8f95-039792bce28c-headshot.jpg', 'munoz-betsy-24121-28188.jpg'),
  (-66000408::bigint, 'Gary Garcia Snyder', '9dc1fc82-56dc-4f0e-a6fb-2a642a75c78b-headshot.jpg', 'garciasnyder-gary-24090-29699.jpg'),
  (-66000409::bigint, 'Emilia Cortez', '9a418e10-e0c6-460f-8084-3ac0bbb85a82-headshot.jpg', 'cortez-emilia-24066-29010.jpg'),
  (-66000410::bigint, 'Delores McLaughlin', '9341f86a-9800-4705-994b-37c2c8b61424-headshot.jpg', 'mclaughlin-delores-24455-30142.jpg'),
  (-66000411::bigint, 'Lisbeth Arescurenaga', '433844aa-c80f-4168-a908-66244419feff-headshot.jpg', 'arescurenaga-lisbeth-23963-30081.jpg'),
  (-66000412::bigint, 'Alberto Flores', 'a271fc70-2cf1-4374-b579-82ae4007b1f3-headshot.jpg', 'flores-alberto-24147-28543.jpg'),
  (-66000413::bigint, 'Tiffany Byrne', '1ad9d855-e499-4a37-85fc-7359851f591c-headshot.jpg', 'byrne-tiffany-24139-28228.jpg'),
  (-66000415::bigint, 'Frank Roberts', '8e68ba41-86b1-4eed-8907-6a7c068b1678-headshot.jpg', 'roberts-frank-23988-30108.jpg'),
  (-66000417::bigint, 'Deborah Howard', 'a0b8deea-5347-442a-bf62-a48cf6d9f228-headshot.jpg', 'howard-deborah-23736-27542.jpg'),
  (-66000418::bigint, 'Barbara Fike', '37508991-a40c-470c-8087-eb0972661b19-headshot.jpg', 'fike-barbara-24131-28212.jpg'),
  (-66000419::bigint, 'Marc Graham', '10c0b936-996d-4982-bc09-42e20443ee0a-headshot.jpg', 'graham-marc-23925-29068.jpg'),
  (-66000420::bigint, 'Christine Marie Scianna', '186a3b90-48b4-46cb-a737-ac34b3cdadc7-headshot.jpg', 'scianna-christine-23914-27847.jpg'),
  (-66000421::bigint, 'Mike Gannuscio', '2c906e4d-5fd4-440c-bf97-358aa5b5dafb-headshot.jpg', 'gannuscio-mike-24113-30165.jpg'),
  (-66000422::bigint, 'David Rose', '8f6d28bd-fe31-403f-acb5-4988ef4600ab-headshot.jpg', 'rose-david-23355-26949.jpg'),
  (-66000423::bigint, 'Brian McMahan', 'ccfc3d75-e579-437c-bb8c-c1a5a417381d-headshot.jpg', 'mcmahan-brian-25097.jpg')
  ) AS v(ext, full_name, file, sos_file)
  LEFT JOIN essentials.politicians p ON p.external_id = v.ext AND p.full_name = v.full_name
   AND p.source LIKE 'CA_0282 (2026-09-24):%';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0289_img WHERE pid IS NOT NULL AND url LIKE '%/' || pid::text || '-headshot.jpg';
  IF n <> 82 THEN RAISE EXCEPTION 'PRE: resolved % of 82 CA_0282 people to their file', n; END IF;
  SELECT count(*) INTO n FROM ca0289_img c JOIN essentials.politician_images i ON i.politician_id = c.pid
   WHERE i.url <> c.url;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the 82 already have a different image', n; END IF;
  RAISE NOTICE 'CA_0289 pre-flight OK';
END $$;

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), c.pid, c.url, 'default', 'press_use'
  FROM ca0289_img c
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = c.pid);

UPDATE essentials.politicians p
   SET photo_origin_url = 'https://apps.arizona.vote/electioninfo/Election/69'
  FROM ca0289_img c
 WHERE p.id = c.pid AND p.photo_origin_url IS NULL;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0289_img c
   WHERE (SELECT count(*) FROM essentials.politician_images i
           WHERE i.politician_id = c.pid AND i.url = c.url AND i.type = 'default' AND i.photo_license = 'press_use') = 1
     AND (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id = c.pid) = 1
     AND (SELECT photo_origin_url FROM essentials.politicians WHERE id = c.pid) = 'https://apps.arizona.vote/electioninfo/Election/69';
  IF n <> 82 THEN RAISE EXCEPTION 'POST: % of 82 people carry exactly their one headshot', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.source LIKE 'CA_0282 (2026-09-24):%'
     AND NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = p.id);
  IF n <> 9 THEN RAISE EXCEPTION 'POST: % CA_0282 people without a headshot, expected 9 (3 rejected + 6 no photo)', n; END IF;

  RAISE NOTICE 'CA_0289 applied: 82 AZ legislature candidate headshots';
END $$;

COMMIT;
