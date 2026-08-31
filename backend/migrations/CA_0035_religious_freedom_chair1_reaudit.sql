BEGIN;

-- =============================================================================
-- CA_0035: Religious Freedom — chair-1 re-audit (in-place), for the v2 axis
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: re-audit the 25 chair-1 seatings against the v2 (Axis-B) chair 1
--   ("prohibit religious exemptions from civil rights and anti-discrimination laws"),
--   CA_0030 having reframed the topic and CA_0034 having pinned v2 into Season 2.
--   Dispositions (primary-source verified 2026-08-30, recorded in
--   data/season2-carry/religious-freedom-chair1-dispositions.json):
--     11 CARRY at chair 1 (re-sourced to a primary Equality Act / authored-bill instrument)
--      1 MOVE  Rob Bonta 1 -> 2 (AG amicus accepts the ministerial exception, opposes extending it)
--     13 BLANK (only church-state-separation / non-primary evidence on the exemptions axis)
--
-- WHY IN-PLACE (changes open Season 1): the schema cannot represent "blank in Season 2,
--   seated in Season 1" — politician_answers.value is CHECK 1..5 (no 0), and the compare read
--   collapses to the newest season with no status gate, so an absent Season-2 row falls back
--   to the Season-1 seating. Blanking therefore requires deleting the shared row, which also
--   removes the person from open Season 1. Decision 2026-08-30 (Chris Andrews): apply in place,
--   CA_0033 style. These seatings were under-evidenced under v1 too (chair 1 conflated
--   church-state separation with exemptions); correcting them is right for both seasons.
--
-- Expected end state (religious-freedom answers): 1=11, 2=193, 3=80, 4=229, 5=176; 13 rows removed.
-- Idempotent: every step no-ops on re-run.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id='6b9ba6d9-1001-43f5-b073-4d37130696fd' AND topic_key='religious-freedom') THEN
    RAISE EXCEPTION 'CA_0035: religious-freedom topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id='dfbd847a-294c-49d2-9ac3-69270ea03054' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd' AND version=2) THEN
    RAISE EXCEPTION 'CA_0035: v2 revision missing';
  END IF;
END $$;

-- ── 1. Re-source keeps (chair unchanged at 1; primary instrument) ─────────────────────────────
UPDATE inform.politician_context SET
  reasoning = $r$Rep. Betty McCollum voted Aye on the Equality Act (H.R. 5, 116th Congress), On Passage, Roll Call 217 (May 17, 2019). The Equality Act bars the Religious Freedom Restoration Act from supplying a religious-exemption defense to civil-rights claims — a position against religious exemptions from anti-discrimination law.$r$,
  sources = ARRAY['https://clerk.house.gov/evs/2019/roll217.xml']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='8d4d216a-2d44-4565-b605-14b24e31207b' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Betty McCollum
UPDATE inform.politician_context SET
  reasoning = $r$Rep. Janice Schakowsky voted Aye on the Equality Act (H.R. 5, 116th Congress), On Passage, Roll Call 217 (May 17, 2019), which bars RFRA religious-exemption defenses to civil-rights claims.$r$,
  sources = ARRAY['https://clerk.house.gov/evs/2019/roll217.xml']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='4fbdecd3-3161-49da-a610-9b9312e72507' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Janice D. Schakowsky
UPDATE inform.politician_context SET
  reasoning = $r$Rep. Jared Huffman voted Aye on the Equality Act (H.R. 5, 116th Congress), On Passage, Roll Call 217 (May 17, 2019), which bars RFRA religious-exemption defenses to civil-rights claims. (Replaces the prior church-state-separation reasoning, which is a different axis.)$r$,
  sources = ARRAY['https://clerk.house.gov/evs/2019/roll217.xml']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='960e5acd-c847-4c8b-9a00-980483647849' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Jared Huffman
UPDATE inform.politician_context SET
  reasoning = $r$Rep. Nydia Velázquez voted Aye on the Equality Act (H.R. 5, 116th Congress), On Passage, Roll Call 217 (May 17, 2019), which bars RFRA religious-exemption defenses to civil-rights claims.$r$,
  sources = ARRAY['https://clerk.house.gov/evs/2019/roll217.xml']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='8fad496d-d92d-4f68-bc25-93102a4612e8' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Nydia M. Velázquez
UPDATE inform.politician_context SET
  reasoning = $r$Rep. Kelly Morrison is an original cosponsor of the Equality Act (H.R. 15, 119th Congress; sponsor Rep. Takano), cosponsored April 29, 2025 — the bill bars RFRA religious-exemption defenses to civil-rights claims.$r$,
  sources = ARRAY['https://www.congress.gov/bill/119th-congress/house-bill/15/cosponsors']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='8a0696c4-5536-4309-9d02-b0ebb61de56b' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Kelly Morrison
UPDATE inform.politician_context SET
  reasoning = $r$Sen. Mark Warner is an original cosponsor of the Equality Act (S. 1503, 119th Congress; sponsor Sen. Merkley), cosponsored April 29, 2025 — the bill bars RFRA religious-exemption defenses to civil-rights claims.$r$,
  sources = ARRAY['https://www.congress.gov/bill/119th-congress/senate-bill/1503/cosponsors']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='85d27350-e1b6-45b8-aee3-509ca88c5af4' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Mark Warner
UPDATE inform.politician_context SET
  reasoning = $r$Sen. Tim Kaine is an original cosponsor of the Equality Act (S. 1503, 119th Congress; sponsor Sen. Merkley), cosponsored April 29, 2025 — the bill bars RFRA religious-exemption defenses to civil-rights claims.$r$,
  sources = ARRAY['https://www.congress.gov/bill/119th-congress/senate-bill/1503/cosponsors']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='8cffe7a0-b56c-42fe-adbf-f57d63589973' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Tim Kaine
UPDATE inform.politician_context SET
  reasoning = $r$Rep. Sydney Kamlager-Dove is an original cosponsor of the Equality Act (H.R. 15, 119th Congress; sponsor Rep. Takano), cosponsored April 29, 2025 — the bill bars RFRA religious-exemption defenses to civil-rights claims.$r$,
  sources = ARRAY['https://www.congress.gov/bill/119th-congress/house-bill/15/cosponsors']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='a2c6adc7-7689-49b9-964f-8f2aeb243a83' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Sydney Kamlager-Dove
UPDATE inform.politician_context SET
  reasoning = $r$Rep. Ted Lieu is an original cosponsor of the Equality Act (H.R. 15, 119th Congress, April 29, 2025) and voted Yea on the Equality Act (H.R. 5, 117th Congress), On Passage, Roll Call 39 (Feb 25, 2021). The Act bars RFRA religious-exemption defenses to civil-rights claims.$r$,
  sources = ARRAY['https://www.congress.gov/bill/119th-congress/house-bill/15/cosponsors', 'https://clerk.house.gov/evs/2021/roll039.xml']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='3a39c313-b994-447b-b3fd-592e4994769b' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Ted W. Lieu
UPDATE inform.politician_context SET
  reasoning = $r$Rep. Suzanne Bonamici voted Yea on the Equality Act (H.R. 5, 117th Congress), On Passage, Roll Call 39 (Feb 25, 2021), and is an original cosponsor of H.R. 15 (119th Congress). The Act bars RFRA religious-exemption defenses to civil-rights claims. (Corrects a prior citation that pointed at Roll Call 60, which was H.R. 1280, a different bill.)$r$,
  sources = ARRAY['https://clerk.house.gov/evs/2021/roll039.xml', 'https://www.congress.gov/bill/119th-congress/house-bill/15/cosponsors']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='6ffb9093-7489-4197-aebc-67065c239fc3' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Suzanne Bonamici
UPDATE inform.politician_context SET
  reasoning = $r$As a California state senator, Ricardo Lara authored SB 1146 (2015–16), which as introduced would have removed the Title IX religious exemption for California religious colleges (later amended to a disclosure requirement), and SB 323 (2013–14), which strips state tax exemptions from youth organizations that discriminate — his own authored acts removing belief-based exemptions from anti-discrimination law.$r$,
  sources = ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201520160SB1146', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201320140SB323']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at = now()
 WHERE politician_id='bab3379b-d64e-423b-b62e-4efa04cee750' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Ricardo Lara

-- ── 2. Move: Rob Bonta chair 1 -> chair 2 ────────────────────────────────────────────────────
UPDATE inform.politician_answers SET value=2, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='8b183a30-3afb-4d9e-aa40-aa2ad2c674aa' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd' AND value=1;
UPDATE inform.politician_context SET
  reasoning = $r$As California Attorney General, Bonta joined a multistate amicus brief (Ninth Circuit en banc, March 2026) arguing there is no legal precedent to expand religious institutions' faith-based hiring right to non-ministerial positions. Accepting the ministerial exception while opposing its extension places him at protecting religious freedom without letting it override employment anti-discrimination protections (chair 2), rather than a categorical bar on exemptions (chair 1).$r$,
  sources = ARRAY['https://oag.ca.gov/news/press-releases/attorney-general-bonta-opposes-attack-against-state-law-protecting-employees']::text[],
  editor_id = '854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE politician_id='8b183a30-3afb-4d9e-aa40-aa2ad2c674aa' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';

-- ── 3. Blanks: remove the seating, rewrite context as a documented blank ──────────────────────
CREATE TEMP TABLE rf_blank(pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO rf_blank(pid, tid) VALUES
  ('a1fc524b-7c90-43c0-83a7-c76664293913','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Luz Maria Rivas
  ('00cd05cc-75de-4d9a-ab23-9f53441bc186','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Joseline Peña-Melnyk
  ('eef42ac4-5573-47c7-8b41-f2f1e0769aec','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Jay Jones
  ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Abdul El-Sayed
  ('2763b8c4-a297-4e6e-9aee-5d2e7784f3d8','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Daniel Biss
  ('60f2dcfe-1669-4dee-9c32-a285f4756569','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Melissa Bean
  ('327298e7-e42c-4dfa-9f1d-55cfd48e0659','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Taylor J. Paden
  ('a89982a7-85d2-421f-9355-c255b898899c','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Drew Cox
  ('48593795-6e01-4da0-99b3-ef522b906652','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Andy Ellis
  ('b658dc6c-aa28-49d8-9481-61ce64aeb9a2','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Jennifer Booker
  ('d36fc2e8-f76a-4f52-bc82-1ea16dacfd83','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- John Croisant
  ('27e19bcf-9501-48b5-bc08-34097fcefc70','6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Keith B. Goodenough
  ('60d485a8-17c9-4092-a666-b06c011d66e8','6b9ba6d9-1001-43f5-b073-4d37130696fd');  -- Rachel Fetty Anderson

DELETE FROM inform.politician_answers a USING rf_blank b
 WHERE a.politician_id=b.pid AND a.topic_id=b.tid;

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180AB1163']::text[],
  reasoning = $r$Researched 2026-08-30 — Rivas took office June 2018 and could not have voted on SB 1146 (2016). Her authored record (climate, homelessness, STEM, AB 1163 voluntary SOGI data collection) contains no instrument on religious exemptions vs. anti-discrimination law. Prior Courage Score / voter-guide reasoning is non-primary. Left blank.$r$
 WHERE politician_id='a1fc524b-7c90-43c0-83a7-c76664293913' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Luz Maria Rivas
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://mgaleg.maryland.gov/2012rs/bills/hb/hb0438t.pdf']::text[],
  reasoning = $r$Researched 2026-08-30 — Her concrete instruments (co-sponsoring HB 438, the 2012 Civil Marriage Protection Act, and supporting SB 212, 2014) are anti-discrimination laws that themselves grant religious exemptions; they establish direction, not a position on the exemptions axis, and if anything preserve exemptions. No primary anti-exemption instrument located. Left blank.$r$
 WHERE politician_id='00cd05cc-75de-4d9a-ab23-9f53441bc186' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Joseline Peña-Melnyk
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY[]::text[],
  reasoning = $r$Researched 2026-08-30 — Jones's one on-record act is a 2020 floor vote for the Virginia Values Act, an anti-discrimination expansion that itself preserves a religious-organization exemption (direction-only). He left the House of Delegates before the 2022 religious-freedom bill. No primary instrument on the exemptions axis; prior Washington Blade / Ballotpedia cites are non-primary. Left blank.$r$
 WHERE politician_id='eef42ac4-5573-47c7-8b41-f2f1e0769aec' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Jay Jones
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://abdulforsenate.com']::text[],
  reasoning = $r$Researched 2026-08-30 — His campaign site's only LGBTQ content is healthcare-access language (a different axis); nothing addresses the Equality Act or religious exemptions from anti-discrimination law. Prior OnTheIssues + inference is non-primary. Left blank.$r$
 WHERE politician_id='ec0cfeae-a512-4ce2-a8f2-a25b00112b9b' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Abdul El-Sayed
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://ilga.gov/documents/legislation/99/SB/PDF/09900SB0111.pdf']::text[],
  reasoning = $r$Researched 2026-08-30 — Biss sponsored the Illinois conversion-therapy ban (SB 111, 99th GA, Youth Mental Health Protection Act), but its text regulates licensed mental-health providers and contains no religious-exemption or civil-rights-exemption provision. It shows LGBTQ-protective direction via professional regulation, not a position on religious exemptions. Left blank.$r$
 WHERE politician_id='2763b8c4-a297-4e6e-9aee-5d2e7784f3d8' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Daniel Biss
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://www.melissabeanforcongress.com/issues']::text[],
  reasoning = $r$Researched 2026-08-30 — Her campaign site's 'Equality for All' pledges equal treatment in housing, employment and health care but names neither the Equality Act nor religious exemptions; her own candidate questionnaire is likewise silent. Direction-only; prior Americans United rating is non-primary. Left blank.$r$
 WHERE politician_id='60f2dcfe-1669-4dee-9c32-a285f4756569' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Melissa Bean
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://www.padenforutah.com/about']::text[],
  reasoning = $r$Researched 2026-08-30 — The only religion content on his site is church-state separation ('a Utah for all of us, not just religious leaders'), a different axis; his LGBTQ content is gender-affirming-care access. Nothing addresses religious exemptions or the Equality Act. Left blank.$r$
 WHERE politician_id='327298e7-e42c-4dfa-9f1d-55cfd48e0659' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Taylor J. Paden
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://www.drewcox.org/the-issues']::text[],
  reasoning = $r$Researched 2026-08-30 — The chair-1 basis (a pledge to 'pass the Equality Act') is not present on his own campaign site, live or in Wayback captures (Apr–Jul 2026); it traces only to BallotReady (non-primary). His site offers only bodily-autonomy (off-axis) and generic civil-rights language. No primary exemptions-axis instrument. Left blank.$r$
 WHERE politician_id='a89982a7-85d2-421f-9355-c255b898899c' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Drew Cox
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY[]::text[],
  reasoning = $r$Researched 2026-08-30 — His own campaign material states general values with no position on religious exemptions or the Equality Act; the prior basis was the national Green Party platform, which he did not personally author. IDENTITY FLAG: research surfaced a Maryland Green candidate, while this record may be for Maine — verify the person before any live write. Left blank.$r$
 WHERE politician_id='48593795-6e01-4da0-99b3-ef522b906652' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Andy Ellis
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://jenbooker.com']::text[],
  reasoning = $r$Researched 2026-08-30 — Her documented priorities are church-state separation and opposition to public funding of religious education (establishment axis); none states that religious exemptions should not override anti-discrimination law. Left blank.$r$
 WHERE politician_id='b658dc6c-aa28-49d8-9481-61ce64aeb9a2' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Jennifer Booker
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://croisantforcongress.com']::text[],
  reasoning = $r$Researched 2026-08-30 — His campaign site's priorities contain no exemptions-axis position; the prior basis was church-state separation / religion in schools, a different axis. Left blank.$r$
 WHERE politician_id='d36fc2e8-f76a-4f52-bc82-1ea16dacfd83' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- John Croisant
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY[]::text[],
  reasoning = $r$Researched 2026-08-30 — His 2026 candidate questionnaires speak only to secular government (separation axis); his Wyoming legislative service (1989–2005) predates the state's LGBTQ non-discrimination/exemption bills, so no recorded exemptions-axis vote exists. Prior 2008 OnTheIssues cite is non-primary. Left blank.$r$
 WHERE politician_id='27e19bcf-9501-48b5-bc08-34097fcefc70' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Keith B. Goodenough
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://fettyandersonforsenate.com/issues']::text[],
  reasoning = $r$Researched 2026-08-30 — Her issues page opposes establishing religious texts in schools and funding religious institutions (establishment axis); it contains no position on religious exemptions or the Equality Act. Left blank.$r$
 WHERE politician_id='60d485a8-17c9-4092-a666-b06c011d66e8' AND topic_id='6b9ba6d9-1001-43f5-b073-4d37130696fd';  -- Rachel Fetty Anderson

-- @context-decision: rewritten-as-blank — the topic applies to each person and each record WAS
-- read against primary sources on 2026-08-30; none carried a primary instrument on the
-- exemptions-vs-anti-discrimination axis (only church-state separation, non-primary ratings, or
-- direction-only votes), so each context is a documented blank naming what was checked.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate on the blanked pairs (regexes identical).
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM rf_blank t
    JOIN inform.politician_context pc ON pc.politician_id=t.pid AND pc.topic_id=t.tid
   WHERE coalesce(cardinality(pc.sources),0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'CA_0035 context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- ── 4. Post-verify ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE tid uuid := '6b9ba6d9-1001-43f5-b073-4d37130696fd'; c1 int;c2 int;c3 int;c4 int;c5 int; miss int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.politician_answers WHERE politician_id='8b183a30-3afb-4d9e-aa40-aa2ad2c674aa' AND topic_id=tid AND value=2) THEN
    RAISE EXCEPTION 'verify: Bonta not at chair 2';
  END IF;
  SELECT count(*) INTO miss FROM rf_blank b JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF miss <> 0 THEN RAISE EXCEPTION 'verify: % blanked pair(s) still have an answer row', miss; END IF;
  SELECT count(*) FILTER (WHERE value=1),count(*) FILTER (WHERE value=2),count(*) FILTER (WHERE value=3),count(*) FILTER (WHERE value=4),count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid;
  IF (c1,c2,c3,c4,c5) <> (11,193,80,229,176) THEN
    RAISE EXCEPTION 'verify: chair counts %/%/%/%/% (expected 11/193/80/229/176)', c1,c2,c3,c4,c5;
  END IF;
  RAISE NOTICE 'CA_0035 post-verify OK: 1=%/2=%/3=%/4=%/5=%; 13 blanked, Bonta->2', c1,c2,c3,c4,c5;
END $$;

COMMIT;
