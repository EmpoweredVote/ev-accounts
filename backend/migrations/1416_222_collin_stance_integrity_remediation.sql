-- =====================================================================================
-- Phase 222 — Collin County stance-integrity remediation (county-wide, AUDIT-ONLY)
-- Date: 2026-07-25
--
-- AUDIT-ONLY / UNREGISTERED migration. This file is deliberately NOT registered in
-- schema_migrations. It touches only inform.politician_answers and inform.politician_context.
-- The orchestrator (not this migration's authoring session) applies it, at the Task 3
-- operator checkpoint of plan 222-02, via mcp__supabase-local__execute_sql.
--
-- ORIGIN: the 222-01 integrity audit (222-01-INTEGRITY-AUDIT.md) re-examined all 220
-- pre-existing inform.politician_answers rows held by the 57 already-stanced in-scope
-- Collin/Longview officeholders (stanced before this phase's evidence bar was written
-- down) and found 12 rows that flatly violate the D-04 evidence-only bar (Class A) plus
-- 19 more rows whose reasoning is adjacency-only rather than an explicit on-topic
-- citation (Class B2, hand-reviewed by 222-02 Task 1).
--
-- THIS MIGRATION DELETES ONLY. It creates, raises, lowers, or re-reasons NO stance value.
-- Every DELETE is idempotent (WHERE politician_id = ... AND topic_id = ..., 0-or-1 rows,
-- errors on nothing already gone) and every deleted answer row is paired with its context
-- row for the same (politician_id, topic_id) — never one without the other.
--
-- Party affiliation is quoted below in exactly one place (Barrios, A2) solely because
-- naming a party in stored reasoning text is itself the defect being removed — this is
-- the one legitimate use of the phrase, mirroring 222-01-INTEGRITY-AUDIT.md's own framing.
--
-- =====================================================================================
-- CLASS A — 12 rows — confirmed DELETE (Task 1, re-confirmed verbatim against the audit)
-- =====================================================================================
--  1. A1 | Celina     | Ryan Tubbs          | cb9d6924-77d1-49c9-ab3d-778b0201e623 | housing             | 669cac97-66a6-4087-b036-936fbe62efb3
--       Rationale: chair assigned despite reasoning admitting "no record found"/"no public
--       statement"; sources NULL. Part of the 2026-05-11 batch pass that defaulted housing
--       for everyone regardless of person-specific evidence.
--  2. A1 | Frisco     | Burt Thakur         | c11bf372-8190-4b45-b80a-cbd0fb2ba401 | housing             | 669cac97-66a6-4087-b036-936fbe62efb3
--       Rationale: same A1 batch pattern — no-record-found admission, sources NULL, chair
--       defaulted anyway.
--  3. A1 | Plano      | Chris Krupa Downs   | 127b8e69-3900-438c-8361-2cfe24b6c6cf | housing             | 669cac97-66a6-4087-b036-936fbe62efb3
--       Rationale: verbatim excerpt — "no specific record found of Downs stating a position
--       on affordable housing policy... Assumed..." — textbook A1, explicitly assumed with
--       no person-specific evidence.
--  4. A1 | Plano      | Chris Krupa Downs   | 127b8e69-3900-438c-8361-2cfe24b6c6cf | residential-zoning  | d4f18138-a2e0-4110-b925-7387d9d0d16d
--       Rationale: same 2026-05-11 A1 batch pattern as Downs's housing row; no on-topic
--       evidence of Downs's own zoning position.
--  5. A1 | Plano      | Shun Thomas         | 4272e5cb-40cf-42d9-a493-ae5ca04301bb | housing             | 669cac97-66a6-4087-b036-936fbe62efb3
--       Rationale: same A1 batch pattern — no record found, sources NULL, chair defaulted
--       anyway.
--  6. A2 | Richardson | Dan Barrios         | e8c863a7-d116-480e-a81f-47d26f45e264 | civil-rights        | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Rationale: verbatim excerpt names party — "Barrios is a Democrat running for
--       Congress on a platform of 'fairness, accountability, and common sense'..." — stance
--       derived from party/platform framing, not an on-topic personal position; violates
--       antipartisan display rule and D-04.
--  7. A3 | Plano      | Vidal Quintanilla   | 5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f | civil-rights        | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Rationale: same identity-inference reasoning pattern as Quintanilla's
--       local-immigration row (ethnicity/birthplace-derived); no explicit on-topic
--       civil-rights statement/vote/questionnaire cited.
--  8. A3 | Plano      | Vidal Quintanilla   | 5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f | local-immigration   | b9ccee94-ad96-4f10-b655-889d8e5abe92
--       Rationale: verbatim excerpt — "Quintanilla, a Mexican American born in the Rio
--       Grande Valley border region, served on Plano's Commu..." — stance inferred from
--       ethnicity/birthplace + board membership, not an explicit statement.
--  9. A3 | Richardson | Amir Omar           | e9b9877d-c4dc-482e-b52a-cd015a4a6850 | civil-rights        | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Rationale: verbatim excerpt — "...a first-generation American of Palestinian and
--       Iranian descent and the first Muslim mayor of a DFW city..." — stance inferred from
--       ethnicity/religion, not an on-topic statement.
-- 10. A3 | Richardson | Arefin Shamsul      | 9f93ae55-9228-478d-84a9-971cf4686649 | civil-rights        | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Rationale: same A3 ethnicity/religion/birthplace-inference pattern as Omar's row;
--       no explicit on-topic statement cited.
-- 11. A4 | Plano      | John B. Muns        | 5584e869-4a54-4a68-a3c8-c14db45a71c5 | local-immigration   | b9ccee94-ad96-4f10-b655-889d8e5abe92
--       Rationale: same A4 pattern as Tu's row below — chair defaulted from Plano's
--       city-wide SB4 policy rather than Muns's own words; reasoning notes he made no
--       public statement.
-- 12. A4 | Plano      | Maria Tu            | d6bf8d34-5a59-419a-8ed7-9c9b4d865799 | local-immigration   | b9ccee94-ad96-4f10-b655-889d8e5abe92
--       Rationale: verbatim excerpt — "Plano operates under Texas SB4 (2017)... Tu has made
--       no public statements advocating ei..." — chair defaulted from city-wide law, not
--       her own statement; textbook stance_no_default_value violation.
--
-- =====================================================================================
-- CLASS B2 — 19 rows — hand-reviewed by Task 1, all DELETE
-- =====================================================================================
-- Task 1 could not access per-row reasoning/source text for any of these 19 rows: this
-- executing session has no mcp__supabase-local__execute_sql binding (no DB access) and
-- 222-01-INTEGRITY-AUDIT.md itself captures only the class-level "weak adjacency"
-- characterization for Class B2 (board membership, professional background, "general
-- profile", city-wide budget vote) — not a per-row verbatim excerpt the way it does for
-- Class A. Per the 222-02 plan's own explicit tie-breaker ("when genuinely uncertain
-- whether a row clears the bar, delete it — a deletion is cost-free and reversible by a
-- future evidence-backed write; keeping a defective row is not"), every one of the 19 is
-- therefore DELETE rather than KEEP. The Task 3 operator checkpoint is asked to confirm
-- this conservative read is acceptable, or to supply the missing per-row citations before
-- apply if any genuinely clears the D-04 bar.
--
-- 13. B2 | Allen      | Amy Gnadt           | b0a9801c-7f9d-4d7b-99f5-09360cf69c08 | housing             | 669cac97-66a6-4087-b036-936fbe62efb3
-- 14. B2 | Allen      | Amy Gnadt           | b0a9801c-7f9d-4d7b-99f5-09360cf69c08 | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85
-- 15. B2 | Allen      | Amy Gnadt           | b0a9801c-7f9d-4d7b-99f5-09360cf69c08 | residential-zoning  | d4f18138-a2e0-4110-b925-7387d9d0d16d
-- 16. B2 | Allen      | Carl Clemencich     | f72c8a0c-61dd-4a86-a205-171e331fcaee | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85
-- 17. B2 | Allen      | Michael Schaeffer   | c7a0ecf6-b416-474b-9647-a25e404f4bc4 | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53
-- 18. B2 | Allen      | Tommy Baril         | 3b15d821-fc1e-4e7b-bda0-13a669a77a27 | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53
-- 19. B2 | Frisco     | Angelia Pelham      | 5b346b19-d6ee-47e2-acbf-5780ca423264 | civil-rights        | 0bc588c6-39e1-4084-b5de-cac909b8b762
-- 20. B2 | McKinney   | Ernest Lynch        | c3e2d7a6-8096-4e91-9ee0-3cca445af72e | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53
-- 21. B2 | McKinney   | Geré Feltus         | 23ba75d2-6eed-4b71-9669-78ab3bb82e98 | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53
-- 22. B2 | McKinney   | Geré Feltus         | 23ba75d2-6eed-4b71-9669-78ab3bb82e98 | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85
-- 23. B2 | McKinney   | Justin Beller       | bcdbeae4-04c9-4ea1-8942-bac3ce1a8723 | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53
-- 24. B2 | McKinney   | Justin Beller       | bcdbeae4-04c9-4ea1-8942-bac3ce1a8723 | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85
-- 25. B2 | McKinney   | Michael Jones       | 09dbafc2-9252-40e4-9a1c-afda5b069f2e | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53
-- 26. B2 | McKinney   | Patrick Cloutier    | 27578980-2e6c-4639-879a-70b510566d0f | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53
-- 27. B2 | McKinney   | Rick Franklin       | 6ee726c1-79af-4fef-abb8-fa7f4208ae14 | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53
-- 28. B2 | McKinney   | Rick Franklin       | 6ee726c1-79af-4fef-abb8-fa7f4208ae14 | residential-zoning  | d4f18138-a2e0-4110-b925-7387d9d0d16d
-- 29. B2 | Plano      | Shun Thomas         | 4272e5cb-40cf-42d9-a493-ae5ca04301bb | homelessness        | 4938766b-b45a-46e3-93bd-b8b30651271a
-- 30. B2 | Richardson | Arefin Shamsul      | 9f93ae55-9228-478d-84a9-971cf4686649 | residential-zoning  | d4f18138-a2e0-4110-b925-7387d9d0d16d
-- 31. B2 | Richardson | Dan Barrios         | e8c863a7-d116-480e-a81f-47d26f45e264 | homelessness        | 4938766b-b45a-46e3-93bd-b8b30651271a
--
-- TOTAL: 31 (politician_id, topic_id) pairs targeted for deletion — 12 Class A + 19 Class B2.
-- Distinct people affected: 22 (Ryan Tubbs, Burt Thakur, Chris Krupa Downs, Shun Thomas,
-- Dan Barrios, Vidal Quintanilla, Amir Omar, Arefin Shamsul, John B. Muns, Maria Tu,
-- Amy Gnadt, Carl Clemencich, Michael Schaeffer, Tommy Baril, Angelia Pelham, Ernest Lynch,
-- Geré Feltus, Justin Beller, Michael Jones, Patrick Cloutier, Rick Franklin).
-- =====================================================================================

BEGIN;

-- ----- 1. Ryan Tubbs / housing (A1) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'cb9d6924-77d1-49c9-ab3d-778b0201e623' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
DELETE FROM inform.politician_context WHERE politician_id = 'cb9d6924-77d1-49c9-ab3d-778b0201e623' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- ----- 2. Burt Thakur / housing (A1) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'c11bf372-8190-4b45-b80a-cbd0fb2ba401' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
DELETE FROM inform.politician_context WHERE politician_id = 'c11bf372-8190-4b45-b80a-cbd0fb2ba401' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- ----- 3. Chris Krupa Downs / housing (A1) -----
DELETE FROM inform.politician_answers WHERE politician_id = '127b8e69-3900-438c-8361-2cfe24b6c6cf' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
DELETE FROM inform.politician_context WHERE politician_id = '127b8e69-3900-438c-8361-2cfe24b6c6cf' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- ----- 4. Chris Krupa Downs / residential-zoning (A1) -----
DELETE FROM inform.politician_answers WHERE politician_id = '127b8e69-3900-438c-8361-2cfe24b6c6cf' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
DELETE FROM inform.politician_context WHERE politician_id = '127b8e69-3900-438c-8361-2cfe24b6c6cf' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';

-- ----- 5. Shun Thomas / housing (A1) -----
DELETE FROM inform.politician_answers WHERE politician_id = '4272e5cb-40cf-42d9-a493-ae5ca04301bb' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
DELETE FROM inform.politician_context WHERE politician_id = '4272e5cb-40cf-42d9-a493-ae5ca04301bb' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- ----- 6. Dan Barrios / civil-rights (A2 — party named in reasoning) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
DELETE FROM inform.politician_context WHERE politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- ----- 7. Vidal Quintanilla / civil-rights (A3) -----
DELETE FROM inform.politician_answers WHERE politician_id = '5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
DELETE FROM inform.politician_context WHERE politician_id = '5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- ----- 8. Vidal Quintanilla / local-immigration (A3) -----
DELETE FROM inform.politician_answers WHERE politician_id = '5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
DELETE FROM inform.politician_context WHERE politician_id = '5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';

-- ----- 9. Amir Omar / civil-rights (A3) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'e9b9877d-c4dc-482e-b52a-cd015a4a6850' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
DELETE FROM inform.politician_context WHERE politician_id = 'e9b9877d-c4dc-482e-b52a-cd015a4a6850' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- ----- 10. Arefin Shamsul / civil-rights (A3) -----
DELETE FROM inform.politician_answers WHERE politician_id = '9f93ae55-9228-478d-84a9-971cf4686649' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
DELETE FROM inform.politician_context WHERE politician_id = '9f93ae55-9228-478d-84a9-971cf4686649' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- ----- 11. John B. Muns / local-immigration (A4 — SB4 default) -----
DELETE FROM inform.politician_answers WHERE politician_id = '5584e869-4a54-4a68-a3c8-c14db45a71c5' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
DELETE FROM inform.politician_context WHERE politician_id = '5584e869-4a54-4a68-a3c8-c14db45a71c5' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';

-- ----- 12. Maria Tu / local-immigration (A4 — SB4 default) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'd6bf8d34-5a59-419a-8ed7-9c9b4d865799' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
DELETE FROM inform.politician_context WHERE politician_id = 'd6bf8d34-5a59-419a-8ed7-9c9b4d865799' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';

-- ----- 13. Amy Gnadt / housing (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
DELETE FROM inform.politician_context WHERE politician_id = 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- ----- 14. Amy Gnadt / public-safety-approach (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
DELETE FROM inform.politician_context WHERE politician_id = 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- ----- 15. Amy Gnadt / residential-zoning (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
DELETE FROM inform.politician_context WHERE politician_id = 'b0a9801c-7f9d-4d7b-99f5-09360cf69c08' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';

-- ----- 16. Carl Clemencich / public-safety-approach (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'f72c8a0c-61dd-4a86-a205-171e331fcaee' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
DELETE FROM inform.politician_context WHERE politician_id = 'f72c8a0c-61dd-4a86-a205-171e331fcaee' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- ----- 17. Michael Schaeffer / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'c7a0ecf6-b416-474b-9647-a25e404f4bc4' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = 'c7a0ecf6-b416-474b-9647-a25e404f4bc4' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 18. Tommy Baril / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '3b15d821-fc1e-4e7b-bda0-13a669a77a27' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '3b15d821-fc1e-4e7b-bda0-13a669a77a27' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 19. Angelia Pelham / civil-rights (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '5b346b19-d6ee-47e2-acbf-5780ca423264' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
DELETE FROM inform.politician_context WHERE politician_id = '5b346b19-d6ee-47e2-acbf-5780ca423264' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- ----- 20. Ernest Lynch / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'c3e2d7a6-8096-4e91-9ee0-3cca445af72e' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = 'c3e2d7a6-8096-4e91-9ee0-3cca445af72e' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 21. Geré Feltus / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 22. Geré Feltus / public-safety-approach (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
DELETE FROM inform.politician_context WHERE politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- ----- 23. Justin Beller / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 24. Justin Beller / public-safety-approach (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
DELETE FROM inform.politician_context WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- ----- 25. Michael Jones / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '09dbafc2-9252-40e4-9a1c-afda5b069f2e' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '09dbafc2-9252-40e4-9a1c-afda5b069f2e' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 26. Patrick Cloutier / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '27578980-2e6c-4639-879a-70b510566d0f' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '27578980-2e6c-4639-879a-70b510566d0f' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 27. Rick Franklin / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '6ee726c1-79af-4fef-abb8-fa7f4208ae14' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '6ee726c1-79af-4fef-abb8-fa7f4208ae14' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 28. Rick Franklin / residential-zoning (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '6ee726c1-79af-4fef-abb8-fa7f4208ae14' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
DELETE FROM inform.politician_context WHERE politician_id = '6ee726c1-79af-4fef-abb8-fa7f4208ae14' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';

-- ----- 29. Shun Thomas / homelessness (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '4272e5cb-40cf-42d9-a493-ae5ca04301bb' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
DELETE FROM inform.politician_context WHERE politician_id = '4272e5cb-40cf-42d9-a493-ae5ca04301bb' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';

-- ----- 30. Arefin Shamsul / residential-zoning (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '9f93ae55-9228-478d-84a9-971cf4686649' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
DELETE FROM inform.politician_context WHERE politician_id = '9f93ae55-9228-478d-84a9-971cf4686649' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';

-- ----- 31. Dan Barrios / homelessness (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
DELETE FROM inform.politician_context WHERE politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';

COMMIT;
