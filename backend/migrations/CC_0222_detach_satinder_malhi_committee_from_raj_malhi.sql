-- CC_0222 — `MALHI FOR ASSEMBLY 2016` is Satinder S. Malhi's, not Raj Malhi's. Detach it.
--
-- The first MONEY-CARRYING misattribution the confirmed-518 audit found, and the only one in
-- $357.4M. Audit: `.planning/todos/2026-10-10-cal-access-confirmed-518-audit-log.md`.
-- Buckets and the eight duplicate rows: `CC_0221`.
--
--
-- ══ THE EVIDENCE — FPPC FORM 460, COVER PAGE PART 5 ══════════════════════════════════════════
--
-- Filing `2000320` for committee `1376762`, a termination statement for 07/01/2015-11/16/2015,
-- signed **under penalty of perjury**:
--
--     COMMITTEE NAME ................ Malhi for Assembly 2016          (I.D. 1376762)
--     PART 5, NAME OF CANDIDATE ..... Satinder S. Malhi
--     OFFICE SOUGHT ................. State Assembly Person, Assembly District 14
--     ADDRESS ....................... Sacramento, CA 95841
--     VERIFICATION SIGNED BY ........ Satinder S. Malhi, 11/17/2015
--
-- Our row is **`Raj Malhi`**, whose other cal_access source is `1382079`
-- **`MALHI FOR LANCASTER CITY COUNCIL 2018; RAJ`** — Lancaster is in **Los Angeles County**, some
-- 400 miles from Sacramento, and nowhere near AD-14 (Contra Costa / Solano).
--
-- 🟢 **Satinder S. Malhi is independently present in this corpus as a separate person** — the
-- `cal_access_discovery` placeholder `MALHI FOR MARTINEZ CITY COUNCIL 2024; SATINDER S`
-- (`1470998`), Martinez being in Contra Costa County, consistent with AD-14. Two different people.
--
-- ⚠ **He has no real politician row**, only placeholders — so, exactly as with Esmeralda Hurtado in
-- `CC_0221`, the disposition is **`not_applicable`, NOT a repoint.**
--
--
-- ══ WHY THE AUDIT NEARLY MISSED IT, AND WHAT THAT CHANGES ════════════════════════════════════
--
-- 🔴🔴 **ABSENCE FROM THE CAL-ACCESS CANDIDATE PAGE IS NOT EVIDENCE OF MISATTRIBUTION.** Three
-- money-carrying sources were flagged by that signal. **Two of the three were CORRECT** and stay
-- `confirmed` — a 67% false-positive rate on the audit's main instrument:
--
--     1480126  DIXON FOR SUPERVISOR 2026; DIANE      $798,784   ✅ CORRECT — hers
--     1451483  SOLACHE FOR CITY COUNCIL 2022         $ 76,121   ✅ CORRECT — his
--     1376762  MALHI FOR ASSEMBLY 2016               $ 31,050   🔴 WRONG — this migration
--
-- **Diane Dixon's committee is absent because it carries no `(OFFICEHOLDER: …)` line**: the office
-- sought is coded **"Other"** (Orange County Supervisor, District 5 — a county office with no state
-- office code), while her linked committees all show `(OFFICEHOLDER: ASSEMBLY DISTRICT 72)`. Her
-- Form 460 of 2026-09-24 names her and she signed it; her Assembly 2026 committee `1477047`
-- **terminated 2026-06-30 with $0**, because she switched races. Jose Solache's Form 460 names him
-- as Lynwood City Council Member and **cross-lists `1443410` as his controlled committee**, which
-- independently confirms a second source of ours.
--
-- 🟢 **THE FORM 460 COVER PAGE IS A STRONGER INSTRUMENT THAN THE CANDIDATE PAGE.** Part 5 names the
-- candidate **and** the office sought, under penalty of perjury, and exists for every committee
-- that files — including the ones seeking a non-state office that the candidate page cannot reach.
-- ▶ **Use it whenever the candidate page is silent. Silence is not a negative.**
--
-- Two traps in getting to it, both already paid for once:
-- - 🔴 **The PDF endpoint returns the 212-byte Incapsula stub at HTTP 200 `text/html`** to `curl`.
--   Fetch it inside the Playwright context, as `application/pdf`.
-- - 🔴 **The electronic-filings list is SESSION-SCOPED.** A first pass read the default session and
--   reported **zero filings** for both committees; a positive control against `1480126` (known to
--   have 7) exposed it. Solache's sit in 2021/2023/2025, Malhi's in 2015.
--
--
-- ══ WHAT CHANGES ═════════════════════════════════════════════════════════════════════════════
--
-- **One source.** `1376762` on `Raj Malhi` (`57ffdbb3`) goes `confirmed` -> `not_applicable`.
--
-- ⚠ **Raj Malhi's row is `is_active = false`, `source = 'scraped'`** — so this publishes nothing
-- today, and the $31,050 was never on a voter's page. It is the same loaded-gun shape as `CC_0221`'s
-- eight rows: a merge would have carried it onto a live officeholder. ▶ **Add Raj Malhi to the
-- dedupe backlog**; `check:duplicate-people` cannot see him either, being inactive.
--
-- 🔴 **THE 69 CONTRIBUTIONS ARE NOT DELETED AND THE SOURCE ROW STAYS.**
-- `contributions.politician_source_id` has no foreign key, so removing the source would strand them
-- silently. Only `research_status` changes; the count is asserted identical before and after.
--
-- ⚠ `1382079` `MALHI FOR LANCASTER CITY COUNCIL 2018; RAJ` **stays `confirmed`** — it names Raj and
-- is his. This migration does not touch it.

BEGIN;

DO $$
DECLARE
  v_cnt int;
  v_contrib0 bigint;
  v_amt0 numeric;
  v_src uuid;
  n int;
BEGIN
  -- ── PRE-VERIFY ────────────────────────────────────────────────────────────────────────────

  -- 1. Exactly one confirmed source for this committee on Raj Malhi's row.
  SELECT s.id INTO v_src
    FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access'
     AND s.external_id = '1376762'
     AND s.essentials_politician_id = '57ffdbb3-a8bb-4337-9812-3216dd325f74'
     AND s.source_type = 'candidate_committee'
     AND s.research_status = 'confirmed';
  IF v_src IS NULL THEN
    RAISE EXCEPTION 'CC_0222: no confirmed 1376762 on Raj Malhi — already done, or the row moved';
  END IF;

  -- 2. The row really is Raj Malhi, and really is the inactive scraped one. Asserting BOTH halves:
  --    the name, so we are detaching from who we think, and the inactivity, so we know the blast
  --    radius is zero today.
  SELECT count(*) INTO v_cnt FROM essentials.politicians p
   WHERE p.id = '57ffdbb3-a8bb-4337-9812-3216dd325f74'
     AND p.full_name = 'Raj Malhi' AND p.is_active = false AND p.source = 'scraped';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0222: target row is not the inactive scraped Raj Malhi'; END IF;

  -- 3. The money, recorded so the post-verify can prove none of it moved or vanished.
  SELECT count(*), COALESCE(sum(amount),0) INTO v_contrib0, v_amt0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id = v_src;
  IF v_contrib0 <> 69 THEN
    RAISE EXCEPTION 'CC_0222: 1376762 carries % contributions, expected 69 — re-read before writing', v_contrib0;
  END IF;
  IF round(v_amt0) <> 31050 THEN
    RAISE EXCEPTION 'CC_0222: 1376762 carries $%, expected $31,050', round(v_amt0);
  END IF;

  -- 4. 🔴 Satinder S. Malhi has NO real politician row — which is WHY this is not_applicable
  --    rather than a repoint. If one ever appears, this migration's reasoning no longer holds.
  SELECT count(*) INTO v_cnt FROM essentials.politicians p
   WHERE p.full_name ILIKE '%malhi%' AND p.source <> 'cal_access_discovery'
     AND p.id <> '57ffdbb3-a8bb-4337-9812-3216dd325f74';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0222: % non-placeholder Malhi row(s) now exist — repoint instead of detaching', v_cnt;
  END IF;

  -- ── THE CHANGE ────────────────────────────────────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'not_applicable',
         notes = COALESCE(s.notes, '')
                 || ' | NOT APPLICABLE CC_0222: FPPC Form 460 filing 2000320 cover page Part 5 names '
                 || 'SATINDER S. MALHI, Assembly District 14, Sacramento — not Raj Malhi, whose own '
                 || 'committee 1382079 is Lancaster city council in Los Angeles County. Adjudicated '
                 || '2026-10-10 against the Form 460, the candidate page being silent.',
         updated_at = now()
   WHERE s.id = v_src;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0222: updated % rows, expected 1', n; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  -- 1. End state, read back.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.id = v_src AND s.research_status = 'not_applicable';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0222: 1376762 did not reach not_applicable'; END IF;

  -- 2. 🔴 Every one of the 69 contributions is still attached to this source, for the same total.
  --    No FK protects them; this is the assertion that stands in for one.
  SELECT count(*), COALESCE(sum(amount),0) INTO v_cnt, v_amt0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id = v_src;
  IF v_cnt <> v_contrib0 THEN
    RAISE EXCEPTION 'CC_0222: source carried % contributions and now carries %', v_contrib0, v_cnt;
  END IF;
  IF round(v_amt0) <> 31050 THEN RAISE EXCEPTION 'CC_0222: total changed to $%', round(v_amt0); END IF;

  -- 3. Raj Malhi keeps his OWN Lancaster committee. Detaching the wrong one must not take the
  --    right one with it.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.essentials_politician_id = '57ffdbb3-a8bb-4337-9812-3216dd325f74'
     AND s.external_id = '1382079' AND s.research_status = 'confirmed';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0222: Raj Malhi lost his own Lancaster committee'; END IF;

  -- 4. Nothing else was touched: exactly one cal_access source carries a CC_0222 note.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.notes LIKE '%CC_0222%';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0222: % sources carry a CC_0222 note, expected 1', v_cnt; END IF;

  -- 5. The two correct ones are untouched and still publishing. This migration is as much about
  --    what it REFUSED to change as what it changed.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.external_id IN ('1480126','1451483')
     AND s.research_status = 'confirmed';
  IF v_cnt <> 2 THEN
    RAISE EXCEPTION 'CC_0222: Dixon 1480126 / Solache 1451483 — % still confirmed, expected 2', v_cnt;
  END IF;

  RAISE NOTICE 'CC_0222: 1 source detached from Raj Malhi, 69 contributions intact, Dixon and Solache left confirmed';
END $$;

COMMIT;
