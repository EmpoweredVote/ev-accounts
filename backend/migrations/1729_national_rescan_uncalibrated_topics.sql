-- 1729_national_rescan_uncalibrated_topics.sql
-- THE NATIONAL RE-SCAN — the six topics migration 1714's scan never judged.
--
-- 1714 flagged inversions only in topics its calibration step could score. Four topics scored
-- UNCALIBRATED and contributed no flags (Voting Rights, Reproductive Rights, Immigration, Fossil
-- Fuel); two more were excluded BY HAND as "object-ambiguous" (School Vouchers, AI Oversight).
-- Migration 1727 established the polarity of all six while sweeping 24 politicians. This is that
-- polarity applied to the whole corpus.
--
-- SCANNED: 3,166 rows sitting at their topic's anti pole across the six topics.
-- READ: 185 candidates (unambiguously pro-worded for that topic's pro pole, any oppositional
-- marker disqualifying — 1714's refined rule). CORRECTED: 14.
--
--   topic                     anti-pole rows   candidates   inversions
--   Voting Rights                       574           30            0
--   Reproductive Rights                 691           26            0
--   Immigration                         638          103            1
--   Fossil Fuel                         578            9            2
--   School Vouchers                     534            2            2
--   AI Oversight (pole = 1-2)           151           15            9
--
-- 🔑🔑 THE FOUR "UNCALIBRATED" TOPICS ARE ESSENTIALLY CLEAN — 3 inversions in 2,481 anti-pole rows.
-- The calibration step was RIGHT to refuse them, and the reason is now legible: in exactly these
-- topics the pro-lexicon appears overwhelmingly as the OBJECT OF AN OPPOSING VERB, because the
-- pro side owns the bill names. All 30 Voting Rights candidates and all 26 Reproductive Rights
-- candidates are genuine opponents whose rows say "voted against the For the People Act", "voted
-- NO on the John Lewis Voting Rights Advancement Act", "voted against the Women's Health
-- Protection Act", "opposed the Abortion Care Access Act". A lexicon cannot see that "against"
-- governs the phrase it matched. **0 for 56.**
--
-- 🔴🔴 THE YIELD IS IN THE TWO HAND-EXCLUDED TOPICS — 11 of the 14. AI Oversight was excluded as
-- object-ambiguous, but the real problem is that ITS LADDER IS REVERSED: chair 1 is "allow AI
-- companies to develop and deploy technology freely without government interference" and chair 5
-- is "ban AI systems that could cause serious harm". So its anti pole is 1-2, which no scan
-- looking at 4-5 could ever have reached. Nine legislators who wrote AI-safety law sat at the
-- laissez-faire end: Katie Fry Hester (bills banning election deepfakes), Lindsay Sabadosa
-- (banned algorithmic rent-fixing), Ayanna Pressley (co-led the Facial Recognition and Biometric
-- Technology Moratorium Act), Haley Stevens (pre-deployment safety and ethics review).
--
-- ⚠ AND THE SAME TOPIC PROVES THE READING WAS NECESSARY. Raul Campillo's row also matched
-- "banning algorithmic" — but he cast the SOLE dissenting vote AGAINST San Diego's ban, so chair 2
-- is his actual position. Rosilicie Ochoa Bogh voted NO on SB 1047, the AI safety testing bill.
-- Both KEPT. Six of the 15 AI candidates were kept, along with Ashley Moody, Kevin Sparks, and two
-- rows evidencing only committee membership or hearing attendance, which is not a position.
--
-- ⚠ Immigration yielded exactly ONE: Cecilia Lunaparra (Berkeley), who authored the Sanctuary City
-- Contracting Ordinance and co-sponsored the $200,000 deportation defense fund, sitting at chair 5
-- — "stop most legal immigration and block public services for anyone without legal status". The
-- other 10 clean candidates are restrictionists whose rows name sanctuary law, DACA and in-state
-- tuition as the things they are REPEALING. Same shape as Voting Rights.
--
-- 🔑 TARGET = THE LEAST EXTREME PRO-SIDE OPTION THE REASONING SUPPORTS. On AI Oversight that means
-- 4 ("require safety testing and ban high-risk AI uses") for the members who wrote bans, and 3
-- ("require developers to disclose risks and be held responsible") for transparency and
-- anti-preemption records. Pressley's Fossil Fuel row goes to 2, "stop issuing new permits" —
-- the Keep It in the Ground Act ends new federal leases, which is that option, not chair 1's
-- immediate ban on all extraction.
--
-- 🔑 CHAIRS ONLY. No reasoning or sourcing touched.
--
-- Rollback: data/stance-retirement/2026-08-12-national-rescan-1729-rollback.json
BEGIN;

CREATE TEMP TABLE nr_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE nr_want (pid uuid, tid uuid, val_before numeric, want numeric) ON COMMIT DROP;
INSERT INTO nr_want VALUES
-- AI Oversight — the ladder is REVERSED, so these sat at the laissez-faire pole (1-2).
('6da20195-1b0c-43f2-b1b3-7a3954326fe6','666bf03d-81fc-4138-ab15-69ae734c9023',2,4), -- Katie Fry Hester: bills banning election deepfakes and unsafe minor chatbots
('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd','666bf03d-81fc-4138-ab15-69ae734c9023',2,4), -- Lindsay Sabadosa: H.1564 banning algorithmic rent-fixing
('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','666bf03d-81fc-4138-ab15-69ae734c9023',2,4), -- Ayanna Pressley: Facial Recognition and Biometric Technology Moratorium Act
('5b642054-504c-46c8-a68b-324e7b593587','666bf03d-81fc-4138-ab15-69ae734c9023',2,4), -- Haley M. Stevens: pre-deployment safety and ethics review
('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1','666bf03d-81fc-4138-ab15-69ae734c9023',2,3), -- Abigail Spanberger: AI Accountability Act, impact assessments and transparency
('77ceaab2-846e-4bc8-b09d-faff40ddbc60','666bf03d-81fc-4138-ab15-69ae734c9023',2,3), -- Francisco E. Paulino: H.1931, emerging-technology child protection
('d423151e-8477-470d-8f73-ba7d2092f714','666bf03d-81fc-4138-ab15-69ae734c9023',1,3), -- Brian J. Feldman: signed the letter opposing federal preemption of state AI law
('fc23b939-0dfd-4968-ab19-fc1e7745e997','666bf03d-81fc-4138-ab15-69ae734c9023',1,3), -- Clarence K. Lam: SB0987 (2025), AI oversight in health insurance decisions
('85d27350-e1b6-45b8-aee3-509ca88c5af4','666bf03d-81fc-4138-ab15-69ae734c9023',1,3), -- Mark Warner: lead sponsor of the RESTRICT Act
-- Fossil Fuel Policy — the restrictive chair is the pro-climate one.
('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','a22215c3-6693-4bc2-b248-01aebba14570',5,2), -- Ayanna Pressley: Keep It in the Ground Act, ends new federal fossil leases
('e1f72270-5809-4d0e-969c-48d1ab34fbdc','a22215c3-6693-4bc2-b248-01aebba14570',4,2), -- Patrick M. O'Connor: co-sponsored 100% Renewable Energy by 2045
-- School Vouchers — chair 1 is "fully fund public schools and eliminate vouchers".
('30b6b674-509f-46f6-a9aa-aa3dbefc2f42','00b95a6a-75db-4521-b523-3326bba938de',5,1), -- Diana DiZoglio: consistently opposed vouchers and public-funds diversion
('98291d86-d42d-49d0-a5b2-d689a8154b15','00b95a6a-75db-4521-b523-3326bba938de',5,1), -- Erika Uyterhoeven: opposed charter expansion and vouchers, fully funded public schools
-- Immigration
('116aace8-9440-498b-bf1d-ebb196727c85','4e2c69ce-591e-4197-9cd5-7aceff79d390',5,2); -- Cecilia Lunaparra: Sanctuary City Contracting Ordinance, deportation defense fund

UPDATE inform.politician_answers a SET value = w.want
FROM nr_want w
WHERE a.politician_id = w.pid AND a.topic_id = w.tid AND a.value = w.val_before;

-- Guard 1: all 14 rows exist and hold exactly the intended chair.
DO $$
DECLARE bad int; n int;
BEGIN
  SELECT count(*) FILTER (WHERE a.value <> w.want), count(*) INTO bad, n
  FROM nr_want w JOIN inform.politician_answers a ON a.politician_id=w.pid AND a.topic_id=w.tid;
  IF n <> 14 THEN RAISE EXCEPTION 'guard 1 failed: matched % rows, expected 14', n; END IF;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) do not hold the intended chair', bad; END IF;
END $$;

-- Guard 2: chairs only, nothing created or deleted, no orphans, every value on the 1-5 ladder.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; off_ladder int; snap record;
BEGIN
  SELECT * INTO snap FROM nr_snapshot;
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

-- Guard 3: the two AI Oversight rows deliberately KEPT at the laissez-faire pole are still there.
-- Campillo voted against San Diego's algorithmic-rent ban and Ochoa Bogh voted NO on SB 1047; if a
-- later pass sweeps them it will have stopped reading the rows.
DO $$
DECLARE kept int;
BEGIN
  SELECT count(*) INTO kept FROM inform.politician_answers a
  JOIN essentials.politicians p ON p.id = a.politician_id
  WHERE a.topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid AND a.value <= 2
    AND p.full_name IN ('Raul Campillo', 'Rosilicie Ochoa Bogh');
  IF kept <> 2 THEN RAISE EXCEPTION 'guard 3 failed: % of the 2 deliberately kept AI rows remain', kept; END IF;
  RAISE NOTICE 'national re-scan ok: 14 chairs corrected across 6 topics';
END $$;

COMMIT;
