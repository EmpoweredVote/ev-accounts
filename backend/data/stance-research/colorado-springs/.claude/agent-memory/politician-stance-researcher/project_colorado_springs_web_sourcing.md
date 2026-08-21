---
name: project_colorado_springs_web_sourcing
description: What actually works (and doesn't) when researching Colorado Springs / El Paso County politicians beyond the tier-1 CPR questionnaires
metadata:
  type: project
---

Researched Nancy Henjum (Council D5) 2026-08-21 for the local 22-topic scale
(`backend/data/stance-research/colorado-springs/scale-local.json`). Findings for the next pass
in this cohort:

- **coloradosprings.gov council pages are bio-only.** The working URL pattern is
  `https://coloradosprings.gov/city-council/page/{firstname}-{lastname}-district-{n}` (e.g.
  `nancy-henjum-district-5`) — it 200s, but contains only contact info + a short personal bio
  ("enjoys hiking, biking..."). No stated policy positions. Don't expect stance content from
  these pages; use them only to confirm district/contact facts.
- **ballotpedia.org/[First_Last] returned empty content for Henjum** — not a 403, WebFetch got a
  response but the small model found no body text. Likely no Ballotpedia page exists for this
  person, or it's a stub. Don't burn more than one attempt per person on this before moving on.
- **Site search URLs (`?s=query`) are dead ends via WebFetch** — gazette.com, koaa.com, krdo.com,
  csindy.com search endpoints either 403, redirect to an unrelated domain (csindy.com → 302 to
  socoinsider.com, a rebrand), or 200 with a homepage that has no search results rendered (JS-driven
  search, WebFetch only sees the static shell). WebFetch cannot substitute for a real search here —
  don't retry these patterns; they won't resolve to article content without a known article URL.
- **Candidate campaign sites may be placeholders.** `nancyhenjum.com` resolved but was a Squarespace
  "coming soon" page with zero content, months after her 2025 re-election. Don't assume a personal
  domain guess will pay off — verify it has content before investing a prompt.
- council.coloradosprings.gov (the subdomain form) does not resolve (DNS failure) — use
  `coloradosprings.gov/city-council/...` not a `council.` subdomain.
- **Net effect: for this cohort, the CPR/KRCC questionnaire in `sources/` is likely to remain the
  dominant source** for most topics. Budget web-fetch attempts accordingly — a handful of
  reasonable URL guesses, then stop and rely on what the questionnaire supports rather than
  grinding through more 404s.

See also [[project_colorado_springs_local_scale_chairs]] for how the 22-topic ladder played out
for Henjum specifically (which topics her questionnaire could/couldn't seat).

## David Leinweber (At-Large 2) pass, 2026-08-21 — confirms the pattern, one new URL note

- **At-large council members' bio pages don't follow the district URL pattern.** Henjum's worked
  as `coloradosprings.gov/city-council/page/{firstname}-{lastname}-district-{n}`; for an at-large
  member the working page was the bare `coloradosprings.gov/{firstlast}` (no hyphens, no
  "district", no "/city-council/page/" prefix) — e.g. `coloradosprings.gov/davidleinweber`. Same
  content ceiling as before though: contact info + personal/business bio (Angler's Covey, PPORA),
  **zero stated policy positions**. Confirms: don't expect stance content from these pages, at-large
  or district.
- `ballotpedia.org/David_Leinweber` and `ballotpedia.org/David_Leinweber_(Colorado)` both returned
  **empty** WebFetch responses (not 403, just no body text extracted) — same dead end as Henjum.
  Try once, don't retry variants.
- `coloradosprings.gov/city-council` (the directory/roster page) DOES resolve and lists all
  members with links to their individual bio pages — useful for *finding* the right bio-page slug
  when you don't know it, but the bio pages themselves are still policy-free per above.
- Net effect unchanged from the Henjum pass: for 2023/2025 CPR-questionnaire subjects, the
  tier-1 questionnaire file remains the dominant (often only) usable source. Two candidates in a
  row, same ceiling — treat this as the expected baseline for this cohort, not a fixable gap to
  keep probing.

## Brian Risley (At-Large 3) pass, 2026-08-21 — third data point, same ceiling, no new working URL

- `coloradosprings.gov/brianrisley` (bare at-large pattern, confirmed working format) 200s but is
  **bio-only** yet again: architecture practice, Planning Commission chair, Citizens' Transportation
  Advisory Board — qualifications, zero stated policy positions. Third-for-three on this pattern.
- `ballotpedia.org/Brian_Risley` returned **empty** content again (WebFetch got no body text) — same
  as Henjum and Leinweber. Don't bother retrying Ballotpedia for this cohort's at-large 2023 crowd;
  0-for-3 so far.
- Did not find any CSU-utility-board rate-case/generation-plan vote or AIA/development-industry
  statement in Risley's own words anywhere reachable via direct-URL WebFetch — the brief's
  suggestion to check CSU board actions for an architect/ex-Planning-Commissioner candidate didn't
  pay off for him specifically; no fossil-fuels/climate chair resulted.
- Net effect: three candidates in, the tier-1 CPR questionnaire remains the *only* productive
  source in this cohort. Stop budgeting more than 1-2 confirmatory WebFetch calls per new person —
  they consistently confirm "bio-only" / "empty," never add content.

## Second-pass addendum (2026-08-21) — coloradosprings.gov/news + koaa.com search

- **`coloradosprings.gov/news` is real and fetchable**, and its site search at
  `coloradosprings.gov/search?query=X` is a genuine server-rendered search (not JS-only) — it
  correctly returns "No search results found" for terms not in the index. Trust a negative result
  from it. BUT: it appears to index only city press releases/news items, not council-meeting
  quotes or votes — three Aug-2026 items found there (Homelessness Response Team, KICAS sanitation,
  Community-First Data Center Standards) named the Mayor and one other councilmember but **not**
  Henjum by name. Don't assume every councilmember appears just because their city covers the
  initiative — check the actual article body per person.
- **`koaa.com/search?q=...` WORKS WELL and is the highest-yield source found so far for this
  cohort** — real keyword search, returns article titles + URLs even though full result-list
  bodies aren't rendered (WebFetch's summarizer only sees a handful of preview snippets per query,
  so narrow the query terms rather than trusting a single broad search to surface everything).
  `krdo.com/?s=` and `krdo.com/search/?q=` both 404 — krdo.com does not have a working WebFetch-
  accessible search endpoint; don't retry it.
- A **useful compound-query pattern**: `koaa.com/search?q=<Name>+<topic word>` (e.g. "Henjum
  sanitation", "Henjum data centers") reliably confirms ABSENCE (returns unrelated preview
  snippets with a large irrelevant result count) as cleanly as it confirms presence — a genuinely
  useful negative-evidence tool, not just a positive-lead finder.
- Found via koaa.com search but ultimately NOT usable: a KOAA article on a Colorado Springs
  sit-lie-ordinance expansion vote named Henjum's NO vote but attached zero reasoning to her (only
  the vote tally) — classic bare-vote, doesn't seat a chair per the brief's rule even though the
  topic (homelessness criminalization) badly wanted evidence. Chased three related articles
  looking for a quote from her specifically explaining that vote; none of Colorado Springs' local
  outlets attributed reasoning to her on it, only to other councilmembers (Avila, Talarico,
  Donelson) who did get quoted. Don't keep re-searching once multiple related articles all confirm
  the same silence — treat it as settled.
- Found via the same search pattern and DID seat a chair: a KOAA article on a council resolution
  declaring "Colorado Springs is not a sanctuary city for migrants" directly quoted Henjum's NO
  vote with her own reasoning ("We don't put blockades on I-25 and say who can and can't come into
  our city. When people come, they will be served.") — this is the kind of vote-plus-quote pairing
  that seats a chair. Search term that found it: `koaa.com/search?q=Colorado+Springs+council+immigration+resolution`
  (plain "Henjum immigration" / "Henjum sanctuary" combos did NOT surface it — broader institutional
  phrasing worked better than name+topic for this one).

## Kimberly Gold (Council D4) pass, 2026-08-21 - thin record confirmed, only 2 of 22 seated

- Her CPR/KRCC questionnaire (`sources/cpr-2025-gold.md`, ~16.5K chars, the longest in the cohort)
  is long on rhetoric but short on chair-distinguishing specifics. Only two topics survived the
  "does this name a specific chair" test: `growth-and-development` (value 3 - careful,
  infrastructure-first annexation review while explicitly warning against "overly restrictive"
  policy) and `public-safety-approach` (value 4 - calls for more police-training/tech investment,
  cites the PPA's endorsement). Her homelessness answer ("layered, holistic approach... meet
  people where they are") is genuinely silent on enforcement/criminalization, so it under-
  determines `homelessness` vs `homelessness-response` between the two non-punitive chairs (1 vs
  2) - skipped per the adjacent-chairs rule rather than guessed. Her `residential-zoning`-adjacent
  line ("responsible density... while preserving neighborhood character") is too generic to pick
  between chair 2 (modest ADU/duplex infill) and chair 3 (multifamily near corridors) - skipped
  for the same reason.
- **`coloradosprings.gov/news` did NOT surface anything for Gold**, unlike the mayor. Checked the
  three known-productive Aug-2026 articles (KICAS sanitation, Community-First Data Center
  Standards, Homelessness Response Team launch) directly - none quote her (KICAS quotes Mobolade,
  Williams D3, CSPD chief, URA director; the other two only quote Mobolade/staff). Paged
  `coloradosprings.gov/news?page=1..6` (Jun-Aug 2026) looking for her by name - the only hits were
  two July 2026 articles on the Southeast Strong Community Plan's unanimous adoption, where she's
  quoted but only in celebratory/gratitude language ("I'm deeply grateful to the residents...",
  "it's an honor to now represent these neighborhoods") - fails the forward-looking gate, not
  usable for a chair even though the plan itself plausibly touches growth/zoning/transportation.
  Her own bio page (`coloradosprings.gov/kimberlygold` - bare slug works for her, a district
  member, not just at-large members) confirms she led that plan's adoption and "supports economic
  development through Peak Innovation Park," but has no direct quote on an economic-development
  chair either.
- **`coloradosprings.gov/news?combine=X` and `/search/node/X` do NOT work** as query-string search
  (combine= returns the unfiltered page; search/node/ 404s) - use the bio page + direct
  paging-by-date approach instead, or `koaa.com/search?q=`.
- **`koaa.com/search?q=Name+topic` reliably returns a huge irrelevant hit-count with unrelated
  preview snippets when there's no real coverage** (tested "Kimberly Gold homelessness
  encampment", "Kimberly Gold data center sanitation", "Kimberly Gold District 4 public safety") -
  consistent with the Henjum-pass finding that this is trustworthy negative evidence, not just a
  lead-finder. When it does have a real hit it surfaces the correct headline in the preview list
  (found her Southeast Strong plan article this way) even though WebFetch can't read the full
  results page - worth 1-2 compound-query attempts per topic before giving up.

## Brandy Williams (Council D3) pass, 2026-08-21 - only 3 of 22 seated, but coloradosprings.gov/news DID surface her (unlike Gold)

- Her CPR/KRCC questionnaire (`sources/cpr-2025-williams.md`) is the classic thin-rhetoric pattern
  (water/growth "conversations," PlanCOS "growing pains," e-bike-trail process) - every
  growth/zoning/transportation answer fails the two-adjacent-chairs test. The one answer that DID
  seat cleanly: her public-safety answer ("The most pressing public safety issue is our lack of
  police officers... City Council will need to help the Mayor's office to take an active role to
  recruit and retain police officers") -> `public-safety-approach` = 4, a clean forward quote.
- **`coloradosprings.gov/news` DID name her** (contrast with the Gold pass, which found nothing):
  the Aug-2026 KICAS ("Keep It Clean And Safe") article quotes her directly on the South Nevada
  corridor security expansion in her own district ("I'm excited about this enhancement to District
  3. A visible professional security presence will help deter nuisance activity..."). Useful as
  *corroborating* evidence for `public-safety-approach`, but her actual words there are about
  security/storefronts, not homelessness/shelter, so it fails the on-question gate for
  `homelessness`/`homelessness-response` even though the KICAS program itself explicitly targets
  "trash, crime, and homelessness" - don't let the program's stated scope stand in for what she
  personally said. The other two Aug-2026 city-news articles the brief flags as productive
  (Community-First Data Center Standards, Homelessness Response Team launch) quote ONLY the Mayor
  and department staff - confirmed zero Williams quotes in either, so `data-centers` stayed
  unseated for her (also: it's explicitly a mayoral/executive framework release, not a council
  vote - office-type matters here too).
- **Best find of the pass came from `koaa.com/search?q=` on a program-review article, not a vote or
  a questionnaire**: "Downtown Colorado Springs 'Clean and Safe' initiative marks one year" reports
  (paraphrase, not a direct quote) that "Councilmembers Dave Donelson and Brandy Williams
  questioned whether penalties for low-level offenses are enough to deter crime." No quotation
  marks around her words in the source, so `quote_text` was left blank per the rules, but the
  *record* (a specific, on-question, forward-leaning position reported by name) was still strong
  enough to seat `homelessness` = 4 and, combined with her questionnaire's services-first language,
  `homelessness-response` = 3. Lesson: a clean paraphrase attributing a specific position to a
  named council member is usable stance evidence even with zero quotable text - don't discard it
  just because there's nothing to put in `quote_text`.
- Confirmed (again) `coloradosprings.gov/BrandyWilliams` (bare at-large-style slug pattern) works
  for a *district* member too, not just at-large - joins Henjum's `/city-council/page/{name}-
  district-{n}` pattern as a second working district-page format; try the bare-slug form first via
  `coloradosprings.gov/get-know-your-councilmember` (which lists the exact slug per member) if the
  hyphenated district URL 404s. Content ceiling unchanged: contact info only, zero policy content.
- `en.wikipedia.org/wiki/Brandy_Williams` is NOT this politician - it redirects to Oracene Price
  (Venus/Serena Williams's mother, a former Brandy Williams). Don't waste an attempt re-checking
  Wikipedia for this specific name; there is no page for the Colorado Springs councilmember.
- `krdo.com` still has no reachable search endpoint (`/search/?q=` 404s too, joining `?s=` and
  `/search/`) - three endpoint guesses now dead across two research passes, stop trying krdo.com
  search entirely for this cohort and rely on koaa.com.

## Lynette Crow-Iverson (At-Large 1) pass, 2026-08-21 — first NO-QUESTIONNAIRE candidate in this
## cohort, and first real test of pikespeakbulletin.org / socoinsider.com

Her `sources/cpr-2023-crow-iverson.md` records "Candidate did not respond to survey" on every
single question (verified by reading the full file) — zero tier-1 material, unlike every prior
candidate in this cohort. Went in expecting 0 rows; landed 2/22 via web sourcing alone.

- **`pikespeakbulletin.org/?s=<Name>` WORKS WELL and DID surface real content** — 5 distinct
  articles for "Crow-Iverson" (2025-2026), mostly about her as Council President (sworn in April
  2025) handling public-comment procedure, an MLK proclamation controversy, and a Charlie Kirk
  resolution. Good WebFetch summarization quality — returned real dates, URLs and verbatim quotes
  on the first pass, no retry needed.
- **`socoinsider.com/?s=<Name>` returned a genuine, trustworthy ZERO** ("Search Results:
  Crow-Iverson (0)") — confirms the brief's claim that this endpoint is real server-rendered
  search, not a JS shell; a negative here is worth recording; don't skip trying it just because it
  came up empty for this person — it may hit for others.
- **Most of what pikespeakbulletin.org surfaced for her was PROCEDURAL/DECORUM, not policy** — her
  Council-President-era fights (banning public comment on a resolution, reprimanding a colleague
  for a social-media post, restricting comment procedure) all involve free-speech/meeting-process
  disputes that do NOT map onto any of the 22 topics (not `religious-freedom`, not
  `campaign-finance`, not `civil-rights` — checked all three explicitly). **A council president's
  procedural fight over WHO gets to talk and WHEN is not a policy stance on the subject they were
  talking about.** She was notably deliberate about staying off the immigration substance during
  the MLK/ICE controversy — her reprimand of Councilmember Gold was framed entirely as a decorum
  violation, explicitly NOT engaging the ICE-detainer content faith leaders raised. Read three
  separate articles on this to confirm she never took a position on the actual immigration
  question — this is a genuine, confirmed absence (not an unchecked topic) for `local-immigration`,
  distinct from Henjum's case (where she had a real detainer-adjacent quote).
- **The single highest-value source for her: `koaa.com` had an actual sit-down interview article**
  — "One-on-one with Colorado Springs City Council President Lynette Crow-Iverson" (found via
  `koaa.com/search?q=Crow-Iverson`, by Tony Keith). This is a proper Q&A/profile interview, not a
  vote-report — it yielded her own words on limited-government philosophy, police/fire/
  infrastructure as her "essential functions" focus, the sit-lie ordinance, and a North Nevada
  Avenue corridor redevelopment mention. **When a name search on koaa.com surfaces a "one-on-one"
  or profile-interview headline, prioritize fetching it directly** — it's a much richer source per
  fetch than vote-report articles, which tend to quote everyone BUT the person you're researching.
- **Her own words on the sit-lie ordinance seated 2 chairs where a bare vote (Henjum's case)
  seated none.** She said, unprompted, in the interview: "we expanded sit-lie, which is a
  compassionate way of dealing with homelessness and vagrancy," "Getting people the help they need
  is more compassionate than letting them sit there in freezing temperatures," and "You can't just
  trash a part of our city. You have to do something." Cross-referenced with
  `pikespeakbulletin.org/?s=sit-lie` for the ordinance's actual mechanics (found via
  `local-politics/homeless-union-protests-sit-lie-expansion/`): $500 fine 1st offense, up to 90
  days JAIL 2nd offense, no shelter-bed contingency mentioned, no explicit warning step before the
  first penalty. The combination of (a) her own forward-looking normative framing and (b) the
  ordinance's actual criminal-penalty mechanics is what let both `homelessness` and
  `homelessness-response` seat cleanly (5 and 4 respectively) — neither the quote alone nor the
  ordinance-mechanics alone would have been enough.
- **`public-safety-approach` and `economic-development` came close but didn't seat** — her "I'm a
  limited government. Essential functions of government, police, fire and infrastructure... will
  continue to be my focus" is priority/continuity language, not a funding-DIRECTION claim (no
  "increase," no specific budget ask like Henjum's "200 more sworn officers"), so it under-
  determines between "keep current" and "increase" chairs — skipped. Her "North Nevada corridor...
  it's kind of a gem in the rough" economic-development lead went nowhere: searched
  `pikespeakbulletin.org/?s=North+Nevada+corridor` and `socoinsider.com/?s=North+Nevada` for the
  actual funding mechanism (tax abatement? public infrastructure spend?) and found NOTHING on
  either — a real, checkable lead that simply has no corroborating source yet.
- **The CPR bio-paragraph's TOPS/PPRTA advocacy claims (rule: reporter's voice, not usable)
  produced zero corroboration anyway** — searched `pikespeakbulletin.org/?s=PPRTA` and
  `socoinsider.com/?s=PPRTA` specifically hoping to find HER OWN words on the ballot campaign; no
  PPRTA article mentions her at all. Even if the bio-paragraph rule didn't bar it, there's no
  independent source to promote it with. Same non-result for a direct utilities/rate-case search
  (`pikespeakbulletin.org/?s=Crow-Iverson+utilities`) — nothing CSU-board-specific for her.
- **Net effect: alt-press search (`pikespeakbulletin.org`) + a koaa.com profile-interview together
  fully replaced a missing questionnaire for 2 of 22 topics** — meaningfully better than zero, and
  proof that `pikespeakbulletin.org/?s=` is worth running FIRST (before `coloradosprings.gov` or
  `koaa.com`) for any candidate in this cohort, questionnaire or not — it was faster and higher
  signal-per-fetch than any other source tried this pass.
