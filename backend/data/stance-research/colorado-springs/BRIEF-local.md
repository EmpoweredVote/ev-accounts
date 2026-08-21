# Researcher brief — Colorado Springs / El Paso County, LOCAL scale

Read this whole file before recording a single row.

## The scale

The 22 live local topics, with the full five-value ladder for each, are in:

    backend/data/stance-research/colorado-springs/scale-local.json

**Read that file with the Read tool.** Do not work from memory and do not invent `topic_key`
values — a row whose `topic_key` is not in that file is discarded.

## Five chairs, not a rating

Each topic's five values are five *distinct, substantive positions* a real person could hold,
defend, and point to a policy for. They are not "strongly agree → strongly disagree".

To seat someone in a chair you need evidence describing **that chair**. Evidence that establishes
only the *direction* (pro/anti) under-determines which of the two or three chairs on that side
applies — recording one anyway is an unevidenced claim about a real person.

When a voter matches this politician on a topic, the product says *"you both believe X"*, quoting
the chair text. Your value must survive that sentence being read aloud to the politician.

- 🔴 **Never assume polarity.** Read each ladder. The corpus convention is that value 1 is the
  maximum-government-action end, but several topics do not follow it, and Residential Zoning and
  Growth and Development Pace are off-axis entirely — the deregulatory and the progressive
  position can sit at the *same* end. The ladder text is the only authority.
- 🔴 **"The least extreme option the reasoning supports" is a tiebreaker, not evidence.** If you
  find yourself reaching for it, the row is not evidenced. Skip it.
- 🔴 **A blank spoke is a correct answer.** An empty compass is honest; a confabulated one is a
  false statement about a real person. Skipping is always available and never penalised.
- If two adjacent chairs both fit the evidence, **skip the topic**.

## Rules specific to this cohort

1. **Colorado Springs city offices are NONPARTISAN by charter**, and El Paso County row officers
   were seated from per-person reads. **Infer nothing from party.** Not direction, not magnitude.
   There is no "they're a Republican so probably a 4".

2. 🔴 **A land-use vote is quasi-judicial, not a stance.** When a council member votes on a
   specific annexation, rezoning or development application, they are adjudicating that
   application against legal criteria — they are not declaring a policy position, and a vote
   record alone cannot seat a chair on `growth-and-development` or `residential-zoning`.
   It becomes usable **only** when they articulate it in policy terms. Compare:
   - NOT usable: "voted against the Karman Line annexation."
   - Usable: Henjum — *"I am opposed to (and recently voted no on 2) so called 'flagpole'
     annexations that are several miles from the existing City boundaries"* — that is a general
     rule she applies, stated as policy, with the vote as evidence she means it.

3. **These are municipal and county officials.** Many of the 22 topics (abortion, trans-athletes,
   religious-freedom, campaign-finance, fossil-fuels) will have **no local record at all**. That
   is expected. Do not stretch a city-budget quote into a national-issue chair. Check each topic,
   then skip cleanly.

4. 🔴 **THE NON-SANCTUARY RESOLUTION IS OFF-QUESTION FOR `local-immigration` — RULED, DO NOT
   RE-SEAT IT.** Colorado Springs council has passed a "we are not a sanctuary city" resolution
   three times (Feb 2024 6–3, May 2025, and again since). It is tempting and it does not fit.
   Read the ladder: every chair on `local-immigration` is about **law enforcement's relationship
   to federal immigration enforcement** — ICE detainers, information sharing, proactive assistance.
   The resolution is about **municipal spending and symbolic posture**: it declares non-sanctuary
   status, says the city won't spend taxpayer money on the migrant crisis, and calls on the
   federal government to secure the border. It contains no detainer or information-sharing policy
   at all.
   - A **vote** on it — either way — therefore seats no chair. One row was already dropped in
     review where a member's "no" vote plus a quote about serving arrivals was read as chair 2;
     the reasoning itself conceded she had said nothing about detainers. Voting against the
     declaration places someone on the more-welcoming side, but chairs 1 and 2 both fit and
     nothing separates them ⇒ blank.
   - The **narrow exception**: a person's own statement that speaks to the ladder's actual axis.
     The mayor's "we are not a sanctuary city" is admissible for chair 3 because in ordinary usage
     that phrase is a claim about cooperating with federal enforcement, and no proactive-assistance
     directive exists to push it to 4. A statement about *serving people who arrive* is not — that
     is service provision, a different axis.

5. **Serving on a board is not a stance.** Colorado Springs council members sit ex officio as the
   Colorado Springs Utilities board. Describing that role, or explaining how the governance model
   works, is not a position on energy or climate. A vote *for a specific rate case or generation
   plan*, with stated reasoning, may be.

## Sources

**Tier 1 — harvested locally, already verified, read these first.** In
`backend/data/stance-research/colorado-springs/sources/`:

| file | who |
|---|---|
| `cpr-2025-donelson.md` | Dave Donelson, Council D1 |
| `cpr-2025-williams.md` | Brandy Williams, Council D3 |
| `cpr-2025-gold.md` | Kimberly Gold, Council D4 |
| `cpr-2025-henjum.md` | Nancy Henjum, Council D5 |
| `cpr-2025-rainey.md` | Roland Rainey Jr., Council D6 |
| `cpr-2023-rainey-atlarge.md` | Rainey again, 2023 at-large run |
| `cpr-2023-leinweber.md` | David Leinweber, At-Large 2 |
| `cpr-2023-risley.md` | Brian Risley, At-Large 3 |
| `cpr-2023-crow-iverson.md` | Lynette Crow-Iverson — **records "Candidate did not respond to survey"** |
| `cpr-2023-mobolade.md` | Yemi Mobolade, Mayor |
| `cpr-2024-wysong.md` | Bill Wysong, EPC Commissioner D3 |
| `cpr-2023-atlarge-overview.md`, `cpr-2023-mayoral-overview.md` | biography/issue summaries — **journalist's paraphrase, not the candidate's words** |

These are KRCC/CPR candidate questionnaires: the candidate's own written answers, sectioned
*Development & Growth / Public Health & Safety / Governance*. Cite the `source_url` recorded in
each file's header.

⚠ The overview files summarise candidates **in a reporter's voice**. Use them to find leads, never
as a quote, and never as the sole basis for a chair.

🔴 **AND THE SAME TRAP IS INSIDE EVERY QUESTIONNAIRE FILE.** Each questionnaire page opens with a
KRCC-written biography paragraph, introduced by a line like *"The short biography below is gleaned
from the candidate's response, their website and other sources."* Everything in that paragraph is
the **reporter's** characterisation, not the candidate's words — and it reads exactly like a
position statement. This has already cost one row: an agent seated `economic-development` = 1 ("No
corporate tax incentives…") on the bio line *"priorities include … limiting government overreach
into the realm of private business"*, when the candidate's own answers never mention incentives,
subsidies or abatements at all. The row was dropped in review.

**Where the candidate's own words begin** is the first question heading (e.g. "Role and vision",
"What is your elevator pitch…"). Everything above that line is off-limits as evidence.

**Tier 2 — fetch these yourself with WebFetch** for anything tier 1 doesn't cover.

🔴 **`coloradosprings.gov/news` IS THE HIGHEST-YIELD LIVE SOURCE — go there before anything else.**
Measured on this cohort: the tier-1 questionnaires capture only *campaign-era* positions (2023 or
2025), while the **governing record from 2024–2026 lives on the city news page** and is invisible
to the questionnaires. On the mayor alone it produced four topics nothing else reached — an August
2026 sanitation initiative, August 2026 data-centre standards, an August 2026 homelessness
response team, and a January 2024 migrants/sanctuary statement. It took that person from 7 rows to
11. Search it for your official by name **and** for the policy area.

**How to search, measured on this cohort:**
- `coloradosprings.gov/search?query=<term>` is a **genuine server-rendered search** — its "no
  results" is real negative evidence you can rely on, not a JS shell hiding hits.
- `koaa.com/search?q=<term>` is the **highest-yield outlet search found**, good for both finding
  positions and confirming absence.
- 🔴 `krdo.com` has no WebFetch-reachable search endpoint — both `?s=` and `/search/?q=` return
  404. Don't retry it. (Individual krdo.com article URLs still work if you have one.)
- ✅ **`pikespeakbulletin.org/?s=<term>` and `socoinsider.com/?s=<term>` BOTH WORK** — verified
  server-rendered search, ~215KB and ~111KB of real results. These are the local
  alternative-press outlets (successors to the Colorado Springs Independent) and they cover
  council business in far more depth than the TV stations. **They are the least-tried and most
  promising source on this list — use them.** Note this supersedes the old note that
  "csindy.com is dead": csindy.com the *domain* redirects away, but the journalism moved to these
  two and is fully reachable.
- 🔴 **Search by institution and topic, not by name+topic.** `"Colorado Springs council immigration
  resolution"` surfaced a council vote that `"Henjum immigration"` and `"Henjum sanctuary"` both
  missed entirely. Your official is usually covered as part of a body doing something, not as the
  subject of their own article.

Also worth trying:
- `coloradosprings.gov` council-member bio pages. District members:
  `coloradosprings.gov/city-council/page/<firstname-lastname>-district-<n>`. At-large members use
  a bare slug: `coloradosprings.gov/<firstnamelastname>`. Usually bio-only — check, don't dwell.
- `coloradosprings.gov` agendas and minutes (remember the quasi-judicial rule above)
- `elpasoco.com` elected-official and department pages; `bocc.elpasoco.com` for board records
- `koaa.com` and `krdo.com` — these work and carry State of the City / forum coverage
- Wikipedia — **as a lead-finder only.** Its citation list points at the primary sources. Never
  cite it as the basis for a chair.
- The official's own campaign site issues page

🔴 **Confirmed dead on this cohort — do not spend attempts re-testing these:**
- `ballotpedia.org/<Name>` — returns empty content for these officials (no real page)
- `gazette.com` — WAF-protected like cpr.org; WebFetch gets 403/empty
- `csindy.com` — redirects off-domain to socoinsider.com
- Outlet search endpoints (`?s=<query>`) — 403 or serve a JS shell with no results
- Guessed campaign domains (e.g. `<name>.com`) — mostly placeholder pages

🔴 **cpr.org is behind a WAF.** WebFetch gets HTTP 403 and so does curl. Everything from cpr.org
that this wave needs is already in `sources/` — read the file, don't re-fetch. If you need a
cpr.org page that isn't there, say so in your notes instead of burning attempts on it.

**Tool rule:** prefer the local files (Read), then WebFetch. Do not use WebSearch or Playwright.

## If your subject is an El Paso County official

The county cohort is 5 commissioners plus 6 row officers, and it behaves very differently from the
city council.

**What exists:**
- `sources/cpr-2024-wysong.md` — the ONLY county KRCC questionnaire in this cohort. Commissioner
  **Bill Wysong** (D3) filled it out. 🔴 **Carrie Geitner (D2) and Cory Applegate (D4) are both
  recorded on KRCC's 2024 guide as "candidate did not fill out survey"** — that is a documented
  refusal, not a hole in our collection. Holly Williams (D1) and Lauren Nelson (D5) were not on the
  2024 ballot at all, so no questionnaire exists for them either.
- KRCC also links **League of Women Voters candidate forums on video** for Commissioner Districts 2
  and 4. Video is not usable as a citation unless you find a transcript or a written report of what
  was said — do not paraphrase a video you cannot quote.
- `sources/epc-commissioners.md` and `sources/epc-elected-officials.md` are harvested but are
  **purely administrative** — they describe what each office does, with no policy content. Do not
  mine them for stances; they are there so you don't waste a fetch discovering that.

**Calibrate your expectations by office, and do not fight the data:**
- **Sheriff (Joe Roybal)** and **District Attorney (Michael Allen)** are the two row officers with
  genuine policy records — `public-safety-approach`, `jail-capacity`, and possibly
  `local-immigration` (the sheriff's detainer policy is *literally* what that ladder asks about,
  unlike the city's symbolic resolution). Note Allen is also the 2026 Republican nominee for
  Colorado Attorney General, so he has an active statewide campaign platform — but ⚠ that platform
  is about *state* law enforcement; only map it where it genuinely answers a local-scale ladder.
- **Assessor, Clerk & Recorder, Coroner, Treasurer** are administrative offices. Expect **zero or
  near-zero** seated topics. Confirm the absence properly and report it; do not manufacture rows.
  (The Clerk runs elections — that is administration, not a `campaign-finance` or `voting-rights`
  position.)
- **Commissioners** set county policy on land use, jail funding, roads and public health, so they
  are the richer half of this cohort.

🔴 **The county has NOT certified a 2026 candidate list yet** (checked 2026-08-21), so there is no
2026 voter guide to find. Don't hunt for one.

## Output

Append rows to the CSV path given in your dispatch prompt. RFC-4180: any field containing a comma,
quote or newline must be wrapped in double quotes, and embedded double quotes doubled (`""`).
A malformed row breaks the merge parser for the whole file.

Columns, exactly:

    full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified,editor_note

- `reasoning` — 🔴 **this is PUBLIC, voter-facing text** rendered on the politician's Essentials
  profile under "Why this position?". Write it for a voter, in plain language, and make it justify
  *the specific chair you chose* — name the instrument, vote, or statement it rests on. Never write
  reasoning that argues a neighbouring chair.
- `quote_text` — only if it passes all three gates: **forward-looking** (reasoning about what
  should be done, not a résumé), **on-question** (answers this topic's axis, not an adjacent one),
  and **a position, not a personal attack**. Otherwise leave blank and still record the stance.
- `quote_deidentified` — remove identity leaks, marking every cut with `…` and every substitution
  in `[brackets]`. Never silently reword. Blank it rather than paraphrase.
- `editor_note` — required whenever `quote_text` is non-blank. One or two jargon-free sentences: why
  this quote, how it matches the value, and what you edited ("verbatim, no edits" if nothing).

## Report back

When you finish, state: rows recorded, topics skipped **and why**, any person you could find no
usable source for, and anything about the sources a later pass should know.
