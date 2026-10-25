-- Migration 1931 — the re-research of the 131. Re-seat 10 on instruments the members AUTHORED.
--
-- WHAT THIS IS. Migration 1926 blanked 165 direction-only chairs; migration 1928 re-read them and
-- re-seated 34 where the cited roll call already stated the rung. 131 remained, needing something
-- the existing evidence could not give: a NEW instrument. This pass went and looked for one.
--
-- METHOD, and why it is not the same as 1928. 1928 re-read evidence already in the row. This pass
-- fetched each member's own AUTHORED and COAUTHORED bill list from capitol.texas.gov — four
-- sessions, 86R through 89R — and matched captions against the topics the member has a blank row
-- on. Authorship is a deliberate act of association and is distinctive whatever a final margin was;
-- that is why it can seat a rung where a vote could not.
--
-- ⚖⚖ THE YIELD IS LOW AND THAT IS THE FINDING: 10 of 131. Across 20 verified members, ~7,000 bill
-- captions were scanned. For most of these members the topics they are blank on are topics they
-- have never legislated on — they voted and did not file. ▶ The remaining 121 rows cannot be
-- rescued from the Texas record; they need the member's own words, and most of these (topic, level)
-- pairs are evidence_basis 'record'.
--
-- 🔴🔴 A TRAP THAT WOULD HAVE CORRUPTED THIS PASS, RECORDED BECAUSE IT NEARLY DID.
-- The member codes stored in our own rows are not reliable. Of 26 taken from the cited
-- `capitol.texas.gov/Members/MemberInfo` URLs, SIX do not resolve to the right person: five return
-- HTTP 500 on the member page and one (A1390, recorded for Ramon Romero Jr.) resolves to
-- **Sen. Taylor Rehmet**, a different human being. And the authored-bills report for a bad code
-- does NOT error — it returns a clean page reading "No bills have been authored."
--   ▶ A WRONG IDENTIFIER PRODUCES A PLAUSIBLE EMPTY RESULT, INDISTINGUISHABLE FROM A MEMBER WHO
--     FILED NOTHING. Five members were silently reported as having no record at all.
-- The control that caught it: resolve every code to a NAME and compare it to the person expected.
-- ⚠ And the control had its own false positive — "Terri Leo-Wilson" vs the site's "Terri Leo
-- Wilson" failed a last-name match that was mine, not the data's. Printing the resolved name
-- rather than a boolean is what made both visible.
-- 🔑 A FAILED CODE IS NOT AN ABSENCE OF EVIDENCE. Rhetta Bowers' code is one of the six that did
-- not resolve, and she turns out to be the PRIMARY AUTHOR of the enacted CROWN Act — found by
-- reading the bill rather than her member page. She is re-seated below.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- CIVIL RIGHTS -> 2  (9 rows). The CROWN Act.
-- ─────────────────────────────────────────────────────────────────────────────
-- Rung 2 reads "strengthen civil rights enforcement and ADDRESS SYSTEMIC DISCRIMINATION". The
-- instrument is 88(R) HB 567 — "Relating to discrimination on the basis of hair texture or
-- protective hairstyle associated with race" — primary author Rhetta Bowers, ENACTED, effective
-- 1 September 2023; and its predecessor 87(R) HB 392, the same text. Adding a protected
-- characteristic to the state's anti-discrimination law extends civil rights enforcement, which is
-- rung 2's own clause. Rung 1 requires mandating "racial equity requirements in all institutions",
-- which the Act does not do. Rung 3 is "MAINTAIN current civil rights laws", and the Act changes
-- them. ⚖ This is authorship or coauthorship, not a vote, so the near-unanimity rule that governs
-- roll calls does not apply: filing one's name to a bill is a distinctive act.
-- ⚠ Three of the nine carry more than the CROWN Act and are noted in their own rows: Toni Rose
-- (sexual-orientation and gender-identity discrimination, housing discrimination on criminal
-- history), Nicole Collier (housing discrimination, sex discrimination in employment compensation)
-- and John Bryant (employment discrimination on sexual orientation or gender identity).
--
-- ─────────────────────────────────────────────────────────────────────────────
-- CLIMATE CHANGE -> 5  (1 row). Terry Wilson, 87(R) HB 4470.
-- ─────────────────────────────────────────────────────────────────────────────
-- Rung 5 reads "END GOVERNMENT SUBSIDIES AND MANDATES FOR CLEAN ENERGY." The instrument, authored
-- by him, is "Relating to imposing a tax on the amount of federal renewable energy production
-- credits received by wind electric generators" — a state tax recapturing a clean-energy subsidy,
-- which is rung 5's subject exactly. Rung 4 is "stay neutral on energy and let the market choose
-- among all sources", and a tax aimed at one source is the opposite of neutral. ⚠ HONEST ABOUT
-- OUTCOME: the bill did not pass — referred to Ways & Means 29 March 2021 and left there.
-- Sponsorship evidences the bill as filed, which is what a position is.
--
-- ⚠ WHAT THE SEARCH REFUSED, so the bar is visible:
--  · Walle's and Martinez's abortion rows: their filings are POSTPARTUM Medicaid and fertility
--    reporting, not abortion. Off axis.
--  · Bryant's abortion rows: he authored HB 3000 repealing abortion prohibitions, which reaches
--    rung 1's "legal and accessible at all stages" but says nothing about rung 1's PUBLIC FUNDING
--    limb. Blank, consistent with the identical refusal in migration 1923.
--  · Bryant's, Longoria's and Flores' healthcare rows: Medicaid expansion again. Expansion proves
--    a floor, never a ceiling — the rule migration 1928 set.
--  · Collier's redistricting row: she authored HB 3052 (apportionment BASE, off axis) and HB 3054
--    ("principles to govern redistricting plans enacted by the legislature"), which accepts the
--    legislature as the drawer but names neither rung 3's supermajority nor rung 4's court
--    oversight. Cannot separate them.
--  · Toth's and Leo-Wilson's civil-rights rows: their "discrimination" bills concern financial
--    institutions, industries and vaccination status, not the axis this ladder asks about.
--  · Every taxes row: property-tax relief delivered THROUGH school finance cuts taxes without
--    scaling back services, so it matches neither rung 3 nor rung 4.
--
-- Applied by hand via psql; no migration runner exists in this repo. Guards below fail the whole
-- transaction rather than write a partial result.

CREATE TEMP TABLE mig1931_targets (
  politician_id uuid NOT NULL,
  topic_id      uuid NOT NULL,
  new_value     int  NOT NULL,
  reasoning     text NOT NULL,
  add_source    text NOT NULL
);

INSERT INTO mig1931_targets VALUES
-- CIVIL RIGHTS -> 2, the CROWN Act
('f4286f1f-dda7-4fe4-9473-455772f40fae'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: 88(R) HB 567, "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - the CROWN Act - of which she is the PRIMARY AUTHOR, and which was ENACTED, effective 1 September 2023. Adding a protected characteristic to the state''s anti-discrimination law extends civil rights enforcement, which is rung 2''s own clause, "strengthen civil rights enforcement and address systemic discrimination". Rung 1 requires mandating racial equity requirements in all institutions, which the Act does not do; rung 3 is to MAINTAIN current civil rights laws, and the Act changes them. This is authorship rather than a vote, so it is distinctive whatever the final margin.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
('43567dd1-db59-40af-928e-03708237eb98'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: she is an author of 88(R) HB 567, the CROWN Act - "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - enacted effective 1 September 2023. She also authored 88(R) HB 725, prohibiting discrimination based on sexual orientation or gender identity or expression, and 87(R) HB 3479, prohibiting housing discrimination on the basis of criminal history. Three instruments of her own, each EXTENDING anti-discrimination protection to a group the law did not cover, which is rung 2''s clause "strengthen civil rights enforcement and address systemic discrimination". Rung 1''s mandated racial equity requirements in all institutions is not what any of them does; rung 3 would have her MAINTAIN current law, and she is changing it.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
('41e2f865-d56b-4999-9232-57473dea13ee'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: she is a coauthor of 88(R) HB 567 and 87(R) HB 392, the CROWN Act - "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - enacted effective 1 September 2023. She also authored 88(R) HB 1193, prohibiting housing discrimination by a property owners'' association based on a tenant''s source of income, and 86(R) HB 1751, prohibiting sex discrimination in employment compensation. Each extends anti-discrimination protection, which is rung 2''s clause "strengthen civil rights enforcement and address systemic discrimination". Rung 1''s mandated racial equity requirements in all institutions is not evidenced; rung 3 is to MAINTAIN current law, which these instruments change.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
('70920806-a146-4dc3-8cc7-4566f9caf903'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: he is a coauthor of 88(R) HB 567, the CROWN Act - "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - enacted effective 1 September 2023 - and of 88(R) HB 1806, prohibiting employment discrimination based on sexual orientation or gender identity or expression, and 89(R) HB 607, prohibiting discrimination by health care providers on grounds including race, disability, immigration status and sexual orientation. Each extends anti-discrimination protection to a group the law did not cover, which is rung 2''s clause "strengthen civil rights enforcement and address systemic discrimination". Rung 1''s mandated racial equity requirements in all institutions is not what these do; rung 3 is to MAINTAIN current law.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
('1a94bee0-7418-4b75-ba17-f3cf97d888aa'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: she is a coauthor of 88(R) HB 567 and 87(R) HB 392, the CROWN Act - "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - enacted effective 1 September 2023. She also authored 87(R) HB 3157 on the criminal offence of violation of the civil rights of persons in custody. Extending a protected characteristic in the state''s anti-discrimination law is rung 2''s clause, "strengthen civil rights enforcement and address systemic discrimination". Rung 1 requires mandating racial equity requirements in all institutions, which this is not; rung 3 is to MAINTAIN current civil rights laws, and the Act changes them.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
('d9486e4a-490a-4d87-a495-655cce9700e2'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: he is a coauthor of 88(R) HB 567 and 87(R) HB 392, the CROWN Act - "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - enacted effective 1 September 2023. Adding a protected characteristic to the state''s anti-discrimination law extends civil rights enforcement, which is rung 2''s clause "strengthen civil rights enforcement and address systemic discrimination". Rung 1 requires mandating racial equity requirements in all institutions, which the Act does not do; rung 3 is to MAINTAIN current civil rights laws, and the Act changes them. This is coauthorship rather than a vote, so it is distinctive whatever the final margin.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
('c456d802-e836-4208-8d18-33402c807429'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: he is a coauthor of 88(R) HB 567 and 87(R) HB 392, the CROWN Act - "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - enacted effective 1 September 2023. Adding a protected characteristic to the state''s anti-discrimination law extends civil rights enforcement, which is rung 2''s clause "strengthen civil rights enforcement and address systemic discrimination". Rung 1 requires mandating racial equity requirements in all institutions, which the Act does not do; rung 3 is to MAINTAIN current civil rights laws, and the Act changes them. This is coauthorship rather than a vote, so it is distinctive whatever the final margin.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
('2d3e3416-fb12-455b-9010-4185010fb3aa'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: he is a coauthor of 88(R) HB 567 and 87(R) HB 392, the CROWN Act - "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - enacted effective 1 September 2023. Adding a protected characteristic to the state''s anti-discrimination law extends civil rights enforcement, which is rung 2''s clause "strengthen civil rights enforcement and address systemic discrimination". Rung 1 requires mandating racial equity requirements in all institutions, which the Act does not do; rung 3 is to MAINTAIN current civil rights laws, and the Act changes them. This is coauthorship rather than a vote, so it is distinctive whatever the final margin.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
('4750d905-2ccc-4eaf-9a69-f5f20ef8b18f'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: she is a coauthor of 88(R) HB 567 and 87(R) HB 392, the CROWN Act - "Relating to discrimination on the basis of hair texture or protective hairstyle associated with race" - enacted effective 1 September 2023. She also authored 87(R) HB 3157 on the criminal offence of violation of the civil rights of persons in custody. Extending a protected characteristic in the state''s anti-discrimination law is rung 2''s clause, "strengthen civil rights enforcement and address systemic discrimination". Rung 1 requires mandating racial equity requirements in all institutions, which this is not; rung 3 is to MAINTAIN current civil rights laws, and the Act changes them.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB567'),
-- CLIMATE CHANGE -> 5
('56b91150-194f-4699-ba31-e944443eacae'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,5,
 'RE-SEATED from blank by migration 1931, on the re-research migration 1928 called for. 🔑 THE NEW INSTRUMENT: 87(R) HB 4470, which he AUTHORED - "Relating to imposing a tax on the amount of federal renewable energy production credits received by wind electric generators". A state tax that recaptures a clean-energy subsidy is rung 5''s subject exactly: "End government subsidies and mandates for clean energy." Rung 4 is "stay neutral on energy and let the market choose among all sources", and a tax aimed at a single source is the opposite of neutrality, so it is excluded rather than merely less apt. HONEST ABOUT THE OUTCOME: the bill did not pass - referred to Ways and Means on 29 March 2021 and left there. Sponsorship evidences the bill AS FILED, which is what a position is.','https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=HB4470');

-- GUARD 1 — the set is what the re-research found.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1931_targets;
  IF n <> 10 THEN RAISE EXCEPTION 'migration 1931: expected 10 re-seats, found %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1931_targets) s;
  IF n <> 10 THEN RAISE EXCEPTION 'migration 1931: duplicate (politician, topic) pairs; % of 10', n; END IF;
  SELECT count(*) INTO n FROM mig1931_targets WHERE new_value = 2;
  IF n <> 9 THEN RAISE EXCEPTION 'migration 1931: expected 9 civil-rights re-seats, found %', n; END IF;
END $$;

-- GUARD 2 — every target is currently one of 1926's blanks. 🔴 Staleness gate.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1931_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
     AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
    JOIN inform.politician_answers pa
      ON pa.politician_id=t.politician_id AND pa.topic_id=t.topic_id AND pa.season_id=pc.season_id
   WHERE pc.reasoning LIKE 'INTERNAL RECORD - blanked by migration 1926%' AND pa.value = 0;
  IF n <> 10 THEN RAISE EXCEPTION 'migration 1931: only % of 10 targets are still 1926 blanks — re-measure', n; END IF;

  SELECT count(*) INTO n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id AND pa.season_id=pc.season_id
   WHERE pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pc.reasoning LIKE 'INTERNAL RECORD - blanked by migration 1926%' AND pa.value = 0;
  IF n <> 131 THEN RAISE EXCEPTION 'migration 1931: expected 131 remaining blanks, found % — the population moved', n; END IF;
END $$;

-- GUARD 3 — the rungs claimed exist in this season's ladder.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1931_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.season_questions sq
       JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = sq.topic_revision_id
      WHERE sq.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND sq.topic_id = t.topic_id AND sr.value = t.new_value);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1931: % target(s) name a rung that does not exist', n; END IF;
END $$;

UPDATE inform.politician_answers pa
   SET value = t.new_value, updated_at = now()
  FROM mig1931_targets t
 WHERE pa.politician_id=t.politician_id AND pa.topic_id=t.topic_id
   AND pa.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

UPDATE inform.politician_context pc
   SET reasoning = t.reasoning, updated_at = now()
  FROM mig1931_targets t
 WHERE pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
   AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The new instrument goes into sources. Idempotent.
UPDATE inform.politician_context pc
   SET sources = pc.sources || ARRAY[t.add_source], updated_at = now()
  FROM mig1931_targets t
 WHERE pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
   AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND NOT (pc.sources @> ARRAY[t.add_source]);

-- GUARD 4 — verify the RESULT.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1931_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id=t.politician_id AND pa.topic_id=t.topic_id
     AND pa.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = t.new_value;
  IF n <> 10 THEN RAISE EXCEPTION 'migration 1931: expected 10 rows at their new rung, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1931_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
     AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE NOT (pc.sources @> ARRAY[t.add_source])
      OR pc.reasoning NOT LIKE 'RE-SEATED from blank by migration 1931%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1931: % row(s) did not record their new instrument', n; END IF;

  -- 🔑 Every re-seated row must name an identifier the chair-evidence gate can see.
  SELECT count(*) INTO n
    FROM mig1931_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id
     AND pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning !~ '\mHB ?[0-9]';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1931: % re-seated row(s) name no citable bill', n; END IF;

  -- 🔴 BLAST RADIUS: exactly 121 of 1926's blanks remain blank.
  SELECT count(*) INTO n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id AND pa.season_id=pc.season_id
   WHERE pc.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pc.reasoning LIKE 'INTERNAL RECORD - blanked by migration 1926%' AND pa.value = 0;
  IF n <> 121 THEN RAISE EXCEPTION 'migration 1931: expected 121 rows left blank, found % — wrong blast radius', n; END IF;

  -- Season 1 is closed.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
    JOIN mig1931_targets t ON t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id
   WHERE pa.updated_at > now() - interval '5 minutes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1931: % Season 1 answer(s) were modified', n; END IF;

  RAISE NOTICE 'migration 1931: re-seated 10 of 131; 121 remain blank';
END $$;

DROP TABLE mig1931_targets;
