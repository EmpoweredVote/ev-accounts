-- Migration 1932 — seed two `local-immigration` chairs that migration 1930 left without a home.
--
-- WHAT THIS IS. Migration 1930 blanked three deportation chairs seated on sanctuary instruments,
-- on the ground that a sanctuary instrument governs WHAT A CITY DOES WITH ITS OWN RESOURCES and
-- not WHO SHOULD BE DEPORTED. Eunisses Hernandez already holds the on-axis row — the separate
-- `local-immigration` ladder, where migration 1921 seated her at chair 1 and called the same
-- ordinance "squarely on-axis". HUGO SOTO-MARTINEZ AND ADENA ISHII HAD NO SUCH ROW AT ALL, so for
-- them the blank left real, verified evidence with nowhere on-axis to sit. 1930's ledger logged
-- that as a gap to seed. This seeds it.
--
-- ⚖⚖ A SEED IS A BIGGER CLAIM THAN A BLANK, AND IS HELD TO A HIGHER BAR. Blanking needs only a
-- showing that the evidence does not reach the chair. Seating asserts affirmatively that this
-- person holds this stance. Both rows below were therefore built from PRIMARY DOCUMENTS READ IN
-- FULL — the enacted ordinance text in each city, plus a primary record of the person's own act —
-- and not from the news summaries that describe them. The relevant rule here is the standing one:
-- read the enacted text, never seat from a title or a press paraphrase. 🔴 That rule has teeth in
-- this very chain: press coverage of the Los Angeles ordinance described its LAPD clause as a
-- carve-out LETTING police contact ICE about violent felons. The enacted text (Sec. 19.191(b))
-- does the opposite — it REQUIRES approval from a department immigrant affairs liaison before such
-- an arrest or transfer. A restriction, reported as a permission.
--
-- THE LADDER (`local-immigration`, "How should your community's law enforcement relate to federal
-- immigration enforcement?"). Chair 1 has TWO limbs and both must be evidenced:
--   "Refuse all ICE detainers; prohibit local employees from sharing immigration status
--    information with federal agencies"
-- Chair 3, the nearest weaker neighbour, reads "Follow federal law as required but do not use
-- local resources for proactive immigration enforcement" — it carries NEITHER limb, which is what
-- separates it from chair 1 and why the enacted text had to be read rather than assumed.
--
-- ── HUGO SOTO-MARTINEZ (Los Angeles City Council) → chair 1 ────────────────────────────────────
-- HIS OWN ACT, from the primary record: Los Angeles council file 23-0243 lists him as a Mover, and
-- the originating motion of 06/09/2023 is recorded as "Motion (Soto-Martinez - Rodriguez)". That
-- file produced ORDINANCE NO. 188441, adding Chapter 19 to Division 19 of the Administrative Code,
-- effective 12-19-24.
-- WHAT THE ENACTED TEXT DOES, quoted from the ordinance:
--   · Sec. 19.191(c) — no City resources shall be used to "Respond to any administrative warrant or
--     other request to detain, transfer, or notify any Immigration Agent about the status or
--     release of any individual for the purpose of Immigration Enforcement."  → LIMB 1. An ICE
--     detainer is precisely an administrative request to detain, and Sec. 19.193 preserves only
--     JUDICIAL warrants, which are not detainers.
--   · Sec. 19.192 — "no City personnel shall provide access to any City data or information that
--     can be used to determine or trace a person's Citizenship or Immigration Status to any
--     Immigration Agent."  → LIMB 2.
-- Both limbs of chair 1 are in the enacted text, so chair 3 is too weak and chair 1 is right.
--
-- ── ADENA ISHII (Mayor of Berkeley) → chair 1 ──────────────────────────────────────────────────
-- ⚠ A UNANIMOUS VOTE ALONE WOULD NOT HAVE CARRIED THIS ROW. Ordinance No. 7,984-N.S. passed 9-0
-- with none absent, and a lopsided vote is weak evidence of an individual's position — the rule
-- that blanked Newhouse on 385-41. The chair does NOT rest on the tally.
-- HER OWN ACT, from the primary record: the City Attorney's report to Council of 2025-09-09
-- (Item 25, "Proposed Sanctuary City Ordinance - Council Referral") states that "In January 2025,
-- the Mayor convened a Sanctuary City Task Force that recommended codifying these sanctuary
-- policies in an ordinance", and that the City Attorney "consulted with the Mayor, City Manager,
-- and members of the Task Force for direction on desired policy outcomes." Ishii took office in
-- December 2024, so the Mayor who convened it is her. The ordinance exists because of that body.
-- She is then recorded in the Ayes on 2025-09-09.
-- WHAT THE ENACTED TEXT DOES, quoted from Ordinance No. 7,984-N.S. (BMC Chapter 13.114):
--   · 13.114.030(C)(5) — prohibits "Complying with any civil immigration warrant or request to
--     detain, transfer, or notify any federal authority about the release of any individual."
--     → LIMB 1.
--   · 13.114.030(C)(4) — prohibits "Disseminating or disclosing Protected Personal Information to
--     Immigration Authorities in connection with Immigration Enforcement without a valid judicial
--     warrant or subpoena issued by a court of competent jurisdiction." → LIMB 2.
-- Both limbs again. ⚠ The 13.114.050 exceptions (individual consent, necessity to provide a City
-- service, or where required by state/federal law including 8 U.S.C. 1373) do not reopen either
-- limb: none of them permits honouring a civil detainer.
--
-- ADMISSIBILITY. `inform.compass_topic_roles` marks local-immigration/local as
-- evidence_basis = 'record'. Both rows rest on a record — a moved motion and an enacted ordinance
-- for Soto-Martinez, a convened task force, an enacted ordinance and a recorded vote for Ishii —
-- so neither needs the 'own-words' basis that this topic does not grant. Guard 3 checks this.
--
-- ⚠ WHAT THIS DOES NOT DO. It does not restore the deportation chairs migration 1930 withdrew;
-- those remain blank because that ladder asks a different question. Hernandez's existing
-- local-immigration row is untouched.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1932_seeds (
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  value         numeric NOT NULL,
  reasoning     text NOT NULL,
  sources       text[] NOT NULL
);

INSERT INTO mig1932_seeds (politician_id, who, value, reasoning, sources) VALUES
(
  '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid,
  'Hugo Soto-Martinez',
  1,
  'Seated at chair 1 by migration 1932, on his own act and the enacted text of the ordinance it produced. HIS ACT: Los Angeles council file 23-0243 records him as a Mover, and the originating motion of 2023-06-09 is listed as "Motion (Soto-Martinez - Rodriguez)". That file produced Ordinance No. 188441, which added Chapter 19 to Division 19 of the Los Angeles Administrative Code, effective 2024-12-19. WHAT THE ENACTED ORDINANCE DOES, against this ladder''s chair 1 - "Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies": (1) Sec. 19.191(c) provides that no City resources shall be utilized to "Respond to any administrative warrant or other request to detain, transfer, or notify any Immigration Agent about the status or release of any individual for the purpose of Immigration Enforcement" - an ICE detainer is an administrative request to detain, and Sec. 19.193 preserves only JUDICIAL warrants, which are a different instrument; (2) Sec. 19.192 provides that "no City personnel shall provide access to any City data or information that can be used to determine or trace a person''s Citizenship or Immigration Status to any Immigration Agent". Both limbs of chair 1 are therefore in the enacted text. WHY NOT CHAIR 3: chair 3 reads "follow federal law as required but do not use local resources for proactive immigration enforcement" and carries neither the detainer refusal nor the data prohibition, so it understates what this ordinance enacts. ⚠ Press coverage described the ordinance''s LAPD clause as a carve-out permitting contact with ICE about violent felons; the enacted Sec. 19.191(b) does the reverse, requiring prior approval from a department immigrant affairs liaison. The text was read rather than the coverage. This row was seeded because migration 1930 withdrew his deportation chair, which rested on this same ordinance on a ladder that asks who should be deported - a question a city ordinance does not answer.',
  ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0243',
    'https://cityclerk.lacity.org/onlinedocs/2023/23-0243_ord_%20188441_12-19-24.pdf'
  ]
),
(
  '965de422-660e-4e24-9fe6-717cc0313403'::uuid,
  'Adena Ishii',
  1,
  'Seated at chair 1 by migration 1932, on her own act and the enacted text of the ordinance it produced. ⚠ NOT ON THE TALLY: Berkeley Ordinance No. 7,984-N.S. passed 9-0 with none absent, and a unanimous vote is weak evidence of an individual''s position. HER ACT: the City Attorney''s report to Council of 2025-09-09 (Item 25, "Proposed Sanctuary City Ordinance - Council Referral") records that "In January 2025, the Mayor convened a Sanctuary City Task Force that recommended codifying these sanctuary policies in an ordinance, in order to ensure the continuation of the City''s sanctuary status", and that the City Attorney''s Office "consulted with the Mayor, City Manager, and members of the Task Force for direction on desired policy outcomes." Ishii took office in December 2024, so the Mayor who convened that task force is her, and the ordinance exists on its recommendation. She is then recorded in the Ayes when the Council passed it to print on 2025-09-09. WHAT THE ENACTED ORDINANCE DOES, against this ladder''s chair 1 - "Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies": Berkeley Municipal Code Chapter 13.114 prohibits (1) at 13.114.030(C)(5) "Complying with any civil immigration warrant or request to detain, transfer, or notify any federal authority about the release of any individual", and (2) at 13.114.030(C)(4) "Disseminating or disclosing Protected Personal Information to Immigration Authorities in connection with Immigration Enforcement without a valid judicial warrant or subpoena issued by a court of competent jurisdiction". Both limbs of chair 1 are therefore in the enacted text. ⚠ The exceptions at 13.114.050 - individual consent, necessity to provide a City service, or where required by state or federal law including 8 U.S.C. 1373 - do not reopen either limb, since none of them permits honouring a civil detainer. WHY NOT CHAIR 3: chair 3 carries neither limb. This row was seeded because migration 1930 withdrew her deportation chair, which rested on sanctuary evidence on a ladder that asks who should be deported.',
  ARRAY[
    'https://berkeleyca.gov/sites/default/files/documents/2025-09-09%20Item%2025%20Proposed%20Sanctuary%20City%20Ordinance.pdf',
    'https://berkeleyca.gov/sites/default/files/documents/2025-09-30%20Item%2001%20Proposed%20Sanctuary%20City%20Ordinance%20%E2%80%93%20Council%20Referral.pdf'
  ]
);

-- Record the before-picture for a delta check that does not depend on the predicate.
CREATE TEMP TABLE mig1932_before AS
SELECT count(*) AS seated_season2
  FROM inform.politician_answers
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;

-- 🔴 SEASON 1 IS CLOSED. Both targets ALREADY HOLD Season 1 rows on this ladder, so "no Season 1
-- row exists" is not the test — the test is that this pass changes none of them. Snapshot, then
-- compare. (The first draft of this migration asserted the absence of Season 1 rows and failed its
-- own dry run on a pre-existing condition it had not caused.)
CREATE TEMP TABLE mig1932_season1_before AS
SELECT pa.politician_id, pa.value, pa.updated_at
  FROM inform.politician_answers pa
  JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
  JOIN mig1932_seeds s ON s.politician_id = pa.politician_id
 WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid;

-- ⚠⚠ FOUND WHILE WRITING THIS, RECORDED RATHER THAN FIXED: ADENA ISHII'S SEASON 1 ROW ON THIS
-- LADDER IS INVERTED. It sits at chair 5 — "Direct local police to actively assist with immigration
-- enforcement and support federal detention operations" — while its own stored reasoning says she
-- "reaffirmed Berkeley's sanctuary city status ... stating 'we will not be doing that' regarding
-- ICE assistance" and "led passage of a codified sanctuary ordinance in September 2025". The row
-- asserts the opposite of the evidence printed beneath it. It carries the SAME topic_revision_id as
-- the Season 2 ladder, so this is NOT a season-remap artifact — it is a chair inversion.
-- 🔴 SEASON 1 IS CLOSED AND THIS MIGRATION DOES NOT TOUCH IT. Logged for a pass that can.
-- 🔑 Note also that this independently corroborates the Season 2 seed below: a different research
-- pass, working separately, also recorded Ishii as having LED the ordinance.

-- GUARD 1 — exactly two seeds, and NEITHER MAY ALREADY EXIST. 🔴 This is the gate that makes the
-- pass an INSERT rather than a silent overwrite: if a row appeared since this was researched, the
-- migration refuses instead of clobbering someone else's adjudication.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1932_seeds;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1932: expected 2 seeds, found %', n; END IF;

  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN mig1932_seeds s ON s.politician_id = pa.politician_id
   WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % target(s) already hold a local-immigration row — this pass only seeds absent rows', n; END IF;

  SELECT count(*) INTO n
    FROM inform.politician_context pc
    JOIN mig1932_seeds s ON s.politician_id = pc.politician_id
   WHERE pc.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % target(s) already hold a local-immigration context row', n; END IF;
END $$;

-- GUARD 2 — the topic must actually be asked in this season, and the people must exist.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND topic_id  = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1932: local-immigration is not a Season 2 question; seeding it would create an answer to a question nobody asked'; END IF;

  SELECT count(*) INTO n FROM mig1932_seeds s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = s.politician_id);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % seed(s) name a politician that does not exist', n; END IF;

  -- The chair being seated must be a real rung on this ladder.
  SELECT count(*) INTO n FROM mig1932_seeds s
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.compass_stances cs
      WHERE cs.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND cs.value = s.value);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % seed(s) name a rung that does not exist on this ladder', n; END IF;
END $$;

-- GUARD 3 — 🔴 ADMISSIBILITY. local-immigration/local is evidence_basis 'record'. Both rows rest on
-- a record, so this is satisfied — but if the basis ever changed, the reasoning written below would
-- be making a claim the table no longer licenses, so it is checked rather than assumed.
DO $$
DECLARE basis text;
BEGIN
  SELECT r.evidence_basis INTO basis
    FROM inform.compass_topic_roles r
   WHERE r.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND r.role_scope = 'local';
  IF basis IS DISTINCT FROM 'record' THEN
    RAISE EXCEPTION 'migration 1932: local-immigration/local evidence_basis is %, not the record basis these rows were judged against', coalesce(basis, 'missing');
  END IF;
END $$;

-- GUARD 4 — every seed must cite primary documents, and must name its instrument. A seed with a
-- bare or aggregator citation is the defect this whole campaign exists to remove.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1932_seeds WHERE coalesce(cardinality(sources), 0) < 2;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % seed(s) cite fewer than two sources', n; END IF;

  -- No bare domains: every citation must carry a path.
  SELECT count(*) INTO n FROM mig1932_seeds s, unnest(s.sources) u
   WHERE u !~ '^https://[^/]+/.+';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % citation(s) are not https URLs with a path', n; END IF;

  -- No aggregators standing in for the record.
  SELECT count(*) INTO n FROM mig1932_seeds s, unnest(s.sources) u
   WHERE u ~* '(wikipedia|ballotpedia)\.org';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % citation(s) are aggregator pages, not the record', n; END IF;

  -- The reasoning must quote the ladder's own chair-1 limbs, which is what the read established.
  SELECT count(*) INTO n FROM mig1932_seeds
   WHERE reasoning !~* 'detain' OR reasoning !~* 'Citizenship or Immigration Status|Protected Personal Information';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % seed(s) do not evidence both limbs of chair 1', n; END IF;
END $$;

-- ── THE WRITE ──────────────────────────────────────────────────────────────────────────────────

-- Context first: a seated answer without reasoning is the ANSWER_WITHOUT_CONTEXT defect, so the
-- row a reader checks must exist before the number a reader sees.
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT s.politician_id,
       'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid,
       'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid,
       s.reasoning,
       s.sources
  FROM mig1932_seeds s;

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT s.politician_id,
       'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid,
       'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid,
       s.value
  FROM mig1932_seeds s;

-- ── VERIFY THE RESULT, NOT THE ABSENCE OF AN ERROR ────────────────────────────────────────────

DO $$
DECLARE n int; before_seated int; after_seated int;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN mig1932_seeds s ON s.politician_id = pa.politician_id AND s.value = pa.value
   WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1932: expected 2 seated rows at the adjudicated chair, found %', n; END IF;

  -- Every new answer has reasoning and citations a reader can check.
  SELECT count(*) INTO n
    FROM mig1932_seeds s
    JOIN inform.politician_answers pa
      ON pa.politician_id = s.politician_id
     AND pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
        AND pc.season_id = pa.season_id
        AND length(pc.reasoning) > 0
        AND coalesce(cardinality(pc.sources), 0) >= 2);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % seeded answer(s) lack reasoning or citations', n; END IF;

  -- Exactly one row per pair; a duplicate would double-count the person in every rollup.
  SELECT count(*) INTO n FROM (
    SELECT pa.politician_id
      FROM inform.politician_answers pa
      JOIN mig1932_seeds s ON s.politician_id = pa.politician_id
     WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
       AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     GROUP BY pa.politician_id HAVING count(*) > 1) d;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % target(s) now hold duplicate rows', n; END IF;

  -- 🔴 BLAST RADIUS, as a delta: exactly two MORE seated Season 2 rows, nothing else moved.
  SELECT seated_season2 INTO before_seated FROM mig1932_before;
  SELECT count(*) INTO after_seated
    FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;
  IF after_seated - before_seated <> 2 THEN
    RAISE EXCEPTION 'migration 1932: seated Season 2 rows rose by %, expected exactly 2', after_seated - before_seated;
  END IF;

  -- 🔴 The deportation chairs migration 1930 withdrew must STAY withdrawn. This pass gives the
  -- evidence an on-axis home; it does not quietly restore the off-axis one.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
   WHERE pa.topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.politician_id IN ('965de422-660e-4e24-9fe6-717cc0313403'::uuid,
                              '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid,
                              '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid)
     AND pa.value <> 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % deportation chair(s) blanked by migration 1930 are seated again', n; END IF;

  -- Hernandez's existing local-immigration row must be untouched.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
   WHERE pa.politician_id = '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid
     AND pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.value = 1;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1932: Hernandez/local-immigration no longer sits at chair 1'; END IF;

  -- 🔴 Season 1 is closed and must not have MOVED — proved against the snapshot, not by asserting
  -- that no Season 1 row exists. Both targets already had one; that is the pre-existing state this
  -- pass is obliged to leave exactly as it found it, inversion and all.
  SELECT count(*) INTO n
    FROM mig1932_season1_before b
    JOIN inform.politician_answers pa
      ON pa.politician_id = b.politician_id
     AND pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
    JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
   WHERE pa.value IS DISTINCT FROM b.value OR pa.updated_at IS DISTINCT FROM b.updated_at;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1932: % Season 1 row(s) moved', n; END IF;

  -- And no NEW Season 1 row may appear: the count must be exactly what it was.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
    JOIN mig1932_seeds s ON s.politician_id = pa.politician_id
   WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid;
  IF n <> (SELECT count(*) FROM mig1932_season1_before) THEN
    RAISE EXCEPTION 'migration 1932: the number of Season 1 rows on this ladder changed';
  END IF;
END $$;

-- Final shape, for the apply log.
SELECT s.who, pa.value AS chair, cardinality(pc.sources) AS n_sources
  FROM mig1932_seeds s
  JOIN inform.politician_answers pa
    ON pa.politician_id = s.politician_id
   AND pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
 ORDER BY s.who;
