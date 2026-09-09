BEGIN;

-- =============================================================================
-- CA_0108: Growth and Development Pace (growth-and-development) — re-audit the
--          chair-4 and chair-5 seatings against the CA_0077 re-fork wording,
--          before Season 2 opens. Three moves 5->4, three documented blanks.
-- =============================================================================
-- Created 2026-09-01 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4 ('growth-and-development',
--   "Growth and Development Pace"). CA_0077 re-forked chairs 4 and 5 off MAGNITUDE
--   onto CONDITIONALITY (approved v2 = rev 65e8ffd5-…, pinned to the draft Season 2):
--     chair 4 = "Actively push for faster growth — cut red tape and recruit new
--               development, while keeping basic guardrails." (government ACTS to
--               promote growth, keeps guardrails)
--     chair 5 = "Step back and let the market set the pace — remove development
--               constraints beyond basic health and safety." (government STEPS BACK,
--               market-led, hands-off)
--   Chairs 1-3 were wording-only (clarifying) and their seats carry — NOT re-audited
--   here. Only chairs 4 and 5 were evidenced against wording that no longer exists.
--
-- WHY EDIT THE LIVE SEASON-1 ROWS (model, per CA_0033 / CA_0097 precedent): every
--   answer in the system is Season-1 / v1 today; no Season-2 answer rows exist yet.
--   The edits below apply to the live Season-1 seatings, which is correct because
--   each correction also holds under v1: the three moves fit their new chair better
--   than their old one, and the three blanks were unevidenced under v1 too (a chair
--   is a distinct evidenced position, not a rating of direction). Season 1 (open)
--   keeps serving v1 wording; these edits improve it. Season 2 (draft) already pins
--   v2 via CA_0077 — this migration does NOT re-pin (it asserts the pin as a
--   precondition).
--
-- SCOPE PRICED IN THE REVIEW (CA_0077 memo): chair 5 = 6 seated rows RE-READ; chair 4
--   = 96 seated rows SCANNED. Seat dist at CA_0077 apply: 18/113/196/96/6 (429).
--
-- DISPOSITIONS
--   CHAIR 5 (6 rows re-read against "step back, let the market set the pace"):
--     CONFIRM @5 (genuinely hands-off / remove-constraints; not touched):
--       · James Taylor    — sole prime sponsor of AZ HB2492 (2026) voiding every urban
--                           growth-boundary law entirely. The archetype of chair 5.
--       · Steve Hilton    — Golden Together housing paper: eliminate the CEQA private
--                           right of action, cap impact fees, expand the urban footprint,
--                           "beyond the Infill Ideology", fast-track — remove constraints,
--                           let market demand drive the pace.
--       · James B. Gibson — dismisses sprawl, advocates opening federal land and
--                           "removing barriers to growth" so growth is not held back.
--     MOVE 5 -> 4 (actively promotes/approves specific development; NOT hands-off — a
--     "pro-development" seat that maps to chair 4 under the re-fork):
--       · Dan H. Stewart  — voted Yes (4-0) to approve a specific 3,000-home development
--                           agreement and defended it. Active approval, negotiated
--                           agreement = a guardrail. Not "market sets the pace".
--       · David DeGroot   — used blight designation, eminent domain and a $764M Foxconn
--                           TIF, and voted Aye (7-0) to sell TID No. 5 land to Microsoft.
--                           The most active form of government promotion of growth — the
--                           opposite of stepping back.
--       · Jim Seebock     — voted Yes on the unanimous ordinance annexing Eldorado Valley
--                           land and champions city-led Water Street redevelopment. Active
--                           annexation/recruitment, not deregulatory hands-off.
--   CHAIR 4 (96 rows scanned for hands-off "remove all rules / market decides" holders
--     who should migrate UP to 5). No row met the chair-5 bar with evidence. Three rows
--     described a REDUCE-GOVERNMENT-ROLE stance rather than active recruitment, so they
--     no longer fit new chair 4 either; none carries instrument-grade evidence placing a
--     specific chair, so each is BLANKED (a guessed chair is a blank spoke, not a moved
--     one — CLAUDE.md evidence standard):
--       · Candice B. Pierucci — general small-government rhetoric ("the solution is
--                           smaller government", private-sector leadership, reduce zoning
--                           restrictions) from a GOP cost-of-living plan; re-research found
--                           no bill/vote/ordinance placing a chair. Deregulatory direction
--                           only.
--       · Katy Hall       — seat rested on party-caucus alignment ("97% Republican caucus
--                           loyalty", "no affordable housing bills") — a direction defaulted
--                           from party, no stated position and no named instrument.
--       · Sheldon Stewart — jurisdictional stance ("get the county out of the zoning and
--                           land use business", let local communities decide; opposed the
--                           county-approved Olympia Hills rezone). A question of WHO decides,
--                           off this pace axis; no instrument places him at 4 or 5.
--     The other 93 chair-4 rows are active recruiters / streamliners deploying government
--     levers to promote growth — correctly chair 4 under the re-fork; not touched. Several
--     already reasoned explicitly against old chair 5 (Megan Norris, Teri Murphy, Michael
--     Summers), confirming the 4/5 line was drawn deliberately.
--
--   NEW DISTRIBUTION: 18/113/196/96/3 (426 seated + 3 documented blanks). Chair 4 stays
--   at 96 (−3 blanked, +3 moved in); chair 5 falls 6 -> 3.
--
-- Idempotent: moves are guarded on the old value; blanks DELETE then rewrite context
--   (re-run is a no-op). Post-verify gate on the end state.
-- Model: CA_0097 (re-audit + moves + documented blanks + ORPHAN guard). Chair-evidence
--   gate: the three MOVES name a recorded vote (voted Yes / voted Aye + ordinance); the
--   confirms and blanks are not in the gate set (confirms unchanged; blanks seat no chair).
--   Namespaced (CA_) answer-deletes bypass the check:answer-delete-guards CI regex, so the
--   guard below is pasted by hand and check:stance-sources is run by hand after apply.
-- =============================================================================

-- ── 0. Preconditions ─────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'
                   AND topic_key='growth-and-development') THEN
    RAISE EXCEPTION 'CA_0108 precondition: topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id='65e8ffd5-5aac-4d40-8862-a321949eafa4'
                   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'
                   AND version=2 AND status='approved') THEN
    RAISE EXCEPTION 'CA_0108 precondition: re-fork v2 (65e8ffd5) is not approved';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
                   AND number=2 AND status='draft') THEN
    RAISE EXCEPTION 'CA_0108 precondition: Season 2 is not a draft';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions
                 WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
                   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'
                   AND topic_revision_id='65e8ffd5-5aac-4d40-8862-a321949eafa4') THEN
    RAISE EXCEPTION 'CA_0108 precondition: Season 2 does not pin the re-fork v2 (run CA_0077 first)';
  END IF;
  -- Guard the priced scope: the re-audit assumes the 6/96 chair-5/chair-4 seatings.
  IF (SELECT count(*) FROM inform.politician_answers
       WHERE topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4' AND value=5) <> 6 THEN
    RAISE EXCEPTION 'CA_0108 precondition: chair-5 seat count is not 6 (scope drift)';
  END IF;
  IF (SELECT count(*) FROM inform.politician_answers
       WHERE topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4' AND value=4) <> 96 THEN
    RAISE EXCEPTION 'CA_0108 precondition: chair-4 seat count is not 96 (scope drift)';
  END IF;
END $$;

-- ── 1. Moves 5 -> 4 (value change; reasoning reworded to fit new chair 4 and to name
--       the recorded vote it rests on) ───────────────────────────────────────────

-- Dan H. Stewart 5 -> 4
UPDATE inform.politician_answers
   SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='50682ef1-360a-4597-9e1a-eaf43c50673d'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4' AND value=5;
UPDATE inform.politician_context
   SET reasoning = $r$On Nov. 21, 2023 Stewart voted Yes in a 4-0 Henderson City Council vote approving the development agreement, zoning change and tentative map for the Three Kids Mine 3,000-home community, and publicly defended his pro-development vote against conflict-of-interest questions. Actively approving and championing a specific large master-planned development — where the negotiated development agreement is itself a guardrail — is the active-promotion posture of chair 4 (actively push for faster growth and recruit new development while keeping basic guardrails), not chair 5's hands-off, remove-constraints, let-the-market-set-the-pace stance.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='50682ef1-360a-4597-9e1a-eaf43c50673d'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

-- David DeGroot 5 -> 4
UPDATE inform.politician_answers
   SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='4bbafa07-020e-4f89-8a72-6f427d47c069'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4' AND value=5;
UPDATE inform.politician_context
   SET reasoning = $r$As Mount Pleasant Village President, DeGroot led the Foxconn land assembly using blight designation and eminent domain, dismissed objections ("This happens every day across the state of Wisconsin"), championed the $764 million Foxconn TIF, and voted Aye in the 7-0 board approval of the $50.085 million sale of Tax Incremental District No. 5 land to Microsoft. Using eminent domain and public tax-increment financing to assemble land and recruit named employers is the most active form of government promotion of growth — the opposite of chair 5's step-back, market-sets-the-pace posture — so this fits chair 4 (actively push growth and recruit development while keeping basic guardrails).$r$,
       sources = ARRAY[
         'https://shepherdexpress.com/culture/happening-now/mount-pleasant-continues-to-claim-eminent-domain/',
         'https://www.wpr.org/economy/mount-pleasant-panel-recommends-foxconn-land-plan-eminent-domain-powers',
         'https://spectrumnews1.com/wi/milwaukee/news/2023/03/31/mount-pleasant-village-board-approves-agreements-with-microsoft'
       ]::text[],
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='4bbafa07-020e-4f89-8a72-6f427d47c069'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

-- Jim Seebock 5 -> 4
UPDATE inform.politician_answers
   SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='99d43f01-4b07-471f-bacf-e89d2a1c36b2'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4' AND value=5;
UPDATE inform.politician_context
   SET reasoning = $r$Seebock voted Yes on the unanimous ordinance annexing 290+ acres of Eldorado Valley land (Henderson City Council, May 2023 — industrial/commercial zoning, Station Casinos resort approval), saying "It's a significant investment in Henderson... I am very much looking forward to its continued development"; his platform centers continuing Water Street / Ward 1 redevelopment. Actively voting to annex land and recruit development, and championing city-led redevelopment, is the active-promotion posture of chair 4, not chair 5's hands-off, remove-constraints stance.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='99d43f01-4b07-471f-bacf-e89d2a1c36b2'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

-- ── 2. Blanks: remove the seating, rewrite context as a documented blank ──────
CREATE TEMP TABLE gd_blank(pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO gd_blank(pid, tid) VALUES
  ('99198363-2ac9-4b56-9d80-7abfe7b2a01a','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), -- Candice B. Pierucci
  ('e1e4e88b-bfd0-4c16-8e95-72c51b59c1f4','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), -- Katy Hall
  ('bc7cdf2d-2ee7-404f-b6be-286bf4252dc5','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'); -- Sheldon Stewart

DELETE FROM inform.politician_answers a
 USING gd_blank b
 WHERE a.politician_id=b.pid AND a.topic_id=b.tid;

-- Candice B. Pierucci
UPDATE inform.politician_context
   SET reasoning = $r$Researched 2026-09-01 — Representative Pierucci's seat rested on general small-government rhetoric ("the solution is smaller government," private-sector leadership, reducing zoning restrictions) drawn from a GOP cost-of-living plan, not on a specific instrument. A re-read for the CA_0077 re-fork found no bill, vote or ordinance placing her at either chair 4 (actively push growth, keep guardrails) or chair 5 (step back, let the market set the pace); the record shows a deregulatory direction only, which under-determines the chair. Left blank.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='99198363-2ac9-4b56-9d80-7abfe7b2a01a'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

-- Katy Hall
UPDATE inform.politician_context
   SET reasoning = $r$Researched 2026-09-01 — Representative Hall's seat rested on party-caucus voting alignment ("97% Republican caucus loyalty," "no affordable housing investment bills sponsored") and an inference of "reduced government intervention in land use" — a direction defaulted from party, not a stated position and not a named instrument. A re-read for the CA_0077 re-fork found no bill, vote or ordinance placing her at chair 4 or chair 5. Left blank.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='e1e4e88b-bfd0-4c16-8e95-72c51b59c1f4'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

-- Sheldon Stewart
UPDATE inform.politician_context
   SET reasoning = $r$Researched 2026-09-01 — Stewart's position is jurisdictional: he campaigns to "get the county out of the zoning and land use business" and let local communities decide (citing his opposition to the county-approved Olympia Hills rezone). That is a question of WHO decides, not of how permissive the county is toward the pace of growth, so it does not place him on this axis — he supports southwest-county growth but opposed a major development on local-control grounds. No bill, vote or ordinance places him at chair 4 or chair 5. Left blank.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='bc7cdf2d-2ee7-404f-b6be-286bf4252dc5'
   AND topic_id='fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

-- @context-decision: rewritten-as-blank — the topic (pace of growth/development) applies
-- to each person (a Utah state legislator on land-use policy; a county council member on
-- zoning) and each record WAS read this pass; none carried a bill/vote/ordinance placing a
-- specific chair on the re-forked pace spine, so each context is a documented blank naming
-- what was checked. No answer row remains.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate, applied to the blanked pairs.
-- Regexes kept character-identical to the gate.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM gd_blank t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid
   WHERE coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'CA_0108 context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- ── 3. Post-verify ───────────────────────────────────────────────────────────
DO $$
DECLARE
  tid uuid := 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
  c1 int; c2 int; c3 int; c4 int; c5 int; blanks int; pinned uuid;
BEGIN
  -- Moves landed at chair 4
  IF (SELECT count(*) FROM inform.politician_answers
       WHERE topic_id=tid AND value=4
         AND politician_id IN ('50682ef1-360a-4597-9e1a-eaf43c50673d',
                               '4bbafa07-020e-4f89-8a72-6f427d47c069',
                               '99d43f01-4b07-471f-bacf-e89d2a1c36b2')) <> 3 THEN
    RAISE EXCEPTION 'CA_0108 verify: the three 5->4 moves are not all at chair 4';
  END IF;
  -- Blanks have no answer row
  SELECT count(*) INTO blanks FROM gd_blank b
    JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF blanks <> 0 THEN RAISE EXCEPTION 'CA_0108 verify: % blanked pair(s) still seated', blanks; END IF;
  -- Distribution 18/113/196/96/3
  SELECT count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2), count(*) FILTER (WHERE value=3),
         count(*) FILTER (WHERE value=4), count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid AND value IS DISTINCT FROM 0;
  IF (c1,c2,c3,c4,c5) <> (18,113,196,96,3) THEN
    RAISE EXCEPTION 'CA_0108 verify: chair counts are %/%/%/%/% (expected 18/113/196/96/3)', c1,c2,c3,c4,c5;
  END IF;
  -- Season 2 still pins the re-fork v2 (unchanged by this migration)
  SELECT topic_revision_id INTO pinned FROM inform.season_questions
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id=tid;
  IF pinned <> '65e8ffd5-5aac-4d40-8862-a321949eafa4' THEN
    RAISE EXCEPTION 'CA_0108 verify: Season 2 pin is % (expected re-fork v2)', pinned;
  END IF;

  RAISE NOTICE 'CA_0108 post-verify OK: 3 moves 5->4 (Stewart/DeGroot/Seebock), 3 documented blanks (Pierucci/Hall/Stewart), 3 confirms @5 untouched; distribution 18/113/196/96/3; Season 2 still pins the re-fork v2.';
END $$;

COMMIT;
