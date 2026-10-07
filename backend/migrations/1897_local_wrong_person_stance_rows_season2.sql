-- 1897_local_wrong_person_stance_rows_season2.sql
-- The LOCAL half of the wrong-person class: chairs built from a DIFFERENT politician's evidence.
-- The federal half closed in migration 1896 (ev-accounts #904). This is what it left behind.
--
-- OUTCOME: 24 keys blanked, 3 blocked, 2 recorded findings WITHDRAWN as false positives.
--   22 context + 22 answer rows INSERTED into Season 2; 2 existing Season 2 keys UPDATED in place.
--   SEASON 1 IS NOT TOUCHED. Nothing is deleted.
--
-- 🔴 WHY A FORWARD WRITE. Season 1 is CLOSED and IMMUTABLE -- inform.closed_season_is_immutable()
-- rejects any write there and its own error text names the remedy: write in the OPEN season,
-- which shadows the old row on read without destroying history. Shape as 1870, 1893, 1894, 1896.
-- 🔑 A BLANK IS `value 0` INSERTED, NEVER A DELETE -- a deleted Season 2 row falls back to
-- Season 1 and the bad chair stays visible (CC_0057). Every blank below CARRIES THE SOURCES IT
-- EXAMINED (migration 1887's rule).
--
-- ══ THE HANDOFF SAID 8 ROWS. IT IS 27, AND TWO OF THE 8 WERE NOT DEFECTS AT ALL ══════════════
-- Migration 1896 recorded a local remainder of 8 rows across 5 officials plus 2 candidates. Each
-- of those officials was re-read ROW BY ROW rather than key by key, because the rule 1896
-- established is that THE REPAIR UNIT IS THE PERSON, NOT THE KEY. The count roughly tripled:
--
--   Liz Ortega        <- Laura Richardson      recorded 1, actually  6
--   Steve Bennett     <- Suzette Valladares    recorded 2, actually  5
--   Katy Yaroslavsky  <- Sheila Kuehl          recorded 3, actually  6
--   Eddie Morales     <- Dustin Burrows        recorded 1, actually  1
--   Elizabeth Campos  <- Dustin Burrows        recorded 1, actually  1
--   Steve Johnson (MD)                         recorded 0, actually  8
--
-- 🔴🔴 THE REASON THE FIRST COUNT WAS LOW IS THE SAME REASON AS LAST TIME, ONE LEVEL DEEPER.
-- 1896's finding was that a borrowed CAMPAIGN WEBSITE scores clean on every "is this generic?"
-- test. The local rows show that a borrowed BILL CITATION is worse: Ortega's and Bennett's
-- contaminated rows cite leginfo.legislature.ca.gov bill pages -- the most specific, most
-- primary-looking source in the entire corpus -- and the bills are real. They are simply
-- SOMEONE ELSE'S BILLS. Only the rows that happened to cite a Wikipedia BIOGRAPHY were visible
-- to the probe that found them; the bill-cited rows were invisible and are the majority.
--
-- ══ HOW EACH LINK IS PROVED ══════════════════════════════════════════════════════════════════
-- 🔑 THE STRONGEST PROOF NEEDED NO EXTERNAL PAGE AT ALL. Both California cases are settled by
-- this database contradicting itself: Laura Richardson and Suzette Martinez Valladares are both
-- rows here, both CALIFORNIA STATE SENATORS, and OUR OWN ROWS FOR THEM ATTRIBUTE THE VERY SAME
-- BILLS TO THEM. "Richardson authored SB 510 (2025)" and "Authored SB 510" sit in the corpus
-- under two different people. So do SB 530, SB 611, SB 752, SB 767, SB 34, SB 1137 and SB 1144.
--   * Liz Ortega is an ASSEMBLY MEMBER; her rows credit her with authoring SENATE bills, with a
--     "prior US House record" and with being a "prior Long Beach City Council member". She has
--     never served in the US House or on the Long Beach City Council. Laura Richardson did both.
--     en.wikipedia.org/wiki/Laura_Richardson: "Richardson" 103 hits, "Ortega" 0, "Hayward" 0.
--   * Steve Bennett is a DEMOCRATIC Assembly member from Ventura; his rows describe a "Republican
--     senator" who "narrowly lost to Pilar Schiavo in 2022 and won back a senate seat in 2024",
--     whose "grandfather was a Cesar Chavez farmworker", a "founding member of the bipartisan
--     Problem Solvers Caucus". Every one of those is Valladares, verbatim from her article.
--     en.wikipedia.org/wiki/Suzette_Martinez_Valladares: "Valladares" 33, "Republican" 33,
--     "Schiavo" 5, "Ventura" 1 -- and "Bennett" 1.
--     🔑🔑 THAT SINGLE "Bennett" HIT IS THE MECHANISM. It is the infobox line "Member of the
--     California State Assembly from the 38th district ... Succeeded by Steve Bennett". THE
--     CONTAMINATION TRAVELLED ALONG A SUCCESSION LINK -- the predecessor's article is one click
--     from the subject's and names him once, as his own predecessor. This is not a name
--     collision and no name-based probe can find it. Every officeholder has such a neighbour.
--
-- ══ A SECOND MECHANISM: INHERITANCE FROM A MENTOR ════════════════════════════════════════════
-- Katy Yaroslavsky's six rows are not a misfiling. The research states the gap in its own words
-- -- "No specific vote or statement on childcare policy was found", "No specific LA City Council
-- votes on healthcare access were found" -- and then seats the chair on SHEILA KUEHL, the county
-- supervisor she once worked for: "Her mentor Sheila Kuehl was a champion of childcare", "her
-- mentor Sheila Kuehl co-authored California's first same-sex marriage bill in 2002". Two rows
-- cite en.wikipedia.org/wiki/Sheila_Kuehl as their ONLY source. 🔑 NO PROBE IN THE SET CAN SEE
-- THIS, because every name on the page is correct and the substitution is openly stated. WHOM
-- SOMEONE WORKED FOR IS NOT A POSITION THEY HOLD.
--
-- ══ A THIRD: THE PARTY AND THE INSTRUMENTS ARE BOTH INVENTED ═════════════════════════════════
-- Steve Johnson is a DEMOCRATIC Maryland Delegate, District 34A, Harford County. All eight of
-- his Season 1 chairs sit at RUNG 4 and each is reached by calling him a Republican -- "As an
-- Eastern Shore Republican", "As a Republican member". His own cited page says "Party Democrat"
-- ("Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0), and across the 150 bills
-- it lists, "Solar" 0, "Generating Station" 0, "Redistricting" 0, "Scholarship" 0, "Voter" 0 and
-- "Citizenship" 0 -- that is five of the eight chairs resting on bills that are not on his
-- record. One claim is contradicted outright: the public-safety row says he opposes "major
-- police accountability reforms", and his page lists him as a CO-SPONSOR of HB0508, "Public
-- Safety - Police Accountability - Investigation Records".
-- ⚠ THE LIMIT IS STATED IN EVERY BLANK: that bill list covers the 2025 and 2026 sessions only,
-- so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our
-- Elections Act of 2026, which is dated inside it.
--
-- ══ TWO RECORDED FINDINGS ARE WITHDRAWN ══════════════════════════════════════════════════════
-- 1896 recorded two candidates under "no source names them". Both are WRONG and are withdrawn
-- here rather than left to be re-derived:
--   * N'Kiyla Thomas (OK) cites jasmineforok.com. That IS her own site: it is headed "N'kiyla
--     Jasmine Thomas For US Senate" and its footer reads "Paid for By N'Kiyla For OK". She
--     campaigns under her middle name. Her rows are sound and are left alone.
--   * Gary Crockett (LA) cites a WWNO candidate Q&A. That page names him 5 times, runs his
--     photo, and carries his answers in the first person -- "I am Moderate/pro-choice ... I
--     oppose total abortion bans", which is exactly what his chair says. Sound, left alone.
-- 🔑 THE LESSON: "does any source name them?" was run against the URL and the name string, not
-- against the PAGE. A probe that fires must be confirmed by reading the page, or it manufactures
-- false defects as readily as it finds real ones.
--
-- ══ BLOCKED: THE SAME ORPHAN TOPIC AS LAST TIME ══════════════════════════════════════════════
-- Three contaminated rows CANNOT be written: Ortega / immigration (chair 2), Bennett /
-- immigration (chair 4) and Yaroslavsky / immigration (chair 2). `immigration` has NO Season 2
-- pin -- it is the Season-1-only orphan topic -- so there is no row to shadow the bad one with.
-- 🔴 WITH THE THREE FEDERAL ONES STILL STANDING FROM 1896 (Joshi 5, Vindman 4, Roth 2), SIX
-- WRONG-PERSON CHAIRS REMAIN VISIBLE TO VOTERS, ALL OF THEM ON `immigration`, AND NONE OF THEM
-- CAN BE FIXED BY A SEASON 2 WRITE. That is now the single largest blocked defect in the audit
-- and it belongs to the Season 3 decision, not to this migration. A pre-guard below asserts that
-- immigration still has no Season 2 pin, so that if it ever gains one this file's own guard
-- fails loudly and the six are revisited.
--
-- ⚠ NOT FIXED HERE, DELIBERATELY. Every row of all six people was read. Besides the 27 above,
-- Yaroslavsky carries a large SELF-CONFESSED-ABSENCE cluster (abortion, deportation, economic-
-- development, jail-capacity, rent-regulation, school-vouchers, taxes, voting-rights, local-
-- immigration all open with "no specific vote or statement was found" or cite only the generic
-- en.wikipedia.org/wiki/Sanctuary_city article). Those are a different defect class with its own
-- queue, and widening this migration to cover them would have made it unreviewable. They are
-- recorded in the dispositions file beside this one.

DO $pre$
DECLARE n integer;
BEGIN
  -- The Season 1 cohort, asserted as (politician, topic, value) TRIPLES. A value list alone
  -- would still pass if two rows had swapped, so the triple is the assertion that matters.
  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND (a.politician_id, a.topic_id, a.value) IN (
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
    ('c1914284-9aee-44f4-8b7f-a833d8f392e7'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 4)
  );
  IF n <> 24 THEN
    RAISE EXCEPTION 'migration 1897: expected 24 Season 1 rows at their recorded chairs, found %', n;
  END IF;

  -- Season 2 must be EMPTY for every key we INSERT, and must hold the recorded value for
  -- every key we UPDATE in place.
  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('c1914284-9aee-44f4-8b7f-a833d8f392e7'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid)
  );
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1897: % Season 2 rows already exist for the insert keys', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id, a.value) IN (
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2)
  );
  IF n <> 2 THEN
    RAISE EXCEPTION 'migration 1897: the 2 update keys are not at their recorded Season 2 values (found %)', n;
  END IF;

  -- Every topic written here must be pinned in Season 2 at the revision we are writing.
  SELECT count(*) INTO n FROM (
    SELECT DISTINCT topic_id, topic_revision_id FROM (VALUES
      ('00b95a6a-75db-4521-b523-3326bba938de'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid),
      ('0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid),
      ('48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid),
      ('669cac97-66a6-4087-b036-936fbe62efb3'::uuid, '598c879d-f387-461c-9120-fbbbf6314bbc'::uuid),
      ('9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, 'c334f475-05bd-48ba-9d25-f4de593a3f15'::uuid),
      ('a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid),
      ('c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid),
      ('c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, '8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid),
      ('cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid),
      ('d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid),
      ('d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid),
      ('e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid),
      ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid),
      ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid),
      ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid)
    ) AS v(topic_id, topic_revision_id)) w
  WHERE NOT EXISTS (SELECT 1 FROM inform.season_questions sq
                     WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND sq.topic_id = w.topic_id
                       AND sq.topic_revision_id = w.topic_revision_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1897: % written topics are not pinned in Season 2 at the stated revision', n;
  END IF;

  -- The three blocked keys ride on `immigration`, which still has NO Season 2 pin. If that
  -- ever changes, these three contaminated chairs become writable and must be revisited.
  SELECT count(*) INTO n FROM inform.season_questions sq
    JOIN inform.compass_topics t ON t.id = sq.topic_id
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND t.topic_key = 'immigration';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1897: immigration now HAS a Season 2 pin (%) -- the 3 blocked keys are writable, revisit', n;
  END IF;
END
$pre$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
VALUES
  -- Liz Ortega / civil-rights  (Season 1 chair 2 -> blank)
  ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Laura Richardson''s research filed under Assembly Member Liz Ortega. Both are California Democrats and both are rows in this database: Liz Ortega is an Assembly Member; Laura Richardson is a State Senator, and before that a member of the US House of Representatives and of the Long Beach City Council. The rows filed under Ortega credit her with AUTHORING Senate bills -- SB 510, SB 530, SB 535, SB 611, SB 748, SB 752, SB 767, SB 34 -- and with a "prior US House record" and service as a "prior Long Beach City Council member". 🔑 THE DECISIVE TEST NEEDS NO PAGE: Liz Ortega has never served in the US House and never sat on the Long Beach City Council. Laura Richardson did both, and THIS DATABASE''S OWN ROW FOR RICHARDSON ATTRIBUTES THE VERY SAME BILLS TO HER -- "Richardson authored SB 510 (2025)", "Richardson authored SB 530 (2025)", "Richardson authored SB 611 (2025)", "authored SB 752", "authored SB 767", "Richardson authored SB 34 (2025) on port emissions". The immigration row cites en.wikipedia.org/wiki/Laura_Richardson outright: control term "Richardson" 103 hits, "Ortega" 0, "Hayward" 0. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB510']::text[]),
  -- Liz Ortega / climate-change  (Season 1 chair 3 -> blank)
  ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Laura Richardson''s research filed under Assembly Member Liz Ortega. Both are California Democrats and both are rows in this database: Liz Ortega is an Assembly Member; Laura Richardson is a State Senator, and before that a member of the US House of Representatives and of the Long Beach City Council. The rows filed under Ortega credit her with AUTHORING Senate bills -- SB 510, SB 530, SB 535, SB 611, SB 748, SB 752, SB 767, SB 34 -- and with a "prior US House record" and service as a "prior Long Beach City Council member". 🔑 THE DECISIVE TEST NEEDS NO PAGE: Liz Ortega has never served in the US House and never sat on the Long Beach City Council. Laura Richardson did both, and THIS DATABASE''S OWN ROW FOR RICHARDSON ATTRIBUTES THE VERY SAME BILLS TO HER -- "Richardson authored SB 510 (2025)", "Richardson authored SB 530 (2025)", "Richardson authored SB 611 (2025)", "authored SB 752", "authored SB 767", "Richardson authored SB 34 (2025) on port emissions". The immigration row cites en.wikipedia.org/wiki/Laura_Richardson outright: control term "Richardson" 103 hits, "Ortega" 0, "Hayward" 0. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB752']::text[]),
  -- Liz Ortega / healthcare  (Season 1 chair 2 -> blank)
  ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Laura Richardson''s research filed under Assembly Member Liz Ortega. Both are California Democrats and both are rows in this database: Liz Ortega is an Assembly Member; Laura Richardson is a State Senator, and before that a member of the US House of Representatives and of the Long Beach City Council. The rows filed under Ortega credit her with AUTHORING Senate bills -- SB 510, SB 530, SB 535, SB 611, SB 748, SB 752, SB 767, SB 34 -- and with a "prior US House record" and service as a "prior Long Beach City Council member". 🔑 THE DECISIVE TEST NEEDS NO PAGE: Liz Ortega has never served in the US House and never sat on the Long Beach City Council. Laura Richardson did both, and THIS DATABASE''S OWN ROW FOR RICHARDSON ATTRIBUTES THE VERY SAME BILLS TO HER -- "Richardson authored SB 510 (2025)", "Richardson authored SB 530 (2025)", "Richardson authored SB 611 (2025)", "authored SB 752", "authored SB 767", "Richardson authored SB 34 (2025) on port emissions". The immigration row cites en.wikipedia.org/wiki/Laura_Richardson outright: control term "Richardson" 103 hits, "Ortega" 0, "Hayward" 0. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB530', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB535']::text[]),
  -- Liz Ortega / medicare/aid  (Season 1 chair 2 -> blank)
  ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Laura Richardson''s research filed under Assembly Member Liz Ortega. Both are California Democrats and both are rows in this database: Liz Ortega is an Assembly Member; Laura Richardson is a State Senator, and before that a member of the US House of Representatives and of the Long Beach City Council. The rows filed under Ortega credit her with AUTHORING Senate bills -- SB 510, SB 530, SB 535, SB 611, SB 748, SB 752, SB 767, SB 34 -- and with a "prior US House record" and service as a "prior Long Beach City Council member". 🔑 THE DECISIVE TEST NEEDS NO PAGE: Liz Ortega has never served in the US House and never sat on the Long Beach City Council. Laura Richardson did both, and THIS DATABASE''S OWN ROW FOR RICHARDSON ATTRIBUTES THE VERY SAME BILLS TO HER -- "Richardson authored SB 510 (2025)", "Richardson authored SB 530 (2025)", "Richardson authored SB 611 (2025)", "authored SB 752", "authored SB 767", "Richardson authored SB 34 (2025) on port emissions". The immigration row cites en.wikipedia.org/wiki/Laura_Richardson outright: control term "Richardson" 103 hits, "Ortega" 0, "Hayward" 0. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB530']::text[]),
  -- Steve Bennett / climate-change  (Season 1 chair 4 -> blank)
  ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Suzette Martinez Valladares''s research filed under Assembly Member Steve Bennett. Steve Bennett is a DEMOCRATIC member of the California State Assembly representing Ventura. The rows filed under him describe a "Republican senator", a "Republican representing Santa Clarita/Simi Valley", and a "Republican who narrowly lost to Pilar Schiavo in 2022 and won back a senate seat in 2024". That is Suzette Martinez Valladares, a Republican state senator, who is a separate row in this database. Two of the rows cite en.wikipedia.org/wiki/Suzette_Martinez_Valladares outright and carry her biography verbatim: "her grandfather was a farmworker who worked alongside Cesar Chavez" and "one of the inaugural members of the California State Legislature''s Problem Solvers Caucus". Control terms on that page: "Valladares" 33 hits, "Republican" 33, "Schiavo" 5, "Bennett" 1. 🔑 THE SINGLE "Bennett" HIT IS THE MECHANISM, NOT A COINCIDENCE: it is the infobox line "Member of the California State Assembly from the 38th district ... Succeeded by Steve Bennett". THE CONTAMINATION TRAVELLED ALONG A SUCCESSION LINK, not a name collision -- the article is one click from his own and names him exactly once, as the man who replaced her. This database''s own row for Valladares attributes the same tax bills to her: "authored SB 1144 (increasing the dependent exemption credit from $475 to $700 for 2026-2030), SB 1137 (lowering the medical expense deduction threshold from 7.5% to 4% of AGI)". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1161']::text[]),
  -- Steve Bennett / fossil-fuels  (Season 1 chair 4 -> blank)
  ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Suzette Martinez Valladares''s research filed under Assembly Member Steve Bennett. Steve Bennett is a DEMOCRATIC member of the California State Assembly representing Ventura. The rows filed under him describe a "Republican senator", a "Republican representing Santa Clarita/Simi Valley", and a "Republican who narrowly lost to Pilar Schiavo in 2022 and won back a senate seat in 2024". That is Suzette Martinez Valladares, a Republican state senator, who is a separate row in this database. Two of the rows cite en.wikipedia.org/wiki/Suzette_Martinez_Valladares outright and carry her biography verbatim: "her grandfather was a farmworker who worked alongside Cesar Chavez" and "one of the inaugural members of the California State Legislature''s Problem Solvers Caucus". Control terms on that page: "Valladares" 33 hits, "Republican" 33, "Schiavo" 5, "Bennett" 1. 🔑 THE SINGLE "Bennett" HIT IS THE MECHANISM, NOT A COINCIDENCE: it is the infobox line "Member of the California State Assembly from the 38th district ... Succeeded by Steve Bennett". THE CONTAMINATION TRAVELLED ALONG A SUCCESSION LINK, not a name collision -- the article is one click from his own and names him exactly once, as the man who replaced her. This database''s own row for Valladares attributes the same tax bills to her: "authored SB 1144 (increasing the dependent exemption credit from $475 to $700 for 2026-2030), SB 1137 (lowering the medical expense deduction threshold from 7.5% to 4% of AGI)". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1161']::text[]),
  -- Steve Bennett / school-vouchers  (Season 1 chair 4 -> blank)
  ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Suzette Martinez Valladares''s research filed under Assembly Member Steve Bennett. Steve Bennett is a DEMOCRATIC member of the California State Assembly representing Ventura. The rows filed under him describe a "Republican senator", a "Republican representing Santa Clarita/Simi Valley", and a "Republican who narrowly lost to Pilar Schiavo in 2022 and won back a senate seat in 2024". That is Suzette Martinez Valladares, a Republican state senator, who is a separate row in this database. Two of the rows cite en.wikipedia.org/wiki/Suzette_Martinez_Valladares outright and carry her biography verbatim: "her grandfather was a farmworker who worked alongside Cesar Chavez" and "one of the inaugural members of the California State Legislature''s Problem Solvers Caucus". Control terms on that page: "Valladares" 33 hits, "Republican" 33, "Schiavo" 5, "Bennett" 1. 🔑 THE SINGLE "Bennett" HIT IS THE MECHANISM, NOT A COINCIDENCE: it is the infobox line "Member of the California State Assembly from the 38th district ... Succeeded by Steve Bennett". THE CONTAMINATION TRAVELLED ALONG A SUCCESSION LINK, not a name collision -- the article is one click from his own and names him exactly once, as the man who replaced her. This database''s own row for Valladares attributes the same tax bills to her: "authored SB 1144 (increasing the dependent exemption credit from $475 to $700 for 2026-2030), SB 1137 (lowering the medical expense deduction threshold from 7.5% to 4% of AGI)". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://en.wikipedia.org/wiki/Suzette_Martinez_Valladares']::text[]),
  -- Steve Bennett / taxes  (Season 1 chair 4 -> blank)
  ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Suzette Martinez Valladares''s research filed under Assembly Member Steve Bennett. Steve Bennett is a DEMOCRATIC member of the California State Assembly representing Ventura. The rows filed under him describe a "Republican senator", a "Republican representing Santa Clarita/Simi Valley", and a "Republican who narrowly lost to Pilar Schiavo in 2022 and won back a senate seat in 2024". That is Suzette Martinez Valladares, a Republican state senator, who is a separate row in this database. Two of the rows cite en.wikipedia.org/wiki/Suzette_Martinez_Valladares outright and carry her biography verbatim: "her grandfather was a farmworker who worked alongside Cesar Chavez" and "one of the inaugural members of the California State Legislature''s Problem Solvers Caucus". Control terms on that page: "Valladares" 33 hits, "Republican" 33, "Schiavo" 5, "Bennett" 1. 🔑 THE SINGLE "Bennett" HIT IS THE MECHANISM, NOT A COINCIDENCE: it is the infobox line "Member of the California State Assembly from the 38th district ... Succeeded by Steve Bennett". THE CONTAMINATION TRAVELLED ALONG A SUCCESSION LINK, not a name collision -- the article is one click from his own and names him exactly once, as the man who replaced her. This database''s own row for Valladares attributes the same tax bills to her: "authored SB 1144 (increasing the dependent exemption credit from $475 to $700 for 2026-2030), SB 1137 (lowering the medical expense deduction threshold from 7.5% to 4% of AGI)". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1137', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1144', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB17']::text[]),
  -- Katy Yaroslavsky / trans-athletes  (Season 1 chair 2 -> blank)
  ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid, 'Blanked 2026-10-07. 🔴 THE CHAIR RESTS ON A DIFFERENT PERSON''S RECORD. Katy Yaroslavsky is a Los Angeles City Council member; this chair is reached from the record of Sheila Kuehl, the former LA County Supervisor and state legislator she once worked for. The same-sex-marriage and trans-athletes rows cite en.wikipedia.org/wiki/Sheila_Kuehl as their ONLY source. The reasoning states the gap itself -- "No specific vote or statement on childcare policy was found", "No specific LA City Council votes on healthcare access were found", "No specific statement or vote by Yaroslavsky on transgender athletes was found" -- and then seats the chair on Kuehl anyway: "Her mentor Sheila Kuehl was a champion of childcare and early childhood programs", "her mentor Sheila Kuehl co-authored California''s first same-sex marriage bill in 2002", "Her background working for Kuehl -- who authored LGBTQ protections in California -- signals consistent support", "her background at Climate Action Reserve and working for Kuehl aligns with strengthening civil rights protections". 🔑 THIS IS INHERITANCE, NOT A MISFILING. The research did not confuse two people; it substituted a mentor''s positions for the subject''s, which is why no name-token, state or party probe can see it -- every name on the page is correct. WHOM SOMEONE WORKED FOR IS NOT A POSITION THEY HOLD. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://en.wikipedia.org/wiki/Sheila_Kuehl']::text[]),
  -- Katy Yaroslavsky / childcare  (Season 1 chair 2 -> blank)
  ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-07. 🔴 THE CHAIR RESTS ON A DIFFERENT PERSON''S RECORD. Katy Yaroslavsky is a Los Angeles City Council member; this chair is reached from the record of Sheila Kuehl, the former LA County Supervisor and state legislator she once worked for. The same-sex-marriage and trans-athletes rows cite en.wikipedia.org/wiki/Sheila_Kuehl as their ONLY source. The reasoning states the gap itself -- "No specific vote or statement on childcare policy was found", "No specific LA City Council votes on healthcare access were found", "No specific statement or vote by Yaroslavsky on transgender athletes was found" -- and then seats the chair on Kuehl anyway: "Her mentor Sheila Kuehl was a champion of childcare and early childhood programs", "her mentor Sheila Kuehl co-authored California''s first same-sex marriage bill in 2002", "Her background working for Kuehl -- who authored LGBTQ protections in California -- signals consistent support", "her background at Climate Action Reserve and working for Kuehl aligns with strengthening civil rights protections". 🔑 THIS IS INHERITANCE, NOT A MISFILING. The research did not confuse two people; it substituted a mentor''s positions for the subject''s, which is why no name-token, state or party probe can see it -- every name on the page is correct. WHOM SOMEONE WORKED FOR IS NOT A POSITION THEY HOLD. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky']::text[]),
  -- Katy Yaroslavsky / healthcare  (Season 1 chair 2 -> blank)
  ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07. 🔴 THE CHAIR RESTS ON A DIFFERENT PERSON''S RECORD. Katy Yaroslavsky is a Los Angeles City Council member; this chair is reached from the record of Sheila Kuehl, the former LA County Supervisor and state legislator she once worked for. The same-sex-marriage and trans-athletes rows cite en.wikipedia.org/wiki/Sheila_Kuehl as their ONLY source. The reasoning states the gap itself -- "No specific vote or statement on childcare policy was found", "No specific LA City Council votes on healthcare access were found", "No specific statement or vote by Yaroslavsky on transgender athletes was found" -- and then seats the chair on Kuehl anyway: "Her mentor Sheila Kuehl was a champion of childcare and early childhood programs", "her mentor Sheila Kuehl co-authored California''s first same-sex marriage bill in 2002", "Her background working for Kuehl -- who authored LGBTQ protections in California -- signals consistent support", "her background at Climate Action Reserve and working for Kuehl aligns with strengthening civil rights protections". 🔑 THIS IS INHERITANCE, NOT A MISFILING. The research did not confuse two people; it substituted a mentor''s positions for the subject''s, which is why no name-token, state or party probe can see it -- every name on the page is correct. WHOM SOMEONE WORKED FOR IS NOT A POSITION THEY HOLD. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky']::text[]),
  -- Katy Yaroslavsky / civil-rights  (Season 1 chair 2 -> blank)
  ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-07. 🔴 THE CHAIR RESTS ON A DIFFERENT PERSON''S RECORD. Katy Yaroslavsky is a Los Angeles City Council member; this chair is reached from the record of Sheila Kuehl, the former LA County Supervisor and state legislator she once worked for. The same-sex-marriage and trans-athletes rows cite en.wikipedia.org/wiki/Sheila_Kuehl as their ONLY source. The reasoning states the gap itself -- "No specific vote or statement on childcare policy was found", "No specific LA City Council votes on healthcare access were found", "No specific statement or vote by Yaroslavsky on transgender athletes was found" -- and then seats the chair on Kuehl anyway: "Her mentor Sheila Kuehl was a champion of childcare and early childhood programs", "her mentor Sheila Kuehl co-authored California''s first same-sex marriage bill in 2002", "Her background working for Kuehl -- who authored LGBTQ protections in California -- signals consistent support", "her background at Climate Action Reserve and working for Kuehl aligns with strengthening civil rights protections". 🔑 THIS IS INHERITANCE, NOT A MISFILING. The research did not confuse two people; it substituted a mentor''s positions for the subject''s, which is why no name-token, state or party probe can see it -- every name on the page is correct. WHOM SOMEONE WORKED FOR IS NOT A POSITION THEY HOLD. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://www.planningreport.com/2019/09/03/katy-young-yaroslavsky-unpacks-measure-w-implementation-la-s-safe-clean-water-program', 'https://jewishinsider.com/2022/06/los-angeles-city-council-sam-yebri-katy-young-yaroslavsky-scott-epstein-jimmy-biblarz/']::text[]),
  -- Eddie Morales / redistricting  (Season 1 chair 1 -> blank)
  ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-07. 🔴 THE CITED EVIDENCE IS ABOUT A DIFFERENT PERSON, AND ON THE OPPOSITE SIDE. This redistricting chair cites en.wikipedia.org/wiki/Dustin_Burrows. Dustin Burrows is the REPUBLICAN Speaker of the Texas House who presided over the 2025 mid-decade congressional redistricting that this row opposes, and he is a separate row in this database (Representative, TX, Republican). Nothing in that citation records this member''s own position. The reasoning reaches the chair from party membership alone -- "Democrats in the Texas House unanimously opposed the 2025 mid-decade congressional redistricting" -- plus a conditional about the district: "Morales''s district was potentially affected by new maps designed to protect Republican incumbents". 🔑 A PARTY IS NOT AN INSTRUMENT, AND AN OPPONENT''S ARTICLE IS NOT EVIDENCE ABOUT THIS MEMBER. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://www.texastribune.org/2025/09/04/2025-texas-redistricting-maps/', 'https://en.wikipedia.org/wiki/Dustin_Burrows']::text[]),
  -- Elizabeth Campos / redistricting  (Season 1 chair 1 -> blank)
  ('c1914284-9aee-44f4-8b7f-a833d8f392e7'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-07. 🔴 THE CITED EVIDENCE IS ABOUT A DIFFERENT PERSON, AND ON THE OPPOSITE SIDE. This redistricting chair cites en.wikipedia.org/wiki/Dustin_Burrows. Dustin Burrows is the REPUBLICAN Speaker of the Texas House who presided over the 2025 mid-decade congressional redistricting that this row opposes, and he is a separate row in this database (Representative, TX, Republican). Nothing in that citation records this member''s own position. The reasoning reaches the chair from party membership alone -- "Democrats in the Texas House unanimously opposed the 2025 mid-decade congressional redistricting" -- plus a conditional about the district: "Campos would support independent redistricting commissions over partisan map drawing", stated as an expectation rather than a record. 🔑 A PARTY IS NOT AN INSTRUMENT, AND AN OPPONENT''S ARTICLE IS NOT EVIDENCE ABOUT THIS MEMBER. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://www.texastribune.org/2025/09/04/2025-texas-redistricting-maps/', 'https://en.wikipedia.org/wiki/Dustin_Burrows']::text[]),
  -- Steve Johnson / climate-change  (Season 1 chair 4 -> blank)
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE REASONING DESCRIBES A REPUBLICAN; THE CITED PAGE SAYS DEMOCRAT. All eight of Steve Johnson''s Season 1 chairs sit at rung 4 and each is reached by calling him a Republican -- "As an Eastern Shore Republican", "As a Republican member", "consistent with Republican preference for private market healthcare". His own cited page, mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01, states "Party Democrat", District 34A, County Harford, Health Committee. Control terms on that page: "Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0. This database records him as a Democrat. 🔴 THE INSTRUMENTS ARE NOT ON HIS RECORD EITHER. That page lists 150 bills for the 2025 and 2026 sessions. Control terms across the list: "Solar" 0 and "Generating Station" 0 (the climate-change and fossil-fuels rows rest on a "Solar Energy - Construction of Generating Stations in Priority Preservation Areas" bill); "Redistricting" 0 in any bill title (the "Fair Districts for Maryland Act"); "Scholarship" 0 (the "Opting in on Opportunity Act"); "Voter" 0 and "Citizenship" 0 (the "SAVE Our Elections Act of 2026"). ⚠ THE LIMIT, STATED PLAINLY: that list covers the 2025 and 2026 sessions only, so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our Elections Act of 2026, which is dated inside it. 🔴 AND ONE CLAIM IS CONTRADICTED OUTRIGHT: the public-safety row says he is "opposing major police accountability reforms", while his own page lists him as a CO-SPONSOR of HB0508, "Public Safety - Police Accountability - Investigation Records Relating to Not Administratively Charged, Unfounded, and Exonerated Complaints". The bills that ARE his are real and have nothing to do with these chairs: optometry board revisions, physician and midwife parity, interference-of-custody penalties, and a Schedule III scheduling bill for medetomidine and xylazine. ⚠ ballotpedia.org/Steve_Johnson_(Maryland), the second source on the voting-rights row, returned a page on which every control term scored 0, including both party names; it was NOT READ and nothing is asserted about its contents in either direction. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]),
  -- Steve Johnson / fossil-fuels  (Season 1 chair 4 -> blank)
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE REASONING DESCRIBES A REPUBLICAN; THE CITED PAGE SAYS DEMOCRAT. All eight of Steve Johnson''s Season 1 chairs sit at rung 4 and each is reached by calling him a Republican -- "As an Eastern Shore Republican", "As a Republican member", "consistent with Republican preference for private market healthcare". His own cited page, mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01, states "Party Democrat", District 34A, County Harford, Health Committee. Control terms on that page: "Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0. This database records him as a Democrat. 🔴 THE INSTRUMENTS ARE NOT ON HIS RECORD EITHER. That page lists 150 bills for the 2025 and 2026 sessions. Control terms across the list: "Solar" 0 and "Generating Station" 0 (the climate-change and fossil-fuels rows rest on a "Solar Energy - Construction of Generating Stations in Priority Preservation Areas" bill); "Redistricting" 0 in any bill title (the "Fair Districts for Maryland Act"); "Scholarship" 0 (the "Opting in on Opportunity Act"); "Voter" 0 and "Citizenship" 0 (the "SAVE Our Elections Act of 2026"). ⚠ THE LIMIT, STATED PLAINLY: that list covers the 2025 and 2026 sessions only, so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our Elections Act of 2026, which is dated inside it. 🔴 AND ONE CLAIM IS CONTRADICTED OUTRIGHT: the public-safety row says he is "opposing major police accountability reforms", while his own page lists him as a CO-SPONSOR of HB0508, "Public Safety - Police Accountability - Investigation Records Relating to Not Administratively Charged, Unfounded, and Exonerated Complaints". The bills that ARE his are real and have nothing to do with these chairs: optometry board revisions, physician and midwife parity, interference-of-custody penalties, and a Schedule III scheduling bill for medetomidine and xylazine. ⚠ ballotpedia.org/Steve_Johnson_(Maryland), the second source on the voting-rights row, returned a page on which every control term scored 0, including both party names; it was NOT READ and nothing is asserted about its contents in either direction. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]),
  -- Steve Johnson / healthcare  (Season 1 chair 4 -> blank)
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE REASONING DESCRIBES A REPUBLICAN; THE CITED PAGE SAYS DEMOCRAT. All eight of Steve Johnson''s Season 1 chairs sit at rung 4 and each is reached by calling him a Republican -- "As an Eastern Shore Republican", "As a Republican member", "consistent with Republican preference for private market healthcare". His own cited page, mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01, states "Party Democrat", District 34A, County Harford, Health Committee. Control terms on that page: "Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0. This database records him as a Democrat. 🔴 THE INSTRUMENTS ARE NOT ON HIS RECORD EITHER. That page lists 150 bills for the 2025 and 2026 sessions. Control terms across the list: "Solar" 0 and "Generating Station" 0 (the climate-change and fossil-fuels rows rest on a "Solar Energy - Construction of Generating Stations in Priority Preservation Areas" bill); "Redistricting" 0 in any bill title (the "Fair Districts for Maryland Act"); "Scholarship" 0 (the "Opting in on Opportunity Act"); "Voter" 0 and "Citizenship" 0 (the "SAVE Our Elections Act of 2026"). ⚠ THE LIMIT, STATED PLAINLY: that list covers the 2025 and 2026 sessions only, so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our Elections Act of 2026, which is dated inside it. 🔴 AND ONE CLAIM IS CONTRADICTED OUTRIGHT: the public-safety row says he is "opposing major police accountability reforms", while his own page lists him as a CO-SPONSOR of HB0508, "Public Safety - Police Accountability - Investigation Records Relating to Not Administratively Charged, Unfounded, and Exonerated Complaints". The bills that ARE his are real and have nothing to do with these chairs: optometry board revisions, physician and midwife parity, interference-of-custody penalties, and a Schedule III scheduling bill for medetomidine and xylazine. ⚠ ballotpedia.org/Steve_Johnson_(Maryland), the second source on the voting-rights row, returned a page on which every control term scored 0, including both party names; it was NOT READ and nothing is asserted about its contents in either direction. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]),
  -- Steve Johnson / judicial-criminal-justice  (Season 1 chair 4 -> blank)
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c334f475-05bd-48ba-9d25-f4de593a3f15'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE REASONING DESCRIBES A REPUBLICAN; THE CITED PAGE SAYS DEMOCRAT. All eight of Steve Johnson''s Season 1 chairs sit at rung 4 and each is reached by calling him a Republican -- "As an Eastern Shore Republican", "As a Republican member", "consistent with Republican preference for private market healthcare". His own cited page, mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01, states "Party Democrat", District 34A, County Harford, Health Committee. Control terms on that page: "Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0. This database records him as a Democrat. 🔴 THE INSTRUMENTS ARE NOT ON HIS RECORD EITHER. That page lists 150 bills for the 2025 and 2026 sessions. Control terms across the list: "Solar" 0 and "Generating Station" 0 (the climate-change and fossil-fuels rows rest on a "Solar Energy - Construction of Generating Stations in Priority Preservation Areas" bill); "Redistricting" 0 in any bill title (the "Fair Districts for Maryland Act"); "Scholarship" 0 (the "Opting in on Opportunity Act"); "Voter" 0 and "Citizenship" 0 (the "SAVE Our Elections Act of 2026"). ⚠ THE LIMIT, STATED PLAINLY: that list covers the 2025 and 2026 sessions only, so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our Elections Act of 2026, which is dated inside it. 🔴 AND ONE CLAIM IS CONTRADICTED OUTRIGHT: the public-safety row says he is "opposing major police accountability reforms", while his own page lists him as a CO-SPONSOR of HB0508, "Public Safety - Police Accountability - Investigation Records Relating to Not Administratively Charged, Unfounded, and Exonerated Complaints". The bills that ARE his are real and have nothing to do with these chairs: optometry board revisions, physician and midwife parity, interference-of-custody penalties, and a Schedule III scheduling bill for medetomidine and xylazine. ⚠ ballotpedia.org/Steve_Johnson_(Maryland), the second source on the voting-rights row, returned a page on which every control term scored 0, including both party names; it was NOT READ and nothing is asserted about its contents in either direction. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]),
  -- Steve Johnson / public-safety-approach  (Season 1 chair 4 -> blank)
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE REASONING DESCRIBES A REPUBLICAN; THE CITED PAGE SAYS DEMOCRAT. All eight of Steve Johnson''s Season 1 chairs sit at rung 4 and each is reached by calling him a Republican -- "As an Eastern Shore Republican", "As a Republican member", "consistent with Republican preference for private market healthcare". His own cited page, mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01, states "Party Democrat", District 34A, County Harford, Health Committee. Control terms on that page: "Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0. This database records him as a Democrat. 🔴 THE INSTRUMENTS ARE NOT ON HIS RECORD EITHER. That page lists 150 bills for the 2025 and 2026 sessions. Control terms across the list: "Solar" 0 and "Generating Station" 0 (the climate-change and fossil-fuels rows rest on a "Solar Energy - Construction of Generating Stations in Priority Preservation Areas" bill); "Redistricting" 0 in any bill title (the "Fair Districts for Maryland Act"); "Scholarship" 0 (the "Opting in on Opportunity Act"); "Voter" 0 and "Citizenship" 0 (the "SAVE Our Elections Act of 2026"). ⚠ THE LIMIT, STATED PLAINLY: that list covers the 2025 and 2026 sessions only, so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our Elections Act of 2026, which is dated inside it. 🔴 AND ONE CLAIM IS CONTRADICTED OUTRIGHT: the public-safety row says he is "opposing major police accountability reforms", while his own page lists him as a CO-SPONSOR of HB0508, "Public Safety - Police Accountability - Investigation Records Relating to Not Administratively Charged, Unfounded, and Exonerated Complaints". The bills that ARE his are real and have nothing to do with these chairs: optometry board revisions, physician and midwife parity, interference-of-custody penalties, and a Schedule III scheduling bill for medetomidine and xylazine. ⚠ ballotpedia.org/Steve_Johnson_(Maryland), the second source on the voting-rights row, returned a page on which every control term scored 0, including both party names; it was NOT READ and nothing is asserted about its contents in either direction. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]),
  -- Steve Johnson / redistricting  (Season 1 chair 4 -> blank)
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE REASONING DESCRIBES A REPUBLICAN; THE CITED PAGE SAYS DEMOCRAT. All eight of Steve Johnson''s Season 1 chairs sit at rung 4 and each is reached by calling him a Republican -- "As an Eastern Shore Republican", "As a Republican member", "consistent with Republican preference for private market healthcare". His own cited page, mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01, states "Party Democrat", District 34A, County Harford, Health Committee. Control terms on that page: "Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0. This database records him as a Democrat. 🔴 THE INSTRUMENTS ARE NOT ON HIS RECORD EITHER. That page lists 150 bills for the 2025 and 2026 sessions. Control terms across the list: "Solar" 0 and "Generating Station" 0 (the climate-change and fossil-fuels rows rest on a "Solar Energy - Construction of Generating Stations in Priority Preservation Areas" bill); "Redistricting" 0 in any bill title (the "Fair Districts for Maryland Act"); "Scholarship" 0 (the "Opting in on Opportunity Act"); "Voter" 0 and "Citizenship" 0 (the "SAVE Our Elections Act of 2026"). ⚠ THE LIMIT, STATED PLAINLY: that list covers the 2025 and 2026 sessions only, so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our Elections Act of 2026, which is dated inside it. 🔴 AND ONE CLAIM IS CONTRADICTED OUTRIGHT: the public-safety row says he is "opposing major police accountability reforms", while his own page lists him as a CO-SPONSOR of HB0508, "Public Safety - Police Accountability - Investigation Records Relating to Not Administratively Charged, Unfounded, and Exonerated Complaints". The bills that ARE his are real and have nothing to do with these chairs: optometry board revisions, physician and midwife parity, interference-of-custody penalties, and a Schedule III scheduling bill for medetomidine and xylazine. ⚠ ballotpedia.org/Steve_Johnson_(Maryland), the second source on the voting-rights row, returned a page on which every control term scored 0, including both party names; it was NOT READ and nothing is asserted about its contents in either direction. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]),
  -- Steve Johnson / school-vouchers  (Season 1 chair 4 -> blank)
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE REASONING DESCRIBES A REPUBLICAN; THE CITED PAGE SAYS DEMOCRAT. All eight of Steve Johnson''s Season 1 chairs sit at rung 4 and each is reached by calling him a Republican -- "As an Eastern Shore Republican", "As a Republican member", "consistent with Republican preference for private market healthcare". His own cited page, mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01, states "Party Democrat", District 34A, County Harford, Health Committee. Control terms on that page: "Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0. This database records him as a Democrat. 🔴 THE INSTRUMENTS ARE NOT ON HIS RECORD EITHER. That page lists 150 bills for the 2025 and 2026 sessions. Control terms across the list: "Solar" 0 and "Generating Station" 0 (the climate-change and fossil-fuels rows rest on a "Solar Energy - Construction of Generating Stations in Priority Preservation Areas" bill); "Redistricting" 0 in any bill title (the "Fair Districts for Maryland Act"); "Scholarship" 0 (the "Opting in on Opportunity Act"); "Voter" 0 and "Citizenship" 0 (the "SAVE Our Elections Act of 2026"). ⚠ THE LIMIT, STATED PLAINLY: that list covers the 2025 and 2026 sessions only, so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our Elections Act of 2026, which is dated inside it. 🔴 AND ONE CLAIM IS CONTRADICTED OUTRIGHT: the public-safety row says he is "opposing major police accountability reforms", while his own page lists him as a CO-SPONSOR of HB0508, "Public Safety - Police Accountability - Investigation Records Relating to Not Administratively Charged, Unfounded, and Exonerated Complaints". The bills that ARE his are real and have nothing to do with these chairs: optometry board revisions, physician and midwife parity, interference-of-custody penalties, and a Schedule III scheduling bill for medetomidine and xylazine. ⚠ ballotpedia.org/Steve_Johnson_(Maryland), the second source on the voting-rights row, returned a page on which every control term scored 0, including both party names; it was NOT READ and nothing is asserted about its contents in either direction. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]),
  -- Steve Johnson / voting-rights  (Season 1 chair 4 -> blank)
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-07. 🔴🔴 THE REASONING DESCRIBES A REPUBLICAN; THE CITED PAGE SAYS DEMOCRAT. All eight of Steve Johnson''s Season 1 chairs sit at rung 4 and each is reached by calling him a Republican -- "As an Eastern Shore Republican", "As a Republican member", "consistent with Republican preference for private market healthcare". His own cited page, mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01, states "Party Democrat", District 34A, County Harford, Health Committee. Control terms on that page: "Harford" 15 hits, "Democrat" 1, "Republican" 0, "Eastern Shore" 0. This database records him as a Democrat. 🔴 THE INSTRUMENTS ARE NOT ON HIS RECORD EITHER. That page lists 150 bills for the 2025 and 2026 sessions. Control terms across the list: "Solar" 0 and "Generating Station" 0 (the climate-change and fossil-fuels rows rest on a "Solar Energy - Construction of Generating Stations in Priority Preservation Areas" bill); "Redistricting" 0 in any bill title (the "Fair Districts for Maryland Act"); "Scholarship" 0 (the "Opting in on Opportunity Act"); "Voter" 0 and "Citizenship" 0 (the "SAVE Our Elections Act of 2026"). ⚠ THE LIMIT, STATED PLAINLY: that list covers the 2025 and 2026 sessions only, so absence is established for that window and NOT for 2023-2024 -- except for the SAVE Our Elections Act of 2026, which is dated inside it. 🔴 AND ONE CLAIM IS CONTRADICTED OUTRIGHT: the public-safety row says he is "opposing major police accountability reforms", while his own page lists him as a CO-SPONSOR of HB0508, "Public Safety - Police Accountability - Investigation Records Relating to Not Administratively Charged, Unfounded, and Exonerated Complaints". The bills that ARE his are real and have nothing to do with these chairs: optometry board revisions, physician and midwife parity, interference-of-custody penalties, and a Schedule III scheduling bill for medetomidine and xylazine. ⚠ ballotpedia.org/Steve_Johnson_(Maryland), the second source on the voting-rights row, returned a page on which every control term scored 0, including both party names; it was NOT READ and nothing is asserted about its contents in either direction. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01', 'https://ballotpedia.org/Steve_Johnson_(Maryland)']::text[]);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
VALUES
  -- Liz Ortega / civil-rights
  ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Liz Ortega / climate-change
  ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Liz Ortega / healthcare
  ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Liz Ortega / medicare/aid
  ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 0),
  -- Steve Bennett / climate-change
  ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Steve Bennett / fossil-fuels
  ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Steve Bennett / school-vouchers
  ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Steve Bennett / taxes
  ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Katy Yaroslavsky / trans-athletes
  ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid, 0),
  -- Katy Yaroslavsky / childcare
  ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Katy Yaroslavsky / healthcare
  ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Katy Yaroslavsky / civil-rights
  ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Eddie Morales / redistricting
  ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Elizabeth Campos / redistricting
  ('c1914284-9aee-44f4-8b7f-a833d8f392e7'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Steve Johnson / climate-change
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Steve Johnson / fossil-fuels
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 0),
  -- Steve Johnson / healthcare
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Steve Johnson / judicial-criminal-justice
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c334f475-05bd-48ba-9d25-f4de593a3f15'::uuid, 0),
  -- Steve Johnson / public-safety-approach
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 0),
  -- Steve Johnson / redistricting
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Steve Johnson / school-vouchers
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Steve Johnson / voting-rights
  ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0);

-- Liz Ortega / housing -- a Season 2 row already exists at 3; blank it IN PLACE.
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is State Senator Laura Richardson''s research filed under Assembly Member Liz Ortega. Both are California Democrats and both are rows in this database: Liz Ortega is an Assembly Member; Laura Richardson is a State Senator, and before that a member of the US House of Representatives and of the Long Beach City Council. The rows filed under Ortega credit her with AUTHORING Senate bills -- SB 510, SB 530, SB 535, SB 611, SB 748, SB 752, SB 767, SB 34 -- and with a "prior US House record" and service as a "prior Long Beach City Council member". 🔑 THE DECISIVE TEST NEEDS NO PAGE: Liz Ortega has never served in the US House and never sat on the Long Beach City Council. Laura Richardson did both, and THIS DATABASE''S OWN ROW FOR RICHARDSON ATTRIBUTES THE VERY SAME BILLS TO HER -- "Richardson authored SB 510 (2025)", "Richardson authored SB 530 (2025)", "Richardson authored SB 611 (2025)", "authored SB 752", "authored SB 767", "Richardson authored SB 34 (2025) on port emissions". The immigration row cites en.wikipedia.org/wiki/Laura_Richardson outright: control term "Richardson" 103 hits, "Ortega" 0, "Hayward" 0. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', sources = ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB611', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB748']::text[], updated_at = now()
 WHERE politician_id = '6730d01a-e87e-4177-9a2b-876b9c494774'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE politician_id = '6730d01a-e87e-4177-9a2b-876b9c494774'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

-- Katy Yaroslavsky / same-sex-marriage -- a Season 2 row already exists at 2; blank it IN PLACE.
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-07. 🔴 THE CHAIR RESTS ON A DIFFERENT PERSON''S RECORD. Katy Yaroslavsky is a Los Angeles City Council member; this chair is reached from the record of Sheila Kuehl, the former LA County Supervisor and state legislator she once worked for. The same-sex-marriage and trans-athletes rows cite en.wikipedia.org/wiki/Sheila_Kuehl as their ONLY source. The reasoning states the gap itself -- "No specific vote or statement on childcare policy was found", "No specific LA City Council votes on healthcare access were found", "No specific statement or vote by Yaroslavsky on transgender athletes was found" -- and then seats the chair on Kuehl anyway: "Her mentor Sheila Kuehl was a champion of childcare and early childhood programs", "her mentor Sheila Kuehl co-authored California''s first same-sex marriage bill in 2002", "Her background working for Kuehl -- who authored LGBTQ protections in California -- signals consistent support", "her background at Climate Action Reserve and working for Kuehl aligns with strengthening civil rights protections". 🔑 THIS IS INHERITANCE, NOT A MISFILING. The research did not confuse two people; it substituted a mentor''s positions for the subject''s, which is why no name-token, state or party probe can see it -- every name on the page is correct. WHOM SOMEONE WORKED FOR IS NOT A POSITION THEY HOLD. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.', sources = ARRAY['https://en.wikipedia.org/wiki/Sheila_Kuehl']::text[], updated_at = now()
 WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

DO $post$
DECLARE n integer;
BEGIN
  -- Every written key must now be a PAIRED Season 2 row at value 0.
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c USING (politician_id, topic_id, season_id)
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value = 0 AND (a.politician_id, a.topic_id) IN (
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('c1914284-9aee-44f4-8b7f-a833d8f392e7'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid)
  );
  IF n <> 24 THEN
    RAISE EXCEPTION 'migration 1897: expected 24 paired Season 2 blanks, found %', n;
  END IF;

  -- Nothing may be written for the three blocked keys.
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.compass_topics t ON t.id = a.topic_id
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND t.topic_key = 'immigration' AND a.politician_id IN (
    '6730d01a-e87e-4177-9a2b-876b9c494774'::uuid,
    '8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid,
    '10678016-146d-4543-941c-00414b4c4ad2'::uuid
  );
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1897: % rows written for the blocked immigration keys', n;
  END IF;

  -- Season 1 is immutable and must be untouched, asserted per row as a triple.
  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND (a.politician_id, a.topic_id, a.value) IN (
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
    ('c1914284-9aee-44f4-8b7f-a833d8f392e7'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 1),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 4)
  );
  IF n <> 24 THEN
    RAISE EXCEPTION 'migration 1897: Season 1 changed under us (24 expected, %)', n;
  END IF;

  -- No blank may ship with empty sources or empty reasoning (migration 1887's rule).
  SELECT count(*) INTO n FROM inform.politician_context c
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (c.politician_id, c.topic_id) IN (
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('c1914284-9aee-44f4-8b7f-a833d8f392e7'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('dbb1c600-c87b-449c-bd3b-1c236287c00f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid)
  )
     AND (coalesce(array_length(c.sources, 1), 0) = 0 OR btrim(coalesce(c.reasoning, '')) = '');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1897: % rows written with empty sources or empty reasoning', n;
  END IF;
END
$post$;
