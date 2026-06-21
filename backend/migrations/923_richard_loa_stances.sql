-- 923_richard_loa_stances.sql — Phase 146 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Evidence-only compass stances for Richard J. Loa (external_id 692504, Palmdale D2).
-- Chairs model; 100% citation; honest blanks. NO judicial topics (D-13). Apply via raw SQL; ledger stays 919.
-- NOTE: Loa was removed from the ceremonial Mayor title in July 2025 but remains a seated D2 councilmember.
-- That governance/personnel episode was deliberately NOT converted into any stance (no citable policy
-- position embedded in it). His homelessness statements were about jurisdictional/funding equity (LA County),
-- NOT the enforcement-vs-services axis, so homelessness is an honest blank.
BEGIN;

-- taxes = 4 (self-described fiscal conservative; "fight attempts to raise taxes")
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 4 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=692504 AND t.topic_key='taxes' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$On his campaign Issues & Policy page, Loa self-identifies as a "fiscal conservative" who will "protect taxpayer dollars and fight attempts to raise taxes." Explicit opposition to tax increases with emphasis on spending restraint best matches chair 4 (cut/oppose new taxes) rather than chair 3 (keep current/close loopholes).$$,
ARRAY['https://www.richardloa.com/issues-policy']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=692504 AND t.topic_key='taxes' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- economic-development = 4 (responsible development; Amazon/Sprouts; aerospace partnerships; public-private partnerships)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 4 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=692504 AND t.topic_key='economic-development' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$Loa's platform touts support for "responsible development in Palmdale, including the new Sprouts market, Amazon fulfillment center" and "public-private partnerships to invigorate our local economy," plus partnership with local aerospace manufacturers to build a homegrown workforce. Actively recruiting and partnering with major employers aligns with chair 4 (compete for major employers) more than the community-benefit-conditioned chair 3.$$,
ARRAY['https://www.richardloa.com/issues-policy','https://www.richardloa.com/']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=692504 AND t.topic_key='economic-development' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- public-safety-approach = 4 (supports law enforcement w/ accountability; ensure public safety has necessary resources)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 4 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=692504 AND t.topic_key='public-safety-approach' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$Loa's platform states he "supports local law enforcement while also holding them accountable" and emphasizes "ensuring that public safety has the necessary resources to keep our families safe." A stated priority of funding/resourcing police (with an accountability caveat, not reallocation) best fits chair 4 (increase/ensure police resources). He does not propose redirecting police budget (not 1-2) and the accountability language is oversight rather than a crisis-team/co-responder program (short of chair 3).$$,
ARRAY['https://www.richardloa.com/issues-policy']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=692504 AND t.topic_key='public-safety-approach' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;
