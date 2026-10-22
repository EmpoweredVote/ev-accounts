-- Migration 1934 — seed `local-immigration` chairs for the three Berkeley sanctuary sponsors who
-- have no Season 2 row.
--
-- WHAT THIS IS. Migration 1932 seated Adena Ishii and Hugo Soto-Martinez on the enacted sanctuary
-- ordinance text of their cities. The Season 1 inversion scan that followed
-- (`chair-inversion-scan.mjs`, recorded in this pass's LEDGER §8) surfaced a Berkeley cohort around
-- the same instruments. This seeds the remaining sponsors: CECILIA LUNAPARRA, BRENT BLACKABY and
-- TERRY TAPLIN, all at chair 1, none of whom holds a Season 2 row on this ladder.
--
-- ⚖⚖ A SEED IS A BIGGER CLAIM THAN A BLANK. Every sponsorship below was read from a PRIMARY CITY
-- RECORD. 🔴 THAT WAS NOT A FORMALITY: the Season 1 corpus asserts that Shoshana O'Keefe
-- "co-sponsored the second reading of Berkeley's Sanctuary City Contracting Ordinance". SHE DID
-- NOT. She appears on no sponsor line of any of the three instruments; her only record is an Aye on
-- measures that passed unanimously. Had the Season 1 reasoning been inherited rather than checked,
-- this migration would have seated a chair on a sponsorship that does not exist. O'KeefE IS
-- THEREFORE NOT SEEDED.
--
-- ⚠ AND THAT IS THE SAME BAR MIGRATION 1932 SET: a unanimous vote does not seat a chair. Berkeley's
-- sanctuary measures passed 9-0 and 8-0, so an Aye on them is weak evidence of any individual's
-- position — the rule that blanked Newhouse on 385-41. Every row below rests on AUTHORSHIP or
-- NAMED CO-SPONSORSHIP, never on a tally.
--
-- THE THREE INSTRUMENTS AND THEIR SPONSOR LINES, quoted from the city's own records:
--   (A) 2025-01-21, Item 27, Resolution Reaffirming Berkeley As a Sanctuary City —
--       "Councilmember Blackaby (Author), Mayor Ishii (Co-Sponsor), Councilmember Lunaparra
--        (Co-Sponsor), Councilmember Taplin (Co-Sponsor)"
--   (B) 2025-04-15, Item 12, Referral to City Attorney for Sanctuary City Ordinance —
--       "Mayor Adena Ishii (Author), Councilmember Brent Blackaby (Co-Sponsor), Councilmember
--        Cecilia Lunaparra (Co-Sponsor), Councilmember Terry Taplin (Co-Sponsor)"
--   (C) 2025-12-02, Item 3, Sanctuary City Contracting Ordinance Updates (Ord. 7,994-N.S.) —
--       "Councilmember Lunaparra (Author), Mayor Ishii (Co-Sponsor), Councilmember Humbert
--        (Co-Sponsor), Councilmember Blackaby (Co-Sponsor)"
--
--   Lunaparra  — author of (C), co-sponsor of (A) and (B).  three instruments
--   Blackaby   — author of (A), co-sponsor of (B) and (C).  three instruments
--   Taplin     — co-sponsor of (A) and (B).                  two instruments
--
-- ⚠ Humbert co-sponsored only (C) and is NOT seeded here: one instrument is thinner evidence than
-- the bar this campaign has been applying, and a seed is the claim that must clear the bar.
--
-- WHY CHAIR 1, from the enacted text rather than from the word "sanctuary". The ladder asks "How
-- should your community's law enforcement relate to federal immigration enforcement?" and chair 1
-- has TWO limbs: "Refuse all ICE detainers; prohibit local employees from sharing immigration
-- status information with federal agencies". Chair 3 — "follow federal law as required but do not
-- use local resources for proactive immigration enforcement" — carries NEITHER, which is what
-- separates them. Berkeley Ordinance No. 7,984-N.S. (BMC Chapter 13.114), which (A) and (B) set in
-- motion, enacts both:
--   · 13.114.030(C)(5) prohibits "Complying with any civil immigration warrant or request to
--     detain, transfer, or notify any federal authority about the release of any individual."
--   · 13.114.030(C)(4) prohibits "Disseminating or disclosing Protected Personal Information to
--     Immigration Authorities in connection with Immigration Enforcement without a valid judicial
--     warrant or subpoena issued by a court of competent jurisdiction."
-- The 13.114.050 exceptions (consent, necessity to provide a City service, or where required by
-- state or federal law including 8 U.S.C. 1373) do not reopen either limb: none permits honouring a
-- civil detainer.
--
-- ADMISSIBILITY. `inform.compass_topic_roles` marks local-immigration/local as evidence_basis
-- 'record'. Authorship and co-sponsorship recorded on a city agenda are records. Guard 3 checks it.
--
-- ⚠ SEASON 1 IS CLOSED AND IS NOT TOUCHED, including where it is wrong. Lunaparra's Season 1 row on
-- this ladder sits at chair 5 — "direct local police to actively assist with immigration
-- enforcement" — which is the inversion LEDGER §8 documents. Blackaby's and Taplin's Season 1 rows
-- are already at chair 1. 🔑 THAT MIX IS ITSELF THE FINDING: the Season 1 defect is NOT a uniform
-- Berkeley mis-seed, it is an INCONSISTENT one, three of a cohort inverted while two colleagues on
-- the same instruments were seated correctly.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1934_seeds (
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  value         numeric NOT NULL,
  reasoning     text NOT NULL,
  sources       text[] NOT NULL
);

INSERT INTO mig1934_seeds (politician_id, who, value, reasoning, sources) VALUES
(
  '116aace8-9440-498b-bf1d-ebb196727c85'::uuid,
  'Cecilia Lunaparra',
  1,
  'Seated at chair 1 by migration 1934, on her own sponsorship of Berkeley''s sanctuary instruments and the enacted text they produced. HER ACTS, from the city''s own records: she is the AUTHOR of the Sanctuary City Contracting Ordinance Updates, Ordinance No. 7,994-N.S. - the Council agenda of 2025-12-02 lists Item 3 as "Councilmember Lunaparra (Author), Mayor Ishii (Co-Sponsor), Councilmember Humbert (Co-Sponsor), Councilmember Blackaby (Co-Sponsor)"; she is a CO-SPONSOR of the Resolution Reaffirming Berkeley As a Sanctuary City of 2025-01-21 (Item 27, "Councilmember Blackaby (Author), Mayor Ishii (Co-Sponsor), Councilmember Lunaparra (Co-Sponsor), Councilmember Taplin (Co-Sponsor)"); and a CO-SPONSOR of the 2025-04-15 Referral to City Attorney for a Sanctuary City Ordinance (Item 12). Three instruments, one of them authored. WHAT THE RESULTING ORDINANCE DOES, against this ladder''s chair 1 - "Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies": Berkeley Municipal Code Chapter 13.114, adopted as Ordinance No. 7,984-N.S., prohibits at 13.114.030(C)(5) "Complying with any civil immigration warrant or request to detain, transfer, or notify any federal authority about the release of any individual", and at 13.114.030(C)(4) "Disseminating or disclosing Protected Personal Information to Immigration Authorities in connection with Immigration Enforcement without a valid judicial warrant or subpoena issued by a court of competent jurisdiction". Both limbs of chair 1 are in the enacted text; chair 3 carries neither. ⚠ The 13.114.050 exceptions - consent, necessity to provide a City service, or where required by state or federal law including 8 U.S.C. 1373 - do not reopen either limb. ⚠ This chair does NOT rest on a vote: Berkeley''s sanctuary measures passed unanimously, and a unanimous vote is weak evidence of an individual''s position. It rests on the sponsorship lines above.',
  ARRAY[
    'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025',
    'https://berkeleyca.gov/sites/default/files/documents/2025-04-15%20Item%2012%20Referral%20to%20City%20Attorney%20for%20Sanctuary%20City%20Ordinance.pdf',
    'https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-12-02%20Annotated%20Agenda%20-%20Council.pdf',
    'https://berkeleyca.gov/sites/default/files/documents/2025-09-30%20Item%2001%20Proposed%20Sanctuary%20City%20Ordinance%20%E2%80%93%20Council%20Referral.pdf'
  ]
),
(
  '424eb63b-9976-4059-8049-365c09719cc6'::uuid,
  'Brent Blackaby',
  1,
  'Seated at chair 1 by migration 1934, on his own sponsorship of Berkeley''s sanctuary instruments and the enacted text they produced. HIS ACTS, from the city''s own records: he is the AUTHOR of the Resolution Reaffirming Berkeley As a Sanctuary City, adopted 2025-01-21 - the Council agenda lists Item 27 as "Councilmember Blackaby (Author), Mayor Ishii (Co-Sponsor), Councilmember Lunaparra (Co-Sponsor), Councilmember Taplin (Co-Sponsor)"; he is a CO-SPONSOR of the 2025-04-15 Referral to City Attorney for a Sanctuary City Ordinance, whose sponsor line reads "Mayor Adena Ishii (Author), Councilmember Brent Blackaby (Co-Sponsor), Councilmember Cecilia Lunaparra (Co-Sponsor), Councilmember Terry Taplin (Co-Sponsor)"; and a CO-SPONSOR of the Sanctuary City Contracting Ordinance Updates, Ordinance No. 7,994-N.S. (agenda of 2025-12-02, Item 3). Three instruments, one of them authored - and the resolution he authored is the one that set the codification in motion. WHAT THE RESULTING ORDINANCE DOES, against this ladder''s chair 1 - "Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies": Berkeley Municipal Code Chapter 13.114, adopted as Ordinance No. 7,984-N.S., prohibits at 13.114.030(C)(5) "Complying with any civil immigration warrant or request to detain, transfer, or notify any federal authority about the release of any individual", and at 13.114.030(C)(4) "Disseminating or disclosing Protected Personal Information to Immigration Authorities in connection with Immigration Enforcement without a valid judicial warrant or subpoena issued by a court of competent jurisdiction". Both limbs of chair 1 are in the enacted text; chair 3 carries neither. ⚠ This chair does NOT rest on a vote: Berkeley''s sanctuary measures passed unanimously, and a unanimous vote is weak evidence of an individual''s position. It rests on the sponsorship lines above.',
  ARRAY[
    'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025',
    'https://berkeleyca.gov/sites/default/files/documents/2025-04-15%20Item%2012%20Referral%20to%20City%20Attorney%20for%20Sanctuary%20City%20Ordinance.pdf',
    'https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-12-02%20Annotated%20Agenda%20-%20Council.pdf',
    'https://berkeleyca.gov/sites/default/files/documents/2025-09-30%20Item%2001%20Proposed%20Sanctuary%20City%20Ordinance%20%E2%80%93%20Council%20Referral.pdf'
  ]
),
(
  'bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid,
  'Terry Taplin',
  1,
  'Seated at chair 1 by migration 1934, on his own sponsorship of Berkeley''s sanctuary instruments and the enacted text they produced. HIS ACTS, from the city''s own records: he is a CO-SPONSOR of the Resolution Reaffirming Berkeley As a Sanctuary City, adopted 2025-01-21 - the Council agenda lists Item 27 as "Councilmember Blackaby (Author), Mayor Ishii (Co-Sponsor), Councilmember Lunaparra (Co-Sponsor), Councilmember Taplin (Co-Sponsor)" - and a CO-SPONSOR of the 2025-04-15 Referral to City Attorney for a Sanctuary City Ordinance, whose sponsor line reads "Mayor Adena Ishii (Author), Councilmember Brent Blackaby (Co-Sponsor), Councilmember Cecilia Lunaparra (Co-Sponsor), Councilmember Terry Taplin (Co-Sponsor)". ⚠ TWO INSTRUMENTS, BOTH CO-SPONSORED RATHER THAN AUTHORED - a thinner record than his co-sponsors Lunaparra and Blackaby, each of whom authored one of these instruments, and the reader should weigh it accordingly. It is still sponsorship of the two measures that produced the ordinance, not a vote on them. WHAT THE RESULTING ORDINANCE DOES, against this ladder''s chair 1 - "Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies": Berkeley Municipal Code Chapter 13.114, adopted as Ordinance No. 7,984-N.S., prohibits at 13.114.030(C)(5) "Complying with any civil immigration warrant or request to detain, transfer, or notify any federal authority about the release of any individual", and at 13.114.030(C)(4) "Disseminating or disclosing Protected Personal Information to Immigration Authorities in connection with Immigration Enforcement without a valid judicial warrant or subpoena issued by a court of competent jurisdiction". Both limbs of chair 1 are in the enacted text; chair 3 carries neither. ⚠ This chair does NOT rest on a vote: Berkeley''s sanctuary measures passed unanimously, and a unanimous vote is weak evidence of an individual''s position.',
  ARRAY[
    'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025',
    'https://berkeleyca.gov/sites/default/files/documents/2025-04-15%20Item%2012%20Referral%20to%20City%20Attorney%20for%20Sanctuary%20City%20Ordinance.pdf',
    'https://berkeleyca.gov/sites/default/files/documents/2025-09-30%20Item%2001%20Proposed%20Sanctuary%20City%20Ordinance%20%E2%80%93%20Council%20Referral.pdf'
  ]
);

-- Record the before-picture for a delta check that does not depend on the predicate.
CREATE TEMP TABLE mig1934_before AS
SELECT count(*) AS seated_season2
  FROM inform.politician_answers
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;

-- 🔴 SEASON 1 IS CLOSED. All three already hold Season 1 rows on this ladder (Lunaparra at the
-- inverted chair 5, Blackaby and Taplin correctly at chair 1), so "no Season 1 row exists" is NOT
-- the test — the test is that this pass changes none of them. Snapshot, then compare.
CREATE TEMP TABLE mig1934_season1_before AS
SELECT pa.politician_id, pa.value, pa.updated_at
  FROM inform.politician_answers pa
  JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
  JOIN mig1934_seeds s ON s.politician_id = pa.politician_id
 WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid;

-- GUARD 1 — exactly three seeds, and NONE may already exist. This makes the pass an INSERT rather
-- than a silent overwrite of someone else's adjudication.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1934_seeds;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1934: expected 3 seeds, found %', n; END IF;

  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id FROM mig1934_seeds) d;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1934: duplicate politician in the seed set'; END IF;

  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN mig1934_seeds s ON s.politician_id = pa.politician_id
   WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % target(s) already hold a Season 2 row on this ladder', n; END IF;

  SELECT count(*) INTO n
    FROM inform.politician_context pc
    JOIN mig1934_seeds s ON s.politician_id = pc.politician_id
   WHERE pc.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % target(s) already hold a Season 2 context row', n; END IF;
END $$;

-- GUARD 2 — the topic must be asked in this season, the people must exist, and the chair must be a
-- real rung. 🔴 The seed set must also be the OFFICEHOLDER records, not the identically-named
-- Cal-Access committee filers ("LUNAPARRA FOR BERKELEY CITY COUNCIL 2024; CECILIA" and friends),
-- which is a live hazard in this database.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND topic_id  = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1934: local-immigration is not a Season 2 question'; END IF;

  SELECT count(*) INTO n FROM mig1934_seeds s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = s.politician_id);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % seed(s) name a politician that does not exist', n; END IF;

  SELECT count(*) INTO n FROM mig1934_seeds s
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.compass_stances cs
      WHERE cs.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND cs.value = s.value);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % seed(s) name a rung that does not exist', n; END IF;

  -- A committee filer record carries no Season 1 stance row; the officeholder does. This is the
  -- cheap discriminator, and it also proves we picked the same person the inversion scan read.
  SELECT count(*) INTO n FROM mig1934_seeds s
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_answers pa
      JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
      WHERE pa.politician_id = s.politician_id
        AND pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % seed(s) have no Season 1 row on this ladder — likely a committee filer record, not the officeholder', n; END IF;

  SELECT count(*) INTO n FROM mig1934_seeds s
   JOIN essentials.politicians p ON p.id = s.politician_id
   WHERE p.full_name <> s.who;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % seed(s) do not match the stored full_name', n; END IF;
END $$;

-- GUARD 3 — 🔴 ADMISSIBILITY. local-immigration/local is evidence_basis 'record'; sponsorship
-- recorded on a city agenda is a record. Checked rather than assumed.
DO $$
DECLARE basis text;
BEGIN
  SELECT r.evidence_basis INTO basis
    FROM inform.compass_topic_roles r
   WHERE r.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND r.role_scope = 'local';
  IF basis IS DISTINCT FROM 'record' THEN
    RAISE EXCEPTION 'migration 1934: local-immigration/local evidence_basis is %, not the record basis these rows were judged against', coalesce(basis, 'missing');
  END IF;
END $$;

-- GUARD 4 — every seed must cite primary city documents, name its instrument, and say what the
-- enacted text does. 🔑 And it must record a SPONSORSHIP, because the whole point of this pass is
-- that a unanimous vote does not seat a chair.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1934_seeds WHERE coalesce(cardinality(sources), 0) < 3;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % seed(s) cite fewer than three sources', n; END IF;

  SELECT count(*) INTO n FROM mig1934_seeds s, unnest(s.sources) u
   WHERE u !~ '^https://[^/]+/.+';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % citation(s) are not https URLs with a path', n; END IF;

  SELECT count(*) INTO n FROM mig1934_seeds s, unnest(s.sources) u
   WHERE u !~* '^https://berkeleyca\.gov/';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % citation(s) are not City of Berkeley records', n; END IF;

  SELECT count(*) INTO n FROM mig1934_seeds
   WHERE reasoning !~* '(Author|Co-Sponsor)';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % seed(s) record no sponsorship — a unanimous vote does not seat a chair', n; END IF;

  SELECT count(*) INTO n FROM mig1934_seeds
   WHERE reasoning !~* 'detain' OR reasoning !~* 'Protected Personal Information';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % seed(s) do not evidence both limbs of chair 1', n; END IF;
END $$;

-- ── THE WRITE ──────────────────────────────────────────────────────────────────────────────────

-- Context first: a seated answer without reasoning is the ANSWER_WITHOUT_CONTEXT defect, so the row
-- a reader checks exists before the number a reader sees.
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT s.politician_id,
       'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid,
       'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid,
       s.reasoning,
       s.sources
  FROM mig1934_seeds s;

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT s.politician_id,
       'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid,
       'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid,
       s.value
  FROM mig1934_seeds s;

-- ── VERIFY THE RESULT, NOT THE ABSENCE OF AN ERROR ────────────────────────────────────────────

DO $$
DECLARE n int; before_seated int; after_seated int;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN mig1934_seeds s ON s.politician_id = pa.politician_id AND s.value = pa.value
   WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1934: expected 3 seated rows at the adjudicated chair, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1934_seeds s
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = s.politician_id
        AND pc.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
        AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND length(pc.reasoning) > 0
        AND coalesce(cardinality(pc.sources), 0) >= 3);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % seeded answer(s) lack reasoning or citations', n; END IF;

  SELECT count(*) INTO n FROM (
    SELECT pa.politician_id
      FROM inform.politician_answers pa
      JOIN mig1934_seeds s ON s.politician_id = pa.politician_id
     WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
       AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     GROUP BY pa.politician_id HAVING count(*) > 1) d;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % target(s) now hold duplicate rows', n; END IF;

  -- 🔴 BLAST RADIUS, as a delta: exactly three MORE seated Season 2 rows, nothing else moved.
  SELECT seated_season2 INTO before_seated FROM mig1934_before;
  SELECT count(*) INTO after_seated
    FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;
  IF after_seated - before_seated <> 3 THEN
    RAISE EXCEPTION 'migration 1934: seated Season 2 rows rose by %, expected exactly 3', after_seated - before_seated;
  END IF;

  -- 🔴 Season 1 must not have MOVED — proved against the snapshot, including Lunaparra's inverted
  -- chair 5, which this pass deliberately leaves exactly as it found it.
  SELECT count(*) INTO n
    FROM mig1934_season1_before b
    JOIN inform.politician_answers pa
      ON pa.politician_id = b.politician_id
     AND pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
    JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
   WHERE pa.value IS DISTINCT FROM b.value OR pa.updated_at IS DISTINCT FROM b.updated_at;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % Season 1 row(s) moved', n; END IF;

  -- The rows migrations 1932 and 1930 settled must be unchanged.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
   WHERE pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pa.politician_id IN ('965de422-660e-4e24-9fe6-717cc0313403'::uuid,   -- Ishii
                              '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid,   -- Soto-Martinez
                              '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid)   -- Hernandez
     AND pa.value <> 1;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1934: % row(s) seated by migrations 1921/1932 moved off chair 1', n; END IF;
END $$;

-- Final shape, for the apply log.
SELECT s.who, pa.value AS chair, cardinality(pc.sources) AS n_sources
  FROM mig1934_seeds s
  JOIN inform.politician_answers pa
    ON pa.politician_id = s.politician_id
   AND pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
 ORDER BY s.who;
