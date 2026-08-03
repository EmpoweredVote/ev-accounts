-- 1541_restore_pretenure_chairs_from_affirmative_evidence.sql
--
-- Restore 9 of the 36 stance rows retired by migration 1537, on new evidence. 1537 deleted rows that
-- credited members of Congress with votes cast before they held the office; it did not decide whether
-- the chairs were right, and its own header says "ALL 39 TOPICS ARE OWED RE-RESEARCH: the chairs may
-- well be right, but the evidence cited for them was not." This is that re-research, for the 9 pairs
-- where affirmative evidence supports exactly one chair.
--
--   Reviews:  data/stance-research/pretenure-reresearch/ADJUDICATION-TRANCHE-1.md
--             data/stance-research/pretenure-reresearch/ADJUDICATION-TRANCHE-2.md
--             data/stance-research/pretenure-reresearch/ADJUDICATION-TRANCHE-3.md
--             data/stance-research/pretenure-reresearch/AFFIRMATIVE-SOURCE.md
--   Evidence: data/stance-research/pretenure-reresearch/affirmative-candidates.json
--             (adjudication.verdicts — all 36 pairs, with the basis for each)
--   Rollback: DELETE the 9 (politician_id, topic_id) pairs listed below from inform.politician_answers
--             and inform.politician_context. No prior state is overwritten — every target pair is
--             currently ABSENT from both tables, verified in the pre-flight guard below, because 1537
--             deleted them. That makes this migration exactly reversible without a capture file.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1541_...sql` from C:/EV-Accounts/backend.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY THESE 9 AND NOT THE OTHER 27
-- ---------------------------------------------------------------------------------------------------
-- All 36 retired pairs were adjudicated. 9 support a chair; 22 are blank; 5 were settled blank in
-- tranche 1. The standard for assigning a chair, applied uniformly and stated so it can be argued with:
--   (a) a SPONSORSHIP or a repeated ORIGINAL co-sponsorship -- never a late co-sponsorship alone, which
--       members add for courtesy and constituency reasons; and
--   (b) a multi-clause textual match to exactly one chair, with the ADJACENT chair's distinguishing
--       clause absent or contradicted.
-- Everything else is left blank under the standing rule in gen-topic-scale.mjs: "If two adjacent chairs
-- both fit, SKIP the topic." A blank spoke is a correct outcome, not a gap.
--
-- 🔴 5 OF THE 9 CHANGE THE RETIRED VALUE. These are not restorations of what was there before:
--   Hoyle / Affordable Housing        1.0 -> 3
--   Hoyle / Campaign Finance Reform   1.0 -> 3
--   Hoyle / Civil Rights              1.0 -> 2
--   Salinas / Voting Rights           1.0 -> 2
--   Collins / Civil Rights            3.0 -> 5
-- Collins is the only correction in the whole workstream that makes a stored position MORE extreme.
-- The retired row understated him: he is an original co-sponsor, twice, of a bill that would bar
-- race-conscious measures across the entire federal government.
--
-- ---------------------------------------------------------------------------------------------------
-- EVERY CITATION WAS FETCHED AND ITS CONTENT READ
-- ---------------------------------------------------------------------------------------------------
-- Sources are govinfo bill-text URLs, each fetched and confirmed to contain the expected bill number
-- AND title before being written here. That matters twice over:
--   ⚠ A 200 IS NOT CONFIRMATION. BILLS-118hjres25rh/eh/enr all return HTTP 200 with 44,164 bytes that
--     strip to zero text -- an error page served as success. Only the `ih` package holds the
--     resolution. Three other packages 302'd. The version suffix cannot be assumed.
--   ⚠ The bill identity was matched from govinfo BILLSTATUS bulk data on bioguideId, never on surname,
--     and every sponsorship role below is read from that data rather than from a member's own website.
-- Roles: SPONSOR = filed the bill. ORIGINAL CO-SPONSOR = signed at introduction (isOriginalCosponsor).
--
-- NO last_stances_researched_at IS TOUCHED. It is populated on well under 1% of the corpus, 1537 left
-- it alone, and setting it on 9 rows would imply a per-politician sweep that did not happen.

BEGIN;

CREATE TEMP TABLE _restore_1541 (
  politician_id uuid,
  topic_id      uuid,
  value         numeric,
  reasoning     text,
  sources       text[],
  who           text,
  what          text,
  retired_chair text
) ON COMMIT DROP;

INSERT INTO _restore_1541 (politician_id, topic_id, value, reasoning, sources, who, what, retired_chair) VALUES

-- 1 ── Ayanna Pressley / Taxation and Public Spending — chair 1 (retired 1.0, CONFIRMED)
('c61baf45-dc2a-4d78-b4b7-21b1e9d79464', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1,
 'Pressley is the lead sponsor of the American Opportunity Accounts Act, filed in three consecutive Congresses, which would create a federally funded savings account for every American child and pay for it with revenue provisions that raise the top estate tax rate, add brackets for estates over $10 million, increase the capital gains rate, and treat gains as realized at gift or death. Sponsoring the bill rather than signing it, three times over, makes this an affirmative commitment rather than a courtesy signature. Pairing significant new taxes on inherited wealth with a new universal program is what distinguishes this position from moderate increases that fund existing services.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-116hr3922ih/html/BILLS-116hr3922ih.htm'],
 'Ayanna Pressley', 'Taxation and Public Spending', '1.0'),

-- 2 ── Ayanna Pressley / Criminal Justice Approach — chair 1 (retired 1.0, CONFIRMED)
('c61baf45-dc2a-4d78-b4b7-21b1e9d79464', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1,
 'Pressley sponsored the Federal Death Penalty Prohibition Act, which would bar any federal death sentence and require the resentencing of everyone currently under one, and was an original co-sponsor of the MORE Act, which decriminalizes marijuana federally and provides for expungement and community reinvestment. Her wider record runs in the same direction: sentence review, record sealing, ending money bail, and a constitutional amendment repealing the punishment exception to the Thirteenth Amendment. That is a rehabilitative and second-chance approach rather than one that delivers accountability by other means such as treatment, community service, or restitution.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-117hr262ih/html/BILLS-117hr262ih.htm',
       'https://www.govinfo.gov/content/pkg/BILLS-116hr3884ih/html/BILLS-116hr3884ih.htm'],
 'Ayanna Pressley', 'Criminal Justice Approach', '1.0'),

-- 3 ── Guy Reschenthaler / Taxation and Public Spending — chair 4 (retired 4.0, CONFIRMED)
('6840c7e6-2169-43a4-8490-1e73c8704cbd', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4,
 'Reschenthaler was an original co-sponsor of the Death Tax Repeal Act, which repeals the estate and generation-skipping transfer taxes, and of the Main Street Tax Certainty Act, which makes the deduction for qualified business income permanent. He was also an original co-sponsor of the Family and Small Business Taxpayer Protection Act, which rescinds the unobligated Internal Revenue Service balances appropriated by the Inflation Reduction Act, supplying the scaled-back-services half of the position. A more absolute anti-government position is not supported: nothing in his record proposes a balanced budget amendment, a flat or consumption tax, or a statutory spending cap, and he co-sponsored repeated expansions of the low-income housing tax credit.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-117hr1712ih/html/BILLS-117hr1712ih.htm',
       'https://www.govinfo.gov/content/pkg/BILLS-117hr1381ih/html/BILLS-117hr1381ih.htm',
       'https://www.govinfo.gov/content/pkg/BILLS-118hr23eh/html/BILLS-118hr23eh.htm'],
 'Guy Reschenthaler', 'Taxation and Public Spending', '4.0'),

-- 4 ── Val Hoyle / Reproductive Rights and Abortion Access — chair 1 (retired 1.0, CONFIRMED)
('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1,
 'Hoyle was an original co-sponsor of the EACH Act, which would require Medicaid, Medicare and CHIP to cover abortion, repeal the provisions letting states bar coverage in exchange plans, and permit premium tax credits to pay for it. She was also an original co-sponsor of the Women''s Health Protection Act, which bars governmental restrictions on abortion before viability and permits it afterward where a patient''s life or health requires it. Public funding is the element that separates this position from one that keeps abortion legal and accessible without paying for it, and the EACH Act is an affirmative commitment to it.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118hr561ih/html/BILLS-118hr561ih.htm',
       'https://www.govinfo.gov/content/pkg/BILLS-118hr12ih/html/BILLS-118hr12ih.htm'],
 'Val Hoyle', 'Reproductive Rights and Abortion Access', '1.0'),

-- 5 ── Val Hoyle / Affordable Housing — chair 3 🔴 CHANGES the retired value (1.0 -> 3)
('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '669cac97-66a6-4087-b036-936fbe62efb3', 3,
 'Hoyle is the lead sponsor of the DASH Act, which expands the low-income housing tax credit, creates a credit of up to $15,000 for first-time homebuyers, funds vouchers and modular construction grants, and encourages local zoning and planning that permit multi-family housing. Those are precisely targeted subsidies for affordable projects, first-time buyer assistance, and easier permitting, and she reinforced the last of the three by co-sponsoring the YIMBY Act. A position of directly building and operating public housing is not supported: the DASH Act works through vouchers, tax credits and grants to other builders rather than through government construction.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118hr6970ih/html/BILLS-118hr6970ih.htm'],
 'Val Hoyle', 'Affordable Housing', '1.0'),

-- 6 ── Val Hoyle / Campaign Finance Reform — chair 3 🔴 CHANGES the retired value (1.0 -> 3)
('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '92730f69-ae57-401c-8ad1-2d07834a895d', 3,
 'Hoyle was an original co-sponsor of the DISCLOSE Act in two consecutive Congresses, which would require organizations that spend on elections to disclose their large donors and report independent expenditures. Full disclosure is what that bill does; it does not cap or ban corporate and dark-money spending, so a stricter limiting position is not established by it. Her co-sponsorship of the Freedom to Vote Act touches small-dollar public financing, but an omnibus democracy bill does not establish a commitment to banning private money in politics outright.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118hr1118ih/html/BILLS-118hr1118ih.htm',
       'https://www.govinfo.gov/content/pkg/BILLS-119hr7802ih/html/BILLS-119hr7802ih.htm'],
 'Val Hoyle', 'Campaign Finance Reform', '1.0'),

-- 7 ── Val Hoyle / Civil Rights and Social Justice — chair 2 🔴 CHANGES the retired value (1.0 -> 2)
('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2,
 'Hoyle was an original co-sponsor of the Equality Act, which extends the Civil Rights Act''s protections to sexual orientation and gender identity across employment, housing, credit and public accommodations, and of the joint resolution removing the ratification deadline for the Equal Rights Amendment. Both are commitments to strengthening civil rights enforcement and addressing systemic discrimination. A stronger position requiring mandated equity requirements across institutions and the provision of reparations is not supported: no such bill appears in her record, and her only reparations item is a later co-sponsorship of a commission to study the question rather than to act on it.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118hr15ih/html/BILLS-118hr15ih.htm',
       'https://www.govinfo.gov/content/pkg/BILLS-118hjres25ih/html/BILLS-118hjres25ih.htm'],
 'Val Hoyle', 'Civil Rights and Social Justice', '1.0'),

-- 8 ── Andrea Salinas / Voting Rights and Electoral Integrity — chair 2 🔴 CHANGES the value (1.0 -> 2)
('5f6c498b-87dd-48fe-b744-62c8dced2ac3', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2,
 'Salinas is the lead sponsor of the Universal Right To Vote by Mail Act, which would bar states from imposing any condition on casting a mail ballot in a federal election beyond deadlines for requesting and returning it, and would require notice and an opportunity to cure defects. That is no-excuse mail voting for every voter, sponsored as a standalone bill rather than carried inside an omnibus. A stronger position additionally requires automatic registration of all eligible citizens and online voting; her automatic-registration support is only a later co-sponsorship of the Freedom to Vote Act, and no bill before Congress authorizes voting online.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119hr738ih/html/BILLS-119hr738ih.htm'],
 'Andrea Salinas', 'Voting Rights and Electoral Integrity', '1.0'),

-- 9 ── Mike Collins / Civil Rights and Social Justice — chair 5 🔴 CHANGES the value (3.0 -> 5)
('b6542655-fc71-4b18-a022-6528522cdcae', '0bc588c6-39e1-4084-b5de-cac909b8b762', 5,
 'Collins was an original co-sponsor of the Dismantle DEI Act in two consecutive Congresses. The bill amends the Civil Rights Act of 1964 to define a prohibited practice as discriminating for or against any person on the basis of race, color, ethnicity, religion, sex or national origin, and applies that prohibition to federal personnel and training, contracts above $10,000, grants and cooperative agreements, advisory committees, education accreditation, the housing finance agencies, capital markets, and the Departments of Health and Human Services, Defense and Homeland Security, enforced through a private right of action. Barring race-conscious measures across the federal government goes further than narrowing civil rights enforcement to clear cases of discrimination.',
 ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119hr925ih/html/BILLS-119hr925ih.htm',
       'https://www.govinfo.gov/content/pkg/BILLS-118hr8706ih/html/BILLS-118hr8706ih.htm'],
 'Mike Collins', 'Civil Rights and Social Justice', '3.0');

-- ---- pre-flight ------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_bad text;
BEGIN
  SELECT count(*) INTO v_n FROM _restore_1541;
  IF v_n <> 9 THEN RAISE EXCEPTION 'expected 9 rows staged, found %', v_n; END IF;

  -- The people must be who the adjudication says they are. ⚠ Cliff Bentz appeared in 0 of 277 roll
  -- calls because a bioguide was recalled from memory instead of derived; identifiers get checked now.
  SELECT string_agg(r.who || ' / ' || COALESCE(p.full_name, '(no such politician)'), '; ') INTO v_bad
    FROM _restore_1541 r LEFT JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE p.id IS NULL OR p.full_name <> r.who;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'politician_id does not match the expected name: %', v_bad; END IF;

  -- Topics must exist and be live, or the row would be written where nothing can display it.
  SELECT string_agg(r.what || ' / ' || COALESCE(t.title, '(no such topic)'), '; ') INTO v_bad
    FROM _restore_1541 r LEFT JOIN inform.compass_topics t ON t.id = r.topic_id
   WHERE t.id IS NULL OR t.title <> r.what OR t.is_live IS NOT TRUE;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'topic_id missing, mistitled, or not live: %', v_bad; END IF;

  -- 🔴 Every target must be ABSENT. 1537 deleted these rows; if any exists, either 1537 was rolled
  -- back or another session has written a chair here, and this migration would be silently overwriting
  -- someone else's work. It inserts; it must never clobber.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _restore_1541 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'expected 0 existing answers for the 9 target pairs, found % — do not overwrite', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context c
    JOIN _restore_1541 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'expected 0 existing context rows for the 9 target pairs, found %', v_n; END IF;

  -- Chairs are discrete 1-5. The table's CHECK also permits half-steps (0.5 increments), which is how
  -- 63 fractional stances once reached production; nothing here may add another.
  SELECT string_agg(r.who || ' / ' || r.what || ' = ' || r.value, '; ') INTO v_bad
    FROM _restore_1541 r WHERE r.value <> round(r.value) OR r.value < 1 OR r.value > 5;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'non-integer or out-of-range chair: %', v_bad; END IF;

  -- Every row must carry reasoning and at least one source. A chair with no citation is the defect
  -- this whole workstream exists to remove.
  SELECT string_agg(r.who || ' / ' || r.what, '; ') INTO v_bad
    FROM _restore_1541 r
   WHERE COALESCE(btrim(r.reasoning), '') = '' OR COALESCE(array_length(r.sources, 1), 0) = 0;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'row without reasoning or sources: %', v_bad; END IF;

  -- Sources must be absolute https URLs; a bare path or a composed fragment is how 1,166 citations
  -- came to point at pages that never existed.
  SELECT string_agg(DISTINCT s, '; ') INTO v_bad
    FROM _restore_1541 r, unnest(r.sources) AS s WHERE s NOT LIKE 'https://%';
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'non-absolute source URL: %', v_bad; END IF;
END $$;

-- ---- record the pre-insert per-person totals, to assert the delta afterwards ------------------------
CREATE TEMP TABLE _before_1541 AS
SELECT r.politician_id, r.who, count(a.topic_id) AS n_before
  FROM (SELECT DISTINCT politician_id, who FROM _restore_1541) r
  LEFT JOIN inform.politician_answers a ON a.politician_id = r.politician_id
 GROUP BY r.politician_id, r.who;

-- ---- insert ----------------------------------------------------------------------------------------
INSERT INTO inform.politician_answers (politician_id, topic_id, value, write_in_text)
SELECT politician_id, topic_id, value, NULL FROM _restore_1541;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, topic_id, reasoning, sources FROM _restore_1541;

-- ---- verify ----------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_bad text;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _restore_1541 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id
   WHERE a.value = r.value;
  IF v_n <> 9 THEN RAISE EXCEPTION 'expected 9 answers at the adjudicated chair, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context c
    JOIN _restore_1541 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id
   WHERE c.reasoning = r.reasoning AND c.sources = r.sources;
  IF v_n <> 9 THEN RAISE EXCEPTION 'expected 9 context rows written verbatim, found %', v_n; END IF;

  -- The standing invariant: no answer may exist without a context row to explain it.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'found % answers with no context row', v_n; END IF;

  -- Each person must gain exactly the number of pairs staged for them, and nothing else may move.
  SELECT string_agg(x.who || ': ' || x.n_before || ' -> ' || x.n_after || ' (expected +' || x.n_staged || ')', '; ')
    INTO v_bad
    FROM (
      SELECT b.who, b.n_before,
             (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = b.politician_id) AS n_after,
             (SELECT count(*) FROM _restore_1541 r WHERE r.politician_id = b.politician_id) AS n_staged
        FROM _before_1541 b
    ) x
   WHERE x.n_after <> x.n_before + x.n_staged;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'per-person answer count moved unexpectedly: %', v_bad; END IF;

  -- Nobody may be left with a fractional chair anywhere, including rows this migration did not touch.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _restore_1541 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id
   WHERE a.value <> round(a.value);
  IF v_n <> 0 THEN RAISE EXCEPTION 'wrote % fractional chairs', v_n; END IF;
END $$;

-- Post-apply report. Expected: Pressley 39->41, Reschenthaler 14->15, Hoyle 3->7, Salinas 7->8,
-- Collins 13->14, and 9 rows listed.
SELECT b.who, b.n_before,
       (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = b.politician_id) AS n_after
  FROM _before_1541 b ORDER BY b.who;

SELECT r.who, r.what, r.retired_chair AS was, a.value AS now,
       array_length(c.sources, 1) AS n_sources
  FROM _restore_1541 r
  JOIN inform.politician_answers a ON a.politician_id = r.politician_id AND a.topic_id = r.topic_id
  JOIN inform.politician_context c ON c.politician_id = r.politician_id AND c.topic_id = r.topic_id
 ORDER BY r.who, r.what;

COMMIT;
