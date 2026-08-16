-- 1783_wa_criminal_justice_reverse_1781.sql
-- Reverses migration 1781. The 12 senators it seated at `judicial-criminal-justice` chair 5 on
-- SB 5566 become 11 DOCUMENTED BLANKS plus one seating on different evidence: Matt Boehnke at
-- CHAIR 4, from the stated purpose of his own SB 6083.
--
-- ── ⚖ OPERATOR RULING, 2026-08-15: THE 1780 RULING DOES NOT GOVERN THE 4/5 PAIR ──────────────────
-- Migration 1781 extended "structure over inferred purpose" from the chair 1/3 pair to the chair 4/5
-- pair and flagged itself for review. The operator reviewed it and reversed. The facts in 1781 were
-- all confirmed on re-reading -- SB 5566 raises assault 3 on an officer from class C to class B,
-- moves it up the sentencing grid, adds a 180-day mandatory minimum for assault "in furtherance of a
-- riot or unlawful assembly", carries no findings and no intent section, and the bill's own sponsor
-- line names exactly the 12 members seated. The REASONING is what failed, in three places:
--
-- 1. IT REASONED FROM ABSENCE. 1781 refuted chair 3 because "the act has no support limb
--    whatsoever". That is incompleteness, and precedent 9b (migration 1771) says a chair is refuted
--    by CONTRADICTION, not by incompleteness.
--
-- 2. LOVICK IS THE COUNTEREXAMPLE, INSIDE THE SAME LADDER. He sits at chair 3 from migration 1780
--    while holding two penalty-increase instruments. So "the act punishes the behavior, therefore
--    chair 5" is a predicate his record also satisfies. Chair 5's first clause is true of every
--    penalty provision in the criminal code and cannot discriminate anything. What actually decided
--    1780 was a POSITIVE, ELEMENT-BY-ELEMENT match between the second-look mechanism and chair 3's
--    three clauses -- time served, the petition, the exclusions -- not a general rule that structure
--    beats purpose. 1781 generalised the label rather than the reasoning.
--
-- 3. CHAIR 5's DISCRIMINATING CLAUSE IS ITSELF A PURPOSE. "Society needs to know that breaking the
--    law has real consequences" is a claim about the message sent to the public -- the same order of
--    inference 1781 correctly refused to make for chair 4's "making sure others think twice". Strip
--    it and only the non-discriminating half of chair 5 remains.
--
-- 🔑 THE SCOPE OF THE 1780 RULING, RESTATED SO IT IS NOT EXTENDED AGAIN. "Structure over inferred
-- purpose" resolves a purpose-free mechanism against a chair whose TEXT THE MECHANISM INSTANTIATES
-- CLAUSE BY CLAUSE. It is not a tiebreaker that sends purposeless instruments to whichever chair
-- reads as more structural. Where no chair is positively matched, precedent 1 governs and the
-- fallback is BLANK.
--
-- ── ✅ MATT BOEHNKE IS SEATED AT CHAIR 4 ON A STATED PURPOSE ─────────────────────────────────────
-- The 1780 ruling has a boundary -- where an act STATES its purpose, the stated purpose governs --
-- and exactly one of the twelve holds an instrument that does. SB 6083 (2026, Boehnke sole sponsor)
-- removes a court's ability to waive restitution owed to a postsecondary institution, and its §1
-- states why: a threat to public safety from "organized groups under the guise of political speech",
-- and it "has become necessary to protect the property and persons of its citizens". That is
-- prospective and aimed at people not before the court, which is chair 4. Note this cuts AGAINST
-- 1781: the one testable case among the twelve points at the chair the tiebreaker ruled out.
-- ⚠ Recorded weakness: this is a single-instrument seating resting on an intent section. If a later
-- reader reads "protect the property and persons" as a generic public-safety finding rather than a
-- discouragement rationale, this is the row to move -- and it moves to a blank, not to chair 5.
--
-- ── 🔎 THE FULL RE-SCREEN, AND WHY IT PRODUCED NO OTHER SEATING ──────────────────────────────────
-- Every one of the twelve had their whole criminal justice record re-read, not just the five
-- instruments 1781 screened. Four findings worth keeping:
--   · SB 5267 (Wagoner, prime -- the death penalty for murder committed while incarcerated) is the
--     closest thing in the corpus to a stated purpose on this ladder, and it STILL cannot
--     discriminate: it directs the review panel to weigh "whether imposition of the death penalty
--     measurably contributes to the core purposes of retribution and deterrence" -- chair 5's value
--     and chair 4's value, named together as co-equal criteria, with neither ranked, alongside
--     mitigating circumstances "to merit leniency". This is the single best piece of evidence that
--     the 4/5 pair is not discriminable, and it is now logged in the trouble-spot file.
--   · SB 6022 (Christian prime, J. Wilson co) is a fifth confirmed title trap. It is captioned
--     "improving juvenile rehabilitation" and it REPEALS the JR-25 policies outright. Its §1 argues
--     cost ($257,000 per person at DCYF against $76,000 at corrections) and violence and contraband
--     at Green Hill School -- an efficacy and fiscal argument, not a position on what matters when
--     someone breaks the law. It reaches no chair, and it does NOT give Christian a chair-3 support
--     limb.
--   · SB 5644 (Wagoner) is titled "deterring criminal conduct involving gift cards" and has no
--     findings and no intent section. Precedent 12 forbids seating from a title, so it stays off.
--   · SB 5646 (Harris, prime -- penalties for assaulting outreach workers) is co-sponsored by
--     Senators Cleveland and Hasegawa, both Democrats. That is 1781's own unanimity disqualifier in
--     a weaker form: a measure drawn from both caucuses demonstrates no preference among the
--     competing values this ladder asks about.
--
-- Coverage effect: 136 of 147 covered becomes 131. King, Holy, Torres, Harris and Dozier return to
-- uncovered; Boehnke stays covered on chair 4. That is the honest number -- see the standing note in
-- COMPASS-LADDER-TROUBLE-SPOTS.md that a blank reads to a coverage-hungry session as "not yet
-- researched", which is exactly what these eleven rows are now protected against.
BEGIN;

CREATE TEMP TABLE cj_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

-- The 12 pairs migration 1781 wrote. Kept for the DELETE, the orphan guard and the content guards.
CREATE TEMP TABLE cj_rev (pid uuid, tid uuid, nm text, seated boolean) ON COMMIT DROP;
INSERT INTO cj_rev (pid, tid, nm, seated) VALUES
('fec68f5f-c9e1-4579-869a-7b4a78f7da90','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Curtis King',      false),
('d0350f2f-6463-452e-b97d-c18ea094e2ee','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Jeff Holy',        false),
('aadf55f0-a4b4-4a4a-acf0-bfce06815149','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Jeff Wilson',      false),
('6cc4c706-fa7a-486f-ac67-6cbdede4a607','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Jim McCune',       false),
('f3cd74bb-3bdb-4d55-a07d-5c14bda50926','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Keith Goehner',    false),
('3db3f064-dd6e-4bca-9200-3d4395972253','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Keith Wagoner',    false),
('0e935fed-534e-42b0-a5ad-74f4199ff6df','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Leonard Christian',false),
('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Matt Boehnke',     true),
('624622d4-ce11-4fa3-9f0b-89c47559d1c6','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Nikki Torres',     false),
('c4e1312c-e746-483e-a3ec-f27bc40b6d26','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Paul Harris',      false),
('4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Perry Dozier',     false),
('d3fad6d8-8022-4c66-b505-4e7a8fc816d7','9db07b16-1076-4b7d-ad89-ebe7b51f4336','Phil Fortunato',   false);

DO $$
DECLARE n int;
BEGIN
  -- 1781's rows must be exactly as it left them, or this is not the reversal that was reviewed.
  SELECT count(*) INTO n
    FROM cj_rev t
    JOIN inform.politician_answers a ON a.politician_id=t.pid AND a.topic_id=t.tid
   WHERE a.value = 5;
  IF n <> 12 THEN RAISE EXCEPTION 'pre-check: expected 12 chair-5 answers from migration 1781, found %', n; END IF;

  SELECT count(*) INTO n
    FROM cj_rev t
    JOIN inform.politician_context c ON c.politician_id=t.pid AND c.topic_id=t.tid
   WHERE 'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf' = ANY(c.sources);
  IF n <> 12 THEN RAISE EXCEPTION 'pre-check: expected 12 context rows citing SB 5566, found %', n; END IF;

  -- Tripwires. The whole reversal is an argument about the WORDING of chairs 4 and 5; if either is
  -- reworded the argument has to be made again rather than inherited.
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=4 AND text ILIKE '%think twice%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: chair 4 is no longer the "think twice" chair -- re-argue before reversing'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=5 AND text ILIKE '%real consequences%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: chair 5 is no longer the "real consequences" chair -- re-argue before reversing'; END IF;

  -- inform.politician_context_evidence CASCADEs on a context delete. These 12 pairs have no evidence
  -- rows today, so the delete-and-rewrite below destroys nothing; assert it rather than assume it.
  SELECT count(*) INTO n
    FROM cj_rev t
    JOIN inform.politician_context_evidence e ON e.politician_id=t.pid AND e.topic_id=t.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % evidence row(s) would be cascaded away by the context delete', n; END IF;

  -- Lovick at chair 3 is load-bearing: he is the counterexample that shows a penalty increase does
  -- not imply chair 5. If migration 1780's row has moved, reason 2 in the header no longer holds.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id=(SELECT id FROM essentials.politicians WHERE full_name='John Lovick')
     AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: John Lovick is no longer at chair 3 -- the reversal argument depends on him'; END IF;
END $$;

DELETE FROM inform.politician_answers a USING cj_rev t
 WHERE a.politician_id=t.pid AND a.topic_id=t.tid;

DELETE FROM inform.politician_context c USING cj_rev t
 WHERE c.politician_id=t.pid AND c.topic_id=t.tid;

-- ── the 11 documented blanks ─────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('fec68f5f-c9e1-4579-869a-7b4a78f7da90','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. Also screened: SSB 5323 (penalties for theft of stolen property from first responders, enacted, no findings or intent section), SB 5705 (traffic infraction penalty amounts) and SB 5484 (payments to tow truck operators for release of vehicles to indigent owners). None states a purpose.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('d0350f2f-6463-452e-b97d-c18ea094e2ee','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. Also screened: SB 5333 (penalties for eluding police vehicles and resisting arrest), SSB 5323, SB 6340 (residential restrictions for conditional release to a less restrictive alternative) and SB 5705. All are further enhancements or release restrictions and none states a purpose.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('aadf55f0-a4b4-4a4a-acf0-bfce06815149','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. Also screened: SB 6022, which he co-sponsored. Its title reads "improving juvenile rehabilitation" and its operative effect is to repeal the JR-25 policies outright; §1 argues cost -- approximately $257,000 per incarcerated individual at the department of children, youth, and families against approximately $76,000 at the department of corrections -- together with violence and contraband at Green Hill School. That is an efficacy and fiscal argument, not a position on what matters when someone breaks the law, so it reaches no chair. Also SB 5274 (body worn cameras in corrections), SB 5295 (sexual assault survivor bill of rights), SSB 5323 and SB 6031.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf',
       'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6022.pdf']),
('6cc4c706-fa7a-486f-ac67-6cbdede4a607','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Prime sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. Prime sponsorship does not change the reading -- authorship and co-sponsorship carry the same weight in this corpus, and the act still states no purpose. His only other criminal justice instrument is SB 5818 (transfer of certain individuals in the custody of the department of corrections), which bears on immigration enforcement rather than on this question.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('f3cd74bb-3bdb-4d55-a07d-5c14bda50926','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. His criminal justice record is three instruments in total: this one, SSB 5323 and SB 5218 (motor vehicle and driver licensing definitions). None states a purpose.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('3db3f064-dd6e-4bca-9200-3d4395972253','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. His own SB 5267, which would allow the death penalty to be sought for aggravated first degree murder committed while already serving a term of incarceration, comes closer to a stated purpose than anything else in the corpus and still cannot discriminate: it directs the review panel to consider "whether imposition of the death penalty measurably contributes to the core purposes of retribution and deterrence of capital crimes by prospective offenders", naming chair 5's value and chair 4's value together as co-equal criteria and ranking neither, alongside "whether there are sufficient mitigating circumstances to merit leniency" and "the goal of fairness and consistency in the criminal justice system". Also screened: SB 5644, titled "deterring criminal conduct involving gift cards" but carrying no findings and no intent section, so the title alone cannot seat it; SB 5843, SB 5223 and SB 5366.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf',
       'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5267.pdf']),
('0e935fed-534e-42b0-a5ad-74f4199ff6df','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. He has the largest criminal justice record of the twelve and none of it states a purpose. His SB 6022 is captioned "improving juvenile rehabilitation" and repeals the JR-25 policies outright, arguing in §1 from cost -- approximately $257,000 per incarcerated individual at the department of children, youth, and families against approximately $76,000 at the department of corrections -- and from violence and contraband at Green Hill School, which is an efficacy and fiscal argument rather than a position on what matters when someone breaks the law, so it supplies no chair-3 support limb. His SB 5760 establishes a colocated community facility and work release centre in the general administration building on the capitol campus, and its stated purpose is proximity to elected officials rather than reentry. Also screened: SB 5255, SB 5256, SB 5257, SB 5499 and SB 5530.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf',
       'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6022.pdf',
       'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5760.pdf']),
('624622d4-ce11-4fa3-9f0b-89c47559d1c6','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. Also screened: her own SB 6249 (department of corrections supervision of individuals convicted of stalking) and SB 6340 (residential restrictions for conditional release to a less restrictive alternative), plus SB 5333, SB 6301 and SSB 5323. All are supervision or enhancement instruments and none states a purpose.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('c4e1312c-e746-483e-a3ec-f27bc40b6d26','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. His entire criminal justice record is two bills: this one and his own SB 5646, criminal penalties for assaulting outreach workers, which applies the same mechanism to a different class of victim and is co-sponsored by Senators Cleveland and Hasegawa, both of the other caucus. A measure drawn from both caucuses demonstrates no preference among the competing values this ladder asks about.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf',
       'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5646.pdf']),
('4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. Also screened: SB 5277, the repeal of the juvenile rehabilitation to 25 legislation, which carries no findings and no intent section and so states no reason of its own; plus SB 5333, SB 6249, SB 6301, SB 6340, SB 5274, SB 5843 and SSB 5323. None states a purpose.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf',
       'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5277.pdf']),
('d3fad6d8-8022-4c66-b505-4e7a8fc816d7','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Co-sponsor of SB 5566 (2025), which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and require a minimum term of 180 days total confinement for assaulting an officer "in furtherance of a riot or unlawful assembly". The act was read in full and contains no findings and no intent section. A penalty increase that states no purpose cannot discriminate chairs 3, 4 and 5: chair 5's first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code, and its second clause, "society needs to know that breaking the law has real consequences", is a claim about the message sent to the public that the act nowhere makes, of the same order as the inference chair 4 would require. Chair 3 is not refuted, because adding accountability without a support limb is incompleteness rather than contradiction. Chairs 1 and 2 are unevidenced: the act carries no rehabilitation, treatment, diversion or restitution provision. Also screened: his own SB 5347 and SB 5348 (organized retail theft and a sentencing enhancement for it), SB 5530 (penalty increases for certain offenses), SB 5846 and SB 5830, plus SB 5267. Every one is a further enhancement, which reinforces the direction of his record without discriminating a chair on it.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']);

-- ── Matt Boehnke, chair 4, on SB 6083's stated purpose ───────────────────────────────────────────
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Sole sponsor of SB 6083 (2026), which removes a court's ability to waive restitution when the restitution is owed to a postsecondary institution. Alone among his criminal justice instruments, this act states its own purpose. Section 1 finds that "a threat to the public safety and welfare exists due to recent actions by organized groups under the guise of political speech", that "acts of vandalism and violence have occurred", and that while the legislature "applauds and affirms the constitutional rights of peaceful protesters" it "has become necessary to protect the property and persons of its citizens" -- and it is "in furtherance of this goal" that the act narrows the waiver. That rationale is prospective and directed at people who are not before the court, which is chair 4's "making sure others think twice before doing the same thing"; the act's own title states its object as "discouraging violent protests at postsecondary institutions", agreeing with §1 rather than pointing away from it. Chair 5 is not reached: nothing in the act says the offender deserves the sanction, and its stated aim is protecting property and persons in the future rather than punishment for its own sake. Chair 2 is refuted despite naming restitution verbatim, because the act makes restitution non-waivable even where the court finds the offender "does not have the current or likely future ability to pay", which is the opposite of giving the person a fair chance to make things right. Chairs 1 and 3 are unevidenced. He also co-sponsored SB 5566, a penalty increase for assaulting a law enforcement officer that states no purpose; it leaves chair 4 true rather than contradicting it.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6083.pdf',
       'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 4);

-- @context-decision: rewritten-as-blank — 11 of the 12 rows keep their topic and were re-read in full, so each is rewritten as a documented blank naming SB 5566 and the clause that failed; the twelfth (Boehnke) is re-seated at chair 4 on SB 6083 and its reasoning replaced accordingly.

-- GUARD: the answers deleted above must not leave gate-visible orphan context behind. This is
-- check-stance-sources.mjs's ORPHAN_CONTEXT predicate -- including its `pa.politician_id IS NULL`
-- leg, which the template omits because it assumes every deleted pair stays answerless; here one
-- pair is deliberately re-answered, and without that leg the guard would fire on Boehnke's new row.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM cj_rev t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';

  IF new_orphans > 0 THEN
    RAISE EXCEPTION
      'context guard: % row(s) lost their answer but kept reasoning that still describes a position. '
      'Delete that context, or rewrite it as a documented blank, IN THIS MIGRATION -- not later.',
      new_orphans;
  END IF;
END $$;

DO $$
DECLARE ans_after int; ctx_after int; s record; n int;
BEGIN
  SELECT * INTO s FROM cj_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  -- 12 answers removed, 1 written back.
  IF ans_after <> s.ans_before - 11 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected -11', s.ans_before, ans_after; END IF;
  -- 12 context rows replaced by 12 context rows.
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected no net change', s.ctx_before, ctx_after; END IF;

  -- The eleven blanks: no answer, the carve-out phrase, the clause each was read against, and SB 5566.
  SELECT count(*) INTO n
    FROM cj_rev t
    JOIN inform.politician_context c ON c.politician_id=t.pid AND c.topic_id=t.tid
   WHERE t.seated = false
     AND c.reasoning ~ '^Unable to place on this ladder'
     AND c.reasoning ~ 'no findings and no intent section'
     AND c.reasoning ~ 'incompleteness rather than contradiction'
     AND 'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf' = ANY(c.sources)
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF n <> 11 THEN RAISE EXCEPTION 'guard 2: % complete documented blank(s), expected 11', n; END IF;

  -- Assert the OTHER side separately: a bug that blanked all twelve still satisfies the count above.
  SELECT count(*) INTO n
    FROM cj_rev t
    JOIN inform.politician_answers a ON a.politician_id=t.pid AND a.topic_id=t.tid
    JOIN inform.politician_context c ON c.politician_id=t.pid AND c.topic_id=t.tid
   WHERE t.seated = true
     AND a.value = 4
     AND c.reasoning ~ 'discouraging violent protests'
     AND c.reasoning ~ 'protect the property and persons'
     AND c.reasoning !~ '^Unable to place'
     AND 'https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6083.pdf' = ANY(c.sources);
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: % seated chair-4 row(s) for Boehnke, expected 1', n; END IF;

  -- Nothing from migration 1781 survives at chair 5.
  SELECT count(*) INTO n
    FROM cj_rev t
    JOIN inform.politician_answers a ON a.politician_id=t.pid AND a.topic_id=t.tid
   WHERE a.value = 5;
  IF n <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-5 row(s) survived the reversal, expected 0', n; END IF;

  -- Migration 1780 is untouched: this reverses 1781 only.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=3;
  IF n < 12 THEN RAISE EXCEPTION 'guard 2: migration 1780 chair-3 rows are down to %, expected at least 12', n; END IF;
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

  RAISE NOTICE 'judicial-criminal-justice: migration 1781 reversed -- 11 documented blanks, Boehnke at chair 4; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
