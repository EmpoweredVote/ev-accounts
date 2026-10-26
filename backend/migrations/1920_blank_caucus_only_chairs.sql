-- Migration 1920 — withdraw 60 stance chairs whose entire evidence is CAUCUS MEMBERSHIP.
--
-- WHAT THIS IS. The first worked slice of the national generic-sourcing queue's unmeasured
-- remainder. That remainder was located and measured on 2026-10-20:
-- `backend/data/stance-research/2026-10-20-national-queue-remainder/MEASUREMENT.md`. Within it,
-- rows whose reasoning cites a caucus and names no instrument or vote of the person's own form a
-- mechanically identifiable sub-queue. All 79 were read by hand, one at a time, each with a
-- written reason: **60 BLANK · 14 KEEP · 5 blocked** (`immigration`, the one live topic with no
-- Season 2 ladder). 81.1% of the 74 actionable rows.
--
-- 🔴 THE SAMPLE SAID 100% AND THE FULL READ SAYS 81%. Five of these rows fell in the
-- measurement samples and all five failed, which is why the queue was described as near-uniformly
-- defective. Reading all 79 found 14 sound rows. Same lesson as tier A, where a 12-row sample
-- said ~50% and the full read said 67%: **a small sample gets the ORDER right long before the SIZE.**
--
-- ⚖⚖ THE RULE THIS PASS SETTLED, because 79 rows turn on it:
--   **A caucus organised around a TOPIC or a COUNTRY cannot seat a rung defined by DEGREE.**
-- The Congressional Ukraine Caucus takes no position on the LEVEL of aid, so it cannot separate
-- "significantly increase" from "continue current levels". The Equality Caucus advocates full
-- equality, so where it is the only evidence it argues for rung 1 and cannot seat rung 2 or 3 —
-- several rows here cite it and seat 3 anyway. The Freedom Caucus is an ideological bloc.
--   **Narrow exception, and it kept exactly one row:** a SINGLE-POLICY caucus whose policy IS the
-- rung's own text can seat that rung. Frederica Wilson's Medicare for All Caucus membership maps
-- to medicare/aid rung 1, "expand Medicare to cover everyone regardless of age", word for word.
-- Contrast the Expand Social Security Caucus, which names a DIRECTION spanning rungs 1 and 2 and
-- therefore seats neither (ledger C004, blanked).
--
-- ⚖ WHAT ELSE SURVIVED, and why these are not blanks. 14 KEEPs, and all of them hold an act of the
-- person's own that the caucus was merely sitting beside: Grijalva's sole vote against closing the
-- Mexican American Studies programme; Dereck Davis scrutinising contracts for participation by
-- historically disadvantaged business owners; Conaway backing the removal of religious vaccination
-- exemptions and calling an exemption bill "a recipe for disaster"; Magaziner on the board of
-- Marriage Equality Rhode Island; McDonald Rivet's support for Michigan Proposal 3, whose viability
-- line is exactly what separates abortion rung 2 from rung 1.
-- 🔑 Sigcho-Lopez's taxes row (C013) is the model of the remedy rather than of the defect: an
-- earlier migration had already stripped the caucus step out of it, saying so in the row itself —
-- "caucus membership is not a position" — and re-seated it on a letter it quotes.
--
-- ⚖ WHAT A BLANK HERE ASSERTS, AND WHAT IT DOES NOT. It asserts that the row's own reasoning does
-- not support the chair it carries. It does NOT assert the person holds no view, and for many of
-- these people the view is well documented elsewhere — the repair is cheap and is the better fix
-- where someone has the time. Fitzpatrick (C011) co-chairs the Ukraine Caucus and has abundant
-- supplemental votes on the record; the row simply never cited one.
--
-- 🔑 WHY A SEASON 2 BLANK. Season 1 is closed. A Season 2 answer of 0 SUPPRESSES —
-- `NULLIF(pa.value, 0)`, the guard outside the season collapse. Same mechanism as 1914-1919.
--
-- COMPOSITION. 60 rows across 37 people. 44 INSERT, 16 UPDATE.
-- THE SHAPES: AFFIL 56 · RUNGTEXT 8 · OFFAXIS 8 · ADMITS 3 · SCORE 3 · AWAY 2 · GEO 2 · NONCOSP 1 ·
-- VINTAGE 1 · STALE-PROSE 1 · ABSENCE 1 · MAXIMAL-RUNG 1 · IDENTITY 1.
-- BY TOPIC: ukraine-support 13/15 · same-sex-marriage 12/13 · civil-rights 9/12 · taxes 4/5 ·
-- housing 4/4 · abortion 3/5 · healthcare 3/3 · the rest in ones and twos.
-- 🔴 ONE PERSON, EIGHT ROWS: every actionable Denny Hoskins row in this queue rests on Missouri
-- Freedom Caucus membership and all eight blank. **The repair unit is the PERSON.**
--
-- ⚠ NOT TOUCHED — the 5 `immigration` rows (C003 Grijalva, C030 Hoskins, C042 Landsman,
-- C069 Menendez, C078 Ansari). That topic has no Season 2 ladder, so there is no revision to write
-- an S2 answer against. They remain the same blocked cohort named in migrations 1915 and 1917.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards below fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1920_decisions (
  politician_id     uuid   NOT NULL,
  topic_id          uuid   NOT NULL,
  topic_revision_id uuid   NOT NULL,
  reasoning         text   NOT NULL,
  ledger_no         text   NOT NULL
) ON COMMIT DROP;

INSERT INTO mig1920_decisions
  (politician_id, topic_id, topic_revision_id, reasoning, ledger_no)
VALUES
-- C002  Adelita S. Grijalva / housing  (was 3, ADMITS+RUNGTEXT)
('b0215f01-089f-4892-85a1-f9abcb4ff4af'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'598c879d-f387-461c-9120-fbbbf6314bbc'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: SELF-DECLARED. The row states in its own words that no position was found, or that the evidence is thin, and seats a chair anyway. RUNG TEXT. The evidence is real and on-axis, and the seated rung''s own wording describes something the evidence does not show. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C002.','C002'),
-- C004  Adriano Espaillat / social-security  (was 2, AFFIL+NONCOSP)
('26636234-c292-4a02-8205-6b84f6864f82'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,'8defc029-0b7e-426f-b838-a2e170f566c9'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. NON-CO-SPONSORSHIP. The evidence is that a named bill was NOT co-sponsored. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C004.','C004'),
-- C005  Adriano Espaillat / ukraine-support  (was 2, AFFIL)
('26636234-c292-4a02-8205-6b84f6864f82'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C005.','C005'),
-- C006  Alexi Giannoulias / abortion  (was 2, AFFIL+VINTAGE)
('65df6ce5-a824-4b24-a0a9-d031e3631272'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. VINTAGE. The basis predates the office now held, or a change of office or party. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C006.','C006'),
-- C007  Alexi Giannoulias / healthcare  (was 2, AFFIL)
('65df6ce5-a824-4b24-a0a9-d031e3631272'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C007.','C007'),
-- C008  Alexi Giannoulias / taxes  (was 2, AFFIL)
('65df6ce5-a824-4b24-a0a9-d031e3631272'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,'87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C008.','C008'),
-- C009  Bonnie Watson Coleman / ukraine-support  (was 2, AFFIL)
('a75a3e6e-31ff-4870-8aea-501e41326fd1'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C009.','C009'),
-- C011  Brian K. Fitzpatrick / ukraine-support  (was 2, AFFIL)
('a5d68f92-d5e2-4fa1-a191-a64e8ebb2ada'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C011.','C011'),
-- C012  Brittany Pettersen / healthcare  (was 2, AFFIL)
('3142051c-9ded-4883-95fc-4af1de6e6eec'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C012.','C012'),
-- C014  Christopher R. Deluzio / civil-rights  (was 2, AFFIL)
('c20345d9-e451-4813-8645-985734fedba3'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C014.','C014'),
-- C015  Christopher R. Deluzio / same-sex-marriage  (was 3, AFFIL+AWAY)
('c20345d9-e451-4813-8645-985734fedba3'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. ABSENCE MOVES THE SEAT. The positive evidence points at a different rung and an absence carries the seat away from it. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C015.','C015'),
-- C016  Chuck Edwards / abortion  (was 4, AFFIL)
('f7763de5-8cb1-439b-9176-2c16070c01df'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C016.','C016'),
-- C017  Chuck Edwards / housing  (was 5, AFFIL+STALE-PROSE)
('f7763de5-8cb1-439b-9176-2c16070c01df'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'598c879d-f387-461c-9120-fbbbf6314bbc'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. STALE RUNG NUMBER. The row''s prose names a rung number that no longer matches the ladder it is seated on. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C017.','C017'),
-- C018  Craig J. Zucker / abortion  (was 2, AFFIL+ADMITS)
('82145bc2-770a-421e-a2a1-0e79aae5b643'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. SELF-DECLARED. The row states in its own words that no position was found, or that the evidence is thin, and seats a chair anyway. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C018.','C018'),
-- C020  David P. Joyce / climate-change  (was 3, AFFIL)
('811f725f-1eaa-4e67-9dbc-389698615e00'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C020.','C020'),
-- C021  David P. Joyce / fossil-fuels  (was 3, AFFIL)
('811f725f-1eaa-4e67-9dbc-389698615e00'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C021.','C021'),
-- C022  David P. Joyce / medicare/aid  (was 3, AFFIL+ABSENCE)
('811f725f-1eaa-4e67-9dbc-389698615e00'::uuid,'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid,'38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. ABSENCE. An absence of evidence supplies the direction instead of narrowing a range. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C022.','C022'),
-- C023  David Schweikert / ukraine-support  (was 4, OFFAXIS+AFFIL)
('17e59190-17e2-4a90-8353-b5ea8d083480'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: OFF AXIS. The evidence is checkable and the person''s own, and it answers a different question from the one this ladder asks. AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C023.','C023'),
-- C024  Deborah K. Ross / ukraine-support  (was 2, ADMITS+AFFIL)
('291f71df-c5c2-4f0a-b6be-d762d7aec9dd'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: SELF-DECLARED. The row states in its own words that no position was found, or that the evidence is thin, and seats a chair anyway. AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C024.','C024'),
-- C025  Denny Hoskins / civil-rights  (was 5, AFFIL+MAXIMAL-RUNG)
('b7318128-42e4-4285-989d-11a849f76e95'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. MAXIMAL RUNG. The seat is at an end of the ladder, where no stronger neighbour exists for an absence to decline, and the end clause itself is unevidenced. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C025.','C025'),
-- C026  Denny Hoskins / climate-change  (was 5, AFFIL)
('b7318128-42e4-4285-989d-11a849f76e95'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C026.','C026'),
-- C027  Denny Hoskins / deportation  (was 4, AFFIL)
('b7318128-42e4-4285-989d-11a849f76e95'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,'55c3167e-3ad8-425d-a699-b2e91552d912'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C027.','C027'),
-- C028  Denny Hoskins / fossil-fuels  (was 4, AFFIL+GEO)
('b7318128-42e4-4285-989d-11a849f76e95'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. DISTRICT DEMOGRAPHICS. Who lives in the district is offered as what the member holds. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C028.','C028'),
-- C029  Denny Hoskins / healthcare  (was 4, AFFIL+RUNGTEXT)
('b7318128-42e4-4285-989d-11a849f76e95'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. RUNG TEXT. The evidence is real and on-axis, and the seated rung''s own wording describes something the evidence does not show. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C029.','C029'),
-- C031  Denny Hoskins / redistricting  (was 4, AFFIL+RUNGTEXT)
('b7318128-42e4-4285-989d-11a849f76e95'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. RUNG TEXT. The evidence is real and on-axis, and the seated rung''s own wording describes something the evidence does not show. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C031.','C031'),
-- C032  Denny Hoskins / religious-freedom  (was 5, AFFIL)
('b7318128-42e4-4285-989d-11a849f76e95'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C032.','C032'),
-- C033  Denny Hoskins / taxes  (was 5, AFFIL)
('b7318128-42e4-4285-989d-11a849f76e95'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,'87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C033.','C033'),
-- C035  Derek Tran / childcare  (was 2, AFFIL+OFFAXIS)
('b7612f49-c914-4ea7-a6da-559d71f313c2'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid,'0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. OFF AXIS. The evidence is checkable and the person''s own, and it answers a different question from the one this ladder asks. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C035.','C035'),
-- C037  Derek Tran / misinformation  (was 2, OFFAXIS)
('b7612f49-c914-4ea7-a6da-559d71f313c2'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: OFF AXIS. The evidence is checkable and the person''s own, and it answers a different question from the one this ladder asks. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C037.','C037'),
-- C038  Dina Titus / civil-rights  (was 2, AFFIL+SCORE)
('786af5d2-9502-401c-a3ed-61de88e589e9'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. BARE SCORE. An alignment percentage or rating stands in for a record of votes. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C038.','C038'),
-- C039  Frank J. Mrvan / same-sex-marriage  (was 2, AFFIL)
('e08ec276-3194-41d4-833b-953f27454857'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C039.','C039'),
-- C043  Greg Landsman / taxes  (was 2, AFFIL)
('6cad043f-a4c0-48d5-af76-fdf70d319920'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,'87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C043.','C043'),
-- C045  J. French Hill / ukraine-support  (was 2, AFFIL)
('85ec278d-c143-4128-a058-e468899ded8f'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C045.','C045'),
-- C046  Jill N. Tokuda / same-sex-marriage  (was 3, AFFIL+RUNGTEXT)
('761aa2ac-d877-4654-97c7-60bf40980f63'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. RUNG TEXT. The evidence is real and on-axis, and the seated rung''s own wording describes something the evidence does not show. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C046.','C046'),
-- C047  Joseph D. Morelle / ukraine-support  (was 2, AFFIL+SCORE)
('c02d8232-aa7a-429a-9abe-dccb409c1c6f'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. BARE SCORE. An alignment percentage or rating stands in for a record of votes. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C047.','C047'),
-- C049  Josh Riley / same-sex-marriage  (was 2, AFFIL)
('a6a6d7b2-88d4-441b-8191-d5baa0db6987'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C049.','C049'),
-- C050  Keith Ellison / same-sex-marriage  (was 2, AFFIL+OFFAXIS)
('9b7310b5-d12f-419d-af87-6ad834a1055a'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. OFF AXIS. The evidence is checkable and the person''s own, and it answers a different question from the one this ladder asks. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C050.','C050'),
-- C052  Kelly Morrison / same-sex-marriage  (was 2, AFFIL)
('8a0696c4-5536-4309-9d02-b0ebb61de56b'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C052.','C052'),
-- C054  Kristen McDonald Rivet / civil-rights  (was 2, AFFIL+GEO)
('7d800c44-7a73-440e-8023-14f93fde06c0'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. DISTRICT DEMOGRAPHICS. Who lives in the district is offered as what the member holds. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C054.','C054'),
-- C055  Kristen McDonald Rivet / same-sex-marriage  (was 2, AFFIL)
('7d800c44-7a73-440e-8023-14f93fde06c0'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C055.','C055'),
-- C056  LaMonica McIver / civil-rights  (was 2, OFFAXIS+AFFIL)
('c8cd097f-ce28-40b1-8236-18bc111ad868'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: OFF AXIS. The evidence is checkable and the person''s own, and it answers a different question from the one this ladder asks. AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C056.','C056'),
-- C057  Madeleine Dean / ukraine-support  (was 2, AFFIL+SCORE)
('bf942e86-fe8c-496f-9a36-212e9f9403e3'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. BARE SCORE. An alignment percentage or rating stands in for a record of votes. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C057.','C057'),
-- C058  Marie Gluesenkamp Perez / civil-rights  (was 3, AFFIL+AWAY)
('a24347dd-c92d-4fca-9629-48cf7631b0c5'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. ABSENCE MOVES THE SEAT. The positive evidence points at a different rung and an absence carries the seat away from it. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C058.','C058'),
-- C059  Marie Gluesenkamp Perez / same-sex-marriage  (was 3, AFFIL+RUNGTEXT)
('a24347dd-c92d-4fca-9629-48cf7631b0c5'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. RUNG TEXT. The evidence is real and on-axis, and the seated rung''s own wording describes something the evidence does not show. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C059.','C059'),
-- C060  Michael Lawler / ukraine-support  (was 2, AFFIL)
('cd4e9f29-d1b0-40c1-9e4a-5024cdc7b028'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C060.','C060'),
-- C061  Mike Flood / taxes  (was 4, AFFIL+OFFAXIS)
('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,'87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. OFF AXIS. The evidence is checkable and the person''s own, and it answers a different question from the one this ladder asks. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C061.','C061'),
-- C062  Morgan McGarvey / same-sex-marriage  (was 2, AFFIL)
('9c8e165b-9079-4ed2-ad0a-0a9d98fd9931'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C062.','C062'),
-- C063  Ro Khanna / housing  (was 4, AFFIL+RUNGTEXT)
('07255876-bbe6-4f6a-8c68-75939d9b5128'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'598c879d-f387-461c-9120-fbbbf6314bbc'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. RUNG TEXT. The evidence is real and on-axis, and the seated rung''s own wording describes something the evidence does not show. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C063.','C063'),
-- C064  Ro Khanna / ukraine-support  (was 3, RUNGTEXT)
('07255876-bbe6-4f6a-8c68-75939d9b5128'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: RUNG TEXT. The evidence is real and on-axis, and the seated rung''s own wording describes something the evidence does not show. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C064.','C064'),
-- C065  Robert Garcia / misinformation  (was 2, AFFIL)
('28a5f098-7f90-4fa9-af7e-c034d49cb538'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C065.','C065'),
-- C066  Robert Menendez / civil-rights  (was 2, AFFIL)
('fc7a00d6-c552-4627-87f7-b0fc5cfe486c'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C066.','C066'),
-- C068  Robert Menendez / housing  (was 3, AFFIL)
('fc7a00d6-c552-4627-87f7-b0fc5cfe486c'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'598c879d-f387-461c-9120-fbbbf6314bbc'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C068.','C068'),
-- C070  Robert Menendez / ukraine-support  (was 2, AFFIL)
('fc7a00d6-c552-4627-87f7-b0fc5cfe486c'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C070.','C070'),
-- C071  Sam Liccardo / civil-rights  (was 2, OFFAXIS)
('7ceb0371-baba-4d05-9204-2852cc91dee0'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: OFF AXIS. The evidence is checkable and the person''s own, and it answers a different question from the one this ladder asks. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C071.','C071'),
-- C072  Sam Liccardo / same-sex-marriage  (was 2, AFFIL)
('7ceb0371-baba-4d05-9204-2852cc91dee0'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C072.','C072'),
-- C073  Sam Liccardo / ukraine-support  (was 2, AFFIL)
('7ceb0371-baba-4d05-9204-2852cc91dee0'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C073.','C073'),
-- C075  Suhas Subramanyam / same-sex-marriage  (was 3, AFFIL+RUNGTEXT)
('98b05c70-2a30-48ea-81f3-b3216ffb0ca0'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. RUNG TEXT. The evidence is real and on-axis, and the seated rung''s own wording describes something the evidence does not show. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C075.','C075'),
-- C076  Timothy M. Kennedy / ukraine-support  (was 2, AFFIL)
('7e37b0b1-d311-4cf3-8f19-f861626d5d98'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,'107d180d-a949-4a42-a250-54f0a7683be0'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C076.','C076'),
-- C077  Yassamin Ansari / civil-rights  (was 2, AFFIL+IDENTITY)
('dde8a67d-a16a-4442-9732-3e620f4f561b'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,'2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. IDENTITY. The person''s background or identity is offered as evidence of a position. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C077.','C077'),
-- C079  Yassamin Ansari / same-sex-marriage  (was 2, AFFIL+OFFAXIS)
('dde8a67d-a16a-4442-9732-3e620f4f561b'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid,'INTERNAL RECORD - blanked: the chair rested on an affiliation rather than on evidence of a position. Shape: AFFILIATION. The seat rests on membership of a caucus, party or bloc, or on what that group advocates, rather than on an act of this person. OFF AXIS. The evidence is checkable and the person''s own, and it answers a different question from the one this ladder asks. Writing this pair blank in Season 2 withdraws the Season 1 answer from view; it does not assert that the person holds no view, only that none was shown. Caucus-only queue of the national generic-sourcing remainder, migration 1920, ledger row C079.','C079');

-- GUARD 1 — the decision table arrived whole.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1920_decisions;
  IF n <> 60 THEN
    RAISE EXCEPTION 'migration 1920: expected 60 decisions, found %', n;
  END IF;
  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1920_decisions) s;
  IF n <> 60 THEN
    RAISE EXCEPTION 'migration 1920: decisions contain duplicate (politician, topic) pairs; % distinct of 60', n;
  END IF;
END $$;

-- GUARD 2 — every target must TODAY carry a non-zero chair somewhere. If a pair is already blank,
-- something else has moved it since the queue was measured and this file is operating on a stale
-- picture; stop rather than silently re-blank it.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1920_decisions d
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_answers pa
      WHERE pa.politician_id = d.politician_id
        AND pa.topic_id = d.topic_id
        AND pa.value <> 0);
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1920: % target pair(s) no longer carry a non-zero chair — re-measure the queue', n;
  END IF;
END $$;

-- GUARD 3 — every target must have citations available to carry forward, BEFORE anything is
-- written. 🔴 Migration 1915 wrote 206 blanks with EMPTY sources and every ROW COUNT passed; the
-- defect was in the SHAPE of what was written, not in how much.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1920_decisions d
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc0
      WHERE pc0.politician_id = d.politician_id
        AND pc0.topic_id = d.topic_id
        AND coalesce(cardinality(pc0.sources), 0) > 0);
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1920: % target pair(s) have no citations to carry forward', n;
  END IF;
END $$;

-- The answer: 0 is the documented blank.
INSERT INTO inform.politician_answers
  (politician_id, topic_id, value, season_id, topic_revision_id)
SELECT d.politician_id, d.topic_id, 0, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, d.topic_revision_id
  FROM mig1920_decisions d
ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
  SET value = 0, updated_at = now();

-- The record of WHY, which is what makes it a documented blank rather than a deletion.
-- 🔑 SOURCES ARE CARRIED FROM THE ROW BEING WITHDRAWN, by the SQL rather than from the decision
-- table, so they cannot drift from what the pair actually cites.
INSERT INTO inform.politician_context
  (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id)
SELECT d.politician_id, d.topic_id, d.reasoning,
       COALESCE((SELECT pc0.sources
                   FROM inform.politician_context pc0
                  WHERE pc0.politician_id = d.politician_id
                    AND pc0.topic_id = d.topic_id
                    AND coalesce(cardinality(pc0.sources), 0) > 0
                  ORDER BY (pc0.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid), pc0.updated_at DESC NULLS LAST
                  LIMIT 1), '{}'::text[]),
       '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, d.topic_revision_id
  FROM mig1920_decisions d
ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = CASE WHEN coalesce(cardinality(inform.politician_context.sources), 0) = 0
                       THEN EXCLUDED.sources
                       ELSE inform.politician_context.sources END,
      updated_at = now();

-- GUARD 4 — verify the RESULT, not the absence of an error.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1920_decisions d
    JOIN inform.politician_answers pa
      ON pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = 0
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pc.reasoning LIKE 'INTERNAL RECORD%';
  IF n <> 60 THEN
    RAISE EXCEPTION 'migration 1920: expected 60 blanked Season 2 rows, found %', n;
  END IF;

  SELECT count(*) INTO n
    FROM mig1920_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1920: % blank(s) carry no citations - a documented blank must record what was checked', n;
  END IF;

  -- Each row must say WHICH KIND of nothing it is: the reason code is part of the record.
  SELECT count(*) INTO n
    FROM mig1920_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%Shape:%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1920: % blank(s) do not record which kind of nothing they are', n;
  END IF;

  -- Season 1 is closed and must not have moved.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
    JOIN mig1920_decisions d
      ON d.politician_id = pa.politician_id AND d.topic_id = pa.topic_id
   WHERE pa.value = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1920: % Season 1 answer(s) were modified — Season 1 is closed', n;
  END IF;
END $$;
