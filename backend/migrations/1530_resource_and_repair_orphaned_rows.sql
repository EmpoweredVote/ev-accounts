-- 1530_resource_and_repair_orphaned_rows.sql
--
-- The last 9 rows damaged by the comma-splitting ingestion: reasoning truncated mid-sentence AND no
-- URL left anywhere in the array. 1527/1528 could not touch them because restoring the reasoning
-- alone would leave `sources` empty, and EMPTY_SOURCES is a ZERO-TOLERANCE gate class.
--   Rollback: data/stance-retirement/2026-08-01-prose-sources-rollback.json (`held`)
--   Review:   data/stance-retirement/2026-08-02-held-rows-resolution.md
--
-- Operator decision 2026-08-02: RE-SOURCE rather than retire. These are not bad research -- the claims
-- are specific, dated and checkable, and it was our pipeline that destroyed the citation, not the
-- researcher. Retiring them would delete sound work to pay for an ingestion bug.
--
-- 🔴 EVERY SOURCE BELOW WAS VERIFIED TO CARRY THE ROW'S OWN NAMED INSTRUMENTS BEFORE BEING ASSIGNED.
-- The obvious move -- "give each Maryland senator their mgaleg member page" -- IS WRONG and the check
-- is what caught it: mgaleg shows ONE SESSION, so Zucker's 2011/2013/2018/2021 bills and Feldman's
-- 2018-2021 record are ABSENT from their 2025 pages. Assigning those pages would have produced nine
-- citations that look authoritative and support nothing. Each row is pointed at the page that
-- actually contains its claims, verified by fetch:
--
--   Lam / Medicare-aid    mgaleg lam02?ys=2025RS  -> SB0111 "Step Therapy, Fail-First Protocols",
--                         SB0438 "Pharmacy Benefits Administration", SB0448 "Self-Directed Mental
--                         Health Services", SB0974 "Nonopioid Drugs for the Treatment of Pain" —
--                         all four present, all Primary sponsorship, titles matching the row.
--   Lam / Criminal Just.  same page -> SB0741 present.
--   Lam / Healthcare      clarencelam.com/meet-clarence -> "capping the cost of insulin at no more
--                         than $1 per day", "the only physician in the Maryland State Senate",
--                         "healthcare is a human right", coverage for undocumented immigrants. The
--                         mgaleg page does NOT support the insulin claim (2022 session), so this row
--                         gets the campaign biography instead. Different rows, different sources.
--   Feldman / Healthcare  en.wikipedia -> "Protect Maryland Health Care", "individual mandate",
--                         "medical debt", "Prescription Drug Affordability" all present.
--   Zucker / Civil Rights en.wikipedia -> "Civil Marriage", "death penalty", "harassment", "Raskin".
--   Valentine / Voting    mgaleg valentine01 -> HB0454 "(SAVE Our Elections Act of 2026)" and HB0964
--                         "Secure the Vote Act of 2026", both Co-Sponsor.
--   Fleming / Healthcare  ontheissues Health_Care -> "single-payer", "socialized medicine", "repeal",
--                         "takeover", "health savings".
--   Fleming / Immigration ontheissues Immigration -> "Birthright Citizenship", "ALIPAC", "welfare",
--                         and "All illegal immigrants should be deported" (summary answer D).
--   Fleming / Relig.Free. ontheissues Civil_Rights -> "Fleming co-sponsored Marriage and Religious
--                         Freedom Act" and, verbatim, "Protecting religious freedom from Government
--                         intrusion is a Government interest of the highest order"; plus
--                         Principles_+_Values for "Ten Commandments", prayer and "Christian principles".
--
-- ⚠ UNMATCHED QUOTATION MARKS ARE REPAIRED TOO. The split also ate opening quotes, leaving text like
-- `received an A" rating` and `a Government interest of the highest order" and`. A dangling CLOSING
-- quote is proof its opening was lost in the same split, so it is restored -- never invented.
--
-- ⚠ Fleming / Religious Freedom ends "advocates complete autonomy for religious organizations in how
-- they operate". That phrase appears on NO source page, because it is OUR OWN chair-5 text. It is the
-- researcher's alignment statement, not a quotation, and is left unquoted as such. This is the
-- documented "quoted compass chair label" trap -- do not go looking for it on the source.

BEGIN;

-- Clarence Lam / Healthcare
UPDATE inform.politician_context SET
  reasoning = 'Lam is the only physician in the Maryland Senate and believes healthcare is a human right. He capped insulin at $1/day, expanded Medicaid for pregnant people and undocumented immigrants, and sponsored 15+ healthcare bills in 2025 alone covering drug pricing, mental health.',
  sources = ARRAY['https://www.clarencelam.com/meet-clarence/']::text[]
 WHERE politician_id = 'fc23b939-0dfd-4968-ab19-fc1e7745e997' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

-- Clarence Lam / Medicare-aid — the rejoin closes the parenthesis the split had orphaned.
UPDATE inform.politician_context SET
  reasoning = 'Lam has repeatedly expanded Maryland Medical Assistance (Medicaid) coverage including to undocumented immigrants and sponsored multiple 2025 Medicaid bills (SB0111 step therapy, SB0438 pharmacy benefits, SB0448 self-directed mental health, SB0974 nonopioid pain drugs).',
  sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]
 WHERE politician_id = 'fc23b939-0dfd-4968-ab19-fc1e7745e997' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';

-- Clarence Lam / Criminal Justice
UPDATE inform.politician_context SET
  reasoning = 'Lam supports reducing racially biased policing, reforming mandatory minimums, eliminating crack/powder cocaine sentencing disparities, and reducing three-strikes penalties. He also sponsored forensic mental health treatment reform (SB0741 2025).',
  sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lam02?ys=2025RS']::text[]
 WHERE politician_id = 'fc23b939-0dfd-4968-ab19-fc1e7745e997' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';

-- Brian Feldman / Healthcare — mgaleg 2025RS does NOT carry these 2018-2021 bills; Wikipedia does.
UPDATE inform.politician_context SET
  reasoning = 'Feldman sponsored the Protect Maryland Health Care Act (2018) reinstating the individual mandate, established a Prescription Drug Affordability Board with price-setting power (2019), banned medical debt wage garnishment and home liens (2021), and created a $1/month health insurance pilot program for young adults.',
  sources = ARRAY['https://en.wikipedia.org/wiki/Brian_Feldman_(politician)']::text[]
 WHERE politician_id = 'd423151e-8477-470d-8f73-ba7d2092f714' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

-- Craig Zucker / Civil Rights — same reason: 2011/2013/2018/2021 bills are not on a 2025 session page.
UPDATE inform.politician_context SET
  reasoning = 'Zucker stated support for Civil Marriage Protection Act (2011), voted to repeal capital punishment (2013), sponsored sexual harassment NDA ban legislation (2018), co-sponsored Tommy Bloom Raskin crisis counselor act (2021).',
  sources = ARRAY['https://en.wikipedia.org/wiki/Craig_Zucker']::text[]
 WHERE politician_id = '82145bc2-770a-421e-a2a1-0e79aae5b643' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- William Valentine / Voting Rights
UPDATE inform.politician_context SET
  reasoning = 'Valentine co-sponsored the SAVE Our Elections Act (citizenship verification), in-person voting proof of identity, absentee ballot signature verification, and the Secure the Vote Act of 2026.',
  sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]
 WHERE politician_id = 'cdf746c1-8311-416b-9ad3-2684a83b6992' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

-- John Fleming / Healthcare — opening quote restored before "universal".
UPDATE inform.politician_context SET
  reasoning = 'Fleming explicitly opposes "universal, single-payer, government-run socialized medicine" and supports full repeal of the ACA, calling it a "federal health care takeover." He favors purely market-driven health insurance through competition and health savings accounts.',
  sources = ARRAY['https://www.ontheissues.org/House/John_Fleming_Health_Care.htm']::text[]
 WHERE politician_id = '8be7e981-77a6-4ef7-b8d7-891fd9cc26d8' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

-- John Fleming / Immigration — opening quote restored around the "A" rating.
UPDATE inform.politician_context SET
  reasoning = 'Fleming received an "A" rating from ALIPAC (Americans for Legal Immigration) for his anti-amnesty stance, co-sponsored the Birthright Citizenship Act multiple times (2009-2013) to eliminate birthright citizenship for children of undocumented immigrants, and supports mandatory deportation of those in the country illegally, removal of all welfare and benefits for undocumented immigrants.',
  sources = ARRAY['https://www.ontheissues.org/House/John_Fleming_Immigration.htm']::text[]
 WHERE politician_id = '8be7e981-77a6-4ef7-b8d7-891fd9cc26d8' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

-- John Fleming / Religious Freedom — opening quote restored, stray trailing quote removed.
UPDATE inform.politician_context SET
  reasoning = 'Fleming considers religious freedom "a Government interest of the highest order" and co-sponsored the Marriage and Religious Freedom Act to protect faith-based objections from any federal adverse action. He supports Ten Commandments displays in government buildings and courts, school prayer, and Christian principles in public life, and advocates complete autonomy for religious organizations in how they operate.',
  sources = ARRAY['https://www.ontheissues.org/House/John_Fleming_Civil_Rights.htm',
                  'https://www.ontheissues.org/House/John_Fleming_Principles_+_Values.htm']::text[]
 WHERE politician_id = '8be7e981-77a6-4ef7-b8d7-891fd9cc26d8' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';

-- John Fleming / Taxes — NOT one of the nine, and not damaged in the same way. It was caught by this
-- migration's own "must be a finished sentence" assertion, which was written too broadly (scoped to
-- the politician instead of the row) and so swept in a neighbouring row. Same ingestion family: the
-- CSV double-quote ESCAPE leaked through, leaving `Abolish the Income Tax.""` with its opening quote
-- lost. Collapsed to one quote and the opening restored. Measured corpus-wide: exactly ONE row
-- contains `""`, so this is isolated. (12 rows carry a single unmatched quote; several are repaired
-- above, and the remainder are logged as a small follow-up rather than swept in here blind.)
UPDATE inform.politician_context SET
  reasoning = 'Fleming signed the Americans for Tax Reform Taxpayer Protection Pledge against any net tax increases, co-sponsored the Fair Tax Act (H.R.25) to abolish the IRS and replace income/estate taxes with a 23% national sales tax, and supports permanent repeal of the estate tax. He stated: "My position is clear: Abolish the Income Tax."'
 WHERE politician_id = '8be7e981-77a6-4ef7-b8d7-891fd9cc26d8' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

DO $$
DECLARE v_n int;
BEGIN
  -- Not one non-URL entry may remain anywhere in the corpus: this migration closes the class.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.value <> 0 AND pc.sources IS NOT NULL
     AND EXISTS (SELECT 1 FROM unnest(pc.sources) s
                  WHERE s !~* '^https?://' AND s !~ '^[a-z0-9.-]+\.[a-z]{2,}(/|$)');
  IF v_n <> 0 THEN RAISE EXCEPTION 'NON_URL_SOURCE should be 0 after this migration, found %', v_n; END IF;

  -- ...and none of the nine may have been left sourceless, which is what blocked them until now.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE (pc.politician_id::text, pc.topic_id::text) IN (
           ('fc23b939-0dfd-4968-ab19-fc1e7745e997','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
           ('fc23b939-0dfd-4968-ab19-fc1e7745e997','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
           ('fc23b939-0dfd-4968-ab19-fc1e7745e997','9db07b16-1076-4b7d-ad89-ebe7b51f4336'),
           ('d423151e-8477-470d-8f73-ba7d2092f714','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
           ('82145bc2-770a-421e-a2a1-0e79aae5b643','0bc588c6-39e1-4084-b5de-cac909b8b762'),
           ('cdf746c1-8311-416b-9ad3-2684a83b6992','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
           ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
           ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
           ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8','6b9ba6d9-1001-43f5-b073-4d37130696fd'))
     AND coalesce(cardinality(pc.sources), 0) = 0;
  IF v_n <> 0 THEN RAISE EXCEPTION '% of the nine ended up with empty sources', v_n; END IF;

  -- Every restored reasoning must now be a finished sentence, which is the defect being repaired.
  -- 🔴 SCOPED TO THE TEN ROWS, NOT TO THE POLITICIAN. The first version matched on politician_id and
  -- failed on Fleming/Taxes -- a neighbouring row this migration was not repairing. That is the same
  -- over-broad-assertion mistake 1524 made, and both times it found a real defect, so the answer is
  -- to narrow the check AND fix what it found (above), never to narrow it and walk away.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE (pc.politician_id::text, pc.topic_id::text) IN (
           ('fc23b939-0dfd-4968-ab19-fc1e7745e997','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
           ('fc23b939-0dfd-4968-ab19-fc1e7745e997','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
           ('fc23b939-0dfd-4968-ab19-fc1e7745e997','9db07b16-1076-4b7d-ad89-ebe7b51f4336'),
           ('d423151e-8477-470d-8f73-ba7d2092f714','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
           ('82145bc2-770a-421e-a2a1-0e79aae5b643','0bc588c6-39e1-4084-b5de-cac909b8b762'),
           ('cdf746c1-8311-416b-9ad3-2684a83b6992','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
           ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
           ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
           ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
           ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8','f7e5678d-dadd-4556-a2fc-446e24642ceb'))
     AND pc.reasoning !~ '[.!?]["'')\]]?\s*$';
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) still end mid-sentence', v_n; END IF;

  -- And no doubled CSV quote-escape may survive anywhere.
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE reasoning LIKE '%""%';
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) still contain a doubled quote escape', v_n; END IF;
END $$;

COMMIT;
