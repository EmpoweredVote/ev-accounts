-- Migration 1190: Kim Young (Councilor / Council President, Sherwood OR) compass stances — AUDIT-ONLY (not registered in the ledger)
-- Evidence-only; 100% cited; chairs model (value 1-5); 3 cited stances; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live=true (no hardcoded topic UUIDs).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'At the October 28, 2025 special session (attending remotely, per roll call), Council President Young personally moved adoption of Resolution 2025-073 declaring an emergency to refer Charter amendments protecting Sherwood''s home-rule authority against state housing-preemption bills; the minutes record her saying "taking away public participation in land use decisions was counter to Statewide Land Use Goal 1" and that she supported the resolution. She then seconded Resolution 2025-074, which asked voters to enshrine that "annexation may only take effect with the approval of city voters" (barring a public-health emergency) and that this authority "shall not be preempted by state laws." Voters ratified the measure 82.71% in favor on January 13, 2026. Personally introducing and seconding the voter-approval-gate charter amendments matches the require-voter-approval-for-annexations-and-major-development chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf']::text[]),
    ('residential-zoning', 2, 'On Resolution 2025-075 at the same October 28, 2025 session — the Charter measure enshrining citizen involvement in land use decisions — Young stated "she agreed with Councilor Scott and emphasized the importance of the public process," said the state''s SB 974 (which would have cut mailed-notice radius from 1,000 feet to 100 feet and barred hearings on Type III applications) "went against Statewide Land Use Goal 1," and said "she was in favor of the proposed Charter amendment." The measure she championed requires at least one neighborhood meeting and one public hearing, plus 1,000-foot mailed notice, before any Type III-or-higher land-use application (which covers larger subdivisions and multifamily projects) can be decided. Insisting on strong neighborhood-meeting and public-hearing requirements as a precondition for higher-density approvals, without opposing such development outright, matches the modest-density-with-strong-neighborhood-input chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf']::text[]),
    ('housing', 3, 'At the May 19, 2026 council meeting, with Young recorded present, the council unanimously authorized the city manager to sell a city-owned 0.98-acre parcel at 22468 S.W. Pacific Hwy to Oaktree Real Estate LLC for $415,000, expressly conditioned on the buyer developing affordable housing on the site and making a good-faith effort to rezone it from office-commercial to high-density residential. Using a city-owned asset as targeted leverage to enable one specific affordable-housing project — rather than directly building public housing, mandating rent caps/inclusionary requirements citywide, or simply deregulating zoning broadly — matches the targeted-help-for-affordable-projects chair.', ARRAY['https://www.sherwoodsun.org/sherwood-city-council-recap-may-19-2026/']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '66ae4909-109b-4c9c-a16c-a2fa74620a8f'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'At the October 28, 2025 special session (attending remotely, per roll call), Council President Young personally moved adoption of Resolution 2025-073 declaring an emergency to refer Charter amendments protecting Sherwood''s home-rule authority against state housing-preemption bills; the minutes record her saying "taking away public participation in land use decisions was counter to Statewide Land Use Goal 1" and that she supported the resolution. She then seconded Resolution 2025-074, which asked voters to enshrine that "annexation may only take effect with the approval of city voters" (barring a public-health emergency) and that this authority "shall not be preempted by state laws." Voters ratified the measure 82.71% in favor on January 13, 2026. Personally introducing and seconding the voter-approval-gate charter amendments matches the require-voter-approval-for-annexations-and-major-development chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf']::text[]),
    ('residential-zoning', 2, 'On Resolution 2025-075 at the same October 28, 2025 session — the Charter measure enshrining citizen involvement in land use decisions — Young stated "she agreed with Councilor Scott and emphasized the importance of the public process," said the state''s SB 974 (which would have cut mailed-notice radius from 1,000 feet to 100 feet and barred hearings on Type III applications) "went against Statewide Land Use Goal 1," and said "she was in favor of the proposed Charter amendment." The measure she championed requires at least one neighborhood meeting and one public hearing, plus 1,000-foot mailed notice, before any Type III-or-higher land-use application (which covers larger subdivisions and multifamily projects) can be decided. Insisting on strong neighborhood-meeting and public-hearing requirements as a precondition for higher-density approvals, without opposing such development outright, matches the modest-density-with-strong-neighborhood-input chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf']::text[]),
    ('housing', 3, 'At the May 19, 2026 council meeting, with Young recorded present, the council unanimously authorized the city manager to sell a city-owned 0.98-acre parcel at 22468 S.W. Pacific Hwy to Oaktree Real Estate LLC for $415,000, expressly conditioned on the buyer developing affordable housing on the site and making a good-faith effort to rezone it from office-commercial to high-density residential. Using a city-owned asset as targeted leverage to enable one specific affordable-housing project — rather than directly building public housing, mandating rent caps/inclusionary requirements citywide, or simply deregulating zoning broadly — matches the targeted-help-for-affordable-projects chair.', ARRAY['https://www.sherwoodsun.org/sherwood-city-council-recap-may-19-2026/']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '66ae4909-109b-4c9c-a16c-a2fa74620a8f'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id — a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = '66ae4909-109b-4c9c-a16c-a2fa74620a8f';
  IF v_ext IS DISTINCT FROM -4167102 THEN
    RAISE EXCEPTION 'UUID 66ae4909-109b-4c9c-a16c-a2fa74620a8f does not belong to external_id -4167102 (Kim Young) — found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = '66ae4909-109b-4c9c-a16c-a2fa74620a8f';
  IF n <> 3 THEN
    RAISE EXCEPTION 'Expected % answers, found % — topic_key mismatch dropped rows', 3, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = '66ae4909-109b-4c9c-a16c-a2fa74620a8f';
  IF n <> 3 THEN
    RAISE EXCEPTION 'Expected % context rows, found % — answers/context VALUES lists diverged', 3, n;
  END IF;
END $$;

COMMIT;
