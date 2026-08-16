-- 1782_wa_last_senate_republicans.sql
-- Closes the last uncovered bloc: 6 rows on `taxes` at chair 4, 3 on `public-safety-approach` at
-- chair 4, and 3 DOCUMENTED BLANKS. Gildon and MacEwen are seated; Muzzall, Short and Schoesler are
-- blanked with reasons.
--
-- ── 🔑 THE CUT SIDE OF THE TAXES LADDER IS REACHABLE AFTER ALL — IT NEEDED AN EXPENDITURE LIMIT ───
-- Migration 1764 blanked Ed Orcutt at chair 4 and recorded exactly what was missing: "no instrument
-- pairs a cut with a service reduction, and there is no EXPENDITURE-LIMIT BILL in 69 substantive
-- sponsorships". SB 5151 is that bill. It forbids the state to spend above a limit that grows only at
-- the 10-year average of median wage growth, makes a breach a violation subjecting the treasurer to
-- statutory penalties, and dedicates the excess revenue to property tax relief. Chair 4 is "cut taxes
-- for everyone AND scale back public services to match": the property tax relief is the cut, and a
-- binding cap below the cost of maintaining current service levels is the scale-back, legislated
-- rather than forecast. Chair 5 ("DRASTICALLY cut taxes and shrink government") is refused on the
-- adverb rule that has governed this ladder since migration 1759 — the act indexes spending to wage
-- growth rather than reducing it, so nothing in the text supports "drastically".
-- This closes the trouble-spot worry that the cut side was unreachable and would bias the corpus by
-- party. It is reachable; it just needs an instrument that legislates the consequence, and only one
-- of the 3,411 bills in the biennium does.
--
-- ── `public-safety-approach` chair 4 for SB 5958 ─────────────────────────────────────────────────
-- Two additional basic law enforcement academy classes at a new regional academy, $5,000,000
-- appropriated, wait times reported annually. The enacted ESHB 2015 seated in migration 1779 defines
-- chair 4's staffing limb as "hiring, retaining, and TRAINING law enforcement officers"; this funds
-- the training capacity that gates the pipeline. Chairs 2 and 3 are refuted (staffing rises, no
-- co-responder or crisis team is created), chair 5 is refuted (a targeted $5,000,000 ranks police
-- against nothing), chair 1 is the opposite direction.
-- ⚠ Note the cohort is bipartisan — a Republican prime with two Democratic co-sponsors.
--
-- ── the three blanks ─────────────────────────────────────────────────────────────────────────────
-- Muzzall is the "defending what exists" shape at its clearest: six health instruments, every one of
-- them inside medicaid or the rural hospital programmes, none changing who is covered. Short's
-- comprehensive-plan bill is administrative relief for towns under 500 people, not a growth position.
-- Schoesler's tax record is exemptions, which is the fourth time this sweep has hit the taxes chair-4
-- consequence clause — after Orcutt (R), Krishnadasan (D) and Steele (R).
BEGIN;

CREATE TEMP TABLE lr_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='d997402c-ee18-4544-b770-ac13a777b601' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Gildon already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='755f24a5-2330-4546-9679-d5f7fa94aaa9' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Braun already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='0e935fed-534e-42b0-a5ad-74f4199ff6df' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Leonard Christian already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='d3fad6d8-8022-4c66-b505-4e7a8fc816d7' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Phil Fortunato already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='b316dce9-ed2e-44f6-b974-bf639cacb816' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Judy Warnick already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='aadf55f0-a4b4-4a4a-acf0-bfce06815149' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Wilson already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='5ab349b4-f041-4637-af64-c4e6e4f54c3e' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Drew MacEwen already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='054dd953-bc6b-44de-8173-00efab5a9c04' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Conway already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context WHERE politician_id='f183194f-814a-43c6-858e-11fc66ad5d41' AND topic_id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Ron Muzzall already has a healthcare context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics WHERE id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529' AND topic_key='healthcare' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: healthcare topic id does not resolve to a live topic'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context WHERE politician_id='a88093ad-c483-49c1-ae1e-9f851cdb53fc' AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelly Short already has a growth-and-development context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics WHERE id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4' AND topic_key='growth-and-development' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: growth-and-development topic id does not resolve to a live topic'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context WHERE politician_id='f893ae5d-6659-40cd-a874-e9351efcdb95' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mark Schoesler already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics WHERE id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND topic_key='taxes' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: taxes topic id does not resolve to a live topic'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND value=4 AND text ILIKE '%scale back public services%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: taxes chair 4 no longer carries the service-reduction clause'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('d997402c-ee18-4544-b770-ac13a777b601','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Prime sponsor of SB 5151, which would impose a hard state expenditure limit: beginning July 1, 2026 the state "may not expend from the general fund and related funds during any fiscal year state moneys in excess of the state expenditure limit", the limit growing only at the 10-year average of median wage growth, with the treasurer barred from issuing any warrant that breaches it — and with excess revenues dedicated to property tax relief.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5151.pdf']),
('755f24a5-2330-4546-9679-d5f7fa94aaa9','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of SB 5151, which would impose a hard state expenditure limit: beginning July 1, 2026 the state "may not expend from the general fund and related funds during any fiscal year state moneys in excess of the state expenditure limit", the limit growing only at the 10-year average of median wage growth, with the treasurer barred from issuing any warrant that breaches it — and with excess revenues dedicated to property tax relief.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5151.pdf']),
('0e935fed-534e-42b0-a5ad-74f4199ff6df','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of SB 5151, which would impose a hard state expenditure limit: beginning July 1, 2026 the state "may not expend from the general fund and related funds during any fiscal year state moneys in excess of the state expenditure limit", the limit growing only at the 10-year average of median wage growth, with the treasurer barred from issuing any warrant that breaches it — and with excess revenues dedicated to property tax relief.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5151.pdf']),
('d3fad6d8-8022-4c66-b505-4e7a8fc816d7','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of SB 5151, which would impose a hard state expenditure limit: beginning July 1, 2026 the state "may not expend from the general fund and related funds during any fiscal year state moneys in excess of the state expenditure limit", the limit growing only at the 10-year average of median wage growth, with the treasurer barred from issuing any warrant that breaches it — and with excess revenues dedicated to property tax relief.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5151.pdf']),
('b316dce9-ed2e-44f6-b974-bf639cacb816','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of SB 5151, which would impose a hard state expenditure limit: beginning July 1, 2026 the state "may not expend from the general fund and related funds during any fiscal year state moneys in excess of the state expenditure limit", the limit growing only at the 10-year average of median wage growth, with the treasurer barred from issuing any warrant that breaches it — and with excess revenues dedicated to property tax relief.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5151.pdf']),
('aadf55f0-a4b4-4a4a-acf0-bfce06815149','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Co-sponsor of SB 5151, which would impose a hard state expenditure limit: beginning July 1, 2026 the state "may not expend from the general fund and related funds during any fiscal year state moneys in excess of the state expenditure limit", the limit growing only at the 10-year average of median wage growth, with the treasurer barred from issuing any warrant that breaches it — and with excess revenues dedicated to property tax relief.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5151.pdf']),
('5ab349b4-f041-4637-af64-c4e6e4f54c3e','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Prime sponsor of SB 5958, which would require the criminal justice training commission to run at least two additional basic law enforcement academy classes at a new regional training academy, appropriating $5,000,000 for the purpose and requiring the commission to report average student wait times annually. The classes "are in addition to the classes currently provided by the commission".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5958.pdf']),
('1e6d175b-1af0-444c-b373-e5d0a279d240','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of SB 5958, which would require the criminal justice training commission to run at least two additional basic law enforcement academy classes at a new regional training academy, appropriating $5,000,000 for the purpose and requiring the commission to report average student wait times annually. The classes "are in addition to the classes currently provided by the commission".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5958.pdf']),
('054dd953-bc6b-44de-8173-00efab5a9c04','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of SB 5958, which would require the criminal justice training commission to run at least two additional basic law enforcement academy classes at a new regional training academy, appropriating $5,000,000 for the purpose and requiring the commission to report average student wait times annually. The classes "are in addition to the classes currently provided by the commission".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5958.pdf']),
('f183194f-814a-43c6-858e-11fc66ad5d41','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 $r$Unable to place on this ladder. Prime sponsor of SB 6103 (Chapter law, 2026), which makes medical assistance payments for rural emergency hospital services subject to appropriation within the critical access hospital framework, and of SB 5881, which would take the state savings created by federal medicaid reforms — narrowed eligibility, redeterminations, community engagement requirements — and route them into a new account for increased medicaid reimbursement rates to providers and hospitals. His wider health record is of the same kind: network adequacy standards for skilled nursing, critical access hospital designations, rural local health officers. Every instrument works inside the existing medicaid and rural hospital programmes and none changes who is covered. Chair 3 pairs helping people who cannot afford care with EXPANDING programmes for seniors and low-income residents; chair 4 asserts the state should help ONLY the poorest and leave everyone else to employers and private insurance, which he never states; chairs 1 and 2 are universal or near-universal coverage; chair 5 is staying out of healthcare, which sponsoring medicaid payment legislation refutes. Sustaining a programme's payment mechanics is not a chair.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6103.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5881.pdf']),
('a88093ad-c483-49c1-ae1e-9f851cdb53fc','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
 $r$Unable to place on this ladder. Prime sponsor of SB 5173, which would let a city or town opt out of the full periodic review of its comprehensive plan if it has fewer than 500 residents, sits more than 10 miles from a city over 100,000, and grew less than 10 percent in the preceding decade — while still requiring it to update its critical areas, capital facilities and transportation elements. That is administrative relief for the smallest jurisdictions, not a position on the pace of growth: it sets no growth limit (chair 1), conditions nothing on infrastructure capacity (chair 2), funds no infrastructure ahead of growth (chair 3), streamlines no permitting and reduces no fees for development (chair 4), and removes no regulatory barrier to building (chair 5). Same shape as SB 5558, which reached no chair for the same reason.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5173.pdf']),
('f893ae5d-6659-40cd-a874-e9351efcdb95','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Unable to place on this ladder. Prime sponsor of SB 5289, which would extend the existing sales and use tax exemption for farm machinery to replacement parts and to the labour of installing and repairing them, and of SB 5405 (inflation adjustment to the estate tax exclusion) and SB 5431 (tax and revenue law changes "not estimated to affect state or local" collections). Chairs 1 and 2 require raising taxes on wealthy people and large companies, which he sponsors nowhere; chair 3 requires keeping the system as-is while closing unfair loopholes, and these open preferences rather than closing them; chairs 4 and 5 require cutting taxes for everyone AND scaling back public services to match, and a targeted exemption for farm equipment repair states no service consequence — the same missing clause that blanked Ed Orcutt in migration 1764, Deborah Krishnadasan in 1777 and Mike Steele in 1778.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5289.pdf']);

-- answers for the two cohorts only; the three blanks get NO answer row
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('d997402c-ee18-4544-b770-ac13a777b601','f7e5678d-dadd-4556-a2fc-446e24642ceb', 4),
('755f24a5-2330-4546-9679-d5f7fa94aaa9','f7e5678d-dadd-4556-a2fc-446e24642ceb', 4),
('0e935fed-534e-42b0-a5ad-74f4199ff6df','f7e5678d-dadd-4556-a2fc-446e24642ceb', 4),
('d3fad6d8-8022-4c66-b505-4e7a8fc816d7','f7e5678d-dadd-4556-a2fc-446e24642ceb', 4),
('b316dce9-ed2e-44f6-b974-bf639cacb816','f7e5678d-dadd-4556-a2fc-446e24642ceb', 4),
('aadf55f0-a4b4-4a4a-acf0-bfce06815149','f7e5678d-dadd-4556-a2fc-446e24642ceb', 4),
('5ab349b4-f041-4637-af64-c4e6e4f54c3e','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('1e6d175b-1af0-444c-b373-e5d0a279d240','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('054dd953-bc6b-44de-8173-00efab5a9c04','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4);

DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; ct int; cp int; nblank int;
BEGIN
  SELECT * INTO s FROM lr_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 9 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +9', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 12 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +12', s.ctx_before, ctx_after; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND a.politician_id IN ('d997402c-ee18-4544-b770-ac13a777b601','755f24a5-2330-4546-9679-d5f7fa94aaa9','0e935fed-534e-42b0-a5ad-74f4199ff6df','d3fad6d8-8022-4c66-b505-4e7a8fc816d7','b316dce9-ed2e-44f6-b974-bf639cacb816','aadf55f0-a4b4-4a4a-acf0-bfce06815149')
     AND (a.value <> 4 OR c.reasoning !~ 'state expenditure limit' OR c.reasoning !~ 'property tax relief');
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % taxes row(s) wrong chair or missing both limbs of the chair', bad; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND a.politician_id IN ('5ab349b4-f041-4637-af64-c4e6e4f54c3e','1e6d175b-1af0-444c-b373-e5d0a279d240','054dd953-bc6b-44de-8173-00efab5a9c04')
     AND (a.value <> 4 OR c.reasoning !~ 'basic law enforcement academy');
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % public-safety row(s) wrong chair or missing the academy clause', bad; END IF;

  SELECT count(*) INTO ct FROM inform.politician_answers WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND value=4 AND politician_id IN ('d997402c-ee18-4544-b770-ac13a777b601','755f24a5-2330-4546-9679-d5f7fa94aaa9','0e935fed-534e-42b0-a5ad-74f4199ff6df','d3fad6d8-8022-4c66-b505-4e7a8fc816d7','b316dce9-ed2e-44f6-b974-bf639cacb816','aadf55f0-a4b4-4a4a-acf0-bfce06815149');
  SELECT count(*) INTO cp FROM inform.politician_answers WHERE topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND value=4 AND politician_id IN ('5ab349b4-f041-4637-af64-c4e6e4f54c3e','1e6d175b-1af0-444c-b373-e5d0a279d240','054dd953-bc6b-44de-8173-00efab5a9c04');
  IF ct <> 6 THEN RAISE EXCEPTION 'guard 2: taxes chair-4 count is %, expected 6', ct; END IF;
  IF cp <> 3 THEN RAISE EXCEPTION 'guard 2: public-safety chair-4 count is %, expected 3', cp; END IF;

  SELECT count(*) INTO nblank
    FROM inform.politician_context c
   WHERE ((c.politician_id='f183194f-814a-43c6-858e-11fc66ad5d41' AND c.topic_id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529') OR (c.politician_id='a88093ad-c483-49c1-ae1e-9f851cdb53fc' AND c.topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4') OR (c.politician_id='f893ae5d-6659-40cd-a874-e9351efcdb95' AND c.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'))
     AND c.reasoning ~ '^Unable to place on this ladder'
     AND coalesce(cardinality(c.sources),0) >= 1
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF nblank <> 3 THEN RAISE EXCEPTION 'guard 2: % documented blank(s), expected 3', nblank; END IF;
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

  RAISE NOTICE 'taxes: 6 at chair 4; public-safety: 3 at chair 4; 3 documented blanks; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
