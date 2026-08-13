-- 1741_md_taxation_reexamined.sql
-- Re-examines the 13 Maryland Taxation rows that mig 1736 blanked. **11 blanks stand; 2 rows are
-- restored.** This migration therefore only INSERTS two answers — but the point of the pass is as much
-- the 11 it leaves alone, and guard 4 exists to prove it left them alone.
--
-- ── 🔴🔴 WHY REOPEN AT ALL: 1736's STATED REASON WAS WRONG ────────────────────────────────────
-- 1736 blanked all 13 on one premise, recorded verbatim: chair 2's "only difference from chair 1 is
-- MAGNITUDE", so sponsorship "cannot prove moderately". **That misreads the chair text.** The full
-- options are:
--   ch1  "Significantly raise taxes on wealthy people and large companies to fund MORE public services"
--   ch2  "Moderately raise taxes on wealthy people and large companies to fund EXISTING services"
-- The second half is not an adverb, it is a **PURPOSE test — MORE services versus EXISTING services —
-- and a purpose is documentable** from where a bill sends its revenue. That is what this pass tests,
-- and it is the same discriminator that settled Elo-Rivera in mig 1740.
--
-- ── ✅ RESTORED AT CHAIR 1: Alonzo T. Washington ──────────────────────────────────────────────
-- 🔑 THE ONE ROW WHERE EVEN THE ADVERB IS IN A STATE DOCUMENT. **HB0695 (2020), and he is its SOLE
--    sponsor** — the strongest attribution in the cohort:
--   · "large companies": the tax reaches only businesses with **at least $100.0 million** in global
--     annual gross revenues. The threshold is in the bill, not inferred.
--   · "fund MORE public services": the synopsis requires the Comptroller to distribute the revenue to
--     **The Blueprint for Maryland's Future Fund**, a special nonlapsing fund for the Kirwan education
--     programme, which the fiscal note says needs **an additional $2.8 billion in State funding and
--     $1.2 billion in local funding by fiscal 2030**. That is an expansion, not the general fund.
--   · "significantly": the fiscal note states special fund revenues "may increase by **a significant
--     amount**", as much as **$250.0 million** in the first full year. The very adverb 1736 called
--     unprovable is the state's own word for this bill.
-- ⚠ Kept visible rather than laundered: he also co-sponsored **HB0222**, the 1% capital gains surtax
--    whose $120.9 million goes to the **general fund** — an instrument that fits chair 2, not chair 1.
--    His sole-sponsored, earmarked bill is the stronger attribution and governs; the tension is stated
--    in the reasoning.
-- ⚠ He also appears on Maryland Estate Tax - Unified Credit bills, which RAISE the exemption and so cut
--    tax on wealthy estates. Co-sponsorships on a technical/portability measure, noted not hidden.
--
-- ── ✅ RESTORED AT CHAIR 2: Sara Love ─────────────────────────────────────────────────────────
-- **HB0222 (2020)**, co-sponsor. The cleanest chair-2-shaped instrument in the whole Maryland set,
-- because all three clauses are in the bill and its fiscal note at once: **one percentage point**
-- ("moderately"), on **net capital gains of individuals** ("wealthy people"), yielding **$120.9 million
-- of GENERAL FUND revenue** with no earmark ("existing services").
--
-- ── ▶ 11 BLANKS STAND, WITH THE REASON CORRECTED ─────────────────────────────────────────────
-- The outcome is unchanged but the reasoning is not, and the distinction matters for the next pass:
--   · 4 rows have **no qualifying instrument at all** in a complete record (Muse 127 candidates,
--     Waldstreicher 151, Charles, Henson). All 13 members have **0 unreadable sessions**, so absence is
--     a safe finding here.
--   · 6 rows (Kagan, Rosapepe, Smith, Ellis, Benson, Watson) rest entirely on **combined reporting,
--     the throwback rule, Corporate Tax Fairness and carried interest**. Read rather than titled, none
--     of these raises a RATE: they broaden the base by ending profit-shifting and the carried-interest
--     preference. That is **chair 3's literal clause, "small adjustments to close unfair loopholes"**,
--     as much as chair 2's "raise taxes on large companies" — so chair 2 cannot beat chair 3 and the
--     row is not evidenced. Decided with the user rather than re-seated to chair 3 silently.
--   · 1 row (Kramer) rested on a bill that is **not a tax increase at all**: SB0523 (2020) is the
--     pass-through entity **election**, a SALT-cap workaround that benefits pass-through owners.
--
-- ── 🔴🔴 TWO DEFECTS FOUND IN THE MD TOOLING, BOTH TITLE-LEVEL TRAPS ─────────────────────────
-- 1. **THE CANDIDATE LISTS CONTAIN CROSSFILES, NOT ONLY SPONSORSHIPS.** Alonzo Washington's 293
--    on-topic candidates include **102 Senate bills from sessions before 2023, when he was a Delegate
--    and could not sponsor a Senate bill** — they are the Senate companions of his House bills, which
--    mgaleg member pages also list. SB0002 (2020) sits in his list and is sponsored by Senators Miller
--    and Ferguson. **A candidate list entry is a reading queue item, never a sponsorship**; verify
--    against the bill's own sponsor line, in the right chamber. Generalises the surname trap in
--    [[md_sponsor_identity_traps]].
-- 2. **"Business Relief and Tax Fairness Act" IS NOT A TAX BILL.** Its synopsis is about **fees
--    collected by the State Department of Assessments and Taxation for filing** business documents. It
--    was about to be scored as counter-evidence — a tax cut for business — across Muse (12), Benson
--    (16), Waldstreicher (10) and others, purely on the words "Relief" and "Tax Fairness" in the title.
--    Off-axis for this ladder entirely.
-- ⚠ Also corrected by reading: `/surcharge/` in a first-cut net matched **court fees, civil-case
--    surcharges, eviction filing surcharges and development impact fees** — none a tax on the wealthy.
--
-- Rollback: data/stance-retirement/2026-08-13-md-taxation-1741-rollback.json
BEGIN;

CREATE TEMP TABLE tx_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE tx_intent (pid uuid, tid uuid, chair numeric, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO tx_intent (pid, tid, chair, reasoning, sources) VALUES

-- ─────────── RESTORED AT CHAIR 1: Alonzo T. Washington ───────────
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','f7e5678d-dadd-4556-a2fc-446e24642ceb', 1,
 'Washington was the sole sponsor of HB0695 in the 2020 session, imposing a tax on annual gross revenues derived from digital advertising services in Maryland. The tax reaches only large companies: the fiscal note records that it applies to businesses with at least $100 million in global annual gross revenues. The bill requires the Comptroller to distribute the revenue, after administration costs, to the Blueprint for Maryland''s Future Fund, a special nonlapsing fund for the state''s education programme whose recommendations the fiscal note says are expected to require an additional $2.8 billion in state funding and $1.2 billion in local funding by fiscal 2030, so the proceeds expand services rather than sustain existing ones. On magnitude the fiscal note states that special fund revenues may increase by a significant amount, as much as $250 million in the first full year the tax is collected. He also co-sponsored HB1051 in 2018 applying the corporate income tax throwback rule to sales into states where a corporation is not taxable. His record is not uniformly aimed at expansion: he co-sponsored HB0222 in 2020, a one percentage point additional rate on net capital gains whose $120.9 million would have gone to the general fund rather than to a dedicated programme.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0695?ys=2020RS','https://mgaleg.maryland.gov/2020RS/fnotes/bil_0005/hb0695.pdf','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1051?ys=2018RS']::text[]),

-- ─────────── RESTORED AT CHAIR 2: Sara Love ───────────
('c5d2cd24-170a-4f87-8fde-84216fe62806','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2,
 'Love co-sponsored HB0222 in the 2020 session, providing for an additional state individual income tax rate of one percent on the net capital gains of individuals. All three elements of the seated position are documented in the bill and its fiscal note rather than inferred: the increase is a single percentage point, it falls on net capital gains income of individuals, and the fiscal note records that general fund revenues would increase by $120.9 million in fiscal 2021 with no dedication of the proceeds to any new programme, so the revenue would sustain existing services. This is her only instrument in the readable record that raises a tax on wealthy people or large companies.',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0222?ys=2020RS','https://mgaleg.maryland.gov/2020RS/fnotes/bil_0002/hb0222.pdf']::text[]);

-- The rows were BLANKED by 1736, so the answer must be INSERTed, not updated. Context always survived.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT i.pid, i.tid, i.chair FROM tx_intent i
WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id = i.pid AND a.topic_id = i.tid);

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM tx_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

-- Guard 1: both restored rows sit at their intended chair with their intended text and sources.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM tx_intent i
  LEFT JOIN inform.politician_answers a ON a.politician_id=i.pid AND a.topic_id=i.tid
  LEFT JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE a.value IS DISTINCT FROM i.chair
     OR c.reasoning IS DISTINCT FROM i.reasoning
     OR c.sources IS DISTINCT FROM i.sources;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) not as intended', bad; END IF;
END $$;

-- Guard 2: the gate's own test, plus the fiscal note. Every restored row must name its bill AND cite
-- the fiscal note that carries the revenue destination — the purpose clause is the whole basis here,
-- so a row without its fiscal note would be a chair seated on a synopsis.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM tx_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning !~ '\mHB0(695|222)\M'
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%fnotes%')
     OR EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s ILIKE '%ballotpedia%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 2 failed: % row(s) name no bill, cite no fiscal note, or still cite ballotpedia', bad; END IF;
END $$;

-- Guard 3: row-count arithmetic. Exactly 2 answers appear; context never moves.
DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM tx_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 2 THEN
    RAISE EXCEPTION 'guard 3 failed: answers % -> %, expected +2', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 3 failed: context moved % -> %', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 4: 🔑 THE POINT OF THE PASS. The other ELEVEN taxation rows must STILL BE BLANK. A
-- re-examination that quietly restored the cohort it was meant to test would be worthless, and mig
-- 1732 is the precedent for a pass having to undo its predecessor's over-reach.
DO $$
DECLARE seated int;
BEGIN
  SELECT count(*) INTO seated FROM inform.politician_answers a
   WHERE a.topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND a.politician_id IN (
       '4754dede-4a3b-4280-a8b1-7497530107f7', -- Arthur Ellis
       '7a2d1548-3268-4767-97a8-bb8b142d5a33', -- Benjamin F. Kramer
       '47823046-7dea-4a4f-a11b-0c5890539891', -- C. Anthony Muse
       'e35d5990-55c7-42e2-94bc-27cb1c49b5f1', -- Cheryl C. Kagan
       'da75c207-bb23-477e-b3c0-7c462394b570', -- Jeff Waldstreicher
       '9c400214-f007-4a8d-92fe-5f5d23b3838e', -- Jim Rosapepe
       '4a7dc8a6-2138-4472-8197-8b878034f029', -- Joanne C. Benson
       'cf190bac-9369-4175-bd4b-8ba776697d9c', -- Nick Charles
       '9aef8bfb-8e0c-4f00-9898-c738abe4970c', -- Ron Watson
       '05c9b5b9-cb2b-4387-ab6b-350b69553fac', -- Shaneka Henson
       'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'  -- William C. Smith, Jr.
     );
  IF seated > 0 THEN RAISE EXCEPTION 'guard 4 failed: % of the 11 confirmed blanks got re-seated', seated; END IF;
END $$;

-- Guard 5: those 11 kept their politician_context. The re-examination read their records; it must not
-- have destroyed the research behind them.
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing FROM (VALUES
    ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid),('7a2d1548-3268-4767-97a8-bb8b142d5a33'),
    ('47823046-7dea-4a4f-a11b-0c5890539891'),('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'),
    ('da75c207-bb23-477e-b3c0-7c462394b570'),('9c400214-f007-4a8d-92fe-5f5d23b3838e'),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'),('cf190bac-9369-4175-bd4b-8ba776697d9c'),
    ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'),('05c9b5b9-cb2b-4387-ab6b-350b69553fac'),
    ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc')) v(pid)
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                     WHERE c.politician_id = v.pid
                       AND c.topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb');
  IF missing > 0 THEN RAISE EXCEPTION 'guard 5 failed: % of the 11 lost their context', missing; END IF;
END $$;

COMMIT;
