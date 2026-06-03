-- Correction migration for Alex Vindman (politician_id: a2fee754-f90c-47ff-a3b7-377d55992273)
-- FL State Senate candidate; fmr. NSC Director for European Affairs; Ukraine impeachment witness
-- Source date: 2026-06-02 (research from batch-A CSV)
-- Corrections: 8 topics; original data had 4-5 value lock with abortion=5 and religious-freedom=5 flagged
-- Corrected values: ukraine-support=1, healthcare=2, medicare/aid=2, campaign-finance=2,
--   taxes=2, school-vouchers=1, housing=3, voting-rights=2
-- Topics corrected: ukraine-support, healthcare, medicare/aid, campaign-finance,
--   taxes, school-vouchers, housing, voting-rights

BEGIN;

-- ukraine-support: value corrected to 1 (former NSC Ukraine director, testified at Trump impeachment)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2fee754-f90c-47ff-a3b7-377d55992273',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'),
  'Alexander Vindman is the former NSC Director for European Affairs who was reassigned after testifying at Trump''s first impeachment about the Ukraine phone call. His entire career as a foreign policy professional specialized in Eurasia/Ukraine. He was born in the Ukrainian Soviet Socialist Republic. His Wikipedia page notes he came to national attention testifying about Trump''s attempt to withhold military aid from Ukraine. He has been a consistent public advocate for strong U.S. support of Ukraine against Russian aggression. As a Florida Senate candidate, his foreign policy platform emphasizes defending allies. This fits value 1 (significantly increase military aid to Ukraine and commit to supporting them until complete victory over Russia) — he has the deepest personal and professional stake of any candidate in sustained Ukraine support.',
  ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman', 'https://alexvindman.com/florida-first-agenda/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- healthcare: value corrected to 2 (defends ACA, expands Medicare, not single-payer)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2fee754-f90c-47ff-a3b7-377d55992273',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Vindman''s campaign states ''Health care is a right, not a privilege. No one should go broke to stay healthy.'' He pledges to ''defend and strengthen the Affordable Care Act, lower drug prices, and expand access to quality, affordable care across all of Florida.'' His platform explicitly defends the ACA (a mix of public and regulated private insurance) rather than advocating for single-payer. He also supports strengthening Medicare by adding dental and eye coverage. This combination — defending ACA, expanding Medicare, expanding Medicaid access — fits value 2 (make sure everyone has affordable coverage through a mix of public programs and regulated private insurance).',
  ARRAY['https://alexvindman.com/florida-first-agenda/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- medicare/aid: value corrected to 2 (strengthen Medicare + dental/eye, expand Medicaid access)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2fee754-f90c-47ff-a3b7-377d55992273',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Vindman''s agenda states: ''Alex will strengthen Medicare by supporting legislation that adds dental and eye coverage to this life-saving program and expanding the state''s Medicaid and Medicare access programs.'' He also opposes Medicaid cuts, stating Moody ''voted for the largest cut to Medicaid in American history.'' This is an expand-not-privatize stance that fits value 2 (lower Medicare age to 55 and expand Medicaid significantly).',
  ARRAY['https://alexvindman.com/florida-first-agenda/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- campaign-finance: value corrected to 2 (no corporate PAC money, repeal Citizens United, limit dark money)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2fee754-f90c-47ff-a3b7-377d55992273',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Vindman''s agenda states he ''hasn''t taken a dime in corporate PAC money'' and pledges to ''join the growing ranks of legislators calling for a repeal of Citizens United and limiting the influence of dark money in American politics.'' He also pledges to ''crack down on dark money in our elections'' and ban Congressional stock trading. His stance is strictly limit corporate/dark money but operates within a framework of regulated private donations (not a full public-finance-only model), fitting value 2 (strictly limit corporate donations and dark money groups).',
  ARRAY['https://alexvindman.com/florida-first-agenda/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- taxes: value corrected to 2 (raise taxes on billionaires/corporations, close loopholes, middle-class relief)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2fee754-f90c-47ff-a3b7-377d55992273',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Vindman''s agenda states ''Nobody thinks it is fair for the billionaires and megacorporations to get tax cuts and get richer, while ordinary people get squeezed with higher taxes.'' He supports ''tax relief for middle-class families, making the tax system fair for everyone, closing loopholes for tax cheats.'' He opposes Moody''s alignment with corporate tax cuts. This is a raise-taxes-on-wealthy/close-loopholes position without advocating for the most dramatic tax increases, fitting value 2 (moderately raise taxes on wealthy people and large companies to fund existing services).',
  ARRAY['https://alexvindman.com/florida-first-agenda/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- school-vouchers: value corrected to 1 (explicitly anti-defunding public education, opposes ideological cuts)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2fee754-f90c-47ff-a3b7-377d55992273',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Vindman''s agenda states he ''will push back against efforts to defund or politicize public education, whether this comes in the form of sweeping cuts on a federal level, or ideologically motivated measures at the local level'' and will ''fight back against these cuts to public education.'' He opposes Moody''s support for dismantling the Department of Education. As a ''proud girl dad'' who believes ''every child deserves a high-quality education no matter their zip code,'' he is explicitly pro-public-school-investment and anti-defunding. This aligns with value 1 (fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions).',
  ARRAY['https://alexvindman.com/florida-first-agenda/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- housing: value corrected to 3 (cut red tape + first-time buyer help + oppose corporate speculation)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2fee754-f90c-47ff-a3b7-377d55992273',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Vindman''s agenda states ''We need to build more affordable housing and it needs to be done faster and smarter. That''s why Alex will work to cut red tape that slows construction and support policies that allow first-time homebuyers to break into the market.'' He also pledges to ''take on corporate investors who view housing purely as a speculative asset.'' This combination — cutting regulations to enable construction AND targeting corporate investors — is a center-left approach. It does not advocate for direct public housing construction (value 1) or rent caps (value 2), but rather a targeted help approach with buyer assistance and streamlined permitting. This fits value 3 (offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits).',
  ARRAY['https://alexvindman.com/florida-first-agenda/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- voting-rights: value corrected to 2 (crack down on dark money, expand oversight, democracy advocate)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2fee754-f90c-47ff-a3b7-377d55992273',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Vindman''s campaign states he ''will push to crack down on dark money in our elections to ensure that the government works for the people'' and supports ''the expansion of congressional oversight and investigatory authorities.'' His campaign co-chairs the Global Democracy Ambassador Scholarship to help Ukrainian scholars understand ''the fragility and importance of democracy'' (per Wikipedia). He appeared in Lincoln Project and VoteVets ads in 2020. As a candidate emphasizing corruption, democracy, and electoral integrity, his position — crack down on dark money, support oversight — fits value 2 (expand early voting periods and make mail-in voting available to all voters without requiring an excuse) in terms of expanding ballot access while maintaining legitimate election integrity measures.',
  ARRAY['https://alexvindman.com/florida-first-agenda/', 'https://en.wikipedia.org/wiki/Alexander_Vindman']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
