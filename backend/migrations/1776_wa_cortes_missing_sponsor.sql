-- 1776_wa_cortes_missing_sponsor.sql
-- One row on `taxes` at chair 2 for Adrian Cortes (D-18), who belonged in migration 1770 and was
-- missing from it. Same instrument, same chair, same reasoning as the other 26 sponsors.
--
-- 🔴 HOW HE WENT MISSING, AND WHY IT MATTERS MORE THAN ONE ROW. The sponsorship index has exactly one
-- source: SponsorService/GetSponsors. For SB 6346 that service returns **26** sponsors. The enrolled
-- session law names **27** — "...Nobles, Saldaña, Salomon, and Cortes". The service's list is a
-- version snapshot and it dropped him. Nothing downstream could have caught this: the cohort guards
-- check the rows that WERE written, the gate checks orphans, and a member the service never mentions
-- looks exactly like a member who sponsored nothing. A tool's gap looks like a clean result.
--
-- ✅ AUDITED, NOT ASSUMED. Every instrument this sweep has seated a cohort on was re-checked against
-- the sponsor list printed on the bill itself — EHB 1217, HB 2367, HB 1699, HB 1696, HB 1687,
-- HB 1435, HB 1584, HB 1585, HB 2225, SB 5038, SB 6264, SB 5818, SB 5002, SB 6182, SB 5471, SB 5184,
-- SB 5091, SJR 8204 and SB 6346. **SB 6346 is the only instrument with a real discrepancy**, so the
-- other ~250 rows stand. The audit is committed as `scripts/wa-sweep/wa_audit_sponsors.py`; run it
-- before any future cohort write.
--
-- ⚠ Two false alarms it raises, both benign and both worth knowing before someone "fixes" them:
--   · A NAME CHANGE looks like a missing sponsor. Member 20760 is printed as "Caldier" on bills
--     introduced in January 2025 and returned as "Valdez" by the service today — same member ID, same
--     person. It fired on HB 1435 and HB 1699. Compare IDs, never surnames.
--   · Sponsor lines run into the bill text on some PDFs, so a stray token like "(3" can appear as a
--     printed-only name (SB 5818). Read the line before believing it.
BEGIN;

CREATE TEMP TABLE cx_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f8feca06-c2bb-4ec8-ad85-0989559912e9' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adrian Cortes already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f8feca06-c2bb-4ec8-ad85-0989559912e9' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adrian Cortes already has a taxes context row'; END IF;
  -- he must be the ONLY one still missing: 1770 wrote 26 rows from this instrument
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND reasoning ~ 'Chapter 238, Laws of 2026';
  IF n <> 26 THEN RAISE EXCEPTION 'pre-check: expected 26 existing ESSB 6346 rows from migration 1770, found %', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('f8feca06-c2bb-4ec8-ad85-0989559912e9','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of ESSB 6346 (Chapter 238, Laws of 2026), the millionaires' tax: a 9.90 percent tax on Washington taxable income above a $1,000,000 standard deduction, reaching the wealthiest one-half of one percent of households. Section 1(6) states the intent of the act is to "maintain and preserve essential governmental services for Washingtonians, particularly within K-12 education, health care, higher education, and human services", and section 202 directs the revenue to fund sales and use tax relief, the working families' tax credit and business and occupation tax relief alongside the general fund's existing investments in K-12 education, health care, human services and higher education.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('f8feca06-c2bb-4ec8-ad85-0989559912e9','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2);

DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; total int;
BEGIN
  SELECT * INTO s FROM cx_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 1 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +1', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 1 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +1', s.ctx_before, ctx_after; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.politician_id='f8feca06-c2bb-4ec8-ad85-0989559912e9' AND a.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND (a.value <> 2
          OR c.reasoning !~ 'maintain and preserve essential governmental services'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/6346-S.SL.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: the Cortes row is the wrong chair, missing the destination clause, or missing the session law'; END IF;

  -- the cohort is now whole: 27 rows, matching the enrolled act's sponsor list
  SELECT count(*) INTO total FROM inform.politician_context
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND reasoning ~ 'Chapter 238, Laws of 2026';
  IF total <> 27 THEN RAISE EXCEPTION 'guard 2: ESSB 6346 rows total %, expected 27', total; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'taxes: Cortes added; ESSB 6346 cohort now 27 rows; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
