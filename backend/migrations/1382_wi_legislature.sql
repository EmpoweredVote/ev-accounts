-- 1382_wi_legislature.sql
-- Seed the full 132-member sitting Wisconsin Legislature: 33 Senate + 99 Assembly.
-- STRUCTURAL migration. Idempotent. GENERATED from the Open States v3 roster --
-- do not hand-edit; regenerate instead (see PROVENANCE below).
--
-- PRECONDITION -- the WI sldu/sldl TIGER load (NOT migration 1380/1381, which are the
-- 2026 candidate seeds and are unrelated): the 33 STATE_UPPER +
-- 99 STATE_LOWER essentials.districts rows (geo_id 55001..55033 / 55001..55099,
-- mtfcc G5210/G5220, state='wi') are created by
--   npx tsx scripts/load-state-tiger-boundaries.ts --state WI --fips 55 --layers sldu,sldl
-- This migration will insert ZERO offices if that load has not run.
--
-- PROVENANCE: Open States v3 /people?jurisdiction=Wisconsin (OPENSTATES_API_KEY already in
--   backend/.env), fetched 2026-07-25. 132 members returned: districts 1-33 (upper) and
--   1-99 (lower), each exactly once, no gaps, no duplicates. Party split 72 R / 60 D,
--   matching the real chamber composition. Photos are the Legislature's own
--   docs.legis.wisconsin.gov images, stored on photo_origin_url (NOT photo_custom_url,
--   which is reserved for manual overrides -- migration 192 D-08).
--
-- CRITICAL (shared geo_id space): WI SLDU and SLDL BOTH number 55001.. AND collide with
--   county FIPS (Racine County is 55101, Adams County is 55001). geo_id 55001 therefore
--   matches THREE districts rows. Every office<->district WHERE below pins BOTH
--   district_type AND state, or a join would silently mislink a senator onto an Assembly
--   district or a county. Verified post-load: the three tiers are disambiguated by mtfcc.
--
-- CRITICAL (state casing): legislative districts are LOWERCASE state='wi' (TIGER loader
--   convention for this tier) whereas the WI STATE_EXEC/NATIONAL tier uses uppercase
--   'WI'. Do not "normalize" these.
--
-- Wisconsin nests exactly 3 Assembly districts per Senate district, so the counts are
--   33 and 99 as DISTINCT polygons -- unlike AZ (1286), where 2 House members share one
--   SLDL polygon. Each WI district has exactly 1 member, so the simpler
--   (district_id, chamber_id) office guard is correct for BOTH chambers here.
--
-- Titles follow each state's own nomenclature (cf. CA "Assembly Member", MD "Delegate"):
--   WI uses "State Senator" and "Representative to the Assembly" (the formal title the
--   Wisconsin Elections Commission prints on the ballot).
--
-- ANTIPARTISAN: politicians.party IS populated here, matching every other officeholder
--   seed (1286 AZ, 1053 NV, the existing WI congressional delegation). The antipartisan
--   rule governs DISPLAY, not storage -- party must never be rendered as a candidate label.
--
-- Open States had no photo for 1 member(s); photo_origin_url is NULL for:
--   STATE_LOWER D44 Ann Roe
--   (backfill via the find-headshots skill)
BEGIN;

-- ── 1. Two legislative chambers under the State of Wisconsin (geo_id '55') ──
-- chambers.slug is GENERATED ALWAYS from name_formal -- never in the INSERT column list.
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'State Senate', 'Wisconsin State Senate',
       (SELECT id FROM essentials.governments WHERE geo_id = '55'), 33
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'State Senate'
     AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '55')
);
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Assembly', 'Wisconsin State Assembly',
       (SELECT id FROM essentials.governments WHERE geo_id = '55'), 99
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'Assembly'
     AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '55')
);

-- ── 2. 132 politician rows (idempotent on external_id) ──
-- external_id: -5505001..-5505033 Senate, -5506001..-5506099 Assembly (district-aligned,
-- mirroring 1286 AZ's -4005xxx/-4006xxx scheme). Block verified unused before writing.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party, is_active, is_incumbent,
   is_appointed, is_vacant, photo_origin_url, email_addresses, data_source)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, v.party,
       true, true, false, false, v.photo_origin_url,
       CASE WHEN v.email IS NULL THEN NULL ELSE ARRAY[v.email] END,
       'openstates-v3-wi'
FROM (VALUES
    (-5505001::bigint, 'André Jacque'::text, 'André'::text, 'Jacque'::text, 'Republican'::text, 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2419.jpg'::text, 'sen.jacque@legis.wisconsin.gov'::text),  -- UPPER D1
    (-5505002, 'Eric Wimberger', 'Eric', 'Wimberger', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2439.jpg', 'sen.wimberger@legis.wisconsin.gov'),  -- UPPER D2
    (-5505003, 'Tim Carpenter', 'Tim', 'Carpenter', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2413.jpg', 'sen.carpenter@legis.wisconsin.gov'),  -- UPPER D3
    (-5505004, 'Dora Drake', 'Dora', 'Drake', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2462.jpg', 'sen.drake@legis.wisconsin.gov'),  -- UPPER D4
    (-5505005, 'Rob Hutton', 'Rob', 'Hutton', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2560.jpg', 'sen.hutton@legis.wisconsin.gov'),  -- UPPER D5
    (-5505006, 'LaTonya Johnson', 'LaTonya', 'Johnson', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2421.jpg', 'sen.johnson@legis.wisconsin.gov'),  -- UPPER D6
    (-5505007, 'Chris Larson', 'Chris', 'Larson', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2424.jpg', 'sen.larson@legis.wisconsin.gov'),  -- UPPER D7
    (-5505008, 'Jodi Habush Sinykin', 'Jodi', 'Habush Sinykin', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Jodi_Habush_Sinykin.PNG', 'sen.habushsinykin@legis.wisconsin.gov'),  -- UPPER D8
    (-5505009, 'Devin LeMahieu', 'Devin', 'LeMahieu', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2425.jpg', 'sen.lemahieu@legis.wisconsin.gov'),  -- UPPER D9
    (-5505010, 'Rob Stafsholt', 'Rob', 'Stafsholt', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2434.jpg', 'sen.stafsholt@legis.wisconsin.gov'),  -- UPPER D10
    (-5505011, 'Steve Nass', 'Steve', 'Nass', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2427.jpg', 'sen.nass@legis.wisconsin.gov'),  -- UPPER D11
    (-5505012, 'Mary Felzkowski', 'Mary', 'Felzkowski', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2417.jpg', 'rep.felzkowski@legis.wisconsin.gov'),  -- UPPER D12
    (-5505013, 'John Jagler', 'John', 'Jagler', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2420.jpg', 'sen.jagler@legis.wisconsin.gov'),  -- UPPER D13
    (-5505014, 'Sarah Keyeski', 'Sarah', 'Keyeski', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/SarahKeyeski24.jpg', 'sen.keyeski@legis.wisconsin.gov'),  -- UPPER D14
    (-5505015, 'Mark Spreitzer', 'Mark', 'Spreitzer', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2561.jpg', 'sen.spreitzer@legis.wisconsin.gov'),  -- UPPER D15
    (-5505016, 'Melissa Ratcliff', 'Melissa', 'Ratcliff', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2546.jpg', 'sen.ratcliff@legis.wisconsin.gov'),  -- UPPER D16
    (-5505017, 'Howard Marklein', 'Howard', 'Marklein', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2426.jpg', 'sen.marklein@legis.wi.gov'),  -- UPPER D17
    (-5505018, 'Kristin Dassler-Alfheim', 'Kristin', 'Dassler-Alfheim', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/KristinAlfheim2024.jpeg', 'sen.dassler-alfheim@legis.wisconsin.gov'),  -- UPPER D18
    (-5505019, 'Rachael Cabral-Guevara', 'Rachael', 'Cabral-Guevara', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2562.jpg', 'sen.cabral-guevara@legis.wisconsin.gov'),  -- UPPER D19
    (-5505020, 'Dan Feyen', 'Dan', 'Feyen', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2418.jpg', 'sen.feyen@legis.wi.gov'),  -- UPPER D20
    (-5505021, 'Van Wanggaard', 'Van', 'Wanggaard', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2438.jpg', 'sen.wanggaard@legis.wisconsin.gov'),  -- UPPER D21
    (-5505022, 'Bob Wirch', 'Bob', 'Wirch', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2440.jpg', 'sen.wirch@legis.wisconsin.gov'),  -- UPPER D22
    (-5505023, 'Jesse James', 'Jesse', 'James', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2563.jpg', 'sen.james@legis.wisconsin.gov'),  -- UPPER D23
    (-5505024, 'Patrick Testin', 'Patrick', 'Testin', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2437.jpg', 'sen.testin@legis.wisconsin.gov'),  -- UPPER D24
    (-5505025, 'Romaine Quinn', 'Romaine', 'Quinn', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2564.jpg', 'sen.quinn@legis.wisconsin.gov'),  -- UPPER D25
    (-5505026, 'Kelda Roys', 'Kelda', 'Roys', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2432.jpg', 'sen.roys@legis.wisconsin.gov'),  -- UPPER D26
    (-5505027, 'Dianne Hesselbein', 'Dianne', 'Hesselbein', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2566.jpg', 'sen.hesselbein@legis.wisconsin.gov'),  -- UPPER D27
    (-5505028, 'Julian Bradley', 'Julian', 'Bradley', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2412.jpg', 'sen.bradley@legis.wisconsin.gov'),  -- UPPER D28
    (-5505029, 'Cory Tomczyk', 'Cory', 'Tomczyk', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2567.jpg', 'sen.tomczyk@legis.wisconsin.gov'),  -- UPPER D29
    (-5505030, 'Jamie Wall', 'Jamie', 'Wall', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/JamieWall2024.jpg', 'sen.wall@legis.wisconsin.gov'),  -- UPPER D30
    (-5505031, 'Jeff Smith', 'Jeff', 'Smith', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2433.jpg', 'sen.smith@legis.wisconsin.gov'),  -- UPPER D31
    (-5505032, 'Brad Pfaff', 'Brad', 'Pfaff', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2429.jpg', 'sen.pfaff@legis.wisconsin.gov'),  -- UPPER D32
    (-5505033, 'Chris Kapenga', 'Chris', 'Kapenga', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2422.jpg', 'sen.kapenga@legis.wisconsin.gov'),  -- UPPER D33
    (-5506001, 'Joel Kitchens', 'Joel', 'Kitchens', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2476.jpg', 'rep.kitchens@legis.wisconsin.gov'),  -- LOWER D1
    (-5506002, 'Shae Sortwell', 'Shae', 'Sortwell', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2516.jpg', 'rep.sortwell@legis.wisconsin.gov'),  -- LOWER D2
    (-5506003, 'Ron Tusler', 'Ron', 'Tusler', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2528.jpg', 'rep.tusler@legis.wisconsin.gov'),  -- LOWER D3
    (-5506004, 'David Steffen', 'David', 'Steffen', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2519.jpg', 'rep.steffen@legis.wisconsin.gov'),  -- LOWER D4
    (-5506005, 'Joy Goeben', 'Joy', 'Goeben', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2542.jpg', 'rep.goeben@legis.wisconsin.gov'),  -- LOWER D5
    (-5506006, 'Elijah Behnke', 'Elijah', 'Behnke', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2447.jpg', 'rep.behnke@legis.wisconsin.gov'),  -- LOWER D6
    (-5506007, 'Karen Kirsch', 'Karen', 'Kirsch', 'Democratic', 'https://shepherdexpress.com/downloads/66652/download/Karen-Kirsch.jpg?cb=13a333d591ca9798f5ad320c3b7ce126&w=1200&h=', 'rep.kirsch@legis.wisconsin.gov'),  -- LOWER D7
    (-5506008, 'Sylvia Ortiz-Velez', 'Sylvia', 'Ortiz-Velez', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2496.jpg', 'rep.ortiz-velez@legis.wisconsin.gov'),  -- LOWER D8
    (-5506009, 'Priscilla Prado', 'Priscilla', 'Prado', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/PriscillaPrado2024.jpeg', 'rep.prado@legis.wisconsin.gov'),  -- LOWER D9
    (-5506010, 'Darrin Madison', 'Darrin', 'Madison', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2536.jpg', 'rep.madison@legis.wisconsin.gov'),  -- LOWER D10
    (-5506011, 'Sequanna Taylor', 'Sequanna', 'Taylor', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/IMG_5830-min.JPG', 'rep.taylor@legis.wisconsin.gov'),  -- LOWER D11
    (-5506012, 'Russell Goodwin', 'Russell', 'Goodwin', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/rg.jpeg', 'rep.goodwin@legis.wisconsin.gov'),  -- LOWER D12
    (-5506013, 'Robyn Vining', 'Robyn', 'Vining', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2530.jpg', 'rep.vining@legis.wisconsin.gov'),  -- LOWER D13
    (-5506014, 'Angelito Tenorio', 'Angelito', 'Tenorio', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Sep2720211220PM_104500298_AngelitoHeadshot.jpg', 'rep.tenorio@legis.wisconsin.gov'),  -- LOWER D14
    (-5506015, 'Adam Neylon', 'Adam', 'Neylon', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2492.jpg', 'rep.neylon@legis.wisconsin.gov'),  -- LOWER D15
    (-5506016, 'Kalan Haywood', 'Kalan', 'Haywood', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2468.jpg', 'rep.haywood@legis.wisconsin.gov'),  -- LOWER D16
    (-5506017, 'Supreme Moore Omokunde', 'Supreme', 'Moore Omokunde', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2486.jpg', 'rep.mooreomokunde@legis.wisconsin.gov'),  -- LOWER D17
    (-5506018, 'Margaret Arney', 'Margaret', 'Arney', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Brennan_Balestrieri_20240808_094539.jpg', 'rep.arney@legis.wisconsin.gov'),  -- LOWER D18
    (-5506019, 'Ryan Clancy', 'Ryan', 'Clancy', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2538.jpg', 'rep.clancy@legis.wisconsin.gov'),  -- LOWER D19
    (-5506020, 'Christine Sinicki', 'Christine', 'Sinicki', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2512.jpg', 'rep.sinicki@legis.wisconsin.gov'),  -- LOWER D20
    (-5506021, 'Jessie Rodriguez', 'Jessie', 'Rodriguez', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2505.jpg', 'rep.rodriguez@legis.wisconsin.gov'),  -- LOWER D21
    (-5506022, 'Paul Melotik', 'Paul', 'Melotik', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2690.jpg', 'rep.melotik@legis.wisconsin.gov'),  -- LOWER D22
    (-5506023, 'Deb Andraca', 'Deb', 'Andraca', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2443.jpg', 'rep.andraca@legis.wisconsin.gov'),  -- LOWER D23
    (-5506024, 'Dan Knodl', 'Dan', 'Knodl', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/senate/2688.jpg', 'rep.knodl@legis.wisconsin.gov'),  -- LOWER D24
    (-5506025, 'Paul Tittl', 'Paul', 'Tittl', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2526.jpg', 'rep.tittl@legis.wisconsin.gov'),  -- LOWER D25
    (-5506026, 'Joe Sheehan', 'Joe', 'Sheehan', 'Democratic', 'https://sheehanforassembly.com/wp-content/uploads/2024/08/Joe_Sheehan-scaled-e1724167126836-1024x825.jpeg', 'rep.sheehan@legis.wisconsin.gov'),  -- LOWER D26
    (-5506027, 'Lindee Brill', 'Lindee', 'Brill', 'Republican', 'https://static.wixstatic.com/media/3d690d_54cafbce3962411589e2a2742be35965~mv2.jpg/v1/fill/w_489,h_634,al_c,lg_1,q_80,enc_avif,quality_auto/3d690d_54cafbce3962411589e2a2742be35965~mv2.jpg', 'rep.brill@legis.wisconsin.gov'),  -- LOWER D27
    (-5506028, 'Rob Kreibich', 'Rob', 'Kreibich', 'Republican', 'https://www.kreibichforassembly.com/hobenug/themes/kreibich-wi/assets/kreibich_1.jpg', 'rep.kreibich@legis.wisconsin.gov'),  -- LOWER D28
    (-5506029, 'Treig Pronschinske', 'Treig', 'Pronschinske', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2502.jpg', 'rep.pronschinske@legis.wisconsin.gov'),  -- LOWER D29
    (-5506030, 'Shannon Zimmerman', 'Shannon', 'Zimmerman', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2535.jpg', 'rep.zimmerman@legis.wisconsin.gov'),  -- LOWER D30
    (-5506031, 'Tyler August', 'Tyler', 'August', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2445.jpg', 'rep.august@legis.wisconsin.gov'),  -- LOWER D31
    (-5506032, 'Amanda Nedweski', 'Amanda', 'Nedweski', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2551.jpg', 'rep.nedweski@legis.wisconsin.gov'),  -- LOWER D32
    (-5506033, 'Robin Vos', 'Robin', 'Vos', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2531.jpg', 'rep.vos@legis.wisconsin.gov'),  -- LOWER D33
    (-5506034, 'Rob Swearingen', 'Rob', 'Swearingen', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2523.jpg', 'rep.swearingen@legis.wisconsin.gov'),  -- LOWER D34
    (-5506035, 'Calvin Callahan', 'Calvin', 'Callahan', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2456.jpg', 'rep.callahan@legis.wisconsin.gov'),  -- LOWER D35
    (-5506036, 'Jeff Mursau', 'Jeff', 'Mursau', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2489.jpg', 'rep.mursau@legis.wisconsin.gov'),  -- LOWER D36
    (-5506037, 'Mark Born', 'Mark', 'Born', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2449.jpg', 'rep.born@legis.wisconsin.gov'),  -- LOWER D37
    (-5506038, 'Will Penterman', 'Will', 'Penterman', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2497.jpg', 'rep.penterman@legis.wisconsin.gov'),  -- LOWER D38
    (-5506039, 'Alex Dallman', 'Alex', 'Dallman', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2459.jpg', 'rep.dallman@legis.wisconsin.gov'),  -- LOWER D39
    (-5506040, 'Karen DeSanto', 'Karen', 'DeSanto', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Karen_DeSanto_20241106_112902.jpg', 'rep.desanto@legis.wisconsin.gov'),  -- LOWER D40
    (-5506041, 'Tony Kurtz', 'Tony', 'Kurtz', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2479.jpg', 'rep.kurtz@legis.wisconsin.gov'),  -- LOWER D41
    (-5506042, 'Maureen McCarville', 'Maureen', 'McCarville', 'Democratic', 'https://static1.squarespace.com/static/661c4ad59cca8c36cee06052/t/6630dc1cdd4eb0334f4f6768/1714478116835/MaureenMcCarville_AD42_Headshot.JPG', 'rep.mccarville@legis.wisconsin.gov'),  -- LOWER D42
    (-5506043, 'Brienne Brown', 'Brienne', 'Brown', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Brienne_Brown.jpg', 'rep.brown@legis.wisconsin.gov'),  -- LOWER D43
    (-5506044, 'Ann Roe', 'Ann', 'Roe', 'Democratic', NULL, 'rep.roe@legis.wisconsin.gov'),  -- LOWER D44
    (-5506045, 'Clint Anderson', 'Clint', 'Anderson', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2559.jpg', 'rep.canderson@legis.wisconsin.gov'),  -- LOWER D45
    (-5506046, 'Joan Fitzgerald', 'Joan', 'Fitzgerald', 'Democratic', 'https://images.squarespace-cdn.com/content/v1/65b3fbbf2b490f4bfe76c24e/6ba4a753-b2b3-4338-a77b-0f73f067f2cb/JoanFitzgerald%2857of76%29.jpg?format=1500w', 'rep.fitzgerald@legis.wisconsin.gov'),  -- LOWER D46
    (-5506047, 'Randy Udell', 'Randy', 'Udell', 'Democratic', 'https://bloximages.chicago2.vip.townnews.com/captimes.com/content/tncms/assets/v3/editorial/c/7b/c7b832ac-dbcf-11ee-ab35-771e1438be52/65e88e3c05aed.image.jpg?crop=1163%2C871%2C26%2C52&resize=668%2C500&order=crop%2Cresize', 'rep.udell@legis.wisconsin.gov'),  -- LOWER D47
    (-5506048, 'Andrew Hysell', 'Andrew', 'Hysell', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/ahysell2.jpg', 'rep.hysell@legis.wisconsin.gov'),  -- LOWER D48
    (-5506049, 'Travis Tranel', 'Travis', 'Tranel', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2527.jpg', 'rep.tranel@legis.wisconsin.gov'),  -- LOWER D49
    (-5506050, 'Jenna Jacobson', 'Jenna', 'Jacobson', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2545.jpg', 'rep.jacobson@legis.wisconsin.gov'),  -- LOWER D50
    (-5506051, 'Todd Novak', 'Todd', 'Novak', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2493.jpg', 'rep.novak@legis.wisconsin.gov'),  -- LOWER D51
    (-5506052, 'Lee Snodgrass', 'Lee', 'Snodgrass', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2514.jpg', 'rep.snodgrass@legis.wisconsin.gov'),  -- LOWER D52
    (-5506053, 'Dean Kaufert', 'Dean', 'Kaufert', 'Republican', 'http://legis.wisconsin.gov/sitecollectionimages/2013/asm55.jpeg', 'rep.kaufert@legis.wisconsin.gov'),  -- LOWER D53
    (-5506054, 'Lori Palmeri', 'Lori', 'Palmeri', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2547.jpg', 'rep.palmeri@legis.wisconsin.gov'),  -- LOWER D54
    (-5506055, 'Gus Gustafson', 'Gus', 'Gustafson', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2550.jpg', 'rep.gustafson@legis.wisconsin.gov'),  -- LOWER D55
    (-5506056, 'Dave Murphy', 'Dave', 'Murphy', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2488.jpg', 'rep.murphy@legis.wisconsin.gov'),  -- LOWER D56
    (-5506057, 'Kevin Petersen', 'Kevin', 'Petersen', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2498.jpg', 'rep.petersen@legis.wisconsin.gov'),  -- LOWER D57
    (-5506058, 'Rick Gundrum', 'Rick', 'Gundrum', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2467.jpg', 'rep.gundrum@legis.wisconsin.gov'),  -- LOWER D58
    (-5506059, 'Rob Brooks', 'Rob', 'Brooks', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2452.jpg', 'rep.rob.brooks@legis.wisconsin.gov'),  -- LOWER D59
    (-5506060, 'Jerry O''Connor', 'Jerry', 'O''Connor', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2549.jpg', 'rep.o''connor@legis.wisconsin.gov'),  -- LOWER D60
    (-5506061, 'Bob Donovan', 'Bob', 'Donovan', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2555.jpg', 'rep.donovan@legis.wisconsin.gov'),  -- LOWER D61
    (-5506062, 'Angelina Cruz', 'Angelina', 'Cruz', 'Democratic', 'https://victoryfund.org/wp-content/uploads/2024/06/AC-headshot-scaled-e1719503338133-500x500-250x250.jpeg', 'rep.cruz@legis.wisconsin.gov'),  -- LOWER D62
    (-5506063, 'Bob Wittke', 'Bob', 'Wittke', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2534.jpg', 'rep.wittke@legis.wisconsin.gov'),  -- LOWER D63
    (-5506064, 'Tip McGuire', 'Tip', 'McGuire', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2483.jpg', 'rep.mcguire@legis.wisconsin.gov'),  -- LOWER D64
    (-5506065, 'Ben DeSmidt', 'Ben', 'DeSmidt', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Ben_DeSmidt_20240808_100327.jpeg', 'rep.desmidt@legis.wisconsin.gov'),  -- LOWER D65
    (-5506066, 'Greta Neubauer', 'Greta', 'Neubauer', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2491.jpg', 'rep.neubauer@legis.wisconsin.gov'),  -- LOWER D66
    (-5506067, 'Dave Armstrong', 'Dave', 'Armstrong', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2444.jpg', 'rep.armstrong@legis.wisconsin.gov'),  -- LOWER D67
    (-5506068, 'Rob Summerfield', 'Rob', 'Summerfield', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2522.jpg', 'rep.summerfield@legis.wisconsin.gov'),  -- LOWER D68
    (-5506069, 'Karen Hurd', 'Karen', 'Hurd', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2552.jpg', 'rep.hurd@legis.wisconsin.gov'),  -- LOWER D69
    (-5506070, 'Nancy VanderMeer', 'Nancy', 'VanderMeer', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2529.jpg', 'rep.vandermeer@legis.wisconsin.gov'),  -- LOWER D70
    (-5506071, 'Vinnie Miresse', 'Vinnie', 'Miresse', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Vinnie_Miresse.jpeg', 'rep.miresse@legis.wisconsin.gov'),  -- LOWER D71
    (-5506072, 'Scott Krug', 'Scott', 'Krug', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2478.jpg', 'rep.krug@legis.wisconsin.gov'),  -- LOWER D72
    (-5506073, 'Angela Stroud', 'Angela', 'Stroud', 'Democratic', 'https://www.northland.edu/wp-content/uploads/2015/08/AngelaStroud-800x800.jpg', 'rep.stroud@legis.wisconsin.gov'),  -- LOWER D73
    (-5506074, 'Chanz Green', 'Chanz', 'Green', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2558.jpg', 'rep.green@legis.wisconsin.gov'),  -- LOWER D74
    (-5506075, 'Duke Tucker', 'Duke', 'Tucker', 'Republican', 'https://dukeforwisconsin.com/wp-content/uploads/2024/03/IMG_0256-scaled.jpg', 'rep.tucker@legis.wisconsin.gov'),  -- LOWER D75
    (-5506076, 'Francesca Hong', 'Francesca', 'Hong', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2472.jpg', 'rep.hong@legis.wisconsin.gov'),  -- LOWER D76
    (-5506077, 'Renuka Mayadev', 'Renuka', 'Mayadev', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Renuka_Mayadev_20240808_092901.jpg', 'rep.mayadev@legis.wisconsin.gov'),  -- LOWER D77
    (-5506078, 'Shelia Stubbs', 'Shelia', 'Stubbs', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2520.jpg', 'rep.stubbs@legis.wisconsin.gov'),  -- LOWER D78
    (-5506079, 'Lisa Subeck', 'Lisa', 'Subeck', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2521.jpg', 'rep.subeck@legis.wisconsin.gov'),  -- LOWER D79
    (-5506080, 'Mike Bare', 'Mike', 'Bare', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2554.jpg', 'rep.bare@legis.wisconsin.gov'),  -- LOWER D80
    (-5506081, 'Alex Joers', 'Alex', 'Joers', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2553.jpg', 'rep.joers@legis.wisconsin.gov'),  -- LOWER D81
    (-5506082, 'Scott Allen', 'Scott', 'Allen', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2441.jpg', 'rep.allen@legis.wisconsin.gov'),  -- LOWER D82
    (-5506083, 'Dave Maxey', 'Dave', 'Maxey', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2537.jpg', 'rep.maxey@legis.wisconsin.gov'),  -- LOWER D83
    (-5506084, 'Chuck Wichgers', 'Chuck', 'Wichgers', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2556.jpg', 'rep.wichgers@legis.wisconsin.gov'),  -- LOWER D84
    (-5506085, 'Pat Snyder', 'Pat', 'Snyder', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2515.jpg', 'rep.snyder@legis.wisconsin.gov'),  -- LOWER D85
    (-5506086, 'John Spiros', 'John', 'Spiros', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2517.jpg', 'rep.spiros@legis.wisconsin.gov'),  -- LOWER D86
    (-5506087, 'Brent Jacobson', 'Brent', 'Jacobson', 'Republican', 'https://jacobsonforassembly.com/wp-content/uploads/2024/03/IMG_0484.png', 'rep.brent.jacobson@legis.wisconsin.gov'),  -- LOWER D87
    (-5506088, 'Ben Franklin', 'Ben', 'Franklin', 'Republican', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/BenFranklin2024.png', 'rep.franklin@legis.wisconsin.gov'),  -- LOWER D88
    (-5506089, 'Ryan Spaude', 'Ryan', 'Spaude', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Ryan_Spaude_20240808_093050.jpg', 'rep.spaude@legis.wisconsin.gov'),  -- LOWER D89
    (-5506090, 'Amaad Rivera-Wagner', 'Amaad', 'Rivera-Wagner', 'Democratic', 'https://images.squarespace-cdn.com/content/v1/66195445b4b9aa03925c9d90/46c6514c-c52c-4199-b161-75528cc53721/Amaad+2024-2.jpg', 'rep.riverawagner@legis.wisconsin.gov'),  -- LOWER D90
    (-5506091, 'Jodi Emerson', 'Jodi', 'Emerson', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2465.jpg', 'rep.emerson@legis.wisconsin.gov'),  -- LOWER D91
    (-5506092, 'Clint Moses', 'Clint', 'Moses', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2487.jpg', 'rep.moses@legis.wisconsin.gov'),  -- LOWER D92
    (-5506093, 'Christian Phelps', 'Christian', 'Phelps', 'Democratic', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/ChristianPhelps24.jpg', 'rep.phelps@legis.wisconsin.gov'),  -- LOWER D93
    (-5506094, 'Steve Doyle', 'Steve', 'Doyle', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2461.jpg', 'rep.doyle@legis.wisconsin.gov'),  -- LOWER D94
    (-5506095, 'Jill Billings', 'Jill', 'Billings', 'Democratic', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2448.jpg', 'rep.billings@legis.wisconsin.gov'),  -- LOWER D95
    (-5506096, 'Tara Johnson', 'Tara', 'Johnson', 'Democratic', 'https://wisconsinpublictv.s3.us-east-2.amazonaws.com/wp-content/uploads/2023/09/politics-election-2024-3rddistrict-tarajohnson-announcement.jpg', 'rep.johnson@legis.wisconsin.gov'),  -- LOWER D96
    (-5506097, 'Cindi Duchow', 'Cindi', 'Duchow', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2463.jpg', 'rep.duchow@legis.wisconsin.gov'),  -- LOWER D97
    (-5506098, 'Jim Piwowarczyk', 'Jim', 'Piwowarczyk', 'Republican', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Jim_Piwowarczyk_20240814_075459.jpg', 'rep.piwowarczyk@legis.wisconsin.gov'),  -- LOWER D98
    (-5506099, 'Barbara Dittrich', 'Barbara', 'Dittrich', 'Republican', 'https://docs.legis.wisconsin.gov/2023/legislators/assembly/2460.jpg', 'rep.dittrich@legis.wisconsin.gov')  -- LOWER D99
  ) AS v(external_id, full_name, first_name, last_name, party, photo_origin_url, email)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id
);

-- ── 3. 132 offices, each pinned to (geo_id, district_type, state) ──
-- Looked up by external_id rather than chained off the INSERT above, so a re-run still
-- backfills an office whose politician row already exists.
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', false, false, 1
FROM (VALUES
    (-5505001::bigint, '55001'::text, 'STATE_UPPER'::text, 'State Senator'::text, 'State Senate'),
    (-5505002, '55002', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505003, '55003', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505004, '55004', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505005, '55005', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505006, '55006', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505007, '55007', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505008, '55008', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505009, '55009', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505010, '55010', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505011, '55011', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505012, '55012', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505013, '55013', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505014, '55014', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505015, '55015', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505016, '55016', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505017, '55017', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505018, '55018', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505019, '55019', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505020, '55020', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505021, '55021', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505022, '55022', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505023, '55023', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505024, '55024', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505025, '55025', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505026, '55026', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505027, '55027', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505028, '55028', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505029, '55029', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505030, '55030', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505031, '55031', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505032, '55032', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5505033, '55033', 'STATE_UPPER', 'State Senator', 'State Senate'),
    (-5506001, '55001', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506002, '55002', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506003, '55003', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506004, '55004', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506005, '55005', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506006, '55006', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506007, '55007', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506008, '55008', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506009, '55009', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506010, '55010', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506011, '55011', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506012, '55012', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506013, '55013', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506014, '55014', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506015, '55015', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506016, '55016', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506017, '55017', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506018, '55018', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506019, '55019', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506020, '55020', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506021, '55021', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506022, '55022', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506023, '55023', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506024, '55024', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506025, '55025', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506026, '55026', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506027, '55027', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506028, '55028', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506029, '55029', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506030, '55030', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506031, '55031', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506032, '55032', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506033, '55033', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506034, '55034', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506035, '55035', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506036, '55036', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506037, '55037', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506038, '55038', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506039, '55039', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506040, '55040', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506041, '55041', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506042, '55042', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506043, '55043', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506044, '55044', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506045, '55045', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506046, '55046', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506047, '55047', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506048, '55048', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506049, '55049', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506050, '55050', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506051, '55051', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506052, '55052', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506053, '55053', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506054, '55054', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506055, '55055', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506056, '55056', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506057, '55057', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506058, '55058', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506059, '55059', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506060, '55060', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506061, '55061', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506062, '55062', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506063, '55063', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506064, '55064', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506065, '55065', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506066, '55066', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506067, '55067', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506068, '55068', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506069, '55069', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506070, '55070', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506071, '55071', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506072, '55072', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506073, '55073', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506074, '55074', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506075, '55075', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506076, '55076', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506077, '55077', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506078, '55078', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506079, '55079', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506080, '55080', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506081, '55081', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506082, '55082', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506083, '55083', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506084, '55084', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506085, '55085', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506086, '55086', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506087, '55087', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506088, '55088', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506089, '55089', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506090, '55090', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506091, '55091', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506092, '55092', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506093, '55093', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506094, '55094', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506095, '55095', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506096, '55096', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506097, '55097', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506098, '55098', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly'),
    (-5506099, '55099', 'STATE_LOWER', 'Representative to the Assembly', 'Assembly')
  ) AS v(external_id, geo_id, district_type, title, chamber)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id
 AND d.district_type = v.district_type
 AND d.state = 'wi'
JOIN essentials.chambers c
  ON c.name = v.chamber
 AND c.government_id = (SELECT id FROM essentials.governments WHERE geo_id = '55')
JOIN essentials.politicians p
  ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id
);

-- ── 4. Post-verify gate: any assertion failure rolls back the whole transaction ──
DO $$
DECLARE
  n_sen_d   int; n_asm_d   int;
  n_sen_o   int; n_asm_o   int;
  n_chamber int; n_orphan  int; n_mislink int;
BEGIN
  SELECT count(*) INTO n_sen_d FROM essentials.districts
   WHERE state='wi' AND district_type='STATE_UPPER';
  SELECT count(*) INTO n_asm_d FROM essentials.districts
   WHERE state='wi' AND district_type='STATE_LOWER';
  IF n_sen_d <> 33 OR n_asm_d <> 99 THEN
    RAISE EXCEPTION 'district precondition failed: % STATE_UPPER (want 33), % STATE_LOWER (want 99). Run the WI sldu/sldl TIGER load first.', n_sen_d, n_asm_d;
  END IF;

  SELECT count(*) INTO n_chamber FROM essentials.chambers
   WHERE government_id=(SELECT id FROM essentials.governments WHERE geo_id='55')
     AND name IN ('State Senate','Assembly');
  IF n_chamber <> 2 THEN
    RAISE EXCEPTION 'expected 2 WI legislative chambers, found %', n_chamber;
  END IF;

  SELECT count(*) INTO n_sen_o FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.state='wi' AND d.district_type='STATE_UPPER';
  SELECT count(*) INTO n_asm_o FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.state='wi' AND d.district_type='STATE_LOWER';
  IF n_sen_o <> 33 OR n_asm_o <> 99 THEN
    RAISE EXCEPTION 'office count failed: % Senate (want 33), % Assembly (want 99)', n_sen_o, n_asm_o;
  END IF;

  -- every seeded politician must hold exactly one office
  SELECT count(*) INTO n_orphan FROM essentials.politicians p
   WHERE p.data_source='openstates-v3-wi'
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id);
  IF n_orphan <> 0 THEN
    RAISE EXCEPTION '% seeded WI legislators hold no office', n_orphan;
  END IF;

  -- chamber<->district_type must never cross (the shared-geo_id hazard)
  SELECT count(*) INTO n_mislink FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.chambers c  ON c.id=o.chamber_id
   WHERE d.state='wi'
     AND ((c.name='State Senate' AND d.district_type<>'STATE_UPPER')
       OR (c.name='Assembly'     AND d.district_type<>'STATE_LOWER'));
  IF n_mislink <> 0 THEN
    RAISE EXCEPTION '% WI offices link a chamber to the wrong district tier', n_mislink;
  END IF;

  RAISE NOTICE 'WI legislature verify PASSED: 33 Senate + 99 Assembly offices, 2 chambers, 0 orphans, 0 mislinks.';
END $$;

COMMIT;
