-- Migration 1921 — re-seat 9 chairs and withdraw 13 from the REPAIRED-CHAIRS queue.
--
-- WHAT THIS IS. Every voter-facing row in the national generic-sourcing remainder whose Season 2
-- reasoning carries the citation-repair marker from migrations 1909 / 1911 / 1913 ("Citation
-- repaired … THE CHAIR IS UNCHANGED"). 40 rows / 21 people, all read by hand.
-- **17 KEEP · 9 RE-SEAT · 13 BLANK · 1 citation repair → 22 of 40 defective = 55.0%** (CI 40-69%).
-- Ledger: data/stance-research/2026-10-20-repaired-chairs/LEDGER.md
--
-- ⚖⚖ THIS IS THE CHAIR PASS A REPAIR IS NOT ALLOWED TO DO. The rule "a repair must not move a
-- chair" is right, and its consequence was never queued: a repair fixes the citation and leaves the
-- seating untouched, so a row with a wrong chair comes out of the pass LOOKING SOURCED and nothing
-- flags it afterwards. These 40 are the backlog that rule created.
--
-- 🔑 THE REMEDY IS MOSTLY A RE-SEAT, NOT A BLANK — 9 of 22. That is the opposite of the
-- caucus-only queue (migration 1920), where 60 of 60 defects blanked. The reason is structural: a
-- repaired row HAS evidence, and what failed is the MAPPING. Blanking those would throw away good
-- research. Disposition follows the held-row playbook (migration 1913): re-read against the Season 2
-- ladder, re-seat where a rung describes the evidence, blank only where no rung asks the question.
--
-- THE INSERTED-RUNG PROBE WAS RUN FIRST. Eight rows carry a value that changed between seasons;
-- every topic's S1 and S2 ladders were compared rung by rung and there is NO literal renumbering
-- anywhere, so those eight are deliberate moves rather than artefacts. ⚠ But the probe tests TEXT
-- equality, and `same-sex-marriage` turns out to have had a SEMANTIC +1 insertion the probe scored
-- as "rewritten" — S1 rung 1 is now S2 rung 2, and S2 rung 1 is a genuinely new top rung. The
-- earlier passes remapped all six SSM rows correctly. A future probe needs a meaning test.
--
-- 🔴 FOUR FINDINGS ABOUT THE REPAIR PASSES THEMSELVES
-- 1. A REPAIR SKIPPED A DEDICATED POLICY SECTION ON THE PAGE IT WAS READING. Kathy Tran's page
--    carries "== Policy positions == === Abortion ===", recording that she introduced the Repeal
--    Act, cutting the physicians required to approve a third-term abortion from three to one and
--    lowering the threshold to "any medical reason". The repair quoted a campaign attack line
--    instead. The instrument puts her at rung 1, not 2. (R28)
-- 2. A REPAIR ATTRIBUTED AN EMPLOYER'S PLATFORM TO THE PERSON. Briana Sewell's page says she worked
--    for "Campaign for a Family Friendly Economy, AN ORGANIZATION THAT ADVOCATES FOR … affordable
--    healthcare". The page carries no statement of her own on healthcare at all. (R02)
-- 3. A SEASON REMAP MOVED A CHAIR ONTO A RUNG THAT NEGATES ITS OWN EVIDENCE. Eunisses Hernandez
--    pushed LA to build a large-scale SOCIAL HOUSING programme. S1 rung 2 included "publicly fund
--    new housing" and fitted. S2 rung 3 reads "BUILD NO PUBLIC HOUSING, but set binding rules". The
--    remap left her asserting the opposite of her own record. (R12)
-- 4. 🔴 THE SAME ROLL-CALL VOTE SEATS TWO DIFFERENT RUNGS. Hernandez and Soto-Martinez both voted
--    against the LAPD raises package; both rows cite it; the quoted argument — the money "would pull
--    money away from mental health clinicians, homeless outreach workers" — is rung 1 word for word.
--    Hernandez sits at 1 (sound); Soto-Martinez sat at 2 and moves here. Two rows citing one vote
--    cannot both be right, and nothing in the corpus compares them.
--
-- ⚠ SIX PAGES WERE FETCHED where the call turned on them, and three more for repair attempts; no
-- call rests on a search summary. The fetches changed four calls. 🔴 My first search of them was
-- BUGGY — a grep demanding 200 characters on both sides of a match silently dropped hits near a
-- line start, and I was one step from recording Chyanne Chen's row as a composed citation. Her
-- quote IS on the page, and the page carries MORE than the repair claimed: she VOTED against the
-- upzoning rather than merely criticising it. A false negative from your own matcher is the
-- dangerous direction.
--
-- ▶ TWO REPAIRS WERE ATTEMPTED INSTEAD OF BLANKS, as asked, and they came out differently.
--    VanValkenburg/housing SUCCEEDED — a second enacted zoning instrument on the same page means
--    rung 5's "at most, cut the regulations" is established after all, so the chair STANDS and only
--    the citation changes (handled separately below; a repair must not move a chair, and it does
--    not). Grove/abortion FAILED to rescue the chair — the page's own reference identifies the
--    unnamed bill as a 2014 sex-selective abortion ban, which is real and directional but states no
--    EXCEPTION FRAMEWORK, which is what rung 4 turns on. Zbur/same-sex-marriage FAILED for want of a
--    source: the word "marriage" appears nowhere on his cited page, nor on his Ballotpedia page, and
--    the Proposition 3 page names no authors. He very likely co-authored ACA-5, but an unfetched
--    claim is not a citation. Blanked and routed to re-research.
--
-- 🔑 WHY SEASON 2. Season 1 is closed and is not touched. A re-seat writes the new value into the
-- Season 2 answer that already exists; a blank writes 0, which SUPPRESSES (NULLIF(pa.value, 0)).
-- Every row in this queue already serves from Season 2, so all 22 are UPDATEs, not inserts.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards below fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1921_decisions (
  politician_id     uuid   NOT NULL,
  topic_id          uuid   NOT NULL,
  topic_revision_id uuid   NOT NULL,
  new_value         int    NOT NULL,
  reasoning         text   NOT NULL,
  ledger_no         text   NOT NULL
) ON COMMIT DROP;

INSERT INTO mig1921_decisions
  (politician_id, topic_id, topic_revision_id, new_value, reasoning, ledger_no)
VALUES
-- R04  Carl DeMaio / same-sex-marriage  3 -> 2
('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,2,'CHAIR MOVED 3 -> 2 (migration 1921, ledger row R04). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 3, reads "Allow same-sex marriage, but protect religious organizations'' right to decline to perform or host these marriages.". The seat it takes, rung 2, reads "Guarantee same-sex marriage the same benefits and protections as any other marriage.". WHY: DeMaio/same-sex-marriage 3 -> 2: FETCHED. The words ''religious'' and ''exemption'' DO NOT APPEAR ON THE PAGE, so rung 3''s distinguishing clause has no support at all. What the page does carry is his announced support for same-sex marriage, his same-sex partner in a 2014 campaign ad, and a Log Cabin Republicans endorsement - which is rung 2. He is himself gay and married; seating him at a religious-carve-out rung is a substantive error, not a technicality. Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R04'),
-- R05  Chyanne Chen / growth-and-development  2 -> 1
('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,'65e8ffd5-5aac-4d40-8862-a321949eafa4'::uuid,1,'CHAIR MOVED 2 -> 1 (migration 1921, ledger row R05). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 2, reads "Allow growth only as fast as current infrastructure can handle — make new development wait for capacity.". The seat it takes, rung 1, reads "Hold the pace of growth down — cap major new development, and let residents vote directly on the largest projects.". WHY: Chen/growth-and-development 2 -> 1: FETCHED. The page carries MORE than the repair claimed - she VOTED AGAINST the December 2025 bill to upzone 60% of San Francisco, and is quoted at length. ''infrastructure'' and ''capacity'' DO NOT APPEAR, so rung 2''s distinguishing clause is unsupported. Her vote to block the largest upzoning plus ''doing things to our communities, not with our communities'' is rung 1 - holding the pace down with residents having a say. JUDGMENT CALL: her stated reason is process and affordability, not pace. Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R05'),
-- R11  Eunisses Hernandez / growth-and-development  2 -> 1
('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,'65e8ffd5-5aac-4d40-8862-a321949eafa4'::uuid,1,'CHAIR MOVED 2 -> 1 (migration 1921, ledger row R11). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 2, reads "Allow growth only as fast as current infrastructure can handle — make new development wait for capacity.". The seat it takes, rung 1, reads "Hold the pace of growth down — cap major new development, and let residents vote directly on the largest projects.". WHY: Hernandez/growth-and-development 2 -> 1: her own quoted words are ''My plan to fight gentrification is to be the biggest barrier I can to luxury and market-rate development.'' That is rung 1, holding the pace of growth down - not rung 2''s infrastructure pacing, a rationale she never gives. Rung 1''s referendum clause is not evidenced; it is the nearest rung on a single-choice ladder and the new reasoning says so. Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R11'),
-- R12  Eunisses Hernandez / housing  3 -> 2
('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'598c879d-f387-461c-9120-fbbbf6314bbc'::uuid,2,'CHAIR MOVED 3 -> 2 (migration 1921, ledger row R12). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 3, reads "Build no public housing, but set binding rules on the private market like rent caps or required affordable units.". The seat it takes, rung 2, reads "Build a large public housing sector that competes with the private market to hold prices down, while private housing stays the norm.". WHY: Hernandez/housing 3 -> 2: 🔴 THE SEASON REMAP MOVED HER ONTO A RUNG THAT NEGATES HER OWN EVIDENCE. S1 rung 2 read ''rent caps, required affordable units, AND PUBLICLY FUND NEW HOUSING'' - correct for her, since she pushed the city to build a large-scale SOCIAL HOUSING programme. S2 rung 3 reads ''BUILD NO PUBLIC HOUSING, but set binding rules''. The remap dropped the public-funding limb and left her asserting the opposite of what she campaigned for. S2 rung 2 - ''build a large public housing sector'' - is exactly social housing. Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R12'),
-- R24  Hugo Soto-Martinez / jail-capacity  2 -> 1
('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid,'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid,'f63a4e70-055e-4115-a5e0-3deeb5748816'::uuid,1,'CHAIR MOVED 2 -> 1 (migration 1921, ledger row R24). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 2, reads "Reducing the incarcerated population through pretrial diversion, bail reform, and treatment alternatives rather than building new capacity". The seat it takes, rung 1, reads "Redirecting incarceration funding into community-based mental health, addiction, housing, and restorative justice programs to shrink the jail system". WHY: Soto-Martinez/jail-capacity 2 -> 1: his evidence is supporting Measure J, which allocates at least 10% of county funding to community reinvestment and alternatives to incarceration. That IS rung 1''s text - redirecting incarceration funding into community programmes. Rung 2 is about diversion and bail mechanisms he is not shown advocating. Hernandez sits at rung 1 on the same measure (R13). Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R24'),
-- R25  Hugo Soto-Martinez / public-safety-approach  2 -> 1
('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid,'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid,1,'CHAIR MOVED 2 -> 1 (migration 1921, ledger row R25). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 2, reads "Maintain current police staffing but shift non-violent calls to unarmed mental health co-responders". The seat it takes, rung 1, reads "Redirect a significant portion of the police budget to social services, mental health, and community programs". WHY: Soto-Martinez/public-safety-approach 2 -> 1: 🔴 THE SAME ROLL-CALL VOTE SEATS TWO DIFFERENT RUNGS. He voted against the police raises arguing they would ''pull money away from mental health clinicians, homeless outreach workers'' - that is rung 1, redirecting police budget to social services, word for word. Hernandez''s row (R15) cites the SAME vote and is seated at 1. Rung 2 asserts maintaining staffing with co-responders, which neither of them says. Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R25'),
-- R28  Kathy KL Tran / abortion  2 -> 1
('f224a300-8b54-4b57-b988-5c340667f99b'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid,1,'CHAIR MOVED 2 -> 1 (migration 1921, ledger row R28). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 2, reads "keep abortion legal and accessible through the second trimester with rare exceptions afterward.". The seat it takes, rung 1, reads "ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy.". WHY: Tran/abortion 2 -> 1: 🔴 FETCHED, AND THE REPAIR SKIPPED A DEDICATED POLICY SECTION ON THE PAGE IT WAS READING. The page carries ''== Policy positions == === Abortion ==='' recording that she introduced the REPEAL ACT, cutting the physicians required to approve a third-TERM abortion from three to one and lowering the threshold to ''any medical reason''. That is rung 1''s ''at all stages''; her Planned Parenthood funding quote supplies rung 1''s funding limb. The repair quoted the campaign line and left the instrument on the table. Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R28'),
-- R32  Marqueece Harris-Dawson / redistricting  1 -> 2
('ece32bfa-26de-4177-9bb3-cea506870747'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid,2,'CHAIR MOVED 1 -> 2 (migration 1921, ledger row R32). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 1, reads "independent citizens'' commissions with no elected officials involved at any level.". The seat it takes, rung 2, reads "independent redistricting commissions with equal representation from both major parties.". WHY: Harris-Dawson/redistricting 1 -> 2: FETCHED. The page says he ''advocated for an INDEPENDENT REDISTRICTING COMMISSION by opening up the charter for full reform''. The words ''citizens'' and ''elected officials'' DO NOT APPEAR, so rung 1''s ''no elected officials involved at any level'' is unsupported - while rung 2''s headline, ''independent redistricting commissions'', is the page''s own phrase. Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R32'),
-- R36  R. Creigh Deeds / same-sex-marriage  3 -> 2
('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,2,'CHAIR MOVED 3 -> 2 (migration 1921, ledger row R36). This is a RE-SEAT, not a citation repair: the chair itself changes. The seat it leaves, rung 3, reads "Allow same-sex marriage, but protect religious organizations'' right to decline to perform or host these marriages.". The seat it takes, rung 2, reads "Guarantee same-sex marriage the same benefits and protections as any other marriage.". WHY: Deeds/same-sex-marriage 3 -> 2: his recorded 2006 vote against the Virginia constitutional amendment banning same-sex marriage is opposition to a ban, which is rung 2''s territory; rung 3''s religious-exemption clause is unevidenced and was carried through the remap from an S1 rung that also asserted it. ⚠ VINTAGE: a 2006 basis for a sitting senator - the re-seat is provisional and the row routes to re-research. Reviewed in the repaired-chairs pass over rows an earlier citation repair left seated (migrations 1909/1911/1913), which were forbidden from moving a chair.','R36'),
-- R02  Briana D. Sewell / healthcare  (was 2, EMPLOYER)
('77ce6e63-7379-4c8a-9038-5c708510d6cc'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: EMPLOYER''S PLATFORM - an organisation the person worked for is quoted as if it were the person. WHY: Sewell/healthcare: FETCHED. The page says she worked for ''Campaign for a Family Friendly Economy, AN ORGANIZATION THAT ADVOCATES FOR ... affordable healthcare''. The repair attributed her former EMPLOYER''s platform to her. The page carries no ''she supports'' or ''she advocates'' anywhere, and ''affordable healthcare'' seats no rung in any case. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R02.','R02'),
-- R07  David Chiu / local-environment  (was 2, OFFAXIS)
('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'::uuid,'1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid,'d67eabf7-8da0-4ca7-b2af-74745b3bfd47'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: OFF AXIS - the evidence is the person''s own and checkable, and it answers a different question from the one this ladder asks. WHY: Chiu/local-environment: a nail-salon worker-safety programme and AB 546, which streamlines SOLAR PERMITTING. Neither is about the burden on development to prove it will not damage the environment, which is rung 2. AB 546 arguably leans the other way. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R07.','R07'),
-- R09  Elizabeth R. Guzman / healthcare  (was 2, OFFAXIS)
('cea4db8b-acb5-4ebb-be09-e731d4412249'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: OFF AXIS - the evidence is the person''s own and checkable, and it answers a different question from the one this ladder asks. WHY: Guzman/healthcare: collective bargaining and paid sick leave for home health care WORKERS is labour policy. This ladder asks about COVERAGE. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R09.','R09'),
-- R17  Eunisses Hernandez / transportation-priorities  (was 1, AFFIRM)
('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid,'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid,'c48782d5-e905-408d-8532-2a5fd5bb6efa'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: NO POSITION - what is offered is a salience or activity claim, not a direction on this axis. WHY: Hernandez/transportation-priorities: speaking at a bus-shade launch, funding a traffic STUDY, and ''took part in the council''s handling of'' a gondola proposal. None of these is a position, and rung 1 is the ladder''s end rung. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R17.','R17'),
-- R26  Hugo Soto-Martinez / taxes  (was 2, OFFAXIS)
('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,'87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: OFF AXIS - the evidence is the person''s own and checkable, and it answers a different question from the one this ladder asks. WHY: Soto-Martinez/taxes: opposing a budget that cut every department except the LAPD is a SPENDING position. This ladder asks about tax rates, and the row says nothing about them. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R26.','R26'),
-- R30  Marcus B. Simon / redistricting  (was 2, DUTY)
('c490eece-71f4-4051-975d-8fa5ed5f652b'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: OFFICE DUTY - serving in a role is offered as advocating for it. WHY: Simon/redistricting: being APPOINTED to the 2021 Virginia Redistricting Commission is an office duty, not a position. Serving on a commission is not advocating for commissions. STANDARD.md step 1(a). Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R30.','R30'),
-- R31  Marqueece Harris-Dawson / economic-development  (was 2, RUNGTEXT)
('ece32bfa-26de-4177-9bb3-cea506870747'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: RUNG TEXT - the evidence is real and on-axis, and the seated rung''s own wording describes something it does not show. WHY: Harris-Dawson/economic-development: FETCHED and confirmed - $1.7bn leveraged for streetscapes, and a Senior Meals Program supporting 32 local businesses. The infrastructure figure is rung 1''s positive clause and the meals programme is rung 2''s, while BOTH rungs turn on a negative commitment about subsidies to outside companies that he has never made. The evidence does not discriminate. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R31.','R31'),
-- R33  Michelle Rodriguez / healthcare  (was 2, RUNGTEXT)
('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: RUNG TEXT - the evidence is real and on-axis, and the seated rung''s own wording describes something it does not show. WHY: Rodriguez/healthcare: ''her legislative priorities included advancing universal healthcare'' - a priority-list entry, and ''universal healthcare'' is ambiguous between rung 1 (public sector) and rung 2 (universal coverage through a mix). It establishes neither. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R33.','R33'),
-- R34  Michelle Rodriguez / homelessness  (was 2, AFFIRM)
('108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid,'4938766b-b45a-46e3-93bd-b8b30651271a'::uuid,'6958fa99-e317-45d7-8076-d11a0a78c897'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: NO POSITION - what is offered is a salience or activity claim, not a direction on this axis. WHY: Rodriguez/homelessness: ''her legislative priorities included addressing homelessness.'' That is a salience claim with no direction whatever, and it is seated at a rung asserting decriminalisation. The clearest defect in the queue. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R34.','R34'),
-- R35  Phillip A. Scott / taxes  (was 4, RUNGTEXT)
('597a4057-4ccc-43f6-bf97-bcc701d7e637'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,'87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: RUNG TEXT - the evidence is real and on-axis, and the seated rung''s own wording describes something it does not show. WHY: Phillip Scott/taxes: one enacted bill letting localities LOWER vehicle tax rates as used-car prices rose. Rung 4 asserts cutting taxes for everyone AND scaling back public services; rung 3 asks about closing loopholes. A narrow local-option measure establishes no system-level posture. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R35.','R35'),
-- R37  R. Creigh Deeds / taxes  (was 2, AWAY)
('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,'87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: EVIDENCE POINTS AWAY - the cited record points at the opposite side of this ladder from the seat. WHY: Deeds/taxes: 🔴 THE BASIS POINTS THE OPPOSITE WAY. In January 2009 he proposed a $10,000 business tax CREDIT and supported a sales tax EXEMPTION - tax cuts - and the row seats him at ''moderately RAISE taxes on wealthy people and large companies''. Same shape as Scott Brown in mig 1916, and vintage besides. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R37.','R37'),
-- R38  Rick Chavez Zbur / same-sex-marriage  (was 2, OFFAXIS)
('ff77225c-51f9-4628-acc3-020d40382d05'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: OFF AXIS - the evidence is the person''s own and checkable, and it answers a different question from the one this ladder asks. WHY: Zbur/same-sex-marriage: FETCHED, and the word MARRIAGE does not appear on the Wikipedia page at all. ▶ REPAIR ATTEMPTED AND FAILED within bounded effort: his Ballotpedia page carries no marriage, no ACA 5 and no Proposition 3 either (only the Equality California role already known), and the Proposition 3 page names no authors. He very likely co-authored ACA 5 alongside Gabriel, but no accessible source shows it, and an unfetched claim is not a citation. Blanked and ROUTED to re-research. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R38.','R38'),
-- R40  Shannon Grove / abortion  (was 4, RUNGTEXT)
('03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid,0,'INTERNAL RECORD - blanked: the chair does not stand on the evidence the row cites. Shape: RUNG TEXT - the evidence is real and on-axis, and the seated rung''s own wording describes something it does not show. WHY: Grove/abortion: ▶ REPAIR ATTEMPTED, AND IT DOES NOT RESCUE THE CHAIR. The pages reference identifies the unnamed bill - a 2014 Assembly bill banning sex-selective abortion, which failed - and her opposition to the 2015 crisis-pregnancy-centre disclosure law. Both are real and both point anti-abortion, but neither states an EXCEPTION FRAMEWORK, which is what rung 4 (rape, incest, life of the mother) and rung 3 both turn on. 🔴 Her Ballotpedia page Planned Parenthood hits are SCORECARD BOILERPLATE listing which organisations rate California legislators - present on every such page and evidence of nothing. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs queue, migration 1921, ledger row R40.','R40');

-- GUARD 1 — the decision table arrived whole, and the split is what the ledger says.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1921_decisions;
  IF n <> 22 THEN RAISE EXCEPTION 'migration 1921: expected 22 decisions, found %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1921_decisions) s;
  IF n <> 22 THEN RAISE EXCEPTION 'migration 1921: duplicate (politician, topic) pairs; % distinct of 22', n; END IF;
  SELECT count(*) INTO n FROM mig1921_decisions WHERE new_value = 0;
  IF n <> 13 THEN RAISE EXCEPTION 'migration 1921: expected 13 blanks, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1921_decisions WHERE new_value <> 0;
  IF n <> 9 THEN RAISE EXCEPTION 'migration 1921: expected 9 re-seats, found %', n; END IF;
END $$;

-- GUARD 2 — every target must TODAY hold a Season 2 answer, and it must differ from what we write.
-- If a pair already sits where this file would put it, the queue was measured on a stale picture.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1921_decisions d
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_answers pa
      WHERE pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
        AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1921: % target(s) hold no Season 2 answer — re-measure', n; END IF;

  SELECT count(*) INTO n
    FROM mig1921_decisions d
    JOIN inform.politician_answers pa
      ON pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = d.new_value;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1921: % target(s) already sit at the new value — stale picture', n; END IF;
END $$;

-- GUARD 3 — a re-seat must land on a rung that EXISTS in the revision it is written against.
-- 🔴 Writing a value with no matching rung would produce a chair that renders as nothing.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1921_decisions d
   WHERE d.new_value <> 0
     AND NOT EXISTS (
       SELECT 1 FROM inform.compass_stance_revisions csr
        WHERE csr.topic_revision_id = d.topic_revision_id AND csr.value = d.new_value);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1921: % re-seat(s) target a rung that does not exist', n; END IF;
END $$;

-- GUARD 4 — every target must have citations to carry. Migration 1915 wrote 206 blanks with EMPTY
-- sources and every ROW COUNT passed; the defect was in the SHAPE of what was written.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1921_decisions d
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc0
      WHERE pc0.politician_id = d.politician_id AND pc0.topic_id = d.topic_id
        AND coalesce(cardinality(pc0.sources), 0) > 0);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1921: % target(s) have no citations to carry forward', n; END IF;
END $$;

-- The answer. A re-seat writes the new rung; a blank writes 0.
UPDATE inform.politician_answers pa
   SET value = d.new_value, updated_at = now()
  FROM mig1921_decisions d
 WHERE pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The record of WHY. Sources are left exactly as they are: every row here already serves from
-- Season 2 and already carries its own citations, and a re-seat rests on the SAME page.
UPDATE inform.politician_context pc
   SET reasoning = d.reasoning, updated_at = now()
  FROM mig1921_decisions d
 WHERE pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The one CITATION REPAIR: R39 VanValkenburg / housing. The chair does NOT move.
UPDATE inform.politician_context
   SET reasoning = 'Citation repaired 2026-10-21 (migration 1921). THE CHAIR IS UNCHANGED at 5; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: in 2026 he sponsored a "housing near jobs" bill allowing by-right zoning for apartment buildings, townhomes and mixed-use development in commercial districts, AND he filed the bill letting manufactured homes be placed in any residential district that allows traditional site-built housing, which is now Virginia law. WHY THIS MATTERS TO THE CHAIR: a single supply-side bill could not establish rung 5''s negative - "rely on the market to set prices and supply - at most, cut the regulations and zoning limits that block private building". Two independent zoning-liberalisation instruments, with nothing on the housing axis about binding rules, subsidies or public building, can. The earlier repair cited only the first and the row was read as a one-bill seat. Repaired-chairs queue, ledger row R39.', updated_at = now()
 WHERE politician_id = '38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid
   AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
   AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- GUARD 5 — verify the RESULT, not the absence of an error.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1921_decisions d
    JOIN inform.politician_answers pa
      ON pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = d.new_value;
  IF n <> 22 THEN RAISE EXCEPTION 'migration 1921: expected 22 rows at their new value, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1921_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1921: % row(s) lost their citations', n; END IF;

  -- A re-seat must SAY it moved the chair; a blank must say which kind of nothing it is.
  SELECT count(*) INTO n
    FROM mig1921_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE (d.new_value <> 0 AND pc.reasoning NOT LIKE 'CHAIR MOVED%')
      OR (d.new_value =  0 AND pc.reasoning NOT LIKE '%Shape:%');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1921: % row(s) do not record what was done to them', n; END IF;

  -- 🔴 No row may still carry the old repair marker: that is the defect this pass exists to clear.
  SELECT count(*) INTO n
    FROM mig1921_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning ILIKE '%THE CHAIR IS UNCHANGED%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1921: % row(s) still carry the repair marker', n; END IF;

  -- Season 1 is closed and must not have moved.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
    JOIN mig1921_decisions d ON d.politician_id = pa.politician_id AND d.topic_id = pa.topic_id
   WHERE pa.updated_at > now() - interval '5 minutes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1921: % Season 1 answer(s) were modified — Season 1 is closed', n; END IF;
END $$;
