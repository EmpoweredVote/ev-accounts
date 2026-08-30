-- CA_0039_abortion_chair3_reaudit.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
--
-- NOTE: originally authored as CA_0035; renumbered to CA_0039 after fetch revealed CA_0034/0035
-- (Religious Freedom) and CA_0036/0037 (childcare) had merged to master, with CA_0038 claimed by
-- childcare. No prod data embeds this migration's own number; the data change was applied once, ad hoc.
--
-- WHAT / WHY
-- The `abortion` topic (id af2fdfd6-02c4-49df-b09c-cf8536f4773f) was reworded and published as a
-- CLARIFYING revision (revision 5, id 085feb9c, version 1) on 2026-08-29. The change fixed an old
-- 3-vs-4 collision by REMOVING the "rape, incest, or maternal health" clause from chair 3:
--   OLD chair 3: "allow abortion in the first trimester AND in cases of rape, incest, or maternal
--                 health risks."
--   NEW chair 3: "allow abortion during the first trimester, and after that only to protect the
--                 mother's health."   (elective first-trimester access is the defining feature)
--   NEW chair 4: "ban abortion except in cases of rape, incest, or a serious risk to the mother's
--                 life."              (a ban with exceptions; no elective window)
--
-- The Season-1 answers are still PINNED to revision 1 (dab46e5c, version 1), but ADR 0006 (Option Y)
-- renders the latest published/superseded revision of the pinned VERSION — so the pin (version 1)
-- resolves to revision 5, and voters already see the new chair-3 wording against these answers.
-- Moving a row 3->4 keeps its rev-1 pin; value 4 then renders as new chair 4.
--
-- RE-AUDIT of the 104 Season-1 rows at value 3 (this migration touches only the 4 rows that no
-- longer fit; the other 100 are unchanged). Full classification: scratchpad RE-AUDIT-REPORT.md.
--
-- CITATION BAR (Andrews, per CA_0033, 2026-08-30): a chair must rest on a PRIMARY instrument — the
-- officeholder's own bill/vote/letter/official statement. Wikipedia and OnTheIssues are not evidence.
--
-- KEY FINDING (why so few rows move): most value-3 rows that look like "ban with exceptions" rest
-- ONLY on co-authorship of HB 44 / SB 31 (89R), the bipartisan "Life of the Mother Act." SB 31
-- passed the House 134-4 and HB 44 had 60+ co-authors from both parties: a near-unanimous medical
-- clarification held across the whole spectrum. It proves a person wanted AT LEAST life-of-mother
-- exceptions; it does NOT distinguish chair 3 (elective first trimester) from chair 4 (ban with
-- exceptions). Per the compass rule ("direction is not enough; a blank spoke is correct"), those 34
-- rows are DIRECTION-ONLY and are left on 3, flagged for a primary-sourced re-audit — NOT moved and
-- NOT split by party. Only rows with a chair-placing PRIMARY instrument beyond that clarification are
-- touched here.
--
-- DISPOSITIONS (4 rows)
--   MOVE 3 -> 4 (a primary instrument shows they back the ABORTION BAN, plus HB 44 exceptions):
--     Jeff Leach       jeffleach.com/issues — backed the Heartbeat Bill and HB 1280 (88R ban)
--     Jared Patterson  jaredpatterson.net/about — "key role in the passage of ... the Texas
--                      Heartbeat Act" (SB 8, six-week ban)
--   BLANK (documented, rewritten-as-blank) — chair-3 seating rested only on a secondary source the
--   citation bar rejects, and no primary instrument places a specific chair:
--     Gabe Evans       (Wikipedia only)
--     Michael Lawler   (OnTheIssues / Wikipedia only)
--
-- Expected end state (abortion, all seasons — only Season 1 carries answers today):
--   chair counts 1=522, 2=627, 3=100, 4=495, 5=198 (was 522/627/104/493/198); 2 answer rows removed.

BEGIN;

-- ── 0. Preconditions (structural only, so the migration is idempotent) ───────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='af2fdfd6-02c4-49df-b09c-cf8536f4773f' AND topic_key='abortion') THEN
    RAISE EXCEPTION 'precondition: abortion topic id/key mismatch';
  END IF;
  -- Season-1 answers are pinned to revision 1; the clarifying revision 5 is the current published one.
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions
                 WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
                   AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
                   AND topic_revision_id='dab46e5c-628a-4360-ad1d-3aaba61768f0') THEN
    RAISE EXCEPTION 'precondition: Season 1 abortion pin is not revision 1 (dab46e5c)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id='085feb9c-f157-4dae-bfd0-7b2736c5d87c'
                   AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
                   AND revision=5 AND version=1 AND status='published' AND is_current) THEN
    RAISE EXCEPTION 'precondition: clarifying revision 5 (085feb9c) is not the current published revision';
  END IF;
END $$;

-- ── 1. MOVE: Jeff Leach 3 -> 4 (backs the abortion ban + HB 44 exceptions = ban with exceptions) ──
UPDATE inform.politician_answers
   SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='c4ea9acb-af11-46ea-9e5c-4f9c3fed7207'
   AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND value=3;

UPDATE inform.politician_context
   SET reasoning = $r$Rep. Jeff Leach's own campaign site states he backed the Texas Heartbeat Bill and HB 1280 (88R), the state's abortion ban; he also co-authored HB 44 (89R), the "Life of the Mother Act" that adds narrow medical-emergency exceptions to that ban. Backing the ban while supporting only medical exceptions is a ban-with-exceptions position — closest to chair 4 (ban except rape, incest, or a serious risk to the mother's life) — and not chair 3, which requires allowing elective abortion during the first trimester.$r$,
       sources = ARRAY[
         'https://www.jeffleach.com/issues',
         'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB44'
       ]::text[],
       editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='c4ea9acb-af11-46ea-9e5c-4f9c3fed7207'
   AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

-- ── 1b. MOVE: Jared Patterson 3 -> 4 (backs SB 8 six-week ban + HB 44 exceptions) ─────────────────
UPDATE inform.politician_answers
   SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='4f6da77d-f516-4873-b705-3adeb23c1ffb'
   AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND value=3;

UPDATE inform.politician_context
   SET reasoning = $r$Rep. Jared Patterson states on his own campaign site that in 2021 he "played a key role in the passage of ... the Texas Heartbeat Act" — Senate Bill 8, the six-week abortion ban — and lists "Sanctity of Life & Protecting Women" as a core issue. He also co-authored HB 44 (89R), the "Life of the Mother Act" that adds narrow medical-emergency exceptions to Texas's near-total ban. Backing the six-week ban while supporting only medical exceptions is a ban-with-exceptions position — closest to chair 4 (ban except rape, incest, or a serious risk to the mother's life) — and not chair 3, which requires allowing elective abortion during the first trimester.$r$,
       sources = ARRAY[
         'https://jaredpatterson.net/about/',
         'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB44'
       ]::text[],
       editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='4f6da77d-f516-4873-b705-3adeb23c1ffb'
   AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

-- ── 2. BLANK: remove the seating, rewrite context as a documented blank ───────────────────────────
CREATE TEMP TABLE ab_blank(pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO ab_blank(pid, tid) VALUES
  ('0a636eab-2b48-42d6-a4c6-e5759fb4c306','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), -- Gabe Evans
  ('cd4e9f29-d1b0-40c1-9e4a-5024cdc7b028','af2fdfd6-02c4-49df-b09c-cf8536f4773f'); -- Michael Lawler

DELETE FROM inform.politician_answers a
 USING ab_blank b
 WHERE a.politician_id=b.pid AND a.topic_id=b.tid
   AND a.season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

-- Each blank names what was checked and why it fails to place a chair. The leading
-- "Researched 2026-08-30" is TRUE (each record was read this pass) and also satisfies the
-- ORPHAN_CONTEXT carve-out, so a kept sources array does not read as a live orphan.
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — Rep. Gabe Evans's prior chair-3 seating rested only on a Wikipedia summary that he supports banning abortion except for rape, incest, or maternal-health cases while opposing a nationwide ban. That is a secondary source, not a primary instrument (the officeholder's own bill, vote, letter, or official statement), which the CA_0033 citation bar (2026-08-30) does not accept; as a 2024 freshman he has no federal abortion vote on record. No primary instrument places a specific chair on this spectrum; left blank pending a primary-sourced re-audit.$r$
 WHERE politician_id='0a636eab-2b48-42d6-a4c6-e5759fb4c306' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Researched 2026-08-30 — Rep. Michael Lawler's prior chair-3 seating rested only on OnTheIssues and Wikipedia summaries that he opposes abortion except for rape, incest, or maternal health and opposes a federal ban. Those are secondary aggregators, not a primary instrument (the officeholder's own bill, vote, letter, or official statement), which the CA_0033 citation bar (2026-08-30) does not accept. No primary instrument on the record places a specific chair on this spectrum; left blank pending a primary-sourced re-audit.$r$
 WHERE politician_id='cd4e9f29-d1b0-40c1-9e4a-5024cdc7b028' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

-- @context-decision: rewritten-as-blank — the abortion topic applies to Evans and Lawler and each
-- record WAS read on 2026-08-30; the only sources were secondary (Wikipedia/OnTheIssues), which the
-- CA_0033 bar rejects, so each context is a documented blank naming what was checked. No answer row
-- remains for these pairs.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate, applied to the pairs this migration
-- blanked. Regexes kept character-identical to the gate.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM ab_blank t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid
   WHERE coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- ── 3. Post-verify gate (row-specific + distribution, idempotent) ─────────────────────────────────
DO $$
DECLARE
  tid uuid := 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  sid uuid := '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  c1 int; c2 int; c3 int; c4 int; c5 int; still int; nblank int;
BEGIN
  -- Leach and Patterson moved to 4
  IF NOT EXISTS (SELECT 1 FROM inform.politician_answers
                 WHERE politician_id='c4ea9acb-af11-46ea-9e5c-4f9c3fed7207' AND topic_id=tid AND value=4) THEN
    RAISE EXCEPTION 'verify: Jeff Leach not seated at chair 4';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.politician_answers
                 WHERE politician_id='4f6da77d-f516-4873-b705-3adeb23c1ffb' AND topic_id=tid AND value=4) THEN
    RAISE EXCEPTION 'verify: Jared Patterson not seated at chair 4';
  END IF;
  -- Evans and Lawler have no answer row (blank spoke)
  SELECT count(*) INTO still FROM ab_blank b
    JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF still <> 0 THEN RAISE EXCEPTION 'verify: % blanked pair(s) still have an answer row', still; END IF;
  -- Their context is a documented blank (leading "Researched")
  SELECT count(*) INTO nblank FROM ab_blank b
    JOIN inform.politician_context pc ON pc.politician_id=b.pid AND pc.topic_id=b.tid
   WHERE pc.reasoning ~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}';
  IF nblank <> 2 THEN RAISE EXCEPTION 'verify: expected 2 documented-blank contexts, found %', nblank; END IF;
  -- Chair distribution (topic-wide; only Season 1 carries answers today)
  SELECT count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2), count(*) FILTER (WHERE value=3),
         count(*) FILTER (WHERE value=4), count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid;
  IF (c1,c2,c3,c4,c5) <> (522,627,100,495,198) THEN
    RAISE EXCEPTION 'verify: chair counts are %/%/%/%/% (expected 522/627/100/495/198)', c1,c2,c3,c4,c5;
  END IF;
END $$;

COMMIT;
