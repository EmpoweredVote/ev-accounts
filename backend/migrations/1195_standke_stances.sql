-- Migration 1195: Dan Standke (Councilor, Sherwood OR) compass stances — AUDIT-ONLY (not registered in the ledger)
-- Evidence-only; 100% cited; chairs model (value 1-5); 2 cited stances; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live=true (no hardcoded topic UUIDs).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'Standke was present at the October 28, 2025 special council session and voted with the rest of the council 7:0 to adopt Charter-amendment Resolutions 2025-073, -074, and -075. On Resolution 2025-073 (declaring an emergency to call the special election), the minutes record him saying the matter "rose to an emergency when the public engagement was being limited for land use cases." On Resolution 2025-074, which asks voters to write into the Charter that "annexation may only take effect with the approval of city voters" and that this authority "shall not be preempted by state laws," Standke stated the language "reinforced the city''s support for voter approved annexations." On Resolution 2025-075, which bars any Type III or higher land-use application from being decided without at least one noticed neighborhood meeting and one public hearing, he said "public participation was essential for us to function as a city," adding he was "shocked that Salem would limit public participation" and that he supported the resolution. Voters subsequently passed both charter measures in the January 13, 2026 special election. Standke''s own votes and floor comments backing a voter-approval requirement for annexations plus mandatory public hearings before larger developments match the growth-limits/voter-approval-gate chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf', 'https://www.opb.org/article/2026/01/03/sherwood-vote-challenge-oregon-housing-laws/']::text[]),
    ('local-immigration', 3, 'In council announcements at the February 17, 2026 meeting, Standke was the only official to address Governor Kotek''s February 5 letter to Homeland Security (co-signed by 31 mayors) calling to halt federal immigration enforcement actions in Oregon. He told residents "Their messages were thoughtful and heartfelt, and they reflect a deep concern for the safety and well-being in our community," and defended Oregon''s existing sanctuary framework rather than calling for it to be strengthened or rolled back: "Sanctuary protections do not give anyone a free pass on crime," he said, explaining the law exists so that "federal immigration enforcement remains federal while local officers stay focused on keeping neighborhoods safe" and "to preserve the trust between communities and local law enforcement." Two weeks earlier, at the February 3, 2026 meeting, he told council "our community deserved to know that constitutional protections apply to all people of Sherwood, citizens and non-citizens alike." His framing — city police stay out of proactive federal immigration enforcement and remain focused on local public safety, with federal agencies handling federal enforcement, and no call for either refusing court-ordered cooperation or assisting ICE — matches the follow-federal-law-without-proactive-local-enforcement chair.', ARRAY['https://www.sherwoodsun.org/sherwood-city-council-recap-feb-17-2026/', 'https://www.sherwoodoregon.gov/wp-content/uploads/2026/02/02.03.2026-City-Council-Meeting-Mintues.pdf']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2a58cc49-bef8-4800-a092-4a33e77330fc'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'Standke was present at the October 28, 2025 special council session and voted with the rest of the council 7:0 to adopt Charter-amendment Resolutions 2025-073, -074, and -075. On Resolution 2025-073 (declaring an emergency to call the special election), the minutes record him saying the matter "rose to an emergency when the public engagement was being limited for land use cases." On Resolution 2025-074, which asks voters to write into the Charter that "annexation may only take effect with the approval of city voters" and that this authority "shall not be preempted by state laws," Standke stated the language "reinforced the city''s support for voter approved annexations." On Resolution 2025-075, which bars any Type III or higher land-use application from being decided without at least one noticed neighborhood meeting and one public hearing, he said "public participation was essential for us to function as a city," adding he was "shocked that Salem would limit public participation" and that he supported the resolution. Voters subsequently passed both charter measures in the January 13, 2026 special election. Standke''s own votes and floor comments backing a voter-approval requirement for annexations plus mandatory public hearings before larger developments match the growth-limits/voter-approval-gate chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf', 'https://www.opb.org/article/2026/01/03/sherwood-vote-challenge-oregon-housing-laws/']::text[]),
    ('local-immigration', 3, 'In council announcements at the February 17, 2026 meeting, Standke was the only official to address Governor Kotek''s February 5 letter to Homeland Security (co-signed by 31 mayors) calling to halt federal immigration enforcement actions in Oregon. He told residents "Their messages were thoughtful and heartfelt, and they reflect a deep concern for the safety and well-being in our community," and defended Oregon''s existing sanctuary framework rather than calling for it to be strengthened or rolled back: "Sanctuary protections do not give anyone a free pass on crime," he said, explaining the law exists so that "federal immigration enforcement remains federal while local officers stay focused on keeping neighborhoods safe" and "to preserve the trust between communities and local law enforcement." Two weeks earlier, at the February 3, 2026 meeting, he told council "our community deserved to know that constitutional protections apply to all people of Sherwood, citizens and non-citizens alike." His framing — city police stay out of proactive federal immigration enforcement and remain focused on local public safety, with federal agencies handling federal enforcement, and no call for either refusing court-ordered cooperation or assisting ICE — matches the follow-federal-law-without-proactive-local-enforcement chair.', ARRAY['https://www.sherwoodsun.org/sherwood-city-council-recap-feb-17-2026/', 'https://www.sherwoodoregon.gov/wp-content/uploads/2026/02/02.03.2026-City-Council-Meeting-Mintues.pdf']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2a58cc49-bef8-4800-a092-4a33e77330fc'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id — a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = '2a58cc49-bef8-4800-a092-4a33e77330fc';
  IF v_ext IS DISTINCT FROM -4167107 THEN
    RAISE EXCEPTION 'UUID 2a58cc49-bef8-4800-a092-4a33e77330fc does not belong to external_id -4167107 (Dan Standke) — found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = '2a58cc49-bef8-4800-a092-4a33e77330fc';
  IF n <> 2 THEN
    RAISE EXCEPTION 'Expected % answers, found % — topic_key mismatch dropped rows', 2, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = '2a58cc49-bef8-4800-a092-4a33e77330fc';
  IF n <> 2 THEN
    RAISE EXCEPTION 'Expected % context rows, found % — answers/context VALUES lists diverged', 2, n;
  END IF;
END $$;

COMMIT;
