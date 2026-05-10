-- Migration 120: John McKinney judicial compass stances
-- politician_id: 6cd2e87b-7366-429a-a049-990751bd647f
-- Researched: 2026-05-09
-- Sources: Patch Q&A, mckinney4la.com/issues, LAist voter guide, SPNA DTLA article
-- 5 of 6 applicable topics have placed stances; judicial-transparency is "not found"

BEGIN;

-- ============================================================
-- Section A: politician_answers for 5 placed stances
-- (judicial-transparency has no public-record evidence — context-only in Section C)
-- ============================================================

-- judicial-prosecution-priorities (value=4: prosecute all solid cases; declination is the exception)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6cd2e87b-7366-429a-a049-990751bd647f', 'abb99d95-cbb1-4617-8f8b-f220ef6028ca', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-criminal-justice (value=4: making sure others think twice; deterrence framing)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6cd2e87b-7366-429a-a049-990751bd647f', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-police-accountability (value=4: defend city employees vigorously; aggressive risk management)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6cd2e87b-7366-429a-a049-990751bd647f', '7bad33eb-e93e-4d94-8822-97212d49bde5', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-access-to-justice (value=3: reasonable standards; balanced approach)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6cd2e87b-7366-429a-a049-990751bd647f', '9d45acaf-1ba4-4cb8-95e1-5ed985223b91', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-government-deference (value=3: apply the law evenly; settle meritorious cases)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6cd2e87b-7366-429a-a049-990751bd647f', 'e5e48f0e-8f3a-40e1-8080-889fea389603', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- ============================================================
-- Section B: politician_context (reasoning + sources) for 5 placed stances
-- ============================================================

-- judicial-prosecution-priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '6cd2e87b-7366-429a-a049-990751bd647f',
  'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
  'McKinney''s prosecution framework covers a broad set of cases requiring active prosecution: repeat offenders, retail theft, organized shoplifting, illegal firearms, street racing, open-air drug markets, and encampment-related quality-of-life crimes. His Patch Q&A states: "The focus of the Los Angeles City Attorney''s Office must be on the crimes that are most directly impacting the public safety of our communities and the quality of life of our neighborhoods. That means prioritizing cases involving repeat offenders who drive quality-of-life crime through theft, vandalism, and destruction of property." His LAist campaign survey confirms he "will focus on repeat offenders driving down quality-of-life crime, retail theft and organized shoplifting, illegal firearms, and dangerous activities such as street racing and open-air drug markets." His "compassionate accountability" framing includes working with diversion programs and service providers, but explicitly as a complement to prosecution — he describes restoring order in public spaces as the primary goal, with services helping individuals "access housing, treatment and support" after enforcement contact. This positions him at value 4: prosecute all solid cases; declination requires a strong reason. He does not reach value 5 because he explicitly acknowledges diversion''s role and describes his approach as "not about punishment for its own sake."',
  ARRAY[
    'https://patch.com/california/los-angeles/meet-john-mckinney-candidate-los-angeles-city-attorney',
    'https://mckinney4la.com/issues',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-criminal-justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '6cd2e87b-7366-429a-a049-990751bd647f',
  '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
  'McKinney consistently frames criminal justice in terms of deterrence, accountability, and community safety. The LAist voter guide reports: "McKinney said he believes in enforcing the law fairly and without fear or favor. ''As City Attorney, he will uphold the integrity of the justice system and city government.''" His campaign told LAist: "[McKinney] will focus on repeat offenders driving down quality-of-life crime, retail theft and organized shoplifting, illegal firearms, and dangerous activities such as street racing and open-air drug markets." His career biography in the Patch Q&A — nearly 30 years as a prosecutor, 100+ jury trials including 40 murder cases, working in the Hardcore Gang Unit and Major Crimes Division — reinforces deterrence and accountability as his criminal justice philosophy. His platform does include diversion and services language ("compassionate accountability"), but describes these as means to "restore order" rather than alternatives to enforcement. This best matches value 4: making sure others think twice before doing the same thing. He does not reach value 5 (pure punishment) because he explicitly invokes the dignity of individuals and acknowledges diversion programs alongside prosecution.',
  ARRAY[
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://patch.com/california/los-angeles/meet-john-mckinney-candidate-los-angeles-city-attorney',
    'https://mckinney4la.com/issues'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-police-accountability
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '6cd2e87b-7366-429a-a049-990751bd647f',
  '7bad33eb-e93e-4d94-8822-97212d49bde5',
  'McKinney''s approach to police misconduct litigation is grounded in vigorous litigation management and liability reduction, not independent accountability. His Patch Q&A states: "As city attorney, I would implement an aggressive risk management strategy to reduce lawsuits and payouts, vigorously defend against frivolous claims, and settle meritorious cases early to avoid costly verdicts." He frames this as knowing "which cases to fight and which to resolve" — a liability management lens. His primary critique of the incumbent is about the LAPD data breach as a management and transparency failure, not about failure to hold police accountable for misconduct. He is endorsed by the Los Angeles Police Protective League (LAPD officer union) and former DAs Nathan Hochman and Jackie Lacey, both with law-enforcement-aligned records. His platform contains no statement about independent investigation of police misconduct, civilian oversight support, or systemic LAPD accountability. The pattern — vigorous defense of city employees, settling meritorious claims to cut costs (not as an accountability mechanism), police union endorsement — most closely matches value 4: defend city employees vigorously; that is the job; settlements invite more lawsuits. He does not reach value 5 because he explicitly acknowledges settling meritorious cases rather than defending everything regardless of merit.',
  ARRAY[
    'https://patch.com/california/los-angeles/meet-john-mckinney-candidate-los-angeles-city-attorney',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://mckinney4la.com/issues'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-access-to-justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '6cd2e87b-7366-429a-a049-990751bd647f',
  '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
  'McKinney''s access-to-justice framing is balanced and pragmatic rather than access-maximizing or access-restricting. His LAist entry includes: "McKinney said he respects constitutional protections that allow legal aid attorneys to challenge government actions. ''Limiting such advocacy through contract conditions or fear of lawsuits undermines legal services for the city''s most vulnerable and under-served residents.''" This affirms he supports legal access for vulnerable residents and opposes barriers to legitimate legal advocacy. His Issues page also commits to protecting renters from unlawful evictions and workers from wage theft, indicating he sees the legal system as a vehicle for these claims. At the same time, his litigation management approach — "vigorously defend against frivolous claims" — and repeated emphasis on reducing unnecessary lawsuits reflect a concern for filtering unmeritorious cases. His housing enforcement policy is explicitly "balanced," respecting both tenant rights and property owner rights. The combination of supporting legal aid access for the vulnerable while prioritizing efficient resolution and filtering frivolous claims best matches value 3: reasonable standards that keep out frivolous cases without blocking legitimate ones.',
  ARRAY[
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://patch.com/california/los-angeles/meet-john-mckinney-candidate-los-angeles-city-attorney',
    'https://mckinney4la.com/issues'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-government-deference
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '6cd2e87b-7366-429a-a049-990751bd647f',
  'e5e48f0e-8f3a-40e1-8080-889fea389603',
  'Inferred from litigation management framing and accountability statements — no single direct quote addresses the citizen vs. city deference question explicitly. McKinney explicitly commits to settling meritorious claims against the city: his Patch Q&A states "settle meritorious cases early to avoid costly verdicts. Effective litigation requires knowing which cases to fight and which to resolve, saving taxpayers money while ensuring accountability." This is neither reflexive city defense (value 4-5) nor a citizen-first stance (value 1-2). He also describes "promoting transparency in city contracting" and "ensuring taxpayer dollars are used responsibly" — framing the office as an independent steward of public funds, not as a defender of city officials'' decisions. His criticism of the incumbent is about management failures and LAPD data breach mismanagement, framing himself as holding City Hall accountable for errors. However, his "uphold the integrity of the justice system and city government" framing and career as an institutional prosecutor suggest a baseline respect for government authority. His stated approach of applying the law "fairly and consistently" across cases best matches value 3: neither side automatically — look at the facts and apply the law evenly.',
  ARRAY[
    'https://patch.com/california/los-angeles/meet-john-mckinney-candidate-los-angeles-city-attorney',
    'https://mckinney4la.com/issues',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Section C: politician_context-only for "not found" topics
-- (NO politician_answers row — value must never be NULL)
-- ============================================================

-- judicial-transparency (not found: all McKinney transparency statements are about city operations
-- and taxpayer accountability, not about court proceedings or legal record openness)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '6cd2e87b-7366-429a-a049-990751bd647f',
  '6674d87e-999d-433a-aab7-3f626f59fd5f',
  'Researched 2026-05-09 — no public record found. McKinney''s transparency statements are exclusively about city government operations, office management, and taxpayer accountability — not about transparency in legal proceedings, court record access, or the openness of hearings and evidence. His Issues page states: "defending ethical governance, promoting transparency in city contracting, and ensuring that taxpayer dollars are used responsibly." His Patch Q&A mentions the LAPD data breach as a management failure, and his campaign website describes "restored fiscal accountability." None of these address the 1–5 spectrum for judicial-transparency, which concerns whether legal proceedings, hearings, evidence, and rulings should be maximally public vs. protected. No source contains a McKinney statement on court record sealing, closed proceedings, evidentiary transparency, or balancing victim privacy against public access to proceedings. Checked: LAist voter guide, Patch profile, mckinney4la.com, SPNA DTLA article, LA Forward voter guide, DSA-LA voter guide, Knock LA, Abundant Housing LA, LA Times editorial board responses (paywalled — not attempted).',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
