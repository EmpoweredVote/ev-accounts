-- 1769_wa_residential_zoning_split.sql
-- 7 rows on residential-zoning, SPLIT 3 at chair 2 and 4 at chair 4. Bipartisan cohort:
-- the prime sponsor is a Republican (Goehner) and five of the six co-sponsors are Democrats.
--
-- ⚠ THE INSTRUMENT THE PICKER CHOSE WAS A DUD, AND THAT IS WORTH RECORDING. Goehner was selected
-- because SB 5558 ("growth management comprehensive plans", enacted, +10 uncovered legislators)
-- topped the coverage ranking. Reading it, SB 5558 only moves DEADLINES for periodic comprehensive
-- plan updates and exempts small slow-growing counties from the update cycle. It takes no position on
-- growth pace, permitting, fees or infrastructure, so it reaches NO chair on either
-- `growth-and-development` or `residential-zoning`. On-topic by vocabulary, not by rationale.
-- 🔑 The picker ranks by REACH, not by evidentiary quality. Rank to choose where to look; still read
-- the instrument before believing it seats anything.
--
-- ── chair 2 (3): SB 5471 alone ────────────────────────────────────────────────────────────────
-- Chair 2 is "allow modest density increases (DUPLEXES, ACCESSORY UNITS) with strong design review
-- and neighbourhood input". Middle housing is that parenthetical exactly, and this cohort legislated
-- on both halves of it: SB 5471 authorises middle housing inside urban growth areas, and its
-- companion SB 5470 (same prime sponsor, six of the same seven) LIMITS detached accessory dwelling
-- units outside them.
-- The other three chairs are refuted rather than merely unproven:
--   · chair 1 ("protect existing neighbourhood character strictly; require community votes before any
--     rezoning") — the act authorises density rather than blocking it;
--   · chair 3 ("multifamily and mixed-use near commercial corridors") — this is parcel-based, keyed
--     to wherever single-family is already allowed, not to corridors;
--   · chair 5 ("eliminate single-family-only zoning ... on any lot COMMUNITYWIDE") — it reaches only
--     unincorporated urban growth areas and certain rural development areas, and only middle housing
--     types.
-- ⚠ RECORDED WEAKNESS: chair 2 also says "with strong DESIGN REVIEW", and SB 5471 contains no design
-- review provision. What it does have is optional adoption by county ordinance, which is the
-- neighbourhood-input half, plus a water-and-sewer service condition. Chair 2 survives on its main
-- clause and on the refutation of all three neighbours, not on a complete textual match.
--
-- ── chair 4 (4): SB 5471 + SB 5184 ────────────────────────────────────────────────────────────
-- Chair 4 is "upzone broadly to allow multifamily by right; streamline approvals and REDUCE PARKING
-- REQUIREMENTS". SB 5184 is that second clause in mandatory, statewide terms — cities, code cities
-- and counties "may not require more than" 0.5 spaces per unit or two per 1,000 square feet of
-- commercial space — and its findings say parking mandates "needlessly drive up the cost of
-- development, particularly housing" and "discourage walking and multimodal transit usage". Combined
-- with authorising middle housing on every single-family parcel, both of chair 4's mechanisms are
-- present.
-- 🔑 Permissive-versus-directive discriminates here exactly as it did on `local-immigration` in
-- migration 1766: SB 5471 says a county "may", SB 5184 says a city "may not require". The four who
-- signed the mandatory one hold the stronger position.
-- ⚠ Not a breach of the cohort rule: SB 5471 sets chair 2 as the floor for all seven of its sponsors,
-- and SB 5184 raises it for the four who also signed that.
--
-- 🔴 A GAP THIS COHORT EXPOSES, FOR THE LADDER OWNER. Goehner's other land-use bills — SB 5659
-- ("eliminating each local government's proportional share of Washington's housing shortage") and
-- SB 5470 — express a LOCAL CONTROL position: the state should not mandate density outcomes,
-- counties should choose. No chair on this ladder describes that. All five prescribe a density
-- outcome. A very common land-use position therefore has nowhere to sit, and the only reason these
-- seven are seatable at all is that SB 5471 happens to authorise a specific density type.
BEGIN;

CREATE TEMP TABLE rz_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has a residential-zoning answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has a residential-zoning context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='eba44d6a-6602-4a90-bef0-44ab12db6109' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marko Liias already has a residential-zoning answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='eba44d6a-6602-4a90-bef0-44ab12db6109' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marko Liias already has a residential-zoning context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4991ee01-0a35-454f-bdf6-bb2f34cf1c30' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Noel Frame already has a residential-zoning answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4991ee01-0a35-454f-bdf6-bb2f34cf1c30' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Noel Frame already has a residential-zoning context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='436194e1-479e-4066-8d99-f325fd6bb880' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: T''wina Nobles already has a residential-zoning answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='436194e1-479e-4066-8d99-f325fd6bb880' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: T''wina Nobles already has a residential-zoning context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f3cd74bb-3bdb-4d55-a07d-5c14bda50926' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Keith Goehner already has a residential-zoning answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f3cd74bb-3bdb-4d55-a07d-5c14bda50926' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Keith Goehner already has a residential-zoning context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Chapman already has a residential-zoning answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Chapman already has a residential-zoning context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has a residential-zoning answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has a residential-zoning context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d' AND value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: residential-zoning chair 2 not defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d' AND value=4;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: residential-zoning chair 4 not defined exactly once (%)', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('1e6d175b-1af0-444c-b373-e5d0a279d240','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Prime sponsor of SB 5471, which lets counties authorise middle housing on any parcel that already permits a single-family home in unincorporated urban growth areas; and of SB 5184 (Chapter law, 2025), which caps minimum parking requirements statewide — a city "may not require more than 0.5 parking spaces" per unit — on the finding that parking mandates "needlessly drive up the cost of development, particularly housing".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5471.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5184-S.SL.pdf']),
('eba44d6a-6602-4a90-bef0-44ab12db6109','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Co-sponsor of SB 5471, which lets counties authorise middle housing on any parcel that already permits a single-family home in unincorporated urban growth areas; and of SB 5184 (Chapter law, 2025), which caps minimum parking requirements statewide — a city "may not require more than 0.5 parking spaces" per unit — on the finding that parking mandates "needlessly drive up the cost of development, particularly housing".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5471.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5184-S.SL.pdf']),
('4991ee01-0a35-454f-bdf6-bb2f34cf1c30','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Co-sponsor of SB 5471, which lets counties authorise middle housing on any parcel that already permits a single-family home in unincorporated urban growth areas; and of SB 5184 (Chapter law, 2025), which caps minimum parking requirements statewide — a city "may not require more than 0.5 parking spaces" per unit — on the finding that parking mandates "needlessly drive up the cost of development, particularly housing".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5471.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5184-S.SL.pdf']),
('436194e1-479e-4066-8d99-f325fd6bb880','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Co-sponsor of SB 5471, which lets counties authorise middle housing on any parcel that already permits a single-family home in unincorporated urban growth areas; and of SB 5184 (Chapter law, 2025), which caps minimum parking requirements statewide — a city "may not require more than 0.5 parking spaces" per unit — on the finding that parking mandates "needlessly drive up the cost of development, particularly housing".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5471.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5184-S.SL.pdf']),
('f3cd74bb-3bdb-4d55-a07d-5c14bda50926','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Prime sponsor of SB 5471 (Chapter law, 2025), which lets a county authorise middle housing — duplexes and similar — on any parcel that already permits a single-family home in unincorporated urban growth areas, provided the parcel is served by water and sewer. Adoption is optional and happens by county ordinance.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5471.SL.pdf']),
('cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Co-sponsor of SB 5471 (Chapter law, 2025), which lets a county authorise middle housing — duplexes and similar — on any parcel that already permits a single-family home in unincorporated urban growth areas, provided the parcel is served by water and sewer. Adoption is optional and happens by county ordinance.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5471.SL.pdf']),
('4218b4c2-d642-431e-a279-5aff5100379f','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Co-sponsor of SB 5471 (Chapter law, 2025), which lets a county authorise middle housing — duplexes and similar — on any parcel that already permits a single-family home in unincorporated urban growth areas, provided the parcel is served by water and sewer. Adoption is optional and happens by county ordinance.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5471.SL.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('1e6d175b-1af0-444c-b373-e5d0a279d240','d4f18138-a2e0-4110-b925-7387d9d0d16d', 4),
('eba44d6a-6602-4a90-bef0-44ab12db6109','d4f18138-a2e0-4110-b925-7387d9d0d16d', 4),
('4991ee01-0a35-454f-bdf6-bb2f34cf1c30','d4f18138-a2e0-4110-b925-7387d9d0d16d', 4),
('436194e1-479e-4066-8d99-f325fd6bb880','d4f18138-a2e0-4110-b925-7387d9d0d16d', 4),
('f3cd74bb-3bdb-4d55-a07d-5c14bda50926','d4f18138-a2e0-4110-b925-7387d9d0d16d', 2),
('cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','d4f18138-a2e0-4110-b925-7387d9d0d16d', 2),
('4218b4c2-d642-431e-a279-5aff5100379f','d4f18138-a2e0-4110-b925-7387d9d0d16d', 2);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM rz_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 7 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +7', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 7 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +7', s.ctx_before, ctx_after; END IF;
END $$;

DO $$
DECLARE bad int; c4 int; c2 int;
BEGIN
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d' AND a.politician_id IN ('1e6d175b-1af0-444c-b373-e5d0a279d240','eba44d6a-6602-4a90-bef0-44ab12db6109','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','436194e1-479e-4066-8d99-f325fd6bb880')
     AND (a.value <> 4 OR c.reasoning !~ 'may not require more than' OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5184-S.SL.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-4 row(s) wrong chair, missing the mandatory parking clause, or missing SB 5184', bad; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d' AND a.politician_id IN ('f3cd74bb-3bdb-4d55-a07d-5c14bda50926','cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','4218b4c2-d642-431e-a279-5aff5100379f')
     AND (a.value <> 2 OR c.reasoning !~ 'Adoption is optional' OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5471.SL.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-2 row(s) wrong chair, missing the permissive clause, or missing SB 5471', bad; END IF;

  SELECT count(*) INTO c4 FROM inform.politician_answers WHERE topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d' AND value=4 AND politician_id IN ('1e6d175b-1af0-444c-b373-e5d0a279d240','eba44d6a-6602-4a90-bef0-44ab12db6109','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','436194e1-479e-4066-8d99-f325fd6bb880');
  SELECT count(*) INTO c2 FROM inform.politician_answers WHERE topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d' AND value=2 AND politician_id IN ('f3cd74bb-3bdb-4d55-a07d-5c14bda50926','cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','4218b4c2-d642-431e-a279-5aff5100379f');
  IF c4 <> 4 THEN RAISE EXCEPTION 'guard 2: chair-4 count is %, expected 4', c4; END IF;
  IF c2 <> 3 THEN RAISE EXCEPTION 'guard 2: chair-2 count is %, expected 3', c2; END IF;
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

  RAISE NOTICE 'residential-zoning: 3 at chair 2, 4 at chair 4; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
