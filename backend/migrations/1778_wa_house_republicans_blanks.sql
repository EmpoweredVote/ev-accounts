-- 1778_wa_house_republicans_blanks.sql
-- 3 DOCUMENTED BLANKS closing the House Republicans: Joshua Penner on `childcare` and `healthcare`,
-- Mike Steele on `taxes`. No answer rows. Drew Stokesbary, the third, gets NOTHING — see below.
--
-- 🔑 A LADDER GAP THIS EXPOSES: A SUBSIDY CHANNELLED THROUGH EMPLOYERS HAS NO CHAIR. Penner's
-- HB 2187 pays employers a B&O credit worth half of what they spend on employees' child care. The
-- `childcare` ladder offers universal public funding (1), expanded family subsidies (2), income-tested
-- family credits plus provider grants (3), deregulation with subsidies for the poorest only (4), and
-- the pure market (5). A capped employer-side credit is a real, common policy and it sits between the
-- family-subsidy chairs and the market chair, matching neither. Logged for the ladder owner.
--
-- ⚠ AND ONE THAT KEEPS RECURRING: PREVENTING A CUT IS NOT A CHAIR. HB 2331 forbids the health care
-- authority from cutting off life-sustaining services under medical assistance. `healthcare` chair 3
-- pairs helping people who cannot afford care with EXPANDING programmes; chair 4 asserts the state
-- should help ONLY the poorest. Defending the existing scope of a safety-net programme is neither.
-- Same shape as climate in migration 1772 and taxes chair 4 throughout: the ladders describe changes
-- of direction and have nowhere to put maintaining what exists.
--
-- 🔴 STOKESBARY IS DELIBERATELY LEFT WITH NO ROW AT ALL, AND THAT IS NOT AN OVERSIGHT. The House
-- Minority Leader has ONE substantive primary sponsorship in the biennium (HB 2565, investment of
-- gifts and bequests) and one substantive co-sponsorship; everything else is procedural. A documented
-- blank would assert that a ladder was tried and could not reach him. What is actually true is that
-- THIS SOURCE CLASS is empty for him, which is a different statement, and writing the blank would
-- earn the carve-out by wording rather than by truth. He and Speaker Jinkins both need a different
-- source class — floor speeches, budget documents, press — and until then they stay unresearched
-- rather than falsely blanked.
BEGIN;

CREATE TEMP TABLE hr_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joshua Penner already has a childcare answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joshua Penner already has a childcare context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='c1ac1330-47f7-44ec-baf3-c913d926b97c' AND topic_key='childcare' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: childcare topic id does not resolve to a live topic'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd' AND topic_id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joshua Penner already has a healthcare answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd' AND topic_id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joshua Penner already has a healthcare context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529' AND topic_key='healthcare' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: healthcare topic id does not resolve to a live topic'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='87a700d7-b217-4475-9366-53a4e04acb19' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Steele already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='87a700d7-b217-4475-9366-53a4e04acb19' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Steele already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND topic_key='taxes' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: taxes topic id does not resolve to a live topic'; END IF;
  -- Stokesbary must stay untouched by this migration
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='9c1035b7-3372-4129-bca3-751b788b0999';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Stokesbary already holds context rows; re-read before writing'; END IF;
END $$;

-- context rows ONLY: a documented blank is a context row with sources and NO answer
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd','c1ac1330-47f7-44ec-baf3-c913d926b97c',
 $r$Unable to place on this ladder. Prime sponsor of HB 2187, which would give employers a business and occupation and public utility tax credit worth 50 percent of what they pay a registered child care provider for an employee's dependents — a five-year capped pilot, open first to employers with fewer than 100 full-time equivalent employees and to small businesses pooling into "child care consortiums", on the finding that "the lack of affordable child care is a primary barrier to workforce participation, particularly for employees of small and mid-sized businesses". Chair 5 is refuted: a tax credit is a public subsidy, so this is not leaving child care to the market. Chairs 2 and 3 direct subsidies at FAMILIES — chair 3 by income threshold, with provider training and facility grants alongside — and this credit is paid to EMPLOYERS with no income test and no provider grants. Chair 4 requires reducing regulation on providers, which the act does not do, and chair 1 is universal public funding. No chair describes a subsidy channelled through employers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2187.pdf']),
('2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 $r$Unable to place on this ladder. Prime sponsor of HB 2331, which would amend the medical assistance statute so that the health care authority and the department "may not cut off any prescription medications, oxygen supplies, respiratory services, or other life-sustaining medical services or supplies", to prevent reductions in pediatric primary care and behavioral health access. That protects the existing scope of a programme for people who cannot afford care, and every chair here asks for something else: chair 3 pairs helping those people with EXPANDING programmes, which this does not do; chair 4 claims the state should help ONLY the poorest and leave everyone else to employers and private insurance, which no instrument of his states; chairs 1 and 2 are universal or near-universal coverage, and chair 5 is staying out entirely, which sponsoring a medicaid protection refutes. Preventing a cut is not a chair on this ladder.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2331.pdf']),
('87a700d7-b217-4475-9366-53a4e04acb19','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Unable to place on this ladder. Co-sponsor of HJR 4207, a constitutional amendment authorizing a homestead property tax exemption of up to $250,000 of assessed valuation on a principal residence, with the state levy "reduced as necessary" so the exemption does not shift the burden to other property. It is the only tax instrument in his record. Chairs 1 and 2 require raising taxes on wealthy people and large companies; chair 3 requires keeping the system as-is while closing unfair loopholes; chairs 4 and 5 require cutting taxes AND scaling back public services to match, and a property tax relief measure states no service consequence — the same missing clause that blanked Ed Orcutt in migration 1764 and Deborah Krishnadasan in 1777. His remaining sponsorships are administrative rather than positional — volunteer firefighter deferred compensation, access to birth and death certificates, liquor licensing, captive insurers for public utility districts, public works board bonds, a ninth grade success grant program and foster youth support — and his co-sponsorships are almost entirely commemorative House resolutions, so no other ladder is reachable either.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Joint%20Resolutions/4207.pdf']);

DO $$
DECLARE ans_after int; ctx_after int; s record; nb int; stoke int;
BEGIN
  SELECT * INTO s FROM hr_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before THEN
    RAISE EXCEPTION 'guard 1: answers changed % -> %, this migration must write NONE', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 3 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +3', s.ctx_before, ctx_after; END IF;

  SELECT count(*) INTO nb
    FROM inform.politician_context c
   WHERE ((c.politician_id='2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd' AND c.topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c') OR (c.politician_id='2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd' AND c.topic_id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529') OR (c.politician_id='87a700d7-b217-4475-9366-53a4e04acb19' AND c.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb'))
     AND c.reasoning ~ '^Unable to place on this ladder'
     AND coalesce(cardinality(c.sources),0) >= 1
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF nb <> 3 THEN RAISE EXCEPTION 'guard 2: % documented blank(s), expected 3', nb; END IF;

  -- the deliberate absence is asserted, so a later pass cannot quietly "fix" it
  SELECT count(*) INTO stoke FROM inform.politician_context
   WHERE politician_id='9c1035b7-3372-4129-bca3-751b788b0999';
  IF stoke <> 0 THEN RAISE EXCEPTION 'guard 2: Stokesbary must have NO row — a blank would assert a ladder was tried'; END IF;
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

  RAISE NOTICE '3 documented blanks written; Stokesbary deliberately untouched; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
