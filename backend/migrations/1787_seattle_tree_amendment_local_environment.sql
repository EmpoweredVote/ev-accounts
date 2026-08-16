-- 1787_seattle_tree_amendment_local_environment.sql
-- Seattle's September 2025 tree amendment: 4 local-environment rows, all at chair 3.
-- Rivera (sponsor), Saka, Juarez, Hollingsworth. Strauss and Lin deliberately untouched.
--
-- ── 🔴 THE PREMISE THIS TASK WAS HANDED WAS WRONG, AND THE ENACTED TEXT IS WHY ────────────────────
-- The handoff described "Amendment 102" as an amendment "tightening tree preservation rules", from
-- The Urbanist's summary, and asked whether chair 1 or chair 2 applied -- chair 2 turning on whether
-- developers must FULLY OFFSET impact. Neither chair applies. The amendment's centre of gravity is
-- the opposite direction: it converts a prohibition on shrinking tree protection areas into a grant
-- of discretion to the SDCI Director. This is the fifth confirmed instance of the Class E trap
-- (WA-SWEEP-PRECEDENTS section 12) and the first where a NEWS SUMMARY, not a bill title, pointed at
-- the wrong chair. The operator was right to withhold the row from migration 1784 pending the text.
--
-- ⚠ It is also NOT the amendment named in migration 1784's header. 1784 says Rivera is prime sponsor
-- of "the 2025 tree preservation amendment (passed 4-3)". The 4-3 vote is real and hers, but the
-- instrument is Amendment 102 to CB 120993 -- the ZONING COMPLIANCE bill -- not to CB 120985, the
-- comprehensive plan. Amendments 1-53 belong to CB 120985; 54-114 to CB 120993. A search of CB
-- 120985's 43 attachments for "Amendment 102" returns nothing, which is what makes this findable.
--
-- ── WHAT AMENDMENT 102 VERSION 3 ACTUALLY DOES (read from the redline, then re-read in the session
--    law, because the two differ in wording -- precedent 9a) ───────────────────────────────────────
-- TIGHTENING:
--   · 25.11.010.E purpose expands from "Protect Tier 2 trees" to "Protect Tier 2 and Tier 3 trees",
--     and adds "public health" to the values that make a tree an important community resource.
--   · 25.11.070.A.1.b drops the dwelling-width threshold that justifies removing a Tier 2 tree from
--     15 feet to 10 feet, and A.1.c narrows the removal justifications to "required" vehicle and
--     pedestrian access and a "Director-required" retaining wall.
-- LOOSENING -- and this is the operative core:
--   · 25.11.070.A.4.b: "The ((basic)) tree protection area ((cannot)) may be ((modified)) altered by
--     the Director pursuant to subsection 25.11.060.A.3 and subsection 25.11.060.A.4." The word
--     struck is CANNOT. In Neighborhood Residential zones the basic tree protection area had been
--     unmodifiable; it is now modifiable at the Director's discretion.
--   · 25.11.060.A.4 gains the discretion clause the amendment is titled after: the Director "may
--     approve additional modifications not listed in this subsection 25.11.060.A.4, if the Director
--     finds the modifications do not interfere with the overall health and stability of the retained
--     tree".
-- FLEXIBILITY GRANTED IN ORDER TO KEEP A TREE (neither, exactly):
--   · 25.11.070.A.2 permits extension into front or rear setbacks to retain a Tier 1-4 tree, and
--     A.3's bar on that extension is repealed to "Reserved."
--
-- ── WHY CHAIR 3 AND NOT 1, 2, 4 OR 5 ──────────────────────────────────────────────────────────────
-- Chair 3 is "Apply consistent environmental standards while giving developers reasonable
-- flexibility on implementation", and both limbs are enacted text rather than inference: the tiered
-- framework is retained and in part widened (standards), and the addition is case-by-case Director
-- discretion expressly conditioned on not interfering with the retained tree's health (flexibility
-- on implementation). Reductions past 35 percent of the outer half of the protection radius still
-- demand an alternative area or method giving "equal or greater tree protection".
-- Chair 2 needs developers to "fully offset any environmental impact". Nothing in the amendment
-- creates an offset duty, and striking "cannot" is the opposite of protecting canopy strictly. All
-- four also voted AGAINST Amendment 103, the strict option put to the same committee the same day.
-- Chair 1 needs green space and environmental review "before approving any development"; the
-- amendment creates no precondition on approval at all.
-- Chair 4 needs fees in lieu of on-site preservation; 25.11.110's payment-in-lieu is untouched, and
-- conditioning every modification on the tree's survival is not prioritising economic activity.
-- Chair 5 is refuted outright -- the chapter is retained and its purpose section widened.
-- This is not the forbidden "least extreme option" tiebreaker: chair 3 is positively matched clause
-- by clause, which is the boundary drawn in precedent 9e.
--
-- ── ✅ STRAUSS: VALUE-CHANGE CHECK RETURNS CONFIRMED AT 3. NOTHING WRITTEN FOR HIM ────────────────
-- Strauss holds local-environment=3 from Ordinance 126821, the ordinance Amendment 102 amends. He
-- voted NO on 102. That No does not move him, and his own instruments are the reason: he sponsored
-- Amendment 100 (at least one tree per 2,500 square feet of lot area, adopted 5-0-3), Amendment 106
-- (define the tree protection area as the drip line, withdrawn) -- and Amendment 104, "Provide
-- greater flexibility when trees are protected", which lets structures sit anywhere within a setback
-- and cuts amenity-area requirements where a tree is kept, adopted 5-3 with Strauss voting aye.
-- Strict standards plus generous siting flexibility to meet them is chair 3 read literally. His No
-- on 102 is a disagreement about how much discretion, not a rejection of the standards-plus-
-- flexibility frame, and under precedent 9b degree is incompleteness, not contradiction.
-- ⚠ THE ONE DATUM THAT CUTS THE OTHER WAY, recorded rather than buried: Strauss was the ONLY aye on
-- his own Amendment 103, which would have barred removal of any Tier 1 or Tier 2 tree within five
-- feet of a lot corner (defeated 1-7). A categorical no-removal rule is chair 2's first limb. It
-- does not carry him there -- chair 2's second limb, full offset, is absent from his record entirely
-- -- but if the operator reads 103 as decisive, Strauss is the row to move, and it moves to 2.
--
-- ── 🔴 THE LADDER FINDING, WHICH IS THE REAL YIELD HERE ───────────────────────────────────────────
-- A 4-3 divided municipal roll call on precisely the question this ladder asks produces ZERO chair
-- separation. Rivera, Saka, Juarez and Hollingsworth voted aye; Strauss voted no; all five sit at
-- chair 3. `local-environment` has no resolution finer than "standards plus flexibility", so the
-- live Seattle argument -- how much discretion an administrator gets over a protection area -- falls
-- entirely inside one chair. Same shape as `climate-change` chair 3 absorbing the middle (migs
-- 1772/1773), but reached from a divided VOTE rather than from sponsorship, which is new. Logged for
-- COMPASS-LADDER-TROUBLE-SPOTS.md.
--
-- ⚠ Eddie Lin's documented blank is untouched and remains correct: he took office in 2026 and was
-- not on the council for this vote. His position -- more public canopy, fewer private-lot retention
-- duties -- is still unplaceable, and this amendment does not reach it.
--
-- ⚠ Council sponsorship of city land-use bills is weak evidence when the bill is mayor-transmitted
-- (RESEARCH-METHOD-SELECTION). That caveat does not apply here: Amendment 102 is a councilmember
-- amendment drafted by Council Central Staff at the member's direction and carried on a contested
-- roll call. A divided vote is the rare Seattle instrument that is genuinely attributable.
--
-- Sources, all four fetched in full this session:
--   Amendment 102 v3 redline .. legistar2.granicus.com/seattle/attachments/a7678afc-...pdf
--   Sept 17-19 vote tally ..... legistar2.granicus.com/seattle/attachments/650aefaf-...pdf
--   Signed Ordinance 127376 ... legistar2.granicus.com/seattle/attachments/6e1276fe-...pdf
--   Amendments for indiv votes  legistar2.granicus.com/seattle/attachments/b75127b5-...pdf
BEGIN;

CREATE TEMP TABLE tr_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE tr_rows (pid uuid, tid uuid, val int, nm text) ON COMMIT DROP;
INSERT INTO tr_rows (pid, tid, val, nm) VALUES
('81057c65-d128-4712-8ded-52c4534b0d9b','1935979c-b290-42e4-baa5-8cb0138b4ffa',3,'Maritza Rivera'),
('215f2142-c0a1-46fb-b78e-3204843ae3e5','1935979c-b290-42e4-baa5-8cb0138b4ffa',3,'Rob Saka'),
('b510823d-e54b-40a5-92c0-09a6636359d5','1935979c-b290-42e4-baa5-8cb0138b4ffa',3,'Debora Juarez'),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','1935979c-b290-42e4-baa5-8cb0138b4ffa',3,'Joy Hollingsworth');

DO $$
DECLARE n int;
BEGIN
  -- Nothing here may overwrite an existing curated row.
  SELECT count(*) INTO n FROM tr_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of these pairs already have an answer', n; END IF;
  SELECT count(*) INTO n FROM tr_rows r
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of these pairs already have a context row', n; END IF;

  -- Strauss stays at 3 and is not rewritten. If he has moved, the value-change check documented in
  -- this header is stale and must be redone before these four rows can rest on the same reasoning.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2e4714c6-feb4-443f-9cc0-08d866a0a99f'
     AND topic_id='1935979c-b290-42e4-baa5-8cb0138b4ffa' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Strauss local-environment=3 is gone (found %)', n; END IF;

  -- Eddie Lin's documented blank must still be a blank: context, no answer.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='9e33c647-967a-4dce-a900-ad7d066cc57f'
     AND topic_id='1935979c-b290-42e4-baa5-8cb0138b4ffa';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Eddie Lin local-environment is no longer a blank'; END IF;

  -- Chair-text tripwires. The whole ruling is chair 3 over chair 2, so assert both wordings. If the
  -- ladder is reworded, these four rows mean something other than what they were written to mean.
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='1935979c-b290-42e4-baa5-8cb0138b4ffa' AND value=3
     AND text ILIKE '%reasonable flexibility on implementation%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: local-environment chair 3 is no longer the consistent-standards-with-flexibility chair'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='1935979c-b290-42e4-baa5-8cb0138b4ffa' AND value=2
     AND text ILIKE '%fully offset any environmental impact%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: local-environment chair 2 no longer carries the full-offset clause the ruling turns on'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('81057c65-d128-4712-8ded-52c4534b0d9b','1935979c-b290-42e4-baa5-8cb0138b4ffa',
 $r$Rivera was the sponsor and mover of Amendment 102 version 3 to Council Bill 120993, adopted 4-3 by the Select Committee on the Comprehensive Plan on 18 September 2025 and enacted in Ordinance 127376. The amendment retains Chapter 25.11's tiered tree protection framework and widens its purpose section, which now reads "Protect Tier 2 and Tier 3 trees" with "public health" added to the values that make a tree an important community resource, where it previously reached Tier 2 alone. What it adds operationally is discretion. Section 25.11.070.A.4.b strikes "cannot" so that the tree protection area "may be altered by the Director", and section 25.11.060.A.4 lets the Director "approve additional modifications not listed in this subsection 25.11.060.A.4, if the Director finds the modifications do not interfere with the overall health and stability of the retained tree". Reductions past 35 percent of the outer half of the protection radius still require an alternative area or construction method giving "equal or greater tree protection". Consistent standards kept, with case-by-case flexibility bounded by the retained tree's survival, is chair 3 on both limbs. Chair 2 is refuted twice: no duty to fully offset environmental impact is created anywhere in the amendment, and converting a prohibition into Director discretion is the opposite of protecting canopy strictly. Rivera also voted against Amendment 103, the strict option before the same committee the same day, which would have required retention of any Tier 1 or Tier 2 tree within five feet of a lot corner and was defeated 1-7. Chair 1 fails because the amendment requires no green space and no environmental review before approving development. Chair 4 fails because no fee in lieu is created or widened. The per-member screen surfaced her own Amendment 93 version 2b, NR tree canopy requirements, defeated 4-4, which would have set minimum planting-area and soil-depth requirements while granting reduced setbacks, additional floor area and additional height where a Tier 2 tree is preserved. Standards plus incentive-based flexibility is the same chair, so the screen does not move her.$r$,
 ARRAY['https://legistar2.granicus.com/seattle/attachments/a7678afc-c1bc-4a52-9e3e-f1fd0e02378a.pdf',
       'https://legistar2.granicus.com/seattle/attachments/650aefaf-7b9f-454c-9134-ef65054ed222.pdf',
       'https://legistar2.granicus.com/seattle/attachments/6e1276fe-c616-458c-8741-8a21f3cc0d8c.pdf',
       'https://legistar2.granicus.com/seattle/attachments/b75127b5-0e7c-4bb1-bee3-001d8ac6dec9.pdf']),
('215f2142-c0a1-46fb-b78e-3204843ae3e5','1935979c-b290-42e4-baa5-8cb0138b4ffa',
 $r$Saka voted for Amendment 102 version 3 to Council Bill 120993, adopted 4-3 by the Select Committee on the Comprehensive Plan on 18 September 2025 and enacted in Ordinance 127376. The amendment retains Chapter 25.11's tiered tree protection framework and widens its purpose section to "Protect Tier 2 and Tier 3 trees", while adding discretion as its operative core: section 25.11.070.A.4.b strikes "cannot" so that the tree protection area "may be altered by the Director", and section 25.11.060.A.4 lets the Director "approve additional modifications not listed in this subsection 25.11.060.A.4, if the Director finds the modifications do not interfere with the overall health and stability of the retained tree". That is chair 3 on both limbs, consistent standards with case-by-case flexibility on implementation. Saka's other votes that day place him there rather than at a neighbouring chair from either side. He voted FOR Amendment 100, which requires at least one tree planted for every 2,500 square feet of lot area in Neighborhood Residential zones, adopted 5-0-3, so he is not at chair 4 or 5 removing obligations. He voted AGAINST Amendment 103, which would have required retention of any Tier 1 or Tier 2 tree within five feet of a lot corner and was defeated 1-7, so chair 2's strict-protection limb is refuted from his own vote, and no instrument in this record creates a duty to fully offset environmental impact. He also voted AGAINST Amendment 104, which would have let structures sit anywhere within a setback wherever a tree is kept, adopted 5-3 without him, which shows the flexibility he supports is the conditioned, case-by-case kind rather than a blanket relaxation. Chair 1 fails because nothing here requires green space or environmental review before approving development.$r$,
 ARRAY['https://legistar2.granicus.com/seattle/attachments/a7678afc-c1bc-4a52-9e3e-f1fd0e02378a.pdf',
       'https://legistar2.granicus.com/seattle/attachments/650aefaf-7b9f-454c-9134-ef65054ed222.pdf',
       'https://legistar2.granicus.com/seattle/attachments/6e1276fe-c616-458c-8741-8a21f3cc0d8c.pdf',
       'https://legistar2.granicus.com/seattle/attachments/b75127b5-0e7c-4bb1-bee3-001d8ac6dec9.pdf']),
('b510823d-e54b-40a5-92c0-09a6636359d5','1935979c-b290-42e4-baa5-8cb0138b4ffa',
 $r$Juarez voted for Amendment 102 version 3 to Council Bill 120993, adopted 4-3 by the Select Committee on the Comprehensive Plan on 18 September 2025 and enacted in Ordinance 127376. The amendment retains Chapter 25.11's tiered tree protection framework and widens its purpose section to "Protect Tier 2 and Tier 3 trees", while adding discretion as its operative core: section 25.11.070.A.4.b strikes "cannot" so that the tree protection area "may be altered by the Director", and section 25.11.060.A.4 lets the Director "approve additional modifications not listed in this subsection 25.11.060.A.4, if the Director finds the modifications do not interfere with the overall health and stability of the retained tree". Reductions past 35 percent of the outer half of the protection radius still require an alternative area or method giving "equal or greater tree protection". Consistent standards with case-by-case flexibility bounded by the tree's survival is chair 3 on both limbs. Her other votes on the same package hold her there. She voted FOR Amendment 100, requiring at least one tree planted for every 2,500 square feet of lot area in Neighborhood Residential zones, adopted 5-0-3, which refutes chairs 4 and 5. She voted AGAINST Amendment 103, which would have required retention of any Tier 1 or Tier 2 tree within five feet of a lot corner and was defeated 1-7, which refutes chair 2's strict-protection limb; and nothing in her record creates a duty to fully offset environmental impact, chair 2's second limb. Chair 1 fails because the amendment requires no green space and no environmental review before approving any development.$r$,
 ARRAY['https://legistar2.granicus.com/seattle/attachments/a7678afc-c1bc-4a52-9e3e-f1fd0e02378a.pdf',
       'https://legistar2.granicus.com/seattle/attachments/650aefaf-7b9f-454c-9134-ef65054ed222.pdf',
       'https://legistar2.granicus.com/seattle/attachments/6e1276fe-c616-458c-8741-8a21f3cc0d8c.pdf',
       'https://legistar2.granicus.com/seattle/attachments/b75127b5-0e7c-4bb1-bee3-001d8ac6dec9.pdf']),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','1935979c-b290-42e4-baa5-8cb0138b4ffa',
 $r$Hollingsworth, as land use chair, voted for Amendment 102 version 3 to Council Bill 120993, adopted 4-3 by the Select Committee on the Comprehensive Plan on 18 September 2025 and enacted in Ordinance 127376. The amendment retains Chapter 25.11's tiered tree protection framework and widens its purpose section to "Protect Tier 2 and Tier 3 trees", while adding discretion as its operative core: section 25.11.070.A.4.b strikes "cannot" so that the tree protection area "may be altered by the Director", and section 25.11.060.A.4 lets the Director "approve additional modifications not listed in this subsection 25.11.060.A.4, if the Director finds the modifications do not interfere with the overall health and stability of the retained tree". Consistent standards with case-by-case flexibility bounded by the retained tree's survival is chair 3 on both limbs. Chair 2 is refuted from her own vote: she voted AGAINST Amendment 103, which would have required retention of any Tier 1 or Tier 2 tree within five feet of a lot corner, defeated 1-7, and no instrument in this record creates a duty to fully offset environmental impact. She also voted against Amendment 104, which would have let structures sit anywhere within a setback wherever a tree is kept, adopted 5-3 without her, so the flexibility she supports is conditioned and case by case rather than blanket, which is what separates chair 3 from chair 4. Chair 1 fails because the amendment requires no green space and no environmental review before approving any development. She abstained on Amendment 100, the tree-planting-ratio amendment, so that vote is not used here in either direction.$r$,
 ARRAY['https://legistar2.granicus.com/seattle/attachments/a7678afc-c1bc-4a52-9e3e-f1fd0e02378a.pdf',
       'https://legistar2.granicus.com/seattle/attachments/650aefaf-7b9f-454c-9134-ef65054ed222.pdf',
       'https://legistar2.granicus.com/seattle/attachments/6e1276fe-c616-458c-8741-8a21f3cc0d8c.pdf',
       'https://legistar2.granicus.com/seattle/attachments/b75127b5-0e7c-4bb1-bee3-001d8ac6dec9.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pid, tid, val FROM tr_rows;

DO $$
DECLARE n int; bad int; s record;
BEGIN
  SELECT * INTO s FROM tr_snap;

  SELECT count(*) INTO n FROM inform.politician_answers;
  IF n <> s.ans_before + 4 THEN
    RAISE EXCEPTION 'guard 1: answers went % -> %, expected +4', s.ans_before, n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context;
  IF n <> s.ctx_before + 4 THEN
    RAISE EXCEPTION 'guard 1: context went % -> %, expected +4', s.ctx_before, n; END IF;

  -- Content guard, per row: the chair VALUE, a phrase from each of the two clauses the chair was
  -- read from, and the two source URLs that carry those clauses. A count guard alone would pass if
  -- every row collapsed onto one chair or carried empty reasoning.
  SELECT count(*) INTO bad
    FROM tr_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid
   WHERE a.value <> r.val
      OR length(c.reasoning) < 400
      OR c.reasoning NOT LIKE '%Amendment 102 version 3 to Council Bill 120993%'
      OR c.reasoning NOT LIKE '%may be altered by the Director%'
      OR c.reasoning NOT LIKE '%do not interfere with the overall health and stability of the retained tree%'
      OR NOT ('https://legistar2.granicus.com/seattle/attachments/a7678afc-c1bc-4a52-9e3e-f1fd0e02378a.pdf' = ANY(c.sources))
      OR NOT ('https://legistar2.granicus.com/seattle/attachments/6e1276fe-c616-458c-8741-8a21f3cc0d8c.pdf' = ANY(c.sources));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'guard 2: % row(s) wrong chair, thin reasoning, or missing the clause or the source', bad; END IF;

  -- Chair 2 must NOT appear on any of these rows. The whole ruling is that the full-offset chair is
  -- refuted, so assert the negative rather than trusting the positive check above.
  SELECT count(*) INTO bad FROM tr_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE a.value <> 3;
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % row(s) are not at chair 3', bad; END IF;

  -- Strauss and Lin are untouched: he still holds 3, Lin still holds a blank.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2e4714c6-feb4-443f-9cc0-08d866a0a99f'
     AND topic_id='1935979c-b290-42e4-baa5-8cb0138b4ffa' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: Strauss local-environment=3 was disturbed'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='9e33c647-967a-4dce-a900-ad7d066cc57f'
     AND topic_id='1935979c-b290-42e4-baa5-8cb0138b4ffa';
  IF n <> 0 THEN RAISE EXCEPTION 'guard 2: Eddie Lin local-environment blank was disturbed'; END IF;

  -- Six of Seattle's eleven offices now carry a local-environment position: five at chair 3 and one
  -- documented blank. This is the headline count.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE topic_id='1935979c-b290-42e4-baa5-8cb0138b4ffa'
     AND politician_id IN ('81057c65-d128-4712-8ded-52c4534b0d9b','215f2142-c0a1-46fb-b78e-3204843ae3e5',
                           'b510823d-e54b-40a5-92c0-09a6636359d5','1187a22d-1064-4ff4-8193-189c34b4b6e8',
                           '2e4714c6-feb4-443f-9cc0-08d866a0a99f');
  IF n <> 5 THEN RAISE EXCEPTION 'guard 2: % of 5 Seattle local-environment answers present, expected 5', n; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  -- Predicate copied verbatim from the CI gate. These four rows all carry an answer, so the orphan
  -- count must not move.
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

  RAISE NOTICE 'Seattle tree amendment: 4 local-environment rows at chair 3; Strauss and Lin untouched; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
