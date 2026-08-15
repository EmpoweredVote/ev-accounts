-- 1757_ca_berkeley_orphan_context_blanks.sql
-- The last four ORPHAN_CONTEXT rows above baseline, and the end of the 224 regression.
--
-- Blanked by 1738 (3) and 1739 (1) with the answer deleted and the context kept -- the same shape as
-- the Maryland rows in 1756 and the judicial rows in 1755. Third time in one investigation, so it is
-- the pattern and not an accident: a pass that deletes an answer and leaves the reasoning creates a
-- gate violation the pass itself never sees.
--
-- The prose left behind reads as support for the very chair the pass rejected. Blackaby's row still
-- narrates the $200,000 deportation defence fund; Taplin's still quotes "police officers are not
-- social workers"; Tregub's still lists two pedestrian-safety budget referrals. Write an answer for
-- any of these pairs and Citations.jsx publishes that text under "Why this position?" -- the exact
-- sentence a reader would take as the justification for a chair the record does not support.
--
-- 🔑 EACH BLANK IS RESTATED FROM THE FINDING THAT PRODUCED IT, NOT COMPOSED FRESH. Two of them turn on
-- a distinction worth keeping visible:
--  · Blackaby / Deportation — the ladder asks WHO should be deported; a city instrument answers
--    WHETHER THE CITY COOPERATES. Same structural mismatch that blanked all five MD Immigration rows.
--  · Taplin / Public Safety — the sole mental-health item is a CEREMONIAL PROCLAMATION. On-topic by
--    VOCABULARY, not by RATIONALE.
--
-- ⚠ TREGUB / TRANSPORTATION IS THE ONE THAT COULD HAVE BEEN A GAP RATHER THAN A FINDING, and 1739
-- settled it before blanking: seated December 2024, and none of the 96 items recovered by the corpus
-- repair falls inside that tenure. An absence is only a finding once the record behind it is complete.
--
-- After this the gate reads ORPHAN_CONTEXT 50 against a baseline of 50, with ca back at 35 -- so the
-- 224 is fully worked off and NOT ONE baseline number is changed. That is the point: the regression is
-- gone because the rows were read, not because the threshold moved.
--
-- Rollback: data/stance-retirement/2026-08-14-ca-berkeley-orphan-1757-rollback.json
BEGIN;

CREATE TEMP TABLE bko_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE bko_new (pid uuid, tid uuid, reasoning text) ON COMMIT DROP;
INSERT INTO bko_new VALUES
  ('424eb63b-9976-4059-8049-365c09719cc6','44905f3b-e105-4f6c-afc7-5d223813dbac',$bk$Researched 2026-08-13 — all 52 council items read, and the row fails for two independent reasons. The ladder asks WHO should be deported: chair 2 is "only deport people convicted of serious violent crimes", but the ordinance backed here is CATEGORICAL, carrying no criminal-conviction carve-out anywhere, which contradicts that chair rather than supporting it. And the cited instrument, the $200,000 deportation defence fund, is the same act already carrying the Local Immigration Enforcement row — a city instrument answers whether the city cooperates, not who should be deported. No scorable public record was found for this chair.$bk$),
  ('9f9a35a9-0226-45f0-9fd8-ef46163f7245','e9ebefcd-c496-45e8-b816-a79f8442ba85',$bk$Researched 2026-08-13 — chair 3 is "adding crisis response teams". The cited Proposition 6 resolution is about FORCED PRISON LABOUR, and the only Specialized Care Unit item in this tenure is a City Manager contract to EVALUATE the existing unit (2024-11-19). No scorable public record was found for this chair.$bk$),
  ('bcdb549a-48bf-400f-9d23-c93e2e71007c','e9ebefcd-c496-45e8-b816-a79f8442ba85',$bk$Researched 2026-08-13 — chair 2 is "shift non-violent calls to unarmed mental health co-responders". The sole mental-health item in the record is a CEREMONIAL PROCLAMATION, Res. 69,853-N.S. declaring May 2021 Mental Health Month: on-topic by vocabulary, not by rationale. No scorable public record was found for this chair.$bk$),
  ('9f9a35a9-0226-45f0-9fd8-ef46163f7245','ba59337e-30e2-4aba-a39a-426b3366eb27',$bk$Researched 2026-08-13 — chair 2's "invest equally in roads" is CONTRADICTED by a record that is pedestrian, cycling and transit throughout (the Oxford for All Class IV bikeway, accessible pedestrian signals, the MTC letter). Chair 1 would fit that half, but its second clause, "reduce parking requirements communitywide", has no instrument behind it anywhere in the repaired corpus. Contradicted at 2, incomplete at 1, so neither chair is described. The absence rests on a COMPLETE record: seated December 2024, and none of the 96 items recovered by the corpus repair falls inside that tenure. No scorable public record was found for this chair.$bk$);

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM bko_new;
  IF n <> 4 THEN RAISE EXCEPTION 'pre-check: % rows, expected 4', n; END IF;

  SELECT count(*) INTO n FROM bko_new m
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=m.pid AND c.topic_id=m.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % row(s) no longer exist', n; END IF;

  -- If one acquired an answer since capture, someone decided the record DOES place them and
  -- overwriting the reasoning with a blank would contradict a live published chair.
  SELECT count(*) INTO n FROM bko_new m
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id=m.pid AND a.topic_id=m.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % row(s) acquired an answer since capture', n; END IF;
END $$;

UPDATE inform.politician_context c
   SET reasoning = m.reasoning
  FROM bko_new m
 WHERE c.politician_id = m.pid AND c.topic_id = m.tid;

-- Guard 1: text only. Nothing created, nothing destroyed.
DO $$
DECLARE ctx_after int; ans_after int; s record;
BEGIN
  SELECT * INTO s FROM bko_snap;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 1: context moved % -> %', s.ctx_before, ctx_after; END IF;
  IF ans_after <> s.ans_before THEN
    RAISE EXCEPTION 'guard 1: answers moved % -> %', s.ans_before, ans_after; END IF;
END $$;

-- Guard 2: each rewritten row now reads as a documented blank under both carve-outs and kept its
-- sources. A blank that cites nothing is a worse row than the one it replaced.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c JOIN bko_new m
    ON m.pid=c.politician_id AND m.tid=c.topic_id
   WHERE c.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
      OR c.reasoning !~* 'no scorable'
      OR coalesce(cardinality(c.sources),0) = 0;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 2: % row(s) are not a cited documented blank', bad; END IF;
END $$;

-- Guard 3: the whole check is back to its baseline of 50, and no answer lost its context. Asserted on
-- the TOTAL rather than on these four, because "my four rows are fixed" is not the claim being made.
DO $$
DECLARE total int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO total
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF total <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', total; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) now have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'berkeley orphan blanks: 4 rewritten, ORPHAN_CONTEXT back to baseline 50';
END $$;

COMMIT;
