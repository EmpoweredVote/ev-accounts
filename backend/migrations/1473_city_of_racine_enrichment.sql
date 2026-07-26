-- Migration 1473: City of Racine officeholder enrichment (headshots + contact)
--
-- Source: cityofracinewi.gov (WordPress; no WAF -- plain curl -sL works, but -L is REQUIRED
--   because the apex URL 301s). Roster <img src> is a lazy-load inline SVG placeholder, so
--   WebFetch reports "placeholder image" and sees no photos; the real files are on the
--   media.cityofracinewi.gov CDN and must be matched from the raw markup.
-- Headshots: 15 aldermen at 300x300 and Mayor Mason at 212x250 are the ONLY sizes published
--   (probed for -scaled/original variants: all 403). Upscaled to the 600x750 standard with
--   Lanczos + unsharp 2x1+1.5+0.012, per the headshots.md low-res rule; samples approved by
--   user 2026-07-26 before batch processing (same precedent as Maine Phase 52-03).
-- Emails: aldermen publish First.Last@cityofracine.org -- note the .org domain, NOT the
--   site's .gov, and the page markup capitalises it @CityOfRacine.org (a case-sensitive
--   regex silently misses 6 of 15). Domain normalised to lowercase; local part left as published.
-- Mayor Mason publishes NO personal email: his page offers a phone, a Gravity contact form,
--   and only a staffer's address under "Staff Info". Recorded as web_form_url; the staffer's
--   address is deliberately NOT attributed to him.
-- Renee Kelly (D13) shares ONE politician row with her Racine County D2 supervisor seat
--   (merged by migration 1450). Her county 384x384 portrait is retained as higher quality --
--   no city image row is inserted -- and her city email is APPENDED to the county one.
-- Idempotent: image inserts guard on politician_id; emails use array_append with a
--   membership test, so re-running never duplicates an address.

BEGIN;

-- 1) Headshot rows ---------------------------------------------------------
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6cd02c2b-6bca-4b74-9703-0917872bf3f7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6cd02c2b-6bca-4b74-9703-0917872bf3f7-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='6cd02c2b-6bca-4b74-9703-0917872bf3f7');  -- Mayor Cory Mason
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c52c91ca-a08f-4b8b-a26e-7971a25b52a0', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c52c91ca-a08f-4b8b-a26e-7971a25b52a0-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='c52c91ca-a08f-4b8b-a26e-7971a25b52a0');  -- D1 Malik Frazier
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '21a99682-c016-4eb1-850b-3bf07818596d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/21a99682-c016-4eb1-850b-3bf07818596d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='21a99682-c016-4eb1-850b-3bf07818596d');  -- D2 Alyson Weiss
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '433fcd8d-29dd-44e9-8d99-5f5a2f72ca7b', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/433fcd8d-29dd-44e9-8d99-5f5a2f72ca7b-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='433fcd8d-29dd-44e9-8d99-5f5a2f72ca7b');  -- D3 Olivia Turquoise Davis
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '359c3243-f328-4cfd-b13a-0c319acf1b6d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/359c3243-f328-4cfd-b13a-0c319acf1b6d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='359c3243-f328-4cfd-b13a-0c319acf1b6d');  -- D4 David L. Maack
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'bc8463aa-5db8-41cd-a3cb-34608e9f9a7c', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bc8463aa-5db8-41cd-a3cb-34608e9f9a7c-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='bc8463aa-5db8-41cd-a3cb-34608e9f9a7c');  -- D5 Jens Jorgensen
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e13f9358-153f-4358-9f31-3238b05f71bb', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e13f9358-153f-4358-9f31-3238b05f71bb-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='e13f9358-153f-4358-9f31-3238b05f71bb');  -- D6 Sandy Weidner
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '47cdf9e8-d5f8-4cb3-aeab-8d8ef1be4909', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47cdf9e8-d5f8-4cb3-aeab-8d8ef1be4909-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='47cdf9e8-d5f8-4cb3-aeab-8d8ef1be4909');  -- D7 Maurice Horton
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6bd87474-91f1-4381-bdfe-b54de0477497', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6bd87474-91f1-4381-bdfe-b54de0477497-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='6bd87474-91f1-4381-bdfe-b54de0477497');  -- D8 Brittany Hodges
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7cd80dd2-bbc6-4ae0-8445-b8688bf19c47', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7cd80dd2-bbc6-4ae0-8445-b8688bf19c47-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='7cd80dd2-bbc6-4ae0-8445-b8688bf19c47');  -- D9 Grace Allen
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'afcc665d-1d0a-4bc5-a681-b535801aa044', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/afcc665d-1d0a-4bc5-a681-b535801aa044-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='afcc665d-1d0a-4bc5-a681-b535801aa044');  -- D10 Sam Peete
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a9762952-cb70-4546-8862-a4cba2137c1f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a9762952-cb70-4546-8862-a4cba2137c1f-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='a9762952-cb70-4546-8862-a4cba2137c1f');  -- D11 Mary Land
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '144aea3e-8903-4a38-b509-d46cc0c47b21', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/144aea3e-8903-4a38-b509-d46cc0c47b21-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='144aea3e-8903-4a38-b509-d46cc0c47b21');  -- D12 Rocco DeMark
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b9ff7e84-79b3-45a1-b9c6-b6b303771b14', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9ff7e84-79b3-45a1-b9c6-b6b303771b14-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='b9ff7e84-79b3-45a1-b9c6-b6b303771b14');  -- D14 Marlo Harmon
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '951d059a-0cf5-46ba-9eda-fb96cbe1da8b', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/951d059a-0cf5-46ba-9eda-fb96cbe1da8b-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='951d059a-0cf5-46ba-9eda-fb96cbe1da8b');  -- D15 Nathan Pabon

-- 2) photo_origin_url -----------------------------------------------------
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/mayor/' WHERE id='6cd02c2b-6bca-4b74-9703-0917872bf3f7' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-1/' WHERE id='c52c91ca-a08f-4b8b-a26e-7971a25b52a0' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/02-district/' WHERE id='21a99682-c016-4eb1-850b-3bf07818596d' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/03-district/' WHERE id='433fcd8d-29dd-44e9-8d99-5f5a2f72ca7b' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/04-district/' WHERE id='359c3243-f328-4cfd-b13a-0c319acf1b6d' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-5/' WHERE id='bc8463aa-5db8-41cd-a3cb-34608e9f9a7c' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-6/' WHERE id='e13f9358-153f-4358-9f31-3238b05f71bb' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-7/' WHERE id='47cdf9e8-d5f8-4cb3-aeab-8d8ef1be4909' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-8/' WHERE id='6bd87474-91f1-4381-bdfe-b54de0477497' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-9/' WHERE id='7cd80dd2-bbc6-4ae0-8445-b8688bf19c47' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-10/' WHERE id='afcc665d-1d0a-4bc5-a681-b535801aa044' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-11/' WHERE id='a9762952-cb70-4546-8862-a4cba2137c1f' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-12/' WHERE id='144aea3e-8903-4a38-b509-d46cc0c47b21' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-14/' WHERE id='b9ff7e84-79b3-45a1-b9c6-b6b303771b14' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://cityofracinewi.gov/government/city-leadership/common-council/cityalderman/district-15/' WHERE id='951d059a-0cf5-46ba-9eda-fb96cbe1da8b' AND photo_origin_url IS NULL;

-- 3) Emails (array_append; Kelly keeps her county address too) ------------
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Malik.Frazier@cityofracine.org')
 WHERE id='c52c91ca-a08f-4b8b-a26e-7971a25b52a0' AND NOT ('Malik.Frazier@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D1 Malik Frazier
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Alyson.Weiss@cityofracine.org')
 WHERE id='21a99682-c016-4eb1-850b-3bf07818596d' AND NOT ('Alyson.Weiss@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D2 Alyson Weiss
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Olivia.Turquoise-Davis@cityofracine.org')
 WHERE id='433fcd8d-29dd-44e9-8d99-5f5a2f72ca7b' AND NOT ('Olivia.Turquoise-Davis@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D3 Olivia Turquoise Davis
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'David.Maack@cityofracine.org')
 WHERE id='359c3243-f328-4cfd-b13a-0c319acf1b6d' AND NOT ('David.Maack@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D4 David L. Maack
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Jens.Jorgensen@cityofracine.org')
 WHERE id='bc8463aa-5db8-41cd-a3cb-34608e9f9a7c' AND NOT ('Jens.Jorgensen@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D5 Jens Jorgensen
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Sandy.Weidner@cityofracine.org')
 WHERE id='e13f9358-153f-4358-9f31-3238b05f71bb' AND NOT ('Sandy.Weidner@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D6 Sandy Weidner
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Maurice.Horton@cityofracine.org')
 WHERE id='47cdf9e8-d5f8-4cb3-aeab-8d8ef1be4909' AND NOT ('Maurice.Horton@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D7 Maurice Horton
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Brittany.Hodges@cityofracine.org')
 WHERE id='6bd87474-91f1-4381-bdfe-b54de0477497' AND NOT ('Brittany.Hodges@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D8 Brittany Hodges
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Grace.Allen@cityofracine.org')
 WHERE id='7cd80dd2-bbc6-4ae0-8445-b8688bf19c47' AND NOT ('Grace.Allen@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D9 Grace Allen
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Sam.Peete@cityofracine.org')
 WHERE id='afcc665d-1d0a-4bc5-a681-b535801aa044' AND NOT ('Sam.Peete@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D10 Sam Peete
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Mary.Land@cityofracine.org')
 WHERE id='a9762952-cb70-4546-8862-a4cba2137c1f' AND NOT ('Mary.Land@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D11 Mary Land
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Rocco.DeMark@cityofracine.org')
 WHERE id='144aea3e-8903-4a38-b509-d46cc0c47b21' AND NOT ('Rocco.DeMark@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D12 Rocco DeMark
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Renee.Kelly@cityofracine.org')
 WHERE id='6c040b24-d9cc-48ad-8271-3cfead5a6c5d' AND NOT ('Renee.Kelly@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D13 Renee Kelly
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Marlo.Harmon@cityofracine.org')
 WHERE id='b9ff7e84-79b3-45a1-b9c6-b6b303771b14' AND NOT ('Marlo.Harmon@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D14 Marlo Harmon
UPDATE essentials.politicians SET email_addresses=array_append(coalesce(email_addresses,'{}'),'Nathan.Pabon@cityofracine.org')
 WHERE id='951d059a-0cf5-46ba-9eda-fb96cbe1da8b' AND NOT ('Nathan.Pabon@cityofracine.org' = ANY(coalesce(email_addresses,'{}')));  -- D15 Nathan Pabon

-- 4) Mayor contact form ---------------------------------------------------
UPDATE essentials.politicians SET web_form_url='https://cityofracinewi.gov/government/city-leadership/mayor/contact-the-mayor/'
WHERE id='6cd02c2b-6bca-4b74-9703-0917872bf3f7' AND web_form_url IS NULL;

COMMIT;
