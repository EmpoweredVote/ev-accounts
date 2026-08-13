-- 1731_md_chairs_evidenced_or_blanked.sql
-- MARYLAND, first slice: seat a chair only on evidence describing THAT chair — or blank the spoke.
--
-- 🔑 THE STANDARD (CLAUDE.md): the five chairs are five distinct stances. To sit in one you need
-- evidence describing that chair, with sources. Migs 1726/1727/1729/1730 made 169 chairs
-- non-contradictory, but `scripts/audit-chair-evidence.mjs` measured that **121 of them (72%) rest
-- on directional-only reasoning** — they establish which half of the ladder, not which chair.
-- Maryland owes 82 of those 121. This migration closes the first 11 of the 82.
--
-- 🔴🔴 THE RANKER WAS NOT ALLOWED TO DECIDE A BLANK. `md-chair-candidates.mjs` scores each of the
-- member's own sponsored bills against the seated chair's text versus its four rivals, and it put
-- 54 of the 82 rows in a "no chair-discriminating candidate" bucket. Blanking on that would have
-- manufactured absences: reading Cheryl Kagan's FULL list of 171 candidates turned up "Voting by
-- Absentee Ballot - Prepaid Postage for Return of Ballots" and "Absentee Ballot Deposit Boxes",
-- neither of which the top-5 ranking surfaced. **Every blank below was decided by reading that
-- row's COMPLETE candidate list, not the shortlist.** The other 71 rows stay owed rather than
-- being blanked on a score.
--
-- 🔑 SPONSORSHIP IS mgaleg's OWN ATTRIBUTION. Candidates come from the member's per-session
-- sponsored-legislation page, not from a surname match against a bill's sponsor list — the
-- identity trap recorded in the Maryland notes.
--
-- ── 8 RE-SOURCED, each to a bill whose TITLE describes the seated chair ───────────────────────
-- Voting Rights chair 2 is "expand early voting periods and make mail-in voting available to all
-- voters without requiring an excuse", so a bill about ballot *security* or *registration age*
-- does not qualify no matter how on-topic it is:
--   · Kramer        SB0029 (2021) "Elections by Mail, Polling Places, and Early Voting Centers"
--   · Kagan         SB0343 (2019) "Voting by Absentee Ballot - Prepaid Postage for Return of Ballots"
--   · Waldstreicher SB0461 (2019) "Early Voting Centers - Establishment and Hours"
--   · Benson        SB0373 (2013) "Early Voting Access Act of 2013"
--   · Smith         SB0730 (2018) "Municipal Elections - No-Excuse Absentee Voting" — chair 2's
--                    "without requiring an excuse", verbatim
-- Healthcare Access chair 2 is coverage "through a mix of public programs and regulated private
-- insurance", which is what an insurance-mandate bill evidences:
--   · Kramer        SB0410 (2019) "Health Insurance - Coverage for Insulin - Prohibition on
--                    Deductible, Copayment, and Coinsurance"
--   · Waldstreicher SB0868 (2019) "Health Insurance - Consumer Protections and Maryland Health
--                    Insurance Coverage Protection"
-- Public Safety chair 3 is "keep current funding while adding crisis response teams for mental
-- health and addiction calls":
--   · Smith         SB0815 (2019) "Public Safety - Crisis Intervention Team Technical Assistance
--                    Center" — "crisis intervention team" is the chair's own clause
--
-- ── 3 BLANKED — the answer row is deleted, the context row stays ──────────────────────────────
-- A blank spoke is the honest state when no evidence describes the chair. Each was read to the end
-- of its candidate list:
--   · Alonzo T. Washington / Voting Rights — all 8 candidates read. The only election bill is
--     SB0515 (2024) "Voter Registration Age - Alteration", which is registration, not early voting
--     or no-excuse mail.
--   · Arthur Ellis / Voting Rights — all 32 read. Precinct procedures, absentee envelope party
--     affiliation, correctional-facility registration, elderly/disabled polling procedures. None
--     expands early voting or no-excuse mail.
--   · C. Anthony Muse / Voting Rights — all 22 read. SB0018 (2025) "Early Voting - Number of Days"
--     does not say whether the number goes UP or DOWN, and a workgroup on mail-in ballot
--     accessibility studies rather than establishes. ⚠ Recorded as blank rather than guessed;
--     re-reading SB0018's page could recover this row.
--
-- ⚠ 71 Maryland rows REMAIN OWED. This is a first slice, not the state.
-- 🔑 Chairs are NOT changed here. Every re-sourced row keeps the chair it already held; what
-- changes is that the chair is now evidenced.
--
-- Rollback: data/stance-retirement/2026-08-12-md-chairs-1731-rollback.json
BEGIN;

CREATE TEMP TABLE ce_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE ce_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO ce_intent (pid, tid, reasoning, sources) VALUES
-- Benjamin F. Kramer / Voting Rights (chair 2)
('7a2d1548-3268-4767-97a8-bb8b142d5a33','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 'Kramer sponsored SB0029 (2021), "Election Law - Voting - Elections by Mail, Polling Places, and Early Voting Centers".',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0029?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02']::text[]),
-- Cheryl C. Kagan / Voting Rights (chair 2)
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 'Kagan sponsored SB0343 (2019), "Election Law - Voting by Absentee Ballot - Prepaid Postage for Return of Ballots".',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0343?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01']::text[]),
-- Jeff Waldstreicher / Voting Rights (chair 2)
('da75c207-bb23-477e-b3c0-7c462394b570','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 'Waldstreicher sponsored SB0461 (2019), "Election Law - Early Voting Centers - Establishment and Hours".',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0461?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1']::text[]),
-- Joanne C. Benson / Voting Rights (chair 2)
('4a7dc8a6-2138-4472-8197-8b878034f029','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 'Benson sponsored SB0373 (2013), the "Early Voting Access Act of 2013".',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0373?ys=2013RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson']::text[]),
-- William C. Smith, Jr. / Voting Rights (chair 2)
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 'Smith sponsored SB0730 (2018), "Local Government - Municipal Elections - No-Excuse Absentee Voting".',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0730?ys=2018RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02']::text[]),
-- Benjamin F. Kramer / Healthcare Access (chair 2)
('7a2d1548-3268-4767-97a8-bb8b142d5a33','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 'Kramer sponsored SB0410 (2019), "Health Insurance - Coverage for Insulin - Prohibition on Deductible, Copayment, and Coinsurance".',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0410?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02']::text[]),
-- Jeff Waldstreicher / Healthcare Access (chair 2)
('da75c207-bb23-477e-b3c0-7c462394b570','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 'Waldstreicher sponsored SB0868 (2019), "Health Insurance - Consumer Protections and Maryland Health Insurance Coverage Protection".',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0868?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1']::text[]),
-- William C. Smith, Jr. / Public Safety Approach (chair 3)
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Smith sponsored SB0815 (2019), "Public Safety - Crisis Intervention Team Technical Assistance Center".',
 ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0815?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02']::text[]);

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM ce_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

-- The 3 blanks: delete the ANSWER, keep the CONTEXT. 541 context rows already sit without an
-- answer, so this is the corpus's established shape for an unevidenced spoke.
CREATE TEMP TABLE ce_blank (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO ce_blank VALUES
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), -- Alonzo T. Washington / Voting Rights
('4754dede-4a3b-4280-a8b1-7497530107f7','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), -- Arthur Ellis / Voting Rights
('47823046-7dea-4a4f-a11b-0c5890539891','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'); -- C. Anthony Muse / Voting Rights

DELETE FROM inform.politician_answers a USING ce_blank b
WHERE a.politician_id = b.pid AND a.topic_id = b.tid;

-- Guard 1: the 8 re-sourced rows hold the intended text, cite an mgaleg bill page, and now NAME an
-- instrument — the same test scripts/audit-chair-evidence.mjs --check applies.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM ce_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning IS DISTINCT FROM i.reasoning
     OR c.sources IS DISTINCT FROM i.sources
     OR c.reasoning !~ '(\mSB\d|\mHB\d)'
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % re-sourced row(s) wrong', bad; END IF;
END $$;

-- Guard 2: the 3 blanked spokes have NO answer and DO still have their context.
DO $$
DECLARE still_answered int; lost_context int;
BEGIN
  SELECT count(*) INTO still_answered FROM ce_blank b
  JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF still_answered > 0 THEN RAISE EXCEPTION 'guard 2 failed: % spoke(s) still answered', still_answered; END IF;
  SELECT count(*) INTO lost_context FROM ce_blank b
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=b.pid AND c.topic_id=b.tid);
  IF lost_context > 0 THEN RAISE EXCEPTION 'guard 2 failed: % blanked row(s) lost their context', lost_context; END IF;
END $$;

-- Guard 3: exactly 3 answers removed, no context created or destroyed, no orphans.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM ce_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 3 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before - 3 THEN RAISE EXCEPTION 'guard 3 failed: answers moved % -> %, expected -3', snap.ans_before, ans_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;
  RAISE NOTICE 'MD chairs slice ok: 8 re-sourced, 3 blanked';
END $$;

COMMIT;
