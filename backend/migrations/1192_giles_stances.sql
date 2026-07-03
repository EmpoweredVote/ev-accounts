-- Migration 1192: Taylor Giles (Councilor, Sherwood OR) compass stances — AUDIT-ONLY (not registered in the ledger)
-- Evidence-only; 100% cited; chairs model (value 1-5); 2 cited stances; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live=true (no hardcoded topic UUIDs).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'Giles was present in person at the October 28, 2025 special session and voted with the council 7:0 to adopt Resolution 2025-073 declaring an emergency and calling the January 2026 special election on home-rule Charter amendments, after stating he "understood the state''s approach to creating more affordable housing" but that "public input was important and does not slow down development," and "stated he supported the resolution." He also voted for and personally seconded Resolution 2025-075, which wrote into the Charter a requirement that no Type III-or-higher land-use application be decided "without at least one duly noticed neighborhood meeting and one public hearing," telling colleagues "he wanted more housing, to grow responsibly, and to be treated as a partner with the state legislature" while warning that SB 974''s limits on public input "could result in buildings that do not help the city grow." He additionally voted for Resolution 2025-074, amending the Charter so "annexation may only take effect with the approval of city voters" and that these procedures "shall not be preempted by state laws." Voters ratified both Charter measures in January 2026. Unlike colleagues who framed the vote in confrontational anti-Salem terms, Giles cast the same votes while explicitly favoring more housing production — but the concrete policy he voted for, and personally seconded, is a voter-approval gate on annexation paired with a mandatory public-hearing gate on major development, matching the growth-limits/voter-approval chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf', 'https://www.opb.org/article/2026/01/18/sherwood-votes-overwhelmingly-to-challenge-new-state-housing-laws/']::text[]),
    ('residential-zoning', 2, 'At the same October 28, 2025 hearing, Giles''s own stated reasoning centered on wanting more housing built while preserving neighborhood input: he "said he wanted more housing, to grow responsibly, and to be treated as a partner with the state legislature," stated "builders want to build nice affordable homes," and warned that SB 974''s cut to mailed notice (from 1,000 feet down to 100 feet) and removal of hearings for Type III-and-under applications "could result in buildings that do not help the city grow." He then personally seconded Resolution 2025-075, which locked into the Charter a requirement for "at least one duly noticed neighborhood meeting and one public hearing" before any Type III-or-higher land-use decision, plus mailed notice to owners within 1,000 feet for Type II-or-higher applications. Pairing an explicit desire for more housing construction with insistence on neighborhood-meeting and public-hearing review before significant development matches the modest-growth-with-strong-neighborhood-input chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '6427eeca-2e13-4bf8-af28-45e6d1e373ea'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'Giles was present in person at the October 28, 2025 special session and voted with the council 7:0 to adopt Resolution 2025-073 declaring an emergency and calling the January 2026 special election on home-rule Charter amendments, after stating he "understood the state''s approach to creating more affordable housing" but that "public input was important and does not slow down development," and "stated he supported the resolution." He also voted for and personally seconded Resolution 2025-075, which wrote into the Charter a requirement that no Type III-or-higher land-use application be decided "without at least one duly noticed neighborhood meeting and one public hearing," telling colleagues "he wanted more housing, to grow responsibly, and to be treated as a partner with the state legislature" while warning that SB 974''s limits on public input "could result in buildings that do not help the city grow." He additionally voted for Resolution 2025-074, amending the Charter so "annexation may only take effect with the approval of city voters" and that these procedures "shall not be preempted by state laws." Voters ratified both Charter measures in January 2026. Unlike colleagues who framed the vote in confrontational anti-Salem terms, Giles cast the same votes while explicitly favoring more housing production — but the concrete policy he voted for, and personally seconded, is a voter-approval gate on annexation paired with a mandatory public-hearing gate on major development, matching the growth-limits/voter-approval chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf', 'https://www.opb.org/article/2026/01/18/sherwood-votes-overwhelmingly-to-challenge-new-state-housing-laws/']::text[]),
    ('residential-zoning', 2, 'At the same October 28, 2025 hearing, Giles''s own stated reasoning centered on wanting more housing built while preserving neighborhood input: he "said he wanted more housing, to grow responsibly, and to be treated as a partner with the state legislature," stated "builders want to build nice affordable homes," and warned that SB 974''s cut to mailed notice (from 1,000 feet down to 100 feet) and removal of hearings for Type III-and-under applications "could result in buildings that do not help the city grow." He then personally seconded Resolution 2025-075, which locked into the Charter a requirement for "at least one duly noticed neighborhood meeting and one public hearing" before any Type III-or-higher land-use decision, plus mailed notice to owners within 1,000 feet for Type II-or-higher applications. Pairing an explicit desire for more housing construction with insistence on neighborhood-meeting and public-hearing review before significant development matches the modest-growth-with-strong-neighborhood-input chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '6427eeca-2e13-4bf8-af28-45e6d1e373ea'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id — a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = '6427eeca-2e13-4bf8-af28-45e6d1e373ea';
  IF v_ext IS DISTINCT FROM -4167104 THEN
    RAISE EXCEPTION 'UUID 6427eeca-2e13-4bf8-af28-45e6d1e373ea does not belong to external_id -4167104 (Taylor Giles) — found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = '6427eeca-2e13-4bf8-af28-45e6d1e373ea';
  IF n <> 2 THEN
    RAISE EXCEPTION 'Expected % answers, found % — topic_key mismatch dropped rows', 2, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = '6427eeca-2e13-4bf8-af28-45e6d1e373ea';
  IF n <> 2 THEN
    RAISE EXCEPTION 'Expected % context rows, found % — answers/context VALUES lists diverged', 2, n;
  END IF;
END $$;

COMMIT;
