-- 1570_reresearch_somerville_council_stances.sql
--
-- Restore 32 of the 62 Somerville City Council stance rows retired by migrations 1564/1565, rebuilt
-- from Somerville's Legistar record — the first cluster in this workstream with STRUCTURED, NAMED,
-- PER-MEMBER ROLL CALLS.
--
--   Review:   data/stance-research/reresearch-somerville/FINDINGS.md
--   Rollback: DELETE the 32 (politician_id, topic_id) pairs from inform.politician_answers and
--             inform.politician_context, then set last_stances_researched_at = NULL for the 10.
--   Follows:  1565 (somervillejournal.com, the 8th fabricated cluster), 1567/1568/1569
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1570_reresearch_somerville_council_stances.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE BEST EVIDENCE BASE FOUND SO FAR — AND HOW TO GET AT IT
-- ---------------------------------------------------------------------------------------------------
-- `webapi.legistar.com/v1/somervillema` is open and unauthenticated and returns **per-member roll calls
-- by name, including Nays**. That is qualitatively better than the PDF minutes used for Alhambra,
-- Carson and Waltham: no extraction, no column-alignment trap, and contested votes are visible.
--
-- ⚠ But the obvious path does not work: `matters/{id}/histories` returns [] for every matter, exactly
-- as in Carson. The path that works is
--       events -> events/{id}/eventitems -> eventitems/{id}/votes
-- matching on `EventItemMatterFile`. There is no top-level `/eventitems` collection (404).
-- Harvested with `harvest-rollcalls.mjs`: **371 recorded roll calls, 2025-08-28 → 2026-07-27.**
--
-- ⚠ MANY ITEMS ARE VOICE VOTES WITH NO ROLL CALL, and they are NOT evidence of anything either way.
-- Two matters that look perfect for this cluster are voice votes and therefore unusable:
--   * 24-1604 "Reaffirming Somerville's commitment as a Sanctuary and Trust Act City"
--   * 26-1041 "In support of rent control negotiations between the Keep Massachusetts Home campaign…"
-- Rent Regulation is owed by five members and stays BLANK for all five because of this.
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT THE 32 REST ON
-- ---------------------------------------------------------------------------------------------------
-- * Local Immigration Enforcement (10) — 26-0919 (2026-05-28) and 26-0522 (2026-07-09), amendments to
--   Section 2-6 of the Code of Ordinances, the **Welcoming Communities Ordinance** — Somerville's
--   sanctuary/Trust Act ordinance — the second "to further enhance civil rights protections". All ten
--   voted Aye on 26-0919 (Davis was absent for 26-0522, so his row cites the vote he was present for).
--   Reinforced by 26-1054, $350,000 to the Immigrant Legal Services Stabilization Fund, all Aye.
-- * Affordable Housing (9) — 26-1015 (2026-06-25), appropriating and transferring **$1,000,000** from
--   the Community Benefits Stabilization Fund to the Housing Assistance Stabilization Fund.
--   🔴 McLaughlin was ABSENT and is therefore left BLANK — his only other housing votes are
--   confirmations of appointments and receipt of reports, which are not positions.
-- * Public Safety Approach (7) — the body-worn-camera and police-grant series, the only genuinely
--   CONTESTED votes in the corpus, which is what makes them discriminating. Per-member below.
-- * Civil Rights (3) — 26-1135 (2026-06-25), restoring funding for cut positions in the **Racial and
--   Social Justice Department**, all Aye.
-- * Transportation (3) — Blue Bike station appropriations 26-0270 (2026-03-12) and 26-0202 (2026-03-26).
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THIRTY ROWS STAY BLANK, AND MOSTLY FOR ONE REASON: VOICE VOTES
-- ---------------------------------------------------------------------------------------------------
--   Residential Zoning 9 · Rent Regulation 5 · Env Protection vs Development 5 · Homelessness 3 ·
--   Deportation 2 · Climate Change 2 · Fossil Fuels 1 · Econ Dev Incentives 1 · Immigration 1 ·
--   Affordable Housing 1 (McLaughlin, absent)
-- Somerville legislates heavily by voice vote and by confirming appointments; neither produces a
-- per-member position. Confirming three trustees to the Affordable Housing Trust is not a housing
-- stance, and receiving a report is not a stance on its subject.
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _som (
  politician_id uuid, full_name text, topic_id uuid, value numeric, reasoning text, sources text[]
) ON COMMIT DROP;

CREATE TEMP TABLE _members (pid uuid, nm text) ON COMMIT DROP;
INSERT INTO _members VALUES
 ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','Ben Ewen-Campen'),
 ('ce379255-f87e-4856-9e2c-dda38c976bdc','Ben Wheeler'),
 ('bc02a2c7-2033-40a3-89f6-e50d95ac1e4e','Emily Hardt'),
 ('a79ac715-57a6-4a18-82a0-0b8a5ed60464','Jefferson Thomas Scott'),
 ('8242a03d-6801-4b91-aed9-918a603b4a21','Jon Link'),
 ('1e5429d3-c4b2-4a1f-913f-483833565e93','Kristen E. Strezo'),
 ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','Lance L. Davis'),
 ('5b2a514f-ea4b-4476-bf45-0d221a138d3a','Matthew McLaughlin'),
 ('cb506153-5bd5-4b43-b982-58d07c9611e4','Naima Sait'),
 ('9b11117c-d064-404b-8c89-0042f417c576','Wilfred N. Mbah');

-- ---------- Local Immigration Enforcement: all 10, chair 1 -------------------------------------------
INSERT INTO _som
SELECT pid, nm, 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 1,
  'Voted to amend Section 2-6 of the Code of Ordinances, Somerville''s Welcoming Communities Ordinance, on May 28, 2026, and the Council adopted a further amendment on July 9, 2026 "to further enhance civil rights protections in Somerville". The ordinance is the city''s sanctuary and Trust Act law, limiting cooperation between city government and federal immigration enforcement. The same Council also voted unanimously on June 25, 2026 to move $350,000 into the Immigrant Legal Services Stabilization Fund for continued legal services.',
  ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=34516&GUID=CC67A4D9-6EAA-459F-ADA9-55059C12ACB7',
        'https://somervillema.legistar.com/LegislationDetail.aspx?ID=34659&GUID=0F4C084B-C416-4159-A720-6414801BAE9E']
FROM _members;

-- ---------- Affordable Housing: 9 (McLaughlin absent, left blank), chair 2 --------------------------
INSERT INTO _som
SELECT pid, nm, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2,
  'Voted on June 25, 2026 to appropriate and transfer $1,000,000 from the Community Benefits Stabilization Fund — money contributed by developers under project community-benefit agreements — into the Housing Assistance Stabilization Fund for housing assistance. Somerville also requires affordable units in qualifying new development and maintains an Affordable Housing Trust funded by that mechanism.',
  ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=34619&GUID=B1309F4F-D97D-456E-B02E-466360D5DBB0']
FROM _members WHERE nm <> 'Matthew McLaughlin';

-- ---------- Civil Rights: 3, chair 2 ----------------------------------------------------------------
INSERT INTO _som
SELECT pid, nm, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2,
  'Voted on June 25, 2026 that the Administration restore funding for the cut positions in Somerville''s Racial and Social Justice Department and restore funding toward the department''s mission. The same Council amended the Welcoming Communities Ordinance on July 9, 2026 "to further enhance civil rights protections in Somerville".',
  ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=34749&GUID=FD69071D-4EE4-416E-BB2A-D2272064D3CC',
        'https://somervillema.legistar.com/LegislationDetail.aspx?ID=34093&GUID=D4F6DD77-9921-4C11-89B1-AE72CC42EC74']
FROM _members WHERE nm IN ('Ben Ewen-Campen','Naima Sait','Wilfred N. Mbah');

-- ---------- Transportation Priorities: 3, chair 1 ---------------------------------------------------
INSERT INTO _som
SELECT pid, nm, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 1,
  'Voted in March 2026 to appropriate money from Somerville''s Bike Share Stabilization Fund for the installation and startup of Blue Bike stations at new development sites, part of the city''s programme of building out cycling infrastructure alongside new development.',
  ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=33827&GUID=2A23A606-932C-4C27-8FC7-9D5F141F1AAD']
FROM _members WHERE nm IN ('Ben Ewen-Campen','Jon Link','Kristen E. Strezo');

-- ---------- Public Safety Approach: 7, split by the contested record ---------------------------------
-- The body-worn-camera and police-grant votes are the only contested items in 371 roll calls, which is
-- exactly what makes them informative: on the same motions, some members voted no and others yes.
INSERT INTO _som (politician_id, full_name, topic_id, value, reasoning, sources) VALUES

('8242a03d-6801-4b91-aed9-918a603b4a21','Jon Link','e9ebefcd-c496-45e8-b816-a79f8442ba85',2,
 'Has the most consistent record of opposition on the Council to expanding police capability: voted against accepting the $231,635 state grant for a body-worn camera programme on both July 9 and July 27, 2026, against the Technology-Specific Surveillance Use Policy and the Surveillance Technology Impact Report for those cameras, and against a Metropolitan Mayors Coalition Community Safety Initiative grant in March 2026.',
 ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=33944&GUID=57095F11-616C-404E-986C-B99DE5C5E210',
       'https://somervillema.legistar.com/LegislationDetail.aspx?ID=34848&GUID=F8BCD057-B73F-48BA-9CA8-C2275C888ABC',
       'https://somervillema.legistar.com/LegislationDetail.aspx?ID=33830&GUID=BDFC41C4-26BE-4B88-86AC-8178E7E4AB72']),

('cb506153-5bd5-4b43-b982-58d07c9611e4','Naima Sait','e9ebefcd-c496-45e8-b816-a79f8442ba85',2,
 'Voted against accepting the $231,635 state grant for a body-worn camera programme on July 27, 2026, against both the Surveillance Use Policy and the Surveillance Technology Impact Report for those cameras, and against a Metropolitan Mayors Coalition Community Safety Initiative grant in March 2026.',
 ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=33944&GUID=57095F11-616C-404E-986C-B99DE5C5E210',
       'https://somervillema.legistar.com/LegislationDetail.aspx?ID=34849&GUID=356A6D09-8D03-4AFF-B3F3-99717038CF22',
       'https://somervillema.legistar.com/LegislationDetail.aspx?ID=33830&GUID=BDFC41C4-26BE-4B88-86AC-8178E7E4AB72']),

('9b11117c-d064-404b-8c89-0042f417c576','Wilfred N. Mbah','e9ebefcd-c496-45e8-b816-a79f8442ba85',2,
 'Voted against three separate grant acceptances that would have expanded police and emergency-security capability in early 2026: a Metropolitan Mayors Coalition Community Safety Initiative grant and a $43,000 Boston Office of Emergency Management grant to the Police Department, both in March 2026, and a $48,000 Urban Areas Security Initiative grant in February 2026.',
 ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=33830&GUID=BDFC41C4-26BE-4B88-86AC-8178E7E4AB72']),

('073a3e12-55bb-4c88-9bd9-3333b93f40cd','Ben Ewen-Campen','e9ebefcd-c496-45e8-b816-a79f8442ba85',2,
 'Supported accepting the state grant for a body-worn camera programme but voted against the governing rules for it — both the Technology-Specific Surveillance Use Policy and the Surveillance Technology Impact Report for body-worn cameras, on July 27, 2026 — a vote for the equipment and against the surveillance framework proposed to govern it.',
 ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=34848&GUID=F8BCD057-B73F-48BA-9CA8-C2275C888ABC',
       'https://somervillema.legistar.com/LegislationDetail.aspx?ID=34849&GUID=356A6D09-8D03-4AFF-B3F3-99717038CF22']),

('1e5429d3-c4b2-4a1f-913f-483833565e93','Kristen E. Strezo','e9ebefcd-c496-45e8-b816-a79f8442ba85',2,
 'Voted on July 9, 2026 against both the Surveillance Technology Impact Report and the Technology-Specific Surveillance Use Policy for body-worn cameras, the only member to oppose them at that reading, while supporting the underlying grant.',
 ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=34849&GUID=356A6D09-8D03-4AFF-B3F3-99717038CF22',
       'https://somervillema.legistar.com/LegislationDetail.aspx?ID=34848&GUID=F8BCD057-B73F-48BA-9CA8-C2275C888ABC']),

('5b2a514f-ea4b-4476-bf45-0d221a138d3a','Matthew McLaughlin','e9ebefcd-c496-45e8-b816-a79f8442ba85',3,
 'Voted to approve every police and public-safety item that came before the Council in the 2026 session, including the $231,635 state grant for a body-worn camera programme and its accompanying surveillance use policy and impact report, and the federal and regional emergency-management grants that several colleagues opposed. He recorded no opposition on any of them.',
 ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=33944&GUID=57095F11-616C-404E-986C-B99DE5C5E210',
       'https://somervillema.legistar.com/LegislationDetail.aspx?ID=34848&GUID=F8BCD057-B73F-48BA-9CA8-C2275C888ABC']),

('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','Lance L. Davis','e9ebefcd-c496-45e8-b816-a79f8442ba85',3,
 'As Council President voted to approve the police and public-safety items that came before the Council in the 2026 session, including the $231,635 state grant for a body-worn camera programme and its accompanying surveillance use policy and impact report, and recorded no opposition on any of them.',
 ARRAY['https://somervillema.legistar.com/LegislationDetail.aspx?ID=33944&GUID=57095F11-616C-404E-986C-B99DE5C5E210',
       'https://somervillema.legistar.com/LegislationDetail.aspx?ID=34848&GUID=F8BCD057-B73F-48BA-9CA8-C2275C888ABC']);

-- --- PRE-CONDITIONS -------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int; v_bad text;
BEGIN
  IF (SELECT count(*) FROM _som) <> 32 THEN
    RAISE EXCEPTION 'PRE: expected 32 rows, found %', (SELECT count(*) FROM _som);
  END IF;

  -- All ten are seated Somerville City Councillors.
  SELECT count(DISTINCT d.pid) INTO v_cnt
  FROM _members d
  JOIN essentials.office_terms ot ON ot.politician_id = d.pid
  JOIN essentials.offices o  ON o.id = ot.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2562535';
  IF v_cnt <> 10 THEN RAISE EXCEPTION 'PRE: expected 10 seated Somerville councillors, found %', v_cnt; END IF;

  -- 1564/1565 left all ten at zero.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN (SELECT pid FROM _members);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: members already hold % answers', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT pid FROM _members);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: members already hold % context rows', v_cnt; END IF;

  -- No duplicate (politician, topic) pair.
  SELECT count(*) INTO v_cnt FROM (
    SELECT politician_id, topic_id FROM _som GROUP BY 1,2 HAVING count(*) > 1) d;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: % duplicated (politician, topic) pairs', v_cnt; END IF;

  -- Topics live, chair values real.
  SELECT count(*) INTO v_cnt FROM _som a
   JOIN inform.compass_topics t ON t.id = a.topic_id AND t.is_live
   JOIN inform.compass_stances s ON s.topic_id = a.topic_id AND s.value = a.value;
  IF v_cnt <> 32 THEN RAISE EXCEPTION 'PRE: % of 32 map to a live topic + real chair', v_cnt; END IF;

  -- Every source must be a Somerville Legistar legislation URL. Never somervillejournal.com (the 8th
  -- fabricated cluster) and never the invented /city-council/members/<name> scheme.
  SELECT string_agg(DISTINCT s, ', ') INTO v_bad
  FROM _som a, unnest(a.sources) s
  WHERE s NOT LIKE 'https://somervillema.legistar.com/LegislationDetail.aspx?ID=%';
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'PRE: non-Legistar source(s): %', v_bad; END IF;

  -- Rent Regulation was a voice vote and must not be assigned to anyone.
  SELECT count(*) INTO v_cnt FROM _som WHERE topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'PRE: rent regulation is unevidenced, found % row(s)', v_cnt; END IF;

  -- McLaughlin was absent for the housing appropriation and must not receive that row.
  IF EXISTS (SELECT 1 FROM _som
              WHERE politician_id = '5b2a514f-ea4b-4476-bf45-0d221a138d3a'
                AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3') THEN
    RAISE EXCEPTION 'PRE: McLaughlin was ABSENT for the housing vote and must stay blank';
  END IF;
END $$;

-- --- CHANGES --------------------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
SELECT politician_id, topic_id, value, NULL FROM _som;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, topic_id, reasoning, sources FROM _som;

UPDATE essentials.politicians
   SET last_stances_researched_at = now()
 WHERE id IN (SELECT DISTINCT politician_id FROM _som);

-- --- POST-CONDITIONS ------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int;
BEGIN
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN (SELECT pid FROM _members);
  IF v_cnt <> 32 THEN RAISE EXCEPTION 'POST: expected 32 answers, found %', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT pid FROM _members);
  IF v_cnt <> 32 THEN RAISE EXCEPTION 'POST: expected 32 context rows, found %', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
  FROM inform.politician_context c
  FULL OUTER JOIN inform.politician_answers a
    ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE COALESCE(a.politician_id, c.politician_id) IN (SELECT pid FROM _members)
    AND (a.politician_id IS NULL OR c.politician_id IS NULL);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % unpaired rows', v_cnt; END IF;

  -- Every one of the ten is back above zero, and Local Immigration Enforcement covers all ten.
  SELECT count(DISTINCT politician_id) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN (SELECT pid FROM _members);
  IF v_cnt <> 10 THEN RAISE EXCEPTION 'POST: only % of 10 members have answers', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'
     AND politician_id IN (SELECT pid FROM _members);
  IF v_cnt <> 10 THEN RAISE EXCEPTION 'POST: immigration rows = %, expected 10', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id IN (SELECT pid FROM _members)
     AND (sources IS NULL OR array_length(sources, 1) IS NULL);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % rows carry no citation', v_cnt; END IF;
END $$;

COMMIT;
