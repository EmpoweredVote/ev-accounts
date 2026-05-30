-- Migration 121: Marissa Roy judicial compass stances
-- politician_id: 7157dd95-0f1b-4e05-bd4f-39317345b47c
-- Researched: 2026-05-09
-- Sources: Patch Q&A, LAist voter guide, AOL/LA Times syndicated, LA Forward voter guide,
--          SPNA DTLA article, marissaroy.com
-- 5 of 6 applicable topics have placed stances; judicial-transparency is "not found"

BEGIN;

-- ============================================================
-- Section A: politician_answers for 5 placed stances
-- (judicial-transparency has no public-record evidence — context-only in Section C)
-- ============================================================

-- judicial-prosecution-priorities (value=2: use diversion when available and makes sense;
-- reserve prosecution for when community safety actually requires it)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', 'abb99d95-cbb1-4617-8f8b-f220ef6028ca', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-criminal-justice (value=2: giving the person a fair chance through treatment,
-- community service, or restitution; break cycles of criminalization)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-police-accountability (value=2: settle valid claims quickly and pursue real
-- accountability; defending misconduct wastes money and public trust)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', '7bad33eb-e93e-4d94-8822-97212d49bde5', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-access-to-justice (value=1: courts exist for everyone — not just people with
-- expensive lawyers; public interest law firm vision for workers, tenants, consumers)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', '9d45acaf-1ba4-4cb8-95e1-5ed985223b91', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-government-deference (value=1: the citizen, almost always; "serves the people,
-- not the powerful"; career representing workers/tenants/consumers against institutions)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7157dd95-0f1b-4e05-bd4f-39317345b47c', 'e5e48f0e-8f3a-40e1-8080-889fea389603', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- ============================================================
-- Section B: politician_context (reasoning + sources) for 5 placed stances
-- ============================================================

-- judicial-prosecution-priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7157dd95-0f1b-4e05-bd4f-39317345b47c',
  'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
  'Roy''s prosecution framework centers on diversion as the primary response to nonviolent misdemeanors, with prosecution reserved for cases that genuinely require it. Her Patch Q&A states: "Diversion is a tailored, court-supervised program that connects people with the services they need to address that cause, such as behavioral health treatment, addiction support and counseling. Data has shown that when nonviolent misdemeanors are addressed with diversion, rather than incarceration, people are dramatically less likely to reoffend." She describes her philosophy as "develop tools like diversion that are shown to work, collaborate with communities to develop sustainable, neighborhood-centered solutions, and work to permanently break cycles of criminalization." The AOL/LA Times piece quotes her directly: Roy "has promised to place a heavy emphasis on the legal process known as diversion… In cases involving nonviolent crimes, diversion is more likely than jail to keep people from becoming repeat offenders. ''It makes not only the person whole, but the community safer.''" At the same time, Roy does not call for abandoning prosecution entirely — her LAist candidate survey states she would use "the office''s misdemeanor authority to prosecute ICE agents," and her Patch Q&A notes "That does not mean freezing misdemeanor prosecution — it means right-sizing and tailoring our approach based on what will most effectively serve public safety." This is precisely value 2: use diversion when available and appropriate; reserve prosecution for when community safety actually requires it.',
  ARRAY[
    'https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney',
    'https://www.aol.com/news/guide-l-city-attorneys-race-100000010.html',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-criminal-justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7157dd95-0f1b-4e05-bd4f-39317345b47c',
  '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
  'Roy''s criminal justice philosophy is organized around breaking cycles of criminalization through evidence-based alternatives to incarceration. Her Patch Q&A states: "I want to pursue strategies that actually make our communities safer — one key goal is reducing recidivism, or the rate of reoffending. When we structure a public safety approach that breaks cycles of criminalization, we are preventing crime and making everyone safer." She explicitly describes diversion as connecting people to "behavioral health treatment, addiction support and counseling." Her LAist candidate survey states: "I would work to restore and scale up diversion programs, so we can use all of the tools in our toolbox to address public safety." Her campaign website frames the goal as "strategies that break cycles of criminalization, and make everyone in our communities safer." This maps to value 2: giving the person a fair chance to make things right through treatment, community service, or restitution. She is not at value 1 (pure rehabilitation focus) because she consistently frames outcomes in terms of community safety and explicitly maintains prosecution for cases requiring it — the goal is community safety through treatment, not rehabilitation as an end in itself.',
  ARRAY[
    'https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://www.laforward.org/voterguide'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-police-accountability
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7157dd95-0f1b-4e05-bd4f-39317345b47c',
  '7bad33eb-e93e-4d94-8822-97212d49bde5',
  'Roy''s approach to police misconduct liability combines accountability with smart settlement practice. The SPNA DTLA article identifies as a key platform element: "Critical of Incumbent: Her platform argues the current administration has spent too much on ''liability payouts'' and has been overly aggressive in suing journalists and protesters." Her Patch Q&A states regarding legal liability: "For more long-term solutions, I''d work to bring departments in compliance with the law so that we prevent lawsuits before they occur" — framing LAPD compliance as a priority for reducing costs through accountability. The AOL/LA Times piece quotes her vowing "to put a particular focus on the Los Angeles Police Department, making sure it follows through on the recommendations drafted in the wake of costly litigation." Her proposed liability audit by City Controller Kenneth Mejia would scrutinize the office''s existing settlement and defense practices for police-related cases. The LA Forward voter guide describes Roy as committed to "holding abusive police accountable" and contrasts her with the incumbent''s posture of defending city departments against misconduct lawsuits. Roy''s position — settle valid claims, make LAPD follow through on recommendations, audit existing practices — maps to value 2: settle valid claims quickly and pursue real accountability; defending misconduct wastes money and public trust. She does not reach value 1 (independent investigation against officials) because her emphasis is on smart liability management that produces accountability as a byproduct, not on the office acting as an independent police watchdog.',
  ARRAY[
    'https://www.spna-dtla.org/blog/la-city-attorney-race-4-candidates-their-views',
    'https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney',
    'https://www.aol.com/news/guide-l-city-attorneys-race-100000010.html',
    'https://www.laforward.org/voterguide'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-access-to-justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7157dd95-0f1b-4e05-bd4f-39317345b47c',
  '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
  'Inferred from career pattern and platform framing — no single explicit quote addresses court access barriers, but the consistent pattern is unambiguous. Roy''s entire campaign vision is built on eliminating barriers to legal access for workers, tenants, immigrants, and consumers who currently lack it. Her core platform commitment — stated consistently across all sources — is to make the City Attorney''s Office "the largest public interest law firm in Los Angeles" (LAist, Patch, marissaroy.com). Her specific programmatic proposals are all access-maximizing: a dedicated "Tenants'' Rights Team" to fight abusive landlords (SPNA), expanded wage theft investigation staffing, and using the office to pursue "workers, tenants, climate, civil rights" as top priorities (LAist). Her Patch Q&A describes bringing wage theft cases that "put thousands of dollars back in workers'' pockets" — using government legal resources as a vehicle for those who could not otherwise afford representation against corporate defendants. Her career background — staff attorney at the Public Rights Project, consumer protection work at the California AG''s office suing tech companies — embodies the value 1 framing: courts and legal resources exist for everyone, not just people with expensive lawyers. Low barriers mean more access to justice.',
  ARRAY[
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney',
    'https://www.laforward.org/voterguide',
    'https://www.marissaroy.com/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-government-deference
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7157dd95-0f1b-4e05-bd4f-39317345b47c',
  'e5e48f0e-8f3a-40e1-8080-889fea389603',
  'Inferred from overall platform framing and career pattern — no single direct quote addresses the citizen vs. government deference question explicitly. Roy explicitly frames the office''s primary obligation as being to the public — workers, tenants, consumers — against both corporate and city interests. Her campaign website states: "As City Attorney, I''ll restore integrity to the Office to make sure our City Attorney serves the people, not the powerful." Her LAist candidate survey describes her mission as making the office the "most significant public interest law office in Los Angeles" to prioritize "workers, tenants, climate, civil rights." The LA Forward voter guide quotes her commitment to "holding abusive police accountable" and contrasts her with the incumbent''s posture of defending city departments against misconduct lawsuits. Her proposed liability audit — inviting City Controller Kenneth Mejia to audit the office''s settlement practices — signals that Roy sees independent review of city decisions as part of her mandate, not reflexive defense of city positions. Her entire career has been spent representing workers, tenants, and consumers against institutions (corporate and government) that have legal resources they lack. This places her at value 1: the citizen, almost always; government has lawyers, money, and power; regular people need courts to level the playing field.',
  ARRAY[
    'https://www.marissaroy.com/',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://www.laforward.org/voterguide',
    'https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Section C: politician_context-only for "not found" topics
-- (NO politician_answers row — value must never be NULL)
-- ============================================================

-- judicial-transparency (not found: all Roy transparency statements are about office culture
-- and accountability to the public — not about court proceedings, record sealing, or
-- the balance between open hearings and protecting sensitive information)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7157dd95-0f1b-4e05-bd4f-39317345b47c',
  '6674d87e-999d-433a-aab7-3f626f59fd5f',
  'Researched 2026-05-09 — no public record found. Roy''s transparency statements across all sources focus on office transparency (culture, accountability, compliance, integrity) rather than transparency in legal proceedings. The LAist voter guide quotes her: "as city attorney, she''d uphold the highest standards of accountability, transparency and integrity. This includes faithfully executing the dual function of the role, restoring a culture of trust and respect within the Office and prioritizing compliance for all city departments." Her campaign website states: "restore integrity to the Office to make sure our City Attorney serves the people, not the powerful." These statements concern office culture and government accountability to the public — not the 1–5 spectrum for judicial-transparency, which concerns whether legal proceedings, hearings, evidence, and rulings should be maximally public vs. protected. No source contains a Roy statement on court record sealing, closed proceedings, evidentiary transparency, or balancing victim privacy against public access to proceedings. Checked: LAist voter guide, Patch profile Q&A, marissaroy.com, SPNA DTLA article, LA Forward voter guide, AOL/LA Times syndicated piece, Knock LA, Abundant Housing LA, Vote411/LWV (not indexed for this race), LA Times editorial board responses (paywalled — not attempted).',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
