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
-- 19 more rows characterized as adjacency-only (Class B2).
--
-- THIS MIGRATION DELETES ONLY. It creates, raises, lowers, or re-reasons NO stance value.
-- Every DELETE is idempotent (WHERE politician_id = ... AND topic_id = ..., 0-or-1 rows,
-- errors on nothing already gone) and every deleted answer row is paired with its context
-- row for the same (politician_id, topic_id) — never one without the other.
--
-- Party affiliation is quoted below in exactly two places (Barrios) solely because naming
-- a party in stored reasoning text is itself the defect being removed — the one legitimate
-- use, mirroring 222-01-INTEGRITY-AUDIT.md's own framing.
--
-- ---------------------------------------------------------------------------------------
-- REVISION 2026-07-25 (orchestrator, at the Task 3 checkpoint — supersedes revision 1)
-- ---------------------------------------------------------------------------------------
-- Revision 1 of this file targeted all 31 rows (12 Class A + all 19 Class B2). The
-- authoring session had no DB access and so could not read the 19 Class B2 rows' actual
-- stored reasoning; it applied the plan's uncertainty tie-breaker and marked all 19 DELETE,
-- explicitly flagging that a reader with DB access should re-decide them per-row. That
-- re-read has now been done against the live reasoning/sources text.
--
-- OUTCOME: 4 of the 19 Class B2 rows CLEAR the D-04 bar and are REMOVED from this
-- migration (kept in production). 15 are confirmed DELETE. 2 of those 15 turned out to be
-- Class-A-grade rather than mere adjacency and are re-labelled below.
--
-- NEW TOTAL: 27 pairs (12 Class A + 15 Class B2-confirmed), 19 distinct people.
--
-- KEPT — removed from this migration, these 4 cite an explicit on-topic action by the
-- named person and therefore satisfy D-04:
--   * Michael Schaeffer  | c7a0ecf6-b416-474b-9647-a25e404f4bc4 | economic-development
--       Reasoning cites his own dated recorded vote: approved the Kalahari Resort ($950M)
--       performance-based incentive deal, Feb 2025. A specific, dated, on-topic vote.
--   * Michael Jones      | 09dbafc2-9252-40e4-9a1c-afda5b069f2e | economic-development
--       Reasoning carries a verbatim first-person commitment: "welcoming businesses to move
--       to McKinney, decreasing property tax rates and encouraging companies with higher
--       paying jobs to join our community." Explicit and on-topic.
--   * Rick Franklin      | 6ee726c1-79af-4fef-abb8-fa7f4208ae14 | residential-zoning
--       Reasoning cites his own zoning votes (incl. affordable workforce apartments, 2019)
--       AND his own quote calling an 11-acre apartment development one of the "worst ones"
--       he'd seen for density. Own votes + own on-topic quote.
--   * Arefin Shamsul     | 9f93ae55-9228-478d-84a9-971cf4686649 | residential-zoning
--       Reasoning cites a dated attributed statement — April 2025 LWV Forum — endorsing the
--       Comprehensive Plan's "small housing and missing middle housing" provisions as
--       positive steps. Dated, attributed, on-topic.
--   (Note Shamsul's civil-rights row is still deleted below — different row, A3 defect.)
--
-- RE-LABELLED — deleted as Class-A-grade, not adjacency:
--   * Amy Gnadt / housing — reasoning self-admits "No housing-specific statements found"
--       and then states the chair is "the default moderate-conservative suburban position."
--       An explicitly defaulted stance = stance_no_default_value violation (A1-grade).
--   * Dan Barrios / homelessness — reasoning derives the chair from "his progressive
--       Democratic lean" and admits "No direct policy statement on public camping found."
--       Party-based inference + self-admitted absence of evidence (A2/A4-grade).
--
-- =====================================================================================
-- CLASS A — 12 rows — confirmed DELETE
-- =====================================================================================
--  1. A1 | Celina     | Ryan Tubbs          | cb9d6924-77d1-49c9-ab3d-778b0201e623 | housing            | 669cac97-66a6-4087-b036-936fbe62efb3
--       Chair assigned despite reasoning admitting "no public record found"; sources NULL.
--       Part of the 2026-05-11 batch that defaulted housing regardless of evidence.
--  2. A1 | Frisco     | Burt Thakur         | c11bf372-8190-4b45-b80a-cbd0fb2ba401 | housing            | 669cac97-66a6-4087-b036-936fbe62efb3
--       Same A1 batch pattern — no-record-found admission, sources NULL, chair defaulted.
--  3. A1 | Plano      | Chris Krupa Downs   | 127b8e69-3900-438c-8361-2cfe24b6c6cf | housing            | 669cac97-66a6-4087-b036-936fbe62efb3
--       Verbatim: "no specific record found of Downs stating a position on affordable
--       housing policy... Assumed..." — textbook A1.
--  4. A1 | Plano      | Chris Krupa Downs   | 127b8e69-3900-438c-8361-2cfe24b6c6cf | residential-zoning | d4f18138-a2e0-4110-b925-7387d9d0d16d
--       Same 2026-05-11 A1 pattern; no evidence of Downs's own zoning position.
--  5. A1 | Plano      | Shun Thomas         | 4272e5cb-40cf-42d9-a493-ae5ca04301bb | housing            | 669cac97-66a6-4087-b036-936fbe62efb3
--       Same A1 batch pattern — no record found, sources NULL, chair defaulted.
--  6. A2 | Richardson | Dan Barrios         | e8c863a7-d116-480e-a81f-47d26f45e264 | civil-rights       | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Verbatim names party — "Barrios is a Democrat running for Congress on a platform of
--       'fairness, accountability, and common sense'..." Stance from party/platform framing,
--       not an on-topic personal position. Violates the antipartisan rule and D-04.
--  7. A3 | Plano      | Vidal Quintanilla   | 5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f | civil-rights       | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Identity/board-membership inference; no explicit on-topic civil-rights statement.
--  8. A3 | Plano      | Vidal Quintanilla   | 5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f | local-immigration  | b9ccee94-ad96-4f10-b655-889d8e5abe92
--       Verbatim: "Quintanilla, a Mexican American born in the Rio Grande Valley border
--       region..." — stance inferred from ethnicity/birthplace.
--  9. A3 | Richardson | Amir Omar           | e9b9877d-c4dc-482e-b52a-cd015a4a6850 | civil-rights       | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Verbatim: "...a first-generation American of Palestinian and Iranian descent and the
--       first Muslim mayor of a DFW city..." — stance inferred from ethnicity/religion.
-- 10. A3 | Richardson | Arefin Shamsul      | 9f93ae55-9228-478d-84a9-971cf4686649 | civil-rights       | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Same A3 identity/civic-adjacency pattern; no explicit on-topic statement.
-- 11. A4 | Plano      | John B. Muns        | 5584e869-4a54-4a68-a3c8-c14db45a71c5 | local-immigration  | b9ccee94-ad96-4f10-b655-889d8e5abe92
--       Chair defaulted from Plano's city-wide SB4 posture rather than Muns's own words.
-- 12. A4 | Plano      | Maria Tu            | d6bf8d34-5a59-419a-8ed7-9c9b4d865799 | local-immigration  | b9ccee94-ad96-4f10-b655-889d8e5abe92
--       Verbatim: "Plano operates under Texas SB4 (2017)... Tu has made no public statements
--       advocating ei..." — chair defaulted from city-wide law, not her own statement.
--
-- =====================================================================================
-- CLASS B2 — 15 of 19 confirmed DELETE after per-row re-read against live reasoning
-- =====================================================================================
-- 13. A1-grade | Allen | Amy Gnadt         | b0a9801c-7f9d-4d7b-99f5-09360cf69c08 | housing                | 669cac97-66a6-4087-b036-936fbe62efb3
--       "No housing-specific statements found... the default moderate-conservative suburban
--       position." Explicitly defaulted — re-labelled A1-grade.
-- 14. B2 | Allen      | Amy Gnadt           | b0a9801c-7f9d-4d7b-99f5-09360cf69c08 | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85
--       Chair from city-wide budget history + "supports public services"; reasoning states no
--       co-responder or reallocation statements found. Adjacency only.
-- 15. B2 | Allen      | Amy Gnadt           | b0a9801c-7f9d-4d7b-99f5-09360cf69c08 | residential-zoning     | d4f18138-a2e0-4110-b925-7387d9d0d16d
--       "supports 'smart growth' without specific zoning advocacy found"; chair rests on the
--       city's adopted framework plus generic unanimous rezoning votes. Adjacency only.
-- 16. B2 | Allen      | Carl Clemencich     | f72c8a0c-61dd-4a86-a205-171e331fcaee | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85
--       Pure tenure adjacency — police HQ approved "during" his term; no personal position.
-- 17. B2 | Allen      | Tommy Baril         | 3b15d821-fc1e-4e7b-bda0-13a669a77a27 | economic-development   | eb3d1247-0de1-4b7f-baec-7259861efd53
--       Board presidency + generic "fiscally prudent" quote; reasoning itself notes he was
--       ABSENT from the one on-topic incentive vote. Adjacency only.
-- 18. B2 | Frisco     | Angelia Pelham      | 5b346b19-d6ee-47e2-acbf-5780ca423264 | civil-rights           | 0bc588c6-39e1-4084-b5de-cac909b8b762
--       Extensive civic/nonprofit work, but reasoning states "no specific policy mandates...
--       or systemic reform proposals at the council level were found." Adjacency only.
-- 19. B2 | McKinney   | Ernest Lynch        | c3e2d7a6-8096-4e91-9ee0-3cca445af72e | economic-development   | eb3d1247-0de1-4b7f-baec-7259861efd53
--       Quote is real but generic ("policies that support businesses of all sizes"); does not
--       locate the incentive-aggressiveness chair it was used to set.
-- 20. B2 | McKinney   | Geré Feltus         | 23ba75d2-6eed-4b71-9669-78ab3bb82e98 | economic-development   | eb3d1247-0de1-4b7f-baec-7259861efd53
--       Board membership + "suggesting"/"indicating" chain of inference. Adjacency only.
-- 21. B2 | McKinney   | Geré Feltus         | 23ba75d2-6eed-4b71-9669-78ab3bb82e98 | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85
--       "public safety is my top priority" does not distinguish this chair from its
--       neighbour, and the reasoning cites a vote pointing the other way. Not explicit.
-- 22. B2 | McKinney   | Justin Beller       | bcdbeae4-04c9-4ea1-8942-bac3ce1a8723 | economic-development   | eb3d1247-0de1-4b7f-baec-7259861efd53
--       Profession + bond-committee service + "suggests" inference. Adjacency only.
-- 23. B2 | McKinney   | Justin Beller       | bcdbeae4-04c9-4ea1-8942-bac3ce1a8723 | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85
--       Cites real dated votes, but they are HOMELESSNESS-criminalization votes used to set a
--       PUBLIC-SAFETY chair — cross-topic inference, not on-topic evidence.
-- 24. B2 | McKinney   | Michael Jones       | -- KEPT, see revision note above --
-- 25. B2 | McKinney   | Patrick Cloutier    | 27578980-2e6c-4639-879a-70b510566d0f | economic-development   | eb3d1247-0de1-4b7f-baec-7259861efd53
--       Board membership + profession + "aligned with". Adjacency only.
-- 26. B2 | McKinney   | Rick Franklin       | 6ee726c1-79af-4fef-abb8-fa7f4208ae14 | economic-development   | eb3d1247-0de1-4b7f-baec-7259861efd53
--       Board membership + profession; "actively supports" asserted without quote or vote.
--       (His residential-zoning row is KEPT — see revision note.)
-- 27. B2 | Plano      | Shun Thomas         | 4272e5cb-40cf-42d9-a493-ae5ca04301bb | homelessness           | 4938766b-b45a-46e3-93bd-b8b30651271a
--       Real campaign pledge quote, but about "wrap-around services for residents in need"
--       generally — not an on-topic position on public camping / homelessness response.
-- 28. A2/A4-grade | Richardson | Dan Barrios | e8c863a7-d116-480e-a81f-47d26f45e264 | homelessness          | 4938766b-b45a-46e3-93bd-b8b30651271a
--       "combined with his progressive Democratic lean — suggests..." plus "No direct policy
--       statement on public camping found." Party inference + admitted absence of evidence.
--
-- TOTAL: 27 (politician_id, topic_id) pairs deleted — 12 Class A + 15 Class B2-confirmed.
-- Distinct people affected: 19 (Ryan Tubbs, Burt Thakur, Chris Krupa Downs, Shun Thomas,
-- Dan Barrios, Vidal Quintanilla, Amir Omar, Arefin Shamsul, John B. Muns, Maria Tu,
-- Amy Gnadt, Carl Clemencich, Tommy Baril, Angelia Pelham, Ernest Lynch, Geré Feltus,
-- Justin Beller, Patrick Cloutier, Rick Franklin).
-- KEPT in production: 4 rows / 4 people (Schaeffer, Jones, Franklin-zoning, Shamsul-zoning).
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

-- ----- 13. Amy Gnadt / housing (A1-grade — explicitly defaulted) -----
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

-- ----- 17. Tommy Baril / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '3b15d821-fc1e-4e7b-bda0-13a669a77a27' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '3b15d821-fc1e-4e7b-bda0-13a669a77a27' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 18. Angelia Pelham / civil-rights (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '5b346b19-d6ee-47e2-acbf-5780ca423264' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
DELETE FROM inform.politician_context WHERE politician_id = '5b346b19-d6ee-47e2-acbf-5780ca423264' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- ----- 19. Ernest Lynch / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'c3e2d7a6-8096-4e91-9ee0-3cca445af72e' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = 'c3e2d7a6-8096-4e91-9ee0-3cca445af72e' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 20. Geré Feltus / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 21. Geré Feltus / public-safety-approach (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
DELETE FROM inform.politician_context WHERE politician_id = '23ba75d2-6eed-4b71-9669-78ab3bb82e98' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- ----- 22. Justin Beller / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 23. Justin Beller / public-safety-approach (B2 — cross-topic inference) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
DELETE FROM inform.politician_context WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- ----- 24. Patrick Cloutier / economic-development (B2) -----
DELETE FROM inform.politician_answers WHERE politician_id = '27578980-2e6c-4639-879a-70b510566d0f' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '27578980-2e6c-4639-879a-70b510566d0f' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 25. Rick Franklin / economic-development (B2) -----
--        (Franklin's residential-zoning row is intentionally NOT deleted — it clears D-04.)
DELETE FROM inform.politician_answers WHERE politician_id = '6ee726c1-79af-4fef-abb8-fa7f4208ae14' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
DELETE FROM inform.politician_context WHERE politician_id = '6ee726c1-79af-4fef-abb8-fa7f4208ae14' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- ----- 26. Shun Thomas / homelessness (B2 — off-topic quote) -----
DELETE FROM inform.politician_answers WHERE politician_id = '4272e5cb-40cf-42d9-a493-ae5ca04301bb' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
DELETE FROM inform.politician_context WHERE politician_id = '4272e5cb-40cf-42d9-a493-ae5ca04301bb' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';

-- ----- 27. Dan Barrios / homelessness (A2/A4-grade — party inference + no statement) -----
DELETE FROM inform.politician_answers WHERE politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
DELETE FROM inform.politician_context WHERE politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';

COMMIT;
