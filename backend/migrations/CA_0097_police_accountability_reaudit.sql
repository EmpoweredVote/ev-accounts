BEGIN;

-- =============================================================================
-- CA_0097: Police Accountability (judicial-police-accountability) — re-audit the
--          16 seated rows against the CA_0080 re-axis v2 wording, before Season 2
--          opens. One move, four documented blanks, five reasoning trims.
-- =============================================================================
-- Created 2026-09-01 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC 7bad33eb-… ('judicial-police-accountability', "Police Accountability").
--   CA_0080 re-axed all five chairs onto one instrument-neutral
--   "protect <-> hold-accountable" orientation (approved v2 = rev
--   eb6e1ecd-…, pinned to the draft Season 2). This migration re-audits the
--   16 Season-1 seatings against that new wording so the corrected seatings are
--   what Season 2 carries forward.
--
-- WHY EDIT THE LIVE SEASON-1 ROWS (model, per CA_0033 precedent): every answer in
--   the system is Season-1 / v1 today; no Season-2 answer rows exist yet. The row
--   edits below apply to the live Season-1 seatings, which is correct because each
--   correction also holds under v1: the two moves fit their new v1 chair better
--   than their old one, and the three blanks were unevidenced under v1 too. Season 1
--   (open) keeps serving v1 wording; these edits improve it. Season 2 (draft) already
--   pins v2 via CA_0080 — this migration does NOT re-pin (it asserts the pin as a
--   precondition).
--
-- DISPOSITIONS (16 rows; new distribution 4/2/4/2/0, 12 seated + 4 blank):
--   MOVE (value change; reasoning already fits the new chair):
--     Rob Bonta        2 -> 1  AB 1506 mandatory independent DOJ review of officer-
--                              involved deaths + Police Practices Review Division =
--                              active watchdog, not "act on valid claims". (Under v1
--                              he fit chair 1 "investigate independently", not chair 2
--                              "settle valid claims" — an AG does not settle claims.)
--   BLANK (delete answer; rewrite context as a documented blank):
--     David Chiu           prior reasoning itself said "insufficient specific evidence
--                          — assigning based on legislative pattern" (unrelated civil-
--                          rights bills). No topic evidence.
--     Shawn Robinson       "no direct statements on prosecuting officers"; seat rested
--                          on a public-defender occupation inference.
--     Hydee Feldstein Soto cited record is prosecuting protesters with the LAPD (off
--                          this ladder's axis) + a "moderate" rating (not a position).
--     Heather Ferbert      was seated at chair 4 (defense), but the stored reasoning was
--                          accountability-supportive (campaign counsel to the Commission
--                          on Police Practices + a Gun Violence Prevention Unit). A
--                          re-research (2026-09-01) surfaced the opposite on the governing
--                          side: as San Diego City Attorney her office declined to
--                          cooperate with the Commission and deferred to SDPD on officer
--                          conduct. Mixed and contradictory — no primary instrument
--                          cleanly places a chair. Blank rather than guess. (This also
--                          clears the audit-chair-evidence gate, which flagged the move.)
--   REASONING TRIM (chair unchanged; drop the stale trailing "maps to value N: <old
--   wording>" clause that quoted the pre-re-axis chair text, keep all evidence):
--     Aida Ashouri (1), Nathan Hochman (1), Marissa Roy (2), John McKinney (4), Kent Davis (4).
--   CARRY, untouched: Andrea Campbell (1), Jay Jones (2), Brooke Jenkins (3),
--     Dawn McIntosh (3), Jeffrey Gray (3), Sim Gill (3).
--
--   Chair 5 stays at 0 seats — no current officeholder reaches "defend rather than
--   hold accountable"; an honest empty chair, not a defect.
--
-- Idempotent: moves are guarded on the old value; blanks DELETE then rewrite context
--   (re-run is a no-op); trims set fixed text. Post-verify gate on the end state.
-- Model: CA_0033 (re-audit + blanks + ORPHAN guard). Chair-evidence gate: the one MOVE
--   row (Bonta -> 1) names a primary instrument (AB 1506) and passes; carries/blanks
--   assert no new chair. Ferbert's move to 3 FAILED the gate (reasoning named no numbered
--   instrument); the re-research it triggered found a contradictory record, so she is
--   blanked instead — see dispositions.
-- =============================================================================

-- ── 0. Preconditions ─────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='7bad33eb-e93e-4d94-8822-97212d49bde5'
                   AND topic_key='judicial-police-accountability') THEN
    RAISE EXCEPTION 'CA_0097 precondition: topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id='eb6e1ecd-daa3-4362-810b-55fab93ff64c'
                   AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5'
                   AND version=2 AND status='approved') THEN
    RAISE EXCEPTION 'CA_0097 precondition: re-axis v2 (eb6e1ecd) is not approved';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
                   AND number=2 AND status='draft') THEN
    RAISE EXCEPTION 'CA_0097 precondition: Season 2 is not a draft';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions
                 WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
                   AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5'
                   AND topic_revision_id='eb6e1ecd-daa3-4362-810b-55fab93ff64c') THEN
    RAISE EXCEPTION 'CA_0097 precondition: Season 2 does not pin the re-axis v2 (run CA_0080 first)';
  END IF;
END $$;

-- ── 1. Move ──────────────────────────────────────────────────────────────────
-- Rob Bonta 2 -> 1
UPDATE inform.politician_answers
   SET value=1, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='8b183a30-3afb-4d9e-aa40-aa2ad2c674aa'
   AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5' AND value=2;

-- ── 2. Reasoning trims (chair unchanged; drop stale old-chair mapping clause) ──
-- Aida Ashouri (chair 1)
UPDATE inform.politician_context
   SET reasoning = $r$Ashouri has direct, specific positions on police accountability. Her Patch Q&A states: "As city attorney, I would reform the criminal division and train attorneys to recognize cases where constitutional rights are violated and to not file those cases. My goal would be to abolish racial profiling in my office. This will also impact the LAPD as they will be disincentivized to arrest when they knew that we would not file those cases." The LAist voter guide confirms she described "how overpolicing leads to racial profiling and the criminalization of poverty." Her platform explicitly commits to "protecting our rights to protest and be free from unreasonable search and seizure." She would use prosecutorial declination as an accountability mechanism against the LAPD, abolish racial profiling in her office, and decline unconstitutional cases — actively holding law enforcement accountable and working for the public rather than the officials the office is meant to keep in check.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='0f6484bd-2fc1-4071-9648-d7b8a950d29c' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- Nathan Hochman (chair 1)
UPDATE inform.politician_context
   SET reasoning = $r$Hired an independent special prosecutor specifically to handle cases of law enforcement misconduct, framing the DA office as working for the public rather than for law enforcement. Has stated the office will prosecute officers when the evidence warrants — actively holding law enforcement accountable, independent of the departments the office relies on.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='83474f06-c501-416d-a870-65d75f0cec9d' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- Marissa Roy (chair 2)
UPDATE inform.politician_context
   SET reasoning = $r$Roy's approach to police misconduct liability combines accountability with disciplined settlement practice. The SPNA DTLA article identifies as a key platform element: "Critical of Incumbent: Her platform argues the current administration has spent too much on 'liability payouts' and has been overly aggressive in suing journalists and protesters." Her Patch Q&A states regarding legal liability: "For more long-term solutions, I'd work to bring departments in compliance with the law so that we prevent lawsuits before they occur" — framing LAPD compliance as a priority for reducing costs through accountability. The AOL/LA Times piece quotes her vowing "to put a particular focus on the Los Angeles Police Department, making sure it follows through on the recommendations drafted in the wake of costly litigation." Her proposed liability audit by City Controller Kenneth Mejia would scrutinize the office's existing settlement and defense practices for police-related cases. The LA Forward voter guide describes Roy as committed to "holding abusive police accountable" and contrasts her with the incumbent's posture of defending city departments against misconduct lawsuits. Her emphasis is on liability management that produces accountability — resolving valid claims and making the LAPD follow through on reforms — rather than acting as an independent police watchdog.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- John McKinney (chair 4)
UPDATE inform.politician_context
   SET reasoning = $r$McKinney's approach to police misconduct litigation is grounded in vigorous litigation management and liability reduction, not independent accountability. His Patch Q&A states: "As city attorney, I would implement an aggressive risk management strategy to reduce lawsuits and payouts, vigorously defend against frivolous claims, and settle meritorious cases early to avoid costly verdicts." He frames this as knowing "which cases to fight and which to resolve" — a liability management lens. His primary critique of the incumbent is about the LAPD data breach as a management and transparency failure, not about failure to hold police accountable for misconduct. He is endorsed by the Los Angeles Police Protective League (LAPD officer union) and former DAs Nathan Hochman and Jackie Lacey, both with law-enforcement-aligned records. His platform contains no statement about independent investigation of police misconduct, civilian oversight support, or systemic LAPD accountability. The pattern is vigorous defense of city employees, settling only clearly meritorious claims to cut costs rather than as an accountability mechanism, alongside a police-union endorsement — giving employees the benefit of the doubt and conceding only the clear cases.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='6cd2e87b-7366-429a-a049-990751bd647f' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- Kent Davis (chair 4)
UPDATE inform.politician_context
   SET reasoning = $r$Davis's campaign is built around "supporting law enforcement" and he is endorsed by a Sheriff, the Utah Attorney General, and the former Governor. He has made no statement about independently investigating or prosecuting police misconduct. His framing positions law enforcement as partners in public safety, not as actors to be scrutinized.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='974cd2b6-8dd2-4794-aded-88c6ebc38a30' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- ── 3. Blanks: remove the seating, rewrite context as a documented blank ──────
CREATE TEMP TABLE jpa_blank(pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO jpa_blank(pid, tid) VALUES
  ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6','7bad33eb-e93e-4d94-8822-97212d49bde5'), -- David Chiu
  ('068393be-9502-44e6-a36f-2fa99cb9a3e8','7bad33eb-e93e-4d94-8822-97212d49bde5'), -- Shawn Robinson
  ('3f90952e-7d1b-413d-a0e1-e319fb23fa05','7bad33eb-e93e-4d94-8822-97212d49bde5'), -- Hydee Feldstein Soto
  ('0d81c306-514e-455c-988e-b0d04f7e0897','7bad33eb-e93e-4d94-8822-97212d49bde5'); -- Heather Ferbert

DELETE FROM inform.politician_answers a
 USING jpa_blank b
 WHERE a.politician_id=b.pid AND a.topic_id=b.tid;

-- David Chiu
UPDATE inform.politician_context
   SET reasoning = $r$Researched 2026-09-01 — City Attorney David Chiu has no primary instrument on police accountability. The prior seating rested on unrelated civil-rights legislation (corporate diversity mandates, immigrant protections, fair-chance licensing) and a general "legislative pattern" inference, which the prior reasoning itself flagged as insufficient. No source places him at a specific chair on this ladder; left blank.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='86c12b33-cb76-41da-bdf0-6b58a0cbbed6' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- Shawn Robinson
UPDATE inform.politician_context
   SET reasoning = $r$Researched 2026-09-01 — DA candidate Shawn Robinson has no direct statement on holding officers or other government employees accountable. The prior seating rested on his two decades as a public defender and generic "accountability and fairness" campaign language — an occupation inference, not a stated position. No primary source places him at a specific chair on this ladder; left blank.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='068393be-9502-44e6-a36f-2fa99cb9a3e8' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- Hydee Feldstein Soto
UPDATE inform.politician_context
   SET reasoning = $r$Researched 2026-09-01 — City Attorney Hydee Feldstein Soto's cited record concerns charging pro-Palestine protesters — a judge found evidence of biased prosecution and coordination with the LAPD on those charges — which is off this ladder's axis of how the office handles government-employee misconduct. The prior "moderate overall" note is a rating, not a position. No primary source places her at a specific chair on this spectrum; left blank.$r$,
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='3f90952e-7d1b-413d-a0e1-e319fb23fa05' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- Heather Ferbert — was chair 4; re-research (2026-09-01) found a mixed/contradictory record.
UPDATE inform.politician_context
   SET reasoning = $r$Researched 2026-09-01 — Heather Ferbert's record on police accountability is mixed and, on the governing side, contradictory. Her campaign framing supported civilian oversight (counsel to the voter-mandated Commission on Police Practices; a Gun Violence Prevention Unit), but as San Diego City Attorney her office has been reported declining to cooperate with the Commission and deferring to the San Diego Police Department on officer-conduct matters. No single primary instrument cleanly places her at a specific chair on this ladder; left blank.$r$,
       sources = ARRAY[
         'https://heatherferbert.com/public-safety',
         'https://www.sandiego.gov/city-attorney/about',
         'https://www.daylightsandiego.org/executive-director-of-the-san-diego-commission-on-police-practices-is-asking-for-testimony-about-interactions-with-cops/'
       ]::text[],
       editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='0d81c306-514e-455c-988e-b0d04f7e0897' AND topic_id='7bad33eb-e93e-4d94-8822-97212d49bde5';

-- @context-decision: rewritten-as-blank — the topic applies to each person (each is a
-- legal officer whose office handles government-employee/police misconduct) and each
-- record WAS read this pass; none carried a primary instrument placing a specific chair,
-- so each context is a documented blank naming what was checked. No answer row remains.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate, applied to the blanked pairs.
-- Regexes kept character-identical to the gate.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM jpa_blank t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid
   WHERE coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'CA_0097 context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- ── 4. Post-verify ───────────────────────────────────────────────────────────
DO $$
DECLARE
  tid uuid := '7bad33eb-e93e-4d94-8822-97212d49bde5';
  c1 int; c2 int; c3 int; c4 int; c5 int; blanks int; pinned uuid;
BEGIN
  -- Move landed
  IF NOT EXISTS (SELECT 1 FROM inform.politician_answers
                 WHERE politician_id='8b183a30-3afb-4d9e-aa40-aa2ad2c674aa' AND topic_id=tid AND value=1) THEN
    RAISE EXCEPTION 'CA_0097 verify: Bonta not seated at chair 1';
  END IF;
  -- Blanks have no answer row (Chiu, Robinson, Feldstein Soto, Ferbert)
  SELECT count(*) INTO blanks FROM jpa_blank b
    JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF blanks <> 0 THEN RAISE EXCEPTION 'CA_0097 verify: % blanked pair(s) still seated', blanks; END IF;
  -- Distribution 4/2/4/2/0
  SELECT count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2), count(*) FILTER (WHERE value=3),
         count(*) FILTER (WHERE value=4), count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid AND value IS DISTINCT FROM 0;
  IF (c1,c2,c3,c4,c5) <> (4,2,4,2,0) THEN
    RAISE EXCEPTION 'CA_0097 verify: chair counts are %/%/%/%/% (expected 4/2/4/2/0)', c1,c2,c3,c4,c5;
  END IF;
  -- Season 2 still pins the re-axis v2 (unchanged by this migration)
  SELECT topic_revision_id INTO pinned FROM inform.season_questions
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id=tid;
  IF pinned <> 'eb6e1ecd-daa3-4362-810b-55fab93ff64c' THEN
    RAISE EXCEPTION 'CA_0097 verify: Season 2 pin is % (expected re-axis v2)', pinned;
  END IF;

  RAISE NOTICE 'CA_0097 post-verify OK: 1 move (Bonta->1), 4 blanks (Chiu/Robinson/Feldstein Soto/Ferbert), 5 reasoning trims; distribution 4/2/4/2/0; Season 2 still pins v2. Season 1 seatings corrected in place.';
END $$;

COMMIT;
