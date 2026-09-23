-- CA_0156_la_unified_unsourced_holder_audit.sql
-- Audit and clean up the 238 politician rows that the unsourced "school-district" seeding pass put on
-- LA County unified school boards (data_source 'https://empowered.vote/school-district/<name>_unified',
-- LAUSD excluded). CA_0143-CA_0154 (2026-09-22, two sessions) closed their stale terms; this file
-- decides, row by row, what those people ARE.
--
-- No migration runner exists; this file records SQL applied by hand over a `postgres` connection
-- (psql with DATABASE_URL) because it creates one archive table (DDL). Operator approval: Chris
-- Andrews, 2026-09-22 ("Approve", including the recommendation to delete the C2 terms).
--
-- ---------------------------------------------------------------------------------------------------
-- A. PROVENANCE -- why these rows are suspect
-- ---------------------------------------------------------------------------------------------------
-- All 238 carry source 'scraped', last_synced 2026-02-24, external_id in -201833..-202376 (minted in
-- the same pass as the CA-roster import), a placeholder data_source, no urls/emails, party
-- 'Nonpartisan'. No generator exists in any repo. The pass evidently produced plausible names: some are
-- real former trustees, some are real people from OTHER offices (two are Inland Empire officials), most
-- have no trace at all. Same defect class as migration 1566 (Waltham's fabricated mayor).
--
-- ---------------------------------------------------------------------------------------------------
-- B. EVIDENCE GATHERED 2026-09-22 (full per-row table: la_unified_audit_classification.csv, PR body)
-- ---------------------------------------------------------------------------------------------------
--   * LA County RR/CC candidate lists Nov 2017 - Nov 2026 (lavote.gov/Apps/CandidateList, 21 elections)
--     and RR/CC results 2013 - 2026 (results.lavote.gov /ElectionResults/GetElectionData, 73 elections,
--     incl. 967 = Nov 3 2015 with winner flags), all names matched per district.
--   * Per-district rosters: district board pages and their Wayback snapshots, BoardDocs minutes, Smart
--     Voter archives, Ballotpedia, local news. Two districts publish EVERY trustee ever:
--     Glendale (gusd.net/8457_3, 1936-2026) and South Pasadena (spusd.net Past Board Members, 1923-).
--   * inform.politician_answers / politician_context / politician_context_evidence / evidence_items:
--     ZERO rows for all 238 -- deactivating anyone orphans no stance data (asserted below).
--   Limit: the session's web-search quota ran out mid-audit, so most no-evidence names got one search
--   plus a roster check rather than two searches. 79 of the 178 no-evidence names are absent from a
--   roster that is complete for the period covering their recorded term end.
--
-- ---------------------------------------------------------------------------------------------------
-- C. CLASSES AND WHAT HAPPENS TO EACH (every class: party and party_short_name -> NULL; antipartisan)
-- ---------------------------------------------------------------------------------------------------
--   A1  16  REAL, CURRENT  -- still seated, verified on the board page by CA_0143-0154. Party only.
--   A2  27  REAL, FORMER   -- RR/CC incumbent flag / 2015 win, or a quoted district page, minutes or
--           news item. Closed term KEPT, row stays active, is_incumbent false, evidence appended to the
--           term source. Dates NOT changed: office_terms has no end-precision column, and the generic
--           seats were paired with successors arbitrarily, so a sourced year would become an invented day
--           on possibly the wrong seat. (Robin Funk, El Segundo 2005-2013, is REAL -- CA_0143's comment
--           that a search found no board service for her is wrong.)
--   B  178  NO EVIDENCE    -- deactivated (is_active false, is_incumbent false). Closed term KEPT
--           (absence is not disproof -- 1588/1590) but tagged '| unverified CA_0156' in its source.
--           Includes six name-only matches to other offices (Moran, Zuniga, Montez, Trujillo,
--           Lichtblau, Carey) and one other-role match (Thompson, Compton Personnel Commission).
--   C   15  DISPROVED      -- term row archived to essentials._fabricated_ca0156_removed and DELETED,
--           row deactivated and retained (1566). Same standard CA_0143/0146/0149 used for Redinger,
--           Malauulu and Hardie: the person is documented in a DIFFERENT office.
--           C1 (8): Sho Tay (Arcadia City Council), Joseph Rocha (Azusa City Council / Mayor), Carl Coles
--           (Bonita superintendent 2018-2020 -- Ed Code 35107 bar -- and absent from a complete Bonita
--           roster 2003-2026), Judy Chen Haggerty (Mt. SAC trustee since 2001), Adrienne Konigar-Macklin
--           (Pomona USD trustee; at Inglewood only as general counsel 2003-2008), Herlinda Chico (Long
--           Beach CCD trustee, not LBUSD), Tim Goodrich (Torrance City Council), Darcy McNaboe (Mayor of
--           Grand Terrace).
--           C2 (7): absent from the district's OWN list of every trustee it has ever had -- Glendale:
--           Gary Springer, Kathia Dipp Metzler; South Pasadena: Don Galvan, Jennifer Kassan, Rosemary
--           Cortez, Rosemary Lim Youngblood, Ying Chen. Operator ruling: an exhaustive official roster is
--           the complete-field test 1590 accepted.
--   C0H  1  Gary Hardie   -- duplicate of 'Gary Hardie Jr.' (b5eb36c0), who holds the Lynwood seat; his
--           wrong Covina-Valley term was deleted by CA_0149. Deactivated.
--   C0M  1  Vivian Malauulu -- a Long Beach CCD trustee; her ABC term was deleted by CA_0146. She holds
--           no seat in this DB, so is_incumbent -> false; kept ACTIVE (2026 LB Council D7 race row).
--   Also fixed: five rows held no term at all yet still read is_incumbent = true (Jorge Blanco, Vanessa
--   Ramirez, Chuck Kauffman, David Buerge, Joseph Chang) -- the flat-list gate reads that flag directly.
--
-- ---------------------------------------------------------------------------------------------------
-- D. ROLLBACK
-- ---------------------------------------------------------------------------------------------------
--   * Deleted terms: INSERT INTO essentials.office_terms SELECT id, office_id, politician_id, term_start,
--     term_end, start_precision, how_started, how_ended, source, created_at
--     FROM essentials._fabricated_ca0156_removed;
--   * Tags: strip the ' | verified CA_0156 ...' / ' | unverified CA_0156 ...' suffix from source, and
--     drop the notes element starting 'CA_0156'.
--   * Flags: set is_active/is_incumbent back per the class list below (A1 incumbents stay true). Party
--     was 'Nonpartisan' / party_short_name 'N' on 222 / 228 rows; restoring it is not recommended.
--
-- IDEMPOTENT: every UPDATE is guarded on the value it changes; the archive insert and the delete are
-- keyed on the term id; a re-run is a no-op and the post-verify gate still passes.
-- ===================================================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS essentials._fabricated_ca0156_removed AS
  SELECT ot.*, NULL::text AS reason, now() AS removed_at
    FROM essentials.office_terms ot WHERE false;

CREATE TEMP TABLE _a (politician_id uuid PRIMARY KEY, full_name text, cls text, district text, evidence text) ON COMMIT DROP;
INSERT INTO _a VALUES
  ('f2a863a9-ce21-453a-9d2b-fc7282307eb0'::uuid, 'Robert Gin', 'A1', 'Alhambra Unified', ''),
  ('a1e9b61d-96e0-47be-ae4f-dab05158e56b'::uuid, 'Rachelle Marcus', 'A1', 'Beverly Hills Unified', ''),
  ('b7dc60f1-7d9f-4ac8-abb1-a977ffd25d26'::uuid, 'Armond Aghakhanian', 'A1', 'Burbank Unified', ''),
  ('123e8e2b-4c4c-471f-80a4-216a1a73c50c'::uuid, 'Alma Taylor-Pleasant', 'A1', 'Compton Unified', ''),
  ('24076e95-943f-4f94-afe3-05552575659c'::uuid, 'Michael Hooper', 'A1', 'Compton Unified', ''),
  ('dafc1db2-758f-498f-93f8-4f632b0adc7a'::uuid, 'Linda Menges', 'A1', 'Las Virgenes Unified', ''),
  ('028e1a70-5ac2-42ec-bc2e-eafc9dcc630e'::uuid, 'Diana Craighead', 'A1', 'Long Beach Unified', ''),
  ('22969acc-f5d2-48de-8715-4eb67601cdba'::uuid, 'Erik Miller', 'A1', 'Long Beach Unified', ''),
  ('2f601ba5-a8be-4947-961e-cbbb50b61f28'::uuid, 'Juan Benitez', 'A1', 'Long Beach Unified', ''),
  ('4ef6ef6a-7a0c-4f66-bc9e-3e923ce4965d'::uuid, 'Jen Fenton', 'A1', 'Manhattan Beach Unified', ''),
  ('820d81c8-4f1a-4a05-a739-98e1c1e35c56'::uuid, 'Kim Kenne', 'A1', 'Pasadena Unified', ''),
  ('5cbf44d9-91de-4fc9-b5f0-76e2ae236914'::uuid, 'Michelle Bailey', 'A1', 'Pasadena Unified', ''),
  ('b1f63336-4614-4c12-9b03-6ad3c30604df'::uuid, 'Yarma Velázquez Vargas', 'A1', 'Pasadena Unified', ''),
  ('063fd6f1-42f0-47dc-aa7d-7feac385c495'::uuid, 'Jon Kean', 'A1', 'Santa Monica-Malibu Unified', ''),
  ('0952f897-7414-4ad3-af88-022de9e4971c'::uuid, 'Laurie Lieberman', 'A1', 'Santa Monica-Malibu Unified', ''),
  ('dc78ce32-d1d6-40f6-a200-dd8fb5a13f7d'::uuid, 'Maria Leon-Vazquez', 'A1', 'Santa Monica-Malibu Unified', ''),
  ('90b0b8a1-c700-4786-84d6-33ddb55f5b6f'::uuid, 'Ken Tang', 'A2', 'Alhambra Unified', 'RR/CC Nov 2024 candidate list: KENNETH TRUNG TANG, incumbent (Alhambra TA); resigned 2025-08-06 per CA_0151'),
  ('b545317b-d799-4ca0-ae8d-f9a93c35729f'::uuid, 'Rosemary Garcia', 'A2', 'Azusa Unified', 'http://web.archive.org/web/20010405130848/http://www.azusausd.k12.ca.us:80/districtinfo/districtinfo.html — "Board of Education Rosemary Garcia, Vice President Lisa Harrington, Clerk Jose L. Torres, Member Ilean M. Ochoa, Member" (service by 2001-2013)'),
  ('09cd1f70-2a45-4393-ac52-33f55091ffd4'::uuid, 'Cristina Lucero', 'A2', 'Baldwin Park Unified', 'RR/CC: CHRISTINA LUCERO won Nov 2015 (results.lavote.gov election 967); incumbent on Nov 2020 and Nov 2024 lists'),
  ('84a73092-e2e4-4030-8b05-2113ec404df1'::uuid, 'Alissa Roston', 'A2', 'Beverly Hills Unified', 'https://beverlypress.com/2024/01/candidates-for-beverly-hills-council-continue-campaigns/ — "She served on the Beverly Hills Unified School District Board of Education for two terms from 1999-2007" (service 1999-2007)'),
  ('35d08038-550b-4f13-b564-dcfe48b3dfa6'::uuid, 'Brian Goldberg', 'A2', 'Beverly Hills Unified', 'http://web.archive.org/web/20100917233930/http://bhusd.org/apps/pages/index.jsp?userGroupREC_ID=31884&uREC_ID=31884&type=d&title=Board+of+Education&un=SEC-BOE — "Steven Fenton Board President Lisa Korbatov Vice President Brian David Goldberg, Ph.D Member Myra Lurie Member" (service at least 2009-2015)'),
  ('8bc76d78-5793-4ab8-ba47-ddeefeb33413'::uuid, 'Noah Margo', 'A2', 'Beverly Hills Unified', 'RR/CC: NOAH MARGO won Nov 2015 (election 967); incumbent on Nov 2020 list'),
  ('8d34fe9c-7363-4ec3-9587-be656b7ad8a1'::uuid, 'Roberta Reynolds', 'A2', 'Burbank Unified', 'RR/CC Nov 2020 candidate list: ROBERTA GRANDE REYNOLDS, incumbent'),
  ('31996159-ce51-4ac7-971f-bcd78a467499'::uuid, 'Steve Ferguson', 'A2', 'Burbank Unified', 'RR/CC Nov 2020 candidate list: STEVE FERGUSON, incumbent'),
  ('19db4957-f8af-4e9f-b3d4-b9374e4fd37a'::uuid, 'Hilary LaConte', 'A2', 'Claremont Unified', 'https://web.archive.org/web/20091108050449/http://www.cusd.claremont.edu:80/boe/index.php — "Hilary LaConte Vice President Board Service Began 12/2007 Term Expires 12/2011" (service Dec 2007-Dec 2020 (elected); appointed again Jan/Feb 2023-Jul 2023 (Trustee Area 4))'),
  ('7a52ea32-cd3d-4853-ba1e-7c51087d998f'::uuid, 'Steven Llanusa', 'A2', 'Claremont Unified', 'RR/CC: STEVEN M. LLANUSA incumbent on Nov 2018 and Nov 2022 lists'),
  ('5501c147-5dad-48d5-845c-b6b91e8860a9'::uuid, 'Kathy Paspalis', 'A2', 'Culver City Unified', 'https://culvercitycrossroads.com/2018/11/30/paspalis-gets-a-warm-farewell-from-the-school-board-and-the-district/ — "After serving on the Culver City Unified School Board for nine years, Kathy Paspalis attended her final meeting on Tuesday, November 27, 2018." (service 2009-2018)'),
  ('599376b6-bdfa-4b76-837f-dd2230a546ad'::uuid, 'Scott Zeidman', 'A2', 'Culver City Unified', 'http://web.archive.org/web/20080421175606/http://www.ccusd.org:80/apps/pages/index.jsp?uREC_ID=42334&type=d — "Member: Scott Zeidman Term of Office: 12/1/07 - 11/30/11" (service 2007-2011)'),
  ('b0ad0f94-2ec8-499c-be99-c39082da8f4c'::uuid, 'Donald LaPlante', 'A2', 'Downey Unified', 'RR/CC: DONALD E. LA PLANTE won Downey TA4, Nov 2015 (election 967)'),
  ('4a484a17-5426-403c-8c51-0b7e387a07b1'::uuid, 'Robin Funk', 'A2', 'El Segundo Unified', 'https://web.archive.org/web/20080110050328/http://www.elsegundousd.com:80/board.html — "Robin Funk was elected to the Board of Education in November 2005" (service 2005-2013)'),
  ('c096896b-72e7-49e3-87ea-ddc90888b996'::uuid, 'Jennifer Freemon', 'A2', 'Glendale Unified', 'https://www.gusd.net/8457_3 — "Jennifer Freemon 2015 - 2024" (service 2015-2024)'),
  ('9b362b24-72a3-4c81-8e38-7bd476eba72e'::uuid, 'Nayiri Nahabedian', 'A2', 'Glendale Unified', 'https://www.gusd.net/8457_3 — "Nayiri Nahabedian 2007 - 2024" (service 2007-2024)'),
  ('0e59e9c1-a019-4b2a-aa02-b97f17a6d761'::uuid, 'Shant Sahakian', 'A2', 'Glendale Unified', 'https://www.gusd.net/8457_3 — "Shant Sahakian 2017 - 2026" (service 2017-2026)'),
  ('c5f6d8ec-f6c2-4560-ab67-4c4cf3cbba5b'::uuid, 'Joseph Chang', 'A2', 'Hacienda La Puente Unified', 'RR/CC Nov 2018 candidate list: JOSEPH K. CHANG, incumbent (Hacienda La Puente)'),
  ('695ab650-58df-43b8-b8c9-b075e1e519fd'::uuid, 'Kate Vadehra', 'A2', 'Las Virgenes Unified', 'https://www.theacorn.com/articles/community-mourns-death-of-school-boards-vadehra/ — "Pediatrician Kate Vadehra, who won her LVUSD board election in 2020, died Nov. 26" (service 2020-2022)'),
  ('df7e4a1a-14d1-4044-9f81-2936486b3d4a'::uuid, 'Jennifer Cochran', 'A2', 'Manhattan Beach Unified', 'RR/CC Nov 2018 candidate list: JENNIFER COCHRAN, incumbent'),
  ('cca09d1e-6e2b-427c-add8-5eeea52a9633'::uuid, 'Ed Gililland', 'A2', 'Monrovia Unified', 'RR/CC Nov 2020 candidate list: ED GILILLAND, incumbent'),
  ('68eea13f-e95d-468b-bc43-aa83c19a37da'::uuid, 'Lawrence Torres', 'A2', 'Pasadena Unified', 'https://ballotpedia.org/Pasadena_Unified_School_District,_California,_elections — "Lawrence Torres won election in the general election for Pasadena Unified School District school board District 6 on March 10, 2015." (service 2015-2020)'),
  ('7dae12c6-d2b7-45a4-af3f-0003e13fbacf'::uuid, 'Pat Cahalan', 'A2', 'Pasadena Unified', 'https://ballotpedia.org/Pasadena_Unified_School_District,_California,_elections — "Incumbent Patrick Cahalan won election in the general election for Pasadena Unified School District school board District 4 on March 10, 2015." (service 2015-2024)'),
  ('592a2ac4-686f-47d5-8668-269e21ad1924'::uuid, 'Craig Foster', 'A2', 'Santa Monica-Malibu Unified', 'https://web.archive.org/web/20150223020419/http://www.smartvoter.org:80/2014/11/04/ca/la/school.html — "Craig Foster .......... 12,126 votes 16.50%" (service 2014-2022)'),
  ('98043faa-6ece-4c24-888f-5d556c04ef98'::uuid, 'Kenneth Knollenberg', 'A2', 'Temple City Unified', 'RR/CC: KENNETH E. KNOLLENBERG won Nov 2015 (election 967); incumbent on Nov 2020 list'),
  ('22dfaff5-6d3d-4bba-abc3-6c7500e42ded'::uuid, 'Don Lee', 'A2', 'Torrance Unified', 'RR/CC: DON LEE won Torrance, Nov 2015 (election 967)'),
  ('9e7f9ff8-24d7-4ab3-b09b-c9adf823a602'::uuid, 'Terry Ragins', 'A2', 'Torrance Unified', 'RR/CC: TERRY L. RAGINS won Torrance, Nov 2015 (election 967)'),
  ('e1b7f87e-cde7-408b-860a-f2e034a5dfe0'::uuid, 'Arturo Montez', 'B', 'ABC Unified', ''),
  ('401d37f3-24d8-4b95-8be5-46dab72bc477'::uuid, 'Mike Seck', 'B', 'ABC Unified', ''),
  ('d142c4c9-ad9c-4003-ac48-27e035ff8f62'::uuid, 'Olimpia Miranda', 'B', 'ABC Unified', ''),
  ('bdfbb3bc-d63c-4188-9ba2-528fa9bcf6ec'::uuid, 'Paula Lantz', 'B', 'ABC Unified', ''),
  ('c3b1093f-891b-4fd2-bc47-521af38f693d'::uuid, 'Ramona Anand', 'B', 'ABC Unified', ''),
  ('220bbe64-4cd0-4949-b7a4-7453e316b1f0'::uuid, 'Sommer Foster', 'B', 'ABC Unified', ''),
  ('8a50278f-7d9b-4beb-93c5-d47ea5241468'::uuid, 'James Clark', 'B', 'Acton-Agua Dulce Unified', ''),
  ('c71b2202-e824-4958-8434-a599cb69e1d8'::uuid, 'James Hicks', 'B', 'Acton-Agua Dulce Unified', ''),
  ('133b8a7f-3827-4701-b3be-f75021a07b23'::uuid, 'Linda Aranda', 'B', 'Acton-Agua Dulce Unified', ''),
  ('c5bcafaa-1860-4ebe-be52-3384f50c2997'::uuid, 'Michael Drewry', 'B', 'Acton-Agua Dulce Unified', ''),
  ('f0d86e95-981c-4fca-8033-3232fc24b8be'::uuid, 'Tiffany Kellogg', 'B', 'Acton-Agua Dulce Unified', ''),
  ('ab3b160e-2904-42b0-895e-e28b407ac405'::uuid, 'Frances Robles', 'B', 'Alhambra Unified', ''),
  ('7ac28374-bcaf-4135-aa10-4462559e1a1a'::uuid, 'Luchi Gonzalez', 'B', 'Alhambra Unified', ''),
  ('29d411a9-c672-4549-8c2e-a9b276cf8537'::uuid, 'Ed Chung', 'B', 'Arcadia Unified', ''),
  ('be1c71f8-d5d9-416e-a713-35ccda7a5743'::uuid, 'Elizabeth Mensah', 'B', 'Arcadia Unified', ''),
  ('bf906462-f937-4d8c-b452-6555e95b4bac'::uuid, 'Tim Tran', 'B', 'Arcadia Unified', ''),
  ('b9ded757-2653-4c45-982d-36682b08b8f8'::uuid, 'Diana Coronel', 'B', 'Azusa Unified', ''),
  ('0624c64b-af95-4d06-ac16-ca185f50da42'::uuid, 'Edward Zuniga', 'B', 'Azusa Unified', ''),
  ('195f331d-ebc2-4d05-9adc-f9508fe0b610'::uuid, 'Kimberly Howell', 'B', 'Azusa Unified', ''),
  ('9d2713c4-1d4f-4c40-ae35-b331e9771fa1'::uuid, 'Ariel Mestas', 'B', 'Baldwin Park Unified', ''),
  ('74bfd93c-d707-4432-8e99-ad62a20a1235'::uuid, 'Herman Dace', 'B', 'Baldwin Park Unified', ''),
  ('090f3cb2-20e9-42a9-872e-80081f3b5bfe'::uuid, 'Leticia Garcia', 'B', 'Baldwin Park Unified', ''),
  ('93989522-c68e-4187-bf11-99afb673473f'::uuid, 'Mario Ventura Rodriguez', 'B', 'Baldwin Park Unified', ''),
  ('4fe290b2-aa2f-4ba1-b172-c0e75e8994ee'::uuid, 'Diana Corona', 'B', 'Bassett Unified', ''),
  ('3dc1d627-754d-4053-a11c-c30b6088073a'::uuid, 'John Piazza', 'B', 'Bassett Unified', ''),
  ('ee87befc-d2e3-4a24-acb8-76f95c3ab2ee'::uuid, 'Maria Huerta', 'B', 'Bassett Unified', ''),
  ('9fc809a1-6e91-46ea-9850-b815df5cfbb9'::uuid, 'Rafael Limon', 'B', 'Bassett Unified', ''),
  ('1c0c6ccc-cbe7-43da-b760-7c812943292f'::uuid, 'Roy Munoz', 'B', 'Bassett Unified', ''),
  ('6edc2e44-f7f7-4212-8746-03112a933be3'::uuid, 'Cindy Rosenberger', 'B', 'Bellflower Unified', ''),
  ('688fdc43-4d61-48c8-9216-c5cccf722a47'::uuid, 'Joseph Santoyo', 'B', 'Bellflower Unified', ''),
  ('b0f48347-625e-4b16-8ac1-e05363219688'::uuid, 'Patricia Avalos', 'B', 'Bellflower Unified', ''),
  ('fe5803dd-c13f-4a9a-9c9e-c433a1c390a9'::uuid, 'Rebecca Petz', 'B', 'Bellflower Unified', ''),
  ('2000e3c6-9634-4591-97ce-ad9d21274e5e'::uuid, 'Sheila Lichtblau', 'B', 'Bellflower Unified', ''),
  ('9ddd1703-dbaa-4ec6-8a6b-0ec1ef4ae106'::uuid, 'Svetlana Shagalov', 'B', 'Beverly Hills Unified', ''),
  ('c9875c5f-aa1f-400e-8a7b-e085ee305795'::uuid, 'Ann Behrens', 'B', 'Bonita Unified', ''),
  ('024bd1aa-94da-4189-880d-afbe711eada9'::uuid, 'Greg Hasselbach', 'B', 'Bonita Unified', ''),
  ('9e200512-e820-47a0-97d5-730302469f88'::uuid, 'Joanne Ruelas', 'B', 'Bonita Unified', ''),
  ('38729e85-809c-43f3-9ed8-e6601b22f6cd'::uuid, 'Mike Snelgrove', 'B', 'Bonita Unified', ''),
  ('9cab21a6-f107-4789-bcd1-b5b1e6cd7a15'::uuid, 'Adam Schur', 'B', 'Burbank Unified', ''),
  ('352826a5-7a8a-4f18-980d-a3a655f17720'::uuid, 'Charlene Stiles', 'B', 'Burbank Unified', ''),
  ('2551c624-92bb-4510-8770-e7e10d29c143'::uuid, 'Anita Torres', 'B', 'Charter Oak Unified', ''),
  ('3406623a-e942-4677-b154-541c4c05fbc9'::uuid, 'Lisa Gonzalez', 'B', 'Charter Oak Unified', ''),
  ('0b2c8789-97c0-40e7-927a-c40f01309d3c'::uuid, 'Marcia Riddick', 'B', 'Charter Oak Unified', ''),
  ('29fe6345-0c50-478a-b674-c0868ec29def'::uuid, 'Tim Nader', 'B', 'Charter Oak Unified', ''),
  ('55a6fb8c-df2e-4cd0-9d36-a2db0b3f2262'::uuid, 'Ed Honeycutt', 'B', 'Claremont Unified', ''),
  ('2c2ba201-424e-4a0c-942a-3cb1256f3f37'::uuid, 'Jennifer Becerra', 'B', 'Claremont Unified', ''),
  ('39132ee9-bfb6-47a3-b217-4853f7ba0c15'::uuid, 'Steve Wolan', 'B', 'Claremont Unified', ''),
  ('28018031-c46f-4e1b-b10b-6edf33bb09cc'::uuid, 'Danna Perez', 'B', 'Compton Unified', ''),
  ('fa10414c-4f35-4929-8909-7e7fe6d7ee90'::uuid, 'Dorothy Taylor-Moore', 'B', 'Compton Unified', ''),
  ('235af364-eb4b-40db-8581-fdfb8ff155b6'::uuid, 'Jimmie Thompson', 'B', 'Compton Unified', ''),
  ('f0e9775a-f691-4fe8-84dc-d8f9c5e301c7'::uuid, 'Amy Rottschafer', 'B', 'Covina-Valley Unified', ''),
  ('06b5dac4-73b6-44a3-a279-77b1758a6163'::uuid, 'Cheryl Cox', 'B', 'Covina-Valley Unified', ''),
  ('5a521a16-f581-47a0-90eb-1a44434e705b'::uuid, 'John Garcia', 'B', 'Covina-Valley Unified', ''),
  ('22763240-b5c9-4ad9-912a-a94cb23db695'::uuid, 'Sam Payán', 'B', 'Covina-Valley Unified', ''),
  ('628180d5-26f9-4213-b2c7-6c22ceb120ef'::uuid, 'Dawn Espe', 'B', 'Culver City Unified', ''),
  ('6fe04ab6-3df4-4472-ac27-4c35a9c2f72f'::uuid, 'Jamila Thomas', 'B', 'Culver City Unified', ''),
  ('c46ce1ed-be39-4986-a070-4d12f37ee979'::uuid, 'Sadie Farber', 'B', 'Culver City Unified', ''),
  ('3845a8c4-ef17-4cf1-8384-6d2f57f02b29'::uuid, 'Barbara Ige', 'B', 'Downey Unified', ''),
  ('16f0ef7c-ba0b-4bc4-83ee-a7f0a223282a'::uuid, 'Nila Aikin', 'B', 'Downey Unified', ''),
  ('e3180a6b-2461-442b-a937-2d7b4401a2a3'::uuid, 'Saul Hernandez', 'B', 'Downey Unified', ''),
  ('699196f9-b15d-43e5-acd8-befdd2948793'::uuid, 'Susan Herbers', 'B', 'Downey Unified', ''),
  ('8766ef1c-343a-49d6-aa6c-339a863d704b'::uuid, 'Anna Muñiz', 'B', 'Duarte Unified', ''),
  ('d672334c-0b65-446f-be5e-0594889a71d2'::uuid, 'Denise Jaquez', 'B', 'Duarte Unified', ''),
  ('90db015f-be68-40ea-843c-fc6a42af07d7'::uuid, 'Randy Gonzales', 'B', 'Duarte Unified', ''),
  ('52897998-3e0d-412c-b9d9-fe6360b6dad5'::uuid, 'Valerie Navarro', 'B', 'Duarte Unified', ''),
  ('134cc13a-f45a-442c-9946-4cfe893c46b8'::uuid, 'Diego Cardenas', 'B', 'El Rancho Unified', ''),
  ('84869bde-6410-46f0-bbe2-1315cd5c017b'::uuid, 'Gloria Negrete-Mendoza', 'B', 'El Rancho Unified', ''),
  ('4956d410-f77a-43f8-92c8-e8827e50a17a'::uuid, 'Lesley Chavez Magan', 'B', 'El Rancho Unified', ''),
  ('ea4552a4-3112-4089-9902-1630715cba97'::uuid, 'Raquel Otiniano', 'B', 'El Rancho Unified', ''),
  ('cbe120bb-0a1a-43ff-ad68-87406b499964'::uuid, 'Tony Fuerte', 'B', 'El Rancho Unified', ''),
  ('81154d3e-fe2c-4864-a341-5c8c8538e4b6'::uuid, 'Al Winkler', 'B', 'El Segundo Unified', ''),
  ('1bef4877-5dec-4460-ad79-a7ecb186c1b8'::uuid, 'Amanda Grossman', 'B', 'El Segundo Unified', ''),
  ('c7a69d69-20b9-4d54-ab4a-33198c9f7c78'::uuid, 'Christian Thomas', 'B', 'El Segundo Unified', ''),
  ('d0f59905-f5e3-4e38-a3df-2dc6fb51a4a4'::uuid, 'Dave Horner', 'B', 'El Segundo Unified', ''),
  ('0136184a-71a4-48cf-b3f0-52beb7da6038'::uuid, 'Bob Gard', 'B', 'Glendora Unified', ''),
  ('215f92ac-46d3-4b48-9567-62ecbc9ed45c'::uuid, 'Dawn Sherrill', 'B', 'Glendora Unified', ''),
  ('12223b4f-15c1-4852-9e2a-d1d04ff7c165'::uuid, 'Randy Battenfield', 'B', 'Glendora Unified', ''),
  ('4e21995f-5d6b-44ca-aac6-bef3a65dcfc9'::uuid, 'Stephanie Harding', 'B', 'Glendora Unified', ''),
  ('c5942060-6b40-46f0-8518-9d6aa0e55307'::uuid, 'Dorothy Chi', 'B', 'Hacienda La Puente Unified', ''),
  ('b59c2b42-0cc7-4120-91bd-ea078bb4f248'::uuid, 'Eduardo Arreola', 'B', 'Hacienda La Puente Unified', ''),
  ('3497ebda-ffab-4987-bf69-d59bcbd3eb82'::uuid, 'Gloria Mercado-Vega', 'B', 'Hacienda La Puente Unified', ''),
  ('6acf611b-8790-4e1f-bb08-05164ae18981'::uuid, 'Jorge Blanco', 'B', 'Hacienda La Puente Unified', ''),
  ('4e7828d8-5046-483a-9d71-58cc2d5c0f4c'::uuid, 'Kathleen Reynen', 'B', 'Hacienda La Puente Unified', ''),
  ('97aabe4f-794c-4617-8518-cfefe2cd91b7'::uuid, 'Samuel Lee', 'B', 'Hacienda La Puente Unified', ''),
  ('002969f3-e8cf-4c1e-8ee9-bc855b0f39ac'::uuid, 'Damien Straughn', 'B', 'Inglewood Unified', ''),
  ('0e648516-55fc-4773-ba51-65da7d3c9fda'::uuid, 'Guillermo Vega Jr.', 'B', 'Inglewood Unified', ''),
  ('1d9d72c9-4a06-41eb-8196-a09f879dce80'::uuid, 'Maria Escobedo', 'B', 'Inglewood Unified', ''),
  ('7ea7b7b1-fa32-4652-82a4-4d6f67ad1127'::uuid, 'Yvonne Gallegos', 'B', 'Inglewood Unified', ''),
  ('9f240574-48a1-44f7-9728-712ade528e84'::uuid, 'Brian Riddick', 'B', 'La Cañada Unified', ''),
  ('0720ce76-332a-4817-b887-2e7599934f64'::uuid, 'Darleen Ramos', 'B', 'La Cañada Unified', ''),
  ('ea6acf1c-3ada-4062-b324-0278459c99be'::uuid, 'Diana Carey', 'B', 'La Cañada Unified', ''),
  ('5112b67b-566e-4099-9c8a-2f1fbc623055'::uuid, 'Jon Haraguchi', 'B', 'La Cañada Unified', ''),
  ('64f2bab6-2325-41da-8202-b8dd756aa9d3'::uuid, 'Kristin Shane', 'B', 'La Cañada Unified', ''),
  ('8f5fded3-98c2-4703-8c83-4ccbf8a6cc7d'::uuid, 'Barry Zorthian', 'B', 'Las Virgenes Unified', ''),
  ('62674342-08a9-48ba-bd31-6fb3fe3f8fde'::uuid, 'Christine Wood', 'B', 'Las Virgenes Unified', ''),
  ('49ff1385-476d-4bb3-9912-80202b106cbc'::uuid, 'Shira Katz', 'B', 'Las Virgenes Unified', ''),
  ('09772a05-d16b-45c4-98c6-8a340dc80734'::uuid, 'Lyn Behrens', 'B', 'Long Beach Unified', ''),
  ('8c0fdb31-0020-4d1f-a60b-230e1146eef5'::uuid, 'Alma Carina Larrazolo', 'B', 'Lynwood Unified', ''),
  ('a4e55f6b-f062-4a7d-b86a-e5998d696a46'::uuid, 'George Gamboa', 'B', 'Lynwood Unified', ''),
  ('d6b805e8-d1ac-4a22-9cdc-53d2779668ca'::uuid, 'Jose Ro', 'B', 'Lynwood Unified', ''),
  ('23b32605-c2be-473e-9dd6-4fc2974b80b6'::uuid, 'Raul Saldana', 'B', 'Lynwood Unified', ''),
  ('67b3bb06-3c13-49dc-93d0-1aa7f5b04672'::uuid, 'Holly Bhagavan', 'B', 'Manhattan Beach Unified', ''),
  ('29558ef3-818a-4e33-968c-5abe35f93e1f'::uuid, 'Jason Turner', 'B', 'Manhattan Beach Unified', ''),
  ('102e826e-87df-4731-8ee7-ae7c7f0f07dd'::uuid, 'Joanna Robinson', 'B', 'Manhattan Beach Unified', ''),
  ('9e396ede-1420-4b3e-aab2-d1799e284e18'::uuid, 'Alex Lujan', 'B', 'Monrovia Unified', ''),
  ('2e1658de-04ce-4d50-bb86-6a74f62d2aa6'::uuid, 'Jessica Castro', 'B', 'Monrovia Unified', ''),
  ('341f687f-4a41-414c-8da8-7675922e9283'::uuid, 'Mary Ann Blount', 'B', 'Monrovia Unified', ''),
  ('f931ec44-44cb-443a-9995-f3e0867be886'::uuid, 'Stephanie Juarez', 'B', 'Monrovia Unified', ''),
  ('75c60e41-1ef0-426b-9899-67b8796ea4b8'::uuid, 'Anthony Medina', 'B', 'Montebello Unified', ''),
  ('f8dddc8f-f5aa-4e6e-be08-7f686436b3db'::uuid, 'Christina Lara', 'B', 'Montebello Unified', ''),
  ('051b8e30-2ddf-4e74-95ac-f02ca3abbeea'::uuid, 'Lorraine Abundis', 'B', 'Montebello Unified', ''),
  ('6ded6ac5-dcf5-4e96-aba6-8fc32c827a36'::uuid, 'Paul Shelton', 'B', 'Montebello Unified', ''),
  ('c5d72741-5ca0-4aad-ae06-486b1186d070'::uuid, 'Vanessa Ramirez', 'B', 'Montebello Unified', ''),
  ('60fb595d-32dd-46b2-a090-b8c5b48d208b'::uuid, 'Vicky Martinez', 'B', 'Montebello Unified', ''),
  ('6684b629-12c1-46ac-80ea-6d9e7bf51c6c'::uuid, 'David Gallardo', 'B', 'Norwalk-La Mirada Unified', ''),
  ('52380601-bf5d-4f66-b982-dc79f6a98132'::uuid, 'Doug Goist', 'B', 'Norwalk-La Mirada Unified', ''),
  ('e28513df-231a-420c-9b8c-1ad3b4646d73'::uuid, 'Patricia Mitchell', 'B', 'Norwalk-La Mirada Unified', ''),
  ('af24991f-7ac0-4264-a7db-7d15963ed06e'::uuid, 'Rosy Simas', 'B', 'Norwalk-La Mirada Unified', ''),
  ('f5bc9f89-8f84-4a76-bc7c-a7c05e01813e'::uuid, 'Terri Apodaca', 'B', 'Norwalk-La Mirada Unified', ''),
  ('7cbf6f43-43d0-4a61-84ed-277eb3a8cf05'::uuid, 'Cindy Byelich', 'B', 'Palos Verdes Peninsula Unified', ''),
  ('649e6bdf-eaed-40aa-b383-3af5725209f3'::uuid, 'David Maron', 'B', 'Palos Verdes Peninsula Unified', ''),
  ('c95c888a-8857-421b-af4f-63ddcbace789'::uuid, 'Sandra Dorit', 'B', 'Palos Verdes Peninsula Unified', ''),
  ('9163f6fc-8e93-4065-a49b-a009ff443477'::uuid, 'Stacy Hollingsworth', 'B', 'Palos Verdes Peninsula Unified', ''),
  ('96ee62ec-4a0d-4d02-8d2d-43b84f16a9de'::uuid, 'Susan Craig', 'B', 'Palos Verdes Peninsula Unified', ''),
  ('326107a2-c531-4f59-8879-9ea19f7d0d64'::uuid, 'Dennis Trujillo', 'B', 'Paramount Unified', ''),
  ('0214504a-cd44-4fe8-baf3-fec1796efe1a'::uuid, 'Maria Avalos', 'B', 'Paramount Unified', ''),
  ('3a2a57d8-5502-45ef-aece-3ed0ba1d1e53'::uuid, 'Ramon Quintero', 'B', 'Paramount Unified', ''),
  ('5841f6ec-7b0b-4ccf-9edb-6469c1fe3e48'::uuid, 'Richard Martinez', 'B', 'Paramount Unified', ''),
  ('0821276c-0847-4557-9611-2de17f57939b'::uuid, 'Sandra Soto', 'B', 'Paramount Unified', ''),
  ('7e2ecc87-9c9d-413d-9948-dfb688e59088'::uuid, 'Cynthia Cervantes Jackson', 'B', 'Pasadena Unified', ''),
  ('d9e394d9-3e01-4643-ae70-90fbccc5aeb7'::uuid, 'Adriana Camorlinga', 'B', 'Pomona Unified', ''),
  ('a72b6e3b-1f34-4469-b9d1-622b64496927'::uuid, 'Ashley Johnson', 'B', 'Pomona Unified', ''),
  ('54dbc290-591b-4a01-95c4-6c2c80c68195'::uuid, 'Chuck Kauffman', 'B', 'Pomona Unified', ''),
  ('3f09884f-950d-462b-821f-6161c5d52784'::uuid, 'David Buerge', 'B', 'Pomona Unified', ''),
  ('ca63670f-2000-490e-9a99-0317684f1ad9'::uuid, 'Evelyne Aquilar', 'B', 'Pomona Unified', ''),
  ('4fe30078-fd83-4d42-aca0-83ea14062dd7'::uuid, 'Isabel Cruz', 'B', 'Pomona Unified', ''),
  ('04fcc309-611e-4678-808b-87ca80f95ac6'::uuid, 'Roberta Bacon', 'B', 'Pomona Unified', ''),
  ('52e2ca7c-cf20-490e-97dd-57741a95fb52'::uuid, 'Eric Sheridan', 'B', 'Redondo Beach Unified', ''),
  ('f5925180-4bec-4ab9-9dae-068ad3c8b657'::uuid, 'Maggie McLaughlin', 'B', 'Redondo Beach Unified', ''),
  ('5977fd63-62f6-471d-b379-046423e7fc75'::uuid, 'Mark Schilit', 'B', 'Redondo Beach Unified', ''),
  ('bbff7247-f129-41ef-8d39-393b3c973163'::uuid, 'Naomi Kim', 'B', 'Redondo Beach Unified', ''),
  ('00c36fe6-86e1-4bd8-bfd7-417739ce553e'::uuid, 'Rosie Ferree', 'B', 'Redondo Beach Unified', ''),
  ('9b1ebb14-fc87-4705-8639-667d8f3b3101'::uuid, 'Cary Romo Nakayama', 'B', 'Rowland Unified', ''),
  ('7d4241b8-cc27-48a0-9b76-f205f2eeca84'::uuid, 'Jeff Mata', 'B', 'Rowland Unified', ''),
  ('015e3a37-ac58-49a1-8483-1343f33a9356'::uuid, 'Jeff Seawright', 'B', 'Rowland Unified', ''),
  ('296f315f-bb67-4816-9bcd-a59108ce972a'::uuid, 'Marilyn Solorzano', 'B', 'Rowland Unified', ''),
  ('9dc46319-a05f-4370-9ab6-8577bb61fb91'::uuid, 'Mike Bhatt', 'B', 'Rowland Unified', ''),
  ('d46f8101-1cc9-4f2f-8e6a-ceb58febba8b'::uuid, 'Estela Sanchez-Torres', 'B', 'San Gabriel Unified', ''),
  ('e526fc4e-536d-4878-b1f0-5d2b903a6ee0'::uuid, 'Megan Ngo', 'B', 'San Gabriel Unified', ''),
  ('8825a1a2-c225-47d3-8848-8fa687f0f7ba'::uuid, 'Nora Martinez', 'B', 'San Gabriel Unified', ''),
  ('a4ed6e28-252b-4bd5-a6f2-ddb96c37aa3f'::uuid, 'Yvette Vivanco', 'B', 'San Gabriel Unified', ''),
  ('3aeeb9e8-68e7-4bd3-a4ff-19958d46debd'::uuid, 'Yvonne Marquez', 'B', 'San Gabriel Unified', ''),
  ('1a7a4b31-f17f-4e95-954b-0cd7f78b5e85'::uuid, 'Ann Huang', 'B', 'San Marino Unified', ''),
  ('910b1c9b-1af6-48a1-ac98-1d93605a915f'::uuid, 'Jason Paguio', 'B', 'San Marino Unified', ''),
  ('7b2e6829-ce2b-41c7-9258-4f65bb72c258'::uuid, 'Linh Nguyen', 'B', 'San Marino Unified', ''),
  ('59d50869-a5c4-4e95-9276-a129e984fb8d'::uuid, 'Marcella Hovey', 'B', 'San Marino Unified', ''),
  ('d0b60b59-207f-4687-86c9-15c7810d4117'::uuid, 'Tom Regan', 'B', 'San Marino Unified', ''),
  ('636c3d78-e230-4c1f-b267-921c4775b2c4'::uuid, 'Alicia Brodkin', 'B', 'Santa Monica-Malibu Unified', ''),
  ('fdc4de72-cd43-4ff8-b13e-28e1c419fe83'::uuid, 'Roy Rifkin', 'B', 'Santa Monica-Malibu Unified', ''),
  ('a22830b9-27ab-44b5-900d-ece20863a822'::uuid, 'James Chang', 'B', 'Temple City Unified', ''),
  ('412056da-037b-4e87-9c5f-bd4fec768d39'::uuid, 'Kevin Pan', 'B', 'Temple City Unified', ''),
  ('09f4a078-f1fa-4cfb-b8fe-6b90200105d2'::uuid, 'Lena Lee Liu', 'B', 'Temple City Unified', ''),
  ('544aa910-95a2-4443-99e5-6a3b350940ae'::uuid, 'George Fuller', 'B', 'Torrance Unified', ''),
  ('08f76054-5a5d-4543-88de-569ffb4d5b96'::uuid, 'Michael Rock', 'B', 'Torrance Unified', ''),
  ('509fe7b3-e444-4b85-9ffe-850d2adf7809'::uuid, 'Cindy Ruelas', 'B', 'Walnut Valley Unified', ''),
  ('a077e0db-3534-46b9-aee9-40eafb0d019a'::uuid, 'John Castellano', 'B', 'Walnut Valley Unified', ''),
  ('23e22371-fd7f-470d-9d2e-4bb9151bceb1'::uuid, 'Nathan Donato', 'B', 'Walnut Valley Unified', ''),
  ('1d6cb616-1d88-4010-9d91-2f13f625c58f'::uuid, 'Noy Palacios', 'B', 'Walnut Valley Unified', ''),
  ('4a11c484-260d-4f62-a7d3-2011cd163f70'::uuid, 'Wenling Chin', 'B', 'Walnut Valley Unified', ''),
  ('a08c5e26-feee-4bbf-a60a-5de90eda74b5'::uuid, 'Ben Kay', 'B', 'West Covina Unified', ''),
  ('af08db12-bace-48ce-b9e5-eaa0e3e2ffd8'::uuid, 'Cynthia Moran', 'B', 'West Covina Unified', ''),
  ('4d0397a4-6863-4e57-bfdf-510d3738630b'::uuid, 'Joe Panganiban', 'B', 'West Covina Unified', ''),
  ('8f362998-d0ae-490d-a3df-1d5a5de9243f'::uuid, 'Lorenzo Munoz', 'B', 'West Covina Unified', ''),
  ('f12ba4c2-859f-4453-9b32-37624d0132a0'::uuid, 'Anastasia Flores', 'B', 'Wiseburn Unified', ''),
  ('6fa8ba0f-8afc-4bfa-ba1a-970f2a50171f'::uuid, 'Jody Dean', 'B', 'Wiseburn Unified', ''),
  ('91687c59-c7b0-4b20-8bdd-8cd2ba3e07b5'::uuid, 'Matt Addington', 'B', 'Wiseburn Unified', ''),
  ('9bd840d2-3877-42ab-ac68-961accbf9140'::uuid, 'Michael Murphy', 'B', 'Wiseburn Unified', ''),
  ('f930cd79-ce2f-4a9e-9e73-1d29a3abd4dc'::uuid, 'Patricia Ollie', 'B', 'Wiseburn Unified', ''),
  ('661de009-8046-4beb-ba70-420a862e78e8'::uuid, 'Vivian Malauulu', 'C0M', 'ABC Unified', ''),
  ('9f4f1f7f-52be-4b7f-885d-112ff0039119'::uuid, 'Gary Hardie', 'C0H', 'Covina-Valley Unified', ''),
  ('1a0a34d3-0203-4f5a-a4f0-2e4f27034b48'::uuid, 'Sho Tay', 'C', 'Arcadia Unified', 'https://www.pasadenastarnews.com/2014/04/08/tom-beck-roger-chandler-and-sho-tay-elected-to-arcadia-city-council/ — "Tom Beck, Roger Chandler and Sho Tay elected to Arcadia City Council"'),
  ('29435a50-1e00-4a96-bc0b-9e3755a2a0fa'::uuid, 'Joseph Rocha', 'C', 'Azusa Unified', 'https://www.biographies.net/people/en/joseph_r_rocha — "Rocha has been a member of the Azusa City Council since 1997 and was elected Mayor in 2007."'),
  ('4022fac2-7c62-48fe-a194-b451796f636f'::uuid, 'Carl Coles', 'C', 'Bonita Unified', 'https://caschoolnews.net/articles/bonita-unified-school-district-to-celebrate-retiring-board-member/ — "Bonita Unified Superintendent Carl J. Coles said."'),
  ('f9695574-91b2-482f-823d-0ee090298ee2'::uuid, 'Judy Chen Haggerty', 'C', 'Duarte Unified', 'https://www.mtsac.edu/governance/trustees/members/chen.html — "Judy Chen Haggerty has served as a member of the Mt. SAC Board of Trustees since 2001."'),
  ('99effb34-c061-4956-887a-46efa4cd099d'::uuid, 'Adrienne Konigar-Macklin', 'C', 'Inglewood Unified', 'https://ballotpedia.org/Adrienne_D._Konigar-Macklin — "Adrienne D. Konigar-Macklin is an incumbent member of and was a candidate for an at-large seat on the Pomona Unified School District School Board"'),
  ('d71d9dca-9256-46fd-851c-a61d54ec488b'::uuid, 'Herlinda Chico', 'C', 'Long Beach Unified', 'https://ballotpedia.org/Herlinda_Chico — "Herlinda Chico was a member of the Long Beach Community College District Board of Trustees in California, representing Area 4."'),
  ('f3f377a7-5eef-4c16-9df5-6828ac4eeb4e'::uuid, 'Tim Goodrich', 'C', 'Torrance Unified', 'https://web.archive.org/web/20201025000036/https://www.torranceca.gov/Government/City-Council/Goodrich — "Tim Goodrich was first elected to the City Council on June 3, 2014, and re-elected on June 5, 2018."'),
  ('ced90e57-de77-4a49-a9d8-5fa4ec9599c7'::uuid, 'Darcy McNaboe', 'C', 'West Covina Unified', 'https://cdnsm5-hosted.civiclive.com/UserFiles/Servers/Server_12337255/File/Government/Voting%20Elections/CandidateStatement_DarcyMcNaboe.pdf — "As Mayor, I provided leadership necessary for Grand Terrace to weather recent turbulent times"'),
  ('7db07f24-2ec9-4011-82cb-19c9e36468d6'::uuid, 'Gary Springer', 'C', 'Glendale Unified', 'absent from the district''s own list of every trustee 1936-2026 (gusd.net/8457_3, read 2026-09-22)'),
  ('636ff578-53a3-4b98-8421-0492afbba802'::uuid, 'Kathia Dipp Metzler', 'C', 'Glendale Unified', 'absent from the district''s own list of every trustee 1936-2026 (gusd.net/8457_3, read 2026-09-22)'),
  ('1d2080a9-c3a3-4ee5-9d4e-dab183b00a44'::uuid, 'Don Galvan', 'C', 'South Pasadena Unified', 'absent from the district''s own list of every trustee 1923-present (spusd.net Past Board Members, uREC_ID=756712 pREC_ID=1379457, read 2026-09-22)'),
  ('6514b3c1-7846-42bf-be84-d5c0077a2dcf'::uuid, 'Jennifer Kassan', 'C', 'South Pasadena Unified', 'absent from the district''s own list of every trustee 1923-present (spusd.net Past Board Members, uREC_ID=756712 pREC_ID=1379457, read 2026-09-22)'),
  ('8c7c3d26-3d21-492a-86ae-db73cee53f09'::uuid, 'Rosemary Cortez', 'C', 'South Pasadena Unified', 'absent from the district''s own list of every trustee 1923-present (spusd.net Past Board Members, uREC_ID=756712 pREC_ID=1379457, read 2026-09-22)'),
  ('fbd175e9-5edb-49d8-8d04-3b3b84c47b5f'::uuid, 'Rosemary Lim Youngblood', 'C', 'South Pasadena Unified', 'absent from the district''s own list of every trustee 1923-present (spusd.net Past Board Members, uREC_ID=756712 pREC_ID=1379457, read 2026-09-22)'),
  ('d7b1c97d-fc07-456a-8de8-b31d8a9eb517'::uuid, 'Ying Chen', 'C', 'South Pasadena Unified', 'absent from the district''s own list of every trustee 1923-present (spusd.net Past Board Members, uREC_ID=756712 pREC_ID=1379457, read 2026-09-22)');

CREATE TEMP TABLE _del (term_id uuid PRIMARY KEY, politician_id uuid, office_id uuid) ON COMMIT DROP;
INSERT INTO _del VALUES
  ('ea635ff3-ca08-4569-9344-09837bc5dd93'::uuid, '1a0a34d3-0203-4f5a-a4f0-2e4f27034b48'::uuid, '53e6bd33-e92c-4d09-bb6b-6ffd28b65f6f'::uuid),  -- Sho Tay
  ('f75f8cc5-b73c-4c5e-bbb1-e68aa97c7c1e'::uuid, '29435a50-1e00-4a96-bc0b-9e3755a2a0fa'::uuid, 'dac64cb9-808b-41a0-80d5-9d9a847cff38'::uuid),  -- Joseph Rocha
  ('3dd1d428-ad6e-4a72-96e6-1439eb51bf8d'::uuid, '4022fac2-7c62-48fe-a194-b451796f636f'::uuid, 'b6db7900-474c-4775-82ed-5f6acf2edb5b'::uuid),  -- Carl Coles
  ('3125e5f7-6171-4f67-8320-15327b56b82f'::uuid, 'f9695574-91b2-482f-823d-0ee090298ee2'::uuid, '359bdf54-8484-42b7-bf2e-a37e15d6acfa'::uuid),  -- Judy Chen Haggerty
  ('42db3091-a578-473c-b01f-95445e30686f'::uuid, '99effb34-c061-4956-887a-46efa4cd099d'::uuid, '4eda120c-2eb3-4907-959a-5be8df86d503'::uuid),  -- Adrienne Konigar-Macklin
  ('923986dc-cc45-47c6-94e1-f48b5025a08b'::uuid, 'd71d9dca-9256-46fd-851c-a61d54ec488b'::uuid, '49604161-db6c-4ff3-8a85-6b9ecdfeaeef'::uuid),  -- Herlinda Chico
  ('93954c83-f74b-4ebe-983a-e0026cd94386'::uuid, 'f3f377a7-5eef-4c16-9df5-6828ac4eeb4e'::uuid, '1d941c9d-5576-4a37-83f9-eb7a98d9b929'::uuid),  -- Tim Goodrich
  ('69e3a4b0-3414-4400-9e60-a8c0bfa0a94a'::uuid, 'ced90e57-de77-4a49-a9d8-5fa4ec9599c7'::uuid, '10047a98-d090-4183-8bff-8a1bee926b0f'::uuid),  -- Darcy McNaboe
  ('bed833af-fe76-4545-8599-f5c57568bdb3'::uuid, '7db07f24-2ec9-4011-82cb-19c9e36468d6'::uuid, '1d696a35-2bac-4571-bc98-ccba92a8c1b1'::uuid),  -- Gary Springer
  ('7b87c46a-1361-4292-b31b-20486ed2de03'::uuid, '636ff578-53a3-4b98-8421-0492afbba802'::uuid, '95ee13cd-7b88-47e1-8ceb-1b9e6e5df698'::uuid),  -- Kathia Dipp Metzler
  ('d3786a80-28d4-4d20-9a1d-6ba2c49cb18e'::uuid, '1d2080a9-c3a3-4ee5-9d4e-dab183b00a44'::uuid, 'cf23db9e-ed5b-4edf-af7a-e6c60824e3d7'::uuid),  -- Don Galvan
  ('eb3f11b2-48fe-464d-b213-d28027ce7007'::uuid, '6514b3c1-7846-42bf-be84-d5c0077a2dcf'::uuid, 'e8dd3801-1bdc-4a55-bd52-1c71c7a2f88f'::uuid),  -- Jennifer Kassan
  ('b81d2e8f-4d07-4d32-995b-7abf3944c3b5'::uuid, '8c7c3d26-3d21-492a-86ae-db73cee53f09'::uuid, 'bb8d35c0-56cf-4ea2-abc1-98dc420b103a'::uuid),  -- Rosemary Cortez
  ('535772a1-6843-46d8-ba08-911eec3bc85b'::uuid, 'fbd175e9-5edb-49d8-8d04-3b3b84c47b5f'::uuid, 'e93511a7-8d11-4b45-8f52-3eaea4c456d4'::uuid),  -- Rosemary Lim Youngblood
  ('0df9130c-ae23-4a6c-8725-a1d211e68272'::uuid, 'd7b1c97d-fc07-456a-8de8-b31d8a9eb517'::uuid, '5a946b9e-8e89-4410-8f96-d5105641eea8'::uuid)   -- Ying Chen
;

CREATE TEMP TABLE _baseline ON COMMIT DROP AS
  SELECT (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms,
         (SELECT count(*) FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
           WHERE _a.cls = 'A1' AND ot.term_end IS NULL) AS a1_open_terms;

-- ─── PRE-FLIGHT: derive-then-verify every identifier ───────────────────────────────────────────────
DO $$
DECLARE v_n int; v_m int;
BEGIN
  SELECT count(*) INTO v_n FROM _a;
  IF v_n <> 238 THEN RAISE EXCEPTION 'PRE: expected 238 audit rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT cls, count(*) c FROM _a GROUP BY cls) x
   WHERE (cls, c) NOT IN (('A1',16),('A2',27),('B',178),('C',15),('C0H',1),('C0M',1));
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: class counts differ from the approved plan'; END IF;

  -- every row is the politician we audited: same id, same name, same seeding pass
  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE p.full_name = _a.full_name
     AND p.data_source LIKE 'https://empowered.vote/school-district/%unified'
     AND p.data_source NOT LIKE '%los_angeles_unified';
  IF v_n <> 238 THEN RAISE EXCEPTION 'PRE: only % of 238 politicians match id+name+data_source', v_n; END IF;

  -- and the audit covered the WHOLE population (nobody seeded since, nobody missed)
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.data_source LIKE 'https://empowered.vote/school-district/%unified'
     AND p.data_source NOT LIKE '%los_angeles_unified'
     AND NOT EXISTS (SELECT 1 FROM _a WHERE _a.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % unified-board rows exist that the audit did not classify', v_n; END IF;

  -- deactivating orphans nothing: no stance data on ANY of the 238
  SELECT (SELECT count(*) FROM inform.politician_answers x JOIN _a ON _a.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.politician_context x JOIN _a ON _a.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.politician_context_evidence x JOIN _a ON _a.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.evidence_items x JOIN _a ON _a.politician_id = x.politician_id)
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % stance/evidence rows exist for audited politicians -- decide them first', v_n; END IF;

  -- no one being deactivated is on a ballot (only Malauulu, who stays active, has a race row)
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN _a ON _a.politician_id = rc.politician_id
   WHERE _a.cls IN ('B','C','C0H');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race_candidates rows point at politicians about to be deactivated', v_n; END IF;

  -- every A1 still holds exactly one open term
  SELECT count(*) INTO v_n FROM _a
   WHERE cls = 'A1' AND (SELECT count(*) FROM essentials.office_terms ot
                          WHERE ot.politician_id = _a.politician_id AND ot.term_end IS NULL) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % A1 rows no longer hold exactly one open term', v_n; END IF;

  -- no one outside A1 holds an open term (their closures are what this audit builds on)
  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls <> 'A1' AND ot.term_end IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % open terms held by non-A1 audited politicians', v_n; END IF;

  -- each term to delete is either still present exactly as audited, or already archived (re-run)
  SELECT count(*) INTO v_n FROM _del d JOIN essentials.office_terms ot
      ON ot.id = d.term_id AND ot.politician_id = d.politician_id AND ot.office_id = d.office_id
     AND ot.term_start IS NULL AND ot.term_end IS NOT NULL;
  SELECT count(*) INTO v_m FROM _del d JOIN essentials._fabricated_ca0156_removed r ON r.id = d.term_id;
  IF v_n + v_m <> 15 OR (SELECT count(*) FROM _del) <> 15 THEN
    RAISE EXCEPTION 'PRE: terms to delete: % present + % archived, expected 15', v_n, v_m; END IF;

  -- deleting them never empties a seat: each office also holds the successor's term
  SELECT count(*) INTO v_n FROM _del d JOIN essentials.office_terms ot ON ot.id = d.term_id
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms s
                      WHERE s.office_id = d.office_id AND s.id <> d.term_id AND s.term_start > ot.term_end);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % deletable terms have no successor on their seat', v_n; END IF;

  -- the C terms belong to C politicians and to nobody else
  SELECT count(*) INTO v_n FROM _del d LEFT JOIN _a ON _a.politician_id = d.politician_id
   WHERE _a.cls IS DISTINCT FROM 'C';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % deletable terms are not held by class-C politicians', v_n; END IF;
END $$;

-- ─── 1. C: archive, then delete, the disproved terms ────────────────────────────────────────────────
INSERT INTO essentials._fabricated_ca0156_removed
SELECT ot.*,
       'CA_0156: recorded ' || _a.district || ' board seat disproved -- ' || _a.evidence,
       now()
  FROM essentials.office_terms ot
  JOIN _del d ON d.term_id = ot.id AND d.politician_id = ot.politician_id
  JOIN _a ON _a.politician_id = d.politician_id
 WHERE NOT EXISTS (SELECT 1 FROM essentials._fabricated_ca0156_removed r WHERE r.id = ot.id);

DELETE FROM essentials.office_terms ot
 USING _del d
 WHERE ot.id = d.term_id AND ot.politician_id = d.politician_id
   AND EXISTS (SELECT 1 FROM essentials._fabricated_ca0156_removed r WHERE r.id = ot.id);

-- ─── 2. Tag the closed terms that stay ──────────────────────────────────────────────────────────────
UPDATE essentials.office_terms ot
   SET source = ot.source || ' | verified CA_0156 (2026-09-22): real former board member -- ' || _a.evidence
  FROM _a
 WHERE _a.politician_id = ot.politician_id AND _a.cls = 'A2'
   AND ot.term_end IS NOT NULL AND ot.source NOT LIKE '%CA_0156%';

UPDATE essentials.office_terms ot
   SET source = ot.source || ' | unverified CA_0156 (2026-09-22): no evidence this person ever served on '
                || 'this board (RR/CC lists 2017-2026, RR/CC results 2013-2026, district rosters, news); '
                || 'seeded by the unsourced school-district pass; politician deactivated, term kept (not disproved)'
  FROM _a
 WHERE _a.politician_id = ot.politician_id AND _a.cls = 'B'
   AND ot.term_end IS NOT NULL AND ot.source NOT LIKE '%CA_0156%';

-- ─── 3. Party: never stored (antipartisan) ──────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET party = NULL, party_short_name = NULL
  FROM _a
 WHERE _a.politician_id = p.id AND (p.party IS NOT NULL OR p.party_short_name IS NOT NULL);

-- ─── 4. Flags ───────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = false
  FROM _a
 WHERE _a.politician_id = p.id AND _a.cls <> 'A1' AND p.is_incumbent;

UPDATE essentials.politicians p
   SET is_active = false
  FROM _a
 WHERE _a.politician_id = p.id AND _a.cls IN ('B','C','C0H') AND p.is_active;

-- ─── 5. One audit note per non-A1 row ───────────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET notes = COALESCE(p.notes, ARRAY[]::text[]) || ARRAY[
       CASE _a.cls
         WHEN 'A2'  THEN 'CA_0156 (2026-09-22): verified former ' || _a.district || ' board member -- ' || _a.evidence
         WHEN 'B'   THEN 'CA_0156 (2026-09-22): NO EVIDENCE of service on the ' || _a.district || ' board. Seeded by '
                         || 'the unsourced school-district pass (placeholder data_source). Searched LA RR/CC candidate '
                         || 'lists 2017-2026 and results 2013-2026, district rosters incl. Wayback, local news. '
                         || 'Deactivated; closed term kept and tagged unverified (absence is not disproof).'
         WHEN 'C'   THEN 'CA_0156 (2026-09-22): recorded ' || _a.district || ' board seat DISPROVED -- ' || _a.evidence
                         || '. Term archived to essentials._fabricated_ca0156_removed and deleted; row deactivated '
                         || 'and retained for audit.'
         WHEN 'C0H' THEN 'CA_0156 (2026-09-22): duplicate of ''Gary Hardie Jr.'' (b5eb36c0-877f-4cf5-8f24-ed48b6fd8ced), '
                         || 'who holds the Lynwood USD seat; this row''s wrong Covina-Valley term was deleted by CA_0149. Deactivated.'
         WHEN 'C0M' THEN 'CA_0156 (2026-09-22): not an ABC USD trustee (term deleted by CA_0146); a Long Beach Community '
                         || 'College District trustee (NetFile: Re-Elect Vivian Malauulu for LBCCD Trustee 2024). Holds no '
                         || 'seat in this DB, so is_incumbent cleared; kept active for her 2026 LB Council D7 race.'
       END]
  FROM _a
 WHERE _a.politician_id = p.id AND _a.cls <> 'A1'
   AND NOT EXISTS (SELECT 1 FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0156%');

-- ─── POST-VERIFY ────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE p.party IS NOT NULL OR p.party_short_name IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % audited rows still carry a party', v_n; END IF;

  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE p.is_active <> (_a.cls IN ('A1','A2','C0M'));
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows have the wrong is_active', v_n; END IF;

  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE p.is_incumbent <> (_a.cls = 'A1');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows have the wrong is_incumbent', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls = 'C';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % terms remain for class-C politicians', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials._fabricated_ca0156_removed r JOIN _del d ON d.term_id = r.id;
  IF v_n <> 15 THEN RAISE EXCEPTION 'POST: archive holds % of the 15 deleted terms', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls IN ('A2','B') AND ot.source NOT LIKE '%CA_0156%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % A2/B terms are untagged', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms ot JOIN _a ON _a.politician_id = ot.politician_id
   WHERE _a.cls = 'A1' AND ot.term_end IS NULL;
  IF v_n <> (SELECT a1_open_terms FROM _baseline) OR v_n <> 16 THEN
    RAISE EXCEPTION 'POST: A1 open terms = %, expected 16 and unchanged', v_n; END IF;

  SELECT count(*) INTO v_n FROM _a JOIN essentials.politicians p ON p.id = _a.politician_id
   WHERE _a.cls <> 'A1'
     AND (SELECT count(*) FROM unnest(COALESCE(p.notes, ARRAY[]::text[])) n WHERE n LIKE 'CA_0156%') <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % non-A1 rows lack exactly one CA_0156 note', v_n; END IF;

  -- no seat lost its occupancy record
  SELECT count(*) INTO v_n FROM essentials.offices_missing_terms;
  IF v_n <> (SELECT missing_terms FROM _baseline) THEN
    RAISE EXCEPTION 'POST: offices_missing_terms moved from % to %', (SELECT missing_terms FROM _baseline), v_n; END IF;

  -- still no stance data touched
  SELECT (SELECT count(*) FROM inform.politician_answers x JOIN _a ON _a.politician_id = x.politician_id)
       + (SELECT count(*) FROM inform.politician_context x JOIN _a ON _a.politician_id = x.politician_id)
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: stance rows appeared (%)', v_n; END IF;
END $$;

COMMIT;
