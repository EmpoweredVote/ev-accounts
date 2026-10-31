-- Migration 1947 — the Massachusetts Safe Communities Act on the local-immigration ladder.
--
-- 72 serving rows name this Act. **69 are written: 41 re-seated, 28 withdrawn.** 3 are left alone
-- because they carry an instrument of the member's own.
--
--   rows  shape                                            decision                      written
--   ----  -----------------------------------------------  ----------------------------  -------
--     41  the member CO-SPONSORED the Act                   re-seat from chairs 1/2 to 3       41
--     27  the member did NOT co-sponsor it                  withdraw                           27
--      1  a US Representative who cannot co-sponsor it      withdraw                            1
--      3  the member has a bill of their OWN                left alone                          0
--
-- 66 of the writes INSERT a Season 2 row because the row serves from the closed Season 1; 3 UPDATE
-- a row that already serves from Season 2. Season 1 is untouched and the post-flight block proves
-- it. local-immigration pins ONE revision across both seasons, so every row written here is read
-- against the very ladder its reasoning was researched against.
--
-- 🔑 WHY THIS LADDER AND NOT `immigration`. Season 1's `immigration` question was split for Season 2
-- because it was trying to do too much - its chairs each carried two limbs, legal-immigration
-- levels AND public-service eligibility. `local-immigration` is one of the successors and it asks a
-- single question: what local law enforcement should do. Season 1's `immigration` has no Season 2
-- question at all, so its 1,666 valued answers cannot be shadowed by an insert and are not
-- repairable by the technique these passes use. This file works the successor, which is.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- A. THE ACT WAS READ, AND IT DOES NOT SAY WHAT THE ROWS SAY IT SAYS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- H.2288 / S.1510 of the 193rd General Court, "An Act to protect the civil rights and safety of all
-- Massachusetts residents". The ladder:
--     c1 Refuse all ICE detainers; prohibit local employees from sharing immigration status
--        information with federal agencies
--     c2 Comply only with court-ordered detainers; protect undocumented crime victims and witnesses
--        from referral
--     c3 Follow federal law as required but do not use local resources for proactive immigration
--        enforcement
--
-- 🔴 CHAIR 1 IS NEGATED BY THE ACT'S OWN TEXT. Section 2(e): "nothing in this section shall prohibit
-- or restrain any state or local agency from sending to, or receiving from, any local, state, or
-- federal agency, information regarding citizenship or immigration status." That clause exists
-- because 8 U.S.C. 1373 forbids a State from barring such sharing - so chair 1's second limb is
-- something no Massachusetts statute could deliver. The Act never uses the word "detainer" either,
-- so its first limb is unevidenced as well. 39 rows were nevertheless seated there.
--
-- CHAIR 2 fails on its spine: complying only with COURT-ORDERED detainers is a framing the Act does
-- not use. Its second limb does match - section 2(b) bars questioning "persons, including victims
-- and witnesses of crimes, about their immigration status" - but a matching limb is not a matching
-- chair.
--
-- CHAIR 3 matches BOTH limbs. Section 3: no officer of the department of corrections, state police,
-- a sheriff's department or a city or town police department "shall perform the functions of an
-- immigration officer, whether pursuant to 8 U.S.C. section 1357(g)", and inconsistent agreements
-- in existence are void - that is exactly "do not use local resources for proactive immigration
-- enforcement". And section 2(e), with the exceptions for where "state or federal law requires the
-- inquiry", is exactly "follow federal law as required". The Act is a chair 3 instrument.
--
-- ⚖ This is the same test migration 1943 used on the Climate Solutions Now Act: one chair whose
-- spine the statute matches, the others failing on the statute's own text.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- B. 🔴🔴 28 ROWS SEAT A POSITION ON NOT HAVING SIGNED SOMETHING
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- This is the larger defect, and it was not what the contradiction check flagged. 27 rows in this
-- cohort hold a chair on the member's ABSENCE from the Act's co-sponsor list, read off an advocacy
-- organisation's tracker, with the direction supplied by party:
--     "Did not co-sponsor Safe Communities Act (red X on AOM) ... Middle position - not limiting
--      cooperation but not mandating it."                                              -> chair 3
--     "Zero co-sponsorships including Safe Communities Act. Republican caucus member with no
--      local-immigration legislation. Consistent with honoring ICE detainers ..."      -> chair 4
--     "As a Republican Assistant Minority Leader, Durant likely supports honoring ICE detainers
--      and sharing immigration status information proactively ..."                     -> chair 4
--     "Her failure to support this bill - unlike many Cambridge-area ..."              -> chair 3
-- A Democrat who did not sign was placed at chair 3 as a "middle position"; a Republican who did
-- not sign at chair 4. That is an algorithm over a tracker and a party column, not research.
--
-- NOT SIGNING A BILL IS NOT A POSITION. It is equally consistent with disagreeing with the bill,
-- agreeing and not signing, never having been asked, and holding no view at all, and nothing in
-- these rows chooses between those. All 27 are blanked.
--
-- ⚠ THE 28TH is a United States Representative, who cannot co-sponsor a Massachusetts bill at all.
-- What her row holds is direction and demographics - "has consistently backed local non-cooperation
-- with ICE detainer requests", "defended Massachusetts' Safe Communities Act", a record "driven by
-- her district's significant immigrant popula[tion]" - with no vote, bill or statement of her own
-- named. She cannot be re-seated on the Act's chair because the Act is not her instrument.
--
-- ⚖ THREE ROWS ARE LEFT ALONE because each carries an affirmative instrument of the member's own,
-- which is exactly what the other 27 lack: H.2009 (directing local compliance with ICE detainers),
-- H.2573 ("An Act to enhance public safety", requiring mandatory local cooperation with ICE), and
-- H.2575 (regulating law-enforcement federal immigration agreements without prohibiting them).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- C. ⚠ A CITATION POINTING AT THE WRONG SESSION'S BILL
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Two rows cite malegislature.gov/Bills/194/H2288. In the 194th General Court H.2288 is "An Act
-- relative to MBTA communities", a housing and zoning bill. The Safe Communities Act of the 194th
-- is H.2580 / S.1681; H.2288 was its number in the 193rd. The rows' PROSE is right - "H.2288 /
-- S.1510" are the 193rd's numbers - and the URL is wrong by one session.
--
-- This is the third cross-session collision found in three passes: California "SB 42" merged the
-- 2025-26 Fair Elections Act with the 2023-24 CARE Court Act (migration 1945), Texas bill numbers
-- recur across the 85th, 87th, 88th and 89th legislatures, and now this. The check's keys scope a
-- numeric bill by its legislature but NOT by its session, and `MA:H2288` merges a sanctuary bill
-- with a housing bill. Recorded; it belongs in the checker, not in a migration.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE TARGETS, FROZEN. Two shapes, because the rows live in two places.
--   mig1947_ins  serving from the CLOSED Season 1 (ADR 0005 section 1.6), so a Season 2 row is
--                INSERTed. local-immigration pins ONE revision across both seasons, so that row is
--                read against the very ladder the reasoning was researched against.
--   mig1947_upd  already serving from the OPEN Season 2, so updated in place.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE mig1947_ins ON COMMIT DROP AS
SELECT x.politician_id, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AS topic_id, x.op, x.value_after,
       sq.topic_revision_id AS s2_revision,
       pa1.value AS value_before, pa1.topic_revision_id AS s1_revision,
       pa1.updated_at AS s1_updated_at,
       pc1.reasoning AS reasoning_before, pc1.sources AS sources_before
  FROM (VALUES
  ('78ae3786-e71e-4dc4-8b84-0ab28b555632'::uuid,'sca-chair3',3),  -- Adam Gómez: was chair 1
  ('19b7c45b-57a7-468c-9762-82b926080646'::uuid,'sca-chair3',3),  -- Andres X. Vargas: was chair 1
  ('5c497509-7a9d-492b-ac35-ff37f8fcfb82'::uuid,'sca-chair3',3),  -- Brandy Fluker-Reid: was chair 1
  ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid,'sca-chair3',3),  -- Brendan P. Crighton: was chair 1
  ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab'::uuid,'sca-chair3',3),  -- Carlos González: was chair 1
  ('a9ea7006-d595-45aa-a301-9c71d5a3af4d'::uuid,'sca-chair3',3),  -- Carmine L. Gentile: was chair 1
  ('ca6d9c06-e613-46a1-b938-0d89d488b583'::uuid,'sca-chair3',3),  -- Daniel F. Cahill: was chair 1
  ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a'::uuid,'sca-chair3',3),  -- Danillo Sena: was chair 1
  ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid,'sca-chair3',3),  -- David A. LeBoeuf: was chair 1
  ('ffb8e526-7ad7-4911-92c5-d69528a0f280'::uuid,'sca-chair3',3),  -- David M. Rogers: was chair 1
  ('fa6beaf8-acfe-4365-82a2-6f282aa1b688'::uuid,'sca-chair3',3),  -- David P. Linsky: was chair 1
  ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid,'sca-chair3',3),  -- Dylan A. Fernandes: was chair 1
  ('98291d86-d42d-49d0-a5b2-d689a8154b15'::uuid,'sca-chair3',3),  -- Erika Uyterhoeven: was chair 1
  ('5729a0a4-40a9-41bd-82a4-9a0bea757567'::uuid,'sca-chair3',3),  -- Frank A. Moran: was chair 1
  ('04a9edee-5d51-49f3-a2c9-585e2231bd08'::uuid,'sca-chair3',3),  -- Jack P. Lewis: was chair 1
  ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5'::uuid,'sca-chair3',3),  -- Jacob R. Oliveira: was chair 1
  ('9ed1b75f-a314-4241-87ff-231de4aba963'::uuid,'sca-chair3',3),  -- James B. Eldridge: was chair 1
  ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid,'sca-chair3',3),  -- James K. Hawkins: was chair 1
  ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid,'sca-chair3',3),  -- Jason M. Lewis: was chair 1
  ('961506eb-3f00-4358-a9a3-1730e7004474'::uuid,'sca-chair3',3),  -- Joanne M. Comerford: was chair 1
  ('bd451748-111f-461d-9752-95e7c243769e'::uuid,'sca-chair3',3),  -- Julian A. Cyr: was chair 1
  ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd'::uuid,'sca-chair3',3),  -- Lindsay Sabadosa: was chair 1
  ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid,'sca-chair3',3),  -- Liz Miranda: was chair 1
  ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid,'sca-chair3',3),  -- Lydia M. Edwards: was chair 1
  ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90'::uuid,'sca-chair3',3),  -- Michael J. Barrett: was chair 1
  ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92'::uuid,'sca-chair3',3),  -- Mike Connolly: was chair 1
  ('ecafa801-15b3-4777-9c38-95f5ded5cbe6'::uuid,'sca-chair3',3),  -- Mindy Domb: was chair 1
  ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid,'sca-chair3',3),  -- Patricia D. Jehlen: was chair 1
  ('756f9e6b-5286-4a9e-9d05-f6341830bd12'::uuid,'sca-chair3',3),  -- Pavel M. Payano: was chair 1
  ('b7369e32-1916-413e-b0eb-2871a5348470'::uuid,'sca-chair3',3),  -- Rebecca L. Rausch: was chair 1
  ('e96b35eb-dad1-4a29-b416-d9b10838840f'::uuid,'sca-chair3',3),  -- Russell E. Holmes: was chair 1
  ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd'::uuid,'sca-chair3',3),  -- Sean Garballey: was chair 1
  ('918296a2-5def-4ddf-8986-860d542900e7'::uuid,'sca-chair3',3),  -- Simon Cataldo: was chair 1
  ('1d78debb-efd5-45e8-9204-06aab3076b2a'::uuid,'sca-chair3',3),  -- Steven C. Owens: was chair 1
  ('c947719a-cd1a-497a-8fc9-d9c4d434b18f'::uuid,'sca-chair3',3),  -- Vanna Howard: was chair 1
  ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid,'sca-chair3',3),  -- William N. Brownsberger: was chair 1
  ('b96758c6-2ea0-4698-8886-d574d34e366d'::uuid,'trahan-blank',0),  -- Lori Trahan: was chair 2
  ('2ada2d01-a77a-44f6-a569-916d9639fbdc'::uuid,'sca-chair3',3),  -- Priscila S. Sousa: was chair 2
  ('c70bd1f2-6ba2-446e-a40c-d07f446db214'::uuid,'sca-chair3',3),  -- Thomas M. Stanley: was chair 2
  ('e2daa3aa-02b6-4a4d-859b-fb75f674625b'::uuid,'sca-absence-blank',0),  -- Aaron L. Saunders: was chair 3
  ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2'::uuid,'sca-absence-blank',0),  -- Adam J. Scanlon: was chair 3
  ('a646d95b-7341-4181-a25b-87b5abcf0a6c'::uuid,'sca-absence-blank',0),  -- Alan Silvia: was chair 3
  ('ac853e6e-d419-4d05-b89c-77d11bb68fb2'::uuid,'sca-absence-blank',0),  -- Alice H. Peisch: was chair 3
  ('7cbdb829-4836-49e9-afb2-cb8035afc6bf'::uuid,'sca-absence-blank',0),  -- Christine P. Barber: was chair 3
  ('9cb46542-a671-4bdd-bfcb-98fc1bc79415'::uuid,'sca-absence-blank',0),  -- Christopher Hendricks: was chair 3
  ('2270da0d-09e7-40b4-858f-fe25bc822916'::uuid,'sca-absence-blank',0),  -- Christopher M. Markey: was chair 3
  ('516feaaa-7086-4382-8cfa-9463f508dd74'::uuid,'sca-absence-blank',0),  -- Christopher R. Flanagan: was chair 3
  ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2'::uuid,'sca-absence-blank',0),  -- Colleen M. Garry: was chair 3
  ('248f76d7-e76a-49e5-88b7-dc43a3131329'::uuid,'sca-absence-blank',0),  -- Cynthia F. Friedman: was chair 3
  ('b46a6774-2d85-4750-813a-6d4ef2eefb5b'::uuid,'sca-absence-blank',0),  -- Cynthia S. Creem: was chair 3
  ('8e125ae2-3101-49b1-b228-f172ad9c70d9'::uuid,'sca-absence-blank',0),  -- Estela A. Reyes: was chair 3
  ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid,'sca-absence-blank',0),  -- Francisco E. Paulino: was chair 3
  ('6148f954-b8cc-4204-96ca-34f2afc1d24a'::uuid,'sca-absence-blank',0),  -- Jennifer Balinsky Armini: was chair 3
  ('ef888471-24a9-4a9f-9115-e530c16986ae'::uuid,'sca-absence-blank',0),  -- John J. Cronin: was chair 3
  ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10'::uuid,'sca-absence-blank',0),  -- Marjorie C. Decker: was chair 3
  ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid,'sca-absence-blank',0),  -- Michael D. Brady: was chair 3
  ('62764b2a-5b54-4edb-9c69-06320cbebbad'::uuid,'sca-absence-blank',0),  -- Michael F. Rush: was chair 3
  ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid,'sca-absence-blank',0),  -- Michael J. Moran: was chair 3
  ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid,'sca-absence-blank',0),  -- Michael J. Rodrigues: was chair 3
  ('c0b79f82-6ce7-413a-a18a-286c9a8fa5fd'::uuid,'sca-absence-blank',0),  -- Michael O. Moore: was chair 3
  ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid,'sca-absence-blank',0),  -- Paul R. Feeney: was chair 3
  ('f530be83-6f1b-4b04-a8c4-3a83dc35099f'::uuid,'sca-absence-blank',0),  -- Paul W. Mark: was chair 3
  ('44ca0b25-e4b9-4409-8407-f5119568be3e'::uuid,'sca-absence-blank',0),  -- Donald H. Wong: was chair 4
  ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid,'sca-absence-blank',0),  -- Donald R. Berthiaume: was chair 4
  ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid,'sca-absence-blank',0),  -- Patrick M. O'Connor: was chair 4
  ('82943cda-5803-46c7-a854-697ad6052eda'::uuid,'sca-absence-blank',0)  -- Peter J. Durant: was chair 4
  ) AS x(politician_id, op, value_after)
  JOIN inform.politician_answers pa1
    ON pa1.politician_id = x.politician_id AND pa1.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND pa1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.politician_context pc1
    ON pc1.politician_id = x.politician_id AND pc1.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND pc1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.season_questions sq
    ON sq.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

CREATE TEMP TABLE mig1947_upd ON COMMIT DROP AS
SELECT x.politician_id, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AS topic_id, x.op, x.value_after,
       pa2.value AS value_before, pa2.topic_revision_id AS s2_revision,
       pc2.reasoning AS reasoning_before, pc2.sources AS sources_before
  FROM (VALUES
  ('290ee018-6e9e-4a8c-9561-385cf5ef3d73'::uuid,'sca-chair3',3),  -- Adrian C. Madaro: was chair 1
  ('c4c3ed02-2592-4505-a26c-0195d0b5314e'::uuid,'sca-chair3',3),  -- Judith A. Garcia: was chair 1
  ('fc1d7143-1be8-49b0-be31-6dbc5874230d'::uuid,'sca-chair3',3)  -- Tram T. Nguyen: was chair 1
  ) AS x(politician_id, op, value_after)
  JOIN inform.politician_answers pa2
    ON pa2.politician_id = x.politician_id AND pa2.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND pa2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
  JOIN inform.politician_context pc2
    ON pc2.politician_id = x.politician_id AND pc2.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND pc2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- GUARD 1 — the target sets must be exactly what was read.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1947_ins;
  IF n <> 66 THEN RAISE EXCEPTION 'migration 1947: expected 66 insert targets, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1947_upd;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1947: expected 3 update targets, found %', n; END IF;
  SELECT (SELECT count(*) FROM mig1947_ins WHERE op = 'sca-chair3') + (SELECT count(*) FROM mig1947_upd WHERE op = 'sca-chair3') INTO n;
  IF n <> 41 THEN RAISE EXCEPTION 'migration 1947: sca-chair3 expected 41, found %', n; END IF;
  SELECT (SELECT count(*) FROM mig1947_ins WHERE op = 'trahan-blank') + (SELECT count(*) FROM mig1947_upd WHERE op = 'trahan-blank') INTO n;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1947: trahan-blank expected 1, found %', n; END IF;
  SELECT (SELECT count(*) FROM mig1947_ins WHERE op = 'sca-absence-blank') + (SELECT count(*) FROM mig1947_upd WHERE op = 'sca-absence-blank') INTO n;
  IF n <> 27 THEN RAISE EXCEPTION 'migration 1947: sca-absence-blank expected 27, found %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT politician_id FROM mig1947_ins UNION SELECT politician_id FROM mig1947_upd) s;
  IF n <> 69 THEN RAISE EXCEPTION 'migration 1947: duplicate people; % distinct of 69', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT reasoning_before, sources_before FROM mig1947_ins
    UNION ALL SELECT reasoning_before, sources_before FROM mig1947_upd) s
   WHERE reasoning_before IS NULL OR btrim(reasoning_before) = '' OR sources_before IS NULL OR cardinality(sources_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % target(s) have no reasoning or citation to keep', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT reasoning_before FROM mig1947_ins UNION ALL SELECT reasoning_before FROM mig1947_upd) s
   WHERE reasoning_before LIKE '%migration 1947%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % target(s) already carry a 1947 notice', n; END IF;
END $$;

-- GUARD 2 — every target must still sit where it was read, and every row must name the Act.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (
    SELECT op, value_before FROM mig1947_ins UNION ALL SELECT op, value_before FROM mig1947_upd) s
   WHERE (op = 'sca-chair3'        AND value_before NOT IN (1,2))
      OR (op = 'sca-absence-blank' AND value_before NOT IN (3,4))
      OR (op = 'trahan-blank'      AND value_before <> 2);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT reasoning_before FROM mig1947_ins UNION ALL SELECT reasoning_before FROM mig1947_upd) s
   WHERE reasoning_before !~* 'safe communities act';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % row(s) do not name the Safe Communities Act', n; END IF;
  -- the withdrawn-for-absence rows must really say the member did NOT sign it
  SELECT count(*) INTO n FROM mig1947_ins
   WHERE op = 'sca-absence-blank'
     AND reasoning_before !~* '(did not co-?spons|zero co-?sponsorship|failure to support|absence of co-?sponsorship|not a co-?sponsor)';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % absence row(s) do not actually rest on an absence', n; END IF;
  -- and the re-seated rows must really say the member DID sign it
  SELECT count(*) INTO n FROM (
    SELECT op, reasoning_before FROM mig1947_ins UNION ALL SELECT op, reasoning_before FROM mig1947_upd) s
   WHERE op = 'sca-chair3' AND reasoning_before !~* '(co-?sponsor|cosponsor|signed on|is a sponsor)';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % re-seated row(s) do not claim a co-sponsorship', n; END IF;
END $$;

-- GUARD 3 — THE LADDER. local-immigration pins ONE revision across both seasons, and the rung TEXTS
-- are asserted because this file turns on the exact wording of chairs 1, 2 and 3.
DO $$
DECLARE n int; t text;
BEGIN
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status = 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1947: Season 2 is not the open season'; END IF;
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND status <> 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1947: Season 1 is not closed'; END IF;
  SELECT count(*) INTO n FROM inform.season_questions a
    JOIN inform.season_questions b ON b.topic_id = a.topic_id
   WHERE a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND b.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND a.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND a.topic_revision_id = b.topic_revision_id
     AND a.topic_revision_id = 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1947: local-immigration no longer pins one revision across both seasons'; END IF;

  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'prohibit local employees from sharing immigration status information'
    THEN RAISE EXCEPTION 'migration 1947: chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'court-ordered detainers' THEN RAISE EXCEPTION 'migration 1947: chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid AND value = 3;
  IF t IS NULL OR t !~* 'do not use local resources for proactive immigration enforcement'
    THEN RAISE EXCEPTION 'migration 1947: chair 3 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'd497a221-1616-4ebf-8405-f9c851083e2c'::uuid AND value = 4;
  IF t IS NULL OR t !~* 'honor ice detainers' THEN RAISE EXCEPTION 'migration 1947: chair 4 does not read as recorded: %', t; END IF;
END $$;

-- GUARD 4 — the two shapes must not blur, and nobody here may be inactive.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1947_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers pa
                  WHERE pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % insert target(s) ALREADY have a Season 2 answer', n; END IF;
  SELECT count(*) INTO n FROM mig1947_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_context pc
                  WHERE pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % insert target(s) ALREADY have a Season 2 context row', n; END IF;
  SELECT count(*) INTO n FROM mig1947_upd u
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = u.politician_id AND pa.topic_id = u.topic_id AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % update target(s) have no Season 1 record behind them', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT politician_id FROM mig1947_ins UNION SELECT politician_id FROM mig1947_upd) s
    JOIN essentials.politicians p ON p.id = s.politician_id WHERE NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % target(s) are on inactive people', n; END IF;
END $$;

-- GUARD 5 — POPULATIONS, NOT JUST TARGETS. Every serving row on this ladder whose reasoning names
-- the Safe Communities Act must be accounted for: a target here, or one of the three rows left
-- alone because they carry an instrument of the member's OWN (H.2009, H.2573, H.2575).
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (
    SELECT DISTINCT ON (pa.politician_id) pa.politician_id, pa.season_id, pa.value, pc.reasoning
      FROM inform.politician_answers pa
      JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
      JOIN essentials.politicians p ON p.id = pa.politician_id
     WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND p.is_active
       AND pa.season_id <> '7b3a066c-815d-43b2-a6a0-6a3029778075'::uuid
     ORDER BY pa.politician_id, (pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid) DESC) s
   WHERE s.value <> 0 AND s.reasoning ~* 'safe communities act';
  IF n <> 72 THEN RAISE EXCEPTION 'migration 1947: expected 72 serving rows naming the Act, found % — re-read before writing', n; END IF;

  SELECT count(*) INTO n FROM (
    SELECT DISTINCT ON (pa.politician_id) pa.politician_id, pa.value, pc.reasoning
      FROM inform.politician_answers pa
      JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
      JOIN essentials.politicians p ON p.id = pa.politician_id
     WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND p.is_active
       AND pa.season_id <> '7b3a066c-815d-43b2-a6a0-6a3029778075'::uuid
     ORDER BY pa.politician_id, (pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid) DESC) s
   WHERE s.value <> 0 AND s.reasoning ~* 'safe communities act' AND s.reasoning !~ 'H\.? ?(2009|2573|2575)'
     AND NOT EXISTS (SELECT 1 FROM mig1947_ins i WHERE i.politician_id = s.politician_id)
     AND NOT EXISTS (SELECT 1 FROM mig1947_upd u WHERE u.politician_id = s.politician_id);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % row(s) naming the Act are neither targets nor left alone for their own bill', n; END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE WRITE. The Season 2 reasoning is the notice followed by the ORIGINAL prose, verbatim.
-- Sources are carried across byte for byte; this file re-reads evidence, it never re-cites it.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision, i.value_after FROM mig1947_ins i;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision,
       CASE i.op
         WHEN 'sca-chair3' THEN '[migration 1947, 2026-10-26] Re-seated to chair 3. This row rests on co-sponsoring the Massachusetts Safe Communities Act (H.2288 / S.1510 in the 193rd General Court, "An Act to protect the civil rights and safety of all Massachusetts residents"). The Act was read, not its reputation. Chair 1 requires BOTH refusing all ICE detainers AND prohibiting local employees from sharing immigration status information with federal agencies - and the Act EXPRESSLY PRESERVES that sharing: section 2(e) provides that "nothing in this section shall prohibit or restrain any state or local agency from sending to, or receiving from, any local, state, or federal agency, information regarding citizenship or immigration status". The Act never uses the word "detainer" either. Chair 2 turns on complying only with court-ordered detainers, a framing the Act does not use. What the Act actually does is section 3: no officer "shall perform the functions of an immigration officer, whether pursuant to 8 U.S.C. section 1357(g)", voiding existing agreements - no local resources for proactive immigration enforcement - while section 2(e) and the "when state or federal law requires" exceptions follow federal law as required. Both limbs of chair 3. Original reasoning kept verbatim below.

'
         WHEN 'trahan-blank' THEN '[migration 1947, 2026-10-26] Withdrawn. This row sits in the Safe Communities Act cohort but its member is a United States Representative, who cannot co-sponsor a Massachusetts bill. What is left is direction and demographics - "has consistently backed local non-cooperation with ICE detainer requests", "defended Massachusetts'' Safe Communities Act", and a record "driven by her district''s significant immigrant popula[tion]" - with no vote, bill or statement of her own named. Direction is not a rung, and a district is not a position. The Act cannot seat her at its own chair because it is not her instrument. Original reasoning kept verbatim below.

'
         WHEN 'sca-absence-blank' THEN '[migration 1947, 2026-10-26] Withdrawn. This row seats a voter-facing position on the member NOT having co-sponsored the Safe Communities Act, read off an advocacy organisation''s co-sponsorship tracker - "did not co-sponsor (red X on AOM)", "zero co-sponsorships" - with the direction supplied by party: a Democrat who did not sign was placed at chair 3 as a "middle position", a Republican who did not sign at chair 4 as "likely supports honoring ICE detainers". Not signing a bill is not a position. It is consistent with disagreeing with it, with agreeing and not signing, with never having been asked, and with holding no view at all, and nothing in these rows chooses between those. A blank withdraws a claim nobody established; it does not assert that the person holds no view. Every citation is kept, so the row can be seated the moment an instrument of the member''s own is found. Original reasoning kept verbatim below.

'
       END || i.reasoning_before,
       i.sources_before
  FROM mig1947_ins i;

UPDATE inform.politician_answers pa
   SET value = u.value_after
  FROM mig1947_upd u
 WHERE pa.politician_id = u.politician_id AND pa.topic_id = u.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

UPDATE inform.politician_context pc
   SET reasoning = CASE u.op
         WHEN 'sca-chair3' THEN '[migration 1947, 2026-10-26] Re-seated to chair 3. This row rests on co-sponsoring the Massachusetts Safe Communities Act (H.2288 / S.1510 in the 193rd General Court, "An Act to protect the civil rights and safety of all Massachusetts residents"). The Act was read, not its reputation. Chair 1 requires BOTH refusing all ICE detainers AND prohibiting local employees from sharing immigration status information with federal agencies - and the Act EXPRESSLY PRESERVES that sharing: section 2(e) provides that "nothing in this section shall prohibit or restrain any state or local agency from sending to, or receiving from, any local, state, or federal agency, information regarding citizenship or immigration status". The Act never uses the word "detainer" either. Chair 2 turns on complying only with court-ordered detainers, a framing the Act does not use. What the Act actually does is section 3: no officer "shall perform the functions of an immigration officer, whether pursuant to 8 U.S.C. section 1357(g)", voiding existing agreements - no local resources for proactive immigration enforcement - while section 2(e) and the "when state or federal law requires" exceptions follow federal law as required. Both limbs of chair 3. Original reasoning kept verbatim below.

'
         WHEN 'trahan-blank' THEN '[migration 1947, 2026-10-26] Withdrawn. This row sits in the Safe Communities Act cohort but its member is a United States Representative, who cannot co-sponsor a Massachusetts bill. What is left is direction and demographics - "has consistently backed local non-cooperation with ICE detainer requests", "defended Massachusetts'' Safe Communities Act", and a record "driven by her district''s significant immigrant popula[tion]" - with no vote, bill or statement of her own named. Direction is not a rung, and a district is not a position. The Act cannot seat her at its own chair because it is not her instrument. Original reasoning kept verbatim below.

'
         WHEN 'sca-absence-blank' THEN '[migration 1947, 2026-10-26] Withdrawn. This row seats a voter-facing position on the member NOT having co-sponsored the Safe Communities Act, read off an advocacy organisation''s co-sponsorship tracker - "did not co-sponsor (red X on AOM)", "zero co-sponsorships" - with the direction supplied by party: a Democrat who did not sign was placed at chair 3 as a "middle position", a Republican who did not sign at chair 4 as "likely supports honoring ICE detainers". Not signing a bill is not a position. It is consistent with disagreeing with it, with agreeing and not signing, with never having been asked, and with holding no view at all, and nothing in these rows chooses between those. A blank withdraws a claim nobody established; it does not assert that the person holds no view. Every citation is kept, so the row can be seated the moment an instrument of the member''s own is found. Original reasoning kept verbatim below.

'
       END || u.reasoning_before
  FROM mig1947_upd u
 WHERE pc.politician_id = u.politician_id AND pc.topic_id = u.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-FLIGHT. Same transaction, so a failure here rolls the whole file back.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1947_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = i.value_after AND pa.topic_revision_id = i.s2_revision;
  IF n <> 66 THEN RAISE EXCEPTION 'migration 1947: % of 66 inserted answers are at their chair', n; END IF;
  SELECT count(*) INTO n FROM mig1947_upd u
    JOIN inform.politician_answers pa
      ON pa.politician_id = u.politician_id AND pa.topic_id = u.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = u.value_after;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1947: % of 3 updated answers are at their chair', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_answers pa
   WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = 3
     AND EXISTS (SELECT 1 FROM mig1947_ins i WHERE i.politician_id = pa.politician_id AND i.op = 'sca-chair3');
  IF n <> 38 THEN RAISE EXCEPTION 'migration 1947: wrong number of re-seated inserts at chair 3: %', n; END IF;

  -- the kept prose and the untouched citations
  SELECT count(*) INTO n FROM mig1947_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM i.sources_before OR strpos(pc.reasoning, i.reasoning_before) = 0
      OR pc.reasoning NOT LIKE '%migration 1947%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % inserted context row(s) lost prose, citations or notice', n; END IF;
  SELECT count(*) INTO n FROM mig1947_upd u
    JOIN inform.politician_context pc
      ON pc.politician_id = u.politician_id AND pc.topic_id = u.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM u.sources_before OR strpos(pc.reasoning, u.reasoning_before) = 0
      OR pc.reasoning NOT LIKE '%migration 1947%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % updated context row(s) lost prose, citations or notice', n; END IF;

  -- 🔴 SEASON 1 IS CLOSED. Not one value, not one word, not one updated_at may move.
  SELECT count(*) INTO n FROM mig1947_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pa.value <> i.value_before OR pa.updated_at IS DISTINCT FROM i.s1_updated_at
      OR pa.topic_revision_id <> i.s1_revision;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % Season 1 answer(s) MOVED — the closed season was written to', n; END IF;
  SELECT count(*) INTO n FROM mig1947_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pc.reasoning IS DISTINCT FROM i.reasoning_before OR pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1947: % Season 1 context row(s) were rewritten', n; END IF;

  -- the three rows left alone for their own bill are still where they were
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
   WHERE pa.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND pa.value <> 0
     AND pc.reasoning ~* 'safe communities act' AND pc.reasoning ~ 'H\.? ?(2009|2573|2575)';
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1947: the 3 rows left alone for their own bill moved; found %', n; END IF;
END $$;

COMMIT;
