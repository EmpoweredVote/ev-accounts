-- CC_0225 — ADR 0008: give four committees an EVIDENCED direction, and publish two of them.
--
-- `CC_0224` added `support_oppose` and the read path began withholding anything without one.
-- This migration supplies the values, each from a named FPPC filing read on 2026-10-10.
--
-- Applies with `DATABASE_URL` (`ev_api`) — this is DML, unlike `CC_0224`.
--
--
-- ══ THE EVIDENCE, ONE FILING PER ROW ═════════════════════════════════════════════════════════
--
--   1489255  WORKING FAMILIES FOR JOHN ERICKSON …      -> support   Form 496 #3201920, Part 1
--   1447993  … SUPPORTING SENATOR MELISSA HURTADO      -> support   Form 460 #2779221, Part 7
--   1448127  CALIFORNIANS FOR SOLUTIONS SUPPORTING
--            MIKE GIPSON                               -> support   Form 460 #2763543, Part 7
--   1418587  RAN ACTION FUND COMMITTEE TO RECALL
--            GAVIN NEWSOM                              -> 🔴 OPPOSE  Form 460 #2463962, Part 6
--
-- Part 7 ("Primarily Formed Committee") names the candidate, the office and a SUPPORT/OPPOSE
-- checkbox. Gipson's reads `Mike Gipson · State Assembly Person District No. 65 · SUPPORT`;
-- Hurtado's `Melissa Hurtado · State Senator District No. 16 · SUPPORT`.
--
-- 🟢 **Form 496 carries the same field and ADR 0008 did not know it.** Erickson's committee files a
-- *Late Independent Expenditure Report*, whose Part 1 "List Only One Candidate or Ballot Measure"
-- names `John Erickson · State Senator District 24 · SUPPORT ☒`. A pure-IE committee may file
-- **only** 496s, so a Part 7-only rule would have found nothing for it.
--
--
-- ══ 🔴🔴 THE INVERSION — WHY A NAIVE READ WOULD HAVE PUBLISHED THE OPPOSITE ═══════════════════
--
-- **The Newsom recall committee does not use Part 7 at all.** It files as a **BALLOT MEASURE
-- COMMITTEE** under **Part 6**:
--
--     NAME OF BALLOT MEASURE:  Recall Gavin Newsom
--     SUPPORT ☒   OPPOSE ☐
--
-- 🔴 **The checkbox says SUPPORT, and the correct value for this row is `oppose`.** Part 6's
-- direction is relative to the **MEASURE**, not to the politician — and the measure is his recall.
-- Supporting the recall is opposing the officeholder. **For a recall measure the polarity
-- INVERTS.**
--
-- ▶ Had this been read as a checkbox rather than as a sentence, `CC_0225` would have published
-- $33,172.80 raised to REMOVE Gavin Newsom as money SUPPORTING him — on a live Governor's page.
-- That is precisely the false statement ADR 0008 exists to prevent, arriving through the very
-- field added to prevent it.
--
-- ⚠ **So `support_oppose` cannot be mechanically copied from a checkbox.** The column means
-- *direction relative to THIS POLITICIAN*; the filing means *direction relative to whatever the
-- filer named*. When those differ, the filing must be read. ADR 0008 §4 is amended accordingly.
--
--
-- ══ WHAT PUBLISHES, AND WHAT GOES DARK ═══════════════════════════════════════════════════════
--
-- **Gipson and Newsom are also RETYPED.** Both sit on live incumbents as
-- `candidate_committee` / `disputed` — withheld, because confirming them as-is would publish a
-- committee the politician does not control as their own fundraising. They are IE committees:
-- retyped `ie_committee`, confirmed, and given a direction, they publish as **outside spending**,
-- which is what they have always been.
--
--     Mike A. Gipson   +8 contributions    $194,000.00   supporting him
--     Gavin Newsom     +402 contributions  $ 33,172.80   OPPOSING him
--
-- 🔴 **`1442937` TRACI PARK IS DELIBERATELY LEFT NULL AND THEREFORE GOES DARK** (20 contributions,
-- $4,050). It is an `la_socrata` row — an LA **city** filer — and a sweep of CAL-ACCESS sessions
-- found **no filings for it at all**, so there is no Form 460 or 496 to read. Its committee name
-- reads as support; **a name is not evidence**, which is the rule this whole ADR rests on.
-- ADR 0008 §5 accepted exactly this cost. ▶ Its direction must come from the LA city filing
-- system, and that is open work.

BEGIN;

DO $$
DECLARE
  v_cnt int;
  v_contrib0 bigint;
  n int;
BEGIN
  CREATE TEMP TABLE _ev (src uuid, ext text, who text, dir text, filing text) ON COMMIT DROP;
  INSERT INTO _ev VALUES
    ('432e9040-81e9-4b80-8e56-6f981883c9a6','1489255','John Erickson',  'support','Form 496 #3201920 Part 1'),
    ('18db72ef-bbf6-46b3-aabe-26203fa587b7','1447993','Melissa Hurtado','support','Form 460 #2779221 Part 7'),
    ('d40629eb-00b9-406d-b4d5-08752a9bea20','1448127','Mike A. Gipson', 'support','Form 460 #2763543 Part 7'),
    ('ffe32d48-3903-4377-a456-f3daac53370a','1418587','Gavin Newsom',   'oppose', 'Form 460 #2463962 Part 6 (recall measure; polarity inverted)');

  -- ── PRE-VERIFY ────────────────────────────────────────────────────────────────────────────

  -- 1. All four rows exist, on the politician the filing names, and all four are LIVE.
  SELECT count(*) INTO v_cnt
    FROM _ev e JOIN transparent_motivations.politician_sources s ON s.id = e.src
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE s.external_id = e.ext AND p.full_name = e.who AND p.is_active;
  IF v_cnt <> 4 THEN
    RAISE EXCEPTION 'CC_0225: % of 4 rows match (id, external_id, politician, live), want 4', v_cnt;
  END IF;

  -- 2. 🔴 `CC_0224` must already be applied, or this writes into a column with no CHECK behind it.
  SELECT count(*) INTO v_cnt FROM pg_constraint
   WHERE conname = 'politician_sources_support_oppose_check'
     AND conrelid = 'transparent_motivations.politician_sources'::regclass;
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0225: CC_0224 has not been applied — no CHECK present'; END IF;

  -- 3. None of the four already carries a direction.
  SELECT count(*) INTO v_cnt
    FROM _ev e JOIN transparent_motivations.politician_sources s ON s.id = e.src
   WHERE s.support_oppose IS NOT NULL;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0225: % of the 4 already have a direction', v_cnt; END IF;

  -- 4. Record the money so the post-verify can prove this migration moved none of it. It only
  --    changes where the money is DESCRIBED, never which rows it hangs on.
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c
   WHERE c.politician_source_id IN (SELECT src FROM _ev);
  IF v_contrib0 <> 419 THEN
    RAISE EXCEPTION 'CC_0225: the 4 sources carry % contributions, expected 419', v_contrib0;
  END IF;

  -- ── PART A — the two already typed ie_committee/confirmed: direction only ─────────────────

  UPDATE transparent_motivations.politician_sources s
     SET support_oppose = e.dir,
         notes = COALESCE(s.notes,'') || ' | DIRECTION CC_0225: ' || e.dir || ' per ' || e.filing,
         updated_at = now()
    FROM _ev e
   WHERE s.id = e.src AND e.ext IN ('1489255','1447993')
     AND s.source_type = 'ie_committee' AND s.research_status = 'confirmed';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0225: Part A updated % rows, expected 2', n; END IF;

  -- ── PART B — the two withheld ones: retype, confirm, and give a direction ─────────────────

  UPDATE transparent_motivations.politician_sources s
     SET source_type = 'ie_committee',
         research_status = 'confirmed',
         support_oppose = e.dir,
         notes = COALESCE(s.notes,'')
                 || ' | IE + DIRECTION CC_0225: this is an outside-spending committee, not one the '
                 || 'politician controls. Direction ' || e.dir || ' per ' || e.filing,
         updated_at = now()
    FROM _ev e
   WHERE s.id = e.src AND e.ext IN ('1448127','1418587')
     AND s.source_type = 'candidate_committee' AND s.research_status = 'disputed';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0225: Part B updated % rows, expected 2', n; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  -- 1. 🔴🔴 THE ONE THAT MATTERS: Newsom's recall committee is `oppose`. If a future edit ever
  --    flips this to 'support' it publishes money raised to remove him as money he raised.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.id = 'ffe32d48-3903-4377-a456-f3daac53370a' AND s.support_oppose = 'oppose';
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'CC_0225: the Newsom RECALL committee is not oppose — refusing to publish it';
  END IF;

  -- 2. All four now carry a direction, and all four publish.
  SELECT count(*) INTO v_cnt
    FROM _ev e JOIN transparent_motivations.politician_sources s ON s.id = e.src
   WHERE s.support_oppose = e.dir AND s.source_type = 'ie_committee'
     AND s.research_status = 'confirmed';
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'CC_0225: % of 4 are publishable with the right direction', v_cnt; END IF;

  -- 3. 🔴 Traci Park's la_socrata row stays NULL and therefore stays withheld. Asserting the
  --    ABSENCE is the point: it is the cost ADR 0008 §5 accepted, not an oversight.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.id = 'ec42b073-6bfb-4900-be5e-0cb2becd7c11' AND s.support_oppose IS NULL;
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'CC_0225: Traci Park 1442937 was given a direction it has no evidence for';
  END IF;

  -- 4. Exactly four rows in the whole corpus carry a direction. Nothing was swept in.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE support_oppose IS NOT NULL;
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'CC_0225: % rows carry a direction, expected exactly 4', v_cnt; END IF;

  -- 5. No contribution moved. This migration re-describes money; it never relocates it.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.contributions c
   WHERE c.politician_source_id IN (SELECT src FROM _ev);
  IF v_cnt <> v_contrib0 THEN
    RAISE EXCEPTION 'CC_0225: the 4 sources carried % contributions and now carry %', v_contrib0, v_cnt;
  END IF;

  RAISE NOTICE 'CC_0225: 4 directions evidenced (1 OPPOSE), Gipson + Newsom now publish as outside spending, Traci Park left dark';
END $$;

COMMIT;
