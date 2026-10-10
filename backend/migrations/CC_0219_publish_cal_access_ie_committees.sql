-- CC_0219 — publish the two CAL-ACCESS independent-expenditure committees that were parked.
--
-- `CC_0216` and `CC_0218` identified two genuine IE committees, moved them to the right live
-- politician and typed them `ie_committee` — but deliberately left them `not_applicable`, because
-- `getOutsideSpendingForPolitician` could not render a non-`la_socrata` committee. It gathered a
-- committee's rows with `source_system = 'la_socrata'` hardcoded while the CTE that LISTS the
-- committees carried no such filter, so a confirmed cal_access IE link rendered as **a card with an
-- empty name and $0**.
--
-- 🔴 **THAT CODE FIX IS THE PRECONDITION FOR THIS MIGRATION, AND IT IS NOT OBSERVABLE FROM THE
-- DATABASE.** It shipped in PR #969 (merge commit 906e018d) and must be LIVE on `ev-accounts-api`
-- before this runs — Render auto-deploy can silently not fire, so the check is
-- `list_deploys` for the SHA, not an assumption. Applying this first publishes the broken card.
-- Nothing in SQL can assert it; this comment is the gate.
--
--     1447993  HURTADO 2022; COALITION OF BUSINESS ORGANIZATIONS SUPPORTING SENATOR MELISSA
--              -> Melissa Hurtado  d3b4ee4d    8 contributions   $344,843.80
--     1489255  ERICKSON FOR STATE SENATE 2026, SPONSORED BY UNITE HERE LOCAL 11;
--              WORKING FAMILIES FOR JOHN
--              -> John Erickson    29ccd743    1 contribution    $ 25,000.00
--
-- Both were typed `candidate_committee` by `confirm-cal-access.ts` and would have published as the
-- politician's OWN fundraising. Both are absent from their candidate's CAL-ACCESS candidate page,
-- which is what established they are not candidate-controlled — the same test that, run the other
-- way, proved "VALLEY FAMILIES FOR MELISSA HURTADO FOR SENATE 2026" **is** hers.
--
-- 🟢 **THIS CANNOT MOVE EITHER POLITICIAN'S OWN FUNDRAISING.** `campaignFinanceService.ts:37` reads
-- own fundraising through `research_status = 'confirmed' AND source_type = 'candidate_committee'`,
-- and these stay `ie_committee`. The post-verify asserts both totals are byte-identical.
-- What changes is `outside_spending.committees`, which is reported separately and labelled as
-- spending by others.

BEGIN;

DO $$
DECLARE
  r          record;
  v_cnt      bigint;
  v_n        bigint;
  v_sum      numeric;
  v_melissa  uuid;
  v_john     uuid;
  n_pub      int := 0;
BEGIN
  -- ── idempotence
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources
   WHERE external_id IN ('1447993','1489255') AND source_system = 'cal_access'
     AND source_type = 'ie_committee' AND research_status = 'confirmed';
  IF v_cnt = 2 THEN
    RAISE NOTICE 'CC_0219: already applied (both IE committees are confirmed) — skipping';
    RETURN;
  END IF;

  SELECT p.id INTO v_melissa FROM essentials.politicians p
   WHERE p.id::text LIKE 'd3b4ee4d%' AND p.full_name = 'Melissa Hurtado' AND p.is_active;
  IF v_melissa IS NULL THEN RAISE EXCEPTION 'CC_0219: no active "Melissa Hurtado" at d3b4ee4d'; END IF;

  SELECT p.id INTO v_john FROM essentials.politicians p
   WHERE p.id::text LIKE '29ccd743%' AND p.full_name = 'John Erickson' AND p.is_active;
  IF v_john IS NULL THEN RAISE EXCEPTION 'CC_0219: no active "John Erickson" at 29ccd743'; END IF;

  -- capture own-fundraising before, so the post-verify compares rather than asserts a constant
  CREATE TEMP TABLE _own_before ON COMMIT DROP AS
    SELECT s.essentials_politician_id AS pid, count(c.id) AS n, coalesce(sum(c.amount), 0) AS amt
      FROM transparent_motivations.politician_sources s
      LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
     WHERE s.essentials_politician_id IN (v_melissa, v_john)
       AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee'
     GROUP BY 1;

  SELECT count(*) INTO v_cnt FROM _own_before;
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'CC_0219: captured % own-fundraising baselines, expected 2', v_cnt; END IF;

  -- ── publish, each resolved by (external_id + the live row it hangs on)
  FOR r IN
    SELECT x.ext, x.owner FROM (VALUES
      ('1447993', 'melissa'),
      ('1489255', 'john')
    ) AS x(ext, owner)
  LOOP
    SELECT count(*) INTO v_cnt
      FROM transparent_motivations.politician_sources s
     WHERE s.source_system = 'cal_access' AND s.external_id = r.ext
       AND s.essentials_politician_id = CASE r.owner WHEN 'melissa' THEN v_melissa ELSE v_john END
       AND s.source_type = 'ie_committee' AND s.research_status = 'not_applicable';
    IF v_cnt <> 1 THEN
      RAISE EXCEPTION 'CC_0219: % resolves to % parked ie_committee rows on its live politician, expected 1', r.ext, v_cnt;
    END IF;

    UPDATE transparent_motivations.politician_sources s
       SET research_status = 'confirmed',
           notes = (s.notes::jsonb || jsonb_build_object(
                      'published_by','CC_0219',
                      'published_reason','outside spending in this politician''s race; publishable once getOutsideSpendingForPolitician stopped scoping its gather to source_system=la_socrata (PR #969)'))::text,
           updated_at = now()
     WHERE s.source_system = 'cal_access' AND s.external_id = r.ext
       AND s.essentials_politician_id = CASE r.owner WHEN 'melissa' THEN v_melissa ELSE v_john END
       AND s.source_type = 'ie_committee';
    n_pub := n_pub + 1;
  END LOOP;

  IF n_pub <> 2 THEN RAISE EXCEPTION 'CC_0219: published % committees, expected 2', n_pub; END IF;

  -- ══ POST-VERIFY ═════════════════════════════════════════════════════════════════════════════

  -- 1. 🔴 NEITHER POLITICIAN'S OWN FUNDRAISING MOVED. This is the invariant that makes publishing
  --    outside spending safe: it is reported beside their money, never added to it.
  FOR r IN
    SELECT b.pid, b.n AS was_n, b.amt AS was_amt,
           (SELECT count(c.id) FROM transparent_motivations.politician_sources s
              LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
             WHERE s.essentials_politician_id = b.pid
               AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee') AS now_n,
           (SELECT coalesce(sum(c.amount), 0) FROM transparent_motivations.politician_sources s
              LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
             WHERE s.essentials_politician_id = b.pid
               AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee') AS now_amt
      FROM _own_before b
  LOOP
    IF r.was_n <> r.now_n OR round(r.was_amt, 2) <> round(r.now_amt, 2) THEN
      RAISE EXCEPTION 'CC_0219: own fundraising for % moved from % / % to % / %',
                      r.pid, r.was_n, round(r.was_amt, 2), r.now_n, round(r.now_amt, 2);
    END IF;
  END LOOP;

  -- 2. Each committee is confirmed, still typed ie_committee, on a LIVE politician, and carries
  --    the contributions the adjudication measured.
  SELECT count(c.id), coalesce(sum(c.amount), 0) INTO v_n, v_sum
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id = v_melissa AND s.external_id = '1447993'
     AND s.source_type = 'ie_committee' AND s.research_status = 'confirmed';
  IF v_n <> 8 OR round(v_sum, 2) <> 344843.80 THEN
    RAISE EXCEPTION 'CC_0219: Hurtado IE committee is % / %, expected 8 / 344843.80', v_n, round(v_sum, 2);
  END IF;

  SELECT count(c.id), coalesce(sum(c.amount), 0) INTO v_n, v_sum
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id = v_john AND s.external_id = '1489255'
     AND s.source_type = 'ie_committee' AND s.research_status = 'confirmed';
  IF v_n <> 1 OR round(v_sum, 2) <> 25000.00 THEN
    RAISE EXCEPTION 'CC_0219: Erickson IE committee is % / %, expected 1 / 25000.00', v_n, round(v_sum, 2);
  END IF;

  -- 3. No cal_access source anywhere became `confirmed candidate_committee` as a side effect —
  --    that is the shape that would publish somebody else's money as their own.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
   WHERE s.external_id IN ('1447993','1489255') AND s.source_system = 'cal_access'
     AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0219: % of these committees are confirmed as OWN fundraising', v_cnt;
  END IF;

  -- 4. The two discovery placeholder rows carrying the same filer ids are untouched. They are
  --    gathered by the widened query (same system, same id) and hold zero contributions, so they
  --    add nothing — but they must not have been promoted.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE s.external_id IN ('1447993','1489255') AND s.source_system = 'cal_access'
     AND p.source = 'cal_access_discovery' AND s.research_status <> 'needs_research';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0219: % discovery placeholder rows changed state', v_cnt;
  END IF;

  RAISE NOTICE 'CC_0219: 2 IE committees published; own fundraising unchanged on both politicians';
END $$;

COMMIT;
