-- Migration 1653: backfill U.S. Senate contact, bioguide and term-end data
--
-- Source: https://www.senate.gov/general/contact_information/senators_cfm.xml
--         (fetched 2026-08-09, HTTP 200, 100 members)
-- The authoritative machine-readable roster for all 100 senators. Supplies
-- website, contact-form URL, party, bioguide_id and Senate class per member.
--
-- Context: migration 1651 populated exactly one senator (Padilla, P000145) while
-- de-conflating him from the Inglewood councilman of the same name. That left him
-- as the only one of 97 seated senators with any contact data. This applies the
-- same source to the rest.
--
-- WHAT THIS DOES NOT WRITE, AND WHY:
--   valid_from is deliberately left alone. The class gives the SEAT's term start,
--   not the PERSON's arrival. For anyone appointed mid-term (Husted OH, Armstrong OK,
--   Moody FL, ...) the seat start is simply false, and `is_appointed` is not a
--   reliable filter -- Moody is an appointee and is NOT flagged. valid_to has no such
--   problem: the seat's term ends on that date whoever holds it, and per the corpus
--   occupancy model it is the term_end gate that matters. So: term end yes, start no.
--   Blank rather than wrong, matching the 1649/1651 precedent on this same record.
--
--   email_addresses is left NULL. Senators publish a contact form, not an address;
--   the XML's <email> element actually contains the form URL, which is why it lands
--   in web_form_url instead.
--
-- BACKFILL-ONLY: every column is guarded on being NULL/empty, so this never
-- overwrites a curated value and is safe to replay. Padilla's already-correct
-- website and term end are preserved untouched; only his blank party_short_name
-- ('' since the cicero load) is filled in.
--
-- valid_to is TEXT and the corpus convention is a BARE DATE ('2029-01-03').
-- Do not cast ::timestamp here -- that silently stores '2029-01-03 00:00:00'.

BEGIN;

WITH senate_xml(last_name, st, party_short, bioguide_id, website, form_url, term_end) AS (
  VALUES
    ('Murkowski', 'AK', 'R', 'M001153', 'https://www.murkowski.senate.gov/', 'https://www.murkowski.senate.gov/public/index.cfm/contact', '2029-01-03'),
    ('Sullivan', 'AK', 'R', 'S001198', 'https://www.sullivan.senate.gov', 'https://www.sullivan.senate.gov/contact/email', '2027-01-03'),
    ('Britt', 'AL', 'R', 'B001319', 'https://www.britt.senate.gov/', 'https://www.britt.senate.gov/contact/', '2029-01-03'),
    ('Tuberville', 'AL', 'R', 'T000278', 'https://www.tuberville.senate.gov', 'https://www.tuberville.senate.gov/contact/contact-form/', '2027-01-03'),
    ('Boozman', 'AR', 'R', 'B001236', 'https://www.boozman.senate.gov/', 'https://www.boozman.senate.gov/public/index.cfm/contact', '2029-01-03'),
    ('Cotton', 'AR', 'R', 'C001095', 'https://www.cotton.senate.gov', 'https://www.cotton.senate.gov/contact/contact-tom', '2027-01-03'),
    ('Gallego', 'AZ', 'D', 'G000574', 'https://www.gallego.senate.gov/', 'https://www.gallego.senate.gov/', '2031-01-03'),
    ('Kelly', 'AZ', 'D', 'K000377', 'https://www.kelly.senate.gov', 'https://www.kelly.senate.gov/contact/contact-form/', '2029-01-03'),
    ('Padilla', 'CA', 'D', 'P000145', 'https://www.padilla.senate.gov', 'https://www.padilla.senate.gov/contact/', '2029-01-03'),
    ('Schiff', 'CA', 'D', 'S001150', 'https://www.schiff.senate.gov', 'https://www.schiff.senate.gov', '2031-01-03'),
    ('Bennet', 'CO', 'D', 'B001267', 'https://www.bennet.senate.gov', 'https://www.bennet.senate.gov/public/index.cfm/contact', '2029-01-03'),
    ('Hickenlooper', 'CO', 'D', 'H000273', 'https://www.hickenlooper.senate.gov', 'https://www.hickenlooper.senate.gov/contact/', '2027-01-03'),
    ('Blumenthal', 'CT', 'D', 'B001277', 'https://www.blumenthal.senate.gov', 'https://www.blumenthal.senate.gov/contact/', '2029-01-03'),
    ('Murphy', 'CT', 'D', 'M001169', 'https://www.murphy.senate.gov/', 'https://www.murphy.senate.gov/contact', '2031-01-03'),
    ('Blunt Rochester', 'DE', 'D', 'B001303', 'https://www.bluntrochester.senate.gov/', 'https://www.bluntrochester.senate.gov/', '2031-01-03'),
    ('Coons', 'DE', 'D', 'C001088', 'https://www.coons.senate.gov/', 'https://www.coons.senate.gov/contact', '2027-01-03'),
    ('Moody', 'FL', 'R', 'M001244', 'https://www.moody.senate.gov', 'https://www.moody.senate.gov', '2029-01-03'),
    ('Scott', 'FL', 'R', 'S001217', 'https://www.rickscott.senate.gov/', 'https://www.rickscott.senate.gov/contact/contact', '2031-01-03'),
    ('Ossoff', 'GA', 'D', 'O000174', 'https://www.ossoff.senate.gov', 'https://www.ossoff.senate.gov/contact-us/', '2027-01-03'),
    ('Warnock', 'GA', 'D', 'W000790', 'https://www.warnock.senate.gov', 'https://www.warnock.senate.gov/contact/', '2029-01-03'),
    ('Hirono', 'HI', 'D', 'H001042', 'https://www.hirono.senate.gov/', 'https://www.hirono.senate.gov/contact', '2031-01-03'),
    ('Schatz', 'HI', 'D', 'S001194', 'https://www.schatz.senate.gov', 'https://www.schatz.senate.gov/contact', '2029-01-03'),
    ('Ernst', 'IA', 'R', 'E000295', 'https://www.ernst.senate.gov', 'https://www.ernst.senate.gov/public/index.cfm/contact', '2027-01-03'),
    ('Grassley', 'IA', 'R', 'G000386', 'https://www.grassley.senate.gov', 'https://www.grassley.senate.gov/contact', '2029-01-03'),
    ('Crapo', 'ID', 'R', 'C000880', 'https://www.crapo.senate.gov', 'https://www.crapo.senate.gov/contact', '2029-01-03'),
    ('Risch', 'ID', 'R', 'R000584', 'https://www.risch.senate.gov', 'https://www.risch.senate.gov/public/index.cfm?p=Email', '2027-01-03'),
    ('Duckworth', 'IL', 'D', 'D000622', 'https://www.duckworth.senate.gov', 'https://www.duckworth.senate.gov/content/contact-senator', '2029-01-03'),
    ('Durbin', 'IL', 'D', 'D000563', 'https://www.durbin.senate.gov', 'https://www.durbin.senate.gov/contact/', '2027-01-03'),
    ('Banks', 'IN', 'R', 'B001299', 'https://www.banks.senate.gov/', 'https://www.banks.senate.gov/', '2031-01-03'),
    ('Young', 'IN', 'R', 'Y000064', 'https://www.young.senate.gov', 'https://www.young.senate.gov/contact', '2029-01-03'),
    ('Marshall', 'KS', 'R', 'M001198', 'https://www.marshall.senate.gov', 'https://www.marshall.senate.gov/contact/', '2027-01-03'),
    ('Moran', 'KS', 'R', 'M000934', 'https://www.moran.senate.gov', 'https://www.moran.senate.gov/public/index.cfm/e-mail-jerry', '2029-01-03'),
    ('McConnell', 'KY', 'R', 'M000355', 'https://www.mcconnell.senate.gov/', 'https://www.mcconnell.senate.gov/public/index.cfm?p=contact', '2027-01-03'),
    ('Paul', 'KY', 'R', 'P000603', 'https://www.paul.senate.gov', 'https://www.paul.senate.gov/connect/email-rand', '2029-01-03'),
    ('Cassidy', 'LA', 'R', 'C001075', 'https://www.cassidy.senate.gov', 'https://www.cassidy.senate.gov/contact', '2027-01-03'),
    ('Kennedy', 'LA', 'R', 'K000393', 'https://www.kennedy.senate.gov', 'https://www.kennedy.senate.gov/public/email-me', '2029-01-03'),
    ('Markey', 'MA', 'D', 'M000133', 'https://www.markey.senate.gov', 'https://www.markey.senate.gov/contact', '2027-01-03'),
    ('Warren', 'MA', 'D', 'W000817', 'https://www.warren.senate.gov', 'https://www.warren.senate.gov/?p=email_senator', '2031-01-03'),
    ('Alsobrooks', 'MD', 'D', 'A000382', 'https://alsobrooks.senate.gov/', 'https://alsobrooks.senate.gov/', '2031-01-03'),
    ('Van Hollen', 'MD', 'D', 'V000128', 'https://www.vanhollen.senate.gov', 'https://www.vanhollen.senate.gov/contact/email', '2029-01-03'),
    ('Collins', 'ME', 'R', 'C001035', 'https://www.collins.senate.gov', 'https://www.collins.senate.gov/contact', '2027-01-03'),
    ('King', 'ME', 'I', 'K000383', 'https://www.king.senate.gov/', 'https://www.king.senate.gov/contact', '2031-01-03'),
    ('Peters', 'MI', 'D', 'P000595', 'https://www.peters.senate.gov', 'https://www.peters.senate.gov/contact/email-gary', '2027-01-03'),
    ('Slotkin', 'MI', 'D', 'S001208', 'https://www.slotkin.senate.gov/', 'https://www.slotkin.senate.gov/', '2031-01-03'),
    ('Klobuchar', 'MN', 'D', 'K000367', 'https://www.klobuchar.senate.gov/', 'https://www.klobuchar.senate.gov/public/index.cfm/contact', '2031-01-03'),
    ('Smith', 'MN', 'D', 'S001203', 'https://www.smith.senate.gov', 'https://www.smith.senate.gov/share-your-opinion/', '2027-01-03'),
    ('Hawley', 'MO', 'R', 'H001089', 'https://www.hawley.senate.gov', 'https://www.hawley.senate.gov/contact-senator-hawley', '2031-01-03'),
    ('Schmitt', 'MO', 'R', 'S001227', 'https://www.schmitt.senate.gov/', 'https://www.schmitt.senate.gov/contact/', '2029-01-03'),
    ('Hyde-Smith', 'MS', 'R', 'H001079', 'https://www.hydesmith.senate.gov/', 'https://www.hydesmith.senate.gov/contact-senator', '2027-01-03'),
    ('Wicker', 'MS', 'R', 'W000437', 'https://www.wicker.senate.gov', 'https://www.wicker.senate.gov/public/index.cfm/contact', '2031-01-03'),
    ('Daines', 'MT', 'R', 'D000618', 'https://www.daines.senate.gov', 'https://www.daines.senate.gov/connect/email-steve', '2027-01-03'),
    ('Sheehy', 'MT', 'R', 'S001232', 'https://www.sheehy.senate.gov/', 'https://www.sheehy.senate.gov/', '2031-01-03'),
    ('Budd', 'NC', 'R', 'B001305', 'https://www.budd.senate.gov/', 'https://www.budd.senate.gov/contact/', '2029-01-03'),
    ('Tillis', 'NC', 'R', 'T000476', 'https://www.tillis.senate.gov', 'https://www.tillis.senate.gov/public/index.cfm/email-me', '2027-01-03'),
    ('Cramer', 'ND', 'R', 'C001096', 'https://www.cramer.senate.gov', 'https://www.cramer.senate.gov/contact/contact-kevin', '2031-01-03'),
    ('Hoeven', 'ND', 'R', 'H001061', 'https://www.hoeven.senate.gov', 'https://www.hoeven.senate.gov/contact/contact-the-senator', '2029-01-03'),
    ('Fischer', 'NE', 'R', 'F000463', 'https://www.fischer.senate.gov', 'https://www.fischer.senate.gov/public/index.cfm/contact', '2031-01-03'),
    ('Ricketts', 'NE', 'R', 'R000618', 'https://www.ricketts.senate.gov', 'https://www.ricketts.senate.gov/contact/', '2027-01-03'),
    ('Hassan', 'NH', 'D', 'H001076', 'https://www.hassan.senate.gov', 'https://www.hassan.senate.gov/content/contact-senator', '2029-01-03'),
    ('Shaheen', 'NH', 'D', 'S001181', 'https://www.shaheen.senate.gov', 'https://www.shaheen.senate.gov/contact/contact-jeanne', '2027-01-03'),
    ('Booker', 'NJ', 'D', 'B001288', 'https://www.booker.senate.gov', 'https://www.booker.senate.gov/?p=contact', '2027-01-03'),
    ('Kim', 'NJ', 'D', 'K000394', 'https://www.kim.senate.gov/', 'https://www.kim.senate.gov/', '2031-01-03'),
    ('Heinrich', 'NM', 'D', 'H001046', 'https://www.heinrich.senate.gov/', 'https://www.heinrich.senate.gov/contact', '2031-01-03'),
    ('Luján', 'NM', 'D', 'L000570', 'https://www.lujan.senate.gov', 'https://www.lujan.senate.gov/contact/', '2027-01-03'),
    ('Cortez Masto', 'NV', 'D', 'C001113', 'https://www.cortezmasto.senate.gov', 'https://www.cortezmasto.senate.gov/contact', '2029-01-03'),
    ('Rosen', 'NV', 'D', 'R000608', 'https://www.rosen.senate.gov', 'https://www.rosen.senate.gov/contact_jacky', '2031-01-03'),
    ('Gillibrand', 'NY', 'D', 'G000555', 'https://www.gillibrand.senate.gov', 'https://www.gillibrand.senate.gov/contact/email-me', '2031-01-03'),
    ('Schumer', 'NY', 'D', 'S000148', 'https://www.schumer.senate.gov/', 'https://www.schumer.senate.gov/contact/email-chuck', '2029-01-03'),
    ('Husted', 'OH', 'R', 'H001104', 'https://www.husted.senate.gov/', 'https://www.husted.senate.gov', '2029-01-03'),
    ('Moreno', 'OH', 'R', 'M001242', 'https://www.moreno.senate.gov', 'https://www.moreno.senate.gov', '2031-01-03'),
    ('Armstrong', 'OK', 'R', 'A000383', 'https://www.armstrong.senate.gov/', 'https://www.armstrong.senate.gov/', '2027-01-03'),
    ('Lankford', 'OK', 'R', 'L000575', 'https://www.lankford.senate.gov', 'https://www.lankford.senate.gov/contact/email', '2029-01-03'),
    ('Merkley', 'OR', 'D', 'M001176', 'https://www.merkley.senate.gov', 'https://www.merkley.senate.gov/contact/', '2027-01-03'),
    ('Wyden', 'OR', 'D', 'W000779', 'https://www.wyden.senate.gov/', 'https://www.wyden.senate.gov/contact/', '2029-01-03'),
    ('Fetterman', 'PA', 'D', 'F000479', 'https://www.fetterman.senate.gov/', 'https://www.fetterman.senate.gov/contact/', '2029-01-03'),
    ('McCormick', 'PA', 'R', 'M001243', 'https://mccormick.senate.gov/', 'https://mccormick.senate.gov/', '2031-01-03'),
    ('Reed', 'RI', 'D', 'R000122', 'https://www.reed.senate.gov/', 'https://www.reed.senate.gov/contact/', '2027-01-03'),
    ('Whitehouse', 'RI', 'D', 'W000802', 'https://www.whitehouse.senate.gov/', 'https://www.whitehouse.senate.gov/contact/email-sheldon', '2031-01-03'),
    ('Graham', 'SC', 'R', 'G000608', 'https://www.dgraham.senate.gov/', 'https://www.dgraham.senate.gov/', '2027-01-03'),
    ('Scott', 'SC', 'R', 'S001184', 'https://www.scott.senate.gov/', 'https://www.scott.senate.gov/contact/email-me', '2029-01-03'),
    ('Rounds', 'SD', 'R', 'R000605', 'https://www.rounds.senate.gov', 'https://www.rounds.senate.gov/contact/email-mike', '2027-01-03'),
    ('Thune', 'SD', 'R', 'T000250', 'https://www.thune.senate.gov/', 'https://www.thune.senate.gov/public/index.cfm/contact', '2029-01-03'),
    ('Blackburn', 'TN', 'R', 'B001243', 'https://www.blackburn.senate.gov', 'https://www.blackburn.senate.gov/email-me', '2031-01-03'),
    ('Hagerty', 'TN', 'R', 'H000601', 'https://www.hagerty.senate.gov', 'https://www.hagerty.senate.gov/email-me/', '2027-01-03'),
    ('Cornyn', 'TX', 'R', 'C001056', 'https://www.cornyn.senate.gov/', 'https://www.cornyn.senate.gov/contact', '2027-01-03'),
    ('Cruz', 'TX', 'R', 'C001098', 'https://www.cruz.senate.gov', 'https://www.cruz.senate.gov/?p=form&id=16', '2031-01-03'),
    ('Curtis', 'UT', 'R', 'C001114', 'https://www.curtis.senate.gov/', 'https://www.curtis.senate.gov/', '2031-01-03'),
    ('Lee', 'UT', 'R', 'L000577', 'https://www.lee.senate.gov/', 'https://www.lee.senate.gov/public/index.cfm/contact', '2029-01-03'),
    ('Kaine', 'VA', 'D', 'K000384', 'https://www.kaine.senate.gov/', 'https://www.kaine.senate.gov/contact', '2031-01-03'),
    ('Warner', 'VA', 'D', 'W000805', 'https://www.warner.senate.gov', 'https://www.warner.senate.gov/public/index.cfm?p=Contact', '2027-01-03'),
    ('Sanders', 'VT', 'I', 'S000033', 'https://www.sanders.senate.gov/', 'https://www.sanders.senate.gov/contact/', '2031-01-03'),
    ('Welch', 'VT', 'D', 'W000800', 'https://www.welch.senate.gov/', 'https://www.welch.senate.gov/email-peter/', '2029-01-03'),
    ('Cantwell', 'WA', 'D', 'C000127', 'https://www.cantwell.senate.gov', 'https://www.cantwell.senate.gov/public/index.cfm/email-maria', '2031-01-03'),
    ('Murray', 'WA', 'D', 'M001111', 'https://www.murray.senate.gov/', 'https://www.murray.senate.gov/write-to-patty/', '2029-01-03'),
    ('Baldwin', 'WI', 'D', 'B001230', 'https://www.baldwin.senate.gov/', 'https://www.baldwin.senate.gov/feedback', '2031-01-03'),
    ('Johnson', 'WI', 'R', 'J000293', 'https://www.ronjohnson.senate.gov/', 'https://www.ronjohnson.senate.gov/public/index.cfm/email-the-senator', '2029-01-03'),
    ('Capito', 'WV', 'R', 'C001047', 'https://www.capito.senate.gov', 'https://www.capito.senate.gov/contact/contact-shelley', '2027-01-03'),
    ('Justice', 'WV', 'R', 'J000312', 'https://www.justice.senate.gov/', 'https://www.justice.senate.gov/', '2031-01-03'),
    ('Barrasso', 'WY', 'R', 'B001261', 'https://www.barrasso.senate.gov', 'https://www.barrasso.senate.gov/public/index.cfm/contact-form', '2031-01-03'),
    ('Lummis', 'WY', 'R', 'L000571', 'https://www.lummis.senate.gov', 'https://www.lummis.senate.gov/contact/contact-form/', '2027-01-03')
),
alias(db_last_name, xml_last_name) AS (
  VALUES
    ('Moore Capito', 'Capito')
),
matched AS (
  SELECT p.id,
         x.party_short, x.bioguide_id, x.website, x.form_url, x.term_end
  FROM essentials.politicians p
  JOIN essentials.offices o
    ON o.id = p.office_id
  LEFT JOIN alias a
    ON a.db_last_name = p.last_name
  JOIN senate_xml x
    ON x.st = o.representing_state
   AND x.last_name = COALESCE(a.xml_last_name, p.last_name)
  WHERE o.chamber_id = '7cbe07bc-84b8-433b-952b-540e7de18a92'
    AND p.is_incumbent
)
UPDATE essentials.politicians p
SET bioguide_id      = CASE WHEN COALESCE(p.bioguide_id, '') = ''      THEN m.bioguide_id      ELSE p.bioguide_id END,
    web_form_url     = CASE WHEN COALESCE(p.web_form_url, '') = ''     THEN m.form_url         ELSE p.web_form_url END,
    party_short_name = CASE WHEN COALESCE(p.party_short_name, '') = '' THEN m.party_short      ELSE p.party_short_name END,
    valid_to         = CASE WHEN COALESCE(p.valid_to, '') = ''         THEN m.term_end         ELSE p.valid_to END,
    urls             = CASE WHEN p.urls IS NULL                        THEN ARRAY[m.website]   ELSE p.urls END
FROM matched m
WHERE p.id = m.id;

COMMIT;
