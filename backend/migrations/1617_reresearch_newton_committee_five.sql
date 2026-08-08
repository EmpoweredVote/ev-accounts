-- 1617: Newton block 2 -- the five councilors named in Fig City News committee coverage.
--
-- 9 rows were in scope (Kalis 2, Oliver 2, Malakie 2, Wright 2, Baker 1). **5 restored, 4 not.**
--
-- 🔴 THE SCOPE DOC POINTED AT THE WRONG EVIDENCE CLASS. `2026-08-07-scope.md` built this block around
-- the per-meeting COMMITTEE REPORTS -- named attendance, per-item tallies, named dissent. Reading all
-- 28 of the 2026 Zoning & Planning / Land Use / Public Safety & Transportation reports, that class
-- yielded almost nothing: the tallies really are 8-0 and 7-1, and the only named dissents among these
-- five are Baker abstaining twice, Wright not voting on police wages (a recusal), and Kalis opposing a
-- "No Action Necessary". None of those carries a chair.
-- ✅ What DID work was ordinary Fig City News JOURNALISM -- topical articles and meeting write-ups in
-- which a reporter quotes a councilor by name. All five restored rows come from that class. Harvested
-- the housing / zoning / traffic / transportation topic categories plus the city-council category
-- (219 articles) and read every body sentence naming the five.
--
-- 🔴 A PROCEDURAL DISSENT HAS NO INHERENT DIRECTION -- I nearly wrote a row backwards. On 2026-01-26
-- the Z&P voted 7-1 "No Action Necessary" on extending the VCOD to Auburndale and West Newton, Oliver
-- opposed. I first read his dissent as wanting to PURSUE the extension, i.e. pro-upzoning. It is the
-- opposite: Oliver "had strenuously opposed" the VCOD in his own words. Voting against closing a
-- docket item says nothing about which way he wanted it to go. Do not chair from a procedural vote.
--
-- ⚠ TENURE. Every cited statement is the councilor's own, made while seated: Oliver Jan/Feb 2025,
-- Wright Mar 2025 + Jan 2026, Malakie and Kalis Apr 2025. All five appear on 2026 committee
-- attendance rosters, so all are current. No pre-tenure risk.
--
-- ===================================== RESTORED (5) =========================================
--
-- John Oliver -- Residential Zoning 2 -> 3. Favoured the MU4 rezoning at 386-390 Watertown Street
--   (a village-centre commercial parcel) while stating he had strenuously opposed the VCOD because it
--   was "by right" rather than "up to a decision-making process"; separately would back a Nonantum
--   project but not a VC2 designation. Multi-family near commercial corridors via council review,
--   most residential zones untouched -- chair 3 exactly. Not 4/5 (he rejects by-right); not 1/2 (he
--   voted for a 13-unit four-storey building).
-- Pamela Wright -- Residential Zoning 2 (unchanged value, new basis). Proposed a by-right path for
--   large homes to convert to up to 4 units with a "modest" rear addition, framed as preservation
--   rather than teardown; separately pressed for design criteria on ADUs.
--   ⚠ FLAGGED, the most arguable call here: the word "by-right" pulls toward chair 4, whose text is
--   "upzone broadly... streamline approvals and reduce parking requirements". I chose 2 because none
--   of chair 4's substance appears -- no broad upzoning, no streamlining, no parking claim -- and the
--   through-line of everything she says is modest added units inside existing houses plus design
--   standards. A reviewer who weights "by-right" more heavily should move this to 4 or drop it.
-- Pamela Wright -- Affordable Housing 1 -> 2. Would "prefer to have units on-site and integrated into
--   the market-rate project" over a cash payment in lieu. That is chair 2's "require new developments
--   to include affordable units".
-- Julia Malakie -- Affordable Housing 2 (unchanged value, new basis). "I couldn't disagree more about
--   enlarging the scope of the project that would allow payment in lieu of producing units. The
--   surest way to get a unit is to get a unit."
-- David Kalis -- Affordable Housing 2 -> 3. Embraced the payment-in-lieu-of-development provision --
--   money into the Newton Housing Trust -- saying "the more cash we have, the more we can do". The
--   reporter stages him as the pole opposite Malakie and Baker, who warned the cash option would
--   reduce the number of affordable units. Chair 3 ("subsidies for affordable projects"), not 2,
--   because the clause that distinguishes chair 2 is the on-site REQUIREMENT he argues against.
--   ⚠ One clause of that paragraph -- "the payments would likely prevent smaller developments" -- is
--   genuinely ambiguous in context and is NOT used in the reasoning.
--
-- ================================== NOT RESTORED (4) ========================================
-- Nothing is deleted; mig 1548 removed these and they stay removed. Reasons recorded so no later
-- sweep re-queues them.
--
-- R. Lisle Baker -- Transportation Priorities. Searched 219 articles including 44 traffic/transit
--   pieces and every 2026 Public Safety & Transportation report. Baker appears in transportation
--   coverage exactly twice, both as bare attendance. He is quoted often, but only on zoning, rules
--   and procedure. There is no transportation evidence for him at all.
--   ⚠ Lead for a later block, deliberately NOT acted on because it is outside this row set: he is
--   quoted on the facade-ratio ordinance as a means to regulate "oversize" residential buildings,
--   which is Residential Zoning evidence. He holds no Residential Zoning row today, and adding an
--   unowed row is scope creep.
-- John Oliver -- Affordable Housing. He chaired the April 2025 inclusionary-zoning meeting and his
--   only recorded remark is procedural (the committee "might be able to develop a new ordinance").
--   Chairing a meeting on a subject is not a position on it.
-- David Kalis -- Residential Zoning. Three candidates, all refused. (1) He opposed a "No Action
--   Necessary" on delaying the facade build-out ordinance -- procedural, direction unreadable, see
--   the Oliver correction above. (2) He asked the planning-director nominee how she would strengthen
--   business districts while preserving neighbourhood character -- a question is not a position.
--   (3) He was one of five councilors who "believed the proposal was unnecessary" on ADU carve-outs
--   in historic districts, but the reasoning quote in that sentence is Albright's. Attributing her
--   stated grounds to him would be manufacturing.
-- Julia Malakie -- Residential Zoning. She is visibly a VCOD sceptic, but nothing pins a chair. Her
--   VCOD remark is a paraphrase of a factual claim about state funding, made jointly with Block, at a
--   meeting where she sat as a Finance member and did not cast the Z&P vote; her teardown remark is a
--   question to a nominee; her one clear vote is against a manufacturing-to-BU2 rezoning, which is
--   commercial, not residential density. Chairs 1, 2 and 3 all remain open on that evidence.
--
-- Every cited URL was fetched live (HTTP 200) and every distinctive term in the prose below was
-- asserted present in the raw HTML before this was written.

BEGIN;

DO $$
DECLARE v_existing int;
BEGIN
  SELECT count(*) INTO v_existing FROM inform.politician_context
   WHERE (politician_id, topic_id) IN (
     ('c6a65ddf-9c48-4683-9100-28ce1c9f7983','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
     ('8a35fe01-8450-4726-a9b3-b61b7a967475','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
     ('8a35fe01-8450-4726-a9b3-b61b7a967475','669cac97-66a6-4087-b036-936fbe62efb3'),
     ('a00a26a4-f0f1-4a12-945a-d52498de8a3f','669cac97-66a6-4087-b036-936fbe62efb3'),
     ('cbc9201b-a23c-44ff-af75-5174d4531762','669cac97-66a6-4087-b036-936fbe62efb3'));
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing rows, found %', v_existing; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES

('c6a65ddf-9c48-4683-9100-28ce1c9f7983', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Oliver backs multi-family development in Newton''s village centres case by case, but rejects granting it by right. In February 2025 all three Ward 1 councilors, Oliver among them, favoured the MU4 rezoning of 386-390 Watertown Street in Nonantum, supporting both the additional storey and the three additional units that took the building to thirteen units, three of them below market rate. He drew a line between that rezoning and the Village Center Overlay District, which he said he had strenuously opposed, emphasising that MU4 is not "by right" but subject to a decision-making process. On an earlier Nonantum proposal he told residents he would support the project but could not support a VC2 designation.',
 ARRAY['https://www.figcitynews.com/2025/02/land-use-committee-does-not-approve-rezoning-and-special-permit-for-386-390-watertown-street/',
       'https://www.figcitynews.com/2025/01/proposed-spot-zoning-project-stirs-controversy-in-nonantum/']),

('8a35fe01-8450-4726-a9b3-b61b7a967475', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Wright favours adding a modest number of units inside houses that already exist, paired with design standards, as an alternative to teardowns. At a January 2026 Zoning and Planning Committee meeting she and Council President Oliver presented initiatives to encourage preservation, and Wright suggested creating a path for large homes to be converted into up to 4 units by-right, allowing for a "modest" addition off the back. In the committee''s March 2025 working session on the ADU ordinance she said that preserving architectural integrity was important, supporting special-permit criteria that exterior alterations be compatible with the size, scale, and architecture of the principal dwelling.',
 ARRAY['https://www.figcitynews.com/2026/03/newtons-tools-for-historic-preservation-local-landmark-status-demolition-delays-historic-districts/',
       'https://www.figcitynews.com/2025/03/in-working-session-zoning-and-planning-committee-discusses-amendments-to-adu-ordinance/']),

('8a35fe01-8450-4726-a9b3-b61b7a967475', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Wright wants new developments to build their affordable units rather than pay a fee instead. In the Zoning and Planning Committee''s April 2025 review of Newton''s Inclusionary Zoning Ordinance, where a consultant proposed offering a cash payment in lieu of affordable units on projects up to 20 units, Wright would prefer to have units on-site and integrated into the market-rate project. She argued that smaller Newton projects of 35 units and under are generally condominiums rather than rentals, so the consultant''s assumption of ongoing management cost overstated the burden on developers, while agreeing that $650,000 per unit was the right figure.',
 ARRAY['https://www.figcitynews.com/2025/04/zoning-planning-committee-reviews-inclusionary-zoning-ordinance/']),

('a00a26a4-f0f1-4a12-945a-d52498de8a3f', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Malakie wants developments required to produce below-market units rather than buy their way out of the requirement. In the Zoning and Planning Committee''s April 2025 review of Newton''s Inclusionary Zoning Ordinance, where the consultant recommended widening the cash-payment-in-lieu option to projects of 20 or fewer units, she said: "I couldn''t disagree more about enlarging the scope of the project that would allow payment in lieu of producing units. The surest way to get a unit is to get a unit."',
 ARRAY['https://www.figcitynews.com/2025/04/zoning-planning-committee-reviews-inclusionary-zoning-ordinance/']),

('cbc9201b-a23c-44ff-af75-5174d4531762', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Kalis would rather the city collect cash from developers and spend it on affordable housing than require below-market units inside each project. In the Zoning and Planning Committee''s April 2025 review of Newton''s Inclusionary Zoning Ordinance he embraced the payment-in-lieu-of-development provision, under which payments go into the Newton Housing Trust, responding that "the more cash we have, the more we can do". Colleagues on the other side of that debate expressed concern that the cash option would reduce the number of affordable units.',
 ARRAY['https://www.figcitynews.com/2025/04/zoning-planning-committee-reviews-inclusionary-zoning-ordinance/']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('c6a65ddf-9c48-4683-9100-28ce1c9f7983','d4f18138-a2e0-4110-b925-7387d9d0d16d',3),
('8a35fe01-8450-4726-a9b3-b61b7a967475','d4f18138-a2e0-4110-b925-7387d9d0d16d',2),
('8a35fe01-8450-4726-a9b3-b61b7a967475','669cac97-66a6-4087-b036-936fbe62efb3',2),
('a00a26a4-f0f1-4a12-945a-d52498de8a3f','669cac97-66a6-4087-b036-936fbe62efb3',2),
('cbc9201b-a23c-44ff-af75-5174d4531762','669cac97-66a6-4087-b036-936fbe62efb3',3);

DO $$
DECLARE v_ctx int; v_ans int; v_orphan int; v_empty int; v_prose int; v_closed int;
        v_nonascii int; v_frac int;
  added text[] := ARRAY[
    'c6a65ddf-9c48-4683-9100-28ce1c9f7983|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    '8a35fe01-8450-4726-a9b3-b61b7a967475|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    '8a35fe01-8450-4726-a9b3-b61b7a967475|669cac97-66a6-4087-b036-936fbe62efb3',
    'a00a26a4-f0f1-4a12-945a-d52498de8a3f|669cac97-66a6-4087-b036-936fbe62efb3',
    'cbc9201b-a23c-44ff-af75-5174d4531762|669cac97-66a6-4087-b036-936fbe62efb3'];
  -- Baker/Transportation, Oliver/AffHousing, Kalis/ResZoning, Malakie/ResZoning must remain absent
  closed text[] := ARRAY[
    '9d34705c-0a66-4c08-8936-7e63629ce435|ba59337e-30e2-4aba-a39a-426b3366eb27',
    'c6a65ddf-9c48-4683-9100-28ce1c9f7983|669cac97-66a6-4087-b036-936fbe62efb3',
    'cbc9201b-a23c-44ff-af75-5174d4531762|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    'a00a26a4-f0f1-4a12-945a-d52498de8a3f|d4f18138-a2e0-4110-b925-7387d9d0d16d'];
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(added);
  IF v_ctx <> 5 THEN RAISE EXCEPTION 'expected 5 context rows, found %', v_ctx; END IF;
  SELECT count(*) INTO v_ans FROM inform.politician_answers WHERE politician_id::text||'|'||topic_id::text = ANY(added);
  IF v_ans <> 5 THEN RAISE EXCEPTION 'expected 5 answer rows, found %', v_ans; END IF;

  SELECT count(*) INTO v_closed FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(closed);
  IF v_closed <> 0 THEN RAISE EXCEPTION '% deliberately-unrestored rows are present', v_closed; END IF;
  SELECT count(*) INTO v_closed FROM inform.politician_answers WHERE politician_id::text||'|'||topic_id::text = ANY(closed);
  IF v_closed <> 0 THEN RAISE EXCEPTION '% deliberately-unrestored answers are present', v_closed; END IF;

  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pc.politician_id::text||'|'||pc.topic_id::text = ANY(added) AND pa.politician_id IS NULL;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan rows', v_orphan; END IF;

  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(added) AND (sources IS NULL OR cardinality(sources)=0);
  IF v_empty <> 0 THEN RAISE EXCEPTION '% rows with empty sources', v_empty; END IF;

  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(added) AND reasoning ~ 'https?://';
  IF v_prose <> 0 THEN RAISE EXCEPTION '% rows embed a URL in reasoning', v_prose; END IF;

  -- scope-doc warning: a stray curly quote slipped into block 1's prose pre-apply
  SELECT count(*) INTO v_nonascii FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(added) AND reasoning ~ '[^\x00-\x7F]';
  IF v_nonascii <> 0 THEN RAISE EXCEPTION '% rows contain non-ASCII reasoning', v_nonascii; END IF;

  -- chairs are discrete 1-5, never fractional (the x.5 corruption class)
  SELECT count(*) INTO v_frac FROM inform.politician_answers
   WHERE politician_id::text||'|'||topic_id::text = ANY(added)
     AND (value <> round(value) OR value < 1 OR value > 5);
  IF v_frac <> 0 THEN RAISE EXCEPTION '% answers are fractional or out of range', v_frac; END IF;
END $$;

COMMIT;
