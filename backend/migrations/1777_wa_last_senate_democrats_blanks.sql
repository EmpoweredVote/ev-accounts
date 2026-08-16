-- 1777_wa_last_senate_democrats_blanks.sql
-- 2 DOCUMENTED BLANKS, closing the Senate Democrats. Deborah Krishnadasan on `taxes` and Drew
-- Hansen on `rent-regulation`. Neither gets an answer row, and that is the finding.
--
-- 🔑 KRISHNADASAN IS THE ORCUTT CASE ON THE OTHER SIDE OF THE AISLE, AND THAT SETTLES A QUESTION THE
-- TROUBLE-SPOT LOG LEFT OPEN. Migration 1764 blanked Ed Orcutt (R), House Finance ranking member,
-- who wanted to cut the state sales tax from 6.5% to 6.0% — because taxes chair 4 requires cutting
-- taxes AND scaling back public services to match, and no instrument of his stated the second half.
-- The log recorded a worry that this made the cut side of the ladder unreachable in a way that would
-- bias the corpus BY PARTY. It does not: Krishnadasan (D) proposed the SAME 6.5-to-6.0 cut, for the
-- opposite reason — Washington's tax code "remains the second most regressive in the nation" — and
-- she is unplaceable for exactly the same missing clause. The ladder cannot describe a tax cut
-- offered as fairness policy any more than one offered as small-government policy. The defect is in
-- the chair, not in one party's record.
--
-- Hansen is the eviction-procedure case the rent-regulation rule in migration 1763 already predicted:
-- SB 6139 is about what a partial rent payment does to a pending unlawful detainer, and chairs 2-5
-- turn on the scope of rent control. Recorded so nobody reads his 18 primary sponsorships again.
-- ⚠ Also recorded on his row: SB 5066 (attorney general authority to investigate and sue local law
-- enforcement over patterns of misconduct) matches `judicial-police-accountability` chair 1 almost
-- word for word — "investigate independently; the office works for the public". That ladder is scoped
-- `city_attorney_da` and asks what the SUBJECT'S OWN OFFICE does. A legislator does not hold that
-- office, and seating him there would repeat the scope error migration 1755 had to unwind.
BEGIN;

CREATE TEMP TABLE lb_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Deborah Krishnadasan already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Deborah Krishnadasan already has a taxes context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND topic_key='taxes' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: taxes topic id does not resolve to a live topic'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='65cae041-2bf3-4d9f-a010-02d2f07b949c' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Drew Hansen already has a rent-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='65cae041-2bf3-4d9f-a010-02d2f07b949c' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Drew Hansen already has a rent-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2' AND topic_key='rent-regulation' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: rent-regulation topic id does not resolve to a live topic'; END IF;
END $$;

-- context rows ONLY: a documented blank is a context row with sources and NO answer
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Unable to place on this ladder. Prime sponsor of SB 5795, which would cut the state sales and use tax rate from 6.5 to 6.0 percent on the finding that Washington's tax system "remains the second most regressive in the nation" and that lowering the sales tax reduces "one of the key drivers of regressivity"; and of SB 6162 (Chapter law, 2026), which expands the senior citizen property tax relief program and consolidates the state property tax. Her remaining tax record is exemptions and credits — farm machinery, food banks, precious metals, and two working families' tax credit expansions. Chairs 1 and 2 require raising taxes on wealthy people and large companies, and she sponsors no such instrument. Chair 4 requires cutting taxes for everyone AND scaling back public services to match; the cut is there and the service reduction is not — the act's stated purpose is fairness, not smaller government. Chair 5 is refuted for the same reason. Chair 3 requires keeping the system mostly as-is with adjustments to close unfair loopholes, and a half-point cut in the state's largest revenue source is not that. No chair describes the position.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5795.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6162.pdf']),
('65cae041-2bf3-4d9f-a010-02d2f07b949c','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Unable to place on this ladder. Prime sponsor of SB 6139, which provides that a partial payment of past-due rent does not reinstate the lease, is not grounds for dismissing a pending unlawful detainer proceeding, and does not extend the five-court-day deadline, and which requires landlords to keep accepting agreed payment methods. This is eviction procedure: under the rule set for this ladder, eviction and just-cause instruments cannot discriminate among chairs 2 through 5, which turn on the SCOPE of rent control, and chair 1 requires rent control on all rental units plus just-cause requirements, which this act does not create. No chair describes the position. His wider record is higher education, consumer protection and attorney general authority; SB 5066, which would let the attorney general investigate and sue local law enforcement agencies over patterns of misconduct, matches judicial-police-accountability chair 1 in substance, but that ladder is scoped to city attorneys and district attorneys and asks what the subject's own office does, so it cannot be used for a legislator.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6139.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5066.pdf']);

DO $$
DECLARE ans_after int; ctx_after int; s record; nb int;
BEGIN
  SELECT * INTO s FROM lb_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before THEN
    RAISE EXCEPTION 'guard 1: answers changed % -> %, this migration must write NONE', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 2 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +2', s.ctx_before, ctx_after; END IF;

  SELECT count(*) INTO nb
    FROM inform.politician_context c
   WHERE ((c.politician_id='7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe' AND c.topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb') OR (c.politician_id='65cae041-2bf3-4d9f-a010-02d2f07b949c' AND c.topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2'))
     AND c.reasoning ~ '^Unable to place on this ladder'
     AND coalesce(cardinality(c.sources),0) >= 2
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF nb <> 2 THEN RAISE EXCEPTION 'guard 2: % documented blank(s), expected 2', nb; END IF;
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
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50 — these blanks must match the carve-out', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE '2 documented blanks written; no answers; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
