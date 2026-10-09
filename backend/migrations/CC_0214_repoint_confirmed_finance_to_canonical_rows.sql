-- CC_0214 — give Hurtado, Dutra and Dixon their own campaign finance back.
--
-- Follow-on from CC_0211 / CC_0212 (retire archived duplicates, recover stranded finance) and
-- CC_0213 (detach the CAL-ACCESS surname buckets). Adjudication and evidence:
-- `.planning/todos/2026-10-09-finance-surname-buckets.md`.
--
-- Each of these three people has TWO rows: an active canonical row, and an inactive row seeded on
-- 2026-05-22 that `confirm-cal-access.ts` turned into a surname bucket. CC_0213 marked the
-- mis-attributed committees `disputed`, which removed them from every read. What it deliberately
-- did NOT do was move each person's OWN committees onto the row a voter actually sees.
-- That is all this migration does.
--
--
-- ══ IDENTITY — settled for all three, and two of them were settled in this database already ════
--
-- 🔴 The worklist said the identity was THIN because the inactive rows came from the CA SoS
-- statewide cities-towns roster, which "names no city". That is wrong twice over.
--
--   Gil Hurtado   1a6190c0 -> 75f11f44
--     The roster (admin.cdn.sos.ca.gov/ca-roster/2025/cities-towns.pdf, read 2026-10-09) lists
--     "Council: Gil Hurtado, Al Rios, Maria del Pilar Avalos" under CITY OF SOUTH GATE, and names
--     no other Gil Hurtado in California. The canonical row holds the matching seat here
--     (Council Member, At-Large, City of South Gate, geo_id 0673080) and its photo_origin_url is
--     that city council member page.
--     🔴 AND THE INACTIVE ROW NAMED THE CITY ALL ALONG: its essentials.politician_contacts row is
--     contact_type = city_website, website_url = https://www.cityofsouthgate.org.
--
--   Fernando Dutra  bf91e362 -> 99929a73
--     Already adjudicated by CA_0185 on 2026-09-23, which writes on the inactive row itself:
--     "inactive scraped twin of 99929a73 (Fernando Dutra, former Whittier D4 member, left
--     2026-04-28)". Its city_website contact reads https://www.cityofwhittier.org.
--     ⚠ The 2025 roster still lists him on the Whittier council. He LOST on 2026-04-14 to Aida
--     Susie Macedo. The roster is authoritative for the CITY and stale for the SEAT — the same
--     trap CA_0185 recorded for George Dotson.
--
--   Arthur Dixon   b8e3727a -> 76d1140a
--     🔴 The worklist says the roster cannot settle him and that his FEC committee is "unverified".
--     Neither holds. The inactive row carries fec_house:H6CA34302, whose own FEC records read
--     candidate_first_name = ARTHUR, candidate_last_name = DIXON, HOUSE, California, district 34,
--     committee "ARTHUR DIXON FOR CONGRESS" (C00903773). That is a candidate-ID match, not a
--     surname match. The canonical row photo_origin_url is ballotpedia.org/Arthur_Dixon, which
--     records the same candidacy: Democratic Party, U.S. House California District 34, lost the
--     primary 2026-06-02, $16,991 raised. Two sources, same office, state, district, cycle and
--     outcome.
--
--
-- ══ WHAT THIS MIGRATION MOVES — 8 sources, and only one of them carries money ══════════════════
--
--   Gil Hurtado      4 cal_access   HURTADO FOR CITY COUNCIL 2013/2020/2024, CITY CLERK 2017; GIL
--                                     0 contributions
--   Fernando Dutra   3 cal_access   DUTRA FOR CITY COUNCIL 2014/2018/2026; FERNANDO
--                                     0 contributions
--   Arthur Dixon     1 fec_house    H6CA34302  ARTHUR DIXON FOR CONGRESS
--                                    11 contributions, $12,750
--
-- Every one names its owner in full. The real gain is small and that is the honest finding: two of
-- the three move no money at all, because those people's own committees were never ingested with
-- any contribution rows. Only Arthur Dixon gains anything a voter can see.
--
--
-- ══ WHAT THIS MIGRATION DOES NOT DO — IT DELETES NOTHING ══════════════════════════════════════
--
-- 🔴 The three inactive rows are KEPT, against the CC_0211 / CC_0212 pattern of retiring a
-- duplicate into essentials.politician_merges. Two independent reasons:
--
--   1. They still hold 72 `disputed` CAL-ACCESS sources between them (15 / 14 / 43) — the buckets
--      CC_0213 detached one day ago. `transparent_motivations.politician_sources
--      .essentials_politician_id` is NOT NULL and `filed_report_summaries` holds a RESTRICT FK, so
--      a delete would force those sources either onto a LIVE politician or out of existence.
--      Moving them onto a live row re-creates the exact hazard CC_0213 removed. Deleting them
--      destroys the one-UPDATE revert path that made CC_0213 safe to apply.
--   2. Nothing is gained. An inactive row publishes nothing, so leaving it costs a voter nothing.
--
-- ▶ Retiring them properly becomes available once the disputed buckets are themselves adjudicated.
-- Until then the inactive row IS the bucket, and the bucket is worth keeping.
--
-- 🟢 All five CASCADE / SET NULL foreign keys into essentials.politicians measure ZERO on all six
-- rows (name_aliases, inform.evidence_items, inform.politician_context_evidence,
-- inform.topic_rewrite_stance_proposals, quest_verified_facts). The gate below asserts it, so that
-- a later session reading this file knows no stance research was ever at risk here.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML). Idempotent.

BEGIN;

DO $$
DECLARE
  v_cnt        int;
  v_moved      int := 0;
  k_hurtado_in uuid := '1a6190c0-039a-410c-8340-a47a49daa3d2';
  k_hurtado_ok uuid := '75f11f44-9760-49bf-ab8c-f7aa1f53255f';
  k_dutra_in   uuid := 'bf91e362-ae5b-4229-9217-75ffc6b752ae';
  k_dutra_ok   uuid := '99929a73-8c32-4921-8c12-f5a0f5d4847d';
  k_dixon_in   uuid := 'b8e3727a-388e-4254-87bc-97bee301722b';
  k_dixon_ok   uuid := '76d1140a-6007-4713-ae6c-a1d86893b658';
  n_hurtado_ok CONSTANT text := 'CC_0214 (2026-10-09): same person as inactive row 1a6190c0. The CA SoS 2025 cities-towns roster names Gil Hurtado on the City of South Gate council, and that row city_website contact reads cityofsouthgate.org. Its 4 confirmed CAL-ACCESS committees (HURTADO FOR CITY COUNCIL 2013/2020/2024 and CITY CLERK 2017; GIL) are re-pointed here. They carry 0 contributions - his own money was never ingested.';
  n_hurtado_in CONSTANT text := 'CC_0214 (2026-10-09): duplicate of canonical 75f11f44 (Gil Hurtado, South Gate City Council). Its 4 confirmed committees were re-pointed to that row. KEPT, not deleted: it still holds 15 disputed CAL-ACCESS committees belonging to other Hurtados, and deleting it would destroy the revert path for CC_0213.';
  n_dutra_ok   CONSTANT text := 'CC_0214 (2026-10-09): same person as inactive row bf91e362, already established by CA_0185. Its 3 confirmed CAL-ACCESS committees (DUTRA FOR CITY COUNCIL 2014/2018/2026; FERNANDO) are re-pointed here. They carry 0 contributions.';
  n_dutra_in   CONSTANT text := 'CC_0214 (2026-10-09): duplicate of canonical 99929a73, as CA_0185 recorded. Its 3 confirmed committees were re-pointed to that row. KEPT, not deleted: it still holds 14 disputed CAL-ACCESS committees, mostly John Dutra committees, and deleting it would destroy the revert path for CC_0213.';
  n_dixon_ok   CONSTANT text := 'CC_0214 (2026-10-09): same person as inactive row b8e3727a. FEC candidate H6CA34302 reads ARTHUR DIXON, HOUSE, California district 34, committee ARTHUR DIXON FOR CONGRESS (C00903773); ballotpedia.org/Arthur_Dixon records the same candidacy, lost primary 2026-06-02. That source is re-pointed here: 11 contributions, USD 12,750.';
  n_dixon_in   CONSTANT text := 'CC_0214 (2026-10-09): duplicate of canonical 76d1140a (Arthur Dixon, 2026 candidate for US House CA-34). Its FEC source was re-pointed to that row. KEPT, not deleted: it still holds 43 disputed CAL-ACCESS committees, several named for the CITY of Dixon, and deleting it would destroy the revert path for CC_0213.';
BEGIN

  -- ───────────────────────────────────────── PRE-FLIGHT: the six rows are what this file assumes
  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id IN (k_hurtado_in, k_dutra_in, k_dixon_in) AND is_active = false;
  IF v_cnt <> 3 THEN
    RAISE EXCEPTION 'CC_0214: expected 3 inactive duplicate rows, found %', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id IN (k_hurtado_ok, k_dutra_ok, k_dixon_ok) AND is_active = true;
  IF v_cnt <> 3 THEN
    RAISE EXCEPTION 'CC_0214: expected 3 active canonical rows, found %', v_cnt;
  END IF;

  -- 🔴 The five CASCADE / SET NULL children, counted explicitly before anything moves.
  -- Nothing is deleted here, so this cannot destroy research — it is asserted so the NEXT session,
  -- which may well delete these rows, inherits a measured zero rather than an assumption.
  SELECT (SELECT count(*) FROM essentials.politician_name_aliases    WHERE politician_id IN (k_hurtado_in,k_dutra_in,k_dixon_in))
       + (SELECT count(*) FROM inform.evidence_items                 WHERE politician_id IN (k_hurtado_in,k_dutra_in,k_dixon_in))
       + (SELECT count(*) FROM inform.politician_context_evidence    WHERE politician_id IN (k_hurtado_in,k_dutra_in,k_dixon_in))
       + (SELECT count(*) FROM inform.topic_rewrite_stance_proposals WHERE politician_id IN (k_hurtado_in,k_dutra_in,k_dixon_in))
       + (SELECT count(*) FROM essentials.quest_verified_facts       WHERE politician_id IN (k_hurtado_in,k_dutra_in,k_dixon_in))
    INTO v_cnt;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0214: % CASCADE/SET NULL child rows hang off the inactive rows, expected 0 — re-read the person-merge policy before touching them', v_cnt;
  END IF;

  -- ──────────────────────────────────── PART 1: re-point the CONFIRMED sources, and only those
  -- `research_status = 'confirmed'` is the whole predicate. CC_0213 already decided, committee by
  -- committee, which sources name their owner; this migration must not re-litigate that, and must
  -- never move a `disputed` row onto a live politician.
  WITH moved AS (
    UPDATE transparent_motivations.politician_sources s
       SET essentials_politician_id = CASE s.essentials_politician_id
             WHEN k_hurtado_in THEN k_hurtado_ok
             WHEN k_dutra_in   THEN k_dutra_ok
             WHEN k_dixon_in   THEN k_dixon_ok END,
           updated_at = now()
     WHERE s.essentials_politician_id IN (k_hurtado_in, k_dutra_in, k_dixon_in)
       AND s.research_status = 'confirmed'
    RETURNING 1)
  SELECT count(*) INTO v_moved FROM moved;

  -- ───────────────────────────────────────────────── PART 2: record the ruling ON the rows
  UPDATE essentials.politicians SET notes = coalesce(notes,'{}'::text[]) || ARRAY[n_hurtado_ok]
   WHERE id = k_hurtado_ok AND NOT (coalesce(notes,'{}'::text[]) @> ARRAY[n_hurtado_ok]);
  UPDATE essentials.politicians SET notes = coalesce(notes,'{}'::text[]) || ARRAY[n_hurtado_in]
   WHERE id = k_hurtado_in AND NOT (coalesce(notes,'{}'::text[]) @> ARRAY[n_hurtado_in]);
  UPDATE essentials.politicians SET notes = coalesce(notes,'{}'::text[]) || ARRAY[n_dutra_ok]
   WHERE id = k_dutra_ok   AND NOT (coalesce(notes,'{}'::text[]) @> ARRAY[n_dutra_ok]);
  UPDATE essentials.politicians SET notes = coalesce(notes,'{}'::text[]) || ARRAY[n_dutra_in]
   WHERE id = k_dutra_in   AND NOT (coalesce(notes,'{}'::text[]) @> ARRAY[n_dutra_in]);
  UPDATE essentials.politicians SET notes = coalesce(notes,'{}'::text[]) || ARRAY[n_dixon_ok]
   WHERE id = k_dixon_ok   AND NOT (coalesce(notes,'{}'::text[]) @> ARRAY[n_dixon_ok]);
  UPDATE essentials.politicians SET notes = coalesce(notes,'{}'::text[]) || ARRAY[n_dixon_in]
   WHERE id = k_dixon_in   AND NOT (coalesce(notes,'{}'::text[]) @> ARRAY[n_dixon_in]);

  -- ────────────────────────────────── VERIFY the END STATE, so a re-run passes too
  -- 1. no confirmed source is left on any of the three inactive rows
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN (k_hurtado_in, k_dutra_in, k_dixon_in)
     AND research_status = 'confirmed';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0214: % confirmed sources still sit on the inactive rows, expected 0', v_cnt;
  END IF;

  -- 2. the canonical rows hold exactly what was moved
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = k_hurtado_ok AND research_status = 'confirmed';
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'CC_0214: Gil Hurtado holds % confirmed sources, expected 4', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = k_dutra_ok AND research_status = 'confirmed';
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'CC_0214: Fernando Dutra holds % confirmed sources, expected 3', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = k_dixon_ok AND research_status = 'confirmed';
  IF v_cnt <> 1 THEN RAISE EXCEPTION 'CC_0214: Arthur Dixon holds % confirmed sources, expected 1', v_cnt; END IF;

  -- 3. 🔴 THE DISPUTED BUCKETS MUST NOT HAVE MOVED. This is the one way this migration could do
  --    harm: a disputed source landing on a live politician re-publishes other people's donations.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN (k_hurtado_ok, k_dutra_ok, k_dixon_ok)
     AND research_status <> 'confirmed';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0214: % non-confirmed sources reached a LIVE politician — that is the CC_0213 harm, re-created', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN (k_hurtado_in, k_dutra_in, k_dixon_in)
     AND research_status = 'disputed';
  IF v_cnt <> 72 THEN
    RAISE EXCEPTION 'CC_0214: the inactive rows hold % disputed sources, expected 72 (15 + 14 + 43)', v_cnt;
  END IF;

  -- 4. the only money this migration makes visible: Arthur Dixon's own 11 contributions
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
   WHERE s.essentials_politician_id = k_dixon_ok
     AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 11 THEN
    RAISE EXCEPTION 'CC_0214: Arthur Dixon publishes % contributions, expected 11', v_cnt;
  END IF;

  -- 5. and the two who gain nothing visible still gain nothing — asserted, so that a later
  --    ingestion run that DOES load their contributions shows up as a change rather than a surprise
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources s ON s.id = c.politician_source_id
   WHERE s.essentials_politician_id IN (k_hurtado_ok, k_dutra_ok) AND s.research_status = 'confirmed';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0214: Hurtado and Dutra publish % contributions, expected 0 — their committees held none when this was written', v_cnt;
  END IF;

  RAISE NOTICE 'CC_0214: re-pointed % confirmed sources to their canonical rows (Hurtado 4, Dutra 3, Dixon 1). Arthur Dixon now publishes his own 11 contributions (USD 12,750); Hurtado and Dutra gain 0, their committees hold none. 72 disputed bucket sources left untouched on the inactive rows, which are KEPT.', v_moved;
END $$;

COMMIT;
