-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H1 (4 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H1.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Quang H Nguyen (State House District 1) / local-immigration = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9cc152b6-c83b-4501-9e1a-2ab50e1db6a7', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9cc152b6-c83b-4501-9e1a-2ab50e1db6a7', ct.id, $ctx$Nguyen (R-Prescott, HD-1) filed a formal complaint with AZ AG Kris Mayes in April 2026 arguing Phoenix's Community Transparency Initiative illegally lets a city manager gatekeep federal immigration enforcement, and that state law bars cities from restricting enforcement 'to less than the full extent permitted by federal law.' His position is that cities must not obstruct or condition ICE/federal enforcement activity, aligning with stance 4 (honor detainers, no local restriction) rather than 5 (no evidence he called for city police to actively assist beyond non-obstruction).$ctx$,
       ARRAY['https://azmirror.com/briefs/phoenix-says-its-ice-policy-is-legal-a-gop-lawmaker-wants-kris-mayes-to-decide/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Wilmeth (State House District 2) / abortion = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '729d1a1e-b58f-4a33-bf18-a0f11e3c5e04', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '729d1a1e-b58f-4a33-bf18-a0f11e3c5e04', ct.id, $ctx$Wilmeth (R-Phoenix, HD-2) was one of only three House Republicans who voted with Democrats on April 24, 2024 (HB2677, 32-28) to repeal Arizona's 1864 near-total abortion ban, restoring the state to its existing 15-week law (elective abortion permitted through roughly the first trimester/early second trimester, with an exception structure rather than a full ban). This individual roll-call vote rules out stance 5 (total ban) and points to the more permissive first-trimester-plus-exceptions framework of stance 3; no personal Wilmeth quote on his reasoning was found, so this is scored from the record.$ctx$,
       ARRAY['https://azmirror.com/2024/04/24/az-house-has-voted-to-repeal-the-1864-abortion-ban-upheld-by-the-supreme-court/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Wilmeth (State House District 2) / ai-regulation = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '729d1a1e-b58f-4a33-bf18-a0f11e3c5e04', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'ai-regulation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '729d1a1e-b58f-4a33-bf18-a0f11e3c5e04', ct.id, $ctx$As chairman of the newly formed House Committee on Artificial Intelligence and Innovation (Jan 2026), Wilmeth told reporters Arizona will stay 'innovation friendly' and that 'no one should expect major regulations,' while pushing back on federal AI standards being dictated from Washington. This reflects a light-touch, let-industry-lead posture rather than mandatory testing or approval requirements, matching stance 2.$ctx$,
       ARRAY['https://azmirror.com/briefs/gop-led-committee-vows-arizona-will-remain-innovation-friendly-on-ai-regulation/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'ai-regulation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alexander Kolodin (State House District 3) / voting-rights = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '178470c3-94ea-442a-a558-7b3c841ce858', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '178470c3-94ea-442a-a558-7b3c841ce858', ct.id, $ctx$Kolodin (R-Scottsdale, HD-3), an Elections Committee member, is lead sponsor of HCR2001 'Arizona Secure Elections Act' (House-passed Feb 2026), which requires photo ID concurrent with casting a ballot, mandates voters re-confirm their address each cycle or be dropped from the early voter list, and cuts off Election Day ballot drop-off at 7pm the preceding Friday. This is a voter-ID-plus-roll-maintenance approach rather than full elimination of mail voting, matching stance 4.$ctx$,
       ARRAY['https://azmirror.com/2026/02/09/arizona-house-approves-resolution-ending-election-day-ballot-drop-offs/', 'https://azmirror.com/2025/11/24/gop-pushes-constitutional-amendment-to-restrict-arizona-early-voting/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
