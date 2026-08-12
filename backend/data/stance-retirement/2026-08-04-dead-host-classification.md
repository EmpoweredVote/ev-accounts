# Non-resolving cited hosts — classification

Generated 2026-08-04 by `scripts/classify-dead-cited-hosts.mjs`.

Method: **CDX exact-URL match** as the primary test (was this URL ever captured?), host sibling
coverage for presence, exponential backoff throughout. The first version used the availability API
with three un-backed-off rounds per URL and throttled itself into UNKNOWN on every host.

⚠ **A lapsed campaign domain is the normal end state of a real campaign site**, so `NO_ARCHIVE_CAMPAIGN_WEAK`
is explicitly NOT evidence of fabrication. Only `HOST_ARCHIVED_PATHS_NEVER_CAPTURED` and
`NO_ARCHIVE_OTHER` are candidates for the newtonobserver.com treatment, and each still needs a hand read.

| host | rows | class | archived siblings | cited paths |
|---|---|---|---|---|
| `willametteweek.com` | 57 | HOST_ARCHIVED_PATHS_NEVER_CAPTURED | 300 | ABSENT, ABSENT, ABSENT, ABSENT, ABSENT |
| `bilalmahmood.com` | 12 | REPOINTABLE_ALL | 29 | ARCHIVED, ARCHIVED, ARCHIVED |
| `davidredkey4congress.com` | 7 | REPOINTABLE_ALL | 44 | ARCHIVED, ARCHIVED, ARCHIVED, ARCHIVED, ARCHIVED |
| `chapmanforcongress.com` | 5 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `walthampatch.com` | 5 | NO_ARCHIVE_OTHER | 3 | ABSENT, ABSENT |
| `tracinskiletter.com` | 4 | REPOINTABLE_SOME | 300 | ABSENT, ABSENT, ARCHIVED, ABSENT, ABSENT |
| `davidfbristol.com` | 4 | REPOINTABLE_ALL | 29 | ARCHIVED |
| `kateforbloomington.org` | 4 | REPOINTABLE_ALL | 53 | ARCHIVED |
| `bradknott.com` | 3 | REPOINTABLE_ALL | 249 | ARCHIVED |
| `dutra4whittier.com` | 3 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `boli.oregon.gov` | 3 | NO_ARCHIVE_OTHER | 0 | ABSENT |
| `kennethforla.com` | 2 | NO_ARCHIVE_CAMPAIGN_WEAK | 0 | ABSENT |
| `craigandresforprosper.com` | 2 | REPOINTABLE_ALL | 3 | ARCHIVED |
| `act.juliabrownley.com` | 2 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `octavioforwhittier.com` | 2 | NO_ARCHIVE_CAMPAIGN_WEAK | 0 | ABSENT |
| `markhenderson.org` | 2 | REPOINTABLE_ALL | 260 | ARCHIVED |
| `maryannforwhittier.com` | 2 | REPOINTABLE_ALL | 34 | ARCHIVED |
| `monteiro4council2022.com` | 2 | REPOINTABLE_ALL | 63 | ARCHIVED |
| `m.lasvegassun.com` | 1 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `metromayor.org` | 1 | NO_ARCHIVE_OTHER | 1 | ABSENT |
| `downeylegend.com` | 1 | NO_ARCHIVE_OTHER | 2 | ABSENT |
| `rightnowmn.org` | 1 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `cambridgeresidentsalliance.org` | 1 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `vivioforcongress.com` | 1 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `allenrwaters.com` | 1 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `publicleadershipinstitute.org` | 1 | REPOINTABLE_ALL | 300 | ARCHIVED |
| `figcitynews.com` *(control)* | 0 | CONTROL_OK | 300 | — |
| `wweek.com` *(control)* | 0 | CONTROL_OK | 300 | — |

## Per-host detail

### `willametteweek.com` — HOST_ARCHIVED_PATHS_NEVER_CAPTURED (57 rows, dns ERRORED)

- archived siblings: 300 (e.g. `http://www.willametteweek.com:80/`, `http://www.willametteweek.com:80/%23Web+Pages/pages/default.html`, `http://www.willametteweek.com/2008/arrow_icon2.gif`)
- ABSENT — `https://www.willametteweek.com/news/2024/10/30/portland-council-district-3-candidates-answer-our-questions/` (17 rows)
- ABSENT — `https://www.willametteweek.com/news/2024/10/30/portland-council-district-1-candidates-answer-our-questions/` (14 rows)
- ABSENT — `https://www.willametteweek.com/news/2024/10/30/portland-council-district-2-candidates-answer-our-questions/` (13 rows)
- ABSENT — `https://www.willametteweek.com/news/2024/10/30/portland-council-district-4-candidates-answer-our-questions/` (8 rows)
- ABSENT — `https://www.willametteweek.com/news/2024/10/30/portland-mayor-candidates-answer-our-questions/` (5 rows)

### `bilalmahmood.com` — REPOINTABLE_ALL (12 rows, dns NO_DNS)

- archived siblings: 29 (e.g. `http://bilalmahmood.com/`, `https://www.bilalmahmood.com/.well-known/ai-plugin.json`, `https://www.bilalmahmood.com/.well-known/assetlinks.json`)
- ARCHIVED (8 captures, first 20231104212748) — `https://bilalmahmood.com/platform` (9 rows)
- ARCHIVED (8 captures, first 20110207113357) — `https://bilalmahmood.com/` (3 rows)
- ARCHIVED (8 captures, first 20231109071107) — `https://bilalmahmood.com/about` (2 rows)

### `davidredkey4congress.com` — REPOINTABLE_ALL (7 rows, dns NO_DNS)

- archived siblings: 44 (e.g. `http://www.davidredkey4congress.com/`, `https://www.davidredkey4congress.com/.well-known/ai-plugin.json`, `https://www.davidredkey4congress.com/.well-known/assetlinks.json`)
- ARCHIVED (3 captures, first 20260313011753) — `https://www.davidredkey4congress.com/economic-bill-of-rights` (2 rows)
- ARCHIVED (3 captures, first 20260209112553) — `https://www.davidredkey4congress.com/tricare-prime-for-all` (2 rows)
- ARCHIVED (3 captures, first 20260209122630) — `https://www.davidredkey4congress.com/federal-monies-for-school-funding` (1 rows)
- ARCHIVED (3 captures, first 20260209105434) — `https://www.davidredkey4congress.com/fights-for-reproductive-rights` (1 rows)
- ARCHIVED (3 captures, first 20260209121136) — `https://www.davidredkey4congress.com/stopping-the-trump-tariffs` (1 rows)

### `chapmanforcongress.com` — REPOINTABLE_ALL (5 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `http://www.chapmanforcongress.com:80/`, `https://chapmanforcongress.com/&themeRefresh=1`, `http://chapmanforcongress.com/1/`)
- ARCHIVED (8 captures, first 20030211134459) — `https://chapmanforcongress.com/issues/` (5 rows)

### `walthampatch.com` — NO_ARCHIVE_OTHER (5 rows, dns ERRORED)

- archived siblings: 3 (e.g. `http://walthampatch.com/`, `http://walthampatch.com/favicon.ico`, `http://www.walthampatch.com/robots.txt`)
- ABSENT — `https://www.walthampatch.com/posts/waltham-city-council-mbta-zoning-vote-2024` (4 rows)
- ABSENT — `https://www.walthampatch.com/posts/waltham-mbta-communities-zoning-compliance-2024` (1 rows)

### `tracinskiletter.com` — REPOINTABLE_SOME (4 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `http://www.tracinskiletter.com/`, `https://tracinskiletter.com/.well-known/ai-plugin.json`, `https://tracinskiletter.com/.well-known/assetlinks.json`)
- ABSENT — `https://www.tracinskiletter.com/p/so-much-for-originalism` (2 rows)
- ABSENT — `https://www.tracinskiletter.com/p/the-borderline-constitution` (2 rows)
- ARCHIVED (8 captures, first 20121013030840) — `https://www.tracinskiletter.com/about` (1 rows)
- ABSENT — `https://www.tracinskiletter.com/p/farmageddon` (1 rows)
- ABSENT — `https://www.tracinskiletter.com/p/things-that-would-be-nice-if-they` (1 rows)

### `davidfbristol.com` — REPOINTABLE_ALL (4 rows, dns NO_DNS)

- archived siblings: 29 (e.g. `http://davidfbristol.com/`, `https://davidfbristol.com/favicon.ico`, `http://davidfbristol.com/robots.txt`)
- ARCHIVED (8 captures, first 20211201091036) — `https://davidfbristol.com/` (4 rows)

### `kateforbloomington.org` — REPOINTABLE_ALL (4 rows, dns NO_DNS)

- archived siblings: 53 (e.g. `https://kateforbloomington.org/`, `https://kateforbloomington.org/.well-known/ai-plugin.json`, `https://kateforbloomington.org/.well-known/assetlinks.json`)
- ARCHIVED (6 captures, first 20190723180506) — `https://kateforbloomington.org/issues/` (4 rows)

### `bradknott.com` — REPOINTABLE_ALL (3 rows, dns NO_DNS)

- archived siblings: 249 (e.g. `http://www.bradknott.com:80/`, `https://www.bradknott.com/.well-known/ai-plugin.json`, `https://www.bradknott.com/.well-known/assetlinks.json`)
- ARCHIVED (1 captures, first 20260512171724) — `https://www.bradknott.com/priorities` (3 rows)

### `dutra4whittier.com` — REPOINTABLE_ALL (3 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `http://dutra4whittier.com`, `https://www.dutra4whittier.com/.well-known/ai-plugin.json`, `https://dutra4whittier.com/.well-known/assetlinks.json`)
- ARCHIVED (8 captures, first 20190717142033) — `https://www.dutra4whittier.com/about/` (3 rows)

### `boli.oregon.gov` — NO_ARCHIVE_OTHER (3 rows, dns NO_DNS)

- archived siblings: 0
- ABSENT — `https://boli.oregon.gov/pages/news.aspx` (3 rows)

### `kennethforla.com` — NO_ARCHIVE_CAMPAIGN_WEAK (2 rows, dns NO_DNS)

- archived siblings: 0
- ABSENT — `https://www.kennethforla.com/` (2 rows)

### `craigandresforprosper.com` — REPOINTABLE_ALL (2 rows, dns NO_DNS)

- archived siblings: 3 (e.g. `http://craigandresforprosper.com/`, `https://craigandresforprosper.com/favicon.ico`, `http://craigandresforprosper.com/robots.txt`)
- ARCHIVED (2 captures, first 20180808145709) — `https://craigandresforprosper.com/` (2 rows)

### `act.juliabrownley.com` — REPOINTABLE_ALL (2 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `http://act.juliabrownley.com/`, `http://act.juliabrownley.com/citizens-united`, `http://act.juliabrownley.com/citizens-united?&firstname=Walter&lastname=Jorgensen&zip=98501&email=waltjorgensen@comcast.net`)
- ARCHIVED (2 captures, first 20171223013806) — `https://act.juliabrownley.com/page/s/call-on-congress-to-pass-the-dream-act` (2 rows)

### `octavioforwhittier.com` — NO_ARCHIVE_CAMPAIGN_WEAK (2 rows, dns NO_DNS)

- archived siblings: 0
- ABSENT — `https://octavioforwhittier.com/` (2 rows)

### `markhenderson.org` — REPOINTABLE_ALL (2 rows, dns NO_DNS)

- archived siblings: 260 (e.g. `http://www.markhenderson.org:80/`, `https://www.markhenderson.org/.well-known/ai-plugin.json`, `https://www.markhenderson.org/.well-known/assetlinks.json`)
- ARCHIVED (8 captures, first 20130126072321) — `https://www.markhenderson.org/` (2 rows)

### `maryannforwhittier.com` — REPOINTABLE_ALL (2 rows, dns NO_DNS)

- archived siblings: 34 (e.g. `http://www.maryannforwhittier.com/`, `https://www.maryannforwhittier.com/_api/communities-blog-api-web`, `https://www.maryannforwhittier.com/_api/communities-blog-node-api`)
- ARCHIVED (1 captures, first 20231215180833) — `https://www.maryannforwhittier.com/issues` (2 rows)

### `monteiro4council2022.com` — REPOINTABLE_ALL (2 rows, dns NO_DNS)

- archived siblings: 63 (e.g. `https://www.monteiro4council2022.com/`, `https://www.monteiro4council2022.com/comments/feed/`, `https://www.monteiro4council2022.com/events/?ical=1`)
- ARCHIVED (6 captures, first 20220117232610) — `https://www.monteiro4council2022.com/` (2 rows)

### `m.lasvegassun.com` — REPOINTABLE_ALL (1 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `http://m.lasvegassun.com:80/`, `https://m.lasvegassun.com/.../as-las-vegas-rebounds-from.../`, `https://m.lasvegassun.com/.../in-humboldt-county.../`)
- ARCHIVED (3 captures, first 20191107105922) — `https://m.lasvegassun.com/news/2019/nov/06/tense-las-vegas-council-oks-homeless-ordinance/` (1 rows)

### `metromayor.org` — NO_ARCHIVE_OTHER (1 rows, dns NO_DNS)

- archived siblings: 1 (e.g. `http://metromayor.org/robots.txt`)
- ABSENT — `https://metromayor.org/climate-resolutions/` (1 rows)

### `downeylegend.com` — NO_ARCHIVE_OTHER (1 rows, dns NO_DNS)

- archived siblings: 2 (e.g. `http://downeylegend.com`, `http://downeylegend.com/robots.txt`)
- ABSENT — `https://downeylegend.com/get-to-know-mayor-claudia-frometa/` (1 rows)

### `rightnowmn.org` — REPOINTABLE_ALL (1 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `http://rightnowmn.org/`, `https://www.rightnowmn.org/.well-known/ai-plugin.json`, `https://www.rightnowmn.org/.well-known/assetlinks.json`)
- ARCHIVED (8 captures, first 20230401133928) — `https://www.rightnowmn.org/hughmctavish` (1 rows)

### `cambridgeresidentsalliance.org` — REPOINTABLE_ALL (1 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `http://www.cambridgeresidentsalliance.org:80/`, `http://www.cambridgeresidentsalliance.org/--`, `http://www.cambridgeresidentsalliance.org/--You`)
- ARCHIVED (8 captures, first 20121113155724) — `https://www.cambridgeresidentsalliance.org/` (1 rows)

### `vivioforcongress.com` — REPOINTABLE_ALL (1 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `https://vivioforcongress.com/`, `https://vivioforcongress.com/.well-known/ai-plugin.json`, `https://vivioforcongress.com/.well-known/assetlinks.json`)
- ARCHIVED (6 captures, first 20251107155935) — `https://vivioforcongress.com/about/` (1 rows)

### `allenrwaters.com` — REPOINTABLE_ALL (1 rows, dns NO_DNS)

- archived siblings: 300 (e.g. `http://www.allenrwaters.com/`, `https://www.allenrwaters.com/.well-known/ai-plugin.json`, `https://www.allenrwaters.com/.well-known/assetlinks.json`)
- ARCHIVED (8 captures, first 20170329122320) — `https://www.allenrwaters.com` (1 rows)

### `publicleadershipinstitute.org` — REPOINTABLE_ALL (1 rows, dns ERRORED)

- archived siblings: 300 (e.g. `http://www.publicleadershipinstitute.org:80/`, `https://publicleadershipinstitute.org/.png`, `https://publicleadershipinstitute.org/.svg`)
- ARCHIVED (8 captures, first 20191016140756) — `https://publicleadershipinstitute.org/2019/09/25/proactive-abortion-rights-summary-of-2019/` (1 rows)

