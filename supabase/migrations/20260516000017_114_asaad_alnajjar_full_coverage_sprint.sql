-- Full coverage sprint for Asaad Alnajjar (politician_id: f05ec762-9053-45a0-be1a-a4b173a06015)
-- LA Mayor candidate 2026; structural engineer, LA Metro infrastructure background
-- Group A: update sources on 3 thin context rows (housing, local-environment, public-safety-approach)
-- Group B: 6 new answer+context rows
--          (civil-rights=2, deportation=3, economic-development=3, fossil-fuels=3,
--           homelessness=2, residential-zoning=3)
-- Skipped: abortion, same-sex-marriage, trans-athletes, school-vouchers, campaign-finance,
--          voting-rights, taxes, jail-capacity, childcare, rent-regulation, religious-freedom,
--          misinformation — no on-record statements found

-- ── GROUP A: Update sources on thin context rows ──────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Campaign platform imposes a moratorium on luxury developments until affordable housing benchmarks are achieved and leverages engineering expertise for expedited building permits to produce affordable housing. Framing is pro-intervention to boost affordable supply rather than market-led or universal-guarantee.',
  sources = ARRAY[
    'https://www.lamayor2026.org/on-the-issues',
    'https://abc7.com/post/los-angeles-mayor-race-full-list-14-candidates-2026-election-republicans-democrats-hoping-replace-karen-bass/18756539/',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-mayor'
  ]
WHERE politician_id = 'f05ec762-9053-45a0-be1a-a4b173a06015' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

UPDATE inform.politician_context SET
  reasoning = 'Infrastructure section of campaign platform explicitly supports Solar LED street lighting, EV charging expansion, cool asphalt, and the Sepulveda Transit Corridor design-build under Green New Deal goals. No position on eliminating development outright, but strong city-level green investment posture beyond baseline maintenance.',
  sources = ARRAY[
    'https://www.lamayor2026.org/on-the-issues',
    'https://abc7.com/post/los-angeles-mayor-race-full-list-14-candidates-2026-election-republicans-democrats-hoping-replace-karen-bass/18756539/'
  ]
WHERE politician_id = 'f05ec762-9053-45a0-be1a-a4b173a06015' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';

UPDATE inform.politician_context SET
  reasoning = 'Platform commits to fully equipping and staffing police and firefighters with modern training and resources, and optimizing LAFD programs for wildfire-prone areas. Also calls for civilian participation in the emergency operations center. No mental health co-responder or budget reallocation language; balanced traditional-policing approach.',
  sources = ARRAY[
    'https://www.lamayor2026.org/on-the-issues',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-mayor',
    'https://abc7.com/post/los-angeles-mayor-race-full-list-14-candidates-2026-election-republicans-democrats-hoping-replace-karen-bass/18756539/'
  ]
WHERE politician_id = 'f05ec762-9053-45a0-be1a-a4b173a06015' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Operates on a ''Unity through Diversity'' platform, standing explicitly against all forms of discrimination and hate and protecting the rights of all residents. ABC7 candidate profile lists LGBTQ+ rights protection as a named component of this platform. Campaign establishes a Worker Protection Unit and expands legal defense funds for immigrants.',
  ARRAY['https://www.lamayor2026.org/on-the-issues','https://abc7.com/post/los-angeles-mayor-race-full-list-14-candidates-2026-election-republicans-democrats-hoping-replace-karen-bass/18756539/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', '44905f3b-e105-4f6c-afc7-5d223813dbac', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', '44905f3b-e105-4f6c-afc7-5d223813dbac',
  'Proposes canceling General Order 40 on day one so LAPD can identify immigration status, but pairs this with a 90-day pathway to legalize undocumented residents through existing TPS programs. Not advocating mass removal or criminal-history-first prioritization; the framing is enforcement plus structured legalization rather than blanket deportation.',
  ARRAY['https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-mayor','https://www.lamayor2026.org/on-the-issues'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Supports reducing red tape for small businesses, introducing incentives, providing local contracts, and improving district infrastructure. Simultaneously opposes the $2.62B Los Angeles Convention Center expansion as a developer-priority vanity project, stating funds should go to streets, affordable housing, and public safety. Targeted incentives with community-benefit framing rather than maximum-incentive competition.',
  ARRAY['https://lamayor2026.org/wp-content/uploads/2025/10/EINPresswire-860321925-los-angeles-mayoral-candidate-asaad-alnajjar-strongly-opposes-costly-2-6b-los-angeles-convention-center-expansion-1.pdf','https://www.lamayor2026.org/on-the-issues','https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-mayor'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', 'a22215c3-6693-4bc2-b248-01aebba14570', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', 'a22215c3-6693-4bc2-b248-01aebba14570',
  'Campaign platform references Green New Deal goals in the infrastructure section and explicitly supports Solar LED street lighting, EV charging expansion, and cool asphalt. No stated position on oil drilling permits or extraction bans at the city level. Environmental investments are framed as city infrastructure upgrades rather than fossil fuel phase-out advocacy.',
  ARRAY['https://www.lamayor2026.org/on-the-issues','https://abc7.com/post/los-angeles-mayor-race-full-list-14-candidates-2026-election-republicans-democrats-hoping-replace-karen-bass/18756539/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Platform centers on a Housing-First Strategy prioritizing mental health and addiction recovery access. Proposes a 90-day audit of homelessness spending and a moratorium on luxury developments until affordable housing benchmarks are achieved. Framing treats homelessness as a services and accountability failure rather than a criminalization issue.',
  ARRAY['https://www.lamayor2026.org/on-the-issues','https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-mayor','https://abc7.com/post/los-angeles-mayor-race-full-list-14-candidates-2026-election-republicans-democrats-hoping-replace-karen-bass/18756539/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f05ec762-9053-45a0-be1a-a4b173a06015', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Supports expedited building permits and leveraging engineering expertise for affordable housing production. Imposes a moratorium on luxury developments until affordable housing benchmarks are met. No blanket upzoning language and no single-family neighborhood protection stance; targeted pro-affordable-density approach with conditions on luxury development.',
  ARRAY['https://www.lamayor2026.org/on-the-issues','https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-mayor'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
