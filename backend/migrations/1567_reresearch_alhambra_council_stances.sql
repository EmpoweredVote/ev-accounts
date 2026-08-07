-- 1567_reresearch_alhambra_council_stances.sql
--
-- Restore 16 Alhambra City Council stance rows, re-researched from the city's own council minutes
-- after migration 1564 retired all 19 of the city's rows as fabricated-source citations.
--
--   Review:   data/stance-research/reresearch-alhambra/FINDINGS.md — evidence, per-row basis, judgement calls
--   Rollback: DELETE both rows for the 16 (politician_id, topic_id) pairs listed in the VALUES block,
--             then UPDATE essentials.politicians SET last_stances_researched_at = NULL for the 5.
--             Nothing else is touched, so the rollback is exact.
--   Follows:  1564 (retired all 19; Alhambra fell to zero answers and its chip was flipped false)
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1567_reresearch_alhambra_council_stances.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY THE OLD ROWS COULD NOT BE REPAIRED, AND WHAT REPLACED THEM
-- ---------------------------------------------------------------------------------------------------
-- All six sources the 19 retired rows cited were fabricated: five `sgvtribune.com` article paths
-- (denylisted by 1564 — a real, live outlet carrying invented paths, the `lowellsun.com` shape) and one
-- 404 index at `alhambraca.gov/government/city-council/agendas-minutes`. Nothing was re-pointable.
--
-- ⚠ One retired citation asserted an "Alhambra mental health co-responder program". There is NO
-- co-responder, crisis-response or mental-health response team anywhere in Alhambra's 2024-2026 council
-- minutes. The program appears not to exist. 🔑 When a fabricated citation names a PROGRAM, check
-- whether the program exists — its absence corroborates the fabrication, and here it also decided the
-- Public Safety chairs (chair 3 "adding crisis response teams" has no support for anyone).
--
-- Evidence base rebuilt from scratch: 77 of 78 AgendaCenter minutes PDFs, 2024-2026. Alhambra minutes
-- carry named roll calls, per-member attributed discussion and per-item vote tallies.
--
-- 🔴 EVERY VOTE TALLY BELOW WAS RE-EXTRACTED WITHOUT `pdftotext -layout`. With `-layout` the
-- 2025-07-28 immigration resolution reads "Noes: ANDRADE-STADLER, MALONEY, MAZA, WANG, LEE" — all five
-- against a resolution they had just moved, seconded and spoken in support of. The columns are
-- misaligned; the true tally is Ayes all five, Noes NONE, passed 5-0. Trusting it would have published
-- five councilmembers as voting against a pro-immigrant resolution: a fabrication in the opposite
-- direction, from a genuine document. See FINDINGS.md.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THREE ROWS ARE DELIBERATELY NOT RESTORED
-- ---------------------------------------------------------------------------------------------------
-- Homelessness Response is owed by LEE, WANG and MAZA. The 2024-2026 minutes contain no position
-- statement on homelessness from any of the three — Lee's only trace is a clarifying question about the
-- Police HOME (Homeless Outreach Mental Evaluation) Team's membership, and a question is not a position.
-- Per the standing rule, verified absent leaves the spoke BLANK; only "unsure" would be wrong to act on.
-- Those three remain in the coverage gap and are not closed by this migration.
--
-- Sources: only `alhambraca.gov` official minutes, each fetched and read. No retired citation is reused.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _alh (
  politician_id uuid,
  full_name     text,
  topic_id      uuid,
  topic         text,
  value         numeric,
  reasoning     text,
  sources       text[]
) ON COMMIT DROP;

INSERT INTO _alh (politician_id, full_name, topic_id, topic, value, reasoning, sources) VALUES

-- ---------- Local Immigration Enforcement -----------------------------------------------------------
-- Resolution No. R2M25-29, adopted 5-0 on 2025-07-28: "Alhambra condemns aggressive and non-transparent
-- federal immigration enforcement tactics, reaffirms commitment to constitutional and community safety
-- principles, and directs proactive local response measures." Moved ANDRADE-STADLER, seconded MALONEY.
('f6d52199-b1d1-48d3-9972-66b8d229acdc', 'Adele Andrade-Stadler',
 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 'Local Immigration Enforcement', 1,
 'Moved Resolution No. R2M25-29 on July 28, 2025, which condemns aggressive and non-transparent federal immigration enforcement tactics and directs proactive local response measures; it was adopted 5-0. On February 9, 2026 she described her work with Union del Barrio supporting immigrant communities and asked staff to prepare a further resolution addressing additional concerns.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_07282025-1433',
       'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02092026-1525']),

('e4df4fce-9289-43db-8568-e316a73ae931', 'Jeff Maloney',
 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 'Local Immigration Enforcement', 1,
 'Seconded Resolution No. R2M25-29, adopted 5-0 on July 28, 2025. On February 9, 2026, as Mayor, he restated the Council''s position that the City would not cooperate with Immigration and Customs Enforcement officers, asked staff to look into establishing "ICE Free Zones" in Alhambra following the approach taken by Los Angeles County, and formed a two-member Council subcommittee to review and extend the City''s prior resolutions.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_07282025-1433',
       'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02092026-1525']),

('f22187bb-dc57-4088-bb19-8bc39bcb95c9', 'Katherine Lee',
 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 'Local Immigration Enforcement', 2,
 'Voted for Resolution No. R2M25-29 on July 28, 2025 and spoke in support of it, discussing the need for federal immigration policy to be reformed. On February 9, 2026 she supported both a Council subcommittee focused on immigration enforcement and a new resolution. She also asked that the word "aggressive" in the resolution''s title be reconsidered, and framed her support by the limitations of local government against federal policy.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_07282025-1433',
       'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02092026-1525']),

('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb', 'Noya Wang',
 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 'Local Immigration Enforcement', 2,
 'Voted for Resolution No. R2M25-29 on July 28, 2025 and spoke in support of it, and on February 9, 2026 supported the Mayor and Vice Mayor serving on a Council subcommittee on immigration enforcement. She proposed narrowing the resolution''s title to "unwarranted aggressive and non-transparent tactics" and echoed her colleagues'' comments on the limitations of local government.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_07282025-1433',
       'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02092026-1525']),

-- ---------- Affordable Housing ----------------------------------------------------------------------
-- 2026-02-23: tenant displacement at 110 S. Chapel Ave. and use of the Inclusionary Housing In-Lieu fund.
('f22187bb-dc57-4088-bb19-8bc39bcb95c9', 'Katherine Lee',
 '669cac97-66a6-4087-b036-936fbe62efb3', 'Affordable Housing', 2,
 'At the February 23, 2026 meeting she moved to extend the City''s Inclusionary Housing In-Lieu fund to fund tenant relocation assistance of $3,000 per household for low- to moderate-income residents displaced by new development, paid directly to the new landlord, alongside health and safety standards applied to proposed developments.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02232026-1529']),

('f6d52199-b1d1-48d3-9972-66b8d229acdc', 'Adele Andrade-Stadler',
 '669cac97-66a6-4087-b036-936fbe62efb3', 'Affordable Housing', 2,
 'At the February 23, 2026 meeting she supported Displaced Tenant Assistance and pressed staff to review the Inclusionary Housing In-Lieu fund as a source of that assistance. She also pressed on the developer including 10 percent affordable units for low and very low-income households.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02232026-1529']),

('e4df4fce-9289-43db-8568-e316a73ae931', 'Jeff Maloney',
 '669cac97-66a6-4087-b036-936fbe62efb3', 'Affordable Housing', 2,
 'At the February 23, 2026 meeting he moved that staff examine the Inclusionary Housing In-Lieu fund and Measure A funds as sources for tenant relocation assistance, and discussed the displacement of residents through new development. He declined two related sub-items on the grounds that there would be no legal path to pursue them.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02232026-1529']),

('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb', 'Noya Wang',
 '669cac97-66a6-4087-b036-936fbe62efb3', 'Affordable Housing', 3,
 'At the February 23, 2026 meeting she resisted repurposing the Inclusionary Housing In-Lieu fund for tenant relocation, warning that it would affect the City''s Regional Housing Needs Assessment allocation and was not among the approved or intended uses of the fees, and suggested instead that developers contribute directly to tenant relocation assistance.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02232026-1529']),

('27441d13-d90b-48e8-bb35-3b7da5d24c6e', 'Ross J. Maza',
 '669cac97-66a6-4087-b036-936fbe62efb3', 'Affordable Housing', 3,
 'At the February 23, 2026 meeting he was not in favor of two proposed tenant-assistance sub-items, emphasising the Council''s responsibility to follow State law and to protect the City''s certified Housing Element from a finding of violation by the state housing department. He supported only further discussion of the third sub-item.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02232026-1529']),

-- ---------- Residential Zoning ----------------------------------------------------------------------
-- 2025-08-25 Item 3: SB 79 (Wiener), higher-density housing near transit overriding local zoning.
('f22187bb-dc57-4088-bb19-8bc39bcb95c9', 'Katherine Lee',
 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 'Residential Zoning', 1,
 'On August 25, 2025 she opposed SB 79, the state bill allowing higher-density housing near transit over local zoning, citing the State''s overreach, the local burden of additional housing and the erosion of democracy, and stated that the City of Alhambra officially opposed it. In January and February 2026 she sought changes to the municipal code to condition or reduce the impact of permitted developments and objected to high-density projects in medium-density neighborhood zones.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_08252025-1444',
       'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_01262026-1516']),

('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb', 'Noya Wang',
 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 'Residential Zoning', 2,
 'On August 25, 2025 she was critical of SB 79, the state bill allowing higher-density housing near transit over local zoning, discussing the ways it failed to recognise the specific needs at the local level. She worked within the City''s Regional Housing Needs Assessment obligation rather than joining a blanket opposition, and in January 2026 supported further discussion of density concerns in order to collect more information.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_08252025-1444',
       'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_01262026-1516']),

-- ---------- Public Safety Approach -------------------------------------------------------------------
-- 2026-01-12 Item 14: Lenco G2 Bearcat Armored Rescue Vehicle, $123,690, approved 5-0 over a public
-- comment urging Council to decline it because militarized equipment reduces community trust.
('f6d52199-b1d1-48d3-9972-66b8d229acdc', 'Adele Andrade-Stadler',
 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Public Safety Approach', 4,
 'On January 12, 2026 she moved the purchase of a Lenco G2 Bearcat Armored Rescue Vehicle for the Alhambra Police Department at a cost not to exceed $123,690, and discussed its potential use during school lockdowns. The purchase was approved 5-0 over a public comment urging the Council to decline it on the grounds that militarized equipment reduces community trust.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_01122026-1512']),

('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb', 'Noya Wang',
 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Public Safety Approach', 4,
 'On January 12, 2026 she seconded the purchase of a Lenco G2 Bearcat Armored Rescue Vehicle for the Alhambra Police Department at a cost not to exceed $123,690, discussing its use for officer and citizen rescue, serving search warrants and de-escalating high-risk situations. The purchase was approved 5-0 over a public comment objecting to militarized equipment.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_01122026-1512']),

('27441d13-d90b-48e8-bb35-3b7da5d24c6e', 'Ross J. Maza',
 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Public Safety Approach', 4,
 'On January 12, 2026 he supported the purchase of a Lenco G2 Bearcat Armored Rescue Vehicle for the Alhambra Police Department at a cost not to exceed $123,690 and discussed the costs of armored vehicles. The purchase was approved 5-0 over a public comment urging the Council to decline it.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_01122026-1512']),

('f22187bb-dc57-4088-bb19-8bc39bcb95c9', 'Katherine Lee',
 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Public Safety Approach', 4,
 'On January 12, 2026 she voted to approve the purchase of a Lenco G2 Bearcat Armored Rescue Vehicle for the Alhambra Police Department at a cost not to exceed $123,690, approved 5-0 over a public comment objecting to militarized equipment. Her recorded remarks concerned the current practice of borrowing armored vehicles from neighboring cities, the availability of used and new vehicles, and the vehicle''s appearance, rather than the level of police funding.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_01122026-1512']),

-- ---------- Growth and Development Pace ---------------------------------------------------------------
('e4df4fce-9289-43db-8568-e316a73ae931', 'Jeff Maloney',
 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 'Growth and Development Pace', 3,
 'In January and February 2026 he declined to pursue changes that would jeopardise the status of Alhambra''s certified Housing Element, and opposed a stand-alone Council discussion of conditioning or reducing development impacts while supporting that the subject be taken up at the Strategic Planning Session. On August 25, 2025 he observed that SB 79''s effect on Alhambra would be very small and said he looked forward to the State Assembly process and its amendments, and did not join the letter of opposition.',
 ARRAY['https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_01262026-1516',
       'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_02092026-1525',
       'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/_08252025-1444']);

-- --- PRE-CONDITIONS -------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int; v_bad text;
BEGIN
  IF (SELECT count(*) FROM _alh) <> 16 THEN
    RAISE EXCEPTION 'PRE: expected 16 proposed rows, found %', (SELECT count(*) FROM _alh);
  END IF;

  -- The five are the Alhambra council, seated, and each currently holds ZERO answers (1564 emptied them).
  SELECT count(*) INTO v_cnt
  FROM (SELECT DISTINCT politician_id FROM _alh) d
  JOIN essentials.politicians p ON p.id = d.politician_id
  JOIN essentials.office_terms ot ON ot.politician_id = p.id
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '0600884';
  IF v_cnt <> 5 THEN
    RAISE EXCEPTION 'PRE: expected 5 seated Alhambra councilmembers, found %', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_answers a
   WHERE a.politician_id IN (SELECT politician_id FROM _alh);
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'PRE: Alhambra members already hold % answers — 1564 left them at zero', v_cnt;
  END IF;
  SELECT count(*) INTO v_cnt FROM inform.politician_context c
   WHERE c.politician_id IN (SELECT politician_id FROM _alh);
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'PRE: Alhambra members already hold % context rows', v_cnt;
  END IF;

  -- Every topic is live, and every chair value exists on its own scale.
  SELECT count(*) INTO v_cnt FROM _alh a
   JOIN inform.compass_topics t ON t.id = a.topic_id AND t.is_live;
  IF v_cnt <> 16 THEN
    RAISE EXCEPTION 'PRE: % of 16 rows map to a live topic', v_cnt;
  END IF;
  SELECT count(*) INTO v_cnt FROM _alh a
   JOIN inform.compass_stances s ON s.topic_id = a.topic_id AND s.value = a.value;
  IF v_cnt <> 16 THEN
    RAISE EXCEPTION 'PRE: % of 16 rows carry a value that exists on its topic scale', v_cnt;
  END IF;

  -- No proposed row may cite a denylisted url, and every source must be an alhambraca.gov minutes URL.
  SELECT string_agg(DISTINCT s, ', ') INTO v_bad
  FROM _alh a, unnest(a.sources) s
  WHERE s NOT LIKE 'https://www.alhambraca.gov/AgendaCenter/ViewFile/Minutes/%';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE: non-minutes source(s) present: %', v_bad;
  END IF;

  -- Homelessness Response must NOT be assigned to anyone — it is deliberately left blank.
  SELECT count(*) INTO v_cnt FROM _alh
   WHERE topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'PRE: Homelessness Response must stay unassigned, found % row(s)', v_cnt;
  END IF;
END $$;

-- --- CHANGES --------------------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
SELECT politician_id, topic_id, value, NULL FROM _alh;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, topic_id, reasoning, sources FROM _alh;

-- These five were researched today, from primary sources. Under the 1494 rule the timestamp is nulled
-- only for politicians emptied to zero; these are the opposite case, so it is set rather than cleared.
UPDATE essentials.politicians
   SET last_stances_researched_at = now()
 WHERE id IN (SELECT DISTINCT politician_id FROM _alh);

-- --- POST-CONDITIONS ------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int;
BEGIN
  SELECT count(*) INTO v_cnt FROM inform.politician_answers a
   WHERE a.politician_id IN (SELECT politician_id FROM _alh);
  IF v_cnt <> 16 THEN RAISE EXCEPTION 'POST: expected 16 Alhambra answers, found %', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_context c
   WHERE c.politician_id IN (SELECT politician_id FROM _alh);
  IF v_cnt <> 16 THEN RAISE EXCEPTION 'POST: expected 16 Alhambra context rows, found %', v_cnt; END IF;

  -- No context row is orphaned, and no answer lacks its reasoning: the two sets match exactly.
  SELECT count(*) INTO v_cnt
  FROM inform.politician_context c
  FULL OUTER JOIN inform.politician_answers a
    ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE COALESCE(a.politician_id, c.politician_id) IN (SELECT politician_id FROM _alh)
    AND (a.politician_id IS NULL OR c.politician_id IS NULL);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % answer/context rows unpaired', v_cnt; END IF;

  -- Per-member expectation, so a silent mis-key cannot pass: Lee 4, Wang 4, Andrade-Stadler 3,
  -- Maloney 3, Maza 2 = 16, and every one of the five is back above zero.
  IF (SELECT count(*) FROM inform.politician_answers
       WHERE politician_id = 'f22187bb-dc57-4088-bb19-8bc39bcb95c9') <> 4
     OR (SELECT count(*) FROM inform.politician_answers
       WHERE politician_id = 'abad7f66-e2d3-4edf-a35f-2170c2bd4cbb') <> 4
     OR (SELECT count(*) FROM inform.politician_answers
       WHERE politician_id = 'f6d52199-b1d1-48d3-9972-66b8d229acdc') <> 3
     OR (SELECT count(*) FROM inform.politician_answers
       WHERE politician_id = 'e4df4fce-9289-43db-8568-e316a73ae931') <> 3
     OR (SELECT count(*) FROM inform.politician_answers
       WHERE politician_id = '27441d13-d90b-48e8-bb35-3b7da5d24c6e') <> 2
  THEN RAISE EXCEPTION 'POST: per-member answer counts do not match the reviewed findings';
  END IF;

  -- Nobody has a stance with no citation.
  SELECT count(*) INTO v_cnt FROM inform.politician_context c
   WHERE c.politician_id IN (SELECT politician_id FROM _alh)
     AND (c.sources IS NULL OR array_length(c.sources, 1) IS NULL);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % rows carry no citation', v_cnt; END IF;
END $$;

COMMIT;
