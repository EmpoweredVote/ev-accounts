-- 1766_wa_local_immigration_split_cohort.sql
-- 7 rows on local-immigration for seven Republican senators, SPLIT 5 at chair 4 and 2 at chair 5.
--
-- 🔑 THIS IS THE FIRST TIME THE PER-MEMBER SCREEN CHANGED AN OUTCOME. Migrations 1763, 1764 and 1765
-- all screened their cohorts and found nothing that moved a chair. Here it did: two members hold a
-- materially stronger instrument of their own, and a blanket cohort write would have buried it.
--
-- ── chair 4 (5): SB 6264 and SB 5818 ──────────────────────────────────────────────────────────
-- Both are PERMISSIVE rollbacks of the Keep Washington Working Act. SB 6264 amends RCW 10.93.160 by
-- DELETING THE WORD "not" from three prohibitions, so agencies MAY collect immigration status, MAY
-- provide it "pursuant to notification requests from federal immigration authorities", and MAY grant
-- federal agents custodial interview access (striking the written-consent protections outright). Its
-- new sec. 2(8)(b) provides that a person "may continue to be held in custody based on a civil
-- immigration warrant or an immigration hold request". SB 5818 sec. 3 lets the department of
-- corrections transfer an incarcerated person to federal immigration custody "on the basis of the
-- presence of an immigration detainer, hold, notification request, or civil immigration warrant".
-- 🔑 Chair 4 is "honor ICE detainers and share information proactively when federal agencies request
-- it" — both clauses, matched by the operative text. Chair 5 is REFUTED for these five: it requires
-- DIRECTING police to actively assist, and every operative verb in these two bills is "may".
-- Chair 3 ("do not use local resources for proactive immigration enforcement") is refuted because
-- proactive information sharing is precisely what is being authorised.
--
-- ── chair 5 (2): SB 5002 ──────────────────────────────────────────────────────────────────────
-- Fortunato is PRIME sponsor and McCune a co-sponsor of a bill that goes considerably further, and
-- it is MANDATORY where the other two are permissive:
--   · sec. 1 repeals the Keep Washington Working framework entire (RCW 43.17.420, 43.17.425,
--     10.93.160, 43.10.310, 43.10.315, 43.330.510) plus the court-interpreter provisions;
--   · sec. 3 "SANCTUARY POLICIES PROHIBITED" — no state or local entity "may ... have in effect a
--     sanctuary policy";
--   · sec. 4(1) "A law enforcement agency SHALL use best efforts to support the enforcement of
--     federal immigration law";
--   · sec. 5(1)(c) an agency holding a person subject to a detainer SHALL "comply with the requests
--     made in the immigration detainer";
--   · sec. 6 "Each county correctional facility SHALL enter into an agreement ... with a federal
--     immigration agency for temporarily housing persons who are the subject of immigration
--     detainers";
--   · sec. 7 makes the duties enforceable by the attorney general against individual officers.
-- 🔑 Chair 5 is "direct local police to actively assist with immigration enforcement AND support
-- federal detention operations". Sec. 4(1) is the first clause and sec. 6 is the second, both in
-- mandatory terms. This is not the "next chair along because the reasoning felt strong" tiebreaker:
-- the discriminator between chairs 4 and 5 on this ladder is permissive-versus-directive, and these
-- two bills sit on opposite sides of it.
-- ⚠ NOT A CONTRADICTION OF THE COHORT RULE. Fortunato and McCune also co-sponsored SB 5818, which
-- seats chair 4. The corpus rule is that one INSTRUMENT cannot seat its co-sponsors in different
-- chairs — it does not say a member may not hold a stronger instrument of their own. SB 5818 sets a
-- floor for all six of its sponsors; SB 5002 raises it for the two who signed it. Every other SB 5818
-- and SB 6264 sponsor was checked and holds no third instrument.
--
-- ⚠ SCOPE JUDGEMENT, RECORDED. The generated topic reference warns that `local-immigration` is
-- "usually the WRONG choice for a federal or statewide official". It is used here deliberately: all
-- three bills legislate on exactly what that ladder asks — whether local law enforcement cooperates
-- with federal immigration enforcement — and a state legislator writing the statewide rule for local
-- agencies is answering that question, not an adjacent one. The general `immigration` ladder was
-- considered and REJECTED: it asks about immigration levels and access to public services, and none
-- of these bills changes either.
BEGIN;

CREATE TEMP TABLE li_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='6cc4c706-fa7a-486f-ac67-6cbdede4a607' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jim McCune already has a local-immigration answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='6cc4c706-fa7a-486f-ac67-6cbdede4a607' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jim McCune already has a local-immigration context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d3fad6d8-8022-4c66-b505-4e7a8fc816d7' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Phil Fortunato already has a local-immigration answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d3fad6d8-8022-4c66-b505-4e7a8fc816d7' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Phil Fortunato already has a local-immigration context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='b316dce9-ed2e-44f6-b974-bf639cacb816' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Judy Warnick already has a local-immigration answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='b316dce9-ed2e-44f6-b974-bf639cacb816' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Judy Warnick already has a local-immigration context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='755f24a5-2330-4546-9679-d5f7fa94aaa9' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Braun already has a local-immigration answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='755f24a5-2330-4546-9679-d5f7fa94aaa9' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Braun already has a local-immigration context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0e935fed-534e-42b0-a5ad-74f4199ff6df' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Leonard Christian already has a local-immigration answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0e935fed-534e-42b0-a5ad-74f4199ff6df' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Leonard Christian already has a local-immigration context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='3db3f064-dd6e-4bca-9200-3d4395972253' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Keith Wagoner already has a local-immigration answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='3db3f064-dd6e-4bca-9200-3d4395972253' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Keith Wagoner already has a local-immigration context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='aadf55f0-a4b4-4a4a-acf0-bfce06815149' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Wilson already has a local-immigration answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='aadf55f0-a4b4-4a4a-acf0-bfce06815149' AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Wilson already has a local-immigration context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND value=4;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: local-immigration chair 4 not defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND value=5;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: local-immigration chair 5 not defined exactly once (%)', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('6cc4c706-fa7a-486f-ac67-6cbdede4a607','b9ccee94-ad96-4f10-b655-889d8e5abe92',
 $r$Co-sponsor of SB 5002 (2025), which would repeal Washington's Keep Washington Working framework, prohibit any state or local entity from having a sanctuary policy, require law enforcement agencies to "use best efforts to support the enforcement of federal immigration law", require agencies holding someone subject to an immigration detainer to comply with it, and require every county correctional facility to contract with a federal immigration agency to house people held on detainers. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5002.pdf']),
('d3fad6d8-8022-4c66-b505-4e7a8fc816d7','b9ccee94-ad96-4f10-b655-889d8e5abe92',
 $r$Prime sponsor of SB 5002 (2025), which would repeal Washington's Keep Washington Working framework, prohibit any state or local entity from having a sanctuary policy, require law enforcement agencies to "use best efforts to support the enforcement of federal immigration law", require agencies holding someone subject to an immigration detainer to comply with it, and require every county correctional facility to contract with a federal immigration agency to house people held on detainers. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5002.pdf']),
('b316dce9-ed2e-44f6-b974-bf639cacb816','b9ccee94-ad96-4f10-b655-889d8e5abe92',
 $r$Co-sponsor of SB 6264 and co-sponsor of SB 5818 (2025-26), which would let state and local agencies collect a person's immigration status, share it with federal immigration authorities on request, and hold someone in custody on a civil immigration warrant or detainer — reversing prohibitions in current law. Neither bill passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6264.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5818.pdf']),
('755f24a5-2330-4546-9679-d5f7fa94aaa9','b9ccee94-ad96-4f10-b655-889d8e5abe92',
 $r$Prime sponsor of SB 6264 and co-sponsor of SB 5818 (2025-26), which would let state and local agencies collect a person's immigration status, share it with federal immigration authorities on request, and hold someone in custody on a civil immigration warrant or detainer — reversing prohibitions in current law. Neither bill passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6264.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5818.pdf']),
('0e935fed-534e-42b0-a5ad-74f4199ff6df','b9ccee94-ad96-4f10-b655-889d8e5abe92',
 $r$Co-sponsor of SB 6264 and co-sponsor of SB 5818 (2025-26), which would let state and local agencies collect a person's immigration status, share it with federal immigration authorities on request, and hold someone in custody on a civil immigration warrant or detainer — reversing prohibitions in current law. Neither bill passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6264.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5818.pdf']),
('3db3f064-dd6e-4bca-9200-3d4395972253','b9ccee94-ad96-4f10-b655-889d8e5abe92',
 $r$Co-sponsor of SB 6264 (2025-26), which would let state and local agencies collect a person's immigration status, share it with federal immigration authorities on request, and hold someone in custody on a civil immigration warrant or detainer — reversing prohibitions in current law. Neither bill passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6264.pdf']),
('aadf55f0-a4b4-4a4a-acf0-bfce06815149','b9ccee94-ad96-4f10-b655-889d8e5abe92',
 $r$Co-sponsor of SB 6264 and co-sponsor of SB 5818 (2025-26), which would let state and local agencies collect a person's immigration status, share it with federal immigration authorities on request, and hold someone in custody on a civil immigration warrant or detainer — reversing prohibitions in current law. Neither bill passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6264.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5818.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('6cc4c706-fa7a-486f-ac67-6cbdede4a607','b9ccee94-ad96-4f10-b655-889d8e5abe92', 5),
('d3fad6d8-8022-4c66-b505-4e7a8fc816d7','b9ccee94-ad96-4f10-b655-889d8e5abe92', 5),
('b316dce9-ed2e-44f6-b974-bf639cacb816','b9ccee94-ad96-4f10-b655-889d8e5abe92', 4),
('755f24a5-2330-4546-9679-d5f7fa94aaa9','b9ccee94-ad96-4f10-b655-889d8e5abe92', 4),
('0e935fed-534e-42b0-a5ad-74f4199ff6df','b9ccee94-ad96-4f10-b655-889d8e5abe92', 4),
('3db3f064-dd6e-4bca-9200-3d4395972253','b9ccee94-ad96-4f10-b655-889d8e5abe92', 4),
('aadf55f0-a4b4-4a4a-acf0-bfce06815149','b9ccee94-ad96-4f10-b655-889d8e5abe92', 4);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM li_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 7 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +7', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 7 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +7', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 2: the SPLIT is the whole point of this migration, so assert both sides separately. A bug
-- that collapsed everyone onto one chair would still satisfy guard 1.
DO $$
DECLARE bad int; n5 int; n4 int;
BEGIN
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND a.politician_id IN ('6cc4c706-fa7a-486f-ac67-6cbdede4a607','d3fad6d8-8022-4c66-b505-4e7a8fc816d7')
     AND (a.value <> 5
          OR c.reasoning !~ 'best efforts to support the enforcement of federal immigration law'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5002.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-5 row(s) wrong chair, missing the mandatory clause, or missing SB 5002', bad; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND a.politician_id IN ('b316dce9-ed2e-44f6-b974-bf639cacb816','755f24a5-2330-4546-9679-d5f7fa94aaa9','0e935fed-534e-42b0-a5ad-74f4199ff6df','3db3f064-dd6e-4bca-9200-3d4395972253','aadf55f0-a4b4-4a4a-acf0-bfce06815149')
     AND (a.value <> 4
          OR c.reasoning !~ 'reversing prohibitions in current law'
          OR coalesce(cardinality(c.sources),0) = 0);
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-4 row(s) wrong chair, missing the rollback clause, or missing source', bad; END IF;

  -- nobody cited SB 5002 may sit at chair 4, and nobody at chair 5 may lack it
  SELECT count(*) INTO n5 FROM inform.politician_answers WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND value=5 AND politician_id IN ('6cc4c706-fa7a-486f-ac67-6cbdede4a607','d3fad6d8-8022-4c66-b505-4e7a8fc816d7');
  SELECT count(*) INTO n4 FROM inform.politician_answers WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND value=4 AND politician_id IN ('b316dce9-ed2e-44f6-b974-bf639cacb816','755f24a5-2330-4546-9679-d5f7fa94aaa9','0e935fed-534e-42b0-a5ad-74f4199ff6df','3db3f064-dd6e-4bca-9200-3d4395972253','aadf55f0-a4b4-4a4a-acf0-bfce06815149');
  IF n5 <> 2 THEN RAISE EXCEPTION 'guard 2: chair-5 count is %, expected 2', n5; END IF;
  IF n4 <> 5 THEN RAISE EXCEPTION 'guard 2: chair-4 count is %, expected 5', n4; END IF;
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

  RAISE NOTICE 'local-immigration seated: 5 at chair 4, 2 at chair 5; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
