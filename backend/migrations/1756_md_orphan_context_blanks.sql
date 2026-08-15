-- 1756_md_orphan_context_blanks.sql
-- The Maryland reasoning left behind when 1731/1732/1734/1736 blanked the answers.
--
-- 🔴 THESE ARE NOT HONEST BLANKS AND THAT IS THE POINT. The answers were correctly deleted -- the
-- record did not place these people -- but the prose stayed, and the prose still ASSERTS a position:
--   · "Harris represents a district with significant immigrant communities. He supports immigrant
--     protections" -- a position inferred from DISTRICT DEMOGRAPHICS.
--   · "Rosapepe served as US Ambassador to Romania ... He supports US assistance to Ukraine" -- a
--     BIOGRAPHY prior. "As a former Democratic leader, he strongly backs voter access" -- a PARTY prior,
--     the class flagged as still-open since 2026-08-01 and never worked.
--   · Economic Development Incentives is 10 near-identical sentences with the county name swapped;
--     Taxes is 11 more. Template output, no instrument, no source for the claim.
-- That is the attribute-prior class migration 1521 retired. Assign a chair to any of these pairs and
-- Citations.jsx publishes the sentence verbatim under "Why this position?".
--
-- 🔑 WHY A BLANK IS EARNED HERE AND WAS NOT EARNED FOR THE JUDICIAL COHORT (mig 1755). There the
-- question did not apply to the subject at all, so writing "we looked and found nothing" would have
-- asserted an untested absence. Here the topics genuinely apply -- a Maryland legislator can hold a
-- position on Taxes or Immigration -- and the looking is ON THE RECORD: 1736 read every candidate
-- behind its rows (~2,765 titles), 1734 read 1,471 unique titles across its non-judicial rows, and
-- both recorded the count per row. Same gate, same shape, opposite remedy.
--
-- ⚠ THE CARVE-OUT IS EARNED BY TRUTH, NOT BY WORDING. The gate exempts a leading "Researched
-- YYYY-MM-DD", so this prefix could exempt anything. It is used only because each row carries a count
-- of what was read and a reason it failed, taken from the migration that blanked it -- per-row where
-- 1731/1732/1736 recorded one, and from 1734's header for the three rows whose own record pushes back.
-- Nothing here is a fresh judgement about a politician.
--
-- 🔑 MAGNITUDE IS THE SINGLE BIGGEST GROUP, AND IT IS A REAL FINDING, NOT A GAP. Every Taxation row
-- sits at chair 2 -- "MODERATELY raise taxes ... to fund EXISTING services" -- which differs from chair
-- 1 only in degree. Alonzo Washington LEADS the Digital Advertising Gross Revenues tax (HB0695, 2020);
-- Kagan co-sponsored carried-interest repeal and the Corporate Tax Fairness Act. Every one proves
-- DIRECTION and not one can prove "moderately". A bill citation proves direction, never magnitude.
--
-- ▶ OWED, recorded so it is not lost with the prose: four rows are RE-SEAT candidates whose own record
-- points at a different chair -- Rosapepe / Voting Rights (the Universal Voter Registration Act is
-- chair 1's language), and 1736's Hester / AI Oversight, Kramer / Medicare-Medicaid and Kagan /
-- Campaign Finance. Moving a chair is a decision, not a re-sourcing. The blanks below say the seated
-- chair is unevidenced; they do not say the person has no view.
--
-- SOURCES ARE NOT TOUCHED. They record what was checked, which is exactly what a documented blank
-- should cite -- the same shape as the 80 cited blanks the gate already carves out.
--
-- Rollback: data/stance-retirement/2026-08-14-md-orphan-context-1756-rollback.json
BEGIN;

CREATE TEMP TABLE mob_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE mob_new (pid uuid, tid uuid, reasoning text) ON COMMIT DROP;
INSERT INTO mob_new VALUES
  ('d423151e-8477-470d-8f73-ba7d2092f714','666bf03d-81fc-4138-ab15-69ae734c9023',$md$Researched 2026-08-12 — 9 candidate bills read from the complete Maryland General Assembly sponsorship record: record shows disclosure and liability, no bans. No scorable public record was found for this chair.$md$),
  ('da75c207-bb23-477e-b3c0-7c462394b570','92730f69-ae57-401c-8ad1-2d07834a895d',$md$Researched 2026-08-12 — 13 candidate bills read from the complete Maryland General Assembly sponsorship record: disclosure/anti-fraud, not limits on corporate or dark money. No scorable public record was found for this chair.$md$),
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','9db07b16-1076-4b7d-ad89-ebe7b51f4336',$md$Researched 2026-08-12 — 106 candidate bills read from the complete Maryland General Assembly sponsorship record: the record fails the must-beat-every-rival test rather than lacking evidence — the lead restorative bill SB0766 (2019) states discipline’s purpose is "rehabilitative, restorative, AND educational", so it cannot pick this chair over its neighbour. No scorable public record was found for this chair.$md$),
  ('da75c207-bb23-477e-b3c0-7c462394b570','9db07b16-1076-4b7d-ad89-ebe7b51f4336',$md$Researched 2026-08-12 — 64 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('cf190bac-9369-4175-bd4b-8ba776697d9c','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 34 candidate bills read from the complete Maryland General Assembly sponsorship record: targeted-industry incentives without the job-quality/CBA clause. No scorable public record was found for this chair.$md$),
  ('4754dede-4a3b-4280-a8b1-7497530107f7','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 42 candidate bills read from the complete Maryland General Assembly sponsorship record: targeted-industry incentives without the job-quality/CBA clause. No scorable public record was found for this chair.$md$),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 21 candidate bills read from the complete Maryland General Assembly sponsorship record: targeted-industry incentives without the job-quality/CBA clause. No scorable public record was found for this chair.$md$),
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 24 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 39 candidate bills read from the complete Maryland General Assembly sponsorship record: targeted-industry incentives without the job-quality/CBA clause. No scorable public record was found for this chair.$md$),
  ('c5d2cd24-170a-4f87-8fde-84216fe62806','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 12 candidate bills read from the complete Maryland General Assembly sponsorship record: targeted-industry incentives without the job-quality/CBA clause. No scorable public record was found for this chair.$md$),
  ('47823046-7dea-4a4f-a11b-0c5890539891','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 48 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('da75c207-bb23-477e-b3c0-7c462394b570','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 49 candidate bills read from the complete Maryland General Assembly sponsorship record: targeted-industry incentives without the job-quality/CBA clause. No scorable public record was found for this chair.$md$),
  ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 94 candidate bills read from the complete Maryland General Assembly sponsorship record: targeted incentives for specific industries are richly evidenced (One Maryland credits, RISE zones, the Aerospace Commission, all LEAD), but nothing evidences the community-benefit or job-quality clause, leaving this chair tied with its neighbour. No scorable public record was found for this chair.$md$),
  ('9aef8bfb-8e0c-4f00-9898-c738abe4970c','eb3d1247-0de1-4b7f-baec-7259861efd53',$md$Researched 2026-08-12 — 14 candidate bills read from the complete Maryland General Assembly sponsorship record: targeted-industry incentives without the job-quality/CBA clause. No scorable public record was found for this chair.$md$),
  ('4754dede-4a3b-4280-a8b1-7497530107f7','1935979c-b290-42e4-baa5-8cb0138b4ffa',$md$Researched 2026-08-12 — 14 candidate bills read from the complete Maryland General Assembly sponsorship record: counter-evidence rather than absence — a plausible co-sponsored candidate (SB0203, 2019, no-net-loss at 40%) is outweighed by the lead bill SB0663 (2021), which EXEMPTS Charles County cemeteries from sediment control, stormwater management and forest conservation, the opposite of requiring developers to fully offset environmental impact. No scorable public record was found for this chair.$md$),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1','1935979c-b290-42e4-baa5-8cb0138b4ffa',$md$Researched 2026-08-12 — 12 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac','1935979c-b290-42e4-baa5-8cb0138b4ffa',$md$Researched 2026-08-12 — 15 candidate bills read from the complete Maryland General Assembly sponsorship record: no tree-canopy or developer-offset instrument. No scorable public record was found for this chair.$md$),
  ('7a2d1548-3268-4767-97a8-bb8b142d5a33','1935979c-b290-42e4-baa5-8cb0138b4ffa',$md$Researched 2026-08-12 — 25 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','1935979c-b290-42e4-baa5-8cb0138b4ffa',$md$Researched 2026-08-12 — 21 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1','4e2c69ce-591e-4197-9cd5-7aceff79d390',$md$Researched 2026-08-12 — 3 candidate bills read from the complete Maryland General Assembly sponsorship record: ladder is public-service access; the record is enforcement cooperation. No scorable public record was found for this chair.$md$),
  ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','4e2c69ce-591e-4197-9cd5-7aceff79d390',$md$Researched 2026-08-12 — 9 candidate bills read from the complete Maryland General Assembly sponsorship record: ladder is public-service access; the record is enforcement cooperation. No scorable public record was found for this chair.$md$),
  ('c5d2cd24-170a-4f87-8fde-84216fe62806','4e2c69ce-591e-4197-9cd5-7aceff79d390',$md$Researched 2026-08-12 — 10 candidate bills read from the complete Maryland General Assembly sponsorship record: ladder is public-service access; the record is enforcement cooperation. No scorable public record was found for this chair.$md$),
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','4e2c69ce-591e-4197-9cd5-7aceff79d390',$md$Researched 2026-08-12 — 17 candidate bills read from the complete Maryland General Assembly sponsorship record: ladder is public-service access; the record is enforcement cooperation. No scorable public record was found for this chair.$md$),
  ('da75c207-bb23-477e-b3c0-7c462394b570','4e2c69ce-591e-4197-9cd5-7aceff79d390',$md$Researched 2026-08-12 — 10 candidate bills read from the complete Maryland General Assembly sponsorship record: ladder is public-service access; the record is enforcement cooperation. No scorable public record was found for this chair.$md$),
  ('cf190bac-9369-4175-bd4b-8ba776697d9c','e9ebefcd-c496-45e8-b816-a79f8442ba85',$md$Researched 2026-08-12 — 55 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('4754dede-4a3b-4280-a8b1-7497530107f7','e9ebefcd-c496-45e8-b816-a79f8442ba85',$md$Researched 2026-08-12 — 31 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac','e9ebefcd-c496-45e8-b816-a79f8442ba85',$md$Researched 2026-08-12 — 49 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('47823046-7dea-4a4f-a11b-0c5890539891','e9ebefcd-c496-45e8-b816-a79f8442ba85',$md$Researched 2026-08-12 — 154 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e','e9ebefcd-c496-45e8-b816-a79f8442ba85',$md$Researched 2026-08-12 — 113 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('da75c207-bb23-477e-b3c0-7c462394b570','e9ebefcd-c496-45e8-b816-a79f8442ba85',$md$Researched 2026-08-12 — 242 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('9aef8bfb-8e0c-4f00-9898-c738abe4970c','e9ebefcd-c496-45e8-b816-a79f8442ba85',$md$Researched 2026-08-12 — 64 candidate bills read from the complete Maryland General Assembly sponsorship record: nothing in that record describes the seated chair. No scorable public record was found for this chair.$md$),
  ('c5d2cd24-170a-4f87-8fde-84216fe62806','48cc9585-ec22-4f53-8d42-6839828dd36f',$md$Researched 2026-08-12 — 3 candidate bills read from the complete Maryland General Assembly sponsorship record: district STANDARDS, not an independent commission. No scorable public record was found for this chair.$md$),
  ('4a7dc8a6-2138-4472-8197-8b878034f029','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 150 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('cf190bac-9369-4175-bd4b-8ba776697d9c','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 40 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('4754dede-4a3b-4280-a8b1-7497530107f7','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 39 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 46 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 74 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('7a2d1548-3268-4767-97a8-bb8b142d5a33','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 81 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('47823046-7dea-4a4f-a11b-0c5890539891','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 76 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 194 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 119 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('da75c207-bb23-477e-b3c0-7c462394b570','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 92 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('9aef8bfb-8e0c-4f00-9898-c738abe4970c','f7e5678d-dadd-4556-a2fc-446e24642ceb',$md$Researched 2026-08-12 — 26 candidate bills read from the complete Maryland General Assembly sponsorship record: MAGNITUDE — ch2 differs from ch1 only in degree; sponsorship cannot prove "moderately". No scorable public record was found for this chair.$md$),
  ('c5d2cd24-170a-4f87-8fde-84216fe62806','d1618b9c-0b9e-45af-b986-bb33d270b8e4',$md$Researched 2026-08-12 — 10 candidate bills read from the complete Maryland General Assembly sponsorship record: never legislated in the MD corpus. No scorable public record was found for this chair.$md$),
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','d1618b9c-0b9e-45af-b986-bb33d270b8e4',$md$Researched 2026-08-12 — 5 candidate bills read from the complete Maryland General Assembly sponsorship record: never legislated in the MD corpus. No scorable public record was found for this chair.$md$),
  ('da75c207-bb23-477e-b3c0-7c462394b570','d1618b9c-0b9e-45af-b986-bb33d270b8e4',$md$Researched 2026-08-12 — 4 candidate bills read from the complete Maryland General Assembly sponsorship record: never legislated in the MD corpus. No scorable public record was found for this chair.$md$),
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e','24e9212c-b011-422a-865c-093e35050901',$md$Researched 2026-08-12 — 3 candidate bills read from the complete Maryland General Assembly sponsorship record: a federal question a state record cannot reach. No scorable public record was found for this chair.$md$),
  ('4754dede-4a3b-4280-a8b1-7497530107f7','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',$md$Researched 2026-08-12 — 32 candidate bills read from the complete Maryland General Assembly sponsorship record: precinct procedures, absentee envelope party affiliation, correctional-facility registration, elderly/disabled polling procedures — none expands early voting or no-excuse mail. No scorable public record was found for this chair.$md$),
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',$md$Researched 2026-08-12 — 13 candidate bills read from the complete Maryland General Assembly sponsorship record: no early-voting or no-excuse-mail instrument. No scorable public record was found for this chair.$md$),
  ('c5d2cd24-170a-4f87-8fde-84216fe62806','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',$md$Researched 2026-08-12 — 23 candidate bills read from the complete Maryland General Assembly sponsorship record: no early-voting or no-excuse-mail instrument. No scorable public record was found for this chair.$md$),
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',$md$Researched 2026-08-12 — 50 candidate bills read from the complete Maryland General Assembly sponsorship record: deep election-law record but nothing expanding early voting or no-excuse mail; the Universal Voter Registration Act is chair 1's language, a re-seat to consider on evidence later. No scorable public record was found for this chair.$md$);

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mob_new;
  IF n <> 51 THEN RAISE EXCEPTION 'pre-check: % rows, expected 51', n; END IF;

  -- Every target must still exist AND still be an orphan. If one acquired an answer since the grounding
  -- was captured, someone has since decided the record DOES place them, and overwriting their reasoning
  -- with a blank would contradict a live published chair.
  SELECT count(*) INTO n FROM mob_new m
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=m.pid AND c.topic_id=m.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % row(s) no longer exist', n; END IF;

  SELECT count(*) INTO n FROM mob_new m
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id=m.pid AND a.topic_id=m.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % row(s) acquired an answer since capture', n; END IF;
END $$;

UPDATE inform.politician_context c
   SET reasoning = m.reasoning
  FROM mob_new m
 WHERE c.politician_id = m.pid AND c.topic_id = m.tid;

-- Guard 1: nothing was created or destroyed. This pass rewrites text and touches nothing else.
DO $$
DECLARE ctx_after int; ans_after int; s record;
BEGIN
  SELECT * INTO s FROM mob_snap;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 1: context moved % -> %', s.ctx_before, ctx_after; END IF;
  IF ans_after <> s.ans_before THEN
    RAISE EXCEPTION 'guard 1: answers moved % -> %', s.ans_before, ans_after; END IF;
END $$;

-- Guard 2: every rewritten row now reads as a documented blank under BOTH of the gate's carve-out
-- predicates, and every one kept its sources. A blank with no citation of what was checked is a worse
-- row than the one it replaced.
DO $$
DECLARE not_blank int; lost_sources int;
BEGIN
  SELECT count(*) INTO not_blank FROM inform.politician_context c JOIN mob_new m
    ON m.pid=c.politician_id AND m.tid=c.topic_id
   WHERE c.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}';
  IF not_blank > 0 THEN RAISE EXCEPTION 'guard 2: % row(s) miss the date carve-out', not_blank; END IF;

  SELECT count(*) INTO not_blank FROM inform.politician_context c JOIN mob_new m
    ON m.pid=c.politician_id AND m.tid=c.topic_id
   WHERE c.reasoning !~* 'no scorable';
  IF not_blank > 0 THEN RAISE EXCEPTION 'guard 2: % row(s) miss the prose carve-out', not_blank; END IF;

  SELECT count(*) INTO lost_sources FROM inform.politician_context c JOIN mob_new m
    ON m.pid=c.politician_id AND m.tid=c.topic_id
   WHERE coalesce(cardinality(c.sources),0) = 0;
  IF lost_sources > 0 THEN RAISE EXCEPTION 'guard 2: % row(s) lost their sources', lost_sources; END IF;
END $$;

-- Guard 3: Maryland is now clear of gate-visible orphans, and no answer anywhere lost its context.
DO $$
DECLARE md_left int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO md_left
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
    LEFT JOIN LATERAL (
      SELECT ofc.representing_state, d.state FROM essentials.office_current_holder och
        JOIN essentials.offices ofc ON ofc.id = och.office_id
        LEFT JOIN essentials.districts d ON d.id = ofc.district_id
       WHERE och.politician_id = pc.politician_id ORDER BY ofc.title LIMIT 1) seat ON true
    LEFT JOIN LATERAL (
      SELECT lower(e.state::text) AS state FROM essentials.race_candidates rc
        JOIN essentials.races r ON r.id = rc.race_id
        JOIN essentials.elections e ON e.id = r.election_id
       WHERE rc.politician_id = pc.politician_id AND rc.candidate_status = 'active'
       ORDER BY e.election_date DESC LIMIT 1) cand ON true
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)'
     AND lower(coalesce(seat.state, seat.representing_state, cand.state, '')) = 'md';
  IF md_left <> 0 THEN RAISE EXCEPTION 'guard 3: % MD orphan(s) remain', md_left; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) now have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'md orphan blanks: 51 rewritten, 0 MD orphans left';
END $$;

COMMIT;
