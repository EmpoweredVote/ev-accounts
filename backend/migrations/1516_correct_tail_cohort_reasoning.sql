-- 1516_correct_tail_cohort_reasoning.sql
--
-- Correct 4 published stance rows whose reasoning misstated what the cited page says. NOTHING IS
-- RETIRED HERE and no stance VALUE changes -- only the text a voter reads and the sources it rests on.
--   Rollback record: data/stance-retirement/2026-08-01-tail-corrections-rollback.json
--   Review:          data/stance-retirement/2026-08-01-tail-hand-review.md
--
-- WHY THIS MATTERS MORE THAN THE GATE COUNTS. inform.politician_context.reasoning is VOTER-FACING --
-- Citations.jsx renders it under "Why this position?" and the compass card shows it in the stance
-- accordion. A quotation mark around words the source never said is a fabricated quote on a live
-- profile, regardless of whether the underlying stance is correct.
--
-- Civil Miller-Watkins: the row quoted "protect voting rights and election integrity". Her page says
--   "I will work to protect voting rights, increase civic participation, strengthen faith in our
--   elections and ensure government remains accountable to the people" -- two separate commitments
--   compressed into one quotation that appears nowhere. Replaced with the verbatim sentence, plus her
--   actual words on the John Lewis Voting Rights Act.
--
-- Johnny Baucom: the row said his survey "could not be directly retrieved (repeated access block), so
--   no verbatim quote is available". It retrieves fine, and it is far more specific than the
--   paraphrase: "income and property taxes are unconstitutional and reprehensible" and "the full
--   abolition of the IRS is the only proper step forward in American liberation". The stance value is
--   unchanged and the page supports it more strongly than the old text did.
--
-- Isaac Bryan: the row quoted "The solution to homelessness is housing." That sentence is not on the
--   cited page and no source for it was found, so it is REMOVED rather than re-attributed. AB 1685 is
--   confirmed his at leginfo -- "Assembly Bill No. 1685 Introduced by Assembly Member Bryan ...
--   Vehicles: parking violations" -- and is added as a source.
--
-- Carine Werner: SB1729 confirmed hers at azleg -- "REFERENCE TITLE: first-time homebuyer assistance
--   program ... Introduced by Senators Werner: Angius". Source added; reasoning already accurate.
--
-- 🔴 JARRETT KEOHOKALOLE WAS DROPPED FROM THIS MIGRATION. His row asserts he sponsored HI HB489 (2015).
-- The bill is real and its mechanism matches exactly -- it registers to vote everyone applying for a
-- driver's licence "unless that person affirmatively declines" -- but his NAME APPEARS NOWHERE in the
-- measure's 53,000-character status page, and the bill document's INTRODUCED BY line is a blank
-- signature placeholder. Adding a citation to a sponsorship the record does not show would lend the
-- row false authority, which is the exact failure this whole workstream exists to undo. Left for a
-- human with the evidence recorded.

BEGIN;

-- Civil Miller-Watkins / Voting Rights: quote compressed two separate sentences into one quotation
UPDATE inform.politician_context SET reasoning = 'Platform commits to ''protect voting rights, increase civic participation, strengthen faith in our elections and ensure government remains accountable to the people,'' and she describes herself as ''a strong supporter of the John Lewis Voting Rights Act,'' an expansive federal ballot-access and anti-discrimination measure. That places her at the more access-expanding end of the spectrum, absent an explicit automatic-registration or online-voting pledge.'
 WHERE politician_id = '0d2998fc-a952-4337-9c12-61d11d0a2506' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

-- Johnny Baucom / Taxes: reasoning claimed the survey could not be retrieved; it is on the cited page verbatim
UPDATE inform.politician_context SET reasoning = 'In his Ballotpedia Candidate Connection survey Baucom writes that ''income and property taxes are unconstitutional and reprehensible'' and that ''the full abolition of the IRS is the only proper step forward in American liberation.'' He lists taxation and deregulation among the policy areas he is most passionate about. That is a drastically-cut-taxes and shrink-government position.'
 WHERE politician_id = 'a8895322-9cf9-44ad-af0b-2be7e76c0c5d' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

-- Isaac Bryan / Housing: removes an unsourced quotation; adds the bill the claim actually rests on
UPDATE inform.politician_context SET reasoning = 'Bryan authored AB 1685 (2021-22), which relieves parking-ticket debt for unhoused people living in their vehicles, and has introduced legislation extending homelessness mandates to large California jurisdictions. That record reflects public investment in housing and rental assistance, consistent with stance 2 — publicly funded housing plus requirements that new developments include affordable units. He has not advocated government directly building and operating public housing as in stance 1.', sources = ARRAY['https://ballotpedia.org/Isaac_Bryan', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220AB1685']
 WHERE politician_id = '5cdd28b7-f8be-4968-bc1a-0e7928786980' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- Carine Werner / Housing: adds the bill the claim rests on; SB1729 confirmed as hers at azleg
UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Carine_Werner', 'https://www.azleg.gov/legtext/57leg/1R/bills/sb1729p.htm']
 WHERE politician_id = 'b769f53e-c9e5-4259-9e00-c20bfa945d15' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

DO $$
DECLARE
  v_bad int;
BEGIN
  -- The removed Bryan quotation must not survive anywhere in the corrected text.
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '5cdd28b7-f8be-4968-bc1a-0e7928786980' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
     AND reasoning ILIKE '%solution to homelessness is housing%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'Bryan row still carries the unsourced quotation';
  END IF;

  -- Both bill citations must be present.
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '5cdd28b7-f8be-4968-bc1a-0e7928786980' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
     AND NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%leginfo.legislature.ca.gov%');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Bryan row missing the AB 1685 citation'; END IF;

  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = 'b769f53e-c9e5-4259-9e00-c20bfa945d15' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
     AND NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%azleg.gov%');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Werner row missing the SB1729 citation'; END IF;
END $$;

COMMIT;
