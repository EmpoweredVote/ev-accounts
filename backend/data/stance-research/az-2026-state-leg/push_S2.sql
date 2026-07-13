-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch S2 (5 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-S2.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Wendy Rogers (State Senate District 7) / voting-rights = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '23b7d096-37ad-4b00-8291-c7f0640a22d2', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '23b7d096-37ad-4b00-8291-c7f0640a22d2', ct.id, $ctx$In May 2024, Sen. Rogers authored HCR2056, a 19-page ballot resolution that would eliminate Election Day polling-place ballot drop-off, restrict early ballot drop-off to designated sites until 7 p.m. the Friday before Election Day, and require photo ID from anyone dropping off an early ballot. She framed the measure as prioritizing election security and trust over voting convenience. This tightened-ID/reduced-convenience approach (without eliminating mail voting outright) matches stance 4 rather than stance 5.$ctx$,
       ARRAY['https://azmirror.com/2024/05/16/republicans-take-aim-at-the-convenience-of-voting-with-sweeping-election-reform-ballot-measure/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wendy Rogers (State Senate District 7) / immigration = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '23b7d096-37ad-4b00-8291-c7f0640a22d2', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '23b7d096-37ad-4b00-8291-c7f0640a22d2', ct.id, $ctx$Rogers has repeatedly and personally promoted 'great replacement' rhetoric, framing mass immigration (not merely illegal border crossing) as a deliberate strategy by 'communists & our enemies' to replace the existing population, and posted 'we are being replaced and invaded' and 'MAKE WESTERN CIVILIZATION GREAT AGAIN' in July 2021 when challenged on the rhetoric. This sustained personal framing of immigration itself as an existential threat is the most hardline position on the scale and places her at stance 5. No specific immigration bill/vote of hers was found, so this row rests on her own public statements rather than a roll call.$ctx$,
       ARRAY['https://azmirror.com/2021/07/20/gop-sen-wendy-rogers-defends-her-promotion-of-racist-great-replacement-ideology/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David C. Farnsworth (State Senate District 10) / abortion = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '7ab7c163-bfac-4a95-8b94-22d1a4395522', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '7ab7c163-bfac-4a95-8b94-22d1a4395522', ct.id, $ctx$During the May 1, 2024 Senate floor debate on HB2677 (repeal of Arizona's 1864 near-total abortion ban, whose only exception is a life-threatening emergency for the mother, with no rape or incest exception), Sen. Farnsworth spoke against repeal and urged voters to hold accountable the two Republicans who crossed over to support it. His opposition to repealing a law that permits abortion only to save the mother's life places him at stance 4 (restrict to only life-threat/rape/incest cases) rather than stance 5, since the 1864 law he sought to preserve does carry a life-of-the-mother exception and does not criminalize patients.$ctx$,
       ARRAY['https://azmirror.com/2024/05/01/the-az-senate-has-repealed-the-1864-abortion-ban-after-2-republicans-join-dems/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Kuby (State Senate District 8) / taxes = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '68308cfb-52ff-4a9c-8363-9a582ea9a989', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '68308cfb-52ff-4a9c-8363-9a582ea9a989', ct.id, $ctx$As a Tempe councilmember in June 2021 (before her 2025 Senate service began), Kuby wrote in an Arizona Mirror op-ed that Arizona's congressional delegation should help 'raise the corporate tax rate' as part of federal infrastructure legislation, criticizing Senate Republicans for protecting 'corporate donors' from 'paying their fair share.' This documents a personal position favoring a moderate corporate tax increase (the Biden administration's proposed 21%-to-28% hike, not a drastic restructuring), aligning with stance 2. No 2025-2026 AZ Senate tax vote of hers was found, so this pre-Senate but personally authored op-ed is used.$ctx$,
       ARRAY['https://azmirror.com/2021/06/24/corporations-must-pay-their-fair-share-if-we-want-a-21st-century-infrastructure/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Kuby (State Senate District 8) / climate-change = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '68308cfb-52ff-4a9c-8363-9a582ea9a989', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '68308cfb-52ff-4a9c-8363-9a582ea9a989', ct.id, $ctx$In a March 2021 Arizona Mirror op-ed, Kuby (then a Tempe councilmember) called on Arizona's congressional delegation to help reinstate federal clean-car emissions standards and invest in zero-emissions vehicles, citing Tempe's transportation-sector emissions and Maricopa County's poor air-quality grade. This reflects a gradual clean-energy-investment approach rather than a mandated rapid fossil-fuel phase-out or emergency declaration, aligning with stance 3. No 2025-2026 AZ Senate-specific climate vote of hers was found, so this pre-Senate op-ed is the most definitive personal statement available.$ctx$,
       ARRAY['https://azmirror.com/2021/03/09/its-past-time-for-cleaner-cars-on-arizona-roadways/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
