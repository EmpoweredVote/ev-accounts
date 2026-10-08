-- 1907_tx_ssm_five_held_rows_to_rung1.sql
-- The last five rows of the Texas generic-profile-sourcing cohort, seated on the operator's
-- ruling of 2026-10-08. Five rows written; nothing else in the cohort is touched.
--
-- ══ WHERE THESE FIVE CAME FROM ════════════════════════════════════════════════════════════════
-- Migration 1903 blanked thirteen same-sex-marriage rows by applying the carry gate to the wrong
-- pair of rungs: it compared the SAME NUMBER across seasons for rows that were ALREADY IN SEASON
-- 2, on a ladder Season 2 had RENUMBERED by inserting a new rung 1. Migration 1906 corrected
-- that. Eight of the thirteen went back to the chair Season 2 already held. FIVE DID NOT, and
-- 1906 left them at 0 with the reason restated, because each one's own filed record argues a
-- DIFFERENT rung from the one Season 2 held -- and a chair move is a decision, not a repair.
-- The operator made that decision on 2026-10-08: all five move to rung 1.
--
-- ══ WHY RUNG 1, AND WHY IT IS THE SAME ARGUMENT FIVE TIMES ════════════════════════════════════
-- Season 2 rung 1 reads "Guarantee same-sex couples full legal equality -- equal marriage plus
-- protection from discrimination (such as in jobs and housing)". It is the ONLY rung on this
-- ladder that carries the anti-discrimination half; rung 2 is equal marriage alone and rung 3 is
-- equal marriage with a religious-organisation carve-out.
--
-- Each of these five has filed, under their own name or as a coauthor, a bill whose caption is
-- that half in so many words -- "the prohibition of ... discrimination based on sexual
-- orientation or gender identity or expression" -- and all five already sat on the equal-marriage
-- side of the ladder, so the first half was never in dispute. Their own instruments supply the
-- second.
--
--   Erin Zwiener        2 -> 1   HB 254 (86R), coauthor.
--   John Bryant         3 -> 1   HB 1806 (88R), coauthor; and HB 5031 (88R) / HB 2758 (89R) as
--                                AUTHOR. 🔴 He sat on the rung that protects a religious
--                                organisation's right to decline. NOTHING HE HAS FILED SUPPORTS
--                                THAT CARVE-OUT and his own bills run the other way.
--   Penny Morales Shaw  2 -> 1   HB 3796 (87R) and HB 1806 (88R) as AUTHOR, HB 850 (88R) as
--                                coauthor. The strongest of the five: she wrote two of them.
--   Toni Rose           2 -> 1   HB 4122 (87R) and HB 725 (88R), both as AUTHOR.
--   Venton Jones        2 -> 1   HB 1806 (88R), coauthor.
--
-- ⚖ THE LATEST FILING GOVERNS, and it was checked for each of the five. Every one of their later
-- same-sex-marriage filings -- the repeal of the offense of homosexual conduct (88R HB 2055, 89R
-- HB 1738), the repeal of the prohibition on promoting homosexuality (87R HB 4425, 88R HB 2048),
-- the statutory changes recognising same-sex marriages (88R HB 5031, 89R HB 2758) -- places the
-- member on the equal-marriage side WITHOUT separating rungs 1, 2 and 3. A band that CONTAINS a
-- rung is not a disagreement with it. None of the five has filed anything matching the
-- opposite-side rules (recusal from performing a marriage, a sincerely held religious belief),
-- so nothing on any of these records pulls the other way.
--
-- ⚠ THE EVIDENCE IS A FILING, NOT A VOTE, and a filing is a weaker instrument than a roll call:
-- none of these bills reached a recorded vote. It is nonetheless FIRST-PERSON evidence of the
-- member's own position, which is what this cohort exists to restore -- every one of these rows
-- was cited to a biography before the audit touched it.
--
-- Season 1 is CLOSED and IMMUTABLE: every write here is forward, into Season 2.
-- No migration runner exists; this file records SQL applied by hand.

DO $pre$
DECLARE n integer;
BEGIN
  -- 1. all five are sitting at 0 and carry migration 1906's restated blank. If they do not,
  --    something has moved them since and this file is seating a chair over someone else's work.
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id = a.politician_id
     AND c.topic_id = a.topic_id AND c.season_id = a.season_id
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND a.topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
     AND a.value = 0
     AND c.reasoning LIKE 'Blanked 2026-10-08 (migration 1906)%'
     AND a.politician_id IN (SELECT * FROM (VALUES
    ('17648ed7-5a6a-4ac1-b49e-0d3eaf08417e'::uuid),
    ('70920806-a146-4dc3-8cc7-4566f9caf903'::uuid),
    ('81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid),
    ('43567dd1-db59-40af-928e-03708237eb98'::uuid),
    ('e8058f2b-c68a-474b-b9fe-df4d2d22545b'::uuid)
     ) AS k(pid));
  IF n <> 5 THEN
    RAISE EXCEPTION 'migration 1907: expected 5 same-sex-marriage rows at 0 carrying migration 1906 reasoning, found %', n;
  END IF;

  -- 2. THE WHOLE RULING RESTS ON WHAT SEASON 2 RUNG 1 SAYS, so assert it rather than assume it.
  --    Rung 1 must be the one that adds anti-discrimination protection to equal marriage, and
  --    rung 2 must NOT -- otherwise the distinction this migration seats on does not exist.
  SELECT count(*) INTO n
    FROM inform.season_questions q
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = q.topic_revision_id
   WHERE q.topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
     AND q.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND r.value = 1
     AND lower(r.text) LIKE '%full legal equality%'
     AND lower(r.text) LIKE '%protection from discrimination%';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1907: Season 2 same-sex-marriage rung 1 is not the full-legal-equality rung this file seats on (%)', n;
  END IF;

  SELECT count(*) INTO n
    FROM inform.season_questions q
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = q.topic_revision_id
   WHERE q.topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
     AND q.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND r.value IN (2, 3)
     AND lower(r.text) LIKE '%protection from discrimination%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1907: rung 1 is not the only Season 2 rung carrying anti-discrimination protection (% others)', n;
  END IF;
END
$pre$;

-- Erin Zwiener / same-sex-marriage  (chair 2 -> 1, OPERATOR RULING 2026-10-08)
UPDATE inform.politician_context SET reasoning = 'Chair moved from 2 to 1 on 2026-10-08 (migration 1907). This row was one of five that migration 1906 left at 0 rather than write at a chair its own evidence contradicted; the operator ruled on 2026-10-08 that all five move to rung 1. THE RECORD: she is a coauthor of HB 254 (86R), "Relating to the prohibition of certain discrimination based on sexual orientation or gender identity or expression; providing an administrative penalty; creating a criminal offense". ⚖ THE RUNG: Season 2 rung 1 is the ONLY rung on this ladder that adds anti-discrimination protection to equal marriage -- "full legal equality: equal marriage plus protection from discrimination (such as in jobs and housing)". Rung 2, where this row sat, is equal marriage alone. The marriage half was therefore already granted, and HB 254 supplies the half that distinguishes rung 1, in the very example the rung gives. ⚠ THE LATEST FILING GOVERNS AND IT WAS CHECKED: her later work -- HB 4425 (87R) and HB 2048 (88R) as author, repealing the prohibition on promoting homosexuality in educational materials, and HB 2055 (88R) and HB 1738 (89R) as coauthor, repealing the offense of homosexual conduct -- places her on the equal-marriage side without separating rungs 1, 2 and 3. A band that contains the rung is not a disagreement with it, and she has filed nothing on the other side. ⚠ This is a FILING and not a roll call; none of these bills reached a recorded vote. It is first-person evidence of her own position, which is what this row lacked: before the audit it was cited to a biography.', sources = ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=86R&Bill=HB254', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB2048', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1738', 'https://en.wikipedia.org/wiki/Erin_Zwiener']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '17648ed7-5a6a-4ac1-b49e-0d3eaf08417e'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 1, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '17648ed7-5a6a-4ac1-b49e-0d3eaf08417e'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- John Bryant / same-sex-marriage  (chair 3 -> 1, OPERATOR RULING 2026-10-08)
UPDATE inform.politician_context SET reasoning = 'Chair moved from 3 to 1 on 2026-10-08 (migration 1907). This row was one of five that migration 1906 left at 0 rather than write at a chair its own evidence contradicted; the operator ruled on 2026-10-08 that all five move to rung 1. THE RECORD: he is a coauthor of HB 1806 (88R), "Relating to the prohibition of employment discrimination based on sexual orientation or gender identity or expression", and the AUTHOR of HB 5031 (88R) and HB 2758 (89R), "Relating to certain statutory changes to reflect and address same-sex marriages and parenting relationships and to the removal of provisions regarding the criminality or unacceptability of homosexual conduct". 🔴 THE RUNG HE SAT ON IS THE ONE HIS RECORD ARGUES AGAINST. Season 2 rung 3 is "Allow same-sex marriage, but protect religious organizations'' right to decline to perform or host these marriages" -- a carve-out. Nothing he has filed creates or defends one; his own bills run the other way, writing same-sex marriages and the parenting relationships that follow from them into the statutes without exception. ⚖ Season 2 rung 1 is the only rung that adds anti-discrimination protection to equal marriage, and HB 1806 is that protection in the rung''s own example, employment. ⚠ THE LATEST FILING GOVERNS AND IT POINTS THE SAME WAY: his most recent instrument on this topic is HB 2758, filed in the 89th as author. ⚠ This is a FILING and not a roll call; none of these bills reached a recorded vote. It is first-person evidence of his own position, which is what this row lacked: before the audit it was cited to a biography.', sources = ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB1806', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB5031', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2758', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1738', 'https://capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=H&Code=A4120', 'https://en.wikipedia.org/wiki/John_Bryant_(Texas_politician)']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '70920806-a146-4dc3-8cc7-4566f9caf903'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 1, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '70920806-a146-4dc3-8cc7-4566f9caf903'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- Penny Morales Shaw / same-sex-marriage  (chair 2 -> 1, OPERATOR RULING 2026-10-08)
UPDATE inform.politician_context SET reasoning = 'Chair moved from 2 to 1 on 2026-10-08 (migration 1907). This row was one of five that migration 1906 left at 0 rather than write at a chair its own evidence contradicted; the operator ruled on 2026-10-08 that all five move to rung 1. 🔑 SHE IS THE STRONGEST OF THE FIVE: SHE WROTE TWO OF THEM HERSELF. THE RECORD: as AUTHOR, HB 3796 (87R) and HB 1806 (88R), "Relating to the prohibition of employment discrimination based on sexual orientation or gender identity or expression"; and as coauthor, HB 850 (88R), "Relating to the prohibition of certain discrimination based on sexual orientation or gender identity or expression; providing an administrative penalty". ⚖ THE RUNG: Season 2 rung 1 is the ONLY rung on this ladder that adds anti-discrimination protection to equal marriage -- "full legal equality: equal marriage plus protection from discrimination (such as in jobs and housing)". Rung 2, where this row sat, is equal marriage alone. The marriage half was already granted; her own bills supply the half that distinguishes rung 1, in the rung''s own example. ⚠ THE LATEST FILING GOVERNS AND IT WAS CHECKED: HB 2048, HB 2055 and HB 5031 (88R) and HB 1738 (89R) place her on the equal-marriage side without separating rungs 1, 2 and 3, and she has filed nothing on the other side. ⚠ This is a FILING and not a roll call; none of these bills reached a recorded vote. It is first-person evidence of her own position, which is what this row lacked: before the audit it was cited to a biography.', sources = ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=HB3796', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB1806', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB850', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1738', 'https://capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=H&Code=A4035', 'https://en.wikipedia.org/wiki/Penny_Morales_Shaw']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 1, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- Toni Rose / same-sex-marriage  (chair 2 -> 1, OPERATOR RULING 2026-10-08)
UPDATE inform.politician_context SET reasoning = 'Chair moved from 2 to 1 on 2026-10-08 (migration 1907). This row was one of five that migration 1906 left at 0 rather than write at a chair its own evidence contradicted; the operator ruled on 2026-10-08 that all five move to rung 1. THE RECORD: she is the AUTHOR of HB 4122 (87R) and HB 725 (88R), both "Relating to prohibiting certain discrimination based on sexual orientation or gender identity or expression" -- her own bill, filed twice, in consecutive legislatures. ⚖ THE RUNG: Season 2 rung 1 is the ONLY rung on this ladder that adds anti-discrimination protection to equal marriage -- "full legal equality: equal marriage plus protection from discrimination (such as in jobs and housing)". Rung 2, where this row sat, is equal marriage alone. The marriage half was already granted; HB 4122 and HB 725 supply the half that distinguishes rung 1. ⚠ THE LATEST FILING GOVERNS AND IT WAS CHECKED: her later work -- HB 2055 (88R) and HB 1738 (89R) as coauthor, repealing the offense of homosexual conduct -- places her on the equal-marriage side without separating rungs 1, 2 and 3, and she has filed nothing on the other side. ⚠ This is a FILING and not a roll call; neither bill reached a recorded vote. It is first-person evidence of her own position, which is what this row lacked: before the audit it was cited to a biography.', sources = ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=HB4122', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB725', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1738', 'https://capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=H&Code=A2555']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '43567dd1-db59-40af-928e-03708237eb98'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 1, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '43567dd1-db59-40af-928e-03708237eb98'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- Venton Jones / same-sex-marriage  (chair 2 -> 1, OPERATOR RULING 2026-10-08)
UPDATE inform.politician_context SET reasoning = 'Chair moved from 2 to 1 on 2026-10-08 (migration 1907). This row was one of five that migration 1906 left at 0 rather than write at a chair its own evidence contradicted; the operator ruled on 2026-10-08 that all five move to rung 1. THE RECORD: he is a coauthor of HB 1806 (88R), "Relating to the prohibition of employment discrimination based on sexual orientation or gender identity or expression", and the AUTHOR of HB 2055 and HB 3160 (88R) and HB 1738 (89R), repealing the offense of homosexual conduct. ⚖ THE RUNG: Season 2 rung 1 is the ONLY rung on this ladder that adds anti-discrimination protection to equal marriage -- "full legal equality: equal marriage plus protection from discrimination (such as in jobs and housing)". Rung 2, where this row sat, is equal marriage alone. The marriage half was already granted, and HB 1806 supplies the half that distinguishes rung 1, in the rung''s own example, employment. ⚠ THE LATEST FILING GOVERNS AND IT WAS CHECKED: his most recent instrument, HB 1738 in the 89th as author, places him on the equal-marriage side without separating rungs 1, 2 and 3 -- a band that contains the rung is not a disagreement with it -- and he has filed nothing on the other side. ⚠ This is a FILING and not a roll call; none of these bills reached a recorded vote. It is first-person evidence of his own position, which is what this row lacked: before the audit it was cited to a biography.', sources = ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=88R&Bill=HB1806', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1738', 'https://en.wikipedia.org/wiki/Venton_Jones']::text[], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'e8058f2b-c68a-474b-b9fe-df4d2d22545b'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 1, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'e8058f2b-c68a-474b-b9fe-df4d2d22545b'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid
     AND reasoning LIKE '%(migration 1907)%';
  IF n <> 5 THEN
    RAISE EXCEPTION 'migration 1907: wrote % reasoning rows, expected 5', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id = a.politician_id
     AND c.topic_id = a.topic_id AND c.season_id = a.season_id
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE '%(migration 1907)%'
     AND a.value = 1;
  IF n <> 5 THEN
    RAISE EXCEPTION 'migration 1907: % of the 5 rows are seated at rung 1, expected 5', n;
  END IF;

  -- nothing may be left at 0 in the five, and no Season 1 row may have moved
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND reasoning LIKE '%migration 1907%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1907: % Season 1 rows were altered, expected 0', n;
  END IF;
END
$post$;
