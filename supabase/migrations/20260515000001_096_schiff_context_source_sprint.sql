-- Source quality sprint for Adam Schiff (politician_id: 8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032)
-- Fills sources + tightened reasoning for 6 gap topics (no duplicate stale rows found).

-- Abortion
UPDATE inform.politician_context
SET
  reasoning = 'Schiff voted for the Women''s Health Protection Act to codify Roe v. Wade, releasing a statement condemning the Senate''s failure to advance the bill as necessary to ensure "access to abortion services regardless of what state an individual lives in." After Dobbs he stated "It''s time to abolish the filibuster, unpack the Supreme Court, and enshrine Roe into law." He co-sponsored the EACH Act (Equal Access to Abortion Coverage in Health Insurance), which eliminates Hyde Amendment restrictions on publicly funded abortion care through Medicaid and federal health programs.',
  sources = ARRAY[
    'https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-failure-to-pass-womens-health-protection-act',
    'https://schiff.house.gov/news/press-releases/congressman-schiff-on-supreme-court-decision-to-strike-down-roe-v-wade',
    'https://www.congress.gov/bill/118th-congress/house-bill/561'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032'
  AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';

-- Civil Rights
UPDATE inform.politician_context
SET
  reasoning = 'Schiff is an original co-sponsor of the Equality Act (H.R. 5, 117th Congress), which provides comprehensive federal nondiscrimination protections for LGBTQ+ individuals across employment, housing, education, credit, and public accommodations. He also authored the Equal Health Care for All Act, which makes equitable health access a protected civil right, renames HHS''s office to the "Office of Civil Rights and Health Equity," and requires disaggregated health outcome data by demographic — framing racial health disparities as a civil rights enforcement problem.',
  sources = ARRAY[
    'https://www.congress.gov/bill/117th-congress/house-bill/5',
    'https://schiff.house.gov/news/press-releases/schiff-introduces-equal-health-care-for-all-act',
    'https://schiff.house.gov/issues/lgbtq-equality'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032'
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- Misinformation
UPDATE inform.politician_context
SET
  reasoning = 'Schiff co-introduced the bipartisan AI Ads Act with Rep. Brian Fitzpatrick, expanding FEC jurisdiction to regulate AI-generated deepfakes in political communications and prohibiting fraudulent AI misrepresentation of candidates. In a 2020 statement on Facebook''s deepfake policy he declared "speedy takedowns the utmost priority," noting misinformation''s damage is "not undone when the deception is exposed." He sent formal oversight letters to Meta, X, TikTok, Google, Microsoft, and YouTube in October 2024 demanding written plans for addressing election misinformation before the general election.',
  sources = ARRAY[
    'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-landmark-bipartisan-bill-to-combat-fraudulent-ai-campaign-ads',
    'https://schiff.house.gov/news/press-releases/rep-schiff-statement-on-facebooks-deepfake-policy',
    'https://schiff.house.gov/news/press-releases/schiff-demands-social-media-companies-take-action-in-advance-of-2024-election-to-address-spread-of-election-misinformation'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032'
  AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';

-- Religious Freedom
UPDATE inform.politician_context
SET
  reasoning = 'Schiff is an original co-sponsor of the Equality Act (H.R.5), which explicitly narrows the Religious Freedom Restoration Act so it cannot be invoked as a defense against LGBTQ nondiscrimination claims — a direct policy choice to subordinate religious exemptions to civil rights protections across employment, housing, and public accommodations. His LGBTQ equality issues page affirms support for "the rights of all citizens to be treated equally under the law, regardless of their sexual orientation or gender identity," and he has co-sponsored the Equality Act across multiple congressional sessions, reflecting a consistent position that civil rights protections take precedence over RFRA-based carve-outs.',
  sources = ARRAY[
    'https://schiff.house.gov/issues/lgbtq-equality',
    'https://www.congress.gov/bill/117th-congress/house-bill/5',
    'https://www.washingtonblade.com/2023/02/09/exclusive-adam-schiff-discusses-senate-run-and-new-bill-protecting-trans-youth/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032'
  AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';

-- Same-Sex Marriage
UPDATE inform.politician_context
SET
  reasoning = 'Schiff co-sponsored H.R.8404, the Respect for Marriage Act (117th Congress), which repealed DOMA and required federal recognition of same-sex and interracial marriages. On final House passage in December 2022 he stated he was "proud that the House passed the Respect for Marriage Act" and that it would "ensure that LGBTQ+ couples and interracial couples never again need to worry about whether their marriage will be recognized." He serves as vice chair of the Congressional LGBTQ+ Equality Caucus and has supported marriage equality consistently across congressional sessions.',
  sources = ARRAY[
    'https://schiff.house.gov/news/press-releases/congressman-schiff-on-passage-of-respect-for-marriage-act',
    'https://www.congress.gov/bill/117th-congress/house-bill/8404',
    'https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-passage-of-respect-for-marriage-act'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032'
  AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';

-- Social Security
UPDATE inform.politician_context
SET
  reasoning = 'Schiff''s Affordability Agenda calls explicitly for expanding Social Security by lifting the payroll cap to $250,000 of income and boosting benefits for the lowest-income retirees. When Mike Johnson became Speaker in October 2023, Schiff stated Johnson "wants to end Medicare and Social Security as we know it," framing the election as a fight to protect the programs. As a senator he joined Padilla and 27 Democratic colleagues demanding the Trump administration and DOGE refrain from cuts to Medicare and Medicaid.',
  sources = ARRAY[
    'https://www.adamschiff.com/plans/affordability-agenda/',
    'https://x.com/AdamSchiff/status/1717239952184893868',
    'https://www.schiff.senate.gov/news/press-releases/news-sens-schiff-padilla-colleagues-raise-alarm-on-trump-administration-targeting-cuts-to-medicare-and-medicaid/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032'
  AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';
