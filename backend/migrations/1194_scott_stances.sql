-- Migration 1194: Doug Scott (Councilor, Sherwood OR) compass stances — AUDIT-ONLY (not registered in the ledger)
-- Evidence-only; 100% cited; chairs model (value 1-5); 3 cited stances; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live=true (no hardcoded topic UUIDs).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'Scott attended the October 28, 2025 special session and seconded Resolution 2025-073 (declaring an emergency to call a special election on Charter amendments) and moved adoption of Resolution 2025-075 (citizen involvement in land-use decisions), both passing 7:0 with his vote; on the annexation measure he pressed staff on whether "the intent was to require future annexations to go before the voters." On 2025-075 he was the most forceful voice in the room, saying the legislators in Salem and the Governor "should be ashamed of themselves" and that SB 974 was "unrepresentative and despicable," that the idea limiting public engagement served the public interest was "absurd," and that he was "embarrassed to be an Oregonian," concluding Sherwood "needed to take it back" and that he supported the Charter amendment language. Voters ratified the resulting measures — which write into the Charter that annexation requires voter approval and that Type III-or-higher land-use decisions require a neighborhood meeting and public hearing — in January 2026. This is consistent with his September 19, 2023 comment on the Sherwood West UGB-expansion letter of interest that "clear annexation rules were something that needed to be in place before the city submitted their UGB expansion request application," matching the growth-limits/voter-approval-required chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf', 'https://www.sherwoodoregon.gov/wp-content/uploads/2025/10/09.19.2023_council_meeting_packet_-_amended.pdf']::text[]),
    ('housing', 3, 'At the May 19, 2026 council meeting Scott voted to authorize selling a city-owned 0.98-acre parcel at 22468 SW Pacific Hwy to a private developer specifically to produce affordable housing, saying "I''m in support of this... It sounds like, based on everything we understand, that the buyer is fully intending to meet the 120% or 60% AMI requirements to build housing that is affordable to more people," and that while "six or 11 units is not a massive amount... it is a chip away at the number we need to get to." The deal he endorsed conditioned the sale (and an accompanying zoning change) on income-restricted units — 120% AMI for-sale or 60% AMI rental, the latter eligible for the federal Low Income Housing Tax Credit program — rather than direct city-built public housing or blanket deregulation, a targeted, project-specific affordability tool matching the targeted-help chair.', ARRAY['https://www.sherwoodsun.org/sherwood-city-council-recap-may-19-2026/']::text[]),
    ('economic-development', 2, 'Discussing the Old Town Strategic Plan, Councilor Scott said he was "on board with some of it so far, and sees value in the permit fee relief and alley activation," framing the plan as "strategic and trying to move the Old Town forward in what eventually becomes a transformative way," and singling out "bringing in new businesses and alley activation" as the most transformative pieces of the plan. Reduced permitting costs and placemaking investment aimed at existing small businesses in Sherwood''s historic Old Town core, rather than large-employer tax abatements or major incentive packages, matches the small-business/local-entrepreneur-support chair. Attendance note: the Feb 17 2026 session was split -- official minutes show Scott present (remote) at the work session where this Old Town discussion occurred, and absent from the same evening''s regular meeting; the Sherwood Sun recap conflated the two.', ARRAY['https://www.sherwoodsun.org/sherwood-city-council-recap-feb-17-2026/']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8bf23d4d-d3e2-4cbd-99ff-863fb80f7ae4'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'Scott attended the October 28, 2025 special session and seconded Resolution 2025-073 (declaring an emergency to call a special election on Charter amendments) and moved adoption of Resolution 2025-075 (citizen involvement in land-use decisions), both passing 7:0 with his vote; on the annexation measure he pressed staff on whether "the intent was to require future annexations to go before the voters." On 2025-075 he was the most forceful voice in the room, saying the legislators in Salem and the Governor "should be ashamed of themselves" and that SB 974 was "unrepresentative and despicable," that the idea limiting public engagement served the public interest was "absurd," and that he was "embarrassed to be an Oregonian," concluding Sherwood "needed to take it back" and that he supported the Charter amendment language. Voters ratified the resulting measures — which write into the Charter that annexation requires voter approval and that Type III-or-higher land-use decisions require a neighborhood meeting and public hearing — in January 2026. This is consistent with his September 19, 2023 comment on the Sherwood West UGB-expansion letter of interest that "clear annexation rules were something that needed to be in place before the city submitted their UGB expansion request application," matching the growth-limits/voter-approval-required chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf', 'https://www.sherwoodoregon.gov/wp-content/uploads/2025/10/09.19.2023_council_meeting_packet_-_amended.pdf']::text[]),
    ('housing', 3, 'At the May 19, 2026 council meeting Scott voted to authorize selling a city-owned 0.98-acre parcel at 22468 SW Pacific Hwy to a private developer specifically to produce affordable housing, saying "I''m in support of this... It sounds like, based on everything we understand, that the buyer is fully intending to meet the 120% or 60% AMI requirements to build housing that is affordable to more people," and that while "six or 11 units is not a massive amount... it is a chip away at the number we need to get to." The deal he endorsed conditioned the sale (and an accompanying zoning change) on income-restricted units — 120% AMI for-sale or 60% AMI rental, the latter eligible for the federal Low Income Housing Tax Credit program — rather than direct city-built public housing or blanket deregulation, a targeted, project-specific affordability tool matching the targeted-help chair.', ARRAY['https://www.sherwoodsun.org/sherwood-city-council-recap-may-19-2026/']::text[]),
    ('economic-development', 2, 'Discussing the Old Town Strategic Plan, Councilor Scott said he was "on board with some of it so far, and sees value in the permit fee relief and alley activation," framing the plan as "strategic and trying to move the Old Town forward in what eventually becomes a transformative way," and singling out "bringing in new businesses and alley activation" as the most transformative pieces of the plan. Reduced permitting costs and placemaking investment aimed at existing small businesses in Sherwood''s historic Old Town core, rather than large-employer tax abatements or major incentive packages, matches the small-business/local-entrepreneur-support chair. Attendance note: the Feb 17 2026 session was split -- official minutes show Scott present (remote) at the work session where this Old Town discussion occurred, and absent from the same evening''s regular meeting; the Sherwood Sun recap conflated the two.', ARRAY['https://www.sherwoodsun.org/sherwood-city-council-recap-feb-17-2026/']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8bf23d4d-d3e2-4cbd-99ff-863fb80f7ae4'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id — a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = '8bf23d4d-d3e2-4cbd-99ff-863fb80f7ae4';
  IF v_ext IS DISTINCT FROM -4167106 THEN
    RAISE EXCEPTION 'UUID 8bf23d4d-d3e2-4cbd-99ff-863fb80f7ae4 does not belong to external_id -4167106 (Doug Scott) — found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = '8bf23d4d-d3e2-4cbd-99ff-863fb80f7ae4';
  IF n <> 3 THEN
    RAISE EXCEPTION 'Expected % answers, found % — topic_key mismatch dropped rows', 3, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = '8bf23d4d-d3e2-4cbd-99ff-863fb80f7ae4';
  IF n <> 3 THEN
    RAISE EXCEPTION 'Expected % context rows, found % — answers/context VALUES lists diverged', 3, n;
  END IF;
END $$;

COMMIT;
