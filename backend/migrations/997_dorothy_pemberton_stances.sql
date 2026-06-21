-- 997_dorothy_pemberton_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 992)
-- Dorothy Pemberton (D3, ext_id 675360) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
-- Pre-tenure discipline: Pemberton was seated Dec 2023 — she was NOT on the Jan 2021 rent-control vote.
--   Her rent-regulation stance is scored from her OWN 2024 candidate Q&A only (A5 rule).
-- THIN RECORD (seated Dec 2023): Many honest blanks expected and preserved — only 4 stances documented.
-- NO judicial-* topics — Downey has an appointed City Attorney (council-manager form).
-- Phase 150 Wave 4 (DWNY-01). On-disk counter stays 992; this file is AUDIT-ONLY.
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 675360),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('rent-regulation', 4::numeric, $stz$Pemberton opposes additional rent caps, stating in her 2024 re-election Q&A: "Expenses for owners are not going down just like all other costs for the general public." She favors supply-side solutions such as ADUs (accessory dwelling units) over rent control to address affordability. She was not on the council for the January 2021 vote (seated December 2023).$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2024/10/making-downey-a-destination$stz$]::text[]),
  ('public-safety-approach', 4::numeric, $stz$Pemberton states "Public safety is a top priority" and explicitly does not support cuts to the police budget. She supports the current police budget pending review, framing public safety as a primary city responsibility.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2024/10/making-downey-a-destination$stz$]::text[]),
  ('homelessness-response', 3::numeric, $stz$Pemberton supports outreach services and programs for people experiencing homelessness but explicitly opposes developing homeless housing facilities in Downey — a middle position that funds services/outreach while resisting permanent local homeless housing development.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2024/10/making-downey-a-destination$stz$]::text[]),
  ('local-immigration', 1::numeric, $stz$Pemberton co-voted in 2025 for the special Downey City Council meeting on ICE immigration raids and the $25,000 allocation to assist families impacted by the raids — aligning with the immigrant-protection majority on the council.$stz$, ARRAY[$stz$https://calonews.com/downey-residents-demand-action$stz$]::text[])
),
ans AS (
 INSERT INTO inform.politician_answers (politician_id, topic_id, value)
 SELECT pol.id, t.id, d.val
 FROM d JOIN inform.compass_topics t ON t.topic_key=d.topic_key AND t.is_live=true CROSS JOIN pol
 ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value
 RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, t.id, d.reasoning, d.sources
FROM d JOIN inform.compass_topics t ON t.topic_key=d.topic_key AND t.is_live=true CROSS JOIN pol
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
COMMIT;
