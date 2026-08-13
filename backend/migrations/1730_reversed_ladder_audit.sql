-- 1730_reversed_ladder_audit.sql
-- WHICH LADDERS ARE REVERSED — all 44 live topics audited, then the outliers scanned.
--
-- Migration 1729 closed the six topics 1714's scan never judged, and its finding was that the real
-- question is not "which topics have inversions" but "WHICH LADDERS RUN THE OTHER WAY". This is
-- that audit: chair-1 text vs chair-5 text for every one of the 44 topics carrying answers.
--
-- 🔑 THE CORPUS CONVENTION IS: chair 1 = maximum government action, chair 5 = minimum. 42 of 44
-- topics follow it. TWO DO NOT:
--   · Artificial Intelligence Oversight — chair 1 "allow AI companies to develop and deploy
--     technology freely", chair 5 "ban AI systems that could cause serious harm". (Fixed in 1729.)
--   · **Tariffs** — chair 1 "eliminate all tariffs and pursue completely free trade", chair 5
--     "impose high tariffs on all imports". Minimum intervention sits at chair 1, not chair 5.
--     3,315 rows, NEVER SCANNED before now.
--
-- ⚠ THREE MORE ARE NOT REVERSED BUT ARE OFF-AXIS, which is just as dangerous for a lexicon:
--   · Residential Zoning — chair 1 protects neighborhood character, chair 5 eliminates
--     single-family-only zoning. Deregulatory AND progressive sit at the SAME end, so both a
--     "pro-government" lexicon and a "progressive" lexicon point the wrong way. This already bit
--     migration 1727, where six rows at chair 4-5 were correct.
--   · Growth and Development Pace — same shape.
--   · Government Deference (judicial) — chair 1 is "side with the citizen against government",
--     which is not an intervention axis at all.
--
-- SCANNED the three off-convention topics symmetrically — pro-worded at the anti pole AND
-- anti-worded at the pro pole, since neither direction can be assumed:
--   Tariffs             5 + 25 candidates →  1 inversion
--   Residential Zoning  3 + 24 candidates →  7
--   Growth Pace         4 +  2 candidates →  2
--
-- 🔑 TARIFFS IS ALMOST ENTIRELY CLEAN and for the now-familiar reason: 24 of its 25 candidates are
-- genuine tariff supporters whose rows contain "free trade" only as the OBJECT of what they
-- oppose — "opposes free trade", "fair trade not free trade", "voted NO on SJR 7", the California
-- resolution against Trump's tariffs. The one real inversion is **Laura Richardson**, who voted
-- YES on that resolution and sat at chair 4, "increase tariffs on countries that don't trade
-- fairly". She moves to 3, "use tariffs selectively" — opposing BROAD tariffs is not the same as
-- opposing all of them, and chair 3 is the least extreme option her vote supports.
--
-- 🔑 RESIDENTIAL ZONING IS WHERE THE OFF-AXIS LADDER ACTUALLY COST US, and it cost us in BOTH
-- directions, which no single-direction scan would have found:
--   · Maura Healey — "the most aggressive governor in Massachusetts history on upzoning", stored at
--     chair 1, "protect existing neighborhood character strictly". → 4.
--   · Jake Auchincloss — "the most prominent YIMBY in the MA delegation … explicitly advocated for
--     ending single-family-only zoning" — that is chair 5's text — stored at chair 2. → 4.
--   · Jake Wilson and Kevin G. Honan both carry the MBTA Communities Act, which mandates by-right
--     multifamily zoning near transit, at chairs 1 and 2. → 3, the option scoped to transit and
--     commercial corridors.
--   · Cassie Julia and Flavia DeBrito both voted to eliminate parking minimums statewide (LD 427),
--     stored at chair 1. → 2.
--   · And the other way: **Drew Boyles** "advocated regionally and statewide to protect
--     single-family housing neighborhoods" while stored at chair 4, the upzoning option. → 1.
--
-- ⚠ ROWS READ AND KEPT — the off-axis ladders make the keeps as informative as the changes.
-- Chris Null keeps chair 4 ("market-based approaches to housing supply" IS the upzoning end).
-- Roxanne Ziegler and Joyce Jones-Ivey keep Growth chair 4 — both APPROVED large developments.
-- Patrick Cloutier, Steven Deffibaugh, Tim Flaherty and Victor Gordo keep Residential Zoning
-- chair 2: their rows are restrictive (a development moratorium, wider setbacks, objecting to
-- state upzoning mandates) and chair 2 is already on the restrictive half, so they are understated
-- at worst, not inverted. Only rows crossing the ladder's midpoint were changed.
--
-- 🔑 CHAIRS ONLY. No reasoning or sourcing touched.
--
-- Rollback: data/stance-retirement/2026-08-12-reversed-ladder-1730-rollback.json
BEGIN;

CREATE TEMP TABLE rl_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE rl_want (pid uuid, tid uuid, val_before numeric, want numeric) ON COMMIT DROP;
INSERT INTO rl_want VALUES
-- Tariffs (683c8084) — the second reversed ladder.
('9edc0c37-f213-4aae-9212-c9cb4780d854','683c8084-2281-4920-a07c-18439b2dd413',4,3), -- Laura Richardson: voted YES on SJR 7 opposing broad tariffs
-- Residential Zoning (d4f18138) — off-axis; inversions in BOTH directions.
('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','d4f18138-a2e0-4110-b925-7387d9d0d16d',1,4), -- Maura Healey: most aggressive MA governor on upzoning
('41945b74-325e-4fa2-9cc9-edd11ead9ed3','d4f18138-a2e0-4110-b925-7387d9d0d16d',2,4), -- Jake Auchincloss: advocated ending single-family-only zoning
('41ced04d-7403-4170-a267-c339191e6fcd','d4f18138-a2e0-4110-b925-7387d9d0d16d',1,3), -- Jake Wilson: championed the MBTA Communities by-right multifamily law
('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','d4f18138-a2e0-4110-b925-7387d9d0d16d',2,3), -- Kevin G. Honan: co-authored the MBTA Communities Act
('ad28f54e-0639-4005-ade9-3be3b90c3d39','d4f18138-a2e0-4110-b925-7387d9d0d16d',1,2), -- Cassie Julia: voted Yea on LD 427 ending parking minimums
('21f45688-4e19-42bb-b1c0-e17b5dba2d3a','d4f18138-a2e0-4110-b925-7387d9d0d16d',1,2), -- Flavia DeBrito: voted Yea on LD 427 ending parking minimums
('4e485d3a-79a0-40ce-a52f-f84d187bf5de','d4f18138-a2e0-4110-b925-7387d9d0d16d',4,1), -- Drew Boyles: advocated to protect single-family neighborhoods
-- Growth and Development Pace (fb25c1ac) — same off-axis shape.
('2d47a965-81a2-4508-865c-06d45bf6ff42','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',4,2), -- Christine Parra: platform centers slow growth
('7714b7c6-9283-4ab8-802e-cbcfba5ddc96','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',4,2); -- Phil Brock: supports slow growth, opposes tall development

UPDATE inform.politician_answers a SET value = w.want
FROM rl_want w
WHERE a.politician_id = w.pid AND a.topic_id = w.tid AND a.value = w.val_before;

-- Guard 1: all 10 rows exist and hold exactly the intended chair.
DO $$
DECLARE bad int; n int;
BEGIN
  SELECT count(*) FILTER (WHERE a.value <> w.want), count(*) INTO bad, n
  FROM rl_want w JOIN inform.politician_answers a ON a.politician_id=w.pid AND a.topic_id=w.tid;
  IF n <> 10 THEN RAISE EXCEPTION 'guard 1 failed: matched % rows, expected 10', n; END IF;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) do not hold the intended chair', bad; END IF;
END $$;

-- Guard 2: chairs only, nothing created or deleted, no orphans, every value on the ladder.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; off_ladder int; snap record;
BEGIN
  SELECT * INTO snap FROM rl_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;
  SELECT count(*) INTO off_ladder FROM inform.politician_answers WHERE value NOT IN (1,2,3,4,5);
  IF off_ladder > 0 THEN RAISE EXCEPTION 'guard 2 failed: % off-ladder value(s)', off_ladder; END IF;
END $$;

-- Guard 3: the ladder audit's premise — Tariffs and AI Oversight really are the two topics whose
-- chair 1 is the minimum-intervention end. If a future edit reworded either ladder into line with
-- the other 42, this pass's targets would silently become wrong, so pin the two texts.
DO $$
DECLARE tariff_1 text; ai_1 text;
BEGIN
  SELECT s.text INTO tariff_1 FROM inform.compass_stances s
   WHERE s.topic_id='683c8084-2281-4920-a07c-18439b2dd413'::uuid AND s.value=1;
  SELECT s.text INTO ai_1 FROM inform.compass_stances s
   WHERE s.topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'::uuid AND s.value=1;
  IF tariff_1 NOT ILIKE '%eliminate all tariffs%' THEN
    RAISE EXCEPTION 'guard 3 failed: the Tariffs chair-1 text is no longer the free-trade pole';
  END IF;
  IF ai_1 NOT ILIKE '%without government interference%' THEN
    RAISE EXCEPTION 'guard 3 failed: the AI Oversight chair-1 text is no longer the laissez-faire pole';
  END IF;
  RAISE NOTICE 'reversed-ladder audit ok: 44 topics audited, 10 chairs corrected';
END $$;

COMMIT;
